# Configuração do binário para Linux {#linux-binary-setup}

## Opção de uma linha {#one-line-option}

O bootstrap opcional do patrocinador instala pacotes do sistema, baixa a build de CPU certa e roda a configuração e os diagnósticos:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Ele faz login pelo GitHub e instala em `~/zurg`. Binários e configs que já existirem continuam no lugar. Continue abaixo para o caminho manual ou para um caminho personalizado.

O binário do zurg consegue montar o resto da instalação sozinho. Ele escreve a config, baixa o rclone correto (e o ffprobe, a menos que já exista um no seu PATH) para a máquina, cria o mount e registra um serviço do systemd habilitado.

Este fluxo foi verificado em 4 de setembro de 2026 em servidores Ubuntu 24.04 novos, tanto ARM64 quanto x86_64.

## 1. Instale o FUSE 3 {#1-install-fuse-3}

Em Debian, Ubuntu e derivados:

```bash
sudo apt-get update
sudo apt-get install -y fuse3
```

Outras distribuições também chamam o pacote de `fuse3`: `sudo dnf install fuse3` no Fedora, `sudo pacman -S fuse3` no Arch, `sudo zypper install fuse3` no openSUSE.

Verifique se o auxiliar e o dispositivo estão presentes:

```bash
command -v fusermount3
test -c /dev/fuse
```

Se o Plex, o Jellyfin ou outro processo rodar com um usuário Unix diferente, ative `allow_other` uma única vez:

```bash
echo user_allow_other | sudo tee -a /etc/fuse.conf
```

Sem essa configuração o mount ainda funciona, mas só a conta que executa o zurg consegue acessá-lo. `zurg doctor` mostra essa diferença.

## 2. Baixe o zurg {#2-download-zurg}

Baixe o arquivo Linux correspondente nas [releases de patrocinador](https://github.com/debridmediamanager/zurg/releases). Escolha `linux-amd64` para uma máquina Intel ou AMD e `linux-arm64` para uma máquina ARM.

Pegue o nightly mais recente. Ele é a pré-release no topo da lista. Não pegue a release marcada como **Latest** no GitHub. Essa é a v1.0.0. Ela é mais antiga que o `zurg setup` e responde a ele com `unknown command`.

Os nightlies são para patrocinadores. Até a sua conta do GitHub ter acesso, essa página mostra 404. Patrocine no [gatekeeper](https://gatekeeper.debridmediamanager.com/) para liberar o acesso. A build pública gratuita é a v1.0.0, das [releases do zurg-public](https://github.com/debridmediamanager/zurg-public/releases). Ela não tem `zurg setup`. Configure-a manualmente, como explica o [README dela](https://github.com/debridmediamanager/zurg-public#readme), em vez de seguir os passos abaixo.

Extraia tudo no diretório que deve conter a instalação completa:

```bash
mkdir -p ~/zurg
cd ~/zurg
# Put the downloaded zurg binary here, then:
chmod +x zurg
```

Tudo que o zurg guarda fica ao lado desse binário: `config.yml`, helpers baixados, estado da biblioteca, logs e o cache do rclone.

## 3. Execute a configuração {#3-run-setup}

```bash
cd ~/zurg
./zurg setup
```

O setup pergunta quais provedores você quer configurar. Escolha um ou vários, em ordem de prioridade:

```text
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
```

Por exemplo, digite `2,4` para TorBox seguido de Usenet. O setup pede só as credenciais dos provedores selecionados. Depois ele:

1. Cria e valida o `config.yml`.
2. Restringe o config ao dono usando o modo `0600`.
3. Baixa um rclone nativo para `bin/`, e o ffprobe também, a menos que um já esteja no seu PATH.
4. Ativa o mount do rclone em `/mnt/zurg`.
5. Instala e inicia um serviço systemd habilitado.

Use um mount dentro da sua pasta home se você não tiver permissão para criar `/mnt/zurg`:

```bash
./zurg setup --mount-path "$HOME/zurg-mount"
```

Você pode rodar o setup de novo sem problemas. Ele atualiza o serviço gerado, mas não substitui um `config.yml` que já exista.

### Escolhendo o escopo do systemd {#choosing-the-systemd-scope}

With a working systemd user manager, the default `auto` scope installs `~/.config/systemd/user/zurg.service`. Otherwise, setup installs `/etc/systemd/system/zurg.service` and asks sudo to run it as the current user.

Se precisar escolher manualmente:

```bash
./zurg setup --service-scope user
./zurg setup --service-scope system --service-user "$USER"
```

Para que um serviço de usuário inicie antes do primeiro login após uma reinicialização, habilite o lingering:

```bash
loginctl show-user "$USER" -p Linger
sudo loginctl enable-linger "$USER"
```

Rodar o setup como `root` em um servidor seleciona um serviço de sistema pertencente ao root.

## 4. Verifique a instalação {#4-verify-the-install}

```bash
./zurg doctor
curl -fsS http://127.0.0.1:9999/http/version.txt
ls /mnt/zurg/version.txt
```

`doctor` verifica a configuração e suas permissões, as duas ferramentas baixadas, o FUSE, a unit do systemd, o endpoint HTTP e o mount reportado pelo zurg.

Uma biblioteca grande do Real-Debrid leva um tempo para ser montada na primeira execução. O serviço pode já estar ativo enquanto a primeira listagem do mount espera essa varredura terminar.

`version.txt` responde assim que o zurg está rodando. Uma biblioteca grande continua carregando depois disso. Suas pastas aparecem vazias ou como `Input/output error` até terminar. O `/ready` te avisa quando isso acontecer.

```bash
curl -fsS http://127.0.0.1:9999/ready
```

## Disco que o mount usa {#disk-the-mount-uses}

O mount guarda em cache todo arquivo que lê, em `~/zurg/data/rclone-cache`. Ele mantém o arquivo inteiro depois que a reprodução termina. Se você não fizer nada, esse cache cresce até **256G** e fica assim. Ele não é limpo quando um vídeo para. O limite de 72h também não resolve, porque o rclone conta um arquivo como acessado sempre que alguma coisa o lê, e a manutenção noturna do servidor de mídia lê a biblioteca inteira.

Veja o que ele está guardando.

```bash
du -sh ~/zurg/data/rclone-cache
```

Se 256G for mais do que o disco pode suportar, então limite o tamanho em `config.yml`, com um valor menor.

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Reinicie o zurg depois. Para esvaziar o cache manualmente, pare o zurg primeiro e depois rode este comando.

```bash
rm -rf ~/zurg/data/rclone-cache/vfs/* ~/zurg/data/rclone-cache/vfsMeta/*
```

Se você mover o diretório do zurg, o cache é renomeado e a cópia antiga fica para trás. O zurg recupera esses arquivos na próxima inicialização e registra no log quanto espaço liberou. Os detalhes e como desativar isso estão em [a referência de configuração](../reference/config.md#disk-the-mount-uses).

## Gerenciando o zurg {#managing-zurg}

Execute estes comandos a partir do diretório do zurg:

```bash
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` remove apenas o início automático. O binário, a configuração, os dados, os logs e o cache continuam no lugar.

Para acompanhar os logs de um serviço de usuário:

```bash
journalctl --user -u zurg.service -f
```

Para um serviço de sistema:

```bash
sudo journalctl -u zurg.service -f
```

## Atualizando o zurg {#updating-zurg}

Uma build de patrocinador se substitui sozinha:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` pega a nightly mais recente. Ele baixa, confere se o novo binário informa a versão esperada e só então o troca pelo atual com um rename, assim o processo em execução nunca é sobrescrito. Se a build instalada já for a mais recente, ele avisa e não muda nada.

`update` faz login no GitHub com a conta que você usou na instalação. O instalador guarda a GitHub CLI em `~/zurg/bin` para isso. Se o `update` disser que não encontrou nenhuma credencial do GitHub, sua instalação é mais antiga que essa mudança. Rode a atualização do instalador uma vez, e todo `zurg update` depois disso vai funcionar. O mesmo comando também atualiza uma build antiga demais para ter `zurg update`. Ele só troca o binário e não mexe em mais nada.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

Num servidor sem a GitHub CLI, você pode definir `GITHUB_TOKEN`. Use um token clássico com o escopo `repo`, da conta do GitHub que tem acesso ao zurg.

## Configurações existentes e sem supervisão {#existing-and-unattended-configs}

O setup nunca substitui um `config.yml` que já existe.

Para o setup sem interação, repita `--provider` e informe os flags de arquivo de token correspondentes ou os `--nntp-*`. As variáveis `REALDEBRID_TOKEN`, `TORBOX_TOKEN`, `ALLDEBRID_TOKEN` e as `NNTP_*` também funcionam. Execute `./zurg setup --help` para ver a lista completa.

Veja a [Referência de configuração](../reference/config.md) para todas as configurações.

Ainda com dúvida? Pergunte no fórum **zurg-support** do [Discord](https://discord.com/invite/7u4YjMThXP). [Como pedir ajuda](../../guides/remote-help.md) explica o que incluir.

## Veja também {#see-also}

- [Docker](docker.md) — configuração do container e propagação do mount FUSE
- [macOS](macos.md) — o mesmo instalador de binário com macFUSE e launchd
- [Windows](windows.md) — o mesmo instalador de binário com WinFsp e uma tarefa agendada interativa
