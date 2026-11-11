# Кнопки DMM в Safari {#dmm-buttons-in-safari}

DMM-расширение для браузера добавляет кнопку **DMM🔎** на сайты с фильмами и сериалами. Она открывает нужный тайтл в DMM. Рядом с magnet-ссылками появляется кнопка **DMM🧲**, которая добавляет торрент в твою библиотеку DMM.

В Chrome и Firefox установи [расширение для Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm) или [дополнение для Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/). Safari использует тот же код как [пользовательский скрипт на Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager) с менеджером userscript.

Выбери один менеджер:

| Менеджер | Цена | Работает на | Обновляет скрипт |
|---|---|---|---|
| [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) | Бесплатно | Mac, iPhone, iPad | Когда ты нажмёшь **Update** в его всплывающем окне |
| [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) | $2.99 | Mac, iPhone, iPad | Самостоятельно |

## С Userscripts {#with-userscripts}

1. Установите [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) из App Store и откройте его один раз.
2. Включите расширение:
   - **Mac:** Safari > **Settings** > **Extensions**, поставьте галочку у **Userscripts**.
   - **iPhone и iPad:** **Settings** > **Apps** > **Safari** > **Extensions** > **Userscripts**, включите **Allow Extension**.
3. Разрешите работу на всех сайтах. Magnet-ссылки могут быть на любом сайте, поэтому скрипт должен работать везде.
   - **Mac:** в той же вкладке **Extensions** нажмите **Edit Websites…** и поставьте **When visiting other websites** в значение **Allow**.
   - **iPhone и iPad:** на том же экране **Userscripts** поставьте **All Websites** в значение **Allow**.
4. В Safari откройте [файл пользовательского скрипта DMM](https://update.greasyfork.org/scripts/463268/Debrid%20Media%20Manager.user.js). Он отобразится как обычный текст.
5. Откройте всплывающее окно Userscripts: кнопка на панели инструментов на Mac или кнопка **aA** в адресной строке на iPhone. Нажмите на предложение установки, которое он покажет, и подтвердите.

Чтобы обновить позже, откройте всплывающее окно Userscripts и нажмите **Update**, когда там появится скрипт DMM.

## С Tampermonkey {#with-tampermonkey}

1. Установите [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) из App Store.
2. Включите его и пусть работает на всех сайтах, как в шагах 2 и 3 выше, только вместо **Userscripts** используйте **Tampermonkey**.
3. В Safari откройте [страницу скрипта на Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager) и нажмите **Install this script**.
4. Tampermonkey откроет свою страницу установки. Нажмите **Install**.

Tampermonkey проверяет наличие новой версии раз в день.

## Проверьте, что всё работает {#check-it-works}

Откройте [Dune: Part Two на Letterboxd](https://letterboxd.com/film/dune-part-two/). Рядом с названием появится бирюзовая кнопка **DMM🔎**, и по ней фильм откроется в DMM.

Кнопки нет? Проверьте следующее:

- В всплывающем окне менеджера расширений есть **Debrid Media Manager**, и его переключатель включён.
- Safari разрешает менеджеру работать на этом сайте. Когда он спросит, выберите **Always Allow on Every Website**.
- Страница полностью загрузилась. Такие сайты, как TMDB, Wikipedia и AniList, показывают кнопку чуть позже, уже после загрузки страницы.
