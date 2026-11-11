# Limites do TorBox e como o zurg se adapta a eles {#torbox-limits-and-how-zurg-adapts-to-them}

zurg's library behaviour grew around Real-Debrid's constraints. TorBox's are different in kind, not just in magnitude, and driving it like Real-Debrid gets the account rate-limited within seconds of a first library scan. This is what the limits are, where the figures come from, and what zurg does about each.

As limites dos provedores são declaradas no código como `debrid.Capabilities`, para que o código genérico da biblioteca as leia em vez de presumi-las. Adicionar um backend significa preencher essa struct, sem editar o gerenciador de torrents.

## Limites de requisições {#rate-limits}

| Limite | Valor | Fonte |
|---|---|---|
| Todos os endpoints juntos, por token de API | 300/min | [documentado](https://api-docs.torbox.app/) |
| `POST /torrents/createtorrent` (só não cacheados) | 60/hora | documentado |
| `POST /webdl/createwebdownload`, `POST /usenet/createusenetdownload` | 60/hora | documentado |
| `GET /torrents/requestdl` | **~100 chamadas, depois 429** — um orçamento, não um limite de taxa | medido, 2026-08-30 |
| Conexões simultâneas para um host de CDN | **exatamente 20**, 429 acima disso | medido, 2026-08-23 |
| Teto de rajada global | dispara em ~40 simultâneas, limita *todos* os endpoints | medido |
| Recuperação do 429 | `Retry-After: 300`, corte binário | medido |

Os limites são por token de API e sincronizados entre os servidores da TorBox, não por IP. Por isso, clientes extras em outras máquinas dividem o mesmo orçamento. A TorBox deixou isso claro: parou de aceitar pedidos de whitelist de IP porque o limite é atrelado ao token.

Três coisas tornam isso mais pesado do que os 300/min da manchete sugerem:

- **Os 300/min não são por endpoint.** É um único orçamento que a chave inteira gasta. Então, controlar o ritmo de cada endpoint separadamente pode fazer a soma deles ultrapassar um teto que nenhum deles ultrapassa sozinho.
- **O `requestdl` é muito mais restrito do que o documentado, e não é um limite de taxa.** É o endpoint que gera as URLs de download, e ele parou depois de cerca de 100 chamadas, enquanto `user/me`, `mylist` e `checkcached` aguentaram mais de 500 na mesma concorrência.

  Desacelerar não compra mais chamadas. Medido em 2026-08-30 na conta principal, em três rodadas, cada uma começando com o bloqueio zerado:

  | Ritmo | 429 apareceu em | Tempo decorrido |
  |---|---|---|
  | o mais rápido possível, subindo de 60 a 240/min | chamada **100** | 56s |
  | uma por segundo (60/min) | chamada **94** | 108s |
  | uma a cada dois segundos (30/min) | chamada **101** | 198s |
  | uma a cada três segundos (20/min) | **nunca** — 241 chamadas | 721s, sem erro |

  Cortar o ritmo pela metade deu noventa segundos a mais e nenhuma chamada a mais; cortar de novo fez o 429 deixar de acontecer. O que a conta tem é **100 chamadas em cinco minutos corridos — 20/min**, e só essa leitura explica as quatro rodadas: ela prevê o bloqueio em t≈100s, t≈200s e de imediato nas três primeiras, e prevê que a quarta fique exatamente na linha e passe.

  Esta é a correção que mais importa ao ler o resto deste arquivo. Um limitador por minuto não consegue manter o zurg dentro do orçamento, então os números de ritmo abaixo compram suavidade, não folga. Um limitador mais rápido não termina a varredura da biblioteca mais cedo: ele só chega ao mesmo bloqueio antes e deixa o mount sem responder nada por cinco minutos quando isso acontece. Gastar *menos* chamadas é a única coisa que aumenta o quanto uma varredura consegue avançar, e é por isso que a leitura antecipada foi descartada aqui e por que dar nome a um arquivo já resolvido nunca pode custar uma requisição.
- **O 429 é um penhasco, não uma ladeira.** Depois que dispara, 100% das requisições falham por cerca de cinco minutos. Não há uma queda parcial de desempenho para aguentar.

Downloads da CDN são medidos separadamente e **não** dividem o orçamento da API. Transmitir um arquivo nunca gasta cota de resolução de links. Isso foi verificado nos dois sentidos: saturar os downloads da CDN até o 429 deixou o `requestdl` respondendo normalmente, e o contrário também.

### Dois limites diferentes, ambos com número 20 {#two-different-limits-both-numbered-20}

A tabela acima mostra o 20 duas vezes, e elas não têm relação entre si. É fácil confundir as duas
e acabar ajustando a coisa errada.

- **`requestdl` com cerca de 20 simultâneas** é um limite de *API*: cerca de 100 chamadas com essa simultaneidade antes de um 429, gastando a cota de requisições da conta.
- **20 conexões por host de CDN** é um limite do *caminho dos bytes*, medido em 2026-08-23 com uma rampa gradual. Ele não precisa de nenhuma chamada a `requestdl` — reutilizar uma URL já gerada basta para atingi-lo.

O teto do caminho dos bytes é **exatamente 20** e se comporta como um limite rígido, não como uma subida gradual: 20 sustentadas, tenha-se pedido 24, 32, 40 ou 48 conexões, com as recusas aumentando para absorver tudo que passa da linha.

Ele vale para o **host do CDN, não para o objeto nem para o IP**, o que corrige a leitura antiga de "por IP na camada do Cloudflare":

- Dois arquivos *diferentes* servidos do mesmo host `nexus-NNN` dividem o único orçamento de 20 e recusam o mesmo excedente.
- A mesma carga dividida entre dois hosts roda sem problemas.
- 32 streams simultâneos espalhados por 16 hosts, todos do mesmo IP, funcionam bem.

Para comparar com os outros provedores medidos do mesmo jeito: o Real-Debrid limita a 32 por host (recusando na camada TCP, sem nenhum status HTTP), o AllDebrid a 32 (HTTP 429), e o Premiumize não mostrou teto algum até 64. O 20 do TorBox é o menor dos quatro.

**Os edges globais do TorBox não têm esse limite.** O 20 é uma propriedade dos hosts por nó `nexus-NNN.<region>.tb-cdn.st` que o `requestdl` gera. Os dois edges globais — `nexus.erth.tb-cdn.earth` e `nexus.hare.tb-cdn.earth` — servem qualquer arquivo da conta, e ambos subiram até 64 conexões simultâneas sem nenhuma recusa. Só o host muda; o caminho e o token continuam autenticando a requisição. O zurg não reescreve para eles hoje (o serviço irmão `debrid` faz isso, via `TORBOX_CDN_EDGE`), então o teto abaixo é o que se aplica aqui.

### O que o zurg faz {#what-zurg-does}

- **`GetTorrentInfo` é servido a partir da lista de torrents.** O `mylist` da TorBox
  já inclui a lista de arquivos de cada torrent, então atualizar a biblioteca custa uma
  requisição em vez de uma por torrent. Isso é declarado como
  `Capabilities.ListIncludesFiles`, e o caminho de atualização pula tanto a chamada por
  torrent quanto o cache de informações em disco para os provedores que definem essa flag. Numa
  conta com 213 torrents, isso é a diferença entre 213 requisições e 1.
- **Um único limitador controla todos os endpoints**, configurado em 240/min contra os 300
  documentados, deixando folga para tudo o mais que use a mesma chave: o painel da TorBox,
  outro cliente, um segundo zurg.
- **O `requestdl` tem um segundo limitador por cima**, configurado em 15/min. Cada resolução
  consome dos dois. O número fica abaixo do 20/min medido, e não igual a ele, pelo
  mesmo motivo de o limitador geral ficar em 240 contra os 300 documentados: o
  orçamento é gasto por tudo que usa a chave, e os 20/min foram medidos sem mais nada
  usando a chave. `TestTheRequestdlBudgetCannotBeSpentInsideItsWindow`
  garante o invariante real: a cota inteira não pode ser gasta dentro da janela que a
  reabastece, então a constante não pode voltar a ultrapassar o limite sem ninguém perceber.
- **O cliente de download é limitado a 20 conexões por host de CDN**
  (`maxConnsPerCDNHost` em `internal/torbox/client.go`, passado por
  `rdclient.HTTPClientOptions.MaxConnsPerHost`). O `MaxConnsPerHost` do Go faz a
  requisição 21 *esperar por uma conexão livre* em vez de falhar, então o limite transforma
  uma recusa do provedor em uma fila local. Sem ele, o cliente de download herdava o
  ajuste de ilimitado do transporte de uso geral e podia receber 429s no caminho dos bytes,
  mesmo com todos os limitadores de API sendo respeitados.
- **Respostas 429 bloqueiam todos os chamadores** pela janela do `Retry-After`, em vez de
  deixar cada um gastar uma requisição para descobrir de novo o bloqueio. O bloqueio vale
  para a conta inteira, então um 429 recebido em qualquer endpoint segura todos eles.
- **A concorrência é limitada a 16 requisições em andamento**, abaixo do teto de rajada global
  de ~40, deixando espaço para o cliente de download funcionar junto.
- **O read-ahead foi descartado.** O zurg aquece o próximo arquivo de um lançamento numa
  leitura a frio, e isso todo backend com um orçamento por minuto de verdade aguenta. Uma
  varredura da biblioteca é o caso que quebra isso: ela abre cada arquivo exatamente uma vez,
  então toda abertura é a frio, a recusa de leitura aquecida nunca dispara, e a conta
  recebe duas resoluções por arquivo. Medido em 30/08/2026, uma varredura de quarenta arquivos
  gerou exatamente quarenta resoluções especulativas junto com suas quarenta leituras: metade
  do orçamento gasta em arquivos que ninguém tinha pedido. A TorBox declara
  `Capabilities.SpeculativeResolutionsAffordable` como false e não recebe nenhuma.
- **Dar nome a um arquivo resolvido não custa requisição.** Toda resolução termina buscando
  o nome e o tamanho do arquivo para o registro de download. Essa busca passava pelo snapshot da
  lista, então, quando a janela de frescor de trinta segundos expirava, a leitura seguinte
  buscava a lista inteira de torrents antes de conseguir responder. Durante uma varredura, isso
  acontecia a cada trinta segundos enquanto a varredura durasse, e numa biblioteca de 3.700
  torrents essa listagem era paginada quatro vezes. Agora ela lê a listagem que já está em mãos,
  não importa a idade dela, já que os nomes e tamanhos dos arquivos de um torrent finalizado não mudam.
- **O cache de links é mantido por um dia, com recuperação em caso de recusa explícita.**
  Chamadas repetidas de `requestdl` devolveram URLs idênticas na sondagem de 30/08/2026,
  inclusive uma hora depois, e uma URL com 3h25min ainda servia `206`. Isso prova reuso,
  não um tempo de vida ilimitado. Em 04/09/2026, uma URL em cache, com autenticação correta,
  retornou `400` com “Invalid Presigned Token”, enquanto uma resolução nova do mesmo
  torrent/arquivo devolveu um host e um caminho diferentes e serviu `206`. A query era a
  mesma. Trocar só o caminho/query antigo para o novo host ainda retornava `400`.

  O cache de 24h continua sendo uma escolha de orçamento: uma varredura resolve a 20/min e pode
  levar horas. Uma recusa explícita de token inválido agora invalida essa URL e tenta uma
  resolução nova. Leitores concorrentes compartilham o trabalho de resolução, e uma recusa
  atrasada não consegue remover uma URL em cache mais nova. Se a URL recém-resolvida também
  for recusada, a reprodução pausa localmente por um minuto sem condenar o arquivo. Erros 400
  genéricos não provam que a URL está velha e só disparam um cooldown curto. Os 429s do CDN
  preservam o `Retry-After` e mantêm as leituras daquele host paradas entre arquivos e chamadas
  de verificação; o orçamento da API continua separado.
- **`bypass_cache=true` em toda chamada de listagem.** O cache próprio do `mylist` da TorBox tem
  um TTL de ~5 minutos; servir a partir dele é o que faz os mounts WebDAV ficarem
  5–15 minutos atrasados em relação à realidade. O parâmetro não custa nada no limite de taxa e
  reduz a propagação para menos de um segundo.
- **Uma consulta custa uma listagem.** A consulta de mudanças da biblioteca é o único chamador que
  força uma busca, já que detectar uma mudança é todo o trabalho dela. A contagem de
  ativos feita no mesmo ciclo, e a atualização completa que vem depois de uma mudança,
  leem ambos o snapshot que ela acabou de preencher. Forçar também nesses pontos significava
  despejar a biblioteca inteira duas ou três vezes por consulta — com o intervalo padrão de
  dez segundos, milhares de leituras completas redundantes por dia, contra um serviço cujo
  próprio cache de listagem o zurg já está contornando.
- **A listagem é percorrida em páginas de 1000.** O `mylist` limita uma resposta a 1000
  torrents — esse é o padrão documentado para `limit`, e pedir mais não aumenta o limite —
  e não informa nem o total nem se "há mais". Uma única requisição, portanto, responde a uma
  conta maior com os 1000 mais novos e parece exatamente uma biblioteca completa. O zurg
  pagina por `offset` até vir uma página curta, removendo ids duplicados conforme avança: a lista
  é ordenada por id decrescente, então um torrent adicionado durante a leitura desloca a janela
  uma posição e repete um item na junção entre as páginas.

## Limites da conta {#account-limits}

| Plano | Slots ativos | Seeding | Tamanho máx. do torrent | Observações |
|---|---|---|---|---|
| Free | 1 | nenhum | 10 GB | 1 adição/24h, 10 adições/mês, sem torrents privados |
| Essential | 3 | — | 200 GB | sem cooldown, adições em cache ilimitadas |
| Standard | 5 | 2 semanas | — | |
| Pro | 10 | 30 dias | — | expiração em 30 dias |

Fonte: [Restrições de conta](https://support.torbox.app/en/articles/9836418-account-restrictions).

`/user/me` informa o plano como um número, e os números não estão em ordem de preço:
**0 Free, 1 Essential, 2 Pro, 3 Standard**. O Standard foi adicionado depois do Pro. O zurg lia o plano 2 como Standard até 2026-10-03, o que dava às contas Pro cinco slots e o piso de uso do Standard.

**Slots ativos são a principal restrição da TorBox**, enquanto a do Real-Debrid é a largura de banda. Um torrent ocupa um slot enquanto está baixando *ou fazendo seeding*, então em um plano pago um torrent concluído pode ocupar um slot por até 30 dias.

### O que o zurg faz {#what-zurg-does-1}

- **`GetActiveTorrentCount` reports the plan's real ceiling**, read from
  `plan` on the user record, so repair blocks and waits instead of queueing
  adds the account will reject. A provider reporting no ceiling is treated as
  unbounded rather than blocking forever.
- **Added torrents are marked never-seed by default.** Seeding holds a slot for
  weeks and bills outgoing traffic, neither of which helps a streaming mount.
  `tb_seed_torrents` changes it for an operator whose private tracker counts
  ratio: `never` sends `seed=3` (the default), `always` sends `seed=2`, and
  `auto` leaves the field out. TorBox's own description of the field is "1 is
  auto. 2 is seed. 3 is don't seed. Optional. Default is 1, or whatever the user
  has in their settings. Overwrites option in settings", so any value sent,
  `1` included, replaces the account's Seeding setting and only an absent field
  lets it apply. The same mode goes on all three add paths: the magnet add, the
  cached-only add and the `.torrent` upload. With seeding on, finished torrents
  keep their slots, so repair and the download-client endpoints stall against
  the ceiling once seeding torrents hold all of them.
- **The cache is never checked before adding.** `checkcached` has no call site
  at all. Cached-only mode (`qbittorrent.download_timeout_mins: 0`) was the one
  exception until it was made to add the torrent and watch the instance like
  every other backend, because the endpoint reports whether the content is in
  TorBox's cache rather than whether this account ends up holding it. That costs
  something real on a miss: an uncached add consumes the 60/hour allowance where
  a probe consumed nothing. Cached adds still fall under the 300/min budget.

## Expiração do conteúdo {#content-expiry}

Conteúdo Pro expira após 30 dias. Torrents expirados voltam da API como `expired` ou `reported missing`, mas ainda informam `download_finished: true` com `download_present: false`.

Ler só o `download_finished` faria o zurg montar um torrent inteiro cujos links dão 404. O zurg mapeia as duas formas para o status `error`, e `Capabilities.ContentExpires` marca isso como normal para o backend, e não como falha.

**Os dois booleanos, sozinhos, não indicam que os dados sumiram.** Um download sem cache saudável informa `download_finished: true` com `download_present: false` pelos últimos 9.6 segundos de vida, enquanto passa por `processing`, `downloading` e `uploading`. Medido em 2026-08-30 com polling de 0.5 segundo e descrito em `docs/torrent-lifecycle.md`. Antes, o zurg lia esse par como morte, independentemente da string de estado, e qualquer instância com `delete_error_torrents: true` apagava esse torrent no meio do download. Cinco torrents de teste foram apagados assim naquele dia. A regra estrutural agora só decide sobre um payload que não traz `download_state` nenhum. Uma forma de escrita que este código não conhece é tratada como trabalho em andamento, porque `processing` era uma dessas até ser medida.

Uma leitura que chega a esse arquivo mesmo assim agora custa mais de uma chamada. Como o caminho de serving trata um 404 em uma URL de entrega gerada como um link revogado, e não como arquivo ausente (que é o que ele é no Real-Debrid, cujos códigos morrem quando a linha de downloads é apagada), ele resolve de novo antes de desistir. Assim, um arquivo expirado no TorBox gasta até quatro chamadas `requestdl` por leitura, em vez de uma. O limite vale por leitura, e a listagem já marcou o torrent como `error`, então ninguém percorre uma biblioteca expirada nesse ritmo. Mas um cliente que martela um mesmo caminho expirado paga quatro vezes o que pagava antes.

### O que o zurg faz {#what-zurg-does-2}

**Nada readiciona os torrents de um backend que expira sozinho.** O reparo corrige um torrent quebrado adicionando o magnet de novo. Isso é um reparo em um backend que mantém o conteúdo, mas é um novo download em um que o expira. Rodar isso em um temporizador sobre a biblioteca inteira é o comportamento que a TorBox cita em primeiro lugar entre os motivos para uma conta ser sinalizada: "excessive transfer retention (using tools to artificially keep transfers active)". Além disso, cada readição de um conteúdo não cacheado é uma transferência de entrada contada na cota do plano.

Por isso, a varredura periódica ignora os torrents cuja cópia reparável está em um provedor que declara `ContentExpires`. Eles continuam quebrados e visíveis. O botão de reparo do painel continua funcionando, e um release que também está no Real-Debrid continua sendo reparado a partir dessa cópia normalmente. A distinção está em quem pediu, não no que quebrou.

## Uso e o sistema de abuso {#usage-and-the-abuse-system}

O TorBox não fiscaliza pedidos. Ele mede os bytes transferidos em uma janela contínua de 15 dias, comparados com um limite derivado do percentil 99 de cada faixa de plano. Ele avisa três vezes (**cada aviso troca a chave da API**) e bane na quarta. Os pisos publicados, ou seja, o mínimo em que esses limites dinâmicos podem ficar:

| Plano | Piso |
|---|---|
| Free | 5 TB/mês |
| Essential | 10 TB/mês |
| Standard | 20 TB/mês |
| Pro | 30 TB/mês |

Os dois sentidos contam: os adds não cacheados que entram e tudo o que o TorBox envia, seja para o seu dispositivo ou de volta para o swarm. Os adds cacheados não contam. A contabilidade é exata até o byte, então um arquivo lido só parcialmente custa apenas o que foi lido.

**`cooldown_until` em `/user/me` não é um desses avisos, e tratá-lo como um vai te custar um dia.** Verificado em 12/08/2026 em uma conta do plano 2 com um cooldown ativo e recém-definido (24h pela frente, `updated_at` de um minuto atrás): `/user/me`, `checkcached` e `mylist` responderam todos `200 success:true`, o `PROPFIND` do WebDAV retornou `207`, e uma leitura com intervalo `bytes=0-0` veio com **`206` e um `Content-Range` correto em 2,8s**. Nenhuma camada recusou o serviço. A transferência total dessa conta era de 14,1 GB contra um piso de 30 TB/mês, então era um cooldown de taxa da API, não um strike por banda. O que diferencia os dois casos é a **chave**: um aviso real troca a chave, e depois todos os endpoints retornam `AUTH_ERROR`, enquanto um cooldown com a chave intacta não tem efeito observável. E como o `checkcached` pode informar que um release está cacheado sem que o TorBox realmente o sirva, **a leitura com intervalo é a única verificação que comprova que o serviço está funcionando**. Confira o caminho dos bytes antes de concluir que o TorBox não está utilizável.

Fonte: [O Sistema de Abuso do TorBox](https://support.torbox.app/en/articles/10336778-the-torbox-abuse-system).

### O que o zurg faz {#what-zurg-does-3}

- **Torrents adicionados nunca fazem seed por padrão**, então nada é cobrado na saída para o conteúdo que o zurg só lê. `tb_seed_torrents: always` (ou `auto` em uma conta configurada para fazer seed) é a única configuração que muda isso, e o upload dela é cobrado como qualquer outro.
- **O uso é amostrado e comparado.** A API não publica um número acumulado, só um contador vitalício em `/user/me`, então o atualizador de contas registra esse contador a cada 30 minutos em `data/torbox_usage.json` e calcula a diferença entre as amostras. Um valor dos últimos 30 dias que ultrapassar 80% do piso do plano gera um aviso no log. Esse aviso é o principal motivo da amostragem: o painel mostra apenas o que o próprio zurg fez proxy, nunca essas diferenças. Uma instalação nova não tem histórico e informa isso, em vez de mostrar um zero tranquilizador.
- **Uma chave rejeitada é reportada como um possível aviso de abuso**, e não como erro de configuração nem como problema no conteúdo. A rotação de chaves é justamente como a TorBox envia esses avisos, e tratar isso como problema no conteúdo mandaria a biblioteca inteira para reparo.

## Propositalmente não mapeado {#deliberately-unmapped}

Um `download_state` não reconhecido é reportado como `downloading`, nunca como `error`.
Com `delete_error_torrents` ativado, um status de erro faz o zurg apagar o torrent da conta, então um estado que a TorBox introduzir depois que este código foi escrito não pode ser capaz de causar exclusões.
