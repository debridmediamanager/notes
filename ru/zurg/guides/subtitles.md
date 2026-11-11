# Субтитры с Bazarr {#subtitles-with-bazarr}

Bazarr находит субтитры для того, что импортируют Sonarr и Radarr, и сохраняет каждый файл рядом с его видео. С zurg видео лежит в `__magic__`, и субтитр тоже. Библиотеки Plex и Jellyfin, указывающие на `__magic__`, читают его как любой субтитр на диске, а rex показывает его в меню субтитров как **English (SRT External)**.

Для этого нужны zurg и rex из ночной сборки 2026-10-24 или новее.

Всё ниже протестировано 2026-10-23 с Radarr `6.3.0.10514`, текущим образом `lscr.io/linuxserver/bazarr`, zurg и rex за этот день и аккаунтом Real-Debrid.

## Перед началом {#before-you-start}

Radarr (или Sonarr) уже импортирует через zurg, и его корневая папка находится внутри `__magic__`, например `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` на macOS, `Z:\__magic__\movies` на Windows). Если это ещё не так, сначала следуйте инструкции [Sonarr & Radarr for torrents](sonarr-radarr-torrents.md) или [for Usenet](sonarr-radarr.md).

## 1. Запустите Bazarr {#1-run-bazarr}

На Linux-хосте дайте Bazarr тот же том, что и Radarr, чтобы оба видели фильм по одному и тому же пути и path mapping не понадобился:

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./bazarr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6767:6767
    restart: unless-stopped
```

Монтируйте **папку выше** точки монтирования zurg (`/mnt`, в которой лежит `/mnt/zurg`), а не саму точку монтирования. Контейнер, который монтирует саму точку, после перезапуска zurg остаётся с мёртвым монтированием, и каждое чтение возвращает `Socket not connected`. [Шаг про Docker в руководстве по торрентам](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker) объясняет, почему. `PUID` и `PGID` требуют такой же аккуратности, как и для Whisparr: [см. там](whisparr.md#2-run-whisparr).

На macOS и Windows этот compose-файл не подходит, по причине, которую объясняет [шаг 8 руководства по Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). Запускайте Bazarr из исходников (`python bazarr.py`) на той же машине, что Radarr и zurg, от того же пользователя, что и zurg, следуя собственным страницам Bazarr для [macOS](https://wiki.bazarr.media/Getting-Started/Installation/MacOS/macos/) и [Windows](https://wiki.bazarr.media/Getting-Started/Installation/Windows/source/). В Windows не используйте установщик Bazarr: он настраивает Bazarr как службу Windows, а служба не видит диск `Z:` zurg ([почему](sonarr-radarr.md#before-you-start)). Вместо этого запускайте `bazarr.py` из своей залогиненной сессии. Тогда Bazarr видит каждый фильм по тому пути, который сообщает Radarr, и path mapping не нужен. Протестирован только Docker-образ выше.

Откройте `http://<your server>:6767`.

## 2. Подключите его к Radarr и Sonarr {#2-connect-it-to-radarr-and-sonarr}

**Settings → Radarr**: включи его и введи адрес Radarr, порт и API-ключ (в Radarr это **Settings → General**). Если запускаешь из контейнера, используй LAN-IP хоста, а не `localhost`. Нажми **Test**, затем **Save**. Sonarr настраивается так же, в разделе **Settings → Sonarr**.

## 3. Языки {#3-languages}

**Settings → Languages**: добавь нужные языки, создай из них языковой профиль и сделай его профилем по умолчанию для фильмов и для сериалов. После этого Bazarr запрашивает субтитры для всего, что уже есть в Radarr и Sonarr.

## 4. Провайдеры {#4-providers}

**Settings → Providers**: добавьте сайты с субтитрами, которые ищет Bazarr. Для некоторых нужен аккаунт, для некоторых нет. Два момента, с которыми мы столкнулись при тестировании:

- **subf2m** требует User-Agent в настройках провайдера. Без него Bazarr приостанавливает его на 12 часов после первого поиска.
- Bazarr приостанавливает провайдера, который какое-то время выдаёт ошибки, и если все провайдеры приостановлены, поиск ничего не находит. **System → Providers** показывает их список и сбрасывает приостановку.

## 5. Встроенные субтитры {#5-embedded-subtitles}

Многие релизы уже содержат английскую дорожку внутри видеофайла. Bazarr считает, что английский есть, и ничего не скачивает. Если всё равно нужен файл субтитров, выключите **Use Embedded Subtitles** в разделе **Settings → Subtitles**.

## 6. Проверьте один {#6-check-one}

Страница **Movies** в Bazarr показывает, каких субтитров не хватает каждому фильму. Найдите субтитры прямо оттуда, и файл появится рядом с видео (на Windows откройте ту же папку `Z:\__magic__\movies` в Explorer):

```bash
$ ls "/mnt/zurg/__magic__/movies/Night of the Living Dead (1968)/"
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.en.hi.srt
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.mkv
```

Субтитры хранятся как обычный файл на диске zurg, в папке `data/local/__magic__/` (см. [Sidecars](magic.md#sidecars-nfo-posters-subtitles)). Видео по-прежнему воспроизводится из вашего аккаунта.

## В rex {#in-rex}

zurg отправляет rex каждый субтитр, который лежит рядом с видео в `__magic__`, независимо от того, куда Radarr или Sonarr переместили это видео. zurg проверяет новые, изменённые и удалённые субтитры раз в минуту, поэтому субтитр, который сохранит Bazarr, появится в rex примерно через минуту, а удалённый исчезнет так же быстро. Больше ничего настраивать не нужно, кроме `rex_url` в конфиге zurg. Его вы уже задали по [гайду по rex](../../rex/with-zurg.md).

Имя файла говорит, что это за субтитр, так же, как Plex читает имена субтитров:

| Имя файла заканчивается на | rex показывает |
|---|---|
| `.srt` | Unknown (SRT External) |
| `.en.srt` | English (SRT External) |
| `.en.forced.srt` | English Forced (SRT External) |
| `.en.hi.srt`, `.en.sdh.srt`, `.en.cc.srt` | English SDH (SRT External) |

Читаются файлы `.srt`, `.ass`, `.ssa`, `.smi` и `.txt`. Язык может быть двух- или трёхбуквенным кодом (`en`, `eng`, `de`, `ger`). Имя перед ним должно совпадать с именем самого видео, как его записывает Bazarr.

В rex попадают только субтитры из `__magic__`. Субтитр, сохранённый рядом с файлом в другой папке zurg, например `/mnt/zurg/movies`, не отправляется.

rex умеет находить субтитры и сам: кнопка **Search Subtitles** в любом приложении Plex, Bazarr для этого не нужен. См. [субтитры в rex](../../rex/with-zurg.md#subtitles).
