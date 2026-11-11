# zurg への移行 {#migrating-to-zurg}

ずっと先まで読む前に、まずこのページを読んでください。すべての移行に当てはまる内容で、必要なことの大半はここにあります。サーバーごとのページは短くしてありますが、それは共通部分をこのページにまとめているからです。

## 要点 {#the-short-version}

**zurg は、いま使っているサーバーが公開しているメディアファイルをすべて公開していて、それ以上のものも公開しています。** これは 2026-09-01 に測定したものです。同じ 5 つのリリースを 5 つのサーバーすべてに入れ、マウントを `tree` で読み取りました。[完全な比較はこちら](https://github.com/debridmediamanager/usenet-streaming-benchmark)です。
zurg が *少なく* しか公開していないのは par2 のパリティファイルだけです。Plex がこれをライブラリのアイテムに変えることはありません。

なので **コンテンツが失われることはありません。** 一部は別のファイル名で届きます。このページで扱うのはその点だけです。Plex はライブラリのアイテムをファイルパスに紐づけます。新しいパスのファイルは、新しいアイテムになります。

失うのはファイルではなく、**キュレーション**です。

| 引き継がれるもの | 古いアイテムと一緒に消えるもの |
|---|---|
| 視聴済みフラグ、再生回数、再開位置 | コレクションへの所属 |
| ユーザーの評価 | プレイリストの項目（アイテム ID で保存されているため） |
| ファイルそのもの | 選んだポスター、アート、手動のマッチ修正 |
| | `added_at`。ライブラリが Recently Added で埋まります |

視聴状態が残るのは、`metadata_item_settings` がパスやアイテム ID ではなく、アカウントと `plex://` GUID で管理されているからです。新しいアイテムが同じ GUID にマッチすれば、状態は再びつきます。Plex が再追加されたアイテムを誤マッチさせると、状態は戻りません。最初のスキャンのあとに数件確認してください。

この代償を払えば、このトレードを完全に避けることもできます。Plex のデータベースで `media_parts.file` を書き換えて、行が消えないようにする方法です。あるいは、zurg のマウントの上に、古いパスをすべて再現するシンボリックリンクのシムツリーを作る方法もあります。どちらも動きますが、どちらもドキュメントのないスキーマへの非公式な手作業で、Plex のバージョンによって変わります。書き換えが途中で止まると、防ごうとした結果のどちらよりも悪くなります。

このガイドでは、シンプルな方法を取り、その代償を正確にお伝えします。

## ライブラリは symlink の集まりではなく `__magic__` に入ります {#your-library-lands-in-__magic__-and-not-in-a-symlink-farm}

このリストにあるサーバーはどれも、\*arrs へのライブラリの渡し方に symlink の集まりを使っています。**zurg はそれを行わないし、作り直すべきではありません。** 代わりに [`__magic__`](../guides/magic.md) があります。これは、パスが計算されるのではなく*保存される*唯一のディレクトリです。その中で移動すると、小さなテーブルの1行が書き換えられるだけです。バイトは動きません。コピーもされません。リリースはアカウント上の元の場所に残ります。Sonarr と Radarr をそこに向ければ、費用をかけずに好きなように整理・改名できます。

これは単に部品が1つ減るというだけではありません。古い方式のように壊れることのない層です。symlink は実在するパスを指している必要があります。分かりやすい対象は `__all__/<release>/<file>` ですが、このパスは*計算*されます。リリースの名前が変わると変わります。さらに、2つのリリースが衝突して zurg がどちらかに `{shorthash}` を付けると、また変わります。そのたびに、リンクは静かに宙ぶらりんになります。`__magic__` の配置は、リリースのコンテンツハッシュと、その中のファイルのパスをキーにしています。ですから名前が変わっても生き残ります。`{shorthash}` の接尾辞が付いても生き残ります。リリースが全く新しい id で再追加される修復を行っても生き残ります。

つまり、今どんな構成を使っていても、**パスは変わり、ライブラリは再追加することになります**。これは \*arr の symlink ライブラリにも、古いマウントを直接指している Plex にも当てはまります。上で述べたトレードオフであり、ここでのあらゆる移行にかかる費用の全てです。

## 今の構成はプラットフォームによって異なります {#what-you-have-today-depends-on-your-platform}

このページの後にあるリネームの表が、Plexライブラリについて説明しているのか、それとも元になったソースについて説明しているのかを決めます。読む前に、ここを正しく理解しておいてください。

### Linux と macOS。Sonarr や Radarr などのリネームはすでに済んでいます {#linux-and-macos-your-arrs-already-renamed-everything}

シンボリックリンク方式は、ここで紹介している4つのサーバーすべてで推奨されているセットアップで、これらのプラットフォームでしか使えません。サーバーは `completed-symlinks/<category>/<release>/<file>.rclonelink` を公開します。次に `rclone mount
--links` が、それぞれを本物のシンボリックリンクに変換します。その後 **Sonarr と Radarr がそのファームから、自分で決めたパスにあるライブラリへインポートします。** 参照元はマウントであって、ライブラリではありません。

ここから分かることは2つあります。

- **Plex が見るパスは、必ず \*arr が決めたものです。** ルートフォルダ、シリーズフォルダ、シーズンフォルダの順になっていて、どれにもリリース名は含まれません。
- **ファイル名も、リネームを有効にしていれば \*arr が決めたものです。** 「Rename Episodes」と「Rename Movies」がそれにあたります。リネームを無効にしていれば、ファイル名は元のサーバーの名前のままで、次のページの表が実際に見える内容をそのまま説明しています。

つまり \*arr でリネームを有効にしている場合、サーバーごとのリネーム表は**あなたのライブラリを説明していません**。それは \*arr がインポート時に受け取った内容を説明しています。とはいえ、これは今も重要です。元のファイル名がわかりやすいほど解析の精度が上がり、このあと再インポートする予定だからです。

### Windows。symlink の層はまったくありません {#windows-no-symlink-layer-at-all}

Linux/macOS向けのシェルコマンドは、ドライブレターを使う Windows では使えません。

`rclone mount --links` を使ったシンボリックリストのファームには、Windows のセットアップは含まれていません。マウントは WinFsp を通したドライブレターとして作られ、Plex や \*arrs はそこを直接指定します。そのため **Plex にはサーバー側の元のファイル名が表示されます**。名前変更の表には、実際に何がどう変わるかが正確に書かれています。ドライブレターとそのセッションのルールについては、[Windowsセットアップ](../setup/windows.md)のページを参照してください。

サーバーごとのページにあるシェルコマンドは Linux と macOS 向けに書かれています（macOS では `/mnt/zurg` を `/Volumes/Zurg` と読み替えてください）。Windows では `/mnt/zurg` を `Z:\` と読み替えてください。古いサーバーは、どの方法で起動したかに関係なく停止してください。フォルダの作成やファイルの移動は、`__magic__` 内で [`__magic__`ガイド](../guides/magic.md)の PowerShell コマンドを使って行ってください。

### symlink ライブラリからの移行 {#coming-off-a-symlink-library}

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

## 絶対に省いてはいけない安全策 {#the-one-guard-you-must-not-skip}

**`autoEmptyTrash` は、何かを触る前に必ず `0` にしてください。**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Windows では、PowerShell で次を実行します:

```powershell
$TOKEN = 'your-plex-token'
((Invoke-RestMethod "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN").MediaContainer.Setting | Where-Object id -eq autoEmptyTrash).value
# set it if needed:
curl.exe -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Plex は、この設定がオフのとき `0` または `false` として報告します。

Plex は削除をソフトに行います。`0` のときは、ファイルがなくなったアイテムがゴミ箱に残り、ファイルが戻ればそのまま復活します。`1` にしていると、スキャンがそれに気づいた瞬間に完全に消えてしまいます。スキャン中にマウントが10秒ほど途切れるだけで、ライブラリ全体が消えることもあります。これまでにも、何万件ものアイテムがこの被害に遭っています。

こうした簡易ガイドでは、この設定は以前より重要な役割を担っています。**ゴミ箱は、新しいアイテムを確認している間、古いアイテムを待たせておく場所です。** 確認が済んで満足してから、ゴミ箱を空にしてください。それより前は絶対に空にしないでください。ゴミ箱を空にする操作だけが本当に取り返しのつかない損失になり、このガイドの中で唯一元に戻せない操作です。

ついでに、対象のライブラリで **"Generate video preview thumbnails"** もオフにしてください。ストリーミングマウントでは、サムネイルを作るたびに、Usenet や debrid の利用枠を使ってリリース全体を読み込むことになります。移行では Plex に新しいアイテムが一度に大量に渡されるため、特にこの設定に注意が必要です。

## どの移行でも得られるもの {#what-every-migration-gains}

- **サンプル動画。** 5つのツールの中で、RARリリースの `Sample/` ディレクトリ内にサンプルファイルを公開するのは zurg だけです。Plex が 9 MB の `-sample.mp4` を追加コンテンツとして、またはエピソードの2つ目のバージョンとして拾ってしまうことがあります。それが困る場合は、メディアライブラリがスキャンするディレクトリで [`only_show_the_biggest_file: true`](../reference/config.md) を設定してください。
- **`.nfo` ファイル。** 残すのは zurg だけです。Plex のデフォルトエージェントでは何の効果もありません。XBMC and NFO エージェントを使っていれば、そのエージェントがこれらを読み込みます。
- **`thumbnail.jpg` と `.url` の広告ファイル。** 効果はありません。`thumbnail.jpg` は Plex がポスターとして使うファイル名ではなく、`.url` ファイルは投稿元の宣伝用です。
- **空のフォルダ。** リリースのアーカイブが途中で壊れている場合に出てきます。Plex は中にメディアがないディレクトリを無視します。
- **par2 と sfv が消えます。** zurg はファイル名ではなく、ファイルの実際の中身を見て判断してこれらを隠します。Plex はもともとこれらを項目として扱わないため、ライブラリからは見えません。影響があるのは、これらを走査していたツールだけです。

## ガイド一覧 {#the-guides}

- [AltMount から](altmount.md)。アーカイブのリリースだけ名前を変えます
- [decypharr から](decypharr.md)。単一ファイルとアーカイブの両方のリリースの名前を変えます
- [InfiniDysk から](infinidysk.md)。単一ファイルとアーカイブの両方のリリースの名前を変えます
- [nzbdav から](nzbdav.md)。名前は一切変えません。5つの中で一番簡単です
- [streamnzb から](streamnzb.md)。移行するライブラリはありません。zurg には独自の Stremio アドオンがあります

Plex から zurg へではなく、Plex から離れたい場合は？ [Plex から rex へ移行](../../rex/from-plex.md)では、zurg と Plex アプリをそのまま残し、rex を Plex サーバーと並べて、または代わりに動かせます。

命名の動作は、各ページのとおり 2026-09-01 に、5つのリリースからなるコーパスで測定しました。使ったビルドは zurg `bda7e3c3`、AltMount `0614008b`、InfiniDysk `cd9b1205`、nzbdav `794948be`、decypharr `0dd1cbbd` です。これより古い、または新しいビルドでは、命名が異なる場合があります。再スキャンのリストを丸ごと信用する前に、手元のツリーで数件のリリースを抜き取り確認してください。
