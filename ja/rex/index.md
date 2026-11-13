# rex

[rex](https://rex.debridmediamanager.com/ja/) は、公式の Plex アプリ向けのメディアサーバーで、ファイルは一切持ちません。ソースがライブラリの中身を rex に伝え、各ファイルを配信します。再生を押すと、rex がそのファイルをストリーミングします。rex は個人利用であれば無料です。[ソースコード](https://github.com/debridmediamanager/rex)は PolyForm Noncommercial ライセンスで公開されています。Linux、macOS、Windows で動作し、Linux 向けの Docker イメージ `ghcr.io/debridmediamanager/rex:nightly` としても提供されています（[自分のアプリで使う](any-source.md#run-rex-in-docker)、[zurg と使う](with-zurg.md#run-rex-in-docker)）。

- [rex for Android](android.md) は、パソコンなしでスマホ、タブレット、TV ボックス上で rex とそのアドオンを動かします。無料です。スポンサー向けには [zurg+rex](../zurg/guides/android.md) もあります。これはスマホ上で動く Plex サーバーで、デブリッドや Usenet のライブラリも rex に接続します。
- [rex の質問](faq.md) では、インストール前に知っておきたいことをまとめています。
- [自分のアプリで rex を使う](any-source.md) は、HTTP でファイルを配信し、rex のフィード API に対応したソースを設定する方法です。
- [Stremio アドオンで rex を使う](stremio.md) では、rex-stremio で rex にコンテンツを追加します。無料で、スポンサーは不要です。
- [zurg で rex を使う](with-zurg.md) では、zurg を通じてデブリッドアカウントまたは Usenet から rex にコンテンツを追加します。
- [rex でライブ TV](live-tv.md) は、rex-live-sports を使ってライブチャンネルとガイドを追加します。
- [rex で音楽](music.md) は、Plexamp と対応する Plex アプリ向けの音楽ライブラリを追加します。
- [Plex から rex へ移行](from-plex.md) は、rex を Plex と並べて、または Plex の代わりに動かす方法です。
- [家族や友人と rex を共有](sharing.md) では、一緒に見る人を招待する方法を説明します。
- [rex アドオンの作り方](addons.md) は、ホームビデオ、録画、Stremio カタログを rex に取り込みます。
- [アドオンのチュートリアル](addon-home-videos.md) では、1 つの Python ファイルで、ホームビデオ、音楽、IPTV のアドオンを完成まで作ります。
- [アドオンでさらに](addon-more.md) では、字幕、特典、チャプター、コレクション、プレイリストなどを追加します。
- [視聴履歴を持ち込む](import-watched.md) は、Plex から視聴状態、評価、再開位置をコピーします。
- [rex と Kometa](kometa.md) は、rex のライブラリにコレクションとポスターバッジを作ります。
- [プロバイダーからのダイレクトダウンロード](direct-download.md) では、Plex アプリがソースのリンクから直接ダウンロードできるようにします。これにより、rex を動かすマシンは映画のデータを持たずに済みます。
