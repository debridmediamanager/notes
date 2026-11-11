# Tutorial para macOS {#macos-tutorial}

## Opção de uma linha {#one-line-option}

The optional sponsor bootstrap installs macFUSE when needed, downloads the Intel or Apple silicon build, and runs
the provider chooser and diagnostics:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

It uses GitHub browser sign-in. macOS may still need approval under **System Settings > Privacy & Security** and a
reboot. Existing binaries and configs stay in place. Continue below for the manual route.

## Passo 1: Instalar o macFUSE {#step-1-install-macfuse}

O macFUSE permite que o rclone monte o sistema de arquivos virtual do zurg como um diretório real no seu Mac.

1. Baixe a versão mais recente do `.dmg` em [macfuse.io](https://macfuse.io)
2. Abra o `.dmg` e execute o instalador
3. Durante a instalação, o macOS vai bloquear a extensão de sistema. Vá em **System Settings > Privacy & Security**, role para baixo e clique em **Allow**
4. **Reinicie seu Mac** (necessário para a extensão de kernel carregar)

Depois de reiniciar, abra o **Terminal** (pressione `Cmd + Space`, digite "Terminal" e pressione Enter) e verifique se o macOS vai carregar o macFUSE. É a mesma verificação que o `zurg setup` faz:

```bash
/Library/Filesystems/macfuse.fs/Contents/Resources/load_macfuse && echo "macFUSE is ready"
```

Se `macFUSE is ready` não aparecer, o macOS ainda não permitiu a extensão. Em Macs com Apple silicon, ative as extensões de kernel de terceiros no Recovery, permita o macFUSE em **System Settings > Privacy & Security** e depois reinicie e verifique de novo.

## Passo 2: Baixar o zurg {#step-2-download-zurg}

Abra o [GitHub Releases](https://github.com/debridmediamanager/zurg/releases) em um navegador em que você esteja logado na conta do GitHub que tem acesso ao zurg. Pegue a nightly mais recente. Ela é a pré-release no topo da lista. Baixe o zip `darwin-arm64` ou `darwin-amd64` se você tiver um Mac Intel. Não pegue a release que o GitHub marca como **Latest**. Essa é a v1.0.0. Ela é mais antiga que o `zurg setup` e responde com `unknown command`.

As nightlies são para apoiadores. Até a sua conta do GitHub ter acesso, essa página responde 404. Apoie no [gatekeeper](https://gatekeeper.debridmediamanager.com/) para liberar o acesso. A build pública gratuita é a v1.0.0, em [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). Ela não tem o `zurg setup`. Configure-a manualmente como o [README dela](https://github.com/debridmediamanager/zurg-public#readme) explica, em vez de seguir os passos abaixo.

Depois, descompacte.

```bash
mkdir -p ~/zurg && cd ~/zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
```

Verifique:

```bash
./zurg version
```

## Recomendado: deixe o zurg concluir a configuração {#recommended-let-zurg-finish-the-setup}

```bash
./zurg setup
./zurg doctor
```

`setup` pergunta quais provedores você quer configurar. Escolha um ou vários entre Real-Debrid, TorBox, AllDebrid, Usenet, Premiumize, Debrid-Link e Offcloud, na ordem de prioridade. Por exemplo, digite `2,4` para TorBox seguido de Usenet. Ele pede apenas as credenciais dos provedores escolhidos, cria o `config.yml` com modo `0600`, baixa o rclone (e o ffprobe, a menos que você já tenha um no seu PATH), prepara o `/Volumes/Zurg` e instala a inicialização automática.

Ele escolhe um LaunchAgent quando o usuário atual tem um domínio GUI do launchd. Em um Mac sem interface gráfica, sem nenhum usuário logado, ele instala um LaunchDaemon do sistema que continua executando o zurg como o usuário atual. Esse caminho não exige login automático.

A verificação de pré-requisitos diferencia um pacote macFUSE instalado de uma extensão que o macOS realmente consegue carregar. Em Macs com Apple silicon, a primeira instalação do macFUSE pode exigir uma alteração de segurança única no Recovery, a aprovação em **System Settings > Privacy & Security** e uma reinicialização. Nenhum instalador consegue contornar essas confirmações.

O setup pode ser executado novamente com segurança. Ele atualiza o serviço do launchd gerado, mas não substitui um `config.yml` que já exista.

Antes de fazer streaming pelo mount, abra o `config.yml` ou o Dashboard em `http://localhost:9999/config/` e defina `--vfs-cache-max-size` e `--vfs-cache-min-free-space` em `rclone_extra_args`. Mantenha o tamanho máximo abaixo da metade do espaço livre atual em disco e reserve pelo menos `20G` com a configuração de espaço livre mínimo. Depois, execute `./zurg service restart`.

O restante desta página explica a configuração do config e a configuração do Plex. Os passos 3, 4, 5 e 7 são a alternativa manual e podem ser ignorados depois que o `zurg setup` for concluído com sucesso.

## Passo 3: Configurar o zurg manualmente {#step-3-configure-zurg-manually}

Crie um arquivo de configuração com o seu token de API do Real-Debrid:

```bash
cd ~/zurg
cat > config.yml << 'EOF'
# Minimal config - use Dashboard at http://localhost:9999/config/ for more settings
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN_HERE

rclone_enabled: true
mount_path: /Volumes/Zurg

rclone_extra_args:
  - "--vfs-cache-max-size"
  - "100G"
  - "--vfs-cache-min-free-space"
  - "20G"

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
EOF
```

Substitua o token de exemplo pelo seu token real, que você encontra em [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354):

```bash
sed -i '' "s|YOUR_RD_API_TOKEN_HERE|PASTE_YOUR_TOKEN_HERE|g" ~/zurg/config.yml
```

> **Não remova `mount_path`.** Sem ele, o rclone usaria `/Volumes/Zurg` no macOS, mas a varredura do servidor de mídia só é ativada quando `mount_path` está definido explicitamente. Se você deixar de fora, o Plex nunca será avisado para atualizar (Passo 6).

> **O tamanho do cache é essencial.** O cache do VFS guarda partes dos arquivos em streaming no seu disco local. Se ele encher o disco, o desempenho do macOS cai muito: Spotlight, Plex e até o próprio sistema podem parar de responder. Sempre defina **os dois** limites:
>
> - `--vfs-cache-max-size`: limite máximo do tamanho total do cache. Defina no máximo **50% do seu espaço livre em disco**. Verifique com `df -h /`.
> - `--vfs-cache-min-free-space`: para de gravar no cache quando o espaço livre cair abaixo deste valor. Mantenha em **20G ou mais** como uma rede de segurança.
>
> Por exemplo, em um drive de 256GB com 100GB livres, use `50G` como tamanho máximo e `20G` como espaço livre mínimo.

## Passo 4: Baixar as dependências manualmente {#step-4-download-dependencies-manually}

zurg tem um comando embutido que baixa o rclone e o ffprobe e atualiza o `config.yml` com os caminhos deles:

```bash
cd ~/zurg
./zurg download-requirements
```

Crie o ponto de montagem e o diretório de logs. `/Volumes` pertence ao root, então o zurg não consegue criar `/Volumes/Zurg` sozinho. O diretório de logs precisa existir antes do launchd abrir os arquivos de saída no Passo 7:

```bash
sudo mkdir -p /Volumes/Zurg
sudo chown "$(whoami)" /Volumes/Zurg
mkdir -p ~/zurg/logs
```

Veja [a referência de configuração](../reference/config.md) para todas as opções disponíveis, ou use o Dashboard web em `http://localhost:9999/config/` depois de iniciar o zurg.

## Passo 5: Testar o zurg manualmente {#step-5-test-zurg-manually}

Antes de configurar a inicialização automática, verifique se tudo funciona:

```bash
cd ~/zurg && ./zurg
```

Você deve ver a saída de log mostrando o zurg iniciando, conectando ao Real-Debrid e montando via rclone. Em outra janela do terminal, verifique:

```bash
# Check the HTTP endpoint
curl -s http://localhost:9999/http/version.txt

# Check the mount
ls /Volumes/Zurg/
# Expected: __all__  __downloads__  __unplayable__  movies  shows  version.txt
```

Se tudo estiver certo, pare o zurg com `Ctrl+C`.

## Passo 6: Instalar o Plex Media Server {#step-6-install-plex-media-server}

1. Baixe em [plex.tv/media-server-downloads](https://www.plex.tv/media-server-downloads/) — selecione **macOS** (Universal)
2. Abra o `.dmg` e arraste **Plex Media Server** para `/Applications`
3. Abra o Plex Media Server pela pasta Applications (ou pelo Spotlight: `Cmd + Space` → "Plex Media Server")
4. Seu navegador deve abrir o assistente de configuração do Plex — siga os passos para vincular seu servidor
5. **Ative a inicialização automática:** clique com o botão direito no ícone do Plex na barra de menus e marque **Launch at Login**
6. Pegue seu token do Plex — o jeito mais fácil:
   - Abra qualquer item de mídia no Plex Web
   - Clique em **Get Info** (ou **...** → **Get Info**)
   - Clique em **View XML**
   - Procure por `X-Plex-Token=` na barra de endereço

Adicione o token do Plex na sua configuração do zurg editando o `config.yml`:

```yaml
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
```

## Passo 7: Configurar o início automático do zurg manualmente {#step-7-set-up-zurg-auto-start-manually}

LaunchAgents iniciam serviços automaticamente quando você faz login. O Plex já cuida do próprio início automático (Passo 6), então só precisamos de um LaunchAgent para o zurg.

### LaunchAgent do zurg {#zurg-launchagent}

```bash
cat > ~/Library/LaunchAgents/com.zurg.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zurg</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/zurg/zurg</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${HOME}/zurg</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME}/zurg/logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME}/zurg/logs/launchd-stderr.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST
```

Configurações principais:
- **RunAtLoad** — inicia o zurg quando você faz login
- **KeepAlive / SuccessfulExit: false** — se o zurg travar, o launchd o reinicia automaticamente
- **ThrottleInterval: 10** — espera 10 segundos entre as tentativas de reinício

### Carregar o LaunchAgent {#load-the-launchagent}

```bash
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Verifique se ele está registrado:

```bash
launchctl list | grep zurg
# Should show com.zurg with a PID
```

## Passo 8: Configurar as bibliotecas do Plex {#step-8-configure-plex-libraries}

Agora que o zurg está rodando e o mount está ativo:

1. Abra [http://localhost:32400/web](http://localhost:32400/web)
2. Vá em **Settings** (ícone de chave inglesa) → **Manage** → **Libraries**
3. Clique em **Add Library**

**Adicione a biblioteca de Filmes:**
- Type: **Movies**
- Clique em **Browse for media folder**
- Navegue até `/Volumes/Zurg/movies`
- Clique em **Add Library**

**Adicione a biblioteca de Séries:**
- Type: **TV Shows**
- Clique em **Browse for media folder**
- Navegue até `/Volumes/Zurg/shows`
- Clique em **Add Library**

**Configurações recomendadas da biblioteca** (em Edit → Advanced de cada biblioteca):
- Desmarque **Empty trash automatically after every scan** — o zurg cuida do ciclo de vida do conteúdo
- Desmarque **Generate video preview thumbnails** — economiza banda, já que os arquivos são transmitidos do Real-Debrid

## Passo 9: Verificar se tudo funciona {#step-9-verify-everything-works}

```bash
# 1. zurg is running
curl -s http://localhost:9999/http/version.txt && echo " - zurg is up"

# 2. Mount is active
ls /Volumes/Zurg/movies > /dev/null 2>&1 && echo "Mount is active"

# 3. Plex is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:32400/identity && echo " - Plex is up"

# 4. Processes
ps -eo pid,command | grep -E "[z]urg|[r]clone.*mount|[P]lex Media Server" | head -5

# 5. zurg service (for the manual LaunchAgent from Step 7: launchctl list | grep com.zurg)
cd ~/zurg && ./zurg service status
```

## Passo 10: Ativar o login automático (opcional) {#step-10-enable-auto-login-optional}

Isso só é necessário para o caminho manual do LaunchAgent. Um LaunchAgent exige que o usuário faça login depois de cada reinicialização. O instalador integrado usa um LaunchDaemon em um Mac headless.

Se você usar o LaunchAgent manual de propósito em um servidor headless, ative o login automático para que ele inicie sem intervenção:

1. Abra **System Settings**
2. Vá em **Users & Groups**
3. Clique em **Automatic login** e selecione seu usuário
4. Digite sua senha

> **Nota de segurança:** O login automático significa que qualquer pessoa com acesso físico ao Mac consegue acessar sua conta. Use isso só em máquinas em um local de confiança.

---

## Gerenciando os serviços {#managing-the-services}

Para uma instalação criada pelo `zurg setup`, use os mesmos comandos em todas as plataformas:

```bash
cd ~/zurg
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` remove apenas o início automático. Ele deixa o binário, a configuração, os dados, os logs e o cache no lugar. Os comandos launchctl abaixo são para o LaunchAgent manual do Passo 7 (`com.zurg`). O `zurg setup` usa o nome `com.zurg.zurg` para o dele.

### Iniciar / Parar / Reiniciar {#start--stop--restart}

```bash
# Stop zurg (and its rclone child process)
launchctl stop com.zurg

# Start zurg
launchctl start com.zurg

# Restart zurg
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Ver os logs {#view-logs}

```bash
# zurg logs
tail -50 ~/zurg/logs/zurg.log

# Rclone logs
tail -50 ~/zurg/logs/rclone.log
```

### Recarregar após alterar a configuração {#reload-after-config-change}

Se você editar um arquivo `.plist`:

```bash
launchctl unload ~/Library/LaunchAgents/com.zurg.plist
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Se você editar o `config.yml`, basta reiniciar o zurg:

```bash
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Atualizar o zurg {#update-zurg}

A build de patrocinador se substitui sozinha:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` pega o nightly mais recente. Ele baixa, confere se o novo binário informa a versão esperada e só então o troca por renomeação, para que o processo em execução nunca seja sobrescrito. Quando o build instalado já é o mais recente, ele avisa e não muda nada.

`update` faz login no GitHub com a conta que você usou na instalação. O instalador mantém a GitHub CLI em `~/zurg/bin` para isso. Se o `update` disser que não encontrou nenhuma credencial do GitHub, sua instalação é anterior a essa mudança. Rode a atualização do instalador uma vez e todo `zurg update` a partir daí vai funcionar. O mesmo comando também atualiza um build antigo demais para ter `zurg update`.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

Você também pode definir `GITHUB_TOKEN`. Use um token clássico com o escopo `repo`, da conta do GitHub que tem acesso ao zurg.

Manualmente, baixe o zip `darwin-arm64` mais recente (`darwin-amd64` em um Mac Intel) em [Releases](https://github.com/debridmediamanager/zurg/releases) do mesmo jeito que no Passo 2, e depois:

```bash
cd ~/zurg
./zurg service stop && sleep 2     # manual LaunchAgent: launchctl stop com.zurg
rm -f zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
./zurg service start               # manual LaunchAgent: launchctl start com.zurg
```

Apague o binário antigo em vez de sobrescrevê-lo no lugar. Reescrever o arquivo mantém o mesmo inode e invalida sua assinatura de código ad-hoc, e aí o macOS mata o novo build na hora do exec. O sintoma é uma saída imediata, sem nenhuma mensagem. Por isso o `zurg update` troca por renomeação.

## Solução de problemas {#troubleshooting}

### "Operation not permitted" ao montar {#operation-not-permitted-when-mounting}

macFUSE precisa ser aprovado nas Configurações do Sistema:
1. Vá em **Configurações do Sistema > Privacidade e Segurança**
2. Role a página para baixo e procure a mensagem sobre uma extensão de sistema bloqueada
3. Clique em **Allow**, depois **reinicie** o computador

### A montagem aparece como "not a directory" ou trava {#mount-shows-as-not-a-directory-or-hangs}

O ponto de montagem pode estar travado (stale) por causa de uma queda anterior:

```bash
umount -f /Volumes/Zurg 2>/dev/null
diskutil unmount force /Volumes/Zurg 2>/dev/null
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### O zurg reinicia sem parar (loop de falha) {#zurg-keeps-restarting-crash-loop}

Verifique os logs para encontrar o erro:

```bash
tail -100 ~/zurg/logs/service-stderr.log   # manual LaunchAgent: launchd-stderr.log
```

Causas comuns:
- Sintaxe inválida no `config.yml`. Valide executando `cd ~/zurg && ./zurg` manualmente
- Token do Real-Debrid expirado. Gere um novo em [real-debrid.com/apitoken](http://real-debrid.com/?id=20476410)
- `/Volumes/Zurg` não existe ou não pertence ao seu usuário. O zurg não consegue criá-lo e falha com `ensure mount path: permission denied` (Passo 4)
- Porta 9999 já em uso. Verifique com `lsof -i :9999`

### O macFUSE para de funcionar após atualização do macOS {#macfuse-breaks-after-macos-update}

Atualizações grandes do macOS às vezes invalidam a extensão de kernel. Reinstale o macFUSE:
1. Baixe a versão mais recente em [macfuse.io](https://macfuse.io)
2. Instale
3. Aprove a extensão em **System Settings > Privacy & Security**
4. Reinicie

### Tudo funcionava, mas parou depois de reiniciar {#everything-was-working-but-stopped-after-reboot}

Se você instalou o LaunchAgent manual e o login automático não está ativado, é preciso fazer login antes de ele iniciar. Você pode:
- Ativar o login automático (veja o Passo 10)
- Entrar por SSH — os LaunchAgents já vão estar carregados assim que a sessão do usuário existir
- Usar VNC/Screen Sharing para fazer login remotamente

Uma instalação criada pelo `zurg setup` em um Mac headless usa um LaunchDaemon e não precisa de login na interface gráfica. Verifique com `cd ~/zurg && ./zurg service status`.

Ainda com problemas? Pergunte no fórum **zurg-support** no [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) explica o que incluir.

## Visão geral da arquitetura {#architecture-overview}

```
launchd (PID 1)

  com.zurg LaunchAgent
    └── ./zurg
          ├── HTTP/WebDAV server (:9999)
          ├── Dashboard UI (:9999/config/)
          ├── Real-Debrid API client
          └── rclone mount (child process)
                └── /Volumes/Zurg/
                      ├── movies/
                      └── shows/

  Plex Media Server (:32400)  — Launch at Login via menu bar
    ├── Movies library  → /Volumes/Zurg/movies
    └── Shows library   → /Volumes/Zurg/shows

  macFUSE kernel extension
    └── Enables FUSE mounts for rclone
```

## Referência rápida {#quick-reference}

Execute estes comandos em `~/zurg`. As linhas `zurg service` são para uma instalação feita pelo `zurg setup`; o LaunchAgent manual usa os comandos launchctl em [Managing the Services](#managing-the-services).

| Ação | Comando |
|--------|---------|
| Iniciar o zurg | `./zurg service start` |
| Parar o zurg | `./zurg service stop` |
| Reiniciar o zurg | `./zurg service restart` |
| Verificar a instalação | `./zurg doctor` |
| Remover o início automático | `./zurg service uninstall` |
| Ver os logs do zurg | `tail -f ~/zurg/logs/zurg.log` |
| Ver os logs do rclone | `tail -f ~/zurg/logs/rclone.log` |
| Verificar o mount | `ls /Volumes/Zurg/` |
| Verificar a saúde do zurg | `curl http://localhost:9999/http/version.txt` |
| Verificar a saúde do Plex | `curl http://localhost:32400/identity` |
| Painel | `open http://localhost:9999/config/` |
| Forçar a desmontagem | `umount -f /Volumes/Zurg` |
