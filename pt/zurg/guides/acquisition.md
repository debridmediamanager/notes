# Fontes de aquisição {#acquisition-sources}

Plex watchlist, sua [lista de desejados do DMM](#dmm-wanted-list), [Seerr](https://github.com/seerr-team/seerr),
[Radarr](https://radarr.video) e [Sonarr](https://sonarr.tv) usam um único motor de aquisição. Ele acompanha o progresso,
as tentativas e as confirmações. Resultados Newznab viram NZBs para o backend Usenet do zurg. Resultados Torznab
viram info hashes para uma conta de debrid. Veja [Newznab e Torznab](#newznab-and-torznab).

O motor só confirma um grab depois de verificá-lo. Um NZB precisa chegar ao servidor de notícias. Em uma conta `torbox_nzb`,
a TorBox precisa baixá-lo no lugar. Um torrent precisa aparecer na biblioteca com arquivos. Veja
[Verificando um grab](#verifying-a-grab).

Uma release que o zurg pega mantém os ids do título para o qual foi pega, todos eles que o
Plex usa para casar títulos: IMDb, TMDB e, para uma série, TVDB. Ela nunca é
identificada de novo pelo nome. Esses ids substituem qualquer id que o DMM ou o nome da release
tenha dado a ela, mas nunca um que você tenha definido manualmente. Uma release que já estava na
sua biblioteca quando o zurg a pegou pode ter sido adicionada para outra coisa, então ela só recebe esses ids
quando não tem nenhum id ou quando já tem exatamente o mesmo. Com
[`rex_url`](../reference/config.md#rex) definido, um filme pego vai para o rex como aquele filme, com
esses ids, mesmo quando o DMM não conseguiu encaixá-lo; os episódios de uma série continuam
numerados pelo encaixe do DMM e carregam os ids da série. Ao iniciar, o zurg
faz o mesmo para cada release que seus jobs salvos pegaram antes, o que corrige
releases que perderam os ids antes desta mudança.

## Configuração {#configuration}

```yaml
acquisition:
  quality: best
  prefer: usenet          # usenet (default), torrents, or best
  best_first: false       # true makes Radarr and Sonarr take the profile's best quality first
  max_size_gb: 0          # a cap on a film or episode, and each episode of a season pack; 0, the default, is none
  max_season_size_gb: 0   # a cap on each season a pack holds; 0, the default, is none
  exclude_words: [DV, HDR10+]  # never take a release whose name says these
  prefer_words: [FraMeSToR]    # take a release whose name says these first, within its resolution
  audio_languages: [original]  # take only releases with this audio (any one), read from the streams
  subtitle_languages: [en]     # and with these subtitles
  concurrency: 8          # titles worked on at once (default 8, at most 200)
  indexer_concurrency: 3  # calls to one indexer at once (default 3, at most 16)
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
      # type: newznab      # default, a Usenet indexer
    - name: my-trackers
      url: https://prowlarr.example
      api_key: YOUR_PROWLARR_API_KEY
      type: torznab        # a torrent indexer, handed to a debrid account
    - name: zilean
      url: http://zilean:8181/torznab
      type: torznab        # no api_key: Zilean takes none, and is asked without one
  sources:
    - name: plex-watchlist
      type: plex_watchlist
      enabled: true
      check_every_secs: 60
      remove_after_grab: true   # default; false keeps the watchlist intact
      only_new_items: true      # default; false works through the existing list
    - name: requests
      type: seerr
      enabled: true
      url: http://seerr:5055
      api_key: YOUR_SEERR_API_KEY
      check_every_secs: 60
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Radarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Sonarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
```

Rode isso em uma instância do zurg com um provedor `nzb` ou uma conta `torbox_nzb` (TorBox Pro), uma conta de debrid que aceita torrents, ou as duas. NZBs de indexadores Newznab caem no diretório `nzbs/`. Uma conta `torbox_nzb` não tem servidores de notícias para checar; um download ali é verificado pelo fato de o TorBox ter buscado o arquivo. Torrents de indexadores Torznab vão para uma conta de debrid. Eles só são adicionados quando essa conta já tem o conteúdo em cache. Sem nenhum dos dois tipos de conta, as fontes não iniciam. A página de aquisição explica o motivo. O Plex precisa do `plex_token` que você já tem. O Seerr precisa da sua URL base e da chave de API, independentemente de quaisquer configurações do Plex no zurg. Subcaminhos de URL e URLs terminando em `/api/v1` são suportados. O Radarr precisa da sua URL base (uma URL base como `/radarr` e um `/api/v3` no final são aceitos), da sua chave de API em **Settings > General** e de `library_path` quando ele enxerga o mount do zurg em outro caminho: veja [Comportamento do Radarr](#radarr-behavior). O Sonarr usa as mesmas três configurações: veja [Comportamento do Sonarr](#sonarr-behavior).

Ambas são lidas quando o zurg inicia, assim como o resto do bloco. `indexer_concurrency` cobre buscas e downloads de NZB juntos, porque um indexador limita a chave e não o endpoint. Chaves de indexador costumam ser compartilhadas, e três chamadas por chave é o que se mostrou seguro em chaves que também atendem outra aplicação.

Mantenha os nomes e as URLs do Seerr estáveis: eles identificam as filas salvas. Trocar a chave do Seerr mantém a fila. Reinicie depois de adicionar fontes ou mudar a URL ou as credenciais delas. As configurações existentes `watchlist:` e `plex_watchlist_enabled` continuam funcionando por meio de um adaptador `plex-watchlist` automático. Uma fonte `plex_watchlist` explícita, mesmo desabilitada, substitui a chave legada de ativação. Apenas uma fonte Plex pode usar a conta Plex configurada. As configurações de busca compartilhadas usam como padrão `watchlist:` e seus valores padrão existentes; indexadores omitidos usam os indexadores de watchlist/Stremio.

## Excluindo releases pelo nome {#excluding-releases-by-name}

```yaml
acquisition:
  exclude_words: [DV, HDR10+]
```

`exclude_words` lista as palavras que nenhuma release baixada pode ter no nome.
Use isso para manter Dolby Vision ou HDR10+ longe de um player que não consegue exibi-los,
mantendo ainda o 4K. Vale para todas as fontes igualmente: a watchlist do Plex, Seerr, Radarr e Sonarr.
Vale para resultados de Usenet e de torrent igualmente. Uma release que ele exclui nunca é
baixada, salva, adicionada a uma conta de debrid nem enviada ao Radarr ou Sonarr. Deixe de fora para
não excluir nada. O zurg lê isso na inicialização, como o resto do `config.yml`.

## Preferindo releases pelo nome {#preferring-releases-by-name}

```yaml
acquisition:
  prefer_words: [FraMeSToR, CiNEPHiLES]
```

`prefer_words` lista palavras, como grupos de release, que colocam um release na frente entre os releases da sua resolução. Ela é comparada da mesma forma que `exclude_words`: palavras inteiras, sem diferenciar maiúsculas de minúsculas. A lista é uma ordem: um release com a primeira palavra vem antes de um com a segunda, e assim por diante. É uma preferência e não um filtro. Quando nenhum release tem alguma dessas palavras, o zurg pega o que pegaria sem elas.

Um release preferido nunca passa na frente de uma resolução. Com `quality: best`, um release 2160p de qualquer grupo ainda vem antes de um 1080p preferido, e com `quality: 1080p` um 2160p preferido não passa na frente dos releases 1080p. Um upgrade para uma resolução maior ainda acontece quando o grupo preferido não tem release nessa resolução.

Isso vale para todas as fontes e para resultados de Usenet e de torrent. Com uma fonte `radarr` ou `sonarr`, o perfil ainda precisa aceitar o release preferido. Quando o Radarr ou o Sonarr usam o zurg como cliente de download, eles escolhem o release sozinhos, e `prefer_words` não se aplica nesse caso. Deixe de fora para não preferir nada.

O release de um filme também nunca é pego quando o nome dele indica um ano com mais de um ano de diferença do ano do filme, seja qual for a fonte. Alguns indexadores colocam certos posts sob o id do IMDb de outro filme: o DrunkenSlug coloca The Aswang Chronicles (2012) sob a sequência de 2014 dele. Um nome sem ano não é recusado por isso. Para a lista de desejados do DMM, que envia todos os títulos pelos quais um filme é conhecido (original, alternativos e traduções), um release cujo nome não traz inteiro um desses títulos também é recusado: o DrunkenSlug coloca Przesluchanie (1982) sob An Affair (1982), e `Rocky.2015` não é *Rocky Horror Show Live*. Um nome pode parar onde começa o subtítulo de um título, depois de dois-pontos ou de um traço com espaços, então `Diana.2021` é *Diana: The Musical*. Acentos e umlauts batem nos dois sentidos, então `Les.Miserables` e `Verwuenscht.nochmal` contam.

Como um nome é comparado:

- **Só palavras inteiras.** Um nome é lido como palavras formadas por letras e dígitos. Pontos, espaços, traços, sublinhados, colchetes e parênteses separam palavras. Maiúsculas e minúsculas não importam. `DV` exclui `Avengers.Infinity.War.2018.DV.2160p.WEB.H265-RVKD` e `Mortal_Kombat_II_2026_COMPLETE_BLURAY_2160p_DV_HDR_TrueHD`. Não exclui `DVDRip`, `DVD9`, `Come and See DvD 1` nem um título como *Adventures*, porque nenhum deles tem a palavra DV.
- **Frases batem em ordem.** `Dolby Vision` ou `DV HDR` batem essas palavras uma ao lado da outra, nessa ordem, seja qual for o separador entre elas.
- **Um `+` no fim faz parte da palavra.** `HDR10+` é uma palavra própria. Excluir `HDR10` deixa os releases HDR10+ em paz, e excluir `HDR10+` deixa o HDR10 simples em paz. Liste as duas para excluir as duas. Um `+` entre duas palavras as separa, como em `DD+7.1` ou `DV+HDR10`.
- **Duas famílias de grafias contam como uma palavra.** Qualquer grafia da lista exclui todas as grafias da sua família.

  | Escreva qualquer um de | Exclui nomes com qualquer um de |
  |---|---|
  | `DV`, `DoVi`, `Dolby Vision`, `DolbyVision` | `DV`, `DoVi`, `Dolby.Vision`, `Dolby-Vision`, `Dolby Vision`, `DolbyVision` |
  | `HDR10+`, `HDR10Plus` | `HDR10+`, `HDR10Plus` |

  Nada mais é equivalente. `HDR` exclui nomes com a palavra HDR e não `HDR10`, `HDR10+` ou `HDRip`. `WEB-DL` bate com `WEB-DL`, `WEB.DL` e `WEB DL`, mas não com `WEBDL`.
- **Só o nome do release é lido.** É o título que o indexador responde, antes de qualquer coisa ser baixada. Os arquivos dentro não são lidos. Um release Dolby Vision cujo nome não diz isso não é excluído.

Excluir uma palavra nunca mexe na resolução. Com `DV` excluído, um release 2160p com HDR simples ou HDR10 ainda é pego, e `quality: 4k` ainda coloca o 2160p primeiro. Um release excluído conta como não encontrado. Uma busca de filme ou episódio continua passando pelas páginas de cada indexador até ter dez releases que pode pegar, o indexador acabar, ou dez páginas terem sido lidas. Uma busca de temporada lê uma página e procura separadamente por qualquer episódio que essa página deixe sem release. Um título cujos releases são todos excluídos falha com "no eligible releases", assim como um cujos releases estão todos acima de `max_size_gb`, e é tentado de novo depois. Um pedido 4K do Seerr pega só releases 2160p, então ele espera quando todos os releases 2160p são excluídos.

### Exclusões e perfis do Radarr ou Sonarr {#exclusions-and-radarr-or-sonarr-profiles}

Com uma fonte `radarr` ou `sonarr`, a exclusão vem primeiro. Um release excluído nunca é passado para o parser do Radarr ou do Sonarr. Nenhuma pontuação de custom format o traz de volta, e ele não conta como recusa pelo perfil. Todos os outros releases são avaliados pelo perfil, como descrito em [Comportamento do Radarr](#radarr-behavior) e [Comportamento do Sonarr](#sonarr-behavior). Um release precisa passar pelos dois. Um custom format que dá pontuação abaixo do mínimo do perfil para Dolby Vision faz o mesmo papel dentro do *arr, e mantê-lo não faz mal.

Os upgrades seguem a mesma regra. Se os únicos releases que levariam um arquivo até o cutoff do perfil forem excluídos, o arquivo continua abaixo do cutoff e a passada de upgrade do zurg continua procurando sem pegar nada. Isso acontece quando um custom format dá uma pontuação alta para Dolby Vision e a pontuação do cutoff depende dela. Diminua a pontuação do cutoff ou tire essa pontuação do custom format.

Quando o Radarr ou o Sonarr usam o zurg como cliente de download pelo bloco `sabnzbd:` ou `qbittorrent:`, eles pesquisam nos próprios indexadores e escolhem o release por conta própria. `exclude_words` não se aplica nesse caso. Exclua as mesmas palavras no *arr, com um custom format com pontuação abaixo do mínimo do perfil, ou em **Must Not Contain** de um release profile.

## Escolhendo por idioma de áudio e legendas {#choosing-by-audio-and-subtitle-language}

```yaml
acquisition:
  audio_languages: [original]   # or [de], [de, en], ...
  subtitle_languages: [en]
```

`audio_languages` aceita apenas lançamentos com uma faixa de áudio em um dos idiomas listados, e `subtitle_languages` apenas lançamentos com uma faixa de legenda em um deles. Deixe qualquer um de fora para não pedir nada. Ambos valem para todas as fontes.

Cada lista também é uma ordem: um torrent com um idioma anterior vem antes de um que tenha só um idioma posterior. `[de, original]` pega uma dublagem em alemão quando existe uma, e o idioma original quando não existe.

O zurg lê o idioma a partir dos streams do lançamento, não do nome. A maioria dos lançamentos não informa os idiomas no nome: quase nenhum dos de Parasite diz KOREAN. Escreva códigos ISO 639, de duas ou três letras: `en`, `eng`, `de`, `deu` e `ger` funcionam todos. Um nome como `german` é recusado na inicialização.

Alguns idiomas têm dublagens ou legendas diferentes, e um código pode indicar uma delas:

| Escreva | Para |
|---|---|
| `es-419`, `es-ES` | Espanhol latino-americano (Latino) ou castelhano |
| `pt-BR`, `pt-PT` | Português brasileiro ou europeu |
| `fr-CA`, `fr-FR` | Québécois (VFQ) ou francês da França (VFF, VFI) |
| `nl-BE` | Flamengo |
| `yue`, `cmn` | Cantonês ou mandarim |
| `zh-Hant`, `zh-Hans` | Legendas em chinês tradicional ou simplificado (`zh-TW` e `zh-HK` são lidos como tradicional, `zh-CN` como simplificado; para áudio em cantonês escreva `yue`) |
| `nb`, `nn` | Norueguês Bokmål ou Nynorsk |

O código simples pega todos eles: `es` pega o Latino e o castelhano, `zh` o cantonês e o mandarim, `no` o Bokmål e o Nynorsk. Uma parte depois do idioma que o zurg não consegue ler, como `es-latam`, é recusada na inicialização. O zurg descobre de qual deles é uma faixa pelo título dela, porque os streams nunca trazem isso de um jeito que o zurg consiga ler: "Latino", "Spanish (Latin American)", "Castellano", "French (Canada)", "VFQ", "Portuguese (Brazilian)", "Chinese (Cantonese)", "繁体中字". Uma faixa cujo título não diz nada disso nunca é recusada por causa disso. O nome do lançamento resolve o empate quando diz algo, como `Dual-Lat`, `[Castellano]`, `MULTi.VFQ`, `VF2`, `PT-BR` ou `[ES-LA]`. Um nome nunca recusa nada, e o título de uma faixa tem prioridade sobre ele. Para `[es-419, es]`, o zurg pega, nessa ordem: uma faixa com título Latino, uma sem título em um lançamento chamado Latino, uma sem título, uma sem título em um lançamento chamado Castellano, e uma faixa com título Castellano. Para uma casa latino-americana:

```yaml
acquisition:
  audio_languages: [es-419, es]  # Latino first, then Castilian
  subtitle_languages: [es]
  audio_or_subtitles: true       # or any audio with Spanish subtitles
```

`audio_or_subtitles: true` aceita um lançamento que tenha o áudio ou as legendas, em vez de ambos. Um lançamento com o áudio vem antes de um que tenha só as legendas.

`original` significa o idioma em que o título foi feito, conforme o TMDB registra: coreano para Parasite, francês para Anatomy of a Fall. O zurg pede isso ao DMM, então precisa de `dmm_api_key`. Sem a chave, `original` não pede nada.

### Como um release é avaliado {#how-a-release-is-judged}

- **Antes de um torrent ser adicionado.** O DMM guarda os dados do ffprobe de cada release que um zurg analisou. Com `dmm_api_key` definida, o zurg lê esses dados para todo resultado de torrent em uma única chamada. Um torrent cujos streams não têm o idioma nunca é adicionado. Um que tem fica à frente dos torrents sobre os quais nada se sabe. Em uma medição de cinco filmes em 2026-10-25, o DMM tinha esses dados para cerca de um terço dos torrents que o Real-Debrid tinha em cache.
- **Depois do download.** Todo download, torrent ou Usenet, é analisado uma vez assim que entra na biblioteca: com os dados do DMM, quando ele os tem, ou com o ffprobe. Um download cujos streams não têm o idioma é posto de lado como um post morto. Ele é removido da conta do debrid ou do diretório de monitoramento, e o próximo candidato é testado na hora. O painel mostra o motivo, por exemplo "it has no English audio, only French".
- **Uma atualização mantém os seus idiomas.** Quando a lista de desejados do DMM troca um filme por uma resolução melhor, a nova release precisa ter idiomas pelo menos tão cedo nas suas listas quanto a cópia que ela substitui. Uma cópia 1080p em espanhol latino não é trocada por uma 2160p em espanhol de Castela.
- **Desconhecido é aceito.** Uma release nunca é recusada pelo que não pode ser lido. Isso inclui faixas sem tag, uma faixa marcada como `und` ou `mul`, uma release só alcançada pelos seus arquivos compactados, ou nenhuma análise em um minuto. O zurg registra que a aceitou como está.

Comentários e faixas de audiodescrição não contam como áudio do filme, e legendas de comentários não contam como legendas dele. Isso inclui um comentário nomeado apenas no título, como "Commentary by Bong Joon Ho" em Parasite. Faixas de legenda com título forced (forzados, forcés), signs ou songs não contam como legendas. A flag forced sozinha não exclui uma faixa: remuxes de filmes estrangeiros marcam as legendas completas em inglês como forced para que os players as mostrem.

Só os arquivos de vídeo principais de uma release são avaliados, os que têm pelo menos um quinto da duração do mais longo. Extras costumam ter menos dublagens que o filme. Em um pacote de temporada, todo episódio precisa ter o idioma.

Uma release posta de lado por causa do idioma continua de lado por 30 dias, como um post morto, mesmo que você mude os idiomas.

## Lista de desejos do DMM {#dmm-wanted-list}

Um apoiador do DMM adiciona filmes e séries a uma lista de desejados com o botão **Want** nas páginas dele em debridmediamanager.com, e eles aparecem em `/wanted`. O zurg lê essa lista sempre que `dmm_api_key` estiver definida: não há mais nada para escrever. Nada é montado e nenhum Sonarr ou Radarr está envolvido. A origem se chama `dmm-wanted` e é consultada a cada 60 segundos.

- **O que é buscado.** Um filme uma vez, depois qualquer upgrade dele (abaixo), ou uma cópia em cada uma de várias resoluções quando `quality` for uma lista (abaixo). Os episódios já exibidos de uma série, nas temporadas desejadas, ou em todas as temporadas quando a série inteira for desejada, e os novos episódios conforme forem ao ar.
  O DMM envia os IDs do IMDb, TMDB e TVDB de cada título, o ano e, no caso de uma série, os episódios já exibidos, numerados como o TMDB os numera. Especiais nunca são listados. Uma temporada que ainda está em exibição é buscada como episódios avulsos, já que nenhum pacote a cobre ainda.
- **Quando é pesquisado.** Um filme é pesquisado assim que sai para o público doméstico: o DMM envia o dia do seu primeiro lançamento digital, físico ou de TV em que o TMDB tiver essa informação, e o zurg espera no máximo até esse dia e, depois, pesquisa a cada dois minutos por seis horas e a cada dez até dois dias depois, como faz com um [novo episódio](#sonarr-behavior). Nunca a data de estreia no cinema: um WEB-DL é publicado junto com o lançamento digital. O episódio mais novo de uma série recebe a mesma data, a partir da hora em que foi ao ar, quando o DMM sabe essa hora. Um título sem data mantém as tentativas comuns, com no máximo uma semana entre elas, e nada na lista é nunca [pausado](#persistence-and-recovery). Um filme que está aguardando a próxima tentativa é pesquisado na próxima consulta quando o DMM vê uma nova postagem na Usenet que o cita.
- **Para onde vai.** O mesmo que qualquer outra origem: um NZB de um indexador Newznab para o backend Usenet desta instância, ou um torrent de um indexador Torznab para uma conta de debrid que já tenha esse torrent em cache, o que for que a `prefer` pegar primeiro. `quality`, `max_size_gb` (por episódio, no caso de pacote de temporada), `exclude_words` e os [idiomas](#choosing-by-audio-and-subtitle-language) se aplicam, e também `max_season_size_gb`, quando você escrever essa opção.
- **Indexadores.** Sem nenhum indexador escrito em `acquisition:`, `watchlist:` ou `stremio:`, a chave também pesquisa os do próprio DMM: o indexador Usenet dele e os torrents que ele sabe que a Real-Debrid ou a AllDebrid têm (`/api/torznab/cached`). Escrever qualquer indexador substitui os dois.
- **Confirmação.** Quando a obtenção de um filme é verificada, o zurg avisa o DMM, e o filme sai da lista que o zurg lê, a menos que ele esteja aguardando um upgrade ou outra de suas cópias (abaixo); o `/wanted` mostra quando isso aconteceu. Uma série continua na lista e continua sendo acompanhada até você removê-la por lá. Remover um título interrompe o trabalho sobre ele.
- **Upgrades.** Um filme cujo nome de lançamento indica uma resolução abaixo da que `quality` busca (2160p para `best` e `4k`, 1080p para `1080p`, 720p para `720p`) permanece na lista. O zurg busca um lançamento que indique uma resolução maior do que a cópia que ele tem, quando um desses sai, até ter essa versão. Depois que a cópia melhor passa na verificação, a antiga é removida se o zurg a tiver obtido, a partir do nightly de 2026-10-30: um torrent da conta à qual o zurg o adicionou, ou um NZB do diretório de monitoramento. Uma cópia que já era sua é mantida, e também uma que tenha alguma parte colocada em `__magic__`, como por uma importação do Radarr. Um lançamento cujo nome não indica resolução nunca é atualizado, e `quality: smallest` não atualiza nada. Até sair um lançamento melhor, o filme é pesquisado cerca de uma vez por semana, e ele nunca é [pausado](#persistence-and-recovery). Ativado por padrão; `upgrades: false` no bloco `acquisition:` desliga isso.
- **Uma cópia em cada uma de várias resoluções.** Com `quality` escrito como lista, como `[1080p, 4k]`, cada filme mantém uma cópia em cada resolução dela. Veja [uma cópia em cada uma de várias resoluções](#a-copy-at-each-of-several-resolutions).
- **Sem conta para obtenção.** Uma instância sem provedor `nzb`, sem conta `torbox_nzb` (TorBox Pro) e sem conta de debrid que aceite torrents não lê a lista.

**Dois zurgs com a mesma chave buscam todos os títulos.** Cada um lê a mesma lista, então rode a lista de desejados em apenas um deles e desligue nos outros escrevendo-a como desabilitada:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

Uma assinatura vencida ou uma chave redefinida interrompe a lista. O zurg registra um aviso de que o DMM recusou `dmm_api_key` e tenta de novo uma hora depois, ou imediatamente quando você definir uma nova chave. O que ele já buscou continua na sua biblioteca.

### Uma cópia em cada uma de várias resoluções {#a-copy-at-each-of-several-resolutions}

Escreva `quality` como uma lista para manter uma cópia de cada filme na lista de desejados em cada resolução dela, por exemplo para que uma TV 1080p reproduza um sem que o arquivo 4K precise ser transcodificado:

```yaml
acquisition:
  quality: [1080p, 4k]
```

Cada cópia pega o melhor release na sua resolução ou abaixo dela, e nunca um acima dela. A cópia 1080p não pega nenhum release 2160p, nem nenhum cujo nome não informe resolução, já que pode ser qualquer coisa. A cópia 4K pega um desses só quando não há nenhum release com resolução informada que possa ser pego, e aí o mantém para sempre, já que um release sem resolução informada nunca é atualizado. Cada cópia é atualizada por conta própria, até a sua própria resolução. Quando as duas pegariam o mesmo release, elas dividem uma só cópia, e essa cópia só é removida quando nenhuma delas mais a mantém:

| Releases disponíveis | Cópia 1080p | Cópia 4K | Na sua biblioteca |
|---|---|---|---|
| 720p | o 720p | o mesmo 720p | o 720p |
| + 1080p | sobe para o 1080p | sobe para o 1080p | o 1080p |
| + 2160p | fica | sobe para o 2160p | o 1080p e o 2160p |

Um filme que sai só em 2160p ganha a sua cópia 4K na hora, e a sua cópia 1080p quando aparece um release em 1080p ou abaixo. Até lá, ele é buscado cerca de uma vez por semana e nunca fica parado. O filme só sai da lista que o zurg lê quando cada cópia tem um release que não quer melhor do que ele.

- **O que a lista aceita.** Duas ou mais de `4k` (ou `2160p`), `1080p` e `720p`, cada uma uma vez, em qualquer ordem e em qualquer caixa (maiúsculas ou minúsculas). O zurg se recusa a iniciar com qualquer outra coisa e diz `acquisition.quality lists resolutions, each once: 4k, 1080p or 720p`. Uma lista com um só item é lida como esse valor, então `[1080p]` é `quality: 1080p` e mantém uma cópia; escreva `4k` ali, já que `[2160p]` é recusada.
- **Só no bloco `acquisition:`.** `quality` em `watchlist:` é um valor só; uma lista ali impede o zurg de iniciar. A configuração de qualidade na página de configuração edita apenas `watchlist.quality` e não muda nada enquanto `acquisition.quality` estiver escrito.
- **Só filmes da lista de desejados do DMM.** Séries nela, e todas as outras fontes, ainda recebem uma cópia, escolhida como se `quality` citasse apenas a maior resolução da lista: `[1080p, 4k]` funciona como `quality: 4k` para elas, e `[720p, 1080p]` como `quality: 1080p`, que ainda pega um release 2160p quando nenhum 1080p está disponível.
- **Com `upgrades: false`** cada cópia mantém o primeiro release que pega. Enquanto só um 720p estiver disponível, as duas cópias são esse 720p para sempre.
- **Filmes baixados antes de você escrever a lista** são buscados de novo, uma cópia em cada resolução. Uma cópia cujo melhor release já está na sua biblioteca usa esse release como está. O zurg nunca remove a cópia baixada antes: apague-a você mesmo se as novas cópias a substituírem.
- **Voltar a um único valor** deixa as cópias onde estão.
- **O `/wanted` mostra o filme como baixado** assim que a primeira cópia estiver pronta, com o primeiro release que o zurg pegou. Ele não mostra qual resolução ainda está esperando. Um filme baixado antes de você escrever a lista pode continuar mostrando "waiting for" com a resolução pela qual esperava naquela época.

### Assistindo um filme do YouTube {#streaming-a-film-from-youtube}

Many wanted films no indexer carries are on YouTube, uploaded whole by the studio that
made them. With `acquisition.youtube` set, zurg streams such a film from that upload
instead of leaving it unfetched. Nothing is downloaded.

```yaml
acquisition:
  youtube:
    cookies: /home/you/zurg/youtube-cookies.txt   # required: a signed-in account's cookies (Netscape format)
    # ytdlp_binary: yt-dlp                        # default; the standalone build
    # js_runtime: node                            # default; yt-dlp needs one to read YouTube's player
    # channels: [UC1D36wr10qyCfisHulZ5G8Q]       # the channel ids uploads are taken from
    # searches_per_hour: 20                       # default; films looked for on YouTube in an hour
```

- **When.** Only for a film on the DMM wanted list, and only when nothing the indexers
  return can be taken: no release passes `quality`, `max_size_gb`, `exclude_words` and
  the title and year checks, or every one was found gone, with every indexer answering.
  Never for a show or an upgrade, nor with `audio_languages` or `subtitle_languages`
  set, since an upload's languages cannot be read. Only the wanted list takes a stream:
  a film the Plex watchlist also wants is not settled for it by one, since Plex cannot
  play it, and the watchlist keeps looking for a release.
- **How often.** At most `searches_per_hour` films are looked for in an hour (20 by
  default: 1,820 films take four days), one at a time. A film YouTube has nothing for is
  asked about again a day later, restarts included.
- **Which upload.** zurg searches YouTube for the title and year, and for the original
  title when DMM sends one, and takes an upload only when all of these hold: it is on
  one of `channels`; it runs at least 90% of the film's runtime, or an hour when DMM does
  not know the runtime; its title begins with the film's title (`'Separada' FULL MOVIE |
  ...`), states no other year, and is no trailer, teaser, clip or `Part N`. Of those it
  takes the longest, then the most watched, and checks that YouTube streams it with
  picture and sound together.
- **Channels.** The default list is the Philippine studios' own channels: ABS-CBN Star
  Cinema, Regal Entertainment, VIVA Films, SOLAR WATCH NOW, OctoArts Films, CineMo and
  Cinema One. Of 100 random unfetched films on one wanted list (2026-10-31), 65 had a
  full-length upload and 33 were on these channels; the rest were re-uploads (every
  Disney one) and, for new releases, scams titled "full movie". Writing `channels`
  replaces the list. A channel's id is the `UC...` part of its address, or what
  `yt-dlp --print channel_id <a video's page>` prints.
- **What you get.** The film is named `Title.Year.1080p.YouTube.WEB-DL` and DMM is told
  it was fetched (`youtube:<video id>`). rex gets it as an HLS item in your movies
  library, read through zurg. Jellyfin and Kodi get
  `__magic__/__movies__/Title (Year) {tmdb-N}/Title (Year) {tmdb-N}.strm`, with `__magic__`
  on. The address in the `.strm` is zurg's own, from [`base_url`](../reference/config.md), and needs
  no login. Either address is the stream's playlist served by zurg, every segment in it
  an address on zurg too, which zurg fetches from YouTube itself. zurg resolves the
  stream with yt-dlp and keeps it until an hour before it expires. A segment's address
  is good for a day; a player that comes back later reads the playlist again.
- **Upgrades.** A streamed film stays on the wanted list while `upgrades` is on, and any
  release of it that comes out replaces the stream, whatever its resolution: the stream,
  its `.strm` and its rex item go once the release has passed its check.

Limits:

- **Plex cannot play it.** It is no file on the mount. Use rex, Jellyfin or Kodi.
- **Cookies are required.** Without a signed-in account's cookies YouTube offers an
  address that fetches much only video and audio apart, or nothing, so zurg starts with
  the fallback off and says why. Export them from a browser signed in to YouTube, ideally
  on the same network. Signing out in that browser ends them.
- **Every byte passes through zurg.** Nothing is redirected to YouTube: rex sends its
  source's login with every request its transcoder makes, redirected ones included, and
  YouTube ties a stream to the address that resolved it. So any player that reaches
  zurg plays it, and zurg carries the film's traffic.

## Comportamento do Seerr {#seerr-behavior}

The adaptador segue as [rotas de requisição](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/routes/request.ts),
as [definições de status](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/constants/media.ts)
e o [contrato da API](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/seerr-api.yml) do seerr-team/seerr.

- Consulta todas as páginas de requisições aprovadas usando `X-Api-Key`. Se uma página falhar, a fila anterior é mantida e o trabalho dessa fonte é pausado.
- Verifica a aprovação de novo antes de baixar. Requisições pendentes, recusadas, com falha, concluídas, removidas ou que já estão disponíveis não iniciam downloads.
- Resolve os IDs pelo Seerr. A aquisição de séries fica restrita às temporadas aprovadas e aos episódios já exibidos que se conhecem. Uma temporada parcial continua pendente.
- Trata 4K e não-4K separadamente. Uma release 1080p não atende a uma requisição 4K.
- Verifica as requisições abertas a cada 30 minutos após uma aquisição bem-sucedida, para encontrar episódios novos nas temporadas pedidas. Episódios sem data anunciada só viram trabalho quando aparecem nos metadados do Seerr.
- Prefere packs depois que todos os episódios conhecidos já foram exibidos. Temporadas em exibição usam episódios avulsos. Especiais (temporada 0) não são suportados. Uma requisição com a temporada 0 aprovada não é adquirida de jeito nenhum e falha até ser pausada.
- Não faz gravações de status de requisição nem de disponibilidade. A varredura do servidor de mídia feita pelo Seerr informa a disponibilidade real e avisa quem pediu. Salvar um NZB não prova que ele está indexado ou reproduzível, por isso o engine faz essa checagem antes de considerar a temporada adquirida.

Configure a varredura da biblioteca do Seerr para incluir a biblioteca servida por esta instância. Se o Sonarr/Radarr já adquirem as mesmas requisições, desative esse fluxo sobreposto antes de ativar este adaptador. O adaptador não emula um servidor *arr nem altera a configuração de serviços do Seerr. A consulta periódica garante a recuperação após reinicialização; nenhum webhook é necessário.

## Comportamento do Radarr {#radarr-behavior}

Radarr mantém a lista e é dono da biblioteca. O zurg faz a busca e o download. O Radarr nunca busca e nunca baixa nada: o zurg lê o que o Radarr quer, escolhe um release nos seus próprios indexadores, verifica com os servidores de notícias (o fetch da TorBox numa conta `torbox_nzb`) ou com a conta debrid que tem o arquivo, coloca o vídeo na pasta do filme dentro de `__magic__` e pede para o Radarr fazer um rescan só daquele filme. Nada é copiado: o vídeo é um arquivo na biblioteca do zurg que o Radarr agora enxerga na pasta dele.

### Configurando o Radarr {#setting-up-radarr}

1. **Pasta raiz dentro de `__magic__`, um nível abaixo.** Por exemplo
   `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` no macOS,
   `Z:\__magic__\movies` no Windows). Não `__magic__` em si, e não
   `__magic__/__all__`, que lista todos os lançamentos da biblioteca. Um filme
   cuja pasta esteja em qualquer outro lugar é ignorado, com um aviso no log do
   zurg. No Windows, o Radarr só enxerga `Z:` quando roda na mesma sessão de
   login do zurg, ou seja, não como serviço do Windows: veja
   [as regras de sessão](../setup/windows.md#keeping-it-running-the-session-rules).
2. **Listas de importação com busca ao adicionar desligada.** Adicione filmes
   do jeito que preferir (manualmente, por listas, Seerr apontando para o Radarr).
   Deixe **Search for Movie** desmarcado ao adicionar, já que quem faz a busca é o zurg.
3. **Não são necessários indexadores nem cliente de download.** Se o Radarr tiver
   esses itens, ele pode baixar junto com o zurg, então desligue a busca automática
   nos indexadores (ou remova-os) para os filmes que o zurg cuida.
4. **`library_path` é onde o Radarr enxerga `__magic__`.** Quando o Radarr roda na
   mesma máquina do zurg e enxerga o mount no mesmo caminho em que o zurg o monta,
   deixe essa opção de fora: ela assume por padrão o `mount_path` do zurg mais
   `/__magic__`. Quando o Radarr roda em um container que monta o zurg em outro
   caminho, defina-a para esse caminho, por exemplo `/data/zurg/__magic__`. Um filme
   em `/data/zurg/__magic__/movies/Heat (1995)` é então colocado em
   `movies/Heat (1995)` dentro do `__magic__` do zurg. Caminhos do Windows como
   `Z:\__magic__` também funcionam. Um container do Radarr só é coberto em host Linux:
   o Docker Desktop no macOS e no Windows roda containers em uma VM, e passar o mount
   do zurg para dentro dela não foi testado, então rode o Radarr nativamente nesses casos.

   Se o Radarr também pegar downloads pelos endpoints do zurg de
   [SABnzbd](sonarr-radarr.md) ou [qBittorrent](sonarr-radarr-torrents.md), ele precisa
   enxergar a pasta de download em `library_path/__all__`, pelo mesmo volume das suas
   pastas raiz, senão cada importação dela será uma cópia do arquivo inteiro. O zurg
   pergunta ao Radarr onde ele enxerga os dois e informa isso na página de aquisição,
   no log e no `zurg doctor` quando não puderem compartilhar um mount; veja
   [Um volume para a pasta de download e as pastas raiz](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

### O que o zurg pede ao Radarr {#what-zurg-asks-radarr-for}

Toda enquete lê a lista de filmes do Radarr e age em cada filme que está monitorado, **disponível** pela disponibilidade mínima do filme, e que ou não tem arquivo ou tem um arquivo abaixo do cutoff do perfil de qualidade, desde que o perfil permita upgrades. Abaixo do cutoff significa abaixo do cutoff de qualidade ou abaixo do cutoff de pontuação de formato personalizado, conforme o Radarr calcula. Um filme que ainda não foi lançado, como um filme com data de estreia de meses à frente, espera até o Radarr dizer que ele está disponível.

Cada release candidato que o zurg está prestes a inspecionar é enviado para o próprio parser do Radarr (`/api/v3/parse`) e avaliado pelo perfil de qualidade do filme, então o que o zurg aceita é o que o Radarr também aceitaria:

- **Precisa ser este filme.** O Radarr tem que associar o título ao mesmo filme. Uma busca por ID em um indexador retorna outros filmes (uma busca por *Psycho* retornou *Ed Gein: The Real Psycho*), e um título que o Radarr não associa a nenhum filme é recusado. Um ano no título com mais de um ano de diferença em relação ao do filme também é recusado.
- **A lista de permissão e a pontuação mínima do perfil valem primeiro.** A qualidade interpretada precisa ser permitida pelo perfil, a pontuação do formato personalizado precisa atingir o mínimo do perfil, e o tamanho precisa caber nos limites da qualidade em **Settings > Quality** para a duração do filme.
- **O release precisa estar no idioma do perfil.** Com **Original**, que é o padrão, o Radarr precisa ler o título como o idioma original do filme, então um release só em francês de um filme em inglês é recusado. Um título que não informa idioma conta como original. Um idioma informado exige esse idioma, e **Any** aceita qualquer um. Isso vale tanto para o primeiro arquivo quanto para um upgrade.
- **Upgrades avançam em direção ao cutoff depois.** Um filme sem arquivo aceita qualquer release que passe pelas verificações acima. Depois que ele tem um arquivo abaixo do cutoff, só um release melhor é aceito: uma qualidade maior na ordem do perfil enquanto o arquivo estiver abaixo do cutoff de qualidade, ou uma pontuação de formato personalizado maior (por pelo menos o upgrade step do perfil) enquanto estiver abaixo do cutoff de pontuação. Uma qualidade menor nunca é aceita. Releases PROPER e REPACK da mesma qualidade não são tratados como upgrades.

O perfil é aplicado ao release que o zurg está prestes a pegar como uma lista de permissão: o filme certo, uma qualidade permitida, a pontuação mínima, o idioma e os limites de tamanho. Por padrão, a ordem de preferência do perfil não é usada para escolher entre os releases que ele permite. O zurg pega o primeiro release permitido que for mais barato de verificar, testando primeiro os releases de web (WEB-DL, WEBRip), depois os de Blu-ray e depois os demais, porque os releases de web são os mais comumente publicados como um único arquivo de vídeo. Se o perfil preferir algo melhor do que o que chega e permitir upgrades, o Radarr vê o arquivo do filme abaixo do cutoff, e a passagem de upgrade do zurg procura o release melhor assim que o filme tiver um arquivo. O primeiro arquivo chega rapidamente, e a ordem do perfil é atendida pelo upgrade. Defina `best_first: true` para que a primeira captura siga a ordem do perfil.
Veja [Pegando o melhor do perfil primeiro](#taking-the-profiles-best-first).

Quando uma busca pelo ID do IMDb ou do TMDB não retorna nada, o zurg busca de novo por título e ano, como o Radarr faz. Muitas postagens, principalmente documentários pequenos, são indexadas sem nenhum ID. O parser do Radarr decide se cada resultado é o filme, então um filme de mesmo nome é recusado como qualquer outra correspondência errada.

O Radarr só é consultado sobre um release quando o zurg está prestes a inspecioná-lo, um release por vez, então um filme com um release de arquivo único custa de uma a três perguntas. Nada mais é perguntado depois que um post direto é salvo. Um título que informa uma resolução para a qual o perfil não tem nenhuma qualidade permitida, como um release 2160p para um perfil HD-1080p, é recusado sem perguntar nada ao Radarr. Um título que não informa resolução, ou que informa mais de uma, sempre vai para o Radarr, e o mesmo vale para todo título quando o perfil permite uma qualidade cujo nome não indica resolução (SDTV, DVD, Unknown, Raw-HD, BR-DISK). O zurg faz no máximo oito chamadas simultâneas para um mesmo Radarr.

Se o Radarr não puder ser alcançado, nada é decidido: o filme espera a próxima enquete, e nenhum release é descartado porque o Radarr não respondeu.

### Colocando o arquivo no lugar {#placing-the-file}

Depois que um release é verificado, o zurg coloca o vídeo dele na pasta do filme do mesmo jeito que o Radarr teria importado, movendo o arquivo para dentro de `__magic__`. Nada é copiado nem baixado.

- **O maior vídeo é o que é colocado.** É o maior arquivo `.mkv`, `.mp4`,
  `.m4v`, `.avi`, `.mov` ou `.ts` do release, contando o que está dentro dos
  arquivos compactados. Um release servido a partir de um único arquivo
  compactado é o conteúdo desse arquivo. Um conjunto RAR com arquivos soltos ao
  lado, como um post scene com a amostra e o `.nfo`, é navegado como uma pasta
  do release, e o vídeo que está dentro dele é colocado a partir daí. Amostras,
  extras, legendas e arquivos `.nfo` ficam em `__magic__/__all__`. O arquivo
  mantém o nome que tem no release, a menos que esse nome não diga nada sobre o
  filme (sem o ano e sem nenhuma palavra do título). Nesse caso ele recebe o
  nome do release, para que o Radarr consiga ler a qualidade dele.
- **Uma amostra nunca é colocada.** Um vídeo com nome de amostra (`sample-…`,
  `….sample.mkv`, uma pasta `Sample/`) fica de fora, por maior que seja, a menos
  que o próprio nome do release também diga sample. Um filme que só tem a
  palavra no título (`Sample.Size.2019`, `Death.Proof.2007`) traz a palavra no
  nome do release também; nesse caso o vídeo só fica de fora quando tiver menos
  de um quinto do release. Um release cujo único vídeo é a amostra, inclusive
  um post que é só a amostra, é descartado, e o próximo candidato é testado.
  Assim, um upgrade nunca substitui seu arquivo por um clipe de um minuto.
- **Ele é recusado antes de ser movido se não puder ser lido.** Essa é a mesma
  verificação que uma importação do Sonarr ou do Radarr pelo mount recebe. Um
  release cujos artigos os servidores de news não têm mais, ou cujo arquivo
  compactado nunca vai abrir, é descartado como um post morto, e o próximo
  candidato é testado. Um release que não pode ser lido agora, como um em uma
  conta que está em resfriamento, é tentado de novo mais tarde.
- **O Radarr mantém um arquivo por filme, então um upgrade substitui o arquivo
  antigo.** Quando o vídeo novo está na pasta, todos os outros vídeos que a
  biblioteca do zurg colocou ali ficam ocultos da pasta. Ocultar significa marcar
  como removido (tombstone), do mesmo jeito que uma exclusão pelo mount: o
  release antigo continua em `__all__` e na sua conta. Um arquivo real que você
  mesmo colocou na pasta fica intocado. O arquivo antigo só sai depois que o
  novo é colocado, então, se a colocação falhar, o filme continua com o arquivo
  que já tinha.
- **O Radarr faz uma nova varredura depois.** O zurg informa ao mount quais
  pastas mudaram, para que a varredura não leia uma pasta que o mount ainda
  lembra como vazia. Depois, ele pede ao Radarr que faça uma nova varredura só
  daquele filme.

Uma fonte do Radarr precisa de `__magic__` (`magic.enabled`). Sem ele, a fonte não inicia, e isso aparece no log e na página de aquisição.

### O que o Radarr mostra {#what-radarr-shows}

**Activity** fica vazio: sem entradas na fila e sem eventos de grab ou import, porque o Radarr não pegou nada. O filme simplesmente ganha um arquivo depois do rescan que o zurg pede, e a qualidade e os custom formats dele são a leitura que o Radarr faz desse arquivo. O log do zurg registra cada filme que ele completa.

`only_new_items` e `remove_after_grab` não fazem nada para uma fonte do Radarr. Os filmes que o Radarr deixa como wanted são trabalho, assim como os pedidos aprovados do Seerr, e é o Radarr que decide quando um filme deixa de ser wanted. Mantenha o `name` da fonte estável: ele identifica a fila salva, enquanto a URL e a key podem mudar à vontade.

## Comportamento do Sonarr {#sonarr-behavior}

Sonarr funciona do mesmo jeito que o Radarr. O Sonarr guarda a lista e é dono da biblioteca.
O zurg faz a busca e o download. O Sonarr nunca busca e nunca pega nada. O zurg lê os episódios que o Sonarr está faltando e escolhe uma release dos seus próprios indexadores. Ele verifica a release com os servidores de notícias (o fetch da TorBox numa conta `torbox_nzb`) ou com a conta debrid que tem o arquivo, e coloca o vídeo de cada episódio na pasta da temporada da série dentro de `__magic__`. Depois pede para o Sonarr fazer um rescan só daquela série. Nada é copiado.

### Configurando o Sonarr {#setting-up-sonarr}

1. **Pasta raiz dentro de `__magic__`, um nível abaixo.** Por exemplo
   `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` no macOS,
   `Z:\__magic__\tv` no Windows). Uma série cuja pasta esteja em qualquer outro lugar é
   ignorada, com um aviso no log do zurg.
   No Windows, o Sonarr precisa rodar na mesma sessão de logon do zurg, assim como o Radarr.
2. **Search on add desligado.** Adicione as séries do jeito que preferir. Deixe a opção **Start search
   for missing episodes** desligada, já que quem faz a busca é o zurg.
3. **Não são necessários indexadores nem cliente de download.** Se o Sonarr tiver esses itens, ele
   pode pegar downloads junto com o zurg, então desligue a busca automática nos indexadores das
   séries que o zurg cuida.
4. **`library_path` é onde o Sonarr enxerga o `__magic__`.** Funciona exatamente
   como no Radarr, inclusive com a verificação de que o Sonarr acessa a pasta de download do zurg
   e as pastas raiz pelo mesmo volume. Pode deixar de fora quando o Sonarr
   enxergar o mount no mesmo lugar onde o zurg monta.

### O que o zurg pede ao Sonarr {#what-zurg-asks-sonarr-for}

- **Uma temporada inteira que já terminou de ir ao ar pode vir como pacote.** Quando todos os episódios de uma temporada estão faltando e nenhum ainda vai ao ar, um pacote de temporada é tentado primeiro. Caso contrário, os episódios que faltam da temporada são pegos um a um dos resultados de busca da temporada. Uma temporada que já tem alguns de seus arquivos nunca pega um pacote. Isso colocaria uma segunda cópia desses episódios na pasta.
- **Um episódio novo é um trabalho novo.** Quando o episódio da semana que vem for ao ar, a temporada aparece de novo com esse episódio. O zurg não busca de novo os episódios que já tem.
- **Um episódio novo é buscado de novo em poucos minutos.** O lançamento costuma sair na primeira hora depois que o episódio vai ao ar, então uma busca logo na hora da estreia muitas vezes não encontra nada. Por seis horas depois que um episódio vai ao ar, o zurg tenta de novo a cada dois minutos, e depois disso a cada dez, até dois dias depois da estreia. Depois disso ele recua como faz com qualquer outra coisa (veja [persistência e recuperação](#persistence-and-recovery)). Em uma conta de debrid, o lançamento também precisa já estar em cache lá, porque o zurg adiciona só o que a conta tem.
- **Um episódio apagado volta a ser procurado.** Quando o Sonarr lista um episódio que o zurg já tinha baixado, o zurg procura na pasta da temporada. Se não há mais nenhum vídeo desse episódio ali, ele é buscado de novo. Se ainda há um, o Sonarr ainda não fez a varredura e nada é buscado.
- **Upgrades são por arquivo.** Um arquivo de episódio abaixo do cutoff do perfil de qualidade é um upgrade, desde que o perfil permita upgrades. "Abaixo do cutoff" significa abaixo da qualidade de corte ou abaixo da pontuação de corte de formato personalizado. A lista Cutoff Unmet do próprio Sonarr só considera a qualidade. No Sonarr 4.0.20, um arquivo na qualidade de corte que pontua 0 de uma pontuação de corte de 40 não aparece nela. O zurg considera os dois casos, como a regra de upgrade do próprio Sonarr. Um arquivo com dois episódios conta como um upgrade para os dois.
- **Os episódios de um programa diário são encontrados pelo dia em que foram ao ar.** Seus lançamentos são nomeados pelo dia (`The.Daily.Show.2026.11.03.Min.Jin.Lee...`), e os indexadores não os encontram pelo número do episódio. Por isso, cada episódio que falta também é pedido como uma busca de texto com o título da série e o dia, `The Daily Show 2026.11.03`. O parser do Sonarr converte o dia de volta no episódio (S31E124), como faz com um título numerado por temporada.
- **Os episódios de um anime são encontrados pelo número que o programa usa para contá-los.** Os lançamentos fansub são numerados a partir do primeiro episódio da série (`[SubsPlease] Jujutsu Kaisen - 30` é o sexto da segunda temporada). Por isso, cada episódio que falta também é pedido como uma busca de texto com o título da série e esse número, `JUJUTSU KAISEN 30`. Um lote que cobre os números da temporada (`(25-47)`) é o pacote da temporada. O parser do Sonarr associa o número ao episódio, usando os nomes de cena da temporada (`Jujutsu Kaisen 2nd Season`, `Jujutsu Kaisen S2`). Assim, um título numerado de qualquer um dos dois jeitos é julgado como o episódio que ele é. Um lançamento que o Sonarr não associa a nenhuma série, como um nomeado por um nome de cena que ele não conhece, é recusado como qualquer outro.
- **Especiais são a temporada 0.** Os especiais monitorados no Sonarr aparecem como qualquer temporada, pedidos como temporada `00` (um indexador pedido pela temporada `0` responde com outra temporada). Só um lançamento com `S00Exx` no nome pode dar match: um especial nomeado apenas pelo título não gera nada no parser, nem no Sonarr. Eles são colocados na pasta que o **Specials Folder Format** do Sonarr define.

Cada lançamento candidato é submetido ao próprio parser do Sonarr (`/api/v3/parse`) e julgado pelo perfil de qualidade da série. O que o zurg aceita é o que o Sonarr também aceitaria.

- **Tem que ser esta série e esta temporada.** O Sonarr precisa associar o título à mesma série. Um título que o Sonarr não associa a nada é recusado, a menos que a série não use numeração de cena e a busca de séries do próprio Sonarr encontre esta série primeiro pelo nome no título (um título em outro idioma, por exemplo).
- **Um pacote tem que ser a temporada inteira.** Um pacote parcial é recusado. Um pacote escrito como intervalo, como `Season 1 E01-E07`, conta quando o intervalo é a temporada inteira. Um pacote de várias temporadas conta para cada temporada que ele nomeia (veja [Pacotes de várias temporadas](#packs-of-several-seasons)). O Sonarr lê `S01-S05` como só a temporada 1 e nunca diz onde termina, então o zurg lê o intervalo do título. O Sonarr ainda precisa associá-lo à série e classificá-lo como um pacote completo de várias temporadas. O tamanho é julgado pela duração de todas as temporadas que ele nomeia.
- **Um episódio tem que ser só aquele episódio.** Um lançamento com dois episódios é recusado para um episódio único.
- **O perfil se aplica como se aplica ao Radarr.** A qualidade precisa estar permitida. A pontuação do formato personalizado precisa atingir o mínimo do perfil. O tamanho precisa caber nos limites da qualidade em **Settings > Quality** para a duração dos episódios que o lançamento contém. Um upgrade precisa superar o arquivo atual pelas regras do Sonarr. Os perfis do Sonarr não têm configuração de idioma, então um idioma só conta pela pontuação de um formato personalizado, como acontece no Sonarr.

A ordem entre os lançamentos permitidos é decidida de forma diferente do Radarr. Um pacote de temporada é tentado antes dos episódios avulsos porque é um único download onde os outros seriam vários. Entre os lançamentos que o Sonarr permite, o zurg pega o que a configuração `quality` coloca em primeiro. Com `best`, isso é a maior resolução e depois o maior tamanho, e um pacote é comparado pelo que traz por episódio. Assim, uma temporada terminada com um pacote 1080p é preenchida a partir desse pacote, mesmo quando a mesma busca tem todos os episódios em 2160p. O passe de upgrade então substitui episódio por episódio. Um pacote com mais de `max_size_gb` por episódio, ou mais que um `max_season_size_gb` que você definiu para a temporada, nunca é candidato. `best_first: true` muda os dois. Veja [Pegar o melhor do perfil primeiro](#taking-the-profiles-best-first).

Um título que cita uma resolução para a qual o perfil não tem qualidade permitida é recusado sem consultar o Sonarr. O zurg faz no máximo oito chamadas ao mesmo Sonarr ao mesmo tempo. Se o Sonarr não puder ser alcançado, nada é decidido. A temporada espera a próxima consulta e nenhum lançamento é descartado.

### Colocando os arquivos no lugar {#placing-the-files}

Depois que um release foi verificado, o vídeo de cada episódio vai para a pasta da temporada. É a pasta onde ficam os arquivos já existentes da temporada. Para uma temporada que ainda não tem arquivos, é a pasta que o **Season Folder Format** do Sonarr define, como `Season 1`. Uma série configurada para não usar pastas de temporada tem seus arquivos na pasta da série.

- **Cada episódio ganha seu próprio vídeo.** O vídeo é encontrado pelo número do episódio no nome, inclusive dentro dos arquivos compactados do release. Um pacote coloca todos os episódios para os quais foi feito. Amostras e arquivos `.nfo` ficam em `__magic__/__all__`, e uma amostra nunca é colocada como o episódio.
- **Um pacote que não tem algum episódio é recusado antes de qualquer coisa ser movida.** Ele é posto de lado como um post morto, e o próximo pacote ou os episódios avulsos são tentados.
- **Um episódio avulso cujo nome de arquivo não indica nada recebe o maior vídeo do release.** Posts ofuscados costumam ser assim.
- **O vídeo de um anime ou de um programa diário é colocado dentro da série e do episódio.** Um rescan lê um arquivo só pelo nome e não sabe nada da numeração scene: `[Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv` na pasta da série foi importado como S01E08, enquanto o parser do Sonarr lê o mesmo título como S02E08. Por isso o vídeo é colocado como `JUJUTSU KAISEN - S02E08 - [Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv`, que importa certo, com o nome original mantido depois do episódio para o Sonarr continuar lendo qualidade e grupo. Os vídeos de uma série normal e de um especial mantêm seus nomes, que já dizem o episódio.
- **Um upgrade substitui só o seu próprio episódio.** O vídeo antigo desse episódio fica oculto na pasta da temporada assim que o novo estiver no lugar. Os outros episódios da pasta não são mexidos. Oculto significa tombstoned, como acontece no Radarr.
- **O Sonarr faz um rescan depois.** O zurg avisa o mount quais pastas mudaram e pede ao Sonarr que faça um rescan da série.
- **Um episódio faltando não segura os outros.** Quando um episódio não tem nenhum release que o zurg possa pegar ainda, os episódios que ele encontrou são mesmo assim verificados e colocados. O Sonarr é pedido para fazer um rescan deles imediatamente. O episódio que falta é procurado de novo no cronograma normal de tentativas.

Um source do Sonarr precisa de `__magic__` (`magic.enabled`). Sem ele, o source não inicia, e isso é informado no log e na página de aquisição.

**Activity** no Sonarr fica vazio, como no Radarr. Os episódios simplesmente ganham arquivos depois do rescan que o zurg pede. `only_new_items` e `remove_after_grab` não fazem nada para um source do Sonarr.

## Pacotes com várias temporadas {#packs-of-several-seasons}

A season can be taken from a pack that holds several, such as
`Game.of.Thrones.S01-08.BDRip.1080p` or `Breaking Bad Season 1-5`. Indexers
file such a pack under every season it covers. On DMM's feed, 72 of the 691
results for Breaking Bad season 3 were packs of several seasons. For some
seasons one of them is the only copy an account holds.

- **O título diz quais temporadas.** `S01-S05`, `S01-05`, `[S01-08]`, `S1-9`,
  `Seasons 1-8`, `Season 1 to 5`, `Season 1 · 2 · 3`, `Stagioni 01-05` e
  `Temporadas 1-4` são todos lidos. Um título sem números de temporada, como
  `Complete Series`, não é aceito. Também não é aceito um que cite uma única
  temporada só como palavra, como `Season 3 Complete`. Esses nunca foram lidos
  como packs.
- **Só essa temporada é colocada.** Um pack pego para a temporada 4 coloca os
  episódios da temporada 4 na pasta da temporada. Os arquivos das outras
  temporadas ficam onde a biblioteca os lista. Um pack cujos arquivos não
  tenham todos os episódios da temporada é recusado antes de qualquer coisa
  ser movida, não importa o que o título diz.
- **O tamanho é avaliado por episódio.** O tamanho do pack é dividido pelas
  temporadas que ele cita e depois pelos episódios da temporada, e comparado
  com `max_size_gb`, como seria o mesmo encode postado episódio por episódio.
  Um pack de 346 GB com oito temporadas de dez episódios dá 4.3 GB por
  episódio. O remux da temporada 2 de I Love Lucy, com 31 episódios, tem
  106 GiB, 3.4 GiB por episódio, e cabe num limite escrito de 40. Quando a
  fonte não listou os episódios da temporada, os packs não têm limite por
  episódio. Um `max_season_size_gb` que você escrever limita cada temporada
  citada no pack, além disso; por padrão não há nenhum.
- **A qualidade continua vindo primeiro.** Os packs são ranqueados como
  qualquer outro lançamento: primeiro a resolução, depois o que eles têm por
  episódio, do jeito que a página de temporada do DMM os ranqueia. Um pack
  2160p de uma temporada é pego antes de um pack 1080p de oito. Dentro da
  mesma resolução, o remux próprio de uma temporada vem antes de um pack de
  oito temporadas que é maior no total, mas menor por episódio.
- **As outras temporadas da série usam o mesmo pack.** Depois que uma
  temporada pega um pack de várias temporadas, as outras temporadas da série
  tentam esse pack primeiro, antes de qualquer pack da mesma resolução que a
  busca própria delas encontrou. Ele já está na conta, então não custa nada.
  Enquanto as temporadas de uma série estão escolhendo entre packs de várias
  temporadas, elas escolhem uma de cada vez, para que temporadas pedidas juntas
  (uma série do Sonarr, com todas as temporadas numa mesma consulta) não
  escolham cada uma uma cópia diferente da série. Quando uma delas escolher sem
  um pack desses, porque nenhum estava na conta ou o perfil não permitia
  nenhum, as demais escolhem de uma vez. Uma temporada pedida uma hora depois
  faz uma busca nova.

## Vendo funcionar {#watching-it-work}

O link **Acquisition** do painel abre `/acquisition/` na porta do próprio zurg.
Cada fonte tem uma linha com quantos dos seus títulos estão prontos, em execução,
aguardando, deixados de lado e na fila, ao lado do número de títulos que o zurg
trabalha ao mesmo tempo, das chamadas que ele faz a um indexador ao mesmo tempo e das
conexões com os servidores de notícias que as suas contas `nzb` podem usar. Abaixo disso,
cada fonte tem uma tabela com uma linha por título. Uma linha mostra o estado, o que um
título em execução está fazendo agora (a busca, quantos resultados já foram avaliados e
aceitos até o momento, o candidato que está sendo inspecionado, a verificação nos
servidores de notícias, a colocação), as suas tentativas, a versão escolhida com a qualidade e a
pontuação dadas pela fonte, onde ela foi colocada e quando um título em espera
será tentado de novo. Um título que não tem mais nenhuma versão para tentar diz o motivo,
com as recusas da fonte contadas por regra: `14 refused by the source's own rules
(title mismatch 7, quality 5, size 2)`. As versões recusadas pela resolução, sem perguntar
à fonte, entram na contagem de qualidade.
A página se atualiza sozinha a cada cinco segundos.
O mesmo retrato fica em `/acquisition/status.json`, onde esse motivo aparece no `detail` do título.
Quando nenhuma fonte está habilitada, ou a aquisição está configurada mas pausada, a página informa isso e o motivo.

Cada filme para o qual uma versão é escolhida gera uma linha no log, para medir onde o tempo é gasto:

```
Acquisition: chose <release> for <title>: results=143 local_refusals=97 radarr_refusals=1 inspected=2 radarr_calls=3 in 4.2s
```

`results` é o que a busca retornou, `local_refusals` as versões recusadas sem perguntar à fonte, `radarr_refusals` as recusadas pelas regras da própria fonte, `inspected` os NZBs lidos, `radarr_calls` as perguntas feitas à fonte (os NZBs lidos mais as recusas no caminho até eles, quando a fonte é o Radarr), e o tempo conta a partir do início da busca.
As versões recusadas sem perguntar são registradas uma a uma, apenas no nível debug.

## Verificando um \*arr que usa só o zurg como cliente de download {#checking-an-arr-that-only-uses-zurg-as-its-download-client}

A Sonarr or Radarr pointed at zurg's [SABnzbd](sonarr-radarr.md) or
[qBittorrent](sonarr-radarr-torrents.md) endpoint does its own searching, and does not
need a source here. zurg still wants its API key, because three of its settings
decide whether every import is a free rename or a whole release downloaded
from the debrid account and written to zurg's disk: Remove Completed on a
qBittorrent client, the download folder and the root folders on one volume,
and root folders inside `__magic__`. With the key, zurg turns Remove Completed
on by itself (see [qbittorrent.md](sonarr-radarr-torrents.md#what-to-put-in-each-field))
and warns about the other two. See
[One volume for the download folder and the root folders](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

The easiest way to give zurg the key is the banner on the main dashboard,
described below. Or add it as a source that is switched off:

```yaml
acquisition:
  sources:
    - name: sonarr
      type: sonarr
      enabled: false
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
```

A Radarr or Sonarr source with `enabled: false` acquires nothing. zurg never
reads its wanted list and never searches for it. With its `url` and `api_key`
set, and one of the two endpoints on, zurg only reads the \*arr's root folders,
remote path mappings and download clients, at start, every ten minutes and as
soon as the \*arr first calls one of the endpoints. It turns Remove Completed
on for the \*arr's zurg qBittorrent client when it is off, the one change zurg
makes, and reports a layout that makes imports copies. Every source with a URL
and an API key, enabled or not, is checked and corrected the same way. It is
listed on the acquisition page under **Checked, never searched for**, with
what zurg changed, the findings go to the log, and `zurg doctor` shows them as
`imports (<name>)`. `library_path` is not judged for such a source, since
nothing is placed for it. A source added to config.yml by hand is read at
start, so restart zurg after adding one that way.

zurg also notices a Sonarr or Radarr it cannot check. Both send their name in
every request to the endpoints (`Sonarr/4.0.20.3014 (alpine 3.24.1)`), so zurg
records which ones call it and from which address. When one calls and no
source of its kind has a URL and an API key, zurg logs one warning, `zurg
doctor` reports it on its `*arr settings` line, and the main dashboard shows a
banner with a form for its URL and API key. The URL is filled in with a guess:
the address the \*arr calls from, on its default port (8989 for Sonarr, 7878
for Radarr). That address is often a container's own, which zurg may or may
not reach, so change it to whatever URL reaches the \*arr from where zurg
runs. The API key is in the \*arr under Settings, General, Security. zurg
first asks the \*arr for its status with that key, and saves nothing unless it
answers as the app it was named as. It then adds the source above to
config.yml with `enabled: false`, keeping everything else in the file as it
was, and checks it straight away, with no restart. The form shows what zurg
found and changed. The key is written to config.yml and sent to the \*arr, and
nowhere else.

The banner matches by kind, not by address: an \*arr calls zurg from inside
its container, on an address that has nothing to do with the URL zurg reaches
it on, so one Sonarr source with a key silences the banner for every Sonarr.

## Encontrando releases duplicados {#finding-duplicate-releases}

Um upgrade deixa na sua biblioteca o release que ele substituiu. Com `magic.allow_delete` desligado, a exclusão do arquivo antigo pelo Radarr ou pelo Sonarr só o esconde em `__magic__`, então o release antigo continua em `__all__` e na sua conta. Capturas de mais de um indexador, ou um pacote de temporada junto com episódios avulsos, também deixam vários releases da mesma coisa. **Manage > Duplicates** (`/manage/duplicates/`) lista eles, mostra qual deles o Radarr ou o Sonarr está usando e deixa você apagar os outros. Ela nunca apaga nada sozinha.

**Qual release está em uso é lido pelos caminhos, não pelos nomes.** Todo arquivo que o Radarr e o Sonarr mantêm é identificado por um caminho dentro de `__magic__`, e o zurg sabe de qual release cada caminho vem, porque a movimentação que colocou o arquivo ali registrou isso. A tela lê todos os arquivos que cada \*arr importou, monitorado ou não, esteja no cutoff ou não, e rastreia cada um até o seu release. Um arquivo do Sonarr é rastreado episódio por episódio, então um pacote de temporada do qual o Sonarr usa três episódios aparece como em uso só para esses três.

**Quais releases podem ser cópias é um palpite, e a tela avisa isso.** Os releases são agrupados com um filme, ou com uma temporada, quando:

- um arquivo do \*arr está neles,
- o histórico do \*arr diz que ele importou deles, ou apagou um arquivo que veio deles (um upgrade, manualmente ou por estar ausente do disco),
- o zurg os identificou como o id do IMDb do filme ou da série, ou
- o nome deles tem o título e o ano (um ano de diferença, ou o segundo ano do filme no Radarr, ainda conta) ou a série e a temporada.

Cada release mostra quais desses critérios o colocaram no grupo. Uma temporada só forma grupo quando os releases têm o mesmo episódio: sessenta releases de um episódio cada, da mesma temporada, são sessenta episódios diferentes. Um grupo de temporada lista os episódios que mais de um release tem, qual release tem cada um, em qual deles está o arquivo do Sonarr e quantos episódios cada release tem que nenhum outro do grupo tem. Nenhum release é escolhido como vencedor. Os releases que não batem com nenhum item do Radarr ou do Sonarr ficam em **Name matches only**, agrupados pelos nomes e ids do IMDb.

**Cada release está em In use, No reference found ou Unknown.**

| State | Meaning |
|---|---|
| In use | Um arquivo que o Radarr ou o Sonarr mantêm agora está neste release. Ele não pode ser selecionado. |
| No reference found | Todos os Radarr e Sonarr configurados foram lidos por completo, e nenhum dos arquivos deles está neste release. Plex, Jellyfin e outros clientes que leem o mount não aparecem aqui, então isso não prova que ninguém reproduz esse release. |
| Unknown | O zurg não consegue determinar. Todos os releases ficam Unknown enquanto um \*arr não puder ser lido, enquanto a biblioteca ainda está carregando, ou com `__magic__` desligado. Um release também fica Unknown quando um arquivo do \*arr para o mesmo filme ou episódio não pode ser rastreado até nenhum release, ou quando o histórico do \*arr mostra que um arquivo deste release sumiu do disco e o filme ou episódio não teve arquivo desde então. |

**A qualidade é mostrada nos termos do perfil.** Para um release que o \*arr está usando, é a nota que o próprio \*arr deu ao arquivo. Para um que ele importou antes, é a nota que ele deu na época. Nos outros casos, é lida do nome do release, e a tela avisa isso. Cada uma é posicionada no perfil de qualidade do item, por exemplo "rank 15 of 17 in 4K or best available (cutoff at 17)".

**A exclusão relê tudo antes.** Selecione os releases e escolha **Check again and delete**. O zurg lê de novo os arquivos atuais de todos os \*arr, e só depois oferece a exclusão. Um release que entrou em uso depois que a página carregou fica de fora, e um release Unknown só é apagado se você marcá-lo de novo naquele diálogo. A exclusão em si é a exclusão em massa da página de gerenciamento, que remove todas as cópias do release de todas as contas que o têm.

**Quando ela lê.** Ao abrir a página pela primeira vez, ela lê todos os Radarr e Sonarr em `acquisition.sources`, incluindo o histórico de importação e exclusão. Ler o histórico de uma biblioteca grande pode levar um minuto. Depois disso, a página mostra o que foi lido por último e quando, até você escolher **Read Radarr and Sonarr again**. Uma fonte com `enabled: false` continua sendo lida: desligar a aquisição não muda o que o \*arr mantém. A página mostra os números de cada fonte: arquivos lidos, rastreados até um release, em um caminho fora do seu `library_path`, e dentro de `__magic__` mas sem levar a nada. Se nenhum arquivo de uma fonte for rastreado até um release, verifique o `library_path` dela.

O mesmo relatório está em `/manage/duplicates/report.json`, e `POST /manage/duplicates/check` com `{"hashes": [...]}` relê os \*arr e responde o estado de cada release.

## Newznab e Torznab {#newznab-and-torznab}

Uma entrada de indexador diz qual é o tipo dela com `type`. Se o campo estiver ausente, vale `newznab`, que é o que todas as entradas escritas antes disso significavam. A consulta é a mesma para os dois tipos; a resposta não. Um resultado Newznab é um NZB, que é baixado e gravado em `nzbs/` para o backend Usenet. Um resultado Torznab é um info hash, entregue a uma conta de debrid. Um resultado Torznab sem atributo magnet ou `infohash` é ignorado: o zurg nunca baixa um `.torrent`, então um resultado que só pode ser acessado assim não é algo que ele consiga usar.

**Um torrent só é adicionado a uma conta que já o tenha.** Toda conta que aceita adições recebe o hash, com uma exceção: uma conta Real-Debrid é pulada para um nome de release que ela recusa de vez, porque os caches são independentes e uma conta ter removido um release não diz nada sobre a próxima. A primeira que já tiver o conteúdo fica com ele. Uma falha em todas é um candidato comum que não deu certo, então a varredura desce no ranking para o próximo release, que pode ser outro torrent ou um NZB.

Na TorBox e na Debrid-Link, uma falha não adiciona nada. Na AllDebrid e na Offcloud, ela é apagada na hora. Real-Debrid e Premiumize recebem o torrent adicionado e ficam observando por até 20 segundos. Conteúdo em cache fica pronto em um ou dois segundos. Qualquer coisa que ainda esteja baixando depois disso é removida de novo. Assim, nenhum download fica rodando na conta. Uma falha não é totalmente sem custo, porém. Ela ainda pode contar no limite de adições da conta. Na TorBox, ela usa uma das 60 adições não cacheadas permitidas por hora.

A conta marcada com `watchlist: true` recebe o torrent primeiro. As demais seguem a ordem da sua lista `providers:`. Uma conta marcada com `add_torrents: false` nunca recebe um.

`prefer` decide qual tipo é consultado primeiro quando os dois podem atender a um alvo na mesma resolução. A resolução vem antes: um torrent 2160p que uma conta já tenha é pego antes de um NZB 1080p, independentemente do que `prefer` disser. `usenet` é o padrão, porque uma captura Usenet custa um download, enquanto um torrent consome uma das vagas de adição da conta. `torrents` inverte isso, e `best` deixa de lado a distinção e pega o que o ranking puser em primeiro, ou seja, o release maior dentro de uma resolução.

Um filme tenta até três torrents por tentativa. Cada um custa uma adição. Até 24 dos NZBs dele são inspecionados individualmente, como descreve [escolhendo o release de um filme](#choosing-a-movies-release). Com `usenet`, os NZBs de uma resolução são tentados antes dos torrents dela. Com `torrents`, os torrents vêm primeiro. Com `best`, cada torrent espera a sua vez no ranking. Os NZBs de uma resolução são tentados juntos no lugar do melhor deles. Com uma fonte Radarr, os NZBs de todas as resoluções são tentados juntos no lugar do melhor, do mais barato para o mais caro, como descreve aquela seção. Um pacote de temporada tenta três releases por tentativa, de qualquer um dos tipos. Cada episódio avulso também.

A verificação que uma captura aguarda muda conforme a fonte. Um release Usenet é verificado nos servidores de notícias, que é a única forma de saber se a postagem ainda está lá. Uma conta `torbox_nzb` não tem servidores de notícias para checar; uma captura ali é verificada pelo fato de a TorBox ter baixado o NZB. Um torrent só foi adicionado porque a conta disse que já tinha o conteúdo, então o que resta confirmar é que o release chegou à biblioteca com arquivos dentro; é isso que a checagem pergunta, e um release que a conta lista vazio é descartado como uma postagem morta.

Uma instalação sem conta NZB (`nzb` ou `torbox_nzb`) ainda pode rodar a aquisição só com indexadores Torznab. Os indexadores Newznab dela não são pesquisados ali, porque nada nessa instalação consegue reproduzir um NZB. O log avisa isso uma vez para cada um deles. Uma instalação sem nenhuma conta que aceite torrents não pesquisa os indexadores Torznab dela, do mesmo jeito. Em qualquer dos casos, um release de um tipo para o qual a instalação não tem onde colocar nunca é candidato, então não consome nenhum dos releases que uma tentativa testa, e uma fonte como o Radarr nunca é consultada sobre ele.

### Limites de indexador e chaves recusadas {#indexer-limits-and-refused-keys}

**zurg respeita o limite do DMM em vez de bater nele.** O DMM permite que a chave de um patrocinador faça 20 buscas por minuto somando todos os seus feeds de torrent, então o zurg envia ao DMM no máximo uma busca a cada três segundos. Uma busca além desse limite espera a sua vez, e esperar não é uma busca falha. Uma busca cuja vez chegaria depois do fim da tentativa do seu título, ou a mais de dois minutos de distância, não é feita: o título segue com o que os outros indexadores encontraram.

**Um indexador que responde 429 ou 503 fica em paz pelo tempo que pedir.** Cada busca, download de NZB e verificação de capacidades espera o `Retry-After` dele, até dois minutos, incluindo as requisições que já aguardam a sua vez. Um indexador que pede mais tempo não é consultado até lá.

**Vários zurgs numa mesma chave do DMM dividem as 20 buscas.** Cada um respeita o orçamento inteiro, então dois ou três na mesma chave ainda batem no limite do DMM, e cada recusa pausa as buscas no DMM desse zurg por um minuto. Um título pode então esperar mais tempo pela sua busca e pelo seu download.

**Uma chave recusada fica em paz por uma hora.** Um indexador que responde erro 100 (chave errada) ou 101 (conta suspensa, que é o que o DMM responde quando o patrocínio venceu) não é consultado de novo por uma hora, tanto para buscas quanto para downloads de NZB. O log avisa isso uma única vez, por exemplo `DMM torrents refused the API key: check dmm_api_key`, e a página de aquisição lista o indexador em **Indexers not asked now**. Uma chave que você trocar no `config.yml` é consultada na hora. Qualquer outro erro vale só para aquela busca.

## Escolhendo o release de um filme {#choosing-a-movies-release}

Os candidatos de Usenet de um filme são testados na ordem de quanto custa confirmá-los, e não só de quão bons eles são. Um post com um único vídeo nomeado custa duas leituras de artigos para o zurg e geralmente está completo. Já um conjunto de arquivos compactados com quarenta volumes exige uma passagem de dimensionamento e uma leitura no início e no fim de cada volume, e cerca de dois terços dos conjuntos de remux em vários volumes nos indexadores já não existem mais. O próprio contador `files` do indexador indica o formato, então os candidatos são ordenados por ele: dez arquivos ou menos, depois até trinta, depois mais, depois desconhecido, e pela quantidade dentro de cada faixa. Entre posts de custo igual, quando uma fonte como o Radarr avalia os lançamentos por um perfil próprio, um título que cita WEB-DL ou WEBRip vem primeiro, depois Blu-ray, depois o resto, e o post maior vem primeiro dentro de cada grupo. O ranking da própria fonte não é usado aqui, porque só é conhecido perguntando à fonte, e o zurg só pergunta sobre um lançamento quando está prestes a inspecioná-lo. Sem uma fonte, decidem primeiro o ranking de qualidade e depois o tamanho. Quando nenhuma fonte avalia os candidatos, a resolução pedida pela configuração `quality` vem antes do custo, então uma watchlist configurada com `best` ainda pega a melhor resolução disponível, com o post mais barato primeiro dentro dela. Resultados com o título de uma parte de um post dividido (`[1/9] "Movie.part1.rar"`) nunca são candidatos, e entre dois posts com o mesmo nome só o que tem menos arquivos é mantido, porque a biblioteca só pode ter um deles.

Até 24 candidatos são então inspecionados: cada NZB é baixado e lido com o parser próprio do zurg. Um post com no máximo dois arquivos de conteúdo, um deles um vídeo `.mkv`, `.mp4`, `.m4v`, `.avi`, `.mov` ou `.ts` com nome e com pelo menos 500 MB, é um post direto; volumes PAR2 e arquivos auxiliares como `.nfo`, `.sfv`, `.srr`, `.nzb`, imagens, `.txt`, `.url` e `.exe` não contam como conteúdo. O primeiro post direto é salvo na hora. Posts de arquivos compactados ficam em espera até que os diretos em análise acabem, e então são testados com menos volumes primeiro, por meio de um portão que não deixa mais de seis lançamentos de arquivos compactados esperando nos servidores de notícias ao mesmo tempo. Um post que tenha apenas dados de reparo e arquivos auxiliares nunca é salvo. Os NZBs inspecionados ficam guardados na memória, então, quando um lançamento salvo se revela morto e o título é tentado de novo, o próximo candidato é alcançado sem baixar os anteriores uma segunda vez. As buscas e os downloads de NZB compartilham um único limite de requisições em andamento por indexador, e um indexador que responde `429` ou `503` é consultado de novo depois de uma pausa, respeitando o `Retry-After` recebido. O painel mostra cada etapa: a busca, qual candidato está sendo inspecionado e o que foi salvo. Séries usam a verificação anterior: os três lançamentos melhor classificados que não foram deixados de lado. Quando uma fonte avalia os lançamentos, como o Sonarr faz, cada um é apresentado a ela primeiro, e um lançamento que ela recusa não ocupa nenhuma das três vagas. `best_first` muda a ordem das duas verificações, como explica a próxima seção.

## Colocando primeiro o melhor do perfil {#taking-the-profiles-best-first}

```yaml
acquisition:
  best_first: true
```

Desligado por padrão. Quando ligado, faz com que a primeira captura de uma fonte do Radarr ou do Sonarr siga a ordem de preferência do perfil de qualidade, em vez de ordenar pelo custo de verificação de cada release. A watchlist do Plex e o Seerr não têm perfil e não são afetados. A página de aquisição mostra quando está ligado.

- **A melhor resolução do perfil vem primeiro.** Cada release é posicionada pela resolução que o título indica. Sua posição é a melhor qualidade que o perfil permite nessa resolução. O zurg lê isso do perfil que já tem e não pede mais nada ao Radarr e ao Sonarr. WEB-DL, Blu-ray e remux de uma mesma resolução dividem a mesma posição. Dentro de uma posição, um filme ainda pega o release mais barato de verificar. Uma série pega o que `quality` classifica em primeiro. Um título que não indica resolução vai para o fim.
- **O cutoff conta como o topo.** Enquanto o perfil permite upgrades, toda qualidade igual ou acima do cutoff conta igual ao cutoff. A passagem de upgrade nunca substituiria nenhuma delas. Um perfil que faz upgrade até WEB 1080p não ganha nada com best first, mesmo que também permita 2160p. Um perfil que não permite upgrades mantém a ordem inteira. Seu primeiro arquivo é o que ele mantém.
- **Ele desce no perfil quando falha.** Um release cujo NZB não pode ser baixado ou lido é pulado. Um que os servidores de notícias recusam é descartado como antes. O próximo release na ordem do perfil é tentado. Uma tentativa ainda lê no máximo 24 NZBs no total, seja qual for a posição deles.
- **Ele vem antes da preferência por Usenet ou torrent.** Um torrent que uma conta já tem é capturado antes de um NZB que o perfil posiciona mais abaixo. `prefer` ainda decide entre um NZB e um torrent da mesma posição.
- **Um pacote de temporada precisa ser tão bom quanto os episódios avulsos.** Um pacote classificado abaixo de um episódio avulso da mesma busca é pulado. Os episódios são então capturados um a um. O Sonarr faz a mesma escolha. Só essa busca é comparada. Um episódio não é buscado de novo sozinho, caso exista um release melhor dele.

Isso tem um custo. O topo de um perfil de 2160p é composto principalmente por remux e conjuntos de Blu-ray com quarenta volumes ou mais, e não por arquivos de vídeo únicos. Esses conjuntos demoram mais para verificar. Com mais frequência já saíram dos servidores de notícias. Também esperam uma vaga no portão de arquivo. Por isso o primeiro arquivo geralmente chega mais tarde. Um título cujos melhores releases já saíram tem cada um deles capturado, verificado e descartado antes de o zurg descer no perfil. Uma temporada capturada como episódios avulsos são várias capturas onde um pacote seria uma só. O que ela economiza é a segunda captura. Um primeiro arquivo no cutoff nunca recebe upgrade.

## O que a aquisição faz com a lista da própria fonte {#what-acquiring-does-to-the-sources-own-list}

Uma watchlist do Plex é uma lista que alguém montou, e é o único registro de que essa pessoa quis um título. O Plex não guarda histórico de itens removidos. Duas configurações decidem o que o zurg pode fazer com ela. Ambas valem para fontes `plex_watchlist`. As fontes Seerr e Radarr não têm nenhuma lista na qual o zurg escreva, então as duas não fazem nada nelas.

`remove_after_grab` (padrão `true`) tira da watchlist um título já adquirido, assim que a release correspondente foi verificada. Foi sempre assim que a funcionalidade funcionou: a watchlist é lida como uma fila de coisas a buscar, e um título que o zurg já conseguiu está concluído. Se você definir como `false`, a watchlist continua sendo só uma watchlist, uma lista para navegar que o zurg atende em segundo plano sem editá-la. Deixar um título na lista não custa nada para verificá-lo de novo, porque o registro já cobre esse título, então nenhum indexador é consultado outra vez.

Um título para o qual o zurg não conseguiu nada continua na watchlist, independentemente desta configuração. Quando todas as releases que resolvem o título já estavam na biblioteca, seja a sua cópia ou uma trazida por outro pedido, nada foi baixado nem adicionado, e removê-lo só mexeria na sua lista. Essas releases continuam sendo verificadas, e o título conta como concluído, então ele não é buscado de novo enquanto estiver na lista. Se for removido e adicionado de novo, volta a ficar. Um título do qual o zurg baixou qualquer temporada ou episódio é um título que ele conseguiu, e sai da lista como antes.

`only_new_items` (padrão `true`) adota tudo o que a lista já tem na primeira vez que uma fonte roda, e age apenas sobre o que for adicionado depois. Ativar a funcionalidade deve começar a acompanhar uma lista, não gastar uma noite inteira processando tudo que ela já tem. Defina como `false` para tratar a lista existente como uma fila de pendências.

Essa configuração vale **uma única vez, na primeira execução de cada fonte**. Uma fonte que já tem uma fila está rodando, e essa fila, não esta chave, é quem registra o que já foi e o que não foi feito. Ligar a opção depois nunca descarta uma fila de pendências que já está em andamento. Um título adotado continua adotado enquanto estiver na lista. Removê-lo e adicioná-lo de novo é um pedido novo comum.

## Verificando uma captura {#verifying-a-grab}

Um NZB salvo não é um release. Que o indexador respondeu, que a resposta foi interpretada como NZB e que o arquivo chegou em `nzbs/` são fatos sobre o indexador, não sobre o post. Por isso, cada NZB adquirido é testado nas contas de news configuradas antes de o engine confirmar o pedido. Os primeiros dezesseis artigos e o último de cada arquivo de conteúdo são consultados com `STAT`. O primeiro artigo de cada arquivo, mais alguns outros em um release com poucos arquivos, é baixado inteiro (no máximo sessenta e quatro). Isso porque um servidor de news pode responder `STAT` para um artigo cujo conteúdo ele já retirou. Um artigo que o `STAT` recusa também é baixado inteiro antes de ser dado como perdido, porque um servidor de news pode recusar o `STAT` de um artigo que ainda serve (a NewsDemon fez isso em 21/10/2026). São no máximo dezesseis desses artigos por release. É o mesmo percurso que `/api?mode=addfile` faz para o Sonarr e o Radarr. São três respostas, e o importante é mantê-las separadas:

- **Artigos perdidos.** A aquisição não conta. O recibo é reaberto, então o alvo volta a ser procurado, e o release é registrado como morto por 30 dias. Assim, a próxima tentativa pega o próximo candidato, em vez de ficar presa no que já está na biblioteca. Um release nessa lista não é candidato: ele não é baixado e não gasta um dos candidatos que uma tentativa testa. Assim, uma sequência de posts mortos no topo de um ranking é percorrida, em vez de deixar tudo abaixo dela fora de alcance. Um season pack morto faz a temporada inteira voltar a ser procurada, e os episódios avulsos são pegos no lugar. Um NZB adquirido e salvo pelo próprio sistema é apagado do diretório de watch depois disso, para que um restart não carregue e verifique tudo de novo antes de a biblioteca abrir. Um NZB que já estava no diretório de watch ou na biblioteca, e um do qual o Sonarr ou o Radarr importou, continua onde está.
- **As contas não puderam ser consultadas.** Um pool fora do ar, uma conta sendo limitada ou o caso comum de uma biblioteca que ainda não listou o NZB novo. Nada foi confirmado, então nada é decidido. O pedido é verificado de novo em vinte segundos, depois em 40 e 80 segundos, e depois a cada dois minutos. Essa espera não gasta nenhuma tentativa. Uma verificação que simplesmente ficou sem tempo não é esse caso: ela é reiniciada logo, com o tempo cheio, até três vezes, antes de começar a esperar. Esse tempo é de cinco minutos, ou mais para um release com muitos arquivos em uma conta com poucas conexões. O zurg calcula isso a partir dessas duas informações, da verificação mais lenta já medida e das seis verificações que roda ao mesmo tempo, e depois dobra o valor. Um release de 90 volumes em quatro conexões recebe cerca de 53 minutos. Antes, cinco minutos acabavam em toda tentativa, até o release ser descartado sem verificação. Vinte verificações ao longo de duas horas que não confirmam nada descartam o release do mesmo jeito que um morto, e a próxima tentativa testa outro release. O pedido nunca é confirmado para um release que ninguém conseguiu verificar.
- **O release está lá.** O recibo solta o que estava segurando, e a confirmação segue em frente.

A verificação espera até que o zurg termine de descobrir os tamanhos exatos dos arquivos do release, ou desista deles. É o mesmo ponto em que o endpoint do SABnzbd verifica. Descobrir os tamanhos lê o primeiro artigo de cada arquivo, e a verificação também faz isso. Por isso, rodar as duas ao mesmo tempo só deixou ambas mais lentas. Numa lista de 99 filmes, verificar cada release assim que ele era listado fez o último arquivo chegar pasta do Radarr só depois de quase nove minutos. Uma verificação que ainda espera os tamanhos quando o tempo acaba é reiniciada logo, como uma que ficou sem tempo. Um release que ainda está tendo os tamanhos descobertos depois de 30 minutos é verificado mesmo assim. No máximo seis releases são verificados ao mesmo tempo, e os demais esperam a vez.

A verificação só lê. Ela não move corpos de artigos para o cache e não registra artigos mortos, então não pode silenciar um arquivo que toca. Quando a passagem de descoberta de tamanhos acabou de baixar o primeiro artigo de um arquivo, a verificação lê essa cópia em vez de baixar de novo.

Uma instalação sem conta de NZB (`nzb` ou `torbox_nzb`) não tem como verificar um pedido de NZB. A aquisição continua funcionando ali quando uma conta de debrid aceita torrents. Cada torrent é verificado pelo critério de chegar à biblioteca com arquivos dentro, como descreve [Newznab and Torznab](#newznab-and-torznab). Ele também precisa ter algo para tocar: um vídeo, um áudio ou um arquivo compactado que o zurg transmita (RAR, 7z, zip ou partes numeradas). Um torrent que tem só um programa, uma imagem de disco ou texto é falso, e novos episódios costumam atrair esse tipo de coisa nas primeiras horas depois que vão ao ar. Ele é descartado como um post morto, e o próximo release é testado na hora. Se o zurg o adicionou à conta para esse pedido, ele é apagado da conta de novo. Um torrent que a conta já tinha continua onde está. Um pedido de NZB nunca é confirmado sem conta de NZB, porque nada poderia verificá-lo nem reproduzi-lo. Um pedido que ficou esperando desde antes da remoção da última conta de NZB é descartado como um post morto, e o próximo release é testado.

## Persistência e recuperação {#persistence-and-recovery}

`data/acquisition.json` guarda IDs de fonte/pedido, tentativas, prazos de nova tentativa, trabalhos em andamento e recibos de cada aquisição, incluindo episódios. Ele também registra, por fonte, que um primeiro snapshot foi adotado, então `only_new_items` é decidido uma única vez e não a cada reinício.

Títulos e edições de mídia correspondentes reutilizam recibos entre fontes. Os nomes dos arquivos de release também são deduplicados contra a biblioteca e os NZBs salvos. Um recibo também carrega os grabs que ainda estão esperando uma resposta dos servidores de notícias, e o registro guarda os releases já considerados mortos. Assim, um reinício no meio da espera não confirma um grab não verificado nem devolve um release morto para o ranking.

Um recibo não é confiável para sempre: antes que um título conte como mantido, o zurg verifica se o que o resolveu ainda está lá. Isso significa o vídeo colocado numa pasta do Radarr ou Sonarr, ou, para um item wanted do DMM, uma watchlist do Plex ou um título do Seerr, o próprio release na biblioteca. Se um foi apagado desde então, ele é procurado de novo, mesmo quando o título ainda aparece na lista e o job terminou. Já um release apagado na página manage não é baixado de novo.

Cada release salvo é gravado no disco imediatamente. Contagens de tentativas e horários de nova tentativa são gravados em até um minuto, então uma queda pode perder até um minuto deles, mas nunca um grab.
Escritas fazem flush de um arquivo temporário, substituem o registro e fazem flush do diretório pai onde houver suporte. NZBs gravados antes de uma queda são reaproveitados, mesmo que a última escrita do registro não tenha terminado. Depois que a aquisição é registrada, as novas tentativas de remoção do Plex não adquirem o título de novo.

Falhas são tentadas de novo após 5, 10 e 15 minutos, depois uma hora, depois seis horas. A partir daí, um título espera metade do tempo em que vem falhando, então as esperas crescem: cerca de meio dia depois de um dia de falhas, dois dias depois de quatro, e no máximo cerca de uma semana, com variação de um quarto, para que títulos que falharam juntos não sejam tentados de novo juntos. Uma tentativa que esgota seus cinco minutos sem ter encontrado nada também conta como falha. Já uma tentativa que não encontrou nada enquanto um dos seus indexadores não pôde ser consultado, porque pediu para ser deixado em paz até um horário não mais que um dia à frente (um `Retry-After`), não conta. Nesse caso, o título é tentado de novo após esse horário, no máximo outro tanto depois, para que uma fila de títulos não consulte o indexador tudo de uma vez. Um indexador em descanso por dez minutos significa uma tentativa em até vinte. Isso acontece no máximo três vezes seguidas, e depois a tentativa conta normalmente. Um indexador que não informa horário, como um que responde 410 Gone ou recusa sua chave, não é aguardado.

Um título que falha há duas semanas, com pelo menos oito tentativas, é **parked**: o zurg para de perguntar aos indexadores sobre ele. Ele continua na página acquisition como parked, com há quanto tempo falha e o motivo, e o log avisa disso uma vez. **Resume** nessa página, para um título ou para todos os títulos parked de uma fonte, reinicia a contagem a partir da primeira espera curta. Uma fonte que deixa de listar um título e depois o lista de novo pediu por ele de novo, então isso também o retoma. Um grab confirmado pelos servidores de notícias reinicia as duas semanas de um título, então uma temporada que ainda está encontrando episódios nunca é parked. Um upgrade também não é, de qualquer fonte: o release melhor pode sair meses depois e o título continua listado, então ele mantém novas tentativas com no máximo uma semana de intervalo. Nada da sua lista wanted do DMM é parked, pelo mesmo motivo: um filme que ainda não saiu, ou um antigo que ninguém postou, continua wanted até ser obtido ou você removê-lo. Contagens e prazos sobrevivem a reinícios, inclusive a desligamentos longos.

Uma fila que falha para sempre custa caro de um jeito que a lista de títulos não mostra. Numa instalação, milhares de títulos do Radarr e Sonarr para os quais nada foi encontrado, retentados a cada seis horas para sempre, levaram um indexador de algumas centenas de consultas por dia para dezenas de milhares, e o indexador suspendeu a conta. A maioria era de filmes sem release em Usenet e upgrades em que todo release permitido pelo perfil já tinha sido recusado. Pedidos abertos do Seerr continuam monitorados. Itens do Plex saem da watchlist somente depois que todas as temporadas planejadas forem adquiridas *e* verificadas (um NZB contra os servidores de notícias ou, numa conta `torbox_nzb`, pelo fato de o TorBox ter baixado o arquivo; um torrent ao alcançar a biblioteca com algo para reproduzir), somente quando `remove_after_grab` permitir, e somente quando o zurg tiver baixado algo para eles. O fallback de episódios avulsos continua limitado a episódios encontrados nos resultados dos indexadores.

Uma fonte indisponível pausa o próprio trabalho. Uma gravação de estado que falhou pausa novas aquisições até que o salvamento funcione. Um registro ilegível ou não suportado pausa a aquisição e preserva o arquivo; conserte ou restaure o arquivo e reinicie o zurg. Os outros serviços do zurg continuam rodando.

O antigo `data/plex-watchlist.json` é importado uma única vez, com histórico, novas tentativas e tentativas que aguardam só a remoção do Plex preservados. O arquivo original é mantido. Os dois registros entram nos backups normais sem `--include-caches`. Mantenha `data/` e `nzbs/` ao substituir contêineres.

## Adicionando outro adaptador {#adding-another-adapter}

Implemente `acquisition.Source` no próprio pacote:

1. `ID()` identifica a instância entre reinicializações.
2. `List(ctx)` retorna um snapshot completo de referências `Item`. Faça o snapshot falhar em caso de erros de paginação. Persista apenas metadados, nunca credenciais nem objetos completos de usuário da API.
3. `Resolve(ctx, item)` revalida o item e retorna alvos normalizados de filme, temporada ou episódio. `Gone` cancela trabalho indesejado. `Follow` mantém um pedido aberto sendo monitorado depois que os alvos atuais forem adquiridos.
4. `Complete(ctx, item)` confirma uma aquisição de uma única vez. Ele precisa tolerar chamadas repetidas depois de uma queda. Uma lista somente leitura pode usar um no-op. O engine só o chama quando todos os grabs por trás do item tiverem respondido, então um adapter nunca precisa verificar um release por conta própria, e não deve tratar o fato de ter sido chamado como evidência de nada além disso.

Um source com perfil de qualidade próprio também pode implementar `acquisition.Assessor`, avaliando cada release candidato pelas suas próprias regras. Os adapters do Radarr e do Sonarr fazem isso, usando os próprios parsers.

Registre o tipo de configuração e a factory no serviço de acquisition. A fila, a persistência, os retries e o executor não precisam de nenhum branch específico para source. Trakt, MDBList e Simkl podem se encaixar nesse contrato, mas ainda não estão implementados.
