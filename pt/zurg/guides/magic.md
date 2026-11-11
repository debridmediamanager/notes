# `__magic__`, um diretório que você pode organizar {#__magic__-a-directory-you-can-organise}

Todos os outros diretórios do zurg são calculados. `movies` aplica o filtro de filmes. `__all__` contém tudo.
Uma pasta de release mostra o que a conta reporta. O layout é reconstruído a cada atualização.

`__magic__` é o único diretório com caminhos **armazenados**. Uma movimentação reescreve uma linha da tabela. Nenhum byte é movido e a conta do debrid continua igual. Você organiza tudo manualmente ou deixa o Sonarr e o Radarr usarem essa pasta.

Ele guarda três tipos de coisa. `__magic__/__all__` contém todas as releases que ainda não foram colocadas em nenhum lugar, e é a pasta de onde os clientes de download importam. Como ela é calculada, não dá para criar nada no nível de cima dela, e os bytes de nenhum arquivo podem ser gravados sobre um nome que uma pasta de release já usa (a pasta de release aceita arquivos auxiliares em nomes que ela não usa). Com uma chave de patrocinador do DMM, o zurg coloca tudo que o DMM identificou em `__movies__` e `__shows__`, ordenado por título ([veja abaixo](#__movies__-and-__shows__-sorted-by-title)). Todo o resto na raiz de `__magic__` é seu:

```
/mnt/zurg/__magic__
├── __all__     <- what nothing has placed yet, where a grab lands
├── __movies__  <- films zurg filed by title
├── __shows__   <- shows zurg filed by title
├── __anime__   <- anime shows, with magic.anime: true
├── anime
├── movies
└── tv          <- your *arr root folders
```

Os caminhos desta página usam o mount do Linux, `/mnt/zurg`. No macOS ele é `/Volumes/Zurg` e no Windows `Z:\`, então `/mnt/zurg/__magic__/tv` vira `/Volumes/Zurg/__magic__/tv` ou `Z:\__magic__\tv`.

É isso que faz a separação funcionar. A pasta de onde o cliente importa e as pastas para onde ele importa são irmãs, então nenhuma contém a outra: uma importação manual apontada para a pasta de download não percorre a árvore da sua biblioteca, e nem o Sonarr nem o Radarr avisam sobre essa organização.

Essa função vem desativada por padrão. Ative com:

```yaml
magic:
  enabled: true
```

e reinicie. As rotas são definidas na inicialização, então alternar a opção pelo painel exige um reinício antes que o namespace responda.

## Para que serve {#what-it-is-for}

Um \*arr importa **movendo** o arquivo da pasta de download para a biblioteca. O zurg não tinha onde receber esse movimento, então o \*arr recorria a copiar. E copiar a partir de um mount de debrid significa baixar a release inteira pela rede, justamente o que o mount existe para evitar.

Com `__magic__`, a importação é uma renomeação dentro de um mesmo namespace: uma linha é gravada, o arquivo aparece onde o \*arr o colocou, e nada é baixado. É isso que torna [o endpoint do SABnzbd](sonarr-radarr.md) útil. Ele é uma camada fina sobre isso, e sem ele toda importação seria um download completo.

Isso só funciona se a **pasta raiz do \*arr também estiver dentro de `__magic__`**, como `/mnt/zurg/__magic__/tv`, e não em um diretório qualquer da máquina. Um movimento cujo destino está fora do namespace é um movimento entre dois sistemas de arquivos, ou seja, uma cópia de novo. O zurg recusa isso logo de cara com um `403`, em vez de deixar acontecer em silêncio. O único lugar dentro do namespace que também é recusado é o topo de `__magic__/__all__`, que é a estrutura da própria biblioteca e não um lugar para colocar arquivos. [sabnzbd.md](sonarr-radarr.md) tem as configurações exatas.

Um arquivo colocado fora de `__all__` continua listado lá, e apagar algo em `__all__` apaga da conta. Por isso o zurg recusa apagar um arquivo por `__all__` ou por qualquer outra pasta da biblioteca enquanto uma colocação aqui estiver fazendo streaming dele. Apague em `__magic__`. Isso impede que um \*arr que importa a partir de `__all__` e depois limpa a pasta de download ali, como acontece com um que usa o proxy SABnzbd do DMM, apague a release que acabou de importar.

E o \*arr precisa acessar a pasta de download e a pasta raiz **por um único mount**. Um contêiner que recebe `__magic__/__all__` e `__magic__/tv` como dois volumes separados enxerga dois sistemas de arquivos, mesmo que ambos sejam do zurg. Assim, o kernel recusa a renomeação dentro do contêiner antes que o zurg fique sabendo, e o \*arr copia o arquivo inteiro. O zurg transforma uma cópia desse tipo em uma colocação assim que ela termina e registra `A client copied …` no log, mas o download já aconteceu. Monte um único diretório com todo o mount do zurg dentro do contêiner; veja [Um volume para a pasta de download e as pastas raiz](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

A aquisição feita pelo próprio zurg também coloca arquivos aqui. Uma fonte do Radarr põe cada release que ela confirma na pasta do filme, com o mesmo movimento de uma importação, e depois pede ao Radarr para fazer uma nova varredura: veja [Colocando o arquivo](acquisition.md#placing-the-file).

O zurg também coloca arquivos aqui por conta própria, em `__movies__` e `__shows__`: veja [abaixo](#__movies__-and-__shows__-sorted-by-title).

Organizar a biblioteca manualmente é a outra metade, e funciona sem nenhum \*arr envolvido.

## Com nada armazenado, os lançamentos de `__all__` como pastas reais {#with-nothing-stored-it-is-__all__s-releases-as-real-folders}

Abra `__magic__/__all__` numa instalação nova e você verá todos os releases que `__all__` contém, cada um como uma pasta. A tabela começa vazia e só guarda **desvios** desse padrão, então uma biblioteca intocada não guarda nada: a raiz de `__magic__` contém apenas o espelho, e novos releases aparecem nele assim que surgem em qualquer outro lugar. Quando algo coloca um release, seja a importação de um \*arr ou a organização feita pelo próprio zurg em `__movies__` e `__shows__`, ele sai de `__magic__/__all__`. O espelho é o que ainda não foi colocado em lugar nenhum.

Não existe configuração de diretório por trás disso: nada de `only_show_the_biggest_file`, nem filtros de tamanho. O que o release tem é o que você vê.

A única diferença em relação a `__all__` é **como é a estrutura interna de uma pasta de release**. Em todo o resto, o zurg achata um release em um único diretório, indexado pelo nome do arquivo, com um sufixo quando dois arquivos colidiriam:

```
__all__/Show.S01/Show.S01E01.mkv
__all__/Show.S01/Gag Reel (Extras).mkv
```

`__magic__/__all__` mostra a árvore que o release realmente tem:

```
__magic__/__all__/Show.S01/Show.S01E01.mkv
__magic__/__all__/Show.S01/Extras/Gag Reel.mkv
```

Isso não é cosmético. O Sonarr e o Radarr escaneiam uma pasta de download como pasta: um arquivo dentro de uma **subpasta** `extras`, `samples`, `featurettes`, `trailers` ou `deleted scenes` é ignorado, e um arquivo no nível superior é considerado. Assim, o `Gag Reel (Extras).mkv` achatado é oferecido para importação, onde a árvore real o deixaria de lado. E a importação deles só usa o título do próprio download como fallback para interpretar o nome quando a pasta tem um único vídeo, então um filme achatado ao lado do seu featurette perde esse fallback. Como [o endpoint do SABnzbd](sonarr-radarr.md) entrega ao \*arr uma pasta dentro de `__magic__/__all__`, esta é a superfície onde essas regras se aplicam.

Dois detalhes da forma:

- **Uma pasta envolvente única é removida.** Quase todo release é uma pasta só com tudo dentro, e essa pasta é o nome que o release já *tem*: os backends de debrid derivam o nome dele a partir dela. Então `/Show.S01/Season 01/ep1.mkv` aparece como `Show.S01/Season 01/ep1.mkv`, e não como `Show.S01/Show.S01/Season 01/ep1.mkv`. Só um nível, e só quando não há nada ao lado dela: um release com um arquivo no topo e uma pasta ao lado mantém os dois.
- **Sem sufixos para nomes duplicados.** Eles existem para manter uma listagem achatada sem ambiguidade, e uma árvore tem diretórios para isso.

Todo o resto de uma pasta de release continua igual, inclusive um arquivo: um conjunto RAR ainda pode ser navegado como diretório, agora ficando onde quer que os volumes dele estejam na árvore, e um release servido a partir de um arquivo achatado ainda lista o conteúdo desse arquivo.

`__all__` e os filtros `directories:` continuam planos. É para eles que um servidor de mídia deve apontar, e nada neles muda.

## Organizando {#organising-it}

Pela montagem, com comandos comuns:

+++ Linux
```bash
mkdir -p /mnt/zurg/__magic__/tv/The\ Show/Season\ 01
mv /mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /mnt/zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ macOS
```bash
mkdir -p /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01
mv /Volumes/Zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ Windows
```powershell
New-Item -ItemType Directory -Force "Z:\__magic__\tv\The Show\Season 01"
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Release.S01E01.1080p\ep1.mkv" `
  -Destination "Z:\__magic__\tv\The Show\Season 01\S01E01.mkv"
```
`-LiteralPath` impede que os colchetes que muitos nomes de release têm sejam lidos como curinga.
+++

O arquivo agora fica no novo caminho e sumiu do antigo. Ele continua sendo transmitido da mesma conta de sempre.

Pastas de release inteiras também podem ser movidas, em uma única linha:

+++ Linux
```bash
mv /mnt/zurg/__magic__/__all__/Some.Movie.2024.2160p /mnt/zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ macOS
```bash
mv /Volumes/Zurg/__magic__/__all__/Some.Movie.2024.2160p /Volumes/Zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ Windows
```powershell
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Movie.2024.2160p" -Destination "Z:\__magic__\movies\Some Movie (2024)"
```
+++

Diretórios são movidos com tudo o que está dentro, em um único lote. As movimentações funcionam nos dois sentidos: um arquivo pode ser movido *para dentro* de uma pasta de release, assim como para fora dela, e a pasta lista o arquivo ao lado dos itens próprios do release. Isso é o que um programa que devolve algo para a pasta de onde está importando precisa ver. Quando um nome aparece de dois lugares ao mesmo tempo, vence o que foi intencional: o que você moveu ganha do que o release chama por aquele nome, que por sua vez ganha de um arquivo real em `data/local`. O perdedor fica de fora, em vez de aparecer duas vezes.

Um caso falha na montagem embutida, e só com o padrão `union_writable: local`: renomear um diretório *que você criou pela montagem*, ou seja, `mkdir` e depois, mais tarde, `mv` desse diretório. Com a ordem padrão, o `mkdir` cria o diretório no upstream local do próprio rclone, enquanto as linhas dentro dele fazem o mesmo diretório existir do lado do servidor. Assim, o rclone renomeia a cópia local, move as linhas uma a uma (o zurg responde corretamente a cada uma delas) e então falha ao remover uma origem que já foi renomeada:

```
ERROR : __magic__/tv/Saul: Dir.Rename error: RenameDir rmdir: object not found
```

As linhas acabam exatamente onde você pediu: o zurg serve o novo caminho e retorna 404 para o antigo. Mas o `mv` termina com código 1, e a montagem continua mostrando o diretório de origem vazio, e não o destino, até que a listagem seja lida de novo. Nenhuma requisição para essa remoção chega ao zurg, então nada que o zurg faça pode impedi-la.

Mover arquivos e mover uma pasta de release inteira funcionam com qualquer uma das duas ordens. Se você reorganizar diretórios pela montagem, defina [`union_writable: server`](../reference/config.md#rclone-settings), em que o diretório existe apenas no namespace e a renomeação é uma única operação do lado do servidor. Medido com rclone 1.71.2.

`rm` oculta coisas: veja [Apagar oculta, não destrói](#deleting-hides-it-does-not-destroy).

## `__movies__` e `__shows__`, ordenados por título {#__movies__-and-__shows__-sorted-by-title}

Kodi e o Plex descobrem o que é cada arquivo pela pasta e pelos nomes dos arquivos, e um nome de release como `Succession.S01.MULTi.1080p.BluRay.REMUX.AVC-DEMS` costuma ser mais do que eles conseguem ler. Apontados para nomes de release, o Kodi reconheceu 8 de 56 séries no nosso teste. Com uma chave de patrocinador do DMM, o zurg organiza todo release que o DMM identificou em duas pastas, com nomes que os players reconhecem logo de cara:

```
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.mkv
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/tvshow.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/Season 01/Detective Conan (1996) - S01E1194 [tmdbid-30983].mkv
```

A mesma biblioteca organizada desse jeito fez o Kodi e o Plex reconhecerem todos os 70 filmes, todas as 44 séries e todos os 554 episódios.

### Ativando {#turning-it-on}

Você precisa de um nightly do zurg de 2026-10-26 ou mais recente, com `__magic__` ativado e sua chave de API do DMM, aquela que o [gatekeeper](https://gatekeeper.debridmediamanager.com/) mostra depois que você patrocina:

```yaml
magic:
  enabled: true
dmm_api_key: YOUR_DMM_API_KEY
```

Reinicie o zurg. As duas pastas são preenchidas depois que a biblioteca carregar e o DMM identificá-la, o que, em uma biblioteca grande, leva alguns minutos na primeira vez. Depois disso, um novo lançamento aparece em até um minuto após o DMM identificá-lo. Em seguida, adicione uma biblioteca **Movies** apontando para `/mnt/zurg/__magic__/__movies__` e uma biblioteca **TV** apontando para `/mnt/zurg/__magic__/__shows__` (`/Volumes/Zurg/__magic__/...` no macOS, `Z:\__magic__\__movies__` e `Z:\__magic__\__shows__` no Windows), e escaneie. No Kodi, defina o scraper da fonte TV como **The Movie Database**, como já vem por padrão, e mantenha-o atualizado: os arquivos `tvshow.nfo` precisam da versão 1.7 ou mais recente do scraper de TV do TMDb do Kodi.

Aponte cada biblioteca para a sua própria pasta, nunca para o próprio `__magic__`: isso faria a varredura pegar também `__all__` e suas outras pastas, e encontrar tudo duas vezes.

### O que faz {#what-it-does}

- **O filme ou a série é o que o DMM diz que é**, nunca uma regra de pasta. Um filme que veio dentro de um pacote de série é arquivado como esse filme.
- **Cada lançamento de uma série vai para uma pasta**, com temporadas e episódios numerados do jeito que o TMDB numera, a ordem que o Plex usa por padrão. Anime numerado pela sequência de exibição vai para a sua temporada: `Detective Conan - 1194` é S01E1194.
- **O id do TMDB fica na pasta, em todos os nomes de arquivo e no `.nfo`**, para que cada player o encontre onde procura: o Plex na pasta, o Kodi no `.nfo` e os players que leem apenas nomes de arquivo, no nome do arquivo.
- **Uma cópia por título.** Quando dois lançamentos são o mesmo episódio ou filme, o melhor é arquivado, pela resolução e depois pelo tamanho; o outro fica em `__all__`.
- **Extras e amostras ficam em `__all__`**, assim como qualquer coisa que o DMM não tenha identificado. Um lançamento só é arquivado depois que o DMM o identifica.

### Anime em uma pasta própria {#anime-in-a-folder-of-its-own}

Séries de anime podem ir para uma terceira pasta, `__anime__`, para que o Kodi e o Plex tenham uma biblioteca de Anime só deles, do mesmo jeito que um segundo Sonarr para anime dava uma. Isso precisa de um nightly do zurg de 2026-11-10 ou mais recente e de mais uma linha:

```yaml
magic:
  enabled: true
  placement: true
  anime: true
dmm_api_key: YOUR_DMM_API_KEY
```

Reinicie o zurg e depois adicione uma biblioteca de **TV** apontando para `/mnt/zurg/__magic__/__anime__` e escaneie ela. O que conta como anime é decisão do DMM, com base no TMDB: uma série que o TMDB lista como animação, em japonês e do Japão, os três juntos, ou uma que o TMDB marca com a palavra-chave *anime*. Detective Conan, Ace of the Diamond e Cyberpunk: Edgerunners vão para `__anime__`; Hazbin Hotel (animação dos EUA), Alice in Borderland (japonesa, live action) e LINK CLICK (animação chinesa) continuam em `__shows__`. Filmes continuam em `__movies__`, inclusive os filmes de anime: uma biblioteca de Filmes é de um tipo só, e essa pasta também.

Ligar isso move todas as séries de anime para fora de `__shows__` em poucos minutos, e quem usa o player vai ver as séries saindo de uma biblioteca e aparecendo em outra:

- **Plex** tira elas da biblioteca de TV (como ausentes, ou removidas de vez se ele esvazia a lixeira depois dos scans) e as pega na biblioteca de Anime no próximo scan. O estado de assistido vem junto: o Plex liga isso à série, não à biblioteca, então um episódio assistido na biblioteca de TV aparece como assistido na biblioteca de Anime (medido em 2026-11-09).
- **Kodi** liga o estado de assistido ao caminho do arquivo, então exporte sua biblioteca de vídeo (Settings → Media → Library → Export) antes de ligar isso e importe depois que a fonte de Anime for escaneada.

Desligar isso move elas de volta do mesmo jeito.

### Com a lista de desejos do DMM {#with-the-dmm-wanted-list}

Clique em **Want** no DMM e o zurg busca o título ([lista de desejados do DMM](dmm-wanted.md)). O que ele busca é organizado aqui como todo o resto, então o filme ou a série aparece no Kodi e no Plex com o próprio nome, sem nenhum Sonarr ou Radarr envolvido. Um torrent que ele pegou pode levar até uma hora para ser organizado; um NZB é organizado assim que o DMM o identifica.

### Com Sonarr e Radarr {#with-sonarr-and-radarr}

Eles mantêm as próprias bibliotecas. Uma release que o Sonarr ou o Radarr pegou pelo zurg fica em `__all__` para eles importarem, a partir do momento em que a pegam, e o zurg nunca organiza nada que eles colocaram. Se um deles importar um título que o zurg já organizou, movendo-o para a própria pasta raiz, ele passa a ser deles a partir daí, e o zurg o deixa lá.

Para fazer o Kodi e o Plex combinarem com as bibliotecas deles da mesma forma:

- Ative **Settings → Metadata → Kodi (XBMC) / Emby** em cada um. Assim eles escrevem um `.nfo` com os ids do título ao lado de cada filme e série, e o zurg o mantém para eles.
- Coloque o id nos nomes das pastas, em **Settings → Media Management**:

  | | Folder format |
  |---|---|
  | Radarr | `{Movie CleanTitle} ({Release Year}) {tmdb-{TmdbId}}` |
  | Sonarr | `{Series TitleYear} {tvdb-{TvdbId}}` |

### Bom saber {#good-to-know}

- **Apagar em um player oculta o arquivo**, como qualquer exclusão em `__magic__`. Ele continua na sua conta de debrid, e o zurg não o cataloga de novo.
- **Nada pode ser movido para `__movies__`, `__shows__` ou `__anime__`**: essas pastas são preenchidas pelo zurg. Tirar algo delas, como faz uma importação do \*arr, funciona.
- **Quando a identificação de um release feita pelo DMM muda**, o zurg move os arquivos dele para o novo nome.
- **Um arquivo que quebra mantém o seu lugar** enquanto o zurg o repara, para que o seu servidor de mídia não o perca.
- **Sem uma chave de patrocinador do DMM, nada é catalogado.** Remover a chave, ou desativar o `__magic__`, deixa o que já foi catalogado onde está.

## Uma movimentação sobrevive a reparo, renomeação e nova listagem {#a-move-survives-repair-rename-and-re-listing}

O zurg conserta um lançamento quebrado adicionando-o de novo à conta. O id do torrent muda, a chave de acesso muda, os ids dos arquivos mudam. Por isso, se a tabela usasse qualquer um desses valores como chave, você perderia todas as posições na primeira vez que um link apodrecesse. Em vez disso, as linhas são identificadas pelo **hash de conteúdo** do lançamento e pelo **caminho do arquivo dentro do lançamento**. Nenhum dos dois muda com um conserto.

As consequências são todas intencionais:

- **Um conserto mantém a sua organização.** O lançamento volta com um id novo e os arquivos continuam onde você os colocou.
- **Renomear um lançamento não move nada.** Um rename, e o sufixo que o zurg adiciona quando dois lançamentos diferentes teriam o mesmo nome de pasta, mudam o nome da pasta padrão do lançamento. As posições não são afetadas.
- **Um arquivo que some não é esquecido.** Se um conserto muda o conjunto de arquivos (o caso mais comum é o Real-Debrid reempacotar um lançamento em rar), uma linha cujo arquivo não existe mais é *mantida, mas não listada*. Se o arquivo voltar, a posição dele volta junto. Linhas nesse estado aparecem no dashboard como **dangling**, e aí você pode removê-las.
- **Apagar um lançamento e adicioná-lo de novo também mantém a sua organização.** O reinsert do DMM, ou um delete seguido de um add novo do mesmo lançamento, traz de volta o mesmo hash. Os arquivos voltam para onde você os colocou, e uma pasta que você apagou, como a pasta de trabalho que um \*arr remove depois de importar, continua oculta. Para ter o lançamento de novo em `__magic__/__all__`, pesquise por ele na página `__magic__` do dashboard e pressione **Unhide** na lápide do lançamento.

Um backend precisa de mais do que uma correspondência exata de caminho. Os nomes de arquivo de um post de Usenet são *resolvidos*, e não fornecidos: são recalculados a cada carregamento e nunca armazenados. Por isso, um post lido pela primeira vez enquanto o servidor de notícias estava inacessível mantém os nomes ofuscados até que um carregamento posterior recupere os nomes reais. Para esses casos, a linha usa como fallback o índice do arquivo dentro do NZB e, depois, o nome base mais o tamanho, desde que exatamente um arquivo corresponda.

## Excluir oculta, não destrói {#deleting-hides-it-does-not-destroy}

`rm` em `__magic__` grava uma **lápide** (tombstone): a entrada some de `__magic__`, mas continua exatamente onde estava em `__all__`, em todas as pastas de filtro e na conta do debrid. Nada é apagado.

Isso não é timidez. É o que torna um \*arr seguro para apontar para ele. Num upgrade de qualidade, um \*arr apaga o arquivo antigo e, na importação, apaga a pasta inteira do job. Se esses apagamentos removessem o conteúdo, um upgrade destruiria a release. E se um apagamento removesse só a *linha*, o arquivo reapareceria no local padrão, bem de volta na pasta de onde o \*arr importa.

Se você quer que um apagamento realmente apague:

```yaml
magic:
  allow_delete: true
```

Assim, apagar um **arquivo** também remove o conteúdo da conta. Uma pasta de release e um diretório nunca são removidos, seja qual for essa configuração. A primeira é o que o Sonarr apaga depois de cada importação.

Uma entrada dentro de um arquivo é o episódio ou filme da maioria das releases de Usenet. Ela não tem arquivo próprio, e o arquivo guarda todo o resto da release também. Então apagar uma entrada só remove a release inteira quando nada em `__magic__` usa nenhuma parte dela. Nenhum arquivo dela pode ainda estar posicionado em algum lugar. A pasta dela precisa ser apagada ou não ter mais nada para importar. É esse o estado em que um upgrade deixa um episódio Usenet substituído. Até isso ser tratado, a release substituída ficava na biblioteca para sempre, e o NZB dela continuava em `nzbs/`.

Um vídeo comum é apagado sozinho. A release dele também sai assim que nada em `__magic__` usa nenhuma parte dela. As mesmas duas regras decidem isso. Releases postam mais do que o vídeo: um `.nfo`, legendas ou um pôster ficam ao lado dele, e ninguém importa esses arquivos. Até isso ser tratado, eles mantinham a release na biblioteca depois que o único vídeo era apagado. O NZB continuava em `nzbs/` e uma release de debrid continuava na conta. Outro episódio do mesmo pack mantém a release enquanto estiver posicionado ou ainda na pasta da release. O mesmo vale para uma pasta de release que foi movida para outro lugar, e para um episódio que parou de ler mas ainda pode ser reparado. Apagar um sidecar onde ele foi postado nunca remove a release. Apagar a última legenda que o Sonarr ou o Radarr importou ao lado do vídeo, sim.

`dav_allow_rename` e o caminho de exclusão sem restrição do próprio mount não têm nada a ver com isso. Eles cobrem as rotas que renomeiam e destroem o que a conta do debrid guarda. Uma escrita em `__magic__` não alcança conta nenhuma. `mount_read_only: true` ainda sobrescreve tudo, no kernel.

Desfazer uma lápide é um clique no painel.

Então um upgrade deixa a release que ele substituiu na sua biblioteca. **Manage > Duplicates** lista essas sobras ao lado da release que o \*arr usa agora, e apaga as que você escolher. Veja [encontrando releases duplicadas](acquisition.md#finding-duplicate-releases).

## Filtros e `__all__` não são afetados {#filters-and-__all__-are-untouched}

Uma release que você moveu continua em `movies`, continua em `recent`, continua em `__all__`, com o nome original. `__magic__` é uma segunda visão da mesma biblioteca, não uma realocação.

Isso surpreende muita gente, então vale deixar claro: **mover algo em `__magic__` altera apenas `__magic__`.** Os diretórios de filtro são calculados a partir da release, e a release não mudou.

Para um servidor de mídia, aponte para **um** dos dois. Uma biblioteca do Plex que escaneia `shows/` e `__magic__/tv` vai encontrar cada episódio duas vezes. O mesmo vale para `__movies__`, `__shows__` e `__anime__`: aponte uma biblioteca para um deles, nunca para o próprio `__magic__`.

## Sidecars: `.nfo`, pôsteres, legendas {#sidecars-nfo-posters-subtitles}

Um \*arr grava metadados ao lado do vídeo, e o Bazarr grava legendas. Esses são arquivos reais, e o zurg não tem onde guardá-los em uma biblioteca de debrid. Por isso, eles vão para o disco local, em `data/local/__magic__/`.

Para configurar o Bazarr e entender como as legendas chegam ao rex, veja [Legendas com o Bazarr](subtitles.md).

Se você usa o mount embutido do zurg, isso já funciona sozinho e você não precisa fazer nada. O mount é uma união de `data/local` com o WebDAV do zurg, e o rclone manda todo arquivo novo criado para a parte local. O zurg nem chega a ver a gravação. Por isso o teste "esta pasta é gravável?" do Sonarr passa.

Se você montar o `/dav` por conta própria (com seu próprio rclone, Infuse ou uma unidade WebDAV do Windows), o zurg aceita o `PUT` e grava na mesma árvore, então as duas visões ficam iguais. Existem dois limites:

```yaml
magic:
  sidecar_max_mb: 32       # per file
  sidecar_budget_mb: 2048  # the whole tree
```

O primeiro gera erro `413` e o segundo gera `507`. Eles limitam o que o *zurg* grava. Com o padrão `union_writable: local`, o próprio upstream local do rclone não pode ser recusado daqui. Mesmo assim, a árvore é medida de novo antes de qualquer recusa, então os arquivos que ele colocou ali contam no orçamento na próxima vez que o zurg for pedido para gravar um. A exceção são os maiores que `sidecar_max_mb`, que ficam de fora. Com `union_writable: server`, a criação em si chega ao zurg. Assim, os limites decidem todas as gravações feitas pelo mount, e qualquer coisa fora de `__magic__` é recusada direto.

Um sidecar também pode ficar dentro de uma pasta de release, que é onde um \*arr grava o `.nfo` de um arquivo que importou ali. O zurg grava e renomeia esse arquivo com qualquer nome que a pasta de release ainda não tenha, e recusa um nome que seria igual ao do arquivo original do release. Um `DELETE` em um sidecar realmente apaga o arquivo. Esse é o único caso em `__magic__` em que apagar não gera um tombstone. Um tombstone esconde uma entrada que a biblioteca ainda tem em outro lugar, mas os bytes de um sidecar ficam só em `data/local`.

## O painel {#the-dashboard}

Depois que a biblioteca carrega, o zurg escreve uma linha no log dizendo quantas linhas a tabela tem e quantas estão órfãs, para que uma biblioteca que perdeu conteúdo não fique acumulando linhas que ninguém mais referencia. A página `/magic/` na porta normal do zurg mostra o que a tabela guarda: cada linha armazenada, agrupada por release, o que ela é e de onde veio, as linhas órfãs em uma seção própria e a árvore de sidecars com o tamanho dela em relação ao limite. Ela também mostra os tamanhos do journal e do snapshot, e o tamanho de todo o `data/local`. Esse número diz se algo está importando por cópia, porque, com o `union_writable: local` padrão, um cliente que copia em vez de mover coloca os bytes ali, e nada mais mostraria isso.

Com `union_writable: server`, esse número fica em zero e o log é que avisa: o `PUT` de um cliente que copia é recusado, então a árvore que ele encheria nunca é escrita. A recusa não salva os bytes, porque o cache do rclone os mantém e tenta de novo, mas eles deixam de estar neste disco sob um nome que o zurg consiga contar. [O guia do qBittorrent](sonarr-radarr-torrents.md) explica a causa, que em todos os casos é uma configuração do lado do cliente: um \*arr só move uma importação quando pode remover o download depois.

A partir daí você pode redefinir um posicionamento (o arquivo volta para o local padrão), limpar uma lápide (a entrada volta), descartar uma linha órfã, remover todas de uma vez, ou apagar um sidecar. Cada ação pede confirmação antes de ser executada.

A lista de linhas armazenadas mostra as primeiras mil linhas, e numa biblioteca organizada por um \*arr isso é só uma pequena parte da tabela, porque cada importação deixa uma lápide para trás. Para chegar a um release específico, pesquise por ele: um nome de release, um caminho no mount ou um hash lista todas as linhas armazenadas sobre aquele release, com seus botões, não importa o tamanho da tabela. A lista de órfãs usa a mesma pesquisa. Um release que a biblioteca não tem mais não tem nome na tabela, só o hash dele e os caminhos para onde as linhas apontam.

Sidecars **que nada mais controla** aparecem separados do resto e são contados: um `.nfo` ao lado de um release que saiu da biblioteca, ou dentro de um posicionamento que foi esquecido. Eles continuam sendo servidos, porque um arquivo real é a última coisa que um caminho resolve, e nada acima deles reivindica o nome. O que se perdeu é o motivo pelo qual eles foram criados. O zurg nunca remove um desses sozinho. Um diretório que você criou para sidecars por conta própria, pelo mount e não pelo zurg, aparece da mesma forma, porque também não deixa nenhuma linha.

Se o endpoint do SABnzbd estiver ativado, a página também lista os jobs dele: id, nome, categoria, estado e a pasta entregue ao \*arr. É a forma mais rápida de descobrir por que o Sonarr ainda mostra isso como "downloading".

## Durabilidade {#durability}

Cada alteração é anexada a `data/magic.journal` e gravada em disco **antes** de a requisição ser respondida, então uma movimentação que um \*arr acredita ter feito é uma movimentação que sobrevive a uma queda. O journal é consolidado em um snapshot `data/magic.json` na inicialização, quando ele passa de um limite, e no desligamento.

Nenhum dos dois arquivos serve para alterar a tabela. O zurg mantém a tabela na memória e grava o `magic.json` a partir dela, então uma linha apagada do arquivo à mão enquanto o zurg está rodando volta depois do próximo reinício. Use os botões do dashboard.

Uma última linha incompleta, por causa de uma queda de energia, é descartada e tudo o que vem antes dela é mantido. Um snapshot gravado por outra versão de schema é descartado em vez de ser adivinhado, e uma linha do journal de outra versão interrompe o replay ali. Um snapshot ou journal que não pode ser lido gera um aviso e uma tabela vazia, não uma falha na inicialização. Já uma tabela cujos arquivos não podem ser *abertos* deixa o `__magic__` servindo em somente leitura, como o espelho do `__all__` com que começa, com todas as gravações recusadas. Gravações que chegam durante o desligamento são recusadas com `503`, em vez de serem confirmadas e perdidas.

## Códigos de status {#status-codes}

Útil se você mexer no namespace via WebDAV diretamente; o mount cuida de tudo isso para você.

| Code | Meaning |
|---|---|
| `201` | MOVE, MKCOL ou PUT criou algo |
| `204` | DELETE, ou um PUT que substituiu um sidecar |
| `400` | um caminho que este namespace não consegue armazenar, ou um header `Destination` ausente ou ilegível |
| `403` | um destino fora de `__magic__` ou dentro de `__movies__`, `__shows__` ou `__anime__`, um caminho para o qual a biblioteca responde, um caminho que passa por um arquivo, o próprio `__magic__`, ou uma tabela somente leitura |
| `404` | não há nada ali (um DELETE de algo inexistente ainda responde `204`), ou um MOVE de dentro de um arquivo morto que não tem mais a entrada |
| `405` | MKCOL onde algo já existe, ou PUT sobre um diretório |
| `409` | pai ausente, diretório não vazio, um destino ocupado com `Overwrite: T`, ou um MOVE de dentro de um arquivo que não abre |
| `412` | destino ocupado com `Overwrite: F` |
| `413` / `507` | acima de `sidecar_max_mb` / `sidecar_budget_mb` |
| `503` | desligando, ou um MOVE cuja origem não pode ser servida agora — com um `Retry-After` |

`MOVE` recusa qualquer destino fora de `__magic__`: os diretórios de filtro continuam somente leitura.

Um `MOVE` **de dentro de um arquivo** também é verificado contra o próprio arquivo antes de qualquer coisa ser gravada. Uma importação é um `MOVE`, e um `MOVE` que dá certo é uma promessa que ninguém verifica depois; a listagem que o cliente percorreu não serve de prova, porque o conteúdo de arquivos já lidos fica em memória (memoizado), então um release cujos bytes sumiram continua listando seus episódios. Por isso, primeiro são consultados a saúde do volume, os danos de artigos do release e, quando eles não disserem nada, o próprio arquivo, exatamente como um `HEAD` no mesmo caminho faria; e um release saudável responde a partir da mesma memória que a listagem já montou. Uma origem que nunca vai ser legível dá `409`, uma que não pode ser lida no momento dá `503` com `Retry-After`, e um nome que o arquivo não contém continua sendo `404`. Nada é registrado em caso de recusa.

## Limites que vale conhecer {#limits-worth-knowing}

- **`magic.enabled` precisa de um reinício.** As rotas são registradas na inicialização.
- **Uma colocação por arquivo.** Mover um arquivo de novo faz com que ele seja colocado novamente; o mesmo arquivo não pode aparecer em dois caminhos.
- **Um arquivo dentro de um conjunto rar pode ser colocado** como qualquer outro — a linha guarda o volume e o caminho dentro dele, então ele sobrevive a um re-empacotamento da mesma forma que um arquivo comum. Porém, nada pode ser criado *por baixo* de um arquivo colocado: um caminho que passe por ele é recusado.
- **`serve_strm_files` é ignorado nas listagens de `__magic__`.** O que o namespace existe para é um \*arr mover o arquivo real para fora dele, e um `.strm` não é um arquivo que qualquer coisa possa importar. Um cliente que pedir um deles pelo nome ainda recebe resposta.
- **Os caminhos são comparados exatamente como chegam.** Não há normalização Unicode nem conversão de maiúsculas/minúsculas, então um cliente que escreve um nome de um jeito e o pede de outro não vai encontrá-lo.

## Veja também {#see-also}

- [sabnzbd.md](sonarr-radarr.md) — apontando o Sonarr e o Radarr para o zurg, que é o que o `__magic__` foi criado para tornar possível
- [DMM wanted list](dmm-wanted.md) — clique em Want no DMM e o zurg busca a lista em `__movies__`, `__shows__` ou `__anime__`
- [usenet.md](usenet.md) — o backend de NZB para onde essas buscas vão parar
- [config.md](../reference/config.md#__magic__-a-directory-you-can-organise) — todas as chaves do bloco `magic:`
