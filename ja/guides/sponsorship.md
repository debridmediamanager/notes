# スポンサーシップで得られるもの {#what-a-sponsorship-gives-you}

DMMは無料です。スポンサーからの支援で、ホスティング費用を賄い、zurgとrexの開発を続けられています。このページでは、すべての特典と、その設定場所を紹介します。

[gatekeeper](https://gatekeeper.debridmediamanager.com/)でスポンサーになります。そこにサインインすると、DMMのAPIキーが表示されます。**Open DMM with this key**を押すと、そのブラウザでキーが連携されます。キーを求めてくる他のサービスにも、同じキーを追加してください。キーはパスワードと同じ働きをするので、外部に漏らさないようにしてください。

特典はスポンサーシップに連動しています。スポンサーシップが終了すると、次のリクエストからDMMは特典を止めます。すでにインストールしたJellyfinやEmbyのプラグインは動き続けますが、新しいダウンロードやアップデートは止まります。gatekeeperは次回のチェック時に、zurgへのアクセスとDiscordのロールを取り消します。**Reset key**を押すと、古いキーがすべての場所で一度に無効になります。

## zurg

| 手に入るもの | 場所 |
|---|---|
| すべてのプロバイダーと Usenet に対応したナイトリービルドと Docker イメージ | GitHub の招待を承諾した後に [zurg setup](../zurg/setup/index.md) |
| zurg+rex の Android アプリ（スマホ上で動く Plex サーバー） | GitHub の招待を承諾した後に [Android guide](../zurg/guides/android.md) |
| zurg の完全なソースコード | GitHub 上のプライベートリポジトリ |
| rex と Plex 向けに名前を付けたすべてのリリース | [zurg config](../zurg/reference/config.md) にある `dmm_api_key` |
| ファイルを先に読み込まずに DMM のメディア詳細を取得でき、リリースを追加する前に言語チェックも行えます | `dmm_api_key` 以外は不要 |
| 有効にすると `__magic__` フォルダーを自動で整理 | [\_\_magic\_\_](../zurg/guides/magic.md) |
| zurg が DMM のウォントリストを取得 | [DMM のウォントリスト](../zurg/guides/dmm-wanted.md) |
| 自分のインデクサーがない場合、DMM の Usenet とトレントのインデクサーを検索 | `dmm_api_key` に加えて Usenet プロバイダー、またはトレントを追加できる debrid アカウント |
| 各タイトルの原語に合わせてリリースを選択 | [audio and subtitle languages](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) の `original` |
| どのインデクサーにもない欲しい映画を、公式 YouTube アップロードからストリーミング | [YouTube から映画をストリーミングする](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

`dmm_api_key` の機能には zurg のナイトリービルドが必要です。無料の公開ビルドには含まれていません。

## DMM

| 得られるもの | 場所 |
|---|---|
| zurg が新しいエピソードやアップグレードを取得するウォンテッドリスト。DMM、Kodi、Trakt、MDBList と TMDB のリスト、または Radarr か Sonarr のバックアップから埋められます | [DMM ウォンテッドリスト](../zurg/guides/dmm-wanted.md) |
| Seerr、Overseerr、Jellyseerr からのリクエストがウォンテッドリストに入ります | [DMM 経由の Seerr](../dmm/seerr.md) |
| Easynews の結果をワンクリックで zurg に送れます | 映画やシリーズのページにある DMM の Easynews の結果 |
| DMM を Usenet 用の Newznab インデクサーとして使えます | DMM の [Newznab ページ](https://debridmediamanager.com/newznab) |
| DMM を Torznab インデクサーとして使えます。Real-Debrid、AllDebrid、Debrid-Link、TorBox、Premiumize、Offcloud のキャッシュ済みのみのフィードが使えます。TorBox、Premiumize、Offcloud では連携したサービスキーも必要です | DMM の [Torznab ページ](https://debridmediamanager.com/torznab)。TorBox、Premiumize、Offcloud は連携したサービスキーも必要です |
| デブリッドと Usenet のライブラリ用の Jellyfin プラグインが 7 つ、マウントなしのデブリッドライブラリ用の Emby プラグインが 6 つ | DMM の [Jellyfin](https://debridmediamanager.com/jellyfin) と [Emby](https://debridmediamanager.com/emby) のページ |
| タイトルごとの他のストリームが Stremio Cast と Kodi で 5 つではなく 10 あります | DMM の Real-Debrid、TorBox、AllDebrid の Settings。ほかのサービスは各プロバイダーの Cast ページ |
| NZB アップロードが優先され、1 日あたりの Usenet 容量が 300 GB ではなく 2 TB になります | DMM の Usenet タブ |
| Sonarr と Radarr も同じ優先度と容量になります | DMM の [SABnzbd ページ](https://debridmediamanager.com/sabnzbd) で、Password に DMM の API キーを入力 |
| Real-Debrid へのトレントのアップロードが 1 つではなく 3 つ同時にできます | DMM の検索結果とライブラリにあるアップロードボタン |
| DMM Wanted に追加ボタンと Kodi 内の Wanted フォルダ | DMM の [Kodi ページ](https://debridmediamanager.com/kodi) で Kodi をペアリング |
| リリース名、キャッシュ確認、メディア詳細、メタデータ用の DMM API | [APIドキュメント](https://debridmediamanager.com/api-docs) |

## rex

rex は無料で、スポンサーシップも不要です。Android でも使えます。[Android 版 rex](../rex/android.md) を使うと、スマホや TV ボックスで rex とそのアドオンを動かせます。スポンサーは、上の表にある zurg+rex も使えます。これは、デバッドやUsenet のライブラリをデバイス上の rex につなぐものです。キーがあれば、[rex-stremio](../rex/stremio.md) が DMM がすでにプローブ情報を持っているトレントのデバッドストリームを追加します。各トレントを個別にプローブする代わりに、数秒で済みます。キーは rex-stremio の **DMM** 欄に貼り付けてください。オフにしない限り、トレントファイルのプローブ結果は DMM と共有されます。

## ヘルプ {#help}

| 得られるもの | 場所 |
|---|---|
| 視聴しながら、自分のターミナルで zurg と rex の無料リモートサポートを受けられます | [ヘルプの入手方法](remote-help.md) |
| Discord での Sponsor ロール | gatekeeper で Discord を接続 |

## お金を払わずに手に入れる {#earn-it-without-paying}

DMM の[リクエストボード](https://debridmediamanager.com/requests)でリクエストに応えてください。10件ごとに、上記の DMM 特典が7日分もらえます。同じ人による対応は1日1回だけカウントされます。ボードの無料 gatekeeper アカウントにキーを紐付けると、特典を受け取れます。

獲得した期間で開けるのは、上記の DMM テーブルだけです。zurg のナイトリービルド、ソースコード、Discord ロール、リモートサポート、Android アプリは対象外で、有料のスポンサーシップが必要です。`dmm_api_key` の機能にもナイトリービルドが必要です。

困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP) の **dmm-support** フォーラムで聞いてください。
