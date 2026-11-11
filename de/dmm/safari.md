# DMM-Buttons in Safari {#dmm-buttons-in-safari}

Die DMM-Browsererweiterung fügt auf Film- und Serienseiten einen **DMM🔎**-Button hinzu. Er öffnet den Titel in DMM. Neben Magnet-Links gibt es außerdem einen **DMM🧲**-Button, der den Torrent zu deiner DMM-Bibliothek hinzufügt.

Unter Chrome und Firefox installierst du die [Chrome-Erweiterung](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm) oder das [Firefox-Add-on](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/). Safari nutzt denselben Code als [Greasy-Fork-Userscript](https://greasyfork.org/en/scripts/463268-debrid-media-manager) mit einem Userscript-Manager.

Wähle einen Manager aus:

| Manager | Preis | Läuft auf | Aktualisiert das Skript |
|---|---|---|---|
| [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) | Kostenlos | Mac, iPhone, iPad | Wenn du im Popup auf **Update** tippst |
| [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) | 2,99 $ | Mac, iPhone, iPad | Automatisch |

## Mit Userscripts {#with-userscripts}

1. Installiere [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) aus dem App Store und öffne es einmal.
2. Aktiviere die Erweiterung:
   - **Mac:** Safari > **Einstellungen** > **Erweiterungen**, setze den Haken bei **Userscripts**.
   - **iPhone und iPad:** **Einstellungen** > **Apps** > **Safari** > **Erweiterungen** > **Userscripts**, schalte **Erlauben Sie die Erweiterung** ein.
3. Lass es auf jeder Website laufen. Magnet-Links können auf jeder Website stehen, deshalb muss das Skript überall ausgeführt werden.
   - **Mac:** Klicke im selben Bereich **Erweiterungen** auf **Websites bearbeiten…** und stelle bei **Beim Besuch anderer Websites** auf **Erlauben**.
   - **iPhone und iPad:** Stelle auf dem gleichen **Userscripts**-Bildschirm bei **Alle Websites** auf **Erlauben**.
4. Öffne in Safari die [DMM-Userscript-Datei](https://update.greasyfork.org/scripts/463268/Debrid%20Media%20Manager.user.js). Sie wird als reiner Text angezeigt.
5. Öffne das Userscripts-Popup: über den Symbolleisten-Button auf dem Mac oder über die Schaltfläche **aA** in der Adressleiste auf dem iPhone. Tippe auf die Installationsaufforderung, die es zeigt, und bestätige.

Zum späteren Aktualisieren öffne das Userscripts-Popup und tippe auf **Aktualisieren**, sobald das DMM-Skript in der Liste erscheint.

## Mit Tampermonkey {#with-tampermonkey}

1. Installiere [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) aus dem App Store.
2. Schalte es ein und lass es auf jeder Website laufen, so wie in Schritt 2 und 3 oben, nur mit **Tampermonkey** statt **Userscripts**.
3. Öffne in Safari die [Greasy-Fork-Seite](https://greasyfork.org/en/scripts/463268-debrid-media-manager) des Skripts und klicke auf **Install this script**.
4. Tampermonkey öffnet seine Installationsseite. Klicke auf **Install**.

Tampermonkey sucht einmal am Tag nach einer neuen Version.

## Prüfen, ob es funktioniert {#check-it-works}

Öffne [Dune: Part Two auf Letterboxd](https://letterboxd.com/film/dune-part-two/). Neben dem Titel erscheint ein türkisfarbener **DMM🔎**-Button, und er öffnet den Film auf DMM.

Kein Button? Prüfe diese Punkte:

- Im Popup des Managers steht **Debrid Media Manager**, und der Schalter ist eingeschaltet.
- Safari erlaubt dem Manager, auf dieser Seite zu laufen. Wenn er nachfragt, wähle **Always Allow on Every Website**.
- Die Seite ist vollständig geladen. Seiten wie TMDB, Wikipedia und AniList zeigen den Button ein paar Sekunden nach der Seite selbst.
