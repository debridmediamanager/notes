# Bibliotecas de debrid locais e zurgtorrents portáteis {#local-debrid-libraries-and-portable-zurgtorrents}

A biblioteca local obtém seus membros a partir de arquivos portáteis `.zurgtorrent`. Ela aparece nos diretórios normais de WebDAV, HTTP e do provedor. Importar arquivos, listá-los e atualizar o catálogo não adiciona torrents nem resolve links de download. A reprodução resolve o arquivo solicitado pela sua conta configurada.

## Exportar uma biblioteca {#export-a-library}

No diretório de trabalho da instância de origem:

+++ Linux and macOS
```sh
./zurg --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++ Windows
```powershell
.\zurg.exe --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++

`--provider` é o **nome** da conta configurada, incluindo qualquer nome personalizado. Omita
para exportar todas as cópias suportadas de debrid. A entrada também pode ser um
único arquivo de cache de runtime, um diretório `dump/` legado ou um catálogo portátil
já existente. Para uma biblioteca local, exporte o diretório de origem dela (`torrents/<account>`),
que mantém as referências opcionais a outros provedores.

A exportação é offline. Ela valida todas as entradas e colisões de destino antes de
gravar, informa e pula entradas de runtime sem metadados de arquivo selecionados, mescla
os lançamentos pelo hash e grava `<hash>.zurgtorrent`. Exportações idênticas já existentes podem ser
repetidas sem problema. Para uma migração em massa com entradas de cache legado malformadas,
`--skip-invalid` exporta as entradas válidas e informa quantas foram omitidas. Sem ele, a primeira
entrada inválida aborta a operação antes de qualquer gravação. `--replace` permite substituir uma exportação
portátil com o mesmo hash; ele nunca autoriza sobrescrever um cache de runtime.

Só os arquivos exportados devem ser compartilhados. `data/*.zurgtorrent` continua sendo estado privado de runtime. Um `.zurgbackup` também contém credenciais de conta e é um backup da instância, não uma biblioteca para compartilhar.

## Receber uma biblioteca {#receive-a-library}

Coloque os arquivos exportados em `torrents/rd-local/` e depois configure a conta receptora:

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: YOUR_OWN_TOKEN
    download_tokens: # Optional bandwidth fallback on another RD account.
      - SECOND_RD_TOKEN
    library:
      source: local
      # Optional; defaults to torrents/<account-name>.
      path: torrents/rd-local

  - name: tb-online
    type: torbox
    token: YOUR_OWN_TORBOX_TOKEN
    # Omitted library block means the provider owns this account's catalog.
```

No Real-Debrid e no AllDebrid, `download_tokens` usa o mesmo catálogo local da sua entrada de provider. A segunda conta de RD acima não precisa de diretório, e a biblioteca de torrents dela não é importada.
Esses são tokens de reserva, usados quando a cota de banda do token de download ativo se esgota. Eles não forçam todos os downloads a passarem pela segunda conta.
Já adicionar uma segunda entrada de RD em `providers` cria um catálogo separado, com diretório próprio.
Todas as credenciais continuam no config e ficam de fora das exportações portáteis.

O TorBox também aceita `download_tokens`, mas a rotação de tokens dele não mapeia os IDs de torrent/arquivo guardados para os IDs da outra conta. Use entradas de provider separadas do TorBox para contas separadas, cada uma com seu próprio catálogo local.

Contas do Premiumize, Offcloud e Debrid-Link também podem ter uma biblioteca local. Nenhuma delas tem uma referência de arquivo portátil. Então, assim como no TorBox, cada uma adiciona o hash à própria conta na primeira reprodução e associa os arquivos por caminho e tamanho. Use uma entrada de provider por conta.

Reinicie depois de mudar a configuração das contas. Adições, substituições e remoções de arquivos são captadas pelo loop de atualização normal. Cada diretório é escaneado em um nível de profundidade. Os caminhos precisam ser diretórios distintos dentro de `torrents/`, para que os backups normais os incluam. Um diretório ilegível ou uma substituição inválida mantém a última entrada válida na memória e registra o problema no log. Depois de reiniciar, um arquivo inválido precisa ser corrigido antes de poder entrar no catálogo.

O mesmo manifesto pode ser copiado para o diretório local de uma conta do AllDebrid ou do TorBox. Ele contém a identidade do conteúdo, não o nome de uma conta de provider. O mesmo hash em várias contas aparece uma vez só, com várias fontes, usando a preferência de conta e a ordem de failover já existentes. Arquivos duplicados para um hash dentro de um mesmo diretório usam o primeiro nome de arquivo em ordem alfabética. Mantenha um manifesto por hash.

A participação no catálogo local sobrevive à remoção da biblioteca online do provider. Renomeações, tags, IDs do IMDb e exclusões de arquivos são salvos de volta nos manifestos. Remover um release local remove seus documentos de origem, mas não apaga os torrents do provider. Remover um release que tenha cópias online também apaga essas cópias online, como faz a exclusão normal de release inteiro.

Contas locais não são destinos para watchlists, envios de magnet ou envios de arquivo torrent. Adicione entradas importando manifestos. `add_torrents: false` ainda permite que o RD/AD resgate uma referência compartilhada existente, mas impede que a reprodução crie um anexo no lado do provider quando ele for necessário.

## Descarregar uma conta online para uma biblioteca local {#offload-an-online-account-into-a-local-library}

O AllDebrid aceita no máximo 1000 magnets por conta, e as contas do Real-Debrid também lotam. Um release concluído não precisa do torrent na conta para continuar tocando. Um link `/d/` do Real-Debrid continua funcionando depois que o torrent é apagado, e um link bloqueado `/f/` do AllDebrid continua funcionando depois que o magnet é apagado. O offloading depende disso. O zurg grava um release concluído em uma biblioteca local no mesmo serviço e depois apaga o torrent da conta online, liberando sua vaga. O release mantém sua pasta no mount e toca a partir dos links salvos.

Configure duas entradas para a mesma conta, uma online e uma local:

```yaml
providers:
  - name: ad
    type: alldebrid
    token: YOUR_AD_TOKEN
    library:
      offload_to: ad-local     # the local entry below
      offload_after_mins: 30   # optional, 30 is the default

  - name: ad-local
    type: alldebrid
    token: YOUR_AD_TOKEN       # the same token
    library:
      source: local            # manifests live in torrents/ad-local/
```

Novos releases continuam chegando em `ad`. Depois de cada listagem completa dessa conta, e a cada cinco minutos, o zurg move os releases que se qualificam, um de cada vez. Um release se qualifica quando:

- Ele está completo na conta há `offload_after_mins`, contado a partir do momento em que este processo do zurg o viu completo pela primeira vez. Um reinício recomeça a espera.
- Todo arquivo tem um link funcionando nessa conta que outra conta conseguiria resgatar. Um release com qualquer arquivo sem link fica online.
- Ele está saudável, não está sendo reparado e nenhuma instância dele ainda está baixando. Nenhum passe de reparo ou cliente de download segura o torrent dele.
- Nenhum job de qBittorrent do Sonarr ou Radarr ainda o lista. Ative Remove Completed Downloads no *arr para que um job seja removido depois da importação. Caso contrário, o release fica online até você remover o job.
- A aquisição não o adicionou na última hora.
- Mover não muda nenhum diretório em que ele está e mantém o nome da pasta. Um diretório com filtro `provider:` que cita a conta online o perderia, então esse release permanece online.

A ordem é fixa. O manifesto `<hash>.zurgtorrent` é gravado primeiro na biblioteca local, o release entra na biblioteca local em seguida, e só então o torrent é apagado da conta online. Se o manifesto não puder ser gravado, nada é apagado. Se a exclusão falhar, a cópia online fica ao lado da local, e a próxima atualização mostra se o torrent ainda está lá. Um manifesto que a biblioteca local já tem para o release é atualizado no lugar, em vez de ser gravado duas vezes. Os links da conta online nele são atualizados, e seus nomes e edições seguem o release como o mount o mostra. Os links do outro serviço são mantidos.

O release sai de `__ad__` e aparece em `__ad-local__`. Todos os outros diretórios, incluindo `__all__` e o seu próprio, continuam listando-o com o mesmo nome. Nenhuma varredura do servidor de mídia é iniciada, porque nada que um servidor de mídia indexa mudou. Aponte o Plex e outros servidores de mídia para esses diretórios, e não para um específico de conta.

Com as duas entradas em um mesmo token, a reprodução local pode anexar um release à mesma conta de novo (veja abaixo), e esse torrent então aparece na listagem online. O zurg nunca faz offloading de um release cujo torrent online seja esse tipo de anexo, nem enquanto a reprodução local está adicionando um, porque apagá-lo quebraria a reprodução que acabou de obtê-lo.

Só o Real-Debrid e o AllDebrid podem fazer offloading. TorBox, Premiumize, Offcloud e Debrid-Link não têm link que sobreviva ao torrent, então a reprodução local deles adiciona o torrent de volta, e um offloading não liberaria nada. O zurg recusa `offload_to` nessas contas.

O dashboard também pode mover um único release. Na página de um release, a tabela Accounts mostra Move to local library ao lado de cada cópia do Real-Debrid ou AllDebrid quando existe uma biblioteca local do mesmo tipo, mesmo sem `offload_to`. Quando o release ainda não pode ser movido, o botão fica desativado e diz o motivo. As configurações da conta na página de configuração oferecem a mesma opção e mostram quantos releases foram movidos desde que o zurg foi iniciado, e o último erro.

## O que vai no arquivo {#what-travels-in-the-file}

O formato JSON versionado tem `format: "zurgtorrent"` e `version: 1` numérico.
Ele traz o infohash, os nomes dos lançamentos, o timestamp de adição, o rename, as tags, o ID do IMDb,
e os caminhos, tamanhos e renames opcionais dos arquivos selecionados. As referências são opcionais:

| Provedor | Referência portátil | Reprodução |
|---|---|---|
| Real-Debrid | `https://real-debrid.com/d/...` canônico, com 13 caracteres | Resolva com as credenciais e o IP de download do destinatário. |
| AllDebrid | `https://alldebrid.com/f/...` bloqueado | Desbloqueie com as credenciais do destinatário. |
| TorBox | Hash e caminhos/tamanhos dos arquivos | Obtenha um torrent do lado do destinatário na primeira reprodução e combine os arquivos pelo caminho e pelo tamanho. |
| Premiumize, Offcloud, Debrid-Link | Hash e caminhos/tamanhos dos arquivos | Adicione o hash na conta do destinatário na primeira reprodução e combine os arquivos pelo caminho e pelo tamanho. |

Nomes de conta, credenciais, IDs de torrent/arquivo do provedor, URLs de CDN, URLs de entrada do MediaInfo, IDs do Plex, estado de reparo ou filas de exclusão não são exportados.
O importador rejeita campos desconhecidos e URLs de referência com credenciais ou inesperadas.
Ele não busca URLs durante a validação de um manifesto. O Usenet mantém o formato de origem `.nzb`; caches de runtime de NZB não podem ser exportados como torrents portáteis.

## Reprodução e limites {#playback-and-limits}

O rastreamento local muda quem é dono do catálogo. Isso não garante que o provedor ainda tenha os bytes ou consiga entregá-los. Acesso à conta, locais de rede permitidos, slots ativos, cotas e limites de taxa continuam valendo.

RD e AD usam referências bloqueadas compartilhadas quando elas existem. Manifestos só com hash, e uma referência do RD que a API informa definitivamente como ausente, podem estabelecer o conteúdo na conta do destinatário. O TorBox sempre precisa dessa vinculação à conta e primeiro reaproveita um torrent correspondente que já esteja na conta do destinatário. Os adds usam o ritmo de requisições já existente do provedor e são enfileirados por conta. Quando a conta informa a quantidade de slots, ou o zurg a conhece, um add para uma conta cheia é recusado, e a próxima requisição de reprodução, depois de um minuto, tenta de novo. AllDebrid, Premiumize e Offcloud não informam nenhum, então o add segue em frente e uma conta cheia o recusa. Um add incerto fica retido por 30 minutos antes de nova tentativa; um torrent em preparação só é verificado quando a reprodução é solicitada de novo.

Os IDs do destinatário e os identificadores nativos de arquivo resolvidos ficam guardados em privado em `data/local-torrents/`. Esse registro sobrevive a uma reinicialização e entra nos backups normais. O zurg nunca apaga essas vinculações automaticamente: um add idempotente pode ter retornado um torrent que o destinatário já possuía. O offloading também não mexe nelas. Falhas do provedor deixam a entrada local visível e recuam, em vez de iniciar um reparo em segundo plano ou repetir um add a cada varredura.

Lançamentos de arquivos compactados locais listam seus volumes de origem sem extração automática nem inspeção em segundo plano. Um caminho explícito dentro de um arquivo ainda pode acionar o leitor de arquivos. A sondagem automática do MediaInfo e o pré-carregamento do próximo arquivo são suprimidos em entradas que têm cópias locais.

## Migrar um dump antigo {#migrate-an-old-dump}

Exporte `dump/` com o comando acima, coloque os resultados no diretório `torrents/<name>/` da conta de destino e ative `library.source: local`.

Desative `load_dumped_torrents` depois da migração. O leitor antigo `__dump__`, de adesão opcional, continua disponível por compatibilidade; bibliotecas locais novas não o usam. Caches de runtime sem um tipo de conta precisam ser exportados novamente de uma instância que conheça o provedor deles antes de poderem ser compartilhados.

Backups gerados por esta build usam o formato 2 para incluir as novas raízes duradouras. O comando de restauração ainda lê backups no formato 1. Builds mais antigas recusam o formato 2 em vez de descartar silenciosamente uma biblioteca local.
