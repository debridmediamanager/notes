# Kometa с rex {#kometa-with-rex}

[Kometa](https://kometa.wiki) создаёт коллекции, добавляет значки на постеры (4K, HDR, рейтинги) и заполняет рейтинги и жанры на сервере Plex. rex отвечает Kometa так же, как это делает сервер Plex, поэтому один и тот же конфиг работает и с вашими библиотеками rex.

Всё, что ниже, проверено 2026-10-23 на Kometa 2.5.3 (образ Docker `kometateam/kometa`) и на заявленном rex с фильмами и сериалом.

## Перед началом {#before-you-start}

| Что нужно | Зачем |
|---|---|
| rex настроен и добавлен в аккаунт Plex, как описано в [Add it to a Plex account](any-source.md#step-3-add-it-to-a-plex-account) | Kometa редактирует библиотеку, и делать это может только тот аккаунт, к которому привязан rex. Непривязанный rex никому не служит |
| rex nightly **2026.10.24 или новее** | Обновление, как в разделе [Updating](any-source.md#updating) у rex |
| Docker на любой машине, с которой есть доступ к rex | Kometa работает в контейнере. В документации Kometa есть [другие способы установки](https://kometa.wiki/en/latest/kometa/install/overview/) |
| Бесплатный ключ TMDb API | Он нужен самой Kometa, даже если rex его не требует. Получить его можно в **Settings → API** на themoviedb.org, как описано на [странице TMDb getting started](https://developer.themoviedb.org/docs/getting-started) |

## 1. Получите токен rex {#1-get-rexs-token}

Kometa входит в rex с помощью токена Plex. Используй тот токен, который rex получил при регистрации. На машине с rex:

+++ Linux и macOS
```bash
grep -o '"token": "[^"]*"' ~/rex/claim_state.json
```
+++ Windows
```powershell
(Select-String '"token": "[^"]*"' $HOME\rex\claim_state.json).Matches.Value
```
+++

Если rex запущен в [Docker](any-source.md#run-rex-in-docker), файл доступен только root: `sudo grep -o '"token": "[^"]*"' ~/rex/config/claim_state.json`.

**Что ты должен увидеть.** Одну строку, `"token": "..."`. Скопируй то, что находится между второй парой кавычек. Относись к нему как к паролю: он открывает весь сервер. Если ты когда-нибудь зарегистрируешь rex заново, токен изменится, и Kometa понадобится новый.

**Не токен твоего собственного аккаунта.** В разделе [Поделиться с собственным аккаунтом](any-source.md#share-it-with-your-own-account) твой аккаунт получил rex как общий доступ. Общий доступ позволяет только смотреть, но не редактировать, поэтому с его токеном Kometa остановится с ошибкой `Plex Token is read only`, а если общий доступ разрешает загрузки, она упадёт на первом же изменении.

## 2. Напишите конфиг Kometa {#2-write-kometas-config}

Создай папку для Kometa, например `~/kometa/config` (`$HOME\kometa\config` в Windows), и положи в неё `config.yml` с таким содержимым:

```yaml
libraries:
  Movies:
    collection_files:
      - default: genre
    overlay_files:
      - default: resolution
      - default: ratings
        template_variables:
          rating1: critic
          rating1_image: tmdb
    operations:
      mass_critic_rating_update: tmdb
  TV Shows:
    overlay_files:
      - default: resolution
plex:
  url: http://192.168.1.20:32400
  token: the token from step 1
tmdb:
  apikey: your TMDb API key
```

- `url` — это LAN IP и порт rex, тот адрес из [Установка rex](any-source.md#step-1-install-rex). Не `127.0.0.1` и не `localhost`: внутри контейнера Kometa эти адреса указывают на сам контейнер.
- Имена под `libraries:` должны точно совпадать с библиотеками rex: **Movies** и **TV Shows**, плюс любые, которые ты добавил или переименовал. Если какую-то библиотеку Kometa трогать не должен, просто не добавляй её.

Это только небольшое начало. В документации Kometa есть [все стандартные коллекции и оверлеи](https://kometa.wiki/en/latest/defaults/guide/), а свои файлы с коллекциями тоже работают.

## 3. Запустите один раз {#3-run-it-once}

+++ Linux и macOS
```bash
docker run --rm -v ~/kometa/config:/config kometateam/kometa:latest --run
```
+++ Windows
```powershell
docker run --rm -v "$HOME\kometa\config:/config" kometateam/kometa:latest --run
```
+++

`--run` заставляет Kometa сделать один проход прямо сейчас и завершиться. Без него Kometa остаётся запущенной и ждёт своего ежедневного расписания.

**Что you should see.** В выводе Kometa для каждой библиотеки:

```
Movies Library Connection Successful
...
Overlays Applied: Overlay File (0) 1080P, Overlay File (1) Rating1Fresh
```

В приложении Plex у библиотеки фильмов есть вкладка **Collections** с коллекциями по жанрам, а постеры получают свои значки. Твой аккаунт и все, с кем ты поделился rex, видят одни и те же коллекции и значки. Первый запуск на большой библиотеке занимает некоторое время: Kometa читает каждый тайтл и перерисовывает каждый постер, на который добавляет значок.

## Если не работает {#if-it-does-not-work}

| Что говорит Kometa | Что это значит |
|---|---|
| `Plex Token is read only. Please get a new token` | rex ещё не добавлен в аккаунт Plex, или токен твой собственный, а не тот, что из шага 1 |
| Kometa подключается, но каждое изменение падает | Токен твой собственный. Используй тот, что из шага 1 |
| `url_poster failed to update poster` | Машина с rex не может достучаться до сайта, где лежит картинка |
| `Plex URL is probably invalid` или таймаут | `url` не доходит до rex с машины, где запущен Kometa. Открой `http://192.168.1.20:32400/identity` с этой машины: должен показаться `machineIdentifier` rex-а |
| `Plex Error: Plex Library '...' not found. Options: [...]` | Имя под `libraries:` не совпадает. Скопируй одно из имён из выведенного списка |

Всё ещё не получается? Спроси в форуме **rex-support** в [Discord](https://discord.com/invite/7u4YjMThXP). В [Получение помощи](../guides/remote-help.md) написано, что стоит указать.

## Что Kometa видит, а что нет {#what-kometa-can-and-cannot-see}

Kometa сопоставляет названия по TMDb, TVDb и IMDb id, которые rex показывает для них. Название, которое его источник не распознал (в нём всё ещё имя файла и нет постера), id не имеет, поэтому Kometa пропускает его во всём, что собирается по этим id. Сначала исправь такое название через Fix Match в приложении Plex.

Протестировано на rex: коллекции по поиску по названию, по TMDb id и умные коллекции; стандартные коллекции жанров с постерами; оверлеи разрешения и рейтингов; обновление оценок критиков и жанров из TMDb. Пока не тестировалось: плейлисты, музыкальные библиотеки и другие операции Kometa. Если что-то сломается, лог самой Kometa покажет запрос, который это вызвал, и о таком стоит написать в Discord.
