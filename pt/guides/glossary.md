# O que cada peça faz {#what-each-piece-does}

The nomes não dizem o que cada coisa faz, então aqui vai uma linha para cada uma. Tudo que não está marcado como **For sponsors** é gratuito. Para descobrir quais você precisa, use [Choose your setup](choose-your-setup.md).

## Os três projetos {#the-three-projects}

| Nome | O que faz |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Um site para encontrar releases e adicioná-los à sua conta debrid. Também pesquisa no Usenet e no Easynews |
| [zurg](../zurg/index.md) | Todas as contas debrid e o Usenet como uma única biblioteca. O Plex, o Jellyfin e o Emby leem como uma pasta, o Infuse e o Kodi via WebDAV, e o rex acessa diretamente. As versões atuais são para apoiadores |
| [rex](../rex/index.md) | Um servidor de mídia para os apps do Plex que não tem arquivos próprios. O zurg ou um addon informa o que existe. Gratuito para uso pessoal |

## Assistindo direto pelo DMM {#watching-straight-from-dmm}

Nenhum servidor é necessário para nenhum deles.

| Nome | O que faz |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | Um addon do Stremio que reproduz lançamentos da sua conta de debrid ou Easynews. Ele também funciona no Nuvio |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Navegue, pesquise e reproduza a partir da sua conta de debrid ou Easynews dentro do Kodi |
| DMM Watch | Um botão no DMM que abre um arquivo no seu próprio player, como VLC ou Infuse |

## Alimentando o rex {#feeding-rex}

| Nome | O que faz |
|---|---|
| [rex-stremio](../rex/stremio.md) | Transforma seus addons do Stremio em bibliotecas do rex, para tocarem nos apps do Plex |
| [rex addons](../rex/addons.md) | Pequenos programas que dão algo para o rex tocar: YouTube, Spotify, IPTV, vídeos caseiros ou o que você quiser escrever |
| [rex-live-sports](../rex/live-tv.md) | Um addon do rex que coloca canais de esportes ao vivo e um guia na Live TV dos apps do Plex |
| [rex-direct](../rex/any-source.md#rex-direct) | Dá ao seu rex um endereço seguro próprio, para que os apps do Plex consigam acessá-lo fora de casa |
| [rex for Android](../rex/android.md) | rex e seus addons em um celular ou TV box Android, sem computador |
| [zurg+rex for Android](../zurg/guides/android.md) | Um servidor Plex no seu celular: zurg e rex juntos em um único dispositivo Android, com sua biblioteca de debrid e Usenet. Para patrocinadores |

## Dentro do Jellyfin e do Emby {#inside-jellyfin-and-emby}

| Nome | O que faz |
|---|---|
| [Plugins de debrid](https://debridmediamanager.com/jellyfin) (RD zurg, AD zurg, TB zurg, PM zurg, OC zurg, DL zurg) | Um plugin para cada provedor de debrid: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud e Debrid-Link. Sua biblioteca de debrid aparece no Jellyfin ou no [Emby](https://debridmediamanager.com/emby) sem precisar de nenhum app zurg nem de montagem. Para apoiadores |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Um plugin do Jellyfin que faz streaming de NZBs pela sua própria conta de Usenet. Para apoiadores |

## Adicionando títulos para você {#adding-titles-for-you}

| Nome | O que faz |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Aperte **Want** no DMM e o seu zurg busca, inclusive os episódios novos. Para patrocinadores |
| [Seerr através do DMM](../dmm/seerr.md) | Pedidos da família no Seerr vão para a sua lista Wanted. Para patrocinadores |
| [Torznab](https://debridmediamanager.com/torznab) e [Newznab](https://debridmediamanager.com/newznab) | DMM como indexador para Sonarr, Radarr e Prowlarr. Para patrocinadores |
| zurg como cliente de download | O zurg responde ao Sonarr e ao Radarr como qBittorrent para [torrents](../zurg/guides/sonarr-radarr-torrents.md) e como SABnzbd para [Usenet](../zurg/guides/sonarr-radarr.md), então você não precisa rodar nenhum dos dois. Para patrocinadores |
| [Addon Stremio do zurg](../zurg/guides/stremio.md) | Busca no Usenet quando você aperta play no Stremio e transmite pelo zurg. Para patrocinadores |
| [`__magic__`](../zurg/guides/magic.md) | Uma pasta do zurg que você monta por conta própria, ou deixa o Sonarr e o Radarr montarem. Para patrocinadores |

## O resto do DMM {#the-rest-of-dmm}

| Nome | O que faz |
|---|---|
| Aba Usenet | Envia um release de Usenet para sua biblioteca do Real-Debrid, sem precisar de conta em Usenet. Os patrocinadores vão primeiro e ganham uma cota diária maior |
| [Quadro de pedidos](https://debridmediamanager.com/requests) | Peça um release que o Real-Debrid não tem. Outro usuário do DMM move para a sua biblioteca. Preencha 10 pedidos e ganhe 7 dias dos benefícios de patrocinador do DMM |
| [Listas de hashes](https://debridmediamanager.com/hashlists) | Compartilhe uma lista de releases para que outros possam adicioná-los às contas deles |
| Extensão do navegador | Adiciona botões do DMM em sites de filmes e séries e ao lado de links magnet. Para [Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm), [Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/) e [Safari](../dmm/safari.md) |
| [gatekeeper](https://gatekeeper.debridmediamanager.com) | O site de patrocínio. Seja patrocinador por lá, vincule sua assinatura do Patreon ou do GitHub Sponsors e pegue sua chave de API do DMM. [O que um patrocínio te dá](sponsorship.md) |

## Palavras que você vai ver nos guias {#words-youll-see-in-the-guides}

| Termo | O que significa |
|---|---|
| Release | Uma cópia de um filme, episódio ou temporada como alguém publicou. Um título geralmente tem várias, em qualidades diferentes |
| Debrid provider | Um serviço pago que baixa torrents para você e deixa você fazer streaming deles: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | O provedor já tem o release, então ele toca na hora |
| Usenet | Outro lugar para pegar releases. Use sua própria conta Usenet, deixe o TorBox Pro ou o Easynews fazer isso, ou faça o DMM enviar um resultado para o Real-Debrid |
| Easynews | Um serviço Usenet pago com busca própria que toca os arquivos direto pela web |
| NZB | Um arquivinho que diz onde está um release Usenet, como o arquivo torrent faz para torrents |
| Indexer | Um site de busca de releases. O Sonarr e o Radarr usam um para encontrar coisas |
| Sonarr, Radarr e Prowlarr | Apps que buscam títulos para você: Sonarr para séries, Radarr para filmes. O Prowlarr mantém os indexers deles num lugar só |
| Seerr | Um site de pedidos para família e amigos. Overseerr e Jellyseerr funcionam do mesmo jeito |
| Stremio, Nuvio e Kodi | Apps de player de mídia. Addons dão a eles coisas para tocar. O Nuvio aceita addons do Stremio |
| DMM API key | Uma chave de patrocinador do gatekeeper. Cole onde o guia pedir e mantenha em sigilo, como uma senha |
| Nightly | A build mais nova do zurg ou do rex, feita todas as noites. As nightlies do zurg são para patrocinadores |
| WebDAV | Uma forma de compartilhar arquivos pela web. Infuse, Kodi e muitos players de TV conseguem abri-lo |
| Mount | Faz a pasta do zurg parecer um drive local, para que Plex, Jellyfin ou Emby possam escaneá-la |
| rclone | A ferramenta que o zurg usa para fazer o mount. A configuração do zurg já a instala para você |
| `.strm` | Um arquivinho que guarda um link no lugar do vídeo, para players como o Kodi |
| Source | Qualquer coisa que diz ao rex o que ele tem e entrega os arquivos: zurg, rex-stremio ou um addon |
| Claim | Colocar o rex numa conta do Plex, para que ele mostre títulos e pôsteres e os apps do Plex consigam encontrá-lo |
| Plex Media Server vs Plex apps | O servidor guarda sua biblioteca. Os apps na sua TV e no celular é que tocam. O rex substitui o servidor, não os apps |
