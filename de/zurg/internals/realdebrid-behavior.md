# Torrents

Real-Debrid unterstützt das Herunterladen einer unbegrenzten Anzahl von Torrent-Dateien und Magnet-Links sowie die Auswahl der Dateien daraus, die du herunterladen möchtest.
Wenn die Torrent-Datei oder der Magnet-Link bereits von einem anderen Nutzer heruntergeladen wurde, gilt er als "cached", und Real-Debrid stellt dir den gecachten Link direkt zur Verfügung.
Falls nicht, versucht Real-Debrid, den Magnet-Link über öffentliche Tracker oder DHT/PEX herunterzuladen.
Handelt es sich um eine Torrent-Datei mit Tracker-Informationen, werden diese Tracker verwendet. Das ist praktisch für private Tracker (leider blockieren viele private Tracker die Download-Server von Real-Debrid).
Hat der Torrent keine Seeder oder Leecher mehr und lassen sich nicht alle Teile des Torrents herunterladen, tritt ein Fehler auf.
Nach dem Download erhältst du außerdem gecachte Links, die so aussehen: https://real-debrid.com/d/DOWNLOADCODE
DOWNLOADCODE ist genau eine 13 Zeichen lange, eindeutige ID der jeweiligen Datei (alles nach dem 13. Zeichen wird ignoriert).

# Dateien auswählen {#selecting-files}

As mentioned, you can select only the files you want to download from inside a torrent.
If a torrent contains files A, B and C and you select A and B, it will only download A and B.
The cached status of a torrent actually depends on this unique file selection.
Going back to the torrent with files A, B and C, there are different cached statuses for A, B, B (single), A+B, B+C, A+C (pair), or A+B+C (all files).
Each unique selection downloads the torrent again from the trackers and returns a different cached link, even for the same file.

# Zwischengespeicherte Links {#cached-links}

Cached-Links sind keine herunterladbaren Links, sondern dienen bei Real-Debrid eigentlich nur als Container für DOWNLOAD CODES.
Du musst sie „unrestrict“ oder in einen echten, herunterladbaren oder streambaren Link von Real-Debrid umwandeln, der nach 7 Tagen abläuft.
Cached-Links halten länger als 7 Tage. Wenn ein Torrent funktionierende Cached-Links hat (also erfolgreich unrestricted werden kann), heißt das, dass er noch bei Real-Debrid gecacht ist.
Das ist nicht sicher bekannt, aber sehr wahrscheinlich lässt sich der Cache-Status eines Torrents verlängern, wenn mehr Nutzer einen Cached-Link unrestricten.

Beachte, dass die einzige Möglichkeit zu prüfen, ob ein Cached-Link funktioniert, darin besteht, ihn zu unrestricten und das erste Byte des unrestricted Links über den http-Range-Header zu prüfen.
zurg unterstützt beide Prüfarten: HEAD (Standard, schnell) und Range-basiert (GET bytes=0-0, gründlicher). Die Auswahl erfolgt über die Config-Option use_range_verification.

# Teilen zwischengespeicherter Links zwischen Konten (gemessen am 2026-08-19) {#cached-link-sharing-across-accounts-measured-2026-08-19}

RD gibt Link-IDs in zwei Längen zurück, 13 Zeichen (~70 %) und 16 Zeichen (~30 %). Die zusätzlichen 3 Zeichen bestimmen, WER den Link unrestricten kann:
- Auf die ersten 13 Zeichen gekürzt, lässt sich ein /d/-Link von JEDEM Premium-Konto unrestricten, nicht nur von dem, das ihn erzeugt hat. Die Torrent-Bibliothek des Aufrufers bleibt unberührt. Die einzige Nebenwirkung ist ein Eintrag im Download-Verlauf des Aufrufers.
- Mit der vollen 16-Zeichen-ID gesendet, lässt sich derselbe Link NUR vom erzeugenden Konto unrestricten. Jedes andere Konto bekommt "unavailable_file", auch wenn der erzeugende Torrent noch aktiv ist, auch wenn der Aufrufer dieselbe infohash in seiner eigenen Bibliothek hat, und unabhängig vom ip-Parameter.
Deshalb immer auf 13 Zeichen kürzen, bevor du einen gespeicherten Link unrestrictest. Wer mit ungekürzten IDs testet, kommt fälschlicherweise zu dem Schluss, dass Link-Sharing unmöglich ist.

Gecachte Links überleben es, wenn das erzeugende Konto seinen Torrent löscht, aber sie laufen mit der Zeit ab. Bei einer großen Stichprobe ließen sich Links, die vor 1 bis 2 Monaten erzeugt wurden, alle noch kontoübergreifend unrestricten. Links, die älter als etwa 3 Monate waren, gaben alle "hoster_unavailable" zurück. Außerdem kann RD die Inhalte selbst aus seinem Cache entfernen. Ein Hash, der vor einem Monat nachweislich gecacht war, kann im nächsten Monat als downloading mit 0 Seedern dastehen. Dann gibt der Link für alle "unavailable_file" zurück, auch für das erzeugende Konto.

So deutest du einen Unrestrict-Fehler bei einem gespeicherten gecachten Link:
- 13-Zeichen-Link + hoster_unavailable -> Der Link ist abgelaufen. Den Torrent mit derselben Auswahl erneut hinzuzufügen erzeugt frische Links (siehe Reparatur weiter unten).
- 13-Zeichen-Link + unavailable_file -> RD hat die Inhalte komplett entfernt. Frische Links erfordern einen echten Neudownload von Seedern.
- 16-Zeichen-Link + unavailable_file -> Sagt nichts über die Verfügbarkeit aus. Du bist einfach nicht das erzeugende Konto. Auf 13 Zeichen kürzen und erneut versuchen.

Unrestricted Links (die *.download-Host-URLs) sind durch serverseitiges Tracking an die IP gebunden, nicht durch Verweigerung. Der CDN liefert auch an eine fremde IP mit einem 206 aus. RD erfasst aber die Download-IPs, und wenn ein Konto seine Links von mehreren IPs nutzt, gibt es eine Warnung wegen Kontoteilung. Übergib deshalb die IP des Downloaders an unrestrict/link (den ip-Parameter), damit der Link für die IP erzeugt wird, die die Daten tatsächlich abruft.

# Defekte zwischengespeicherte Links reparieren {#repairing-broken-cached-links}

Manchmal funktioniert ein gecachter Link oder sogar der unrestricted Link einer Datei innerhalb eines Torrents nicht mehr.
Das kann an einem unrestrict-API-Fehler liegen oder daran, dass der unrestricted Link eine HTTP-Fehlerantwort zurückgibt.
Um das zu beheben, müssen wir den Torrent neu herunterladen und neue, frische gecachte Links erzeugen.
Du kannst versuchen, den Torrent mit exakt der gleichen Dateiauswahl erneut herunterzuladen und zu schauen, ob neue, frische gecachte Links erzeugt werden.
Falls das nicht klappt, musst du eine andere Dateiauswahl für diesen Torrent treffen.
Wenn zum Beispiel in einem Torrent mit mehreren Dateien nur eine Datei kaputt ist, dann wähle nur genau diese kaputte Datei aus.
Wenn trotzdem wieder ein kaputter gecachter Link erzeugt wird, füge der Auswahl eine weitere Datei hinzu.
Das machst du so lange, bis du einen frischen, funktionierenden gecachten Link bekommst.

# RAR-Verhalten {#rar-behavior}

Real-Debrid hat das Verhalten, Torrents in RAR-Dateien (ohne Komprimierung) zu speichern, wenn du einen nicht unterstützten Dateityp auswählst, der nicht gestreamt werden kann.
Bestätigte Videodateitypen: .avi .flv .m2ts .m4v .mkv .mov .mp4 .mpg .mpeg .ts .webm .wmv
Bestätigte Audiodateitypen: .mp3 .flac .m4a
Wenn du diese Dateitypen auswählst, liefert Real-Debrid einzelne Datei-Links, die streambar sind.
Wenn du etwas anderes auswählst, wird es garantiert von Real-Debrid in einem RAR-Archiv gespeichert.
Wenn du eine .mkv-Videodatei und eine .sub-Untertitel-Datei auswählst, wird sie gepackt (geraret).
Das Gleiche gilt, wenn du nur das .jpg-Poster auswählst: Es wird geraret.

Ein Torrent, auch mit mehreren Dateien, gibt, wenn er geraret wird, nur einen einzigen Cache-Link zurück (der auf die RAR-Datei zeigt).
Wenn du nur bestätigte Video- oder Audiodateitypen auswählst, wird nichts geraret, und du erhältst für jede ausgewählte Datei einen Cache-Link.

# Das Löschen einer Zeile in der Downloads-Liste widerruft die URL, die sie erzeugt hat {#deleting-a-downloads-list-row-revokes-the-url-it-minted}

Gemessen am 2026-08-22 auf dem Testaccount, ein Unrestrict pro Fall.

Ein Unrestrict legt eine Zeile in /downloads an und eine URL auf einem nummerierten Host, z. B.
https://124-4.download.real-debrid.com/d/<13-Zeichen-Code>/<Dateiname>. Der Code
ist nicht an einen Host gebunden: Bevor die Zeile gelöscht wird, antwortet derselbe Code mit 200 auf 44-4, 125-4 und auf seinen eigenen 124-4. Das Dateinamen-Segment am Ende ist überall optional; zurg entfernt es, und beide Formen antworten identisch.

DELETE /downloads/delete/<id> widerruft diesen Code. Was danach noch funktioniert, hängt davon ab, welche Hosts ihn bereits ausgeliefert haben:

  - Zeile gelöscht, bevor die URL jemals abgerufen wurde: Jeder Host antwortet mit 404 und X-Error: invalid_download_code. Auch 30s später noch 404, es pendelt sich nicht ein.
  - Zeile gelöscht nach einem Abruf über 44-4: 44-4 antwortet weiterhin mit 200, während der erzeugende Host 124-4 und ein unberührter 125-4 beide mit 404 invalid_download_code antworten.

Ein Abruf aktiviert den Code also auf dem Host, der ihn ausgeliefert hat, und die Zeile sorgt dafür, dass alle anderen Hosts weiter ausliefern. Das ist das Gegenteil der Annahme, auf der die Bereinigung der Downloads-Liste aufgebaut war. Das ist wichtig, weil zurg den Download-Host pro Anfrage wählt (ensureReachableDownloadServer schreibt auf einen der N schnellsten Hosts um). Der Host, auf den ein Verifizierungs-HEAD gelandet ist, ist also nicht der Host, den die nächste Anfrage wählt. Eine Auflösung, die nach dem Löschen ihrer Zeile noch im Link-Cache liegt, antwortet daher bei fast jeder späteren Anfrage mit 404 invalid_download_code. Das sieht aus wie ein verrotteter Link und markiert eine gesunde Veröffentlichung als defekt.

Einen Link nach dem Löschen erneut zu unrestricten erzeugt irgendwann eine neue ID auf einem neuen Host, und dann funktioniert alles normal. IDs werden nicht wiederverwendet.

Aber nicht sofort. Die erste Messung hier sagte "unbeeinflusst", weil sie Minuten später gemacht wurde. Erneut gemessen am 2026-08-23 auf dem Testaccount: Nach DELETE /downloads/delete/<id> gab unrestrict/link 75 Sekunden lang dieselbe tote ID zurück und erzeugte erst bei t+81s eine neue.

Daraus folgen zwei Dinge, und beide stehen so im Code. downloadsCleanupMinAge hält eine Zeile zwei Minuten, bevor sie entfernt wird. Eine Schwester-Instanz, die in diesem Fenster denselben Link auflöst, bekommt also einen lebendigen Code. Außerdem passt die Wiederholungskette des Ausliefer-Pfads (vier Versuche in etwa sechs Sekunden) komplett in dieses Fenster. Dass sie erschöpft ist, sagt deshalb nichts über die Datei aus. Wenn jede Auflösung als die URL zurückkommt, die gerade mit 404 geantwortet hat, verweigert zurg den Lesezugriff mit einem Retry-After, statt die Veröffentlichung als defekt zu markieren.
