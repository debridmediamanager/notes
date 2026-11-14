# ガイド {#guides}

すべてのガイドを、プロジェクトごとにまとめています。

## 一般 {#general}

- [Choose your setup](choose-your-setup.md): ルートマップと、DMM、zurg、rex、Kodi、Stremio、Nuvio、Jellyfin/Emby プラグインをいつ使うか
- [What each piece does](glossary.md): DMM、zurg、rex の各パーツと、ガイドに出てくる用語の一行説明
- ["Torrent is being downloaded to debrid"](torrent-being-downloaded-to-debrid.md): Stremio で表示される緑の画面の意味と、その対処法
- [Your Real-Debrid API token](real-debrid-api-token.md): 取得場所、DMM と zurg での設定場所、`bad_token` などのエラーの意味
- [Usenet for beginners](usenet-for-beginners.md): プロバイダー、インデクサー、NZB とは何か、何を購入する必要があるか、zurg と DMM がどう関わるか
- [A Real-Debrid library in Plex](real-debrid-plex.md): Plex Media Server での zurg の `movies` と `shows` フォルダー（システムごと）と、よくある問題
- [Getting help](remote-help.md): zurg と rex のサポートの受け方、質問先、何を伝えればよいか、スポンサー向けのリモートサポート
- [What a sponsorship gives you](sponsorship.md): 特典の一覧と各設定場所、または DMM 向け特典をリクエストボードで獲得する方法

## DMM

- [DMMの概要と使い方](../dmm/index.md): サインイン、検索、リリースのボタン、ライブラリについて
- [StremioでのDMM](../dmm/stremio.md): DMM Castアドオンを使ってStremioで視聴する方法と、うまくいかないときの対処法
- [ハッシュリスト](../dmm/hashlists.md): 共有リストの探し方、デブリッドライブラリへの追加、自分のリストの共有
- [DMMでのTorBox](../dmm/torbox.md): サインイン、各プランでできること、Instant TB、Cast、TorBox ProへのUsenetリリース送信
- [SafariでのDMMボタン](../dmm/safari.md): Mac、iPhone、iPadでユーザースクリプトとして使うブラウザ拡張機能
- [DMM経由のSeerr](../dmm/seerr.md)
- [DMMの希望リスト](../zurg/guides/dmm-wanted.md): **Want**を押した作品をzurgが取得します

## zurg

- [Usenet](../zurg/guides/usenet.md)
- [Usenet向けのSonarr & Radarr](../zurg/guides/sonarr-radarr.md)
- [torrent向けのSonarr & Radarr](../zurg/guides/sonarr-radarr-torrents.md)
- [Sonarr & Radarrのリスト](../zurg/guides/import-lists.md)
- [Sonarr & Radarr向けのzurg検索](../zurg/guides/sonarr-radarr-fetch.md)
- [Bazarrで字幕](../zurg/guides/subtitles.md)
- [Whisparr](../zurg/guides/whisparr.md)
- [\_\_magic\_\_](../zurg/guides/magic.md)
- [名前の変更](../zurg/guides/renaming.md)
- [Plex](../zurg/guides/plex.md)
- [1つのDocker Composeファイル](../zurg/guides/docker-compose.md): zurg、Plex Media Server、rexを1台のLinuxマシンで
- [Jellyfin](../zurg/guides/jellyfin.md)
- [Stremioアドオン](../zurg/guides/stremio.md)
- [ウォッチリストとSeerr](../zurg/guides/acquisition.md)
- [Plexのウォッチリスト](../zurg/guides/plex-watchlist.md)
- [DMMのwantedリスト](../zurg/guides/dmm-wanted.md)
- [ローカルライブラリ](../zurg/guides/local-libraries.md)
- [AndroidとGoogle TV](../zurg/guides/android.md)
- [他のツールからの移行](../zurg/migrate/index.md)

## rex

- [rexのよくある質問](../rex/faq.md): インストール前に
- [rexを自分のアプリで使う](../rex/any-source.md)
- [rexをStremioのアドオンと使う](../rex/stremio.md)
- [rexをzurgと使う](../rex/with-zurg.md)
- [Android向けのrex](../rex/android.md): 無料です。スポンサーの方は、[zurg+rex](../zurg/guides/android.md)を使うと、スマホ上のPlexサーバーからデブリッドとUsenetのライブラリもrexに接続できます
- [rexでライブTV](../rex/live-tv.md)
- [rexで音楽](../rex/music.md)
- [PlexからrexへのLWrite移行](../rex/from-plex.md)
- [rexを家族や友人と共有](../rex/sharing.md)
- [rexアドオンの作成](../rex/addons.md)
  - [チュートリアル: ホームビデオのアドオン](../rex/addon-home-videos.md)
  - [チュートリアル: 音楽のアドオン](../rex/addon-music.md)
  - [チュートリアル: IPTVのアドオン](../rex/addon-iptv.md)
  - [アドオンのその他の機能](../rex/addon-more.md)
- [視聴履歴を取り込む](../rex/import-watched.md)
- [rexでKometa](../rex/kometa.md)
- [アプリがプロバイダーからダウンロード](../rex/direct-download.md)
