# Seerr über DMM {#seerr-through-dmm}

Füge DMM zu [Seerr](https://github.com/seerr-team/seerr) als Radarr und Sonarr hinzu. Genehmigte Anfragen
landen auf deiner [DMM-Wunschliste](../zurg/guides/dmm-wanted.md), damit zurg sie abholt. Du brauchst
kein Radarr oder Sonarr. Seerr muss nur debridmediamanager.com erreichen. Overseerr und Jellyseerr funktionieren
genauso.

Das ist für Sponsoren. Seerr meldet sich mit dem DMM-API-Schlüssel von [gatekeeper](https://gatekeeper.debridmediamanager.com/) an.

## Was du brauchst {#what-you-need}

- zurg liest deine Wunschliste mit `dmm_api_key` in `config.yml`. Siehe [Fetch what you want from DMM](../zurg/guides/dmm-wanted.md#what-you-need).
- Seerr ist mit deinem Plex-, Jellyfin- oder Emby-Server eingerichtet, damit es weiß, welche Episoden du hast.

## DMM als Radarr hinzufügen {#add-dmm-as-radarr}

In Seerr, öffne **Settings → Services** und drücke **Add Radarr Server**. Trag es so ein:

| Field | Value |
|---|---|
| Default Server | ticked |
| 4K Server | unticked |
| Server Name | `DMM`, or any name |
| Hostname or IP Address | `debridmediamanager.com` |
| Port | `443` |
| Use SSL | ticked |
| API Key | your DMM API key |
| URL Base | `/api/arr/radarr` |

Drück **Test**. Wenn die Verbindung klappt, wähl bei Quality Profile **Any** und bei Root Folder **/dmm**.
Lass Minimum Availability, wie es ist. Setz den Haken bei **Enable Scan** und drück **Add Server**.

![Seerr's Add Radarr Server dialog filled in for DMM](../assets/seerr-dmm/01-seerr-radarr-dmm.webp)

Wenn Test fehlschlägt, prüf den Key: Er steht auf DMMs [Settings](https://debridmediamanager.com/settings)-Seite. DMM lehnt ihn außerdem ab, sobald dein Sponsoring abgelaufen ist.

## DMM als Sonarr hinzufügen {#add-dmm-as-sonarr}

Klick auf **Add Sonarr Server** und trage als URL Base `/api/arr/sonarr` ein. Nach **Test** wählst du bei Profiles und Root Folders für beide **Any** und `/dmm`. Setze den Haken bei **Enable Scan** und klick auf **Add Server**.

![Seerr's Add Sonarr Server dialog filled in for DMM](../assets/seerr-dmm/02-seerr-sonarr-dmm.webp)

## Anfragen stellen {#requesting}

Stelle eine Anfrage wie gewohnt. Ein genehmigter Film landet auf deiner Wunschliste:

![Einen Film in Seerr anfragen](../assets/seerr-dmm/03-seerr-request-movie.webp)

![Der Film wird als angefragt angezeigt](../assets/seerr-dmm/04-seerr-movie-requested.webp)

Bei einer Serie wählst du die gewünschten Staffeln aus. Eine spätere Anfrage kann weitere Staffeln hinzufügen. Um der ganzen Serie inklusive neuer Staffeln zu folgen, drücke auf **Want all seasons** auf ihrer DMM-Seite.

![Staffeln einer Serie auswählen](../assets/seerr-dmm/05-seerr-request-seasons.webp)

Deine [Wunschliste](https://debridmediamanager.com/wanted) zeigt jeden Titel innerhalb von Sekunden an. zurg
holt ihn innerhalb einer Minute ab.

## Was Seerr anzeigt {#what-seerr-shows}

Seerr liest die Liste von DMM einmal am Tag in **Radarr Scan** und **Sonarr Scan**. Um sie jetzt auszuführen, öffne **Settings → Jobs & Cache** und drücke neben jedem **Run Now**.

- **Ein Film**, den zurg geholt hat, wird als **Available** angezeigt.

  ![A fetched film shows as available](../assets/seerr-dmm/06-seerr-movie-available.webp)

- **Eine Serie** bleibt auf **Processing**, bis ihre Episoden in deiner Plex-, Jellyfin- oder Emby-Bibliothek ankommen und der Scan von Seerr auf diesem Server sie findet. DMM weiß nicht, welche Episoden zurg hat.

## Einen Titel entfernen {#removing-a-title}

Öffne den Titel in Seerr, drück auf den Zahnrad-Button und dann auf **Remove from Radarr** (oder **Remove from Sonarr**). Damit wird er von deiner Wunschliste entfernt. Was zurg schon geholt hat, bleibt in deiner Bibliothek. **Open in Radarr** daneben öffnet den Titel auf DMM.

Hängst du fest? Frag im Forum **dmm-support** auf [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) erklärt, was du angeben solltest.

## Seerr über DMM oder zurgs eigene Seerr-Quelle {#seerr-through-dmm-or-zurgs-own-seerr-source}

zurg kann Seerr auch direkt auslesen, mit einer [`seerr`-Quelle](../zurg/guides/acquisition.md#configuration).
Nutze eines von beiden, nicht beides:

- **Über DMM** muss Seerr nur das Internet erreichen. Die Anfragen erscheinen auf deiner Wunschliste neben dem, was du mit **Want** hinzugefügt hast, und der tägliche Scan von Seerr markiert die Filme, die zurg geholt hat, als verfügbar.
- **Die eigene Quelle von zurg** unterscheidet eine 4K-Anfrage von einer 1080p-Anfrage, aber zurg muss Seerr erreichen können.
