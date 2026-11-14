# Usenet für Einsteiger: was du kaufen solltest und wie es mit zurg zusammenpasst {#usenet-for-beginners-what-to-buy-and-how-it-fits-with-zurg}

Um Usenet mit zurg zu streamen, brauchst du einen **Usenet-Provider**-Account, der die Dateien enthält, und **NZB-Dateien**, die angeben, wo jedes Release zu finden ist. Ein **Indexer** ist eine Suchseite für NZBs, aber du musst keinen kaufen: Der **Usenet**-Tab von DMM findet NZBs für jeden Film und jede Serie. zurg spielt das Release dann direkt von deinem Provider ab, ohne dass vorher etwas heruntergeladen wird.

## Die drei Teile {#the-three-pieces}

| Teil | Was es ist | Zahlt man dafür? |
|---|---|---|
| Provider oder News-Server | Der Dienst, der die Beiträge speichert. Du bekommst eine Serveradresse, einen Benutzernamen, ein Passwort und eine Anzahl an Verbindungen. zurg liest davon. | Ja. Das ist das Einzige, was du kaufen musst. |
| NZB | Eine kleine Datei, die die Teile eines Releases auflistet, so wie eine `.torrent`-Datei das bei Torrents macht. | Nein. |
| Indexer | Eine Suchseite, die NZBs erstellt. Sonarr, Radarr und Prowlarr durchsuchen einen. | Optional. |

Ein Release auf Usenet wird als Tausende kleiner Teile gepostet. Die NZB listet sie auf, dein Provider liefert sie aus, und zurg setzt sie wieder zu dem Video zusammen, das dein Player anfordert.

## Was du brauchst {#what-you-need}

1. **Eine zurg-Sponsoring-Mitgliedschaft.** Usenet ist in den nächtlichen Builds von zurg enthalten, die mit einem [Sponsoring](sponsorship.md) kommen. Das kostenlose öffentliche zurg unterstützt nur Real-Debrid.
2. **Ein Usenet-Provider-Konto.** Beim Vergleichen von Tarifen sind zwei Zahlen wichtig:
   - **Retention**: wie viele Tage zurück der Server Beiträge aufbewahrt. Ältere Filme und Serien brauchen mehr.
   - **Connections**: wie viele Verbindungen der Tarif gleichzeitig erlaubt. zurg liest mit dieser Anzahl, also trag den echten Wert deines Tarifs in die Config ein.
3. **NZBs.** Speicher sie über den Usenet-Tab in DMM, hol sie von deinem eigenen Indexer oder lass Sonarr, Radarr oder zurg sie suchen.

Das brauchst du nicht:

- **Einen Download-Client** wie SABnzbd oder NZBGet. zurg streamt das Release. Für Sonarr und Radarr agiert zurg selbst als SABnzbd: siehe [Sonarr & Radarr for Usenet](../zurg/guides/sonarr-radarr.md).
- **Speicherplatz für ganze Releases.** zurg lädt nur die Teile, die gerade abgespielt werden. Ein 60-GB-Remux braucht also nicht 60 GB Festplatte.
- **Tools zum Entpacken oder Reparieren.** zurg spielt direkt aus RAR-Sets ab und baut fehlende Teile selbst aus den PAR2-Dateien des Releases wieder auf.
- **Ein Debrid-Konto.** Usenet funktioniert allein oder neben Real-Debrid und TorBox in derselben zurg-Bibliothek.
- **Eine Mitgliedschaft bei einem Indexer**, zumindest zum Start. Siehe unten [die Indexer-Frage](#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers).

Lohnt sich später: **ein zweiter Provider.** Ein Beitrag, den ein Provider verloren hat, ist oft noch auf einem anderen vorhanden. Fehlt bei einem ein Teil, fragt zurg den nächsten. Mit nur einem Provider muss zurg das ganze Release lesen, um diesen Teil neu zu bauen. Siehe [a second news server](../zurg/providers/usenet.md#a-second-news-server-is-worth-more-than-it-looks).

## So spielt zurg mit {#how-zurg-plays-it}

1. Eine NZB landet im Ordner `nzbs/` von zurg. Das machst du selbst, oder Sonarr, Radarr oder zurg selbst übernehmen das.
2. Innerhalb einer oder zwei Sekunden liest zurg sie ein und listet das Release in seiner Bibliothek auf, benannt nach der NZB.
3. Du drückst in Plex, Jellyfin oder rex auf Play. zurg holt die Teile für genau diese Stelle von deinem Provider und reicht sie weiter. Springst du weiter vor, holt es die Teile ab dort.

Niemand muss auf einen abgeschlossenen Download warten. Um alles Schritt für Schritt einzurichten, folge [Usenet with zurg](../zurg/guides/usenet.md). Die Provider-Einstellungen und Docker-Details findest du unter [Usenet provider](../zurg/providers/usenet.md).

## Wo DMM ins Spiel kommt {#where-dmm-fits}

Jede Film- und Serienseite auf [DMM](https://debridmediamanager.com) hat neben **Torrents** einen Tab **Usenet**. Dort stehen die Usenet-Releases des jeweiligen Titels aus den Indexern von DMM. Jeder, der bei DMM angemeldet ist, kann ihn nutzen.

![DMM's Usenet tab for Night of the Living Dead (1968), signed in with TorBox Pro](../assets/usenet-for-beginners/01-dmm-usenet-tab.webp)

Was du mit einer Zeile machen kannst, hängt davon ab, womit du bei DMM angemeldet bist:

| Button | Was er macht | Benötigt |
|---|---|---|
| Das Dateisymbol ganz rechts oder **NZB**, wenn es der einzige Button ist | Speichert die NZB, benannt nach dem Release, ohne das Wasserzeichen des Indexers. Leg sie in zurgs Ordner `nzbs/`. | Eine DMM-Anmeldung |
| **Send** | DMM holt das Release aus Usenet und fügt es deiner Real-Debrid-Bibliothek hinzu. Dafür brauchst du kein Usenet-Konto. | Real-Debrid |
| **TorBox** | Schickt die NZB an TorBox, das das Release für dich herunterlädt. | TorBox Pro, siehe [TorBox in DMM](../dmm/torbox.md) |

Sponsoren bekommen zwei weitere Funktionen:

- **zurg sucht für dich in den Indexern von DMM.** Wenn dein DMM-API-Key als `dmm_api_key` in zurgs Konfiguration steht und du keine eigenen Indexer hast, sucht zurg in den Indexern von DMM, wenn es deine [DMM-Wunschliste](../zurg/guides/dmm-wanted.md) oder deine [Watchlist](../zurg/guides/acquisition.md) abruft.
- **DMM als Newznab-Indexer** für Sonarr, Radarr und Prowlarr. Richte ihn auf DMMs [Newznab-Seite](https://debridmediamanager.com/newznab) ein. Jeder Key bekommt 30 Suchen und 15 Grabs pro Minute sowie 250 Grabs pro Tag.

## Wenn etwas nicht stimmt {#when-something-is-wrong}

| Was du siehst | Was du tun solltest |
|---|---|
| zurg-Log: `Cannot reach the news server for nzb` | zurg kann sich nicht bei deinem Anbieter anmelden. Prüfe Serveradresse, Benutzername und Passwort. Port `563` gehört zu `tls: true`, Port `119` zu `tls: false`. |
| zurg-Log: `Usenet account <name> is not reachable` | Einer von mehreren Accounts ist ausgefallen, die anderen funktionieren weiter. Korrigiere die Daten dieses Accounts. |
| Dein Anbieter lehnt Verbindungen ab, zum Beispiel `502 Too many connections` | `connections` in zurgs Konfiguration ist höher, als dein Tarif erlaubt, oder eine andere App nutzt denselben Login. Setze den Wert auf die Anzahl deines Tarifs. |
| Ein Release taucht als `indexer_download_48213` oder ähnlich auf | zurg benennt ein Release nach seiner NZB-Datei. Benenne die `.nzb` in den Release-Namen um. |
| Eine Datei im Release hat einen zufälligen Namen | Der Post hat seine Dateinamen versteckt und zurg konnte sie nicht wiederherstellen. Wähle ein anderes Release. |
| zurg-Log: `rar: RAR4 header-encrypted archives are not supported` | Das Archiv dieses Releases ist in einem alten Format verschlüsselt, das zurg nicht öffnen kann. Wähle ein anderes Release. |
| Wiedergabe ruckelt oder eine Lücke spielt stumm ab | Teile des Releases fehlen bei deinem Anbieter. zurg baut sie aus PAR2-Dateien wieder auf, wenn der Post welche hat. Ein zweiter Anbieter behebt die meisten dieser Fälle. |
| DMM: **No Usenet results found.** | Die Indexer von DMM haben nichts zu diesem Titel. Probiere den Tab **Torrents** oder deinen eigenen Indexer. |

Die vollständige Fehlerbehebungstabelle findest du unter [Usenet mit zurg](../zurg/guides/usenet.md#troubleshooting). Hängst du fest? Frag im Forum **zurg-support** auf [Discord](https://discord.com/invite/7u4YjMThXP). [Hilfe bekommen](remote-help.md) erklärt, was du angeben solltest.

## Fragen {#questions}

### Kann mir jemand das Usenet-System erklären? {#can-someone-explain-the-usenet-system-to-me}

Usenet ist ein Netzwerk aus Nachrichtenservern, auf denen Beiträge gespeichert werden. Ein Release wird als tausende kleine Teile gepostet. Ein Provider verkauft dir den Zugang zu seinen Servern, eine NZB listet die Teile eines Releases auf, und ein Indexer ist der Ort, an dem du nach NZBs suchst. zurg nimmt eine NZB und spielt das Release direkt von deinem Provider ab.

### Muss man bei den Usenet-Indexern eine Lifetime-Mitgliedschaft haben? {#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers}

Nein, du brauchst keinen Indexer, um loszulegen: Der Usenet-Tab von DMM findet NZBs für dich, und das zurg eines Sponsors kann die Indexer von DMM selbst durchsuchen. Wenn du für mehr Ergebnisse deinen eigenen Indexer willst, funktioniert jeder Newznab-Indexer in zurg, Sonarr und Radarr, egal für welchen Plan du dich entscheidest.

### Wie sollen die Dateien für Usenet benannt werden? {#how-are-the-files-supposed-to-be-named-for-usenet}

Benenne die NZB nach dem Release, etwa `Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb`. zurg verwendet diesen Namen für den Ordner des Releases, und danach gleichen Plex und die anderen Apps ab. Hat eine NZB einen Namen in sich, wird stattdessen dieser verwendet. Der NZB-Button in DMM speichert die Datei bereits unter dem Release-Namen.

### Kann zurg Usenet? {#does-zurg-do-usenet}

Ja, in den Nightly-Builds für Sponsoren. Trag einfach die Daten deines Providers ein, leg NZBs in `nzbs/` ab, und sie lassen sich abspielen. [Usenet mit zurg](../zurg/guides/usenet.md) führt dich Schritt für Schritt durch die Einrichtung.

### Was ist TorBox NNTP? {#what-is-torbox-nntp}

TorBox' Pro-Tarif hat zwei Usenet-Funktionen. Auf der Preisseite steht Usenet nur bei Pro (geprüft am 14. November 2026).

- **Gehostete Usenet-Downloads.** TorBox lädt die ganze Veröffentlichung für dich herunter und liefert sie wie jeden anderen TorBox-Download aus. Schick NZBs vom Usenet-Tab in DMM oder vom `torbox_nzb`-Provider in zurg. Du brauchst keinen Login bei einem News-Server. Siehe [TorBox hosted Usenet](../zurg/providers/torbox-nzb.md).
- **Ein News-Server-Login (NNTP).** Du nutzt ihn in zurg wie jeden anderen Provider. Er erlaubt 10 Verbindungen. Im September 2026 fand er gemessen weniger von einer echten Bibliothek als drei andere kostenpflichtige Provider, deshalb eignet er sich am besten als Ersatz. Siehe [TorBox news server](../zurg/providers/torbox-news-server.md).

### Kann ich einen Usenet-Account an zwei Orten nutzen? {#can-i-use-one-usenet-account-in-two-places}

Lieber nicht. Zwei Apps mit demselben Login teilen sich dessen Verbindungen und werfen sich gegenseitig raus: Der Server kann die ältere Verbindung trennen, um die neuere reinzulassen. Manche Anbieter verbieten in ihren Bedingungen, ein Konto zu teilen. Gib jedem zurg sein eigenes Konto.
