# O que um patrocínio te dá {#what-a-sponsorship-gives-you}

DMM é gratuito. Os apoios pagam pela hospedagem e mantêm o zurg e o rex funcionando. Esta página lista todos os benefícios e onde configurá-los.

Apoie pelo [gatekeeper](https://gatekeeper.debridmediamanager.com/). Entre lá para ver sua chave de API do DMM. **Open DMM with this key** vincula a chave nesse navegador. Adicione a mesma chave nos outros serviços que pedirem. Mantenha-a em segredo, porque ela funciona como uma senha.

Os benefícios acompanham o apoio. Quando ele acaba, o DMM deixa de oferecê-los na próxima requisição. Os plugins do Jellyfin e do Emby que você já instalou continuam funcionando, mas novos downloads e atualizações param. O gatekeeper revoga o acesso ao zurg e o cargo no Discord na próxima verificação. **Reset key** desativa a chave antiga em todos os lugares de uma vez.

## zurg

| O que você recebe | Onde |
|---|---|
| Builds noturnos com todos os provedores e Usenet, mais a imagem Docker | [configuração do zurg](../zurg/setup/index.md) depois que você aceitar o convite do GitHub |
| O app Android do zurg+rex, um servidor Plex no seu celular | [guia do Android](../zurg/guides/android.md) depois que você aceitar o convite do GitHub |
| O código-fonte completo do zurg | O repositório privado no GitHub |
| Todo lançamento com nome de rex e Plex | `dmm_api_key` na [configuração do zurg](../zurg/reference/config.md) |
| Detalhes de mídia do DMM sem ler o arquivo antes, e verificações de idioma antes de um lançamento ser adicionado | Nada além de `dmm_api_key` |
| As pastas `__magic__` organizadas automaticamente quando ativadas | [\_\_magic\_\_](../zurg/guides/magic.md) |
| Sua lista de desejados do DMM buscada pelo zurg | [lista de desejados do DMM](../zurg/guides/dmm-wanted.md) |
| Os indexadores Usenet e de torrent do DMM pesquisados quando você não tem nenhum seu | `dmm_api_key` mais um provedor Usenet ou uma conta de debrid que consiga adicionar torrents |
| Lançamentos escolhidos pelo idioma original de cada título | `original` em [idiomas de áudio e legendas](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) |
| Um filme desejado que nenhum indexador tem é transmitido do upload oficial dele no YouTube | [Transmitindo um filme do YouTube](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

Os recursos de `dmm_api_key` precisam de um build noturno do zurg. O build público gratuito não inclui esses recursos.

## DMM

| O que você ganha | Onde |
|---|---|
| Uma lista de desejados que o zurg busca com episódios novos e upgrades. Preencha pelo DMM, Kodi, listas do Trakt e MDBList ou um backup do Radarr ou Sonarr | [Lista de desejados do DMM](../zurg/guides/dmm-wanted.md) |
| Pedidos do Seerr, Overseerr ou Jellyseerr caem na sua lista de desejados | [Seerr pelo DMM](../dmm/seerr.md) |
| Qualquer resultado do Easynews enviado ao seu zurg com um clique | Os resultados do Easynews em uma página de filme ou série no DMM |
| DMM como indexador Newznab para Usenet | [página Newznab](https://debridmediamanager.com/newznab) do DMM |
| DMM como indexador Torznab com feeds somente em cache para Real-Debrid, AllDebrid, Debrid-Link, TorBox, Premiumize e Offcloud | [página Torznab](https://debridmediamanager.com/torznab) do DMM. TorBox, Premiumize e Offcloud também precisam da chave do serviço vinculado |
| Sete plugins do Jellyfin para bibliotecas de debrid e Usenet e seis plugins do Emby para bibliotecas de debrid, sem nada montado | Páginas do DMM para [Jellyfin](https://debridmediamanager.com/jellyfin) e [Emby](https://debridmediamanager.com/emby) |
| Dez streams extras por título no Stremio Cast e no Kodi, em vez de cinco | Configurações do DMM para Real-Debrid, TorBox e AllDebrid; a página Cast de cada provedor para os outros |
| Uploads de NZB passam na frente, com 2 TB de Usenet por dia em vez de 300 GB | Aba Usenet do DMM |
| A mesma prioridade e cota para o Sonarr e o Radarr | Sua chave de API do DMM como Password na [página SABnzbd](https://debridmediamanager.com/sabnzbd) do DMM |
| Três uploads de torrent para o Real-Debrid ao mesmo tempo, em vez de um | Os botões de upload nos resultados de busca e na biblioteca do DMM |
| Adicionar ao DMM Wanted e uma pasta Wanted dentro do Kodi | Pareie o Kodi na [página Kodi](https://debridmediamanager.com/kodi) do DMM |
| A API do DMM para nomes de release, checagens de cache, detalhes de mídia e metadados | [Documentação da API](https://debridmediamanager.com/api-docs) |

## rex

rex é gratuito e não precisa de patrocínio, inclusive no Android: [rex for Android](https://github.com/debridmediamanager/rex-android) roda o rex e seus addons em um celular ou TV box. Com uma chave, o [rex-stremio](../rex/stremio.md) adiciona streams debrid de torrents que o DMM já tem uma verificação pronta, em segundos, em vez de verificar cada um deles. Cole a chave no campo **DMM** do rex-stremio. Ele compartilha as verificações de arquivos de torrent com o DMM, a menos que você desative isso.

## Ajuda {#help}

| O que você ganha | Onde |
|---|---|
| Ajuda remota gratuita com zurg e rex no seu próprio terminal enquanto você assiste | [Obtendo ajuda](remote-help.md) |
| O cargo Sponsor no Discord | Conecte o Discord no gatekeeper |

## Ganhe sem pagar {#earn-it-without-paying}

Atenda pedidos no [quadro de pedidos](https://debridmediamanager.com/requests) do DMM. A cada 10 pedidos atendidos, você ganha 7 dias dos benefícios do DMM listados acima. Só uma atendida por pessoa por dia conta. Vincule a chave de uma conta gatekeeper gratuita no quadro para resgatá-los.

O tempo ganho libera a tabela do DMM acima. Ele não libera o zurg nightly, o código-fonte, o cargo no Discord, a ajuda remota nem o app para Android. Esses precisam de um patrocínio pago. Os recursos `dmm_api_key` também precisam de um nightly.

Com dúvidas? Pergunte no fórum **dmm-support** no [Discord](https://discord.com/invite/7u4YjMThXP).
