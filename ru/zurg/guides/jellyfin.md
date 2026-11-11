# Возможности и функции Jellyfin {#jellyfin-features--capabilities}

## Конфигурация и хранилище {#configuration--storage}
- Ключи конфига ([`config.md`](../reference/config.md), `config.example.yml`): `jellyfin_server_url` (строка, по умолчанию `""`), `jellyfin_token` (строка, по умолчанию `""`). Оба по умолчанию закомментированы в `config.example.yml` и отсутствуют в `config.simple.yml`. `mount_path` обязательно должен быть задан, иначе сканирование медиа (включая Jellyfin) отключено (`pkg/scan/scanner.go`).
- Значения сохраняются в `config.yml` через дашборд (`updateConfigFileAtomic`); отдельного файла данных для Jellyfin нет. Поля и их хелперы `Get`/`Set` находятся в `zurgConfig` в `internal/config/config.go`; `ZurgConfigV1` (`internal/config/filters.go`) встраивает эту структуру inline.

## Аутентификация и проверка сервера (QuickConnect) {#authentication--server-validation-quickconnect}
- Панель QuickConnect, поток работы:
  - `/jellyfin/check-server` проверяет доступность через `System/Info/Public` и сообщает версию, имя и доступность QuickConnect (`HandleJellyfinCheckServer`, `pkg/jellyfin/auth.go:CheckServerReachable/CheckQuickConnectEnabled`).
  - `/jellyfin/auth` запускает QuickConnect (`InitiateQuickConnect`), создаёт сессию авторизации, привязанную к cookie (`pkg/jellyfin/auth_session.go`), и запускает фоновый опрос.
  - `/jellyfin/auth/status` возвращает состояние завершения или ошибки, опрашивая `/QuickConnect/Connect` и `/Users/AuthenticateWithQuickConnect` (`PollForQuickConnectAuth`, 60 попыток с интервалом 5 секунд, потом таймаут).
  - `/jellyfin/server` сохраняет URL сервера и токен в конфиг, переинициализирует клиент Jellyfin и отвечает успехом или предупреждением, если переинициализация не удалась (`HandleJellyfinServerSelect`).
  - `/jellyfin/logout` очищает конфиг, переинициализирует сканер без Jellyfin и сбрасывает кэшированный статус панели (`JellyfinStatusFetcher.ClearCache`).
- Менеджер сессий авторизации отслеживает сессии QuickConnect, хранит secret, code, токен и данные пользователя, удаляет их через 10 минут (проверка каждые 5) и предоставляет потокобезопасные геттеры (`pkg/jellyfin/auth_session.go`; глобальный экземпляр в `auth_global.go`).
- Вспомогательные функции QuickConnect в `pkg/jellyfin/auth.go` отправляют стандартный заголовок `Authorization: MediaBrowser …` и работают с отключённой проверкой TLS, чтобы терпеть самоподписанные сертификаты (`newHTTPClient`). Клиент для сканирования так не делает: `mediabrowser.NewCore` создаёт обычный `http.Client` с таймаутом 30 секунд (`pkg/mediabrowser/core.go`), поэтому сервер за самоподписанным сертификатом подключается и проверяется нормально, но его вызовы обновления секций падают на TLS.
- Эндпоинт проверки токена `/System/Info` используется, чтобы подтвердить учётные данные перед сохранением (`ValidateToken`).

## Возможности клиента Jellyfin (`pkg/jellyfin/client.go`) {#jellyfin-client-capabilities-pkgjellyfinclientgo}
- `Client` — это тонкая оболочка над встроенным `mediabrowser.Core` (`pkg/mediabrowser/core.go`), которая используется и в `pkg/emby`, потому что оба сервера выросли из одной кодовой базы. Собственный метод у него только один — `GetSections`; сканирование (`ProcessJob`), активности, статус сервера, жизненный цикл, очередь, заголовок авторизации и отслеживание зависаний берутся из core.
- Авторизация: запросы к Jellyfin отправляют стандартный заголовок `Authorization: MediaBrowser … Token="<token>"`, а клиент Emby вместо него шлёт `X-Emby-Token`.
- Жизненный цикл: `NewClientWithLogger` создаёт core (обрезает завершающие слэши и, если пусты URL *или* токен, выводит предупреждение и возвращает nil). Затем `StartWorker` запускает динамического воркера сканирования, если только не задано `GO_TEST_MODE=1`. `Close` останавливает воркера и очередь.
- Очередь сканирования: динамическая очередь заданий + `common.DefaultWorkerConfig`. `GetJobQueueSize` — это значение, которое читает дашборд (через `MediaScanner.GetQueueSizes`). `GetJobQueue` — заглушка для совместимости: возвращает срез пустых заданий нужного размера.
- Обнаружение нагрузки и зависаний: `CheckServerLoad` опрашивает `/ScheduledTasks`, следит за запущенными задачами, в названии которых есть «scan», ведёт счётчики зависаний для каждой задачи и сообщает о загрузке, когда идут сканирования. `IsJobStuck` помечает задачи, которые превысили порог зависания.
- Отслеживание активности: `GetRunningTasks` возвращает подробные структуры `TaskActivity` с ID, Name, State, Progress (из `CurrentProgressPercentage`), Description и статусом зависания для показа на дашборде.
- Статус сервера: `GetServerStatus` опрашивает `/Sessions`, чтобы посчитать активные стриминг-сессии, транскодирование (видео/аудио не в режиме direct) и использование пропускной способности для дашборда.
- Поиск библиотек: `GetSections` вызывает `/Library/VirtualFolders` и возвращает секции с ID/Title/Paths (все папки библиотеки)/Type, а затем дополняет каждую количеством элементов через `Items?ParentId=<id>&Recursive=true&Limit=0`.
- Обновление: `ProcessJob` сообщает обо всех изменённых путях задания одним запросом `POST /Library/Media/Updated`, при этом каждый путь в теле передаётся точно так, как его видит сам сервер в своей файловой системе. Задание без путей обновляет всю библиотеку через `POST /Items/{id}/Refresh`. При ответе 503 возвращается `ServerBusyError`, при 404 — ошибка о том, что библиотека могла быть удалена, а при любом другом 4xx/5xx — тело ответа. `RefreshSection` ставит задания в очередь.
- Вспомогательные функции: `FindSectionNormalized` ищет секцию по префиксу пути (побеждает первое совпадение) и возвращает путь, у которого префикс переписан в регистр, как в расположении библиотеки. Сравнение префикса не зависит от регистра на macOS и Windows и точное на остальных системах (`pkg/common/pathutil.go`).

## Интеграция сканера медиа (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- Инициализирует клиент Jellyfin, когда есть `mount_path`, URL сервера и токен; при ошибках пишет в лог и оставляет клиент nil. Цикла повторных попыток нет (в отличие от Plex), но ручная переинициализация поддерживается.
- `TriggerScan` отправляет запрос в Jellyfin вместе с другими серверами; `triggerJellyfinScan` находит разделы через `FindSectionNormalized`, используя пути с префиксом `mount_path`, и отправляет изменённые пути каждого раздела одним запросом (Plex получает по одному пути в запросе).
- `GetQueueSizes` возвращает длины очередей Plex/Jellyfin/Emby вместе, используя -1 для сервера, который не подключён.
- `ReinitializeJellyfinClient` закрывает существующий клиент и создаёт новый с текущими настройками (используется после авторизации в панели и при выходе из системы).

## Панель управления и маршруты {#dashboard--routes}
- Router mounts Jellyfin endpoints: `/jellyfin/check-server`, `/jellyfin/auth`, `/jellyfin/auth/status`, `/jellyfin/server`, `/jellyfin/logout`, `/jellyfin/scan/{sectionID}`, `/jellyfin/scan-all` (`internal/handlers/router.go`).
- Dashboard modal (templates/scripts) drives QuickConnect, displays status/errors, and saves/removes credentials; queue size, library cards with scan buttons, and server activities surface in `dashboard.tmpl`.
- `JellyfinStatusFetcher` (`internal/handlers/dashboard/mediabrowser_status.go`) fills the dashboard JSON from a background cache rather than blocking the page: it validates the token, marks connectivity, populates the library list (ID/Name/Paths/Type/ItemCount), and collects running task activities plus session/transcode/bandwidth counts. Activities and sessions refresh every 30s; the full fetch, libraries included, every 5 minutes. `response.go` serves the cached copy (`JellyfinServerInfo`, `jellyfin_queue_size`).
- Library scan endpoints (`HandleJellyfinScan`, `HandleJellyfinScanAll`) queue a whole-library refresh with no path for individual or all library sections, as the Plex equivalents do, and 503 when no Jellyfin client is configured (`internal/handlers/dashboard/dashboard.go`).
- `jellyfin_server_url` and `jellyfin_token` are also writable through the generic config-update handlers, so they can be set without the QuickConnect modal (`handlers["jellyfin_server_url"]`/`["jellyfin_token"]` in `dashboard.go`; `updateJellyfinServerURL` in `scripts.tmpl`).

## Побочные эффекты библиотеки и обновление {#library-side-effects--refresh}
- Любые побочные эффекты для библиотеки (смена назначения директорий, синхронизация STRM, починка) вызывают `MediaScanner.TriggerScan`, который обновляет Jellyfin, если клиент подключён (`internal/torrent/hooks.go:TriggerLibrarySideEffects` → `pkg/scan/scanner.go`).
- Тот же вызов сначала сбрасывает устаревшие записи кэша каталогов rclone VFS (dircache) для затронутых путей, чтобы сканирование Jellyfin видело изменение, а не список, закэшированный на несколько часов.
- Синхронизация STRM и хуки `on_library_update` запускаются вместе с триггером сканирования (хук с задержкой 500 мс и без дубликатов). Jellyfin получает пути библиотеки с префиксом mount_path в задачах обновления.

## Разное {#miscellaneous}
- Emby — это интеграция-соседка со своими ключами конфига (`emby_server_url`, `emby_token`) и тем же общим ядром, но без QuickConnect. Войти можно по API key или выбрать пользователя и ввести пароль (`/emby/users`, `/emby/auth`). Карточка на дашборде показывает библиотеки с кнопками сканирования (`/emby/scan/{sectionID}`, `/emby/scan-all`), а также activities и sessions, как у Jellyfin (`EmbyStatusFetcher`).
- `pkg/jellyfin/windows_path_test.go` проверяет, что путь Windows не попадает в URL запроса и доходит до тела без изменений. `find_section_test.go` покрывает сопоставление по префиксу.
