# zurg+rex para Android e Google TV {#zurgrex-for-android-and-google-tv}

zurg+rex é um servidor Plex no seu celular. O zurg traz suas contas de debrid e Usenet, e o rex serve tudo para cada app do Plex da sua casa, com pôsteres, temporadas e progresso de exibição. Ele roda em celular, tablet, Android TV, Google TV ou Fire TV, sem precisar de computador.

Ele vem com um patrocínio. Não tem patrocínio? [rex para Android](../../rex/android.md) é gratuito e reproduz o que os addons dele trouxerem.

| O app | No app Plex | Em qualquer outro app Plex |
|---|---|---|
| ![Status no zurg+rex com a biblioteca pronta e o rex conectado ao Plex](../../assets/zurg/android-status.webp) | ![Big Buck Bunny na página dele no app Plex, servido pelo mesmo celular](../../assets/zurg/android-plex.webp) | ![A mesma biblioteca de filmes abertos no app Plezy](../../assets/zurg/android-plezy.webp) |

## Antes de começar {#before-you-start}

| Você precisa | Por quê |
|---|---|
| Um dispositivo com Android 8.0 ou mais recente | Celular, tablet, Android TV, Google TV ou Fire TV. Usenet precisa de um dispositivo de 64 bits |
| Um apoio com sua conta do GitHub vinculada | O app e o motor dele são baixados do repositório do apoiador. Apoie e vincule o GitHub no [gatekeeper](https://gatekeeper.debridmediamanager.com/) |
| Uma conta de debrid ou uma conta de Usenet | O que o zurg traz para dentro. NZBs hospedados no TorBox (`torbox_nzb`) não estão disponíveis no Android |
| Uma conta do Plex | O rex aparece nos apps do Plex conectados a ela. Uma conta gratuita já basta |
| Sua chave de API do DMM, obtida no gatekeeper (opcional) | Com ela, mais títulos recebem nome e pôster |

## Passo 1. Baixe {#step-1-download-it}

No seu dispositivo, abra a [página de download](https://zurg.debridmediamanager.com/pt/download.html#android), conectado ao GitHub com a sua conta de apoiador, e escolha o arquivo para o processador dele:

| Seu dispositivo | Arquivo |
|---|---|
| A maioria dos celulares, tablets e TV boxes (64 bits) | `android-arm64-v8a.apk` |
| Celulares de 32 bits mais antigos e TV sticks | `android-armeabi-v7a.apk` |
| Chromebooks e emuladores | `android-x86_64.apk` |

Um único arquivo funciona tanto em celulares quanto em TVs.

**O GitHub diz 404?** A conta com a qual você está conectado ainda não tem acesso de apoiador. Se você acabou de apoiar, [aceite o convite](https://github.com/debridmediamanager/zurg/invitations) primeiro; os convites são enviados em até 15 minutos.

## Passo 2. Instale {#step-2-install-it}

Abra o arquivo baixado e permita a instalação pelo app que o abriu. O Android ou o Play Protect podem pedir para você confirmar.

**O que você deve ver.** **zurg+rex** na sua lista de apps.

## Passo 3. Entre no GitHub e instale o motor {#step-3-sign-in-to-github-and-install-the-engine}

Abra o app. Ele mostra **Welcome to zurg+rex.**

1. Pressione **Sign in with GitHub**. O app mostra um código: pressione **Open GitHub**, digite o código e aprove. O GitHub pede acesso `repo` porque as versões de patrocinadores são privadas.
2. **Instale o engine.** O engine é o próprio zurg e rex, guardado em um pacote separado para que ele seja atualizado independentemente do app. Pressione **Install**. O Android pergunta antes de instalar: permita.

**O que você deve ver.** **Add your providers.**

## Passo 4. Adicione seus provedores {#step-4-add-your-providers}

1. Clique em **Add an account** e escolha o provedor.
2. Para uma conta de debrid, cole o token dela em **Provider token**. Para Usenet, preencha **NNTP server**, **Port**, **Username**, **Password** e **Connections**.
3. Clique em **Test account** e depois em **Add provider**.

Adicione quantas contas você tiver; o **Account name** diferencia duas contas do mesmo provedor. O limite de conexões de uma conta Usenet conta todos os outros apps e dispositivos que a usam.

## Passo 5. Inicie sua biblioteca {#step-5-start-your-library}

1. Escolha **Phone**, **Tablet**, **TV box** ou **TV stick**. As opções menores usam menos memória e caches menores.
2. Permita as notificações e deixe o app rodar em segundo plano. Ative **Start after reboot** se este dispositivo deve sempre servir sua biblioteca.
3. Pressione **Start my library**.

**O que você deve ver.** **Status** mostra **Ready for your players** e conta seus lançamentos. O primeiro carregamento de uma conta grande pode levar vários minutos.

## Passo 6. Entre no Plex {#step-6-sign-in-to-plex}

On **Status**, em **rex for the Plex apps**, pressione **Sign in to Plex**.

- **Em um celular ou tablet**, seu navegador abre a página de login do Plex. Faça o login lá.
- **Em uma TV**, o app mostra **On any device, go to plex.tv/link and enter** seguido de um código. Digite o código no seu celular ou computador.

Use a conta com a qual seus apps do Plex estão conectados.

**O que você deve ver.** **Ready for the Plex app**, com um botão **Open Plex** quando o Plex estiver neste dispositivo.

## Passo 7. Assista em um app do Plex {#step-7-watch-in-a-plex-app}

Abra qualquer app do Plex logado na mesma conta: neste dispositivo, na sua TV, em outro celular ou em um computador de casa. Seu servidor aparece com o nome deste dispositivo, com as bibliotecas **Debrid Movies** e **Debrid TV**. Aperte play.

rex converte o que o player não consegue reproduzir, usando o codificador de vídeo do próprio dispositivo.

## Obtenha mais títulos chamados {#get-more-titles-named}

Abra **Settings**, **Library** e cole sua chave de API do DMM no campo **Dmm api key**, depois salve. O zurg então pergunta ao DMM o que é cada arquivo. Sem a chave, o zurg descobre pelo nome do lançamento, e menos títulos recebem nome e pôster.

Um título que ainda pareça errado pode ser corrigido em um app do Plex: abra o menu **⋯** dele e escolha **Fix Match**.

O campo está nas nightlies a partir de 14 de novembro de 2026. Em uma versão mais antiga, adicione `dmm_api_key: YOUR_DMM_API_KEY` em **Settings**, **Advanced**. A mesma chave lê sua [lista de desejos do DMM](dmm-wanted.md).

## Complementos {#addons}

Complementos trazem mais para assistir no rex, além da sua biblioteca. Abra **Addons**: o complemento do Internet Archive já vem instalado e adiciona filmes de domínio público, e o repositório [rex-addons](https://github.com/debridmediamanager/rex-addons) já está na lista. Adicione outro repositório pelo link dele, abra-o e instale o que ele oferece.

Cada complemento informa quais sites ele pode acessar, e uma atualização que passe a acessar sites novos pede sua permissão antes. Instale complementos somente de pessoas em quem você confia. Um complemento que precisa da sua conta mostra um código para você digitar no site dele; o login que ele recebe fica guardado apenas neste dispositivo. **Log** mostra o que um complemento fez recentemente. Remover um complemento tira apenas os títulos dele.

## Outros players neste dispositivo {#other-players-on-this-device}

Você não precisa de um app do Plex para assistir.

- **Library** navega pelas suas pastas e reproduz um arquivo no player que você escolher. **More** oferece outro player e as ações do release: repair, rename, tags, show all files e delete. Elas valem para o release inteiro, e delete pede confirmação antes e o apaga da sua conta no provedor.
- O app **Files** e os seletores de documentos mostram a mesma biblioteca na raiz do zurg. Abra seu player uma vez e termine a configuração dele antes de escolhê-lo pelo Files.
- Players WebDAV como VLC, Kodi e Nova usam `http://127.0.0.1:9999/dav/` como fonte. **Status** mostra o endereço se você tiver mudado a porta.

Em uma TV, mova-se com o D-pad e Select, volte com Back, e abra as ações de um release com Menu ou **More**. Selecione um campo de texto para digitar nele e pressione Back para seguir em frente.

## Compartilhe com outros players em casa {#share-with-other-players-at-home}

Apps Plex em casa não precisam de mais nada: eles encontram o rex sozinhos. Para um player WebDAV em outro dispositivo, abra **Settings**, **Connection** e ative **Expose on local network**. O zurg cria um nome de usuário e uma senha e mostra o endereço para digitar nesse player.

Use isso em uma rede em que você confia: a senha viaja sem criptografia. Essa opção fica desligada até você ativá-la.

## Mantenha rodando {#keep-it-running}

- A notificação mostra o estado do servidor e tem o botão **Stop**. Um bloco nas Configurações Rápidas também inicia e para o servidor.
- Alguns celulares fecham apps em segundo plano de qualquer jeito. [Don't kill my app](https://dontkillmyapp.com/) explica o que o seu precisa.
- **Updates** verifica se há um novo app e um novo engine; eles são atualizados separadamente. Se um novo nightly der problema no seu dispositivo, pressione **Show engine versions** e instale o que funcionou. Pare sua biblioteca em **Status** antes.
- **Settings** tem **Create backup** e **Restore backup**. Um backup guarda suas senhas e tokens, então mantenha-o em sigilo. Pare sua biblioteca antes de restaurar.
- Desligue o rex em **Settings**, **Connection**, **rex for the Plex apps**. Aí o zurg para de alimentá-lo.

## O que o app envia e para onde {#what-the-app-sends-and-where}

zurg+rex não tem anúncios nem analytics. Esta é a lista completa de tudo o que sai do seu dispositivo:

| Onde | O quê | Quando |
|---|---|---|
| GitHub | Seu login, depois pedidos pelas releases dos patrocinadores | Quando você faz login e quando **Updates** verifica atualizações |
| Seus provedores | Seu token de conta ou seu login da Usenet, e pedidos pela sua biblioteca e pelos seus arquivos | Enquanto sua biblioteca estiver rodando |
| debridmediamanager.com | Os nomes das suas releases, para descobrir o que cada uma é, com a sua chave de API do DMM se você tiver informado uma | Enquanto sua biblioteca estiver rodando com o rex ativo |
| plex.tv e o serviço de metadados do Plex | Um pedido de código de login; depois, o nome do servidor, o endereço e os ids dos seus títulos, para buscar pôsteres e descrições | Quando você faz login no Plex, e enquanto o rex roda logado |
| debridmediamanager.com (rex-direct) | O identificador do rex, o token de servidor que o Plex deu a ele, seus endereços IP e porta, para que os apps do Plex consigam acessá-lo por HTTPS | Depois de fazer login no Plex e, depois disso, a cada 6 horas |
| Os sites de cada addon e os repositórios que você adiciona | O que o addon pede | Quando um addon sincroniza ou quando um título é reproduzido |
| logs.debridmediamanager.com | Versões, modelo do dispositivo, os logs do app e do engine e sua configuração, com chaves, senhas e tokens substituídos por `[redacted]` | Só quando você pressiona **Send** em **Send logs to support**, depois de ver tudo. Excluído após 7 dias |

Seu token do GitHub é armazenado criptografado no dispositivo. Desinstalar o app apaga tudo o que ele guardou.

## Limites {#limits}

- **O aparelho é o servidor.** Mantenha ele ligado, conectado e na tomada. Converter vídeo é lento em uma caixinha barata.
- **Ele funciona em casa.** Fora de casa, os apps do Plex precisam de um endereço HTTPS que chegue até o aparelho, o que exige um port forward no seu roteador. Veja [Use it outside your home](../../rex/with-zurg.md#use-it-outside-your-home-optional).
- **Usenet exige Android de 64 bits.** Um aparelho de 32 bits roda apenas bibliotecas de debrid.
- **Não está no Google Play.** Ele se atualiza por dentro do app, em **Updates**.

## Solução de problemas {#troubleshooting}

| O que você vê | O que fazer |
|---|---|
| O GitHub responde 404 na página de download | Entre no GitHub com sua conta de patrocinador e [aceite o convite](https://github.com/debridmediamanager/zurg/invitations). Ainda não é patrocinador: [gatekeeper](https://gatekeeper.debridmediamanager.com/) |
| **No engine is installed. zurg needs one before it can serve your library.** | Toque em **Install an engine** e permita que o Android a instale |
| **No engine is available in the sponsor releases for this device yet.** | A nightly mais recente não tem um engine para o seu processador. Pergunte no suporte |
| **This is a 32-bit device. Debrid libraries are supported; Usenet needs 64-bit Android.** | Adicione uma conta debrid, ou use um dispositivo 64-bit para Usenet |
| **The Plex code expired. Ask for a new one.** | Toque em **Sign in to Plex** de novo e digite o novo código em até 10 minutos |
| O servidor não aparece no app do Plex | Entre no app do Plex com a conta que você usou no Passo 6, e mantenha os dois dispositivos na mesma rede doméstica |
| Os títulos mostram um nome de arquivo e sem pôster | Digite sua chave de API do DMM (veja [Get more titles named](#get-more-titles-named)), ou use **Fix Match** em um app do Plex |
| **Needs an update** em um addon | Esta versão do app não consegue mais rodar essa cópia do addon. Atualize o repositório dele e toque em **Update**. Os títulos continuam disponíveis enquanto isso |
| Ele para quando a tela é desligada | Permita o uso em segundo plano de novo e veja [Don't kill my app](https://dontkillmyapp.com/) |
| Uma atualização deixa o app sem engine | Instale um engine em **Updates** uma vez. Seus provedores e configurações são mantidos |

Se o suporte pedir logs, abra **Logs** e toque em **Send logs to support**. Você vê tudo antes de qualquer coisa ser enviada, depois toque em **Send** e poste o código que você receber.

Travado? Pergunte no fórum **zurg-support** no [Discord](https://discord.com/invite/7u4YjMThXP).
