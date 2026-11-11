# プロバイダーからアプリをダウンロードする {#apps-download-from-your-provider}

通常、rex はソースからすべての映画を読み取り、それを Plex に渡します。ソースがデバッグリンクなどのファイルリンクを返す場合、rex はそれを Plex に渡せます。すると Plex がファイルを直接ダウンロードするので、rex のマシンはメディアを一切持ちません。

これは Plex がそのファイルを direct play できる場合に動作します。rex による変換が必要なものは、引き続き rex を経由するか、選択していれば拒否されます。

2026-10-25 に、Real-Debrid 上の zurg、Plezy と Pixel 6 上の Plex for Android、Chrome 上の Plex Web でテストしました。

## 始める前に {#before-you-start}

**共有のデブリッドアカウントで再生するときは、デフォルトのプロキシモードのままにしてください。** リダイレクトは、1つのデブリッドアカウントを共有する安全な方法ではありません。

- **Real-Debrid は、ダウンロードした各端末のパブリック IP を記録します。** CDN からファイルを問題なく配信できていても、1つのアカウントを複数の IP から使うと共有の警告が付きます。そのアカウントの利用はすべて、1つのパブリック IP に限定してください。リモートのアプリが直接ダウンロードしている一方で、rex やそのソースがサーバーの IP からプローブや変換を行うと、このルールに違反します。再生が成功したからといって、安全だという証明にはなりません。
- **TorBox のダウンロード URL には、`?token=` の中に APIキー全体が含まれています。** リダイレクトすると、どのクライアントや共有ユーザーアカウントでも、削除を含めてアクセスできるようになります。ファイルへのアクセスだけでは済みません。プレーヤーのログやブラウザの履歴にキーが残ることもあります。信頼できないクライアントには、これらのリンクを渡さないでください。

これらのリスクを許容できる場合にのみ先に進んでください。rex のデフォルトのプロキシモードを維持すると、rex はプロバイダーのリンクをアプリに渡す代わりに、ソースのリダイレクトを自分で追跡します。

| 必要なもの | 理由 |
|---|---|
| [rex with your own app](any-source.md)、[rex with your Stremio addons](stremio.md)、[rex with zurg](with-zurg.md) のいずれかの手順で rex を設定済みで、映画が再生できること | このページでは rex の起動コマンドを変更し、一部のソースでは、そのソースの設定も1つ変更します |
| rex nightly **2026.10.26 以降** | 古いビルドにはこの設定がありません。[rex's Updating section](any-source.md#updating) の手順に従って更新してください |
| リンクを返せるソース | rex が渡せるのは、ソースが返したリンクだけです。どのソースがこれに対応しているかは [Step 1](#step-1-let-your-source-hand-out-links) で説明しています |

## どの程度厳しくするか選ぶ {#choose-how-strict}

| | `redirect` | `redirect-only` |
|---|---|---|
| アプリがファイルをそのまま再生する場合 | アプリはプロバイダーからダウンロードします | アプリはプロバイダーからダウンロードします |
| アプリがファイルの変換を必要とする場合（画質を下げる、再生できない音声、焼き付け字幕など） | rex が変換します。ファイルは従来どおりソースから読み込みます | 拒否: アプリにエラーが表示されます |
| ソースがリンクではなく自分でファイルを送ってくる場合（例: zurg の Usenet ファイル） | 従来どおり rex 経由で再生 | 拒否 |
| Plex Web | rex 経由で再生 | すべての Real-Debrid ファイルが拒否されます（下記参照） |

すべて再生し続けたく、かつできるだけ節約したい場合は `redirect` を選んでください。rex を動かすマシンに映画を絶対に通したくない場合（例: データ上限のある小さな VPS）は `redirect-only` を選んでください。

どちらを選んでも、rex を共有しているアプリや人は、再生するものについてソースが rex に渡したリンクを受け取ります。そのリンクの先にあるサービス（例: お使いのデブリッドサービス）は、その人それぞれのダウンロードを見ることになります。

## ステップ1. ソースにリンクを渡してもらう {#step-1-let-your-source-hand-out-links}

**何をするか。** ソースは各読み取りに対し、ファイル本体ではなく、ファイルがある場所へのリンク(HTTP リダイレクト)で応答します。

**なぜ重要か。** rex は、ソースから受け取ったリンクしか渡せません。ファイル本体を直接送ってくるソースは、rex を経由してそのまま送り続けます。

| ソース | やること |
|---|---|
| [rex-stremio](stremio.md) | 何もしない。ストリームアドオンから受け取ったリンクで応答するため。独自のヘッダーが必要なリンクやライブのプレイリストは、引き続き自分で送る |
| [zurg](with-zurg.md) | 下記の `disable_stream_proxy` を有効にする。zurg は Usenet ファイルのリンクを持たないため、それらは常に自分で送る |
| [自分のアプリ](any-source.md) | ファイルへの `GET` に、リンク先への `302` または `307` で応答する |

### zurg

zurgの設定なので、zurgを読むもの（rcloneや、zurgのマウント上のPlexまたはJellyfinサーバーなど）もリンクを受け取ります。詳しくは、zurgの[設定リファレンス](../zurg/reference/config.md)を見てください。

+++ Linux and macOS
まず、この設定がzurgの設定ファイルにすでにあるか確認します:

```bash
grep -n '^disable_stream_proxy:' ~/zurg/config.yml
```

行が表示されたら、`nano ~/zurg/config.yml` で `disable_stream_proxy: true` に変更します。何も表示されなければ、次の行を追加します:

```bash
printf '\ndisable_stream_proxy: true\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
`notepad $HOME\zurg\config.yml` でzurgの設定を開きます。`disable_stream_proxy:` の行があれば `disable_stream_proxy: true` に変更してください。なければ、ファイルの最後にその行を追加します。保存してから、zurgを再起動します:

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++ Docker
zurgのフォルダーで次を実行します:

```bash
sudo grep -n '^disable_stream_proxy:' config.yml
```

行が表示されたら、`sudo nano config.yml` で変更します。表示されなければ、次を実行します:

```bash
printf '\ndisable_stream_proxy: true\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```
+++

**表示される内容。** zurgはいつも通り起動します。この時点では、映画はまだrexを通して再生されます。rexはステップ2まで、自分でリンクをたどります。

## ステップ2. rex にリンクを受け渡してもらう {#step-2-let-rex-pass-the-links-on}

**何をするのか。** rex は、映画をダウンロードしてアプリに渡すのではなく、ソースから受け取ったリンクをそのままアプリに渡します。

rex の起動コマンドの末尾に `--part-mode redirect`（または `--part-mode redirect-only`）を付けてから、rex を再起動してログを開いてください。[rex のインストール](any-source.md#step-1-install-rex) に、起動コマンドの場所や、rex の再起動方法とログの見方が載っています。Linux では、`~/.config/systemd/user/rex.service` の `ExecStart` 行が次のようになります（その行には他に何も入れません）:

```ini
ExecStart=%h/rex/rex --part-mode redirect
```

行にすでにある内容（`--port 32500` や `--announce-url ...` など）は消さずに残してください。

**表示されるはずの内容。** 起動行の末尾は `parts=redirect` になります:

```
INFO    rex on http://192.168.1.20:32400  machine=...  items=...  parts=redirect
```

`redirect-only` の場合は、末尾が `parts=redirect-only` になり、その数行上に rex が `transcoder off: --part-mode redirect-only` と表示します。

## ステップ3. 何かを再生する {#step-3-play-something}

rex のログを開いたままにして、Plezy または Plex for Android で映画を再生してください。

**見えるはずのもの。** アプリが読み込みを行うたびに、プロバイダーのサーバー名を含む行が表示されます:

```
INFO    PART 1000010 range=bytes=0- -> 302 to 129-4.download.real-debrid.com
```

これは rex がアプリをリンク先のサーバー（ここでは Real-Debrid）に接続させている様子です。代わりに `-> 206 len=...` で終わる行が出る場合は、rex が映画そのものを送信しています。[うまくいかない場合](#if-it-does-not-work)を参照してください。

## 各アプリの役割 {#what-each-app-does}

| App | `redirect` | `redirect-only` |
|---|---|---|
| Plezy | プロバイダーからダウンロードされます | 同じ |
| Plex for Android, Original quality | rex がファイルをそのまま再生できる場合は、プロバイダーからダウンロードされます | 同じ |
| Plex for Android, a lower quality, or audio it cannot play | rex が変換します | "Playback Error: This item can't be played right now. Please try again." |
| Plex Web | rex 経由で再生されます | "Playback Error: This server is not powerful enough to convert video." |

Plex Web は Real-Debrid のリンクをまったく使えません。Real-Debrid はファイルを動画ではなくダウンロードとして扱うため、ブラウザーが再生を拒否します。`redirect` の場合、Plex Web は 1 秒以内に rex 経由の変換へ静かに切り替わるので、問題なく動きます。`redirect-only` では切り替え先がありません。

## Dockerで使う場合 {#in-docker}

[Docker での rex](any-source.md#run-rex-in-docker) の手順に従った場合、2つ目の手順は rex の `compose.yml` の `rex:` の下にある `command:` の行を編集することです。この行は `image:` と同じ階層にあります:

```yaml
    command: --part-mode redirect
```

すでに `command: --port 32500` と書いてありますか？ その場合は `command: --port 32500 --part-mode redirect` に変更してください。そのあと rex のフォルダーで `docker compose up -d` を実行します。`docker compose logs -f rex` を実行すると、同じ `parts=redirect` の行が表示されます。

## うまくいかない場合 {#if-it-does-not-work}

| 表示されるもの | 意味 |
|---|---|
| `--part-mode` で rex が `invalid choice` と表示して終了する | rex が 2026.10.26 より古いバージョンです。[rexのアップデート方法](any-source.md#updating)に従って更新してください。 |
| rex のログに、すべての読み取りで `-> 206 len=...` と出る | ソースがファイルそのものを送っています。zurg を使っている場合は、zurg の設定に `disable_stream_proxy: true` がないか、手順 1 の後に zurg を再起動していないかのどちらかです。 |
| 一部のタイトルだけ `-> 206 len=...` と出る | そのタイトルはソースが直接送っています。zurg の Usenet ファイル、または rex が中継しなければならない rex-stremio のリンクです。 |
| `-> 403: the source answered with the bytes, not a link` | ソースがファイルを直接送ってきたものを `redirect-only` が拒否しています。理由は上と同じです。 |
| 映画の再生中、`PART` の行がまったく出ない | アプリがファイルそのものではなく変換後の映像を再生しています。アプリの画質設定を Original にしてください。 |

まだ解決しませんか？ [Discord](https://discord.com/invite/7u4YjMThXP) の **rex-support** フォーラムで質問してください。[サポートを受ける方法](../guides/remote-help.md)に、何を含めればよいか書いてあります。

## 前のページに戻る {#going-back}

rex の起動コマンドから `--part-mode ...` を削除して（Docker の場合は `command:` の行を削除して）、rex を再起動してください。ソース側はこれまで通りリンクを渡し続けて大丈夫です。rex の設定がなくなると、rex がそのリンクを自分でたどるようになります。

zurg の場合は、`disable_stream_proxy` を `false` に戻して zurg を再起動してください。そうすると、zurg がファイルを再び自分で中継するようになります。rclone をはじめ、そこから読み込むほかのものにも同じように効きます。
