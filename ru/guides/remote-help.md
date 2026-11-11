# Получение помощи по zurg и rex {#getting-help-with-zurg-and-rex}

## Спросите в Discord {#ask-in-discord}

Напиши пост в [Discord](https://discord.com/invite/7u4YjMThXP) на форуме, в том канале, которым пользуешься: **zurg-support**, **rex-support** или **dmm-support**. Открывай отдельную ветку на каждую проблему. Расскажи, что ты сделал, чего ожидал и что в итоге случилось. Добавь детали ниже.

**Для zurg** нажми **Export Logs** на дашборде zurg и вставь ссылки, которые он выдаст. Он загрузит лог и конфиг zurg, предварительно убрав твои токены, пароли и API-ключи. Если загрузить не получается, **Download Logs** даст тебе то же самое в виде файла, который можно прикрепить. Также вставь то, что выводит `zurg doctor`:

| zurg запускается как | Команда |
|---|---|
| Бинарник на Linux или macOS | `./zurg doctor` в папке zurg |
| Бинарник на Windows | `.\zurg.exe doctor` в папке zurg |
| Docker | `docker compose exec zurg /app/zurg doctor --working-dir /config` |

**Для rex** нажми Play один раз на то, что не работает, и вставь конец лога rex. rex маскирует токены Plex в логе.

| rex запускается как | Команда |
|---|---|
| Сервис systemd на Linux | `journalctl --user -u rex -n 200 --no-pager` |
| launchd на macOS | `tail -n 200 ~/rex/rex.log` |
| Task Scheduler на Windows | `Get-Content $HOME\rex\rex.log -Tail 200` |
| Docker | `docker compose logs --tail=200 rex` |
| Терминальное окно | Последние 200 строк в этом окне |

В длинном логе важнее всего строки с ошибками, предупреждениями и тем, что rex решил для каждого воспроизведения. Чтобы показать только их, добавь `| grep -E 'ERROR|WARN|upstream|DECISION'` к команде для Linux, macOS или Docker. На Windows выполни `Select-String 'ERROR|WARN|upstream|DECISION' $HOME\rex\rex.log | Select-Object -Last 50`.

## Удалённая помощь для спонсоров {#remote-help-for-sponsors}

Когда тред не помогает, помощник может печатать в вашем терминале, пока вы смотрите. **Удалённая помощь с zurg и rex предназначена для спонсоров и бесплатна.** [Станьте спонсором на gatekeeper](https://gatekeeper.debridmediamanager.com/). Там же подключите Discord, чтобы получить роль спонсора, а затем задайте вопрос в своём треде поддержки.

Эта страница настраивает всё с помощью [upterm](https://github.com/owenthereal/upterm) через `upterm.debridmediamanager.com`. Работает на Linux, macOS и Windows.

Не нужны пароль от аккаунта, изменение настроек роутера или предварительная установка. Команды сами скачают и запустят upterm. Следите за каждой командой в том же терминале. Чтобы завершить сеанс, введите `exit`.

### 1. Выберите машину {#1-pick-the-machine}

Запусти upterm на машине, где работают zurg или rex. Это может быть сервер, а не компьютер, за которым ты сидишь.

| Где это работает | Что делать |
|---|---|
| Этот компьютер | Открой здесь терминал и переходи к шагу 2. |
| Облачный сервер вроде Hetzner, Oracle или VPS | Сначала подключись к нему по SSH. Потом в этом окне SSH используй строку для Linux из шага 2. |
| NAS или домашний сервер вроде Synology или Unraid | Открой его терминал. Потом используй там строку для Linux из шага 2. |
| Docker | Используй машину, на которой запущен Docker, а не контейнер. |

SSH можно использовать и в Windows. В PowerShell `ssh` уже есть.

```bash
ssh you@your-server
```

На **Synology** SSH по умолчанию выключен. Включи его в Control Panel > Terminal & SNMP > Enable SSH service. Потом войди под учётной записью администратора. Адрес NAS возьми из роутера или из Synology Assistant.

Если на Synology на шаге 2 появляется `cannot create directory`, включи Control Panel > User & Group > Advanced > Enable user home service и запусти команду ещё раз.

На **Unraid** терминал есть на веб-странице. Нажми на иконку `>_` в правом верхнем углу.

### 2. Начните сеанс {#2-start-a-session}

Вставьте строку для системы, которую вы выбрали на шаге 1.

#### Linux и macOS {#linux-and-macos}

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

#### Windows

Откройте PowerShell. Запускать его от имени администратора не нужно.

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz" -UseBasicParsing; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

На ARM-ноутбуке, например Surface Pro X, замените `amd64` на `arm64`.

При первом запуске upterm спросит, доверять ли `upterm.debridmediamanager.com`. Введите `yes`. Отпечаток, который он покажет, должен совпадать с этим.

```
SHA256:r1LtSiydnfetLGxGt8hy+ULyqtN2KgnZSHtRgHzDr58
```

### 3. Отправьте строку SSH вашему помощнику {#3-send-the-ssh-line-to-your-helper}

upterm выводит несколько строк. Скопируйте ту, что под **SSH**, она выглядит так.

```
ssh AbCdEfGhIjKlMnOpQrSt:dXB0ZXJt...@upterm.debridmediamanager.com -p 2222
```

**Отправьте её в личном сообщении.** Никогда не публикуйте её в общем канале. Любой, у кого она есть, может печатать на вашей машине.

Затем оставьте окно открытым и не кликайте внутри него: в Windows клик в окне PowerShell может приостановить выполняющиеся там команды, пока вы не нажмёте `Esc`. Вы видите всё, что ваш помощник печатает в этом окне, в тот момент, когда он печатает.

### 4. Завершите сеанс {#4-end-it}

**Когда закончите, введите `exit` в этом окне.** Сессия завершится, и строка подключения сразу перестанет работать.

Простого закрытия окна недостаточно: сессия продолжает работать. Если вы уже закрыли окно, откройте новый терминал, выполните `~/upterm/upterm session list` (в Windows `& "$env:LOCALAPPDATA\upterm\upterm.exe" session list`), а затем ту же программу с `session stop` и именем, которое она покажет.

Чтобы снова получить помощь позже, вставьте строку из шага 2. У каждой сессии своя новая строка.

## Для помощников {#for-helpers}

Запустите строку SSH, которую вам прислали. Подойдёт любой SSH-ключ; если у вас его нет, сначала один раз выполните `ssh-keygen -t ed25519`. Вы окажетесь в их терминале: PowerShell в Windows, а в Linux и macOS — их обычная оболочка.

Чтобы скопировать файл, `:` в ID сессии сбивает `scp`, поэтому передайте его как пользователя: `scp -P 2222 -o User=<everything before the @> file upterm.debridmediamanager.com:file`.

Когда закончите, попросите их ввести `exit`.
