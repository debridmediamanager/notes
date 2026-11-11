# Mais do seu addon {#more-from-your-addon}

[Criar addons do rex](addons.md) cobre o básico. Esta página adiciona legendas, trailers, capítulos, coleções,
playlists, imagens de artistas, filmes conhecidos, bibliotecas grandes, correções e remoção. Cada seção adiciona campos ao
[Passo 5](addons.md#step-5-send-it). Teste-os nos tutoriais de [vídeos caseiros](addon-home-videos.md), [música](addon-music.md)
ou [IPTV](addon-iptv.md).

Todos os exemplos foram enviados para o rex nightly 2026.11.02. A referência completa está em [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Filmes e séries que o Plex conhece {#films-and-shows-plex-knows}

**What it does.** Faz o Plex mostrar o nome de um filme ou episódio, com o pôster, o elenco, a sinopse e as notas, em vez do seu `display`.

Envie `kind` e os ids do título: um id do IMDb (`tt...`) ou do TMDB do filme, ou da **série** no caso de um episódio, com `season` e `episode` na numeração do TMDB:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv",
 "kind": "movie", "ids": {"tmdb": 10378}, "media_info": { "...": "ffprobe's output" }}
```

**O que você deve ver.** O filme é **Big Buck Bunny (2008)** com a arte do Plex, não importa como o arquivo se chame. O rex não lê nada dos nomes: o que você envia é o que aparece. [rex com o seu próprio app](any-source.md) explica tudo em detalhes, inclusive os episódios.

## Legendas {#subtitles}

**O que faz.** Oferece arquivos de legenda que ficam ao lado de um vídeo como as legendas dele. As pessoas escolhem, baixam ou gravam na imagem, como fazem com uma legenda enviada.

```json
"subtitles": [{"path": "films/Big Buck/film.en.srt", "language": "en", "size": 82}]
```

| Campo | Significado |
|---|---|
| `path` | Onde o arquivo está no seu addon, assim como o de um vídeo. A extensão define o formato: `srt`, `ass`, `ssa`, `smi`, `txt` ou `psb` |
| `language` | `en` ou `eng`, como você souber. O rex não lê o idioma pelo nome do arquivo |
| `forced`, `hearing_impaired` | `true` para marcar assim |
| `size` | Tamanho em bytes. O rex só lê o arquivo de novo quando o caminho é novo ou o tamanho mudou |

**O que você deve ver.** O vídeo lista uma legenda **English (SRT External)**. Se você deixar `subtitles` de fora, o que você enviou antes é mantido; `[]` remove as suas (uma legenda enviada ou baixada continua lá). Um arquivo que o rex não consegue ler é deixado de fora e registrado no log, e o vídeo continua sendo aceito.

## Trailers e outros extras {#trailers-and-other-extras}

**O que faz.** Coloca um trailer, um featurette ou uma cena deletada embaixo do seu filme ou série, em **Extras**, em vez de transformá-lo em um título próprio.

```json
{"id": "films/Big Buck/trailer.mp4", "path": "films/Big Buck/trailer.mp4",
 "kind": "extra", "extra_type": "trailer", "media_info": { "...": "ffprobe's output" }}
```

Um extra pertence ao título dos outros vídeos do seu `release` (por padrão, a pasta dele). `extra_type` pode ser `trailer`, `deleted`, `featurette`, `behindthescenes`, `interview`, `scene`, `short`, `opening`, `ending` ou `other`. O rex nunca decide que um vídeo é um extra pelo nome ou pela pasta: só `kind: "extra"` faz isso.

**O que você deve ver.** A página do filme mostra o trailer em Extras, e a biblioteca não lista esse vídeo.

## Capítulos {#chapters}

**O que faz.** Permite pular entre capítulos no player.

Execute `ffprobe` com `-show_chapters` também, e envie a saída como está:

```bash
ffprobe -v error -print_format json -show_format -show_streams -show_chapters film.mkv
```

**O que você deve ver.** Os capítulos do vídeo, com seus nomes e horários. Para adicionar capítulos a vídeos que o rex já tem, envie os probes deles novamente com `-show_chapters` no próximo snapshot.

## Coleções e playlists {#collections-and-playlists}

**O que faz.** Agrupa títulos em coleções da sua biblioteca, e músicas ou vídeos em playlists, criadas e mantidas atualizadas pelo seu addon.

```json
"collections": ["Summer 2026"],
"playlists": {"Road trip": 1}
```

| Field | Meaning |
|---|---|
| `collections` | As coleções em que o título está, pelo nome. Cada uma é criada na primeira vez que um título a menciona |
| `playlists` | As playlists em que o arquivo está, pelo título, com a posição dele em cada uma a partir de 1. Cada uma é uma playlist do dono do servidor, de áudio quando a primeira música é uma faixa e de vídeo caso contrário |

As alterações das pessoas são mantidas: um título que alguém tirou de uma coleção continua fora, uma música que alguém adicionou à sua playlist mantém a posição, e uma playlist que alguém renomeou continua sendo dela. Deixar o campo de fora mantém o que você enviou antes; `[]` (ou `{}` para playlists) tira o arquivo de tudo em que o seu addon o colocou.

**O que você deve ver.** A aba Collections da biblioteca lista **Summer 2026**; Playlists lista **Road trip**, na sua ordem.

## Imagens de artistas {#artist-pictures}

**O que faz.** Mostra as suas imagens dos artistas que o seu addon de música envia, mesmo para os artistas que o Plex conhece e teria a própria imagem.

Registre com `"artwork": "source"` e envie a imagem em cada faixa:

```json
"display": {"artist": {"title": "Radiohead", "poster": "http://127.0.0.1:9982/music/Radiohead/artist.jpg"}}
```

Sem `artwork: "source"`, um artista que o Plex conhece mantém a imagem do Plex, e `display.artist` só aparece para os artistas que o Plex não conhece. De qualquer forma, uma imagem que alguém escolheu ou enviou em um app do Plex continua valendo.

## Bibliotecas grandes: envie as sondagens uma vez {#big-libraries-send-probes-once}

**O que faz.** Permite que um snapshot de milhares de vídeos envie quase nenhuma saída do `ffprobe`, então fica pequeno e rápido.

Envie `probe`, um texto curto seu que muda sempre que o probe do vídeo mudar (um hash da saída do `ffprobe` funciona). Quando o rex já tiver um vídeo com esse `probe`, envie apenas o `probe`, sem `media_info`:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv", "kind": "movie", "ids": {"tmdb": 10378}, "probe": "v1"}
```

O rex responde `"unchanged": 1`. Quando ele não tem esse `probe` (um vídeo novo, ou um cujo probe mudou), ele não muda nada e pede o item:

```json
{"created": 0, "updated": 0, "held": 0, "unchanged": 0, "wants": ["films/Big Buck/film.mkv"]}
```

Envie esses itens de novo com o `media_info`. Um snapshot conta um item desejado como enviado, então ele nunca é removido por causa disso. Confira se o seu rex aceita: a resposta do [registro](addons.md#step-2-register-with-rex) lista `"features": ["probe_digest"]`.

## O que as pessoas corrigiram: Fix Match {#what-people-fixed-fix-match}

**O que faz.** Informa ao seu addon quais dos vídeos dele alguém associou manualmente em um app do Plex (Fix Match), para que ele possa enviá-los corretamente a partir de então.

```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/matches
```

```json
{"size": 1, "matches": [{"release": "films/Mystery Reel", "ids": {"tmdb": 45745, "imdb": "tt1727587", "tvdb": 9413}, "kind": "movie", "matched_at": 1793751999}]}
```

Cada entrada é um `release` (uma pasta, a menos que você envie `release`) e os ids do filme ou série com que ele foi associado. O rex mantém a associação independentemente do que você enviar depois, então nada quebra se você ignorar isso. Ler esse dado permite que seu addon envie `kind` e `ids` por conta própria e lembre da correção caso as linhas do rex sejam reconstruídas. Sem nada associado, a resposta é `{"size": 0}`.

## Removendo seu addon {#removing-your-addon}

**O que faz.** Tira o seu addon e tudo o que ele enviou do rex, sem mexer nos arquivos dele.

São duas requisições: a primeira mostra quanto seria removido e gera um link válido por cinco minutos; a segunda remove de fato.

```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon
# {"confirm": "/rex/sources/myaddon/confirm/eae4...", "items": 4, "expires_in": 300}
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon/confirm/eae4...
# {"deleted": true, "removed": 4}
```

O histórico de exibição vai junto com as linhas. Registrar e enviar de novo depois começa do zero, com linhas novas. Para **substituir** um addon por uma versão nova, mantenha o nome, os ids e o primeiro segmento dos caminhos dele: a nova versão então atualiza as mesmas linhas. O rex nunca apaga bibliotecas; se quiser que sumam, apague-as em um app do Plex.

## Quem pode enviar para o rex {#who-may-send-to-rex}

rex's feed (`/rex/sources` e `/rex/feed`) não exige token. Ele só responde a programas na própria máquina do rex, na sua rede doméstica (`192.168.x.x`, `10.x.x.x`, `172.16-31.x.x` e endereços IPv6 privados) e no Tailscale (`100.64-127.x.x`). Para qualquer outra pessoa, ele simplesmente não existe, mesmo depois de você encaminhar a porta do rex para o rex-direct ou liberar o acesso por IPv6. Um reverse proxy na máquina do rex acessa o feed como um programa local, então bloqueie `/rex/` ali se você colocar um proxy na frente do rex.
