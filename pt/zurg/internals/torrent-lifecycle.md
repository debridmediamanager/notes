# Ciclo de vida de torrents no Real-Debrid, AllDebrid e TorBox {#torrent-lifecycle-on-real-debrid-alldebrid-and-torbox}

Medido em 2026-08-30 com contas ativas. Tudo marcado como **observed** saiu de uma captura. Tudo marcado como **inferred** não saiu, e o texto explica o motivo.

O zurg precisa disso porque o shim do qBittorrent tem que informar ao Sonarr e ao Radarr em que etapa um download está. Hoje ele não consegue fazer isso. `TorrentInfo.Status` carrega o vocabulário de status do Real-Debrid, e os pacotes do AllDebrid e do TorBox traduzem para esse vocabulário antes de o código do próprio zurg ver qualquer torrent. O TorBox `stalled (no seeds)` chega como `queued`. Nada carrega seeders, velocidade ou eta. Por isso a tabela de etapas teve que ser montada a partir do wire, e não dos pacotes de provedores que já normalizam tudo isso.

O harness é `scripts/torrent_lifecycle_probe.py`. Ele acessa as APIs REST brutas, para que as capturas sejam o status do wire. Ele apaga tudo o que adiciona no caminho de saída, inclusive com Ctrl-C.

---

## Como isto foi medido {#how-this-was-measured}

### As contas {#the-accounts}

| Provedor | Conta | Por que este |
|---|---|---|
| Real-Debrid | uma conta de teste | nenhum zurg em execução usa, então nada mais foi tocado durante a execução |
| AllDebrid | uma chave de teste | a conta já tinha outros magnets, então só os ids criados pela execução foram apagados |
| TorBox | uma chave real | **outra instância do zurg estava carregada com a mesma conta**, o que não é uma nota de rodapé. Veja [Hazards](#hazards-found-on-the-way) |

As credenciais vêm de `RD_TOKEN` `AD_KEY` `TB_KEY` no ambiente. Nada as grava em
uma captura.

### Os torrents {#the-torrents}

Todos são legítimos. São imagens FOSS e um filme de domínio público. Cada info hash que veio de um `.torrent` foi recalculado a partir do arquivo pelo harness, e não digitado à mão. Os tamanhos dos swarms são scrapes do tracker feitos no mesmo dia.

| Caso | Torrent | Info hash | Tamanho | Seeders no tracker | Webseeds |
|---|---|---|---|---|---|
| cached | Big Buck Bunny | `dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c` | 264 MiB | n/d | n/d |
| cached | Sintel | `08ada5a7a6183aae1e09d831df6748d566095a10` | 123 MiB | n/d | n/d |
| cached | ubuntu-26.04.1-desktop-amd64.iso | `5b1e0d988fc7a0c9e99bd852071681a59974b39f` | 6.04 GiB | 22 a 27 | nenhum |
| uncached | debian-13.6.0-arm64-DVD-1.iso | `4d38178b8f08447ea8609e844b0071354ed65887` | 3.72 GiB | 212 | 2 |
| uncached | debian-13.2.0-amd64-DVD-1.iso | `7f23b66ebc763f6d931e999583adfd22a7d796fa` | 3.71 GiB | 328 | 2 |
| webseed | Prelinger `205882_Home_Movie_005588` | `69e7bba940b3c2edf7ce517330e3ca904877d8d1` | 0.71 GiB | 0 seeders e 0 leechers | 3 |
| seedless | ubuntu-16.04.6-desktop-i386.iso | `c16796a74dc24cc7c6df2f7b66b861e22dec69b1` | 1.56 GiB | 0 | nenhum |
| seedless | ubuntu-24.04-beta-live-server-s390x.iso | `8e693ebcdda44f741e2034cedbb552e93944143d` | 1.18 GiB | 0 | nenhum |
| nometa | 40 hex aleatórios | `3f9c1a77b0e4d2568af3c01e9b7d4a5268c1f0e3` | nenhum | nenhum | nenhum |

Os zeros são reais e não se trata de um tracker morto. O `torrent.ubuntu.com` foi consultado duas vezes para as três entradas do Ubuntu no mesmo loop. Ele respondeu 22 e depois 27 seeders para a 26.04.1, enquanto respondeu um `d5:filesdee` vazio para as duas seedless. O mesmo vale para o `bt1.archive.org` e para o item da Prelinger.

Antes de adicionar qualquer coisa, perguntei ao `checkcached` da TorBox sobre todos os hashes. É a única consulta de cache não destrutiva das três. Ela disse cached para as três linhas cached e uncached para as outras seis. Essa é exatamente a divisão que os nomes dos casos indicam.

### Cadência de consulta e limites {#poll-cadence-and-caps}

3 s durante os primeiros 2 minutos, depois 15 s. 1 s para o caso em cache, porque todo o ciclo de vida ali pode terminar dentro de uma única consulta normal. Limite de 15 minutos por torrent para a campanha, em vez do padrão do script, que é 30. O timeout padrão proposto pelo shim é de 10 minutos, e um torrent que ainda está em andamento aos 15 já passou da única janela que importa. As adições no Real-Debrid são espaçadas em pelo menos 20 s.

Cada provedor rodou como seu próprio processo, com seu próprio diretório de saída. Isso mantém o espaçamento das adições no Real-Debrid correto dentro de um mesmo processo e permite que os três rodem ao mesmo tempo.

---

## Real-Debrid

### Endpoints

```
POST   /rest/1.0/torrents/addMagnet          magnet=magnet:?xt=urn:btih:<hash>   -> 201 {"id","uri"}
POST   /rest/1.0/torrents/selectFiles/{id}   files=all                           -> 204
GET    /rest/1.0/torrents/info/{id}                                              -> 200 object
DELETE /rest/1.0/torrents/delete/{id}                                            -> 204
```

### Valores de status observados {#status-values-observed}

`waiting_files_selection` `magnet_conversion` `magnet_error` `queued` `downloading` `uploading`
`downloaded`

Não observado aqui. `compressing` `virus` `error` `dead`. Esses precisam de conteúdo que esta campanha não tinha como produzir de forma legítima.

### Quais campos do wire existem em cada status {#which-wire-fields-exist-in-which-status}

Isto importa mais que o vocabulário. Campos aparecem e somem. Um mapper que lê `speed` em todos os estados acaba lendo uma chave ausente metade das vezes.

| Campo | magnet_conversion | queued | downloading | uploading | downloaded |
|---|---|---|---|---|---|
| `status` | sim | sim | sim | sim | sim |
| `progress` | 0 | 0 | **percentual float** de 0 a 100 | **reinicia em 0** e sobe até 100 | 100 |
| `seeders` | sim | **ausente** | sim | **ausente** | **ausente** |
| `speed` | **ausente** | **ausente** | sim, bytes por segundo | sim, sempre 0 na captura | **ausente** |
| `bytes` / `original_bytes` | 0 | tamanho real | tamanho real | tamanho real | tamanho real |
| `filename` | `"Magnet"` | nome real | nome real | nome real | nome real |
| `files` | `[]` | preenchido | preenchido | preenchido | preenchido |
| `links` | `[]` | `[]` | `[]` | é preenchido durante a fase | preenchido |
| `ended` | ausente | ausente | ausente | ausente | presente |

`progress` é um **float** e não um inteiro. A captura tem 0.4, 0.8 e 1.4 junto com 100. Um detector de travamento que arredonda para percentual inteiro vai marcar um release de 100 GB como travado a 1 MB/s.

`progress` **volta para trás de propósito**. Ele é zerado para 0 quando o status vira `uploading` e sobe até 100 de novo. Movimento precisa ser definido como mudança de etapa ou aumento de progresso, nunca como um percentual monotônico.

`seeders` some em vez de ir para zero quando o torrent sai de `downloading`. O mesmo acontece com `speed`. Um mapper deve tratar uma chave ausente como desconhecida, e não como zero.

### O que cada caso fez {#what-each-case-did}

| Caso | Torrent | Transições com segundos desde a adição | Veredito |
|---|---|---|---|
| em cache | Big Buck Bunny | `downloaded`@0.0 | concluído em 1.32 s de ponta a ponta |
| em cache | Sintel | `downloaded`@0.0 | concluído em 0.73 s |
| em cache | Ubuntu 26.04.1 | `downloaded`@0.0 | concluído em 0.32 s |
| sem cache | Debian 13.6.0 arm64 DVD-1 | `downloaded`@0.0 | já estava em cache nesta conta |
| sem cache | Debian 13.2.0 amd64 DVD-1 | `queued`@0.0 `downloading`@3.1 `uploading`@166.5 `downloaded`@196.8 | concluído. 3.71 GiB em 197 s |
| webseed | Prelinger home movie | `magnet_conversion`@0.0 `magnet_error`@318.0 | falhou |
| sem seeds | ubuntu-16.04.6-desktop-i386 | `queued`@0.0 `downloading`@3.1 `uploading` `downloaded`@166.8 | concluído. O caso não se reproduziu |
| sem seeds | ubuntu-24.04-beta-live-server-s390x | `queued`@0.0 `downloading`@3.1 e nada depois disso | **limitado em 907.6 s ainda em `downloading`**. Esse é o padrão de travamento |
| sem metadados | 40-hex aleatório | `magnet_conversion`@0.0 `magnet_error`@317.9 | falhou |

### A latência do cached add {#the-cached-add-latency}

Isto é o número em que se baseia o modo somente-cache do shim.

| Torrent | addMagnet retorna | selectFiles retorna | primeiro `/torrents/info` | status |
|---|---|---|---|---|
| Big Buck Bunny | t=0 | t+1.211 s | t+1.318 s | `downloaded` |
| Sintel | t=0 | t+0.632 s | t+0.729 s | `downloaded` |
| Ubuntu 26.04.1 | t=0 | t+0.215 s | t+0.320 s | `downloaded` |

**Observado.** Um torrent em cache fica `downloaded` já na primeira leitura depois do `selectFiles`. Todo o custo síncrono são dois round trips. Ele nunca passa por `queued` e nunca passa por `downloading`.

Uma segunda rodada consultou `/torrents/info` a cada 0,25 s, tanto no intervalo entre `addMagnet` e `selectFiles` quanto depois dele. Isso é o que `--rd-select-detail` faz, e ela confirma o formato.

| Torrent | Status antes do `selectFiles` | `selectFiles` | Primeira leitura depois dele | addMagnet até `downloaded` |
|---|---|---|---|---|
| Big Buck Bunny | `waiting_files_selection` com 3 arquivos listados e `links` vazio | 204 em t+1,314 s | `downloaded` `progress` 100 `links` 1 | **1,535 s** |
| Sintel | `waiting_files_selection` com 11 arquivos listados | 204 em t+0,627 s | `downloaded` `progress` 100 `links` 1 | **0,841 s** |
| Ubuntu 26.04.1 | `waiting_files_selection` com 1 arquivo listado | 204 em t+0,219 s | `downloaded` `progress` 100 `links` 1 | **0,430 s** |

Então a sequência completa de um torrent em cache é `waiting_files_selection` e depois `downloaded`, sem nada no meio. A lista de arquivos já existe antes do `selectFiles`. Quem preenche `links` é o `selectFiles`.

**A janela de probe do modo somente-cache pode ser de uma única consulta.** De 0,43 s a 1,54 s de ponta a ponta, em três torrents de 123 MiB, 264 MiB e 6,04 GiB. Uma janela de dois segundos com consultas a cada quarto de segundo é folgada.

Comparado aos 100 s que o Sonarr e o Radarr permitem para uma chamada `torrents/add` (veja [qbittorrent-client-contract.md §1.7a](qbittorrent-client-contract.md)), uma janela de probe de poucos segundos não custa nada. Não há motivo para configurá-la em dezenas de segundos.

### Peculiaridades que um stage mapper precisa contornar {#quirks-a-stage-mapper-has-to-survive}

- **`selectFiles` responde 404 enquanto o torrent ainda está em `magnet_conversion`, e o erro engana.**
  O corpo é `{"error":"parameter_missing","error_code":1,"error_details":"{files} is missing"}` mesmo
  quando `files=all` foi enviado. Simplesmente ainda não há arquivos para selecionar. Não é uma falha
  do add e o torrent continua vivo. As duas execuções que bateram nisso sobreviveram mais 318 s.
- **O hash de um tracker privado pode ser descartado de imediato, e não após 318 s.** O hash por trás do relatório do qBittorrent de
  2026-08-31 (um remux da CiNEPHiLES de um indexador UNIT3D, `45e1ec0d…`) respondeu `magnet_error` com zero arquivos na
  primeira leitura após o addMagnet, sem nenhuma janela de `magnet_conversion`, segundos após o add. Se o Real-Debrid
  reconheceu o hash ou falhou rápido nele, o resultado observável é o mesmo: um hash privado não tem enxame DHT, então o
  addMagnet nunca pode funcionar para ele, e o selectFiles na instância morta responde com o 404 enganoso descrito acima.
- **O `addTorrent` não pula nada para conteúdo não cacheado, mas pula tudo para o cacheado.** Um `.torrent` enviado para conteúdo que o
  Real-Debrid não tem (um Big Buck Bunny do archive.org, semeado mas não cacheado) foi para `magnet_conversion` como um
  magnet simples; os metadados do arquivo não são usados para resolver. Um cacheado (uma ISO do Ubuntu) respondeu
  `waiting_files_selection` com a lista de arquivos já na primeira leitura, foi selecionado e terminou `downloaded` em
  menos de dois segundos, sem passar por `magnet_conversion`. Ou seja, o valor do upload está na busca imediata de hash→cache, que
  é o que torna o lançamento de um tracker privado adicionável sempre que o conteúdo está cacheado, e nunca adicionável como magnet.
- **A resolução de metadados desiste após 318 s.** Duas execuções independentes foram de `magnet_conversion` para `magnet_error` em
  317,9 s e 318,0 s. Esse é o limite que um magnet sem peers alcançáveis atinge. É o mesmo
  esteja ou não um torrent existindo para o hash.
- **`seeders` mente durante `magnet_conversion`.** O hash aleatório de 40 hex reportou `seeders: 1` em
  80,9 s. Não existe torrent para ele.
- **`ended` em um torrent cacheado recém-adicionado traz uma data antiga.** As capturas trazem
  `2025-12-28` e `2026-07-28` para torrents adicionados em 2026-08-30. É quando o Real-Debrid teve o
  conteúdo pela primeira vez, e não quando esta instância terminou. Não calcule uma idade a partir dele.
- **Um magnet sem peers morre na resolução de metadados e nunca chega ao webseed.** O Real-Debrid respeita webseeds quando já tem
  o torrent. Ele não consegue obter o torrent a partir de um magnet sem peers. Assim,
  um item só com webseed adicionado como magnet termina em `magnet_error`. Isso é uma falha de metadados, e não
  de webseed, e os dois parecem iguais vistos de `/torrents/info`.

## AllDebrid

### Endpoints

`v4` e `v4.1` não são intercambiáveis, e essa diferença nos pegou nesta campanha.

```
POST /v4/magnet/upload      magnets[]=magnet:?xt=urn:btih:<hash>   -> 200, per-magnet `ready` flag
POST /v4/magnet/upload/file multipart files[]=<the .torrent>       -> 200, per-file `ready` flag
GET  /v4.1/magnet/status?id=<id>                                   -> 200, data.magnets is an OBJECT
GET  /v4.1/magnet/status                                           -> 200, data.magnets is a LIST
POST /v4/magnet/delete      id=<id>                                -> 200
```

**O upload de arquivos responde em `files`, não em `magnets`.** Os mesmos campos em cada entrada: `id`, `hash`, `name`, `ready` e um `error` opcional por entrada. Então a flag `ready` abaixo é a resposta do cache de qualquer forma, mas um decoder escrito para a resposta de magnet lê uma lista vazia.

**E o arquivo é a única forma de um release que o AllDebrid consegue descrever sem um swarm.** Medido em 2026-09-01 na conta de teste, com dois torrents privados sintéticos de mesmo formato, cujos hashes nenhum swarm jamais viu. Enviados como arquivos, voltaram com seus nomes e tamanhos reais (`"name":"zurg.private.ad.probe","size":65536`), aparecendo como `In queue` com o timer ainda não iniciado. Enviado como um hash puro em `magnets[]`, a resposta foi `"name":"noname","size":0`: o AllDebrid aceitou e não sabia nada sobre ele, o que acontece com todo release de tracker privado adicionado por hash.

**`/v4/magnet/status` foi descontinuado.** Com ou sem id, ele responde HTTP 200 com `{"status":"error","error":{"code":"DISCONTINUED"},"deprecated":true}`. `/v4/magnet/upload` e `/v4/magnet/delete` continuam funcionando. Então a premissa do plano, de que dava para usar o endpoint de status da v4 e amostrar a v4.1 uma vez para comparar, está invertida. A v4.1 é o único endpoint de status, e o harness registra uma leitura v4 por torrent para que a captura traga a prova, e não só a afirmação.

A autenticação é `Authorization: Bearer <apikey>`. Não é preciso o parâmetro `agent`.

### Valores de status observados {#status-values-observed-1}

| `statusCode` | `status` | Seen |
|---|---|---|
| 0 | `In queue` | yes |
| 1 | `Downloading` | yes |
| 2 | `Compressing / Moving` | **no** |
| 3 | `Uploading` | yes |
| 4 | `Ready` | yes |
| 5 and above | the error codes | **no** |

### Quais campos do wire existem em cada status {#which-wire-fields-exist-in-which-status-1}

| Campo | Na fila (0) | Baixando (1) | Enviando (3) | Pronto (4) |
|---|---|---|---|---|
| `status` / `statusCode` | sim | sim | sim | sim |
| `version` | 1 | 2 | 2 | 2 |
| `filename` | `"noname"` até os metadados chegarem | nome real assim que os metadados chegarem | nome real | nome real |
| `size` | 0 até os metadados chegarem | tamanho real | tamanho real | tamanho real |
| `downloaded` | 0 | **o progresso, em bytes** | igual a `size` | **ausente** |
| `downloadSpeed` | 0 | sim, em bytes por segundo | 0 | **ausente** |
| `seeders` | 0 | sim | 0 | **ausente** |
| `uploaded` / `uploadSpeed` | 0 | 0 | **o progresso desta fase** | **ausente** |
| `processingPerc` | 0 | 0 | 0 | **ausente** |
| `files` / `nbLinks` | ausente | ausente | ausente | presente |
| `completionDate` | 0 | 0 | 0 | definido |

**Não existe porcentagem em lugar nenhum.** O progresso no AllDebrid é `downloaded / size`, e os dois são inteiros em bytes. `processingPerc` ficou em 0 em todos os estados em todas as capturas.

`Uploading` é o AllDebrid movendo o download concluído para o próprio armazenamento. Ele tem seu próprio contador de progresso em `uploaded` e `uploadSpeed`, e o `downloadSpeed` fica em 0 o tempo todo. Uma regra de travamento que só observa `downloaded` vai considerar uma fase `Uploading` saudável como travada.

### O que cada caso fez {#what-each-case-did-1}

| Caso | Torrent | `ready` no upload | Transições com segundos desde o add | Veredito |
|---|---|---|---|---|
| cached | Big Buck Bunny | true | `Ready`@0.0 | concluído em 0.11 s |
| cached | Sintel | true | `Ready`@0.0 | concluído em 0.12 s |
| cached | Ubuntu 26.04.1 | true | `Ready`@0.0 | concluído em 0.11 s |
| uncached | Debian 13.6.0 arm64 DVD-1 | true | `Ready`@0.0 | já estava em cache |
| uncached | Debian 13.2.0 amd64 DVD-1 | false | `In queue`@0.0 `Downloading`@12.5 com todos os contadores em zero até 634.9 `Uploading`@650.1 `Ready`@876.9 | concluído em 877 s |
| webseed | Prelinger home movie | false | `In queue`@0.0 `Downloading`@6.3 e todos os contadores em zero depois disso | **limitado em 907.8 s ainda `Downloading`** |
| seedless | ubuntu-16.04.6-desktop-i386 | false | `In queue`@0.0 `Downloading`@9.4 com todos os contadores em zero até 589.6 `Uploading`@619.9 `Ready`@650.2 | concluído em 650 s |
| seedless | ubuntu-24.04-beta-live-server-s390x | false | `In queue`@0.0 `Downloading`@3.2 e todos os contadores em zero depois disso | **limitado em 907.0 s ainda `Downloading`** |
| nometa | random 40-hex | false | `In queue`@0.0 `Downloading`@9.4 e todos os contadores em zero depois disso | **limitado em 907.4 s ainda `Downloading`** |

Uma execução separada com Debian 13.3.0 arm64 DVD-1 (`6aa9b0a4709a0d6c4982fd0363614d9006877223`) pegou um ciclo completo de uncached e é a sequência de referência.

| Segundos | Estado | O que mudou |
|---|---|---|
| 0.0 | `In queue` 0 version 1 | `filename` é `"noname"` e `size` é 0 |
| 2.2 | `Downloading` 1 version 2 | ainda sem nome e sem tamanho |
| 4.3 | `Downloading` | `filename` e `size` são resolvidos |
| 6.5 a 55.1 | `Downloading` | `downloaded` sobe até `size`. `downloadSpeed` chega perto de 110 MB/s no pico. `seeders` de 8 a 9 |
| 57.2 | `Uploading` 3 | `downloadSpeed` cai para 0. `uploadSpeed` e `uploaded` começam a subir |
| 65.6 | `Ready` 4 | `files` e `nbLinks` aparecem. Seis campos de progresso desaparecem |

3.72 GiB em 65.6 s.

### O AllDebrid não informa progresso nenhum enquanto um job espera a própria infraestrutura {#alldebrid-reports-no-progress-at-all-while-a-job-waits-for-its-own-infrastructure}

Este é o achado que mais muda o design do timeout, e levou duas execuções independentes para eu confiar nele.

`Downloading` com `statusCode` 1 aparece em poucos segundos depois do upload. Por um tempo depois disso,
o AllDebrid reporta `downloaded` 0, `downloadSpeed` 0, `seeders` 0, `uploaded` 0,
`uploadSpeed` 0 e `processingPerc` 0. Ele também volta `size` para 0 e `filename` para o info
hash, mesmo quando já tinha informado os dois corretamente.

| Execução | Quanto tempo todos os contadores ficaram em zero | O que aconteceu depois |
|---|---|---|
| Debian 13.2.0 amd64 DVD-1 | **622 s** de 12.5 s até 634.9 s | 3.71 GiB baixados em 15 s, depois `Uploading`, depois `Ready` em 876.9 s |
| ubuntu-16.04.6-desktop-i386 | **580 s** de 9.4 s até 589.6 s | 1.56 GiB baixados em 30 s, depois `Uploading`, depois `Ready` em 650.2 s |

Os dois terminaram. Nenhum deles mostrou um único byte de progresso nos primeiros dez minutos.

**Um timeout de dez minutos sem progresso abandonaria jobs saudáveis do AllDebrid.** O default proposto
de `download_timeout_mins`, 10, cai dentro dessa janela nas duas execuções. Ou o timeout
precisa ser maior que isso, ou o AllDebrid `Downloading` com `size` 0 precisa contar como uma etapa própria,
na qual o relógio não roda. Perder o nome e o tamanho é como o AllDebrid diz que o job está
atribuído, mas ainda não começou, e isso não é uma falha.

Uma execução que começou logo de cara serve de contraste. Debian 13.3.0 arm64 DVD-1 foi de `In queue` para
contadores de bytes reais em 6.5 s. Ou seja, a espera é uma fila e não um atraso fixo.

### A flag `ready` é uma resposta real de cache {#the-ready-flag-is-a-real-cache-answer}

`ready` na resposta de `/v4/magnet/upload` veio como true para todos os hashes que a TorBox também marcou como cacheados, e como false para os dois que a campanha baixou. A AllDebrid não tem uma consulta de cache separada, então essa flag é todo o sinal de cache. O zurg agora passa esse valor pelos dois caminhos de adição, o do magnet e o do upload de arquivo, como `MagnetResponse.Cached` com `CacheKnown` definido. Assim, um backend que não consegue responder nunca é confundido com um que informa um miss.

**Um `ready` false significa que o magnet já foi adicionado.** Não há como perguntar à AllDebrid se um hash está em cache sem adicioná-lo. Um caminho somente-cacheado na AllDebrid precisa apagar o miss.

## TorBox

### Endpoints

```
GET  /v1/api/torrents/checkcached?hash=<hash>&format=list
POST /v1/api/torrents/createtorrent      magnet=…&seed=3&allow_zip=false   -> {"success":true,"data":{"torrent_id":N}}
POST /v1/api/torrents/createtorrent      multipart file=<the .torrent>    -> the same shape; `detail` says whether it was cached
GET  /v1/api/torrents/mylist?id=<id>&bypass_cache=true
POST /v1/api/torrents/controltorrent     {"torrent_id":N,"operation":"delete"}
```

### Valores de status observados {#status-values-observed-2}

`metaDL` `checking` `stalledDL` `stalled (no seeds)` `downloading` `processing`
`uploading (no peers)` `uploading` `cached`

`processing`, `checking` e `stalledDL` **não estão na tabela de tradução do zurg** (`internal/torbox/types.go` `normalizeStatus`). Os três caem no ramo padrão e são reportados como `downloading`.

`checking` é a fase em que o TorBox espera pelos metadados, e não onde ele verifica um hash. Um magnet cujo swarm nunca responde vai para `metaDL`, depois para `checking`, e fica ali. O hash aleatório de 40-hex ainda estava em `checking` no limite de 910 s, e o item Prelinger sem peers também em 911 s. O TorBox nunca desiste como o Real-Debrid faz em 318 s.

**Enviar o `.torrent` pula essa espera por completo, e é essa a diferença total para o release
de um tracker privado.** Medido em 2026-09-01 na conta acima, o mesmo torrent privado sintético foi
enviado das duas formas. Como hash: aceito com um `torrent_id`, depois `checking` com `name` definido
como o hash puro, `size: -1`, `files: null` e `eta: 8640000` — o TorBox procurando um swarm que não
está na DHT, o que ele vai fazer até o limite sem relatar nada sobre isso. Como arquivo, em
`POST /torrents/createtorrent` com os bytes em uma parte multipart `file`: lido três segundos depois,
trazendo o próprio nome do torrent, o tamanho real e `stalled (no seeds)` — o mesmo conteúdo que
ninguém tem, mas agora descrito. A fase é o que importa. `checking` com `size: -1` vira
`StageResolvingMetadata`, que diz que o trabalho está em andamento e que nada pode ser concluído;
`stalled (no seeds)` vira `StageStalledNoPeers`, com a qual o endpoint do qBittorrent consegue agir.
Um release em cache voltou como `done` com 100%, e com a lista de arquivos dentro dos mesmos três
segundos. O nome da parte é fundamental: um arquivo enviado com qualquer outro nome simplesmente não
é visto, e o endpoint responde `MISSING_REQUIRED_OPTION`, "You must provide either a file or magnet link".

(Uma tradução anterior foi rejeitada: os trechos de código não batiam (` maps to `). Mantenha a estrutura exatamente.)

### Quais campos do wire existem em cada status {#which-wire-fields-exist-in-which-status-2}

TorBox envia o mesmo conjunto de chaves em todos os estados e muda apenas os valores. Por isso é o mais fácil de ler dos três. Os valores é que carregam o significado.

| Estado | `download_finished` | `download_present` | `cached` | `active` | `progress` | `eta` | `size` |
|---|---|---|---|---|---|---|---|
| `metaDL` | false | false | false | true | 0 | 8640000 | 0 |
| `checking` | false | false | false | true | 0 | 8640000 | **-1** |
| `stalledDL` | false | false | false | true | tiny | 8640000 | real |
| `stalled (no seeds)` | false | false | false | true | 0 | 8640000 | real |
| `downloading` | false depois **true** | false | false | true | fração | segundos | real |
| `processing` | **true** | **false** | false | true | 1 | segundos | real |
| `uploading (no peers)` | **true** | **false** | false | true | 1 | 2591994 | real |
| `uploading` | true | **true** | true | true | 1 | 0 | real |
| `cached` | true | true | true | false | 1 | 0 | real |

Nomes dos campos. O plano listava todos como não verificados.

| O que é | Campo do TorBox | Formato |
|---|---|---|
| progress | `progress` | **fração de um**, não porcentagem. `0.0793719` |
| seeders | `seeds` | inteiro |
| leechers | `peers` | inteiro |
| taxa de download | `download_speed` | bytes por segundo |
| taxa de upload | `upload_speed` | bytes por segundo |
| eta | `eta` | segundos. `8640000` é o valor de "não sabido" |
| bytes baixados | `total_downloaded` | inteiro |
| saúde do swarm | `availability` | float. Vai para **-1** em `uploading (no peers)` |
| onde estão os dados | `download_path` | null até os dados estarem presentes |

`8640000` são 100 dias. É a forma que o TorBox usa para dizer que não sabe. É também a mesma constante que o shim do zurg entrega ao Sonarr hoje quando não tem nada para reportar.

### O que cada caso fez {#what-each-case-did-2}

| Caso | Torrent | `checkcached` | Transições com segundos desde a adição | Veredito |
|---|---|---|---|---|
| em cache | Big Buck Bunny | true | `cached`@0.0 | concluído em 0.83 s |
| em cache | Sintel | true | `cached`@0.0 | concluído em 0.94 s |
| em cache | Ubuntu 26.04.1 | true | `cached`@0.0 | concluído em 0.69 s |
| sem cache | Debian 13.6.0 arm64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@7.3 `downloading`@24.1 depois **gone**@48.6 | apagado pelo outro zurg em 86.7% |
| sem cache | Debian 13.2.0 amd64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@13.8 `downloading`@27.8 `processing`@69.4 `downloading`@72.7 `uploading (no peers)`@83.1 depois **gone**@86.7 | apagado pelo outro zurg |
| webseed | Prelinger home movie | false | `metaDL`@0.0 `checking`@23.3 e nunca mais nada | **limitado a 911.3 s em `checking`**. O TorBox não usou o webseed |
| sem seeds | ubuntu-16.04.6-desktop-i386 | false | `metaDL`@0.0 `checking`@10.5 `downloading`@20.6 `processing`@184.4 depois **gone**@200.4 | apagado pelo outro zurg em `processing` |
| sem seeds | ubuntu-24.04-beta-live-server-s390x | false | `metaDL`@0.0 `checking`@18.9 `stalled (no seeds)`@169.3 `downloading`@230.9 depois **gone**@462.3 | apagado pelo outro zurg em 91.9 por cento |
| sem metadados | 40 caracteres hex aleatórios | false | `metaDL`@0.0 `checking`@10.2 e nunca mais nada | **limitado a 910.3 s em `checking`** |

Uma execução separada, com polling de 0.5 s contra o Debian 13.5.0 amd64 netinst
(`58846860f0a766f8a42b0bb214d8c713fdf1b167`), sobreviveu tempo suficiente para chegar a concluído e é a sequência de referência.

| Segundos | Estado | `download_finished` | `download_present` | `progress` |
|---|---|---|---|---|
| 0.0 | `stalledDL` | false | false | 0.000289735 |
| 16.3 | `downloading` | false | false | 0.0608651 |
| 54.8 | `processing` | **true** | **false** | 1 |
| 59.1 | `downloading` | **true** | **false** | 0.997972 |
| 64.4 | `uploading` | true | **true** | 1 |

754 MiB em 64.4 s.

Leia as três últimas linhas duas vezes. O TorBox define `download_finished` como true e `progress` como 1 cerca de dez segundos **antes** de os dados estarem presentes. Depois ele volta para `downloading` com um progresso menor que o que acabou de informar. Tanto `progress` quanto `download_state` voltam para trás em um download saudável.

---

## A tabela de stages {#the-stage-table}

The enum de estágio que o shim vai usar é `resolving-metadata` `queued` `downloading` `stalled-no-peers` `finalizing` `done` `failed`, e a string vazia para desconhecido.

### Real-Debrid

| Raw `status` | Stage | Basis |
|---|---|---|
| `magnet_conversion` | `resolving-metadata` | **observed**. `bytes` 0 e `files` vazio e `filename` é o texto literal `"Magnet"` |
| `waiting_files_selection` | `queued` | **observed** com `--rd-select-detail`. Os arquivos já aparecem na lista. `links` fica vazio |
| `queued` | `queued` | **observed**. Tamanho real e nome real já são conhecidos. Sem `seeders` e sem `speed` |
| `downloading` | `downloading` | **observed** |
| `downloading` com `seeders` 0 | `stalled-no-peers` | **observed**. 904 s com `progress` 0, `seeders` 0 e `speed` 0 em 92 consultas |
| `compressing` | `finalizing` | **inferred**. Não foi visto |
| `uploading` | `finalizing` | **observed**. O progresso recomeça do 0 e `seeders` some |
| `downloaded` | `done` | **observed** |
| `magnet_error` | `failed` | **observed** depois de 318 s em `magnet_conversion` |
| `error` `virus` `dead` | `failed` | **inferred**. Não foi visto |

### AllDebrid

| `statusCode` | Etapa | Base |
|---|---|---|
| 0 `In queue` | `queued` | **observado**. Dura alguns segundos. `filename` pode continuar `"noname"` e `size` 0 |
| 1 `Downloading` com `size` 0 | `queued` | **observado**. Não é `downloading` nem `stalled-no-peers`. AllDebrid pegou o job e ainda não começou. Ficou parado por 622 s e 580 s em duas execuções que depois terminaram |
| 1 `Downloading` com `size` real | `downloading` | **observado** |
| 1 `Downloading` com `seeders` 0 e `downloaded` parado | `stalled-no-peers` | **não observado e não dá para inferir com segurança**. Veja abaixo |
| 2 `Compressing / Moving` | `finalizing` | **inferido**. Não foi visto |
| 3 `Uploading` | `finalizing` | **observado**. `uploaded` e `uploadSpeed` mostram o progresso aqui e `downloadSpeed` é 0 |
| 4 `Ready` | `done` | **observado** |
| 5 em diante | `failed` | **inferido**. Não foi visto |

**AllDebrid não tem um padrão observável de travamento.** Um job que o AllDebrid colocou na fila e um job que o AllDebrid não consegue avançar têm a mesma aparência na resposta. Os dois são `statusCode` 1 com `size` 0 e todos os contadores zerados. O item Prelinger ficou exatamente nesse estado durante todo o limite de 907,8 s e outros dois torrents ficaram nele por dez minutos cada e depois terminaram. Assim, nada na resposta do AllDebrid diferencia os dois casos, e um veredito de travamento no AllDebrid só pode vir de um relógio.

### TorBox

| `download_state` bruto | Etapa | Base |
|---|---|---|
| `metaDL` | `resolving-metadata` | **observado**. `size` 0 e `name` igual ao hash |
| `checking` | `resolving-metadata` | **observado**. `size` **-1** enquanto dura. É aqui que a TorBox espera o torrent e não uma verificação de hash. Não está na tabela do zurg hoje |
| `stalledDL` | `stalled-no-peers` | **observado**. Não está na tabela do zurg hoje |
| `stalled (no seeds)` | `stalled-no-peers` | **observado**. O nome exagera. Duas capturas tinham `seeds` 1 e 2 nesse estado. O zurg mapeia para `queued` hoje |
| `downloading` | `downloading` | **observado** |
| `processing` | `finalizing` | **observado**. Não está na tabela do zurg hoje |
| `uploading (no peers)` | `finalizing` | **observado** quando `download_present` é false |
| `uploading` | `done` | **observado** quando `download_present` é true |
| `cached` `completed` `seeding` | `done` | `cached` **observado**. Os outros dois **inferidos** |
| `expired` `reported missing` `failed` `error` `missingfiles` | `failed` | **inferido**. Nenhum visto |

**O par `download_finished` e `download_present` não substitui a string de estado.** Tanto `processing` quanto `uploading (no peers)` e parte de `downloading` trazem `download_finished: true` com `download_present: false`. Essa combinação é uma fase normal de finalização e não um torrent morto. Veja o hazard abaixo.

## O que não pôde ser medido {#what-could-not-be-measured}

- **O caso sem seeds foi reproduzido em um candidato de dois.** Ambos tinham zero peers no tracker.
  ubuntu-16.04.6-desktop-i386 baixou mesmo assim nos três provedores porque a DHT forneceu peers que o
  tracker não conhecia. ubuntu-24.04-beta-live-server-s390x travou no Real-Debrid pelo limite total
  e é a observação de travamento acima. Um zero em uma consulta ao tracker é um preditor fraco. Mantenha
  dois candidatos no caso. O Real-Debrid trouxe os metadados dos dois de qualquer forma e informou `bytes` e
  `filename` corretamente já na primeira leitura `queued`.
- **O status `compressing` do Real-Debrid nunca apareceu.** Todas as execuções concluídas foram de `downloading` direto para
  `uploading`.
- **O código de status 2 do AllDebrid nunca apareceu.** Todas as capturas foram de 1 direto para 3.
- **Nenhum provedor foi levado ao próprio vocabulário de erros.** Os `error`, `virus` e `dead` do Real-Debrid, todos os códigos do AllDebrid acima de 4 e todos os estados de falha do TorBox continuam não medidos.
  Para produzi-los, é preciso um conteúdo bloqueado, infectado ou expirado, e não uma ISO do FOSS.
- **Não foi possível acompanhar o TorBox até o fim com frequência.** Quatro torrents da campanha e um do acompanhamento foram apagados no meio do download pelo outro zurg na conta. Veja o aviso abaixo. Só uma imagem de 754 MiB terminou antes que esse processo consultasse novamente.

## Armadilhas encontradas no caminho {#hazards-found-on-the-way}

### Um segundo zurg na conta do TorBox apaga downloads saudáveis {#a-second-zurg-on-the-torbox-account-deletes-healthy-downloads}

Outra instância do zurg foi carregada com a mesma conta do TorBox. Sua configuração diz:

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

**Cinco** torrents de sondagem foram apagados enquanto baixavam normalmente. Isso foi **observado** nos dois lados. O harness viu cada torrent sumir, e o journal da outra instância diz o motivo.

```
Aug 30 12:43:26 zurg-host zurg: INFO manager Deleting torrent 86695315 because it encountered an error status: error
Aug 30 12:43:27 zurg-host zurg: DEBUG torbox Deleted TorBox torrent id=86695315
Aug 30 12:44:56 zurg-host zurg: INFO manager Deleting torrent 86695708 because it encountered an error status: error
Aug 30 12:47:41 zurg-host zurg: INFO manager Deleting torrent 86697191 because it encountered an error status: error
```

Os cinco são `86695315` `86695708` `86697191` `86702627` `86704212`. Todos tinham o mesmo motivo. Nenhum deles estava quebrado.

O mecanismo é a segunda regra em `normalizeStatus` em `internal/torbox/types.go`.

```go
if w.DownloadFinished && !w.DownloadPresent {
    return "error"
}
```

Essa combinação é uma fase normal de finalização do TorBox. A captura de 0,5 s mostra isso com números. Numa imagem de 754 MiB, a janela entre `download_finished` ficar verdadeiro e `download_present` ficar verdadeiro foi de **9,6 segundos**. Numa imagem de 3,7 GiB foi de pelo menos 17 s, e a varredura caiu dentro dessa janela. A outra instância do zurg consulta a biblioteca a cada 15 s, mais ou menos. Se um download saudável do TorBox sobrevive ao próprio término é quase cara ou coroa.

São três consequências. Um download do TorBox que o usuário vê terminar na interface do TorBox pode sumir da biblioteca dele no zurg. `delete_error_torrents` está documentado como apagando torrents que o provedor diz estarem com erro, e aqui ele apagou os que o provedor diz estarem bem. E qualquer medição do TorBox nessa conta está correndo contra essa varredura.

**Não corrigido aqui.** A Fase 0 apenas mede. A correção fica com o trabalho das etapas. Lá, `download_finished && !download_present` passa a virar `finalizing` em vez de `failed`.

### Um segundo zurg na conta do AllDebrid escapou ileso {#a-second-zurg-on-the-alldebrid-account-got-away-with-it}

A chave do AllDebrid usada nesta campanha também foi carregada por outra instância do zurg, com as mesmas três configurações de varredura da chave do TorBox.

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

Nenhuma sonda do AllDebrid foi apagada. O motivo está no código e não é sorte. `normalizeStatus` em `internal/alldebrid/types.go` mapeia para `error` apenas os códigos de status iguais ou maiores que 5 e não tem nenhuma regra estrutural do tipo `download_finished && !download_present`. Assim, um download saudável do AllDebrid nunca pode ser lido como quebrado. O bug do TorBox é só essa regra extra, e não a varredura em geral.

O Real-Debrid é o caso à parte. Nenhum outro zurg foi carregado com a conta de teste. Nada estava varrendo a conta e nada interferiu.

### O TorBox responde a um delete de id desconhecido com HTTP 500 {#torbox-answers-a-delete-for-an-unknown-id-with-http-500}

```
POST /v1/api/torrents/controltorrent  {"torrent_id":86695315,"operation":"delete"}
-> HTTP 500 {"success":false,"error":"DATABASE_ERROR","detail":"There was an error processing your request. Please try again later."}
```

`GET /torrents/mylist?id=<gone>` responde do mesmo jeito. Então um torrent que não existe mais é indistinguível de uma queda da TorBox só pelo status code. O zurg reporta isso como `account temporarily unavailable`. O journal da outra instância mostra ela tentando deletar de novo um id já deletado a cada 15 s. O harness contorna isso pedindo `mylist` depois de um delete que falhou e tratando um torrent que sumiu como deletado.

### A limitação de taxa do Real-Debrid não apareceu {#real-debrid-throttling-did-not-appear}

Nove adições com intervalo de 20 s geraram zero 451s e zero 429s em toda a campanha. Isso bate com a nota no `CLAUDE.md` da raiz, que diz que 6 adições com 10 s de intervalo deram 0/6 e as mesmas 6 com 20 s deram 6/6. O piso de 20 s faz diferença de verdade e não é superstição.

---

## Como rodar a campanha de novo {#re-running-the-campaign}

```bash
export RD_TOKEN=…   # a Real-Debrid test account
export AD_KEY=…     # AllDebrid test
export TB_KEY=…     # TorBox

# 1. check the catalog still resolves and the swarms are still what the tables claim
./scripts/torrent_lifecycle_probe.py --inspect-torrents

# 2. non-destructive. Confirms the cached/uncached split before anything is added
./scripts/torrent_lifecycle_probe.py --cache-probe

# 3. record what each account holds now, so step 6 has something to compare against
./scripts/torrent_lifecycle_probe.py --list

# 4. the campaign. One process per provider, each with its own output directory
for p in rd ad tb; do
  LIFECYCLE_OUTDIR=~/lifecycle/$p ./scripts/torrent_lifecycle_probe.py \
    --provider $p --case all --cap-mins 15 > ~/lifecycle/$p.out 2>&1 &
done

# 5. the two follow-ups the campaign cannot do
./scripts/torrent_lifecycle_probe.py --provider rd --case cached --rd-select-detail
./scripts/torrent_lifecycle_probe.py --provider tb --case adhoc --fast-poll 0.5 --fast-window 480 \
  --extra-hash 58846860f0a766f8a42b0bb214d8c713fdf1b167:debian-netinst

# 6. verify nothing was left behind
./scripts/torrent_lifecycle_probe.py --cleanup-only
./scripts/torrent_lifecycle_probe.py --list
```

Execute isso a partir de uma máquina com egress residencial. A AllDebrid responde `NO_SERVER` para IPs de datacenter.

O passo 6 não é opcional, e o passo 3 é o que lhe dá sentido. Depois da campanha de 2026-08-30, nenhum dos 34 IDs de instância que o harness tinha reivindicado sobrou em nenhuma das três contas. Também nenhum dos nove hashes de sonda.

Antes de mexer na TorBox, verifique se algum outro zurg está carregado com a mesma conta, leia as configurações de varredura dele e espere a varredura descrita acima.

```bash
grep -E "delete_error_torrents|stalled_download_mins|enable_repair" config.yml
```

Nunca altere isso. Uma sonda que desaparece no meio da execução é um dado.
