# Migrando do AltMount para o zurg {#migrating-from-altmount-to-zurg}

Leia [a página compartilhada](index.md) primeiro. Ela explica o trash guard e por que sua biblioteca acaba em `__magic__`.

O AltMount entrega a árvore mais limpa dos cinco. Exatamente um arquivo por release. Nada de miniaturas, nada de anúncios, nada de amostra e nada de sobras. A migração é proporcionalmente pequena porque há muito pouco ali para dar problema.

Medido contra o zurg nos mesmos cinco releases.

| | |
|---|---|
| o zurg ganha | o clipe de amostra, o `.nfo`, o `thumbnail.jpg`, os anúncios `.url`, o diretório interno do arquivo, **e todo release que o AltMount recusou** |
| o zurg perde | nada |
| renomeado | **somente releases em arquivo (RAR)** |

!!!info Só o caminho do arquivo renomeia
Em três execuções independentes na build `0614008b`, os releases de arquivo único simples mantiveram o nome de arquivo do poster. Isso inclui um cujo nome interno é diferente do nome do NZB e um totalmente ofuscado. Só o release que precisou ser descompactado de um RAR saiu como `<NZB name>.mp4`.

As builds mais antigas do AltMount renomeavam mais do que isso. Confira a sua própria árvore antes de confiar na lista abaixo. O único comando em "What your library looks like afterwards" te diz isso em segundos.
!!!

## O problema maior é o que o AltMount nunca importou {#the-bigger-issue-is-what-altmount-never-imported}

AltMount recusou um pack de temporada de 10 episódios em todas as quatro tentativas. Os artigos foram verificados como presentes no news server antes.

```
fast-fail segment check inconclusive: 93 segment(s) remained
unverified after 3 attempts: context deadline exceeded
```

A verificação não é determinística. A mesma release voltou com 196 segmentos não verificados, depois 93 e depois 76. Ela também tem viés de tamanho. Definir `import.segment_sample_percentage: 1` amostra 1% dos segmentos, então uma release maior precisa de mais STATs para cair dentro do prazo. Repetindo contra um news host *mais rápido*, ele recusou mais, não menos. Essa rodada perdeu tanto o pack de temporada quanto um remux de 41 GB. Latência não é a explicação.

Na prática, para você, a consequência é esta. **As releases que o AltMount simplesmente nunca publicou são as que o zurg vai adicionar.** Elas não têm item no Plex hoje, então nada está preservado e nada está em risco. Elas simplesmente aparecem. Se sua biblioteca é menor que sua coleção de NZBs, é por isso.

Se você quiser manter o AltMount importando durante a migração, baixar `segment_sample_percentage` é o ajuste para testar. Isso não foi testado aqui.

## Como fica sua biblioteca depois {#what-your-library-looks-like-afterwards}

**Tudo é adicionado de novo** porque a raiz da biblioteca passa a ser `__magic__`. Veja [a página compartilhada](index.md) para entender por que não existe um caminho mais barato.

O que muda no caminho é pouca coisa. Lançamentos de arquivo único simples mantêm o nome de arquivo que o AltMount deu a eles, então a maior parte da biblioteca continua com a mesma aparência. **Lançamentos em arquivo compactado voltam com o nome do postador** e uma pasta mais fundo. Isso é estritamente melhor para um \*arr. O nome `father.brown.2013.s02e05.hdtv.x264-tla.mp4` traz a qualidade, a fonte e o grupo que `FatherBrown.mp4` descartava.

Para achar os lançamentos em arquivo compactado, procure uma pasta de montagem cujo único arquivo tenha o nome da pasta.

```bash
AM=/mnt/altmount
for d in "$AM"/*/; do
  r=$(basename "$d")
  for f in "$d"*; do
    b=$(basename "$f")
    [ "${b%.*}" = "$r" ] && echo "RENAMED BY ALTMOUNT: $f"
  done
done
```

!!!info Se você vai ver algo disso depende da sua configuração
Se o Plex lê a montagem diretamente, então os nomes acima são o que muda na sua biblioteca. Isso vale para todas as configurações no Windows e para qualquer configuração no Linux ou macOS sem uma fazenda de links simbólicos do \*arr.

Se o Sonarr e o Radarr organizam uma biblioteca de links simbólicos com renomeação ativada, então **seus nomes de arquivo já são os deles** e nenhum dos nomes acima aparece no Plex. O que os nomes mostram, nesse caso, é a qualidade da análise que o \*arr estava usando. Isso importa na hora de reimportar. Veja [a página compartilhada](index.md).
!!!

## O que aparece de conteúdo novo {#what-new-content-shows-up}

AltMount não publica nada disso, então tudo o que está na lista da página compartilhada se aplica a você.

- **Clipes de amostra** dentro de `Sample/`. Esse é o único que vale a pena configurar. Defina [`only_show_the_biggest_file: true`](../reference/config.md) se você não quiser que uma amostra de 9 MB apareça como segunda versão.
- `thumbnail.jpg`, o `.nfo` e os arquivos `.url` de anúncio do pôster. Todos inofensivos.
- **Releases inteiras que o AltMount recusou** aparecendo como novos itens da biblioteca.
- Pastas vazias onde uma cadeia de arquivos está quebrada.

## Tire seus NZBs de lá {#get-your-nzbs-out}

O AltMount assumiu a posse de cada NZB que você enviou para ele. O original foi movido para outro lugar, e uma cópia compactada ficou guardada em
`<config>/.nzbs/<category>/<queueID>-<name>.nzbz`. A ligação entre a pasta do mount e o `.nzbz` está nos arquivos `.meta` dentro de `<config>/metadata/complete/<Release>/`. Eles são binários com a assinatura `AM3`, e o caminho do `.nzbz` aparece dentro deles como uma string simples.

O zurg quer um `.nzb` por release, com o nome do release e direto na pasta `nzbs/`. Subdiretórios são ignorados. O nome da pasta `metadata/complete/<Release>` *é* o nome da pasta do mount, e é exatamente esse nome que o arquivo deve receber.

```bash
AM=/path/to/altmount/config          # holds altmount.db, .nzbs/, metadata/
OUT=./recovered-nzbs
mkdir -p "$OUT"
for dir in "$AM"/metadata/complete/*/; do
  release=$(basename "$dir")
  meta=$(find "$dir" -maxdepth 1 -name '*.meta' | head -1)
  [ -n "$meta" ] || { echo "NO META: $release" >&2; continue; }
  nzbz=$(strings "$meta" | grep -m1 '\.nzbz$')
  case "$nzbz" in "") echo "NO NZBZ REF: $release" >&2; continue ;;
                  /*) src=$nzbz ;; *) src="$AM/$nzbz" ;; esac
  [ -f "$src" ] || { echo "NZBZ MISSING: $release" >&2; continue; }
  [ -e "$OUT/$release.nzb" ] && { echo "NAME COLLISION: $release" >&2; continue; }
  if zcat "$src" > "$OUT/$release.nzb" 2>/dev/null && grep -q '<nzb' "$OUT/$release.nzb"; then
    echo "OK: $release"
  else
    rm -f "$OUT/$release.nzb"
    echo "NOT A GZIPPED NZB: $release. Use the API export instead" >&2
  fi
done
```

Na instalação v0.3.2 que eu medi, o `.nzbz` era uma cópia em gzip do NZB importado. O código-fonte também tem um caminho com zstd-protobuf para esses arquivos, então a verificação com `zcat` e `grep` não é paranoia. O que for rejeitado passa pela API. `GET /api/files/export-nzb?path=<virtual path>` gera de novo um NZB fiel a partir do armazenamento, e `POST /api/files/export-batch` retorna um ZIP. Os dois exigem um JWT, e não a chave de API.

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

Pegue os caminhos virtuais na visualização de arquivos da UI do AltMount ou em `/api/files/info`, em vez de tentar adivinhar o formato. O download sai com o nome `<queueID>-<name>.nzb`. Renomeie para `<Release>.nzb` para que o zurg nomeie a pasta corretamente.

Uma checagem rápida: a quantidade de arquivos `.nzb` recuperados deve ser igual à quantidade de diretórios em `metadata/complete/*/`.

## Monte o zurg ao lado {#build-zurg-alongside}

AltMount continua servindo durante todo o processo. Rode o zurg na porta 9999. Não há conflito
com a porta 8585 do AltMount.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy host/port/TLS/credentials from AltMount
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
mkdir -p nzbs && cp recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l
```

Espere **mais** pastas aqui do que o AltMount tinha. Isso é a classe de importações recusadas chegando.

## Faça a troca {#cut-over}

**Um único caminho, seja qual for o seu setup atual. Nada aqui move bytes.**

**1. Ative o `__magic__`** e reinicie. As rotas são registradas na inicialização, então a opção do painel precisa de um reinício antes que o namespace responda.

```yaml
magic:
  enabled: true
```

**2. Crie as pastas raiz.** Elas ficam na raiz de `__magic__`, ao lado da `__all__` que o zurg mantém ali. Não em `__magic__/__all__`, nem no próprio `__magic__` e nem na raiz do mount. Os dois \*arrs geram uma verificação de saúde para esses casos; pastas no mesmo nível não disparam nenhum dos dois problemas.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` espelha a biblioteca, então todo lançamento já está presente antes de você organizar qualquer coisa.

**3. Organize.** Um `mv` dentro de `__magic__` grava uma linha e não move bytes.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Se o Sonarr e o Radarr organizaram sua biblioteca antiga, mova-a com um único script.** Ele renomeia cada arquivo para o qual a biblioteca antiga aponta, colocando-o em uma nova pasta raiz dentro de `__magic__`. Cada um cai no caminho que o \*arr já espera. Nada é copiado. Depois você troca a pasta raiz do \*arr sem deixar que ele mova nada. Os passos e o script estão [na página compartilhada](index.md#coming-off-a-symlink-library). Nunca deixe um \*arr mover os arquivos sozinho. Isso cruza a fronteira do mount. Vira uma cópia e baixa toda a sua biblioteca de novo.

O script precisa de uma função `zurg_path` para os links do AltMount. Salve isto como `zurg_path.sh` ao lado dele e defina `OLDMOUNT` com o caminho onde o AltMount está montado.

```bash
OLDMOUNT=/mnt/altmount          # AltMount's mount, where the old links point
zurg_path() {
  case "$1" in "$OLDMOUNT"/*) ;; *) return ;; esac   # not a link into AltMount
  local name=${1##*/} f videos
  local release; release=$(basename "$(dirname "$1")")
  [ -f "$ZURG/__all__/$release/$name" ] && { echo "$ZURG/__all__/$release/$name"; return; }
  # AltMount named a lone video or an unpacked archive after the release. Take its one video.
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

A função espera que a pasta do lançamento fique logo acima do arquivo no destino de cada link. O caminho exato que os links do AltMount usam não foi verificado para este guia. Antes de tudo, rode `readlink` em um link. Quando o AltMount nomeou um vídeo solto ou um arquivo descompactado com o nome do lançamento, a função pega o único vídeo que o zurg serve nesse lançamento. Um lançamento com mais de um vídeo nunca é adivinhado. Nesse caso ela imprime `NOT IN ZURG`.

**4. Aponte o Plex para as pastas raiz que você criou** — `__magic__/tv` e `__magic__/movies` — e só para elas. Nunca para a raiz de `__magic__`, que também tem a biblioteca inteira em `__magic__/__all__`, e nunca para `__magic__` *e* uma pasta de filtro ao mesmo tempo, senão cada episódio é encontrado duas vezes. Confirme que `autoEmptyTrash` está em `0`. Adicione o novo local e faça a varredura. Depois remova o antigo. Esse é o caminho da biblioteca do seu \*arr, ou o mount do AltMount se o Plex lia direto dele.

**5. Esvazie a lixeira** depois de conferir por amostragem alguns itens. O estado de assistido volta pelo match de GUID. Coleções e escolhas de arte não voltam.

Deixe o AltMount rodando até lá. Ele não custa nada e é o seu rollback. Quando terminar, pare-o.

```bash
sudo systemctl stop altmount
```

## Depois {#afterwards}

Não desative o AltMount até ter feito streaming de uma amostra representativa. O diretório de configuração dele guarda o armazenamento `.nzbz`, e essa é a única outra cópia dos seus NZBs.

Agora pense na aquisição. O zurg tem um endpoint compatível com SABnzbd, opcional, pelo qual o Sonarr e o Radarr podem fazer os downloads ([guia](../guides/sonarr-radarr.md)). Ele substitui o AltMount como cliente de download deles. O zurg verifica cada grab antes de informar que ele terminou. Ele pergunta aos servidores de notícias sobre o início e o fim de cada arquivo. Também baixa o primeiro artigo de cada arquivo. São até sessenta e quatro deles, mais alguns a mais em um release com só alguns arquivos. Alguns servidores de notícias ainda dizem que um artigo existe depois que o conteúdo foi removido, e só um download mostra isso. O zurg reconstrói um release com artigos faltando nos arquivos PAR2 sempre que consegue. Um que ele não consegue reconstruir é reportado como **Failed**. Aí o \*arr o coloca na blocklist e pega outro. A verificação é uma amostra e não o post inteiro. Um post que perdeu um trecho que a amostra não alcançou ainda é reportado como Completed e falha na leitura que chega à lacuna. Mantenha as root folders dos \*arrs dentro de `__magic__`. Uma root folder em qualquer outro lugar recebe uma cópia completa de cada importação. No Docker, dê ao \*arr um único volume que contenha todo o mount do zurg. Uma pasta de download e root folders em dois volumes também copiam cada importação. Veja [um volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
