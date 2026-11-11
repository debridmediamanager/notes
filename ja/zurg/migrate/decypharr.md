# decypharrからzurgへの移行 {#migrating-from-decypharr-to-zurg}

[共有ページ](index.md)を先に読んでください。トラッシュガードの仕組みと、ライブラリが `__magic__` に入る理由を説明しています。

decypharr と zurg は同じ問題を解決するもので、ルートのレイアウトもよく似ています。設定の多くはそのまま引き継げます。

| decypharr | zurg |
|---|---|
| `__all__/<job>/<file>` | `__all__/<name>/<file>` |
| `version.txt` | `version.txt` |
| `__bad__/` | `__unplayable__/` |
| `torrents/` | `not_provider: nzb` を指定した `directories:` のエントリ |
| `nzbs/<job>/` | `provider: nzb` を指定した `directories:` のエントリ、または組み込みの `__nzb__` |

**デビッドリンク側は何もする必要がありません。** どちらのサーバーも同じアカウントを一覧表示し、トレントのファイル名をそのまま見せます。zurg を decypharr のマウントポイントに置けば、そのパスは同じになります。以下は、すべて Usenet 側の話です。

始める前に決めておくことが二つあります。

- **プロバイダー。** プロバイダーは移行の妨げになりません。zurg は decypharr が対応しているすべてのサービス用のバックエンドを持っています。Premiumize と Debrid-Link のアカウントも、他と同じように移行できます。それぞれ [プロバイダー](../providers/index.md) の下にページがあります。
- **移行前に decypharr の `folder_naming` を変更しないでください。** これを変更すると、ライブラリ内のすべてのフォルダーが一度にリネームされます。その結果、すべてのシンボリックリンクの参照先と、マウント直接の Plex パスが一気に壊れてしまいます。

## Usenet側の違い {#what-differs-on-the-usenet-side}

| | |
|---|---|
| zurg が追加するもの | `thumbnail.jpg`、サンプル動画、`.nfo`、`.url` の広告ファイル、アーカイブ内のディレクトリ、**そして decypharr が落としていた難読化されたリリース** |
| zurg が失うもの | なし |
| 名前が変わるもの | 単一ファイルのリリースとアーカイブのリリース |

**単一ファイルのリリース**は、decypharr では作業名で出力されます。decypharr では `ToyStory5/ToyStory5.mkv` になりますが、zurg では投稿者の名前がそのまま残り、`ToyStory5/Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv` として配信されます。

**アーカイブのリリース**は興味深いケースで、理解しておく価値があります。2つの症状をまとめて説明してくれるからです。decypharr は次のようなものを出力します。

```
FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLAfather.brown.2013.s02e05.hdtv.x264-tla.mp4
```

これはアーカイブ内のディレクトリ名とファイル名が、**区切り文字なしで**連結されたものです。`/` が抜けてしまったパス結合の問題です。つまり、欠けているディレクトリ階層と壊れたファイル名は、2つの別々の不具合ではなく、同じ1つの不具合です。zurg では本来の構造を次の場所に再現します：
`FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown.….mp4`

**複数ファイルのリリースとシーズンパック**は、両方の側で本来のファイル名がそのまま残ります。フォルダ名が一致すれば、自動的にマッチします。

## 移行後のライブラリの見た目 {#what-your-library-looks-like-afterwards}

**ライブラリのルートが `__magic__` に移るので、すべて再追加されます。** なぜこれより安い方法がないのかは、[共有ページ](index.md)を見てください。

得られるのは名前の部分です。単一ペイロードのリリースはすべて、ジョブ名ではなく投稿者のファイル名で戻ってきます。たとえば `ToyStory5/ToyStory5.mkv` は `Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv` になります。Sonarr、Radarr、Plex は、この文字列から画質、ソース、グループ、エディションを読み取ります。アーカイブのリリースは、くっついた名前を持たなくなり、アーカイブ自身のディレクトリに入ります。複数ファイルのリリースとシーズンパックは、もともと正しく読めていたので変わりません。

名前が変わるリリースは次のとおりです。

```bash
MOUNT=/mnt/decypharr
for d in "$MOUNT"/__all__/*/; do
  job=$(basename "$d")
  n=$(find "$d" -type f | wc -l)
  [ "$n" -eq 1 ] && echo "RENAMED BY DECYPHARR: $job"
done
```

!!!info これが見えるかどうかは、お使いの環境次第です
Plex がマウントを直接読んでいる場合、上の名前が実際にライブラリで変わります。これはすべての Windows 環境と、\*arr のシンボリックリンク群を使っていない Linux や macOS 環境に当てはまります。

Sonarr と Radarr がシンボリックリンクのライブラリを作り、リネーム機能をオンにしている場合は、**ファイル名はすでに \*arr 側のものになっています**。そのため、上の名前は Plex にまったく出てきません。その場合、名前からわかるのは、\*arr が元にしていたパースがどれだけ良かったかです。これは再インポートのときに重要になります。[共有ページ](index.md)を見てください。
!!!

## 新しいコンテンツはどう表示されるか {#what-new-content-shows-up}

- **サンプル動画**は `Sample/` 内にあります。設定する価値があるのはこれです。9 MB のサンプルが2つ目のバージョンとして表示されてしまうのが嫌なら、[`only_show_the_biggest_file: true`](../reference/config.md) を設定してください。
- `thumbnail.jpg`、`.nfo`、そしてポスターの `.url` 広告ファイルです。どれも何の影響もありません。
- decypharr が取りこぼした**難読化されたリリース**が、新しいライブラリ項目として届くことがあります。ハッシュ名だけのポストについては、decypharr は何も公開していませんでした。zurg が実際のリリース名を解決して配信します。
- アーカイブの連鎖が途切れている箇所に残る空のフォルダです。

## NZBを取り戻す {#get-your-nzbs-back}

**decypharrではこれらを取り出せません。** 各ジョブごとに圧縮されたバイナリを `usenet/meta/<uuid>.meta` に保存しています。ベンチで確認したところ、`usenet/nzbs/` ディレクトリは空でした。文書化されたエクスポート機能もありません。`.meta` ファイルをNZBに戻せるかどうかは未確認です。元のデータは復元できないものとして扱ってください。

手元にあるのはジョブ名です。両方のサーバーでは、ジョブフォルダ名がそのままNZBのファイル名になっています。つまり、フォルダの一覧が買い物リストになります。

```bash
MOUNT=/mnt/decypharr
ls "$MOUNT/nzbs" > nzb-jobs.txt      # the usenet jobs
wc -l nzb-jobs.txt
```

各ジョブについて、フォルダ名で検索してインデクサーからNZBを再取得してください。そのあと、zurgの `nzbs/` ディレクトリに入れる前に、**ファイル名をフォルダ名そのまま＋`.nzb`にリネームしてください**。ファイル名はフォルダ名と同じにしてください。フォルダ名がパスを安定させる役割を担っているからです。

作業中は次の2つのルールを守ってください。

- **すでにデブリッドアカウントが保有しているリリースは飛ばしてください。** シンボリックリンクはtorrentのコピーを通じて解決されます。NZBも追加すると、zurgは同じ名前で異なる2つのリリースを認識し、そのうちの1つに `Some.Release {a1b2c3}` のようなハッシュ付きの接尾辞を付けてしまいます。そうなると、元の名前を参照していたものが動かなくなります。
- インデクサーがもう扱っていないリリースは、単純に失われたものとなります。`autoEmptyTrash` が `0` の場合、Plexのアイテムは削除すると決めるまでゴミ箱に残ります。

## zurgを並行して構築する {#build-zurg-alongside}

zurg を decypharr と並べて、専用のマウントポイントで実行してください。一覧表示は読み取り専用なので、両方が同じ debrid アカウントを同時に一覧表示しても問題ありません。

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

次に進む前に、debrid 側の内容が揃っているか確認してください。

```bash
ls /mnt/decypharr/__all__      | sort > decypharr-jobs.txt
ls /mnt/zurg-staging/__all__   | sort > zurg-jobs.txt
diff decypharr-jobs.txt zurg-jobs.txt
```

ときどき、torrent フォルダーの名前が *体系的に* 食い違うことがあります。拡張子が付いていたり、付いていなかったりします。元の名前ではなく RD 側の名前で表示される場合もあります。そのときは、手で直すのではなく、`retain_rd_torrent_name` か `retain_folder_name_extension` を切り替えてから再スキャンしてください。decypharr 側にしかないフォルダーは Usenet のジョブです。Premiumize と Debrid-Link のフォルダー名は decypharr 側と比較していません。それらのアカウントのフォルダーも、ここで確認してください。

## 切り替える {#cut-over}

今の環境がどうであれ、やることは一つだけです。ここではバイトは一切移動しません。

**1. `__magic__` を有効にして**、再起動します。ルートは起動時に登録されるため、ダッシュボードのトグルだけでは、再起動するまで名前空間が応答しません。

```yaml
magic:
  enabled: true
```

**2. ルートフォルダーを作成します。** `__magic__` の直下に、zurg が置いている `__all__` と並べて作ります。`__magic__/__all__` の中でも、`__magic__` そのものでも、マウントのルートでもありません。両方の \*arr は、それらの場所に対してヘルスチェックの警告を出します。並列に置いたフォルダーは、どちらの警告も出しません。

Docker を使っている場合、\*arr は `__all__` とこれらのルートフォルダーに、1 つのボリュームを通してアクセスできる必要があります。decypharr の構成では、ダウンロード用フォルダーとメディア用フォルダーを別々にバインドすることがよくあります。ボリュームを 2 つにすると、インポートのたびにファイルの完全コピーが発生します。代わりに、zurg のマウントの親ディレクトリを一度だけバインドしてください。やり方は[手順ガイド](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)に載っています。

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` はライブラリを反映しているので、整理する前からすべてのリリースがそろっています。

**3. 整理します。** `__magic__` の中での `mv` は、データベースに行を書き込むだけで、バイトは一切移動しません。

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Sonarr と Radarr で古いライブラリを整理していた場合は、1 つのスクリプトで移行してください。** このスクリプトは、古いライブラリがリンクしているファイルすべてを、`__magic__` 配下の新しいルートフォルダーへ名前を変えて移動します。各ファイルは、\*arr がすでに期待しているパスに配置されます。コピーは発生しません。その後、\*arr がファイルを動かさないようにしたまま、\*arr のルートフォルダーを切り替えます。手順とスクリプトは[共通ページ](index.md#coming-off-a-symlink-library)にあります。\*arr に自分でファイルを移動させることは、絶対にしないでください。マウントの境界をまたぐため、コピーになってしまい、ライブラリ全体をダウンロードしてしまいます。

このスクリプトには、decypharr のリンク用の `zurg_path` 関数が必要です。これを `zurg_path.sh` という名前でスクリプトと同じ場所に保存し、`OLDMOUNT` には decypharr をマウントしている場所を設定してください。

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

debrid のリリースや、複数ファイルからなる NZB リリースへのリンクは、両方のサーバーで同じファイルを指しています。decypharr は NZB リリースを 2 種類の方法でリネームしていました。1 本だけの動画はジョブ名で呼び、アーカイブのフォルダーとファイルは 1 つの名前に結合していました。この関数は、その両方について zurg 側のコピーを見つけます。動画が 2 本以上あるジョブは推測せず、代わりに `NOT IN ZURG` と表示します。

**4. Plex は作成したルートフォルダーだけを指定します** — `__magic__/tv` と `__magic__/movies` です。`__magic__` のルートは指定しないでください。ライブラリ全体が `__magic__/__all__` にもあるため、そこを指定すると重複します。また、`__magic__` とフィルター用ディレクトリを*両方*指定しないでください。すべてのエピソードが 2 回ずつ見つかってしまいます。`autoEmptyTrash` が `0` であることを確認します。新しい場所を追加してスキャンします。その後、古い場所を削除します。古い場所とは、\*arr のライブラリパス、または Plex が直接読んでいた場合は decypharr のマウントです。

**5. ゴミ箱を空にします**。いくつかのアイテムを抜き取りで確認したら実行してください。視聴状態は GUID の照合で戻ります。コレクションやアートワークの選択は戻りません。

それまでは decypharr を動かしたままにしておいてください。動かしておいても費用はかからず、これが元に戻すための手段になります。設定ファイルや `db/`、`usenet/` の状態も削除しないでください。すべて終わったら停止してください。

```bash
sudo systemctl stop decypharr
```

## 移行後 {#afterwards}

**自動化も両方そのまま引き継がれます。** zurg には、オプトインで有効にできる [SABnzbd 互換エンドポイント](../guides/sonarr-radarr.md) があり、Sonarr と Radarr から NZB を渡せます。また、オプトインの [qBittorrent 互換エンドポイント](../guides/sonarr-radarr-torrents.md) もあり、デブリッドアカウント用のマグネットリンクや `.torrent` を渡せます。どちらも名前変更によって `__magic__/__all__` からインポートされます。選択肢は次のとおりです。

- **NZB。** `sabnzbd.enabled` をオンにして、\*arr の接続先を zurg に向けます。zurg は、取得したものを完了と報告する前に確認します。各ファイルの先頭と末尾について、ニュースサーバーに問い合わせます。さらに、各ファイルの最初の記事もダウンロードします。ファイル数が多いリリースでは最大 64 件、ファイルが少ないリリースでもさらに数件を確認します。一部のニュースサーバーは、内容が削除された後でも記事が存在すると応答することがあり、実際にダウンロードしてみないと分からない場合があります。zurg は、記事が欠けた PAR2 ファイルから、可能な場合はリリースを再構築します。再構築できないものは **Failed** と報告されます。すると \*arr はそれをブロックリストに入れて、別のものを取得します。このチェックはサンプルであり、投稿全体を確認するわけではありません。サンプルが届かなかった範囲で欠落があった投稿は、Completed と報告されます。そして、そのギャップに到達した読み取りで失敗します。
- **Torrent。** `qbittorrent.enabled` をオンにして、2 つ目のダウンロードクライアントとして追加します。プライベートトラッカーのリリースも、インデクサーが素のマグネットリンクではなく `.torrent` ファイルを渡す場合は動作します。このファイルを使うと、アカウントのキャッシュ照会をハッシュで直接行えるためです。
- **単発の追加。** zurg のダッシュボードには追加ボタンがありません。qBittorrent エンドポイントから、ある \*arr のカテゴリーを指定してマグネットリンクや `.torrent` を追加すると、そのリリースはその \*arr に送られます。方法は[手動でリリースを追加する](../guides/sonarr-radarr-torrents.md#11-adding-a-release-by-hand)を参照してください。DMM 経由で追加したマグネットリンクや、`nzbs/` に入れた NZB は、どちらも zurg の一覧に表示されます。ただし、それだけでは Sonarr や Radarr には届きません。zurg 独自の[取得機能](../guides/acquisition.md)も、リクエストを自動で取得します。リクエストは Plex のウォッチリストや、Seerr、\*arr から届きます。アカウントにキャッシュ済みであれば、Newznab インデクサーから NZB を、Torznab インデクサーから torrent を取得します。
- **ハイブリッド。** decypharr は \*arr のダウンロードクライアントとしてのみ使い、同じデブリッドアカウントにリリースを送り込みます。zurg はマウントを提供します。両方が同じアカウントを一覧表示するので、zurg は decypharr が追加したものを拾えます。この場合、\*arr のインポート手順では、zurg のツリーへのリモートパスマッピングが必要です。そのツリーとルートフォルダーは、同じボリューム内になければなりません。まず 1 件だけ取得して、動作を確かめてください。
