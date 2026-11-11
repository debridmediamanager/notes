# Servidor de notícias ElfHosted {#elfhosted-news-server}

ElfHosted inclui uma conta de Usenet nos planos do addon Stremio dele e chama isso de Usenet Essential. Esta
página registra o que esse servidor é. Tudo abaixo foi medido em 04/09/2026 a partir de um único host. A
conta em si não pôde ser medida, porque a única credencial que a ElfHosted publicou está morta, e
esse é o primeiro achado.

## O que responde na rede {#what-answers-on-the-wire}

`news.elfhosted.com` resolve para `94.232.116.124` e fala NNTP sobre TLS 1.3 na porta 563, atrás de um certificado do Let's Encrypt para `news.elfhosted.com`. O certificado tem só esse nome e nada mais, e foi emitido em 2026-08-17. O mesmo servidor responde em texto puro na porta 119 com a mesma saudação. A saudação é `200 Welcome to elfhosted`.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
AUTHINFO USER
```

É a mesma string `nntpswitch2` que o [leitor do TorBox](torbox-news-server.md) mostra. Esta lista é a não autenticada, então ela termina em `AUTHINFO USER` e não em `POST`. `HELP` responde sem credenciais e lista o conjunto completo de comandos, incluindo `POST`, `IHAVE`, `XPAT` e `XGTITLE`, então a ausência de `POST` vem da sessão e não do servidor.

Três comandos funcionam antes da autenticação e nenhum outro.

| Comando | Resposta |
|---|---|
| `DATE` | `111 20260903225242` |
| `HELP` | `100 Help follows.` |
| `CAPABILITIES` | `101 Capabilities.` |
| `MODE READER` | `480 Authentication required for command.` |
| `GROUP` and `LIST` and `STAT` and `POST` | `480 Authentication required for command.` |

## Quem administra {#who-runs-it}

The TorBox page had to infer the operator from adjacency. This one does not. `news.elfhosted.com`
sits inside the Abavia reader block itself.

`94.232.116.124` is in `94.232.112.0/21`, `AS48345 AS-ABAVIA`, registered to Abavia S.r.l. of San
Marino. Uma varredura reversa de `94.232.116.0/24` retorna 79 nomes. Quarenta e cinco deles respondem NNTP na porta 563,
e todos os quarenta e cinco informam `nntpswitch2 (local-dev)` com listas de capacidades idênticas byte a byte, na mesma ordem. Os roteadores de borda da própria Abavia estão no mesmo /24, assim como os alimentadores, o host web e o nameserver da XS News.

| Endereço | Leitor | Saudação |
|---|---|---|
| `94.232.116.122` | `reader2.newsxs.nl` | `200 Welcome to Newsxs` |
| `94.232.116.124` | `news.elfhosted.com` | `200 Welcome to elfhosted` |
| `94.232.116.125` | `reader.spotnews.nl` | `200 Welcome to Spotnews` |
| `94.232.116.128` | `reader.easyusenet.nl` | `200 Welcome to Easyusenet` |
| `94.232.116.131` | `reader.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.135` | `reader-usenetfarm.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.136` | `reader.torrentclaw.com` | `200 Welcome to TorrentClaw` |
| `94.232.116.140` | `reader.usenet.nl` | `200 Usenet.nl S.r.l.` |
| `94.232.116.147` | `giganews.hostredirects.com` | `200 Welcome to giganews` |
| `94.232.116.150` | `news.usenext.de` | `200 Welcome to Aviteo Ltd DE` |
| `94.232.116.174` | `news.hitnews.com` | `200 Welcome to Hitnews` |

ElfHosted tem quatro endereços da Easyusenet, sete da XS News e doze da TorrentClaw, que é outro addon do Stremio que atua como frente da mesma plataforma.

Não há multiplexação baseada em nome. Conectar ao endereço com um servername `reader.xsnews.nl`, ou com um que nem existe, retorna o mesmo certificado e a mesma saudação `200 Welcome to elfhosted`. Um endereço por marca.

A TorBox não está nesse bloco. Ela fica em `78.152.55.171`, em `AS3257 GTT`, na Holanda. Por isso, a atribuição ao ElfHosted é a mais forte das duas. A TorBox roda o mesmo software ao lado de uma marca dessa família. O ElfHosted roda nele no próprio espaço de endereços da Abavia.

**Medido** é a impressão digital do software, a propriedade do endereço, o certificado e a ausência de multiplexação baseada em nome. **Inferido** é que o spool por trás disso é da própria Abavia, e não uma mistura montada pelo ElfHosted. Nada no wire distingue essas duas coisas sem uma credencial.

## A credencial publicada está morta {#the-published-credential-is-dead}

On 2025-12-20 ElfHosted anunciou acesso NNTP incluído com o NzbDav como uma prova de conceito de dois meses
com um provedor de infraestrutura Usenet não identificado, e publicou uma credencial compartilhada no anúncio.

| Campo | Como foi publicado, 2025-12-20 |
|---|---|
| Host | `news.elfhosted.com` |
| Port | 563 SSL |
| Username | `elfie` |
| Password | `elfie` |
| Connections | 100 |
| Custo | nenhum até fevereiro de 2026 |

Ela já vinha pré-configurada no NzbDav para novos usuários. O post dizia que o acordo seria avaliado
quando a prova de conceito terminasse. Foi o que aconteceu. A credencial não autentica mais.

```
200 Welcome to elfhosted
381 Need more.
482 Invalid username or password
```

Neste software, `482 Invalid username or password` é a resposta de credencial morta, e não o limite de
conexões, que diz `482 too many connections for your user`. O tempo de resposta confirma isso. Cinco
tentativas com um usuário que nunca existiu e duas com `elfie` recebem a mesma recusa, no mesmo
formato.

| Tentativa | Resposta | Tempo |
|---|---|---|
| Usuário aleatório, cinco tentativas | `482 Invalid username or password` | mediana 2066 ms, faixa de 2043 a 2070 |
| `elfie` e `elfie`, duas tentativas | `482 Invalid username or password` | 2043 ms e 2212 ms |

Uma credencial aposentada e um usuário que nunca foi emitido são indistinguíveis aqui, tanto no código
quanto no tempo de resposta. Cerca de dois segundos é o que este software leva para dizer não, e é
o mesmo que o leitor do TorBox também faz.

Ou seja, o número de 100 conexões descreve uma oferta que já acabou. É o único número que a ElfHosted
já publicou sobre esse servidor, e ele não se aplica a nada que você pode comprar hoje. O Usenet
Essential pago provavelmente emite uma credencial por cliente, mas isso não dá para verificar de fora.

O mesmo anúncio também publicou um endpoint Newznab interno em `elfhosted-internal.zyclops` que
aceita qualquer chave de API e pode ser filtrado para resultados saudáveis conhecidos de um determinado backbone. Esse
endpoint é o que a loja da ElfHosted quer dizer quando afirma que um plano Usenet inclui o indexador. Ele mostra
sinais de disponibilidade e saúde, não o conteúdo em si, e a própria equipe descreve isso como uma
"bola de cristal para a saúde da infraestrutura", e não como um "mapa do tesouro". Um plano ainda precisa de um
indexador de verdade junto com ele.

## O que não pôde ser medido {#what-could-not-be-measured}

Tudo que decide se vale a pena preencher uma vaga de provedor. Tudo isso exige uma credencial.

| Propriedade | Estado |
|---|---|
| Limite de conexões | desconhecido, o 100 foi aplicado só à prova de conceito aposentada |
| Retenção | nunca publicada |
| Grupos em `LIST ACTIVE` | precisa de autenticação |
| Janela de números de artigo | precisa de autenticação |
| Cobertura em comparação com outros backbones | precisa de autenticação |
| Throughput de uma única conexão | precisa de autenticação |
| Postagem | o servidor oferece `POST`, a conta é desconhecida |

Um teste de sete dias custa um dólar e compra a credencial. Rodar a mesma varredura de 531 message ids usada na [página do TorBox](torbox-news-server.md#what-it-actually-holds) dentro dessa semana responderia a todas as linhas acima.

## O que a plataforma já informa {#what-the-platform-already-tells-you}

Dois fatos se mantêm das medições do TorBox, e um não.

Se mantém: a semântica das recusas e o tempo de recusa. É o mesmo software, então as respostas são as mesmas. Por isso, `482 Invalid username or password` significa credencial inválida aqui também, e o limite tem outra string.

Se mantém: a janela de números de artigo. Um leitor `nntpswitch2` gera números de artigo dentro de uma janela curta, então qualquer coisa que percorra números em vez de message ids enxerga uma quinzena de Usenet. Isso é uma característica da plataforma, não de uma conta específica. Leituras feitas via NZB buscam os artigos pelo message id e não são afetadas.

Não se mantém: a cobertura. O leitor do TorBox foi medido como um subconjunto estrito de uma conta Omicron, com 71.2 por cento, e zero artigos próprios em 531. Esse número é do endpoint do TorBox, não deste, e o TorBox nem está neste bloco. É a referência mais próxima, no mesmo software e com o mesmo operador, mas não é uma medição do ElfHosted. Trate isso como a hipótese a ser testada, não como a resposta.

## Configurando no zurg {#configuring-it-in-zurg}

Se uma credencial for obtida, ela vira uma entrada de servidor `type: nzb` comum, ao lado do primário.

```yaml
providers:
  - type: nzb
    nntp:
      host: your-primary.example.com
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 40
      backbone: primary-backbone
      servers:
        - name: elfhosted-news
          host: news.elfhosted.com
          port: 563
          tls: true
          username: YOUR_ELFHOSTED_USERNAME
          password: YOUR_ELFHOSTED_PASSWORD
          connections: 8
          backbone: abavia
          backup: true
```

Comece com 8 conexões e só aumente depois de medir o limite real. O 100 publicado foi aposentado, e um pool que abre além de um limite desconhecido vai se recusar durante um cold start. Defina `backbone: abavia` em vez de um nome de marca, porque XS News, Easyusenet, Hitnews, UseNeXT e este são a mesma plataforma, e tratá-los como backbones separados faria um pool contar um mesmo spool várias vezes. `backup: true` mantém o servidor para artigos que todos os primários já recusaram.

Nunca aponte um segundo cliente para a mesma credencial. O servidor derruba quem entrou primeiro, não quem chegou depois, então um segundo consumidor derruba o primeiro.

## Vale a pena ocupar um lugar? {#is-it-worth-a-slot}

Ele não pode ser comprado sozinho. Ele vem junto com um plano de addon do Stremio de nove dólares por mês, que também inclui um addon hospedado, uma instância do NzbDav e uma conta TorBox Essentials. Como um item dentro desse pacote, ele não custa nada a mais, e esse é o argumento mais forte a favor dele sem uma credencial.

Comparado a uma pilha que já tem uma conta Omicron, Eweka e Frugal, adicionar um quarto leitor dessa plataforma é a mesma aposta que a página do TorBox fez e perdeu. Essa aposta não foi medida aqui, então é uma hipótese inicial e não um veredito. O que resolveria a questão seria um dólar, uma semana e a varredura de ids 531.
