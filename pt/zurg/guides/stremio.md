# O addon do Stremio {#the-stremio-addon}

zurg pode responder ao Stremio como um addon. O Stremio pede pelo id do IMDb. O zurg pesquisa nos seus indexadores Newznab e puxa o NZB da release escolhida para o backend de Usenet. Depois disso, ele reproduz e repara como qualquer outra release do zurg.
Tudo o que for reproduzido desse jeito também entra na biblioteca e aparece no Plex.

## Configuração {#configuration}

O addon precisa de uma conta NZB, `nzb` ou
[`torbox_nzb`](../providers/torbox-nzb.md), que é quem entrega os bytes, e
de pelo menos um indexador. Com `torbox_nzb`, um release que a TorBox já tem
começa dentro do tempo de espera do addon, desde que não haja outro post NZB
esperando. Um release não cacheado precisa terminar de baixar na TorBox
primeiro, o que demora mais do que o player espera.

```yaml
stremio:
  enabled: true
  # token: ""            # generated and kept in data/stremio-token when empty
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_KEY
    - name: second-indexer
      url: https://second-indexer.example
      api_key: YOUR_KEY
      api_path: /api/v1/api   # for an indexer that 404s the default /api
```

Tudo isso fica na página de configuração, em **Stremio Addon**: o switch, a
lista de indexadores e o limite de resultados. A URL do addon aparece ali com
um botão de copiar, montada a partir do endereço que você abriu o dashboard.
Esse é o endereço que você deve usar: veja [Instalando em outro dispositivo](#installing-it-on-another-device).

Ao iniciar, o zurg registra a URL do addon no log:

```
<zurg>/stremio/<token>/manifest.json
```

Cole a URL no Stremio (em Addons, a caixa de busca aceita uma URL). O token no
caminho é toda a autorização. Os clientes do Stremio não enviam autenticação
própria, então as rotas ficam fora da basic auth, do mesmo jeito que o endpoint
do SABnzbd. Trate a URL como uma senha: os links de reprodução que ela gera
carregam suas api keys dos indexadores, e quem tiver a URL pode gastar seus
grabs de indexador e conexões com o servidor de notícias.

## Instalando em outro dispositivo {#installing-it-on-another-device}

O Stremio só aceita um addon por `http` simples no computador onde o próprio Stremio roda. Ou seja, `http://127.0.0.1` ou `http://localhost` na máquina do zurg. Em todos os outros lugares ele precisa de `https`. Uma TV, um celular ou um segundo computador mostra **failed to load manifest** para um endereço `http://`, mesmo quando consegue acessar o zurg sem problema. Isso vale também para um endereço da LAN e para um endereço do Tailscale. A página de configuração avisa isso ao lado da URL do addon sempre que você a abriu por `http` simples em um desses endereços.

O zurg não serve `https` sozinho. Coloque na frente dele algo que faça isso. Depois abra a página de configuração no endereço `https` e copie a URL do addon de lá. O zurg monta a URL do addon e todos os links de play a partir do endereço pelo qual cada requisição chegou. Não existe configuração de URL pública e o `base_url` não é usado aqui. Um único zurg pode atender um player da LAN e um player remoto ao mesmo tempo.

Seja o que for que fique na frente, ele precisa dizer ao zurg duas coisas. O nome vem do cabeçalho `Host` ou de `X-Forwarded-Host`. O esquema vem de `X-Forwarded-Proto: https`. Sem esse cabeçalho o addon carrega, mas os links de play voltam como `http://` e a reprodução falha. Cada opção abaixo envia as duas coisas.

O Stremio usa dois caminhos. `/stremio/` é o addon. `/strm/e/` é para onde o botão de play manda o player para o vídeo. Os dois funcionam sem a senha do zurg, porque o Stremio não consegue enviar senha. Quem protege é o token na URL do addon. Quando o zurg for para a internet, publique só esses dois caminhos. O resto é o seu painel e a sua biblioteca.

### Tailscale Serve

O jeito mais simples quando todos os dispositivos que rodam o Stremio conseguem rodar o Tailscale. O zurg fica fora da internet.

1. No console de administração do Tailscale, ative o MagicDNS e os certificados HTTPS.
2. Rode isto na máquina do zurg. Use sua própria porta se o zurg não estiver na 9999.

   ```bash
   tailscale serve --bg 9999
   ```

   No Windows, rode o mesmo comando no PowerShell. Se ele responder access denied, abra um PowerShell como administrador. No Linux, coloque `sudo` na frente, a menos que você tenha se tornado operador do Tailscale (`sudo tailscale set --operator=$USER`). No macOS, se o `tailscale` não for encontrado, a cópia do próprio app Tailscale é `/Applications/Tailscale.app/Contents/MacOS/Tailscale`.

3. Abra `https://<machine>.<tailnet>.ts.net/config/` e copie a URL do addon do card **Stremio Addon**.

O Tailscale obtém o certificado e envia os dois headers. `tailscale serve reset` desativa isso de novo.

Um dispositivo que não consegue rodar o Tailscale pode usar o Tailscale Funnel. Ele coloca o mesmo endereço na internet. Publique apenas o que o Stremio precisa.

```bash
tailscale funnel --bg --set-path /stremio http://127.0.0.1:9999/stremio
tailscale funnel --bg --set-path /strm/e http://127.0.0.1:9999/strm/e
```

A página de configuração não fica nesse endereço. Copie a URL do addon da página como você costuma abri-la e troque o início por `https://<machine>.<tailnet>.ts.net`. O Tailscale limita a largura de banda que um Funnel recebe. Um remux 4K pode travar.

### Seu próprio reverse proxy {#your-own-reverse-proxy}

Já tem um reverse proxy rodando com domínio e certificado? Adicione o zurg nele.
O Caddy mantém o header `Host` e envia `X-Forwarded-Proto` por conta própria.
Isso publica só os dois caminhos do Stremio e mais nada.

```
zurg.example.com {
    handle /stremio/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle /strm/e/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle {
        respond 404
    }
}
```

O nginx não envia nenhum dos dois headers, a não ser que você peça os dois.

```nginx
location ~ ^/(stremio|strm/e)/ {
    proxy_pass http://127.0.0.1:9999;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
}
```

Coloque isso dentro do bloco `server` que já escuta na porta 443 com o seu certificado. O `proxy_buffering off` deixa o vídeo passar em streaming direto, sem passar pelos buffers do nginx.

### Cloudflare Tunnel

Um túnel nomeado dá ao zurg um endereço `https` em um domínio seu que esteja na Cloudflare, sem precisar abrir nenhuma porta. A Cloudflare mantém o header `Host` e envia o `X-Forwarded-Proto` por conta própria. Roteie só os caminhos do Stremio no `config.yml` do túnel.

```yaml
ingress:
  - hostname: zurg.example.com
    path: ^/(stremio|strm/e)/
    service: http://127.0.0.1:9999
  - service: http_status:404
```

Duas coisas para saber antes. A Cloudflare desiste de uma requisição depois de 100 segundos. O primeiro play de um release pode demorar mais que isso. Clique em play de novo e ele começa. E os termos da Cloudflare permitem que ela limite contas que mandam muito vídeo pela rede dela sem um plano pago. Cada play passa pelo túnel.

## O que acontece quando você dá play {#what-a-play-does}

Escolher um stream é uma captura: o zurg baixa o NZB do indexador, coloca-o em `nzbs/` (usando as mesmas regras de nomenclatura do endpoint do SABnzbd, então um release capturado duas vezes, ou já capturado por um *arr, é encontrado e não duplicado), espera a biblioteca listá-lo e redireciona o player para o endpoint assinado `/strm/e/`, pelo qual todo arquivo `.strm` já toca: leituras por faixa, failover de conta, interiores de RAR/7z.

A primeira reprodução de um release demora mais do que um stream de debrid. O NZB precisa ser baixado e analisado, e a leitura do interior de um arquivo compactado também leva tempo: normalmente alguns segundos, e até um ou dois minutos para uma postagem ofuscada cuja etapa de renomeação precisa rodar. Uma reprodução que passa do tempo de espera responde 503 com um Retry-After. Apertar play de novo cai no caminho rápido. Todas as reproduções seguintes são imediatas.

Um release que é listado mas não tem nada reproduzível, geralmente porque saiu do spool ou porque a checagem do news server marcou todos os arquivos como quebrados, não encerra o clique. A URL de reprodução carrega a requisição para a qual foi gerada, então o zurg reordena os releases do título e tenta as linhas depois da escolhida, cada uma pelo mesmo caminho de captura e listagem. O primeiro que tocar é para onde o player é redirecionado. Ele percorre a resposta inteira, não só as linhas que a lista mostrou. `max_results` é quanto uma pessoa quer rolar a tela. Se ele também limitasse a recuperação, um título mostrado dez linhas abaixo só conseguiria tentar nove, mesmo que a busca já tivesse encontrado mais. As linhas *depois* da escolha são de propósito: são a mesma resolução e menores, ou a resolução abaixo, nunca um release maior que o usuário deixou passar. Um fallback que ainda está ingerindo responde o mesmo 503, e apertar play de novo o resolve. O release recusado é recusado na hora, e o fallback é encontrado pelo caminho rápido. Só essa recusa final cai para o próximo. Um 503 nunca cai.

Cada tentativa gasta uma captura no indexador e deixa seu release na biblioteca como qualquer outra captura. Por isso a cadeia é limitada por um orçamento de vinte e cinco segundos e um teto de seis tentativas. O orçamento é o limite principal porque as tentativas não custam o mesmo: um release que saiu do spool é recusado em menos de um segundo, enquanto um que ingere e abre um arquivo antes de se revelar vazio pode consumir sozinho quase todo o orçamento. Quando todas as linhas tentadas são recusadas, a resposta é o 404 de sempre. Cada fallback é registrado em nível info, com o release recusado e o próximo que foi tentado.

Medido contra outros três addons do Stremio baseados em usenet em 7 de setembro de 2026: stremio-addon-findings-2026-09-07.md.
Resumindo, o limite por resolução corrigiu o que a rodada anterior encontrou, mas a cobertura ainda caiu pela metade. Um bucket de cinco entradas não tem para onde ir quando a primeira entrada reproduzível é um release que saiu do spool. O fallback acima é a primeira correção dessa rodada. O bucket já cresceu de cinco para dez.

## Comportamento da busca {#search-behaviour}

- Filmes pesquisam `t=movie`, episódios `t=tvsearch` com `season`/`ep`, ambos por
  `imdbid` — só com dígitos, porque vários indexadores devolvem zero resultados
  para a forma `tt`.
- Cada indexador é consultado por `search_limit` releases (padrão 100). Todos os
  limites abaixo escolhem entre o que essa busca pediu, então ele é o teto da
  resposta.
- Os indexadores são consultados em paralelo; se um recusar (um limite de rajada,
  uma chave morta), perde os resultados dele, não a lista inteira. As recusas são
  registradas por indexador.
- Os resultados são deduplicados pelo nome do release, ordenados primeiro pela
  resolução e depois pelo tamanho, e limitados a `max_results` (padrão 10) *por
  resolução*. O limite conta por resolução porque a ordenação começa pelo 2160p:
  um título popular tem mais releases UHD abaixo do teto de tamanho do que
  qualquer limite, então contar na lista inteira deixa todo título popular só com
  remuxes, independente do que a busca achou no resto.
- O que cada resolução mantém é uma distribuição de tamanhos, não os maiores:
  escolhas igualmente espaçadas, do maior release até o menor, sendo que os dois
  extremos sempre entram. Se mantivesse só do topo, uma faixa de 1080p com cinco
  itens seriam cinco remuxes entre 19 e 30 GB, e o encode de 4 GB que um celular
  ou um notebook reproduz direto seria justamente o que o limite remove. Medido em
  7 de setembro de 2026: três das quinze entradas do zurg para The Shawshank
  Redemption tinham menos de 6 GB, contra quarenta releases desse tipo nos mesmos
  indexadores. A lista continua em ordem decrescente de tamanho dentro de cada
  resolução. Um release cujo tamanho o indexador não informou não tem lugar nesse
  eixo, então só ocupa o espaço que sobra para os releases com tamanho.
- A descrição de cada stream traz o nome do release, o tamanho, o indexador que o
  encontrou e há quanto tempo ele foi postado — `3d`, `126d`, `2y` — quando o
  indexador informou. O envelhecimento no servidor de notícias foi o motivo mais
  comum de falha de reprodução na rodada de 7 de setembro, e a data de postagem é
  o único sinal que o espectador tem para escolher um release que evite isso.
- Releases maiores que `max_size_gb` são descartados antes da ordenação, para um
  player que não aguenta remux. Por padrão não há limite: a distribuição acima já
  lista o menor release de cada resolução ao lado dos seus remuxes. Tamanhos que o
  indexador não informou são mantidos. O filtro é aplicado quando a lista é
  renderizada, então mudar o teto vale também para títulos em cache.
- Os resultados ficam em cache no disco (`data/stremio-cache/`, um arquivo por
  título), então reabrir um título não gera nenhuma chamada aos indexadores — eles
  costumam ter cota diária, e o Treasure Maps recusa depois de umas seis
  consultas seguidas. Quanto tempo uma resposta fica válida depende de quanto a
  busca encontrou, porque uma lista pequena indica que os uploads ainda estão
  chegando ou que algum indexador estava fora do ar: um resultado vale uma hora,
  dois valem duas horas, até quatro; cinco ou mais é uma resposta fechada e vale
  `cache_hours` (padrão 24 — a única faixa configurável). Resposta vazia nunca é
  guardada em cache. Uma lista de streams em cache traz um item **refresh** no
  final, informando a idade dela; abrir esse item (ele abre no navegador, não no
  player) limpa o cache daquele título, e reabrir o título faz uma busca nova. O
  cache sobrevive a reinícios e as entradas expiradas se apagam sozinhas.
- A temporada 0 (especiais) é recusada em vez de ser pesquisada de forma errada, e
  a cobertura da busca por id depende do indexador: um release que o indexador só
  encontra por busca de texto não vai aparecer.
