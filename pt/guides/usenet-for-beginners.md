# Usenet para iniciantes: o que comprar e como funciona com o zurg {#usenet-for-beginners-what-to-buy-and-how-it-fits-with-zurg}

Para fazer streaming de Usenet com o zurg, você precisa de uma conta de **provedor de Usenet**, que guarda os arquivos, e de **arquivos NZB**, que dizem onde está cada release. Um **indexador** é um site de busca de NZBs, mas você não precisa comprar um: a aba **Usenet** do DMM encontra NZBs para qualquer filme ou série. Depois disso, o zurg reproduz o release direto do seu provedor, sem baixar nada antes.

## As três peças {#the-three-pieces}

| Peça | O que é | Você paga por isso? |
|---|---|---|
| Provider, ou news server | O serviço que guarda os posts. Você recebe um endereço de servidor, um usuário, uma senha e um número de conexões. O zurg lê dele. | Sim. É a única coisa que você precisa comprar. |
| NZB | Um arquivo pequeno que lista as partes de um lançamento, do mesmo jeito que um arquivo `.torrent` faz para torrents. | Não. |
| Indexer | Um site de busca que gera NZBs. Sonarr, Radarr e Prowlarr pesquisam em um deles. | Opcional. |

Um lançamento no Usenet é postado como milhares de pequenas partes. O NZB lista todas elas, o seu provider as entrega, e o zurg as junta de novo no vídeo que o seu player pede.

## O que você precisa {#what-you-need}

1. **Um patrocínio do zurg.** O Usenet está nas builds noturnas do zurg, que vêm com um [patrocínio](sponsorship.md). O zurg público e gratuito funciona só com Real-Debrid.
2. **Uma conta de provedor de Usenet.** Dois números importam na hora de comparar planos:
   - **Retention**: quantos dias para trás o servidor guarda as postagens. Filmes e séries mais antigos precisam de mais.
   - **Connections**: quantas conexões o plano permite ao mesmo tempo. O zurg lê nesse número, então coloque no config o número real do seu plano.
3. **NZBs.** Salve pela aba Usenet do DMM, pegue no seu próprio indexador, ou deixe o Sonarr, o Radarr ou o zurg encontrarem.

Você não precisa de:

- **Um cliente de download** como SABnzbd ou NZBGet. O zurg transmite o release. Para Sonarr e Radarr, o zurg atua como o próprio SABnzbd: veja [Sonarr & Radarr para Usenet](../zurg/guides/sonarr-radarr.md).
- **Espaço em disco para releases inteiros.** O zurg baixa só as partes que cobrem o que está tocando. Um remux de 60 GB não precisa de 60 GB de disco.
- **Ferramentas para descompactar ou reparar.** O zurg reproduz de dentro dos conjuntos RAR e reconstrói as partes que faltam a partir dos arquivos PAR2 do próprio release.
- **Uma conta de debrid.** O Usenet funciona sozinho, ou junto com Real-Debrid e TorBox na mesma biblioteca do zurg.
- **Uma assinatura de indexador**, pelo menos para começar. Veja [a questão do indexador](#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers) abaixo.

Vale adicionar depois: **um segundo provedor.** Uma postagem que um provedor perdeu muitas vezes ainda está em outro. Quando um não tem uma parte, o zurg pede ao próximo. Com só um, o zurg precisa ler o release inteiro para reconstruir essa parte. Veja [um segundo servidor de notícias](../zurg/providers/usenet.md#a-second-news-server-is-worth-more-than-it-looks).

## Como o zurg faz isso {#how-zurg-plays-it}

1. Um NZB cai na pasta `nzbs/` do zurg. Você coloca ele lá, ou o Sonarr, o Radarr ou o próprio zurg faz isso.
2. Em um ou dois segundos o zurg lê o arquivo e lista o release na biblioteca dele, com o nome do NZB.
3. Você dá play no Plex, no Jellyfin ou no rex. O zurg busca do seu provedor as partes daquele trecho e entrega para o player. Se você pular para mais à frente, ele busca a partir daquele ponto.

Nada fica esperando um download terminar. Para configurar passo a passo, siga [Usenet com zurg](../zurg/guides/usenet.md). As configurações do provedor e os detalhes do Docker estão em [Provedor Usenet](../zurg/providers/usenet.md).

## Onde o DMM entra {#where-dmm-fits}

Toda página de filme e série no [DMM](https://debridmediamanager.com) tem uma aba **Usenet** ao lado de **Torrents**. Ela lista as releases de Usenet desse título vindas dos indexadores do DMM. Qualquer pessoa conectada ao DMM pode usar.

![Aba Usenet do DMM para Night of the Living Dead (1968), conectado com TorBox Pro](../assets/usenet-for-beginners/01-dmm-usenet-tab.webp)

O que cada linha pode fazer depende de com qual conta você está conectado:

| Botão | O que faz | Precisa de |
|---|---|---|
| O ícone de arquivo no final, ou **NZB** quando é o único botão | Salva o NZB, com o nome da release, sem a marca d'água do indexador. Coloque-o na pasta `nzbs/` do zurg. | Uma conexão no DMM |
| **Send** | O DMM baixa a release da Usenet e a adiciona à sua biblioteca do Real-Debrid. Você não precisa de conta de Usenet para isso. | Real-Debrid |
| **TorBox** | Envia o NZB para o TorBox, que baixa a release para você. | TorBox Pro, veja [TorBox no DMM](../dmm/torbox.md) |

Os apoiadores ganham mais duas opções:

- **O zurg busca nos indexadores do DMM por você.** Com sua chave de API do DMM no config do zurg como `dmm_api_key` e sem indexadores próprios, o zurg pesquisa nos do DMM quando busca sua [lista de desejados do DMM](../zurg/guides/dmm-wanted.md) ou sua [watchlist](../zurg/guides/acquisition.md).
- **DMM como indexador Newznab** para Sonarr, Radarr e Prowlarr. Configure na [página Newznab](https://debridmediamanager.com/newznab) do DMM. Cada chave tem direito a 30 buscas e 15 downloads de NZB por minuto, e 250 downloads por dia.

## Quando algo está errado {#when-something-is-wrong}

| O que você vê | O que fazer |
|---|---|
| Log do zurg: `Cannot reach the news server for nzb` | O zurg não consegue fazer login no seu provedor. Verifique o endereço do servidor, o usuário e a senha. A porta `563` vai com `tls: true`, a porta `119` com `tls: false`. |
| Log do zurg: `Usenet account <name> is not reachable` | Uma de várias contas falhou, e as outras continuam funcionando. Corrija os dados dessa conta. |
| Seu provedor recusa conexões, por exemplo `502 Too many connections` | O valor de `connections` na configuração do zurg é maior do que o seu plano permite, ou outro app está usando o mesmo login. Diminua para o número do seu plano. |
| Um release aparece como `indexer_download_48213` ou algo parecido | O zurg dá ao release o nome do arquivo NZB. Renomeie o `.nzb` para o nome do release. |
| Um arquivo dentro do release tem um nome aleatório | O post escondeu os nomes dos arquivos e o zurg não conseguiu recuperá-los. Escolha outro release. |
| Log do zurg: `rar: RAR4 header-encrypted archives are not supported` | O arquivo compactado desse release está em um formato antigo que o zurg não consegue abrir. Escolha outro release. |
| A reprodução trava ou um trecho toca sem som | Partes do release sumiram do seu provedor. O zurg reconstrói essas partes a partir dos arquivos PAR2, quando o post os tem. Um segundo provedor resolve a maioria desses casos. |
| DMM: **No Usenet results found.** | Os indexadores do DMM não têm nada para esse título. Tente a aba **Torrents** ou o seu próprio indexador. |

A tabela completa de solução de problemas está em [Usenet com zurg](../zurg/guides/usenet.md#troubleshooting). Ainda com dificuldade? Pergunte no fórum **zurg-support** no [Discord](https://discord.com/invite/7u4YjMThXP). [Pedindo ajuda](remote-help.md) explica o que incluir.

## Perguntas {#questions}

### Pode me explicar como funciona o sistema Usenet? {#can-someone-explain-the-usenet-system-to-me}

Usenet é uma rede de servidores de notícias que armazenam posts. Um release é postado em milhares de pequenos pedaços. Um provedor vende o acesso aos servidores dele, um NZB lista os pedaços de um release, e um indexador é onde você pesquisa NZBs. O zurg pega um NZB e reproduz o release direto do seu provedor.

### Preciso ter assinaturas vitalícias nos indexadores de Usenet? {#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers}

Não, você não precisa de nenhum indexador para começar: a aba Usenet do DMM encontra NZBs para você, e o zurg de um patrocinador pode pesquisar os indexadores do próprio DMM. Se quiser um indexador próprio para ter mais resultados, qualquer indexador Newznab funciona no zurg, no Sonarr e no Radarr, independentemente do plano que você escolher.

### Como os arquivos devem ser nomeados para Usenet? {#how-are-the-files-supposed-to-be-named-for-usenet}

Dê ao NZB o nome do release, como `Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb`. O zurg usa esse nome para a pasta do release, e é nele que o Plex e os outros apps se baseiam para identificar o conteúdo. Se um NZB tiver um nome dentro dele, o zurg usa esse nome no lugar. O botão NZB do DMM já salva o arquivo com o nome do release.

### O zurg faz Usenet? {#does-zurg-do-usenet}

Sim, nas compilações noturnas para patrocinadores. Informe os dados do seu provedor, coloque os NZBs em `nzbs/` e eles tocam. [Usenet com zurg](../zurg/guides/usenet.md) explica o passo a passo.

### O que é o TorBox NNTP? {#what-is-torbox-nntp}

TorBox tem dois recursos de Usenet no plano Pro. A página de preços mostra Usenet só no Pro (verificado em 14 de novembro de 2026).

- **Downloads de Usenet hospedados.** A TorBox baixa a release inteira para você e a entrega como qualquer outro download da TorBox. Envie NZBs pela aba Usenet do DMM ou pelo provider `torbox_nzb` do zurg. Você não precisa de login em servidor de notícias. Veja [TorBox hospedado de Usenet](../zurg/providers/torbox-nzb.md).
- **Um login em servidor de notícias (NNTP).** Use no zurg como qualquer outro provider. Ele permite 10 conexões. Medido em setembro de 2026, encontrou menos da biblioteca real do que outros três providers pagos, então funciona melhor como reserva. Veja [Servidor de notícias do TorBox](../zurg/providers/torbox-news-server.md).

### Posso usar uma conta de Usenet em dois lugares? {#can-i-use-one-usenet-account-in-two-places}

Melhor não. Dois apps usando o mesmo login compartilham as conexões dele e acabam se derrubando: o servidor pode fechar a conexão mais antiga para dar lugar à mais nova. Alguns provedores proíbem compartilhar a conta nos termos de uso. Dê a cada zurg a sua própria conta.
