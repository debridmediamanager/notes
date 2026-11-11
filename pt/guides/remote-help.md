# Obtendo ajuda com zurg e rex {#getting-help-with-zurg-and-rex}

## Pergunte no Discord {#ask-in-discord}

Poste no fórum do [Discord](https://discord.com/invite/7u4YjMThXP) o que você usa: **zurg-support**, **rex-support** ou **dmm-support**. Abra uma thread para cada problema. Conte o que você fez, o que esperava e o que aconteceu. Inclua os detalhes abaixo.

**Para o zurg**, clique em **Export Logs** no painel do zurg e cole os links que ele mostrar. Ele envia o log e a configuração do zurg com seus tokens, senhas e chaves de API removidos. Se não conseguir enviar, **Download Logs** gera o mesmo conteúdo em um arquivo que você pode anexar. Cole também o que `zurg doctor` mostra:

| O zurg roda como | Execute |
|---|---|
| O binário no Linux ou macOS | `./zurg doctor` na pasta do zurg |
| O binário no Windows | `.\zurg.exe doctor` na pasta do zurg |
| Docker | `docker compose exec zurg /app/zurg doctor --working-dir /config` |

**Para o rex**, aperte Play uma vez no que está falhando e depois cole o final do log do rex. O rex mascara os tokens do Plex nele.

| O rex roda como | Execute |
|---|---|
| Um serviço systemd no Linux | `journalctl --user -u rex -n 200 --no-pager` |
| launchd no macOS | `tail -n 200 ~/rex/rex.log` |
| Task Scheduler no Windows | `Get-Content $HOME\rex\rex.log -Tail 200` |
| Docker | `docker compose logs --tail=200 rex` |
| Uma janela de terminal | As últimas 200 linhas dessa janela |

Em um log longo, as linhas mais importantes são os erros, os avisos e o que o rex decidiu para cada reprodução. Adicione `| grep -E 'ERROR|WARN|upstream|DECISION'` à linha do Linux, macOS ou Docker para mostrar só essas, ou no Windows execute `Select-String 'ERROR|WARN|upstream|DECISION' $HOME\rex\rex.log | Select-Object -Last 50`.

## Ajuda remota para apoiadores {#remote-help-for-sponsors}

Quando um tópico não resolver, um ajudante pode digitar no seu terminal enquanto você acompanha. **Ajuda remota com zurg e rex é para patrocinadores e é gratuita.** [Torne-se patrocinador no gatekeeper](https://gatekeeper.debridmediamanager.com/). Conecte o Discord por lá para receber o cargo de patrocinador e depois peça ajuda no seu tópico de suporte.

Esta página configura isso com o [upterm](https://github.com/owenthereal/upterm) pelo `upterm.debridmediamanager.com`. Funciona no Linux, macOS e Windows.

Você não precisa de senha de conta, de mudar nada no roteador nem de instalação prévia. Os comandos baixam e iniciam o upterm. Acompanhe cada comando no mesmo terminal. Digite `exit` para encerrar a sessão.

### 1. Escolha a máquina {#1-pick-the-machine}

Execute o upterm na máquina que roda o zurg ou o rex. Pode ser um servidor e não o computador que está na sua frente.

| Onde roda | O que fazer |
|---|---|
| Este computador | Abra um terminal aqui e vá para o passo 2. |
| Um servidor na nuvem, como Hetzner, Oracle ou VPS | Faça SSH nele primeiro. Depois use a linha do Linux do passo 2 nessa janela de SSH. |
| Um NAS ou servidor em casa, como Synology ou Unraid | Abra o terminal dele. Depois use a linha do Linux do passo 2 ali. |
| Docker | Use a máquina que roda o Docker e não um container. |

Você também pode usar SSH no Windows. O PowerShell já tem o `ssh` embutido.

```bash
ssh you@your-server
```

No **Synology**, o SSH vem desligado por padrão. Ligue em Control Panel > Terminal & SNMP > Enable SSH service. Depois entre com uma conta de administrador. Use o endereço do NAS que está no seu roteador ou no Synology Assistant.

Se o passo 2 mostrar `cannot create directory` no Synology, ative em Control Panel > User & Group > Advanced > Enable user home service e rode de novo.

No **Unraid**, o terminal fica na própria página web. Clique no ícone `>_` no canto superior direito.

### 2. Inicie uma sessão {#2-start-a-session}

Cole aqui a linha do sistema que você escolheu no passo 1.

#### Linux e macOS {#linux-and-macos}

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

#### Windows

Abra o PowerShell. Ele não precisa ser executado como administrador.

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz" -UseBasicParsing; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

Em um laptop ARM, como o Surface Pro X, troque `amd64` por `arm64`.

Na primeira vez, o upterm pergunta se você quer confiar em `upterm.debridmediamanager.com`. Digite `yes`. A impressão digital que ele mostrar deve ser esta.

```
SHA256:r1LtSiydnfetLGxGt8hy+ULyqtN2KgnZSHtRgHzDr58
```

### 3. Envie a linha SSH para quem vai te ajudar {#3-send-the-ssh-line-to-your-helper}

upterm mostra algumas linhas. Copie a que fica embaixo de **SSH**, que tem este formato.

```
ssh AbCdEfGhIjKlMnOpQrSt:dXB0ZXJt...@upterm.debridmediamanager.com -p 2222
```

**Envie em uma mensagem privada.** Nunca poste em um canal público. Quem tiver essa linha pode digitar no seu computador.

Depois, deixe a janela aberta e não clique dentro dela: no Windows, um clique em uma janela do PowerShell pode pausar o que está rodando nela até você apertar `Esc`. Você vê tudo o que a sua pessoa de apoio digita nessa janela, conforme ela digita.

### 4. Encerre a sessão {#4-end-it}

**Digite `exit` nessa janela quando terminar.** A sessão termina e a linha para de funcionar na hora.

Fechar a janela não basta: a sessão continua rodando. Se você fechou, abra um novo terminal, rode `~/upterm/upterm session list` (no Windows, `& "$env:LOCALAPPDATA\upterm\upterm.exe" session list`) e depois o mesmo programa com `session stop` e o nome que ele mostrar.

Para pedir ajuda de novo depois, cole de novo a linha do passo 2. Cada sessão recebe uma linha nova.

## Para quem ajuda {#for-helpers}

Execute a linha SSH que você recebeu. Qualquer chave SSH serve; se você não tiver nenhuma, execute `ssh-keygen -t ed25519` uma vez antes. Você cai no terminal deles: PowerShell no Windows, o shell normal deles no Linux e no macOS.

Para copiar um arquivo, o `:` do ID da sessão confunde o `scp`, então passe ele como usuário: `scp -P 2222 -o User=<everything before the @> file upterm.debridmediamanager.com:file`.

Peça para eles digitarem `exit` quando você terminar.
