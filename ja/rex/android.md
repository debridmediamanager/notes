# rex for Android

rex は、Plex アプリ向けのメディアサーバーです。ファイルは一切持ちません。rex for Android を使えば、スマートフォン、タブレット、Android TV、Google TV、Fire TV などで、パソコンなしで動かせます。お使いの機器の Plex アプリは、rex を他の Plex サーバーと同じように見つけて、そこから再生します。

再生する内容は **addons** から来ます。最初から入っているのは Internet Archive のパブリックドメイン映画です。Stremio のアドオンや YouTube、Spotify などのアドオンは、リポジトリを追加すれば、アプリ内からインストールできます。

rex for Android は無料です。debrid アカウントや Usenet も使いたいですか？ それなら zurg+rex がおすすめです。zurg を内蔵した Plex サーバーをスマートフォンで動かせて、スポンサー特典が付いています: [zurg+rex for Android](../zurg/guides/android.md)

## 始める前に {#before-you-start}

| 必要なもの | 理由 |
|---|---|
| Android 8.0以降のデバイス | 電話、タブレット、Android TV、Google TV、Fire TV |
| Plexアカウント | rexは、そのアカウントでサインインしたPlexアプリに表示されます。無料アカウントで十分です |
| 視聴するデバイスのPlexアプリ | Plex for Android、Android TV、iPhone、スマートテレビ、Plex Web、Plexamp |

まだGoogle Playにはありません。APK（アプリのファイル）を自分でインストールする必要があります。

## ステップ 1. ダウンロードする {#step-1-download-it}

デバイスで、お使いのプロセッサ向けのファイルをダウンロードしてください。各リンクは常に最新版です。

| お使いのデバイス | ダウンロード |
|---|---|
| ほとんどのスマートフォン、タブレット、TVボックス（64ビット） | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| 古い、または安価な32ビットのボックス（Fire TV Stickなど） | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| PC上のエミュレーター | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

すべてのバージョンとその変更点は、[リリースページ](https://github.com/debridmediamanager/rex-android/releases)にあります。

迷ったら、まず `arm64-v8a` を試してください。このファイル1つでスマートフォンもTVも動きます。

## ステップ 2. インストールする {#step-2-install-it}

開いてください、ダウンロードしたファイルを。Android が最初に確認してきます:

1. 「この提供元からの不明なアプリのインストールは許可されていません」と表示されます。**設定** を押し、**この提供元を許可** をオンにしてから戻ります。
2. **インストール** を押します。

ブラウザがないテレビボックスでは、APK を開ける downloader アプリでファイルをダウンロードしてください。

**表示されるはずの画面。** アプリ一覧に **rex** が表示されます。

## ステップ 3. rex を起動する {#step-3-start-rex}

**rex** を開きます。最初の画面に **Welcome to rex.** と表示されます。

1. **Allow notifications** を押してから **Allow** を押します。rex はバックグラウンドで動き、その通知から停止できます。
2. **Let rex keep running in the background** を押します。開いたリストで **rex** を選び、**Don't optimize** を選びます。新しい Android では **Allow background usage**、次に **Unrestricted** です。rex に戻ります。両方のボタンの先頭に ✓ が付いていれば完了です。
3. **Name** は Plex アプリでこのサーバーを表示する名前です。好みで変更してください。
4. **Port** は `32400` のままにします。この端末で別の Plex サーバーがすでに動いている場合、rex は **Another app here already uses this port, maybe a Plex server. Try 32500.** と表示します。その場合は `32500` と入力してください。
5. **Start rex** を押します。

**表示されるはずの画面。** **2 / 2** と **Sign in to Plex.** が表示されます。

## ステップ 4. Plex にサインインする {#step-4-sign-in-to-plex}

Ｐlex の **Sign in to Plex** を押します。rex にコードが表示されます。**On any phone or computer, go to plex.tv/link and enter** に従って、スマホかパソコンで plex.tv/link を開き、そのコードを入力してください。

- **On a phone or tablet** の場合は、ブラウザで Plex のページも開きます。そこには **rex for Android would like to sign in to your Plex account** と表示されるので、そこでサインインしてください。
- **On a TV** の場合は、スマホかパソコンで [plex.tv/link](https://plex.tv/link) を開き、サインインしてコードを入力してください。

Plex アプリにサインインしているアカウントを使ってください。**Skip for now** を押して、あとで **Status** からサインインすることもできます。

**表示される内容。** **Signed in. rex shows up in the Plex apps as** のあとにサーバー名が表示されれば成功です。**Done** を押してください。**Status** に **RUNNING** と **Ready for the Plex apps.** が表示されていれば準備完了です。

## ステップ 5. Plex アプリで視聴する {#step-5-watch-in-a-plex-app}

Plex の同じアカウントでサインインしている Plex アプリを開いてください。Plex がこのデバイスにインストールされている場合は、**Status** に **Open Plex** ボタンがあります。

Plex for Android では、**Libraries**、**All Libraries** の順に開き、サーバー名の下にある **Movies** を選んでください。ほかの Plex アプリでも、サーバー名の下に表示されます。

Internet Archive の初回同期には時間がかかります。テスト用のデバイスでは約 30 分かかりました。その間、rex が各映画をチェックしています。**Status** には、同期が終わるまで **Syncing** と表示され、終わると **Ready · 97 titles** のように件数が表示されます。好きな映画を選んで再生してください。

## アドオン {#addons}

**Addons** は、インストールしたものを一覧表示します。各アドオンには、そのタイトルと最後に同期した日時が表示されます。ボタンは **Sync now**、**Settings**、**Log**、**Remove** の4つです。スマホでは、ボタンの並びを横にスワイプすると全部見られます。**Enabled** のスイッチを切ると、削除せずにアドオンをオフにできます。

アドオンは **repositories**（アドオンを入れた git リポジトリ）から届きます。アプリは最初から [rex-addons](https://github.com/debridmediamanager/rex-addons) が追加された状態で起動し、Internet Archive のパブリックドメインの映画がはじめからインストールされています。さらに増やしたい場合は、[rex-community-addons](https://github.com/debridmediamanager/rex-community-addons) を追加してください（下の **Add a repository** を参照）。次のアドオンが使えるようになります。

| Addon | What it brings |
|---|---|
| Stremio addons | Your Stremio addons' film and series catalogs, played from the streams your stream addons give |
| YouTube | Your YouTube playlists. You sign in with a code |
| Spotify | Your Spotify library as music for Plex and Plexamp. Needs the YouTube addon, signed in |

**インストールする。** **Repositories** の下で、リポジトリの横にある **Addons** を押し、そのアドオンの下にある **Install** を押します。rex は、アクセスできるウェブサイトを表示して、もう一度確認してから同期を始めます。

**サインインする。** アカウントが必要なアドオンには **Sign in to start.** と表示されます。その **Sign in** ボタンを押し、表示されたページをどのデバイスでも開いて、表示されたコードを入力してください。

**リポジトリを追加する。** **Add a repository** の下にリンクを入力します（`github.com/user/repo` だけで十分です）。そして **Add** を押してください。信頼できる人が作ったものだけをインストールしてください。自分でアドオンを作りたい場合は [rex-addons](https://github.com/debridmediamanager/rex-addons) を参照してください。

## 自宅の他のデバイスで視聴する {#watch-on-other-devices-at-home}

Plex に同じアカウントでサインインしているアプリはすべて、ホームネットワーク上で rex を名前で見つけられます。テレビ、別のスマートフォン、パソコンの Plex Web などです。**Status** には、ホームでの rex のアドレスが `http://192.168.1.20:32400` のように表示されます。

ご家族が自分の Plex アカウントで一緒に見られるようにしたい場合は、[Share rex with family and friends](sharing.md) をご覧ください。

## 実行し続ける {#keep-it-running}

- rex は端末の電源が入っている間ずっと動きます。通知の **Stop** で停止できます。**Status** には **Start**、**Stop**、**Restart** があります。
- **Settings** で **Start when this device turns on** をオンにしてください。オンにしていない場合は、再起動後に rex を開いて **Start** を押す必要があります。
- 端末によっては、バックグラウンドのアプリを止めてしまうことがあります。必要な設定は [Don't kill my app](https://dontkillmyapp.com/) で確認できます。
- サーバーの名前を変えたいときは、Plex アプリで **Settings**、**General** を開き、**Friendly name** を変更してください。

## 制限 {#limits}

- **Funktioniert zu Hause.** Außerhalb deines Zuhauses brauchen Plex-Apps eine HTTPS-Adresse, die das Gerät erreicht. Dafür muss dein Router einen Port zu diesem Gerät weiterleiten. Siehe [Außerhalb deines Zuhauses nutzen](any-source.md#use-it-outside-your-home-optional).
- **Das Gerät ist der Server.** Lass es eingeschaltet, per WLAN oder Ethernet verbunden und am Strom. Wenn ein Video für einen Player umgewandelt werden muss, der die Datei nicht abspielen kann, nutzt das die Hardware des Geräts und kann auf einem günstigen Gerät langsam sein.
- **Nur, was die Addons liefern.** Auf dem Gerät selbst liegt keine Dateibibliothek.
- **Noch nicht bei Google Play.** Zum Aktualisieren installierst du die neue Datei von [den Releases](https://github.com/debridmediamanager/rex-android/releases/latest) über die alte. Öffne danach rex und tippe auf **Start**. Deine Anmeldung und Addons bleiben erhalten.

## トラブルシューティング {#troubleshooting}

| 見えるもの | やること |
|---|---|
| **App not installed as app isn't compatible with your phone.** | ファイルの選び方が間違っています。Step 1 の表から、もう一方のファイルを試してください |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | ポートとして `32500` と入力してください |
| **Use a number from 1024 to 65535** | ポートは、その範囲の数字にしてください |
| Plex アプリにサーバーが表示されない | Step 4 で使ったのと同じアカウントで Plex アプリにサインインし、両方の機器を同じホームネットワークに接続したままにしてください |
| ライブラリが空っぽ | 最初の同期がまだ実行中です。**Status** に作品数が表示されるまで待ってください |
| addon の下に **Sign in needed** と表示される | その addon の **Sign in** ボタンを押して、コードを入力してください |
| **That isn't a repository link. Try github.com/user/repo.** | リポジトリのリンクを入力してください。例: `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | リンクが間違っているか、リポジトリが非公開です。ブラウザで確認してください |
| 画面を消すと rex が止まる | Step 3 のバックグラウンド設定をやり直してください。あわせて [アプリを強制終了させない](https://dontkillmyapp.com/) も確認してください |

**Logs** には、rex と addon が最近何を伝えたかが、キーやパスワードを隠した状態で表示されます。サポートからログを求められたら、**Send logs to support** を押してください。送信前に中身をすべて確認できます。その後 **Send** を押して、表示されたコードを投稿してください。

アプリが送信する内容と送信先は、[プライバシーポリシー](android-privacy.md)に書かれています。

困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP) の **rex-support** フォーラムで聞いてください。
