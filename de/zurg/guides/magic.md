# `__magic__`, ein Verzeichnis, das du organisieren kannst {#__magic__-a-directory-you-can-organise}

Jedes andere zurg-Verzeichnis wird berechnet. `movies` wendet den Filter für Filme an. `__all__` enthält alles.
Ein Release-Ordner enthält das, was der Account meldet. Der Aufbau wird bei jedem Refresh neu erstellt.

`__magic__` ist das einzige Verzeichnis mit **gespeicherten** Pfaden. Ein Verschieben ändert nur eine Tabellenzeile. Es werden keine Daten verschoben, und der Debrid-Account bleibt unverändert. Du kannst das selbst einrichten oder Sonarr und Radarr damit arbeiten lassen.

Es enthält drei Arten von Inhalten. `__magic__/__all__` enthält jedes Release, das noch nirgends einsortiert wurde, und ist der Ordner, aus dem die Download-Clients importieren. Da er berechnet wird, kann auf seiner obersten Ebene nichts angelegt werden, und die Bytes einer Datei können nicht über einen Namen geschrieben werden, den ein Release-Ordner bereits belegt (ein Release-Ordner nimmt Sidecar-Dateien nur unter Namen an, die er nicht verwendet). Mit einem DMM-Sponsor-Schlüssel sortiert zurg alles, was DMM identifiziert hat, nach Titel in `__movies__` und `__shows__` ([unten](#__movies__-and-__shows__-sorted-by-title)). Alles andere auf der obersten Ebene von `__magic__` gehört dir:

```
/mnt/zurg/__magic__
├── __all__     <- what nothing has placed yet, where a grab lands
├── __movies__  <- films zurg filed by title
├── __shows__   <- shows zurg filed by title
├── __anime__   <- anime shows, with magic.anime: true
├── anime
├── movies
└── tv          <- your *arr root folders
```

Die Pfade auf dieser Seite verwenden den Linux-Mount `/mnt/zurg`. Unter macOS ist er `/Volumes/Zurg` und unter Windows `Z:\`, also wird `/mnt/zurg/__magic__/tv` zu `/Volumes/Zurg/__magic__/tv` oder `Z:\__magic__\tv`.

Genau diese Trennung ist der Sinn der Sache. Der Ordner, aus dem ein Client importiert, und die Ordner, in die er importiert, liegen nebeneinander, also enthält keiner den anderen. Ein manueller Import, der auf den Download-Ordner zeigt, durchsucht deine Bibliothek nicht, und weder Sonarr noch Radarr warnen wegen dieser Anordnung.

Standardmäßig ist es ausgeschaltet. Aktiviere es mit:

```yaml
magic:
  enabled: true
```

und starte neu. Die Routen werden beim Start festgelegt, daher musst du nach dem Umschalten im Dashboard neu starten, bevor der Namespace antwortet.

## Wofür es da ist {#what-it-is-for}

Ein *arr importiert, indem er die Datei aus dem Download-Ordner in die Bibliothek **verschiebt**. zurg hatte keinen Ort, an dem dieser Verschiebevorgang landen konnte, also wich der *arr auf Kopieren aus. Eine Kopie von einem Debrid-Mount heißt aber, das komplette Release über das Netzwerk herunterzuladen. Genau das soll der Mount eigentlich vermeiden.

Mit `__magic__` ist der Import ein Umbenennen innerhalb eines Namensraums: Es wird eine Zeile geschrieben, die Datei erscheint dort, wo der *arr sie hinlegt, und es wird nichts heruntergeladen. Genau deshalb lohnt sich [der SABnzbd-Endpunkt](sonarr-radarr.md). Er ist nur eine dünne Schicht darüber, und ohne ihn würde jeder Import einen vollständigen Download bedeuten.

Das funktioniert nur, wenn der **Root-Ordner des \*arr ebenfalls innerhalb von `__magic__`** liegt, also `/mnt/zurg/__magic__/tv` und nicht irgendein Verzeichnis anderswo auf dem Rechner. Ein Verschieben, dessen Ziel außerhalb des Namensraums liegt, ist ein Verschieben zwischen zwei Dateisystemen, und das ist wieder eine Kopie. zurg lehnt so etwas direkt mit einem `403` ab, statt es stillschweigend zuzulassen. Die einzige Stelle innerhalb des Namensraums, die ebenfalls abgelehnt wird, ist die oberste Ebene von `__magic__/__all__`. Die gehört zum Bibliotheks-Layout und ist kein Ort zum Ablegen. [sabnzbd.md](sonarr-radarr.md) enthält die genauen Einstellungen.

Eine Datei, die außerhalb von `__all__` platziert wurde, bleibt dort weiterhin gelistet, und ein Löschen in `__all__` löscht vom Account. Deshalb verweigert zurg das Löschen einer Datei über `__all__` oder einen anderen Bibliotheksordner, solange eine Platzierung hier daraus streamt. Lösch sie stattdessen unter `__magic__`. Dadurch löscht ein *arr, der aus `__all__` importiert und danach seinen Download-Ordner dort aufräumt (wie einer, der über den SABnzbd-Proxy von DMM gespeist wird), nicht das Release, das er gerade importiert hat.

Außerdem muss der *arr den Download-Ordner und den Root-Ordner **über einen einzigen Mount** erreichen. Ein Container, dem `__magic__/__all__` und `__magic__/tv` als zwei getrennte Volumes übergeben werden, sieht zwei Dateisysteme, obwohl beide zu zurg gehören. Der Kernel lehnt dann das Umbenennen im Container ab, bevor zurg überhaupt davon erfährt, und der *arr kopiert stattdessen die ganze Datei. zurg wandelt so eine Kopie zwar nachträglich wieder in eine Platzierung um, sobald sie fertig ist, und protokolliert `A client copied …`. Der Download hat dann aber bereits stattgefunden. Binde deshalb ein Verzeichnis mit dem gesamten zurg-Mount in den Container ein. Siehe [Ein Volume für den Download-Ordner und die Root-Ordner](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

Auch zurgs eigene Beschaffung legt Dateien hier ab. Eine Radarr-Quelle schiebt jedes bestätigte Release mit demselben Verschiebevorgang wie ein Import in den Ordner des Films und bittet Radarr danach um einen Rescan. Siehe [acquisition.md](acquisition.md#placing-the-file).

zurg platziert außerdem selbstständig Dateien hier, und zwar in `__movies__` und `__shows__`. Siehe [unten](#__movies__-and-__shows__-sorted-by-title).

Die Bibliothek von Hand zu organisieren ist die andere Hälfte, und das funktioniert komplett ohne einen \*arr.

## Mit nichts gespeichert sind die Releases von `__all__` als echte Ordner {#with-nothing-stored-it-is-__all__s-releases-as-real-folders}

Öffnest du `__magic__/__all__` auf einer frischen Installation, siehst du jedes Release, das `__all__` enthält, jeweils als eigenen Ordner. Die Tabelle beginnt leer und speichert nur **Abweichungen** von diesem Standard. Eine unangetastete Bibliothek speichert deshalb gar nichts, die Wurzel von `__magic__` enthält nur den Spiegel, und neue Releases erscheinen dort sofort, sobald sie irgendwo anders auftauchen. Sobald etwas ein Release platziert, also ein Import durch einen \*arr oder die eigene Ablage von zurg in `__movies__` und `__shows__`, verschwindet es aus `__magic__/__all__`. Der Spiegel zeigt, was noch nichts platziert hat.

Es gibt keine Verzeichniskonfiguration dahinter: kein `only_show_the_biggest_file`, keine Größenfilter. Was das Release mitbringt, siehst du auch.

Der einzige Unterschied zu `__all__` ist, **wie ein Release-Ordner innen aussieht**. Überall sonst flacht zurg ein Release in ein einziges Verzeichnis ab, mit dem Dateinamen als Schlüssel, und hängt ein Suffix an, wenn zwei Dateien kollidieren würden:

```
__all__/Show.S01/Show.S01E01.mkv
__all__/Show.S01/Gag Reel (Extras).mkv
```

`__magic__/__all__` zeigt den Baum, den das Release tatsächlich hat:

```
__magic__/__all__/Show.S01/Show.S01E01.mkv
__magic__/__all__/Show.S01/Extras/Gag Reel.mkv
```

Das ist nicht nur kosmetisch. Sonarr und Radarr scannen einen Download-Ordner als Ordner: Eine Datei in einem Unterordner `extras`, `samples`, `featurettes`, `trailers` oder `deleted scenes` wird übersprungen, eine Datei auf oberster Ebene dagegen berücksichtigt. So wird die abgeflachte `Gag Reel (Extras).mkv` zum Import angeboten, wo der echte Baum sie übergeht. Außerdem greift das Parsen per Fallback auf den Titel des Downloads nur, wenn der Ordner genau eine Videodatei enthält. Ein Film, der neben seinem Featurette abgeflacht liegt, verliert deshalb diesen Fallback. Da der [SABnzbd-Endpunkt](sonarr-radarr.md) einem \*arr einen Ordner unter `__magic__/__all__` übergibt, greifen diese Regeln genau auf diese Oberfläche.

Zwei Details zur Form:

- **Ein einzelner umschließender Ordner wird weggelassen.** Fast jedes Release ist ein Ordner, der alles enthält, und dieser Ordner ist der Name, den das Release bereits trägt. Die Debrid-Backends leiten den Namen daraus ab. Also wird `/Show.S01/Season 01/ep1.mkv` als `Show.S01/Season 01/ep1.mkv` angezeigt, nicht als `Show.S01/Show.S01/Season 01/ep1.mkv`. Das gilt nur für eine Ebene, und nur wenn daneben nichts liegt: Ein Release mit einer Datei oben und einem Ordner daneben behält beides.
- **Keine Suffixe für doppelte Namen.** Die gibt es, damit eine abgeflachte Liste eindeutig bleibt. Ein Baum hat dafür Verzeichnisse.

Alles andere an einem Release-Ordner bleibt unverändert, auch bei einem Archiv: Ein RAR-Set lässt sich weiterhin wie ein Verzeichnis durchsuchen, liegt jetzt aber dort, wo seine Teile im Baum liegen. Ein Release, das aus einem einzelnen abgeflachten Archiv bereitgestellt wird, listet weiterhin den Inhalt dieses Archivs auf.

`__all__` und die `directories:`-Filter bleiben flach. Dorthin soll ein Medienserver zeigen, und daran ändert sich nichts.

## Organisieren {#organising-it}

Über den Mount, mit ganz normalen Befehlen:

+++ Linux
```bash
mkdir -p /mnt/zurg/__magic__/tv/The\ Show/Season\ 01
mv /mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /mnt/zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ macOS
```bash
mkdir -p /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01
mv /Volumes/Zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ Windows
```powershell
New-Item -ItemType Directory -Force "Z:\__magic__\tv\The Show\Season 01"
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Release.S01E01.1080p\ep1.mkv" `
  -Destination "Z:\__magic__\tv\The Show\Season 01\S01E01.mkv"
```
`-LiteralPath` sorgt dafür, dass die eckigen Klammern, die viele Release-Namen haben, nicht als Platzhalter interpretiert werden.
+++

Die Datei liegt jetzt am neuen Pfad und ist vom alten verschwunden. Sie wird weiterhin vom selben Konto gestreamt wie bisher.

Ganze Release-Ordner lassen sich ebenfalls verschieben, als eine einzige Zeile:

+++ Linux
```bash
mv /mnt/zurg/__magic__/__all__/Some.Movie.2024.2160p /mnt/zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ macOS
```bash
mv /Volumes/Zurg/__magic__/__all__/Some.Movie.2024.2160p /Volumes/Zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ Windows
```powershell
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Movie.2024.2160p" -Destination "Z:\__magic__\movies\Some Movie (2024)"
```
+++

Verzeichnisse werden samt allem, was darin liegt, in einem Rutsch verschoben. Verschieben geht in beide Richtungen: Eine Datei lässt sich *in* einen Release-Ordner verschieben und auch wieder heraus, und der Ordner zeigt sie neben den eigenen Einträgen des Releases an. Genau das braucht ein Programm, das etwas in den Ordner zurücklegt, aus dem es gerade importiert. Taucht ein Name gleichzeitig von zwei Seiten auf, gewinnt der bewusste: Was du verschoben hast, schlägt das, wie das Release diesen Namen nennt, und das wiederum schlägt eine echte Datei in `data/local`. Der Verlierer wird weggelassen statt doppelt aufgelistet.

Eine Konstellation schlägt beim eingebauten Mount fehl, und zwar nur beim Standardwert `union_writable: local`: Umbenennen eines Verzeichnisses, *das du über den Mount angelegt hast*, also erst `mkdir` und später `mv` auf dieses Verzeichnis. Bei der Standardreihenfolge legt `mkdir` das Verzeichnis auf rclones eigenem lokalen Upstream an, während die Zeilen darunter dasselbe Verzeichnis serverseitig existieren lassen. rclone benennt daraufhin seine lokale Kopie um, verschiebt die Zeilen einzeln – zurg beantwortet jede davon korrekt – und scheitert dann beim Entfernen einer Quelle, die es bereits umbenannt hat:

```
ERROR : __magic__/tv/Saul: Dir.Rename error: RenameDir rmdir: object not found
```

Die Zeilen landen genau dort, wo du sie hinhaben wolltest: zurg liefert den neuen Pfad aus und beantwortet den alten mit 404. Aber `mv` endet mit Exitcode 1, und der Mount zeigt das leer gewordene Quellverzeichnis statt des Ziels, bis seine Auflistung neu eingelesen wird. Die Entfernungsanfrage erreicht zurg nie, deshalb kann zurg da nichts verhindern. Dateien verschieben und ganze Release-Ordner verschieben funktioniert bei beiden Reihenfolgen. Wenn du Verzeichnisse über den Mount umorganisierst, setze [`union_writable: server`](../reference/config.md#rclone-settings). Dann existiert das Verzeichnis nur im Namensraum, und das Umbenennen ist eine einzige serverseitige Operation. Gemessen mit rclone 1.71.2.

`rm` versteckt Dinge, siehe [Löschen versteckt, zerstört aber nichts](#deleting-hides-it-does-not-destroy).

## `__movies__` und `__shows__`, sortiert nach Titel {#__movies__-and-__shows__-sorted-by-title}

Kodi und Plex erkennen anhand von Ordner- und Dateinamen, was eine Datei ist. Ein Release-Name wie `Succession.S01.MULTi.1080p.BluRay.REMUX.AVC-DEMS` ist für sie oft zu viel. Bei Release-Namen erkannte Kodi in unserem Test nur 8 von 56 Serien. Mit einem DMM-Sponsor-Schlüssel legt zurg jeden Release, den DMM identifiziert hat, in zwei Ordnern ab, und zwar unter Namen, die die Player sofort zuordnen:

```
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.mkv
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/tvshow.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/Season 01/Detective Conan (1996) - S01E1194 [tmdbid-30983].mkv
```

Dieselbe Bibliothek, so abgelegt, ließ Kodi und Plex alle 70 Filme, alle 44 Serien und alle 554 Episoden zuordnen.

### Einschalten {#turning-it-on}

Du brauchst ein zurg-Nightly vom 2026-10-26 oder neuer, `__magic__` aktiviert und deinen DMM-API-Schlüssel, den dir [gatekeeper](https://gatekeeper.debridmediamanager.com/) anzeigt, sobald du sponserst:

```yaml
magic:
  enabled: true
dmm_api_key: YOUR_DMM_API_KEY
```

Starte zurg neu. Die beiden Ordner füllen sich, sobald die Bibliothek geladen und von DMM erkannt wurde. Bei einer großen Bibliothek dauert das beim ersten Mal ein paar Minuten. Danach wird ein neues Release innerhalb einer Minute einsortiert, nachdem DMM es erkannt hat. Dann fügst du eine **Movies**-Bibliothek hinzu, die auf `/mnt/zurg/__magic__/__movies__` zeigt, und eine **TV**-Bibliothek, die auf `/mnt/zurg/__magic__/__shows__` zeigt (`/Volumes/Zurg/__magic__/...` unter macOS, `Z:\__magic__\__movies__` und `Z:\__magic__\__shows__` unter Windows), und startest den Scan. In Kodi stellst du den Scraper der TV-Quelle auf **The Movie Database** ein, wie er standardmäßig ist, und hältst ihn aktuell: Die `tvshow.nfo`-Dateien brauchen Version 1.7 oder neuer des TMDb-TV-Scrapers von Kodi.

Richte jede Bibliothek auf ihren eigenen Ordner aus, nie auf `__magic__` selbst. Sonst würden auch `__all__` und deine anderen Ordner gescannt, und alles würde doppelt gefunden.

### Was es macht {#what-it-does}

- **Film oder Serie ist das, was DMM sagt, nie eine Ordnerregel.** Ein Film, der in einem Staffelpaket einer Serie kam, wird als dieser Film abgelegt.
- **Jede Version einer Serie landet in einem Ordner**, mit Staffeln und Episoden nummeriert wie bei TMDB, also in der Reihenfolge, die Plex standardmäßig nutzt. Anime, die durchgehend nummeriert ist, wird in ihre Staffel einsortiert: `Detective Conan - 1194` wird zu S01E1194.
- **Die TMDB-ID steht im Ordner, in jedem Dateinamen und in der `.nfo`**, damit jeder Player sie dort findet, wo er sucht: Plex im Ordner, Kodi in der `.nfo` und Player, die nur Dateinamen lesen, im Dateinamen.
- **Ein Exemplar pro Titel.** Wenn zwei Releases dieselbe Episode oder denselben Film darstellen, wird die bessere abgelegt, zuerst nach Auflösung, dann nach Größe. Die andere bleibt in `__all__`.
- **Extras und Samples bleiben in `__all__`**, ebenso alles, was DMM nicht erkannt hat. Ein Release wird abgelegt, sobald DMM es erkannt hat.

### Anime in einem eigenen Ordner {#anime-in-a-folder-of-its-own}

Anime-Serien können in einen dritten Ordner, `__anime__`, verschoben werden. So bekommen Kodi und Plex eine eigene Anime-Bibliothek, ähnlich wie früher eine zweite Sonarr-Instanz für Anime dir eine gegeben hat. Dafür brauchst du einen zurg-Nightly ab 2026-11-10 oder neuer und eine weitere Zeile:

```yaml
magic:
  enabled: true
  placement: true
  anime: true
dmm_api_key: YOUR_DMM_API_KEY
```

Starte zurg neu und füge dann eine **TV**-Bibliothek hinzu, die auf `/mnt/zurg/__magic__/__anime__` zeigt, und scanne sie. Was als Anime gilt, entscheidet DMM anhand von TMDB: eine Serie, die TMDB als Animation führt, auf Japanisch und aus Japan, alle drei Kriterien, oder eine, die TMDB mit dem Keyword *anime* versehen hat. Detective Conan, Ace of the Diamond und Cyberpunk: Edgerunners landen in `__anime__`. Hazbin Hotel (Animation aus den USA), Alice in Borderland (japanisch, Realfilm) und LINK CLICK (chinesische Animation) bleiben in `__shows__`. Filme bleiben in `__movies__`, auch Anime-Filme: Eine Movies-Bibliothek hat nur einen Typ, und dieser Ordner ist genauso einer.

Wenn du das einschaltest, werden alle Anime-Serien innerhalb weniger Minuten aus `__shows__` verschoben. Deine Player sehen das so, als würden die Serien aus einer Bibliothek verschwinden und in einer anderen auftauchen:

- **Plex** entfernt sie aus der TV-Bibliothek (als fehlend markiert oder komplett gelöscht, falls du den Papierkorb nach jedem Scan automatisch leerst) und holt sie beim nächsten Scan in die Anime-Bibliothek. Der Gesehen-Status bleibt erhalten, denn Plex hängt ihn an die Serie, nicht an die Bibliothek. Eine in der TV-Bibliothek gesehene Episode wird also auch in der Anime-Bibliothek als gesehen angezeigt (gemessen am 2026-11-09).
- **Kodi** hängt den Gesehen-Status an den Dateipfad. Exportiere deshalb deine Videobibliothek (Settings → Media → Library → Export), bevor du das einschaltest, und importiere sie wieder, nachdem die Anime-Quelle gescannt wurde.

Wenn du es ausschaltest, werden sie auf dieselbe Weise zurückverschoben.

### Mit der DMM-Wunschliste {#with-the-dmm-wanted-list}

Drück bei DMM auf **Want**, dann holt zurg den Titel ([DMM-Wunschliste](dmm-wanted.md)). Was geholt wird, landet wie alles andere hier im Ordner. Dadurch erscheint der Film oder die Serie unter ihrem eigenen Namen in Kodi und Plex, ohne dass Sonarr oder Radarr beteiligt sind. Ein Torrent, den es geholt hat, kann bis zu einer Stunde brauchen, bis er einsortiert ist. Ein NZB wird sofort einsortiert, sobald DMM ihn erkannt hat.

### Mit Sonarr und Radarr {#with-sonarr-and-radarr}

Sie behalten ihre eigenen Bibliotheken. Ein Release, das Sonarr oder Radarr über zurg geholt hat, bleibt ab dem Moment des Holens in `__all__` liegen, damit sie es importieren können, und zurg verschiebt nichts, das sie abgelegt haben. Wenn eine der Apps einen Titel importiert, den zurg bereits einsortiert hat, indem sie ihn in ihren eigenen Root-Ordner verschiebt, gehört er ab dann dieser App, und zurg lässt ihn dort liegen.

Damit Kodi und Plex ihre Bibliotheken auf die gleiche Weise zuordnen:

- Aktiviere in jeder App **Settings → Metadata → Kodi (XBMC) / Emby**. Sie schreiben dann neben jedem Film und jeder Serie eine `.nfo` mit den IDs des Titels, und zurg behält diese Dateien für sie.
- Trage die ID in die Ordnernamen ein, unter **Settings → Media Management**:

  | | Ordnerformat |
  |---|---|
  | Radarr | `{Movie CleanTitle} ({Release Year}) {tmdb-{TmdbId}}` |
  | Sonarr | `{Series TitleYear} {tvdb-{TvdbId}}` |

### Gut zu wissen {#good-to-know}

- **Das Löschen in einem Player blendet die Datei aus**, wie jedes Löschen in `__magic__`. Sie bleibt auf deinem Debrid-Konto, und zurg legt sie nicht erneut ab.
- **In `__movies__`, `__shows__` oder `__anime__` kann nichts verschoben werden**: Diese Ordner gehören zurg und werden von zurg befüllt. Etwas daraus herauszuverschieben, wie es ein \*arr-Import tut, funktioniert.
- **Wenn DMMs Erkennung eines Releases sich ändert**, verschiebt zurg dessen Dateien unter den neuen Namen.
- **Eine kaputte Datei behält ihren Platz**, während zurg sie repariert, damit dein Medienserver sie nicht verliert.
- **Ohne DMM-Sponsor-Key wird nichts abgelegt.** Wenn du den Key entfernst oder `__magic__` ausschaltest, bleibt das bereits Abgelegte, wo es ist.

## Ein Verschieben übersteht Reparatur, Umbenennung und erneutes Auflisten {#a-move-survives-repair-rename-and-re-listing}

zurg repariert ein kaputtes Release, indem es das Release erneut zum Konto hinzufügt. Die Torrent-ID ändert sich, der Zugriffsschlüssel ändert sich, die Datei-IDs ändern sich. Eine Tabelle, die auf einem dieser Werte basiert, würde also bei der ersten abgelaufenen Verknüpfung jede Platzierung verlieren. Deshalb werden Zeilen stattdessen über den **Inhalts-Hash** des Releases und den **Pfad der Datei innerhalb des Releases** identifiziert. Beides ändert eine Reparatur nicht.

Alles hier ist bewusst so gewählt:

- **Eine Reparatur behält dein Layout.** Das Release kommt unter einer neuen ID zurück, und die Dateien liegen immer noch dort, wo du sie abgelegt hast.
- **Umbenennen verschiebt nichts.** Ein Umbenennen und das Suffix, das zurg anhängt, wenn zwei verschiedene Releases denselben Ordnernamen hätten, ändern beide den Namen des Standardordners eines Releases. Die Platzierungen bleiben davon unberührt.
- **Eine fehlende Datei wird nicht vergessen.** Wenn eine Reparatur die Dateiliste ändert, meist weil Real-Debrid ein per RAR gepacktes Release neu packt, wird eine Zeile, deren Datei nicht mehr existiert, *behalten, aber nicht aufgelistet*. Taucht die Datei wieder auf, kehrt auch ihre Position zurück. Zeilen in diesem Zustand erscheinen auf dem Dashboard als **dangling**, dort kannst du sie entfernen.
- **Löschen und erneutes Hinzufügen behält dein Layout ebenfalls.** DMMs Reinsert oder ein Löschen, gefolgt von einem neuen Hinzufügen desselben Releases, bringt denselben Hash zurück. Die Dateien landen wieder dort, wo du sie abgelegt hast. Ein gelöschter Ordner, etwa der Job-Ordner, den ein \*arr nach einem Import entfernt, bleibt versteckt. Damit das Release wieder in `__magic__/__all__` erscheint, suche es auf der `__magic__`-Seite des Dashboards und drücke bei seinem Release-Tombstone auf **Unhide**.

Ein Backend braucht mehr als einen exakten Pfadvergleich. Die Dateinamen eines Usenet-Posts werden *aufgelöst* statt angegeben. Sie werden bei jedem Laden neu abgeleitet und nie gespeichert. Ein Post, der zuerst gelesen wurde, während der News-Server nicht erreichbar war, behält seine verschleierten Namen, bis ein späteres Laden die echten wiederherstellt. Für solche Posts fällt eine Zeile zuerst auf den Index der Datei innerhalb der NZB zurück und danach auf Basename plus Größe, sofern genau eine Datei passt.

## Löschen blendet aus, es zerstört nichts {#deleting-hides-it-does-not-destroy}

**Grabstein** (Tombstone): `rm` unter `__magic__` setzt einen Grabstein. Der Eintrag verschwindet aus `__magic__`, bleibt aber genau dort, wo er in `__all__`, in jedem Filterverzeichnis und auf dem Debrid-Konto war. Es wird nichts gelöscht.

Das ist keine Zurückhaltung. Damit kann ein \*arr sicher darauf zeigen. Bei einem Qualitäts-Upgrade löscht ein \*arr die alte Datei, und beim Import löscht er den ganzen Job-Ordner. Würden diese Löschvorgänge Inhalte entfernen, würde ein Upgrade das Release zerstören. Würde ein Löschen nur die *Zeile* entfernen, würde die Datei an ihrem Standardort wieder auftauchen, direkt in dem Ordner, aus dem der \*arr importiert.

Wenn ein Löschen wirklich löschen soll:

```yaml
magic:
  allow_delete: true
```

Dann entfernt ein **Datei**-Löschvorgang den Inhalt auch vom Konto. Ein Release-Ordner oder ein Verzeichnis wird dabei nie gelöscht, egal wie das eingestellt ist. Den Release-Ordner löscht Sonarr nach jedem Import.

Ein Eintrag in einem Archiv ist bei den meisten Usenet-Releases die Episode oder der Film. Er hat keine eigene Datei. Das Archiv enthält außerdem alles andere im Release. Ein Löschen entfernt das ganze Release also erst dann, wenn nichts unter `__magic__` mehr etwas davon verwendet. Keine Datei daraus darf noch irgendwo platziert sein. Der eigene Ordner muss gelöscht sein oder nichts mehr zum Importieren enthalten. In diesem Zustand lässt ein Upgrade eine ersetzte Usenet-Episode zurück. Bis dieser Fall behandelt wurde, blieb das ersetzte Release für immer in der Bibliothek und seine NZB in `nzbs/`.

Eine normale Videodatei wird für sich allein gelöscht. Ihr Release geht ebenfalls weg, sobald nichts unter `__magic__` mehr etwas davon verwendet. Dieselben beiden Regeln entscheiden darüber. Releases enthalten oft mehr als nur das Video. Eine `.nfo`, Untertitel oder ein Poster liegen daneben, und niemand importiert diese Dateien. Bis dieser Fall behandelt wurde, hielten sie das Release in der Bibliothek, auch nachdem das einzige Video gelöscht war. Die NZB blieb in `nzbs/`, und ein Debrid-Release blieb auf dem Konto. Eine andere Episode desselben Packs hält das Release am Leben, solange sie platziert ist oder noch im Release-Ordner liegt. Das gilt auch für einen Release-Ordner, der irgendwohin verschoben wurde. Ebenso für eine Episode, die nicht mehr lesbar ist, aber noch repariert werden kann. Eine Begleitdatei dort zu löschen, wo sie gepostet wurde, entfernt nie das Release. Das Löschen der letzten Untertiteldatei, die Sonarr oder Radarr neben dem Video importiert hat, tut es dagegen.

`dav_allow_rename` und der eigene, nicht abgesicherte Löschpfad des Mounts haben mit alldem nichts zu tun. Diese decken die Wege ab, auf denen umbenannt und zerstört wird, was das Debrid-Konto hält. Ein Schreibvorgang unter `__magic__` erreicht kein Konto. `mount_read_only: true` setzt trotzdem alles außer Kraft, auf Kernel-Ebene.

Einen Grabstein rückgängig zu machen, ist ein Klick auf dem Dashboard.

Ein Upgrade lässt also das ersetzte Release in deiner Bibliothek liegen. **Manage > Duplicates** listet diese Überbleibsel neben dem Release auf, das der \*arr jetzt verwendet, und löscht die, die du auswählst. Siehe [Doppelte Releases finden](acquisition.md#finding-duplicate-releases).

## Filter und `__all__` bleiben unverändert {#filters-and-__all__-are-untouched}

Ein Release, das du verschoben hast, liegt weiterhin in `movies`, weiterhin in `recent`, weiterhin in `__all__`, unter seinem ursprünglichen Namen. `__magic__` ist eine zweite Ansicht derselben Bibliothek, keine Verschiebung.

Das überrascht viele, deshalb sage ich es klar: **Wenn du etwas in `__magic__` verschiebst, ändert sich nur `__magic__`.** Die Filterverzeichnisse werden aus dem Release berechnet, und am Release selbst hat sich nichts geändert.

Für einen Media-Server solltest du auf **eine** der beiden Ansichten zeigen. Eine Plex-Bibliothek, die sowohl `shows/` als auch `__magic__/tv` scannt, findet jede Episode doppelt. Das gilt genauso für `__movies__`, `__shows__` und `__anime__`: Richte eine Bibliothek auf eines davon, nie auf `__magic__` selbst.

## Sidecars: `.nfo`, Poster, Untertitel {#sidecars-nfo-posters-subtitles}

Ein \*arr schreibt Metadaten neben die Videodatei, und Bazarr schreibt Untertitel. Das sind echte Dateien, und zurg hat in einer Debrid-Bibliothek keinen Platz dafür. Deshalb landen sie auf der lokalen Festplatte unter `data/local/__magic__/`.

Wie du Bazarr einrichtest und wie seine Untertitel zu rex gelangen, steht in [Untertitel mit Bazarr](subtitles.md).

Wenn du zurgs eingebauten Mount nutzt, passiert das schon automatisch und du musst nichts tun. Der Mount ist eine Union aus `data/local` und zurgs WebDAV, und rclone schickt jede neu erstellte Datei an die lokale Hälfte. zurg bekommt den Schreibvorgang nie mit. Deshalb besteht auch Sonarrs Test „Ist dieser Ordner beschreibbar?“.

Wenn du `/dav` selbst einbindest, zum Beispiel mit deinem eigenen rclone, mit Infuse oder mit einem Windows-WebDAV-Laufwerk, dann akzeptiert zurg das `PUT` und schreibt in denselben Baum. Beide Sichten stimmen also überein. Dabei gelten zwei Grenzen:

```yaml
magic:
  sidecar_max_mb: 32       # per file
  sidecar_budget_mb: 2048  # the whole tree
```

Bei der ersten kommt `413` zurück, bei der zweiten `507`. Sie begrenzen, was *zurg* schreibt. Bei der Standardeinstellung `union_writable: local` kann rclone seinen eigenen lokalen Upstream von hier aus nicht abweisen. Der Baum wird aber vor jeder Ablehnung neu gemessen. Dateien, die rclone dort ablegt, zählen deshalb beim nächsten Schreibwunsch an zurg gegen das Budget. Ausgenommen sind nur Dateien, die größer als `sidecar_max_mb` sind. Mit `union_writable: server` wird das umgedreht. Die Erstellung selbst kommt dann bei zurg an, sodass die Grenzen auch jeden Schreibvorgang über den Mount entscheiden. Alles außerhalb von `__magic__` wird dann direkt abgelehnt.

Ein Sidecar kann auch in einem Release-Ordner liegen. Dorthin schreibt ein \*arr die `.nfo` für eine Datei, die er dort importiert hat. zurg schreibt und benennt einen Sidecar um, und zwar unter jedem Namen, den das Release noch nicht belegt. Einen Namen, der der eigenen Datei des Releases gehört, lehnt zurg ab. Ein `DELETE` auf einen Sidecar löscht ihn wirklich. Das ist die einzige Stelle in `__magic__`, an der ein Löschen kein Tombstone ist. Ein Tombstone blendet einen Eintrag aus, den die Bibliothek anderswo noch hat. Die Daten eines Sidecars liegen dagegen nur in `data/local` und sonst nirgends.

## Das Dashboard {#the-dashboard}

Sobald die Bibliothek geladen ist, schreibt zurg eine Zeile ins Log, die angibt, wie viele Zeilen die Tabelle enthält und wie viele davon verwaist sind. So bleibt bei einer Bibliothek, die Inhalte verloren hat, keine wachsende Menge an Zeilen, von der niemand etwas mitbekommt.

Unter `/magic/` auf dem normalen Port von zurg siehst du, was die Tabelle enthält: jede gespeicherte Zeile, gruppiert nach Release, was jede davon ist und woher sie stammt, die verwaisten Zeilen in einem eigenen Abschnitt sowie den Sidecar-Baum mit seiner Größe im Vergleich zum Budget. Außerdem zeigt die Seite die Größen von Journal und Snapshot und die Größe des gesamten `data/local`. Diese Zahl sagt dir, ob etwas per Kopieren importiert wird, denn bei der Standardeinstellung `union_writable: local` legt ein Client, der kopiert statt zu verschieben, die Bytes dort ab, und sonst würde man das nie sehen.

Bei `union_writable: server` bleibt diese Zahl bei null, und stattdessen sagt das Log, was passiert ist: Ein `PUT` eines kopierenden Clients wird abgelehnt, sodass der Baum, den er füllen würde, nie geschrieben wird. Die Bytes gehen dadurch nicht verloren, denn der Cache von rclone hält sie und versucht es erneut. Sie liegen aber nicht mehr auf dieser Festplatte unter einem Namen, den zurg zählen kann. [Die qBittorrent-Anleitung](sonarr-radarr-torrents.md) erklärt die Ursache, die in allen Fällen eine clientseitige Einstellung ist: Ein \*arr verschiebt einen Import nur dann, wenn er den Download danach entfernen darf.

Von dort aus kannst du eine Platzierung zurücksetzen (die Datei wandert zurück an ihren Standardort), einen Tombstone entfernen (der Eintrag kommt zurück), eine verwaiste Zeile löschen, alle davon auf einmal bereinigen und einen Sidecar löschen. Jede Aktion muss vor dem Ausführen bestätigt werden.

Die Liste der gespeicherten Zeilen zeigt die ersten tausend Zeilen. Bei einer Bibliothek, die ein \*arr organisiert, ist das nur ein kleiner Teil der Tabelle, weil jeder Import einen Tombstone hinterlässt. Um ein einzelnes Release zu erreichen, suche danach: Ein Release-Name, ein Pfad auf dem Mount oder ein Hash listet jede gespeicherte Zeile zu diesem Release mit ihren Schaltflächen auf, egal wie groß die Tabelle ist. Die Liste der verwaisten Zeilen funktioniert genauso. Ein Release, das die Bibliothek nicht mehr hat, hat in der Tabelle keinen Namen, sondern nur seinen Hash und die Pfade, auf die seine Zeilen verweisen.

Sidecars, **die niemand mehr zuordnet**, werden getrennt vom Rest aufgelistet und gezählt: eine `.nfo` neben einem Release, das die Bibliothek verlassen hat, oder innerhalb einer Platzierung, die vergessen wurde. Sie werden weiterhin ausgeliefert, denn eine echte Datei ist das Letzte, worauf ein Pfad aufgelöst wird, und darüber beansprucht niemand mehr den Namen. Weggefallen ist aber der Grund, aus dem sie dort abgelegt wurden. zurg löscht nie eine davon automatisch. Ein Verzeichnis, das du selbst für Sidecars angelegt hast, und zwar über den Mount und nicht über zurg, wird genauso angezeigt, weil dafür ebenfalls keine Zeile existiert.

Ist der SABnzbd-Endpunkt aktiviert, listet die Seite außerdem seine Jobs auf: ID, Name, Kategorie, Status und den Ordner, der an das \*arr übergeben wurde. Das ist der schnellste Weg, um die Frage „Warum zeigt Sonarr das immer noch als Download an?“ zu beantworten.

## Haltbarkeit {#durability}

Jede Änderung wird an `data/magic.journal` angehängt und **vor** der Antwort auf die Anfrage auf die Festplatte geschrieben. So bleibt ein Verschieben, von dem ein \*arr glaubt, dass er es gemacht hat, auch nach einem Absturz erhalten.

Das Journal wird beim Start, wenn es über einen Schwellenwert hinauswächst, und beim Herunterfahren in einen Snapshot `data/magic.json` zusammengeführt.

Keine der beiden Dateien ist dafür da, die Tabelle zu ändern. zurg hält sie im Speicher und schreibt `magic.json` von dort aus. Wenn du also eine Zeile bei laufendem zurg von Hand aus der Datei löschst, ist sie nach dem nächsten Neustart wieder da. Nutze dafür die Buttons im Dashboard.

Eine angebrochene letzte Zeile nach einem Stromausfall wird verworfen, alles davor bleibt erhalten. Ein Snapshot mit einer anderen Schema-Version wird verworfen, statt ihn zu raten, und eine Journal-Zeile aus einer anderen Version stoppt das Wiedereinspielen an dieser Stelle. Ein Snapshot oder Journal, das nicht gelesen werden kann, ist eine Warnung und eine leere Tabelle, kein fehlgeschlagener Start. Und wenn die Dateien einer Tabelle nicht *geöffnet* werden können, bleibt `__magic__` schreibgeschützt, als Spiegel von `__all__`, mit dem es startet, und jeder Schreibzugriff wird abgelehnt. Schreibzugriffe, die während des Herunterfahrens ankommen, werden mit `503` abgelehnt, statt bestätigt und dann verloren zu gehen.

## Statuscodes {#status-codes}

Nützlich, wenn du den Namensraum direkt über WebDAV ansteuerst. Der Mount erledigt das alles für dich.

| Code | Bedeutung |
|---|---|
| `201` | MOVE, MKCOL oder PUT hat etwas angelegt |
| `204` | DELETE, oder ein PUT, das eine Sidecar-Datei ersetzt hat |
| `400` | ein Pfad, den dieser Namensraum nicht speichern kann, oder ein `Destination`-Header, der fehlt oder nicht lesbar ist |
| `403` | ein Ziel außerhalb von `__magic__` oder innerhalb von `__movies__`, `__shows__` oder `__anime__`, ein Pfad, für den die Bibliothek antwortet, ein Pfad, der durch eine Datei läuft, `__magic__` selbst, oder eine Tabelle, die schreibgeschützt ist |
| `404` | dort ist nichts (ein DELETE auf nichts antwortet trotzdem mit `204`), oder ein MOVE aus einem Archiv, das den Eintrag nicht mehr enthält |
| `405` | MKCOL, wo schon etwas existiert, oder PUT auf ein Verzeichnis |
| `409` | fehlendes übergeordnetes Verzeichnis, nicht leeres Verzeichnis, ein belegtes Ziel mit `Overwrite: T`, oder ein MOVE aus einem Archiv, das sich nicht öffnen lässt |
| `412` | belegtes Ziel mit `Overwrite: F` |
| `413` / `507` | über `sidecar_max_mb` / `sidecar_budget_mb` |
| `503` | wird heruntergefahren, oder ein MOVE, dessen Quelle gerade nicht bereitgestellt werden kann — mit einem `Retry-After` |

`MOVE` lehnt jedes Ziel außerhalb von `__magic__` ab: Die Filterverzeichnisse bleiben schreibgeschützt.

Ein `MOVE` **aus einem Archiv** wird außerdem gegen das Archiv selbst geprüft, bevor irgendetwas geschrieben wird. Ein Import ist ein `MOVE`, und ein `MOVE`, das erfolgreich ist, ist ein Versprechen, das danach niemand mehr nachprüft. Die Verzeichnisliste, die der Client durchlaufen hat, ist dafür kein Beleg: Geparste Archivinhalte werden zwischengespeichert, daher listet ein Release, dessen Daten verschwunden sind, trotzdem seine Episoden. Deshalb werden zuerst der Zustand des Volumes, die Artikelschäden des Releases und, wo diese nichts aussagen, das Archiv selbst geprüft, genau so, wie ein `HEAD` auf denselben Pfad sie prüft. Ein gesundes Release antwortet dabei aus demselben Zwischenspeicher, den seine Auflistung bereits aufgebaut hat. Eine Quelle, die niemals lesbar sein wird, ergibt ein `409`, eine, die im Moment nicht gelesen werden kann, ein `503` mit einem `Retry-After`, und ein Name, den das Archiv nicht enthält, bleibt ein `404`. Bei einer Ablehnung wird nichts vermerkt.

## Grenzen, die man kennen sollte {#limits-worth-knowing}

- **`magic.enabled` braucht einen Neustart.** Die Routen werden beim Start registriert.
- **Eine Platzierung pro Datei.** Wird eine Datei erneut verschoben, wird sie neu platziert; dieselbe Datei kann nicht unter zwei Pfaden erscheinen.
- **Eine Datei in einem rar-Set kann** wie jede andere platziert werden — die Zeile merkt sich das Volume und den Pfad darin, sodass sie ein Neu-Packen genauso übersteht wie eine normale Datei. Unterhalb einer platzierten Datei kann aber *nichts* angelegt werden: ein Pfad, der durch eine solche Datei führt, wird abgelehnt.
- **`serve_strm_files` wird in den Listings von `__magic__` ignoriert.** Dafür gibt es den Namespace: ein \*arr verschiebt die echte Datei daraus heraus, und eine `.strm` kann von keinem Programm importiert werden. Ein Client, der eine solche Datei namentlich anfragt, bekommt trotzdem eine Antwort.
- **Pfade werden exakt so verglichen, wie sie ankommen.** Es gibt keine Unicode-Normalisierung und keine Umwandlung der Groß-/Kleinschreibung. Ein Client, der einen Namen anders schreibt, als er ihn anfragt, findet die Datei daher nicht.

## Siehe auch {#see-also}

- [sabnzbd.md](sonarr-radarr.md) — Sonarr und Radarr auf zurg zeigen lassen, genau dafür wurde `__magic__` gebaut
- [DMM-Wunschliste](dmm-wanted.md) — drück in DMM auf Want, dann holt zurg die Liste nach `__movies__`, `__shows__` oder `__anime__`
- [usenet.md](usenet.md) — das NZB-Backend, in dem die Grabs landen
- [config.md](../reference/config.md#__magic__-a-directory-you-can-organise) — jeder Schlüssel im `magic:`-Block
