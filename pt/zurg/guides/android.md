# zurg+rex para Android e Google TV {#zurgrex-for-android-and-google-tv}

O aplicativo Android roda um mecanismo zurg no próprio dispositivo, e o rex fica ao lado dele: o seu próprio servidor Plex no celular ou na TV box, para os apps do Plex. Um único app funciona em celulares, tablets, Android TV e Google TV. É necessário Android 8.0 ou mais recente. O Fire TV pode instalar o mesmo APK por sideload. Use um player WebDAV quando ele não tiver um app de Arquivos do sistema. Usenet exige Android de 64 bits; os NZBs hospedados no TorBox (`torbox_nzb`) não estão disponíveis no Android.

## Instalar e configurar {#install-and-set-up}

[Baixe um APK](https://zurg.debridmediamanager.com/pt/download.html#android) no lançamento noturno (nightly) do repositório privado de patrocinadores. Escolha `arm64-v8a` para a maioria dos celulares e TV boxes, `armeabi-v7a` para dispositivos antigos de 32 bits ou `x86_64` para um emulador ou Chromebook compatível. Todo APK inclui as interfaces de celular e de TV.

O app não contém o zurg em si. Depois de entrar com sua conta do GitHub, você instala o motor (engine) pelo próprio app. É preciso ter uma conta de patrocinador. Patrocine no [gatekeeper](https://gatekeeper.debridmediamanager.com/) para dar acesso à sua conta do GitHub. O Setup te guia nesse processo.

Permita a instalação a partir do app que você usou para abrir o APK. O Android ou o Play Protect podem pedir para você confirmar a instalação de fonte externa. O ID do aplicativo é `com.debridmediamanager.zurg`. As atualizações precisam manter a mesma assinatura de lançamento.

1. Abra o zurg, entre com sua conta do GitHub e depois instale uma versão do engine. O app não consegue iniciar uma biblioteca enquanto um engine não estiver instalado.
2. Adicione as contas dos provedores e teste as credenciais. Os nomes das contas diferenciam várias contas no mesmo provedor. Os limites de conexão Usenet valem para todos os outros consumidores daquela conta.
3. Escolha Phone, Tablet, TV box ou TV stick. Os perfis definem a meta de memória do engine e o tamanho do cache em disco. Uma meta de heap do Go não é um limite fixo de RSS.
4. Permita notificações e a execução em segundo plano. Ative o início após reinicialização se este dispositivo deve servir a biblioteca o tempo todo.
5. Inicie a biblioteca. O primeiro carregamento de uma conta grande pode levar vários minutos. A notificação e a tela Status mostram quando os diretórios estiverem prontos.

## Assistir neste dispositivo {#watch-on-this-device}

Use Library para navegar pelas pastas e reproduzir um arquivo. More oferece outro player ou um URI de documento do Android. O player escolhido pode virar o player preferido.
Os gerenciadores de arquivos e seletores de documentos exibem a mesma biblioteca na raiz de armazenamento do zurg.
Os arquivos são transmitidos com acesso aleatório; eles não são baixados por completo antes.
Abra seu player uma vez e termine a configuração dele antes de escolhê-lo no Files.

Para players WebDAV, adicione `http://127.0.0.1:9999/dav/` como fonte. Use a porta exibida em Status se você tiver alterado. VLC, Kodi e Nova conseguem navegar por uma fonte WebDAV; players que aceitam apenas URLs individuais podem ser abertos a partir da Library. Na TV, use o D-pad e Select para mover e acionar os controles, Back para voltar, e Menu ou More para ações de release. Selecione um campo de texto para editá-lo e pressione Back para voltar à navegação. Um toque longo também abre More no celular.

Repair, rename, tags, show all files e delete atuam sobre o release inteiro ao qual o arquivo pertence. A exclusão pede confirmação e apaga do seu conta no provedor.
MediaInfo usa o ffprobe incluído e abre os detalhes de vídeo, áudio e legendas resultantes no dashboard. Não é preciso instalar nenhuma ferramenta de mídia separada.

## Assistir nos apps do Plex {#watch-in-the-plex-apps}

From the nightly of 10 November 2026 the app also runs rex (64-bit devices in
that nightly, every supported device from the 11 November nightly), a media
server for the Plex apps, and points zurg at it, so your library appears
in the official Plex apps and in Plezy, on this device and on others in your
home. Once your library is running, Status shows **rex for the Plex apps**:
choose **Sign in to Plex** and approve the sign-in (on a TV, enter the code at
plex.tv/link). The server appears in Plex under this device's name. rex converts
what a player cannot play with the device's hardware encoder. Turn rex off in
Settings, Connection; zurg then stops feeding it.

## Compartilhar pela rede local {#share-over-the-local-network}

Em Configurações, ative **Expose on local network**. O zurg gera as credenciais e mostra o endereço WebDAV da rede local (LAN) do dispositivo. Insira esse endereço e essas credenciais em um player no outro dispositivo. Mantenha o host Android ligado e em funcionamento.
A autenticação HTTP básica não criptografa o tráfego; use apenas uma rede local confiável.
O loopback é o padrão. Os intents do player nunca contêm a senha do seu servidor.

## Configurações, backups e atualizações {#settings-backups-and-updates}

Configurações cobre conexão, provedores, biblioteca, reparo, recursos e logs.
Advanced aceita YAML bruto e pede para o engine instalado validá-lo antes de
salvar. Settings não tem um campo para a sua chave de API do DMM: adicione
`dmm_api_key: YOUR_DMM_API_KEY` em Advanced para a [lista de desejos do DMM](dmm-wanted.md)
e para a nomeação de lançamentos do DMM. Ao salvar uma configuração em execução, o app pergunta antes de reiniciar o servidor.
Web dashboard abre o painel local para as configurações de integração com o desktop.

Logs inclui a saída recente do engine e as últimas 200 linhas do supervisor.
Logs compartilhados ocultam os segredos e URLs configurados. Backups contêm credenciais e
o estado da biblioteca, então salve-os em local privado. Pare o zurg antes de restaurar. O Android
recusa links de backup e arquivos especiais, e restaura primeiro para o loopback.

Updates verifica o repositório privado de patrocinadores. O login de dispositivo do GitHub pede o escopo `repo`,
porque os assets das releases são privados. Os tokens do GitHub são criptografados
com preferências protegidas pelo Android Keystore. Também há suporte a um token informado manualmente, com acesso de leitura
ao repositório. Se o Android não conseguir mais descriptografar um login salvo, Updates pede
que você faça login de novo e preserva a configuração da sua biblioteca. Atualizações baixadas precisam corresponder ao
application ID e à chave de assinatura, e ter um version code mais novo. O instalador do Android
pede confirmação antes de substituir o app.

Atualizar a partir de uma build que trazia o próprio engine deixa o app sem um. Instale um engine
pelo Updates uma vez, e seus provedores e configurações de biblioteca são mantidos intactos.

O app e o engine são atualizados separadamente. Updates lista as versões do engine entre as
30 releases mais recentes do repositório de patrocinadores, marca a que você tem e instala qualquer
uma delas. Se um novo nightly se comportar mal no seu aparelho, instale a versão que funcionou para você. Pare a sua biblioteca em Status antes de trocar o engine. O app só
executa um pacote de engine assinado com a chave dele, e verifica isso de novo
a cada início.

A notificação persistente tem uma ação Stop. Um tile de Quick Settings também
inicia ou para o servidor. A isenção de bateria ajuda com os limites de ociosidade do Android; gerenciadores de tarefas específicos de fabricantes podem exigir configurações adicionais, veja [Don't kill my app](https://dontkillmyapp.com/).
