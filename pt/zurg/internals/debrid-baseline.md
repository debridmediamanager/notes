# A base de referência do debrid {#the-debrid-baseline}

O que o zurg custa e a rapidez com que ele responde no caminho **debrid**, com Real-Debrid, AllDebrid
e TorBox. Aqui não existe concorrente. O concorrente é um zurg mais novo, e este arquivo
é o que ele precisa superar.

- **Build testado:** `23869fa4` (`2026.08.18.0140-nightly-48-g23869fa4`)
- **Medido em:** 2026-08-19, na `zen` (2 núcleos, 7,6 GB, Ubuntu 22.04)
- **Ambiente:** `scripts/dbench/`, instalado em `~/dbench` na zen

## Como ler {#how-to-read-it}

Três provedores também não são três concorrentes. Suas bibliotecas diferem em duas ordens de grandeza — 3416 torrents no Real-Debrid, 479 no TorBox, 14 no AllDebrid — então um tempo de build a frio absoluto diz mais sobre a conta do que sobre o zurg. Por isso, todo número que depende do tamanho também é dado por torrent, e a comparação que realmente importa é sempre **este build contra o próximo na mesma conta**.

O que é realmente comparável entre provedores é o *formato* do custo: quantas chamadas de API um backend precisa por torrent, se ele paga pela verificação de links, e se a sua consulta de mudanças é uma página ou um token.

## Configuração {#configuration}

Cada instância roda um provedor, em sua própria porta, com seu próprio diretório de dados. As
mudanças em relação aos padrões de fábrica são apenas as que o isolamento exige:

| Configuração | Bench | Motivo |
|---|---|---|
| `host` / `port` | `127.0.0.1`, 9991-9994 | quatro instâncias no mesmo host |
| `providers` | um por instância | atribuir o custo a um backend |
| `rclone_enabled` | `false` | medido via HTTP, nunca pelo FUSE |
| `directories` | um `all`, sem filtros | o custo de listagem passa a depender do tamanho da biblioteca |
| `enable_repair` | `false` | Outro zurg foi carregado com a mesma conta do TorBox, e só uma instância pode reparar uma conta |

Todo o resto fica no padrão de fábrica *de propósito*, incluindo dois que afetam bastante os
números e que são, por si só, descobertas:

- `log_level: DEBUG` — o padrão de fábrica (`pkg/logutil/factory.go`).
- `torrents_rate_limit_per_minute: 75` — o padrão de fábrica, e a restrição que limita um build frio do Real-Debrid.

## Corpus

Doze releases, os **mesmos infohashes nas três contas**, então uma diferença entre provedores é do provedor e não do arquivo. Os tamanhos vão de um episódio de 1.5 GB até um pacote remux de 334 GB. Os formatos incluem filmes com um único arquivo, packs de temporada e um pack de série com 349 arquivos. A entrada 0, `The Shawshank Redemption (1994) DS4K`, de 7.31 GB e com um arquivo só, é o item de streaming usado nas fases de latência e throughput.

Montar isso foi a parte complicada e vale registrar. O cache do TorBox se sobrepõe à biblioteca do Real-Debrid em cerca de 2% (3 acertos em 136 consultas), então o corpus precisa ser conduzido pelo lado do TorBox e não pelo do Real-Debrid. O AllDebrid não tinha nada em cache, mas aceitou os magnets na hora: 14 de 16. O Real-Debrid precisou de 20 a 45 s entre as adições por causa do limite 451, e recusou dois. Um foi o bloqueio determinístico por nome documentado (`Supergirl…WEB-DL…`), recusado já na primeira tentativa limpa, depois de um período de três minutos sem atividade. O outro ficou preso no limite.

## Medindo o custo da API {#measuring-api-cost}

zurg não mantém nenhum contador de requisições de saída, e o `log_requests` pula deliberadamente dois endpoints do Real-Debrid — `torrents/activeCount` e `torrents?limit=1&…` — que juntos são todo o polling de detecção de mudanças. Contar a partir do log, portanto, mostraria o custo ocioso do Real-Debrid como zero.

Por isso a contagem é feita fora do processo. O mitmproxy encerra o TLS, um addon grava uma linha JSONL por requisição, e a instância é iniciada com `HTTPS_PROXY` e `SSL_CERT_FILE` apontando para a CA interceptadora. O loader de x509 do Go respeita `SSL_CERT_FILE`, então a confiança fica restrita a esse único processo e nada no host é modificado. As requisições são classificadas como `api`, `nettest`, `content` ou `other`.

O proxy fica no caminho da requisição, então ele é usado só nas fases de custo de API; as fases de tempo rodam direto. No TorBox — onde o build inteiro são quatro chamadas — uma execução com proxy e uma execução direta ficaram em 3,0 s e 4,0 s, então nessa escala o proxy está dentro do ruído.

## Resultados {#results}

All numbers from build `23869fa4` on zen, 2026-08-19. Latency and throughput come
from one interleaved run over the same 7.31 GB file — same infohash on all three
accounts, and `ffprobe` reports the identical 8552.574 s duration through each, so
the content really is byte-identical.

### Construção da biblioteca a frio {#cold-library-build}

Esvaziar caches para uma biblioteca compilada. Este é o único número que não é comparável
entre provedores — as contas diferem em duas ordens de grandeza — então leia as colunas por torrent.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Torrents | 3,316 | 14 | 479 |
| Tempo até compilado | **1,774 s** | 1.0 s | 3.0 s |
| Segundos por torrent | 0.535 | 0.071 | 0.006 |
| Requisições à API | **7,442** | 7 | 4 |
| Requisições à API por torrent | **2.24** | 0.50 | 0.008 |
| Respostas não-2xx | **756 (10.2%)** | 0 | 0 |
| Bytes recebidos da API | 2.87 MB | 27.9 KB | 298 KB |
| Requisições de teste de rede na inicialização | 88 | 88 | 88 |
| RSS máximo | 77 MB | 26 MB | 52 MB |
| Segundos de CPU | 17.5 | 0.04 | 0.5 |

As 7,442 chamadas do Real-Debrid se dividem em 3,414 `torrents/info` — uma por torrent,
inevitável sem `ListIncludesFiles` — e **3,992 `unrestrict/link`**, que é
a verificação proativa de links. É o único backend com `StoredLinksCanRot: true`,
então é o único que paga por isso. O TorBox responde a toda a varredura com um único
`mylist`, que é o que `ListIncludesFiles` oferece.

A build do Real-Debrid foi executada duas vezes, e as duas concordam o suficiente para que
uma futura melhoria da build não seja ruído:

| | execução 1 | execução 2 |
|---|---|---|
| Tempo até compilado | 1,774.5 s | 1,759.5 s |
| Requisições à API | 7,442 | 7,391 |
| `unrestrict/link` | 3,992 | 3,933 |
| Não-2xx | 756 | 699 |
| Segundos de CPU | 17.5 | 16.1 |

#### Quais são as falhas {#what-the-failures-are}

O segundo run manteve o log de fluxo, então os 699 têm esta divisão:

| Status | Contagem | Endpoint |
|---|---|---|
| 429 | 589 | `unrestrict/link` |
| 503 | 85 | `unrestrict/link` |
| 404 | **22** | `downloads/delete/{id}` |
| 451 | 3 | `unrestrict/link` |

São dois problemas separados, e nenhum deles é "o provedor estava instável":

- **589 rejeições por rate limit**, todas em `unrestrict/link`. `api_rate_limit_per_minute` vem com 250 por padrão e não mantém o unrestrict dentro do que o Real-Debrid realmente permite. Então cerca de 8% do build a frio são recusas e novas tentativas.
- **22 de 23 chamadas a `downloads/delete` retornaram 404.** A limpeza que deveria equilibrar os 3.992 unrestricts não é só rara, ela falha quando roda: está apagando ids que não existem. Cada unrestrict cria uma entrada persistente na lista de downloads da conta, e depois desses scans a conta de teste chegou a **12.469**.

Um número mudou entre os runs e ainda não está explicado: as probes HEAD para `*.download.real-debrid.com` foram 88 no primeiro build e **3.426** no segundo (cerca de uma por torrent). Ele acompanha o crescimento da lista de downloads, e o segundo run também buscou `/downloads` oito vezes, contra uma vez no primeiro. Mas isso é uma correlação, não uma causa. Vale descobrir a causa antes de otimizar.

### Reinicialização a quente {#warm-restart}

O custo inicial é realmente único.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Tempo até compilar | 4.0 s | 1.0 s | 2.0 s |
| Requisições de API | 17 | 6 | 4 |
| Requisições de teste de rede | 8 | 0 | 0 |
| Pico de RSS | 77 MB | 27 MB | 39 MB |

1,774 s passa a ser 4.0 s, e 7,442 chamadas passam a ser 17.

### Estado ocioso estável {#idle-steady-state}

Dez minutos de uma biblioteca carregada sem fazer nada. A ordem é definida pelo que cada backend consegue responder de forma barata, e é a melhor ilustração do motivo de `LibraryFingerprinter` existir.

| | Chamadas de API/min | Bytes de API/min | CPU s / 10 min | Peak RSS | O que envia |
|---|---|---|---|---|---|
| AllDebrid | **4.0** | **867** | 0.20 | 28 MB | um delta do Live Mode por consulta, vazio quando nada muda |
| TorBox | 7.9 | 43.6 KB | 0.33 | 53 MB | lista `mylist` paginada, sem feed de delta e sem validadores de cache |
| Real-Debrid | 11.4 | 59.8 KB | 0.43 | 85 MB | `torrents?limit=1` + `activeCount`, mais `/downloads` |

O Real-Debrid gasta 32 das suas 114 chamadas listando `/downloads` de novo, a mesma lista que o build frio cresceu até 12,469 entradas.

Esta tabela também é o motivo de a contagem ser feita por um proxy, e não pelo `log_requests`: 80 das 114 chamadas em repouso do Real-Debrid vão para os dois endpoints que `ShouldSkipLogging` suprime, então o log mostraria o custo em repouso dele como praticamente zero.

### Listagem {#listing}

Nenhum gargalo em lugar nenhum, em qualquer tamanho de biblioteca.

| | Real-Debrid (3.312) | AllDebrid (14) | TorBox (479) |
|---|---|---|---|
| PROPFIND biblioteca inteira, Depth 1 | 26 ms / 1,17 MB | 1 ms / 5,1 KB | 7 ms / 172 KB |
| Índice HTML | 14 ms / 645 KB | 1 ms / 2,4 KB | 3 ms / 90 KB |
| PROPFIND um release, Depth 1 | 1 ms | 11 ms | 3 ms |

### Dê play {#press-play}

Um arquivo de 7.31 GB, cada leitura feita em uma instância recém-iniciada.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Abertura a frio, 1 MB | 1.294 s | **0.476 s** | 0.565 s |
| Tempo até o primeiro byte, 64 MB | **0.158 s** | 0.203 s | 0.208 s |
| Scrub, mediana de 8 | 0.343 s | **0.259 s** | 0.356 s |
| Releitura a quente, 64 MB | 2.065 s | 2.163 s | **1.960 s** |
| ffprobe | 1.98 s | 1.34 s | **0.99 s** |
| RSS | 75 MB | **30 MB** | 50 MB |

**A releitura a quente é igual à leitura a frio.** No caminho do Usenet, uma releitura
volta em 0.05-0.17 s do LRU de 512 MB; aqui ela custa uma busca completa, porque o
caminho do debrid faz proxy do CDN e não guarda nada em cache. Com `rclone_enabled: false`,
isso é só o zurg sozinho: em uma instalação normal, o cache do VFS do rclone absorve esse
custo, mas, como propriedade do próprio zurg, não existe caminho quente nenhum.

### Throughput

256 MB de leituras sequenciais, três repetições, com a ordem alternando entre as repetições.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Média MB/s | 25.75 | 27.21 | **35.96** |
| Mín-máx MB/s | 20.09-29.57 | 17.52-32.21 | **34.31-37.57** |
| CPU s por GB | 7.8 | **5.3** | 7.9 |
| TTFB mediana | 1.023 s | **0.267 s** | 0.489 s |
| Pico de RSS | 88 MB | **29 MB** | 55 MB |
| Leituras concluídas | 3/3 | 3/3 | 3/3 |

O TorBox é ao mesmo tempo o mais rápido e bem o mais estável; os outros dois oscilam cerca de 40% entre as repetições. O TTFB mediano do Real-Debrid sob carga é quatro vezes o do AllDebrid.

### Para onde vai de fato a abertura a frio {#where-cold-open-actually-goes}

`apiref.py` mede a parte do próprio provedor — a chamada que transforma um arquivo armazenado em uma URL acessível, e o primeiro byte dessa URL — com o zurg fora do caminho. Ele foi executado duas vezes; a primeira execução é anterior à correção do AllDebrid, então essa linha tem só uma amostra.

| | resolve | CDN TTFB | total do provedor | zurg cold open | parcela do zurg |
|---|---|---|---|---|---|
| Real-Debrid, execução 1 | 0.133 s | 0.267 s | 0.400 s | 1.294 s | **0.89 s** |
| Real-Debrid, execução 2 | 0.157 s | 0.383 s | 0.540 s | 1.294 s | **0.75 s** |
| AllDebrid | 0.139 s | 0.333 s | 0.472 s | 0.476 s | 0.00 s |
| TorBox, execução 1 | 0.260 s | 0.277 s | 0.537 s | 0.565 s | 0.03 s |
| TorBox, execução 2 | 0.270 s | 0.381 s | 0.651 s | 0.565 s | ~0 |

Os números do provedor e os do zurg vêm de momentos diferentes, então a subtração é indicativa, não exata. O padrão se mantém nas duas execuções: AllDebrid e TorBox não acrescentam praticamente nada além do que o próprio provedor já custa, enquanto o Real-Debrid acrescenta de 0.75 a 0.89 s. Essa diferença é o ponto mais claro para atacar.

### Os três provedores em uma instância {#all-three-providers-in-one-instance}

A instância mesclada carrega todas as contas de uma vez, e o corpus está de propósito nas três, então ela testa o caminho em que um mesmo release está em várias contas.

| | Só Real-Debrid | As três mescladas |
|---|---|---|
| Torrents vistos | 3,316 | 3,781 |
| Releases únicos | 3,318 | 3,778 |
| Tempo até compilar | 1,774 s | 1,775 s |
| Requisições de API | 7,442 | 7,491 |
| Pico de RSS | 77 MB | 82 MB |
| PROPFIND da biblioteca inteira | 26 ms / 1.17 MB | 23 ms / 1.34 MB |

Adicionar TorBox e AllDebrid a uma instância do Real-Debrid quase não custa nada: são 465 torrents a mais, com 49 chamadas de API a mais e 5 MB de RSS a mais, e nenhum tempo mensurável. A mesclagem é real: os 3.809 torrents das três contas, separadas, viram 3.781 aqui, e o corpus passa de três cópias para uma só.

### Detecção de adição e exclusão {#add-and-delete-detection}

Quanto tempo leva desde uma mudança no provedor até o mount ficar igual.

| | Exclusão detectada | Adição detectada |
|---|---|---|
| Real-Debrid | 18.7 s | 12.7 s |
| AllDebrid | 16.5 s | 14.4 s |

Os dois ficam dentro de um ciclo de `check_for_changes_every_secs` mais um refresh, então nenhum dos dois espera por `library_resync_every_mins`. O TorBox não foi testado: o release de teste fica permanentemente nessa conta, e apagá-lo não tem como ser desfeito sem adicioná-lo de novo, o que pode não estar em cache.

### Queda do provedor, CDN no ar {#provider-outage-cdn-up}

`ca/outage.py` faz toda chamada à API do provedor retornar 503 enquanto as requisições de conteúdo passam, e só então o zurg é iniciado nesse cenário.

| | Leitura antes | Biblioteca compilada durante a queda | Leitura durante a queda |
|---|---|---|---|
| Real-Debrid | 206, 1.60 s | nunca (180 s) | timeout em 120 s |
| AllDebrid | 206, 0.44 s | nunca (180 s) | timeout em 120 s |
| TorBox | 206, 1.53 s | nunca (180 s) | 400 em 0.035 s |

**Iniciar o zurg enquanto o provedor está fora produz um mount vazio.** Esse é o cenário que mais importa na prática: um host reinicia durante uma fase de 503 do Real-Debrid. Foi exatamente essa condição que destruiu dezenas de milhares de itens no Plex no `fun` em agosto, quando um mount momentaneamente vazio durante um scan foi interpretado como "todos os arquivos foram apagados". A proteção contra isso está no Plex (`autoEmptyTrash 0`), não no zurg.

Real-Debrid e AllDebrid ainda fazem o leitor esperar até estourar o próprio timeout, em vez de falhar logo. Já o TorBox responde em 35 ms.

### Um 503 transitório deixa releases como pastas vazias {#a-transient-503-leaves-releases-as-empty-folders}

The clearest defect of the run, and it was found by accident.

Dos 3.316 torrents de um cold build no Real-Debrid, **85 respostas vieram como 503** e
**84 torrents acabaram em `broken_torrent`**. Um release nesse estado continua listado
no mount, mas a pasta dele fica **vazia**. Isso foi verificado com PROPFIND em dois deles, que tinham 10 e 3 arquivos selecionados no registro salvo e não serviam nenhum.

Ele não se resolve sozinho. O benchmark roda com `enable_repair: false`, e esses releases continuaram quebrados por mais de uma hora e vários restarts depois.

Ligar o repair, que é o padrão da versão lançada, funciona e vai resolvendo os casos, mas devagar. Com um pass disparado manualmente:

| Tempo decorrido | Quebrados | Em reparo |
|---|---|---|
| 0 min | 85 | 0 |
| ~2 min | 77 | 2 |
| ~15 min | 73 | 4 |

Doze releases em um quarto de hora, e a taxa cai depois dos primeiros minutos. Nesse ritmo, o volume de quebras de um cold build inteiro leva mais de uma hora para ser limpo, e cada release que ainda não foi alcançado fica como pasta vazia durante todo esse tempo.

Então a gravidade depende de uma configuração:

- Com o repair ligado (padrão), um 503 durante um scan custa a um release os arquivos dele até um pass de reparo chegar até ele. São cerca de uma hora para uma biblioteca completa.
- Com o repair desligado, o release fica como pasta vazia por tempo indeterminado.

A TorBox tem a versão mais grave disso. Ela reporta `StoredLinksCanRot: false`, então o refresh nunca rechecka os links dela. Não existe caminho que limpe um estado quebrado sem passar pelo reparo. O único release da TorBox marcado como quebrado durante o teste de queda continuou quebrado por 68 minutos e vários restarts depois, enquanto o provedor o reportava como `cached`, `download_present`, com um arquivo, 7,31 GB.

### Integridade de leitura {#read-integrity}

Uma leitura no AllDebrid, no primeiro teste de throughput, devolveu 263.798.425 bytes para um range de 268.435.456 bytes, com um 206 e sem erro. **Não se repetiu**: oito repetições em cada um dos casos, Real-Debrid e AllDebrid, devolveram o range completo todas as vezes. Foi registrado como um caso isolado, não como um defeito, mas vale ficar de olho.

## Sob a carga do Plex {#under-plexs-load}

Tudo que vimos até agora é de um leitor por vez, o que não é como um servidor de mídia se comporta. O Plex faz varreduras — milhares de arquivos, um pouquinho de cada — e também faz streaming, e as duas coisas se sobrepõem. Estas fases medem o mount sob os dois cenários.

**Leia os números agregados como uma propriedade do zen, não do zurg.** Todos os alvos estabilizam em 73-78 MB/s, seja qual for o provedor e seja qual for o modo, o que corresponde ao link do host. O que pode ser generalizado são as *taxas de conclusão* e os formatos de falha de cada provedor; o teto é local.

### Vários leitores, arquivos diferentes, um provedor {#multiple-readers-different-files-one-provider}

96 MB por stream, arquivos distintos.

| streams | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 1 | 44.8 | 52.1 | 45.6 | 51.8 |
| 2 | 72.3 | 63.5 | 71.4 | 69.8 |
| 4 | 73.7 | 64.2 | 74.6 | 70.2 |
| 8 | 73.6 | 73.4 | 65.5 | 75.1 |
| 12 | 77.1 | 73.8 | 76.3 | 77.1 |

MB/s agregado. O pipe fica cheio com dois streams; depois disso, mais leitores dividem a mesma banda. A mediana por stream cai de ~45 MB/s com um para ~8 MB/s com doze.

A coluna de conclusão é a mais interessante:

| streams | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 4 | 4/4 | **2/4** | 4/4 | 4/4 |
| 8 | 8/8 | **3/8** | 8/8 | 8/8 |
| 12 | 10/12 | **4/12** | 9/12 | 10/12 |

**O AllDebrid para de concluir leituras de quatro arquivos distintos simultâneos.** Os bytes continuam fluindo — o agregado fica no teto do host — mas os streams individuais não terminam, e a mediana por stream cai para zero com oito e doze, com medianas de TTFB acima de 3 s. Todo o resto aguenta até doze, onde todos perdem um ou dois.

> **Retratado em 2026-08-23. Isso não é um limite de concorrência do provedor.** Testado de novo direto nas APIs, com bitrates de reprodução limitados, em vez de a todo vapor pelo zurg, o AllDebrid resolveu **4/8/12/16/24 links distintos simultâneos com 100%** e sustentou **24/24** streams ao vivo. As falhas acima foram causadas por **três hosts de CDN do AllDebrid com rota nula** — `l4m5n6.debrid.it`, `o7p8q9.debrid.it`, `c1uw74.debrid.it`, todos resolvendo para `0.0.0.0` e respondendo por **15,6% dos links resolvidos**. O primeiro é o mesmo host registrado como link morto pontual mais abaixo neste documento; não é um caso isolado.
>
> Um host morto só falha quando o arquivo dele está no lote, então a contagem de falhas sobe com N e tem exatamente o formato de um teto de concorrência. **Qualquer escada que sorteie mais arquivos distintos conforme sobe vai reproduzir esse falso resultado.**
>
> A coluna inteira de conclusão está limitada pelo método pelo mesmo motivo: essas execuções puxaram a todo vapor por um link saturado de 73–78 MB/s, então o que ela mede é **divisão de banda, não limite do provedor**. Os tetos reais por host, todos não documentados, são: Real-Debrid **32** (derrubado na camada TCP), AllDebrid **32** (HTTP 429), TorBox **20** por host `nexus-NNN` (HTTP 429, por host e não por IP), e nenhum teto encontrado para Premiumize em 64.
>
> Uma ressalva contra interpretar demais a retratação: um host com rota nula falha em ~0,1 s, enquanto as medianas de TTFB acima passam de 3 s. É uma falha lenta com outra assinatura, então provavelmente também houve falta de banda. Os dois efeitos apontam para longe de um limite do provedor.
>
> **A correção que isso implica:** trate uma falha em nível de conexão em um host de CDN do AllDebrid como algo que pode ser repetido **refazendo o unlock do link** — um novo `/link/unlock` retorna um host diferente — e não reduzindo a concorrência. Uma consulta DNS que rejeite `0.0.0.0` pega todos os casos vistos aqui e não custa nada.

### Vários leitores, um arquivo {#multiple-readers-one-file}

Mesmo nível, um arquivo só, offsets diferentes: o formato de leitura antecipada mais seek.

| streams | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| 4 | 4/4 | 4/4 | 4/4 |
| 8 | 8/8 | 8/8 | 8/8 |
| 12 | 10/12 | 9/12 | 10/12 |

O AllDebrid está **bem** aqui, com 4/4 e 8/8, enquanto estava com 2/4 e 3/8 em arquivos diferentes.
Essa inversão é o diagnóstico: o limite dele não é banda nem um teto por torrent,
é a **resolução de links** concorrente. Arquivos diferentes significam desbloqueios diferentes; um arquivo só resolve uma vez e depois é só streaming.

> **Retratado em 2026-08-23**: a inversão tem uma explicação mais simples. Arquivos diferentes caíam em hosts de CDN diferentes, e três dos hosts do AllDebrid estavam com rota nula; um arquivo só resolve para um host e ou funciona ou não funciona. A própria resolução de links foi medida e estava limpa com 24 concorrentes. Veja a nota acima.

### Vários leitores em provedores diferentes {#multiple-readers-across-different-providers}

Este é o caso de provedores misturados, e ele precisa de um corpus que o corpus pareado não consegue fornecer. Como a instância mesclada serve um release de múltiplas contas a partir de `Sources[0]`, todas as leituras do corpus pareado caem no Real-Debrid. Então o pool aqui é *exclusivo* por provedor: 8 arquivos que só o Real-Debrid tem, 7 só o AllDebrid, 8 só o TorBox.

| streams (por provedor) | MB/s agregado | concluídos | RD | AD | TB |
|---|---|---|---|---|---|
| 3 (1 cada) | 55.3 | 2/3 | 28.8 | — | 27.9 |
| 6 (2 cada) | 66.9 | 5/6 | 16.1 | 13.3 | 21.5 |
| 12 (4 cada) | 75.9 | 11/12 | 7.4 | 8.4 | 9.0 |

As colunas por provedor são medianas por stream em MB/s.

Leituras em contas diferentes realmente rodam em paralelo, mas chegam ao mesmo teto de 76 MB/s do host que um único provedor já atinge sozinho. **Neste host, misturar backends não traz mais largura de banda.** Se isso traz algum ganho em outro lugar depende de ter um link mais largo do que um provedor consegue preencher, o que o zen não tem. O que ele traz em vez disso é disponibilidade — e só em parte, como mostra a seção de failover abaixo.

A única falha consistente é um arquivo do AllDebrid cujo hostname do CDN, `l4m5n6.debrid.it`, resolve para **0.0.0.0**. Isso é o AllDebrid entregando um link morto, não o zurg — mas o zurg gasta cerca de 4 s em três tentativas antes de retornar 500, e como o arquivo não está em nenhuma outra conta, não há para onde recorrer.

### Failover: só em uma direção {#failover-only-from-one-direction}

Como a instância unificada não consegue distribuir a carga, o que ela deveria garantir é a sobrevivência de uma conta com problema. `ca/cdnfail.py` derruba o CDN de uma conta e deixa todas as APIs e as outras contas intactas, então a biblioteca continua carregando e só os bytes são afetados. Os releases lidos fazem parte do corpus pareado: as três contas têm todos eles.

| CDN derrubado | leituras atendidas | o que a leitura fez |
|---|---|---|
| Real-Debrid | 2/2 | recorreu ao AllDebrid, 0,6 s |
| AllDebrid | **0/3** | uma tentativa no AllDebrid, 503, e depois **500 para o cliente em 0,1 s** |

**O failover só acontece quando a conta com falha é a Real-Debrid**, e o motivo é uma capacidade que os outros backends não ativam. O refresh só verifica os links proativamente quando `StoredLinksCanRot` é verdadeiro, o que vale apenas para a Real-Debrid:

```
Link verification failed during refresh for /A.Business.Proposal…: (code: 503)
```

É isso que rebaixa a fonte, e depois as leituras passam para outra conta sem problemas. AllDebrid e TorBox nunca são verificados, então um CDN morto em qualquer um dos dois nunca é percebido, a fonte nunca é rebaixada, e toda leitura desse release retorna 500 enquanto a condição durar.

Duas outras coisas que isso mostra:

- **O caminho de leitura não tem fallback inline nenhum.** Um 503 do CDN da conta escolhida vira um 500 para o cliente em 0,1 s, e as outras contas que têm o mesmo arquivo não são tentadas. A recuperação fica inteiramente por conta do refresh em segundo plano, então mesmo no caso da Real-Debrid existe uma janela em que as leituras falham.
- É o mesmo mecanismo ausente por trás do release do TorBox que ficou em `broken_torrent` por 68 minutos. Nada reverifica um link do TorBox ou do AllDebrid, então nada limpa um estado ruim nem percebe quando a conta se recupera.

### Um link morto do provedor {#a-dead-link-from-the-provider}

Um arquivo do AllDebrid no pool exclusivo falhou todas as vezes em que foi acessado, tanto nas execuções de scan quanto nas do mixed-reader. O hostname do CDN dele resolve para uma rota nula:

```
$ getent hosts l4m5n6.debrid.it
::              l4m5n6.debrid.it
0.0.0.0
```

O AllDebrid entregou um link apontando para `0.0.0.0`. Essa parte é culpa do provedor, não do zurg. O que cabe ao zurg é o que ele faz com isso: três tentativas em cerca de 4 s e depois um erro 500. O arquivo não está em nenhuma outra conta, então não havia para onde recorrer. Mas o resultado do failover acima mostra que ele também não faria fallback nesse caso.

> **2026-08-23: não é um host, nem um arquivo só.** Três hostnames de CDN do AllDebrid estavam com rota nula ao mesmo tempo: `l4m5n6.debrid.it`, `o7p8q9.debrid.it`, `c1uw74.debrid.it`. Eles respondiam por **5 de 32 links em uma amostra e 4 de 32 em outra, com conteúdos sem relação entre si**. O AllDebrid continua entregando esses mesmos hosts mortos para arquivos diferentes, e ainda fazia isso dias depois desta execução. É um buraco persistente na frota dele, e foi ele que gerou a descoberta de concorrência retirada mencionada acima.
>
> Três tentativas e um 500 é a resposta errada. **Desbloqueie de novo em vez disso**: o `/link/unlock` devolve um host diferente. E faça uma verificação prévia com uma consulta DNS que rejeite `0.0.0.0`, que pega todos os casos observados sem custo nenhum.

### Escaneamento {#scanning}

`ffprobe` sobre todo o pool misto de 23 arquivos, que é o formato de uma análise do Plex.

| concurrency | files/min | per-file median | per-file max | CPU s |
|---|---|---|---|---|
| 1 | 43.7 | 1.16 s | 3.11 s | 2.22 |
| 4 | 112.0 | 1.67 s | 4.19 s | 1.29 |
| 8 | 142.3 | 1.87 s | 6.67 s | 1.16 |

A varredura paraleliza bem: 3,3x de uma thread para oito, com a latência por arquivo subindo só 60%. Para a biblioteca do Real-Debrid com 3.316 releases, isso dá cerca de **76 minutos com uma thread e 23 minutos com oito**, sem contar o trabalho próprio do Plex.

### Streaming durante o escaneamento {#streaming-while-scanning}

A caso que mais preocupa, já que uma varredura contra um mount momentaneamente instável foi o que custou dezenas de milhares de itens no Plex em `fun`.

| scan concurrency | stream alone | stream during scan | kept | scan wall |
|---|---|---|---|---|
| 4 | 57.7 MB/s | 66.5 MB/s | 115% | 11.8 s |
| 8 | 67.8 MB/s | 66.8 MB/s | 98.5% | 9.7 s |

**Uma varredura não deixa o stream sem recursos.** O usuário que está assistindo mantém praticamente toda a sua velocidade, e o tempo até o primeiro byte até melhora (de 1.18 s para 0.15 s), porque a conexão já está aquecida nessa altura. Este é o único ponto em que o caminho do debrid se comporta melhor do que o temido.

## Defeitos que esta execução revelou {#defects-this-run-surfaced}

1. **Um 503 transitório deixa um release como pasta vazia.** 85 x 503 durante um build a frio fizeram 84 releases irem para `broken_torrent`, e um release quebrado aparece na lista sem arquivos dentro. Com o repair desligado, ele nunca se limpa; com o repair ligado, ele só se limpa quando uma passagem chega até ele. No TorBox não existe nenhum caminho de re-verificação (`StoredLinksCanRot: false`), e o único release quebrado ali continuava quebrado 68 minutos depois, mesmo com o provedor informando que ele estava em cache e disponível.
2. **A limpeza das entradas de download está quebrada, e o custo se acumula.** 3.992 chamadas a `unrestrict/link` contra 23 chamadas a `downloads/delete`, e **22 dessas 23 retornaram 404**: a limpeza apaga ids que não existem. A conta passou de 12.469 entradas para **18.768** em mais dois builds a frio, e o zurg pagina a lista inteira na inicialização de 5.000 em 5.000, então o vazamento vira um custo de inicialização que cresce junto com ele.
3. **589 rejeições por rate limit em um único build a frio.** Todas em `unrestrict/link`, cerca de 8% da passagem. O padrão `api_rate_limit_per_minute: 250` não mantém o unrestrict dentro do limite real do Real-Debrid. Essas rejeições e os 503s são o mesmo evento que produz o defeito 1.
4. **Iniciar durante uma queda de provedor deixa a montagem vazia**, e uma leitura no Real-Debrid ou no AllDebrid fica travada até o timeout do próprio cliente, em vez de falhar rápido. O TorBox responde 400 em 35 ms.
5. ~~**O AllDebrid para de completar leituras simultâneas de arquivos diferentes.**~~ **Retirado em 2026-08-23. Veja a nota em "Vários leitores, arquivos diferentes" acima.** A causa eram três hosts de CDN do AllDebrid com rota nula, que concentravam 15,6% dos links, e não um limite de concorrência; testado de novo diretamente, o AD resolve 24 links distintos simultâneos com 100% de sucesso e sustenta 24/24 streams.

   2 de 4, 3 de 8, 4 de 12. Os mesmos níveis com um único arquivo funcionam (4/4, 8/8), então o limite está na resolução simultânea de links, não na banda nem em um teto por torrent. Quatro arquivos tocando ao mesmo tempo é uma noite comum para uma família.
6. **Um release com várias contas sempre serve pela mesma conta.** `File.PrimarySource` retorna `Sources[0]`, então a escolha é a conta que apareceu primeiro. Verificado em 7 de 7 releases do corpus servidos pelo Real-Debrid, enquanto o AllDebrid e o TorBox tinham cópias idênticas. Ele nunca escolhe a conta mais rápida ou a menos carregada.
7. **O failover funciona em um sentido só e nunca na hora.** Com a CDN do Real-Debrid recusando, as leituras passaram para o AllDebrid; com a do AllDebrid recusando, 0 de 3 leituras foram atendidas e cada uma retornou 500 em 0,1 s sem tentar as duas contas que tinham o mesmo arquivo. Só o Real-Debrid define `StoredLinksCanRot`, então só os links dele são re-verificados durante o refresh, e só as falhas dele rebaixam uma fonte. Nada no caminho de leitura tenta uma segunda conta quando há erro.
8. **O teste de rede da inicialização roda para todos os backends.** 88 requisições HEAD para hosts de download do Real-Debrid numa instância só com TorBox e outra só com AllDebrid, que não têm utilidade para o resultado.
9. **O href do próprio PROPFIND de uma coleção dá 404.** O zurg emite `<d:href>/all/…</d:href>`, sem o prefixo `/dav`; buscar esse caminho retorna 404. Os filhos são emitidos como hrefs relativos simples, então só a entrada do próprio item está errada. A RFC 4918 pede um href que o cliente consiga resolver, e o rclone e o Plex só se viram porque não usam esse campo.
10. **`user`/`user/me` é chamado três vezes em toda inicialização, a frio ou a quente**, tanto no TorBox quanto no AllDebrid.

## Não são defeitos, mas vale saber {#not-defects-but-worth-knowing}

- **O Real-Debrid não deduplica por infohash.** Adicionar um magnet que já está na conta cria uma *segunda* entrada. É por isso que os 3.416 torrents viram 3.318 releases únicos, e isso invalidou a primeira sonda de detecção de exclusão, que apagou a duplicata que tinha acabado de criar e concluiu que nada nunca foi detectado.
- **`torrents_rate_limit_per_minute` vem com o valor padrão 75**, que é o que limita a build fria do Real-Debrid. É um padrão intencional, não um bug, mas é o número que define os 29 minutos.

## Executando de novo {#rerunning}

```bash
cd ~/dbench && ./runall.sh          # p1..p6
./p7.py adddel rd,ad && ./p7.py outage rd,ad,tb
./apiref.py rd,ad,tb                # provider-side reference latency
./report.py                         # tables
```

Nunca rode duas instâncias ao mesmo tempo, e compare números só de uma única execução intercalada — a velocidade do provedor varia bastante ao longo da noite.
