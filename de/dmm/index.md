# Was ist DMM und wie benutze ich es? {#what-is-dmm-and-how-do-i-use-it}

[Debrid Media Manager](https://debridmediamanager.com) (DMM) ist eine kostenlose Website, auf der du Filme und Serien finden und zu deinem Debrid-Konto hinzufügen kannst: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud oder Debrid-Link. Du meldest dich mit diesem Konto an, suchst nach einem Titel und drückst bei einer Version auf **Instant RD** (oder den Button deines Dienstes). Danach ist der Titel sofort in deiner Bibliothek und bereit zum Abspielen, direkt in DMM, in Stremio oder Kodi oder in Plex über [zurg](../zurg/index.md).

DMM ist Open Source und gehört nicht zu Real-Debrid oder einem anderen Dienst. Die Dateien bleiben bei deinem Debrid-Dienst.

## Anmelden {#sign-in}

1. Öffne [debridmediamanager.com](https://debridmediamanager.com) und drück auf deinen Dienst: **Login with Real Debrid**, **Login with AllDebrid**, **Login with Torbox**, **Login with Premiumize**, **Login with Offcloud** oder **Login with Debrid-Link**.
2. Bei Real-Debrid drückst du auf **Sign in with Real-Debrid**. DMM zeigt dir einen Code: Drück auf **Open real-debrid.com/device**, gib den Code dort ein und bestätige ihn. Die DMM-Seite schließt dann von selbst ab. Du kannst auch dein [API-Token](../guides/real-debrid-api-token.md) unter **or paste an API key** einfügen und auf **Save API Key** drücken.
3. Andere Dienste: Folge ihrer Login-Seite. Wenn dort ein API-Key verlangt wird, kopier ihn aus deinem Konto bei diesem Dienst, füg ihn ein und drück auf **Save API Key**.

![DMM's sign-in page](../assets/dmm-index/01-sign-in.webp)

Hast du noch einen anderen Dienst? Öffne **Debrid services** auf der Startseite von DMM und drück auf dessen **Login**-Button, zum Beispiel **AllDebrid Login**.

Du hast nur Easynews? Drück auf **Login with Easynews**. Du kannst in Easynews suchen und es an Stremio senden, aber für die Bibliothek brauchst du ein Debrid-Konto. Sponsoren können sich auch mit **Login with DMM key** anmelden.

## Einen Film oder eine Serie suchen {#search-a-movie-or-show}

1. Gib im Suchfeld auf der Startseite einen Titel bei **Search movies & shows...** ein. Wähle einen Vorschlag aus oder drücke **Search** für die vollständige Liste.
2. Drücke auf das Poster. Auf der Seite des Titels werden die Releases aufgelistet, die DMM gefunden hat.
3. Drücke über den Ergebnissen auf den Chip deines Dienstes (**RD**, **PM** und so weiter), um nur Releases anzuzeigen, die dieser bereits hat.

![DMM's home page after signing in](../assets/dmm-index/02-home.webp)

## Was die Buttons bei einem Release bedeuten {#what-the-buttons-on-a-release-mean}

![Releases von Sintel auf DMM, angemeldet mit Premiumize](../assets/dmm-index/03-results.webp)

| Button | Was er macht |
|---|---|
| **Instant RD** (**Instant TB**, **Instant AD**, **Instant PM**, **Instant OC**, **Instant DL**) | Dein Dienst hat dieses Release schon. Drück drauf, dann ist es sofort in deiner Bibliothek. |
| **DL with RD** (**DL with TB** und so weiter; **Add to DL** bei Debrid-Link) | Dein Dienst hat es noch nicht. Wenn du drückst, wird es trotzdem hinzugefügt, und der Dienst lädt es zuerst herunter. Willst du jetzt schauen, nimm lieber einen **Instant**-Button. [Warum das passiert](../guides/torrent-being-downloaded-to-debrid.md). |
| **RD (100%)** (**PM (100%)** und so weiter) | Es ist in deiner Bibliothek. Die Zahl zeigt, wie weit der Download ist. Drück drauf, um es aus deiner Bibliothek zu entfernen. |
| **Check RD** (**Check AD**, **Check DL**) | Fragt den Dienst, ob er dieses Release gerade im Cache hat. |
| **Cast (RD)** (**Cast (PM)** und so weiter) | Schickt das Release an Stremio. Siehe [DMM in Stremio](stremio.md). |
| **Watch** | Öffnet einen Tab **Ready to play**. Drück auf **Play**, dann öffnet sich dein Player. Den Player wählst du unter **Settings** → **Video player**. |
| **Copy** | Kopiert den Magnet-Link des Releases und zeigt **Magnet link copied.** an. Ist unter **Settings** der Haken bei **Download .magnet files instead of copy** gesetzt, steht da **Download** und es wird eine .magnet-Datei gespeichert. |
| **Report** | Markiert ein schlechtes Release: **XXX / Porn Content**, **Incorrect IMDB ID**, **Malware / Executable File** und bei Serien **Tagged for Wrong Season**. |

Der Tab **Usenet** neben **Torrents** listet Usenet-Releases desselben Titels auf. **NZB** lädt eines herunter. Um sie in deine Bibliothek zu schicken, brauchst du Real-Debrid oder TorBox. Hast du Easynews? Füg es unter **Settings** hinzu, dann wird es hier auch durchsucht.

## Deine Bibliothek {#your-library}

Drücke auf der Startseite auf **Library**. Dort werden alle Inhalte aufgelistet, die in den Konten liegen, mit denen du dich angemeldet hast: Name, Größe, Status und wann sie hinzugefügt wurden.

![Die Suchleiste und Schaltflächen der Bibliothek](../assets/dmm-index/04-library.webp)

- Suche mit **search by filename/hash/id, supports regex** oder schränke die Liste mit **Movies**, **TV shows** und **Others** ein.
- Drücke auf eine Zeile, um ihre Details sowie die Schaltflächen **Hashlist**, **Delete**, **Cast** und **Copy** zu sehen. Die Symbole am Ende jeder Zeile haben dieselben Funktionen.
- **Backup** speichert deine Liste in einer `.dmm.json`-Datei. **RD Restore** (**PM Restore** und so weiter) fügt eine gespeicherte Liste wieder hinzu.
- **Share List** macht aus dem, was angezeigt wird, oder aus deiner Auswahl eine [Hash-Liste](hashlists.md), die andere Leute in ihre eigenen Konten übernehmen können.
- **Delete List** löscht alles, was angezeigt wird, nachdem du die Abfrage **Yes, delete!** bestätigt hast. Suche oder wähle vorher aus.

## Wo es als Nächstes weitergeht {#where-to-go-next}

- [DMM in Stremio](stremio.md): Schau dir an, was du in Stremio findest, mit dem DMM Cast-Addon.
- [Hash-Listen](hashlists.md): Füge deiner Bibliothek eine ganze geteilte Bibliothek hinzu oder teile deine eigene.
- [TorBox in DMM](torbox.md): Was welcher TorBox-Tarif in DMM kann, und wie du Usenet-Releases an TorBox Pro schickst.
- ["Torrent is being downloaded to debrid"](../guides/torrent-being-downloaded-to-debrid.md): Was dieser Bildschirm in Stremio bedeutet und wie DMM zeigt, was im Cache liegt.
- [DMM-Buttons in Safari](safari.md): Die Browser-Erweiterung fügt einen DMM-Button zu IMDb, Trakt und anderen Film- und Serienseiten hinzu.

DMM unterstützt auch die anderen Projekte:

- **zurg** fragt DMM, welcher Film oder welche Episode zu jeder Datei gehört. Ein Sponsor bekommt den DMM-API-Schlüssel über [gatekeeper](https://gatekeeper.debridmediamanager.com/). Ohne ihn verlässt sich zurg auf Dateinamen, und es passen weniger Titel. [rex mit zurg](../rex/with-zurg.md#why-dmm-places-the-files) erklärt den Unterschied.
- **Sonarr Radarr und Prowlarr** können DMM als Torznab-Torrent-Indexer oder Newznab-Usenet-Indexer durchsuchen. Beides braucht eine aktive Sponsorschaft und den DMM-API-Schlüssel. Richte sie auf den Seiten [Torznab](https://debridmediamanager.com/torznab) und [Newznab](https://debridmediamanager.com/newznab) ein.
- **Deine Wunschliste**: Drücke **Want** oder folge einer Trakt-, MDBList-, TMDB- oder Simkl-Liste. zurg holt sie und neue Episoden, sobald sie erscheinen. Sponsorschaft nötig. Siehe [DMM-Wunschliste](../zurg/guides/dmm-wanted.md).
- **Seerr Overseerr und Jellyseerr** können DMM als Radarr und Sonarr nutzen. Anfragen landen dann auf deiner Wunschliste, und zurg holt sie. Sponsorschaft nötig. Siehe [Seerr über DMM](seerr.md).
- **rex-direct** gibt einem beanspruchten rex eine eigene Adresse und ein eigenes Zertifikat. Siehe [rex-direct](../rex/any-source.md#rex-direct).

Alles, was eine Sponsorschaft freischaltet, und wo jede Sache eingerichtet wird, steht auf [Was dir eine Sponsorschaft bringt](../guides/sponsorship.md).

## Wenn etwas nicht stimmt {#when-something-is-wrong}

| What you see | What to do |
|---|---|
| **Real-Debrid rejected that API key.** | Der Token, den du eingefügt hast, funktioniert nicht. Kopier ihn erneut von [real-debrid.com/apitoken](https://real-debrid.com/apitoken) oder drück stattdessen auf **Sign in with Real-Debrid**. Mehr dazu in [Your Real-Debrid API token](../guides/real-debrid-api-token.md). |
| **That code expired before it was approved. Try again.** | Der Real-Debrid-Code ist abgelaufen. Drück noch einmal auf **Sign in with Real-Debrid** und bestätige den neuen Code schneller. |
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Der kostenlose TorBox-Plan lässt sich mit DMM nicht nutzen. Wechsle auf einen bezahlten Plan oder melde dich mit einem anderen Dienst an. |
| Only **DL with RD** buttons, no **Instant RD** | Dein Dienst hat keine dieser Releases im Cache. Drück auf einen Button und warte, bis der Download fertig ist, oder probier ein anderes Release. |

Nicht weitergekommen? Frag im **dmm-support**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP) nach. [Wie du Hilfe bekommst](../guides/remote-help.md) erklärt, was du angeben solltest.

## Fragen {#questions}

### Was ist DMM eigentlich? {#what-actually-is-dmm}

Eine Suchseite für dein Debrid-Konto. Sie findet Releases eines Films oder einer Serie, zeigt dir, welche davon dein Dienst schon hat, und fügt die von dir gewählte Version deinem Konto hinzu. DMM selbst speichert keine Dateien.

### Wie benutze ich es? {#how-do-i-use-it}

Melde dich bei deinem Debrid-Dienst an, suche einen Titel, öffne ihn und drücke bei einem Release auf **Instant RD** (oder auf den **Instant**-Button deines Dienstes). Drücke dann auf **Watch**, streame es zu Stremio oder lass zurg es in Plex einfügen.

### Wird DMM von Real-Debrid gemacht? {#is-dmm-made-by-real-debrid}

Nein. DMM ist ein Open-Source-Projekt, das mit Real-Debrid und fünf weiteren Diensten funktioniert. Viele Leute suchen danach unter „Real-Debrid Media Manager“.

### Ist es kostenlos? {#is-it-free}

Ja. Du brauchst dafür ein eigenes Debrid-Konto, und das ist ein kostenpflichtiger Dienst. Mit einer DMM-Sponsorschaft bekommst du zusätzliche Funktionen wie die Wunschliste und die Indexer: Was dir eine Sponsorschaft bringt, steht hier: [Was dir eine Sponsorschaft bringt](../guides/sponsorship.md).

### Welche Dienste funktionieren? {#which-services-work}

Real-Debrid, AllDebrid, TorBox (kostenpflichtige Tarife), Premiumize, Offcloud und Debrid-Link. Easynews funktioniert für die Suche und das Streamen, nicht für die Bibliothek.
