# zurg+rex の Android と Google TV 向け {#zurgrex-for-android-and-google-tv}

zurg+rex は、スマホの中で動く Plex サーバーです。zurg がデバッドのアカウントと Usenet を取り込み、rex が家の中のすべての Plex アプリに配信します。ポスター、シーズン、視聴の続きからの再生も使えます。スマホ、タブレット、Android TV、Google TV、Fire TV で動き、パソコンは要りません。

スポンサー特典付きで提供されています。スポンサーではない場合は、[rex for Android](../../rex/android.md) が無料で使えます。アドオンが提供するものを再生します。

| アプリ | Plex アプリ内 | 他のどの Plex アプリでも |
|---|---|---|
| ![ライブラリの準備が整い、rex が Plex にサインインしている zurg+rex のステータス画面](../../assets/zurg/android-status.webp) | ![Plex アプリで表示された Big Buck Bunny のページ。同じスマホから配信されています](../../assets/zurg/android-plex.webp) | ![Plezy アプリで表示された、同じオープンムービーのライブラリ](../../assets/zurg/android-plezy.webp) |

## 始める前に {#before-you-start}

| 必要なもの | 理由 |
|---|---|
| Android 8.0 以降のデバイス | スマートフォン、タブレット、Android TV、Google TV、Fire TV。Usenet には 64 ビットのデバイスが必要です |
| GitHub アカウントを連携したスポンサー登録 | アプリとそのエンジンは、スポンサー向けリポジトリからダウンロードされます。[gatekeeper](https://gatekeeper.debridmediamanager.com/) でスポンサーになり、GitHub を連携してください |
| debrid アカウントまたは Usenet アカウント | zurg が取り込むもの。TorBox のホストする NZB (`torbox_nzb`) は Android では利用できません |
| Plex アカウント | rex は、そのアカウントでサインインした Plex アプリに表示されます。無料アカウントで十分です |
| DMM の API キー (gatekeeper から取得、任意) | これがあると、より多くのタイトルで名前とポスターが表示されます |

## ステップ 1. ダウンロードする {#step-1-download-it}

デバイスで、[ダウンロードページ](https://zurg.debridmediamanager.com/ja/download.html#android)を開き、スポンサー用のアカウントで GitHub にサインインして、お使いのプロセッサに合ったファイルを選んでください。

| お使いのデバイス | ファイル |
|---|---|
| ほとんどのスマートフォン、タブレット、TVボックス（64ビット） | `android-arm64-v8a.apk` |
| 古い32ビットのスマートフォンやTVスティック | `android-armeabi-v7a.apk` |
| Chromebook やエミュレーター | `android-x86_64.apk` |

1つのファイルでスマートフォンもTVも動きます。

**GitHub で 404 と表示される？** サインインしているアカウントにはまだスポンサーとしてのアクセス権がありません。スポンサーになったばかりなら、まず[招待を承認](https://github.com/debridmediamanager/zurg/invitations)してください。招待は15分以内に届きます。

## ステップ 2. インストールする {#step-2-install-it}

ダウンロードしたファイルを開き、そのファイルを開いたアプリからのインストールを許可してください。Androidや Play Protect から確認を求められることがあります。

**表示されるもの。** アプリ一覧に **zurg+rex** が表示されます。

## ステップ3. GitHubにサインインしてエンジンをインストール {#step-3-sign-in-to-github-and-install-the-engine}

Appを開きます。画面に **Welcome to zurg+rex.** と表示されます。

1. **Sign in with GitHub** を押します。Appにコードが表示されるので、**Open GitHub** を押し、コードを入力して承認してください。スポンサー向けのリリースは非公開のため、GitHubが `repo` へのアクセスを求めてきます。
2. **エンジンをインストールします。** エンジンはzurgとrex本体で、Appとは別のパッケージに入っているため、Appとは別に更新されます。**Install** を押してください。Androidがインストール前に確認してくるので、許可してください。

**表示されるはずの画面。** **Add your providers.**

## ステップ4. プロバイダーを追加 {#step-4-add-your-providers}

1. **Add an account** を押して、プロバイダーを選びます。
2. デブリッドのアカウントの場合は、そのトークンを **Provider token** に貼り付けます。Usenet の場合は、**NNTP server**、**Port**、**Username**、**Password**、**Connections** を入力します。
3. **Test account** を押してから、**Add provider** を押します。

アカウントは持っている分だけ追加できます。同じプロバイダーのアカウントが複数ある場合は、**Account name** で区別できます。Usenet アカウントの接続数の上限は、そのアカウントを使っている他のアプリやデバイスも合わせてカウントされます。

## ステップ5. ライブラリを開始 {#step-5-start-your-library}

1. **Phone**、**Tablet**、**TV box**、**TV stick**のいずれかを選びます。小さい方を選ぶと、メモリとキャッシュの使用量が少なくなります。
2. 通知を許可して、アプリがバックグラウンドで動作できるようにします。このデバイスでライブラリを常に配信したい場合は、**Start after reboot**をオンにします。
3. **Start my library**を押します。

**表示される内容。** **Status**に**Ready for your players**と表示され、リリースの件数が数えられます。アカウントのデータが多いと、最初の読み込みに数分かかることがあります。

## ステップ6. Plexにサインイン {#step-6-sign-in-to-plex}

**Status** の **rex for the Plex apps** で **Sign in to Plex** を押します。

- **スマホやタブレットの場合**、ブラウザが Plex のサインインページを開きます。そこでサインインしてください。
- **テレビの場合**、アプリに **On any device, go to plex.tv/link and enter** とコードが表示されます。スマホかパソコンで plex.tv/link を開き、そのコードを入力してください。

Plex アプリにサインインしているのと同じアカウントを使ってください。

**正しく設定できているときの表示。** この端末に Plex がある場合、**Ready for the Plex app** と **Open Plex** ボタンが表示されます。

## ステップ7. Plexアプリで視聴 {#step-7-watch-in-a-plex-app}

同じアカウントでサインインしている Plex アプリを開いてください。この端末でも、テレビでも、別のスマホでも、自宅のパソコンでも構いません。サーバーは、この端末の名前で表示されます。ライブラリ **Debrid Movies** と **Debrid TV** があるはずです。再生を押してください。

rex は、プレイヤーで再生できないものを、端末自身のビデオエンコーダーを使って変換します。

## 名前で他のタイトルを探す {#get-more-titles-named}

**Settings**、**Library** を開き、DMM の API キーを **Dmm api key** 欄に貼り付けて保存します。その後 zurg が DMM に各ファイルの内容を問い合わせます。キーがないと、zurg はリリース名から推測するため、名前やポスターが付くタイトルが少なくなります。

タイトルが間違って見える場合は、Plex アプリでそのタイトルの **⋯** メニューを開き、**Fix Match** を選んで修正できます。

この欄は 2026年11月14日以降の nightly ビルドにあります。それより古いバージョンでは、**Settings** の **Advanced** に `dmm_api_key: YOUR_DMM_API_KEY` を追加してください。同じキーで [DMM のウィッシュリスト](dmm-wanted.md)も読み込めます。

## アドオン {#addons}

アドオンを使うと、ライブラリ以外にも rex で見られるものが増えます。**Addons** を開いてください。Internet Archive のアドオンは最初からインストールされていて、パブリックドメインの映画を追加します。[rex-addons](https://github.com/debridmediamanager/rex-addons) のリポジトリもすでに登録されています。別のリポジトリを追加するには、そのリンクを入力して開き、提供されているアドオンをインストールしてください。

各アドオンは、アクセスできる Web サイトを明示しています。新しいサイトにアクセスするようになったアップデートは、事前に確認を求めます。信頼できる人が提供するアドオンだけをインストールしてください。アカウントが必要なアドオンは、Web サイトで入力するコードを表示します。そこで得られたサインイン情報は、この端末に保存されたままになります。**Log** では、アドオンが最近何をしたかを確認できます。アドオンを削除すると、そのアドオンが追加したタイトルだけが消えます。

## このデバイスの他のプレイヤー {#other-players-on-this-device}

Plex アプリがなくても視聴できます。

- **Library** ではフォルダを参照し、選んだプレイヤーでファイルを再生できます。**More** では別のプレイヤーを開いたり、リリース全体に対する操作を行えます。操作は repair、rename、tags、show all files、delete です。これらはリリース全体に作用し、delete は実行前に確認を求めたうえで、プロバイダーアカウントからリリースを削除します。
- **Files** アプリとドキュメントピッカーには、zurg ルート配下にある同じライブラリが表示されます。Files からプレイヤーを選ぶ前に、一度そのプレイヤーを開いてセットアップを済ませてください。
- VLC、Kodi、Nova などの WebDAV 対応プレイヤーでは、ソースとして `http://127.0.0.1:9999/dav/` を指定します。ポートを変更している場合は、**Status** でアドレスを確認できます。

TV では D-pad と Select で移動し、Back で戻ります。Menu か **More** を押すと、リリースの操作を開けます。テキストフィールドを選択すると入力でき、入力が終わったら Back を押して次に進みます。

## 自宅の他のプレイヤーと共有 {#share-with-other-players-at-home}

Plex アプリが自宅にあるなら、それ以上の設定は要りません。rex は自動で見つけてくれます。別のデバイスにある WebDAV プレーヤーで使うには、**Settings**、**Connection** を開き、**Expose on local network** をオンにしてください。zurg がユーザー名とパスワードを作成し、そのプレーヤーに入力するアドレスを表示します。

信頼できるネットワークでだけ使ってください。パスワードは暗号化されずに送られます。この機能は初期状態ではオフで、自分でオンにしたときだけ有効になります。

## 実行し続ける {#keep-it-running}

- 通知にはサーバーの状態が表示され、**Stop** があります。クイック設定タイルからも開始と停止ができます。
- 一部のスマートフォンは、それでもバックグラウンドのアプリを停止させることがあります。[Don't kill my app](https://dontkillmyapp.com/) では、アプリに必要な設定が説明されています。
- **Updates** では新しいアプリと新しいエンジンを確認できます。両者は別々に更新されます。新しいナイトリービルドが端末で不具合を起こす場合は、**Show engine versions** を押して、正常に動いていたものをインストールしてください。その前に **Status** でライブラリを停止しておきます。
- **Settings** には **Create backup** と **Restore backup** があります。バックアップにはパスワードやトークンが含まれるため、取り扱いに注意してください。復元する前にライブラリを停止しておきます。
- **Settings** の **Connection** にある **rex for the Plex apps** をオフにしてください。そうすると zurg は rex へのデータ送信を止めます。

## アプリが送信する内容と送信先 {#what-the-app-sends-and-where}

zurg+rex には広告もアナリティクスもありません。デバイスから外に出るものは次のとおりです。

| 送信先 | 内容 | いつ |
|---|---|---|
| GitHub | サインイン情報と、スポンサー向けリリースのリクエスト | サインインしたときと、**Updates** で更新を確認したとき |
| あなたのプロバイダー | アカウントのトークンまたは Usenet のログイン情報、ライブラリとファイルへのリクエスト | ライブラリが動いている間 |
| debridmediamanager.com | リリース名（それぞれが何かを調べるため）。DMM API キーを入力している場合はそのキーも含む | rex をオンにしてライブラリが動いている間 |
| plex.tv と Plex のメタデータサービス | サインインコードのリクエスト。その後、ポスターや説明を取得するためのサーバー名、アドレス、タイトルの ID | Plex にサインインするときと、サインインした状態で rex が動いている間 |
| debridmediamanager.com (rex-direct) | rex の識別子、Plex が発行したサーバートークン、IP アドレスとポート（Plex アプリが HTTPS で接続できるように） | Plex にサインインした後、6 時間ごと |
| 各アドオンの Web サイトと追加したリポジトリ | アドオンが要求する内容 | アドオンが同期するときや、タイトルを再生するとき |
| logs.debridmediamanager.com | バージョン、デバイスのモデル、アプリとエンジンのログ、設定内容（キー、パスワード、トークンは `[redacted]` に置き換え） | **Send logs to support** の下の **Send** を押したときだけ。内容をすべて確認した後に限ります。7 日後に削除されます |

GitHub トークンはデバイス上で暗号化されて保存されます。アプリをアンインストールすると、アプリが保存していたものはすべて削除されます。

## 制限 {#limits}

- **The device is the server.** Keep it on, connected and plugged in. Converting video is slow on a cheap box.
- **It plays at home.** Away from home, Plex apps need an HTTPS address that reaches the device, which needs a port forward on your router. See [Use it outside your home](../../rex/with-zurg.md#use-it-outside-your-home-optional).
- **Usenet needs 64-bit Android.** A 32-bit device runs debrid libraries only.
- **Not on Google Play.** It updates from inside the app, under **Updates**.

## トラブルシューティング {#troubleshooting}

| 表示される内容 | 対処方法 |
|---|---|
| GitHub のダウンロードページで 404 が表示される | スポンサーのアカウントで GitHub にサインインし、[招待を承諾](https://github.com/debridmediamanager/zurg/invitations)してください。まだスポンサーでない場合は [gatekeeper](https://gatekeeper.debridmediamanager.com/) をご覧ください |
| **No engine is installed. zurg needs one before it can serve your library.** | **Install an engine** を押して、Android にインストールを許可してください |
| **No engine is available in the sponsor releases for this device yet.** | 最新の nightly には、お使いのプロセッサ向けのエンジンがありません。サポートで相談してください |
| **This is a 32-bit device. Debrid libraries are supported; Usenet needs 64-bit Android.** | debrid アカウントを追加するか、Usenet を使うなら 64 ビットの端末を使ってください |
| **The Plex code expired. Ask for a new one.** | **Sign in to Plex** をもう一度押して、10 分以内に新しいコードを入力してください |
| Plex アプリにサーバーが表示されない | Plex アプリを、ステップ6で使ったアカウントでサインインしてください。両方の端末は同じホームネットワークに接続したままにしてください |
| タイトルがファイル名だけで、ポスターが表示されない | DMM の API キーを入力するか（[タイトル名を増やす](#get-more-titles-named)を参照）、Plex アプリで **Fix Match** を使ってください |
| アドオンの下に **Needs an update** と表示される | このバージョンのアプリでは、そのアドオンのコピーをもう実行できません。リポジトリを更新して **Update** を押してください。その間もタイトルは残ります |
| 画面を消すと停止する | バックグラウンドでの動作を再度許可し、[Don't kill my app](https://dontkillmyapp.com/) を確認してください |
| アップデート後にアプリにエンジンがなくなる | **Updates** からエンジンを一度インストールしてください。プロバイダーと設定はそのまま残ります |

サポートからログを求められた場合は、**Logs** を開いて **Send logs to support** を押してください。送信前に内容をすべて確認できます。そのあと **Send** を押して、表示されたコードを投稿してください。

困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP) の **zurg-support** フォーラムで質問してください。
