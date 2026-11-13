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
| zurg が DMM のウォントリストを取得 | [DMM wanted list](../zurg/guides/dmm-wanted.md) |
| 自分のインデクサーがない場合、DMM の Usenet とトレントのインデクサーを検索 | `dmm_api_key` に加えて Usenet プロバイダー、またはトレントを追加できる debrid アカウント |
| 各タイトルの原語に合わせてリリースを選択 | [audio and subtitle languages](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) の `original` |
| どのインデクサーにもない欲しい映画を、公式 YouTube アップロードからストリーミング | [Streaming a film from YouTube](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

`dmm_api_key` の機能には zurg のナイトリービルドが必要です。無料の公開ビルドには含まれていません。

## DMM

| 得られるもの | 場所 |
|---|---|
| 新しいエピソードやアップグレードを zurg が取得する Wanted リスト。DMM、Kodi、Trakt と MDBList のリスト、または Radarr か Sonarr のバックアップから入れられます | [DMM のWanted リスト](../zurg/guides/dmm-wanted.md) |
| Seerr、Overseerr、Jellyseerr からのリクエストが Wanted リストに入ります | [DMM 経由の Seerr](../dmm/seerr.md) |
| 映画や番組のページにある Easynews の結果を、ワンクリックで zurg に送れます | DMM の映画・番組ページにある Easynews の結果 |
| Usenet 用の Newznab インデクサーとしての DMM | DMM の [Newznab ページ](https://debridmediamanager.com/newznab) |
| Real-Debrid、AllDebrid、Debrid-Link、TorBox、Premiumize、Offcloud 向けに、キャッシュ済みのみのフィードを出す Torznab インデクサーとしての DMM | DMM の [Torznab ページ](https://debridmediamanager.com/torznab)。TorBox、Premiumize、Offcloud では、リンクしたサービスキーも必要です |
| マウントなしのデバッドとUsenet ライブラリ向けの Jellyfin プラグイン七つと、デバッドライブラリ向けの Emby プラグイン六つ | DMM の [Jellyfin](https://debridmediamanager.com/jellyfin) と [Emby](https://debridmediamanager.com/emby) のページ |
| Stremio Cast と Kodi で、タイトルごとの他のストリームが五件ではなく十件 | Real-Debrid、TorBox、AllDebrid は DMM の設定。その他は各プロバイダーの Cast ページ |
| NZB のアップロードを優先し、Usenet の割り当てを 300 GB ではなく 1日 2 TB | DMM の Usenet タブ |
| Sonarr と Radarr でも同じ優先度と割り当て | [DMM の SABnzbd ページ](https://debridmediamanager.com/sabnzbd) で、Password に DMM の API キーを入力 |
| Real-Debrid へのトレントのアップロードを一件ではなく同時に三件 | DMM の検索結果とライブラリにあるアップロードボタン |
| DMM Wanted への追加と、Kodi 内の Wanted フォルダ | DMM の [Kodi ページ](https://debridmediamanager.com/kodi) で Kodi をペアリング |
| リリース名、キャッシュ確認、メディア詳細、メタデータ用の DMM API | [API docs](https://debridmediamanager.com/api-docs) |

## rex

rex は無料で、スポンサーも必要ありません。Android でも使えます。[rex for Android](../rex/android.md) を使うと、スマホや TV ボックスで rex とそのアドオンを動かせます。キーを用意したら、[rex-stremio](../rex/stremio.md) が DMM がすでに確認済みのトレントのデバッグストリームを追加します。各トレントを一つずつ確認する代わりに、数秒で取得できます。キーは rex-stremio の **DMM** 欄に貼り付けてください。オフにしない限り、トレントファイルの確認結果は DMM と共有されます。

## ヘルプ {#help}

| 得られるもの | 場所 |
|---|---|
| 視聴しながら、自分のターミナルで zurg と rex の無料リモートサポートを受けられます | [Getting help](remote-help.md) |
| Discord での Sponsor ロール | gatekeeper で Discord を接続 |

## お金を払わずに手に入れる {#earn-it-without-paying}

DMM の[リクエストボード](https://debridmediamanager.com/requests)でリクエストに応えてください。10件ごとに、上記の DMM 特典が7日分もらえます。同じ人による対応は1日1回だけカウントされます。ボードの無料 gatekeeper アカウントにキーを紐付けると、特典を受け取れます。

獲得した期間で開けるのは、上記の DMM テーブルだけです。zurg のナイトリービルド、ソースコード、Discord ロール、リモートサポート、Android アプリは対象外で、有料のスポンサーシップが必要です。`dmm_api_key` の機能にもナイトリービルドが必要です。

困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP) の **dmm-support** フォーラムで聞いてください。
