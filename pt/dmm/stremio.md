# Use o DMM no Stremio com o DMM Cast {#use-dmm-in-stremio-with-dmm-cast}

DMM Cast é o addon Stremio do Debrid Media Manager. É assim que o DMM aparece no Stremio: você escolhe uma versão no DMM, aperta **Cast**, e o Stremio lista isso como um stream que toca da sua própria conta de debrid ou Easynews. Resumindo: entre no DMM, abra a página Cast do seu provedor, instale o addon no Stremio e depois aperte **Cast** em qualquer filme ou série.

Cast aqui se refere ao addon do DMM. Não é Chromecast nem espelhamento de tela.

## O que você precisa {#what-you-need}

- Um login no DMM com Real-Debrid, TorBox, AllDebrid, Premiumize, Offcloud, Debrid-Link ou Easynews.
- Stremio. O [Stremio Web](https://web.stremio.com) funciona sem uma conta do Stremio.

Não precisa de patrocínio.

## Configure {#set-it-up}

1. Faça login no [debridmediamanager.com](https://debridmediamanager.com) com seu provedor. O Easynews faz login em **Settings**.
2. Na página inicial do DMM, clique em **Cast for RD**, **Cast for TB** e assim por diante. Com várias contas conectadas, há uma única linha **Cast** com um botão por provedor. Cada provedor tem sua própria página de Cast:

   | Provedor | Página de Cast |
   |---|---|
   | Real-Debrid | [debridmediamanager.com/stremio](https://debridmediamanager.com/stremio) |
   | TorBox | [debridmediamanager.com/stremio-torbox](https://debridmediamanager.com/stremio-torbox) |
   | AllDebrid | [debridmediamanager.com/stremio-alldebrid](https://debridmediamanager.com/stremio-alldebrid) |
   | Premiumize | [debridmediamanager.com/stremio-premiumize](https://debridmediamanager.com/stremio-premiumize) |
   | Offcloud | [debridmediamanager.com/stremio-offcloud](https://debridmediamanager.com/stremio-offcloud) |
   | Debrid-Link | [debridmediamanager.com/stremio-debridlink](https://debridmediamanager.com/stremio-debridlink) |
   | Easynews | [debridmediamanager.com/stremio-easynews](https://debridmediamanager.com/stremio-easynews) |

   ![Página de Cast do DMM para Premiumize, com o endereço do addon borrado](../assets/dmm-stremio/01-dmm-cast-page.webp)

3. Clique em **Install (web)**. O Stremio Web abre com o addon. Clique em **Install** lá.

   ![Stremio Web pedindo para instalar o DMM Cast](../assets/dmm-stremio/02-stremio-install.webp)

   Para outro Stremio, copie o endereço mostrado embaixo dos botões e adicione-o lá. No Stremio Web, o caminho é **Addons** → **Add addon** → cole → **Add** → **Install**. O endereço é privado da sua conta: nunca compartilhe.

4. De volta ao DMM, pesquise um filme ou série e abra o título. Os lançamentos que seu provedor já tem ganham um botão **Cast**: **Cast (RD)**, **Cast (TB)**, **Cast (AD)**, **Cast (PM)**, **Cast (OC)** ou **Cast (DL)**. Clique nele. O DMM confirma com **Cast started in Stremio** (em uma série, **Casting succeeded.** e quantos episódios foram enviados) e tenta abrir o título no seu app do Stremio.

   ![Clicando em Cast (PM) no DMM](../assets/dmm-stremio/03-dmm-cast-button.webp)

5. Abra o título no Stremio. Seu cast aparece como **DMM Cast PM (Yours)** (RD, TB e assim por diante para os outros provedores). Clique nele para reproduzir.

   ![Stremio listando o cast como DMM Cast PM (Yours)](../assets/dmm-stremio/04-stremio-streams.webp)

## O que mais você tem no Stremio {#what-else-you-get-in-stremio}

- **DMM Cast PM ✨ · Cast a file inside a torrent** em todos os filmes e episódios. Ele abre esse título no DMM, para você escolher um release por lá.
- Até cinco streams extras de casts de outras pessoas e de releases que seu provedor já tem. Defina o número em **Other streams limit** na página Cast. Apoiadores podem aumentar para dez.
- Linhas no Board do Stremio: **DMM PM Movies** e **DMM PM TV Shows** trazem seus casts. **DMM PM Library** traz tudo que está na sua conta, e cada item abre com os arquivos. A Easynews não tem linha Library.
- Não quer as linhas? Instale o addon com **Without catalogs** → **Install (web)**. Os streams continuam aparecendo.
- **Manage Casted Links** na página Cast lista seus casts. Marque os que quer remover (ou clique em **Select All**) e depois em **Delete Selected** para tirá-los do Stremio.
- **Hide "Cast a file inside a torrent" option** na página Cast remove a linha ✨.

No Debrid-Link, o cast adiciona o release à sua conta. Um release que o Debrid-Link ainda não tem inicia um download de verdade e usa um dos seus 50 torrents do dia.

## Quando algo está errado {#when-something-is-wrong}

| O que você vê | O que fazer |
|---|---|
| Só aparece **DMM Cast PM ✨ · Cast a file inside a torrent** (RD, TB…), sem outros streams | Nada foi enviado para esse título ainda. Clique nessa linha: ela abre o título no DMM. Clique em **Cast** em um lançamento e depois abra o título no Stremio de novo. |
| **⚠️ DMM Cast · Set up DMM Cast for Premiumize again** (ou seu provedor) como único stream | O addon no Stremio não corresponde mais ao seu login no DMM. Clique nele para abrir sua página de Cast, faça login, depois remova o addon antigo do Stremio e instale de novo a partir dessa página. |
| **Real-Debrid Required. You must be logged in with Real-Debrid to use the Stremio Cast feature.** (ou TorBox, Easynews…) | Você não está logado nesse provedor no DMM, ou abriu a página de Cast de outro provedor. Clique em **Login with …**, ou use o botão **Cast for …** na página inicial do DMM. |
| **No episodes in this release on Premiumize** | O DMM não conseguiu associar os arquivos desse lançamento a episódios. Envie um lançamento diferente. |
| O endereço do addon colado na barra de pesquisa no topo do Stremio Web não faz nada | Essa barra serve só para pesquisar. Use **Addons** → **Add addon**. |

Travou? Pergunte no fórum **dmm-cast-support** no [Discord](https://discord.com/invite/7u4YjMThXP). [Obtendo ajuda](../guides/remote-help.md) explica o que incluir.

## Perguntas {#questions}

### Posso pesquisar o DMM no Stremio? {#can-i-search-dmm-in-stremio}

Não. O DMM Cast não adiciona busca ao Stremio, e a busca do Stremio não mostra nada dele. Pesquise em [debridmediamanager.com](https://debridmediamanager.com) e clique em **Cast**. A partir de um título que você já tem aberto no Stremio, a linha ✨ leva você até esse título no DMM.

### Funciona na minha TV, Fire TV ou celular? {#does-it-work-on-my-tv-fire-tv-or-phone}

Os elencos ficam salvos no DMM, não no dispositivo de onde você transmite. Todo Stremio que tiver o endereço do seu addon os lista. Transmita pelo celular ou pelo computador e, depois, escolha o stream **(Yours)** no Stremio onde você estiver assistindo.

### Quais provedores funcionam? {#which-providers-work}

Real-Debrid, TorBox, AllDebrid, Premiumize, Offcloud, Debrid-Link e Easynews. Cada um tem sua própria página de Cast e seu próprio addon. Instale um para cada conta que você quiser usar no Stremio.

### Por que o Stremio mostra só o Cast e nenhum stream? {#why-does-stremio-show-only-cast-and-no-stream}

Nenhum elenco foi adicionado para esse título ainda. Clique na linha ✨, adicione um lançamento no DMM e depois abra o título no Stremio novamente.

### Posso reproduzir toda a minha biblioteca debrid no Stremio? {#can-i-play-my-whole-debrid-library-in-stremio}

Sim. A linha **DMM Library** no Board do Stremio lista tudo que está na sua conta (não no Easynews). Abra um item para ver os arquivos dele.

### Preciso de um patrocínio? {#do-i-need-a-sponsorship}

Não. Para o DMM Cast, um patrocínio só aumenta o **Other streams limit** de cinco para dez. Pegue sua chave de API do DMM no [gatekeeper](https://gatekeeper.debridmediamanager.com/) e cole em **Settings** do DMM.
