# Recursos e funcionalidades do Plex {#plex-features--capabilities}

Rodando o rex junto com o Plex Media Server, ou no lugar dele? [Migrar do Plex para o rex](../../rex/from-plex.md) explica o que manter no zurg, incluindo o seu mount do rclone, e quais configurações do Plex do zurg remover.

## Configuração e armazenamento {#configuration--storage}
- Chaves de configuração documentadas em [`config.md`](../reference/config.md)/`config.example.yml`: `plex_server_url`, `plex_token`, `plex_match_every_mins` (padrão 1440), `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` (a grafia antiga de `watchlist.check_every_secs`, padrão 60s), `mount_path` (obrigatório para a correspondência e para montar os caminhos de escaneamento). As configurações feitas pelo painel são salvas diretamente no `config.yml` através do gravador de configuração (`updateConfigFileAtomic`).
- O intervalo da watchlist volta ao padrão para qualquer valor igual a 0 ou menor (`GetWatchlistCheckEverySecs`); `plex_match_every_mins` volta ao padrão apenas quando vale exatamente `0` (`intOr`, `internal/config/config.go`). Nenhum dos dois pode ser desativado. O painel rejeita qualquer valor menor que 1 (`internal/handlers/dashboard/dashboard.go`), e um `plex_match_every_mins` negativo no `config.yml` faz o zurg parar na inicialização com `is negative; use 0 for the default`; ele nunca desliga a correspondência.
- A aquisição pela watchlist é configurada pelo bloco `watchlist:` — `enabled`, `check_every_secs`, `indexers`, `max_size_gb`, `max_season_size_gb` e `quality` (padrão `best`). Um `indexers` vazio usa emprestado o `stremio.indexers`. As chaves planas `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` e `watchlist_quality` continuam valendo como as grafias antigas da primeira, da segunda e da última dessas opções. Veja [config.md](../reference/config.md#watchlist).
- `mount_path` também é o prefixo dos caminhos de escaneamento enviados ao Plex e do mount rclone gerenciado ([`config.md`](../reference/config.md), `pkg/scan/scanner.go`).
- O hook de atualização da biblioteca (`on_library_update`) recebe cada caminho alterado como argumento, com debounce de 500 ms e sem duplicatas, com uma única invocação por vez, o que permite usar scripts de autoscan do Plex (`internal/torrent/hooks.go`).

## Autenticação e descoberta do servidor {#authentication--server-discovery}
- Fluxo do painel web: `/plex/auth` cria uma sessão com PIN (`pkg/plex/auth.go`, `CreatePlexAuthURL`), guarda essa sessão em `pkg/plex/auth_session.go` (limpeza automática depois de 10 min, varredura a cada 5) e fica consultando a conclusão via `/plex/auth/status` (`PollForAuthToken`, 60 tentativas com intervalo de 5s antes de dar timeout).
- `/plex/callback` mostra uma página de progresso que, depois da autorização, chama `/plex/servers` para listar os servidores e `/plex/server` para selecionar um deles (`internal/handlers/dashboard/dashboard.go`).
- Descoberta de servidores (`pkg/plex/auth.go`): busca os recursos do Plex com os endpoints HTTP e HTTPS, filtra o relay se existir um endpoint direto, trata endereços IPv6 e testa o `/identity` de cada entrada (com verificação TLS desativada). Só são considerados servidores **de sua propriedade** da conta (`device.Owned`, `auth.go`), então servidores compartilhados nunca aparecem. Entradas que falham no teste são removidas da resposta, em vez de voltarem com `last_error` preenchido (`enrichServersWithIdentity`, `auth.go`).
- Ao selecionar um servidor, são gravados `plex_server_url`/`plex_token` na configuração, o cliente do Plex é reinicializado, o agendador do matcher é (re)iniciado, um gatilho de correspondência é disparado e o status do painel em cache é atualizado (`HandlePlexServerSelect`, `internal/handlers/dashboard/dashboard.go`). `/plex/logout` limpa os valores guardados e o cache de status.

## Capacidades do cliente Plex (`pkg/plex/client.go`) {#plex-client-capabilities-pkgplexclientgo}
- Ciclo de vida da conexão: opção de início adiado (`WithDeferredStart`), guarda `ValidateConnection` contra `/identity`, `Close` gracioso. Não existe API de reinício. O `RestartAllowed`/`RestartReason` do dashboard é inferido a partir da URL do servidor (local/LAN vs. remoto) e serve só para exibição (`internal/handlers/dashboard/plex_status.go:getPlexConnectionDetails`).
- Fila de scan: fila e worker de jobs dinâmicos (`common.DynamicJobQueue`). `ProcessJob` faz `GET /library/sections/{key}/refresh` com os headers do Plex e **no máximo um** parâmetro de query `path` por job. Mais de um é rejeitado de cara (`client.go`). Um job sem path é um refresh da seção inteira. 503 vira um erro de servidor ocupado, 404 informa que a biblioteca foi apagada do Plex. `GetJobQueueSize` expõe o backlog.
- Detecção de carga e de travamento: `CheckServerLoad` inspeciona `/activities`, acompanha o progresso de `library.update.section` por UUID (um progresso *ou* subtítulo que mudou conta como progresso), e `IsJobStuck` marca jobs parados pelo `librarySectionID`, com fallback para o Title. `GetServerActivitiesDetails` cria e aposenta os mesmos trackers, porque `CheckServerLoad` só roda enquanto o worker tem um job na fila. Antes, um scan que o próprio Plex iniciou não ganhava tracker nenhum. Por isso nunca podia ser reportado como travado, e o tempo decorrido aparecia como zero a cada refresh. Os dois caminhos mantêm histórico só para `library.update.section`. Rastrear qualquer outra coisa aqui faria o tracker oscilar com a limpeza (prune) do worker.
- **O subtítulo da atividade não é o arquivo em que um scan parado está preso.** Medido no rig plex503, em 2026-09-15: o subtítulo de `library.update.section` é o ponteiro de enumeração do scanner e fica à frente das leituras. Com o mount recusando três arquivos, ele citou um quarto que nunca tinha sido pedido, e citou o arquivo bloqueado por 290 ms de um ciclo de 56 s. O dashboard mostra isso como "Plex reports" e não liga a um release. O que o scan está realmente esperando vem das recusas do próprio zurg (`internal/universal/refused_reads.go`), que é o único lado que sabe. O corpus está em `internal/handlers/dashboard/testdata/plex503-*`.
- Consultas à biblioteca: `GetSections` (seções de filmes/séries com locations), `GetSectionItemCount`, `FindSectionNormalized` (confere um path com uma location da seção e corrige o prefixo para o casing da biblioteca), `GetAllMediaItemsConcurrent` (busca concorrente em lotes, com `includeGuids` para coletar paths, GUIDs e IDs do IMDB), e `GetShowLevelIMDBIndex` (IDs no nível da série para seções de TV, para que os episódios herdem esses IDs).
- Auxiliares de metadados e matching (`pkg/plex/match.go`): `GetMetadataSummary` (`GET /library/metadata/{ratingKey}`), `GetMatchCandidates` (`GET /library/metadata/{ratingKey}/matches?manual=1`, com overrides de title/year/language), `LookupMetadataByGUID`/`LookupRatingKeyByGUID` (`GET /library/all?guid=…`), `ApplyManualMatch` (`PUT /library/metadata/{ratingKey}/match`), e parsing de GUID (`ExtractIMDBIDFromGUID`, `ExtractTMDBIDFromGUID`, `ExtractTVDBIDFromGUID`, `ExtractAnyIDFromGUIDs`; tipos `MatchResult`/`MatchSelection`).
- Informações do servidor: `GetServerIdentityOnly` e `GetServerDetails` (machine ID/versão; esta última também totaliza sessões/transcodificações/banda), `GetStreamingSessions`, `GetTranscodeSessions`, `GetServerActivitiesDetails` (anotada com o status de travamento).
- Histórico de exibição: `GetWatchHistory` (`GET /status/sessions/history/all`), `GetMetadataBatch` (rating keys separadas por vírgula consultando `/library/metadata`), e `GetWatchHistoryWithMetadata` (`pkg/plex/history.go`), alimentando as estatísticas em `pkg/plex/stats.go`.

## Integração do scanner de mídia (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- Inicializa o cliente do Plex quando `mount_path`, `plex_server_url` e `plex_token` estão definidos; tenta de novo a cada 5s até conectar, disparando os callbacks de `OnPlexReconnected`.
- `TriggerScan` agrupa os caminhos por seção do Plex (via `FindSectionNormalized`) e coloca na fila um job de atualização por caminho com o prefixo de `mount_path`, registrando o progresso a cada 50. Também funciona com Jellyfin/Emby, que recebem o caminho sem agrupamento. Um caminho que não cai em nenhuma seção só gera aviso quando *nenhum* dos caminhos do lote deu match; caso contrário, é apenas uma linha de debug. Assim, um torrent que está tanto em uma pasta da biblioteca quanto em uma pasta só do zurg (recent, music, …) não gera aviso.
- `ReinitializePlexClient` permite que as atualizações do dashboard troquem servidores e tokens ao vivo.
- `GetQueueSizes` expõe a profundidade da fila do Plex para a UI e para o monitoramento.

## Correspondência e sincronização de metadados (`internal/plex/matcher.go`, `internal/plex/schedule.go`) {#matching--metadata-sync-internalplexmatchergo-internalplexschedulego}
- Pré-requisitos: precisa ter a URL e o token do Plex configurados, `mount_path` e um `scanner.PlexClient` ativo. Se algum deles faltar, a função retorna erros explícitos.
- O único estado do Plex guardado em um torrent é `PlexRatingKey` (no nível da série, para conteúdo episódico) e `IMDBID` (`internal/torrent/torrent_types.go`). Os GUIDs do Plex são usados durante a execução para extrair e reportar IDs, mas nunca são salvos.
- Coleta de dados: busca todos os torrents do mapa de diretórios e todos os itens do Plex via `GetAllMediaItemsConcurrent`. Antes disso, roda uma passada `GetShowLevelIMDBIndex`, para que os episódios herdem o ID IMDB/TVDB/TMDB da série em vez de um ID próprio do episódio. Os itens são indexados pelo `GrandparentRatingKey`, quando ele existe.
- Etapas da sincronização:
  - Valida cada rating key guardada contra os itens do Plex recém-buscados. Se o Plex não tiver mais uma chave, ela é limpa junto com o ID IMDB do torrent, e o torrent é colocado de volta na fila para nova correspondência.
  - Correspondência por caminho para torrents sem rating key: `buildPlexDirIndex` indexa cada componente de caminho em minúsculas de cada arquivo do Plex, e o `GetKey` do torrent é procurado ali (O(1), vale a primeira entrada). Torrents cujos diretórios atribuídos não batem com nenhuma localização de seção do Plex são pulados logo no início.
  - Preenchimento de IMDB: primeiro usa o lote já buscado (sem chamadas de API) e depois, torrent por torrent, via `GetMetadataSummary` (no máximo 20 em paralelo).
  - Detecta itens do Plex que não têm nenhum torrent.
  - Envia para o DMM os pares hash+IMDB que a pessoa definiu manualmente, nunca IDs que o Plex adivinhou. O DMM aceita esses pares sem chave, e o `dmm_api_key` vai junto quando estiver definido (`sendHashImdbPairs` → `TorrentManager.SendHashImdbPairs`, `internal/torrent/mediainfo.go`).
- `MatchSingleTorrent` roda a mesma busca por caminho para um único torrent, usada logo depois de uma varredura direcionada. Ela não faz nada se o torrent já tiver uma rating key.
- Relatório: grava `logs/match_report.txt` com a contagem, os torrents sem correspondência, os torrents pulados, os itens do Plex sem torrents e as correspondências sem IMDB.
- Agendamento (`internal/plex/schedule.go`): cada execução concluída grava o carimbo em `data/plex_match_timestamp`. Ao iniciar, `StartMatchingJob` roda na hora só se o carimbo estiver ausente ou for mais antigo que `plex_match_every_mins`. Caso contrário, espera o tempo que falta antes de rodar. Ele escuta gatilhos manuais em `TorrentManager.PlexMatchTrigger`, mudanças de intervalo em tempo real em `ResetPlexMatchTicker`, e roda o job de novo até três vezes se ele der panic.
- O endpoint de gatilho manual `/plex/match-torrents` envia um sinal para o canal de gatilho e recusa a execução se já houver uma rodando. `/plex/match-torrents/status` informa se uma execução está em andamento (`internal/handlers/utilities.go`).

## Correspondência manual e interface de gerenciamento (`internal/handlers/manage`) {#manual-matching--manage-ui-internalhandlersmanage}
- Filtros da lista de torrents expõem estados do Plex (`plex_matched`, `plex_in_library_not_matched`, `plex_no_imdb`, `plex_missing_metadata`) para visualizações rápidas (`torrent_list_state.go`).
- Página de correspondência manual por torrent `/manage/{hash}/plex-match`:
  - Exige que o torrent já tenha um `PlexRatingKey` (definido pelo matcher); caso contrário, a página mostra "torrent is not linked to Plex". `resolvePlexRatingKey` valida essa chave com `GetMetadataSummary`, preenche um IMDB ID ausente a partir dela e, se a chave estiver desatualizada, resolve de novo via `LookupRatingKeyByGUID` usando o ID `tt…`/`tvdb://`/`tmdb://` salvo no torrent (`internal/handlers/manage/handler.go`).
  - Busca os candidatos de correspondência manual do Plex com substituições opcionais de título/ano/idioma (44 opções de idioma, padrão `en-US`); exibe as correspondências com a seleção atual destacada (`torrent_matches.go`).
  - Ao aplicar uma correspondência (`HandleApplyPlexMatch`), chama `ApplyManualMatch`, depois busca de novo a chave pelo GUID escolhido, porque o Plex pode reatribuí-la, atualiza a chave e o IMDB do torrent (incluindo um IMDB opcional informado pelo usuário), salva as mudanças e redireciona com os estados de sucesso/erro.

## Aquisição pela watchlist {#watchlist-acquisition}

- O watchlist do Plex é um adaptador em `internal/acquisition/plex`, rodando no serviço de aquisição compartilhado junto com o Seerr. As configurações atuais do watchlist continuam funcionando, e você também pode configurar adaptadores em `acquisition.sources`.
- O cliente usa `discover.provider.plex.tv` e busca 100 itens por vez. O token do Plex é lido de novo a cada requisição, então a reautenticação vale sem precisar reiniciar o adaptador.
- O executor compartilhado adquire filmes ou cada temporada planejada nos indexadores Newznab e Torznab, dando preferência aos season packs. Nas buscas de séries, ele tenta o TVDB antes do IMDb, porque os mapeamentos dos indexadores são diferentes.
- O progresso, os prazos de nova tentativa e os comprovantes por episódio sobrevivem a reinicializações em `data/acquisition.json`. O antigo ledger do Plex é importado automaticamente.
- A remoção acontece depois que todos os alvos planejados forem adquiridos. Requisições que falharam continuam na lista de desejos e são tentadas de novo com backoff persistente. Uma nova tentativa só de remoção não adquire de novo. Veja [aquisição do watchlist do Plex](plex-watchlist.md) para os limites e [fontes de aquisição](acquisition.md) para a configuração compartilhada.

## Painel e endpoints da API (`internal/handlers/router.go`, `internal/handlers/dashboard`) {#dashboard--api-endpoints-internalhandlersroutergo-internalhandlersdashboard}
- Rotas: `/plex/auth`, `/plex/callback`, `/plex/auth/status`, `/plex/servers`, `/plex/server`, `/plex/logout`, `/plex/match-torrents`, `/plex/match-torrents/status`, `/plex/scan/{sectionKey}`, `/plex/scan-all`, `/plex-stats`, `/plex-stats/data`, `/plex-stats/image`, `/manage/{hash}/plex-match`.
- O dashboard mostra as informações e o status do servidor Plex através do `PlexStatusFetcher`, com dois timers: a cada 30s ele atualiza as sessões de streaming, as transcodificações, a largura de banda e as atividades do servidor (`GetStreamingSessions`/`GetTranscodeSessions`/`GetServerActivitiesDetails`); a cada 5 minutos ele faz uma busca completa, que também relê a identidade (`GetServerIdentityOnly`), as seções da biblioteca e a contagem de itens de cada seção. As atividades de escaneamento são cruzadas com a lista de torrents pelo nome do arquivo, para que o dashboard consiga vincular uma atividade a um hash de torrent.
- Os endpoints de escaneamento por seção e de todas as seções colocam na fila um refresh **completo** da seção (`RefreshSection(key, nil)`, sem caminho), para uma ou todas as seções. Eles não mexem nos arquivos STRM nem disparam efeitos colaterais na biblioteca (`HandlePlexScan`/`HandlePlexScanAll`).

## Plex Wrapped (`internal/handlers/dashboard/plex_wrapped.go`)
- `/plex-stats` renderiza um resumo do ano em 9 slides com o histórico de exibição do Plex dos últimos 12 meses; `/plex-stats/data` retorna as mesmas estatísticas em JSON, e `/plex-stats/image` gera um PNG para compartilhar usando headless chromedp (`square` 1080x1080 por padrão, `instagram` 1080x1920, `facebook` 1200x630).
- As estatísticas são buscadas no máximo uma vez a cada 24h (`?refresh=true` força a atualização), com limite de 10000 itens do histórico, e ficam em cache tanto na memória quanto no disco, em `data/plex_wrapped_cache.json`, que é recarregado na inicialização. Enquanto a busca está em andamento, a página mostra um estado de carregamento em vez de travar.

## Efeitos colaterais na biblioteca e links de atualização {#library-side-effects--refresh-links}
- Os efeitos colaterais da biblioteca são disparados em mudanças de atribuição de diretório, renomeações, exclusões e reparos de arquivos: `TriggerLibrarySideEffects` invalida o dircache do rclone VFS para os caminhos afetados (para que os servidores de mídia não escaneiem uma listagem desatualizada), chama `MediaScanner.TriggerScan` (acionando o refresh do Plex) e executa o hook `on_library_update` do usuário (`internal/torrent/hooks.go`).
- O pipeline de refresh só executa a geração de STRM e os efeitos colaterais depois que a inicialização termina, para evitar scans prematuros no Plex (`internal/torrent/refresh.go`).

## Infraestrutura e scripts {#infrastructure--scripts}
- Exemplo de vhost do Nginx para fazer proxy do tráfego do Plex (`nginx/plex.conf`).
- `plex_update.sh` é o script de referência para scan parcial, usado em `on_library_update: sh plex_update.sh "$@"`. Coloque-o ao lado do `docker-compose.yml`, cuja pasta é montada em `/config`, então o script já fica dentro do container. No Windows, o hook roda pelo PowerShell em vez de `/bin/sh` (`pkg/script/script.go`), então este script não roda lá. [Usenet → Point Plex at it](usenet.md#6-point-plex-at-it) mostra a forma em PowerShell.
- `integration/plex_integration.sh` roda com `make integration-test` e `make integration-test-media`. Ele pula com um aviso bem visível em um host sem servidor Plex, então leia a saída em vez de confiar apenas no código de saída. `scripts/plex-e2e-test.sh` é uma verificação de reprodução independente que lê `plex_server_url`/`plex_token` do `config.yml`.

## Configurações recomendadas do Plex {#recommended-plex-settings}

Os padrões do Plex partem do pressuposto de discos locais que estão sempre presentes e livres para leitura. Um mount do zurg não é nenhum dos dois: os bytes dele vêm de um provedor via HTTP, e ele pode ficar brevemente ilegível enquanto o rclone reconecta. Vários padrões do Plex são claramente prejudiciais nessas condições.

O zurg reconcilia essas configurações a cada atualização de status do Plex. `plex_settings_policy` decide até onde ele vai: `off`, `warn`, `guard` (padrão) ou `enforce`. A lista fica em `pkg/plex/settings.go` (`RecommendedSettings`), e a política fica em `pkg/plex/reconcile.go`.

Uma configuração que o servidor não informa é ignorada. Assim, uma versão do Plex que não tenha uma delas não é reportada como mal configurada.

Nove dos dezesseis valores abaixo são diferentes do padrão do próprio Plex. Os outros sete coincidem com ele e funcionam como guardas, e não como correções: só disparam para quem tiver ativado uma dessas opções. Essas linhas mostram o mesmo valor nas duas colunas, e isso não é um erro. O Plex vem com `GenerateBIFBehavior` em `never`, mas o servidor em que estes valores foram medidos estava em `scheduled`. O Plex informa o próprio padrão de cada configuração em `/:/prefs`, então a coluna "Plex ships" abaixo é lida do servidor, e não presumida (medido em 2026-09-05 com o Plex 1.42.2).

### Desativando uma configuração {#opting-out-of-one-setting}

`plex_settings_policy` tem níveis, e o nível nem sempre é a pergunta que está sendo feita. Um operador cujos arquivos se movem entre pastas da biblioteca (por exemplo, organização por tags) depende de o Plex esvaziar a própria lixeira para apagar a entrada que ficou para trás, e `guard` desliga isso. Mudar para `warn` para recuperar essa função também abre mão das guardas de eventos do sistema de arquivos, que estão no mesmo nível e não são o que você pediu.

`plex_settings_ignore` nomeia as configurações uma a uma:

```yaml
plex_settings_policy: guard
plex_settings_ignore:
  - autoEmptyTrash
```

O painel escreve isso para você. A página de configuração tem uma chave **Let Plex Empty Its Own Trash** acima das configurações de Library Trash Sweep. Ela adiciona e remove `autoEmptyTrash` aqui e deixa o resto da lista como está. Ao ligar, a mudança vale na próxima reinicialização.

Uma configuração ignorada continua sendo lida e continua aparecendo no painel e em `zurg plex-settings` (marcada como `skip`), então nada fica escondido. Ela só nunca é escrita, nunca é contada como problema e nunca aciona o banner de lixeira do painel. Os ids não diferenciam maiúsculas de minúsculas. Um id que não corresponde a nenhuma configuração nas tabelas abaixo é reportado na inicialização e a configuração continua protegida, já que um erro de digitação não pode passar como opt-out.

Ignorar uma configuração de segurança é por sua conta e risco, e o zurg avisa isso uma vez ao iniciar, não a cada atualização. `autoEmptyTrash`, em especial, é a configuração que esvazia uma biblioteca quando uma varredura encontra um mount que falhou por um instante. Ignorá-la também devolve ao Plex a tarefa de limpeza, veja abaixo.

### Quem esvazia a lixeira {#who-empties-the-trash}

Desligar `autoEmptyTrash` deixa um trabalho sem fazer. O Plex foi instruído a não apagar entradas cujos arquivos sumiram, e, por muito tempo, a remoção do próprio zurg era opcional. Por isso, por padrão, a biblioteca acumulava entradas mortas e nada as recolhia. Nenhum dos lados estava errado, mas a lacuna era real: é o que alguém encontra quando um arquivo muda de pasta na biblioteca e a entrada antiga fica para sempre.

O zurg agora assume a tarefa que tirou dele. Com `plex_trash_sweep_every_mins` sem valor, a [varredura da lixeira](../internals/plex-trash-sweep.md) remove as entradas a cada 60 minutos, mas só quando mais ninguém está fazendo isso. Se o Plex ainda esvazia a própria lixeira, porque `plex_settings_policy` está `off` ou `warn`, ou porque `autoEmptyTrash` está em `plex_settings_ignore`, o zurg se retira e deixa a tarefa com o Plex. Dois coletores na mesma biblioteca fazem com que uma divergência entre eles vire uma exclusão.

A varredura é bem mais restrita que o esvaziamento do próprio Plex, e isso é justamente o motivo de preferi-la. Ela remove uma entrada por vez, nunca uma que ainda tenha arquivo, e só de um mount que esteja respondendo naquele momento. Tem limite de 50 remoções e 10% da lixeira por passagem. Entradas sobre as quais ela não tem veredito ficam visíveis como quebradas por 14 dias antes. Ela também precisa de `plex_database_path` definido, então só roda onde o Plex está neste host, e com o próprio zurg rodando o mount (`rclone_enabled` com `mount_path` definido). O zurg lê esse banco com o programa `Plex SQLite` que o Plex instala, e o encontra onde o instalador do Plex o coloca no Linux, macOS e Windows. Por isso, `plex_database_path` é a única chave que você precisa definir:

+++ Linux
```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ macOS
```yaml
plex_database_path: "/Users/YOU/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ Windows
```yaml
plex_database_path: 'C:\Users\YOU\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db'
```
Mantenha as aspas simples: dentro de aspas duplas, o YAML lê a barra invertida como caractere de escape. Defina `plex_sqlite_binary` apenas para um Plex instalado em outro lugar, como um Plex de 32 bits: `'C:\Program Files (x86)\Plex\Plex Media Server\Plex SQLite.exe'`.
+++

Substitua `YOU` pelo seu nome de usuário: o zurg não expande `~` nem `%LOCALAPPDATA%`. A varredura compara os caminhos que o Plex guarda com `mount_path`, o que trata uma letra de unidade como `Z:` (`pkg/utils/path_within.go`).

Para manter a remoção desligada e esvaziar a lixeira você mesmo, escreva `plex_trash_sweep_every_mins: 0`. Isso é o não explícito, e é diferente de deixar a chave de fora.

Essa chave só desliga a remoção do próprio zurg. Ela não devolve a configuração ao Plex. Com `guard`, o zurg ainda grava `autoEmptyTrash` como desligado, então o Plex continua sem esvaziar a lixeira depois de uma varredura, e as entradas se acumulam sem nada para recolhê-las. Use o interruptor do painel ou `plex_settings_ignore` para devolver a tarefa ao Plex.

### Segurança — corrigida em `guard` e `enforce` {#safety--corrected-under-guard-and-enforce}

Esses itens fazem você perder dados, e não tempo. Por isso a política padrão os grava em vez de apenas avisar. Só o `autoEmptyTrash` vem com o valor destrutivo. Os outros três já vêm com o padrão que o zurg quer e estão aqui para pegar um operador que tenha ativado algum deles.

| Preferência | Padrão do Plex | zurg quer | Motivo |
|---|---|---|---|
| `autoEmptyTrash` | `1` | `0` | O Plex esvazia a lixeira depois de cada scan. Se a montagem ficar brevemente ilegível enquanto um scan está percorrendo, cada arquivo aparece como excluído, e o Plex os remove permanentemente em vez de deixá-los na lixeira para voltar com a montagem. |
| `FSEventLibraryUpdatesEnabled` | `0` | `0` | Atualizações orientadas a eventos não captam o que realmente muda aqui. A árvore do zurg muda do lado dele, o que nunca passa pelo kernel local, então nenhum evento é gerado e a biblioteca fica desatualizada sem aviso. Os eventos que chegam são gravações feitas *através* da montagem, que acontecem enquanto um diretório ainda está sendo montado. |
| `FSEventLibraryPartialScanEnabled` | `0` | `0` | Um scan parcial roda com base nesses mesmos eventos, então dispara nas gravações que passam pela montagem, exatamente quando um diretório está pela metade, e nunca nas mudanças do lado remoto que realmente precisariam de um scan. |
| `ButlerTaskBackupDatabase` | `1` | `1` | O backup noturno do banco de dados é a única coisa que recupera uma biblioteca que o Plex já excluiu. |

Os dois motivos de `FSEvent` foram reescritos depois de medidos, em todas as plataformas onde o zurg monta. O texto anterior dizia que uma montagem FUSE "não os emite de forma confiável, então isso gera scans em momentos que ninguém pediu". As duas partes estão erradas.

Medido em 2026-09-05, cada plataforma foi monitorada com a API que o servidor de mídia realmente usa, contra uma montagem do rclone cujo diretório de origem podia ser alterado diretamente. **A** é uma gravação feita através da montagem; **B** é o mesmo arquivo aparecendo do outro lado, como acontece quando a árvore do zurg muda.

| Plataforma | Montagem | Monitorado com | A: através da montagem | B: alterado do outro lado |
|---|---|---|---|---|
| Linux | `fuse.rclone` | inotify | `CREATE` `OPEN` `ATTRIB` `CLOSE_WRITE` | **nenhum evento** |
| Docker | mesma montagem, montada dentro de um container | inotify, dentro do container | as mesmas quatro, vistas no container | **nenhum evento** |
| macOS | macFUSE | FSEvents | `Created IsFile` | **nenhum evento** |
| Windows | WinFsp | `ReadDirectoryChangesW` | `Created` `Changed` | **nenhum evento** |

Todas as plataformas entregaram A, e um controle na mesma execução em um sistema de arquivos nativo (APFS, NTFS) gerou os mesmos eventos, então os monitores estavam funcionando. Nenhuma entregou B, mesmo com o arquivo visível através da montagem depois que o cache do diretório expirou.

Então o modo de falha é o oposto do que foi dito: uma atualização orientada a eventos dispara nas gravações que chegam *através* da montagem (uma importação do \*arr caindo em um diretório que ainda está sendo montado) e nunca dispara nas mudanças do lado remoto, que são justamente o motivo de existir um scan. Não é que os eventos sejam pouco confiáveis. É que eles informam a metade errada do que acontece em uma montagem de debrid.

### Banda — corrigida apenas em `enforce` {#bandwidth--corrected-under-enforce-only}

Cada uma dessas opções faz o Plex decodificar arquivos inteiros para um resultado que ninguém vê. Não tem problema no armazenamento local; numa montagem de debrid, cada byte é uma requisição ao provedor, e isso roda na biblioteca inteira. A análise cuja saída *é* visível — prévias ao arrastar a barra, imagens de capítulos, nivelamento de volume, análise sonora — fica na camada de preferências abaixo, onde o `enforce` não mexe.

| Preference | Plex default | zurg wants |
|---|---|---|
| `ButlerTaskDeepMediaAnalysis` | `1` | `0` |
| `ButlerTaskUpgradeMediaAnalysis` | `1` | `0` |
| `GenerateAdMarkerBehavior` | `scheduled` | `never` |
| `GenerateVADBehavior` | `never` | `never` |
| `GenerateIndexFilesDuringAnalysis` | `0` | `0` |
| `ButlerTaskGenerateMediaIndexFiles` | `0` | `0` |

### Hábitos — sempre reportados, nunca corrigidos {#taste--always-reported-never-corrected}

There is a feature behind each of these, so zurg says what the value costs and leaves the choice alone. Turning one off unasked would take away something the operator can see, which is not zurg's call however much bandwidth it would save. For the first two the cheaper option keeps the feature and moves the work into the maintenance window; for the rest the choice is the feature or the bandwidth.

| Preference | Plex default | zurg suggests | Why |
|---|---|---|---|
| `GenerateIntroMarkerBehavior` | `asap` | `scheduled` or `never` | `asap` decodes each file the moment it lands, outside any maintenance window. `scheduled` keeps the Skip Intro button and moves the work into the window. |
| `GenerateCreditsMarkerBehavior` | `asap` | `scheduled` or `never` | O mesmo, para o Skip Credits. |
| `GenerateBIFBehavior` | `never` | `never` | Decodes the whole video to build the image strip shown while scrubbing. Playback does not need it. |
| `GenerateChapterThumbBehavior` | `scheduled` | `never` | Decodes the file to pull one frame per chapter, for the picture beside each entry in the chapter list. |
| `LoudnessAnalysisBehavior` | `scheduled` | `never` | Fully decodes every file's audio to measure it, for volume levelling between tracks and titles. |
| `MusicAnalysisBehavior` | `scheduled` | `never` | Decodes every track — many small files, so this is the request count that gets an account rate-limited. Buys sonic analysis: similar-track mixes and the visualiser. |

### A janela de manutenção {#the-maintenance-window}

zurg não mexe em `ButlerStartHour`/`ButlerEndHour`, porque não existe um horário que sirva para todo mundo. Vale a pena configurar isso manualmente: o Plex usa 02:00–05:00 por padrão, e uma janela que se sobreponha aos horários em que as pessoas assistem faz todas as tarefas de manutenção travarem. Tudo o que sobrar na faixa de banda roda dentro dessa janela.

### Parando uma execução já em andamento {#stopping-a-pass-already-in-flight}

Mudar uma preferência vale só para as *próximas* execuções, não para a que já está rodando. O Plex Media Server recria os processos filhos do scanner, então matá-los não adianta:

+++ Linux e macOS
```bash
curl -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
+++ Windows
```powershell
curl.exe -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
No Windows PowerShell 5.1, `curl` é só outro nome para `Invoke-WebRequest`, então digite `curl.exe`.
+++

Primeiro, defina `$TOKEN` com o seu token do Plex: `TOKEN=your-token` no shell, `$TOKEN = 'your-token'` no PowerShell.
