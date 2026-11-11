# Migrando do streamnzb v5.1.0 para o zurg {#migrating-from-streamnzb-v510-to-zurg}

streamnzb é um addon do Stremio. Ele pesquisa indexadores Newznab quando você aperta play e transmite o melhor resultado.
Nada fica guardado. Ele não tem montagem WebDAV no sistema de arquivos nem biblioteca Plex.

Não há **nenhuma biblioteca em disco para preservar e nenhum estado de exibição do Plex em risco**. Os passos de preservação de caminhos dos outros guias de migração não se aplicam.

O zurg pode substituí-lo de duas formas. Use uma delas ou as duas.

- **Continuar com o Stremio.** O zurg tem um [addon do Stremio](../guides/stremio.md) próprio. Ele pesquisa seus indexadores Newznab quando você aperta play e transmite o lançamento que você escolher pela sua conta de news. É assim que o streamnzb também funciona.
  Não precisa de nada além do zurg. Sem rclone e sem servidor de mídia. Todo lançamento reproduzido desta forma também fica guardado na biblioteca do zurg.
- **Montar uma biblioteca.** O zurg guarda os lançamentos que tem em uma biblioteca e a monta para Plex, Jellyfin ou Emby. Sonarr e Radarr podem preenchê-la. O próprio zurg também pode, a partir da sua watchlist.

Algumas coisas que o streamnzb fazia não têm equivalente no zurg. Este guia diz quais são.

Este guia é mais curto que os seus irmãos porque o problema é menor.

## O que precisa ser escaneado de novo e que conteúdo novo aparece {#what-needs-rescanning-and-what-new-content-shows-up}

As duas perguntas que os [outros guias de migração](index.md) respondem não se aplicam muito aqui. Vale explicar o motivo em vez de deixar você na dúvida.

**Não precisa reescanear nada, porque não há nada para reescanear.** O streamnzb não tem biblioteca, e o Plex não tem itens ligados a nenhum caminho. Então, nada da proteção contra lixeira da página compartilhada é essencial para você. Não há item antigo para preservar e nada que possa ser jogado na lixeira por um erro.

**Tudo é conteúdo novo.** Tudo o que você colocar em `nzbs/` do zurg será um primeiro escaneamento em uma biblioteca vazia. Configure suas bibliotecas do jeito que você quer antes da primeira varredura, em vez de consertar depois. Vale deixar duas configurações prontas antes.

- [`only_show_the_biggest_file: true`](../reference/config.md) nos diretórios que suas bibliotecas de mídia escaneiam. Sem isso, você verá clipes de amostra, arquivos `.nfo` e os arquivos `.url` de propaganda do poster.
- "Generate video preview thumbnails" **desativado** nessas bibliotecas. Em um mount de streaming, cada passagem de miniaturas lê o lançamento inteiro e consome sua franquia de Usenet. Um primeiro escaneamento entrega a biblioteca inteira ao Plex de uma vez.

---

(Uma tradução anterior foi rejeitada: os alvos dos links estavam diferentes. Mantenha a estrutura exatamente como está.)

## A mudança de modelo {#the-model-change}

| | streamnzb | zurg |
|---|---|---|
| Content acquisition | Pesquisa indexadores Newznab a cada pedido de reprodução | O [addon do Stremio](../guides/stremio.md) pesquisa indexadores Newznab a cada pedido de reprodução. Uma biblioteca também é preenchida a partir de arquivos `.nzb` e do endpoint SABnzbd, e da [aquisição](../guides/acquisition.md) |
| Ranking and selection | Traits do jhin, perfis de filtro e uma checagem no AvailNZB | Primeiro a resolução e depois uma variedade de tamanhos em cada resolução. Sem traits e sem perfis de filtro |
| Retention | Nada é guardado. Cada reprodução é uma busca nova | Biblioteca persistente. Um release reproduzido pelo addon permanece nela |
| Client | Stremio. O addon também é o provedor de metadados | Stremio pelo addon do zurg, que responde apenas com streams. Qualquer servidor de mídia sobre o mount. Ou WebDAV direto para o Infuse |
| Filesystem | Nenhum | Mount rclone FUSE mais WebDAV mais um índice HTTP simples |
| Archives | RAR e 7z **somente STORE**. Releases compactados não reproduzem | RAR e 7z compactados são transmitidos de forma transparente |
| Obfuscated posts | Recusados | Nomes recuperados dos cabeçalhos yEnc e do PAR2. O conteúdo é apresentado com o nome do release |
| Damaged posts | Pulados via AvailNZB | O reparo PAR2 reconstrói artigos faltantes. O addon pula um release cujo início sumiu e tenta o próximo |
| SABnzbd API | Não. Tem um proxy NNTP na porta 119 no lugar | Sim, e opcional. Cada envio é verificado nos servidores de notícias. Um post morto é reconstruído a partir do PAR2 quando possível e marcado como Failed quando não é |

No dia a dia, o Stremio pode continuar como está. Adicione o addon do zurg e escolha um título do jeito que você já fazia. O zurg pesquisa seus indexadores e reproduz o que você escolher. A [página do Stremio](../guides/stremio.md) cobre a configuração. A primeira reprodução de um release espera enquanto o zurg busca o NZB e lista o release. Costuma levar alguns segundos. Todas as reproduções seguintes desse release começam na hora.

Uma biblioteca para o seu servidor de mídia precisa de algo para preenchê-la.

- **O endpoint do SABnzbd.** Definir `sabnzbd.enabled: true` faz o zurg responder ao Sonarr e ao Radarr como um cliente de download. A importação é um rename dentro de `__magic__`. O envio cai em `__magic__/__all__`. A importação move o arquivo de lá para a pasta raiz que você criou ao lado. Nada é copiado. A maioria das configurações de biblioteca deve usar isso. Veja [Sonarr & Radarr](../guides/sonarr-radarr.md). O zurg verifica cada envio nos servidores de notícias antes de informar que terminou. Ele pergunta sobre o início e o fim de cada arquivo. Também baixa o primeiro artigo de cada arquivo. São até sessenta e quatro deles, mais alguns a mais em um release com poucos arquivos. Alguns servidores de notícias ainda dizem que um artigo existe depois que o conteúdo foi retirado, e só um download mostra isso. O zurg reconstrói um release com artigos faltando a partir dos seus arquivos PAR2 sempre que possível. Um que não pode ser reconstruído é marcado como **Failed**. Os \*arrs então o colocam na blocklist e pegam outro.
- **Aquisição.** O zurg pode buscar pedidos por conta própria. Eles vêm da sua watchlist do Plex e do Seerr e dos \*arrs. Ele pesquisa seus indexadores Newznab e verifica cada envio do mesmo jeito. Veja [aquisição](../guides/acquisition.md).
- **Depósito manual.** Baixe o `.nzb` no site do seu indexador e copie para `nzbs/`. O nome é fixo, o diretório é reescaneado a cada 15 segundos aproximadamente, e os arquivos nunca são movidos nem consumidos. Sempre funciona e é a base mais honesta.
- **Blackhole "Usenet" do Sonarr e do Radarr.** Os \*arrs podem ser configurados com um cliente de download Blackhole cuja *Nzb Folder* é o `nzbs/` do zurg. Isso devolve a automação de busca e captura, sem o endpoint, com um custo. O \*arr espera que um download concluído apareça na sua pasta de monitoramento e então o importa. O zurg nunca produz um, porque o release aparece no mount. Assim, a fila do \*arr mostra o item como se nunca terminasse. Você tem entrega automática de NZB em vez do pipeline de importação e renomeação do \*arr. O lado do \*arr não foi rechecado para o guia. O lado do zurg foi verificado no código em `internal/nzb/provider.go:30`.
- **O RSS do próprio indexador ou o download de carrinho para um diretório.** Isso depende totalmente do indexador e de você criar um script para o download. Não verificado e mencionado apenas porque alguns indexadores oferecem essa opção.

**Dê um nome ao arquivo antes de soltá-lo.** A pasta do release no mount recebe o nome do *nome do arquivo* NZB. O cabeçalho `<meta type="name">` só é usado quando o nome do arquivo parece um hash. Isso foi medido nos cinco servidores em 2026-08-19. Um arquivo chamado `indexer_download_48213.nzb` não dá nada para o Plex casar, então renomeie-o para o nome do release primeiro. Isso também significa que o nome da pasta fica totalmente sob o seu controle. Dois releases diferentes com o mesmo nome recebem o sufixo ` {shorthash}`.

## Configurações que continuam valendo {#configuration-that-carries-over}

O primeiro é o provedor Usenet. O streamnzb configura provedores em **Settings → Providers**, com host, porta, usuário, senha e conexões. Variáveis de ambiente também funcionam. A mesma conta vira o bloco `nntp` do zurg.

Antes, no streamnzb. Esta é a forma com variáveis de ambiente e as chaves documentadas.

```
PROVIDER_1_HOST=news.example.com
PROVIDER_1_PORT=563
PROVIDER_1_SSL=true
PROVIDER_1_USERNAME=USERNAME
PROVIDER_1_PASSWORD=PASSWORD
PROVIDER_1_CONNECTIONS=30
PROVIDER_1_PRIORITY=1
```

Depois, no `config.yml` do zurg.

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true            # streamnzb's SSL flag
      username: USERNAME
      password: PASSWORD
      connections: 30      # your plan's real allowance and the tuning knob
      cache_size_mb: 512
```

Um segundo provedor do streamnzb, como `PROVIDER_2_*`, vai dentro de `nntp.servers`. Assim o zurg vai testando as contas uma após a outra, artigo por artigo. `priority` corresponde diretamente. O zurg tem dois conceitos que o streamnzb não tem. Com `backup: true`, você marca uma conta de bloco pago que só é consultada quando todos os primários respondem *no such article*. Já `backbone` evita que duas contas do mesmo spool façam a mesma pergunta duas vezes. Só é permitida uma entrada de provedor `nzb`. As contas Usenet extras ficam dentro dela, e não ao lado.

O segundo são os seus indexadores. Eles vão em `stremio.indexers`, com a mesma URL e a mesma chave de API. A aquisição usa essa mesma lista quando não tem uma própria.

```yaml
stremio:
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
```

Nada mais do `data/config.json` do streamnzb é transferido. Os blocos `streams` e `filter_profiles` moldavam o que o addon do streamnzb oferecia. O addon do zurg tem uma lista por título e o próprio ranqueamento. Os ajustes mais próximos são dois. `max_size_gb` descarta releases acima de um tamanho. `max_results` define quantos releases cada resolução mantém. A [página do Stremio](../guides/stremio.md) tem o restante.

## Histórico de exibição {#watch-history}

streamnzb guarda o histórico de reprodução de cada stream no banco de dados. Por padrão é SQLite, em `data/streamnzb.db`, mas também dá para usar Postgres. É a partir dele que ele monta as linhas Continue Watching e Because You Watched. A documentação descreve o conteúdo como "library, search and play history, bad releases, and metrics".

**Nada disso é portável para uma biblioteca do Plex.** O estado de visualização do Plex fica por item, no banco de dados do próprio Plex, e está vinculado a itens que precisam existir antes em uma biblioteca. Não existe importador em nenhum dos lados. Na prática, isso não é bem uma perda de dados e sim um desencontro entre dois modelos. Os registros de histórico do streamnzb apontam para buscas e streams, e não para arquivos. Se você quiser guardar esse registro antes de desativar tudo, o banco é SQLite simples e pode ser lido diretamente.

```bash
sqlite3 data/streamnzb.db .tables
sqlite3 data/streamnzb.db "select * from <table> limit 20;"
```

Os nomes exatos das tabelas não estão documentados e não foram verificados para este guia. Use `.tables` para descobri-los. No Postgres, os mesmos dados ficam no banco apontado por `DATABASE_URL`. O estado de visualização na sua nova configuração começa do zero e vai sendo acumulado no Plex a partir da primeira reprodução.

---

## O que você ganha {#what-you-gain}

- **Uma biblioteca de verdade.** Plex, Jellyfin e Emby leem um sistema de arquivos e guardam metadados e o estado de visualização em todos os clientes que suportam. Não é só o Stremio.
- **Reparo com PAR2.** Uma release com artigos faltando é reconstruída a partir dos próprios arquivos de recuperação, em segundo plano. A resposta do streamnzb para uma release ruim era pular ela. A do zurg é consertar.
- **Releases ofuscadas.** O zurg recupera os nomes de arquivo reais a partir dos cabeçalhos yEnc e do índice PAR2, e apresenta um payload totalmente ofuscado com o nome da release. Medido na bancada onde `Obfuscated.nzb` entregou um `Toy.Story.5.2026...KyoGo.mkv` limpo. O streamnzb recusa esses casos de cara.
- **RAR e 7z compactados.** O streamnzb transmite apenas arquivos STORE, e o README dele é explícito: "Compressed RAR releases will not play". O zurg transmite o vídeo de dentro de arquivos compactados e reproduz a estrutura de diretórios interna enquanto faz isso.
- **Segunda reprodução começa na hora.** O streamnzb buscava e verificava a cada reprodução. O zurg guarda o que você já assistiu. Uma release que já está na biblioteca toca imediatamente. Tudo que o Sonarr ou o Radarr baixa já fica nesse estado desde o início.
- **Profundidade com várias contas.** Prioridades, contas `backup` com cobrança por uso, deduplicação com `backbone` e um caminho de reparo quando todas as contas falham.

## O que você perde {#what-you-lose}

- **jhin e perfis de filtro.** O addon do zurg também pesquisa nos seus indexadores. Ele classifica só por resolução e tamanho. Não existem características de jhin, perfis de filtro nem pontuações.
- **A verificação do AvailNZB.** O zurg não pergunta a mais ninguém se uma release está viva. O addon descobre isso lendo o início da release que você escolheu. Quando esse início some, ele passa para a próxima release da lista. Um download enviado pelo Sonarr ou Radarr é verificado nos seus servidores de notícias antes de ser considerado concluído. Danos mais para o meio de um arquivo só aparecem quando uma leitura chega até eles. Aí o reparo PAR2 reconstrói o arquivo, desde que a postagem tenha dados de recuperação suficientes. Em 2026-08-19, um conjunto RAR com volumes inteiros faltando aparecia como uma pasta vazia, e não como erro.
- **Catálogos e linhas do streamnzb.** Os catálogos e metadados embutidos dele, e as linhas Continue Watching e Because You Watched, vinham do próprio histórico. O addon do zurg responde apenas streams. Um servidor de mídia tem suas próprias versões dessas linhas para a biblioteca.
- **O proxy NNTP na porta 119.** Se o SABnzbd ou o NZBGet apontavam para o streamnzb como servidor de notícias, agora eles precisam das credenciais reais do provedor de novo.

---

## Subindo o zurg {#standing-up-zurg}

A `config.yml` que funciona só com Usenet.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30          # the plan's full allowance once streamnzb is gone
      cache_size_mb: 512

enable_repair: true            # PAR2 repair does not run without this
par2_patch_cache_mb: 512

stremio:                       # keeps Stremio working. Leave it out for a library alone
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY

mount_path: "/mnt/zurg"
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run

directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

Não use filtros `tags_match_any` para conteúdo Usenet. As tags `zurg_*` vêm do ffprobe, e o ffprobe nunca roda neste backend. Uma pasta assim simplesmente nunca vai ter um release Usenet. Filtre por nomes, extensões, tamanhos e `has_episodes`.

Depois, inicie.

```bash
./zurg               # startup verifies the news account and says so, loudly, and makes nzbs/
ls /mnt/zurg/__all__/
```

Se o Usenet é a sua única conta, a pasta `__nzb__` fica de fora da listagem da raiz do mount, e `__all__` tem os mesmos arquivos. Então teste a reprodução em `__all__` no mount, ou abra o caminho HTTP direto `http://localhost:9999/http/__nzb__/`. As subpastas de `nzbs/` são ignoradas, e `.nzb.gz` não é lido.

### A primeira biblioteca do Plex {#the-first-plex-library}

Aponte as bibliotecas para **subpastas** do mount, como `/mnt/zurg/movies` e `/mnt/zurg/shows`. Nunca para a raiz. A mesma release aparece em `__all__` e em cada pasta correspondente, então escanear a raiz faria o Plex ler tudo várias vezes. Se o Usenet for sua única conta, `__nzb__` não aparece na listagem da raiz do mount e não resolve através dele, já que `__all__` tem os mesmos arquivos. Informe ao zurg `plex_server_url` e `plex_token` para que ele possa pedir scans parciais.

Duas configurações da biblioteca importam desde o primeiro scan, seja ela nova ou não. O problema que elas evitam é o mount falhar *durante* um scan.

1. **Desmarque "Empty trash automatically after every scan"** para que `autoEmptyTrash` fique em 0. Se o mount sumir no meio do scan, o Plex conclui que todos os arquivos foram apagados. Basta um restart do zurg ou um remount do rclone para isso acontecer. Com o esvaziamento automático ligado, os itens são removidos de forma permanente e imediata. Com ele desligado, ficam na lixeira e voltam quando o mount voltar. Isso já custou dezenas de milhares de itens antes.
2. **Desmarque "Generate video preview thumbnails".** No Usenet, cada passada de miniaturas é uma leitura completa da release inteira, e isso consome sua franquia de conexão.

E nunca reinicie o zurg enquanto o Plex estiver escaneando. Antes de tudo, verifique que ambas as configurações estão em zero.

```bash
TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

Use `grep -o … | wc -l` em vez de `grep -c`. O grep sai com código de erro diferente de zero quando não encontra nada, e nesse caso isso é o *bom* resultado. Ele interrompe uma cadeia `&&` ou um script com `set -e` logo antes do restart que deveria proteger.

Os tamanhos dos arquivos se ajustam um pouco depois que uma release aparece pela primeira vez. Um NZB não informa o tamanho de cada arquivo. Por isso, a primeira listagem estima o tamanho a partir dos tamanhos dos artigos que o NZB registra. Essa estimativa pode ficar até cerca de 3 por cento acima do real. Depois disso, o zurg descobre o tamanho exato em segundo plano e passa a usá-lo. Um scan que tenha rodado antes disso vê a estimativa. O Plex então considera o arquivo modificado e o analisa de novo uma vez. Nada é apagado.

## Rodando os dois lado a lado {#running-both-side-by-side}

Nenhuma porta colide. O streamnzb usa a 7000 e a 119, e o zurg usa a 9999. Então a transição mais simples é manter o streamnzb servindo o Stremio enquanto a biblioteca do zurg se enche.

O único recurso compartilhado é a conta de news. **Os dois leem do mesmo limite de conexões, e o provedor aplica esse limite nos dois.** Um plano com 50 conexões não pode rodar o streamnzb com 50 e o zurg com 30. O excedente recebe conexões recusadas, e do lado do zurg isso aparece como streams lentos ou travando. Divida o limite explicitamente. Tente `PROVIDER_1_CONNECTIONS=20` no streamnzb e `connections: 30` no zurg. Quando você desligar o streamnzb, dê ao zurg o limite completo, porque a velocidade de um único stream no zurg é definida por esse número.

Quando você desligar o streamnzb, remova o addon dele do Stremio em todos os seus clientes. Guarde uma cópia de `data/` se quiser manter o histórico. O `config.json` e o `streamnzb.db` são todo o estado dele. Depois, aponte de volta para o seu provedor diretamente qualquer coisa que usava o proxy NNTP na porta 119.
