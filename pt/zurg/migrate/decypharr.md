# Migrando do decypharr para o zurg {#migrating-from-decypharr-to-zurg}

Leia [a página compartilhada](index.md) primeiro. Ela explica o trash guard e por que sua biblioteca cai em `__magic__`.

decypharr e zurg resolvem o mesmo problema, e os layouts de raiz deles são parecidos. Boa parte da configuração se aproveita.

| decypharr | zurg |
|---|---|
| `__all__/<job>/<file>` | `__all__/<name>/<file>` |
| `version.txt` | `version.txt` |
| `__bad__/` | `__unplayable__/` |
| `torrents/` | uma entrada `directories:` com `not_provider: nzb` |
| `nzbs/<job>/` | uma entrada `directories:` com `provider: nzb` ou a `__nzb__` embutida |

O **lado do debrid não precisa de nada**. Os dois servidores listam as mesmas contas e apresentam os nomes de arquivo originais do torrent. Esses caminhos são idênticos quando o zurg fica no ponto de montagem do decypharr. Tudo abaixo é sobre o lado Usenet.

Duas coisas para resolver antes de começar.

- **Provedores.** Eles não limitam a migração. O zurg tem um backend para
  todo serviço que o decypharr suporta. Contas Premiumize e Debrid-Link migram
  como as demais. Cada uma tem uma página em [Provedores](../providers/index.md).
- **Não mude o `folder_naming` do decypharr antes de migrar.** Ele renomeia
  todas as pastas da biblioteca de uma vez. Isso quebra todos os alvos de symlink
  e todos os caminhos do Plex em mount-direct de uma só vez.

## O que muda no lado do Usenet {#what-differs-on-the-usenet-side}

Medido contra o zurg nos mesmos cinco lançamentos.

| | |
|---|---|
| o zurg ganha | `thumbnail.jpg`, o clipe de amostra, o `.nfo`, os anúncios `.url`, o diretório interno do arquivo, **e o lançamento ofuscado que o decypharr descartou** |
| o zurg perde | nada |
| renomeados | lançamentos de arquivo único e lançamentos em arquivo compactado |

**Lançamentos de arquivo único** saem do decypharr com o nome da tarefa. Você recebe
`ToyStory5/ToyStory5.mkv`, enquanto o zurg mantém o nome que o postador deu e serve
`ToyStory5/Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`.

**Lançamentos em arquivo compactado** são o caso mais interessante e vale entender, porque
explica dois sintomas de uma vez. O decypharr gera isto.

```
FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLAfather.brown.2013.s02e05.hdtv.x264-tla.mp4
```

Isso é o nome do diretório interno do arquivo concatenado com o nome do próprio arquivo, **sem separador nenhum**. É uma junção de caminhos que perdeu o `/`. Ou seja, o nível de diretório que falta e o nome de arquivo malformado são o mesmo defeito, e não dois. O zurg reproduz a estrutura real em
`FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown.….mp4`.

**Lançamentos de múltiplos arquivos e temporadas completas mantêm os nomes reais de arquivo nos dois lados.** Eles batem automaticamente assim que o nome da pasta bate.

## Como fica sua biblioteca depois {#what-your-library-looks-like-afterwards}

**Tudo é adicionado de novo** porque a raiz da biblioteca muda para `__magic__`. Veja [a página compartilhada](index.md) para entender por que não existe um caminho mais barato.

O ganho está nos nomes. Todo release de arquivo único volta com o nome de arquivo de quem postou, e não com o nome do job. Assim, `ToyStory5/ToyStory5.mkv` vira `Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`. É essa string que o Sonarr, o Radarr e o Plex leem para identificar qualidade, fonte, grupo e edição. Releases de arquivo deixam de carregar um nome colado e passam a ficar no diretório próprio do arquivo. Releases com vários arquivos e season packs já são lidos corretamente e não mudam.

Liste os releases cujos nomes vão mudar.

```bash
MOUNT=/mnt/decypharr
for d in "$MOUNT"/__all__/*/; do
  job=$(basename "$d")
  n=$(find "$d" -type f | wc -l)
  [ "$n" -eq 1 ] && echo "RENAMED BY DECYPHARR: $job"
done
```

!!!info Se você vai ver isso depende da sua configuração
Se o Plex lê o mount diretamente, então os nomes acima são o que muda na sua biblioteca. Isso vale para qualquer configuração no Windows e para qualquer uma no Linux ou macOS que não use uma fazenda de symlinks do \*arr.

Se o Sonarr e o Radarr organizam uma biblioteca de symlinks com renomeação ativada, então **os seus nomes de arquivo já são os deles** e nenhum dos nomes acima aparece no Plex. O que os nomes mostram, nesse caso, é a qualidade do parse que o \*arr estava usando. Isso importa na hora de reimportar. Veja [a página compartilhada](index.md).
!!!

## O que aparece de conteúdo novo {#what-new-content-shows-up}

- **Clipes de amostra** dentro de `Sample/`. Este é o que vale a pena configurar. Defina
  [`only_show_the_biggest_file: true`](../reference/config.md) se você não quiser que uma amostra de 9 MB apareça como uma segunda versão.
- `thumbnail.jpg`, o `.nfo` e os arquivos `.url` de propaganda do pôster. Todos inofensivos.
- **Releases ofuscadas que o decypharr deixou passar** chegando como novos itens da biblioteca. O decypharr não publicou nada para um post com nome totalmente em hash. O zurg resolve para o nome real do release e o serve.
- Pastas vazias onde uma cadeia de arquivos está quebrada.

## Recupere seus NZBs {#get-your-nzbs-back}

**decypharr não consegue entregar eles para você.** Ele guarda um binário comprimido por job
em `usenet/meta/<uuid>.meta` e um diretório `usenet/nzbs/` que estava vazio na bancada. Não existe exportação documentada. Se os blobs `.meta` podem ser decodificados de volta em NZBs não foi verificado. Trate os originais como irrecuperáveis.

O que você tem são os nomes dos jobs. Nos dois servidores, o nome da pasta do job *é* o nome do arquivo NZB. Então a lista de pastas é a sua lista de compras.

```bash
MOUNT=/mnt/decypharr
ls "$MOUNT/nzbs" > nzb-jobs.txt      # the usenet jobs
wc -l nzb-jobs.txt
```

Para cada job, baixe o NZB de novo do seu indexador pesquisando pelo nome da pasta. Depois **renomeie o arquivo para exatamente esse nome mais `.nzb`** antes de colocá-lo no diretório `nzbs/` do zurg. O nome do arquivo é o nome da pasta, e o nome da pasta é o que mantém o caminho estável.

Duas regras enquanto você faz isso.

- **Pule qualquer release que uma conta debrid já tenha.** O symlink resolve pela cópia do torrent. Se você adicionar também o NZB, o zurg passa a ver duas releases diferentes com o mesmo nome e adiciona um sufixo de hash em uma delas, ficando `Some.Release {a1b2c3}`. Isso quebra tudo que apontava para o nome original.
- Uma release que o seu indexador não tem mais simplesmente se perdeu. Com `autoEmptyTrash` em `0`, o item do Plex fica na lixeira até você decidir apagá-lo.

## Monte o zurg ao lado {#build-zurg-alongside}

Rode o zurg ao lado do decypharr no próprio mountpoint. Os dois podem listar as mesmas contas de debrid ao mesmo tempo, porque a listagem é somente leitura.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_TOKEN
  # - type: alldebrid / torbox as you have them
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30                # your plan's real allowance
retain_rd_torrent_name: false        # align with decypharr's folder_naming
retain_folder_name_extension: false  # true if your folders carry .mkv/.mp4
mount_path: "/mnt/zurg-staging"
rclone_enabled: true
rclone_binary: bin/rclone
directories:                         # optional: mirror decypharr's top level
  torrents:
    filters:
      - not_provider: nzb
  nzbs:
    filters:
      - provider: nzb
```

Depois, confira se o lado do debrid está alinhado antes de seguir em frente.

```bash
ls /mnt/decypharr/__all__      | sort > decypharr-jobs.txt
ls /mnt/zurg-staging/__all__   | sort > zurg-jobs.txt
diff decypharr-jobs.txt zurg-jobs.txt
```

Às vezes, os nomes das pastas de torrent são diferentes *de forma sistemática*. Uma extensão aparece ou some. O nome renomeado do RD aparece no lugar do original. Nesse caso, mude `retain_rd_torrent_name` ou `retain_folder_name_extension` e faça um rescan, em vez de corrigir nada na mão. Pastas que existem só no lado do decypharr são os jobs de Usenet. Os nomes de pastas do Premiumize e do Debrid-Link não foram comparados com os do decypharr. Confira também as pastas dessas contas aqui.

## Faça a troca {#cut-over}

Uma única opção, com o que você tem hoje. Nada aqui move bytes.

**1. Ative o `__magic__`** e reinicie. As rotas são registradas na inicialização, então
um toggle no dashboard precisa de reinício antes que o namespace responda.

```yaml
magic:
  enabled: true
```

**2. Crie as pastas raiz.** Elas ficam na raiz do `__magic__`, ao lado do
`__all__` que o zurg mantém ali. Não em `__magic__/__all__`, nem em `__magic__`
em si, nem na raiz do mount. Os dois \*arrs disparam um health check para esses
casos; pastas irmãs não disparam nenhum.

No Docker, os \*arrs precisam acessar o `__all__` e essas pastas raiz por meio de
um único volume. Configurações com decypharr costumam montar uma pasta de downloads
e uma pasta de mídia separadamente. Dois volumes transformam cada importação em uma
cópia completa. Monte o diretório pai do mount do zurg uma vez só. O
[passo a passo](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)
mostra como fazer.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` espelha a biblioteca, então todo release já está presente antes
de você organizar qualquer coisa.

**3. Organize.** Um `mv` dentro do `__magic__` grava uma linha e não move nenhum byte.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Se o Sonarr e o Radarr organizaram sua biblioteca antiga, mova ela com um único script.**
Ele renomeia cada arquivo que a biblioteca antiga linka para uma nova pasta raiz
dentro do `__magic__`. Cada um cai no caminho que o \*arr já espera.
Nada é copiado. Depois você troca o root folder do \*arr sem deixar que ele mova nada.
Os passos e o script estão na
[página compartilhada](index.md#coming-off-a-symlink-library). Nunca deixe um \*arr
mover os arquivos sozinho. Isso atravessa a fronteira do mount. Vira cópia e baixa
toda a sua biblioteca.

O script precisa de uma função `zurg_path` para os links do decypharr. Salve isto como
`zurg_path.sh` ao lado dele e defina `OLDMOUNT` com o local onde o decypharr está montado.

```bash
OLDMOUNT=/mnt/decypharr         # decypharr's mount, where the old links point
zurg_path() {
  local rel=${1#"$OLDMOUNT"/__all__/}
  [ "$rel" = "$1" ] && return   # not a link into decypharr
  local job=${rel%%/*} name=${1##*/} f videos
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # decypharr welded an archive's inner folder and file into one name.
  for f in "$ZURG/__all__/$job"/*/*; do
    [ "$(basename "$(dirname "$f")")$(basename "$f")" = "$name" ] && { echo "$f"; return; }
  done
  # decypharr named a lone video after the job. Take the job's one video.
  case "$name" in "$job".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$job" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Um link para um release de debrid ou para um release NZB com vários arquivos aponta
para o mesmo arquivo nos dois servidores. O decypharr renomeou dois tipos de release NZB.
Ele deu a um vídeo solto o nome do job e fundiu a pasta e o arquivo de um arquivo
compactado num único nome. A função encontra a cópia do zurg nos dois casos. Um job
com mais de um vídeo nunca é adivinhado. Nesse caso ela imprime `NOT IN ZURG`.

**4. Aponte o Plex para as pastas raiz que você criou** — `__magic__/tv` e
`__magic__/movies` — e só para elas. Nunca para a raiz do `__magic__`, que também
guarda a biblioteca inteira em `__magic__/__all__`, e nunca para `__magic__`
*e* para uma pasta de filtro, senão cada episódio é encontrado duas vezes. Confirme
que `autoEmptyTrash` está em `0`. Adicione o novo local e faça a varredura. Depois
remova o antigo. Esse é o caminho da biblioteca no seu \*arr ou o mount do decypharr,
caso o Plex leia direto dele.

**5. Esvazie a lixeira** depois de conferir alguns itens por amostragem. O estado de
exibição volta pelo match de GUID. Coleções e escolhas de arte não voltam.

Deixe o decypharr rodando até lá. Ele não custa nada e é o seu plano de volta.
Também não apague a configuração, nem o estado em `db/` ou `usenet/`. Quando terminar,
pare o serviço.

```bash
sudo systemctl stop decypharr
```

## Depois {#afterwards}

**A automação continua funcionando, nas duas partes.** O zurg tem um endpoint compatível com SABnzbd, opcional, [aqui](../guides/sonarr-radarr.md), para que o Sonarr e o Radarr possam enviar um NZB para ele. Ele também tem um endpoint compatível com qBittorrent, opcional, [aqui](../guides/sonarr-radarr-torrents.md), para que eles enviem um magnet ou um `.torrent` para uma conta debrid. Os dois importam de `__magic__/__all__` renomeando. Veja suas opções.

- **NZBs.** Ative `sabnzbd.enabled` e aponte os \*arrs para o zurg. O zurg verifica cada envio antes de informar que ele terminou. Ele pergunta aos servidores de notícias sobre o início e o fim de cada arquivo. Também baixa o primeiro artigo de cada arquivo. São até sessenta e quatro deles, mais alguns a mais em um release com poucos arquivos. Alguns servidores de notícias ainda dizem que um artigo existe depois que o conteúdo foi removido, e só um download mostra isso. Quando possível, o zurg reconstrói um release que perdeu artigos nos seus arquivos PAR2. Um release que ele não consegue reconstruir é informado como **Failed**. Aí o \*arr o coloca na blocklist e pega outro. A verificação é uma amostra, não o post inteiro. Um post que perdeu um trecho que a amostra não alcançou ainda aparece como Completed e falha na leitura que chega até a falha.
- **Torrents.** Ative `qbittorrent.enabled` e adicione-o como um segundo cliente de download. O release de um tracker privado funciona quando o indexador entrega um arquivo `.torrent` em vez de um magnet simples, porque o arquivo informa o hash diretamente para a busca no cache da conta.
- **Adições avulsas.** O painel do zurg não tem botão de adicionar. Adicione um magnet ou um `.torrent` pelo endpoint qBittorrent com a categoria de um dos \*arrs e ele vai para aquele \*arr. [Adicionando um release manualmente](../guides/sonarr-radarr-torrents.md#11-adding-a-release-by-hand) mostra como fazer. Um magnet adicionado pelo DMM e um NZB colocado em `nzbs/` aparecem na lista do zurg. Nenhum dos dois chega ao Sonarr ou ao Radarr sozinho. A [aquisição](../guides/acquisition.md) do próprio zurg também busca pedidos sozinha. Eles vêm da sua watchlist do Plex e do Seerr e dos \*arrs. Ela pega NZBs de indexadores Newznab e torrents de indexadores Torznab quando a sua conta já os tem em cache.
- **Híbrido.** Mantenha o decypharr apenas como cliente de download dos \*arrs, enviando para as mesmas contas debrid, com o zurg servindo o mount. Os dois listam a mesma conta, então o zurg pega o que o decypharr adiciona. A etapa de importação do \*arr então precisa de mapeamento de caminho remoto para a árvore do zurg. Essa árvore e as pastas raiz precisam estar no mesmo volume. Teste um envio primeiro.
