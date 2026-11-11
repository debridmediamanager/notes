# 内部構造 {#internals}

zurg の作りかた。どのくらいの性能で計測したか。扱いにくい部分の設計メモ。
コードを変更しようとしている人向けに書いています。
zurg を動かすだけなら、ここの内容は必要ありません。

## 全体の構成 {#the-shape-of-it}

| ページ | 内容 |
|---|---|
| [Architecture](architecture.md) | 全体の構造と、壊れやすい不変条件。ここから読んでください。 |
| [Naming](naming.md) | リリースとそのファイルが、マウントに表示される名前を得るまでの仕組み。 |
| [Persistent caches](persistent-caches.md) | 再起動をまたいでディスクに保存されるものと、そのコスト。 |
| [Directory config UI/UX](uiux.md) | ディレクトリエディターの背後にある設計評価。 |

## 計測した内容 {#what-was-measured}

| ページ | 内容 |
|---|---|
| [Debrid baseline](debrid-baseline.md) | zurg のコストと、Real-Debrid、AllDebrid、TorBox での体感速度。 |
| [Torrent lifecycle](torrent-lifecycle.md) | グラブの実行中に各アカウントが実際に報告する内容をライブで記録したもの。 |
| [Real-Debrid API notes](realdebrid-behavior.md) | リンクの仕様、ファイル選択、cached が実際に意味するもの。 |

## zurg が満たすべき契約 {#contracts-zurg-has-to-satisfy}

| ページ | 内容 |
|---|---|
| [SABnzbd クライアントの契約](sabnzbd-client-contract.md) | Sonarr と Radarr が SABnzbd に期待する正確な形式です。 |
| [qBittorrent クライアントの契約](qbittorrent-client-contract.md) | 同じ内容を qBittorrent 向けにまとめたものです。 |
| [plex_api.json](../../internals/plex_api.json) | zurg が使っている生の Plex API の範囲です。1.2 MB。 |

## うまくいかなかったこと {#things-that-went-wrong}

| Page | What it holds |
|---|---|
| [Plexのゴミ箱掃除](plex-trash-sweep.md) | 掃除の対象を、zurg自身が壊れていると判断しているものに合わせること。 |
| [ストリームのタイムアウト回帰](stream-timeout-regression.md) | プロキシ経由のストリームが、長い読み取りに耐えられなくなった問題。 |
| [rcloneのMOVE拒否](rclone-move-refusal.md) | バックエンドがMOVEを拒否した後に空のインポートが発生した問題と、そのパッチ。 |

## テスト {#testing}

- [E2E テスト](e2e-test.md) では、E2E スイートが何を検証するか、また実行にどれだけのコストがかかるかを説明しています。

特定のサービスが何をするのか、また何に制限があるのかについては、ここではなく [Providers](../providers/index.md) にまとめています。
