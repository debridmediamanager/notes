# Safari で DMM のボタンを表示 {#dmm-buttons-in-safari}

DMM拡張機能を使うと、映画やテレビ番組のサイトに **DMM🔎** ボタンが表示されます。そのボタンを押すと、タイトルがDMMで開きます。マグネットリンクの横には **DMM🧲** ボタンが追加されます。これを押すと、そのトレントがDMMのライブラリに追加されます。

ChromeとFirefoxでは、[Chrome拡張機能](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm)または[Firefoxアドオン](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/)をインストールしてください。Safariでは、同じコードを[Greasy Fork用ユーザースクリプト](https://greasyfork.org/en/scripts/463268-debrid-media-manager)として、ユーザースクリプトマネージャーと一緒に使います。

マネージャーを1つ選んでください:

| マネージャー | 価格 | 対応環境 | スクリプトの更新 |
|---|---|---|---|
| [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) | 無料 | Mac、iPhone、iPad | ポップアップで **Update** をタップしたとき |
| [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) | $2.99 | Mac、iPhone、iPad | 自動で |

## Userscripts を使う場合 {#with-userscripts}

1. App Store から [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) をインストールし、一度開いてください。
2. 拡張機能を有効にします:
   - **Mac:** Safari > **Settings** > **Extensions** を開き、**Userscripts** にチェックを入れます。
   - **iPhone と iPad:** **Settings** > **Apps** > **Safari** > **Extensions** > **Userscripts** を開き、**Allow Extension** をオンにします。
3. すべてのサイトで動作するようにします。マグネットリンクはどのサイトにもあり得るので、スクリプトはどこでも動く必要があります。
   - **Mac:** 同じ **Extensions** の画面で **Edit Websites…** をクリックし、**When visiting other websites** を **Allow** に設定します。
   - **iPhone と iPad:** 同じ **Userscripts** の画面で、**All Websites** を **Allow** に設定します。
4. Safari で [DMM のユーザースクリプトファイル](https://update.greasyfork.org/scripts/463268/Debrid%20Media%20Manager.user.js) を開きます。プレーンテキストとして表示されます。
5. Userscripts のポップアップを開きます。Mac ではツールバーのボタン、iPhone ではアドレスバーの **aA** ボタンから開けます。表示されるインストールのプロンプトをタップして、確定してください。

あとで更新するときは、Userscripts のポップアップを開き、DMM のスクリプトが表示されたら **Update** をタップします。

## Tampermonkey を使う場合 {#with-tampermonkey}

1. App Store から [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) をインストールします。
2. オンにして、すべてのサイトで動くようにします。上の手順 2 と 3 と同じですが、**Userscripts** の代わりに **Tampermonkey** を使います。
3. Safari で、スクリプトの [Greasy Fork ページ](https://greasyfork.org/en/scripts/463268-debrid-media-manager) を開き、**Install this script** をクリックします。
4. Tampermonkey のインストールページが開きます。**Install** をクリックします。

Tampermonkey は 1 日に 1 回、新しいバージョンがないか確認します。

## 動作を確認する {#check-it-works}

[Letterboxd で Dune: Part Two を開き](https://letterboxd.com/film/dune-part-two/)ます。タイトルの横に青緑色の **DMM🔎** ボタンが表示され、押すと DMM でその映画が開きます。

ボタンが出ない場合は、次を確認してください。

- 拡張機能マネージャーのポップアップに **Debrid Media Manager** が表示されていて、スイッチがオンになっているか。
- Safari でマネージャーがそのサイトで動くのを許可しているか。許可を求められたら **Always Allow on Every Website** を選びます。
- ページの読み込みが終わっているか。TMDB、Wikipedia、AniList などのサイトでは、ボタンがページより少し遅れて表示されます。
