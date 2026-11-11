# Linha de comando {#command-line}

The binary zurg é o servidor e um conjunto de ferramentas. Rode sem nenhum comando para iniciar o servidor. Todo comando aceita `--help` e imprime o texto em que esta página foi escrita.

Rode os comandos a partir do diretório de trabalho da instância. O zurg lê `./config.yml` nesse diretório, a menos que você passe `--config`. As pastas de dados e de logs também são resolvidas a partir desse diretório.

```
zurg [flags]
zurg [command]
```

## Flags que todo comando aceita {#flags-every-command-takes}

| Flag | O que faz |
|---|---|
| `-c`, `--config` | O arquivo de configuração a ser lido. O padrão é `./config.yml`. |
| `-v`, `--version` | Mostra a build e encerra. A saída é igual à de `zurg version`. |
| `-h`, `--help` | Mostra a ajuda do zurg ou de um comando específico. |

## Configuração {#setting-up}

### zurg setup

Escreve a configuração, baixa o rclone e o ffprobe e, em seguida, registra o zurg para iniciar sozinho. Se faltar alguma coisa, ele pergunta. `--dry-run` mostra o plano e não altera nada.

As chaves e senhas são lidas de arquivos. Assim elas ficam fora do histórico do seu shell.

| Flag | O que faz |
|---|---|
| `--provider` | Um provedor para configurar. Repita a flag para mais de um. Um dos valores: realdebrid, torbox, alldebrid, nzb, premiumize, debridlink, offcloud, torbox_nzb. O torbox_nzb lê a chave de `--torbox-token-file` ou `TORBOX_TOKEN`, assim como o torbox. |
| `--realdebrid-token-file` | Lê o token do Real-Debrid deste arquivo. A mesma flag existe para `torbox`, `alldebrid`, `premiumize`, `debridlink` e `offcloud`. |
| `--nntp-host` | O servidor de notícias para o provedor `nzb`. |
| `--nntp-port` | A porta dele. O padrão é 563 com TLS e 119 sem TLS. |
| `--nntp-tls` | Usa TLS. Vem ativado por padrão. |
| `--nntp-username` | O nome de usuário da conta de notícias. |
| `--nntp-password-file` | Lê a senha da conta de notícias deste arquivo. |
| `--nntp-connections` | O limite de conexões da conta de notícias. O padrão é 8. |
| `--mount-path` | Onde o mount aparece. O padrão é a convenção da sua plataforma. |
| `--port` | A porta HTTP. Se você não informar, mantém o valor que está no config. |
| `--service-name` | O nome do serviço ou da tarefa agendada. O padrão é `zurg`. |
| `--service-scope` | `auto`, `user` ou `system`. O padrão é `auto`. |
| `--service-user` | O usuário com o qual um serviço do sistema roda. |
| `--no-service` | Configura tudo, mas não registra a inicialização automática. |
| `--no-start` | Registra o serviço, mas não o inicia. |
| `--skip-downloads` | Não baixa o rclone nem o ffprobe. |
| `--skip-prerequisites` | Pula a verificação do FUSE para esta plataforma. |
| `--non-interactive` | Falha em vez de pedir informações que estejam faltando. |
| `--dry-run` | Mostra o plano e não altera nada. |

Cada plataforma tem o seu próprio passo a passo.

- [Linux](../setup/linux.md)
- [macOS](../setup/macos.md)
- [Windows](../setup/windows.md)
- [Docker](../setup/docker.md)

### zurg doctor

Verifica o que a instalação configurou. Ele lê a configuração e procura rclone e ffprobe. Depois, checa o serviço, o endpoint HTTP e o mount. Rode primeiro quando algo não estiver funcionando.

| Flag | O que faz |
|---|---|
| `--working-dir` | O diretório de trabalho da instância. O padrão é o diretório atual. |
| `--service-name` | O nome do serviço a verificar. O padrão é `zurg`. |
| `--service-scope` | `auto`, `user` ou `system`. O padrão é `auto`. |

### zurg service

Instala e controla o início automático sem executar o resto da configuração.

| Comando | O que faz |
|---|---|
| `zurg service install` | Instala o início automático e o inicia. Use `--start=false` para instalar sem iniciar. |
| `zurg service uninstall` | Remove o início automático. A configuração e os dados continuam lá. |
| `zurg service start` | Inicia o serviço instalado. |
| `zurg service stop` | Para o serviço. |
| `zurg service restart` | Reinicia o serviço. |
| `zurg service status` | Mostra o status do início automático. |

Todos eles aceitam as mesmas flags.

| Flag | O que faz |
|---|---|
| `--name` | O nome do serviço ou da tarefa agendada. O padrão é `zurg`. |
| `--scope` | `auto`, `user` ou `system`. O padrão é `auto`. |
| `--user` | O usuário que o serviço do sistema roda. |
| `--working-dir` | O diretório de trabalho em que o serviço inicia. |
| `--executable` | O binário do zurg que o serviço executa. |

### zurg download-requirements

Baixa o rclone e o ffprobe para uma pasta e grava os caminhos deles na configuração. O setup faz isso por você, a menos que você passe `--skip-downloads`.

| Flag | O que faz |
|---|---|
| `--dir` | Onde os binários são salvos. O padrão é `bin`. |
| `--rclone-version` | Uma versão do rclone, como `1.67.0`. O padrão é `latest`. |
| `--ffprobe-version` | Uma versão do ffprobe. O padrão é `latest`. |

### zurg update

Substitui o binário pelo nightly mais recente para patrocinadores. A conta do GitHub que ele usa precisa de acesso de patrocinador no [gatekeeper](https://gatekeeper.debridmediamanager.com/). Dentro de um container ele se recusa, porque o próximo recreate jogaria o binário novo fora. Nesse caso, baixe uma nova imagem. `--force` atualiza mesmo assim.

Ele faz login no GitHub pelo GitHub CLI. É aquele que está no seu PATH ou o que os instaladores guardam em `bin`, ao lado do zurg. Um login que o GitHub CLI salvou sem keyring funciona mesmo quando o próprio CLI não está mais instalado. `GITHUB_TOKEN` também funciona. Quando não encontra nada, ele mostra o comando do instalador que restaura o GitHub CLI.

### zurg version

Mostra a build. `zurg --version` mostra a mesma coisa.

## Backups

### zurg backup

Grava um arquivo `.zurgbackup` com o que mais ninguém consegue recriar. Isso inclui o config com os seus tokens e cada `data/*.zurgtorrent` com suas tags e vínculos de conta. Também inclui o store `__magic__` em `data/local/` e os NZBs de origem em `nzbs/`. Caches, snapshots do Plex e logs ficam de fora, para que o backup tenha o tamanho do que ele protege.

A instância não precisa estar rodando. Isso torna seguro agendar o comando. O arquivo é um tar com gzip e tem os seus tokens dentro. Guarde-o como se fosse uma senha.

| Flag | O que faz |
|---|---|
| `-o`, `--out` | Onde gravar. O padrão é `zurg-<timestamp>.zurgbackup` no diretório atual. |
| `--include-caches` | Também inclui metadados derivados e bytes em cache para uma restauração com cache aquecido. Snapshots do Plex e logs continuam de fora. Isso pode ficar grande. |

### zurg restore-backup

Descompacta um `.zurgbackup` no diretório atual. Cada arquivo volta para o caminho de onde veio. Pare o zurg antes. A restauração grava arquivos que uma instância em execução também está gravando.

```
zurg restore-backup my-backup.zurgbackup
```

Se já existir uma config no diretório, ela não é alterada. Esse arquivo guarda os tokens de que toda a biblioteca depende. Use `--force-config` para sobrescrevê-la.

## Medições {#measuring}

### zurg benchmark-my-setup

Ele lê bytes reais do jeito que um player faria e informa a variação, em vez de um único número. Ele roda em três fases. Primeiro, cada conta sozinha. Esse é o número para comparar com o que o serviço promete. Depois, todas as contas ao mesmo tempo. Contas que fazem 70 MiB/s sozinhas e 25 MiB/s juntas dividem um uplink saturado. Por último, lê pelo mount do rclone. A diferença para a primeira fase é o custo do FUSE e do VFS.

As amostras caem em offsets aleatórios. Todas as camadas abaixo cacheiam, e reler um mesmo offset mediria o cache e não o link.

Ele não adiciona nem apaga nada. Mas usa a sua banda. Cada conta lê o tamanho da amostra vezes o número de iterações, duas vezes. A fase do mount vem por cima disso.

| Flag | O que faz |
|---|---|
| `-n`, `--iterations` | Amostras por conta por fase. O padrão é 3. |
| `--sample-mb` | MiB lidos por amostra. O padrão é 128. Use 1024 para passar da rampa de read-chunk do rclone e obter um número de mount sustentado. |
| `--provider` | Testa apenas estas contas pelo nome. Pode ser repetido. |
| `--skip-concurrent` | Pula a fase de todas as contas. |
| `--skip-mount` | Pula a fase do mount. |
| `--json` | Imprime o relatório em JSON. |

### zurg network-test

Mede a rapidez com que este host alcança cada servidor de download do Real-Debrid tanto por IPv4 quanto por IPv6. Os resultados vão para `logs/network-test.log` e para `data/`, onde o servidor os lê para escolher os hosts. Defina `PROXY` no ambiente para testar por meio de um proxy.

| Flag | What it does |
|---|---|
| `-t`, `--test-url` | Uma URL de arquivo cujo caminho é baixado de cada servidor, em vez do arquivo de teste de velocidade do próprio Real-Debrid. |

## Plex

Estes três funcionam com o servidor Plex deste host. Configure o Plex primeiro. Veja [Integração com Plex](config.md#plex-integration).

### zurg plex-settings

Mostra as configurações do Plex que importam para um mount e corrige o que a política permite. Os padrões do Plex partem do princípio de que os discos são locais. Uma delas apaga a biblioteca quando uma varredura encontra uma falha passageira. Outras fazem o Plex decodificar todos os arquivos que ele tem. [plex.md](../guides/plex.md#recommended-plex-settings) explica cada uma.

| Flag | O que faz |
|---|---|
| `-p`, `--policy` | `off`, `warn`, `guard` ou `enforce` para esta execução. O padrão é `plex_settings_policy` da configuração. Passar uma política mais rigorosa mostra a prévia antes de você adotá-la. |

### zurg plex-drift

Lê o banco de dados do Plex sem escrever nele e verifica cada arquivo que ele aponta dentro do mount. Ele informa quais já não existem mais. Execute antes de um scan da biblioteca. Um scan que encontre esses arquivos os transforma em exclusões. Saber a quantidade antes faz do scan uma decisão e não um tiro no escuro.

Ele precisa de `plex_database_path` e do Plex no mesmo host.

### zurg plex-backups

Lista os snapshots do banco de dados do Plex que o zurg guarda, do mais novo para o mais antigo. Cada linha mostra quando ele foi feito, o tamanho e quantos itens cada biblioteca tinha naquele momento. As contagens vêm dos próprios snapshots, então a lista mostra o que cada um realmente consegue restaurar. [Plex Library Maintenance](config.md#plex-library-maintenance-same-host-only) explica quando o zurg faz esses snapshots.

## Compartilhamento {#sharing}

### zurg export-torrents

Grava arquivos `.zurgtorrent` portáteis que descrevem suas versões sem a sua conta dentro. Nenhuma credencial entra no arquivo. Também não há ids de torrent, estado de reparo nem links de CDN. Nenhum provedor é contatado.

Ele lê `data/*.zurgtorrent` ou um arquivo de dump antigo. Passe um arquivo ou uma pasta para exportar apenas esses. Quem recebe coloca os arquivos em `torrents/<their-account>/` e define essa conta como `library.source: local`. [portable-libraries.md](../guides/local-libraries.md) cobre o lado de quem recebe.

| Flag | O que faz |
|---|---|
| `--provider` | Exporta as versões mantidas por esta conta configurada. |
| `--output` | Onde os arquivos portáteis são gravados. |
| `--replace` | Substitui uma exportação existente do mesmo hash. |
| `--skip-invalid` | Pula e conta as entradas que não consegue ler durante uma exportação em massa. |

### zurg nzb-share

Cria uma cópia compartilhável das suas NZBs que você pode publicar. O resultado é uma pasta com um `manifest.json` e um `.nzb.gz` por release, nomeado pelo hash do conteúdo. Cada NZB é limpa primeiro. Comentários, DOCTYPEs e metadados de marca d'água são removidos. Os nomes de arquivo originais também saem. Os posters e as datas também são removidos, e cada arquivo recebe o mesmo newsgroup fixo, porque alguns indexadores mudam os três a cada download. Os carimbos de conta que um indexador esconde em um subject, um título ou uma senha são cortados. O que você publica nomeia o release e nunca a conta que fez o download. As senhas reais de arquivo são mantidas, porque os destinatários precisam delas para ler o release.

Publique a pasta em qualquer lugar estático. Um repositório git funciona. Um site do Pages também, ou `rclone serve`. A auditoria do que foi removido fica na sua máquina e é impressa aqui. Ela contém justamente os identificadores que a limpeza existe para remover.

| Flag | O que faz |
|---|---|
| `--from` | A pasta de monitoramento a compartilhar. Percorrida recursivamente. O padrão é `nzbs`. |
| `--out` | A pasta de saída. O padrão é `nzb-share-<timestamp>`. |
| `--title` | Um título registrado no manifest. |
| `--filter` | Compartilha apenas os caminhos de origem que correspondem a esta expressão regular. |

O dashboard também pode servir um compartilhamento. Veja [Compartilhamento público de NZB](config.md#public-nzb-sharing).

### zurg nzb-sync

Puxa uma biblioteca compartilhada para a sua pasta de monitoramento. Ele segue o `manifest.json` de um compartilhamento a partir de uma URL ou de um caminho local. Cada NZB é verificado contra o hash no manifesto antes de ser gravado. Suas próprias contas de notícias baixam os arquivos.

```
zurg nzb-sync https://example.com/share/manifest.json
```

Ele só adiciona. Entradas que você já tem são ignoradas, e um compartilhamento nunca apaga nada. Dois compartilhamentos com os mesmos lançamentos são deduplicados pelo hash do conteúdo.

| Flag | O que faz |
|---|---|
| `--into` | A pasta de monitoramento onde gravar. O padrão é `nzbs`. |
| `--dry-run` | Informa o que gravaria, mas não grava nada. |

## Limpando uma conta do Real-Debrid {#clearing-a-real-debrid-account}

Estes dois apagam tudo de um tipo específico de uma conta do Real-Debrid. Não dá para desfazer. Eles funcionam só com o Real-Debrid.

Os dois pedem o cookie `auth` de uma sessão do navegador logada no Real-Debrid, e não o seu token de API. Eles mostram uma linha de JavaScript que exibe esse cookie. Rode isso no console do navegador em real-debrid.com e cole o resultado.

| Comando | O que faz |
|---|---|
| `zurg clear-torrents` | Apaga todos os torrents da conta. |
| `zurg clear-downloads` | Apaga todos os downloads da conta. São os links desbloqueados. |

## Autocompletar no shell {#shell-completion}

`zurg completion bash` imprime um script de autocompletar para o bash. O mesmo funciona para `zsh`, `fish` e `powershell`. `zurg completion <shell> --help` mostra onde colocá-lo.
