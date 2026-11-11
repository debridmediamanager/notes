# Migrando para o zurg {#migrating-to-zurg}

Leia esta página primeiro. Ela se aplica a todas as migrações e é a maior parte do que você precisa. As páginas de cada servidor são curtas porque esta carrega a parte comum.

## A versão curta {#the-short-version}

**zurg publica todos os arquivos de mídia que o servidor que você está deixando publica, e mais.** Isso foi medido em 01/09/2026. Os mesmos cinco lançamentos foram colocados nos cinco servidores e os mounts foram lidos de volta com `tree`. Aqui está [a comparação completa](https://github.com/debridmediamanager/usenet-streaming-benchmark).
A única coisa que o zurg publica *a menos* é a paridade par2. O Plex nunca transforma isso em um item da biblioteca.

Então **você não vai perder conteúdo.** Parte dele aparece com um nome de arquivo diferente. Esse é todo o problema que esta página trata. O Plex vincula um item da biblioteca a um caminho de arquivo. Um arquivo em um caminho novo é um item novo.

O que você troca não são os arquivos. É a **curadoria**.

| Sobrevive | Morre com o item antigo |
|---|---|
| Marcações de assistido, contagem de reproduções, pontos de retomada | Participação em coleções |
| Avaliações de usuário | Entradas de playlist (elas guardam IDs de item) |
| Os próprios arquivos | Pôsteres, artes e correções manuais de correspondência escolhidas |
| | `added_at`. Sua biblioteca vai inundar Adicionados Recentemente |

O estado de assistido sobrevive porque `metadata_item_settings` é indexado por conta e pelo GUID `plex://`, e não por caminho nem por ID de item. Ele é reassociado quando o novo item corresponde ao mesmo GUID. Se o Plex associar errado o item readicionado, o estado não volta. Confira alguns depois da primeira varredura.

Você pode evitar essa troca por completo, mas há um custo. Reescrever `media_parts.file` no banco de dados do Plex para que as linhas nunca morram. Ou criar uma árvore de symlinks que recrie cada caminho antigo sobre o mount do zurg. Os dois funcionam. Os dois são uma intervenção não suportada em um esquema não documentado que muda entre versões do Plex. Uma reescrita aplicada pela metade é pior do que qualquer um dos dois resultados que ela deveria evitar.

Estes guias seguem o caminho simples e dizem exatamente o que ele custa.

## Sua biblioteca vai parar em `__magic__` e não em uma fazenda de symlinks {#your-library-lands-in-__magic__-and-not-in-a-symlink-farm}

Cada servidor desta lista entrega sua biblioteca para os \*arrs por meio de um conjunto de symlinks. **O zurg não faz isso, e você não deve reconstruir um.** Em vez disso, ele tem o [`__magic__`](../guides/magic.md). Esse é o único diretório cujos caminhos são *armazenados* e não calculados. Uma movimentação dentro dele reescreve uma linha em uma tabela pequena. Nenhum byte é movido. Nada é copiado. O release continua onde está, na conta. Aponte o Sonarr e o Radarr para ele e eles organizam e renomeiam do jeito que quiserem, sem custo nenhum.

Isso não é só uma peça a menos para cuidar. É uma camada que não tem como quebrar do jeito que a antiga quebrava. Um symlink precisa apontar para um caminho real. O alvo óbvio é `__all__/<release>/<file>`, e esse caminho é *calculado*. Ele muda quando o release é renomeado. Muda de novo quando dois releases colidem e o zurg adiciona o sufixo `{shorthash}` em um deles. Cada uma dessas mudanças deixa um link quebrado sem aviso. Um placement em `__magic__` é indexado pelo hash de conteúdo do release mais o caminho do arquivo dentro dele. Por isso ele sobrevive a uma renomeação. Sobrevive ao sufixo `{shorthash}`. Sobrevive a um reparo que readiciona o release com um id totalmente novo.

Então, seja o que for que você tenha hoje, **os caminhos vão mudar e a biblioteca precisa ser readicionada**. Isso vale para uma biblioteca de symlinks do \*arr e também para o Plex apontado direto para o mount antigo. É a troca mencionada acima e é todo o custo de qualquer migração aqui.

## O que você tem hoje depende da sua plataforma {#what-you-have-today-depends-on-your-platform}

Isto define se as tabelas de renomeação nas páginas seguintes descrevem a sua biblioteca do Plex ou apenas a fonte de onde ela foi criada. Acerte isso antes de ler as tabelas.

### Linux e macOS. Seus \*arrs já renomearam tudo {#linux-and-macos-your-arrs-already-renamed-everything}

A estratégia de symlink é a configuração documentada para os quatro servidores aqui e só existe nessas plataformas. O servidor publica `completed-symlinks/<category>/<release>/<file>.rclonelink`. Depois, `rclone mount
--links` transforma cada um deles em um symlink de verdade. Depois, **o Sonarr e o Radarr importam desse farm para uma biblioteca em caminhos que eles escolheram.** O mount é a fonte, não a biblioteca.

Duas consequências.

- **Os caminhos que o Plex enxerga são os do \*arr.** Sempre. Pasta raiz, depois pasta da série, depois pasta da temporada. Nenhuma delas contém o nome do release.
- **Os nomes dos arquivos também são do \*arr, se você deixou a renomeação ligada.** Isso é "Rename Episodes" e "Rename Movies". Com a renomeação desligada, eles são os nomes do servidor de origem, e as tabelas das próximas páginas descrevem exatamente o que você vê.

Então, se você usa os \*arrs com renomeação ligada, as tabelas de renomeação de cada servidor **não** descrevem a sua biblioteca. Elas descrevem o que o \*arr recebeu no momento da importação. Isso ainda importa. Um nome de arquivo de origem melhor significa um parse melhor, e você vai reimportar em breve.

### Windows. Nenhuma camada de symlink {#windows-no-symlink-layer-at-all}

A farm de symlinks precisa de `rclone mount --links`, e que isso não faz parte de uma configuração no Windows. O mount é uma letra de unidade via WinFsp, e o Plex e os \*arrs apontam direto para ela. Por isso **o Plex mostra os nomes de arquivo do próprio servidor**, e as tabelas de renomeação descrevem exatamente o que você vai ver mudar. A página [configuração no Windows](../setup/windows.md) explica a letra de unidade e a regra da sessão.

Os comandos de shell nas páginas de cada servidor são escritos para Linux e macOS (no macOS, leia `/mnt/zurg` como `/Volumes/Zurg`). No Windows, leia `/mnt/zurg` como `Z:\`, pare o servidor antigo do jeito que você o iniciou, e crie pastas e mova arquivos dentro de `__magic__` com os comandos PowerShell do [guia do `__magic__`](../guides/magic.md).

### Saindo de uma biblioteca com symlinks {#coming-off-a-symlink-library}

You are not moving a library. You are rebuilding one. And `__magic__` gives the
\*arrs exactly what the symlink farm gave them without the farm. They move and
rename inside it as freely as before. Each move is a row write instead of a
file operation.

!!!danger Never let an \*arr move the old library into `__magic__`
Changing a series or movie root folder makes Sonarr or Radarr offer to **move**
the files. Say no. A move inside `__magic__` is free. A move from anywhere else crosses the
mount boundary and that is a copy. So is a move between two volumes of the same
mount. In Docker give the \*arr one volume that holds zurg's whole mount. A copy off a streaming mount pulls your
entire library down through your news or debrid allowance. Your old library is
a tree of symlinks so what gets copied is every target they resolve to.
!!!

Move each file into place yourself instead. Every move is one rename through
zurg's mount. Nothing is copied and nothing on your account changes. The script
below does it from your old library of symlinks. A link's path under the old
root folder is where Sonarr or Radarr expects the episode or film. Its target
names the file. So each file lands at the same path under the new root folder
that its link had under the old one. The old library is only read. It keeps
working until you switch the \*arr over.

1. **Build zurg beside the old server** as its page shows. Let it list the
   whole library first.
2. **Turn on `__magic__`** as its page shows. Keep Plex scans off and the
   \*arr queues paused.
3. **Save the `zurg_path` function from your server's page** as
   `zurg_path.sh` beside the script. It turns an old link's target into the
   file zurg serves. Each server lays its files out differently.
4. **Run the script** once per root folder. Set `OLD` and `NEW` and `LOG` for
   each one. A setup with `sonarr4k` and `radarr4k` beside the regular pair
   needs four runs.

   ```bash
   #!/bin/bash
   # adopt.sh — move every file an old root folder links to into __magic__.
   # One rename per file through zurg's mount. Nothing is copied or downloaded.
   # The old root folder is only read. GNU find and bash required.
   ZURG=/mnt/zurg                  # zurg's own mount
   OLD=/data/media/tv              # the old root folder, a tree of symlinks
   NEW="$ZURG/__magic__/tv"        # the new root folder inside __magic__
   LOG=./adopt-tv.log              # what went where
   . ./zurg_path.sh                # the zurg_path function from your server's page
   find "$OLD" -type l | while IFS= read -r link; do
     dest="$NEW/${link#"$OLD"/}"
     [ -e "$dest" ] && { echo "ALREADY THERE: $dest"; continue; }
     src=$(zurg_path "$(readlink "$link")")
     [ -n "$src" ] && [ -f "$src" ] || { echo "NOT IN ZURG: $link"; continue; }
     mkdir -p "$(dirname "$dest")"
     if mv "$src" "$dest"; then
       printf '%s\t%s\n' "$src" "$dest" >> "$LOG"
     else
       echo "FAILED: $link"
     fi
   done
   # Real files such as subtitles are small. They are copied and land on zurg's own disk.
   find "$OLD" -type f -size -32M | while IFS= read -r file; do
     dest="$NEW/${file#"$OLD"/}"
     [ -e "$dest" ] || { mkdir -p "$(dirname "$dest")" && cp "$file" "$dest"; }
   done
   ```

   It prints a line for every link it leaves alone.

   - `NOT IN ZURG` is a link to a file zurg does not have. Its NZB could not be
     recovered or its account is not in zurg's config.
   - `FAILED` is a move zurg refused. A second link to a file the script
     already moved prints this after a line from `mv` that says `No such file
     or directory`. A file can sit at only one path in `__magic__`. It stays
     where the first link put it.
   - `ALREADY THERE` is a path the new root folder already holds. Running the
     script again skips everything it placed before.

5. **Switch each \*arr over.** Select every series or every movie and edit them
   together. Set the root folder to the new one under `__magic__`. When it asks
   whether to move the files answer **No, I'll Move the Files Myself**. The
   script already put them there. Then run **Update All** so it finds them.
6. **Point Plex at the new root folders** and at nothing else. The next box
   says why.

Each move took about 15 milliseconds on a test library and nothing was copied.
Watch `data/local` on zurg's `/magic/` dashboard while the script runs. It
grows only by the subtitles and other small files the script copies. A number
that grows by gigabytes means something is being copied. Stop and look.

The old links keep working. A moved file still shows at its old `__all__` path
as well as at its new one. Builds before the 2026.10.04 nightly hid it at the
old path for up to 12 hours even though zurg still served it there. On one of
those builds restart zurg once the script is done. Keep Plex away from the old
folders and from `__all__` until you have.

The zurg side of this was measured on 2026-10-03. The \*arr side is its
ordinary root folder edit and was not tested for this guide. Do one series
first.

!!!warning Point each Plex library at one directory and not two
A library that scans a filter directory such as `movies` or `shows` or
`__all__` **and** scans `__magic__` finds every episode twice — and `__magic__`
holds its own `__all__`, so pointing a library at the root of the namespace
scans the whole library along with what you organised. Pick one. If you use the
\*arrs then point Plex at the root folders you made, `__magic__/tv` and
`__magic__/movies`. If you browse a library nobody organises then pick the
filter directories and leave `__magic__` off.
!!!

## A única proteção que você não pode pular {#the-one-guard-you-must-not-skip}

**`autoEmptyTrash` precisa estar em `0` antes de você mexer em qualquer coisa.**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

No Windows, no PowerShell:

```powershell
$TOKEN = 'your-plex-token'
((Invoke-RestMethod "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN").MediaContainer.Setting | Where-Object id -eq autoEmptyTrash).value
# set it if needed:
curl.exe -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

O Plex mostra a configuração como `0` ou `false` quando ela está desligada.

O Plex apaga de forma suave. Com `0`, um item cujo arquivo deixou de existir fica na lixeira e volta se o arquivo reaparecer. Com `1`, ele some para sempre no momento em que um scan percebe. Uma montagem que cai por dez segundos durante um scan leva a biblioteca inteira junto. Isso já custou dezenas de milhares de itens antes.

Nesses guias simplificados, essa configuração faz mais trabalho do que antes, e não menos. **A lixeira é onde os seus itens antigos esperam enquanto você confere os novos.** Esvazie a lixeira quando estiver satisfeito, e não antes. Esse é o passo que torna a perda real, e é a única coisa irreversível em todos esses guias.

Já que você está nessas configurações, desligue **"Generate video preview thumbnails"** nas bibliotecas afetadas. Em uma montagem de streaming, cada passe de thumbnails é uma leitura completa do release, consumindo a sua cota de Usenet ou debrid. Uma migração entrega ao Plex um monte de itens novos de uma vez.

## O que toda migração ganha {#what-every-migration-gains}

Dois deles são arquivos novos que aparecem em pastas que o Plex já escaneia. Vale a pena saber disso antes que eles te peguem de surpresa.

- **Clipes de amostra.** O zurg é o único dos cinco que publica o arquivo de amostra dentro da pasta `Sample/` de um lançamento em RAR. O Plex pode pegar um `-sample.mp4` de 9 MB e tratá-lo como um extra ou como uma segunda versão do episódio. Se você não quiser isso, defina [`only_show_the_biggest_file: true`](../reference/config.md) nas pastas que suas bibliotecas de mídia escaneiam.
- **Arquivos `.nfo`.** O zurg é o único que os mantém. Eles não fazem nada com os agentes padrão do Plex. O agente XBMC e NFO lê esses arquivos, se você usar ele.
- **Propagandas `thumbnail.jpg` e `.url`.** Não fazem nada. `thumbnail.jpg` não é um nome de arquivo que o Plex usa para pôsteres, e os arquivos `.url` são só propaganda de quem publicou o conteúdo.
- **Pastas vazias** onde a cadeia de arquivos de um lançamento está quebrada. O Plex ignora pastas sem nenhum arquivo de mídia.
- **Os par2 e sfv somem.** O zurg os esconde lendo o que o arquivo é, e não o nome dele. O Plex nunca os listou, então isso não aparece na sua biblioteca. Só importa para ferramentas que percorriam essas pastas.

## Os guias {#the-guides}

- [De AltMount](altmount.md). Renomeia apenas releases de arquivo
- [De decypharr](decypharr.md). Renomeia releases de arquivo único e de arquivo compactado
- [De InfiniDysk](infinidysk.md). Renomeia releases de arquivo único e de arquivo compactado
- [De nzbdav](nzbdav.md). Não renomeia nada e é o mais fácil dos cinco
- [De streamnzb](streamnzb.md). Não há biblioteca para migrar. O zurg tem um addon próprio para o Stremio

Saindo do Plex em vez de ir para o zurg? [Mova do Plex para o rex](../../rex/from-plex.md) mantém o zurg e seus apps do Plex e roda o rex ao lado do seu servidor Plex ou no lugar dele.

O comportamento de nomeação de cada página foi medido em 2026-09-01 em um corpus de cinco releases.
As builds foram zurg `bda7e3c3`, AltMount `0614008b`, InfiniDysk `cd9b1205`, nzbdav `794948be` e decypharr `0dd1cbbd`. Uma build mais antiga ou mais nova que essas pode nomear as coisas de outro jeito. Confira algumas releases na sua própria árvore antes de confiar totalmente em uma lista de rescan.
