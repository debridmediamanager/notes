# zurg+rex の Android と Google TV 向け {#zurgrex-for-android-and-google-tv}

Androidアプリは、デバイス上でzurgエンジンを動かし、その横でrexも動かします。つまり、スマホやTVボックスの中に自分専用のPlexサーバーを置き、Plexアプリから見られるようにします。このアプリはスマホ、タブレット、Android TV、Google TVで動きます。Android 8.0以降が必要です。Fire TVでも同じAPKをサイドロードできます。システムのファイルアプリがないときは、WebDAVプレーヤーを使ってください。Usenetには64ビット版のAndroidが必要です。TorBoxでホストされているNZB（`torbox_nzb`）はAndroidでは使えません。

デビッドリッドアカウントもUsenetもなく、アドオンだけを使いたいですか？ [rex for Android](../../rex/android.md)は無料で、スポンサーになる必要もありません。

## インストールとセットアップ {#install-and-set-up}

[APK をダウンロード](https://zurg.debridmediamanager.com/ja/download.html#android)します。プライベートなスポンサー用リポジトリのナイトリーリリースから入手できます。ほとんどのスマホや TV ボックスでは `arm64-v8a` を、古い 32 ビット端末では `armeabi-v7a` を、エミュレーターや対応する Chromebook では `x86_64` を選んでください。どの APK にも、スマホ用と TV 用の両方の画面が含まれています。

アプリには zurg 本体は含まれていません。GitHub にサインインしてから、アプリ内でエンジンをインストールします。スポンサー権限が必要です。GitHub アカウントにアクセス権を付与するには、[gatekeeper](https://gatekeeper.debridmediamanager.com/) でスポンサーになってください。Setup で手順を順番に案内してくれます。

APK を開くのに使ったアプリからのインストールを許可してください。Android や Play Protect から、サイドロードの確認を求められることがあります。アプリケーション ID は `com.debridmediamanager.zurg` です。アップデートでも、リリース時の署名情報を維持する必要があります。

1. zurg を開いて GitHub にサインインし、エンジンのバージョンを 1 つインストールします。エンジンがインストールされるまでは、ライブラリを開始できません。
2. プロバイダーのアカウントを追加して、認証情報をテストします。同じプロバイダーに複数のアカウントがある場合は、アカウント名で区別されます。Usenet の接続数の上限は、そのアカウントを使う他のすべてのアプリと共有されます。
3. Phone、Tablet、TV box、TV stick から選びます。プロファイルによって、エンジンのメモリ目標値とディスクキャッシュのサイズが設定されます。Go のヒープ目標値は、RSS の厳密な上限ではありません。
4. 通知とバックグラウンド動作を許可します。この端末で常にライブラリを提供したい場合は、「start after reboot」を有効にしてください。
5. ライブラリを開始します。大きなアカウントでは、最初の読み込みに数分かかることがあります。通知と Status 画面で、ディレクトリの準備ができたかどうかを確認できます。

## このデバイスで視聴 {#watch-on-this-device}

Library でフォルダを参照し、ファイルを再生できます。More では別のプレイヤーや Android のドキュメント URI を選べます。選んだプレイヤーを優先プレイヤーに設定することもできます。
Files とドキュメントピッカーからは、同じライブラリが zurg のストレージルートの下に表示されます。
ファイルはランダムアクセスでストリーミングされるので、先に全体をダウンロードする必要はありません。
Files からプレイヤーを選ぶ前に、一度プレイヤーを開いてセットアップを済ませておいてください。

WebDAV 対応のプレイヤーでは、`http://127.0.0.1:9999/dav/` をソースとして追加します。ポートを変更している場合は、Status に表示されているポートを使ってください。VLC、Kodi、Nova は WebDAV ソースを参照できます。個別の URL しか受け付けないプレイヤーは、Library から起動できます。
TV では、D-pad と Select でコントロールを移動・操作し、Back で戻ります。リリースに対する操作は Menu または More から行えます。テキストフィールドを編集するには Select で選び、編集後に Back を押してナビゲーションに戻ります。スマートフォンでは、長押しでも More が開きます。

Repair、rename、tags、show all files、delete は、そのファイルを含むリリース全体に対して動作します。delete を実行すると確認が表示され、契約しているプロバイダーのアカウントからも削除されます。
MediaInfo はバンドルされている ffprobe を使い、ビデオ、音声、字幕の詳細をダッシュボードに表示します。別途メディアツールをインストールする必要はありません。

## Plex アプリで視聴 {#watch-in-the-plex-apps}

From the nightly of 10 November 2026, the app also runs rex (64-bit devices in
that nightly, every supported device from the 11 November nightly), a media
server for the Plex apps, and points zurg at it. That way your library appears
in the official Plex apps and in Plezy, on this device and on others in your
home. Once your library is running, Status shows **rex for the Plex apps**.
Choose **Sign in to Plex** and approve the sign-in (on a TV, enter the code at
plex.tv/link). The server appears in Plex under this device's name. rex converts
what a player cannot play with the device's hardware encoder. To turn rex off, go to
Settings, Connection. zurg then stops feeding it.

## ローカルネットワークで共有 {#share-over-the-local-network}

**Expose on local network** を Settings でオンにしてください。zurg が認証情報を生成し、デバイスの LAN WebDAV アドレスを表示します。そのアドレスと認証情報を、別のデバイスのプレーヤーに入力してください。Android ホストは電源を入れたまま、起動した状態にしておいてください。
HTTP の基本認証では通信は暗号化されません。信頼できるローカルネットワークで使ってください。
ループバックがデフォルトです。プレーヤーのインテントには、サーバーのパスワードは含まれません。

## 設定、バックアップ、アップデート {#settings-backups-and-updates}

Settings では、接続、プロバイダー、ライブラリ、修復、リソース、ログを設定できます。
Advanced では生の YAML を入力でき、保存する前にインストール済みのエンジンで検証させられます。
Settings には DMM の API キーを入れる欄がありません。[DMMのウォンテッドリスト](dmm-wanted.md)と DMM のリリース名の規則を使うには、Advanced に `dmm_api_key: YOUR_DMM_API_KEY` を追加してください。
実行中の設定を保存すると、サーバーを再起動する前に確認されます。
Web dashboard では、デスクトップ連携の設定用にローカルのダッシュボードを開けます。

Logs には、エンジンの最近の出力と supervisor の最後の 200 行が含まれます。
共有用のログでは、設定済みの秘密情報と URL が伏せられます。
バックアップには認証情報とライブラリの状態が含まれるため、非公開の場所に安全に保存してください。復元する前に zurg を停止してください。
Android では、バックアップのリンクや特殊ファイルは拒否され、復元はまず loopback に対して行われます。

Updates では、非公開のスポンサーリポジトリを確認します。リリースのアセットは非公開なので、GitHub のデバイスサインインでは `repo` スコープを要求します。
GitHub のトークンは、Android Keystore に対応した preferences で暗号化して保存されます。リポジトリへの読み取り権限を持つトークンを手動で入力することもできます。
保存されたサインインを Android が復号できなくなった場合、Updates から再度サインインするよう求められますが、ライブラリの設定はそのまま残ります。
ダウンロードした更新は、アプリケーション ID と署名鍵が一致し、バージョンコードが新しい必要があります。Android のインストーラーは、アプリを置き換える前に確認します。

エンジンを同梱していたビルドからアップデートすると、アプリにはエンジンがなくなります。Updates から一度エンジンをインストールしてください。プロバイダーとライブラリの設定はそのまま引き継がれます。

アプリとエンジンは別々に更新されます。Updates には、スポンサーリポジトリの直近 30 件のリリースに含まれるエンジンのバージョンが一覧表示され、お使いのものには印が付きます。どれでもインストールできます。
新しい nightly が端末で不具合を起こす場合は、動作していた版をインストールしてください。エンジンを変更する前に、Status でライブラリを停止してください。アプリは自身の鍵で署名されたエンジンパッケージだけを実行し、起動のたびにその署名を確認します。

常駐通知には Stop のアクションがあります。Quick Settings のタイルからも、サーバーを起動・停止できます。Battery exemption は Android のアイドル制限への対策に役立ちます。メーカー独自のタスクキラーには追加の設定が必要な場合があり、その場合は [Don't kill my app](https://dontkillmyapp.com/)（アプリを強制終了させない）を参照してください。
