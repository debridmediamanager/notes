# O endpoint MCP {#the-mcp-endpoint}

zurg consegue responder a um agente de IA pelo [Model Context Protocol](https://modelcontextprotocol.io):
o cliente pergunta quais ferramentas existem, o zurg as descreve, e o agente as chama
para ler a biblioteca, descobrir por que um release não está tocando, consertá-lo ou controlar
os servidores de mídia. São as mesmas operações que o dashboard e a CLI
expõem, só que como ferramentas tipadas com schemas, em vez de HTML e redirects 303.

O endpoint vem desativado por padrão. Ele fica atrás da mesma basic auth do
dashboard, e o zurg se recusa a servi-lo de jeito nenhum quando não há username configurado.
Com ele vazio, todas as rotas do servidor ficam públicas, e essas ferramentas apagam releases.

## Configuração {#configuration}

```yaml
mcp:
  enabled: true
```

É isso aí para uma instalação normal. O resto tem padrões que vale a pena conhecer:

```yaml
mcp:
  enabled: true
  toolsets: [library, releases, repair]   # the default; see below
  read_only: false                        # withhold every tool that changes anything
  allow_unauthenticated: false            # serve /mcp with no username set
  allow_lifecycle: false                  # admit the tools that stop zurg or its mount
  page_limit: 50                          # items a listing returns by default; 500 is the cap
  max_result_kb: 256                      # ceiling on one result; a page over it is trimmed
  session_timeout_mins: 30                # -1 keeps sessions for the life of the process
```

Assim como os outros blocos de recursos, isso é lido uma única vez na inicialização: para alterar, é preciso reiniciar.

## Conectando {#connecting}

### Via HTTP {#over-http}

O endpoint é `/mcp` na porta de sempre do zurg, usando Streamable HTTP. Aponte um cliente para `http://<host>:9999/mcp` com as credenciais do dashboard.

```bash
npx @modelcontextprotocol/inspector
# Transport:  Streamable HTTP
# URL:        http://localhost:9999/mcp
# Header:     Authorization: Basic <base64 of user:password>
```

### Via stdio {#over-stdio}

Clientes que só falam stdio usam o subcomando `zurg mcp`, que faz a ponte com uma instância do zurg já em execução:

```json
{
  "mcpServers": {
    "zurg": {
      "command": "/path/to/zurg",
      "args": ["mcp"],
      "cwd": "/path/to/your/zurg/directory"
    }
  }
}
```

O `cwd` importa: todos os caminhos do zurg são resolvidos a partir do diretório de trabalho, e é ali que o `zurg mcp` lê o `config.yml` para pegar a porta e as credenciais. Com isso, ele não precisa de argumentos. `--username` e `--password` substituem as credenciais locais. Um `--url` personalizado nunca herda credenciais da configuração local. Quando esse endpoint precisar delas, passe as duas flags de credencial explicitamente, para que uma senha local não seja enviada a outro host por acidente.

Ele não inicia uma segunda instância. Uma segunda instância do zurg carregaria a biblioteca inteira, ocuparia um segundo conjunto de slots do provedor em contas que cobram por eles e disputaria o mount com a primeira. Por isso, o comando é apenas um pipe para o daemon e não serve nada quando o daemon não está no ar. Os diagnósticos dele vão para o stderr, porque o stdout carrega o protocolo.

Uma limitação: uma notificação que o servidor dispara fora de qualquer chamada não atravessa a ponte. Progresso e linhas de log disparados *durante* uma chamada viajam na própria resposta dessa chamada e chegam normalmente, o que cobre tudo que o zurg envia.

## Conjuntos de ferramentas {#toolsets}

O conjunto completo do zurg tem algumas centenas de ferramentas, e isso é mais do que um cliente consegue usar bem. Acima de uns oitenta, o modelo escolhe a ferramenta errada com mais frequência, e só os schemas já custam dezenas de milhares de tokens. Por isso, `toolsets` seleciona grupos, e o padrão é um subconjunto que funciona, não tudo.

| Toolset | No padrão | O que cobre |
|---|:-:|---|
| `library` | sim | Busca, listagens de diretório, contagem de tags |
| `releases` | sim | Um release em detalhe: arquivos, cópias por conta, o que pode servir cada arquivo |
| `repair` | sim | O que está quebrado, se o reparo vai alcançar, forçar um reparo |
| `releases_write` | | Apagar, renomear, marcar tags, forçar exibição, escrever arquivos `.strm` |
| `magic` | | O namespace `__magic__`: o layout armazenado, suas linhas e mover coisas de lugar |
| `plex` | | Plex, Jellyfin e Emby: status, correspondência e escaneamento com proteções |
| `providers` | | As contas configuradas: o que cada uma faz, se está acessível, quanto já gastou |
| `usenet` | | O backend NZB: contas de news, sondagens de artigos, danos e o cache de artigos |
| `clients` | | Os endpoints SABnzbd, qBittorrent e Stremio com os quais Sonarr e Radarr se comunicam |
| `diagnostics` | | O log, os contadores de bytes, memória e goroutines |
| `config` | | Ler a configuração, encontrar divergências e escrever um conjunto selecionado de chaves |
| `mount` | | O mount do rclone: status, esquecer listagens em cache, reiniciá-lo |
| `system` | | Informações do build, `doctor`, o serviço, backups e atualização |

`toolsets: [all]` ativa todos os grupos. Um nome com prefixo `-` remove um grupo, então `[all, -config, -system]` é a superfície inteira sem os dois grupos que mudam a máquina e não só a biblioteca. Um nome não reconhecido gera um aviso na inicialização e é ignorado: um erro de digitação não pode tirar o endpoint do ar.

As ferramentas que param o zurg, controlam o serviço dele ou reciclam o mount não formam um grupo próprio. Elas ficam em `system` e `mount`, e permanecem ocultas até que `allow_lifecycle` seja definido, não importa o que `toolsets` diga.

Um pequeno grupo `server`, que informa qual é este build e se a biblioteca já terminou de carregar, é sempre registrado, não importa o que `toolsets` diga. Ocultá-lo deixaria um cliente sem como descobrir que todas as outras respostas estão, neste momento, parciais.

## O que ele não fará sem ser solicitado {#what-it-will-not-do-without-being-asked}

**Confirmação.** Uma ferramenta que tira algo do seu sistema descreve o que faria
e devolve um token; ela só age quando é chamada de novo com esse token. O token
é gerado a partir do plano, então uma confirmação não pode ser usada em outro
plano — se a biblioteca mudou no meio do caminho, a segunda chamada volta a
descrever em vez de executar. Os tokens são de uso único, valem por dois minutos
e não sobrevivem a um reinício.

**`read_only`.** Uma chave única que oculta todas as ferramentas que alteram
alguma coisa, independentemente do que `toolsets` disser. A pergunta que um
operador realmente faz é "isso pode quebrar minha biblioteca?", e não "qual
dessas ferramentas escreve?". Elas são omitidas de `tools/list`, então um
cliente não consegue selecionar uma capacidade que este endpoint nunca vai
permitir. A verificação no momento da chamada continua valendo como defesa
extra caso a configuração ativa mude depois que o servidor foi criado.

**`allow_lifecycle`.** As ferramentas que param o zurg, controlam o serviço dele
ou reiniciam o mount ficam ocultas da mesma forma, atrás de uma chave separada.
Cada uma pode fazer a biblioteca inteira sumir de uma vez, e as ações de
processo/serviço não conseguem informar o próprio resultado, porque podem
encerrar o processo que está respondendo à chamada.

**Segredos.** Nenhum resultado de ferramenta traz um token de provedor, uma
chave de API, uma senha de servidor de notícias, um link de CDN já resolvido
ou uma URL assinada de `.strm`. A saída de log é censurada antes de ser
exibida. Um link resolvido pode ser usado por quem o tiver, na conta que o
gerou, e uma transcrição não é lugar para guardar um desses links.

**Tamanho.** Cada listagem tem dois limites: um limite de itens por página e um
teto para o resultado serializado. Uma conta medida com isso tinha 84.000
releases, o que dá cerca de doze megabytes só de nomes antes de listar qualquer
arquivo. Um resultado acima do teto é cortado, e a resposta avisa que foi
cortado.

## Notas {#notes}

The endpoint inherits the dashboard's basic auth by being registered inside it.
A cross-origin request is refused: `/mcp` is for a local agent, not a web page.
A reverse proxy in front of zurg works — the protocol library's DNS-rebinding
check would otherwise reject a proxy that forwards its own `Host` while dialling
`127.0.0.1`, so zurg turns that check off and leaves the gate to basic auth.

`zurg mcp --help` lists the bridge's flags. `zurg doctor` checks whether the
endpoint is answering at all.
