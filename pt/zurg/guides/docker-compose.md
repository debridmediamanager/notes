# Um arquivo Docker Compose para zurg, Plex e rex {#one-docker-compose-file-for-zurg-plex-and-rex}

Em uma máquina Linux, um único `docker-compose.yml` pode rodar zurg, Plex Media Server e rex lado a lado. O zurg mostra sua biblioteca como pastas em `/zurg_mnt/zurg`, o Plex Media Server lê essas pastas, e o rex pega a mesma biblioteca direto do zurg, sem precisar de pastas. Rode o instalador Docker do zurg uma vez e depois troque o `docker-compose.yml` dele pelo de baixo.

Quer o Plex Media Server ou o rex, mas não os dois? Deixe o outro de fora do arquivo. Sem o Plex, apague também a linha `command:` do rex.

Docker Desktop no Windows ou no Mac não consegue rodar isso: as pastas do zurg nunca chegam ao Explorer ou ao Finder, e o rex não consegue alcançar um zurg que está dentro dele. Use [zurg no Windows](../setup/windows.md) ou [zurg no macOS](../setup/macos.md) nesses casos.

## Antes de começar {#before-you-start}

- **Uma máquina Linux** que fique ligada. O instalador adiciona o Docker se ele não estiver instalado.
- **Um apoio ao zurg.** A imagem do zurg é privada. Apoie no [gatekeeper](https://gatekeeper.debridmediamanager.com/) e ele dá acesso à sua conta do GitHub.
- **Seu token de API do Real-Debrid**, ou o login de outro serviço que o zurg suporta: [Seu token de API do Real-Debrid](../../guides/real-debrid-api-token.md).
- **Para o Plex Media Server**, sua conta do Plex. **Para o rex**, uma conta nova do Plex criada só para ele: [rex com zurg](../../rex/with-zurg.md#before-you-start) explica o motivo.

## 1. Execute o instalador Docker do zurg {#1-run-zurgs-docker-installer}

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Ele instala o Docker se ele não estiver presente (ele pergunta antes), deixa `/zurg_mnt` pronto para as pastas do zurg agora e depois de cada reinicialização, faz login no GitHub para pegar a imagem do zurg, escreve `~/zurg/docker-compose.yml`, pergunta pelos seus serviços e token, sobe o zurg e roda `zurg doctor`. [A configuração do zurg com Docker](../setup/docker.md) faz o mesmo manualmente.

**O que você deve ver.**

```bash
ls /zurg_mnt/zurg
```

lista `__all__`, `__downloads__`, `__unplayable__`, `movies`, `shows` e `version.txt`.

## 2. Substitua pelo arquivo completo {#2-swap-in-the-full-file}

```bash
cd ~/zurg
nano docker-compose.yml
```

Substitua tudo nele por isto:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:${ZURG_TAG}
    container_name: zurg
    restart: unless-stopped
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    ports:
      - 9999:9999
    volumes:
      - ./:/config
      - /zurg_mnt:/zurg_mnt:rshared

  plex:
    image: plexinc/pms-docker
    container_name: plex
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM=
    volumes:
      - ../plex/config:/config
      - ../plex/transcode:/transcode
      - /zurg_mnt:/zurg_mnt:rslave
    depends_on:
      zurg:
        condition: service_healthy

  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    command: --port 32500
    volumes:
      - ../rex/config:/config
```

- **zurg** é o serviço do próprio instalador, sem alterações.
- O **plex** enxerga as pastas do zurg no mesmo caminho que o zurg usa, `/zurg_mnt/zurg`, então, quando o zurg pede uma verificação, ele informa um nome de pasta que o Plex conhece. `rslave` mantém as pastas ali quando o zurg reinicia. Coloque o seu fuso horário em `TZ`.
- **PLEX_CLAIM** faz o Plex Media Server entrar na sua conta na primeira vez que ele inicia. Já logado no Plex, abra [plex.tv/claim](https://www.plex.tv/claim), copie o código e cole logo depois do `=`. Ele expira em alguns minutos, então inicie a stack logo em seguida.
- **rex** é o serviço de [rex com zurg](../../rex/with-zurg.md#d2-start-rex-in-docker), na porta 32500 porque o Plex Media Server usa a 32400. Os arquivos dele ficam em `~/rex/config`, onde o rex com zurg procura por eles.

Salve e inicie tudo:

```bash
docker compose up -d
docker compose ps
```

Se o `docker` mostrar permission denied, coloque `sudo` antes de cada comando `docker` desta página.

**O que você deve ver.** Três containers: `plex` e `zurg` mostram `(healthy)`, `rex` mostra `Up`. Os arquivos próprios do Plex Media Server vão para `~/plex`.

## 3. Adicione as pastas do zurg no Plex {#3-add-zurgs-folders-in-plex}

Abra o Plex Web em `http://<this machine's LAN IP>:32400/web`. Adicione uma biblioteca **Movies** com a pasta `/zurg_mnt/zurg/movies` e uma biblioteca **TV Shows** com `/zurg_mnt/zurg/shows`, como mostra [Real-Debrid in Plex](../../guides/real-debrid-plex.md#3-add-the-folders-in-plex).

Para que o Plex fique sabendo das coisas novas, abra o painel do zurg em `http://<this machine's LAN IP>:9999/config/` e clique em **Login with Plex** em **Media Server Integration** ([passo 4 da página](../../guides/real-debrid-plex.md#4-let-zurg-tell-plex-about-new-things)).

## 4. Configure o rex {#4-set-up-rex}

Siga [rex com zurg](../../rex/with-zurg.md) de [D3](../../rex/with-zurg.md#d3-add-it-to-a-plex-account) até [D5](../../rex/with-zurg.md#d5-watch), usando `32500` onde estiver escrito `32400`. Por exemplo, a linha do zurg fica `rex_url: http://192.168.1.20:32500`, com o IP da LAN do rex. Seus apps do Plex vão então listar os dois servidores: o [passo 2 de rex com zurg](../../rex/with-zurg.md#step-2-install-rex) explica como diferenciá-los.

## Atualizando {#updating}

```bash
cd ~/zurg
docker compose pull
docker compose up -d
```

Isso atualiza o zurg, o Plex e o rex juntos. Se o rex com o zurg roda `docker compose` em `~/rex`, rode aqui em `~/zurg` com `rex` no final, assim ele mexe só no rex: `docker compose stop rex` no lugar de `docker compose down`, `docker compose up -d rex` no lugar de `docker compose up -d`.

## Quando algo está errado {#when-something-is-wrong}

`docker compose logs --tail=100 zurg` (ou `plex`, `rex`) mostra o que o contêiner disse por último.

| O que você vê | O que fazer |
|---|---|
| O instalador diz `Host-visible Docker mounts require a Linux host. Use the binary installer on macOS or Windows.` | Você está em um Mac ou Windows. Instale o zurg com o instalador [para Windows](../setup/windows.md) ou [para macOS](../setup/macos.md). |
| `Error response from daemon: error from registry: unauthorized` quando o Docker baixa o zurg | Esta máquina não está logada no registro do GitHub com uma conta que tenha acesso ao zurg. Apoie no [gatekeeper](https://gatekeeper.debridmediamanager.com/) e rode o instalador de novo. Para logar manualmente, veja [configuração do zurg com Docker](../setup/docker.md#1-install-docker-and-unlock-the-image): o token precisa de `read:packages` e `repo`. |
| `path /zurg_mnt is mounted on ... but it is not a shared mount` | `/zurg_mnt` ainda não está compartilhado. Rode `sudo mount --bind /zurg_mnt /zurg_mnt` e `sudo mount --make-rshared /zurg_mnt`, depois `docker compose up -d`. O instalador faz isso ficar salvo depois de reiniciar; manualmente, veja [passo 7 da configuração do zurg com Docker](../setup/docker.md#7-make-the-shared-parent-survive-reboots). |
| O `zurg` fica reiniciando, e o log termina com `Error: config ./config.yml is not valid YAML: yaml: unmarshal errors:` e `mapping key "..." already defined` | Essa configuração está duplicada no config do zurg. Rode `sudo nano ~/zurg/config.yml`, apague uma das duas linhas que o erro indica, salve e rode `docker compose restart zurg`. |
| O log do zurg diz `Mount verification failed: mount verification timeout: /zurg_mnt/zurg/version.txt not accessible after 60 attempts -- you appear to be running inside Docker, mount a parent directory with rshared propagation` | As pastas do zurg não subiram. Confira se a linha de volume do zurg é `/zurg_mnt:/zurg_mnt:rshared`, com o pai e não `/zurg_mnt/zurg`, e se `/zurg_mnt` está compartilhado (a linha acima). [Mount is empty](../setup/docker.md#mount-is-empty) tem mais verificações. |
| As bibliotecas do Plex ficam vazias depois que o zurg reinicia, e `docker exec plex ls /zurg_mnt/zurg` diz `cannot access '/zurg_mnt/zurg': Transport endpoint is not connected` | A linha de volume do Plex está sem `rslave`. Ela precisa ser `/zurg_mnt:/zurg_mnt:rslave`. Corrija e rode `docker compose up -d`. |
| O rex para com `rex: cannot bind 0.0.0.0:32400: Address already in use (os error 98) (another rex or Plex on this port? --port picks another)` | O Plex Media Server já usa a porta 32400. Mantenha `command: --port 32500` no rex. |
| `/zurg_mnt/zurg/movies` está vazio, ou diz `Input/output error`, logo depois de iniciar | O zurg ainda está lendo a sua conta. `curl http://localhost:9999/ready` mostra `ready` quando terminar. Não reinicie o zurg enquanto isso: a leitura recomeça do zero. |
| Os títulos aparecem no rex, mas nada toca | A linha `upstream failed` de [rex com o zurg, Quando algo está errado](../../rex/with-zurg.md#when-something-is-wrong) verifica se o rex consegue alcançar o zurg. |
| O disco enche | O zurg guarda uma cópia do que foi reproduzido em `~/zurg/data/rclone-cache`, até 256G por padrão. [O que fica onde](../setup/docker.md#what-lives-where) mostra como limitar isso. |

Ainda travado? Pergunte no fórum **zurg-support** no [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) diz o que incluir.

## Perguntas {#questions}

### Você pode verificar meu arquivo docker compose? {#can-you-check-my-docker-compose-file}

Compare com a de cima. O que mais importa: o zurg monta `/zurg_mnt` com `rshared`, o Plex monta o mesmo `/zurg_mnt` com `rslave`, e o rex usa a imagem `ghcr.io/debridmediamanager/rex` com `network_mode: host`. Um serviço chamado `rex` que roda `plexinc/pms-docker` é só um segundo Plex Media Server, não é o rex.

(Uma tradução anterior foi rejeitada: os trechos de código diferem (`/zurg_mnt`). Mantenha a estrutura exatamente igual.)

### Preciso de um container rclone separado? {#do-i-need-a-separate-rclone-container}

Não. O zurg roda o rclone dentro do próprio container e monta sua biblioteca em `/zurg_mnt/zurg` por conta própria.

### Posso usar o Plex Media Server e o rex juntos? {#can-i-use-plex-media-server-and-rex-together}

Sim, é isso que este arquivo faz. O Plex Media Server reproduz a partir das pastas do zurg, e o rex reproduz diretamente do zurg. Seus apps do Plex mostram os dois. Mantenha só o que você usa, se preferir não ter os dois.

### Isso funciona em um NAS? {#does-this-work-on-a-nas}

Foi testado em um PC com Linux, não em um NAS. O instalador precisa de um terminal (SSH) com `sudo` e de FUSE (`/dev/fuse`). Se o passo 1 terminar com as pastas do zurg em `/zurg_mnt/zurg`, siga para o passo 2.

### Com quais versões isso foi testado? {#which-versions-was-this-tested-with}

zurg `2026.11.14.1134-nightly`, rex `2026.11.14.1123-nightly` e Plex Media Server `1.43.5.11079`, em 14 de novembro de 2026.
