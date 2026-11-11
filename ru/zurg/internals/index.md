# Внутреннее устройство {#internals}

Как устроен zurg. Что у него с производительностью. Заметки по проектированию сложных мест. Написано для тех, кто собирается менять код. Для запуска zurg всё это не нужно.

## Общая картина {#the-shape-of-it}

| Страница | Что в ней |
|---|---|
| [Architecture](architecture.md) | Общая структура и инварианты, которые легко сломать. Начните отсюда. |
| [Naming](naming.md) | Как релиз и его файлы получают имена, которые показывает mount. |
| [Persistent caches](persistent-caches.md) | Что хранится на диске между перезапусками и чего это стоит. |
| [Directory config UI/UX](uiux.md) | Оценка дизайна, на которой основан редактор директорий. |

## Что было измерено {#what-was-measured}

| Страница | Что внутри |
|---|---|
| [Debrid baseline](debrid-baseline.md) | Сколько стоит zurg и насколько быстро он работает с Real-Debrid, AllDebrid и TorBox. |
| [Torrent lifecycle](torrent-lifecycle.md) | Что каждый аккаунт показывает во время загрузки, записано в реальном времени. |
| [Real-Debrid API notes](realdebrid-behavior.md) | Как работают ссылки, выбор файлов и что на самом деле значит cached. |

## Требования, которым должен соответствовать zurg {#contracts-zurg-has-to-satisfy}

| Страница | Что внутри |
|---|---|
| [SABnzbd client contract](sabnzbd-client-contract.md) | Точные форматы, которые Sonarr и Radarr ожидают от SABnzbd. |
| [qBittorrent client contract](qbittorrent-client-contract.md) | То же самое для qBittorrent. |
| [plex_api.json](../../internals/plex_api.json) | Сырой набор Plex API, на который ориентируется zurg. 1.2 MB. |

## Что пошло не так {#things-that-went-wrong}

| Страница | Что здесь |
|---|---|
| [Plex trash sweep](plex-trash-sweep.md) | Как привести очистку Plex в соответствие с тем, что сам zurg считает сломанным. |
| [Stream timeout regression](stream-timeout-regression.md) | Проксируемый стрим, который перестал выдерживать длинные чтения. |
| [rclone move refusal](rclone-move-refusal.md) | Пустые импорты после того, как бэкенд отказал в MOVE, и патч для этого. |

## Тестирование {#testing}

- [E2E-тестирование](e2e-test.md) описывает, что проверяет сквозной набор тестов и сколько стоит его запуск.

Что делает конкретный сервис и какие у него ограничения, написано в разделе [Providers](../providers/index.md), а не здесь.
