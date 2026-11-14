# Eine Real-Debrid-Bibliothek in Plex mit zurg {#a-real-debrid-library-in-plex-with-zurg}

Zurg zeigt alles, was in deinem Real-Debrid-Konto liegt, als Ordner auf deinem Computer an, bereits sortiert in `movies` und `shows`. Füg diese beiden Ordner zu Plex Media Server hinzu, und deine gesamte Real-Debrid-Bibliothek lässt sich in jeder Plex-App abspielen, gestreamt von Real-Debrid, ohne dass vorher etwas heruntergeladen werden muss. Zurg installierst du einmal; es bringt seinen eigenen rclone mit, du musst also nichts weiter einrichten.

Du willst lieber keinen Plex Media Server oder kein eingebundenes Laufwerk betreiben? [rex mit zurg](../rex/with-zurg.md) zeigt dir dieselbe Bibliothek für die Plex-Apps, ohne dass eines von beidem nötig ist.

## Was du brauchst {#what-you-need}

- **Ein Sponsoring.** Die nightly-Version von zurg ist für Sponsoren gedacht. Werde über [gatekeeper](https://gatekeeper.debridmediamanager.com/) Sponsor, dann bekommt dein GitHub-Konto Zugriff auf den Download. [Was ein Sponsoring bringt](sponsorship.md) erklärt den Rest.
- **Ein Real-Debrid-Premium-Konto** und dessen API-Token: [Dein Real-Debrid-API-Token](real-debrid-api-token.md) zeigt dir, wo du ihn findest.
- **Plex Media Server auf demselben Computer wie zurg.** Plex liest die Dateien aus den Ordnern von zurg, deshalb muss es sie sehen können. Danach kann jede Plex-App etwas abspielen.
- **Ein Computer, der eingeschaltet bleibt**: Windows 10 oder 11, Linux, ein Mac oder ein Linux-Rechner mit Docker.

## 1. zurg installieren {#1-install-zurg}

Jede Einrichtungsseite beginnt mit einem einzeiligen Installer. Wenn dort `Choose one or more providers in priority order:` steht, tippst du `1` für Real-Debrid ein und fügst danach dein Token ein.

| Dein Computer | Installation mit | Deine Bibliothek erscheint unter |
|---|---|---|
| Windows | [zurg unter Windows](../zurg/setup/windows.md) | `Z:\movies` und `Z:\shows` |
| Linux | [zurg unter Linux](../zurg/setup/linux.md) | `/mnt/zurg/movies` und `/mnt/zurg/shows` |
| Mac | [zurg unter macOS](../zurg/setup/macos.md) | `/Volumes/Zurg/movies` und `/Volumes/Zurg/shows` |
| Linux mit Docker | [Eine Docker-Compose-Datei](../zurg/guides/docker-compose.md), die Plex Media Server neben zurg ausführt | `/zurg_mnt/zurg/movies` und `/zurg_mnt/zurg/shows` |

Der Installer endet mit `zurg doctor`, einer Liste von `PASS`-Zeilen.

## 2. Ordner prüfen {#2-check-the-folders}

Öffne den Drive- oder Ordner von zurg. Du solltest `movies`, `shows`, `__all__`, `__downloads__`, `__unplayable__` und `version.txt` sehen.

Beim ersten Start liest zurg dein gesamtes Real-Debrid-Konto ein. Bis das fertig ist, bleiben die Ordner leer. Zum Prüfen öffnest du `http://localhost:9999/ready` im Browser: Dort steht `ready`, sobald deine Bibliothek eingelesen ist.

## 3. Ordner in Plex hinzufügen {#3-add-the-folders-in-plex}

In Plex Web drückst du **Add Library**, den Button neben dem Namen deines Servers in der Seitenleiste:

1. Wähle **Movies** und drücke **Next**.
2. Drücke **Browse for media folder** und wähle den Ordner `movies` von zurg aus der Tabelle oben, zum Beispiel `Z:\movies` unter Windows.
3. Drücke **Add Library**.

Mach dasselbe mit **TV Shows** und dem Ordner `shows`. Plex scannt dann beide und ergänzt Poster und Titel.

## 4. zurg Plex über neue Inhalte informieren lassen {#4-let-zurg-tell-plex-about-new-things}

Plex merkt nicht, wenn etwas Neues in deinem Real-Debrid-Konto landet. zurg kann es ihm sagen. Öffne das Dashboard von zurg unter `http://localhost:9999/config/`, geh zu **Media Server Integration** und drück auf **Login with Plex**. Melde dich bei Plex an und wähle deinen Server aus.

![The Media Server Integration section of zurg's dashboard, with the Login with Plex button](../assets/real-debrid-plex/01-zurg-login-with-plex.webp)

Ab dann bittet zurg Plex, jeden Ordner zu scannen, der sich ändert. Außerdem schaltet es ein paar Plex-Einstellungen ab, die bei einer gestreamten Bibliothek riskant sind, zum Beispiel **Empty trash automatically after every scan**: [Empfohlene Plex-Einstellungen](../zurg/guides/plex.md#recommended-plex-settings) listet sie auf.

## Wenn etwas nicht stimmt {#when-something-is-wrong}

| Was du siehst | Was zu tun ist |
|---|---|
| Plex findet nichts, oder zurgs Ordner sind leer | zurg liest dein Konto noch. Warte, bis `http://localhost:9999/ready` `ready` anzeigt, und scanne dann in Plex erneut. |
| Unter Windows gibt es kein `Z:`-Laufwerk, oder Plex findet `Z:\movies` nicht | `Z:` gehört zu deiner Windows-Desktop-Sitzung, und zurgs Installer startet zurg dort, wenn du dich anmeldest. Eine als Administrator geöffnete PowerShell sieht es auch nicht. [Wenn auf Windows etwas nicht stimmt](../zurg/setup/windows.md#when-something-is-wrong) erklärt jeden Fall. |
| Unter Linux sieht Plex einen leeren Ordner oder kann ihn nicht öffnen, und `./zurg doctor` meldet `user_allow_other is not enabled in /etc/fuse.conf; the mount will be visible only to the zurg service user` | Plex läuft als anderer Benutzer als zurg. Lass andere Benutzer mit <code>echo user_allow_other &#124; sudo tee -a /etc/fuse.conf</code> zu, und führe dann `./zurg service restart` im zurg-Ordner aus. |
| In Docker werden Plex-Bibliotheken leer, nachdem zurg neu gestartet wurde, und `docker exec plex ls /zurg_mnt/zurg` meldet `Transport endpoint is not connected` | Gib dem Plex-Container zurgs Ordner mit `rslave`: `/zurg_mnt:/zurg_mnt:rslave`. [Eine Docker-Compose-Datei](../zurg/guides/docker-compose.md) enthält das. |
| Neue Inhalte erscheinen in zurgs Ordnern, aber nicht in Plex | Mach Schritt 4. Drück bis dahin in Plex bei der Bibliothek auf **Scan Library Files**. |
| zurg meldet `bad_token` | Das Real-Debrid-Token ist falsch oder abgeschnitten. [Dein Real-Debrid-API-Token](real-debrid-api-token.md#when-something-is-wrong) zeigt die Lösung. |
| Deine Festplatte läuft voll | zurg speichert eine Kopie von dem, was du abspielst, standardmäßig bis zu 256G. Wie du das begrenzt, zeigen [Cache klein halten](../zurg/setup/windows.md#keeping-the-cache-small) (Windows) bzw. [Festplattenplatz, den der Mount nutzt](../zurg/setup/linux.md#disk-the-mount-uses) (Linux). |

Immer noch nicht weitergekommen? Frag im Forum **zurg-support** auf [Discord](https://discord.com/invite/7u4YjMThXP). [Hilfe bekommen](remote-help.md) sagt, was du angeben solltest.

## Fragen {#questions}

### Gibt es eine Anleitung, um DMM, zurg und rclone einzurichten, damit du in Plex streamen kannst? {#is-there-a-guide-to-set-up-dmm-zurg-and-rclone-to-stream-in-plex}

Diese Seite. Du richtest rclone nicht selbst ein: Das Installationsprogramm von zurg lädt es herunter, und zurg startet es. DMM ist der Ort, an dem du Releases findest und sie zu deinem Real-Debrid-Konto hinzufügst ([Was DMM ist und wie du es benutzt](../dmm/index.md)). zurg zeigt sie dann in seinen Ordnern an, und Plex übernimmt sie.

### Werden die Filme auf meinen Computer heruntergeladen? {#do-the-movies-download-to-my-computer}

Nein. Plex liest jede Datei von Real-Debrid über zurg, wenn du auf Play drückst. zurg legt zwar einen Cache für alles an, was abgespielt wurde, und der kann ziemlich groß werden: siehe die Zeile Disk oben.

### Kann ich Plex Media Server auslassen? {#can-i-skip-plex-media-server}

Ja, mit rex. [rex mit zurg](../rex/with-zurg.md) zeigt deine zurg-Bibliothek in den Plex-Apps, ohne Plex Media Server und ohne Mount. Du kannst auch beides laufen lassen: [Eine Docker-Compose-Datei](../zurg/guides/docker-compose.md) startet zurg, Plex Media Server und rex auf einer Maschine.

### Funktioniert es auch mit TorBox oder Usenet? {#does-it-work-with-torbox-or-usenet-too}

Ja. Das Installationsprogramm von zurg bietet außerdem TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud und Usenet an und legt alle in denselben Ordnern `movies` und `shows` ab. Für jeden Anbieter gibt es eine eigene Seite unter [Anbieter](../zurg/providers/index.md).
