# Debrid-Link

`type: debridlink`

[Debrid-Link](https://debrid-link.com/id/diG1t) の seedbox 一覧には、すべてのファイルが載っています。ライブラリを更新するときは、リリースごとに個別に問い合わせる代わりに、ページを順番にめくるだけで済みます。3つのクラウドバックエンドの中で、同期を保つのに最もコストがかからないものです。

## APIキーを取得する {#get-the-api-key}

サインインして、[debrid-link.fr/webapp/apikey](https://debrid-link.fr/webapp/apikey) を開きます。キーを生成してコピーします。

## 設定する {#configure-it}

```yaml
zurg: v1
providers:
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_KEY
mount_path: "/zurg_mnt/zurg"
```

まっさらなコンテナにインストールしたときは、セットアップに書き込ませましょう。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider debridlink
```

すでに `config.yml` があるインストールなら、`http://localhost:9999/config/` の Dashboard で **Add provider** を使うか、ファイルを直接編集してください。どちらの場合も、最後にリスタートしてください。

```bash
docker compose restart zurg
```

`DEBRIDLINK_TOKEN` は `zurg setup` が読み取るもので、実行中のデーモンは読みません。

## エントリごとに認証情報は1つ {#one-credential-per-entry}

Debrid-Linkは、ライブラリを一覧表示しているアカウントに属するIDで各ファイルを解決します。
ローテーションに使える2つ目のキーはありません。`download_tokens`は拒否されますし、`token`と異なる`strm_link_token`も拒否されます。2つ目のアカウントを使いたい場合は、独自の`name`を持つ2つ目のエントリを追加してください。

```yaml
providers:
  - type: debridlink
    name: dl-main
    token: FIRST_DEBRID_LINK_API_KEY
  - type: debridlink
    name: dl-second
    token: SECOND_DEBRID_LINK_API_KEY
```

## ここで使えるもの {#what-works-here}

ライブラリの閲覧、ストリーミング読み取り、リダイレクト読み取り、STRM、マグネットの追加、`.torrent` のアップロード、削除はすべて動作します。アカウントごとに専用の `__debridlink__` ディレクトリが作られます。

## 知っておきたい制限 {#limits-worth-knowing}

**同時に使えるスロットは20個です。** zurg は、これ以上の追加をこの上限で止めます。

**同時 API リクエストは8件まで。** 複数ボリュームのアーカイブでは、4つのボリュームが同時に解決されます。

**コンテンツは期限切れになります。** 配信元から消えたリリースは、壊れているのではなく、想定どおりの状態です。

**キャッシュ確認はありません。** Debrid-Link はそのエンドポイントを廃止しており、zurg も使っていません。cached-only の追加では、ヒットしたかどうかは追加時のレスポンスそのものでしか判断できません。追加前に「キャッシュ済みか」を尋ねることは、このバックエンドでは答えられない質問です。

zurg は、サービスのエラーコードを次に取るべき動作に対応付けます。

| Debrid-Link からのコード | zurg の動作 |
|---|---|
| `badToken` or `badSign` | 不正な認証情報を報告します。キーを修正してください。 |
| `floodDetected` | アカウントを1時間停止します。 |
| `maxTorrent` `maxData` `maxLink` and their `Host` variants | 1日分の追加またはトラフィックの上限に達したことを報告します。 |
| `serverNotAllowed` `maintenanceHost` `maxTransfer` | アカウントを一時的に利用不可として扱います。 |
| `badId` | そのtorrentは消えたものとして扱います。 |

!!!warning flood 拒否は1時間の停止になります
`floodDetected` は、アカウントを1分ではなく丸1時間停止させます。これは意図的な仕様です。flood 拒否のあとに再試行すると、次の拒否を招くだけです。zurg を再起動する前に、それを連続で叩いていたものの間隔を空けてください。
!!!

## 正しく動いたか確認する {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/debridlink/test
ls /zurg_mnt/zurg/__all__/ | head
```

アカウントが1つだけだと、そのアカウント用のフォルダはマウントのルート一覧から外されます。
そのため、マウントでは同じファイルが `__all__` の下に表示されます。

## うまくいかないとき {#when-it-goes-wrong}

**一時間ずっと何も起きない。** フラッドによる拒否です。上の警告を参照してください。

**Grab は拒否されるのに、読み取りは動く。** 1日あたりの追加またはトラフィックのクォータを使い切っています。リセットはサービス側のスケジュールに従います。

**追加は成功するのに、そのまま止まっている。** キャッシュ用エンドポイントがないと、あるハッシュがすでに保持されているかを事前に知る方法がありません。キャッシュされていない追加は、ほかの追加と同じようにダウンロードされます。
