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

Você não está movendo uma biblioteca. Você está reconstruindo uma. E `__magic__` entrega aos \*arrs exatamente o que a fazenda de symlinks entregava, só que sem a fazenda. Eles continuam movendo e renomeando dentro dela com a mesma liberdade de antes. Cada movimento agora é uma escrita de linha em vez de uma operação de arquivo.

!!!danger Nunca deixe um \*arr mover a biblioteca antiga para dentro de `__magic__`
Ao trocar a pasta raiz de uma série ou de um filme, o Sonarr ou o Radarr oferecem **mover** os arquivos. Diga não. Um movimento dentro de `__magic__` é gratuito. Um movimento de qualquer outro lugar cruza a fronteira do mount, e isso é uma cópia. Também é uma cópia um movimento entre dois volumes do mesmo mount. No Docker, dê ao \*arr um único volume que contenha todo o mount do zurg. Uma cópia a partir de um mount de streaming puxa a sua biblioteca inteira pela sua cota de Usenet ou de debrid. Sua biblioteca antiga é uma árvore de symlinks, então o que seria copiado é cada alvo para o qual eles apontam.
!!!

Mova cada arquivo para o lugar certo você mesmo. Cada movimento é um único rename através do mount do zurg. Nada é copiado e nada na sua conta muda. O script abaixo faz isso a partir da sua biblioteca antiga de symlinks. O caminho de um link dentro da pasta raiz antiga é onde o Sonarr ou o Radarr espera o episódio ou o filme. O alvo do link informa qual é o arquivo. Assim, cada arquivo acaba no mesmo caminho dentro da nova pasta raiz que o link tinha na antiga. A biblioteca antiga é só lida. Ela continua funcionando até você trocar os \*arrs.

1. **Monte o zurg ao lado do servidor antigo** como mostra a página dele. Deixe-o listar a biblioteca inteira primeiro.
2. **Ligue o `__magic__`** como mostra a página dele. Mantenha os scans do Plex desligados e as filas dos \*arrs pausadas.
3. **Salve a função `zurg_path` da página do seu servidor** como `zurg_path.sh` ao lado do script. Ela transforma o alvo de um link antigo no arquivo que o zurg serve. Cada servidor organiza os arquivos de um jeito diferente.
4. **Rode o script** uma vez para cada pasta raiz. Defina `OLD`, `NEW` e `LOG` para cada uma. Uma configuração com `sonarr4k` e `radarr4k` ao lado do par normal precisa de quatro execuções.

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

   Ele imprime uma linha para cada link que deixa de lado.

   - `NOT IN ZURG` é um link para um arquivo que o zurg não tem. Ou o NZB dele não pôde ser recuperado, ou a conta dele não está na configuração do zurg.
   - `FAILED` é um movimento que o zurg recusou. Um segundo link para um arquivo que o script já moveu imprime isso depois de uma linha do `mv` dizendo `No such file or directory`. Um arquivo só pode estar em um caminho dentro de `__magic__`. Ele fica onde o primeiro link o colocou.
   - `ALREADY THERE` é um caminho que a nova pasta raiz já tem. Rodar o script de novo pula tudo o que ele já colocou no lugar.

5. **Troque cada \*arr.** Selecione todas as séries ou todos os filmes e edite-os juntos. Defina a pasta raiz como a nova dentro de `__magic__`. Quando ele perguntar se deve mover os arquivos, responda **No, I'll Move the Files Myself**. O script já os colocou lá. Depois rode **Update All** para que ele os encontre.
6. **Aponte o Plex para as novas pastas raiz e para nenhuma outra.** A próxima caixa explica por quê.

Cada movimento levou cerca de 15 milissegundos em uma biblioteca de teste e nada foi copiado. Acompanhe `data/local` no painel `/magic/` do zurg enquanto o script roda. Ele só cresce com as legendas e outros arquivos pequenos que o script copia. Um número que cresce em gigabytes significa que algo está sendo copiado. Pare e verifique.

Os links antigos continuam funcionando. Um arquivo movido ainda aparece no caminho antigo em `__all__`, além do novo. As versões anteriores à nightly de 2026.10.04 escondiam o arquivo no caminho antigo por até 12 horas, mesmo com o zurg ainda o servindo ali. Em uma dessas versões, reinicie o zurg uma vez quando o script terminar. Mantenha o Plex longe das pastas antigas e de `__all__` até fazer isso.

A parte do zurg desta página foi medida em 2026-10-03. A edição de pasta raiz no \*arr é o procedimento comum dele e não foi testada para este guia. Faça uma série primeiro.

!!!warning Aponte cada biblioteca do Plex para um diretório, e não para dois
Uma biblioteca que escaneia um diretório de filtro como `movies`, `shows` ou `__all__` **e** também escaneia `__magic__` encontra cada episódio duas vezes. E `__magic__` contém o seu próprio `__all__`, então apontar uma biblioteca para a raiz do namespace escaneia a biblioteca inteira junto com o que você organizou. Escolha um. Se você usa os \*arrs, aponte o Plex para as pastas raiz que você criou, `__magic__/tv` e `__magic__/movies`. Se você navega por uma biblioteca que ninguém organiza, escolha os diretórios de filtro e deixe `__magic__` de fora.
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
