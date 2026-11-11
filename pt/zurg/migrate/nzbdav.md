# Migrando do nzbdav para o zurg {#migrating-from-nzbdav-to-zurg}

Leia [a página compartilhada](index.md) primeiro. Ela explica o trash guard e por que sua biblioteca cai em `__magic__`.

O último release do nzbdav é o v0.6.4, de abril de 2026, e o repositório original não é mais mantido.
Esse release funciona. Esta migração serve para sair de um software sem manutenção. Não há necessidade de uma troca apressada.

**Esta é a mais fácil das cinco migrações.** Comparado ao zurg nos mesmos cinco releases, a árvore do nzbdav difere em exatamente duas coisas.

| | |
|---|---|
| o zurg ganha | o arquivo `.nfo` do release |
| o zurg perde | 5 volumes par2 com nome de hash dentro de releases ofuscados |

**Nada é renomeado.** Todo nome de arquivo que o nzbdav serve é um nome que o zurg serve com o mesmo nome e no mesmo formato de diretório. Isso vale também dentro de arquivos RAR. Os dois servidores concordaram em todos os 20 arquivos que não são par2 do corpus.

!!!warning Nunca percorra a raiz do WebDAV
O object store `.ids` do nzbdav materializa todos os 16 filhos hexadecimais em cada um dos seus cinco níveis, independentemente do conteúdo. Isso dá 16^5, ou cerca de 1.048.576 diretórios. Aponte `find`, `du`, `rclone` e qualquer scanner explicitamente para `/content`, `/nzbs` ou `/completed-symlinks`. Nunca para `/`.
!!!

## Como fica sua biblioteca depois {#what-your-library-looks-like-afterwards}

**Tudo é adicionado de novo** porque a raiz da biblioteca muda para `__magic__`.
Não existe um caminho mais barato nem um caminho parcial. Veja [a página compartilhada](index.md)
para entender o motivo.

A boa notícia é que a migração do nzbdav é a única em que **nada que você vê muda, exceto o prefixo**. Todo nome de arquivo que o zurg serve é o mesmo que o nzbdav servia.
Um \*arr que reimporta de `__magic__` faz o parse exatamente do que fazia antes.
Uma pasta que você organiza à mão continua com a mesma aparência de sempre.

Isso vale para qualquer configuração que você tenha. No Windows e em qualquer outro lugar onde o Plex lê o mount diretamente, os nomes de arquivo são idênticos. Se o Sonarr e o Radarr organizam uma biblioteca de symlinks, então os nomes de arquivo já eram deles e a origem que eles fazem o parse não muda. Ou seja, essa migração não altera nada em como sua biblioteca é lida. Ela só muda onde ela fica.

## O que aparece de conteúdo novo {#what-new-content-shows-up}

- O `.nfo` dentro de releases RAR.
- **Clipes de amostra** dentro de `Sample/`. O nzbdav publica o diretório e o clipe, e o zurg também. Isso *não* é novidade para você. O nzbdav é o único dos quatro servidores que já fazia isso.
- Pastas vazias para releases cuja cadeia de arquivos está quebrada. O nzbdav não criou nada para elas.
- Arquivos par2 e sfv deixam de ficar visíveis.

Nada disso gera um item no Plex, exceto o clipe de amostra, e o nzbdav já te dava isso. Se não estava incomodando antes, nada muda.

## Tire seus NZBs de lá {#get-your-nzbs-out}

zurg é alimentado por um diretório de arquivos `.nzb`, e o nzbdav ainda tem todos os seus em `/nzbs/<category>/`. **Copie-os. Não os mova.** Apagar algo de `/nzbs/` cancela o job.

```bash
mkdir -p ~/migration/nzbs
for cat in uncategorized movies tv audio software; do
  rclone copy "nzbdav:/nzbs/$cat" ~/migration/nzbs/ --include '*.nzb'
done
ls ~/migration/nzbs | wc -l
```

Os dois servidores nomeiam a pasta do release com o *nome do arquivo* NZB. Então os stems que você recuperou devem ser iguais às pastas que o nzbdav serve. Verifique isso e renomeie as que estiverem diferentes.

```bash
rclone lsf "nzbdav:/content/movies" --dirs-only | sed 's:/$::' | sort > ~/migration/folders-old.txt
ls ~/migration/nzbs | sed 's/\.nzb$//' | sort > ~/migration/stems.txt
diff ~/migration/folders-old.txt ~/migration/stems.txt
```

Duas regras de nomenclatura do zurg valem a pena conferir nessa lista.

- O zurg remove um `.mkv` ou `.mp4` do fim do nome de uma pasta. Se algum stem terminar assim, defina `retain_folder_name_extension: true`.
- Dois releases diferentes com o mesmo stem recebem o sufixo ` {shorthash}` em um deles. Encontre-os agora com `ls ~/migration/nzbs | sed 's/\.nzb$//' | sort |
  uniq -d`.

## Monte o zurg ao lado {#build-zurg-alongside}

nzbdav continua servindo o tempo todo. Copie o bloco de provider dele para a config do zurg.
Dê ao zurg o seu próprio ponto de montagem. Jogue os NZBs na pasta e deixe ele escanear. O diretório de monitoramento é verificado a cada 15 segundos, mais ou menos.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from nzbdav's provider settings
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp ~/migration/nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l     # should approach your release count
```

## Faça a troca {#cut-over}

**Um único caminho, não importa o que você tenha hoje.** Nada aqui move bytes.

**1. Ative o `__magic__`** e reinicie. As rotas são registradas na inicialização, então um toggle do dashboard precisa de um restart antes que o namespace responda.

```yaml
magic:
  enabled: true
```

**2. Crie as pastas raiz.** Elas vão na raiz de `__magic__`, ao lado do `__all__` que o zurg mantém ali. Não em `__magic__/__all__`, nem em `__magic__` em si, nem na raiz do mount. Os dois \*arrs disparam um health check para esses casos; as pastas irmãs não disparam nenhum dos dois.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` espelha a biblioteca, então todo release já está presente antes de você organizar qualquer coisa.

**3. Organize.** Um `mv` dentro de `__magic__` escreve uma linha e não move bytes.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Se o Sonarr e o Radarr organizaram sua biblioteca antiga, mova ela com um único script.** Ele renomeia cada arquivo que a biblioteca antiga linka para uma nova pasta raiz dentro de `__magic__`. Cada um cai no caminho que o \*arr já espera. Nada é copiado. Depois você troca a pasta raiz do \*arr sem deixar que ele mova nada. Os passos e o script estão na [página compartilhada](index.md#coming-off-a-symlink-library). Nunca deixe um \*arr mover os arquivos sozinho. Isso cruza a fronteira do mount. É uma cópia, e ela baixa toda a sua biblioteca de novo.

O script precisa de uma função `zurg_path` para os links do nzbdav. Salve isto como `zurg_path.sh` ao lado dele e defina `OLDMOUNT` com o local onde o nzbdav está montado.

```bash
OLDMOUNT=/mnt/nzbdav            # nzbdav's mount, where the old links point
# The map from each .ids name to its release and file. Built once while nzbdav runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # A file under another name. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Os links do nzbdav apontam para o store `.ids` dele, e o zurg não tem nada parecido. Então a função lê uma vez a árvore `completed-symlinks` do nzbdav para descobrir qual release e qual arquivo cada nome `.ids` representa. Mantenha o nzbdav rodando até o script terminar. O nzbdav não renomeia nada, então todo nome que ele encontra é um que o zurg serve.

**4. Aponte o Plex para as pastas raiz que você criou** — `__magic__/tv` e `__magic__/movies` — e só para elas. Nunca para a raiz de `__magic__`, que também contém a biblioteca inteira em `__magic__/__all__`, e nunca para `__magic__` *e* um diretório de filtro, senão cada episódio é encontrado duas vezes. Confirme que `autoEmptyTrash` está como `0`. Adicione a nova localização e faça o scan. Depois remova a antiga. Essa é o caminho da biblioteca do seu \*arr, ou o mount do nzbdav caso o Plex leia direto dele.

**5. Esvazie a lixeira** depois de conferir alguns itens por amostragem. O estado de assistido volta pelo match de GUID. Coleções e escolhas de arte não voltam.

Deixe o nzbdav rodando até lá. Ele não custa nada e é o seu rollback. Quando terminar, pare ele.

```bash
sudo systemctl stop nzbdav
```

## Depois {#afterwards}

Mantenha o diretório de configuração do nzbdav até você ter feito streaming de uma amostra representativa. Ele é a única outra cópia dos seus NZBs.

Agora pense na aquisição. O zurg tem um [endpoint compatível com SABnzbd, opcional](../guides/sonarr-radarr.md), que o Sonarr e o Radarr podem usar para fazer os downloads. Ele substitui o nzbdav como cliente de download deles. O download cai em `__magic__/__all__` e a importação o tira de lá por renomeação. Nada é copiado.

O zurg verifica cada download antes de informar que ele terminou. Ele pergunta aos servidores de notícias sobre o início e o fim de cada arquivo. Também baixa o primeiro artigo de cada arquivo. São até sessenta e quatro deles, mais alguns a mais em um release com só alguns arquivos. Alguns servidores de notícias ainda dizem que um artigo existe depois que o conteúdo foi removido, e só um download mostra isso. Onde pode, o zurg reconstrói um release com artigos ausentes usando seus arquivos PAR2. Um que ele não consegue reconstruir é reportado como **Failed**. Aí o \*arr o coloca na lista de bloqueio e pega outro. A verificação é uma amostra, e não o post inteiro. Um post que perdeu um trecho que a amostra não alcançou ainda aparece como Completed e falha na leitura que chega ao buraco.

Mantenha as pastas raiz dos \*arrs dentro de `__magic__`. Uma pasta raiz em qualquer outro lugar recebe uma cópia completa de cada importação. No Docker, dê ao \*arr um único volume que contenha todo o mount do zurg. Uma pasta de download e pastas raiz em dois volumes também copiam cada importação. Veja [um volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
