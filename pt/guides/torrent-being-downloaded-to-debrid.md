# O que significa "Torrent is being downloaded to debrid" {#what-torrent-is-being-downloaded-to-debrid-means}

O tela verde **Torrent is being downloaded to debrid...** significa que o lançamento que você escolheu ainda não está em cache no seu serviço debrid. O Torrentio, o addon do Stremio que mostra essa tela, acabou de adicionar o torrent à sua conta do Real-Debrid, TorBox ou outro debrid, e o serviço está baixando agora. Quando terminar, o mesmo resultado funciona como qualquer outro.

## O que fazer {#what-to-do}

1. **Escolha um resultado em cache.** Na lista do Torrentio, `[RD+]` (ou `[TB+]`, `[AD+]`, `[PM+]`) significa que está em cache, então toca na hora. `[RD download]` significa que não está em cache. Esses ficam depois dos que estão em cache.
2. **Ou espere alguns minutos e toque no mesmo resultado de novo.** Enquanto ainda está baixando, a tela verde aparece de novo. Quando terminar, ele toca.
3. **Acompanhe o download** na [página de torrents da Real-Debrid](https://real-debrid.com/torrents), no seu [painel da TorBox](https://torbox.app/dashboard) ou na [biblioteca do DMM](https://debridmediamanager.com/library). O DMM mostra a porcentagem, os seeds e a velocidade de cada download que não terminou.
4. **Travado em 0% e sem seeds?** Ninguém está compartilhando esse lançamento agora, então pode nunca terminar. Escolha outro.
5. **Não quer ver esses resultados de jeito nenhum?** Abra a [página de configuração do Torrentio](https://torrentio.strem.fun/configure), coloque seu serviço debrid e a chave como antes, marque **Don't show download to debrid links** em **Options** e aperte **INSTALL**. Você só vai ver resultados em cache.

## Veja o que está em cache antes de dar play {#see-whats-cached-before-you-press-play}

Entre no [DMM](https://debridmediamanager.com/) com o seu serviço debrid e pesquise o título. Na página dele, um botão verde **Instant RD** significa que o Real-Debrid já tem essa versão em cache, então ela toca na hora. O **DL with RD** significa que ela não está em cache e precisa baixar primeiro. Toque no chip **RD** acima dos resultados para esconder tudo que não estiver em cache. TorBox, AllDebrid, Premiumize e Offcloud têm os mesmos botões (**Instant TB**, **DL with TB** e assim por diante).

## Perguntas {#questions}

### Quanto tempo leva? {#how-long-does-it-take}

Depende de quantas pessoas compartilham aquele torrent. Um lançamento popular costuma ficar pronto em minutos: no nosso teste no Premiumize, um filme de 1,5 GB ficou pronto cinco minutos depois do primeiro clique, baixando de três peers. Um que quase ninguém compartilha pode demorar bastante, e um que ninguém compartilha pode nunca terminar. A página de torrents ou o dashboard mostra a velocidade e quantos seeds foram encontrados.

### Por que acontece em alguns resultados e não em outros? {#why-does-it-happen-on-some-results-and-not-others}

Os serviços de debrid guardam o que os usuários baixam. Se alguém já buscou exatamente aquela versão, ela está em cache e toca na hora. Se ninguém buscou, ou se o serviço já removeu o arquivo, a sua conta precisa baixá-lo primeiro. É essa a diferença entre `[RD+]` e `[RD download]`. A TorBox [explica como funciona o cache dela](https://support.torbox.app/en/articles/9923071-how-does-the-torbox-cache-work).

### Por que um resultado `[RD+]` mostrou isso? {#why-did-an-rd-result-show-it}

Real-Debrid não deixa addons perguntarem o que está em cache. Então, no Real-Debrid, o `+` do Torrentio significa que o release foi reproduzido por alguém recentemente, e não que o Real-Debrid confirmou isso agora. Se o Real-Debrid já tiver removido o arquivo, ele baixa de novo. Escolha outro resultado com `+` ou espere.

### Meu debrid está quebrado? {#is-my-debrid-broken}

Não. A tela verde significa que seu serviço aceitou o torrent e está trabalhando nele. Quando algo está realmente errado, o Torrentio mostra uma tela vermelha ou amarela com outras palavras, como "Access denied" ou "Some usage limit exceeded".

### Meu addon mostra outra coisa {#my-addon-says-something-else}

As palavras exatas vêm do Torrentio e de cópias self-hosted dele. Outros addons dizem a mesma coisa do seu jeito. O AIOStreams mostra "The file is being downloaded to your debrid. Try again later", o Comet mostra "The media you tried to play is not cached yet on this debrid service" e o StremThru mostra "Downloading to Store". Mesma causa, mesma solução.
