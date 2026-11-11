# DMM

[Debrid Media Manager](https://debridmediamanager.com) では、映画やドラマを探して、debrid のライブラリに保存しておけます。

DMM のブラウザ拡張機能を使うと、IMDb、Trakt などの映画・ドラマサイトにボタンが追加されます。[Safari での DMM ボタン](safari.md) に Safari の設定方法があります。

DMM は他のプロジェクトのためにも動いています。

- **zurg** は、各ファイルがどの映画やエピソードなのかを DMM に問い合わせます。スポンサーになると、[gatekeeper](https://gatekeeper.debridmediamanager.com/) から DMM API キーを取得できます。キーがないと、zurg はファイル名だけに頼るので、一致するタイトルが減ります。違いについては [zurg と使う rex](../rex/with-zurg.md#why-dmm-places-the-files) を見てください。
- **Sonarr Radarr と Prowlarr** は、DMM を Torznab のトレントインデクサー、または Newznab の Usenet インデクサーとして検索できます。どちらもスポンサーが有効であることと DMM API キーが必要です。設定は [Torznab](https://debridmediamanager.com/torznab) と [Newznab](https://debridmediamanager.com/newznab) のページでできます。
- **ウォントリスト**: **Want** を押すか、Trakt や MDBList のリストをフォローします。zurg がリストを取得し、新しいエピソードも放送されるたびに取得します。スポンサーが必要です。[DMM のウォントリスト](../zurg/guides/dmm-wanted.md) を見てください。
- **Seerr Overseerr Jellyseerr** は、DMM を Radarr や Sonarr の代わりに使えます。リクエストはウォントリストに入り、zurg が取得します。スポンサーが必要です。[DMM 経由の Seerr](seerr.md) を見てください。
- **rex-direct** は、認証済みの rex に専用のアドレスと証明書を与えます。[rex-direct](../rex/any-source.md#rex-direct) を見てください。

スポンサーになると何が使えるようになり、それぞれどこで設定するかは [スポンサーになると得られるもの](../guides/sponsorship.md) にまとめてあります。

困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP) の **dmm-support** フォーラムで聞いてください。何を書けばよいかは [サポートの受け方](../guides/remote-help.md) にあります。
