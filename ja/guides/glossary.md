# 各コンポーネントの役割 {#what-each-piece-does}

名前だけではそれぞれの役割が分かりにくいので、1行ずつ説明します。**For sponsors** と書かれていないものはすべて無料です。必要なものを探すには、[構成の選び方](choose-your-setup.md) を使ってください。

## 3つのプロジェクト {#the-three-projects}

| 名前 | 何をするか |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | リリースを探して、debrid アカウントに追加するためのウェブサイトです。Usenet と Easynews も検索できます |
| [zurg](../zurg/index.md) | すべての debrid アカウントと Usenet を 1 つのライブラリにまとめます。Plex、Jellyfin、Emby はフォルダとして読み込み、Infuse と Kodi は WebDAV 経由で読み込みます。rex はこれを直接受け取ります。最新ビルドはスポンサー向けです |
| [rex](../rex/index.md) | 自分のファイルを持たない、Plex アプリ向けのメディアサーバーです。zurg またはアドオンが、何があるかを教えてくれます。個人利用は無料です |

## DMMから直接視聴する {#watching-straight-from-dmm}

サーバーは一切不要です。

| 名前 | 機能 |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | デブリッドまたは Easynews のアカウントにあるリリースを再生する Stremio アドオン |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Kodi 内で、デブリッドまたは Easynews のアカウントを閲覧、検索、再生できます |
| DMM Watch | DMM のボタンで、VLC や Infuse など、お使いのプレーヤーでファイルを開けます |
| [DMM Music](https://debridmediamanager.com/music) | ブラウザで Real-Debrid の音楽を再生・ダウンロードできます |

## rexにフィードする {#feeding-rex}

| 名前 | 内容 |
|---|---|
| [rex-stremio](../rex/stremio.md) | Stremioのアドオンをrexのライブラリに変えて、Plexアプリで再生できるようにします |
| [rex アドオン](../rex/addons.md) | rexに再生するものを渡す小さなプログラムです。YouTube、Spotify、IPTV、ホームビデオ、自分で書いたものなどが使えます |
| [rex-live-sports](../rex/live-tv.md) | スポーツのライブチャンネルとガイドを、PlexアプリのLive TVに表示するrexアドオンです |
| [rex-direct](../rex/any-source.md#rex-direct) | rexに専用の安全なアドレスを付けるので、家の外からでもPlexアプリで接続できます |
| [Android向けrex](../rex/android.md) | AndroidのスマホやTVボックスでrexとそのアドオンを動かします。パソコンは不要です |
| [Android向けzurg+rex](../zurg/guides/android.md) | スマホ上のPlexサーバーです。1台のAndroid端末でzurgとrexを一緒に動かし、debridとUsenetのライブラリを使えます。スポンサー向けです |

## JellyfinとEmbyの中で {#inside-jellyfin-and-emby}

| 名前 | 役割 |
|---|---|
| [Debrid plugins](https://debridmediamanager.com/jellyfin) (RD zurg, AD zurg, TB zurg, PM zurg, OC zurg, DL zurg) | デブリッドのプロバイダーごとに 1 つずつのプラグインです。対象は Real-Debrid、AllDebrid、TorBox、Premiumize、Offcloud、Debrid-Link です。zurg アプリもマウントも使わずに、デブリッドのライブラリを Jellyfin や [Emby](https://debridmediamanager.com/emby) に表示できます。スポンサー向けです。 |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | 自分の Usenet アカウント経由で NZB をストリーミングする Jellyfin プラグインです。スポンサー向けです。 |

## 自動でタイトルを追加する {#adding-titles-for-you}

| Name | What it does |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Drücke **Want** in DMM und dein zurg holt es, inklusive neuer Folgen. Für Sponsoren |
| [Seerr through DMM](../dmm/seerr.md) | Anfragen der Familie in Seerr landen auf deiner Wanted-Liste. Für Sponsoren |
| [Torznab](https://debridmediamanager.com/torznab) und [Newznab](https://debridmediamanager.com/newznab) | DMM als Indexer für Sonarr, Radarr und Prowlarr. Für Sponsoren |
| zurg als Download-Client | zurg antwortet Sonarr und Radarr als qBittorrent für [Torrents](../zurg/guides/sonarr-radarr-torrents.md) und als SABnzbd für [Usenet](../zurg/guides/sonarr-radarr.md), sodass du keines von beiden selbst betreiben musst. Für Sponsoren |
| [zurgs Stremio-Addon](../zurg/guides/stremio.md) | Sucht auf Usenet, wenn du in Stremio auf Play drückst, und streamt es über zurg. Für Sponsoren |
| [`__magic__`](../zurg/guides/magic.md) | Ein zurg-Ordner, den du selbst einrichtest oder von Sonarr und Radarr einrichten lässt. Für Sponsoren |

## DMMのその他の機能 {#the-rest-of-dmm}

| 名前 | 機能 |
|---|---|
| Usenet タブ | Usenet のリリースを、Usenet アカウントなしで Real-Debrid ライブラリに送れます。スポンサーが優先され、1日あたりの割り当ても多くなります |
| [Request board](https://debridmediamanager.com/requests) | Real-Debrid にないリリースをリクエストできます。別の DMM ユーザーがそれをあなたのライブラリに移してくれます。リクエストを 10 件満たすと、DMM スポンサー特典が 7 日間もらえます |
| [Hash lists](https://debridmediamanager.com/hashlists) | リリースのリストを共有して、ほかの人が自分のアカウントに追加できるようにします |
| ブラウザ拡張機能 | 映画や TV のサイトと magnet リンクの横に DMM ボタンを追加します。[Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm)、[Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/)、[Safari](../dmm/safari.md) に対応しています |
| [gatekeeper](https://gatekeeper.debridmediamanager.com) | スポンサーサイトです。ここでスポンサーになり、Patreon または GitHub Sponsors の支援を連携すると、DMM API キーが取得できます。[スポンサーになるとできること](sponsorship.md) |

## ガイドに出てくる用語 {#words-youll-see-in-the-guides}

| 用語 | 意味 |
|---|---|
| Release | 映画、エピソード、シーズンのうち、誰かが公開した1つのコピーです。1つのタイトルには、画質の違うリリースが普通たくさんあります |
| Debrid provider | 代わりにトレントをダウンロードして、ストリーミングできるようにしてくれる有料サービスです。Real-Debrid、AllDebrid、TorBox、Premiumize、Offcloud、Debrid-Link などがあります |
| Cached | プロバイダーがすでにそのリリースを持っているので、すぐに再生できる状態です |
| Usenet | リリースを入手できるもう1つの場所です。自分の Usenet アカウントを使うか、TorBox Pro や Easynews に任せるか、DMM から Real-Debrid に結果を送ってもらえます |
| Easynews | 独自の検索機能を持つ有料の Usenet サービスです。ファイルをウェブ経由で直接再生できます |
| NZB | Usenet リリースの場所を示す小さなファイルです。トレントにおけるトレントファイルのような役割を果たします |
| Indexer | リリースを検索するためのサイトです。Sonarr と Radarr は、これを使って目的のものを探します |
| Sonarr, Radarr and Prowlarr | 作品を自動で取得してくれるアプリです。Sonarr はドラマやアニメ、Radarr は映画向けです。Prowlarr は、それらのインデクサーを1か所にまとめて管理します |
| Seerr | 家族や友人がリクエストを送るためのサイトです。Overseerr や Jellyseerr も同じ仕組みで動きます |
| Stremio and Kodi | メディアプレーヤーのアプリです。アドオンを追加すると、再生できるものが増えます |
| DMM API key | gatekeeper が発行するスポンサー向けのキーです。ガイドで指定された場所に貼り付けてください。パスワードと同じように、外部に漏らさないようにしてください |
| Nightly | zurg または rex の最新ビルドで、毎晩作られます。zurg のナイトリービルドはスポンサー向けです |
| WebDAV | ファイルをウェブ経由で共有する仕組みです。Infuse、Kodi、多くのテレビ向けプレーヤーで開くことができます |
| Mount | zurg のフォルダーをローカルドライブのように見せるので、Plex、Jellyfin、Emby でスキャンできるようになります |
| rclone | zurg がマウントを作るために使うツールです。zurg のセットアップで自動的に用意されます |
| `.strm` | 動画の代わりにリンクを保存する小さなファイルです。Kodi などのプレーヤーで使われます |
| Source | rex に対して、何を持っているかを伝えてファイルを配信するものすべてを指します。zurg、rex-stremio、アドオンなどが該当します |
| Claim | rex を Plex アカウントに紐づける作業です。これによって、rex がタイトルやポスターを表示できるようになり、Plex アプリからも見つけられるようになります |
| Plex Media Server と Plex アプリ の違い | サーバーはライブラリを保存する場所です。テレビやスマートフォンのアプリは、そのライブラリを再生します。rex が置き換えるのはサーバーで、アプリではありません |
