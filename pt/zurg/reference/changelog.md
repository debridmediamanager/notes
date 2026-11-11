# Changelog

## zurg encontra animes, programas diários e especiais para o Sonarr {#zurg-finds-anime-daily-shows-and-specials-for-sonarr}

Uma fonte do Sonarr costumava pular uma série diária, uma série de anime e os especiais de uma série, com um aviso para cada uma. Agora, os episódios que faltam de uma série diária também são pedidos pela data em que foram ao ar (`The Daily Show 2026.11.03`), os de um anime pelo número que a série usa para contá-los (`Jujutsu Kaisen 30` é o sexto da segunda temporada), e os especiais como temporada `00`, junto com a busca usual por temporada e episódio. O parser do próprio Sonarr diz qual episódio cada release é, como faz com qualquer série, e o perfil de qualidade avalia do mesmo jeito de antes.

Um vídeo colocado para um anime ou uma série diária recebe o nome `JUJUTSU KAISEN - S02E06 - <the release's own name>`, porque o rescan do Sonarr lê o arquivo só pelo nome e colocaria `2nd Season - 06` na temporada 1. Os vídeos de uma série comum e de um especial mantêm seus nomes.

Os especiais vão para a pasta que o **Specials Folder Format** do Sonarr define, e só um release com `S00Exx` no nome pode corresponder a um deles. Veja [O que o zurg pede ao Sonarr](../guides/acquisition.md#what-zurg-asks-sonarr-for).

## Mantenha um filme desejado em 1080p e em 4K {#keep-a-wanted-film-at-1080p-and-at-4k}

`quality: [1080p, 4k]` no bloco `acquisition:` mantém duas cópias de cada filme na sua lista de desejados do DMM, para que uma TV 1080p consiga tocar uma delas sem transcodificar o arquivo 4K. Cada cópia pega a melhor release em ou abaixo da própria resolução e sobe para ela sozinha. Enquanto nada melhor que 1080p estiver disponível, as duas compartilham uma só cópia. Séries e todas as outras fontes continuam com uma cópia só. Veja [a copy at each of several resolutions](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

## A atualização do zurg funciona após a instalação em uma linha {#zurg-update-works-after-the-one-line-install}

Os instaladores de uma linha fazem login no GitHub pela GitHub CLI. Eles baixaram a ferramenta só para isso e a apagaram ao terminar. Aí o `zurg update` procurou a GitHub CLI e não achou nada. Ele parou com "no GitHub credential found", mesmo com o seu login ainda salvo. A GitHub CLI do próprio Ubuntu é antiga demais para repassar esse login. O update também parou do mesmo jeito nesse caso.

Agora o `zurg update` também usa a GitHub CLI que os instaladores mantêm na pasta `bin`, ao lado do zurg. Um login que a GitHub CLI salvou sem keyring passa a funcionar mesmo quando a própria CLI já foi removida. Quando ainda assim não encontra nada, ele mostra o único comando que resolve o problema. Rode o update do instalador uma vez, e todo `zurg update` seguinte faz login sozinho.

## Muitos links antigos do Real-Debrid falhando ao mesmo tempo não é mais chamado de outage {#many-old-real-debrid-links-failing-at-once-is-no-longer-called-an-outage}

Os links do Real-Debrid param de funcionar alguns meses depois de criados, então os releases adicionados por volta da mesma época também param de tocar por volta da mesma época. Quando mais de cinco deles falhavam em uma mesma passada de reparo, o zurg registrava "suspected provider-wide outage" e segurava o reparo de todos, exceto cinco. Com isso, um lote grande ficava quebrado por muito mais tempo e parecia que o Real-Debrid estava fora do ar. Agora o zurg primeiro pede ao Real-Debrid um release na mesma conta que ainda toca. Se ele tocar, os links que falharam são simplesmente antigos e todos os releases são reparados normalmente. Só quando o Real-Debrid também recusa links que funcionam é que o zurg trata isso como uma queda e espera.

## Os links de sessão do Emby no painel abrem o painel do Emby {#the-dashboards-emby-session-links-open-embys-dashboard}

The links "active sessions" and "transcodes" on the dashboard's Emby panel opened `/web/#/dashboard`, which is Jellyfin's address for that page, and Emby ficava parado na tela de abertura para sempre. Both links now open `/web/index.html#!/dashboard`, the address Emby uses itself. The Jellyfin panel's links are unchanged.

## Um .nfo ausente não envia mais uma release do Usenet para o repair {#a-missing-nfo-no-longer-sends-a-usenet-release-to-repair}

Posts antigos da Usenet costumam perder o .nfo primeiro, enquanto todos os arquivos de vídeo e as partes dos compactados continuam lá. O zurg tratava isso como dano em toda a release. Ele começava um reparo sempre que encontrava um desses .nfo, e isso se repetia depois de cada reinício. Os reparos de verdade ficavam esperando atrás de centenas de reparos desnecessários. Algumas releases que tocavam sem problema eram marcadas como irreparáveis, e apagar o .nfo era a única forma de voltar atrás.

Um .nfo ou outro arquivo pequeno que esteja faltando ao lado do vídeo agora aparece como vazio e não pede nenhum reparo. Ele também não marca mais a release como irreparável. Um vídeo danificado pode ser reparado de novo quando o .nfo ao lado dele não existe. As releases que já estavam marcadas como irreparáveis desse jeito são verificadas de novo em cerca de um dia e voltam sozinhas.

## Arquivos do Usenet não tocam mais silêncio onde um servidor enviou o artigo de outro upload {#usenet-files-no-longer-play-silence-where-a-server-sent-another-uploads-article}

Alguns servidores de notícias (Usenet) respondem a um pedido de um artigo do seu
arquivo com um artigo de outro upload que tem o mesmo número. O zurg só percebia
isso quando o outro upload tinha menos artigos que o seu arquivo. Em arquivos
menores, como volumes de RAR e episódios curtos, ele pegava o artigo errado e
tocava silêncio nesse trecho. O log chamava isso de `an internal mapping failure in zurg`
e dizia que o offset `falls between two articles that are both present and neither
covers`. Agora o zurg também confere o tamanho do arquivo que cada artigo informa.
Ele recusa um artigo de outro arquivo e pede o artigo certo às suas outras contas
de Usenet. Artigos que uma versão antiga já tinha salvo no cache de artigos também
são recusados. Com uma única conta, o trecho ainda toca como silêncio. Agora o log
diz que um servidor enviou o artigo de outro arquivo, em vez de culpar o zurg.

## As conexões do Usenet voltam à velocidade total depois que outro app para de usar a conta {#usenet-connections-come-back-at-full-speed-after-another-app-stops-using-the-account}

Se o seu provedor de news alguma vez recusou o zurg por ter conexões demais, por exemplo enquanto outro programa ou um zurg anterior ainda estava usando algumas, o zurg continuava abrindo conexões uma por segundo enquanto estivesse rodando, mesmo depois que a vaga voltava. Depois de cada período de calmaria, uma rajada de downloads recomeçava a partir das duas conexões já abertas. Assim, uma conta grande levava mais de um minuto para voltar à velocidade máxima, e as importações ficavam na fila atrás dela, com "waited 5s for a connection (queued for the account's allowance)" no log de depuração. Agora, assim que o provedor aceitar uma conexão de novo e passar um minuto sem nova recusa, o zurg abre de imediato tudo o que precisa.

## O log de depuração informa quando um fetch espera por uma conexão com vários servidores de notícias configurados {#the-debug-log-says-when-a-fetch-waits-for-a-connection-with-several-news-servers-configured}

Com um único servidor de Usenet, um fetch que ficava mais de cinco segundos esperando por uma conexão deixava uma linha de debug avisando isso. Com dois ou mais servidores, essa linha nunca aparecia, então adicionar um segundo servidor fazia a linha sumir, mesmo que a espera tivesse parado. Agora a linha também aparece em configurações com vários servidores e informa os nomes dos servidores que o fetch estava esperando.

## Um grab do Usenet sem arquivos de repair e com o primeiro artigo morto falha na hora {#a-usenet-grab-with-no-repair-files-and-a-dead-first-article-fails-at-once}

A release posted sem arquivos PAR2 cujo primeiro artigo tinha sumido de todos os servidores de notícias ficava parado por cinco minutos até que o Radarr ou o Sonarr ficassem sabendo que tinha falhado, esperando um reparo que não tinha de onde reparar. Agora o zurg vê que não há dados de recuperação e informa que o grab falhou na hora, então o cliente coloca o release na blocklist e segue em frente.

## Um grab do Usenet que o repair corrigiu não é mais marcado como falho cinco minutos depois {#a-usenet-grab-that-repair-fixed-is-no-longer-reported-failed-five-minutes-later}

Quando um download estava faltando alguns artigos e os arquivos PAR2 conseguiam reconstruí-los, o zurg reparava o conteúdo. Mas um read-ahead em execução durante o reparo podia pedir os artigos faltantes de novo e receber uma recusa logo depois que o reparo terminava. Essa recusa colocava o release de volta na lista de danificados, então o download ficava retido por cinco minutos e depois era marcado como falho. Aí o Radarr ou o Sonarr colocava na lista de bloqueio um release que tocava normalmente. Uma recusa para um artigo que o reparo já reconstruiu não é mais considerada dano.

## Downloads atualizados que vieram com um .nfo ou legendas também são apagados {#upgraded-downloads-that-came-with-an-nfo-or-subtitles-are-deleted-too}

Com `magic.allow_delete` ativado, um vídeo apagado que não estava dentro de um arquivo RAR era apagado sozinho. O `.nfo`, as legendas e o pôster postados ao lado dele mantinham o download na sua biblioteca. O NZB dele continuava em `nzbs/` e o torrent continuava na sua conta debrid. Cada upgrade de um download desse deixava um resto para trás. Agora o download inteiro é apagado assim que nada em `__magic__` o usa mais. Um download fica enquanto outro episódio dele ainda estiver na sua biblioteca ou ainda esperando na própria pasta para ser importado. Legendas que o Sonarr ou o Radarr importaram ao lado do vídeo também o mantêm até serem apagadas.

## Downloads do Usenet substituídos ou com falha não se acumulam mais {#replaced-and-failed-usenet-downloads-no-longer-pile-up}

Com `magic.allow_delete` ativado, um episódio ou filme excluído que veio de um arquivo RAR era apenas escondido. O download de origem continuava na biblioteca e o seu NZB ficava em `nzbs/` para sempre. Ao atualizar episódios individuais para um pacote de temporada, sobrava um desses para cada episódio.

Agora o download inteiro é excluído assim que nada em `__magic__` usa mais ele. Um download continua existindo enquanto outro episódio do mesmo arquivo ainda estiver na sua biblioteca. Ele também continua existindo enquanto a própria pasta tiver algo para importar.

O Sonarr e o Radarr pedem que os arquivos de um download com falha sejam excluídos quando o removem. O zurg mantinha o NZB mesmo assim. Agora ele o exclui quando nada foi importado desse release. Um download que terminou e foi importado mantém o seu NZB como antes, porque o arquivo importado continua sendo reproduzido a partir dele.

## O zurg agora informa quando a biblioteca terminou de carregar {#zurg-now-says-when-the-library-has-finished-loading}

Docker considera o zurg saudável assim que ele está rodando. Uma biblioteca grande pode continuar carregando por mais de uma hora depois disso. Enquanto isso, as pastas no mount falham com `Input/output error` o tempo todo, e parece que a instalação está quebrada. O novo endereço `/ready` diferencia os dois casos. Ele responde 503 até a biblioteca terminar de carregar e 200 depois que ela carregar. Não precisa de senha. Dentro do container, `/app/healthcheck.sh --ready` verifica a mesma coisa. A verificação de saúde do próprio container ainda só pergunta se o zurg está rodando. Assim, um primeiro carregamento longo não consegue fazer o container reiniciar nem atrasar um mount que depende dele. A verificação de saúde também lê agora a variável de ambiente `PORT`. Antes, um container que definia `PORT` era verificado na porta errada.

## A aquisição pode pular releases por palavras em seus nomes {#acquisition-can-skip-releases-by-words-in-their-names}

Defina `exclude_words` no bloco `acquisition:` e o zurg nunca pega um lançamento cujo nome tenha uma dessas palavras. `exclude_words: [DV, HDR10+]` mantém Dolby Vision e HDR10+ longe de uma TV que não consegue reproduzi-los, e ainda pega 4K com HDR comum. Funciona para a watchlist do Plex, Seerr, Radarr e Sonarr, e para Usenet e torrents. Só palavras inteiras. `DV` não pega `DVDRip` nem um filme chamado Adventures. `DV`, `DoVi` e `Dolby Vision` significam a mesma coisa, assim como `HDR10+` e `HDR10Plus`. O Radarr e o Sonarr nunca são consultados sobre um lançamento excluído.

## O Radarr e o Sonarr podem pegar primeiro a melhor qualidade do perfil {#radarr-and-sonarr-can-take-the-profiles-best-quality-first}

zurg normalmente pega o release permitido que é mais rápido de verificar. Para um filme, geralmente é um WEB-DL 1080p. A passada de upgrade então avança em direção ao cutoff do seu perfil. Séries pegam um season pack antes de episódios avulsos. Assim, um pack 1080p poderia preencher uma temporada mesmo quando havia episódios em 2160p disponíveis. Defina `best_first: true` em `acquisition:` e a primeira captura passa a seguir o seu perfil de qualidade do Radarr ou Sonarr. A melhor resolução permitida por ele vem primeiro. Qualquer coisa igual ou acima do cutoff conta como boa o suficiente. Quando um release acaba não estando mais disponível, o zurg vai descendo pelo perfil. O primeiro arquivo pode demorar mais para chegar porque os melhores releases costumam ser posts grandes com várias partes. Essa opção vem desligada por padrão.

## Resultados de torrent não atropelam mais os NZBs onde nenhuma conta aceita torrents {#torrent-results-no-longer-crowd-out-nzbs-where-no-account-takes-torrents}

Em uma instância com um provedor de NZB e sem conta de debrid que aceite torrents, a aquisição ainda pesquisava seus indexadores Torznab, e cada torrent encontrado consumia uma das três tentativas que um episódio ou pacote de temporada recebe por tentativa. Com `prefer: torrents`, ou com torrents 4K classificados acima de um NZB 1080p, os NZBs nunca eram testados e o episódio falhava. Agora os indexadores Torznab são ignorados nesse caso, com uma linha no log informando isso, e um release que a instância não tem onde colocar não conta como tentativa. Os filmes também deixam de perguntar ao Radarr sobre esses torrents.

## A aquisição não conta mais um NZB como concluído quando nada consegue tocá-lo {#acquisition-no-longer-counts-an-nzb-as-done-where-nothing-can-play-it}

Em uma instância com conta debrid e sem provedor de NZB, a aquisição ainda pesquisava seus indexadores Newznab, e um NZB que ela baixava era contado como concluído sem nenhuma verificação. Um título da watchlist do Plex podia sair da lista por causa de um arquivo que nada naquela instância consegue reproduzir. Agora os indexadores Newznab são ignorados nesse caso, com uma linha no log informando isso, e um NZB nunca é contado como concluído em uma instância sem provedor de NZB.

## Uma release sem nada para tocar é informada uma vez, e não todos os dias {#a-release-with-nothing-left-to-play-is-reported-once-instead-of-every-day}

Quando todos os arquivos reproduzíveis de um lançamento tinham sido apagados, o zurg avisava todo dia que ele "has no playable file that still reads". Uma biblioteca com cem desses lançamentos registrava cem desses avisos por dia, para lançamentos que ninguém tinha mexido. Agora o aviso aparece uma única vez, e o lançamento só é verificado de novo quando algo nele muda. Restaurar um arquivo ainda o traz de volta imediatamente.

## Releases quebradas no AllDebrid e no TorBox voltam quando os arquivos ainda tocam {#broken-releases-on-alldebrid-and-torbox-come-back-when-the-files-still-play}

Uma release que só está disponível no AllDebrid, TorBox, Premiumize, Offcloud ou Debrid-Link
poderia ficar quebrada e escondida por semanas enquanto a conta ainda a estava entregando. O Repair não readiciona releases
nesses serviços por conta própria, porque eles removem conteúdo de propósito, e
nada mais verificava se os arquivos tinham voltado a funcionar. Agora o Repair
pergunta à conta, uma vez por dia, se os arquivos de uma release quebrada ainda tocam,
e recoloca as que tocam, sem adicionar nada. Qualquer coisa que a conta
tenha removido de fato ainda precisa do botão Repair. A visão de reparo do MCP
diz a mesma coisa, em vez de dizer que nenhuma verificação automática vai agir sobre ela.

## Grabs que o TorBox enfileira para uma vaga livre aparecem como na fila e terminam {#grabs-torbox-queues-for-a-free-slot-show-as-queued-and-finish}

Quando todos os slots de download de uma conta do TorBox estavam ocupados, o TorBox colocava os novos pedidos do Sonarr e do Radarr na fila dele, e o zurg perdia o rastro deles. O pedido aparecia como fetching metadata por cerca de dez minutos e depois como erro, então o Sonarr e o Radarr descartavam o pedido. Quando o TorBox baixava o arquivo depois, ninguém importava. Agora o zurg acompanha o pedido enfileirado até o TorBox começar a processá-lo e continua até o download terminar. Enquanto espera, ele aparece como queued, e o timeout de sem progresso só começa a contar depois que o TorBox iniciar o pedido.

## Você pode pesquisar uma release na página `__magic__` {#you-can-search-for-one-release-on-the-__magic__-page}

Em uma biblioteca que o Sonarr ou o Radarr organiza, cada importação deixa para trás uma pasta de trabalho oculta, e a página `__magic__` lista apenas as primeiras mil linhas armazenadas. O release que você procurava normalmente não estava entre elas, então os botões Unhide e Reset dele ficavam fora de alcance, e a nota embaixo da lista apontava para data/magic.json. Editar esse arquivo enquanto o zurg está rodando não funciona: o zurg o grava de novo a partir da memória quando para, então as linhas voltam depois de um reinício.

As linhas armazenadas e as páginas dangling agora têm uma caixa de busca. Digite o nome de um release, um caminho do seu mount ou um hash, e todas as linhas armazenadas sobre esse release aparecem com os botões, não importa o tamanho da tabela.

Também é assim que você traz de volta um release que está em `__all__`, mas nunca aparece em `__magic__/__all__.` Apagar um release e adicioná-lo de novo, ou reinseri-lo a partir do DMM, mantém o hash dele, então ele volta com tudo o que o `__magic__` tinha armazenado sobre ele, inclusive a pasta de trabalho que foi apagada depois da importação. Pesquise por ele e clique em Unhide na linha de release-tombstone dele.

## O `__magic__` no Windows deixa de crescer o journal para sempre {#__magic__-on-windows-stops-growing-its-journal-forever}

On Windows, zurg logged `cannot truncate data\magic.journal ... Access is
denied.` every time it tried to tidy the file where `__magic__` records your
moves and folders. The file was never emptied, so it grew with every change
and every start read all of it again. After a few thousand changes in one run,
each further change also rewrote the whole saved layout. zurg now empties it
on Windows as it always did elsewhere, and the first start after updating
clears what has piled up. If tidying ever fails, zurg tries again after more
changes instead of on every one.

## Restaurar um arquivo pelo MCP recoloca a release de volta na hora {#restoring-a-file-over-mcp-puts-its-release-back-right-away}

Restaurar um arquivo com a ferramenta MCP `zurg_release_file_restore` trazia o arquivo de volta, mas deixava o release marcado como quebrado e dentro de `__unplayable__` até a próxima atualização da biblioteca. Agora ela faz o que o botão Restore do gerenciador de torrents faz: o release sai de `__unplayable__`, volta para as suas pastas com os arquivos .strm e fica salvo assim. Como antes, ela não pede para o Plex, o Jellyfin ou o seu script on_library_update fazerem uma nova varredura.

## Traz de volta os arquivos que um repair com falha escondia {#bring-back-files-a-failed-repair-hid}

Versões antigas marcavam um arquivo como excluído quando um reparo desistia de uma conta, mesmo quando outra conta ainda conseguia reproduzi-lo, e o lançamento então sumia de todas as pastas. O gerenciador de torrents ganhou um novo filtro "Deleted, still served" que lista lançamentos sem nada para reproduzir, mas cujo arquivo excluído ainda está disponível em alguma conta. Segure o botão Restore dele e o zurg verifica o link de cada arquivo e coloca de volta nas pastas os que ainda reproduzem, igual a clicar em Restore em cada arquivo.

O zurg não faz isso sozinho. Um arquivo que você excluiu de propósito fica guardado exatamente do mesmo jeito, então confira a lista e restaure só o que você não excluiu. Lançamentos que ainda reproduzem algo ficam de fora, já que excluir um extra ou um episódio é a exclusão intencional mais comum.

## A aquisição olha além da primeira página dos resultados de busca {#acquisition-looks-past-the-first-page-of-search-results}

A aquisição costumava ler apenas a primeira página que um indexador retornava. Com o DMM, que retorna dez resultados por página com os maiores primeiro, um limite de tamanho podia remover todos eles, e o filme falhava com "no eligible releases" a cada poucas horas, mesmo com releases menores nas páginas seguintes. Agora ele continua pedindo mais páginas até ter releases suficientes que caibam nos seus limites, até dez páginas. Para séries, um episódio que a busca da temporada não encontrou, normalmente um mais antigo quando o episódio mais novo ocupa os resultados, agora é buscado sozinho.

## Arquivos mortos nas pastas de filmes e séries do `__magic__` agora saem da lista para que o Radarr e o Sonarr percebam {#dead-files-in-__magic__-movie-and-show-folders-now-drop-out-so-radarr-and-sonarr-notice}

A arquivo que o Radarr ou o Sonarr tinha importado para uma pasta dentro de `__magic__` continuava aparecendo com o tamanho completo depois que o release parou de funcionar. Por isso, uma varredura ainda o encontrava e o filme ou episódio nunca voltava para a lista de desejados. Agora ele sai da pasta no mesmo momento em que sai de todas as outras listagens: assim que o reparo não consegue mais trazê-lo de volta, ou um dia depois de quebrar, quando o reparo está desligado. Na próxima varredura ele é marcado como ausente e a aquisição procura um substituto. Se o arquivo voltar a funcionar, ele reaparece no mesmo lugar.

## O Season Fix organiza pacotes de várias temporadas e extras numerados {#season-fix-sorts-multi-season-packs-and-numbered-extras}

Season Fix agora lê sozinho a temporada que cada arquivo indica, então um pack como `Full Metal Panic S2 - 01`, `Bakuman II - 01`, `KonoSuba 2 - 01` ou `Demon Slayer Mugen Train Arc - 01` coloca cada episódio em sua própria temporada, em vez de deixar o Plex empilhar todos na temporada 1. Lotes nomeados em romaji ou com algum sufixo, como `Sergeant Keroro 001-358` ou `Dragon Ball Z COMPLETE`, são reconhecidos quando os arquivos compartilham o mesmo título, e nomes com sublinhados, `Ep01`, `1.01.` ou um número dentro do título do episódio são interpretados como deveriam ser.

Extras numerados como `Special 01`, `OVA 01`, `- 11 (OVA)` e recaps `24.5` antes ficavam em cima de um episódio real como uma segunda versão, e o Play podia escolher o extra. Agora eles são renomeados com o sufixo `-other` do Plex, para aparecerem como extras.

## Um link morto do Real-Debrid não segura mais uma varredura da biblioteca por minutos {#a-dead-real-debrid-link-no-longer-holds-a-library-scan-for-minutes}

Quando o Real-Debrid continua respondendo um arquivo com o mesmo link revogado, o zurg espera um pouco por alguns minutos, já que isso é normal logo depois que um download é removido. Um arquivo que ainda for recusado dessa forma depois de cinco minutos agora é tratado como link quebrado e enviado para reparo, em vez de pedir para o usuário voltar mais tarde. Antes, um único arquivo morto podia travar uma varredura do Plex por cerca de dez minutos.

## Jobs do Usenet com falha ou travados podem ser limpos na página `__magic__` {#failed-and-stuck-usenet-jobs-can-be-cleared-from-the-__magic__-page}

Um job Failed ou Stuck na lista do SABnzbd ficava lá para sempre depois que o Sonarr ou o Radarr deixava de usar o zurg como cliente de download. Reiniciar não resolvia. A única saída era apagar `data/sabnzbd-jobs.json` manualmente. A página de jobs do `__magic__` agora tem um botão **Clear** em cada job Failed ou Stuck, e um botão acima da lista que limpa todos de uma vez. Segure até a barra encher.

Jobs Queued e Completed nunca são tocados. O NZB do job também é apagado, a menos que alguma importação em `__magic__` ainda use aquele release.

## O addon do Stremio informa quando precisa de https {#the-stremio-addon-says-when-it-needs-https}

Stremio só carrega um addon via http simples no computador onde ele roda. Em uma TV, um celular ou outro computador, um endereço http falha com "failed to load manifest", mesmo quando o aparelho consegue acessar o zurg. A página de configuração agora avisa isso ao lado da URL do addon sempre que você a abriu por http em um endereço desse tipo. O guia do Stremio mostra três formas de colocar o zurg atrás de https: Tailscale Serve, seu próprio reverse proxy e um túnel da Cloudflare.

## O Plex pega um filme ou episódio assim que o Radarr ou o Sonarr o importa para o `__magic__` {#plex-picks-up-a-movie-or-episode-as-soon-as-radarr-or-sonarr-imports-it-into-__magic__}

Depois que o Radarr ou o Sonarr moveu um arquivo para uma pasta dentro de `__magic__`, o zurg pediu ao Plex para escanear o próprio arquivo. O Plex só escaneia pastas, então respondeu como se tudo estivesse certo e não adicionou nada, e o filme continuou faltando até o próximo scan agendado do Plex. Agora o zurg pede ao Plex para escanear a pasta onde o arquivo foi parar. O mesmo vale para o arquivo que um upgrade substitui, para que a versão antiga saia da biblioteca, e também para os endpoints de scan manual, a ferramenta MCP `zurg_plex_scan_releases`, os scans depois de um rename ou da exclusão de um arquivo, e os caminhos passados para `on_library_update`.

## A página Manage lista releases duplicadas e qual delas o Radarr ou o Sonarr usa {#the-manage-page-lists-duplicate-releases-and-which-one-radarr-or-sonarr-uses}

Uma atualização deixa para trás a release que foi substituída na sua biblioteca, e buscas em indexadores diferentes podem deixar mais de uma cópia de um filme ou de uma temporada. A nova visualização Duplicates na página Manage agrupa as releases que têm o mesmo filme ou os mesmos episódios e mostra qual delas o Radarr ou o Sonarr está usando. O zurg descobre isso pelo local onde o arquivo está em `__magic__`, não pelos nomes das releases. Para uma temporada, ele lista cada episódio que mais de uma release tem e qual release contém o arquivo do Sonarr, então um pacote do qual o Sonarr pega só alguns episódios ainda aparece como em uso. Qualquer outra release é marcada como "No reference found" ou "Unknown", com o motivo. Selecione as que você quer remover, e o zurg consulta o Radarr e o Sonarr de novo antes de apagar, deixando de fora qualquer coisa que tenha entrado em uso desde então. Nada é apagado automaticamente.

## Os slots de download ocupados do TorBox são contados do jeito que o TorBox os conta {#torboxs-busy-download-slots-are-counted-the-way-torbox-counts-them}

Antes que o reparo ou a primeira reprodução adicione um torrent ao TorBox, o zurg verifica se a conta tem uma vaga de download livre. Antes, ele contava todo torrent que não estava totalmente baixado. Isso deixava de fora os torrents em seeding, que o TorBox conta contra o seu plano por até 30 dias, e contava torrents cujo conteúdo já tinha expirado, que não ocupam vaga nenhuma. Alguns torrents expirados numa biblioteca já bastavam para o reparo ficar esperando, como se todas as vagas estivessem ocupadas.
Agora o zurg conta exatamente os torrents que o TorBox marca como ativos.

## O TorBox pode fazer seed para trackers privados {#torbox-can-seed-for-private-trackers}

A new setting, `tb_seed_torrents`, decide se os torrents que o zurg adiciona no TorBox vão fazer seed. Ele fica em `never` a menos que você mude, então nada muda para quem não mexer nele. Coloque em `always` se um tracker privado precisar do seu ratio, ou em `auto` para deixar a configuração de seeding da sua conta TorBox decidir. Dá para mudar no seção Health & Repairs do dashboard e ela vale a partir da próxima adição.

Um torrent que está fazendo seed ocupa uma das vagas ativas do seu plano TorBox enquanto estiver em seed, até 30 dias no Pro. Quando torrents em seed preenchem todas as vagas, novos grabs e reparos nessa conta precisam esperar até que uma vaga seja liberada.

## Conjuntos RAR com volumes nomeados fora de ordem agora tocam {#rar-sets-whose-volumes-are-named-out-of-order-now-play}

Uma release cujos volumes RAR têm cada um um nome diferente, como um nome aleatório por volume ou `Movie 2026 part1.rar`, antes aparecia como um arquivo por volume. O primeiro da lista mostrava o filme, mas deixava de funcionar depois da primeira parte, e os outros não mostravam nada. Agora o zurg lê dentro de cada volume a posição que ele ocupa e junta o conjunto de novo, o que antes se resolvia renomeando os volumes para `part001.rar` em diante, feito à mão. Isso só acontece quando os volumes se numeram formando um conjunto completo. Se um estiver faltando ou dois reivindicarem a mesma posição, a release fica como estava e o log diz o motivo. Arquivos compactados cujos volumes foram postados fora de ordem também funcionam agora.

## Uma varredura do Plex que ainda está analisando não é mais marcada como travada {#a-plex-scan-that-is-still-analysing-is-no-longer-reported-as-stuck}

Durante a análise dos arquivos encontrados, o Plex mantém o progresso e a pasta atual de uma varredura da biblioteca sem mudanças. Isso pode levar bastante tempo em uma biblioteca grande ou remota. Antes, o painel chamava isso de varredura travada e sugeria reiniciar o Plex no meio do processo. Agora o zurg escuta o feed de atualizações do próprio Plex e conta os itens que o Plex informa estar processando. Assim, só é sinalizada uma varredura que realmente parou.

## Uploads de torrent somente em cache preservam o add recusado em provedores com limite de taxa {#cached-only-torrent-uploads-preserve-the-refusing-add-on-rate-paced-providers}

Um `.torrent` enviado no modo somente-em-cache agora chega à rejeição de adição do TorBox mesmo quando o limite horário de adições passa pelo backend. Uma falta em cache não cria nenhuma transferência e não ocupa nenhum slot ativo; mesmo assim, ela gasta uma das 60 adições sem cache por hora do TorBox. As adições comuns continuam enviando o arquivo original. O guia do qBittorrent agora lista todos os seis provedores de upload de torrent e explica os caminhos distintos de somente-em-cache do Debrid-Link e do TorBox.

## Um arquivo que você apaga enquanto ele está sendo restaurado continua apagado {#a-file-you-delete-while-it-is-being-restored-stays-deleted}

Apagar um arquivo ou release enquanto uma restauração ainda está verificando o link agora espera essa verificação terminar e depois prevalece. Um refresh da biblioteca que já estava em andamento não consegue mais trazer de volta um release que você acabou de apagar.

## Uma busca longe dentro de um arquivo compactado não trava mais o leitor {#a-seek-far-into-a-compressed-archive-no-longer-hangs-the-reader}

Um arquivo dentro de um RAR ou zip compactado só pode ser decodificado a partir do início, então uma leitura perto do fim de um arquivo grande costumava esperar o arquivo inteiro sem nenhuma resposta. O Plex podia ficar esperando por essa leitura por mais de uma hora, o que era tempo suficiente para travar o banco de dados dele. Agora o zurg responde em até 20 segundos, mantém o progresso que já fez e prepara o fim do arquivo em segundo plano, então a próxima leitura desse trecho é imediata.

## Recusas do Real-Debrid seguem as regras de nome de arquivo publicadas {#real-debrid-refusals-follow-the-published-filename-rules}

Quando o Real-Debrid recusa adicionar de novo um release durante o reparo, o zurg agora verifica o nome do release e os nomes dos arquivos dele contra as regras de nomes publicadas. Um release bloqueado por essas regras é marcado como infrator de forma definitiva. Qualquer outra recusa é tratada como o Real-Debrid desacelerando as adições, e o release continua na fila para a próxima rodada de reparo, em vez de ser aposentado.

## Restaurar um arquivo o devolve ao lugar certo imediatamente {#restoring-a-file-puts-it-back-where-it-belongs-straight-away}

A ação Restore na página de gerenciamento de um release agora move o release de volta para os diretórios certos, salva o estado recuperado e escreve o arquivo STRM assim que o arquivo é verificado e está ok. Um arquivo restaurado não fica mais no diretório de não reproduzíveis até o próximo refresh do provedor, e um release cujo último arquivo quebrado foi restaurado não é mais reportado como quebrado depois de um restart. Arquivos que você apagou continuam apagados até você restaurá-los.

## Rejeitar artigos Usenet estrangeiros antes de servir os bytes {#reject-foreign-usenet-articles-before-serving-bytes}

Rejeite artigos Usenet de mesmo número cujo total positivo do yEnc seja menor que o maior número listado no NZB, incluindo os caminhos de cache persistido e progressivo, para que os fallbacks válidos de conta forneçam os bytes.

## Preservar a classificação de recusa do RD baseada em evidências {#preserve-evidence-backed-rd-refusal-classification}

Trate em silêncio as respostas 451 do addMagnet como recusas de release, a menos que haja evidência de limitação local da conta que abranja toda a operação, e preserve os erros temporários durante o reparo.

## Esclarecer as janelas de leitura de arquivos quebrados expirados {#clarify-expired-broken-file-read-windows}

Relate uma janela de repetição de leitura de arquivo quebrado que expirou, sem dizer que o reparo desistiu.

## Expor a saúde registrada do arquivo no MCP {#expose-recorded-file-health-in-mcp}

Exponha as contagens de saúde registradas por arquivo nas visões de release do MCP e mantenha as tabelas de arquivos lazy seguras para inspeção, sem afirmar que um estado de ciclo de vida é uma verificação de serving ao vivo.

## Lidar com operações de sidecar duplicadas {#handle-duplicate-sidecar-operations}

Reconhecer respostas tipadas de fonte ausente vindas de aliases WebDAV duplicados, mantendo os erros reais de falha total e de permissão.

## Um novo download com o mesmo nome é reparado em vez de falhar {#a-re-grab-under-the-same-name-is-repaired-instead-of-failed}

Pegar um NZB de novo com um nome que o zurg já tem não verifica nem repara mais a cópia antiga enquanto a nova está sendo lida. O download espera pelo novo arquivo, então uma release com um artigo faltando que o PAR2 consegue reconstruir é reparada e concluída, em vez de ser marcada como falha.

## Falhas de reparo não se passam mais por exclusões feitas pelo usuário {#repair-failures-no-longer-masquerade-as-user-deletions}

Falhas de reparo automático agora marcam apenas a fonte do provedor que falhou como quebrada, preservando as cópias alternativas saudáveis e permitindo que as próximas atualizações do provedor restaurem a visibilidade dos arquivos.

## Torrents sem um id do IMDb são identificados pelo nome do release através do DMM {#torrents-without-an-imdb-id-are-identified-by-release-name-through-dmm}

Com o `dmm_metadata_secret` definido, o job de IMDb não precisa mais de uma chave do OpenSubtitles. Torrents sem id, ou que tenham apenas o marcador de "não encontrado" do OpenSubtitles, são identificados na inicialização a partir de uma tag `imdb-tt…` no nome deles, ou então pelo resolver do DMM, que só responde quando um único título bate exatamente. Romanizações de fansub como "Kaijuu 8-gou" são resolvidas pelos aliases do DMM para Kaiju No. 8, e um nome que vários programas compartilham é deixado de lado. Um torrent que o DMM não consegue nomear mantém o id vazio, para que um match no Plex ainda possa preenchê-lo.

## Um filme do Radarr que nenhum indexador conhece pelo id é buscado pelo nome {#a-radarr-movie-that-no-indexer-knows-by-id-is-searched-for-by-name}

Muitos posts de Usenet são indexados sem id do IMDb ou TMDB. O zurg buscava um filme do Radarr só pelo id, então um documentário que nenhum indexador encontrava pelo id falhava com "no eligible releases", enquanto a busca do próprio Radarr pelo nome encontrava uma release limpa. Quando a busca por id não encontra nada para aproveitar, o zurg agora também busca pelo título e pelo ano, e o parser do próprio Radarr continua decidindo se cada resultado é o filme. Só uma busca por id que não encontrou absolutamente nada é seguida de uma busca por nome: um filme que a busca por id encontra é indexado por id, e pedir de novo pelo nome só traria os mesmos posts.

## NZBs encontrados pelo Prowlarr podem ser baixados {#nzbs-found-through-prowlarr-can-be-downloaded}

Prowlarr entrega todo NZB do Usenet redirecionando para o indexador, e não permite desativar isso. O zurg só seguia um redirecionamento para o mesmo host, então, com indexadores configurados pelo Prowlarr, toda aquisição de NZB escolhida falhava com "answered 301 Moved Permanently" e nada era adquirido. Agora o redirecionamento é seguido. A chave de API do próprio link continua nunca chegando ao outro host, e um redirecionamento de HTTPS para HTTP continua sendo recusado.

## Um indexador que recusa por horas não trava mais a aquisição {#an-indexer-that-refuses-for-hours-no-longer-stalls-acquisition}

Prowlarr responde a uma busca em um indexador que ele desativou com `429` e um `Retry-After` de muitas horas. O zurg esperava dois minutos e tentava de novo, três vezes, então cada busca gastava seis minutos naquele único indexador. A aquisição desistia de cada título depois de cinco tentativas e descartava tudo o que os outros indexadores já tinham respondido, então nada era adquirido até o indexador voltar. Agora, um indexador que pede para ser deixado em paz por mais de dois minutos é pulado até o horário que ele informou, e as buscas seguem nos outros.

## Um título excluído após a aquisição é buscado novamente {#a-title-deleted-after-acquisition-is-searched-for-again}

Quando um arquivo que o zurg tinha adquirido para o Sonarr ou o Radarr era apagado, seja porque não era a versão desejada ou por qualquer outro motivo, e o título voltava para a lista de faltantes, o zurg respondia "completed without a search, the release was already held" e nunca mais procurava por ele. Agora o zurg verifica primeiro a pasta da temporada ou do filme em `__magic__`. Um episódio ou filme cujo vídeo não está mais lá é procurado de novo. Um cujo vídeo ainda está lá, o que acontece enquanto o Sonarr ainda não fez a nova varredura, é deixado em paz.

## "Scan in Plex" na lista de não detectados espera pelo resultado {#scan-in-plex-on-the-undetected-list-waits-for-the-result}

The botão de segurar para escanear na lista de não detectados recarregava a página dois segundos depois de ser pressionado, enquanto a correspondência com o Plex ainda não tinha começado. Em uma biblioteca grande essa correspondência leva minutos, então a lista sempre voltava sem mudanças e o botão parecia não fazer nada. Agora o botão mostra que a correspondência está em andamento, espera ela terminar, informa quantas releases foram correspondidas e só então recarrega a página.

## Um release cujo nome termina em espaço é associado ao Plex {#a-release-whose-name-ends-in-a-space-is-matched-to-plex}

A release whose file name has a space before the extension, such as
`... [Hurtom] v2 .mkv`, gets a directory whose name ends in a space. Plex found
it, but zurg could never match it, so it stayed on the undetected list after
every scan. Agora ele é reconhecido.

## Excluir um arquivo na página de gerenciamento mantém sua posição {#deleting-a-file-on-the-manage-page-keeps-your-place}

Excluir, restaurar, renomear ou forçar a exibição de um arquivo na página de gerenciamento de um lançamento costumava recarregar a página no topo, então limpar um pacote grande significava rolar a tela para baixo de novo após cada clique. Agora a página volta na linha desse arquivo e o destaca.

## O painel aceita um caminho de montagem digitado entre aspas {#the-dashboard-takes-a-mount-path-typed-with-quotes}

A caminho de montagem colado no painel do jeito que o config.yml escreve, como `"/Users/me/Plex Media Server/ZurgMount"` ou `'Z:\'`, era recusado com "mount path should be absolute", porque as aspas eram lidas como parte do caminho. Agora o painel remove um par de aspas que estiver combinado em volta do valor e salva o caminho sem elas.

## Uma falha ao buscar a watchlist do Plex informa o motivo {#a-failed-plex-watchlist-fetch-says-why}

When o Plex recusa um pedido da watchlist, o log agora mostra o motivo dado pelo próprio Plex, como `unexpected status: 401: Invalid token`, em vez de só o status. Se você ainda vir `Failed to fetch watchlist: ... unexpected status: 400`, essa mensagem vem de uma versão anterior a agosto. Atualize o zurg: as versões atuais pedem a watchlist em páginas que o Plex aceita.

## Um release danificado demais para a memória do reparo falha de imediato {#a-release-too-damaged-for-repairs-memory-fails-at-once}

Quando um release da Usenet está faltando mais do que o reparo PAR2 consegue manter na memória de uma só vez, o zurg agora avisa isso e para, e o Sonarr ou o Radarr escolhem outro release. Antes, ele mantinha o grab em espera, tentava de novo a cada poucos minutos e verificava o release inteiro a cada vez para receber a mesma resposta. Danos que ainda não foram confirmados como perdidos, como artigos que um servidor não respondeu, continuam sendo tentados novamente.

## A configuração passa por uma config vazia e avisa quando o prompt do token está oculto {#setup-gets-past-an-empty-config-and-says-when-the-token-prompt-is-hidden}

`zurg setup`, e os instaladores que o executam, se recusavam a continuar enquanto existisse um `config.yml` vazio, com um erro que terminava em branco. Agora um config vazio é substituído. Um config com conteúdo continua nunca sendo sobrescrito, e o erro agora informa qual arquivo é e como recomeçar do zero. O prompt do token avisa que o que você digitar ou colar fica oculto, o que antes parecia o terminal não aceitar a entrada. Um erro de digitação no `config.yml` agora é reportado em relação ao `config.yml`, e não a uma "outbound identity config" interna.

## Um servidor de notícias de backup agora preenche artigos que o servidor principal responde errado {#a-backup-news-server-now-fills-in-articles-the-main-server-answers-wrongly}

Alguns servidores de notícias respondem a um pedido de um artigo com um pedaço de um upload diferente. O zurg reconhecia o pedaço errado, mas nunca pedia o certo ao servidor de backup, então a falha aparecia como silêncio ou o arquivo não abria, mesmo com um servidor de backup que tinha o conteúdo. Agora o zurg pede ao próximo servidor, do mesmo jeito que o SABnzbd faz.

## Um release Usenet em RAR chega ao seu diretório sem precisar reiniciar {#a-rard-usenet-release-reaches-its-directory-without-a-restart}

Uma release postada como um conjunto RAR é organizada em diretórios pelos nomes dos seus volumes até que o arquivo seja aberto, e pelos arquivos que ela contém depois disso. Nada a reorganizava de novo quando o arquivo era aberto. Por isso, um diretório que procura um `.mkv` ou números de episódio não encontrava uma release RAR recém-baixada até que o zurg fosse reiniciado, e o Plex e o Jellyfin nunca a viam ali. Agora, a release vai para os diretórios certos assim que o seu arquivo é listado pela primeira vez.

## Um filme postado com nome aleatório recebe o nome do seu release {#a-movie-posted-under-a-random-name-is-named-after-its-release}

Alguns posts de Usenet dão ao filme um nome aleatório, como `eq5KVi5Y3iTwFEn1Nub8yPY9yd6oUzTu.mkv`, e repetem esse nome em todos os lugares do post que poderiam trazer o nome real. O zurg mantinha esse nome, então o Radarr e o Sonarr não tinham nada no nome do arquivo para se basear. Agora o zurg dá ao arquivo o nome do release, como o SABnzbd faz: só quando é claramente o único arquivo grande do release, só para arquivo de vídeo, e nunca para estrutura de disco ou arquivo compactado. Isso vale para os releases baixados daqui para frente; um que já está na biblioteca mantém o nome que tinha.

## Regras de tamanho agora se aplicam a arquivos dentro de arquivos compactados {#size-rules-now-apply-to-files-inside-archives}

Um filme do Usenet postado como um conjunto RAR é mostrado como os arquivos de dentro do arquivo.
Esses arquivos ignoravam as configurações `only_show_the_biggest_file` e `only_show_files_with_size_gte`/`_lte` de um diretório, então qualquer outra coisa que o post trouxesse continuava visível ao lado do filme. Muitos posts incluem uma imagem pequena com o nome do filme, uma folha de imagens com carimbo de tempo, e o Jellyfin usava isso como pôster. As configurações de tamanho agora se aplicam ao conteúdo dos arquivos da mesma forma que se aplicam a todos os outros arquivos.

## Releases Usenet cujo maior arquivo PAR2 passa de 512 MB podem ser reparados {#usenet-releases-whose-largest-par2-file-is-over-512-mb-can-be-repaired}

Quando uma release está faltando partes, o zurg reconstrói essas partes a partir dos próprios arquivos PAR2 da release. Ele se recusava a ler qualquer arquivo PAR2 maior que 512 MB, e em uma release grande esse arquivo guarda mais dados de reparo do que qualquer outro, e muitas vezes é o único que existe. Uma release assim não podia ser reparada, não importava quão pouco estivesse faltando, e o zurg continuava tentando de novo, baixando todos os seus arquivos PAR2 menores a cada vez antes de desistir. Agora o zurg lê um arquivo PAR2 de qualquer tamanho. Uma release com mais danos do que um reparo consegue guardar na memória é recusada assim que os danos são contados, antes de qualquer um dos seus arquivos PAR2 ser baixado.

## O Sonarr pode passar seus episódios faltantes para o zurg {#sonarr-can-hand-its-missing-episodes-to-zurg}

zurg agora também pode pegar a sua lista do Sonarr. Adicione uma fonte `sonarr` em
`acquisition.sources` com a URL e a API key do Sonarr. O zurg então trabalha nos
episódios que o Sonarr está procurando e nos arquivos de episódio que ele quer
atualizar. Ele pesquisa nos seus indexers e verifica se os servidores de news ainda
têm o release. Coloca cada episódio na pasta da temporada dentro de `__magic__` e pede
ao Sonarr para escanear a série de novo. O Sonarr não precisa de indexers nem de
download client para isso.

Uma temporada que está faltando por inteiro e já terminou de ser exibida pode vir como
um season pack só. Todo o resto vem episódio por episódio. Cada release passa primeiro
pelo parser do próprio Sonarr. Ele precisa ser da série certa e do episódio certo, e
precisa se encaixar no quality profile da série. Upgrades substituem só o episódio que
estão atualizando. Quando um episódio de uma temporada ainda não tem release, os outros
são colocados mesmo assim e o Sonarr escaneia de novo para eles. Séries diárias e de
anime são puladas por enquanto, com um aviso no log. O `docs/acquisition.md` cobre o
lado do Sonarr na configuração.

## A aquisição trabalha em muitos títulos ao mesmo tempo {#acquisition-works-on-many-titles-at-once}

Títulos de uma watchlist ou de um serviço de pedidos costumavam ser adquiridos um depois do outro, então uma lista longa levava tanto tempo quanto todos os seus títulos somados. Agora o zurg trabalha em até oito ao mesmo tempo, definido por `acquisition.concurrency`. Um título que aparece tarde na lista não espera mais os anteriores terminarem.

Um lançamento novo não fica mais parado por dois minutos antes de o zurg verificá-lo. O zurg verifica a cada segundo até o lançamento aparecer na biblioteca, por até um minuto e meio. Quando os servidores de notícias não têm mais um lançamento, o zurg passa direto para o próximo candidato em vez de tentar de novo cinco minutos depois. Verificar um lançamento também não precisa mais caber no tempo que sobrou da busca, então uma busca lenta em uma lista longa não atrasa mais os títulos em minutos. Atualizações de títulos que você já tem esperam até que os títulos que faltam da mesma lista estejam prontos, para que nunca disputem chamadas aos indexadores ou conexões com os servidores de notícias.

## Um release Usenet reparado com PAR2 continua reparado enquanto é lido {#a-usenet-release-repaired-with-par2-stays-repaired-while-it-is-read}

Quando alguns artigos de uma release somem dos servidores de notícias, o zurg os reconstrói a partir dos arquivos PAR2 da release e entrega os bytes reconstruídos. A parte do zurg que faz o pré-carregamento à frente do player não sabia dos pedaços reconstruídos, então pedia de novo aos servidores os artigos que faltavam. Eles continuavam faltando, e o zurg marcava a release como danificada outra vez, mesmo com todos os bytes entregues estando corretos. Uma release reparada durante uma importação podia ser reprovada instantes depois, e um cliente de download acabava descartando uma cópia boa e baixando outra. Agora o zurg não pede mais aos servidores nada que ele já tenha reconstruído.

## O Radarr pode passar seus filmes desejados para o zurg {#radarr-can-hand-its-wanted-movies-to-zurg}

O zurg agora pode pegar sua lista do Radarr. Adicione uma fonte `radarr` em `acquisition.sources` com a URL e a API key do Radarr, e o zurg trabalha nos filmes que o Radarr está faltando ou quer atualizar. Ele pesquisa nos seus indexadores, verifica se os servidores de notícias ainda têm o lançamento, coloca o vídeo na pasta do filme dentro de `__magic__` e pede ao Radarr para escanear esse filme de novo. Para isso, o Radarr não precisa de indexadores nem de cliente de download. Todo lançamento que o zurg pega passa primeiro pelo parser do próprio Radarr, então ele tem que ser o filme certo e se encaixar no perfil de qualidade do filme: uma qualidade permitida, a pontuação mínima de formato personalizado, os limites de tamanho e atualizações só até o cutoff. O zurg pega o primeiro lançamento permitido que for mais rápido de verificar, com lançamentos web primeiro, e deixa as qualidades preferidas do perfil para a atualização que vem depois. Ele só pergunta ao Radarr sobre um lançamento quando está prestes a verificá-lo, um de cada vez, e nunca pergunta sobre um cujo título cita uma resolução para a qual o perfil não tem qualidade. Assim, um Radarr ocupado responde de uma a três perguntas para a maioria dos filmes, em vez de uma para cada resultado da pesquisa. Se o Radarr enxerga o mount do zurg em outro caminho, defina `library_path` com o caminho onde ele enxerga `__magic__`. Uma nova página Acquisition no dashboard mostra todos os títulos em que o zurg está trabalhando, o que ele está fazendo agora e para onde cada lançamento foi colocado. `docs/acquisition.md` cobre o lado do Radarr na configuração.

## A aquisição escolhe o release Usenet que for mais rápido de confirmar {#acquisition-picks-the-usenet-release-that-is-quickest-to-confirm}

Quando o zurg adquire um filme, ele agora olha primeiro para os posts que trazem um único arquivo de vídeo. Esses costumam estar completos nos servidores de notícias com mais frequência e precisam de apenas duas leituras de artigo para serem confirmados. Ele lê o NZB de cada candidato antes de salvar qualquer coisa, salva o primeiro post de vídeo único que encontrar e só recorre a conjuntos de arquivos multivolume quando nenhum estiver disponível. Nesse caso, ele escolhe o menor conjunto primeiro e nunca processa mais de seis ao mesmo tempo. Resultados com título de uma parte de um post dividido são ignorados. Nos testes com o IMDb Top 100, essa forma de escolha reduziu os NZBs que o zurg precisou baixar de 517 para 156. As buscas e os downloads de NZB agora compartilham um limite de requisições em andamento por indexer, e o zurg espera quando um indexer informa que está ocupado. Um pedido de filme sem perfil de qualidade por trás ainda recebe primeiro a resolução que foi pedida. A aquisição de séries não mudou.

## A aquisição verifica um release assim que o zurg conhece seus tamanhos {#acquisition-checks-a-release-once-zurg-knows-its-sizes}

Antes, o zurg verificava uma release nos servidores de notícias assim que ela aparecia na biblioteca, enquanto ainda lia a mesma release para descobrir os tamanhos dos arquivos. As duas tarefas pediam os mesmos artigos pelas mesmas conexões, então em uma lista longa ambas ficavam lentas. Em uma lista de 99 filmes, o último chegou ao Radarr depois de quase nove minutos. Agora o zurg verifica uma release assim que os tamanhos dela já são conhecidos, do mesmo jeito que já faz para o Sonarr e o Radarr pelo endpoint do SABnzbd. Ele verifica no máximo seis releases por vez e reaproveita o primeiro artigo que a checagem de tamanho já tinha baixado, quando ainda o tem. Uma rajada de releases salvas agora gera uma única atualização da biblioteca, em vez de uma por release.

A verificação de uma release agora passa na frente das checagens de tamanho de outras releases, mas nunca na frente da reprodução. Além disso, uma conta com mais de doze conexões agora descobre os tamanhos de até dezesseis releases por vez, em vez de oito.

## Um release Usenet baixado com algumas partes faltando é reparado antes de falhar {#a-grabbed-usenet-release-with-a-few-missing-pieces-is-repaired-before-it-is-failed}

Antes de avisar o Radarr ou o Sonarr que um download terminou, o zurg verifica se as partes da release ainda estão nos servidores de notícias. Quando essa verificação encontrava alguma parte faltando, o zurg marcava o download como falho na hora, mesmo quando os arquivos PAR2 da própria release poderiam reconstruir o que tinha sumido. Aí o Radarr descartava a release e ia procurar outra, muitas vezes pior. Agora o zurg reconstrói primeiro as partes faltando e só informa que o download falhou se essa reconstrução não der certo. Em uma semana de downloads reais, a maioria das releases que falharam dessa forma tinha os arquivos PAR2 que poderiam tê-las salvado.

## Releases Usenet danificados esperam sua vez de reparo em vez de falhar {#damaged-usenet-releases-wait-their-turn-for-a-repair-instead-of-being-failed}

zurg repara no máximo duas versões danificadas por vez, e um reparo pode levar de alguns minutos a mais de uma hora. Um terceiro download danificado tinha apenas cinco minutos para começar antes de o zurg avisar o Radarr ou o Sonarr de que tinha falhado. Por isso, quando vários chegavam juntos, todos menos dois eram descartados sem que ninguém tentasse repará-los, e o log não dizia nada sobre isso. Agora o zurg mantém o download em espera enquanto o reparo aguarda na fila, por até três horas, e o log avisa quando um reparo está esperando a vez.

## Um download Usenet não espera mais para sempre por tamanhos de arquivo que nunca serão descobertos {#a-usenet-download-no-longer-waits-for-ever-on-file-sizes-nothing-is-going-to-learn}

zurg segura um download finalizado no Radarr e no Sonarr até descobrir o tamanho exato de cada arquivo, porque os clientes verificam o tamanho na hora de importar. Depois de certos re-grabs, o zurg podia parar de tentar descobrir os tamanhos enquanto ainda esperava por eles, e o download ficava na fila até o cliente desistir, muitas vezes duas horas depois. Agora o zurg calcula o tamanho de novo para esse release e, quando não há mais como calcular e todas as partes do release estão nos servidores de news, ele avisa o cliente que o download está pronto.

## Releases Usenet cujo poster renomeou apenas o primeiro volume do arquivo voltam a tocar {#usenet-releases-whose-poster-renamed-only-the-first-archive-volume-play-again}

Alguns postadores renomeiam o primeiro volume de um arquivo para o nome da release e deixam o resto com os nomes originais. Assim, uma release chega como `Show.S02E03.part03.rar` mais `show.203.r00` até `show.203.r19`. O zurg agrupou os volumes pelo nome, viu dois arquivos incompletos e não conseguiu abrir nenhum dos dois. Agora ele lê o cabeçalho do primeiro volume, descobre a quais volumes ele pertence e o renomeia de acordo, então o episódio toca e é importado. Quando uma pasta realmente está sem algum volume do arquivo, agora aparece uma mensagem clara dizendo isso, em vez de um erro genérico do servidor.

## Releases Usenet ofuscados cujos volumes estão apenas numerados agora tocam {#obfuscated-usenet-releases-whose-volumes-are-just-numbered-now-play}

Alguns lançamentos escondem todos os nomes de arquivo atrás de uma string aleatória e um número, então um filme chega como `f342c135….01`, `….02` e assim por diante, com os arquivos de texto e as capas numerados no meio deles. O zurg não reconhecia esses arquivos como partes de um mesmo arquivo compactado, listava-os como arquivos soltos, e o Radarr e o Sonarr não encontravam nada para importar. Agora o zurg lê o início de cada arquivo numerado, junta as partes do arquivo na ordem certa (mesmo quando a primeira parte foi postada por último) e deixa os arquivos de texto e as imagens de fora.

## NZBs de temporada completa acima de 32 MB são aceitos {#season-pack-nzbs-over-32-mb-are-accepted}

zurg recusava qualquer NZB maior que 32 MB enviado pelo endpoint do SABnzbd, respondendo "request body too large". Os NZBs de season packs grandes costumam passar disso: uma season de 526 GB veio como um NZB de 49 MB. Agora o zurg aceita NZBs de até 256 MB. Um NZB de 49 MB com quase meio milhão de partes carrega em menos de meio minuto.

## Arquivos de posts Usenet embrulhados mantêm seus nomes reais {#files-from-wrapped-usenet-posts-keep-their-real-names}

Algumas ferramentas de postagem colocam cada nome de arquivo dentro do assunto, como em `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv]-[3/4]`, e deixam vazio o nome de arquivo entre aspas que costuma aparecer. O zurg mantinha o invólucro como parte do nome, então os episódios apareciam como `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv`, o que o Sonarr e os servidores de mídia não conseguem reconhecer. Agora o zurg tira o nome de dentro do invólucro. Os lançamentos que já estão na biblioteca são lidos de novo uma vez para pegar os nomes corrigidos.

## Downloads já marcados como falhos não ocupam mais vagas de reparo dos novos {#downloads-already-reported-failed-no-longer-take-repair-slots-from-new-ones}

Quando o zurg avisa o Radarr ou o Sonarr que um download falhou, o cliente descarta esse download e procura outro. Mesmo assim, o zurg continuava tentando reparar esses downloads toda vez que reiniciava, e esses reparos inúteis podiam ocupar as duas vagas de reparo enquanto um download novo, que ainda poderia ser salvo, ficava esperando. Agora o zurg para de reparar um download assim que ele foi reportado como falho.

## Os relatórios de dano citam cada arquivo {#damage-reports-name-every-file}

Quando uma release da Usenet estava com partes faltando, a mensagem de falha do zurg listava os arquivos danificados pelo nome, e um arquivo que o próprio post nunca nomeou aparecia em branco: "across 4 file(s): , , , ". Agora esse arquivo é listado pela sua posição na release, como em "file 12 of 73", então a mensagem mostra quais arquivos foram afetados.

## O Stremio pula uma release cujo vídeo começa com nada {#stremio-skips-a-release-whose-video-starts-with-nothing}

When a Usenet release's video is missing its beginning on the news servers, zurg filled it with silence and handed it to Stremio as if it were fine, so the player showed nothing and the film looked broken. zurg now checks the first bytes before it starts playback. If there is nothing real there, it moves on to the next release in the list, the same way it already does for a release with nothing playable in it. A film with a gap somewhere later still plays.

## Arquivos quebrados continuam na biblioteca enquanto o zurg ainda tenta de novo {#broken-files-stay-in-the-library-while-zurg-will-still-retry-them}

Quando o zurg não conseguia reparar um arquivo quebrado na primeira tentativa, ele tirava o arquivo do mount, mesmo quando ia tentar de novo um dia depois. O Plex lê um arquivo que some como um arquivo apagado, então uma única varredura da biblioteca podia mandar episódios, temporadas e séries inteiras para a lixeira. Agora, um arquivo quebrado fica no mount enquanto o zurg tiver outra tentativa de reparo planejada. Ele só sai quando o zurg tem certeza de que o conteúdo sumiu, por exemplo quando o serviço recusa o release de vez ou quando não sobra nada reproduzível nele.

## Radarr e Sonarr buscam de novo quando uma release que pegaram duas vezes está morta {#radarr-and-sonarr-search-again-when-a-release-they-grab-twice-is-dead}

Quando o primeiro release que o Radarr pegou se mostrou morto, a próxima busca muitas vezes escolheu o mesmo release de outro indexador, com o mesmo nome. O zurg registrou esse segundo download sob o job id do primeiro. O Radarr e o Sonarr guardam todo download que viram falhar por esse id, então trataram o novo download como a falha antiga e nunca mais olharam para ele: sem falha, sem blocklist, sem nova busca. O filme simplesmente parou. Numa execução do IMDb Top 100 pelo Radarr, 25 filmes terminaram desse jeito.

Um download de um release que o zurg já respondeu como disponível agora recebe um job id próprio, do mesmo jeito que o próprio SABnzbd nomeia cada download. Quando esse também morre, o Radarr recebe a segunda falha, coloca o release na blocklist e faz uma nova busca.

## Releases mortas de Usenet são marcadas como falhas em minutos, em vez de até meia hora {#dead-usenet-releases-are-reported-failed-in-minutes-instead-of-up-to-half-an-hour}

zurg verifica os artigos de uma release capturada antes de avisar o Radarr ou o Sonarr que ela terminou, e espera os tamanhos dos arquivos da release se estabilizarem antes de perguntar. Uma post morta é justamente a release cujos tamanhos nunca chegam, então a verificação ficava presa atrás de uma espera de trinta minutos enquanto o cliente esperava uma resposta. Agora, depois que o zurg tenta e falha em descobrir os tamanhos de uma release, ele verifica os artigos imediatamente, e uma release cujos artigos sumiram é marcada como falha para que o cliente passe para outra.

Uma release encontrada danificada durante a leitura também esperava cinco minutos por um reparo PAR2, mesmo com `enable_repair: false`, quando nenhum reparo chega a rodar. Essa espera agora é pulada sempre que nenhum reparo puder rodar.

Em uma execução do IMDb Top 100 pelo Radarr com mais da metade das releases capturadas mortas, essas duas esperas responderam pela maior parte do tempo que um filme passou no zurg.

## Uma release que se revela danificada durante a importação é marcada como falha, e o Radarr pega outra {#a-release-that-turns-out-damaged-during-import-is-failed-so-radarr-grabs-another}

zurg verifica um artigo por arquivo antes de avisar o Radarr que uma release está pronta, então uma release com um buraco no meio de um arquivo pode passar. Quando a importação do Radarr chegou ao buraco, o zurg recusou mover o arquivo, o que está certo, mas deixou o download com cara de inacabado em vez de falho. O Radarr então marcou o filme como "import blocked" e nunca procurou outra cópia. Numa rodada do IMDb Top 100 pelo Radarr, cinco filmes ficaram presos desse jeito.

Agora, quando a importação é recusada, o download é marcado como falho. O Radarr coloca essa release na blocklist e procura outra.

## Uma release totalmente ofuscada não sai mais com um arquivo de vídeo sem nome {#a-fully-obfuscated-release-no-longer-comes-out-with-a-nameless-video-file}

Quando um post de Usenet esconde todos os nomes de arquivo, o zurg descobre qual é o arquivo principal pelos primeiros bytes dele e o nomeia com base no release, do mesmo jeito que o SABnzbd faz. Essa verificação ficava por último em uma rodada com limite de noventa segundos, e quando os grabs chegavam em rajada esse limite podia acabar antes. O arquivo de vídeo era então publicado com o nome do release e sem extensão nenhuma, o que faz o Radarr e o Sonarr ignorarem, e o download ficava parado na fila deles esperando um arquivo que eles pudessem importar.

Agora um release é renomeado de novo, até três vezes, até o zurg conseguir olhar o arquivo, e só depois é mostrado para a sua biblioteca e para os seus *arr. Em uma rodada do IMDb Top 100 pelo Radarr, isso aconteceu com Seven Samurai, um .mkv de 42 GB.

## Releases com acentos ou CJK nos nomes de arquivo mantêm os nomes inteiros {#releases-with-accents-or-cjk-in-their-filenames-keep-their-whole-names}

Um release cujos arquivos têm nomes com qualquer coisa fora das letras simples do inglês saiu do zurg com o começo de todos os nomes faltando. `Détective Conan S11E01 - 286 [MULTI] [AVC].mkv` foi servido como `tective Conan S11E01 - 286 [MULTI] [AVC].mkv`, e um título em chinês ou japonês perdeu ainda mais, porque tudo até o último desses caracteres foi descartado.

O Sonarr e o Radarr não conseguiam fazer nada com o que sobrou. Um nome como `tective Conan S11E01` não corresponde a nenhuma série, então eles recorreram ao histórico de captura do download, recusaram a importação só com base nisso e deixaram o item parado com "release was matched to series by ID. Automatic import is not possible." O release ficou parado na fila e nada o movia.

Isso também podia custar arquivos. Quando a única coisa que diferencia dois arquivos fica depois do último caractere acentuado, os dois saem com o mesmo nome, e o nome é um caminho. Um release francês com dez volumes de reparo teve todos os dez reduzidos ao mesmo nome e publicou quatro arquivos, quando o post tem treze, deixando os dados de reparo sem como chegar até eles.

Agora o zurg lê todo caractere acima do ASCII simples como parte do nome do arquivo, que é o que ele sempre é: os contadores de partes, o marcador `yEnc`, os colchetes e as extensões de arquivo que os posters escrevem são todos ASCII simples, então qualquer outra coisa pertence ao título. Releases com nomes em ASCII simples não são afetados e saem exatamente como antes.

Releases que já estão na sua biblioteca mantêm os nomes com que foram registrados, já que o zurg não revisita uma lista de arquivos que já gravou. Adicionar de novo um release afetado pega os nomes corrigidos.

(Uma tradução anterior foi rejeitada: os spans de código diferem (` was served as `). Mantenha a estrutura exatamente.)

## Um nome escrito em japonês, coreano, chinês, tailandês ou árabe é deixado como está {#a-name-written-in-japanese-korean-chinese-thai-or-arabic-is-left-alone}

zurg renomeia um arquivo dentro de um arquivo compactado quando o nome dele não diz nada sobre o conteúdo. Assim, um release postado com nome de hash chega com o nome original do release. Para decidir isso, a checagem comparava letras maiúsculas com minúsculas, e muitos sistemas de escrita não têm nenhuma das duas. Um arquivo chamado `오징어 게임 S01E01` tinha zero de cada, não passava no teste de nome comum e era renomeado como se fosse um hash, junto com o S01E01. Kanji, hiragana e katakana, hangul, tailandês, hebraico e árabe foram todos afetados.

Agora, uma letra sem maiúscula nem minúscula encerra a questão em vez de reprovar o nome. Nomes nessas escritas são mantidos como foram postados, e os hashes continuam sendo renomeados exatamente como antes.

O zurg também avisa no log quando dois arquivos de um mesmo release acabam com o mesmo nome. Um nome é um caminho, então, quando isso acontece, o release oferece silenciosamente menos arquivos do que contém, e os extras não podem ser abertos de jeito nenhum. Antes, nada reportava isso, e foi por isso que o defeito com nomes acentuados da entrada anterior passou despercebido: a única evidência era uma listagem de pasta com menos linhas do que o esperado.

## As correções de nome de arquivo agora chegam às releases que você já tem {#the-filename-fixes-now-reach-releases-you-already-have}

As duas entradas acima mudaram a forma como o zurg lê o nome de um arquivo a partir de um post da Usenet, mas o zurg guarda o resultado da leitura de cada NZB e o reutiliza a cada início, em vez de processar todo o seu diretório de observação novamente. Esses resultados guardados ainda eram os antigos, então, depois da atualização, uma release que você já tinha continuou mostrando o mesmo nome errado de antes. Só um NZB recém-adicionado recebeu o nome corrigido.

Agora o zurg percebe que lê os posts de forma diferente da usada para gravar os resultados guardados, e os lê de novo. Na primeira inicialização após a atualização, ele relê uma vez todos os NZBs do seu diretório de observação, o que demora um pouco mais que o normal, e depois volta ao funcionamento habitual. Nada é baixado novamente e nenhum artigo é buscado; ele apenas relê arquivos que já estão no seu disco.

Se uma release foi afetada, os arquivos voltam com os nomes que o post deu a eles. Seu cliente de download pode ainda estar guardando a importação que falhou antes, então uma release que está parada no Sonarr ou no Radarr sem conseguir importar precisa que esse item da fila seja removido para tentar novamente.

## Títulos com pontuação também mantêm os nomes inteiros {#titles-with-punctuation-in-them-keep-their-whole-names-too}

A correção de nome de arquivo mais acima nesta lista fez o zurg parar de cortar nomes em caracteres acentuados e chineses, mas não foi longe o bastante. O zurg decidia o que era um nome de arquivo listando os caracteres que um nome podia conter, e essa lista deixava de fora vinte sinais comuns. Assim, um título que tinha um deles era cortado ali, do mesmo jeito:

    Tom & Jerry - The Movie.1992.1080p.mkv   ->   Jerry - The Movie.1992.1080p.mkv
    Mairimashita! Iruma-kun (2026) [22].mp4  ->   Iruma-kun (2026) [22].mp4

`!`, `&`, `#`, `$`, `%`, `@`, `~`, `;`, `=` e `^` faziam isso.

Tentar listar os caracteres que um título pode ter é uma batalha perdida, então o zurg não tenta mais. Um nome é um nome de arquivo, e os únicos caracteres que certamente não podem estar em um são os que nenhum sistema de arquivos aceita: `/ \ : * ? " < > |`. Todo o resto agora faz parte do título.

Testamos isso com todos os NZBs de uma pasta de monitoramento grande: dos subjects que são um nome de arquivo simples, quase todos que antes saíam cortados agora mantêm o nome inteiro. Os únicos que ainda são encurtados são os que têm o carimbo por download do indexador removido, que é o que deveria acontecer com ele.

## Uma release cujos arquivos foram renomeados pega os nomes novos sozinha {#a-release-whose-files-were-renamed-picks-the-new-names-up-on-its-own}

O que o zurg fez

As correções de nome de arquivo feitas acima mudaram os nomes que o zurg dá aos arquivos dentro de um release Usenet, e um release que já estava na sua biblioteca nem sempre percebeu. O zurg compara um release que ele já conhece com uma nova listagem usando o link que ele guardou para cada arquivo, e um link Usenet carrega a posição do arquivo dentro do release. Quando um nome corrigido ordena diferente do antigo, essa posição muda, o link guardado deixa de apontar para o mesmo arquivo e não sobra nada para comparar, então o nome antigo continuou.

Agora ele usa o tamanho do arquivo como plano B, porque o tamanho não muda. Quando exatamente um arquivo do release tem esse tamanho, é ele que está sendo considerado e o nome é atualizado. Quando dois arquivos têm o mesmo tamanho, nada é renomeado, em vez de adivinhar e colocar um episódio com o nome de outro.

Releases em que a posição não mudou já estavam pegando os nomes novos e não são afetados, e também não são afetados os backends que não são Usenet, cujos links não mudam quando um arquivo é renomeado.

## Um arquivo que o mount não consegue ler deixa de travar todo o resto {#a-file-the-mount-cannot-read-stops-holding-everything-else-up}

Quando uma leitura falhava por um motivo que o zurg não conseguia identificar, ele dizia ao cliente para tentar de novo, e continuava dizendo isso enquanto o arquivo seguisse falhando. O rclone leva isso a sério: uma única leitura de um arquivo desses gastava 55 segundos e três dúzias de requisições antes de desistir. E como o rclone reduz a velocidade de toda a conexão com um servidor que continua retornando erros, o próximo arquivo saudável levava 3.66 segundos para abrir, em vez de 0.04.

Agora, a repetição para depois de um minuto do mesmo erro. A leitura recebe a mesma resposta que já era dada a uma leitura de arquivo quebrado, o arquivo continua na listagem da sua biblioteca, e a mesma leitura leva meio segundo.

O zurg continua tentando baixar o arquivo toda vez, então um arquivo que volta a funcionar é pego pela próxima leitura.

## O mount para de baixar quando você para de ler {#the-mount-stops-downloading-once-you-stop-reading}

A library scan, a subtitle check ou qualquer outra coisa que toque rapidamente em muitos
arquivos estava baixando muito mais da sua conta de debrid do que lia.

O rclone 1.74 passou a manter um arquivo sendo baixado por cinco segundos depois que o último
programa o fechava. Ninguém estava esperando por esses bytes, e em uma conta rápida
cinco segundos são algumas centenas de megabytes por arquivo. Ler 1 MiB de cada um de
vinte arquivos baixava 4,2 GiB, quando antes baixava 80 MiB.

O zurg agora desativa isso. Montagens com rclone 1.73 ou mais antigo não são afetadas e
continuam iguais, porque a opção não existe nessas versões.

Se você usa o seu próprio rclone em vez da montagem do zurg, adicione `--vfs-handle-caching 0`
ao comando de montagem no rclone 1.74 ou mais novo. O README explica isso.

## Uma release que perde um volume de arquivo não perde mais o resto {#a-release-that-loses-one-archive-volume-no-longer-loses-the-rest}

Arquivos da Usenet postados como um conjunto de rar ou 7z em várias partes podiam deixar de ser importados por completo. O Sonarr e o Radarr ficavam presos em "Waiting for import" e nunca saíam dali, e a pasta do release aparecia só com as partes do rar, ou simplesmente deixava de existir.

Quando o zurg não conseguia ler um dos volumes de um conjunto, ele deixava esse volume de lado e seguia a próxima listagem sem ele. Essa listagem encontrava o conjunto com um volume a menos, parava no volume seguinte e também deixava esse de lado. Um release perdia os volumes uma listagem por vez, mais ou menos um a cada dez minutos, e quando não sobrava nenhum ele saía da biblioteca e da pasta de onde o cliente de download importa. Para o Sonarr, um caminho que não existe não é uma pasta vazia: é uma importação que falha para sempre.

Agora, um volume sabidamente ilegível continua dentro do seu conjunto. Toda listagem para no mesmo volume e informa a mesma coisa sobre ele, então um release que está faltando parte da postagem é reportado assim uma única vez, e o seu cliente pode colocá-lo na lista de bloqueio e procurar outra cópia. Releases com todos os volumes legíveis não são afetados.

## As varreduras seguem a biblioteca até o novo lugar, em `__magic__` {#scans-follow-the-library-into-its-new-home-under-__magic__}

O espelho da sua biblioteca passou de `__magic__` para `__magic__/__all__` na versão 2026.09.17.2240-nightly. Uma parte do zurg continuou usando o caminho antigo.

Quando chegava um release novo, o scan que o zurg pedia ao Plex ou ao Jellyfin apontava para uma pasta que não existia mais desde aquele release. Por isso nada entrava na fila, e o conteúdo novo ficava esperando o scan agendado do próprio servidor de mídia. Quem usava um script de `on_library_update` recebia o mesmo caminho errado.

Agora os dois usam a pasta de onde o seu cliente de download foi instruído a importar. A listagem que o zurg remove do cache do mount, quando um release chega ou sai, também usa essa pasta.

## A watchlist agora pode pegar torrents, de indexadores Torznab {#the-watchlist-can-take-torrents-now-from-torznab-indexers}

Até agora, um watchlist ou um pedido no Seerr só podia ser atendido pelo Usenet. Adicione `type: torznab` a um indexador e o zurg também vai pesquisar nele. Um resultado de torrent é entregue a uma conta debrid, em vez de ser gravado em `nzbs/`.

**Ele só é entregue a uma conta que já tenha o conteúdo em cache.** Toda conta que aceita adições recebe o hash, porque os caches são independentes, e a primeira que já tiver o lançamento fica com ele. Se ninguém tiver, é só um candidato que não deu certo, então o zurg passa para o próximo lançamento, que pode ser outro torrent ou um NZB. Nada é baixado para a sua conta, nenhuma cota de adição sem cache é gasta e nada fica rodando para algo que ninguém está esperando.

Quando os dois tipos de indexador podem responder, `prefer` decide qual deles é consultado primeiro. O valor padrão é `usenet`, a não ser que você diga outra coisa, então uma instalação que tinha só indexadores Newznab se comporta exatamente como antes. `torrents` inverte essa ordem, e `best` usa o que o ranqueamento colocar em primeiro lugar, seja torrent ou não.

Uma captura de torrent espera para ser verificada como qualquer outra, mas a pergunta feita é diferente. A conta já disse que tem o conteúdo, então o que se verifica é se o lançamento chegou à sua biblioteca com arquivos dentro. Se ele aparecer como vazio, é descartado para que o próximo lançamento tenha a sua vez.

Você também pode rodar a aquisição só com indexadores Torznab, sem um provedor `nzb`.

## Um agente lendo a biblioteca não chama mais todas as releases de vazias {#an-agent-reading-the-library-no-longer-calls-every-release-empty}

zurg, nas listagens MCP, só mede o tamanho de um release quando isso é pedido, porque percorrer a tabela de arquivos de uma biblioteca inteira custa tempo de verdade. Para os releases que não tinham sido medidos, eles informavam o tamanho e a quantidade de arquivos como zero, e nada na resposta indicava que zero significava "não medido" e não "não há nada ali". Um agente que pedisse para listar um diretório diria que um filme de 6,6 GB não tinha arquivos, enquanto a ferramenta para um único release sempre tinha a resposta certa.

Agora, uma listagem que não mediu deixa esses dois números de fora, em vez de informar zero. Peça-os com `with_size`, ordenando por tamanho ou com um filtro de tamanho. `zurg_library_search` também aceita `with_size`, o que antes não fazia, então obter os tamanhos não custa mais um resultado reduzido ou reordenado.

## O zurg doctor diz se o endpoint MCP está respondendo {#zurg-doctor-says-whether-the-mcp-endpoint-is-answering}

O `zurg doctor` verificava se a porta do painel respondia e parava por aí, o que não diz nada sobre `/mcp`. Um endpoint que a configuração ativa, mas que o servidor depois se recusa a servir, que é o que acontece quando `username` está vazio, parecia saudável de fora e só se explicava em uma linha do log de inicialização, e em mais nenhum lugar.

Quando `mcp.enabled` está ativado, o `doctor` agora fala o protocolo com `/mcp` e informa o que voltou: answering, refusing the configured credentials, ou enabled but not served. Uma instância com o endpoint desligado não é consultada sobre ele e não recebe nenhuma linha.

## Abrir o endpoint MCP no navegador agora mostra o que ele é {#opening-the-mcp-endpoint-in-a-browser-now-tells-you-what-it-is}

Quando abria `/mcp` no navegador, aparecia "Bad Request: GET requires an
Mcp-Session-Id header", que é uma resposta correta para uma pergunta que ninguém fez.
Agora o endpoint se descreve quando um navegador o abre: qual protocolo ele fala, o
endereço para apontar um cliente, o trecho para o bridge stdio, qual build
está rodando e todas as ferramentas que ele está oferecendo no momento, agrupadas por toolset e
marcadas quando uma ferramenta descreve o que faria e aguarda confirmação.

Essa lista é o que o registro realmente produziu, e não uma segunda cópia mantida
à mão. Assim, uma ferramenta retirada por `read_only`, pelos seus toolsets ou pelo
switch de ciclo de vida não aparece como uma que você pode chamar. A página também
avisa quando o endpoint está sendo servido sem autenticação.

Nenhum cliente é afetado. A página só é servida para um GET que pede HTML e
não traz sessão, ou seja, um navegador e nunca um cliente MCP. O GET de um cliente
continua abrindo o event stream exatamente como antes.

## A reprodução de Usenet preenche a cota de conexões mais rápido {#usenet-playback-fills-the-connection-allowance-sooner}

As leituras do Usenet agora colocam o artigo do ponto de reprodução no agendador da conta antes de oferecer o resto do intervalo pedido. Quando um intervalo grande é dividido entre conexões em pipeline, os artigos seguintes são distribuídos entre elas, em vez de a primeira conexão pegar os quatro primeiros, a segunda os quatro seguintes, e assim por diante. Assim, os primeiros artigos úteis chegam já na primeira rodada de conexões, sem ficar esperando os bytes posteriores.

Posts de arquivos compactados com artigos pequenos ganham uma janela de leitura antecipada de pelo menos 64 MiB. Posts modernos, com artigos de vários megabytes, mantêm a janela que já tinham. A quantidade maior de artigos não aumenta o uso de memória: os corpos especulativos ficam limitados a dois leitores e à metade de `cache_size_mb` (256 MiB no padrão), enquanto o cache de artigos mantém o limite rígido que já tinha. Pedidos do tamanho de reprodução começam em 64 MiB em vez de 128 MiB, então um buffer de player de 90 MiB não cai mais no caminho de seek/probe. Seeks pequenos, porém, continuam passando por ele.

Um lote em pipeline travado pode disparar requisições duplicadas para até cinco artigos diferentes ao mesmo tempo. O limite da conta de vinte pedidos de artigo por minuto continua igual, e leituras antecipadas, reparos e outras tarefas que não têm nenhum cliente esperando por elas continuam nunca sendo duplicadas.

Abrir arquivos com vários volumes também ficou mais rápido. Quando o PAR2 já informou o tamanho exato de todos os volumes, o cabeçalho yEnc verificado de um volume pode fornecer o passo comum dos artigos para um conjunto grande de volumes irmãos. Cada volume irmão confirma essa inferência pelo próprio cabeçalho antes de entregar o primeiro byte, então a resolução não precisa mais baixar um artigo por volume, um após o outro, e também não confia em geometria inferida para os dados. A recuperação do nome do arquivo também passa a responder pelo cabeçalho yEnc, sem esperar que o restante do artigo seja baixado.

## Arquivos .strm salvos acompanham uma mudança de Base URL {#saved-strm-files-follow-a-base-url-change}

Mudar a Base URL deixava todos os `.strm` que já estavam em `strm/` apontando para o endereço antigo, e reiniciar não resolvia, porque o zurg só escrevia os arquivos que faltavam. Agora, um `.strm` cuja URL é diferente da que o zurg escreveria é reescrito no lugar. Isso acontece em toda inicialização e logo que a Base URL é alterada no painel, ou quando `save_strm_files` é ativado lá. Arquivos que já estão corretos são deixados como estão, para que um servidor de mídia não precise reler a pasta inteira a cada scan.

O Jellyfin guarda a URL que leu de um `.strm` e pega a nova no próximo scan da biblioteca. Um `.strm` que ainda tenha um link de conta de uma build mais antiga também é reescrito, para a forma que troca entre contas e sobrevive a reparos. Um `.strm` editado à mão dentro de `strm/` é sobrescrito, então defina a Base URL com o endereço que você quer.

## Ligar a watchlist do Plex não a esvazia mais {#turning-the-plex-watchlist-on-no-longer-empties-it}

Ativar a watchlist costumava tratar a lista inteira como uma fila de pendências e ir processando, apagando cada título conforme avançava. Numa primeira execução, 121 títulos saíram de uma lista de 163 itens em cerca de quatro minutos. O Plex não guarda registro de uma entrada removida da watchlist, então a única forma de voltar atrás era um snapshot feito antes, e nada na configuração ou nos logs avisava que isso ia acontecer.

Agora, duas configurações definem o que a aquisição faz com a lista, que é sua e não do zurg.

**`watchlist.only_new_items`** vem ativada por padrão. Quando você liga a watchlist, o zurg passa a monitorá-la. Tudo o que já está na lista é considerado resolvido, e o que você adicionar depois é adquirido. Isso vale só uma vez, na primeira execução, e nunca sobre uma fila que já existe. Assim, uma instalação que já vinha processando uma watchlist continua exatamente como estava.

**`watchlist.remove_after_grab`** também vem ativada por padrão, que é o que a função sempre fez, então nada muda para você a menos que você peça. Desative para manter sua watchlist como uma lista de verdade. Ela continua sendo uma lista que você navega para decidir o que assistir, e o zurg atende a lista em segundo plano sem nunca editá-la. Um título que fica na lista não custa nada para ser verificado de novo, porque o recibo já cobre esse título e nenhum indexador é consultado sobre ele outra vez.

As duas ficam na página de configuração e entram em vigor no próximo reinício. Fontes de aquisição que você define explicitamente em `acquisition.sources` podem configurar qualquer uma das duas por fonte. Elas não têm efeito em uma fonte do Seerr, porque ela não tem nenhuma lista na qual o zurg escreva.

## A watchlist e os pedidos do Seerr esperam pelos servidores de notícias antes de serem limpos {#watchlist-and-seerr-requests-wait-for-the-news-servers-before-they-are-cleared}

Antes, um pedido era dado como concluído assim que o NZB chegava na pasta de monitoramento. O indexador respondia, a resposta era lida como um NZB e o arquivo era gravado. Isso são três fatos sobre o indexador e nenhum sobre a postagem. Com base neles, o pedido era dado como concluído, e numa watchlist do Plex isso significa que o item é apagado, e o Plex não guarda registro de um item removido. Uma postagem morta, portanto, levava embora o único registro de que você queria aquele título, antes de qualquer coisa ter lido um byte dele. Uma única execução sobre uma watchlist de 163 itens removeu 121 títulos, e 12 dos releases por trás deles não puderam ser lidos.

Agora, cada release adquirido é testado nos servidores de notícias antes de qualquer confirmação, a mesma verificação que o endpoint do SABnzbd faz desde a build noturna de 08.28. Há três respostas, e elas são mantidas separadas.

- **Os artigos sumiram.** A captura não conta. O título continua na sua watchlist, o pedido continua aberto, e o release fica marcado como morto, para que a próxima tentativa escolha o próximo candidato em vez de se fixar no que já está na sua biblioteca. Um release já sabido como morto não custa nada. Ele não é baixado e não ocupa vaga entre os três candidatos de uma tentativa, então uma sequência de postagens mortas no topo de um ranking é pulada em vez de ser tentada de novo para sempre. Quando um season pack é considerado morto, a temporada inteira volta a ser procurada, para que os episódios avulsos sejam baixados.
- **Não foi possível consultar os servidores.** Um pool fora do ar, uma conta sendo limitada, ou simplesmente uma biblioteca que ainda não listou o novo NZB. Nada foi confirmado, então nada é decidido. O pedido espera e é verificado de novo, e a espera não gasta nenhuma tentativa de retry. Um release que ainda não pode ser verificado depois de cerca de duas horas é descartado da mesma forma que um morto, e o próximo release tem a sua vez. O título nunca é dado como concluído com base em um release que ninguém conseguiu verificar.
- **O release está lá.** Exatamente como antes.

Uma instalação sem conta de Usenet não tem o que consultar e não é afetada.

## Verificar uma release grande não fica sem tempo em um servidor de notícias lento {#checking-a-big-release-no-longer-runs-out-of-time-on-a-slow-news-server}

Antes de dar um download como concluído, o zurg pergunta aos servidores de Usenet sobre cada arquivo do release. Antes, ele perguntava um arquivo de cada vez. Algumas contas respondem devagar e estritamente uma por vez, então mandar todas as perguntas de uma vez por uma única conexão não ajudava em nada. Um dos provedores levava mais de cinco segundos por arquivo, o que fazia um release 4K de 133 volumes gastar cerca de doze minutos só em perguntas, e cada verificação tinha direito a cinco. A verificação nunca terminava. Então o Sonarr e o Radarr esperavam três horas, davam o grab como falho, e a watchlist ficava esperando para sempre.

Agora os arquivos são perguntados vários de cada vez, usando todas as conexões da conta, exceto a que fica reservada para a reprodução. Ou seja, quanto mais conexões a sua conta permitir, mais rápido um release grande é verificado. Comparando com o mesmo release de 133 volumes, que antes nunca conseguia ser verificado, agora ele leva menos de dois minutos com doze conexões. Com quatro conexões ainda estoura o tempo, porque o que demora são as próprias perguntas. Um release pequeno não fica mais lento do que era antes.

Um release que a verificação não consegue concluir a tempo não trava mais o título. A watchlist o descarta da mesma forma que descarta um release morto e tenta o próximo. E o endpoint do SABnzbd informa a falha, como sempre fez, para que o Sonarr e o Radarr procurem outro.

## Pegas somente em cache no TorBox não baixam mais as releases que deveriam pular {#cached-only-grabs-on-torbox-no-longer-download-the-releases-they-were-meant-to-skip}

A TorBox tem uma flag que faz uma adição recusar tudo o que ela ainda não tem. Ela está na API deles, mas em nenhuma parte da documentação. O zurg não estava usando, então um grab só de cache adicionava o torrent, esperava para ver se ele completava e apagava de novo quando virava um download de verdade. Isso gastava uma das sessenta adições por hora da conta, ocupava um slot de transferência e baixava bytes de um release que o *arr já tinha sido avisado para pular.

Agora, grabs só de cache pedem o conteúdo e são recusados em menos de um segundo se a TorBox não tiver, sem deixar nada na conta. Um erro ainda custa uma das sessenta adições por hora, então o zurg continua controlando o ritmo delas, como antes. E um acerto ainda é verificado, não aceito de cara: o cache da TorBox pode dizer que tem o conteúdo e depois não conseguir entregá-lo, então o release precisa terminar antes de o zurg reportar.

## Pegas somente em cache no Debrid-Link não gastam mais a cota diária de adição {#cached-only-grabs-on-debrid-link-no-longer-spend-the-daily-add-allowance}

Debrid-Link aceita um info hash puro, além de um magnet, e só adiciona o hash quando já tem o conteúdo. O zurg estava enviando um magnet, que é uma instrução para buscar: cada pedido só-em-cache que dava errado era aceito, debitado da cota de 50 adições não cacheadas por dia e de uma das 20 vagas de transferência da conta, e depois apagado para devolver a cota. Com cinquenta erros, a conta não conseguia adicionar mais nada até o reset diário.

Os pedidos só-em-cache agora enviam o hash. Um erro é recusado logo de cara, em cerca de um décimo de segundo, e não mexe na conta. Assim, um *arr pode percorrer uma lista longa de releases sem gastar nada com as que ninguém tem. Isso vale também para pedidos que chegam como arquivo .torrent: o arquivo existe para poupar um serviço da busca de metadados que um hash puro exige, e uma consulta de cache não precisa disso.

## Os bloqueios por limite de taxa do Debrid-Link agora recuam de novo {#debrid-link-rate-limit-lockouts-are-backed-off-from-again}

Debrid-Link responde ao bloqueio de uma hora por endpoint com HTTP 503 e o motivo no corpo da resposta. O zurg tratava todo 503 como o serviço estar fora do ar por pouco tempo, então nunca lia o motivo e continuava tentando um endpoint que já tinha pedido para esperar uma hora. Agora ele reconhece o bloqueio e fica longe desse endpoint até que ele seja liberado.

## `__magic__` agora espelha sua biblioteca em `__magic__/__all__`, deixando a raiz para você {#__magic__-now-mirrors-your-library-at-__magic____all__-leaving-its-root-to-you}

O namespace costumava espelhar `__all__` na raiz, o que fazia da pasta que um cliente de download importa a mesma pasta onde cada release já ficava. Para escapar dos dois health checks que esse arranjo dispara, a root folder de um Sonarr ou Radarr tinha que ficar aninhada *dentro* da pasta de download. E um import manual apontado para a pasta de download percorria a biblioteca inteira à procura de um único release.

O espelho agora está um nível abaixo. `__magic__/__all__` é a biblioteca como `__all__` a lista, e é isso que `sabnzbd.complete_dir` e `qbittorrent.save_path` passam a calcular. A raiz de `__magic__` é sua, para as pastas `tv`, `movies` e `anime` que você aponta para os \*arrs. As duas são irmãs, então nenhuma contém a outra e nenhum cliente avisa.

**Isso muda caminhos.** Se você definiu `sabnzbd.complete_dir` ou `qbittorrent.save_path` manualmente (o caso do mapeamento de container), adicione `/__all__` no final. Se você apontou uma biblioteca do Plex ou do Jellyfin para `__magic__` em si, e não para uma pasta dentro dele, os caminhos dela mudam um nível. Aponte para `__magic__/__all__` ou para a pasta onde você importa. Suas root folders não mudam, e nada armazenado na tabela muda: os placements são caminhos dentro de pastas que você criou, e os tombstones são indexados pelo release, então o layout existente fica intacto. Um grab que já estiver em andamento quando você atualizar carrega o caminho antigo e precisa ser refeito.

Nada pode ser gravado em `__magic__/__all__`: uma linha ali seria um segundo endereço para um release que já tem um, então um MOVE, MKCOL ou DELETE apontado para lá é recusado. Gravar *dentro* de uma pasta de release continua igual, que é onde um \*arr coloca o .nfo ao lado de um arquivo que importou.

## Export Logs agora mostra para onde foram seus links e por quanto tempo duram {#export-logs-now-tells-you-where-your-links-went-and-how-long-they-last}

Export Logs tenta vários hosts de paste e entrega o primeiro que aceitar o arquivo. Nunca dizia qual era, e eles não são intercambiáveis: o host preferido mantém um paste por 180 dias e renova o prazo toda vez que alguém o lê, enquanto o alternativo apaga depois de três. Link com aparência igual, e um relatório enviado numa sexta-feira virou dois links mortos até segunda-feira, sem nada explicando o motivo. Agora os links vêm com o host que os guarda e o prazo que vem com ele.

O motivo de você cair no alternativo é a segunda metade disto. O host preferido bloqueia um endereço que envia arquivos várias vezes em sequência rápida, e uma exportação publica dois arquivos a cada clique, então uma série de relatórios de bug fez o endereço ser recusado. Depois disso, toda requisição daquela máquina foi negada, inclusive a leitura de um paste que ela já tinha armazenado. O zurg mandou as duas metades de cada exportação seguinte para lá mesmo assim e registrou cada uma como um upload que falhou, o que apontava para o arquivo em vez do endereço. Um host que recusa a máquina agora fica de fora por um dia, e o log diz que foi isso que aconteceu.

## Enviar informações de depuração não publica mais suas chaves de indexador e de cliente de download {#uploading-debug-info-no-longer-publishes-your-indexer-and-download-client-keys}

Export Logs oculta todas as credenciais que encontra antes de enviar a configuração para um serviço de paste, mas só estava verificando o nível superior. As chaves dentro dos blocos aninhados saíam em texto puro: as suas chaves de API dos indexadores Newznab, tanto da lista do Stremio quanto da lista de watchlist, o token de addon do Stremio, as chaves de API do SABnzbd e do qBittorrent, o token de conta do zrok e o token de scan do Plex. O mais grave são as chaves dos indexadores: elas dão acesso à sua conta de Usenet, não à do zurg.

Agora elas estão ocultas. Tokens de provedores e senhas de news servers nunca foram afetados.

## O zurg pode ser controlado por um agente de IA {#zurg-can-be-driven-by-an-ai-agent}

Há um novo endpoint em `/mcp` que fala o Model Context Protocol. Assim, um cliente como o Claude pode pesquisar na biblioteca, descobrir por que um lançamento não toca e consertá-lo, usando ferramentas tipadas em vez de ler o HTML do painel.

Ele vem desativado por padrão. Ative com `mcp: {enabled: true}` e aponte um cliente para `http://your-zurg:9999/mcp`, usando o mesmo usuário e senha que o painel pede. Clientes que só falam stdio usam `zurg mcp`, que faz a ponte com a instância que já está rodando, em vez de iniciar uma segunda.

Além das ferramentas, ele oferece a documentação do próprio zurg e o estado atual dele como coisas que um cliente pode ler diretamente, e seis prompts para os procedimentos que vale seguir à risca: diagnosticar um lançamento que não toca, preparar uma varredura do Plex com segurança e fazer a triagem do que o repair desistiu de consertar.

Ele sabe o que não pode fazer sem avisar. Qualquer coisa que remova algo primeiro descreve o que faria e só age quando você confirma exatamente esse plano. `read_only: true` oculta todas as ferramentas que alteram algo, e as ferramentas que poderiam parar o zurg ou o mount ficam atrás da própria chave. Nenhum resultado traz um token, uma senha ou um link resolvido.

Veja [o servidor MCP](mcp.md).

## O zurg avisa quando sua build está desatualizada {#zurg-says-when-your-build-is-out-of-date}

Nada no zurg mostrava a idade de uma build, e é assim que um defeito corrigido em agosto acaba aparecendo num relatório de bug em setembro, com a correção já com três semanas e ninguém na conversa tendo motivo para suspeitar dela. Uma vez por dia, o zurg agora pergunta ao repositório público qual é a release mais nova e, se a sua build for anterior a ela, escreve uma linha com o nome da release, a data dela e a da sua. No resto do tempo ele fica quieto: não imprime nada se você já estiver atualizado, não imprime nada se o GitHub não puder ser acessado, e uma build que não sabe quando foi feita, que é o caso da imagem Docker, não é chutada. Os sponsors numa nightly ficam sempre à frente da última release pública e nunca chegam a ver essa mensagem. A resposta fica em cache por um dia, então reiniciar não gera nenhuma requisição, uma recusa não é tentada de novo até amanhã, e tudo pode ser desligado com `disable_update_check: true`.

## Um link morto dentro de uma release arquivada deixa de ser declarado saudável a cada varredura {#a-dead-link-inside-an-archived-release-stops-being-declared-healthy-every-sweep}

Quando um release é servido como um único arquivo e o reparo não consegue reduzir mais o re-add, o zurg verifica se o próprio arquivo ainda é lido e, se for, tira as marcas de quebrado do release em vez de condená-lo. Ele tirou todas elas, inclusive as marcas dos arquivos que a conta acessa diretamente com links próprios. Um link de arquivo verificado prova que o arquivo é lido, mas não prova nada sobre esses outros. Assim, um arquivo cujo link a conta tinha parado de servir voltou a ficar saudável com base em uma leitura não relacionada. A próxima varredura o desrestringiu e viu que ele estava morto de novo, o release foi condenado de novo, e a passagem que o condenou terminou restaurando-o de novo. Num release de 64 arquivos com 9 links que a conta tinha parado de servir, isso rodou 111 vezes em uma semana, duas vezes dentro dos mesmos 40 segundos, com dois adds de magnet por passagem. A tolerância agora cobre só os arquivos que o arquivo realmente serve, que são os que não têm link próprio. Um arquivo que a conta acessa mantém o veredito que o próprio link lhe deu e vai para o reparo, que é o único caminho capaz de gerar um link que funcione.

## Downloads que chegam só em parte não ficam mais parados na fila para sempre {#downloads-that-only-partly-arrive-no-longer-sit-in-the-queue-for-ever}

Quando alguns arquivos de um lançamento não podiam ser lidos, o zurg mantinha o download na fila esperando pelos tamanhos exatos dos arquivos, que ele nunca ia conseguir descobrir. A verificação que teria encontrado o problema só rodava depois que esses tamanhos chegavam. O Sonarr e o Radarr mostravam esse download em 0%, sem tempo restante, enquanto o zurg continuasse rodando. Eles nunca colocavam o lançamento na lista de bloqueio nem procuravam outro.

Agora, o zurg consulta os servidores de notícias sobre um lançamento que está esperando há trinta minutos. Se os artigos dele sumiram, ou se não foi possível consultar os servidores de jeito nenhum, o zurg informa que o download falhou. Um lançamento cujos tamanhos ainda estão a caminho não é afetado e continua segurado até que eles cheguem.

## Uma release que uma conta desistiu pode ser reparada por outra {#a-release-one-account-gave-up-on-can-be-repaired-from-another}

Os serviços de debrid mantêm caches independentes. Um release que o Real-Debrid já apagou, ou um que ele recusa só pelo nome do arquivo, pode estar em cache no AllDebrid neste exato momento, com o mesmo hash. Até agora o zurg não conseguia usar isso. O repair sempre readicionava um release à conta de onde ele tinha vindo, então, quando essa conta desistia, não sobrava nada para tentar, e o release continuava morto na sua biblioteca enquanto outra conta que você já paga estava com ele.

Agora, um release que todas as contas que o têm desistiram é oferecido às suas outras contas. A primeira que já o tiver pega, e o release volta com as duas contas por trás, alternando entre elas como qualquer release que duas contas tenham. Não há nada para ativar: se você tem uma segunda conta configurada e o repair está habilitado, isso é o que o repair faz quando esgota as outras opções.

Uma conta só recebe conteúdo que ela já tem. Se ela precisasse baixar o release, o add é cancelado e apagado de novo, então nada é baixado e nenhuma cota de transferência é gasta. Uma conta que responde que não tem é consultada de novo um dia depois, depois dois dias, depois quatro, até cerca de quinze dias, então um release que se foi de vez não custa nada para continuar perguntando.

## Pegas somente em cache são avaliadas pela sua conta, não por uma consulta ao cache {#cached-only-grabs-are-judged-by-your-account-not-by-a-cache-lookup}

No modo cached-only, o zurg costumava perguntar ao TorBox, ao Premiumize e ao Offcloud se um release estava no cache deles e devolvia essa resposta direto para o Sonarr. Esses endpoints respondem a outra pergunta. Eles dizem que o conteúdo está no cache do serviço, não que sua conta vai ficar com ele, e ninguém verificava o torrent depois. Um "sim" que virava download chegava ao Sonarr como o grab instantâneo que tinha sido prometido, e isso é justamente o que o cached-only existe para evitar.

Agora todas as contas são avaliadas do mesmo jeito. O torrent é adicionado, a instância é monitorada e só conta como cached se ele terminar dentro da janela. Qualquer outro caso é apagado de novo e o grab é recusado, o que faz o Sonarr passar para o próximo release da lista. O custo é que um miss nesses três serviços agora gasta um slot de adição, enquanto antes uma consulta ao cache não gastava nada.

## Uma chave de backup do AllDebrid não responde mais pela sua biblioteca {#an-alldebrid-backup-key-no-longer-answers-for-your-library}

`download_tokens` em uma conta do AllDebrid são contas separadas do AllDebrid, guardadas pela franquia de download delas. Quando a chave principal da conta atingia o limite e saía de rotação, todas as outras chamadas também iam para a chave de reserva: a listagem de magnets, a lista de arquivos de um lançamento, adições, exclusões, reinícios, os links salvos por trás de `__downloads__` e a verificação de mudanças. Assim, a atualização da biblioteca podia listar os magnets da conta de reserva e adotá-los como se fossem seus, uma exclusão podia ser enviada para uma conta que nunca tinha aquele magnet e voltar parecendo que ele já tinha sido removido, e, quando todas as chaves atingiam o limite, o catálogo inteiro saía do ar por causa de algo que é só um limite de bytes. Agora, só desbloquear um link faz a rotação. Tudo que diz respeito à sua conta é pedido à sua conta.

## Uma release saudável deixa de ficar oscilando entre dentro e fora da lista Broken {#a-healthy-release-stops-flapping-in-and-out-of-the-broken-list}

Uma release cuja conta continua oferecendo um único link morto podia ficar na lista Broken do painel metade de cada hora, enquanto todos os arquivos dela tocavam perfeitamente. O Repair descarta um link que respondeu `hoster_unavailable` por três ciclos, para poder reendereçar a release, e guarda a lembrança desse descarte para que a próxima listagem não traga o link morto de volta. Só que essa memória era apagada pela coisa errada: qualquer reparo que terminasse bem limpava a lista, inclusive as passadas que não criavam nada e só confirmavam que o endereçamento que a entrada já tinha ainda funcionava. "O arquivo que serve a release ainda funciona" é o caso extremo: prova que o único link que serve a release funciona, e não diz absolutamente nada sobre um link que a conta recusou. Então a desistência era esquecida, o refresh seguinte adotava o mesmo link morto, o Repair não conseguia atribuí-lo de novo e condenava a entrada outra vez, num ciclo de trinta minutos que nunca acabava. Medido em uma biblioteca ativa ao longo de três dias: uma release foi condenada de novo 129 vezes, 556 condenações na biblioteca em uma semana, e cada ciclo gastava de duas a quatro adições de magnet. Agora só um reparo que realmente reendereçou a release esquece uma desistência, e um Repair manual continua esquecendo todas, para que o operador possa devolver um link na mão.

## Uma release servida como um único arquivo não é mais marcada como quebrada a cada varredura {#a-release-served-as-one-archive-is-no-longer-marked-broken-every-sweep}

Alguns releases vêm como um único arquivo: o `.rar` carrega o único link da conta, e cada episódio dentro dele aparece como um arquivo próprio, sem nenhum link. Mesmo assim, a varredura de reparo perguntava à conta sobre esses arquivos internos. Não havia com o que perguntar, então nenhuma conta foi consultada e nada foi medido. Ainda assim, a resposta voltava "file is broken", que a varredura gravava em cada arquivo e usava para condenar o release inteiro. Isso gerou duas adições de magnet: a conta foi consultada só pelos arquivos quebrados, respondeu com o mesmo link do arquivo único de sempre, e o fallback do arquivo verificou esse link e restaurou todos os arquivos que tinham acabado de ser condenados. Medido numa biblioteca real, 44 episódios de um único .rar de 4,9 GB passaram por esse ciclo a cada meia hora. Agora, um arquivo para o qual nenhuma conta tem link é deixado em paz, e o próprio arquivo do .rar é avaliado exatamente como antes. Quando o link que realmente serve o release deixa de resolver, esse arquivo fica quebrado e o release junto.

## O tráfego volta para o token da sua própria conta assim que a cota é renovada {#traffic-goes-back-to-your-own-accounts-token-once-its-allowance-resets}

A conta do Real-Debrid que esgota a cota diária passa o tráfego para a primeira entrada de `download_tokens` que ainda tiver cota, e o watcher coloca o token da própria conta de volta na rotação assim que ela consegue servir bytes de novo.
Recuperar um token não trouxe o tráfego de volta. A rotação continuava a partir de onde tinha parado e só verificava se aquele token específico estava limitado, então a conta de backup seguia pegando todos os bytes pelo resto do dia, mesmo com o contador da conta principal já em zero. A ordem em `download_tokens` agora é uma preferência, não uma posição a percorrer: o token mais próximo do início que conseguir servir é o que serve, então a conta principal retoma o tráfego em até um minuto depois que o contador dela é zerado.

## Um remote do rclone apontando para o endereço errado agora avisa sobre isso {#an-rclone-remote-pointed-at-the-wrong-address-now-says-so}

Se a url de um remote WebDAV do rclone estiver sem o `/dav/` no final, toda listagem falhava com "couldn't list files: 405 Method Not Allowed" e nada, em lugar nenhum, explicava o motivo. O dashboard respondia normalmente no navegador, então o zurg parecia saudável, e o log do próprio zurg ficava em silêncio sobre o cliente que falhava a cada poucos segundos. Agora o zurg responde a uma requisição WebDAV que chega fora de `/dav/` com o endereço correto a usar, que o rclone mostra como parte do próprio erro, e escreve um único aviso com o nome do cliente que enviou a requisição.

## Instalações no Windows voltam a enviar atualizações de escaneamento para o servidor de mídia {#windows-installs-now-send-media-server-scans-again}

Um `mount_path` de `Z:`, que é o que `zurg setup` grava no Windows, montava os caminhos de escaneamento em relação ao diretório atual dentro dessa unidade, e não em relação à raiz dela. Por isso, todo caminho caía fora da seção da biblioteca a que pertencia, e nenhum escaneamento era enviado. O aviso que aparecia em seguida pedia para o operador verificar um `mount_path` que já estava correto. Configs existentes não precisam de nenhuma edição.

## A varredura em massa lê a biblioteca do Plex uma vez, e não uma vez por torrent {#bulk-scan-reads-the-plex-library-once-instead-of-once-per-torrent}

Depois de um bulk scan no dashboard, o matching lia a biblioteca inteira do Plex para cada torrent do lote. Assim, ao escanear uma biblioteca grande, eram disparadas centenas de buscas completas idênticas num servidor Plex que normalmente já estava ocupado com outros scans.

## Os caminhos da biblioteca no Windows batem independentemente de maiúsculas e minúsculas {#windows-library-paths-match-regardless-of-case}

A biblioteca do Plex, Jellyfin ou Emby registrada como `Z:\Movies` não perde mais o `Z:\movies` que o zurg monta a partir do nome do próprio diretório. O NTFS não diferencia maiúsculas de minúsculas, então os dois nomes apontam para o mesmo diretório. Comparar os nomes exatamente fazia a varredura ser descartada e reportava o mount_path como incorreto.

## Um arquivo que para de ser servido não trava mais um escaneamento do Plex {#a-file-that-stops-serving-no-longer-stalls-a-plex-scan}

Um arquivo quebrado mantinha seu lugar na listagem da pasta e respondia às leituras com
`503 File temporarily unavailable (being repaired)` até que algo suspendesse o veredito. Com um reparo em andamento, isso durava até o reparo terminar. O Plex trava diante de um 503, então um único arquivo desses trava a varredura da biblioteca, e uma biblioteca que acumula muitos deles nunca termina a varredura. Já o Jellyfin ignora esses arquivos e parece funcionar bem.

São duas decisões separadas e agora elas têm respostas separadas. A entrada continua listada enquanto ainda puder voltar, porque uma entrada que some de uma pasta parece uma exclusão para um scanner de mídia, e o item acaba indo para a lixeira. Nada disso muda. O que muda é a leitura: ela responde 503 por um minuto depois que o arquivo para de ser servido, e 404 depois disso. Um minuto é o tempo que um cliente consegue aproveitar, já que o rclone tenta de novo um 503 e desiste de uma leitura por volta desse ponto. Assim, uma falha curta ainda é absorvida e a leitura dá certo. Passado esse tempo, o 503 já estava falhando a leitura de qualquer forma e prejudicando todas as varreduras atrás dele.

Medido com um Plex real, em uma biblioteca de quinze filmes, com dez arquivos recusados e todos ainda listados: as leituras que respondiam 404 terminaram a varredura em 5 segundos. Já um 503 que nunca era suspenso tinha encontrado três dos quinze quando a execução foi interrompida aos dez minutos.

## Novos jobs do SABnzbd não esperam mais atrás das verificações de tamanho de uma biblioteca inteira {#new-sabnzbd-jobs-no-longer-wait-behind-a-full-librarys-size-checks}

Quando o zurg reiniciava com uma biblioteca grande de Usenet, ele colocava na fila uma verificação de tamanho para cada release e esquecia quais verificações falhadas ainda estavam dentro do atraso de uma hora para nova tentativa. Um release recém-baixado podia então ficar atrás de milhares de verificações em segundo plano enquanto o Sonarr ou o Radarr esperavam pelos tamanhos exatos dos arquivos. Agora as verificações de tamanho usam uma fila de workers fixa, um release com um job do SABnzbd em espera vai para o início da fila, e tanto as verificações concluídas quanto os atrasos de nova tentativa sobrevivem a um reinício em `data/nzb-sizes/`. Enquanto houver trabalho na fila, o zurg informa a cada minuto as contagens de em espera, de prioridade do cliente e de em execução.

## Downloads que um cliente nunca libera não impedem mais a importação de novos {#downloads-a-client-never-clears-no-longer-stop-new-ones-from-being-imported}

zurg mostra para o Sonarr, o Radarr e outros clientes de download uma página com os downloads concluídos, e mantém cada um nessa página até que o cliente o remova. Os clientes só removem o que importam ou o que falha, então uma importação bloqueada, como um título que eles não conseguem associar, ficava na página para sempre. Quando a página encheu com esses itens, todo download novo que terminava ficava esperando na fila e nunca era importado. Um download que está na página há dez minutos sem ser removido agora cede o lugar a um que está esperando, do mesmo jeito que o SABnzbd tira as linhas mais antigas da página de histórico conforme novas chegam. Nada muda enquanto a página tiver espaço, e pedir um release novamente dá a ele um lugar próprio.

## Um download consultado pelo seu id é encontrado assim que termina {#a-download-looked-up-by-its-id-is-found-as-soon-as-it-finishes}

Ferramentas que consultam o zurg sobre um download por vez, pelo seu id, como o LazyLibrarian, agora são avisadas de que ele terminou assim que isso acontece, mesmo quando a página de downloads concluídos que o Sonarr e o Radarr leem está cheia. Antes, um download assim podia parecer não concluído para eles até que abrisse uma vaga nessa página.

## A correção de temporada tem uma página no painel {#season-fix-has-a-page-in-the-dashboard}

A renomeação de toda a biblioteca que organiza os episódios numerados por fansubs com os nomes que o Plex lê só era acessível como dois endpoints HTTP desde que foi lançada: `/torrents/season-fix/plan` e `/torrents/season-fix/apply`, sem nenhum controle no painel e com um único parágrafo na referência de nomenclatura. Uma funcionalidade que ninguém consegue encontrar não existe, e essa foi pedida no canal de wishlist no mês passado por pessoas que não faziam ideia de que ela já estava pronta.

`/season-fix/` agora explica o que essa passagem faz, mostra a forma canônica que ela gera a partir do nome do fansub que substitui e diz de onde vem o formato das temporadas: do provedor de metadados do próprio Plex, nunca da biblioteca local, já que uma biblioteca que juntou as temporadas é justamente o que está sendo corrigido. Também lista o que o mapeador se recusa a tocar e por quê, porque uma varredura que volta quase vazia é a resposta conservadora funcionando, não um defeito.

A varredura continua atrás de um botão: o planejamento percorre cada torrent e pergunta ao Plex sobre cada série correspondente, então abrir a página não a inicia. Os resultados são agrupados por série, com cada renomeação mostrada de antigo para novo, e os arquivos ignorados ficam numa seção recolhível. Uma entrada marcada como provável correspondência com a série errada chega desmarcada e diz isso de novo na confirmação, assim aplicar tudo de uma vez não consegue renomear em silêncio uma release associada à série errada.

## Reproduza uma release compactada que está dividida em vários volumes {#play-a-compressed-release-that-is-split-across-several-volumes}

Uma release que foi compactada (em vez de guardada inteira) parava no fim do primeiro volume. Todos os arquivos dentro dela apareciam na lista com o nome e o tamanho certos, mas não tocavam, e o log mostrava um erro de bad header CRC. Agora o zurg continua a descompactação em cada junção de volume, então essas releases tocam do começo ao fim.

## Inicie rapidamente quando sua conta tiver torrents com falha {#start-up-quickly-when-your-account-holds-failed-torrents}

Cada atualização da biblioteca verificava de novo todos os torrents que o seu serviço de debrid tinha marcado como com falha, um pedido de cada vez, e o serviço permite só algumas dessas consultas por segundo. Em uma conta com algumas centenas deles, isso sozinho levava mais de um minuto, a cada atualização, e a sua biblioteca ficava inacessível por todo esse tempo depois de cada início. Esse tempo basta para o Plex escanear uma pasta que ainda não existe e marcar tudo nela como indisponível. Agora o zurg lê do disco o que ele já sabe sobre um torrent com falha e só consulta o serviço de novo quando o serviço informa que o torrent deixou de estar com falha.

## Pare de perguntar ao AllDebrid sobre magnets que ele já recusou tentar de novo {#stop-re-asking-alldebrid-about-magnets-it-has-already-refused-to-retry}

Quando um magnet falha, o zurg pede ao AllDebrid que o busque de novo. O AllDebrid recusa alguns desses pedidos, e a recusa não era contada nas duas tentativas que cada torrent tem. Por isso, o mesmo magnet era perguntado a cada atualização da biblioteca enquanto o zurg estivesse rodando. Agora a resposta fica guardada por uma hora, junto com o status que a conta devolveu. Assim, se o magnet mudar, ele é perguntado de novo. A contagem de tentativas também é gravada em disco, em vez de ser esquecida a cada reinício e gasta de novo do zero.

## Mantenha o link estável para uma release que sua conta tem duas vezes {#keep-the-link-steady-for-a-release-your-account-holds-twice}

A mesma release adicionada duas vezes em uma conta fica com tudo em dobro, inclusive dois links de download por arquivo. O zurg mantinha um link por conta, então cada cópia substituía a outra a cada atualização e a entrada nunca se estabilizava. Nada ficava injogável, mas o log se enchia de re-apontamentos e a biblioteca era reescrita no disco a cada poucos segundos. Agora o zurg deixa o link em paz quando só consegue ver parte do que a conta tem.

## Verificações de mudança mais rápidas no TorBox quando a conta tem torrents com falha {#faster-change-checks-on-torbox-when-the-account-holds-failed-torrents}

TorBox não tem como informar se a conta mudou, então o zurg lê uma pequena página com os torrents mais recentes e acompanha os que ainda não terminaram. Um torrent que o TorBox marcou como falho nunca termina, então uma única falha antiga fazia cada verificação ler uma página bem maior, pelo resto da vida da conta. Torrents com falha não são mais acompanhados à espera de mudanças que eles nunca vão fazer.

## Uma release que o seu *arr não conseguiu importar não é mais apagada na tentativa {#a-release-your-arr-could-not-import-is-no-longer-deleted-by-the-attempt}

When zurg recusa mover um release para fora da pasta de staging do Usenet porque ele não pode ser lido dos servidores de notícias, o Sonarr e o Radarr não desistem simplesmente. O .NET responde a um movimento que falhou copiando o arquivo e depois apagando o original, e o zurg estava respeitando esse delete, então o release sumia e um arquivo vazio ficava no lugar onde ele tinha sido importado. Agora o delete que vem depois de um movimento recusado também é recusado pelo mesmo motivo, e o release fica no lugar.

## As leituras do Usenet diferenciam um lote lento de um travado {#usenet-reads-tell-a-slow-batch-from-a-stalled-one}

O zurg pede a um segundo conexão de news um artigo cuja espera já demorou demais, e usa a resposta que chegar primeiro. Antes, decidir que a espera tinha demorado demais era feito com base no relógio. Um lote comum de artigos grandes, em uma conta rápida, era pedido duas vezes enquanto o primeiro artigo ainda estava chegando.

Agora essa decisão vem dos bytes que chegam pela rede. Uma conexão de news já renova o seu próprio timeout toda vez que chegam bytes, e a leitura também vê essa evidência. Um lote que está na metade de um artigo grande fica em paz, não importa quanto tempo esse artigo leve. Só um lote cujos bytes pararam de chegar é pedido em outro lugar.

Quando uma conexão pega um lote de artigos e não responde a nenhum deles, o zurg pede a outra conexão o resto inteiro daquele lote de uma vez, em vez de buscar cada artigo que falta por conta própria. A conexão lenta nunca é cortada, então os artigos dela ainda contam se chegarem. Só os artigos que nunca chegaram são pedidos de novo, no máximo uma vez por lote. Os artigos mais próximos do ponto de reprodução vêm primeiro, e sempre fica uma segunda requisição de um segundo de reserva, para que a próxima leitura que fique parada ainda possa pedir o artigo dela.

Uma leitura também deixa de considerar a espera que gastou em uma segunda requisição como sua velocidade normal. Ela aprende apenas o tempo que o zurg estava disposto a esperar, nem um segundo a mais. Em uma conta onde todo artigo leva legitimamente um segundo ou mais, o limite agora se ajusta perto do que aquela conta realmente entrega, em vez de cair para o menor valor possível e pedir duas vezes a maioria dos artigos.

## O read-ahead do Usenet mantém a janela cheia entre artigos e volumes {#usenet-read-ahead-keeps-its-window-full-across-articles-and-volumes}

Antes, o read-ahead parava de pedir novos bytes enquanto um artigo anterior estava atrasado, então um único artigo lento esvaziava a janela que tinha sido construída. Agora o zurg mantém uma janela limitada de bytes solicitados em andamento, mesmo assim, e um lote de artigos pode atravessar a junção entre dois volumes RAR armazenados, em vez de terminar nela.

A janela usa no máximo um quarto do cache de RAM que você configurou e nunca mais de 128 MiB, então um cache menor gera uma janela menor. As requisições mantêm o próprio cancelamento e os limites de conexão e de cache da sua conta.

## A reprodução via Usenet consome menos CPU em processadores mais antigos {#usenet-playback-costs-less-cpu-on-older-processors}

O cache de leitura faz um checksum de cada registro que armazena. Em processadores Intel e AMD que têm SSE4.1 mas não AVX, o SHA-256 roda sem nenhuma ajuda de hardware, e esse custo apareceu durante a reprodução. O zurg agora usa um checksum de 256 bits mais rápido nesses processadores. Os registros carregam uma versão, então corrupção continua sendo detectada, um cache existente continua legível, e todos os outros processadores continuam usando SHA-256.

## Os compartilhamentos NZB não apontam mais de volta para a conta que os baixou {#nzb-shares-no-longer-point-back-to-the-account-that-grabbed-them}

Alguns indexadores marcam cada download com detalhes que levam de volta à sua conta, e parte disso estava em campos que um compartilhamento mantinha. Um deles coloca um token novo no título da release, e muitas vezes na senha, e muda o poster, a data e o newsgroup em cada arquivo. Outro coloca o número da sua conta no começo do subject de um arquivo. Um terceiro põe uma marca de conta em todos os posters. Agora, o `zurg nzb-share` remove posters e datas, dá a todos os arquivos o mesmo newsgroup fixo, corta a marca do subject e ignora um token onde quer que ele esteja. Quando o nome e o título não batem, o nome vale. Duas pessoas que baixaram a mesma release agora publicam o mesmo arquivo. Os compartilhamentos também deixam de pular NZBs salvos na codificação Latin-1, e deixam de duplicar as barras invertidas que alguns subjects têm.

O que a limpeza remove está em [`zurg nzb-share`](cli.md#zurg-nzb-share).

## Bibliotecas locais adicionam o hash no AllDebrid, Premiumize e Offcloud {#local-libraries-add-the-hash-on-alldebrid-premiumize-and-offcloud}

A biblioteca local cujo manifesto não tem link portátil adiciona o hash à sua conta no primeiro play. Um manifesto exportado do TorBox é sempre assim. Também é o caso de um cujo link do AllDebrid expirou. No AllDebrid, Premiumize e Offcloud, todo play desses falhava com "provider did not report an active torrent allowance". O zurg exigia que a conta informasse o limite de slots de torrent antes de adicionar. Esses três nunca informam esse limite. Agora o zurg usa, como fallback, a quantidade de slots declarada, do mesmo jeito que o repair faz. Sem nenhum dos dois, ele adiciona o hash e deixa o provedor recusar uma conta cheia.

## Os arquivos do Offcloud informam a duração {#offcloud-files-report-their-length}

Ao resolver um arquivo do Offcloud, o tamanho dele ficava sem valor. Uma biblioteca local compara esse tamanho com o manifesto dela. Por isso, ela recusava toda reprodução do Offcloud com "resolved file size does not match the portable manifest". A reprodução normal também perdia o tratamento de range, que precisa do tamanho. Agora o zurg pede o tamanho ao servidor de entrega, do mesmo jeito que a listagem do Offcloud já faz.

## O zurg roda em celulares Android e no Google TV {#zurg-runs-on-android-phones-and-google-tv}

Um novo app para Android hospeda sua biblioteca no próprio dispositivo. Ele se adapta a celulares e tablets, além de Android TV e Google TV. Ele precisa do Android 8.0 ou mais recente, e o Usenet precisa de Android de 64 bits. O app guia você pelas contas dos provedores e pelo perfil do dispositivo e depois inicia a biblioteca. Você navega pela biblioteca no próprio app ou no Arquivos do Android, e reproduz no player externo que escolher, com busca completa. Um controle remoto de TV funciona em todas as telas. O MediaInfo funciona no dispositivo sem precisar de ferramentas extras. A biblioteca também pode ser compartilhada com outros dispositivos na sua rede local, protegida por senha. Essa senha nunca chega a um player.

Os APKs estão nas releases nightly de sponsor. O app não inclui o zurg. Depois que você entra no GitHub, ele instala o motor do zurg como um segundo pacote. O app e o motor são atualizados separadamente. A seção Updates lista todas as versões do motor que ainda estão publicadas, para que uma nightly que se comporte mal no seu dispositivo possa ser revertida para uma que funcionou. Quem instalou o primeiro build do Android precisa instalar um motor pela seção Updates uma vez. Provedores e configurações da biblioteca são mantidos intactos.

O motor para dispositivos ARM de 64 bits agora consulta os endereços dos provedores pelo resolvedor próprio do Android. O motor do primeiro build podia não conseguir alcançar nenhum provedor.

As notas de configuração e do player estão em [Android](../guides/android.md).

## Um novo NZB aparece na biblioteca em poucos segundos {#a-new-nzb-shows-up-in-the-library-within-seconds}

O NZB caía no diretório de watch e esperava pela próxima checagem periódica de mudanças. Uma release ofuscada então esperava mais um intervalo enquanto os nomes reais dos arquivos eram lidos. Com o intervalo padrão, isso somava de 20 a 30 segundos com a grab do Sonarr ou do Radarr parada em Queued o tempo todo.

Agora o zurg checa o diretório de watch por conta própria, uma vez por segundo. Ele não depende de eventos do sistema de arquivos, então se comporta do mesmo jeito em um NAS ou dentro de um container. Uma release aparece na lista assim que seus nomes forem lidos. Um season pack de vinte releases ainda custa uma única listagem. A checagem periódica continua como backstop para um NZB substituído com um nome que já existia.

## Os streams via Usenet mantêm a velocidade {#usenet-streams-hold-their-speed}

Um arquivo dentro de um conjunto RAR chega à conta de news um volume por vez. O zurg abre o próximo volume antecipadamente para que a travessia não comece do zero. Antes, ele só aquecia os primeiros quatro megabytes. Em uma release dividida em volumes pequenos, isso significava um limite a cada um ou dois segundos de reprodução e uma travada em cada um deles. Uma dessas releases rodava entre 14 e 16 MB/s, enquanto um arquivo comum na mesma conta chegava a 86 a 99 MB/s. Agora, o próximo volume é aquecido em toda a janela de leitura antecipada assim que a reprodução chega a 32 MiB dele. Um volume em que a reprodução acabou de entrar mantém a leitura antecipada que já conquistou. Um volume que nada está perto de alcançar continua sendo aquecido apenas no início. Isso evita que uma varredura da biblioteca baixe dados que nunca serão lidos.

Uma leitura contínua também passava cerca de um segundo a cada vinte travada em um único artigo lento, enquanto todas as outras conexões esperavam por ele. Agora, o zurg pede esse mesmo artigo a uma segunda conexão quando a espera se prolonga, e usa a resposta que chegar primeiro. Isso só acontece para uma leitura que um player está esperando. A leitura antecipada e o reparo nunca são duplicados. O limite é de vinte requisições extras por minuto, por conta.

A leitura que um player está esperando agora tem prioridade em mais situações. A leitura antecipada não ocupa mais a última conexão livre de uma conta. A passagem de dimensionamento na inicialização também deixa uma livre. Uma leitura usa as conexões que a conta já mantém, em vez de abrir uma nova. Ela espera por uma conexão que já está sendo aberta, em vez de pagar por outra. O artigo em que o player está travado pode passar na frente das requisições enfileiradas para bytes posteriores. Em uma medição, o primeiro byte de uma leitura chegou em 177 ms, em vez de 354 ms. O aquecimento, os keep-alives e as leituras agora também compartilham um mesmo limite de conexões. O zurg nunca abre mais conexões do que a conta permite.

Salvar um artigo decodificado no cache em disco não trava mais a leitura que o buscou. A gravação ficava dentro de um lock que todas as outras leituras precisavam, e agora acontece depois que os bytes chegam ao player. Uma rajada maior do que o cache consegue acompanhar pula os registros extras, em vez de deixar a reprodução mais lenta. Um cache existente é mantido como está.

## Sonarr e Radarr deixam de esperar por grabs que nunca vão terminar {#sonarr-and-radarr-stop-waiting-on-grabs-that-can-never-finish}

The endpoint do SABnzbd costumava deixar alguns jobs na fila para sempre. O cliente nunca os colocava na blocklist e nunca pegava outra release. Cada caso abaixo agora é reportado como Failed com uma mensagem que diz o motivo. Failed é o que faz o Sonarr e o Radarr colocarem a release na blocklist e pesquisarem de novo.

Uma release pode sair da biblioteca depois do grab. Ela pode ser apagada do dashboard, removida do watch directory ou descartada por todas as contas. O job ficava parado em 0% sem nada que fizesse ele andar. Agora ele falha quando a release fica fora por quinze minutos. Nada falha nos primeiros quinze minutos depois de um restart, enquanto a biblioteca ainda está carregando.

Um grab pode cair numa release que um import anterior já esvaziou. Isso acontece quando um upgrade apaga o arquivo importado e uma pesquisa escolhe a mesma release de novo. O zurg respondia Completed e apontava o cliente para uma pasta sem nada dentro. Agora um grab de uma release já esvaziada falha na hora. Uma pasta que fica vazia por quinze minutos também faz o job falhar. Isso inclui uma pasta esvaziada por uma movimentação feita à mão ou por um import registrado em outro job. O grab que faz o import ainda mostra Completed enquanto termina.

Algumas releases nunca terminam a verificação de artigos. O zurg pergunta aos news servers se os artigos de uma release ainda estão lá antes de informar que o grab terminou. Uma verificação que não conseguia terminar era repetida a cada minuto sem fim. Agora ela falha depois de trinta tentativas seguidas que cubram pelo menos três horas. Uma conta de news que fica fora do ar por uma hora não faz todos os jobs em espera serem colocados na blocklist. Uma verificação que finalmente responde zera a contagem.

Algumas releases não têm o arquivo completo. Um conjunto pode não ter nenhum volume com o início do arquivo. Pode faltar um volume no meio. Pode começar em um volume que não é o primeiro. O Sonarr era apontado para uma pasta da qual nunca conseguiria importar e tentava de novo para sempre. Agora o grab falha. O veredito está ligado aos volumes exatos em que foi obtido. Um reparo com PAR2, um novo grab ou uma segunda conta que tenha os volumes que faltam faz a release ser analisada de novo.

## Os tokens de download de backup assumem quando a cota diária acaba {#backup-download-tokens-take-over-when-the-daily-allowance-runs-out}

O Real-Debrid recusa um download assim que um token gasta a cota diária. O zurg deveria desativar esse token e passar para o próximo item de `download_tokens`. Isso parou de acontecer durante a reprodução quando os streams via proxy passaram para um novo cliente HTTP. A recusa voltava como uma resposta comum, e nada marcava o token como esgotado. Todos os tokens de backup ficavam parados, e cada leitura gastava de novo o token com limite.

Agora a recusa é reconhecida em todos os pontos onde o zurg a encontra. Isso inclui a reprodução, o loop de atualização e o repair. Os dois verificam os links mesmo quando nada está tocando. Uma recusa que chega sem o header usual do Real-Debrid também desativa o token.

Um token desativado é testado uma vez por minuto, para voltar assim que a cota dele for renovada. Esse teste usava um link em cache feito com o próprio token desativado. Depois que o token para de funcionar, ninguém renova esse cache. Por isso o teste não encontrava nada, e o token ficava fora até o reset noturno ou até um restart. Agora o teste pega emprestado um link de qualquer token que ainda esteja funcionando.

O reset noturno estava atrasado um dia. O Real-Debrid renova as cotas alguns minutos depois da meia-noite CET. O zurg pulava a primeira meia-noite depois de cada start e fazia o reset na segunda. Uma conta que já tinha gasto a cota continuava usando o token de backup por mais um dia. Além disso, o zurg calculava essa meia-noite pela data do próprio host. Na costa oeste da Europa, isso deixava o reset na hora em que o zurg tivesse sido iniciado por acaso. Agora todo reset é agendado pela data no fuso CET.

## Um grab de magnet mantém o nome da release na conta de debrid {#a-magnet-grab-keeps-its-release-name-on-the-debrid-account}

O Sonarr e o Radarr passam para o endpoint do qBittorrent o magnet inteiro do indexador. Antes, o zurg cortava o magnet só para o info hash antes de adicionar o torrent. Assim, o nome de exibição e os trackers nunca chegavam à conta. Em um indexador que só tem magnet, o nome de exibição é o único lugar onde o nome do lançamento existe. Um torrent não cacheado ficava na lista da conta com um hash de 40 caracteres. Para um torrent que ninguém semeia, esse é o único nome que ele vai ter.

Agora o magnet chega à conta do jeito que o cliente enviou. O Repair, a watchlist do Plex e as bibliotecas portáteis ainda adicionam só o hash puro, porque não têm nenhum nome para repassar.

## O despejo de .strm contém apenas arquivos que um player consegue abrir {#the-strm-dump-holds-only-files-a-player-can-open}

`save_strm_files` costumava gravar um .strm para cada arquivo selecionado de um release. Legendas, pôsteres, NFOs e volumes PAR2 viravam cada um uma entrada da biblioteca que não abria nada. TorBox e AllDebrid marcam todos os arquivos como selecionados. O mesmo acontece com um post Usenet com seus arquivos de reparo ao lado do vídeo. Agora só vídeo e áudio reconhecidos recebem um .strm, junto com qualquer extensão listada em `addl_playable_extensions`. Um vídeo dentro de um conjunto RAR continua sendo gravado, mas os volumes ao redor não. As entradas gravadas por versões anteriores são removidas na próxima vez que o release for percorrido.

Vários caminhos de gravação também mandavam o servidor de mídia fazer uma varredura antes de os arquivos .strm existirem. Plex, Jellyfin ou Emby podiam olhar para uma pasta vazia e não indexar nada. Nada pedia para ele verificar de novo até que o release mudasse. Agora os arquivos são gravados primeiro em todos os caminhos.

## Mover a pasta do zurg não deixa mais o cache do mount órfão {#moving-the-zurg-folder-no-longer-strands-the-mount-cache}

O cache do mount rclone guarda o que ele lê em `data/rclone-cache`. O rclone nomeia esse cache de acordo com a própria configuração. A configuração inclui o caminho completo da pasta `data/local` do zurg. Mover a pasta do zurg ou mudar `union_writable` fazia o cache ganhar um nome novo. A árvore antiga continuava no disco, onde nenhum limite de tamanho a contava e nada a limpava. Algumas mudanças podiam deixar para trás terabytes.

No início do mount, o zurg agora pergunta ao rclone qual árvore de cache está em uso e apaga as outras. Ele registra no log quanto espaço liberou. Ele pula essa limpeza quando `rclone_extra_args` define o próprio `--cache-dir`. Defina `rclone_cache_reclaim: false` para manter as árvores antigas.

O cache em uso também é maior do que a maioria das pessoas imagina. Ele cresce até 256G por padrão e fica por aí. A varredura noturna de um servidor de mídia toca em todos os arquivos, então o limite de idade de 72 horas quase nunca remove nada. Planeje em volta do limite de tamanho. Como reduzi-lo está em [a referência de configuração](config.md#disk-the-mount-uses).

## Pôsteres e arquivos .nfo continuam caindo em `__magic__` {#posters-and-nfo-files-keep-landing-in-__magic__}

A cliente que escreve pelo mount do zurg coloca os arquivos novos em `data/local`. Essa é a pasta onde o `__magic__` guarda seus sidecars. O zurg contava cada arquivo ali contra o `sidecar_budget_mb`. Alguns vídeos que um \*arr gravou pelo mount podiam consumir o orçamento inteiro. Depois disso, todo .nfo e todo pôster era recusado como se a árvore estivesse cheia. Aumentar o orçamento nunca ajudava. Um arquivo maior que `sidecar_max_mb` não pode ter vindo pelo caminho de sidecars do zurg. Esses arquivos não contam mais contra o orçamento. O zurg os lista uma vez na inicialização, porque eles continuam ocupando espaço em disco.

Apagar um caminho do `__magic__` que já não existe agora funciona. O mount consegue remover um sidecar compartilhado dos dois lados sem quebrar a limpeza de uma importação.

## Uma reprodução no Stremio tenta a próxima release quando a primeira expira {#a-stremio-play-tries-the-next-release-when-the-first-has-aged-off}

A clique no Stremio costumava significar uma única release. Se essa release não tivesse nada reproduzível, a reprodução falhava com um 404. A causa mais comum é um post que saiu do servidor de notícias. A lista de streams podia mostrar uma dúzia de outras releases.

Agora, quando uma reprodução é recusada, o sistema tenta até mais duas linhas da mesma lista ranqueada. Ele começa depois da linha que você escolheu. Assim, o fallback é da mesma resolução e menor, ou da faixa logo abaixo. Nunca é uma release maior que você deixou passar. Uma release que ainda está sendo buscada responde 503, como antes, e apertar play de novo a pega. Cada tentativa gasta uma busca no indexador e deixa a release na biblioteca. Os links de reprodução criados antes dessa mudança continuam funcionando como sempre funcionaram.

## As listas do Stremio mostram todas as resoluções e uma variedade de tamanhos {#stremio-lists-show-every-resolution-and-a-spread-of-sizes}

O limite da lista de streams costumava contar em toda a lista. Os resultados em 4K ficam no topo, e um título popular tem mais deles do que o limite. A lista podia ficar cheia de remuxes de 20 a 40 GB e esconder todos os lançamentos em 1080p e 720p que a busca tinha encontrado. Agora `stremio.max_results` conta por resolução e o padrão é 5. Um valor que você definiu manualmente mantém o mesmo número e passa a valer para cada resolução.

Dentro de cada resolução, a lista antes mantinha só os lançamentos maiores. Quem era cortado era o encode de 4 GB que um celular ou notebook consegue reproduzir. Agora cada resolução mantém escolhas igualmente espaçadas, do lançamento maior até o menor. As duas pontas são sempre incluídas.

A descrição de cada stream agora termina com há quanto tempo o lançamento foi postado. Ela aparece como `3d`, `126d` ou `2y`. A idade é a melhor pista de que um post pode ter saído do servidor de notícias Usenet. Resultados em cache feitos antes dessa mudança não mostram idade até que o cache daquele título seja atualizado.

O manifesto do addon agora traz a versão real do build, em vez de `0.1.0`. O `zurg --version` mostra os mesmos detalhes de build que o `zurg version` e não precisa de arquivo de configuração.

## Releases saudáveis deixam de desaparecer da biblioteca {#healthy-releases-stop-disappearing-from-the-library}

A falha de conexão ou de consulta DNS na API do Real-Debrid agora marca a conta como temporariamente indisponível. Antes, isso marcava arquivos saudáveis como quebrados. Depois, eles ficavam esperando reparo quando a rede voltava.

A limpeza depois de uma atualização da biblioteca costumava esperar a análise de mídia em segundo plano terminar. Quando ela rodava, uma atualização mais recente já podia ter adicionado de volta um lançamento. A limpeza atrasada então o removia de novo. Agora a limpeza termina antes de uma atualização retornar. A análise de mídia continua rodando em segundo plano.

## O Kodi consegue navegar pelo compartilhamento WebDAV {#kodi-can-browse-the-webdav-share}

As listagens do WebDAV agora mostram o caminho completo de cada pasta e arquivo, com o prefixo `/dav/` incluído. O Kodi e outros players mais rigorosos costumavam remover esse prefixo e não conseguiam abrir pastas nem mídias. Nomes com caracteres escapados e caminhos dentro de arquivos mantêm seus endereços.

## Um servidor de notícias ocupado não deixa mais buracos em um stream {#a-busy-news-server-no-longer-puts-holes-in-a-stream}

Um servidor de notícias pode responder "no such article" para um artigo que ele tem, enquanto está ocupado. Antes, o zurg confirmava essa resposta algumas centenas de milissegundos depois, na mesma conexão. Em seguida, ele entregava o trecho como zeros e dava o artigo como perdido por um dia. Uma leitura de 32 MiB voltou com 384,000 bytes zero de um artigo que o servidor entregou corretamente um minuto depois.

Agora, um artigo recusado é consultado mais uma vez, um segundo depois. A segunda consulta vai por outra conexão, onde haja uma livre. A leitura espera essa resposta em vez de preencher o buraco. Um artigo que realmente sumiu continua sendo entregue como silêncio e reparado como antes. Por isso, uma release com problemas demora cerca de um segundo a mais para chegar a esse silêncio.

Um artigo cuja conexão fica muda também é consultado mais uma vez, em outra conexão. Antes, isso fazia falhar a resposta inteira. Um stream RAR respondia 500 para um artigo que o provedor só estava demorando para enviar.

## Escolha como o zurg se identifica para os serviços que ele chama {#choose-how-zurg-identifies-itself-to-the-services-it-calls}

As requisições para serviços debrid e indexadores agora usam um User-Agent genérico de navegador por padrão. As buscas de legendas também usam, e não enviam mais `zurg v0`. Essas requisições também deixam de enviar os cabeçalhos origin e referrer, junto com os próprios cabeçalhos do zurg. Isso vale também em redirecionamentos. Um redirecionamento não pode vazar o caminho privado nem a API key da URL anterior.

`user_agent` define outro agente, e `omit_user_agent` faz com que nenhum seja enviado. As chaves `outbound_*` definem os nomes de cliente e de dispositivo que Plex, Jellyfin e Emby veem. Todas estão no painel, em Network & Connectivity, e passam a valer depois de reiniciar. As conexões Usenet não enviam nenhum identificador de software. Isso remove os identificadores próprios do zurg. Não torna você anônimo.

Os detalhes estão em [Outbound identity](outbound-identity.md).

## O zurg esvazia a lixeira do Plex por padrão {#zurg-empties-the-plex-trash-by-default}

zurg desativa a opção "Empty trash automatically after every scan" do Plex. Caso contrário, um scan que encontra um mount temporariamente ilegível apagaria a biblioteca em vez de deixá-la de lado. O que ficou para trás passou despercebido. O Plex já não coletava entradas mortas, e a remoção feita pelo próprio zurg era opcional. Por padrão, então, ninguém as coletava. As entradas cujos arquivos já tinham sumido se acumularam. O caso mais visível foi o de um arquivo movido entre pastas da biblioteca, cuja entrada antiga ficava lá para sempre.

Com `plex_trash_sweep_every_mins` não definido, a limpeza da lixeira agora roda a cada 60 minutos. Ela não roda quando o Plex ainda está esvaziando a própria lixeira. Remove uma entrada por vez e nunca uma que ainda tenha arquivo. Só roda em um mount que esteja lendo. Tudo o que ela não consegue avaliar fica marcado como quebrado por 14 dias antes. Escreva `plex_trash_sweep_every_mins: 0` para manter a remoção desligada e esvaziar a lixeira por conta própria.

Essa configuração não devolve ao Plex o esvaziamento da lixeira. Para isso, a página de configuração agora tem a opção Let Plex Empty Its Own Trash. O risco que ela traz está escrito ao lado dela.

A restauração também funciona agora. O Plex pula um scan comum de uma pasta que ele já escaneou. Uma série na lixeira cujos arquivos já tinham voltado podia continuar lá scan após scan. A limpeza agora pede ao Plex um scan forçado dessa pasta. Um scan iniciado manualmente pelo dashboard também alcança os caminhos `__magic__` a partir dos quais uma biblioteca Usenet é indexada. Antes, ele não encontrava nenhuma seção do Plex e não fazia nada.

Como os dois coletores dividem o trabalho está descrito em [Plex](../guides/plex.md#who-empties-the-trash).

## Arquivos danificados listam os bytes corretos ou nada {#damaged-archives-list-the-right-bytes-or-nothing-at-all}

Alguns conjuntos RAR danificados costumavam listar um vídeo que tocava os bytes errados. Um conjunto com um volume faltando no meio entregava o resto do arquivo deslocado, com uma cauda de zeros. Esse tipo de conjunto agora é recusado. Um conjunto cujo primeiro cabeçalho não podia ser lido tinha os bytes seguintes deslocados. O zurg agora lê primeiro os cabeçalhos de continuação, para que todos os offsets se mantenham corretos. Arquivos depois do filme no último volume também são mantidos.

Um marcador de fim RAR4 costumava ser confundido com criptografia. Conjuntos divididos com blocos finais preenchidos perdiam o primeiro volume. Agora eles listam o vídeo completo.

Um NZB com 10% ou mais de seus artigos faltando é recusado antes de qualquer coisa ser servida. Conteúdo que o PAR2 já reconstruiu continua tocando.

As listagens de arquivos existentes são reconstruídas, para que essas correções cheguem aos lançamentos que já estão na biblioteca.

## Bibliotecas grandes podem devolver memória ociosa {#large-libraries-can-give-idle-memory-back}

`library_detail` decide se a lista de arquivos de cada release continua na memória. `resident` mantém todas elas e continua sendo o padrão. `lazy` libera as listas de arquivos que ninguém leu há `library_detail_idle_secs`. As listagens continuam disponíveis, e uma lista de arquivos volta do disco quando algo a lê. `auto` faz o mesmo, mas só quando há pressão sustentada de memória no host ou no container. Packs de temporada grandes ocupam bem menos memória em qualquer um dos dois modos. Uma cópia de recuperação compactada protege a lista de arquivos caso o cache em disco dela seja danificado. Alterações não salvas nunca são liberadas. O dashboard oferece os três modos. Para mudar, é preciso reiniciar.

A inicialização também usa menos memória quando o histórico de downloads do Real-Debrid é grande. Salvar e carregar esse histórico e os caches da biblioteca não cria mais cópias extras deles.

Os trade-offs estão em [the configuration reference](config.md#library-detail).

## A watchlist do Plex e os pedidos do Seerr compartilham uma só fila {#plex-watchlist-and-seerr-requests-share-one-queue}

O bloco `acquisition:` junta os itens da watchlist do Plex e os pedidos do Seerr em uma única fila. Os dois são pesquisados nos seus indexadores Newznab e os resultados vão para o backend de Usenet. Os pedidos do Seerr só são acompanhados depois de aprovados. Só as temporadas pedidas são baixadas. Um pedido em 4K fica separado de um em 1080p. Os pedidos abertos no Seerr são verificados de novo para episódios que acabaram de ser lançados.

O progresso agora sobrevive a um reinício. Isso inclui os prazos de nova tentativa, a contagem de tentativas e quais episódios já foram concluídos. Uma aquisição interrompida continua de onde parou. Uma que já tinha terminado só tenta de novo remover o item da watchlist e não pesquisa de novo. O estado salvo faz parte dos backups normais. As configurações `watchlist:` que você já tem continuam funcionando sem mudanças.

A configuração está em [Acquisition](../guides/acquisition.md).

## Bibliotecas do debrid podem viver em arquivos locais portáteis {#debrid-libraries-can-live-in-portable-local-files}

Uma conta de debrid agora pode pegar a sua biblioteca de uma pasta com arquivos `.zurgtorrent`, em vez de usar a lista da própria conta. O `zurg export-torrents` grava uma biblioteca existente nesses arquivos. Eles descrevem o conteúdo e não guardam credenciais nem links de download. Assim, a biblioteca pode ser compartilhada. Quem recebe reproduz pela própria conta, e os limites do provedor dessa pessoa continuam valendo. Importar, listar e atualizar os arquivos não acrescenta nada à conta.

As configs existentes continuam funcionando. Os novos backups usam o formato 2 e precisam deste build ou de um mais novo para serem restaurados.

A exportação e a configuração estão em [Bibliotecas locais](../guides/local-libraries.md).

## Caches de leitura sobrevivem a um reinício {#read-caches-survive-a-restart}

zurg agora mantém os caches de leitura em disco entre reinícios. Isso inclui os NZBs analisados e os artigos Usenet decodificados. Também inclui os layouts de arquivos compactados, os blocos decodificados desses arquivos e os links de entrega. Depois de um reinício, o zurg não precisa mais analisar todo NZB nem ler de novo o cabeçalho de todo arquivo compactado. Cada cache de bytes tem limite padrão de 512 MiB. `zurg backup --include-caches` inclui os caches em um backup para uma restauração com cache aquecido.

Pedidos para o mesmo arquivo do AllDebrid ou do TorBox feitos ao mesmo tempo agora compartilham uma única consulta de link.

As configurações e os limites estão em [Caches persistentes](../internals/persistent-caches.md).

## Grabs de Usenet são verificados com mais cuidado antes de aparecerem como Completed {#usenet-grabs-are-checked-more-closely-before-they-read-completed}

Antes de um grab aparecer como Completed, o zurg pergunta ao servidor de news sobre os primeiros dezesseis artigos e o último artigo de cada arquivo de conteúdo. Antes, ele checava só o primeiro. Isso deixava passar falhas no cabeçalho da mídia. As verificações são enviadas em um lote por arquivo, então arquivos grandes não estouram mais o tempo limite.

Uma release cujos artigos ausentes foram totalmente reconstruídos pelo PAR2 agora é importada. Antes, ela falhava porque os artigos originais ainda estavam faltando no servidor. Um reparo parcial continua não contando.

`sabnzbd.history_limit` agora pode usar o mesmo valor de limite de histórico do Sonarr ou do Radarr. Assim, um grande acúmulo de jobs finalizados é esvaziado em lotes maiores. Os dois lados precisam usar o mesmo número. O padrão continua sendo sessenta.

## `enforce` deixa em paz os recursos do Plex que você consegue ver {#enforce-leaves-the-plex-features-you-can-see-alone}

`plex_settings_policy: enforce` não desliga mais as miniaturas de prévia na barra de progresso nem as imagens de capítulos. Também não desliga o nivelamento de volume nem a análise sonora. Cada um deles decodifica arquivos inteiros, e isso consome banda em um mount de debrid. Mas cada um também gera algo que você consegue ver. Agora eles ficam junto com Skip Intro e Skip Credits, como uma questão de gosto. O zurg continua mostrando quanto cada um custa. Só que ele deixa de fazer a escolha por você. O grupo de banda agora inclui apenas a análise cujo resultado ninguém olha.

## Links de debrid expirados se recuperam sem falhar a reprodução {#expired-debrid-links-recover-without-failing-playback}

A link do TorBox cujo token assinado ficou desatualizado agora recebe um novo. Leitores que esperam pelo mesmo arquivo compartilham essa única consulta. Falhas repetidas pausam a reprodução sem marcar o arquivo como quebrado.

Quando um servidor de download do TorBox, Real-Debrid ou AllDebrid pede para o zurg esperar, ele agora espera o tempo que for indicado. Também para de tentar de novo um servidor que continua recusando. Isso vale para reprodução, verificações de link e leituras de arquivos compactados. Um link revogado aberto por meio de `__downloads__` também recebe um novo.

## O zurg se atualiza sozinho {#zurg-updates-itself}

`zurg update` substitui o binário em execução pelo nightly mais recente para apoiadores. Ele lê o feed de releases usando o login do GitHub CLI, se existir um, e `GITHUB_TOKEN` ou `GH_TOKEN` caso contrário. Antes de substituir qualquer coisa, verifica se os downloads funcionam e informa a versão esperada. A troca é feita por rename, então a atualização não falha enquanto o zurg está rodando. Se um build já estiver no nightly mais recente, ou for mais novo que ele, nada é feito. Dentro de um container, o comando se recusa e aponta para o pull da imagem, pois um binário substituído ali se perde na próxima recriação; `--force` ignora essa verificação. Os instaladores ganharam um modo `update` equivalente para builds antigos que não têm o comando.

Por plataforma: [Linux](../setup/linux.md#updating-zurg), [macOS](../setup/macos.md#update-zurg), [Windows](../setup/windows.md#updating-zurg), [Docker](../setup/docker.md).

## Uma configuração do Plex pode ser excluída da política {#one-plex-setting-can-be-opted-out-of-the-policy}

`plex_settings_ignore` nomeia preferências do Plex que o zurg deixa em paz, independentemente do que `plex_settings_policy` diz. Ela existe para a configuração que realmente precisa de uma delas: uma biblioteca cujos arquivos mudam de pasta depende de o Plex esvaziar a própria lixeira para limpar a entrada que fica para trás, e a política padrão desliga isso. Mas mudar para `warn` para recuperar essa opção também abriria mão das proteções de eventos do sistema de arquivos que ficam ao lado dela.

Uma configuração ignorada continua sendo lida e continua sendo reportada, no painel e como `skip` em `zurg plex-settings`. Ela só nunca é gravada, nunca gera aviso e nunca aparece atrás do banner da lixeira. Ignorar uma configuração de segurança é por sua conta e risco, e o zurg avisa isso uma vez na inicialização. Um id que não corresponde a nada é reportado e a configuração continua protegida, então um erro de digitação não pode passar como uma exclusão.

As configurações em si, e o que cada nível de política faz com elas, estão em [Plex](../guides/plex.md#recommended-plex-settings).

## Instaladores de uma linha para todos os hosts suportados {#one-line-installers-for-every-supported-host}

Instalações novas agora têm bootstraps opcionais de uma linha para Linux, macOS, Windows e Docker no Linux. Eles verificam ou instalam os pré-requisitos da plataforma, usam o login no navegador do GitHub para acesso de patrocinador, baixam a arquitetura correta e passam o controle para `zurg setup` e `zurg doctor`. Binários e configs existentes são preservados, e todos os guias manuais continuam disponíveis.

## A configuração pergunta quais provedores configurar {#setup-asks-which-providers-to-configure}

Instalações novas do `zurg setup` não assumem mais o Real-Debrid. O instalador interativo pergunta por um ou mais provedores, na ordem de prioridade, e coleta só as credenciais dos provedores escolhidos. Instalações não interativas podem repetir `--provider` e usar as flags de arquivo de token específicas de cada provedor ou variáveis de ambiente. As configs existentes continuam sendo preservadas, e as entradas antigas do Real-Debrid (`--token-file`, `TOKEN` e `RD_TOKEN`) seguem compatíveis quando forem passadas explicitamente.

## Um burst maior que a janela de histórico do Sonarr não perde mais importações {#a-burst-larger-than-sonarrs-history-window-no-longer-loses-imports}

O Sonarr e o Radarr pedem ao SABnzbd todos os jobs da fila, mas só os sessenta mais recentes do histórico. Isso costuma funcionar bem com um downloader de verdade: as conclusões chegam aos poucos, e o cliente remove cada uma depois de importar. Uma biblioteca de NZB em cache é diferente. Uma busca em massa por temporada pode terminar centenas de jobs de episódios individuais antes da próxima consulta do cliente, e o zurg costumava remover todos da fila, retornando apenas sessenta no histórico. Qualquer job além dessa página ficava ausente das duas respostas, então o cliente nunca o importava nem o marcava como falho, e o release ficava na raiz de `__magic__` indefinidamente.

Agora o zurg mantém os jobs concluídos além dessa página visível na fila. Conforme o cliente importa e remove os primeiros sessenta, as próximas conclusões avançam para o histórico. Assim, uma temporada baixada como episódios individuais é esvaziada em lotes limitados, em vez de disputar uma janela de tamanho fixo. Um season pack continua se comportando como um único job.

## Uma exclusão pelo mount sempre funciona, e `dav_allow_delete` foi removido {#a-delete-through-the-mount-always-works-and-dav_allow_delete-is-gone}

Apagar um arquivo de um servidor de mídia apontado para o mount não fazia nada visível antes: o zurg recusava o WebDAV DELETE com um 403, o rclone transformava isso em um erro de I/O, e o cliente reportava uma falha sem causa alguma. O Plex responde um `400 Bad Request` simples e não registra nada, então o botão simplesmente não funcionava e nada dizia o motivo. A chave que permitia isso, `dav_allow_delete`, foi removida; um DELETE pelo mount agora é aceito em todos os casos, sem nenhuma configuração. Um arquivo de config que ainda define a chave não gera erro, porque chaves desconhecidas são ignoradas; ela só deixou de fazer qualquer efeito.

O que essa chave protegia não sumiu, então vale deixar claro: o rclone não tem como expressar "sobrescrever" e, ao gravar de novo um arquivo, envia um DELETE seguido de um PUT. Isso significa que um programa que reescreve um arquivo no lugar (um gravador de `.nfo`, um processo de trickplay, um rename do \*arr, ou um `touch` qualquer) acaba apagando o release da conta debrid em vez de substituir o arquivo. E como o mount usa as credenciais do próprio rclone, nada do lado de cima consegue distinguir isso de uma exclusão deliberada. A parte do PUT ainda é recusada, e é isso que impede a sequência de se completar silenciosamente. Se algum programa grava dentro do seu mount, defina `mount_read_only: true`, que faz a escrita falhar no kernel antes mesmo de chegar ao zurg.

## A watchlist do Plex adquire conteúdo pelos seus indexadores Newznab {#the-plex-watchlist-acquires-through-your-newznab-indexers}

O monitor da watchlist agora funciona, e usa seus próprios indexadores. A versão antiga pesquisava usando uma chave de API do DMM e parou de funcionar sem aviso quando o Plex moveu a watchlist para o host discover, já que o endpoint que ela consultava passou a responder 404. Agora ele consulta o host certo, e cada novo item da watchlist é pesquisado nos indexadores Newznab que você já configurou. Um filme vira a melhor release correspondente. Uma série é adquirida temporada por temporada, **dando preferência a season packs** em vez de episódios avulsos. Se ninguém postou um pack de uma temporada, ele cai nos episódios avulsos, com a melhor release para cada episódio. E se o link NZB da release escolhida falhar ao ser baixado (por exemplo, um 429 de limite de rajada do indexador), o monitor passa para o próximo candidato no ranking, em vez de perder o item. O NZB escolhido vai para o backend de Usenet seguindo as mesmas regras de nomenclatura do endpoint SABnzbd e do addon Stremio, então as três superfícies reconhecem os downloads umas das outras e não duplicam pedidos. Um item só sai da watchlist depois que algo foi realmente adquirido. Antes, a ordem era remover primeiro e verificar depois, então qualquer falha apagava o item da sua lista sem avisar.

Configure tudo pelo novo bloco `watchlist:`, com as chaves `enabled`, `check_every_secs` (padrão 60), `indexers` (se vazio, usa `stremio.indexers`), `max_size_gb` (padrão 40, para filmes e episódios avulsos), `max_season_size_gb` (padrão 100, para season packs) e `quality` (`best`, `4k`, `1080p`, `720p`, `smallest`). As chaves legadas `plex_watchlist_*` mantêm o mesmo significado. Um `plex_token` é tudo o que o monitor precisa do Plex. Ele se comunica com o serviço em nuvem do Plex, então funciona sem problemas em uma instância sem `plex_server_url`. As pesquisas de séries começam pelo id do TVDB e, se não encontrarem nada, tentam mais uma vez pelo id do IMDb. Isso acontece porque os indexadores organizam séries pelo TVDB, e o mapeamento de IMDb em nível de série deles é irregular o suficiente para que uma série muito indexada retorne zero resultados numa busca por imdbid.

Todas as chaves estão na página de configuração em **Plex Watchlist**, e na [referência de configuração](config.md#watchlist).

## Um addon do Stremio sobre os seus indexadores Newznab {#a-stremio-addon-over-your-newznab-indexers}

O zurg agora responde ao Stremio diretamente. Ative o bloco `stremio:`, liste seus indexadores Newznab e cole a URL `/stremio/<token>/manifest.json` que aparece no log no Stremio. O cliente pede streams pelo id do IMDb, e o zurg pesquisa nos indexadores (filmes com `t=movie`, episódios com `t=tvsearch`, com temporada e episódio). Os resultados voltam ordenados primeiro pela resolução, como streams prontos para reproduzir. Ao escolher um, o NZB é enviado para o backend Usenet, seguindo as mesmas regras de nomenclatura do endpoint do SABnzbd. Assim, um release baixado duas vezes é encontrado em vez de duplicado. Depois ele é reproduzido pelo endpoint assinado `/strm/e/`, com suporte a ranges, failover e conteúdo de dentro de arquivos. Tudo o que for reproduzido entra na biblioteca e aparece no Plex como qualquer outro release.

O token no caminho é toda a autorização. Ele é gerado e guardado em `data/stremio-token` quando a config não define nenhum. Os resultados de busca ficam em cache em `data/stremio-cache`, então reabrir um título não gera chamadas aos indexadores. O tempo de validade do cache depende de quantos resultados a busca encontrou: uma hora por resultado até quatro, e a partir de cinco usa `stremio.cache_hours` (padrão 24). Respostas vazias nunca são guardadas. Uma lista de streams em cache traz um item de atualização que limpa o cache daquele título.

Releases maiores que `stremio.max_size_gb` (padrão 40) são removidos da lista. Assim, um remux de disco completo não fica em primeiro lugar em relação a todas as opções reproduzíveis.

Tudo, incluindo o custo da primeira reprodução: [O addon do Stremio](../guides/stremio.md).

## Uma pasta é a instalação inteira do Docker, e ela é montada na primeira execução {#one-folder-is-the-whole-docker-install-and-it-mounts-on-the-first-run}

A forma documentada de iniciar o zurg no Docker era um único `docker run` com um `TOKEN`, e isso gerava um container que não montava nada. O config gerado deixava `rclone_enabled` desligado e `mount_path` sem valor, então `/zurg_mnt/zurg` ficava vazio até alguém encontrar os dois controles no Dashboard. E esse config era gravado dentro do container, então o próximo `docker pull` jogava a resposta fora junto com o cache da biblioteca. O início rápido precisava de uma nota de rodapé listando os dois, e isso é um início rápido admitindo que não funciona.

Agora o `MOUNT_PATH` já grava `rclone_enabled: true` e `mount_path` no config na execução que cria o arquivo, junto com o que o `TOKEN` já gravava. O diretório de trabalho da imagem é `/config`, e tudo que o zurg guarda é resolvido a partir dele: `config.yml`, `data/`, `logs/`, `dump/`, `strm/`, `nzbs/` e o cache do rclone. Então um único `-v ~/zurg:/config` guarda a instalação inteira, e atualizar a imagem não move nada disso. Uma primeira execução é um comando só e termina com a biblioteca montada, sem precisar de uma missão no Dashboard.

As duas variáveis são lidas **somente quando ainda não existe nenhum arquivo de config**, e são ignoradas depois disso. É a mesma regra que o `log_level` já tem em relação ao `LOG_LEVEL`, pelo mesmo motivo: um `MOUNT_PATH` esquecido em um arquivo do compose nunca pode desfazer silenciosamente um mount path alterado depois no Dashboard. Agora, na inicialização, o zurg avisa quando uma dessas variáveis está definida e não bate com o config, assim quem redeploya e não vê efeito fica sabendo o motivo.

Instalações feitas com o layout antigo não foram afetadas. O Docker cria o destino de todo bind mount, então a presença de `/app/config.yml`, `/app/data` ou `/app/logs` é o layout antigo se anunciando, e o container continua usando `/app` quando encontra qualquer um deles. A configuração completa, e o que quebra um mount visível no host, está em [Docker](../setup/docker.md).

## TorBox e AllDebrid também recebem o `.torrent`, então um grab privado não fica pendurado {#torbox-and-alldebrid-are-handed-the-torrent-too-so-a-private-grab-is-not-left-hanging}

O arquivo `.torrent` que um \*arr envia começou a viajar junto com a adição na versão anterior, mas só o Real-Debrid conseguia aceitar um. As outras duas contas ainda recebiam apenas o info hash, que, para o lançamento de um tracker privado, é a única forma que elas não conseguem usar. Nada falhava, e isso dificultava ver o problema. Medido na conta real do TorBox, um hash sem swarm público era aceito, recebia um id de torrent e ficava em `checking` com `size: -1`, sem lista de arquivos e com uma estimativa de cem dias. Era exatamente o que foi relatado em um grab do TorrentLeech que "só fica travado, nada baixa". Já o arquivo desse mesmo lançamento era respondido na hora, com o nome real, o tamanho real e a lista de arquivos, e o endpoint do qBittorrent conseguia seguir com o trabalho.

Agora as duas contas aceitam o arquivo. O `createtorrent` do TorBox e o `magnet/upload/file` do AllDebrid aceitam o arquivo no lugar do magnet e respondem no mesmo formato que a adição por magnet já usava, então nada depois da adição muda. O AllDebrid ainda informa sobre o próprio upload se ele já tinha o conteúdo, que é a única resposta de cache que essa conta dá. Testado ao vivo pelo próprio caminho de adição do zurg nas duas contas: um lançamento em cache foi enviado e voltou como `done` com 100% e a lista de arquivos em poucos segundos. Um que ninguém tinha voltou com nome, tamanho e parado por falta de peers, um estado com o qual o endpoint consegue lidar. No caso do hash, era um torrent que nunca resolvia e nunca terminava.

Uma recusa também ficou mais clara. Quando uma chamada ao TorBox era recusada com um 4xx, o chamador recebia apenas o "unexpected status code: 400" do cliente HTTP compartilhado, porque o corpo da resposta, onde o TorBox coloca o próprio código e detalhe do erro, era descartado em favor desse erro. Assim, um `.torrent` que o TorBox não aceitava chegava ao \*arr só como um número de status, sem mais nada. Agora o corpo é lido primeiro, e o motivo dado pela própria conta acompanha a recusa.

Para saber o que isso significa na hora de configurar os indexadores, veja: [Sonarr & Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## Entradas de arquivos compactados são transmitidas, decodificadas sob demanda {#compressed-archive-entries-stream-decoded-on-demand}

Uma entrada de RAR compactada ou de zip com deflate não consegue responder a uma leitura por faixa de bytes como uma entrada armazenada consegue. Os bytes dela só existem por trás de um decodificador, que precisa rodar desde o começo da entrada. Por isso o zurg recusava essas entradas: um release só com entradas compactadas respondia 415, e as entradas compactadas irmãs de entradas armazenadas eram puladas. Para um streamer, essa era a resposta honesta, mas escondia a maior parte do catálogo antigo da Usenet: todo poster que empacotou com compressão, inteirinho.

Agora essas entradas são servidas decodificando para frente sob demanda, dentro de uma janela limitada na memória. Nada é gravado em disco e nada é decodificado que nenhuma leitura pediu. A reprodução sequencial, que é o padrão que o player gera, chega na borda da janela e a avança um pouco a cada leitura. Um seek para trás, além do que a janela guardou, reinicia a decodificação desde o começo da entrada. Os bytes da entrada inteira são exatamente o que o unrar extrairia: os três arquivos jpg de um volume RAR4 compactado de verdade são decodificados byte a byte exatos em relação ao mesmo fixture lido por uma passada independente de decodificador, md5 por md5.

Para percorrer os volumes de um conjunto dividido, era preciso usar a cadeia de volumes do rardecode, que abre `.part02.rar` direto do sistema de arquivos. Os volumes do zurg ficam atrás de leitores de rede por faixa de bytes. O decodificador agora está incluído no repositório em `internal/rardecode` (MIT, upstream v1.1.3), com uma única mudança: `OpenReaderOver` recebe um abridor, então cada próximo volume vem do conjunto pelo nome que o próprio arquivo deriva.

As listagens mudam de formato por causa disso. Um release só com entradas compactadas agora apresenta o seu conteúdo (`stream_compressed_archives: false` restaura as recusas antigas), e um arquivo misto lista as suas entradas compactadas ao lado das armazenadas. Listagem versão 15.

## Sonarr e Radarr podem fazer grab de torrents, e o Prowlarr pode enviá-los {#sonarr-and-radarr-can-grab-torrents-and-prowlarr-can-push-them}

zurg pode responder aos \*arrs como se fosse um qBittorrent. Eles passam um magnet ou um `.torrent`, e ele adiciona o info hash a uma conta debrid — Real-Debrid, TorBox ou AllDebrid, a que estiver configurada. Quando o release entra na biblioteca, o torrent aparece como finished com uma pasta dentro de `__magic__` para importar. A importação é o mesmo rename que o endpoint do SABnzbd sempre fez para downloads de Usenet: uma linha na tabela `__magic__`, nenhum byte é movido.

O endpoint é registrado em `/api/v2` e `/qbittorrent/api/v2`, fica desligado até você ativar, e é protegido por uma API key que os clientes enviam como bearer token. Um pedido de download é oferecido a todas as contas que aceitam torrents, na ordem de `providers:`. Se um download para de andar — sem mudança de estágio, sem aumento de progress, durante `qbittorrent.download_timeout_mins` minutos (quinze por padrão) — ele sai dessa conta e é tentado na próxima. `0` aceita apenas conteúdo que a conta já tem em cache e recusa o resto já durante a adição, que é a única recusa com a qual os \*arrs reagem. O que a conta está fazendo com um download é convertido para os estados que os clientes entendem, com a velocidade, os peers e o tempo restante onde a conta os informa.

Uma limitação honesta: a API do qBittorrent não tem como indicar que um download falhou, então um release que nenhuma conta aceita chega ao cliente como um warning, e não como entrada em blocklist — aparece na fila com o motivo anexado, mas nunca é pedido de novo sem intervenção. O endpoint do SABnzbd não tem esse problema.

O Prowlarr fala com o mesmo endpoint para o papel que um download client tem para ele: enviar um release para a conta manualmente. Nada é importado depois de um envio pelo Prowlarr — para isso existem os \*arrs.

Passo a passo completo, capturado em uma instalação ativa: [Sonarr & Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## `__magic__`, um diretório que você pode organizar {#__magic__-a-directory-you-can-organise}

Cada diretório que o zurg serve é um filtro salvo. Um release está em `movies` porque bate com o filtro de filmes, e ao mesmo tempo está em `__all__`, em `recent` e em `movies`. Por isso nunca houve um lugar na biblioteca para *colocar* algo. Isso funciona até um programa querer mover um arquivo. O Radarr e o Sonarr importam movendo, e uma montagem que não aceita um move faz eles copiarem: cada importação puxa o release inteiro do host de debrid ou do Usenet, justamente o que a montagem existe para evitar.

`__magic__` é um novo diretório de topo que começa como uma cópia exata de `__all__`: cada release como uma pasta, contendo exatamente o que `__all__/<release>/` contém, incluindo o conteúdo de um arquivo virtualizado. Dentro dele, qualquer coisa pode ser movida para qualquer lugar. Rode `mkdir -p /mnt/zurg/__magic__/tv/Show/Season 01` e use `mv` para colocar um episódio ali, e ele estará lá: nenhum byte movido, nenhum torrent renomeado, nada baixado de novo, e `__all__` sem mudanças. Um move reescreve uma linha em uma pequena tabela, e essa tabela usa como chave o hash de conteúdo do release e o caminho do próprio arquivo dentro dele. Assim, um reparo que readiciona o release e reconstrói todos os ids em volta não perde onde você colocou as coisas. Renomear um release pelo dashboard também não.

Moves funcionam nos dois sentidos. Um arquivo pode ser movido *para dentro* de uma pasta de release, assim como para fora dela, e a pasta lista o arquivo ao lado das entradas do próprio release. Isso é o que um programa que devolve algo à pasta de onde está importando precisa ver. Quando um nome chega de duas fontes ao mesmo tempo, a escolha deliberada vence: o que você moveu vence o que o release chama por aquele nome, que vence um arquivo em `data/local`. O perdedor não é listado, em vez de aparecer duas vezes.

Excluir é a outra metade, e por padrão ele oculta em vez de destruir. Um `rm` dentro de `__magic__` tira a entrada de `__magic__` e a deixa em `__all__` e em todos os diretórios de filtro. Assim, um cliente que reorganiza a biblioteca não consegue perder nada. Uma pasta de release pode sumir do mesmo jeito, o que permite que o Sonarr apague a pasta do job depois de uma importação sem tocar no release de onde acabou de importar. `magic.allow_delete: true` ativa o significado mais forte para arquivos, em que o conteúdo também vai embora. Uma pasta de release e um diretório só ocultam, independentemente desse valor.

Está desligado por padrão, porque é uma árvore gravável, e um \*arr apontado para a pasta raiz errada pode reorganizar uma biblioteca:

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

As chaves `sidecar_` são para clientes que montam `/dav` diretamente, em vez de pela montagem do próprio zurg. Esses clientes enviam ao zurg um `PUT` de um novo `.nfo`, poster ou faixa de legenda. Agora ele grava o corpo em `data/local/__magic__/…`, a mesma árvore onde a montagem do próprio zurg já grava esses arquivos. Assim, as duas visões mostram um diretório só em vez de dois, e o arquivo é lido de volta com suporte a ranges, tamanho e data de modificação como qualquer outro. Os limites impedem que isso vire, sem perceber, um armazenamento de arquivos geral. Um arquivo maior que `sidecar_max_mb` é recusado com 413, e um que levaria a árvore além de `sidecar_budget_mb` é recusado com 507. Nada que a biblioteca responde pode ser sobrescrito: uma pasta de release, uma entrada dela ou um caminho para onde algo foi movido resulta em 403. E um move nunca destrói um arquivo real para abrir espaço para uma linha.

Duas coisas valem a pena saber antes de apontar qualquer coisa para lá. Os diretórios de filtro não são alterados de propósito, então um release movido dentro de `__magic__` continua em `recent` e `movies` com o próprio nome. Aponte um servidor de mídia para `__magic__` **ou** para os filtros, não para os dois. E a montagem sempre foi gravável em uma direção: qualquer coisa realmente nova escrita nela, como um `.nfo`, uma legenda ou um poster, vai para o `data/local` do próprio zurg e é mesclada na listagem. É por isso que sidecars ao lado de um release simplesmente funcionam, e por que o teste de escrita da pasta raiz de um \*arr passa.

`dav_allow_rename` e `dav_allow_delete` não têm nada a ver com nada disso. Eles protegem o caminho que renomeia e exclui o que a conta de debrid tem, e uma escrita dentro de `__magic__` não chega a nenhuma conta. `mount_read_only: true` continua sobrescrevendo tudo.

O dashboard tem uma página para isso, em `/magic/`. Ela mostra cada linha que a tabela guarda, agrupada por release, dizendo o que cada uma é, de qual arquivo de qual release veio e de onde esse arquivo é servido agora. Também mostra quantas linhas existem, quanto o journal e o snapshot ocupam em disco e quanto do `sidecar_budget_mb` os arquivos reais ao lado da biblioteca estão usando. Ela ainda informa o tamanho de todo o `data/local`, que é o número que diz se algo está importando por cópia. Um cliente que copia em vez de mover coloca os bytes ali, e nada mais no dashboard jamais mostraria isso.

Três dos estados que ela mostra não poderiam ser alcançados por um cliente. Um posicionamento pode ser **reset**, e o arquivo volta para onde a biblioteca o coloca. Uma tombstone pode ser **unhidden**, e a entrada volta a ser listada. E uma linha **dangling**, cujo release, ou cujo arquivo dentro dele, a biblioteca não tem mais, pode ser descartada, uma por uma ou todas de uma vez. Esse último é território novo. Uma linha assim não resolve para nada, então nenhum cliente consegue listá-la, movê-la ou excluí-la. Ela é mantida de propósito em vez de descartada, porque um reparo que traz o release de volta também traz o posicionamento de volta junto. Até agora não havia onde fazer essa limpeza.

Os sidecars também aparecem listados, com a mesma classificação aplicada a eles. Um arquivo real numa pasta que ninguém mais responde, como um `.nfo` ao lado de um release que saiu da biblioteca ou dentro de um posicionamento que foi esquecido, aparece como **orphaned** e é contado separado do resto. Nada é varrido, pelo mesmo motivo que uma linha dangling não é: o arquivo ainda é seu, e um reparo que traz o release de volta volta a responder pela pasta. Excluir um desses lá de fato apaga o arquivo, exatamente como um `DELETE` pela montagem. Cada um desses botões manda a montagem esquecer as listagens que mudou, porque ela guarda um diretório em cache por doze horas com polling desligado.

`magic:` e `sabnzbd:` agora são editáveis na página de configuração, e os dois estão marcados como **Restart Required** porque isso é sério. As rotas que servem `__magic__` e o endpoint do SABnzbd são decididos uma única vez, na inicialização, exatamente a partir desses valores. Ligar um deles grava no `config.yml` e não muda nada na execução que está respondendo. A página `__magic__` diz isso com todas as letras, em vez de mostrar um namespace vazio como se estivesse tudo bem.

### Sonarr e Radarr agora podem entregar um NZB ao zurg {#sonarr-and-radarr-can-now-hand-zurg-an-nzb}

O motivo de `__magic__` existir é dar a um \*arr um lugar de onde importar, e o zurg agora fala a outra metade: um endpoint em `/api` que responde ao Sonarr e ao Radarr como se fosse um SABnzbd. Aponte-os para o host e a porta do zurg, cole a API key, e os grabs caem em `nzbs/` para o backend Usenet. Quando o release já estiver na biblioteca, o job é reportado como Completed com uma pasta dentro de `__magic__`, e a importação é um rename dentro da montagem: uma linha na tabela, nenhum byte lido, nada baixado da Usenet para colocar numa pasta de série.

```yaml
sabnzbd:
  enabled: true
  api_key: ""          # left empty, zurg generates one and logs it once
  categories: [tv, movies]
  complete_dir: ""     # defaults to <mount_path>/__magic__; set it to what a containerised *arr sees
```

Desligado por padrão, e ele precisa das duas partes para ser útil: um provider `nzb` para ler o NZB, e `magic.enabled` para ter de onde importar. O endpoint não fica atrás da autenticação básica do zurg, porque nenhum dos \*arr envia esse tipo de autenticação para um download client, e a camada HTTP deles interpreta um 401 como "não foi possível conectar". A API key é a única barreira, então trate essa porta com cuidado. As root folders ficam **dentro** de `__magic__` (`__magic__/tv`, `__magic__/movies`), nunca em `__magic__` nem acima dele, senão a verificação de integridade das root folders dos clientes tem algo a reclamar.

Uma coisa a saber antes de trocar uma biblioteca: **o sinal de falha é parcial**. Um release que a biblioteca tem, mas sem nada importável dentro (todos os arquivos quebrados, apagados ou filtrados, ou nada além de scaffolding de reparo e sidecars, que é o que acontece com um NZB só com volumes de recuperação), é reportado como `Failed`. Isso faz os dois clientes colocarem o release na blocklist e buscarem uma alternativa. Um conjunto RAR conta como conteúdo, já que o zurg transmite o vídeo direto dele. A exceção é um conjunto que o zurg não consegue transmitir de jeito nenhum, com só entradas comprimidas: esse é reportado como Failed a partir do momento em que algo o abriu e descobriu isso. Esse veredito fica guardado com o release, porque descobri-lo custa uma leitura de todos os volumes do conjunto. O que não é reportado é um post cujos artigos já saíram do servidor de notícias. O zurg ainda não verifica isso, então um release morto é reportado como Completed como qualquer outro e falha na primeira leitura, e o Sonarr vê uma falha de importação em vez de uma falha de download. Esse caso ainda exige uma decisão manual. Todo o resto do fluxo funciona, incluindo a limpeza pós-importação: a pasta do job que o Sonarr apaga vira um tombstone, e o release continua em `__all__`.

Um grab não espera o próximo poll de mudanças. O zurg relê o diretório de watch assim que escreve nele, e isso só para as contas Usenet. Um season pack são vinte grabs em poucos segundos, e reler uma biblioteca debrid com dezenas de milhares de torrents para notar um arquivo local seria vinte vezes trabalho à toa. Se nenhum provider `nzb` estiver configurado, o zurg agora avisa isso na inicialização, em vez de aceitar grabs que ninguém vai ler.

A página `__magic__` lista os jobs, somente leitura: o `nzo_id` pelo qual cada cliente conhece um grab, sua categoria, quando chegou, se a biblioteca já lista o release e, quando lista, a pasta de onde o \*arr importa.

A configuração completa, incluindo o mapeamento de caminho remoto para \*arrs em contêiner e o que cada erro do teste de conexão significa, está em `docs/sabnzbd.md`.

## O mount usa mais da largura de banda que ele tem disponível {#the-mount-reaches-more-of-the-bandwidth-it-has}

Ler um arquivo pelo mount do rclone estava mais lento do que buscar os mesmos bytes por HTTP. O motivo era como uma leitura começa, e não como ela roda. O primeiro bloco era pedido com 4 MB e dobrava a partir daí. Assim, uma leitura que começava em um offset frio passava a maior parte do tempo abaixo da velocidade que a conexão realmente aguentava. E cada seek inicia uma leitura nova. Agora o primeiro bloco é pedido com 32 MB.

Medimos em um host com cerca de 70 MB/s de banda de download útil, testando cada configuração por vez para que um minuto lento não caísse só em uma delas. A mediana de throughput do mount no Real-Debrid foi de 49 para 57 MB/s, e no TorBox a melhora foi parecida. O AllDebrid ganha menos aqui porque o limite dele é por conexão, e não por conta.

O tamanho do bloco é todo o efeito. O read-ahead do FUSE também foi aumentado durante os testes, mas não mudou nada. E isso não custa banda extra: o tamanho do bloco é o quanto é *pedido*, não o quanto é transferido, e o rclone para de puxar quando a reprodução para. Uma leitura de 4 MB ainda baixava 6 MB, igual ao que acontecia com o read-ahead desligado de vez. Então, uma biblioteca que é navegada e amostrada, em vez de assistida do início ao fim, não baixa mais do que antes.

Você não precisa mudar nada. O novo valor já vem como padrão, e o `rclone_extra_args` continua substituindo ele.

## `zurg benchmark-my-setup` mostra a velocidade real da sua configuração {#zurg-benchmark-my-setup-answers-how-fast-the-setup-actually-is}

Até agora, a única forma de saber se um stream lento era culpa da conta, do host ou do mount era chutar. O novo comando lê bytes reais pelo mesmo caminho que um player usa e mostra a distribuição — mínimo, mediana, média, máximo e tempo até o primeiro byte — em vez de um único número que qualquer amostra azarada poderia ter produzido.

Ele roda três fases. Primeiro, cada conta sozinha, que é o número para comparar com o que o serviço promete. Depois, todas as contas configuradas ao mesmo tempo, a única fase que consegue distinguir um provedor lento de um uplink saturado: contas que sustentam 70 MiB/s cada uma sozinha, mas 25 MiB/s juntas, são um único gargalo, não três problemas, e o relatório diz qual dos dois está vendo. Por fim, a mesma leitura pelo mount do rclone, onde a diferença em relação à primeira fase mostra o custo do FUSE e do VFS. A fase do mount é pulada quando `rclone_enabled` está desligado.

As amostras são feitas em offsets aleatórios, e isso não é detalhe. Todas as camadas por baixo fazem cache — o VFS do rclone guarda o que já buscou, e um edge de CDN do debrid guarda o que já serviu — então ler de novo o mesmo offset mede esses caches, e não o link. Em uma configuração real, o mesmo arquivo deu 47 MiB/s na primeira leitura e 285 MiB/s na segunda leitura da mesma região.

O tamanho da amostra muda o que o número do mount significa, e o relatório avisa sobre isso. O rclone abre um arquivo com `vfs_read_chunk_size` e vai dobrando a partir daí, então uma amostra curta passa a maior parte do tempo ainda em rampa: medido em uma configuração, deu 47 MiB/s com amostra de 256 MiB contra 88 MiB/s com 1 GiB, com HTTP estável em torno de ~70 nos dois casos. O padrão de 128 MiB é o número de busca e scrub; `--sample-mb 1024` é o teto sustentado. Nenhum dos dois está errado, e a execução diz qual dos dois você acabou de medir.

`-n` define o número de iterações, `--provider` limita a execução às contas nomeadas, `--skip-mount` e `--skip-concurrent` removem uma fase, e `--json` emite o relatório para uso em scripts. Ele consome banda real das contas do próprio operador — iterações x tamanho da amostra por conta, duas vezes, mais a fase do mount. Execute a partir do diretório do zurg: o backend NZB lê a pasta `nzbs/` relativa ao diretório de trabalho, e uma conta que não lista nada é reportada como tal, e não como uma conta sem arquivos grandes.

## Releases funcionando no Real-Debrid não são mais marcadas como quebradas depois de uma verificação de link {#working-real-debrid-releases-are-no-longer-marked-broken-after-a-link-check}

Desde a nightly de 2026-08-20, uma biblioteca saudável podia encher o log com `Link verification failed during refresh` e `keeping files as broken`, cada uma trazendo um `404 Not Found` e `invalid_download_code` de um host de download. Nada estava errado com os lançamentos.

Essa nightly adicionou uma limpeza para as linhas que a Real-Debrid cria em My Downloads: cada link que o zurg verifica cria uma. Se ninguém mexer, a lista cresce uma linha por torrent a cada build a frio, até a inicialização estar paginando dezenas de milhares delas. A limpeza apaga essas linhas em segundo plano, partindo do princípio de que a linha e a URL que ela gerou são coisas separadas.

Não são. Apagar a linha revoga o código de download, e a única coisa que mantém ele vivo é um host que já o buscou. Medido em 2026-08-22: um código gerado em `124-4` e buscado uma vez por `44-4` ainda respondeu `200` em `44-4`, enquanto `124-4` e um `125-4` intocado responderam `404 invalid_download_code`. O zurg escolhe o host de download a cada requisição, entre os mais rápidos, então o host que verificou um link raramente é o que o pede depois. A resolução ficou em cache por quatro horas, e toda requisição nessa janela voltou `404`, lida como um link apodrecido, e o lançamento foi marcado como quebrado.

Agora, uma resolução sai do cache de links no momento em que a linha dela é enfileirada para exclusão, então nada reaproveita uma URL que está de saída; a próxima requisição resolve uma nova. As linhas continuam sendo limpas. Lançamentos marcados como quebrados por engano se recuperam no próximo refresh, sem precisar readicionar nem escanear de novo.

## Séries nomeadas por data de exibição são classificadas como séries, não como filmes {#shows-named-by-air-date-are-filed-as-shows-not-movies}

Um programa sem número de temporada e de episódio recebe o nome da data em que foi ao ar, como `WWE SmackDown 2026-08-21`, e isso vale para todo programa diário e de madrugada depois dele. Nada no teste de episódio sabia dessa convenção. Ele procurava `S01E01`, um número de temporada ou de episódio escrito por extenso, o hash de um release de anime e, se nada disso aparecesse, uma sequência de arquivos numerados. Um release diário é um único arquivo com uma única data, então a resposta era não, e o release caía no primeiro diretório que aceitasse, que na maioria das configurações era o de filmes.

Agora a data de exibição conta como o marcador que ela é, escrita como `2026-08-21`, `2026.08.21`, `2026 08 21`, `2026_08_21` ou `20260821`. Só datas válidas entram nessa conta: o mês precisa ser um dos doze, e o dia, um dos trinta e um. Assim, um ano colado em uma resolução, como em `Movie.2026.05.1080p`, nunca é lido como data. Medido em uma biblioteca de 6755 releases, nenhum filme mudou de diretório. Medido em 4734 releases reais de programas diários, 4633 passam a ser reconhecidos. Os restantes são nomes scene mais antigos que abreviam o ano para dois dígitos ou o colocam no final. Esses casos não dá para distinguir com segurança de um layout de canais de áudio, então ficam de fora.

Uma biblioteca que já está em disco se reorganiza sozinha na inicialização, então basta reiniciar. Não precisa escanear nem importar nada de novo.
