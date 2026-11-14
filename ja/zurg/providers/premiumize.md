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

**クラウドストレージとフェアユースは、アカウント自体の上限です。** zurg はこれらの上限を引き上げたり、回避したりはしません。

**同時 API リクエスト 8 件。** 複数ボリュームのアーカイブの 4 つのボリュームが同時に解決されます。

**コンテンツは期限切れになります。** リリースが消えているのは想定どおりの結果であり、障害ではありません。修復は、こちらが依頼しない限り、そのリリースには手を出しません。

**トレントリストにはファイルの詳細が含まれません。** 各リリースは、初回に個別の検索が 1 回ずつ必要になります。

zurg は、サービスのエラーコードごとに次に取るべき動作を決めています。

| Premiumize からのコード | zurg の動作 |
|---|---|
| `authentication_failed` | 認証情報が不正だと報告します。キーを修正してください。 |
| `rate_limit_reached` | アカウントを 1 分間一時停止します。 |
| `account_limit_reached` または `service_limit_reached` | 利用枠を使い切ったと報告します。 |
| `service_down` | アカウントを一時的に利用できない状態として扱います。 |
| `not_found` | トレントが消えたものとして扱います。 |

## 正しく動いたか確認する {#check-it-worked}

```bash
curl -sS -X POST http://localhost:9999/api/providers/premiumize/test
ls /zurg_mnt/zurg/__all__/ | head
```

アカウントが1つだけの場合、そのアカウント専用のフォルダはマウントのルート一覧から除外されるため、同じファイルが `__all__` の下に表示されます。

## うまくいかないとき {#when-it-goes-wrong}

**資格情報が正しくないと、すべてが失敗する。** [premiumize.me/account](https://www.premiumize.me/account) でキーを再生成し、エントリを更新してください。Premiumize はキーが未設定の場合と間違っている場合で同じ応答を返すことに注意してください。そのため、どちらだったのかはメッセージからは分かりません。

**リリースはストリーミングできるが、修復されない。** 記録されたハッシュがないためです。これは zurg 以外の経路でアカウントに入ってきたことを意味します。上記を参照してください。

**読み込みが1分ごとに止まる。** レート制限に達したため、zurg がアカウントを意図的に一時停止しています。自動的に再開します。

**生成された URL は、持っている人なら誰でも使える。** 配信 URL や `.strm` へのアクセスは非公開にしておく価値があります。それらが消費するクォータは、そのアカウント自身のものです。
