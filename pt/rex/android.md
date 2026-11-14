# rex para Android {#rex-for-android}

rex é um servidor de mídia para os apps do Plex que não possui nenhum arquivo. O rex para Android roda em um celular, tablet, Android TV, Google TV ou Fire TV, sem precisar de computador. Os apps do Plex nos seus dispositivos encontram o rex como qualquer outro servidor Plex e reproduzem a partir dele.

O que ele reproduz vem de **addons**. Ele começa com os filmes de domínio público do Internet Archive. Outros addons, como os seus addons do Stremio, YouTube e Spotify, são instalados dentro do app depois que você adiciona o repositório deles.

O rex para Android é gratuito. Quer colocar suas contas de debrid e Usenet nele também? O zurg+rex, um servidor Plex no seu celular com o zurg embutido, vem com um patrocínio: veja [zurg+rex para Android](../zurg/guides/android.md).

## Antes de começar {#before-you-start}

| Você precisa | Por quê |
|---|---|
| Um dispositivo com Android 8.0 ou mais recente | Celular, tablet, Android TV, Google TV ou Fire TV. Fire TVs com Vega OS, como o Fire TV Stick 4K Select, não rodam apps Android |
| Uma conta no Plex | O rex aparece nos apps do Plex em que você estiver conectado com ela. Uma conta gratuita basta |
| Um app do Plex no dispositivo em que você assiste | Plex para Android, Android TV, iPhone, uma smart TV, Plex Web, Plexamp |

## Passo 1. Obtenha o app {#step-1-get-the-app}

| Forma | Ideal para |
|---|---|
| Google Play | Celulares, tablets, Android TV e Google TV. Em breve |
| Amazon Appstore | Fire TV e tablets Fire. Em breve |
| [Obtainium](#with-obtainium) | Celulares e tablets. As atualizações chegam sozinhas |
| [Downloader](#with-downloader-on-fire-tv) | Fire TV e TV boxes |
| [O arquivo do GitHub](#the-file-from-github) | Qualquer dispositivo. Você instala as atualizações por conta própria |

**As formas não se misturam.** Google Play, Amazon Appstore e o arquivo do GitHub (que o Obtainium e o Downloader também instalam) são assinados de maneiras diferentes, então um não consegue atualizar o outro. Para trocar, desinstale o rex e refaça os Passos 2 e 3.

**Elas começam com addons diferentes.** O arquivo do GitHub começa com o repositório [rex-addons](https://github.com/debridmediamanager/rex-addons) já adicionado. As versões da loja começam só com o addon do Internet Archive; adicione o rex-addons por conta própria (veja [Complementos](#addons)) se quiser.

### Com o Obtainium {#with-obtainium}

[Obtainium](https://obtainium.imranr.dev/) instala apps do GitHub e mantém eles atualizados.

1. Instale o Obtainium.
2. No mesmo dispositivo, abra [rex.debridmediamanager.com/obtainium](https://rex.debridmediamanager.com/pt/obtainium). O Obtainium abre e pede para **Import app**. Toque em **Continue**.
3. Toque em **rex** e depois em **Install**. O Obtainium escolhe o arquivo para o processador do seu dispositivo.
4. Na primeira vez, o Android diz que o Obtainium não tem permissão para instalar apps. Ative **Allow from this source** e volte.
5. Toque em **Install**. Se o Play Protect mostrar **App scan recommended**, toque em **Scan app** e depois em **Install**.

Quando uma nova versão sair, o Obtainium mostra **Update** ao lado do rex.

### Com o Downloader na Fire TV {#with-downloader-on-fire-tv}

1. Na Fire TV, instale o **Downloader** da AFTVnews pela Appstore.
2. Abra o app, selecione a caixa de endereço e digite `rex.debridmediamanager.com/tv`. Pressione **Next**. Ele vai baixar o `rex-android-armeabi-v7a.apk`.
3. Pressione **Install**. Na primeira vez, a Fire TV abre **Developer options** no lugar. Selecione **Install unknown apps** e depois o **Downloader**, até aparecer **ON**. Pressione Voltar duas vezes e pressione **Install** de novo.
4. Pressione **Install** e depois **Open**.

Para atualizar, repita os passos 2 a 4. Um código curto do Downloader está chegando.

### O arquivo do GitHub {#the-file-from-github}

No dispositivo, baixe o arquivo para o processador dele. Cada link sempre aponta para a versão mais nova:

| Seu dispositivo | Download |
|---|---|
| A maioria dos celulares, tablets e TV boxes (64 bits) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| Fire TV e TV boxes mais antigos ou mais baratos de 32 bits | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| Emuladores no PC | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

Todas as versões e suas mudanças estão em [the releases page](https://github.com/debridmediamanager/rex-android/releases). Não tem certeza? Tente `arm64-v8a` primeiro. Um único arquivo funciona tanto em celulares quanto em TVs.

Abra o arquivo baixado. O Android diz que **não tem permissão para instalar apps desconhecidos a partir desta fonte**. Toque em **Settings**, ative **Allow from this source**, volte e toque em **Install**.

Para atualizar, instale o novo arquivo por cima do antigo. O rex inicia de novo sozinho e seu login e seus addons continuam.

**O que você deve ver.** **rex** na sua lista de apps.

## Passo 2. Inicie o rex {#step-2-start-rex}

**rex**. Abra o **rex**. A primeira tela diz **Welcome to rex.**

1. Toque em **Allow notifications** e depois em **Allow**. O rex roda em segundo plano com uma notificação que você pode usar para pará-lo.
2. Toque em **Let rex keep running in the background**. Na lista que abrir, escolha **rex** e selecione **Don't optimize**. Em versões mais novas do Android, é **Allow background usage** e depois **Unrestricted**. Volte para o rex. Os dois botões agora começam com um ✓.
3. **Name** é o nome que os apps do Plex mostram para este servidor. Mude se quiser.
4. Deixe **Port** em `32400`. Se outro servidor Plex já estiver rodando neste dispositivo, o rex mostra **Another app here already uses this port, maybe a Plex server. Try 32500.** Digite `32500`.
5. Toque em **Start rex**.

**O que você deve ver.** **2 / 2** e **Sign in to Plex.**

| A primeira tela | A página do filme no app Plex (Passo 4) |
|---|---|
| ![A primeira tela do rex para Android, com os campos de nome e porta e o botão Start rex](../assets/rex/android-setup.webp) | ![Um filme mudo de 1916 do Internet Archive na sua página no Plex para Android](../assets/rex/android-plex-film.webp) |

## Passo 3. Entre no Plex {#step-3-sign-in-to-plex}

Pressione **Sign in to Plex**. O rex mostra um código: **On any phone or computer, go to plex.tv/link and enter** it.

- **On a phone or tablet** o seu navegador também abre uma página do Plex que diz **rex for Android would like to sign in to your Plex account**. Entre por lá.
- **On a TV** acesse [plex.tv/link](https://plex.tv/link) no seu celular ou computador, entre na sua conta e digite o código.

Use a conta com a qual seus apps do Plex estão conectados. Você pode pressionar **Skip for now** e entrar depois em **Status**.

![rex for Android on a TV showing the code to enter at plex.tv/link](../assets/rex/android-tv-signin.webp)

**O que você deve ver.** **Signed in. rex shows up in the Plex apps as** o nome do seu servidor. Pressione **Done**. **Status** mostra **RUNNING** e **Ready for the Plex apps.**

## Passo 4. Assista em um app do Plex {#step-4-watch-in-a-plex-app}

Abra qualquer app do Plex conectado à mesma conta. Se o Plex estiver neste dispositivo, **Status** tem um botão **Open Plex**.

No Plex para Android, abra **Libraries**, depois **All Libraries** e então **Movies**, sob o nome do seu servidor. Os outros apps do Plex também listam a biblioteca sob o nome do servidor.

A primeira sincronização do Internet Archive demora um pouco: cerca de meia hora no nosso dispositivo de teste, enquanto o rex verifica cada filme. **Status** mostra **Syncing** até terminar e depois a contagem, como **Ready · 97 titles**. Dê play em qualquer filme.

![O app do Plex numa TV tocando um curta de Chaplin de 1914 vindo do rex na mesma TV](../assets/rex/android-tv-playing.webp)

## Complementos {#addons}

**Addons** lista o que você instalou. Cada um mostra seus títulos e quando foi sincronizado pela última vez. Os botões são **Sync now**, **Settings**, **Log** e **Remove**; no celular, deslize a linha de botões para o lado para ver todos. A chave **Enabled** desativa um addon sem removê-lo.

Os addons vêm de **repositories**: repositórios git que guardam addons. O addon Internet Archive já vem instalado. Para mais, adicione [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons) (veja **Add a repository** abaixo), que oferece:

| Addon | O que traz |
|---|---|
| Stremio addons | Os catálogos de filmes e séries dos seus addons do Stremio, reproduzidos a partir dos streams que seus addons de stream fornecem |
| YouTube | Suas playlists do YouTube. Você entra com um código |
| Spotify | Sua biblioteca do Spotify como música para Plex e Plexamp. Precisa do addon do YouTube, com login feito |

**Instale um.** Em **Repositories**, toque em **Addons** ao lado de um repositório e depois em **Install** embaixo do addon. O rex mostra quais sites ele consegue acessar, pergunta mais uma vez e começa a sincronizar.

**Entre na conta.** Um addon que precisa da sua conta diz **Sign in to start.** Toque no botão **Sign in** dele: acesse a página indicada em qualquer dispositivo e digite o código que aparece.

**Adicione um repositório.** Em **Add a repository**, digite o link dele (`github.com/user/repo` já basta) e toque em **Add**. Instale apenas de pessoas em quem você confia. Para criar seu próprio addon, veja [rex-addons](https://github.com/debridmediamanager/rex-addons).

## Assista em outros dispositivos em casa {#watch-on-other-devices-at-home}

Todo app do Plex conectado na mesma conta encontra o rex na sua rede doméstica pelo nome: sua TV, outro celular, o Plex Web em um computador. **Status** mostra o endereço do rex em casa, como `http://192.168.1.20:32400`.

Para deixar a família assistir com as próprias contas do Plex, veja [Compartilhe o rex com família e amigos](sharing.md).

## Mantenha rodando {#keep-it-running}

- rex roda enquanto o dispositivo estiver ligado. A **Stop** na notificação para o rex; em **Status** há **Start**, **Stop** e **Restart**.
- Em **Settings**, ative **Start when this device turns on**. Caso contrário, abra o rex e toque em **Start** depois de reiniciar.
- Alguns celulares ainda encerram apps em segundo plano. [Don't kill my app](https://dontkillmyapp.com/) explica o que o seu precisa.
- Para renomear o servidor, abra **Settings**, **General** em um app do Plex e altere **Friendly name**.

## Limites {#limits}

- **Funciona em casa.** Fora de casa, os apps do Plex precisam de um endereço HTTPS que chegue ao aparelho, o que exige um port forward no seu roteador apontando para ele. Veja [Use it outside your home](any-source.md#use-it-outside-your-home-optional).
- **O aparelho é o servidor.** Mantenha-o ligado, no Wi-Fi ou Ethernet, e na tomada. Converter vídeo para um player que não consegue tocar um arquivo usa o hardware do próprio aparelho e pode ser lento em uma caixa mais barata.
- **Só o que os addons trazem.** Ele não tem uma biblioteca de arquivos no próprio aparelho.

## Solução de problemas {#troubleshooting}

| O que você vê | O que fazer |
|---|---|
| **App not installed as app isn't compatible with your phone.** | Você escolheu o arquivo errado para o processador. Tente o outro da tabela no Passo 1 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | Digite `32500` como a porta |
| **Use a number from 1024 to 65535** | A porta precisa ser um número nessa faixa |
| O servidor não aparece no app Plex | Entre no app Plex com a mesma conta que você usou no Passo 3, e deixe os dois dispositivos na mesma rede doméstica |
| A biblioteca está vazia | A primeira sincronização ainda está rodando: espere até **Status** mostrar um número de títulos |
| **Sign in needed** em um addon | Pressione o botão **Sign in** dele e digite o código |
| **Needs an update** em um addon | Esta versão do app não consegue mais rodar essa cópia do addon. Atualize o repositório dele e pressione **Update**. Os títulos continuam disponíveis enquanto isso |
| **That isn't a repository link. Try github.com/user/repo.** | Digite o link do repositório, como `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | O link está errado ou o repositório é privado. Confira no navegador |
| rex para quando a tela é desligada | Refaça a configuração de segundo plano do Passo 2, e veja [Don't kill my app](https://dontkillmyapp.com/) |

**Logs** mostra o que o rex e os addons disseram recentemente, com chaves e senhas ocultas. Se o suporte pedir os logs, pressione **Send logs to support**: você vê tudo antes de qualquer coisa ser enviada, depois pressione **Send** e poste o código que você receber.

O que o app envia e para onde está na sua [política de privacidade](android-privacy.md).

Ficou travado? Pergunte no fórum **rex-support** no [Discord](https://discord.com/invite/7u4YjMThXP).
