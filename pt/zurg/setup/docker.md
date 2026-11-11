# Configuração com Docker {#docker-setup}

This guia executa o zurg no Docker e expõe o mount FUSE dele em um host Linux. O Docker fornece o zurg, o rclone e o ffprobe. O comando `setup` embutido cria a config. O `doctor` verifica a instalação.

Este fluxo foi verificado em 4 de setembro de 2026 com o Docker Engine 29.1.1. Use o nightly datado mais recente para que a imagem tenha o seletor de provedores abaixo.

> **Imagem de patrocinador:** `ghcr.io/debridmediamanager/zurg` é para patrocinadores. Torne-se patrocinador no [gatekeeper](https://gatekeeper.debridmediamanager.com/). Isso dá à sua conta do GitHub acesso à imagem.

> **Host Linux obrigatório:** o mount visível no host abaixo depende da propagação de mount do Linux. O Docker Desktop executa os containers dentro de uma VM no macOS e no Windows: ele não consegue propagar esse mount FUSE para o Finder ou o Explorer, e o rex não consegue alcançar um zurg dentro dela, então nada tocaria ali. Use o guia do binário para [macOS](https://notes.debridmediamanager.com/pt/zurg/setup/macos/) ou [Windows](https://notes.debridmediamanager.com/pt/zurg/setup/windows/) em qualquer um desses hosts. No Linux, com o rex em outra máquina, dê ao container do zurg `network_mode: host`, como mostra [rex com zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex).

## Opção de uma linha {#one-line-option}

On a fresh Linux host, the optional bootstrap can install Docker when you approve it, configure persistent FUSE mount propagation, log in to the sponsor registry, write the Compose project, run the provider chooser, and verify the result:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Existing Compose files and configs are kept as they are. The sections below show every step for people who prefer the manual route.

## O que o instalador faz em um contêiner {#what-the-installer-does-in-a-container}

As flags são intencionais:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

- `setup` pergunta quais provedores configurar, pede só as credenciais deles e grava o `config.yml` com modo `0600`.
- `--no-service` deixa o início automático por conta da política `restart: unless-stopped` do Docker, em vez de tentar instalar o systemd dentro do Alpine.
- `--skip-downloads` usa o rclone e o ffprobe que já estão instalados na imagem.
- `--mount-path` registra o subdiretório cujo mount FUSE vai propagar de volta para o host.

Rodar o setup de novo é seguro. Ele valida e atualiza a instalação, mas não substitui um `config.yml` que já existe.

## 1. Instale o Docker e libere a imagem {#1-install-docker-and-unlock-the-image}

Instale o Docker Engine com o plugin Compose no host Linux. Verifique os dois comandos antes de continuar:

```bash
docker version
docker compose version
```

Faça login no GitHub Container Registry com seu nome de usuário do GitHub. Quando pedir a senha, cole um personal access token clássico com os escopos `read:packages` e `repo`. A imagem pertence a um repositório privado, e um token só com `read:packages` até consegue fazer login, mas o pull ainda vai falhar:

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

Defina `ZURG_TAG` com a release datada mais recente de patrocinador. Mantê-la no `.env` te dá um alvo de rollback conhecido e torna as atualizações explícitas:

```bash
printf 'ZURG_TAG=YYYY.MM.DD.HHMM-nightly\n' > .env
```

Substitua o placeholder pela tag real da release antes de continuar.

## 2. Prepare a propagação do mount FUSE {#2-prepare-fuse-mount-propagation}

The FUSE mount must be created below a shared parent mount. Run this once before the first container starts:

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

Verify the device and propagation mode:

```bash
test -c /dev/fuse
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

The second command should report `shared` under `PROPAGATION`.

## 3. Crie o projeto do compose {#3-create-the-compose-project}

```bash
mkdir -p ~/zurg
cd ~/zurg
```

Crie `docker-compose.yml`:

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
```

Você não precisa de `privileged: true`. O dispositivo FUSE, a capability `SYS_ADMIN` e o perfil AppArmor sem confinamento formam o conjunto mais restrito que a montagem usa.

Não faça bind direto em `/zurg_mnt/zurg`. A montagem FUSE precisa ser filha do bind `rshared`, senão o evento de montagem não chega ao host.

Os containers que leem a montagem, principalmente o Sonarr e o Radarr, seguem a mesma regra do outro lado: faça o bind do diretório pai (`/zurg_mnt`) uma só vez, com `rslave`, e acesse todas as pastas por esse único bind. Fazer bind de `__magic__/__all__` e `__magic__/tv` no \*arr como dois volumes transforma cada importação numa cópia do arquivo inteiro. Veja [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

## 4. Execute a configuração integrada {#4-run-the-built-in-setup}

De `~/zurg`, execute:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

Escolha um ou vários provedores em ordem de prioridade. Por exemplo, digite `2,4` para TorBox seguido de Usenet. O setup pede apenas as credenciais deles, cria o `config.yml` em `~/zurg`, ativa o rclone e cria `/zurg_mnt/zurg`. Nenhuma credencial é gravada no arquivo do compose nem no histórico do shell.

Para automação, repita `--provider` e passe os flags específicos de cada provedor, como o arquivo de token ou os `--nntp-*`. O setup mantém uma config existente nas execuções seguintes.

O setup grava as contas somente na execução que cria o `config.yml`. Para adicionar uma conta a uma instalação que já tem config, use o **Add provider** do Dashboard ou edite o arquivo e reinicie. Cada serviço tem sua própria página, com a credencial, o bloco de config e os limites que vale conhecer: [Provedores](../providers/index.md).

## 5. Inicie o zurg {#5-start-zurg}

```bash
docker compose up -d
docker compose logs -f --tail=100 zurg
```

Saia do log com `Ctrl+C`; o container continua rodando. O Dashboard fica em `http://localhost:9999/config/` e edita o mesmo `config.yml` guardado ao lado do arquivo compose.

Uma biblioteca grande pode demorar um pouco para carregar. As pastas do mount não listam até que ela termine. Elas aparecem vazias ou como `Input/output error`, enquanto o Dashboard e o `version.txt` funcionam normalmente. Isso significa que o zurg ainda está carregando, e não que o mount esteja quebrado. [Up versus ready](#up-versus-ready) mostra como saber quando o carregamento terminou.

## 6. Verifique com o doctor {#6-verify-with-doctor}

Quando a biblioteca estiver pronta, rode a mesma ferramenta de diagnóstico usada na instalação binária:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
```

O `doctor` verifica a configuração e as permissões dela, o ffprobe, o rclone, o FUSE, o endpoint HTTP e o mount reportado pelo zurg. `WARN service zurg is not installed` é esperado no Docker, porque o Compose cuida do início automático. Warnings não fazem o comando falhar; qualquer `FAIL` faz.

Confirme que o mount propagado também fica visível fora do container:

```bash
cat /zurg_mnt/zurg/version.txt
ls -la /zurg_mnt/zurg/
```

## 7. Faça o diretório pai compartilhado sobreviver a reinicializações {#7-make-the-shared-parent-survive-reboots}

A autovinculação do passo 2 não sobrevive a um reinício. Crie uma unit oneshot do systemd no host:

```bash
sudo tee /etc/systemd/system/rshared-zurg-mnt.service << 'EOF'
[Unit]
Description=Make /zurg_mnt rshared for Docker FUSE mounts
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "mount --bind /zurg_mnt /zurg_mnt && mount --make-rshared /zurg_mnt"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable rshared-zurg-mnt.service
```

No próximo reinício, o host prepara o diretório pai compartilhado antes de o Docker restaurar o container do zurg.

## Up versus ready

zurg responde a duas perguntas diferentes por HTTP. Nenhuma delas exige senha, mesmo quando `username` está definido.

| Endereço | Responde 200 quando | Enquanto a biblioteca carrega |
|---|---|---|
| `/http/version.txt` | o zurg está rodando | 200 |
| `/ready` | a biblioteca terminou de carregar | 503 com `Retry-After: 5` |

O health check do container consulta o primeiro. `docker compose ps` mostra `healthy` assim que o zurg está rodando. Uma biblioteca grande pode continuar carregando por bastante tempo depois disso. Consulte `/ready` quando precisar da biblioteca inteira. Ele imprime `ready` quando o carregamento termina.

```bash
curl -fsS http://localhost:9999/ready
docker compose exec zurg /app/healthcheck.sh --ready && echo ready
```

Um script pode esperar por ele assim.

```bash
until curl -fsS http://localhost:9999/ready >/dev/null; do sleep 10; done
```

### Por que o health check não espera pela biblioteca {#why-the-health-check-does-not-wait-for-the-library}

Docker mantém um status de saúde por contêiner. As ferramentas que o leem entendem isso como "o zurg está vivo?". O autoheal e o Docker Swarm reiniciam um contêiner que fica unhealthy. O `depends_on` com `condition: service_healthy` segura os outros serviços até o zurg ficar healthy.

Já foram relatados inícios a frio de 15 a 90 minutos em bibliotecas grandes. Um health check que esperasse a biblioteca carregar seguraria todos os serviços dependentes por esse tempo todo. Um contêiner rclone na frente do zurg deixaria a pasta de montagem vazia durante todo esse período. Uma pasta vazia parece, para um servidor de mídia, uma biblioteca que foi apagada. Uma carga que passasse das tentativas do health check também seria marcada como unhealthy. Qualquer coisa que reiniciasse contêineres unhealthy começaria a carga do zero. Ela nunca terminaria.

### Usando readiness com o Compose {#using-readiness-with-compose}

Mantenha o contêiner de montagem com o health check padrão para que a montagem fique disponível assim que o zurg estiver rodando.

```yaml
services:
  rclone:
    depends_on:
      zurg:
        condition: service_healthy
```

Aguarde em `/ready` no que precisar da biblioteca inteira. Pode ser um script de scan ou um job de importação.

Você pode fazer o próprio contêiner do zurg reportar healthy só depois que a biblioteca carregar. Sobrescreva o health check dele em `docker-compose.yml` e defina `start_period` maior que o seu carregamento mais lento. O Docker não conta falhas dentro do start period. Assim, todo serviço que depende do zurg também espera pela biblioteca. Não combine isso com autoheal.

```yaml
services:
  zurg:
    healthcheck:
      test: ["CMD", "/app/healthcheck.sh", "--ready"]
      interval: 30s
      timeout: 10s
      start_period: 3h
      retries: 3
```

## Gerenciando e atualizando o zurg {#managing-and-updating-zurg}

Execute estes comandos a partir de `~/zurg`:

```bash
docker compose ps
docker compose logs -f --tail=100 zurg
docker compose restart zurg
docker compose stop zurg
docker compose start zurg
```

O projeto compose usa o `ZURG_TAG` do `.env`, que o instalador define como `latest`, então um pull sempre traz a nightly mais recente. Para atualizar, faça o pull e recrie o container, depois execute o doctor:

```bash
docker compose pull zurg
docker compose up -d zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`zurg update` não é o caminho aqui e se recusa a rodar dentro de um container: o binário que ele grava fica na camada do container e é perdido assim que o container é recriado, então o próximo `up` voltaria silenciosamente para a build antiga. Faça o pull da imagem. `--force` ignora a recusa, para um container que você pretende manter.

Para voltar a uma versão anterior, defina `ZURG_TAG` no `.env` com uma tag específica de nightly e execute os três comandos de novo. A configuração montada por bind, o estado da biblioteca, os logs e o cache não mudam com o container.

`docker compose down` remove o container e a rede, mas deixa os arquivos montados por bind em `~/zurg` e o diretório pai do mount em `/zurg_mnt`.

## O que fica onde {#what-lives-where}

Tudo que o zurg escreve é gravado dentro de `/config`, então o único bind `./:/config` guarda a instalação:

| Caminho | O que é |
|---|---|
| `config.yml` | Configurações e credenciais dos provedores; as edições feitas no Dashboard são gravadas aqui |
| `data/` | Estado da biblioteca, arquivos locais, chaves geradas e o cache de VFS do rclone |
| `logs/` | Logs do zurg e do rclone |
| `dump/` | Dumps de torrents, quando ativados |
| `strm/` | Arquivos `.strm`, quando `save_strm_files` está ativado |
| `nzbs/` | Diretório de monitoramento do backend de Usenet |

Baixar ou recriar a imagem não altera nenhum desses arquivos.

`data/rclone-cache` é o que cresce. O mount baixa por completo cada arquivo que
lê e o mantém depois que a reprodução termina, até **256G** por padrão, então o
diretório do bind precisa de espaço para o cache além de todo o resto. O limite
de idade de 72h, na prática, não o limita — qualquer coisa que leia a biblioteca,
inclusive a varredura noturna de um servidor de mídia, conta como acesso ao arquivo.

```bash
du -sh ./data/rclone-cache
```

Diminua o limite no `config.yml` quando o disco do host não puder comportar esse
tanto:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Mudar o caminho do host por trás de `/config` renomeia o cache e deixa a cópia
antiga órfã; o zurg recupera essas árvores órfãs no próximo start e registra no
log o que liberou. Veja [config.md](../reference/config.md#disk-the-mount-uses).

### Semeando variáveis de ambiente para instalações sem supervisão {#environment-seeding-for-unattended-installs}

A imagem ainda oferece suporte ao caminho antigo de primeira execução. Se não existir um `config.yml`, `TOKEN` ou `RD_TOKEN` cria a conta, e `MOUNT_PATH` ativa o mount. Essas variáveis são lidas apenas enquanto o arquivo está sendo criado; o arquivo tem prioridade em todas as inicializações seguintes.

O Real-Debrid é a única conta que o container em execução cria dessa forma. `TORBOX_TOKEN`, `ALLDEBRID_TOKEN`, `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN`, `OFFCLOUD_TOKEN` e `NNTP_HOST` são lidas pelo `zurg setup`, então elas só funcionam no container de setup único descrito acima e não fazem nada se estiverem no bloco `environment:` do serviço.

O comando `setup` interativo é o preferido para quem está em um terminal, porque o token nunca entra no arquivo do compose. A criação por variáveis de ambiente continua útil para automações que já têm um cofre de segredos.

### Atualizando uma instalação que montou `/app` {#upgrading-an-install-that-mounted-app}

Projetos antigos do compose montavam `/app/config.yml`, `/app/data` e outros caminhos separadamente. O entrypoint continua selecionando `/app` sempre que encontra esse layout, então puxar uma imagem mais nova continua usando o config e o cache antigos.

Para adotar o layout de pasta única, pare o container, copie o `config.yml` existente, a pasta `data/` e os outros diretórios de estado para um único diretório no host e, depois, monte esse diretório em `/config`.

## Solução de problemas {#troubleshooting}

Comece pelo diagnóstico e pelos logs atuais:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
docker compose logs --tail=200 zurg
```

### `unknown command "setup"` ou `unknown command "doctor"` {#unknown-command-setup-or-unknown-command-doctor}

O container é anterior ao instalador integrado. Use `2026.09.04.1449-nightly` ou uma imagem mais recente do zurg com data e depois recrie o container:

```bash
docker compose pull zurg
docker compose up -d zurg
```

### `Transport endpoint is not connected`

A montagem FUSE antiga está desatualizada:

```bash
sudo umount -l /zurg_mnt/zurg
docker compose restart zurg
```

### Dispositivo FUSE indisponível {#fuse-device-is-unavailable}

Carregue o módulo agora e também nos próximos boots:

```bash
sudo modprobe fuse
echo fuse | sudo tee /etc/modules-load.d/fuse.conf
```

Depois, confirme se o serviço do compose ainda inclui `/dev/fuse`, `SYS_ADMIN` e a configuração do AppArmor.

### O mount está vazio {#mount-is-empty}

Verifique cada camada em ordem:

```bash
docker compose logs zurg 2>&1 | grep -i rclone
docker compose exec zurg ls -la /zurg_mnt/zurg
curl -fsS http://localhost:9999/http/version.txt
curl -fsS http://localhost:9999/ready
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

O caminho do host precisa ser um bind mount compartilhado, e o volume do compose deve montar o diretório pai como `/zurg_mnt:/zurg_mnt:rshared`.

Se `/ready` falhar com erro 503, a biblioteca ainda está carregando e o mount está certo. As pastas aparecem vazias ou mostram `Input/output error` até o carregamento terminar. Espere em vez de reiniciar o zurg. Um restart faz o carregamento começar de novo.

### O mount aparece duas vezes na saída de `mount` {#mount-appears-twice-in-mount-output}

That é normal. A mesma montagem FUSE aparece nos namespaces de montagem do container e do host porque a propagação está funcionando.

Ainda travado? Pergunte no fórum **zurg-support** no [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) explica o que incluir.
