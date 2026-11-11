# Teste E2E {#e2e-testing}

Testes ponta a ponta para verificar se o zurg está funcionando corretamente após a implantação.

## Teste de Reprodução no Plex {#plex-playback-test}

Verifica se o conteúdo realmente pode ser reproduzido no Plex, escolhendo um filme aleatório e testando todo o pipeline de reprodução.

### Execute o Teste {#run-the-test}

```bash
./scripts/plex-e2e-test.sh
```

O script lê automaticamente `plex_server_url` e `plex_token` do `config.yml`.

Para sobrescrever com configurações personalizadas:
```bash
PLEX_URL="http://your-plex:32400" PLEX_TOKEN="your-token" ./scripts/plex-e2e-test.sh
```

### O Que Ele Testa {#what-it-tests}

| Step | Description |
|------|-------------|
| 1 | Encontrar a biblioteca Movies via Plex API |
| 2 | Obter a contagem total de filmes |
| 3 | Selecionar um filme aleatório |
| 4 | Obter a URL de stream do filme |
| 5 | Verificar se o stream está acessível (HTTP 200) |
| 6 | Decodificar 3 segundos de vídeo com ffmpeg |
| 7 | Criar e verificar o rastreamento de sessão no Plex |

### Saída Esperada {#expected-output}

```
=== Plex E2E Playback Test ===

[1/7] Finding Movies library...
  Library key: 15
[2/7] Getting movie count...
  Total movies: 1234
[3/7] Selecting random movie...
  Selected: 2 Fast 2 Furious (2003) (ratingKey: 756524)
[4/7] Getting stream URL...
  File size: 54GiB
[5/7] Verifying stream accessibility...
  HTTP Status: 200 OK
[6/7] Decoding video (3 seconds)...
  Decoded 72 frames successfully
[7/7] Testing Plex session tracking...
  Session created and tracked

=== TEST PASSED ===
Movie '2 Fast 2 Furious (2003)' is playable via Plex
```

### Pré-requisitos {#prerequisites}

- Servidor Plex rodando e acessível
- `plex_server_url` e `plex_token` configurados em `config.yml`
- `curl`, `jq` e `ffmpeg` instalados

### Solução de problemas {#troubleshooting}

| Erro | Causa | Solução |
|-------|-------|-----|
| No movie library found | Tipo de biblioteca errado ou vazia | Verifique se o Plex tem uma biblioteca "Movies" |
| Stream not accessible (HTTP 4xx) | Problema de autenticação ou caminho | Confira se o token está certo e se o arquivo existe |
| Failed to decode video frames | Arquivo corrompido ou problema de rede | Verifique os logs do zurg e tente outro filme |
| Session not detected | Tempo de sessão do Plex esgotado | Verifique os logs do Plex |

## Suíte de Integração {#integration-suite}

```bash
ssh zen
cd /path/to/isolated/zurg/source
make integration-test
```

**Execute em um alvo isolado no `zen`.** Forneça ali um toolchain do Go, shellcheck,
rclone e a sonda de movimentação do .NET. A suíte cria seus próprios processos zurg
e montagens; ela não exige substituir o serviço zurg normal do zen nem a montagem dele.
Use um diretório de origem separado, `TMPDIR`, config, porta e `MOUNT_PATH` próprios.
Inspecione a config temporária antes de executar e mantenha o `INTEGRATION_LOCK_FILE=/tmp/zurg-integration-rd.lock` de todo o host, mesmo com um `TMPDIR` privado, para que outras sessões continuem serializando com a sua.

Os testes cujos pré-requisitos estiverem ausentes podem pular com código de saída de sucesso. Leia a saída deles para verificar que FUSE, rclone, Plex e NNTP realmente foram executados.

| Teste | Precisa de FUSE | Precisa do Plex | Precisa de uma conta Usenet |
|------|:----------:|:----------:|:----------------------:|
| `refresh_repair_integration.sh` | | | |
| `network_test_cache_integration.sh` | | | |
| `rclone_mount_integration.sh` | sim | | |
| `magic_mount_integration.sh` | sim | | |
| `magic_move_refusal.sh` | sim | | |
| `magic_library_move_integration.sh` | sim | | |
| `plex_integration.sh` | sim | sim | |
| `nzb_bench_integration.sh` | | | sim |

`force_location_integration.sh` **não** está na suíte — ele verifica algo sobre o caminho de rede deste host até a CDN do Real-Debrid, e não sobre o zurg, então falha onde esse caminho não consegue responder, independentemente da mudança testada. Execute-o de propósito com `make force-location-test`, em um host com IPv4 funcionando até a região forçada. Veja [Teste de integração Force Location](#force-location-integration-test).

Os cinco testes que usam o Real-Debrid usam a mesma conta — veja [a conta é compartilhada](#the-real-debrid-test-account-is-shared). O benchmark usa uma conta de notícias no lugar e não toca no Real-Debrid, mas pega o mesmo bloqueio de todo o host que os demais: uma medição feita ao lado das leituras de outra suíte está medindo a outra suíte.

O teste de montagem também roda em um Mac quando o macFUSE está instalado — ele foi verificado tanto com macFUSE quanto com `fusermount` do Linux. O teste do Plex precisa de `plex_server_url` e `plex_token` na config temporária, e o Plex precisa conseguir atravessar todos os diretórios pais da montagem temporária. Uma montagem dentro de um diretório home privado pode funcionar para o usuário do teste e continuar inacessível para o Plex.

`make integration-test` compila o zurg, roda o shellcheck nos scripts, o self-test do `lib.sh` e os testes unitários de `integration/nzbbench`, depois executa todos os sete, do mais barato para o mais caro: cache de teste de rede, montagem rclone, Plex, montagem `__magic__`, recusa de movimentação .NET, refresh/repair e, por último, o benchmark de Usenet. Os dois últimos são os mais caros — refresh/repair espera uma varredura completa da biblioteca, e o benchmark lê gigabytes de um servidor de notícias duas vezes — então um erro em qualquer um dos outros não deve custar essa espera para ser descoberto. `make integration-test-media` roda os testes de montagem rclone, Plex e `__magic__`, e `make nzb-bench-test` só o benchmark.

Cada script possui um diretório de trabalho em `$TMPDIR`, sua própria porta, e grava ali o log do zurg; a suíte roda com `STREAM_LOGS=false`, então só as asserções do próprio teste chegam ao terminal. Defina `STREAM_LOGS=true` para acompanhar o log do zurg no stderr durante a depuração.

Os helpers compartilhados ficam em `integration/lib.sh` (controle de processos, a API do Real-Debrid, consultas à biblioteca em disco) e `integration/lib_media.sh` (FUSE e Plex). Para adicionar um teste, faça source deles, e não copie outro script.
`integration/lib_test.sh` cobre os próprios helpers: sem conta, sem rede, cerca de um segundo. `integration/nzb_bench_timing_gate_test.sh` cobre como o wrapper do benchmark converte o código de saída da ferramenta no vocabulário da suíte, rodando a partir de um relatório real reduzido em `integration/testdata/`; ambos rodam em `make test-integration-lib`.

### A conta de teste do Real-Debrid é compartilhada {#the-real-debrid-test-account-is-shared}

A suíte usa uma conta de teste do Real-Debrid, e essa conta não é privada. O zurg de produção da `zen` observa a mesma biblioteca, então lista e atualiza justamente os torrents que um teste acabou de adicionar. Qualquer instância nessa conta **com repair habilitado** também verifica, repara e organiza esses torrents.

As duas falhas abaixo foram diagnosticadas em 2026-08-23, quando o zurg do `macmini` rodava nessa conta com repair a cada 10 minutos. Essa instância foi parada em 2026-08-29 e não há nada supervisionando ela, e as execuções da `zen` usam `enable_repair: false`. Por isso, a partir de 2026-09-01, nenhuma das duas falhas tem uma fonte ativa. Elas voltam assim que repair for ligado em qualquer lugar dessa conta, e é por isso que a serialização descrita abaixo continua valendo.

O que isso faz com uma execução, depois que quatro dos seis scripts falharam tanto no build em teste quanto na linha de base:

- **Um fixture que nunca aparece.** O Real-Debrid deduplica os ids de download por link, e apagar uma linha da tabela downloads revoga esse código para todo mundo que o tem. A limpeza de outra instância revoga o código que esta execução acabou de resolver, a verificação desta execução responde `404 invalid_download_code`, e o zurg marca o arquivo como quebrado. Um torrent quebrado fica oculto em todas as listagens. O teste então diz `zurg serves the fixture over HTTP but it never appeared under .../mnt/movies within 180s`, o que parece um bug de mount ou de dircache, mas não é nenhum dos dois.
- **Um delete que é desfeito.** Uma instância com repair readiciona um torrent que esta execução acabou de apagar, então `refresh never dropped <hash> after it was deleted from the account` falha contra uma biblioteca que está refletindo a realidade corretamente.

As asserções de delete e de repair são as que mais sofrem com isso. Antes de culpar uma mudança, leia o contexto da falha descrito abaixo. E se uma execução precisar estar limpa, pare antes o repair das outras instâncias.

**Nenhum dos scripts pode rodar ao mesmo tempo**, nesta máquina ou a partir de outra sessão nela. Eles compartilham o orçamento de chamadas de API por minuto da conta, então um par de execuções recebe `API rate limit (code=34)` e as asserções começam a falhar por causa do tráfego, e não do comportamento (medido na `fun`, com duas execuções em paralelo). Além disso, cada script apaga torrents *pelo hash*, então a limpeza de uma execução vai apagar, sem nenhum problema, o fixture da outra. Por isso, todo script pega um lock global do host no início de `main`, antes da primeira chamada de API, e o mantém até sair.

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `INTEGRATION_LOCK_FILE` | `$TMPDIR/zurg-integration-rd.lock` | O lock. `flock` onde ele existir, um diretório `.d` com o pid do dono gravado caso contrário (o macOS não traz `flock`) |
| `INTEGRATION_LOCK_WAIT` | `0` | Segundos para aguardar atrás de uma execução em andamento. `0` recusa na hora, que é o que você quer, porque a alternativa é ficar uma hora esperando um scan frio |

Um lock deixado para trás por uma execução que foi morta é recuperado automaticamente: o diretório guarda o pid do dono, e o `flock` é liberado pelo kernel. O lock não diz nada para a zen nem para o macmini, claro. Ele só mantém as execuções deste host separadas.

**Lendo uma falha.** Cada `fail` agora imprime, a partir do log do zurg daquela execução: a contagem de cada sintoma compartilhado da conta, que são `invalid_download_code`, `hoster_unavailable`, linhas de rate-limit, `code=34`, `Link verification failed`, `keeping files as broken`, `broken_file]` e `Deleted downloads entry`. Depois vêm as últimas dez dessas linhas e, por fim, as últimas linhas que citam o fixture em teste. A linha `none present, so this failure is probably zurg's own and not the account's` é a que indica para ir investigar o código.

`docs/realdebrid-behavior.txt` tem a semântica dos links por trás de tudo isso: quais links resgatam em qual conta, e por que `unavailable_file` e `hoster_unavailable` significam coisas diferentes.

### Tempo de Execução {#runtime}

A primeira execução numa determinada pasta de trabalho (work dir) paga por uma varredura fria da biblioteca: uma chamada de info e uma verificação de link por torrent, espaçadas pelo orçamento de API da conta. Numa conta com alguns milhares de torrents isso leva dezenas de minutos. Esta conta tinha 3,361 torrents em 2026-08-29, o suficiente para provocar `code=34` contínuo e fazer um script levar cerca de vinte minutos.

A pasta de trabalho guarda três caches entre execuções, para que as seguintes pulem essa etapa: `info/`, `linkcache/` e os resultados dos testes de rede. Apague a pasta de trabalho para forçar o caminho frio.

`linkcache/` é o que `internal/debrid.LinkCache` grava em disco, um arquivo por instância de provedor. É essa a metade que elimina os vinte minutos: o primeiro contato com um torrent resolve um de seus links para verificá-lo. Com o cache vazio, isso é uma chamada `unrestrict/link` por torrent; com o cache quente, é de graça. O ganho é limitado pelo TTL de 4h do cache. Uma re-execução da suíte no dia seguinte volta a ser fria, então ele encurta a iteração, mas não a primeira execução.

Nem `info/` nem `linkcache/` são livres de links, e ambos guardam códigos que outra instância na conta compartilhada pode revogar. Um `.zurginfo` é um `TorrentInfo` literal, então carrega os códigos `/d/` do Real-Debrid do torrent, e `linkcache/` guarda o que esses códigos resolveram. Mesmo assim, os dois são preservados. Reconstruí-los é o que custa as dezenas de minutos, e uma entrada revogada não é uma resposta errada: a verificação recebe `404 invalid_download_code`, o zurg invalida essa entrada e gera um novo código, então só as entradas revogadas pagam uma chamada. Espere algumas em toda execução, e espere que o ganho de velocidade varie conforme a quantidade.

Um fixture é mais restrito ainda: `clean_state_for_hash` apaga as entradas de `info/` cujo hash corresponde a ele, então a lista de links dele é sempre buscada de novo na conta. `linkcache/` é indexado por link, não por hash, e não é limpo por fixture. Por isso, a *resolução* de um desses links ainda pode vir de uma execução anterior. Isso não afeta nenhuma asserção aqui, já que os fixtures testam refresh, roteamento, a montagem e o reparo. Uma resolução que ficou velha falha na verificação e é gerada de novo antes que qualquer um deles a veja.

### Teste de Integração de Refresh/Repair {#refreshrepair-integration-test}

```bash
./integration/refresh_repair_integration.sh
```

A reparo automático continua desativado na configuração de teste. As duas requisições explícitas para `/manage/{hash}/repair` ignoram essa configuração e reparam os seus fixtures.
Ativar o reparo sem supervisão também faria o scan e alterar entradas não relacionadas na conta compartilhada, gastando o orçamento da API de que as asserções precisam.
O `refresh_repair_config_test.sh` verifica a configuração gerada sem tráfego para o provedor, usando a entrada de teste redigida capturada na falha de 2026-09-10.

| Cenário | Descrição |
|----------|-------------|
| 1. Atualização automática (adição) | Adiciona um torrent pela API do RD e espera o loop de atualização perceber — sem reiniciar, senão estaria testando o caminho de carregamento a frio |
| 2. Atribuição de diretórios e roteamento | Verifica se os arquivos aparecem nos diretórios virtuais HTTP/DAV |
| 3. Persistência (reinício) | Reinicia o zurg e confirma que o estado em cache sobrevive |
| 4. Atualização automática (remoção) | Apaga o torrent e espera a varredura de chaves obsoletas removê-lo |
| 5. Gatilho de reparo | Dispara o reparo pela Manage API, verifica se o zurg registrou que aceitou a requisição, e espera por `ok_torrent` com 0 arquivos quebrados |
| 6. Verificação do reparo | Repara um segundo torrent e faz requisição por faixas de um arquivo de vídeo dele |

#### Variáveis de Ambiente {#environment-variables}

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `12345` | Porta para a instância de teste do zurg |
| `CONFIG_PATH` | `config.yml` | Config de onde pegar as credenciais: o `token` do provider `realdebrid` e o `username`/`password` de nível superior |
| `TEST_HASH` | *(built-in)* | Hash do torrent para os testes de refresh |
| `REPAIR_TEST_HASH` | *(built-in)* | Hash do torrent com partes quebradas para os testes de repair |
| `VERIFY_TEST_HASH` | *(built-in)* | Hash do torrent para os testes de verificação do repair |
| `READY_TIMEOUT` | `120` | Segundos para esperar o zurg ficar pronto |
| `INITIAL_SCAN_TIMEOUT` | `3600` | Segundos para esperar a primeira varredura completa do refresh |
| `REFRESH_TIMEOUT` | `120` | Segundos para esperar um refresh captar uma adição ou remoção |
| `REPAIR_TIMEOUT` | `300` | Segundos para esperar um repair se estabilizar |
| `STREAM_LOGS` | `true` | Acompanhar o log do zurg no stderr |
| `ZURG_BIN` | `$(pwd)/zurg` | Caminho do binário do zurg — absoluto, porque o zurg é iniciado a partir do diretório de trabalho |
| `WORK_DIR` | `$TMPDIR/zurg-refresh-repair` | Diretório de trabalho (mantido entre execuções) |
| `WORK_DIR_CLEANUP` | `false` | Apagar o diretório de trabalho ao sair, descartando os caches que deixam as execuções seguintes mais rápidas |

### Teste de Integração de Force Location {#force-location-integration-test}

```bash
make force-location-test
```

Não faz parte do `make integration-test`; deve ser executado manualmente. Medido em `fun` em 2026-08-29, os hosts `nyk` forçados resolviam para registros AAAA que o cliente de download acessava via `tcp4`, então todo HEAD terminava com `no suitable address
found`; com três tentativas cada, a varredura da biblioteca que este teste espera fica travada por quase uma hora antes de falhar por causa da rede do host, e não por causa do zurg. O teste já pula quando uma região está inoperante (veja abaixo), mas essa verificação não cobre um host que não consegue alcançar uma região *saudável* via IPv4.

Cria um cache de teste de rede fixado em `LOCATION` (padrão `nyk`) e depois verifica se um link resolvido pelo endpoint `/strm/` do zurg redireciona para um host de download nessa localização. `MAX_GEO_PROBES` (padrão `4`) limita quantos servidores geo a etapa de seed consulta.

Com `cdn_host_preference` definido, todo link que o zurg verifica passa pela região forçada; se ela estiver inoperante, a listagem fica vazia e a falha parece um bug do zurg. Por isso, o teste verifica a região primeiro e pula, em vez de falhar, quando o Real-Debrid não gera um link para ela ou quando o host que ele devolve não entrega os bytes.

### Teste de Integração de Network Test Cache {#network-test-cache-integration-test}

```bash
./integration/network_test_cache_integration.sh
```

Executa o zurg duas vezes: a primeira inicialização deve rodar o teste de latência e gravar `data/network_test_results.json`, a segunda deve carregar esse arquivo e não rodar um novo teste.

### Teste de Integração de Rclone Mount {#rclone-mount-integration-test}

```bash
./integration/rclone_mount_integration.sh
```

Percorre o caminho que o player realmente faz — FUSE → HTTP do zurg → Real-Debrid:

| Passo | Verificação |
|------|-----------|
| 2 | o zurg sobe a própria montagem e registra `Mount verification successful` |
| 3 | os diretórios configurados ficam visíveis na raiz da montagem |
| 4a–4c | o fixture entra na biblioteca, é servido via HTTP e chega à montagem — em etapas, para que uma falha aponte qual salto quebrou, e não apenas "not in the mount" |
| 5 | ler o arquivo pelo FUSE retorna bytes reais |
| 6 | desligar o zurg libera a montagem |

O passo 4c é a verificação do dircache do VFS: o fixture só chega à montagem se a listagem do diretório foi invalidada, em vez de ser servida de uma listagem guardada em cache antes de o torrent chegar.

A biblioteca é filtrada por uma regex criada a partir do nome do próprio fixture, então a montagem tem só um release, e não a conta inteira. `MOUNT_PATH` usa `$WORK_DIR/mnt` por padrão — nunca o `/mnt/zurg` de produção. `RCLONE_BIN` usa `$(pwd)/bin/rclone` por padrão.

### Teste de Integração do Plex {#plex-integration-test}

```bash
./integration/plex_integration.sh
```

| Step | Assertion |
|------|-----------|
| 2 | zurg registra `Successfully connected to Plex server` |
| 3 | o fixture chega à biblioteca e, se também aparecer no mount, precisa ser legível (o Plex lê como o próprio usuário) |
| 4 | uma nova seção descartável é criada sobre `$MOUNT_PATH/movies` |
| 5 | o zurg resolve o caminho da biblioteca para essa seção e agenda uma atualização **para o caminho do fixture** |
| 6 | o Plex acaba com o item indexado |

Aqui, o fixture aparecer no mount é uma pré-condição, não a asserção:
com o Plex configurado, o zurg também roda o matcher sobre toda a biblioteca do Plex,
o que disputa com a atualização, então a listagem do VFS pode ficar bem atrás.
O teste avisa isso e segue em frente depois de `MOUNT_VISIBLE_TIMEOUT` (padrão `420`) —
os passos 5 e 6 já falham se o Plex não conseguir ver o arquivo, e verificar que
a invalidação funciona é trabalho do teste de mount. `PLEX_URL` e `PLEX_TOKEN` sobrescrevem
o `plex_server_url`/`plex_token` da config.

O Plex escaneia uma nova seção automaticamente e pode terminar antes da criação retornar.
O teste informa essa contagem inicial; o passo 5 verifica, de forma independente, que o zurg
agenda o caminho correto depois de uma requisição explícita de manage.

A seção é criada com `agent=tv.plex.agents.none` e o scanner `Plex Video
Files`, assim o Plex indexa localmente sem consultar um agente de metadados online,
e ela é apagada na saída — inclusive em caso de falha, pela trap EXIT. Porém, nada roda
com SIGKILL, então, depois de uma execução morta, inspecione e remova apenas a sua própria seção.
O harness deixa as seções que já existiam em paz, porque elas podem pertencer a outra sessão.
As bibliotecas existentes nunca são tocadas.

O passo 5 pede ao zurg que execute os efeitos colaterais via `POST /manage/{hash}/scan` em vez de esperar uma passada de atualização. O gatilho de atribuição de diretório dispara uma vez, quando um torrent é descoberto, o que necessariamente acontece antes de a seção existir; esperar a próxima passada completa custa dezenas de minutos numa conta com alguns milhares de torrents.
O mapeamento testado não muda — o zurg ainda precisa resolver sozinho o caminho da própria biblioteca para a seção certa.

### Regressão do Benchmark de Usenet {#usenet-benchmark-regression}

```bash
./integration/nzb_bench_integration.sh
make nzb-bench-test
```

Nada mais na suíte lê um byte sequer via NNTP. Uma mudança no fetcher de artigos, no decodificador yEnc, no reparo PAR2 ou no leitor de arquivos pode cortar a vazão pela metade, dobrar o uso de memória ou começar a servir silêncio onde um artigo sumiu, e todos os outros testes continuariam passando. Este lê quatro releases preparadas através de um zurg descartável e verifica tanto os números quanto os bytes.

**Por que é um A/B e não um número salvo.** A vazão em um servidor de notícias ao vivo oscila 10–20% ao longo de uma noite — seis leituras da mesma release variaram entre 34 e 50 MB/s numa mesma sessão — então uma faixa apertada em relação a um valor registrado na semana passada falharia por causa do momento, não do código. Por isso o teste mede dois binários na mesma janela de tempo, no mesmo host, alternando a ordem a cada repetição para que o aquecimento do lado do provedor atinja os dois, e compara as medianas.

A é a referência: por padrão, a tag `*-nightly` mais recente alcançável a partir de `HEAD`, extraída com `git archive`, compilada uma vez e depois guardada em cache dentro do diretório de trabalho, para que execuções seguintes a reaproveitem. B é o candidato, o `zurg` que este repositório acabou de compilar. **Uma métrica falha quando B está pior que A em mais de 5%** (`BENCH_TOLERANCE`); quando está melhor, é reportada como melhoria, e uma métrica ausente de um dos lados aparece como `n/a`, e não como regressão.

A cada repetição, ele mede: abertura a frio, tempo até o primeiro byte, uma leitura de 64 MiB e a mesma leitura de 64 MiB de novo, já com cache (warm), um scrub de oito pontos, uma leitura de 256 MiB com CPU-segundos por gigabyte e pico de RSS ao lado (só Linux — ambos vêm de `/proc`), e a leitura da duração do contêiner feita pelo `ffprobe`.

A correção é verificada só no candidato, e nunca pelo relógio: cada leitura registra um md5 que precisa bater com uma constante registrada e precisa concordar entre os dois binários; a release danificada precisa servir os bytes originais ou silêncio, e nada mais; e o reparo precisa chegar ao original e continuar correto depois de um restart.

O corpus fica versionado em `integration/nzbbench/corpus/`: seis NZBs para seis perguntas:

| NZB | O que é | Para que serve |
|-----|------------|----------------|
| `ToyStory5.nzb` | um WEB-DL de 6.61 GB, 1,576 artigos de 4 MiB | todos os números de vazão e latência, e a verificação do ffprobe |
| `ToyStory5Damaged.nzb` | a mesma release, mas com o message-id do artigo 21 corrompido, então qualquer servidor responde `430` | o buraco precisa ser lido como os bytes originais ou como silêncio — qualquer outra coisa é um bug de correção; depois o PAR2 precisa reparar, e o reparo precisa sobreviver a um restart |
| `Obfuscated.nzb` | o mesmo filme postado como sete arquivos sob `<hex> [n/7] yEnc`, cujo nome real só pode ser recuperado pelo índice do PAR2 | as etapas de nomes: ele precisa aparecer na listagem com o nome real `.mkv` e o tamanho certo, sem nenhum `.par2` visível |
| `FatherBrown.nzb` | um RAR de 11 volumes com um episódio, um diretório `Sample/` e um nfo | o leitor de arquivos: a estrutura de pastas precisa sobreviver, e as leituras dentro do arquivo têm número de vazão próprio (`rar_read_MBps`, uma leitura por repetição) |
| `WrongTurn3.nzb.gz` | um 7z sem compressão de 58 GB em 54 volumes de 1 GiB (o último menor) mais sete arquivos PAR2, uma árvore completa de BluRay UHD; compactado com gzip porque o NZB tem 7 MB sem compactação | o leitor de 7z dividido: os volumes precisam ser unidos e o cabeçalho no fim do último lido antes de qualquer listagem, e é essa listagem que é cronometrada (`sevenzip_list_s`, uma por repetição, a partir de um layout limpo); o stream do filme de 57.6 GB então precisa responder 16 MiB em 8 GiB com o md5 registrado, o que é uma verificação de correção, não de tempo. Sem número de vazão — cada volume dessa release está sem cerca de um quinto dos artigos neste provedor, então uma leitura cronometrada mediria a descoberta de buracos |
| `NestedRar.nzb` | um repost XviD de dois CDs: um conjunto externo de volumes RAR5 cujos membros são os volumes de dois outros conjuntos RAR, em `CD1/` e `CD2/`, mais um clipe em `Sample/` e um nfo | o leitor de arquivos aninhados: os dois conjuntos internos precisam ser abertos — o teste plano recusa dois conjuntos comparáveis, e são os diretórios do postador que os agrupam — com os dois filmes listados nos tamanhos reais e com número de vazão próprio (`nested_read_MBps`, uma leitura por repetição) |

**Uma conta, uma instância.** Um segundo zurg numa conta de notícias disputa com o primeiro a cota de conexões, e o servidor recusa a instância *mais antiga* — em `fun`, o `zurg-usenet` de produção ocupa todas as conexões que o plano da conta permite, então o benchmark roda com 10 (`BENCH_NNTP_CONNECTIONS`) e uma recusa `Too many connections` é reportada como **skip, não como falha**. O mesmo vale para um servidor inacessível ou um `AUTHINFO` rejeitado: o ambiente não conseguiu responder à pergunta, então o teste diz isso em vez de culpar o build.

Cerca de 15–20 minutos com as quatro repetições padrão, mais alguns minutos extras, uma única vez, na primeira vez em que a referência precisar ser compilada.

| Variável | Padrão | Descrição |
|----------|---------|-------------|
| `PORT` | `12358` | Porta das instâncias zurg do benchmark (uma por vez) |
| `WORK_DIR` | `$TMPDIR/zurg-nzb-bench` | Guarda a config gerada, os diretórios de execução e os logs dos dois binários, o `report.json` e o binário de referência em cache. É mantido entre execuções — o `data/` persistido é o que faz as repetições seguintes medirem um restart e não um aprendizado a frio |
| `BENCH_ENV_FILE` | `~/.config/zurg/bench-account.env` | Arquivo de conta, carregado quando existe. Linhas `KEY=value` para as variáveis `BENCH_NNTP_*`. **A forma recomendada de dar ao benchmark uma conta própria**, e o que mantém as credenciais fora do repositório e do histórico do shell |
| `CONFIG_PATH` | `config.yml` | Config de onde pegar emprestada a conta de notícias, quando nem o ambiente nem o arquivo de conta a definem: o bloco `nntp:` do primeiro provedor `type: nzb`. O empréstimo é recusado quando essa conta já tem conexões abertas aqui — veja abaixo |
| `BENCH_NNTP_HOST` / `_PORT` / `_TLS` / `_USER` / `_PASS` | *(de `BENCH_ENV_FILE`, depois `CONFIG_PATH`)* | A conta de notícias. Um valor exportado tem prioridade sobre o arquivo de conta. Se nada for encontrado em lugar nenhum → skip |
| `BENCH_NNTP_CONNECTIONS` | `10` | Conexões que o benchmark abre. É um teto: uma conta configurada com menos conexões mantém o próprio número |
| `BENCH_ALLOW_SHARED_ACCOUNT` | *(não definida)* | Defina como `1` para fazer o benchmark numa conta emprestada que já tem conexões abertas. Só quando você tiver confirmado que a conta tem folga |
| `BASELINE_REF` | a `*-nightly` mais recente alcançável a partir de `HEAD` | Com o que comparar. Resolvido depois de um `git fetch --tags` feito no melhor esforço |
| `BASELINE_BIN` | *(compilado a partir de `BASELINE_REF`)* | Uma referência já compilada, usada como está. A forma de comparar com algo que não compila mais aqui |
| `BENCH_REPS` | `4` | Repetições por binário. As medianas são calculadas sobre elas |
| `BENCH_TOLERANCE` | `0.05` | Quanto B pode piorar antes de virar regressão |
| `BENCH_SKIP` | *(nenhuma)* | Lista separada por vírgulas das fases a deixar de fora: `repair`, `obfuscated`, `rar`, `ffprobe`. O `ffprobe` é adicionado automaticamente quando não há nenhum no `PATH` nem em `bin/` |
| `REPORT_JSON` | `$WORK_DIR/report.json` | Onde o relatório é salvo |
| `STREAM_LOGS` | `true` | Acompanha o `zurg.log` do candidato no stderr. O progresso da ferramenta é impresso de qualquer forma |

O `report.json` guarda cada linha por repetição dos dois binários, as medianas, os veredictos por métrica, a saída de `version` dos dois binários, além do host e do SO — assim, um número nele pode ser lido junto com o código que o gerou. Para registrar um conjunto de números sem comparar nada, chame a ferramenta diretamente com um único `--bin`; ela mede, grava o JSON e sai com código 0:

```bash
cd integration/nzbbench && go build -o /tmp/nzbbench . && cd -
/tmp/nzbbench --config /path/to/a-config-with-an-nzb-provider.yml --port 12358 \
  --corpus integration/nzbbench/corpus --work /tmp/nzbbench-record \
  --bin candidate=./zurg --out /tmp/record.json
```

A configuração tem que ser a sua: a que o wrapper gera traz a senha da conta do servidor de Usenet em texto puro e é apagada quando a execução termina.

`integration/nzbbench/README.md` documenta as flags e os códigos de saída da própria ferramenta.

**Os códigos de saída de `nzb_bench_integration.sh`.** `0` a comparação foi feita e passou, ou o host não conseguiu fazer benchmark de jeito nenhum e a execução foi pulada; `1` uma asserção funcional falhou ou uma métrica regrediu; `4` todas as asserções funcionais passaram e o gate de tempo **não foi julgado** -- o servidor de Usenet ultrapassou o limite de estabilidade da ferramenta dentro da janela, então a comparação de throughput e latência foi descartada. O 4 é intencionalmente diferente tanto do 1 de um build quebrado quanto do 0 de um skip: nada foi decidido sobre performance, a resposta é rodar de novo numa janela mais tranquila, e a execução imprime um banner nomeando o gate e os spreads que o quebraram. `make integration-test` transforma qualquer linha de receita que falhe no exit 2 próprio do make, então uma rodada da suíte mostra isso como um make com código diferente de zero mais esse banner, no lugar da linha "All integration tests passed." do target; chame o script diretamente quando algo precisar tratar o 4 por si só.

### Pré-requisitos {#prerequisites-1}

- Token do Real-Debrid no `config.yml` (como um provedor `realdebrid`) ou `RD_TOKEN`
- `curl`, `python3` e um binário do zurg já compilado
- `shellcheck` para o `make lint-integration` (é pulado com um aviso se não estiver instalado)
- Para os testes de mount e Plex: `fusermount`/macFUSE, um binário do rclone e
  `user_allow_other` em `/etc/fuse.conf` para que o Plex consiga ler o mount
- Para a verificação de recusa do move: o rclone corrigido gerado por
  `scripts/build-rclone-move-fix.sh`, definido tanto em `RCLONE_BIN` quanto em `RCLONE_TEST_BIN`. Um rclone upstream mais novo e sem o patch não basta. Veja [a regressão do MOVE](rclone-move-refusal.md).
  Forneça um helper já compilado por meio de `DOTNET_MOVE_PROBE_BIN`, ou o Docker para compilá-lo. Ao compilar com um usuário de container sem privilégios, dê ao .NET um `XDG_DATA_HOME` gravável, além dos diretórios de cache da CLI e do NuGet.
- Para o benchmark de Usenet: uma conta de notícias, além de Go, `git`, `tar` e `make`. Ele monta a baseline a partir de um `git archive` de uma tag nightly.

### Dê ao benchmark sua própria conta de newsgroup {#give-the-benchmark-its-own-news-account}

Uma cota de conexões pertence à **conta**, não a um processo. Se você apontar o benchmark para a conta em que uma instância de produção já está, as duas passam a consumir o mesmo plano ao mesmo tempo, e aí o servidor recusa a conexão *mais antiga*, que é a de produção, sem nem saber que foi o benchmark que causou isso.

Por isso, o benchmark só usa `CONFIG_PATH` como alternativa, e **se recusa a usar uma conta que já tenha conexões abertas neste host**. Dê a ele uma conta própria em `~/.config/zurg/bench-account.env`:

```
BENCH_NNTP_HOST=news.example.net
BENCH_NNTP_PORT=563
BENCH_NNTP_TLS=true
BENCH_NNTP_USER=...
BENCH_NNTP_PASS=...
BENCH_NNTP_CONNECTIONS=25
```

Escolha uma conta com folga que nada mais use: um servidor cujo limite medido esteja bem acima do que qualquer instância está configurada para usar, assim o benchmark não deixa nenhum leitor sem conexão. Qualquer valor exportado na linha de comando ainda tem prioridade sobre o arquivo, e `BENCH_ALLOW_SHARED_ACCOUNT=1` ignora a recusa, caso você já tenha confirmado que existe folga suficiente.

### Não está na suíte {#not-in-the-suite}

`rename_integration.sh`, `tag_stats_integration.sh` e `test_repair_verification.sh` não são executados por `make integration-test`. Eles ainda têm suas próprias cópias dos helpers antigos, de antes do `lib.sh`. Migre-os para o `lib.sh` e dê a cada um portas que não entrem em conflito antes de integrá-los ao teste.
