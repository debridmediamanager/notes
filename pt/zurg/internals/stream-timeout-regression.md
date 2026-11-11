# Regressão de timeout em stream via proxy {#proxied-stream-timeout-regression}

## Resumo {#summary}

O zurg usava `download_timeout_secs` como um prazo de tempo total (wall-clock) para downloads HTTP via proxy. O padrão é 15 segundos, então qualquer resposta upstream cujo corpo levasse mais de 15 segundos para terminar era cortada, mesmo com os bytes chegando normalmente.

O defeito foi reportado no Discord em 2026-08-21 contra `2026.08.21.0151-nightly` (`fc2a21f`). Requisições repetidas de 2 GB com range através do zurg terminaram em 15.001 segundos, depois de entregar cerca de 1.26 GB a 84 MB/s. O mesmo range foi concluído diretamente do Real-Debrid, e aumentar `download_timeout_secs` para 3600 fez a requisição terminar pelo zurg em 25.8 segundos.

Isso foi uma regressão do zurg, não filtragem de conteúdo, falha de CDN nem regressão em `fc2a21f`. O commit `6edeaa8c` (`Optimize client`, 2024-11-17) a introduziu. O caminho de entrega via proxy simples foi corrigido por `41db7245`, e depois `eff972b8` tornou difícil reintroduzir o mesmo erro na fronteira da API do provedor.

## Impacto para o usuário {#user-impact}

O caminho afetado era qualquer corpo de resposta que o zurg repassava de um provedor de debrid com HTTP e que ficava aberto por mais tempo que `download_timeout_secs`. O Real-Debrid foi afetado a partir de novembro de 2024. TorBox e AllDebrid herdaram o mesmo comportamento quando foram adicionados. Leituras de NZB servidas localmente nunca passavam pelo cliente de download HTTP e não foram afetadas.

Os sintomas visíveis para o usuário incluíam:

- o Infuse ou outro cliente WebDAV direto travando durante a reprodução;
- a reprodução falhando depois que um seek abriu uma nova requisição com range;
- um download terminando cedo mesmo recebendo HTTP `206 Partial Content`; e
- erros do cliente que pareciam culpar o arquivo de mídia ou a CDN, mesmo quando uma requisição direta era concluída normalmente.

O player nem sempre falhava 15 segundos depois que a reprodução começava. Na velocidade relatada de 84 MB/s, o zurg transferia cerca de 1,26 GB antes do prazo. Um player podia consumir esse buffer por vários minutos antes de secar, o que transformava um corte de rede exato de 15 segundos em um travamento de reprodução que parecia variar.

## Causa raiz {#root-cause}

O `http.Client.Timeout` do Go é um prazo para o ciclo de vida inteiro da requisição. Ele não é um timeout de inatividade ou de travamento. O relógio começa quando a requisição começa e continua rodando enquanto o corpo da resposta é lido, independentemente de haver dados fluindo.

Antes do `6edeaa8c`, o próprio cliente de download não tinha timeout para a requisição inteira:

```go
client: &http.Client{}
```

O `download_timeout_secs` limitava as fases de conexão e de cabeçalhos da resposta, através do dialer do transporte e do `ResponseHeaderTimeout`. Quando o corpo da resposta chegava, o caminho de entrega podia continuar lendo pelo tempo que o cliente downstream precisasse.

O `6edeaa8c` reorganizou o transporte HTTP, adicionou o timeout configurado no próprio cliente e removeu o `ResponseHeaderTimeout`:

```go
client.client = &http.Client{
    Transport: transport,
    Timeout:   time.Duration(timeoutSecs) * time.Second,
}
```

Isso mudou o significado do valor de 15 segundos que já existia. Ele ainda protegia a fase de conexão, mas agora também impunha um prazo absoluto para o corpo da resposta. O caminho de entrega já buscava mídia por meio desse cliente, então a regressão passou a valer assim que essa mudança entrou.

A falha passou em silêncio. O zurg enviava o status e os cabeçalhos de sucesso do upstream antes de copiar o corpo para o player. Quando o prazo do cliente interrompia o corpo, a operação de cópia retornava um erro, mas o caminho de entrega descartava esse erro:

```go
n, _ = copyBuffered(resp, body)
```

Nessa altura, a resposta `206` já tinha sido enviada e não podia mais ser trocada por um status de erro. Com o log de requisições desativado, nada informava por que o corpo tinha ficado incompleto. Por isso, o cliente downstream via uma resposta de conteúdo parcial aparentemente bem-sucedida, cujo corpo terminava antes do tamanho anunciado.

## Histórico da regressão {#regression-history}

| Data | Commit | Efeito |
|---|---|---|
| 2024-06-28 | `c3aea427` | Direcionou a leitura de serving existente por `DownloadFile`. Isso preservou o comportamento, porque o cliente de download ainda não tinha um timeout para a requisição inteira. |
| 2024-11-17 | `6edeaa8c` | Adicionou `http.Client.Timeout` ao cliente de download. Esta é a regressão que começou a cortar o corpo de respostas proxied comuns. |
| 2026-02-26 | `dea98d34` | Diagnosticou corretamente o mesmo corte de 15 segundos nas leituras de arquivos RAR, adicionou um cliente de streaming sem timeout e moveu apenas o caminho RAR para ele. O serving de arquivos comuns continuou em `DownloadFile`. |
| 2026-08-02 | `e9318e66` | Moveu os downloads para a interface multi-provedor `debrid.Provider` e manteve a chamada de serving comum sem alterações. Não criou o bug do Real-Debrid, mas novos provedores baseados em HTTP herdaram o método inseguro. |
| 2026-08-21 | `fc2a21f` | O nightly usado no relato. Ele continha o bug, mas não o introduziu. |
| 2026-08-21 | `41db7245` | Mudou a reprodução proxied comum para usar `DownloadFileStreaming` e adicionou o primeiro teste de regressão de timeout de ponta a ponta. |
| 2026-08-21 | `eff972b8` | Tornou o `DownloadFile` de todo provedor HTTP sem timeout, como uma proteção estrutural, e ampliou a cobertura para Real-Debrid, AllDebrid, TorBox e um controle de NZB. |

A correção do RAR de fevereiro foi o quase-acerto importante. A mensagem do commit diz explicitamente que `http.Client.Timeout` cobre o corpo da resposta e que o timeout padrão de 15 segundos estava matando os streams RAR. O diagnóstico estava correto, mas a correção ficou restrita ao leitor RAR. Manter os métodos separados `DownloadFile` e `DownloadFileStreaming` permitiu que o caminho de serving comum mantivesse a escolha insegura por mais seis meses.

## Por que ficou escondido {#why-it-stayed-hidden}

Vários fatores esconderam a regressão por cerca de 21 meses:

1. A maioria das instalações de media server lê o zurg através do rclone, e não por WebDAV direto. O rclone usa requisições de range limitadas. Os padrões atuais do managed mount começam em 4 MB e crescem até um limite de 512 MB, então, em uma conexão rápida, muitas requisições individuais ao upstream terminam em menos de 15 segundos. Isso reduzia a exposição, mas não tornava o caminho seguro, principalmente em conexões mais lentas.
2. Clientes WebDAV diretos, como o Infuse, podem pedir ranges grandes ou sem fim. Essas requisições mantêm uma única resposta do upstream aberta tempo suficiente para bater no prazo de forma confiável, e é por isso que a reprodução no Discord foi exata nos três offsets diferentes.
3. O buffer de reprodução separou causa de sintoma. A requisição ao upstream morreu aos 15 segundos, mas a reprodução só parou depois que o player consumiu os bytes que já tinham sido entregues. O atraso visível variava com o bitrate, o buffer e os seeks.
4. A resposta parecia bem-sucedida. O CDN retornou um `206` válido, o zurg encaminhou, e o erro na cópia do corpo foi ignorado depois que os headers já tinham sido enviados. Os testes diretos no CDN continuaram saudáveis e os logs normais não tinham nenhum erro de timeout.
5. Aumentar a configuração pareceu resolver o problema. Isso fez o defeito parecer um valor de ajuste pequeno demais, e não um timeout ligado à abstração errada.
6. Os testes existentes usavam corpos ou ranges que terminavam dentro do timeout configurado. Nenhum teste manteve de propósito um corpo de resposta fluindo além do prazo e depois verificou o tamanho completo e o checksum pelo caminho de serving.
7. A correção pontual do RAR removeu a manifestação mais óbvia de antes, mas não removeu o padrão inseguro dos downloads comuns.

## Por que um timeout maior parecia resolver {#why-a-higher-timeout-appeared-to-fix-it}

Mudar a configuração para 3600 segundos não mudou o que o timeout cobria. Ela só empurrou o prazo final da requisição para longe o suficiente para que a transferência de 25.8 segundos relatada terminasse:

```text
15 seconds   < 25.8-second transfer < 3600 seconds
```

Foi um contorno, não uma correção segura. Qualquer timeout finito para a requisição inteira ainda pode cortar um corpo suficientemente longo, inclusive com um cliente lento ou uma conexão pausada. A configuração também alimenta o timeout de conexão do cliente de download e as requisições de verificação limitadas, então aumentá-la para uma hora pode fazer um host inacessível demorar muito mais para falhar. Builds corrigidas devem usar o valor normal configurado; ele não limita mais o corpo de mídia em proxy.

## Correção e proteções {#fix-and-guardrails}

A correção imediata em `41db7245` mudou `streamFileToResponse` para buscar o arquivo por meio de `Provider.DownloadFileStreaming`. Esse cliente usa o mesmo transporte, mas não tem `http.Client.Timeout`, então o tempo de vida do corpo da resposta não está mais ligado a `download_timeout_secs`. A requisição ainda usa o contexto da requisição downstream, então, se o player desconectar, a leitura upstream é cancelada. O estabelecimento da conexão e o handshake TLS continuam limitados pelo transporte.

Depois, `eff972b8` removeu a dependência de cada chamador escolher o método pelo nome com "Streaming":

- O `DownloadFile` do Real-Debrid agora usa `DoStreaming`.
- O helper compartilhado `debrid.DownloadRanged` aceita `StreamingDoer`, que expõe apenas `DoStreaming`. AllDebrid e TorBox usam esse helper.
- Os dois métodos de download dos provedores são, portanto, seguros para corpos de resposta longos.
- Leituras limitadas que não são de reprodução, como as duas leituras de 64 KiB usadas para o hash do OpenSubtitles, recebem o próprio deadline explícito no contexto, em vez de depender de um timeout de corpo global e inseguro no cliente.

Os testes de regressão em `internal/universal/stream_timeout_test.go` usam um servidor local que envia um corpo de 1,6 MB em 16 pedaços ao longo de cerca de 1,6 segundo, com o timeout configurado em um segundo. Eles verificam o tamanho total e o checksum:

- diretamente pelos dois métodos de download dos provedores, para Real-Debrid, AllDebrid e TorBox;
- de ponta a ponta pelo `streamFileToResponse`, para os três provedores baseados em HTTP; e
- por um provedor local no formato NZB, como controle, já que ele não é afetado.

A regra agora está explícita: um método que retorna um corpo de download nunca pode usar um timeout de requisição inteira. Sondagens curtas e leituras de metadados devem ter um deadline no próprio contexto. Corpos de streaming devem durar até a conclusão, até o cancelamento downstream ou até um erro real de transporte.

## Limitado pelo progresso, não pelo tempo {#bounded-by-progress-not-by-time}

Deixar cada leitura correr até o fim abriu uma brecha para que uma leitura nunca terminasse: um nó de entrega que mantém a resposta aberta e para de enviar dados, ou que nunca responde. Em setembro de 2026, um scan do Plex ficou onze horas preso em um único arquivo do Real-Debrid cuja leitura nunca falhou. Esse cliente não tinha limite para desistir dela, e o `--timeout` do rclone é um limite de inatividade: o zurg repassa o corpo em escritas de 256 KiB, então um nó que entrega 256 KiB a cada cinco minutos, abaixo de 1 KB/s, reseta esse limite para sempre. Um nó mais lento de fato dispara o limite, mas o rclone então envia a mesma requisição ao mesmo nó, registrando um erro a cada três timeouts. Medido no zen com rclone 1.75 e com as próprias flags do mount em 2026-10-03, um leitor em um nó assim ainda estava bloqueado depois de 30 minutos.

`internal/universal/starved_read.go` agora interrompe uma leitura via proxy assim que o nó tiver entregado menos de 1 MiB em 30 segundos em que o zurg ficou esperando por ele. Só a espera pelo nó conta: do momento em que a requisição tem uma conexão até os headers chegarem, e o tempo dentro de cada leitura do corpo. O tempo gasto escrevendo para o cliente não conta, então a propriedade acima continua valendo, e um cliente pausado ou lento pode manter um stream aberto pelo tempo que quiser. Um arquivo cortado recebe `503` por dois minutos, para que as tentativas do rclone terminem logo em vez de cada uma esperar mais uma janela. Leituras de arquivos NZB servidos localmente não são monitoradas.

Leituras de arquivos dentro de um arquivo compactado nunca passaram por `streamFileToResponse`, então ficaram fora desse limite até o card 204. Os bytes delas vêm de trechos de cada volume, buscados pelo mesmo cliente via `providerDoer.Do` e lidos pelo parser de RAR. Um nó poderia segurar uma dessas buscas enquanto mantivesse a conexão. Agora cada busca de volume é monitorada pelo mesmo piso, a entrada é recusada por dois minutos quando uma busca é cortada, e um corte enquanto o arquivo compactado está sendo listado faz a listagem falhar, em vez de deixar o parser excluir o volume como danificado. Em um conjunto real de cinco volumes, isso servia a entrada com o tamanho total, mas com os bytes errados depois do segundo volume.

O card 222 encontrou o mesmo problema por trás de todas as outras formas como um nó pode falhar uma leitura de volume: um 5xx, um 429, uma conexão derrubada no meio dos headers. O parser tratava cada uma como um volume danificado e listava o arquivo sem ele, e essa listagem ficava em cache. No mesmo conjunto, um 503 no volume 3 servia bytes errados a partir do offset 16,057 e continuava servindo mesmo depois de o nó se recuperar. Agora o parser diferencia um volume cujos bytes não puderam ser parseados de um volume cujos bytes nunca chegaram (`rarstream.ErrVolumeUnavailable`, marcado pelo `HTTPSrc` para os status que ele vê, pelo `providerDoer` para tudo em que uma leitura remota falha, e pelo corpo do NZB para o que o leitor classifica como transporte). O segundo caso faz a listagem falhar, incluindo conjuntos aninhados e agrupamento por cabeçalho de volume, e a falha é respondida com `503` e um `Retry-After`, nunca guardada em cache como falha do arquivo, nunca registrada como veredito, e nunca respondida em uma navegação com os volumes brutos no lugar do conteúdo do arquivo. Volumes danificados ou ausentes continuam sendo listados ao redor, como antes.

As escritas de 256 KiB citadas acima também entraram no card 204. A cópia ainda preenche seu buffer enquanto um nó é rápido, então um corpo rápido sai em buffers inteiros como antes, mas envia os primeiros bytes assim que chegam e nunca segura um byte por mais de 250 ms (`defaultCopyFlushAfter` em `internal/universal/downloader.go`), descarregando a resposta junto com eles. Um nó lento não impede mais o cliente de receber os headers. Antes dessa mudança, no zen, via rclone e com as próprias flags do mount, uma entrada de arquivo compactado em um nó que enviava 64 KiB e depois 16 KiB a cada quatro minutos não tinha enviado nada ao rclone quando ele desistiu exatamente aos cinco minutos, três vezes seguidas: tudo o que o nó tinha enviado ainda estava no buffer.
