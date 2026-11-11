# Como criar addons para o rex {#building-rex-addons}

[rex](https://rex.debridmediamanager.com/pt/) mostra o que as suas fontes dizem a ele sobre. Uma fonte diz ao rex o que ela tem pela API de feed e entrega os arquivos quando o rex pede. Para o rex, todas as fontes são iguais. Um **addon** é uma fonte que você mesmo escreve para vídeos caseiros, gravações, catálogos do Stremio, [música](#music) ou [canais ao vivo](#live-tv).

Esta página explica o que o rex precisa de um addon, como nomear os itens dele e as regras que importam. Ela termina com o [rex-stremio](https://github.com/debridmediamanager/rex-stremio) como um exemplo em um único arquivo.

Um addon faz três coisas:

- **Entrega os bytes.** O rex baixa cada byte do seu addon por HTTP quando alguém aperta play: um arquivo ou um stream para o qual o rex é redirecionado.
- **Diz ao rex o que tem.** Ele envia uma lista pela API de feed do rex e, depois, toda mudança. O rex nunca escaneia nada.
- **Dá nome ao que traz.** Para coisas que nenhum agente conhece, o seu addon envia ele mesmo o título, a sinopse, a data e as artes. Os apps do Plex mostram tudo como qualquer outra biblioteca.

Se o que você traz são filmes e séries que o Plex já conhece (ele tem os IDs deles no IMDb ou no TMDB), o ideal é [rex com o seu próprio app](any-source.md): aí o Plex nomeia e descreve tudo para você.

Para trazer os catálogos dos seus addons do Stremio para o rex, não há nada para escrever: o rex-stremio já está pronto. Você cola os links dos seus addons na página de configurações dele e marca os catálogos que quiser.

**Prefere começar com código pronto?** Três tutoriais, cada um monta um addon completo em um único arquivo Python, usando só a biblioteca padrão, e explica o que cada parte faz:

| Tutorial | Traz para o rex |
|---|---|
| [Vídeos caseiros](addon-home-videos.md) | Uma pasta com os seus próprios vídeos, como uma biblioteca com títulos, datas e pôsteres extraídos dos próprios vídeos |
| [Música](addon-music.md) | Uma pasta de álbuns, nomeados pelo Plex via MusicBrainz, com letras |
| [IPTV](addon-iptv.md) | Uma playlist M3U e o seu guia XMLTV, como canais de Live TV com guia |

Esta página explica cada passo que esses tutoriais dão. [Mais do seu addon](addon-more.md) adiciona legendas, trailers, capítulos, coleções, playlists e o resto.

## Antes de começar {#before-you-start}

| Você precisa | Por quê |
|---|---|
| rex, configurado como em [rex com seu próprio app](any-source.md) (passos 1 a 3) | É aí que a biblioteca do seu addon aparece |
| Um nightly do rex com data 2026.10.25 ou mais recente, ou 2026.11.02 ou mais recente para [Music](#music) e [Live TV](#live-tv) | Esta página foi escrita para ele |
| FFmpeg onde o rex roda, se o seu addon serve streams | O rex toca um stream convertendo-o (uma cópia, barata). O rex encontra o FFmpeg sozinho; veja [Converting video](any-source.md#converting-video-optional) |
| Seu addon na mesma máquina do rex, ou na sua rede doméstica | O feed do rex responde só para eles: veja [Keep the port private](any-source.md#keep-the-port-private) |

Esta página escreve o endereço do rex como `192.168.1.20:32400` e o do addon como `127.0.0.1:9981`. Coloque o seu no lugar deles. A referência completa da API do rex está em [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Passo 1. Sirva os arquivos {#step-1-serve-the-bytes}

**O que faz.** Dá a cada vídeo uma URL que o rex consegue ler.

**Por que importa.** O rex não guarda mídia. Toda vez que alguém aperta play, o rex lê o vídeo do seu addon.

Seu addon é um servidor HTTP. Um vídeo fica em `<your address>/<path>`, e `path` é o que você escolher. Existem dois tipos:

| Você serve | Como | O que o rex faz |
|---|---|---|
| **Um arquivo** (`.mkv`, `.mp4`, ...) | Responda `GET` com o arquivo. Responda pedidos `Range` (`206`) para que o avanço seja rápido; sem eles, o rex lê desde o início a cada avanço | Os apps do Plex reproduzem direto quando conseguem, ou o rex converte |
| **Um stream** (HLS, `.m3u8`) | Responda `GET` com a playlist, ou com um redirecionamento para ela. Os redirecionamentos são seguidos, e seu login nunca é enviado a outro host | O rex sempre converte: uma cópia da imagem e do som no formato que o app reproduz. Um app que lê o arquivo direto é enviado para essa conversão |

Opcional, mas vale a pena:

- **Um login.** Basic auth (`user`, `password`) ou um bearer token. O rex envia isso apenas para o endereço do seu addon.
- **Exclusões.** Quando alguém exclui um título em um app do Plex, o rex primeiro envia ao seu addon um `DELETE` do WebDAV para o path. Responda `2xx` (excluído) ou `404` (já não existe) e o rex remove o título. Qualquer outra resposta, e o app do Plex informa que não foi possível excluir.

## Passo 2. Registre-se no rex {#step-2-register-with-rex}

**O que faz.** Diz ao rex o nome do seu addon, onde estão os seus bytes e quais bibliotecas ele preenche.

**Por que importa.** O rex não lê nada de uma fonte que ele não conhece. Registrar de novo não muda nada, então faça isso toda vez que o seu addon iniciar.

+++ Linux and macOS
```bash
curl -X PUT http://192.168.1.20:32400/rex/sources/myaddon \
  -H 'Content-Type: application/json' \
  -d '{"url": "http://127.0.0.1:9981",
       "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++ Windows
```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/myaddon -ContentType application/json `
  -Body '{"url": "http://127.0.0.1:9981", "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++

| Campo | Significado |
|---|---|
| `url` | Onde estão os seus bytes. Os bytes de um vídeo são `GET <url>/<path>` |
| `user` and `password`, or `bearer` | O login do seu addon, se ele tiver um. Nunca dentro de `url` |
| `directories` | As bibliotecas que o seu addon preenche. Cada entrada é um primeiro segmento do caminho (`name`) e o título da biblioteca: `shows` para uma biblioteca de séries, `movies` para uma biblioteca de filmes, `music` para uma biblioteca de música, ou várias. O rex cria cada biblioteca na primeira vez; se você renomear no Plex, o nome fica |
| `trash` | `false` apaga o que o seu addon remove (um snapshot que deixa de fora um item, ou um `DELETE`) em vez de guardar na lixeira do rex |

O primeiro segmento do caminho escolhe a biblioteca: no exemplo acima, todo caminho que começa com `kids/` cai em **Kids**. Use um primeiro segmento diferente para cada biblioteca.

**O que você deve ver.** O rex responde com a fonte. O log do rex diz `SOURCES myaddon registered at http://127.0.0.1:9981` e, na primeira vez, `SECTION create Kids (show) for myaddon's kids`. A biblioteca aparece nos apps do Plex em More em menos de um segundo.

## Passo 3. Descreva cada vídeo {#step-3-describe-each-video}

**O que faz.** Monta o registro que o rex guarda para cada vídeo: onde ele está, o que é e como é.

**Por que importa.** Esse registro é tudo o que o rex sabe. Uma sonda ausente ou um id que muda causa a maioria dos bugs do addon.

```json
{
  "id": "home-2026-07-22-beach",
  "path": "kids/summer-2026/beach.mp4",
  "kind": "episode", "season": 1, "episode": 3,
  "name": "Summer 2026",
  "media_info": { "...": "ffprobe's output, whole" },
  "display": {
    "title": "First day at the beach",
    "summary": "...",
    "date": "2026-07-22",
    "thumb": "http://127.0.0.1:9981/kids/summer-2026/beach.jpg",
    "show": {"title": "Summer 2026", "summary": "...", "poster": "https://...", "art": "https://..."},
    "season": {"poster": "https://..."}
  }
}
```

| Campo | Obrigatório | Significado |
|---|---|---|
| `id` | sim | Sua chave para este vídeo, **para sempre**. O rex guarda o histórico de exibição com base nela |
| `path` | sim | Onde estão os bytes dele dentro do seu `url`. O primeiro segmento escolhe a biblioteca |
| `media_info` | sim, na prática | O JSON do ffprobe com `-show_format -show_streams` do vídeo (para um stream, faça a sonda na URL dele). Sem ele o arquivo fica **retido**: é armazenado mas não aparece, porque os apps do Plex não reproduzem um vídeo que não conhecem. Um stream (`.m3u8`) sem ele é rejeitado com `not a video file`, então envie um stream só depois de sondá-lo |
| `kind` | para uma série | `episode` ou `movie`. Sem ele nada coloca o vídeo no lugar: em uma biblioteca de séries ele vira um episódio de uma série com o nome de `name`, numerado na ordem dos arquivos; em uma biblioteca de filmes, um filme com o título do arquivo |
| `season`, `episode` | para um episódio | Onde ele vai. Numere os episódios de forma que um novo nunca desloque os outros |
| `name` | não | O nome da série, que também agrupa os episódios. Padrão: o nome da pasta dele (o nome do arquivo, para um path sem pasta) |
| `release` | não | Agrupa os vídeos que pertencem juntos. Padrão: a pasta do vídeo |
| `display` | para o que nenhum agente conhece | Título, resumo, data e artes: Passo 4 |

O `path` de um stream termina em `.m3u8`, e o `media_info` dele tem `"format_name": "hls"`. O rex só aceita com as duas coisas. Qualquer outro arquivo precisa ter uma extensão de vídeo.

## Passo 4. Dê um nome e uma aparência {#step-4-name-and-dress-it}

**O que faz.** Dá aos apps do Plex um título, resumo, data e imagens para o que nenhum agente do Plex conhece.

**Por que importa.** Sem `display`, um episódio aparece como "Episode 3" com um bloco em branco, e uma série não tem pôster.

| Campo | Onde aparece |
|---|---|
| `title`, `summary` | O título e o resumo do vídeo, exatamente como foram enviados |
| `date` | A data de lançamento (`YYYY-MM-DD`), e o ano dela. Ou só o ano (`YYYY`) para algo conhecido apenas pelo ano, como um filme antigo: os apps do Plex mostram então o ano e nenhum dia de lançamento |
| `thumb` | O pôster de um filme, ou a imagem de cena de um episódio |
| `art` | O fundo de um filme |
| `show.title`, `show.summary`, `show.poster`, `show.art` | A série do episódio |
| `season.summary`, `season.poster` | A temporada do episódio (o pôster da série quando não há um) |

Todos os campos são opcionais. As imagens são URLs `http://` ou `https://`. O rex busca as imagens por conta própria: da internet pública, ou do endereço do seu addon (o `url` que você registrou), com o login do seu addon. Qualquer outro endereço da sua rede doméstica é recusado. Assim, um addon pode servir as próprias imagens, como um quadro de cada vídeo caseiro. Uma imagem 2:3 faz o melhor pôster, e uma 16:9 a melhor imagem de cena e de fundo.

Como o rex trata esses campos:

- **Só para o que ninguém nomeia.** Um vídeo enviado com `kind` e `ids` que o Plex conhece é mostrado como o Plex descreve, e `display` é ignorado.
- **Envios posteriores atualizam.** Envie o vídeo de novo com um `display` novo e a linha, a série e a temporada mudam no lugar; os apps redesenham as novas imagens. Uma série mantém o título com que foi criada.
- **Quem editou vence.** Um campo que alguém editou e travou em um app do Plex mantém o valor dessa pessoa, e um pôster que ela enviou continua lá.
- **É verificado.** Uma imagem que não seja URL http(s), ou uma data em outro formato, recusa o vídeo e informa qual campo causou o problema.

## Passo 5. Envie {#step-5-send-it}

**O que faz.** Envia seus vídeos para o rex: tudo de uma vez de tempos em tempos, e as mudanças conforme acontecem.

**Por que importa.** O rex mostra exatamente o que você enviou por último.

| Para | Envie | O rex responde |
|---|---|---|
| Adicionar ou alterar vídeos | `POST /rex/feed/myaddon/items` com `{"items": [...]}` | Quantos foram `created`, `updated`, `held`, `unchanged`, e cada `rejected` com o motivo |
| Remover vídeos | `DELETE /rex/feed/myaddon/items` com `{"ids": [...]}` | Quantos foram `trashed`, `deleted`, `released` (os retidos são esquecidos) e `unknown` |
| Enviar tudo | `PUT /rex/feed/myaddon/snapshot` com `{"items": [...]}`. Em partes: `"session"` (qualquer texto), `"part"` começando em 0, `"complete": true` na última | Os mesmos totais, e o que foi `removed`: todo vídeo seu que o snapshot não citou |

Envie algumas centenas de vídeos por requisição. Um snapshot que não cita nada não remove nada, e um que removeria mais da metade dos seus vídeos é recusado, a menos que a última parte tenha `"force": true`: um addon que perdeu o controle das coisas não pode esvaziar sua biblioteca por acidente.

**O que você deve ver.**

+++ Linux e macOS
```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/items | head -c 400   # what rex shows, with each ratingKey
curl -s http://192.168.1.20:32400/rex/feed/myaddon/held                  # what waits for a probe
```
+++ Windows
```powershell
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/items   # what rex shows, with each ratingKey
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/held    # what waits for a probe
```
+++

O log do rex nomeia cada vídeo recusado e o motivo: `FEED myaddon rejected <id>: <reason>`.

## Música {#music}

**O que faz.** Traz álbuns para uma biblioteca de música, que o Plexamp, o Plex Web e o Plex para Android reproduzem.

**Por que importa.** O Plex nomeia a música pelo release do álbum no MusicBrainz. Envie esse id e o Plex preenche sozinho todos os títulos, capas, fotos de artistas e biografias.

Envie cada arquivo de áudio como uma faixa:

```json
{
  "id": "albums/in-rainbows/01",
  "path": "music/Radiohead/In Rainbows/01 - 15 Step.flac",
  "kind": "track",
  "ids": {"mbid": "3b408cb5-7d51-4188-b07c-fabcf308cda3"},
  "disc": 1, "track": 1,
  "media_info": { "...": "ffprobe's output, whole" }
}
```

| Campo | Significado |
|---|---|
| `kind` | `track` |
| `path` | Um arquivo de áudio: `.flac`, `.mp3`, `.m4a`, `.aac`, `.ogg`, `.oga`, `.opus`, `.wav`, `.alac`, `.aif`, `.aiff`, `.wma`, `.ape`, `.wv`, `.dsf` ou `.mka` |
| `ids.mbid` | O id do **release** do álbum da faixa no MusicBrainz: o id do link `musicbrainz.org/release/<id>`, não o de um release group nem o de uma gravação. Ou `ids.plex`, o guid de álbum do próprio Plex (`plex://album/<id>`) |
| `disc`, `track` | Onde a faixa está nesse release. A faixa do Plex com esses números é a que aparece |
| `release` | Qual cópia do álbum a faixa pertence. Padrão: a pasta dela. Cada cópia é um álbum próprio, como o Plex lista duas cópias, então envie um `release` para os arquivos de uma cópia que estão em pastas de disco (`CD1/`, `CD2/`) |
| `display` | Para música que o Plex não conhece: o `title` da faixa, o `artist` (`title`, `summary`, `poster`, `art`) e o `album` (`title`, `summary`, `poster`, `date`) |
| `lyrics` | Arquivos de letra ao lado dela no seu addon: `[{"path": "music/.../01 - 15 Step.lrc", "size": 147}]`. Um `.lrc` (letra com tempos) ou um `.txt`, exibido como a letra da música |
| `loudness` | Só se o seu addon medir o volume, com os nomes do Plex: `gain`, `albumGain`, `peak`, `albumPeak`, `albumRange`, `loudness` e `lra`, os fades `startRamp` e `endRamp`, e `levels`, o volume a cada 100 ms. O rex não mede nada por conta própria |

- **Uma biblioteca de música primeiro.** Declare uma no Passo 2 (`"directories": [{"name": "music", "music": "Music"}]`), ou adicione uma biblioteca de Música em um app do Plex. Uma faixa que nenhuma biblioteca de música aceita é recusada: `no music library holds <file>`.
- **Encontrando o id do release.** Pesquise no MusicBrainz pelo título e artista do álbum (`https://musicbrainz.org/ws/2/release?query=release:%22In%20Rainbows%22%20AND%20artist:Radiohead&fmt=json`) e escolha um lançamento oficial com o seu número de faixas. Vários costumam bater (um por país), e qualquer um deles identifica o álbum. O MusicBrainz responde a uma requisição por segundo por endereço e recusa mais, e pede um User-Agent com o nome do seu addon. Pergunte uma vez por álbum e guarde a resposta.
- **O rex não lê tags.** Títulos, capas, gêneros e artistas semelhantes são do Plex. Uma faixa cujo release o Plex não conhece mostra o seu `display`, agrupada sob o artista e o álbum que você informar, ou o nome do arquivo em `[Unknown Artist]` sem ele.
- **Ele toca como está.** Não é preciso FFmpeg, a não ser que um app peça uma qualidade menor que a original: aí o rex converte com FFmpeg, como o Plex faz.
- **O que não tem.** A rádio, as mixes, as estações e as faixas sonicamente semelhantes do Plexamp precisam de uma análise que o rex não faz.

**O que você deve ver.** O álbum na biblioteca de música com a capa e os nomes das faixas do Plex, e o artista com uma foto. No Plexamp, escolha a biblioteca de música do rex como biblioteca.

## TV ao vivo {#live-tv}

**O que faz.** Transforma um stream ao vivo em um canal do **Live TV** no Plex Web e no Plex para Android, com um guia de TV, What's On e um número de canal.

**Por que importa.** Um stream ao vivo sozinho é só uma linha na biblioteca. Com um `channel`, as pessoas encontram o stream do jeito que encontram TV: no guia, pelo que está passando agora.

Envie o stream ao vivo como no Passo 3 (um `.m3u8` com o seu probe), mais um `channel`:

```json
"channel": {
  "number": "100.1",
  "title": "Rex News",
  "guide": [
    {"start": "2026-11-01T18:00:00Z", "end": "2026-11-01T19:00:00Z",
     "title": "Evening News", "summary": "The day's headlines.", "categories": ["News"]},
    {"start": "2026-11-01T19:00:00Z", "end": "2026-11-01T19:45:00Z",
     "title": "The Pilot", "type": "episode", "show": "Rex Stories", "season": 1, "episode": 1,
     "categories": ["Drama"]}
  ]
}
```

| Campo | Significado |
|---|---|
| `number` | O número do canal no guia (`100.1`, `704`): letras, dígitos, `.`, `-` e `_`. Escolha números que não sejam usados pelos outros addons; o primeiro canal enviado com um número fica com ele |
| `title` | O nome dele no guia. Padrão: o título `display` do stream |
| `call_sign` | O nome curto dele. Padrão: `title` |
| `guide` | O que está passando: `start` e `end` (segundos epoch, ou ISO 8601 com `Z` ou um offset), `title` e, opcionalmente, `summary`, `categories`, `thumb` e `previously_shown` (`true` para uma reprise). Um episódio adiciona `"type": "episode"` com `show`, `season` e `episode`, e o guia agrupa ele pela série |

- **Envie o guia de algumas horas atrás até o máximo que você souber à frente** (cerca de uma semana, como fazem os arquivos de guia de TV), e envie de novo sempre que ele mudar. O rex mostra um programa até três horas depois do fim dele. Cada envio substitui o guia do canal; um envio sem `channel` mantém o guia; `"channel": null` encerra o canal.
- **O FFmpeg é necessário**, como para qualquer stream: o rex converte o canal enquanto alguém assiste.
- **Nada é gravado.** O Plex Web e o Plex para Android não oferecem um botão Record.
- **Canais que terminam.** Registre com `"trash": false` (Passo 2) para que um canal que você remova seja apagado, e não guardado na lixeira do rex.
- **O que a categoria faz.** Um episódio em `Sports` ou `News` aparece nas prateleiras Sports e News do What's On. Um programa sem `type` é mostrado como filme, como o Plex faz com qualquer guia de TV.

**O que você deve ver.** No Plex Web ou no Plex para Android, **Live TV** no menu do app, o canal no guia no número dele, e o stream tocando quando você abre o canal. O log do rex informa um canal recusado e o motivo, como `channel.guide[3]: end must be after start`.

[rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) faz tudo isso para os canais de um servidor de esportes ao vivo: ele numera os canais por grupo a partir de `100.1`, mantém o número de cada canal e pega os guias da Pluto TV e dos arquivos XMLTV gratuitos da epgshare01.

## As regras que pegam as pessoas de surpresa {#the-rules-that-trip-people-up}

| Regra | O que acontece se você quebrar |
|---|---|
| **Um id é para sempre.** Mudou o id e o vídeo vira um título novo | O histórico de exibição e as edições ficam na linha antiga, que o próximo snapshot remove |
| **Um vídeo, um caminho.** Dois ids não podem compartilhar o mesmo `path` | O segundo é rejeitado: `... is already <id>'s file` |
| **Os bytes de um arquivo são fixos por id.** O rex mantém os streams com que foi analisado pela primeira vez; uma análise posterior muda só os capítulos. Só um stream (`.m3u8`) aceita uma nova análise com streams diferentes | Se os bytes de um arquivo mudarem (outro formato, um upload corrigido), dê a ele um novo id e um novo caminho |
| **Analise tudo.** Sem `media_info`, sem vídeo | O arquivo fica em `held` até um envio trazer um; um stream é rejeitado |
| **Mantenha o nome da fonte.** As linhas pertencem a (source, id) | Outro nome começa uma fonte vazia; as linhas da antiga ficam até você apagá-la |
| **Snapshots são completos.** Um que deixa de fora um canal o remove | Não envie um snapshot depois de uma falha parcial: pule essa rodada |

Para **substituir** um addon (ou um script) que já preencheu uma biblioteca, mantenha o nome da fonte, os ids e o primeiro segmento do caminho. Seu primeiro envio então atualiza as linhas dele no lugar, com histórico de exibição e tudo, em vez de criar novas.

## Exemplo: rex-stremio {#example-rex-stremio}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) transforma os catálogos dos seus addons do Stremio em bibliotecas do rex: filmes numa biblioteca de filmes, séries numa biblioteca de TV, canais ao vivo numa biblioteca chamada Live TV (não o guia da Live TV). Ele faz os Passos 1 a 5 e é um único arquivo Python, que usa só a biblioteca padrão. Ele não faz exclusões: os títulos de um catálogo não são dele para apagar.

**Registro.** Cada catálogo que você marca dá nome a uma biblioteca: Stremio Films, Stremio Shows ou Live TV, a menos que você renomeie. O rex-stremio se registra como `stremio`, com um diretório por biblioteca, nomeado como ela (`stremio-films`), e declara essa biblioteca como o título `shows` do diretório para catálogos de séries, ou como o título `movies` para catálogos de filmes e de TV ao vivo.

**Servindo.** Os links dos addons de stream expiram, então o rex-stremio não guarda nenhum link. Ele serve uma URL por título, `/<directory>/<catalog>/<id>.<ext>`, e responde com um redirecionamento para um link que ele pede naquele momento:

```python
url = app.sync.resolve(vid)   # ask every stream addon, rank, take the first link that opens
self.send_response(302)
self.send_header("Location", url)
```

Ele pergunta a cada addon que serve o título (`/stream/<movie or series>/<id>.json`), mantém só os links `http(s)` simples (o `infoHash` de um torrent não é um arquivo que o rex consegue ler), descarta o que estiver acima dos seus limites de resolução ou tamanho, e tenta o resto começando pela maior resolução. O link que abre fica em cache até uma hora antes de expirar (ou por uma hora, quando o link não informa a validade). O rex segue o redirecionamento e lê o arquivo, com seek, direto do link. Um link que precisa de headers próprios é repassado pelo próprio rex-stremio, e uma playlist HLS master é respondida só com a sua melhor variante.

**Sondagem.** Uma vez por título, o rex-stremio roda ffprobe na sua própria URL, para que o `media_info` descreva exatamente o que o rex vai ler, e guarda o resultado em cache. Ele verifica `probe_workers` títulos de uma vez (4, a menos que você defina outro valor), e ainda pergunta a cada host de addon no máximo uma vez a cada `stream_interval_seconds`. O stream de onde veio aquele probe fica guardado e é tentado primeiro em cada reprodução, então o que toca é o que o rex foi informado. O container do probe define a extensão do caminho: `.mkv`, `.mp4`, `.ts`, `.avi`, ou `.m3u8` para HLS.

**Probes salvos.** Com uma chave de API do DMM (`dmm_api_key`, ou **DMM** na página de configurações), um stream de torrent pula o ffprobe quando o DMM já tem um probe do seu arquivo. O hash do torrent vem do `infoHash` do stream ou do seu link (os links de debrid do Torrentio trazem o hash no caminho). O rex-stremio lê o tamanho do arquivo na resposta do link a um `Range` de um byte, e pergunta ao `POST /api/sponsor/mediainfo` do DMM por até 100 hashes de cada vez. Ele usa o probe do DMM só quando exatamente um arquivo daquele release tem esse tamanho, e esse nome quando o stream informa o nome do arquivo. Todo o resto passa pelo probe descrito acima, e esse probe volta para o DMM (`POST /api/sponsor/probes`: o hash do torrent, o tamanho do arquivo, o nome dele quando o stream informa, e a saída do ffprobe sem o endereço que ele leu), para que o próximo sponsor que encontrar o arquivo pule essa etapa. O DMM mantém o primeiro probe de um arquivo e responde primeiro com os snapshots do próprio zurg. `share_probes: false` mantém os probes só no rex-stremio; os do DMM continuam sendo usados. O probe de uma playlist nunca é enviado.

**Nomeação.** Cada filme e episódio vai para o rex com `kind` e o seu id do IMDb em `ids`, para que o Plex nomeie como em [rex com seu próprio app](any-source.md). O título, a sinopse, a data e o pôster do catálogo vão em `display`, que só aparece até o Plex nomear o item. Um canal ao vivo, ou um título que só o addon conhece, não tem id do IMDb, então só o `display` o nomeia.

**Numeração.** Um filme é um filme. As temporadas e os episódios de uma série vêm do Cinemeta, cujos ids são do IMDb, e mantêm os números dele, então um episódio novo nunca desloca os outros. O rex os coloca nos números do TMDB, então, onde os números do Cinemeta forem diferentes, um episódio cai no lugar errado.

**IDs.** Um id é o catálogo mais o id do IMDb (e temporada e episódio), como `st-<catalog>-tt0111161`. Ele nunca muda, então um mesmo filme em dois catálogos são dois itens. Com **Catalogs as collections** ativado, um filme ou série listado por vários catálogos de uma mesma biblioteca é um só título ali, em cada coleção de catálogo.

**Envio.** A cada seis horas e depois de cada salvamento: registro, depois cada título assim que é verificado (`POST .../items`, até 20 títulos ou o que estiver pronto a cada 5 segundos), e então um snapshot de cada catálogo, em partes de 200. O primeiro snapshot depois de um salvamento vem com `"force": true`, já que desmarcar catálogos pode remover mais da metade dos itens. Se um catálogo responder vazio ou só em parte, a rodada não envia snapshot: ela adiciona e atualiza, mas não remove nada, e uma rodada completa posterior remove o que realmente saiu.

## Solução de problemas {#troubleshooting}

| Você vê | Por quê | Correção |
|---|---|---|
| `rejected`: `not a video file` | O nome do arquivo não tem extensão de vídeo, ou é um `.m3u8` cujo probe não é `hls` | Nomeie os streams como `.m3u8` e envie o probe deles. Uma música precisa de `"kind": "track"` |
| `rejected`: `no music library holds <file>` | Nenhuma biblioteca de música aceita a faixa | Declare uma com `music` no Passo 2 |
| Álbuns mostram os nomes dos seus arquivos em `[Unknown Artist]` | Não há `ids.mbid`, ou o id de release não é conhecido pelo Plex, e não há `display` | Envie o id de release do álbum no MusicBrainz, ou um `display` |
| Um álbum mostra as faixas erradas | `ids.mbid` aponta para outra edição do álbum, como uma deluxe com mais faixas | Escolha um release com o seu número de faixas |
| Um canal não está no guia da Live TV | Não há `channel`; ele foi recusado, e o log do rex diz o motivo (`channel.guide[...]`); ou outro canal já tem esse número, o que não é registrado no log | Corrija o campo que o log indica, ou escolha um número livre |
| A Live TV não aparece em um app do Plex | Nenhum item foi enviado com `channel` ainda, ou o app não foi testado | Envie um `channel`, e use o Plex Web ou o Plex para Android, que são os apps testados |
| Um vídeo nunca aparece | Ele está retido (o `media_info` não tem streams, ou um arquivo foi enviado sem ele), ou um stream enviado sem `media_info` foi rejeitado | Faça o probe e envie de novo |
| `rejected`: `... is already <id>'s file` | Outro id já tem esse `path` | Mantenha um id por path |
| Um snapshot responde `409`: `the snapshot would remove more than half of this source's items` | Seu snapshot deixa de fora mais da metade do que o rex tem de você: um disco ausente, uma listagem que falhou, ou uma limpeza de verdade | Resolva o que sumiu. Se você quis mesmo isso, envie a última parte do snapshot com `"force": true` |
| Episódios com título "Episode 1" e miniaturas em branco | Não há `display` | Envie um `display` com cada vídeo |
| Um filme enviado com o id do IMDb mantém o seu título de `display`, e não o do Plex | O rex só pede os títulos ao Plex depois que ele é reivindicado | Reivindique o rex: [passo 3 do rex com seu próprio app](any-source.md#step-3-add-it-to-a-plex-account) |
| As imagens não aparecem | A URL está na sua rede doméstica, mas fora do `url` registrado do seu addon, ou não é http(s) | Sirva as imagens pelo endereço do próprio addon, ou hospede-as na internet pública. |
| A reprodução falha com 502 no log do rex | Seu addon não respondeu, ou o site do stream recusou a conexão | Verifique primeiro o log do próprio addon |
| Um título apagado em um app do Plex continua aparecendo | Seu addon respondeu ao `DELETE` com algo diferente de `2xx` ou `404` | Apague do seu lado e depois responda com `2xx` |
| Um título apagado volta | Seu addon continua enviando o vídeo | Pare de enviar o que foi apagado |

Ainda com problemas? Pergunte no fórum **rex-support** no [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) diz o que incluir.
