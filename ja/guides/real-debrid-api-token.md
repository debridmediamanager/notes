# Real-DebridのAPIトークン: 取得場所とエラーの意味 {#your-real-debrid-api-token-where-to-get-it-and-what-the-errors-mean}

Real-Debrid の API トークンは [real-debrid.com/apitoken](https://real-debrid.com/apitoken) にあります。Real-Debrid にサインインして、そのページを開き、**API Private Token** の下にあるコードをコピーしてください。それを DMM または zurg に貼り付けます。アプリに `bad_token` と表示された場合は、アプリに入っているトークンが間違っているか不完全です。そのページからもう一度コピーし直してください。

## トークンを取得する {#get-your-token}

1. [real-debrid.com](https://real-debrid.com) にサインインします。サインインしていないと、トークンのページには **403-Forbidden** としか表示されません。
2. [real-debrid.com/apitoken](https://real-debrid.com/apitoken) を開きます。
3. **API Private Token** の下にあるコード全体をコピーします。大文字のアルファベットと数字が52文字並んでいます。

![Real-DebridのAPI Private Tokenページ。トークンはぼかしてあります](../assets/real-debrid-api-token/01-apitoken.webp)

このトークンはパスワードと同じように扱ってください。有効期限はなく、持っている人はあなたのアカウント全体を使えてしまいます。そのページには Real-Debrid 自身の警告も書かれています: **This token is not meant to be used into public apps, it is insecure !**

そのページの **Refresh** を押すと新しいトークンが発行されます。誰かに自分のトークンを知られたかもしれないと思ったら、Real-Debrid もこの操作を勧めています。更新したら、古いトークンを使っていたアプリすべてに新しいトークンを貼り付けてください。

## DMMに入れる {#put-it-in-dmm}

1. [debridmediamanager.com](https://debridmediamanager.com) で **Login with Real Debrid** を押します。
2. **or paste an API key** の下にある **API Key**欄にトークンを貼り付け、**Save API Key** を押します。**Get API Key from Real-Debrid** を押すと、トークンのページが開きます。

![DMM's Connect Real-Debrid page](../assets/real-debrid-api-token/02-dmm-paste-key.webp)

DMM はトークンがなくても使えます。**Sign in with Real-Debrid** を押すと、real-debrid.com/device で承認するためのコードが表示されます。この方法だと DMM 専用のサインインになり、自動で更新されます。詳しくは [DMMとは何か、そして使い方は?](../dmm/index.md#sign-in) を参照してください。

## zurgに入れる {#put-it-in-zurg}

`config.yml` の `providers` の下に、次のように記述します:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
```

または zurg の Dashboard（`http://localhost:9999`）で、**Config** を開き、**Providers** の下にある realdebrid の行で **Edit** を押し、**Token** にトークンを貼り付けて **Save** を押します。どちらの場合も zurg を再起動してください。残りの内容（Docker の `TOKEN` 設定を含む）は [Real-Debrid with zurg](../zurg/providers/realdebrid.md) に書いてあります。

zurg がトークンをどう判断しているか確認するには:

```bash
curl -sS -X POST http://localhost:9999/api/providers/realdebrid/test
```

Real-Debrid が受け付けないトークンの場合、次のメッセージが返ります: `account connection check failed; verify credentials and network`

## トークンを自分で確認する {#check-a-token-yourself}

```bash
curl -H "Authorization: Bearer YOUR_RD_API_TOKEN" https://api.real-debrid.com/rest/1.0/user
```

Windowsでは `curl` ではなく `curl.exe` と入力します。有効なトークンを使うと、アカウント情報が表示されます。表示内容は `username`、`"type": "premium"`、そして `expiration` の日付です。無効なトークンの場合は次のように表示されます:

```json
{
	"error": "bad_token",
	"error_code": 8
}
```

## 問題が起きたとき {#when-something-is-wrong}

Real-Debrid のエラーには名前と番号が付いています。zurg は両方を表示します。例: `bad_token (status code: 401) (code: 8)`

| 見えるもの | 意味と対処 |
|---|---|
| `bad_token`、コード 8。zurg では: `Failed to get user information: api response error: bad_token (status code: 401) (code: 8) trying again in 30s` | Real-Debrid はそのトークンを知りません。コピーが間違っているか、途中で切れているか、差し替えられています。[real-debrid.com/apitoken](https://real-debrid.com/apitoken) からもう一度コピーしてください。前後に何も付けず、全体をコピーします。そのあと zurg を再起動します。 |
| zurg: `Account realdebrid refused zurg (credential rejected)` | `bad_token` と同じです。他のアカウントは引き続き動作し、zurg は 10 分ごとに Real-Debrid へ再確認します。 |
| DMM: **Real-Debrid rejected that API key.** | `bad_token` と同じです。もう一度コピーするか、代わりに **Sign in with Real-Debrid** を押してください。 |
| `permission_denied`、コード 9。zurg では: `RD Permission denied (code=9)` | トークンではなく、Real-Debrid がアカウントを拒否しています。ドキュメントではロックされたアカウントが挙げられており、一部のリクエストでは Premium のないアカウントも対象です。real-debrid.com にサインインして、アカウントと **Premium** の残り日数を確認してください。どちらも問題なければ、トークンページで **Refresh** を押し、zurg のメッセージにあるとおり新しいトークンを貼り付けてください。 |
| `ip_not_allowed`、コード 22。zurg では: `RD refused link generation from this IP (code=22, ip_not_allowed)` | トークンの問題ではありません。Real-Debrid はサーバーや VPS のアドレスからのダウンロードリンク生成を受け付けません。自宅のネット回線から実行するか、Real-Debrid から Remote Traffic を購入してください。 |
| `service_unavailable`、コード 25 | Real-Debrid 側に問題が起きています。こちらで変更することはありません。[Real-Debrid はダウンしている？それとも自分だけ？](https://debridmediamanager.com/is-real-debrid-down-or-just-me) を確認して、後でもう一度試してください。 |
| real-debrid.com/apitoken で **403-Forbidden** | Real-Debrid にサインインしていません。サインインしてから、そのページをもう一度開いてください。 |

すべてのコードは、[Real-Debrid の API ドキュメント](https://api.real-debrid.com/) の一番下に一覧があります。

## よくある質問 {#questions}

### Real-DebridのAPIトークンはどこで見つけられますか? {#where-do-i-find-my-real-debrid-api-token}

[real-debrid.com/apitoken](https://real-debrid.com/apitoken) にサインインした状態で開いてください。**API Private Token** の下にあるコードをコピーします。

### 別のアプリではトークンが使えるのにzurgで無効と言われます。なぜですか? {#my-token-works-in-another-app-but-zurg-says-its-invalid-why}

アカウントの API トークンは 1 つだけです。多くのアプリはこのトークンを使わず、代わりにコードでサインインします。たとえば DMM の **Sign in with Real-Debrid** がそうです。そのため、別のアプリが動いていても、zurg に正しいトークンが入っているとは限りません。トークンページからもう一度コピーして zurg に入れてください。前後に余計な文字を付けないように注意し、その後 zurg を再起動してください。

### トークンは期限切れになりますか? {#does-the-token-expire}

いいえ、APIトークンには有効期限はありません。アプリからのサインインは別物で、そのアプリ専用の認証情報が発行され、それは自動的に更新されます。

### アドオンやWebサイトにトークンを渡しても安全ですか? {#is-it-safe-to-give-my-token-to-an-addon-or-website}

信頼できるアプリにだけ入力してください。このトークンでアカウント全体が開けてしまい、Real-Debridも公開アプリ向けのものではないと明言しています。コードでのサインインに対応しているアプリなら、そちらを使ってください。
