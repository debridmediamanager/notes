# 「Torrent is being downloaded to debrid」が意味すること {#what-torrent-is-being-downloaded-to-debrid-means}

緑色の **Torrent is being downloaded to debrid...** 画面は、選んだリリースがまだお使いの debrid サービスにキャッシュされていないことを意味します。その結果を表示している Stremio のアドオン Torrentio が、ちょうどそのトレントを お使いの Real-Debrid、TorBox などの debrid アカウントに追加したところで、サービスが今それをダウンロードしています。ダウンロードが終われば、同じ結果が他のものと同じように再生できます。

## 対処方法 {#what-to-do}

1. **キャッシュ済みの結果を選びましょう。** Torrentio の一覧で `[RD+]`(または `[TB+]`、`[AD+]`、`[PM+]`)が付いているものはキャッシュ済みなので、すぐ再生できます。`[RD download]` はキャッシュされていません。これらはキャッシュ済みの結果の後に並んでいます。
2. **または数分待ってから、同じ結果をもう一度押してください。** まだダウンロード中だと、また緑の画面が出ます。完了すると再生されます。
3. **ダウンロードの進み具合を確認できます。** [Real-Debrid のトレント一覧ページ](https://real-debrid.com/torrents)、[TorBox のダッシュボード](https://torbox.app/dashboard)、[DMM のライブラリ](https://debridmediamanager.com/library)で見られます。DMM では、未完了のダウンロードごとに進捗率、シーダー数、速度が表示されます。
4. **0% のまま止まっていて、シーダーもいませんか?** 今そのリリースを共有している人がいないので、完了しないかもしれません。別の結果を選んでください。
5. **これらの結果はまったく表示したくありませんか?** [Torrentio の設定ページ](https://torrentio.strem.fun/configure)を開いて、前と同じようにデバッグサービスとキーを設定します。**Options** の **Don't show download to debrid links** にチェックを入れて **INSTALL** を押してください。そうすると、キャッシュ済みの結果だけが表示されます。

## 再生する前にキャッシュ状況を確認する {#see-whats-cached-before-you-press-play}

debridサービスを使って[DMM](https://debridmediamanager.com/)にサインインし、タイトルを検索します。ページ上の緑色の **Instant RD** ボタンは、Real-Debrid がそのリリースをキャッシュ済みであることを意味するので、すぐに再生できます。**DL with RD** は、キャッシュされていないため、先にダウンロードが必要であることを意味します。検索結果の上にある **RD** チップをタップすると、キャッシュされていないものがすべて非表示になります。TorBox、AllDebrid、Premiumize、Offcloud も同じボタンが使えます（**Instant TB**、**DL with TB** など）。

## よくある質問 {#questions}

### どのくらい時間がかかりますか？ {#how-long-does-it-take}

それは、そのトレントを何人が共有しているかによります。人気のあるリリースは通常、数分で準備できます。当方のテストでは、Premiumizeで1.5 GBの映画が最初のボタン押下から5分後に準備でき、3つのピアからダウンロードされました。あまり共有されていないものは遅くなることがあり、誰も共有していないものは完了しないこともあります。トレントページまたはダッシュボードには、速度と見つかったシード数が表示されます。

### なぜ一部の結果だけでそうなるのですか？ {#why-does-it-happen-on-some-results-and-not-others}

デバッグサービスは、ユーザーがダウンロードしたものを保存しています。誰かがそのリリースをすでに取得していれば、それはキャッシュ済みになっていて、すぐに再生できます。誰も取得していない場合や、サービスがそれを削除してしまった場合は、あなたのアカウントが先にダウンロードしなければなりません。これが `[RD+]` と `[RD download]` の違いです。TorBox は[キャッシュの仕組みについて説明しています](https://support.torbox.app/en/articles/9923071-how-does-the-torbox-cache-work)。

### `[RD+]` の結果でそれが表示されたのはなぜですか？ {#why-did-an-rd-result-show-it}

Real-Debrid では、アドオンが「キャッシュ済みか」を問い合わせることはできません。だから Real-Debrid で Torrentio の `+` が表示されるのは、そのリリースが最近誰かに再生された、という意味です。Real-Debrid がたった今それを確認したわけではありません。その後 Real-Debrid から削除されていた場合は、もう一度ダウンロードが始まります。別の `+` の結果を選ぶか、しばらく待ってください。

### デブリッドが壊れていますか？ {#is-my-debrid-broken}

いいえ。緑の画面は、サービスがそのトレントを受け付けて、処理中という意味です。本当に問題があるときは、Torrentioは赤や黄色の画面に別の文言を表示します。たとえば "Access denied" や "Some usage limit exceeded" などです。

### アドオンが別のメッセージを表示しています {#my-addon-says-something-else}

これらの正確な文言は Torrentio と、そのセルフホスト版から来ています。他のアドオンも同じ内容を別の言い方で表示します。AIOStreams は "The file is being downloaded to your debrid. Try again later" と表示し、Comet は "The media you tried to play is not cached yet on this debrid service" と表示し、StremThru は "Downloading to Store" と表示します。原因は同じで、直し方も同じです。
