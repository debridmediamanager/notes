# Plex から rex へ移行する {#move-from-plex-to-rex}

Plex Media Serverを使っていて、rexを試してみたいとします。Plexのアプリはそのまま使えます。変わるのはライブラリのソースとサーバーのアドレスです。

## 変わること {#what-changes}

| | Plex Media Server | rex |
|---|---|---|
| ライブラリの取得元 | Plex はディスクやマウントしたフォルダをスキャンします | ソース（自分のアプリ、rex-stremio、zurg など）が rex に持っているものを伝えます。rex がフォルダをスキャンすることはなく、マウントも不要です |
| 各ファイルの中身 | Plex はファイル名をもとに照合します | ソースが中身を判断して rex に伝えます。rex がファイル名を読むことはありません |
| 誤った照合 | サーバーで Fix Match | rex を所有するアカウントでサインインした Plex アプリで **Fix Match** を使います。rex は選択を保持し、zurg のように、ソースがその選択を取り消して保持し直すこともできます（[タイトルが現在の位置に配置される理由](with-zurg.md#why-dmm-places-the-files)） |
| サーバーのアカウント | 通常は自分のアカウント | rex 用に作成した新しい Plex アカウントを、自分のアカウントと共有します |
| 音楽、Live TV、写真 | フォルダとチューナーから | 送ってくるソースからのみ。例：アドオン（[rex アドオンの構築](addons.md#music)）や zurg のコミックブック。Plex Web では写真が表示されますが、Plex for Android では表示されません |
| テレビの録画 | はい | いいえ |

## 方法を選ぶ {#pick-a-way}

| | Plex と並べて | Plex の代わりに |
|---|---|---|
| What you get | Plex の隣で rex を動かします。アプリには両方のサーバーが表示されます | rex だけ。Plex の通常のポートを使います |
| Good for | rex を試すとき、写真や音楽をディスクに入れた Plex を残したいとき、TV を録画するとき | 完全に移行するとき |
| On the same machine as Plex | rex は `32500` ポートで動き、共有している Plex アカウント経由でアプリが見つけます | Plex を停止すると rex が `32400` ポートを使い、家のアプリが自動で見つけます |

置き換えるつもりでも、まずは Plex と並べて始めてください。視聴履歴をコピーするには、古い Plex サーバーが動いている必要があるからです。ステップ 1 から 3 を行い、しばらく rex を使ってみて、準備ができたらステップ 4 を行ってください。

## 手順 1. rex を Plex と並べてセットアップする {#step-1-set-up-rex-beside-plex}

[rex with your own app](any-source.md)、[rex with your Stremio addons](stremio.md)、[rex with zurg](with-zurg.md) のように、rex に中身を入れてくれるソースを設定して、何か見られるところまで進めてください。

すでに Plex 用に zurg を動かしていますか？ その場合は zurg のインストールはスキップして、rex with zurg の手順 1 に書かれている通りに更新してください。zurg は nightly **2026.10.27** 以降から rex にデータを送れます。

- **Plex を同じマシンで動かしていますか？** [rex のインストール](any-source.md#step-1-install-rex) に書かれている通り、その場合は rex をポート `32500` に置き、ソース側にもそのポートを設定してください。そうすると、アプリには同じマシン名のサーバーが2つ表示されます。共有されている方が rex で、その横に新しいアカウントの名前が付きます。名前の変更方法は [rex のインストール](any-source.md#step-1-install-rex) を見てください。
- **rex は新しい Plex アカウントに登録してください。** Plex サーバーがあるアカウントではなくです。詳しくは [Plex アカウントへの追加](any-source.md#step-3-add-it-to-a-plex-account) を参照してください。
- **rex-direct で外出先から使いますか？** ルーターのポート 32400 はすでに Plex に転送されているはずです。ポート `32500` も rex のマシンに転送してください。または、[IPv6 の場合](any-source.md#rex-direct-over-ipv6) は、`32500` を rex のマシンへ通してください。

zurg を使っていますか？ 両方が動いている間は、zurg が両方にデータを送ります。Plex 用に zurg で設定しているものは、そのまま残してください（`plex_server_url`、`plex_token`、rclone のマウント、スキャン用スクリプトなど）。Plex はこれまで通り動き続け、`rex_url` を追加すると rex も加わります。

## 手順 2. 視聴履歴を持ってくる {#step-2-bring-your-watch-history}

ライブラリを rex に入れたら、[視聴履歴を取り込む](import-watched.md)で、Plex サーバーから視聴したもの、途中で止めた位置、星の評価をコピーできます。Plex が動いている間に実行してください。共有している人それぞれが、自分の履歴について同じ操作をします。

## 手順 3. 共有相手を再招待する {#step-3-invite-your-people-again}

友達や家族は、あなたの Plex サーバーには招待されていますが、rex には招待されていません。rex は新しいアカウント上の新しいサーバーなので、そこから招待してください。ほかの共有と同じように、相手が承諾すれば完了です：[家族や友達と rex を共有する](sharing.md)

## 手順 4. Plex を引退させる（任意） {#step-4-retire-plex-optional}

**Plex を完全に停止します。** Linux では `sudo systemctl disable --now plexmediaserver` を実行します。Docker では、そのコンテナを停止して compose ファイルから削除します。Windows と macOS では、Plex Media Server を終了し、ログイン時に起動するアプリの一覧から外します。

**rex を 32400 番ポートに移します。** 同じマシンで Plex と並んで `32500` を使っていた場合は、次の手順で変更します:

1. rex の起動コマンド（Docker の場合は `command:` の行）から `--port 32500` を削除し、[rex のインストール](any-source.md#step-1-install-rex) に書かれた手順に従って rex を再起動します。Windows では、その手順どおりに 32400 番と探索用の 2 つのポートをファイアウォールで許可してください。
2. ソース側に rex の新しいアドレス `http://192.168.1.20:32400`（rex の LAN IP）を設定して、再起動します。zurg の `rex_url`、または rex-stremio の設定ページにある **rex's address** です。
3. rex のアドレスを設定した他の場所（Kometa など）でも、`32500` を `32400` に変更します。
4. rex-direct を使っている場合は、ルーターのポート 32400 の転送先を rex のマシンに向け、`32500` の転送設定は削除します。IPv6 の場合は、ファイアウォールのルールを `32500` から `32400` に変更し、rex を再起動して新しいポートで IPv6 を提供させます。

これで rex は 32400 番ポートで応答します。家庭内の Plex アプリは、ネットワーク上で自動的に rex を見つけます。

**zurg を使っている場合は、Plex の設定を整理します。** zurg の設定には、停止した Plex がまだ残っているかもしれません:

| zurg の `config.yml` の項目 | 対応 |
|---|---|
| `plex_server_url` と `plex_token` | 両方を削除するか、zurg のダッシュボード（設定ページの **Media Server Integration**）で Plex の横にある **Remove** を押してください。zurg の [Plex ウォッチリスト](../zurg/guides/plex-watchlist.md) を使っていますか？ その場合は `plex_server_url` だけを削除してください。ウォッチリストは `plex_token` を使って plex.tv から読み込まれ、Plex サーバーは不要です。代わりに rex を指定することもできます。そのページで **Re-Auth** を押し、新しいアカウントでサインインして rex を選んでください。zurg 2026.10.27 以降では、サーバーが rex だと認識され、スキャン、Plex のマッチング、シーズン修正、Plex 設定の確認は送られなくなります。このときのトークンは新しいアカウントのものになるので、Plex ウォッチリストもそのアカウントに従います |
| Plex のスキャンを実行する `on_library_update`（例: `plex_update.sh`） | 削除してください。rex は zurg から直接すべての変更を受け取ります |
| `plex_database_path`、`plex_scan_check_url`、`plex_scan_check_token` | 削除してください。これらは停止した Plex を指しています |
| rclone のマウント（`rclone_enabled: true`、または自分で実行している rclone） | Sonarr、Radarr、Bazarr など、そこのファイルを読むものがあれば残してください。Plex だけが読んでいたなら、オフにしても構いません。rex は各ファイルを zurg から直接読みます |

設定を編集したら、zurg を再起動してください。

## 引き継がれるものと引き継がれないもの {#what-comes-along-and-what-does-not}

| 引き継がれるもの | 方法 |
|---|---|
| あなたの映画と番組 | ソースがrexに送ります。zurgを使う場合、Plexが読み込むのと同じdebridアカウントから届きます |
| 視聴履歴、再生位置、映画とエピソードの星評価 | [視聴履歴を取り込む](import-watched.md)（それぞれの人が個別に行います） |

| 引き継がれないもの | 理由 |
|---|---|
| Plexで行ったFix Matchの修正 | rexはPlexの一致情報を使いません。どのファイルが何かはソースが教えてくれます。間違っている場合は、rexの **Fix Match** で直してください |
| コレクション | コピーされません。[rexのKometa](kometa.md)が、Kometaの設定から作り直します |
| 選んだポスターやアートワーク | 古いサーバーにのみ残ります |
| プレイリストとサーバーの再生履歴一覧 | 古いサーバーにのみ残ります |
| 友達のアクセス権 | 古いサーバーに招待されていました。rexに招待し直してください（[ステップ3](#step-3-invite-your-people-again)） |
| ディスク上の音楽と写真、チューナーからのライブTV、録画 | rexにはチューナーがなく、録画もしません。音楽、写真、ライブチャンネルは、それらを送ってくれるソースからのみ届きます。これらのためにPlexをrexと並べて残しておいてください |
| ローカルディスク上のファイル | rexはフォルダをスキャンしません。アプリがファイルを配信し、rexに知らせる必要があります：[rexを自分のアプリで使う](any-source.md) |
