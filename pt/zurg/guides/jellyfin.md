# Recursos e capacidades do Jellyfin {#jellyfin-features--capabilities}

## Configuração e armazenamento {#configuration--storage}
- Chaves de config ([`config.md`](../reference/config.md), `config.example.yml`): `jellyfin_server_url` (string, padrão `""`), `jellyfin_token` (string, padrão `""`). As duas vêm comentadas no `config.example.yml` e não existem no `config.simple.yml`. `mount_path` precisa estar definido, senão a escaneamento de mídia (incluindo o Jellyfin) fica desativada (`pkg/scan/scanner.go`).
- Os valores são salvos no `config.yml` pelo dashboard (`updateConfigFileAtomic`); não existe um arquivo de dados separado para o Jellyfin. Os campos e os helpers `Get`/`Set` ficam no `zurgConfig` em `internal/config/config.go`; o `ZurgConfigV1` (`internal/config/filters.go`) incorpora essa struct inline.

## Autenticação e validação do servidor (QuickConnect) {#authentication--server-validation-quickconnect}
- Fluxo do QuickConnect no Dashboard:
  - `/jellyfin/check-server` verifica se o servidor responde via `System/Info/Public` e informa a versão, o nome e se o QuickConnect está disponível (`HandleJellyfinCheckServer`, `pkg/jellyfin/auth.go:CheckServerReachable/CheckQuickConnectEnabled`).
  - `/jellyfin/auth` inicia o QuickConnect (`InitiateQuickConnect`), cria uma sessão de autenticação vinculada ao cookie (`pkg/jellyfin/auth_session.go`) e começa a consultar o status em segundo plano.
  - `/jellyfin/auth/status` retorna o estado de conclusão ou erro enquanto consulta `/QuickConnect/Connect` + `/Users/AuthenticateWithQuickConnect` (`PollForQuickConnectAuth`, 60 tentativas com intervalo de 5s antes de dar timeout).
  - `/jellyfin/server` salva a URL e o token do servidor na config, reinicializa o cliente do Jellyfin e responde com sucesso ou aviso caso a reinicialização falhe (`HandleJellyfinServerSelect`).
  - `/jellyfin/logout` limpa a config, reinicializa o scanner sem o Jellyfin e descarta o status em cache do dashboard (`JellyfinStatusFetcher.ClearCache`).
- O gerenciador de sessões de autenticação acompanha as sessões do QuickConnect, guarda o secret, o código, o token e as informações do usuário, e faz a limpeza depois de 10 minutos (verificando a cada 5). Ele também oferece getters thread-safe (`pkg/jellyfin/auth_session.go`; instância global em `auth_global.go`).
- Os helpers do QuickConnect em `pkg/jellyfin/auth.go` enviam o header padrão `Authorization: MediaBrowser …` e rodam com a verificação de TLS desabilitada para aceitar certificados autoassinados (`newHTTPClient`). O cliente de scan não faz isso: `mediabrowser.NewCore` cria um `http.Client` simples com timeout de 30s (`pkg/mediabrowser/core.go`). Por isso, um servidor atrás de um certificado autoassinado faz o pareamento e a validação sem problemas, mas as chamadas de seção e de refresh falham no TLS.
- O endpoint de validação de token `/System/Info` é usado para confirmar as credenciais antes de salvar (`ValidateToken`).

## Capacidades do cliente Jellyfin (`pkg/jellyfin/client.go`) {#jellyfin-client-capabilities-pkgjellyfinclientgo}
- `Client` é uma casca fina em cima do `mediabrowser.Core` embutido (`pkg/mediabrowser/core.go`), compartilhado com `pkg/emby` porque os dois servidores vêm da mesma base de código. O único método próprio dele é `GetSections`; a varredura (`ProcessJob`), as atividades, o status do servidor, o ciclo de vida, a fila, o header de autenticação e o rastreamento de travamentos vêm todos do core.
- Autenticação: as chamadas ao Jellyfin enviam o header padrão `Authorization: MediaBrowser … Token="<token>"`; o cliente do Emby envia `X-Emby-Token`.
- Ciclo de vida: `NewClientWithLogger` monta o core (remove as barras finais da URL e avisa e retorna nil quando a URL *ou* o token estiver vazio). Depois, `StartWorker` inicia o worker dinâmico de varredura, a menos que `GO_TEST_MODE=1`. O `Close` desliga o worker e a fila.
- Fila de varredura: fila dinâmica de jobs + `common.DefaultWorkerConfig`. O `GetJobQueueSize` é o que o dashboard lê (via `MediaScanner.GetQueueSizes`). O `GetJobQueue` é um stub de compatibilidade que retorna uma lista de jobs vazios com o tamanho da fila.
- Detecção de carga e travamento: `CheckServerLoad` consulta `/ScheduledTasks`, acompanha as tarefas em execução cujo nome contém "scan", mantém a contagem de travamentos por tarefa e informa ocupado quando há varreduras ativas. `IsJobStuck` marca as tarefas que passam do limite de travamento.
- Rastreamento de atividades: `GetRunningTasks` retorna structs `TaskActivity` detalhadas com ID, Name, State, Progress (vindo de `CurrentProgressPercentage`), Description e o status de travamento, para exibir no dashboard.
- Status do servidor: `GetServerStatus` consulta `/Sessions` para contar as sessões de streaming ativas, as transcodificações (vídeo/áudio que não são direct) e o uso de banda, para exibir no dashboard.
- Descoberta de bibliotecas: `GetSections` chama `/Library/VirtualFolders` e retorna as seções com ID/Title/Paths (todas as pastas da biblioteca)/Type, e acrescenta a cada uma a contagem de itens via `Items?ParentId=<id>&Recursive=true&Limit=0`.
- Atualização: `ProcessJob` informa todos os caminhos alterados de um job em um único `POST /Library/Media/Updated`, com cada caminho no corpo exatamente como o servidor o vê no próprio sistema de arquivos. Um job sem caminho atualiza a biblioteca inteira com `POST /Items/{id}/Refresh`. Ele retorna `ServerBusyError` em caso de 503, um erro de "library may have been deleted" em caso de 404, e o corpo da resposta em qualquer outro 4xx/5xx. `RefreshSection` enfileira os jobs.
- Auxiliares: `FindSectionNormalized` faz a correspondência pelo prefixo do caminho (vence a primeira correspondência) e retorna o caminho com o prefixo reescrito para a capitalização da localização da biblioteca. O teste de prefixo não diferencia maiúsculas de minúsculas no macOS e no Windows, e é exato nos demais sistemas (`pkg/common/pathutil.go`).

## Integração do scanner de mídia (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- Inicializa o cliente do Jellyfin quando `mount_path`, a URL do servidor e o token estão presentes; registra sucesso no log e mantém o cliente como nil em caso de falha. Não há loop de retentativas (diferente do Plex), mas a reinicialização manual é suportada.
- `TriggerScan` envia o aviso ao Jellyfin junto com os outros servidores; `triggerJellyfinScan` resolve as seções via `FindSectionNormalized` usando caminhos com o prefixo `mount_path` e envia os caminhos alterados de cada seção em uma única requisição (o Plex recebe um caminho por requisição).
- `GetQueueSizes` retorna os tamanhos das filas do Plex, Jellyfin e Emby juntos, usando -1 para um servidor que não está conectado.
- `ReinitializeJellyfinClient` fecha qualquer cliente existente e recria com a configuração atual (usado após a autenticação no dashboard e no logout).

## Painel e rotas {#dashboard--routes}
- Router mounts Jellyfin endpoints: `/jellyfin/check-server`, `/jellyfin/auth`, `/jellyfin/auth/status`, `/jellyfin/server`, `/jellyfin/logout`, `/jellyfin/scan/{sectionID}`, `/jellyfin/scan-all` (`internal/handlers/router.go`).
- Dashboard modal (templates/scripts) drives QuickConnect, displays status/errors, and saves/removes credentials; queue size, library cards with scan buttons, and server activities surface in `dashboard.tmpl`.
- `JellyfinStatusFetcher` (`internal/handlers/dashboard/mediabrowser_status.go`) fills the dashboard JSON from a background cache rather than blocking the page: it validates the token, marks connectivity, populates the library list (ID/Name/Paths/Type/ItemCount), and collects running task activities plus session/transcode/bandwidth counts. Activities and sessions refresh every 30s; the full fetch, libraries included, every 5 minutes. `response.go` serves the cached copy (`JellyfinServerInfo`, `jellyfin_queue_size`).
- Library scan endpoints (`HandleJellyfinScan`, `HandleJellyfinScanAll`) queue a whole-library refresh with no path for individual or all library sections, as the Plex equivalents do, and 503 when no Jellyfin client is configured (`internal/handlers/dashboard/dashboard.go`).
- `jellyfin_server_url` and `jellyfin_token` are also writable through the generic config-update handlers, so they can be set without the QuickConnect modal (`handlers["jellyfin_server_url"]`/`["jellyfin_token"]` in `dashboard.go`; `updateJellyfinServerURL` in `scripts.tmpl`).

## Efeitos colaterais na biblioteca e atualização {#library-side-effects--refresh}
- Quaisquer efeitos colaterais na biblioteca (mudanças de atribuição de diretório, sincronização STRM, reparos) invocam `MediaScanner.TriggerScan`, que inclui atualizações do Jellyfin quando o cliente está conectado (`internal/torrent/hooks.go:TriggerLibrarySideEffects` → `pkg/scan/scanner.go`).
- A mesma chamada primeiro esquece as entradas de dircache do VFS do rclone afetadas, para que a varredura do Jellyfin veja a mudança em vez de uma listagem em cache por horas.
- A sincronização STRM e os hooks `on_library_update` rodam junto com o gatilho da varredura (o hook tem debounce de 500ms e deduplicação); o Jellyfin recebe caminhos da biblioteca com o prefixo mount_path nos jobs de atualização.

## Diversos {#miscellaneous}
- Emby é uma integração irmã, com as próprias chaves de configuração (`emby_server_url`, `emby_token`) e o mesmo núcleo compartilhado, mas sem QuickConnect: você entra com uma chave de API ou escolhe um usuário e digita a senha (`/emby/users`, `/emby/auth`). O cartão do painel mostra as bibliotecas com botões de scan (`/emby/scan/{sectionID}`, `/emby/scan-all`), além de atividades e sessões, igual ao Jellyfin (`EmbyStatusFetcher`).
- `pkg/jellyfin/windows_path_test.go` verifica que um caminho do Windows fica fora da URL da requisição e chega ao corpo sem alterações; `find_section_test.go` cobre a correspondência de prefixo.
