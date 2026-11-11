# Der MCP-Endpunkt {#the-mcp-endpoint}

zurg kann einem KI-Agenten über das [Model Context Protocol](https://modelcontextprotocol.io) antworten:
Der Client fragt, welche Tools es gibt, zurg beschreibt sie, und der Agent ruft sie auf, um die Bibliothek zu lesen, herauszufinden, warum ein Release nicht abspielbar ist, es zu reparieren oder die Media-Server zu steuern. Es ist dieselbe Menge an Operationen, die auch das Dashboard und die CLI bieten, nur als typisierte Tools mit Schemas statt als HTML und 303-Weiterleitungen.

Der Endpunkt ist standardmäßig deaktiviert. Er liegt hinter derselben Basic Auth wie das Dashboard, und zurg liefert ihn überhaupt nicht aus, wenn kein Benutzername konfiguriert ist. Ist der Benutzername leer, sind alle Routen auf dem Server öffentlich, und diese Tools löschen Releases.

## Konfiguration {#configuration}

```yaml
mcp:
  enabled: true
```

Das war's im Grunde für eine normale Installation. Der Rest hat Standardwerte, die man kennen sollte:

```yaml
mcp:
  enabled: true
  toolsets: [library, releases, repair]   # the default; see below
  read_only: false                        # withhold every tool that changes anything
  allow_unauthenticated: false            # serve /mcp with no username set
  allow_lifecycle: false                  # admit the tools that stop zurg or its mount
  page_limit: 50                          # items a listing returns by default; 500 is the cap
  max_result_kb: 256                      # ceiling on one result; a page over it is trimmed
  session_timeout_mins: 30                # -1 keeps sessions for the life of the process
```

Wie die anderen Funktionsblöcke wird auch dieser einmal beim Start gelesen: Änderungen werden erst nach einem Neustart wirksam.

## Verbinden {#connecting}

### Über HTTP {#over-http}

Der Endpunkt ist `/mcp` auf dem üblichen Port von zurg und nutzt Streamable HTTP. Verbinde einen Client mit `http://<host>:9999/mcp` und den Zugangsdaten des Dashboards.

```bash
npx @modelcontextprotocol/inspector
# Transport:  Streamable HTTP
# URL:        http://localhost:9999/mcp
# Header:     Authorization: Basic <base64 of user:password>
```

### Über stdio {#over-stdio}

Clients, die nur stdio sprechen, nutzen den Unterbefehl `zurg mcp`. Er stellt die Verbindung zu einer laufenden Instanz her:

```json
{
  "mcpServers": {
    "zurg": {
      "command": "/path/to/zurg",
      "args": ["mcp"],
      "cwd": "/path/to/your/zurg/directory"
    }
  }
}
```

Das `cwd` ist wichtig: Jeder zurg-Pfad wird relativ zum Arbeitsverzeichnis aufgelöst, und dort liest `zurg mcp` die `config.yml` für Port und Zugangsdaten. Damit braucht es keine weiteren Argumente. `--username` und `--password` überschreiben die lokalen Zugangsdaten. Eine eigene `--url` übernimmt nie Zugangsdaten aus der lokalen Config. Wenn dieser Endpunkt Zugangsdaten braucht, übergib beide Credential-Flags ausdrücklich, damit ein lokales Passwort nicht versehentlich an einen anderen Host geschickt wird.

Es startet keine zweite Instanz. Eine zweite zurg würde die ganze Bibliothek laden, eine weitere Gruppe von Provider-Slots bei Accounts belegen, die danach abgerechnet werden, und sich mit der ersten um den Mount streiten. Deshalb ist der Befehl nur eine Pipe zum Daemon, und wenn der Daemon nicht läuft, liefert er nichts aus. Seine Diagnosemeldungen gehen nach stderr, weil stdout das Protokoll trägt.

Eine Einschränkung: Eine Benachrichtigung, die der Server außerhalb eines Aufrufs auslöst, wird nicht über die Brücke weitergeleitet. Fortschritts- und Logzeilen, die *während* eines Aufrufs entstehen, hängen an der Antwort dieses Aufrufs und kommen normal an, was alles abdeckt, was zurg sendet.

## Toolsets

Die volle Oberfläche von zurg umfasst ein paar hundert Tools. Das ist mehr, als ein Client gut verarbeiten kann. Ab etwa achtzig wählt ein Modell häufiger das falsche Tool, und allein die Schemas kosten zehntausende Tokens. Deshalb wählt `toolsets` Gruppen aus, und der Standard ist eine funktionierende Teilmenge statt alles.

| Toolset | Im Standard | Was es abdeckt |
|---|:-:|---|
| `library` | ja | Suche, Verzeichnislisten, Tag-Zählungen |
| `releases` | ja | Ein Release im Detail: Dateien, Kopien pro Konto, was jede Datei ausliefern kann |
| `repair` | ja | Was kaputt ist, ob die Reparatur es erreicht, Erzwingen einer Reparatur |
| `releases_write` | | Löschen, Umbenennen, Taggen, Erzwingen der Anzeige, Schreiben von `.strm`-Dateien |
| `magic` | | Der Namensraum `__magic__`: das gespeicherte Layout, dessen Zeilen und das Verschieben von Dingen |
| `plex` | | Plex, Jellyfin und Emby: Status, Zuordnung und abgesicherte Scans |
| `providers` | | Die eingerichteten Konten: was jedes kann, ob es erreichbar ist, was es verbraucht hat |
| `usenet` | | Das NZB-Backend: Newskonten, Artikelprüfungen, Schäden und der Artikel-Cache |
| `clients` | | Die SABnzbd-, qBittorrent- und Stremio-Endpunkte, mit denen Sonarr und Radarr sprechen |
| `diagnostics` | | Das Log, die Byte-Zähler, Speicher und Goroutinen |
| `config` | | Die Konfiguration lesen, Abweichungen finden und eine kuratierte Auswahl an Schlüsseln schreiben |
| `mount` | | Der rclone-Mount: Status, Vergessen zwischengespeicherter Listings, Neustart |
| `system` | | Build-Infos, `doctor`, der Dienst, Backups und Updates |

`toolsets: [all]` aktiviert jede Gruppe. Ein Name mit vorangestelltem `-` zieht eine Gruppe ab. Daher ist `[all, -config, -system]` die gesamte Oberfläche ohne die beiden Gruppen, die eher die Maschine als die Bibliothek verändern. Ein unbekannter Name erzeugt beim Start eine Warnung und wird ignoriert: Ein Tippfehler darf den Endpunkt nicht wegnehmen.

Die Tools, die zurg stoppen, seinen Dienst steuern oder den Mount durchstarten, sind keine eigene Gruppe. Sie liegen in `system` und `mount` und bleiben zurückgehalten, bis `allow_lifecycle` gesetzt ist, egal was `toolsets` sagt.

Eine kleine `server`-Gruppe wird immer registriert, egal was `toolsets` sagt. Sie zeigt, welche Build-Version läuft und ob die Bibliothek fertig geladen ist. Würde man sie zurückhalten, könnte ein Client nicht herausfinden, dass alle anderen Antworten gerade unvollständig sind.

## Was er nicht ohne Nachfrage tut {#what-it-will-not-do-without-being-asked}

**Bestätigung.** Ein Tool, das etwas wegnimmt, beschreibt zuerst, was es tun würde,
und gibt ein Token zurück; es handelt erst, wenn es erneut mit diesem Token
aufgerufen wird. Das Token wird aus dem Plan abgeleitet, sodass sich eine
Bestätigung nicht auf einen anderen Plan übertragen lässt. Hat sich die Bibliothek
in der Zwischenzeit geändert, beschreibt der zweite Aufruf erneut, statt etwas zu
tun. Tokens sind einmalig verwendbar, gelten zwei Minuten und überleben keinen
Neustart.

**`read_only`.** Ein Schalter, der alle Tools ausblendet, die etwas ändern, egal
was `toolsets` sagt. Die Frage, die sich ein Betreiber eigentlich stellt, lautet
„Kann das meine Bibliothek kaputt machen?“ und nicht „Welches dieser Tools
schreibt?“. Diese Tools werden aus `tools/list` entfernt, sodass ein Client
keine Funktion auswählen kann, die dieser Endpunkt nie zulassen wird. Die Prüfung
zur Aufrufzeit bleibt als zusätzliche Absicherung bestehen, falls sich die
laufende Einstellung nach dem Aufbau des Servers ändert.

**`allow_lifecycle`.** Die Tools, die zurg stoppen, seinen Dienst steuern oder
den Mount neu zyklen, werden über einen eigenen Schalter genauso ausgeblendet.
Jedes davon kann die gesamte Bibliothek auf einmal verschwinden lassen, und die
Prozess- bzw. Dienst-Aktionen können ihr eigenes Ergebnis nicht melden, weil sie
den Prozess beenden können, bevor er auf den Aufruf antwortet.

**Geheimnisse.** Kein Tool-Ergebnis enthält ein Provider-Token, einen API-Schlüssel,
ein News-Server-Passwort, einen aufgelösten CDN-Link oder eine signierte
`.strm`-URL. Die Log-Ausgabe wird beim Verlassen geschwärzt. Ein aufgelöster Link
kann von jedem eingelöst werden, der ihn besitzt, und zwar über das Konto, das
ihn erstellt hat. Ein Transkript ist deshalb kein Ort für so einen Link.

**Größe.** Jede Auflistung wird zweifach begrenzt: durch ein Seitenlimit und durch
eine Obergrenze für das marshallte Ergebnis. Ein Konto mit 84.000 Releases, das
wir dagegen gemessen haben, enthält allein etwa zwölf Megabyte an Namen, noch
bevor eine einzige Datei aufgelistet wird. Ein Ergebnis oberhalb der Obergrenze
wird gekürzt, und das wird auch so angegeben.

## Hinweise {#notes}

Der Endpoint übernimmt die Basic-Auth des Dashboards, weil er innerhalb davon registriert wird.
Eine Cross-Origin-Anfrage wird abgelehnt: `/mcp` ist für einen lokalen Agenten gedacht, nicht für eine Webseite.
Ein Reverse Proxy vor zurg funktioniert. Die DNS-Rebinding-Prüfung der Protokollbibliothek würde sonst einen Proxy ablehnen, der seinen eigenen `Host` weiterleitet und dabei `127.0.0.1` anspricht. Deshalb schaltet zurg diese Prüfung ab und überlässt die Absicherung der Basic-Auth.

`zurg mcp --help` zeigt die Flags der Bridge an. `zurg doctor` prüft, ob der Endpoint überhaupt antwortet.
