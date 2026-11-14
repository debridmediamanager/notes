# DMM

[Debrid Media Manager](https://debridmediamanager.com) は、映画やドラマを探して、debrid ライブラリに保存しておくのに役立ちます。

Stremio で見るには、DMM 独自のアドオン DMM Cast を追加します。設定方法は [DMM in Stremio](stremio.md) を参照してください。

DMM のブラウザ拡張機能を使うと、IMDb、Trakt などの映画・ドラマサイトにボタンが追加されます。Safari での設定は [DMM buttons in Safari](safari.md) で説明しています。

DMM は他のプロジェクトにも機能を提供しています。

- **zurg** は、各ファイルがどの映画やエピソードなのかを DMM に問い合わせます。スポンサーは [gatekeeper](https://gatekeeper.debridmediamanager.com/) から DMM API キーを取得できます。キーがないと、zurg はファイル名だけを頼りにするため、一致するタイトルが少なくなります。違いについては [rex with zurg](../rex/with-zurg.md#why-dmm-places-the-files) を参照してください。
- **Sonarr、Radarr、Prowlarr** は、DMM を Torznab のトレントインデクサー、または Newznab の Usenet インデクサーとして検索できます。どちらも有効なスポンサー登録と DMM API キーが必要です。設定は [Torznab](https://debridmediamanager.com/torznab) と [Newznab](https://debridmediamanager.com/newznab) のページで行ってください。
- **ウォントリスト**: **Want** を押すか、Trakt や MDBList のリストをフォローします。zurg がリストと、放送される新しいエピソードを取得します。スポンサー登録が必要です。詳しくは [DMM wanted list](../zurg/guides/dmm-wanted.md) を参照してください。
- **Seerr、Overseerr、Jellyseerr** は、DMM を Radarr や Sonarr の代わりに使えます。リクエストはウォントリストに入り、zurg が取得します。スポンサー登録が必要です。詳しくは [Seerr through DMM](seerr.md) を参照してください。
- **rex-direct** は、認証された rex に独自のアドレスと証明書を与えます。詳しくは [rex-direct](../rex/any-source.md#rex-direct) を参照してください。

スポンサー登録で使える機能の一覧と、それぞれの設定場所は [What a sponsorship gives you](../guides/sponsorship.md) にあります。

困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP) の **dmm-support** フォーラムで質問してください。何を含めればよいかは [Getting help](../guides/remote-help.md) に書かれています。
