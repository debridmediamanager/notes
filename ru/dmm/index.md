# DMM

[Debrid Media Manager](https://debridmediamanager.com) помогает находить фильмы и сериалы и хранить их в твоей библиотеке debrid.

Чтобы смотреть в Stremio, добавь собственный аддон DMM, DMM Cast. В [DMM in Stremio](stremio.md) описано, как это сделать.

Расширение DMM для браузера добавляет кнопку на IMDb, Trakt и другие сайты про фильмы и сериалы. В [DMM buttons in Safari](safari.md) описана настройка для Safari.

DMM также работает с другими проектами:

- **zurg** спрашивает у DMM, какой фильм или эпизод соответствует каждому файлу. Спонсор получает ключ API DMM на [gatekeeper](https://gatekeeper.debridmediamanager.com/). Без него zurg опирается на имена файлов, и совпадает меньше названий. В [rex with zurg](../rex/with-zurg.md#why-dmm-places-the-files) объясняется разница.
- **Sonarr Radarr и Prowlarr** могут искать в DMM как в торрент-индексаторе Torznab или Usenet-индексаторе Newznab. Для обоих нужна активная спонсорская подписка и ключ API DMM. Настрой их на страницах [Torznab](https://debridmediamanager.com/torznab) и [Newznab](https://debridmediamanager.com/newznab).
- **Твой список желаемого**: нажми **Want** или подпишись на список Trakt или MDBList. zurg будет загружать его и новые эпизоды по мере выхода. Нужна спонсорская подписка. См. [DMM wanted list](../zurg/guides/dmm-wanted.md).
- **Seerr Overseerr и Jellyseerr** могут использовать DMM вместо Radarr и Sonarr. Тогда запросы попадают в твой список желаемого, и zurg их загружает. Нужна спонсорская подписка. См. [Seerr through DMM](seerr.md).
- **rex-direct** даёт заявленному rex собственный адрес и сертификат. См. [rex-direct](../rex/any-source.md#rex-direct).

Все возможности спонсорской подписки и то, где что настраивается, описаны в [What a sponsorship gives you](../guides/sponsorship.md).

Застрял? Спроси на форуме **dmm-support** в [Discord](https://discord.com/invite/7u4YjMThXP). В [Getting help](../guides/remote-help.md) написано, что стоит указать.
