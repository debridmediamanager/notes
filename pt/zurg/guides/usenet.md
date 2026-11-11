# Usenet com o zurg {#usenet-with-zurg}

zurg-nzb

Como o backend `nzb` do zurg transforma arquivos `.nzb` em uma biblioteca montada. Não há downloader nem pasta de concluídos.
Nada é baixado antes de reproduzir. Ele guarda os NZBs e caches limitados em `data/bytecache` e `data/par2`,
além de registros de índice. `nzb_article_disk_cache_mb` vem com padrão de 512 MiB. Ao fazer um seek, o zurg busca apenas os artigos
que cobrem aqueles bytes. Um remux de 60 GB não precisa de 60 GB de disco.

Usenet usa os mesmos filtros de biblioteca, mount e integração com servidor de mídia que os backends de debrid. Conteúdo de Usenet pode
ficar junto com conteúdo do Real-Debrid ou TorBox. Você pode usar só Usenet.

**Vários provedores de Usenet são suportados.** Uma entrada `nzb` pode ter quantas contas de notícias você quiser — provedores ilimitados, contas de bloco, o que você tiver — e o zurg faz fallback entre elas artigo por artigo. Isso importa mais aqui do que redundância costuma importar: a retenção é por provedor, então uma segunda conta muitas vezes é a diferença entre buscar mais um artigo e reconstruir um release inteiro a partir do PAR2. Veja [Mais de um provedor de Usenet](#more-than-one-usenet-provider).

Este guia cobre contas de notícias, NZBs, o mount e o Plex.

| | |
|---|---|
| Referência de configuração | [config.md → Usenet accounts](../reference/config.md#usenet-accounts) |
| Dashboard | `http://localhost:9999/config/` → Essentials → Providers |
| Onde fica o código | `internal/nzb` (backend), `internal/nntp` (cliente de notícias), `internal/par2` (matemática de reparo) |
| Pasta de monitoramento | `nzbs/`, no diretório de trabalho do zurg (`/config` no Docker) |
| Cache de reparo | `data/par2/` |
| Nomes resolvidos | `data/nzb-names/`, para que um release ofuscado seja lido pelos nomes uma vez, e não uma vez a cada reinício |
| Índice de artigos | `data/nzb-index/`, sob `nzb_segments: mmap` — o padrão no Linux, macOS e BSD |

---

## O que você precisa {#what-you-need}

- **Pelo menos uma conta de provedor Usenet.** A retenção é o que mais importa — um provedor com 4000+ dias ainda terá posts que um provedor de 1000 dias já apagou. A sua *franquia de conexões* do plano é o segundo número que você precisa saber; é com ele que o zurg trabalha.
- **Mais contas, se você tiver.** Um segundo provedor ilimitado em um backbone diferente, ou uma conta barata de blocos para preencher as lacunas, é a coisa de maior valor que você pode adicionar a uma configuração Usenet — veja [Mais de um provedor Usenet](#more-than-one-usenet-provider).
- **Arquivos NZB ou algo que os busque.** Baixe-os do seu indexador e coloque-os em `nzbs/`. Ou ative o [endpoint compatível com SABnzbd](sonarr-radarr.md) e deixe o Sonarr e o Radarr enviarem os arquivos para ele. Ele grava no mesmo diretório. O zurg também consegue pesquisar nos seus indexadores Newznab sozinho. Ele faz isso quando você aperta play no [Stremio](stremio.md). Também faz isso para pedidos da sua watchlist e do Seerr e dos \*arrs através da [aquisição](acquisition.md). Os torrents de uma conta debrid têm um endpoint próprio que fala [qBittorrent](sonarr-radarr-torrents.md).
- **zurg**, mais o `rclone` se você quiser um mount de sistema de arquivos em vez de usar o WebDAV diretamente. O zurg baixa o rclone para você na primeira execução.

---

## 1. Configure suas contas de notícias {#1-configure-your-news-accounts}

Cada conta no zurg é uma entrada em `providers:`. Uma conta Usenet faz autenticação com credenciais do servidor em vez de um token de API, então ela tem um bloco `nntp` no lugar de `token`:

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 30        # your plan's allowance — see below
      cache_size_mb: 512     # decoded articles held in memory, across all files
```

É só isso. Adicione contas debrid ao lado dela, se você tiver:

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: nzb
    nntp:
      host: news.example.com
      ...
```

| Chave | Padrão | Observações |
|---|---|---|
| `host` | *(obrigatório)* | O servidor de notícias. Um host ausente ou vazio gera erro na inicialização. |
| `port` | `563` com TLS, `119` sem | |
| `tls` | `false` | Ative. NNTP sem criptografia envia sua senha em texto puro e suas leituras para qualquer pessoa no caminho. |
| `username` / `password` | `""` | |
| `connections` | `8` | **Defina isso como o limite real do seu plano.** Não é um limite de taxa com o qual você precise ser educado: uma única conexão carrega uma fração da velocidade de um provedor, então o zurg lê nesse número. Baixo demais e o streaming fica lento; acima do limite do plano e o servidor começa a recusar conexões. |
| `warm_connections` | `4` | Conexões ociosas e autenticadas mantidas abertas para que uma leitura nunca espere por uma nova conexão. Abrir uma conexão leva cerca de 0,8s entre TCP, TLS, saudação e `AUTHINFO`, e sem um piso isso era pago no caminho de demanda após cada início e cada período de inatividade. Elas saem de `connections` em vez de serem extras — o plano conta essas conexões como abertas, e o zurg as mantém vivas com um `DATE` periódico — então o piso é limitado pelo limite. `-1` não mantém nenhuma, o que é o ideal para um plano cobrado por tempo de conexão. O `warm_connections` no nível superior define o padrão para uma conta que não informa nenhum — veja [conexões aquecidas](../reference/config.md#warm-connections). |
| `cache_size_mb` | `512` | Dados de artigos decodificados mantidos em memória, compartilhados entre todos os arquivos sendo lidos, em vez de por arquivo. |
| `servers` | `[]` | Contas de notícias adicionais — veja [Mais de um provedor Usenet](#more-than-one-usenet-provider). |

Duas regras que o validador de configuração aplica:

- **Apenas uma entrada de provedor `nzb` habilitada.** Duas escaneariam o mesmo diretório `nzbs/` e duplicariam cada release. Isso não é um limite de quantos *provedores Usenet* você pode usar — contas de notícias extras vão em `nntp.servers` dessa única entrada, onde atendem à mesma biblioteca em vez de uma segunda cópia dela.
- **`watchlist: true` não pode apontar para ela.** O backend Usenet não consegue adicionar conteúdo, então nunca pode ser a conta onde uma adição da watchlist do Plex vai parar.

### Mais de um provedor de Usenet {#more-than-one-usenet-provider}

A retenção é por provedor, e a diferença entre um download extra e uma reconstrução completa do release com PAR2 é se alguma outra conta ainda tem o artigo. Por isso, uma segunda conta vale mais aqui do que a redundância costuma valer.

As chaves que já estão no bloco `nntp` descrevem a primeira conta. Tudo o que estiver em `servers` é outra conta. Contas com o mesmo `priority` dividem a carga, um número maior só é consultado depois dos menores, e uma conta `backup` só é usada depois que todas as primárias falharam em entregar o artigo. Uma configuração existente com uma única conta continua funcionando sem mudanças:

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # first account: the workhorse
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com   # different backbone = different retention
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com              # metered — only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

Cada conta mantém o próprio limite de conexões, e as leituras são controladas pelo **limite combinado das contas não-backup que compartilham o menor `priority` ativo** — 30 + 20 = 50 no exemplo acima, em que ambas estão no priority padrão. Um segundo provedor ilimitado no mesmo priority, portanto, traz throughput além de seguro de retenção. Uma conta `backup` não traz nenhum dos dois, por design: ela só carrega o que as primárias não conseguiram fornecer, e contá-la aumentaria cada janela de leitura antecipada por uma capacidade que a reprodução em regime nunca usa.

Três chaves definem quem é consultado:

| Chave | Padrão | Efeito |
|---|---|---|
| `name` | valor de `host` | Dá um rótulo à conta nos logs. |
| `priority` | `0` | Quem é consultado primeiro, do menor para o maior. Contas com o mesmo priority são consultadas na ordem em que foram escritas, exceto que uma com conexão livre é preferida a uma cujo limite já foi esgotado. Assim, duas contas iguais dividem a carga em vez de formar fila em uma só. |
| `backup` | `false` | Marca uma conta de bloco medida, consultada somente quando todas as primárias informaram que não têm o artigo, enviaram uma cópia danificada, falharam no meio do caminho ou não puderam ser alcançadas. Uma primária apenas **ocupada** não basta: o zurg espera por ela em vez de gastar bytes medidos com algo que uma conta ilimitada teria atendido. |
| `backbone` | `""` | Dá nome ao spool de artigos ao qual a conta se conecta. Duas contas no mesmo backbone têm os mesmos artigos, então, assim que uma delas informa que não tem um artigo, as outras no mesmo spool são puladas, em vez de gastar uma viagem de ida e volta com a mesma resposta. |

Cada conta também mantém um piso de conexões aquecidas próprio, tirado do próprio limite: uma lacuna de retenção manda a leitura direto para além da primária, então a conta acessada pela primeira vez é exatamente aquela cuja conexão ninguém ainda pagou. Uma conta de bloco com duas conexões pode ser configurada para não ter nenhuma, com `warm_connections: -1`.

A revenda é comum, então vale preencher `backbone`: duas contas compradas de empresas diferentes podem estar no mesmo spool, e sem ele cada falta é pedida duas vezes. Agrupe-as com o nome que preferir. A string só é comparada com outras entradas.

Na inicialização, o zurg identifica cada conta que vai usar:

```
Usenet account nzb connected: nntps://unlimited.example.com:563 (30 connections) + nntps://second-unlimited.example.com:563 (20 connections) [usenetexpress] + nntps://block.example.com:563 (10 connections) [backup] [omicron]
```

O levantamento que decide se um release precisa de reparo pergunta a todas as contas antes de dar um artigo como faltante, e pergunta a cada uma apenas sobre o que as anteriores não tinham. Uma falha de transporte nunca é confundida com um artigo expirado: se uma conta deu timeout ou perdeu o artigo no meio do caminho, é essa falha que é reportada. Assim, um timeout nunca faz com que o silêncio seja servido e um reparo seja agendado para algo que nunca tinha sumido. Uma conta que não pôde ser alcançada de jeito nenhum não conta: se outra conta disser que o artigo sumiu, ele é tratado como sumido.

### Configurando provedores no Dashboard {#configuring-providers-in-the-dashboard}

`http://localhost:9999/config/` → **Essentials** → **Providers** faz a mesma coisa sem editar YAML. A tabela lista todas as contas na ordem do config:

```
#  Name        Type        Token                Flags
1  realdebrid  realdebrid  …DFFND4OA            —          [Edit] [Delete]
2  nzb         nzb         news.example.com     —          [Edit] [Delete]
```

Para uma linha `nzb`, a coluna Token mostra o **host do servidor de news** em vez de uma dica de token, já que não há token para ocultar. Depois vem quantos outros servidores de news ela tem.

**Para adicionar uma conta Usenet:**

1. Clique em **Add provider**.
2. Defina **Type** como `nzb`. Os campos de token somem e os campos NNTP aparecem no lugar deles.
3. Deixe **Name** vazio, a menos que queira algo diferente de `nzb`. Esse nome é o da pasta da conta, então `usenet` aqui resulta em `__usenet__` no mount.
4. Preencha **NNTP host**, **Port**, **TLS** (marcado por padrão, deixe ativado), **Username**, **Password**, **Connections** (placeholder `8`; coloque aqui o limite real do seu plano) e **Cache size MB** (placeholder `512`).
5. Deixe **Watchlist target** desmarcado. O backend não consegue adicionar conteúdo, e salvar com ele marcado é rejeitado. **Disabled** mantém a entrada no `config.yml` sem carregá-la.
6. Clique em **Save**.

O formulário é validado como se a edição já tivesse sido aplicada, então erros aparecem como um alerta e não como um config quebrado. Adicionar um **segundo** provedor `nzb` é recusado nessa tela. A mensagem de erro aponta para **Further news servers** (ou `nntp.servers`), que é onde ficam as contas de news adicionais.

**Para adicionar outro servidor de news**, seja uma segunda conta ou uma conta de bloco em outro backbone, clique em **Edit** na linha `nzb` e depois em **Add news server** em **Further news servers**. Cada servidor tem seu próprio **Name**, **NNTP host**, **Port**, **TLS**, **Username**, **Password**, **Connections**, **Priority**, **Backbone** e **Backup only**. **Remove server** remove um deles. **Save** grava todos em `nntp.servers`.

**Para editar um**, clique em **Edit** na linha dele. O formulário carrega tudo, exceto as senhas, tanto a da primeira conta quanto a de cada servidor adicional. Elas ficam em branco e significam *manter a existente*. Digite uma nova senha só se quiser trocá-la. As configurações que o formulário não tem campo para elas são mantidas como estão no `config.yml`.

**Delete** pede confirmação e depois remove a entrada do provedor do `config.yml`. Ele não mexe no seu diretório `nzbs/`: os arquivos NZB continuam onde estão e voltam junto com o provedor. O último provedor habilitado não pode ser deletado nem desabilitado.

Toda alteração feita aqui é gravada direto no `config.yml` e mostra:

> Provider changes saved to config.yml — restart zurg to apply

As edições de provedores **não** são recarregadas a quente. Reinicie o zurg antes de esperar que algo mude.

## 2. Inicie o zurg e confirme as contas {#2-start-zurg-and-confirm-the-accounts}

+++ Linux e macOS
```bash
./zurg
```
+++ Windows
```powershell
.\zurg.exe
```
+++

Se `zurg setup` instalou o zurg para iniciar sozinho, reinicie-o com `zurg service restart`, use `./zurg service restart` (ou `.\zurg.exe service restart` no Windows).

O zurg verifica as contas de Usenet uma vez na inicialização, porque uma senha errada, de outra forma, aparece bem depois como todos os arquivos falhando ao reproduzir:

```
Usenet account nzb connected: nntps://news.example.com:563 (30 connections)
```

Uma falha total também é bem barulhenta:

```
Cannot reach the news server for nzb: <reason>
```

Verifique primeiro a porta e o pareamento de TLS (`563`+`tls: true`, ou `119`+`tls: false`), depois as credenciais e, por último, se o plano está realmente ativo.

**Com várias contas, leia os avisos, não só a linha de conectado.** Cada conta inacessível gera um aviso próprio, e a inicialização continua enquanto *uma* conta responder. O erro acima aparece só quando todas as contas estiverem inacessíveis. Então, um segundo provedor morto parece uma inicialização saudável, a menos que você perceba:

```
Usenet account block.example.com is not reachable: <reason>
```

---

## 3. Adicione arquivos NZB {#3-add-nzb-files}

O zurg cria a pasta de monitoramento `nzbs/` quando inicia. Ela fica na pasta de onde o zurg é executado. Copie os arquivos NZB para dentro dela.

+++ Linux e macOS
```bash
cp ~/Downloads/Some.Release.2024.2160p.nzb nzbs/
```
+++ Windows
```powershell
Copy-Item "$HOME\Downloads\Some.Release.2024.2160p.nzb" nzbs\
```
+++

Em um ou dois segundos o zurg percebe o arquivo e o lê, e a biblioteca o lista assim que a leitura termina. O log mostra o que foi lido:

```
Loaded NZB Some.Release.2024.2160p.nzb: 94 files
```

### Quão rápido aparece {#how-quickly-it-appears}

zurg observa a pasta `nzbs/` por conta própria, fazendo uma checagem por volta de um segundo que custa uma única syscall, não importa quantos NZBs a pasta tenha. Assim, um arquivo que chega nela é lido quase imediatamente, e não só na próxima checagem de mudanças da biblioteca. Uma [release ofuscada](#obfuscated-releases) demora um pouco mais, porque seus nomes de arquivo reais precisam ser lidos dos próprios artigos antes, normalmente bem abaixo de um segundo, e ela aparece na lista assim que isso termina. Nenhuma dessas esperas depende mais de `check_for_changes_every_secs`. Antes dependia: uma release ofuscada demorava até dois intervalos inteiros para aparecer depois de ser colocada na pasta. Um intervalo era para a pasta ser lida, e outro porque os nomes tinham sido resolvidos logo depois da checagem que deveria tê-la notado. Medido com um intervalo de 10 segundos, isso dava 17,7 segundos desde a colocação do arquivo até a release aparecer, dos quais 0,67 segundo era o trabalho em si.

A checagem periódica continua existindo e segue sendo a rede de segurança. Ela pega as duas coisas que uma pasta observada não consegue reportar sozinha: um NZB **substituído no lugar** com um nome que ele já tinha, e um sistema de arquivos cujos timestamps de diretório são grossos demais para separar duas mudanças feitas no mesmo segundo.

### O que é captado {#what-gets-picked-up}

- Arquivos **diretamente dentro de `nzbs/`** cujo nome termine em `.nzb`, sem diferenciar maiúsculas de minúsculas.
- **Subpastas são ignoradas.** `nzbs/movies/foo.nzb` fica invisível. Deixe tudo na mesma pasta em vez de organizar em subpastas: a organização da biblioteca vem dos filtros de diretório, não desta pasta.
- **Somente XML puro.** `.nzb.gz` não é descompactado nem lido; descompacte antes.
- Um arquivo que não puder ser analisado é ignorado com um aviso, e isso não interrompe a varredura.

### Como se chama o release {#what-the-release-is-called}

O nome que o zurg mostra, e portanto a pasta que o Plex enxerga, é:

1. o valor de `<meta type="name">` do próprio NZB, se ele tiver um e ele sobreviver à sanitização, senão
2. **o nome do arquivo sem o `.nzb`**.

Então, na maioria das vezes, *o nome do arquivo NZB é o nome do release*. Nomeie o arquivo do jeito que você nomearia o release, porque é isso que o seu servidor de mídia vai tentar casar:

```bash
# good
nzbs/Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb

# bad — Plex has nothing to work with
nzbs/indexer_download_48213.nzb
```

Dois releases diferentes que acabem com o mesmo nome são diferenciados por uma tag de hash curta (`Some.Release {a1b2c3}`), igual em qualquer outro lugar do zurg.

### Releases protegidos por senha {#password-protected-releases}

Se o indexador gravou a senha do arquivo no bloco de metadados do NZB, o zurg usa essa senha ao fazer o streaming do conjunto RAR:

```xml
<head>
  <meta type="password">thepassword</meta>
</head>
```

Não precisa de mais nada. Uma release protegida cujo NZB não tem metadado de senha não pode ser aberta.

### Releases ofuscados {#obfuscated-releases}

Posts com nomes de arquivo aleatórios são tratados, com um custo pago uma única vez na hora do scan. O zurg tenta primeiro a fonte mais barata: o nome que o artigo ainda declara no próprio cabeçalho yEnc, um artigo por arquivo. Se isso não funcionar, ele usa o índice PAR2 da release, que registra o nome verdadeiro de cada arquivo junto com o MD5 dos seus primeiros 16 KiB. O nome e o tamanho exato estão no cabeçalho do artigo, então o scan pode responder assim que esse cabeçalho chegar, enquanto o corpo continua sendo gravado no cache para uma leitura futura. Assim, uma release ofuscada recebe nome e tamanho pelos mesmos artigos. O zurg registra o que recuperou:

```
Recovered 27 filename(s) in Some.Release
```

Toda a etapa de nomeação tem limite de 90 segundos por NZB, então um servidor inacessível atrasa o scan em vez de travá-lo. Os nomes são definidos *antes* de a biblioteca ser montada a partir deles, porque a biblioteca identifica os arquivos pelo nome, e uma renomeação posterior faria esses arquivos se perderem.

**Um post totalmente ofuscado não tem um nome real para recuperar.** Alguns posters ofuscam antes de montar o conjunto de recuperação, então o índice PAR2 restaura nomes que também são aleatórios (`aJPSgA7eYizyzjJXT.part01.rar`), e o arquivo dentro do archive também é um hash. Nada no post sabe qual é a release. Só o nome do próprio NZB revela isso. Por isso, o zurg apresenta o conteúdo com o nome da release, a mesma coisa que o SABnzbd faz ao final da descompactação:

```
Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR/
└── Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR.mkv
```

Só é renomeado o arquivo que claramente é a release: a maior entrada do archive, e somente quando ela tiver pelo menos três vezes o tamanho da próxima, quando a extensão não fizer parte de uma estrutura de disco (`.vob`, `.m2ts`, `.mpls`) e quando o nome não disser nada. Legendas e amostras com o mesmo nome acompanham esse arquivo. Um archive com vários arquivos de tamanho parecido, como um pack de temporada, é deixado como está, porque nenhum deles é a release. Os nomes originais do archive continuam funcionando como endereços, então um player que começou antes de uma nova varredura não perde o arquivo.

### Substituindo e removendo {#replacing-and-removing}

- **Remover** um NZB de `nzbs/` tira a release da biblioteca, descarta o leitor em cache e o cache de artigos, e esquece quaisquer bytes reparados que ele guardava.
- **Apagar uma release Usenet pelo Dashboard apaga o arquivo `.nzb` do disco.** Não há outro lugar onde ele possa ficar. Isso não é o mesmo que apagar um torrent de uma conta debrid, onde o arquivo continua no serviço.
- **Substituir um NZB no lugar é o jeito mais lento.** Sobrescrever um arquivo não muda o diretório, então o monitoramento acima não consegue ver isso; quem percebe é a verificação periódica de mudanças, que lê a data de modificação do arquivo e o analisa de novo — na primeira checagem de `check_for_changes_every_secs` que acontecer mais de 15 segundos depois da última leitura do diretório (cerca de 30 segundos no padrão). Remover o arquivo antigo e adicionar o novo é percebido em um ou dois segundos, e é o que um indexador ou o endpoint do SABnzbd já faz de qualquer forma.

## 4. Onde os releases aparecem no mount {#4-where-releases-land-in-the-mount}

A release Usenet é uma entrada normal da biblioteca, então seus filtros `directories:` que já existem se aplicam a ela sem nenhuma mudança:

```yaml
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

Além deles, a conta ganha um diretório próprio: `__nzb__` por padrão, ou `__<name>__` se você definir `name:` na entrada do provedor. Esse diretório não é só uma visualização: as leituras dentro dele são **fixadas** na conta Usenet, sem failover, o que o torna o lugar certo para testar se a reprodução via Usenet funciona sem que uma conta debrid responda no lugar dela. Se o Usenet for sua única conta, essa pasta fica fora da listagem da raiz do mount e `__all__` contém os mesmos arquivos. Então teste a reprodução em `__all__` no mount, ou use o caminho HTTP direto `http://localhost:9999/http/__nzb__/`.

Quatro coisas específicas do Usenet para saber ao escrever os filtros:

- **Filtros de tag só batem com o conteúdo Usenet depois que ele é analisado.** Toda tag `zurg_*` (resolução, HDR, bitrate, duração, idioma) vem do ffprobe. O zurg roda o ffprobe nos arquivos Usenet por conta própria, pelo seu próprio servidor e num ritmo que o servidor de notícias aguenta, então uma release Usenet recebe as tags como qualquer outra depois de analisada. Até lá, um diretório baseado em `tags_match_any` não a inclui.
- **Arquivos `.par2` e `.sfv` ficam ocultos.** Eles são estrutura de reparo; o zurg os lê por conta própria e nenhum servidor de mídia tem uso para oito deles por pacote de temporada. O `.nfo` é mantido, porque Kodi, Emby e Jellyfin o leem.
- **Conjuntos RAR são conteúdo, não arquivos para descompactar.** Os `.rar` e `.rNN` continuam visíveis, e um conjunto de volumes aparece no mount como uma *pasta* cujo conteúdo são os arquivos de dentro dela. O zurg transmite o vídeo direto de dentro do arquivo, sem extrair nada. Uma release que é *só* um conjunto de volumes fica no lugar do próprio conteúdo, sem pasta de arquivo no meio: o arquivo de mídia fica diretamente na pasta da release, que é onde um servidor de mídia procura. Os arquivos publicados junto ao conjunto — o `.nfo`, o `.txt` do postador, artwork, legendas — também continuam listados ali.
- **`force_select_playable_files` não se aplica.** Um post Usenet é inteiro; não há o que selecionar. Todos os arquivos de conteúdo já são oferecidos.

Confira o resultado antes de envolver um servidor de mídia. `http://localhost:9999/http/` é um índice HTML simples com exatamente o que o mount vai mostrar:

+++ Linux e macOS
```bash
curl -s http://localhost:9999/http/__nzb__/ | head
```
+++ Windows
Digite `curl.exe`, não `curl`: no Windows PowerShell 5.1, `curl` é outro nome para `Invoke-WebRequest`.

```powershell
curl.exe -s http://localhost:9999/http/__nzb__/ | Select-Object -First 10
```
+++

---

## 5. Monte com o rclone {#5-mount-it-with-rclone}

### O caminho fácil: deixe o zurg executar o rclone {#the-easy-path-let-zurg-run-rclone}

```yaml
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run
mount_path: "/mnt/zurg"        # /Volumes/Zurg on macOS, Z: on Windows
```

zurg inicia o rclone com um perfil de VFS já ajustado para o padrão de leitura dele (tamanho do buffer, tamanho dos chunks, modo de cache, tempo do dir-cache, timeouts), mantém o mount ativo e invalida as entradas certas do dircache quando a biblioteca muda. O `mount_path` também é o prefixo que o zurg usa para dizer ao Plex quais caminhos escanear, então ele precisa estar definido mesmo se você montar em outro lugar.

Verifique:

+++ Linux
```bash
ls /mnt/zurg/
ls /mnt/zurg/__all__/
```
+++ macOS
```bash
ls /Volumes/Zurg/
ls /Volumes/Zurg/__all__/
```
+++ Windows
Execute no PowerShell na área de trabalho: a unidade só fica visível na sessão de login que a montou ([as regras de sessão](../setup/windows.md#keeping-it-running-the-session-rules)).

```powershell
Get-ChildItem Z:\
Get-ChildItem Z:\__all__\
```
+++

### O caminho manual: seu próprio rclone {#the-manual-path-your-own-rclone}

Se você já usa o rclone, aponte um remote WebDAV para o zurg:

```ini
[zurg]
type = webdav
url = http://localhost:9999/dav/
vendor = other
pacer_min_sleep = 0
```

+++ Linux
O rclone não cria o ponto de montagem, e `/mnt` pertence ao root:

```bash
sudo mkdir -p /mnt/zurg && sudo chown "$USER" /mnt/zurg
rclone mount zurg: /mnt/zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ macOS
Precisa do [macFUSE](../setup/macos.md#step-1-install-macfuse) e do rclone em [rclone.org](https://rclone.org/downloads/): o rclone do Homebrew não consegue montar. O rclone não cria o ponto de montagem, e `/Volumes` pertence ao root:

```bash
sudo mkdir -p /Volumes/Zurg && sudo chown "$USER" /Volumes/Zurg
rclone mount zurg: /Volumes/Zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ Windows
Precisa do [WinFsp](https://winfsp.dev). A letra da unidade não pode estar em uso, e só os programas na sessão de logon que executa o rclone a enxergam ([as regras de sessão](../setup/windows.md#keeping-it-running-the-session-rules)).

```powershell
rclone mount zurg: Z: --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++

`--vfs-handle-caching 0` precisa do rclone 1.74 ou mais novo, e impede que o rclone continue baixando por mais cinco segundos depois que um leitor fecha um arquivo. O README explica o que você perde se deixar essa opção de fora.

Ainda assim, defina `mount_path` no `config.yml` com o local onde você montou, senão as notificações de atualização do servidor de mídia vão ser montadas com o prefixo errado.

### Docker

O diretório de trabalho do zurg na imagem é `/config`, e o diretório de monitoramento e o cache de reparo ficam dentro dele. Um único bind mount leva tudo isso junto com o resto:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:latest
    volumes:
      - ./:/config
    ports:
      - 9999:9999
```

Quando você coloca um NZB em `./nzbs` no host, ele é detectado dentro do container sem precisar reiniciar.

Isso exige um host Linux para o mount. O Docker Desktop no macOS e no Windows roda o container dentro de uma VM, e o mount não chega ao Finder, ao Explorer nem a um Plex instalado no host. Nesses casos, use o binário para [macOS](../setup/macos.md) ou [Windows](../setup/windows.md) ([motivo](../setup/docker.md)).

> Instalações feitas antes de `/config` montar `/app/config.yml`, `/app/nzbs` e `/app/data` separadamente continuam funcionando exatamente como antes. Veja [docker.md](../setup/docker.md#upgrading-an-install-that-mounted-app).

---

## 6. Aponte o Plex para ele {#6-point-plex-at-it}

1. **Informe ao zurg suas credenciais do Plex**, para que ele possa pedir ao Plex que escaneie só os caminhos que mudaram, em vez de deixar você esperando por um escaneamento completo periódico. O jeito mais fácil é pelo fluxo de autenticação do Plex no Dashboard, que grava os valores de volta no `config.yml`:

   ```yaml
   plex_server_url: "http://localhost:32400"
   plex_token: YOUR_PLEX_TOKEN
   ```

2. **Adicione bibliotecas apontando para subpastas do mount**, nunca para a raiz do mount:

   - Movies → `/mnt/zurg/movies` (`/Volumes/Zurg/movies` no macOS, `Z:\movies` no Windows)
   - TV Shows → `/mnt/zurg/shows` (`/Volumes/Zurg/shows` no macOS, `Z:\shows` no Windows)

   No Windows, o Plex só enxerga `Z:` quando roda na mesma sessão de logon do zurg, que é o que a tarefa de logon do `zurg setup` oferece: veja [as regras de sessão](../setup/windows.md#keeping-it-running-the-session-rules).

   O mesmo lançamento aparece em cada pasta cujo filtro ele atende *e* em `__all__` e `__nzb__`. Se você apontar o Plex para a raiz, ele escaneia o mesmo arquivo várias vezes.

3. **Defina duas opções da biblioteca** em Edit → Advanced de cada biblioteca:

   - **Desmarque "Empty trash automatically after every scan".** Esta é a mais importante. Se o mount falhar por um instante enquanto o Plex está escaneando (um restart do zurg, uma remontagem do rclone), o Plex conclui que todos os arquivos foram apagados. Com essa opção ligada, eles são removidos de vez e na hora; com ela desligada, ficam na lixeira e voltam quando o mount volta. Isso já custou uma biblioteca de 30.000 itens antes.
   - **Desmarque "Generate video preview thumbnails".** Cada miniatura é uma busca em todo o arquivo; no Usenet, isso significa uma leitura completa do lançamento pela sua cota de conexão.

4. **Nunca reinicie o zurg durante um escaneamento do Plex.** Verifique antes de fazer isso:

   ```bash
   TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
   curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'
   curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l
   ```

   No Windows, no PowerShell, a partir da pasta do zurg:

   ```powershell
   $TOKEN = ((Select-String -Path config.yml -Pattern '^plex_token:').Line -split '\s+')[1].Trim('"', "'")
   (Invoke-RestMethod "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN").MediaContainer.size
   @((Invoke-RestMethod "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN").MediaContainer.Directory | Where-Object refreshing -eq 1).Count
   ```

   Sessões em `size="0"` (`0` no Windows) e uma contagem que se atualiza em `0` significam que é seguro. Se a linha de sessões não imprimir nada, o Plex recusou o token ou não respondeu, e o `0` abaixo dela não quer dizer nada: verifique o `plex_token` antes de reiniciar. (No PowerShell, a recusa aparece como um erro `401`.) (Use `grep -o … | wc -l`, e não `grep -c`: o grep retorna código de erro quando não encontra nada, que é o caso *bom*, e vai interromper uma cadeia `&&` justamente antes do restart que ela estava protegendo.)

5. **Escaneamentos parciais.** O `on_library_update` recebe cada caminho alterado; o `plex_update.sh` na raiz do repositório é o script de referência:

   ```yaml
   on_library_update: sh plex_update.sh "$@"
   ```

   O script precisa de `curl`, `xmllint` e `python3`, que a imagem Docker já tem, e da linha `zurg_mount` configurada com o caminho do seu mount. No Windows, o hook roda em PowerShell e não em `sh`, então este script não roda lá. Cada caminho alterado chega como um elemento de `$args`, relativo ao mount e com barras normais (`movies/Big Buck Bunny`); passe-os para um script PowerShell com `@args`:

   ```yaml
   on_library_update: '& C:\zurg\my_update.ps1 @args'
   ```

   O zurg já pede ao Plex que escaneie os caminhos alterados assim que o passo 1 estiver feito e o `mount_path` estiver definido, então um hook só é necessário para outras coisas.

**O que o Plex não recebe do conteúdo Usenet:** nada até o zurg tê-lo analisado (veja a seção 4), então o Plex pode fazer a própria análise na primeira reprodução, como faria com qualquer arquivo local. Os tamanhos dos arquivos se estabilizam logo depois que um lançamento é escaneado: a primeira listagem pode mostrar uma estimativa barata, baseada na contagem de artigos, e o tamanho exato chega depois, do índice de recuperação quando existe e, senão, a partir de um artigo por arquivo. Para um arquivo grande de múltiplos volumes cujo índice de recuperação já informa todos os tamanhos exatos, um volume verificado pode estabelecer o passo de artigos compartilhado; cada volume irmão confere essa inferência com o próprio cabeçalho antes de servir o primeiro byte. Assim que um tamanho é definido, a biblioteca é avisada de que o lançamento mudou, então o mount e o Plex veem o tamanho real. O zurg calcula o tamanho de até oito lançamentos por vez (nunca mais que as conexões da conta) em contas de doze conexões ou menos, e mais em contas maiores (doze com 16 conexões, dezesseis a partir de 20). Quando a aquisição verifica um lançamento nos servidores de notícias, essa verificação entra na fila ao lado deste cálculo de tamanho e da leitura antecipada, e nunca toma a conexão reservada para uma leitura que o player está esperando.

### Jellyfin / Emby / Infuse

Jellyfin e Emby usam `jellyfin_server_url` / `jellyfin_token` e `emby_server_url` / `emby_token` e recebem as mesmas notificações de escaneamento; veja [jellyfin.md](jellyfin.md). O Infuse pode apontar direto para `http://<host>:9999/dav/` e você pode pular o rclone por completo.

## 7. Quando um artigo está faltando {#7-when-an-article-is-missing}

Esse é o problema que o Usenet tem e o debrid não tem. Os artigos saem da retenção de um provedor ou são removidos, e um release pode aparecer listado perfeitamente enquanto alguns dos seus artigos já sumiram.

A resposta do zurg, em ordem de preferência:

1. **Peça a outro servidor de notícias.** Um artigo que saiu da retenção de um provedor geralmente ainda está em outro. É só uma busca — veja [Mais de um provedor de Usenet](#more-than-one-usenet-provider).
2. **Reconstrua a partir dos próprios arquivos PAR2 do release.** É para isso que eles são postados. Custa uma leitura do *release inteiro* — o Reed-Solomon precisa combinar cada fatia que sobrou para resolver uma faltando — então, num post de 200 GB, são 200 GB de leitura para recuperar alguns megabytes.
3. **Entregue silêncio.** Só quando nenhuma das opções acima consegue responder.

O reparo com PAR2 roda em segundo plano, no máximo dois releases por vez, e precisa de:

```yaml
enable_repair: true            # the default; set false to turn PAR2 repair off
par2_patch_cache_mb: 512       # budget for data/par2/; -1 keeps repairs in memory only
```

Os bytes reconstruídos são gravados em `data/par2/<nzb-id>/` e recarregados quando o arquivo é aberto da próxima vez, então um reinício não custa uma releitura completa do release. Só os trechos que realmente sumiram são guardados — um release danificado costuma custar poucos megabytes — e releases inteiros são descartados começando pelo menos usado (LRU) quando o orçamento é ultrapassado. Os trechos de cada release são marcados com a data de modificação do NZB do qual foram reconstruídos, então um NZB salvo de novo descarta esses trechos, em vez de servir bytes em posições que podem ter mudado.

Um reparo se anuncia e depois informa quanto custou:

```
PAR2 repair of Some.Release: 5 slice(s) missing; reading the release to rebuild them
PAR2 repair of Some.Release rebuilt 5 slice(s) in 55s on the avx2 kernel, keeping 3.4 MiB of them (library holds 3.4 MiB in memory, 3.4 MiB on disk)
```

Duas coisas que vale saber:

- **A reprodução sempre tem prioridade sobre o reparo.** As conexões são distribuídas por quem está esperando: primeiro a leitura sob demanda, depois o read-ahead, e o reparo por último — exceto que o reparo tem garantido um quarto da cota em relação ao read-ahead, para que o arquivo que está sendo reproduzido ainda consiga reparar o trecho em que está travado.
- **O reparo em nível de biblioteca do zurg não ajuda aqui.** Esse mecanismo adiciona de novo um torrent à conta de onde ele veio; um backend que não consegue adicionar conteúdo pode marcar um release como quebrado, mas não consegue consertá-lo. Para o Usenet, o PAR2 *é* o reparo.

Um release sem arquivos PAR2 no seu NZB e sem segunda conta de notícias não tem nenhum caminho de recuperação. Isso é uma característica do post, não do zurg.

## Desempenho {#performance}

| | |
|---|---|
| Fluxo único, arquivo direto | ~100 Mbit/s |
| Fluxo único, de um conjunto RAR | 90–106 Mbit/s |
| Dois fluxos simultâneos, total | ~124 Mbit/s |

A sua franquia de conexões define o primeiro teto da velocidade de um fluxo único. O zurg mantém essa franquia cheia ao dimensionar a leitura antecipada em artigos e em bytes: posts com artigos pequenos de arquivo recebem pelo menos 64 MiB de alcance, enquanto posts de vários megabytes mantêm a janela de conexões e pipeline que já tinham. Então:

- **Defina `connections` com o número real do seu plano.** Esse é o botão de ajuste. Oito conexões não vão transmitir um remux.
- **Duas contas primárias somam.** As leituras são feitas na soma da franquia das contas que não são `backup` e que compartilham a menor `priority` ativa. Assim, um segundo provedor ilimitado com a mesma prioridade também aumenta esse teto, além de cobrir as lacunas de retenção do primeiro. Uma conta `backup` não entra nessa soma.
- **`warm_connections` (4 por padrão) melhora a latência, não a velocidade.** Ele mantém esse número de conexões abertas, ociosas e autenticadas, para que a primeira leitura depois de um início ou de um período parado não gaste ~0,8s discando antes do primeiro byte: 1,5s até o primeiro byte a frio contra 0,15s a quente. Depois que um fluxo está rodando, ele não muda nada.
- **As conexões que acontecem ficam presas a um backend, então as sessões TLS são retomadas.** Uma conexão nova custa cerca de 0,8s, medido em um servidor de news real em 29/08/2026: 106ms de TCP, 213ms de handshake TLS, 256ms de saudação e 218ms para as duas trocas de `AUTHINFO`. O nome de host de um provedor é um rodízio (este resolve para 11 endereços), e um ticket de sessão TLS só vale na máquina que o emitiu. Por isso, discar de novo para o endereço que o resolvedor citou primeiro retomou **0 de 3** sessões, enquanto discar de novo para o mesmo endereço retomou **3 de 3**. Cada conta agora disca de novo para o endereço da sua última conexão, o que tira **110–140ms de cada nova conexão** ali. Um handshake retomado leva 109–141ms, contra 225–261ms de um completo. Um servidor com ida e volta de ~18ms economiza menos. O vínculo é desfeito e o nome é resolvido de novo assim que esse endereço para de responder, então nada fica preso a uma máquina que o provedor já aposentou. Já uma recusa que chega ao NNTP (a conta no limite de conexões ou uma senha rejeitada) mantém o vínculo, porque essa é a resposta da conta, e não do backend. Cada conexão registra suas fases em nível debug, incluindo `resumed=`.
- `cache_size_mb` (512 por padrão) é compartilhado entre todos os arquivos sendo lidos. Aumente-o se você roda vários fluxos simultâneos; ele não deixa um fluxo mais rápido. Leituras especulativas podem reservar no máximo metade dele, entre no máximo dois leitores, deixando a outra metade para artigos já consumidos ou prestes a serem consumidos.
- Se um lançamento vem empacotado em RAR ou como arquivos simples já não importa muito para a velocidade.

**Um artigo lento não trava mais o fluxo.** Uma leitura sequencial com média de ~90 MB/s ainda cai para 1–5 MB/s por cerca de um segundo de cada vez, e todas essas quedas têm a mesma causa: um artigo deixa de chegar enquanto as outras conexões terminam os seus e ficam ociosas. Quando uma leitura está parada em um artigo há mais tempo do que aquele leitor aprendeu a esperar, o zurg pede o mesmo artigo a uma **segunda conexão** e entrega a resposta que chegar primeiro. Um lote em pipeline travado pode bloquear vários artigos seguidos da posição de reprodução no mesmo socket morto, então até cinco artigos distintos de um mesmo leitor podem ser duplicados juntos, ou um ou dois em um post cujos artigos têm menos de 1 MiB. Nenhum artigo é pedido duas vezes. A conta paga por no máximo 20 pedidos duplicados por minuto. O prazo continua sendo o dobro da espera recente do próprio leitor, nunca menos de 250 ms (125 ms para posts com artigos menores que 1 MiB) e nunca mais de 2 s. Só é duplicada uma leitura que um cliente está de fato esperando. Leitura antecipada, pré-carregamento do próximo volume e reparo não são duplicados. Um artigo que os servidores acabaram de *recusar* também não é duplicado, pois ele já está esperando a própria confirmação um segundo depois, e pedir dentro dessa janela não prova nada. Cada duplicação escreve uma linha em nível debug dizendo quanto tempo a leitura ficou bloqueada, e a linha seguinte diz se o segundo pedido venceu.

Para intervalos declarados, o artigo da posição de reprodução entra no agendador de prioridades antes que os bytes seguintes sejam oferecidos. As conexões em pipeline então recebem rodadas consecutivas de artigos, e não blocos contíguos, de modo que os primeiros artigos úteis se espalham pela franquia. Uma requisição de pelo menos 64 MiB é tratada como reprodução e recebe a fronteira completa de intervalo. Uma busca pequena continua sendo uma sondagem e abre apenas uma rampa estreita.

### Cruzando um limite de volume {#crossing-a-volume-boundary}

Um arquivo dentro de um conjunto RAR é servido um volume por vez, e cada volume é uma leitura separada na conta de Usenet. O zurg abre o próximo volume enquanto o atual ainda está tocando e lê os primeiros quatro megabytes dele, então a passagem não começa do zero. Em um release postado com volumes pequenos, esse início não basta sozinho: quatro megabytes equivalem a cerca de dez artigos de um release postado em partes de ~395 KB, e volumes de ~26 MB criam um limite a cada 1,7 segundo de reprodução. Ou seja, o stream esgotava o início aquecido da memória em um quarto de segundo e depois esperava um tempo de ida e volta por tudo o que vinha depois. Medido em uma Hetzner CCX23, com dez conexões, em 8 de setembro de 2026, esse release fazia stream a **14–16 MB/s**, enquanto um arquivo comum na mesma conta chegava a **86–99 MB/s**. A taxa de um segundo oscilava entre 1 e 29 MB/s, e de 46 a 55 dos 60 slots de leitura antecipada da conta ficavam sem uso.

Agora o zurg aquece o próximo volume com uma janela de leitura antecipada inteira de profundidade, assim que o stream chega a 32 MiB do limite. E um volume em que o stream acabou de entrar mantém a janela que já conquistou, em vez de recomeçar com dois artigos. Um volume que a posição de reprodução não vai alcançar em vários segundos continua sendo aquecido só no início. Isso evita que uma varredura de biblioteca (um leitor por entrada, alguns megabytes de cada uma) puxe uma janela de todo próximo volume que nunca será lido. Nada disso precisa de configuração, e não muda o limite de memória: uma conta ainda usa duas janelas de leitura antecipada ao mesmo tempo, o volume em reprodução e o que está sendo aquecido, dentro de `cache_size_mb`.

Os reparos são lentos por natureza, já que leem o release inteiro, mas rodam com prioridade de segundo plano e são limitados pelo próprio servidor de Usenet, e não pela conta do zurg.

### Memória: quanto custa um diretório de monitoramento {#memory-what-a-watch-directory-costs}

Um NZB é uma lista de artigos, e uma biblioteca grande é muitos artigos. Ao fazer o parse de um NZB, o zurg guarda os message ids e seus offsets na memória para que uma leitura consiga encontrá-los. As versões anteriores mantinham todos eles durante toda a vida do processo. Medido em um diretório de observação com 2,636 NZBs e 27.6 million `<segment>` elements, isso dava **1.52 GB de heap em uso**, cerca de 58 bytes por artigo, além do cache de artigos. Quase nada disso é usado: uma listagem precisa só de nomes, tamanhos e contagens, e só um arquivo que está sendo lido ou reparado precisa saber como se chamam os seus artigos.

`nzb_segments` decide se o zurg mantém essas informações:

```yaml
nzb_segments: mmap             # mmap (default) | reparse | resident
nzb_segments_idle_secs: 120    # how long a release's articles are kept after the last read
```

- **`mmap`**: as listas são gravadas em `data/nzb-index/<id>.bin` e esse arquivo é mapeado sob demanda. Assim, os bytes ficam no page cache e não no heap do zurg, e o kernel os libera quando a memória está sob pressão. **O padrão no Linux, macOS e BSD.** Gasta aproximadamente tanto disco quanto as próprias listas.
- **`reparse`**: as listas são descartadas depois que um release se estabiliza, e o NZB é lido de novo do disco quando uma leitura ou um reparo precisa delas. Não gasta nenhum disco, e é por isso que você escolheria esse modo: um host onde `data/` não pode crescer.
- **`resident`**: todas as listas de artigos ficam sempre na memória. **O comportamento anterior**, o que todas as versões antigas faziam. Continua suportado, mas não é mais o padrão.

Seja qual for o modo, uma listagem nunca carrega nada. O nome, o tamanho e a contagem de artigos de um arquivo são respondidos sem que a lista de artigos chegue perto da memória. Assim, uma atualização da biblioteca, uma checagem de fingerprint ou um *arr perguntando se um job já se estabilizou continuam sem custo. O que os modos lazy custam é a primeira leitura de um release que ninguém tocou por `nzb_segments_idle_secs` (uma varredura roda a cada 30 segundos). Além disso, todos os arquivos de um release são carregados juntos. Por isso, percorrer em ordem os volumes rar de um season pack paga esse custo uma vez só.

Medido em um release com 60 arquivos e 30,000 segmentos:

| | heap por release | primeira leitura de um release ocioso | por artigo no caminho de leitura |
|---|---|---|---|
| `resident` | 1.74 MB | — | 6 ns |
| `reparse` | 21.3 kB | 39 ms | 52 ns |
| `mmap` | 16.6 kB | 0.27 ms | 63 ns |

Cinquenta nanossegundos por artigo não são nada perto dos milissegundos que levam para buscar um artigo, então os números do caminho de leitura importam menos do que parecem. O que vale considerar é o reload. O `reparse` lê e faz o parse do documento XML inteiro de novo, o que, em um season pack, leva dezenas de milissegundos antes que o primeiro byte se mova. O `mmap` é uma chamada de `mmap`, um cabeçalho de slice por arquivo e um checksum do índice que acabou de ser mapeado: 0.08 ms dos três. Os outros 0.19 ms são o preço de detectar um byte ruim em vez de servi-lo como um message id.

E considerando a biblioteca inteira, e não um release só (2,636 NZBs, 27.6 million artigos, o mesmo binário executado três vezes sobre o mesmo corpus, ocioso depois de uma varredura):

| | resident set | heap em uso | CPU ociosa | abertura a frio, p50 | índice em disco |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

As aberturas a quente (1 ms), a vazão de streaming (38–39 MB/s) e o tempo de inicialização não tiveram diferença perceptível entre os três modos. O `mmap` abre um release frio *mais rápido* do que manter tudo na memória, porque um release que não foi aberto nesta execução também precisa ser parseado no `resident`. E mapear uma arena já escrita é uma syscall, enquanto fazer o parse são megabytes de XML.

O índice se reescreve sempre que o NZB muda, se repara sozinho caso fique ilegível (voltando ao NZB e gravando de novo) e é removido quando o NZB sai do diretório de observação. Tanto o cabeçalho quanto o conteúdo têm checksum, então um byte ruim é detectado em vez de servido como um message id que ninguém postou. O tamanho atual do índice aparece na página inicial do **Dashboard**, em **Article Index**, e na linha que o backend registra na inicialização. No **Windows** não há mapeamento: o índice seria lido para o heap, o que equivale à memória residente *mais* um reload. Por isso, o padrão ali continua sendo `resident`, e o modo lazy que vale a pena escolher é o `reparse`.

## Solução de problemas {#troubleshooting}

| Sintoma | Causa | Solução |
|---|---|---|
| `Cannot reach the news server for nzb` na inicialização | Combinação errada de host, porta e TLS, credenciais inválidas ou um plano inativo | `563` usa `tls: true`, `119` usa `tls: false`; depois confira as credenciais novamente |
| Biblioteca vazia, sem linhas `Loaded NZB` | A pasta `nzbs/` está faltando ou no lugar errado | Ela é relativa ao **diretório de trabalho** do zurg. Confira `WorkingDirectory=` na sua unit do systemd, ou o diretório montado em `/config` no Docker, que é a `nzbs/` ao lado do arquivo compose. Só uma instalação anterior ao `/config` observa `/app/nzbs` |
| Um NZB nunca aparece | Está em uma subpasta, se chama `.nzb.gz` ou não pode ser interpretado | Mova-o diretamente para `nzbs/` e descompacte-o; confira no log se há um aviso `Skipping` |
| O release aparece com um nome sem utilidade | O nome do arquivo NZB é usado como nome, na falta de um `<meta type="name">` | Renomeie o `.nzb` para o nome do release |
| Os arquivos têm nomes aleatórios dentro do release | Post ofuscado cuja recuperação falhou | Procure por `Recovered N filename(s)`; sem arquivos PAR2 no NZB, não há de onde tirar os nomes reais |
| O vídeo ainda tem nome aleatório, mas a pasta está certa | Post totalmente ofuscado, em que o arquivo contém vários arquivos de tamanho parecido | Só um payload único e claro é renomeado para o release; um season pack em um único arquivo mantém os nomes que o arquivo lhe deu |
| Streaming lento | `connections` deixado no padrão 8 | Defina o valor permitido pelo seu plano |
| A primeira reprodução depois de um período parado demora um segundo para começar, depois roda bem | O piso de aquecimento está desativado, ou zerado por uma conta de uma conexão só | Deixe `warm_connections` sem definir (o padrão é 4) e confira se nem ele nem o `warm_connections` de nível superior foram definidos como negativos |
| Conexões recusadas pelo provedor | `connections` acima do que o plano permite | Reduza para o valor real |
| A reprodução trava ou um trecho toca em silêncio | Artigos faltando | Procure por `PAR2 repair of …` no log; confirme `enable_repair: true`; adicione [outro provedor Usenet](#more-than-one-usenet-provider) |
| Um trecho fica em silêncio e nenhuma linha de reparo aparece | `enable_repair` está desativado, ou o NZB não tem arquivos `.par2` | Defina `enable_repair: true`; se o post não tem arquivos de recuperação, só outra conta de notícias pode ajudar |
| Um segundo provedor nunca parece ser consultado | As duas contas têm o mesmo `backbone`, então a segunda é pulada assim que a primeira informa que o artigo sumiu | Corrija os valores de `backbone`. Só contas realmente no mesmo spool devem compartilhar um nome |
| Uma de várias contas está inativa, mas a inicialização pareceu normal | A inicialização só falha quando *todas* as contas estão inacessíveis | Procure por `is not reachable` no log; cada conta com problema avisa pelo nome |
| Uma conta de bloco está cobrando por artigos que a conta ilimitada já tem | `backup: true` não está definido nela | Defina; um primário apenas ocupado deixará de empurrar leituras para a conta medida |
| Um release está faltando em uma pasta filtrada por tag | Ele ainda não foi analisado, então não tem tags `zurg_*` | Aguarde a análise, ou execute Analyze & Tag Library no Dashboard |
| Arquivos `.par2` não visíveis no mount | Intencional: ficam ocultos como estrutura de reparo | Nada a corrigir; o zurg ainda os lê |
| Alterou um provedor no Dashboard e nada aconteceu | Alterações de provedor são gravadas em `config.yml`, mas não são recarregadas a quente | Reinicie o zurg. O aviso abaixo da tabela de provedores diz isso |
| O Plex esvaziou a biblioteca depois de reiniciar o zurg | Uma varredura estava em andamento enquanto o mount estava fora, com auto-empty-trash ativado | Desative o auto-empty-trash e encerre as sessões *e* atualize o estado antes de qualquer reinício |
| O tamanho de um arquivo mudou um pouco logo depois que o release apareceu | A primeira listagem só pode estimar a partir da contagem de artigos; o tamanho exato chega depois, pelo índice PAR2 ou pelo cabeçalho yEnc do próprio arquivo | Esperado, e se estabiliza uma vez: o tamanho é gravado em `data/nzb-sizes/` e mantido até o NZB mudar |

### Perguntando sobre um artigo {#asking-about-one-article}

`GET /debug/nzb/probe` faz uma única pergunta às contas de notícias pelo mesmo pool que o zurg já está usando, na prioridade que uma leitura de demanda recebe. Ele existe porque a alternativa não funcionava: uma conta oferece oito conexões e o zurg ocupa todas elas, então testar um post à mão exigia uma segunda conta ou parar o servidor, e parar o servidor destrói o estado que está sendo diagnosticado.
No Windows, use `curl.exe` em vez de `curl` nesses comandos.

```bash
# Is this article still there? A STAT, so nothing is transferred.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?message_id=abc@news.example'

# The same question addressed the way you have it: a release id from the
# library, a file index counting from zero, an article number counting from one.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&file=0&article=3'

# &body=1 fetches the one article and reports what actually arrived against what
# the article says should have. This is how a provider that strips trailing
# bytes is identified: `short: true` with `decoded_bytes` below `span_bytes`.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&article=3&body=1'
```

Ele responde com `{"probes": [...]}`, com um objeto para o provedor `nzb`, contendo `found`, `missing` e o tempo que levou. Ele pergunta às contas de notícias na ordem de prioridade até uma delas ter o artigo (uma conta de backup só é consultada quando as principais falham). Ele não informa qual conta de notícias tinha o artigo. É somente leitura: nada que ele busca entra no cache de artigos, e um artigo que ele não encontra não é registrado como morto, então um teste nunca consegue silenciar um arquivo que toca.

---

Ainda com problemas? Pergunte no fórum **zurg-support** no [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) diz o que incluir.

## Veja também {#see-also}

- [config.md](../reference/config.md) — every option, including the [Usenet account reference](../reference/config.md#usenet-accounts) and the [directory filter reference](../reference/config.md#7-directories--filters)
- [plex.md](plex.md) — how zurg drives Plex scanning, matching and the trash sweep
- [jellyfin.md](jellyfin.md) — integração com o Jellyfin
- [docker.md](../setup/docker.md) — configuração do Docker, propagação do FUSE e solução de problemas
- [tags.md](../reference/tags.md) — o sistema de tags
- [architecture.md](../internals/architecture.md) — `internal/nzb` e `internal/nntp` no contexto geral
