# InfiniDysk から zurg への移行 {#migrating-from-infinidysk-to-zurg}

[共有ページ](index.md)を先に読んでください。トラッシュガードと、ライブラリが `__magic__` に入る理由が説明されています。

同じ 5 つのリリースを使って zurg と比較しました。

| | |
|---|---|
| zurg で増えるもの | サンプル動画、`.nfo` |
| zurg で失われるもの | 難読化されたリリース内にあるハッシュ名の par2 ボリューム 5 個 |
| リネーム | **マルチファイル以外のすべてのリリース** |

!!!warning 移行で一番大きいのはリネームです
InfiniDysk は、リリースが単一のペイロードに解決されると、そのメディアファイルを NZB のファイル名にリネームします。2026-09-01 の参照用コーパスでは、5 つのうち 4 つが `ToyStory5.mkv`、`Obfuscated.mkv`、`FatherBrown.mp4`、`MandaloriaREMUX.mkv` になりました。残ったのは 10 話のシーズンパックだけで、こちらはエピソード名がそのまま残りました。
リネームはどの階層にも適用されます。`FatherBrown.mp4` は、保持されている `Father.Brown.2013.S02E05.HDTV.x264-TLA/` ディレクトリの *内側* にあります。

zurg は投稿者のファイル名をそのまま残します。そのため、リリース名が元に戻り、単一ペイロードのリリースはすべてパスが変わります。このリリース名は、Plex や \*arrs が画質、グループ、エピソードを解析するときに使う文字列です。
!!!

もう 1 つの違いは小さいですが、初めて見ると混乱しやすい点です。InfiniDysk はアーカイブの `Sample/` ディレクトリを作成しますが、中身は**空**のままです。zurg はその中にサンプル動画を入れます。

移行する理由は内容ではありません。ビルド `cd9b1205` では、シーズンパックを含む参照用コーパスの 5 つのリリースすべてがインポートされました。InfiniDysk がファイルを落とすことを心配する必要はありません。変わるのは主にネーミングです。

!!!warning WebDAV のルートを走査しないでください
`.ids` オブジェクトストアは、中身に関係なく 5 階層すべてで 16 個の 16 進数の子ディレクトリを実体化します。つまり 16^5、約 1,048,576 個のディレクトリがあります。`find`、`du`、`rclone`、その他のスキャナは、必ず `/content`、`/nzbs`、`/completed-symlinks` を明示的に指定してください。`/` を指定してはいけません。
!!!

## 移行後のライブラリの見た目 {#what-your-library-looks-like-afterwards}

**`__magic__`にライブラリのルートが移るため、すべて再追加になります。** なぜこれより安い方法がないのかは[共通ページ](index.md)を見てください。

これは、コストが最も小さく、得るものが最も大きい移行です。ほぼすべてのファイル名が良くなります。`ToyStory5.mkv`は`Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`になり、`__magic__`から再インポートする\*arrは、ファイル名から画質、ソース、グループ、エディションをようやく読み取れるようになります。シーズンパックだけは元のままですが、それらはもともと正しく読めています。

名前が変わるリリースを一覧にしてください。その多くになるはずです。

```bash
ID=/mnt/remote/nzbdav                      # your InfiniDysk mount
find "$ID/content" -mindepth 3 -maxdepth 4 -type f | while IFS= read -r f; do
  rel=$(basename "$(dirname "$f")")
  b=$(basename "$f")
  [ "${b%.*}" = "$rel" ] && echo "RENAMED BY INFINIDYSK: $f"
done
```

`-maxdepth 4`が大事なのは、アーカイブディレクトリの1階層内側でリネームが起きることがあるからです。

!!!info この内容が見えるかどうかは、お使いの環境によります
Plexがマウントを直接読んでいる場合、上記の名前がそのままライブラリで変わります。これは、Windowsのすべての環境と、\*arrのsymlinkファームを使わないLinuxまたはmacOSの環境が対象です。

SonarrとRadarrがリネームを有効にしてsymlinkライブラリを整理している場合、**ファイル名はすでに彼らのもの**になっているので、上記の名前はPlexには表示されません。その場合、名前から分かるのは、\*arrがどれだけ良いパースを元に作業していたかです。これは再インポートのときに重要になります。詳しくは[共通ページ](index.md)を見てください。
!!!

## 新しいコンテンツはどう表示されるか {#what-new-content-shows-up}

- **サンプルクリップ。** 既にある `Sample/` ディレクトリが空ではなくなります。これは設定しておく価値が最もある項目です。9 MB のサンプルがエピソードの2つ目のバージョンとして表示されてほしくない場合は、[`only_show_the_biggest_file: true`](../reference/config.md) を設定してください。
- RAR リリース内の `.nfo`。Plex のデフォルトエージェントでは効果がありません。
- アーカイブのチェーンが途切れているディレクトリ内の空フォルダ。InfiniDysk はこれらに対して何も作成しません。
- **par2 と sfv が見えなくなります。** 難読化されたリリース内のハッシュ名のボリュームも含まれます。これらにはメディアの拡張子がないため、Plex は項目として登録しません。Plex 以外のツールでこれらを走査していた場合は、それに気づくでしょう。

## NZBを取り出す {#get-your-nzbs-out}

zurgには `.nzb` ファイルのディレクトリを渡します。リリースごとに1つで、リリースフォルダの名前を付けてください。InfiniDysk の WebDAV にある `/nzbs/<category>/` はキューを反映しており、読み取り可能です。

```bash
mkdir -p ~/recovered-nzbs
rclone copy infinidysk:nzbs ~/recovered-nzbs/ --include '*.nzb'   # scoped to /nzbs, never the root
find ~/recovered-nzbs -name '*.nzb' | wc -l
```

完了したジョブが終了後も `/nzbs` に表示され続けるかどうかは、**未確認**です。このフォルダはキューを反映しているので、履歴はキューより深く残っているかもしれません。InfiniDysk が再マウント用に保持している NZB メタデータで不足しているものは、`{CONFIG_PATH}/blobs/` にあります。blob の形式も未確認なので、信用する前に確認してください。

```bash
for f in "$CONFIG_PATH"/blobs/*; do head -c 32 "$f" | grep -q '<?xml' && echo "NZB: $f"; done
```

お使いの環境で blob がプレーンな XML でなければ、インデクサーのダウンロード履歴を代わりに使ってください。

そのうえで、実際に持っているリリースフォルダごとに `<release>.nzb` というファイルを作成してください。

```bash
find "$ID/content" -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | awk -F/ '{print $1 "\t" $2}' > releases.tsv
```

`/nzbs/<category>/` から取得した NZB は、通常すでに正しい名前になっています。フォルダ名はそこから取られたものだからです。リストと照らし合わせて確認しておきたい zurg の命名ルールが2つあります。

- zurg はフォルダ名末尾の `.mkv` や `.mp4` を取り除きます。そうした形で終わるリリースフォルダがあれば、`retain_folder_name_extension: true` を設定してください。
- 同じ名前を持つ別々のリリースが2つあると、そのうちの1つに ` {shorthash}` のサフィックスが付きます。`cut -f2 releases.tsv | sort | uniq -d` で見つけられます。InfiniDysk では別の形で同じ問題が起きていました。そこで NZB を再インポートすると `<Release> (2)` が作られました。

## zurgを並行して構築する {#build-zurg-alongside}

InfiniDysk は、ずっとサービスを提供し続けます。

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

`__all__` には、ディレクトリのフィルターに関係なく、すべてのリリースが入っています。

## 切り替える {#cut-over}

**1. `__magic__` を有効にして**、再起動してください。ルートは起動時に登録されるので、ダッシュボードのトグルだけでは再起動するまで名前空間が応答しません。

```yaml
magic:
  enabled: true
```

**2. ルートフォルダを作ります。** `__magic__` 直下、zurg がそこに残している `__all__` の隣に置きます。`__magic__/__all__` でも、`__magic__` 自体でも、マウントのルートでもありません。両方の \*arr がこれらの場所についてヘルスチェックの警告を出しますが、兄弟の位置に作ればどちらも警告を出しません。

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` はライブラリをそのまま映し出すので、何かを整理する前に、すべてのリリースがそこに揃っています。

**3. 整理します。** `__magic__` 内での `mv` は行を書き込むだけで、バイトは一切動きません。

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**古いライブラリを Sonarr と Radarr で整理していた場合は、1 つのスクリプトでまとめて移せます。** これは古いライブラリがリンクしているすべてのファイルを、`__magic__` 配下の新しいルートフォルダへリネームします。各ファイルは、\*arr がすでに期待しているパスに配置されます。コピーは一切行いません。その後、\*arr のルートフォルダを切り替えますが、この時点で \*arr にファイルを動かさせることはありません。手順とスクリプトは [共通ページ](index.md#coming-off-a-symlink-library) にあります。\*arr にファイルを自分で動かさせることは、絶対にしないでください。マウントの境界をまたぐため、コピーになってしまい、ライブラリ全体をダウンロードし直すことになります。

このスクリプトには、InfiniDysk のリンク用に `zurg_path` 関数が必要です。以下を `zurg_path.sh` という名前で隣に保存し、`OLDMOUNT` を InfiniDysk のマウント先に設定してください。

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

InfiniDysk のリンクは `.ids` ストアを指していますが、zurg にはそのようなものはありません。そこで関数は、InfiniDysk の `completed-symlinks` ツリーを一度だけ読み込み、各 `.ids` の名前がどのリリースのどのファイルに対応するかを調べます。InfiniDysk が単独の動画にリリース名を付けていた場合は、そのリリースに zurg が配信している動画がちょうど 1 本あれば、それを使います。動画が複数あるリリースは推測せず、代わりに `NOT IN ZURG` と表示します。スクリプトが終わるまで、InfiniDysk は動かしたままにしてください。

**4. Plex を、作成したルートフォルダ、つまり `__magic__/tv` と `__magic__/movies` だけに向けます。** `__magic__` 直下は指定しないでください。そこには `__magic__/__all__` を含むライブラリ全体があるため、同じ項目が二重に見つかってしまいます。`__magic__` と、フィルタ用ディレクトリの両方を指定するのも避けてください。理由は同じく、すべてのエピソードが二重に見つかるからです。`autoEmptyTrash` が `0` であることを確認します。新しい場所を追加してスキャンします。そのあとで古い場所を削除します。古い場所とは、\*arr のライブラリパス、または Plex が直接読んでいた場合は InfiniDysk のマウントです。

**5. 数件を抜き取りで確認したら、Empty Trash を実行します。** 視聴状態は GUID 照合を通じて戻ってきます。ただし、コレクションとアートワークの選択は戻りません。

それまでは InfiniDysk を動かしたままにしてください。コストはかかりませんし、ロールバック用に必要です。作業が終わったら停止してください。

```bash
sudo systemctl stop infinidysk infinidysk-rclone-mount
```

## 移行後 {#afterwards}

代表的なサンプルからストリーミングできたことを確認するまで、`{CONFIG_PATH}/blobs/` と復元した NZB のセットは残しておいてください。

次に取得(acquisition)について考えましょう。zurg には、オプトイン式の [SABnzbd 互換エンドポイント](../guides/sonarr-radarr.md) があり、Sonarr と Radarr はここ経由で取得できます。これが、両者のダウンロードクライアントとして InfiniDysk の代わりになります。取得したものは `__magic__/__all__` に置かれ、インポート時に名前を変更して移動されます。コピーは行われません。

zurg は、完了を報告する前に取得ごとにチェックします。すべてのファイルについて、先頭と末尾の記事をニュースサーバーに問い合わせます。また、各ファイルの最初の記事をダウンロードします。ファイル数は最大 64 件で、ファイル数が少ないリリースではさらに数件分を加えます。ニュースサーバーによっては、内容が削除された後も記事が存在すると応答することがあり、それを確かめられるのは実際のダウンロードだけです。zurg は、可能な場合は PAR2 ファイルを使って、記事が欠けたリリースを復元します。復元できないものは **Failed** と報告されます。すると \*arr はそれをブロックリストに入れ、別のものを取得します。

このチェックはサンプルであり、投稿全体を確認するものではありません。サンプルが届かなかった範囲で欠落している投稿は、それでも Completed と報告され、欠けている箇所に到達した読み込み時に失敗します。

\*arr のルートフォルダは `__magic__` の中に置いてください。それ以外の場所にルートフォルダがあると、インポートのたびにファイルが丸ごとコピーされます。Docker では、\*arr には zurg のマウント全体を含む 1 つのボリュームを渡してください。ダウンロードフォルダとルートフォルダが別々の 2 つのボリュームにあると、やはりインポートのたびにコピーが発生します。詳しくは [1 つのボリューム](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) を参照してください。
