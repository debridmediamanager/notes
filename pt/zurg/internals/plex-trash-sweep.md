# Alinhando a varredura de lixo do Plex com o status de arquivo do próprio zurg {#aligning-the-plex-trash-sweep-with-zurgs-own-file-status}

## Objetivo deste documento {#purpose-of-this-document}

O sweep de lixo do Plex atualmente decide o que remover de uma biblioteca do Plex usando
**ausência do arquivo mais um temporizador de idade**. O zurg já sabe algo muito melhor —
se o conteúdo por trás desse arquivo é reparável ou permanentemente morto — e não consulta essa informação.

Este documento é o plano para substituir o temporizador por esse conhecimento. Ele existe
para ser revisado **antes** de qualquer código ser escrito, porque a mudança decide o que
é apagado de uma biblioteca de mídia, e o comportamento atual está errado nos dois sentidos: ele espera duas semanas
para remover conteúdo que já está morto no primeiro dia, e apaga conteúdo que o zurg ainda está reparando ativamente.

Ele registra o que foi verificado no código e em uma biblioteca em uso, o que está sendo proposto e o que foi deliberadamente deixado de fora. Tudo o que é afirmado como fato abaixo foi conferido no sistema em execução em 2026-08-16, não inferido a partir dos nomes.

Escopo: `internal/plexsweep`, `internal/plexdb`, e uma nova consulta somente leitura em `internal/torrent`. Nenhuma mudança no comportamento de reparo em si.

---

## 1. Contexto — o que foi lançado e por que precisa ser revisado {#1-background--what-shipped-and-why-it-needs-revisiting}

Quatro commits entraram no sweep:

| Commit | O que faz |
|---|---|
| `4737b677` | Avisa quando o `autoEmptyTrash` do Plex está ativado |
| `020042a3` | O sweeper: detecção, guardas, reparo, remoção por item |
| `51cc9f69` | UI de configuração no dashboard e documentação |
| `1a481a8f` | Conta os reparos no limite, e não só as remoções |
| `c6f41621` | `plex_trash_sweep_min_age_days`, padrão 14 |

A invariante que governa o sweep continua a mesma e se mantém: **nada que ainda tenha um
arquivo é removido.** Itens com um arquivo ativo são reparados, ou ficam como estão com o
ícone da lixeira. Séries e temporadas com episódios ativos nunca são tocadas. A remoção é
por item, nunca o `emptyTrash` de toda a seção do Plex.

O que está sendo revisto é só a regra de *quando uma entrada realmente ausente pode ser
removida*.

### O timer é um substituto para uma pergunta que o zurg consegue responder diretamente {#the-timer-is-a-proxy-for-a-question-zurg-can-answer-directly}

`plex_trash_sweep_min_age_days` espera 14 dias antes de remover uma entrada, com a ideia de que o ícone vermelho da lixeira é o único aviso que o operador recebe de que o conteúdo sumiu, e que apagar a entrada destrói esse aviso.

A intenção está certa; o mecanismo é um palpite. Ele erra nos dois sentidos:

- Um torrent marcado como `infringing torrent` está **morto desde o início**. Deixar a entrada do Plex parada por duas semanas não ajuda ninguém, porque esperar não vai trazê-lo de volta.
- Um torrent que ainda está sendo tentado de novo pode levar **mais de 14 dias** para voltar. O timer apaga a entrada enquanto o zurg ainda está trabalhando nele. Esse é o erro pior, porque destrói uma entrada da biblioteca de um conteúdo que depois volta.

## 2. Fatos verificados {#2-verified-facts}

### 2.1 O modelo de estados do zurg {#21-zurgs-state-model}

Existem três estados de arquivo e dois estados de torrent (contados em `internal/torrent`, sem os testes):

| Nível | Estados |
|---|---|
| `File.State` | `ok_file`, `broken_file`, `deleted_file` |
| `Torrent.State` | `ok_torrent`, `broken_torrent` |

Os dois são máquinas `pkg/fsm`. `FSMWithTime` registra o timestamp unix de cada transição e oferece suporte a `SinceWhen`, então "há quanto tempo isso está quebrado" já pode ser respondido sem adicionar nada.

**Um único arquivo quebrado condena o torrent inteiro.**
`MarkFileBrokenAndEnqueueRepair` (`internal/torrent/hooks.go:215-234`):

```go
changed := file.State.Set("broken_file", torrent.State.GetMutex()) == nil
...
if err := torrent.State.Set("broken_torrent"); err == nil {
    t.repairLog.Infof("Torrent state changed: %s [? -> broken_torrent] (has broken file)", ...)
}
```

O log diz *"has broken file"*, no singular. Um de dez quebrados e dez de dez quebrados geram exatamente o mesmo estado de torrent. Nada agrega os estados dos arquivos.

**`Unfixable` agrega por conta, não por arquivo.**
`markAsUnrepairable` (`internal/torrent/unplayable_unrepairable.go:44-71`):

```go
if cp != nil {
    cp.SetUnrepairableReasonIfEmpty(reason)      // one account's copy
    entryCondemned = t.repairableCopy(torrent) == nil
}
if entryCondemned {
    torrent.SetUnrepairableReasonIfEmpty(reason) // the entry
}
```

A entrada é condenada quando **não sobra nenhuma cópia capaz de reparo**. De propósito, não é "toda cópia tem um motivo". Uma cópia que nunca poderia ser reparada de qualquer forma (o backend Usenet não tem adicionador de magnet) manteria um release morto elegível para reparo para sempre. `File` não tem nenhum campo de irreparável (`internal/torrent/file_types.go`).

Então os três níveis respondem a três perguntas diferentes, e **nenhum deles responde sobre o escopo**:

| Nível | Diz | Não consegue dizer |
|---|---|---|
| `File.State` | se este arquivo está ok / quebrado / excluído | se ele está permanentemente morto |
| `TorrentCopy.UnrepairableReason` | que a cópia desta conta está morta | nada sobre as outras contas |
| `Torrent.UnrepairableReason` | que nenhuma conta consegue reparar isto | quanto do release é afetado |

(Uma tradução anterior foi rejeitada: as linhas da tabela estavam diferentes. Mantenha a estrutura exatamente.)

### 2.2 Medições ao vivo (uma biblioteca de produção, 2026-08-16) {#22-live-measurements-a-production-library-2026-08-16}

As porcentagens abaixo são dos torrents quebrados, que somavam cerca de **3% da biblioteca**.

**Quase todos os quebrados (98%) trazem um motivo `Unfixable`**:

| Motivo | Parcela dos quebrados |
|---|---|
| stalled download | 38% |
| infringing torrent | 37% |
| repair failed | 15% |
| duplicate file IDs (pack torrent) | 4% |
| rar'ed by RD | 1% |
| repair failed, no seeders | 1% |
| the lone cached file is broken | menos de 1% |
| invalid file ids | menos de 1% |
| repair failed, download status: error | menos de 1% |
| provider cannot re-add torrents | menos de 1% |

**Os demais (2%) estão quebrados sem motivo** — ainda assim reparáveis.

**Mas `Unfixable` não é o mesmo que morto.** O zurg já separa esses motivos em
permanentes e recuperáveis (`internal/torrent/unrepairable_reasons.go:44-70`).
A lista `permanentReasons` tem oito veredictos que nenhuma nova tentativa muda — infringing,
unsupported, unavailable, invalid, too big, not allowed, no repairable files,
invalid file ids — mais qualquer motivo que comece com `repair failed, download status:`.
Todo o resto, inclusive os dois maiores grupos acima, é explicitamente
temporário: `stalled download`, `repair failed`, `duplicate file IDs`,
`rar'ed by RD`, `not cached`, `the lone cached file is broken`,
`full torrent repair failed`.

`repair failed, no seeders` era o nono motivo quando as porcentagens acima foram tiradas, e os registros que o trazem aqui são o motivo de ele não ser mais: nenhum backend com que o zurg conversa informa seeders, então esse veredito nunca foi medido de fato — foi deduzido de um reparo que ficou sem tempo. Agora ele é temporário e, além disso, não pode ser registrado (`verdictClaims`), então esses registros se aposentam e são tentados de novo como qualquer outro.

Aplicando essa divisão às porcentagens acima:

| | Parcela dos quebrados |
|---|---|
| Irreparável de forma permanente | **39%** |
| Irreparável, mas recuperável | **59%** |
| Quebrado, sem motivo ainda | 2% |

Um motivo não reconhecido (`provider cannot re-add torrents`, um registro aqui) não está em nenhuma das listas, e `IsPermanentlyUnrepairable` retorna false para ele — a resposta conservadora, que é a que queremos.

Esta é a descoberta mais importante para o design: **uma regra baseada em "`Unfixable` está definido" removeria entradas do Plex de duas vezes e meia mais lançamentos do que os que estão de fato mortos.**

O mais importante é onde esses torrents quebrados estão em relação ao mount:

| | Parcela dos quebrados | O que o Plex vê |
|---|---|---|
| Quebrado, **ainda no mount** | cerca de três em cada quatro | O arquivo parece existir → nunca vira tombstone. Sem ícone de lixeira; falha só na reprodução |
| Quebrado, **fora do mount** | cerca de um em cada quatro | Arquivo ausente → vira tombstone → **estes são os candidatos da varredura** |

Esta é a medição principal. Isso significa que a varredura só encontra o segundo grupo, e para esse grupo o zurg normalmente já tem um veredito.

Do lado do Plex, mesmo host: um acúmulo de episódios na lixeira, **nenhum** deles além da janela de 14 dias (tombstone mais antigo em 2026-08-11). Além disso, algumas cascas de séries vazias e algumas dúzias de cascas de temporadas vazias.

---

## 3. A lacuna {#3-the-gap}

`broken_torrent` significa "pelo menos uma coisa está errada". Essa granularidade é errada para a varredura.

Na prática: um pacote de dez episódios em que o arquivo de um episódio sumiu de vez, mas o torrent continua reparável no geral. Perguntando ao torrent, a resposta é "ainda reparável", então a varredura manteria a entrada desse episódio morto no Plex **para sempre**.

Não existe um estado que signifique *"este lançamento inteiro está morto"* diferente de *"algo neste lançamento está quebrado"*.

---

## 4. Design

### 4.1 Não adicionar um quarto estado persistido {#41-do-not-add-a-fourth-persisted-state}

O caminho óbvio seria criar um novo estado para o torrent, como `dead_torrent` ou algo parecido. **Descartado.**

Todo site que muda o estado de um torrent teria que manter essa informação em dia, e uma flag desatualizada dizendo "todos os arquivos quebrados" é pior do que não ter flag nenhuma, porque ela *autoriza remoções*. A informação já existe nos estados dos arquivos. Ela só não está agregada.

Então, derive o valor:

```go
// AllFilesBroken reports whether nothing in this release still reads.
// Derived from the file states rather than stored, so it cannot go stale
// and needs no migration or new transitions.
func (t *Torrent) AllFilesBroken() bool
```

Fica barato, sempre consistente e dá pra mostrar no dashboard sem persistir nada.

Definição a fechar durante a implementação: `deleted_file` tem que contar como não-leitura, junto com `broken_file`. E um torrent com **zero** arquivos tem que retornar false, e não true por vacuidade. Uma release vazia não é evidência de que o torrent morreu.

### 4.2 Perguntar ao arquivo, recorrer ao torrent {#42-ask-the-file-fall-back-to-the-torrent}

A varredura resolve um caminho do Plex para um arquivo do zurg e depois aplica:

| Veredito do zurg | Varredura |
|---|---|
| arquivo é `ok_file` | **manter**: ele não sumiu de verdade |
| `broken_file`, torrent sem motivo irreparável | **manter**: o reparo pode restaurá-lo, por mais tempo que demore |
| `broken_file`, motivo definido mas **não** permanente | **manter**: o zurg ainda considera recuperável |
| `broken_file`, motivo é **permanentemente** irreparável | **remover**: nenhuma nova tentativa pode mudar esse veredito |
| zurg não tem torrent para este caminho | **usar a janela de idade** |

O teste de permanência é `IsPermanentlyUnrepairable(reason)`
(`internal/torrent/unrepairable_reasons.go:59`), usado exatamente como o `ForceRepairTorrent` o usa. Reaproveitar essa função em vez de criar uma lista nova importa: um motivo adicionado depois em `permanentReasons` deve mudar o comportamento da varredura automaticamente, e um motivo não reconhecido deve continuar não permanente.

`AllFilesBroken()` **não** autoriza a remoção sozinho: uma release totalmente quebrada com motivo recuperável ainda está sendo trabalhada. Ele serve para refinar os relatórios e o painel, e para distinguir "um episódio de dez se foi" de "o pacote inteiro se foi" para quem lê o log.

A última linha explica por que `plex_trash_sweep_min_age_days` continua existindo. Quando um torrent sai totalmente da conta, o `.zurgtorrent` dele vai junto, e o zurg não tem mais nada a dizer. O timer deixa de ser a regra principal e passa a ser o fallback exatamente para o caso em que não existe nada melhor.

Isso também rebaixa a configuração na interface, o que resolve a outra reclamação de que o rótulo dela ("Keep Broken Entries Visible") descreve um efeito colateral e não a ação.

### 4.3 Caminho → torrent → busca do arquivo {#43-path--torrent--file-lookup}

O matcher existente de Plex vai no sentido contrário: `buildPlexDirIndex`
(`internal/plex/matcher.go:539`) indexa os componentes de caminho do Plex e os procura pela chave do torrent. A varredura precisa do inverso, construído com a mesma ideia:

1. Montar `map[strings.ToLower(GetKey(torrent))] *Torrent` a partir de
   `DirectoryMap.Get(INT_ALL)`.
2. Para um caminho do Plex, separar em componentes com a mesma normalização de
   `splitPathComponents` (`matcher.go:525`) e procurar cada um. O diretório do release é o componente que acerta.
3. Dentro desse torrent, comparar o restante do caminho com `File.Path`
   (`internal/debrid/types.go:133`) para chegar ao arquivo específico.

Esse caminho tem que passar pelo `TorrentManager` e não por comparação de string com `data/*.zurgtorrent`. Os motivos são: nomes desambiguados (`Some.Release {a1b2c3}`), cópias de múltiplas contas e renomeações, que só são resolvidos corretamente através do `GetKey`.

**Uma busca que falha não é licença para apagar.** Se não der para resolver, trate como "o zurg não tem opinião" e use o fallback da janela de idade.

### 4.4 O que não muda {#44-what-does-not-change}

- O invariante: nada com um arquivo ativo é removido.
- Séries e temporadas com descendentes ativos nunca são tocadas.
- Por item, `DELETE`, nunca `emptyTrash`.
- Guardas: rclone gerenciado e em execução, leitura do mount, Plex não escaneando.
- Snapshot antes de qualquer mudança; limites valem para reparos *e* remoções.

As novas regras só tornam a varredura **mais** conservadora ou **mais** precisa —
elas nunca autorizam uma remoção que o código atual recusaria.

---

## 5. Plano de implementação {#5-implementation-plan}

| # | Passo | Arquivos |
|---|---|---|
| 0 | Confirme que a divisão entre permanente e recuperável é o critério certo, com uma contagem de simulação (dry-run) numa biblioteca real antes de qualquer exclusão | — |
| 1 | `AllFilesBroken()` + testes unitários (release vazia, mista, toda quebrada, toda apagada) | `internal/torrent/` |
| 2 | Consulta somente leitura de status: caminho → torrent → arquivo, retornando um valor de veredito pequeno | novo arquivo em `internal/torrent/` ou `internal/plexsweep/` |
| 3 | Defina o tipo de veredito (`StatusOK`, `StatusRecoverable`, `StatusPermanentlyDead`, `StatusUnknown`) para que o sweep nunca lide diretamente com os internos do zurg | `internal/plexsweep` |
| 4 | Conecte a consulta ao `Sweeper` por trás de uma interface, do mesmo jeito que `Mount`/`Library`/`Trash` já são | `internal/plexsweep/sweep.go` |
| 5 | Aplique a tabela de decisão; mantenha a janela de idade como fallback de `StatusUnknown` | `internal/plexsweep/sweep.go` |
| 6 | Injete o `TorrentManager` no ponto de chamada | `internal/app.go` |
| 7 | Testes: um para cada linha da tabela de decisão, mais um teste de falha na consulta provando que um caso não resolvível nunca remove nada | `internal/plexsweep/sweep_test.go` |
| 8 | Documentação: `docs/config.md`, `config.example.yml`, `docs/CHANGELOG.md`, e reescreva o rótulo do painel | docs + templates |

Observação sobre a ordem: os passos 1–3 são apenas adições, sem mudança de comportamento, e podem entrar
em um único commit; o passo 5 é o único que muda o que é apagado.

## 6. Riscos e perguntas em aberto {#6-risks-and-open-questions}

1. **Ordem de montagem.** Confirmado: `startPlexTrashSweep` é chamado em
   `internal/app.go:268`, e `TorrentManager` é construído em `internal/app.go:285` — depois dele. A chamada precisa ser movida para depois, ou usar um setter. É preciso verificar se mais alguma coisa depende da posição atual.
2. **Ambiguidade na busca.** Dois torrents cujas chaves colidem no mesmo componente de caminho. Resolução: se mais de um candidato corresponder, tratar como `StatusUnknown` em vez de escolher um.
3. **`only_show_the_biggest_file`.** O diretório de filmes oculta arquivos, então um caminho do Plex pode apontar para um arquivo que não é o que o zurg serviria. A busca não pode presumir que o nome de arquivo do Plex aparece em `File.Path` exatamente como está.
4. **Custo.** Construir o índice de chaves a cada varredura é O(biblioteca). Com alguns milhares de torrents isso é trivial, e a varredura roda diariamente. Construa o índice por varredura, não por item.
5. ~~**O `Unfixable` algum dia é limpo?**~~ **Resolvido: sim.** `refresh.go:851-857` limpa quando um torrent é verificado e volta para `ok_torrent` ("all links intact, no broken files"), e `repair.go:165-181` limpa — a entrada e todas as cópias — quando um reparo é forçado. Ou seja, uma release recuperada não carrega uma condenação antiga, e o design não precisa se defender disso.
6. **Os torrents quebrados mas presentes.** Fora do escopo aqui: o Plex nunca os marca como removidos, então a varredura nunca os vê. Vale notar que eles ficam invisíveis tanto para o Plex quanto para este recurso até que a reprodução falhe.

## 7. Como foi implementado (2026-08-16) {#7-how-it-was-implemented-2026-08-16}

Entrou como `feat: decide plex trash sweep removals from zurg's repair verdicts`.
Quando a implementação resolveu uma questão que este documento deixou em aberto, ou se afastou do §4, aqui estão a decisão e o motivo:

- **A busca compara exatamente o diretório pai do caminho** com `DirectoryMap[INT_ALL]`, em vez de varrer cada componente do caminho (§4.3). A montagem organiza cada release de forma plana: `<library dir>/<key>/<visible name>`. E o Plex gravou o caminho a partir da montagem, que serve a chave exatamente como ela é. Uma busca que não encontra nada responde desconhecido, e a ambiguidade de colisão de chaves (risco 2) desaparece: chaves exatas não podem colidir.
- **A linha 1 da tabela de decisão mudou.** Um `ok_file` que, mesmo assim, não aparece na montagem é um arquivo escondido pelos filtros, não "não foi mesmo removido". Mantê-lo para sempre deixaria um ícone de lixeira permanente depois de uma mudança nos filtros. Nesse caso, o sistema volta para a janela de idade.
- **`deleted_file` conta junto com `broken_file`** em todas as regras, não só em `AllFilesBroken()`. As linhas da tabela dizem "não `ok_file`".
- **Itens com várias versões são avaliados como um todo** (a tabela era por arquivo, mas a unidade da varredura é um item do Plex com partes). Uma parte recuperável mantém o item inteiro. O item só é considerado morto quando todas as partes estão mortas. Qualquer outra combinação cai na janela de idade.
- **Um nome de arquivo que leva a um torrent, mas não a um arquivo** (renomeação, listagem de arquivo compactado, `only_show_the_biggest_file`, risco 3) só é morto se o motivo da entrada for permanente **e** `AllFilesBroken()` for verdadeiro. É recuperável quando o torrent está quebrado sem um veredito permanente. Nos outros casos, o status é desconhecido. Um nome sem correspondência nunca é condenado por associação enquanto algum arquivo ainda puder ser lido.
- **Ligação (risco 1):** `startPlexTrashSweep` foi movido para baixo da construção do manager em `internal/app.go`. Nada dependia da posição antiga. Os veredictos chegam à varredura através de `plexsweep.Verdicts`, implementado por `TorrentManager.FileStatusForMountPath`. Antes da primeira atualização preencher `INT_ALL`, toda busca responde desconhecido, e a varredura se comporta exatamente como a versão baseada apenas na janela de idade.

## 8. Explicitamente fora do escopo {#8-explicitly-out-of-scope}

- **Cascatas vazias de séries e temporadas.** A varredura remove apenas os episódios, então uma série totalmente morta deixa uma casca vazia (algumas séries e algumas dezenas de temporadas na biblioteca medida). Isso é outro problema, separado, e precisa de cuidado na ordem: remover os episódios, verificar de novo o item pai e remover apenas quando não restarem filhos.
- Qualquer mudança no comportamento de reparo, na fila de reparo ou no momento em que o zurg marca algo como irreparável.
- O `autoEmptyTrash` do próprio Plex, que já é tratado pelo aviso em `4737b677`.
- O acúmulo existente da biblioteca medida, deixado de propósito para uma decisão manual.
