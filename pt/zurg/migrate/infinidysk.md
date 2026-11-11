# Migrando do InfiniDysk para o zurg {#migrating-from-infinidysk-to-zurg}

[the shared page](index.md) primeiro. Ele explica o trash guard e por que sua biblioteca cai em `__magic__`.

Medido contra o zurg nas mesmas cinco releases.

| | |
|---|---|
| o zurg ganha | o clipe de amostra, o `.nfo` |
| o zurg perde | 5 volumes par2 com nome hash dentro de releases ofuscadas |
| renomeados | **todas as releases exceto as de múltiplos arquivos** |

!!!warning A renomeação é a migração inteira
O InfiniDysk renomeia o arquivo de mídia de uma release para o nome do arquivo NZB sempre que a release resolve para um único payload. No corpus de 2026-09-01, quatro de cinco viraram `ToyStory5.mkv`, `Obfuscated.mkv`, `FatherBrown.mp4` e `MandaloriaREMUX.mkv`. Só o pacote de temporada de dez episódios manteve os nomes dos episódios.
A renomeação vale em qualquer profundidade. `FatherBrown.mp4` fica *dentro* do diretório preservado `Father.Brown.2013.S02E05.HDTV.x264-TLA/`.

O zurg mantém o nome de arquivo original do poster. Assim, o nome da release volta e toda release de payload único muda de caminho. Esse nome é a string que o Plex e os \*arrs leem para qualidade, grupo e episódio.
!!!

Mais uma diferença, pequena mas confusa se você topar com ela do nada. O InfiniDysk cria o diretório `Sample/` do arquivo e o deixa **vazio**. O zurg coloca o clipe de amostra dentro dele.

O conteúdo não é motivo para mudar. A build `cd9b1205` importou as cinco releases do corpus de referência, incluindo o pacote de temporada. Não espere ver o InfiniDysk descartando nada. O que você recebe de volta é a nomeação.

!!!warning Nunca percorra a raiz do WebDAV
O object store `.ids` materializa todos os 16 filhos hex em cada um dos seus cinco níveis, independentemente do conteúdo. Isso dá 16^5, ou cerca de 1.048.576 diretórios. Aponte `find`, `du`, `rclone` e qualquer scanner explicitamente para `/content`, `/nzbs` ou `/completed-symlinks`. Nunca para `/`.
!!!

## Como fica sua biblioteca depois {#what-your-library-looks-like-afterwards}

**Tudo é adicionado de novo** porque a raiz da biblioteca muda para `__magic__`. Veja [a página compartilhada](index.md) para entender por que não existe um caminho mais barato.

Esta é a migração em que isso custa menos e ganha mais. Quase todos os nomes de arquivo melhoram. `ToyStory5.mkv` vira `Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`, e um \*arr que reimporta de `__magic__` finalmente consegue ler qualidade, fonte, grupo e edição a partir do nome do arquivo. Só os season packs continuam como estavam, e esses já são lidos corretamente.

Liste os releases cujos nomes vão mudar. Vão ser a maioria.

```bash
ID=/mnt/remote/nzbdav                      # your InfiniDysk mount
find "$ID/content" -mindepth 3 -maxdepth 4 -type f | while IFS= read -r f; do
  rel=$(basename "$(dirname "$f")")
  b=$(basename "$f")
  [ "${b%.*}" = "$rel" ] && echo "RENAMED BY INFINIDYSK: $f"
done
```

O `-maxdepth 4` é importante porque a renomeação pode acontecer um nível dentro de um diretório de arquivo.

!!!info Se você vai ver algo disso depende da sua configuração
Se o Plex lê o mount diretamente, então os nomes acima são o que muda na sua biblioteca. Isso cobre todas as configurações no Windows e qualquer configuração no Linux ou macOS sem um conjunto de symlinks do \*arr.

Se o Sonarr e o Radarr organizam uma biblioteca de symlinks com renomeação ativada, então **os seus nomes de arquivo já são os deles** e nenhum dos nomes acima aparece no Plex. O que os nomes mostram, nesse caso, é a qualidade da leitura que o \*arr fazia. Isso importa na hora de reimportar. Veja [a página compartilhada](index.md).
!!!

## O que aparece de conteúdo novo {#what-new-content-shows-up}

- **Clipes de amostra.** As pastas `Sample/` que você já tem deixam de estar vazias. Essa é a opção que vale a pena configurar. Defina [`only_show_the_biggest_file: true`](../reference/config.md) se você não quiser que uma amostra de 9 MB apareça como uma segunda versão do episódio.
- O `.nfo` dentro de releases em RAR. Não faz nada com os agentes padrão do Plex.
- Pastas vazias onde a cadeia de arquivos está quebrada. O InfiniDysk não criou nada para elas.
- **Os arquivos par2 e sfv deixam de ser visíveis.** Isso inclui os volumes com nome de hash em releases ofuscadas. Eles não têm extensão de mídia, então o Plex não vai listá-los. Se alguma ferramenta que você usa fora do Plex lia esses arquivos, ela vai perceber a diferença.

## Tire seus NZBs de lá {#get-your-nzbs-out}

zurg é alimentado por um diretório de arquivos `.nzb`. Um por release, nomeado com o nome da pasta da release. O `/nzbs/<category>/` do WebDAV da InfiniDysk espelha a fila e pode ser lido.

```bash
mkdir -p ~/recovered-nzbs
rclone copy infinidysk:nzbs ~/recovered-nzbs/ --include '*.nzb'   # scoped to /nzbs, never the root
find ~/recovered-nzbs -name '*.nzb' | wc -l
```

Se as tarefas concluídas continuam listadas em `/nzbs` depois de terminar é **não verificado**. Ele espelha a fila, e o seu histórico pode ser mais profundo que a fila. Para qualquer item que esteja sem os metadados NZB que a InfiniDysk guarda para remontagem, eles ficam em `{CONFIG_PATH}/blobs/`. O formato dos blobs não foi verificado, então confira antes de confiar nele.

```bash
for f in "$CONFIG_PATH"/blobs/*; do head -c 32 "$f" | grep -q '<?xml' && echo "NZB: $f"; done
```

Se os blobs não forem XML simples na sua instalação, o histórico de downloads do seu indexador é a alternativa.

Depois, crie um arquivo `<release>.nzb` para cada pasta de release que você realmente tem.

```bash
find "$ID/content" -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | awk -F/ '{print $1 "\t" $2}' > releases.tsv
```

Os NZBs baixados de `/nzbs/<category>/` normalmente já têm o nome certo, porque é de lá que veio o nome da pasta. Vale conferir a lista com duas regras de nomenclatura do zurg.

- O zurg remove `.mkv` ou `.mp4` do final do nome da pasta. Se alguma pasta de release terminar assim, defina `retain_folder_name_extension: true`.
- Duas releases diferentes com o mesmo nome recebem o sufixo ` {shorthash}` em uma delas. Encontre-as com `cut -f2 releases.tsv | sort | uniq -d`. A InfiniDysk teve o mesmo problema, mas de outro jeito. Reimportar um NZB lá criou `<Release> (2)`.

## Monte o zurg ao lado {#build-zurg-alongside}

InfiniDysk continua funcionando o tempo todo.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from InfiniDysk's provider settings
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
enable_repair: true
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp ~/recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l          # should approach your release count
```

`__all__` guarda todos os lançamentos, independentemente dos filtros de diretório.

## Faça a troca {#cut-over}

Um único caminho, seja qual for o seu caso hoje. Nada aqui move bytes.

**1. Ative o `__magic__`** e reinicie. As rotas são registradas na inicialização, então
um toggle no dashboard precisa de reinício antes que o namespace responda.

```yaml
magic:
  enabled: true
```

**2. Crie as pastas raiz.** Elas vão na raiz do `__magic__`, ao lado do `__all__` que o zurg mantém ali. Não em `__magic__/__all__`, nem em `__magic__` em si, nem na raiz do mount. Os dois \*arrs disparam uma verificação de saúde para esses casos; pastas irmãs não disparam nenhuma.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` espelha a biblioteca, então cada release já está presente antes de você organizar qualquer coisa.

**3. Organize.** Um `mv` dentro do `__magic__` grava uma linha e não move bytes.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Se o Sonarr e o Radarr organizaram sua biblioteca antiga, traga ela para cá com um único script.** Ele renomeia cada arquivo que a biblioteca antiga linka para uma nova pasta raiz dentro do `__magic__`. Cada um cai no caminho que o \*arr já espera. Nada é copiado. Depois você troca a pasta raiz do \*arr sem deixar que ele mova nada. Os passos e o script estão em [a página compartilhada](index.md#coming-off-a-symlink-library). Nunca deixe um \*arr mover os arquivos por conta própria. Isso cruza a fronteira do mount. Vira uma cópia e baixa sua biblioteca inteira.

O script precisa de uma função `zurg_path` para os links do InfiniDysk. Salve isso como `zurg_path.sh` ao lado dele e defina `OLDMOUNT` com o local onde o InfiniDysk está montado.

```bash
OLDMOUNT=/mnt/remote/infinidysk # InfiniDysk's mount, where the old links point
# The map from each .ids name to its release and file. Built once while InfiniDysk runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # InfiniDysk named a lone video after the release. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Os links do InfiniDysk apontam para o armazenamento `.ids`, e o zurg não tem isso. Então a função lê uma vez a árvore `completed-symlinks` do InfiniDysk para descobrir qual release e qual arquivo cada nome `.ids` representa. Mantenha o InfiniDysk rodando até o script terminar. Quando o InfiniDysk nomeou um vídeo avulso com o nome do release, a função pega o único vídeo que o zurg serve nesse release. Um release com mais de um vídeo nunca é chutado. Nesse caso ela imprime `NOT IN ZURG`.

**4. Aponte o Plex para as pastas raiz que você criou** — `__magic__/tv` e `__magic__/movies` — e somente para elas. Nunca para a raiz do `__magic__`, que também contém a biblioteca inteira em `__magic__/__all__`, e nunca para `__magic__` *e* uma pasta de filtro, ou cada episódio será encontrado duas vezes. Confirme que `autoEmptyTrash` está em `0`. Adicione a nova localização e faça um scan. Depois remova a antiga. Essa é o caminho da biblioteca do seu \*arr ou o mount do InfiniDysk, caso o Plex leia ele diretamente.

**5. Esvazie a lixeira** depois de conferir alguns itens por amostragem. O estado de exibição volta pelo match de GUID. Coleções e escolhas de artwork não voltam.

Deixe o InfiniDysk rodando até lá. Não custa nada e é seu plano de volta. Quando terminar, pare ele.

```bash
sudo systemctl stop infinidysk infinidysk-rclone-mount
```

## Depois {#afterwards}

Mantenha `{CONFIG_PATH}/blobs/` e o conjunto de NZBs recuperados até você ter feito streaming de uma amostra representativa.

Agora pense na aquisição. O zurg tem um [endpoint compatível com SABnzbd](../guides/sonarr-radarr.md) opcional que o Sonarr e o Radarr podem usar para baixar. Ele substitui o InfiniDysk como cliente de download deles. O grab cai em `__magic__/__all__` e a importação move o arquivo para fora por renomeação. Nada é copiado.

O zurg verifica cada grab antes de informar que ele terminou. Ele pergunta aos servidores de notícias sobre o início e o fim de cada arquivo. Também baixa o primeiro artigo de cada arquivo. São até sessenta e quatro deles, mais alguns a mais no caso de um release com poucos arquivos. Alguns servidores de notícias ainda dizem que um artigo existe depois que o conteúdo foi removido, e só um download mostra isso. Quando pode, o zurg reconstrói um release que perdeu artigos nos seus arquivos PAR2. Um release que ele não consegue reconstruir é informado como **Failed**. Aí o \*arr o coloca na blocklist e pega outro. A verificação é uma amostra e não o post inteiro. Um post que perdeu um trecho que a amostra não alcançou ainda aparece como Completed e falha na leitura que chega ao buraco.

Mantenha as root folders dos \*arrs dentro de `__magic__`. Uma root folder em qualquer outro lugar recebe uma cópia completa de cada importação. No Docker, dê ao \*arr um único volume que contenha todo o mount do zurg. Uma pasta de download e root folders em dois volumes também copiam cada importação. Veja [um volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
