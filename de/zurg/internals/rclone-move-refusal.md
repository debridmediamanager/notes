# Leere Imports nach einem abgelehnten Verschieben {#empty-imports-after-a-refused-move}

Reproduziert mit rclone 1.72.0, einem local-first Union, VFS-Vollcaching und dem .NET 6 `File.Move(source, destination)`, das Sonarr 4.0.19.2979 verwendet.

Wenn das Backend ein MOVE ablehnt, lässt `vfs.File.rename` von rclone Verzeichnis und Name der Datei auf das versuchte Ziel zeigen. .NET greift dann auf eine Kopie zurück. Beim Anlegen des Ziels entsteht ein leerer VFS-Cache-Eintrag. Beim Öffnen der Quelle landet man im selben Eintrag, sodass die Kopie EOF liest und Erfolg meldet. Die Reproduktion erwartete 4096 Bytes und bekam null. Die Änderung der WebDAV-Ablehnung von 409 auf 422 änderte am Ergebnis nichts.

Der Patch in `scripts/patches/rclone-v1.72.0-rename.patch` stellt Verzeichnis und Name wieder her, wenn das direkte Umbenennen fehlschlägt. Er enthält einen Regressionstest für VFS aus dem Upstream. Der Mount-Test prüft den gesamten Weg über WebDAV, Union, FUSE und .NET mit einem Fake-Archiv und ohne Provider-Zugangsdaten. Das Schadensurteil wird eingespielt, während die Fixture-Bytes noch lesbar sind: .NET darf diese Bytes erfolgreich kopieren, darf sie aber nicht in eine leere Datei verwandeln.

Baue ein neues Binary neben dem installierten:

```sh
./scripts/build-rclone-move-fix.sh /absolute/path/to/rclone-fixed
RCLONE_TEST_BIN=/absolute/path/to/rclone-fixed ./integration/magic_move_refusal.sh
```

Der Build fixiert den Upstream-Commit `38ab3dd5b1df946aecf5bd085c671c86f46f68eb` (1.72.0). Vor dem Bauen laufen die VFS-Rename-Tests. Der Mount-Test braucht Linux-FUSE und Docker oder ein eigenständiges `DOTNET_MOVE_PROBE_BIN`, das aus `integration/dotnet-move-probe` gebaut wurde. Gegen das unveränderte Binary schlägt er absichtlich fehl. `make integration-test` enthält diese Prüfung. Setze beim Ausführen der Suite `RCLONE_TEST_BIN` und `RCLONE_BIN` auf das korrigierte Binary.

Für die Installation musst du den Mount neu starten, und zwar mit den üblichen Media-Server-Schutzmechanismen deines Setups. Behalte das alte Binary für ein Rollback. Vorhandene leere Dateien im lokalen Upstream einer Union überstehen einen Mount-Neustart. Bewahre sie dort und entferne nur bestätigte leere Import-Artefakte. Ein Neustart räumt die veralteten VFS-Knoten auf, repariert aber keine fehlenden Usenet-Artikel.

Diese Korrektur unterdrückt den Kopier-Fallback von .NET nicht und macht auch keine beschädigten Inhalte lesbar. Die Verfügbarkeitsprüfung von zurg vor dem SABnzbd-Abschluss und das abgelehnte MOVE sind eigenständige Schutzmechanismen und bleiben bestehen. Stichprobenartige Verfügbarkeitsprüfung ist keine vollständige Dateiprüfung. Siehe `sabnzbd-client-contract.md`.

Der angepinnte Patch enthält außerdem die Korrektur für Datei-Aliase, die die eingebettete Union nutzt. Mit `action_policy: all` können sowohl lokal als auch WebDAV eine Dateioperation erhalten. Ein erfolgreiches lokales Move oder Remove zusammen mit einem WebDAV-404 wird nur akzeptiert, wenn eine frische Abfrage belegt, dass die Quelle des fehlgeschlagenen Upstreams weg ist. Operationen, bei denen alle fehlgeschlagen sind, eine Quelle, die noch existiert, ein fehlendes Zielverzeichnis sowie andere I/O- oder Berechtigungsfehler bleiben Fehler. Das resultierende Binary meldet `v1.72.0-zurg-rename-sidecar-fix`, damit es sich vom ursprünglichen, nur VFS-basierten Build unterscheiden lässt.
