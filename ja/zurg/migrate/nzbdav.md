# nzbdavからzurgへの移行 {#migrating-from-nzbdav-to-zurg}

[共有ページ](index.md)を先に読んでください。trash guard の仕組みと、ライブラリが `__magic__` に入る理由が説明されています。

nzbdav-dev の最新リリースは2026年4月のv0.6.4で、upstreamのリポジトリはもうメンテナンスされていません。
そのリリースは問題なく動きます。この移行は、メンテナンスされていないソフトウェアから離れるためのものです。急いで切り替える必要はありません。

**これは5つの移行の中で最も簡単です。** 同じ5つのリリースでzurgと比べると、nzbdavのツリーの違いは次の2点だけです。

| | |
|---|---|
| zurg gains | リリースに含まれる `.nfo` ファイル |
| zurg loses | 難読化されたリリース内にあるハッシュ名のpar2ボリューム 5 個 |

**名前は変わりません。** nzbdavが配信するすべてのファイル名は、同じ名前・同じディレクトリ構成でzurgも配信します。RARアーカイブの中でも同じです。2つのサーバーは、コーパス内の非par2ファイル20個すべてで一致していました。

!!!warning WebDAV のルートを絶対にたどらないでください
nzbdav の `.ids` オブジェクトストアは、中身に関係なく5階層すべてで16個の16進数の子ディレクトリを実体化します。つまり 16^5、およそ 1,048,576 個のディレクトリになります。`find`、`du`、`rclone`、そのほかのスキャナーは、必ず `/content`、`/nzbs`、`/completed-symlinks` を明示的に指定してください。`/` は絶対に指定しないでください。
!!!

## 移行後のライブラリの見た目 {#what-your-library-looks-like-afterwards}

**すべて再度追加する必要があります**。ライブラリのルートが `__magic__` に移るためです。
近道も部分的な方法もありません。理由は[共有ページ](index.md)を参照してください。

良いニュースとして、nzbdav からの移行は**接頭辞以外に見た目が変わらない**唯一のケースです。zurg が提供するすべてのファイル名は、nzbdav が提供していたものと同じです。`__magic__` から再インポートする \*arr は、以前と同じものを解析します。手動で整理しているフォルダも、これまでと同じように見えます。

これはどの構成でも同じです。Windows やその他の環境で Plex がマウントを直接読む場合、ファイル名は同一です。Sonarr や Radarr がシンボリックリンクのライブラリを整理している場合も、ファイル名はもともとそれらが付けたものなので、解析されるソースは変わりません。つまり、この移行でライブラリの読み取り方が変わることはありません。変わるのは保存場所だけです。

## 新しいコンテンツはどう表示されるか {#what-new-content-shows-up}

・RAR リリース内の `.nfo`。
・`Sample/` 内の **サンプルクリップ**。nzbdav はディレクトリとクリップの両方を公開しますし、zurg も同様です。これは *新しい* 問題ではありません。4 つのサーバーの中で、nzbdav だけが以前からこれを公開していました。
・アーカイブチェーンが壊れているリリース用の空フォルダー。nzbdav はそれらについて何も作成していません。
・par2 と sfv が表示されなくなります。

このうち Plex のアイテムになるのはサンプルクリップだけで、それは nzbdav がすでに表示していたものです。以前から気になっていなかったのであれば、何も変わりません。

## NZBを取り出す {#get-your-nzbs-out}

```bash
mkdir -p ~/migration/nzbs
for cat in uncategorized movies tv audio software; do
  rclone copy "nzbdav:/nzbs/$cat" ~/migration/nzbs/ --include '*.nzb'
done
ls ~/migration/nzbs | wc -l
```

```bash
rclone lsf "nzbdav:/content/movies" --dirs-only | sed 's:/$::' | sort > ~/migration/folders-old.txt
ls ~/migration/nzbs | sed 's/\.nzb$//' | sort > ~/migration/stems.txt
diff ~/migration/folders-old.txt ~/migration/stems.txt
```

両方のサーバーは、リリースのフォルダー名を NZB の *ファイル名* に合わせて付けます。つまり、復元したステムは nzbdav が配信しているフォルダーと一致するはずです。それを確認して、ずれているものはリネームしてください。

zurg の命名ルールのうち、このリストと照らし合わせて確認しておきたいものが 2 つあります。

- zurg は、フォルダー名末尾の `.mkv` や `.mp4` を取り除きます。ステムがこれらで終わるものがあれば、`retain_folder_name_extension: true` を設定してください。
- 同じステムを持つ別々のリリースが 2 つあると、そのうちの 1 つに ` {shorthash}` のサフィックスが付きます。今すぐ `ls ~/migration/nzbs | sed 's/\.nzb$//' | sort |
  uniq -d` で見つけてください。

## zurgを並行して構築する {#build-zurg-alongside}

nzbdav は、その間ずっと配信を続けます。
nzbdav の provider ブロックを zurg の設定にコピーします。
zurg には専用のマウントポイントを用意します。
NZB を入れて、スキャンさせます。
watch ディレクトリは約15秒ごとに検出されます。

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

## 切り替える {#cut-over}

今お使いの環境が何であれ、手順は1つだけです。ここではバイトを一切移動しません。

**1. `__magic__` を有効にして**、再起動してください。ルートは起動時に登録されるため、ダッシュボードのトグルだけでは、再起動するまで名前空間が応答しません。

```yaml
magic:
  enabled: true
```

**2. ルートフォルダを作成します。** `__magic__` 直下、zurg がそこに置いている `__all__` の隣に作ってください。`__magic__/__all__` や `__magic__` 自体、マウントのルートではいけません。どちらの \*arr もそれらに対してヘルスチェックの警告を出します。並列のフォルダなら、どちらも警告を出しません。

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` はライブラリをミラーしているので、整理を始める前にすべてのリリースが揃っています。

**3. 整理します。** `__magic__` 内での `mv` は、行を1つ書き換えるだけで、バイトは移動しません。

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Sonarr と Radarr で古いライブラリを整理していた場合は、1つのスクリプトで移し替えられます。** 古いライブラリがリンクしているファイルすべてを、`__magic__` 配下の新しいルートフォルダへ名前を変えて移動します。各ファイルは、\*arr がすでに想定しているパスに配置されます。コピーは発生しません。そのあと、\*arr 側でルートフォルダを切り替えますが、その際に \*arr にファイルを移動させないでください。手順とスクリプトは [共通ページ](index.md#coming-off-a-symlink-library) にあります。\*arr にファイルを直接移動させるのは避けてください。マウント境界をまたぐため、コピーになってライブラリを丸ごとダウンロードしてしまいます。

このスクリプトには、nzbdav のリンク用の `zurg_path` 関数が必要です。これを `zurg_path.sh` という名前で、スクリプトと同じ場所に保存し、`OLDMOUNT` を nzbdav のマウント先に設定してください。

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

nzbdav のリンクは `.ids` ストアを指していますが、zurg にはそのようなものがありません。そこで関数は、nzbdav の `completed-symlinks` ツリーを一度読み込み、各 `.ids` の名前がどのリリースとどのファイルに対応するかを調べます。スクリプトが終わるまで nzbdav を動かしたままにしてください。nzbdav は名前を変更しないので、見つかった名前はすべて zurg が配信しているものです。

**4. Plex が、作成したルートフォルダを読むように設定します。** 対象は `__magic__/tv` と `__magic__/movies` だけです。`__magic__` のルートは指定しないでください。そこには `__magic__/__all__` を含むライブラリ全体があり、さらに `__magic__` と フィルタ用ディレクトリの両方を指定すると、すべてのエピソードが二重に見つかってしまいます。`autoEmptyTrash` が `0` であることを確認してください。新しいロケーションを追加してスキャンし、そのあと古いロケーションを削除します。古いロケーションとは、\*arr のライブラリパス、または Plex が直接読んでいた場合は nzbdav のマウントです。

**5. いくつかの項目を抜き取りで確認したら、ゴミ箱を空にします。** 視聴状況は GUID の照合で引き継がれます。コレクションとアートワークの選択は引き継がれません。

それまでは nzbdav を動かしたままにしてください。費用はかからず、ロールバックのための手段になります。作業がすべて終わったら停止してください。

```bash
sudo systemctl stop nzbdav
```

## 移行後 {#afterwards}

次の点を考えておきましょう。nzbdav の設定ディレクトリは、代表的なサンプルをストリーミング再生できるまで残しておいてください。それが NZB の唯一の別のコピーです。

次に取得について考えます。zurg には、オプトイン式の [SABnzbd 互換エンドポイント](../guides/sonarr-radarr.md) があり、Sonarr と Radarr はここ経由で grab できます。これは両者のダウンロードクライアントとして nzbdav を置き換えます。grab の結果は `__magic__/__all__` に入り、インポート時には名前変更によって移動されます。何もコピーされません。

zurg は、grab が完了と報告される前に各 grab を確認します。すべてのファイルの先頭と末尾についてニュースサーバーに問い合わせ、各ファイルの最初の記事もダウンロードします。記事数は最大 64 件で、ファイル数が少ないリリースではさらに数件ほど追加されます。ニュースサーバーによっては、記事の内容が削除された後も記事が存在すると答えることがあり、それはダウンロードしてみて初めて分かります。zurg は、欠けた記事を PAR2 ファイルから復元できる場合はリリースを再構築します。再構築できないものは **Failed** と報告されます。その後 \*arr はそれをブロックリストに登録し、別のものを grab します。

このチェックはサンプルであり、投稿全体を確認するものではありません。サンプルが届かなかった範囲で欠けている投稿は、それでも Completed と報告され、欠損部分に到達した読み込み時に失敗します。

\*arr のルートフォルダは `__magic__` の内側に置いてください。それ以外の場所にあるルートフォルダでは、インポートのたびに完全なコピーが作られます。Docker では、\*arr に zurg のマウント全体を含む 1 つのボリュームを割り当ててください。ダウンロードフォルダとルートフォルダが 2 つのボリュームに分かれていると、やはりインポートのたびにコピーされます。詳しくは [単一ボリューム](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) をご覧ください。
