# Interna {#internals}

Wie zurg aufgebaut ist. Was dabei gemessen wurde. Die Designnotizen zu den kniffligen Teilen.
Geschrieben für alle, die gleich am Code etwas ändern wollen. Um zurg auszuführen, brauchst du davon nichts.

## Die Grundstruktur {#the-shape-of-it}

| Seite | Was sie enthält |
|---|---|
| [Architektur](architecture.md) | Der Aufbau des Ganzen und die Invarianten, die leicht kaputtgehen. Hier anfangen. |
| [Benennung](naming.md) | Wie ein Release und seine Dateien die Namen bekommen, die das Mount anzeigt. |
| [Persistente Caches](persistent-caches.md) | Was zwischen Neustarts auf der Festplatte gespeichert bleibt und was das kostet. |
| [Verzeichniskonfiguration UI/UX](uiux.md) | Die Design-Bewertung hinter dem Verzeichnis-Editor. |

## Was gemessen wurde {#what-was-measured}

| Seite | Was sie enthält |
|---|---|
| [Debrid-Baseline](debrid-baseline.md) | Was zurg kostet und wie schnell es sich über Real-Debrid, AllDebrid und TorBox anfühlt. |
| [Torrent-Lebenszyklus](torrent-lifecycle.md) | Was jeder Account während eines Downloads tatsächlich meldet, live mitgeschnitten. |
| [Real-Debrid-API-Notizen](realdebrid-behavior.md) | Bedeutung der Links, Dateiauswahl und was „cached“ wirklich heißt. |

## Verträge, die zurg erfüllen muss {#contracts-zurg-has-to-satisfy}

| Seite | Was sie enthält |
|---|---|
| [SABnzbd-Client-Vertrag](sabnzbd-client-contract.md) | Die genauen Formate, die Sonarr und Radarr von einem SABnzbd erwarten. |
| [qBittorrent-Client-Vertrag](qbittorrent-client-contract.md) | Dasselbe für einen qBittorrent. |
| [plex_api.json](../../internals/plex_api.json) | Die rohe Plex-API-Oberfläche, gegen die zurg programmiert. 1.2 MB. |

## Was schiefging {#things-that-went-wrong}

| Seite | Was sie enthält |
|---|---|
| [Plex trash sweep](plex-trash-sweep.md) | Die Bereinigung an zurgs eigene Sicht auf defekte Dateien anpassen. |
| [Stream timeout regression](stream-timeout-regression.md) | Ein durchgeleiteter Stream, der bei langen Lesevorgängen nicht mehr durchhielt. |
| [rclone move refusal](rclone-move-refusal.md) | Leere Importe nach einem Backend, das ein MOVE abgelehnt hat, und der Patch dazu. |

## Testen {#testing}

- [E2E-Tests](e2e-test.md) erklärt, was die End-to-End-Suite prüft und was ihr Ausführen kostet.

Was ein bestimmter Dienst leistet und welche Grenzen er hat, steht unter
[Providers](../providers/index.md) und nicht hier.
