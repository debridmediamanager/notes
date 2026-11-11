# DMM

[Debrid Media Manager](https://debridmediamanager.com) помогает находить фильмы и сериалы и сохранять их в вашей библиотеке debrid.

Расширение браузера DMM добавляет кнопку на IMDb, Trakt и другие сайты о фильмах и сериалах. [Кнопки DMM в Safari](safari.md) объясняет, как его настроить в Safari.

DMM также работает с другими проектами:

- **zurg** спрашивает у DMM, какой это фильм или эпизод для каждого файла. Спонсор получает ключ API DMM на [gatekeeper](https://gatekeeper.debridmediamanager.com/). Без него zurg опирается на имена файлов, и совпадает меньше названий. [rex с zurg](../rex/with-zurg.md#why-dmm-places-the-files) объясняет разницу.
- **Sonarr Radarr и Prowlarr** могут искать в DMM как в торрент-индексаторе Torznab или Usenet-индексаторе Newznab. Для обоих нужно активное спонсорство и ключ API DMM. Настраиваются они на страницах [Torznab](https://debridmediamanager.com/torznab) и [Newznab](https://debridmediamanager.com/newznab).
- **Ваш список желаемого**: нажмите **Want** или подпишитесь на список Trakt или MDBList. zurg загрузит его, а также новые эпизоды по мере выхода. Нужно спонсорство. См. [Список желаемого DMM](../zurg/guides/dmm-wanted.md).
- **Seerr Overseerr и Jellyseerr** могут использовать DMM вместо Radarr и Sonarr. Тогда запросы попадают в ваш список желаемого, и zurg их загружает. Нужно спонсорство. См. [Seerr через DMM](seerr.md).
- **rex-direct** даёт получившему доступ rex собственный адрес и сертификат. См. [rex-direct](../rex/any-source.md#rex-direct).

Всё, что открывает спонсорство, и где что настраивается, описано в разделе [Что даёт спонсорство](../guides/sponsorship.md).

Застряли? Спросите на форуме **dmm-support** в [Discord](https://discord.com/invite/7u4YjMThXP). В разделе [Как получить помощь](../guides/remote-help.md) написано, что стоит указать.
