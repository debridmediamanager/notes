# 各コンポーネントの役割 {#what-each-piece-does}

名前だけでは何をするものか分かりにくいので、それぞれの役割を一行ずつ説明します。必要なものを探すには、[Choose your setup](choose-your-setup.md) を使ってください。

## 3つのプロジェクト {#the-three-projects}

| 名前 | 何をするもの |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | リリースを探して、あなたのデバッグアカウントに追加するためのウェブサイトです。Usenet と Easynews も検索します。無料です |
| [zurg](../zurg/index.md) | すべてのデバッグアカウントと Usenet を 1 つのフォルダにまとめます。Plex、Jellyfin、Emby、Infuse、rex がそのフォルダを普通のドライブとして読み込みます。スポンサー向けです |
| [rex](../rex/index.md) | 自分ではファイルを持たないメディアサーバーです。ソースが何を持っているかを教えてくれて、すべての Plex アプリで再生できます。個人利用は無料です |

## DMMから直接視聴する {#watching-straight-from-dmm}

サーバーは一切不要です。

| 名前 | 機能 |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio/) | デブリッドまたは Easynews アカウントのリリースを再生する Stremio アドオン |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Kodi 内で、デブリッドまたは Easynews アカウントを閲覧、検索、再生できます |
| DMM Watch | DMM のボタンで、VLC や Infuse などお使いのプレーヤーでファイルを開けます |
| [DMM Music](https://debridmediamanager.com/music/) | ブラウザで Real-Debrid から音楽を再生、ダウンロードできます |

## rexにフィードする {#feeding-rex}

| Name | What it does |
|---|---|
| [rex-stremio](../rex/stremio.md) | Verwandelt deine Stremio-Addons in rex-Bibliotheken, damit sie in Plex-Apps abgespielt werden. Kostenlos |
| [rex addons](../rex/addons.md) | Kleine Programme, die rex etwas zum Abspielen geben: YouTube, Spotify, IPTV, Heimvideos oder was du selbst schreibst |
| [rex for Android](../rex/android.md) | rex und seine Addons auf einem Android-Handy oder einer TV-Box, ohne Computer. Kostenlos. Für deine Debrid- und Usenet-Bibliothek nutzen Sponsoren zurg+rex |
| [zurg+rex for Android](../zurg/guides/android.md) | Ein Plex-Server auf deinem Handy: zurg und rex zusammen auf einem Android-Gerät. Für Sponsoren |

## JellyfinとEmbyの中で {#inside-jellyfin-and-emby}

| 名前 | 機能 |
|---|---|
| [RD, AD, TB, PM, OC and DL zurg](https://debridmediamanager.com/jellyfin) | デブリッドプロバイダーごとに1つのプラグインです。zurgアプリやマウントなしで、デブリッドのライブラリがJellyfinや[Emby](https://debridmediamanager.com/emby)に表示されます。スポンサー向け |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | 自分のUsenetアカウント経由でNZBをストリーミングするJellyfinプラグインです。スポンサー向け |

## 自動でタイトルを追加する {#adding-titles-for-you}

| Name | What it does |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | DMM で **Want** を押すと、zurg が取得します。新しいエピソードも含みます。スポンサー向け |
| [Seerr through DMM](../dmm/seerr.md) | Seerr の家族からのリクエストが Wanted リストに届きます。スポンサー向け |
| [Torznab and Newznab](https://debridmediamanager.com/torznab) | DMM を Sonarr、Radarr、Prowlarr のインデクサーとして使い、zurg をダウンロードクライアントにします。スポンサー向け |
| [zurg's Stremio addon](../zurg/guides/stremio.md) | Stremio で再生を押すと Usenet を検索し、zurg 経由でストリーミングします |
| [`__magic__`](../zurg/guides/magic.md) | 自分で整理する zurg のフォルダ。または Sonarr と Radarr に整理させることもできます |

## DMMのその他の機能 {#the-rest-of-dmm}

| Name | What it does |
|---|---|
| [リクエストボード](https://debridmediamanager.com/requests) | Real-Debrid にないリリースをリクエストできます。別の DMM ユーザーがそれをあなたのライブラリに移してくれます。リクエストに応えると DMM スポンサー特典がもらえます |
| [ハッシュリスト](https://debridmediamanager.com/hashlists) | リリースのリストを共有して、他の人が自分のアカウントに追加できるようにします |
| [ブラウザ拡張機能](../dmm/safari.md) | 映画やテレビのサイトと magnet リンクの横に DMM のボタンを追加します |
| [スポンサーページ](https://gatekeeper.debridmediamanager.com) | スポンサーになったり、Patreon または GitHub Sponsors の支援を連携したりできる場所です。[スポンサーになると得られるもの](sponsorship.md) |

## ガイドに出てくる用語 {#words-youll-see-in-the-guides}

| 用語 | 意味 |
|---|---|
| Debrid provider | トレントを代わりにダウンロードして、ストリーミングできるようにしてくれる有料サービスです。Real-Debrid、AllDebrid、TorBox、Premiumize、Offcloud、Debrid-Link などがあります |
| Cached | プロバイダーがすでにそのリリースを持っているので、すぐに再生できます |
| Usenet | リリースを入手するもう一つの方法です。Usenetプロバイダーのアカウントが必要です。代わりにやってくれるTorBox Proもあります |
| NZB | Usenetのリリースの場所を示す小さなファイルです。トレントファイルがトレントにとってそうであるのと同じです |
| Indexer | リリースを検索するサイトです。SonarrやRadarrはこれを使って探します |
| WebDAV | Web経由でファイルを共有する方法です。Infuse、Kodi、多くのTVプレーヤーで開けます |
| Mount | zurgのフォルダーをローカルドライブのように見せて、Plex、Jellyfin、Emby がスキャンできるようにします |
| Plex Media Server vs Plex apps | サーバーはライブラリを保持します。テレビやスマホのアプリがそれを再生します。rexが置き換えるのはサーバーで、アプリではありません |
