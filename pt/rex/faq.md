# Perguntas sobre o rex {#rex-questions}

Respostas curtas para o que as pessoas perguntam antes de instalar o rex, e logo depois. Cada resposta linka para o guia que tem os detalhes.

## Antes de instalar {#before-you-install}

### O que é o rex? {#what-is-rex}

Um servidor de mídia para os apps oficiais do Plex que não guarda nenhum arquivo. Seus apps veem mais um servidor Plex, com pôsteres, temporadas, histórico de exibição e Continue Assistindo. Uma **fonte** informa ao rex o que existe na biblioteca e entrega cada arquivo. O rex faz o streaming quando você aperta play. Nada é baixado antes.

Ele é um servidor próprio. Não é um plugin do Plex Media Server e não precisa de um. Rode-o junto com o Plex se quiser usar os dois. [Instale o rex](any-source.md#step-1-install-rex) explica os nomes e [Migre do Plex para o rex](from-plex.md) cobre as duas rotas.

### Quanto custa? {#what-does-it-cost}

rex é gratuito para uso pessoal, sem plano pago. O código-fonte é público sob a licença PolyForm Noncommercial. Uso comercial não é permitido. Todas as builds ficam públicas em [GitHub Releases](https://github.com/debridmediamanager/rex/releases), exceto a build para Android, que vem somente dentro do app [zurg+rex Android](../zurg/guides/android.md), exclusivo para sponsors, um servidor Plex no seu celular.

Algumas coisas ao redor podem ter custo:

| | |
|---|---|
| [rex-stremio](stremio.md), seu próprio app ou um addon como fonte | Gratuito |
| zurg nightly, uma fonte para uma biblioteca debrid ou Usenet | Um benefício para [sponsors do DMM](https://gatekeeper.debridmediamanager.com) |
| Uma API key do DMM, para os matches exatos do DMM no zurg | Opcional, também obtida ao apoiar o DMM |
| Imagem Docker do rex | Gratuita e pública, para Linux: [rex in Docker](any-source.md#run-rex-in-docker) |

### Minha conta do Plex corre risco? {#is-my-plex-account-at-risk}

rex não é feito pela Plex e a Plex pode tomar medidas contra uma conta que o registre. Use uma **conta gratuita nova da Plex** criada só para o rex e depois compartilhe com a sua conta. Seu histórico, seus amigos e o Plex Pass ficam na sua conta principal. [Adicione à sua conta Plex](any-source.md#step-3-add-it-to-a-plex-account) mostra o passo a passo. Use o rex por sua conta e risco.

### Quais apps do Plex funcionam? {#which-plex-apps-work}

| App | Testado |
|---|---|
| Plex Web (app.plex.tv) | O que mais foi testado: navegação, reprodução, conversão, legendas, música, Live TV e reprodução fora de casa com contas gratuitas nos dois lados |
| Plex para Android (celular) | Num Pixel 6: reprodução, conversão e [download do seu provedor](direct-download.md). Num emulador: música e Live TV |
| Plexamp | Num emulador Android: navegação e reprodução de uma biblioteca de música, com fotos de artistas e playlists |
| Plex para iOS | Num iPad: reprodução e conversão. Dolby Vision tem um bug do app (veja abaixo) |
| Plex para Apple TV | Reprodução, incluindo canais ao vivo numa biblioteca |
| Plex Desktop | Plex para Mac: reprodução e conversão |
| Plezy | Num Pixel 6: reprodução e download do seu provedor |
| Plex HTPC | Ainda não testado |
| Plex para Android TV, NVIDIA Shield, Google TV | Ainda não testado |
| Plex para Roku | Ainda não testado |
| Apps de Smart TV (Samsung, LG e outras) | Ainda não testado |
| Infuse | Ainda não testado |

Fora de casa, só o Plex Web foi testado.

### Ele reproduz 4K, HDR e Dolby Vision? {#does-it-play-4k-hdr-and-dolby-vision}

Sim. Os arquivos tocam na qualidade original: o rex entrega o arquivo ao app do jeito que ele está, e o app decide o que consegue exibir. Quando um app não consegue tocar um arquivo do jeito que ele está, o rex o converte, desde que o FFmpeg esteja configurado ([Converting video](any-source.md#converting-video-optional)). Uma conversão transforma HDR e Dolby Vision em uma imagem padrão (Settings, Transcoder, **Enable HDR tone mapping**, ativado por padrão), na placa de vídeo sempre que possível. Com o runtime OpenCL da Intel instalado, uma máquina Intel pequena (um J4105) converte 4K HDR10 e Dolby Vision perfil 5 para 1080p em aproximadamente tempo real. Sem o FFmpeg, um arquivo que o app não consegue tocar mostra "This server is not powerful enough to convert video". Quando todos os títulos mostram isso em todos os dispositivos, o FFmpeg não é a solução: veja [Nothing plays](#nothing-plays-or-every-app-says-it-is-not-powerful-enough).

**Plex para iOS e Dolby Vision.** O Plex para iOS 2026.20.0 fica em 0:00 quando toca um arquivo Dolby Vision do jeito que ele está. Um Plex Media Server real servindo o mesmo arquivo trava da mesma forma, então o problema está no app. Arquivos 4K HDR10 e SDR tocam normalmente.

### Preciso do Plex Pass? {#do-i-need-plex-pass}

Não. O rex diz aos apps do Plex que a conta em que ele está registrado tem Plex Pass, então reproduzir fora de casa e converter vídeo funcionam com contas gratuitas. Reproduzir fora de casa foi testado no Plex Web com conta gratuita dos dois lados; outros apps não foram testados fora de casa. Edições de filmes, o Dashboard, Downloads, pular intro e créditos e o restante de [Movie and TV capabilities](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities) também funcionam. Um app ainda pode aplicar as próprias regras.

### Posso baixar para assistir offline? {#can-i-download-for-offline-viewing}

Os **Downloads** dos apps do Plex estão disponíveis. O rex prepara o download na própria máquina, como arquivo original ou convertido com FFmpeg, e guarda na pasta ao lado de `rex.db` até o app buscá-lo. A conta em que o rex está registrado sempre pode baixar; quem você compartilha precisa ter downloads permitidos no compartilhamento dele ([Compartilhe o rex](sharing.md#what-each-person-may-see-and-do)). O app ainda pode aplicar as próprias regras. Um download convertido deixa de fora as legendas de texto. Salvar um download no celular e assistir offline ainda não foi testado.

### Várias pessoas podem usar, cada uma com o próprio histórico? {#can-several-people-use-it-each-with-their-own-history}

Sim. Cada pessoa com quem você compartilhar o rex entra com a própria conta e tem o próprio histórico de assistidos, Continue assistindo, avaliações e playlists. Cada uma pode copiar o histórico de um servidor Plex antigo ([Traga seu histórico de exibição](import-watched.md)). [Compartilhe o rex com família e amigos](sharing.md) tem os passos, incluindo os usuários gerenciados para crianças.

### Que hardware ele precisa? {#what-hardware-does-it-need}

Uma máquina que fique ligada, rodando Linux (amd64 ou arm64, glibc 2.35 ou mais recente, ou seja, Ubuntu 22.04 ou superior), macOS (Intel ou Apple Silicon) ou Windows 64 bits; ou o app zurg+rex para Android/Google TV, que roda zurg e rex juntos (exclusivo para patrocinadores; veja o [guia do Android](../zurg/guides/android.md)). Esse app só funciona em dispositivos de 64 bits até o nightly de 11 de novembro de 2026.

**Memória:** reserve 1 GB. Com uma biblioteca de 4.062 filmes e 656 séries, o rex usou menos de 500 MB durante a inicialização e cerca de 730 MB enquanto a biblioteca era navegada. A conversão de vídeo precisa de mais memória além disso.

**Disco:** nada para filmes. O rex guarda a biblioteca em `rex.db`. Os downloads e as imagens que a análise gera (prévias de busca, imagens de capítulos) também ficam ao lado dele, se você usar esses recursos.

**Conversão:** só com FFmpeg. Um chip gráfico deixa tudo bem mais rápido: um filme em 1080p convertido em um chip Intel pequeno começa em cerca de 2 segundos. Quais chips o rex usa em cada sistema está em [Por plataforma](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#by-platform): no macOS a conversão sempre é feita pelo processador.

### Ele lê meus arquivos locais? {#does-it-read-my-local-files}

Não. O rex nunca escaneia uma pasta ou um disco e não precisa de mount. Todo arquivo vem de uma fonte via HTTP. Arquivos no seu próprio disco também podem entrar: alguma coisa precisa servi-los e informar o rex sobre eles, como mostra [rex com o seu próprio app](any-source.md).

### Funciona com Usenet? {#does-it-work-with-usenet}

Sim, por meio de uma fonte que lê Usenet, como o zurg. O rex nunca conversa com um provedor de Usenet: a fonte lê os arquivos e os entrega ao rex como qualquer outro arquivo. Configure o zurg para isso com [Usenet](../zurg/guides/usenet.md) e aponte-o para o rex como em [rex com zurg](with-zurg.md).

### Preciso do zurg? {#do-i-need-zurg}

Não. zurg é só uma fonte entre outras. O rex aceita qualquer coisa que fale a API de feed dele:

- [rex com seu próprio app](any-source.md): qualquer app que sirva arquivos via HTTP
- [rex com seus addons do Stremio](stremio.md): catálogos de addons do Stremio
- [rex com zurg](with-zurg.md): sua conta de debrid ou Usenet
- [Criando addons para o rex](addons.md): vídeos caseiros, gravações ou canais, com uma programação sua, e três [tutoriais](addon-home-videos.md) para começar

Várias fontes podem preencher as mesmas bibliotecas de Movies e TV.

### Preciso abrir uma porta (port forward)? {#do-i-need-to-forward-a-port}

Fora de casa? Os apps do Plex na sua rede doméstica encontram o rex sem precisar mexer no roteador. O app.plex.tv também funciona pelo endereço HTTPS que o [rex-direct](any-source.md#rex-direct) gera para um rex reivindicado.

O rex precisa de um endereço próprio para assistir fora de casa ou para outra residência. O caminho mais simples é um único port forward ([rex-direct](any-source.md#rex-direct)). Com IPv6 e sem IPv4 público, use o [rex-direct over IPv6](any-source.md#rex-direct-over-ipv6). O [Tailscale serve](any-source.md#tailscale-serve) não precisa de port forward nos dispositivos que rodam Tailscale. [Use it outside your home](any-source.md#use-it-outside-your-home-optional) compara as opções.

### O que ele não faz? {#what-does-it-not-do}

There is no tuner or DVR. Música, TV ao vivo e fotos precisam de uma fonte que as envie. Veja [Música com o rex](music.md) e [TV ao vivo com o rex](live-tv.md). O zurg envia quadrinhos como fotos, que o Plex Web mostra. Mixes e estações de rádio do Plexamp estão ausentes. O rex não tem relay, então o uso remoto precisa do próprio endereço ([Use it outside your home](any-source.md#use-it-outside-your-home-optional)).

## Depois de instalar {#after-you-install}

### Por que o app mostra uma versão do Plex e "Check for Updates"? {#why-does-the-app-show-a-plex-version-and-check-for-updates}

rex se apresenta para os apps e para o plex.tv como um Plex Media Server, então os apps mostram um número de versão de Plex Media Server. Esse número não é o da rex. **Check for Updates** sempre responde que o servidor está atualizado: a rex nunca se atualiza sozinha. Para atualizar a rex, baixe um nightly mais novo, como em [Updating](any-source.md#updating).

### Por que meu navegador em port 32400/web não abre uma biblioteca? {#why-does-my-browser-at-port-32400web-not-open-a-library}

rex não tem um app web próprio. Abrir `http://<rex's LAN IP>:32400/web` mostra uma página de status curta. Assista em um app do Plex ou em um navegador em [app.plex.tv](https://app.plex.tv).

![A página que o rex mostra em /web enquanto ainda não foi reivindicado](../assets/rex/80-rex-web-page.webp)

### O que sai da minha máquina? {#what-leaves-my-machine}

- **plex.tv, no início e uma vez por dia, registrado ou não:** o id, o nome e a versão do servidor, para ler a lista pública de lançamentos do Plex e descobrir o número da versão mais nova.
- **plex.tv, depois de registrado em uma conta Plex:** a claim, os endereços do servidor (o endereço da LAN e os endereços HTTPS) e os nomes das suas bibliotecas.
- **Serviço de metadados do Plex, depois de registrado:** o id de cada título, para buscar o nome, o pôster, a sinopse e os episódios. Uma busca de legendas, pelo **Search Subtitles** ou pela configuração automática de legendas de uma pessoa, envia o nome do arquivo e a impressão digital dele.
- **Hosts de imagens, quando um app as mostra:** requisições para os pôsteres e as imagens que as suas fontes indicam.
- **DMM, para o rex-direct, depois de registrado e depois a cada 6 horas:** o id do servidor, o token dele na conta Plex e o IP da LAN. O DMM confere com o plex.tv que o servidor é seu, vê o seu IP público e aponta os nomes do seu rex-direct para ele e para o IP da LAN. Se a máquina tiver um endereço IPv6 global, o rex também envia esse endereço, um minuto depois de iniciar (ou de ser reivindicado) e depois a cada 6 horas, e toda vez que o DMM se conecta a ele para verificar se ele chega ao mesmo servidor. Desligue com `REX_DIRECT_URL=off`.
- **Suas fontes, quando você reproduz ou apaga:** requisições para os arquivos que você reproduz, e os apagamentos (abaixo).
- **Seu servidor Plex antigo, somente quando você [traz o seu histórico de exibição](import-watched.md):** requisições para o seu histórico de exibição.
- **Webhooks, somente se você configurar algum:** eventos, para os endereços que você definir.

O rex não pergunta a ninguém o que é um lançamento: a fonte decide e avisa o rex. O zurg, por exemplo, pergunta ao DMM ([Por que o DMM coloca os arquivos](with-zurg.md#why-dmm-places-the-files)).

### Apagar pelo app do Plex apaga o arquivo? {#does-deleting-in-a-plex-app-delete-the-file}

Sim. Apagar um filme ou episódio em um app do Plex, logado com a conta em que o rex está registrado, apaga os arquivos na origem, do mesmo jeito que um servidor Plex apaga arquivos do próprio disco. Uma origem em uma conta de debrid, como o zurg, apaga os arquivos ali. Se a origem recusar, o título continua lá e o app avisa que não foi possível apagar. Pessoas com quem você compartilha não conseguem apagar. [Apagar no app do Plex](any-source.md#step-5-watch-something) explica como desativar isso.

### Nada reproduz, ou todos os apps dizem que não tem poder suficiente {#nothing-plays-or-every-app-says-it-is-not-powerful-enough}

Olhe o log do rex logo depois que você aperta Play. `upstream failed` ou `502` ali significa que o rex não consegue acessar sua fonte no endereço que a fonte informou para ele, e instalar o FFmpeg não resolve isso. A causa mais comum é o zurg no Docker Desktop, no Windows ou no macOS. A linha `upstream failed` de [rex com zurg](with-zurg.md#when-something-is-wrong) ou [rex com seu próprio app](any-source.md#when-something-is-wrong) verifica o endereço e diz o que mudar. Se só alguns arquivos falham, muitas vezes só no navegador, o dispositivo não consegue reproduzi-los do jeito que estão: configure [Conversão de vídeo](any-source.md#converting-video-optional).

### Um título foi identificado errado. Como corrijo? {#a-title-is-matched-wrong-how-do-i-fix-it}

O que é cada arquivo é decidido pela fonte, e o rex mostra esse título. Entre com a conta em que o rex está registrado e use **Fix Match**: o rex guarda a sua escolha, e uma fonte pode ler essa informação de volta para manter isso como a correspondência daquele release, como o zurg faz ([Por que o DMM posiciona os arquivos](with-zurg.md#why-dmm-places-the-files)).

### Onde consigo ajuda? {#where-do-i-get-help}

[Obtendo ajuda](../guides/remote-help.md) explica onde pedir ajuda e o que incluir: o fórum **rex-support** no [Discord](https://discord.com/invite/7u4YjMThXP), e a ajuda remota para patrocinadores.
