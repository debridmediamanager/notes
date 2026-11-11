# Caches de leitura persistentes {#persistent-read-caches}

Entradas importadas de NZBs, Real-Debrid, AllDebrid e TorBox mantêm todo o estado da biblioteca em `data/*.zurgtorrent`. Esses arquivos descrevem a biblioteca. Os caches de preparação de leitura e de bytes ficam ao lado deles, então mudar ou apagar um cache derivado não reescreve a biblioteca nem faz você perder tags, nomes e associações de conta.

## O que sobrevive a um reinício {#what-survives-a-restart}

| Cache | Location | Work avoided |
| --- | --- | --- |
| NZB document manifests | `data/nzb-manifests/` | Análise de XML inalterado para obter nomes, tamanhos, classificação de recuperação, senhas e contagem de segmentos |
| NZB article indexes | `data/nzb-index/` | Reconstrução das referências de artigos; usado tanto pelo modo `mmap` quanto pelo `resident` |
| Decoded Usenet articles | `data/bytecache/articles/` | Buscar e decodificar yEnc de um artigo que já foi lido |
| Archive layouts | `data/archive-layouts/` | Ler os cabeçalhos do arquivo de novo para reconstruir os intervalos de volumes, entradas aninhadas e offsets ZIP aprendidos |
| Decompressed archive blocks | `data/bytecache/decoded/` | Decodificar de novo para chegar aos intervalos de bytes retidos depois de um reinício ou de um seek para trás |
| Provider state | `data/provider-cache/` | Reconstruir a janela de downloads do RD inalterada ou buscar de novo a tabela de regiões do TorBox |
| Delivery links | `data/linkcache/` | Resolver de novo uma URL que ainda é válida |

Archive layouts suportam entradas RAR/ZIP armazenadas e comprimidas, fontes aninhadas,
intervalos criptografados e arquivos divididos suportados. Eles guardam referências de fonte e
offsets, não leitores HTTP ativos. As URLs atuais do provedor são anexadas na restauração.
Layouts incompletos com volumes faltando são reconstruídos a partir da fonte. Os offsets
de payload ZIP aprendidos são persistidos após a primeira leitura, sem buscar eagerly um
cabeçalho para cada entrada durante a listagem de um diretório.

Os manifests NZB são verificados contra o tamanho do arquivo de origem, o tempo de modificação
em nanossegundos e a versão do parser. `mmap` restaura os metadados imediatamente e mapeia o
índice de artigos quando necessário. `resident` carrega esse índice na memória heap. `reparse`
restaura os metadados imediatamente, mas ainda analisa o XML quando as referências de artigos são
necessárias. Bibliotecas existentes criam os manifests durante a primeira varredura com esta
versão; o salvamento na inicialização passa a valer nas varreduras seguintes e nos reinícios.

As requisições simultâneas do AllDebrid e do TorBox para o mesmo arquivo não cacheado de uma conta agora
compartilham uma única resolução. Cancelar uma chamada não cancela a resolução de outra chamada.
O RD mantém a coalescência que já tinha. O TorBox usa os nomes e tamanhos já conhecidos
do catálogo ao resolver um arquivo, em vez de buscar esses detalhes de novo.

Os registros de detalhes de provedores em `data/info/` são memoizados após a primeira decodificação
JSON por processo. Cada reutilização verifica identidade do arquivo, tamanho e tempo de modificação
e retorna uma cópia independente. Os arquivos de biblioteca e de detalhes são substituídos de forma atômica.

## Orçamentos de armazenamento {#storage-budgets}

Estas configurações opcionais de nível superior são medidas em MiB e passam a valer depois de um reinício:

```yaml
nzb_article_disk_cache_mb: 512
archive_decoded_disk_cache_mb: 512
```

Cada cache tem 512 MiB por padrão em toda a instância. Zero desativa esse cache, e valores negativos são tratados como zero. Os limites contam os bytes dos registros, incluindo os checksums, e não o espaço extra de alocação do sistema de arquivos. Os registros mais antigos que não são usados há mais tempo são removidos conforme novos registros chegam. Se você reduzir um limite, o cache existente é reduzido durante a inicialização. Se você desativar o cache, os arquivos que já existem continuam disponíveis para remoção manual.

O cache de artigos complementa o cache de RAM que já existe. O cache de arquivos guarda blocos decodificados de 64 KiB e complementa a janela de RAM rolante de 64 MiB de cada decodificador. Nenhum dos dois pré-baixa a biblioteca. Uma leitura fora dos blocos decodificados guardados ainda precisa decodificar desde o início de uma entrada compactada. O cache VFS do Rclone é separado e continua servindo intervalos completos em cache sem passar por esses caminhos. Esses caches também ajudam as leituras HTTP/WebDAV diretas.

Uma entrada compactada só pode ser decodificada a partir do início, então uma leitura bem no meio dela significa buscar o arquivo inteiro antes. O zurg segura essa leitura por 20 segundos e depois responde com `503`, para não deixar o cliente sem resposta. O que a decodificação já alcançou fica guardado, então um player que tenta de novo um avanço (seek) chega um pouco mais longe a cada vez. Uma leitura recusada perto do fim de uma entrada também inicia uma única decodificação em segundo plano dessa entrada, uma entrada por vez, que mantém os últimos 8 MiB da entrada em `data/bytecache/decoded-tails/`. Depois disso, o fim do arquivo é lido na hora, que é o que um servidor de mídia pede quando analisa um arquivo. Esse armazenamento usa de novo o mesmo limite de `archive_decoded_disk_cache_mb` e é desativado junto com ele.

Os metadados derivados crescem junto com a biblioteca e não entram nesses limites de bytes. As varreduras de NZB removem os manifestos e os índices de artigos dos documentos removidos. Revisões antigas do layout de arquivos podem ser removidas com a instância parada. Elas são descartáveis e serão recriadas quando precisarem.

## Validação e recuperação {#validation-and-recovery}

Novos registros de metadados e blobs de bytes têm checksums. Registros danificados e gravações de cache que falharam voltam para a fonte. Registros de artigos só entram no cache em disco depois de um fetch completo e bem-sucedido, e são gravados depois que o artigo já foi entregue à leitura que o buscou, então uma leitura nunca espera pelo cache. Uma rajada com mais gravações de artigos do que podem rodar ao mesmo tempo descarta os registros extras em vez de segurar uma leitura; um registro descartado é buscado de novo quando for necessário outra vez. A identidade do artigo inclui a revisão do NZB, a configuração do servidor, o arquivo e o segmento; a identidade do archive inclui as referências de origem atuais, os tamanhos, a configuração da conta, a senha e a versão do formato. A substituição da fonte NZB também invalida os layouts de archive e os bytes decodificados.

A impressão digital da fonte local presume que uma substituição muda o tamanho ou a data de modificação. Ela evita, de propósito, calcular o hash de todo o XML a cada inicialização. Para manter os dois valores iguais em uma substituição, é preciso remover os caches derivados associados.

Os snapshots do RD só são aceitos para o mesmo token e o mesmo limite de download configurado, dentro de uma hora, depois que uma sondagem ao vivo confirma a entrada mais recente e a contagem total. Uma lista alterada dispara uma reconciliação completa. As tabelas de região do TorBox mantêm o tempo de vida atual de seis horas. A duração das URLs de entrega e o tratamento de falhas do provedor não mudaram: um layout em cache (warm) abre o payload antes de confirmar o sucesso HTTP, permitindo que uma URL revogada siga o caminho normal de resolução/nova tentativa.

Alterações nos links de entrega disparam uma gravação unificada em disco após cerca de um segundo. A nova tentativa a cada cinco minutos e a gravação no desligamento continuam valendo. A substituição atômica impede que os leitores vejam registros escritos pela metade; ela não é uma garantia de fsync contra queda de energia. Os novos arquivos de cache usam o modo `0600` no Unix, porque links e layouts de archive criptografados podem carregar credenciais ou chaves derivadas. No Windows, são usadas as ACLs do diretório que contém os arquivos, em vez dos bits de permissão do Unix.

## Backups com caches aquecidos {#backups-with-warm-caches}

O backup padrão ainda guarda o estado autoritativo. Para incluir também os caches derivados e o cache VFS do rclone local da instância:

```sh
./zurg backup --include-caches --out warm.zurgbackup
```

Esse backup pode ficar bem maior que um backup padrão. Ele inclui as raízes listadas acima, os caches de nomeação, dimensionamento e PAR2 dos NZBs e o estado dos testes de rede. Logs e snapshots do banco de dados do Plex continuam de fora. Caches do rclone fora de `data/rclone-cache/` não são incluídos. Pare a instância quando for importante ter um snapshot consistente dos caches ativos.

Para restaurar, pare a instância e use `./zurg restore-backup warm.zurgbackup`.
Os backups preservam os timestamps de origem em nanossegundos, para que NZBs inalterados possam manter seus índices e manifests. Os caches restaurados ainda passam pelas verificações normais de validação e expiração. Os backups contêm os tokens e as credenciais em cache da configuração.

## Verificações reproduzíveis {#reproducible-checks}

`BenchmarkParsedDocumentStartup` compara a análise de XML com cada modo de restauração do manifesto, usando 60 arquivos e 30.000 segmentos. `BenchmarkDetailJSONRefresh` compara o caminho de leitura JSON com o acesso memoizado para um registro de 1.000 arquivos. Os dois são benchmarks locais de sistema de arquivos já aquecido, não medições de inicialização de produção de ponta a ponta.

Medido em um Apple M3 Pro com três execuções de 500 ms em 2026-09-05 (mediana por operação):

| Operação | Tempo | Bytes alocados |
| --- | ---: | ---: |
| Analisar o XML do NZB | 43,49 ms | 20,27 MB |
| Restaurar metadados no modo `mmap` | 0,224 ms | 59 KB |
| Restaurar metadados e o índice de artigos residente | 0,577 ms | 1,79 MB |
| Restaurar metadados no modo `reparse` | 0,199 ms | 59 KB |
| Ler/decodificar um registro de detalhes do provedor | 0,538 ms | 784 KB |
| Reutilizar o registro de detalhes com verificação de stat e cópia | 0,0084 ms | 59 KB |

O caso de decodificação de detalhes limpa a nova memória antes de cada chamada e inclui o custo de preenchê-la. Esses números comparam os dois caminhos de acesso atuais; eles não estimam a latência de rede nem projetam o tempo de inicialização de uma biblioteca inteira.

Os testes de regressão cobrem reutilização após reinício, corrupção, mudanças na origem, isolamento de contas, resolução concorrente, identidade de bytes no início/meio/fim, buscas para trás além da janela de RAM e revogação de URL após a restauração do layout.

```sh
go test ./...
go test -race ./internal/debrid ./internal/nzb ./internal/rarstream ./internal/universal ./pkg/cachefile ./pkg/diskcache
go test ./internal/nzb ./internal/torrent -run '^$' -bench 'Benchmark(ParsedDocumentStartup|DetailJSONRefresh)$' -benchmem
make integration-test
```

O alvo de integração exige suas contas de teste ao vivo documentadas e as dependências do host. Um script de integração pulado não verifica uma mudança no cache.
