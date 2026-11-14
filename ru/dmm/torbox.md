# TorBox в DMM {#torbox-in-dmm}

DMM работает с платным тарифом TorBox: Essential, Standard или Pro. Вставьте свой API-ключ с [torbox.app/settings](https://torbox.app/settings) на странице **Connect Torbox** в DMM, а затем выполните поиск: релизы, которые уже есть у TorBox, получат метку **Instant TB**. На бесплатном тарифе нет доступа к API, поэтому DMM с ним работать не может, а отправка релизов Usenet в TorBox требует тариф Pro.

## Вход {#sign-in}

1. На [debridmediamanager.com](https://debridmediamanager.com) нажмите **Login with Torbox**. Уже вошли через другой сервис? Откройте **Debrid services** на главной странице и нажмите **Torbox Login**.
2. Нажмите **Get API Key from Torbox**. Откроется [torbox.app/settings](https://torbox.app/settings), где находится ваш API-ключ.
3. Вставьте ключ в поле **API Key** и нажмите **Save API Key**.

![Страница DMM Connect Torbox отклоняет ключ бесплатного тарифа, ключ размыт](../assets/dmm-torbox/01-free-plan.webp)

Когда вы вошли, на главной странице видны **Cast for TB** и **Requests**, а в **Debrid services** ваш аккаунт TorBox отмечен значком ✓. Нажмите на него, чтобы увидеть тариф и дату окончания, или чтобы **Add another account** или **Logout**.

## Что умеет каждый тариф {#what-each-plan-can-do}

| | Free | Essential или Standard | Pro |
|---|---|---|---|
| Вход в DMM | Нет | Да | Да |
| **Instant TB**, **DL with TB**, библиотека и **Cast (TB)** | Нет | Да | Да |
| Отправка Usenet-релизов в TorBox | Нет | Нет | Да |
| Одновременные загрузки (активные слоты TorBox) | 1 | 3 или 5 | 10 |

Если войти с ключом бесплатного плана, DMM покажет **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** На [странице тарифов](https://torbox.app/pricing) TorBox API-доступ на Free не входит, а Usenet есть только на Pro.

## Поиск того, что уже есть в TorBox {#find-what-torbox-already-has}

1. Найдите фильм или сериал и откройте его.
2. DMM спрашивает у TorBox, какие релизы уже есть в кэше. Они помечены **Instant TB** и **Cast (TB)** и выводятся первыми. Чип **TB ✓** над результатами показывает только их. Он пишет `is:tb` в поле фильтра; нажмите его ещё раз, чтобы показать всё.
3. Нажмите **Instant TB**. Релиз сразу появляется в вашей библиотеке TorBox.

![Night of the Living Dead (1968) on DMM with TorBox: Instant TB, Cast (TB) and DL with TB](../assets/dmm-torbox/02-results.webp)

Релизы, которых нет у TorBox, показывают **DL with TB**. Если нажать её, TorBox сначала скачает релиз, и на время загрузки занимает один из ваших активных слотов. **No seeders** рядом с размером означает, что сейчас никто его не раздаёт, поэтому он может так и не докачаться. TorBox всегда добавляет релиз целиком: выбирать отдельные файлы нельзя.

## Твоя библиотека {#your-library}

Нажмите **Library**. Там показан список ваших торрентов и веб-загрузок TorBox.

- **TB Add** открывает **Add to your TB library**. Вставьте magnet-ссылки, загрузите файлы `.torrent` или вставьте прямые ссылки на скачивание, которые TorBox загрузит как веб-загрузки.
- **Backup** сохраняет ваш список в файл. **TB Restore** добавляет сохранённый список обратно.
- Всё остальное работает так же, как у любого сервиса: см. [your library](index.md#your-library).

Загрузки Usenet, которые вы отправили в TorBox, не отображаются в библиотеке DMM. Найти их можно на сайте TorBox, в строке **DMM TB Library** в DMM Cast в Stremio или через [TorBox hosted Usenet](../zurg/providers/torbox-nzb.md) в zurg.

## Смотреть в Stremio {#watch-in-stremio}

Нажмите **Cast for TB** на главной странице и установите аддон оттуда. Затем нажмите **Cast (TB)** на любом релизе, который TorBox уже закешировал. Все шаги описаны в [DMM в Stremio](stremio.md).

В Stremio аддон называется **DMM Cast for TorBox**. Его строка **DMM TB Library** показывает ваши торренты TorBox, а также завершённые загрузки из веба и Usenet.

## Отправка релизов Usenet в TorBox (Pro) {#send-usenet-releases-to-torbox-pro}

1. Откройте фильм или сериал и нажмите вкладку **Usenet**.
2. Если у вас TorBox Pro, над списком будет заголовок **Send to TorBox**, а у каждого релиза есть кнопка **TorBox**. Нажмите её.
3. DMM покажет, что TorBox сделал с релизом:
   - **Usenet → TorBox: TorBox already had it, it is ready in your TorBox Usenet downloads.**
   - **Usenet → TorBox: TorBox is downloading it, usually ready within a few minutes.**
   - **Usenet → TorBox: queued, it starts when one of your TorBox active slots frees up.**

![DMM's Usenet tab with TorBox Pro: Send to TorBox](../assets/dmm-torbox/03-usenet-tab.webp)

Вы также вошли в Real-Debrid? Тогда над списком будет заголовок **Send to Real-Debrid or TorBox** и обе кнопки. Значок файла в конце строки вместо этого сохраняет NZB. Если вы только начинаете работать с Usenet, сначала прочитайте [Usenet для начинающих](../guides/usenet-for-beginners.md).

TorBox удаляет загрузку Usenet через 30 дней после того, как закэширует её. Чтобы вернуть её, отправьте релиз снова.

## Заполнение запросов через TorBox {#fill-requests-with-torbox}

Пользователи Real-Debrid просят релизы на доске запросов DMM — [request board](https://debridmediamanager.com/requests). Нажмите **Requests** на главной странице, затем **Fulfil** у релиза, который TorBox уже закешировал. Он уходит из вашего TorBox к ним на Real-Debrid. За каждые 10 отправок вы получаете 7 дней бонусов спонсора DMM: см. [earn it without paying](../guides/sponsorship.md#earn-it-without-paying).

## Если что-то не работает {#when-something-is-wrong}

| Что вы видите | Что делать |
|---|---|
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Этот ключ от бесплатного тарифа TorBox. Оплатите или продлите подписку на TorBox, затем войдите снова. |
| **Failed to refresh torbox: Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Ваш платный тариф закончился после входа. Продлите его на TorBox. |
| **API Error: Request failed with status code 403. Status: 403** | TorBox не принял этот ключ. Скопируйте его заново с [torbox.app/settings](https://torbox.app/settings), целиком. |
| Нет кнопки **TorBox** на вкладке Usenet | Отправка Usenet-релизов в TorBox требует Pro. На тарифах Essential и Standard этой кнопки нет. |
| **Usenet → TorBox: TorBox Usenet needs a Pro plan** | TorBox отклонил NZB, потому что тариф не Pro. |
| Только **DL with TB**, без **Instant TB** | На TorBox нет кэша для этих релизов. Нажмите на нужный и дождитесь загрузки или выберите другой релиз. |
| Показываются только релизы **Instant TB** | Включен чип **TB ✓** (`is:tb` в поле фильтра). Нажмите его еще раз или нажмите **Reset**. |
| **No torrents found yet. Use Want above to have zurg fetch it once one turns up, or try the Usenet tab.** | В DMM пока нет торрентов для этого тайтла. Новые серии могут появляться не сразу. Попробуйте вкладку **Usenet** или зайдите позже. |
| В Stremio: **⚠️ TorBox refused your account** | TorBox принимает ключ аддона, но не отдает контент для аккаунта, обычно потому что тариф закончился. Проверьте на [torbox.app/settings](https://torbox.app/settings). На DMM ничего менять не нужно. |
| zurg: `Acquisition: dmm-torbox refused the search: No TorBox key linked.` | Фиду спонсора `tb/cached` на [странице Torznab](https://debridmediamanager.com/torznab) в DMM нужен ваш ключ TorBox, привязанный в разделе **Link a provider key** на этой странице. Входа в TorBox на DMM недостаточно. `api_key` в zurg остается вашим API-ключом DMM. |

TorBox сейчас недоступен или проблема только у меня? Проверьте [Is TorBox Down Or Just Me?](https://debridmediamanager.com/is-torbox-down-or-just-me). Застряли? Спросите в форуме **dmm-support** в [Discord](https://discord.com/invite/7u4YjMThXP). В [разделе о помощи](../guides/remote-help.md) написано, что указать в вопросе.

## Вопросы {#questions}

### Нет поддержки TorBox на бесплатном тарифе zurg? {#is-torbox-support-not-on-the-free-tier-of-zurg}

Ладно. Публичная бесплатная сборка zurg работает только с Real-Debrid. TorBox, остальные сервисы и Usenet есть в ночных сборках zurg для спонсоров. Ваш план TorBox тоже должен быть платным, так как zurg не может работать с бесплатным аккаунтом. Настраивайте по инструкции [TorBox с zurg](../zurg/providers/torbox.md).

### zurg использует не тот тариф TorBox? {#zurg-uses-the-wrong-torbox-plan}

zurg-ночные сборки до 3 октября 2026 года считали тариф Pro у TorBox тарифом Standard и разрешали 5 загрузок одновременно вместо 10. Обновите zurg. Остальное — в [ограничениях TorBox для zurg](../zurg/providers/torbox-limits.md).

### Нет результатов поиска с TB? {#no-search-results-with-tb}

DMM-шный поиск одинаковый, с каким бы сервисом вы ни входили. TorBox лишь определяет, какие релизы помечены как **Instant TB**. Если ничего не видно, проверьте, что чип **TB ✓** выключен, перезагрузите страницу или нажмите **Show More Results** внизу. Свежий эпизод может пока не иметь торрентов на DMM: попробуйте вкладку **Usenet**.

### Можно ли использовать TorBox и Real-Debrid вместе? {#can-i-use-torbox-and-real-debrid-together}

Да. Войдите в оба сервиса, и у каждого релиза появятся кнопки обоих сервисов. Если TorBox уже закешировал релиз, а Real-Debrid — нет, появится кнопка **TB → RD**, которая отправит его с TorBox на ваш Real-Debrid.

### Какой тариф TorBox нужен для DMM? {#which-torbox-plan-do-i-need-for-dmm}

Любой платный тариф. Выбирайте Pro, если хотите отправлять релизы Usenet в TorBox или запускать 10 загрузок одновременно.
