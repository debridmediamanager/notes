# Plexの機能と性能 {#plex-features--capabilities}

rex を Plex Media Server と並べて使いますか、それとも Plex の代わりに使いますか？ [Plex から rex への移行](../../rex/from-plex.md) では、rclone マウントを含めて zurg に残すものと、zurg の Plex 設定のうち削除すべきものを説明しています。

## 設定とストレージ {#configuration--storage}
- 設定キー（[`config.md`](../reference/config.md) と `config.example.yml` に記載）: `plex_server_url`、`plex_token`、`plex_match_every_mins`（デフォルト 1440）、`plex_watchlist_enabled`、`plex_watchlist_check_every_secs`（`watchlist.check_every_secs` の古い書き方、デフォルト 60 秒）、`mount_path`（マッチングとスキャンパスの組み立てに必須）。ダッシュボードで設定した項目は、設定ライターの `updateConfigFileAtomic` を通じて `config.yml` に直接保存されます。
- ウォッチリストの間隔は、0 以下の値が指定されると（`GetWatchlistCheckEverySecs`）デフォルト値にフォールバックします。`plex_match_every_mins` は、ちょうど `0` の場合にだけフォールバックします（`intOr`、`internal/config/config.go`）。どちらも無効にはできません。ダッシュボードは 1 未満の値を拒否します（`internal/handlers/dashboard/dashboard.go`）。`config.yml` に負の `plex_match_every_mins` を書くと、起動時に `is negative; use 0 for the default` というエラーで zurg が停止します。マッチングがオフになるわけではありません。
- ウォッチリストの取得は `watchlist:` ブロックで設定します。`enabled`、`check_every_secs`、`indexers`、`max_size_gb`、`max_season_size_gb`、`quality`（デフォルトは `best`）があります。`indexers` が空の場合は `stremio.indexers` を借用します。フラットなキーの `plex_watchlist_enabled`、`plex_watchlist_check_every_secs`、`watchlist_quality` は、それぞれ上記の最初、2 番目、最後の項目の古い書き方として引き続き有効です。詳しくは [config.md](../reference/config.md#watchlist) を見てください。
- `mount_path` は、Plex に送るスキャンパスと、zurg が管理する rclone マウントのプレフィックスにもなります（[`config.md`](../reference/config.md)、`pkg/scan/scanner.go`）。
- `on_library_update` フックには、変更されたすべてのパスが引数として渡されます。500 ミリ秒のデバウンスと重複排除がかかり、一度に実行されるのは 1 回だけです。Plex の autoscan スクリプトで使えます（`internal/torrent/hooks.go`）。

## 認証とサーバー検出 {#authentication--server-discovery}
- Web dashboard flow: `/plex/auth` creates a PIN session (`pkg/plex/auth.go`, `CreatePlexAuthURL`), stores it in `pkg/plex/auth_session.go` (auto-cleanup after 10 min, swept every 5), and polls for completion via `/plex/auth/status` (`PollForAuthToken`, 60 attempts 5s apart before timing out).
- `/plex/callback` serves a progress page that, once authorized, calls `/plex/servers` to list servers and `/plex/server` to select one (`internal/handlers/dashboard/dashboard.go`).
- Server discovery (`pkg/plex/auth.go`): fetches Plex resources with both HTTP/HTTPS endpoints, filters relay if direct exists, handles IPv6 addresses, and probes each entry's `/identity` (TLS verification disabled). Only servers **owned** by the account are considered (`device.Owned`, `auth.go`) — shared servers never appear — and entries that fail the probe are dropped from the response rather than returned with `last_error` set (`enrichServersWithIdentity`, `auth.go`).
- Selecting a server writes `plex_server_url`/`plex_token` to config, reinitializes the Plex client, (re)starts the matcher scheduler, fires a match trigger, and refreshes the cached dashboard status (`HandlePlexServerSelect`, `internal/handlers/dashboard/dashboard.go`). `/plex/logout` clears the stored values and the status cache.

## Plexクライアントの機能 (`pkg/plex/client.go`) {#plex-client-capabilities-pkgplexclientgo}
- 接続のライフサイクル: 遅延開始オプション (`WithDeferredStart`)、`/identity` に対する `ValidateConnection` のガード、正常な `Close`。再起動 API はありません。ダッシュボードの `RestartAllowed` / `RestartReason` は、サーバー URL (ローカル/LAN かリモートか) から推測される表示用の値です (`internal/handlers/dashboard/plex_status.go:getPlexConnectionDetails`)。
- スキャンキュー: 動的ジョブキュー/ワーカー (`common.DynamicJobQueue`)。`ProcessJob` は Plex ヘッダー付きで `GET /library/sections/{key}/refresh` を送り、ジョブごとの `path` クエリパラメータは **最大1つ** です。2つ以上あると即座に拒否されます (`client.go`)。パスがないジョブは、セクション全体の更新になります。503 はサーバー混雑のエラーになり、404 はそのライブラリが Plex から削除されたと報告します。`GetJobQueueSize` で未処理の数を確認できます。
- 負荷とスタックの検出: `CheckServerLoad` は `/activities` を調べ、UUID ごとに `library.update.section` の進捗を追跡します (進捗または subtitle が変わると、進んだとみなします)。`IsJobStuck` は `librarySectionID` で古いジョブにフラグを立て、一致しない場合は Title で代替判定します。`GetServerActivitiesDetails` も同じトラッカーを作成・破棄します。`CheckServerLoad` はワーカーがジョブをキューに入れているときしか動かないためです。以前は、Plex が自分で始めたスキャンにはトラッカーが作られませんでした。そのためスタックとして報告できず、更新のたびに経過時間が 0 と表示されていました。どちらの経路も履歴は `library.update.section` だけに保持します。それ以外を追跡すると、ワーカーの prune と食い違ってしまうためです。
- **アクティビティの subtitle は、保留中のスキャンがブロックされているファイルではありません。** 2026-09-15 に plex503 の検証環境で計測しました。`library.update.section` の subtitle はスキャナーの列挙ポインタで、実際の読み取りより先に進みます。マウントが3つのファイルを拒否している間、subtitle は一度も要求されていない4つ目のファイルを指していました。ブロックされているファイルを指していたのは、56 秒のサイクルのうち 290 ms だけです。ダッシュボードはこれを "Plex reports" と表示し、リリースとはリンクしません。スキャンが実際に待っているものは、zurg 自身の拒否情報 (`internal/universal/refused_reads.go`) から取得します。それを知っているのは zurg 側だけだからです。コーパスは `internal/handlers/dashboard/testdata/plex503-*` にあります。
- ライブラリのクエリ: `GetSections` (location 付きの movie/show セクション)、`GetSectionItemCount`、`FindSectionNormalized` (パスをセクションの location と照合し、プレフィックスをライブラリの大文字小文字に合わせて修正)、`GetAllMediaItemsConcurrent` (`includeGuids` 付きのバッチ・並列取得で、パス、GUID、IMDB ID を集めます)、`GetShowLevelIMDBIndex` (TV セクションの show レベルの ID を取得し、エピソードが継承できるようにします)。
- メタデータとマッチングのヘルパー (`pkg/plex/match.go`): `GetMetadataSummary` (`GET /library/metadata/{ratingKey}`)、`GetMatchCandidates` (`GET /library/metadata/{ratingKey}/matches?manual=1`、title/year/language の上書きに対応)、`LookupMetadataByGUID` / `LookupRatingKeyByGUID` (`GET /library/all?guid=…`)、`ApplyManualMatch` (`PUT /library/metadata/{ratingKey}/match`)、そして GUID の解析 (`ExtractIMDBIDFromGUID`、`ExtractTMDBIDFromGUID`、`ExtractTVDBIDFromGUID`、`ExtractAnyIDFromGUIDs`、`MatchResult` / `MatchSelection` 型)。
- サーバー情報: `GetServerIdentityOnly` と `GetServerDetails` (マシン ID とバージョン。後者はセッション数、トランスコード数、帯域幅の合計も返します)、`GetStreamingSessions`、`GetTranscodeSessions`、`GetServerActivitiesDetails` (スタック状態が付与されます)。
- 視聴履歴: `GetWatchHistory` (`GET /status/sessions/history/all`)、`GetMetadataBatch` (カンマ区切りの rating key を `/library/metadata` に送ります)、`GetWatchHistoryWithMetadata` (`pkg/plex/history.go`)。これらは `pkg/plex/stats.go` の統計に使われます。

## メディアスキャナー連携 (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- `mount_path`、`plex_server_url`、`plex_token` が設定されていれば Plex クライアントを初期化します。接続できるまで5秒ごとに再試行し、接続できたら `OnPlexReconnected` コールバックを呼び出します。
- `TriggerScan` はパスを Plex のセクションごとにまとめ（`FindSectionNormalized` を使用）、`mount_path` で始まるパスごとに更新ジョブを1つキューに入れます。進捗は50件ごとにログに出ます。Jellyfin/Emby にも対応していて、こちらはまとめずに別の経路を使います。どのセクションにも入らなかったパスについての警告は、バッチ内の*一つも*一致しなかった場合だけ出ます。それ以外はデバッグ行になります。そのため、ライブラリのディレクトリと zurg 専用のディレクトリ（recent、music など）の両方に入っているトレントでは警告は出ません。
- `ReinitializePlexClient` を使うと、ダッシュボードの更新でサーバーやトークンを再起動せずに切り替えられます。
- `GetQueueSizes` は Plex のキューの深さを返すので、UI や監視に使えます。

## マッチングとメタデータ同期 (`internal/plex/matcher.go`, `internal/plex/schedule.go`) {#matching--metadata-sync-internalplexmatchergo-internalplexschedulego}
- 前提条件: Plex の URL とトークン、`mount_path`、有効な `scanner.PlexClient` が設定されている必要があります。足りない場合は、わかりやすいエラーを返します。
- torrent に保存される Plex の情報は、`PlexRatingKey`（エピソード形式のコンテンツでは番組単位）と `IMDBID` だけです（`internal/torrent/torrent_types.go`）。Plex の GUID は、処理中に ID を取り出したりレポートに書いたりするためだけに使われ、保存はされません。
- データの収集: ディレクトリマップからすべての torrent を読み込み、`GetAllMediaItemsConcurrent` で Plex のすべてのアイテムを取得します。その前に `GetShowLevelIMDBIndex` を実行し、エピソードがエピソード単位の ID ではなく番組の IMDB/TVDB/TMDB ID を引き継ぐようにします。アイテムは `GrandparentRatingKey` があればそれをキーにします。
- 同期の手順:
  - 保存されているすべてのレーティングキーを、取得し直した Plex のアイテムと照らし合わせて検証します。Plex にもうないキーは、torrent の IMDB ID と一緒にクリアされ、torrent はマッチング用のキューに戻されます。
  - レーティングキーがない torrent はパスでマッチングします。`buildPlexDirIndex` は Plex の各ファイルのパス要素を小文字にして、すべてインデックス化します。torrent の `GetKey` をそこで検索します（O(1)、最初に見つかったものが優先）。割り当てられたディレクトリがどの Plex セクションの場所にも一致しない torrent は、先にスキップされます。
  - IMDB の補完: まず、すでに取得済みのバッチから行います（API 呼び出しなし）。その後、torrent ごとに `GetMetadataSummary` で補完します（最大 20 並列）。
  - Plex のアイテムの中で、torrent が紐づいていないものを検出します。
  - ユーザーが手動で設定したハッシュと IMDB のペアだけを DMM に送ります。Plex が推測した ID は送りません。DMM はそれをキーなしで受け取ります。`dmm_api_key` が設定されていれば、それも一緒に送ります（`sendHashImdbPairs` → `TorrentManager.SendHashImdbPairs`、`internal/torrent/mediainfo.go`）。
- `MatchSingleTorrent` は、1 つの torrent に対して同じパスでの検索を行います。ターゲットを絞ったスキャンの直後に使われます。torrent にすでにレーティングキーがある場合は、何もせずに終了します。
- レポート: `logs/match_report.txt` を書き出します。件数、マッチしなかった torrent、スキップされた torrent、torrent が紐づいていない Plex のアイテム、IMDB が欠けているマッチの概要が含まれます。
- スケジュール（`internal/plex/schedule.go`）: 実行が完了するたびに `data/plex_match_timestamp` が更新されます。起動時、そのタイムスタンプがないか、`plex_match_every_mins` より古い場合にだけ、`StartMatchingJob` がすぐにジョブを実行します。それ以外の場合は、残りの時間を待ってから実行します。手動のトリガーは `TorrentManager.PlexMatchTrigger` で受け取ります。実行間隔の変更は `ResetPlexMatchTicker` でライブに反映されます。ジョブがパニックした場合は、最大 3 回まで再実行します。
- 手動トリガーのエンドポイント `/plex/match-torrents` は、トリガーのチャネルに送信します。ただし、実行中は受け付けません。`/plex/match-torrents/status` は、実行中かどうかを返します（`internal/handlers/utilities.go`）。

## 手動マッチングと管理UI (`internal/handlers/manage`) {#manual-matching--manage-ui-internalhandlersmanage}
- トレントの一覧フィルターには、クイック表示用に Plex の状態（`plex_matched`、`plex_in_library_not_matched`、`plex_no_imdb`、`plex_missing_metadata`）があります（`torrent_list_state.go`）。
- トレントごとの手動マッチページ `/manage/{hash}/plex-match`:
  - トレントに `PlexRatingKey` が入っている必要があります（マッチャーが設定します）。入っていない場合、ページに "torrent is not linked to Plex" と表示されます。`resolvePlexRatingKey` はこのキーを `GetMetadataSummary` で検証し、IMDB ID が空なら補完します。キーが古くなっている場合は、トレントに保存されている `tt…`/`tvdb://`/`tmdb://` の ID を使って `LookupRatingKeyByGUID` でキーを取り直します（`internal/handlers/manage/handler.go`）。
  - Plex の手動マッチ候補を、必要に応じてタイトル・年・言語を上書きして取得します（言語は 44 種類から選べて、デフォルトは `en-US`）。候補は一覧に表示され、現在選ばれているものがハイライトされます（`torrent_matches.go`）。
  - マッチを適用すると（`HandleApplyPlexMatch`）、まず `ApplyManualMatch` が呼ばれます。Plex が rating key を振り直すことがあるため、選んだ GUID でキーを再度検索します。そのうえでトレントの rating key と IMDB を更新します（ユーザーが任意で入力した IMDB もここで反映されます）。変更を保存したあと、成功またはエラーの状態を付けてリダイレクトします。

## ウォッチリストからの取得 {#watchlist-acquisition}

- Plex ウォッチリストは `internal/acquisition/plex` にあるアダプターで、Seerr と同じ共有 acquisition サービス上で動きます。既存のウォッチリスト設定はそのまま使えます。アダプターは `acquisition.sources` の下でも設定できます。
- クライアントは `discover.provider.plex.tv` を使い、100 件ずつページ送りします。Plex トークンはリクエストごとに読み込まれるので、再認証はアダプターを再起動しなくても反映されます。
- 共有の executor は、映画または計画された各シーズンを Newznab と Torznab のインデクサーから取得し、シーズンパックを優先します。テレビ番組の検索では、インデクサーごとにマッピングが違うため、IMDb より先に TVDB を試します。
- 進捗、リトライの期限、エピソードごとの受領記録は、再起動後も `data/acquisition.json` に残ります。以前の Plex 台帳は自動でインポートされます。
- 削除は、計画されたすべての対象の取得が終わってから行われます。失敗したリクエストはウォッチリストに残り、永続的なバックオフでリトライされます。削除だけのリトライでは、再度取得は行われません。制限については [Plex ウォッチリストの取得](plex-watchlist.md) を、共通の設定については [acquisition ソース](acquisition.md) を参照してください。

## ダッシュボードとAPIエンドポイント (`internal/handlers/router.go`, `internal/handlers/dashboard`) {#dashboard--api-endpoints-internalhandlersroutergo-internalhandlersdashboard}
- ルート: `/plex/auth`, `/plex/callback`, `/plex/auth/status`, `/plex/servers`, `/plex/server`, `/plex/logout`, `/plex/match-torrents`, `/plex/match-torrents/status`, `/plex/scan/{sectionKey}`, `/plex/scan-all`, `/plex-stats`, `/plex-stats/data`, `/plex-stats/image`, `/manage/{hash}/plex-match`
- ダッシュボードには、2つのティッカーで `PlexStatusFetcher` を使って Plex サーバーの情報とステータスが表示されます。30秒ごとにストリーミングセッション、トランスコード、帯域幅、サーバーアクティビティを更新します（`GetStreamingSessions`/`GetTranscodeSessions`/`GetServerActivitiesDetails`）。5分ごとにはフルフェッチを行い、サーバーIDの再読み込み（`GetServerIdentityOnly`）、ライブラリのセクション、セクションごとのアイテム数も更新します。スキャンのアクティビティは、ファイル名をもとにトレントリストと照合されるので、ダッシュボードからアクティビティをトレントのハッシュにリンクできます。
- セクション/全体のスキャンエンドポイントは、1つまたは全セクションに対して**フル**のセクション更新（`RefreshSection(key, nil)`、パスなし）をキューに入れます。STRM ファイルには触れず、ライブラリのサイドエフェクトも発生させません（`HandlePlexScan`/`HandlePlexScanAll`）。

## Plex Wrapped (`internal/handlers/dashboard/plex_wrapped.go`)
- `/plex-stats` は、過去12か月のPlex視聴履歴から、9枚構成の1年間のまとめスライドを表示します。
- `/plex-stats/data` は同じ統計をJSONで返します。
- `/plex-stats/image` は、ヘッドレスchromedpを使って共有用のPNG画像を生成します (`square` 1080x1080がデフォルト、`instagram` 1080x1920、`facebook` 1200x630)。
- 統計の取得は最大で24時間に1回です (`?refresh=true` を付けると強制的に再取得します)。取得する履歴は最大10000件までです。
- 結果はメモリとディスク (`data/plex_wrapped_cache.json`) の両方にキャッシュされ、起動時にディスクから読み込まれます。
- 取得中はページを止めず、読み込み中の状態を表示します。

## ライブラリへの副作用とリフレッシュリンク {#library-side-effects--refresh-links}
- ディレクトリの割り当て変更、リネーム、削除、ファイル修復のときにライブラリの副作用が発火します。`TriggerLibrarySideEffects` は影響を受けるパスの rclone VFS dircache を無効化し(メディアサーバーが古い一覧をスキャンしないようにするため)、`MediaScanner.TriggerScan` を呼び出し(Plex のリフレッシュを実行)、さらにユーザーの `on_library_update` フックを実行します(`internal/torrent/hooks.go`)。
- リフレッシュパイプラインは、初期化が完了した後にのみ STRM 生成と副作用を実行します。これは Plex の早すぎるスキャンを避けるためです(`internal/torrent/refresh.go`)。

## インフラとスクリプト {#infrastructure--scripts}
- サンプルの Nginx vhost（Plex のトラフィックをプロキシする設定、`nginx/plex.conf`）。
- `plex_update.sh` は `on_library_update: sh plex_update.sh "$@"` 用の参照版 partial-scan スクリプトです。`docker-compose.yml` と同じフォルダに置いてください。そのフォルダは `/config` にマウントされるので、スクリプトはすでにコンテナの中にあります。Windows では、フックは `/bin/sh` ではなく PowerShell 経由で実行されます（`pkg/script/script.go`）。そのため、このスクリプトは Windows では動きません。PowerShell 版の書き方は [Usenet → Point Plex at it](usenet.md#6-point-plex-at-it) を見てください。
- `integration/plex_integration.sh` は `make integration-test` と `make integration-test-media` で実行されます。Plex サーバーがないホストでは、大きめの警告を出してスキップします。そのため、終了コードだけでなく出力をよく読んでください。`scripts/plex-e2e-test.sh` は単独で動く再生チェックで、`config.yml` から `plex_server_url`/`plex_token` を読み取ります。

## 推奨されるPlexの設定 {#recommended-plex-settings}

Plex のデフォルト設定は、ローカルディスクが常に存在し、いつでも読み取れることを前提にしています。zurg のマウントはそうではありません。データはプロバイダーから HTTP 経由で届き、rclone が再接続している間は一時的に読めなくなることがあります。こうした条件では、Plex のデフォルトの一部がむしろ問題を起こします。

zurg は Plex のステータス更新のたびに、これらの設定を調整します。どこまで踏み込むかは `plex_settings_policy` で決まり、`off`、`warn`、`guard`（デフォルト）、`enforce` から選べます。設定の一覧は `pkg/plex/settings.go`（`RecommendedSettings`）にあり、ポリシーは `pkg/plex/reconcile.go` にあります。

サーバーが報告しない設定はスキップされます。そのため、その設定を持たない Plex バージョンが設定ミスとして報告されることはありません。

下記の16個の値のうち9個は Plex のデフォルト値に反するものです。残りの7個は Plex のデフォルト値と同じで、修正ではなくガードとして働きます。これらはユーザーが該当の設定を有効にした場合にのみ発動します。ガードの行では両方の列に同じ値が表示されていますが、これは間違いではありません。Plex は `GenerateBIFBehavior` を `never` で出荷していますが、測定に使ったサーバーでは `scheduled` になっていました。

Plex は各設定のデフォルト値を `/:/prefs` で報告します。そのため、下の「Plex ships」列は想定ではなく、サーバーから読み取った値です（2026-09-05、Plex 1.42.2で測定）。

### 1つの設定をオプトアウトする {#opting-out-of-one-setting}

`plex_settings_policy` は段階制ですが、その段階が必ずしも知りたいことに対応しているとは限りません。ファイルがライブラリフォルダー間で移動する運用、たとえばタグによる振り分けを行っている場合、残された項目を消すために Plex 自身にゴミ箱を空にしてもらう必要があります。ところが `guard` を選ぶとその機能がオフになります。`warn` に下げて取り戻そうとすると、同じ段階にあるファイルシステムイベントのガードも失われます。これは本来求めていたことではありません。

`plex_settings_ignore` では設定を個別に指定します。

```yaml
plex_settings_policy: guard
plex_settings_ignore:
  - autoEmptyTrash
```

この項目はダッシュボードが自動で書き込みます。設定ページの Library Trash Sweep の設定の上に **Let Plex Empty Its Own Trash** のスイッチがあります。これを切り替えると、ここに `autoEmptyTrash` が追加または削除されます。リストのほかの項目はそのままです。オンにすると、次回の再起動から反映されます。

無視された設定も引き続き読み取られ、ダッシュボードと `zurg plex-settings` には（`skip` と表示されて）表示されます。つまり、何かが隠されることはありません。ただ、書き込まれず、問題としてカウントされず、ダッシュボードのゴミ箱バナーの対象にもなりません。ID は大文字と小文字を区別せずに照合されます。下の表のどの設定にも当てはまらない ID は起動時に報告され、その設定はガードされたままになります。タイプミスがオプトアウトとして扱われないようにするためです。

安全に関わる設定を無視する場合は、自己責任になります。zurg はそのことを毎回の更新ではなく、起動時に一度だけ知らせます。特に `autoEmptyTrash` は、スキャン中にマウントが一時的に不安定になったときにライブラリを空にしてしまう設定です。これを無視すると、クリーンアップの作業も Plex 側に任されることになります。詳しくは下記を参照してください。

### ゴミ箱を空にするのは誰か {#who-empties-the-trash}

`autoEmptyTrash` をオフにすると、仕事が1つ残ったままになります。Plex は、ファイルが消えたエントリを消さないように指示されています。zurg 側の削除も長いあいだオプトインだったので、初期設定ではライブラリに無効なエントリがたまり続け、それを回収する仕組みがありませんでした。どちらが間違っていたわけでもありませんが、このすき間は実際に問題でした。ファイルがライブラリのフォルダー間で移動され、古いエントリが残り続ける、というときに困ることになります。

zurg は、手放していた仕事を再び引き受けるようになりました。`plex_trash_sweep_every_mins` を未設定のままにすると、[トラッシュ掃除](../internals/plex-trash-sweep.md) が60分ごとにエントリを削除します。ただし、ほかに削除を行っている者がいないときだけです。`plex_settings_policy` が `off` か `warn` になっている場合や、`autoEmptyTrash` が `plex_settings_ignore` に入っている場合など、Plex がまだ自分のゴミ箱を空にしているときは、zurg は手を引いて Plex に任せます。1つのライブラリに掃除役が2つあると、両者の食い違いがそのまま削除につながってしまうからです。

トラッシュ掃除は、Plex 自身の空にする処理よりずっと控えめです。だからこそ、こちらを優先する価値があります。1回に1エントリだけを削除し、まだファイルが残っているエントリは決して削除しません。また、その時点で読み取れているマウントからのみ動作し、1回の実行で削除は50件まで、ゴミ箱の10%までに制限されています。判定のつかないエントリは、削除前に14日間、壊れたものとして表示され続けます。

さらに `plex_database_path` の設定が必要なので、Plex がこのホスト上で動いている場合にだけ動きます。また、zurg 自身がマウントを動かしている必要があります（`rclone_enabled` を有効にし、`mount_path` を設定）。zurg は Plex がインストールする `Plex SQLite` プログラムでデータベースを読みます。Linux、macOS、Windows では、Plex のインストーラーがそれを置く場所を自動的に探すので、設定するキーは `plex_database_path` の1つだけです。

+++ Linux
```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ macOS
```yaml
plex_database_path: "/Users/YOU/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ Windows
```yaml
plex_database_path: 'C:\Users\YOU\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db'
```
シングルクォートはそのまま残してください。ダブルクォートの中では、YAML がバックスラッシュをエスケープとして読んでしまいます。`plex_sqlite_binary` を設定するのは、32ビット版の Plex など、別の場所にインストールされた Plex を使う場合だけです。例: `'C:\Program Files (x86)\Plex\Plex Media Server\Plex SQLite.exe'`
+++

`YOU` は自分のユーザー名に置き換えてください。zurg は `~` も `%LOCALAPPDATA%` も展開しません。トラッシュ掃除は、Plex が保存しているパスを `mount_path` と照合します。その際、`Z:` のようなドライブ文字も扱えます（`pkg/utils/path_within.go`）。

削除を無効にして、自分でゴミ箱を空にしたい場合は、`plex_trash_sweep_every_mins: 0` と書いてください。これは明示的に「いいえ」と指定することで、キーを省略した状態とは区別されます。

このキーがオフにするのは、zurg 自身の削除だけです。Plex の設定を元に戻すわけではありません。`guard` の下では、zurg は依然として `autoEmptyTrash` をオフに書き込みます。そのため、スキャン後に Plex はゴミ箱を空にせず、エントリが回収されないままたまり続けます。Plex にその仕事を返すには、ダッシュボードのスイッチか `plex_settings_ignore` を使ってください。

### 安全性 — `guard` と `enforce` の下で修正 {#safety--corrected-under-guard-and-enforce}

これらは時間ではなくデータを失わせます。そのため、デフォルトのポリシーでは警告だけでなく書き換えを行っています。`autoEmptyTrash` だけが破壊的な値で出荷されています。残りの3つはすでに zurg が望む値になっているので、誰かが有効にしてしまった場合に気づくための確認用です。

| 設定 | Plex のデフォルト | zurg の推奨値 | 理由 |
|---|---|---|---|
| `autoEmptyTrash` | `1` | `0` | Plex はスキャンのたびにゴミ箱を空にします。スキャンの途中でマウントが一時的に読めなくなると、すべてのファイルが削除されたように見えます。すると Plex はマウントが戻ってきてもゴミ箱から復元できず、ファイルを完全に削除してしまいます。 |
| `FSEventLibraryUpdatesEnabled` | `0` | `0` | イベント駆動の更新では、実際に変わったものを取りこぼします。zurg のツリーはサーバー側で変わるので、ローカルのカーネルを経由せず、イベントも発生しません。その結果、ライブラリが気づかないうちに古くなります。届くイベントは、マウント*経由*の書き込みだけです。これはディレクトリがまだ組み立て中に書き込まれたものです。 |
| `FSEventLibraryPartialScanEnabled` | `0` | `0` | 部分スキャンも同じイベントを使って動きます。そのため、マウント経由の書き込みに反応します。つまり、ディレクトリが半分しか書かれていないタイミングで実行されてしまい、本当にスキャンが必要なサーバー側の変更には反応しません。 |
| `ButlerTaskBackupDatabase` | `1` | `1` | 毎晩のデータベースバックアップは、Plex がすでに削除したライブラリを復元できる唯一の手段です。 |

2つの `FSEvent` の理由は、zurg がマウントするすべてのプラットフォームで測定したあとに書き直しました。以前の文章では、FUSE マウントは「確実にイベントを出さないため、誰も求めていないタイミングでスキャンが発生する」と書いていました。しかし、その両方の内容が間違っていました。

2026-09-05 に測定しました。各プラットフォームでは、メディアサーバーが実際に使っている API で監視しました。対象は、バックエンドのディレクトリを直接変更できる rclone マウントです。**A** はマウント経由で行った書き込みです。**B** は、zurg 自身のツリーが変わったときと同じように、反対側に同じファイルが現れるケースです。

| プラットフォーム | マウント | 監視に使ったAPI | A: マウント経由 | B: 反対側で変更 |
|---|---|---|---|---|
| Linux | `fuse.rclone` | inotify | `CREATE` `OPEN` `ATTRIB` `CLOSE_WRITE` | **イベントなし** |
| Docker | 同じマウントをコンテナにバインドマウント | コンテナ内の inotify | 同じ4つ（コンテナ内で確認） | **イベントなし** |
| macOS | macFUSE | FSEvents | `Created IsFile` | **イベントなし** |
| Windows | WinFsp | `ReadDirectoryChangesW` | `Created` `Changed` | **イベントなし** |

すべてのプラットフォームで A のイベントは届きました。同じ実行内で、ネイティブのファイルシステム（APFS、NTFS）を使った対照実験でも同じイベントが出たため、監視の仕組みは正しく動いていました。どのプラットフォームも B のイベントは届きませんでしたが、ディレクトリのキャッシュが切れたあとには、マウント越しにファイルが見えていました。

つまり、問題の起きかたは説明していたものと逆でした。イベント駆動の更新が発火するのは、マウント*経由*の書き込みのとき、たとえば \*arr のインポートがまだ組み立て中のディレクトリに届いたときです。一方で、そもそもスキャンが必要な理由であるサーバー側の変更では、まったく発火しません。イベントが信頼できないわけではありません。debrid マウントで起きていることのうち、間違った半分を報告しているのです。

### 帯域幅 — `enforce` の下でのみ修正 {#bandwidth--corrected-under-enforce-only}

以下のそれぞれは、結果を誰も見ないのに、Plex にファイル全体をデコードさせます。ローカルストレージなら無害ですが、debrid マウント越しだと、1バイトごとがプロバイダーへのリクエストになり、ライブラリ全体で実行されてしまいます。出力が実際に見える解析（シーク時のプレビュー、チャプター画像、音量レベル調整、ソニック分析）は、代わりに下の taste tier に置かれ、`enforce` の対象にはなりません。

| Preference | Plexのデフォルト | zurgの推奨値 |
|---|---|---|
| `ButlerTaskDeepMediaAnalysis` | `1` | `0` |
| `ButlerTaskUpgradeMediaAnalysis` | `1` | `0` |
| `GenerateAdMarkerBehavior` | `scheduled` | `never` |
| `GenerateVADBehavior` | `never` | `never` |
| `GenerateIndexFilesDuringAnalysis` | `0` | `0` |
| `ButlerTaskGenerateMediaIndexFiles` | `0` | `0` |

### 好み — 常に報告され、修正されない {#taste--always-reported-never-corrected}

| 設定 | Plex の既定値 | zurg の推奨 | 理由 |
|---|---|---|---|
| `GenerateIntroMarkerBehavior` | `asap` | `scheduled` または `never` | `asap` は、ファイルが届いた瞬間にメンテナンス時間帯の外でも各ファイルをデコードします。`scheduled` なら Skip Intro ボタンは残したまま、作業をその時間帯に移せます。 |
| `GenerateCreditsMarkerBehavior` | `asap` | `scheduled` または `never` | 同じ理由で、Skip Credits についても同様です。 |
| `GenerateBIFBehavior` | `never` | `never` | 動画全体をデコードして、シーク時に表示される画像ストリップを作ります。再生には不要です。 |
| `GenerateChapterThumbBehavior` | `scheduled` | `never` | ファイルをデコードして、チャプター一覧の各項目の横に表示する画像用に、チャプターごとに 1 フレームを取り出します。 |
| `LoudnessAnalysisBehavior` | `scheduled` | `never` | 各ファイルの音声を完全にデコードして音量を測定します。トラックやタイトル間の音量をそろえるためです。 |
| `MusicAnalysisBehavior` | `scheduled` | `never` | すべてのトラックをデコードします。ファイル数が多いため、アカウントがレート制限されるほどのリクエスト数になります。得られるのは音の解析で、類似トラックのミックスやビジュアライザーに使われます。 |

### メンテナンスウィンドウ {#the-maintenance-window}

zurgは`ButlerStartHour`と`ButlerEndHour`には手を加えません。全員にとって正しい時間帯は存在しないからです。自分で設定する価値はあります。Plexのデフォルトは02:00〜05:00ですが、視聴する時間帯と重なると、メンテナンス作業がすべて止まってしまいます。帯域幅のティアで残ったものは、この時間帯の中で実行されます。

### 処理中のパスを停止する {#stopping-a-pass-already-in-flight}

設定を変えても、反映されるのは*これから*始まる実行だけで、すでに動いている実行には影響しません。Plex Media Server はスキャナーの子プロセスを何度でも起動し直すので、それらを終了させても意味がありません:

+++ Linux と macOS
```bash
curl -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
+++ Windows
```powershell
curl.exe -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
Windows PowerShell 5.1 では `curl` は `Invoke-WebRequest` の別名なので、`curl.exe` と入力してください。
+++

まず、`$TOKEN` に自分の Plex トークンを設定してください。シェルなら `TOKEN=your-token`、PowerShell なら `$TOKEN = 'your-token'` と入力します。
