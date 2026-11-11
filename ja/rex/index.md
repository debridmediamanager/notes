# rex

[rex](https://rex.debridmediamanager.com/ja/) は、公式の Plex アプリ向けのメディアサーバーで、ファイルは一切持ちません。ソースがライブラリに何があるかを rex に伝え、各ファイルを配信します。再生を押すと、rex がそのファイルをストリーミングします。rex は個人利用であれば無料です。[ソースコード](https://github.com/debridmediamanager/rex)は PolyForm Noncommercial ライセンスで公開されています。Linux、macOS、Windows で動作するほか、Linux 向け Docker イメージ `ghcr.io/debridmediamanager/rex:nightly` としても提供されています（[自分のアプリで使う](any-source.md#run-rex-in-docker)、[zurg で使う](with-zurg.md#run-rex-in-docker)）。

- [rex のよくある質問](faq.md)：インストール前に知っておきたいことをまとめています
- [自分のアプリで rex を使う](any-source.md)：HTTP でファイルを配信し、rex のフィード API に対応したソースを設定します
- [Stremio アドオンで rex を使う](stremio.md)：rex-stremio で rex にコンテンツを追加します。無料で、スポンサーも不要です
- [zurg で rex を使う](with-zurg.md)：zurg を通じて、デビリッドのアカウントや Usenet から rex にコンテンツを追加します
- [rex でライブ TV を見る](live-tv.md)：rex-live-sports を使ってライブチャンネルとガイドを追加します
- [rex で音楽を聴く](music.md)：Plexamp や対応する Plex アプリ向けに音楽ライブラリを追加します
- [Plex から rex に移行する](from-plex.md)：Plex と並べて、または Plex の代わりに rex を動かします
- [rex を家族や友達と共有する](sharing.md)：一緒に見る人を招待します
- [rex 用アドオンを作る](addons.md)：ホームビデオ、録画、Stremio のカタログを rex に取り込みます
- [アドオンのチュートリアル](addon-home-videos.md)：ホームビデオ、音楽、IPTV のアドオンを 1 つの Python ファイルで完成させます
- [アドオンのその他の機能](addon-more.md)：字幕、エクストラ、チャプター、コレクション、プレイリストなどを追加します
- [視聴履歴を取り込む](import-watched.md)：視聴状態、評価、再開位置を Plex からコピーします
- [rex で Kometa を使う](kometa.md)：rex のライブラリにコレクションやポスターバッジを作成します
- [プロバイダーからアプリでダウンロードする](direct-download.md)：Plex アプリがソースのリンクから直接ダウンロードできるようにします。rex を動かすマシンに映画を置く必要はありません
