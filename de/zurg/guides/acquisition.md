# Erwerbsquellen {#acquisition-sources}

Deine Plex-Watchlist, deine [DMM-Wunschliste](#dmm-wanted-list), [Seerr](https://github.com/seerr-team/seerr),
[Radarr](https://radarr.video) und [Sonarr](https://sonarr.tv) nutzen eine gemeinsame Beschaffungs-Engine. Sie verfolgt den Fortschritt,
Wiederholungen und Bestätigungen. Newznab-Ergebnisse werden zu NZBs für zurgs Usenet-Backend. Torznab-Ergebnisse werden
zu Info-Hashes für ein Debrid-Konto. Siehe [Newznab und Torznab](#newznab-and-torznab).

Die Engine bestätigt einen Grab erst, nachdem sie ihn geprüft hat. Eine NZB muss den News-Server erreichen. Bei einem `torbox_nzb`-Konto muss stattdessen TorBox sie abrufen. Ein Torrent muss mit Dateien in der Bibliothek erscheinen. Siehe [Einen Grab prüfen](#verifying-a-grab).

Ein Release, das zurg gegrabbt hat, behält alle IDs des Titels, für den es gegrabbt wurde, und zwar jede, nach der Plex Titel zuordnet: IMDb, TMDB und bei einer Serie TVDB. Es wird nie anhand seines Namens erneut zugeordnet.
Diese IDs ersetzen alle IDs, die DMM oder der Release-Name ihm gegeben hat, aber niemals eine, die du selbst von Hand gesetzt hast. Ein Release, das schon in deiner Bibliothek war, als zurg es ausgewählt hat, wurde vielleicht für etwas anderes hinzugefügt. Deshalb übernimmt es die IDs nur, wenn es keine ID hat oder schon dieselbe hat.
Mit gesetztem [`rex_url`](../reference/config.md#rex) geht ein gegrabbter Film als dieser Film zu rex, anhand dieser IDs, auch wenn DMM ihn nicht einordnen konnte. Die Episoden einer Serie werden weiterhin nach DMMs Einordnung nummeriert und tragen die IDs der Serie. Beim Start macht zurg dasselbe für jedes Release, das seine gespeicherten Jobs früher gegrabbt haben. So werden Releases repariert, die ihre IDs vor dieser Änderung verloren haben.

## Konfiguration {#configuration}

```yaml
acquisition:
  quality: best
  prefer: usenet          # usenet (default), torrents, or best
  best_first: false       # true makes Radarr and Sonarr take the profile's best quality first
  max_size_gb: 0          # a cap on a film or episode, and each episode of a season pack; 0, the default, is none
  max_season_size_gb: 0   # a cap on each season a pack holds; 0, the default, is none
  exclude_words: [DV, HDR10+]  # never take a release whose name says these
  prefer_words: [FraMeSToR]    # take a release whose name says these first, within its resolution
  audio_languages: [original]  # take only releases with this audio (any one), read from the streams
  subtitle_languages: [en]     # and with these subtitles
  concurrency: 8          # titles worked on at once (default 8, at most 200)
  indexer_concurrency: 3  # calls to one indexer at once (default 3, at most 16)
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
      # type: newznab      # default, a Usenet indexer
    - name: my-trackers
      url: https://prowlarr.example
      api_key: YOUR_PROWLARR_API_KEY
      type: torznab        # a torrent indexer, handed to a debrid account
    - name: zilean
      url: http://zilean:8181/torznab
      type: torznab        # no api_key: Zilean takes none, and is asked without one
  sources:
    - name: plex-watchlist
      type: plex_watchlist
      enabled: true
      check_every_secs: 60
      remove_after_grab: true   # default; false keeps the watchlist intact
      only_new_items: true      # default; false works through the existing list
    - name: requests
      type: seerr
      enabled: true
      url: http://seerr:5055
      api_key: YOUR_SEERR_API_KEY
      check_every_secs: 60
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Radarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Sonarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
```

Führe das auf einer zurg-Instanz mit einem `nzb`-Provider oder einem `torbox_nzb`-Account (TorBox Pro) aus, einem Debrid-Account, der Torrents annimmt, oder beides. NZBs von Newznab-Indexern landen in seinem `nzbs/`-Verzeichnis. Ein `torbox_nzb`-Account hat keine Newsserver, gegen die geprüft wird. Ein Abruf dort wird stattdessen danach geprüft, ob TorBox ihn geholt hat. Torrents von Torznab-Indexern gehen an einen Debrid-Account. Sie werden nur hinzugefügt, wenn dieser Account sie bereits gecacht hat. Ohne einen der beiden Account-Typen starten die Quellen nicht. Die Acquisition-Seite erklärt warum. Plex braucht den vorhandenen `plex_token`. Seerr braucht seine Base URL und seinen API-Key, unabhängig von allen Plex-Einstellungen in zurg. URL-Subpfade und URLs, die auf `/api/v1` enden, werden unterstützt. Radarr braucht seine Base URL (eine URL-Basis wie `/radarr` und ein abschließendes `/api/v3` sind in Ordnung), seinen API-Key aus **Settings > General** und `library_path`, wenn es zurgs Mount unter einem anderen Pfad sieht: siehe [Radarr-Verhalten](#radarr-behavior). Sonarr nimmt dieselben drei Einstellungen: siehe [Sonarr-Verhalten](#sonarr-behavior).

Beide werden beim Start von zurg gelesen, wie der Rest des Blocks. `indexer_concurrency` gilt für Suchen und NZB-Downloads zusammen, weil ein Indexer den Key drosselt und nicht den Endpunkt. Indexer-Keys werden oft geteilt. Drei Aufrufe pro Key haben sich bei Keys, die auch eine andere Anwendung bedienen, als sicher erwiesen.

Namen und Seerr-URLs bitte stabil halten, denn sie identifizieren gespeicherte Warteschlangen. Das Rotieren eines Seerr-Keys behält seine Warteschlange. Nach dem Hinzufügen von Quellen oder dem Ändern ihrer URL oder Zugangsdaten zurg neu starten. Bestehende `watchlist:`- und `plex_watchlist_enabled`-Einstellungen funktionieren weiter über einen automatischen `plex-watchlist`-Adapter. Eine explizite `plex_watchlist`-Quelle hat Vorrang vor dem alten Enable-Schalter, auch wenn sie deaktiviert ist. Nur eine Plex-Quelle kann den konfigurierten Plex-Account nutzen. Gemeinsame Sucheinstellungen fallen auf `watchlist:` und dessen bestehende Standardwerte zurück. Nicht angegebene Indexer fallen auf die Watchlist-/Stremio-Indexer zurück.

## Releases nach Namen ausschließen {#excluding-releases-by-name}

```yaml
acquisition:
  exclude_words: [DV, HDR10+]
```

`exclude_words` listet Wörter auf, die kein beschafftes Release in seinem Namen haben darf.
Nutze es, um Dolby Vision oder HDR10+ von einem Player fernzuhalten, der diese nicht anzeigen kann,
während du trotzdem 4K nimmst. Es gilt für alle Quellen gleichermaßen: die Plex-Watchlist,
Seerr, Radarr und Sonarr. Es gilt für Usenet- und Torrent-Ergebnisse gleichermaßen. Ein
Release, das ausgeschlossen wird, wird nie geholt, gespeichert, einem Debrid-Konto hinzugefügt oder
an Radarr oder Sonarr übergeben. Lass es weg, wenn du nichts ausschließen willst. zurg liest es beim
Start, genau wie den Rest von `config.yml`.

## Releases nach Namen bevorzugen {#preferring-releases-by-name}

```yaml
acquisition:
  prefer_words: [FraMeSToR, CiNEPHiLES]
```

`prefer_words` listet Wörter auf, etwa Release-Gruppen, die ein Release unter den Releases seiner Auflösung nach vorne bringen. Abgeglichen wird es genauso wie `exclude_words`: ganze Wörter, egal ob groß oder klein geschrieben. Die Liste ist eine Reihenfolge: Ein Release mit dem ersten Wort kommt vor einem mit dem zweiten, und so weiter. Es ist eine Bevorzugung und kein Filter. Wenn kein Release eines der Wörter hat, nimmt zurg das, was es auch ohne sie genommen hätte.

Ein bevorzugtes Release wird nie vor eine höhere Auflösung gesetzt. Bei `quality: best` kommt ein 2160p-Release aus jeder Gruppe trotzdem vor einem bevorzugten 1080p-Release, und bei `quality: 1080p` kommt ein bevorzugtes 2160p-Release nicht vor die 1080p-Releases. Ein Upgrade auf eine höhere Auflösung passiert trotzdem, wenn die bevorzugte Gruppe kein Release in dieser Auflösung hat.

Es gilt für jede Quelle und für Usenet- und Torrent-Ergebnisse gleichermaßen. Bei einer `radarr`- oder `sonarr`-Quelle muss das Profil das bevorzugte Release trotzdem akzeptieren. Wenn Radarr oder Sonarr zurg als Download-Client nutzen, wählen sie das Release selbst aus, und `prefer_words` greift dort nicht. Lass es weg, dann wird nichts bevorzugt.

Ein Film-Release wird außerdem nie genommen, wenn sein Name ein Jahr angibt, das mehr als eins vom Jahr des Films abweicht, egal aus welcher Quelle. Indexer legen manche Beiträge unter der IMDb-ID eines anderen Films ab: DrunkenSlug legt The Aswang Chronicles (2012) unter dessen 2014er Fortsetzung ab. Ein Name ohne Jahr wird deswegen nicht abgelehnt. Für die DMM-Wunschliste, die jeden Titel schickt, unter dem ein Film bekannt ist (Original, Alternativen und Übersetzungen), wird auch ein Release abgelehnt, dessen Name keinen dieser Titel als Ganzes enthält: DrunkenSlug legt Przesluchanie (1982) unter An Affair (1982) ab, und `Rocky.2015` ist nicht *Rocky Horror Show Live*. Ein Name darf an der Stelle enden, an der der Untertitel eines Titels beginnt, nach einem Doppelpunkt oder einem Strich mit Leerzeichen, sodass `Diana.2021` zu *Diana: The Musical* passt. Akzente und Umlaute werden in beiden Richtungen abgeglichen, daher zählen `Les.Miserables` und `Verwuenscht.nochmal`.

So wird ein Name abgeglichen:

- **Nur ganze Wörter.** Ein Name wird als Wörter aus Buchstaben und Ziffern gelesen. Punkte, Leerzeichen, Bindestriche, Unterstriche, eckige und runde Klammern trennen alle Wörter. Groß- und Kleinschreibung spielt keine Rolle. `DV` schließt `Avengers.Infinity.War.2018.DV.2160p.WEB.H265-RVKD` und `Mortal_Kombat_II_2026_COMPLETE_BLURAY_2160p_DV_HDR_TrueHD` aus. Es schließt `DVDRip`, `DVD9`, `Come and See DvD 1` oder einen Titel wie *Adventures* nicht aus, weil keiner davon das Wort DV enthält.
- **Wortgruppen werden in Reihenfolge abgeglichen.** `Dolby Vision` oder `DV HDR` treffen, wenn genau diese Wörter in dieser Reihenfolge nebeneinanderstehen, egal womit sie getrennt sind.
- **Ein nachgestelltes `+` gehört zum Wort.** `HDR10+` ist ein eigenes Wort. Wenn du `HDR10` ausschließt, bleiben HDR10+-Releases unberührt, und wenn du `HDR10+` ausschließt, bleibt einfaches HDR10 unberührt. Trag beide ein, um beide auszuschließen. Ein `+` zwischen zwei Wörtern trennt sie, wie in `DD+7.1` oder `DV+HDR10`.
- **Zwei Schreibweisen-Familien zählen als ein Wort.** Jede Schreibweise in der Liste schließt jede Schreibweise ihrer Familie aus.

  | Schreibe eine davon | Schließt Namen mit einer davon aus |
  |---|---|
  | `DV`, `DoVi`, `Dolby Vision`, `DolbyVision` | `DV`, `DoVi`, `Dolby.Vision`, `Dolby-Vision`, `Dolby Vision`, `DolbyVision` |
  | `HDR10+`, `HDR10Plus` | `HDR10+`, `HDR10Plus` |

  Nichts anderes wird zusammengefasst. `HDR` schließt Namen mit dem Wort HDR aus, aber nicht `HDR10`, `HDR10+` oder `HDRip`. `WEB-DL` trifft `WEB-DL`, `WEB.DL` und `WEB DL`, nicht aber `WEBDL`.
- **Nur der Release-Name wird gelesen.** Das ist der Titel, den der Indexer liefert, bevor etwas heruntergeladen wird. Die Dateien darin werden nicht gelesen. Ein Dolby-Vision-Release, dessen Name das nicht sagt, wird nicht ausgeschlossen.

Ein ausgeschlossenes Wort verändert die Auflösung nie. Mit ausgeschlossenem `DV` wird ein 2160p-Release mit einfachem HDR oder HDR10 trotzdem genommen, und `quality: 4k` setzt 2160p weiterhin nach vorne. Ein ausgeschlossenes Release zählt als nicht gefunden. Eine Film- oder Episodensuche blättert bei jedem Indexer weiter, bis sie zehn Releases hat, die sie nehmen darf, dem Indexer die Ergebnisse ausgehen oder zehn Seiten gelesen sind. Eine Staffelsuche liest eine Seite und sucht danach separat nach jeder Episode, die auf dieser Seite keine hat. Ein Titel, dessen Releases alle ausgeschlossen sind, schlägt mit "no eligible releases" fehl, genau wie einer, dessen Releases alle über `max_size_gb` liegen, und wird später erneut versucht. Eine Seerr-4K-Anfrage nimmt nur 2160p-Releases, daher wartet sie, wenn alle 2160p-Releases ausgeschlossen sind.

### Ausschlüsse und Radarr- oder Sonarr-Profile {#exclusions-and-radarr-or-sonarr-profiles}

Bei einer `radarr`- oder `sonarr`-Quelle kommt der Ausschluss zuerst. Eine ausgeschlossene Release wird nie an den Parser von Radarr oder Sonarr weitergegeben. Kein custom-format-Score holt sie zurück, und sie zählt auch nicht als Ablehnung durch das Profil. Jede andere Release bewertet das Profil so, wie unter [Radarr-Verhalten](#radarr-behavior) und [Sonarr-Verhalten](#sonarr-behavior) beschrieben. Eine Release muss beide Prüfungen bestehen. Ein custom format, das Dolby Vision unter das Mindest-Score des Profils drückt, macht dasselbe innerhalb der *arr. Es schadet nicht, es drin zu lassen.

Für Upgrades gilt dieselbe Regel. Wenn die einzigen Releases, die eine Datei auf den Cutoff ihres Profils heben würden, ausgeschlossen sind, bleibt die Datei unter dem Cutoff, und zurgs Upgrade-Durchlauf sucht weiter, ohne etwas zu übernehmen. Das passiert, wenn ein custom format Dolby Vision einen hohen Score gibt und der Cutoff-Score genau diesen braucht. Senke dann den Cutoff-Score oder nimm den Score für Dolby Vision aus dem custom format heraus.

Wenn Radarr oder Sonarr zurg über den Block `sabnzbd:` oder `qbittorrent:` als Download-Client nutzen, suchen sie in ihren eigenen Indexern und wählen die Release selbst aus. `exclude_words` greift dort nicht. Schließe dieselben Wörter in der *arr aus: entweder mit einem custom format, dessen Score unter dem Mindest-Score des Profils liegt, oder mit **Must Not Contain** in einem Release-Profil.

## Auswahl nach Audio- und Untertitelsprache {#choosing-by-audio-and-subtitle-language}

```yaml
acquisition:
  audio_languages: [original]   # or [de], [de, en], ...
  subtitle_languages: [en]
```

`audio_languages` nimmt nur Releases mit einer Tonspur in einer der aufgelisteten Sprachen, und `subtitle_languages` nur Releases mit einer Untertitelspur in einer davon. Lass eine der beiden weg, dann wird dafür nichts abgefragt. Beide gelten für jede Quelle.

Jede Liste ist außerdem eine Reihenfolge: Ein Torrent mit einer früheren Sprache kommt vor einem, der nur eine spätere hat. `[de, original]` nimmt eine deutsche Synchronisation, wenn es eine gibt, und die Originalsprache, wenn nicht.

zurg liest die Sprache aus den Streams des Releases, nicht aus dessen Namen. Die meisten Releases nennen ihre Sprachen nicht: Fast keines von Parasite's Releases enthält KOREAN im Namen. Schreib ISO-639-Codes mit zwei oder drei Buchstaben: `en`, `eng`, `de`, `deu` und `ger` funktionieren alle. Ein Name wie `german` wird beim Start abgelehnt.

Manche Sprachen haben Synchronisationen oder Untertitel, die sich unterscheiden, und ein Code kann eine davon benennen:

| Schreib | Für |
|---|---|
| `es-419`, `es-ES` | Lateinamerikanisches (Latino) oder kastilisches Spanisch |
| `pt-BR`, `pt-PT` | Brasilianisches oder europäisches Portugiesisch |
| `fr-CA`, `fr-FR` | Québécois (VFQ) oder Französisch aus Frankreich (VFF, VFI) |
| `nl-BE` | Flämisch |
| `yue`, `cmn` | Kantonesisch oder Mandarin |
| `zh-Hant`, `zh-Hans` | Traditionelle oder vereinfachte chinesische Untertitel (`zh-TW` und `zh-HK` gelten als Traditionell, `zh-CN` als Vereinfacht; für kantonesische Tonspur schreib `yue`) |
| `nb`, `nn` | Norwegisch Bokmål oder Nynorsk |

Der einfache Code nimmt alle davon: `es` nimmt Latino und Kastilisch, `zh` Kantonesisch und Mandarin, `no` Bokmål und Nynorsk. Ein Teil nach der Sprache, den zurg nicht lesen kann, etwa `es-latam`, wird beim Start abgelehnt. zurg erkennt an dem Titel eines Tracks, welche Variante es ist, weil die Streams sie nie in einer Form enthalten, die zurg lesen kann: "Latino", "Spanish (Latin American)", "Castellano", "French (Canada)", "VFQ", "Portuguese (Brazilian)", "Chinese (Cantonese)", "繁体中字". Ein Track, dessen Titel keins davon sagt, wird deswegen nie abgelehnt. Der Releasename entscheidet bei Gleichstand, wenn er eine Variante nennt, etwa `Dual-Lat`, `[Castellano]`, `MULTi.VFQ`, `VF2`, `PT-BR` oder `[ES-LA]`. Ein Name lehnt nie etwas ab, und der Titel eines Tracks hat Vorrang.

Bei `[es-419, es]` nimmt zurg der Reihe nach: einen Track mit dem Titel Latino, einen ohne Titel in einem Release namens Latino, einen ohne Titel, einen ohne Titel in einem Release namens Castellano und einen Track mit dem Titel Castellano. Für einen lateinamerikanischen Haushalt:

```yaml
acquisition:
  audio_languages: [es-419, es]  # Latino first, then Castilian
  subtitle_languages: [es]
  audio_or_subtitles: true       # or any audio with Spanish subtitles
```

`audio_or_subtitles: true` nimmt ein Release, das die Tonspur oder die Untertitel hat, statt beides zu verlangen. Ein Release mit Tonspur kommt vor einem, das nur Untertitel hat.

`original` bedeutet die Sprache, in der der Titel gedreht wurde, so wie TMDB sie einträgt: Koreanisch für Parasite, Französisch für Anatomie eines Falls. zurg fragt DMM danach, daher braucht es `dmm_api_key`. Ohne den Schlüssel fragt `original` nichts ab.

### So wird ein Release bewertet {#how-a-release-is-judged}

- **Bevor ein Torrent hinzugefügt wird.** DMM speichert die ffprobe-Daten jedes Releases, das ein
  zurg analysiert hat. Mit gesetztem `dmm_api_key` liest zurg diese Daten für jedes Torrent-Ergebnis in einem einzigen Aufruf aus. Ein Torrent, dessen Streams die Sprache nicht haben, wird nie hinzugefügt. Einer, der sie hat, kommt vor die Torrents, über die nichts bekannt ist. Bei einer Messung von fünf Filmen am 2026-10-25 hatte DMM diese Daten für etwa ein Drittel der Torrents, die Real-Debrid gecacht hatte.
- **Nach dem Abruf.** Jeder Abruf, Torrent oder Usenet, wird einmal geprüft, sobald er in der Bibliothek ist: mit den Daten von DMM, wenn DMM sie hat, sonst mit ffprobe. Ein Abruf, dessen Streams die Sprache nicht haben, wird wie ein toter Beitrag aussortiert. Er wird vom Debrid-Konto entfernt oder aus dem Watch-Verzeichnis genommen, und der nächste Kandidat wird sofort probiert. Das Dashboard zeigt den Grund an, zum Beispiel "it has no English audio, only French".
- **Ein Upgrade behält seine Sprachen.** Wenn die DMM-Wunschliste einen Film auf eine bessere Auflösung hochstuft, muss das neue Release mindestens die Sprachen haben, die in deinen Listen weiter vorne stehen als in der Kopie, die es ersetzt. Eine Latino-1080p-Kopie wird nicht gegen eine kastilische 2160p-Version getauscht.
- **Unbekanntes wird genommen.** Ein Release wird nie abgelehnt, weil etwas nicht gelesen werden kann. Dazu zählen Spuren ohne Tag, eine Spur mit dem Tag `und` oder `mul`, ein Release, das nur über seine Archive erreichbar ist, oder keine Prüfung innerhalb einer Minute. zurg protokolliert, dass es das Release so genommen hat, wie es ist.

Kommentar- und Audiodeskriptionsspuren zählen nicht als Tonspur des Films, und Kommentar-Untertitel zählen nicht als Untertitel des Films. Das gilt auch für einen Kommentar, der nur im Titel so heißt, etwa Parasites "Commentary by Bong Joon Ho". Untertitelspuren mit dem Titel forced (forzados, forcés), signs oder songs zählen nicht als Untertitel. Das forced-Flag allein schließt eine Spur nicht aus: Remuxes ausländischer Filme markieren ihre vollständigen englischen Untertitel als forced, damit die Player sie anzeigen.

Nur die Hauptvideodateien eines Releases werden geprüft, also diejenigen, die mindestens ein Fünftel so lang sind wie die längste. Extras haben oft weniger Synchronfassungen als der Film. In einem Staffelpaket muss jede Folge die Sprache haben.

Ein Release, das wegen seiner Sprache aussortiert wurde, bleibt 30 Tage aussortiert, wie ein toter Beitrag auch, selbst wenn du die Sprachen änderst.

## DMM-Wunschliste {#dmm-wanted-list}

Ein DMM-Sponsor fügt Filme und Serien mit dem **Want**-Button auf seinen Seiten bei debridmediamanager.com zu einer Wunschliste hinzu, und sie erscheinen dann unter `/wanted`. zurg liest diese Liste, sobald `dmm_api_key` gesetzt ist. Mehr musst du nicht schreiben: Nichts wird eingehängt, und weder Sonarr noch Radarr sind beteiligt. Die Quelle heißt `dmm-wanted` und wird alle 60 Sekunden abgefragt.

- **Was abgerufen wird.** Ein Film einmal, dann jedes Upgrade davon (siehe unten), oder eine Kopie in jeder von mehreren Auflösungen, wenn `quality` eine Liste ist (siehe unten). Von einer Serie die bereits ausgestrahlten Folgen in den gewünschten Staffeln, oder in jeder Staffel, wenn die ganze Serie gewünscht ist, und ihre neuen Folgen, sobald sie ausgestrahlt werden.
  DMM sendet die IMDb-, TMDB- und TVDB-IDs jedes Titels, sein Jahr und bei einer Serie die bisher ausgestrahlten Folgen, nummeriert so, wie TMDB sie nummeriert. Specials werden nie abgerufen. Eine Staffel, die noch läuft, wird als einzelne Folgen abgerufen, da noch kein Pack sie abdeckt.
- **Wann gesucht wird.** Ein Film wird gesucht, sobald er zu Hause herauskommt: DMM sendet den Tag seiner frühesten digitalen, physischen oder TV-Veröffentlichung, sofern TMDB einen kennt. zurg wartet nicht länger als bis zu diesem Tag und sucht dann alle zwei Minuten sechs Stunden lang und danach alle zehn Minuten bis zwei Tage später, so wie bei einer [neuen Folge](#sonarr-behavior). Nie ein Kinostart: Ein WEB-DL wird mit der digitalen Veröffentlichung hochgeladen. Die neueste Folge einer Serie wird auf dieselbe Weise datiert, ab der Stunde, zu der sie ausgestrahlt wurde, wenn DMM sie kennt. Ein Titel ohne Datum behält die üblichen Wiederholungen, höchstens eine Woche auseinander, und nichts auf der Liste wird jemals [geparkt](#persistence-and-recovery). Ein Film, der auf seinen nächsten Versuch wartet, wird beim nächsten Abruf gesucht, sobald DMM einen neuen Usenet-Beitrag sieht, der ihn nennt.
- **Wohin es geht.** Wie bei jeder anderen Quelle: eine NZB von einem Newznab-Indexer an das Usenet-Backend dieser Instanz, oder ein Torrent von einem Torznab-Indexer auf ein Debrid-Konto, das ihn bereits im Cache hat, je nachdem, was `prefer` zuerst ansteuert. `quality`, `max_size_gb` (pro Folge bei einem Staffel-Pack), `exclude_words` und die [Sprachen](#choosing-by-audio-and-subtitle-language) gelten, dazu `max_season_size_gb`, wenn du es schreibst.
- **Indexer.** Ohne einen Indexer unter `acquisition:`, `watchlist:` oder `stremio:` durchsucht der Schlüssel auch DMMs eigene: dessen Usenet-Indexer und die Torrents, von denen DMM weiß, dass Real-Debrid oder AllDebrid sie haben (`/api/torznab/cached`). Wenn du einen Indexer schreibst, ersetzt er beide.
- **Bestätigung.** Sobald der Download eines Films geprüft ist, meldet zurg das an DMM, und der Film verschwindet von der Liste, die zurg liest, es sei denn, er wartet auf ein Upgrade oder auf eine weitere seiner Kopien (siehe unten). `/wanted` zeigt, wann das passiert. Eine Serie bleibt auf der Liste und wird weiter verfolgt, bis du sie dort entfernst. Wenn du einen Titel entfernst, hört zurg auf, daran zu arbeiten.
- **Upgrades.** Ein Film, dessen Release-Name eine Auflösung unter der angibt, die `quality` anstrebt (2160p für `best` und `4k`, 1080p für `1080p`, 720p für `720p`), bleibt auf der Liste. zurg holt ein Release mit einer höheren Auflösung als die Kopie, die es hat, sobald eines erscheint, bis es diese besitzt. Sobald die bessere Kopie ihre Prüfung besteht, wird die alte entfernt, sofern zurg sie geholt hat, ab dem nächtlichen Lauf vom 2026-10-30: ein Torrent vom Konto, dem zurg ihn hinzugefügt hat, oder eine NZB aus dem Watch-Verzeichnis. Eine Kopie, die schon dir gehörte, bleibt erhalten, ebenso eine, bei der etwas davon unter `__magic__` abgelegt wurde, etwa durch einen Radarr-Import. Ein Release, dessen Name keine Auflösung angibt, wird nie aktualisiert, und `quality: smallest` aktualisiert gar nichts. Bis ein besseres Release auftaucht, wird der Film etwa einmal pro Woche gesucht, und er wird nie [geparkt](#persistence-and-recovery). Standardmäßig aktiv; `upgrades: false` im `acquisition:`-Block schaltet es ab.
- **Eine Kopie in jeder von mehreren Auflösungen.** Wenn `quality` als Liste geschrieben ist, etwa `[1080p, 4k]`, wird von jedem Film eine Kopie in jeder Auflösung darin behalten. Siehe [eine Kopie in jeder von mehreren Auflösungen](#a-copy-at-each-of-several-resolutions).
- **Ohne Download-Konto.** Eine Instanz ohne `nzb`-Provider, ohne `torbox_nzb`-Konto (TorBox Pro) und ohne Debrid-Konto, das Torrents annimmt, liest die Liste nicht.

**Zwei zurgs mit demselben Schlüssel holen beide jeden Titel.** Beide lesen dieselbe Liste, also lass die Wunschliste auf einem laufen und schalte sie auf den anderen aus, indem du sie dort deaktiviert schreibst:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

Ein ausgelaufenes Sponsoring oder ein zurückgesetzter Schlüssel stoppt die Liste. zurg protokolliert eine Warnung, dass DMM `dmm_api_key` abgelehnt hat, und fragt eine Stunde später wieder nach, oder sofort, wenn du einen neuen Schlüssel setzt. Was schon abgerufen wurde, bleibt in deiner Bibliothek.

### Eine Kopie pro Auflösung {#a-copy-at-each-of-several-resolutions}

Schreib `quality` als Liste, damit jeder Film auf der Wunschliste in jeder Auflösung eine Kopie behält, zum Beispiel damit ein 1080p-Fernseher ihn abspielt, ohne dass die 4K-Datei transkodiert werden muss:

```yaml
acquisition:
  quality: [1080p, 4k]
```

Jede Kopie nimmt die beste Version bis zu ihrer eigenen Auflösung und nie eine darüber. Die 1080p-Kopie nimmt keine 2160p-Version und keine, deren Name keine Auflösung angibt, weil die alles Mögliche sein könnte. Die 4K-Kopie nimmt so eine Version nur, wenn keine Version mit angegebener Auflösung mehr zu holen ist. Dann behält sie sie für immer, weil eine Version ohne Auflösungsangabe nie aufgewertet wird. Jede Kopie wird für sich aufgewertet, bis zu ihrer eigenen Auflösung. Wenn beide dieselbe Version nehmen würden, teilen sie sich eine Kopie. Die wird erst entfernt, wenn keine von beiden sie mehr hält:

| Releases da | 1080p-Kopie | 4K-Kopie | In deiner Bibliothek |
|---|---|---|---|
| 720p | die 720p | dieselbe 720p | die 720p |
| + 1080p | wird auf die 1080p aufgewertet | wird auf die 1080p aufgewertet | die 1080p |
| + 2160p | bleibt | wird auf die 2160p aufgewertet | die 1080p und die 2160p |

Ein Film, der nur in 2160p erscheint, bekommt seine 4K-Kopie sofort und seine 1080p-Kopie, sobald eine Version mit 1080p oder weniger auftaucht. Bis dahin wird etwa einmal pro Woche danach gesucht, und er wird nie geparkt. Der Film verschwindet von der Liste, die zurg liest, erst dann, wenn jede Kopie eine Version hält, die sie nicht besser haben will.

- **Was die Liste annimmt.** Zwei oder mehr von `4k` (oder `2160p`), `1080p` und `720p`, jeweils einmal, in beliebiger Reihenfolge und Groß-/Kleinschreibung. zurg startet bei allem anderen nicht und meldet `acquisition.quality lists resolutions, each once: 4k, 1080p or 720p`. Eine Liste mit einem Eintrag wird als dieser eine Wert gelesen, also ist `[1080p]` gleich `quality: 1080p` und behält eine Kopie. Schreib dort `4k`, denn `[2160p]` wird abgelehnt.
- **Nur im `acquisition:`-Block.** `quality` unter `watchlist:` ist ein einzelner Wert, eine Liste dort verhindert den Start von zurg. Die Qualitätseinstellung auf der Konfigurationsseite ändert nur `watchlist.quality` und bewirkt nichts, solange `acquisition.quality` geschrieben ist.
- **Nur Filme auf der DMM-Wunschliste.** Serien auf dieser Liste und alle anderen Quellen bekommen trotzdem nur eine Kopie, ausgewählt so, als würde `quality` nur die höchste aufgelistete Auflösung nennen: `[1080p, 4k]` funktioniert für sie wie `quality: 4k`, und `[720p, 1080p]` wie `quality: 1080p`, was auch dann eine 2160p-Version nimmt, wenn keine 1080p-Version draußen ist.
- **Mit `upgrades: false`** behält jede Kopie die erste Version, die sie bekommt. Solange nur eine 720p draußen ist, sind beide Kopien dauerhaft diese 720p.
- **Filme, die vor dem Schreiben der Liste geholt wurden,** werden erneut geholt, eine Kopie in jeder Auflösung. Eine Kopie, deren beste Version schon in deiner Bibliothek ist, übernimmt sie so, wie sie ist. zurg entfernt die früher geholte Kopie nie. Lösch sie selbst, wenn die neuen Kopien sie ersetzen sollen.
- **Zurück zu einem Wert** lässt die Kopien, wo sie sind.
- **`/wanted` zeigt den Film als geholt,** sobald seine erste Kopie da ist, mit der ersten Version, die zurg genommen hat. Es zeigt nicht an, welche Auflösung noch wartet. Ein Film, der vor dem Schreiben der Liste geholt wurde, kann weiterhin „waiting for“ mit der Auflösung anzeigen, auf die er damals gewartet hat.

### Einen Film von YouTube streamen {#streaming-a-film-from-youtube}

Many wanted films no indexer carries are on YouTube, uploaded whole by the studio that
made them. With `acquisition.youtube` set, zurg streams such a film from that upload
instead of leaving it unfetched. Nothing is downloaded.

```yaml
acquisition:
  youtube:
    cookies: /home/you/zurg/youtube-cookies.txt   # required: a signed-in account's cookies (Netscape format)
    # ytdlp_binary: yt-dlp                        # default; the standalone build
    # js_runtime: node                            # default; yt-dlp needs one to read YouTube's player
    # channels: [UC1D36wr10qyCfisHulZ5G8Q]       # the channel ids uploads are taken from
    # searches_per_hour: 20                       # default; films looked for on YouTube in an hour
```

- **When.** Only for a film on the DMM wanted list, and only when nothing the indexers
  return can be taken: no release passes `quality`, `max_size_gb`, `exclude_words` and
  the title and year checks, or every one was found gone, with every indexer answering.
  Never for a show or an upgrade, nor with `audio_languages` or `subtitle_languages`
  set, since an upload's languages cannot be read. Only the wanted list takes a stream:
  a film the Plex watchlist also wants is not settled for it by one, since Plex cannot
  play it, and the watchlist keeps looking for a release.
- **How often.** At most `searches_per_hour` films are looked for in an hour (20 by
  default: 1,820 films take four days), one at a time. A film YouTube has nothing for is
  asked about again a day later, restarts included.
- **Which upload.** zurg searches YouTube for the title and year, and for the original
  title when DMM sends one, and takes an upload only when all of these hold: it is on
  one of `channels`; it runs at least 90% of the film's runtime, or an hour when DMM does
  not know the runtime; its title begins with the film's title (`'Separada' FULL MOVIE |
  ...`), states no other year, and is no trailer, teaser, clip or `Part N`. Of those it
  takes the longest, then the most watched, and checks that YouTube streams it with
  picture and sound together.
- **Channels.** The default list is the Philippine studios' own channels: ABS-CBN Star
  Cinema, Regal Entertainment, VIVA Films, SOLAR WATCH NOW, OctoArts Films, CineMo and
  Cinema One. Of 100 random unfetched films on one wanted list (2026-10-31), 65 had a
  full-length upload and 33 were on these channels; the rest were re-uploads (every
  Disney one) and, for new releases, scams titled "full movie". Writing `channels`
  replaces the list. A channel's id is the `UC...` part of its address, or what
  `yt-dlp --print channel_id <a video's page>` prints.
- **What you get.** The film is named `Title.Year.1080p.YouTube.WEB-DL` and DMM is told
  it was fetched (`youtube:<video id>`). rex gets it as an HLS item in your movies
  library, read through zurg. Jellyfin and Kodi get
  `__magic__/__movies__/Title (Year) {tmdb-N}/Title (Year) {tmdb-N}.strm`, with `__magic__`
  on. The address in the `.strm` is zurg's own, from [`base_url`](../reference/config.md), and needs
  no login. Either address is the stream's playlist served by zurg, every segment in it
  an address on zurg too, which zurg fetches from YouTube itself. zurg resolves the
  stream with yt-dlp and keeps it until an hour before it expires. A segment's address
  is good for a day; a player that comes back later reads the playlist again.
- **Upgrades.** A streamed film stays on the wanted list while `upgrades` is on, and any
  release of it that comes out replaces the stream, whatever its resolution: the stream,
  its `.strm` and its rex item go once the release has passed its check.

Limits:

- **Plex cannot play it.** It is no file on the mount. Use rex, Jellyfin or Kodi.
- **Cookies are required.** Without a signed-in account's cookies YouTube offers an
  address that fetches much only video and audio apart, or nothing, so zurg starts with
  the fallback off and says why. Export them from a browser signed in to YouTube, ideally
  on the same network. Signing out in that browser ends them.
- **Every byte passes through zurg.** Nothing is redirected to YouTube: rex sends its
  source's login with every request its transcoder makes, redirected ones included, and
  YouTube ties a stream to the address that resolved it. So any player that reaches
  zurg plays it, and zurg carries the film's traffic.

## Seerr-Verhalten {#seerr-behavior}

Der Adapter folgt den [Request-Routen](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/routes/request.ts),
den [Status-Definitionen](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/constants/media.ts)
und dem [API-Vertrag](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/seerr-api.yml) von seerr-team/seerr.

- Fragt alle Seiten der genehmigten Requests mit `X-Api-Key` ab. Schlägt eine Seite fehl, bleibt die bisherige Queue erhalten und die Arbeit für diese Quelle wird pausiert.
- Prüft die Genehmigung vor dem Download erneut. Requests, die ausstehend, abgelehnt, fehlgeschlagen, abgeschlossen, entfernt oder bereits verfügbar sind, starten keine Downloads.
- Löst IDs über Seerr auf. Die TV-Beschaffung beschränkt sich auf genehmigte angefragte Staffeln und deren bekannte, bereits ausgestrahlte Episoden. Eine unvollständige Staffel bleibt ausstehend.
- Behandelt 4K und Nicht-4K getrennt. Ein 1080p-Release kann einen 4K-Request nicht erfüllen.
- Prüft offene Requests alle 30 Minuten nach einer erfolgreichen Beschaffung erneut, um neu ausgestrahlte Episoden in angefragten Staffeln zu finden. Noch nicht angekündigte Episoden werden erst zur Arbeit, wenn sie in den Metadaten von Seerr auftauchen.
- Bevorzugt Packs, sobald alle bekannten Episoden ausgestrahlt sind. Laufende Staffeln verwenden einzelne Episoden. Specials (Staffel 0) werden nicht unterstützt. Ein genehmigter Request mit Staffel 0 wird gar nicht beschafft und schlägt fehl, bis er geparkt wird.
- Schreibt keinen Request-Status und keine Verfügbarkeit. Der Medienserver-Scan von Seerr meldet die tatsächliche Verfügbarkeit und benachrichtigt die Anfragenden. Ein gespeichertes NZB beweist noch nicht, dass es indexiert oder abspielbar ist. Deshalb prüft die Engine das, bevor sie eine Staffel als beschafft zählt.

Konfiguriere den Bibliotheksscan von Seerr so, dass er die Bibliothek einschließt, die von dieser Instanz bereitgestellt wird. Wenn Sonarr/Radarr dieselben Requests bereits beschaffen, deaktiviere diesen sich überschneidenden Workflow, bevor du diesen Adapter aktivierst. Der Adapter emuliert keinen *arr-Server und ändert nichts an der Dienst-Einrichtung von Seerr. Das Polling sorgt für die Wiederherstellung nach einem Neustart. Ein Webhook ist nicht nötig.

## Radarr-Verhalten {#radarr-behavior}

Radarr behält die Liste und gehört die Bibliothek. zurg übernimmt die Suche und das Herunterladen. Radarr sucht nie und holt nie etwas: zurg liest, was Radarr will, wählt ein Release aus den eigenen Indexern aus, prüft es bei den Usenet-Servern (TorBox' Abruf bei einem `torbox_nzb`-Konto) oder beim Debrid-Konto, das es hat, legt das Video im Ordner des Films innerhalb von `__magic__` ab und bittet Radarr, nur diesen einen Film neu zu scannen. Nichts wird kopiert: Das Video ist eine Datei in zurgs Bibliothek, die Radarr jetzt in seinem Ordner sieht.

### Radarr einrichten {#setting-up-radarr}

1. **Root-Ordner innerhalb von `__magic__`, eine Ebene tiefer.** Zum Beispiel
   `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` unter macOS,
   `Z:\__magic__\movies` unter Windows). Nicht `__magic__` selbst und nicht
   `__magic__/__all__`, das jeden Release in der Bibliothek auflistet. Ein Film,
   dessen Ordner woanders liegt, wird übersprungen, mit einer Warnung im Log von zurg.
   Unter Windows sieht Radarr `Z:` nur, wenn es in derselben Anmeldesitzung wie zurg läuft,
   also nicht als Windows-Dienst: siehe [die Regeln zur Sitzung](../setup/windows.md#keeping-it-running-the-session-rules).
2. **Importlisten mit Suche beim Hinzufügen aus.** Füge Filme hinzu, wie du willst (von Hand, über Listen, Seerr mit Verbindung zu Radarr). Lass **Search for Movie** beim Hinzufügen deaktiviert, da zurg die Suche übernimmt.
3. **Keine Indexer und kein Download-Client nötig.** Wenn Radarr welche hat, kann es parallel zu zurg etwas holen. Schalte deshalb die automatische Suche bei seinen Indexern aus (oder entferne sie) für die Filme, um die sich zurg kümmert.
4. **`library_path` ist der Ort, an dem Radarr `__magic__` sieht.** Wenn Radarr auf derselben Maschine wie zurg läuft und den Mount dort sieht, wo zurg ihn einbindet, lass es weg: Standard ist zurgs `mount_path` plus `/__magic__`. Wenn Radarr in einem Container läuft, der zurg an einem anderen Pfad einbindet, setze es auf diesen Pfad, zum Beispiel `/data/zurg/__magic__`. Ein Film unter `/data/zurg/__magic__/movies/Heat (1995)` wird dann in `movies/Heat (1995)` innerhalb von zurgs `__magic__` abgelegt. Windows-Pfade wie `Z:\__magic__` funktionieren ebenfalls. Ein Radarr-Container wird nur auf einem Linux-Host unterstützt: Docker Desktop unter macOS und Windows führt Container in einer VM aus, und das Durchreichen von zurgs Mount dorthin ist nicht getestet. Betreibe Radarr dort deshalb nativ.

   Wenn Radarr außerdem Grabs vom [SABnzbd](sonarr-radarr.md)- oder [qBittorrent](sonarr-radarr-torrents.md)-Endpunkt von zurg entgegennimmt, muss es deren Download-Ordner unter `library_path/__all__` sehen, und zwar über dasselbe Volume wie seine Root-Ordner. Sonst ist jeder Import daraus eine Kopie der gesamten Datei. zurg fragt Radarr, wo es beide sieht, und meldet das auf der Acquisition-Seite, in seinem Log und in `zurg doctor`, wenn sie sich keinen Mount teilen können. Siehe [Ein Volume für den Download-Ordner und die Root-Ordner](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

### Was zurg bei Radarr anfragt {#what-zurg-asks-radarr-for}

Jede Abfrage liest die Filmliste von Radarr und handelt bei jedem Film, der überwacht wird, **verfügbar** laut der Mindestverfügbarkeit des Films ist und entweder keine Datei hat oder eine Datei unterhalb des Cutoffs seines Qualitätsprofils, wenn das Profil Upgrades erlaubt. Unterhalb des Cutoffs bedeutet unterhalb der Cutoff-Qualität oder unterhalb des Cutoff-Scores für Custom Formats, so wie Radarr es zählt. Ein noch nicht erschienener Film, etwa einer mit einem Datum in einigen Monaten, wartet, bis Radarr sagt, dass er verfügbar ist.

Jeder Kandidat-Release, den zurg als Nächstes prüfen will, wird an Radarrs eigenen Parser (`/api/v3/parse`) geschickt und anhand des Qualitätsprofils des Films bewertet. Was zurg annimmt, ist also das, was Radarr auch annehmen würde:

- **Es muss genau dieser Film sein.** Radarr muss den Titel demselben Film zuordnen. Eine ID-Suche bei einem Indexer liefert auch andere Filme (eine Suche nach *Psycho* lieferte *Ed Gein: The Real Psycho*), und ein Titel, den Radarr keinem Film zuordnen kann, wird abgelehnt. Ein Jahr im Titel, das mehr als eins vom Jahr des Films abweicht, wird ebenfalls abgelehnt.
- **Zuerst gelten die Allow-Liste und der Mindestscore des Profils.** Die erkannte Qualität muss vom Profil erlaubt sein, der Custom-Format-Score muss den Mindestwert des Profils erreichen, und die Größe muss zu den Grenzen der Qualität passen, die unter **Settings > Quality** für die Laufzeit des Films eingestellt sind.
- **Der Release muss in der Sprache des Profils sein.** Bei **Original**, dem Standard, muss Radarr den Titel als Originalsprache des Films lesen. Ein Release, der nur auf Französisch ist, wird daher bei einem englischen Film abgelehnt. Ein Titel, der keine Sprache nennt, gilt als Original. Wird eine Sprache genannt, wird genau diese verlangt, und **Any** nimmt alle Sprachen. Das gilt für die erste Datei genauso wie für ein Upgrade.
- **Upgrades streben später Richtung Cutoff.** Ein Film ohne Datei nimmt jeden Release, der die obigen Prüfungen besteht. Hat er einmal eine Datei unterhalb des Cutoffs, wird nur noch ein besserer Release genommen: eine höhere Qualität in der Reihenfolge des Profils, solange die Datei unter der Cutoff-Qualität liegt, oder ein höherer Custom-Format-Score (mindestens um den Upgrade-Schritt des Profils), solange sie unter dem Cutoff-Score liegt. Eine niedrigere Qualität wird nie genommen. PROPER- und REPACK-Releases derselben Qualität gelten nicht als Upgrade.

Das Profil wird auf den Release angewendet, den zurg gleich nimmt, als Allow-Liste: der richtige Film, eine erlaubte Qualität, der Mindestscore, die Sprache und die Größengrenzen.

Standardmäßig wird die Reihenfolge des Profils nicht genutzt, um unter den erlaubten Releases auszuwählen. zurg nimmt den ersten erlaubten Release, der am günstigsten zu prüfen ist. Dabei probiert es zuerst Web-Releases (WEB-DL, WEBRip), dann Blu-ray und dann alles andere, weil Web-Releases am häufigsten als einzelne Videodatei gepostet werden. Wenn das Profil etwas Besseres bevorzugt als das, was ankommt, und Upgrades erlaubt, sieht Radarr die Datei des Films unterhalb des Cutoffs. zurgs Upgrade-Durchlauf sucht dann nach dem besseren Release, sobald der Film eine Datei hat. Die erste Datei kommt schnell, und die Reihenfolge des Profils wird durch das Upgrade umgesetzt. Setze `best_first: true`, damit der erste Download stattdessen der Reihenfolge des Profils folgt. Siehe [Den besten Treffer des Profils zuerst nehmen](#taking-the-profiles-best-first).

Wenn eine Suche nach der IMDb- oder TMDB-ID des Films gar nichts liefert, sucht zurg erneut nach Titel und Jahr, so wie Radarr es tut. Viele Posts, besonders bei kleinen Dokumentationen, sind ganz ohne ID indexiert. Radarrs Parser entscheidet bei jedem Ergebnis, ob es der Film ist. Ein Film mit gleichem Namen wird daher wie jeder andere falsche Treffer abgelehnt.

Radarr wird nur dann nach einem Release gefragt, wenn zurg ihn gerade prüfen will, und zwar jeweils einen Release nach dem anderen. Ein Film mit einem einzelnen Release kostet daher ein bis drei Anfragen. Nach einem direkt gespeicherten Post wird nichts mehr gefragt. Ein Titel, der eine Auflösung nennt, für die das Profil keine erlaubte Qualität hat, etwa ein 2160p-Release bei einem HD-1080p-Profil, wird abgelehnt, ohne Radarr überhaupt zu fragen. Ein Titel, der keine Auflösung oder mehrere nennt, geht immer an Radarr. Das gilt auch für jeden Titel, wenn das Profil eine Qualität erlaubt, deren Name keine Auflösung angibt (SDTV, DVD, Unknown, Raw-HD, BR-DISK). zurg stellt einem Radarr gleichzeitig höchstens acht Anfragen.

Wenn Radarr nicht erreicht werden kann, wird nichts entschieden: Der Film wartet bis zur nächsten Abfrage, und kein Release wird aussortiert, nur weil Radarr nicht geantwortet hat.

### Die Datei ablegen {#placing-the-file}

Sobald eine Veröffentlichung geprüft wurde, legt zurg ihr Video in den Ordner des Films, so wie Radarr es importiert hätte. Dafür wird die Datei innerhalb von `__magic__` verschoben. Es wird nichts kopiert oder heruntergeladen.

- **Das größte Video wird platziert.** Gemeint ist die größte Datei `.mkv`, `.mp4`,
  `.m4v`, `.avi`, `.mov` oder `.ts` in der Veröffentlichung, wobei der Inhalt ihrer Archive mitgezählt wird. Eine Veröffentlichung, die aus einem einzelnen Archiv bereitgestellt wird, besteht aus dem Inhalt dieses Archivs. Ein RAR-Set mit losen Dateien daneben, etwa ein Scene-Post mit Sample und `.nfo`, wird als Ordner der Veröffentlichung durchsucht, und das Video darin wird von dort aus platziert. Samples, Featurettes, Untertitel und `.nfo`-Dateien bleiben in `__magic__/__all__`. Die Datei behält den Namen, den sie in der Veröffentlichung hat, außer dieser Name sagt nichts über den Film aus (weder Jahr noch ein Wort aus dem Titel). Dann übernimmt sie den Namen der Veröffentlichung, damit Radarr deren Qualität lesen kann.
- **Ein Sample wird nie platziert.** Ein Video, das als Sample erkennbar ist (`sample-…`, `….sample.mkv`, ein Ordner `Sample/`), wird ausgelassen, egal wie groß es ist, es sei denn, der Name der Veröffentlichung selbst enthält auch das Wort sample. Ein Film, der das Wort nur im Titel trägt (`Sample.Size.2019`, `Death.Proof.2007`), hat es auch im Namen der Veröffentlichung. Dort wird das Video nur ausgelassen, wenn es weniger als ein Fünftel der Veröffentlichung ausmacht. Eine Veröffentlichung, deren einziges Video das Sample ist, auch ein Post, der nur aus dem Sample besteht, wird aussortiert, und der nächste Kandidat wird probiert. So ersetzt ein Upgrade deine Datei nie durch einen Ein-Minuten-Clip.
- **Es wird abgelehnt, bevor es verschoben wird, wenn es nicht lesbar ist.** Das ist dieselbe Prüfung, die ein Import von Sonarr oder Radarr über den Mount bekommt. Eine Veröffentlichung, deren Artikel die Newsserver nicht mehr haben, oder deren Archiv sich nie öffnen lässt, wird wie ein toter Post aussortiert, und der nächste Kandidat wird probiert. Eine Veröffentlichung, die im Moment nicht lesbar ist, etwa weil das Konto gerade abkühlt, wird später noch einmal versucht.
- **Radarr behält eine Datei pro Film, daher ersetzt ein Upgrade die alte Datei.** Sobald das neue Video im Ordner liegt, wird jedes andere Video, das die zurg-Bibliothek dort hineingelegt hat, aus dem Ordner ausgeblendet. Ausgeblendet heißt als gelöscht markiert, so wie ein Löschen über den Mount. Die alte Veröffentlichung bleibt in `__all__` und auf ihrem Konto. Eine echte Datei, die du selbst in den Ordner gelegt hast, bleibt unberührt. Die alte Datei wird erst entfernt, nachdem die neue platziert wurde. Wenn das Platzieren fehlschlägt, behält der Film also die Datei, die er vorher hatte.
- **Radarr scannt danach neu.** zurg meldet dem Mount, welche Ordner sich geändert haben, damit der Rescan keinen Ordner liest, den der Mount noch als leer speichert. Danach bittet zurg Radarr, genau diesen einen Film neu zu scannen.

Eine Radarr-Quelle braucht `__magic__` (`magic.enabled`). Ohne das startet die Quelle nicht, und das wird im Log und auf der Acquisition-Seite angezeigt.

### Was Radarr anzeigt {#what-radarr-shows}

**Activity** bleibt leer: keine Warteschlangeneinträge und keine Grab- oder Import-Ereignisse, weil Radarr nichts gegrabbt hat. Der Film hat nach dem Rescan, den zurg anstößt, einfach eine Datei, und deren Qualität und Custom Formats sind Radarrs Einschätzung dieser Datei. Das Log von zurg hält jeden Film fest, den es fertigstellt.

`only_new_items` und `remove_after_grab` haben bei einer Radarr-Quelle keine Wirkung. Die gewünschten Filme von Radarr sind Arbeit, genau wie die genehmigten Anfragen von Seerr, und Radarr entscheidet, wann ein Film nicht mehr gewünscht ist. Halte den `name` der Quelle stabil: Er identifiziert die gespeicherte Warteschlange, während URL und Key sich frei ändern können.

## Sonarr-Verhalten {#sonarr-behavior}

Sonarr funktioniert genauso wie Radarr. Sonarr führt die Liste und verwaltet die Bibliothek.
zurg übernimmt die Suche und den Download. Sonarr sucht nie und holt nie etwas.
zurg liest die Episoden, die Sonarr fehlen, und wählt ein Release aus seinen eigenen
Indexern aus. Es prüft das Release bei den Newsservern (TorBox-Abruf bei einem `torbox_nzb`-Konto)
oder bei dem Debrid-Konto, in dem das Release liegt. Dann legt es das Video jeder Episode im Staffelordner der Serie innerhalb von `__magic__` ab. Danach bittet es Sonarr, nur diese eine Serie neu zu scannen. Es wird nichts kopiert.

### Sonarr einrichten {#setting-up-sonarr}

1. **Stammordner innerhalb von `__magic__`, eine Ebene tiefer.** Zum Beispiel
   `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` unter macOS,
   `Z:\__magic__\tv` unter Windows). Eine Serie, deren Ordner woanders liegt,
   wird übersprungen, und zurg schreibt dazu eine Warnung in das Log.
   Unter Windows muss Sonarr in derselben Anmeldesitzung wie zurg laufen, so wie es bei Radarr auch sein muss.
2. **Search on add aus.** Füge Serien hinzu, wie du willst. Lass **Start search
   for missing episodes** aus, weil zurg die Suche übernimmt.
3. **Keine Indexer und kein Download-Client nötig.** Wenn Sonarr welche hat, kann es parallel zu zurg etwas herunterladen. Schalte deshalb die automatische Suche bei den Indexern für die Serien aus, um die sich zurg kümmert.
4. **`library_path` ist der Ort, an dem Sonarr `__magic__` sieht.** Es funktioniert genauso wie bei Radarr, einschließlich der Prüfung, dass Sonarr den Download-Ordner von zurg und dessen Stammordner über ein gemeinsames Volume erreicht. Lass ihn weg, wenn Sonarr das Laufwerk an demselben Ort sieht, an dem zurg es einhängt.

### Was zurg bei Sonarr anfragt {#what-zurg-asks-sonarr-for}

Bei jeder Abfrage liest zurg die fehlenden Episoden aus Sonarr. Das sind überwachte Episoden einer überwachten Serie, die bereits ausgestrahlt wurden und keine Datei haben. zurg gruppiert sie nach Staffel und behandelt jede Staffel als ein zusammenhängendes Stück Arbeit.

- **Eine komplett ausgestrahlte Staffel kann als Pack kommen.** Wenn jede Episode einer Staffel fehlt und keine mehr ausgestrahlt werden soll, wird zuerst ein Season-Pack versucht. Andernfalls werden die fehlenden Episoden der Staffel einzeln aus den Suchergebnissen dieser Staffel genommen. Eine Staffel, von der schon einige Dateien da sind, bekommt nie ein Pack. Sonst läge im Ordner eine zweite Kopie dieser Episoden.
- **Eine neue Episode ist neue Arbeit.** Wenn die Episode der nächsten Woche ausgestrahlt wird, taucht die Staffel mit dieser Episode erneut auf. zurg sucht nicht noch einmal nach den Episoden, die es schon hat.
- **Eine neue Episode wird innerhalb von Minuten erneut gesucht.** Ihr Release wird meist innerhalb einer Stunde nach der Ausstrahlung veröffentlicht. Eine Suche direkt zur Sendezeit findet deshalb oft nichts. Sechs Stunden nach der Ausstrahlung versucht zurg es alle zwei Minuten, danach alle zehn Minuten, bis zwei Tage nach der Ausstrahlung. Danach wartet es wie bei allem anderen länger (siehe [Persistenz und Wiederherstellung](#persistence-and-recovery)). Bei einem Debrid-Konto muss das Release dort außerdem schon gecacht sein, weil zurg nur hinzufügt, was das Konto bereits hat.
- **Eine gelöschte Episode wird erneut gesucht.** Wenn Sonarr eine Episode auflistet, die zurg schon erhalten hat, schaut zurg im Staffelordner nach. Ist dort kein Video mehr für diese Episode, wird sie erneut gesucht. Ist noch eins da, hat Sonarr noch nicht neu gescannt, und es wird nichts gesucht.
- **Upgrades gelten pro Datei.** Eine Episodendatei, die unter dem Cutoff ihres Qualitätsprofils liegt, ist ein Upgrade, solange das Profil Upgrades erlaubt. Unter dem Cutoff heißt: unter der Cutoff-Qualität oder unter dem Cutoff-Score des Custom Formats. Die Liste Cutoff Unmet von Sonarr zählt nur die Qualität. In Sonarr 4.0.20 steht eine Datei in der Cutoff-Qualität, die 0 von einem Cutoff-Score von 40 hat, nicht auf dieser Liste. zurg zählt beides, so wie es auch Sonarrs eigene Upgrade-Regel tut. Eine Datei mit zwei Episoden ist ein einziges Upgrade für beide.
- **Die Episoden einer täglichen Show werden nach dem Ausstrahlungstag gefunden.** Ihre Releases sind nach dem Tag benannt (`The.Daily.Show.2026.11.03.Min.Jin.Lee...`), und die Indexer finden sie nicht über die Episodennummer. Deshalb wird jede fehlende Episode zusätzlich als Textsuche nach Serientitel und Tag angefragt, `The Daily Show 2026.11.03`. Sonarrs Parser macht aus dem Tag wieder die Episode (S31E124), genauso wie bei einem Titel, der nach Staffel nummeriert ist.
- **Die Episoden eines Animes werden über die Nummer gefunden, mit der die Serie sie zählt.** Fansub-Releases sind ab der ersten Episode der Serie nummeriert (`[SubsPlease] Jujutsu Kaisen - 30` ist die sechste Episode der zweiten Staffel). Deshalb wird jede fehlende Episode zusätzlich als Textsuche nach Serientitel und dieser Nummer angefragt, `JUJUTSU KAISEN 30`. Ein Batch über die Nummern der Staffel (`(25-47)`) ist das Pack dieser Staffel. Sonarrs Parser ordnet die Nummer der Episode zu, mit den Szene-Namen der Staffel (`Jujutsu Kaisen 2nd Season`, `Jujutsu Kaisen S2`). Ein Titel, der auf eine der beiden Arten nummeriert ist, wird also als die Episode beurteilt, die er tatsächlich ist. Ein Release, das Sonarr keiner Serie zuordnen kann, etwa weil es einen Szene-Namen trägt, den Sonarr nicht kennt, wird wie jedes andere abgelehnt.
- **Specials sind Staffel 0.** Die überwachten Specials von Sonarr werden wie jede andere Staffel aufgelistet und als Staffel `00` angefragt. Ein Indexer, der nach Staffel `0` gefragt wird, antwortet mit einer anderen Staffel. Nur ein Release mit `S00Exx` im Namen kann passen. Ein Special, das nur nach seinem Titel benannt ist, ergibt beim Parsen nichts, auch in Sonarr. Specials landen in dem Ordner, den Sonarrs **Specials Folder Format** vorgibt.

Jedes Kandidaten-Release wird Sonarrs eigenem Parser (`/api/v3/parse`) vorgelegt und nach dem Qualitätsprofil der Serie beurteilt. Was zurg annimmt, ist also genau das, was Sonarr auch angenommen hätte.

- **Es muss diese Serie und diese Staffel sein.** Sonarr muss den Titel derselben Serie zuordnen. Ein Titel, dem Sonarr nichts zuordnet, wird abgelehnt. Ausnahme: Die Serie nutzt keine Szene-Nummerierung, und Sonarrs eigene Serien-Suche findet diese Serie zuerst anhand des Namens im Titel (etwa bei einem fremdsprachigen Titel).
- **Ein Pack muss die ganze Staffel sein.** Ein Teil-Pack wird abgelehnt. Ein Pack, das als Bereich geschrieben ist, etwa `Season 1 E01-E07`, zählt, wenn der Bereich die ganze Staffel umfasst. Ein Pack mit mehreren Staffeln zählt für jede Staffel, die es nennt (siehe [Packs mit mehreren Staffeln](#packs-of-several-seasons)). Sonarr liest `S01-S05` nur als Staffel 1 und sagt nie, wo es endet. Deshalb liest zurg den Bereich aus dem Titel. Sonarr muss das Pack trotzdem der Serie zuordnen und als vollständiges Pack mit mehreren Staffeln einstufen. Seine Größe wird an der Laufzeit aller genannten Staffeln gemessen.
- **Eine Episode muss genau diese eine Episode sein.** Ein Release mit zwei Episoden wird für eine einzelne Episode abgelehnt.
- **Das Profil gilt wie bei Radarr.** Die Qualität muss erlaubt sein. Der Custom-Format-Score muss das Minimum des Profils erreichen. Die Größe muss in die Grenzen der Qualität unter **Settings > Quality** passen, gemessen an der Laufzeit der Episoden, die das Release enthält. Ein Upgrade muss die aktuelle Datei nach Sonarrs Regeln schlagen. Sonarr-Profile haben keine Sprach-Einstellung. Eine Sprache zählt deshalb nur über den Score eines Custom Formats, genau wie in Sonarr.

Welches erlaubte Release zuerst kommt, wird anders entschieden als bei Radarr. Ein Season-Pack wird vor den einzelnen Episoden versucht, weil es ein einziger Grab ist, wo sonst mehrere nötig wären. Unter den Releases, die Sonarr erlaubt, nimmt zurg dasjenige, das die `quality`-Einstellung an erster Stelle reiht. Bei `best` ist das zuerst die höchste Auflösung und dann das größte Release, bei einem Pack gemessen an dem, was es pro Episode enthält. Eine abgeschlossene Staffel mit einem 1080p-Pack wird also aus diesem Pack gefüllt, auch wenn dieselbe Suche jede Episode in 2160p hat. Der Upgrade-Durchlauf ersetzt sie dann Episode für Episode. Ein Pack, das pro Episode mehr als `max_size_gb` enthält, oder insgesamt mehr als ein `max_season_size_gb`, den du für eine Staffel festgelegt hast, kommt nie als Kandidat infrage. `best_first: true` ändert beides. Siehe [Das Beste des Profils zuerst nehmen](#taking-the-profiles-best-first).

Ein Titel mit einer Auflösung, für die das Profil keine erlaubte Qualität hat, wird abgelehnt, ohne Sonarr zu fragen. zurg stellt höchstens acht Anfragen gleichzeitig an eine Sonarr-Instanz. Ist Sonarr nicht erreichbar, wird nichts entschieden. Die Staffel wartet auf die nächste Abfrage, und kein Release wird zurückgestellt.

### Die Dateien ablegen {#placing-the-files}

Sobald ein Release geprüft wurde, landet das Video jeder Episode im Staffelordner. Das ist der Ordner, in dem die bestehenden Dateien der Staffel liegen. Hat eine Staffel noch keine Dateien, ist es der Ordner, den das **Season Folder Format** von Sonarr vorgibt, zum Beispiel `Season 1`. Eine Serie, die keine Staffelordner verwendet, bekommt ihre Dateien im Serienordner.

- **Jede Episode bekommt ihr eigenes Video.** Das Video wird über die Episodennummer im Namen gefunden, auch innerhalb der Archive des Releases. Ein Pack legt jede Episode ab, für die es gedacht ist. Samples und `.nfo`-Dateien bleiben in `__magic__/__all__`, und ein Sample wird nie als Episode abgelegt.
- **Ein Pack, dem eine Episode fehlt, wird abgelehnt, bevor etwas verschoben wird.** Es wird wie ein toter Post behandelt und beiseitegelegt. Danach werden das nächste Pack oder die einzelnen Episoden probiert.
- **Eine einzelne Episode, deren Dateiname keine Nummer enthält, bekommt das größte Video des Releases.** Verschleierte Posts sehen oft so aus.
- **Das Video einer Anime- oder Daily-Show wird unter Serie und Episode abgelegt.** Ein Rescan liest eine Datei nur anhand ihres Namens und kennt keine Scene-Nummerierung: `[Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv` im Serienordner wurde als S01E08 importiert, während Sonarrs Parser denselben Titel als S02E08 liest. Deshalb wird das Video als `JUJUTSU KAISEN - S02E08 - [Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv` abgelegt. Das importiert richtig, und der ursprüngliche Name bleibt hinter der Episode erhalten, damit Sonarr trotzdem Qualität und Gruppe erkennt. Die Videos einer Standardserie und eines Specials behalten ihre Namen, denn die sagen die Episode bereits.
- **Ein Upgrade ersetzt nur seine eigene Episode.** Das alte Video dieser Episode wird aus dem Staffelordner ausgeblendet, sobald das neue drin ist. Die anderen Episoden im Ordner bleiben unangetastet. Ausgeblendet heißt tombstoned, wie bei Radarr.
- **Danach rescannt Sonarr.** zurg teilt dem Mount mit, welche Ordner sich geändert haben, und bittet Sonarr, die Serie neu zu scannen.
- **Eine fehlende Episode hält die übrigen nicht zurück.** Wenn für eine Episode noch kein Release verfügbar ist, das zurg übernehmen kann, werden die gefundenen Episoden trotzdem geprüft und abgelegt. Sonarr wird sofort um einen Rescan für sie gebeten. Die fehlende Episode wird nach dem üblichen Wiederholungsplan erneut gesucht.

Eine Sonarr-Quelle braucht `__magic__` (`magic.enabled`). Ohne das startet die Quelle nicht, und das wird im Log und auf der Acquisition-Seite angezeigt.

**Activity** in Sonarr bleibt leer, wie bei Radarr. Die Episoden bekommen einfach Dateien nach dem Rescan, den zurg anfordert. `only_new_items` und `remove_after_grab` haben bei einer Sonarr-Quelle keine Wirkung.

## Pakete mit mehreren Staffeln {#packs-of-several-seasons}

Eine Staffel kann aus einem Paket stammen, das mehrere Staffeln enthält, zum Beispiel `Game.of.Thrones.S01-08.BDRip.1080p` oder `Breaking Bad Season 1-5`. Indexer legen so ein Paket unter jeder Staffel ab, die es abdeckt. Im Feed von DMM waren 72 der 691 Ergebnisse für Breaking Bad Staffel 3 Pakete mit mehreren Staffeln. Bei manchen Staffeln ist eines davon die einzige Kopie, die ein Konto hat.

- **Der Titel sagt, welche Staffeln es sind.** `S01-S05`, `S01-05`, `[S01-08]`, `S1-9`, `Seasons 1-8`, `Season 1 to 5`, `Season 1 · 2 · 3`, `Stagioni 01-05` und `Temporadas 1-4` werden alle gelesen. Ein Titel ohne Staffelnummern, etwa `Complete Series`, wird nicht übernommen. Auch einer, der nur als Wort eine einzelne Staffel nennt, etwa `Season 3 Complete`, wird nicht übernommen. Solche Titel wurden nie als Pakete gelesen.
- **Nur diese Staffel wird eingeordnet.** Ein Paket, das für Staffel 4 genommen wird, legt die Folgen von Staffel 4 in den Staffelordner. Die Dateien der anderen Staffeln bleiben dort, wo die Bibliothek sie auflistet. Ein Paket, dessen Dateien nicht alle Folgen der Staffel enthalten, wird abgelehnt, bevor etwas verschoben wird, egal was der Titel behauptet.
- **Die Größe wird pro Folge bewertet.** Die Größe eines Pakets wird durch die Anzahl der genannten Staffeln und dann durch die Folgen der Staffel geteilt und gegen `max_size_gb` geprüft, so als wäre dieselbe Encodierung Folge für Folge hochgeladen worden. Ein 346-GB-Paket mit acht Staffeln zu je zehn Folgen sind 4,3 GB pro Folge. Der Remux von Staffel 2 von I Love Lucy mit 31 Folgen ist 106 GiB, also 3,4 GiB pro Folge, und passt unter den eingetragenen Wert 40. Wenn die Quelle die Folgen der Staffel nicht aufgelistet hat, gibt es für Pakete keine Obergrenze pro Folge. Ein `max_season_size_gb`, den du setzt, begrenzt zusätzlich jede Staffel, die das Paket nennt. Standardmäßig ist keins gesetzt.
- **Qualität kommt weiterhin zuerst.** Pakete werden wie jede andere Veröffentlichung eingestuft: zuerst nach Auflösung, dann nach dem, was sie pro Folge bieten, so wie DMMs Staffelseite sie sortiert. Ein 2160p-Paket mit einer Staffel wird vor einem 1080p-Paket mit acht Staffeln genommen. Bei gleicher Auflösung kommt der eigene Remux einer Staffel vor einem Paket mit acht Staffeln, das insgesamt größer, pro Folge aber kleiner ist.
- **Die anderen Staffeln der Serie nehmen dasselbe Paket.** Sobald eine Staffel ein Paket mit mehreren Staffeln übernommen hat, versuchen die anderen Staffeln der Serie zuerst dieses Paket, noch vor jedem Paket derselben Auflösung, das ihre eigene Suche gefunden hat. Es liegt schon auf dem Konto, kostet also nichts. Während die Staffeln einer Serie unter Paketen mit mehreren Staffeln auswählen, wählen sie nacheinander. So entscheiden sich Staffeln, die zusammen angefragt werden (eine Sonarr-Serie, alle Staffeln bei einer Abfrage), nicht jeweils für eine andere Kopie der Serie. Sobald eine davon ohne so ein Paket gewählt hat, weil keins auf dem Konto lag oder das Profil keins zuließ, wählen die übrigen gleichzeitig. Eine Staffel, die eine Stunde später angefragt wird, sucht neu.

## Dabei zusehen, wie es arbeitet {#watching-it-work}

Der **Acquisition**-Link im Dashboard öffnet `/acquisition/` auf zurgs eigenem Port.
Jede Quelle bekommt eine Zeile mit der Anzahl ihrer Titel, die fertig, laufend, wartend, zurückgestellt und in der Warteschlange sind, dazu die Anzahl der Titel, an denen zurg gleichzeitig arbeitet, die Anfragen, die sie gleichzeitig an einen Indexer stellt, und die News-Verbindungen, die deine `nzb`-Konten erlauben. Darunter hat jede Quelle eine Tabelle mit einer Zeile pro Titel. Eine Zeile zeigt den Status und was ein laufender Titel gerade macht (die Suche, wie viele Ergebnisse bisher bewertet und zugelassen wurden, den gerade geprüften Kandidaten, die Prüfung auf den News-Servern, die Ablage), seine Versuche, das gewählte Release mit der Qualität und dem Score, die die Quelle ihm gegeben hat, wohin es abgelegt wurde, und wann ein wartender Titel das nächste Mal versucht wird. Ein Titel, dessen Releases alle durch sind, nennt den Grund, und die Ablehnungen der Quelle werden nach Regel gezählt: `14 refused by the source's own rules (title mismatch 7, quality 5, size 2)`. Releases, die wegen ihrer Auflösung abgelehnt werden, ohne die Quelle zu fragen, zählen unter quality. Die Seite aktualisiert sich alle fünf Sekunden selbst. Denselben Stand gibt es unter `/acquisition/status.json`, dort steht dieser Grund im `detail` des Titels. Ist keine Quelle aktiviert oder ist Acquisition konfiguriert, aber pausiert, sagt die Seite das und den Grund.

Für jeden Film, für den ein Release gewählt wird, gibt es eine Zeile im Log, mit der sich messen lässt, wo die Zeit hingeht:

```
Acquisition: chose <release> for <title>: results=143 local_refusals=97 radarr_refusals=1 inspected=2 radarr_calls=3 in 4.2s
```

`results` ist, was die Suche zurückgegeben hat, `local_refusals` die Ergebnisse, die abgelehnt wurden, ohne die Quelle zu fragen, `radarr_refusals` die, die nach den eigenen Regeln der Quelle abgelehnt wurden, `inspected` die gelesenen NZBs, `radarr_calls` die Anfragen an die Quelle (die gelesenen NZBs plus die Ablehnungen auf dem Weg dorthin, wenn die Quelle Radarr ist), und die Zeit läuft ab dem Start der Suche. Releases, die ohne Nachfrage abgelehnt werden, werden nur auf Debug-Ebene einzeln ins Log geschrieben.

## Einen \*arr prüfen, der nur zurg als Download-Client nutzt {#checking-an-arr-that-only-uses-zurg-as-its-download-client}

A Sonarr or Radarr pointed at zurg's [SABnzbd](sonarr-radarr.md) or
[qBittorrent](sonarr-radarr-torrents.md) endpoint does its own searching, and does not
need a source here. zurg still wants its API key, because three of its settings
decide whether every import is a free rename or a whole release downloaded
from the debrid account and written to zurg's disk: Remove Completed on a
qBittorrent client, the download folder and the root folders on one volume,
and root folders inside `__magic__`. With the key, zurg turns Remove Completed
on by itself (see [qbittorrent.md](sonarr-radarr-torrents.md#what-to-put-in-each-field))
and warns about the other two. See
[One volume for the download folder and the root folders](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

The easiest way to give zurg the key is the banner on the main dashboard,
described below. Or add it as a source that is switched off:

```yaml
acquisition:
  sources:
    - name: sonarr
      type: sonarr
      enabled: false
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
```

A Radarr or Sonarr source with `enabled: false` acquires nothing. zurg never
reads its wanted list and never searches for it. With its `url` and `api_key`
set, and one of the two endpoints on, zurg only reads the \*arr's root folders,
remote path mappings and download clients, at start, every ten minutes and as
soon as the \*arr first calls one of the endpoints. It turns Remove Completed
on for the \*arr's zurg qBittorrent client when it is off, the one change zurg
makes, and reports a layout that makes imports copies. Every source with a URL
and an API key, enabled or not, is checked and corrected the same way. It is
listed on the acquisition page under **Checked, never searched for**, with
what zurg changed, the findings go to the log, and `zurg doctor` shows them as
`imports (<name>)`. `library_path` is not judged for such a source, since
nothing is placed for it. A source added to config.yml by hand is read at
start, so restart zurg after adding one that way.

zurg also notices a Sonarr or Radarr it cannot check. Both send their name in
every request to the endpoints (`Sonarr/4.0.20.3014 (alpine 3.24.1)`), so zurg
records which ones call it and from which address. When one calls and no
source of its kind has a URL and an API key, zurg logs one warning, `zurg
doctor` reports it on its `*arr settings` line, and the main dashboard shows a
banner with a form for its URL and API key. The URL is filled in with a guess:
the address the \*arr calls from, on its default port (8989 for Sonarr, 7878
for Radarr). That address is often a container's own, which zurg may or may
not reach, so change it to whatever URL reaches the \*arr from where zurg
runs. The API key is in the \*arr under Settings, General, Security. zurg
first asks the \*arr for its status with that key, and saves nothing unless it
answers as the app it was named as. It then adds the source above to
config.yml with `enabled: false`, keeping everything else in the file as it
was, and checks it straight away, with no restart. The form shows what zurg
found and changed. The key is written to config.yml and sent to the \*arr, and
nowhere else.

The banner matches by kind, not by address: an \*arr calls zurg from inside
its container, on an address that has nothing to do with the URL zurg reaches
it on, so one Sonarr source with a key silences the banner for every Sonarr.

## Doppelte Releases finden {#finding-duplicate-releases}

Ein Upgrade lässt die Version, die es ersetzt hat, in deiner Bibliothek liegen. Ist `magic.allow_delete` ausgeschaltet, versteckt das Löschen der alten Datei durch Radarr oder Sonarr sie nur in `__magic__`. Dadurch bleibt die alte Version in `__all__` und auf deinem Konto.

Auch Grabs von mehr als einem Indexer oder ein Staffelpaket neben einzelnen Episoden lassen mehrere Releases desselben Inhalts zurück.

Unter **Manage > Duplicates** (`/manage/duplicates/`) findest du sie alle. Dort steht, welches Release Radarr oder Sonarr gerade verwendet, und du kannst die anderen löschen. Es wird nie automatisch etwas gelöscht.

**Welches Release gerade in Benutzung ist, wird anhand der Pfade erkannt, nicht anhand der Namen.** Jede Datei, die Radarr und Sonarr verwalten, wird über einen Pfad unter `__magic__` angesprochen. zurg weiß, aus welchem Release jeder Pfad stammt, weil der Verschiebevorgang, der die Datei dorthin gebracht hat, das notiert hat. Die Ansicht liest jede Datei, die ein \*arr importiert hat, egal ob überwacht oder nicht, ob am Cutoff oder nicht, und führt jede auf ihr Release zurück. Eine Sonarr-Datei wird Episode für Episode zurückverfolgt. Wenn Sonarr drei Episoden aus einem Staffelpaket nimmt, wird es für genau diese drei als in Benutzung angezeigt.

**Welche Releases Kopien sein könnten, ist eine Vermutung, und das wird auch so angezeigt.** Releases werden zusammen mit einem Film oder einer Staffel gruppiert, wenn:

- eine \*arr-Datei darin liegt,
- die Historie des \*arr sagt, dass er daraus importiert hat, oder eine Datei daraus gelöscht hat (bei einem Upgrade, von Hand oder weil sie von der Festplatte fehlt),
- zurg sie der IMDb-ID des Films oder der Serie zugeordnet hat, oder
- ihr Name Titel und Jahr enthält (ein um eins abweichendes Jahr oder das zweite Jahr, das Radarr für den Film führt, zählt trotzdem) oder Serie und Staffel.

Jedes Release zeigt an, welcher dieser Gründe es in die Gruppe gebracht hat. Eine Staffel ist nur dann eine Gruppe, wenn Releases dieselbe Episode enthalten: Sechzig Einzelepisoden-Releases einer Staffel sind sechzig verschiedene Episoden. Eine Staffelgruppe zeigt die Episoden, die mehr als ein Release enthält, welches Release jede davon enthält, in welchem Release die Datei von Sonarr liegt und wie viele Episoden jedes Release hat, die sonst kein anderes Release in der Gruppe hat. Kein Release wird als Gewinner ausgewählt. Releases, auf die kein Radarr- oder Sonarr-Eintrag passt, stehen unter **Name matches only**, gruppiert nach ihren Namen und IMDb-IDs.

**Jedes Release ist In use, No reference found oder Unknown.**

| Status | Bedeutung |
|---|---|
| In use | Eine Datei, die Radarr oder Sonarr gerade hält, liegt in diesem Release. Es kann nicht ausgewählt werden. |
| No reference found | Jeder konfigurierte Radarr und Sonarr wurde vollständig gelesen, und keine ihrer Dateien liegt in diesem Release. Plex, Jellyfin und andere Clients, die den Mount lesen, sind hier nicht sichtbar, daher ist das kein Beweis, dass nichts es abspielt. |
| Unknown | zurg kann es nicht feststellen. Alle Releases sind Unknown, solange ein \*arr nicht gelesen werden kann, während die Bibliothek noch lädt, oder wenn `__magic__` aus ist. Ein Release ist außerdem Unknown, wenn eine \*arr-Datei für denselben Film oder dieselbe Episode keinem Release zugeordnet werden kann, oder wenn die Historie des \*arr zeigt, dass eine Datei aus diesem Release von der Festplatte verschwunden ist und der Film oder die Episode seitdem keine Datei mehr hatte. |

**Die Qualität wird in den Begriffen des Qualitätsprofils angezeigt.** Bei einem Release, das der \*arr verwendet, ist es die eigene Bewertung der Datei durch den \*arr. Bei einem, das er vorher importiert hat, ist es die Bewertung, die er damals vergeben hat. Ansonsten wird sie aus dem Release-Namen gelesen, und das wird auch so angezeigt. Jede Angabe wird im Qualitätsprofil des Eintrags eingeordnet, zum Beispiel "rank 15 of 17 in 4K or best available (cutoff at 17)".

**Beim Löschen wird zuerst neu gelesen.** Wähle Releases aus und klicke auf **Check again and delete**. zurg liest die aktuellen Dateien aller \*arr erneut und bietet das Löschen erst danach an. Ein Release, das seit dem Laden der Seite in Benutzung gekommen ist, wird ausgelassen, und ein Unknown-Release wird nur gelöscht, wenn du es in diesem Dialog erneut anhakst. Das Löschen selbst ist die Massenlöschung der Manage-Seite. Sie entfernt jede Kopie des Releases aus jedem Konto, das es hat.

**Wann gelesen wird.** Wenn du die Seite zum ersten Mal öffnest, werden alle Radarr und Sonarr unter `acquisition.sources` gelesen, einschließlich der Import- und Löschhistorie. Bei einer großen Bibliothek kann das Lesen der Historie eine Minute dauern. Danach zeigt die Seite, was zuletzt gelesen wurde und wann, bis du **Read Radarr and Sonarr again** wählst. Eine Quelle mit `enabled: false` wird trotzdem gelesen: Wenn du Acquisition ausschaltest, ändert das nichts daran, was der \*arr hält. Die Seite zeigt die Zähler jeder Quelle: gelesene Dateien, einem Release zugeordnet, auf einem Pfad außerhalb ihres `library_path` und innerhalb von `__magic__`, führen aber zu nichts. Wenn keine einzige Datei einer Quelle einem Release zugeordnet wird, prüfe ihren `library_path`.

Den gleichen Bericht findest du unter `/manage/duplicates/report.json`. Mit `POST /manage/duplicates/check` und `{"hashes": [...]}` werden die \*arr erneut gelesen, und du bekommst den Status jedes Releases zurück.

## Newznab und Torznab {#newznab-and-torznab}

Ein Indexer-Eintrag gibt mit `type` an, um welche Art es sich handelt. Fehlt die Angabe, gilt `newznab`, so wie bei allen Einträgen, die vor dieser Option geschrieben wurden. Die Suchanfrage ist für beide gleich, die Antwort aber nicht. Ein Newznab-Ergebnis ist eine NZB. Sie wird geholt und in `nzbs/` für das Usenet-Backend gespeichert. Ein Torznab-Ergebnis ist ein Info-Hash, der an ein Debrid-Konto übergeben wird. Ein Torznab-Ergebnis ohne Magnet oder `infohash`-Attribut wird übersprungen. zurg lädt nie eine `.torrent`-Datei herunter, also kann zurg mit einem Ergebnis, das nur so erreichbar wäre, nichts anfangen.

**Ein Torrent wird nur einem Konto hinzugefügt, das ihn schon hat.** Jedem Konto, das Hinzufügungen annimmt, wird der Hash angeboten. Ein Real-Debrid-Konto wird allerdings übersprungen, wenn es einen Release-Namen rundweg ablehnt. Die Caches sind unabhängig voneinander, und nur weil ein Konto ein Release gelöscht hat, heißt das nicht, dass das beim nächsten auch so ist. Das erste Konto, das ihn schon hat, nimmt ihn. Findet sich nirgends einer, ist das ein gewöhnlicher fehlgeschlagener Kandidat. Der Durchlauf geht dann in der Rangliste weiter zum nächsten Release, das ein anderer Torrent oder eine NZB sein kann.

Bei TorBox und Debrid-Link fügt ein Fehlschlag nichts hinzu. Bei AllDebrid und Offcloud wird er sofort wieder gelöscht. Real-Debrid und Premiumize bekommen den Torrent hinzugefügt und werden bis zu 20 Sekunden beobachtet. Gecachter Inhalt ist innerhalb von ein oder zwei Sekunden bereit. Alles, was danach noch lädt, wird wieder entfernt. So läuft auf dem Konto nie ein Download weiter. Ganz kostenlos ist ein Fehlschlag aber nicht. Er kann trotzdem auf das Limit der Hinzufügungen des Kontos angerechnet werden. Bei TorBox verbraucht er eine der 60 nicht gecachten Hinzufügungen, die pro Stunde erlaubt sind.

Das Konto mit `watchlist: true` bekommt den Torrent zuerst angeboten. Die übrigen folgen in der Reihenfolge deiner `providers:`-Liste. Ein Konto mit `add_torrents: false` bekommt nie einen Torrent angeboten.

`prefer` legt fest, welche Art zuerst versucht wird, wenn beide ein Ziel in derselben Auflösung erfüllen könnten. Die Auflösung kommt zuerst. Ein 2160p-Torrent, den ein Konto schon hat, wird also vor einer 1080p-NZB genommen, egal was `prefer` sagt. `usenet` ist der Standard, weil ein Usenet-Download einen Download kostet, während ein Torrent einen der Add-Slots des Kontos belegt. `torrents` dreht das um. `best` hebt den Unterschied ganz auf und nimmt, was die Rangliste vorne hat, also das größere Release innerhalb einer Auflösung.

Ein Film probiert pro Versuch bis zu drei Torrents aus. Jeder kostet eine Hinzufügung. Bis zu 24 seiner NZBs werden einzeln geprüft, so wie es im Abschnitt [choosing a movie's release](#choosing-a-movies-release) beschrieben ist. Bei `usenet` werden die NZBs einer Auflösung vor ihren Torrents versucht. Bei `torrents` kommen die Torrents zuerst. Bei `best` wartet jeder Torrent auf seinen Platz in der Rangliste. Die NZBs einer Auflösung werden gemeinsam an der Stelle ihres besten Eintrags versucht. Bei einer Radarr-Quelle werden die NZBs aller Auflösungen gemeinsam an der Stelle des besten Eintrags versucht, und zwar die günstigsten zuerst, wie es in diesem Abschnitt beschrieben ist. Ein Season-Pack probiert pro Versuch drei Releases aus, egal welcher Art. Genauso jede einzelne Episode.

Die Prüfung, auf die ein Grab wartet, unterscheidet sich je nach Quelle. Ein Usenet-Release wird bei den News-Servern geprüft. Nur so lässt sich herausfinden, ob der Post noch vorhanden ist. Ein `torbox_nzb`-Konto hat keine News-Server, gegen die geprüft werden könnte. Ein Grab dort wird daran geprüft, ob TorBox die NZB geholt hat. Ein Torrent wurde nur hinzugefügt, weil das Konto gemeldet hat, dass es den Inhalt schon hat. Zu prüfen bleibt daher nur, ob das Release mit Dateien in der Bibliothek angekommen ist. Genau das fragt die Prüfung ab. Ein Release, das das Konto als leer auflistet, wird wie ein toter Post aussortiert.

Eine Installation ohne NZB-Konto (`nzb` oder `torbox_nzb`) kann die Beschaffung trotzdem nur über Torznab-Indexer laufen lassen. Ihre Newznab-Indexer werden dort nicht durchsucht, weil auf dieser Installation keine NZB abgespielt werden kann. Das Log meldet das für jeden von ihnen einmal. Eine Installation ohne Konto, das Torrents annimmt, durchsucht ihre Torznab-Indexer ebenfalls nicht, aus demselben Grund. In beiden Fällen ist ein Release einer Art, für die die Installation keinen Ort hat, nie ein Kandidat. Deshalb verbraucht es keinen der Versuche eines Durchlaufs, und eine Quelle wie Radarr wird danach nie gefragt.

### Limits der Indexer und abgelehnte Schlüssel {#indexer-limits-and-refused-keys}

**zurg hält sich an DMMs Limit, statt dagegen zu laufen.** DMM erlaubt einem Sponsoren-Schlüssel 20 Suchen pro Minute über alle seine Torrent-Feeds hinweg, deshalb schickt zurg an DMM höchstens eine Suche alle drei Sekunden. Eine Suche, die darüber hinausgeht, wartet ihren Zug ab, und Warten gilt nicht als fehlgeschlagene Suche. Eine Suche, deren Zug erst nach dem Ende des Versuchs für ihren Titel käme oder mehr als zwei Minuten entfernt wäre, wird nicht ausgeführt: Der Titel geht mit dem weiter, was die anderen Indexer gefunden haben.

**Ein Indexer, der mit 429 oder 503 antwortet, wird so lange in Ruhe gelassen, wie er es verlangt.** Jede Suche, jeder NZB-Download und jede Fähigkeitsprüfung wartet seine `Retry-After`-Zeit ab, höchstens zwei Minuten, einschließlich Anfragen, die bereits auf ihren Zug warten. Ein Indexer, der länger verlangt, wird bis dahin nicht angefragt.

**Mehrere zurgs auf einem DMM-Schlüssel teilen sich dessen 20 Suchen.** Jeder richtet sich nach dem gesamten Budget, also laufen zwei oder drei auf einem Schlüssel trotzdem in DMMs Limit, und jede Ablehnung pausiert die DMM-Suchen dieses zurgs für eine Minute. Ein Titel kann dann länger auf seine Suche und seinen Download warten.

**Ein abgelehnter Schlüssel wird eine Stunde lang in Ruhe gelassen.** Ein Indexer, der mit Fehler 100 (falscher Schlüssel) oder 101 (Konto gesperrt, was DMM bei abgelaufenem Sponsoring antwortet) antwortet, wird eine Stunde lang nicht mehr angefragt, weder für Suchen noch für NZB-Downloads. Das Log sagt das einmal, zum Beispiel `DMM torrents refused the API key: check dmm_api_key`, und die Acquisition-Seite führt ihn unter **Indexers not asked now** auf. Ein Schlüssel, den du in `config.yml` änderst, wird sofort wieder angefragt. Jeder andere Fehler gilt nur für die eine Suche.

## Das Release eines Films auswählen {#choosing-a-movies-release}

Die Usenet-Kandidaten eines Films werden in der Reihenfolge ausprobiert, wie teuer ihre Prüfung ist, nicht nur danach, wie gut sie sind. Ein Post mit einem einzelnen benannten Video kostet zurg zwei Artikel-Lesevorgänge und ist meist vollständig. Ein Archiv-Set mit vierzig Teilen kostet dagegen einen Größen-Durchlauf und einen Lesevorgang an beiden Enden jedes Teils, und etwa zwei Drittel der Mehrteiler-Remux-Sets bei den Indexern sind verschwunden. Die eigene `files`-Anzahl des Indexers verrät die Form, deshalb werden die Kandidaten danach sortiert: zehn Dateien oder weniger, dann bis zu dreißig, dann mehr, dann unbekannt, und innerhalb jeder Gruppe nach der Anzahl. Haben Posts die gleichen Kosten, kommt ein Titel mit WEB-DL oder WEBRip zuerst, wenn eine Quelle wie Radarr Releases nach einem eigenen Profil bewertet. Danach kommt Blu-ray, dann der Rest, und innerhalb davon der größere Post zuerst. Das Ranking der Quelle selbst wird hier nicht verwendet. Es ist nur bekannt, wenn man die Quelle danach fragt, und zurg fragt nur nach einem Release, wenn es ihn gleich prüfen will. Ohne Quelle entscheiden zuerst die Qualitätsrangfolge und dann die Größe. Wo keine Quelle die Kandidaten bewertet, kommt die Auflösung, die die Einstellung `quality` verlangt, vor den Kosten. Eine Watchlist mit `best` bekommt also trotzdem die beste verfügbare Auflösung, und innerhalb davon zuerst den günstigsten Post. Ergebnisse, die nach einem Teil eines geteilten Posts benannt sind (`[1/9] "Movie.part1.rar"`), sind nie Kandidaten. Und von zwei Posts mit dem gleichen Namen wird nur der mit weniger Dateien behalten, weil die Bibliothek nur einen davon aufnehmen kann.

Dann werden bis zu 24 Kandidaten geprüft: Jede NZB wird geholt und mit dem eigenen Parser von zurg gelesen. Ein Post mit höchstens zwei Inhaltsdateien, davon eine benannte `.mkv`-, `.mp4`-, `.m4v`-, `.avi`-, `.mov`- oder `.ts`-Videodatei mit mindestens 500 MB, ist ein direkter Post. PAR2-Volumes und Begleitdateien wie `.nfo`, `.sfv`, `.srr`, `.nzb`, Bilder, `.txt`, `.url` und `.exe` zählen nicht als Inhalt. Der erste direkte Post wird sofort gespeichert. Archiv-Posts werden zurückgehalten, bis die direkten Posts in der Liste aufgebraucht sind. Danach werden sie mit der geringsten Anzahl an Teilen zuerst probiert, und zwar über einen gatekeeper, der nicht mehr als sechs Archiv-Releases gleichzeitig bei den News-Servern warten lässt. Ein Post, der nur Reparaturdaten und Begleitdateien enthält, wird nie gespeichert. Die geprüften NZBs werden im Speicher gemerkt. Wenn ein gespeichertes Release sich als tot herausstellt und der Titel erneut probiert wird, kommt man zum nächsten Kandidaten, ohne die früheren ein zweites Mal zu holen. Suchen und NZB-Downloads teilen sich pro Indexer ein Limit für gleichzeitige Anfragen. Antwortet ein Indexer mit `429` oder `503`, wird er nach einer Pause erneut gefragt, und sein `Retry-After` wird beachtet. Das Dashboard zeigt jeden Schritt: die Suche, welcher Kandidat gerade geprüft wird und was gespeichert wurde. Bei Serien wird der frühere Durchgang genutzt, also die drei am besten bewerteten Releases, die nicht zurückgestellt sind. Bewertet eine Quelle die Releases, wie Sonarr es tut, wird jedes Release zuerst dort vorgelegt. Ein Release, das sie ablehnt, zählt dann nicht zu den drei. `best_first` ändert die Reihenfolge beider Durchgänge, wie im nächsten Abschnitt beschrieben.

## Das Beste des Profils zuerst nehmen {#taking-the-profiles-best-first}

```yaml
acquisition:
  best_first: true
```

Standardmäßig ausgeschaltet. Wenn du es einschaltest, folgt der erste Abruf einer Radarr- oder Sonarr-Quelle der Reihenfolge der Präferenz im Qualitätsprofil, statt danach, was eine Veröffentlichung kostet, um sie zu prüfen. Die Plex-Watchlist und Seerr haben kein Profil und sind nicht betroffen. Die Acquisition-Seite zeigt an, wenn es aktiviert ist.

- **Die beste Auflösung des Profils kommt zuerst.** Jede Veröffentlichung wird nach der Auflösung eingeordnet, die in ihrem Titel steht. Ihr Platz ist die beste Qualität, die das Profil in dieser Auflösung erlaubt. zurg liest das aus dem Profil, das es bereits hat, und fragt Radarr und Sonarr nicht weiter nach. WEB-DL, Blu-ray und Remux einer Auflösung teilen sich einen Platz. Innerhalb eines Platzes nimmt ein Film trotzdem die Veröffentlichung, die am günstigsten zu prüfen ist. Eine Serie nimmt die, die `quality` zuerst einordnet. Ein Titel, der keine Auflösung nennt, kommt ganz nach hinten.
- **Der Cutoff zählt als oberste Stufe.** Solange das Profil Upgrades erlaubt, zählt jede Qualität ab dem Cutoff genauso wie der Cutoff selbst. Der Upgrade-Durchlauf würde keine davon ersetzen. Ein Profil, das bis WEB 1080p upgradet, gewinnt durch Best first nichts, auch wenn es zusätzlich 2160p erlaubt. Ein Profil, das keine Upgrades erlaubt, behält seine ganze Reihenfolge. Seine erste Datei ist die, die es behält.
- **Es fällt im Profil Stufe für Stufe zurück.** Eine Veröffentlichung, deren NZB nicht geladen oder nicht gelesen werden kann, wird übersprungen. Eine, die die Newsserver ablehnen, wird wie bisher beiseitegelegt. Dann wird die nächste Veröffentlichung in der Reihenfolge des Profils probiert. Ein Versuch liest trotzdem insgesamt nicht mehr als 24 NZBs, egal auf welchem Platz sie stehen.
- **Es kommt vor der Usenet- oder Torrent-Präferenz.** Ein Torrent, den ein Konto bereits hat, wird genommen, bevor eine NZB, die das Profil niedriger einordnet. `prefer` entscheidet weiterhin zwischen einer NZB und einem Torrent auf demselben Platz.
- **Ein Season-Pack muss so gut sein wie die einzelnen Episoden.** Ein Pack, das in derselben Suche schlechter eingeordnet ist als eine einzelne Episode, wird übersprungen. Die Episoden werden dann einzeln genommen. Sonarr trifft dieselbe Wahl. Nur diese eine Suche wird verglichen. Eine Episode wird nicht noch einmal einzeln gesucht, falls es eine bessere Veröffentlichung von ihr gibt.

Das hat einen Preis. Die Spitze eines 2160p-Profils besteht größtenteils aus Remux- und Blu-ray-Sets mit vierzig Bänden oder mehr und nicht aus einzelnen Videodateien. Solche Sets brauchen länger zum Prüfen. Sie fehlen öfter auf den Newsservern. Außerdem warten sie auf einen Platz am archive gate. Deshalb kommt die erste Datei meist später. Sind alle besten Veröffentlichungen eines Titels weg, wird jede davon abgerufen, geprüft und beiseitegelegt, bevor zurg im Profil eine Stufe nach unten geht. Eine Staffel, die als einzelne Episoden geholt wird, sind mehrere Abrufe, wo ein Pack einer gewesen wäre. Gespart wird der zweite Abruf. Eine erste Datei auf dem Cutoff wird nie aktualisiert.

## Was das Erwerben mit der eigenen Liste der Quelle macht {#what-acquiring-does-to-the-sources-own-list}

Eine Plex-Watchlist ist eine Liste, die jemand selbst zusammengestellt hat, und sie ist der einzige Hinweis darauf, dass diese Person einen Titel wollte. Plex speichert keine Historie für entfernte Einträge. Zwei Einstellungen legen fest, was zurg damit machen darf. Beide gelten für `plex_watchlist`-Quellen. Seerr- und Radarr-Quellen besitzen keine Liste, in die zurg schreibt, daher haben beide dort keine Wirkung.

`remove_after_grab` (Standard `true`) entfernt einen beschafften Titel von der Watchlist, sobald die dazugehörige Veröffentlichung geprüft wurde. Das macht die Funktion schon immer so: Die Watchlist wird als Warteschlange gelesen, und ein Titel, den zurg besorgt hat, ist erledigt. Setzt du den Wert auf `false`, bleibt die Watchlist eine Watchlist, also eine dauerhafte Liste zum Durchstöbern, die zurg im Hintergrund abarbeitet, ohne sie zu verändern. Einen Titel auf der Liste zu lassen kostet beim erneuten Prüfen nichts. Der Nachweis deckt ihn bereits ab, daher wird kein Indexer erneut danach gefragt.

Ein Titel, für den zurg nichts bekommen hat, bleibt unabhängig von dieser Einstellung auf der Watchlist. Wenn alle Veröffentlichungen, die den Titel klären, bereits in der Bibliothek waren, deine eigene Kopie oder eine, die eine andere Anfrage hereingeholt hat, wurde nichts geholt oder hinzugefügt. Das Entfernen würde dann nur deine Liste verändern. Diese Veröffentlichungen werden trotzdem geprüft, und der Titel gilt als erledigt. Solange er auf der Liste steht, wird er also nicht erneut gesucht. Wird er entfernt und später wieder hinzugefügt, bleibt er wieder stehen. Eine Show, von der zurg irgendeine Staffel oder Folge geholt hat, ist eine, die es bekommen hat, und sie verschwindet wie bisher.

`only_new_items` (Standard `true`) übernimmt beim ersten Lauf einer Quelle alles, was die Liste bereits enthält, und handelt nur bei Einträgen, die danach hinzukommen. Wenn du die Funktion aktivierst, soll sie eine Liste zu beobachten beginnen und nicht einen Abend damit verbringen, alles darauf abzuarbeiten. Setzt du den Wert auf `false`, behandelst du die vorhandene Liste als Rückstand.

Er gilt **einmalig, beim ersten Lauf einer Quelle**. Eine Quelle, die bereits eine Warteschlange hat, läuft schon, und diese Warteschlange hält fest, was sie erledigt hat und was nicht, nicht dieser Schalter. Wenn du ihn also später einschaltest, geht ein bereits laufender Rückstand nie verloren. Ein übernommener Titel bleibt übernommen, solange er auf der Liste steht. Wenn du ihn entfernst und wieder hinzufügst, ist das eine ganz normale neue Anfrage.

## Einen Grab überprüfen {#verifying-a-grab}

Eine gespeicherte NZB ist noch kein Release. Dass der Indexer antwortet, dass die Antwort sich als NZB parsen lässt und dass die Datei in `nzbs/` ankommt, sind Fakten über den Indexer, nicht über den Post. Deshalb wird jede beschaffte NZB bei den konfigurierten Newsserver-Konten geprüft, bevor die Engine die Anfrage bestätigt. Die ersten sechzehn Artikel und der letzte jeder Inhaltsdatei werden mit `STAT` abgefragt. Außerdem wird der erste Artikel jeder Datei komplett geladen, dazu ein paar weitere bei einem Release mit wenigen Dateien (höchstens vierundsechzig). Der Grund: Ein Newsserver kann `STAT` für einen Artikel beantworten, den er schon entfernt hat. Ein Artikel, den `STAT` ablehnt, wird ebenfalls komplett geladen, bevor er als verloren gilt, denn ein Newsserver kann `STAT` auch für einen Artikel verweigern, den er noch ausliefert (NewsDemon hat das am 2026-10-21 getan). Pro Release sind das höchstens sechzehn solcher Artikel. Es ist derselbe Durchlauf, den `/api?mode=addfile` für Sonarr und Radarr macht. Es gibt drei mögliche Antworten, und sie auseinanderzuhalten ist der springende Punkt:

- **Artikel fehlen.** Der Grab zählt nicht. Die Quittung wird wieder geöffnet, das Ziel wird also erneut gesucht, und das Release wird 30 Tage lang als tot vermerkt. So nimmt der nächste Versuch den nächsten Kandidaten statt wieder den, der schon in der Bibliothek liegt. Ein Release auf dieser Liste ist kein Kandidat: Es wird nicht geladen und verbraucht keinen der Kandidaten, die ein Versuch durchprobiert. So wird eine Reihe toter Posts ganz oben in einem Ranking übersprungen, statt alles darunter unerreichbar zu machen. Ein totes Staffelpaket setzt die ganze Staffel wieder auf gesucht; die einzelnen Episoden werden stattdessen genommen. Eine NZB-Beschaffung, die zwar selbst gespeichert wurde, wird danach aus dem Watch-Verzeichnis gelöscht, damit ein Neustart sie nicht erneut lädt und prüft, bevor die Bibliothek wieder offen ist. Eine NZB, die schon im Watch-Verzeichnis oder in der Bibliothek lag, und eine, aus der Sonarr oder Radarr importiert hat, bleibt an ihrem Platz.
- **Die Konten konnten nicht gefragt werden.** Ein Server ist nicht erreichbar, ein Konto wird gedrosselt, oder der häufige Fall: Die Bibliothek hat die neue NZB noch nicht aufgelistet. Es wurde nichts festgestellt, also wird auch nichts entschieden. Die Anfrage wird nach 20 Sekunden erneut angesehen, dann nach 40 und 80 Sekunden, danach alle zwei Minuten. Die Wartezeit kostet keinen Wiederholungsversuch. Eine Prüfung, der einfach die Zeit ausgegangen ist, zählt nicht als dieser Fall: Sie wird sofort mit ihrer vollen Zeit neu gestartet, höchstens dreimal, bevor gewartet wird. Diese Zeit beträgt fünf Minuten, bei einem Release mit vielen Dateien über ein Konto mit wenigen Verbindungen auch länger. zurg berechnet sie aus den beiden Werten, aus der langsamsten bisher gemessenen Prüfung und aus den sechs Prüfungen, die gleichzeitig laufen, und verdoppelt sie dann. Ein 90-teiliges Release auf vier Verbindungen bekommt etwa 53 Minuten, während fünf Minuten bei jedem Versuch ablief, bis das Release ungeprüft aussortiert wurde. Zwanzig Prüfungen über zwei Stunden, die nichts feststellen, sortieren das Release so aus wie ein totes, und der nächste Versuch probiert ein anderes Release. Die Anfrage wird niemals für ein Release bestätigt, das niemand prüfen konnte.
- **Das Release ist vorhanden.** Die Quittung gibt auf, was sie gehalten hat, und die Bestätigung geht raus.

Die Prüfung wartet, bis zurg die genauen Dateigrößen des Releases ermittelt hat oder aufgegeben hat, sie zu ermitteln. Dieselbe Stelle prüft auch der SABnzbd-Endpunkt. Die Größenermittlung liest den ersten Artikel jeder Datei, und das tut die Prüfung ebenfalls. Liefen beide gleichzeitig, wurden sie nur langsamer. Bei einer Liste von 99 Filmen hat es fast neun Minuten gedauert, bis die letzte Datei in Radarrs Ordner lag, weil jedes Release sofort nach dem Listen geprüft wurde. Eine Prüfung, die noch auf die Größen wartet, wenn ihre Zeit abläuft, wird sofort neu gestartet, genau wie eine Prüfung, der die Zeit ausgegangen ist. Ein Release, das nach 30 Minuten immer noch gemessen wird, wird trotzdem geprüft. Es werden nie mehr als sechs Releases gleichzeitig geprüft, die übrigen warten ihren Platz ab.

Die Prüfung liest nur. Sie verschiebt keine Artikelinhalte in den Cache und vermerkt keine toten Artikel. So kann sie keine Datei zum Schweigen bringen, die gerade abspielt. Hat die Größenermittlung gerade den ersten Artikel einer Datei geladen, liest die Prüfung diese Kopie, statt ihn noch einmal zu laden.

Eine Installation ohne NZB-Konto (`nzb` oder `torbox_nzb`) hat nichts, womit sie eine NZB-Beschaffung prüfen könnte. Die Beschaffung läuft dort trotzdem, wenn ein Debrid-Konto Torrents annimmt. Jeder Torrent wird danach geprüft, ob er mit Dateien in der Bibliothek ankommt, wie es unter [Newznab and Torznab](#newznab-and-torznab) beschrieben ist. Außerdem muss er etwas enthalten, das sich abspielen lässt: ein Video, eine Audiodatei oder ein Archiv, das zurg streamt (RAR, 7z, zip oder nummerierte Teile). Ein Torrent, der nur ein Programm, ein Disc-Image oder Text enthält, ist ein Fake. Solche Fakes tauchen in den ersten Stunden nach der Ausstrahlung neuer Episoden häufig auf. Er wird wie ein toter Post aussortiert, und das nächste Release wird sofort probiert. Hat zurg ihn für diese Anfrage zum Konto hinzugefügt, wird er dort wieder gelöscht. Ein Torrent, den das Konto schon hatte, bleibt, wo er ist. Eine NZB-Beschaffung wird ohne NZB-Konto nie bestätigt, weil es dann niemanden gäbe, der sie prüfen oder abspielen könnte. Eine Anfrage, die noch aus der Zeit vor dem Entfernen des letzten NZB-Kontos wartet, wird wie ein toter Post aussortiert, und das nächste Release wird probiert.

## Speicherung und Wiederherstellung {#persistence-and-recovery}

`data/acquisition.json` speichert Quell- und Anfrage-IDs, Versuche, Wiederholungsfristen, laufende Arbeit und Belege für einzelne Acquisitions, auch für Episoden. Außerdem merkt es sich pro Quelle, dass ein erster Snapshot übernommen wurde. So wird `only_new_items` einmal entschieden und nicht bei jedem Neustart neu.
Passende Medien-Ziele und Editionen verwenden Belege quellenübergreifend wieder. Release-Dateinamen werden außerdem gegen die Bibliothek und gespeicherte NZBs dedupliziert. Ein Beleg enthält auch die Grabs, auf deren Antwort vom News-Server er noch wartet. Das Ledger enthält die Releases, die bereits als tot erkannt wurden. So bestätigt ein Neustart während des Wartens keinen ungeprüften Grab und gibt kein totes Release zurück an das Ranking.
Ein Beleg wird nicht für immer vertraut. Bevor ein Titel als vorhanden gilt, prüft zurg, dass das, was ihn erledigt hat, noch da ist: das platzierte Video in einem Radarr- oder Sonarr-Ordner, oder bei einem DMM-Wunschtitel, einem Plex-Watchlist- oder Seerr-Titel das Release selbst in der Bibliothek. Wurde es seitdem gelöscht, wird erneut danach gesucht. Das gilt auch dann, wenn der Titel noch gelistet ist und der Job fertig war. Ein Release, das du auf der Verwaltungsseite gelöscht hast, wird nicht wieder geholt.

Jedes gespeicherte Release wird sofort auf die Festplatte geschrieben. Versuchszähler und Wiederholungszeiten werden innerhalb einer Minute geschrieben. Ein Absturz kann also bis zu einer Minute davon verlieren, aber nie einen Grab.
Beim Schreiben wird eine temporäre Datei geflusht, das Ledger ersetzt und, wo es unterstützt wird, das übergeordnete Verzeichnis geflusht. NZBs, die vor einem Absturz geschrieben wurden, werden wiederverwendet, auch wenn der letzte Ledger-Schreibvorgang nicht fertig wurde. Sobald eine Acquisition erfasst ist, versuchen Plex-Entfernungswiederholungen nicht mehr, den Titel erneut zu holen.

Fehlgeschlagene Versuche werden nach 5, 10 und 15 Minuten wiederholt, dann nach einer Stunde und danach nach sechs Stunden. Ab dann wartet ein Titel jeweils halb so lange, wie er schon fehlschlägt. Die Wartezeiten wachsen also: etwa einen halben Tag nach einem Tag Fehlschlägen, zwei Tage nach vier, höchstens etwa eine Woche, plus/minus einem Viertel. So werden Titel, die zusammen fehlgeschlagen sind, nicht zusammen erneut versucht. Ein Versuch, der seine fünf Minuten aufgebraucht hat, ohne etwas zu finden, zählt ebenfalls als Fehlschlag.
Ein Versuch, der nichts fand, während einer deiner Indexer nicht angefragt werden konnte, zählt nicht. Der Indexer hat dann darum gebeten, bis zu einem Zeitpunkt in Ruhe gelassen zu werden, der höchstens einen Tag entfernt ist (ein `Retry-After`). In diesem Fall wird der Titel nach dieser Zeit erneut versucht, höchstens genauso lange danach noch einmal. So fragt eine Warteschlange von Titeln den Indexer nicht alle auf einmal an. Ruht ein Indexer zehn Minuten, folgt der nächste Versuch innerhalb von zwanzig. Das passiert höchstens dreimal hintereinander, danach zählt der Versuch wie üblich. Ein Indexer, der keine Zeit nennt, etwa einer, der mit 410 Gone antwortet oder seinen Schlüssel ablehnt, wird nicht abgewartet.
Ein Titel, der seit zwei Wochen fehlschlägt und dabei mindestens acht Versuche hatte, wird **parked**: zurg fragt die Indexer nicht mehr danach. Er bleibt auf der acquisition page als parked stehen, mit Angabe, wie lange und warum er fehlschlug, und das Log meldet das einmal. **Resume** auf dieser Seite startet ihn wieder, für einen einzelnen Titel oder für alle geparkten Titel einer Quelle, und zwar ab der ersten kurzen Wiederholung. Hört eine Quelle auf, einen Titel zu listen, und listet ihn später wieder, hat sie ihn neu angefordert. Das setzt ihn ebenfalls fort.
Ein Grab, den die News-Server bestätigen, startet die zwei Wochen eines Titels neu. Eine Staffel, die noch Episoden findet, wird so nie geparkt. Auch ein Upgrade wird nicht geparkt, aus welcher Quelle auch immer. Sein besseres Release kann erst Monate später erscheinen, und der Titel bleibt gelistet. Deshalb behält er seine Wiederholungen höchstens eine Woche auseinander. Gleiches gilt für alles auf deiner DMM-Wunschliste: Ein Film, der noch nicht erschienen ist, oder ein alter, den niemand gepostet hat, bleibt gewünscht, bis er geholt oder von dir entfernt wird. Zähler und Fristen überstehen Neustarts, auch lange Abschaltungen.

Eine Warteschlange, die für immer fehlschlägt, kostet etwas, was die Titelliste nicht zeigt. Auf einer Installation fanden tausende Radarr- und Sonarr-Titel nichts, wurden alle sechs Stunden für immer erneut versucht und brachten einen Indexer von ein paar hundert Anfragen am Tag auf Zehntausende. Der Indexer sperrte daraufhin das Konto. Die meisten waren Filme ohne Usenet-Release und Upgrades, bei denen jedes Release, das das Profil erlaubte, bereits abgelehnt worden war. Offene Seerr-Anfragen bleiben überwacht. Plex-Elemente verlassen die Watchlist erst, wenn alle geplanten Staffeln erfasst *und* geprüft sind (ein NZB gegen die News-Server oder bei einem `torbox_nzb`-Konto daran, ob TorBox ihn geholt hat; ein Torrent daran, dass die Bibliothek mit etwas Abspielbarem erreicht wird). Das passiert nur, wenn `remove_after_grab` es erlaubt, und nur, wenn zurg für sie etwas geholt hat. Die Einzelfolgen-Ausweichlösung bleibt auf Episoden beschränkt, die in Indexer-Ergebnissen gefunden wurden.

Eine nicht erreichbare Quelle pausiert nur ihre eigene Arbeit. Ein fehlgeschlagenes Schreiben des Status pausiert weitere Acquisition, bis das Speichern gelingt. Ein unlesbares oder nicht unterstütztes Ledger pausiert die Acquisition und bleibt als Datei erhalten. Repariere oder stelle es wieder her und starte zurg neu. Andere zurg-Dienste laufen weiter.

Die bisherige `data/plex-watchlist.json` wird einmalig importiert, samt Verlauf, Wiederholungen und Versuchen, die nur noch auf die Plex-Entfernung warten. Die Originaldatei bleibt erhalten. Beide Ledger sind in normalen Backups enthalten, ohne `--include-caches`. Behalte `data/` und `nzbs/` bei Container-Austauschen.

## Einen weiteren Adapter hinzufügen {#adding-another-adapter}

Implementiere `acquisition.Source` in einem eigenen Paket:

1. `ID()` identifiziert die Instanz über Neustarts hinweg.
2. `List(ctx)` gibt einen vollständigen Snapshot von `Item`-Referenzen zurück. Schlägt eine Paginierung fehl, schlägt auch der Snapshot fehl. Speichere nur Metadaten, niemals Zugangsdaten oder komplette API-Benutzerobjekte.
3. `Resolve(ctx, item)` prüft das Item erneut und gibt normalisierte Ziele für Filme, Staffeln oder Episoden zurück. `Gone` bricht unerwünschte Arbeit ab. `Follow` hält eine offene Anfrage im Blick, nachdem die aktuellen Ziele erworben wurden.
4. `Complete(ctx, item)` bestätigt eine einmalige Acquisition. Es muss verkraften, dass es nach einem Absturz wiederholt aufgerufen wird. Eine reine Lese-Liste kann einen No-op verwenden. Die Engine ruft es erst auf, wenn jeder Grab hinter dem Item geantwortet hat. Ein Adapter muss deshalb nie selbst ein Release prüfen und darf den Aufruf nicht als Beleg für mehr werten als dafür, dass er erfolgt ist.

Eine Quelle mit eigenem Quality-Profil kann zusätzlich `acquisition.Assessor` implementieren und jedes Kandidaten-Release nach den eigenen Regeln bewerten. Die Radarr- und Sonarr-Adapter machen das über ihre eigenen Parser.

Registriere den Konfigurationstyp und die Factory im acquisition-Service. Die Queue, die Persistenz, die Retries und der Executor brauchen keinen quellenspezifischen Zweig. Trakt, MDBList und Simkl passen zu diesem Vertrag, sind aber noch nicht implementiert.
