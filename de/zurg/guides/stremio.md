# Das Stremio-Addon {#the-stremio-addon}

zurg kann Stremio als Addon antworten. Stremio fragt nach einer IMDb-ID. zurg durchsucht deine Newznab-Indexer und holt die NZB der gewählten Veröffentlichung ins Usenet-Backend. Danach wird sie wie jede andere zurg-Veröffentlichung abgespielt und repariert. Alles, was so abgespielt wird, landet auch in der Bibliothek und erscheint in Plex.

## Konfiguration {#configuration}

Das Addon braucht ein NZB-Konto, `nzb` oder [`torbox_nzb`](../providers/torbox-nzb.md). Darüber laufen die eigentlichen Daten. Außerdem brauchst du mindestens einen Indexer. Bei `torbox_nzb` startet ein Release, das TorBox schon hat, innerhalb der Wartezeit des Addons, solange kein anderer NZB-Post wartet. Ein noch nicht gecachtes Release muss dagegen erst bei TorBox fertig werden, und das dauert länger, als ein Player wartet.

```yaml
stremio:
  enabled: true
  # token: ""            # generated and kept in data/stremio-token when empty
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_KEY
    - name: second-indexer
      url: https://second-indexer.example
      api_key: YOUR_KEY
      api_path: /api/v1/api   # for an indexer that 404s the default /api
```

Alles findest du auf der Konfigurationsseite unter **Stremio Addon**: den Schalter, die Indexer-Liste und das Limit für die Ergebnisse. Dort wird auch die Addon-URL angezeigt, mit einem Kopieren-Button. Sie wird aus der Adresse gebaut, unter der du das Dashboard geöffnet hast. Genau diese Adresse solltest du verwenden, siehe [Installation auf einem anderen Gerät](#installing-it-on-another-device).

Beim Start schreibt zurg die Addon-URL ins Log:

```
<zurg>/stremio/<token>/manifest.json
```

Füge sie in Stremio ein (unter Addons nimmt das Suchfeld eine URL entgegen). Das Token im Pfad ist die komplette Autorisierung. Stremio-Clients schicken keine eigene Authentifizierung mit. Deshalb liegen die Routen außerhalb der Basic Auth, genau wie der SABnzbd-Endpoint. Behandle die URL wie ein Passwort. Die Abspiel-Links, die sie erzeugt, enthalten deine Indexer-API-Keys, und wer die URL hat, kann deine Indexer-Grabs und deine Newsserver-Verbindungen nutzen.

## Installation auf einem anderen Gerät {#installing-it-on-another-device}

Stremio akzeptiert ein Addon nur über einfaches `http` auf dem Computer, auf dem Stremio selbst läuft.
Das heißt `http://127.0.0.1` oder `http://localhost` auf dem zurg-Rechner.
Überall sonst braucht es `https`. Ein Fernseher, ein Handy oder ein zweiter Computer zeigt
**failed to load manifest** bei einer `http://`-Adresse an, auch wenn er zurg problemlos erreichen kann.
Das gilt auch für eine LAN-Adresse und eine Tailscale-Adresse. Die Konfigurationsseite
sagt das direkt neben der Addon-URL, wenn du sie über einfaches `http` auf so einer
Adresse geöffnet hast.

zurg liefert selbst kein `https` aus. Stell davor etwas, das das übernimmt.
Öffne dann die Konfigurationsseite über die `https`-Adresse und kopiere die Addon-URL von dort.
zurg baut die Addon-URL und jeden Play-Link aus der Adresse, über die jede Anfrage ankam.
Es gibt keine Einstellung für eine öffentliche URL, und `base_url` wird hier nicht benutzt.
Ein zurg kann gleichzeitig einen Player im LAN und einen von unterwegs bedienen.

Was davor sitzt, muss zurg zwei Dinge sagen. Der Name kommt aus dem
`Host`-Header oder aus `X-Forwarded-Host`. Das Schema kommt aus
`X-Forwarded-Proto: https`. Ohne diesen Header lädt das Addon zwar, aber die Play-
Links kommen als `http://` zurück und die Wiedergabe schlägt fehl. Jede der folgenden Optionen schickt
beides.

Stremio nutzt zwei Pfade. `/stremio/` ist das Addon. `/strm/e/` ist der Ort, an den beim Drücken von
Play der Player für das Video geschickt wird. Beide funktionieren ohne zurgs Passwort, weil
Stremio keines senden kann. Das Token in der Addon-URL schützt sie. Wenn
zurg ins Internet geht, veröffentliche nur diese beiden Pfade. Alles andere ist dein
Dashboard und deine Bibliothek.

### Tailscale Serve

Die einfachste Option, wenn jedes Gerät, auf dem Stremio läuft, Tailscale ausführen kann. zurg bleibt vom Internet getrennt.

1. Schalte in der Tailscale-Admin-Konsole MagicDNS und HTTPS-Zertifikate ein.
2. Führe dies auf dem Rechner aus, auf dem zurg läuft. Nutze deinen eigenen Port, falls zurg nicht auf 9999 läuft.

   ```bash
   tailscale serve --bg 9999
   ```

   Unter Windows führst du den gleichen Befehl in PowerShell aus. Wenn er "access denied" meldet, öffne PowerShell als Administrator und versuche es dort erneut.
   Unter Linux setzt du `sudo` davor, es sei denn, du hast dich selbst als Tailscale-Operator eingetragen (`sudo tailscale set --operator=$USER`). Unter macOS ist, falls `tailscale` nicht gefunden wird, die eigene Kopie der Tailscale-App `/Applications/Tailscale.app/Contents/MacOS/Tailscale`.
3. Öffne `https://<machine>.<tailnet>.ts.net/config/` und kopiere die Addon-URL aus der Karte **Stremio Addon**.

Tailscale holt sich das Zertifikat und schickt beide Header. `tailscale serve reset` schaltet es wieder ab.

Ein Gerät, das Tailscale nicht ausführen kann, kann stattdessen Tailscale Funnel nutzen. Damit wird dieselbe Adresse im Internet veröffentlicht. Veröffentliche nur, was Stremio braucht.

```bash
tailscale funnel --bg --set-path /stremio http://127.0.0.1:9999/stremio
tailscale funnel --bg --set-path /strm/e http://127.0.0.1:9999/strm/e
```

Die Config-Seite ist unter dieser Adresse nicht erreichbar. Kopiere die Addon-URL von der Seite, so wie du sie normal öffnest, und ersetze den Anfang durch `https://<machine>.<tailnet>.ts.net`. Tailscale begrenzt die Bandbreite, die ein Funnel bekommt. Ein 4K-Remux kann ruckeln.

### Dein eigener Reverse Proxy {#your-own-reverse-proxy}

Schon einen Reverse Proxy mit einer Domain und einem Zertifikat am Laufen? Dann füg zurg einfach dort hinzu.
Caddy behält den `Host`-Header bei und schickt `X-Forwarded-Proto` selbst mit.
Damit werden nur die zwei Stremio-Pfade veröffentlicht, sonst nichts.

```
zurg.example.com {
    handle /stremio/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle /strm/e/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle {
        respond 404
    }
}
```

nginx schickt keinen der beiden Header, außer du forderst beide ausdrücklich an.

```nginx
location ~ ^/(stremio|strm/e)/ {
    proxy_pass http://127.0.0.1:9999;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
}
```

Setz das in den `server`-Block, der bereits auf 443 mit deinem Zertifikat lauscht. `proxy_buffering off` sorgt dafür, dass der Videostream direkt durchgeleitet wird und nicht über die Puffer von nginx läuft.

### Cloudflare Tunnel

Ein benannter Tunnel gibt zurg eine `https`-Adresse auf einer Domain, die du bei Cloudflare hast, ohne dass du einen Port öffnen musst. Cloudflare behält den `Host`-Header bei und setzt `X-Forwarded-Proto` selbst. Leite in der `config.yml` des Tunnels nur die Stremio-Pfade weiter.

```yaml
ingress:
  - hostname: zurg.example.com
    path: ^/(stremio|strm/e)/
    service: http://127.0.0.1:9999
  - service: http_status:404
```

Zwei Dinge solltest du vorher wissen. Cloudflare bricht eine Anfrage nach 100 Sekunden ab. Der erste Start eines Releases kann länger dauern. Drück einfach nochmal auf Play, dann läuft es. Und die Nutzungsbedingungen von Cloudflare erlauben, dass Konten eingeschränkt werden, die ohne bezahlten Tarif viel Video über ihr Netz schicken. Jeder Play-Vorgang läuft durch den Tunnel.

## Was ein Play macht {#what-a-play-does}

Einen Stream auszuwählen ist ein Grab: zurg lädt die NZB vom Indexer herunter und legt sie in `nzbs/` ab (über dieselben Namensregeln wie der SABnzbd-Endpoint, sodass ein Release, das zweimal gegrabbt wurde, oder schon von einem *arr gegrabbt wurde, gefunden und nicht doppelt angelegt wird), wartet, bis die Bibliothek es auflistet, und leitet den Player in den signierten `/strm/e/`-Endpoint weiter, über den jede `.strm`-Datei ohnehin abgespielt wird: Range-Lesevorgänge, Konto-Failover, RAR/7z-Archivinhalte.

Der erste Abruf eines Releases dauert deshalb länger als ein Debrid-Stream. Die NZB muss geladen und geparst werden, und dann kommt noch das Lesen eines Archivinhalts dazu. Meist sind es ein paar Sekunden, bei einem verschleierten Post, dessen Namensprüfung laufen muss, auch eine bis zwei Minuten. Dauert ein Abspielvorgang länger als die Wartezeit, antwortet zurg mit 503 und einem Retry-After. Drückst du erneut auf Play, landest du auf dem schnellen Pfad. Jeder weitere Abruf ist sofort da.

Ein Release, das gelistet wird und sich dann als nichts Abspielbares herausstellt (meist, weil es aus dem Spool gefallen ist und der News-Server-Check jede Datei als defekt markiert hat), ist noch nicht das Ende des Klicks. Die Play-URL trägt die Anfrage, für die sie erstellt wurde. zurg ordnet deshalb die Releases des Titels neu ein und probiert die Zeilen nach dem gewählten durch, jede über denselben Grab-and-List-Pfad. Das erste, das abspielt, ist das, wohin der Player weitergeleitet wird. Dabei geht zurg die ganze Antwort durch und nicht nur die Zeilen, die die Liste angezeigt hat. `max_results` ist, wie viel jemand scrollen möchte. Würde es auch die Wiederherstellung begrenzen, könnte ein Titel, der zehn Zeilen tief angezeigt wird, nur neun probieren, egal wie viel die Suche schon gefunden hat.

Die Zeilen *nach* der Auswahl sind Absicht: Sie haben dieselbe Auflösung und sind kleiner, oder sie haben die Auflösung darunter. Ein größeres Release, das der Nutzer übergangen hat, wird nie probiert. Ein Fallback, der selbst noch ingestet, antwortet mit demselben 503. Erneutes Drücken auf Play löst ihn auf: Das abgelehnte Release wird sofort abgelehnt, und der Fallback wird auf dem schnellen Pfad gefunden. Nur diese letzte Ablehnung wird weitergereicht, ein 503 nie.

Jeder Versuch verbraucht einen Indexer-Grab und hinterlässt sein Release in der Bibliothek wie jeder andere Grab. Deshalb ist die Kette begrenzt: durch ein Budget von fünfundzwanzig Sekunden und eine Obergrenze von sechs Versuchen. Das Budget ist die Bremse, weil die Versuche nicht gleich viel kosten. Ein Release, das aus dem Spool gefallen ist, wird in unter einer Sekunde abgelehnt. Eines, das ingestet und ein Archiv öffnet, bevor es sich als leer herausstellt, kann dagegen fast das ganze Budget allein aufbrauchen. Wenn jede probierte Zeile abgelehnt wird, lautet die Antwort wie bisher 404. Jeder Fallback wird mit info protokolliert, mit dem abgelehnten Release und dem Release, das als Nächstes probiert wird.

Gemessen wurde am 7. September 2026 gegen drei andere Usenet-basierte Stremio-Addons: stremio-addon-findings-2026-09-07.md.
Kurz gesagt: Die Obergrenze pro Auflösung hat behoben, was die letzte Runde gefunden hatte, aber die Abdeckung hat sich trotzdem halbiert. Eine Gruppe mit fünf Einträgen kann nirgendwo ausweichen, wenn ihr erster abspielbarer Eintrag ein Release ist, das aus dem Spool gefallen ist. Der oben beschriebene Fallback ist der erste Fix aus dieser Runde. Die Gruppe ist inzwischen von fünf auf zehn gewachsen.

## Suchverhalten {#search-behaviour}

- Filme suchen mit `t=movie`, Episoden mit `t=tvsearch` und `season`/`ep`, beides über
  `imdbid` — als reine Ziffern, weil mehrere Indexer bei der `tt`-Form null Ergebnisse liefern.
- Jeder Indexer wird nach `search_limit` Releases gefragt (Standard 100). Jede Grenze unten
  wählt aus dem, was so angefordert wurde, also ist sie die Obergrenze der Antwort.
- Indexer werden parallel durchsucht. Lehnt einer ab (ein Burst-Limit, ein toter Key), kostet
  das nur dessen Ergebnisse, nicht die ganze Liste. Ablehnungen werden pro Indexer geloggt.
- Ergebnisse werden nach Releasenamen dedupliziert, zuerst nach Auflösung und dann nach Größe
  sortiert und pro Auflösung auf `max_results` (Standard 10) begrenzt. Das Limit zählt pro
  Auflösung, weil die Sortierung mit 2160p beginnt: Ein beliebter Titel hat mehr UHD-Releases
  unter der Größenobergrenze als jedes Limit. Würde man über die ganze Liste zählen, bekäme jeder
  beliebte Titel nur Remuxes als Antwort, egal was die Suche sonst gefunden hat.
- Was jede Auflösung behält, ist eine Verteilung ihrer Größen, nicht ihre größten paar:
  gleichmäßig verteilte Auswahl vom größten bis zum kleinsten Release, wobei beide immer
  dabei sind. Von oben behalten, wären fünf 1080p-Einträge fünf Remuxes zwischen 19 und 30 GB,
  und das 4-GB-Encode, das ein Handy oder ein Laptop direkt abspielt, würde genau durch das
  Limit entfernt. Gemessen am 7. September 2026: drei von zurgs fünfzehn Einträgen für
  The Shawshank Redemption waren unter 6 GB, gegenüber vierzig solchen Releases auf denselben
  Indexern. Die Liste bleibt innerhalb einer Auflösung größenabsteigend. Ein Release, dessen
  Größe der Indexer nicht angegeben hat, hat auf dieser Achse keinen Platz; es füllt nur den
  Raum, den die Releases mit Größe übrig lassen.
- Die Beschreibung jedes Streams enthält den Releasenamen, seine Größe, den Indexer, der ihn
  gefunden hat, und wie lange er schon gepostet ist — `3d`, `126d`, `2y` — wenn der Indexer
  das angegeben hat. Die Alterung auf dem Newsserver war der häufigste Grund für fehlgeschlagene
  Wiedergaben in der Runde vom 7. September, und das Veröffentlichungsdatum ist das einzige
  Signal, mit dem ein Zuschauer ihr ausweichen kann.
- Releases, die größer als `max_size_gb` sind, werden vor dem Ranking verworfen, für einen Player,
  der keinen Remux schafft. Standardmäßig gibt es keine Grenze: Die Verteilung oben listet
  ohnehin das kleinste Release jeder Auflösung neben ihren Remuxes. Größen, die der Indexer nicht
  angegeben hat, bleiben erhalten. Die Grenze wird beim Rendern der Liste angewendet, daher wirkt
  eine Änderung der Obergrenze auch auf gecachte Titel.
- Ergebnisse werden auf der Festplatte gecacht (`data/stremio-cache/`, eine Datei pro Titel), damit
  das erneute Öffnen eines Titels keine Indexer-Anfragen kostet. Die sind oft tageskontingentiert,
  und Treasure Maps lehnt nach etwa sechs schnellen ab. Wie lange eine Antwort lebt, richtet sich
  danach, wie viel die Suche gefunden hat, denn eine dünne Liste ist ein Hinweis, dass die Uploads
  noch eintreffen oder ein Indexer ausgefallen war: Ein Ergebnis lebt eine Stunde, zwei leben zwei,
  bis zu vier. Fünf oder mehr sind eine abgeschlossene Antwort und leben `cache_hours`
  (Standard 24, die einzige konfigurierbare Stufe). Eine leere Antwort wird nie gecacht. Eine
  gecachte Stream-Liste trägt unten einen **refresh**-Eintrag, der sagt, wie alt sie ist. Wird
  dieser Eintrag geöffnet (er öffnet sich im Browser, nicht im Player), wird der Cache für diesen
  Titel geleert, und beim erneuten Öffnen des Titels wird frisch gesucht. Der Cache übersteht
  Neustarts, und abgelaufene Einträge räumen sich selbst auf.
- Staffel 0 (Specials) wird abgelehnt, statt falsch gesucht zu werden. Die ID-Suche deckt nur
  ab, was der Indexer kennt: Ein Release, das ein Indexer nur über die Textsuche findet, taucht
  nicht auf.
