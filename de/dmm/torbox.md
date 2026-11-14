# TorBox in DMM

DMM funktioniert mit einem bezahlten TorBox-Tarif: Essential, Standard oder Pro. Füge deinen API-Schlüssel von [torbox.app/settings](https://torbox.app/settings) auf der Seite **Connect Torbox** von DMM ein und starte dann die Suche. Releases, die TorBox schon hat, bekommen **Instant TB**. Der kostenlose Tarif hat keinen API-Zugriff, daher kann DMM ihn nicht nutzen, und um Usenet-Releases an TorBox zu senden, brauchst du Pro.

## Anmelden {#sign-in}

1. Auf [debridmediamanager.com](https://debridmediamanager.com) auf **Login with Torbox** klicken. Schon mit einem anderen Dienst angemeldet? Dann auf der Startseite **Debrid services** öffnen und **Torbox Login** drücken.
2. **Get API Key from Torbox** drücken. Dabei öffnet sich [torbox.app/settings](https://torbox.app/settings), dort findest du deinen API-Schlüssel.
3. Den Schlüssel in **API Key** einfügen und **Save API Key** drücken.

![DMM's Connect Torbox page turning down a free-plan key, key blurred](../assets/dmm-torbox/01-free-plan.webp)

Sobald du drin bist, zeigt die Startseite **Cast for TB** und **Requests** an, und **Debrid services** listet dein TorBox-Konto mit einem ✓. Wenn du darauf drückst, siehst du deinen Tarif und wann er abläuft, oder du kannst **Add another account** oder **Logout** wählen.

## Was jeder Tarif kann {#what-each-plan-can-do}

Wenn du dich mit einem Free-Plan-Schlüssel anmeldest, zeigt DMM **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** an. Die [Preisseite von TorBox](https://torbox.app/pricing) listet API-Zugriff im Free-Plan nicht auf, und Usenet gibt es nur im Pro-Plan.

| | Free | Essential or Standard | Pro |
|---|---|---|---|
| Sign in to DMM | No | Yes | Yes |
| **Instant TB**, **DL with TB**, the library and **Cast (TB)** | No | Yes | Yes |
| Send Usenet releases to TorBox | No | No | Yes |
| Downloads at once (TorBox's active slots) | 1 | 3 or 5 | 10 |

## Finde, was TorBox schon hat {#find-what-torbox-already-has}

1. Suche nach einem Film oder einer Serie und öffne sie.
2. DMM fragt TorBox, welche Releases es im Cache hat. Diese zeigen **Instant TB** und **Cast (TB)** und stehen ganz oben. Der **TB ✓**-Chip über den Ergebnissen zeigt nur diese. Er schreibt `is:tb` in das Filterfeld. Drück ihn noch einmal, um wieder alles anzuzeigen.
3. Drück auf **Instant TB**. Das Release ist sofort in deiner TorBox-Bibliothek.

![Night of the Living Dead (1968) auf DMM mit TorBox: Instant TB, Cast (TB) und DL with TB](../assets/dmm-torbox/02-results.webp)

Releases, die TorBox nicht hat, zeigen **DL with TB**. Wenn du darauf drückst, lädt TorBox das Release zuerst herunter. Das belegt so lange einen deiner aktiven Slots, wie der Download läuft. **No seeders** neben der Größe bedeutet, dass es gerade niemand teilt. Dann wird es vielleicht nie fertig. TorBox fügt immer das komplette Release hinzu. Einzelne Dateien kannst du nicht auswählen.

## Deine Bibliothek {#your-library}

Drück auf **Library**. Dort siehst du deine TorBox-Torrents und Web-Downloads.

- **TB Add** öffnet **Add to your TB library**. Hier kannst du Magnet-Links einfügen, `.torrent`-Dateien hochladen oder direkte Download-Links einfügen, die TorBox als Web-Downloads abruft.
- **Backup** speichert deine Liste in einer Datei. **TB Restore** fügt eine gespeicherte Liste wieder hinzu.
- Alles Weitere funktioniert wie bei jedem anderen Dienst: siehe [your library](index.md#your-library).

Usenet-Downloads, die du an TorBox geschickt hast, sind nicht in der DMM-Bibliothek. Du findest sie auf der TorBox-Website, in der Zeile **DMM TB Library** von DMM Cast in Stremio oder über [TorBox gehostetes Usenet](../zurg/providers/torbox-nzb.md) in zurg.

## In Stremio ansehen {#watch-in-stremio}

Drücke auf der Startseite auf **Cast for TB** und installiere das Addon von dort aus. Drücke dann auf **Cast (TB)** bei jedem Release, den TorBox bereits im Cache hat. Alle Schritte stehen in [DMM in Stremio](stremio.md).

In Stremio heißt das Addon **DMM Cast for TorBox**. Seine Zeile **DMM TB Library** zeigt deine TorBox-Torrents sowie deine fertigen Web- und Usenet-Downloads.

## Usenet-Releases an TorBox senden (Pro) {#send-usenet-releases-to-torbox-pro}

1. Öffne einen Film oder eine Serie und drücke auf den Tab **Usenet**.
2. Mit TorBox Pro steht über der Liste **Send to TorBox**, und jede Veröffentlichung hat einen **TorBox**-Button. Drücke ihn.
3. DMM zeigt dir an, was TorBox damit gemacht hat:
   - **Usenet → TorBox: TorBox already had it, it is ready in your TorBox Usenet downloads.**
   - **Usenet → TorBox: TorBox is downloading it, usually ready within a few minutes.**
   - **Usenet → TorBox: queued, it starts when one of your TorBox active slots frees up.**

![DMM's Usenet tab with TorBox Pro: Send to TorBox](../assets/dmm-torbox/03-usenet-tab.webp)

Bist du auch bei Real-Debrid angemeldet? Dann steht über der Liste **Send to Real-Debrid or TorBox**, und es gibt beide Buttons. Das Dateisymbol am Ende einer Zeile speichert stattdessen die NZB. Neu bei Usenet? Fang mit [Usenet für Einsteiger](../guides/usenet-for-beginners.md) an.

TorBox löscht einen Usenet-Download 30 Tage nach dem Zwischenspeichern. Schick ihn einfach noch einmal, dann ist er wieder da.

## Anfragen mit TorBox erfüllen {#fill-requests-with-torbox}

Nutzer von Real-Debrid können auf DMMs [Anfrageboard](https://debridmediamanager.com/requests) nach Releases fragen. Klicke auf der Startseite auf **Requests** und dann auf **Fulfil** bei einem Release, das TorBox bereits gecacht hat. Es wird von deinem TorBox auf deren Real-Debrid übertragen. Für alle 10 Übertragungen erhältst du 7 Tage DMM-Sponsor-Vorteile: siehe [ohne Bezahlung verdienen](../guides/sponsorship.md#earn-it-without-paying).

## Wenn etwas nicht stimmt {#when-something-is-wrong}

| Was du siehst | Was zu tun ist |
|---|---|
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Dieser Key gehört zum kostenlosen TorBox-Plan. Upgrade oder verlängere ihn bei TorBox und melde dich dann erneut an. |
| **Failed to refresh torbox: Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Dein bezahlter Plan ist abgelaufen, seit du dich angemeldet hast. Verlängere ihn bei TorBox. |
| **API Error: Request failed with status code 403. Status: 403** | TorBox hat diesen Key nicht akzeptiert. Kopiere ihn erneut von [torbox.app/settings](https://torbox.app/settings), komplett. |
| Kein **TorBox**-Button im Usenet-Tab | Usenet-Releases an TorBox zu senden braucht Pro. Essential und Standard bekommen den Button nicht. |
| **Usenet → TorBox: TorBox Usenet needs a Pro plan** | TorBox hat die NZB abgelehnt, weil der Plan nicht Pro ist. |
| Nur **DL with TB**, kein **Instant TB** | TorBox hat keines dieser Releases gecacht. Drücke auf eines und warte, bis es heruntergeladen ist, oder wähle ein anderes Release. |
| Nur **Instant TB**-Releases werden angezeigt | Der **TB ✓**-Chip ist an (`is:tb` im Filterfeld). Drücke ihn erneut oder drücke **Reset**. |
| **No torrents found yet. Use Want above to have zurg fetch it once one turns up, or try the Usenet tab.** | DMM hat noch keine Torrents für diesen Titel. Neue Episoden können eine Weile dauern. Probiere den **Usenet**-Tab oder schau später wieder vorbei. |
| In Stremio: **⚠️ TorBox refused your account** | TorBox akzeptiert den Key des Addons, liefert aber nicht für das Konto aus, meist weil der Plan abgelaufen ist. Prüfe es unter [torbox.app/settings](https://torbox.app/settings). An DMM muss nichts geändert werden. |
| zurg: `Acquisition: dmm-torbox refused the search: No TorBox key linked.` | Das Sponsor-Feed `tb/cached` auf der [Torznab-Seite von DMM](https://debridmediamanager.com/torznab) braucht deinen TorBox-Key, der dort unter **Link a provider key** verknüpft sein muss. Bei TorBox auf DMM angemeldet zu sein reicht nicht. Der `api_key` in zurg bleibt dein DMM-API-Key. |

Ist TorBox selbst gerade down? Prüfe [Is TorBox Down Or Just Me?](https://debridmediamanager.com/is-torbox-down-or-just-me). Hängst du fest? Frag im **dmm-support**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP). [Hilfe holen](../guides/remote-help.md) sagt, was du angeben solltest.

## Fragen {#questions}

### Wird TorBox im kostenlosen Tarif von zurg nicht unterstützt? {#is-torbox-support-not-on-the-free-tier-of-zurg}

Richtig. Der kostenlose öffentliche Build von zurg unterstützt nur Real-Debrid. TorBox, die anderen Dienste und Usenet gibt es in den nächtlichen Builds von zurg für Sponsoren. Dein TorBox-Tarif muss außerdem bezahlt sein, denn zurg kann mit einem kostenlosen Konto nichts anfangen. Richte es mit [TorBox mit zurg](../zurg/providers/torbox.md) ein.

### Zurg nutzt den falschen TorBox-Tarif? {#zurg-uses-the-wrong-torbox-plan}

zurg-Nightlies vor dem 3. Oktober 2026 haben den Pro-Tarif von TorBox als Standard gelesen und nur 5 gleichzeitige Downloads statt 10 erlaubt. Aktualisiere zurg. Alles Weitere steht in [TorBox's Limits mit zurg](../zurg/providers/torbox-limits.md).

### Keine Suchergebnisse mit TB? {#no-search-results-with-tb}

DMMs Suche funktioniert gleich, egal bei welchem Dienst du dich anmeldest. TorBox bestimmt nur, welche Releases **Instant TB** anzeigen. Wenn du nichts siehst, prüf, ob der **TB ✓**-Chip aus ist, lad die Seite neu oder drück unten auf **Show More Results**. Eine brandneue Episode hat auf DMM unter Umständen noch keine Torrents: probier dann den **Usenet**-Tab.

### Kann ich TorBox und Real-Debrid gleichzeitig nutzen? {#can-i-use-torbox-and-real-debrid-together}

Ja. Melde dich bei beiden an, dann zeigt jede Veröffentlichung die Buttons beider Dienste. Eine Veröffentlichung, die TorBox gecacht hat und Real-Debrid nicht, bekommt einen **TB → RD**-Button. Damit wird sie von TorBox zu deinem Real-Debrid übertragen.

### Welchen TorBox-Tarif brauche ich für DMM? {#which-torbox-plan-do-i-need-for-dmm}

Jeder bezahlte Tarif. Wähle Pro, wenn du Usenet-Releases an TorBox senden oder 10 Downloads gleichzeitig laufen lassen willst.
