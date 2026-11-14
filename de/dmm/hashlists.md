# DMM-Hash-Listen: Die Bibliothek von jemand anderem zu deiner hinzufügen {#dmm-hash-lists-add-someones-library-to-yours}

Eine Hash-Liste ist eine Sammlung von Releases, die jemand über DMM aus seiner Debrid-Bibliothek geteilt hat. Öffne eine Liste, melde dich mit deinem Debrid-Dienst bei DMM an und drück den Button deines Dienstes: Die Releases landen dann in deinem eigenen Konto. Geteilte Listen findest du unter [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com), und deine eigene Liste kannst du in DMM unter **Library** mit **Share List** teilen.

Eine Liste enthält Release-Namen, ihre Hashes und Größen. Keine Dateien und keine Konten.

## Eine Liste finden {#find-a-list}

- Auf der Startseite von DMM drückst du auf **Hash lists**. Dann öffnet sich [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com) mit einer zufälligen Liste. Mit **Previous hash list**, **Random hash list** und **Next hash list** wechselst du zwischen den Listen.
- Im **hashlists**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP) posten Leute Listen. Jede davon ist ein Link wie `https://hashlists.debridmediamanager.com/<id>.html`. Wenn du ihn öffnest, wird die Liste in DMM geöffnet.

## Eine Liste zu deiner Bibliothek hinzufügen {#add-a-list-to-your-library}

1. Öffne die Liste. Wenn dort **Login to RD/AD/TB/PM/OC/DL to download** steht, melde dich zuerst im selben Browser bei [DMM](https://debridmediamanager.com) an (siehe [wie du dich anmeldest](index.md#sign-in)) und öffne danach die Liste erneut.
2. DMM prüft, welche Releases dein Dienst bereits hat. Es zeigt nur diese an und lässt alles weg, was schon in deiner Bibliothek ist. Die grüne **hidden**-Box zählt, was ausgeblendet wurde.
3. Grenze die Liste bei Bedarf ein:
   - **Movies** und **TV Shows** zeigen jeweils nur eine Art. Die Zahlen zählen Titel, nicht Dateien.
   - **One per title** behält das beste Release jedes Titels.
   - Der grüne **other files**-Chip neben einem Titel zeigt alle seine Releases.
   - **quick search on filename, hash, or id; supports regex** durchsucht die Liste.
4. Drücke den Button in einer Zeile (**RD**, **TB**, **AD**, **PM**, **OC** oder **DL**), um nur dieses eine Release hinzuzufügen.
5. Oder drücke **RD Download** (**TB Download**, **PM Download** und so weiter), um alle angezeigten Releases hinzuzufügen. Die Zahl darauf ist die Anzahl. DMM fragt vorher nach, zum Beispiel **Add 11 releases to Premiumize?**: Drücke **Add 11**, um zu starten.

![A shared hash list of open movies in DMM, signed in with Premiumize](../assets/dmm-hashlists/01-hash-list.webp)

**Show All** zeigt auch die Releases, die dein Dienst nicht hat, und **Show Instant** wechselt wieder zu den gecachten.

**RD Download** fügt nur Releases hinzu, die Real-Debrid schon hat, und zwar eins pro Minute, weil Real-Debrid Konten pausiert, die zu schnell hinzufügen. Sechzig Releases dauern etwa eine Stunde. Die Hinzufügungen laufen in der Seite, also lass den Tab offen, bis **Started 60 downloads.** erscheint. TorBox und AllDebrid überspringen alles, was sie nicht gecacht haben.

## Deine eigene Bibliothek teilen {#share-your-own-library}

1. Drücke auf der Startseite von DMM auf **Library**.
2. Suche nach den Releases, die du teilen willst, oder markiere sie. Ohne markierte Releases wird alles geteilt, was angezeigt wird.
3. Drücke auf **Share List** (dort steht **Share (3)**, wenn du drei markiert hast). Gib bei **Enter a title for the hash list** einen Namen ein und drücke auf **OK**.
4. DMM öffnet die neue Adresse deiner Liste auf hashlists.debridmediamanager.com. Während sie veröffentlicht wird, kann eine Minute oder zwei lang ein 404 erscheinen. Lade die Seite neu und teile dann diese Adresse.

![The title prompt after pressing Share List](../assets/dmm-hashlists/02-share-list.webp)

Geteilte Listen sind öffentlich. Jeder mit der Adresse kann sie öffnen, und **Random hash list** kann deine Liste auch Fremden zeigen. Es werden nur Namen, Hashes und Größen gespeichert: niemals dein Konto, dein Schlüssel oder eine Tracker-Adresse.

Wenn du ein einzelnes Release teilen willst, ohne etwas zu veröffentlichen, drücke auf das Teilen-Symbol am Ende seiner Zeile in der Library (oder auf **Hashlist** in den Details). DMM öffnet eine Liste mit genau diesem einen Release. Kopiere die Adresse dieser Seite und schick sie weiter.

## Wenn etwas nicht stimmt {#when-something-is-wrong}

| Was du siehst | Was du tun solltest |
|---|---|
| **Login to RD/AD/TB/PM/OC/DL to download** | Du bist in diesem Browser nicht bei DMM angemeldet. Melde dich an und öffne die Liste dann erneut. |
| Alles ist **hidden** und die Liste wirkt leer | Versteckte Zeilen sind bereits in deiner Bibliothek oder dein Dienst hat sie nicht. Drücke **Show All**. |
| **This hash list is still being published; refresh in a minute or two.** | Die Liste wurde vor wenigen Augenblicken geteilt. Warte eine oder zwei Minuten und lade die Seite neu. |
| **0 files** und keine Zeilen | Diese Liste ist leer. Drücke **Next hash list** oder **Random hash list**. |
| **Everything already downloaded** | Jede angezeigte Version ist bereits in deiner Bibliothek. |
| **Torrent not instant in TorBox; skipped.** oder **Torrent not instant in AD; skipped.** | Dein Dienst hat diesen Torrent nicht im Cache, deshalb hat DMM ihn übersprungen, anstatt einen Download zu starten. |
| **Skipping 3 items with no info hash — they cannot be shared.** | Diese Zeilen (zum Beispiel TorBox-Web-Downloads) haben keinen Hash, den man teilen könnte. Der Rest der Liste wird geteilt. |
| **Failed to generate hash list; try again soon.** | Das Veröffentlichen der Liste ist fehlgeschlagen. Versuche es später noch einmal. |

Du hängst fest? Frag im Forum **dmm-support** auf [Discord](https://discord.com/invite/7u4YjMThXP).

## Fragen {#questions}

### Wie füge ich Hash-Listen zu meiner eigenen Bibliothek hinzu? {#how-do-i-add-hash-lists-to-my-own-library}

Öffne die Liste, melde dich bei DMM mit deinem Debrid-Dienst an und klicke dann in einer Zeile auf die Schaltfläche deines Dienstes oder auf **RD Download** (bzw. **Download** deines Dienstes), um alles Angezeigte herunterzuladen. Siehe [Add a list to your library](#add-a-list-to-your-library).

### Warum sind alle Einträge in meiner Hash-Liste ausgeblendet? {#why-are-all-the-items-in-my-hash-list-hidden}

DMM blendet aus, was schon in deiner Bibliothek ist und was dein Dienst nicht im Cache hat. Das **hidden**-Feld zeigt, wie viele es sind. **Show All** zeigt den Rest.

### Warum tauchen Serien nicht in einer Hash-Liste auf? {#why-dont-tv-shows-show-up-in-a-hash-list}

Klicke oben in der Liste auf **TV Shows**. Wenn dort **0 TV Shows** steht, enthält die Liste keine Serien: Die meisten geteilten Listen bestehen aus Filmen. Serien, die dein Dienst nicht hat, werden ebenfalls ausgeblendet. Probiere deshalb **Show All** aus.

### Warum dauert das Hinzufügen einer Hash-Liste so lange? {#why-is-adding-a-hash-list-so-slow}

Bei Real-Debrid fügt DMM jede Minute eine Veröffentlichung hinzu, damit Real-Debrid dein Konto nicht pausiert. Bei den anderen Diensten geht es schneller.

### Gibt es eine API, um die Hash-Listen abzufragen? {#is-there-an-api-to-query-the-hash-lists}

Es gibt keine Such-API. Jede geteilte Liste ist eine Datei im öffentlichen [hashlists-Repository](https://github.com/debridmediamanager/hashlists) auf GitHub. Jede Seite verweist mit der Liste im Link nach dem `#` auf DMM (lz-string-komprimiertes JSON mit Namen, Hashes und Größen). Eine sehr große Liste liegt stattdessen daneben als `lists/<id>.txt`.

### Teilt man beim Teilen einer Liste auch sein Konto? {#does-sharing-a-list-share-my-account}

Nein. Eine Liste enthält nur Release-Namen, Hashes und Größen.
