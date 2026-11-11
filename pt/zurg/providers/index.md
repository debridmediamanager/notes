# Provedores {#providers}

Um provedor é uma conta da qual o zurg monta a sua biblioteca. Cada conta é uma
entrada em `providers:` no `config.yml`. Use uma conta ou use seis. Um lançamento
que esteja em mais de uma delas aparece uma única vez na lista e é lido da conta
que puder entregá-lo naquele momento.

| Serviço | `type` | Página |
|---|---|---|
| Real-Debrid | `realdebrid` | [Real-Debrid](realdebrid.md) |
| TorBox | `torbox` | [TorBox](torbox.md) |
| AllDebrid | `alldebrid` | [AllDebrid](alldebrid.md) |
| Premiumize | `premiumize` | [Premiumize](premiumize.md) |
| Debrid-Link | `debridlink` | [Debrid-Link](debridlink.md) |
| Offcloud | `offcloud` | [Offcloud](offcloud.md) |
| Usenet | `nzb` | [Usenet](usenet.md) |
| TorBox hosted Usenet | `torbox_nzb` | [TorBox hosted Usenet](torbox-nzb.md) |

Três páginas vão além da configuração inicial. [Limites do TorBox](torbox-limits.md) tem os números medidos por trás da limitação do TorBox. [Servidor de notícias do TorBox](torbox-news-server.md)
e [Servidor de notícias do ElfHosted](elfhosted-news-server.md) registram o que são, de fato, as contas de Usenet incluídas nesses planos. Avalie uma delas por lá antes de gastar um slot de provedor com ela.

Todas as páginas aqui partem do pressuposto de que você usa a instalação em contêiner da [Configuração do Docker](../setup/docker.md). `~/zurg` é o diretório do compose no host. `/config` é esse mesmo diretório visto de dentro do contêiner. Existe um único `config.yml` e os dois nomes chegam até ele.

Numa instalação binária em Linux, macOS ou Windows, [Configuração](../setup/index.md) lista o que substitui `docker compose restart zurg` e a linha `setup`. As verificações são traduzidas da mesma forma. Execute-as na pasta do zurg. Leia `logs/zurg.log` em vez de `docker compose logs` (`Get-Content logs\zurg.log -Tail 100 -Wait` no PowerShell). Execute `./zurg doctor` (`.\zurg.exe doctor`) sem `--working-dir /config`. Liste o seu próprio ponto de montagem em vez de `/zurg_mnt/zurg`: `/mnt/zurg`, `/Volumes/Zurg` ou `Z:\`, a menos que você tenha alterado `mount_path`. No Windows PowerShell 5.1, digite `curl.exe`, não `curl`.

## Três formas de adicionar uma conta {#three-ways-to-add-an-account}

Qual você quer depende de o `config.yml` já existir ou não.

### Em uma instalação nova, use o setup {#on-a-fresh-install-use-setup}

`zurg setup` pergunta quais provedores você quer configurar e pede apenas as credenciais deles. Ele só grava as contas **quando ainda não existe um `config.yml`**. Se você rodar de novo depois, ele atualiza a instalação sem mexer nas contas que você já tem.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

O seletor aceita números ou nomes e permite escolher vários de uma vez.

```
Choose one or more providers in priority order:
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
Providers (comma-separated numbers or names): 2,4
```

Nada do que você digitar vai parar no arquivo do compose nem no histórico do shell. O token vai direto para o `config.yml`, e o arquivo é gravado somente com permissão para o dono.

### Em uma instalação existente, use o Dashboard {#on-an-existing-install-use-the-dashboard}

Abra `http://localhost:9999/config/` e use **Add provider** em Essentials.
Escolha o tipo. Cole o token. Salve. O Dashboard grava a entrada de volta no
mesmo `config.yml` ao lado do seu arquivo compose.

Mudanças de provider precisam de um restart para fazer efeito. O Dashboard avisa
sobre isso, e o restart é um único comando.

```bash
docker compose restart zurg
```

### Ou edite o config.yml manualmente {#or-edit-configyml-by-hand}

The file is `~/zurg/config.yml` on the host. Add the entry and restart.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

`mount_path` is `/zurg_mnt/zurg` in a container and the compose file has to bind
`/zurg_mnt:/zurg_mnt:rshared` for the mount to reach the host. That is the
[Docker setup](../setup/docker.md) page and it is the one part of a container
install that is not the same as a binary one.

## Instalações não assistidas {#unattended-installs}

Cada provedor tem uma flag de arquivo de token e uma variável de ambiente. Repita `--provider` para cada conta que você quiser.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

| `type` | Flag | Variável de ambiente |
|---|---|---|
| `realdebrid` | `--realdebrid-token-file` | `REALDEBRID_TOKEN` or `TOKEN` or `RD_TOKEN` |
| `torbox` | `--torbox-token-file` | `TORBOX_TOKEN` |
| `alldebrid` | `--alldebrid-token-file` | `ALLDEBRID_TOKEN` |
| `premiumize` | `--premiumize-token-file` | `PREMIUMIZE_TOKEN` |
| `debridlink` | `--debridlink-token-file` | `DEBRIDLINK_TOKEN` |
| `offcloud` | `--offcloud-token-file` | `OFFCLOUD_TOKEN` |
| `nzb` | `--nntp-password-file` com `--nntp-host` e `--nntp-username` | `NNTP_HOST` e afins |
| `torbox_nzb` | `--torbox-token-file` | `TORBOX_TOKEN` |

`torbox_nzb` nunca é inferido só a partir de `TORBOX_TOKEN` ou `--torbox-token-file`. Passe `--provider torbox_nzb`.

Com `--non-interactive` e sem nenhum `--provider`, o setup usa qualquer uma dessas variáveis que estiver definida.

!!!warning Só o Real-Debrid é configurado pelo container em execução
O daemon do zurg em si lê `TOKEN`, `RD_TOKEN` e `MOUNT_PATH` na execução que cria o `config.yml`. Essa é a lista completa. `TORBOX_TOKEN` e as demais são lidas pelo `zurg setup`. Colocar uma delas no bloco `environment:` do seu compose e iniciar o container não faz nada sozinho. Rode o setup ou adicione a conta no Dashboard.
!!!

## O que cada entrada aceita {#what-every-entry-accepts}

| Key | O que faz |
|---|---|
| `type` | Obrigatório. Um dos oito tipos acima. |
| `name` | Por padrão, usa `type`. Diferencia duas contas no mesmo serviço. |
| `token` | A chave de API. Não é usada por `nzb`. |
| `disabled` | Desativa a conta sem apagar a credencial. |
| `watchlist` | Marca a conta em que os novos torrents adicionados são testados primeiro. |
| `add_torrents` | Se estiver como `false`, a conta continua servindo, mas nunca recebe nada novo. |
| `warm_connections` | Conexões mantidas abertas por host, para que uma leitura não precise abrir uma nova. |

As descrições completas e todo o resto estão na
[referência de configuração](../reference/config.md#accounts).

## Regras que o loader aplica {#rules-the-loader-enforces}

- Os nomes precisam ser únicos. Duas contas do Real-Debrid precisam de `name: rd-main` e `name: rd-backup`, senão o carregamento falha.
- O nome `e` é reservado para o roteamento de links `.strm`. Escolha outro.
- No máximo uma entrada pode definir `watchlist: true`.
- `watchlist: true` e `add_torrents: false` na mesma entrada são recusados.
- Só há suporte para uma entrada `nzb` ou `torbox_nzb` habilitada. Servidores de notícias extras vão em `nntp.servers` de uma entrada `nzb`.
- Se todas as entradas estiverem desabilitadas, o carregamento falha.
- Premiumize, Debrid-Link e Offcloud recusam `download_tokens` e um `strm_link_token` diferente de `token`. Os IDs de arquivo deles pertencem a uma única conta, então uma segunda conta precisa ser uma segunda entrada.

## Verifique se funcionou {#check-it-worked}

```bash
docker compose logs -f --tail=100 zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`WARN service zurg is not installed` é esperado no Docker porque o Compose cuida do início automático. Avisos não fazem o doctor falhar. Só um `FAIL` faz.

Depois, teste a própria conta pelo Dashboard ou pelo shell.

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
```

`{"success":true}` quer dizer que a credencial foi autenticada. O nome no caminho é o `name` da conta. Por padrão ele é o próprio `type`. Adicione `-u user:pass` se você tiver definido um `username` no `config.yml`. Sem ele, o Dashboard e a API ficam abertos na porta que você publicou.

Por último, veja a biblioteca no mount.

```bash
ls /zurg_mnt/zurg/__all__/
```

Cada conta configurada ganha um diretório `__<name>__`. Ele tem tudo o que aquela conta tem e fixa as leituras nessa conta. `__torbox__/Some.Release/` faz streaming só do TorBox e de mais nenhum lugar. A pasta de uma conta única não aparece na listagem da raiz do mount, já que `__all__` é a mesma biblioteca. Caminhos HTTP e WebDAV diretos, como `/http/__torbox__/`, continuam respondendo. Pelo mount eles também deixam de resolver; aponte qualquer biblioteca ou script que usava `__<name>__` para `__all__`.

Uma biblioteca grande demora um pouco no primeiro carregamento. Até terminar, `/dav/movies/` responde 503 e o mount pode não listar nada.

## Executando várias contas {#running-several-accounts}

A ordem importa em um único ponto. A ordem da lista `providers:` é a ordem em que as contas que aceitam adições são testadas. Uma conta com `watchlist: true` é testada primeiro, esteja onde estiver na lista. Para listar e ler, a ordem não faz diferença.

Duas coisas valem a pena saber antes de apontar um servidor de mídia para o resultado.

- O mesmo lançamento aparece nos seus diretórios filtrados **e** em todos os diretórios `__<name>__` que o contêm. Aponte o Plex ou o Jellyfin para uma parte do mount, e não para o mount inteiro, senão ele escaneia o mesmo conteúdo várias vezes.
- Não existe failover silencioso dentro de um diretório `__<name>__`. Um arquivo morto em uma conta dá 404 ali, mas toca pelo diretório de outra conta. O resto do mount continua servindo ele normalmente.
