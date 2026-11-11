# Servidor de notícias do TorBox {#torbox-news-server}

A assinatura TorBox Pro inclui uma conta Usenet. É um servidor NNTP de verdade, e o zurg pode usá-lo como um provedor `type: nzb` comum. Esta página registra o que esse servidor é e o que ele vale como vaga de provedor. Tudo abaixo foi medido em 2 e 3 de setembro de 2026, a partir de dois hosts em redes separadas.

## O que responde na rede {#what-answers-on-the-wire}

`nntp.torbox.app:563` fala NNTP sobre TLS 1.3, por trás de um certificado Let's Encrypt para `nntp.torbox.app`. A saudação é `200 Welcome to TorBox`. A lista de capacidades diz qual é o software.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
POST
```

Essa string de implementação não é INN, nem Diablo, nem o `nntpd` que alguns provedores informam.
É um software próprio, e o nome diz o que ele faz. Um switch fica na frente de um ou mais spools de artigos.

## Quem administra {#who-runs-it}

Quarenta hosts públicos de leitura foram testados com essa string de implementação. Trinta e dois responderam via NNTP,
e seis deles informam `nntpswitch2`. Todos os seis devolvem listas de capacidades idênticas, na mesma ordem.

| Leitor | Endereço | Saudação |
|---|---|---|
| `nntp.torbox.app` | 78.152.55.171 | `200 Welcome to TorBox` |
| `news.cheapnews.eu` | 78.152.55.164 | `200 Welcome to Cheapnews` |
| `reader.xsnews.nl` | 94.232.116.131 | `200 Welcome to XS News` |
| `news.easyusenet.nl` | 94.232.116.128 | `200 Welcome to Easyusenet` |
| `news.hitnews.com` | 94.232.116.174 | `200 Welcome to Hitnews` |
| `news.usenext.de` | 94.232.116.150 | `200 Welcome to Aviteo Ltd DE` |

Todo o resto respondeu de outro jeito. Isso inclui as marcas da Omicron, Eweka, Frugal,
UsenetExpress, Giganews e Usenet.Farm.

Os endereços resolvem o resto. `94.232.112.0/21` está registrado para a Abavia S.r.l., de San Marino, com
`abuse@abavia.com` no registro. Uma varredura reversa de `94.232.116.0/24` retorna mais de sessenta
nomes de leitores só nesse bloco. XS News, Easyusenet, Hitnews e UseNeXT ficam ali, junto de dezenas
de marcas menores. O bloco vizinho `94.232.117.0/24` usa nomes de host da XS News de ponta a ponta.

A TorBox não fica nesse bloco. Ela fica numa faixa de Amsterdã, a sete endereços de
`news.cheapnews.eu`.

**Medido** é a impressão digital do software, a titularidade dos endereços e a proximidade entre eles. **Inferido** é
o acordo comercial. A TorBox descreve o seu Usenet como uma mistura de alta qualidade de provedores de Usenet, e o
software de troca é compatível com isso. Então a afirmação segura é que a TorBox opera na frente da mesma
plataforma de leitura que as marcas da Abavia e da XS News usam, e não que a TorBox revende um spool específico com nome.

## O que a conta te dá {#what-the-account-gives-you}

| Propriedade | Valor |
|---|---|
| Host | `nntp.torbox.app:563` TLS, também responde na 119 |
| Grupos em `LIST ACTIVE` | 103,415 |
| Conexões | 10, um limite rígido contado exatamente, incluindo o handshake em andamento |
| Retenção | 3900+ dias que a TorBox informa para este servidor |
| Postagem | permitida, `POST` retorna `340 Start posting` |
| Campos de overview | Subject, From, Date, Message-ID, References, Bytes, Lines, Xref:full |
| Compressão | `XZVER` e `XZHDR` ambos oferecidos |
| Largura de banda | ilimitada, mas contada no número de uso do painel da TorBox |

As credenciais vêm do torbox.app, em tools e View Usenet Connection Details. O username é o auth id da conta. A senha é mostrada uma única vez. Qualquer reset invalida a anterior, então um reset quebra todos os clientes que já estão configurados.

Duas mensagens de recusa são importantes quando algo dá errado. `482 too many connections for your user` é o limite de conexões e ela some assim que uma conexão é devolvida. `482 Invalid username or password` é uma credencial realmente morta. Ambas são falhas lentas, por volta de dois segundos. Uma autenticação bem-sucedida é bem mais rápida e foi medida entre 64 ms e 592 ms ao longo de um dia de conexões em produção.

## A janela de número de artigo tem duas semanas de largura {#the-article-number-window-is-two-weeks-wide}

`GROUP` em um grupo binário movimentado informa uma contagem exatamente igual à marca alta menos a marca baixa. Spools reais têm lacunas, então essa igualdade é a assinatura de numeração sintetizada. Além disso, a janela é curta.

| Grupo | Marca baixa | Marca alta | Números na janela |
|---|---|---|---|
| `alt.binaries.boneless` | 148068410000 | 150053594960 | 1,985,184,960 |
| `alt.binaries.teevee` | 2992135000 | 3392153099 | 400,018,099 |
| `alt.binaries.multimedia` | 31901685000 | 32301734812 | 400,049,812 |

Ao pegar os números mais antigos de `alt.binaries.boneless`, o servidor retorna artigos postados em 2026-08-19. Isso foi catorze dias antes da escrita deste texto. Qualquer coisa mais antiga não tem número nesse servidor.

Isso não afeta o zurg. Um NZB endereça os artigos pelo message id, e uma busca por message id alcança artigos muito mais antigos que a janela. Afeta, sim, qualquer coisa que percorra os números dos artigos. Um header downloader ou um indexador apontado para esse servidor vê uma quinzena de Usenet e nada além disso.

## Ele está repassando sua requisição para outros provedores? {#is-it-proxying-your-request-to-other-providers}

Não. Três medições dizem que a resposta vem de um spool que a plataforma já tem.

**Ele recusa mais rápido do que conseguiria perguntar a alguém.** Vinte e cinco message ids que nunca existiram em lugar nenhum foram perguntados a três servidores.

| Servidor | `STAT` em um hit | `STAT` em um id que nunca existiu |
|---|---|---|
| `nntp.torbox.app` | 37 ms | **43 ms** |
| `news.eweka.nl` | 20 ms | 471 ms |
| `newshosting.tweaknews.eu` | 44 ms | 909 ms |

Um servidor que consulta upstreams antes de responder fica mais lento quando a resposta é não, porque cada upstream precisa responder primeiro. Este diz não no mesmo tempo em que confirma um sim. Isso é um índice local respondendo.

**Não há penalidade no primeiro fetch.** Dez artigos de 2012 a 2018 foram buscados frios e depois imediatamente de novo na mesma conexão.

| Servidor | mediana fria | mediana quente |
|---|---|---|
| `nntp.torbox.app` | 49.6 ms | 30.9 ms |
| `news.eweka.nl` | 98.0 ms | 78.1 ms |

A razão frio para quente é 1.6 aqui, contra 1.25 em um spool comum. Isso é TCP e page cache. Um fetch de um terceiro na primeira requisição custaria bem mais e só apareceria na passagem fria. Um artigo de 792 KB chegou frio em 49 a 73 ms, o que dá por volta de 11 a 16 MB/s, e não sobra espaço para um round trip a outro provedor.

**Uma mistura não pode ser um subconjunto de um de seus membros.** Este é o argumento que decide. Se o servidor tivesse juntado vários backbones, a cobertura seria a união deles e ele teria artigos que pelo menos um membro não tinha. Ele não tinha nenhum. É um subconjunto estrito da conta Omicron, com 71.2 por cento. Juntar provedores não consegue produzir isso.

Um detalhe relacionado para quem tenta rastrear a origem. Os headers voltam normalizados, não verbatim. A ordem dos campos muda e a capitalização é reescrita, então `X-Received-Body-CRC` vira `X-Received-Body-Crc` e `Message-ID` vira `Message-Id`. `Path` é `not-for-mail` em todo artigo verificado. Um spool comum pode preservar a cadeia real, e um dos servidores acima retorna `news.tweak-news.eu!spooler.pl1!...!feed.tweaknews.nl!path-stripped` para o mesmo artigo. Então os headers são reconstruídos a partir de campos parseados, e o caminho do feed não pode ser recuperado a partir deles.

## Configurando no zurg {#configuring-it-in-zurg}

A conta é uma entrada de servidor `type: nzb` comum. Duas chaves são mais importantes que as outras.

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
        - name: torbox-news
          host: nntp.torbox.app
          port: 563
          tls: true
          username: YOUR_TORBOX_AUTH_ID
          password: YOUR_TORBOX_NEWS_PASSWORD
          connections: 8
          backbone: torbox
          backup: true
```

`backup: true` mantém as dez conexões para artigos que todas as outras contas já recusaram. Um
primário ocupado não desvia para ela. Só um *no such article* de verdade faz isso. Veja
[as chaves do provedor](../reference/config.md) para entender como `backup` e `backbone` se comportam.

Configure 8 em vez de 10. O limite conta conexões que ainda estão em handshake, então um pool que
abre até o limite vai se recusar durante uma inicialização a frio. Deixar duas sobrando também dá espaço para
rodar uma verificação manual sem derrubar a produção. Nunca aponte um segundo cliente para as mesmas
credenciais. Dois consumidores de uma conta de dez conexões vão disputar conexões e travar um ao outro, e o
servidor recusa o titular mais antigo, não o mais novo.

## O que ele realmente guarda {#what-it-actually-holds}

A cobertura foi medida em três outros backbones usando os mesmos ids de artigo. A amostra tem 177
releases tirados de uma biblioteca NZB real do zurg. As datas de postagem vão de 2011 a 2026. De cada release
foram pegos três artigos, com espaçamento uniforme ao longo do arquivo. Isso dá 531 message ids. Cada id
foi perguntado a quatro contas, com uma conexão cada. As outras três são uma conta Omicron acessada pela Tweaknews, uma conta
Eweka e uma conta Frugal.

| Ano de postagem | ids | `nntp.torbox.app` | `newshosting.tweaknews.eu` | `news.eweka.nl` | `newswest.frugalusenet.com` |
|---|---|---|---|---|---|
| 2011 | 9 | 0 | 9 | 0 | 0 |
| 2012 | 21 | 16 | 21 | 21 | 21 |
| 2013 | 36 | 30 | 33 | 33 | 33 |
| 2014 | 36 | 33 | 36 | 36 | 36 |
| 2015 | 33 | 17 | 31 | 24 | 26 |
| 2016 | 36 | 31 | 36 | 36 | 36 |
| 2017 | 36 | 21 | 33 | 27 | 19 |
| 2018 | 36 | 16 | 36 | 24 | 24 |
| 2019 | 36 | 30 | 36 | 36 | 36 |
| 2020 | 36 | 34 | 36 | 36 | 36 |
| 2021 | 36 | 25 | 36 | 33 | 30 |
| 2022 | 36 | 29 | 36 | 27 | 27 |
| 2023 | 36 | 15 | 29 | 22 | 16 |
| 2024 | 36 | 23 | 35 | 32 | 33 |
| 2025 | 36 | 28 | 36 | 31 | 31 |
| 2026 | 36 | 30 | 36 | 30 | 30 |
| **Total** | **531** | **378 (71,2%)** | **515 (97,0%)** | **448 (84,4%)** | **434 (81,7%)** |

A TorBox respondeu por menos desta biblioteca do que qualquer um dos três backbones pagos.

O número que decide se o slot vale a pena é outro. **A TorBox não tinha nada que os outros não tivessem.** Nenhum artigo em 531. Comparada com a conta Omicron, ela é um subconjunto estrito, sem nenhum artigo próprio. Ela tinha 9 artigos que a Frugal não tinha e 6 que a Eweka não tinha. Todos esses também estavam na Omicron. Enquanto isso, só a conta Omicron tinha 61 artigos que nenhum outro backbone tinha.

Um miss nesse servidor é real, não é um servidor ocupado respondendo mal. Todos os 153 misses foram perguntados de novo, numa conexão nova, minutos depois, e nenhum voltou. Uma rodada anterior, do mesmo formato, perguntou de novo 77 misses e recuperou 1. Então, mais ou menos 1 por cento de uma resposta negativa é ruído, e o resto é ausência.

Um hit também é real. Vinte artigos que os quatro servidores disseram ter foram depois baixados por inteiro com `BODY`. Os quatro entregaram 20 de 20. Dá para confiar que um `STAT` nesse servidor significa que os bytes vão chegar.

A velocidade de uma única conexão também foi medida nas mesmas rodadas, mas não está reportada aqui, porque não foi estável. Três rodadas a partir de um mesmo host colocaram a TorBox em algum ponto entre 1,6 e 7,4 MB/s, com os outros três se sobrepondo a essa faixa e sem uma ordem consistente. Quem for dimensionar um pool deve medir a partir do próprio host.

Três ressalvas devem acompanhar a tabela. A amostra é a biblioteca de um único operador, então reflete o que essa biblioteca coleta. Três artigos de um mesmo release não são independentes entre si, então cada célula por ano é, na prática, doze releases, e não trinta e seis. E uma resposta `STAT` é uma afirmação sobre um artigo, não um veredito sobre um release inteiro.

## Vale a pena ocupar um lugar? {#is-it-worth-a-slot}

A conta não custa nada a mais, porque vem incluída no Pro. Esse é o argumento mais forte a favor dela.

Ela não é um backbone de retenção, e configurá-la como se fosse vai decepcionar. Ela respondeu por menos de uma biblioteca real do que as três contas pagas com as quais foi comparada, e não produziu nenhum artigo que outra já não tivesse recusado. Uma stack que já tem uma conta Omicron não ganha nada ao adicionar esta.

Restam dois usos honestos. Numa configuração com um único provedor, ela dá uma segunda opinião de graça, e qualquer segunda opinião é melhor do que nenhuma. E `backup: true` torna um palpite errado barato, porque uma conta de backup só é consultada depois que todas as primárias responderam que o artigo não existe.
