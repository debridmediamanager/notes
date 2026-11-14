# Используйте DMM в Stremio с DMM Cast {#use-dmm-in-stremio-with-dmm-cast}

DMM Cast — это аддон Debrid Media Manager для Stremio. Через него DMM появляется в Stremio: вы выбираете релиз в DMM, нажимаете **Cast**, и Stremio показывает его как поток, который воспроизводится с вашего аккаунта debrid или Easynews. Вкратце: войдите в DMM, откройте страницу Cast вашего провайдера, установите аддон в Stremio, а затем нажмите **Cast** на любом фильме или сериале.

Cast здесь означает аддон DMM. Это не Chromecast и не дублирование экрана.

## Что понадобится {#what-you-need}

- Вход в DMM через Real-Debrid, TorBox, AllDebrid, Premiumize, Offcloud, Debrid-Link или Easynews.
- Stremio. [Stremio Web](https://web.stremio.com) работает без аккаунта Stremio.

Спонсорство не требуется.

## Настройка {#set-it-up}

1. Войдите на [debridmediamanager.com](https://debridmediamanager.com) через свой провайдер. Easynews входит через **Settings**.
2. На главной странице DMM нажмите **Cast for RD**, **Cast for TB** и так далее. Если вы вошли в несколько аккаунтов, там будет одна строка **Cast** с кнопкой для каждого провайдера. У каждого провайдера есть своя страница Cast:

   | Провайдер | Страница Cast |
   |---|---|
   | Real-Debrid | [debridmediamanager.com/stremio](https://debridmediamanager.com/stremio) |
   | TorBox | [debridmediamanager.com/stremio-torbox](https://debridmediamanager.com/stremio-torbox) |
   | AllDebrid | [debridmediamanager.com/stremio-alldebrid](https://debridmediamanager.com/stremio-alldebrid) |
   | Premiumize | [debridmediamanager.com/stremio-premiumize](https://debridmediamanager.com/stremio-premiumize) |
   | Offcloud | [debridmediamanager.com/stremio-offcloud](https://debridmediamanager.com/stremio-offcloud) |
   | Debrid-Link | [debridmediamanager.com/stremio-debridlink](https://debridmediamanager.com/stremio-debridlink) |
   | Easynews | [debridmediamanager.com/stremio-easynews](https://debridmediamanager.com/stremio-easynews) |

   ![Страница DMM Cast для Premiumize, адрес аддона размыт](../assets/dmm-stremio/01-dmm-cast-page.webp)

3. Нажмите **Install (web)**. Откроется Stremio Web с аддоном. Нажмите там **Install**.

   ![Stremio Web предлагает установить DMM Cast](../assets/dmm-stremio/02-stremio-install.webp)

   Для другого Stremio скопируйте адрес, который показан под кнопками, и добавьте его там. В Stremio Web это **Addons** → **Add addon** → вставьте → **Add** → **Install**. Адрес привязан к вашему аккаунту, поэтому никому его не показывайте.

4. Вернитесь в DMM, найдите фильм или сериал и откройте его. Релизы, которые уже есть у вашего провайдера, получают кнопку **Cast**: **Cast (RD)**, **Cast (TB)**, **Cast (AD)**, **Cast (PM)**, **Cast (OC)** или **Cast (DL)**. Нажмите её. DMM покажет **Cast started in Stremio** (для сериала — **Casting succeeded.** и сколько серий отправлено) и попытается открыть тайтл в вашем приложении Stremio.

   ![Нажатие Cast (PM) в DMM](../assets/dmm-stremio/03-dmm-cast-button.webp)

5. Откройте тайтл в Stremio. Ваш cast будет в списке как **DMM Cast PM (Yours)** (RD, TB и так далее для других провайдеров). Нажмите на него, чтобы начать воспроизведение.

   ![Stremio со списком cast как DMM Cast PM (Yours)](../assets/dmm-stremio/04-stremio-streams.webp)

## Что ещё вы получаете в Stremio {#what-else-you-get-in-stremio}

- **DMM Cast PM ✨ · Cast a file inside a torrent** на каждом фильме и эпизоде. Открывает этот тайтл в DMM, так что можно скастить релиз прямо оттуда.
- Ещё до пяти стримов из чужих кастов и из релизов, которые уже есть у вашего провайдера. Число задаётся в **Other streams limit** на странице Cast. Спонсоры могут поднять его до десяти.
- Ряды на **Board** в Stremio: **DMM PM Movies** и **DMM PM TV Shows** содержат ваши касты. **DMM PM Library** содержит всё из вашего аккаунта, и каждый элемент открывается со своими файлами. У Easynews нет ряда Library.
- Не хотите рядов? Установите аддон через **Without catalogs** → **Install (web)**. Стримы всё равно будут показываться.
- **Manage Casted Links** на странице Cast показывает ваши касты. Отметьте нужные (или **Select All**) и нажмите **Delete Selected**, чтобы убрать их из Stremio.
- **Hide "Cast a file inside a torrent" option** на странице Cast убирает ряд ✨.

На Debrid-Link каст добавляет релиз в ваш аккаунт. Если его там ещё нет, начинается настоящая загрузка, и на это уходит один из ваших 50 торрентов на день.

## Если что-то не работает {#when-something-is-wrong}

| Что вы видите | Что делать |
|---|---|
| Только **DMM Cast PM ✨ · Cast a file inside a torrent** (RD, TB…) и никаких других потоков | Для этого тайтла ещё ничего не было скастено. Нажмите на эту строку: откроется тайтл на DMM. Нажмите **Cast** у нужного релиза, а затем снова откройте тайтл в Stremio. |
| **⚠️ DMM Cast · Set up DMM Cast for Premiumize again** (или ваш провайдер) как единственный поток | Аддон в Stremio больше не совпадает с вашим входом в DMM. Нажмите на него, чтобы открыть страницу Cast, войдите, затем удалите старый аддон из Stremio и установите его заново со страницы. |
| **Real-Debrid Required. You must be logged in with Real-Debrid to use the Stremio Cast feature.** (или TorBox, Easynews…) | Вы не вошли в этого провайдера на DMM или открыли страницу Cast другого провайдера. Нажмите **Login with …** или используйте кнопку **Cast for …** на главной странице DMM. |
| **No episodes in this release on Premiumize** | DMM не смог сопоставить файлы этого релиза с эпизодами. Скастите другой релиз. |
| Адрес аддона, вставленный в строку поиска вверху Stremio Web, ничего не делает | Эта строка только ищет. Используйте **Addons** → **Add addon**. |

Застряли? Спросите на форуме **dmm-cast-support** в [Discord](https://discord.com/invite/7u4YjMThXP). В [Получение помощи](../guides/remote-help.md) написано, что указать.

## Вопросы {#questions}

### Можно ли искать DMM в Stremio? {#can-i-search-dmm-in-stremio}

Нет. DMM Cast не добавляет поиск в Stremio, и в поиске Stremio из него ничего не показывается. Ищите на [debridmediamanager.com](https://debridmediamanager.com) и нажмите **Cast**. Из тайтла, который уже открыт в Stremio, строка ✨ переведёт вас к этому тайтлу на DMM.

### Работает ли это на моём телевизоре, Fire TV или телефоне? {#does-it-work-on-my-tv-fire-tv-or-phone}

Трансляции сохраняются в DMM, а не на устройстве, с которого вы их транслируете. Каждый Stremio, в котором есть адрес вашего аддона, их показывает. Запустите трансляцию с телефона или компьютера, а затем выберите поток **(Yours)** в Stremio там, где вы смотрите.

### Какие провайдеры работают? {#which-providers-work}

Real-Debrid, TorBox, AllDebrid, Premiumize, Offcloud, Debrid-Link и Easynews. У каждого есть своя страница Cast и свой аддон. Установите по одному на каждый аккаунт, который хотите подключить к Stremio.

### Почему Stremio показывает только Cast и нет потока? {#why-does-stremio-show-only-cast-and-no-stream}

Для этого тайтла пока ничего не добавлено. Нажмите на строку с ✨, добавьте релиз в DMM, а затем снова откройте тайтл в Stremio.

### Можно ли воспроизводить всю мою debrid-библиотеку в Stremio? {#can-i-play-my-whole-debrid-library-in-stremio}

Да. Строка **DMM Library** на доске Stremio показывает всё, что есть в вашем аккаунте (кроме Easynews). Откройте элемент, чтобы увидеть его файлы.

### Нужна ли мне спонсорская подписка? {#do-i-need-a-sponsorship}

Нет. Для DMM Cast спонсорство поднимает только **Other streams limit** с пяти до десяти. Получите свой API-ключ DMM на [gatekeeper](https://gatekeeper.debridmediamanager.com/) и вставьте его в **Settings** в DMM.
