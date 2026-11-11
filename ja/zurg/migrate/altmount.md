# AltMountからzurgへの移行 {#migrating-from-altmount-to-zurg}

まず[共有ページ](index.md)を読んでください。ゴミ箱ガードの仕組みと、ライブラリが `__magic__` に入る理由が説明されています。

AltMount は 5 つの中で最もすっきりしたツリーを提供します。リリースごとにファイルはちょうど 1 つだけです。サムネイルも広告も、サンプルも、残りかすもありません。そのため移行もかなり小さくなります。もめるような中身がほとんどないからです。

同じ 5 つのリリースを zurg と比べた結果です。

| | |
|---|---|
| zurg で増えるもの | サンプルクリップ、`.nfo`、`thumbnail.jpg`、`.url` の広告、アーカイブ内部のディレクトリ、**AltMount が拒否したリリースすべて** |
| zurg で失われるもの | なし |
| 名前が変わるもの | **アーカイブ (RAR) リリースのみ** |

!!!info 名前が変わるのはアーカイブ経路だけ
同じビルド `0614008b` で 3 回の独立した実行を行ったところ、単一ファイルのリリースは投稿者のファイル名をそのまま保持していました。NZB 名と内部名が異なるものや、完全に難読化されたものも含まれます。RAR から展開する必要があったリリースだけが `<NZB name>.mp4` になりました。

古い AltMount のビルドでは、これより多くの名前変更が行われていました。下のリストを信じる前に、ご自身のツリーを確認してください。「移行後にライブラリがどう見えるか」にあるコマンドを 1 つ実行すれば、数秒で分かります。
!!!

## より大きな問題は、AltMountが一度もインポートしなかったもの {#the-bigger-issue-is-what-altmount-never-imported}

AltMount は、4回の実行すべてで10話のシーズンパックを拒否しました。事前にニュースサーバー上でアーティクルが存在することは確認済みでした。

```
fast-fail segment check inconclusive: 93 segment(s) remained
unverified after 3 attempts: context deadline exceeded
```

このチェックは決定的ではありません。同じリリースで、未確認のセグメントが196件、次に93件、その次に76件と、実行ごとに結果が変わりました。また、サイズによる偏りもあります。`import.segment_sample_percentage: 1` を設定すると、セグメントの1%だけをサンプリングします。そのため、大きいリリースほど期限内に完了するためにより多くの STAT が必要になります。*より速い*ニュースホストに対して繰り返し試したところ、拒否される数はむしろ増えました。その実行では、シーズンパックと41 GBのremuxの両方を失いました。レイテンシーが原因ではありません。

あなたにとっての実際の影響は次のとおりです。**AltMount が黙って公開しなかったリリースこそ、zurg が追加するものです。** それらは今のところ Plex にアイテムがないため、何も保持されておらず、失うものもありません。ただ現れるだけです。ライブラリが NZB コレクションより小さい場合、理由はこれです。

移行中も AltMount でのインポートを続けたい場合は、`segment_sample_percentage` を下げるのが試す価値のある設定です。ここでは検証していません。

## 移行後のライブラリの見た目 {#what-your-library-looks-like-afterwards}

**ライブラリのルートが `__magic__` に移るため、すべて再度追加されます。** もっと安い方法がない理由は [共通ページ](index.md) に書いてあります。

途中で変わるのは小さなことです。単一ファイルの通常のリリースは、AltMount が付けたファイル名がそのまま残るので、ライブラリの大半は今までと同じに見えます。**アーカイブのリリースは投稿者の名前で戻ってきて**、1階層深い場所に置かれます。これは \*arr にとって間違いなく良い変化です。`father.brown.2013.s02e05.hdtv.x264-tla.mp4` という名前には、`FatherBrown.mp4` が捨ててしまった画質、ソース、グループの情報が入っています。

アーカイブのリリースを探すには、中に単一のファイルがあり、そのファイル名がフォルダ名と同じになっているマウントフォルダを探してください。

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

!!!info この変化が見えるかどうかは、お使いの環境によります
Plex がマウントを直接読んでいる場合、上に書いた名前の変化がそのままライブラリに表れます。これは Windows のすべての環境と、\*arr の symlink ファームを使っていない Linux や macOS の環境が対象です。

Sonarr と Radarr で symlink ライブラリを整理し、名前の変更をオンにしている場合は、**ファイル名はすでに \*arr が付けた名前になっています**。そのため、上に書いた名前は Plex には一切表れません。その場合、名前からわかるのは、\*arr が元の情報をどれだけ正しく解析できていたか、ということです。これは再インポートのときに重要になります。詳しくは [共通ページ](index.md) を見てください。
!!!

## 新しいコンテンツはどう表示されるか {#what-new-content-shows-up}

AltMount はこれらを公開していないため、共有ページのリストにある項目はすべてあなたにも当てはまります。

- **サンプル動画**（`Sample/` 内）。ここだけは設定しておく価値があります。9 MB のサンプルが 2 つ目のバージョンとして出てきてほしくない場合は、
  [`only_show_the_biggest_file: true`](../reference/config.md) を設定してください。
- `thumbnail.jpg`、`.nfo`、ポスターの `.url` 広告ファイル。どれも無害です。
- **AltMount が拒否したリリース全体**が、新しいライブラリ項目として届いてしまうもの。
- アーカイブの連鎖が途切れている場所にできる空のフォルダ。

## NZBを取り出す {#get-your-nzbs-out}

AltMount は、取り込んだ NZB をすべて自分で管理するようになります。元のファイルは移動され、圧縮したコピーが `<config>/.nzbs/<category>/<queueID>-<name>.nzbz` に保存されます。マウントフォルダと `.nzbz` の対応は、`<config>/metadata/complete/<Release>/` 以下の `.meta` ファイルに書かれています。これらはマジックが `AM3` のバイナリで、`.nzbz` のパスは平文の文字列として中に入っています。

zurg は、リリース名と同じ名前の `.nzb` を `nzbs/` 直下に 1 つずつ置いてほしい形式です。サブディレクトリは無視されます。`metadata/complete/<Release>` のディレクトリ名がそのままマウントフォルダ名なので、ファイルにもその名前を付ける必要があります。

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

計測した v0.3.2 のインストールでは、`.nzbz` は取り込んだ NZB の gzip コピーとして展開されました。ソースには、これらのファイル向けの zstd-protobuf のパスも入っているので、`zcat` と `grep` で確認するのは考えすぎではありません。それでも受け付けてもらえないものは、API 経由で取り出します。`GET /api/files/export-nzb?path=<virtual path>` を使うと、ストアから正確な NZB を再生成できます。`POST /api/files/export-batch` は ZIP を返します。どちらも API キーではなく JWT が必要です。

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

形式を推測せず、仮想パスは AltMount の UI のファイル表示か `/api/files/info` から取得してください。ダウンロードされるファイル名は `<queueID>-<name>.nzb` です。zurg がフォルダ名を正しく付けられるように、`<Release>.nzb` にリネームしてください。

確認のため、一つ見ておきましょう。復元した `.nzb` の数は、`metadata/complete/*/` のディレクトリ数と一致するはずです。

## zurgを並行して構築する {#build-zurg-alongside}

AltMount は途中でも配信を続けます。
zurg はポート 9999 で起動してください。
AltMount の 8585 とは競合しないので、問題ありません。

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

ここでは AltMount の時より **多くの** フォルダが表示されるはずです。これは refused-import クラスのものが入ってきているためです。

## 切り替える {#cut-over}

**1. `__magic__` を有効にする** と、サーバーを再起動します。ルートは起動時に登録されるため、ダッシュボードで切り替えただけでは、再起動するまで名前空間が応答しません。

```yaml
magic:
  enabled: true
```

**2. ルートフォルダーを作ります。** `__magic__` 直下に作ってください。zurg がそこに置いている `__all__` の隣です。`__magic__/__all__` の中でも、`__magic__` そのものでも、マウントのルートでもダメです。両方の \*arr は、それらの場所に対してヘルスチェックの警告を出します。隣に作ったフォルダーなら、どちらも警告を出しません。

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` はライブラリの鏡になっているので、整理を始める前に、すべてのリリースが揃っていることを確認できます。

**3. 整理します。** `__magic__` の中での `mv` は行を1つ書き換えるだけで、ファイルのデータは一切動きません。

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Sonarr と Radarr で古いライブラリを整理していた場合は、1つのスクリプトでまとめて移せます。** このスクリプトは、古いライブラリがリンクしている各ファイルを、`__magic__` 配下の新しいルートフォルダーへ名前を変えて移します。各ファイルは、\*arr が期待しているパスにそのまま置かれます。コピーはされません。その後、\*arr のルートフォルダーを切り替えますが、\*arr にファイルを動かさせないようにしてください。手順とスクリプトは [共通ページ](index.md#coming-off-a-symlink-library) にあります。\*arr に自分でファイルを移動させないでください。それはマウントの境界を越えるので、コピーになり、ライブラリを丸ごとダウンロードしてしまいます。

このスクリプトには、AltMount のリンク用の `zurg_path` 関数が必要です。これを `zurg_path.sh` という名前でスクリプトと同じ場所に保存し、`OLDMOUNT` に AltMount のマウント先を設定してください。

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

この関数は、各リンクのターゲットで、ファイルのすぐ上にあるリリースフォルダーを想定しています。AltMount のリンクが使う正確なパスは、このガイドでは確認していません。まず1つのリンクに対して `readlink` を実行してください。AltMount が単独の動画ファイルや展開済みアーカイブにリリース名を付けている場合、この関数は、そのリリースの中で zurg が配信している動画を1つ選びます。動画が複数あるリリースについては、推測は一切しません。その場合は `NOT IN ZURG` と表示されます。

**4. Plex が見る場所を、作ったルートフォルダーに向けてください。** `__magic__/tv` と `__magic__/movies` だけです。`__magic__` のルートは絶対に指定しないでください。そこには `__magic__/__all__` も含めてライブラリ全体があるため、重複します。また、`__magic__` とフィルターディレクトリを同時に指定しないでください。すべてのエピソードが2回見つかってしまいます。`autoEmptyTrash` が `0` であることを確認してください。新しい場所を追加してスキャンし、それから古い場所を削除します。古い場所とは、\*arr のライブラリパス、または Plex が直接読んでいた場合は AltMount のマウントです。

**5. 数件を抜き取りで確認したら、ゴミ箱を空にします。** 視聴状況は GUID マッチで戻ってきます。ただし、コレクションとアートワークの選択は戻りません。

それまでは AltMount を動かしたままにしてください。費用はかからず、切り戻し用の保険になります。作業が終わったら停止してください。

```bash
sudo systemctl stop altmount
```

## 移行後 {#afterwards}

代表的なサンプルからストリーミングできたことを確認するまで、AltMount は廃止しないでください。
その設定ディレクトリには `.nzbz` ストアがあり、これがお持ちの NZB のもう一つの唯一のコピーです。

次に取得について考えましょう。zurg には、オプトインの [SABnzbd 互換エンドポイント](../guides/sonarr-radarr.md) があります。Sonarr と Radarr はこれを通じて取得できます。これは AltMount の代わりに、両者のダウンロードクライアントとして使われます。zurg は、各取得を完了として報告する前に確認します。すべてのファイルについて、ニュースサーバーに開始と終了の部分があるかを問い合わせます。さらに、各ファイルの最初の記事もダウンロードします。ファイル数が少ないリリースでも、最大 64 件に加えて数件を確認します。ニュースサーバーによっては、コンテンツが削除された後も記事が存在すると答えることがあります。そのような場合は、実際にダウンロードしてみないとわかりません。zurg は、可能であれば PAR2 ファイルから記事が欠けたリリースを再構築します。再構築できないものは **Failed** と報告されます。すると \*arr はそれをブロックリストに入れ、別のものを取得します。この確認はサンプルであり、投稿全体を調べるわけではありません。サンプルが及ばなかった範囲が欠けている投稿は、引き続き Completed と報告されます。そして、その欠けた部分に到達する読み取りの時点で失敗します。

\*arr のルートフォルダは `__magic__` の中に置いてください。それ以外の場所をルートフォルダにすると、インポートのたびにファイルの完全なコピーが作られてしまいます。Docker では、\*arr に zurg のマウント全体を含む 1 つのボリュームを割り当ててください。ダウンロードフォルダとルートフォルダを 2 つのボリュームに分けると、インポートのたびに同様にコピーが発生します。
詳しくは [1つのボリューム](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) を参照してください。
