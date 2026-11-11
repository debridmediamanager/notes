# TorBox-Limits und wie zurg sich daran anpasst {#torbox-limits-and-how-zurg-adapts-to-them}

zurgs Verhalten bei der Bibliothek ist um die Beschränkungen von Real-Debrid herum gewachsen. Die von TorBox sind anderer Art, nicht nur in der Größenordnung, und wer zurg mit Real-Debrid-Logik betreibt, wird schon beim ersten Bibliotheksscan innerhalb von Sekunden rate-limited. Hier steht, welche Limits es gibt, woher die Werte stammen und was zurg bei jedem davon macht.

Die Limits eines Anbieters sind im Code als `debrid.Capabilities` hinterlegt, daher liest der generische Bibliothekscode sie aus, anstatt sie vorauszusetzen. Ein neues Backend hinzuzufügen heißt, diese Struktur auszufüllen, nicht den Torrent-Manager zu bearbeiten.

## Rate-Limits {#rate-limits}

| Limit | Wert | Quelle |
|---|---|---|
| Alle Endpunkte zusammen, pro API-Token | 300/min | [dokumentiert](https://api-docs.torbox.app/) |
| `POST /torrents/createtorrent` (nur uncached) | 60/Stunde | dokumentiert |
| `POST /webdl/createwebdownload`, `POST /usenet/createusenetdownload` | 60/Stunde | dokumentiert |
| `GET /torrents/requestdl` | **~100 Aufrufe, dann 429**, ein Budget, keine Rate | gemessen, 2026-08-30 |
| Gleichzeitige Verbindungen zu einem CDN-Host | **genau 20**, darüber 429 | gemessen, 2026-08-23 |
| Globale Burst-Grenze | greift bei ~40 gleichzeitigen Verbindungen, drosselt *alle* Endpunkte | gemessen |
| 429-Erholung | `Retry-After: 300`, Alles-oder-nichts-Sperre | gemessen |

Die Limits gelten pro API-Token und werden über die Server von TorBox synchronisiert. Sie gelten also nicht pro IP. Zusätzliche Clients auf anderen Rechnern teilen sich das gleiche Budget. TorBox sagt das auch ausdrücklich: Sie nehmen keine IP-Whitelisting-Anfragen mehr an, weil das Limit am Token hängt.

Drei Dinge machen das Ganze strenger, als die Schlagzeile mit 300/min vermuten lässt:

- **Die 300/min gelten nicht pro Endpunkt.** Es ist ein einziges Budget, das der ganze Schlüssel verbraucht. Wenn du jeden Endpunkt einzeln drosselst, kann die Summe eine Grenze überschreiten, die keiner der Endpunkte für sich allein erreicht.
- **`requestdl` ist viel strenger als dokumentiert, und es ist keine Rate.** Dieser Endpunkt erzeugt die Download-URLs. Er hat nach etwa 100 Aufrufen aufgehört, obwohl `user/me`, `mylist` und `checkcached` bei gleicher Parallelität 500+ Aufrufe geschafft haben.

  Langsamer werden bringt nicht mehr davon. Gemessen am 2026-08-30 auf dem Hauptaccount, drei Läufe pro Variante, jeweils von einer geleerten Sperre aus:

  | Pacing | 429 kam bei | Verstrichene Zeit |
  |---|---|---|
  | so schnell wie möglich, hochgefahren 60→240/min | Aufruf **100** | 56s |
  | eine pro Sekunde (60/min) | Aufruf **94** | 108s |
  | eine alle zwei Sekunden (30/min) | Aufruf **101** | 198s |
  | eine alle drei Sekunden (20/min) | **nie**, 241 Aufrufe | 721s, ohne Fehler |

  Die Rate zu halbieren brachte neunzig Sekunden mehr, aber keinen einzigen Aufruf mehr. Halbierst du sie nochmal, tritt das 429 gar nicht mehr auf. Der Account hat **100 Aufrufe pro gleitendem Fünf-Minuten-Fenster, also 20/min**. Nur diese Lesart passt auf alle vier Läufe: Sie sagt den Abbruch bei t≈100s, t≈200s und sofort bei den ersten drei voraus, und beim vierten liegt man genau auf der Grenze und kommt durch.

  Das ist die wichtigste Korrektur beim Lesen des restlichen Textes. Ein Limiter pro Minute hält zurg nicht unter dem Budget. Die Pacing-Zahlen weiter unten sorgen also für gleichmäßige Abläufe, aber nicht für mehr Reserve. Ein schnellerer Limiter beendet einen Bibliotheks-Scan nicht früher. Er läuft nur schneller in dieselbe Sperre, und dann antwortet das Mount fünf Minuten lang gar nicht. Nur **weniger Aufrufe** erhöhen, wie weit ein Scan kommt. Deshalb ist Read-ahead hier nicht vorgesehen, und das Benennen einer bereits aufgelösten Datei darf nie einen Request kosten.
- **429 ist eine Klippe, keine Rampe.** Sobald das Limit greift, schlagen 100 % der Anfragen etwa fünf Minuten lang fehl. Es gibt keine Phase mit reduziertem Durchsatz, die man einfach aussitzen könnte.

CDN-Downloads werden separat gezählt und teilen sich das API-Budget **nicht**. Das Streamen einer Datei kostet nie Kontingent für die Link-Auflösung. Das wurde in beide Richtungen geprüft: Haben wir die CDN-Downloads bis zum 429 ausgelastet, hat `requestdl` normal weitergeantwortet, und umgekehrt genauso.

### Zwei verschiedene Limits, die beide 20 sind {#two-different-limits-both-numbered-20}

Die Tabelle oben führt die 20 zweimal auf, und die beiden haben nichts miteinander zu tun. Sie zu verwechseln ist leicht und führt dazu, dass man das Falsche drosselt.

- **`requestdl` bei ~20 gleichzeitigen** ist ein *API*-Limit: etwa 100 Aufrufe bei dieser Parallelität, bevor ein 429 kommt, und dabei wird das Request-Kontingent des Accounts verbraucht.
- **20 Verbindungen pro CDN-Host** ist ein *Byte-Pfad*-Limit, gemessen am 2026-08-23 mit einem schrittweisen Hochfahren. Dafür braucht es gar keinen `requestdl`-Aufruf. Es reicht schon, eine bereits erzeugte URL wiederzuverwenden, um es zu erreichen.

Die Obergrenze des Byte-Pfads liegt **genau bei 20**, und sie verhält sich eher wie eine harte Grenze als wie eine Kurve: 20 dauerhaft, egal ob 24, 32, 40 oder 48 Verbindungen angefragt wurden. Die Ablehnungen steigen, um alles über der Linie abzufangen.

Sie gilt für den **CDN-Host, nicht für das Objekt und nicht für die IP**. Das korrigiert die ältere Annahme „pro IP auf der Cloudflare-Ebene“:

- Zwei *verschiedene* Dateien, die über denselben `nexus-NNN`-Host ausgeliefert werden, teilen sich das eine Budget von 20 und lehnen den gleichen Überschuss ab.
- Dieselbe Last, auf zwei Hosts aufgeteilt, läuft sauber.
- 32 gleichzeitige Streams, verteilt auf 16 Hosts, alle von einer IP, sind in Ordnung.

Zum Vergleich mit den anderen Anbietern, die auf die gleiche Weise gemessen wurden: Real-Debrid begrenzt auf 32 pro Host (lehnt auf TCP-Ebene ab, ohne HTTP-Status), AllDebrid auf 32 (HTTP 429), und Premiumize zeigte bis 64 gar keine Obergrenze. Die 20 von TorBox sind die niedrigste der vier.

**Die globalen Edges von TorBox haben keine solche Grenze.** Die 20 gelten für die Knoten-Hosts `nexus-NNN.<region>.tb-cdn.st`, die `requestdl` erzeugt. Die beiden globalen Edges, `nexus.erth.tb-cdn.earth` und `nexus.hare.tb-cdn.earth`, liefern jede Datei im Account aus. Beide wurden ohne eine einzige Ablehnung auf 64 gleichzeitige Verbindungen hochgefahren. Nur der Host unterscheidet sich, Pfad und Token authentifizieren die Anfrage weiterhin. zurg schreibt Anfragen heute nicht auf sie um (der Schwester-Dienst `debrid` tut das über `TORBOX_CDN_EDGE`), daher gilt hier die Obergrenze unten.

### Was zurg macht {#what-zurg-does}

- **`GetTorrentInfo` wird aus der Torrent-Liste bedient.** TorBox' `mylist` enthält bereits die Dateiliste jedes Torrents, also kostet eine Bibliotheksaktualisierung eine Anfrage statt einer pro Torrent. Das wird als `Capabilities.ListIncludesFiles` deklariert, und der Aktualisierungspfad überspringt bei Providern, die das setzen, sowohl den Einzelaufruf pro Torrent als auch den Info-Cache auf der Festplatte. Bei einem Account mit 213 Torrents ist das der Unterschied zwischen 213 Anfragen und 1.
- **Ein Limiter taktet jeden Endpunkt**, eingestellt auf 240/min statt der dokumentierten 300, damit Luft bleibt für alles andere, das denselben Schlüssel nutzt: das TorBox-Dashboard, einen anderen Client, eine zweite zurg-Instanz.
- **`requestdl` bekommt obendrauf einen zweiten Limiter**, eingestellt auf 15/min. Eine Auflösung zehrt von beiden. Der Wert liegt unter den gemessenen 20/min statt genau darauf, aus demselben Grund, warum der allgemeine Limiter bei 240 statt der dokumentierten 300 liegt: Das Budget wird von allem verbraucht, was den Schlüssel hält, und die 20/min wurden gemessen, ohne dass sonst etwas darauf lief. `TestTheRequestdlBudgetCannotBeSpentInsideItsWindow` prüft die eigentliche Invariante: Das gesamte Kontingent darf nicht innerhalb des Fensters verbraucht werden können, das es wieder auffüllt. So landet die Konstante nicht unbemerkt wieder darüber.
- **Der Download-Client ist auf 20 Verbindungen pro CDN-Host begrenzt** (`maxConnsPerCDNHost` in `internal/torbox/client.go`, durchgereicht über `rdclient.HTTPClientOptions.MaxConnsPerHost`). Go's `MaxConnsPerHost` sorgt dafür, dass Anfrage 21 *auf eine freie Verbindung wartet*, statt zu scheitern. So wird eine Ablehnung durch den Provider zu einer lokalen Warteschlange. Ohne sie erbte der Download-Client die unbegrenzte Einstellung des allgemeinen Transports und konnte 429er auf dem Datenpfad einsammeln, während alle API-Limiter eingehalten wurden.
- **429-Antworten parken jeden Aufrufer** für das `Retry-After`-Fenster, statt dass jeder eine Anfrage verbraucht, um die Sperre erneut herauszufinden. Die Sperre gilt für den ganzen Account, also hält eine 429 auf irgendeinem Endpunkt alle zurück.
- **Gleichzeitig laufen maximal 16 Anfragen**, unter der globalen Burst-Obergrenze von etwa 40, damit daneben Platz für den Download-Client bleibt.
- **Das Vorauslesen ist abgeschaltet.** zurg wärmt bei einem kalten Lesezugriff die nächste Datei eines Releases vor, was jedes Backend mit einem echten Minutenbudget verkraftet. Ein Bibliotheksscan ist der Fall, der das kaputt macht: Er öffnet jede Datei genau einmal, also ist jeder dieser Zugriffe kalt, die Ablehnung für warme Lesezugriffe greift nie, und der Account wird für jede Datei zu zwei Auflösungen aufgefordert. Gemessen am 2026-08-30 löste ein Scan mit vierzig Dateien genau vierzig spekulative Auflösungen neben seinen vierzig Lesezugriffen aus, also die Hälfte des Budgets, verbraucht für Dateien, die niemand angefordert hatte. TorBox deklariert `Capabilities.SpeculativeResolutionsAffordable` als false, und dafür wird nichts angefordert.
- **Namen einer aufgelösten Datei kosten keine Anfrage.** Jede Auflösung endet damit, Name und Länge dieser Datei für den Download-Eintrag nachzuschlagen. Dieser Lookup lief über den Listen-Snapshot. Sobald dessen Frischefenster von dreißig Sekunden abgelaufen war, holte der nächste Lesezugriff die komplette Torrent-Liste, bevor er antworten konnte: während eines Scans alle dreißig Sekunden, solange der Scan lief, und bei einer Bibliothek mit 3,700 Torrents wurde die Liste dabei viermal seitenweise abgerufen. Jetzt liest er die bereits vorliegende Liste, egal wie alt sie ist, da sich Dateinamen und Längen eines abgeschlossenen Torrents nicht ändern können.
- **Der Link-Cache wird einen Tag lang gehalten, mit Neuauflösung bei ausdrücklicher Ablehnung.** Wiederholte `requestdl`-Aufrufe lieferten in der Probe vom 2026-08-30 identische URLs, auch eine Stunde später, und eine 3h25m alte URL antwortete immer noch mit `206`. Das belegt Wiederverwendung, aber keine unbegrenzte Lebensdauer. Am 2026-09-04 gab eine korrekt authentifizierte gecachte URL `400` mit „Invalid Presigned Token“ zurück, während eine frische Auflösung desselben Torrents bzw. derselben Datei einen anderen Host und Pfad lieferte und mit `206` antwortete. Die Query war unverändert. Nur den alten Pfad und die alte Query auf den neuen Host zu verschieben, ergab weiterhin `400`.

  Der 24h-Cache bleibt eine Budgetentscheidung: Ein Scan löst mit 20/min auf und kann Stunden dauern. Eine ausdrückliche Ablehnung wegen ungültigen Tokens verwirft nun diese URL und versucht eine frische Auflösung. Parallele Lesezugriffe teilen sich die Auflösungsarbeit, und eine verspätete Ablehnung kann keine neuere gecachte URL verdrängen. Wird auch die frisch aufgelöste URL abgelehnt, pausiert die Wiedergabe lokal für eine Minute, ohne die Datei zu verurteilen. Allgemeine 400er beweisen keine veraltete URL und lösen nur eine kurze Abkühlzeit aus. CDN-429er bewahren `Retry-After` und parken Lesezugriffe auf diesen Host, über alle Dateien und Verifikationsaufrufe hinweg. Das API-Budget bleibt davon getrennt.
- **`bypass_cache=true` bei jedem Listenaufruf.** Der eigene `mylist`-Cache von TorBox hat eine TTL von etwa 5 Minuten, und genau daraus bedient zu werden ist der Grund, warum WebDAV-Mounts 5–15 Minuten hinter der Realität herhinken. Der Parameter kostet kein Rate-Limit und bringt Änderungen in unter einer Sekunde durch.
- **Ein Poll kostet eine Auflistung.** Der Poll auf Bibliotheksänderungen ist der einzige Aufrufer, der einen frischen Abruf erzwingt, denn das Erkennen von Änderungen ist seine ganze Aufgabe. Die aktive Anzahl, die im selben Takt erhoben wird, und die vollständige Aktualisierung, die auf eine Änderung folgt, lesen beide den Snapshot, den er gerade gefüllt hat. Auch dort zu erzwingen hieß, die ganze Bibliothek zwei- oder dreimal pro Poll abzuladen. Bei dem Standardintervall von zehn Sekunden waren das tausende überflüssige vollständige Bibliotheksabrufe am Tag, gegen einen Dienst, dessen eigenen Listen-Cache zurg ohnehin schon umgeht.
- **Die Liste wird in Seiten zu 1000 durchlaufen.** `mylist` begrenzt eine Antwort auf 1000 Torrents, dem dokumentierten Standardwert für `limit`. Mehr anzufordern hebt das nicht an. Dabei meldet die API weder eine Gesamtzahl noch einen Hinweis auf „there is more“. Eine einzelne Anfrage beantwortet also einen größeren Account mit seinen neuesten 1000 und sieht genau aus wie eine vollständige Bibliothek. zurg paginiert per `offset`, bis eine unvollständige Seite zurückkommt, und dedupliziert IDs unterwegs. Die Liste ist nach ID absteigend sortiert, also verschiebt ein während des Durchlaufs hinzugefügter Torrent das Fenster um einen Platz und wiederholt einen Eintrag an der Nahtstelle.

## Konto-Limits {#account-limits}

| Plan | Aktive Slots | Seeding | Max. Torrent-Größe | Hinweise |
|---|---|---|---|---|
| Free | 1 | keins | 10 GB | 1 Hinzufügen/24h, 10 Hinzufügen/Monat, keine privaten Torrents |
| Essential | 3 | — | 200 GB | keine Abklingzeit, unbegrenzt viele Hinzufügen aus dem Cache |
| Standard | 5 | 2 Wochen | — | |
| Pro | 10 | 30 Tage | — | Ablauf nach 30 Tagen |

Quelle: [Kontobeschränkungen](https://support.torbox.app/en/articles/9836418-account-restrictions).

`/user/me` meldet den Plan als Zahl, und die Zahlen sind nicht nach Preis sortiert:
**0 Free, 1 Essential, 2 Pro, 3 Standard**. Standard wurde nach Pro hinzugefügt. zurg hat Plan 2 bis zum 03.10.2026 als Standard gelesen. Dadurch bekamen Pro-Konten fünf Slots und das Nutzungslimit von Standard.

**Aktive Slots sind die prägendste Einschränkung von TorBox**, bei Real-Debrid ist es die Bandbreite. Ein Torrent belegt einen Slot, solange er herunterlädt *oder seedet*. Bei einem kostenpflichtigen Plan kann ein fertiger Torrent so einen Slot bis zu 30 Tage blockieren.

### Was zurg macht {#what-zurg-does-1}

- **`GetActiveTorrentCount` meldet die echte Obergrenze deines Tarifs.** Sie wird aus `plan` im Benutzerdatensatz gelesen. So blockiert und wartet die Reparatur, statt Hinzufügungen in die Warteschlange zu stellen, die der Account ablehnen würde. Meldet ein Anbieter keine Obergrenze, wird das als unbegrenzt behandelt und nicht als dauerhafte Blockade.
- **Hinzugefügte Torrents sind standardmäßig auf never-seed gesetzt.** Seeding belegt wochenlang einen Slot und verursacht ausgehenden Traffic, und beides bringt einem Streaming-Mount nichts. Mit `tb_seed_torrents` kannst du das ändern, falls ein Operator bei einem privaten Tracker ein Ratio einhalten muss: `never` sendet `seed=3` (der Standard), `always` sendet `seed=2`, und bei `auto` fehlt das Feld ganz. TorBox beschreibt das Feld so: "1 is auto. 2 is seed. 3 is don't seed. Optional. Default is 1, or whatever the user has in their settings. Overwrites option in settings". Jeder gesendete Wert, auch `1`, überschreibt also die Seeding-Einstellung des Accounts. Nur ein fehlendes Feld lässt sie greifen. Derselbe Modus gilt für alle drei Hinzufüge-Wege: den Magnet-Add, den Cached-only-Add und den `.torrent`-Upload. Ist Seeding aktiv, behalten fertige Torrents ihre Slots. Dann bleiben Reparatur und die Download-Client-Endpunkte an der Obergrenze hängen, sobald Seeding-Torrents alle Slots belegen.
- **Der Cache wird vor dem Hinzufügen nie geprüft.** `checkcached` wird nirgends aufgerufen. Einzige Ausnahme war der Cached-only-Modus (`qbittorrent.download_timeout_mins: 0`). Dort wird jetzt der Torrent hinzugefügt und die Instanz wie bei allen anderen Backends beobachtet. Der Grund: Der Endpunkt sagt nur, ob der Inhalt im TorBox-Cache liegt, nicht ob dein Account ihn am Ende tatsächlich hat. Das kostet bei einem Cache-Miss etwas: Ein ungecachter Add verbraucht das Kontingent von 60 pro Stunde, während eine Prüfung nichts verbraucht hat. Gecachte Adds fallen weiterhin unter das Budget von 300 pro Minute.

## Ablauf von Inhalten {#content-expiry}

Pro-Inhalte laufen nach 30 Tagen ab. Abgelaufene Torrents liefert die API als `expired` oder `reported missing` zurück, melden aber weiterhin `download_finished: true` mit `download_present: false`.

Wenn du nur `download_finished` liest, würde ein ganzer Torrent eingebunden, bei dem jeder Link 404 liefert.

zurg bildet beide Formulierungen auf den Status `error` ab. `Capabilities.ContentExpires` markiert das für das Backend als normal und nicht als Fehler.

**Die beiden Booleans allein heißen noch nicht, dass die Daten weg sind.** Ein gesunder, nicht gecachter Download meldet `download_finished: true` mit `download_present: false` für die letzten 9.6 Sekunden seines Lebens, während er durch `processing`, `downloading` und `uploading` läuft. Gemessen wurde das am 2026-08-30 mit einem Abfrageintervall von 0.5 und beschrieben in `docs/torrent-lifecycle.md`. zurg hat dieses Paar früher unabhängig vom Statustext als Tod gelesen. Jede Instanz mit `delete_error_torrents: true` hat so einen Torrent mitten im Download gelöscht. Allein an diesem Tag wurden fünf Probe-Torrents so gelöscht. Jetzt entscheidet nur noch die Strukturregel, und zwar nur bei einer Antwort, die gar kein `download_state` enthält. Eine Formulierung, die dieser Code noch nicht kennt, wird stattdessen als laufende Arbeit behandelt, weil `processing` auch so eine Formulierung war, bis es gemessen wurde.

Ein Lesevorgang, der trotzdem auf so eine Datei trifft, kostet jetzt mehr als einen Aufruf. Der Auslieferungspfad behandelt eine 404 auf eine erzeugte Auslieferungs-URL als widerrufenen Link und nicht als fehlende Datei. Das ist auf Real-Debrid auch so, wo die Codes sterben, sobald ihre downloads-Zeile gelöscht wird. Deshalb wird vor dem Aufgeben neu aufgelöst. Eine abgelaufene TorBox-Datei verbraucht pro Lesevorgang bis zu vier `requestdl`-Aufrufe statt einem. Das ist pro Lesevorgang begrenzt, und die Auflistung hat den Torrent bereits als `error` markiert. Niemand läuft also mit diesem Tempo durch eine abgelaufene Bibliothek. Ein Client, der immer wieder denselben abgelaufenen Pfad anfragt, zahlt aber jetzt das Vierfache von früher.

### Was zurg macht {#what-zurg-does-2}

**Nichts fügt die Torrents eines ablaufenden Backends von selbst wieder hinzu.** Repair behebt einen kaputten Torrent, indem es dessen Magnet erneut hinzufügt. Auf einem Backend, das Inhalte behält, ist das eine Reparatur. Auf einem Backend, das sie ablaufen lässt, ist es ein erneuter Download. Wird das in einem Timer über die ganze Bibliothek ausgeführt, ist das genau das Verhalten, das TorBox als Erstes nennt, wenn ein Konto markiert wird: "excessive transfer retention (using tools to artificially keep transfers active)". Außerdem zählt jede nicht gecachte erneute Hinzufügung als eingehende Übertragung auf das Kontingent des Tarifs.

Die periodische Prüfung überspringt daher Torrents, deren reparierbare Kopie auf einem Provider liegt, der `ContentExpires` deklariert. Sie bleiben kaputt und sichtbar. Der Reparieren-Button im Dashboard funktioniert weiterhin. Und ein Release, das auch bei Real-Debrid liegt, wird weiterhin wie gewohnt von dieser Kopie repariert. Entscheidend ist also, wer die Reparatur angestoßen hat, nicht, was kaputtgegangen ist.

## Nutzung und das Missbrauchssystem {#usage-and-the-abuse-system}

TorBox prüft Anfragen nicht. Es misst die übertragenen Bytes über ein rollierendes 15-Tage-Fenster, gegen einen Schwellenwert, der aus dem 99. Perzentil jeder Tarifstufe abgeleitet wird. Es gibt drei Warnungen, und **jede Warnung rotiert den API-Key**. Bei der vierten folgt ein Bann. Die veröffentlichten Untergrenzen sind das Minimum, auf das diese dynamischen Schwellenwerte sinken können:

| Tarif | Untergrenze |
|---|---|
| Free | 5 TB/Monat |
| Essential | 10 TB/Monat |
| Standard | 20 TB/Monat |
| Pro | 30 TB/Monat |

Beide Richtungen zählen: eingehende nicht gecachte Adds und alles, was TorBox ausschickt, egal ob an dein Gerät oder zurück in den Swarm. Gecachte Adds zählen nicht. Die Abrechnung ist byte-genau, also kostet eine teilweise gelesene Datei nur das, was tatsächlich gelesen wurde.

**`cooldown_until` auf `/user/me` ist keine dieser Warnungen, und wenn du es als eine liest, verlierst du dadurch einen Tag.** Verifiziert am 2026-08-12 auf einem Plan-2-Konto mit einem aktiven, frisch gesetzten Cooldown (24h in der Zukunft, `updated_at` eine Minute alt): `/user/me`, `checkcached` und `mylist` antworteten alle mit `200 success:true`, WebDAV-`PROPFIND` lieferte `207`, und ein `bytes=0-0`-Range-Read kam mit `206` und korrektem `Content-Range` in 2.8s zurück. Keine Schicht verweigerte den Dienst. Der Lifetime-Traffic dieses Kontos lag bei 14.1 GB gegenüber einer Untergrenze von 30 TB/Monat, es war also ein API-Rate-Cooldown und kein Bandbreiten-Strike. Das Unterscheidungsmerkmal ist der **Key**: Eine echte Warnung rotiert ihn, und danach liefert jeder Endpunkt `AUTH_ERROR`. Ein Cooldown mit intaktem Key hat dagegen keine sichtbare Auswirkung. Da `checkcached` außerdem einen Release als gecacht melden kann, den TorBox tatsächlich nicht ausliefert, ist der Range-Read die einzige Prüfung, die belegt, dass ausgeliefert wird. Prüf also zuerst den Byte-Pfad, bevor du daraus schließt, dass TorBox unbrauchbar ist.

Quelle: [Das TorBox-Missbrauchssystem](https://support.torbox.app/en/articles/10336778-the-torbox-abuse-system).

### Was zurg macht {#what-zurg-does-3}

- **Hinzugefügte Torrents werden standardmäßig nie geseedet**, sodass beim Ausgehen nichts abgerechnet wird
  für Inhalte, die zurg nur liest. `tb_seed_torrents: always` (oder `auto` bei einem Konto, das auf Seeden eingestellt ist) ist die einzige Einstellung, die das ändert, und deren Upload wird wie jeder andere berechnet.
- **Die Nutzung wird stichprobenartig erfasst und die Differenzen gebildet.** Die API veröffentlicht keinen laufenden Wert, nur einen Lebenszeitzähler auf `/user/me`. Deshalb speichert der Account-Refresher diesen Zähler alle 30 Minuten in `data/torbox_usage.json` und bildet die Differenzen zwischen den Stichproben. Überschreitet der Wert der letzten 30 Tage 80 % der Untergrenze des Tarifs, wird eine Warnung geloggt. Genau dafür gibt es die Stichproben: Das Dashboard zeigt nur, was zurg selbst weitergeleitet hat, aber nie diese Differenzen. Bei einer frischen Installation gibt es noch keinen Verlauf, und das wird auch so gesagt, anstatt eine beruhigende Null anzuzeigen.
- **Ein abgelehnter Schlüssel wird als möglicher Missbrauchshinweis gemeldet**, weder als Tippfehler in der Konfiguration noch als defekter Inhalt. Denn Schlüsselrotation ist genau der Weg, auf dem TorBox solche Hinweise verschickt. Würde man es als Defekt behandeln, müsste die gesamte Bibliothek repariert werden.

## Absichtlich nicht zugeordnet {#deliberately-unmapped}

An unbekannter `download_state` wird als `downloading` gemeldet, niemals als `error`.
Wenn `delete_error_torrents` aktiviert ist, löscht zurg bei einem Fehlerstatus den Torrent aus dem Konto. Ein Status, den TorBox erst nach dem Schreiben dieses Codes einführt, darf daher keine Löschungen auslösen.
