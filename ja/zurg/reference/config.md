# zurg の設定ドキュメント {#zurg-configuration-documentation}

このドキュメントでは、zurg で利用できるすべての設定オプションを説明します。これらのオプションは `config.yml` ファイルで設定してください。

> **ヒント:** ほとんどの設定は **Dashboard** で行えます。アクセス先は `http://localhost:9999/config/` です。Web インターフェースを使えば、設定ファイルを直接編集しなくても、設定の確認や変更が簡単にできます。

## `providers` より前の設定からの移行 {#migrating-from-a-pre-providers-config}

設定ファイルが複数アカウント対応の導入前に書かれたものでも、そのまま起動します。トップレベルの `token:`、`download_tokens:`、`strm_link_token:` キーは、本来の意味どおり、Real-Debrid アカウントひとつを指すものとして読まれます。そのため、起動時には非推奨の警告が表示されます。これらを `providers` のエントリに移すだけで済みます。いつ対応するかはご自由にどうぞ。ほかのキーの名前、型、削除に変更はありません。

ただし、変わるのはそれだけではありません。名前と値はそのままでも、コードの置き場所が変わったため、動作が少し違うディレクティブがいくつかあります。それらは下の [What else changes when you upgrade](#what-else-changes-when-you-upgrade) にまとめています。アーカイブ、タグ、リリースの追加日時で絞り込んでいる場合は、ぜひ一度目を通してください。

### 変更すべき 1 点 {#the-one-change-to-make}

以前は1つのReal-Debridアカウントに、トップレベルのキーが3つ必要でした。現在はその3つすべてが1つの`providers`エントリの中に入ります。

変更前:

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
download_tokens:
  - ANOTHER_RD_API_TOKEN
strm_link_token: RD_TOKEN_FOR_STRM
```

変更後:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    download_tokens:
      - ANOTHER_RD_API_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
```

移動したら、古いキーは削除してください。`providers`ブロックでReal-Debridがすでに設定されている状態で残しておくと、そのキーは無視され、起動時に警告が出ます。これにより、どのトークンが有効かについて両者が黙って食い違うことはなくなります。

ファイルの他の部分は変更する必要はありません。他のキーは名前も意味もそのままです。認証情報が`token:`だけの設定なら、この編集だけで済みます。

必ずしも移行する必要はありません。移行していない設定でも起動はします。その場合、3つのキーは`realdebrid`という名前の1つのReal-Debridアカウントとして読み込まれ、起動時には読み込んだキーと、代わりに書くべき内容が表示されます。これらは非推奨であり、サポート対象ではありません。新しいアカウント機能は`providers`エントリからしか使えません。

`TOKEN`と`RD_TOKEN`の環境変数は引き続き使え、初回実行時に設定ファイルを自動作成します。

### できるようになったこと（必要かもしれないもの） {#what-became-possible-that-you-may-want}

これらはどれも必須ではありません。`providers` ブロックを使うと、次のことができるようになります:

| 利用可能になったもの | 場所 |
|---|---|
| TorBox、AllDebrid、Usenet バックエンドに対応（Real-Debrid と併用も、置き換えも可能） | [アカウント](#accounts) |
| 同じサービスの複数アカウント（`name` で区別） | [アカウント](#accounts) |
| `disabled: true` で、認証情報を消さずにアカウントを一時停止 | [アカウント](#accounts) |
| `watchlist: true` で、新しいトレントの追加を最初に試すアカウントを選択 | [アカウント](#accounts) |
| `provider:` / `not_provider:` のディレクトリフィルター、アカウントごとのディレクトリ | [ディレクトリ](#7-directories--filters) |
| `rd_cdn_host_preference` と `tb_cdn_host_preference` でサービスごとの CDN を選択 | [CDN とホストの選択](#cdn--host-selection) |

知っておくと良い小さな変更点が 2 つあります:

- `cdn_host_preference` は引き続き動作し、Real-Debrid を指します。現在は `rd_cdn_host_preference` の別名になっており、両方設定されている場合は `rd_cdn_host_preference` が優先されます。
- ダッシュボードの認証フローで取得した Plex の認証情報は、`plex_server_url` と `plex_token` として `config.yml` に書き戻されるようになりました。以前は `data/plex.json` に保存されていました。

### 手動での移行とダッシュボードでの移行 {#migrating-by-hand-vs-by-dashboard}

Dashboard で自動的に移行できます。移行前の設定でも読み込めるので、providers エディタにアクセスでき、トップレベルのキーが読み取られた Real-Debrid アカウントが一覧に表示されます。どれかのアカウントを保存すると、それらのキーがディスク上の `providers` ブロックに移動します。ファイルを手動で編集して再起動しても同じ結果になります。設定そのものが読み込めない場合は、これが唯一の方法です。

Dashboard で、もう受け付けなくなったものが一つあります。`POST /config` は以前、`token`、`download_tokens`、`strm_link_token` をトップレベルのキーとして受け取っていましたが、今では `400 Unknown config option` を返します。認証情報はアカウントごとに編集するようになりました。この3つを使ってスクリプトを書いている場合は、更新が必要です。

### アップグレード時にほかに変わること {#what-else-changes-when-you-upgrade}

以下のディレクティブは、どれも名前・型・値が変わりません。変わったのはそれを読み取るコードなので、同じ設定でも結果が変わることがあります。ここに書かれていることを編集する必要はありません。これは「こういう挙動になる」という説明です。納得がいかない部分だけ、設定を変えてください。

**フィルターがアーカイブの中身を見るようになりました。** `any_file_inside_regex`、`any_file_inside_contains`、`any_file_inside_size_gte`/`_lte`、それらの `not_` 版、`has_episodes`、`is_music` は、以前はアーカイブ自体に対して評価されていました。つまり `Show.part01.rar` という1つのエントリで、ボリュームと同じサイズです。zurg がアーカイブを一覧に取り込んだあとは、代わりに中身に対して評価されます。実際のファイル名、実際のサイズが使われ、アーカイブ自体のサイズは意図的に使われません（中身よりずっと大きく、全体を圧倒していたため）。以前は1つの巨大なファイルに見えていたシーズンパックが、`has_episodes` にマッチするようになります。`any_file_inside_regex: /\.mkv$/i` は、以前は失敗していたところでマッチするようになり、`any_file_inside_not_regex` は以前は通っていたところでマッチしなくなります。別の変更として、すべてのファイルが `.rar`/`.r00`/`.par2` のリリースも、以前のように直接 `__unplayable__` に送られるのではなく、フィルターまで届くようになりました。

これは一度に全部適用されるのではなく、リリースごとに順次反映されます。zurg がすでに一覧に取り込んだアーカイブにのみ適用され、古いパーサーで書かれた一覧は破棄されるため、リリースは初めて開かれたタイミングで切り替わります。ディレクトリが古い挙動に依存している場合は、アーカイブ名に対して `regex`/`not_regex` を使って書き直してください。これらはリリース名にマッチします。

**プローブされなかったリリースを、タグフィルターが捕まえなくなりました。** `zurg_*` タグは ffprobe から来ます。何もプローブできなかったとき、すべてのティアテーブルは最下位まで下がり、それでもリリースには `zurg_sdr`、`zurg_very_low_video_bitrate`、`zurg_very_low_audio_bitrate`、`zurg_0to20mins_duration` が付けられていました。誰も測定していないファイルについての情報だったわけです。これらはもう付与されません。

これら4つのいずれかを指定しているフィルターは、プローブできなかったリリースに対する意味が変わります。`has_tag`/`tags_match_all`/`tags_match_any` はそれらを捕まえなくなります。確認すべき方向として、`not_has_tag`、`tags_missing_all`、`tags_missing_any` は **逆に** それらを捕まえるようになります。他のティアを指定するフィルターには影響ありません。

**重複したリリースについて、`added_within_hours` / `added_within_days` / `added_after` / `added_before` が、より古いタイムスタンプを参照するようになりました。** 1つのリリースが複数回存在する場合、エントリは最初に見つかった追加時刻ではなく、最も古い追加時刻を報告するようになりました。そのため、古いリリースの2つ目のコピーが新しく追加されたように見えなくなります。`recent` 系のディレクトリは、以前残していたリリースを外すことがあります。

**マウントはディレクトリ一覧を12時間キャッシュするようになりました。** `check_for_changes_every_secs` は以前、rclone の `--dir-cache-time` を設定していたため、デフォルトでは15秒ごとに一覧が期限切れになっていました。今は12時間保持され、ライブラリが変わるたびに zurg が該当エントリを明示的に忘れるので、メディアサーバーのスキャンが速いまま保たれます。元に戻したい場合は、直接上書きしてください。`rclone_extra_args` は組み込みフラグより優先されます:

```yaml
rclone_extra_args: ["--dir-cache-time", "15s"]
```

**各アカウントに `__<account>__` ディレクトリが作られるようになりました。** `directories` ではなく `providers` ブロックから作られ、そのアカウントが保持するものをすべて含み、ディレクトリのフィルターは無視し、読み取りをそのアカウントに固定します。`directories` で非表示にすることはできません。アカウントが複数ある場合は、マウントのルートに一覧表示されます。nightly 2026.10.24.0551 より前のビルドでは、単一アカウントのフォルダーもそこに一覧表示されていました。そのnightly以降は、`__all__` が同じライブラリなので、マウントのルート一覧からは外されています。`/http/__realdebrid__/` のような直接の HTTP および WebDAV パスは引き続き応答します。マウント経由では、もう解決されません。`__<name>__` を使っているライブラリやスクリプトは、`__all__` を指すように変更してください。

**同じ名前を持つ2つのリリースが、別々のエントリになりました。** 以前は1つにまとめられ、片方のリリースのファイルがもう片方に黙って畳み込まれていました。素の名前を使わない方には、info hash の先頭6文字がサフィックスとして付きます（例: `Movie.2024 {a1b2c3}`）。この接尾辞付きの文字列に対して `regex`、`not_regex`、`contains`、`not_contains` がマッチするため、行頭・行末を固定したパターンは一致しなくなります。

別件として、重複したベース名で区別されていたエントリは、アップグレード時に一度だけ名前が変更されます。アカウントが発行したファイル ID から、パスに基づくタグへ変わります。

**`.strm` ファイルの形式が変わります。** `serve_strm_files` を使っている場合、マウントが提供するすべての `.strm` は内容と報告されるサイズが変わります。URL は、1つのアカウントのリンクではなく、ライブラリのエントリを指すようになったため、フェイルオーバーしたり修復後も使えたりします。メディアサーバーは、すべての `.strm` が変わったことを検知します。`save_strm_files` を使っている場合、すでに書き出されているファイルは、zurg の初回起動時に同じ名前のまま in place で書き換えられ、メディアサーバーは次回のスキャンで新しい URL を取り込みます。新しい形式は `data/strm_secret` にあるシークレットで署名されます。書き込めない場合、zurg は警告をログに出して起動は続行しますが、次回の再起動後にリンクが解決されなくなります。無視しないほうがよいです。

**`load_dumped_torrents` はアップグレード前の `dump/` を読み込まなくなります。** キャッシュされたトレントには、どのアカウントから来たかが記録されるようになり、その記録がないものはスキップされます。メインキャッシュは次回の更新時にアカウントから再インポートされます。`dump/` の背後にはアカウントがないため、空の状態で読み込まれ、ログに警告が出ます。必要なら、稼働中のインスタンスから再エクスポートしてください。

**`restrict_repair_to_cached` と `only_full_torrent_repair` が false のとき、修復の経路が変わります。** どちらも `true` に設定した場合は変わりません。両方オフ（デフォルト）の場合、ファイルごとの方式とバッチ方式は、壊れたファイルを指定した単一の再追加に置き換えられました。目的は同じですが、アカウントへのリクエストの内容が変わります。

**細かい変更点です。** `ignore_renames` は、ディスク上の `.zurgtorrent` の名前も決めるようになりました（読み込み時に自動で移行します）。`retries_until_failed` は、Real-Debrid のフェアユース再試行の上限になりました。以前は無限に再試行していました。`auto_analyze_new_torrents: false` と `ffprobe_binary` が見つからない場合でも、キャッシュのクリーンアップが抑制されなくなりました。以前は分析と一緒にスキップされていました。アーカイブの最初のボリュームを除外するサイズフィルターは、後続のボリュームにフォールバックするのではなく、そのアーカイブ全体を非表示にするようになりました。認証不要の静的アセットは `/static/css/*` から `/static/*` に広がりました。以前保護されていたルートが公開になったものはありません。

## Windows の設定 {#windows-configuration}

Windows で zurg を動かすときは、パスの書き方を変える必要があります:

```yaml
# Mount path - use drive letter with escaped backslash or forward slash
mount_path: "P:\\"       # Drive letter (escaped backslash)
mount_path: "P:/"        # Drive letter (forward slash also works)

# Binary paths - use forward slashes for paths to executables
ffprobe_binary: "Q:/zurg/bin/ffprobe.exe"
rclone_binary: "Q:/zurg/bin/rclone.exe"

# Alternative: use double forward slashes (also valid)
ffprobe_binary: "Q://zurg//bin//ffprobe.exe"
rclone_binary: "Q://zurg//bin//rclone.exe"
```

**Windows で気をつけるポイント:**
- すべてのパスを引用符で囲む
- `mount_path` にはドライブ文字を使う。例: `P:\`（YAML では `P:\\` と書く）または `P:/`
- バイナリのパスは、フォワードスラッシュ `/` を使うと、エスケープの問題を避けられる
- 実行ファイルには `.exe` 拡張子を必ず付ける

## 1. 基本設定（最初に行うこと） {#1-essentials-setup-first}

これがサーバーを起動するために必ず必要な設定です。

| 項目 | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `zurg` | string | *(必須)* | 設定バージョンの識別子です。必ず `v1` に設定してください。それ以外の値（キーがない場合を含む）では読み込みに失敗します。 |
| `providers` | list | *(必須)* | Debrid と Usenet のアカウントを、1 つずつ登録します。下の [Accounts](#accounts) を参照してください。プロバイダー設定より前からあるトップレベルの `token`、`download_tokens`、`strm_link_token` は非推奨です。これらは単一の Real-Debrid アカウントとして引き続き読み込まれ、起動時に警告が表示されます。Real-Debrid をすでに設定した `providers` ブロックがある場合は、そちらが優先され、余分なキーは無視されます。 |
| `mount_path` | string | OS により異なる | rclone のマウント先となるファイルシステムのパスです。zurg はこのパスをメディアサーバー（Plex、Jellyfin、Emby）に伝え、ファイルの場所を知らせます。`rclone_enabled` が true の場合は、マウントポイントとしても使われます。デフォルトは Linux が `/mnt/zurg`、macOS が `/Volumes/Zurg`、Windows が `Z:` です。Docker を使う場合は、`/zurg_mnt:/zurg_mnt:rshared` のボリュームマウントと合わせて、このパスを `/zurg_mnt/zurg` に設定してください（[docker.md](../setup/docker.md) を参照）。 |
| `base_url` | string | `""` | zurg インスタンスの、外部からアクセス可能な URL です。STRM ファイルに埋め込まれ、メディアサーバーがコンテンツをストリーミングするために使われます。未設定の場合、STRM ファイルには `localhost` の URL が書き込まれ、他のデバイスからは動作しません。Tailscale の IP、LAN の IP、またはリバースプロキシで公開したドメインを使ってください。例: `http://100.x.x.x:9999` |

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/mnt/zurg"
base_url: "http://192.168.0.123:9999"
```

### アカウント {#accounts}

`providers` の各エントリが1つのアカウントです。いくつでも同時に動かせます。Real-Debrid、TorBox、AllDebrid、Premiumize、Debrid-Link、Offcloud を一緒に使うこともできますし、同じサービスのアカウントを複数使うこともできます。

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `type` | string | *(必須)* | アカウントが使うバックエンドの種類です。`realdebrid`、`torbox`、`alldebrid`、`premiumize`、`debridlink`、`offcloud`、`nzb`、`torbox_nzb`（[TorBox がホストする Usenet](../providers/torbox-nzb.md)）のいずれかを指定します。 |
| `name` | string | `type` の値 | このアカウントを、同じ種類の他のアカウントと区別します。`provider` フィルター、[アカウントごとのディレクトリ](#per-account-directories)、キャッシュパス、ダッシュボードで使われる名前です。名前はエントリ間で一意でなければならず、`e` は STRM のリンクルーティング用に予約されています。 |
| `token` | string | *(必須)* | アカウントの API トークンまたはキーです。Real-Debrid のものは http://real-debrid.com/?id=20475782 から、TorBox のものは https://torbox.app/settings から、AllDebrid のものは https://alldebrid.com/apikeys?uid=1kk5i から取得します。`nzb` では使われません。代わりに `nntp` で認証します。Real-Debrid のトークンは、環境変数 `TOKEN` または `RD_TOKEN` で指定することもできます。初回起動時に設定を自動で作成します。 |
| `download_tokens` | list | `[]` | **Real-Debrid と AllDebrid:** 同じサービスのバックアップ API トークンです。現在のトークンの帯域上限に達したときに使われます。このエントリのカタログ（[ローカルカタログ](#local-debrid-catalogs) を含む）をそのまま使い、追加アカウントのトレントライブラリは読み込みません。**TorBox:** 受け付けられますが、トークンを切り替えてもアカウント固有のトレント/ファイル ID は再マッピングされません。別のアカウントには別のプロバイダーエントリを使ってください。**NZB:** 使われません。Premiumize、Debrid-Link、Offcloud では、保存されたファイル ID がリストを取得したアカウントに属するため、別のアカウントエントリが必要です。 |
| `strm_link_token` | string | `""` | `/strm/` エンドポイントに届く読み取りを解決する、専用の API トークンです。プレイヤーが `.strm` を開いても、ライブマウントがストリーミングに使っているトークンを消費しないようにします。未設定の場合は `token` にフォールバックします。**Real-Debrid と AllDebrid** — 認証情報をローテーションする2つのバックエンドで、`.strm` のトラフィックを専用のキーに固定する意味があるのはこの2つです。`torbox` と `nzb` のエントリでは受け付けられますが使われません。Premiumize、Debrid-Link、Offcloud では、このアカウント自身の `token` のみ受け付けます。 |
| `disabled` | bool | `false` | アカウントを設定に残したまま、読み込まないようにします。すべてのエントリが無効だと、読み込みに失敗します。 |
| `watchlist` | bool | `false` | 新しいトレントの追加で最初に試されるアカウントに指定します。対象はダウンロードクライアントのエンドポイントと、acquisition の Torznab インデクサーです。設定できるのは1エントリだけで、`nzb` と `torbox_nzb` のエントリには設定できません。どれも設定しない場合は、トレントを追加できる最初のアカウントが使われます。acquisition の NZB は Usenet バックエンドに送られ、このアカウントには送られません。詳しくは [Watchlist](#watchlist) を参照してください。 |
| `add_torrents` | bool | `true` | このアカウントに新しいトレントを割り当てるかどうかです。ダウンロードクライアントのエンドポイントに渡されるものと、acquisition が Torznab インデクサーから取得するものが対象です。アーカイブ用のアカウントや、クォータが他で使い切られているアカウントには `false` を設定してください。そのアカウントはライブラリの提供と読み込みを続けますが、新しいものは一切追加されなくなります。**`providers:` リストの順序は、追加を受け付けるアカウントが試される順序です。** そのため、このキーとリストの順序はセットで読まれます。`watchlist: true` のアカウントは、リスト内の位置に関係なく最初に試されます。同じエントリで `watchlist: true` と組み合わせることはできません。`nzb` エントリでは無視され、起動時に警告が出ます。ニュースサーバーにトレントが渡されることはないためです。詳しくは [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see) を参照してください。 |
| `warm_connections` | int | `1` | このアカウントが **使用してきた各ホスト** に対して、接続を開いてハンドシェイク済みの状態で維持する数です。読み取りのたびに接続を開く待ち時間を省けます。上限は 4 です。`-1` にすると何も維持しません。`nzb` エントリでは無視されます。NZB の下限はアカウントごとに決まり、[`nntp.warm_connections`](../guides/usenet.md) で設定します。詳しくは [warm connections](#warm-connections) を参照してください。 |
| `nntp` | block | *(`nzb` では必須)* | ニュースサーバーの認証情報です。`nzb` タイプでは必須で、それ以外のタイプでは無視されます。 |

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    strm_link_token: YOUR_RD_API_TOKEN_FOR_STRM
    download_tokens:
      - ANOTHER_RD_API_TOKEN
      - ANOTHER_RD_API_TOKEN_2
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    watchlist: true
  - type: realdebrid
    name: rd-backup
    token: YET_ANOTHER_RD_API_TOKEN
    disabled: true
```

TorBox の `download_tokens` 設定では、RD と AD のロックされたリンクで可能な、アカウントをまたいだ再生フォールバックは提供されません。リゾルバーはトレント/ファイル ID を既存のソースから保持したまま、API キーだけを切り替えます。TorBox のプロバイダーエントリを別々に用意すると、各アカウントの ID とカタログが独立したままになります。ローカルライブラリの場合は、ポータブルなマニフェストを各エントリ自身のソースディレクトリに置いてください。

#### TorBox のシーディング {#torbox-seeding}

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `tb_seed_torrents` | 文字列 | `never` | zurg が TorBox アカウントに追加するトレントをシードするかどうかを決めます。`never` は追加するすべてのトレントでシードをオフにします。`auto` は TorBox アカウントのシード設定に任せます。`always` は追加するすべてのトレントでシードをオンにします。設定内のすべての TorBox アカウントに適用され、変更すると次に追加するトレントからすぐ反映されます。それ以外の値を指定すると、zurg は起動しません。 |

```yaml
tb_seed_torrents: never
```

特別な理由がなければ `never` のままにしておいてください。この設定は、アップロード量で評価するプライベートトラッカー向けのものです。[`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see) エンドポイント経由で `.torrent` ファイルとして取得したリリースは、この設定で追加されます。そのため `always`（または、シードするよう設定したアカウントでの `auto`）にすると、TorBox がそのファイルをトラッカーのスウォームへアップロードし直します。Sonarr や Radarr にインポートしても、これは止まりません。クライアントが削除した完了済みのダウンロードも、アカウント上に残ります。

**シード中のトレントは、シードしている間ずっとプランのアクティブスロットを1つ占有します。** TorBox は、シード中のトレントもダウンロード中のトレントと同じように数えます。プランごとの同時上限は 3、5、10 です（Essential、Standard、Pro）。シード時間はそれぞれ最大 24 時間、14 日、30 日です。すべてのスロットがシード中のトレントで埋まると、そのアカウントでの新しい取得と修復は、トレントのシード時間が終わるか、TorBox 上でトレントを削除してスロットが空くまで止まります。シードは、TorBox のフェアユース上限にもアップロードとしてカウントされます。`never` にしておけば、これらは一切起きません。だからこれがデフォルトになっています。

`auto` は TorBox にシードの指定を一切送りません。そのため、アカウントのシード設定がそのまま適用されます。誰も変更していないアカウントでは、TorBox 側の Auto になります。`always` と `never` は、zurg が追加したトレントに対してだけアカウント設定を上書きし、アカウント内のそれ以外には手を加えません。

#### Usenet アカウント {#usenet-accounts}

`nzb` タイプは debrid サービスではなく Usenet です。`nzbs/` ディレクトリに置いた `.nzb` ファイルが、ライブラリ内のトレントになります。読み込みは、ニュースサーバーから記事を取得して、その場でデコードすることで行われます。

有効な `nzb` エントリは 1 つだけサポートされています。両方が同じディレクトリをスキャンしてしまうためです。追加のニュースサーバーは、そのエントリの `nntp.servers` に入れてください。同じライブラリを提供するもので、別のコピーを作るわけではありません。

[`torbox_nzb`](../providers/torbox-nzb.md) の隣に `nzb` エントリがあると、同じ理由で拒否されます。その種類は、専用の作業ディレクトリを持つ別のインスタンスで実行してください。

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `host` | string | *(必須)* | ニュースサーバーのホスト名です。例: `news.example.com`。 |
| `port` | int | TLS 使用時は `563`、未使用時は `119` | ニュースサーバーのポートです。 |
| `tls` | bool | `false` | 接続を TLS でラップします。 |
| `username` | string | `""` | アカウントのユーザー名です。 |
| `password` | string | `""` | アカウントのパスワードです。 |
| `connections` | int | `8` | アカウントが同時に使える接続数です。zurg はこの数で読み込みます。1 本の接続はプランのスループットの一部しか運ばないので、ストリーミングでは 1 記事ずつ取得するのではなく、許可された接続数をフルに使います。プランの上限を超えると接続が拒否されるため、実際の数に合わせて設定してください。 |
| `pipeline_depth` | int | `4` | 1 本の接続で zurg が同時に要求する記事数です。上限は 8 です。同時に複数のコマンドを処理できないサーバーでは `1` に設定してください。バッチが何度も途切れると、zurg は警告を出して自動的に 1 に下げます。 |
| `socket_receive_buffer_kb` | int | 未設定 | 各接続のカーネル受信バッファを、この KiB 数に固定します。未設定のままにしてください。固定したバッファはカーネルによるチューニングの対象外になります。Linux では受信ウィンドウが約 64 KiB に張り付き、遅延のある回線ではアカウントのスループットの大部分が失われます。チューニングをしないカーネルや、上限が低すぎるカーネル向けの設定です。 |
| `cache_size_mb` | int | `512` | デコード済みの記事データをメモリに保持する量です。ファイルごとではなく、読み込み中のすべてのファイルで合算した量になります。 |
| `servers` | list | `[]` | 記事単位でフォールバックする追加のニュースアカウントです。[複数のニュースサーバー](#more-than-one-news-server)を参照してください。 |

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
```

##### 複数のニュースサーバー {#more-than-one-news-server}

保持期間はプロバイダーごとに違います。あるサーバーで古くなって消えた記事は、別のサーバーにはまだ残っていることがとても多いです。2つ目のアカウントがなければ、消えた記事を取り戻す方法は PAR2 だけで、それには**リリース全体**を読み直す必要があります。つまり、2つ目のサーバーがあれば、記事を1つ取得するだけで済みます。なければ、全部を読み直すことになります。

上に書いたキーは最初のアカウントを表します。`servers` の下にあるものは追加のアカウントで、それより前のアカウントに記事がなかった場合にだけ問い合わせられます。既存の単一サーバー設定は、変更なしでそのまま動きます。

| オプション | 型 | 既定値 | 説明 |
|--------|------|---------|-------------|
| `name` | string | `host` の値 | ログでアカウントに名前を付けます。 |
| `host`, `port`, `tls`, `username`, `password`, `connections`, `pipeline_depth`, `warm_connections`, `socket_receive_buffer_kb` | | | 上と同じです。各アカウントは独自の接続数の上限を持ちます。パイプラインと受信バッファーはアカウントごとに設定します。これらへの耐性はサーバー側の特性だからです。 |
| `priority` | int | `0` | 問い合わせる順番です。値が小さいものから先に問い合わせます。同じ priority のアカウントは書かれた順に問い合わせますが、空きコネクションのあるアカウントを、上限を使い切ったアカウントより優先します。そのため、同じ条件の2つのアカウントで負荷を分け合えます。 |
| `backup` | bool | `false` | ブロックアカウントであることを示します。すべてのプライマリが*no such article*と答えた後にだけ問い合わせられます。プライマリが**busy**なだけでは不十分です。無制限のアカウントで取得できたはずのものに従量課金のバイトを使わないよう、zurg はプライマリが空くまで待ちます。 |
| `backbone` | string | `""` | このアカウントが解決する記事スプールです。同じ backbone の2つのアカウントは同じ記事を保持しています。そのため、片方が記事がないと答えたら、もう片方には同じ質問をせずスキップします。 |

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # the first account
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com          # only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

リリースを修復すべきかを判断する census（棚卸し）は、記事がないと判定する前にすべてのアカウントに問い合わせます。そのため、あるプロバイダーで穴があいていても、別のプロバイダーで配信できるリリースでは PAR2 の再構築が走りません。

トップレベルのキーは、修復の後に何が残るかを管理します。

| オプション | 型 | 既定値 | 説明 |
|--------|------|---------|-------------|
| `par2_patch_cache_mb` | int | `512` | PAR2 修復で再構築されたバイト列が `data/par2/` のうちどれだけを占めてよいかを指定します。これらのバイトは、リーダーがニュースサーバーに再度要求できない唯一のものです（それを運ぶ記事はもう存在しないため）。保持しておけば、再起動のたびに同じ数メガバイトを取り戻すためにリリース全体を読み直す必要がありません。保存されるのは壊れた記事の範囲だけで、破損したリリース1つあたり一桁のメガバイトです。予算を超えると、リリース単位で最も長く使われていないものから削除されます。負の値を指定すると永続化をオフにし、修復はプロセスが動いている間だけメモリに保持されます。 |

さらに、2つのキーは解析済みNZBがメモリ上で占めるサイズを決めます。

| オプション | 型 | 既定値 | 説明 |
|--------|------|---------|-------------|
| `nzb_segments` | string | Linux/macOS/BSD では `mmap`、Windows では `resident` | 解析済みNZBの記事リストをどう保持するかを指定します。**再起動が必要です。** `mmap` はリストを `data/nzb-index/<id>.bin` に書き出し、必要なときにそのファイルをマップします。そのためバイト列は zurg のヒープではなくページキャッシュに置かれます。`reparse` は、リリースが落ち着いたらメモリを解放し、読み取りや修復で必要になったときにNZBをディスクから読み直します。ディスク容量は一切使いません。`resident` は、プロセスが動いている間ずっと全部をメモリに保持します。これは**従来の動作**で、それ以前のビルドはすべてこの方式でした。認識できない値は既定値になり、起動時の警告にその旨が表示されます。実際に有効なモードは、いずれの場合も起動時にログに記録されます。 |
| `nzb_segments_idle_secs` | int | `120` | 遅延モードで、読み取りが最後に行われてからリリースの記事リストを保持する時間です。**再起動が必要です。** 掃除（sweep）は30秒ごとに実行されるため、10 が守れる最短の時間で、Dashboard の下限値にもなっています。`resident` では無視されます。`resident` はメモリを一切解放しないためです。`0` は既定値になります。 |

このトレードオフははっきり書いておく価値があります。よくあるメモリとスピードの取引とは違うからです。一覧取得（ライブラリ更新、フィンガープリント確認、ジョブが落ち着いたかを尋ねる *arr の問い合わせなど）は、どのモードでも記事に触れることはありません。ファイル名、サイズ、記事数はエントリ自体から答えられます。遅延モードのコストは、`nzb_segments_idle_secs` の間まったく触れられていなかったリリースに対する*最初の*読み取りです。節約できるのは、それ以外の時間に記事リストが占めるヒープです。60ファイル、30,000セグメントのリリース（Apple M3 Pro）で計測した結果は次のとおりです。

| | 落ち着いた後のリリースあたりのヒープ | アイドル状態のリリースの最初の読み取り | 読み取り経路での記事1件あたり |
|---|---|---|---|
| `resident` | 1.74 MB（58 B/セグメント） | — | 6 ns |
| `reparse` | 21.3 kB（0.71 B/セグメント） | 39 ms | 52 ns |
| `mmap` | 16.6 kB（0.55 B/セグメント） | 0.27 ms | 63 ns |

`mmap` の再読み込みの3分の2は、マップしたばかりのインデックスに対するチェックサムです。マップ自体は 0.08 ms です。それでも価値があります。チェックサムがなければ、アリーナ内の1バイトの誤りが、誰も投稿していないメッセージ ID として提供されてしまいます。ニュースサーバーはそれを存在しない記事として返し、その上のすべての層はそれをリリースの破損とみなします。

実際のライブラリ（NZB 2,636件、セグメント 27.6 million）で、同じバイナリをスキャン後のアイドル状態で同じコーパスに対して3回実行した結果は次のとおりです。

| | 常駐メモリ（resident set） | 実ヒープ | アイドル時のCPU | コールドオープン（p50） | ディスク上のインデックス |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

ウォームオープン、ストリーミングのスループット、起動時間には差が見られませんでした。実際にマッピングできる環境では `mmap` が既定値です。ディスク以外のすべての面で勝るからです。コールドオープンでも勝ちます。書き込まれたアリーナのマップはシステムコール1回で済みますが、NZB を再度解析すると数メガバイトの XML を読むことになるからです。記事1件あたり約55バイトのディスク容量と、スキャン時にリリースごとに1回の余分な書き込みがかかります。インデックスは NZB が変わるたびに書き直され、NZB が削除されると一緒に削除されます。`data/` が大きくなってはいけないホストでは `reparse` を選んでください。Windows にはマッピングがありません。インデックスはヒープに読み込まれることになり、それは常駐メモリに加えて再読み込みもかかるということです。そのため Windows では既定値が `resident` のままで、遅延モードとして選ぶ価値があるのは `reparse` です。

## 2. メディアサーバー連携 {#2-media-server-integration}

zurg をメディアサーバーに接続すると、ライブラリの更新、メタデータの照合、ウォッチリストの監視が自動で動くようになります。

### Premiumize、Debrid-Link、Offcloud {#premiumize-debrid-link-and-offcloud}

```yaml
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY_OR_OAUTH_TOKEN
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_TOKEN
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
```

これらのバックエンドは、ライブラリの閲覧、ストリーミングとリダイレクトによる読み取り、STRM、マグネットリンクの追加、`.torrent` のアップロードと削除に対応しています。各アカウントは、それぞれ専用の `__<name>__` ディレクトリにも表示されます。アカウントは、ダッシュボードか `zurg setup` で追加してください。手動操作なしのセットアップでは、`--premiumize-token-file`、`--debridlink-token-file`、`--offcloud-token-file` のほか、`PREMIUMIZE_TOKEN`、`DEBRIDLINK_TOKEN`、`OFFCLOUD_TOKEN` も使えます。

Premiumize では、完了した転送と、転送リストを消去した後も残っているクラウドファイルがマウントされます。ネストされたフォルダはパスをそのまま維持します。zurg 経由で渡されたハッシュは `data/premiumize/<account>/sources.json` に保存されるので、再起動や完了済み転送の消去後も、アカウント間のハッシュ照合が維持されます。ハッシュが記録されていないインポート済みのクラウドコンテンツもストリーミングはできますが、ハッシュによる修復や、別アカウントとのハッシュ照合はできません。zurg から Premiumize の転送を削除すると、その転送が所有するファイルも一緒に削除されます。クラウドストレージとフェアユース（fair-use）のクォータは、引き続きアカウント自身の上限になります。

Debrid-Link は、ページネーションを使ってシードボックスの一覧を取得し、各ファイルはそのIDで解決します。廃止されたキャッシュエンドポイントは使っていません。そのため、キャッシュのみの追加では、ヒットかどうかは追加時のレスポンスからしか判断できません。1日あたりの追加回数やトラフィックのクォータ超過は、アカウントの上限として報告されます。フラッド拒否（flood refusal）を受けると、バックエンドは一時停止します。

Offcloud は、cloud explore エンドポイントを通じてファイルハンドルを解決します。ファイルサイズは配信サーバー側で照合されます。キャッシュされた torrent のメタデータは、一意に対応付けられる場合にフォルダパスを補完します。曖昧なファイル一覧はエラーとして報告されます。不正な形式のマグネットリンクは、送信前に拒否されます。

配信URLは、キャッシュの期限が切れたとき、または読み取りで無効と判定されたときに更新されます。生成されたURLとSTRMへのアクセスは非公開にしてください。プロバイダのクォータは、データを配信しているアカウントに属します。これら3つのバックエンドでは、アカウントエントリごとに1つの認証情報を使い、別のアカウントのファイルIDを使い回すことはありません。

### Plex 連携 {#plex-integration}

| 項目 | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `plex_server_url` | string | `""` | Plex サーバーの URL。Plex のマッチングとウォッチリスト機能に必要です。例: `http://localhost:32400` |
| `plex_token` | string | `""` | Plex の認証トークン。`plex_server_url` と一緒に必要です。 |
| `plex_scan_check_url` | string | `plex_server_url` の値 | zurg がマウントを再起動する前に、Plex でライブラリのスキャンが実行中かどうかを確認する先のサーバーです。スキャン中は待機します。スキャンの途中でマウントが消えると、Plex は見えなくなったものをすべてゴミ箱に入れてしまいます。独自の Plex 連携を動かしていないインスタンスに設定してください。通常は、プロバイダーごとに 1 つのインスタンスを用意します。ここで `plex_server_url` を設定すると、Plex のマッチングも始まってしまいます。 |
| `plex_scan_check_token` | string | `plex_token` の値 | `plex_scan_check_url` 用のトークン。 |
| `plex_match_every_mins` | int | `1440` | zurg が Plex ライブラリをスキャンして、torrent を Plex のアイテムにマッチングする頻度（分単位）。どの torrent がどの Plex メディアに対応するかを表示する機能などに使われます。最小 1。`0` の場合はデフォルト値になります。`mount_path` の設定が必要です。 |
| `plex_watchlist_enabled` | bool | `false` | `watchlist.enabled` の旧い書き方です（[Watchlist](#watchlist) を参照）。今も有効です。 |
| `plex_watchlist_check_every_secs` | int | — | `watchlist.check_every_secs` の旧い書き方です。ブロック側で設定されていない場合は、今も有効です。 |
| `watchlist_quality` | string | `"best"` | `watchlist.quality` の旧い書き方です。ブロック側で設定されていない場合は、今も有効です。 |
| `plex_settings_policy` | string | `"guard"` | デビッドマウントにとって重要な Plex の設定を、zurg がどこまで修正してよいかを決めます。`off`（何も触らない）、`warn`（すべて報告するが変更はしない）、`guard`（間違った値でライブラリが失われる設定だけを修正し、残りは報告）、`enforce`（誰も見ない結果のためにファイル全体をデコードさせてしまう設定も修正）のいずれかです。Skip Intro、Skip Credits、プレビューのスクラビング、チャプター画像、音量の均一化、sonic analysis など、表示機能が絡むものは常に報告だけです。[Plex settings](../guides/plex.md#recommended-plex-settings) を参照してください。 |
| `plex_settings_ignore` | list | — | ポリシーに関係なく zurg が触らない Plex の設定 ID。大文字と小文字は区別しません。ティア単位ではなく設定単位で指定するので、1 つを除外しても、その隣の設定はそのまま対象になります。zurg が知らない ID を指定すると、起動時に報告され、何も変更されません。ダッシュボードの **Let Plex Empty Its Own Trash** スイッチは、この一覧に `autoEmptyTrash` を書き込みます。[Opting out of one setting](../guides/plex.md#opting-out-of-one-setting) を参照してください。 |

> **注:** Plex は、ダッシュボード（Web UI）の認証フローで設定するのが一番です。そのフローが `plex_server_url` と `plex_token` を `config.yml` に書き戻します。上記のキーは手動設定用として引き続きサポートされています。

```yaml
plex_server_url: "http://localhost:32400"
plex_token: "your-plex-token"
plex_match_every_mins: 1440
```

### rex

zurg は、公式 Plex アプリ向けのメディアサーバー [rex](../../rex/with-zurg.md) に中身を入れられます。rex は zurg のすべてのファイルを読み込みます。

| 項目 | 型 | 既定値 | 説明 |
|--------|------|---------|-------------|
| `rex_url` | string | `""` | このzurg からライブラリを作る rex の URL です。例: `http://192.168.1.20:32400`。ダッシュボードの Plex サインインで rex を選ぶと、rex がソースを取得するアドレス（LAN または Tailscale のアドレス、プレーン HTTP）が自動で設定され、再起動なしでフィードが始まります。Plex にサインインせずに rex へフィードしたい場合は、手動で設定してください。zurg は、ライブラリの読み込みが終わったあと、`rex_snapshot_every_hours` ごとに、そしてリリースが追加・解析・名前変更・移動・削除されるたびに、ライブラリを rex に送ります。送るのは、設定済みディレクトリ内のすべての動画ファイル、`rex_music` 指定のディレクトリ内のすべての音声ファイル、`rex_photos` 指定のディレクトリ内のコミックブックです。パス、サイズ、IMDb ID、ffprobe が読み取ったメディア情報も含みます。rex は ffprobe が解析するまでファイルを再生できないため、`rex_url` を設定すると、このキーの値に関係なく `auto_analyze_new_torrents` が有効になります。ライブラリの読み込み後に残りを解析し、その後は毎日解析します。各プローブは、そのリリースを持つアカウントから読み込むため、ディレクトリは狭く絞ってください。見ないライブラリでトラフィックを使いたくない場合は、`tags_*` フィルターを外してください（どれか一つでもあると、そのアカウント上のすべてのリリースが解析されます）。更新時は、新しいリリースを配置する前に `dmm_api_key` を通じて IMDb ID も調べます（配置の仕組みは `dmm_api_key` を参照）。\*arr や Bazarr が `__magic__` 内の動画の横に書き出した字幕も、動画と一緒に rex に送られます（[`__magic__`](../guides/magic.md) を参照）。zurg は rex にファイルの読み込み先も伝えます。その WebDAV は `http://<address>:<port>/dav` で、設定されていれば `username` と `password` も含まれます。アドレスは、`host` が一つのアドレスならそれを使います。そうでない場合（既定）は、zurg から rex への接続が出ていくアドレスになります。rex はそのアドレスで zurg に到達できる必要があります。コンテナ内では、コンテナ自身のアドレスになります。これは同じ Linux マシン上の rex からしか届きません。Windows と macOS では Docker Desktop ではなくインストーラーで zurg を入れてください。Linux で rex が別のマシンにある場合は、zurg のコンテナに `network_mode: host` を設定してください（[rex with zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex)）。停止中の rex には再試行したあと、ライブラリ全体を送ります。待つ処理はありません。`plex_server_url` がこの同じ rex を指している場合は、Plex スキャンは送られません。スナップショットの後と 10 分ごとに、zurg は rex で各リリースに対して行われた Fix Matches を読み取り、それを手動で設定した ID として保存します。ただし、その後に管理ページで別の ID を設定していた場合は除きます。DMM はその ID を使ってリリースを配置します。ディレクトリごとに rex 内で別のライブラリを持たせたい場合は、そのディレクトリに [`rex_shows`, `rex_movies`, `rex_music` or `rex_photos`](#directory-options) を設定してください。rex を使わない場合は、`rex_url` を空のままにしてください。 |
| `rex_source` | string | `"zurg"` | rex がこの zurg を識別するときのソース名です。同じ rex にフィードする zurg ごとに、それぞれ別の名前を付けてください。 |
| `rex_snapshot_every_hours` | int | `6` | ライブラリ全体を rex に再度送る間隔です。送信漏れで残ったものを修復します。既定値はほとんどの環境に合います。 |

```yaml
rex_url: "http://192.168.1.20:32400"
```

### ウォッチリスト {#watchlist}

Plex のウォッチリストに何かを追加すると、zurg がそれを取得します。ウォッチリストに新しく追加された項目はすべて、インデクサーで検索されます。Newznab インデクサーは NZB を返します。それは Sonarr の grab や Stremio の再生とまったく同じように Usenet バックエンドに入ります。3つは命名ルールを共有しているので、互いの grab を見つけて、重複して取得することはありません。Torznab インデクサーはトレントを返します。それは、そのデブリッドアカウントにすでにキャッシュされている場合に限り、そのアカウントに追加されます。`prefer` は、同じ解像度のリリース同士でどちらの種類を先に試すかを決めます。映画は1つのリリースになります。番組はシーズンごとに取得され、シーズンパックは個別のエピソードより先に試されます。誰もパックを投稿していないシーズンは、検索で見つかった個別のエピソードにフォールバックします。各エピソードには最良のリリースが選ばれます。項目は、その背後にあるリリースが確認され、かつ `remove_after_grab` が許可している場合にのみ、ウォッチリストから削除されます。失敗した項目はリストに残ります。5分、10分、15分後に再試行され、その後は1時間後、さらにその後も間隔がどんどん長くなります。2週間失敗し続けたタイトルは、取得ページで再開するまで保留されます。[永続化と復旧](../guides/acquisition.md#persistence-and-recovery) を参照してください。

`plex_token` と、少なくとも1つのインデクサーが必要です。独自のリストがない場合は、Stremio アドオンのリストを借ります。モニターは Plex のクラウドサービスと通信するため、`plex_server_url` は必須ではありません。NZB には、同じインスタンス上の `nzb` または `torbox_nzb` プロバイダーが必要です。トレントには、それを受け付けるデブリッドアカウントが必要です。どちらか一方があれば十分です。

以下のオプションはすべて、インデクサーリストも含めて、設定ページの **Plex Watchlist** にあります。ダッシュボードはレガシーのフラットなキーではなく、このブロックを書き込みます。モニターをオフにすると、`plex_watchlist_enabled` もクリアされます。このキーはスイッチにORで組み込まれているためです。

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | bool | `false` | モニターを開始します。レガシーの `plex_watchlist_enabled` キーも引き続き有効です。 |
| `check_every_secs` | int | `60` | Plex のクラウドサービスでウォッチリストをポーリングする間隔です。 |
| `indexers` | list | `[]` | 検索するインデクサーです。それぞれ `name`、`url`、`api_key`、任意で `api_path` と `type` を指定します。`type: torznab` はトレントインデクサーを表します。省略すると `newznab` になります。`stremio.indexers` と同じ形式で、このリストが空のときはそのまま借ります。 |
| `prefer` | string | `"usenet"` | NZB とトレントの両方が使える同じ解像度のとき、どちらを先に試すかを指定します。解像度が先に判断されるので、2160p のトレントは 1080p の NZB より先に試されます。`usenet` は NZB を先に、`torrents` はトレントを先に試します。`best` はランキングだけで決めます。詳しくは [NewznabとTorznab](../guides/acquisition.md#newznab-and-torznab) を参照してください。 |
| `max_size_gb` | int | `0` | この値より大きいリリースは、映画と単独のエピソードでは除外されます。シーズンパックは、1エピソードあたりこの値を超える場合に除外されます。`0` は制限なしなので、`best` はフルディスクのリミux も選びます。インデクサーがサイズを示していないリリースは残されます。 |
| `max_season_size_gb` | int | `0` | シーズンパックに含まれる各シーズンの上限です。対象はパックが示すシーズンごとです。`0` は制限なしです。パックは、1エピソードあたりの `max_size_gb` が書かれている場合にのみその値で判断されるため、長いシーズンのリミux も含めて数えられます。 |
| `quality` | string | `"best"` | どのリリースを選ぶかを決めます。`best`（解像度が先、次にサイズ）、`4k`、`1080p`、`720p`（その解像度を優先し、なければ best にフォールバック）、`smallest` から選びます。レガシーの `watchlist_quality` キーも引き続き有効です。ここでは値は1つだけです。リストを取れるのは `acquisition.quality` だけです（[取得ソース](#acquisition-sources) を参照）。 |

`acquisition` ブロックには、`concurrency`（デフォルトは `8`、`1` から `200`）も指定できます。これは同時に検索、確認、配置するタイトルの数です。`indexer_concurrency`（デフォルトは `3`、`1` から `16`）は、1つのインデクサーに同時に行う呼び出しの数です。インデクサーのキーを共有している場合は、この値を低く保ってください。

`exclude_words` は、このブロックにはコピーがありません。`DV` や `HDR10+` などの単語をウォッチリストの grab から除外するには、`exclude_words` だけを入れた `acquisition:` ブロックを追加します。上記のすべての設定はそのまま適用されます。詳しくは [リリース名による除外](../guides/acquisition.md#excluding-releases-by-name) を参照してください。

```yaml
plex_token: "your-plex-token"
watchlist:
  enabled: true
  check_every_secs: 60
  quality: best
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: your-api-key
```

### 取得元 {#acquisition-sources}

`acquisition.sources` は、zurg が取得を行うサービスの一覧です。各サービスは、[取得ソース](../guides/acquisition.md)で説明されている共通キューを使います。検索設定（`indexers`、`quality`、`prefer`、`max_size_gb`、`max_season_size_gb`）は `acquisition:` ブロック内で `sources` の隣に置かれ、設定がない場合は上の `watchlist:` ブロックの値を使います。`acquisition.quality` だけは `[1080p, 4k]` のような解像度のリストも指定できます。その場合、zurg は DMM のウォントリストにある映画それぞれについて、各解像度のコピーを保持します。そのリストにあるシリーズや、他のすべてのソースでは、リストの中で最も高い解像度が単一の `quality` として使われます。詳しくは [複数の解像度でそれぞれコピーを保持](../guides/acquisition.md#a-copy-at-each-of-several-resolutions) を参照してください。

`best_first` は `acquisition:` ブロックだけにあり、デフォルトではオフです。オンにすると、`radarr` または `sonarr` ソースの最初の取得が、品質プロファイルの優先順位に従います。許可された中で最も高い解像度が最初に来ます。カットオフ以上のものはすべてカットオフと同じ扱いになります。リリースが失敗すると、zurg はプロファイルの順番を下に辿ります。オフのときは、映画は許可されたリリースのうち確認コストが最も低いものを取ります。シリーズは、`quality` で一番上に来るものを取ります。その後、アップグレードの処理がカットオフを目指します。最良のリリースは大きなアーカイブセットであることが多いため、最初のファイルは遅れて届く傾向があります。詳しくは [プロファイルの最良を最初に取る](../guides/acquisition.md#taking-the-profiles-best-first) を参照してください。

`exclude_words`（リスト、デフォルトは空）もここにあり、watchlist からのフォールバックはありません。名前にこれらの単語のいずれかを含むリリースは、どのソースからでも決して取得されません。一致は単語単位で、大文字小文字は区別しません。そのため `DV` は `DVDRip` にはマッチしません。`DV`、`DoVi`、`Dolby Vision` は1つの単語として扱われ、`HDR10+` と `HDR10Plus` も同様です。`HDR10` と `HDR10+` は別の単語です。文字や数字を含まない項目は起動時に拒否されます。完全なルールと、Radarr・Sonarr のプロファイルとの組み合わせ方は [名前によるリリースの除外](../guides/acquisition.md#excluding-releases-by-name) にあります。

| 設定 | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `name` | string | 必須 | 英数字、`_`、`-` のみ使え、一意である必要があります。ソースの保存済みキューを識別するため、変更しないでください。 |
| `type` | string | 必須 | `plex_watchlist`、`seerr`、`radarr`、`sonarr` のいずれか。 |
| `enabled` | bool | `false` | 無効なソースはファイルに残りますが、ポーリングはされません。無効な `radarr` または `sonarr` ソースも、管理ページの[重複表示](../guides/acquisition.md#finding-duplicate-releases)により読み取り専用で引き続き読まれます。 |
| `check_every_secs` | int | `60` | ソースをポーリングする頻度。 |
| `url` | string | | `seerr`、`radarr`、`sonarr`：サービスの HTTP(S) ベース URL。認証情報、クエリ、フラグメントは含めないでください。URL のベースに加えて、末尾の `/api/v1`（Seerr）または `/api/v3`（Radarr、Sonarr）も受け付けます。 |
| `api_key` | string | | `seerr`、`radarr`、`sonarr`：サービスの API キー。ヘッダーで送信され、URL に含まれることは決してなく、共有されるログや設定からは伏せられます。 |
| `library_path` | string | `mount_path` + `/__magic__` | `radarr` と `sonarr` のみ。\*arr から見た zurg の `__magic__` ディレクトリの場所です。例えば、コンテナが zurg を `/data/zurg` にマウントしている場合は `/data/zurg/__magic__` になります。その下にある映画やシリーズのフォルダは、`__magic__` 内の同じ相対パスに配置されます。それ以外の場所にあるフォルダはスキップされます。絶対パスである必要があります。`Z:\__magic__` のような Windows パスも使えます。zurg は、この値と、\*arr から見た zurg ダウンロードクライアントのダウンロードフォルダの位置も比較し、インポートがコピーになってしまうレイアウトを検出すると報告します。詳しくは [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) を参照してください。 |
| `remove_after_grab` | bool | `true` | `plex_watchlist` のみ。`seerr`、`radarr`、`sonarr` では効果はありません。 |
| `only_new_items` | bool | `true` | `plex_watchlist` のみ。`seerr`、`radarr`、`sonarr` では効果はありません。これらのソースで求められているアイテムは、常に作業対象です。 |

```yaml
acquisition:
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
  sources:
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /data/zurg/__magic__
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /data/zurg/__magic__
```

### Plex ライブラリのメンテナンス（同じホストのみ） {#plex-library-maintenance-same-host-only}

これらの機能を使うには、Plex を zurg と同じマシンにインストールしておく必要があります。Plex のデータベースファイルを直接読み込むためです。`plex_server_url` は別のホストやコンテナを指していることがよくあり、HTTP エンドポイントではそのファイルを渡せません。そのため、これらの機能は明示的なパスで動作し、設定するまでは無効のままです。

zurg はこのデータベースを、読み取り専用のハンドルを通して**読み取る**だけです。書き込むことも、Plex を停止させることもありません。作成するファイルは 1 種類だけで、それは zurg 自身の `data/plex-backups/` 内に置かれるスナップショットです。Plex のディレクトリに作成されることはありません。

| 項目 | 型 | 既定値 | 説明 |
|------|----|--------|------|
| `plex_database_path` | string | `""` | `com.plexapp.plugins.library.db` へのフルパス。空にすると、このセクションのすべての機能が無効になります。 |
| `plex_sqlite_binary` | string | Plex のインストール先: Linux では `/usr/lib/plexmediaserver/Plex SQLite`、macOS では `/Applications/Plex Media Server.app/Contents/MacOS/Plex SQLite`、Windows では `%ProgramFiles%\Plex\Plex Media Server\Plex SQLite.exe` | Plex は独自の SQLite ビルドを同梱しています。標準の `sqlite3` では、このデータベースを読めなかったり、破損させたりすることがあります。 |
| `plex_backups_keep` | int | `5` | 保持するスナップショットの数。それぞれがデータベース全体と同じサイズです。明示的に `0` を指定すると、監視のみ行い、スナップショットは一切作成しません。 |
| `plex_backups_every_mins` | int | `15` | スナップショット間の最小間隔。クラッシュを繰り返す zurg が再起動するたびにデータベースをコピーしてしまうのを防ぎます。 |
| `plex_trash_sweep_every_mins` | int | 未設定(注記を参照) | Plex のエントリのうち、ファイルがマウントから消えているものを削除する頻度。未設定の場合は zurg が判断します。Plex のゴミ箱を空にする処理が他に動いていない場合は 60 分ごとに削除を実行し、Plex 側がまだ空にしている場合は待機します。明示的に `0` を指定すると zurg 自身の削除は無効になり、ゴミ箱の管理はあなたに任されます。負の値を指定すると、修復を含むスイープ全体が無効になります。`0` を指定しても Plex 自身のゴミ箱を空にする処理が戻ってくるわけではありません。それを制御するのは `plex_settings_ignore` と、ダッシュボードの **Let Plex Empty Its Own Trash** スイッチです。詳しくは [ゴミ箱を空にするのは誰か](../guides/plex.md#who-empties-the-trash) を参照してください。 |
| `plex_trash_sweep_max_items` | int | `50` | 1 回のスイープで削除できるエントリの最大数。これを超える場合、スイープは何も削除せずに中止されます。 |
| `plex_trash_sweep_max_percent` | int | `10` | ゴミ箱内の件数に対する割合で指定する同じ上限です。そのため、ライブラリの規模に応じて上限が変わります。 |
| `plex_trash_sweep_min_age_days` | int | `14` | スイープがエントリを削除できるまで、赤いゴミ箱アイコンが表示され続ける期間。zurg が判定を持たないエントリのためのフォールバックです。zurg が永久に無効だと把握しているリリースは、この待機なしで削除されます。修復中のものは、経過日数に関係なく残ります。明示的に `0` を指定すると、他のガードが許す限りすぐに削除されます。 |

**スナップショットが必要な理由**: Plex は毎晩自動でバックアップを取っていますが、危険なのは Plex がスキャン中にマウントが乱れることです。その場合、ライブラリは数秒で空になることがあります。毎晩のバックアップは、その時点で 24 時間前のものになっている可能性があります。一方、zurg がマウントに触れる直前に取ったスナップショットなら、数秒前の状態です。

#### ごみ箱の掃除で決して削除されないもの {#what-the-trash-sweep-will-never-remove}

Plexのごみ箱は、削除してよいものの一覧ではありません。削除候補の一覧にすぎず、そのうちかなりの割合は間違っています:

- **まだファイルが残っているアイテム。** 映画の複数バージョンのうち1つが消えただけでも、Plexはその映画全体を削除済み扱い（tombstone）にします。そのため、ごみ箱に入っていても再生できるバージョンが残っていることがよくあります。スイープは、その幽霊バージョンを削除して対応します。すると、コレクション、アートワーク、視聴状況、`added_at` をそのまま保ったまま、アイテムがごみ箱から戻ります。何らかの理由でこの修復に失敗した場合、アイテムには **手を付けません**。ライブラリに残り、ごみ箱アイコンが付いたままになります。削除されることは決してありません。
- **エピソードがまだ残っているシリーズやシーズン。** これら自体はファイルを持っていないので、マウントの状態を理由に削除する根拠はありません。
- **削除直前に、ファイルが欠けていることを個別に確認できていないもの。**

削除はPlex標準の`emptyTrash`ではなく、アイテムごとに行います。`emptyTrash`はセクション全体が対象なので、上で挙げたものまでまとめて消えてしまいます。スイープが絶対にやってはいけないのが、まさにそれです。

#### zurg は戻ってくるかどうかをすでに把握している {#zurg-already-knows-whether-it-is-coming-back}

ファイルが見つからないエントリーはすべて、タイマーに頼る前に、zurg 自身の修復状態を確認します。

| zurg の判定 | スイープの動作 |
|---|---|
| ファイルがまだ読める（フィルターによりマウントからは隠れている） | 経過日数の期間にフォールバックする |
| 壊れているが、修復はまだ諦められていない | **エントリーを残す**。修復にどれだけ時間がかかっても |
| 壊れていて、修復不可能な理由がある（infringing、invalid、not allowed など） | **すぐに削除する**。待っても元に戻らないため |
| 判定なし（torrent がアカウントから完全に消えた場合、またはパスが解決できない場合） | 経過日数の期間にフォールバックする |

複数のバージョンを持つアイテムは、1つのまとまりとして判定されます。1つでも修復中のバージョンがあれば、アイテム全体を残します。すべてのバージョンが無効と確定した場合にのみ、そのエントリーは無効とみなされます。照会に失敗したことを理由に削除することは決してありません。zurg が保証できないものは、以下の経過日数の期間によって、これまでどおり扱われます。

#### ごみ箱アイコンは状態表示なので、削除は待機する {#the-trash-icon-is-a-status-so-removal-waits}

Plex には 3 つの状態があり、問題として目に見えるのは真ん中の状態だけです。

| 状態 | 見えるもの |
|---|---|
| Live | 通常のエントリで、再生できます |
| **Trashed** | エントリは**ライブラリに残ったままで、件数にも含まれ**、グレーアウトして**赤いゴミ箱アイコン**が付きます。再生はできません |
| Purged | 何も表示されません。エントリは Plex から完全に消えています |

ゴミ箱アイコンは、コンテンツが消えたことを知らせてくれる唯一の通知です。エントリを purge すると、その通知も一緒に消えてしまいます。アイテムは目に見えて壊れている状態ではなくなり、ただ存在しなくなります。そのため、zurg が判定を下していないエントリは、アイコンが `plex_trash_sweep_min_age_days` の期間付いたままになるまで放置されます。この猶予期間は、問題に気づいて再取得するためのチャンスです。その後も壊れたままのものは、削除しても良いジャンクだったということです。

猶予期間は、キャップやマウントプローブに加わる 3 つ目の安全層としても働きます。一時的なマウントの問題は、猶予期間が過ぎるよりずっと前に自然に解消されることが多いです。

猶予期間が適用されるのは**削除のみ**です。修復では再生可能なアイテムがライブラリに戻るので、猶予期間に関係なく次のスイープで実行されます。待ってしまうと、正常に動くアイテムが理由もなくゴミ箱アイコンを付けたままになってしまうからです。

これらの状態はどれもファイルには影響しません。ファイルはすでにマウントから消えていて、それがトゥームストーンの原因です。また、debrid アカウントから何かが削除されることもありません。

#### 実行されないとき {#when-it-refuses-to-run}

- zurg は rclone を管理していません（`rclone_enabled: false`）。zurg は自分が所有していないマウントを保証できないので、「ファイルがない」という判断には意味がありません。
- rclone が動いていないか、マウントが読めない状態です。プローブはファイルを `stat` で確認するのではなく、実際に開いて読み込みます。`stat` は rclone のディレクトリキャッシュから答えるため、読み込みが止まった後もずっと成功し続けてしまうからです。
- Plex がスキャン中です。スキャン中は、まだ何が欠けているかを判断している最中です。
- どちらかの上限を超えてしまう場合。これが一番重要です。**空だけど読めるマウントは、他のチェックをすべて通過してしまい**、ライブラリ全体が削除されたように見せてしまいます。上限を超えると、スイープ全体が中止され、何も削除せず、その旨をログに書き出します。

削除の前にスナップショットを取ります。スナップショットに失敗した場合は、スイープ全体が中止されます。

> **無効にする方法：** `plex_trash_sweep_every_mins: 0` を設定します（キーを削除するのは同じ意味ではありません。その場合 zurg は、Plex が自分のゴミ箱を空にするかどうかで判断します）。変更を反映するには zurg の再起動が必要です。これは zurg による削除だけを止めます。Plex に自分のゴミ箱を再び空にさせたい場合は、ダッシュボードの **Let Plex Empty Its Own Trash** スイッチを使うか、`plex_settings_ignore` に `autoEmptyTrash` を書きます。

```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plex_trash_sweep_every_mins: 360
plex_trash_sweep_min_age_days: 14
plex_trash_sweep_max_items: 50
plex_trash_sweep_max_percent: 10
```

このパスは、Linux パッケージがデータベースを保存している場所です。macOS と Windows では、zurg が `~` や `%LOCALAPPDATA%` を展開しないため、パスはフルで書いてください。`plex_sqlite_binary` は、各システムで Plex がインストールされる場所をすでにデフォルトにしています。

| Plex の環境 | `plex_database_path` |
|---|---|
| macOS | `/Users/you/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db` |
| Windows | `C:\Users\you\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db` |

Windows のパスは、YAML でシングルクォートで囲んでください。そうすればバックスラッシュがそのまま残ります。

> **zurg の外にある関連する Plex の設定：** Plex の *Settings → Library → Empty trash automatically after every scan* を **オフ** にしてください。これは Plex ではデフォルトでオンになっていて、zurg のマウントでは危険です。一時的に読めないマウントに当たったスキャンが、ゴミ箱に入れる代わりにライブラリを完全に削除してしまうからです。ゴミ箱に入れておけば、マウントが戻ったときに一緒に復元されるはずのものが、消えてしまいます。デフォルトの `guard` ポリシーでは zurg がこれを自動的にオフにし、ダッシュボードとログにその旨を表示します。ファイルがライブラリのフォルダ間で移動して、その掃除機能が必要な場合は、設定ページの **Let Plex Empty Its Own Trash** スイッチで Plex に再び任せられます。ただし、自己責任でお願いします。

### その他の連携 {#other-integrations}

| 設定項目 | 型 | 既定値 | 説明 |
|--------|------|---------|-------------|
| `jellyfin_server_url` | 文字列 | `""` | Jellyfin サーバーの URL です。zurg が変更を検出すると、ライブラリ更新の通知が有効になります。例: `http://localhost:8096` |
| `jellyfin_token` | 文字列 | `""` | 認証に使う Jellyfin の API トークンです。 |
| `emby_server_url` | 文字列 | `""` | Emby サーバーの URL です。zurg が変更を検出すると、ライブラリ更新の通知が有効になります。例: `http://localhost:8096` |
| `emby_token` | 文字列 | `""` | 認証に使う Emby の API トークンです。 |
| `dmm_api_key` | 文字列 | `""` | DMM の API キーです。[gatekeeper](https://gatekeeper.debridmediamanager.com/) でスポンサーになると表示されます。その後 DMM がファイルを配置し、ウォントリストを埋めます。 |
| `dmm_metadata_secret` | 文字列 | `""` | DMM の内部メタデータ API 用のシークレットです。設定されている場合、IMDb ID がない(または OpenSubtitles の未一致マーカーしかない)torrent は、起動時に DMM を通じてリリース名から特定されます。DMM は、タイトルが1つだけ完全に一致する場合にのみ回答します。特定できなかった torrent は ID が空のままになるので、Plex のマッチャーが後から埋めることができます。 |

```yaml
jellyfin_server_url: "http://localhost:8096"
jellyfin_token: ""
emby_server_url: "http://localhost:8096"
emby_token: ""
dmm_api_key: ""
```

## 3. 再生とファイル構成 {#3-playback--file-structure}

ファイルのうち、メディアサーバーに見せるものと、コンテンツのストリーミング方法を制御します。

### ストリーミングモード {#streaming-mode}

| オプション | 型 | 既定値 | 説明 |
|--------|------|---------|-------------|
| `disable_stream_proxy` | bool | `false` | true にすると、**マウント**からの読み込みは zurg 経由でプロキシされる代わりに、アカウント自身のダウンロード URL へのリダイレクトで応答します。zurg の CPU と帯域幅は減りますが、クライアントがアカウントのサーバーに直接接続できる必要があります。ローカルで配信されるバックエンドのリンクでは無視されます。Usenet ファイルには渡せる URL がないため、常にプロキシされます。**有効にする前に、下のプロバイダーのリスクをよく読んでください。** |
| `serve_strm_files` | bool | `false` | true にすると、zurg は WebDAV マウント内で実際の動画ファイルの代わりに `.strm` ファイルを提供します。Plex や Jellyfin などのメディアサーバーは `.strm` ファイルを読んでストリーミング URL を取得します。**重要:** 有効にすると、実際の動画ファイルは隠され、`.strm` のエントリに置き換えられます。 |
| `save_strm_files` | bool | `false` | true にすると、zurg は zurg バイナリと同じ場所にある `strm/` ディレクトリに `.strm` ファイルを書き出します。ディスクに永続的な STRM ファイルを残したい場合に便利です（例: メディアサーバーへ手動で取り込む場合）。ファイル内の URL には `base_url` が使われます。書き出されるのは、プレイヤーが開けるファイルだけです。認識された動画と音声、そして `addl_playable_extensions` で指定されたものです。そのため字幕、ポスター、NFO、PAR2 ボリュームはダンプに含まれず、古いビルドが書き出したものは、次回リリースを走査したときに削除されます。URL が合わなくなった `.strm`（`base_url` が変わった場合や古いビルドが書いた場合）は、次回起動時にその場で書き直されます。ダッシュボードで `base_url` を変更した場合は、すぐに書き直されます。すでに一致しているファイルは触られないので、スキャンのたびにメディアサーバーがフォルダ全体を読み直すことはありません。 |

```yaml
disable_stream_proxy: false
serve_strm_files: false
save_strm_files: false
```

**共有デブリッドでの再生には、マウント読み込みをプロキシのまま（既定）にしておいてください。** Real-Debrid は各ダウンローダーのパブリック IP を追跡します。1 つのアカウントを複数の IP で使うと、ダウンロードが成功していても共有に関する警告が出ます。サーバーのプローブや変換を含め、そのアカウントのすべての利用を 1 つのパブリック IP に保ってください。プレイヤーからのダウンロードだけではありません。TorBox のダウンロード URL には `?token=` に完全な API キーが含まれているため、リダイレクトすると、すべてのクライアントと共有ユーザーがアカウントにアクセスできてしまいます（削除も含む）。プレイヤーのログやブラウザの履歴にも残る可能性があります。信頼できないクライアントに TorBox のリンクを渡さないでください。

これらのリスクは、`disable_stream_proxy: true` によるマウントのリダイレクトと、`/strm/` のリダイレクトの両方に当てはまります。`disable_stream_proxy: false` のままにしても、`.strm` の再生がプロキシされたり、リモート共有に安全になったりするわけではありません。

#### `disable_stream_proxy` が効くもの・効かないもの {#what-disable_stream_proxy-does-and-does-not-reach}

この設定はマウントを制御します。`/strm/` エンドポイントには、どのバックエンドでも影響しません:

| 読み込み経路 | Real-Debrid / TorBox / AllDebrid | Usenet |
|---|---|---|
| マウント、プロキシオン（既定） | zurg 経由でプロキシ | プロキシ経由 |
| マウント、プロキシオフ | アカウントの URL へ `302` リダイレクト | プロキシ経由 — リダイレクト先の URL が存在しないため |
| `.strm` ファイル（どちらの設定でも） | アカウントの URL へ `307` リダイレクト | プロキシ経由 |

`.strm` は、zurg とセッションを持たないプレーヤーが開きます。そのためエンドポイントは、プレーヤーが自分で取得できる URL を渡すことしかできません。プロキシをオンにしても、そのトラフィックが zurg 経由に戻ることはありません。

知っておくと良い影響ですが、`.strm` 経由の読み込みには、帯域の集計、再生途中の別アカウントへのフェイルオーバー、リンク切れの検出がありません。マウント経由の読み込みには、これらがすべて適用されます。そのため、主に `.strm` で配信しているライブラリでは、どちらの設定でも `disable_stream_proxy` の効果はほとんど見られません。

以前のバージョンのこのページの記述とは異なり、`serve_strm_files` と `disable_stream_proxy` は互いに独立しています。`.strm` は、ストリーミングに関する判断が行われる前にテキストとして配信されるため、両方を同時に有効にできます。ただし `serve_strm_files` をオンにすると、すべての再生が `/strm/` エンドポイントに届きます。これはまさに上の表で `disable_stream_proxy` が何も変えない行です。

### ファイルのフィルタリングと検出 {#file-filtering--detection}

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `addl_playable_extensions` | list | `[]` | 内蔵の動画・音声形式に加えて、zurg が再生可能なメディアとして扱うファイル拡張子です。ドット、引用符、大文字小文字はダッシュボードで正規化されます。`m3u` や `cbz` などの拡張子を追加すると、そのファイルが表示され、選択できるようになります。 |
| `force_select_playable_files` | bool | `false` | true にすると、元は選択されていなくても、zurg がトレント内の再生可能なファイルをすべて自動で選択します。内蔵の動画拡張子と `addl_playable_extensions` の両方で動作します。未選択の動画ファイルにアクセスしたいトレントがあるときに便利です。 |
| `delete_torrent_if_extensions_found` | list | `[]` | トレント内のどれか 1 つでもこれらの拡張子を持つファイルがあると、トレント全体が RD から削除されます。`.rar` アーカイブ（RD で展開されたものを除く）や `.zipx` ファイルなど、不要なコンテンツを自動で削除するのに便利です。 |
| `stream_compressed_archives` | bool | `true` | 圧縮アーカイブに入ったファイルを、読み取りながらデコードして配信します。デコーダーはメモリ上で有限のウィンドウだけを保持します。`false` に設定すると、古いビルドと同じように圧縮アーカイブを拒否します。 |

内蔵の再生可能な形式は、`.avi`、`.flv`、`.m2ts`、`.m4v`、`.mkv`、`.mov`、`.mp4`、`.mpg`、`.mpeg`、`.ts`、`.webm`、`.wmv`、`.mp3`、`.flac`、`.m4a`、`.m4b` です。

```yaml
addl_playable_extensions:
  - m3u
  - cbz
force_select_playable_files: false
delete_torrent_if_extensions_found:
  - zipx
  - rar
```

### メタデータと命名 {#metadata--naming}

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `retain_folder_name_extension` | bool | `false` | **非推奨 — 今後削除されます。** true の場合、フォルダー名はアカウントの `Name` をそのまま使います（拡張子も含みます）。通常は `OriginalName` の末尾にある `.mp4` と `.mkv` を取り除きますが、それを行いません。これは `Name` に `OriginalName` が部分文字列として含まれている場合にのみ適用されます。それ以外の場合は、どのみち取り除きが行われます。`retain_rd_torrent_name` が先にチェックされ、こちらを完全に上書きします。 |
| `retain_rd_torrent_name` | bool | `false` | **非推奨 — 今後削除されます。** true の場合、フォルダー名はアカウントの `Name`（Real-Debrid の `filename`）になります。false の場合は `OriginalName`（`original_filename`）になり、これは torrent 自体が宣言した名前です。これは、ファイルを 1 つだけ選んだパックの場合に影響します。Real-Debrid は `filename` をそのファイル自身のベース名に縮めますが、`original_filename` はパック名のままです。つまり **`false` だとパック名になり、`true` だと個別ファイルの名前になります**。 |
| `ignore_renames` | bool | `false` | true の場合、zurg は torrent 内のリネーム用メタデータをすべて無視し、元のファイル名を使います。リネームされたファイルがメディアサーバーのマッチングで問題を起こしている場合は、これを有効にしてください。非推奨ではありません。 |

```yaml
retain_folder_name_extension: false   # deprecated
retain_rd_torrent_name: false         # deprecated
ignore_renames: false
```

両方の非推奨フラグは、アカウント側で書き換えられてしまう `Name` でライブラリを紐づけます。デフォルトは、torrent 自体が宣言した名前で紐づけます。こちらはアカウント側が手を加えない名前です。どちらかを設定すると、起動時に警告が出ます。Sonarr や Radarr の前段で動かしている場合（`sabnzbd:` または `qbittorrent:` ブロックがある場合）は、デフォルト値だけが正しい設定です。インポート後にアクセスキーが変わると、リリースを見失ってしまうからです。今回のリリースでは動作は変わりません。誰のフォルダー名も移動しません。完全な命名ルールは `docs/naming.txt` にまとめてあります。

### マウント書き込み {#mount-writes}

| オプション | 型 | 既定値 | 説明 |
|--------|------|---------|-------------|
| `dav_allow_rename` | bool | `true` | false にすると、マウント経由の WebDAV MOVE は 403 で拒否されます。既定でオンです。書き込み可能なマウントの主な用途はtorrentやファイルのリネームで、何も壊さないからです。 |

**マウント経由の WebDAV DELETE は常に実行されます。これを切り替えるキーはありません。** ライブラリからファイルを削除し、残りがなくなると、そのリリースを保持しているすべての debrid アカウントからも削除します。書き込みツールをマウントに向ける前に、そのコストを理解しておいてください。rclone は上書きされるファイルを DELETE の後に PUT として書き出すため、ファイルをその場で書き換えるもの（`.nfo` ライターやトリックプレイの処理、\*arr のリネーム、うっかりの `touch`）は、コンテンツを置き換えるのではなく削除してしまいます。しかもマウントは rclone 自身の認証情報を使うので、認証では両者を区別できません。その流れが静かに完了してしまうのを防げるのは、PUT 側だけが拒否されることです。DELETE が zurg に届くこと自体を止めるのは `mount_read_only: true` です。

拒否された書き込みには **403** が返り、それを許可する設定キーがログに記録されます。そのため書き込みが動かなくなったクライアントは、`logs/zurg.log` にその理由が出ています。

知っておきたい副作用が一つあります。プログラムが FUSE マウント経由で書き込むと、rclone の VFS キャッシュは変更済みのコピーを保持し、拒否されたアップロードを間隔を空けて再試行します。そしてそのキャッシュエントリが破棄されるまで、マウントにはローカルで変更されたファイルが表示されます。その間、サーバー側のファイルは最後まで変わりません。`mount_read_only: true` なら、rclone が何もキャッシュする前にカーネルで書き込みを失敗させるので、この問題は完全に避けられます。

```yaml
dav_allow_rename: true
```

関連: `mount_read_only`。こちらは書き込みが zurg に届く前にカーネルで拒否させる設定です。

### ディレクトリ一覧のキャッシュ {#directory-listing-cache}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `disable_listing_cache` | bool | `false` | true のときは、ディレクトリの一覧を毎回のリクエストで最初から描画し直します。オフのままにしておいてください。オンにしていると、`__all__` に対する `PROPFIND Depth:1` のたびにライブラリ全体が描画し直されます。計測値は、6,120 件のリリースで 59 ms、2,636 件の Usenet リリースで 121 ms、`__magic__/__all__` で 148 ms でした。さらに、メディアサーバーのスキャンは同じ一覧を何度も要求します。 |

```yaml
disable_listing_cache: false
```

キャッシュは、トップレベルの各ディレクトリについて、マウントの種類（`/dav`、`/infuse`、`/http`）ごとに最後の描画結果を保持し、ライブラリに変更が入るまでそれを返します。何を変更とみなすかは推測ではありません。rclone が同じ一覧について自前のキャッシュを忘れるきっかけとなるイベントがそのまま使われます。つまり、リリースの追加・削除・名前変更・再分類、ファイルの破損や復旧などです。rclone はこれらの一覧を **12 時間** 保持します。そのため、ここから返される一覧が、マウントがすでに提供している一覧より古くなることはありません。さらに念のため、60 秒の厳しい上限も設けています。

`__magic__/__all__` はミラーで、名前空間の中でキャッシュする価値があるのはこの一覧だけです。その上のルートにはミラーと数行しかないためです。この一覧は、保存済みのレイアウトも追跡します。そのため、\*arr からのインポートがあっても無効になるのはこの一覧だけで、他のディレクトリの描画結果はそのまま残ります。`__downloads__` と `Depth: 0` のリクエストは、一切キャッシュされません。

レスポンスには `X-Zurg-Listing: hit` または `miss` ヘッダーが付くので、実際に動いている環境でも計測できます:

```bash
curl -s -o /dev/null -D - -X PROPFIND -H 'Depth: 1' http://localhost:9999/dav/__all__/ | grep -i x-zurg-listing
```

### `__magic__`、整理できるディレクトリ {#__magic__-a-directory-you-can-organise}

従来のディレクトリはすべて保存済みフィルターで、リリースは条件に一致するため `movies` に入っています。そのためライブラリには、何かを*置く*場所がありません。`__magic__` だけが例外です。`__magic__/__all__` は `__all__` の完全なコピーで、その隣のルートは自由に使えます。どのリリースも、ミラーから名前空間内の好きな場所へ移動できます。移動は `data/magic.journal` の行を書き換え、その内容が `data/magic.json` にまとめられます。バイトは動かず、torrent の名前も変わりません。行はリリースのコンテンツハッシュをキーにしているため、リリースを作り直す修復を行っても、置いた場所は失われません。これにより、Radarr と Sonarr はコピーではなくリネームでインポートできます。

修復後に何が残るか、各拒否が何を意味するかを含む詳しい説明は [docs/magic.md](../guides/magic.md) にあります。

| オプション | 型 | 既定値 | 説明 |
|--------|------|---------|-------------|
| `magic.enabled` | bool | `false` | `__magic__` を提供するかどうかを決めます。既定ではオフです。これは書き込み可能なツリーで、間違ったルートフォルダーを指定した \*arr がライブラリを再編成してしまうおそれがあるためです。何も移動していない場合、その中の `__all__` はライブラリのものとまったく同じに見え、ルートには他に何も入りません。 |
| `magic.allow_delete` | bool | `false` | true にすると、`__magic__` 配下の**ファイル**に対する DELETE が、マウント本体での DELETE と同様にコンテンツも削除します。既定ではオフで、削除は隠すだけです。エントリは `__magic__` から消えますが、`__all__` とすべてのフィルターディレクトリには残ります。この設定が何であっても、リリースフォルダーとディレクトリはコンテンツを削除しません。Sonarr はインポートのたびにジョブフォルダーを削除するためです。`__magic__` 配下のどれも使わなくなった動画やアーカイブ内のエントリを削除すると、そのリリース全体も削除されます。 |
| `magic.sidecar_max_mb` | int | `32` | クライアントが `__magic__` に `PUT` できる単一ファイルの最大サイズです。これを超える書き込みは **413** で拒否されます。 |
| `magic.sidecar_budget_mb` | int | `2048` | サイドカーツリー全体が大きくなれる最大サイズです。これを超える書き込みは **507 Insufficient Storage** で拒否されます。413 では分からない情報を伝えます。何かを削除すると、同じリクエストが成功するようになります。合計は起動時にツリーを走査して測るため、すでに一杯のツリーは再起動しても容量が戻りません。拒否する前にも毎回測り直します。このツリーは zurg 自身のマウントが書き込む `data/local` ディレクトリと同じで、zurg の知らないところでそこからファイルが消えた場合、そのファイルに容量を使わせ続けてはいけないからです。0 以下の値は既定値になります。上限なしを指定する方法はありません。 |

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

`dav_allow_rename` はここでは適用されず、マウントのゲートで制御されていない削除経路も適用されません。これらは debrid アカウントが保持するものをリネームしたり破棄したりする経路を対象としています。`__magic__` への書き込みはどのアカウントにも届きません。`mount_read_only: true` は、それでもすべてを上書きします。カーネルレベルで効きます。

知っておくと良いことが2つあります。フィルターディレクトリは設計上そのままです。つまり、`__magic__` 内で移動したリリースも、元の名前で `recent` や `movies` に残ります。メディアサーバーは `__magic__` **か**フィルターのどちらかを指定してください。両方は指定しないでください。また、マウントに新しく書き込まれたもの（`.nfo`、字幕、ポスター）は zurg 自身の `data/local` に入り、一覧にマージされます。そのため、リリースの隣に置いたサイドカーがそのまま機能します。

#### サイドカーファイルと 2 つの上限の役割 {#sidecar-files-and-what-the-two-caps-are-for}

埋め込みマウントは、最初の上流が `data/local` であるユニオンです。そのため、プログラムがマウント上に新しいファイルを作成すると、rclone はそこに書き込み、zurg には一度も問い合わせません。このツリーには上限がありません。ただし [`union_writable: server`](#rclone-settings) でユニオンの順序を入れ替えると話は別です。その場合、作成リクエストは `PUT` として zurg に届き、`__magic__` の外では拒否され、内側では2つの上限に従います。

デフォルトの順序では、2つの上限は別の種類のクライアント向けです。ユニオンを経由せず `/dav` を直接マウントするクライアントです。そうしたクライアントは zurg に `PUT` を送り、zurg はボディを `data/local/__magic__/<path>` に書き込みます。これはユニオンが提供しているまさにそのディレクトリなので、2つのビューは2つではなく1つのディレクトリとして表示されます。上限がなければ、WebDAV 経由で到達できる汎用ファイルストアになってしまいます。それを防ぐのが `sidecar_max_mb` と `sidecar_budget_mb` です。

`__magic__` の性質から、次の2つのルールが導かれます。どちらも、クライアントが目にする拒否です。

- **ミラーはライブラリ自身のものです。** `__magic__/__all__` と、その直下にあるリリースフォルダーは計算によって生成されます。そのため、いずれかを対象にした `MOVE`、`MKCOL`、`DELETE` は **403** になります。そこに行を作ると、すでに住所を持つリリースに2つ目の住所ができてしまうからです。より深いリリース自身のフォルダーでは、書き込みは他の場所と同じように普通に行えます。\*arr が、インポートしたファイルの隣に `.nfo` を置くのがまさにそこです。
- **ライブラリが応答するものの上には書き込めません。** リリースフォルダー、その中のエントリー、そして移動によって何かが配置されたパスは、すべてライブラリから描画されます。そのため、実際のファイルを `PUT` または `MOVE` で上に置こうとすると **403** になります。リリースに存在しないリリースフォルダー内の名前も含まれます。フォルダーの一覧はそのリリースのものなので、そこに置かれたファイルはどこにも表示されないからです。
- **配置で実ファイルが壊れることはありません。** ライブラリが保持しているものを、サイドカーがすでに占有しているパスへ移動しようとすると、上書きせずに拒否されます。`Overwrite: T` を指定していてもです。逆方向も同じです。実ファイルを含むディレクトリを、ライブラリが応答するパスへ名前変更することはできません。そうすると、そのファイルはリリースだけを一覧するフォルダーの中に置かれてしまうからです。

`DELETE` でサイドカーを対象にすると、実際に削除されます。`__magic__` の中で削除がトゥームストーンにならないのは、この場所だけです。トゥームストーンは、ライブラリが別の場所に保持しているエントリーを隠すだけです。一方、サイドカーのバイト列は `data/local` にしか存在しないからです。

#### `__magic__` ページ {#the-__magic__-page}

ダッシュボードには、namespace 専用のページがあります。パスは `/magic/` で、`__magic__` が設定されているか配信されている場合は、ダッシュボードのクイックリンクからたどれます。テーブルの中身が見えるのはこのページで、2つの状態にはこのページからしか到達できません。

このページには、保存されている行数が表示されます。placement、tombstone、directory はそれぞれ別々に数えられます。あわせて、journal と snapshot がディスク上で使っている容量、`sidecar_budget_mb` のうち sidecar ツリーが使っている量、`data/local` 全体のサイズも出ます。特に気にしてほしいのは最後の数字です。コピーではなく移動しないクライアントだと、中身がそこに溜まっていきます。`data/local` がギガバイト単位で増えていたら、どこかでインポートが逆向きに行われています。行はリリースごとにまとめられています。テーブルが非常に大きい場合はページ上で切り詰められ、その分量が表示されます。上の数字は常にテーブル全体の数です。

保存済み行の一覧には最初の1000行だけが表示されます。\*arr はインポートのたびに tombstone を残すため、整理されたライブラリでは大半の行がその先にあります。保存済み行とダングリングのページには検索ボックスがあり、リリース名、マウント上のパス、ハッシュのいずれかで1つのリリースを探せます。そのリリースについて保存されている行が、ボタンと一緒にすべて表示されます。

`data/magic.json` はその代わりにはなりません。zurg は停止するときにメモリの内容からこのファイルを書き出すため、zurg の実行中に手で行を削除しても、元に戻ってしまいます。

ボタンは3つあり、どれも同じ1つの操作、つまり行が存在しなくなる、を行います。

- **Reset** を押すと placement が消え、ファイルやフォルダーがライブラリの配置先に戻ります。
- **Unhide** を押すと tombstone が消え、そのエントリーが再び `__magic__` に表示されます。隠すために何かを破棄したわけではありません。`__all__` にあるのに、削除して追加し直しても `__magic__/__all__` に現れないリリースには、release tombstone があります。行はハッシュをキーにしていて、再追加してもハッシュは変わらないためです。そのリリースを検索して、その行を Unhide してください。
- **Delete** を押すと **dangling** な行が消えます。dangling な行とは、リリースそのもの、またはその中のファイルが、ライブラリにもう存在しない行のことです。そのような行はどこにも解決されないため、マウント経由では一覧表示も移動も削除もできません。それでも消さずに残しているのは、リリースを復元する修復が、置き場所も含めて元どおりにしてくれるからです。このページができるまでは、これを片付ける方法がありませんでした。**Clear all dangling rows** を使うと、すべてを一度に片付けられます。

sidecar も一覧に出ます。**nothing accounts for any more** と表示される sidecar は、ほかとは分けて表示され、件数も数えられます。これは、sidecar にとっての dangling な行に当たるものです。リリースがライブラリから外れた後に置かれた `.nfo` やポスター、あるいは placement が忘れられたフォルダーの中にあるファイルがこれにあたります。`__magic__` のパスは、実ファイルがあればそれが最後に解決されるので、今も配信されています。上のどの要素もその名前を主張していなくなっただけで、置かれた理由がなくなったという状態です。zurg が sidecar を自動で消すことはありません。削除されたリリースの横にあるファイルも、あなたのファイルのままです。修復でリリースが戻ってくれば、そのフォルダーも再び管理下に入ります。マウント経由で（zurg ではなく）自分で sidecar 用に作ったディレクトリも、行が残らないため、ここでは同じように表示されます。

ページから sidecar を **Delete** すると、マウント経由の `DELETE` と同じように、ファイルが実際に削除されます。どのボタンも、関係するパスについてマウントがキャッシュしている内容を更新します。マウントは、ポーリングをオフにしたままディレクトリの一覧を12時間保持するからです。

SABnzbd エンドポイントが有効になっていると、このページには、それに渡されたジョブも表示されます。各ジョブについて、クライアントが知っている ID、カテゴリー、リリースがライブラリにもう届いたかどうか、届いたらインポート元となるフォルダーが分かります。Sonarr と Radarr は自分のジョブを自分で削除します。Failed や Stuck のジョブで、どちらも削除しないものは、このページからクリアできます。これは、zurg がもうそれらのダウンロードクライアントではなくなった場合に起こります。詳しくは [sabnzbd.md](../guides/sonarr-radarr.md) を参照してください。

`magic:` ブロックと `sabnzbd:` ブロックは、どちらも[設定ページ](#sabnzbd-the-download-client-sonarr-and-radarr-see)で全体を編集できます。どちらにも **Restart Required** と表示されていて、これは文字どおりの意味です。`__magic__` を配信するルートと SABnzbd エンドポイントは、起動時に一度だけこれらの値から登録されます。どちらかを有効にすると `config.yml` に書き込まれますが、その時点で応答している実行には何も影響しません。`__magic__` のページも、空の namespace を表示する代わりに、そのことを明記します。

### `sabnzbd`（Sonarr と Radarr が見るダウンロードクライアント） {#sabnzbd-the-download-client-sonarr-and-radarr-see}

zurg は、Sonarr と Radarr から見ると SABnzbd のように振る舞えます。両者が NZB を渡すと、zurg はそれを Usenet バックエンド用の `nzbs/` に書き込みます。リリースがライブラリに入ると、ジョブは **Completed** と報告され、インポート元として `__magic__/__all__` 配下にジョブフォルダーが作られます。インポートのためにダウンロードは一切発生しません。\*arr がマウント内でファイルの名前を変更するだけで、これは `__magic__` テーブルの1行として扱われます。

使えるようにするには両方が必要です。NZB を受け取るための `nzb` プロバイダー（または `torbox_nzb`）と、インポート元となる `magic.enabled`。どちらも、要求されるまでは無効のままです。\*arr 側で何を設定するかを含む完全なセットアップは、[docs/sabnzbd.md](../guides/sonarr-radarr.md) にあります。

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `sabnzbd.enabled` | bool | `false` | `/api` と `/sabnzbd/api` でエンドポイントを登録します。無効の間は、どちらのルートも存在しません。 |
| `sabnzbd.api_key` | string | 自動生成 | エンドポイントへの唯一の認証手段です。Sonarr と Radarr は basic 認証を送らないため、これらのルートは basic 認証の外に置かれ、代わりに API キーが役割を担います。ブロックを有効にした状態で空のままにすると、zurg が一つ生成し、`data/sabnzbd-apikey` に保存して再起動後も残るようにし、起動時に一度だけログへ出力します。 |
| `sabnzbd.categories` | list | `[tv, movies]` | クライアントに報告されるカテゴリーです。どれもすべて同じディレクトリに解決されます。このオプションは、クライアントが見つけられないカテゴリーについて警告するのを防ぐためだけにあります。\*arr で設定したものを何でも追加してください。`*` も常に報告されます。 |
| `sabnzbd.history_limit` | int | `60` | Sonarr と Radarr が読み取る履歴エントリーの数です。この数を超えた完了済みジョブは、空きスロットができるまでキューに保持されます。空きができるのは、クライアントがひとつ消去したとき、またはジョブが待機している間に一件が10分間消去されないままになったときです。クライアントの `DownloadClientHistoryLimit` を上げている場合は、それに合わせてください。`0` にすると、既定値の60が使われます。 |
| `sabnzbd.complete_dir` | string | `<mount_path>/__magic__/__all__` | クライアントに報告される完了ディレクトリーです。**\*arr** から見えるパスでなければなりません。\*arr がライブラリを別の場所にマウントするコンテナーで動いている場合、それは zurg 自身のパスとは異なります。また、ルートフォルダーと同じボリュームにある必要があります。そうでないと、インポートのたびにコピーが発生します。詳しくは [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) を参照してください。 |

```yaml
sabnzbd:
  enabled: true
  api_key: ""
  categories: [tv, movies]
  complete_dir: ""
```

API キーが認証のすべてです。そのため、エンドポイントは zurg の他のポートと同じように扱ってください。信頼できるネットワーク上で使うか、それを守る何かの背後に置いてください。Basic 認証は使えません。クライアントはそれを送らず、401 はユーザーには認証失敗ではなく「接続できません」と表示されるためです。

### `qbittorrent`（Sonarr と Radarr が見る torrent ダウンロードクライアント） {#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see}

zurgは、Sonarr や Radarr から見ると qBittorrent のように振る舞えます。両者が magnet や `.torrent` を渡すと、zurgはその info hash をデブリッドのアカウントに追加します。リリースがライブラリに入ると、torrent は **finished** と報告され、インポート元として `__magic__/__all__` 配下のフォルダが用意されます。インポートのためにダウンロードは一切発生しません。\*arr はマウント内のファイル名を変更しますが、それは `__magic__` テーブルの1行として記録されます。

役立てるには2つの条件があります。torrent を追加できるアカウントがあって magnet を読み取れること、そして `magic.enabled` で \*arr がインポートできる場所を用意することです。これは要求するまでオフになっています。\*arr 側に何を設定すればよいかを含む完全なセットアップは [docs/qbittorrent.md](../guides/sonarr-radarr-torrents.md) を参照してください。

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `qbittorrent.enabled` | bool | `false` | `/api/v2` と `/qbittorrent/api/v2` でエンドポイントを登録します。オフの間は、どちらのルートも存在しません。 |
| `qbittorrent.api_key` | string | 自動生成 | エンドポイントを守る唯一の制限です。クライアントは **API Key** 欄が設定されている場合はそれをベアラートークンとして送り、設定されていない場合は `auth/login` のパスワードとして受け入れます。ブロックを有効にした状態で空のままにすると、zurgが自動生成し、再起動後も残るように `data/qbittorrent-apikey` に保存し、起動時に一度だけログに出力します。 |
| `qbittorrent.categories` | list | `[tv-sonarr, radarr]` | クライアントに報告するカテゴリです。\*arr に最初から含まれている2つです。どちらも同じディレクトリに解決されるため、クライアントが見つけられないカテゴリについて警告するのを防ぐためだけに存在します。 |
| `qbittorrent.save_path` | string | `<mount_path>/__magic__/__all__` | クライアントに報告する保存パスで、各インポート元フォルダの親にあたります。**\*arr** から見えるパスでなければなりません。\*arr がライブラリを別の場所にマウントするコンテナで動いている場合は、zurgのパスとは異なります。ルートフォルダと同じボリュームに置く必要があります。そうでないと、インポートのたびにコピーが発生します。詳しくは [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) を参照してください。両方のエンドポイントを使う場合は、`sabnzbd.complete_dir` も同じ値に設定してください。 |
| `qbittorrent.download_timeout_mins` | int | `15` | 変化がない（ステージの変化も進捗の上昇もない）状態のまま grab が続く時間です。その時間を過ぎると、そのアカウントは諦められ、次に torrent を受け付けるアカウントが試されます。`0` はキャッシュのみモードを意味します。grab は、すでにコンテンツを保持しているアカウントにしか受け付けられず、そうでなければ追加の時点で拒否されます。Sonarr と Radarr が反応するのはこの拒否だけです。負の数は決して諦めません。詳しくは [タイムアウトとキャッシュのみモード](../guides/sonarr-radarr-torrents.md#timeouts-and-cached-only-mode) を参照してください。 |

```yaml
qbittorrent:
  enabled: true
  api_key: ""
  categories: [tv-sonarr, radarr]
  save_path: ""
  download_timeout_mins: 15
```

15分は測定値であり、選んだ値ではありません。AllDebrid は、健全なジョブでも1バイトも進まないうちに、すべてのカウンターがゼロのまま自前のキューに入れてしまいます。2回の試行のうち2回とも、580秒と622秒そこに留まりました。計測結果は [docs/torrent-lifecycle.md](../internals/torrent-lifecycle.md) にあります。

grab をどのアカウントに送るかは [`add_torrents`](#accounts) と `providers:` リストの順序で決まります。タイムアウトしたか、アカウントが諦めた grab は、次のアカウントを試す前にそのアカウントから削除されます。zurg自身がその grab のために追加し、かつ完了しなかったインスタンスだけが候補になります。このエンドポイントが応答する他のどの操作も、デブリッドのアカウントから何も削除しません。

API キーが認証のすべてです。このエンドポイントは、zurgのポート全体と同じように扱ってください。信頼できるネットワーク上に置くか、それを守る何かの背後に置いてください。Basic 認証は使えません。クライアントはそもそも認証情報を送らず、401 を受け取ると致命的な認証失敗とみなし、再試行しません。

### `stremio` アドオン {#the-stremio-addon}

zurg は、自分の Newznab インデクサーを検索し、Usenet バックエンド経由で再生する Stremio アドオンにもなります。NZB アカウント（`nzb` または [`torbox_nzb`](../providers/torbox-nzb.md)）と、少なくとも 1 つのインデクサーが必要です。`torbox_nzb` を使う場合、TorBox がすでに持っているリリースは、他の NZB 投稿が待機していなければアドオンの待ち時間内に再生が始まります。キャッシュされていないリリースは、プレーヤーの待ち時間より長くかかる TorBox 側の処理が先に終わる必要があります。この機能はオンにするまで無効です。セットアップと再生時の動作については [stremio.md](../guides/stremio.md) を参照してください。

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stremio.enabled` | bool | `false` | アドオンのルートを `/stremio/` 以下に登録します。オフの間は 404 を返します。 |
| `stremio.token` | string | 自動生成 | アドオンのすべてのルートを保護するパスセグメントです。認可はこれだけです。空のままにすると zurg が生成し、`data/stremio-token` に保存します。 |
| `stremio.indexers` | list | `[]` | 検索する Newznab エンドポイントです。各項目は `name`、`url`、`api_key` と、任意の `api_path` を指定します。 |
| `stremio.max_results` | int | `10` | ランク付け後、解像度ごとに残すリリース数です。上限は解像度ごとです。各ティアは最大サイズから最小サイズまでをまんべんなく残します。`0` でデフォルトになります。 |
| `stremio.search_limit` | int | `100` | 検索ごとに各インデクサーへ要求するリリース数です。他のすべての上限はここで要求されたものの中から選ぶので、回答全体の上限になります。`0` でデフォルトになります。 |
| `stremio.max_size_gb` | int | `0` | ランク付けの前に、これより大きいリリースを除外します。リメックスを扱えないプレーヤー向けです。`0`（デフォルト）は何も除外しません。サイズが記載されていないリリースは残ります。 |
| `stremio.cache_hours` | int | `24` | 5 件以上の完全な回答を `data/stremio-cache` から配信する期間です。その後インデクサーに再度問い合わせます。少ない回答はより短く保持されます。空の回答は保存しません。`0` でデフォルトになります。 |

### メディア解析 {#media-analysis}

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `auto_analyze_new_torrents` | bool | `false` | `true`の場合、zurgは追加された新しいtorrentすべてに対して自動的にffprobeを実行し、メディアのメタデータ(解像度、コーデック、再生時間、音声・字幕トラック)を取得します。このメタデータは、`zurg_4k`、`zurg_aud_eng`などのタグベースのディレクトリフィルターや再生時間の区分で使われます。タグベースのフィルターを使っていない場合や、新規追加時のCPU使用率を下げたい場合は、無効にしてください。 |
| `ffprobe_binary` | string | `"ffprobe"` | ffprobe実行ファイルへのパスです。ffprobeがシステムのPATHにない場合のみ必要です。メディア解析に使われます。 |

```yaml
auto_analyze_new_torrents: true
ffprobe_binary: "ffprobe"
```

## 4. ヘルスチェックと修復（自動化） {#4-health--repairs-automation}

「設定したら放っておける」セクションです。zurg が壊れた torrent を自動で検出して直すことで、ライブラリを健全に保つための設定です。

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable_repair` | bool | `true` | 自動の torrent 修復を有効にします。未設定の場合は有効扱いです。torrent が利用できなくなると（例: RD のキャッシュから削除された場合）、zurg は代わりの torrent を探して追加しようとします。AllDebrid では、「ピアがいない」やトラッカーのエラーなど、もう一度試せば直る理由で失敗した magnet も、失敗したままにせず再開します。**重要:** 競合を避けるため、修復を有効にするのは zurg のインスタンスを 1 つだけにしてください。この設定と `delete_error_torrents` の両方がオフの場合、zurg は失敗した torrent をアカウント上にそのまま残し、ログに記録するだけです。 |
| `repair_every_mins` | int | `60` | zurg が修復が必要な壊れた torrent をスキャンする頻度（分単位）。値を小さくすると問題をより早く見つけられますが、API の使用量が増えます。 |
| `repair_timeout_mins` | int | `30` | 修復処理の完了を待つ最大時間（分単位）。修復がこの時間を超えると、torrent は壊れた扱いになり、次の修復サイクルまでスキップされます。 |
| `stalled_download_mins` | int | `10` | ダウンロード中の torrent が停滞とみなされるまでの最短時間（分単位）。実際のしきい値は `max(GB_downloaded, stalled_download_mins)` なので、大きなダウンロードには自動的に長めの時間が与えられます。シードが少ない torrent や公開トラッカーなど、完了までに時間がかかる遅い torrent では、この値を増やしてください。 |
| `restrict_repair_to_cached` | bool | `false` | true の場合、zurg は修復に Real-Debrid にすでにキャッシュされている torrent だけを使います。ダウンロードを待つ必要がないので修復は速くなりますが、代わりのキャッシュ済み torrent がない場合は失敗することがあります。false の場合、zurg はダウンロードに時間のかかる未キャッシュの torrent も追加できます。 |
| `only_full_torrent_repair` | bool | `false` | true の場合、修復は元のファイル選択のまま torrent 全体を再投入するか、諦めるかのどちらかになります。その最初の手順が失敗すると、本来続くはずのアーカイブ単位やファイル単位の戦略は飛ばされ、torrent は即座に壊れた扱いになります。 |
| `check_for_changes_every_secs` | int | `15` | zurg がライブラリの変化（新しい torrent、削除された torrent、ステータス変更）を検出するために Real-Debrid に問い合わせる頻度（秒単位）。値を小さくするとメディアサーバーへの反映が速くなりますが、API 呼び出しが増えます。 |
| `library_resync_every_mins` | int | `10` | 軽量なプローブの代わりに、全件リストから変化チェックを作り直す頻度。プローブが見逃すずれを拾うセーフティネットです。zurg がポーリングする頻度ではありません。Real-Debrid は独自の方法で処理し、この設定は無視します。 |
| `library_detail` | string | `resident` | `resident` はファイルの詳細情報をメモリに保持します。`lazy` は使われていない詳細情報を解放します。`auto` は持続的なメモリ圧迫がある場合にのみ、使われていない詳細情報を解放します。すべてのプロバイダーがこのインスタンス全体のポリシーを共有します。再起動が必要です。詳しくは [ライブラリの詳細](#library-detail) を参照してください。 |
| `library_detail_idle_secs` | int | `300` | `lazy` または `auto` がテーブルを解放してよくなるまでの、詳細の読み取りがない最短時間。スイープは 30 秒ごとに実行されます。`resident` では無視されます。ゼロまたは無効な値の場合は 300 が使われます。再起動が必要です。 |
| `downloads_every_mins` | int | `720` | zurg が RD のダウンロード（制限解除されたリンクやファイルロッカーのリンク）を再取得してマウントする頻度（分単位）。これらは RD からの torrent 以外のダウンロードです。 |
| `delete_error_torrents` | bool | `false` | true の場合、エラー状態の torrent（ダウンロードできない dead torrent など）を RD から自動的に削除します。RD ライブラリをきれいに保てますが、torrent は完全に削除されてしまいます。AllDebrid では、もう一度試せば直る失敗した magnet は削除されず再開されます。修復がオフでも同じです。再開しても直らなかった場合にのみ削除されます。 |
| `on_library_update` | string | `""` | zurg がライブラリの変化を検出するたびに実行されるシェルコマンド。変更されたディレクトリのパスが引数として渡されます。特定のフォルダーに対して Plex/Jellyfin のライブラリスキャンを実行し、より速く反映させるためによく使われます。 |

```yaml
enable_repair: true
repair_every_mins: 60
repair_timeout_mins: 30
stalled_download_mins: 10
restrict_repair_to_cached: false
only_full_torrent_repair: false
check_for_changes_every_secs: 15
library_detail: resident
library_detail_idle_secs: 300
downloads_every_mins: 720
delete_error_torrents: false
on_library_update: |
  for arg in "$@"
  do
      echo "detected update on: $arg"
  done
```

### アカウントをまたいだ修復 {#repairing-across-accounts}

他のすべての修復戦略は、リリースを元のアカウントに再度追加します。そのアカウントがまだコンテンツを提供できる限り、これは正しいやり方です。ただ、1つのケースだけは違います。

各サービスは独立したキャッシュを持っています。Real-Debrid が削除したリリースや、ファイル名だけで受け付けないリリースでも、同じ info hash のまま AllDebrid のキャッシュに今も残っていることがあります。リリース自体に問題はありません。問題があるのはアカウントの方です。

そこで、あるリリースをそれを持っているすべてのアカウントが諦めた場合、zurg は設定された「持っていない」アカウントに順番にそのリリースを提示します。順番は `providers` ブロックに書かれた並び順です。最初に既にそのリリースを持っているアカウントがそれを受け取り、zurg はそのアカウントを一覧に追加します。その後、リリースは複数アカウントのリリースと同じように扱われます。つまり、独自のファイル ID と独自のリンクを持ち、2つのアカウント間で読み取りのフェイルオーバーが行われます。修復可能なコピーが存在するようになると、そのエントリーの判定は自動的に消えます。

この機能に設定項目はありません。2つ目のアカウントを設定すること自体が決定になります。zurg はすでにそのアカウントを一覧に表示し、そこから配信し、読み取りのフェイルオーバーも行っています。最初のアカウントが作れないリリースについて問い合わせるのも、同じ仕組みの延長です。他の修復と同じく `enable_repair` に従います。

リリースの修復ボタンでも同じことが行われます。順番も正しく、まず、リリースを持っているアカウントを従来どおり再試行します。その試行が失敗したときだけ、リリースを他のアカウントに提示します。これは、修復の自動巡回を完全にオフにしていても動作する唯一の経路です。

提示の仕方そのものが、無限に追加を繰り返す「追加ループ」を防ぎます。スイッチではなく、この形が防いでいます。

- **アカウントには、すでに持っているコンテンツだけを渡します。** 提示は追加ですが、15秒以内にアカウントが完了しない場合は取り消され、削除されます。スウォームからリリースを取得する必要があるアカウントは、見つけたときの状態のまま残され、転送の許容量も使いません。これは修復であって、再ダウンロードではありません。`restrict_repair_to_cached` はこの動作を制御せず、ここでは一切読み取られません。このキーはアカウントが自分のコピーを修復する場合の設定であり、この経路は設定の値にかかわらずキャッシュ済みのみを対象とします。
- **どのアカウントも配信できないリリースだけが対象です。** 動作しているリリースは決してコピーされません。修復がまだ諦めていないリリースも対象外です。
- **「ない」と答えたアカウントには、だんだん問い合わせる頻度を減らします。** ミス後の待ち時間は1日から始まり、ミスするたびに倍になり、最大約2週間までになります。今週キャッシュ切れになっただけのリリースは数日以内に再び見つかります。完全に消えてしまったリリースは、2週間ごとの問い合わせに落ち着きます。この減衰がなければ、always-on 運用ではすべてのアカウントで、死んだリリースごとに毎日追加が発生し続けてしまいます。
- **1回の巡回で最大10件です。** そのため、2つ目のアカウントを追加した最初の巡回では、一度に大量に処理せず、バックログを数時間かけて消化します。

これは、コンテンツが期限切れになるアカウントに対して、頼まれていないのに zurg が追加を行う唯一の場所です。修復では、そうしたアカウントにタイマーでリリースを再追加することはしません。サービスが意図的に削除したコンテンツを再取得することは、そのサービスが不正利用と見なすパターンだからです。ただし、キャッシュ済みの提示はこれに当たりません。何も取得せず、転送の許容量も使わず、主張されているコンテンツはすでに、誰か別の人がサービスのキャッシュに入れたものだからです。

### ライブラリの詳細 {#library-detail}

**`library_detail: resident` は引き続きデフォルトです。** モードとアイドル時間は、ダッシュボードの設定ページか `config.yml` で選べます。どちらの設定も zurg を再起動すると反映されます。保存しただけでは、動作中のライブラリが一部だけ切り替わることはありません。このポリシーは、インスタンス内のすべてのプロバイダーに適用されます。

| モード | 動作 | トレードオフ |
|---|---|---|
| `resident` | すべてのリリースのファイル詳細をメモリに保持します。 | アクセスが安定していて、詳細の再読み込みも発生しません。ただし、保持するメモリ量が最も多くなります。 |
| `lazy` | `library_detail_idle_secs` の間使われなかったリリースの詳細を解放します。 | メモリに余裕があっても、アイドル時のメモリ使用量を減らせます。ただし、使われていない詳細にアクセスすると再読み込みが必要になります。 |
| `auto` | メモリに余裕があるあいだは詳細を保持し、継続的な負荷がかかると、アイドル状態が最も長いテーブルから解放します。 | 実行時の状況に応じて動きます。一方で、負荷の監視が加わり、再読み込みの待ち時間は予測しにくくなります。 |

名前、サイズ、リネーム、表示状態は、どのモードでもリスト表示に引き続き使えます。ファイルを開いたり修復したりすると、解放された詳細はその場で再構築されます。`auto` は負荷が下がってもライブラリを先回りして再読み込みすることはありません。詳細は使われるにつれて戻り、負荷とアイドル時間の条件がそろうまで常駐したままになります。

#### 自動の負荷検出 {#automatic-pressure-detection}

`auto` は30秒ごとにサンプリングします。測定された予算の **90%** 以上の値が、30秒以上の間隔を空けて2回続けて読み取られると、退避を開始します。退避は1回のスイープにつき最大 **128個のアイドルテーブル** ずつ行われます。使用量が **80%** 以下になるまで退避を続け、その後、新しいエピソードを検討する前に少なくとも1分間停止します。一時的なスパイクでは退避は始まりません。設定されたアイドル時間の窓は常に適用されます。

判断には、利用可能な測定値のうち最も厳しいものが使われます:

- **ホストメモリ:** 合計から利用可能メモリを引いた値です。OS が回収可能と見積もるキャッシュも含みます。ファイルシステムキャッシュがいっぱいになっただけでは、RAM 不足ではありません。
- **Linux コンテナとサービス制限:** cgroup v2 の `memory.max` と `memory.high`、または v1 の `memory.limit_in_bytes` を使い、見えている各祖先の使用量も含めます。使われていないファイルキャッシュは差し引いて扱います。コンテナの制限はランタイム中に再読み込みされます。プライベートな cgroup namespace では、見えているルートより上の制限が隠れることがあります。
- **明示的なランタイム予算:** 正の値の `memory_limit_mb`（MiB 単位）を、Go が管理するメモリと比較します。`GOMEMLIMIT` が設定されている場合はそちらが優先されます。`GOMEMLIMIT=off` にすると、この信号だけが無効になります。ホストとコンテナの圧迫は引き続き適用されます。Usenet キャッシュから導かれる自動の Go 上限は無視されます。これはライブヒープとともに上がるもので、利用可能な RAM を測るものではないためです。

`auto` を有効にするために追加の予算は必要ありません:

```yaml
library_detail: auto
library_detail_idle_secs: 300
# Optional explicit Go runtime budget, also used by the collector:
# memory_limit_mb: 1024
```

使える測定値がない場合、自動の退避は停止します。これは徐々に行うメモリ最適化であり、**ハードなメモリ上限ではありません**。アクティブなファイル、未保存の変更、リカバリスナップショット、その他のキャッシュがメモリを大きく占めることもありますし、突発的なメモリ確保の急増がスイーパーの処理を上回ることもあります。`memory_limit_mb` は引き続きソフトなコレクタの上限です。ライブデータより低く設定すると、ガベージコレクションが過剰に発生するおそれがあります。

#### データの整合性とコスト {#data-integrity-and-cost}

追い出し（eviction）時には、既存の `data/*.zurgtorrent` ダンプに加えて、**圧縮された復旧用スナップショット**も保持されます。ディスクからの再読み込みは、このスナップショットと一致している必要があります。ダンプが見つからない、壊れている、または置き換えられている場合、zurg はスナップショットを復元してリリースを resident のまま保持し、その後、復旧したデータの保存を再試行します。`auto` では、メモリ圧迫が収まった後に、アイドル状態の dirty なテーブルの保存も再試行します。これは別の、上限付きの保存パスで行われます。ファイルへの書き込みや状態の変更では、すぐに所有権が復元されます。追い出しをまたいで、ストリームが保持しているポインタ経由で行われた書き込みも含まれます。保存に失敗した場合、変更は resident かつ dirty のまま残ります。重なった書き込みが、それより前の保存によって確認されることはありません。プロセス終了後も変更を残すには、保存が成功している必要があります。

Apple Silicon の Mac、Go 1.26.4 で測定しました。変換と永続化の処理を通した、形状ごとに 500 リリースずつの結果で、復旧用スナップショットも含みます。

| 形状 | Resident bytes/entry | Lazy bytes/entry | 削減率 | 平均再構築時間 |
|---|---:|---:|---:|---:|
| Real-Debrid の映画、3ファイル | 3,662 | 2,845 | 22% | 88 µs |
| Real-Debrid のシーズンパック、24ファイル | 15,670 | 7,366 | 53% | 371 µs |
| TorBox、2ファイル | 3,019 | 2,680 | 11% | 56 µs |
| AllDebrid、1ファイル | 2,580 | 2,516 | 2% | 55 µs |
| RAR セット、7ボリューム | 5,343 | 3,303 | 38% | 109 µs |

これらの数値は、リリースごとの保持ヒープ量です。プロセス全体の RSS ではありません。再構築は最近書き込まれたローカルファイルを読み込みます。コールドストレージやリモートストレージでは、もっと時間がかかることがあります。アイドル時のメモリ回収を一定に行いたい場合は `lazy` を、メモリ圧迫時のみ回収したい場合は `auto` を選んでください。アクセスの予測可能性が RAM より重要な場合は `resident` のままにしてください。小さいリリースではあまり節約になりません。また、復旧用スナップショットは、データを守るために意図的にメモリを使います。これらの測定値は、`lazy` と `auto` の両方で追い出されたエントリを対象としています。自動モードでは、任意の時点で保持されるエントリが多くなることがあります。

## 5. ネットワークと接続（技術編） {#5-network--connectivity-technical}

zurgがどのようにバインドし、認証し、ネットワークに接続するかを制御するインフラ設定です。

### サーバーのバインド {#server-binding}

| オプション | 型 | 初期値 | 説明 |
|--------|------|---------|-------------|
| `host` | string | `"[::]"` | 待ち受けるネットワークインターフェースです。`[::]` はすべてのインターフェース（IPv4 と IPv6）で待ち受けます。IPv4 のみにしたい場合は `0.0.0.0` を使ってください。特定の IP を指定すると、1 つのインターフェースだけにアクセスを制限できます。 |
| `port` | string | `"9999"` | zurg が待ち受けるポートです。`PORT` 環境変数を設定すると、この値より優先されます。コンテナでのデプロイに便利です。 |

```yaml
host: "[::]"
port: 9999
```

### ウォーム接続 {#warm-connections}

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `warm_connections` | int | *(未設定)* | 独自の値を持たないすべてのアカウントに適用される下限です。未設定の場合、各バックエンドはデフォルト値を使います。ディブリッドアカウントはホストごとに1、ニュースアカウントはアカウントごとに2です。`-1` を指定すると、すべてのウォームアップを無効にします。アカウントごとの `warm_connections` は常に優先されます。グローバルの `-1` よりも優先されます。 |

```yaml
warm_connections: 2        # every account keeps 2, unless it says otherwise

providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    warm_connections: 4    # this one keeps 4 to each host it uses
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    warm_connections: -1   # and this one keeps none
```

**この設定でどれだけ効果があるかは、ホストによって変わります。ディブリッドサービスの場合、思っているほどの効果はありません。** 何も送られていない接続は、これらのサービスが最初に切断するものです。しかも素早く切断します。2026-08-29にライブホストで計測した結果、無通信の接続を開いたまま、切断されるまでの時間は次のとおりでした。

| ホスト | 無通信の接続 | リクエストを処理した後 |
|---|---|---|
| Real-Debrid のダウンロードホスト | 30秒後に切断 | すぐに切断 |
| `api.alldebrid.com` | 15秒後に切断 | 4分後も接続中 |
| `api.torbox.app` | 15秒後に切断 | 4分後も接続中 |
| `api.real-debrid.com` | 4秒後に切断 | 5秒後に切断 |

そのため、warm floor が役に立つのはダウンロードホストくらいで、それ以外ではあまり効果がありません。Real-Debrid の API はウォームアップできません。4秒で切断されてしまうので、どんな下限を設定しても、zurg が意図的にトラフィックを送って接続を維持しない限り間に合いません。zurg はそのようなことはしません。思い込みで判断せず、**フロアが自分で計測します**。フロアが開いた接続は15秒ごとに入れ替えられ、そのたびに接続がまだ生きていたかを確認します。読み取りで使われる前に接続が閉じられてしまうホストでは、フロアは諦め、そのホストの読み取りは従来どおり都度接続します。設定は何も必要ありません。また、静かなライブラリでフロアが使われなかっただけの場合も、この判定の対象にはなりません。

設定を上げる前に知っておきたいことが、ほかにも2つあります。

- **ディブリッドアカウントのフロアはホストごと、ニュースアカウントのフロアはアカウントごとに適用されます。** ディブリッドアカウントは、APIのホスト名やリンクごとの配信ホストなど、多くのホストを経由します。どのホストを使うかは、リンクが発行されるまで分かりません。そのため、ウォームに保たれるのは、そのアカウントが実際に使ってきたホストです。同時に保持されるのは最大16個で、10分間使われなかったホストは切り離されます。ニュースアカウントは設定で指定した1つのホストだけを使い、プランで許される限りセッションを維持します。そのため、ニュースアカウントのフロアは確実に効果を発揮します。詳しくは [Usenet](../guides/usenet.md) を参照してください。
- **ウォームな接続も実際の接続であり、プロバイダーが管理するホストごとの上限にカウントされます。** その上限は Real-Debrid と AllDebrid では32、TorBox では20です。そのため、ディブリッドのフロアは4までに制限されています。この程度の数なら上限にほとんど影響しません。大きな値にすると、何も運ばないソケットに上限を使い切ってしまいます。

`proxy` が設定されている場合、フロアは無効になります。HTTP または SOCKS のプロキシが設定されていると、zurg はホストではなくプロキシへ接続するため、先で保持する価値のある接続がないからです。

### 認証とプロキシ {#authentication--proxy}

| オプション | 型 | 既定値 | 説明 |
|--------|------|---------|-------------|
| `username` | string | `""` | HTTP basic認証のユーザー名です。`password`と一緒に設定すると、zurgへのすべてのリクエスト（ダッシュボード、WebDAV、API）で認証が必要になります。空のままにすると認証は無効になります。 |
| `password` | string | `""` | HTTP basic認証のパスワードです。`username`と一緒に設定する必要があります。 |
| `proxy` | string | `""` | zurgのすべての外向きネットワーク通信をプロキシ経由にします。`http://`、`https://`、`socks5://`に対応しています。ISPがReal-Debridの通信をブロックしたり帯域を絞ったりする場合に便利です。例: `socks5://user:pass@host:port`。このキーが空の場合は`PROXY`環境変数が使われます。 |

```yaml
username: ""
password: ""
proxy: "http://[username:password@]host:port"
```

### Rclone の設定 {#rclone-settings}

| 項目 | 型 | デフォルト | 説明 |
|------|------|---------|-------------|
| `rclone_enabled` | bool | `false` | `true`にすると、zurgがrcloneのマウントを自動で管理します。これでrcloneを別に起動する必要がなくなります。zurgがrcloneプロセスを起動し、監視し、必要に応じて再起動します。マウントポイントには`mount_path`が使われます。 |
| `rclone_binary` | string | `"rclone"` | rcloneの実行ファイルへのパスです。rcloneがシステムのPATHに入っていない場合のみ必要です。 |
| `rclone_extra_args` | list | `[]` | rcloneのマウントコマンドに渡す追加のコマンドラインフラグです。zurgのベンチマークで最適化されたVFSのデフォルト設定（下の表を参照）を上書きするには、これを使います。各項目は1つのフラグ文字列です。RC設定と`--union-*`/`--webdav-*`のバックエンド用フラグは拒否されます。zurgがそれらを自分で組み立てており、ここで指定したフラグは組み立てた内容より優先されてしまうため（`union_writable`がマウントの状態を正しく表さなくなります）です。 |
| `mount_read_only` | bool | `false` | `true`の場合、マウントはrcloneの`--read-only`付きで起動されるため、カーネルが書き込みをzurgに届く前に拒否します。マウントへのDELETEを止める手段はこれしかありません。ほかに止める仕組みがないためです。ただし、WebDAVエンドポイントに直接接続するクライアントは対象外です。また、マウントのローカルunion上流に誤った書き込みが入るのも防ぎます。フラグごとに上書きするには`rclone_extra_args: ["--read-only=false"]`を使います。 |
| `rclone_cache_reclaim` | bool | `true` | zurgが、以前のマウント設定で残されたVFSキャッシュのツリーを削除するかどうかです。rcloneはキャッシュ名をリモート名から付けますが、その名前はunion上流のハッシュ値になります。上流には`data/local`の絶対パスが含まれるため、zurgのディレクトリを移動したり`union_writable`を切り替えたりすると、キャッシュ名が変わり、古いツリーが残ってしまいます。そうなると上限のカウントにも入らず、クリーナーも見に来ません。マウント開始時に、zurgは実行中のrcloneに今どのツリーが有効かを問い合わせ、それ以外を削除して、解放した内容をログに出します。有効なツリーがrcloneの示す場所にない場合は何もしません。また、`rclone_extra_args`で`--cache-dir`を設定していると、この掃除は丸ごとスキップされます。残っているツリーをすべて残したい場合は`false`にしてください。詳しくは[マウントが使うディスク](#disk-the-mount-uses)を参照してください。 |
| `union_writable` | string | `"local"` | 埋め込みマウントのunionのどちら側に新規作成ファイルを書き込むかです。`local`（デフォルト）は、zurgを経由せずに直接ローカル上流（`data/local`）に書き込みます。`server`はWebDAV上流を先頭に並べるため、作成要求がzurgに届きます。`__magic__`の外では拒否され、内では容量上限付きのサイドカーファイルとして書き込まれます。拒否された書き込みはディスクには届きません。rcloneのVFSキャッシュはそれを受け付けたうえで、バックオフしてアップロードを再試行します。そのため、キャッシュの上限に収まり、`logs/rclone.log`で確認できます。一方、localの順序では無制限のバイト数が`data/local`に書かれてしまうところです。`server`で確認された注意点として、マウント経由でサイドカーファイルをリネームするとエラーが返ることがあります（ファイルは両方の上流に見えるため、rcloneは移動をそれぞれに適用します）。`__magic__`内でのリリース移動（\*arrのインポート経路）は影響を受けません。`server`に切り替えても変わるのは*新しい*作成先だけです。localの順序ですでに`data/local`に書かれたものは、削除するまで残ります。zurgが起動時に出力する行に現在のモードが表示されます（`new files go to zurg over WebDAV (union_writable: server)`）。`data/local`のパスがあるかどうかではなく、この行で確認してください。このパスはどちらの順序でもunionの一部になるためです。 |

```yaml
rclone_enabled: false
rclone_binary: "rclone"
rclone_extra_args: []
mount_read_only: false
rclone_cache_reclaim: true
union_writable: "local"
```

#### ベンチマーク最適化のデフォルト値 {#benchmark-optimized-defaults}

zurg は、ベンチマークで検証済みの rclone VFS 設定を使って、ストリーミング性能を最適化しています:

| 設定 | デフォルト | 理由 |
|------|-----------|------|
| `--buffer-size` | 256M | スムーズなストリーミングのための大きめのバッファ |
| `--vfs-read-chunk-size` | 32M | 新しい読み込みがどれくらい加速に時間をかけるかを決めます。最初のチャンクはこのサイズで取得され、そこから倍々に増えていきます。そのため 4M だと、オフセット先頭からの読み込みの大半が回線速度を大きく下回っていました。これはリクエストサイズであり、強制的な転送ではありません。rclone は、リーダーが読むのを止めれば取得も止めます。 |
| `--vfs-read-chunk-size-limit` | 512M | 上の倍増が止まる上限です。チャンク分割はデフォルトで有効なので、これは上書きで有効になるものではなく、ランプが到達する上限値です。 |
| `--vfs-read-ahead` | 128M | バッファと帯域効率のバランス |
| `--max-read-ahead` | 1M | FUSE カーネルバッファを小さくして、細かい読み込みを減らします。Windows では渡されません。 |
| `--vfs-read-wait` | 5ms | 重要: これを大きくすると深刻な遅延が起きます |
| `--vfs-cache-mode` | full | 最高の性能のためのフルキャッシュ。ただし、プレイヤーがシェア経由でマウントを読む場合は、常に適切な選択とは限りません。[キャッシュのコストが利益を上回るとき](#when-the-cache-costs-more-than-it-buys)を参照してください。 |
| `--vfs-cache-max-size` | 256G | ディスク上の VFS キャッシュの厳格な上限。設定キーではないため、`rclone_extra_args` で上書きしてください。 |
| `--vfs-cache-min-free-space` | 10G | キャッシュディスクがいっぱいになる前にキャッシュを止めます |
| `--vfs-cache-max-age` | 72h | 触れられていないキャッシュファイルを保持する期間。重要なのは「触れられていない」という点で、メディアサーバーはほとんど何にも触れないままにしません。[マウントが使うディスク](#disk-the-mount-uses)を参照してください。 |
| `--vfs-cache-poll-interval` | 1m | キャッシュの更新に素早く反応します |
| `--vfs-fast-fingerprint` | on | ハッシュ計算をせずにファイルを識別します |
| `--dir-cache-time` | 12h | 一覧は数時間保持されます。ライブラリが変わると、zurg は RC API 経由で該当エントリを破棄するため、メディアサーバーのスキャンは温かいキャッシュを使い続けられます |
| `--attr-timeout` | 60s | ライブラリのファイルは変更されず、状態が変わると該当エントリは明示的に破棄されます。スキャンの途中で古いサイズが残らないよう、上限を設けています。 |
| `--poll-interval` | 0 | 変更の監視は rclone ではなく zurg の役目です |
| `--timeout` | 5m | IO のアイドルタイムアウト |
| `--no-modtime` / `--no-checksum` | on | デビッドライブラリではどちらも意味がなく、指定するとリクエストが余計に発生します |
| `--async-read` | rclone のデフォルト（on）、指定なし | zurg はこのフラグをコマンドラインに付けず、rclone のデフォルトは true です。つまりマウントは非同期で読み込み、このページの数値はすべてその条件で計測されています。以前、ある調整フィールドがこれを無効にすると説明していましたが、実際にはフラグを単に追加するだけで、それはもともとのデフォルトと同じ設定でした。実際に無効にするには: `rclone_extra_args: ["--async-read=false"]` |
| `--low-level-retries` | 3 | rclone の VFS ダウンローダーは、1 回のオープンにつき失敗した読み込みを 10 回再開します。そして再開のたびに、バックエンドのペーサーがこの回数だけ再試行します。rclone のデフォルトの 10 だと、zurg が意図的に 503 を返しているファイルを 1 回開くだけで 100 リクエストになります。 |
| `--retries` | 1 | コマンド全体の試行回数の上限です。終了しないマウントでは、起動失敗を増幅させるだけです |
| `--vfs-handle-caching` | 0、rclone 1.74 以降は on | rclone 1.74 では、ファイルを閉じてからも 5 秒間ダウンローダーを維持するようになりました。そのためファイルに一度触れるだけで、読んだ量ではなく、回線が運べる量の 5 秒分が消費されます。50 MB/s のサーバーで計測したところ、1 MiB の読み込み 1 回で 3〜6 MiB ではなく 245〜250 MiB が転送され、20 ファイルのスイープは 80 MiB から 4.2 GiB に増えました。この猶予期間は `serve nfs` のためのもので、zurg はこれを実行しません。古い rclone にはこのフラグがなく、未知のフラグがあると起動を拒否するため、zurg はまずバイナリにバージョンを問い合わせ、1.74 より前では何も渡しません。 |
| `--log-level` | NOTICE | rclone 自身の詳細度。常に渡されます |
| `--cache-dir` | `data/rclone-cache` | 作業ディレクトリを基準に解決されます |
| `--log-file` | `logs/rclone.log` | 作業ディレクトリを基準に解決されます |

`--vfs-cache-max-size`、`--vfs-cache-min-free-space`、`--low-level-retries`、`--retries`、`--vfs-handle-caching`、`--log-level`、`--cache-dir`、`--log-file` は `internal/rclone/manager.go` の定数です。それ以外の行はすべて `internal/rclone/tuning.go` の `tuneVFSOptions` から来ています。名前とは裏腹に、`--vfs-cache-max-age` と `--vfs-cache-poll-interval` もこちらに含まれます。

### マウントが使うディスク {#disk-the-mount-uses}

`--vfs-cache-mode full` は、マウント経由で読み込まれたファイルを **完全に** `data/rclone-cache` にダウンロードし、再生が終わった後もそこに残す、という意味です。動画を止めたら空になる再生用の一時バッファではありません。放置すると、キャッシュは `--vfs-cache-max-size` まで増え続けます。そのデフォルトは **256G** で、そのまま残ります。

2つの上限がキャッシュを制限するはずですが、実際に効いているのは片方だけです。

- `--vfs-cache-max-size` (256G) が本当の上限です。`data/` が置かれているディスクの空き容量の半分以下に設定してください。
- `--vfs-cache-max-age` (72h) は、3日間誰も触れなかったファイルを削除します。rclone は、ファイルシステムの atime ではなく、`data/rclone-cache/vfsMeta/` 内の自身の記録をもとに計測します。そして **ライブラリを読むものは何であれ** その時刻を更新します。スケジュールタスクが有効な Plex サーバーは、夜間メンテナンス時間帯にキャッシュ済みのファイルをすべて読み込みます。そのため 2026-09-09 には、362 個のファイルをキャッシュしていたインスタンスで、すべてのファイルの ATime がその朝の時刻になっていました。数か月の間、どれも古くなって削除されることはなく、今後もありません。年齢による削除を前提に計画しないでください。サイズの上限を基準に計画してください。

`rclone_extra_args` で上限を下げます:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

`--vfs-cache-min-free-space` (デフォルトは 10G) は、ディスクがその量まで埋まるとキャッシュを停止します。他のものと共有しているディスクでは、0 よりずっと大きい値に保ってください。

キャッシュを手動で空にするには、まず zurg を停止してから、両方のツリーを空にします:

```bash
rm -rf data/rclone-cache/vfs/* data/rclone-cache/vfsMeta/*
```

`du -sh data/rclone-cache` で測定します。部分的にダウンロードされたエントリはスパースファイルなので、見かけのバイト数を数えるサイズ表示では、実際にディスクが保持している量よりずっと多く報告されます。

#### キャッシュの費用が効果を上回るとき {#when-the-cache-costs-more-than-it-buys}

`full` は、同じホスト上のメディアサーバーにとっては適切なデフォルトです。ファイルを一度読めば、その後の処理はすべてローカルで完結するからです。ただし、ファイル共有経由でマウントを読むハードウェアプレーヤーにとって、自動的に正しい設定とは限りません。

`full` では、読み取りはリーダーに届く前にまずディスクへ書き込まれている必要があります。しかも取得されるのは、視聴中の部分ではなくファイル全体です。その前に共有を置くと、rclone がまだディスクに書き込んでいる最中に、同じディスクがプレーヤーへの配信も担うことになります。Zidoo プレーヤーで Windows の共有を読み込んだところ、キャッシュをオフにするまでどのタイトルでもカクつき、その後は問題なく再生できたという報告があります（2026-08-30 報告）。以下の仕組みは、この報告についてもっともらしい解釈であって、ここでは測定していません。直接読み取るクライアントが、同じホスト上のメディアサーバーでは問題なく再生できるマウントでカクつく場合は、まずこれを試してみてください。

```yaml
rclone_extra_args:
  - "--vfs-cache-mode"
  - "off"
```

失うものも現実的です。ローカルコピーがないと、シークのたびにプロバイダーから再読み込みされ、2回目の再生では同じファイルをまた丸ごとダウンロードします。再起動すると何も残りません。また、マウントが受け付ける書き込みの扱いも変わります。そのため、\*arr がマウント経由でインポートするホストでは、デフォルトのままにしておいてください。詳しくは [qbittorrent.md](../guides/sonarr-radarr-torrents.md) を参照してください。

#### 移動によって取り残されたキャッシュ {#caches-stranded-by-a-move}

rclone は、キャッシュ対象のリモート名をもとにキャッシュ名を付けます。その名前にはリモートの設定のハッシュが含まれています。zurg のリモートは union で、その upstream には `data/local` の絶対パスが埋め込まれているため、設定が変わると名前も変わります。

| Union の upstream | キャッシュツリー |
|---|---|
| `/home/you/zurg/data/local :webdav:` | `vfs/zurg{QaSkn}` |
| `:webdav: /home/you/zurg/data/local` (`union_writable: server`) | `vfs/zurg{HdSp7}` |
| `/other/root/data/local :webdav:` (zurg を移動した) | `vfs/zurg{Psid2}` |

rclone が集計するのは、現在使っているツリーだけです。古い名前のツリーは上限にカウントされず、クリーナーにも対象にされず、どこからも削除されません。そのため、zurg のディレクトリを移動したり、新しいマウントポイントで戻ってきた外付けドライブがあったりすると、キャッシュが丸ごと残ります。こうした移動が何度か重なると、256G の上限を設定しているのに、複数テラバイトを抱えることになります。

zurg はマウント開始時にそれらのツリーを回収します。実行中の rclone に現在どのツリーが有効かを問い合わせ、残りを削除して、解放した内容をログに出力します。有効なツリーが rclone の示す場所にディスク上にある場合にのみ動作します。また、`rclone_extra_args` で `--cache-dir` が設定されている場合は、そのディレクトリが別の zurg と共有されているかもしれないため、回収は完全にスキップされます。回収を無効にして、取り残されたツリーをすべて残すには、`rclone_cache_reclaim: false` を設定してください。

さらに 4 つのフラグがプラットフォームによって追加されます。すべて Linux 上のものです。`--allow-other` と `--allow-non-empty` は常に追加されます。`--uid` と `--gid` は、実行中のユーザーの ID を読み取れる場合のみ追加されます。`--max-read-ahead` は Windows 以外のすべてで渡されます。[`mount_read_only`](#rclone-settings) が設定されている場合は、`--read-only` も渡されます。

バッファと read-wait の値は、600 Mbps 回線でのベンチマークにより決定しました。コールドキャッシュ時のスループットは約 533 Mbps、TTFB は約 235ms でした。読み取りチャンクサイズは、後日、約 70 MB/s のホストで再測定しました。対応する測定を交互に行った結果、Real-Debrid では 4M から 32M に変更したところ、中央値のスループットが 49.1 → 56.5 MB/s に向上しました。TorBox でも同じ傾向でした。

**既定値を上書きするには** `rclone_extra_args` を使います:
```yaml
rclone_extra_args:
  - "--buffer-size=128M"        # Use less memory
  - "--vfs-read-chunk-size=2M"  # Smaller chunks
```

RC フラグ（`--rc`、`--rc-addr`、および `rc-` で始まるその他すべて）は拒否されます。zurg 自身が rclone のリモートコントロールを動かし、ライブラリが変更されたときに VFS キャッシュを無効化しているためです。

### User Agent とネットワーク {#user-agent--network}

| オプション | 型 | 既定値 | 説明 |
|--------|------|---------|-------------|
| `user_agent` | string | Chrome UA | プロバイダー、インデクサー、ffprobe、外部連携で共有される HTTP User-Agent です。空にすると一般的なブラウザのデフォルトに戻ります。明示的に指定したカスタム値は、入力どおりに送信されます。再起動が必要です。詳しくは [送信リクエストの識別情報](outbound-identity.md) を参照してください。 |
| `omit_user_agent` | boolean | `false` | HTTP User-Agent を送信しないようにします（ffprobe は空の値を使います）。`user_agent` より優先されます。GitHub へのリクエストは、GitHub が User-Agent のないリクエストを拒否するため、引き続き送信されます。再起動が必要です。 |
| `outbound_client_name` | string | `"Media Client"` | 対応しているメディアサーバー連携で使われる製品名 / クライアント名です。空にするとデフォルトに戻ります。再起動が必要です。 |
| `outbound_client_id` | string | `"media-client"` | 対応しているメディアサーバー連携で使われる Plex クライアント識別子です。サインインも含みます。空にするとデフォルトに戻ります。再起動が必要です。 |
| `outbound_client_version` | string | `"1.0"` | 対応しているメディアサーバー連携で使われるクライアントのバージョンです。空にするとデフォルトに戻ります。再起動が必要です。 |
| `outbound_device_name` | string | `"Media Client"` | 対応しているメディアサーバー連携で使われるデバイス名です。空にするとデフォルトに戻ります。再起動が必要です。 |
| `outbound_device_id` | string | `"media-client"` | 対応しているメディアサーバー連携で使われる Jellyfin / Emby のデバイス識別子です。空にするとデフォルトに戻ります。再起動が必要です。 |
| `outbound_platform` | string | `"Desktop"` | 対応しているメディアサーバー連携で使われる Plex のプラットフォームです。空にするとデフォルトに戻ります。再起動が必要です。 |
| `force_ipv6` | bool | `false` | zurg のネットワークテストとホスト選択をすべて IPv6 で行うように強制します。ネットワークで RD サーバーへの IPv6 接続の方が良好な場合は、これを有効にしてください（例：一部の ISP は IPv4 だけを制限し、IPv6 は制限しない場合）。 |
| `unrestrict_ip` | string | `""` | unrestrict のときに RD に渡す IP アドレスです。マルチネットワーク構成で、zurg が動いている IP ではなく、特定の IP（例：VPN の出口 IP）向けにダウンロードリンクを生成したい場合に便利です。 |
| `dns_servers` | list | `[]` (システムの DNS) | RD のホスト名を解決するためのカスタム DNS サーバーです。システムの DNS が遅い、不安定、または ISP によってブロックされている場合に便利です。空のままにするとシステムのリゾルバーを使います。ポートを含める必要があります（例：`1.1.1.1:53`）。 |
| `network_test_every_mins` | int | `1440` | zurg が最速の RD ダウンロードサーバーを見つけるために、ネットワークのレイテンシテストを再実行する頻度（分単位）です。無効にはできません。`<= 0` の値は `1440` として扱われます。結果は `data/network_test_results.json` と `data/network_test_timestamp` に保存されます。再起動時にキャッシュが十分新しければ、ネットワークテストはスキップされます。 |

```yaml
user_agent: "Mozilla/5.0 ..."
force_ipv6: false
unrestrict_ip: ""
network_test_every_mins: 1440
dns_servers:
  - "1.1.1.1:53"   # Cloudflare
  - "8.8.8.8:53"   # Google
```

### NZB の公開共有 {#public-nzb-sharing}

NZB共有は、受信者が取りに行くURLです。そのため、受信者がこのホストに届く場合にしか役に立ちません。ところが、ホームNATの裏にあるzurgは、それを保証できません。この2つのキーは、そのURLを代わりに[zrok](https://zrok.io)サービス経由にします。zurgがサービスへ外向きに接続し、その接続を通じて共有を提供するので、**ローカルのポートは一つも開かず**、このホストで新しく応答するものもありません。トンネルで流れるのは、トークンで保護された2つの共有ルートだけです。ダッシュボードもライブラリも流れません。

両方が空で、`data/zrok`に有効な環境がなければ、共有はこのホストが今いるネットワーク上にとどまり、どこにも接続しません。これがデフォルトです。ただし後半も大事です。環境が一度*有効化された*後は、`zrok_account_token`が空でも、もうローカルのみという意味にはなりません。有効化によって共有がオンになり、その状態が保存されるからです。公開共有をオフに戻すには、`data/zrok`を削除してください。

共有の作成、提供、取り消しは、どちらの場合も同じように動きます。パスに含まれる共有トークンが、ローカルURLでも公開URLでも認可になります。

公開URLは再起動後も残ります。サービス側の共有は、作り直されるのではなく、探し出して再接続されます。残らないのは、再度有効化した場合です。新しい環境には新しい共有が作られ、古い環境で発行されたURLは解決しなくなります。これは`data/zrok`を削除したときに起きます。また、そこに保存されたIDが消えたり読めなくなったりした場合も同じです。その場合は、再度有効化するしか復旧の方法がないからです。

`data/zrok`を手で削除しても、その環境と配下の共有はzrokアカウントに登録されたままになります。それらを解放できたIDは、今まさに削除したものだからです。ゴミが気になる場合は、zrokコンソールから整理してください。また、これは共有をその場でオフにする方法でもありません。動いているzurgは、すでに提供中の接続を保持しているので、プロセスが再起動するまで古いURLは使えたままです。zurgは、環境を置き換えるときに自分で古い環境を解放します。サービスに届かず解放できなかった場合や、ディスク上にファイルは見つかったけれど読めない場合は、置き換えを拒否します。読めない環境の上から有効化すると、再起動のたびに動いている環境を放棄することになるからです。

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `zrok_account_token` | string | `""` | 公開共有をオンにするzrokの有効化トークンです。ホストされたサービスを使う場合は[myzrok.io](https://myzrok.io)で無料で取得できます。自前でホストする場合は、自分のコントローラーから取得します。必要なのは**最初の有効化のときだけ**です。有効化の際に一度だけ使われ、環境のIDとともに`data/zrok`に保存されます。それ以降の呼び出しは、この保存されたものを使って認証します。そのため、後で`config.yml`からキーを消しても、次回の再起動時に公開共有は問題なく立ち上がります。ただし、秘密情報について次のことを意味します。設定からキーを消しても、トークンはホストから消えません。それでもキーを残しておく理由は二つあります。一つ目は、有効化が*失敗*した場合です。トークンが拒否された、あるいはサービスに届かなかった場合などは完了していないので、再試行にキーが必要です。二つ目は、後で*再度*有効化する場合です。キーを消した後で`data/zrok`内のIDを失ったインスタンスは、自力では復旧できません。有効化済みのトークンを更新した場合は、ここから新しい値が読み込まれ、保存された環境、ID、公開URLはそのまま保たれたまま適用されます。 |
| `zrok_api_endpoint` | string | `""` | 接続先のzrokサービスです。自前でホストする場合に使います。空のままだと、SDKのデフォルトである`https://api-v2.zrok.io`（ホストされたサービス）になります。**有効化の時点でのみ**読み込まれます。`data/zrok`に有効な環境が一度保存されると、そこに保存されたエンドポイントが優先されます。そのため、既に有効化済みのzurgを別のサービスに向けたい場合は、`data/zrok`を削除してから、もう一度有効化する必要があります。IDは発行したサービスに属するものなので、この順序が筋が通っています。これは`zrok_account_token`の代わりにはなりません。最初の有効化には、ここで指定したサービスから取得したトークンが今でも必要です。同じ時点では、SDK自身の`ZROK2_API_ENDPOINT`環境変数がこのキーより優先されます。 |

自前でホストするサービスの場合、到達性は2つの方向で別々に考える必要があり、そのうち自分で管理できるのは一方だけです。**このzurg**はコントローラーAPIに届く必要があり、そのためにはtailnetのアドレスで十分です。一方、**受信者**はサービスのフロントエンドに届く必要があります。自分のtailnet内でしか届かないサービスでは、自分のtailnet内の人しか開けない共有URLが発行されてしまいます。

自前でホストするサービスでは、さらに2点を揃える必要があります。共有URLは、サービスがフロントエンド用に広告しているURLになります。スキームのない素のホスト名は`https`と見なされます。そのため、平文HTTPで配信するフロントエンドの前にはTLSを置くか、スキームとポートを含む完全なURLを広告させてください。もう一つは、共有がzrok SDKの解決する名前空間に作られる点です。これは、SDK自身の`ZROK2_DEFAULT_NAMESPACE`で別の指定がない限り`public`です。zurgはどちらも固定しないので、名前空間の名前が違うサービスの場合は、その環境変数で伝えてください。

```yaml
zrok_account_token: ""   # the enable token, needed for the first enable only
zrok_api_endpoint: ""    # self-hosted only; empty = the hosted service
```

## 6. パフォーマンスとチューニング（上級編） {#6-performance--tuning-advanced}

これらの設定は、デバッグや特定のネットワーク環境に合わせた最適化をするとき以外は、ほとんど触る必要はありません。

### 永続的な読み取りキャッシュ {#persistent-read-caches}

二つのバイトキャッシュは、再起動後も残ります。どちらもインスタンス全体で共有され、それぞれ MiB 単位の独自のディスク上限があります。変更は再起動後に反映されます。

| オプション | 型 | 初期値 | 説明 |
|--------|------|---------|-------------|
| `nzb_article_disk_cache_mb` | int | `512` | デコード済みの Usenet 記事を `data/bytecache/articles/` に保存します。一度読んだ記事は、次回からディスクから配信されます。`0` で無効になります。 |
| `archive_decoded_disk_cache_mb` | int | `512` | 展開済みのアーカイブブロックを `data/bytecache/decoded/` に保存します。後方シークや再起動のとき、エントリの先頭から再度デコードすることはありません。同じ上限が `data/bytecache/decoded-tails/` にも使われ、一度要求された圧縮エントリの最後の 8 MiB を保持します。`0` にすると両方とも無効になります。 |

上限がいっぱいになると、最も古く使われていないレコードから先に削除されます。再起動後も残るすべてのキャッシュについては、[再起動後も残るキャッシュ](../internals/persistent-caches.md)を参照してください。

### CDN とホストの選択 {#cdn--host-selection}

> **関連:** 最速のホストを決めるネットワーク遅延テストは、[`network_test_every_mins`](#user-agent--network)に基づいて定期的に実行されます(デフォルト: 1440分 / 24時間ごと)。

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rd_cdn_host_preference` | string | `"auto"` | zurg が優先する RD のダウンロードサーバーを指定します。`auto` は RD が提供するものをそのまま使います。`force_cloudflare` はホストを `.cloud` の対応ホストに書き換えます。これは Cloudflare 経由で同じマシンに届くので、直接の IP がブロックされている場合に便利です。`force_numbered` は RD の番号付きホストを直接使います。`force_location_<location>`(例: `force_location_syd`、`force_location_fra`)は、特定の国のサーバー経由でルーティングします。 |
| `cdn_host_preference` | string | — | `rd_cdn_host_preference` の古い別名です。互換性のために残されており、Real-Debrid でのみ使われます。両方が設定されている場合は、明示的に指定した方が優先されます。 |
| `tb_cdn_host_preference` | string | `"auto"` | TorBox の CDN リージョンです。`auto` は TorBox 側の選択をそのまま使います。`force_location_<region>` を指定すると、そのリージョンからダウンロードを配信します。現在配信ノードを公開しているリージョンだけを強制できて、ダッシュボードの選択肢にはそのリージョンだけが並びます。古いキーへのフォールバックはありません。その値は Real-Debrid のロケーションコードなので、ここでは意味がないからです。 |
| `number_of_hosts` | int | `0` (all) | zurg が使うダウンロードホストを、速い順に N 件までに絞ります。利用可能なホストの速度テストを行った後、zurg は上位 N 件だけを使います。すべての利用可能なホストを使うには `0` を設定します。`3` のような値にすると接続の分散は減りますが、常に最速のサーバーを使えるようになります。 |

```yaml
rd_cdn_host_preference: "auto"
tb_cdn_host_preference: "auto"
number_of_hosts: 3
```

> **`force_cloudflare` と `force_location_*` は同時に使えません。** RD が `.cloud` の対応ホストを用意しているのは、番号付きホストだけです。2026-08-09 に測定したところ、番号付きサブドメイン 25 件はすべて対応ホストを持っていますが、国別の 22 件はどれも持っていませんでした。そのため、RD アカウントの設定で Cloudflare を有効にしているアカウントには、必ず番号付きホストが割り当てられ、どのロケーション指定も反映されません。zurg は起動時にアンレストリクトしたリンクからこれを検出し、成功しないジオプロービングを飛ばします。それでもロケーションが設定されている場合は、その理由をログに出力します。

> **`force_location_*` の検証に関する注意:** `force_location_nyk` のようなジオロケーション指定を使うと、RD の `/rest/1.0/downloads` API エンドポイントは、実際のアンレストリクトのレスポンスでは地域サーバー(例: `nyk7-4.download.real-debrid.com`)が返されていても、ダウンロード URL を番号付きサーバー(例: `128-4.download.real-debrid.com`)に正規化します。ダウンロードコード自体にも番号付きサーバーが埋め込まれています(例: コード `...4128` はサーバー `128-4` に対応します)。ジオルーティングが正しく動作しているかを確認するには、zurg のログか、生のアンレストリクトのレスポンスを確認してください。RD の downloads API は **使わないでください**。

### レート制限 {#rate-limits}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_rate_limit_per_minute` | int | `250` | RD API への一般的な操作 (torrent の一覧取得を除くすべて) で 1 分あたりに呼び出せる最大数です。RD 側でも独自の制限があり、この設定は zurg がその制限に引っかかって一時的にブロックされるのを防ぎます。RD プランで上限を増やしてもよいと確信できる場合にだけ増やしてください。 |
| `torrents_rate_limit_per_minute` | int | `75` | torrent 一覧を取得するための `/torrents` エンドポイントに対して、1 分あたりに呼び出せる最大数です。torrent の一覧取得は最も頻繁に行われる API 呼び出しで、独自のレート特性があるため、別に分けています。 |
| `fetch_torrents_page_size` | int | `5000` | RD ライブラリを同期するときに、1 ページあたりに取得する torrent の数です。値を大きくすると API 呼び出しの回数は減りますが、1 回のレスポンスが大きくなります。ライブラリが非常に大きい場合 (10,000 件以上)、この値を大きくすると同期にかかる時間を短縮できます。 |

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

### リンクの検証 {#link-verification}

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `use_range_verification` | bool | `false` | zurg がダウンロードリンクがまだ有効かどうかを確認する方法を制御します。false の場合、zurg は `HEAD` リクエストを使います（軽量で、データは転送されません）。true の場合は `Range` ヘッダー（`GET bytes=0-0`）を使い、1 バイトだけダウンロードします。ネットワークや RD のサーバーが HEAD リクエストに正しく応答せず、リンクが誤って失敗扱いになる場合は、これを有効にしてください。 |

```yaml
use_range_verification: false
```

### タイムアウトとリトライ {#timeouts--retries}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_timeout_secs` | int | `60` | RD APIの呼び出しが応答するまで待つ最大秒数です。回線が遅くてAPI呼び出しがタイムアウトする場合は、この値を増やしてください。 |
| `download_timeout_secs` | int | `15` | ダウンロードリンクをテストするとき（ホストの速度テストやリンク検証の最中）に待つ最大秒数です。実際のファイルダウンロードのタイムアウトではありません。 |
| `retries_until_failed` | int | `2` | APIの呼び出しが失敗したとき、あきらめて失敗扱いにするまでに何回再試行するかです。値を大きくするとRDの一時的な障害に強くなりますが、失敗の検出は遅くなります。 |
| `retry_503_errors` | bool | `false` | trueにすると、RDから503 (Service Unavailable) の応答を受けたリクエストを再試行します。RDはメンテナンス中や過負荷のときに503を返します。すぐに直る503エラーが頻繁に出る場合は、これを有効にしてください。 |

```yaml
api_timeout_secs: 60
download_timeout_secs: 15
retries_until_failed: 2
retry_503_errors: false
```

### ダウンロードとデバッグ {#downloads--debugging}

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|-------------|
| `get_downloads_limit` | int | `-1` | 取得する RD のダウンロード項目 (非トレント) の最大数です。`-1` は無制限 (全件取得)、`0` はダウンロードを一切取得せず、正の数を指定するとその数で上限を設けます。RD の直接リンク解除機能を使っていて、それらのファイルを zurg で見たい場合に便利です。キーを省略すると `-1` になります。明示的に `0` と書いた場合は「cache none」として扱われ、起動時に警告が出ます。`0` の意味が変わる前に書かれた設定である可能性が高いためです。 |
| `load_dumped_torrents` | bool | `false` | true にすると、起動時に `dump/` フォルダからトレントデータを読み込みます。これは復旧用の仕組みです。zurg が以前にトレントの状態をダンプしていた場合 (例: クラッシュ時)、これを有効にすると、RD からすべて取り直さなくてもその状態を復元できます。 |
| `log_requests` | bool | `false` | true にすると、ダウンロードリクエストごとに詳細な統計 (ファイルパス、応答時間、送信バイト数) をログに出します。ストリーミングの問題のデバッグや、アクセスパターンの把握に便利です。ログ量が大きくなるので、本番環境では無効にしてください。 |
| `log_level` | string | `DEBUG` | ログの詳細度です: `DEBUG`、`INFO`、`WARN`、`ERROR`、`FATAL` のいずれか。ダッシュボードから変更すると即座に反映されます。再起動は不要で、すべてのコンポーネントのレベルが一度に変わります。環境変数 `LOG_LEVEL` より優先されるので、コンテナに値が焼き込まれていても、ダッシュボードから変更できます。キーを省略すると、選択を `LOG_LEVEL` に戻します。レベル名として認識できない値は、起動時に警告を出して無視されます (起動は止まりません)。 |
| `traffic_alert_gb` | int | `0` | 1 つのデブリッドアカウントが 1 日に zurg 経由で転送したデータ量が、この GiB を超えると警告します (日付は CET の 00:05 にリセットされ、Real-Debrid の割当と同じです)。警告には、その時間帯に最も多く使われたファイルと、それを読んだ相手が表示されるので、ライブラリのスキャンやクライアントによるファイル全体の取得が起きている最中に気づけます。アラートの設定に関係なく、zurg は毎時の初めに、その時間で最も大きいファイルの概要をログに出します。また、1 回の読み取りが 1 GiB 以上の場合にも 1 行ログに出します。`0` でアラートを無効にします。 |
| `traffic_alert_webhook` | string | — | アラートも投稿される Discord の Webhook です。URL を知っている人は誰でもそのチャンネルに投稿できるので、非公開にしてください。 |

```yaml
get_downloads_limit: -1
load_dumped_torrents: false
log_requests: false
log_level: DEBUG
traffic_alert_gb: 500
```

#### サポートへのログ送信 {#sending-logs-to-support}

**Export Logs** をダッシュボードで押すか `zurg support` を実行すると、マスキング済みのログと設定が DMM のサポートサーバー `logs.debridmediamanager.com` に送られ、サポートスレッドに貼るためのコードが表示されます。これを変更する設定はありません。このサーバーに接続できないか、アップロードを拒否された場合は、ファイルは公開ペーストサービスに送られます。その際は次の順番で試されます: `paste.c-net.org`、`temp.sh`、`0x0.st`。ファイアウォールで zurg がアクセスできるホストを制限している場合は、`logs.debridmediamanager.com` を許可してください。

403 を返したホストは、このマシンからのアクセスを拒否したとみなされるため、zurg はそのホストを 24 時間スキップします。`logs.debridmediamanager.com` も対象です。ダッシュボードの **Download Logs** を使うと、マスキング済みの同じファイルを、どこにも送信せずに入手できます。

## 7. ディレクトリとフィルター {#7-directories--filters}

仮想ディレクトリを定義して、柔軟なフィルタールールに基づいてトレントを整理できます。各ディレクトリはマウント内のフォルダとして表示され、そのフィルターに一致するトレントだけが表示されます。

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true

  # ... (see config.example.yml for full examples)
```

### ディレクトリのオプション {#directory-options}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `group` | string | ディレクトリ自身の名前 | 同じ group を共有するディレクトリは、各 torrent を取り合います。torrent は、filters が一致する最初のディレクトリに入り、同じ group の他のディレクトリには入りません。異なる group のディレクトリには、それぞれ独自のコピーが入ります。 |
| `group_order` | int | `0`（`1` として扱われます） | group 内の優先順位です。値が小さいほど先に来ます。同じ値の場合は、ディレクトリ名の順で決まります。 |
| `filters` | list | `[]` | このディレクトリに何を入れるかを決めるルールです。torrent は、リスト内の**いずれか**の項目に一致すれば、このディレクトリに一致します。リストが空または存在しない場合は、すべての torrent に一致します。 |
| `only_show_the_biggest_file` | bool | `false` | 各 torrent の中で最も大きいファイルだけを表示します。サンプル、特典、関連ファイルは隠します。 |
| `only_show_files_with_size_lte` | int | `0`（オフ） | 指定したバイト数より大きいファイルを隠します。 |
| `only_show_files_with_size_gte` | int | `0`（オフ） | 指定したバイト数より小さいファイルを隠します。 |
| `rex_shows` | string | `""`（なし） | `rex_url` と併用します。このディレクトリのエピソードを表示する、rex 内の TV ライブラリのタイトルです。 |
| `rex_movies` | string | `""`（なし） | `rex_url` と併用します。このディレクトリの映画と、rex がエピソードだと判断できないファイルを表示する、rex 内の Movies ライブラリのタイトルです。 |
| `rex_music` | string | `""`（なし） | `rex_url` と併用します。このディレクトリの音声ファイル（`.flac`、`.mp3`、`.m4a`、`.m4b`）を表示する、rex 内のミュージックライブラリのタイトルです。オーディオブックも含みます。これを指定しないと、音声ファイルは rex に渡されません。 |
| `rex_photos` | string | `""`（なし） | `rex_url` と併用します。このディレクトリのコミックブック（`.cbz`、`.cbr`）を表示する、rex 内の Photos ライブラリのタイトルです。各コミックはページをまとめたアルバムとして扱われ、Plex Web ではページをめくるスライドショーとして再生されます。Plex for Android には写真ライブラリが表示されません。コミックはマウント上のファイルのままです。 |

zurg で明示的に表示に設定されたファイルは、上記の3つの表示オプションをすべて無視します。

### フィルター条件 {#filter-conditions}

| 条件 | 型 | 説明 |
|-----------|------|-------------|
| `id` | string | トレントのID。優先条件です。同じエントリ内の他の条件は一切考慮されません。 |
| `regex` | string | トレント名がパターンに一致する。 |
| `not_regex` | string | トレント名がパターンに一致しない。 |
| `contains` | string | トレント名にそのテキストが含まれる（大文字小文字を区別しない）。 |
| `contains_strict` | string | トレント名にそのテキストが含まれる（大文字小文字を区別する）。 |
| `not_contains` | string | トレント名にそのテキストが含まれない（大文字小文字を区別しない）。 |
| `not_contains_strict` | string | トレント名にそのテキストが含まれない（大文字小文字を区別する）。 |
| `size_gte` | int | トレント全体のサイズが、このバイト数以上。 |
| `size_lte` | int | トレント全体のサイズが、このバイト数以下。 |
| `any_file_inside_regex` | string | トレント内のいずれかのファイルがパターンに一致する。 |
| `any_file_inside_not_regex` | string | トレント内のいずれかのファイルがパターンに一致しない。 |
| `any_file_inside_contains` | string | いずれかのファイルにそのテキストが含まれる（大文字小文字を区別しない）。 |
| `any_file_inside_contains_strict` | string | いずれかのファイルにそのテキストが含まれる（大文字小文字を区別する）。 |
| `any_file_inside_not_contains` | string | いずれかのファイルにそのテキストが含まれない（大文字小文字を区別しない）。 |
| `any_file_inside_not_contains_strict` | string | いずれかのファイルにそのテキストが含まれない（大文字小文字を区別する）。 |
| `any_file_inside_size_gte` | int | いずれかのファイルが、このバイト数以上。 |
| `any_file_inside_size_lte` | int | いずれかのファイルが、このバイト数以下。 |
| `added_within_hours` | int | トレントが、この時間数以内に追加された。 |
| `added_within_days` | int | トレントが、この日数以内に追加された。 |
| `added_after` | string | トレントが、この日付以降に追加された。形式は `YYYY-MM-DD` または `YYYY-MM-DD HH:MM`。 |
| `added_before` | string | トレントが、この日付より前に追加された。形式は同じ。`added_after` と一緒に使う場合は、両方の条件を満たす必要があります。 |
| `has_episodes` | bool | エピソードの判定。トレントまたはファイル名にシーズン/エピソードの表記やCRCハッシュがある、または連番のファイル群がある場合。最大のファイルが2番目に大きいファイルの5倍以上あると、おまけ付きの映画とみなされて除外されます。 |
| `is_music` | bool | いずれかのファイルの拡張子が `.m3u`, `.mp3`, `.flac`, `.m4a` または `.m4b`。 |
| `has_tag` | string | トレントがこのタグを持っている。ゲートとして働き、これがないとエントリ内の他の条件は一致しません。 |
| `not_has_tag` | string | トレントがこのタグを持っていない。同じようにゲートとして働きます。 |
| `tags_match_all` | list | 列挙したタグがすべて存在する（大文字小文字を区別しない）。 |
| `tags_match_any` | list | 列挙したタグのうち、1つ以上が存在する。 |
| `tags_missing_all` | list | 列挙したタグが、どれも存在しない。 |
| `tags_missing_any` | list | 列挙したタグのうち、1つ以上が存在しない。 |
| `provider` | string | リリースがこのアカウントで保持されている（providersブロックの`name`で指定）。マッチではなくゲートです。他の条件と組み合わせると両方を満たす必要があります。単独で使うと、アカウント全体がディレクトリに入ります。 |
| `not_provider` | string | リリースを保持しているアカウントに、このアカウントは含まれない。同じようにゲートとして働きます。 |
| `and` | list | 入れ子になったすべての条件に一致する必要がある。 |
| `or` | list | 入れ子になった条件のうち、1つ以上に一致すればよい。 |

タグはメディア解析から取得されます。全一覧は[tags.md](tags.md)を参照してください。

パターンは `/expression/flags` の形で書きます。フラグには `i`（大文字小文字を区別しない）、`m`（複数行）、`s`（ドットが改行にも一致）、`x`（拡張）が使えます。スラッシュで囲まれていない値は、そのままGoの正規表現としてコンパイルされます。

1つのフィルターエントリ内の条件は、デフォルトでは**AND**で結合されません。ほとんどの条件は、そのうちどれか1つが満たされた時点でエントリにマッチします。すべての条件を満たす必要がある場合は、明示的に`and:`ブロックを使ってください:

```yaml
directories:
  anime:
    group: media
    group_order: 10
    filters:
      - and:
          - has_episodes: true
          - any_file_inside_regex: /^\[/
          - not_regex: /\[One Pace\]/
```

### アカウントごとのディレクトリ {#per-account-directories}

`__all__` と並んで、設定されたアカウントごとに、アカウント名のディレクトリが作られます。例として `__realdebrid__`、`__torbox__`、`__alldebrid__`、`__nzb__` があります。これらは設定するものではありません。アカウントが存在するから現れ、アカウントを削除すると消えます。アカウントが1つだけの場合、そのフォルダはマウントのルートの一覧から外されますが、`__all__` には同じファイルが入っています。`/http/__realdebrid__/` のような直接の HTTP や WebDAV のパスは引き続き応答します。マウント経由では、もう `__<name>__` は解決されません。`__<name>__` を使っていたライブラリやスクリプトは、すべて `__all__` に向け直してください。

それぞれのディレクトリには、そのアカウントが持っているものがすべて入ります。さらに、フィルタ済みのディレクトリとは違い、読み込み元もこのディレクトリが決めます。2つのアカウントが持っているリリースは、ライブラリ上では1つのエントリです。これがないと、そのコピーはすべて `providers` ブロックで先に並ぶアカウントからストリーミングされてしまいます。

```
__realdebrid__/Some.Release/movie.mkv   → streamed from Real-Debrid
__torbox__/Some.Release/movie.mkv       → streamed from TorBox
```

このピン留めは、指定したアカウントを優先するだけでなく、他のアカウントを除外します。黙ってフェイルオーバーすることはありません。TorBox がファイルを配信できない場合、`__torbox__` 配下の読み込みは失敗します。Real-Debrid のデータを黙って返すことはありません。マウント内の他の場所での読み込みは影響を受けず、従来どおり通常にフェイルオーバーします。

アカウントごとに持っているコンテンツが同じではないため、次の2つの影響があります。

- ディレクトリには、そのアカウントが実際に持っているファイルだけが表示されます。Real-Debrid ではリリース全体を持っているのに、TorBox では一部だけダウンロードされている場合、`__torbox__` には一部だけが表示されます。
- 壊れているかどうかはアカウントごとに判定されます。Real-Debrid では無効だが TorBox では正常なファイルは、`__realdebrid__` では 404 になりますが、`__torbox__` では再生できます。マウントの他の部分では、引き続き配信されます。

ディレクトリの名前は、アカウントの `name` に基づきます。`name` の既定値は `type` です。同じサービスに2つのアカウントがある場合は、別々の名前（`rd-main`、`rd-backup`）が必要で、それぞれにディレクトリが作られます。Usenet バックエンドの既定は `nzb` なので、`__nzb__` として表示されます。`__usenet__` を参照したい場合は、そのプロバイダーのエントリに `name: usenet` を設定してください。

アカウントは後から名前を変更できます。zurg は同じリリースを新しい名前の下に認識し、そちらに移動します。古いディレクトリは古い名前とともになくなります。メディアサーバーがそのディレクトリを読んでいる場合は、名前を変更する前に新しいディレクトリを指すように設定してください。

同じリリースは、それを持つすべてのアカウントの下と、フィルタ済みのディレクトリの両方に現れるため、メディアサーバーはマウント全体ではなく、マウントの一部だけを指すようにしてください。そうしないと、同じコンテンツを何度もスキャンしてしまいます。

zurg がすでに使っているディレクトリ名（`all`、`unplayable`、`dump`、`downloads`）と同じ名前のアカウントには、アカウントごとのディレクトリは作られません。また、既存のディレクトリを乗っ取るのではなく、起動時に警告をログに出力します。

### ローカルのデブリッドカタログ {#local-debrid-catalogs}

各 debrid プロバイダーのエントリーには、任意の `library` ブロックを指定できます。

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: PRIMARY_RD_TOKEN
    download_tokens: # Optional bandwidth fallback.
      - SECOND_RD_TOKEN
    library:
      source: local
      path: torrents/rd-local
```

`source` のデフォルトは `provider` です。`local` にすると、ポータブルな `.zurgtorrent` ファイルがメンバーシップを管理し、再生にはこのアカウントの認証情報が使われます。`path` のデフォルトは `torrents/<resolved-account-name>` で、`torrents/` の下に置く必要があります。同じソースディレクトリを、有効な 2 つのアカウントに割り当てることはできません。NZB プロバイダーは、既存の `nzbs/` ライブラリをそのまま使います。

この例では、両方の RD トークンが `torrents/rd-local/` にある 1 つのカタログを提供します。2 つ目のトークンには、プロバイダーエントリーもディレクトリも必要ありません。また、そのトークンのトレントライブラリはインポートされません。`download_tokens` は帯域幅フォールバックの動作をそのまま保ちます。すべてのダウンロードを 2 つ目のトークン経由にするわけではありません。2 つの別々の local プロバイダーエントリーを作ると、2 つの異なるカタログディレクトリをそれぞれ管理できます。両方が Real-Debrid でも同じです。認証情報は設定ファイルに残り、ポータブルファイルに書き出されることはありません。

オフラインでのエクスポート、`dump/` からの移行、共有の仕組み、再生の制限については、[ポータブルライブラリ](../guides/local-libraries.md) を参照してください。

#### オンラインアカウントをローカルライブラリへオフロードする {#offloading-an-online-account-into-a-local-library}

自分でカタログを持っている Real-Debrid または AllDebrid アカウント（`source` がない、または `source: provider` のもの）は、完成したリリースをローカルライブラリに移動し、アカウントから削除できます。これでスロットが空きます:

```yaml
providers:
  - name: rd
    type: realdebrid
    token: YOUR_RD_TOKEN
    library:
      offload_to: rd-local      # a local entry of the same type
      offload_after_mins: 30    # optional, 30 is the default

  - name: rd-local
    type: realdebrid
    token: YOUR_RD_TOKEN        # the same account
    library:
      source: local
```

| Key | Default | 意味 |
|---|---|---|
| `library.offload_to` | none | 同じ種類の、有効になっている `source: local` エントリーの名前。受け付けるのは `realdebrid` と `alldebrid` のアカウントだけです。これらのアカウントのリンクだけが、torrent を削除した後も使い続けられるためです。アカウント自身の名前は指定できません。 |
| `library.offload_after_mins` | `30` | リリースが自動で移動されるまでに、アカウント上で完成している状態が続いている必要がある時間です。zurg が完成を最初に確認した時点から数えるため、再起動すると待ち時間は最初からやり直しになります。`offload_to` が必要です。 |

リリースが移動されるのは、次の条件をすべて満たしたときだけです。すべてのファイルに、ほかのアカウントが引き換えられるリンクがあること。修復もダウンロードもされていないこと。qBittorrent エンドポイントの Sonarr や Radarr のジョブに、まだ一覧されていないこと。そして、移動してもフォルダー名と、そのリリースが入っているすべてのディレクトリが保たれること。フォルダーは元の場所に残ったままで、メディアサーバーのスキャンも開始されません。ダッシュボードのリリースページからは、`offload_to` の有無にかかわらず、1 つのリリースを手動で移動できます。手順の順番、どこかの手順が失敗したときの動き、共有トークンでのローカル再生がどう守られるかについては、[ポータブルライブラリ](../guides/local-libraries.md#offload-an-online-account-into-a-local-library) を参照してください。
