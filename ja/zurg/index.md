# zurg

zurgは、デバッドのアカウントとUsenetのライブラリを1つの仮想フォルダにまとめます。ローカルに動画を保存することはありません。プレーヤーが要求するまで何も取得されないため、60 GBのリミックス動画がローカルのディスクを60 GB使うことはありません。

同じライブラリを見る4つの方法:

| エンドポイント | 用途 |
|---|---|
| `/dav/` | WebDAV。rcloneがマウントするもの |
| `/http/` | HTMLのディレクトリブラウザ |
| `/infuse/` | Infuseの癖に合わせたWebDAVのバリアント |
| `/strm/` | `.strm`ファイル内の署名付きURL。マウントではなくURLを求めるプレーヤー向け |

## セットアップ {#setup}

zurg を自分のマシンで動かしてみましょう。

- [Linux](setup/linux.md) — FUSE 3 と systemd による自動起動
- [Docker](setup/docker.md) — ホストから見えるマウントを持つ Linux ホスト
- [macOS](setup/macos.md) — macFUSE と launchd による自動起動
- [Windows](setup/windows.md) — WinFsp とドライブレターのタスク

## プロバイダー {#providers}

zurg をアカウントに接続します。
各ページでは、認証情報と `config.yml` の設定項目を説明しています。
例はすべて Docker を使っています。バイナリでインストールする場合も、設定項目は同じです。
コマンドについては [Setup](setup/index.md) を参照してください。

| ページ | 違う点 |
|---|---|
| [Real-Debrid](providers/realdebrid.md) | ファイル単位の選択、`__downloads__`、CDN ホストの選択、`.strm` 用の別トークン |
| [TorBox](providers/torbox.md) | ライブラリ更新ごとのリクエストは 1 回。帯域幅ではなく、同時アクティブスロットの上限で制限される |
| [AllDebrid](providers/alldebrid.md) | ファイル一覧は専用のエンドポイントから届くため、最初のスキャンでは少しずつ埋まっていく |
| [Premiumize](providers/premiumize.md) | 完了した転送と、クラウドに残ったファイルを、フォルダ構成ごと扱う |
| [Debrid-Link](providers/debridlink.md) | seedbox の一覧にはすべてのファイルが含まれ、キャッシュチェックはない |
| [Offcloud](providers/offcloud.md) | サイズは配信サーバーで確認し、フォルダパスはキャッシュされたメタデータから取得する |
| [Usenet](providers/usenet.md) | プロバイダー項目としての `nzb` タイプ。トークンは不要で、代わりに監視ディレクトリを使う |
| [TorBox limits](providers/torbox-limits.md) | TorBox のスロットリングの背景にある実測値と、zurg がそれに合わせてどうペース調整するか |
| [TorBox ニュースサーバー](providers/torbox-news-server.md) · [ElfHosted ニュースサーバー](providers/elfhosted-news-server.md) | 同梱の Usenet アカウントが通信上どういうものか |

[共通ページ](providers/index.md)では、Docker でアカウントを追加する 3 つの方法と、設定ローダーが適用するルールを説明しています。

## ガイド {#guides}

- [Usenet](guides/usenet.md) — `nzb` バックエンドのエンドツーエンドの手順です。ニュースアカウント、NZB、マウント、Plex まで扱います
- [Sonarr & Radarr for Usenet](guides/sonarr-radarr.md) — \*arr は zurg の回答を SABnzbd として受け取るので、インポートはダウンロードではなく名前の変更で済みます
- [Sonarr & Radarr for torrents](guides/sonarr-radarr-torrents.md) — 同じ内容ですが、zurg が qBittorrent として応答します。Prowlarr も対象です
- [zurg searches for Sonarr & Radarr](guides/sonarr-radarr-fetch.md)。Radarr と Sonarr はリストを保持し、リリースの検索と配置は zurg が行います。どちらにもインデクサーやダウンロードクライアントは不要です
- [`__magic__`](guides/magic.md) — レイアウトが保存される唯一のディレクトリで、そのため自分で整理できます。ライブラリはタイトルごとに Kodi と Plex 用に整理されます
- [Renaming](guides/renaming.md) — ライブラリのどこでもリリースやファイルの名前を変更できます。移動は拒否され、その理由がページに表示されます
- [Plex](guides/plex.md) — zurg が Plex トークンで何をするか、そして意図的に何をしないか
- [Jellyfin](guides/jellyfin.md) — Jellyfin 向けの同じ内容です
- [rex with zurg](../rex/with-zurg.md) — ファイルを持たず、debrid アカウントから zurg が中身を入れる Plex アプリ向けメディアサーバーです。詳しくは [rex](../rex/index.md) をご覧ください
- [The Stremio addon](guides/stremio.md) — 自分のインデクサーを検索し、Usenet バックエンドから直接再生する Stremio です
- [Watchlist and Seerr](guides/acquisition.md) は、自分のインデクサー経由で依頼したものを取得します
- [Plex watchlist](guides/plex-watchlist.md) は、その Plex 側の機能です
- [DMM wanted list](guides/dmm-wanted.md) は、DMM で Want を押したものを取得します。ほかに設定は必要ありません
- [Local libraries](guides/local-libraries.md) は、共有のリリース一覧を自分のアカウント経由で再生します
- [Android と Google TV](guides/android.md) は、スマートフォンや TV ボックスでライブラリ全体を動かします

## 移行 {#migrating}

移行: 既存のライブラリを、再ダウンロードも再スキャンもせずに zurg へ移します。

- [AltMount からの移行](migrate/altmount.md)
- [decypharr からの移行](migrate/decypharr.md)
- [InfiniDysk からの移行](migrate/infinidysk.md)
- [nzbdav からの移行](migrate/nzbdav.md)
- [streamnzb からの移行](migrate/streamnzb.md)

## リファレンス {#reference}

- [Configuration](reference/config.md) — `config.yml` のすべてのオプション
- [Command line](reference/cli.md) では zurg のバイナリが受け付けるすべてのコマンドとフラグを一覧できます
- [Outbound identity](reference/outbound-identity.md) では、zurg が呼び出すサービスに自分自身について何を伝えるかを説明しています
- [MCP server](reference/mcp.md) では、AI エージェントが Model Context Protocol 経由で zurg を操作する方法を説明しています
- [Tags](reference/tags.md) — torrent にどのタグが付けられ、その理由は何か
- [Changelog](reference/changelog.md) — いつ何が変わったか

## 内部構造 {#internals}

zurg の構成、計測結果、そして扱いにくい部分の設計メモです。

- [アーキテクチャ](internals/architecture.md) — 全体の構造と、壊れやすい不変条件
- [Debrid のベースライン](internals/debrid-baseline.md) — zurg のコストと、RD、AD、TorBox across での体感速度
- [Torrent のライフサイクル](internals/torrent-lifecycle.md) — 取得の実行中に各アカウントが実際に返す情報（ライブで計測）
- [SABnzbd クライアント仕様](internals/sabnzbd-client-contract.md) — Sonarr と Radarr が期待する正確な形式
- [Plex のゴミ掃除](internals/plex-trash-sweep.md) · [ストリームのタイムアウトの回帰](internals/stream-timeout-regression.md) · [ディレクトリ設定の UI/UX](internals/uiux.md)
- [E2E テスト](internals/e2e-test.md) · [Real-Debrid API のメモ](internals/realdebrid-behavior.md)
- [qBittorrent クライアント仕様](internals/qbittorrent-client-contract.md) · [永続キャッシュ](internals/persistent-caches.md)
- [命名規則](internals/naming.md) · [rclone の移動拒否](internals/rclone-move-refusal.md)

---

zurg はスポンサー向けに配布しています: [GitHub Releases](https://github.com/debridmediamanager/zurg/releases)
· [Sponsor](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP)
