# Seerr через DMM {#seerr-through-dmm}

Добавьте DMM в [Seerr](https://github.com/seerr-team/seerr) как Radarr и Sonarr. Одобренные запросы
попадают в ваш [список желаемого DMM](../zurg/guides/dmm-wanted.md), откуда zurg их забирает. Radarr
и Sonarr не нужны. Seerr должен только иметь доступ к debridmediamanager.com. Overseerr и Jellyseerr
работают так же.

Это для спонсоров. Seerr входит с API-ключом DMM из [gatekeeper](https://gatekeeper.debridmediamanager.com/).

## Что понадобится {#what-you-need}

- zurg читает ваш список желаемого из DMM с помощью `dmm_api_key` в `config.yml`. См. [Fetch what you want from DMM](../zurg/guides/dmm-wanted.md#what-you-need).
- Seerr настроен на ваш сервер Plex, Jellyfin или Emby, чтобы знать, какие эпизоды у вас есть.

## Добавление DMM как Radarr {#add-dmm-as-radarr}

В Seerr откройте **Settings → Services** и нажмите **Add Radarr Server**. Заполните поля так:

| Поле | Значение |
|---|---|
| Default Server | отмечено |
| 4K Server | не отмечено |
| Server Name | `DMM` или любое другое имя |
| Hostname or IP Address | `debridmediamanager.com` |
| Port | `443` |
| Use SSL | отмечено |
| API Key | ваш API-ключ DMM |
| URL Base | `/api/arr/radarr` |

Нажмите **Test**. Когда подключение заработает, выберите **Any** для Quality Profile и **/dmm** для Root Folder.
Minimum Availability не трогайте. Отметьте **Enable Scan** и нажмите **Add Server**.

![Диалог Add Radarr Server в Seerr, заполненный для DMM](../assets/seerr-dmm/01-seerr-radarr-dmm.webp)

Если Test не проходит, проверьте ключ: его можно найти на странице [Settings](https://debridmediamanager.com/settings) в DMM. Также DMM не будет принимать ключ, если срок вашей спонсорской подписки истёк.

## Добавление DMM как Sonarr {#add-dmm-as-sonarr}

Нажмите **Add Sonarr Server** и укажите URL Base `/api/arr/sonarr`. После **Test** выберите **Any** и `/dmm` для профилей и корневых папок. Отметьте **Enable Scan** и нажмите **Add Server**.

![Диалог Add Sonarr Server в Seerr, заполненный для DMM](../assets/seerr-dmm/02-seerr-sonarr-dmm.webp)

## Запросы {#requesting}

Запрашивайте как обычно. Одобренный фильм попадает в ваш список желаемого:

![Requesting a film in Seerr](../assets/seerr-dmm/03-seerr-request-movie.webp)

![The film shows as requested](../assets/seerr-dmm/04-seerr-movie-requested.webp)

Для сериала выберите нужные сезоны. Последующий запрос может добавить ещё сезоны. Чтобы следить за всем сериалом, включая новые сезоны, нажмите **Want all seasons** на его странице в DMM.

![Picking seasons of a show](../assets/seerr-dmm/05-seerr-request-seasons.webp)

Ваш [список желаемого](https://debridmediamanager.com/wanted) показывает каждое название в течение нескольких секунд. zurg подхватывает его в течение минуты.

## Что показывает Seerr {#what-seerr-shows}

Seerr читает список DMM один раз в день в **Radarr Scan** и **Sonarr Scan**. Чтобы запустить их прямо сейчас, откройте **Settings → Jobs & Cache** и нажмите **Run Now** рядом с каждым.

- **Фильм**, который zurg уже загрузил, отображается как **Available**.

  ![Загруженный фильм отображается как доступный](../assets/seerr-dmm/06-seerr-movie-available.webp)

- **Сериал** остаётся в статусе **Processing**, пока его эпизоды не появятся в вашей библиотеке Plex, Jellyfin или Emby, и сканирование Seerr на этом сервере их не найдёт. DMM не знает, какие эпизоды есть у zurg.

## Удаление тайтла {#removing-a-title}

Откройте тайтл в Seerr, нажмите кнопку с шестерёнкой и затем **Remove from Radarr** (или **Remove from Sonarr**). Так он уберётся из вашего списка желаемого. То, что zurg уже загрузил, останется в вашей библиотеке. **Open in Radarr** рядом открывает тайтл в DMM.

Застряли? Спросите в форуме **dmm-support** в [Discord](https://discord.com/invite/7u4YjMThXP). В [Getting help](../guides/remote-help.md) написано, что нужно указать.

## Seerr через DMM или собственный источник Seerr в zurg {#seerr-through-dmm-or-zurgs-own-seerr-source}

zurg также может читать сам Seerr, через [источник `seerr`](../zurg/guides/acquisition.md#configuration).
Используйте что-то одно, но не оба варианта:

- **Через DMM** Seerr нужен только доступ в интернет. Запросы появляются в вашем wanted list рядом с тем, что вы добавили через **Want**, а ежедневное сканирование Seerr отмечает фильмы, которые zurg загрузил, как доступные.
- **Собственный источник zurg** отличает запрос в 4K от запроса в 1080p, но zurg должен иметь доступ к Seerr.
