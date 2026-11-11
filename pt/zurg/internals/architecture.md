# Arquitetura {#architecture}

A visão geral de como o zurg funciona: o que ele é, como as peças se encaixam e por que cada pacote existe. Pensada para quem vai mexer no código: aponta as decisões que sustentam a estrutura e os invariantes que são fáceis de quebrar sem perceber.

O detalhe de cada pacote está no `doc.go` de cada um. Este documento fica um nível acima: o formato do conjunto e o raciocínio que leva a esse formato.

## O que é o zurg {#what-zurg-is}

Um daemon em Go que apresenta a biblioteca de torrents de uma conta de debrid como um sistema de arquivos virtual. Ele não armazena nenhuma mídia. Cada leitura vira um GET HTTP com range na CDN do provedor, no momento da requisição.

Ele não tem conteúdo próprio e recusa um PUT, então é somente leitura no sentido que importa para os bytes. Duas escritas são aceitas: um rename, que guarda um nome e não mexe em nenhuma conta ([renaming.md](../guides/renaming.md)), e um DELETE, que remove o release de todas as contas que o têm. `__magic__` adiciona uma terceira escrita dentro do seu namespace: um layout armazenado ([magic.md](../guides/magic.md)). Ela vale em tudo que está dentro dele, exceto em `__magic__/__all__` e nas pastas de release logo abaixo dele, que são o espelho calculado de onde os clientes de download importam.

Quatro visões da mesma biblioteca:

| Endpoint | Para |
|---|---|
| `/dav/` | WebDAV, o que o rclone monta |
| `/http/` | Navegador de diretórios em HTML |
| `/infuse/` | Variante do WebDAV com os detalhes do Infuse tratados |
| `/strm/` | URLs assinadas dentro de arquivos `.strm`, para players que querem uma URL e não um mount |

O rclone faz o mount FUSE de `/dav/`, então Plex, Jellyfin, Emby e Infuse veem uma árvore de diretórios comum.

O grande desafio do projeto é a distância entre o que um sistema de arquivos promete (caminhos estáveis, `stat` instantâneo, bytes sob demanda) e o que uma API de debrid oferece: JSON com rate limit, links que expiram e nenhuma semântica de sistema de arquivos. Quase todo pacote existe para fechar uma parte dessa distância.

```
media player
    │
    ├─ rclone FUSE ──► /dav/  ──┐
    └─ direct HTTP ──► /http/ ──┤
                                ▼
                    internal/handlers  (chi router, auth, routing)
                                │
                internal/dav ───┤─── internal/htmlindex     (listings)
                                │
                                ▼
                    internal/torrent   (the library, in memory)
                                │  resolve link for this file
                                ▼
                    internal/universal (byte path, proxy/redirect, RAR)
                                │
                                ▼
                    internal/debrid    (Provider dispatch)
                                │
        ┌───────────┬───────────┼────────────┬──────────┐
        ▼           ▼           ▼            ▼          ▼
   realdebrid    torbox     alldebrid       nzb ──► nntp ──► par2
        └───────────┴───────────┘            (Usenet, no debrid service)
                    │
              internal/rdclient  (host rotation, rate limit, retry, DNS)
```

## Sequência de inicialização {#boot-sequence}

`cmd/zurg` é uma CLI Cobra simples (serve, version, network-test, clear downloads/torrents, mount control, download requirements). Tudo o que importa acontece em `internal/app.go`, cujo `MainApp` é de propósito uma única função legível:

1. Cria os diretórios de execução (`logs`, `data`, `data/info`, `dump`, `strm`, `nzbs`) e o logger.
2. `ensureConfigAndRequirements` — carrega a configuração e baixa `ffprobe` e `rclone` caso não existam (`internal/requirements`). Na primeira execução, sem configuração, ele grava uma padrão e para, a menos que o token tenha vindo do ambiente.
3. Inicializa o `strmlink` logo no começo, para que um diretório de dados sem permissão de escrita seja reportado agora, e não como arquivos `.strm` que param de resolver depois do próximo reinício.
4. Executa o **teste de latência de rede** nos hosts de download do Real-Debrid (`internal/rdclient`), ou carrega o resultado em cache do disco se ele ainda estiver recente o suficiente. Isso classifica os hosts de CDN e é o que a rotação de hosts usa depois.
5. Cria todos os provedores configurados a partir do registro, monta-os em um `debrid.Set` e guarda uma referência tipada do primeiro Real-Debrid — o dashboard, a página de hosts e o teste de rede ainda falam com o RD especificamente.
6. Constrói o `TorrentManager`, que logo começa a carregar a biblioteca em cache do disco em segundo plano e depois a atualiza.
7. Conecta o roteador chi, inicia o servidor HTTP e depois inicia o rclone assim que o servidor estiver aceitando conexões.
8. Aguarda SIGINT/SIGTERM/SIGQUIT; ao receber o sinal, encerra o servidor HTTP com calma, para o serviço Plex e desmonta o rclone, cada um com um limite de 20 s.

`ZURG_PPROF=1` ativa o pprof em `127.0.0.1:6060` — só loopback, porque fazer profiling de uma instância em execução é o único jeito de descobrir o consumo de CPU durante uma tempestade de scan, mas esse endpoint nunca pode ser acessível pela rede.

## Camada 1 — Configuração {#layer-1--config}

`internal/config` é a única fonte da verdade; quase todos os outros pacotes leem `ZurgConfigV1`. Os getters tipados aplicam valores padrão quando um campo está zerado, então quem chama nunca precisa verificar se o campo existe.

A parte mais importante é o `filters.go`: uma linguagem de filtros aninhados com AND/OR que atribui cada torrent a um ou mais **diretórios virtuais**. É isso que transforma uma lista plana de torrents em `movies/`, `shows/`, `anime/`, `recent/`.

As condições cobrem o nome do torrent (`regex`, `contains`, `not_regex`), o tamanho dele, os arquivos (`any_file_inside_regex`, `any_file_inside_size_gte`), as tags (`tags_match_any`, `tags_missing_all`), a idade (`added_within_hours`, `added_after`), propriedades derivadas (`has_episodes`, `is_music`) e de qual conta ele veio (`provider`, `not_provider`). As regras de exibição por diretório ficam junto: `only_show_the_biggest_file`, além dos limites mínimo e máximo de tamanho.

As regexes usadas por torrent em cada passagem de atribuição são compiladas uma única vez no nível do pacote, porque chamar `MustCompile` a cada chamada estava pesando de forma mensurável no tempo de inicialização.

A config pode ser editada ao vivo pelo dashboard. `UpdateConfigFileAtomic` faz edições no nível das chaves em vez de reserializar o arquivo inteiro, então comentários e chaves desconhecidas são preservados.

## Camada 2 — Abstração de backends {#layer-2--backend-abstraction}

`internal/debrid` é a espinha dorsal. Ele é dono dos tipos de domínio que todos os outros pacotes usam — `Torrent`, `TorrentInfo`, `File`, `Download`, `User` — e da interface `Provider` que cada backend implementa.

### Provedor e capacidades {#provider-and-capabilities}

`Provider` fica pequeno: lista torrents, busca informações, apaga, resolve um link, verifica, baixa os bytes e informa o estado da conta. Tudo que um serviço pode razoavelmente não ter é uma **interface de capacidade opcional** que quem chama faz type-assert e degrada quando não existe:

| Interface | O que adiciona | Quem precisa |
|---|---|---|
| `MagnetAdder` | adiciona por hash, seleciona arquivos, contagem de slots ativos | repair |
| `TorrentRestarter` | tenta de novo um torrent com falha no mesmo lugar | repair, a estratégia mais barata |
| `HostRotator` | troca o pool de hosts de CDN | teste de rede, página `/hosts` |
| `DownloadLister` | uma lista separada de downloads de hosters | o diretório `__downloads__` |
| `ArchivePasswordKeeper` | senha dos arquivos de um release | só Usenet |
| `PremiumMonitor` | tempo restante do plano | aviso na inicialização |

Junto com isso, `Capabilities` é a auto-descrição do provider: não o que ele consegue fazer, mas os limites dentro dos quais ele precisa ser usado. Isso existe porque o comportamento de biblioteca do zurg cresceu em torno do formato do Real-Debrid, e fixar esse formato no código faz todos os outros backends ficarem quebrados ou desperdiçarem recursos.

Duas flags já controlam o comportamento real:

- **`ListIncludesFiles`** — a lista de torrents já traz os detalhes de cada arquivo. Transforma um scan frio da biblioteca de uma chamada de API por torrent em uma única chamada no total. É a diferença mais cara entre os backends.
- **`StoredLinksCanRot`** — um link salvo pode morrer enquanto o torrent ainda parece saudável, então os links precisam ser testados. Essa é uma propriedade do Real-Debrid e um teste caro; em um backend que gera URLs sob demanda não há o que testar, e pular essa etapa é a diferença entre um scan sem custo e um scan que dispara um bloqueio em toda a conta.

Os demais — `ServesLinksLocally`, `MaxActiveSlots`, `MaxConcurrentRequests`, `AddsPerHour`, `ContentExpires`, `SupportsFileSelection` — são declarados por todos os backends e lidos pelo código genérico. O valor zero é intencionalmente a leitura mais conservadora, então um provider que esquece um campo recebe um comportamento cauteloso em vez de uma enxurrada de requisições, e um provider que o zurg não consegue resolver de jeito nenhum cai em `unknownProviderCaps` em `internal/torrent/providers.go`, que define essa resposta cautelosa uma única vez em vez de em cada ponto de chamada.

Existe um terceiro formato que nenhuma das flags expressa: a lista do AllDebrid não traz arquivos, mas o endpoint por torrent aceita um *lote* de ids. Isso é tratado dentro do provider, e não por uma capacidade, porque muda só a forma como o provider gasta as próprias requisições — o refresh genérico continua pedindo um torrent por vez e não precisa saber de nada disso.

### Set

`Set` é cada provedor configurado, na ordem do config, e é o que o gerenciador de torrents, os handlers e o painel dependem em vez de qualquer cliente específico. Dois padrões de acesso são importantes: **fan-out**, em que uma operação roda em todas as contas (um refresh da biblioteca), e **dispatch**, em que uma operação precisa chegar à única conta que é dona de um torrent (delete, resolve, repair). Ele também guarda o estado de saúde e disponibilidade das contas.

### Cache de links {#link-cache}

`LinkCache` armazena as URLs resolvidas indexadas **por token**, e não apenas por link. Uma URL gerada com um token só é válida dentro da cota desse token, então, quando um token atingir o limite de banda, suas entradas devem ser descartadas por completo, em vez de reaproveitadas com o próximo token da rotação. As entradas expiram com base no timestamp `Generated`, e não no momento da inserção, então os links carregados da lista de downloads do próprio provedor expiram segundo o cronograma dele.

### Os backends {#the-backends}

| Pacote | O que é | O que você precisa saber |
|---|---|---|
| `internal/realdebrid` | Real-Debrid, o backend original | Três clientes HTTP separados: API com limite de taxa, unrestrict com limite de taxa e download com rotação de host. Timestamps no horário de Paris são normalizados na fronteira do pacote e nunca vazam para fora dele. `DownloadTokenManager` troca os tokens quando um expira. |
| `internal/torbox` | REST do TorBox | Usa REST com `bypass_cache=true` em vez do WebDAV do TorBox, cuja visão fica 5–15 minutos atrás da realidade. Não existe link por arquivo, então os links são sintetizados como `torbox://<torrent-id>/<file-id>`: estáveis entre reinicializações e legíveis nos logs, o que não aconteceria com uma URL de CDN pura carregando a chave de API. Dois limitadores empilhados: o limite documentado de 300/min e outro bem mais restrito para `requestdl`. Veja [torbox-limits.md](../providers/torbox-limits.md). |
| `internal/alldebrid` | AllDebrid v4.1 | POSTs com dados de formulário; uma falha lógica chega como HTTP **200** com `status:"error"`, então o status HTTP nunca diz se a chamada deu certo. Os arquivos ficam atrás de `/magnet/files`, que aceita um lote, então consultas concorrentes são agrupadas em requisições únicas. A árvore de arquivos aninhada é achatada em profundidade, e essa ordem é essencial. |
| `internal/nzb` | Usenet, que não é um serviço debrid de jeito nenhum | Arquivos NZB em `nzbs/` viram torrents; as leituras buscam artigos e fazem o yEnc-decode sob demanda. Os links são `nzb://<nzb-id>/<file-index>` e servidos localmente, então `DownloadFile` sintetiza a resposta HTTP em vez de fazer proxy de uma. |
| `internal/nntp` | Cliente Usenet mínimo | Pool de conexões limitado pela cota de conexões da conta, BODY/STAT por message id, yEnc decode. Uma única conexão alcança só uma fração da velocidade possível, então as leituras de um arquivo se espalham por toda a cota. |
| `internal/par2` | PAR2 / Reed-Solomon sobre GF(2^16) | Quando um artigo saiu do servidor, os próprios volumes de recuperação do release reconstroem os bytes que ele carregava. É caro de um jeito específico: a aritmética precisa de cada fatia sobrevivente de cada arquivo coberto, uma única vez. Por isso roda como job em segundo plano, um release por vez, e gera patches de intervalos de bytes que os leitores servem no lugar do silêncio. |
| `internal/rdclient` | HTTP compartilhado de baixo nível | Rotação de hosts entre endpoints de CDN ranqueados por latência, limitação por token bucket, retry com backoff, suporte a proxy, DNS customizado, forçamento de IPv4/IPv6, preferência por CDN com geo-fixação. `IPRepository` cuida do teste de rede e do seu cache em disco. |

`internal/nzb` é a prova de que a abstração se sustenta. Ele implementa a mesma
interface sobre um diretório local e um servidor de notícias, o que funciona porque o
contrato real da interface é *"responder um GET com intervalo de bytes"*, não *"fazer proxy
de uma CDN"*.

### Adicionando um backend {#adding-a-backend}

Novo pacote, implemente `debrid.Provider`, chame `debrid.Register` no `init`, adicione
um import em branco em `internal/app.go`. Nada em `internal/debrid` muda.

## Camada 3 — A biblioteca {#layer-3--the-library}

`internal/torrent` é o núcleo do zurg e o maior pacote dele. O `TorrentManager` guarda a biblioteca inteira em mapas concorrentes `cmap`, para leituras sem lock. Ele também atribui os torrents às pastas avaliando os filtros do config, resolve e guarda em cache os links, e roda os jobs em segundo plano.

### Persistência {#persistence}

Cada entrada é gravada em `data/<name>.zurgtorrent` como JSON, e as informações de cada torrent ficam em cache em `data/info/`. Ao reiniciar, ele carrega tudo do disco e já fica pronto para uso, e só depois atualiza. Isso importa porque um scan a frio é limitado pelo rate limit, não pela CPU. Torrents que saíram da conta podem ser arquivados em `dump/` e aparecer como o diretório `__dump__` (`load_dumped_torrents`).

Os dados que mais nada consegue recriar (a config, cada zurgtorrent, o store `__magic__` em `data/local/` e os NZBs de origem em `nzbs/`) ficam em um único `.zurgbackup` em streaming. O `zurg backup` gera um (assim como a página Backup & Restore do dashboard), e o `zurg restore-backup <file>` descompacta ele no diretório de trabalho. O `internal/backup` cuida do formato. O manifest é a primeira entrada, então a restauração valida o que tem antes de escrever qualquer coisa.

Nomes de diretório reservados: `__all__`, `__unplayable__`, `__dump__`, `__downloads__` e um para cada conta, no formato `__<provider-name>__`.

### Torrent vs TorrentCopy

A mesma release pode ficar em mais de uma conta. O zurg mostra ela uma vez só. A divisão funciona assim:

- **Os fatos do conteúdo ficam na entrada** (`Torrent`): nome, hash, quais arquivos existem, tags, id do IMDB, rename.
- **Os fatos da conta ficam em cada cópia** (`TorrentCopy`): os ids de torrent que aquela conta gerou, os links que ela entrega, o próprio estado de quebrado e os contadores de retry.

Os ids de arquivo, em especial, são por conta. O Real-Debrid numera os arquivos dentro de um torrent e marca um subconjunto como selecionado; o TorBox lista só o que ele baixou e numera do jeito dele. Por isso o `FileSource` guarda o `FileID` de cada provedor. O repair monta a seleção com os ids da cópia que está consertando. Se ele ler o id de outra conta, vai readicionar os arquivos errados.

As cópias são guardadas na ordem da config, que é a ordem de preferência. As leituras preferem a primeira cópia saudável e, se ela falhar, passam para a próxima. Apagar a entrada apaga todas as cópias. Uma entrada sem cópias não existe.

### GetKey deve permanecer puro {#getkey-must-stay-pure}

`GetKey` é o nome de um torrent na biblioteca virtual: a entrada do diretório, o nome do arquivo `.zurgtorrent` e o identificador que toda consulta usa. Ele é **recalculado a cada consulta, nunca armazenado**. Por isso não dá para resolver colisões de nome checando o que já está em uso: a resposta mudaria conforme a biblioteca mudasse, e um torrent ficaria impossível de encontrar pelo nome com que foi registrado.

O único sufixo é para o caso mais raro em que dois *releases* diferentes têm o mesmo nome. Ele é uma tag com o hash do próprio conteúdo, tão pura quanto o próprio nome. A flag que ativa isso é decidida pela etapa de refresh, que enxerga a biblioteca inteira, e fica salva no torrent.

### Jobs em segundo plano {#background-jobs}

| Job | File | What it does |
|---|---|---|
| Refresh | `refresh.go` | Consulta cada conta, mescla as instâncias listadas em entradas, busca informações das novas, atribui diretórios e faz a limpeza. Usa uma busca barata de um único item como verificação de mudanças entre as consultas completas. |
| Repair | `repair.go` | Encontra e conserta torrents quebrados. |
| Downloads | `manager.go` | Atualiza a lista de downloads de hosters em `__downloads__`. |
| Network test | `handlers` | Reclassifica periodicamente os hosts de CDN. |

O intervalo de cada job pode ser redefinido em tempo de execução por meio de um canal, então mudar a
configuração pelo dashboard tem efeito sem precisar reiniciar. Os timestamps da última execução são salvos
(`data/repair_timestamp`, `data/downloads_timestamp`) para que um reinício não rode de novo um job que acabou de rodar.

### Reparo {#repair}

A segunda maior preocupação do pacote. Os arquivos carregam um estado FSM (`ok_file` / `broken_file`, via `pkg/fsm`); torrents e cópias carregam os seus próprios. Quando os links param de entregar bytes, o reparo escala por estratégias:

1. **Reiniciar no lugar** (`TorrentRestarter`) — a mais barata: não há novo upload, nenhum slot de adição é gasto, e o torrent mantém o seu id, então a entrada da biblioteca sobrevive em vez de ser apagada e redescoberta. A atualização emite isso para um torrent com falha que ela encontra na conta, e só em uma instância autorizada a agir sobre torrents com falha: `enable_repair` ou `delete_error_torrents`. Com as duas desligadas, a conta fica como está (`mayRestartFailedTorrents`).
2. **Baixar de novo os arquivos quebrados** — selecionar de novo só o que está quebrado.
3. **Reinserir** — adicionar o magnet de novo e colher links novos.
4. **Arquivar** — último recurso para lançamentos que não podem ser recuperados.
5. **Oferecer a uma conta que não tem o item** (`repair_across_accounts.go`) — os serviços mantêm caches independentes, então um lançamento que uma conta purgou, ou recusa pelo nome do arquivo, pode ser colocado em cache em outra. Quando nenhuma conta que tem o lançamento consegue consertá-lo, as contas configuradas que não o têm são consultadas em ordem, e a primeira que já tem o hash o pega; a listagem que vem em seguida o associa à entrada como uma segunda cópia pelo caminho normal `absorbCopy`, que limpa o próprio veredito da entrada. Sempre só em cache, via `AddIfCached` e nunca via `restrict_repair_to_cached` — uma adição que a conta teria de buscar é cancelada e apagada de novo, então isso é um reparo e nunca um novo download. Uma conta que não responde recebe uma espera que vai de um dia a cerca de duas semanas, e uma varredura faz no máximo dez ofertas, o que torna viável rodar isso sem ser pedido contra uma biblioteca de lançamentos condenados.

Em volta disso: backoff exponencial, tetos de tentativas por cópia (`RepairCycles`, `AssignRetries`, persistidos para que os tetos sobrevivam a reinicializações), portões de orçamento de adição por hora a partir de `Capabilities.AddsPerHour`, verificações de slots ativos, deduplicação por meio de uma fila baseada em set, e uma heurística válida para toda a varredura que lê uma rajada de falhas de hoster indisponível como uma única queda do provedor, e não como N torrents quebrados. Vereditos de irreparável são registrados por cópia e só se propagam para a entrada quando *todas* as cópias têm um — um erro permanente do Real-Debrid não diz nada sobre a cópia da TorBox.

Um operador pode forçar um reparo manualmente. O estado de forçar fica no torrent e não no contexto, porque uma requisição que chega no meio de uma varredura fica estacionada na fila e é pega depois, sob o próprio contexto da varredura. O botão também chega ao passo 5, e nessa ordem: primeiro limpa todos os vereditos do lançamento, para que a conta que o tem seja tentada exatamente como antes, e a oferta só acontece se essa tentativa falhar. Como ele limpa esses vereditos, um torrent indicado fica elegível quando a varredura coleta suas entradas condenadas, e só é condenado de novo pelo reparo que acabou de rodar, então é coletado depois desse reparo e não no loop — caso contrário, o único caminho com alguém esperando por ele seria justamente o único que nunca faria a oferta.

### Todo o resto do pacote {#everything-else-in-the-package}

`mediainfo.go` (análise com ffprobe, alimentando as tags de duração/codec), `tags.go`, `rename.go` (renomeações que precisam sobreviver ao refresh), `delete.go`, `strm.go` (gerando arquivos `.strm` para a biblioteca inteira), `hooks.go` (scripts do usuário em eventos do ciclo de vida), `assign_links.go`, `unrestrict.go`, `opensubtitles.go`, `provider_directories.go`, `reset_all.go`.

## Camada 4 — Servindo {#layer-4--serving}

### Roteador {#router}

`internal/handlers` monta o router chi e conecta tudo. Os métodos não padrão do WebDAV (`PROPFIND`, `MKCOL`, `MOVE`) são registrados no chi na `init`. A autenticação básica envolve todas as rotas, *exceto* `version.txt` e `/ready` (para que os health checks funcionem) e os endpoints `.strm` (um player de mídia que abre um `.strm` não tem credenciais para enviar; o token assinado no caminho é que autoriza o acesso).

Duas lições de roteamento estão registradas nos comentários e vale a pena não reaprendê-las: o chi aplica um parâmetro de caminho com regex **dentro de um único segmento**, então um arquivo acessado por meio de um arquivo compactado (`<archive>.rar/<inner>.mkv`) ou um diretório aninhado dentro dele não batia com rota nenhuma. As duas precisaram de wildcards no final. E um caminho dentro de um torrent é dividido entre listagem e download pela barra final, depois que a rota deixa de se importar com a profundidade do caminho.

### Listagens {#listings}

`internal/dav` gera o XML do PROPFIND e trata DELETE, MOVE (renomeações, com validação entre diretórios e entre torrents) e as variantes do Infuse. `pkg/dav` monta o XML por conta própria, com concatenação de strings otimizada em vez de marshalling de XML, faz a conversão de RFC 3339 para RFC 1123 que os clientes WebDAV exigem, e escapa os caminhos tanto para URL quanto para XML.

`internal/htmlindex` renderiza a mesma árvore como HTML para `/http/`.

As duas aplicam as mesmas regras de visibilidade (só o maior arquivo, limites de tamanho, estado broken/deleted) e as duas agrupam os volumes de arquivos RAR de várias partes, então só o primeiro volume fica visível.

### O caminho dos bytes {#the-byte-path}

`internal/universal` é onde uma requisição vira bytes:

- A resolução de links é deduplicada com `singleflight`, então cem leituras simultâneas do mesmo arquivo custam uma única resolução.
- Proxy ou redirecionamento, conforme `disable_stream_proxy` — exceto um link servido localmente (`ServesLinksLocally`), que nunca pode ser redirecionado, já que o cliente não tem o que abrir.
- Refaz o unrestrict em um link quebrado, até um limite pequeno.
- Um cooldown por arquivo para falhas de rede: 3 erros seguidos deixam o arquivo parado por 5 minutos, que é o que impede um host de CDN inacessível de virar um loop de retentativas infinito.
- Pausas curtas durante uma janela de rate limit, em vez de dar erro. Dar erro nas leituras durante o cooldown curto transforma uma conta limitada numa tempestade de erros pelo VFS do rclone — waiters travados, leitores em D-state, um servidor de mídia travado — então segurar a leitura é a resposta mais barata. Classes de cooldown mais longas ainda falham rápido.
- Contabilidade de banda por token, com os contadores zerados à meia-noite CET para bater com o reset diário de tráfego do Real-Debrid.

### Arquivos {#archives}

`internal/rarstream` analisa cabeçalhos RAR4, RAR5 e ZIP por meio de requisições de intervalo de bytes (HTTP 206), monta um mapa de chunks entre os volumes e reconstrói o conteúdo de um único arquivo na hora. **Sem descompressão**: só há suporte para dados armazenados (stored), que é o que os releases de scene usam. `VolumeKey` e `IsVolume` padronizam as muitas convenções de nomes de arquivos multipartes (`.part001.rar`, `.r00`, `.rar`) que `dav` e `htmlindex` usam para juntar os volumes em uma única entrada. As listagens ficam em cache no torrent e são marcadas com o `ListingVersion` do parser, então uma listagem produzida por um parser diferente é descartada em vez de ser servida.

### STRM

`internal/strmlink` codifica e assina a URL que um `.strm` contém. O esquema só para Real-Debrid que ele substitui era seguro por acaso: a URL trazia o código de download de 13 caracteres do RD, então quem tinha a URL *era* a prova de autorização. Outros backends endereçam arquivos por ids trivialmente enumeráveis (`torbox://17/3`), então o mesmo formato permitiria que qualquer um que alcançasse a porta gerasse URLs de CDN na conta ou gastasse as conexões do servidor de news. Um HMAC sobre um segredo em `data/strm_secret` resolve isso: um token que o zurg não escreveu não é resolvido. O segredo precisa sobreviver ao processo: todo `.strm` já escrito continua válido só enquanto a sua chave de assinatura existir.

### Painel e gerenciamento {#dashboard-and-management}

`internal/handlers/dashboard` renderiza a interface web a partir de templates embutidos, já pré-processados na inicialização, então um erro de sintaxe falha logo, e não só na hora da requisição. Páginas: status dos torrents em tempo real, um editor interativo de configuração YAML, latência do host, gerenciamento de diretórios, gerenciamento de provedores, status da conexão com o servidor de mídia, informações de conta/premium, largura de banda, status do rclone e estatísticas "Wrapped" do Plex. Os buscadores de status de cada servidor de mídia rodam em paralelo para manter as páginas responsivas.

`internal/handlers/manage` é a interface de operações por torrent: tags, listagens de arquivos com detalhes de estado, correspondência no Plex, renomeações, exclusão/restauração/force-show por arquivo, exclusão em massa e escaneamento.

A visão de duplicados fica em `internal/duplicates`. `internal/arrinventory` e os leitores `Inventory` ao lado dos adaptadores do Radarr e do Sonarr leem todos os arquivos que um \*arr tem, somente leitura e separados da aquisição. `magic.Resolver.HolderOf` rastreia o caminho de cada arquivo até o release de origem, e o pacote agrupa releases que possam conter o mesmo filme ou os mesmos episódios. O agrupamento usa nomes, IDs do IMDb e o histórico do \*arr. Se um release está em uso é decidido somente pelos caminhos rastreados.

`internal/static` embute CSS, favicon, logo e robots.txt com `go:embed`, então o binário é autossuficiente.

## Camada 5 — O mount {#layer-5--the-mount}

`internal/rclone` supervisiona o rclone como um subprocesso: ele monta o comando de mount (um remote WebDAV apontando para o `/dav/` do próprio zurg), inicia e para o processo, faz um health check a cada 30 s com backoff exponencial de reinício (1 s → 60 s) e reinicia quando ocorre alguma falha.

Uma porta RC efêmera no intervalo 49152–65535 é escolhida na inicialização para invalidação do cache do VFS e consultas de status. Essa invalidação é importante em dois momentos: assim que o cache da biblioteca termina de carregar e de novo depois do primeiro refresh completo. Sem isso, as listagens parciais que o mount pegou no meio do carregamento ficam presas durante todo o `--dir-cache-time`.

As credenciais são passadas por variável de ambiente, nunca na linha de comando. `Controller` é a interface que os handlers e o dashboard consomem; `Runner` e `Command` abstraem o gerenciamento de processos para os testes.

## Camada 6 — Servidores de mídia {#layer-6--media-servers}

Duas coisas distintas compartilham a palavra "Plex":

- **`pkg/plex`, `pkg/jellyfin`, `pkg/emby`** são *clientes* de servidores de mídia, cada um implementando `common.MediaServerWorker`. `pkg/common` fornece o ciclo de vida compartilhado dos jobs: uma fila dinâmica sem limite, controle de tentativas por job, backoff exponencial com jitter, um circuit breaker após falhas consecutivas e detecção de jobs travados. Ele também tem os helpers de caminho que lidam com o APFS case-insensitive do macOS. `pkg/scan` fica por cima como um `MediaScanner` unificado que direciona um job de atualização de caminho para o servidor que é dono desse caminho e informa a profundidade da fila de cada servidor.
- **`internal/plex`** é o comportamento específico do zurg: `Matcher` associa torrents a itens da biblioteca do Plex usando caminhos de arquivo, ids do IMDB e identificadores TVDb/TMDb. Ele roda periodicamente em worker pools com metadados em cache e preenche retroativamente nos torrents os ids do IMDB descobertos.
- **`internal/acquisition`** cuida da fila de aquisição persistente e do executor compartilhado, que pega NZBs de indexadores Newznab e torrents em cache de indexadores Torznab. Plex watchlist, Seerr, Radarr e Sonarr são adapters de fonte que resolvem pedidos em alvos de filme, temporada ou episódio. `data/acquisition.json` guarda os prazos de retry e o progresso por alvo entre reinicializações. Veja [fontes de aquisição](../guides/acquisition.md) para a configuração e os contratos dos adapters.

`pkg/mediabrowser` guarda os tipos que Emby e Jellyfin compartilham.

## Camada 7 — Suporte {#layer-7--support}

| Pacote | Finalidade |
|---|---|
| `pkg/fsm` | Duas variações de uma máquina de estados simples: `FSMWithExternalMutex` para quando a FSM fica embutida em algo que já está travado, `FSMWithTime` para quando ela precisa do próprio lock e de um timestamp de transição (assim `SinceWhen` consegue responder "há quanto tempo isso está quebrado"). |
| `pkg/logutil` | Zap com saída dupla: console colorido e um arquivo com rotação (10 MB × 20 via lumberjack). A verbosidade vem de `log_level` no config.yml, com fallback para a variável de ambiente `LOG_LEVEL` e depois para DEBUG; o nível fica em um `zap.AtomicLevel` compartilhado, então o dashboard pode mudar o nível de todos os loggers de uma vez, sem reiniciar. Inclui a leitura do log de volta para o visualizador do dashboard e para Export Logs. |
| `pkg/utils` | Persistência de hosts bloqueados, regras de visibilidade de arquivos, redação de tokens, detecção de vídeo/áudio, nomenclatura de `.strm` e `GetZurgBaseURL` (que respeita `X-Forwarded-*` atrás de um reverse proxy). |
| `pkg/script` | Executa os scripts de eventos do ciclo de vida definidos pelo usuário; PowerShell no Windows, `/bin/sh` nos demais sistemas. |
| `pkg/dmm` | Cliente para a API de busca do debridmediamanager.com, com limite de 1 requisição a cada 2 segundos, imposto pelo servidor. Usado pelo monitor de watchlist. |
| `internal/version` | Metadados de build injetados via ldflags; também o banner ASCII em `/http/version.txt`. |
| `internal/requirements` | Baixa o `ffprobe` e o `rclone` compatíveis com a plataforma a partir das releases do GitHub na primeira execução e grava caminhos *relativos* no config.yml, para que a configuração continue portátil. Plataformas não suportadas emitem um aviso em vez de falhar. |
| `internal/clear` | Apaga em massa os downloads e torrents do RD usando a interface web com um cookie de autenticação, repetindo até ficar vazio. |
| `internal/handlers/tmplcache` | Cache de templates para o dashboard. |

## Decisões transversais {#cross-cutting-decisions}

**Capacidades em vez de `if provider == "realdebrid"`.** Tudo que assume o formato do Real-Debrid deve ficar atrás de uma flag de capacidade, não de uma checagem de tipo. Essa é a regra que mantém o gerenciador de torrents independente do backend.

**O contrato da interface são bytes, não proxy.** `Provider` nunca promete um CDN remoto, apenas que um GET com range pode ser respondido. Por isso um backend de Usenet se encaixa. Os dois pontos onde a suposição de CDN vazou (redirecionamentos e a entrega de uma URL ao ffprobe, que precisa de algo que um binário externo consiga abrir) agora são protegidos por `ServesLinksLocally`.

**O pareamento posicional de links é essencial.** `TorrentInfo.Links[i]` corresponde ao i-ésimo arquivo **selecionado** em `TorrentInfo.Files`. Um provider que não consegue gerar link para um arquivo precisa marcá-lo como *não selecionado* em vez de omiti-lo, senão todos os arquivos seguintes serão associados silenciosamente ao link errado. Todo backend precisa respeitar isso.

**Um torrent pertence a exatamente uma conta.** Qualquer chamada que chegue a um serviço deve ser despachada pelo provider do torrent (`ProviderFor`, `resolveLink`, `verifyLink`, `DeleteByID`), nunca pelo provider principal. Errar nisso apaga coisas da conta errada.

**O disco é um nível real.** Entradas `.zurgtorrent`, detalhes por torrent em `data/info/`, resultados de testes de rede e seus timestamps, timestamps de jobs, o segredo de assinatura do STRM, caches de listagem de RAR e hosts bloqueados. Ao reiniciar, o sistema retoma de onde parou em vez de escanear tudo de novo.

**Tudo tem ritmo controlado.** Token buckets por provider, limites de concorrência, limites de adição por hora, TTLs de links, cooldowns por arquivo e pausas por rate limit. No TorBox especialmente, a resolução de links é o recurso mais escasso, e o cache de links na frente dela é o que torna um scan da biblioteca viável.

**Leituras não usam lock, escritas são restritas.** Mapas concorrentes sustentam as árvores de diretórios, torrents e arquivos. A mutação é protegida por locks por torrent (`copiesMu`, `tagsMutex`, `operationsMutex`, `archiveCacheMutex`), e não por nenhum lock global.

**O `rdclient` é compartilhado, mas sua política é a do Real-Debrid.** A classificação de erros e as regras de retry dele vieram do RD. Ele retorna erro para qualquer resposta não-2xx, mas ainda devolve a resposta. Por isso, um provider que precisa do status (um 429 com `Retry-After`, por exemplo) deve checar `resp` antes de `err`.

## Build, teste e deploy {#build-test-deploy}

- **Build**: `make build`. Versão, commit e horário do build são injetados via
  ldflags em `internal/version`.
- **Testes unitários**: `go test ./...`. O pre-commit roda gofmt, golangci-lint,
  `go test -short` e uma suíte de qualidade completa.
- **Testes de integração**: `make integration-test`, do mais barato para o mais caro, com
  `refresh_repair` por último porque ele espera uma varredura completa da biblioteca. Rode-os em um
  host que tenha Go, rclone, FUSE e Plex juntos — em outros lugares os testes de mount e
  do Plex são pulados de forma bem visível, mas ainda saem com código 0, então leia a saída em vez de olhar o código de saída. Veja [e2e-test.md](e2e-test.md).
- **Docker**: build em duas etapas com Alpine; a imagem de runtime adiciona ffmpeg, rclone,
  fuse3 e um healthcheck.
- **Deploy**: `make deploy USER=… HOST=… DIR=…`, que para o Plex e os serviços do zurg,
  troca o binário, espera o `version.txt` responder 200 e então reinicia o Plex.

## Onde procurar primeiro {#where-to-look-first}

Os comentários neste código sempre explicam *por quê*, geralmente a falha que motivou o trecho. Todo pacote tem um `doc.go`. Se você for mexer em alguma coisa, leia antes de tudo o `doc.go` desse pacote e o comentário de bloco acima do tipo que você está tocando. Eles trazem restrições que não aparecem nas assinaturas.
