# O que cada peça faz {#what-each-piece-does}

Os nomes não dizem o que cada um faz, então aqui vai uma linha para cada um. Para descobrir quais você precisa, use [Escolha sua configuração](choose-your-setup.md).

## Os três projetos {#the-three-projects}

| Nome | O que faz |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Um site para encontrar releases e adicioná-los à sua conta debrid. Ele também pesquisa em Usenet e Easynews. Gratuito |
| [zurg](../zurg/index.md) | Todas as contas debrid e Usenet em uma única pasta. Plex, Jellyfin, Emby, Infuse e rex leem essa pasta como um drive normal. Para patrocinadores |
| [rex](../rex/index.md) | Um servidor de mídia que não possui nenhum arquivo. Suas fontes informam o que elas têm e todo app do Plex reproduz. Gratuito para uso pessoal |

## Assistindo direto pelo DMM {#watching-straight-from-dmm}

Nenhum servidor é necessário para nenhum desses.

| Nome | O que faz |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio/) | Um addon do Stremio que reproduz lançamentos da sua conta debrid ou Easynews |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Navegue, pesquise e reproduza da sua conta debrid ou Easynews dentro do Kodi |
| DMM Watch | Um botão no DMM que abre um arquivo no seu próprio player, como VLC ou Infuse |
| [DMM Music](https://debridmediamanager.com/music/) | Reproduza e baixe músicas do Real-Debrid no seu navegador |

## Alimentando o rex {#feeding-rex}

| Nome | O que faz |
|---|---|
| [rex-stremio](../rex/stremio.md) | Transforma seus addons do Stremio em bibliotecas do rex, para tocarem nos apps do Plex. Gratuito |
| [addons do rex](../rex/addons.md) | Pequenos programas que dão ao rex algo para tocar: YouTube, Spotify, IPTV, vídeos caseiros ou o que você escrever |
| [rex para Android](../rex/android.md) | rex e seus addons em um celular Android ou TV box, sem computador. Gratuito. Para sua biblioteca de debrid e Usenet, os apoiadores usam zurg+rex |
| [zurg+rex para Android](../zurg/guides/android.md) | Um servidor Plex no seu celular: zurg e rex juntos em um único dispositivo Android. Para apoiadores |

## Dentro do Jellyfin e do Emby {#inside-jellyfin-and-emby}

| Nome | O que faz |
|---|---|
| [RD, AD, TB, PM, OC e DL zurg](https://debridmediamanager.com/jellyfin) | Um plugin para cada provedor de debrid. Sua biblioteca de debrid aparece no Jellyfin ou no [Emby](https://debridmediamanager.com/emby) sem precisar de nenhum app zurg nem montagem. Para apoiadores |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Um plugin para Jellyfin que transmite NZBs pela sua própria conta Usenet. Para apoiadores |

## Adicionando títulos para você {#adding-titles-for-you}

| Nome | O que faz |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Aperte **Want** no DMM e seu zurg busca o conteúdo, incluindo os episódios novos. Para patrocinadores |
| [Seerr pelo DMM](../dmm/seerr.md) | Pedidos da família no Seerr vão para a sua lista Wanted. Para patrocinadores |
| [Torznab e Newznab](https://debridmediamanager.com/torznab) | DMM como indexador para Sonarr, Radarr e Prowlarr, com o zurg como cliente de download. Para patrocinadores |
| [Addon Stremio do zurg](../zurg/guides/stremio.md) | Busca no Usenet quando você aperta play no Stremio e transmite pelo zurg |
| [`__magic__`](../zurg/guides/magic.md) | Uma pasta do zurg que você organiza sozinho, ou deixa o Sonarr e o Radarr organizarem |

## O resto do DMM {#the-rest-of-dmm}

| Nome | O que faz |
|---|---|
| [Quadro de pedidos](https://debridmediamanager.com/requests) | Peça um lançamento que a Real-Debrid não tem. Outro usuário do DMM o move para a sua biblioteca. Atender pedidos dá benefícios de patrocinador do DMM |
| [Listas de hashes](https://debridmediamanager.com/hashlists) | Compartilhe uma lista de lançamentos para que outras pessoas possam adicioná-los às próprias contas |
| [Extensão para navegador](../dmm/safari.md) | Adiciona botões do DMM em sites de filmes e séries e ao lado de links magnet |
| [Página de patrocínio](https://gatekeeper.debridmediamanager.com) | Onde você patrocina e vincula seu apoio no Patreon ou no GitHub Sponsors. [O que um patrocínio te dá](sponsorship.md) |

## Palavras que você vai ver nos guias {#words-youll-see-in-the-guides}

| Palavra | O que significa |
|---|---|
| Provedor debrid | Um serviço pago que baixa torrents para você e deixa você transmiti-los: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | O provedor já tem o release, então ele toca na hora |
| Usenet | Outro lugar para pegar releases. Você precisa de uma conta de provedor Usenet, ou do TorBox Pro para fazer isso por você |
| NZB | Um arquivinho que diz onde está um release Usenet, como um arquivo torrent faz para os torrents |
| Indexer | Um site de busca de releases. O Sonarr e o Radarr usam um para encontrar coisas |
| WebDAV | Uma forma de compartilhar arquivos pela web. Infuse, Kodi e muitos players de TV conseguem abri-lo |
| Mount | Faz a pasta do zurg parecer um drive local, para que Plex, Jellyfin ou Emby consigam escanear |
| Plex Media Server vs Plex apps | O servidor guarda sua biblioteca. Os apps na sua TV e no celular reproduzem ela. O rex substitui o servidor, não os apps |
