# Premiumize

`type: premiumize`

Premiumizeでは、完了したトランスファーだけでなく、トランスファー一覧をクリアした後も残っているクラウドファイルもマウントされます。ネストされたフォルダーはパスが維持されます。Premiumizeで整理したライブラリは、そのままの構成でマウントに反映されます。

## APIキーを取得する {#get-the-api-key}

サインインして [premiumize.me/account](https://www.premiumize.me/account) を開きます。API キーはそのページにあります。

## 設定する {#configure-it}

```yaml
zurg: v1
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY
mount_path: "/zurg_mnt/zurg"
```

コンテナを新しくインストールした場合は、セットアップに書き込ませてください。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider premiumize
```

すでに `config.yml` があるインストールの場合は、`http://localhost:9999/config/` のダッシュボードにある **Add provider** を使うか、ファイルを直接編集してください。どちらの方法でも、そのあとに再起動してください。

```bash
docker compose restart zurg
```

`PREMIUMIZE_TOKEN` は `zurg setup` が読み取るもので、実行中のデーモンは読み取りません。compose の `environment:` ブロックに置いただけでは、何の効果もありません。

## エントリごとに認証情報は1つ {#one-credential-per-entry}

Premiumize のファイル ID は、それを一覧に登録したアカウントに紐づいています。切り替えられる 2 つ目のキーはありません。`download_tokens` は受け付けられず、`token` と異なる `strm_link_token` も同様です。2 つ目の Premiumize アカウントを使うには、それぞれ独自の `name` を持つ別のエントリを追加してください。

```yaml
providers:
  - type: premiumize
    name: pm-main
    token: FIRST_PREMIUMIZE_API_KEY
  - type: premiumize
    name: pm-second
    token: SECOND_PREMIUMIZE_API_KEY
```

ローダーはこの点を黙って無視するのではなく、はっきり伝えます。設定を拒否し、該当するエントリの名前を表示します。

## ここで使えるもの {#what-works-here}

ライブラリの閲覧、ストリーミング読み取り、リダイレクト読み取り、STRM、マグネットリンクの追加、`.torrent` のアップロード、削除は、どれも動きます。アカウントには、ほかのアカウントと同じように専用の `__premiumize__` ディレクトリが作られます。

## ハッシュはディスクに保存されます {#hashes-are-remembered-on-disk}

zurg 経由で渡されたハッシュは、`/config` バインド内の `data/premiumize/<account>/sources.json` に書き込まれます。アカウント間のマッチングは、再起動後も、完了済みの転送リストをクリアした後も維持されます。

別の方法でインポートしたクラウドのコンテンツには、記録されたハッシュがありません。それでもストリーミングはできます。ただし、ハッシュを使った修復はできず、ハッシュで別のアカウントと照合することもできません。

!!!warning 転送を削除すると、ファイルも削除されます
zurg 経由で Premiumize の転送を削除すると、その転送が所有するファイルも削除されます。これは Premiumize 自体の動作で、zurg が独自に追加しているものではありません。
!!!

## 知っておきたい制限 {#limits-worth-knowing}

**Cloud-Speicher und Fair-Use sind die eigenen Grenzen des Kontos.** zurg hebt sie
nicht auf und umgeht sie auch nicht.

**8 gleichzeitige API-Anfragen.** Vier Volumes eines Multi-Volume-Archivs werden
gleichzeitig aufgelöst.

**Inhalte laufen ab.** Ein Release, das nicht mehr verfügbar ist, ist ein erwartetes
Ergebnis und kein Fehler. Repair lässt es in Ruhe, außer du forderst es ausdrücklich an.

**Die Torrent-Liste enthält keine Dateidetails.** Jedes Release braucht beim ersten
Mal eine eigene Abfrage.

zurg ordnet die Fehlercodes des Dienstes dem zu, was als Nächstes zu tun ist.

| Code von Premiumize | Was zurg macht |
|---|---|
| `authentication_failed` | Meldet einen ungültigen Zugangsschlüssel. Korrigiere den Key. |
| `rate_limit_reached` | Pausiert das Konto für eine Minute. |
| `account_limit_reached` oder `service_limit_reached` | Meldet ein aufgebrauchtes Kontingent. |
| `service_down` | Behandelt das Konto als vorübergehend nicht verfügbar. |
| `not_found` | Behandelt den Torrent als nicht mehr vorhanden. |

## 正しく動いたか確認する {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/premiumize/test
ls /zurg_mnt/zurg/__all__/ | head
```

アカウントが1つだけの場合、そのアカウント専用のフォルダはマウントのルート一覧から除外されるため、同じファイルが `__all__` の下に表示されます。

## うまくいかないとき {#when-it-goes-wrong}

**資格情報が正しくないと、すべてが失敗する。** [premiumize.me/account](https://www.premiumize.me/account) でキーを再生成し、エントリを更新してください。Premiumize はキーが未設定の場合と間違っている場合で同じ応答を返すことに注意してください。そのため、どちらだったのかはメッセージからは分かりません。

**リリースはストリーミングできるが、修復されない。** 記録されたハッシュがないためです。これは zurg 以外の経路でアカウントに入ってきたことを意味します。上記を参照してください。

**読み込みが1分ごとに止まる。** レート制限に達したため、zurg がアカウントを意図的に一時停止しています。自動的に再開します。

**生成された URL は、持っている人なら誰でも使える。** 配信 URL や `.strm` へのアクセスは非公開にしておく価値があります。それらが消費するクォータは、そのアカウント自身のものです。
