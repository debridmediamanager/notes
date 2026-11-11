# Documentação de configuração do zurg {#zurg-configuration-documentation}

Este documento detalha todas as opções de configuração disponíveis para o zurg. Configure essas opções no seu arquivo `config.yml`.

> **Dica:** A maioria das configurações pode ser feita pelo **Dashboard** em `http://localhost:9999/config/`. A interface web oferece um jeito mais fácil de ver e alterar as configurações, sem precisar editar o arquivo de configuração diretamente.

## Migrando de uma config anterior ao `providers` {#migrating-from-a-pre-providers-config}

Se a sua configuração foi escrita antes do suporte a várias contas chegar, ela continua funcionando: as chaves de nível superior `token:`, `download_tokens:` e `strm_link_token:` são lidas como a única coisa que elas poderiam descrever — uma única conta do Real-Debrid — e, na inicialização, aparece um aviso dizendo que elas estão obsoletas. Mover essas chaves para uma entrada em `providers` é a única mudança que o seu arquivo de configuração precisa, quando você tiver tempo para fazer isso: nenhuma outra chave foi renomeada, ter o tipo alterado ou removida.

Não é, porém, a única coisa que muda. Algumas diretivas mantêm o nome e o valor, mas passam a decidir algo um pouco diferente do que decidiam antes, porque o código que as lê foi movido. Elas estão reunidas em [O que mais muda ao atualizar](#what-else-changes-when-you-upgrade) abaixo — vale a pena ler se você filtra por arquivos compactados, por tags ou por quando um lançamento foi adicionado.

### A única mudança a fazer {#the-one-change-to-make}

Uma única conta do Real-Debrid antes ficava em três chaves de nível superior. Agora as três ficam dentro de uma única entrada `providers`.

Antes:

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
download_tokens:
  - ANOTHER_RD_API_TOKEN
strm_link_token: RD_TOKEN_FOR_STRM
```

Depois:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    download_tokens:
      - ANOTHER_RD_API_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
```

Apague as chaves antigas depois de movê-las. Se elas ficarem ao lado de um bloco `providers` que já configura o Real-Debrid, são ignoradas e o startup emite um aviso sobre elas, assim os dois nunca podem discordar silenciosamente sobre qual token está ativo. Nada mais no seu arquivo precisa ser alterado: todas as outras chaves mantiveram o nome e o significado, e uma config cuja única credencial era `token:` precisa só dessa edição.

Você não é obrigado a fazer isso. Uma config não migrada ainda inicia: as três chaves são lidas como uma única conta do Real-Debrid chamada `realdebrid`, e o startup informa quais chaves leu e o que escrever no lugar. Elas estão descontinuadas, não suportadas: novos recursos de conta só ficam disponíveis por meio de uma entrada `providers`.

As variáveis de ambiente `TOKEN` / `RD_TOKEN` continuam funcionando e continuam criando uma config automaticamente na primeira execução.

### O que passou a ser possível e você pode querer {#what-became-possible-that-you-may-want}

Nada disso é obrigatório. É o que o bloco `providers` trouxe:

| Já disponível | Onde |
|---|---|
| Backends TorBox, AllDebrid e Usenet, junto com o Real-Debrid ou no lugar dele | [Contas](#accounts) |
| Várias contas do mesmo serviço, diferenciadas pelo `name` | [Contas](#accounts) |
| `disabled: true` para deixar uma conta de lado sem apagar as credenciais | [Contas](#accounts) |
| `watchlist: true` para escolher em qual conta os novos envios de torrent são tentados primeiro | [Contas](#accounts) |
| Filtros de diretório `provider:` / `not_provider:` e diretórios por conta | [Diretórios](#7-directories--filters) |
| `rd_cdn_host_preference` e `tb_cdn_host_preference` para escolher o CDN por serviço | [CDN e seleção de host](#cdn--host-selection) |

Duas mudanças menores que vale conhecer:

- `cdn_host_preference` continua funcionando e ainda se refere ao Real-Debrid. Agora ele é um alias para `rd_cdn_host_preference`, que tem prioridade se os dois estiverem definidos.
- As credenciais do Plex vindas do fluxo de autenticação do Dashboard agora são gravadas de volta no `config.yml` como `plex_server_url` e `plex_token`. Antes ficavam em `data/plex.json`.

### Migrando manualmente vs. pelo painel {#migrating-by-hand-vs-by-dashboard}

O Dashboard pode terminar isso por você. Uma config não migrada carrega normalmente, então o editor de providers fica acessível, e ele lista a conta Real-Debrid na qual suas chaves de nível superior foram lidas. Salvar qualquer conta move essas chaves para o bloco `providers` no disco. Editar o arquivo à mão e reiniciar faz a mesma coisa, e é a única opção se a config não carregar de jeito nenhum.

Uma coisa que o Dashboard não aceita mais: o `POST /config` costumava receber `token`, `download_tokens` e `strm_link_token` como chaves de nível superior, mas agora responde `400 Unknown config option`. As credenciais agora são editadas por conta. Quem tiver scripts que usem essas três chaves precisa atualizá-los.

### O que mais muda ao atualizar {#what-else-changes-when-you-upgrade}

Toda diretiva abaixo mantém o nome, o tipo e o valor. O que mudou é o código que a lê, então a mesma configuração pode produzir um resultado diferente. Nada aqui exige edição. É só o que esperar, e o que mudar apenas se você discordar.

**Os filtros agora enxergam dentro dos arquivos compactados.** `any_file_inside_regex`, `any_file_inside_contains`, `any_file_inside_size_gte`/`_lte`, suas formas `not_`, `has_episodes` e `is_music` antes eram avaliados contra o próprio arquivo compactado: uma entrada chamada `Show.part01.rar`, com o tamanho de um volume. Depois que o zurg listou um arquivo compactado, eles passam a ser avaliados contra o conteúdo: os nomes reais dos arquivos, os tamanhos reais e, de propósito, *não* o tamanho do próprio arquivo compactado, que ofuscava tudo que tinha dentro. Um season pack que aparecia como um arquivo enorme agora bate com `has_episodes`. `any_file_inside_regex: /\.mkv$/i` passa a bater onde antes falhava, e `any_file_inside_not_regex` deixa de bater onde antes passava. Além disso, um release cujos arquivos são todos `.rar`/`.r00`/`.par2` agora chega aos filtros, quando antes ia direto para `__unplayable__`.

Isso acontece release por release, e não de uma vez. Vale só para arquivos compactados que o zurg já listou, e listagens escritas por um parser antigo são descartadas, então um release muda na primeira vez que alguém o abre. Se algum dos seus diretórios depende da leitura antiga, expresse-o contra o nome do arquivo compactado com `regex`/`not_regex`, que continuam batendo com o nome do release.

**Filtros de tag não pegam mais releases que nunca foram analisados.** As tags `zurg_*` vêm do ffprobe. Quando nada pôde ser analisado, todas as tabelas de faixa caíam no fim e o release ainda recebia `zurg_sdr`, `zurg_very_low_video_bitrate`, `zurg_very_low_audio_bitrate` e `zurg_0to20mins_duration`, descrevendo um arquivo que ninguém tinha medido. Essas tags não são mais emitidas. Um filtro que cita uma dessas quatro muda de significado para releases não analisáveis: `has_tag`/`tags_match_all`/`tags_match_any` deixam de pegá-los e, a direção que vale conferir, `not_has_tag`, `tags_missing_all` e `tags_missing_any` **passam** a pegá-los. Filtros que citam qualquer outra faixa não são afetados.

**`added_within_hours` / `added_within_days` / `added_after` / `added_before` leem um timestamp mais antigo para duplicatas.** Quando um mesmo release aparece mais de uma vez, a entrada agora mostra a data de adição mais antiga, e não a primeira encontrada. Assim, uma segunda cópia de um release antigo não faz mais ele parecer recém-adicionado. Um diretório do tipo `recent` pode deixar de manter um release que mantinha antes.

**O mount agora guarda as listagens de diretório por 12 horas.** `check_for_changes_every_secs` costumava definir o `--dir-cache-time` do rclone, então as listagens expiravam a cada 15 segundos por padrão. Agora elas ficam válidas por 12h, e o zurg esquece explicitamente as entradas afetadas sempre que a biblioteca muda, o que mantém os scans do servidor de mídia rápidos. Para voltar ao comportamento antigo, sobrescreva diretamente. `rclone_extra_args` tem prioridade sobre qualquer flag embutida:

```yaml
rclone_extra_args: ["--dir-cache-time", "15s"]
```

**Cada conta ganha um diretório `__<account>__`.** Ele é criado a partir do bloco `providers`, e não de `directories`. Contém tudo o que aquela conta tem, ignora seus filtros de diretório e fixa as leituras naquela conta. Não é algo que `directories` consiga suprimir. Com mais de uma conta, ele aparece na raiz do mount. Builds anteriores ao nightly 2026.10.24.0551 também listavam a pasta de uma única conta ali; a partir desse nightly ela sai da listagem da raiz do mount, já que `__all__` é a mesma biblioteca. Caminhos HTTP e WebDAV diretos, como `/http/__realdebrid__/`, continuam respondendo. Pelo mount, ele também deixa de resolver. Aponte qualquer biblioteca ou script que usava `__<name>__` para `__all__`.

**Dois releases com o mesmo nome agora são duas entradas.** Antes eles se fundiam em uma só, misturando silenciosamente os arquivos de um release com os do outro. O que não fica com o nome puro recebe como sufixo seis caracteres do seu info hash, como em `Movie.2024 {a1b2c3}`. É essa string com sufixo que `regex`, `not_regex`, `contains` e `not_contains` comparam, então um padrão ancorado não vai pegá-la. Além disso, entradas diferenciadas por um basename duplicado são renomeadas uma vez na atualização, trocando um id de arquivo gerado pela conta por uma tag derivada do caminho.

**Os arquivos `.strm` mudam de formato.** Com `serve_strm_files`, todo `.strm` que o mount serve muda de conteúdo e de tamanho informado. A URL agora aponta para a entrada da biblioteca, e não para o link de uma conta, então ela faz failover e sobrevive a reparos. O servidor de mídia vai ver todo `.strm` mudar. Com `save_strm_files`, os arquivos já gravados são reescritos no lugar, com os mesmos nomes, na primeira vez que o zurg iniciar, e o servidor de mídia pega a nova URL no próximo scan. O novo formato é assinado com um segredo em `data/strm_secret`. Se ele não puder ser gravado, o zurg registra um aviso e inicia mesmo assim, e os links deixam de funcionar após o próximo reinício. Vale não ignorar.

**`load_dumped_torrents` não carrega um `dump/` de antes da atualização.** Os torrents em cache agora carregam a conta de onde vieram, e os que não têm essa marca são ignorados. O cache principal é reimportado da conta na próxima atualização. O `dump/` não tem conta por trás, então ele fica vazio e aparece um aviso no log. Se precisar dele, exporte de novo a partir de uma instância em execução.

**O reparo segue outro caminho quando `restrict_repair_to_cached` e `only_full_torrent_repair` estão como false.** As duas chaves continuam iguais quando definidas como `true`. Com elas desligadas, que é o padrão, as estratégias por arquivo e em lote foram substituídas por um único re-add que cita os arquivos quebrados. Mesma intenção, requisições diferentes para a conta.

**Mudanças menores.** `ignore_renames` agora também define o nome do `.zurgtorrent` gravado em disco (migra sozinho ao carregar). `retries_until_failed` agora limita as tentativas de fair usage do Real-Debrid, que antes eram repetidas para sempre. `auto_analyze_new_torrents: false` e um `ffprobe_binary` ausente não impedem mais a limpeza do cache, que antes era pulada junto com a análise. Um filtro de tamanho que exclui o primeiro volume de um arquivo compactado agora esconde esse arquivo inteiro, em vez de cair para um volume posterior. Os assets estáticos sem autenticação foram ampliados de `/static/css/*` para `/static/*`. Nenhuma rota que antes era protegida ficou pública.

## Configuração no Windows {#windows-configuration}

Ao rodar o zurg no Windows, os caminhos precisam ser escritos de forma diferente:

```yaml
# Mount path - use drive letter with escaped backslash or forward slash
mount_path: "P:\\"       # Drive letter (escaped backslash)
mount_path: "P:/"        # Drive letter (forward slash also works)

# Binary paths - use forward slashes for paths to executables
ffprobe_binary: "Q:/zurg/bin/ffprobe.exe"
rclone_binary: "Q:/zurg/bin/rclone.exe"

# Alternative: use double forward slashes (also valid)
ffprobe_binary: "Q://zurg//bin//ffprobe.exe"
rclone_binary: "Q://zurg//bin//rclone.exe"
```

**Pontos principais para Windows:**
- Use aspas em todos os caminhos
- Para `mount_path`: use uma letra de unidade como `P:\` (escrita como `P:\\` no YAML) ou `P:/`
- Para caminhos de binários: barras normais `/` funcionam e evitam problemas com escape
- Garanta que a extensão `.exe` esteja incluída nos executáveis

## 1. Essenciais (configure primeiro) {#1-essentials-setup-first}

Estas são as configurações obrigatórias para colocar o servidor no ar.

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `zurg` | string | *(obrigatório)* | Identificador da versão da configuração. Deve ser definido como `v1`; qualquer outro valor (inclusive uma chave ausente) faz o carregamento falhar. |
| `providers` | list | *(obrigatório)* | Suas contas de debrid e Usenet, uma entrada para cada. Veja [Contas](#accounts) abaixo. As chaves de nível superior anteriores a providers `token`, `download_tokens` e `strm_link_token` estão obsoletas: elas ainda são carregadas, como uma única conta Real-Debrid, e a inicialização emite um aviso. Um bloco `providers` que já configura o Real-Debrid tem prioridade e a chave solta é ignorada. |
| `mount_path` | string | Depende do SO | O caminho do sistema de arquivos onde fica o seu mount do rclone. O zurg usa isso para dizer aos servidores de mídia (Plex, Jellyfin, Emby) onde encontrar os arquivos. Também é usado como ponto de montagem quando `rclone_enabled` é true. O padrão é `/mnt/zurg` (Linux), `/Volumes/Zurg` (macOS) ou `Z:` (Windows). Usuários do Docker devem definir isso como `/zurg_mnt/zurg` com a montagem de volume `/zurg_mnt:/zurg_mnt:rshared` (veja [docker.md](../setup/docker.md)). |
| `base_url` | string | `""` | A URL acessível de fora da sua instância do zurg. Ela é embutida nos arquivos STRM para que os servidores de mídia possam transmitir o conteúdo. Se não for definida, os arquivos STRM terão URLs `localhost`, que não funcionam em outros dispositivos. Use seu IP do Tailscale, seu IP da LAN ou um domínio com reverse proxy. Exemplo: `http://100.x.x.x:9999` |

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/mnt/zurg"
base_url: "http://192.168.0.123:9999"
```

### Contas {#accounts}

Cada entrada em `providers` é uma conta. Você pode rodar quantas quiser ao mesmo tempo: Real-Debrid, TorBox, AllDebrid, Premiumize, Debrid-Link e Offcloud juntos, ou várias contas no mesmo serviço.

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `type` | string | *(obrigatório)* | Qual backend a conta usa: `realdebrid`, `torbox`, `alldebrid`, `premiumize`, `debridlink`, `offcloud`, `nzb` ou `torbox_nzb` ([Usenet hospedado do TorBox](../providers/torbox-nzb.md)). |
| `name` | string | valor de `type` | Diferencia esta conta das outras do mesmo tipo. É o nome usado pelo filtro `provider`, pelo [diretório por conta](#per-account-directories), pelos caminhos de cache e pelo dashboard. Os nomes precisam ser únicos entre as entradas, e `e` é reservado para o roteamento de links STRM. |
| `token` | string | *(obrigatório)* | O token de API ou a chave da conta. Pegue um do Real-Debrid em http://real-debrid.com/?id=20475782, um do TorBox em https://torbox.app/settings, e um do AllDebrid em https://alldebrid.com/apikeys?uid=1kk5i. Não é usado por `nzb`, que se autentica pelo `nntp`. Um token do Real-Debrid também pode ser informado pela variável de ambiente `TOKEN` ou `RD_TOKEN` para criar a config automaticamente na primeira execução. |
| `download_tokens` | list | `[]` | **Real-Debrid e AllDebrid:** tokens de API de backup para o mesmo serviço, usados quando a franquia de banda do token ativo acaba. Eles usam o catálogo desta entrada, incluindo um [catálogo local](#local-debrid-catalogs), sem importar as bibliotecas de torrents das contas extras. **TorBox:** aceito, mas a rotação não remapeia os IDs de torrent/arquivo específicos da conta; use entradas de provider separadas para contas diferentes. Não é usado por NZB. Premiumize, Debrid-Link e Offcloud precisam de entradas de conta separadas, porque os IDs de arquivo armazenados pertencem à conta que fez a listagem. |
| `strm_link_token` | string | `""` | Um token de API separado que resolve as leituras que chegam ao endpoint `/strm/`, para que o player que abre um `.strm` não gaste o token que o mount ao vivo usa para o streaming. Usa `token` se não estiver definido. **Real-Debrid e AllDebrid**, os dois backends que rotacionam credenciais, e por isso os dois em que faz sentido fixar o tráfego `.strm` em uma chave própria. Aceito, mas não usado, em entradas `torbox` e `nzb`. Premiumize, Debrid-Link e Offcloud aceitam aqui apenas o `token` da própria conta. |
| `disabled` | bool | `false` | Mantém a conta na config sem carregá-la. Se todas as entradas estiverem desabilitadas, o carregamento falha. |
| `watchlist` | bool | `false` | Marca a conta que é testada primeiro para novas adições de torrent. Isso vale para os endpoints do cliente de download e para os indexadores Torznab da aquisição. No máximo uma entrada pode definir isso, e nunca uma entrada `nzb` ou `torbox_nzb`. Se nenhuma estiver definida, a primeira conta que pode adicionar torrents é usada. Os NZBs da aquisição vão para o backend Usenet e nunca para esta conta. Veja [Watchlist](#watchlist). |
| `add_torrents` | bool | `true` | Se esta conta recebe novos torrents — os que os endpoints do cliente de download recebem e os que a aquisição pega dos indexadores Torznab. Defina como `false` para uma conta de arquivo, ou para uma cuja cota já está comprometida: ela continua servindo e lendo a biblioteca, mas nada novo é colocado nela. **A ordem da lista `providers:` é a ordem em que as contas que aceitam adições são testadas**, então esta chave e essa ordem são lidas juntas; uma conta marcada com `watchlist: true` é testada primeiro, onde quer que esteja. Não pode ser combinada com `watchlist: true` na mesma entrada, e em uma entrada `nzb` é ignorada com um aviso na inicialização, já que um servidor de notícias nunca recebe um torrent. Veja [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see). |
| `warm_connections` | int | `1` | Quantas conexões esta conta mantém abertas e com handshake feito **com cada host que ela vem usando**, para que uma leitura não precise abrir uma conexão. Limitado a 4. `-1` não mantém nenhuma. Ignorado em uma entrada `nzb`, cujo mínimo é por conta e fica em [`nntp.warm_connections`](../guides/usenet.md). Veja [conexões aquecidas](#warm-connections). |
| `nntp` | block | *(obrigatório para `nzb`)* | Credenciais do servidor de notícias. Obrigatório para o tipo `nzb` e ignorado por todos os outros tipos. |

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    strm_link_token: YOUR_RD_API_TOKEN_FOR_STRM
    download_tokens:
      - ANOTHER_RD_API_TOKEN
      - ANOTHER_RD_API_TOKEN_2
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    watchlist: true
  - type: realdebrid
    name: rd-backup
    token: YET_ANOTHER_RD_API_TOKEN
    disabled: true
```

O `download_tokens` do TorBox não oferece o fallback de reprodução entre contas que os links bloqueados do RD e do AD permitem.
O resolvedor dele troca a chave de API mas mantém os IDs de torrent/arquivo da fonte existente.
Entradas de provider separadas do TorBox mantêm os IDs e o catálogo de cada conta independentes.
Para uma biblioteca local, coloque os manifests portáteis no diretório de fonte de cada entrada.

#### Seeding no TorBox {#torbox-seeding}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `tb_seed_torrents` | string | `never` | Se os torrents que o zurg adiciona a uma conta do TorBox fazem seed. `never` desliga o seed em todas as adições. `auto` deixa a escolha com a configuração de seeding da sua conta no TorBox. `always` liga o seed em todas as adições. Vale para todas as contas do TorBox na configuração e para a próxima adição assim que for alterado. Qualquer outro valor impede o zurg de iniciar. |

```yaml
tb_seed_torrents: never
```

Deixe em `never`, a menos que você precise. Essa opção existe para trackers privados que contam sua razão de upload. Uma release capturada pelo endpoint [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see) como arquivo `.torrent` é adicionada com essa configuração, então, com `always` (ou `auto` em uma conta configurada para fazer seed), o TorBox envia o arquivo de volta para o swarm do tracker. Importar no Sonarr ou no Radarr não impede isso: um download concluído que o cliente remove continua na conta.

**Um torrent em seed ocupa um dos slots ativos do seu plano enquanto estiver fazendo seed.** O TorBox conta um torrent em seed da mesma forma que um torrent baixando. Os planos permitem 3, 5 ou 10 ao mesmo tempo (Essential, Standard, Pro) e fazem seed por até 24 horas, 14 dias ou 30 dias. Quando todos os slots estiverem ocupados por torrents em seed, novas capturas e reparos nessa conta ficam parados até que um slot seja liberado, seja quando o tempo de seed do torrent acabar, seja quando você o excluir no TorBox. O seed também conta como upload para os limites de uso justo do TorBox. Com `never`, nada disso acontece, por isso é o padrão.

`auto` não envia ao TorBox nenhuma preferência de seeding, então vale o que a configuração de seeding da sua conta disser. Em uma conta em que ninguém tenha mudado isso, vale o Auto do próprio TorBox. `always` e `never` substituem a configuração da conta apenas para os torrents que o zurg adiciona e não mexem no resto da conta.

#### Contas de Usenet {#usenet-accounts}

O tipo `nzb` é Usenet, não um serviço debrid: arquivos `.nzb` colocados no diretório `nzbs/` viram torrents na biblioteca, e as leituras são atendidas buscando artigos do seu servidor de notícias e decodificando-os sob demanda.

Só é aceita uma entrada `nzb` habilitada, já que duas leriam o mesmo diretório. Servidores de notícias extras vão em `nntp.servers` dessa entrada, onde servem a mesma biblioteca em vez de uma segunda cópia dela.

Uma entrada `nzb` ao lado de uma [`torbox_nzb`](../providers/torbox-nzb.md) também é recusada pelo mesmo motivo. Rode esse tipo em uma instância própria, com seu próprio diretório de trabalho.

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `host` | texto | *(obrigatório)* | O nome do host do servidor de notícias, ex.: `news.example.com`. |
| `port` | inteiro | `563` com TLS, `119` sem | A porta do servidor de notícias. |
| `tls` | booleano | `false` | Envolve a conexão em TLS. |
| `username` | texto | `""` | O nome de usuário da conta. |
| `password` | texto | `""` | A senha da conta. |
| `connections` | inteiro | `8` | O limite de conexões simultâneas da conta. O zurg lê nesse número — uma conexão carrega só uma fração da velocidade do plano, então o streaming usa todo o limite em vez de buscar um artigo por vez. Passar do que o plano permite faz as conexões serem recusadas, então defina o valor real. |
| `pipeline_depth` | inteiro | `4` | Quantos artigos o zurg pede de uma vez em uma conexão. O limite é 8. Defina como `1` para um servidor que não aguenta vários comandos em andamento. O zurg cai para 1 sozinho, com um aviso, quando os lotes continuam se rompendo. |
| `socket_receive_buffer_kb` | inteiro | não definido | Fixa o buffer de recepção do kernel de cada conexão neste tanto de KiB. Deixe sem definir. Um buffer fixo é um que o kernel para de ajustar. No Linux, isso mantém a janela de recepção perto de 64 KiB e custa a maior parte da velocidade da conta em qualquer link com latência. Existe para kernels que nunca ajustam ou cujo teto está configurado baixo demais. |
| `cache_size_mb` | inteiro | `512` | Quanto dado de artigo decodificado fica guardado na memória, somando todos os arquivos sendo lidos, e não por arquivo. |
| `servers` | lista | `[]` | Outras contas de notícias para usar como fallback, artigo por artigo. Veja [mais de um servidor de notícias](#more-than-one-news-server). |

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
```

##### Mais de um servidor de notícias {#more-than-one-news-server}

As retenções são por provedor: um artigo que um servidor já deixou expirar quase sempre ainda está em outro. Sem uma segunda conta, a única forma de recuperar um artigo morto é o PAR2, e isso custa uma leitura de **toda a release**. Ou seja, um segundo servidor faz a diferença entre baixar um artigo e reler tudo.

As chaves acima descrevem a primeira conta. Qualquer coisa dentro de `servers` é outra conta, consultada apenas quando as anteriores não tinham o artigo. Uma configuração existente com um único servidor continua funcionando sem alterações.

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-----------|
| `name` | string | valor de `host` | Identifica a conta nos logs. |
| `host`, `port`, `tls`, `username`, `password`, `connections`, `pipeline_depth`, `warm_connections`, `socket_receive_buffer_kb` | | | Igual ao descrito acima. Cada conta tem sua própria cota de conexões. Pipelining e o buffer de recebimento são definidos por conta, porque a tolerância a eles pertence ao servidor. |
| `priority` | int | `0` | Quem é consultado primeiro, do menor para o maior. Contas com a mesma prioridade são consultadas na ordem em que foram escritas, exceto que uma com conexão livre é preferida a uma cuja cota já foi esgotada, então duas contas iguais dividem a carga. |
| `backup` | bool | `false` | Marca uma conta de reserva, consultada somente depois que todas as primárias tiverem respondido *no such article*. Uma primária **ocupada** não basta: o zurg espera por ela em vez de gastar bytes medidos em algo que uma conta ilimitada atenderia. |
| `backbone` | string | `""` | O spool de artigos em que esta conta se resolve. Duas contas no mesmo backbone têm os mesmos artigos, então, quando uma já disse que não tem um artigo, a outra é pulada em vez de receber a mesma pergunta. |

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # the first account
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com          # only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

O censo que decide se uma release precisa de reparo pergunta a todas as contas antes de dar um artigo como ausente. Assim, uma release com buracos em um provedor não dispara uma reconstrução por PAR2 quando outro provedor ainda consegue entregá-la.

Uma opção de nível superior controla o que os reparos deixam para trás:

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-----------|
| `par2_patch_cache_mb` | int | `512` | Quanto de `data/par2/` os bytes reconstruídos pelo reparo com PAR2 podem ocupar. Esses bytes são a única coisa que um leitor não consegue pedir de novo ao servidor de notícias, porque os artigos que os carregavam já sumiram. Mantê-los faz com que um reinício não custe uma releitura completa da release só para recuperar os mesmos poucos megabytes. Só são guardados os trechos dos artigos mortos, que ficam na faixa de um dígito de megabytes por release danificada. Releases inteiras são descartadas, da menos usada recentemente para a mais usada, quando o orçamento é excedido. Um valor negativo desliga a persistência e mantém os reparos na memória pelo tempo de vida do processo. |

Duas opções controlam quanto um NZB já analisado custa em memória:

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-----------|
| `nzb_segments` | string | `mmap` em Linux/macOS/BSD, `resident` no Windows | Como a lista de artigos de um NZB analisado é retida. **Requer reinício.** `mmap` grava as listas em `data/nzb-index/<id>.bin` e mapeia esse arquivo sob demanda, então os bytes ficam no cache de páginas em vez de na heap do zurg. `reparse` as devolve assim que a release se estabiliza e relê o NZB do disco quando uma leitura ou um reparo precisa delas, sem custo de disco algum. `resident` mantém todas elas na memória pelo tempo de vida do processo: **o comportamento anterior**, o que todas as versões anteriores faziam. Valores não reconhecidos assumem o padrão e são indicados em um aviso na inicialização. De qualquer forma, o modo realmente em uso é registrado no log na inicialização. |
| `nzb_segments_idle_secs` | int | `120` | Por quanto tempo a lista de artigos de uma release é mantida após a última leitura dela, nos modos lazy. **Requer reinício.** Uma varredura roda a cada 30 segundos, então 10 é a menor janela que ela consegue respeitar e também o mínimo do Dashboard. Ignorado em `resident`, que nunca devolve nada. `0` assume o padrão. |

A troca vale a pena ser dita claramente, porque não é a clássica de memória por velocidade. Uma listagem (uma atualização da biblioteca, uma verificação de impressão digital, um *arr perguntando se um job já se estabilizou) nunca toca em um artigo em nenhum modo: o nome de um arquivo, seu tamanho e sua contagem de artigos são respondidos pela própria entrada. O que os modos lazy custam é a *primeira* leitura de uma release que ninguém tocou por `nzb_segments_idle_secs`. O que economizam é o heap que as listas de artigos ocupam no resto do tempo. Medido em uma release de 60 arquivos e 30.000 segmentos (Apple M3 Pro):

| | heap por release, estabilizada | primeira leitura de uma release ociosa | por artigo no caminho de leitura |
|---|---|---|---|
| `resident` | 1.74 MB (58 B/segment) | — | 6 ns |
| `reparse` | 21.3 kB (0.71 B/segment) | 39 ms | 52 ns |
| `mmap` | 16.6 kB (0.55 B/segment) | 0.27 ms | 63 ns |

Dois terços da recarga do `mmap` são o checksum sobre o índice que acabou de ser mapeado. O mapa em si leva 0.08 ms. Esse custo vale a pena: sem o checksum, um único byte ruim dentro de uma arena seria servido como um message id que ninguém postou. O servidor de notícias responderia como artigo morto, e todas as camadas acima leriam isso como dano à release.

E em uma biblioteca real (2,636 NZBs, 27.6 million segments, o mesmo binário rodado três vezes sobre o mesmo corpus, ocioso após uma varredura):

| | resident set | live heap | CPU ociosa | abertura a frio, p50 | índice em disco |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

Aberturas a quente, throughput de streaming e tempo de inicialização foram indistinguíveis. `mmap` é o padrão sempre que há um mapeamento real, porque vence em todos os eixos exceto o disco. Isso inclui a abertura a frio, já que mapear uma arena gravada é uma syscall, enquanto analisar o NZB de novo são megabytes de XML. Ele custa cerca de 55 bytes de disco por artigo e uma gravação extra por release no momento da varredura. O índice é reescrito sempre que o NZB muda e removido quando o NZB some. Escolha `reparse` em um host onde `data/` não pode crescer. No Windows não há mapeamento: o índice seria lido para o heap, o que equivale à memória residente *mais* uma recarga. Por isso o padrão lá continua sendo `resident`, e `reparse` é o modo lazy que vale a pena escolher.

## 2. Integração com o servidor de mídia {#2-media-server-integration}

Conecte o zurg ao seu servidor de mídia para que as atualizações da biblioteca, a correspondência de metadados e o monitoramento da watchlist funcionem automaticamente.

### Premiumize, Debrid-Link e Offcloud {#premiumize-debrid-link-and-offcloud}

```yaml
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY_OR_OAUTH_TOKEN
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_TOKEN
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
```

Estes backends suportam navegação na biblioteca, leituras em streaming e redirecionadas, STRM, adição por magnet, envio de arquivos `.torrent` e exclusão. Cada conta também aparece no próprio diretório `__<name>__`. Adicione as contas pelo dashboard ou com `zurg setup`; a configuração sem interação aceita `--premiumize-token-file`, `--debridlink-token-file` e `--offcloud-token-file`, ou `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN` e `OFFCLOUD_TOKEN`.

O Premiumize monta as transferências concluídas e os arquivos da nuvem que continuam salvos depois que a lista de transferências é limpa. As pastas aninhadas mantêm os seus caminhos. Os hashes enviados pelo zurg são salvos em `data/premiumize/<account>/sources.json`, para que a correspondência entre contas continue funcionando após uma reinicialização ou após limpar as transferências concluídas. Conteúdo importado da nuvem sem um hash registrado ainda faz streaming, mas não pode ser reparado por hash nem associado a outra conta por hash. Excluir uma transferência do Premiumize pelo zurg também exclui os arquivos pertencentes a essa transferência. As cotas de armazenamento na nuvem e de uso justo continuam sendo os limites da própria conta.

O Debrid-Link lista o seedbox com paginação e resolve cada arquivo pelo seu ID. O endpoint de cache, que foi descontinuado, não é usado; uma adição somente em cache só consegue confirmar um hit pela resposta da adição. Falhas de cota diária de adições e de tráfego são reportadas como limites da conta. O backend pausa depois de uma recusa por flood.

O Offcloud resolve os file handles pelo endpoint de explorar a nuvem. Os tamanhos dos arquivos são conferidos com o servidor de entrega, e os metadados de torrent em cache fornecem os caminhos das pastas sempre que for possível associá-los sem ambiguidade. Uma listagem de arquivos ambígua é reportada como erro. Magnets malformados são rejeitados antes do envio.

As URLs de entrega são atualizadas quando o cache expira ou quando uma leitura as invalida. Mantenha as URLs geradas e o acesso STRM privados; as cotas do provedor pertencem à conta que entrega os bytes. Esses três backends usam uma credencial por entrada de conta e não alternam entre os IDs de arquivo de outra conta.

### Integração com o Plex {#plex-integration}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `plex_server_url` | string | `""` | URL do seu servidor Plex. Obrigatório para a correspondência com o Plex e os recursos de watchlist. Exemplo: `http://localhost:32400` |
| `plex_token` | string | `""` | Seu token de autenticação do Plex. Obrigatório junto com `plex_server_url`. |
| `plex_scan_check_url` | string | valor de `plex_server_url` | O servidor Plex que o zurg consulta para saber se uma varredura da biblioteca está em andamento antes de reiniciar o mount. Ele espera enquanto houver uma. Um mount que some no meio de uma varredura faz o Plex mandar para a lixeira tudo o que não conseguiu ver. Defina isso em uma instância que não tenha integração própria com o Plex. O caso comum é uma instância por provedor. Definir `plex_server_url` ali também ativaria a correspondência com o Plex. |
| `plex_scan_check_token` | string | valor de `plex_token` | O token para `plex_scan_check_url`. |
| `plex_match_every_mins` | int | `1440` | Com que frequência (em minutos) o zurg varre sua biblioteca do Plex para associar torrents aos itens do Plex. Isso ativa recursos como mostrar quais torrents correspondem a qual mídia do Plex. Mínimo 1; `0` usa o padrão. Exige que `mount_path` esteja definido. |
| `plex_watchlist_enabled` | bool | `false` | Grafia antiga de `watchlist.enabled` (veja [Watchlist](#watchlist)); ainda é respeitada. |
| `plex_watchlist_check_every_secs` | int | — | Grafia antiga de `watchlist.check_every_secs`; ainda é respeitada quando o bloco não define um valor. |
| `watchlist_quality` | string | `"best"` | Grafia antiga de `watchlist.quality`; ainda é respeitada quando o bloco não define um valor. |
| `plex_settings_policy` | string | `"guard"` | Até onde o zurg pode ir ao corrigir as preferências do Plex que importam para um mount de debrid. Um de `off` (não mexe em nada), `warn` (informa tudo, não muda nada), `guard` (corrige só as configurações cujo valor errado faz perder uma biblioteca, e informa o resto) ou `enforce` (também corrige as configurações que fazem o Plex decodificar arquivos inteiros para um resultado que ninguém vê). Qualquer coisa com um recurso visível por trás — Skip Intro, Skip Credits, prévias de scrubbing, imagens de capítulos, nivelamento de volume, análise sonora — só é informada. Veja [Plex settings](../guides/plex.md#recommended-plex-settings). |
| `plex_settings_ignore` | list | — | IDs de preferências do Plex que o zurg deixa em paz, independentemente da política, sem diferenciar maiúsculas de minúsculas. É por configuração, e não por nível, então desativar uma não abre mão das outras ao lado. Um ID que não corresponde a nenhuma configuração conhecida pelo zurg é informado na inicialização e não muda nada. A chave **Let Plex Empty Its Own Trash** do painel grava `autoEmptyTrash` nesta lista. Veja [Opting out of one setting](../guides/plex.md#opting-out-of-one-setting). |

> **Nota:** O Plex é melhor configurado pelo Dashboard (interface web), usando o fluxo de autenticação; ele grava `plex_server_url` e `plex_token` de volta no `config.yml`. As chaves acima continuam suportadas para configuração manual.

```yaml
plex_server_url: "http://localhost:32400"
plex_token: "your-plex-token"
plex_match_every_mins: 1440
```

### rex

zurg pode preencher um [rex](../../rex/with-zurg.md), um servidor de mídia para os apps oficiais do Plex que lê cada arquivo do zurg.

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `rex_url` | string | `""` | URL do rex que monta a biblioteca a partir deste zurg, por exemplo `http://192.168.1.20:32400`. Ao escolher um rex no login do Plex no painel, isso define o endereço que o rex usa para as fontes (o endereço LAN ou Tailscale dele, em HTTP simples), e o envio começa sem precisar reiniciar. Defina manualmente para alimentar um rex sem fazer login no Plex. O zurg então envia a biblioteca para o rex: cada arquivo de vídeo em um diretório configurado, cada arquivo de áudio em um deles com `rex_music` e as HQs em um com `rex_photos`, com o caminho, o tamanho, o id do IMDb e os detalhes de mídia que o ffprobe leu. Isso acontece quando a biblioteca termina de carregar, a cada `rex_snapshot_every_hours`, e sempre que um release é adicionado, analisado, renomeado, movido ou excluído. O rex não consegue reproduzir um arquivo antes de o ffprobe analisá-lo, então definir `rex_url` liga `auto_analyze_new_torrents` independentemente do que essa chave diz, e analisa o resto da biblioteca assim que ela carrega e depois todo dia. Cada probe lê da conta que tem o release, então mantenha os diretórios restritos e deixe de fora os filtros `tags_*` (com qualquer um deles, todo release da conta é analisado) se você não quiser que uma biblioteca que nunca assiste gere tráfego. Um refresh também busca o id do IMDb de cada novo release por meio de `dmm_api_key` antes de organizá-lo (veja `dmm_api_key` para saber como os releases são colocados). Legendas que um \*arr ou o Bazarr grava ao lado de um vídeo em `__magic__` são enviadas ao rex junto com ele (veja [`__magic__`](../guides/magic.md)). O zurg diz ao rex onde ler os arquivos: o WebDAV dele em `http://<address>:<port>/dav`, com `username` e `password` quando estiverem definidos. O endereço é `host` quando é um único endereço; caso contrário, o padrão, é o endereço por onde sai a conexão do zurg com o rex, e o rex precisa conseguir alcançá-lo ali. Em um container, esse é o endereço do próprio container, que o rex só alcança a partir da mesma máquina Linux: no Windows e no macOS, instale o zurg com o instalador em vez do Docker Desktop, e no Linux, com o rex em outra máquina, use `network_mode: host` no container do zurg ([rex com zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex)). Um rex que está fora do ar é tentado de novo e depois recebe a biblioteca inteira; nada fica esperando por ele. Nenhum scan do Plex é enviado enquanto `plex_server_url` for este mesmo rex. Depois de cada snapshot e a cada dez minutos, o zurg lê os Fix Matches feitos no rex para os releases dele e mantém cada um como o id definido manualmente do release, a menos que você tenha definido outro na página manage desde então; o DMM então coloca o release com base nele. Para dar a um diretório as próprias bibliotecas no rex, defina [`rex_shows`, `rex_movies`, `rex_music` ou `rex_photos`](#directory-options) nele. Deixe `rex_url` vazio se você não usa o rex. |
| `rex_source` | string | `"zurg"` | O nome da fonte que o rex conhece este zurg. Dê a cada zurg que alimenta o mesmo rex um nome próprio. |
| `rex_snapshot_every_hours` | int | `6` | Com que frequência a biblioteca inteira é enviada de novo ao rex, o que corrige o que um envio perdido deixou para trás. O padrão serve para qualquer configuração. |

```yaml
rex_url: "http://192.168.1.20:32400"
```

### Watchlist

Adicione algo à sua watchlist do Plex e o zurg busca o item. Cada item novo da watchlist é pesquisado nos seus indexadores. Um indexador Newznab entrega um NZB. Ele cai no backend de Usenet exatamente como uma captura do Sonarr ou uma reprodução do Stremio. Os três compartilham as regras de nomenclatura, então encontram as capturas uns dos outros em vez de duplicá-las. Um indexador Torznab entrega um torrent. Ele só é adicionado a uma conta de debrid quando essa conta já o tem em cache. `prefer` decide qual tipo é tentado primeiro entre releases da mesma resolução. Um filme vira um único release. Uma série é adquirida temporada por temporada, e os pacotes de temporada vêm antes dos episódios avulsos. Uma temporada que ninguém postou em pacote volta para os episódios avulsos que a busca encontrou, o melhor release de cada um. O item só sai da watchlist depois que o release por trás dele foi verificado, e somente quando `remove_after_grab` permitir. Falhas continuam na lista. Elas são tentadas de novo após 5, 10 e 15 minutos, depois após uma hora, e então com intervalos cada vez maiores. Um título que falhou por duas semanas fica pausado até você retomá-lo na página Acquisition. Veja [persistência e recuperação](../guides/acquisition.md#persistence-and-recovery).

Ele precisa de um `plex_token` e de pelo menos um indexador. Sem lista própria, ele usa a do addon do Stremio. O monitor fala com o serviço em nuvem do Plex, então `plex_server_url` não é obrigatório. NZBs precisam de um provedor `nzb` ou `torbox_nzb` na mesma instância. Torrents precisam de uma conta de debrid que os aceite. Basta uma das duas.

Todas as opções abaixo estão na página de configuração em **Plex Watchlist**, incluindo a lista de indexadores. O dashboard grava este bloco em vez das chaves planas antigas, e desligar o monitor ali também limpa `plex_watchlist_enabled`, já que essa chave entra em OR no interruptor.

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `enabled` | bool | `false` | Inicia o monitor. A chave legada `plex_watchlist_enabled` continua valendo. |
| `check_every_secs` | int | `60` | Com que frequência a watchlist é consultada no serviço em nuvem do Plex. |
| `indexers` | list | `[]` | Indexadores para pesquisar, cada um com `name`, `url`, `api_key` e, opcionalmente, `api_path` e `type`. `type: torznab` marca um indexador de torrent. Ausente significa `newznab`. Mesmo formato de `stremio.indexers`, que é usado inteiro quando esta lista está vazia. |
| `prefer` | string | `"usenet"` | Qual tipo é tentado primeiro quando um NZB e um torrent da mesma resolução poderiam servir. A resolução decide primeiro, então um torrent 2160p vai antes de um NZB 1080p. `usenet` tenta NZBs primeiro, `torrents` tenta torrents primeiro, e `best` deixa só o ranking decidir. Veja [Newznab e Torznab](../guides/acquisition.md#newznab-and-torznab). |
| `max_size_gb` | int | `0` | Releases maiores que isto são descartados para filmes e episódios avulsos, e pacotes de temporada com mais que isto por episódio. `0` significa sem limite, então `best` pega um remux de disco completo. Releases cujo tamanho o indexador não informou são mantidos. |
| `max_season_size_gb` | int | `0` | Um limite para cada temporada que um pacote de temporada contém, por temporada que ele indica. `0` significa sem limite: um pacote só é descartado pelo `max_size_gb` por episódio, quando esse estiver definido, então o remux de uma temporada longa ainda conta. |
| `quality` | string | `"best"` | Qual release vence: `best` (resolução primeiro, depois tamanho), `4k`, `1080p`, `720p` (prefere essa resolução e cai para o melhor) ou `smallest`. A chave legada `watchlist_quality` continua valendo. Aqui é um valor só; apenas `acquisition.quality` aceita lista (veja [Fontes de aquisição](#acquisition-sources)). |

O bloco `acquisition` também aceita `concurrency` (padrão `8`, de `1` a `200`), que define quantos títulos são pesquisados, verificados e colocados ao mesmo tempo, e `indexer_concurrency` (padrão `3`, de `1` a `16`), que define quantas chamadas são feitas a um indexador ao mesmo tempo. Mantenha este último baixo quando uma chave de indexador for compartilhada.

`exclude_words` não tem cópia neste bloco. Para manter palavras como `DV` ou `HDR10+` fora das capturas da watchlist, adicione um bloco `acquisition:` contendo apenas `exclude_words`. Todas as configurações acima continuam valendo. Veja [excluindo releases pelo nome](../guides/acquisition.md#excluding-releases-by-name).

```yaml
plex_token: "your-plex-token"
watchlist:
  enabled: true
  check_every_secs: 60
  quality: best
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: your-api-key
```

### Fontes de aquisição {#acquisition-sources}

`acquisition.sources` lista os serviços para os quais o zurg adquire, cada um na fila compartilhada descrita em [fontes de aquisição](../guides/acquisition.md). As configurações de busca (`indexers`, `quality`, `prefer`, `max_size_gb`, `max_season_size_gb`) ficam ao lado de `sources` no bloco `acquisition:` e usam o bloco `watchlist:` acima como reserva. Só o `acquisition.quality` também aceita uma lista de resoluções, como `[1080p, 4k]`: nesse caso, o zurg mantém uma cópia de cada filme da lista de desejados do DMM em cada uma delas, enquanto séries dessa lista e todas as outras fontes usam a maior resolução da lista como único `quality`. Veja [uma cópia em cada uma de várias resoluções](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

`best_first` fica só no bloco `acquisition:` e vem desligado por padrão. Quando ligado, a primeira captura de uma fonte `radarr` ou `sonarr` segue a ordem de preferência do perfil de qualidade. A melhor resolução permitida vem primeiro. Qualquer coisa igual ou acima do cutoff conta como o cutoff. Se uma release falhar, o zurg desce no perfil. Quando está desligado, um filme pega a release permitida mais barata de verificar. Uma série pega a que o `quality` ranqueia em primeiro. Depois, a passagem de upgrade vai atrás do cutoff. A melhor release costuma ser um conjunto grande de arquivos, então o primeiro arquivo tende a chegar mais tarde. Veja [pegando a melhor do perfil primeiro](../guides/acquisition.md#taking-the-profiles-best-first).

`exclude_words` (lista, padrão vazio) também fica ali e não tem reserva na watchlist. Uma release cujo nome tenha uma dessas palavras nunca é pega, de nenhuma fonte. A comparação é por palavra inteira e ignora maiúsculas e minúsculas, então `DV` não pega `DVDRip`. `DV`, `DoVi` e `Dolby Vision` contam como uma palavra só, e o mesmo vale para `HDR10+` e `HDR10Plus`. `HDR10` e `HDR10+` são palavras diferentes. Uma entrada sem nenhuma letra ou dígito é recusada na inicialização. As regras completas e como elas se combinam com os perfis do Radarr e do Sonarr estão em [excluindo releases pelo nome](../guides/acquisition.md#excluding-releases-by-name).

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `name` | string | obrigatório | Letras, dígitos, `_` e `-`, únicos. Identifica a fila salva da fonte, então mantenha estável. |
| `type` | string | obrigatório | `plex_watchlist`, `seerr`, `radarr` ou `sonarr`. |
| `enabled` | bool | `false` | Uma fonte desativada fica no arquivo e não é consultada. Uma fonte `radarr` ou `sonarr` desativada ainda é lida, somente leitura, pela [visão de duplicatas](../guides/acquisition.md#finding-duplicate-releases) da página de gerenciamento. |
| `check_every_secs` | int | `60` | Com que frequência a fonte é consultada. |
| `url` | string | | `seerr`, `radarr` e `sonarr`: a URL base HTTP(S) do serviço, sem credenciais, query ou fragmento. Uma URL base com `/api/v1` no final (Seerr) ou `/api/v3` (Radarr, Sonarr) também é aceita. |
| `api_key` | string | | `seerr`, `radarr` e `sonarr`: a chave de API do serviço. Enviada como cabeçalho, nunca na URL, e ocultada de logs e configs compartilhados. |
| `library_path` | string | `mount_path` + `/__magic__` | Apenas `radarr` e `sonarr`: onde o \*arr enxerga o diretório `__magic__` do zurg, como `/data/zurg/__magic__` para um contêiner que monta o zurg em `/data/zurg`. Uma pasta de filme ou série dentro dele é colocada no mesmo caminho relativo dentro de `__magic__`; uma pasta fora dele é ignorada. Precisa ser absoluto; caminhos do Windows como `Z:\__magic__` são aceitos. O zurg também compara com onde o \*arr enxerga a pasta de download de um cliente de download do zurg e avisa sobre um layout que faz as importações virarem cópias; veja [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). |
| `remove_after_grab` | bool | `true` | Apenas `plex_watchlist`; sem efeito para `seerr`, `radarr` e `sonarr`. |
| `only_new_items` | bool | `true` | Apenas `plex_watchlist`; sem efeito para `seerr`, `radarr` e `sonarr`, cujos itens desejados são sempre trabalho. |

```yaml
acquisition:
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
  sources:
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /data/zurg/__magic__
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /data/zurg/__magic__
```

### Manutenção da biblioteca do Plex (apenas no mesmo host) {#plex-library-maintenance-same-host-only}

Estes precisam que o Plex esteja instalado na mesma máquina do zurg, porque eles leem o arquivo de banco de dados diretamente. `plex_server_url` costuma ser outro host ou contêiner, e nenhum endpoint HTTP consegue entregar esse arquivo. Por isso, eles são controlados por um caminho explícito e ficam desligados até você definir um.

O zurg só **lê** esse banco de dados, por meio de um handle somente leitura. Ele nunca escreve nele nem para o Plex. O único arquivo que ele cria é um snapshot em `data/plex-backups/` dentro da própria pasta do zurg, nunca no diretório do Plex.

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `plex_database_path` | string | `""` | Caminho completo para `com.plexapp.plugins.library.db`. Vazio desliga todos os recursos desta seção. |
| `plex_sqlite_binary` | string | onde o Plex instala: `/usr/lib/plexmediaserver/Plex SQLite` no Linux, `/Applications/Plex Media Server.app/Contents/MacOS/Plex SQLite` no macOS, `%ProgramFiles%\Plex\Plex Media Server\Plex SQLite.exe` no Windows | O Plex inclui sua própria build do SQLite. Um `sqlite3` comum pode falhar ou danificar este banco de dados. |
| `plex_backups_keep` | int | `5` | Quantidade de snapshots mantidos. Cada um tem o tamanho do banco de dados inteiro. Um `0` explícito apenas observa, sem nunca criar snapshots. |
| `plex_backups_every_mins` | int | `15` | Intervalo mínimo entre snapshots, para que um zurg em loop de crash não copie o banco a cada reinício. |
| `plex_trash_sweep_every_mins` | int | não definido (veja a nota) | Com que frequência remover entradas do Plex cujos arquivos sumiram do mount. Se não definido, o zurg decide: a remoção roda a cada 60 minutos quando nada mais esvazia a lixeira do Plex, e recua quando o Plex ainda esvazia. Um `0` explícito mantém a remoção do próprio zurg desligada e deixa a lixeira por sua conta; um valor negativo desliga a varredura inteira, incluindo o reparo. `0` **não** devolve o esvaziamento da lixeira ao próprio Plex, o que é feito por `plex_settings_ignore` e pela chave **Let Plex Empty Its Own Trash** do dashboard. Veja [Quem esvazia a lixeira](../guides/plex.md#who-empties-the-trash). |
| `plex_trash_sweep_max_items` | int | `50` | Número máximo de entradas que uma única varredura pode remover. Ultrapassar esse limite aborta a varredura sem remover nada. |
| `plex_trash_sweep_max_percent` | int | `10` | O mesmo limite, em porcentagem do conteúdo da lixeira, para escalar com o tamanho da biblioteca. |
| `plex_trash_sweep_min_age_days` | int | `14` | Por quanto tempo uma entrada mantém o ícone vermelho de lixeira antes de a varredura poder removê-la. É o fallback para entradas sobre as quais o zurg não tem veredito. Um release que o zurg sabe estar permanentemente morto é removido sem esperar, e um que ainda está em reparo permanece independentemente da idade. Um `0` explícito remove assim que as outras proteções permitirem. |

**Por que snapshots**, já que o Plex faz backup sozinho todas as noites: o perigo é o mount ser perturbado enquanto o Plex está no meio de um scan, o que pode esvaziar uma biblioteca em segundos. Um backup noturno pode estar 24 horas defasado nesse momento; um tirado logo antes de o zurg tocar no mount tem apenas segundos.

#### O que a limpeza da lixeira nunca vai remover {#what-the-trash-sweep-will-never-remove}

A lixeira do Plex não é uma lista de coisas que podem ser apagadas. É uma lista de candidatos, e uma grande parte deles está errada:

- **Um item que ainda tem arquivo.** O Plex marca um filme inteiro como apagado quando uma única de suas versões desaparece, então um item na lixeira costuma ter versões que ainda tocam. A varredura remove a versão fantasma, e isso tira o item da lixeira com suas coleções, artes, estado de exibição e `added_at` intactos. Se essa correção falhar por qualquer motivo, o item é **deixado em paz** — ele continua na sua biblioteca com o ícone de lixeira. Ele nunca é apagado.
- **Uma série ou temporada cujos episódios ainda estão lá.** Esses não têm arquivo nenhum, então nada sobre o mount pode justificar remover um deles.
- **Qualquer item cujo arquivo não foi confirmado individualmente como ausente**, logo antes de removê-lo.

A remoção é feita item por item, e não pelo `emptyTrash` do próprio Plex. O `emptyTrash` vale para a seção inteira e levaria exatamente os itens acima, que é justamente o que a varredura não pode fazer.

#### O zurg já sabe se o arquivo vai voltar {#zurg-already-knows-whether-it-is-coming-back}

Para cada arquivo ausente, a varredura consulta primeiro o estado de reparo que o próprio zurg informa, antes de recorrer ao temporizador:

| Veredito do zurg | A varredura |
|---|---|
| o arquivo ainda aparece (os filtros o escondem do mount) | recorre à janela de idade |
| quebrado, e o reparo ainda não desistiu | **mantém a entrada**, por mais tempo que o reparo leve |
| quebrado com um motivo de reparo permanentemente impossível (infringing, invalid, not allowed, …) | **remove na hora** — esperar não vai trazê-lo de volta |
| sem veredito — o torrent saiu totalmente da conta, ou o caminho não resolve | recorre à janela de idade |

Um item com várias versões é avaliado como uma unidade: se uma versão ainda estiver em reparo, a entrada inteira é mantida, e uma entrada só é considerada morta quando todas as versões estiverem mortas. Uma consulta que falha nunca é motivo para apagar nada: tudo que o zurg não consegue confirmar é tratado pela janela de idade abaixo, exatamente como antes.

#### O ícone da lixeira é um status, então a remoção espera {#the-trash-icon-is-a-status-so-removal-waits}

| Estado | O que você vê |
|---|---|
| Live | um item normal que toca |
| **Trashed** | o item **continua na sua biblioteca e continua sendo contado**, em cinza, com um **ícone de lixeira vermelho**, e não toca |
| Purged | nada: o item foi removido do Plex por completo |

O ícone de lixeira é o único aviso de que um conteúdo sumiu, e apagar o item leva esse aviso junto: o item deixa de parecer quebrado e simplesmente deixa de existir. Por isso, um item que o zurg não tem veredito sobre fica intacto até ter exibido o ícone por `plex_trash_sweep_min_age_days`. Esse período é a sua chance de ver o item e buscá-lo de novo. Qualquer coisa que continue quebrada depois disso era lixo que valia a pena limpar.

Ele também funciona como uma terceira camada de segurança, além dos limites e da verificação do mount. Um problema passageiro no mount se resolve muito antes de esse período acabar.

O período de espera vale **apenas para a remoção**. Um reparo coloca de volta na biblioteca um item que pode ser tocado, então ele acontece na próxima varredura, independentemente disso: esperar deixaria um item funcionando com ícone de lixeira à toa.

Nenhum desses estados mexe nos arquivos. O arquivo já tinha sumido do mount, e foi isso que causou o tombstone. Nada é apagado da sua conta de debrid.

#### Quando ele se recusa a rodar {#when-it-refuses-to-run}

- O zurg não está gerenciando o rclone (`rclone_enabled: false`). Ele não pode garantir um mount que não é dele, então "o arquivo está faltando" não quer dizer nada.
- O rclone não está rodando, ou o mount não consegue ler. A sondagem abre e lê um arquivo em vez de chamar `stat`, porque um `stat` é respondido pelo cache de diretórios do rclone e continua dando certo muito depois de as leituras pararem de funcionar.
- O Plex está fazendo um scan. Um scan em andamento ainda está decidindo o que está faltando.
- Algum dos dois limites seria ultrapassado. Este é o mais importante: **um mount que voltou vazio, mas legível, passa em todas as outras verificações** e faz a biblioteca inteira parecer apagada. Ultrapassar um limite aborta a varredura por completo, não remove nada e registra isso no log.

Um snapshot é feito antes de qualquer remoção, e uma falha no snapshot aborta a varredura.

> **Para desligar:** defina `plex_trash_sweep_every_mins: 0` (remover a chave não é a mesma coisa: aí o zurg decide com base em se o Plex esvazia a própria lixeira). Mudar isso exige reiniciar o zurg. Isso desliga só a remoção feita pelo zurg. Para o Plex voltar a esvaziar a própria lixeira, use o switch **Let Plex Empty Its Own Trash** no dashboard, ou inclua `autoEmptyTrash` em `plex_settings_ignore`.

```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plex_trash_sweep_every_mins: 360
plex_trash_sweep_min_age_days: 14
plex_trash_sweep_max_items: 50
plex_trash_sweep_max_percent: 10
```

Esse é o caminho onde o pacote Linux guarda o banco de dados. No macOS e no Windows, escreva o caminho completo, já que o zurg não expande `~` nem `%LOCALAPPDATA%`. `plex_sqlite_binary` já vem por padrão com o local onde o Plex o instala em cada sistema.

| Plex no | `plex_database_path` |
|---|---|
| macOS | `/Users/you/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db` |
| Windows | `C:\Users\you\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db` |

Coloque um caminho do Windows entre aspas simples no YAML para que as barras invertidas fiquem exatamente como estão escritas.

> **Configuração relacionada do Plex, fora do zurg:** desligue em *Settings → Library → Empty trash automatically after every scan* no Plex. Essa opção vem ativada por padrão no Plex e é insegura em um mount do zurg. Um scan que encontra um mount temporariamente ilegível apaga a biblioteca permanentemente, em vez de mandá-la para a lixeira, de onde ela voltaria junto com o mount. Com a política padrão `guard`, o zurg desliga essa opção sozinho e informa isso no dashboard e no log. Se seus arquivos mudam de pasta de biblioteca e você precisa dessa limpeza de volta, o switch **Let Plex Empty Its Own Trash** na página de configuração devolve a limpeza ao Plex, por sua conta e risco.

### Outras integrações {#other-integrations}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `jellyfin_server_url` | string | `""` | URL do seu servidor Jellyfin. Ativa as notificações de atualização da biblioteca quando o zurg detecta mudanças. Exemplo: `http://localhost:8096` |
| `jellyfin_token` | string | `""` | Token de API do Jellyfin para autenticação. |
| `emby_server_url` | string | `""` | URL do seu servidor Emby. Ativa as notificações de atualização da biblioteca quando o zurg detecta mudanças. Exemplo: `http://localhost:8096` |
| `emby_token` | string | `""` | Token de API do Emby para autenticação. |
| `dmm_api_key` | string | `""` | Sua chave de API do DMM. O [gatekeeper](https://gatekeeper.debridmediamanager.com/) mostra ela uma vez que você apoiar o projeto. Depois disso, o DMM organiza seus arquivos e preenche sua lista de desejados. |
| `dmm_metadata_secret` | string | `""` | Segredo para a API interna de metadados do DMM. Quando definido, os torrents sem id do IMDb (ou só com o marcador de falha do OpenSubtitles) são identificados na inicialização pelo nome da release, através do DMM, que responde apenas quando um único título bate exatamente. Os torrents que ele não consegue nomear mantêm o id vazio, para que o matcher do Plex ainda possa preenchê-los. |

```yaml
jellyfin_server_url: "http://localhost:8096"
jellyfin_token: ""
emby_server_url: "http://localhost:8096"
emby_token: ""
dmm_api_key: ""
```

## 3. Reprodução e estrutura de arquivos {#3-playback--file-structure}

Controla quais arquivos o seu servidor de mídia enxerga e como o conteúdo é transmitido.

### Modo de streaming {#streaming-mode}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `disable_stream_proxy` | bool | `false` | Quando true, uma leitura do **mount** é respondida com um redirecionamento para a URL de download da própria conta, em vez de passar pelo zurg. Isso reduz o uso de CPU e de banda do zurg, mas significa que o cliente precisa conseguir acessar os servidores da conta diretamente. Não tem efeito para um backend cujos links são servidos localmente — um arquivo do Usenet não tem URL para entregar, então ele sempre passa pelo proxy. **Leia os riscos do provedor abaixo antes de ativar.** |
| `serve_strm_files` | bool | `false` | Quando true, o zurg serve arquivos `.strm` no lugar dos arquivos de vídeo reais no mount WebDAV. Servidores de mídia como Plex/Jellyfin leem o arquivo `.strm` para obter a URL de streaming. **Importante:** quando ativado, os arquivos de vídeo reais ficam ocultos e são substituídos pelas entradas `.strm`. |
| `save_strm_files` | bool | `false` | Quando true, o zurg grava arquivos `.strm` em um diretório `strm/` ao lado do binário do zurg. Útil para configurações em que você quer arquivos STRM persistentes no disco (por exemplo, para importação manual em um servidor de mídia). Usa `base_url` para as URLs dentro dos arquivos. Apenas arquivos que um player consegue abrir recebem um — vídeo e áudio reconhecidos, além de qualquer coisa que `addl_playable_extensions` indique — então legendas, pôsteres, NFOs e volumes PAR2 ficam de fora, e quaisquer que uma versão mais antiga tenha gravado ali são removidos na próxima vez que o release for percorrido. Um `.strm` cuja URL não corresponde mais, porque `base_url` mudou ou porque uma versão mais antiga o gravou, é reescrito no lugar na próxima inicialização, ou imediatamente se `base_url` for alterado no painel. Arquivos que já correspondem não são tocados, então um servidor de mídia não precisa reler a pasta inteira a cada varredura. |

```yaml
disable_stream_proxy: false
serve_strm_files: false
save_strm_files: false
```

**Mantenha as leituras do mount passando pelo proxy (o padrão) para reprodução de debrid compartilhado.** A Real-Debrid acompanha o IP público de cada downloader; usar uma mesma conta a partir de vários IPs gera um aviso de compartilhamento, mesmo quando o download funciona. Mantenha todo uso dessa conta em um único IP público, incluindo verificações e conversões feitas pelo servidor, e não apenas os downloads do player. As URLs de download da TorBox contêm a chave de API completa em `?token=`, então um redirecionamento dá acesso a todos os clientes e usuários compartilhados da conta, inclusive para exclusão; logs do player e o histórico do navegador podem guardá-la. Não entregue links da TorBox a clientes não confiáveis.

Esses riscos valem tanto para os redirecionamentos do mount com `disable_stream_proxy: true` quanto para os redirecionamentos de `/strm/`. Manter `disable_stream_proxy: false` **não** faz a reprodução de `.strm` passar pelo proxy nem a torna segura para compartilhamento remoto.

#### O que o `disable_stream_proxy` alcança e o que não alcança {#what-disable_stream_proxy-does-and-does-not-reach}

Ele controla o mount. Ele não alcança o endpoint `/strm/`, em nenhum backend:

| Leitura chega via | Real-Debrid / TorBox / AllDebrid | Usenet |
|---|---|---|
| Mount, proxy ligado (padrão) | passa pelo proxy do zurg | passa pelo proxy |
| Mount, proxy desligado | `302` para a URL da conta | passa pelo proxy — não existe URL para redirecionar |
| Um arquivo `.strm`, qualquer configuração | `307` para a URL da conta | passa pelo proxy |

Um `.strm` é aberto por um player com o qual o zurg não tem sessão, então o endpoint só pode entregar uma URL que o próprio player consiga buscar. Ligar o proxy não faz esse tráfego passar pelo zurg. A consequência que vale saber: leituras que chegam por arquivos `.strm` não têm contabilização de banda, nem failover no meio do stream para outra conta, nem detecção de link quebrado, tudo o que uma leitura de mount tem. Por isso, uma biblioteca servida principalmente por `.strm` quase não sente efeito do `disable_stream_proxy`, em nenhum dos dois casos.

`serve_strm_files` e `disable_stream_proxy` são independentes, ao contrário do que versões antigas desta página diziam. Um `.strm` é servido como texto antes de qualquer decisão de streaming ser tomada, então os dois podem ser ativados juntos. Só que, com `serve_strm_files` ligado, toda reprodução chega ao endpoint `/strm/`, que é justamente a linha da tabela em que o `disable_stream_proxy` não muda nada.

### Filtragem e detecção de arquivos {#file-filtering--detection}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `addl_playable_extensions` | list | `[]` | Extensões de arquivo que o zurg deve tratar como mídia reproduzível, além dos formatos de vídeo/áudio já embutidos. Pontos, aspas e maiúsculas/minúsculas são normalizados pelo dashboard. Adicione extensões como `m3u` ou `cbz` se quiser que esses arquivos fiquem visíveis e selecionáveis. |
| `force_select_playable_files` | bool | `false` | Quando true, o zurg seleciona automaticamente todos os arquivos reproduzíveis de um torrent, mesmo que não tenham sido selecionados originalmente. Funciona tanto com as extensões de vídeo embutidas quanto com `addl_playable_extensions`. Útil quando o torrent tem arquivos de vídeo não selecionados que você quer acessar. |
| `delete_torrent_if_extensions_found` | list | `[]` | Se algum arquivo de um torrent tiver uma dessas extensões, o torrent inteiro é apagado do RD. Útil para remover automaticamente torrents que contêm conteúdo indesejado, como arquivos `.rar` (não os extraídos pelo RD) ou arquivos `.zipx`. |
| `stream_compressed_archives` | bool | `true` | Entrega um arquivo empacotado dentro de um arquivo compactado, decodificando-o conforme ele é lido. O decodificador mantém uma janela limitada na memória. Defina `false` para recusar arquivos compactados como as versões mais antigas faziam. |

Os formatos reproduzíveis embutidos são `.avi`, `.flv`, `.m2ts`, `.m4v`, `.mkv`, `.mov`, `.mp4`, `.mpg`, `.mpeg`, `.ts`, `.webm`, `.wmv`, `.mp3`, `.flac`, `.m4a` e `.m4b`.

```yaml
addl_playable_extensions:
  - m3u
  - cbz
force_select_playable_files: false
delete_torrent_if_extensions_found:
  - zipx
  - rar
```

### Metadados e nomenclatura {#metadata--naming}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `retain_folder_name_extension` | bool | `false` | **Obsoleta — será removida.** Quando true, o nome da pasta é o `Name` da conta exatamente como está, com extensão e tudo, em vez de `OriginalName` com a terminação `.mp4` e depois `.mkv` removida. Vale apenas quando `Name` contém `OriginalName` como substring; nos demais casos a remoção acontece de qualquer jeito. `retain_rd_torrent_name` é verificada primeiro e anula esta opção por completo. |
| `retain_rd_torrent_name` | bool | `false` | **Obsoleta — será removida.** Quando true, o nome da pasta é o `Name` da conta (o `filename` do Real-Debrid); quando false, é o `OriginalName` (`original_filename`), que é o nome que o próprio torrent declarou. Isso importa para um pacote com um único arquivo selecionado: o Real-Debrid reduz o `filename` ao nome base desse arquivo, mas o `original_filename` continua sendo o nome do pacote, então **`false` dá o nome do pacote e `true` dá o nome do arquivo individual**. |
| `ignore_renames` | bool | `false` | Quando true, o zurg ignora qualquer metadado de renomeação nos torrents e usa os nomes de arquivo originais. Ative isso se arquivos renomeados estiverem causando problemas na correspondência do seu servidor de mídia. Não está obsoleta. |

```yaml
retain_folder_name_extension: false   # deprecated
retain_rd_torrent_name: false         # deprecated
ignore_renames: false
```

As duas opções obsoletas indexam a biblioteca pelo `Name`, que a conta reescreve por baixo do zurg; os padrões indexam pelo nome que o torrent declarou, que a conta deixa como está. Definir qualquer uma das duas gera um aviso na inicialização, e em uma instância que atende Sonarr ou Radarr (um bloco `sabnzbd:` ou `qbittorrent:`) os padrões são os únicos valores corretos — uma chave de acesso que muda depois de uma importação faz você perder o lançamento. O comportamento não muda nesta versão: ninguém vê os nomes de pasta mudarem. `docs/naming.txt` é o conjunto completo de regras de nomenclatura.

### Gravações no mount {#mount-writes}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `dav_allow_rename` | bool | `true` | Quando false, um MOVE do WebDAV pelo mount é recusado com 403. Ativado por padrão: renomear um torrent ou um arquivo é para que serve o mount gravável, e isso não destrói nada. |

**Um DELETE do WebDAV pelo mount é sempre aceito — não existe chave para ele.** Ele remove um arquivo da biblioteca e, quando nada mais sobra, remove o release de todas as contas de debrid que o tinham. Saiba o que isso custa antes de apontar um gravador para o mount: o rclone descarrega um arquivo sobrescrito como um DELETE seguido de um PUT, então qualquer coisa que reescreva um arquivo no lugar (um gravador de `.nfo`, uma passagem de trickplay, um rename do \*arr, um `touch` perdido) apaga o conteúdo em vez de substituí-lo, e o mount usa as credenciais do próprio rclone, então a autenticação não consegue diferenciar as duas coisas. Só a recusa da parte PUT impede que essa sequência termine em silêncio. `mount_read_only: true` é o que impede um delete de chegar ao zurg.

Uma escrita recusada responde **403** e registra no log a chave de configuração que a permitiria, então um cliente cuja escrita parou de funcionar mostra o motivo em `logs/zurg.log`.

Uma consequência que vale conhecer: quando um programa escreve pelo mount FUSE, o cache VFS do rclone mantém a cópia modificada e tenta de novo o upload recusado com um backoff, e o mount mostra o arquivo modificado localmente até que essa entrada de cache seja descartada — o arquivo no servidor fica intacto o tempo todo. `mount_read_only: true` evita isso por completo, falhando a escrita no kernel antes que o rclone faça qualquer cache.

```yaml
dav_allow_rename: true
```

Veja também `mount_read_only`, que faz o kernel recusar a escrita antes que ela chegue ao zurg.

### Cache da listagem de diretórios {#directory-listing-cache}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `disable_listing_cache` | bool | `false` | Quando true, cada listagem de diretório é renderizada do zero a cada requisição. Deixe desligado: com ele ligado, um `PROPFIND Depth:1` de `__all__` renderiza a biblioteca inteira de novo toda vez que é pedido — medido em 59 ms para 6,120 releases, 121 ms para 2,636 releases Usenet, 148 ms para `__magic__/__all__` — e um scan do servidor de mídia pede a mesma listagem várias vezes. |

```yaml
disable_listing_cache: false
```

O cache guarda a última renderização de cada diretório de nível superior, uma para cada variante de montagem (`/dav`, `/infuse`, `/http`), e a devolve até a biblioteca mudar. O que conta como mudança não é um palpite: é exatamente o conjunto de eventos que já fazem o rclone esquecer a sua própria cópia em cache da mesma listagem — um release adicionado, removido, renomeado, movido de lugar, um arquivo que quebra ou se recupera — e o rclone mantém essas listagens por **doze horas**. Então uma listagem servida daqui nunca está mais desatualizada do que a que a montagem já está servindo, e há um limite fixo de 60 segundos por cima disso, por segurança extra.

`__magic__/__all__` — o espelho, e a única listagem do namespace que vale a pena cachear, já que a raiz acima dele tem o espelho e meia dúzia de linhas — também acompanha o layout armazenado, então uma importação do \*arr invalida só essa listagem e deixa intacta a renderização de todos os outros diretórios. `__downloads__` e requisições `Depth: 0` não são cacheadas de jeito nenhum.

As respostas trazem o cabeçalho `X-Zurg-Listing: hit` ou `miss`, então dá para medir numa instalação em uso:

```bash
curl -s -o /dev/null -D - -X PROPFIND -H 'Depth: 1' http://localhost:9999/dav/__all__/ | grep -i x-zurg-listing
```

### `__magic__`, um diretório que você pode organizar {#__magic__-a-directory-you-can-organise}

Todas as outras pastas são filtros salvos: um release está em `movies` porque corresponde ao filtro de filmes. Por isso não há lugar na biblioteca para *colocar* algo. `__magic__` é a exceção: `__magic__/__all__` é uma cópia exata de `__all__`, a raiz ao lado dele é sua, e qualquer coisa pode ser movida para fora do espelho para qualquer outro lugar do namespace. Um move reescreve uma linha em `data/magic.journal`, que é compactada em `data/magic.json`. Nenhum byte se move, nenhum torrent é renomeado, e as linhas usam como chave o hash de conteúdo do release. Assim, um reparo que reconstrói o release não perde onde você colocou as coisas. É isso que permite ao Radarr e ao Sonarr importar por renomeação em vez de por cópia.

A documentação completa, incluindo o que sobrevive a um reparo e o que cada recusa significa, está em [docs/magic.md](../guides/magic.md).

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `magic.enabled` | bool | `false` | Servir o `__magic__` de fato. Desligado por padrão: é uma árvore gravável, e um \*arr apontado para a raiz errada pode reorganizar uma biblioteca. Sem nada movido, o `__all__` dele é exatamente igual ao da biblioteca, e a raiz não tem mais nada. |
| `magic.allow_delete` | bool | `false` | Quando true, um DELETE de um **arquivo** dentro de `__magic__` também apaga o conteúdo, como um DELETE no próprio mount sempre faz. Desligado, a exclusão só oculta: a entrada sai de `__magic__` e continua em `__all__` e em todas as pastas de filtro. Uma pasta de release ou um diretório nunca apaga conteúdo, independentemente desta configuração. O Sonarr apaga a pasta do job após cada importação. Apagar um vídeo ou uma entrada dentro de um arquivo também apaga o release inteiro, assim que nada em `__magic__` usar nenhuma parte dele. |
| `magic.sidecar_max_mb` | int | `32` | O maior arquivo único que um cliente pode fazer `PUT` em `__magic__`. Acima disso, a escrita é recusada com **413**. |
| `magic.sidecar_budget_mb` | int | `2048` | O maior tamanho que a árvore inteira de sidecars pode atingir. Acima disso, uma escrita é recusada com **507 Insufficient Storage**, o que diz algo que o 413 não diz: apagar alguma coisa faz a mesma requisição dar certo. O total é medido percorrendo a árvore na inicialização, então um restart não devolve a cota a uma árvore que já está cheia. E a medição é refeita antes de qualquer recusa, porque a árvore é o mesmo diretório `data/local` em que o próprio mount do zurg escreve. Um arquivo removido ali por fora do zurg não pode continuar sendo contado. Zero ou valor negativo usa o padrão; não há como pedir sem limite. |

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

`dav_allow_rename` não se aplica aqui, nem o caminho de exclusão sem controle do mount. Esses dois cobrem as rotas que renomeiam e destroem o que a conta de debrid contém. Uma escrita em `__magic__` não alcança conta nenhuma. `mount_read_only: true` ainda sobrepõe tudo, no kernel.

Duas coisas que vale saber. As pastas de filtro não são alteradas, por design. Por isso, um release que você moveu dentro de `__magic__` continua em `recent` e `movies` com o nome original. Aponte um servidor de mídia para `__magic__` **ou** para os filtros, não para os dois. E qualquer coisa realmente nova escrita no mount (um `.nfo`, uma legenda, um pôster) vai para o `data/local` do próprio zurg e é mesclada na listagem. É por isso que os sidecars ao lado de um release simplesmente funcionam.

#### Arquivos auxiliares, e para que servem os dois limites {#sidecar-files-and-what-the-two-caps-are-for}

O volume montado embutido é uma union cujo primeiro upstream é `data/local`. Assim, quando um programa cria um arquivo novo no mount, o rclone grava ali e o zurg nunca é consultado. Nada limita essa árvore, a menos que [`union_writable: server`](#rclone-settings) inverta a ordem da union. Nesse caso, a criação chega ao zurg como um `PUT` e é recusada fora de `__magic__`, e dentro dele fica limitada pelos dois limites.

Com a ordem padrão, os dois limites são para o outro tipo de cliente: aquele que monta `/dav` diretamente, sem nenhuma union na frente. Esses clientes enviam o `PUT` ao zurg, e o zurg grava o corpo em `data/local/__magic__/<path>`, que é exatamente o diretório que a union serve. Assim, as duas visões mostram um só diretório, e não dois. Sem um limite, isso viraria um armazenamento geral de arquivos acessível por WebDAV, e é justamente isso que `sidecar_max_mb` e `sidecar_budget_mb` existem para impedir.

Disso decorrem duas regras, baseadas no que `__magic__` é. Ambas são recusas que um cliente pode ver:

- **O espelho é da biblioteca.** `__magic__/__all__` e as pastas de release diretamente dentro dele são calculadas, então um `MOVE`, `MKCOL` ou `DELETE` apontado para qualquer um deles retorna **403**. Uma linha ali seria um segundo endereço para um release que já tem um. Mais fundo fica a pasta própria de um release, onde uma escrita é tão comum quanto em qualquer outro lugar. É ali que um \*arr coloca o `.nfo` ao lado de um arquivo que importou.
- **Nada que a biblioteca responde pode ser sobrescrito.** Uma pasta de release, uma entrada dela e um caminho onde um move colocou algo são todos renderizados a partir da biblioteca. Portanto, um `PUT` ou um `MOVE` de um arquivo real sobre qualquer um deles retorna **403**. Isso inclui um nome dentro de uma pasta de release que o release não tem: a listagem da pasta pertence ao release, então um arquivo colocado entre as entradas dela não apareceria em lugar nenhum.
- **Um posicionamento nunca destrói um arquivo real.** Mover algo que a biblioteca guarda para um caminho ocupado por um sidecar é recusado, em vez de sobrescrever, mesmo com `Overwrite: T`. O mesmo vale para uma pasta de arquivos reais movida no sentido inverso: ela não pode ser renomeada para um caminho que a biblioteca responde, porque os arquivos dela ficariam em uma pasta que lista o release e mais nada.

Um `DELETE` de um sidecar realmente apaga o arquivo. É o único ponto dentro de `__magic__` em que um delete não é um tombstone. Um tombstone esconde uma entrada que a biblioteca ainda tem em outro lugar, mas os bytes de um sidecar vivem em `data/local` e em nenhum outro lugar.

#### A página `__magic__` {#the-__magic__-page}

A página do dashboard tem uma página própria para o namespace, em `/magic/`, linkada nos quick links do dashboard sempre que `__magic__` estiver configurado ou servido. É ali que a tabela fica visível, e é o único lugar onde dois dos seus estados podem ser acessados.

Ela mostra quantas linhas estão armazenadas (posicionamentos, tombstones e diretórios, contados separadamente), quanto o journal e o snapshot ocupam no disco, quanto do `sidecar_budget_mb` a árvore de sidecars está usando, e o tamanho de todo o `data/local`. Esse último número é o que você deve observar: um cliente que copia em vez de mover coloca os bytes ali, então um `data/local` crescendo para gigabytes significa que algo está importando do jeito errado. As linhas são agrupadas por release. Uma tabela muito grande é truncada na página, e a página informa quantas linhas foram cortadas. Os contadores acima dela sempre se referem à tabela inteira.

A lista de linhas armazenadas mostra as primeiras mil linhas, e um \*arr deixa um tombstone a cada importação, então em uma biblioteca organizada a maioria das linhas fica depois desse ponto. Uma caixa de busca nas páginas de linhas armazenadas e órfãs encontra um release pelo nome, por um caminho no mount ou pelo hash, e lista todas as linhas armazenadas sobre ele com seus botões. `data/magic.json` não é um jeito de contornar isso: o zurg o grava a partir da memória quando para, então uma linha apagada à mão enquanto o zurg está rodando volta.

Três botões, e todos passam pela mesma operação: uma linha deixar de existir.

- **Reset** em um posicionamento, e o arquivo ou pasta volta para onde a biblioteca o colocaria.
- **Unhide** em um tombstone, e a entrada volta a aparecer em `__magic__`. Nada foi destruído para escondê-la. Um release em `__all__` que nunca aparece em `__magic__/__all__`, mesmo depois de apagá-lo e adicioná-lo de novo, tem um tombstone de release: as linhas são indexadas pelo hash dele, que uma nova adição não muda. Busque por ele e faça unhide nessa linha.
- **Delete** em uma linha **órfã**, ou seja, uma cujo release, ou cujo arquivo dentro dele, a biblioteca não tem mais. Uma linha dessas não resolve para nada, então não pode ser listada, movida nem apagada pelo mount. Ela é mantida em vez de descartada, porque um repair que restaura o release também restaura o lugar onde você a colocou. Até esta página não havia como limpar uma dessas linhas; **Clear all dangling rows** varre todas de uma vez.

Os sidecars também aparecem na lista, e os que **nada mais justifica** ficam separados do resto e são contados. Eles são o equivalente de uma linha órfã para sidecars: um `.nfo` ou um pôster gravado ao lado de um release que já saiu da biblioteca, ou dentro de uma pasta cujo posicionamento foi esquecido. Eles continuam sendo servidos, porque um arquivo real é a última coisa que um caminho de `__magic__` resolve, e nada acima deles reivindica mais o nome. Então a única coisa que se foi é o motivo pelo qual foram colocados ali. O zurg nunca remove um desses sozinho: um arquivo deixado ao lado de um release apagado continua sendo seu, e um repair que traz o release de volta volta a contabilizar a pasta. Um diretório que você criou para sidecars manualmente, pelo mount e não pelo zurg, aparece do mesmo jeito aqui, porque isso também não deixa linha.

Apagar um sidecar pela página remove o arquivo de verdade, do mesmo jeito que um `DELETE` pelo mount. Todos os botões alteram o que o mount tem em cache para os caminhos envolvidos, porque o mount guarda a listagem de um diretório por doze horas com o polling desligado.

Se o endpoint do SABnzbd estiver ligado, a página também lista os jobs que ele recebeu: o id pelo qual o cliente conhece cada um, sua categoria, se o release já chegou à biblioteca e a pasta de onde importar quando chegar. Sonarr e Radarr removem os próprios jobs. Um job Failed ou Stuck que nenhum deles jamais vai remover pode ser limpo pela página. Isso acontece quando o zurg não é mais o download client deles. Veja [sabnzbd.md](../guides/sonarr-radarr.md).

Os blocos `magic:` e `sabnzbd:` podem ser editados por completo na [página de configuração](#sabnzbd-the-download-client-sonarr-and-radarr-see), e ambos mostram **Restart Required**, que significa exatamente isso: as rotas que servem `__magic__` e o endpoint do SABnzbd são registradas uma única vez, na inicialização, a partir desses valores. Ligar qualquer um dos dois grava a mudança no `config.yml` e não altera nada da execução que já respondeu. A página de `__magic__` também avisa isso, em vez de mostrar um namespace vazio.

### `sabnzbd`, o cliente de download que o Sonarr e o Radarr enxergam {#sabnzbd-the-download-client-sonarr-and-radarr-see}

zurg consegue responder ao Sonarr e ao Radarr como se fosse um SABnzbd. Eles entregam um NZB para ele, ele grava o arquivo em `nzbs/` para o backend de Usenet e, quando o release está na biblioteca, o job aparece como **Completed** com uma pasta de job em `__magic__/__all__` para importar. Nada é baixado para importar: o \*arr renomeia o arquivo dentro do mount, o que é uma linha na tabela `__magic__`.

Precisa das duas partes para ser útil: um provider `nzb` ou `torbox_nzb` para pegar o NZB, e `magic.enabled` para ter de onde importar. Ele fica desligado até você pedir. A configuração completa, incluindo o que colocar no \*arr, está em [docs/sabnzbd.md](../guides/sonarr-radarr.md).

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-----------|
| `sabnzbd.enabled` | bool | `false` | Registra o endpoint em `/api` e `/sabnzbd/api`. Enquanto estiver desligado, nenhuma dessas rotas existe. |
| `sabnzbd.api_key` | string | gerada | O único controle de acesso ao endpoint. Sonarr e Radarr não enviam basic auth, então essas rotas ficam fora dele e a chave é o que faz esse papel. Se deixar vazio com o bloco habilitado, o zurg gera uma, guarda em `data/sabnzbd-apikey` para sobreviver a um restart e registra no log uma única vez na inicialização. |
| `sabnzbd.categories` | list | `[tv, movies]` | As categorias informadas aos clientes. Todas apontam para o mesmo diretório, então isso existe só para evitar que um cliente reclame de uma categoria que não encontra. Adicione o que você configurou no \*arr. `*` também é sempre informada. |
| `sabnzbd.history_limit` | int | `60` | Quantas entradas do histórico o Sonarr e o Radarr leem. O zurg mantém jobs finalizados além desse limite na fila até liberar uma vaga, o que acontece quando o cliente remove um deles ou quando um job fica dez minutos sem ser removido enquanto outros esperam. Ajuste para bater com o `DownloadClientHistoryLimit` do cliente, se você tiver aumentado esse valor. `0` mantém o padrão deles, que é 60. |
| `sabnzbd.complete_dir` | string | `<mount_path>/__magic__/__all__` | O diretório de concluídos informado aos clientes. Precisa ser o caminho que **o \*arr** enxerga, que não é o do próprio zurg quando o \*arr roda em um container que monta a biblioteca em outro lugar. Também precisa estar no mesmo volume das root folders, senão toda importação vira uma cópia. Veja [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). |

```yaml
sabnzbd:
  enabled: true
  api_key: ""
  categories: [tv, movies]
  complete_dir: ""
```

A API key é toda a autenticação, então trate o endpoint como trata o resto da porta do zurg: numa rede confiável, ou atrás de algo que faça isso por ele. Basic auth não pode ser usado para ele. Os clientes nunca o enviam, e um 401 aparece para o usuário como "unable to connect" e não como falha de autenticação.

### `qbittorrent`, o cliente de download de torrents que o Sonarr e o Radarr enxergam {#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see}

zurg pode responder ao Sonarr e ao Radarr como se fosse um qBittorrent. Eles entregam um magnet ou um `.torrent`, e o zurg adiciona o info hash a uma conta debrid. Quando o release está na biblioteca, o torrent aparece como **finished**, com uma pasta em `__magic__/__all__` de onde importar. Nada é baixado para importar. O \*arr renomeia o arquivo dentro do mount, e isso vira uma linha na tabela `__magic__`.

Duas partes tornam isso útil. Uma conta que pode adicionar torrents lê o magnet, e `magic.enabled` dá ao \*arr um lugar de onde importar. Ela fica desligada até que você a ative. A configuração completa, incluindo o que colocar no \*arr, está em [docs/qbittorrent.md](../guides/sonarr-radarr-torrents.md).

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `qbittorrent.enabled` | bool | `false` | Registra o endpoint em `/api/v2` e `/qbittorrent/api/v2`. Enquanto estiver desligado, nenhuma das duas rotas existe. |
| `qbittorrent.api_key` | string | gerada | A única barreira do endpoint. Os clientes a enviam como bearer token quando o campo **API Key** deles está preenchido, e a aceitam como senha no `auth/login` quando não está. Se estiver vazia com o bloco habilitado, o zurg gera uma, guarda em `data/qbittorrent-apikey` para sobreviver a um reinício e a registra no log uma única vez, na inicialização. |
| `qbittorrent.categories` | list | `[tv-sonarr, radarr]` | As categorias informadas aos clientes, as duas que os \*arrs já trazem por padrão. Todas apontam para o mesmo diretório, então esta opção existe apenas para evitar que um cliente avise sobre uma categoria que não consegue encontrar. |
| `qbittorrent.save_path` | string | `<mount_path>/__magic__/__all__` | O save path informado aos clientes e o diretório pai de todas as pastas de onde eles importam. Precisa ser o caminho que **o \*arr** enxerga, que não é o do zurg quando o \*arr roda em um container que monta a biblioteca em outro lugar. Precisa estar no mesmo volume que as root folders, senão toda importação vira uma cópia; veja [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). Defina `sabnzbd.complete_dir` com o mesmo valor se você rodar os dois endpoints. |
| `qbittorrent.download_timeout_mins` | int | `15` | Por quanto tempo uma captura pode ficar sem movimento, sem mudança de etapa e sem aumento de progresso, antes de a conta ser descartada e a próxima que aceitar torrents ser tentada. `0` significa somente em cache: a captura só é aceita em uma conta que já tenha o conteúdo, e é recusada logo na adição caso contrário. Essa é a única recusa na qual o Sonarr e o Radarr agem. Um número negativo nunca desiste. Veja [Timeouts e modo somente em cache](../guides/sonarr-radarr-torrents.md#timeouts-and-cached-only-mode). |

```yaml
qbittorrent:
  enabled: true
  api_key: ""
  categories: [tv-sonarr, radarr]
  save_path: ""
  download_timeout_mins: 15
```

Quinze minutos é um valor medido, não escolhido. A AllDebrid coloca um job saudável na própria fila, com todos os contadores em zero, antes de transferir qualquer byte. Em duas execuções de duas, o job ficou parado por 580 e 622 segundos. As capturas estão em [docs/torrent-lifecycle.md](../internals/torrent-lifecycle.md).

Qual conta recebe uma captura é decidido por [`add_torrents`](#accounts) e pela ordem da lista `providers:`. Uma captura que expirou, ou que uma conta desistiu, é apagada dessa conta antes que a próxima seja tentada. Só uma instância que o próprio zurg adicionou para aquela captura e que nunca terminou pode ser candidata. Nada mais que este endpoint responde apaga algo de uma conta debrid.

A API key é toda a autenticação. Trate o endpoint como trata o restante da porta do zurg. Coloque-o em uma rede confiável ou atrás de algo que seja confiável. Basic auth não pode ser usado nele. Os clientes nunca enviam essa autenticação e leem um 401 como uma falha definitiva de autenticação, então nunca tentam de novo.

### O addon `stremio` {#the-stremio-addon}

zurg pode ser um addon do Stremio que pesquisa nos seus próprios indexadores Newznab e reproduz pelo backend Usenet. Ele precisa de uma conta NZB, `nzb` ou [`torbox_nzb`](../providers/torbox-nzb.md), e de pelo menos um indexador. Com `torbox_nzb`, uma release que a TorBox já tem começa dentro do tempo de espera do addon, desde que não haja nenhum outro post NZB esperando. Uma release não cacheada precisa terminar de baixar na TorBox primeiro, e isso demora mais do que o player espera. Ele fica desligado até você ativar. A configuração e o que acontece em cada reprodução estão em [stremio.md](../guides/stremio.md).

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `stremio.enabled` | bool | `false` | Registra as rotas do addon em `/stremio/`. Enquanto estiver desligado, elas respondem 404. |
| `stremio.token` | string | gerado | O segmento do caminho que protege todas as rotas do addon. É ele que faz toda a autorização. Se ficar vazio, o zurg gera um e guarda em `data/stremio-token`. |
| `stremio.indexers` | list | `[]` | Endpoints Newznab onde buscar. Cada um recebe `name`, `url`, `api_key` e um `api_path` opcional. |
| `stremio.max_results` | int | `10` | Quantas releases cada resolução mantém depois do ranking. O limite vale por resolução. Cada faixa mantém uma variedade, da maior release até a menor. `0` usa o padrão. |
| `stremio.search_limit` | int | `100` | Quantas releases cada indexador devolve por busca. Todos os outros limites escolhem entre o que foi pedido aqui, então este é o teto da resposta inteira. `0` usa o padrão. |
| `stremio.max_size_gb` | int | `0` | Descarta releases maiores que este valor antes do ranking, para players que não aguentam um remux. `0`, o padrão, não descarta nenhuma. Releases sem tamanho informado são mantidas. |
| `stremio.cache_hours` | int | `24` | Por quanto tempo uma resposta completa, com cinco ou mais resultados, fica guardada em `data/stremio-cache` antes de perguntar de novo aos indexadores. Respostas mais curtas ficam guardadas por menos tempo. Uma resposta vazia nunca é guardada. `0` usa o padrão. |

### Análise de mídia {#media-analysis}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `auto_analyze_new_torrents` | bool | `false` | Quando true, o zurg roda o ffprobe automaticamente em cada torrent recém-adicionado para extrair os metadados da mídia (resolução, codecs, duração, faixas de áudio e legendas). Esses metadados alimentam os filtros de diretório baseados em tags, como `zurg_4k`, `zurg_aud_eng` e as faixas de duração. Desative se você não usa filtros baseados em tags ou se quiser reduzir o uso de CPU em novas adições. |
| `ffprobe_binary` | string | `"ffprobe"` | Caminho para o executável do ffprobe. Só é necessário se o ffprobe não estiver no PATH do seu sistema. Usado para a análise de mídia. |

```yaml
auto_analyze_new_torrents: true
ffprobe_binary: "ffprobe"
```

## 4. Saúde e reparos (automação) {#4-health--repairs-automation}

A seção "set it and forget it" (configure e esqueça). Controla como o zurg mantém sua biblioteca saudável, detectando e consertando torrents quebrados automaticamente.

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `enable_repair` | bool | `true` | Ativa o reparo automático de torrents. Se não estiver definido, fica ativado. Quando um torrent fica indisponível (por exemplo, foi removido do cache do RD), o zurg tenta encontrar e adicionar um substituto. No AllDebrid, ele também reinicia um magnet que falhou por um motivo que uma segunda tentativa pode resolver, como falta de peers ou erro de tracker, em vez de deixá-lo com falha. **Importante:** só uma instância do zurg deve ter o reparo ativado, para evitar conflitos. Com esta opção e `delete_error_torrents` desativadas, o zurg deixa os torrents com falha exatamente como estão na conta e apenas registra no log. |
| `repair_every_mins` | int | `60` | Com que frequência (em minutos) o zurg procura torrents quebrados que precisam de reparo. Valores menores pegam os problemas mais rápido, mas aumentam o uso da API. |
| `repair_timeout_mins` | int | `30` | Tempo máximo (em minutos) para esperar uma operação de reparo terminar. Se um reparo demorar mais que isso, o torrent é marcado como quebrado e ignorado até o próximo ciclo de reparo. |
| `stalled_download_mins` | int | `10` | Mínimo de minutos antes de um download em andamento ser considerado travado. O limite real é `max(GB_downloaded, stalled_download_mins)`, então downloads grandes ganham mais tempo automaticamente. Aumente isso para torrents lentos ou com poucos seeds (por exemplo, trackers públicos) que precisam de mais tempo para terminar. |
| `restrict_repair_to_cached` | bool | `false` | Quando true, o zurg só usa torrents que já estão em cache no Real-Debrid para os reparos. Isso significa reparos mais rápidos (sem esperar downloads), mas pode falhar se não houver alternativa em cache. Quando false, o zurg pode adicionar torrents sem cache, que precisam de tempo para baixar. |
| `only_full_torrent_repair` | bool | `false` | Quando true, o reparo reinsere o torrent inteiro com a seleção de arquivos original ou desiste. Se esse primeiro passo falhar, o torrent é marcado como quebrado na hora, pulando as estratégias de arquivo compactado e de arquivo individual que viriam depois. |
| `check_for_changes_every_secs` | int | `15` | Com que frequência (em segundos) o zurg consulta o Real-Debrid para detectar mudanças na biblioteca (novos torrents, torrents removidos, mudanças de status). Valores menores significam atualizações mais rápidas no seu media server, mas mais chamadas à API. |
| `library_resync_every_mins` | int | `10` | Com que frequência a verificação de mudanças é reconstruída a partir de uma listagem completa, em vez de uma sondagem leve. É uma rede de segurança que pega divergências que a sondagem pode deixar passar. Não é a frequência com que o zurg consulta. O Real-Debrid segue um caminho próprio e ignora esta opção. |
| `library_detail` | string | `resident` | `resident` mantém os detalhes dos arquivos na memória. `lazy` libera os detalhes ociosos. `auto` libera os detalhes ociosos apenas sob pressão de memória prolongada. Todos os provedores compartilham esta política da instância inteira. Precisa reiniciar. Veja [Detalhes da biblioteca](#library-detail). |
| `library_detail_idle_secs` | int | `300` | Tempo mínimo sem leitura de detalhes antes que `lazy` ou `auto` possam liberar uma tabela. A varredura roda a cada 30 segundos. Ignorado por `resident`; valores zero ou inválidos usam 300. Precisa reiniciar. |
| `downloads_every_mins` | int | `720` | Com que frequência (em minutos) o zurg busca de novo seus downloads do RD (links desrestritos, links do file locker) e os monta. São downloads que não são torrents, vindos do RD. |
| `delete_error_torrents` | bool | `false` | Quando true, apaga automaticamente do RD os torrents que estão em estado de erro (por exemplo, torrents mortos que não podem ser baixados). Mantém sua biblioteca do RD limpa, mas significa que o torrent é removido permanentemente. No AllDebrid, um magnet com falha que uma segunda tentativa pode resolver é reiniciado em vez de apagado, mesmo com o reparo desativado, e só é apagado se o reinício não ajudar. |
| `on_library_update` | string | `""` | Um comando de shell executado sempre que o zurg detecta mudanças na biblioteca. Cada caminho de diretório alterado é passado como argumento. Costuma ser usado para disparar varreduras de biblioteca no Plex/Jellyfin em pastas específicas, para atualizações mais rápidas. |

```yaml
enable_repair: true
repair_every_mins: 60
repair_timeout_mins: 30
stalled_download_mins: 10
restrict_repair_to_cached: false
only_full_torrent_repair: false
check_for_changes_every_secs: 15
library_detail: resident
library_detail_idle_secs: 300
downloads_every_mins: 720
delete_error_torrents: false
on_library_update: |
  for arg in "$@"
  do
      echo "detected update on: $arg"
  done
```

### Reparando entre contas {#repairing-across-accounts}

Toda outra estratégia de reparo adiciona o release de novo à conta de onde ele veio, que é o formato certo enquanto essa conta ainda consegue entregar o conteúdo. Para um caso, ele é o formato errado.

Os serviços mantêm caches independentes. Um release que o Real-Debrid purgou, ou que ele recusa só pelo nome do arquivo, pode estar em cache no AllDebrid agora mesmo, com o mesmo info hash. O release não tem nada de errado. Quem está errada é a conta.

Então, quando um release foi dado como perdido por todas as contas que o têm, o zurg o oferece às contas configuradas que não o têm, na ordem em que aparecem no seu bloco `providers`. A primeira que já o tiver em cache fica com ele, o zurg lista essa conta, e o release ganha uma segunda cópia do jeito que qualquer release com várias contas ganha: com os próprios file ids, os próprios links e failover de leitura entre as duas. O veredito da entrada se limpa sozinho assim que existir uma cópia que pode ser reparada.

Não existe configuração para isso. Adicionar uma segunda conta já é a decisão, e o zurg já a lista, serve conteúdo dela e faz failover de leitura para ela. Pedir a ela um release que a primeira conta não consegue produzir é o mesmo arranjo. Isso segue `enable_repair`, como qualquer outro reparo.

O botão de reparo de um release também faz isso, e na ordem certa: ele primeiro tenta de novo na conta que tem o release, exatamente como sempre fez, e só oferece o release para as outras se essa tentativa falhar. É o único caminho que funciona com a varredura de reparo totalmente desligada.

O que impede que isso vire um loop de adições é o formato da oferta, não um interruptor:

- **Uma conta só recebe conteúdo que ela já tem.** A oferta é uma adição que é retirada e apagada de novo, a menos que a conta a complete em quinze segundos. Uma conta que teria que buscar o release no swarm é deixada exatamente como estava, sem gastar nenhuma cota de transferência. Isso é um reparo, nunca um novo download. `restrict_repair_to_cached` não controla isso e nunca é lido aqui: essa chave diz respeito a uma conta reparar a própria cópia, e este caminho só aceita cache, qualquer que seja o valor dela.
- **Só um release que nada consegue servir.** Um release que funciona nunca é copiado para outro lugar, e nem um que o reparo ainda não desistiu.
- **Uma conta que diz não é perguntada cada vez menos.** A espera depois de uma negativa começa em um dia e dobra a cada nova negativa, até cerca de quinze dias. Um release que só está fora de cache nesta semana é encontrado de novo em poucos dias; um que sumiu de vez vira uma pergunta a cada quinze dias. Sem esse decaimento, o modo sempre ligado significaria uma adição diária para cada release morto em cada conta, para sempre.
- **No máximo dez releases por varredura**, então a primeira varredura depois de adicionar uma segunda conta trabalha numa fila acumulada ao longo de horas, não em uma rajada só.

Uma conta que já tem uma cópia do release nunca recebe uma segunda instância dele, por pior que esteja a cópia que ela tem: as estratégias de reparo cuidam dessa conta, e no Real-Debrid uma adição duplicada nunca baixa nada. Releases cuja chave não é um info hash de bittorrent, que é como o backend Usenet identifica os seus, nunca são oferecidos a ninguém.

Este é o único lugar em que o zurg adiciona conteúdo a uma conta cujo conteúdo expira sem que ninguém peça. O reparo não readiciona um release a uma conta dessas por timer, porque buscar de novo um conteúdo que o serviço removeu de propósito é o padrão que esses serviços chamam de abuso. Uma oferta em cache não é isso: nada é buscado, nenhuma cota é gasta, e o conteúdo reivindicado já está no cache do serviço porque outra pessoa o colocou lá.

### Detalhe da biblioteca {#library-detail}

**`library_detail: resident` continua sendo o padrão.** Escolha um modo e o tempo de inatividade
na página de configuração do dashboard ou no `config.yml`. As duas configurações passam a valer depois de reiniciar o zurg; salvá-las não troca parcialmente uma biblioteca em execução. A política se aplica a todos os provedores da instância.

| Modo | Comportamento | Compromisso |
|---|---|---|
| `resident` | Mantém na memória os detalhes de arquivo de todos os releases. | Acesso previsível, sem recarregar detalhes; maior uso de memória. |
| `lazy` | Libera os detalhes depois de `library_detail_idle_secs` sem uso. | Reduz o uso de memória em repouso, mesmo quando há bastante RAM; acessar detalhes "frios" custa um recarregamento. |
| `auto` | Mantém os detalhes enquanto há memória disponível e libera as tabelas mais antigas e ociosas quando a pressão é constante. | Reage às condições de execução; adiciona monitoramento de pressão e uma latência de recarregamento menos previsível. |

Nomes, tamanhos, renomeações e visibilidade continuam disponíveis para as listagens em todos os modos. Abrir ou reparar um arquivo reconstrói os detalhes liberados sob demanda. O `auto` não recarrega a biblioteca de forma antecipada quando a pressão termina: os detalhes voltam conforme são usados e permanecem residentes até que a pressão e a janela de inatividade permitam liberá-los de novo.

#### Detecção automática de pressão {#automatic-pressure-detection}

O `auto` faz uma amostragem a cada 30 segundos. Duas leituras com pelo menos 30 segundos de diferença, iguais ou acima de **90%** de um orçamento medido, iniciam a remoção, em lotes de no máximo **128 tabelas ociosas** por varredura. A remoção continua até o uso chegar a **80%** ou menos e, depois, pausa por pelo menos um minuto antes de considerar um novo episódio. Picos rápidos não iniciam a remoção. A janela de ociosidade configurada sempre vale.

A leitura mais restritiva disponível é que define a decisão:

- **Memória do host:** total menos memória disponível, incluindo a estimativa do sistema operacional para caches recuperáveis. Um cache de sistema de arquivos cheio, por si só, não é falta de RAM.
- **Contêineres Linux e limites de serviço:** cgroup v2 `memory.max` e `memory.high`, ou v1 `memory.limit_in_bytes`, somando o uso de cada ancestral visível. Cache de arquivos frio é descontado. Os limites do contêiner são relidos em tempo de execução; namespaces de cgroup privados podem esconder limites acima da raiz visível.
- **Um orçamento de runtime explícito:** um `memory_limit_mb` positivo, em MiB, é comparado com a memória gerenciada pelo Go. `GOMEMLIMIT`, quando definido, tem prioridade; `GOMEMLIMIT=off` desativa este sinal específico. A pressão do host e do contêiner continua valendo. O teto automático do Go derivado dos caches de Usenet é ignorado, porque ele sobe junto com o heap ativo e não mede a RAM disponível.

Não é preciso nenhum orçamento adicional para ativar o `auto`:

```yaml
library_detail: auto
library_detail_idle_secs: 300
# Optional explicit Go runtime budget, also used by the collector:
# memory_limit_mb: 1024
```

Sem uma medição utilizável, a remoção automática fica pausada. Isso é uma otimização de memória gradual, **não um limite rígido de memória**: arquivos ativos, alterações não salvas, snapshots de recuperação e outros caches podem dominar a memória, e picos repentinos de alocação podem ser mais rápidos que a varredura. O `memory_limit_mb` continua sendo um limite suave para o coletor; definir um valor abaixo dos dados ativos pode causar coleta de lixo excessiva.

#### Integridade dos dados e custo {#data-integrity-and-cost}

A remoção mantém um **snapshot de recuperação compactado** além do dump existente em `data/*.zurgtorrent`. Ao recarregar do disco, os dados precisam bater com esse snapshot. Se o dump estiver ausente, danificado ou substituído, o zurg restaura o snapshot e mantém o release residente, depois tenta salvar de novo os dados recuperados. `auto` também tenta de novo as tabelas sujas ociosas quando a pressão acaba, com uma passagem de salvamento separada e limitada. Gravações em arquivos e mudanças de estado restauram a posse imediatamente, inclusive gravações feitas por meio de um ponteiro mantido por um stream durante a remoção. Salvamentos que falham deixam as mudanças residentes e sujas. Gravações sobrepostas não são confirmadas por um salvamento mais antigo. Um salvamento bem-sucedido ainda é necessário para que as mudanças sobrevivam à saída do processo.

Medido em um Apple Silicon Mac com Go 1.26.4, usando 500 releases por formato nos caminhos de conversão e persistência, incluindo o snapshot de recuperação:

| Formato | Bytes resident/entrada | Bytes lazy/entrada | Redução | Reconstrução média |
|---|---:|---:|---:|---:|
| Filme no Real-Debrid, 3 arquivos | 3,662 | 2,845 | 22% | 88 µs |
| Pacote de temporada no Real-Debrid, 24 arquivos | 15,670 | 7,366 | 53% | 371 µs |
| TorBox, 2 arquivos | 3,019 | 2,680 | 11% | 56 µs |
| AllDebrid, 1 arquivo | 2,580 | 2,516 | 2% | 55 µs |
| Conjunto RAR, 7 volumes | 5,343 | 3,303 | 38% | 109 µs |

Estes são valores de heap retido por release, não o RSS do processo inteiro. As reconstruções leem arquivos locais gravados recentemente. Armazenamento frio ou remoto pode demorar mais. Escolha `lazy` para uma recuperação ociosa consistente, ou `auto` para recuperar memória só sob pressão. Mantenha `resident` quando o acesso previsível importar mais que a RAM. Releases pequenos economizam pouco, e o snapshot de recuperação gasta memória de propósito para proteger os dados. Essas medições descrevem entradas removidas tanto em `lazy` quanto em `auto`. O modo automático pode manter mais entradas em um dado momento.

## 5. Rede e Conectividade (Técnico) {#5-network--connectivity-technical}

Configurações de infraestrutura que controlam como o zurg faz o bind, autentica e se conecta à rede.

### Vinculação do Servidor {#server-binding}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-----------|
| `host` | string | `"[::]"` | A interface de rede à qual vincular. `[::]` escuta em todas as interfaces (IPv4 e IPv6). Use `0.0.0.0` para só IPv4, ou um IP específico para restringir o acesso a uma única interface. |
| `port` | string | `"9999"` | A porta em que o zurg escuta. A variável de ambiente `PORT`, quando definida, substitui esse valor, o que é útil em implantações em contêineres. |

```yaml
host: "[::]"
port: 9999
```

### Conexões quentes {#warm-connections}

Abrir uma conexão com um serviço debrid é caro, e usar uma que já está aberta é quase de graça. Medido a partir de um host real em 2026-08-29, uma conexão nova com um host de download do Real-Debrid custa um ida e volta TCP e depois 68–85 ms de handshake TLS, tudo antes de um único byte do arquivo ser pedido. O transporte HTTP do zurg não abre nada até que uma leitura precise, e descarta uma conexão sem uso depois de 90 segundos. Em qualquer biblioteca que não seja movimentada, a leitura que vem depois de um período parado paga essa conta no caminho do próprio espectador.

Um piso aquecido tira isso desse caminho: cada conta mantém um número definido de conexões já abertas e com handshake feito antes da demanda, então o transporte tem uma pronta quando a leitura chega.

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `warm_connections` | int | *(não definido)* | O piso para toda conta que não define o seu próprio. Não definido deixa cada backend com o padrão dele: 1 por host para uma conta debrid, 2 por conta para uma conta de notícias. `-1` desativa o aquecimento em todos os lugares. O `warm_connections` próprio de uma conta sempre prevalece, inclusive sobre um `-1` global. |

```yaml
warm_connections: 2        # every account keeps 2, unless it says otherwise

providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    warm_connections: 4    # this one keeps 4 to each host it uses
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    warm_connections: -1   # and this one keeps none
```

**Quanto isso ajuda depende do host, e, para os serviços debrid, é menos do que parece.** Uma conexão que não enviou nada é a primeira que esses serviços derrubam, e fazem isso rápido. Cronometrado a partir de um host real em 2026-08-29, mantendo uma conexão silenciosa aberta e esperando ser encerrada:

| Host | Conexão silenciosa | Depois de atender uma requisição |
|---|---|---|
| um host de download do Real-Debrid | fechada após 30s | fechada imediatamente |
| `api.alldebrid.com` | fechada após 15s | ainda aberta com 4 min |
| `api.torbox.app` | fechada após 15s | ainda aberta com 4 min |
| `api.real-debrid.com` | fechada após 4s | fechada após 5s |

Então um piso só vale a pena para um host de download, e pouco mais que isso. A API do Real-Debrid não pode ser aquecida de jeito nenhum: nenhum piso vence um encerramento de quatro segundos sem gerar tráfego artificial para manter a conexão viva, o que o zurg não faz. Em vez de presumir, **o piso mede**. Ele fecha as próprias conexões aos 15 segundos e verifica se cada uma ainda estava viva quando isso aconteceu. Um host que continue fechando-as antes que uma leitura possa usá-las é descartado, e suas leituras voltam a abrir conexão como sempre faziam. Nada precisa ser configurado para isso, e um piso sem uso em uma biblioteca parada não é confundido com esse caso.

Mais duas coisas que vale saber antes de aumentar:

- **O piso de uma conta debrid é por host, e o de uma conta de notícias é por conta.** Uma conta debrid é acessada por muitos hosts, um hostname de API e um host de entrega por link. Quais deles serão usados não dá para saber até que um link seja gerado, então os hosts mantidos aquecidos são os que a conta de fato vinha usando. No máximo 16 ficam aquecidos ao mesmo tempo, e um que fique sem uso por 10 minutos é descartado. Uma conta de notícias usa um único host, nomeado na configuração, e mantém a sessão pelo tempo que o plano permitir. Por isso o piso dela é o que compensa de forma confiável. Veja [Usenet](../guides/usenet.md).
- **Conexões aquecidas são conexões reais e contam no limite por host que o provedor controla:** 32 no Real-Debrid e no AllDebrid, 20 no TorBox. Por isso o piso debrid é limitado a 4. Um piso desse tamanho deixa o limite praticamente intacto, enquanto um grande gastaria essa cota com sockets que não carregam nada.

O piso fica desativado quando `proxy` está definido, já que um proxy HTTP ou SOCKS faz o zurg discar para o proxy em vez do host, e não há nada do outro lado que valha a pena manter aberto.

### Autenticação e Proxy {#authentication--proxy}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `username` | string | `""` | Nome de usuário para autenticação básica HTTP. Quando definido junto com `password`, todas as requisições ao zurg (painel, WebDAV, API) exigem autenticação. Deixe vazio para desativar a autenticação. |
| `password` | string | `""` | Senha para autenticação básica HTTP. Precisa ser definida junto com `username`. |
| `proxy` | string | `""` | Faz todo o tráfego de rede de saída do zurg passar por um proxy. Suporta os protocolos `http://`, `https://` e `socks5://`. Útil se o seu provedor de internet bloqueia ou limita o tráfego do Real-Debrid. Exemplo: `socks5://user:pass@host:port`. A variável de ambiente `PROXY` é usada quando essa chave está vazia. |

```yaml
username: ""
password: ""
proxy: "http://[username:password@]host:port"
```

### Configurações do Rclone {#rclone-settings}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `rclone_enabled` | bool | `false` | Quando true, o zurg gerencia uma montagem do rclone automaticamente. Assim você não precisa rodar o rclone separadamente: o zurg inicia, monitora e reinicia o processo do rclone quando preciso. A montagem usa `mount_path` como ponto de montagem. |
| `rclone_binary` | string | `"rclone"` | Caminho para o executável do rclone. Só é necessário se o rclone não estiver no PATH do sistema. |
| `rclone_extra_args` | list | `[]` | Flags extras de linha de comando passadas ao comando de montagem do rclone. Use para sobrescrever os padrões de VFS otimizados pelo benchmark do zurg (veja a tabela abaixo). Cada item é uma única string de flag. As configurações de RC e as flags de backend `--union-*`/`--webdav-*` são recusadas: o zurg monta essas coisas sozinho, e uma flag teria prioridade sobre o que ele constrói (`union_writable` deixaria de descrever a montagem). |
| `mount_read_only` | bool | `false` | Quando true, a montagem é iniciada com `--read-only` do rclone, então o kernel recusa uma escrita antes de ela chegar ao zurg. Nada mais bloqueia um DELETE na montagem, então esta é a única forma de recusar um. Isso não cobre clientes que falam diretamente com o endpoint WebDAV, mas também impede que uma escrita acidental caia no upstream local da união da montagem. Para sobrescrever por flag, use `rclone_extra_args: ["--read-only=false"]`. |
| `rclone_cache_reclaim` | bool | `true` | Se o zurg apaga as árvores de cache do VFS deixadas por uma configuração anterior da montagem. O rclone nomeia o cache a partir do remote, e esse nome é um hash dos upstreams da união, que carregam o caminho absoluto de `data/local`. Assim, mover o diretório do zurg ou trocar `union_writable` renomeia o cache e deixa a árvore antiga num lugar que nenhum limite conta e nenhum limpador visita. Ao iniciar a montagem, o zurg pergunta ao rclone em execução qual árvore está ativa e remove as outras, registrando no log o que liberou. Ele não faz nada a menos que a árvore ativa esteja onde o rclone diz que está, e pula a varredura por completo quando `rclone_extra_args` define `--cache-dir`. Defina como `false` para manter todas as árvores abandonadas. Veja [Disco usado pela montagem](#disk-the-mount-uses). |
| `union_writable` | string | `"local"` | De qual lado da união da montagem embutida um arquivo criado é gravado. `local`, o padrão, grava direto no upstream local (`data/local`) sem que o zurg veja. `server` coloca o upstream WebDAV primeiro, então a criação chega ao zurg: ela é recusada fora de `__magic__` e gravada como sidecar com limite de tamanho dentro dela. Uma escrita recusada nunca chega ao disco. O cache VFS do rclone aceita e tenta o upload de novo com backoff, então ela fica limitada pelo teto do cache e visível em `logs/rclone.log`, onde a ordem local colocaria bytes sem limite em `data/local`. Uma ressalva medida com `server`: renomear um arquivo sidecar pela montagem pode retornar erro (o arquivo aparece nos dois upstreams, e o rclone aplica a movimentação em cada um). Movimentações de release dentro de `__magic__`, que é o caminho de importação do \*arr, não são afetadas. Trocar para `server` muda apenas onde as *novas* criações vão, e nada mais: o que a ordem local já gravou em `data/local` permanece até você apagar. A linha que o zurg registra na inicialização indica o modo ativo (`new files go to zurg over WebDAV (union_writable: server)`), então é isso que você deve checar, não a presença do caminho `data/local`, que faz parte da união em qualquer ordem. |

```yaml
rclone_enabled: false
rclone_binary: "rclone"
rclone_extra_args: []
mount_read_only: false
rclone_cache_reclaim: true
union_writable: "local"
```

#### Padrões Otimizados por Benchmark {#benchmark-optimized-defaults}

zurg usa configurações de VFS do rclone testadas em benchmark e otimizadas para desempenho de streaming:

| Configuração | Padrão | Motivo |
|---------|---------|-----|
| `--buffer-size` | 256M | Buffer grande para streaming suave |
| `--vfs-read-chunk-size` | 32M | Quanto tempo uma leitura nova leva para ganhar velocidade. O primeiro chunk é buscado nesse tamanho e depois dobra, então com 4M uma leitura a partir de um offset frio passava a maior parte do tempo abaixo da taxa de linha. É um tamanho de requisição, não uma transferência forçada: o rclone continua parando de puxar dados quando o leitor para. |
| `--vfs-read-chunk-size-limit` | 512M | Onde a duplicação acima para. O chunking já vem ligado por padrão, então isso é um teto que a rampa alcança, e não algo que uma substituição liga. |
| `--vfs-read-ahead` | 128M | Equilíbrio entre eficiência de buffer e de banda |
| `--max-read-ahead` | 1M | Um buffer pequeno do kernel FUSE reduz leituras pequenas. Não é passado no Windows. |
| `--vfs-read-wait` | 5ms | Crítico: valores maiores causam lentidão severa |
| `--vfs-cache-mode` | full | Cache completo para o melhor desempenho. Nem sempre é a troca certa para um player lendo o mount por um compartilhamento. Veja [Quando o cache custa mais do que ajuda](#when-the-cache-costs-more-than-it-buys). |
| `--vfs-cache-max-size` | 256G | Limite rígido para o cache VFS em disco. Não é uma chave de configuração: substitua com `rclone_extra_args`. |
| `--vfs-cache-min-free-space` | 10G | Para de fazer cache antes que o disco do cache encha |
| `--vfs-cache-max-age` | 72h | Por quanto tempo um arquivo em cache que ninguém tocou é mantido. "Sem uso" é a palavra que importa, e um servidor de mídia raramente deixa algo sem uso. Veja [Disco que o mount usa](#disk-the-mount-uses). |
| `--vfs-cache-poll-interval` | 1m | Atualizações de cache responsivas |
| `--vfs-fast-fingerprint` | on | Identifica arquivos sem fazer hash deles |
| `--dir-cache-time` | 12h | Listagens ficam válidas por horas; o zurg esquece as entradas afetadas pela API RC quando a biblioteca muda, então as varreduras do servidor de mídia continuam rápidas |
| `--attr-timeout` | 60s | Arquivos da biblioteca são imutáveis, e mudanças de estado esquecem as entradas afetadas explicitamente. Limitado para que um tamanho desatualizado não sobreviva a uma varredura. |
| `--poll-interval` | 0 | Monitorar mudanças é trabalho do zurg, não do rclone |
| `--timeout` | 5m | Timeout de IO ocioso |
| `--no-modtime` / `--no-checksum` | on | Nenhum dos dois faz sentido para uma biblioteca debrid, e pedi-los custa requisições |
| `--async-read` | padrão do rclone (on), não passado | O zurg não coloca essa flag na linha de comando, e o rclone a define como true por padrão. Então o mount lê de forma assíncrona, e todos os números desta página foram medidos assim. Um campo de ajuste já disse que desligava isso, mas tudo o que ele fazia era acrescentar a flag sem valor, que define o padrão que já existia. Para desligar de verdade: `rclone_extra_args: ["--async-read=false"]`. |
| `--low-level-retries` | 3 | O downloader do VFS do rclone já reinicia uma leitura com falha dez vezes por open, e cada reinício é repetido pelo pacer do backend essa quantidade de vezes. Com o padrão de 10 do rclone, isso dá 100 requisições para um único open de um arquivo que o zurg responde com 503 de propósito. |
| `--retries` | 1 | Orçamento do comando inteiro. Para um mount que nunca encerra, só multiplica uma falha na inicialização. |
| `--vfs-handle-caching` | 0, on no rclone 1.74+ | O rclone 1.74 passou a manter os downloaders de um arquivo vivos por cinco segundos depois do último close. Assim, tocar em um arquivo custa cinco segundos do que o link consegue transportar, e não do que foi lido: medido contra um servidor de 50 MB/s, uma leitura de 1 MiB puxou 245-250 MiB em vez de 3-6 MiB, e uma varredura de vinte arquivos foi de 80 MiB para 4.2 GiB. O período de carência existe para `serve nfs`, que o zurg nunca executa. Versões mais antigas do rclone não têm essa flag e se recusam a iniciar com uma flag desconhecida, então o zurg pergunta a versão do binário primeiro e não passa nada abaixo da 1.74. |
| `--log-level` | NOTICE | Verbosidade do próprio rclone, sempre passada |
| `--cache-dir` | `data/rclone-cache` | Resolvido em relação ao diretório de trabalho |
| `--log-file` | `logs/rclone.log` | Resolvido em relação ao diretório de trabalho |

`--vfs-cache-max-size`, `--vfs-cache-min-free-space`, `--low-level-retries`, `--retries`, `--vfs-handle-caching`, `--log-level`, `--cache-dir` e `--log-file` são constantes em `internal/rclone/manager.go`. Todas as outras linhas vêm de `tuneVFSOptions` em `internal/rclone/tuning.go`, incluindo `--vfs-cache-max-age` e `--vfs-cache-poll-interval`, apesar dos nomes.

### Disco que o mount usa {#disk-the-mount-uses}

`--vfs-cache-mode full` significa que um arquivo lido pelo mount é baixado **por completo** para `data/rclone-cache` e fica lá depois que a reprodução termina. Não é um buffer temporário de reprodução que se esvazia quando o vídeo para. Se você não fizer nada, o cache cresce até `--vfs-cache-max-size`, que vem por padrão com **256G**, e fica nesse tamanho.

Dois limites deveriam controlar isso, mas na prática só um funciona:

- `--vfs-cache-max-size` (256G) é o limite de verdade. Defina no máximo metade do espaço livre do disco onde `data/` está.
- `--vfs-cache-max-age` (72h) remove um arquivo que ninguém tocou há três dias. O rclone mede isso pelo registro próprio dele em `data/rclone-cache/vfsMeta/`, não pelo atime do sistema de arquivos, e **qualquer coisa que leia a biblioteca atualiza esse registro**. Um servidor Plex com tarefas agendadas ativadas lê todos os arquivos em cache durante a janela de manutenção noturna. Por isso, em 2026-09-09, uma instância com 362 arquivos no cache tinha ATime daquela mesma manhã em todos eles. Nada tinha sido removido por idade em meses, e nunca seria. Não conte com a remoção por idade; planeje em cima do limite de tamanho.

Diminua o limite com `rclone_extra_args`:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

`--vfs-cache-min-free-space` (10G por padrão) para de criar cache quando o disco chega perto de cheio nesse ponto. Mantenha esse valor bem acima de zero em um disco compartilhado com outras coisas.

Para liberar o cache manualmente, pare o zurg primeiro e depois esvazie as duas árvores:

```bash
rm -rf data/rclone-cache/vfs/* data/rclone-cache/vfsMeta/*
```

Meça com `du -sh data/rclone-cache`. Entradas parcialmente baixadas são arquivos esparsos, então um tamanho que conta bytes aparentes mostra bem mais do que o disco realmente ocupa.

#### Quando o cache custa mais do que entrega {#when-the-cache-costs-more-than-it-buys}

`full` é o padrão certo para um servidor de mídia no mesmo host: ele lê um arquivo uma vez, e tudo depois disso é local. Não é automaticamente o certo para um player de hardware que lê o mount por um compartilhamento de arquivos.

Com `full`, uma leitura precisa ser gravada no disco antes de chegar ao leitor, e o que é baixado é o arquivo inteiro, e não só a parte que está sendo assistida. Coloque um compartilhamento na frente disso e um único disco fica atendendo o player enquanto o rclone ainda está gravando nele. Um player Zidoo lendo um compartilhamento do Windows travava a cada título até o cache ser desligado, e depois tocava sem problemas (relatado em 2026-08-30). O mecanismo acima é a explicação mais plausível para esse relato, e não algo medido aqui, então trate-o como a primeira coisa a tentar quando um cliente de leitura direta travar em um mount que um servidor de mídia no mesmo host reproduz sem problemas:

```yaml
rclone_extra_args:
  - "--vfs-cache-mode"
  - "off"
```

O que isso abre mão é real. Sem uma cópia local, um seek lê de novo do provedor, uma segunda reprodução baixa o arquivo de novo, e nada sobrevive a um reinício. Também muda o que o mount aceita como escrita, então deixe o padrão de lado em um host onde um \*arr importa pelo mount — veja [qbittorrent.md](../guides/sonarr-radarr-torrents.md).

#### Caches deixados para trás por uma mudança {#caches-stranded-by-a-move}

rclone dá ao cache o nome do remote que ele armazena, e esse nome carrega um hash da configuração do remote. O remote do zurg é um union cujos upstreams incluem o caminho absoluto de `data/local`, então o nome muda sempre que a configuração muda:

| Upstreams do union | Árvore de cache |
|---|---|
| `/home/you/zurg/data/local :webdav:` | `vfs/zurg{QaSkn}` |
| `:webdav: /home/you/zurg/data/local` (`union_writable: server`) | `vfs/zurg{HdSp7}` |
| `/other/root/data/local :webdav:` (zurg movido) | `vfs/zurg{Psid2}` |

O rclone só contabiliza a árvore que está usando. Uma árvore com um nome antigo não conta para limite nenhum, não é visitada por limpeza nenhuma e não é apagada por ninguém. Assim, mover o diretório do zurg, ou um HD externo que volta com outro ponto de montagem, deixa um cache inteiro para trás. Algumas mudanças desse tipo é o que faz uma instalação com limite de 256G acabar ocupando vários terabytes.

O zurg recupera essas árvores no início da montagem: ele pergunta ao rclone em execução qual árvore está ativa, apaga as outras e registra no log quanto espaço liberou. Ele só faz isso se a árvore ativa estiver no disco onde o rclone diz que está, e pula a limpeza por completo quando `rclone_extra_args` define `--cache-dir`, já que um diretório escolhido por você pode ser compartilhado com outro zurg. Defina `rclone_cache_reclaim: false` para desligar a função e manter todas as árvores órfãs.

Mais quatro flags são adicionadas conforme a plataforma, todas no Linux: `--allow-other` e `--allow-non-empty` sempre, e `--uid` e `--gid` só quando os ids do usuário que está executando podem ser lidos. `--max-read-ahead` é passado em todas as plataformas, exceto no Windows, e `--read-only` sempre que [`mount_read_only`](#rclone-settings) estiver definido.

Os valores de buffer e de espera de leitura foram definidos por benchmark em uma conexão de 600 Mbps, chegando a ~533 Mbps de throughput com cache frio e ~235ms de TTFB. O tamanho do chunk de leitura foi medido de novo depois, em um host de ~70 MB/s: em pares intercalados, a mediana do throughput foi de 49.1 -> 56.5 MB/s na Real-Debrid ao mudar de 4M para 32M, e o efeito foi o mesmo na TorBox.

**Substitua os padrões** usando `rclone_extra_args`:
```yaml
rclone_extra_args:
  - "--buffer-size=128M"        # Use less memory
  - "--vfs-read-chunk-size=2M"  # Smaller chunks
```

Flags de RC (`--rc`, `--rc-addr` e qualquer outra que comece com `rc-`) são rejeitadas: o zurg executa o controle remoto do rclone por conta própria para invalidar o cache do VFS quando a biblioteca muda.

(Uma tradução anterior foi rejeitada: os trechos de código não batiam. Mantenha a estrutura exatamente como está.)

### User Agent e Rede {#user-agent--network}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-----------|
| `user_agent` | string | UA do Chrome | User-Agent HTTP compartilhado para provedores, indexadores, ffprobe e integrações de saída. Deixar em branco restaura o padrão genérico de navegador; valores personalizados informados são enviados exatamente como digitados. Exige reinício. Veja [identidade das requisições de saída](outbound-identity.md). |
| `omit_user_agent` | boolean | `false` | Suprime o User-Agent HTTP (o ffprobe usa um valor vazio), sobrepondo `user_agent`. As requisições ao GitHub ainda enviam um, porque o GitHub recusa requisições sem ele. Exige reinício. |
| `outbound_client_name` | string | `"Media Client"` | Nome do produto/cliente para integrações com servidores de mídia, onde suportado. Deixar em branco restaura o padrão. Exige reinício. |
| `outbound_client_id` | string | `"media-client"` | Identificador do cliente Plex, incluindo o login para integrações com servidores de mídia, onde suportado. Deixar em branco restaura o padrão. Exige reinício. |
| `outbound_client_version` | string | `"1.0"` | Versão do cliente para integrações com servidores de mídia, onde suportado. Deixar em branco restaura o padrão. Exige reinício. |
| `outbound_device_name` | string | `"Media Client"` | Nome do dispositivo para integrações com servidores de mídia, onde suportado. Deixar em branco restaura o padrão. Exige reinício. |
| `outbound_device_id` | string | `"media-client"` | Identificador do dispositivo Jellyfin/Emby para integrações com servidores de mídia, onde suportado. Deixar em branco restaura o padrão. Exige reinício. |
| `outbound_platform` | string | `"Desktop"` | Plataforma Plex para integrações com servidores de mídia, onde suportado. Deixar em branco restaura o padrão. Exige reinício. |
| `force_ipv6` | bool | `false` | Força todos os testes de rede do zurg e a seleção de hosts a usarem IPv6. Ative isso se a sua rede tiver melhor conectividade IPv6 com os servidores da RD (por exemplo, alguns provedores limitam IPv4, mas não IPv6). |
| `unrestrict_ip` | string | `""` | O endereço IP a ser enviado para a RD ao desbloquear links de download. Útil em configurações com várias redes, quando você quer que os downloads sejam gerados para um IP específico (por exemplo, o IP de saída de uma VPN) em vez do IP onde o zurg está rodando. |
| `dns_servers` | list | `[]` (DNS do sistema) | Servidores DNS personalizados para resolver os nomes de host da RD. Útil se o DNS do seu sistema estiver lento, instável ou bloqueado pelo seu provedor. Deixe vazio para usar o resolvedor do sistema. Deve incluir a porta (por exemplo, `1.1.1.1:53`). |
| `network_test_every_mins` | int | `1440` | Com que frequência (em minutos) o zurg roda de novo o teste de latência de rede para encontrar os servidores de download da RD mais rápidos. Não pode ser desativado — valores `<= 0` são tratados como `1440`. Os resultados são salvos em cache em `data/network_test_results.json` e `data/network_test_timestamp`; ao reiniciar, se o cache ainda estiver recente o bastante, o teste de rede é pulado. |

```yaml
user_agent: "Mozilla/5.0 ..."
force_ipv6: false
unrestrict_ip: ""
network_test_every_mins: 1440
dns_servers:
  - "1.1.1.1:53"   # Cloudflare
  - "8.8.8.8:53"   # Google
```

### Compartilhamento público de NZB {#public-nzb-sharing}

Um compartilhamento NZB é uma URL que o destinatário busca, então só ajuda se ele conseguir alcançar este host, o que um zurg atrás de NAT de casa não pode garantir. Essas duas chaves roteiam essa URL por um serviço do [zrok](https://zrok.io): o zurg se conecta ao serviço de saída e serve o compartilhamento por essa conexão, então **nenhuma porta local é aberta** e nada novo responde neste host. O que o túnel carrega são apenas as duas rotas de compartilhamento protegidas por token, nunca o painel nem a biblioteca.

Com as duas vazias e nenhum ambiente habilitado em `data/zrok`, o compartilhamento fica na rede em que este host já está, sem conectar a lugar nenhum. Esse é o padrão. Atenção à segunda parte: depois que um ambiente *foi* habilitado, um `zrok_account_token` vazio não significa mais somente local, porque a habilitação é o que liga o compartilhamento, e ela fica salva. Para desligar o compartilhamento público de novo, remova `data/zrok`.

Criar, servir e revogar compartilhamentos funciona igual nos dois casos. O token do compartilhamento no caminho é a autorização tanto na URL local quanto na pública.

A URL pública sobrevive a um reinício: o compartilhamento do lado do serviço é localizado e reconectado, não criado de novo. O que ela não sobrevive é uma nova habilitação. Um novo ambiente recebe um novo compartilhamento, e as URLs entregues sob o antigo deixam de resolver. Isso acontece quando você remove `data/zrok`, e também se a identidade salva ali sumir ou ficar ilegível, já que habilitar de novo é o único jeito de voltar.

Remover `data/zrok` na mão também deixa esse ambiente, e o compartilhamento dentro dele, registrados na conta zrok. A identidade que poderia liberá-los é justamente o que você apagou, então limpe pelo console do zrok se a bagunça incomodar. Também não é um jeito de desligar o compartilhamento na hora: um zurg em execução mantém a conexão que já está servindo, então a URL antiga continua funcionando até o processo reiniciar. O zurg libera sozinho um ambiente sempre que substitui um. Ele se recusa a substituir um que não conseguiu liberar por falta de conexão com o serviço, ou um cujos arquivos encontra no disco mas não consegue ler, já que habilitar por cima abandonaria um ambiente ativo a cada reinício.

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `zrok_account_token` | string | `""` | O token de habilitação do zrok que liga o compartilhamento público. Grátis em [myzrok.io](https://myzrok.io) para o serviço hospedado; do seu próprio controlador, se você hospeda o seu. É necessário só na **primeira habilitação**: ao habilitar, ele é resgatado uma vez e salvo, junto com a identidade do ambiente, em `data/zrok`. Todas as chamadas seguintes se autenticam com essa cópia salva, então a chave pode sair do `config.yml` depois e o compartilhamento público ainda sobe no próximo reinício. Atenção ao que isso significa para o segredo: tirar a chave do config não tira o token do host. Há dois motivos para deixá-la lá mesmo assim. Uma habilitação que *falhou* (token recusado, serviço inalcançável) não está concluída, e a nova tentativa precisa da chave. E qualquer *nova* habilitação também precisa dela, então uma instância que teve a chave removida e depois perdeu a identidade em `data/zrok` não consegue se recuperar sozinha. Um token rotacionado é lido daqui e aplicado ao ambiente salvo, com identidade e URL pública intactas. |
| `zrok_api_endpoint` | string | `""` | O serviço zrok com o qual falar, para implantações self-hosted. Vazio mantém o padrão do SDK, `https://api-v2.zrok.io` (o serviço hospedado). Lido **somente no momento da habilitação**. Quando `data/zrok` já tem um ambiente habilitado, o endpoint salvo ali prevalece, então apontar um zurg já habilitado para outro serviço significa apagar `data/zrok` e habilitar de novo. A identidade pertence ao serviço que a emitiu, então essa é a forma honesta de fazer mesmo. Ele não substitui o `zrok_account_token`: a primeira habilitação ainda precisa de um token do serviço que este campo indica. A variável de ambiente `ZROK2_API_ENDPOINT` do próprio SDK tem prioridade sobre esta chave nesse mesmo momento. |

A acessibilidade se divide em duas partes em um serviço self-hosted, e só uma delas é sua: **este zurg** alcança a API do controlador (um endereço da tailnet basta para isso), enquanto **seus destinatários** alcançam o frontend do serviço. Um serviço acessível só na sua tailnet, portanto, entrega URLs de compartilhamento que só a sua tailnet consegue abrir.

Há mais duas coisas que um serviço self-hosted precisa alinhar. A URL de compartilhamento é a que o serviço anuncia para o seu frontend, e um host puro, sem esquema, é assumido como `https`. Então um frontend que serve HTTP simples precisa de TLS na frente, ou de uma URL anunciada que traga seu próprio esquema e porta. E o compartilhamento é criado no namespace que o SDK do zrok resolve, que é `public` a não ser que a variável `ZROK2_DEFAULT_NAMESPACE` do próprio SDK diga outra coisa. O zurg não fixa nenhum dos dois, então um serviço cujo namespace tenha outro nome precisa informar isso por essa variável.

```yaml
zrok_account_token: ""   # the enable token, needed for the first enable only
zrok_api_endpoint: ""    # self-hosted only; empty = the hosted service
```

## 6. Desempenho e Ajuste (Avançado) {#6-performance--tuning-advanced}

Estas configurações raramente precisam ser alteradas, a não ser para depurar ou otimizar para as condições específicas da sua rede.

### Caches de leitura persistentes {#persistent-read-caches}

Dois caches de bytes sobrevivem a um reinício. Ambos são compartilhados por toda a instância e cada um tem seu próprio limite de disco em MiB. Uma mudança só passa a valer depois de um reinício.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `nzb_article_disk_cache_mb` | int | `512` | Artigos Usenet decodificados guardados em `data/bytecache/articles/`. Um artigo lido uma vez é servido do disco na próxima vez. `0` desativa. |
| `archive_decoded_disk_cache_mb` | int | `512` | Blocos de arquivo descompactados guardados em `data/bytecache/decoded/`. Um seek para trás ou um reinício não decodifica o entry desde o início de novo. O mesmo limite é usado de novo para `data/bytecache/decoded-tails/`, que guarda os últimos 8 MiB de um entry compactado assim que alguém pediu por ele. `0` desativa os dois. |

Os registros mais antigos e não usados saem primeiro quando um limite enche. [persistent-caches.md](../internals/persistent-caches.md) cobre todos os caches que sobrevivem a um reinício.

### Seleção de CDN e Host {#cdn--host-selection}

> **Relacionado:** O teste de latência de rede, que define os hosts mais rápidos, roda periodicamente com base em [`network_test_every_mins`](#user-agent--network) (padrão: a cada 1440 minutos / 24 horas).

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `rd_cdn_host_preference` | string | `"auto"` | Define quais servidores de download do RD o zurg prefere. `auto` usa o que o RD oferecer. `force_cloudflare` troca o host pelo gêmeo `.cloud`, que chega à mesma máquina pela Cloudflare. Isso é útil quando os IPs diretos estão bloqueados. `force_numbered` usa os hosts numerados do RD diretamente. `force_location_<location>` (por exemplo, `force_location_syd` ou `force_location_fra`) direciona o tráfego para os servidores de um país específico. |
| `cdn_host_preference` | string | — | Alias legado de `rd_cdn_host_preference`, mantido por compatibilidade e apenas para o Real-Debrid. Se as duas opções estiverem definidas, vale a explícita. |
| `tb_cdn_host_preference` | string | `"auto"` | Região do CDN do TorBox. `auto` deixa a escolha com o próprio TorBox. `force_location_<region>` serve os downloads a partir dessa região. Só dá para forçar regiões que atualmente anunciam um nó de entrega, e a lista suspensa do painel mostra exatamente essas. Não há fallback para a chave legada, porque os valores dela são códigos de localização do Real-Debrid e não significam nada aqui. |
| `number_of_hosts` | int | `0` (todos) | Limita o zurg aos N hosts de download mais rápidos. Depois de testar a velocidade dos hosts disponíveis, o zurg usa apenas os N primeiros. Defina `0` para usar todos os hosts disponíveis. Um valor como `3` reduz a distribuição de conexões, mas garante que você sempre use os servidores mais rápidos. |

```yaml
rd_cdn_host_preference: "auto"
tb_cdn_host_preference: "auto"
number_of_hosts: 3
```

> **`force_cloudflare` e `force_location_*` são mutuamente exclusivos.** O RD publica um gêmeo `.cloud` apenas para os hosts numerados. Medido em 2026-08-09: todos os 25 subdomínios numerados têm um, e nenhum dos 22 subdomínios específicos de país tem. Assim, uma conta com o Cloudflare ativado nas configurações da conta no RD sempre recebe um host numerado, e nenhuma preferência de localização pode ser respeitada nela. O zurg detecta isso pelo link que desbloqueia na inicialização, pula a verificação de geolocalização que não pode dar certo e registra o motivo no log se mesmo assim houver uma localização configurada.

> **Observação sobre a verificação de `force_location_*`:** Ao usar uma preferência de geolocalização como `force_location_nyk`, o endpoint de API `/rest/1.0/downloads` do RD normaliza as URLs de download para servidores numerados (por exemplo, `128-4.download.real-debrid.com`), mesmo que a resposta do unrestrict tenha retornado um servidor de geolocalização (por exemplo, `nyk7-4.download.real-debrid.com`). O próprio código de download incorpora o servidor numerado (por exemplo, o código `...4128` corresponde ao servidor `128-4`). Para confirmar que o roteamento por geolocalização está funcionando, verifique os logs do zurg ou a resposta bruta do unrestrict. **Não** confie na API de downloads do RD.

### Limites de Taxa {#rate-limits}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `api_rate_limit_per_minute` | int | `250` | Número máximo de chamadas à API do RD por minuto para operações gerais (tudo exceto a listagem de torrents). O RD aplica os próprios limites; isso evita que o zurg bata neles e seja bloqueado temporariamente. Aumente só se você tiver certeza de que seu plano do RD permite. |
| `torrents_rate_limit_per_minute` | int | `75` | Número máximo de chamadas à API do RD por minuto especificamente para o endpoint `/torrents`, usado para buscar sua lista de torrents. Ele é separado porque a listagem de torrents é a chamada à API mais frequente e tem dinâmica de limite própria. |
| `fetch_torrents_page_size` | int | `5000` | Quantos torrents buscar por página ao sincronizar sua biblioteca do RD. Valores maiores significam menos chamadas à API, mas respostas maiores. Se você tiver uma biblioteca muito grande (10.000+ torrents), um valor maior reduz o tempo de sincronização. |

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

### Verificação de Links {#link-verification}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `use_range_verification` | bool | `false` | Controla como o zurg verifica se os links de download ainda são válidos. Quando false, o zurg usa uma requisição `HEAD` (leve, sem transferência de dados). Quando true, usa um header `Range` (`GET bytes=0-0`), que baixa apenas 1 byte. Ative isso se sua rede ou os servidores da RD não responderem corretamente a requisições HEAD, causando falsas falhas de link. |

```yaml
use_range_verification: false
```

### Timeouts e Retentativas {#timeouts--retries}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-----------|
| `api_timeout_secs` | int | `60` | Máximo de segundos para esperar qualquer resposta de uma chamada à API do RD. Aumente se sua conexão for lenta e as chamadas à API estiverem dando timeout. |
| `download_timeout_secs` | int | `15` | Máximo de segundos para esperar ao testar links de download (usado durante os testes de velocidade dos hosts e na verificação de links). Não é o timeout para os downloads de arquivos em si. |
| `retries_until_failed` | int | `2` | Quantas vezes tentar de novo uma chamada à API que falhou antes de desistir e marcá-la como falha. Valores mais altos dão mais resistência a quedas passageiras do RD, mas deixam a detecção de falhas mais lenta. |
| `retry_503_errors` | bool | `false` | Quando true, tenta de novo as requisições que recebem uma resposta 503 (Service Unavailable) do RD. O RD retorna 503 durante manutenção ou sobrecarga. Ative isso se você tiver muitos erros 503 que se resolvem sozinhos rapidamente. |

```yaml
api_timeout_secs: 60
download_timeout_secs: 15
retries_until_failed: 2
retry_503_errors: false
```

### Downloads e Depuração {#downloads--debugging}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `get_downloads_limit` | int | `-1` | Número máximo de entradas de download do RD (não-torrent) a buscar. `-1` significa sem limite (busca todas), `0` pula a busca de downloads por completo, e um número positivo limita. Útil se você usa o recurso de desbloqueio de link direto do RD e quer que esses arquivos apareçam no zurg. Se deixar a chave de fora, vale `-1`; um `0` explícito é respeitado como "sem cache" e gera um aviso na inicialização, porque geralmente é uma config escrita antes de `0` mudar de significado. |
| `load_dumped_torrents` | bool | `false` | Quando true, carrega os dados de torrent da pasta `dump/` na inicialização. É um mecanismo de recuperação: se o zurg já tiver salvo o estado dos torrents (por exemplo, durante uma queda), ativar isso restaura esse estado sem buscar tudo de novo no RD. |
| `log_requests` | bool | `false` | Quando true, registra estatísticas detalhadas de cada pedido de download (caminho do arquivo, tempo de resposta, bytes enviados). Útil para depurar problemas de streaming ou entender padrões de acesso. Gera bastante log, então desative em produção. |
| `log_level` | string | `DEBUG` | Quanto detalhe registrar no log: `DEBUG`, `INFO`, `WARN`, `ERROR` ou `FATAL`. Mudar pelo dashboard tem efeito imediato, sem reiniciar, e muda o nível de todos os componentes de uma vez. Isso sobrescreve a variável de ambiente `LOG_LEVEL`, então o controle do dashboard continua funcionando mesmo em um container que já tenha uma definida; deixe a chave de fora para devolver a escolha para `LOG_LEVEL`. Um valor que não nomeia nenhum nível é ignorado com um aviso na inicialização, em vez de causar erro fatal. |
| `traffic_alert_gb` | int | `0` | Avisa quando uma conta de debrid passa de mais que esta quantidade de GiB pelo zurg em um dia (o dia reinicia às 00:05 CET, junto com a cota do Real-Debrid). O aviso indica os arquivos que mais consumiram nesta hora e quem os leu, assim uma varredura da biblioteca ou um cliente baixando arquivos inteiros aparece enquanto está acontecendo. O zurg também registra um resumo dos maiores arquivos da hora no início de cada hora, e uma linha para qualquer leitura única de 1 GiB ou mais, com o alerta configurado ou não. `0` desativa o alerta. |
| `traffic_alert_webhook` | string | — | Um webhook do Discord para onde o alerta de tráfego também é enviado. Mantenha em sigilo: qualquer pessoa com a URL pode postar nesse canal. |

```yaml
get_downloads_limit: -1
load_dumped_torrents: false
log_requests: false
log_level: DEBUG
traffic_alert_gb: 500
```

## 7. Diretórios e Filtros {#7-directories--filters}

Defina diretórios virtuais que organizam seus torrents com base em regras de filtro flexíveis. Cada diretório aparece como uma pasta no seu mount e mostra apenas os torrents que correspondem aos seus filtros.

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true

  # ... (see config.example.yml for full examples)
```

### Opções de diretório {#directory-options}

| Opção | Tipo | Padrão | Descrição |
|--------|------|---------|-------------|
| `group` | string | o próprio nome do diretório | Diretórios no mesmo grupo disputam cada torrent: ele vai para o primeiro cujos filtros baterem, e nenhum outro do grupo o recebe. Diretórios em grupos diferentes ficam cada um com sua própria cópia. |
| `group_order` | int | `0` (tratado como `1`) | Prioridade dentro do grupo: quanto menor, primeiro. Empates são decididos pelo nome do diretório. |
| `filters` | list | `[]` | As regras que decidem o que pertence aqui. Um torrent bate com o diretório se **qualquer** item da lista bater. Uma lista vazia ou ausente bate com todos os torrents. |
| `only_show_the_biggest_file` | bool | `false` | Mostra só o maior arquivo de cada torrent, escondendo amostras, extras e arquivos complementares. |
| `only_show_files_with_size_lte` | int | `0` (desligado) | Esconde arquivos maiores que essa quantidade de bytes. |
| `only_show_files_with_size_gte` | int | `0` (desligado) | Esconde arquivos menores que essa quantidade de bytes. |
| `rex_shows` | string | `""` (nenhum) | Com `rex_url`: o título de uma biblioteca de TV no rex que mostra os episódios deste diretório. |
| `rex_movies` | string | `""` (nenhum) | Com `rex_url`: o título de uma biblioteca de Filmes no rex que mostra os filmes deste diretório, e qualquer arquivo que o rex não consiga identificar como episódio. |
| `rex_music` | string | `""` (nenhum) | Com `rex_url`: o título de uma biblioteca de música no rex que mostra os arquivos de áudio deste diretório (`.flac`, `.mp3`, `.m4a`, `.m4b`), incluindo audiolivros. Sem ela, nenhum arquivo de áudio vai para o rex. |
| `rex_photos` | string | `""` (nenhum) | Com `rex_url`: o título de uma biblioteca de Fotos no rex que mostra os quadrinhos deste diretório (`.cbz`, `.cbr`), cada um como um álbum de suas páginas, que o Plex Web percorre e reproduz como slideshow. O Plex para Android não mostra biblioteca de fotos. Os quadrinhos continuam sendo arquivos no mount. |

Um arquivo forçado explicitamente a aparecer no zurg ignora as três opções de visibilidade.

### Condições de filtro {#filter-conditions}

| Condição | Tipo | Descrição |
|-----------|------|-------------|
| `id` | string | O ID do torrent. Decisivo: nenhum outro item da mesma entrada é considerado. |
| `regex` | string | O nome do torrent casa com o padrão. |
| `not_regex` | string | O nome do torrent não casa com o padrão. |
| `contains` | string | O nome do torrent contém o texto (sem diferenciar maiúsculas). |
| `contains_strict` | string | O nome do torrent contém o texto (diferencia maiúsculas). |
| `not_contains` | string | O nome do torrent não contém o texto (sem diferenciar maiúsculas). |
| `not_contains_strict` | string | O nome do torrent não contém o texto (diferencia maiúsculas). |
| `size_gte` | int | O tamanho total do torrent é de pelo menos esta quantidade de bytes. |
| `size_lte` | int | O tamanho total do torrent é de no máximo esta quantidade de bytes. |
| `any_file_inside_regex` | string | Algum arquivo dentro do torrent casa com o padrão. |
| `any_file_inside_not_regex` | string | Algum arquivo dentro do torrent não casa com o padrão. |
| `any_file_inside_contains` | string | Algum arquivo contém o texto (sem diferenciar maiúsculas). |
| `any_file_inside_contains_strict` | string | Algum arquivo contém o texto (diferencia maiúsculas). |
| `any_file_inside_not_contains` | string | Algum arquivo não contém o texto (sem diferenciar maiúsculas). |
| `any_file_inside_not_contains_strict` | string | Algum arquivo não contém o texto (diferencia maiúsculas). |
| `any_file_inside_size_gte` | int | Algum arquivo tem pelo menos esta quantidade de bytes. |
| `any_file_inside_size_lte` | int | Algum arquivo tem no máximo esta quantidade de bytes. |
| `added_within_hours` | int | O torrent foi adicionado dentro destas horas. |
| `added_within_days` | int | O torrent foi adicionado dentro destes dias. |
| `added_after` | string | O torrent foi adicionado em ou depois desta data. Formato `YYYY-MM-DD` ou `YYYY-MM-DD HH:MM`. |
| `added_before` | string | O torrent foi adicionado antes desta data, nos mesmos formatos. Quando usado junto com `added_after`, ambas as condições precisam valer. |
| `has_episodes` | bool | Detecção de episódios: marcadores de temporada/episódio ou hashes CRC no nome do torrent ou dos arquivos, ou uma sequência de arquivos numerados. Um torrent cujo maior arquivo tem pelo menos 5x o tamanho do segundo maior é lido como um filme com extras e rejeitado. |
| `is_music` | bool | Algum arquivo termina em `.m3u`, `.mp3`, `.flac`, `.m4a` ou `.m4b`. |
| `has_tag` | string | O torrent tem esta tag. Funciona como um portão: sem ela, nada mais na entrada pode casar. |
| `not_has_tag` | string | O torrent não tem esta tag, e funciona como portão do mesmo jeito. |
| `tags_match_all` | list | Todas as tags listadas estão presentes (sem diferenciar maiúsculas). |
| `tags_match_any` | list | Pelo menos uma das tags listadas está presente. |
| `tags_missing_all` | list | Nenhuma das tags listadas está presente. |
| `tags_missing_any` | list | Pelo menos uma das tags listadas está ausente. |
| `provider` | string | O lançamento é mantido por esta conta, identificada pelo seu `name` no bloco providers. É um portão, não uma correspondência: combinado com outra condição, significa que ambas precisam valer. Sozinho, coloca a conta inteira no diretório. |
| `not_provider` | string | Nenhuma conta que mantém o lançamento é esta. Funciona como portão do mesmo jeito. |
| `and` | list | Todas as condições aninhadas precisam casar. |
| `or` | list | Pelo menos uma das condições aninhadas precisa casar. |

As tags vêm da análise de mídia — veja [tags.md](tags.md) para a lista completa.

Os padrões são escritos como `/expression/flags`, onde as flags podem ser qualquer uma de `i` (sem diferenciar maiúsculas), `m` (multilinha), `s` (o ponto corresponde a quebra de linha) e `x` (estendida). Um valor sem barras é compilado como uma expressão regular Go pura.

As condições dentro de uma mesma entrada de filtro **não** são combinadas com AND por padrão — a maioria delas casa com a entrada assim que uma delas for verdadeira. Use um bloco `and:` explícito quando quiser que todas valham:

```yaml
directories:
  anime:
    group: media
    group_order: 10
    filters:
      - and:
          - has_episodes: true
          - any_file_inside_regex: /^\[/
          - not_regex: /\[One Pace\]/
```

### Diretórios por conta {#per-account-directories}

Junto com `__all__`, cada conta configurada ganha um diretório próprio, com o nome dela: `__realdebrid__`, `__torbox__`, `__alldebrid__`, `__nzb__`. Elas não são configuradas; aparecem porque a conta existe, e somem quando ela é removida. Com uma única conta, a pasta dela fica de fora da listagem da raiz do mount, e `__all__` tem os mesmos arquivos. Caminhos HTTP e WebDAV diretos, como `/http/__realdebrid__/`, ainda respondem. Pelo mount, ele também não resolve mais; aponte qualquer biblioteca ou script que usava `__<name>__` para `__all__`.

Cada um guarda tudo o que a conta tem e, diferente de um diretório filtrado, também decide para onde as leituras vão. Um lançamento que está em duas contas é uma única entrada na biblioteca; sem isso, cada cópia dele seria transmitida da conta que vem primeiro no bloco `providers`:

```
__realdebrid__/Some.Release/movie.mkv   → streamed from Real-Debrid
__torbox__/Some.Release/movie.mkv       → streamed from TorBox
```

A fixação exclui as outras contas, em vez de apenas dar preferência à nomeada. Não há failover silencioso: se a TorBox não conseguir servir o arquivo, a leitura em `__torbox__` falha, em vez de responder discretamente com os bytes da Real-Debrid. As leituras em outras partes do mount não mudam e continuam fazendo failover normalmente.

Duas consequências disso vêm do fato de as contas não terem conteúdo idêntico:

- Um diretório lista apenas os arquivos que a conta realmente tem. Se a TorBox baixou parte de um lançamento que a Real-Debrid tem completo, `__torbox__` mostra só essa parte.
- A quebra é avaliada por conta. Um arquivo morto na Real-Debrid, mas saudável na TorBox, dá 404 em `__realdebrid__` e toca em `__torbox__`, enquanto o resto do mount continua servindo ele.

O diretório recebe o nome do `name` da conta, que por padrão é o `type`. Duas contas no mesmo serviço precisam de nomes diferentes (`rd-main`, `rd-backup`) e ganham um diretório cada. O backend Usenet é `nzb` por padrão, então aparece como `__nzb__`; defina `name: usenet` nessa entrada de provider se preferir navegar por `__usenet__`.

Você pode renomear uma conta depois. O zurg enxerga os mesmos lançamentos listados com o novo nome e os move para lá. O diretório antigo some junto com o nome antigo. Se um media server lê esse diretório, aponte-o para o novo antes de renomear.

Como o mesmo lançamento aparece em todas as contas que o têm, e também nos seus diretórios filtrados, aponte um media server para uma parte do mount, e não para tudo, senão ele vai escanear o mesmo conteúdo várias vezes.

Uma conta com nome igual a um diretório que o zurg já usa (`all`, `unplayable`, `dump`, `downloads`) não ganha diretório próprio, e o zurg registra um aviso na inicialização em vez de substituir o existente.

### Catálogos de debrid locais {#local-debrid-catalogs}

Cada entrada de proveedor de debrid acepta un bloque `library` opcional:

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: PRIMARY_RD_TOKEN
    download_tokens: # Optional bandwidth fallback.
      - SECOND_RD_TOKEN
    library:
      source: local
      path: torrents/rd-local
```

`source` tiene `provider` como valor predeterminado. Con `local`, los archivos `.zurgtorrent` portátiles controlan la pertenencia y la reproducción usa las credenciales de esta cuenta. `path` tiene `torrents/<resolved-account-name>` como valor predeterminado y debe quedar dentro de `torrents/`. Un mismo directorio de origen no puede pertenecer a dos cuentas habilitadas. Los proveedores NZB conservan su biblioteca `nzbs/` existente.

En este ejemplo, ambos tokens de RD sirven al mismo catálogo en `torrents/rd-local/`. El segundo token no necesita entrada de proveedor ni directorio, y su biblioteca de torrents no se importa. `download_tokens` mantiene su comportamiento de respaldo por ancho de banda; no obliga a que todas las descargas pasen por el segundo token. Dos entradas de proveedor locales separadas controlan dos directorios de catálogo distintos, incluso si ambas son Real-Debrid. Las credenciales se quedan en la configuración y nunca se exportan a archivos portátiles.

Consulta [bibliotecas portátiles](../guides/local-libraries.md) para la exportación sin conexión, la migración desde `dump/`, la semántica de compartir y los límites de reproducción.

#### Descarregando uma conta online para uma biblioteca local {#offloading-an-online-account-into-a-local-library}

Uma conta Real-Debrid ou AllDebrid que possui o próprio catálogo (sem `source`, ou com `source: provider`) pode mover os releases finalizados para uma biblioteca local e apagá-los da conta, o que libera as vagas deles:

```yaml
providers:
  - name: rd
    type: realdebrid
    token: YOUR_RD_TOKEN
    library:
      offload_to: rd-local      # a local entry of the same type
      offload_after_mins: 30    # optional, 30 is the default

  - name: rd-local
    type: realdebrid
    token: YOUR_RD_TOKEN        # the same account
    library:
      source: local
```

| Chave | Padrão | Significado |
|---|---|---|
| `library.offload_to` | nenhum | Nome de uma entrada `source: local` habilitada do mesmo tipo. Só contas `realdebrid` e `alldebrid` aceitam essa opção, já que só os links delas continuam funcionando depois que o torrent é apagado. Não pode apontar para a própria conta. |
| `library.offload_after_mins` | `30` | Por quanto tempo um release precisa estar completo na conta antes de ser movido automaticamente. A contagem começa quando o zurg o viu completo pela primeira vez, então um reinício recomeça a espera. Precisa de `offload_to`. |

Um release só é movido quando todos os arquivos têm um link que outra conta consegue resgatar, nada está reparando ou baixando ele, nenhum job do Sonarr ou do Radarr no endpoint do qBittorrent ainda o lista, e mover ele mantém o nome da pasta e todos os diretórios em que ele está. A pasta dele continua onde estava e nenhuma verificação no servidor de mídia é iniciada. A página do release no painel pode mover um release manualmente, com ou sem `offload_to`. Veja [bibliotecas portáteis](../guides/local-libraries.md#offload-an-online-account-into-a-local-library) para a ordem das etapas, o que acontece quando uma falha e como a reprodução local com um token compartilhado é protegida.
