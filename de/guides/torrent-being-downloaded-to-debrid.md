# Was „Torrent is being downloaded to debrid“ bedeutet {#what-torrent-is-being-downloaded-to-debrid-means}

Der grüne Bildschirm **Torrent is being downloaded to debrid...** bedeutet, dass die Version, die du ausgewählt hast, bei deinem Debrid-Dienst noch nicht im Cache liegt. Torrentio, das Stremio-Addon, das sie anzeigt, hat den Torrent gerade zu deinem Real-Debrid-, TorBox- oder anderen Debrid-Konto hinzugefügt, und der Dienst lädt ihn jetzt herunter. Sobald das fertig ist, lässt sich dasselbe Ergebnis wie jedes andere abspielen.

## Was zu tun ist {#what-to-do}

1. **Wähle stattdessen ein gecachtes Ergebnis.** In Torrentios Liste bedeutet `[RD+]` (oder `[TB+]`, `[AD+]`, `[PM+]`), dass das Ergebnis gecacht ist, es startet also sofort. `[RD download]` bedeutet, dass es nicht gecacht ist. Diese stehen nach den gecachten.
2. **Oder warte ein paar Minuten und drück dann erneut auf dasselbe Ergebnis.** Solange es noch lädt, siehst du wieder den grünen Bildschirm. Sobald der Download fertig ist, startet die Wiedergabe.
3. **Schau dem Download zu** auf [Real-Debrids Torrent-Seite](https://real-debrid.com/torrents), in deinem [TorBox-Dashboard](https://torbox.app/dashboard) oder in der [DMM-Bibliothek](https://debridmediamanager.com/library). DMM zeigt für jeden unfertigen Download den Fortschritt in Prozent, die Seeds und die Geschwindigkeit an.
4. **Hängt es bei 0 % ohne Seeds?** Gerade teilt niemand dieses Release, es wird also vielleicht nie fertig. Such dir ein anderes aus.
5. **Willst du diese Ergebnisse gar nicht sehen?** Öffne die [Konfigurationsseite von Torrentio](https://torrentio.strem.fun/configure), trage wie zuvor deinen Debrid-Dienst und Schlüssel ein, setze unter **Options** den Haken bei **Don't show download to debrid links** und drück **INSTALL**. Dann siehst du nur gecachte Ergebnisse.

## Sieh vor dem Abspielen nach, was im Cache ist {#see-whats-cached-before-you-press-play}

Melde dich bei [DMM](https://debridmediamanager.com/) mit deinem Debrid-Dienst an und suche nach dem Titel. Auf seiner Seite bedeutet ein grüner **Instant RD**-Button, dass Real-Debrid diese Version bereits im Cache hat, sie startet also sofort. **DL with RD** heißt, dass sie nicht im Cache liegt und erst heruntergeladen werden muss. Tippe auf den **RD**-Chip über den Ergebnissen, um alles auszublenden, was nicht im Cache liegt. TorBox, AllDebrid, Premiumize und Offcloud bekommen dieselben Buttons (**Instant TB**, **DL with TB** und so weiter).

## Fragen {#questions}

### Wie lange dauert es? {#how-long-does-it-take}

Es hängt davon ab, wie viele Leute denselben Torrent teilen. Ein beliebtes Release ist meist in wenigen Minuten fertig: In unserem Test auf Premiumize war ein 1,5-GB-Film fünf Minuten nach dem ersten Klick bereit, heruntergeladen von drei Peers. Ein selten geteilter Torrent kann langsam sein, und einer, den niemand teilt, wird vielleicht nie fertig. Die Torrents-Seite oder das Dashboard zeigt die Geschwindigkeit und wie viele Seeds gefunden wurden.

### Warum passiert das bei manchen Ergebnissen und bei anderen nicht? {#why-does-it-happen-on-some-results-and-not-others}

Debrid-Dienste speichern, was ihre Nutzer herunterladen. Hat jemand die genaue Version schon einmal abgerufen, ist sie im Cache und lässt sich sofort abspielen. Hat sie noch niemand abgerufen oder hat der Dienst sie inzwischen wieder entfernt, muss dein Konto sie zuerst herunterladen. Genau das ist der Unterschied zwischen `[RD+]` und `[RD download]`. TorBox [erklärt, wie der Cache funktioniert](https://support.torbox.app/en/articles/9923071-how-does-the-torbox-cache-work).

### Warum hat ein `[RD+]`-Ergebnis das angezeigt? {#why-did-an-rd-result-show-it}

Real-Debrid erlaubt Addons nicht, abzufragen, was gecacht ist. Bei Real-Debrid bedeutet das `+` bei Torrentio also, dass die Version vor Kurzem für jemand anderen abgespielt wurde, nicht dass Real-Debrid es gerade eben bestätigt hat. Hat Real-Debrid sie seitdem entfernt, wird sie erneut heruntergeladen. Wähl dann ein anderes `+`-Ergebnis oder warte.

### Ist mein Debrid kaputt? {#is-my-debrid-broken}

Nein. Der grüne Bildschirm bedeutet, dass dein Dienst den Torrent angenommen hat und daran arbeitet. Wenn wirklich etwas nicht stimmt, zeigt Torrentio einen roten oder gelben Bildschirm mit anderen Worten, zum Beispiel "Access denied" oder "Some usage limit exceeded".

### Mein Addon zeigt etwas anderes an {#my-addon-says-something-else}

Die genauen Worte stammen von Torrentio und selbst gehosteten Kopien davon. Andere Addons sagen dasselbe auf ihre eigene Art. AIOStreams zeigt "The file is being downloaded to your debrid. Try again later", Comet "The media you tried to play is not cached yet on this debrid service" und StremThru "Downloading to Store". Gleiche Ursache, gleiche Lösung.
