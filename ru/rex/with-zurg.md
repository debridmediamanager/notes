# rex с zurg {#rex-with-zurg}

[rex](https://rex.debridmediamanager.com/ru/) — это медиасервер для официальных приложений Plex, который не хранит никаких файлов. Официальные приложения Plex видят его как обычный сервер Plex. Наполнить его можно любым приложением ([rex с вашим приложением](any-source.md)); эта страница настраивает его вместе с zurg, который передаёт ему вашу библиотеку debrid, а при нажатии на «Воспроизвести» rex стримит файл напрямую из zurg. Ничего не скачивается заранее.

Эта страница проведёт вас от нуля до просмотра фильма, шаг за шагом. В каждом шаге описано, что он делает, зачем он нужен и что вы должны увидеть, прежде чем перейти дальше. Если увиденное не совпадает с описанием, остановитесь: следующий шаг это не исправит.

![zurg регистрируется в rex и передаёт ему библиотеку; приложения Plex воспроизводят через rex, который читает каждый файл из zurg](../assets/rex/how-it-fits.svg)

Четыре вещи, которые нужно знать перед стартом:

- **zurg — это часть, которая общается с вашим сервисом debrid.** Он составляет список того, что есть в вашем аккаунте, и отдаёт файлы.
- **rex — это часть, с которой общаются ваши приложения Plex.** Он не хранит файлы и не нуждается в диске для медиа. Ему не нужны rclone или монтирование.
- **zurg сам сообщает rex о себе.** Вы даёте zurg адрес rex, а дальше zurg всё делает сам. Данные zurg вводить в rex не нужно.
- **zurg и DMM определяют, что за файл; Plex его описывает.** zurg спрашивает DMM, какой это фильм или эпизод, а rex показывает это название с постерами и описаниями из собственных метаданных Plex, как только rex подключён к аккаунту Plex. rex никогда не угадывает по имени файла.

rex бесплатен для личного использования (PolyForm Noncommercial): нет спонсорского уровня и не нужен аккаунт, чтобы его скачать. Ночная сборка zurg, которую использует это руководство, остаётся спонсорским релизом; [rex с вашим приложением](any-source.md) запускает rex без неё. Есть только телефон или ТВ-приставка? zurg+rex, сервер Plex на вашем телефоне, запускает zurg и rex вместе прямо на нём: см. [руководство для Android](../zurg/guides/android.md).

## Перед началом {#before-you-start}

| Что нужно | Зачем |
|---|---|
| Машина, которая работает постоянно: Linux (Ubuntu 22.04 или новее), macOS или Windows (64-бит). Подойдёт Proxmox LXC, в том числе непривилегированный, если в нём включён FUSE (Options > Features > FUSE): установщик zurg без `/dev/fuse` останавливается | rex и zurg — это серверы: твои приложения Plex обращаются к ним каждый раз, когда ты нажимаешь «играть». Там, где команды отличаются, у шага есть вкладка для каждой системы. [Docker](#run-rex-in-docker) описан ниже, для Linux |
| 1 ГБ оперативной памяти | При 4,062 фильмах и 656 сериалах (34,678 серий) rex использовал меньше 500 МБ при запуске и около 730 МБ при просмотре библиотеки; конвертация видео требует больше. zurg нужно мало |
| Аккаунт debrid (Real-Debrid, TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud) или Usenet | Именно там на самом деле хранятся твои фильмы и сериалы |
| Аккаунт GitHub с доступом к спонсорским релизам zurg | Ночная сборка zurg — это приватный релиз GitHub. [gatekeeper](https://gatekeeper.debridmediamanager.com/) открывает доступ твоему аккаунту, когда ты становишься спонсором. Установщик zurg входит в аккаунт один раз |
| Твой API-ключ DMM, который выдаёт [gatekeeper](https://gatekeeper.debridmediamanager.com/) после спонсорства (необязательно) | zurg спрашивает у DMM, что это за файл. Без ключа zurg определяет это по названию релиза через бесплатный поиск по названиям DMM: совпадает меньше тайтлов, а аниме с нумерацией по всей серии остаётся в порядке файлов |
| Новый аккаунт Plex, созданный специально для rex | rex берёт все названия, постеры, описания и названия серий из Plex, когда он [добавлен в аккаунт Plex](#step-3-add-it-to-a-plex-account). До этого названия остаются именами файлов, и постеров нет |

Эта страница требует ночную сборку rex **2026.10.25 или новее** и ночную сборку zurg **2026.10.27 или новее**.

## Шаг 1. Установите zurg {#step-1-install-zurg}

**Что делает.** Скачивает zurg, спрашивает данные твоего debrid-аккаунта и запускает zurg как службу, которая поднимется после перезагрузки.

**Почему это важно.** Всё, что показывает rex, берётся из zurg. Если zurg не видит твою библиотеку, rex её тоже не увидит.

**На Windows и macOS ставь zurg установщиком ниже, а не в Docker Desktop.** rex читает каждый файл по адресу, который ему даёт zurg, а до zurg внутри Docker Desktop он не достучится: тайтлы появятся, а воспроизводиться ничего не будет.

+++ Linux
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
sudo loginctl enable-linger "$USER"
```

zurg окажется в `~/zurg`. Вторая строка оставит твои службы запущенными после выхода из системы.
+++ macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

zurg окажется в `~/zurg`. Установщик также ставит macFUSE, и macOS может попросить разрешить его в **System Settings**, **Privacy & Security**, а потом перезагрузиться: [zurg на macOS](../zurg/setup/macos.md).
+++ Windows
В PowerShell:

```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```

zurg окажется в `$HOME\zurg` (`C:\Users\you\zurg`). Установщик также ставит WinFsp, запрашивая подтверждение администратора, и запускает zurg при каждом входе в Windows: [zurg на Windows](../zurg/setup/windows.md).
+++

Установщик спросит, какими сервисами ты пользуешься (введи `1` для Real-Debrid), а потом попросит API-токен. Токен скрыт, пока ты его вставляешь.

**Что должно появиться.** Установщик завершится списком строк `PASS` и строкой `==> zurg is installed in` с папкой zurg. Потом zurg загрузит твою библиотеку: несколько секунд для небольшого аккаунта и около десяти минут для аккаунта с тысячей релизов на Real-Debrid. Открой панель zurg по адресу `http://<this machine>:9999`: когда загрузка закончится, **Library Size** покажет количество твоих элементов.

Уже запускал zurg? Обнови и перезапусти его командой `cd ~/zurg && ./zurg update && ./zurg service restart` (на Windows: `cd $HOME\zurg; .\zurg.exe update; .\zurg.exe service restart`).

## Шаг 2. Установите rex {#step-2-install-rex}

**Что это делает.** Скачивает rex в `~/rex` (на Windows `$HOME\rex`) и запускает его как службу со всем, что нужно для следующих шагов. Следующим шагам перезапуск не нужен. Перезапуск понадобится только в необязательных разделах ниже.

**Почему это важно.** rex — это то, с чем разговаривают ваши приложения Plex. При первом запуске создаётся `rex.db`, в котором хранятся ваши библиотеки, всё, что присылает zurg, и история просмотров.

На Linux можно запустить zurg и rex в Docker: см. [Запуск rex в Docker](#run-rex-in-docker).

+++ Linux and macOS
```bash
mkdir -p ~/rex && cd ~/rex
TAG=$(curl -fsSL 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1' | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
P=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -fL "https://github.com/debridmediamanager/rex/releases/download/$TAG/rex-$TAG-$P.tar.gz" | tar xz --strip-components=1
```
+++ Windows
В PowerShell:

```powershell
New-Item -ItemType Directory -Force $HOME\rex | Out-Null; cd $HOME\rex
$tag = (Invoke-RestMethod 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1')[0].tag_name
curl.exe -fLO "https://github.com/debridmediamanager/rex/releases/download/$tag/rex-$tag-windows-amd64.zip"
tar -xf "rex-$tag-windows-amd64.zip" --strip-components=1; Remove-Item "rex-$tag-windows-amd64.zip"
```
+++

Скачивается самая новая сборка rex для вашей машины, обычно это nightly.

Узнайте LAN IP rex, то есть его адрес в домашней сети. На Linux `hostname -I` выводит несколько адресов: берите тот, что в вашей домашней сети, а не тот, что начинается с `172.17.` (Docker) или `100.` (Tailscale). На macOS его выводит `ipconfig getifaddr en0` (если вывод пустой, попробуйте `en1`). На Windows в `ipconfig` он указан как **IPv4 Address** в разделе вашего Wi-Fi или Ethernet адаптера. **На этой странице везде написано `192.168.1.20`: подставьте свой адрес.** По нему приложения Plex, zurg и ваши команды будут обращаться к rex.

**Plex Media Server работает на этой же машине?** Завершите команду запуска rex ниже параметром `--port 32500` и используйте `32500` везде, где в команде или настройке стоит `32400`, включая правило брандмауэра Windows. Plex уже занимает порт 32400 и порты, через которые приложения находят серверы, а на любом другом порту rex оставляет их Plex. Тогда в приложениях будут два сервера с именем машины: rex — это тот, что вам открыт, рядом с ним имя нового аккаунта. Когда rex будет привязан к своему аккаунту Plex ([шаг 3](#step-3-add-it-to-a-plex-account)), его можно переименовать: войдите в Plex под этим аккаунтом, откройте в rex **Settings**, **General**, поменяйте **Friendly name** и сохраните, затем перезапустите rex, как описано ниже. После перезапуска приложения Plex будут показывать его под новым именем.

Теперь сделаем из rex службу:

+++ Linux
Создайте `~/.config/systemd/user/rex.service`:

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/rex.service
```

```ini
[Unit]
Description=rex
After=network-online.target

[Service]
WorkingDirectory=%h/rex
EnvironmentFile=-%h/rex/rex.env
ExecStart=%h/rex/rex
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
journalctl --user -u rex -f
```

**Команда запуска** rex — это строка `ExecStart`, а ключи записываются в `~/rex/rex.env`, по одной строке `NAME=value`. После изменений перезапустить rex можно командой `systemctl --user daemon-reload && systemctl --user restart rex`. Лог rex смотрите командой `journalctl --user -u rex -f`.
+++ macOS
`run.sh` запускает rex в его папке, а LaunchAgent запускает `run.sh` при входе в систему:

```bash
cp ~/rex/examples/run.sh.example ~/rex/run.sh
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.rex.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.rex</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$HOME/rex/run.sh</string></array>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$HOME/rex/rex.log</string>
  <key>StandardErrorPath</key><string>$HOME/rex/rex.log</string>
</dict></plist>
PLIST
launchctl load ~/Library/LaunchAgents/com.rex.plist
tail -F ~/rex/rex.log
```

**Команда запуска** rex — это последняя строка `~/rex/run.sh`, а ключи записываются в `~/rex/rex.env`, по одной строке `NAME=value`. После изменений перезапустить rex можно командой `launchctl kickstart -k gui/$(id -u)/com.rex`. Лог смотрите командой `tail -f ~/rex/rex.log`.

rex работает, пока вы вошли в систему на Mac. Если Mac перезагружается сам, включите автоматический вход (**System Settings**, **Users & Groups**). Если включён брандмауэр macOS, разрешите rex, когда macOS спросит, или добавьте `~/rex/rex` в **Options** брандмауэра.
+++ Windows
Откройте PowerShell **от имени администратора** и перейдите в папку rex командой `cd $HOME\rex`. Сначала создайте `run.cmd`: он запускает rex в его папке и пишет лог в `rex.log`. Notepad предложит создать файл:

```powershell
notepad run.cmd
```

```bat
@echo off
cd /d "%~dp0"
rex.exe 2>> rex.log
```

Сохраните. Затем разрешите вашей сети проходить через Windows Firewall к порту rex и двум портам обнаружения, а потом запустите rex сейчас и при каждом входе в систему:

```powershell
New-NetFirewallRule -DisplayName rex -Protocol TCP -LocalPort 32400
New-NetFirewallRule -DisplayName "rex discovery" -Protocol UDP -LocalPort 32410,32414
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask rex -Action (New-ScheduledTaskAction -Execute "$HOME\rex\run.cmd") -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) -Settings $settings
Start-ScheduledTask rex; Start-Sleep 3
Get-Content rex.log -Wait
```

**Команда запуска** rex — это строка `rex.exe` в `run.cmd`, а ключи пишутся над ней, по одной строке `set NAME=value`. После изменений перезапустить rex можно командой `Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex`. Лог смотрите командой `Get-Content $HOME\rex\rex.log -Wait`.

Запустили rex вручную в PowerShell? Тогда лог есть только в этом окне, файла `rex.log` не будет, и после перезагрузки ничего его не запустит. rex хранит базу данных и привязку к аккаунту в папке, из которой запущен, поэтому rex, запущенный из другой папки, — это новый, непривязанный сервер. Остановите его через Ctrl+C и запустите снова из папки rex с теми же флагами или, что лучше, настройте задачу, описанную выше.

rex работает, пока вы вошли в Windows, в собственном окне: не закрывайте его. В PowerShell там, где на этой странице написано `curl`, вводите `curl.exe`: встроенный в Windows PowerShell `curl` — это другая команда.
+++

**Что вы должны увидеть.** Среди первых строк:

```
INFO    seeded rex.db: an empty library named yourhost, machine=...
INFO    no source yet: a source registers itself once pointed at this server (PUT /rex/sources/{name}, docs/feed-api.md)
INFO    claim state: unclaimed
INFO    rex on http://192.168.1.20:32400  machine=...  items=0  parts=proxy
```

rex называет себя по имени машины, и приложения Plex показывают это имя. `no source yet` — это нормально: zurg ещё не подключён к rex. Оставьте лог открытым.

## Шаг 3. Добавьте в аккаунт Plex {#step-3-add-it-to-a-plex-account}

**Что это делает.** Регистрирует rex в аккаунте Plex, как если бы это был настоящий Plex Media Server, и делает его доступным для вашего собственного аккаунта.

**Почему это важно.** rex получает название, постер, описание и названия эпизодов для каждого тайтла из собственных метаданных Plex, и запрашивать их он может только после того, как появится в аккаунте. Тайтлы, которые zurg отправил до регистрации, получат названия сразу, как только она пройдёт. Кроме того, это включает работу Fix Match, убирает уведомление «unclaimed» и нужно, если вы хотите [использовать rex вне дома](#use-it-outside-your-home-optional).

**Для этого используйте новый аккаунт Plex, а не свой.** rex не делает Plex, и Plex может принять меры против аккаунта, который его регистрирует. Поэтому держите свой основной аккаунт, с историей просмотров, друзьями и любой подпиской Plex Pass, в стороне: создайте новый бесплатный аккаунт на [plex.tv](https://www.plex.tv) с адресом электронной почты, который вы нигде больше не используете, зарегистрируйте rex на нём и поделитесь rex со своим собственным аккаунтом. Тогда вы смотрите, войдя как самого себя, так же, как смотрели бы сервер друга. Пока этот шаг не выполнен, rex ничего не воспроизводит.

### Зарегистрируйте rex на новом аккаунте {#register-rex-on-the-fresh-account}

1. Войдите в [plex.tv](https://www.plex.tv) **под новым аккаунтом**, откройте [plex.tv/claim](https://www.plex.tv/claim) и скопируйте код. Он истекает примерно через пять минут.
2. На машине с rex (`curl.exe` в Windows):

   ```bash
   curl -X POST "http://192.168.1.20:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://192.168.1.20:32400/identity
   ```

**Что вы должны увидеть.** Вторая команда показывает `claimed="1"`, и файл `claim_state.json` есть в папке rex. Сделайте резервную копию этого файла: без него придётся привязываться заново с новым кодом. Пока он существует, rex не даёт привязать его ещё раз.

### Поделитесь им со своим аккаунтом {#share-it-with-your-own-account}

1. Всё ещё войдя в свежий аккаунт, откройте [app.plex.tv](https://app.plex.tv), затем **Settings** (значок гаечного ключа), **Manage Library Access** и **Grant Library Access**.
2. Введите имя пользователя или email своего собственного аккаунта, выберите сервер rex и обе библиотеки, **Movies** и **TV Shows**, и отправьте приглашение.
3. Выйдите, войдите как **сам себе** и примите приглашение. Оно придёт по email и в app.plex.tv.

![Manage Library Access в настройках app.plex.tv, с кнопкой Grant Library Access](../assets/rex/20-plex-manage-library-access.webp)

![Диалог Grant Library Access с отмеченными Movies и TV Shows сервера rex](../assets/rex/21-plex-grant-library-access.webp)

**Что должно быть видно.** Войдя под своим аккаунтом, приложения Plex покажут сервер rex рядом с твоими собственными серверами, с обеими библиотеками. Они будут пустыми до следующего шага. История просмотров на rex принадлежит тебе: она хранится отдельно от истории свежего аккаунта. Поделиться ей с кем-то ещё из домашних можно точно так же.

## Шаг 4. Подключите zurg к rex {#step-4-connect-zurg-to-rex}

**Что это делает.** Сообщает zurg, где находится rex. zurg представляется rex, отправляет всю свою библиотеку, считывает видео- и аудиоданные каждого файла и тоже их отправляет, а потом каждое изменение по мере его появления.

**Зачем это нужно.** Это единственная связь между ними. У rex нет настройки для zurg: если `rex_url` отсутствует, rex остаётся пустым. `rex_url` всегда должен быть простым адресом `http://` в вашей сети, а не HTTPS-адресом из [Использование вне дома](#use-it-outside-your-home-optional): rex принимает данные от zurg только из ваших собственных сетей ([Закрытие порта](#keep-the-port-private)). Ваш ключ DMM позволяет zurg спрашивать у DMM, какой фильм или эпизод соответствует каждому файлу. Без него zurg определяет это по имени, и совпадений будет меньше.

zurg не запустится с одним и тем же ключом дважды, а панель zurg записывает `dmm_api_key` в конфиг, когда вы вводите там свой ключ. Если ключа DMM нет, не добавляйте `dmm_api_key`.

+++ Linux и macOS
Сначала проверьте, нет ли уже в конфиге zurg одной из этих строк:

```bash
grep -n '^rex_url:\|^dmm_api_key:' ~/zurg/config.yml
```

Если команда выводит строку, этот ключ уже задан. Измените его там командой `nano ~/zurg/config.yml` и не добавляйте в `printf` ниже.

```bash
printf '\nrex_url: http://192.168.1.20:32400\ndmm_api_key: your_dmm_key\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
Откройте конфиг zurg командой `notepad $HOME\zurg\config.yml`. Если в нём уже есть строка `rex_url:` или `dmm_api_key:`, измените её. Остальные добавьте в конец:

```yaml
rex_url: http://192.168.1.20:32400
dmm_api_key: your_dmm_key
```

Сохраните файл и перезапустите zurg:

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++

**Что вы должны увидеть.** Когда zurg снова загрузит библиотеку, лог zurg (`~/zurg/logs/zurg.log`, в Windows `$HOME\zurg\logs\zurg.log`) напишет `DMM placed N releases` (без ключа DMM: `Placed N releases by their names (no DMM sponsor key)`), а лог rex выведет:

```
INFO    SOURCES zurg registered at http://192.168.1.20:9999/dav
INFO    SOURCES PUT /rex/sources/zurg -> 200
INFO    FEED zurg upsert: 0 created, 0 updated, 200 held, 0 unchanged, 0 rejected
INFO    FEED identified "Sintel.mp4" -> movie tmdb:45745 (placed)
INFO    FEED zurg upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

rex читает каждый файл по адресу из строки `registered at`, поэтому zurg должен быть доступен по нему. rex записывает эту строку повторно, только когда адрес меняется.

`held` означает, что zurg ещё не считал данные этого файла. zurg начинает их считывать, как только его библиотека загрузилась, по одному релизу за раз, и эпизоды сезонного пака приходят вместе. С ключом DMM примерно до 20 релизов в минуту приходят из сохранённых данных DMM. Большая библиотека заполняется несколько часов. Каждый тайтл появляется в rex, как только его данные готовы. Всё, что вы добавите в аккаунт debrid-сервиса позже, появится само, когда zurg его считает.

**Если нет.**

- В логе rex ничего нет: zurg ещё загружает библиотеку, zurg устарел (обновите его, как в [шаге 1](#step-1-install-zurg)) или в `rex_url` опечатка. `grep 'rex feed' ~/zurg/logs/zurg.log | tail -n 5` показывает сторону zurg (в Windows `Select-String 'rex feed' $HOME\zurg\logs\zurg.log | Select-Object -Last 5`). Если нет строки `rex feed: pushing the library to ...`, zurg не прочитал `rex_url`. А `rex feed: snapshot failed, retrying in ...` означает, что по этому адресу он не может достучаться до rex.
- Тайтл остаётся `held`, а zurg пишет `Cannot probe file ...`: первое чтение от debrid-сервиса не удалось. zurg пробует снова сам. **Analyze & Tag Library** в разделе **Utilities** на панели zurg запускает повтор сразу.

  ![Карточка Library Management на странице Utilities в zurg, с кнопкой Analyze & Tag Library](../assets/rex/72-zurg-analyze-tag.webp)

- Тайтлы приходят, но строк `identified` нет: zurg не смог сопоставить их по имени. Если задан `dmm_api_key`, zurg пишет `DMM refused the API key for placement`, когда ключ не спонсорский. Тогда zurg сопоставляет по имени и пробует ключ снова через день или сразу при перезапуске.
- Тайтлы появляются, но ничего не воспроизводится: rex не может достучаться до zurg по адресу из `registered at`. Строка `upstream failed` в разделе [Когда что-то не так](#when-something-is-wrong) это проверяет.

Запускаете несколько zurg (по одному на каждый debrid-сервис)? Дайте каждому своё имя дополнительной строкой `rex_source: rd`, `rex_source: tb` и так далее. Они заполняют одни и те же библиотеки.

### Почему DMM размещает файлы {#why-dmm-places-the-files}

Имена файлов часто нумеруют серии не так, как их показывают списки эпизодов в приложениях Plex. DMM знает, где на самом деле находится каждый файл:

| Релиз | Как назван | Где он на самом деле |
|---|---|---|
| `[Erai-raws] Hibike Euphonium 3 - 01` | season 1, episode 1 | Sound! Euphonium season 3, episode 1 |
| `[HorribleSubs] One Piece - 486` | episode 486 | season 13, episode 486 |
| `Firefly.S01E02.The.Train.Job` (порядок DVD) | episode 2 | episode 1, "The Train Job" |

Файл, который zurg не может разместить, остаётся без совпадения. Это фильм, названный как его файл, или серия шоу с названием релиза, пронумерованная в порядке файлов. Если у тебя есть ключ DMM, zurg снова спросит DMM через день. Исправить вручную можно через **Fix Match** в приложении Plex, войдя в аккаунт, которому принадлежит rex (rex не даёт доступ аккаунтам, с которыми он расшарен). Название, которое ты исправил через Fix Match, сохраняется так, как ты его задал.

![Меню ⋯ фильма в приложении Plex с пунктом Fix Match](../assets/rex/30-plex-fix-match-menu.webp)

![Диалог Fix Match с результатом поиска для выбора](../assets/rex/31-plex-fix-match-results.webp)

Дашборд zurg показывает, что он сделал с каждым релизом. Открой релиз в **Torrent Manager** и посмотри раздел **Placement**. Кнопка **Place again** заново спрашивает DMM, а IMDb id, введённый в поле **External ID**, размещает релиз по этому id.

![Страница релиза в Torrent Manager zurg с полем External ID и разделом Placement](../assets/rex/70-zurg-placement-row.webp)

## Шаг 5. Посмотрите что-нибудь {#step-5-watch-something}

**Что это делает.** Открывает rex в приложении Plex так же, как любой другой сервер Plex.

**Зачем это нужно.** Ради этого всё и затевалось. Это также подтверждает последнее звено: rex читает файл из zurg, пока ты смотришь.

Открой приложение Plex (не веб-браузер) на телефоне, телевизоре или компьютере **в той же домашней сети**. rex появится под именем машины, с **Movies** и **TV Shows**. Выбери фильм и нажми **Play**.

![Приложение Plex, показывающее фильмы и сериалы сервера rex в боковой панели рядом с сеткой фильмов](../assets/rex/10-plex-server-libraries.webp)

Дома больше ничего не нужно: приложения Plex находят rex через собственное локальное обнаружение Plex и подключаются к нему по твоей сети. Для этого устройство должно быть в той же сети, что и rex (а не в гостевом Wi-Fi или отдельном VLAN). Обнаружение работает на UDP-портах 32410 и 32414, поэтому файервол на машине с rex должен их пропускать (в Windows это делают правила файервола из шага 2). rex отвечает на обнаружение, когда использует порт 32400. Если ты перенёс rex на 32500, потому что Plex работает на той же машине, обнаружением занимается этот Plex, а приложения находят rex через аккаунт Plex, которым с ним [поделились](#share-it-with-your-own-account). app.plex.tv в веб-браузере тоже работает дома, по HTTPS-адресу, который [rex-direct](#rex-direct) даёт rex после привязки (rex nightly 2026.11.02 или новее). В первый раз Chrome спросит, может ли app.plex.tv обращаться к устройствам в твоей локальной сети: разреши. `http://192.168.1.20:32400/web` — это не Plex Web: у rex нет собственного веб-приложения, и эта страница лишь показывает, привязан ли rex и где смотреть.

**Что ты должен увидеть.** Постеры, названия и годы, как на любом сервере Plex, и фильм воспроизводится.

Две вещи, с которыми ты можешь столкнуться:

- **"yourhost server is unclaimed and not secure".** Приложение Plex пишет так о любом сервере, не привязанном к аккаунту Plex, и rex ничего не проигрывает, пока не будет привязан. Сделай [шаг 3](#step-3-add-it-to-a-plex-account). Не нажимай **Claim it now**, будучи залогиненным под собой: тогда rex зарегистрируется на твоём собственном аккаунте.
- **"This server is not powerful enough to convert video".** Если все тайтлы не работают на всех устройствах, посмотри лог rex сразу после нажатия Play: `upstream failed` или `502` там означают, что rex не может достучаться до zurg, и FFmpeg это не исправит. В строке `upstream failed` таблицы [Что делать, если что-то не так](#when-something-is-wrong) написано, что делать. Если не работают только некоторые файлы, часто только в веб-браузере, устройство не может проиграть их как есть, часто из-за звука AC3 или DTS. Приложения Plex на телевизорах и телефонах проигрывают большинство файлов как есть. Чтобы проигрывать всё везде, настрой [Конвертацию видео (необязательно)](#converting-video-optional).

Папки zurg помимо `movies` и `shows`, например `anime`, ничего не требуют: каждый файл попадает в **Movies** или **TV Shows** в зависимости от того, что zurg о нём сообщает. Файл, который zurg не может отнести к эпизоду, ждёт в **Movies**.

Чтобы дать одной из этих папок собственные библиотеки, добавь `rex_movies` в `config.yml` zurg, под ней, для папки с фильмами, `rex_shows` для папки с сериалами, а оба ключа только если в ней есть и то, и другое, рядом с её фильтрами, затем перезапусти zurg, как в [шаге 4](#step-4-connect-zurg-to-rex). Каждый ключ создаёт библиотеку, даже пустую, так что папка с фильмами и `rex_shows` даст пустую библиотеку сериалов. DMM раскладывает часть файлов папки как фильмы, а часть как эпизоды, и тип без собственного названия уходит в **Movies** или **TV Shows**:

```yaml
directories:
  anime:
    rex_shows: Anime
    rex_movies: Anime Movies
  films:
    rex_movies: Films
```

Когда zurg загрузится, rex создаст **Anime**, **Anime Movies** и **Films** и перенесёт туда то, что уже показывал из `anime`, как было: история просмотра, Fix Match и правки тоже. Открытый Plex Web сразу покажет их в **More** в боковой панели, где их можно закрепить. Поделись ими со своим аккаунтом, как в [шаге 3](#share-it-with-your-own-account). Переименовывай их в приложении Plex как хочешь. Удалишь одну — она останется удалённой, а её файлы вернутся в **Movies** или **TV Shows», пока ты не добавишь её снова через **Add Library**, где в списке видны папки zurg. Если позже уберёшь `rex_shows` или `rex_movies` из конфига zurg, библиотека, которую для них создал rex, останется, пустая или нет: удали её в приложении Plex, войдя под новым аккаунтом. Если библиотека не появилась, лог zurg или rex скажет почему.

![Окно выбора папки Add Library со списком папок источника: anime, kids и movies](../assets/rex/14-plex-add-library-folders.webp)

!!!warning Удаление в приложении Plex удаляет из твоего debrid-аккаунта
Войдя под новым аккаунтом, **Delete** у фильма или эпизода удаляет и его файл в zurg, а zurg удаляет торрент из твоего debrid-аккаунта, когда не остаётся ни одного его файла. Аккаунты, с которыми открыт доступ к rex, включая твой, удалять не могут. Чтобы выключить удаление: в app.plex.tv под новым аккаунтом открой **Settings**, **Library** сервера rex, **Show Advanced**, сними галочку с **Allow media deletion** и сохрани. rex тогда отказывает в каждом удалении.
!!!

![Настройки библиотеки сервера rex с раскрытым Show Advanced и обведённым Allow media deletion](../assets/rex/32-plex-allow-media-deletion.webp)

Тайтл, который уходит из твоего debrid-аккаунта другим путём, удалённый там или самим zurg, попадает в корзину библиотеки в rex, как было бы в Plex: он остаётся недоступным, с историей просмотра, и возвращается как был, если zurg снова его получит. **Empty Trash** у библиотеки удаляет его насовсем, а **Empty trash automatically after every scan** (Settings, Library) делает это само; по умолчанию эта опция выключена.

**Сделай резервную копию** `rex.db` в папке rex (там твоя библиотека, история просмотра и логин zurg, так что держи его в секрете) и, когда они появятся, `claim_state.json` и `rex-direct.json` (привязка и ключ сертификата rex-direct):

+++ Linux and macOS
```bash
sudo apt install -y sqlite3    # once, on Linux; macOS has it
mkdir -p ~/rex-backup
sqlite3 ~/rex/rex.db ".backup $HOME/rex-backup/rex.db"
cp ~/rex/*.json ~/rex-backup/
```
+++ Windows
Windows не имеет `sqlite3`, поэтому на время останови rex и скопируй `rex.db` вместе с двумя файлами рядом, которые начинаются так же:

```powershell
Stop-Process -Name rex; Start-Sleep 1
New-Item -ItemType Directory -Force $HOME\rex-backup | Out-Null
Copy-Item $HOME\rex\rex.db*, $HOME\rex\*.json $HOME\rex-backup
Start-ScheduledTask rex
```
+++

В Docker файлы лежат в `~/rex/config`, и читать их может только root. Сделай копию изнутри контейнера командой `docker exec rex sqlite3 /config/rex.db ".backup /config/rex.db.bak"`, затем `mkdir -p ~/rex-backup && sudo cp ~/rex/config/rex.db.bak ~/rex/config/*.json ~/rex-backup/`.

[Восстановить из копии](#restore-a-backup) вернёт их на место.

Готово. Разделы ниже необязательны.

## Использование вне дома (необязательно) {#use-it-outside-your-home-optional}

**Что это делает.** Даёт rex HTTPS-адрес, по которому Plex-приложения вне дома могут до него достучаться, и сообщает об этом адресе plex.tv.

**Почему это важно.** Вне дома app.plex.tv подключается только к HTTPS-адресу, а остальные Plex-приложения тоже предпочитают его. Настоящий Plex-сервер может переключиться на ретранслятор Plex, а rex так не умеет, поэтому способ подключения выбираешь ты. Сначала rex нужно [привязать](#step-3-add-it-to-a-plex-account) к аккаунту, а прокси, который смотрит в интернет, должен блокировать `/rex/` ([Держи порт закрытым](#keep-the-port-private)).

**Plex Pass.** Plex Web воспроизводит вне дома без Plex Pass или Remote Watch Pass на любом из аккаунтов. Другие Plex-приложения вне дома не проверялись.

Какой бы вариант ты ни выбрал, всё, что ты смотришь вне дома, уходит через **скорость отдачи** (upload) твоего домашнего интернета. Канал 20 Мбит/с спокойно потянет один 1080p WEB-DL, но не remux.

### Какой вариант выбрать {#which-one-to-use}

| Ваша ситуация | Что использовать | Почему |
|---|---|---|
| Ваш роутер имеет публичный IP, и вы можете пробросить порт | **[rex-direct](#rex-direct)** (самый простой) | Включён по умолчанию: один проброс порта. DMM даёт rex имя и сертификат и следит, чтобы имя указывало на ваш домашний IP |
| Вы можете установить Tailscale на устройства, с которых смотрите | **[Tailscale serve](#tailscale-serve)** (лучший вариант) | Ничего не нужно открывать на роутере, работает за любым интернет-подключением. Сертификат продлевается сам, а никто за пределами вашего tailnet не может достучаться до rex |
| Устройства без Tailscale (телевизор друга, отель), и ваш роутер имеет публичный IP | **[Caddy](#caddy)** с вашим доменом или с бесплатным именем `sslip.io` | Прямое соединение без посредников и бесплатный сертификат, который продлевается сам. Вы пробрасываете порт 443 |
| У вашего подключения нет публичного IPv4 (CGNAT или DS-Lite, часто встречается у кабельных, мобильных и некоторых оптоволоконных провайдеров), но есть IPv6 | **[rex-direct over IPv6](#rex-direct-over-ipv6)** | Не нужен проброс порта и ничего арендовать не нужно: вы открываете порт 32400 для IPv6. Устройствам, с которых смотрите, тоже нужен IPv6, он есть у большинства мобильных сетей |
| У вашего подключения вообще нет публичного IP, либо вы смотрите в сетях без IPv6, и устройства без Tailscale | **[Небольшой VPS](#a-small-vps)** | У rex нет ретранслятора и не будет. Арендованный VPS имеет публичный IP, а туннель передаёт всё до rex на полной скорости VPS |

Не рекомендуется:

- **Cloudflare tunnel.** Каждый байт проходит через Cloudflare, который также отбрасывает `Range` при первом чтении файла, поэтому каждый старт воспроизведения тянет весь файл от вашего debrid-сервиса.
- **Tailscale Funnel, ngrok и другие хостированные туннели.** Они ограничивают полосу или объём данных в месяц, а фильм расходует это очень быстро. Tailscale Funnel также публикует весь rex, включая API, на который отправляет данные zurg: любой в интернете мог бы добавлять или удалять что-то в этой библиотеке.
- **Проброс порта 32400 без rex-direct или собственного сертификата.** Приложения Plex получат адрес с обычным HTTP, который app.plex.tv не принимает.

### rex-direct

rex-direct — это ответ DMM на plex.direct, и по умолчанию он включён. На роутере перенаправьте порт 32400 (TCP) на машину с rex. Больше ничего делать не нужно, перезапускать ничего не требуется.

После привязки rex получает от DMM два имени: `<hash>.rex-direct.debridmediamanager.com`, которое указывает на ваш домашний публичный IP, и `lan.<hash>.rex-direct.debridmediamanager.com`, которое указывает на LAN-IP машины с rex, и сертификат для обоих. Первый сертификат выпускается несколько минут; в логе rex видно, что он выпускается, а затем каждое имя выводится в строке `rex-direct:`. Новый домашний IP и продление сертификатов подхватываются автоматически. На одном аккаунте Plex можно держать до десяти имён rex-direct. Дома приложения Plex, включая app.plex.tv, могут использовать имя `lan.`, которое ведёт к rex напрямую через вашу сеть, поэтому перенаправление порта нужно только для доступа из дома вне сети. В app.plex.tv разрешите доступ к устройствам в локальной сети, когда Chrome об этом спросит, иначе он переключится на публичное имя, для которого нужно перенаправление порта. [Что вы должны увидеть](#what-you-should-see) поможет проверить оба имени.

Если ваш роутер перенаправляет на rex другой внешний порт, добавьте ключ `REX_DIRECT_PORT=<that port>`, как показано в [шаге 2](#step-2-install-rex) для вашей системы, и перезапустите rex. Перенаправление порта не открывает API, на который отправляет данные zurg: см. [Держите порт закрытым](#keep-the-port-private).

### rex-direct через IPv6 {#rex-direct-over-ipv6}

Для подключения без публичного IPv4 (CGNAT или DS-Lite), но с IPv6. Когда DMM подключается к rex по его IPv6-адресу и находит там тот же сервер, он привязывает к этому адресу и имя rex-direct. Нужен rex nightly 2026.11.08 или новее, а в Docker нужен host networking.

Проброс портов для IPv6 не нужен, и маппинг портов тоже не нужен: rex должен использовать один и тот же порт снаружи и внутри, поэтому оставьте `REX_DIRECT_PORT` не заданным. В файрволе роутера разрешите входящие TCP-подключения на порт 32400 к машине с rex по IPv6. rex публикует свой IPv6 через минуту после запуска (или после привязки) и далее каждые 6 часов, поэтому добавьте правило до запуска rex или перезапустите rex после его добавления. Примерно через минуту в логе появятся обе строки с адресами:

```
rex-direct: https://<hash>.rex-direct.debridmediamanager.com:32400 -> <IPv4> and <IPv6>
```

Если строка с `and <IPv6>` не появилась в течение нескольких минут, DMM не смог подключиться к rex по IPv6. Проверьте правило файрвола и то, что rex в Docker использует host networking. В Windows rex публикует временный IPv6-адрес Windows, который система меняет примерно раз в сутки. Чтобы отключить временные адреса, выполните `netsh interface ipv6 set privacy state=disabled` в PowerShell от имени администратора, а затем перезапустите rex, чтобы он опубликовал стабильный адрес. `<IPv4>` в этой строке — общий адрес вашего провайдера, по нему rex не достучаться, поэтому устройствам, с которых вы смотрите, тоже нужен IPv6. Большинство мобильных сетей поддерживают IPv6; гостиничная или офисная сеть только с IPv4 таким способом до rex не дотянется.

### Tailscale serve

Установите [Tailscale](https://tailscale.com/download) на машину с rex и на устройства, с которых будете смотреть, и войдите в один и тот же аккаунт. Затем на машине с rex:

```bash
sudo tailscale serve --bg 32400
```

В Windows запустите это в PowerShell от имени администратора, без `sudo`. На macOS используйте [командную строку](https://tailscale.com/kb/1080/cli) приложения Tailscale, тоже без `sudo`.

Команда выведет адрес, например `https://myhost.tailnet.ts.net`. Добавьте к нему `:443` и передайте rex: в конец команды запуска rex из [шага 2](#step-2-install-rex) допишите `--announce-url https://myhost.tailnet.ts.net:443` и перезапустите rex.

Tailscale соединяет ваши устройства напрямую, поэтому поток не проходит через серверы Tailscale, кроме случаев, когда сеть это блокирует.

### Caddy

Нужно, чтобы на роутере был проброшен порт 443 на машину с rex, и имя для домашнего IP-адреса:

- **Свой домен:** запись `A`, например `rex.example.com`, которая указывает на твой домашний IP.
- **Без домена:** используй `1-2-3-4.sslip.io` с цифрами твоего публичного IP (`curl -s ifconfig.me` его покажет). Оно всегда резолвится в этот IP. Если IP меняется, обнови имя.

Установи [Caddy](https://caddyserver.com/docs/install) и дай ему такой Caddyfile (`/etc/caddy/Caddyfile` для пакета Caddy на Linux; на macOS и Windows это файл с именем `Caddyfile` в отдельной папке, которую читает `caddy run`, запущенный в этой папке):

```
rex.example.com {
	respond /rex/* 403
	reverse_proxy 192.168.1.20:32400
}
```

`respond /rex/* 403` не даёт API, на который отправляет данные zurg, быть доступным из интернета. zurg всё равно достучится до него по `http://192.168.1.20:32400`. Затем перезагрузи Caddy (`sudo systemctl reload caddy` для пакета на Linux). На macOS и Windows вместо этого запусти `caddy run` в его папке и держи его запущенным так же, как [шаг 2](#step-2-install-rex) держит rex. На Windows ещё разреши TCP-порт 443 через брандмауэр, как в шаге 2 делается для 32400.

Caddy получает сертификат при загрузке файла и продлевает его сам. Добавь к команде запуска rex `--announce-url https://rex.example.com:443` и перезапусти rex.

### Небольшой VPS {#a-small-vps}

Если у вас нет публичного IP вообще или вы смотрите из сетей без IPv6: тогда VPS несёт весь трафик вместо [rex-direct через IPv6](#rex-direct-over-ipv6). У rex нет ретранслятора и не будет. Поэтому арендованный сервер заменяет ваш роутер: у него есть публичный IP, а туннель от машины с rex несёт всё до rex. Подойдёт любой VPS с публичным IPv4, это пара евро в месяц. **Выберите тариф, в котором месячного трафика хватит на всё, что вы смотрите вне дома:** каждый байт проходит через него, а тариф с маленьким лимитом трафика закончится.

Понадобятся IP VPS (`1.2.3.4` ниже), открытые порты 443, 80 и 7000 на нём и длинная случайная строка для туннеля (`openssl rand -hex 32`).

**На VPS** установите [frp](https://github.com/fatedier/frp/releases) (программу `frps`) и [Caddy](https://caddyserver.com/docs/install). Создайте `frps.toml`:

```toml
bindPort = 7000
auth.token = "your-long-random-string"
proxyBindAddr = "127.0.0.1"
```

`proxyBindAddr` держит конец туннеля на loopback VPS, так что из интернета к rex можно попасть только через Caddy. Создайте `/etc/caddy/Caddyfile`, где IP VPS указан как `1-2-3-4.sslip.io` (бесплатное имя, которое всегда указывает на этот IP), либо укажите свой домен, направленный на него:

```
1-2-3-4.sslip.io {
	respond /rex/* 403
	reverse_proxy 127.0.0.1:32400
}
```

`respond /rex/* 403` закрывает от интернета API, на который отправляет данные zurg. Запустите `frps -c frps.toml` как службу и выполните `sudo systemctl reload caddy`.

**На машине с rex** тоже установите frp (программу `frpc`) и создайте `frpc.toml`:

```toml
serverAddr = "1.2.3.4"
serverPort = 7000
auth.token = "your-long-random-string"

[[proxies]]
name = "rex"
type = "tcp"
localIP = "192.168.1.20"
localPort = 32400
remotePort = 32400
```

Запустите его как службу: в Linux, например, `~/.config/systemd/user/frpc.service` с `ExecStart=%h/frp/frpc -c %h/frp/frpc.toml` и `Restart=always`; в macOS и Windows запускайте `frpc -c frpc.toml` так же, как [шаг 2](#step-2-install-rex) запускает rex. Затем допишите в конец команды запуска rex `--announce-url https://1-2-3-4.sslip.io:443`, добавьте ключ `REX_DIRECT_URL=off` (за CGNAT IPv4 имени rex-direct не доходит до rex, поэтому plex.tv не должен его публиковать) и перезапустите rex. Тогда app.plex.tv дома тоже пойдёт через VPS; остальные приложения Plex дома по-прежнему подключаются к rex напрямую.

### Что вы должны увидеть {#what-you-should-see}

```bash
curl -s https://lan.<hash>.rex-direct.debridmediamanager.com:32400/identity
```

показывает короткую XML-страницу с `machineIdentifier` rex на домашнем компьютере; `curl` ничего не показывает, если адрес или его сертификат неверны. Используйте свой адрес: rex записывает его при запуске в виде `rex-direct: https://lan.<hash>.rex-direct.debridmediamanager.com:32400 -> 192.168.1.20 (LAN)` (при `REX_DIRECT_URL=off` такой строки нет). Откройте свой внешний адрес с добавленным `/identity` в браузере телефона при выключенном Wi-Fi: при rex-direct это вторая строка `rex-direct:` из лога rex, а при Tailscale serve это `https://myhost.tailnet.ts.net`, который телефон открывает только при включённом Tailscale. Должна появиться короткая XML-страница без предупреждения о сертификате.

Если телефон не подключается, значит, порт не перенаправлен (или, [через IPv6](#rex-direct-over-ipv6), не пропускается), ваше соединение находится за CGNAT без IPv6, rex доступен только по IPv6, а в сети телефона IPv6 нет, или сертификат rex-direct ещё выпускается (пока это происходит, об этом пишет лог rex).

В логе rex перечислены адреса, которые он объявляет:

```
INFO    heartbeat every 600s for machine ... -> https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

rex выводит это при каждом запуске. Проблемы потом проявляются как `heartbeat failed` или `announced but NOT visible`. В остальном сервер передаёт эти адреса на plex.tv, и приложение Plex вне дома выбирает тот, до которого может достучаться. Если rex пишет `waiting for a claim`, сначала выполните [шаг 3](#step-3-add-it-to-a-plex-account).

## История просмотра с другого сервера Plex (необязательно) {#your-watch-history-from-another-plex-server-optional}

Уже смотрели что-нибудь на другом сервере Plex? Когда ваша библиотека будет в rex, [Перенесите историю просмотров](import-watched.md) скопирует оттуда, что вы смотрели, на каком месте остановились и ваши оценки по звёздочкам. Для каждого человека это делается отдельно.

## Sonarr, Radarr и Bazarr (необязательно) {#sonarr-radarr-and-bazarr-optional}

rex не требует монтирования, а вот Sonarr и Radarr требуют: они импортируют файлы в монтирование zurg, в папку `__magic__`. Настройте их вместе с zurg по инструкции [Sonarr и Radarr для торрентов](../zurg/guides/sonarr-radarr-torrents.md) или [для Usenet](../zurg/guides/sonarr-radarr.md). То, что они скачают, попадёт в rex через zurg, как и всё остальное. Субтитры, которые Bazarr сохраняет рядом с импортированными файлами, появляются в rex примерно через минуту: [Субтитры с Bazarr](../zurg/guides/subtitles.md). Один zurg может держать в одной библиотеке и ваш аккаунт debrid, и Usenet ([Usenet](../zurg/guides/usenet.md)). Две копии одного фильма в rex считаются одним тайтлом, и у каждой есть своя версия.

## Конвертация видео (необязательно) {#converting-video-optional}

**Что это делает.** Позволяет rex перекодировать то, что устройство не может воспроизвести, так же, как это делает Plex.

**Зачем это нужно.** Без этого, если устройство не может воспроизвести файл в исходном виде, появляется сообщение "This server is not powerful enough to convert video". Чаще всего с ним сталкиваются веб-браузеры, например при звуке AC3 или DTS. Если не играет вообще всё на всех устройствах, причина другая: см. [шаг 5](#step-5-watch-something).

Установите **jellyfin-ffmpeg** 8, а не `ffmpeg` из вашей системы: это сборка, с которой тестируется rex, и единственная, которая перекодирует все файлы Dolby Vision, тонмаппит HDR на видеочипе и рисует там субтитры. Другой FFmpeg перекодирует обычное видео, а лог rex покажет, чего ему не хватает (собственный FFmpeg Ubuntu 22.04 ещё и промахивается по перемотке на несколько секунд). rex находит его сам.

+++ Linux
Пакет ставится в `/usr/lib/jellyfin-ffmpeg` рядом с любым другим FFmpeg. Первая строка выбирает сборку под вашу систему: есть сборки для Ubuntu 22.04, 24.04 и 26.04 и Debian 12 и 13, для amd64 или arm64, а на любой другой системе `curl` остановится с ошибкой.

```bash
DEB=jellyfin-ffmpeg8_8.1.3-1-$(. /etc/os-release; echo "$VERSION_CODENAME")_$(dpkg --print-architecture).deb
curl -fLO "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/$DEB"
sudo apt install -y "./$DEB" && rm "$DEB"
systemctl --user restart rex
```

На другом Linux распакуйте портативную сборку jellyfin-ffmpeg в `~/rex/ffmpeg`, где rex её ищет, и перезапустите rex. Она использует драйвер видеокарты из вашей системы, поэтому на старой системе перекодирование идёт только на процессоре; где есть пакет, используйте его.

```bash
B=$( [ "$(uname -m)" = aarch64 ] && echo linuxarm64 || echo linux64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
```

Если у вас видеочип Intel или AMD, также выполните `sudo usermod -aG render "$USER"` и перезагрузитесь, чтобы служба получила эту группу; в LXC пробросьте GPU. Чип ускоряет перекодирование; без него rex использует процессор. Без чипа Intel или AMD rex также пробует энкодер видеокарты NVIDIA. На Intel команда `sudo apt install intel-opencl-icd` позволяет перекодировать HDR и Dolby Vision на чипе почти в реальном времени для 4K на маломощном Intel; без неё они перекодируются на процессоре, который маломощный Intel не может тянуть в реальном времени в 4K.
+++ macOS
Портативная сборка кладётся в `~/rex/ffmpeg`, где rex её ищет:

```bash
B=$( [ "$(uname -m)" = arm64 ] && echo macarm64 || echo mac64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
launchctl kickstart -k gui/$(id -u)/com.rex
```

На Mac rex всегда перекодирует на процессоре: у него нет способа использовать видеочип Mac.
+++ Windows
Портативная сборка кладётся в папку `ffmpeg` внутри папки rex, где rex её ищет:

```powershell
cd $HOME\rex
curl.exe -fLO https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Expand-Archive jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip ffmpeg
Remove-Item jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex
```

В Windows rex перекодирует на энкодере видеокарты NVIDIA, если она есть, а иначе на процессоре.
+++

**Что должно появиться.** В логе rex есть строка `transcoder:` с названием FFmpeg и найденным железом (`hardware none` означает процессор); `transcoder off` при старте означает, что ничего не найдено. Файл, который раньше не играл, теперь воспроизводится; в логе видно, что было перекодировано, например `video=copy h264 audio=ac3->aac 6ch`.

Субтитры в перекодированном файле: графические субтитры вшиваются в картинку, а загруженные вами субтитры передаются вместе с файлом. Plex для Android и iOS также сохраняет текстовые субтитры как отдельную дорожку; другие приложения выводят их поверх картинки. Перекодированные офлайн-загрузки по-прежнему не содержат текстовых субтитров.

## Субтитры {#subtitles}

**Что это делает.** Поиск субтитров в приложении Plex находит субтитры у провайдера самого Plex, как только rex подключён. rex проверяет выбранные вами субтитры по файлу и исправляет их тайминг, если они идут с опозданием или были сделаны под другую частоту кадров. Если в вашем аккаунте Plex включён показ субтитров и у фильма нет субтитров на вашем языке, rex ищет их до 3 секунд перед началом воспроизведения.

**Зачем это нужно.** Первый результат Plex часто не совпадает с файлом по синхронизации.

![Диалог поиска субтитров Subtitles в приложении Plex, со списком английских результатов для Sintel](../assets/rex/51-plex-search-subtitles.webp)

Ничего настраивать не нужно. rex сверяет субтитр с текстовыми субтитрами самого файла, если они там есть. Файл без них сверяется со звуком в момент нажатия «Play». Для этого нужно настроить [Converting video](#converting-video-optional), и rex читает шесть кусков файла по 90 секунд.

**Что вы должны увидеть.** В логе rex есть строка `SUBTITLE measured` для каждого проверенного субтитра, а когда он его исправил, появляется строка `SUBTITLE applied ... corrected by`.

## Возможности для фильмов и сериалов {#movie-and-tv-capabilities}

Загрузки, пропуск интро и титров, превью при перемотке и другие серверные настройки описаны в [руководстве по настройке rex](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities). Музыка и Live TV приходят из источников, которые их отдают ([ограничения rex](https://github.com/debridmediamanager/rex#limits)), например из [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) для прямых эфиров каналов. DVR нет, поэтому ничего не записывается. Фото появляются только из источника, который отдаёт картинки: zurg отдаёт комиксы из папки с [`rex_photos`](../zurg/reference/config.md#directory-options). Plex Web их показывает, а Plex для Android медиатеку с фото не показывает.

Для совместного воспроизведения с debrid оставь режим прокси по умолчанию. Real-Debrid отслеживает публичный IP каждого, кто качает; если с одного аккаунта идёт загрузка с нескольких IP, он выдаст предупреждение о шаринге, даже когда загрузки проходят успешно. Ссылки на загрузку TorBox содержат полный API-ключ, поэтому при редиректе каждый клиент и каждый общий пользовательский аккаунт получит доступ, включая удаление. Прочитай [риски и настройку редиректа](direct-download.md#before-you-start), прежде чем разрешать приложениям загружать с провайдера.

## Запуск rex в Docker {#run-rex-in-docker}

Та же настройка, где zurg и rex запущены в контейнерах на одной машине с Linux. Шаги совпадают с описанными выше, отличается только способ запуска каждой части. На macOS и Windows Docker Desktop запускает контейнеры внутри виртуальной машины, поэтому host networking, обнаружение в локальной сети и графический процессор там работают не так, как в Linux, и rex не может подключиться к zurg: ([шаг 1](#step-1-install-zurg)): вместо этого используйте шаги выше.

### D1. Установите zurg в Docker {#d1-install-zurg-in-docker}

**Что делает.** Запускает zurg в контейнере, точка монтирования которого появляется на машине в `/zurg_mnt/zurg`.

**Зачем это нужно.** Как и на шаге 1, всё, что показывает rex, берётся из zurg.

Следуй [инструкции по Docker для zurg](../zurg/setup/docker.md). Установщик в одну строку, который там есть, делает всё сам. Он может сначала попросить подтвердить доступы `read:packages` и `repo` для твоего входа в GitHub: одноразовый код появится в браузере. Ручные шаги на той же странице делают то же самое вручную.

**Что ты должен увидеть.** `docker compose exec zurg /app/zurg doctor --working-dir /config` заканчивается строками `PASS` (`WARN service zurg is not installed` ожидаемо: Docker перезапускает zurg, а не systemd), и

```bash
ls /zurg_mnt/zurg/movies /zurg_mnt/zurg/shows
```

показывает твою библиотеку.

Уже запускал zurg в Docker? Обнови его: `cd ~/zurg && docker compose pull zurg && docker compose up -d zurg`. Если `ZURG_TAG` в `~/zurg/.env` указывает на сборку с датой, сначала поставь `latest`.

### D2. Запустите rex в Docker {#d2-start-rex-in-docker}

**Что он делает.** Запускает rex из его образа и хранит все, что тот сохраняет, в папке рядом с compose-файлом.

**Зачем это нужно.** Это [шаг 2](#step-2-install-rex) в одном файле: образ — это сама программа, а Docker следит за тем, чтобы она работала.

Если `docker ps` выдаёт permission denied, ставьте `sudo` перед каждой командой `docker` на этой странице.

Создайте папку, например `~/rex`, с таким `compose.yml`:

```yaml
services:
  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./config:/config
```

- `network_mode: host` позволяет приложениям Plex в вашей сети находить rex самостоятельно, а также даёт rex доступ к контейнеру zurg.
- Графика Intel или AMD? Добавьте `devices: ["/dev/dri:/dev/dri"]`, чтобы rex конвертировал видео на ней.
- В `./config` попадают `rex.db` и позже `claim_state.json`. Читать их может только root, потому что `rex.db` хранит логин zurg.
- Plex Media Server на той же машине? Добавьте `command: --port 32500` и используйте `32500` везде, где команда или настройка указывает `32400`.

```bash
docker compose up -d
docker compose logs -f rex
```

**Что вы должны увидеть.** Те же строки, что и в [шаге 2](#step-2-install-rex), с `seeded /config/rex.db` и `no source yet`. Оставьте лог открытым.

### D3. Добавьте в аккаунт Plex {#d3-add-it-to-a-plex-account}

**Что это делает.** [Шаг 3](#step-3-add-it-to-a-plex-account) для контейнера, выполняется до того, как zurg начнёт что-либо отправлять, чтобы названия приходили вместе с постерами.

Следуйте шагу 3: его команды `curl` работают как есть на этой машине. `claim_state.json` появляется в `~/rex/config`.

### D4. Подключите zurg к rex {#d4-connect-zurg-to-rex}

**Что это делает.** То же, что и [шаг 4](#step-4-connect-zurg-to-rex). Конфиг zurg лежит в папке compose у zurg и принадлежит root. Сначала проверь его, как в шаге 4:

```bash
cd ~/zurg
sudo grep -n '^rex_url:\|^dmm_api_key:' config.yml
```

Если он что-то выводит, поменяй нужный ключ там с помощью `sudo nano config.yml` и не добавляй его в `printf`. Потом:

```bash
printf '\nrex_url: http://192.168.1.20:32400\ndmm_api_key: your_dmm_key\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```

**Что ты должен увидеть.** В логе rex будет `SOURCES PUT /rex/sources/zurg -> 200`, а `curl -s http://192.168.1.20:32400/rex/sources` покажет zurg с его **адресом в контейнере**, например `http://172.18.0.2:9999/dav`. На Linux это нормально: rex работает на той же машине и достучится до контейнера напрямую.

**zurg и rex на разных машинах?** rex не сможет достучаться до адреса контейнера. Добавь контейнеру zurg `network_mode: host` (и удали его строки `ports:`), чтобы он регистрировался с LAN-IP машины.

### D5. Смотрите {#d5-watch}

rex в логе называет каждый тайтл так, как его читает zurg, например [шаг 4](#step-4-connect-zurg-to-rex). Откройте приложение Plex в вашей сети, например [шаг 5](#step-5-watch-something).

**Что вы должны увидеть.** Тайтлы появляются в **Movies** и **TV Shows**, а `docker compose restart rex` возвращает их обратно с `state file /config/rex.db: restored` и `source zurg: registered`.

### D6. Обновление {#d6-update}

```bash
cd ~/rex && docker compose pull && docker compose up -d
```

rex возвращается с той же библиотекой. Про zurg см. [Управление zurg и его обновление](../zurg/setup/docker.md#managing-and-updating-zurg).

В образе есть jellyfin-ffmpeg, поэтому для [конвертации видео](#converting-video-optional) нужно только передать графический чип. HTTPS работает так же, как описано выше: Tailscale, Caddy и frp запускаются на самой машине, а `--announce-url ...` идёт в `command:` compose-файла.

## Держите порт закрытым {#keep-the-port-private}

rex-API, на который zurg отправляет данные, не требует пароля. Он отвечает только с этой машины, из вашей домашней сети и из Tailscale. Поэтому проброс порта rex для [rex-direct](#rex-direct) или доступ по IPv6 его не открывают. Если роутер даёт внешним посетителям свой собственный адрес, они начинают выглядеть как локальные, и тогда фид становится доступен из интернета. Прокси на машине rex выглядит как локальный для самого rex, поэтому `/rex/*` нужно блокировать в любом прокси, который смотрит в интернет, как это сделано в примере с [Caddy](#caddy).

## Обновление {#updating}

- **zurg:** см. [шаг 1](#step-1-install-zurg).
- **rex:** rex никогда не обновляет себя сам. Запустите блок загрузки из [шага 2](#step-2-install-rex) ещё раз (он заменит программу и `data/`, а `rex.db`, ваши ключи, `claim_state.json` и `rex-direct.json` не тронет), затем перезапустите rex, как показано в шаге 2. В Windows перед блоком загрузки выполните `Stop-Process -Name rex`, потому что Windows не даёт заменить запущенный `rex.exe`, а после блока выполните `Start-ScheduledTask rex`. Если rex после этого завершится с ошибкой `unrecognized arguments`, удалите из команды запуска rex флаги, которые она называет: в rex их больше нет.

## Позже: восстановление, перенос, удаление {#later-restore-move-remove}

### Восстановление из резервной копии {#restore-a-backup}

Остановите rex, удалите `rex.db` и лежащие рядом с ним `rex.db-wal` и `rex.db-shm`, положите файлы вашей резервной копии в папку rex и запустите rex. Если оставить старый `rex.db-wal` на месте, восстановление откатится.

+++ Linux
```bash
systemctl --user stop rex
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
systemctl --user start rex
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
launchctl load ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
```powershell
Stop-Process -Name rex; Start-Sleep 1
Remove-Item $HOME\rex\rex.db*
Copy-Item $HOME\rex-backup\* $HOME\rex
Start-ScheduledTask rex
```
+++ Docker
```bash
cd ~/rex && docker compose down
sudo rm -f config/rex.db config/rex.db-wal config/rex.db-shm
sudo cp ~/rex-backup/rex.db.bak config/rex.db && sudo cp ~/rex-backup/*.json config/
docker compose up -d
```
+++

### Перенос rex на другую машину {#move-rex-to-another-machine}

Сделайте бэкап, как описано в [шаге 5](#step-5-watch-something), затем полностью остановите rex на старой машине, как в первом блоке [Remove rex](#remove-rex). На новой выполните [шаг 2](#step-2-install-rex), но скопируйте файлы бэкапа в папку rex до того, как сделаете его службой. Для ваших приложений Plex это тот же сервер: он по-прежнему привязан к аккаунту и расшарен. Затем:

- Укажите новый LAN IP в `rex_url` у zurg и перезапустите zurg ([шаг 4](#step-4-connect-zurg-to-rex)).
- Перенесите проброс портов на роутере на новую машину или правило IPv6-файрвола до того, как rex запустится там. Имя rex-direct остаётся прежним и само следует за новым публичным IP. Tailscale serve и Caddy настраиваются заново на новой машине.

### Перенос rex на другой аккаунт Plex {#move-rex-to-another-plex-account}

Если аккаунт, к которому привязан rex, потерян или заблокирован, или вы хотите перенести rex на другой аккаунт, создайте новый аккаунт, остановите rex, удалите `claim_state.json` в папке rex, запустите rex и заново выполните [шаг 3](#step-3-add-it-to-a-plex-account): привяжите сервер, а затем снова откройте к нему доступ всем. Если вы ещё можете войти в старый аккаунт, удалите rex и там: в app.plex.tv откройте **Settings**, **Authorized Devices**, выберите фильтр **Servers** и удалите его. Этих двух шагов достаточно, чтобы полностью отвязать rex. У rex нет выхода из аккаунта: запрос Plex на выход (`DELETE /myplex/account`) возвращает 200, но rex остаётся привязанным. Библиотека, Fix Match, правки и имя rex-direct сохраняются, а история просмотров каждого человека вернётся, как только rex снова будет открыт для его аккаунта.

### Какой rex запускать? {#which-rex-do-i-run}

rex не имеет команды version. Дата nightly-сборки указана в названии загрузки (`2026.10.30.0040-nightly`), а у файла программы та же дата: `ls -l ~/rex/rex` (в Windows `(Get-Item $HOME\rex\rex.exe).LastWriteTime`). Версия Plex, которую показывают твои приложения, не относится к rex: rex намеренно сообщает текущую версию Plex Media Server, поэтому приложения считают её актуальной, а **Check for Updates** всегда говорит, что обновление не нужно.

### Начать сначала {#start-over}

Чтобы снова наполнить библиотеку из zurg, сохранив привязку (claim) и общие доступы (shares): удали zurg как источник (`curl -s -X DELETE http://192.168.1.20:32400/rex/sources/zurg`, затем отправь `DELETE` по пути `confirm` из ответа, в течение пяти минут) и перезапусти zurg. Это сбросит историю просмотров того, что zurg отправил. Чтобы начать с нуля, останови rex, удали `rex.db`, `rex.db-wal`, `rex.db-shm`, `claim_state.json` и `rex-direct.json`, запусти rex, убери старый сервер из нового аккаунта, как описано ниже, выполни [шаг 3](#step-3-add-it-to-a-plex-account) и перезапусти zurg.

### Удаление rex {#remove-rex}

Полностью остановите rex:

+++ Linux
```bash
systemctl --user disable --now rex && rm ~/.config/systemd/user/rex.service
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist && rm ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
В PowerShell от имени администратора:

```powershell
Unregister-ScheduledTask rex -Confirm:$false; Stop-Process -Name rex
Remove-NetFirewallRule -DisplayName rex, "rex discovery"
```
+++ Docker
```bash
cd ~/rex && docker compose down
```
+++

Затем удалите строку `rex_url` из `config.yml` у zurg и перезапустите zurg. Зайдите на app.plex.tv под новым аккаунтом, откройте **Settings**, **Authorized Devices**, включите фильтр по **Servers** и удалите rex. Уберите проброс порта на роутере (или правило IPv6 в файрволе) и удалите папку rex.

### Где получить помощь {#getting-help}

Спрашивайте на форуме **rex-support** в [Discord](https://discord.com/invite/7u4YjMThXP) у DMM: в [Getting help](../guides/remote-help.md) написано, что нужно прикладывать, и как спонсоры получают удалённую помощь.

## Если что-то не работает {#when-something-is-wrong}

| Что вы видите | Что делать |
|---|---|
| `/rex/sources` остаётся `{"size":0}` | zurg устарел, `rex_url` неправильный или библиотека zurg ещё загружается. Обновите zurg, как в [шаге 1](#step-1-install-zurg), и посмотрите конец лога zurg ([шаг 4](#step-4-connect-zurg-to-rex)) |
| В логе rex строка `held ... no media_info yet`, библиотека пустая | zurg ещё не прочитал файлы. Подожди, пока загрузится библиотека zurg. Если zurg пишет `segmentation fault`, обнови и перезапусти его, как в [шаге 1](#step-1-install-zurg) |
| Названия фильмов — это имена файлов, постеров нет | rex не привязан к аккаунту Plex. Сделай [шаг 3](#step-3-add-it-to-a-plex-account). Если ты привязал его уже после того, как zurg отправил файлы, они получат нормальные названия сами, как только привязка пройдёт |
| Фильм назван как его файл, или эпизод лежит в сериале, названном по релизу | zurg не смог определить, куда его отнести. Без `dmm_api_key` это значит, что поиск по названию ничего не нашёл. С ключом DMM ещё не определил файл, и zurg спросит снова через день. Дашборд zurg показывает, в чём дело: на странице релиза в **Torrent Manager** есть строка **Placement** (**Unplaced**, **Not asked yet**) и кнопка **Place again**. Нераспознанному релизу там можно указать IMDb id. **Fix Match** исправляет вручную |
| Название попало не в тот сериал или сопоставлено не с тем фильмом | DMM определил неправильно. Если задан `dmm_api_key`, zurg спрашивает DMM снова раз в неделю. Это помогает, когда DMM уже научился лучше. Пока этого не произошло, а без ключа — всегда, используй **Fix Match** в приложении Plex, войдя под новым аккаунтом, которому принадлежит rex. rex отклоняет это (403) для аккаунтов, с которыми им поделились |
| Каждое название не работает на всех устройствах, часто с сообщением "This server is not powerful enough to convert video", а в логе rex после нажатия Play появляется `upstream failed` или `502` (если настроен FFmpeg, то `TRANSCODE ... exited` с отказом в соединении или тайм-аутом) | rex не может достучаться до zurg по адресу, который zurg ему передал, и FFmpeg это не исправит. `curl -s http://192.168.1.20:32400/rex/sources` показывает этот адрес как `url` zurg. На машине с rex выполни `curl -I` по нему: любой HTTP-ответ, включая `401`, — это нормально. `Failed to connect` значит, что rex не может достучаться до zurg. Адрес `172.` — это адрес контейнера. zurg в Docker Desktop на Windows или macOS: удали его и установи zurg, как в [шаге 1](#step-1-install-zurg). zurg в Docker на Linux, а rex на другой машине: дай его контейнеру `network_mode: host`, как в [D4](#d4-connect-zurg-to-rex). Новые сборки говорят об этом прямо: rex пишет `SOURCES zurg: cannot reach ... from this machine`, а zurg пишет `rex feed: rex cannot reach zurg at ...` |
| В логе rex `upstream failed: no source ... configured` | rex не получил регистрацию от zurg. Перезапусти zurg ([шаг 4](#step-4-connect-zurg-to-rex)), чтобы он зарегистрировался снова |
| В логе rex `part ... is unavailable upstream` | У zurg сейчас нет такого файла: он ещё загружает библиотеку или релиз пропал из твоего аккаунта debrid |
| Ничего не играет, в логе rex `PART ... upstream 401` или `403` | zurg отклонил собственный вход. Перезапусти zurg ([шаг 4](#step-4-connect-zurg-to-rex)), чтобы он отправил rex актуальный |
| Некоторые файлы не работают с "This server is not powerful enough to convert video", часто только в веб-браузере | Устройство не может воспроизвести файл как есть. Попробуй приложение Plex на телевизоре или телефоне либо настрой [Конвертацию видео](#converting-video-optional) |
| Файл Dolby Vision не работает, а в логе rex `DoVi (Profile 5) color space is not supported` | У rex нет FFmpeg или стоит не jellyfin-ffmpeg. Установи jellyfin-ffmpeg, как показано в [Конвертации видео](#converting-video-optional), и оставь включённым **Enable HDR tone mapping** (Settings, Transcoder) |
| rex завершается с `cannot bind ...:32400 (another rex or Plex on this port? ...)` | Порт занят другой программой. Если на этой машине работает Plex Media Server, используй `--port 32500`, как сказано в [шаге 2](#step-2-install-rex). Если это другой rex, например запущенный вручную, останови его |
| Устройство дома не подключается, а строка `heartbeat ... ->` в логе rex не содержит `http://192.168.1.20:32400` | rex объявляет частный адрес сети, через которую он выходит в интернет. За VPN или Tailscale exit node это не твоя домашняя сеть. Добавь в конец команды запуска rex ([шаг 2](#step-2-install-rex)) `--announce-url http://192.168.1.20:32400` и перезапусти rex |
| Дома app.plex.tv не достучивается до rex, и адрес `lan.` из [Что вы должны видеть](#what-you-should-see) не отвечает | Некоторые роутеры и DNS-фильтры блокируют публичное имя, которое указывает на домашний адрес (защита от DNS rebind). Разреши там `rex-direct.debridmediamanager.com`, как пользователи Plex разрешают `plex.direct` |
| Другая машина не достучивается до rex в Windows, хотя правила файрвола из шага 2 есть | Если ты когда-либо нажал **Cancel**, когда Windows спрашивала, разрешать ли rex, Windows сохранила правило, которое его блокирует. Оно важнее правил портов. Удали его в PowerShell от имени администратора: <code>Get-NetFirewallApplicationFilter -Program "$HOME\rex\rex.exe" &#124; Get-NetFirewallRule &#124; Where-Object Action -eq Block &#124; Remove-NetFirewallRule</code> (если rex лежит в другом месте, укажи его путь) |
| rex не виден в приложениях Plex вне дома | Не привязан, или устройство не может достучаться до HTTPS-адреса. Адрес только для tailnet требует Tailscale на этом устройстве; [rex-direct по IPv6](#rex-direct-over-ipv6) требует IPv6 в сети этого устройства |
| В логе `waiting for a claim` | Сделай [шаг 3](#step-3-add-it-to-a-plex-account) |
| rex завершается с `argument --announce-url: '...' is not an http:// or https:// address` | Передай `--announce-url` только адрес, например `https://myhost.tailnet.ts.net:443`. Без квадратных скобок, кавычек или ссылки вокруг |
| zurg останавливается при выходе из системы | В Linux выполни `sudo loginctl enable-linger "$USER"` (шаг 1) |
| zurg не запускается после правки `config.yml` | Ключ уже был в файле, и zurg пишет `mapping key "..." already defined`. Удали один из двух |
