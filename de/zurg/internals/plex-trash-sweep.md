# Abstimmung des Plex-Papierkorb-Durchlaufs mit dem eigenen Dateistatus von zurg {#aligning-the-plex-trash-sweep-with-zurgs-own-file-status}

## Zweck dieses Dokuments {#purpose-of-this-document}

Die Plex-Papierkorb-Bereinigung entscheidet derzeit anhand von **fehlender Datei plus einem Altersтimer**, was aus einer Plex-Bibliothek entfernt wird. zurg weiß bereits viel Besseres: ob der Inhalt hinter dieser Datei reparierbar oder dauerhaft tot ist. Diesen Status fragt es aber nicht ab.

Dieses Dokument ist der Plan, diesen Timer durch dieses Wissen zu ersetzen. Es soll **vor** dem Schreiben von Code geprüft werden, weil die Änderung festlegt, was aus einer Medienbibliothek gelöscht wird, und das aktuelle Verhalten ist in beide Richtungen falsch: Es wartet zwei Wochen, bevor Inhalte entfernt werden, die schon am ersten Tag bekanntermaßen tot sind, und es löscht Inhalte, die zurg gerade noch aktiv repariert.

Es hält fest, was im Code und in einer laufenden Bibliothek geprüft wurde, was vorgeschlagen wird und was bewusst unverändert bleibt. Alles unten als Tatsache Angegebene wurde am 16.08.2026 am laufenden System überprüft, nicht aus den Namen abgeleitet.

Umfang: `internal/plexsweep`, `internal/plexdb` und eine neue reine Lese-Abfrage in `internal/torrent`. Am Reparaturverhalten selbst ändert sich nichts.

---

## 1. Hintergrund — was ausgeliefert wurde und warum es überarbeitet werden muss {#1-background--what-shipped-and-why-it-needs-revisiting}

Vier Commits haben den Sweep eingeführt:

| Commit | Was |
|---|---|
| `4737b677` | Warnung, wenn Plex' `autoEmptyTrash` aktiv ist |
| `020042a3` | Der Sweeper: Erkennung, Schutzprüfungen, Reparatur, Entfernung pro Eintrag |
| `51cc9f69` | Konfigurations-UI im Dashboard und Dokumentation |
| `1a481a8f` | Reparaturen zählen auf das Limit, nicht nur Entfernungen |
| `c6f41621` | `plex_trash_sweep_min_age_days`, Standard 14 |

Die oberste Regel des Sweeps bleibt unverändert und gilt weiterhin: **Nichts,
das noch eine Datei hat, wird jemals entfernt.** Einträge mit einer vorhandenen
Datei werden repariert oder bleiben mit ihrem Papierkorb-Symbol unangetastet.
Serien und Staffeln mit noch vorhandenen Episoden werden nie angefasst.
Entfernt wird pro Eintrag, nie über Plex' sektionsweites `emptyTrash`.

Überarbeitet wird nur die Regel, wann ein tatsächlich fehlender Eintrag entfernt
werden darf.

### Der Timer ist ein Ersatz für eine Frage, die zurg direkt beantworten kann {#the-timer-is-a-proxy-for-a-question-zurg-can-answer-directly}

`plex_trash_sweep_min_age_days` wartet 14 Tage, bevor es einen Eintrag entfernt. Der Gedanke dahinter: Das rote Papierkorb-Symbol ist der einzige Hinweis für den Betreiber, dass Inhalte verschwunden sind. Wird der Eintrag gelöscht, geht dieser Hinweis verloren.

Die Absicht stimmt, der Mechanismus ist aber eine Vermutung. Er liegt in beide Richtungen falsch:

- Ein Torrent mit dem Status `infringing torrent` ist **sofort als tot bekannt**. Den Plex-Eintrag zwei Wochen lang stehen zu lassen, bringt niemandem etwas, denn warten kann ihn nicht zurückbringen.
- Ein Torrent, der noch wiederholt wird, braucht unter Umständen **länger als 14 Tage**, bis er zurückkommt. Der Timer löscht seinen Eintrag, während zurg noch daran arbeitet. Das ist der schlimmere Fehler, weil er einen Bibliothekseintrag für Inhalte zerstört, die danach wieder auftauchen.

---

## 2. Geprüfte Fakten {#2-verified-facts}

### 2.1 Das Zustandsmodell von zurg {#21-zurgs-state-model}

Es gibt drei Dateizustände und zwei Torrent-Zustände (gezählt über `internal/torrent`, ohne Tests):

| Ebene | Zustände |
|---|---|
| `File.State` | `ok_file`, `broken_file`, `deleted_file` |
| `Torrent.State` | `ok_torrent`, `broken_torrent` |

Beide sind `pkg/fsm`-Maschinen. `FSMWithTime` speichert den Unix-Zeitstempel jedes Übergangs und unterstützt `SinceWhen`. Damit lässt sich schon beantworten, „wie lange ist das schon kaputt“, ohne etwas hinzufügen zu müssen.

**Eine kaputte Datei verurteilt den ganzen Torrent.**
`MarkFileBrokenAndEnqueueRepair` (`internal/torrent/hooks.go:215-234`):

```go
changed := file.State.Set("broken_file", torrent.State.GetMutex()) == nil
...
if err := torrent.State.Set("broken_torrent"); err == nil {
    t.repairLog.Infof("Torrent state changed: %s [? -> broken_torrent] (has broken file)", ...)
}
```

Im Log steht *"has broken file"*, im Singular. Ob eine von zehn oder alle zehn Dateien kaputt sind, ergibt denselben Torrent-Zustand. Die Dateizustände werden nirgends zusammengefasst.

**`Unfixable` fasst über Accounts zusammen, nicht über Dateien.**
`markAsUnrepairable` (`internal/torrent/unplayable_unrepairable.go:44-71`):

```go
if cp != nil {
    cp.SetUnrepairableReasonIfEmpty(reason)      // one account's copy
    entryCondemned = t.repairableCopy(torrent) == nil
}
if entryCondemned {
    torrent.SetUnrepairableReasonIfEmpty(reason) // the entry
}
```

Der Eintrag wird verurteilt, wenn **keine reparierbare Kopie mehr übrig ist**. Bewusst nicht „jede Kopie hat einen Grund“. Eine Kopie, die ohnehin nie repariert werden könnte (das Usenet-Backend hat keinen Magnet-Adder), würde sonst ein totes Release dauerhaft für eine Reparatur infrage kommen lassen. `File` hat überhaupt kein Feld für Unreparierbarkeit (`internal/torrent/file_types.go`).

Die drei Ebenen beantworten also drei verschiedene Fragen, und **keine davon beantwortet die Reichweite**:

| Ebene | Sagt dir | Kann dir nicht sagen |
|---|---|---|
| `File.State` | ob diese Datei ok / kaputt / gelöscht ist | ob sie endgültig tot ist |
| `TorrentCopy.UnrepairableReason` | dass die Kopie dieses Accounts tot ist | irgendetwas über andere Accounts |
| `Torrent.UnrepairableReason` | dass kein Account das reparieren kann | wie viel vom Release betroffen ist |

### 2.2 Live-Messungen (eine Produktionsbibliothek, 2026-08-16) {#22-live-measurements-a-production-library-2026-08-16}

Die Anteile unten beziehen sich auf die kaputten Torrents, die etwa **3% der Bibliothek** ausmachten.

**Fast alle kaputten (98%) haben einen `Unfixable`-Grund**:

| Grund | Anteil der kaputten |
|---|---|
| stalled download | 38% |
| infringing torrent | 37% |
| repair failed | 15% |
| duplicate file IDs (pack torrent) | 4% |
| rar'ed by RD | 1% |
| repair failed, no seeders | 1% |
| the lone cached file is broken | unter 1% |
| invalid file ids | unter 1% |
| repair failed, download status: error | unter 1% |
| provider cannot re-add torrents | unter 1% |

**Die restlichen (2%) sind kaputt, ohne dass ein Grund angegeben ist** – sie lassen sich aber noch reparieren.

**Aber `Unfixable` heißt nicht gleich tot.** zurg sortiert diese Gründe schon in dauerhaft und wiederherstellbar ein (`internal/torrent/unrepairable_reasons.go:44-70`).
`permanentReasons` enthält acht Urteile, die kein erneuter Versuch ändern kann: infringing, unsupported, unavailable, invalid, too big, not allowed, no repairable files, invalid file ids – dazu jeder Grund mit dem Präfix `repair failed, download status:`.
Alles andere, auch die beiden größten Gruppen oben, ist ausdrücklich nur vorübergehend: `stalled download`, `repair failed`, `duplicate file IDs`, `rar'ed by RD`, `not cached`, `the lone cached file is broken`, `full torrent repair failed`.

`repair failed, no seeders` war der neunte Grund, als die Anteile oben erhoben wurden. Die Einträge, die diesen Grund hier noch tragen, sind der Grund, warum er es nicht mehr ist: Kein Backend, mit dem zurg spricht, meldet Seeder, also wurde dieses Urteil nie gemessen. Es wurde aus einer Reparatur abgeleitet, der die Zeit ausgegangen ist. Jetzt ist es vorübergehend und zusätzlich nicht speicherbar (`verdictClaims`). Diese Einträge werden deshalb ausgetragen und wie alle anderen erneut versucht.

Wenn man diese Aufteilung auf die Anteile oben anwendet:

| | Anteil der kaputten |
|---|---|
| **Dauerhaft nicht reparierbar** | **39%** |
| **Nicht reparierbar, aber wiederherstellbar** | **59%** |
| Kaputt, noch ohne Grund | 2% |

Ein unbekannter Grund (`provider cannot re-add torrents`, ein Eintrag hier) steht in keiner der beiden Listen. Dafür gibt `IsPermanentlyUnrepairable` false zurück, und das ist die vorsichtige Antwort, die wir wollen.

Das ist der wichtigste Befund für das Design: **Eine Regel, die nur auf „`Unfixable` ist gesetzt“ prüft, würde Plex-Einträge für zweieinhalbmal so viele Releases entfernen, wie tatsächlich tot sind.**

Entscheidend ist außerdem, wo diese kaputten Torrents im Verhältnis zum Mount liegen:

| | Anteil der kaputten | Was Plex sieht |
|---|---|---|
| Kaputt, **noch auf dem Mount** | etwa drei von vier | Die Datei scheint zu existieren → wird nie als tombstone markiert. Kein Papierkorb-Symbol; der Fehler zeigt sich erst beim Abspielen |
| Kaputt, **nicht mehr auf dem Mount** | etwa eins von vier | Datei fehlt → wird als tombstone markiert → **diese sind die Kandidaten für den Sweep** |

Das ist die zentrale Messung. Sie bedeutet, dass der Sweep nur auf die zweite Gruppe trifft, und für diese Gruppe hat zurg meist schon ein Urteil.

Plex-Seite, gleicher Host: ein Rückstau an gelöschten Episoden, **keine** davon älter als das 14-Tage-Fenster (ältester tombstone 2026-08-11). Dazu ein paar leere Serien-Hüllen und ein paar Dutzend leere Staffel-Hüllen.

## 3. Die Lücke {#3-the-gap}

`broken_torrent` bedeutet „mindestens eine Sache ist kaputt“. Für den Sweep ist das die falsche Granularität.

Konkret: Bei einem Pack mit zehn Episoden fehlt die Datei einer Episode dauerhaft, das Torrent bleibt aber insgesamt reparierbar. Fragt man das Torrent ab, kommt „still repairable“ zurück, und der Sweep würde den eintrag dieser toten Episode in Plex **für immer** behalten.

Es gibt keinen Zustand, der „dieses ganze Release ist tot“ bedeutet und sich von „irgendetwas in diesem Release ist kaputt“ unterscheidet.

---

## 4. Design

### 4.1 Kein vierter gespeicherter Zustand {#41-do-not-add-a-fourth-persisted-state}

Der naheliegende Schritt wäre ein neuer Torrent-Status, etwa `dead_torrent` oder ähnlich. **Abgelehnt.**

Jede Stelle, die einen Torrent in einen anderen Status überführt, müsste ihn pflegen. Und ein veraltetes Flag "all files broken" ist schlimmer als gar kein Flag, weil es *Löschungen freigibt*. Die Information steckt schon in den Dateistatus, sie wird nur nirgends zusammengefasst.

Stattdessen leiten wir es ab:

```go
// AllFilesBroken reports whether nothing in this release still reads.
// Derived from the file states rather than stored, so it cannot go stale
// and needs no migration or new transitions.
func (t *Torrent) AllFilesBroken() bool
```

Günstig, immer konsistent und im Dashboard sichtbar, ohne dass etwas gespeichert werden muss.

Was wir bei der Umsetzung noch festlegen müssen: `deleted_file` zählt genauso wie `broken_file` als nicht lesbar. Und ein Torrent mit **null** Dateien muss false zurückgeben, nicht fälschlicherweise true. Ein leeres Release ist kein Beweis dafür, dass der Torrent tot ist.

### 4.2 Die Datei fragen, auf den Torrent zurückfallen {#42-ask-the-file-fall-back-to-the-torrent}

Der Sweep löst einen Plex-Pfad in eine zurg-Datei auf und wendet dann Folgendes an:

| zurgs Urteil | Sweep |
|---|---|
| Datei ist `ok_file` | **behalten** — sie ist nicht wirklich weg |
| `broken_file`, Torrent hat keinen Grund für Nicht-Reparierbarkeit | **behalten** — eine Reparatur kann sie wiederherstellen, egal wie lange das dauert |
| `broken_file`, Grund ist gesetzt, aber **nicht** dauerhaft | **behalten** — zurg hält sie noch für wiederherstellbar |
| `broken_file`, Grund ist **dauerhaft** nicht reparierbar | **entfernen** — kein erneuter Versuch kann dieses Urteil ändern |
| zurg hat für diesen Pfad keinen Torrent | **auf das Altersfenster zurückfallen** |

Der Dauerhaftigkeitstest ist `IsPermanentlyUnrepairable(reason)` (`internal/torrent/unrepairable_reasons.go:59`) und wird genau so verwendet wie von `ForceRepairTorrent`. Es ist wichtig, ihn wiederzuverwenden, statt eine Liste neu herzuleiten: Ein Grund, der später zu `permanentReasons` hinzugefügt wird, muss das Verhalten des Sweeps automatisch ändern, und ein unbekannter Grund muss nicht dauerhaft bleiben.

`AllFilesBroken()` autorisiert das Entfernen für sich allein nicht — ein komplett kaputtes Release mit wiederherstellbarem Grund wird weiterhin bearbeitet. Es verfeinert die Berichte und das Dashboard und unterscheidet für einen Menschen im Log zwischen „eine Folge von zehn ist weg“ und „das ganze Paket ist weg“.

Die letzte Zeile ist der Grund, warum `plex_trash_sweep_min_age_days` bleibt. Sobald ein Torrent komplett aus dem Konto verschwunden ist, geht seine `.zurgtorrent` mit weg, und zurg hat dazu keine Meinung mehr. Der Timer ist nicht mehr die wichtigste Regel, sondern wird zum Fallback genau für den Fall, in dem es nichts Besseres gibt.

Das stuft die Einstellung in der UI außerdem herab und löst damit die separate Beschwerde, dass ihr Label („Keep Broken Entries Visible“) eine Nebenwirkung beschreibt statt der Aktion.

### 4.3 Pfad → Torrent → Datei-Suche {#43-path--torrent--file-lookup}

Der bestehende Plex-Matcher geht den *anderen* Weg: `buildPlexDirIndex` (`internal/plex/matcher.go:539`) indexiert Plex-Pfadkomponenten und sucht sie anhand des Torrent-Schlüssels. Der Sweep braucht das Gegenteil, nach derselben Idee aufgebaut:

1. Erstelle `map[strings.ToLower(GetKey(torrent))] *Torrent` aus `DirectoryMap.Get(INT_ALL)`.
2. Zerlege einen Plex-Pfad mit derselben Normalisierung wie `splitPathComponents` (`matcher.go:525`) in Komponenten und suche jede einzeln nach. Das Release-Verzeichnis ist die Komponente, die einen Treffer liefert.
3. Innerhalb dieses Torrents gleichst du den restlichen Pfadteil mit `File.Path` (`internal/debrid/types.go:133`) ab, um die konkrete Datei zu finden.

Der Grund, warum das über `TorrentManager` laufen muss und nicht per String-Vergleich mit `data/*.zurgtorrent`: Namen mit Unterscheidungszusatz (`Some.Release {a1b2c3}`), Kopien über mehrere Accounts und Umbenennungen werden nur über `GetKey` richtig aufgelöst.

**Ein fehlgeschlagener Lookup ist kein Freifahrtschein zum Löschen.** Nicht auflösbar → behandle es als „zurg hat keine Meinung dazu“ → Altersfenster-Fallback.

### 4.4 Was sich nicht ändert {#44-what-does-not-change}

Die Invariante: Nichts mit einer lebenden Datei wird entfernt.
Serien und Staffeln mit lebenden Nachkommen werden nie angefasst.
Pro Element ein `DELETE`, nie `emptyTrash`.
Schutzmechanismen: rclone ist verwaltet und läuft, das Mount liest, Plex scannt nicht.
Vor jeder Änderung ein Snapshot; Obergrenzen gelten für Reparaturen *und* Entfernungen.

Die neuen Regeln machen den Sweep nur **konservativer** oder **präziser**.
Sie erlauben nie eine Entfernung, die der aktuelle Code verweigern würde.

---

## 5. Umsetzungsplan {#5-implementation-plan}

| # | Schritt | Dateien |
|---|---|---|
| 0 | Bestätige mit einer Trockenlauf-Zählung gegen eine echte Bibliothek, dass die Trennung zwischen dauerhaft und wiederherstellbar die richtige Schranke ist, bevor irgendetwas gelöscht wird | — |
| 1 | `AllFilesBroken()` + Unit-Tests (leeres Release, gemischt, alle defekt, alle gelöscht) | `internal/torrent/` |
| 2 | Nur-Lesen-Statusabfrage: Pfad → Torrent → Datei, gibt einen kleinen Ergebniswert zurück | neue Datei in `internal/torrent/` oder `internal/plexsweep/` |
| 3 | Definiere den Ergebnistyp (`StatusOK`, `StatusRecoverable`, `StatusPermanentlyDead`, `StatusUnknown`), damit der Sweep nie direkt mit zurg-Interna zu tun hat | `internal/plexsweep` |
| 4 | Binde die Abfrage hinter einem Interface in `Sweeper` ein, so wie es bei `Mount`/`Library`/`Trash` bereits ist | `internal/plexsweep/sweep.go` |
| 5 | Wende die Entscheidungstabelle an; behalte das Altersfenster als Fallback für `StatusUnknown` | `internal/plexsweep/sweep.go` |
| 6 | Injiziere den `TorrentManager` an der Aufrufstelle | `internal/app.go` |
| 7 | Tests: einer pro Zeile der Entscheidungstabelle, plus ein Test für Lookup-Fehler, der beweist, dass nicht auflösbare Einträge nie entfernen | `internal/plexsweep/sweep_test.go` |
| 8 | Doku: `docs/config.md`, `config.example.yml`, `docs/CHANGELOG.md`, und formuliere die Dashboard-Beschriftung neu | Doku + Vorlagen |

Hinweis zur Reihenfolge: Die Schritte 1–3 sind reine Ergänzungen ohne Verhaltensänderung und können zusammen als ein einziger Commit eingespielt werden; Schritt 5 ist der einzige, der ändert, was gelöscht wird.

## 6. Risiken und offene Fragen {#6-risks-and-open-questions}

1. **Reihenfolge der Verdrahtung.** Bestätigt: `startPlexTrashSweep` wird in `internal/app.go:268` aufgerufen, und `TorrentManager` wird in `internal/app.go:285` erstellt, also danach. Der Aufruf muss hinter diese Stelle wandern oder einen Setter bekommen. Du musst prüfen, ob irgendetwas anderes von der aktuellen Position abhängt.

2. **Mehrdeutige Suche.** Zwei Torrents haben Schlüssel, die mit derselben Pfadkomponente kollidieren. Lösung: Wenn mehr als ein Kandidat passt, behandle es als `StatusUnknown`, statt einen auszuwählen.

3. **`only_show_the_biggest_file`.** Das Filme-Verzeichnis blendet Dateien aus. Ein Plex-Pfad kann also eine Datei nennen, die nicht die ist, die zurg ausliefern würde. Die Suche darf nicht davon ausgehen, dass der Plex-Dateiname wortwörtlich in `File.Path` steht.

4. **Kosten.** Den Schlüssel-Index bei jedem Sweep aufzubauen ist O(Bibliothek). Bei ein paar tausend Torrents ist das trivial, und der Sweep läuft täglich. Baue den Index pro Sweep, nicht pro Eintrag.

5. ~~**Wird `Unfixable` je wieder gelöscht?**~~ **Geklärt: ja.** `refresh.go:851-857` löscht es, wenn ein Torrent sauber verifiziert wird und zurück zu `ok_torrent` geht ("all links intact, no broken files"). `repair.go:165-181` löscht es, Eintrag und jede Kopie, wenn eine Reparatur erzwungen wird. Ein wiederhergestellter Release trägt also keinen veralteten Vermerk mehr mit sich, und das Design muss sich nicht dagegen absichern.

6. **Die kaputten, aber vorhandenen Torrents.** Die sind hier außen vor. Plex markiert sie nie als gelöscht, also sieht der Sweep sie nie. Wichtig zu wissen: Sie sind sowohl für Plex als auch für dieses Feature unsichtbar, bis die Wiedergabe fehlschlägt.

## 7. Wie es umgesetzt wurde (2026-08-16) {#7-how-it-was-implemented-2026-08-16}

Umgesetzt als `feat: decide plex trash sweep removals from zurg's repair verdicts`.

Wo die Umsetzung eine Frage geklärt hat, die dieses Dokument offen gelassen hat, oder von §4 abweicht, stehen hier die Entscheidung und ihr Grund:

- **Die Suche gleicht das übergeordnete Verzeichnis des Pfads exakt** mit `DirectoryMap[INT_ALL]` ab, statt jede Pfadkomponente zu durchsuchen (§4.3). Der Mount legt ein Release flach ab – `<library dir>/<key>/<visible name>` – und Plex hat den Pfad vom Mount übernommen, der den Schlüssel unverändert ausliefert. Ein exakter Fehltreffer liefert „unbekannt“ zurück, und die Mehrdeutigkeit durch Schlüsselkollisionen (Risiko 2) entfällt: exakte Schlüssel können nicht kollidieren.
- **Zeile 1 der Entscheidungstabelle wurde geändert.** Eine `ok_file`, die trotzdem nicht im Mount vorhanden ist, ist eine Datei, die die Filter ausblenden, und nicht „nicht wirklich weg“. Würde man sie dauerhaft behalten, bliebe nach einer Filteränderung ein dauerhaftes Papierkorb-Symbol. Stattdessen greift das Altersfenster.
- **`deleted_file` zählt zusammen mit `broken_file`** in jeder Regel, nicht nur in `AllFilesBroken()` – die Zeilen der Tabelle lauten „nicht `ok_file`“.
- **Items mit mehreren Versionen werden als Ganzes bewertet** (die Tabelle war dateibezogen, die Einheit des Sweeps ist ein Plex-Item mit Parts): Ein wiederherstellbarer Part hält das ganze Item; das Item ist nur dann tot, wenn jeder Part tot ist; jede andere Mischung fällt auf das Altersfenster zurück.
- **Ein Dateiname, der auf einen Torrent, aber nicht auf eine Datei auflöst** (Umbenennung, Archivauflistung, `only_show_the_biggest_file` – Risiko 3), ist nur dann tot, wenn der Grund des Eintrags dauerhaft ist **und** `AllFilesBroken()` zutrifft; wiederherstellbar, wenn der Torrent kaputt ist, ohne dass ein dauerhaftes Urteil vorliegt; sonst unbekannt. Ein nicht zugeordneter Name wird durch die Zuordnung nie verurteilt, solange noch eine Datei lesbar ist.
- **Verdrahtung (Risiko 1):** `startPlexTrashSweep` wurde in `internal/app.go` unter die Erstellung des Managers verschoben; nichts hing von seiner alten Position ab. Die Urteile erreichen den Sweep über `plexsweep.Verdicts`, implementiert von `TorrentManager.FileStatusForMountPath`. Bevor der erste Refresh `INT_ALL` befüllt, liefert jede Suche „unbekannt“, und der Sweep verhält sich genau wie die Version mit dem reinen Altersfenster.

## 8. Ausdrücklich außerhalb des Umfangs {#8-explicitly-out-of-scope}

- **Leere Serien- und Staffel-Hüllen.** Die Bereinigung entfernt nur Blätter, daher bleibt bei einer komplett toten Serie eine leere Hülle zurück (in der gemessenen Bibliothek einige Serien und ein paar Dutzend Staffeln). Das ist ein eigenes Problem und braucht sorgfältige Reihenfolge: Blätter entfernen, übergeordnetes Element prüfen, nur bei null verbleibenden Kindern löschen.
- Jede Änderung am Reparaturverhalten, an der Reparaturwarteschlange oder daran, wann zurg etwas als nicht reparierbar markiert.
- Plex' eigene `autoEmptyTrash`-Einstellung, die bereits durch die Warnung in `4737b677` abgedeckt ist.
- Der bestehende Rückstand der gemessenen Bibliothek, der bewusst für eine manuelle Entscheidung offengelassen wird.
