# rex for Android

rex は、ファイルを一切持たない Plex アプリ向けのメディアサーバーです。rex for Android を使えば、コンピューターがなくてもスマートフォン、タブレット、Android TV、Google TV、Fire TV で動かせます。お使いの機器の Plex アプリは、他の Plex サーバーと同じように rex を見つけて、そこから再生します。

再生できるものは **アドオン** から来ます。最初から入っているのは Internet Archive のパブリックドメイン映画です。Stremio のアドオン、YouTube、Spotify などの追加アドオンは、アプリ内からインストールできます。

rex for Android は無料です。デブリッドのアカウントや Usenet も使いたい場合は? zurg+rex は、zurg を内蔵した Plex サーバーをスマートフォン上で動かすもので、スポンサーシップ付きで提供されています。詳しくは [zurg+rex for Android](../zurg/guides/android.md) をご覧ください。

## 始める前に {#before-you-start}

| 必要なもの | 理由 |
|---|---|
| Android 8.0以降のデバイス | 電話、タブレット、Android TV、Google TV、Fire TV |
| Plexアカウント | rexは、そのアカウントでサインインしたPlexアプリに表示されます。無料アカウントで十分です |
| 視聴するデバイスのPlexアプリ | Plex for Android、Android TV、iPhone、スマートテレビ、Plex Web、Plexamp |

まだGoogle Playにはありません。APK（アプリのファイル）を自分でインストールする必要があります。

## ステップ 1. ダウンロードする {#step-1-download-it}

[最新のリリース](https://github.com/debridmediamanager/rex-android/releases/latest)をデバイスで開き、お使いのプロセッサ向けのファイルをダウンロードしてください。

| お使いのデバイス | ダウンロード |
|---|---|
| ほとんどのスマートフォン、タブレット、テレビボックス（64ビット） | `rex-android-…-arm64-v8a.apk` |
| 古いものや安価な32ビットのボックス（Fire TV Stick を含む） | `rex-android-…-armeabi-v7a.apk` |
| PC 上のエミュレーター | `rex-android-…-x86_64.apk` |

迷ったら、まず `arm64-v8a` を試してみてください。1つのファイルでスマートフォンもテレビも動きます。

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

**Addons** に、インストールしたアドオンが一覧で表示されます。各アドオンには、そのタイトルと最後に同期した日時が表示されます。ボタンは **Sync now**、**Settings**、**Log**、**Remove** の4つです。スマホでは、ボタンの並んだ行を横にスワイプすると、すべて見られます。**Enabled** スイッチを使うと、アドオンを削除せずにオフにできます。

アドオンは **repositories** から提供されます。repositories とは、アドオンを収めた git リポジトリのことです。アプリは最初から [rex-addons](https://github.com/debridmediamanager/rex-addons) が追加された状態で起動します。ここには次のアドオンがあります:

| アドオン | 追加されるもの |
|---|---|
| Internet Archive | パブリックドメインの映画。最初からインストール済み |
| Stremio addons | Stremio のアドオンにある映画とシリーズのカタログ。再生は、それぞれのストリームアドオンが提供するストリームから行われます |
| YouTube | あなたの YouTube プレイリスト。コードを使ってサインインします |
| Spotify | あなたの Spotify ライブラリを、Plex と Plexamp で聴ける音楽として追加します。YouTube アドオンにサインインしておく必要があります |

**インストールするには。** **Repositories** の下で、リポジトリの横にある **Addons** を押し、次にアドオンの下の **Install** を押します。rex は、そのアドオンが接続できるウェブサイトを表示し、もう一度確認してから同期を始めます。

**サインインするには。** アカウントが必要なアドオンには **Sign in to start.** と表示されます。その **Sign in** ボタンを押してください。表示されたページを任意のデバイスで開き、画面に出たコードを入力します。

**repository を追加するには。** **Add a repository** の下に、そのリンクを入力します (`github.com/user/repo` だけで十分です)。次に **Add** を押します。信頼できる人が作ったアドオンだけをインストールしてください。自分でアドオンを作りたい場合は [rex-addons](https://github.com/debridmediamanager/rex-addons) を参照してください。

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

| 表示される内容 | 対処法 |
|---|---|
| **App not installed as app isn't compatible with your phone.** | プロセッサー用のファイルを間違えています。ステップ1の表にあるもう一方のファイルを試してください |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | ポートとして `32500` を入力してください |
| **Use a number from 1024 to 65535** | ポートは1024から65535までの数字にしてください |
| Plexアプリにサーバーが表示されない | ステップ4で使ったのと同じアカウントでPlexアプリにサインインし、両方の端末を同じホームネットワークに接続したままにしてください |
| ライブラリが空っぽ | 最初の同期がまだ実行中です。**Status** に作品数が表示されるまで待ってください |
| アドオンの下に **Sign in needed** と表示される | そのアドオンの **Sign in** ボタンを押して、コードを入力してください |
| **That isn't a repository link. Try github.com/user/repo.** | リポジトリのリンクを入力してください。例: `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | リンクが間違っているか、リポジトリが非公開です。ブラウザで確認してください |
| 画面を消すとrexが止まる | ステップ3のバックグラウンド設定をやり直し、[Don't kill my app](https://dontkillmyapp.com/) も確認してください |

**Logs** には、rexとアドオンが最近出力した内容が、キーやパスワードを隠した状態で表示されます。サポートからログを求められたら、**Send logs to support** を押してください。送信前に内容をすべて確認できます。その後 **Send** を押し、表示されたコードを投稿してください。

行き詰まったら、[Discord](https://discord.com/invite/7u4YjMThXP) の **rex-support** フォーラムで質問してください。
