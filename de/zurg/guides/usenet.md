# Usenet mit zurg {#usenet-with-zurg}

Das `nzb`-Backend von zurg macht aus `.nzb`-Dateien eine eingebundene Bibliothek. Es gibt keinen Downloader und keinen Ordner für fertige Downloads.
Vor dem Abspielen wird nichts heruntergeladen. Gespeichert werden die NZBs, begrenzte Caches in `data/bytecache` und `data/par2`
sowie Index-Einträge. `nzb_article_disk_cache_mb` ist standardmäßig auf 512 MiB eingestellt. Beim Spulen holt zurg nur die Artikel, die
diese Bytes abdecken. Ein 60-GB-Remux braucht keine 60 GB Speicherplatz.

Usenet nutzt dieselben Bibliotheksfilter, Mount- und Media-Server-Integration wie die Debrid-Backends. Usenet-Releases können
neben Real-Debrid- oder TorBox-Inhalten liegen. Du kannst Usenet auch allein nutzen.

**Mehrere Usenet-Provider werden unterstützt.** Ein einzelner `nzb`-Eintrag kann beliebig viele News-Accounts enthalten — unbegrenzt viele Provider, Block-Accounts, was du eben hast — und zurg probiert sie Artikel für Artikel der Reihe nach durch. Das ist hier wichtiger als sonst Redundanz: Die Retention gilt pro Provider, daher ist ein zweiter Account sehr oft der Unterschied zwischen einem zusätzlichen Abruf und dem Neuaufbau eines ganzen Releases aus PAR2. Siehe [Mehr als ein Usenet-Provider](#more-than-one-usenet-provider).

Diese Anleitung behandelt News-Accounts, NZBs, den Mount und Plex.

| | |
|---|---|
| Konfigurationsreferenz | [config.md → Usenet accounts](../reference/config.md#usenet-accounts) |
| Dashboard | `http://localhost:9999/config/` → Essentials → Providers |
| Wo der Code liegt | `internal/nzb` (Backend), `internal/nntp` (News-Client), `internal/par2` (Reparatur-Mathematik) |
| Watch-Verzeichnis | `nzbs/`, im Arbeitsverzeichnis von zurg (`/config` in Docker) |
| Reparatur-Cache | `data/par2/` |
| Aufgelöste Dateinamen | `data/nzb-names/`, damit ein verschleiertes Release nur einmal auf seine Namen gelesen wird und nicht bei jedem Neustart |
| Artikel-Index | `data/nzb-index/`, unter `nzb_segments: mmap` — der Standard unter Linux, macOS und BSD |

---

## Was du brauchst {#what-you-need}

- **Mindestens ein Usenet-Provider-Konto.** Die Retention ist am wichtigsten. Ein Provider mit 4000+ Tagen hat noch Posts, die bei einem mit 1000 Tagen schon abgelaufen sind. Die *Verbindungsanzahl* deines Tarifs ist die zweite Zahl, die du kennen solltest. zurg liest mit dieser Anzahl.
- **Weitere Konten, falls du welche hast.** Ein zweiter unbegrenzter Provider auf einem anderen Backbone oder ein günstiges Block-Konto für die Lücken ist das Wertvollste, was du deinem Usenet-Setup hinzufügen kannst. Siehe [Mehr als ein Usenet-Provider](#more-than-one-usenet-provider).
- **NZB-Dateien oder etwas, das sie abruft.** Lade sie von deinem Indexer herunter und lege sie in `nzbs/` ab. Oder aktiviere den [SABnzbd-kompatiblen Endpunkt](sonarr-radarr.md) und lass Sonarr und Radarr sie übergeben. Er schreibt in dasselbe Verzeichnis. zurg kann auch selbst deine Newznab-Indexer durchsuchen. Das passiert, wenn du in [Stremio](stremio.md) auf Abspielen drückst. Außerdem bei Anfragen aus deiner Watchlist sowie von Seerr und den \*arrs über [Acquisition](acquisition.md). Torrents für ein Debrid-Konto haben einen eigenen Endpunkt, der [qBittorrent](sonarr-radarr-torrents.md) spricht.
- **zurg**, plus `rclone`, falls du einen Dateisystem-Mount statt direktem WebDAV willst. zurg lädt rclone beim ersten Start für dich herunter.

---

## 1. Richte deine Newskonten ein {#1-configure-your-news-accounts}

Jedes Konto in zurg ist ein Eintrag unter `providers:`. Ein Usenet-Konto meldet sich mit Server-Zugangsdaten statt mit einem API-Token an. Deshalb enthält es einen `nntp`-Block statt `token`:

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 30        # your plan's allowance — see below
      cache_size_mb: 512     # decoded articles held in memory, across all files
```

Mehr braucht es nicht. Wenn du Debrid-Konten hast, kannst du sie daneben ergänzen:

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: nzb
    nntp:
      host: news.example.com
      ...
```

| Schlüssel | Standard | Hinweise |
|---|---|---|
| `host` | *(erforderlich)* | Der News-Server. Fehlt der Host oder ist er leer, bricht der Start mit einem Fehler ab. |
| `port` | `563` mit TLS, `119` ohne | |
| `tls` | `false` | Aktiviere es. Unverschlüsseltes NNTP schickt dein Passwort im Klartext und deine Lesezugriffe an jeden, der auf dem Weg mithört. |
| `username` / `password` | `""` | |
| `connections` | `8` | **Trage hier das echte Kontingent deines Tarifs ein.** Das ist kein Ratenlimit, bei dem man höflich sein muss: Eine einzelne Verbindung schafft nur einen Bruchteil der Übertragungsrate eines Anbieters, und zurg liest mit genau dieser Anzahl. Zu wenig, und das Streaming ist langsam. Über dem Limit des Tarifs fängt der Server an, Verbindungen abzulehnen. |
| `warm_connections` | `4` | Inaktive, authentifizierte Verbindungen, die offen gehalten werden, damit ein Lesezugriff nie auf einen Verbindungsaufbau warten muss. Ein Verbindungsaufbau dauert etwa 0,8 s (TCP, TLS, Begrüßung und `AUTHINFO`). Ohne feste Untergrenze fiel er nach jedem Start und jeder ruhigen Phase direkt beim Zugriff an. Sie werden aus `connections` entnommen und kommen nicht obendrauf. Der Tarif zählt sie als offene Verbindungen, und zurg hält sie mit einem regelmäßigen `DATE` am Leben. Deshalb ist die Untergrenze auf das Kontingent begrenzt. `-1` behält keine, was ein Tarif mit Abrechnung nach Verbindungszeit möchte. Der oberste `warm_connections`-Wert legt den Standard für ein Konto fest, das keinen angibt. Siehe [Warme Verbindungen](../reference/config.md#warm-connections). |
| `cache_size_mb` | `512` | Dekodierte Artikeldaten im Speicher, gemeinsam genutzt über alle gelesenen Dateien statt pro Datei. |
| `servers` | `[]` | Weitere News-Konten. Siehe [Mehr als ein Usenet-Anbieter](#more-than-one-usenet-provider). |

Zwei Regeln, die der Config-Validator durchsetzt:

- **Nur ein aktivierter `nzb`-Provider-Eintrag.** Zwei würden denselben `nzbs/`-Ordner jeweils scannen und jede Veröffentlichung doppelt anlegen. Das begrenzt nicht die Anzahl der *Usenet-Anbieter*, die du nutzen kannst: Zusätzliche News-Konten gehören unter `nntp.servers` dieses einen Eintrags. Dort dienen sie dieselbe Bibliothek, statt eine zweite Kopie davon anzulegen.
- **`watchlist: true` kann nicht darauf zeigen.** Das Usenet-Backend kann keine Inhalte hinzufügen, deshalb kann es nie das Konto sein, in dem eine Hinzufügung aus der Plex-Watchlist landet.

### Mehr als ein Usenet-Anbieter {#more-than-one-usenet-provider}

Die Retention gilt pro Provider. Ob du mit einem zusätzlichen Abruf auskommst oder ein komplettes PAR2-Rebuild für das ganze Release brauchst, hängt davon ab, ob irgendein anderer Account den Artikel noch hat. Deshalb ist hier ein zweiter Account mehr wert, als Redundanz sonst üblicherweise ist.

Die Schlüssel, die schon im `nntp`-Block stehen, beschreiben den ersten Account. Alles unter `servers` ist ein weiterer Account. Accounts mit derselben `priority` teilen sich die Last. Eine höhere Zahl wird erst nach den niedrigeren angefragt, und ein `backup`-Account erst dann, wenn alle primären Accounts den Artikel nicht liefern konnten. Eine bestehende Konfiguration mit nur einem Account funktioniert unverändert weiter:

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # first account: the workhorse
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com   # different backbone = different retention
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com              # metered — only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

Jeder Account behält sein eigenes Verbindungskontingent. Lesevorgänge werden mit dem **kombinierten Kontingent der Nicht-Backup-Accounts gesteuert, die die niedrigste aktive `priority` teilen**: 30 + 20 = 50 im obigen Beispiel, wo beide die Standard-Priorität haben. Ein zweiter unbegrenzter Provider mit derselben Priorität bringt daher sowohl Durchsatz als auch Absicherung der Retention. Ein `backup`-Account bringt beides absichtlich nicht. Er liefert nur das, was die primären Accounts nicht liefern konnten, und würde man ihn mitzählen, würde jedes Read-ahead-Fenster größer, für Kapazität, die beim normalen Streaming nie gebraucht wird.

Drei Schlüssel bestimmen, wer gefragt wird:

| Schlüssel | Standard | Wirkung |
|---|---|---|
| `name` | Wert von `host` | Benennt den Account in den Logs. |
| `priority` | `0` | Wer zuerst gefragt wird, niedrigste zuerst. Accounts mit gleicher Priorität werden in der Reihenfolge der Konfiguration gefragt. Ausnahme: Ein Account mit freier Verbindung wird einem bevorzugt, dessen Kontingent aufgebraucht ist. So teilen sich zwei gleichwertige Accounts die Last, statt auf einem zu warten. |
| `backup` | `false` | Markiert einen volumenabgerechneten Block-Account, der erst dann gefragt wird, wenn jeder primäre Account gemeldet hat, dass ihm der Artikel fehlt, eine beschädigte Kopie geschickt hat, mittendrin abgebrochen ist oder nicht erreichbar ist. Ein primärer Account, der nur **ausgelastet** ist, reicht nicht: zurg wartet auf ihn, statt volumenabgerechnete Bytes für etwas auszugeben, das ein unbegrenzter Account geliefert hätte. |
| `backbone` | `""` | Benennt den Artikel-Spool, auf den ein Account auflöst. Zwei Accounts auf demselben Backbone haben dieselben Artikel. Sobald einer gemeldet hat, dass ihm ein Artikel fehlt, werden die anderen auf diesem Spool übersprungen, statt für dieselbe Antwort einen weiteren Roundtrip zu kosten. |

Jeder Account hält außerdem einen eigenen Mindestbestand warmer Verbindungen, und zwar aus seinem eigenen Kontingent. Eine Retention-Lücke schickt einen Lesevorgang direkt am Primary vorbei. Also ist genau der Account, der zum ersten Mal angefragt wird, derjenige, dessen Verbindungsaufbau noch niemand bezahlt hat. Einem Block-Account mit zwei Verbindungen kannst du mit `warm_connections: -1` sagen, dass er gar keinen Mindestbestand hält.

Weiterverkauf ist weit verbreitet, deshalb lohnt es sich, `backbone` auszufüllen. Zwei Accounts, die du bei verschiedenen Anbietern gekauft hast, können auf demselben Spool liegen. Ohne die Angabe wird jeder fehlende Artikel doppelt angefragt. Gruppiere sie nach einem beliebigen Namen, denn der Wert wird nur mit anderen Einträgen verglichen.

Beim Start listet zurg jeden Account auf, den es verwenden wird:

```
Usenet account nzb connected: nntps://unlimited.example.com:563 (30 connections) + nntps://second-unlimited.example.com:563 (20 connections) [usenetexpress] + nntps://block.example.com:563 (10 connections) [backup] [omicron]
```

Die Prüfung, die entscheidet, ob ein Release repariert werden muss, fragt jeden Account, bevor sie einen Artikel als fehlend einstuft. Dabei fragt sie jeden nur nach dem, was seine Vorgänger nicht hatten. Ein Übertragungsfehler wird nie mit einem abgelaufenen Artikel verwechselt: Wenn ein Account in einer Zeitüberschreitung hängen blieb oder den Artikel mittendrin abbrach, wird genau dieser Fehler gemeldet. So sorgt ein Timeout nie dafür, dass Stille ausgeliefert oder eine Reparatur für etwas angestoßen wird, das gar nicht weg war. Ein Account, der überhaupt nicht erreicht werden konnte, zählt nicht. Sagt ein anderer Account, der Artikel sei weg, dann gilt er als weg.

### Anbieter im Dashboard konfigurieren {#configuring-providers-in-the-dashboard}

`http://localhost:9999/config/` → **Essentials** → **Providers** macht dasselbe, ohne dass du YAML bearbeiten musst. Die Tabelle listet jeden Account in der Reihenfolge der Config auf:

```
#  Name        Type        Token                Flags
1  realdebrid  realdebrid  …DFFND4OA            —          [Edit] [Delete]
2  nzb         nzb         news.example.com     —          [Edit] [Delete]
```

Bei einer `nzb`-Zeile zeigt die Spalte Token den **Hostnamen des News-Servers** statt eines Token-Hinweises an, weil es hier kein Token zu schwärzen gibt. Danach steht, wie viele weitere News-Server der Provider hat.

**So fügst du einen Usenet-Account hinzu:**

1. Klicke auf **Add provider**.
2. Stelle **Type** auf `nzb`. Die Token-Felder verschwinden, und an ihrer Stelle erscheinen die NNTP-Felder.
3. Lass **Name** leer, außer du willst etwas anderes als `nzb`. Daraus ergibt sich der Name des Ordners für den Account. Wenn du hier `usenet` einträgst, bekommst du im Mount `__usenet__`.
4. Fülle **NNTP host**, **Port**, **TLS** (standardmäßig aktiviert, lass es an), **Username**, **Password**, **Connections** (Platzhalter `8`; trag hier das echte Kontingent deines Tarifs ein) und **Cache size MB** (Platzhalter `512`) aus.
5. Lass **Watchlist target** deaktiviert. Das Backend kann keine Inhalte hinzufügen, und wenn du es aktivierst, wird das Speichern abgelehnt. Mit **Disabled** bleibt der Eintrag in `config.yml`, wird aber nicht geladen.
6. Klicke auf **Save**.

Das Formular wird so geprüft, als wäre die Änderung schon übernommen. Fehler kommen deshalb als Alert zurück und nicht als kaputte Config. Ein **zweiter** `nzb`-Provider wird hier abgelehnt. Die Fehlermeldung verweist dich auf **Further news servers** (oder `nntp.servers`). Dort gehören weitere News-Accounts hin.

**So fügst du einen weiteren News-Server hinzu**, also einen zweiten Account oder einen Block-Account auf einem anderen Backbone: Klicke bei der `nzb`-Zeile auf **Edit** und dann unter **Further news servers** auf **Add news server**. Jeder Server hat eigene Felder für **Name**, **NNTP host**, **Port**, **TLS**, **Username**, **Password**, **Connections**, **Priority**, **Backbone** und **Backup only**. Mit **Remove server** entfernst du einen Server. **Save** schreibt alle Server nach `nntp.servers`.

**So bearbeitest du einen Eintrag:** Klicke bei seiner Zeile auf **Edit**. Das Formular lädt alles außer den Passwörtern. Das gilt für den ersten Account und für jeden weiteren Server. Die Passwortfelder bleiben leer und bedeuten *das bestehende behalten*. Gib nur dann ein neues Passwort ein, wenn du es ändern willst. Einstellungen, für die das Formular kein Feld hat, bleiben so erhalten, wie sie in `config.yml` stehen.

**Delete** fragt nach einer Bestätigung und entfernt danach den Provider-Eintrag aus `config.yml`. Dein `nzbs/`-Verzeichnis bleibt unberührt. Die NZB-Dateien bleiben, wo sie sind, und kommen mit dem Provider wieder. Der letzte aktive Provider kann weder gelöscht noch deaktiviert werden.

Jede Änderung hier wird direkt in `config.yml` geschrieben und zeigt an:

> Provider changes saved to config.yml — restart zurg to apply

Provider-Änderungen werden **nicht** im laufenden Betrieb übernommen. Starte zurg neu, bevor du erwartest, dass sich etwas ändert.

## 2. Starte zurg und bestätige die Konten {#2-start-zurg-and-confirm-the-accounts}

+++ Linux und macOS
```bash
./zurg
```
+++ Windows
```powershell
.\zurg.exe
```
+++

Hat `zurg setup` zurg so eingerichtet, dass es von allein startet, starte es stattdessen mit `zurg service restart` neu (`./zurg service restart` bzw. `.\zurg.exe service restart` unter Windows).

zurg prüft die Usenet-Konten beim Start einmal, denn ein falsches Passwort würde sich sonst erst viel später zeigen, nämlich wenn sich jede Datei nicht abspielen lässt:

```
Usenet account nzb connected: nntps://news.example.com:563 (30 connections)
```

Ein kompletter Ausfall ist genauso deutlich:

```
Cannot reach the news server for nzb: <reason>
```

Prüfe zuerst Port und TLS-Kombination (`563`+`tls: true` oder `119`+`tls: false`), dann die Zugangsdaten und danach, ob dein Abo tatsächlich aktiv ist.

**Bei mehreren Konten: Lies die Warnungen, nicht nur die connected-Zeile.** Jedes nicht erreichbare Konto bekommt eine eigene Warnung, und der Start läuft weiter, solange *ein* Konto antwortet. Der Fehler von oben erscheint nur, wenn jedes Konto nicht erreichbar ist. Ein ausgefallener zweiter Anbieter sieht also wie ein gesunder Start aus, wenn du nicht genau hinschaust:

```
Usenet account block.example.com is not reachable: <reason>
```

---

## 3. NZB-Dateien hinzufügen {#3-add-nzb-files}

zurg legt beim Start den Überwachungsordner `nzbs/` an. Er liegt in dem Ordner, aus dem zurg läuft. Kopier NZB-Dateien hinein.

+++ Linux und macOS
```bash
cp ~/Downloads/Some.Release.2024.2160p.nzb nzbs/
```
+++ Windows
```powershell
Copy-Item "$HOME\Downloads\Some.Release.2024.2160p.nzb" nzbs\
```
+++

Innerhalb von ein oder zwei Sekunden bemerkt zurg die Datei und liest sie ein. Die Bibliothek zeigt sie an, sobald das Lesen fertig ist. Das Log sagt dir, was gelesen wurde:

```
Loaded NZB Some.Release.2024.2160p.nzb: 94 files
```

### Wie schnell sie erscheint {#how-quickly-it-appears}

zurg überwacht `nzbs/` selbst, mit einer Prüfung etwa einmal pro Sekunde, die unabhängig von der Anzahl der NZBs im Verzeichnis nur einen Systemaufruf kostet. Eine Datei, die dort ankommt, wird deshalb fast sofort gelesen und nicht erst, wenn die nächste Bibliotheksprüfung ansteht. Ein [obfuskiertes Release](#obfuscated-releases) braucht etwas länger, weil seine echten Dateinamen zuerst aus seinen eigenen Artikeln ausgelesen werden müssen, meist deutlich unter einer Sekunde. Danach wird es sofort aufgelistet. Keine der beiden Wartezeiten hängt mehr von `check_for_changes_every_secs` ab. Früher war das anders: Ein obfuskiertes Release wurde bis zu zwei ganze Intervalle nach dem Ablegen aufgelistet, eines, bis das Verzeichnis gelesen wurde, und ein weiteres, weil die Namen erst kurz nach der Prüfung aufgelöst wurden, die es hätte bemerken müssen. Bei einem Intervall von 10 Sekunden dauerte es vom Ablegen bis zum Erscheinen des Releases 17.7 Sekunden, wovon 0.67 Sekunden die eigentliche Arbeit waren.

Die regelmäßige Prüfung gibt es weiterhin, und sie bleibt das Sicherheitsnetz. Sie fängt die zwei Dinge ab, die ein überwachtes Verzeichnis allein nicht melden kann: eine NZB, die **an Ort und Stelle ersetzt** wurde, und zwar unter einem Namen, den sie schon hatte, sowie ein Dateisystem, dessen Verzeichnis-Zeitstempel zu grob sind, um zwei Änderungen innerhalb derselben Sekunde auseinanderzuhalten.

### Was erkannt wird {#what-gets-picked-up}

Dateien **direkt im Ordner `nzbs/`**, deren Name auf `.nzb` endet, Groß- und Kleinschreibung egal.
- **Unterordner werden übersprungen.** `nzbs/movies/foo.nzb` ist unsichtbar. Lege alles flach ab, statt zu sortieren. Die Ordnung der Bibliothek kommt aus den Verzeichnisfiltern, nicht aus diesem Ordner.
- **Nur einfaches XML.** `.nzb.gz` wird weder entpackt noch gelesen. Entpacke sie vorher.
- Eine Datei, die nicht geparst werden kann, wird mit einer Warnung übersprungen und stoppt den Scan nicht.

### Wie der Release heißt {#what-the-release-is-called}

Der Name, den zurg anzeigt, und damit der Ordner, den Plex sieht, ist:

1. der eigene `<meta type="name">`-Wert der NZB, falls vorhanden und er die Bereinigung übersteht, andernfalls
2. **der Dateiname ohne `.nzb`**.

Meistens ist also *der Dateiname der NZB der Release-Name*. Benenne die Datei so, wie du den Release benennen würdest, denn genau danach wird dein Medienserver suchen:

```bash
# good
nzbs/Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb

# bad — Plex has nothing to work with
nzbs/indexer_download_48213.nzb
```

Zwei verschiedene Releases, die am Ende denselben Namen haben, werden durch ein kurzes Hash-Tag unterschieden (`Some.Release {a1b2c3}`), genau wie überall sonst in zurg.

### Passwortgeschützte Releases {#password-protected-releases}

Wenn der Indexer das Archivpasswort im Metadatenblock der NZB hinterlegt hat, nutzt zurg es beim Streamen aus dem RAR-Set:

```xml
<head>
  <meta type="password">thepassword</meta>
</head>
```

Mehr ist nicht nötig. Ein geschütztes Release, dessen NZB keine Passwort-Metadaten enthält, kann nicht geöffnet werden.

### Verschleierte Releases {#obfuscated-releases}

Posts mit zufälligen Dateinamen werden trotzdem verarbeitet, und der Aufwand fällt nur einmal beim Scan an. zurg probiert zuerst die günstige Quelle: den Dateinamen, den ein Artikel noch in seinem eigenen yEnc-Header angibt (ein Artikel pro Datei). Wenn der nichts bringt, greift es auf den PAR2-Index des Releases zurück. Der speichert zu jeder Datei den echten Namen, zusammen mit dem MD5-Hash der ersten 16 KiB. Name und exakte Länge stehen beide im Header des Artikels. Deshalb kann der Scan sofort antworten, sobald dieser Header ankommt, während der Body für einen späteren Lesezugriff in den Cache weiterläuft. Ein verschleiertes Release wird also durch dieselben Artikel benannt und in der Größe bestimmt. zurg protokolliert, was es wiederhergestellt hat:

```
Recovered 27 filename(s) in Some.Release
```

Der gesamte Namensdurchlauf ist auf 90 Sekunden pro NZB begrenzt. Ein nicht erreichbarer Server verzögert also einen Scan, hängt ihn aber nicht auf. Namen werden *vor* dem Aufbau der Bibliothek festgelegt, weil die Bibliothek Dateien über ihren Namen zuordnet und ein späteres Umbenennen sie verlieren würde.

**Ein vollständig verschleierter Post hat keinen echten Namen, der sich wiederherstellen ließe.** Manche Poster verschleiern die Dateien schon, bevor sie das Recovery-Set erstellen. Dann liefert der PAR2-Index Namen, die selbst zufällig sind (`aJPSgA7eYizyzjJXT.part01.rar`), und auch die Datei im Archiv ist nur ein Hash. Im Post steht nirgends, worum es bei dem Release geht. Nur der Name der NZB selbst verrät es. Deshalb zeigt zurg die Nutzdaten unter dem Release-Namen an, genau wie SABnzbd es am Ende des Entpackens macht:

```
Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR/
└── Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR.mkv
```

Umbenannt wird nur die Datei, die eindeutig das Release ist: der größte Eintrag im Archiv, und zwar nur dann, wenn er mindestens dreimal so groß ist wie der nächstgrößte. Außerdem darf seine Endung kein Teil einer Disc-Struktur sein (`.vob`, `.m2ts`, `.mpls`), und sein Name darf nichts aussagen. Untertitel und Samples, die denselben Namen teilen, folgen ihm. Ein Archiv mit mehreren Dateien ähnlicher Größe, etwa ein Staffel-Pack, bleibt unangetastet, weil keine davon das Release ist. Die ursprünglichen Namen im Archiv funktionieren weiterhin als Adressen. Ein Player, der vor einem erneuten Scan gestartet wurde, verliert die Datei also nicht.

### Ersetzen und Entfernen {#replacing-and-removing}

- **Das Entfernen** einer NZB aus `nzbs/` entfernt die Version aus der Bibliothek, verwirft ihren gecachten Reader und den Artikel-Cache und vergisst alle reparierten Bytes, die sie gehalten hat.
- **Das Löschen eines Usenet-Releases im Dashboard löscht die `.nzb`-Datei von der Festplatte.** Sie hat keinen anderen Ort, an dem sie liegen könnte. Das ist nicht dasselbe wie das Löschen eines Torrents aus einem Debrid-Konto, wo die Datei beim Dienst bleibt.
- **Eine NZB direkt zu überschreiben ist der langsame Weg.** Wenn du eine Datei überschreibst, ändert sich das Verzeichnis nicht, deshalb sieht die oben beschriebene Überwachung das nicht. Bemerkt wird es erst durch die regelmäßige Änderungsprüfung. Diese liest die Änderungszeit der Datei und parst sie neu, und zwar beim ersten `check_for_changes_every_secs`-Durchlauf, der mehr als 15 Sekunden nach dem letzten Verzeichnis-Lesen kommt (bei der Standardeinstellung etwa 30 Sekunden). Wenn du die alte Datei entfernst und die neue hinzufügst, wird das innerhalb von ein bis zwei Sekunden bemerkt. Genau so machen es ohnehin ein Indexer oder der SABnzbd-Endpunkt.

## 4. Wo die Releases im Mount landen {#4-where-releases-land-in-the-mount}

Eine Usenet-Veröffentlichung ist ein ganz normaler Bibliothekseintrag, daher gelten deine bestehenden `directories:`-Filter unverändert auch für sie:

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

Zusätzlich bekommt das Konto ein eigenes Verzeichnis: standardmäßig `__nzb__`, oder `__<name>__`, wenn du `name:` am Provider-Eintrag setzt. Dieses Verzeichnis ist nicht nur eine Ansicht: Lesezugriffe darin sind **fixiert** auf das Usenet-Konto, ohne Failover. Deshalb eignet es sich gut, um zu testen, ob die Wiedergabe über Usenet funktioniert, ohne dass stillschweigend ein Debrid-Konto einspringt. Wenn Usenet dein einziges Konto ist, wird dieser Ordner in der Root-Auflistung des Mounts ausgelassen, und `__all__` enthält dieselben Dateien. Teste die Wiedergabe also unter `__all__` im Mount oder über den direkten HTTP-Pfad `http://localhost:9999/http/__nzb__/`.

Vier Usenet-spezifische Dinge, die du beim Schreiben von Filtern wissen solltest:

- **Tag-Filter greifen bei Usenet-Inhalten, sobald sie analysiert sind.** Jeder `zurg_*`-Tag (Auflösung, HDR, Bitrate, Dauer, Sprache) kommt von ffprobe. zurg führt ffprobe bei Usenet-Dateien selbst aus, über den eigenen Server und in einem Tempo, das der News-Server verkraftet. Eine Usenet-Veröffentlichung bekommt ihre Tags also wie jede andere, sobald sie analysiert wurde. Bis dahin passt sie nicht zu einem Verzeichnis, das auf `tags_match_any` basiert.
- **`.par2`- und `.sfv`-Dateien sind versteckt.** Sie sind Reparatur-Gerüst; zurg liest sie selbst, und kein Medienserver braucht acht davon pro Staffel-Pack. `.nfo` bleibt sichtbar, weil Kodi, Emby und Jellyfin es lesen.
- **RAR-Sets sind Inhalt, keine Archive zum Entpacken.** `.rar` und `.rNN` bleiben sichtbar, und ein Volume-Set erscheint im Mount als *Ordner*, dessen Inhalt die Dateien darin sind. zurg streamt Videos direkt aus dem Archiv, ohne etwas zu entpacken. Eine Veröffentlichung, die *nur aus* einem Volume-Set besteht, ersetzt stattdessen ihren eigenen Inhalt, ohne Archivordner dazwischen: Die Nutzdatei liegt direkt im Release-Ordner, dort sucht ein Medienserver sie. Dateien, die neben dem Set gepostet wurden, also die `.nfo`, die `.txt` des Posters, Artwork und Untertitel, bleiben dort ebenfalls aufgelistet.
- **`force_select_playable_files` greift nicht.** Ein Usenet-Post ist vollständig; es gibt nichts auszuwählen. Jede Inhaltsdatei wird bereits angeboten.

Schau dir das Ergebnis an, bevor du einen Medienserver einbindest. `http://localhost:9999/http/` ist ein einfacher HTML-Index genau dessen, was der Mount anzeigen wird:

+++ Linux und macOS
```bash
curl -s http://localhost:9999/http/__nzb__/ | head
```
+++ Windows
Schreibe `curl.exe`, nicht `curl`: In Windows PowerShell 5.1 ist `curl` nur ein anderer Name für `Invoke-WebRequest`.

```powershell
curl.exe -s http://localhost:9999/http/__nzb__/ | Select-Object -First 10
```
+++

---

## 5. Mit rclone einbinden {#5-mount-it-with-rclone}

### Der einfache Weg: zurg lässt rclone laufen {#the-easy-path-let-zurg-run-rclone}

```yaml
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run
mount_path: "/mnt/zurg"        # /Volumes/Zurg on macOS, Z: on Windows
```

zurg startet rclone mit einem VFS-Profil, das bereits auf sein eigenes Leseverhalten abgestimmt ist (Puffergröße, Chunk-Größe, Cache-Modus, Dir-Cache-Zeit, Timeouts). Außerdem hält zurg den Mount am Laufen und invalidiert die richtigen Dircache-Einträge, wenn sich die Bibliothek ändert. `mount_path` ist außerdem das Präfix, das zurg verwendet, um Plex mitzuteilen, welche Pfade gescannt werden sollen. Deshalb muss es gesetzt sein, auch wenn du woanders mountest.

Prüfen:

+++ Linux
```bash
ls /mnt/zurg/
ls /mnt/zurg/__all__/
```
+++ macOS
```bash
ls /Volumes/Zurg/
ls /Volumes/Zurg/__all__/
```
+++ Windows
Starte es in einem PowerShell-Fenster auf deinem Desktop: Das Laufwerk ist nur in der Anmeldesitzung sichtbar, die es eingebunden hat ([die Sitzungsregeln](../setup/windows.md#keeping-it-running-the-session-rules)).

```powershell
Get-ChildItem Z:\
Get-ChildItem Z:\__all__\
```
+++

### Der manuelle Weg: dein eigenes rclone {#the-manual-path-your-own-rclone}

Wenn du rclone schon verwaltest, richte ein WebDAV-Remote auf zurg aus:

```ini
[zurg]
type = webdav
url = http://localhost:9999/dav/
vendor = other
pacer_min_sleep = 0
```

+++ Linux
rclone legt den Mount-Punkt nicht selbst an, und `/mnt` gehört root:

```bash
sudo mkdir -p /mnt/zurg && sudo chown "$USER" /mnt/zurg
rclone mount zurg: /mnt/zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ macOS
Du brauchst [macFUSE](../setup/macos.md#step-1-install-macfuse) und rclone von [rclone.org](https://rclone.org/downloads/): Das rclone von Homebrew kann nicht mounten. rclone legt den Mount-Punkt nicht selbst an, und `/Volumes` gehört root:

```bash
sudo mkdir -p /Volumes/Zurg && sudo chown "$USER" /Volumes/Zurg
rclone mount zurg: /Volumes/Zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ Windows
Du brauchst [WinFsp](https://winfsp.dev). Der Laufwerksbuchstabe darf nicht belegt sein, und nur Programme in der Anmeldesitzung, in der rclone läuft, sehen ihn ([die Sitzungsregeln](../setup/windows.md#keeping-it-running-the-session-rules)).

```powershell
rclone mount zurg: Z: --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++

`--vfs-handle-caching 0` braucht rclone 1.74 oder neuer und verhindert, dass rclone nach dem Schließen einer Datei durch einen Leser noch fünf Sekunden lang weiterlädt. Die README-Datei erklärt, was es kostet, das wegzulassen.

Setze `mount_path` in `config.yml` trotzdem auf den Ort, an dem du gemountet hast, sonst werden die Scan-Benachrichtigungen für den Medienserver mit dem falschen Präfix gebaut.

### Docker

Das Arbeitsverzeichnis von zurg im Image ist `/config`, und das Watch-Verzeichnis sowie der Repair-Cache liegen darunter. Ein einziger Bind-Mount übernimmt sie zusammen mit allem anderen:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:latest
    volumes:
      - ./:/config
    ports:
      - 9999:9999
```

Wenn du eine NZB in `./nzbs` auf dem Host ablegst, wird sie im Container ohne Neustart erkannt.

Dafür brauchst du einen Linux-Host für den Mount. Docker Desktop unter macOS und Windows führt den Container in einer VM aus, und der Mount erreicht weder den Finder, den Explorer noch ein auf dem Host installiertes Plex. Nutze dort stattdessen das [macOS](../setup/macos.md)- bzw. [Windows](../setup/windows.md)-Binary ([warum](../setup/docker.md)).

> Installationen, die noch vor der Einführung von `/config` erstellt wurden und `/app/config.yml`, `/app/nzbs` und `/app/data` separat per Bind-Mount eingebunden haben, funktionieren weiterhin genau wie bisher — siehe [docker.md](../setup/docker.md#upgrading-an-install-that-mounted-app).

---

## 6. Plex darauf verweisen {#6-point-plex-at-it}

1. **Gib zurg deine Plex-Zugangsdaten**, damit es Plex bitten kann, nur die Pfade zu scannen, die sich geändert haben, statt dass du auf einen periodischen Komplett-Scan warten musst. Am einfachsten geht das über den Plex-Auth-Ablauf im Dashboard, der die Werte zurück in `config.yml` schreibt:

   ```yaml
   plex_server_url: "http://localhost:32400"
   plex_token: YOUR_PLEX_TOKEN
   ```

2. **Füge Bibliotheken hinzu, die auf Unterordner des Mounts zeigen**, niemals auf die Mount-Wurzel:

   - Filme → `/mnt/zurg/movies` (`/Volumes/Zurg/movies` unter macOS, `Z:\movies` unter Windows)
   - Serien → `/mnt/zurg/shows` (`/Volumes/Zurg/shows` unter macOS, `Z:\shows` unter Windows)

   Unter Windows sieht Plex `Z:` nur, wenn es in derselben Anmeldesitzung läuft wie zurg. Das erreichst du mit der Anmelde-Aufgabe von `zurg setup`: siehe [die Sitzungsregeln](../setup/windows.md#keeping-it-running-the-session-rules).

   Dieselbe Veröffentlichung taucht in jedem Verzeichnis auf, dessen Filter sie trifft, und außerdem unter `__all__` und `__nzb__`. Zeigst du Plex auf die Wurzel, scannt es dieselben Dateien mehrfach.

3. **Stelle zwei Bibliotheksoptionen** unter Edit → Advanced jeder Bibliothek ein:

   - **Deaktiviere "Empty trash automatically after every scan".** Das ist die wichtigste. Wenn der Mount während eines Plex-Scans kurz ausfällt – ein zurg-Neustart, ein rclone-Remount –, schließt Plex, dass alle Dateien gelöscht wurden. Mit aktiviertem automatischem Leeren werden sie sofort und endgültig entfernt; ohne diese Option liegen sie im Papierkorb und kommen zurück, sobald der Mount wieder da ist. Das hat früher schon einmal eine Bibliothek mit 30.000 Einträgen gekostet.
   - **Deaktiviere "Generate video preview thumbnails".** Jedes Vorschaubild ist ein Sprung über die ganze Datei; bei Usenet bedeutet das ein komplettes Lesen der Veröffentlichung über dein Verbindungskontingent.

4. **Starte zurg nie während eines Plex-Scans neu.** Prüfe vorher:

   ```bash
   TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
   curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'
   curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l
   ```

   Unter Windows, in PowerShell aus dem zurg-Ordner:

   ```powershell
   $TOKEN = ((Select-String -Path config.yml -Pattern '^plex_token:').Line -split '\s+')[1].Trim('"', "'")
   (Invoke-RestMethod "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN").MediaContainer.size
   @((Invoke-RestMethod "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN").MediaContainer.Directory | Where-Object refreshing -eq 1).Count
   ```

   Sitzungen mit `size="0"` (`0` unter Windows) und ein sich aktualisierender Zähler von `0` bedeuten, dass es sicher ist. Gibt die Sitzungszeile gar nichts aus, hat Plex den Token abgelehnt oder nicht geantwortet, und die `0` darunter bedeutet nichts: prüfe `plex_token`, bevor du neu startest. (PowerShell zeigt die Ablehnung stattdessen als `401`-Fehler.) (Verwende `grep -o … | wc -l`, nicht `grep -c`: grep beendet sich mit einem Fehlercode, wenn nichts gefunden wird, und das ist der *gute* Fall. Dann bricht es eine `&&`-Kette genau vor dem Neustart ab, den sie absichern soll.)

5. **Teilscans.** `on_library_update` erhält jeden geänderten Pfad; `plex_update.sh` im Repo-Wurzelverzeichnis ist das Referenzskript:

   ```yaml
   on_library_update: sh plex_update.sh "$@"
   ```

   Das Skript braucht `curl`, `xmllint` und `python3`, die im Docker-Image enthalten sind, und die Zeile `zurg_mount` muss auf deinen Mount-Pfad gesetzt sein. Unter Windows läuft der Hook in PowerShell statt in `sh`, daher läuft dieses Skript dort nicht. Jeder geänderte Pfad kommt als ein Element von `$args` an, relativ zum Mount und mit Schrägstrichen (`movies/Big Buck Bunny`). Übergib sie mit `@args` an ein PowerShell-Skript:

   ```yaml
   on_library_update: '& C:\zurg\my_update.ps1 @args'
   ```

   zurg bittet Plex bereits, die geänderten Pfade zu scannen, sobald Schritt 1 erledigt und `mount_path` gesetzt ist. Ein Hook brauchst du also nur für alles Übrige.

**Was Plex bei Usenet-Inhalten nicht bekommt:** nichts, bis zurg sie analysiert hat (siehe Abschnitt 4). Daher kann Plex beim ersten Abspielen eigene Analysen durchführen, wie bei jeder lokalen Datei. Dateigrößen stabilisieren sich kurz nachdem eine Veröffentlichung gescannt wurde: Die erste Auflistung kann eine grobe Schätzung aus der Artikelanzahl zeigen, und die exakte Länge folgt danach. Sie kommt aus dem Recovery-Index, falls vorhanden, sonst aus einem Artikel pro Datei. Bei einem großen mehrteiligen Archiv, dessen Recovery-Index bereits jede exakte Länge angibt, kann ein verifizierter Teil den gemeinsamen Artikel-Abstand festlegen. Jede Schwesterdatei prüft diese Ableitung anhand ihres eigenen Headers, bevor sie das erste Byte ausliefert. Sobald eine Länge feststeht, wird der Bibliothek mitgeteilt, dass sich die Veröffentlichung geändert hat, sodass Mount und Plex beide die echte Länge sehen. zurg bereitet höchstens acht Veröffentlichungen gleichzeitig vor (nie mehr als die Verbindungen des Accounts) bei einem Account mit zwölf oder weniger Verbindungen, und mehr bei einem größeren (zwölf bei 16 Verbindungen, sechzehn ab 20). Wenn die Beschaffung eine Veröffentlichung bei den News-Servern prüft, reiht sich diese Prüfung neben dieser Größenbestimmung und dem Read-ahead ein. Sie nimmt nie die Verbindung weg, die für einen Lesezugriff reserviert ist, auf den ein Player gerade wartet.

### Jellyfin / Emby / Infuse

Jellyfin und Emby nehmen `jellyfin_server_url` / `jellyfin_token` bzw. `emby_server_url` / `emby_token` entgegen und bekommen dieselben Scan-Benachrichtigungen; siehe [jellyfin.md](jellyfin.md). Infuse kann direkt auf `http://<host>:9999/dav/` zeigen und rclone komplett überspringen.

## 7. Wenn ein Artikel fehlt {#7-when-an-article-is-missing}

Das ist der Fehlerfall, den Usenet hat und Debrid nicht. Artikel fallen aus der Aufbewahrungszeit eines Anbieters heraus oder werden entfernt, und ein Release kann im Index völlig in Ordnung aussehen, während ein paar seiner Artikel fehlen.

zurgs Antwort, in der Reihenfolge ihrer Priorität:

1. **Frag einen anderen News-Server.** Ein Artikel, den ein Anbieter schon hat auslaufen lassen, ist sehr oft noch bei einem anderen vorhanden. Das ist nur ein Abruf – siehe [Mehr als ein Usenet-Anbieter](#more-than-one-usenet-provider).
2. **Stell ihn aus den eigenen PAR2-Dateien des Releases wieder her.** Dafür werden sie schließlich mitgepostet. Das kostet ein Lesen des *gesamten Releases*, denn Reed-Solomon muss jeden verbleibenden Slice einrechnen, um einen fehlenden zu berechnen. Bei einem 200-GB-Post sind das also 200 GB Lesevorgänge, um ein paar Megabyte wiederherzustellen.
3. **Stille ausliefern.** Nur wenn keine der beiden oben genannten Optionen helfen kann.

Die PAR2-Reparatur läuft im Hintergrund, höchstens zwei Releases gleichzeitig, und sie braucht:

```yaml
enable_repair: true            # the default; set false to turn PAR2 repair off
par2_patch_cache_mb: 512       # budget for data/par2/; -1 keeps repairs in memory only
```

Die wiederhergestellten Bytes werden unter `data/par2/<nzb-id>/` abgelegt und beim nächsten Öffnen der Datei wieder aufgegriffen. Ein Neustart kostet also kein komplettes erneutes Lesen des Releases. Gespeichert werden nur die Bereiche, die wirklich fehlen. Ein beschädigtes Release kostet meist einstellige Megabyte. Überschreitet der Speicherplatz das Budget, werden ganze Releases zuerst entfernt, die am längsten nicht genutzt wurden. Die Bereiche jedes Releases bekommen den Änderungszeitstempel der NZB, aus der sie wiederhergestellt wurden. Wird eine NZB neu gespeichert, werden sie deshalb verworfen, statt Bytes an Offsets auszuliefern, die sich womöglich verschoben haben.

Eine Reparatur meldet sich an und nennt danach, was sie gekostet hat:

```
PAR2 repair of Some.Release: 5 slice(s) missing; reading the release to rebuild them
PAR2 repair of Some.Release rebuilt 5 slice(s) in 55s on the avx2 kernel, keeping 3.4 MiB of them (library holds 3.4 MiB in memory, 3.4 MiB on disk)
```

Zwei Dinge sollte man wissen:

- **Wiedergabe geht einer Reparatur immer vor.** Verbindungen werden nach Wartezeit vergeben: zuerst ein angeforderter Lesevorgang, dann Read-ahead, zuletzt eine Reparatur. Eine Ausnahme gibt es: Einer Reparatur ist gegenüber dem Read-ahead ein Viertel des Kontingents garantiert, damit die gerade abgespielte Datei die Lücke, an der sie hängt, trotzdem reparieren kann.
- **Die Reparatur auf Bibliotheksebene von zurgs hilft hier nicht.** Dieser Mechanismus fügt einen Torrent erneut dem Konto hinzu, aus dem er stammt. Ein Backend, das keine Inhalte hinzufügen kann, kann ein Release zwar als kaputt melden, aber nicht reparieren. Bei Usenet *ist* PAR2 die Reparatur.

Ein Release ohne PAR2-Dateien in seiner NZB und ohne zweites News-Konto hat überhaupt keinen Weg zur Wiederherstellung. Das liegt am Post selbst, nicht an zurg.

---

## Performance

Gemessen mit einem Live-Newsaccount mit großem Verbindungskontingent:

| | |
|---|---|
| Einzelner Stream, direkte Datei | ~100 Mbit/s |
| Einzelner Stream, aus einem RAR-Set | 90–106 Mbit/s |
| Zwei parallele Streams, gesamt | ~124 Mbit/s |

Das Verbindungskontingent setzt die erste Obergrenze für die Rate eines einzelnen Streams. zurg hält dieses Kontingent ausgelastet, indem es das Read-ahead sowohl nach Artikeln als auch nach Bytes bemisst: Archiv-Posts mit kleinen Artikeln bekommen mindestens 64 MiB Reichweite, während Posts mit mehreren Megabyte das Verbindungs- und Pipeline-Fenster behalten, das sie schon vorher hatten. Also:

- **Setz `connections` auf die echte Zahl deines Plans.** Das ist die Stellschraube. Acht Verbindungen streamen kein Remux.
- **Zwei Primary-Accounts addieren sich.** Reads werden mit dem kombinierten Kontingent der Nicht-`backup`-Accounts gefahren, die die niedrigste aktive `priority` teilen. Ein zweiter unlimitierter Anbieter mit derselben Priorität erhöht also die Obergrenze und deckt außerdem die Retention-Lücken des ersten ab. Ein `backup`-Account zählt dafür nicht.
- **`warm_connections` (standardmäßig 4) bringt Latenz, keinen Durchsatz.** Es hält so viele Verbindungen offen, im Leerlauf und authentifiziert, damit der erste Read nach einem Start oder einer ruhigen Phase nicht ~0,8 s fürs Wählen verbraucht, bevor das erste Byte kommt: 1,5 s bis zum ersten Byte kalt gegenüber 0,15 s warm. Sobald ein Stream läuft, ändert es nichts mehr.
- **Die Verbindungsaufbauten, die doch passieren, bleiben an einem Backend, damit ihre TLS-Sessions wieder aufgenommen werden.** Ein Verbindungsaufbau kostet etwa 0,8 s, gemessen an einem Live-Newsserver am 2026-08-29: 106 ms TCP, 213 ms TLS-Handshake, 256 ms Greeting, 218 ms für die beiden `AUTHINFO`-Austausche. Ein Provider-Hostname ist eine Rotation (dieser hier löst auf 11 Adressen auf), und ein TLS-Session-Ticket gilt nur auf der Maschine, die es ausgestellt hat. Wurde bei jedem Neuaufbau einfach die Adresse genommen, die der Resolver zuerst nannte, wurden **0 von 3** Sessions wieder aufgenommen. Wurde dieselbe Adresse erneut angewählt, waren es **3 von 3**. Jeder Account verbindet sich deshalb jetzt wieder mit der Adresse, von der seine letzte Verbindung kam. Das spart **110–140 ms bei jedem Neuaufbau**. Ein wieder aufgenommener Handshake dauert 109–141 ms, ein vollständiger 225–261 ms. Ein Server mit ~18 ms Round-Trip spart weniger. Der Pin wird gelöst und der Name neu aufgelöst, sobald diese Adresse nicht mehr antwortet, sodass nichts an einer Maschine hängen bleibt, die der Provider ausgemustert hat. Eine Ablehnung, die bis zum NNTP-Protokoll durchkommt (der Account ist an seinem Verbindungslimit oder ein Passwort wird abgelehnt), behält den Pin. Das ist die Antwort des Accounts und nicht des Backends. Jeder Verbindungsaufbau schreibt seine Phasen auf Debug-Level ins Log, inklusive `resumed=`.
- `cache_size_mb` (Standard 512) wird von allen Dateien geteilt, die gerade gelesen werden. Erhöh es, wenn du mehrere parallele Streams laufen lässt. Ein einzelner Stream wird dadurch nicht schneller. Spekulative Reads dürfen davon höchstens die Hälfte reservieren, und zwar für höchstens zwei Leser. Die andere Hälfte bleibt für Artikel, die schon verbraucht wurden oder gleich verbraucht werden.
- Ob ein Release RAR-verpackt oder als einzelne Dateien gepostet ist, spielt für den Durchsatz inzwischen kaum noch eine Rolle.

**Ein langsamer Artikel hält den Stream nicht mehr auf.** Ein sequenzieller Read mit durchschnittlich ~90 MB/s fällt trotzdem immer mal wieder für etwa eine Sekunde auf 1–5 MB/s ab. Jeder dieser Einbrüche hat dieselbe Ursache: Ein Artikel kommt nicht an, während die anderen Verbindungen ihre Artikel fertig laden und dann im Leerlauf stehen. Hängt ein Read länger an einem Artikel, als dieser Reader gelernt hat zu erwarten, fragt zurg eine **zweite Verbindung** nach demselben Artikel an und liefert, was zuerst ankommt. Ein hängengebliebener Pipeline-Batch kann mehrere aufeinanderfolgende Artikel des Playheads auf demselben toten Socket blockieren. Deshalb dürfen bis zu fünf verschiedene Artikel eines Readers zusammen gehedgt werden, bei Posts mit Artikeln unter 1 MiB ein oder zwei. Ein Artikel wird nie zweimal angefragt. Der Account zahlt trotzdem für höchstens 20 zweite Anfragen pro Minute. Die Frist bleibt das Doppelte der eigenen letzten Wartezeit des Readers, nie unter 250 ms (125 ms bei Posts mit Artikeln unter 1 MiB) und nie über 2 s. Gehedgt wird nur ein Read, auf den ein Client tatsächlich wartet. Read-ahead, Prefetch des nächsten Volumes und Repair sind ausgenommen. Ein Artikel, den die Server gerade *abgelehnt* haben, wird ebenfalls nicht gehedgt. Dafür wartet zurg ohnehin eine Sekunde später auf die eigene Bestätigung, und innerhalb dieses Fensters nachzufragen beweist nichts. Jeder Hedge schreibt eine Zeile auf Debug-Level, die sagt, wie lange der Read blockiert hat. Die folgende Zeile zeigt, ob die zweite Anfrage gewonnen hat.

Bei deklarierten Bereichen kommt der Playhead-Artikel in den Priority-Scheduler, bevor spätere Bytes angeboten werden. Pipelined-Verbindungen bekommen dann aufeinanderfolgende Artikelrunden statt zusammenhängender Blöcke zugeteilt. So verteilen sich die ersten brauchbaren Artikel über das ganze Kontingent. Eine Anfrage von mindestens 64 MiB gilt als Wiedergabe und bekommt die volle Range-Frontier. Ein kleiner Seek bleibt ein Probe und öffnet nur eine schmale Rampe.

### Eine Volume-Grenze überqueren {#crossing-a-volume-boundary}

Eine Datei in einem RAR-Set wird immer nur Volume für Volume ausgeliefert, und jedes Volume ist ein eigener Lesevorgang beim Usenet-Account. zurg öffnet das nächste Volume, während das aktuelle noch läuft, und liest dessen ersten vier Megabyte. Ein Übergang fängt also nicht kalt an. Bei einem Release mit kleinen Volumes reicht dieser Anfang aber allein nicht. Vier Megabyte sind bei einem Release mit ~395 KB großen Teilen etwa zehn Artikel. Und Volumes mit ~26 MB setzen alle 1,7 Sekunden Wiedergabe eine Grenze. Der Stream hat den vorgeladenen Anfang deshalb in einer Viertelsekunde aus dem Speicher geleert und musste danach auf alles Weitere einen Round-Trip warten. Gemessen auf einer Hetzner CCX23 mit zehn Verbindungen am 8. September 2026 lief dieses Release mit **14–16 MB/s**. Eine normale Datei auf demselben Account kam auf **86–99 MB/s**. Die Rate pro Sekunde schwankte zwischen 1 und 29 MB/s, und 46 bis 55 der 60 Read-Ahead-Slots des Accounts blieben ungenutzt.

zurg lädt das nächste Volume jetzt eine komplette Read-Ahead-Fenstertiefe vor, sobald der Stream bis auf 32 MiB an die Grenze herankommt. Ein Volume, in das der Stream gerade gewechselt hat, behält außerdem das Fenster, das es sich verdient hat, statt wieder bei zwei Artikeln anzufangen. Ein Volume, das die Abspielposition erst in mehreren Sekunden erreicht, wird weiterhin nur bis zu seinem Anfang vorgeladen. Dadurch zieht ein Bibliotheks-Scan, also ein Reader pro Eintrag mit ein paar Megabyte von jedem Eintrag, nicht für jedes nächste Volume ein ganzes Fenster, das nie gelesen wird. Du musst dafür nichts konfigurieren, und das Speicherlimit ändert sich nicht. Ein Account hält weiterhin zwei Read-Ahead-Fenster gleichzeitig, eins für das gerade gespielte Volume und eins für das vorgeladene, und beides liegt innerhalb von `cache_size_mb`.

Reparaturen sind von Natur aus langsam, weil sie das ganze Release lesen. Sie laufen aber mit Hintergrundpriorität, und ihr Tempo wird eher durch den Usenet-Server begrenzt als durch die Rechnung in zurg.

### Speicher: was ein Watch-Verzeichnis kostet {#memory-what-a-watch-directory-costs}

Eine NZB ist eine Liste von Artikeln, und eine große Bibliothek bedeutet sehr viele Artikel. Beim Parsen bleiben die Message-IDs und ihre Offsets im Speicher, damit ein Lesezugriff sie finden kann. Frühere Builds haben jede einzelne davon für die gesamte Laufzeit des Prozesses behalten. Gemessen an einem Watch-Verzeichnis mit 2,636 NZBs und 27.6 million `<segment>`-Elementen ergibt das **1.52 GB aktiven Heap**, etwa 58 Byte pro Artikel, zusätzlich zum Artikel-Cache. Fast nichts davon wird tatsächlich gebraucht: Eine Auflistung braucht nur Namen, Größen und Anzahlen, und nur eine Datei, die gerade gelesen oder repariert wird, muss wissen, wie ihre Artikel heißen.

`nzb_segments` legt fest, ob zurg sie behält:

```yaml
nzb_segments: mmap             # mmap (default) | reparse | resident
nzb_segments_idle_secs: 120    # how long a release's articles are kept after the last read
```

- **`mmap`** — Die Listen werden nach `data/nzb-index/<id>.bin` geschrieben, und diese Datei wird bei Bedarf gemappt. Die Bytes liegen dann im Page-Cache statt auf dem Heap von zurg, und der Kernel kann sie unter Speicherdruck freigeben. **Der Standard unter Linux, macOS und BSD.** Kostet ungefähr so viel Plattenplatz wie die Listen selbst.
- **`reparse`** — Die Listen werden freigegeben, sobald eine Veröffentlichung zur Ruhe gekommen ist. Die NZB wird bei einem Lese- oder Reparaturvorgang wieder von der Platte gelesen. Kostet überhaupt keinen Plattenplatz, und genau deshalb wählt man diesen Modus: auf einem Host, dessen `data/` nicht wachsen darf.
- **`resident`** — Jede Artikelliste ist immer im Speicher. **Das bisherige Verhalten**, so wie jeder frühere Build arbeitete. Wird weiterhin unterstützt, ist aber nicht mehr der Standard.

Egal, welche Option gesetzt ist, eine Auflistung lädt nie etwas. Name, Größe und Artikelanzahl einer Datei werden beantwortet, ohne dass die Artikelliste auch nur annähernd im Speicher liegt. Ein Bibliotheks-Refresh, eine Fingerprint-Prüfung und eine Anfrage von einem *arr, ob ein Job zur Ruhe gekommen ist, bleiben also kostenlos. Die Kosten der Lazy-Modi fallen beim ersten Lesen einer Veröffentlichung an, die `nzb_segments_idle_secs` lang unberührt war. Ein Durchlauf läuft alle 30 Sekunden. Alle Dateien einer Veröffentlichung werden gemeinsam geladen. Wer also die RAR-Volumes eines Season-Packs der Reihe nach durchgeht, zahlt das nur einmal.

Gemessen an einer Veröffentlichung mit 60 Dateien und 30,000 Segmenten:

| | Heap pro Veröffentlichung | Erstes Lesen einer inaktiven Veröffentlichung | Pro Artikel im Lesepfad |
|---|---|---|---|
| `resident` | 1.74 MB | — | 6 ns |
| `reparse` | 21.3 kB | 39 ms | 52 ns |
| `mmap` | 16.6 kB | 0.27 ms | 63 ns |

Fünfzig Nanosekunden pro Artikel sind nichts im Vergleich zu den Millisekunden, die das Abrufen eines Artikels dauert. Die Werte des Lesepfads fallen daher weniger ins Gewicht, als sie aussehen. Entscheidend ist das Nachladen: `reparse` liest und parst das gesamte XML-Dokument erneut. Bei einem Season-Pack dauert das Dutzende Millisekunden, bevor das erste Byte fließt. `mmap` ist dagegen ein `mmap`-Aufruf, ein Slice-Header pro Datei und eine Prüfsumme des gerade gemappten Index. Davon entfallen 0.08 ms auf den gesamten Vorgang, die übrigen 0.19 ms sind der Preis dafür, ein fehlerhaftes Byte zu erkennen, statt es als Message-ID auszuliefern.

Und hier das Ganze für eine komplette Bibliothek statt für eine einzelne Veröffentlichung: 2,636 NZBs, 27.6 million Artikel, derselbe Build dreimal über dasselbe Korpus laufen gelassen, jeweils im Leerlauf nach einem Scan:

| | Resident Set | Aktiver Heap | CPU im Leerlauf | Kaltstart-Öffnung, p50 | Index auf Platte |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

Warme Öffnungen (1 ms), Streaming-Durchsatz (38–39 MB/s) und Startzeit unterschieden sich bei allen drei nicht. `mmap` öffnet eine kalte Veröffentlichung *schneller* als das Halten aller Daten im Speicher. Eine Veröffentlichung, die in diesem Lauf noch nie geöffnet wurde, muss nämlich auch unter `resident` geparst werden. Das Mappen eines geschriebenen Arena-Bereichs ist dagegen ein Systemaufruf, während Parsen Megabytes an XML bedeutet.

Der Index wird jedes Mal neu geschrieben, wenn sich die NZB ändert. Ist er einmal nicht lesbar, repariert er sich selbst: Er fällt auf die NZB zurück und schreibt sie erneut. Verlässt die NZB das Watch-Verzeichnis, wird der Index entfernt. Sowohl Header als auch Inhalt sind mit Prüfsummen versehen, sodass ein fehlerhaftes Byte erkannt wird, statt als Message-ID ausgeliefert zu werden, die nie jemand gepostet hat. Wie groß der Index gerade ist, steht auf der Startseite des Dashboards unter **Article Index** und in der Zeile, die das Backend beim Start protokolliert. Unter **Windows** gibt es kein Mapping. Der Index würde stattdessen in den Heap eingelesen, was belegter Speicher *plus* ein erneutes Laden wäre. Deshalb bleibt der Standard dort `resident`, und `reparse` ist der Lazy-Modus, den man dort wählen sollte.

---

## Fehlerbehebung {#troubleshooting}

| Symptom | Ursache | Lösung |
|---|---|---|
| `Cannot reach the news server for nzb` beim Start | Falsche Kombination aus Host, Port und TLS, falsche Zugangsdaten oder ein inaktiver Tarif | `563` gehört zu `tls: true`, `119` zu `tls: false`; danach prüfe die Zugangsdaten noch einmal |
| Bibliothek ist leer, keine `Loaded NZB`-Zeilen | `nzbs/` fehlt oder liegt am falschen Ort | Der Pfad ist relativ zum **Arbeitsverzeichnis** von zurg. Prüfe `WorkingDirectory=` in deiner systemd-Unit oder das Verzeichnis, das in Docker unter `/config` eingebunden ist, also `nzbs/` neben der Compose-Datei. Nur eine Installation vor `/config` überwacht `/app/nzbs` |
| Eine NZB taucht nie auf | Liegt in einem Unterordner, heißt `.nzb.gz` oder ist nicht lesbar | Verschiebe sie direkt nach `nzbs/` und entpacke sie; prüfe das Log auf eine `Skipping`-Warnung |
| Release erscheint mit einem nutzlosen Namen | Der Dateiname der NZB wird als Name verwendet, solange kein `<meta type="name">` vorhanden ist | Benenne die `.nzb` in den Release-Namen um |
| Dateien haben im Release zufällige Namen | Verschleierter Post, dessen Wiederherstellung fehlgeschlagen ist | Prüfe auf `Recovered N filename(s)`. Ohne PAR2-Dateien in der NZB gibt es keine Quelle für die echten Namen |
| Das Video hat trotz richtigem Ordner noch einen zufälligen Namen | Ein vollständig verschleierter Post, in dessen Archiv mehrere Dateien ähnlicher Größe liegen | Nur eine eindeutige Hauptdatei wird auf den Release-Namen umbenannt. Ein Staffelpaket in einem Archiv behält die Namen, die ihm das Archiv gibt |
| Streaming ist langsam | `connections` steht auf dem Standardwert 8 | Setze den Wert auf das Kontingent deines Tarifs |
| Der erste Start nach einer Ruhephase dauert eine Sekunde, danach läuft alles gut | Die Warm-Untergrenze ist aus oder wird durch ein Konto mit nur einer Verbindung auf null gedeckelt | Lass `warm_connections` ungesetzt (der Standard ist 4) und prüfe, dass weder dieser Wert noch der oberste `warm_connections` negativ gesetzt ist |
| Verbindungen werden vom Anbieter abgelehnt | `connections` liegt über dem, was der Tarif erlaubt | Setze es auf den tatsächlichen Wert |
| Wiedergabe ruckelt oder eine Lücke spielt stumm ab | Fehlende Artikel | Suche im Log nach `PAR2 repair of …`, prüfe `enable_repair: true` und füge [einen weiteren Usenet-Anbieter](#more-than-one-usenet-provider) hinzu |
| Eine Lücke bleibt stumm und es erscheint nie eine Reparatur-Zeile | `enable_repair` ist aus, oder die NZB enthält keine `.par2`-Dateien | Setze `enable_repair: true`. Wenn der Post keine Wiederherstellungsdateien hat, kann nur ein weiteres Newskonto helfen |
| Ein zweiter Anbieter wird scheinbar nie gefragt | Beide Konten haben dasselbe `backbone`, daher wird das zweite übersprungen, sobald das erste meldet, dass der Artikel fehlt | Korrigiere die `backbone`-Werte. Nur Konten, die wirklich im selben Spool liegen, sollten einen Namen teilen |
| Eines von mehreren Konten ist tot, aber der Start sah normal aus | Der Start schlägt nur fehl, wenn *alle* Konten nicht erreichbar sind | Suche im Log nach `is not reachable`. Jedes defekte Konto warnt mit seinem Namen |
| Ein Blockkonto wird für Artikel berechnet, die das unbegrenzte Konto hat | `backup: true` fehlt bei ihm | Setze es. Wenn ein Primärkonto nur ausgelastet ist, werden Lesevorgänge danach nicht mehr auf das Blockkonto umgeleitet |
| Ein Release fehlt in einem tag-gefilterten Ordner | Es wurde noch nicht analysiert, daher trägt es keine `zurg_*`-Tags | Warte auf die Analyse oder starte Analyze & Tag Library im Dashboard |
| `.par2`-Dateien sind im Mount nicht sichtbar | Absichtlich, sie sind als Reparatur-Hilfsdateien versteckt | Nichts zu tun. zurg liest sie trotzdem |
| Anbieter im Dashboard geändert, aber nichts passiert | Anbieteränderungen werden in `config.yml` geschrieben, aber nicht im laufenden Betrieb neu geladen | Starte zurg neu. Der Hinweis unter der Anbieter-Tabelle sagt das |
| Plex hat die Bibliothek nach einem zurg-Neustart geleert | Ein Scan lief, während der Mount weg war, und auto-empty-trash war aktiv | Schalte auto-empty aus. Beende vor jedem Neustart zuerst Sitzungen *und* aktualisiere den Status |
| Die Größe einer Datei hat sich kurz nach dem Erscheinen des Releases leicht geändert | Die erste Auflistung kann die Größe nur anhand der Artikelanzahl schätzen. Die exakte Länge kommt danach aus dem PAR2-Index oder aus dem yEnc-Header der Datei | Das ist erwartet und pendelt sich einmal ein. Die Länge wird in `data/nzb-sizes/` gespeichert und bleibt, bis sich die NZB ändert |

### Nach einem einzelnen Artikel fragen {#asking-about-one-article}

`GET /debug/nzb/probe` stellt den News-Accounts eine einzelne Frage, und zwar über den Pool, den zurg ohnehin schon nutzt, mit der Priorität, die ein Demand-Read bekommt. Es gibt ihn, weil die Alternative nicht funktioniert hat: Ein Account stellt acht Verbindungen zur Verfügung, und zurg hält alle acht belegt. Einen Post von Hand zu prüfen hieß also entweder einen zweiten Account oder einen gestoppten Server, und den Server zu stoppen zerstört den Zustand, den du gerade diagnostizieren willst.
Unter Windows schreibst du in diesen Befehlen `curl.exe` statt `curl`.

```bash
# Is this article still there? A STAT, so nothing is transferred.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?message_id=abc@news.example'

# The same question addressed the way you have it: a release id from the
# library, a file index counting from zero, an article number counting from one.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&file=0&article=3'

# &body=1 fetches the one article and reports what actually arrived against what
# the article says should have. This is how a provider that strips trailing
# bytes is identified: `short: true` with `decoded_bytes` below `span_bytes`.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&article=3&body=1'
```

Die Antwort ist `{"probes": [...]}` mit einem Objekt für den Provider `nzb`: `found`, `missing` und wie lange es gedauert hat. Die Probe fragt die News-Accounts in Prioritätsreihenfolge ab, bis einer den Artikel hat (ein Backup erst dann, wenn die Primaries ihn nicht haben). Sie sagt nicht, welcher News-Account den Artikel hatte. Die Probe ist rein lesend: Was sie abruft, landet nicht im Artikel-Cache, und ein Artikel, den sie nicht findet, wird nicht als defekt markiert. So kann eine Probe eine Datei, die abspielt, nicht zum Verstummen bringen.

---

Noch nicht weitergekommen? Frag im Forum **zurg-support** auf [Discord](https://discord.com/invite/7u4YjMThXP). [Hilfe bekommen](../../guides/remote-help.md) sagt dir, was du angeben solltest.

## Siehe auch {#see-also}

- [config.md](../reference/config.md) — jede Option, einschließlich der [Referenz zu Usenet-Accounts](../reference/config.md#usenet-accounts) und der [Referenz zu Verzeichnis-Filtern](../reference/config.md#7-directories--filters)
- [plex.md](plex.md) — wie zurg das Scannen, Zuordnen und den Trash-Sweep in Plex steuert
- [jellyfin.md](jellyfin.md) — Jellyfin-Integration
- [docker.md](../setup/docker.md) — Docker-Setup, FUSE-Propagation und Fehlerbehebung
- [tags.md](../reference/tags.md) — das Tag-System
- [architecture.md](../internals/architecture.md) — `internal/nzb` und `internal/nntp` im Gesamtzusammenhang
