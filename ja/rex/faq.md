# rex の質問 {#rex-questions}

rex のインストール前後によく聞かれることへの短い回答です。各回答から詳しいガイドにリンクしています。

## インストール前に {#before-you-install}

### rex とは? {#what-is-rex}

Official Plex アプリ向けのメディアサーバーで、ファイルは一切持ちません。お使いのアプリには、ポスター、シーズン、視聴履歴、「続きから見る」を備えた Plex サーバーがもう 1 つ増えたように見えます。**ソース** は rex にライブラリの中身を伝え、各ファイルを配信します。再生を押すと rex がストリーミングするので、事前にダウンロードする必要はありません。

rex は独立したサーバーです。Plex Media Server のプラグインではなく、そのために Plex が必要なわけでもありません。両方を使いたい場合は、Plex と並べて動かしてください。名前の意味は [rex をインストールする](any-source.md#step-1-install-rex) で説明しています。2 つの移行方法は [Plex から rex に移行する](from-plex.md) で扱っています。

### 料金はかかりますか? {#what-does-it-cost}

rex は個人利用であれば無料です。有料プランはありません。ソースコードは PolyForm Noncommercial ライセンスのもとで公開されています。商用利用は認められていません。すべてのビルドは [GitHub Releases](https://github.com/debridmediamanager/rex/releases) で公開されており、Android アプリは [rex for Android の](https://github.com/debridmediamanager/rex-android/releases) リリースで公開されています。

周辺のものには費用がかかる場合があります:

| | |
|---|---|
| [rex-stremio](stremio.md)、ソースとして使う自分のアプリやアドオン | 無料 |
| zurg nightly（debrid や Usenet ライブラリのソース） | [DMM のスポンサー](https://gatekeeper.debridmediamanager.com)向けの特典 |
| DMM API キー（zurg で DMM の完全一致を使うため） | 任意。DMM のスポンサーになると入手できます |
| rex の Docker イメージ | 無料で公開。Linux 向け: [Docker での rex 実行](any-source.md#run-rex-in-docker) |

### Plex アカウントは危険になりますか? {#is-my-plex-account-at-risk}

rex は Plex が作ったものではなく、rex を登録したアカウントは Plex に停止される可能性があります。rex 専用に作った**新しい無料の Plex アカウント**を使い、それをご自分のアカウントに共有してください。視聴履歴、フレンド、Plex Pass はご自分のアカウントに残ります。手順は [Plex アカウントに追加する](any-source.md#step-3-add-it-to-a-plex-account) にまとめています。rex の利用はご自身の責任でお願いします。

### どの Plex アプリで動きますか? {#which-plex-apps-work}

| アプリ | テスト状況 |
|---|---|
| Plex Web (app.plex.tv) | 一番多く試しています。ブラウズ、再生、変換、字幕、音楽、Live TV、そして両方とも無料アカウントでの外出先での再生 |
| Plex for Android (スマホ) | Pixel 6では再生、変換、[プロバイダーからのダウンロード](direct-download.md)。エミュレーターでは音楽とLive TV |
| Plexamp | Androidエミュレーターで、アーティスト画像とプレイリストを含む音楽ライブラリのブラウズと再生 |
| Plex for iOS | iPadで再生と変換。Dolby Visionにはアプリのバグがあります（下記参照） |
| Plex for Apple TV | 再生。ライブラリ内のライブチャンネルを含む |
| Plex Desktop | Plex for Mac で再生と変換 |
| Plezy | Pixel 6で再生と、プロバイダーからのダウンロード |
| Plex HTPC | まだ未テスト |
| Plex for Android TV、NVIDIA Shield、Google TV | まだ未テスト |
| Plex for Roku | まだ未テスト |
| スマートTVアプリ（Samsung、LGなど） | まだ未テスト |
| Infuse | まだ未テスト |

外出先からの利用は、Plex Webのみテスト済みです。

### 4K、HDR、Dolby Vision は再生できますか? {#does-it-play-4k-hdr-and-dolby-vision}

Yes. ファイルは元の画質のまま再生されます。rex はファイルをそのままアプリに渡し、そのファイルを再生できるかどうかはアプリが判断します。アプリがファイルをそのままでは再生できない場合は、FFmpeg が設定されていれば rex が変換します ([Converting video](any-source.md#converting-video-optional))。変換では HDR と Dolby Vision を標準の映像に変換します (Settings, Transcoder, **Enable HDR tone mapping**、初期設定ではオン)。可能な場合はグラフィックスチップで処理されます。Intel の OpenCL ランタイムがインストールされていれば、小型の Intel マシン (J4105) でも 4K HDR10 と Dolby Vision プロファイル 5 を 1080p に、ほぼリアルタイムで変換できます。

FFmpeg がないと、アプリで再生できないファイルには "This server is not powerful enough to convert video" と表示されます。すべてのタイトルがすべてのデバイスでこの表示になる場合、解決策は FFmpeg ではありません。[Nothing plays](#nothing-plays-or-every-app-says-it-is-not-powerful-enough) を参照してください。

**Plex for iOS と Dolby Vision。** Plex for iOS 2026.20.0 は、Dolby Vision ファイルをそのままの状態で再生すると 0:00 で止まったままになります。同じファイルを配信する実際の Plex Media Server でも同じように止まるため、原因はアプリ側にあります。HDR10 と SDR の 4K ファイルは再生できます。

### Plex Pass は必要ですか? {#do-i-need-plex-pass}

いいえ。rex は、登録されているアカウントに Plex Pass があることを Plex アプリに伝えるので、無料アカウントでも外出先での再生や動画の変換が使えます。外出先での再生は、両側とも無料アカウントを使った Plex Web で確認しました。他のアプリでは外出先での動作はまだテストしていません。映画のエディション、Dashboard、Downloads、イントロやエンディングのスキップ、その他の [Movie and TV capabilities](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities) も動作します。ただし、アプリ独自のルールが適用される場合があります。

### オフラインで見るためにダウンロードできますか? {#can-i-download-for-offline-viewing}

Plex アプリに **Downloads** があります。rex は、ダウンロード用のファイルを自分のマシン上で準備します。元のファイルのままのものと、FFmpeg で変換したものがあります。準備したファイルは `rex.db` の隣にあるフォルダに保存され、アプリが取りに来るまで残ります。rex に登録しているアカウントは、いつでもダウンロードできます。共有している相手は、共有設定でダウンロードが許可されている必要があります（[rex の共有](sharing.md#what-each-person-may-see-and-do)）。アプリ側で独自のルールが適用されることもあります。変換したダウンロードには、テキスト字幕は含まれません。スマホにダウンロードして、オフラインで見る機能はまだテストしていません。

### 複数の人がそれぞれの履歴で使えますか? {#can-several-people-use-it-each-with-their-own-history}

はい。rex を共有した相手は、それぞれ自分のアカウントでサインインし、視聴済みの状態、Continue Watching、評価、プレイリストを個別に持てます。古い Plex サーバーから視聴履歴をコピーすることもできます（[視聴履歴を取り込む](import-watched.md)）。子ども向けの managed users を含め、手順は [家族や友人と rex を共有する](sharing.md) にまとめてあります。

### どんなハードウェアが必要ですか? {#what-hardware-does-it-need}

マシンは常時稼働している必要があります。対応OSは、Linux（amd64またはarm64、glibc 2.35以降、つまりUbuntu 22.04以降）、macOS（Intel または Apple Silicon）、64ビット版Windowsです。Androidの携帯電話、タブレット、TVボックスでは、[rex for Android](https://github.com/debridmediamanager/rex-android)を使うと、rexとそのアドオンを無料で動かせます。また、スポンサー限定のzurg+rexアプリ（スマホ上でPlexサーバーを動かすもの）では、zurgとrexを一緒に動かせます（[Androidガイド](../zurg/guides/android.md)を参照してください）。

**メモリ:** 1 GB を割り当ててください。4,062本の映画と656本のシリーズがあるライブラリで、rexは起動時に500 MB未満、ライブラリを閲覧している間は約730 MBを使っていました。動画の変換には、さらにメモリが必要です。

**ディスク:** 映画の保存には不要です。rexはライブラリを`rex.db`に保存します。ダウンロードや、分析で作られる画像（シークプレビュー、チャプター画像）も、使う場合はその横に保存されます。

**変換:** FFmpegを使う場合のみです。グラフィックチップがあると高速になります。小型のIntelチップでは、1080pの映画の変換が約2秒で始まりました。各システムでrexがどのチップを使うかは、[By platform](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#by-platform)にまとめてあります。macOSでは、常にプロセッサで変換されます。

### ローカルのファイルを読み込みますか? {#does-it-read-my-local-files}

いいえ。rex はフォルダやディスクをスキャンすることはなく、マウントも必要ありません。すべてのファイルは HTTP 経由でソースから取得します。自分のディスク上のファイルも使えますが、それを配信する何かが必要で、そのファイルについて rex に伝える必要があります。詳しくは [rex with your own app](any-source.md) を参照してください。

### Usenet にも対応していますか? {#does-it-work-with-usenet}

はい、Usenet を読めるソース（zurg など）を通せば可能です。rex は Usenet プロバイダーとは直接やり取りしません。ソースがファイルを読み取り、通常のファイルとして rex に配信します。zurg は [Usenet](../zurg/guides/usenet.md) の手順で設定し、[zurg と組み合わせた rex](with-zurg.md) の手順どおりに rex の接続先を zurg に向けてください。

### zurg は必要ですか? {#do-i-need-zurg}

いいえ。zurg は複数あるソースの一つにすぎません。rex は、フィード API を話せるものなら何でも受け付けます。

- [独自のアプリで rex](any-source.md): HTTP でファイルを配信するアプリなら何でも
- [Stremio のアドオンで rex](stremio.md): Stremio アドオンのカタログを使う
- [zurg で rex](with-zurg.md): デブリッドのアカウントまたは Usenet を使う
- [rex アドオンを作る](addons.md): ホームビデオ、録画、チャンネルなど。自作のプログラムを使い、出発点として三つの[チュートリアル](addon-home-videos.md)があります

複数のソースで、同じ Movies と TV のライブラリを埋めることができます。

### ポート開放は必要ですか? {#do-i-need-to-forward-a-port}

自宅外では使えません。自宅のネットワーク内にいる Plex アプリは、ルーターの設定を変えなくても rex を見つけられます。app.plex.tv も、[rex 直接接続](any-source.md#rex-direct)で得られる HTTPS アドレスを使えば利用できます。

外出先での視聴や別の世帯での利用には、rex に専用のアドレスが必要です。一番簡単な方法は、ポート転送を 1 つ設定することです（[rex 直接接続](any-source.md#rex-direct)）。IPv6 があり、グローバル IPv4 がない場合は、[IPv6 経由の rex 直接接続](any-source.md#rex-direct-over-ipv6)を使ってください。[Tailscale serve](any-source.md#tailscale-serve) は、Tailscale を動かしている端末であればポート転送が不要です。各方法の比較は[自宅外で使う（任意）](any-source.md#use-it-outside-your-home-optional)にまとめています。

### できないことは何ですか? {#what-does-it-not-do}

チューナーや DVR はありません。音楽、ライブ TV、写真には、それらを送ってくれるソースが必要です。[rex での音楽再生](music.md)と[rex でのライブ TV](live-tv.md)を参照してください。zurg は漫画を写真として送るので、Plex Web で表示されます。Plexamp のラジオミックスとステーションは表示されません。rex にはリレー機能がないため、外出先から使うには専用のアドレスが必要です([家の外で使う](any-source.md#use-it-outside-your-home-optional))。

## インストール後に {#after-you-install}

### アプリに Plex のバージョンと「Check for Updates」が表示されるのはなぜですか? {#why-does-the-app-show-a-plex-version-and-check-for-updates}

rex は自分自身をアプリや plex.tv に Plex Media Server として名乗るため、アプリには Plex Media Server のバージョン番号が表示されます。その番号は rex のものではありません。**Check for Updates** は、サーバーが最新だと必ず答えます。rex は自分で更新しないからです。rex を更新するには、[Updating](any-source.md#updating) の手順に従って新しい nightly をダウンロードしてください。

### ブラウザで port 32400/web を開いてもライブラリが表示されないのはなぜですか? {#why-does-my-browser-at-port-32400web-not-open-a-library}

rex には独自の Web アプリがありません。`http://<rex's LAN IP>:32400/web` を開くと、短いステータスページが表示されます。視聴は Plex アプリ、または [app.plex.tv](https://app.plex.tv) のブラウザで行ってください。

![まだ claim されていない間に rex が /web で表示するページ](../assets/rex/80-rex-web-page.webp)

### 何が自分のマシンの外へ送信されますか? {#what-leaves-my-machine}

- **plex.tv、起動時と1日に1回（登録の有無に関係なく）:** サーバーのID、名前、バージョンを送り、Plexの公開リリース一覧で最新のバージョン番号を確認します。
- **plex.tv、Plexアカウントに登録後:** claim、サーバーのアドレス（LANアドレスとHTTPSアドレス）、ライブラリ名。
- **Plexのメタデータサービス、登録後:** 各タイトルのID。名前、ポスター、あらすじ、エピソードを取得するためです。**Search Subtitles** による字幕検索や、人ごとの自動字幕設定では、ファイル名とフィンガープリントを送ります。
- **アートワークのホスト、アプリが表示するとき:** ソースが指定するポスターや画像へのリクエスト。
- **DMM、rex-direct用、登録後は6時間ごと:** サーバーのID、Plexアカウント上のトークン、LAN IP。DMMはplex.tvに問い合わせて、そのサーバーがあなたのものか確認し、公開IPを確認して、rex-directの名前をそのサーバーとLAN IPに向けます。マシンにグローバルIPv6アドレスがあれば、rexはそれも送ります。起動後（またはclaim後）1分後に送り、その後は6時間ごとに送ります。DMMが接続して同じサーバーに届くか確認するたびにも送ります。`REX_DIRECT_URL=off` で無効にできます。
- **ソース（再生時と削除時）:** 再生するファイルへのリクエストと、削除（下記）。
- **古いPlexサーバー（[視聴履歴を持ち込む](import-watched.md)場合のみ）:** 視聴履歴へのリクエスト。
- **Webhook（設定した場合のみ）:** 設定したアドレスへのイベント。

rexは、リリースが何かを誰にも尋ねません。決めて伝えるのはソースです。たとえばzurgはDMMに尋ねます（[DMMがファイルを配置する理由](with-zurg.md#why-dmm-places-the-files)）。

### Plex アプリで削除するとファイルも消えますか? {#does-deleting-in-a-plex-app-delete-the-file}

はい。rex が登録されているアカウントでサインインした Plex アプリで映画やエピソードを削除すると、Plex サーバーがディスクからファイルを消すのと同じように、ソース側のファイルも削除されます。debrid アカウントのソース（zurg など）の場合は、そちらでファイルが削除されます。ソースが削除を拒否した場合は、タイトルはそのまま残り、アプリに削除できなかったと表示されます。共有している相手は削除できません。オフにする方法は [Plex アプリでの削除](any-source.md#step-5-watch-something) で説明しています。

### 何も再生されない、またはすべてのアプリで「not powerful enough」と表示される {#nothing-plays-or-every-app-says-it-is-not-powerful-enough}

Play を押した直後の rex のログを見てください。そこに `upstream failed` や `502` が出ている場合、rex はソースがそのアドレスで接続できていません。FFmpeg をインストールしても、これは解決しません。

よくある原因は、Windows や macOS の Docker Desktop で動かしている zurg です。[zurg と組み合わせた rex](with-zurg.md#when-something-is-wrong) または [独自のアプリと組み合わせた rex](any-source.md#when-something-is-wrong) の `upstream failed` の行で、アドレスを確認し、何を変更すればよいかを説明しています。

一部のファイルだけが失敗する場合（多くは Web ブラウザでだけ起きます）は、デバイスがそのままの形式では再生できないことが原因です。[動画の変換](any-source.md#converting-video-optional) を設定してください。

### タイトルが間違って一致しました。どう直しますか? {#a-title-is-matched-wrong-how-do-i-fix-it}

ソースが各ファイルの正体を決め、rexはそのタイトルを表示します。rexに登録されているアカウントでサインインし、**Fix Match**を使ってください。rexは選んだ内容を保持し、zurgがそうしているように、ソースがそれを読み戻して、そのリリースの一致情報として残すこともできます([DMMがファイルを配置する理由](with-zurg.md#why-dmm-places-the-files))。

### ヘルプはどこで得られますか? {#where-do-i-get-help}

[Getting help](../guides/remote-help.md) では、どこで質問すればよいか、何を含めるべきかを説明しています。質問先は [Discord](https://discord.com/invite/7u4YjMThXP) の **rex-support** フォーラムで、スポンサー向けのリモートサポートもあります。
