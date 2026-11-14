# 各コンポーネントの役割 {#what-each-piece-does}

名前だけではそれぞれの役割が分かりにくいので、1行ずつ説明します。**For sponsors** と書かれていないものはすべて無料です。必要なものを探すには、[構成の選び方](choose-your-setup.md) を使ってください。

## 3つのプロジェクト {#the-three-projects}

| 名前 | 何をするか |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | リリースを探して、debrid アカウントに追加するためのウェブサイトです。Usenet と Easynews も検索できます |
| [zurg](../zurg/index.md) | すべての debrid アカウントと Usenet を 1 つのライブラリにまとめます。Plex、Jellyfin、Emby はフォルダとして読み込み、Infuse と Kodi は WebDAV 経由で読み込みます。rex はこれを直接受け取ります。最新ビルドはスポンサー向けです |
| [rex](../rex/index.md) | 自分のファイルを持たない、Plex アプリ向けのメディアサーバーです。zurg またはアドオンが、何があるかを教えてくれます。個人利用は無料です |

## DMMから直接視聴する {#watching-straight-from-dmm}

サーバーは不要です。どれも必要ありません。

| 名前 | 機能 |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | Real-Debrid、AllDebrid、TorBox、Premiumize、Debrid-Link、Offcloud、Easynews のアカウントから、リリースを再生する Stremio アドオンです。Nuvio でも使えます |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Kodi の中から、debrid または Easynews のアカウントを閲覧、検索して再生できます |
| DMM Watch | DMM にあるボタンで、VLC や Infuse など、お好みのプレイヤーでファイルを開けます |

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
| リリース | 映画、エピソード、シーズンの1つの公開版です。通常、1つのタイトルには画質の違うものが複数あります |
| Debrid provider | 代わりにトレントをダウンロードし、ストリーミング再生できるようにする有料サービスです。Real-Debrid、AllDebrid、TorBox、Premiumize、Offcloud、Debrid-Link があります |
| キャッシュ済み | プロバイダーがすでにそのリリースを持っているので、すぐに再生できます |
| Usenet | リリースを入手できるもう1つの場所です。自分の Usenet アカウントを使うか、TorBox Pro や Easynews に任せるか、DMM から結果を Real-Debrid に送ることができます |
| Easynews | 独自の検索機能を持つ有料の Usenet サービスです。ファイルをウェブ経由で直接再生できます |
| NZB | Usenet のリリースの場所を示す小さなファイルです。トレントにとっての torrent ファイルのような役割です |
| インデクサー | リリースを検索するサイトです。Sonarr と Radarr は、これを使ってタイトルを探します |
| Sonarr、Radarr、Prowlarr | タイトルを代わりに取得してくれるアプリです。Sonarr はシ리ーズ、Radarr は映画を担当します。Prowlarr は、それらのインデクサーを1か所にまとめて管理します |
| Seerr | 家族や友人向けのリクエストサイトです。Overseerr や Jellyseerr も同じ仕組みで動きます |
| Stremio、Nuvio、Kodi | メディアプレーヤーのアプリです。アドオンが再生するものを提供します。Nuvio は Stremio のアドオンに対応しています |
| DMM API キー | gatekeeper から発行されるスポンサー向けのキーです。ガイドで指定された場所に貼り付けてください。パスワードと同じように、外に漏らさないようにしてください |
| Nightly | zurg または rex の最新ビルドで、毎晩作られます。zurg の Nightly はスポンサー向けです |
| WebDAV | ウェブ経由でファイルを共有する方法です。Infuse、Kodi、多くのテレビ用プレーヤーで開けます |
| マウント | zurg のフォルダーをローカルドライブのように見せるので、Plex、Jellyfin、Emby がスキャンできるようになります |
| rclone | zurg がマウントを作るのに使うツールです。zurg のセットアップが自動で用意してくれます |
| `.strm` | 動画の代わりにリンクを持つ小さなファイルです。Kodi のようなプレーヤー向けです |
| ソース | rex に何があるかを伝え、ファイルを配信するものすべてを指します。zurg、rex-stremio、アドオンなどが該当します |
| Claim | rex を Plex アカウントに紐付けることです。これにより、rex がタイトルやポスターを表示でき、Plex のアプリから見つけられるようになります |
| Plex Media Server と Plex アプリ | サーバーはあなたのライブラリを保持します。テレビやスマートフォンのアプリがそれを再生します。rex が置き換えるのはサーバーであって、アプリではありません |
