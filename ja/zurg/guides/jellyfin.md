# Jellyfin の機能と対応範囲 {#jellyfin-features--capabilities}

## 設定とストレージ {#configuration--storage}
- 設定キー（[`config.md`](../reference/config.md)、`config.example.yml`）：`jellyfin_server_url`（string、デフォルトは `""`）と `jellyfin_token`（string、デフォルトは `""`）。どちらも `config.example.yml` ではコメントアウトされた状態で同梱されており、`config.simple.yml` には含まれていません。`mount_path` を設定しないと、Jellyfin を含むメディアスキャンが無効になります（`pkg/scan/scanner.go`）。
- 値はダッシュボードから設定されると、`updateConfigFileAtomic` によって `config.yml` に保存されます。Jellyfin 用の別データファイルはありません。これらのフィールドと、その `Get`/`Set` ヘルパーは `internal/config/config.go` の `zurgConfig` にあります。`ZurgConfigV1`（`internal/config/filters.go`）は、この struct をインラインで埋め込んでいます。

## 認証とサーバー検証 (QuickConnect) {#authentication--server-validation-quickconnect}
- ダッシュボードの QuickConnect の流れ:
  - `/jellyfin/check-server` は `System/Info/Public` で到達性を確認し、バージョンと名前、QuickConnect が使えるかどうかを返します（`HandleJellyfinCheckServer`、`pkg/jellyfin/auth.go:CheckServerReachable/CheckQuickConnectEnabled`）。
  - `/jellyfin/auth` は QuickConnect を開始（`InitiateQuickConnect`）し、Cookie スコープの認証セッションを作成（`pkg/jellyfin/auth_session.go`）して、バックグラウンドでのポーリングを始めます。
  - `/jellyfin/auth/status` は、`/QuickConnect/Connect` と `/Users/AuthenticateWithQuickConnect` をポーリングしながら、完了状態またはエラー状態を返します（`PollForQuickConnectAuth`、5 秒間隔で最大 60 回試行し、その後タイムアウト）。
  - `/jellyfin/server` はサーバー URL とトークンを設定に保存し、Jellyfin クライアントを再初期化します。再初期化に失敗した場合は、成功または警告のレスポンスを返します（`HandleJellyfinServerSelect`）。
  - `/jellyfin/logout` は設定をクリアし、Jellyfin を使わずにスキャナーを再初期化して、キャッシュ済みのダッシュボードのステータスを破棄します（`JellyfinStatusFetcher.ClearCache`）。
- 認証セッションマネージャーは QuickConnect のセッションを管理し、secret、code、token、ユーザー情報を保存します。10 分経過したセッションは削除されます（5 分ごとにスイープ）。また、スレッドセーフなゲッターを提供します（`pkg/jellyfin/auth_session.go`。グローバルインスタンスは `auth_global.go` にあります）。
- `pkg/jellyfin/auth.go` の QuickConnect 関連のヘルパーは、標準の `Authorization: MediaBrowser …` ヘッダーを送信します。また、自己署名証明書に対応するため、TLS 検証を無効にして動作します（`newHTTPClient`）。一方、スキャン用のクライアントは TLS 検証を無効にしていません。`mediabrowser.NewCore` はタイムアウト 30 秒の通常の `http.Client` を作成します（`pkg/mediabrowser/core.go`）。そのため、自己署名証明書の背後にあるサーバーはペアリングも検証も問題なく通りますが、セクションやリフレッシュの呼び出しは TLS で失敗します。
- 保存の前に認証情報を確認するため、トークン検証エンドポイント `/System/Info` を使います（`ValidateToken`）。

## Jellyfin クライアントの機能 (`pkg/jellyfin/client.go`) {#jellyfin-client-capabilities-pkgjellyfinclientgo}
- `Client` は、埋め込みの `mediabrowser.Core`（`pkg/mediabrowser/core.go`）をほぼそのまま包む薄いシェルです。このコアは `pkg/emby` と共有されています。両サーバーは同じコードベースから派生しているためです。独自に持つメソッドは `GetSections` だけです。スキャン（`ProcessJob`）、アクティビティ、サーバー状態、ライフサイクル、キュー、認証ヘッダー、スタック追跡はすべてコアから提供されます。
- 認証: Jellyfin への呼び出しでは、標準の `Authorization: MediaBrowser … Token="<token>"` ヘッダーを送ります。Emby のクライアントは代わりに `X-Emby-Token` を送ります。
- ライフサイクル: `NewClientWithLogger` がコアを作成します（末尾のスラッシュを削除し、URL *または* token が空の場合は警告を出して nil を返します）。その後 `StartWorker` が、`GO_TEST_MODE=1` でない限り動的スキャンワーカーを起動します。`Close` はワーカーとキューを停止します。
- スキャンキュー: 動的ジョブキューと `common.DefaultWorkerConfig` を使います。`GetJobQueueSize` はダッシュボードが読む値です（`MediaScanner.GetQueueSizes` 経由）。`GetJobQueue` は互換性のためのスタブで、キューのサイズに合わせた空のジョブのスライスを返します。
- 負荷とスタックの検出: `CheckServerLoad` は `/ScheduledTasks` をポーリングし、名前に "scan" を含む実行中のタスクを監視し、タスクごとのスタック回数を記録します。スキャンが動いているときは busy を報告します。`IsJobStuck` は、スタック判定のしきい値を超えたタスクにフラグを立てます。
- アクティビティ追跡: `GetRunningTasks` は、ダッシュボード表示用に、ID、Name、State、Progress（`CurrentProgressPercentage` 由来）、Description、スタック状態を持つ詳細な `TaskActivity` 構造体を返します。
- サーバー状態: `GetServerStatus` は `/Sessions` をポーリングし、ダッシュボード表示用に、アクティブなストリーミングセッション数、トランスコード数（direct ではない映像/音声）、帯域幅使用量を集計します。
- ライブラリ検出: `GetSections` は `/Library/VirtualFolders` を呼び出し、ID/Title/Paths（ライブラリのすべてのフォルダー）/Type を持つセクションを返します。さらに `Items?ParentId=<id>&Recursive=true&Limit=0` で各セクションにアイテム数を追加します。
- 更新: `ProcessJob` は、ジョブで変更されたすべてのパスを、サーバーが自身のファイルシステム上で見ているとおりのパスのまま、1 回の `POST /Library/Media/Updated` で報告します。パスが指定されていないジョブは、`POST /Items/{id}/Refresh` でライブラリ全体を更新します。503 の場合は `ServerBusyError` を返し、404 の場合は "library may have been deleted" エラーを返します。それ以外の 4xx/5xx では、レスポンスボディを返します。`RefreshSection` はジョブをキューに入れます。
- ヘルパー: `FindSectionNormalized` はパスのプレフィックスで照合し（最初に一致したものが優先）、プレフィックス部分をライブラリの場所の大文字小文字に書き換えたパスを返します。プレフィックスの比較は macOS と Windows では大文字小文字を区別せず、それ以外では完全一致です（`pkg/common/pathutil.go`）。

## メディアスキャナー連携 (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- `mount_path`、サーバーのURL、トークンが揃っているときに Jellyfin クライアントを初期化します。成功したらログに出力し、失敗したときは クライアントを nil のままにします。Plex と違ってリトライのループはありませんが、手動での再初期化はサポートされています。
- `TriggerScan` は他のサーバーと一緒に Jellyfin にも処理を振り分けます。`triggerJellyfinScan` は `FindSectionNormalized` を使って、`mount_path` を先頭に付けたパスからセクションを特定し、各セクションで変更されたパスをまとめて1回のリクエストで送ります（Plex はリクエストごとに1パスです）。
- `GetQueueSizes` は Plex、Jellyfin、Emby のキューの長さをまとめて返します。サーバーに接続していない場合は -1 を使います。
- `ReinitializeJellyfinClient` は既存のクライアントがあれば閉じてから、現在の設定でクライアントを作り直します（ダッシュボードで認証した後やログアウト時に使われます）。

## ダッシュボードとルート {#dashboard--routes}
- ルーターには Jellyfin のエンドポイントがマウントされています: `/jellyfin/check-server`、`/jellyfin/auth`、`/jellyfin/auth/status`、`/jellyfin/server`、`/jellyfin/logout`、`/jellyfin/scan/{sectionID}`、`/jellyfin/scan-all`（`internal/handlers/router.go`）。
- ダッシュボードのモーダル（templates/scripts）で QuickConnect を操作し、ステータスやエラーを表示し、認証情報の保存と削除を行います。キューサイズ、スキャンボタン付きのライブラリカード、サーバーのアクティビティは `dashboard.tmpl` に表示されます。
- `JellyfinStatusFetcher`（`internal/handlers/dashboard/mediabrowser_status.go`）は、ページの読み込みをブロックせずに、バックグラウンドのキャッシュからダッシュボード用 JSON を作成します。トークンを検証し、接続状態を確認し、ライブラリ一覧（ID/Name/Paths/Type/ItemCount）を取得します。さらに、実行中のタスクのアクティビティと、セッション、トランスコード、帯域幅の数を集めます。アクティビティとセッションは 30 秒ごと、ライブラリを含む全体の取得は 5 分ごとに更新されます。`response.go` はキャッシュされたコピー（`JellyfinServerInfo`、`jellyfin_queue_size`）を返します。
- ライブラリのスキャンエンドポイント（`HandleJellyfinScan`、`HandleJellyfinScanAll`）は、Plex 版と同じように、個別のライブラリセクションまたはすべてのライブラリセクションについて、パスを指定せずにライブラリ全体の更新をキューに入れます。Jellyfin クライアントが設定されていない場合は 503 を返します（`internal/handlers/dashboard/dashboard.go`）。
- `jellyfin_server_url` と `jellyfin_token` は、汎用の設定更新ハンドラーからも書き込めるため、QuickConnect のモーダルを使わずに設定できます（`dashboard.go` の `handlers["jellyfin_server_url"]`/`["jellyfin_token"]`、`scripts.tmpl` の `updateJellyfinServerURL`）。

## ライブラリへの副作用と更新 {#library-side-effects--refresh}
- ライブラリに関わる副作用（ディレクトリ割り当ての変更、STRM 同期、修復など）はすべて `MediaScanner.TriggerScan` を呼び出します。クライアントが接続されている場合は、Jellyfin の更新も含まれます（`internal/torrent/hooks.go:TriggerLibrarySideEffects` → `pkg/scan/scanner.go`）。
- 同じ呼び出しで、最初に影響を受ける rclone VFS の dircache エントリを破棄します。これにより、Jellyfin のスキャンは数時間キャッシュされた一覧ではなく、変更後の内容を確認できます。
- STRM 同期と `on_library_update` フックは、スキャントリガーと並行して実行されます（フックは 500ms のデバウンスと重複排除が適用されます）。Jellyfin の更新ジョブには、mount_path で始まるライブラリパスが渡されます。

## その他 {#miscellaneous}
Emby は Jellyfin の兄弟のような連携で、独自の設定キー（`emby_server_url`、`emby_token`）を持ちますが、共通のコアは同じものを使っています。ただし QuickConnect はありません。サインインは API key を入力するか、ユーザーを選んでパスワードを入力する方法になります（`/emby/users`、`/emby/auth`）。ダッシュボードのカードには、ライブラリが scan ボタン付きで表示されます（`/emby/scan/{sectionID}`、`/emby/scan-all`）。また、Jellyfin と同じようにアクティビティとセッションも表示されます（`EmbyStatusFetcher`）。
- `pkg/jellyfin/windows_path_test.go` では、Windows のパスがリクエスト URL に入らず、そのままボディに届くことを確認しています。`find_section_test.go` はプレフィックス一致をカバーしています。
