# Changelog

## zurg findet Anime, tägliche Shows und Specials für Sonarr {#zurg-finds-anime-daily-shows-and-specials-for-sonarr}

Eine Sonarr-Quelle hat früher eine tägliche Serie, eine Anime-Serie und die Specials einer Serie übersprungen, mit je einer Warnung. Jetzt werden fehlende Episoden einer Daily-Show außerdem nach dem Tag angefragt, an dem sie ausgestrahlt wurde (`The Daily Show 2026.11.03`), die Episoden eines Animes nach der Nummer, mit der die Serie sie zählt (`Jujutsu Kaisen 30` ist die sechste Folge der zweiten Staffel), und Specials als Staffel `00`. Das gilt zusätzlich zur üblichen Suche nach Staffel und Episode. Sonarrs eigener Parser legt fest, welche Episode jeder Release ist, wie bei jeder Serie, und das Qualitätsprofil bewertet ihn wie bisher. Ein Video, das für einen Anime oder eine Daily-Show abgelegt wird, heißt `JUJUTSU KAISEN - S02E06 - <the release's own name>`, weil Sonarrs Rescan eine Datei nur anhand ihres Namens einordnet und `2nd Season - 06` sonst unter Staffel 1 einsortieren würde. Videos von normalen Serien und von Specials behalten ihre Namen. Specials kommen in den Ordner, den **Specials Folder Format** in Sonarr vorgibt, und nur ein Release mit `S00Exx` im Namen kann zu einem Special passen. Siehe [Was zurg Sonarr anfragt](../guides/acquisition.md#what-zurg-asks-sonarr-for).

## Einen gewünschten Film in 1080p und in 4K behalten {#keep-a-wanted-film-at-1080p-and-at-4k}

`quality: [1080p, 4k]` im `acquisition:`-Block sorgt dafür, dass zwei Kopien jedes Films auf deiner DMM-Wunschliste liegen. So kann ein 1080p-Fernseher eine davon abspielen, ohne die 4K-Datei umzuwandeln. Jede Kopie nimmt die beste Veröffentlichung, die höchstens ihre eigene Auflösung hat, und wird eigenständig bis dorthin aufgewertet. Solange nichts Besseres als 1080p erschienen ist, teilen sich die beiden eine Kopie. Serien und alle anderen Quellen bekommen weiterhin nur eine Kopie. Siehe [eine Kopie pro Auflösung](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

## zurg update funktioniert nach der Installation mit einer Zeile {#zurg-update-works-after-the-one-line-install}

Die Einzeiler-Installer melden dich über die GitHub CLI bei GitHub an. Sie haben sie dafür heruntergeladen und nach dem Abschluss wieder gelöscht. `zurg update` suchte dann nach der GitHub CLI, fand aber nichts. Es brach mit „no GitHub credential found“ ab, obwohl deine Anmeldung noch gespeichert war. Die GitHub CLI aus den Ubuntu-Paketen ist zu alt, um die Anmeldung weiterzugeben. Auch dort brach Update genauso ab.

`zurg update` nutzt jetzt auch die GitHub CLI, die die Installer neben zurg im Ordner `bin` ablegen. Eine Anmeldung, die die GitHub CLI ohne Keyring gespeichert hat, funktioniert jetzt auch dann, wenn die CLI selbst nicht mehr da ist. Findet es trotzdem nichts, gibt es den einen Befehl aus, der das behebt. Führe das Update des Installers einmal aus, danach meldet sich jedes weitere `zurg update` automatisch an.

## Viele alte Real-Debrid-Links, die gleichzeitig fehlschlagen, werden nicht mehr als Ausfall gezählt {#many-old-real-debrid-links-failing-at-once-is-no-longer-called-an-outage}

Real-Debrid-Links funktionieren ein paar Monate nach ihrer Erstellung nicht mehr. Deshalb hören Releases, die etwa zur gleichen Zeit hinzugefügt wurden, auch etwa zur gleichen Zeit auf abzuspielen. Wenn bei einem Reparaturdurchlauf mehr als fünf davon fehlschlugen, hat zurg "suspected provider-wide outage" ins Log geschrieben und die Reparatur aller außer fünf zurückgehalten. Dadurch blieb eine große Charge viel länger kaputt, und es sah so aus, als wäre Real-Debrid down. zurg fragt jetzt zuerst bei Real-Debrid auf demselben Account nach einem Release, das noch abspielbar ist. Wenn es abspielbar ist, sind die fehlschlagenden Links einfach alt, und jedes Release wird wie gewohnt repariert. Erst wenn Real-Debrid auch funktionierende Links ablehnt, wertet zurg das als Ausfall und wartet.

## Die Emby-Session-Links des Dashboards öffnen das Emby-Dashboard {#the-dashboards-emby-session-links-open-embys-dashboard}

Die Links „active sessions“ und „transcodes“ im Emby-Panel auf dem Dashboard öffneten `/web/#/dashboard`. Das ist die Adresse, die Jellyfin für diese Seite verwendet. Emby blieb dort für immer auf dem Startbildschirm hängen. Beide Links öffnen jetzt `/web/index.html#!/dashboard`, also die Adresse, die Emby selbst verwendet. Die Links im Jellyfin-Panel sind unverändert.

## Eine fehlende .nfo schickt eine Usenet-Veröffentlichung nicht mehr zur Reparatur {#a-missing-nfo-no-longer-sends-a-usenet-release-to-repair}

Alte Usenet-Posts verlieren oft zuerst ihre .nfo, während jedes Video und jeder Archivteil noch da ist. zurg hat das als Schaden am gesamten Release behandelt. Jedes Mal, wenn zurg auf so eine .nfo stieß, startete es eine Reparatur, und das wiederholte sich nach jedem Neustart. Echte Reparaturen mussten dann hinter Hunderten sinnlosen warten. Manche Releases, die einwandfrei abgespielt wurden, waren als nicht reparierbar markiert, und nur das Löschen der .nfo half.

Eine fehlende .nfo oder eine andere kleine Datei neben dem Video wird jetzt als leer behandelt und löst keine Reparatur aus. Sie markiert einen Release nicht mehr als nicht reparierbar. Ein beschädigtes Video kann wieder repariert werden, wenn die .nfo daneben fehlt. Releases, die so schon als nicht reparierbar markiert wurden, werden innerhalb von etwa einem Tag erneut geprüft und kommen von allein zurück.

## Usenet-Dateien spielen keine Stille mehr ab, wo ein Server den Artikel eines anderen Uploads geschickt hat {#usenet-files-no-longer-play-silence-where-a-server-sent-another-uploads-article}

Manche Newsserver antworten auf eine Anfrage für einen Artikel deiner Datei mit einem Artikel aus einem anderen Upload, der dieselbe Nummer hat.
zurg hat das nur bemerkt, wenn der andere Upload weniger Artikel hatte als deine Datei.
Bei kürzeren Dateien wie RAR-Volumes und kurzen Episoden hat zurg den falschen Artikel genommen und für diesen Abschnitt Stille abgespielt.
Im Log stand `an internal mapping failure in zurg`, und die Meldung sagte, dass der Offset `falls between two articles that are both present and neither covers`.
zurg prüft jetzt außerdem die Dateigröße, die jeder Artikel angibt.
Ein Artikel aus einer anderen Datei wird abgelehnt, und zurg fragt deine anderen Newskonten nach dem richtigen Artikel.
Artikel, die ein älterer Build bereits in seinem Artikel-Cache gespeichert hat, werden ebenfalls abgelehnt.
Mit nur einem Konto wird der Abschnitt trotzdem als Stille abgespielt.
Das Log zeigt jetzt an, dass ein Server einen Artikel einer anderen Datei geschickt hat, statt zurg die Schuld zu geben.

## Usenet-Verbindungen sind wieder mit voller Geschwindigkeit verfügbar, nachdem eine andere App das Konto nicht mehr nutzt {#usenet-connections-come-back-at-full-speed-after-another-app-stops-using-the-account}

Wenn dein Newsprovider zurg jemals wegen zu vieler Verbindungen abgewiesen hat, zum Beispiel weil noch ein anderes Programm oder ein früherer zurg-Lauf einige davon belegt hielt, hat zurg so lange weiter eine Verbindung pro Sekunde hinzugefügt, wie es lief, auch als wieder Platz frei war. Nach jeder ruhigen Phase begann ein Schwall von Abrufen erneut nur mit den zwei warmen Verbindungen. Dadurch brauchte ein großes Konto über eine Minute, um wieder volle Geschwindigkeit zu erreichen, und Importe standen hinter ihm in der Warteschlange, mit "waited 5s for a connection (queued for the account's allowance)" im Debug-Log. Sobald der Provider wieder eine Verbindung akzeptiert hat und eine Minute ohne eine weitere Abweisung vergangen ist, öffnet zurg jetzt sofort, was es braucht.

## Das Debug-Log zeigt an, wenn ein Abruf bei mehreren konfigurierten News-Servern auf eine Verbindung wartet {#the-debug-log-says-when-a-fetch-waits-for-a-connection-with-several-news-servers-configured}

Mit einem News-Server hinterließ ein Abruf, der länger als fünf Sekunden auf eine Verbindung wartete, eine Debug-Zeile, die genau das meldete. Mit zwei oder mehr Servern erschien diese Zeile nie, sodass sie beim Hinzufügen eines zweiten Servers verschwand, egal ob das Warten aufgehört hatte oder nicht. Die Zeile erscheint jetzt auch bei Setups mit mehreren Servern und nennt die Server, auf die der Abruf gewartet hat.

## Ein Usenet-Download ohne Reparaturdateien und mit einem toten ersten Artikel schlägt sofort fehl {#a-usenet-grab-with-no-repair-files-and-a-dead-first-article-fails-at-once}

Eine Veröffentlichung ohne PAR2-Dateien, deren erster Artikel auf jedem News-Server fehlte, wurde fünf Minuten lang festgehalten, bis Radarr oder Sonarr erfuhr, dass sie fehlgeschlagen war, und dabei auf eine Reparatur wartete, für die es nichts zu reparieren gab. zurg erkennt jetzt, dass keine Wiederherstellungsdaten vorhanden sind, und meldet den Grab sofort als fehlgeschlagen. So setzt der Client die Veröffentlichung auf die Blockliste und macht weiter.

## Ein Usenet-Download, den die Reparatur gerettet hat, wird nicht mehr fünf Minuten später als fehlgeschlagen gemeldet {#a-usenet-grab-that-repair-fixed-is-no-longer-reported-failed-five-minutes-later}

Wenn bei einem Grab ein paar Artikel fehlten und ihre PAR2-Dateien sie wiederherstellen konnten, hat zurg das Release repariert. Ein Read-ahead, das während der Reparatur lief, konnte aber die fehlenden Artikel erneut anfordern und wurde kurz nach Abschluss der Reparatur abgelehnt. Diese Ablehnung hat das Release wieder auf die Liste der beschädigten gesetzt. Dadurch wurde der Grab fünf Minuten lang zurückgehalten und dann als fehlgeschlagen gemeldet. Radarr oder Sonarr haben ein Release auf die Blockliste gesetzt, obwohl es einwandfrei abgespielt wurde. Eine Ablehnung für einen Artikel, den die Reparatur bereits wiederhergestellt hat, gilt nicht mehr als Beschädigung.

## Ersetzte Downloads, die eine .nfo oder Untertitel mitbrachten, werden ebenfalls gelöscht {#upgraded-downloads-that-came-with-an-nfo-or-subtitles-are-deleted-too}

Mit `magic.allow_delete` wurde ein gelöschtes Video, das nicht in einem RAR-Archiv lag, einzeln gelöscht. Die `.nfo`, Untertitel und Poster daneben, die beim Download gepostet wurden, blieben in deiner Bibliothek. Die NZB blieb in `nzbs/` und der Torrent auf deinem Debrid-Konto. Bei jedem Upgrade eines solchen Downloads blieb so etwas zurück. Jetzt wird der gesamte Download gelöscht, sobald nichts in `__magic__` ihn mehr verwendet. Ein Download bleibt erhalten, solange eine andere Episode davon noch in deiner Bibliothek liegt oder noch in ihrem eigenen Ordner auf den Import wartet. Untertitel, die Sonarr oder Radarr neben dem Video importiert haben, halten es ebenfalls, bis auch sie gelöscht werden.

## Ersetzte und fehlgeschlagene Usenet-Downloads sammeln sich nicht mehr an {#replaced-and-failed-usenet-downloads-no-longer-pile-up}

Mit `magic.allow_delete` wurde ein gelöschter Episode- oder Film, der aus einem RAR-Archiv stammte, nur ausgeblendet. Der Download, aus dem er kam, blieb in der Bibliothek, und seine NZB blieb dauerhaft in `nzbs/`. Wenn du einzelne Episoden auf ein Staffel-Pack upgradest, blieb dadurch für jede Episode einer übrig.

Jetzt wird der ganze Download gelöscht, sobald ihn nichts mehr in `__magic__` nutzt. Ein Download bleibt erhalten, solange eine andere Episode aus demselben Archiv noch in deiner Bibliothek ist. Er bleibt auch erhalten, solange in seinem eigenen Ordner noch etwas zum Importieren liegt.

Sonarr und Radarr bitten darum, die Dateien eines fehlgeschlagenen Downloads zu löschen, wenn sie ihn entfernen. zurg hat die NZB trotzdem behalten. Jetzt löscht zurg sie, wenn aus diesem Release nichts importiert wurde. Ein Download, der fertig und importiert wurde, behält seine NZB wie bisher, weil die importierte Datei weiterhin aus ihr abgespielt wird.

## zurg zeigt jetzt an, wann die Bibliothek fertig geladen ist {#zurg-now-says-when-the-library-has-finished-loading}

Docker hält zurg schon für „healthy“, sobald der Prozess läuft. Eine große Bibliothek kann danach aber noch über eine Stunde laden. Die Ordner im Mount schlagen die ganze Zeit mit `Input/output error` fehl, und es sieht aus, als wäre die Installation kaputt. Die neue Adresse `/ready` zeigt den Unterschied. Sie antwortet mit 503, bis die Bibliothek geladen ist, und danach mit 200. Ein Passwort braucht sie nicht. Im Container prüft `/app/healthcheck.sh --ready` dasselbe. Der eigene Health-Check des Containers fragt weiterhin nur, ob zurg läuft. So kann ein langer erster Ladevorgang den Container nicht neu starten lassen und auch keinen Mount aufhalten, der davon abhängt. Der Health-Check liest außerdem jetzt die Umgebungsvariable `PORT`. Ein Container, der `PORT` gesetzt hatte, wurde früher auf dem falschen Port geprüft.

## Die Beschaffung kann Veröffentlichungen anhand von Wörtern in ihren Namen überspringen {#acquisition-can-skip-releases-by-words-in-their-names}

Setze `exclude_words` im `acquisition:`-Block, dann nimmt zurg nie ein Release, dessen Name eines dieser Wörter enthält. `exclude_words: [DV, HDR10+]` hält Dolby Vision und HDR10+ von einem TV fern, der sie nicht abspielen kann, und nimmt trotzdem 4K mit einfachem HDR. Das funktioniert für die Plex-Watchlist, Seerr, Radarr und Sonarr sowie für Usenet und Torrents. Nur ganze Wörter zählen. `DV` trifft weder `DVDRip` noch einen Film namens Adventures. `DV`, `DoVi` und `Dolby Vision` bedeuten alle dasselbe, genauso wie `HDR10+` und `HDR10Plus`. Radarr und Sonarr werden zu einem ausgeschlossenen Release nie befragt.

## Radarr und Sonarr können zuerst die beste Qualität aus dem Profil nehmen {#radarr-and-sonarr-can-take-the-profiles-best-quality-first}

zurg nimmt normalerweise die erlaubte Veröffentlichung, die am schnellsten zu prüfen ist. Bei einem Film ist das meist ein 1080p WEB-DL. Der Upgrade-Durchlauf bewegt sich dann Richtung Cutoff deines Profils. Bei Serien kommt ein Staffel-Pack vor einzelnen Episoden. Ein 1080p-Pack kann also eine ganze Staffel füllen, auch wenn 2160p-Episoden vorhanden waren. Setze `best_first: true` unter `acquisition:`, dann folgt der erste Download stattdessen deinem Radarr- oder Sonarr-Qualitätsprofil. Zuerst kommt die beste Auflösung, die das Profil erlaubt. Alles auf oder über dem Cutoff gilt als gut genug. Wenn sich eine Veröffentlichung als nicht mehr verfügbar herausstellt, arbeitet zurg das Profil nach unten ab. Die erste Datei kann länger brauchen, weil die besten Veröffentlichungen oft große Multi-Part-Posts sind. Die Option ist standardmäßig deaktiviert.

## Torrent-Ergebnisse verdrängen keine NZBs mehr, wo kein Konto Torrents annimmt {#torrent-results-no-longer-crowd-out-nzbs-where-no-account-takes-torrents}

Auf einer Instanz mit einem NZB-Anbieter und ohne Debrid-Konto, das Torrents annimmt, hat die Acquisition trotzdem deine Torznab-Indexer durchsucht. Jeder gefundene Torrent hat dabei eine der drei Releases verbraucht, die ein Episoden- oder Staffel-Pack pro Versuch bekommt. Mit `prefer: torrents` oder wenn 4K-Torrents höher eingestuft waren als eine 1080p-NZB, wurden die NZBs nie ausprobiert und die Episode ist fehlgeschlagen. Auf solchen Instanzen werden Torznab-Indexer jetzt übersprungen, und im Log steht dazu eine Zeile. Ein Release, für das die Instanz keinen Platz hat, zählt außerdem nicht mehr als Versuch. Filme fragen Radarr bei solchen Torrents auch nicht mehr nach.

## Die Beschaffung zählt eine NZB nicht mehr als erledigt, wenn sie nicht abspielbar ist {#acquisition-no-longer-counts-an-nzb-as-done-where-nothing-can-play-it}

Auf einer Instanz mit einem Debrid-Konto und ohne NZB-Provider hat die Beschaffung trotzdem deine Newznab-Indexer durchsucht, und ein NZB, das sie geholt hat, wurde ohne jede Prüfung als erledigt gezählt. Dadurch konnte ein Titel aus deiner Plex-Watchlist von der Liste verschwinden, obwohl auf dieser Instanz nichts die Datei abspielen kann. Newznab-Indexer werden dort jetzt übersprungen, und in der Log steht dafür eine Zeile. Auf einer Instanz ohne NZB-Provider wird ein NZB außerdem nie als erledigt gezählt.

## Eine Veröffentlichung ohne abspielbare Inhalte wird einmal statt jeden Tag gemeldet {#a-release-with-nothing-left-to-play-is-reported-once-instead-of-every-day}

Als jede abspielbare Datei einer Veröffentlichung gelöscht war, warnte zurg jeden Tag erneut, dass sie „has no playable file that still reads“ hat. Hatte eine Bibliothek hundert solcher Veröffentlichungen, schrieb sie jeden Tag hundert dieser Warnungen in das Log, und das für Veröffentlichungen, die niemand angefasst hatte. Jetzt erscheint die Warnung nur noch einmal, und die Veröffentlichung wird erst wieder geprüft, wenn sich etwas an ihr ändert. Eine wiederhergestellte Datei wird weiterhin sofort wieder eingebunden.

## Defekte Veröffentlichungen bei AllDebrid und TorBox kommen zurück, wenn die Dateien noch abspielbar sind {#broken-releases-on-alldebrid-and-torbox-come-back-when-the-files-still-play}

Eine Release, die nur bei AllDebrid, TorBox, Premiumize, Offcloud oder Debrid-Link liegt, konnte wochenlang kaputt und versteckt bleiben, obwohl der Account sie noch ausgeliefert hat. Repair fügt Releases bei diesen Diensten nicht von selbst wieder hinzu, weil sie Inhalte absichtlich entfernen, und nichts anderes hat je geprüft, ob die Dateien wieder funktionieren. Repair fragt den Account jetzt einmal am Tag, ob die Dateien einer kaputten Release noch abspielbar sind, und holt die wieder rein, die funktionieren, ohne etwas hinzuzufügen. Alles, was der Account wirklich entfernt hat, braucht weiterhin den Repair-Button. Der MCP-Repair-Ausblick sagt jetzt dasselbe, statt dir zu sagen, dass ein Sweep niemals etwas dafür tun wird.

## Downloads, die TorBox für einen freien Slot einreiht, werden als eingereiht angezeigt und laufen fertig {#grabs-torbox-queues-for-a-free-slot-show-as-queued-and-finish}

Wenn alle Download-Slots eines TorBox-Accounts belegt waren, hat TorBox neue Grabs
von Sonarr und Radarr in seine Warteschlange gesetzt, und zurg hat sie aus den Augen verloren. Der Grab
wurde etwa zehn Minuten lang als „fetching metadata“ angezeigt und danach als Fehler, also hat
Sonarr und Radarr ihn verworfen. Als TorBox ihn später heruntergeladen hat, hat ihn nichts importiert.
zurg verfolgt einen wartenden Grab jetzt, bis TorBox ihn startet, und dann weiter, bis er fertig ist. Solange er wartet, wird er als „queued“ angezeigt, und der Timeout bei fehlendem Fortschritt läuft erst, wenn TorBox ihn gestartet hat.

## Du kannst auf der Seite `__magic__` nach einer einzelnen Veröffentlichung suchen {#you-can-search-for-one-release-on-the-__magic__-page}

Bei einer Bibliothek, die Sonarr oder Radarr organisiert, bleibt bei jedem Import ein verstecktes Job-Verzeichnis zurück, und die `__magic__`-Seite zeigt nur die ersten tausend gespeicherten Zeilen. Das Release, das du suchst, war meist nicht darunter. Deshalb waren seine Buttons Unhide und Reset nicht erreichbar, und der Hinweis unter der Liste verwies stattdessen auf data/magic.json. Diese Datei zu bearbeiten, während zurg läuft, funktioniert nicht: zurg schreibt sie beim Beenden aus dem Speicher neu, und dann sind die Zeilen nach einem Neustart wieder da.

Die gespeicherten Zeilen und hängenden Seiten haben jetzt ein Suchfeld. Gib einen Release-Namen, einen Pfad aus deinem Mount oder einen Hash ein, und jede Zeile, die zu diesem Release gespeichert ist, wird mit ihren Buttons angezeigt, egal wie groß die Tabelle ist.

Damit kannst du auch ein Release zurückholen, das in `__all__` steht, aber nie in `__magic__/__all__.` auftaucht. Wenn du ein Release löschst und wieder hinzufügst oder es aus DMM neu einfügst, bleibt sein Hash gleich. Es kommt dann mit allem zurück, was `__magic__` darüber gespeichert hatte, inklusive des Job-Verzeichnisses, das nach dem Import gelöscht wurde. Such nach dem Release und drück auf Unhide in seiner release-tombstone-Zeile.

## `__magic__` unter Windows lässt sein Journal nicht mehr endlos wachsen {#__magic__-on-windows-stops-growing-its-journal-forever}

On Windows, zurg logged `cannot truncate data\magic.journal ... Access is
denied.` every time it tried to tidy the file where `__magic__` records your
moves and folders. The file was never emptied, so it grew with every change
and every start read all of it again. After a few thousand changes in one run,
each further change also rewrote the whole saved layout. zurg now empties it
on Windows as it always did elsewhere, and the first start after updating
clears what has piled up. If tidying ever fails, zurg tries again after more
changes instead of on every one.

## Eine Datei über MCP wiederherzustellen bringt ihre Veröffentlichung sofort zurück {#restoring-a-file-over-mcp-puts-its-release-back-right-away}

Ein Wiederherstellen einer Datei mit dem MCP-Tool `zurg_release_file_restore` hat die Datei zwar zurückgebracht, das Release blieb aber als defekt markiert und in `__unplayable__`, bis zum nächsten Bibliotheks-Refresh. Jetzt macht es dasselbe wie der Restore-Button im Torrent-Manager: Das Release verlässt `__unplayable__`, kommt mit seinen .strm-Dateien zurück in seine Ordner und wird so gespeichert. Wie bisher fragt es Plex, Jellyfin oder dein on_library_update-Skript nicht an, um neu zu scannen.

## Dateien, die eine fehlgeschlagene Reparatur ausgeblendet hat, werden wieder angezeigt {#bring-back-files-a-failed-repair-hid}

Ältere Builds haben eine Datei als gelöscht markiert, wenn eine Reparatur bei einem Account aufgegeben hat, auch wenn ein anderer Account sie noch abspielen konnte. Dann war das Release in jedem Ordner verschwunden. Der Torrent-Manager hat jetzt einen neuen Filter „Deleted, still served“. Er listet Releases auf, bei denen nichts mehr abspielbar ist, deren gelöschte Datei aber noch von einem Account ausgeliefert wird. Wenn du den Restore-Button gedrückt hältst, prüft zurg den Link jeder Datei und legt die abspielbaren Dateien wieder in ihre Ordner. Das passiert genauso, als würdest du bei jeder Datei einzeln auf Restore klicken.

zurg macht das nicht von selbst. Eine Datei, die du absichtlich gelöscht hast, wird genauso gespeichert. Schau die Liste also durch und stell nur das wieder her, was du nicht selbst gelöscht hast. Releases, die noch etwas abspielen, werden nicht angezeigt, denn das Löschen eines Extras oder einer Episode ist meist eine absichtliche Löschung.

## Die Beschaffung schaut über die erste Seite der Suchergebnisse hinaus {#acquisition-looks-past-the-first-page-of-search-results}

Früher hat die Suche nur die erste Seite gelesen, die ein Indexer zurückgegeben hat. Mit DMM, das pro Seite zehn Ergebnisse liefert, und zwar die größten zuerst, konnte ein Größenlimit alle davon entfernen. Dann ist der Film alle paar Stunden mit "no eligible releases" fehlgeschlagen, obwohl auf den nächsten Seiten kleinere Releases lagen. Jetzt werden so lange weitere Seiten angefragt, bis genug Releases gefunden sind, die zu deinen Limits passen, maximal zehn Seiten. Bei Serien wird eine Episode, die die Staffelsuche nicht gefunden hat, was meist eine ältere Folge ist, wenn die neueste Folge die Ergebnisse füllt, jetzt einzeln gesucht.

## Tote Dateien in den Film- und Serienordnern von `__magic__` fallen jetzt heraus, damit Radarr und Sonarr es bemerken {#dead-files-in-__magic__-movie-and-show-folders-now-drop-out-so-radarr-and-sonarr-notice}

Eine Datei, die Radarr oder Sonarr in einen Ordner unter `__magic__` importiert hatten, wurde nach dem Ausfall des Releases weiterhin in voller Größe angezeigt. Dadurch sah ein Rescan sie noch, und der Film oder die Episode wurde nie wieder als gesucht markiert. Jetzt verschwindet sie aus dem Ordner im selben Moment wie aus allen anderen Listen: sobald Repair sie nicht mehr wiederherstellen kann, bzw. einen Tag nach dem Ausfall, wenn Repair deaktiviert ist. Beim nächsten Rescan wird sie als fehlend markiert, und die Acquisition sucht nach einem Ersatz. Funktioniert die Datei wieder, taucht sie an derselben Stelle wieder auf.

## Season Fix sortiert Multi-Staffel-Pakete und nummerierte Extras {#season-fix-sorts-multi-season-packs-and-numbered-extras}

Season Fix liest jetzt selbst die Staffel aus, die jede Datei im Namen trägt. So landet bei einem Pack wie `Full Metal Panic S2 - 01`, `Bakuman II - 01`, `KonoSuba 2 - 01` oder `Demon Slayer Mugen Train Arc - 01` jede Folge in ihrer eigenen Staffel, statt dass Plex alle auf Staffel 1 stapelt. Batches mit Romaji-Namen oder mit einem Zusatz, etwa `Sergeant Keroro 001-358` oder `Dragon Ball Z COMPLETE`, werden erkannt, wenn ihre Dateien denselben Titel teilen. Namen mit Unterstrichen, `Ep01`, `1.01.` oder einer Zahl im Episodentitel werden so gelesen, wie sie gemeint sind.

Nummerierte Extras wie `Special 01`, `OVA 01`, `- 11 (OVA)` und `24.5`-Recaps hingen früher als zweite Version an einer echten Folge, und Play konnte das Extra auswählen. Sie werden jetzt mit dem Suffix `-other` von Plex umbenannt, damit sie als Extras angezeigt werden.

## Ein toter Real-Debrid-Link blockiert keinen Bibliotheks-Scan mehr minutenlang {#a-dead-real-debrid-link-no-longer-holds-a-library-scan-for-minutes}

Wenn Real-Debrid bei einer Datei immer wieder denselben widerrufenen Link liefert, wartet zurg ein paar Minuten ab, weil das direkt nach dem Entfernen eines Downloads ganz normal ist. Eine Datei, die auch nach fünf Minuten so abgelehnt wird, gilt jetzt als defekter Link und wird zur Reparatur geschickt, statt dem Leser zu sagen, er solle es später noch einmal versuchen. Früher konnte eine einzelne defekte Datei einen Plex-Scan etwa zehn Minuten lang blockieren.

## Fehlgeschlagene und hängende Usenet-Aufträge lassen sich auf der Seite `__magic__` entfernen {#failed-and-stuck-usenet-jobs-can-be-cleared-from-the-__magic__-page}

Ein Job mit dem Status Failed oder Stuck in der SABnzbd-Liste blieb für immer dort, nachdem Sonarr oder Radarr zurg nicht mehr als Download-Client nutzten. Ein Neustart hat ihn nicht entfernt. Der einzige Weg war, `data/sabnzbd-jobs.json` von Hand zu löschen. Auf der Jobliste der Seite `__magic__` hat jetzt jeder Failed- oder Stuck-Job einen **Clear**-Button, und über der Liste gibt es einen Button, der alle auf einmal löscht. Halte ihn gedrückt, bis der Balken voll ist.
Queued- und Completed-Jobs werden nie angefasst. Die NZB des Jobs wird ebenfalls gelöscht, es sei denn, ein Import unter `__magic__` verwendet dieses Release noch.

## Das Stremio-Addon sagt, wenn es https braucht {#the-stremio-addon-says-when-it-needs-https}

Stremio lädt ein Addon nur dann über einfaches http, wenn es auf demselben Rechner läuft. Auf einem Fernseher, einem Handy oder einem anderen Computer schlägt eine http-Adresse mit "failed to load manifest" fehl, auch wenn das Gerät zurg erreichen kann. Die Config-Seite zeigt das jetzt direkt neben der Addon-URL an, wenn du sie über eine solche http-Adresse geöffnet hast. Der Stremio-Guide zeigt drei Wege, zurg hinter https zu bringen: Tailscale Serve, deinen eigenen Reverse Proxy und einen Cloudflare-Tunnel.

## Plex übernimmt einen Film oder eine Episode, sobald Radarr oder Sonarr sie in `__magic__` importiert {#plex-picks-up-a-movie-or-episode-as-soon-as-radarr-or-sonarr-imports-it-into-__magic__}

Nachdem Radarr oder Sonarr eine Datei in einen Ordner unter `__magic__` verschoben hat, hat zurg Plex gebeten,
die Datei selbst zu scannen. Plex scannt aber nur Ordner. Deshalb hat es so getan, als wäre alles in Ordnung,
und nichts hinzugefügt. Der Film fehlte so lange, bis Plex den nächsten geplanten Scan gemacht hat.
zurg bittet Plex jetzt, den Ordner zu scannen, in dem die Datei gelandet ist. Dasselbe gilt für die Datei,
die ein Upgrade ersetzt, damit die alte Version verschwindet. Es gilt auch für die manuellen Scan-Endpunkte, das
MCP-Tool `zurg_plex_scan_releases`, Scans nach einem Umbenennen oder Löschen einer Datei und die Pfade,
die an `on_library_update` übergeben werden.

## Die Seite Manage listet doppelte Veröffentlichungen und zeigt, welche Radarr oder Sonarr verwendet {#the-manage-page-lists-duplicate-releases-and-which-one-radarr-or-sonarr-uses}

Ein Upgrade lässt die Release, die es ersetzt hat, in deiner Bibliothek liegen, und Grabs von verschiedenen Indexern können dazu führen, dass ein Film oder eine Staffel mehrfach vorhanden ist. Die neue Duplicates-Ansicht auf der Manage-Seite gruppiert Releases, die denselben Film oder dieselben Episoden enthalten, und zeigt dir, welche Radarr bzw. Sonarr gerade verwendet. zurg ermittelt das anhand des Speicherorts der Datei in `__magic__`, nicht anhand der Release-Namen.

Bei einer Staffel listet sie jede Episode auf, die mehr als eine Release enthält, und welche Release die Datei von Sonarr enthält. So wird ein Pack, aus dem Sonarr nur ein paar Episoden nimmt, trotzdem als in Benutzung angezeigt. Jede andere Release wird mit "No reference found" oder "Unknown" markiert, zusammen mit dem Grund. Wähl die aus, die du loswerden willst. Vor dem Löschen liest zurg Radarr und Sonarr noch einmal ein und lässt alles aus, was seitdem in Benutzung gekommen ist. Es wird nie automatisch etwas gelöscht.

## Die belegten Download-Slots von TorBox werden so gezählt, wie TorBox sie zählt {#torboxs-busy-download-slots-are-counted-the-way-torbox-counts-them}

Bevor die Reparatur oder eine erste Wiedergabe einen Torrent zu TorBox hinzufügt, prüft zurg, ob das Konto einen freien Download-Slot hat. Bisher wurden alle Torrents gezählt, die nicht vollständig heruntergeladen waren. Dabei wurden Torrents übersehen, die gerade seeden, und TorBox rechnet diese bis zu 30 Tage auf deinen Tarif an. Außerdem wurden Torrents mitgezählt, deren Inhalt abgelaufen war, und die gar keinen Slot belegen. Ein paar abgelaufene Torrents in einer Bibliothek konnten dazu führen, dass die Reparatur wartete, als wären alle Slots belegt.
zurg zählt jetzt genau die Torrents, die TorBox als aktiv markiert.

## TorBox kann für private Tracker seeden {#torbox-can-seed-for-private-trackers}

Eine neue Einstellung, `tb_seed_torrents`, legt fest, ob die Torrents, die zurg zu TorBox hinzufügt, geseedet werden. Sie steht standardmäßig auf `never`, daran ändert sich also nichts, wenn du sie nicht anfasst. Setz sie auf `always`, wenn ein Private Tracker dein Ratio braucht, oder auf `auto`, damit die Seeding-Einstellung in deinem TorBox-Konto entscheidet. Du kannst sie im Bereich Health & Repairs des Dashboards ändern, und sie greift beim nächsten Hinzufügen.

Ein Torrent, der seedet, belegt so lange einen der aktiven Slots deines TorBox-Tarifs, wie er seedet, bei Pro bis zu 30 Tage. Wenn seedende Torrents alle Slots belegen, müssen neue Grabs und Reparaturen auf diesem Konto warten, bis wieder einer frei wird.

## RAR-Sets, deren Volumes in falscher Reihenfolge benannt sind, lassen sich jetzt abspielen {#rar-sets-whose-volumes-are-named-out-of-order-now-play}

Eine Veröffentlichung, bei der jeder RAR-Teil einen anderen Namen trägt, etwa einen zufälligen Namen pro Teil oder `Movie 2026 part1.rar`, erschien früher als ein Archiv pro Teil. Das erste zeigte den Film an, hörte aber nach dem ersten Teil auf zu funktionieren, und die anderen zeigten nichts an. zurg liest jetzt aus dem Teil selbst, wohin jeder Teil gehört, und setzt das Set wieder zusammen. Früher musstest du die Teile von Hand in `part001.rar` und so weiter umbenennen, um das zu erreichen. Das passiert aber nur, wenn die Teile sich selbst zu einem vollständigen Set nummerieren. Fehlt einer oder beansprucht ein anderer denselben Platz, bleibt die Veröffentlichung unverändert und das Log sagt dir, warum. Komprimierte Archive, deren Teile außer der Reihe gepostet wurden, lassen sich jetzt auch abspielen.

## Ein Plex-Scan, der noch analysiert, wird nicht mehr als hängend gemeldet {#a-plex-scan-that-is-still-analysing-is-no-longer-reported-as-stuck}

Plex hält den Fortschritt und den aktuellen Ordner eines Bibliotheksscans unverändert, während es die gefundenen Dateien analysiert. Das kann bei einer großen oder entfernten Bibliothek lange dauern. Das Dashboard hat das früher als hängenden Scan gemeldet und vorgeschlagen, Plex mitten im Scan neu zu starten. Jetzt hört zurg auf den eigenen Update-Feed von Plex und zählt die Elemente, an denen Plex gerade arbeitet. So wird nur ein Scan markiert, der wirklich stehen geblieben ist.

## Nur-gecachte Torrent-Uploads bewahren die Ablehnung beim Hinzufügen bei ratenbegrenzten Anbietern {#cached-only-torrent-uploads-preserve-the-refusing-add-on-rate-paced-providers}

Eine `.torrent`-Datei, die im Modus cached-only eingereicht wird, landet jetzt bei TorBox im Hinzufügen-Pfad, der ablehnt, auch wenn das stündliche Hinzufüge-Limit das Backend umschließt. Ein nicht gecachter Treffer erzeugt keinen Transfer und belegt keinen aktiven Slot, verbraucht aber trotzdem eines der 60 nicht gecachten Hinzufügen pro Stunde bei TorBox. Normale Hinzufügungen laden weiterhin die Originaldatei hoch. Die qBittorrent-Anleitung listet jetzt alle sechs Anbieter für den Torrent-Upload auf und erklärt die unterschiedlichen cached-only-Wege bei Debrid-Link und TorBox.

## Eine Datei, die du während der Wiederherstellung löschst, bleibt gelöscht {#a-file-you-delete-while-it-is-being-restored-stays-deleted}

Das Löschen einer Datei oder eines Releases, während ein Restore noch den Link prüft, wartet jetzt auf diese Prüfung und setzt sich dann durch. Ein Library-Refresh, der bereits lief, kann ein gerade gelöschtes Release nicht mehr zurückbringen.

## Ein weiter Sprung in ein komprimiertes Archiv hängt den Reader nicht mehr auf {#a-seek-far-into-a-compressed-archive-no-longer-hangs-the-reader}

Eine Datei in einem komprimierten RAR- oder ZIP-Archiv lässt sich nur vom Anfang her entpacken. Ein Lesezugriff nahe dem Ende einer großen Datei musste deshalb bisher auf das gesamte Archiv warten, ohne dass eine Antwort kam. Plex konnte bei so einem Zugriff über eine Stunde hängen bleiben, was ausreichte, um die Datenbank zu blockieren. zurg antwortet jetzt innerhalb von 20 Sekunden, behält den Fortschritt, den es bis dahin gemacht hat, und bereitet das Ende der Datei im Hintergrund vor, damit der nächste Lesezugriff darauf sofort erfolgt.

## Real-Debrid-Ablehnungen folgen den veröffentlichten Dateinamensregeln {#real-debrid-refusals-follow-the-published-filename-rules}

Wenn Real-Debrid beim Reparieren das erneute Hinzufügen eines Releases verweigert, prüft zurg jetzt den Namen des Releases und die Namen seiner Dateien anhand der veröffentlichten Dateinamensregeln. Ein Release, das gegen diese Regeln verstößt, wird dauerhaft als infringing markiert. Jede andere Verweigerung wird als Drosselung der Hinzufügungen durch Real-Debrid behandelt, und das Release bleibt für den nächsten Reparaturdurchlauf vorgemerkt, statt aussortiert zu werden.

## Eine Wiederherstellung legt die Datei sofort wieder dort ab, wo sie hingehört {#restoring-a-file-puts-it-back-where-it-belongs-straight-away}

Die Aktion Restore auf der Verwaltungsseite eines Releases verschiebt das Release jetzt in seine Verzeichnisse zurück, speichert den wiederhergestellten Zustand und schreibt seine STRM-Datei, sobald die Datei geprüft ist. Eine wiederhergestellte Datei liegt nicht mehr im Verzeichnis für nicht abspielbare Dateien, bis der nächste Provider-Refresh kommt. Und ein Release, dessen letzte kaputte Datei wiederhergestellt wurde, wird nach einem Neustart nicht mehr als defekt gemeldet. Gelöschte Dateien bleiben gelöscht, bis du sie wiederherstellst.

## Fremde Usenet-Artikel werden abgelehnt, bevor Bytes ausgeliefert werden {#reject-foreign-usenet-articles-before-serving-bytes}

Lehne Usenet-Artikel mit derselben Nummer ab, deren positive yEnc-Gesamtgröße unter der höchsten Nummer in der NZB liegt. Das gilt auch für den gespeicherten Cache und die progressiven Pfade, damit gültige Fallback-Konten die Bytes liefern.

## Belegbasierte Klassifizierung von RD-Ablehnungen bleibt erhalten {#preserve-evidence-backed-rd-refusal-classification}

Behandle addMagnet-451-Antworten still als Release-Ablehnungen, es sei denn, kontospezifische Throttling-Belege decken den gesamten Vorgang ab. Temporäre Fehler bleiben während der Reparatur erhalten.

## Lesefenster für abgelaufene, defekte Dateien werden klarer erklärt {#clarify-expired-broken-file-read-windows}

Ein abgelaufenes Zeitfenster für Lesewiederholungen bei defekten Dateien melden, ohne zu behaupten, dass die Reparatur aufgegeben wurde.

## Aufgezeichneter Dateizustand wird über MCP bereitgestellt {#expose-recorded-file-health-in-mcp}

Zeige aufgezeichnete Gesundheitszahlen pro Datei in den MCP-Release-Ansichten an und halte die Tabellen mit verzögert geladenen Dateien sicher einsehbar, ohne zu behaupten, dass ein Lifecycle-Status eine Live-Serving-Prüfung ist.

## Doppelte Sidecar-Operationen werden behandelt {#handle-duplicate-sidecar-operations}

Typisierte Antworten für fehlende Quellen von doppelten WebDAV-Aliasen erkennen, dabei aber echte Fehler bei allen Versuchen und Berechtigungsfehler weiterhin beibehalten.

## Ein erneuter Download unter demselben Namen wird repariert statt als fehlgeschlagen markiert {#a-re-grab-under-the-same-name-is-repaired-instead-of-failed}

Einen NZB erneut unter einem Namen holen, den zurg schon kennt, prüft und repariert die alte Kopie nicht mehr, während die neue gelesen wird. Der Download wartet auf die neue Datei. So wird ein Release mit einem fehlenden Artikel, den PAR2 wiederherstellen kann, repariert und fertiggestellt, statt als fehlgeschlagen gemeldet zu werden.

## Reparaturfehler werden nicht mehr als Löschungen durch Nutzer dargestellt {#repair-failures-no-longer-masquerade-as-user-deletions}

Fehlgeschlagene automatische Reparaturen markieren jetzt nur die fehlerhafte Provider-Quelle als defekt. Gesunde Alternativkopien bleiben erhalten, und spätere Provider-Aktualisierungen können die Sichtbarkeit der Datei wiederherstellen.

## Torrents ohne IMDb-ID werden über DMM anhand des Release-Namens identifiziert {#torrents-without-an-imdb-id-are-identified-by-release-name-through-dmm}

Wenn `dmm_metadata_secret` gesetzt ist, braucht der IMDb-Job keinen OpenSubtitles-Key mehr. Torrents ohne ID oder nur mit dem Miss-Marker von OpenSubtitles werden beim Start anhand eines `imdb-tt…`-Tags in ihrem Namen erkannt. Falls das nicht klappt, übernimmt der DMM-Resolver. Der antwortet aber nur, wenn genau ein Titel exakt passt. Fansub-Romanisierungen wie "Kaijuu 8-gou" werden über die Aliase von DMM zu Kaiju No. 8 aufgelöst, und ein Name, den mehrere Serien teilen, bleibt unberührt. Ein Torrent, den DMM nicht benennen kann, behält eine leere ID, sodass ein Plex-Match sie trotzdem noch füllen kann.

## Ein Radarr-Film, den kein Indexer über seine ID kennt, wird anhand des Namens gesucht {#a-radarr-movie-that-no-indexer-knows-by-id-is-searched-for-by-name}

Viele Usenet-Posts sind ohne IMDb- oder TMDB-ID indexiert. zurg hat bei einem Radarr-Film nur nach der ID gesucht. Deshalb ist ein Dokumentarfilm, den kein Indexer per ID beantworten konnte, mit "no eligible releases" fehlgeschlagen, obwohl die eigene Suche von Radarr nach dem Namen einen sauberen Release gefunden hat. Wenn die ID-Suche nichts zum Übernehmen findet, sucht zurg jetzt zusätzlich nach Titel und Jahr. Der eigene Parser von Radarr entscheidet weiterhin, ob jedes Ergebnis wirklich der Film ist. Eine Suche nach dem Namen folgt nur dann, wenn die ID-Suche gar nichts gefunden hat. Ein Film, den die ID-Suche findet, wird per ID indexiert. Würde zurg dann noch einmal nach dem Namen suchen, würde es nur dieselben Posts noch einmal holen.

## NZBs, die über Prowlarr gefunden werden, können heruntergeladen werden {#nzbs-found-through-prowlarr-can-be-downloaded}

Prowlarr leitet jede Usenet-NZB per Weiterleitung zum Indexer um, und das lässt sich nicht abschalten. zurg folgte einer Weiterleitung bisher nur, wenn sie auf denselben Host zeigte. Deshalb schlug bei Indexern, die über Prowlarr eingerichtet waren, jede NZB-Übernahme mit "answered 301 Moved Permanently" fehl, und es wurde nie etwas übernommen. Die Weiterleitung wird jetzt verfolgt. Der eigene API-Schlüssel des Links erreicht aber weiterhin nie den anderen Host, und eine Weiterleitung von HTTPS auf unverschlüsseltes HTTP wird nach wie vor abgelehnt.

## Ein Indexer, der stundenlang ablehnt, blockiert die Beschaffung nicht mehr {#an-indexer-that-refuses-for-hours-no-longer-stalls-acquisition}

Prowlarr antwortet auf eine Suche bei einem Indexer, den es deaktiviert hat, mit `429` und einem
`Retry-After` von vielen Stunden. zurg hat zwei Minuten gewartet und dann noch einmal gefragt, dreimal
insgesamt. Jede Suche hat bei diesem einen Indexer also sechs Minuten gekostet. Die Acquisition hat jeden
Titel nach fünf Versuchen aufgegeben und dabei alles weggeworfen, was alle anderen Indexer schon
beantwortet hatten. Deshalb wurde bis zur Rückkehr des Indexers gar nichts erworben.
Ein Indexer, der länger als zwei Minuten um Ruhe bittet, wird jetzt bis zu dem Zeitpunkt übersprungen,
den er nennt, und die Suchen laufen bei den anderen weiter.

## Ein Titel, der nach der Beschaffung gelöscht wurde, wird erneut gesucht {#a-title-deleted-after-acquisition-is-searched-for-again}

Wenn eine Datei, die zurg für Sonarr oder Radarr besorgt hatte, gelöscht wurde, weil sie nicht die gewünschte Version war oder aus einem anderen Grund, und der Titel wieder auf der Liste der fehlenden Einträge auftauchte, antwortete zurg mit "completed without a search, the release was already held" und suchte nie wieder danach. zurg prüft jetzt zuerst den Staffel- oder Filmordner in `__magic__`. Eine Episode oder ein Film, deren Video nicht mehr da ist, wird erneut gesucht. Eine Episode oder ein Film, deren Video noch da ist, was passiert, solange Sonarr noch nicht neu gescannt hat, bleibt unberührt.

## "In Plex scannen" in der Liste der nicht erkannten Dateien wartet auf das Ergebnis {#scan-in-plex-on-the-undetected-list-waits-for-the-result}

Der Button „hold-to-scan“ in der Liste der nicht erkannten Einträge hat die Seite zwei Sekunden nach dem Drücken neu geladen, obwohl der Abgleich mit Plex noch gar nicht begonnen hatte. Bei einer großen Bibliothek dauert dieser Abgleich mehrere Minuten. Deshalb sah die Liste immer unverändert aus, und der Button wirkte, als würde er nichts tun. Der Button zeigt jetzt an, dass der Abgleich läuft, wartet, bis er fertig ist, sagt dir, wie viele Releases abgeglichen wurden, und lädt dann die Seite neu.

## Ein Release, dessen Name mit einem Leerzeichen endet, wird Plex zugeordnet {#a-release-whose-name-ends-in-a-space-is-matched-to-plex}

Ein Release, dessen Dateiname ein Leerzeichen vor der Dateiendung hat, etwa
`... [Hurtom] v2 .mkv`, bekommt ein Verzeichnis, dessen Name auf ein Leerzeichen endet. Plex hat es gefunden, aber zurg konnte es nie zuordnen, deshalb stand es nach jedem Scan weiter auf der undetected-Liste. Jetzt wird es zugeordnet.

## Beim Löschen einer Datei auf der Verwaltungsseite bleibt deine Position erhalten {#deleting-a-file-on-the-manage-page-keeps-your-place}

Wenn du auf der Verwaltungsseite eines Releases eine einzelne Datei löschst, wiederherstellst, umbenennst oder erzwungen anzeigst, sprang die Seite früher wieder ganz nach oben. Beim Aufräumen eines großen Packs musstest du also nach jedem Klick wieder nach unten scrollen. Jetzt kommt die Seite an der Zeile dieser Datei zurück und markiert sie.

## Das Dashboard akzeptiert einen Mount-Pfad, der in Anführungszeichen eingegeben wurde {#the-dashboard-takes-a-mount-path-typed-with-quotes}

Ein Mount-Pfad, der so ins Dashboard eingefügt wurde, wie config.yml ihn schreibt, etwa `"/Users/me/Plex Media Server/ZurgMount"` oder `'Z:\'`, wurde mit "mount path should be absolute" abgelehnt, weil die Anführungszeichen als Teil des Pfads gelesen wurden. Das Dashboard entfernt jetzt ein passendes Paar Anführungszeichen um den Wert und speichert den Pfad innerhalb dieser Anführungszeichen.

## Ein fehlgeschlagener Abruf der Plex-Watchlist nennt den Grund {#a-failed-plex-watchlist-fetch-says-why}

Wenn Plex eine Watchlist-Anfrage ablehnt, enthält das Log jetzt Plex' eigenen Grund, etwa `unexpected status: 401: Invalid token`, statt nur den Statuscode. Wenn du noch `Failed to fetch watchlist: ... unexpected status: 400` siehst, stammt diese Meldung von einem Build, der älter als August ist. Aktualisiere zurg: Aktuelle Builds fragen die Watchlist in Seiten ab, die Plex akzeptiert.

## Ein Release, das für den Speicher von repair zu stark beschädigt ist, schlägt sofort fehl {#a-release-too-damaged-for-repairs-memory-fails-at-once}

Wenn einem Usenet-Release mehr fehlt, als die PAR2-Reparatur auf einmal im Speicher halten kann, sagt zurg das jetzt und hört auf. Sonarr oder Radarr wählen dann ein anderes Release aus. Früher hat es den Grab warten lassen und alle paar Minuten erneut versucht. Dabei wurde jedes Mal das ganze Release neu geprüft, nur um dieselbe Antwort zu bekommen. Schäden, die noch nicht eindeutig als endgültig verloren bestätigt sind, etwa Artikel, die ein Server nicht beantwortet hat, werden weiterhin erneut versucht.

## Setup kommt über eine leere Konfiguration hinweg und sagt, wann die Token-Abfrage verborgen ist {#setup-gets-past-an-empty-config-and-says-when-the-token-prompt-is-hidden}

`zurg setup` und die Installer, die es ausführen, haben nicht weitergemacht, solange eine leere `config.yml` herumlag. Dabei kam eine Fehlermeldung, die einfach leer endete. Eine leere Konfiguration wird jetzt ersetzt. Eine Datei mit Inhalt wird weiterhin nie überschrieben. Die Fehlermeldung sagt jetzt, um welche Datei es geht und wie du neu anfängst. Die Token-Abfrage sagt jetzt, dass das, was du eingibst oder einfügst, verborgen bleibt. Das sah vorher so aus, als würde das Terminal keine Eingaben annehmen. Ein Tippfehler in `config.yml` wird jetzt auch bei `config.yml` gemeldet, nicht mehr bei einer internen „outbound identity config“.

## Ein Backup-News-Server ergänzt jetzt Artikel, die der Hauptserver falsch beantwortet {#a-backup-news-server-now-fills-in-articles-the-main-server-answers-wrongly}

Manche News-Server antworten auf eine Anfrage nach einem Artikel mit einem Stück eines anderen Uploads. zurg hat das falsche Stück zwar erkannt, aber nie den Backup-Server nach dem richtigen gefragt. Dadurch wurde die Lücke als Stille abgespielt oder die Datei ließ sich nicht öffnen, selbst wenn der Backup-Server sie hatte. zurg fragt jetzt den nächsten Server an, so wie SABnzbd es macht.

## Ein RAR-gepacktes Usenet-Release landet ohne Neustart in seinem Verzeichnis {#a-rard-usenet-release-reaches-its-directory-without-a-restart}

Ein Release, das als RAR-Set veröffentlicht wurde, wird zuerst anhand seiner Volume-Namen in Verzeichnisse sortiert, bis sein Archiv geöffnet wurde. Danach erfolgt die Sortierung anhand der Dateien im Archiv. Nachdem das Archiv geöffnet war, wurde nichts mehr neu sortiert. Ein Verzeichnis, das nach einer `.mkv` oder nach Episodennummern sucht, hat ein frisch geholtes RAR-Release deshalb übersehen, bis zurg neu gestartet wurde. Plex und Jellyfin haben es dort nie gesehen. Das Release wird jetzt sofort in die richtigen Verzeichnisse verschoben, sobald sein Archiv zum ersten Mal aufgelistet wird.

## Ein Film, der unter einem zufälligen Namen gepostet wurde, wird nach seinem Release benannt {#a-movie-posted-under-a-random-name-is-named-after-its-release}

Manche Usenet-Posts geben dem Film einen zufälligen Namen, etwa `eq5KVi5Y3iTwFEn1Nub8yPY9yd6oUzTu.mkv`, und wiederholen ihn überall im Post, wo auch der echte Name stehen könnte. zurg hat diesen Namen übernommen, daher hatten Radarr und Sonarr im Dateinamen nichts, woran sie sich orientieren konnten. zurg benennt die Datei jetzt nach dem Release, so wie SABnzbd das macht: nur wenn es klar die eine große Datei des Releases ist, nur bei einer Videodatei und nie bei einer Disc-Struktur oder einem Archiv. Das gilt für Releases, die ab jetzt geholt werden; eine Datei, die schon in der Bibliothek liegt, behält ihren Namen.

## Größenregeln gelten jetzt auch für Dateien innerhalb von Archiven {#size-rules-now-apply-to-files-inside-archives}

Ein Usenet-Film, der als RAR-Set gepostet wurde, wird als die Dateien innerhalb des Archivs angezeigt. Diese Dateien haben die Einstellungen `only_show_the_biggest_file` und `only_show_files_with_size_gte`/`_lte` eines Verzeichnisses umgangen, deshalb blieb alles andere, was der Post enthielt, neben dem Film sichtbar. Viele Posts enthalten ein kleines Bild mit dem Namen des Films, eine Übersicht mit zeitgestempelten Standbildern, und Jellyfin hat dieses als Poster verwendet. Die Größeneinstellungen gelten jetzt für den Inhalt von Archiven genauso wie für alle anderen Dateien.

## Usenet-Releases, deren größte PAR2-Datei über 512 MB liegt, können repariert werden {#usenet-releases-whose-largest-par2-file-is-over-512-mb-can-be-repaired}

Wenn einem Release Teile fehlen, baut zurg sie aus den eigenen PAR2-Dateien des Releases wieder zusammen. Dabei hat zurg jede PAR2-Datei übersprungen, die größer als 512 MB war. Bei einem großen Release enthält genau diese Datei aber den meisten Reparaturdaten, und oft ist sie sogar die einzige, die es gibt. So ein Release ließ sich dadurch nicht reparieren, egal wie wenig davon fehlte. zurg hat es trotzdem immer wieder versucht und dabei jedes Mal alle kleineren PAR2-Dateien heruntergeladen, bevor es aufgab. zurg liest jetzt PAR2-Dateien jeder Größe. Ein Release mit mehr Schäden, als eine Reparatur im Speicher halten kann, wird jetzt abgelehnt, sobald die Schäden gezählt sind, noch bevor eine seiner PAR2-Dateien heruntergeladen wird.

## Sonarr kann seine fehlenden Episoden an zurg übergeben {#sonarr-can-hand-its-missing-episodes-to-zurg}

zurg kann jetzt seine Liste auch von Sonarr beziehen. Füg unter `acquisition.sources` eine `sonarr`-Quelle mit der URL und dem API-Key von Sonarr hinzu. zurg arbeitet dann die Episoden ab, die Sonarr noch fehlen, sowie die Episodendateien, die es ersetzen will. Es sucht bei deinen Indexern und prüft, ob die Newsserver das Release noch haben. Jede Episode landet in ihrem Staffelordner innerhalb von `__magic__`, und zurg bittet Sonarr, die Serie neu zu scannen. Dafür braucht Sonarr keine Indexer und keinen Download-Client.

Eine komplett fehlende Staffel, deren Ausstrahlung abgeschlossen ist, kann als ein einziges Season-Pack kommen. Alles andere kommt Episode für Episode. Jedes Release durchläuft zuerst Sonarrs eigenen Parser. Es muss zur richtigen Serie und zur richtigen Episode passen und ins quality profile der Serie passen. Upgrades ersetzen nur die Episode, die sie verbessern. Fehlt bei einer Staffel noch das Release für eine einzelne Episode, werden die anderen trotzdem abgelegt und Sonarr scannt für sie neu. Daily- und Anime-Serien werden vorerst übersprungen, mit einem Hinweis im Log. Die Sonarr-Seite der Einrichtung wird in `docs/acquisition.md` erklärt.

## Die Beschaffung arbeitet an vielen Titeln gleichzeitig {#acquisition-works-on-many-titles-at-once}

Titel aus einer Watchlist oder einem Anfragedienst wurden früher nacheinander geholt, sodass eine lange Liste genauso lange brauchte wie alle ihre Titel zusammen. zurg arbeitet jetzt an bis zu acht Titeln gleichzeitig, eingestellt über `acquisition.concurrency`. Ein Titel, der spät auf der Liste auftaucht, wartet nicht mehr darauf, dass die davor fertig sind.

Eine neue Veröffentlichung wartet nicht mehr zwei Minuten, bevor zurg sie prüft. zurg prüft jede Sekunde, bis die Veröffentlichung in der Bibliothek erscheint, und zwar bis zu eineinhalb Minuten lang. Wenn die News-Server eine Veröffentlichung nicht mehr haben, geht zurg direkt zum nächsten Kandidaten weiter, statt fünf Minuten später erneut zu versuchen.

Die Prüfung einer Veröffentlichung muss nicht mehr in die Zeit passen, die die Suche übrig gelassen hat. Eine langsame Suche auf einer langen Liste verzögert Titel deshalb nicht mehr um Minuten.

Upgrades zu Titeln, die du schon hast, warten, bis die fehlenden Titel aus derselben Liste fertig sind. So konkurrieren sie nie mit ihnen um Indexer-Anfragen oder News-Verbindungen.

## Ein mit PAR2 repariertes Usenet-Release bleibt während des Lesens repariert {#a-usenet-release-repaired-with-par2-stays-repaired-while-it-is-read}

Wenn bei einem Release einige Artikel vom Newsserver fehlen, baut zurg sie aus den PAR2-Dateien des Releases neu auf und liefert die reparierten Bytes aus. Der Teil von zurg, der Daten schon vor dem Player holt, kannte die neu aufgebauten Teile nicht. Deshalb hat er die fehlenden Artikel erneut bei den Servern angefragt. Die waren dort weiterhin nicht vorhanden, und zurg hat das Release wieder als beschädigt gemeldet, obwohl jedes ausgelieferte Byte korrekt war. Ein während eines Imports repariertes Release konnte dadurch kurz darauf als fehlerhaft gelten, und ein Download-Client hat eine gute Kopie weggeworfen und eine andere geholt. zurg fragt jetzt bei den Servern nichts mehr an, was es bereits neu aufgebaut hat.

## Radarr kann seine gewünschten Filme an zurg übergeben {#radarr-can-hand-its-wanted-movies-to-zurg}

zurg kann jetzt seine Liste aus Radarr holen. Füg eine `radarr`-Quelle unter `acquisition.sources` hinzu, mit der URL und dem API-Key von Radarr. Dann arbeitet zurg die Filme durch, die Radarr fehlen oder die es upgraden will. Es durchsucht deine Indexer, prüft, ob die Usenet-Server das Release noch haben, legt das Video im Ordner des Films innerhalb von `__magic__` ab und bittet Radarr, diesen Film neu zu scannen. Dafür braucht Radarr keine Indexer und keinen Download-Client.

Jedes Release, das zurg übernimmt, hat vorher Radarrs eigenen Parser durchlaufen. Es ist also sicher der richtige Film und passt zum Qualitätsprofil des Films: eine erlaubte Qualität, der minimale Custom-Format-Score, die Größenlimits und Upgrades nur bis zum Cutoff. zurg nimmt das erste erlaubte Release, das am schnellsten zu prüfen ist, und Web-Releases zuerst. Die bevorzugten Qualitäten des Profils überlässt es dem Upgrade, das danach kommt.

zurg fragt Radarr nur dann nach einem Release, wenn es das Release gleich prüfen will, und immer nur eines nach dem anderen. Bei Releases, deren Titel eine Auflösung nennt, für die das Profil keine Qualität hat, fragt es gar nicht erst nach. So beantwortet ein ausgelasteter Radarr für die meisten Filme ein bis drei Fragen, statt eine für jedes Suchergebnis.

Wenn Radarr zurgs Mount unter einem anderen Pfad sieht, setz `library_path` auf den Pfad, unter dem Radarr `__magic__` sieht.

Auf dem Dashboard zeigt die neue Acquisition-Seite alle Titel, an denen zurg gerade arbeitet, was es im Moment tut und wohin jedes Release abgelegt wurde. Die Einrichtung der Radarr-Seite beschreibt `docs/acquisition.md`.

## Die Beschaffung wählt das Usenet-Release, das am schnellsten bestätigt werden kann {#acquisition-picks-the-usenet-release-that-is-quickest-to-confirm}

Wenn zurg einen Film holt, schaut es jetzt zuerst nach den Posts, die nur eine einzelne Videodatei enthalten. Die sind viel öfter noch vollständig auf den Newsservern und lassen sich mit zwei Artikel-Abrufen bestätigen. Bevor etwas gespeichert wird, liest zurg die NZB jedes Kandidaten. Dann speichert es den ersten Post mit einzelner Videodatei, den es findet. Mehrteilige Archivsets nimmt es nur, wenn kein solcher Post angeboten wird. Dabei fängt es mit dem kleinsten Set an und lädt nie mehr als sechs gleichzeitig. Ergebnisse, deren Titel auf einen Teil eines geteilten Posts verweist, werden übersprungen. Im Test mit den IMDb Top 100 hat diese Vorgehensweise die NZBs, die zurg holen musste, von 517 auf 156 gesenkt. Suchen und NZB-Downloads teilen sich jetzt ein Limit für gleichzeitig laufende Anfragen pro Indexer. Meldet ein Indexer, dass er ausgelastet ist, wartet zurg ab. Bei einer Filmanfrage ohne dahinterliegendes quality profile wird trotzdem zuerst die Auflösung berücksichtigt, die angefragt wurde. Die Serienbeschaffung bleibt unverändert.

## Die Beschaffung prüft ein Release, sobald zurg seine Größen kennt {#acquisition-checks-a-release-once-zurg-knows-its-sizes}

zurg hat früher ein neues Release mit den News-Servern geprüft, sobald es in der Bibliothek erschien, während es noch dasselbe Release las, um dessen Dateigrößen zu erfahren. Beide fragten dieselben Artikel über dieselben Verbindungen an, daher wurden lange Listen beide langsam. Bei einer Liste mit 99 Filmen erreichte das letzte Release Radarr erst nach fast neun Minuten. zurg prüft ein Release jetzt, sobald seine Größen bekannt sind, so wie es das bereits bei Sonarr und Radarr über den SABnzbd-Endpunkt tut. Dabei werden nie mehr als sechs Releases gleichzeitig geprüft, und der erste Artikel, den die Größenprüfung schon heruntergeladen hat, wird wiederverwendet, solange er noch vorhanden ist. Eine Reihe gespeicherter Releases führt jetzt zu einer einzigen Aktualisierung der Bibliothek statt einer pro Release.

Die Prüfung eines Releases kommt jetzt vor den Größenprüfungen anderer Releases, allerdings niemals vor der Wiedergabe. Ein Konto mit mehr als zwölf Verbindungen erfährt die Größen nun für bis zu sechzehn Releases gleichzeitig statt für acht.

## Ein heruntergeladenes Usenet-Release mit wenigen fehlenden Teilen wird repariert, bevor es als fehlgeschlagen gilt {#a-grabbed-usenet-release-with-a-few-missing-pieces-is-repaired-before-it-is-failed}

Bevor zurg Radarr oder Sonarr meldet, dass ein Download fertig ist, prüft es, ob die Teile der Veröffentlichung noch auf den News-Servern liegen. Wenn diese Prüfung etwas Fehlendes gefunden hat, hat zurg den Download sofort als fehlgeschlagen gemeldet, auch wenn die eigenen PAR2-Dateien der Veröffentlichung das Fehlende hätten wiederherstellen können. Radarr hat die Veröffentlichung dann verworfen und nach einer anderen gesucht, oft einer schlechteren. zurg baut jetzt zuerst die fehlenden Teile wieder auf und meldet den Download nur dann als fehlgeschlagen, wenn das nicht klappt. Bei den echten Grabs einer Woche hatten die meisten Veröffentlichungen, die so fehlgeschlagen sind, die PAR2-Dateien, die sie hätten retten können.

## Beschädigte Usenet-Releases warten auf ihre Reparatur, statt sofort als fehlgeschlagen zu gelten {#damaged-usenet-releases-wait-their-turn-for-a-repair-instead-of-being-failed}

zurg repariert gleichzeitig höchstens zwei beschädigte Releases, und eine Reparatur kann zwischen ein paar Minuten und über einer Stunde dauern. Ein dritter beschädigter Download hatte nur fünf Minuten Zeit, um anzulaufen, bevor zurg Radarr oder Sonarr mitteilte, dass er fehlgeschlagen ist. Wenn also mehrere gleichzeitig ankamen, wurden alle bis auf zwei weggeworfen, ohne dass jemand versucht hat, sie zu reparieren, und im Log stand nichts davon.
zurg lässt einen Download jetzt so lange warten, bis seine Reparatur an der Reihe ist, und zwar bis zu drei Stunden lang. Im Log steht außerdem, wenn eine Reparatur auf ihren Platz in der Reihe wartet.

## Ein Usenet-Download wartet nicht mehr endlos auf Dateigrößen, die nie ermittelt werden {#a-usenet-download-no-longer-waits-for-ever-on-file-sizes-nothing-is-going-to-learn}

zurg hält einen fertigen Download bei Radarr und Sonarr zurück, bis es die exakte Größe jeder Datei kennt, denn die Clients prüfen die Größe beim Import. Nach bestimmten Neuabrufen konnte zurg aufhören, die Größen zu ermitteln, während es trotzdem noch darauf wartete. Dadurch blieb der Download in der Warteschlange hängen, bis der Client aufgab, oft zwei Stunden später. zurg ermittelt die Größe für ein solches Release jetzt erneut. Wenn keine weitere Größenermittlung mehr möglich ist und alle Teile des Releases auf den News-Servern liegen, meldet zurg dem Client, dass der Download fertig ist.

## Usenet-Releases, bei denen der Poster nur das erste Archivvolume umbenannt hat, lassen sich wieder abspielen {#usenet-releases-whose-poster-renamed-only-the-first-archive-volume-play-again}

Manche Poster benennen die erste Datei eines Archivs nach dem Release-Namen um und lassen den Rest unter den ursprünglichen Namen. So kommt ein Release mit `Show.S02E03.part03.rar` und `show.203.r00` bis `show.203.r19` an. zurg hat die Teile nach ihrem Namen gruppiert, zwei unvollständige Archive gesehen und keins davon öffnen können. Jetzt liest zurg den Header der ersten Datei, erkennt, zu welchen Teilen sie gehört, und benennt sie passend um. So lässt sich die Episode abspielen und importieren. Wenn einem Ordner wirklich ein Teil des Archivs fehlt, zeigt zurg jetzt eine klare Meldung dazu an, statt eines allgemeinen Serverfehlers.

## Verschleierte Usenet-Releases, deren Volumes nur nummeriert sind, lassen sich jetzt abspielen {#obfuscated-usenet-releases-whose-volumes-are-just-numbered-now-play}

Manche Releases verstecken jeden Dateinamen hinter einer zufälligen Zeichenfolge und einer Nummer. Ein Film kommt dann als `f342c135….01`, `….02` und so weiter an, mit den Textdateien und Covern dazwischen nummeriert. zurg hat diese nicht als Teile eines Archivs erkannt, sie als lose Dateien aufgelistet, und Radarr und Sonarr haben nichts zum Importieren gefunden. zurg liest jetzt den Anfang jeder nummerierten Datei, fügt die Teile des Archivs in der richtigen Reihenfolge zusammen (auch dann, wenn der erste Teil zuletzt gepostet wurde) und lässt die Textdateien und Bilder dabei außen vor.

## Season-Pack-NZBs über 32 MB werden akzeptiert {#season-pack-nzbs-over-32-mb-are-accepted}

zurg hat jede NZB über 32 MB abgelehnt, die über seinen SABnzbd-Endpunkt geschickt wurde, mit der Antwort "request body too large". Die NZBs für große Staffel-Packs sind oft größer als das: Eine 526 GB große Staffel kam als 49 MB große NZB. zurg akzeptiert jetzt NZBs bis 256 MB. Eine 49 MB große mit fast einer halben Million Teilen lädt in unter einer halben Minute.

## Dateien aus verpackten Usenet-Posts behalten ihre echten Namen {#files-from-wrapped-usenet-posts-keep-their-real-names}

Manche Posting-Tools packen jeden Dateinamen in den Betreff, wie hier `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv]-[3/4]`, und lassen den sonst üblichen Dateinamen in Anführungszeichen leer. zurg hat die Hülle als Teil des Namens behalten, sodass Episoden als `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv` aufgelistet wurden, was Sonarr und Medienserver nicht zuordnen können. zurg nimmt den Namen jetzt aus der Hülle heraus. Releases, die schon in der Bibliothek sind, werden einmal neu eingelesen, damit die korrigierten Namen übernommen werden.

## Downloads, die schon als fehlgeschlagen gemeldet sind, nehmen neuen Downloads keine Reparatur-Slots mehr weg {#downloads-already-reported-failed-no-longer-take-repair-slots-from-new-ones}

Sobald zurg Radarr oder Sonarr meldet, dass ein Download fehlgeschlagen ist, wirft der Client ihn weg und sucht nach einer anderen Quelle. zurg hat solche Downloads trotzdem bei jedem Neustart weiter zu reparieren versucht. Diese sinnlosen Reparaturen konnten beide Reparatur-Slots blockieren, während ein neuer Download, der sich noch retten ließe, warten musste. zurg repariert einen Download jetzt nicht mehr, sobald er als fehlgeschlagen gemeldet wurde.

## Schadensberichte nennen jede Datei {#damage-reports-name-every-file}

Wenn bei einem Usenet-Release Teile fehlten, hat die Fehlermeldung von zurg die beschädigten
Dateien namentlich aufgelistet, und eine Datei, die im Post selbst nie genannt war, tauchte
als leerer Eintrag auf: "across 4 file(s): , , , ". Solche Dateien werden jetzt über ihre
Position im Release aufgelistet, zum Beispiel als "file 12 of 73". So zeigt die Meldung
an, welche Dateien betroffen sind.

## Stremio überspringt ein Release, dessen Video mit nichts beginnt {#stremio-skips-a-release-whose-video-starts-with-nothing}

Wenn der Anfang des Videos eines Usenet-Releases auf den News-Servern fehlt, hat zurg ihn mit Stille aufgefüllt und an Stremio weitergegeben, als wäre alles in Ordnung. Der Player zeigte dann nichts an, und der Film wirkte kaputt. zurg schaut sich jetzt die ersten Bytes an, bevor die Wiedergabe startet. Ist dort nichts Echtes drin, geht es zum nächsten Release in der Liste weiter, genau wie es das schon heute bei einem Release ohne abspielbaren Inhalt macht. Ein Film mit einer Lücke irgendwo weiter hinten wird weiterhin abgespielt.

## Defekte Dateien bleiben in der Bibliothek, während zurg sie trotzdem weiter erneut versucht {#broken-files-stay-in-the-library-while-zurg-will-still-retry-them}

Wenn zurg eine kaputte Datei beim ersten Versuch nicht reparieren konnte, hat es die Datei aus dem Mount entfernt, selbst dann, wenn ein Versuch einen Tag später geplant war. Plex liest eine verschwundene Datei als gelöschte Datei, daher konnte ein einziger Bibliotheksscan Episoden, Staffeln und ganze Serien in den Papierkorb verschieben. Jetzt bleibt eine kaputte Datei so lange im Mount, wie zurg einen weiteren Reparaturversuch plant. Sie verschwindet erst, wenn zurg sicher ist, dass der Inhalt weg ist, zum Beispiel wenn der Dienst die Veröffentlichung komplett ablehnt oder darin nichts Abspielbares mehr übrig ist.

## Radarr und Sonarr suchen erneut, wenn ein doppelt geholtes Release tot ist {#radarr-and-sonarr-search-again-when-a-release-they-grab-twice-is-dead}

Als das erste Release, das Radarr geholt hat, sich als tot herausstellte, fand die nächste Suche oft dasselbe Release bei einem anderen Indexer, unter demselben Namen. zurg hat diesen zweiten Download unter der Job-ID des ersten abgelegt. Radarr und Sonarr merken sich jeden Download, der unter dieser ID schon einmal fehlgeschlagen ist. Deshalb haben sie den neuen Download als den alten Fehler behandelt und nie mehr angeschaut: kein Fehler, keine Blockliste, keine neue Suche. Der Film ist einfach stehen geblieben. Bei einem Durchlauf der IMDb Top 100 über Radarr sind 25 Filme so hängen geblieben.

Eine Abholung eines Releases, das zurg schon beantwortet hat, bekommt jetzt eine eigene Job-ID, so wie SABnzbd selbst jeden Download benennt. Wenn auch dieser Download tot ist, hört Radarr den zweiten Fehler, setzt das Release auf die Blockliste und sucht erneut.

## Tote Usenet-Releases werden in Minuten statt bis zu einer halben Stunde als fehlgeschlagen gemeldet {#dead-usenet-releases-are-reported-failed-in-minutes-instead-of-up-to-half-an-hour}

zurg prüft die Artikel eines geholten Releases, bevor es Radarr oder Sonarr meldet, dass es fertig ist. Vorher wartet es, bis sich die Dateigrößen des Releases stabilisiert haben. Ein toter Post ist genau das Release, bei dem die Größen nie ankommen. Die Prüfung hing deshalb eine halbe Stunde lang hinter dieser Wartezeit, während der Client auf Nachricht wartete. Wenn zurg versucht hat, die Größen eines Releases zu ermitteln, und das fehlgeschlagen ist, prüft es jetzt sofort die Artikel. Ein Release, dessen Artikel weg sind, wird als fehlgeschlagen gemeldet, damit der Client zu einem anderen übergeht.

Ein Release, das beim Lesen als beschädigt erkannt wurde, wartete außerdem fünf Minuten auf eine PAR2-Reparatur, selbst mit `enable_repair: false`, wo nie eine Reparatur startet. Diese Wartezeit wird jetzt übersprungen, wann immer keine Reparatur laufen kann.

Bei einem Durchlauf der IMDb Top 100 über Radarr, bei dem mehr als die Hälfte der geholten Releases tot war, machten diese beiden Wartezeiten den größten Teil der Zeit aus, die ein Film in zurg verbracht hat.

## Ein Release, das beim Import beschädigt ist, wird als fehlgeschlagen markiert, damit Radarr ein anderes holt {#a-release-that-turns-out-damaged-during-import-is-failed-so-radarr-grabs-another}

zurg prüft vor der Meldung an Radarr, dass ein Release bereit ist, nur einen Artikel pro Datei. Deshalb kann ein Release mit einer Lücke mitten in einer Datei durchrutschen. Als Radarr den Import dann bis zu dieser Lücke brachte, weigerte sich zurg, die Datei zu verschieben. Das war richtig, aber der Download sah danach unfertig statt fehlgeschlagen aus. Radarr hat den Film als "import blocked" geparkt und nie nach einer anderen Kopie gesucht. Bei einem Durchlauf der IMDb Top 100 über Radarr blieben so fünf Filme hängen.

Der abgelehnte Import markiert den Download jetzt als fehlgeschlagen. Radarr setzt dieses Release auf die Blockliste und sucht nach einem anderen.

## Ein vollständig verschleiertes Release liefert keine namenlose Videodatei mehr {#a-fully-obfuscated-release-no-longer-comes-out-with-a-nameless-video-file}

Wenn ein Usenet-Post alle Dateinamen verbirgt, findet zurg die Hauptdatei anhand ihrer ersten Bytes heraus und benennt sie nach dem Release, so wie SABnzbd es macht. Diese Prüfung kam bisher als Letztes in einem Durchlauf mit einem Limit von neunzig Sekunden. Wenn Anfragen in einem Schwung eintrafen, konnte das Limit vorher ablaufen. Die Videodatei wurde dann unter dem Release-Namen ohne jede Dateiendung veröffentlicht, und das überspringen Radarr und Sonarr. Der Download blieb in deren Warteschlange hängen und wartete auf eine Datei, die sie importieren können.

Ein Release wird jetzt bis zu dreimal neu benannt, bis zurg die Datei prüfen konnte. Erst danach wird es deiner Bibliothek und deinen *arr-Apps gezeigt. Bei einem Durchlauf der IMDb Top 100 über Radarr war das Seven Samurai, eine 42 GB große .mkv.

## Releases mit Akzenten oder CJK-Zeichen in ihren Dateinamen behalten ihre vollständigen Namen {#releases-with-accents-or-cjk-in-their-filenames-keep-their-whole-names}

A release whose files are named with anything outside plain English letters came
out of zurg with the front of every name missing. `Détective Conan S11E01 - 286
[MULTI] [AVC].mkv` was served as `tective Conan S11E01 - 286 [MULTI] [AVC].mkv`,
and a Chinesisch oder Japanisch Titel verlor noch mehr, denn alles bis zum letzten
solchen Zeichen wurde abgeschnitten.

Sonarr und Radarr konnten mit dem Rest nichts anfangen. Ein Name wie `tective
Conan S11E01` passt zu keiner Serie. Deshalb griffen sie auf den Grab-Verlauf des
Downloads zurück, verweigerten allein deswegen den Import und setzten das Element
mit "release was matched to series by ID. Automatic import is not possible." auf
Eis. Der Release steckte in der Warteschlange fest, und nichts hat ihn
weiterbewegt.

Es konnte dich auch Dateien kosten. Wenn das Einzige, was zwei Dateien
unterscheidet, nach dem letzten akzentuierten Zeichen steht, bekommen beide den
gleichen Namen, und ein Name ist ein Pfad. Ein französischer Release mit zehn
Reparatur-Volumes hatte alle zehn auf denselben Namen reduziert und vier Dateien
veröffentlicht, obwohl der Post dreizehn enthält. Die Reparaturdaten hatten
dadurch keinen Weg mehr zu den Dateien.

zurg liest jetzt jedes Zeichen über reinem ASCII als Teil des Dateinamens, denn
genau das ist es: Die Teilzähler, der `yEnc`-Marker, die Klammern und die
Dateiendungen, die Poster verwenden, sind alle reines ASCII. Alles andere gehört
also zum Titel. Releases mit reinen ASCII-Namen sind davon nicht betroffen und
kommen genau wie vorher heraus.

Releases, die schon in deiner Bibliothek liegen, behalten die Namen, unter denen
sie abgelegt wurden, denn zurg sieht eine bereits erfasste Dateiliste nicht noch
einmal an. Wenn du einen betroffenen Release erneut hinzufügst, werden die
korrigierten Namen übernommen.

## Ein Name in Japanisch, Koreanisch, Chinesisch, Thailändisch oder Arabisch bleibt unverändert {#a-name-written-in-japanese-korean-chinese-thai-or-arabic-is-left-alone}

zurg benennt eine Datei in einem Archiv um, wenn ihr Name nichts darüber aussagt, was sie enthält. So kommt ein Release, das als Hash gepostet wurde, unter dem eigenen Namen des Releases an. Um das zu entscheiden, musste zurg Groß- gegen Kleinbuchstaben abwägen, und viele Schriften kennen beides gar nicht. Eine Datei namens `오징어 게임 S01E01` hatte von beidem null, fiel beim Test für einen normalen Namen durch und wurde wie ein Hash umbenannt, inklusive S01E01. Han, Kana, Hangul, Thai, Hebräisch und Arabisch waren alle betroffen.

Ein Buchstabe ohne Groß- oder Kleinschreibung beendet die Prüfung jetzt, statt sie scheitern zu lassen. Namen in diesen Schriften bleiben so, wie sie gepostet wurden. Hashes werden weiterhin genauso umbenannt wie bisher.

zurg meldet jetzt auch im Log, wenn zwei Dateien in einem Release denselben Namen bekommen. Ein Name ist ein Pfad. Wenn das passiert, zeigt das Release stillschweigend weniger Dateien an, als es enthält, und die übrigen lassen sich gar nicht öffnen. Bisher wurde das nirgends gemeldet. Deshalb ist der Fehler mit den Akzent-Dateinamen aus dem letzten Eintrag unbemerkt geblieben. Der einzige Hinweis war eine Ordnerliste mit weniger Zeilen als erwartet.

## Die Dateinamen-Korrekturen wirken jetzt auch auf Releases, die du schon hast {#the-filename-fixes-now-reach-releases-you-already-have}

Die beiden Einträge oben haben geändert, wie zurg einen Dateinamen aus einem Usenet-Post liest. zurg speichert aber das Ergebnis für jede NZB und verwendet es bei jedem Start wieder, anstatt dein ganzes Watch-Verzeichnis erneut durchzugehen. Diese gespeicherten Ergebnisse waren noch die alten. Deshalb zeigte ein Release, das du schon hattest, nach dem Update weiter den gleichen falschen Namen wie vorher. Nur eine neu hinzugefügte NZB bekam den korrigierten Namen.

zurg merkt jetzt, dass es Posts anders liest, als die gespeicherten Ergebnisse geschrieben wurden, und liest sie noch einmal ein. Der erste Start nach dem Update liest einmal jede NZB in deinem Watch-Verzeichnis neu ein. Das dauert etwas länger als sonst, danach läuft alles wieder normal. Es wird nichts neu heruntergeladen und keine Artikel werden abgerufen. Es werden nur Dateien gelesen, die schon auf deiner Festplatte liegen.

Wenn ein Release betroffen war, kommen seine Dateien wieder unter den Namen, die der Post ihnen gegeben hat. Dein Download-Client hält unter Umständen noch den fehlgeschlagenen Import von früher fest. Ein Release, das in Sonarr oder Radarr hängt und nicht importiert werden kann, muss daher erst aus der Warteschlange entfernt werden, bevor es erneut versucht wird.

## Titel mit Satzzeichen behalten ebenfalls ihre vollständigen Namen {#titles-with-punctuation-in-them-keep-their-whole-names-too}

Der Dateinamen-Fix weiter oben in dieser Liste hat zwar verhindert, dass zurg Namen bei akzentuierten und chinesischen Zeichen abschneidet, er ging aber nicht weit genug. zurg hat anhand einer Liste der Zeichen entschieden, was ein Dateiname sein darf, und dieser Liste fehlten zwanzig ganz gewöhnliche Zeichen. Ein Titel mit einem davon wurde deshalb genauso abgeschnitten, nämlich auf genau dieselbe Weise:

    Tom & Jerry - The Movie.1992.1080p.mkv   ->   Jerry - The Movie.1992.1080p.mkv
    Mairimashita! Iruma-kun (2026) [22].mp4  ->   Iruma-kun (2026) [22].mp4

`!`, `&`, `#`, `$`, `%`, `@`, `~`, `;`, `=` und `^` haben alle dasselbe bewirkt.

Eine Liste der erlaubten Zeichen für Titel zu pflegen ist ein aussichtsloses Unterfangen, deshalb versucht zurg das nicht mehr. Ein Name ist ein Dateiname, und die einzigen Zeichen, die darin garantiert nicht vorkommen dürfen, sind die, die kein Dateisystem akzeptiert: `/ \ : * ? " < > |`. Alles andere gehört jetzt zum Titel.

Geprüft gegen jede NZB in einem großen Watch-Verzeichnis: Von den Betreffszeilen, die einfache Dateinamen sind, behält fast jede, die vorher zu kurz geriet, jetzt ihren vollständigen Namen. Gekürzt werden nur noch die Betreffszeilen, bei denen der Stempel eines Indexers für jeden Download entfernt wird, und das ist auch richtig so.

## Ein Release, dessen Dateien umbenannt wurden, übernimmt die neuen Namen automatisch {#a-release-whose-files-were-renamed-picks-the-new-names-up-on-its-own}

Die Dateinamen-Korrekturen von oben haben geändert, wie zurg die Dateien innerhalb eines Usenet-Releases benennt, und ein Release, das schon in deiner Bibliothek war, hat das nicht immer bemerkt. zurg gleicht ein Release, das es schon kennt, mit einer neuen Auflistung über den Link ab, den es für jede Datei gespeichert hat, und ein Usenet-Link enthält die Position der Datei im Release. Wenn ein korrigierter Name anders sortiert als der alte, verschiebt sich diese Position, der gespeicherte Link zeigt nicht mehr auf dieselbe Datei, und es gibt nichts mehr, woran abgeglichen werden könnte. Deshalb blieb der alte Name bestehen.

Jetzt greift es stattdessen auf die Dateigröße zurück, die sich nicht ändert. Wenn genau eine Datei im Release diese Größe hat, ist sie es, und der Name wird übernommen. Wenn zwei Dateien dieselbe Größe haben, wird nichts umbenannt, statt zu raten und eine Episode unter dem Namen einer anderen abzulegen.

Releases, bei denen sich die Position nicht verschoben hat, haben die neuen Namen schon vorher übernommen und sind nicht betroffen, genauso wenig wie jedes Nicht-Usenet-Backend, dessen Links sich beim Umbenennen einer Datei nicht ändern.

## Eine Datei, die das Mount nicht lesen kann, hält nicht mehr alles andere auf {#a-file-the-mount-cannot-read-stops-holding-everything-else-up}

Wenn ein Lesevorgang fehlschlug, aus einem Grund, den zurg nicht benennen konnte, sagte zurg dem Client, er solle es erneut versuchen, und tat das weiter, solange die Datei fehlschlug. rclone nimmt das ernst: Ein einziges Lesen einer solchen Datei brauchte 55 Sekunden und drei Dutzend Anfragen, bevor es aufgab. Und weil rclone die ganze Verbindung zu einem Server ausbremst, der ständig Fehler liefert, dauerte das Öffnen der nächsten gesunden Datei 3.66 Sekunden statt 0.04.

Jetzt hört das Wiederholen nach einer Minute mit demselben Fehler auf. Das Lesen wird so beantwortet, wie ein Lesen einer kaputten Datei schon immer beantwortet wurde. Die Datei bleibt in deiner Bibliotheksansicht stehen, und dasselbe Lesen dauert eine halbe Sekunde.

zurg versucht den Download trotzdem jedes Mal. Kommt eine Datei wieder zurück, wird sie beim nächsten Lesen aufgenommen.

## Der Mount hört mit dem Download auf, sobald du nicht mehr liest {#the-mount-stops-downloading-once-you-stop-reading}

Eine Bibliotheks-Prüfung, eine Untertitel-Kontrolle oder irgendetwas anderes, das kurz eine Menge Dateien anfasst, hat aus deinem Debrid-Konto weit mehr gezogen, als sie gelesen hat.

rclone 1.74 hat angefangen, eine Datei noch fünf Sekunden lang weiterzuladen, nachdem das letzte Programm sie geschlossen hatte. Auf diese Bytes wartete aber nichts, und bei einem schnellen Konto sind fünf Sekunden pro Datei ein paar hundert Megabyte. Wurde von zwanzig Dateien je 1 MiB gelesen, sind so 4,2 GiB geladen worden, wo früher 80 MiB reichten.

zurg schaltet das jetzt ab. Mounts mit rclone 1.73 oder älter sind davon nicht betroffen und bleiben unverändert, weil die Option dort nicht existiert.

Wenn du deinen eigenen rclone statt des zurg-Mounts nutzt, füge deinem Mount-Befehl bei rclone 1.74 oder neuer `--vfs-handle-caching 0` hinzu. Die README erklärt das.

## Ein Release, das einen Archiv-Teil verliert, verliert nicht mehr den Rest {#a-release-that-loses-one-archive-volume-no-longer-loses-the-rest}

Usenet-Releases, die als mehrteiliges rar- oder 7z-Set gepostet werden, konnten komplett aufhören zu importieren. Sonarr und Radarr hingen bei "Waiting for import" fest und kamen nie davon weg. Der Ordner des Releases enthielt dann nur noch die rar-Teile oder existierte gar nicht mehr.

Wenn zurg ein Volume eines Sets nicht lesen konnte, legte es dieses Volume beiseite und ließ den nächsten Abruf ohne es weiterlaufen. Dieser Abruf fand das Set dann ein Volume zu kurz, hielt beim Volume dahinter an und legte auch dieses beiseite. Ein Release verlor so seine Volumes nach und nach, etwa eins alle zehn Minuten. Sobald keins mehr übrig war, verschwand es aus der Bibliothek und aus dem Ordner, aus dem der Download-Client importiert. Für Sonarr ist ein Pfad, der nicht existiert, kein leerer Ordner, sondern ein Import, der für immer fehlschlägt.

Ein Volume, von dem bekannt ist, dass es nicht lesbar ist, bleibt jetzt in seinem Set. Jeder Abruf hält am selben Volume an und meldet dasselbe dazu. So wird ein Release, dem ein Teil seines Posts fehlt, einmal als solcher gemeldet. Dein Client kann es dann in die blocklist aufnehmen und nach einer anderen Kopie suchen. Releases, deren Volumes alle lesbar sind, sind davon nicht betroffen.

## Scans folgen der Bibliothek an ihren neuen Ort unter `__magic__` {#scans-follow-the-library-into-its-new-home-under-__magic__}

Der Spiegel deiner Bibliothek ist von `__magic__` nach `__magic__/__all__` umgezogen, und zwar in
2026.09.17.2240-nightly. Ein Teil von zurg benannte weiterhin den alten Ort.

Wenn eine neue Version ankam, zeigte der Scan, den zurg bei Plex oder Jellyfin anstieß, auf einen Ordner, der seit dieser Version nicht mehr existierte. Deshalb wurde nie etwas eingereiht, und neue Inhalte warteten auf den geplanten Scan des Medienservers. Wer ein `on_library_update`-Skript betreibt, bekam denselben Pfad übergeben.

Beide nennen jetzt den Ordner, aus dem dein Download-Client importieren soll, und so auch die Auflistung, die zurg aus dem Cache des Mounts entfernt, wenn eine Version hinzukommt oder verschwindet.

## Die Watchlist kann jetzt Torrents aus Torznab-Indexern übernehmen {#the-watchlist-can-take-torrents-now-from-torznab-indexers}

Bis jetzt konnte eine Watchlist- oder Seerr-Anfrage nur über Usenet erfüllt werden. Füge `type: torznab` zu einem Indexer hinzu, dann durchsucht zurg ihn auch, und ein Torrent-Ergebnis wird an ein Debrid-Konto übergeben, statt in `nzbs/` geschrieben zu werden.

**Es wird nur an ein Konto übergeben, das es bereits gecacht hat.** Jedes Konto, das Hinzufügungen annimmt, bekommt den Hash angeboten, weil die Caches unabhängig voneinander sind, und das erste Konto, das die Veröffentlichung schon hat, nimmt sie. Ein Fehlschlag überall ist nur ein Kandidat, der nicht geklappt hat. zurg geht dann zur nächsten Veröffentlichung weiter, die ein anderer Torrent oder eine NZB sein kann. Nichts wird auf dein Konto heruntergeladen, es wird kein Kontingent für nicht gecachte Hinzufügungen verbraucht, und es läuft nichts weiter für etwas, auf das niemand wartet.

Wenn beide Arten von Indexern antworten könnten, entscheidet `prefer`, welcher zuerst angefragt wird. Standardmäßig ist es `usenet`, sodass eine Installation mit nur Newznab-Indexern genauso funktioniert wie vorher. `torrents` kehrt die Reihenfolge um, und `best` nimmt, was das Ranking an die erste Stelle setzt, egal ob Torrent oder nicht.

Ein Torrent-Download wird wie jeder andere geprüft, bekommt aber eine andere Frage gestellt. Das Konto hat bereits bestätigt, dass es den Inhalt hat, also wird geprüft, ob die Veröffentlichung mit Dateien in deiner Bibliothek angekommen ist. Eine, die als leer gemeldet wird, wird beiseitegelegt, damit die nächste Veröffentlichung drankommt.

Du kannst die Beschaffung auch nur mit Torznab-Indexern betreiben, ohne einen `nzb`-Provider.

## Ein Agent, der die Bibliothek liest, hält nicht mehr jedes Release für leer {#an-agent-reading-the-library-no-longer-calls-every-release-empty}

Die MCP-Listen von zurg messen die Größe eines Releases nur dann, wenn du sie ausdrücklich darum bittest, denn das Durchgehen der Dateitabelle einer ganzen Bibliothek kostet echte Zeit. Bei Releases, die nicht gemessen wurden, meldeten sie Größe und Dateianzahl als null, und nichts in der Antwort verriet einem Leser, dass null "nicht gemessen" bedeutete und nicht "hier ist nichts". Ein Agent, der ein Verzeichnis auflisten sollte, hätte dann behauptet, ein 6,6 GB großer Film enthalte keine Dateien, obwohl das Tool für einen einzelnen Release die ganze Zeit die richtige Antwort hatte.

Eine Liste, bei der nicht gemessen wurde, lässt jetzt beide Werte weg, statt null anzugeben. Fordere sie mit `with_size` an, sortiere nach Größe oder nutze einen Größenfilter. `zurg_library_search` akzeptiert jetzt ebenfalls `with_size`, was vorher nicht ging. So kannst du Größen abrufen, ohne ein eingeschränktes oder anders sortiertes Ergebnis in Kauf nehmen zu müssen.

## zurg doctor zeigt an, ob der MCP-Endpunkt antwortet {#zurg-doctor-says-whether-the-mcp-endpoint-is-answering}

`zurg doctor` prüfte nur, ob der Port des Dashboards antwortet, und hörte dann auf,
was nichts über `/mcp` aussagt. Ein Endpunkt, den die Config einschaltet, der Server
aber dann nicht ausliefert (das passiert, wenn `username` leer ist), sah von außen
gesund aus und erklärte sich nur in einer Zeile im Start-Log und sonst nirgends.

Wenn `mcp.enabled` gesetzt ist, spricht `doctor` jetzt das Protokoll mit `/mcp` und meldet, was zurückkommt: dass der Endpunkt antwortet, dass er die konfigurierten Zugangsdaten ablehnt oder dass er aktiviert, aber nicht ausgeliefert ist. Eine Instanz mit ausgeschaltetem Endpunkt wird dazu nicht befragt und bekommt keine Zeile.

## Wenn du den MCP-Endpunkt im Browser öffnest, sagt er dir jetzt, was er ist {#opening-the-mcp-endpoint-in-a-browser-now-tells-you-what-it-is}

Wenn man `/mcp` im Browser lädt, kam die Antwort "Bad Request: GET requires an Mcp-Session-Id header". Das ist zwar korrekt, beantwortet aber eine Frage, die niemand gestellt hat.

Der Endpunkt beschreibt sich jetzt selbst, wenn ihn ein Browser öffnet: welches Protokoll er spricht, die Adresse, mit der du einen Client verbindest, das Snippet für die stdio-Bridge, welcher Build das ist, und jedes Tool, das er gerade anbietet. Die Tools sind nach Toolset gruppiert. Wo ein Tool nur beschreibt, was es tun würde, und auf eine Bestätigung wartet, ist das extra markiert.

Diese Liste ist das, was die Registrierung tatsächlich erzeugt hat, und keine zweite Kopie, die von Hand gepflegt wird. Ein Tool, das durch `read_only`, durch deine Toolsets oder durch den Lifecycle-Schalter zurückgehalten wird, wird deshalb nicht als aufrufbar angezeigt. Wird der Endpunkt ohne Authentifizierung ausgeliefert, sagt die Seite das ebenfalls.

Kein Client ist betroffen. Die Seite wird nur an ein GET ausgeliefert, das HTML anfordert und keine Session mitschickt. Das ist ein Browser und nie ein MCP-Client. Ein GET vom Client selbst öffnet den Event-Stream wie bisher.

## Usenet-Wiedergabe füllt das Verbindungskontingent schneller auf {#usenet-playback-fills-the-connection-allowance-sooner}

Usenet-Lesezugriffe setzen den Artikel an der Abspielposition jetzt zuerst in den Account-Scheduler, bevor der Rest des angeforderten Bereichs angeboten wird. Wenn ein großer Bereich auf mehrere gepipelinete Verbindungen verteilt wird, werden aufeinanderfolgende Artikel abwechselnd auf diese Verbindungen verteilt. Bisher bekam die erste Verbindung die ersten vier, die zweite die nächsten vier und so weiter. Die ersten nutzbaren Artikel kommen dadurch schon in der ersten Verbindungsrunde zurück und müssen nicht hinter späteren Bytes warten.

Read-ahead-Fenster für Archiv-Posts mit kleinen Artikeln umfassen jetzt mindestens 64 MiB. Moderne Posts mit mehrere Megabyte großen Artikeln behalten ihr bisheriges Fenster. Die höhere Artikelanzahl erhöht den Speicherverbrauch nicht: Spekulative Artikelinhalte sind auf zwei Leser und die Hälfte von `cache_size_mb` begrenzt (bei der Standardeinstellung 256 MiB). Der harte Limit des Artikel-Caches bleibt unverändert. Anfragen in Abspielgröße beginnen jetzt bei 64 MiB statt bei 128 MiB. Dadurch landet ein Player-Buffer von 90 MiB nicht mehr im Seek/Probe-Pfad. Kleine Seeks tun das aber weiterhin.

Ein hängender gepipelineter Batch darf jetzt bis zu fünf verschiedene Artikel gleichzeitig parallel nachfordern. Das Account-Limit von zwanzig Segment-Anfragen pro Minute bleibt unverändert. Read-ahead, Reparaturen und andere Arbeiten, auf die kein Client wartet, werden weiterhin nie parallel nachgefordert.

Das Öffnen von Multi-Volume-Archiven ist außerdem günstiger geworden. Wenn PAR2 bereits die genaue Länge jedes Volumes geliefert hat, kann der verifizierte yEnc-Header eines Volumes den gemeinsamen Artikelabstand für eine große Gruppe von Geschwister-Volumes liefern. Jedes Geschwister-Volume prüft diese Ableitung anhand seines eigenen Headers, bevor es sein erstes Byte ausliefert. So kostet die Auflösung nicht mehr einen seriellen Artikel pro Volume, ohne dass man den abgeleiteten Geometriedaten für die Daten blind vertraut. Die Dateinamen-Wiederherstellung antwortet ebenfalls direkt aus dem yEnc-Header, statt darauf zu warten, dass der restliche Artikel heruntergeladen ist.

## Gespeicherte .strm-Dateien folgen einer Änderung der Base URL {#saved-strm-files-follow-a-base-url-change}

Base URL zu ändern hat dazu geführt, dass alle `.strm`-Dateien, die schon in `strm/` lagen, weiter auf die alte Adresse zeigten.
Neustarten half nicht, weil zurg nur fehlende Dateien geschrieben hat. Jetzt wird eine
`.strm`, deren URL von der abweicht, die zurg schreiben würde, direkt an Ort und Stelle neu geschrieben. Das passiert bei jedem Start und sofort, wenn Base URL im Dashboard geändert oder `save_strm_files` dort eingeschaltet wird. Dateien, die schon stimmen, bleiben unverändert, damit ein Medienserver bei jedem Scan nicht den ganzen Ordner neu einliest.

Jellyfin merkt sich die URL aus einer `.strm` und übernimmt die neue erst beim nächsten Bibliotheks-Scan. Eine `.strm`, die noch einen Konto-Link aus einem älteren Build enthält, wird ebenfalls neu geschrieben, und zwar in die Form, die zwischen Konten umschaltet und Reparaturen übersteht. Eine `.strm`, die du von Hand in `strm/` bearbeitet hast, wird überschrieben. Setz Base URL deshalb auf die Adresse, die du haben willst.

## Das Einschalten der Plex-Watchlist leert sie nicht mehr {#turning-the-plex-watchlist-on-no-longer-empties-it}

Die Watchlist-Funktion hat früher deine gesamte Liste als Warteschlange behandelt und sie Titel für Titel abgearbeitet, wobei jeder Titel aus der Watchlist gelöscht wurde. Ein erster Lauf hat so in etwa vier Minuten 121 Titel von einer Liste mit 163 Einträgen entfernt. Plex führt keinen Verlauf über entfernte Watchlist-Einträge, also gab es nur einen Weg zurück: einen Snapshot, den du vorher gemacht hast. Weder in der Konfiguration noch in den Logs stand ein Hinweis, dass das passieren würde.

Zwei Einstellungen bestimmen jetzt, was das Beschaffen mit der Liste macht. Die Liste gehört dir, nicht zurg.

**`watchlist.only_new_items`** ist standardmäßig aktiv. Wenn du die Watchlist einschaltest, beginnt zurg, sie zu überwachen. Was schon auf der Liste steht, gilt als erledigt, und was du danach hinzufügst, wird beschafft. Das gilt nur einmal, beim ersten Lauf, und überschreibt nie eine bereits vorhandene Warteschlange. Eine Installation, die gerade eine Watchlist abarbeitet, läuft deshalb genauso weiter wie bisher.

**`watchlist.remove_after_grab`** ist standardmäßig aktiv, weil die Funktion das schon immer so gemacht hat. Für dich ändert sich also nichts, solange du es nicht selbst anpasst. Schalte es aus, wenn deine Watchlist eine Watchlist bleiben soll. Sie dient dann weiterhin dazu, durchzustöbern und zu entscheiden, was du ansehen willst, und zurg erfüllt sie im Hintergrund, ohne sie je zu verändern. Ein Titel, der auf der Liste bleibt, kostet nichts bei einer erneuten Prüfung, weil der Eintrag im Beleg schon alles abdeckt und kein Indexer erneut danach gefragt wird.

Beide Einstellungen findest du auf der Konfigurationsseite, und beide werden beim nächsten Neustart wirksam. Eine Beschaffungsquelle, die du unter `acquisition.sources` explizit angibst, kann beide pro Quelle festlegen. Für eine Seerr-Quelle haben sie keine Bedeutung, weil diese keine Liste besitzt, in die zurg schreibt.

## Watchlist- und Seerr-Anfragen warten auf die News-Server, bevor sie geleert werden {#watchlist-and-seerr-requests-wait-for-the-news-servers-before-they-are-cleared}

Früher war ein Grab fertig, sobald seine NZB im Watch-Verzeichnis gelandet war. Der Indexer hat geantwortet, die Antwort wurde als NZB erkannt und die Datei wurde geschrieben. Das sind drei Fakten über den Indexer und keiner über den Post. Die Anfrage wurde dann auf dieser Grundlage abgehakt. Bei einer Plex-Watchlist heißt das, der Eintrag wird gelöscht, und Plex führt keinen Verlauf über entfernte Einträge. Ein toter Post hat also den einzigen Hinweis gelöscht, dass du den Titel wolltest, noch bevor irgendetwas auch nur ein Byte davon gelesen hatte. Ein Durchlauf über eine Watchlist mit 163 Einträgen hat 121 Titel entfernt, und 12 der dahinterstehenden Releases ließen sich nicht lesen.

Jedes beschaffte Release wird jetzt gegen die News-Server geprüft, bevor irgendetwas als erledigt verbucht wird. Das ist dieselbe Prüfung, die der SABnzbd-Endpunkt seit dem 08.28 Nightly macht. Es gibt drei mögliche Antworten, und sie werden strikt auseinandergehalten.

- **Die Artikel sind weg.** Der Grab zählt nicht. Der Titel bleibt auf deiner Watchlist, die Anfrage bleibt offen, und das Release wird als tot vermerkt. So nimmt der nächste Versuch den nächsten Kandidaten, statt sich auf den zu versteifen, der schon in deiner Bibliothek liegt. Ein als tot bekanntes Release kostet gar nichts. Es wird nicht geholt und belegt auch keinen der drei Kandidaten, die ein Versuch probiert. So werden tote Posts ganz oben in einer Rangliste übersprungen, statt endlos wiederholt zu werden. Wird ein Season-Pack als tot erkannt, geht die ganze Staffel zurück auf „gewünscht“, damit stattdessen die einzelnen Episoden geholt werden.
- **Die Server konnten nicht gefragt werden.** Ein Pool, der nicht erreichbar ist, ein Account, der gedrosselt wird, oder schlicht eine Bibliothek, die die neue NZB noch nicht aufgelistet hat. Es wurde nichts festgestellt, also wird auch nichts entschieden. Die Anfrage wartet und wird erneut gefragt, und das Warten kostet keinen Wiederholungsversuch. Ein Release, das auch nach etwa zwei Stunden nicht geprüft werden kann, wird wie ein toter Kandidat zur Seite gelegt, und das nächste Release kommt dran. Der Titel wird niemals auf einem Release abgehakt, das niemand prüfen konnte.
- **Das Release ist vorhanden.** Genau wie bisher.

Eine Installation ohne Usenet-Account hat nichts zum Fragen und ist nicht betroffen.

## Die Prüfung eines großen Releases läuft auf einem langsamen News-Server nicht mehr aus der Zeit {#checking-a-big-release-no-longer-runs-out-of-time-on-a-slow-news-server}

Bevor ein Grab als fertig gemeldet wird, fragt zurg die News-Server bei jeder Datei darin nach. Bisher hat es das eine Datei nach der anderen gemacht. Manche Anbieter antworten auf solche Anfragen langsam und streng der Reihe nach. Alle auf einmal über eine Verbindung zu schicken bringt deshalb nichts. Der Server eines Anbieters brauchte über fünf Sekunden pro Datei. Bei einem 4K-Release mit 133 Volumes waren das etwa zwölf Minuten Anfragen, und jede Prüfung hat nur fünf Minuten Zeit. Die Prüfung konnte so nie fertig werden. Sonarr und Radarr haben drei Stunden gewartet und dann gesehen, dass das Grab fehlgeschlagen ist. Die Watchlist hat ewig gewartet.

Jetzt werden die Dateien mehrere auf einmal abgefragt, und zwar über alle Verbindungen deines Accounts außer der einen, die für Playback freigehalten wird. Je mehr Verbindungen dein Account erlaubt, desto schneller wird ein großes Release geprüft. Beim selben 133-Volume-Release, das vorher nie geprüft werden konnte, dauert es auf zwölf Verbindungen unter zwei Minuten. Auf vier Verbindungen läuft die Zeit trotzdem ab, weil die Anfragen selbst die Zeit kosten. Ein kleines Release ist nicht langsamer als vorher.

Ein Release, das die Prüfung nicht rechtzeitig schafft, blockiert den Titel nicht mehr. Die Watchlist legt es beiseite, so wie sie ein kaputtes Release beiseitelegt, und probiert das nächste Release. Der SABnzbd-Endpunkt meldet es wie immer als fehlgeschlagen, damit Sonarr und Radarr selbst ein anderes suchen.

## Cached-only-Grabs auf TorBox laden die Releases nicht mehr herunter, die sie eigentlich überspringen sollten {#cached-only-grabs-on-torbox-no-longer-download-the-releases-they-were-meant-to-skip}

TorBox hat ein Flag, das einen Add alles ablehnen lässt, was TorBox noch nicht hat. Es steht in deren API, aber in keiner ihrer Dokumentationen, und zurg hat es nicht benutzt: Ein nur-gecachter Grab hat den Torrent hinzugefügt, gewartet, ob er fertig wird, und ihn wieder gelöscht, als sich herausstellte, dass es ein echter Download ist. Das hat eines der sechzig stündlichen Adds des Accounts verbraucht, einen Transfer-Slot belegt und Daten für ein Release geladen, das der *arr bereits zum Überspringen markiert hatte.

Nur-gecachte Grabs fragen jetzt nach dem Inhalt und werden in unter einer Sekunde abgelehnt, wenn TorBox ihn nicht hat. Dabei bleibt nichts im Account zurück. Ein Fehlversuch kostet trotzdem eines dieser sechzig stündlichen Adds, deshalb taktet zurg sie wie bisher. Und ein Treffer wird trotzdem geprüft statt einfach geglaubt: Der Cache von TorBox kann Ja zu Inhalten sagen, die er dann nicht ausliefern kann. Deshalb muss das Release fertig sein, bevor zurg es meldet.

## Cached-only-Grabs auf Debrid-Link verbrauchen nicht mehr das tägliche Hinzufüge-Kontingent {#cached-only-grabs-on-debrid-link-no-longer-spend-the-daily-add-allowance}

Debrid-Link akzeptiert einen nackten Info-Hash genauso wie ein Magnet, und fügt den Hash nur hinzu, wenn es den Inhalt schon hat. zurg hat dagegen ein Magnet geschickt, und das ist eine Anweisung zum Abrufen. Jeder Cache-only-Fehlschlag wurde angenommen, auf die 50 uncached Adds pro Tag und einen der 20 Transfer-Slots des Accounts angerechnet und danach wieder gelöscht, um das Kontingent zurückzubekommen. Bei fünfzig Fehlschlägen konnte der Account bis zum täglichen Reset nichts mehr hinzufügen.

Cached-only-Grabs schicken jetzt den Hash. Ein Fehlschlag wird sofort abgelehnt, in etwa einer zehntel Sekunde, und der Account bleibt unberührt. So kann ein *arr eine lange Release-Liste durchgehen, ohne für die Einträge etwas auszugeben, die niemand gecacht hat. Das gilt auch für Grabs, die als .torrent-Datei ankommen. Die Datei soll einem Dienst die Metadaten-Abfrage ersparen, die ein nackter Hash erzwingt, und eine Cache-Abfrage braucht das nicht.

## Debrid-Link-Sperren wegen Rate-Limits werden jetzt wieder mit Backoff behandelt {#debrid-link-rate-limit-lockouts-are-backed-off-from-again}

Debrid-Link antwortet auf seine einstündige, pro Endpoint geltende Sperre mit HTTP 503 und dem Grund im Body. zurg hat jedes 503 als kurzen Ausfall des Dienstes behandelt, deshalb hat es den Grund nie gelesen und weiter einen Endpoint angefragt, der bereits gesagt hatte, dass man eine Stunde warten soll. Jetzt erkennt zurg die Sperre und bleibt von diesem Endpoint weg, bis sie aufgehoben ist.

## `__magic__` spiegelt deine Bibliothek jetzt unter `__magic__/__all__`, die Wurzel gehört weiterhin dir {#__magic__-now-mirrors-your-library-at-__magic____all__-leaving-its-root-to-you}

Der Namespace hat seinen Spiegel von `__all__` früher direkt in seiner eigenen Wurzel abgelegt. Dadurch war der Ordner, aus dem ein Download-Client importiert, derselbe Ordner, in dem jedes Release ohnehin lag. Ein Sonarr- oder Radarr-Root-Ordner musste *innerhalb* des Download-Ordners liegen, um die zwei Health-Checks zu umgehen, die diese Anordnung auslöst. Und ein manueller Import, der auf den Download-Ordner zeigte, durchsuchte die ganze Bibliothek nach einem einzelnen Release.

Der Spiegel liegt jetzt eine Ebene tiefer. `__magic__/__all__` ist die Bibliothek so, wie `__all__` sie auflistet, und genau das berechnen jetzt `sabnzbd.complete_dir` und `qbittorrent.save_path`. Die Wurzel von `__magic__` gehört dir, für die Ordner `tv`, `movies` und `anime`, auf die du die \*arrs zeigen lässt. Die beiden sind Geschwister, also enthält keiner den anderen, und kein Client schlägt deshalb Alarm.

**Das ändert Pfade.** Wenn du `sabnzbd.complete_dir` oder `qbittorrent.save_path` von Hand gesetzt hast — der Fall mit Container-Mapping —, hänge `/__all__` daran an. Wenn du eine Plex- oder Jellyfin-Bibliothek direkt auf `__magic__` statt auf einen Ordner darin zeigen lässt, verschieben sich ihre Pfade um eine Ebene. Zeig sie dann auf `__magic__/__all__` oder auf den Ordner, in den du importierst. Deine Root-Ordner bleiben, wo sie sind, und nichts in der Tabelle wird verschoben: Platzierungen sind Pfade unter Ordnern, die du angelegt hast, und Tombstones hängen am Release, also bleibt ein bestehendes Layout unverändert. Ein Grab, das beim Upgrade gerade läuft, trägt noch den alten Pfad und muss erneut gegrabbt werden.

In `__magic__/__all__` kann nichts geschrieben werden: Eine Zeile dort wäre eine zweite Adresse für ein Release, das schon eine hat. Deshalb werden MOVE, MKCOL oder DELETE darauf abgelehnt. Schreiben *innerhalb* eines Release-Ordners bleibt unverändert, denn genau dort legt ein \*arr die .nfo neben einer Datei ab, die es importiert hat.

## Export Logs zeigt dir jetzt, wohin deine Links gehen und wie lange sie gültig sind {#export-logs-now-tells-you-where-your-links-went-and-how-long-they-last}

Export Logs probiert mehrere Paste-Hosts aus und gibt dir den ersten zurück, der die Datei annimmt. Es hat nie gesagt, welcher es war, und sie sind nicht austauschbar: Der bevorzugte Host behält einen Paste 180 Tage und verlängert ihn jedes Mal, wenn jemand ihn aufruft, während der Ersatz-Host ihn nach drei Tagen löscht. Der Link sah genauso aus, und ein Bericht, den du an einem Freitag eingereicht hast, war am Montag zwei tote Links, ohne dass es eine Erklärung gab. Die Links kommen jetzt mit dem Host, der sie speichert, und der Frist, die dazu gehört.

Der Grund, warum du beim Ersatz-Host gelandet bist, ist der zweite Teil dieser Geschichte. Der bevorzugte Host sperrt eine Adresse, die ein paar Mal kurz hintereinander hochlädt. Ein Export veröffentlicht pro Klick zwei Dateien, daher wurde bei einer Reihe von Bug-Reports die Adresse abgewiesen. Danach wurde jede Anfrage von diesem Rechner abgelehnt, auch das Abrufen eines Pastes, den er schon gespeichert hatte. zurg hat trotzdem beide Hälften jedes späteren Exports dorthin geschickt und jede davon als fehlgeschlagenen Upload protokolliert. Das hat auf die Datei gezeigt statt auf die Adresse. Ein Host, der den Rechner abweist, wird jetzt einen Tag lang in Ruhe gelassen, und das Log sagt dir genau, dass das passiert ist.

## Beim Hochladen von Debug-Infos werden deine Indexer- und Download-Client-Schlüssel nicht mehr veröffentlicht {#uploading-debug-info-no-longer-publishes-your-indexer-and-download-client-keys}

Export Logs schwärzt vor dem Hochladen der Config auf einen Paste-Host jede Zugangsdaten, die es findet. Bisher hat es aber nur die oberste Ebene geprüft. Die Schlüssel in den verschachtelten Blöcken wurden deshalb im Klartext mitgeschickt: deine Newznab-Indexer-API-Keys (sowohl für die Stremio- als auch für die Watchlist-Listen), das Stremio-Addon-Token, die API-Keys von SABnzbd und qBittorrent, das zrok-Account-Token und der Plex-Scan-Token. Besonders heikel sind die Indexer-Keys: Die gehören zu deinem Usenet-Account, nicht zu zurg.

Das ist jetzt behoben, alle diese Werte werden geschwärzt. Provider-Tokens und Passwörter für News-Server waren nie betroffen.

## zurg kann von einem KI-Agenten gesteuert werden {#zurg-can-be-driven-by-an-ai-agent}

Es gibt einen neuen Endpunkt unter `/mcp`, der das Model Context Protocol spricht. So kann ein Client wie Claude die Bibliothek durchsuchen, herausfinden, warum ein Release nicht abspielbar ist, und es reparieren. Das läuft über typisierte Tools und nicht über das Auslesen des HTML-Dashboards.

Er ist standardmäßig ausgeschaltet. Aktivier ihn mit `mcp: {enabled: true}` und richte deinen Client auf `http://your-zurg:9999/mcp` mit demselben Benutzernamen und Passwort, das auch das Dashboard verlangt. Clients, die nur stdio sprechen, nutzen `zurg mcp`. Das verbindet sich mit der bereits laufenden Instanz, statt eine zweite zu starten.

Neben den Tools bietet er zurgs eigene Dokumentation und den aktuellen Zustand als Ressourcen, die ein Client direkt lesen kann. Außerdem gibt es sechs Prompts für Abläufe, die du genau so befolgen solltest: die Diagnose eines Releases, das nicht abspielbar ist, die sichere Vorbereitung eines Plex-Scans und die Sichtung dessen, was die Reparatur aufgegeben hat.

Er weiß, was er nicht still tun darf. Alles, was etwas wegnimmt, beschreibt zuerst, was es tun würde, und handelt erst, wenn du genau diesen Plan bestätigst. `read_only: true` blendet jedes Tool aus, das etwas verändert. Die Tools, die zurg oder dessen Mount anhalten könnten, bleiben hinter einem eigenen Schalter. Kein Ergebnis enthält ein Token, ein Passwort oder einen aufgelösten Link.

Siehe [der MCP-Server](mcp.md).

## zurg sagt dir, wenn dein Build veraltet ist {#zurg-says-when-your-build-is-out-of-date}

Zurg hat bisher nie angezeigt, wie alt ein Build ist. Deshalb kam es vor, dass ein im August behobener Fehler im September in einem Bug-Report landete, obwohl der Fix schon drei Wochen alt war, und niemand im Thread hatte einen Grund, das zu vermuten. Jetzt fragt zurg einmal am Tag das öffentliche Repository nach seinem neuesten Release. Ist dein Build älter, schreibt es eine Zeile mit dem Namen des Releases, seinem Datum und deinem eigenen Datum. Den Rest der Zeit ist es still: Wenn du aktuell bist, wird nichts ausgegeben, und wenn GitHub nicht erreichbar ist, auch nicht. Ein Build, der nicht weiß, wann er gebaut wurde, also das Docker-Image, wird nicht geraten. Sponsoren auf einem Nightly sind immer vor dem letzten öffentlichen Release und sehen es deshalb nie. Die Antwort wird einen Tag lang gecacht, damit ein Neustart keine Anfrage kostet. Eine abgelehnte Anfrage wird erst am nächsten Tag wieder versucht. Das Ganze lässt sich mit `disable_update_check: true` komplett abschalten.

## Ein toter Link in einem archivierten Release wird nicht mehr bei jedem Durchlauf als gesund gemeldet {#a-dead-link-inside-an-archived-release-stops-being-declared-healthy-every-sweep}

Wenn ein Release als einzelnes Archiv bereitgestellt wird und die Reparatur einen erneuten Hinzufügen nicht weiter eingrenzen kann, prüft zurg, ob das Archiv selbst noch lesbar ist. Wenn ja, hebt zurg die defekt-Markierungen am Release auf, statt es zu verwerfen. Dabei hob es alle auf, auch die Markierungen an Dateien, die der Account über eigene Links direkt anspricht. Ein erfolgreich geprüfter Archiv-Link beweist, dass das Archiv lesbar ist, aber nichts über diese Dateien. Eine Datei, deren Link der Account nicht mehr ausgeliefert hatte, wurde deshalb aufgrund eines unabhängigen Lesevorgangs wieder auf gesund gesetzt. Beim nächsten Durchlauf wurde sie wieder unrestricted, war erneut defekt, das Release wurde wieder verworfen, und der Durchlauf, der es verworfen hatte, stellte es am Ende wieder her.

Bei einem 64-Datei-Release mit 9 Links, die der Account nicht mehr ausgeliefert hatte, passierte das in einer Woche 111-mal, zweimal innerhalb von 40 Sekunden, mit zwei Magnet-Adds pro Durchlauf. Die Ausnahme gilt jetzt nur noch für Dateien, die das Archiv tatsächlich ausliefert, also diejenigen ohne eigenen Link. Eine Datei, die der Account direkt anspricht, behält das Urteil, das ihr eigener Link erzielt hat, und landet in der Reparatur. Nur dort kann sie einen funktionierenden Link bekommen.

## Downloads, die nur teilweise ankommen, bleiben nicht mehr ewig in der Warteschlange {#downloads-that-only-partly-arrive-no-longer-sit-in-the-queue-for-ever}

Wenn ein Teil der Dateien eines Releases nicht gelesen werden konnte, hat zurg den Download in der
Queue behalten und auf genaue Dateigrößen gewartet, die es nie erfahren würde. Die Prüfung, die das
Problem gefunden hätte, lief erst, wenn diese Größen eingetroffen waren. Sonarr und Radarr zeigten
so einen Download bei 0% und ohne verbleibende Zeit an, solange zurg lief. Das Release wurde nie auf
die Blockliste gesetzt, und es wurde auch nicht nach einem anderen gesucht.

zurg fragt jetzt bei den Newsservern nach, wenn ein Release seit dreißig Minuten wartet. Wenn die
Artikel dort nicht mehr vorhanden sind oder die Server gar nicht erst angefragt werden konnten, meldet
zurg den Download als fehlgeschlagen. Ein Release, dessen Größen tatsächlich noch unterwegs sind, ist
davon nicht betroffen und wird wie bisher zurückgehalten, bis die Größen eintreffen.

## Ein Release, das ein Konto aufgegeben hat, kann von einem anderen repariert werden {#a-release-one-account-gave-up-on-can-be-repaired-from-another}

Die Debrid-Dienste führen eigene Caches. Ein Release, das Real-Debrid gelöscht hat, oder eines, das allein wegen des Dateinamens abgelehnt wird, kann unter demselben Hash gerade bei AllDebrid gecacht sein. Bisher konnte zurg das nicht nutzen. Die Reparatur hat ein Release immer wieder in dem Account hinzugefügt, aus dem es stammte. Hatte dieser Account aufgegeben, gab es nichts mehr zu versuchen. Das Release blieb in deiner Bibliothek kaputt, obwohl ein anderer Account, für den du schon bezahlst, es hatte.

Jetzt wird ein Release, das jeder Account, der es hält, aufgegeben hat, deinen anderen Accounts angeboten. Der erste, der es schon hat, übernimmt es, und das Release hängt dann an beiden Accounts und wechselt bei Bedarf zwischen ihnen, so wie bei jedem Release, das zwei Accounts halten. Du musst nichts einschalten: Wenn du einen zweiten Account eingerichtet hast und die Reparatur aktiviert ist, passiert das automatisch, sobald die Reparatur keine anderen Optionen mehr hat.

Ein Account bekommt nur Inhalte, die er ohnehin schon hat. Müsste er das Release erst herunterladen, wird das Hinzufügen zurückgezogen und wieder gelöscht. So lädt nichts etwas herunter, und es wird kein Transfer-Kontingent verbraucht. Ein Account, der Nein sagt, wird einen Tag später erneut gefragt, dann nach zwei Tagen, dann nach vier, und so weiter bis etwa zwei Wochen. So kostet es nichts, bei einem Release nachzufragen, das endgültig weg ist.

## Cached-only-Grabs werden anhand deines Kontos beurteilt, nicht anhand einer Cache-Abfrage {#cached-only-grabs-are-judged-by-your-account-not-by-a-cache-lookup}

Im cached-only-Modus hat zurg früher bei TorBox, Premiumize und Offcloud nachgefragt, ob ein Release in deren Cache liegt, und diese Antwort direkt an Sonarr weitergegeben. Diese Endpunkte beantworten aber eine andere Frage als die, die gestellt wird. Sie sagen, dass der Inhalt im Cache des Dienstes liegt, nicht dass dein Account ihn am Ende auch wirklich hat. Danach hat niemand mehr den Torrent geprüft. Ein Ja, das dann zu einem Download wurde, kam bei Sonarr als der Instant-Grab an, den man versprochen hatte. Genau das soll cached-only aber verhindern.

Jeder Account wird jetzt gleich geprüft. Der Torrent wird hinzugefügt, die Instanz wird beobachtet, und nur wenn sie innerhalb des Zeitfensters fertig wird, zählt sie als cached. Alles andere wird wieder gelöscht und der Grab wird abgelehnt. Dadurch geht Sonarr zum nächsten Release in seiner Liste über. Der Nachteil: Ein Fehlschlag bei diesen drei Diensten verbraucht jetzt einen Add-Slot, während eine Cache-Abfrage früher nichts gekostet hat.

## Ein AllDebrid-Backup-Schlüssel beantwortet nicht mehr Anfragen an deine Bibliothek {#an-alldebrid-backup-key-no-longer-answers-for-your-library}

`download_tokens` bei einem AllDebrid-Account sind separate AllDebrid-Accounts, die für ihr Download-Kontingent genutzt werden. Sobald der eigene Key des Accounts sein Limit erreicht hatte und aus der Rotation fiel, ging jeder andere Aufruf auch über den Backup-Key raus: die Magnet-Liste, die Dateiliste eines Releases, Adds, Deletes, Restarts, die gespeicherten Links hinter `__downloads__` und die Änderungserkennung. Dadurch konnte der Library-Refresh die Magnets des Backup-Accounts auflisten und als deine übernehmen. Ein Delete konnte an einen Account geschickt werden, der diesen Magnet nie hatte, und kam dann zurück, als wäre er schon entfernt. Und sobald alle Keys am Limit waren, ging der ganze Katalog komplett offline, nur wegen eines Limits auf Bytes. Jetzt rotiert nur noch das Entsperren eines Links. Alles, was deinen Account betrifft, wird auch bei deinem Account abgefragt.

## Ein gesundes Release wandert nicht mehr ständig in die Broken-Liste und wieder heraus {#a-healthy-release-stops-flapping-in-and-out-of-the-broken-list}

Ein Release, dessen Account weiterhin einen toten Link anbietet, kann die Hälfte jeder Stunde in der Broken-Liste des Dashboards stehen, obwohl jede Datei darin einwandfrei abgespielt wurde. Repair entfernt einen Link, der drei Zyklen lang mit `hoster_unavailable` geantwortet hat, damit das Release stattdessen neu adressiert werden kann. Außerdem merkt sich Repair diese Entfernung, damit die nächste Auflistung den toten Link nicht wieder ausspuckt. Diese Merkliste wurde dann aber vom falschen Auslöser geleert: Jede Repair, die gut ausging, hat sie gelöscht, auch die Durchläufe, die gar nichts neu zuweisen und nur feststellen, dass die bereits vorhandene Adressierung des Eintrags noch funktioniert. „Das Archiv, das es ausliefert, funktioniert noch“ ist der Extremfall. Das beweist, dass der eine Link, der das Release ausliefert, funktioniert, und sagt überhaupt nichts über einen Link aus, den der Account abgelehnt hat. Die Aufgabe wurde also vergessen, die nächste Aktualisierung übernahm wieder denselben toten Link, Repair konnte ihn nicht erneut zuweisen und markierte den Eintrag erneut als defekt. Das wiederholte sich im Dreißig-Minuten-Takt ohne Ende. Gemessen an einer echten Bibliothek über drei Tage: Ein einzelnes Release wurde 129 Mal erneut als defekt markiert, in einer Woche gab es bibliotheksweit 556 solcher Markierungen, und jeder Zyklus verbrauchte zwei bis vier Magnet-Hinzufügungen. Jetzt vergisst nur noch eine Repair, die das Release tatsächlich neu adressiert hat, eine Aufgabe. Eine manuelle Repair vergisst weiterhin alle Einträge. So kann ein Operator einen Link von Hand wieder freigeben.

## Eine Version, die als ein einziges Archiv bereitgestellt wird, wird bei jedem Durchlauf nicht mehr als defekt markiert {#a-release-served-as-one-archive-is-no-longer-marked-broken-every-sweep}

Manche Releases werden als ein einziges Archiv bereitgestellt: Die `.rar`-Datei hat den einzigen Link des Accounts, und jede Episode darin wird als eigene Datei aufgelistet, ohne dass irgendwo ein Link dazu existiert. Der Reparatur-Durchlauf hat den Account trotzdem nach diesen internen Dateien gefragt. Es gab aber nichts, womit man fragen konnte. Also wurde kein Account abgefragt und nichts gemessen. Trotzdem kam die Antwort "file is broken" zurück. Die schrieb der Durchlauf auf jede Datei und nutzte sie, um das ganze Release zu verurteilen. Danach kosteten zwei Magnet-Adds Zeit: Der Account wurde nur nach den kaputten Dateien gefragt und antwortete mit demselben einzigen Archiv-Link wie immer. Der Archiv-Fallback prüfte dann diesen Link und stellte jede Datei wieder her, die gerade eben verurteilt worden war. Auf einer echten Bibliothek gemessen: 44 Episoden eines einzigen 4,9 GB großen Archivs durchliefen diesen Zyklus alle halbe Stunde. Eine Datei, für die kein Account einen Link hat, wird jetzt in Ruhe gelassen. Die eigene Datei des Archivs wird genauso beurteilt wie vorher. Wenn der Link, der das Release tatsächlich ausliefert, nicht mehr aufgelöst werden kann, wird diese Datei kaputt markiert und mit ihr das Release.

## Der Datenverkehr läuft wieder über dein eigenes Konto-Token, sobald dessen Kontingent zurückgesetzt wird {#traffic-goes-back-to-your-own-accounts-token-once-its-allowance-resets}

Ein Real-Debrid-Konto, das sein tägliches Kontingent aufbraucht, verlagert seinen Traffic auf den ersten `download_tokens`-Eintrag, der noch eines hat, und der Watcher nimmt das eigene Token des Kontos wieder in die Rotation auf, sobald es wieder Bytes ausliefern kann. Dass ein Token wieder verfügbar ist, hat den Traffic aber nicht zurückgeholt. Die Rotation hat dort weitergemacht, wo sie zuletzt stehen geblieben war, und nur geprüft, ob dieses eine Token begrenzt ist. Deshalb hat das Backup-Konto den ganzen restlichen Tag jedes Byte übernommen, obwohl der Zähler des Hauptkontos schon auf null stand. Die Reihenfolge in `download_tokens` ist jetzt eine Präferenz und keine Position, die abgearbeitet wird: Das Token, das am weitesten vorne steht und Bytes ausliefern kann, liefert auch aus. Dadurch übernimmt das Hauptkonto seinen Traffic wieder innerhalb einer Minute, nachdem sein Zähler zurückgesetzt wurde.

## Ein rclone-Remote, das auf die falsche Adresse zeigt, weist jetzt darauf hin {#an-rclone-remote-pointed-at-the-wrong-address-now-says-so}

Wenn die URL eines rclone-WebDAV-Remotes das `/dav/` am Ende fehlt, schlug jede Auflistung mit "couldn't list files: 405 Method Not Allowed" fehl, und nirgendwo stand, warum. Das Dashboard antwortete im Browser ganz normal, daher wirkte zurg gesund, und zurgs eigenes Log blieb still über den Client, der alle paar Sekunden fehlschlug. zurg beantwortet jetzt eine WebDAV-Anfrage, die außerhalb von `/dav/` ankommt, mit der richtigen Adresse, die rclone als Teil seiner eigenen Fehlermeldung ausgibt, und schreibt eine einzige Warnung mit dem Namen des Clients, der die Anfrage gesendet hat.

## Windows-Installationen senden wieder Scan-Aufträge an Medienserver {#windows-installs-now-send-media-server-scans-again}

Ein `mount_path` von `Z:`, also der Wert, den `zurg setup` unter Windows schreibt, hat Scan-Pfade relativ zum aktuellen Verzeichnis auf diesem Laufwerk statt relativ zu dessen Wurzel gebaut. Dadurch passte kein Pfad zum Bibliotheksabschnitt, zu dem er gehörte, und es wurde nie ein Scan gesendet. Die anschließende Warnung forderte dazu auf, einen `mount_path` zu prüfen, der bereits korrekt war. Bestehende Konfigurationen müssen nicht bearbeitet werden.

## Der Massen-Scan liest die Plex-Bibliothek einmal statt einmal pro Torrent {#bulk-scan-reads-the-plex-library-once-instead-of-once-per-torrent}

Das Matching nach einem Bulk-Scan im Dashboard hat für jeden Torrent im Batch die komplette Plex-Bibliothek neu eingelesen. Wenn man eine große Bibliothek gescannt hat, hat das hunderte identische Komplett-Abfragen an einen Plex-Server geschickt, der meistens gerade mit eigenen Scans beschäftigt war.

## Windows-Bibliothekspfade stimmen unabhängig von der Groß- und Kleinschreibung überein {#windows-library-paths-match-regardless-of-case}

Eine Plex-, Jellyfin- oder Emby-Bibliothek, die als `Z:\Movies` gespeichert ist, wird nicht mehr übersehen, wenn zurg `Z:\movies` aus seinem eigenen Verzeichnisnamen baut.
NTFS unterscheidet nicht zwischen Groß- und Kleinschreibung, also bezeichnen die beiden denselben Ordner. Bei einem exakten Vergleich wurde der Scan verworfen und der mount_path als falsch gemeldet.

## Eine Datei, die nicht mehr bereitgestellt wird, bringt keinen Plex-Scan mehr ins Stocken {#a-file-that-stops-serving-no-longer-stalls-a-plex-scan}

Eine kaputte Datei behielt ihren Platz im Verzeichnislisting und beantwortete Lesezugriffe mit `503 File temporarily unavailable (being repaired)`, bis etwas den Status aufhob, also bei laufender Reparatur, bis die Reparatur abgeschlossen war. Plex wartet bei einem 503. Eine einzige solche Datei bremst deshalb einen Bibliotheksscan aus, und eine Bibliothek, die viele davon enthält, wird nie fertig gescannt. Jellyfin geht einfach an ihnen vorbei und sieht völlig normal aus.

Das sind zwei getrennte Entscheidungen, und jetzt haben sie auch getrennte Antworten. Der Eintrag bleibt weiterhin gelistet, solange die Datei vielleicht wiederkommt. Ein Eintrag, der aus einem Ordner verschwindet, sieht für einen Media-Scanner wie eine Löschung aus und lässt das Medienelement in den Papierkorb wandern. Daran ändert sich nichts. Geändert wird der Lesezugriff: Er wird eine Minute lang nach dem Moment, in dem die Datei nicht mehr ausgeliefert wird, mit 503 beantwortet und danach mit 404. Eine Minute ist das, was ein Client gebrauchen kann. rclone wiederholt ein 503 und gibt einen Lesezugriff ungefähr an diesem Punkt auf. Ein kurzer Aussetzer wird also weiterhin abgefangen, und der Lesezugriff gelingt. Nach dieser Minute hat das 503 den Lesezugriff ohnehin schon scheitern lassen und alle Scans dahinter ausgebremst.

Gemessen mit einem echten Plex an einer Bibliothek mit fünfzehn Filmen, bei der zehn Dateien abgelehnt wurden und alle Dateien weiterhin gelistet waren: Lesezugriffe mit 404 beendeten den Scan in 5 Sekunden. Ein 503, das nie aufgehoben wurde, hatte bei Abbruch nach zehn Minuten erst drei der fünfzehn Dateien gefunden.

## Neue SABnzbd-Jobs warten nicht mehr hinter den Größenprüfungen einer vollen Bibliothek {#new-sabnzbd-jobs-no-longer-wait-behind-a-full-librarys-size-checks}

Als zurg mit einer großen Usenet-Bibliothek neu gestartet wurde, hat es für jeden Release eine Größenprüfung in die Warteschlange gestellt. Dabei hat es vergessen, welche fehlgeschlagenen Prüfungen noch in ihrer einstündigen Wartezeit für den nächsten Versuch steckten. Ein neu geholter Release konnte dann hinter Tausenden Hintergrundprüfungen festhängen, während Sonarr oder Radarr auf seine genauen Dateigrößen warteten. Größenprüfungen laufen jetzt über eine feste Worker-Warteschlange. Ein Release mit einem wartenden SABnzbd-Job rückt nach vorne. Abgeschlossene Prüfungen und Wartezeiten überstehen einen Neustart in `data/nzb-sizes/`. Solange Arbeit in der Warteschlange liegt, meldet zurg einmal pro Minute die Anzahl der wartenden, der Client-priorisierten und der laufenden Aufgaben.

## Downloads, die ein Client nie abschließt, verhindern nicht mehr den Import neuer Downloads {#downloads-a-client-never-clears-no-longer-stop-new-ones-from-being-imported}

zurg zeigt Sonarr, Radarr und anderen Download-Clients eine Seite mit fertigen Downloads und behält jeden davon auf dieser Seite, bis der Client ihn entfernt. Clients entfernen aber nur, was sie importieren oder als fehlgeschlagen markieren. Ein Import, den sie blockieren, etwa weil sie einen Titel nicht zuordnen können, blieb deshalb für immer auf der Seite. Sobald die Seite voll davon war, wartete jeder neu fertige Download in der Warteschlange und wurde nie importiert. Ein Download, der seit zehn Minuten auf der Seite liegt und nicht entfernt wurde, macht jetzt Platz für einen wartenden Download. Das funktioniert so wie bei SABnzbd, wo ältere Zeilen von der Verlaufsseite verschwinden, sobald neuere hinzukommen. Solange auf der Seite noch Platz ist, ändert sich nichts. Und wenn du ein Release erneut gegrabbt hast, bekommt es einen eigenen Platz.

## Ein Download, der über seine ID abgerufen wird, wird gefunden, sobald er fertig ist {#a-download-looked-up-by-its-id-is-found-as-soon-as-it-finishes}

Tools, die zurg einen Download nach dem anderen anhand seiner ID abfragen, etwa LazyLibrarian, bekommen jetzt sofort gemeldet, dass er fertig ist, sobald er es ist, selbst wenn die Seite mit den fertigen Downloads, die Sonarr und Radarr auslesen, voll ist. Vorher konnte so ein Download für sie unfertig wirken, bis auf der Seite wieder ein Platz frei wurde.

## Die Staffel-Korrektur hat jetzt eine Seite im Dashboard {#season-fix-has-a-page-in-the-dashboard}

Die bibliotheksweite Umbenennung, die Fansub-nummerierte Episoden unter den Namen ablegt, die Plex liest, war seit ihrer Veröffentlichung nur über zwei HTTP-Endpunkte erreichbar: `/torrents/season-fix/plan` und `/torrents/season-fix/apply`. Im Dashboard gab es dafür keine Bedienelemente, und in der Namensreferenz stand nur ein einziger Absatz. Eine Funktion, die niemand findet, existiert praktisch nicht. Dabei wurde genau diese Funktion erst diesen Monat im Wunschlisten-Kanal angefragt, von Leuten, die nicht wussten, dass sie schon fertig ist.

`/season-fix/` erklärt jetzt, was der Durchlauf macht, zeigt die kanonische Form, die er aus dem Fansub-Namen erzeugt, den er ersetzt, und sagt, woher die Staffelstruktur kommt: vom eigenen Metadaten-Anbieter von Plex, nie von der lokalen Bibliothek. Denn eine Bibliothek, die die Staffeln zusammengefallen lässt, ist ja genau das, was korrigiert wird. Außerdem steht dort, was der Mapper nicht anfasst und warum. Ein Scan, der fast leer zurückkommt, ist nämlich die vorsichtige Lösung, die so funktioniert, wie sie soll, und kein Fehler.

Scannen bleibt hinter einem Button versteckt. Die Planung geht jeden Torrent durch und fragt Plex bei jeder zugeordneten Serie nach, deshalb startet das bloße Öffnen der Seite nichts. Die Ergebnisse sind nach Serie gruppiert. Jede Umbenennung wird alt zu neu angezeigt, und die übersprungenen Dateien stehen hinter einem ausklappbaren Bereich. Ein Eintrag, der als wahrscheinlich falsche Serienzuordnung markiert ist, kommt nicht angehakt an und wird im Bestätigungsdialog noch einmal darauf hingewiesen. So kann das Anwenden aller Einträge auf einmal nicht still eine Veröffentlichung umbenennen, die der falschen Serie zugeordnet wurde.

## Spiele eine komprimierte Version ab, die auf mehrere Volumes aufgeteilt ist {#play-a-compressed-release-that-is-split-across-several-volumes}

Ein Release, das komprimiert statt als Ganzes abgelegt war, brach am Ende seines ersten Volumes ab. Alle Dateien darin wurden mit dem richtigen Namen und der richtigen Größe angezeigt, ließen sich dann aber nicht abspielen, und im Log stand ein fehlerhafter Header-CRC. zurg übernimmt das Entpacken jetzt über jede Volume-Grenze hinweg, sodass diese Releases vom Anfang bis zum Ende durchlaufen.

## Starte schnell, wenn dein Konto fehlgeschlagene Torrents enthält {#start-up-quickly-when-your-account-holds-failed-torrents}

Bei jedem Bibliotheks-Refresh wurde jeder Torrent, den dein Debrid-Dienst als fehlgeschlagen markiert hatte, einzeln erneut abgefragt, und der Dienst erlaubt davon nur wenige pro Sekunde. Bei einem Konto mit ein paar hundert solcher Torrents dauerte das allein über eine Minute, bei jedem Refresh, und deine Bibliothek blieb so lange nach jedem Start unlesbar. Das reicht, damit Plex einen Ordner scannt, der noch nicht da ist, und alles darin als nicht verfügbar markiert. zurg liest jetzt, was es über einen fehlgeschlagenen Torrent bereits weiß, von der Festplatte, und fragt den Dienst nur dann erneut an, wenn dieser meldet, dass der Torrent nicht mehr fehlgeschlagen ist.

## Hör auf, AllDebrid erneut nach Magnets zu fragen, deren Wiederholung es bereits abgelehnt hat {#stop-re-asking-alldebrid-about-magnets-it-has-already-refused-to-retry}

Wenn ein Magnet-Link fehlschlägt, bittet zurg AllDebrid, ihn erneut abzurufen. AllDebrid lehnt
einige davon ab, und diese Ablehnung wurde nicht auf die zwei Versuche angerechnet, die ein
Torrent bekommt. Deshalb wurde derselbe Magnet bei jeder Bibliotheksaktualisierung erneut
angefragt, solange zurg lief. Die Antwort wird jetzt eine Stunde lang gespeichert, und zwar
für den Status, den der Account dabei gemeldet hat. Ändert sich ein Magnet, wird er also neu
angefragt. Die Anzahl der Versuche wird außerdem auf die Festplatte geschrieben, statt bei
jedem Neustart vergessen zu werden und dann wieder komplett neu verbraucht zu werden.

## Der Link bleibt stabil für eine Version, die dein Konto doppelt enthält {#keep-the-link-steady-for-a-release-your-account-holds-twice}

Ein Release, das zweimal in ein Konto gelegt wurde, hat von allem zwei Exemplare, auch zwei Download-Links pro Datei. zurg hat pro Konto nur einen Link behalten. Bei jedem Refresh hat dann eine Kopie die andere ersetzt, und der Eintrag kam nie zur Ruhe. Abspielbar war trotzdem alles, aber das Log lief mit Umbiegen der Links voll, und die Bibliothek wurde alle paar Sekunden neu auf die Festplatte geschrieben. zurg lässt den Link jetzt in Ruhe, wenn es nur einen Teil dessen sieht, was im Konto liegt.

## Schnellere Änderungsprüfungen bei TorBox, wenn das Konto fehlgeschlagene Torrents enthält {#faster-change-checks-on-torbox-when-the-account-holds-failed-torrents}

TorBox hat keine Möglichkeit abzufragen, ob sich ein Konto geändert hat. Deshalb liest zurg eine kleine Seite mit den neuesten Torrents und beobachtet die, die noch nicht fertig sind. Ein Torrent, der bei TorBox fehlgeschlagen ist, wird nie fertig. Ein einziger alter Fehler sorgte daher dafür, dass jede Prüfung für den Rest der Kontolaufzeit eine viel größere Seite las. Fehlgeschlagene Torrents werden nicht mehr auf eine Bewegung hin beobachtet, die sie nie machen können.

## Eine Version, die dein *arr nicht importieren konnte, wird durch den Versuch nicht mehr gelöscht {#a-release-your-arr-could-not-import-is-no-longer-deleted-by-the-attempt}

Wenn zurg das Verschieben eines Releases aus dem Usenet-Staging-Ordner verweigert, weil es nicht von den News-Servern gelesen werden kann, geben Sonarr und Radarr nicht einfach auf. .NET kopiert die Datei bei einem fehlgeschlagenen Verschieben und löscht danach das Original. zurg hat dieses Löschen befolgt, deshalb war das Release verschwunden und an seiner Importstelle lag eine leere Datei. Das Löschen, das auf ein verweigertes Verschieben folgt, wird jetzt aus demselben Grund verweigert, und das Release bleibt an seinem Platz.

## Bei Usenet-Lesevorgängen wird ein langsamer Batch von einem hängenden unterschieden {#usenet-reads-tell-a-slow-batch-from-a-stalled-one}

zurg fragt bei einer zweiten Newsverbindung nach einem Artikel, dessen Wartezeit zu lang geworden ist, und nimmt die Antwort, die zuerst ankommt. Dass die Wartezeit zu lang war, wurde nach der Uhr entschieden. Dadurch wurde ein normales Batch mit großen Artikeln auf einem schnellen Account zweimal angefragt, während der erste Artikel noch ankam.

Diese Entscheidung kommt jetzt von den Bytes auf der Leitung. Eine Newsverbindung setzt ihren Timeout sowieso jedes Mal neu, wenn Bytes ankommen, und der Reader sieht diesen Nachweis ebenfalls. Ein Batch, das mitten in einem großen Artikel steckt, wird in Ruhe gelassen, egal wie lange dieser Artikel braucht. Nur ein Batch, dessen Bytes stehen geblieben sind, wird bei einer anderen Verbindung angefragt.

Wenn eine Verbindung ein Batch von Artikeln übernimmt und dann keinen davon beantwortet, fragt zurg bei einer anderen Verbindung auf einmal den ganzen restlichen Batch an, statt jeden fehlenden Artikel einzeln zu suchen. Die ruhige Verbindung wird nie abgebrochen, ihre Artikel zählen also weiterhin, falls sie ankommen. Nur die Artikel, die nie angekommen sind, werden erneut angefragt, und zwar höchstens einmal pro Batch. Die Artikel, die der Abspielposition am nächsten liegen, kommen zuerst. Außerdem bleibt immer eine zweite Anfrage frei, damit der nächste Read, der stehen bleibt, seinen eigenen Artikel noch anfordern kann.

Ein Read behandelt die Wartezeit, die er für eine zweite Anfrage verbraucht hat, auch nicht mehr als seine normale Geschwindigkeit. Er lernt nur die Zeit, die zurg bereit war zu warten, mehr nicht. Auf einem Account, bei dem jeder Artikel legitim eine Sekunde oder mehr braucht, pendelt sich der Schwellenwert jetzt nahe bei dem ein, was dieser Account wirklich liefert. Er fällt nicht mehr auf seine kürzeste Einstellung und fragt bei den meisten Artikeln nicht mehr zweimal an.

## Das Usenet-Read-ahead hält sein Fenster über Artikel und Volumes hinweg voll {#usenet-read-ahead-keeps-its-window-full-across-articles-and-volumes}

Read-ahead hat früher keine neuen Bytes mehr angefordert, solange ein früherer Artikel verspätet war. Dadurch hat ein langsamer Artikel das Fenster geleert, das vorher aufgebaut worden war. zurg hält jetzt trotzdem ein begrenztes Fenster angeforderter Bytes in Arbeit, und ein Batch von Artikeln kann die Verbindung zwischen zwei gespeicherten RAR-Volumes überspannen, statt an ihr zu enden.

Das Fenster nutzt höchstens ein Viertel des RAM-Caches, den du konfiguriert hast, und nie mehr als 128 MiB. Ein kleinerer Cache ergibt also auch ein kleineres Fenster. Anfragen behalten ihre eigene Abbruchmöglichkeit sowie die Verbindungs- und Cache-Limits ihres Accounts.

## Usenet-Wiedergabe verbraucht auf älteren Prozessoren weniger CPU {#usenet-playback-costs-less-cpu-on-older-processors}

Der Read-Cache erzeugt für jeden Datensatz, den er speichert, eine Prüfsumme. Auf Intel- und AMD-Prozessoren, die SSE4.1, aber kein AVX haben, läuft SHA-256 komplett ohne Hardware-Unterstützung, und genau diese Kosten haben sich beim Abspielen bemerkbar gemacht. zurg nutzt auf diesen Prozessoren jetzt eine schnellere 256-Bit-Prüfsumme. Die Datensätze enthalten eine Versionsnummer, daher wird Beschädigung weiterhin erkannt, ein bestehender Cache bleibt lesbar, und alle anderen Prozessoren verwenden weiterhin SHA-256.

## NZB-Freigaben verweisen nicht mehr auf das Konto, das sie geholt hat {#nzb-shares-no-longer-point-back-to-the-account-that-grabbed-them}

Manche Indexer versehen jeden Download mit Angaben, die zu deinem Konto zurückführen, und ein Teil davon steckte in Feldern, die eine Freigabe behalten hat. Einer versteckt ein frisches Token im Release-Titel und oft auch im Passwort und ändert bei jeder Datei den Poster, das Datum und die Newsgroup. Ein anderer setzt deine Kontonummer vorne in den Betreff einer Datei. Ein dritter setzt in jeden Poster eine Kontomarkierung. `zurg nzb-share` entfernt jetzt Poster und Datum, gibt jeder Datei dieselbe feste Newsgroup, schneidet den Betreff-Stempel ab und ignoriert ein Token, egal wo es steht. Wenn Name und Titel nicht übereinstimmen, gewinnt der Name. Zwei Leute, die sich denselben Release geholt haben, veröffentlichen jetzt dieselbe Datei. Freigaben lassen außerdem keine NZBs mehr aus, die in der Kodierung Latin-1 gespeichert sind, und verdoppeln die Backslashes nicht mehr, die manche Betreffzeilen enthalten.

Was das Bereinigen entfernt, steht unter [`zurg nzb-share`](cli.md#zurg-nzb-share).

## Lokale Bibliotheken ergänzen den Hash bei AllDebrid, Premiumize und Offcloud {#local-libraries-add-the-hash-on-alldebrid-premiumize-and-offcloud}

Eine lokale Bibliothek, deren Manifest keinen portablen Link hat, fügt den Hash beim ersten Abspielen zu deinem Konto hinzu. Ein aus TorBox exportiertes Manifest ist immer so. Das gilt auch für eines, dessen AllDebrid-Link abgelaufen ist. Bei AllDebrid, Premiumize und Offcloud ist jede solche Wiedergabe mit „provider did not report an active torrent allowance“ fehlgeschlagen. zurg wollte, dass das Konto vor dem Hinzufügen seine Torrent-Slot-Grenze meldet. Diese drei melden nie eine. zurg greift jetzt auf die angegebene Slot-Anzahl zurück, so wie es bei repair auch passiert. Gibt es auch die nicht, fügt zurg den Hash trotzdem hinzu und lässt den Anbieter ein volles Konto ablehnen.

## Offcloud-Dateien melden ihre Länge {#offcloud-files-report-their-length}

Beim Auflösen einer Offcloud-Datei blieb ihre Länge leer. Eine lokale Bibliothek prüft diese Länge gegen ihr Manifest. Deshalb hat sie jede Offcloud-Wiedergabe mit "resolved file size does not match the portable manifest" abgelehnt. Auch die normale Wiedergabe hat die Bereichsverarbeitung verloren, die eine Länge braucht. zurg fragt den Auslieferungsserver jetzt nach der Länge, so wie es die Offcloud-Auflistung schon macht.

## zurg läuft auf Android-Handys und Google TV {#zurg-runs-on-android-phones-and-google-tv}

Eine neue Android-App hostet deine Bibliothek direkt auf dem Gerät. Sie passt sich an Smartphones und Tablets sowie an Android TV und Google TV an. Dafür braucht sie Android 8.0 oder neuer, und Usenet braucht ein 64-Bit-Android. Die App führt dich durch die Anbieterkonten und ein Geräteprofil und startet danach die Bibliothek. Du durchsuchst sie in der App oder über Files von Android und spielst sie im externen Player deiner Wahl mit vollem Spulen ab. Eine TV-Fernbedienung funktioniert auf allen Bildschirmen. MediaInfo läuft auf dem Gerät ohne zusätzliche Tools. Die Bibliothek kannst du außerdem mit anderen Geräten in deinem lokalen Netzwerk teilen, geschützt durch ein Passwort. Dieses Passwort wird nie an einen Player übertragen.

Die APKs findest du in den Sponsor-Nightly-Releases. Die App enthält zurg selbst nicht. Nachdem du dich bei GitHub angemeldet hast, installiert sie die zurg-Engine als zweites Paket. Die App und die Engine werden getrennt aktualisiert. Unter Updates werden alle noch veröffentlichten Engine-Versionen aufgelistet. So kannst du eine Nightly, die auf deinem Gerät Probleme macht, auf eine funktionierende Version zurücksetzen. Wer den ersten Android-Build installiert hat, muss einmal eine Engine aus Updates installieren. Anbieter und Bibliothekseinstellungen bleiben dabei unverändert erhalten.

Die Engine für 64-Bit-ARM-Geräte löst Anbieteradressen jetzt über den eigenen Resolver von Android auf. Die Engine des ersten Builds konnte unter Umständen gar keinen Anbieter erreichen.

Hinweise zur Einrichtung und zum Player findest du unter [Android](../guides/android.md).

## Eine neue NZB erscheint innerhalb von Sekunden in der Bibliothek {#a-new-nzb-shows-up-in-the-library-within-seconds}

Ein NZB, der in das Watch-Verzeichnis gelegt wurde, hat bisher auf die nächste periodische Änderungsprüfung gewartet. Ein verschleierter Release musste dann noch ein weiteres Intervall warten, bis seine echten Dateinamen gelesen waren. Bei der Standardeinstellung waren das zusammen 20 bis 30 Sekunden, während die Sonarr- oder Radarr-Anfrage die ganze Zeit auf "Queued" stand.

zurg prüft jetzt das Watch-Verzeichnis selbst einmal pro Sekunde. Es verlässt sich nicht auf Dateisystem-Events, daher verhält es sich auf einem NAS oder in einem Container genauso. Ein Release erscheint in der Liste, sobald seine Namen gelesen wurden. Ein Season Pack mit zwanzig Releases braucht trotzdem nur einen Listing-Vorgang. Die periodische Prüfung bleibt als Sicherheitsnetz für den Fall, dass ein NZB unter einem bereits vorhandenen Namen ersetzt wurde.

## Usenet-Streams halten ihre Geschwindigkeit {#usenet-streams-hold-their-speed}

Eine Datei in einem RAR-Set kommt vom News-Account jeweils Volume für Volume an. zurg öffnet das nächste Volume früh, damit der Übergang nicht kalt startet. Früher wurden nur die ersten vier Megabyte vorgeladen. Bei einem Release, das in kleine Volumes zerteilt war, gab es deshalb alle ein bis zwei Sekunden Wiedergabe eine Grenze und an jeder Grenze einen Hänger. Ein solches Release lief mit 14 bis 16 MB/s, während eine normale Datei auf demselben Account mit 86 bis 99 MB/s lief. Das nächste Volume wird jetzt bis zu einem vollen Vorauslesfenster tief vorgeladen, sobald der Stream sich ihm auf 32 MiB nähert. Ein Volume, in das der Stream gerade eingetreten ist, behält das Vorauslesen, das es sich verdient hat. Ein Volume, in dessen Nähe nichts passiert, wird weiterhin nur am Anfang vorgeladen. So zieht ein Bibliotheks-Scan keine Daten, die nie gelesen werden.

Ein gleichmäßiges Lesen verbrachte außerdem etwa eine Sekunde von zwanzig damit, an einem einzigen langsamen Artikel zu kriechen, während alle anderen Verbindungen dahinter warteten. zurg fragt jetzt eine zweite Verbindung nach genau diesem Artikel, sobald das Warten lang wird, und nimmt die Antwort, die zuerst ankommt. Das passiert nur bei einem Lesezugriff, auf den ein Player wartet. Vorauslesen und Reparatur werden nie doppelt ausgeführt. Es ist auf zwanzig zusätzliche Anfragen pro Minute und Account begrenzt.

Der Lesezugriff, auf den ein Player wartet, hat jetzt an mehr Stellen Vorrang. Das Vorauslesen nimmt keine letzte freie Verbindung eines Accounts mehr. Auch der Größenabgleich beim Start lässt eine frei. Ein Lesezugriff nutzt Verbindungen, die der Account bereits hält, statt eine eigene zu öffnen. Er wartet auf eine Verbindung, die schon aufgebaut wird, statt eine weitere zu bezahlen. Der Artikel, bei dem ein Player hängt, kann in der Warteschlange vor Abrufen für spätere Bytes springen. In einer Messung kam das erste Byte eines Lesezugriffs nach 177 ms statt nach 354 ms an. Aufwärmen, Keep-alives und Lesezugriffe teilen sich jetzt außerdem ein gemeinsames Verbindungslimit. zurg öffnet nie mehr Verbindungen, als der Account erlaubt.

Das Speichern eines dekodierten Artikels im Disk-Cache hält den Lesezugriff, der ihn geholt hat, nicht mehr auf. Der Schreibvorgang lag früher in einem Lock, das alle anderen Lesezugriffe brauchten. Jetzt passiert er, nachdem die Bytes beim Player angekommen sind. Ein Schub, der größer ist, als der Cache verarbeiten kann, überspringt die zusätzlichen Einträge, statt die Wiedergabe zu verlangsamen. Ein bestehender Cache wird unverändert übernommen.

## Sonarr und Radarr warten nicht mehr auf Grabs, die niemals abgeschlossen werden können {#sonarr-and-radarr-stop-waiting-on-grabs-that-can-never-finish}

Der SABnzbd-Endpunkt hat früher manche Jobs für immer in der Warteschlange gelassen. Der Client hat sie nie auf die Blockliste gesetzt und nie einen anderen Release geholt. Jeder unten genannte Fall wird jetzt als Failed gemeldet, mit einer Nachricht, die den Grund nennt. Failed sorgt dafür, dass Sonarr und Radarr das Release blocklisten und neu suchen.

Ein Release kann nach dem Grab aus der Bibliothek verschwinden. Es kann im Dashboard gelöscht, aus dem Watch-Verzeichnis entfernt oder von jedem Account gelöscht worden sein. Der Job blieb früher bei 0 % stehen, und nichts hat ihn je weitergebracht. Jetzt schlägt er fehl, sobald das Release fünfzehn Minuten lang weg war. In den ersten fünfzehn Minuten nach einem Neustart schlägt nichts fehl, solange die Bibliothek noch lädt.

Ein Grab kann auf einem Release landen, das ein früherer Import schon geleert hat. Das passiert, wenn ein Upgrade die importierte Datei löscht und eine Suche wieder dasselbe Release findet. zurg hat früher mit Completed geantwortet und den Client auf einen leeren Ordner zeigen lassen. Ein späteres Grab eines geleerten Releases schlägt jetzt sofort fehl. Ein Ordner, der fünfzehn Minuten leer bleibt, lässt seinen Job ebenfalls fehlschlagen. Dazu gehört ein Ordner, der von Hand verschoben wurde, oder ein Import, der unter einem anderen Job abgelegt wurde. Das Grab, das den Import ausführt, zeigt während des Abschlusses weiterhin Completed.

Manche Releases schließen die Artikelprüfung nie ab. zurg fragt die News-Server, ob die Artikel eines Releases noch vorhanden sind, bevor ein Grab als fertig gemeldet wird. Eine Prüfung, die nicht abgeschlossen werden konnte, wurde früher jede Minute ohne Ende wiederholt. Jetzt schlägt sie fehl, nachdem dreißig Versuche in Folge stattgefunden haben, die sich über mindestens drei Stunden erstrecken. Ein News-Account, der eine Stunde lang nicht erreichbar ist, sorgt nicht dafür, dass alle wartenden Jobs geblocklistet werden. Eine Prüfung, die schließlich eine Antwort liefert, setzt den Zähler zurück.

Manche Releases enthalten nicht ihr komplettes Archiv. Einem Set kann das Volume fehlen, das den Anfang der Datei enthält. Es kann ein Volume aus der Mitte fehlen. Es kann an einem anderen Volume als dem ersten beginnen. Sonarr wurde früher auf einen Ordner gezeigt, aus dem es nie importieren konnte, und hat es immer wieder versucht. Das Grab schlägt jetzt fehl. Das Urteil bezieht sich auf genau die Volumes, auf deren Grundlage es gefällt wurde. Eine PAR2-Reparatur, ein erneutes Grab oder ein zweiter Account, der die fehlenden Volumes hat, sorgt dafür, dass das Release erneut geprüft wird.

## Backup-Download-Tokens übernehmen, wenn das tägliche Kontingent aufgebraucht ist {#backup-download-tokens-take-over-when-the-daily-allowance-runs-out}

Real-Debrid verweigert einen Download, sobald ein Token sein tägliches Kontingent aufgebraucht hat. zurg soll dieses Token dann ausmustern und zum nächsten Eintrag in `download_tokens` weitergehen. Das hat während der Wiedergabe aufgehört, als die Proxy-Streams auf einen neuen HTTP-Client umgestellt wurden. Die Verweigerung kam als ganz normale Antwort zurück, und nichts hat das Token als verbraucht markiert. Alle Backup-Tokens blieben ungenutzt, und jeder Lesezugriff hat wieder das gedeckelte Token verbraucht.

Die Verweigerung wird jetzt überall erkannt, wo zurg auf sie trifft. Das gilt für die Wiedergabe, aber auch für die Refresh-Schleife und die Reparatur. Beide prüfen Links, egal ob gerade etwas abgespielt wird. Eine Verweigerung ohne den üblichen Real-Debrid-Header wird ebenfalls als Grund genommen, das Token auszumustern.

Ein ausgemustertes Token wird jede Minute getestet, damit es wieder aktiv werden kann, sobald sein Kontingent zurückkommt. Dieser Test nutzte einen Link, der im Cache unter dem ausgemusterten Token selbst lag. Nachdem das Token nicht mehr ausliefert, füllt nichts diesen Cache nach. Der Test fand daher nichts, und das Token blieb bis zum nächtlichen Reset oder bis zu einem Neustart draußen. Jetzt leiht es sich einen Link von dem Token, das noch ausliefert.

Der nächtliche Reset kam einen Tag zu spät. Real-Debrid setzt die Kontingente ein paar Minuten nach Mitternacht MEZ zurück. zurg hat nach jedem Start die erste Mitternacht übersprungen und erst bei der zweiten zurückgesetzt. Ein Konto, das sein Kontingent aufgebraucht hatte, lief dadurch einen zusätzlichen Tag über das Backup-Token weiter. Außerdem hat zurg diese Mitternacht aus dem Datum des Hosts berechnet. Westlich von Europa hieß das, dass der Reset auf der Uhrzeit lag, zu der zurg zufällig gestartet wurde. Jeder Reset wird jetzt anhand des Datums in MEZ geplant.

## Ein Magnet-Grab behält seinen Release-Namen auf dem Debrid-Konto {#a-magnet-grab-keeps-its-release-name-on-the-debrid-account}

Sonarr und Radarr geben dem qBittorrent-Endpunkt den kompletten Magnet-Link des Indexers. zurg hat ihn früher vor dem Hinzufügen auf den Info-Hash gekürzt. Der Anzeigename und die Tracker kamen dadurch nie beim Account an. Bei einem Indexer, der nur Magnet-Links liefert, ist der Anzeigename die einzige Stelle, an der der Release-Name steht. Ein nicht gecachter Torrent landete dann in der Liste des Accounts unter einem 40-stelligen Hash. Bei einem Torrent, den niemand seedet, ist das der einzige Name, den er je bekommt.

Der Magnet-Link erreicht den Account jetzt so, wie ihn der Client geschickt hat. Repair, die Plex-Watchlist und portable Bibliotheken fügen weiterhin nur den nackten Hash hinzu, weil sie keinen Namen weitergeben können.

## Der .strm-Export enthält nur Dateien, die ein Player öffnen kann {#the-strm-dump-holds-only-files-a-player-can-open}

`save_strm_files` hat früher für jede ausgewählte Datei eines Releases eine .strm geschrieben. Untertitel, Poster, NFOs und PAR2-Volumes wurden so zu Bibliothekseinträgen, die ins Leere führten. TorBox und AllDebrid markieren jede Datei als ausgewählt. Das gilt auch für einen Usenet-Post mit seinen Reparatur-Dateien neben dem Video. Jetzt bekommen nur erkannte Video- und Audiodateien eine .strm, zusammen mit allem, was in `addl_playable_extensions` steht. Ein Video in einem RAR-Set wird weiterhin geschrieben, die Volumes drumherum dagegen nicht. Einträge, die frühere Builds geschrieben haben, werden beim nächsten Durchlauf des Releases entfernt.

Mehrere Schreibpfade haben dem Medienserver außerdem einen Scan gemeldet, bevor die .strm-Dateien existierten. Plex, Jellyfin oder Emby konnten dann einen leeren Ordner ansehen und nichts indexieren. Bis sich das Release änderte, hat niemand nachgefragt, ob neu gescannt werden soll. Auf allen Pfaden werden die Dateien jetzt zuerst geschrieben.

## Das Verschieben des zurg-Ordners lässt den Mount-Cache nicht mehr verwaisen {#moving-the-zurg-folder-no-longer-strands-the-mount-cache}

Der rclone-Mount legt, was er liest, in `data/rclone-cache` ab. rclone benennt diesen Cache nach seiner eigenen Konfiguration. Zu der Konfiguration gehört der vollständige Pfad des Ordners `data/local` von zurg. Wenn man den zurg-Ordner verschiebt oder `union_writable` ändert, bekommt der Cache einen neuen Namen. Der alte Baum blieb auf der Festplatte liegen, wo keine Größenbegrenzung ihn mitzählte und ihn niemand aufräumte. Ein paar Verschiebungen konnten so Terabytes zurücklassen.

Beim Start des Mounts fragt zurg jetzt bei rclone nach, welcher Cache-Baum gerade benutzt wird, und löscht die anderen. Was er freigegeben hat, schreibt er ins Log. Die Bereinigung überspringt er, wenn `rclone_extra_args` ein eigenes `--cache-dir` setzt. Mit `rclone_cache_reclaim: false` bleiben die alten Bäume erhalten.

Der aktive Cache ist auch größer, als die meisten erwarten. Er wächst bis auf 256G (Standardwert) und bleibt dort. Der nächtliche Durchlauf eines Media-Servers berührt jede Datei, daher greift das 72-Stunden-AltersLimit fast nie und wirft nichts raus. Plane deshalb mit der Größenbegrenzung. Wie man sie senkt, steht in [der Konfigurationsreferenz](config.md#disk-the-mount-uses).

## Poster und .nfo-Dateien landen weiterhin in `__magic__` {#posters-and-nfo-files-keep-landing-in-__magic__}

Ein Client, der über den Mount von zurg schreibt, legt neue Dateien in `data/local` ab. Dort speichert `__magic__` seine Sidecars. zurg hat jede Datei in diesem Ordner auf `sidecar_budget_mb` angerechnet. Ein paar Videos, die ein \*arr über den Mount geschrieben hat, konnten das ganze Budget aufbrauchen. Danach wurde jede .nfo und jedes Poster abgelehnt, als wäre der Speicher voll. Das Budget zu erhöhen hat nie geholfen. Eine Datei, die größer als `sidecar_max_mb` ist, kann nicht über den Sidecar-Pfad von zurg gekommen sein. Diese Dateien zählen jetzt nicht mehr gegen das Budget. zurg nennt sie beim Start einmal, weil sie trotzdem Speicherplatz belegen.

Das Löschen eines `__magic__`-Pfads, der schon nicht mehr existiert, klappt jetzt. Der Mount kann einen geteilten Sidecar von beiden Seiten entfernen, ohne das Aufräumen eines Imports zu brechen.

## Ein Stremio-Abspielen probiert die nächste Version aus, wenn die erste veraltet ist {#a-stremio-play-tries-the-next-release-when-the-first-has-aged-off}

Ein Klick auf Play in Stremio hat früher nur eine Release versucht. Wenn diese Release nichts Abspielbares enthielt, schlug das Abspielen mit einem 404 fehl. Die übliche Ursache ist ein Beitrag, der vom News-Server verschwunden ist. Die Stream-Liste hätte aber ein Dutzend andere Releases zeigen können.

Ein abgelehnter Play-Versuch probiert jetzt bis zu zwei weitere Zeilen aus derselben sortierten Liste. Er beginnt nach der Zeile, die du gewählt hast. Der Ersatz hat also dieselbe Auflösung und eine kleinere Datei oder die Stufe darunter. Es wird nie eine größere Release genommen, die du übergangen hast. Eine Release, die noch geladen wird, antwortet weiterhin mit 503. Wenn du dann erneut auf Play drückst, wird sie übernommen. Jeder Versuch verbraucht einen Indexer-Abruf und lässt die Release in der Bibliothek. Play-Links, die vor dieser Änderung erstellt wurden, verhalten sich weiterhin wie bisher.

## Stremio-Listen zeigen jede Auflösung und eine Spanne von Größen {#stremio-lists-show-every-resolution-and-a-spread-of-sizes}

Die Begrenzung der Stream-Liste hat früher über die ganze Liste hinweg gezählt. 4K-Ergebnisse stehen in der Sortierung oben, und ein beliebter Titel hat mehr davon, als das Limit erlaubt. Die Liste konnte sich mit 20 bis 40 GB großen Remuxes füllen und alle 1080p- und 720p-Releases verstecken, die die Suche gefunden hatte. `stremio.max_results` zählt jetzt pro Auflösung und steht standardmäßig auf 5. Ein Wert, den du von Hand gesetzt hast, behält seine Zahl und gilt jetzt für jede Auflösung.

Innerhalb einer Auflösung hat die Liste früher nur die größten Releases behalten. Das 4-GB-Encode, das ein Handy oder Laptop abspielen kann, wurde abgeschnitten. Jede Auflösung behält jetzt gleichmäßig verteilte Auswahlen vom größten bis zum kleinsten Release. Beide Enden sind immer dabei.

Die Beschreibung jedes Streams endet jetzt mit dem Alter des Releases, also wie lange er schon gepostet wurde. Sie sieht so aus: `3d`, `126d` oder `2y`. Das Alter ist ein guter Hinweis darauf, dass ein Post vom Newsserver gelöscht worden sein könnte. Ergebnisse, die vor dieser Änderung gecacht wurden, zeigen kein Alter, bis der Cache für diesen Titel aktualisiert wird.

Das Manifest des Addons enthält jetzt die echte Build-Version statt `0.1.0`. `zurg --version` gibt dieselben Build-Details aus wie `zurg version` und braucht keine Config-Datei.

## Gesunde Versionen verschwinden nicht mehr aus der Bibliothek {#healthy-releases-stop-disappearing-from-the-library}

Ein fehlgeschlagener Verbindungsaufbau oder DNS-Lookup bei der Real-Debrid-API markiert das Konto jetzt vorübergehend als nicht verfügbar. Früher wurden dadurch gesunde Dateien als defekt markiert. Sie warteten dann auf eine Reparatur, obwohl das Netzwerk längst wieder da war.

Die Bereinigung nach einer Bibliotheksaktualisierung musste früher auf die Hintergrundanalyse der Medien warten. Bis sie lief, hatte eine neuere Aktualisierung vielleicht eine Version wieder hinzugefügt. Die verspätete Bereinigung hat sie dann wieder entfernt. Die Bereinigung ist jetzt vor dem Ende einer Aktualisierung abgeschlossen. Die Medienanalyse läuft weiterhin im Hintergrund.

## Kodi kann die WebDAV-Freigabe durchsuchen {#kodi-can-browse-the-webdav-share}

WebDAV-Listings geben jetzt bei jedem Ordner und jeder Datei den vollen Pfad mit dem Präfix `/dav/` aus. Kodi und andere strikte Player haben dieses Präfix früher weggelassen und konnten dadurch keine Ordner oder Medien öffnen. Namen mit escapeten Zeichen und Pfade in Archiven behalten ihre Adressen.

## Ein stark ausgelasteter News-Server verursacht keine Lücken mehr in einem Stream {#a-busy-news-server-no-longer-puts-holes-in-a-stream}

Ein News-Server kann für einen Artikel, den er hat, „no such article“ antworten, während er gerade beschäftigt ist. zurg hat diese Antwort früher ein paar hundert Millisekunden später auf derselben Verbindung bestätigen lassen. Danach hat es den Abschnitt als Nullen ausgegeben und den Artikel einen Tag lang abgeschrieben. Ein einzelner Lesevorgang mit 32 MiB kam so mit 384,000 Null-Bytes zurück, obwohl der Server denselben Artikel eine Minute später korrekt geliefert hat.

Ein abgelehnter Artikel wird jetzt nach einer Sekunde noch einmal angefragt. Die zweite Anfrage geht über eine andere Verbindung, sofern eine frei ist. Der Lesevorgang wartet auf diese Antwort, statt die Lücke zu füllen. Ein Artikel, der wirklich weg ist, wird weiterhin als Stille ausgegeben und wie bisher repariert. Ein beschädigtes Release braucht dadurch etwa eine Sekunde länger, bis es bei dieser Stille ankommt.

Ein Artikel, dessen Verbindung still wird, wird jetzt ebenfalls einmal auf einer anderen Verbindung neu angefragt. Früher ist dadurch die ganze Antwort fehlgeschlagen. Ein RAR-Stream hat bei einem Artikel, den der Provider nur langsam geschickt hat, mit 500 geantwortet.

## Lege fest, wie sich zurg gegenüber den Diensten identifiziert, die es aufruft {#choose-how-zurg-identifies-itself-to-the-services-it-calls}

Anfragen an Debrid-Dienste und Indexer verwenden jetzt standardmäßig einen generischen Browser-User-Agent. Auch Untertitel-Abfragen nutzen ihn und senden nicht mehr `zurg v0`. Diese Anfragen entfernen außerdem Origin- und Referrer-Header sowie zurgs eigene Header. Das gilt auch bei Weiterleitungen. Eine Weiterleitung kann den privaten Pfad oder API-Schlüssel der vorherigen URL nicht mehr weitergeben.

`user_agent` setzt einen anderen Agent, und `omit_user_agent` sendet gar keinen. Die `outbound_*`-Schlüssel legen die Client- und Gerätenamen fest, die Plex, Jellyfin und Emby sehen. Alle diese Optionen findest du im Dashboard unter Network & Connectivity. Sie wirken erst nach einem Neustart. Usenet-Verbindungen senden überhaupt keine Software-Kennung. Das entfernt zurgs eigene Kennungen. Du bist dadurch aber nicht anonym.

Die Details stehen unter [Outbound-Identität](outbound-identity.md).

## zurg leert den Plex-Papierkorb standardmäßig {#zurg-empties-the-plex-trash-by-default}

zurg schaltet Plex' Option „Empty trash automatically after every scan" ab. Sonst löscht ein Scan, der auf einen kurzzeitig nicht lesbaren Mount trifft, die Bibliothek, statt sie zurückzustellen. Was dabei zurückblieb, fiel niemandem auf. Plex räumte tote Einträge nicht mehr auf, und zurgs eigene Entfernung war nur auf Wunsch aktiv. Standardmäßig räumte also nichts sie weg. Einträge, deren Dateien längst weg waren, sammelten sich an. Am auffälligsten war der Fall einer Datei, die zwischen Bibliotheksordnern verschoben wurde und deren alter Eintrag für immer blieb.

Wenn `plex_trash_sweep_every_mins` nicht gesetzt ist, läuft die Papierkorb-Bereinigung jetzt alle 60 Minuten. Sie pausiert, solange Plex seinen eigenen Papierkorb noch leert. Sie entfernt immer nur einen Eintrag auf einmal und nie einen, der noch eine Datei hat. Sie läuft nur gegen einen Mount, der lesbar ist. Was sie nicht beurteilen kann, bleibt zuerst 14 Tage lang als kaputt sichtbar. Schreib `plex_trash_sweep_every_mins: 0`, damit die Entfernung aus bleibt und du den Papierkorb selbst leerst.

Diese Einstellung gibt das Leeren des Papierkorbs nicht an Plex zurück. Dafür gibt es jetzt auf der Konfigurationsseite den Schalter Let Plex Empty Its Own Trash. Das Risiko, das er mit sich bringt, steht direkt daneben.

Auch das Wiederherstellen funktioniert jetzt. Plex überspringt einen normalen Scan eines Ordners, den es schon gescannt hat. Eine im Papierkorb gelandete Serie, deren Dateien alle wieder da waren, konnte Scan für Scan im Papierkorb bleiben. Die Bereinigung bittet Plex jetzt um einen erzwungenen Scan dieses Ordners. Ein Scan, den du von Hand im Dashboard startest, erreicht jetzt auch die `__magic__`-Pfade, aus denen eine Usenet-Bibliothek indiziert wird. Früher fand er keine Plex-Sektion und tat nichts.

Wie sich die beiden Sammler die Aufgabe teilen, steht unter [Plex](../guides/plex.md#who-empties-the-trash).

## Beschädigte Archive listen die richtigen Bytes oder gar nichts {#damaged-archives-list-the-right-bytes-or-nothing-at-all}

Einige beschädigte RAR-Sets haben ein Video aufgelistet, das falsche Bytes abgespielt hat. Ein Set, dem ein Teil aus der Mitte fehlte, hat den Rest der Datei verschoben ausgeliefert, mit einem Ende aus Nullen. So ein Set wird jetzt abgelehnt. Ein Set, dessen erster Header nicht gelesen werden konnte, hatte verschobene spätere Bytes. zurg liest jetzt zuerst die Fortsetzungs-Header, damit jeder Offset stimmt. Dateien nach dem Film im letzten Teil bleiben ebenfalls erhalten.

Ein RAR4-End-Marker wurde früher für eine Verschlüsselung gehalten. Geteilte Sets mit aufgefüllten End-Blöcken haben ihren ersten Teil verloren. Jetzt listen sie das vollständige Video.

Eine NZB, bei der 10 % oder mehr der Artikel fehlen, wird abgelehnt, bevor irgendetwas ausgeliefert wird. Inhalte, die PAR2 bereits wiederhergestellt hat, werden weiterhin abgespielt.

Bestehende Archiv-Listings werden neu aufgebaut, damit diese Korrekturen auch Releases erreichen, die schon in der Bibliothek sind.

## Große Bibliotheken können ungenutzten Speicher wieder freigeben {#large-libraries-can-give-idle-memory-back}

`library_detail` bestimmt, ob die Dateiliste jeder Veröffentlichung dauerhaft im Speicher bleibt. `resident` behält alle Listen im Speicher und ist weiterhin der Standard. `lazy` gibt Dateilisten frei, die seit `library_detail_idle_secs` niemand gelesen hat. Die Übersichten bleiben verfügbar, und eine Dateiliste wird von der Festplatte geladen, sobald etwas auf sie zugreift. `auto` macht dasselbe, aber nur bei anhaltendem Speicherdruck auf dem Host oder im Container. Große Staffel-Packs brauchen in beiden Modi deutlich weniger Speicher. Eine komprimierte Wiederherstellungskopie schützt eine Dateiliste, falls ihr Festplatten-Cache beschädigt ist. Ungespeicherte Änderungen werden nie freigegeben. Das Dashboard bietet alle drei Modi an. Eine Änderung erfordert einen Neustart.

Auch der Start braucht weniger Speicher, wenn der Real-Debrid-Download-Verlauf groß ist. Das Speichern und Laden dieses Verlaufs sowie der Bibliotheks-Caches erzeugt keine zusätzlichen Kopien mehr.

Die Abwägungen findest du in [der Konfigurationsreferenz](config.md#library-detail).

## Plex-Watchlist und Seerr-Anfragen teilen sich eine Warteschlange {#plex-watchlist-and-seerr-requests-share-one-queue}

Der `acquisition:`-Block schickt Plex-Watchlist-Einträge und Seerr-Anfragen in eine gemeinsame Warteschlange. Beide werden auf deinen Newznab-Indexern gesucht und landen im Usenet-Backend. Seerr-Anfragen werden erst verfolgt, wenn sie genehmigt sind. Es werden nur die angefragten Staffeln geholt. Eine 4K-Anfrage wird getrennt von einer 1080p-Anfrage behandelt. Offene Seerr-Anfragen werden auf neu ausgestrahlte Episoden geprüft.

Der Fortschritt bleibt jetzt bei einem Neustart erhalten. Das gilt für Wiederholungs-Fristen, Versuchszähler und die bereits fertigen Episoden. Eine unterbrochene Acquisition macht dort weiter, wo sie aufgehört hat. Eine bereits abgeschlossene versucht nur noch, den Eintrag von der Watchlist zu entfernen, und sucht nicht erneut. Der gespeicherte Zustand ist Teil der normalen Backups. Bestehende `watchlist:`-Einstellungen funktionieren unverändert weiter.

Die Einrichtung findest du unter [Acquisition](../guides/acquisition.md).

## Debrid-Bibliotheken können in portablen lokalen Dateien liegen {#debrid-libraries-can-live-in-portable-local-files}

Ein Debrid-Konto kann seine Bibliothek jetzt aus einem Ordner mit `.zurgtorrent`-Dateien beziehen, statt aus der eigenen Liste des Kontos. `zurg export-torrents` schreibt eine bestehende Bibliothek in solche Dateien. Sie beschreiben nur den Inhalt und enthalten keine Zugangsdaten oder Download-Links. Deshalb lässt sich eine Bibliothek teilen. Die Person, die sie bekommt, spielt über ihr eigenes Konto ab, und die Limits ihres Anbieters gelten weiterhin. Das Importieren, Auflisten und Aktualisieren der Dateien fügt dem Konto nichts hinzu.

Bestehende Konfigurationen funktionieren weiterhin. Neue Backups verwenden Format 2 und brauchen diesen Build oder einen neueren, um wiederhergestellt zu werden.

Export und Einrichtung sind unter [Lokale Bibliotheken](../guides/local-libraries.md) beschrieben.

## Lese-Caches überstehen einen Neustart {#read-caches-survive-a-restart}

zurg speichert seine Lese-Caches jetzt auf der Festplatte, auch über Neustarts hinweg. Dazu gehören geparste NZBs und dekodierte Usenet-Artikel. Außerdem gehören Archiv-Layouts, dekodierte Archivblöcke und Download-Links dazu. Nach einem Neustart muss zurg nicht mehr jede NZB parsen oder jeden Archiv-Header erneut lesen. Jeder Byte-Cache ist standardmäßig auf 512 MiB begrenzt. `zurg backup --include-caches` nimmt sie in ein Backup auf, damit ein Neustart aus dem Backup schnell wieder warm läuft.

Anfragen für dieselbe AllDebrid- oder TorBox-Datei, die im selben Moment eintreffen, teilen sich jetzt eine einzige Link-Abfrage.

Einstellungen und Grenzwerte stehen unter [Persistent caches](../internals/persistent-caches.md).

## Usenet-Downloads werden genauer geprüft, bevor sie Completed anzeigen {#usenet-grabs-are-checked-more-closely-before-they-read-completed}

Bevor ein Grab auf Completed springt, fragt zurg beim Newsserver die ersten sechzehn Artikel und den letzten Artikel jeder Inhaltsdatei ab. Früher wurde nur der erste geprüft, deshalb blieben Lücken im Medien-Header unentdeckt. Die Prüfungen laufen jetzt als ein Batch pro Datei, damit große Archive nicht mehr die Zeit ausgehen lassen.

Ein Release, dessen fehlende Artikel per PAR2 vollständig rekonstruiert wurden, wird jetzt importiert. Früher schlug der Import fehl, weil die Originalartikel auf dem Server immer noch fehlten. Eine nur teilweise Reparatur zählt weiterhin nicht.

`sabnzbd.history_limit` kann jetzt auf einen größeren History-Limit in Sonarr oder Radarr abgestimmt werden. Ein großer Rückstau abgeschlossener Jobs wird dann in größeren Batches abgearbeitet. Beide Seiten müssen dieselbe Zahl verwenden. Der Standardwert bleibt bei sechzig.

## `enforce` lässt die Plex-Funktionen, die du siehst, in Ruhe {#enforce-leaves-the-plex-features-you-can-see-alone}

`plex_settings_policy: enforce` schaltet beim Scrubbing keine Vorschaubilder und keine Kapitelbilder mehr ab. Auch Lautstärkeangleichung und Sonic-Analyse werden nicht mehr abgeschaltet. Jede davon dekodiert ganze Dateien, und das kostet auf einem Debrid-Mount Bandbreite. Gleichzeitig bekommst du bei jeder etwas zu sehen. Sie stehen jetzt, wie Skip Intro und Skip Credits, zur freien Wahl. zurg zeigt weiterhin an, was jede davon kostet. Es trifft die Entscheidung aber nicht mehr für dich. Die Bandbreiten-Gruppe enthält jetzt nur noch Analysen, deren Ausgabe niemand ansieht.

## Abgelaufene Debrid-Links werden repariert, ohne dass die Wiedergabe fehlschlägt {#expired-debrid-links-recover-without-failing-playback}

Ein TorBox-Link, dessen signierter Token veraltet ist, bekommt jetzt einen neuen. Leser, die auf dieselbe Datei warten, teilen sich diese eine Abfrage. Wiederholte Fehler pausieren die Wiedergabe, ohne die Datei als defekt zu markieren.

Wenn ein TorBox-, Real-Debrid- oder AllDebrid-Download-Server zurg bittet, zu warten, wartet zurg jetzt so lange, wie der Server es verlangt. Außerdem hört zurg auf, einen Server erneut anzufragen, der immer wieder ablehnt. Das gilt für die Wiedergabe, die Link-Prüfungen und das Lesen von Archiven. Auch ein widerrufener Link, der über `__downloads__` geöffnet wird, bekommt einen neuen.

## zurg aktualisiert sich selbst {#zurg-updates-itself}

`zurg update` ersetzt das laufende Binary durch den neuesten Sponsor-Nightly-Build. Dafür liest es den Release-Feed mit der Anmeldung der GitHub CLI, falls eine vorhanden ist, und sonst mit `GITHUB_TOKEN` oder `GH_TOKEN`. Bevor etwas ersetzt wird, prüft es, ob sich der Download ausführen lässt, und meldet die erwartete Version. Das Binary wird dann per Umbenennen ausgetauscht. So kann ein Update nicht fehlschlagen, während zurg läuft. Ein Build, der schon auf dem neuesten Nightly ist oder neuer ist, bleibt unverändert. In einem Container verweigert der Befehl das Update und verweist stattdessen auf den Image-Pull. Ein dort ersetztes Binary geht beim nächsten Neuerstellen des Containers verloren. Mit `--force` kannst du das überschreiben. Die Installer haben einen passenden `update`-Modus bekommen, für Builds, die den Befehl noch nicht mitbringen.

Je Plattform: [Linux](../setup/linux.md#updating-zurg), [macOS](../setup/macos.md#update-zurg), [Windows](../setup/windows.md#updating-zurg), [Docker](../setup/docker.md).

## Eine Plex-Einstellung kann von der Richtlinie ausgenommen werden {#one-plex-setting-can-be-opted-out-of-the-policy}

`plex_settings_ignore` nennt Plex-Einstellungen, die zurg unabhängig von `plex_settings_policy` in Ruhe lässt. Die Option ist für Setups gedacht, die eine davon wirklich brauchen: Eine Bibliothek, deren Dateien zwischen Ordnern verschoben werden, ist darauf angewiesen, dass Plex seinen eigenen Papierkorb leert, um den hinterlassenen Eintrag zu entfernen. Die Standard-Policy schaltet das aus. Auf `warn` zu wechseln, um es zurückzubekommen, würde aber auch die Schutzmechanismen für Dateisystem-Ereignisse daneben aufgeben. Eine ignorierte Einstellung wird weiterhin gelesen und weiterhin gemeldet, im Dashboard und als `skip` in `zurg plex-settings`. Sie wird nur nie geschrieben, nie gewarnt und nie vom Papierkorb-Banner begleitet. Eine Sicherheitseinstellung zu ignorieren geschieht auf eigene Verantwortung, und zurg weist beim Start einmal darauf hin. Eine ID, die nichts benennt, wird gemeldet, und die Einstellung bleibt geschützt. So kann ein Tippfehler nicht wie eine Abmeldung wirken.

Die Einstellungen selbst und was jede Policy-Stufe damit macht, stehen unter [Plex](../guides/plex.md#recommended-plex-settings).

## Einzeilige Installer für jeden unterstützten Host {#one-line-installers-for-every-supported-host}

Frische Installationen haben jetzt optionale Ein-Zeilen-Bootstraps für Linux, macOS, Windows und Docker auf Linux. Sie prüfen oder installieren die Voraussetzungen der Plattform, nutzen die Browser-Anmeldung von GitHub für den Sponsor-Zugang, laden die passende Architektur herunter und übergeben dann an `zurg setup` und `zurg doctor`. Vorhandene Binaries und Konfigurationen bleiben erhalten, und jede manuelle Anleitung bleibt verfügbar.

## Das Setup fragt, welche Anbieter konfiguriert werden sollen {#setup-asks-which-providers-to-configure}

Frische `zurg setup`-Installationen gehen nicht mehr davon aus, dass du Real-Debrid nutzt. Der interaktive Installer fragt dich nach einem oder mehreren Anbietern in Prioritätsreihenfolge und fragt nur die Zugangsdaten ab, die du ausgewählt hast. Nicht-interaktive Installationen können `--provider` mehrfach angeben und anbieterspezifische Token-Datei-Flags oder Umgebungsvariablen verwenden. Bestehende Konfigurationen bleiben weiterhin erhalten, und die alten Real-Debrid-Eingaben `--token-file`, `TOKEN` und `RD_TOKEN` funktionieren weiter, wenn du sie ausdrücklich angibst.

## Ein Schwall größer als Sonarrs Verlaufsfenster verliert keine Importe mehr {#a-burst-larger-than-sonarrs-history-window-no-longer-loses-imports}

Sonarr und Radarr fragen SABnzbd nach jedem Auftrag in der Warteschlange, aber nur nach den neuesten sechzig Einträgen im Verlauf. Das passt normalerweise gut zu einem echten Downloader: Fertige Downloads kommen nach und nach an, und der Client entfernt jeden nach dem Import. Eine gecachte NZB-Bibliothek ist anders. Eine Massensuche nach einer Staffel kann Hunderte einzelne Episoden-Aufträge fertigstellen, bevor der Client das nächste Mal abfragt. Früher hat zurg alle davon aus der Warteschlange entfernt, im Verlauf aber nur sechzig zurückgegeben. Jeder Auftrag über diese Seite hinaus fehlte in beiden Antworten. Deshalb hat der Client ihn nie importiert oder als fehlgeschlagen markiert, und sein Release blieb unbegrenzt in der Wurzel von `__magic__` liegen.

zurg behält fertige Aufträge jenseits dieser sichtbaren Seite jetzt in der Warteschlange. Sobald der Client die ersten sechzig importiert und entfernt, rücken die nächsten fertigen Aufträge in den Verlauf nach. Eine Staffel, die als einzelne Episoden geholt wurde, wird daher in begrenzten Paketen abgearbeitet, statt gegen ein Fenster fester Größe anzutreten. Ein Staffel-Pack verhält sich weiterhin wie ein einziger Auftrag.

## Ein Löschvorgang über den Mount funktioniert immer, und `dav_allow_delete` ist entfallen {#a-delete-through-the-mount-always-works-and-dav_allow_delete-is-gone}

Wenn du eine Datei über den Mount von einem Medienserver aus löschst, passierte früher nichts Sichtbares. zurg hat das WebDAV-DELETE mit einem 403 abgelehnt, rclone hat daraus einen I/O-Fehler gemacht, und der Client meldete einen Fehler ohne Ursache. Plex antwortet nur mit einem einfachen `400 Bad Request` und schreibt nichts ins Log. Der Button hat also einfach nicht funktioniert, und niemand hat gesagt, warum. Der Schlüssel, der das erlaubt hat, `dav_allow_delete`, ist entfernt. Ein DELETE über den Mount wird jetzt überall akzeptiert, ganz ohne Konfiguration. Eine Config-Datei, die den Schlüssel noch setzt, ist kein Fehler, unbekannte Schlüssel werden einfach ignoriert. Er hat nur keine Wirkung mehr.

Was der Schlüssel abgesichert hat, ist aber nicht verschwunden, deshalb sollte man es klar aussprechen: rclone kennt kein "überschreiben". Eine geänderte Datei wird als DELETE gefolgt von PUT geschrieben. Das heißt, ein Programm, das eine Datei an Ort und Stelle umschreibt, etwa ein `.nfo`-Writer, ein Trickplay-Durchlauf, ein Umbenennen durch Sonarr, Radarr & Co. oder ein versehentliches `touch`, löscht das Release aus deinem Debrid-Konto, statt eine Datei zu ersetzen. Der Mount nutzt die eigenen Zugangsdaten von rclone, deshalb kann von außen niemand unterscheiden, ob das ein gewolltes Löschen war. Der PUT-Teil wird weiterhin abgelehnt, und genau das verhindert, dass die Abfolge still abgeschlossen wird. Schreibt irgendetwas in deinen Mount, setz `mount_read_only: true`. Dann schlägt der Schreibvorgang schon im Kernel fehl, bevor er überhaupt bei zurg ankommt.

## Die Plex-Watchlist holt Inhalte über deine Newznab-Indexer {#the-plex-watchlist-acquires-through-your-newznab-indexers}

Der Watchlist-Monitor funktioniert jetzt, und er arbeitet mit deinen eigenen Indexern. Die alte Version suchte über einen DMM-API-Schlüssel und hörte stillschweigend auf zu funktionieren, als Plex die Watchlist auf seinen Discover-Host verschob, weil der abgefragte Endpunkt plötzlich mit 404 antwortete. Jetzt fragt er den richtigen Host ab, und jedes neue Watchlist-Element wird auf den Newznab-Indexern gesucht, die du bereits konfiguriert hast. Ein Film wird zur besten passenden Veröffentlichung. Eine Serie wird Staffel für Staffel geholt, wobei **Season-Packs** gegenüber einzelnen Episoden bevorzugt werden. Für eine Staffel, zu der niemand ein Pack gepostet hat, greift er auf die einzelnen Episoden zurück, jeweils mit der besten Veröffentlichung pro Episode. Und wenn der NZB-Link einer ausgewählten Veröffentlichung nicht geladen werden kann (etwa ein 429 wegen des Burst-Limits eines Indexers), rutscht er zum nächstplatzierten Kandidaten weiter, statt dass das Element dabei verloren geht.

Die gewählte NZB landet im Usenet-Backend nach denselben Benennungsregeln wie der SABnzbd-Endpunkt und das Stremio-Addon. So finden sich die drei Schnittstellen gegenseitig und laden nichts doppelt. Ein Element verschwindet erst dann von der Watchlist, wenn tatsächlich etwas heruntergeladen wurde. Bisher wurde zuerst entfernt und erst danach nachgefragt, sodass jeder Fehler das Element stillschweigend von deiner Liste geworfen hat.

Konfigurieren lässt sich das über den neuen `watchlist:`-Block: `enabled`, `check_every_secs` (Standard 60), `indexers` (leer übernimmt `stremio.indexers`), `max_size_gb` (Standard 40, für Filme und einzelne Episoden), `max_season_size_gb` (Standard 100, für Season-Packs) und `quality` (`best`, `4k`, `1080p`, `720p`, `smallest`). Die alten `plex_watchlist_*`-Schlüssel behalten ihre Bedeutung. Ein `plex_token` reicht für Plex vollkommen aus. Der Monitor spricht mit Plex' Cloud-Dienst, deshalb läuft er auch auf einer Instanz ohne `plex_server_url` problemlos. TV-Suchen beginnen mit der TVDB-ID und versuchen es einmal erneut mit der IMDb-ID, wenn das nichts findet. Indexer ordnen Serien nach TVDB, und ihre IMDb-Zuordnung auf Serienebene ist so lückenhaft, dass eine stark indexierte Serie bei einer imdbid-Suche null Treffer liefern kann.

Jeder Schlüssel steht auf der Konfigurationsseite unter **Plex Watchlist** und in [der Konfigurationsreferenz](config.md#watchlist).

## Ein Stremio-Addon über deine Newznab-Indexer {#a-stremio-addon-over-your-newznab-indexers}

zurg kann jetzt direkt auf Stremio antworten. Aktiviere den `stremio:`-Block, trage deine Newznab-Indexer ein und füge die geloggte `/stremio/<token>/manifest.json`-URL in Stremio ein. Der Client fragt dann Streams über die IMDb-ID an, und zurg durchsucht die Indexer: Filme mit `t=movie`, Episoden mit `t=tvsearch` samt Staffel und Episode. Die Ergebnisse kommen nach Auflösung sortiert zurück, die beste zuerst, als abspielbare Streams. Wenn du einen auswählst, wird die NZB ans Usenet-Backend übergeben. Dabei gelten dieselben Benennungsregeln wie beim SABnzbd-Endpunkt. Ein Release, das zweimal geholt wird, wird deshalb wiedergefunden und nicht doppelt angelegt. Abgespielt wird über den signierten `/strm/e/`-Endpunkt, inklusive Range-Anfragen, Failover und Archiv-Inhalten. Alles, was du abspielst, landet in der Bibliothek und taucht in Plex wie jedes andere Release auf.

Das Token im Pfad ist die gesamte Autorisierung. Es wird erzeugt und in `data/stremio-token` gespeichert, wenn die Konfiguration keines vorgibt. Suchergebnisse werden in `data/stremio-cache` zwischengespeichert, damit das erneute Öffnen eines Titels keine Indexer-Anfragen kostet. Die Lebensdauer richtet sich nach der Anzahl der Treffer: eine Stunde pro Ergebnis bis zu vier, ab fünf gilt `stremio.cache_hours` (Standard 24). Eine leere Antwort wird nie gecacht. Eine gecachte Stream-Liste enthält außerdem einen Aktualisierungseintrag, der den Cache für diesen Titel leert. Releases, die größer als `stremio.max_size_gb` sind (Standard 40), werden aus der Liste entfernt. So verdrängt ein Full-Disc-Remux nicht jede abspielbare Option.

Alles, inklusive der Kosten für das erste Abspielen, steht in [Das Stremio-Addon](../guides/stremio.md).

## Ein Ordner ist die komplette Docker-Installation, und er wird beim ersten Start eingebunden {#one-folder-is-the-whole-docker-install-and-it-mounts-on-the-first-run}

Bisher startete man zurg in Docker laut Doku mit einem einzigen `docker run` und einem `TOKEN`. Das Ergebnis war ein Container, der nichts einband. Die generierte Config ließ `rclone_enabled` aus und `mount_path` ungesetzt, also blieb `/zurg_mnt/zurg` leer, bis jemand die beiden Schalter im Dashboard fand. Und diese Config wurde im Container geschrieben, also verwarf der nächste `docker pull` die Antwort zusammen mit dem Library-Cache. Der Schnellstart brauchte eine Fußnote mit beiden Punkten, und das heißt: ein Schnellstart, der zugibt, dass er nicht funktioniert.

`MOUNT_PATH` belegt jetzt beim Lauf, der die Config erstellt, `rclone_enabled: true` und `mount_path` vor, neben dem, was `TOKEN` schon vorbelegt hat. Das Arbeitsverzeichnis des Images ist `/config`, und alles, was zurg speichert, bezieht sich darauf: `config.yml`, `data/`, `logs/`, `dump/`, `strm/`, `nzbs/` und der rclone-Cache. Damit hält ein einziges `-v ~/zurg:/config` die komplette Installation, und ein Image-Update verschiebt davon nichts. Ein erster Start ist ein einziger Befehl und endet mit eingebundener Bibliothek, statt mit einem Gang ins Dashboard.

Beide Variablen werden **nur gelesen, solange noch keine Config-Datei existiert**, und danach immer ignoriert. Das ist dieselbe Regel, die `log_level` schon gegenüber `LOG_LEVEL` hat, aus demselben Grund: Ein `MOUNT_PATH`, das in einer Compose-Datei übrig geblieben ist, darf niemals stillschweigend einen später im Dashboard geänderten Mount-Pfad rückgängig machen. Beim Start warnt zurg jetzt, wenn eine der Variablen gesetzt ist und der Config widerspricht. So erfährt, wer neu deployt und keine Wirkung sieht, warum.

Installationen im alten Layout bleiben unangetastet. Docker legt das Ziel jedes Bind-Mounts selbst an. Wenn also `/app/config.yml`, `/app/data` oder `/app/logs` existieren, meldet sich damit das alte Layout, und der Container verwendet weiterhin `/app`, sobald er eines davon findet. Das komplette Setup und alles, was einen vom Host sichtbaren Mount kaputt macht, steht in [Docker](../setup/docker.md).

## TorBox und AllDebrid bekommen die `.torrent`-Datei ebenfalls, damit ein privater Download nicht hängen bleibt {#torbox-and-alldebrid-are-handed-the-torrent-too-so-a-private-grab-is-not-left-hanging}

Die `.torrent`-Datei, die ein \*arr mitschickt, wird seit dem letzten Release beim Hinzufügen übertragen, aber nur Real-Debrid konnte eine solche Datei annehmen. Die beiden anderen Accounts bekamen weiterhin nur den Info-Hash, und bei dem Release eines privaten Trackers ist das genau die eine Form, mit der sie nichts anfangen können. Es gab keinen Fehler, und genau das machte es schwer zu sehen: Beim Test mit dem echten TorBox-Account wurde ein Hash ohne öffentlichen Swarm zwar akzeptiert und bekam eine Torrent-ID, blieb danach aber im Status `checking` hängen, mit `size: -1`, ohne Dateiliste und mit einer Schätzung von hundert Tagen. Genau so wurde auch ein TorrentLeech-Download gemeldet, der „einfach hängt, es lädt nichts“. Die Datei desselben Releases wurde sofort mit echtem Namen, echter Größe und Dateiliste beantwortet, und der qBittorrent-Endpunkt konnte die Arbeit fortsetzen.

Beide Accounts nehmen die Datei jetzt an. TorBox' `createtorrent` und AllDebrids `magnet/upload/file` akzeptieren sie anstelle des Magnet-Links und antworten in der gleichen Form, die der Magnet-Add schon hatte. Daher ändert sich nichts nach dem Hinzufügen. AllDebrid meldet weiterhin beim Upload selbst, ob es den Inhalt schon hatte, das ist die einzige Cache-Antwort, die dieser Account überhaupt gibt. Live überprüft über den eigenen Add-Pfad von zurg, bei beiden: Ein gecachtes Release wurde hochgeladen und wenige Sekunden später mit `done`, 100 % und seiner Dateiliste ausgelesen. Eines, das niemand besitzt, wurde mit Namen und Größe zurückgegeben und stand still, weil Peers fehlen. Das ist ein Zustand, auf den der Endpunkt reagieren kann. Beim Hash war es ein Torrent, der nie aufgelöst wurde und nie fertig wurde.

Eine Ablehnung ist jetzt außerdem verständlich. Ein TorBox-Aufruf, den TorBox mit einem 4xx ablehnte, kam beim Aufrufer nur als pauschales „unexpected status code: 400“ des gemeinsam genutzten HTTP-Clients an. Der Antwortkörper, in dem TorBox den eigenen Fehlercode und die Details ablegt, wurde zugunsten dieses Fehlers verworfen. Eine `.torrent`-Datei, die TorBox nicht verarbeitet, wurde dem \*arr deshalb nur als Statusnummer gemeldet und sonst nichts. Der Body wird jetzt zuerst gelesen, und der Grund des Accounts kommt zusammen mit der Ablehnung an.

Was das für die Einrichtung der Indexer bedeutet: [Sonarr & Radarr, Torrents](../guides/sonarr-radarr-torrents.md).

## Komprimierte Archiveinträge werden gestreamt und bei Bedarf dekodiert {#compressed-archive-entries-stream-decoded-on-demand}

Eine komprimierte RAR- oder Deflate-ZIP-Datei kann eine Range-Anfrage nicht so beantworten wie eine gespeicherte. Ihre Bytes existieren nur hinter einem Decoder, der vom Anfang der Datei an laufen muss. Deshalb hat zurg sie abgelehnt: Ein Release, das nur komprimierte Dateien enthält, hat mit 415 geantwortet, und komprimierte Geschwister gespeicherter Dateien wurden übersprungen. Für einen Streamer war das die ehrliche Antwort, aber sie hat den Großteil des älteren Usenet-Katalogs versteckt: jeden Poster, der mit Kompression gepackt hat, komplett und ganz.

Diese Dateien werden jetzt bei Bedarf durch Vorwärtsdekodierung in ein begrenztes In-Memory-Fenster ausgeliefert. Nichts wird auf die Festplatte geschrieben, und nichts wird dekodiert, wonach kein Lesezugriff gefragt hat. Sequenzielle Wiedergabe, also das Muster, das ein Player erzeugt, landet an der Kante des Fensters und schiebt es bei jedem Lesezugriff ein Stück weiter. Ein Sprung rückwärts über das hinaus, was das Fenster behalten hat, startet die Dekodierung vom Anfang der Datei neu. Die gesamten Bytes der Datei sind genau das, was unrar extrahieren würde: Die drei jpg-Dateien eines echten komprimierten RAR4-Volumes werden Byte für Byte identisch dekodiert, verglichen mit demselben Fixture, das ein unabhängiger Decoder-Durchlauf liest, md5 für md5.

Um die Volumes eines geteilten Sets abzulaufen, brauchte rardecode seine Volume-Kette, die `.part02.rar` vom Dateisystem öffnet. zurgs Volumes liegen aber hinter Range-Netzwerk-Readern. Der Decoder ist jetzt unter `internal/rardecode` eingebunden (vendored, MIT, Upstream v1.1.3) und hat eine Änderung: `OpenReaderOver` nimmt einen Opener entgegen, sodass jedes nächste Volume aus dem Set kommt, und zwar unter dem Namen, den das Archiv selbst ableitet. Die Listings ändern sich entsprechend. Ein Release, das nur komprimierte Dateien enthält, zeigt jetzt seine Nutzdaten (`stream_compressed_archives: false` stellt die alten Ablehnungen wieder her), und ein gemischtes Archiv listet seine komprimierten Geschwister neben seinen gespeicherten. Listing-Version 15.

## Sonarr und Radarr können Torrents holen, und Prowlarr kann sie übermitteln {#sonarr-and-radarr-can-grab-torrents-and-prowlarr-can-push-them}

zurg kann den \*arrs antworten, als wäre es ein qBittorrent. Sie übergeben ihm einen Magnet-Link oder eine `.torrent`-Datei, zurg fügt den Info-Hash bei einem Debrid-Konto hinzu (Real-Debrid, TorBox oder AllDebrid, je nachdem, was konfiguriert ist). Sobald das Release in der Bibliothek liegt, meldet der Torrent sich als abgeschlossen, mit einem Ordner unter `__magic__`, aus dem importiert werden kann. Der Import ist dasselbe Umbenennen, das der SABnzbd-Endpunkt schon immer für Usenet-Grabs gemacht hat: eine Zeile in der Tabelle `__magic__`, es werden keine Daten verschoben.

Der Endpunkt wird unter `/api/v2` und `/qbittorrent/api/v2` registriert. Er ist ausgeschaltet, bis man ihn aktiviert, und durch einen API-Schlüssel geschützt, den die Clients als Bearer-Token senden. Ein Grab wird jedem Konto angeboten, das Torrents annimmt, und zwar in der Reihenfolge von `providers:`. Bleibt ein Grab stehen (keine Statusänderung, kein Anstieg beim Fortschritt, und das für `qbittorrent.download_timeout_mins` Minuten, standardmäßig fünfzehn), wird es von diesem Konto entfernt und beim nächsten versucht. `0` nimmt nur Inhalte an, die ein Konto bereits gecacht hat, und lehnt alle anderen schon beim Hinzufügen ab. Das ist die einzige Ablehnung, auf die die \*arrs reagieren. Was das Konto mit einem Download gerade macht, wird auf die Zustände abgebildet, die die Clients verstehen, mit Geschwindigkeit, Swarm und verbleibender Zeit, sofern das Konto diese Werte meldet.

Eine ehrliche Einschränkung: Die qBittorrent-API kann nicht sagen, dass ein Download fehlgeschlagen ist. Deshalb erreicht ein Release, das kein Konto annehmen will, den Client als Warnung und nicht als Eintrag auf der Blockliste. Es ist in der Warteschlange sichtbar, mit dem Grund dabei, wird aber nie automatisch erneut gegrabbt. Der SABnzbd-Endpunkt hat dieses Problem nicht.

Prowlarr spricht mit demselben Endpunkt, so wie ein Download-Client es für Prowlarr tun würde: Ein Release wird von Hand an das Konto geschickt. Bei einem Prowlarr-Push wird nichts importiert. Dafür sind die \*arrs da.

Vollständige Anleitung, an einer laufenden Installation aufgenommen: [Sonarr & Radarr, Torrents](../guides/sonarr-radarr-torrents.md).

## `__magic__`, ein Verzeichnis, das du organisieren kannst {#__magic__-a-directory-you-can-organise}

Jeder Ordner, den zurg ausliefert, ist ein gespeicherter Filter. Ein Release liegt in `movies`, weil es zum Filter movies passt, und es liegt gleichzeitig in `__all__`, in `recent` und in `movies`. Deshalb gab es in der Library bisher nie einen Ort, an den man etwas *legen* konnte. Das ist so lange in Ordnung, bis ein Programm eine Datei verschieben will. Radarr und Sonarr importieren, indem sie verschieben. Ein Mount, der kein Verschieben annehmen kann, zwingt sie zum Kopieren: Bei jedem Import wird das ganze Release vom Debrid-Host oder von Usenet heruntergeladen, und genau das soll der Mount eigentlich vermeiden.

`__magic__` ist ein neues Top-Level-Verzeichnis. Es startet als exakte Kopie von `__all__`, also jedes Release als Ordner mit genau dem Inhalt von `__all__/<release>/`, inklusive der Inhalte eines virtualisierten Archivs. Darin kann man alles überall hin verschieben. `mkdir -p /mnt/zurg/__magic__/tv/Show/Season 01` und dann eine Episode mit `mv` hineinschieben, und die Episode ist dort: Es werden keine Bytes verschoben, kein Torrent umbenannt, nichts neu heruntergeladen, und `__all__` bleibt unverändert. Ein Verschieben schreibt eine einzelne Zeile in eine kleine Tabelle. Diese Tabelle nutzt als Schlüssel den Content-Hash des Releases und den eigenen Pfad der Datei darin. So verliert eine Reparatur, die das Release neu hinzufügt und alle IDs drumherum neu aufbaut, nicht, wohin du etwas gelegt hast. Gleiches gilt, wenn du ein Release im Dashboard umbenennst.

Verschieben funktioniert in beide Richtungen. Eine Datei lässt sich *in* einen Release-Ordner verschieben und auch wieder heraus. Der Ordner zeigt die Datei dann neben den eigenen Einträgen des Releases an. Genau das braucht ein Programm, das etwas in den Ordner zurücklegt, aus dem es importiert. Wenn ein Name aus zwei Quellen gleichzeitig kommt, gewinnt die bewusste Platzierung: Was du verschoben hast, schlägt das, wie das Release diesen Namen nennt, und das wiederum schlägt eine Datei in `data/local`. Der Verlierer wird nicht doppelt aufgelistet, sondern gar nicht.

Löschen ist die andere Hälfte, und standardmäßig wird ausgeblendet statt zerstört. Ein `rm` innerhalb von `__magic__` entfernt den Eintrag aus `__magic__`, lässt ihn aber in `__all__` und in jedem Filterverzeichnis stehen. So kann ein Client, der eine Library umorganisiert, nichts davon verlieren. Auch ein Release-Ordner kann auf dieselbe Weise verschwinden. Damit kann Sonarr den Job-Ordner nach einem Import löschen, ohne das Release anzufassen, aus dem es gerade importiert hat. Mit `magic.allow_delete: true` schaltest du bei Dateien die stärkere Bedeutung ein, bei der auch der Inhalt gelöscht wird. Ein Release-Ordner und ein Verzeichnis werden dagegen immer nur ausgeblendet, egal welchen Wert diese Einstellung hat.

Die Funktion ist standardmäßig ausgeschaltet, weil es ein beschreibbarer Baum ist. Ein \*arr, der auf das falsche Root-Verzeichnis zeigt, kann eine Library umorganisieren:

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

Die beiden `sidecar_`-Schlüssel sind für Clients gedacht, die `/dav` direkt mounten und nicht über den eigenen Mount von zurg. Diese Clients schicken zurg ein `PUT` für eine neue `.nfo`, ein Poster oder eine Untertitelspur. zurg schreibt den Body dann nach `data/local/__magic__/…`, also in denselben Baum, in den auch der eigene Mount von zurg solche Dateien schreibt. So zeigen beide Sichten ein Verzeichnis statt zwei. Die Datei lässt sich danach mit Ranges, Länge und Änderungszeit lesen, wie jede andere Datei. Die Obergrenzen verhindern, dass daraus still ein allgemeiner Dateispeicher wird: Eine Datei über `sidecar_max_mb` wird mit 413 abgelehnt, und eine, die den Baum über `sidecar_budget_mb` bringen würde, mit 507. Nichts, was die Library beantwortet, kann überschrieben werden. Ein Release-Ordner, ein Eintrag darin oder ein Pfad, an den etwas verschoben wurde, ergibt jeweils ein 403. Ein Verschieben zerstört außerdem nie eine echte Datei, nur um Platz für eine Zeile zu machen.

Zwei Dinge solltest du wissen, bevor du etwas darauf richtest. Die Filterverzeichnisse bleiben bewusst unangetastet. Ein Release, das innerhalb von `__magic__` verschoben wurde, steht also weiterhin unter seinem eigenen Namen in `recent` und `movies`. Richte einen Medienserver entweder auf `__magic__` **oder** auf die Filter, nicht auf beide. Außerdem war der Mount schon immer in eine Richtung beschreibbar: Alles wirklich Neue, das hineingeschrieben wird, also eine `.nfo`, ein Untertitel oder ein Poster, landet in `data/local` von zurg selbst und wird in die Auflistung eingemischt. Deshalb funktionieren Sidecars neben einem Release einfach, und der Schreibtest des Root-Verzeichnisses eines \*arr besteht.

`dav_allow_rename` und `dav_allow_delete` haben mit alldem nichts zu tun. Sie schützen den Pfad, der umbenennt und löscht, was das Debrid-Konto hält. Ein Schreibvorgang unter `__magic__` erreicht kein Konto. `mount_read_only: true` setzt weiterhin alles außer Kraft.

Das Dashboard hat dafür eine Seite unter `/magic/`. Sie zeigt jede Zeile der Tabelle, gruppiert nach Release. Dazu kommt, was jede Zeile ist, aus welcher Datei welches Releases sie stammt und von wo diese Datei jetzt ausgeliefert wird. Außerdem zeigt sie, wie viele Zeilen es gibt, wie viel Platz Journal und Snapshot auf der Festplatte belegen und wie viel von `sidecar_budget_mb` die echten Dateien neben der Library nutzen. Sie meldet auch die Größe des gesamten `data/local`. Diese Zahl verrät, ob etwas per Kopieren importiert wird: Ein Client, der statt zu verschieben kopiert, legt die Bytes dort ab, und sonst würde das Dashboard das nirgends zeigen.

Drei der Zustände, die es anzeigt, lassen sich von einem Client aus gar nicht erreichen. Eine Platzierung kann **reset** werden, dann geht die Datei dorthin zurück, wohin die Library sie legt. Ein Tombstone kann **unhidden** werden, dann wird der Eintrag wieder aufgelistet. Und eine **dangling**-Zeile, deren Release oder deren Datei darin die Library nicht mehr hat, lässt sich einzeln oder auf einmal verwerfen. Das ist neu: Eine solche Zeile löst auf nichts auf, also kann kein Client sie auflisten, verschieben oder löschen. Sie wird bewusst behalten statt verworfen, weil eine Reparatur, die das Release zurückbringt, auch die Platzierung wieder zurückbringt. Bisher gab es keinen Ort, an dem man so etwas aufräumen konnte.

Auch Sidecars werden aufgelistet, mit derselben Einordnung. Eine echte Datei in einem Ordner, den nichts mehr zuordnet, also eine `.nfo` neben einem Release, das die Library verlassen hat, oder innerhalb einer Platzierung, die vergessen wurde, wird als **orphaned** angezeigt und getrennt vom Rest gezählt. Nichts wird automatisch aufgeräumt, aus demselben Grund wie bei einer dangling-Zeile: Die Datei gehört immer noch dir, und eine Reparatur, die das Release zurückbringt, ordnet den Ordner wieder zu. Eine Datei dort zu löschen entfernt die Datei wirklich, genau wie ein `DELETE` über den Mount. Jeder dieser Buttons sagt dem Mount außerdem, dass er die Auflistungen vergessen soll, die er geändert hat. Er cacht ein Verzeichnis zwölf Stunden lang, wenn Polling ausgeschaltet ist.

`magic:` und `sabnzbd:` lassen sich jetzt auf der Konfigurationsseite bearbeiten. Beide sind mit **Restart Required** markiert, und das ist ernst gemeint. Die Routen, die `__magic__` ausliefern, und der SABnzbd-Endpunkt werden beim Start einmalig aus genau diesen Werten festgelegt. Wenn du eines davon einschaltest, wird es in `config.yml` gespeichert, ändert aber nichts am laufenden Betrieb, der gerade antwortet. Die `__magic__`-Seite sagt das auch ausdrücklich, statt einen leeren Namespace so darzustellen, als wäre alles in Ordnung.

### Sonarr und Radarr können zurg jetzt eine NZB übergeben {#sonarr-and-radarr-can-now-hand-zurg-an-nzb}

Der Grund, warum `__magic__` existiert, ist, dass ein \*arr dort etwas zum Importieren hat. zurg spricht jetzt die andere Hälfte davon: einen Endpunkt unter `/api`, der Sonarr und Radarr antwortet, als wäre er ein SABnzbd. Trag Host und Port von zurg ein, füg den API-Schlüssel ein, und Grabs landen in `nzbs/` für das Usenet-Backend. Sobald das Release in der Bibliothek ist, meldet der Job Completed mit einem Ordner unter `__magic__`. Der Import ist dann nur ein Umbenennen innerhalb des Mounts: eine Zeile in der Tabelle, keine Bytes gelesen, nichts von Usenet heruntergeladen, um es in einen Serienordner zu legen.

```yaml
sabnzbd:
  enabled: true
  api_key: ""          # left empty, zurg generates one and logs it once
  categories: [tv, movies]
  complete_dir: ""     # defaults to <mount_path>/__magic__; set it to what a containerised *arr sees
```

Standardmäßig ist das ausgeschaltet, und es braucht beide Teile, um nützlich zu sein: einen `nzb`-Provider, um die NZB zu lesen, und `magic.enabled`, damit es einen Ort gibt, von dem importiert werden kann. Der Endpunkt ist nicht durch Basic-Auth von zurg geschützt. Keiner der beiden \*arr sendet jemals Zugangsdaten an einen Download-Client, und ihre HTTP-Schicht liest eine 401 als "unable to connect". Der API-Schlüssel ist also das ganze Tor, behandle diesen Port entsprechend. Root-Ordner liegen **innerhalb** von `__magic__` (`__magic__/tv`, `__magic__/movies`), nie auf oder über ihm, sonst hat die Root-Ordner-Gesundheitsprüfung der Clients etwas zu bemängeln.

Eine Sache solltest du wissen, bevor du eine Bibliothek umstellst: **das Fehlersignal ist unvollständig**. Ein Release, das die Bibliothek zwar hat, in dem aber nichts Importierbares steckt, wird als `Failed` gemeldet. Das gilt, wenn jede Datei kaputt, gelöscht oder herausgefiltert ist, oder wenn nur Reparatur-Gerüst und Begleitdateien übrig sind, was bei einer NZB mit nur Recovery-Volumes genau der Fall ist. Dieses Failed bringt beide Clients dazu, das Release auf die Blockliste zu setzen und eine Alternative zu holen. Ein RAR-Set zählt als Inhalt, weil zurg das Video direkt daraus streamt. Ausnahme ist ein Set, das zurg überhaupt nicht streamen kann, weil es nur komprimierte Einträge enthält. Das wird als Failed gemeldet, sobald etwas es geöffnet und das festgestellt hat. Dieses Urteil wird beim Release gespeichert, denn es herauszufinden kostet ein Lesen jedes Volumes im Set.

Nicht gemeldet wird ein Post, dessen Artikel vom News-Server verschwunden sind. zurg prüft das noch nicht. Ein totes Release wird deshalb wie jedes andere als Completed gemeldet und schlägt erst beim ersten Lesen fehl. Sonarr sieht dann einen Importfehler statt eines Download-Fehlers. Das ist im Moment noch eine manuelle Entscheidung. Alles andere im Ablauf funktioniert, auch die Bereinigung nach dem Import: Der Job-Ordner, den Sonarr löscht, wird zum Tombstone, und das Release bleibt in `__all__`.

Ein Grab wartet nicht auf den nächsten Änderungs-Poll. zurg liest das Watch-Verzeichnis neu, sobald es etwas hineingeschrieben hat. Das gilt aber nur für die Usenet-Konten. Ein Staffel-Paket besteht aus zwanzig Grabs in wenigen Sekunden, und eine Debrid-Bibliothek mit Zehntausenden Torrents nur neu aufzulisten, um eine lokale Datei zu bemerken, wäre zwanzigmal die falsche Arbeit. Ist gar kein `nzb`-Provider konfiguriert, sagt zurg das jetzt beim Start. Es nimmt keine Grabs an, die niemand je lesen wird.

Die Seite `__magic__` listet die Jobs nur lesend auf: die `nzo_id`, unter der jeder Client einen Grab kennt, seine Kategorie, wann er eingetroffen ist, ob die Bibliothek das Release schon listet und, sobald sie es tut, den Ordner, aus dem der \*arr importiert.

Die vollständige Einrichtung steht in `docs/sabnzbd.md`. Dort findest du auch das Remote-Pfad-Mapping für containerisierte \*arr und was jeder Fehler beim Verbindungstest bedeutet.

## Der Mount nutzt mehr von der verfügbaren Bandbreite {#the-mount-reaches-more-of-the-bandwidth-it-has}

Beim Lesen einer Datei über den rclone-Mount ging es langsamer als beim Abrufen derselben Bytes über HTTP. Der Grund war, wie ein Lesevorgang startet, nicht wie er läuft.

Der erste Chunk wurde mit 4 MB angefordert und danach immer verdoppelt. Ein Lesevorgang, der an einer kalten Position begann, blieb deshalb die meiste Zeit deutlich unter der Geschwindigkeit, die die Verbindung eigentlich schaffen würde. Und jeder Seek startet einen neuen Lesevorgang. Der erste Chunk wird jetzt mit 32 MB angefordert.

Gemessen auf einem Host mit etwa 70 MB/s nutzbarer Download-Bandbreite. Jede Einstellung wurde abwechselnd getestet, damit eine langsame Minute nicht nur eine davon trifft. Der Median des Mount-Durchsatzes bei Real-Debrid stieg von 49 auf 57 MB/s, bei TorBox war es ähnlich. AllDebrid profitiert hier weniger, weil das Limit pro Verbindung gilt und nicht pro Konto.

Die Chunk-Größe ist der ganze Effekt. Das FUSE-Read-Ahead wurde beim Testen parallel mit erhöht und hat nichts verändert. Es kostet auch keine zusätzliche Bandbreite: Die Chunk-Größe ist, wie viel *angefragt* wird, nicht wie viel tatsächlich übertragen wird, und rclone hört auf zu laden, sobald die Wiedergabe stoppt. Ein 4-MB-Lesevorgang hat trotzdem 6 MB geladen, genauso wie ohne Read-Ahead. Eine Bibliothek, die nur durchstöbert und stichprobenartig angesehen statt komplett geschaut wird, lädt also nicht mehr als vorher.

Du musst nichts ändern. Der neue Wert ist jetzt der Standard, und `rclone_extra_args` überschreibt ihn weiterhin.

## `zurg benchmark-my-setup` zeigt, wie schnell dein Setup wirklich ist {#zurg-benchmark-my-setup-answers-how-fast-the-setup-actually-is}

Bisher blieb nur das Raten, ob ein langsamer Stream am Account, am Host oder am Mount liegt. Der neue Befehl liest echte Bytes über denselben Pfad, den ein Player nutzt, und gibt die Verteilung aus: Minimum, Median, Durchschnitt, Maximum und Time to First Byte. So hängt das Ergebnis nicht an einem einzelnen Messwert, den ein unglücklicher Ausreißer erzeugt haben könnte.

Er läuft in drei Phasen. Zuerst jeder Account für sich allein. Das ist die Zahl, die du mit dem vergleichst, was der Dienst verspricht. Dann alle konfigurierten Accounts gleichzeitig. Nur diese Phase kann einen langsamen Anbieter von einer ausgelasteten Leitung unterscheiden: Accounts, die jeder für sich allein 70 MiB/s schaffen, gleichzeitig aber nur 25 MiB/s, sind ein Engpass und keine drei Probleme. Der Bericht sagt dir, welcher der beiden Fälle vorliegt. Dann folgt dasselbe Lesen über den rclone-Mount. Der Unterschied zur ersten Phase zeigt, was FUSE und der VFS kosten. Die Mount-Phase wird übersprungen, wenn `rclone_enabled` ausgeschaltet ist.

Die Samples liegen an zufälligen Offsets, und das ist kein Detail. Jede Schicht darunter cached: rclones VFS behält, was es schon geladen hat, und ein Debrid-CDN-Edge behält, was es schon ausgeliefert hat. Liest du denselben Offset noch einmal, misst du also diese Caches statt der Leitung. Auf einem Live-Setup hat dieselbe Datei kalt 47 MiB/s gemeldet und beim zweiten Lesen derselben Region 285 MiB/s.

Die Sample-Größe verändert, was die Mount-Zahl bedeutet, deshalb sagt der Bericht das auch dazu. rclone öffnet eine Datei mit `vfs_read_chunk_size` und verdoppelt die Größe von dort aus. Ein kurzes Sample verbringt also den größten Teil seiner Zeit noch im Hochlauf. Auf einem Setup gemessen: 47 MiB/s bei einem 256-MiB-Sample, gegenüber 88 MiB/s bei 1 GiB, während HTTP bei beidem konstant bei etwa 70 liegt. Der Standardwert von 128 MiB ist die Zahl für Suchen und Vorspulen. `--sample-mb 1024` ist die dauerhafte Obergrenze. Keine der beiden ist falsch, und der Lauf sagt dir, welche du gerade gemessen hast.

`-n` legt die Anzahl der Iterationen fest, `--provider` beschränkt den Lauf auf benannte Accounts, `--skip-mount` und `--skip-concurrent` lassen jeweils eine Phase weg, und `--json` gibt den Bericht für Skripte aus. Der Test verbraucht echte Bandbreite aus deinen eigenen Accounts: Iterationen mal Sample-Größe pro Account, zweimal, plus die Mount-Phase. Starte ihn aus dem zurg-Verzeichnis. Das NZB-Backend liest seinen `nzbs/`-Ordner relativ zum Arbeitsverzeichnis. Ein Account, der nichts auflistet, wird deshalb auch als solcher gemeldet und nicht als Account ohne große Dateien.

## Funktionierende Real-Debrid-Releases werden nach einer Linkprüfung nicht mehr als defekt markiert {#working-real-debrid-releases-are-no-longer-marked-broken-after-a-link-check}

Seit dem Nightly vom 2026-08-20 kann eine gesunde Bibliothek das Log mit `Link verification failed during refresh` und `keeping files as broken` füllen. Dazu kommen jeweils ein `404 Not Found` und `invalid_download_code` von einem Download-Host. An den Releases lag es nicht.

Das Nightly hat eine Aufräumfunktion für die Einträge ergänzt, die Real-Debrid unter My Downloads anlegt. Jeder Link, den zurg prüft, erzeugt so einen Eintrag. Lässt man sie liegen, wächst die Liste pro Torrent und pro Kaltaufbau um eine Zeile, und beim Start werden irgendwann zehntausende davon nachgeladen. Die Aufräumfunktion löscht diese Einträge im Hintergrund. Dahinter steckt die Annahme, dass ein Eintrag und die URL, die er erzeugt hat, getrennte Dinge sind.

Das sind sie aber nicht. Wenn man den Eintrag löscht, wird der Download-Code widerrufen. Am Leben hält ihn nur ein Host, der ihn schon abgerufen hat. Gemessen am 2026-08-22: Ein Code, der auf `124-4` erzeugt und einmal über `44-4` abgerufen wurde, kam auf `44-4` weiterhin mit `200` zurück. `124-4` und das unberührte `125-4` antworteten dagegen beide mit `404 invalid_download_code`. zurg wählt den Download-Host pro Anfrage aus den schnellsten wenigen aus. Der Host, der einen Link geprüft hat, ist deshalb selten derselbe, der ihn danach anfragt. Die Auflösung blieb vier Stunden im Cache, und jede Anfrage in diesem Zeitraum kam mit `404` zurück. Das wurde als kaputter Link gelesen, und das Release wurde als broken markiert.

Eine Auflösung verlässt den Link-Cache jetzt in dem Moment, in dem ihr Eintrag zum Löschen vorgemerkt wird. So wird keine URL mehr wiederholt, die gerade verschwindet. Die nächste Anfrage löst einen frischen Link auf. Die Einträge werden trotzdem weiter aufgeräumt. Fälschlich als broken markierte Releases kommen beim nächsten Refresh von selbst wieder in Ordnung. Dafür musst du nichts neu hinzufügen oder neu scannen.

## Serien, die nach Sendedatum benannt sind, werden als Serien und nicht als Filme abgelegt {#shows-named-by-air-date-are-filed-as-shows-not-movies}

Eine Sendung ohne Staffel- und Episodennummern wird stattdessen nach dem Sendedatum benannt, zum Beispiel `WWE SmackDown 2026-08-21`, und genauso jede Tages- und Late-Night-Show danach. Der Episodentest kannte diese Konvention gar nicht. Er suchte nach `S01E01`, nach ausgeschriebener Staffel- oder Episodennummer, nach dem Hash eines Anime-Releases, und wenn nichts davon passte, nach einer Reihe nummerierter Dateien, die als Sequenz gelesen werden konnten. Ein Tagesrelease ist eine einzelne Datei mit einem einzelnen Datum, also lautete die Antwort nein, und das Release landete im ersten Verzeichnis, das es annehmen würde. In den meisten Konfigurationen waren das die Filme.

Das Sendedatum zählt jetzt als das Merkmal, das es ist, geschrieben als `2026-08-21`, `2026.08.21`, `2026 08 21`, `2026_08_21` oder `20260821`. Nur echte Datumsangaben qualifizieren sich: Der Monat muss einer von zwölf und der Tag einer von einunddreißig sein. So wird eine Jahreszahl neben einer Auflösung, etwa `Movie.2026.05.1080p`, niemals als Datum gelesen. Bei einer Bibliothek mit 6755 Releases wechselt kein Film das Verzeichnis. Bei 4734 echten Tagesshow-Releases werden jetzt 4633 erkannt. Die übrigen sind ältere Scene-Namen, die das Jahr auf zwei Stellen abkürzen oder ans Ende stellen. Die lassen sich nicht mit ausreichender Sicherheit von einer Audio-Kanalbelegung unterscheiden.

Eine Bibliothek, die schon auf der Festplatte liegt, sortiert sich beim Start selbst neu ein. Der nächste Neustart reicht also. Du musst nichts neu scannen oder neu importieren.
