# Туториал по macOS {#macos-tutorial}

## Вариант в одну строку {#one-line-option}

Необязательный bootstrap для спонсоров устанавливает macFUSE при необходимости, скачивает сборку для Intel или Apple silicon и запускает
выбор провайдера и диагностику:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Он использует вход через браузер в GitHub. macOS может всё ещё потребовать подтверждения в **System Settings > Privacy & Security** и
перезагрузки. Существующие бинарники и конфиги остаются на месте. Ручной вариант описан ниже.

## Шаг 1: Установка macFUSE {#step-1-install-macfuse}

macFUSE позволяет rclone монтировать виртуальную файловую систему zurg как обычную папку на вашем Mac.

1. Скачайте последний `.dmg` с [macfuse.io](https://macfuse.io)
2. Откройте `.dmg` и запустите установщик
3. Во время установки macOS заблокирует системное расширение. Перейдите в **System Settings > Privacy & Security**, прокрутите вниз и нажмите **Allow**
4. **Перезагрузите Mac** (это нужно, чтобы kernel extension загрузился)

После перезагрузки откройте **Terminal** (нажмите `Cmd + Space`, введите «Terminal», нажмите Enter) и проверьте, что macOS загрузит macFUSE. Это та же проверка, что делает `zurg setup`:

```bash
/Library/Filesystems/macfuse.fs/Contents/Resources/load_macfuse && echo "macFUSE is ready"
```

Если строки `macFUSE is ready` не появилось, macOS ещё не разрешила расширение. На Apple silicon включите сторонние kernel extensions в Recovery, разрешите macFUSE в **System Settings > Privacy & Security**, затем перезагрузитесь и проверьте снова.

## Шаг 2: Скачивание zurg {#step-2-download-zurg}

Откройте [GitHub Releases](https://github.com/debridmediamanager/zurg/releases) в браузере, где вы вошли в аккаунт GitHub с доступом к zurg. Возьмите самый новый nightly. Это pre-release вверху списка. Скачайте его zip `darwin-arm64`, а на Mac с Intel — `darwin-amd64`. Не берите релиз, который GitHub отмечает как **Latest**. Это v1.0.0. Он старше `zurg setup` и отвечает на него `unknown command`.

Nightly-сборки доступны только спонсорам. Пока у вашего аккаунта GitHub нет доступа, эта страница отвечает 404. Станьте спонсором на [gatekeeper](https://gatekeeper.debridmediamanager.com/), чтобы получить доступ. Бесплатная публичная сборка — это v1.0.0 из [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). В ней нет `zurg setup`. Настройте её вручную, как описано в [её README](https://github.com/debridmediamanager/zurg-public#readme), а не по шагам ниже.

Затем распакуйте архив.

```bash
mkdir -p ~/zurg && cd ~/zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
```

Проверьте:

```bash
./zurg version
```

## Рекомендуется: пусть zurg сам завершит настройку {#recommended-let-zurg-finish-the-setup}

```bash
./zurg setup
./zurg doctor
```

Из распакованной папки выполни:

`setup` спросит, какие провайдеры настроить. Выбери один или несколько из Real-Debrid, TorBox, AllDebrid, Usenet, Premiumize, Debrid-Link и Offcloud в нужном порядке приоритета. Например, введи `2,4`, чтобы сначала выбрать TorBox, а потом Usenet. Он запросит только учётные данные для выбранных сервисов, создаст `config.yml` с правами `0600`, скачает rclone (и ffprobe, если его нет в PATH), подготовит `/Volumes/Zurg` и установит автозапуск.

Если у текущего пользователя есть GUI-домен launchd, setup выберет LaunchAgent. На Mac без графического интерфейса, где никто не вошёл в систему, он установит системный LaunchDaemon, который всё равно запускает zurg от имени текущего пользователя. Для этого варианта автовход не нужен.

Проверка зависимостей отличает установленный пакет macFUSE от расширения, которое macOS реально может загрузить. На Apple silicon первая установка macFUSE может потребовать однократного изменения настроек безопасности в режиме восстановления (Recovery), подтверждения в **System Settings > Privacy & Security** и перезагрузки. Ни один установщик не может обойти эти подтверждения.

Повторно запускать setup безопасно. Он обновит созданный сервис launchd, но не заменит существующий `config.yml`.

Перед стримингом через монтирование открой `config.yml` или Dashboard по адресу `http://localhost:9999/config/` и задай оба параметра `--vfs-cache-max-size` и `--vfs-cache-min-free-space` в `rclone_extra_args`. Максимум держи меньше половины свободного места на диске, а с помощью параметра минимального свободного места оставь не меньше `20G`. Затем выполни `./zurg service restart`.

Остальная часть этой страницы объясняет настройку конфига и Plex. Шаги 3, 4, 5 и 7 относятся к ручной альтернативе и их можно пропустить, если `zurg setup` завершился успешно.

## Шаг 3: Ручная настройка zurg {#step-3-configure-zurg-manually}

Создайте конфигурационный файл с вашим API-токеном Real-Debrid:

```bash
cd ~/zurg
cat > config.yml << 'EOF'
# Minimal config - use Dashboard at http://localhost:9999/config/ for more settings
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN_HERE

rclone_enabled: true
mount_path: /Volumes/Zurg

rclone_extra_args:
  - "--vfs-cache-max-size"
  - "100G"
  - "--vfs-cache-min-free-space"
  - "20G"

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
EOF
```

Замените токен-заглушку на ваш настоящий токен с [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354):

```bash
sed -i '' "s|YOUR_RD_API_TOKEN_HERE|PASTE_YOUR_TOKEN_HERE|g" ~/zurg/config.yml
```

> **Не удаляйте `mount_path`.** Без него rclone на macOS использует `/Volumes/Zurg` по умолчанию, но сканирование медиасервера включается только тогда, когда `mount_path` задан явно. Если его не указать, Plex никогда не получит сигнал на обновление (Шаг 6).

> **Размер кэша очень важен.** VFS-кэш хранит фрагменты потоковых файлов на локальном диске. Если он заполнит диск, производительность macOS сильно упадёт: Spotlight, Plex и даже сама система могут перестать отвечать. Всегда задавайте **оба** ограничения:
>
> - `--vfs-cache-max-size` — жёсткий лимит общего размера кэша. Установите его **не больше 50% свободного места на диске**. Проверить можно командой `df -h /`.
> - `--vfs-cache-min-free-space` — прекращает кэширование, когда свободное место падает ниже этого значения. Оставьте **20G или больше** как запас на всякий случай.
>
> Например, на диске 256 ГБ со 100 ГБ свободного места используйте `50G` для максимального размера и `20G` для минимума свободного места.

## Шаг 4: Ручная установка зависимостей {#step-4-download-dependencies-manually}

zurg умеет сам скачать rclone и ffprobe и прописать их пути в `config.yml`. Для этого есть встроенная команда:

```bash
cd ~/zurg
./zurg download-requirements
```

Создайте точку монтирования и каталог для логов. Папка `/Volumes` принадлежит root, поэтому zurg не может сам создать `/Volumes/Zurg`. Каталог для логов тоже должен существовать до того, как launchd откроет свои выходные файлы на шаге 7:

```bash
sudo mkdir -p /Volumes/Zurg
sudo chown "$(whoami)" /Volumes/Zurg
mkdir -p ~/zurg/logs
```

Все доступные опции описаны в [справочнике по конфигурации](../reference/config.md). Также можно открыть веб-Dashboard по адресу `http://localhost:9999/config/` после запуска zurg.

## Шаг 5: Ручная проверка zurg {#step-5-test-zurg-manually}

Перед настройкой автозапуска убедитесь, что всё работает:

```bash
cd ~/zurg && ./zurg
```

Вы должны увидеть вывод лога, в котором zurg запускается, подключается к Real-Debrid и монтируется через rclone. В другом окне терминала проверьте:

```bash
# Check the HTTP endpoint
curl -s http://localhost:9999/http/version.txt

# Check the mount
ls /Volumes/Zurg/
# Expected: __all__  __downloads__  __unplayable__  movies  shows  version.txt
```

Если всё в порядке, остановите zurg с помощью `Ctrl+C`.

## Шаг 6: Установка Plex Media Server {#step-6-install-plex-media-server}

1. Скачайте с [plex.tv/media-server-downloads](https://www.plex.tv/media-server-downloads/) и выберите **macOS** (Universal)
2. Откройте `.dmg` и перетащите **Plex Media Server** в `/Applications`
3. Запустите Plex Media Server из папки Applications (или через Spotlight: `Cmd + Space` → "Plex Media Server")
4. Браузер должен открыть мастер настройки Plex. Пройдите его, чтобы привязать сервер.
5. **Автозапуск:** щёлкните правой кнопкой мыши по иконке Plex в строке меню и отметьте **Launch at Login**
6. Получите токен Plex. Проще всего так:
   - Откройте любой медиафайл в Plex Web
   - Нажмите **Get Info** (или **...** → **Get Info**)
   - Нажмите **View XML**
   - Найдите `X-Plex-Token=` в адресной строке

Добавьте токен Plex в конфиг zurg, отредактировав `config.yml`:

```yaml
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
```

## Шаг 7: Ручная настройка автозапуска zurg {#step-7-set-up-zurg-auto-start-manually}

macOS LaunchAgents запускают сервисы автоматически при входе в систему. Plex уже сам умеет автозапускаться (Шаг 6), поэтому LaunchAgent нужен только для zurg.

### LaunchAgent для zurg {#zurg-launchagent}

```bash
cat > ~/Library/LaunchAgents/com.zurg.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zurg</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/zurg/zurg</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${HOME}/zurg</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME}/zurg/logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME}/zurg/logs/launchd-stderr.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST
```

Основные настройки:
- **RunAtLoad** — запускает zurg при входе в систему
- **KeepAlive / SuccessfulExit: false** — если zurg упадёт, launchd автоматически перезапустит его
- **ThrottleInterval: 10** — ждёт 10 секунд между попытками перезапуска

### Загрузка LaunchAgent {#load-the-launchagent}

```bash
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Проверьте, что он зарегистрирован:

```bash
launchctl list | grep zurg
# Should show com.zurg with a PID
```

## Шаг 8: Настройка библиотек Plex {#step-8-configure-plex-libraries}

Теперь, когда zurg запущен и монтирование активно:

1. Откройте [http://localhost:32400/web](http://localhost:32400/web)
2. Перейдите в **Settings** (значок гаечного ключа) → **Manage** → **Libraries**
3. Нажмите **Add Library**

**Добавьте библиотеку фильмов:**
- Type: **Movies**
- Нажмите **Browse for media folder**
- Перейдите к `/Volumes/Zurg/movies`
- Нажмите **Add Library**

**Добавьте библиотеку сериалов:**
- Type: **TV Shows**
- Нажмите **Browse for media folder**
- Перейдите к `/Volumes/Zurg/shows`
- Нажмите **Add Library**

**Рекомендуемые настройки библиотек** (в каждой библиотеке через Edit → Advanced):
- Снимите галочку с **Empty trash automatically after every scan**. zurg сам управляет жизненным циклом контента.
- Снимите галочку с **Generate video preview thumbnails**. Так вы сэкономите трафик, ведь файлы стримятся с Real-Debrid.

## Шаг 9: Проверка, что всё работает {#step-9-verify-everything-works}

```bash
# 1. zurg is running
curl -s http://localhost:9999/http/version.txt && echo " - zurg is up"

# 2. Mount is active
ls /Volumes/Zurg/movies > /dev/null 2>&1 && echo "Mount is active"

# 3. Plex is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:32400/identity && echo " - Plex is up"

# 4. Processes
ps -eo pid,command | grep -E "[z]urg|[r]clone.*mount|[P]lex Media Server" | head -5

# 5. zurg service (for the manual LaunchAgent from Step 7: launchctl list | grep com.zurg)
cd ~/zurg && ./zurg service status
```

## Шаг 10: Автоматический вход в систему (необязательно) {#step-10-enable-auto-login-optional}

Это нужно только для ручного пути с LaunchAgent. LaunchAgent требует, чтобы пользователь входил в систему после каждой перезагрузки. Встроенный установщик на headless Mac вместо этого использует LaunchDaemon.

Если вы сознательно используете ручной LaunchAgent на headless-сервере, включите автоматический вход, чтобы он запускался без участия пользователя:

1. Откройте **System Settings**
2. Перейдите в **Users & Groups**
3. Нажмите **Automatic login** и выберите своего пользователя
4. Введите пароль

> **Примечание по безопасности:** автоматический вход означает, что любой, кто физически имеет доступ к Mac, может получить доступ к вашей учётной записи. Используйте это только на машинах в надёжном месте.

---

## Управление сервисами {#managing-the-services}

Для установки, созданной через `zurg setup`, используйте одни и те же команды на всех платформах:

```bash
cd ~/zurg
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` удаляет только автозапуск. Бинарник, конфиг, данные, логи и кэш он оставляет на месте. Команды launchctl ниже предназначены для ручного LaunchAgent из Шага 7 (`com.zurg`). `zurg setup` создаёт свой агент с именем `com.zurg.zurg`.

### Запуск / Остановка / Перезапуск {#start--stop--restart}

```bash
# Stop zurg (and its rclone child process)
launchctl stop com.zurg

# Start zurg
launchctl start com.zurg

# Restart zurg
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Просмотр логов {#view-logs}

```bash
# zurg logs
tail -50 ~/zurg/logs/zurg.log

# Rclone logs
tail -50 ~/zurg/logs/rclone.log
```

### Перезагрузка после изменения конфига {#reload-after-config-change}

Если вы редактируете файл `.plist`:

```bash
launchctl unload ~/Library/LaunchAgents/com.zurg.plist
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Если вы редактируете `config.yml`, просто перезапустите zurg:

```bash
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Обновление zurg {#update-zurg}

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` берёт самую свежую nightly-сборку. Он скачивает её, проверяет, что новый бинарник сообщает ожидаемую версию, и только потом заменяет им старый, переименовывая файл. Поэтому работающий процесс никогда не перезаписывается. Если установлена уже самая новая сборка, команда так и говорит и ничего не меняет.

`update` входит в GitHub под тем аккаунтом, который вы использовали при установке. Для этого установщик хранит GitHub CLI в `~/zurg/bin`. Если `update` пишет, что не нашёл GitHub-учётные данные, значит ваша установка старше этого изменения. Выполните обновление через установщик один раз, и после этого `zurg update` будет работать. Эта же команда обновляет и сборку, которая слишком старая, чтобы иметь `zurg update`.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

Вместо этого можно задать переменную `GITHUB_TOKEN`. Используйте классический токен с областью `repo` от аккаунта GitHub, у которого есть доступ к zurg.

Вручную скачайте новый zip `darwin-arm64` (`darwin-amd64` на Mac с Intel) со страницы [Релизы](https://github.com/debridmediamanager/zurg/releases) так же, как в Шаге 2, а затем:

```bash
cd ~/zurg
./zurg service stop && sleep 2     # manual LaunchAgent: launchctl stop com.zurg
rm -f zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
./zurg service start               # manual LaunchAgent: launchctl start com.zurg
```

Удаляйте старый бинарник, а не перезаписывайте его на месте. Если перезаписать файл, он сохранит тот же inode и потеряет ad-hoc подпись кода, и macOS тогда убивает новую сборку при запуске. Симптом такой: процесс сразу завершается и ничего не выводит. Именно поэтому `zurg update` заменяет файл переименованием.

## Устранение неполадок {#troubleshooting}

### "Operation not permitted" при монтировании {#operation-not-permitted-when-mounting}

macFUSE нужно одобрить в System Settings:
1. Откройте **System Settings > Privacy & Security**
2. Прокрутите вниз и найдите сообщение о заблокированном системном расширении
3. Нажмите **Allow**, а затем **reboot**

### Точка монтирования показывает "not a directory" или зависает {#mount-shows-as-not-a-directory-or-hangs}

Точка монтирования могла остаться «зависшей» после предыдущего падения:

```bash
umount -f /Volumes/Zurg 2>/dev/null
diskutil unmount force /Volumes/Zurg 2>/dev/null
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### zurg постоянно перезапускается (crash loop) {#zurg-keeps-restarting-crash-loop}

Проверьте логи на наличие ошибки:

```bash
tail -100 ~/zurg/logs/service-stderr.log   # manual LaunchAgent: launchd-stderr.log
```

Частые причины:
- Неверный синтаксис в `config.yml` — проверьте вручную командой `cd ~/zurg && ./zurg`
- Истёкший токен Real-Debrid — получите новый на [real-debrid.com/apitoken](http://real-debrid.com/?id=20476410)
- `/Volumes/Zurg` отсутствует или принадлежит не вашему пользователю — zurg не может его создать и выдаёт ошибку `ensure mount path: permission denied` (Шаг 4)
- Порт 9999 уже занят — проверьте командой `lsof -i :9999`

### macFUSE ломается после обновления macOS {#macfuse-breaks-after-macos-update}

Крупные обновления macOS иногда ломают расширение ядра. Переустановите macFUSE:
1. Скачайте последнюю версию с [macfuse.io](https://macfuse.io)
2. Установите её
3. Разрешите расширение в **System Settings > Privacy & Security** (Настройки системы > Конфиденциальность и безопасность)
4. Перезагрузите компьютер

### Всё работало, но перестало работать после перезагрузки {#everything-was-working-but-stopped-after-reboot}

Если вы установили ручной LaunchAgent и автологин не включён, нужно войти в систему, прежде чем он запустится. Выберите один из вариантов:
- Включить автологин (см. Шаг 10)
- Подключиться по SSH: LaunchAgents загрузятся, как только появится пользовательская сессия
- Войти удалённо через VNC/Screen Sharing

Установка, созданная командой `zurg setup` на Mac без монитора, использует LaunchDaemon и не требует входа через графический интерфейс. Проверить её можно командой `cd ~/zurg && ./zurg service status`.

Всё ещё не получается? Задайте вопрос в форуме **zurg-support** в [Discord](https://discord.com/invite/7u4YjMThXP). В разделе [Getting help](../../guides/remote-help.md) написано, что нужно указать.

## Обзор архитектуры {#architecture-overview}

```
launchd (PID 1)

  com.zurg LaunchAgent
    └── ./zurg
          ├── HTTP/WebDAV server (:9999)
          ├── Dashboard UI (:9999/config/)
          ├── Real-Debrid API client
          └── rclone mount (child process)
                └── /Volumes/Zurg/
                      ├── movies/
                      └── shows/

  Plex Media Server (:32400)  — Launch at Login via menu bar
    ├── Movies library  → /Volumes/Zurg/movies
    └── Shows library   → /Volumes/Zurg/shows

  macFUSE kernel extension
    └── Enables FUSE mounts for rclone
```

## Краткая справка {#quick-reference}

Запускайте это в `~/zurg`. Строки `zurg service` подходят для установки, сделанной через `zurg setup`; ручной LaunchAgent использует команды launchctl из раздела [Managing the Services](#managing-the-services).

| Action | Command |
|--------|---------|
| Start zurg | `./zurg service start` |
| Stop zurg | `./zurg service stop` |
| Restart zurg | `./zurg service restart` |
| Check the install | `./zurg doctor` |
| Remove auto-start | `./zurg service uninstall` |
| View zurg logs | `tail -f ~/zurg/logs/zurg.log` |
| View rclone logs | `tail -f ~/zurg/logs/rclone.log` |
| Check mount | `ls /Volumes/Zurg/` |
| Check zurg health | `curl http://localhost:9999/http/version.txt` |
| Check Plex health | `curl http://localhost:32400/identity` |
| Dashboard | `open http://localhost:9999/config/` |
| Force unmount | `umount -f /Volumes/Zurg` |
