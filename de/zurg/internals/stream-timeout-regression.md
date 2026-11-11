# Regression beim Timeout für Proxy-Streams {#proxied-stream-timeout-regression}

## Zusammenfassung {#summary}

zurg hat `download_timeout_secs` als feste Zeitgrenze für proxied HTTP-Downloads verwendet. Der Standardwert ist 15 Sekunden. Deshalb wurde jede einzelne Upstream-Antwort abgebrochen, deren Body länger als 15 Sekunden zum Fertigwerden brauchte, auch wenn die Bytes normal weiterliefen.

Der Fehler wurde am 2026-08-21 auf Discord gemeldet, und zwar für `2026.08.21.0151-nightly` (`fc2a21f`). Wiederholte 2-GB-Range-Requests über zurg endeten nach genau 15,001 Sekunden, nachdem etwa 1,26 GB mit 84 MB/s übertragen worden waren. Derselbe Range wurde direkt von Real-Debrid vollständig geladen. Als `download_timeout_secs` auf 3600 gesetzt wurde, konnte der Request über zurg in 25,8 Sekunden fertig laufen.

Das war ein Regression-Fehler in zurg, kein Content-Filter, kein CDN-Problem und keine Regression in `fc2a21f`. Verursacht hat ihn Commit `6edeaa8c` (`Optimize client`, 2024-11-17). Der normale Proxy-Serving-Pfad wurde mit `41db7245` behoben. Danach hat `eff972b8` dafür gesorgt, dass derselbe Fehler an der Provider-API-Grenze nur noch schwer wieder hineinrutschen kann.

## Auswirkungen für Nutzer {#user-impact}

Der betroffene Pfad war jede Antwort (Response-Body), die zurg von einem HTTP-basierten Debrid-Anbieter weitergeleitet hat und die länger offen blieb als `download_timeout_secs`. Real-Debrid war ab November 2024 betroffen. TorBox und AllDebrid hatten dasselbe Verhalten, als diese Anbieter hinzugefügt wurden. Lokal bereitgestellte NZB-Lesezugriffe liefen nie über den HTTP-Download-Client und waren deshalb nicht betroffen.

Die Probleme waren für Nutzer sichtbar:

- Infuse oder ein anderer direkter WebDAV-Client friert beim Abspielen ein;
- die Wiedergabe bricht ab, nachdem ein Spulen eine neue Range-Anfrage geöffnet hat;
- ein Download endet früh, obwohl HTTP `206 Partial Content` empfangen wurde; und
- Client-Fehler sehen so aus, als läge es an der Mediendatei oder am CDN, obwohl eine direkte Anfrage normal abgeschlossen wurde.

Der Player musste nicht unbedingt 15 Sekunden nach Start der Wiedergabe ausfallen. Bei den gemeldeten 84 MB/s hat zurg bis zur Frist rund 1.26 GB übertragen. Ein Player konnte diesen Puffer mehrere Minuten lang verbrauchen, bevor er leer war. Dadurch wurde ein exakter Netzwerk-Cutoff nach 15 Sekunden zu einem scheinbar zufälligen Einfrieren der Wiedergabe.

## Ursache {#root-cause}

Go's `http.Client.Timeout` ist eine Frist für den gesamten Lebenszyklus einer Anfrage. Es ist kein Inaktivitäts- oder Stall-Timeout. Die Uhr startet, sobald die Anfrage beginnt, und läuft weiter, während der Response-Body gelesen wird, egal ob gerade Daten fließen.

Vor `6edeaa8c` hatte der Download-Client selbst kein Timeout für die gesamte Anfrage:

```go
client: &http.Client{}
```

`download_timeout_secs` begrenzte die Phasen für Verbindungsaufbau und Response-Header über den Dialer des Transports und `ResponseHeaderTimeout`. Sobald der Response-Body eingetroffen war, konnte der Ausliefer-Pfad so lange weiterlesen, wie der nachgelagerte Client es brauchte.

`6edeaa8c` hat den HTTP-Transport umgebaut und das konfigurierte Timeout direkt am Client ergänzt. Gleichzeitig wurde `ResponseHeaderTimeout` entfernt:

```go
client.client = &http.Client{
    Transport: transport,
    Timeout:   time.Duration(timeoutSecs) * time.Second,
}
```

Damit hat sich die Bedeutung des bestehenden 15-Sekunden-Werts geändert. Er schützte weiterhin die Verbindungsphase, legte nun aber auch eine absolute Frist für den Response-Body fest. Der Ausliefer-Pfad holte Medien bereits über diesen Client, deshalb wurde die Regression aktiv, sobald diese Änderung gelandet war.

Der Fehler blieb unbemerkt. zurg schickte den erfolgreichen Upstream-Status und die Header an den Player, bevor es den Body kopierte. Wenn die Frist des Clients den Body unterbrach, gab die Kopieroperation einen Fehler zurück. Diesen Fehler verwarf der Ausliefer-Pfad aber:

```go
n, _ = copyBuffered(resp, body)
```

Zu diesem Zeitpunkt war die `206`-Antwort bereits festgeschrieben und konnte nicht mehr durch einen Fehlerstatus ersetzt werden. Ohne aktiviertes Request-Logging gab es keinen Hinweis darauf, warum der Body zu kurz war. Der nachgelagerte Client bekam daher eine scheinbar erfolgreiche Partial-Content-Antwort, deren Body vor der angekündigten Länge endete.

## Regressionsverlauf {#regression-history}

Die relevanten Commits bilden eine längere Kette als der Nightly-Build, in dem das Problem gemeldet wurde:

| Datum | Commit | Auswirkung |
|---|---|---|
| 2024-06-28 | `c3aea427` | Hat das bestehende Auslesen für die Auslieferung über `DownloadFile` geleitet. Das änderte am Verhalten nichts, weil der Download-Client noch keinen Timeout für die gesamte Anfrage hatte. |
| 2024-11-17 | `6edeaa8c` | Hat `http.Client.Timeout` zum Download-Client hinzugefügt. Das ist die Regression, durch die normale Proxy-Antworten abgeschnitten wurden. |
| 2026-02-26 | `dea98d34` | Hat den gleichen 15-Sekunden-Abbruch bei RAR-Archivlesevorgängen richtig diagnostiziert, einen Streaming-Client ohne Timeout hinzugefügt und nur den RAR-Pfad darauf umgestellt. Die normale Dateiauslieferung blieb bei `DownloadFile`. |
| 2026-08-02 | `e9318e66` | Hat Downloads hinter das Multi-Provider-Interface `debrid.Provider` verlagert und den normalen Serving-Aufruf unverändert übernommen. Es hat den Real-Debrid-Bug nicht verursacht, allerdings haben neue HTTP-basierte Provider die unsichere Methode geerbt. |
| 2026-08-21 | `fc2a21f` | Der im Bericht genannte Nightly-Build. Er enthielt den Bug, hat ihn aber nicht eingeführt. |
| 2026-08-21 | `41db7245` | Hat die normale Proxy-Wiedergabe auf `DownloadFileStreaming` umgestellt und den ersten End-to-End-Regressionstest für Timeouts hinzugefügt. |
| 2026-08-21 | `eff972b8` | Hat `DownloadFile` bei jedem HTTP-Provider ohne Timeout gemacht, als strukturelle Absicherung, und die Abdeckung auf Real-Debrid, AllDebrid, TorBox und eine NZB-Kontrollgruppe erweitert. |

Der RAR-Fix vom Februar ist der wichtige Beinahe-Treffer. In seiner Commit-Nachricht steht ausdrücklich, dass `http.Client.Timeout` den Body abdeckt und dass der Standardwert von 15 Sekunden die RAR-Streams abgewürgt hat. Die Diagnose war richtig, aber der Fix beschränkte sich auf den RAR-Reader. Dass die Methoden `DownloadFile` und `DownloadFileStreaming` getrennt blieben, erlaubte es dem normalen Auslieferungspfad, die unsichere Variante noch weitere sechs Monate beizubehalten.

## Warum es lange unbemerkt blieb {#why-it-stayed-hidden}

Mehrere Effekte haben die Regression etwa 21 Monate lang verdeckt:

1. Die meisten Media-Server-Installationen lesen zurg über rclone und nicht über direktes
   WebDAV. rclone nutzt begrenzte Range-Anfragen. Die aktuellen Standardwerte für den verwalteten
   Mount beginnen bei 4 MB und wachsen bis zu einem Limit von 512 MB, daher sind bei einer schnellen
   Verbindung viele einzelne Upstream-Anfragen innerhalb von 15 Sekunden fertig. Das hat
   die Auswirkungen verringert, den Pfad aber nicht sicher gemacht, vor allem nicht bei langsameren
   Verbindungen.
2. Direkte WebDAV-Clients wie Infuse können große oder offene Ranges anfordern. Solche
   Anfragen halten eine Upstream-Antwort so lange am Leben, dass sie das Zeitlimit zuverlässig
   erreicht. Deshalb war die Reproduktion auf Discord bei drei verschiedenen Offsets genau gleich.
3. Das Puffern beim Abspielen hat Ursache und Symptom getrennt. Die Upstream-Anfrage ist nach
   15 Sekunden abgebrochen, die Wiedergabe ist aber erst gestoppt, nachdem der Player die bereits
   gelieferten Bytes verbraucht hat. Die sichtbare Verzögerung hing von Bitrate, Puffer und Spulen ab.
4. Die Antwort sah erfolgreich aus. Der CDN hat ein gültiges `206` geliefert, zurg hat es
   weitergereicht, und der Fehler beim Kopieren des Body wurde ignoriert, nachdem die Header schon
   gesendet waren. Direkte CDN-Tests blieben unauffällig, und in den normalen Logs stand kein
   Timeout-Fehler.
5. Den Wert zu erhöhen schien das Problem zu lösen. Dadurch sah der Fehler eher nach einem zu
   klein eingestellten Wert aus, und nicht nach einem Timeout, der an der falschen Abstraktion hängt.
6. Vorhandene Tests haben Bodies oder Ranges verwendet, die innerhalb des konfigurierten
   Timeouts fertig waren. Kein Test hat absichtlich einen Response-Body über die Deadline hinaus
   laufen lassen und danach über den Serving-Pfad die vollständige Länge und Checksumme geprüft.
7. Der enge RAR-Fix hat die offensichtlichste frühere Erscheinung beseitigt, aber nicht den
   unsicheren Standardwert bei normalen Downloads entfernt.

## Warum ein höheres Timeout das Problem scheinbar behoben hat {#why-a-higher-timeout-appeared-to-fix-it}

Die Einstellung auf 3600 Sekunden zu setzen hat nicht geändert, was der Timeout abdeckt. Sie hat nur die absolute Deadline weit genug nach hinten verschoben, damit die gemeldete 25.8-Sekunden-Übertragung fertig werden kann:

```text
15 seconds   < 25.8-second transfer < 3600 seconds
```

Das war ein Workaround, kein sicherer Fix. Jeder endliche Timeout für die gesamte Anfrage kann einen ausreichend langen Body trotzdem abbrechen, zum Beispiel bei einem langsamen Client oder einer pausierten Verbindung. Die Einstellung fließt außerdem in den Dial-Timeout des Download-Clients und in begrenzte Verifizierungsanfragen ein. Wenn man sie auf eine Stunde erhöht, kann ein nicht erreichbarer Host also viel länger brauchen, bis er fehlschlägt. Gefixte Builds sollten den normalen konfigurierten Wert verwenden. Er begrenzt einen durchgeleiteten Media-Body nicht mehr.

## Fix und Schutzmechanismen {#fix-and-guardrails}

Der schnelle Fix in `41db7245` hat `streamFileToResponse` so umgestellt, dass er über `Provider.DownloadFileStreaming` lädt. Dieser Client nutzt denselben Transport, hat aber kein `http.Client.Timeout`. Die Lebensdauer des Bodys hängt also nicht mehr an `download_timeout_secs`. Die Anfrage nutzt weiterhin den Request-Context vom Downstream, daher bricht das Lesen vom Upstream ab, sobald der Player die Verbindung trennt. Der Verbindungsaufbau und der TLS-Handshake bleiben weiterhin durch den Transport begrenzt.

`eff972b8` hat dann die Abhängigkeit davon entfernt, dass jeder Aufrufer die richtige Methode wählt, deren Name "Streaming" enthält:

- Real-Debrids `DownloadFile` nutzt jetzt `DoStreaming`.
- Der gemeinsame Helper `debrid.DownloadRanged` akzeptiert `StreamingDoer`, das nur `DoStreaming` anbietet. AllDebrid und TorBox nutzen diesen Helper.
- Beide Download-Methoden der Provider sind deshalb auch für sehr lange Response-Bodies sicher.
- Begrenzte Lesevorgänge, die nicht der Wiedergabe dienen, etwa die zwei 64-KiB-Lesevorgänge für den OpenSubtitles-Hash, bekommen einen eigenen Context-Deadline. Sie leihen sich also kein unsicheres client-weites Body-Timeout.

Die Regressionstests in `internal/universal/stream_timeout_test.go` nutzen einen lokalen Server, der einen 1,6-MB-Body in 16 Chunks über etwa 1,6 Sekunden sendet, während das konfigurierte Timeout eine Sekunde beträgt. Sie prüfen jeweils die volle Länge und die Checksumme:

- direkt über beide Download-Methoden für Real-Debrid, AllDebrid und TorBox;
- End-to-End über `streamFileToResponse` für alle drei HTTP-basierten Provider; und
- über einen NZB-ähnlichen lokalen Provider als unberührten Kontrolltest.

Die Regel ist jetzt explizit: Eine Methode, die einen Download-Body zurückgibt, darf niemals ein Timeout für die gesamte Anfrage verwenden. Kurze Probe-Requests und Metadaten-Abfragen sollen eine Deadline über ihren eigenen Context bekommen. Streaming-Bodies sollen dagegen bis zum Abschluss, bis zum Abbruch durch den Downstream oder bis zu einem echten Transportfehler laufen.

## Begrenzt durch Fortschritt, nicht durch Zeit {#bounded-by-progress-not-by-time}

Bis zum Ende am Leben zu bleiben ließ einen Lesevorgang nie enden: ein Liefer-Node, der die Antwort offen hält und nichts mehr nachliefert, oder der überhaupt nie antwortet. Im September 2026 hing ein Plex-Scan elf Stunden lang an einer einzigen Real-Debrid-Datei, deren Lesevorgang nie fehlschlug. Dieser Client hatte keine Grenze, an der er aufgeben konnte, und rclones `--timeout` ist eine Leerlauf-Grenze: zurg leitet einen Body in 256-KiB-Schreibvorgängen weiter. Ein Node, der alle fünf Minuten 256 KiB liefert (also unter 1 KB/s), setzt den Timer deshalb endlos zurück. Ein langsamerer Node löst ihn zwar aus, aber rclone schickt dann dieselbe Anfrage an denselben Node und loggt pro drei Timeouts einen Fehler. Gemessen auf zen mit rclone 1.75 und den eigenen Flags des Mounts am 2026-10-03 war ein Leser an so einem Node auch nach 30 Minuten noch blockiert.

`internal/universal/starved_read.go` schneidet einen weitergeleiteten Lesevorgang jetzt ab, sobald der Node in 30 Sekunden weniger als 1 MiB geliefert hat, in denen zurg auf ihn gewartet hat. Gezählt wird nur das Warten auf den Node: vom Moment an, in dem die Anfrage eine Verbindung hat, bis ihre Header ankommen, und die Zeit innerhalb jedes Lesens des Bodys. Zeit, in der an den Client geschrieben wird, zählt nicht. Die Eigenschaft oben gilt also weiterhin, und ein pausierter oder langsamer Client kann einen Stream so lange offen halten, wie er will. Eine abgeschnittene Datei wird zwei Minuten lang mit `503` beantwortet, damit rclones Wiederholungen sofort enden, statt jeweils ein weiteres Zeitfenster abzuwarten. Lokal ausgelieferte NZB-Lesevorgänge werden nicht überwacht.

Lesevorgänge von Dateien in einem Archiv sind nie über `streamFileToResponse` gelaufen und fielen deshalb bis Karte 204 aus dieser Grenze heraus. Ihre Bytes kommen aus Abschnitten jedes Volumes, die über denselben Client von `providerDoer.Do` geholt und vom RAR-Parser gelesen werden. Ein Node konnte einen solchen Abschnitt so lange halten, wie er die Verbindung offen ließ. Jeder Volume-Abruf wird jetzt von derselben Untergrenze überwacht, der Eintrag wird zwei Minuten lang abgelehnt, wenn ein Abruf abgeschnitten wird, und ein Abbruch während das Archiv gelistet wird, lässt die Auflistung fehlschlagen. Sonst würde der Parser das Volume als beschädigt auslassen. Bei einem echten Set mit fünf Volumes wurde der Eintrag so mit seiner vollen Länge, aber falschen Bytes nach dem zweiten Volume ausgeliefert.

Karte 222 fand dasselbe hinter allen anderen Wegen, auf denen ein Node einen Volume-Lesevorgang scheitern lassen kann: einen 5xx, ein 429, eine Verbindung, die mitten im Header abbricht. Der Parser hielt jeden davon für ein beschädigtes Volume und listete das Archiv ohne dieses auf, und diese Auflistung wurde gecacht. Beim selben Set lieferte also ein 503 bei Volume 3 ab Offset 16.057 die falschen Bytes und machte damit weiter, auch nachdem der Node sich erholt hatte. Der Parser unterscheidet jetzt ein Volume, dessen Bytes nicht geparst werden konnten, von einem, dessen Bytes gar nicht angekommen sind (`rarstream.ErrVolumeUnavailable`). Markiert wird das von `HTTPSrc` für die Statuscodes, die es sieht, von `providerDoer` für alles, womit ein Remote-Lesevorgang fehlschlägt, und vom NZB-Body für das, was dessen Reader als Transport einstuft. Das zweite lässt die Auflistung fehlschlagen, auch bei verschachtelten Sets und bei Gruppierung über den Volume-Kopf. Der Fehler wird mit `503` und einem `Retry-After` beantwortet, nie als Archivfehler gecacht, nie als Urteil festgehalten und nie bei einem Browse mit den rohen Volumes anstelle des Archivinhalts beantwortet. Beschädigte oder fehlende Volumes werden wie bisher drumherum aufgelistet.

Die 256-KiB-Schreibvorgänge von oben wurden ebenfalls in Karte 204 geändert. Die Kopie füllt ihren Puffer weiterhin, solange ein Node schnell ist, sodass ein schneller Body wie bisher in ganzen Puffern hinausgeht. Sie sendet die ersten Bytes aber sofort, sobald sie ankommen, und hält kein Byte länger als 250 ms (`defaultCopyFlushAfter` in `internal/universal/downloader.go`), und sie schiebt die Antwort mit ihnen hinaus. Ein langsamer Node hält den Client nicht mehr von seinen Headern ab. Vorher hatte ein Archiv-Eintrag auf einem Node, der alle vier Minuten 64 KiB und dann 16 KiB sendete, auf zen über rclone und die eigenen Flags des Mounts rclone gar nichts geschickt, als rclone ihn genau nach fünf Minuten dreimal hintereinander aufgab: Alles, was der Node gesendet hatte, lag noch im Puffer.
