# スポンサーシップで得られるもの {#what-a-sponsorship-gives-you}

DMM は無料です。スポンサーの支援で DMM のホスティング費用を賄い、zurg と rex の開発を続けられています。このページでは、すべての特典と、その設定場所をまとめています。

[gatekeeper](https://gatekeeper.debridmediamanager.com/) でスポンサーになってください。そこにサインインすると、DMM の API キーが表示されます。そのブラウザで **Open DMM with this key** をクリックすると、キーが紐づきます。キーを求めてくる他のサービスにも、同じキーを入力してください。パスワードと同じ扱いになるので、他人に見せないようにしてください。

特典はスポンサーシップに連動しています。スポンサーシップが終了すると、次のリクエストから DMM は特典を止めます。Gatekeeper は次回のチェックで zurg へのアクセスと Discord のロールを取り消します。**Reset key** を押すと、古いキーがすべての場所で一度に無効になります。

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
| zurg が新しいエピソードやアップグレードを取ってくる Wanted リスト。DMM、Kodi、Trakt と MDBList のリスト、または Radarr や Sonarr のバックアップから入れられます | [DMM wanted list](../zurg/guides/dmm-wanted.md) |
| Seerr、Overseerr、Jellyseerr からのリクエストが Wanted リストに入ります | [Seerr through DMM](../dmm/seerr.md) |
| 映画やシリーズのページにある Easynews の結果を、ワンクリックで zurg に送れます | DMM の映画やシリーズのページにある Easynews の結果 |
| DMM を Usenet 用の Newznab インデクサーとして使えます | DMM の [Newznab ページ](https://debridmediamanager.com/newznab) |
| DMM を Torznab インデクサーとして使えます。Real-Debrid、AllDebrid、Debrid-Link、TorBox、Premiumize、Offcloud のキャッシュ済みのみのフィードに対応しています。TorBox、Premiumize、Offcloud では、連携したサービスのキーも必要です | DMM の [Torznab ページ](https://debridmediamanager.com/torznab) |
| マウントしていない debrid や Usenet のライブラリ向けの Jellyfin プラグインが 7 個、debrid ライブラリ向けの Emby プラグインが 6 個あります | DMM の [Jellyfin](https://debridmediamanager.com/jellyfin) ページと [Emby](https://debridmediamanager.com/emby) ページ |
| Stremio の Cast と Kodi で、1 タイトルあたりの他のストリームが 5 件ではなく 10 件になります | Real-Debrid、TorBox、AllDebrid は DMM の Settings。それ以外は各プロバイダーの Cast ページ |
| NZB のアップロードが優先され、Usenet の上限は 1 日 300 GB ではなく 2 TB になります | DMM の Usenet タブ |
| Sonarr と Radarr にも同じ優先度と上限が適用されます | DMM の [SABnzbd ページ](https://debridmediamanager.com/sabnzbd) で、Password に DMM の API キーを入力します |
| Real-Debrid へのトレントのアップロードを、1 回に 1 件ではなく 3 件同時に行えます | DMM の検索結果とライブラリにあるアップロードボタン |
| DMM の Wanted への追加と、Kodi 内の Wanted フォルダーを使えます | DMM の [Kodi ページ](https://debridmediamanager.com/kodi) で Kodi をペアリングします |
| スポンサーキーでサインインすると、別のデバイスでも設定が復元されます | DMM の Settings |
| リリース名の確認、キャッシュのチェック、メディア詳細、メタデータ用の DMM API を使えます | [API docs](https://debridmediamanager.com/api-docs) |

## rex

rex は無料で、スポンサーは必要ありません。Android 版は、スポンサー限定の zurg+rex アプリにのみ含まれています。キーがあると、[rex-stremio](../rex/stremio.md) は、DMM がすでにプローブ結果を持っているトーレントのデバッドストリームを、数秒で追加します。各トーレントを個別にプローブする必要はありません。キーは rex-stremio の **DMM** フィールドに貼り付けてください。設定をオフにしない限り、トーレントファイルのプローブ結果は DMM と共有されます。

## ヘルプ {#help}

| 得られるもの | 場所 |
|---|---|
| 視聴しながら、自分のターミナルで zurg と rex の無料リモートサポートを受けられます | [Getting help](remote-help.md) |
| Discord での Sponsor ロール | gatekeeper で Discord を接続 |

## お金を払わずに手に入れる {#earn-it-without-paying}

DMM の[リクエストボード](https://debridmediamanager.com/requests)でリクエストに応えてください。10件ごとに、上記の DMM 特典が7日分もらえます。同じ人による対応は1日1回だけカウントされます。ボードの無料 gatekeeper アカウントにキーを紐付けると、特典を受け取れます。

獲得した期間で開けるのは、上記の DMM テーブルだけです。zurg のナイトリービルド、ソースコード、Discord ロール、リモートサポート、Android アプリは対象外で、有料のスポンサーシップが必要です。`dmm_api_key` の機能にもナイトリービルドが必要です。

困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP) の **dmm-support** フォーラムで聞いてください。
