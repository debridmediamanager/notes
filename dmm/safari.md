---
label: DMM buttons in Safari
icon: browser
order: 20
---

# DMM buttons in Safari

The DMM browser extension puts a **DMM🔎** button on IMDb, Trakt, Letterboxd, MDBList, JustWatch, TMDB, MyAnimeList and other movie, TV and anime sites that opens the title on DMM. Next to magnet links it adds a **DMM🧲** button that adds the torrent to your DMM library.

On Chrome and Firefox, install the extension from the [Chrome Web Store](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm) or [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/). Safari has no DMM extension, but the same code is published as a userscript on [Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager). A userscript manager runs it in Safari on a Mac, iPhone or iPad.

Pick one manager:

| Manager | Price | Runs on | Updates the script |
|---|---|---|---|
| [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) | Free | Mac, iPhone, iPad | When you tap **Update** in its popup |
| [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) | $2.99 | Mac, iPhone, iPad | On its own |

## With Userscripts

1. Install [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) from the App Store and open it once.
2. Turn the extension on:
   - **Mac:** Safari > **Settings** > **Extensions**, tick **Userscripts**.
   - **iPhone and iPad:** **Settings** > **Apps** > **Safari** > **Extensions** > **Userscripts**, turn on **Allow Extension**.
3. Let it run on every site. Magnet links can be on any site, so the script has to run everywhere.
   - **Mac:** in the same **Extensions** pane, click **Edit Websites…** and set **When visiting other websites** to **Allow**.
   - **iPhone and iPad:** on the same **Userscripts** screen, set **All Websites** to **Allow**.
4. In Safari, open the [DMM userscript file](https://update.greasyfork.org/scripts/463268/Debrid%20Media%20Manager.user.js). It shows as plain text.
5. Open the Userscripts popup: its toolbar button on a Mac, or the **aA** button in the address bar on iPhone. Tap the install prompt it shows and confirm.

To update later, open the Userscripts popup and tap **Update** when it lists the DMM script.

## With Tampermonkey

1. Install [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) from the App Store.
2. Turn it on and let it run on every site, as in steps 2 and 3 above, with **Tampermonkey** in place of **Userscripts**.
3. In Safari, open the script's [Greasy Fork page](https://greasyfork.org/en/scripts/463268-debrid-media-manager) and click **Install this script**.
4. Tampermonkey opens its install page. Click **Install**.

Tampermonkey checks for a new version once a day.

## Check it works

Open [Dune: Part Two on Letterboxd](https://letterboxd.com/film/dune-part-two/). A teal **DMM🔎** button appears next to the title, and it opens the film on DMM.

No button? Check these:

- The manager's popup lists **Debrid Media Manager** and its switch is on.
- Safari lets the manager run on that site. When it asks, choose **Always Allow on Every Website**.
- The page has finished loading. Sites such as TMDB, Wikipedia and AniList show the button a moment after the page does.
