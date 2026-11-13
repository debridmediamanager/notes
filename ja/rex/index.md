# rex

[rex](https://rex.debridmediamanager.com/ja/) は、公式の Plex アプリ向けのメディアサーバーです。ファイルは一切持ちません。ソースがライブラリの中身を rex に伝え、各ファイルを配信します。再生ボタンを押すと、rex がそのファイルをストリーミングします。rex は個人利用なら無料です。[ソースコード](https://github.com/debridmediamanager/rex) は PolyForm Noncommercial ライセンスで公開されています。Linux、macOS、Windows で動作し、Linux 用の Docker イメージ `ghcr.io/debridmediamanager/rex:nightly` としても提供されています（[自分のアプリで使う](any-source.md#run-rex-in-docker)、[zurg で使う](with-zurg.md#run-rex-in-docker)）。

- [Android 版 rex](android.md) は、パソコンなしでスマホ、タブレット、TV ボックスの上で rex とそのアドオンを動かせます。無料です
- [rex のよくある質問](faq.md) では、インストール前に知っておきたいことをまとめています
- [自分のアプリで rex を使う](any-source.md) は、HTTP でファイルを配信し、rex のフィード API に対応したソースを設定します
- [Stremio のアドオンで rex を使う](stremio.md) は rex-stremio で rex に中身を入れます。無料で、スポンサーも不要です
- [zurg で rex を使う](with-zurg.md) は、zurg を通じてデブリッドのアカウントや Usenet から rex に中身を入れます
- [rex でライブ TV を見る](live-tv.md) は rex-live-sports を使って、ライブチャンネルと番組表を追加します
- [rex で音楽を聴く](music.md) は、Plexamp や対応する Plex アプリ向けの音楽ライブラリを追加します
- [Plex から rex に移行する](from-plex.md) は、Plex と並べて、または Plex の代わりに rex を動かす方法です
- [家族や友人と rex を共有する](sharing.md) では、一緒に見る人を招待できます
- [rex のアドオンを作る](addons.md) は、ホームビデオや録画、Stremio のカタログを rex に取り込みます
- [アドオンのチュートリアル](addon-home-videos.md) では、1 つの Python ファイルでホームビデオ、音楽、IPTV のアドオンを一通り作ります
- [アドオンでさらにできること](addon-more.md) は、字幕、エキストラ、チャプター、コレクション、プレイリストなどを追加します
- [視聴履歴を持ってくる](import-watched.md) は、Plex から視聴状況、評価、再生位置をコピーします
- [rex で Kometa を使う](kometa.md) は、rex のライブラリにコレクションやポスターのバッジを作ります
- [プロバイダーからアプリでダウンロードする](direct-download.md) は、Plex アプリがソースのリンクから直接ダウンロードできるようにします。そのため rex のマシンは映画を保持しません
