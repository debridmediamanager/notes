# TorBox

`type: torbox`

[TorBox](https://torbox.app/subscription?referral=74ffa560-7381-4a18-adb1-cef97378c670) は、zurg が同期し続けるのに最もコストがかからないライブラリで、読み取りのスロットルも最もかかりやすいサービスです。torrent の一覧にはすでにすべてのファイルが含まれています。ライブラリの更新は、torrent ごとに 1 回ずつではなく 1 回のリクエストで済みます。リンク解決エンドポイントはレートではなく固定の許容量です。zurg はこれを意図的に慎重に扱っています。

## APIキーを取得する {#get-the-api-key}

サインインして、[torbox.app/settings](https://torbox.app/settings) を開いてください。API キーはそのページにあります。

**無料アカウントは zurg では使えません。** TorBox は無料のキーからのライブラリへのリクエストにすべて `PLAN_RESTRICTED_FEATURE` で応答するため、zurg はアカウントの中身を読み取れません。有料プランを使ってください。有料プランの期限が切れると、同じ理由で無料扱いになります。

## 設定する {#configure-it}

```yaml
zurg: v1
providers:
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

新しいコンテナにインストールする場合は、セットアップに書き込ませてください。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox
```

すでに `config.yml` があるインストールでは、`http://localhost:9999/config/` の Dashboard で **Add provider** を使うか、ファイルを直接編集してください。どちらの場合も、そのあとで再起動してください。

```bash
docker compose restart zurg
```

!!!warning Compose 環境に TorBox キーを入れるだけでは効果がありません
`TORBOX_TOKEN` は実行中のデーモンではなく `zurg setup` が読み取ります。初回起動時に設定を作るのは Real-Debrid の `TOKEN` だけです。キーはセットアップ用のコンテナに渡すか、Dashboard でアカウントを追加してください。
!!!

無人インストールの場合は、環境変数ではなくファイルを指定してセットアップしてください。

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

## ここでは関係ない2つのキー {#two-keys-that-do-not-apply-here}

`download_tokens` は受け付けられますが、Real-Debrid での動作と同じようには働きません。
second key に切り替えても、torrent や file の ID は再割り当てされません。TorBox ではそれらの ID は、一覧に載せたアカウントに紐づいています。2つ目の TorBox アカウントを使うには、独自の `name` を持つ別のエントリが必要です。

```yaml
providers:
  - type: torbox
    name: tb-main
    token: FIRST_TORBOX_API_KEY
  - type: torbox
    name: tb-second
    token: SECOND_TORBOX_API_KEY
```

`strm_link_token` は受け付けられますが使われません。TorBox はリクエストごとにダウンロード URL を発行します。`.strm` ファイルがそこに固定できるような、長期間有効な認証情報は存在しません。

## 実際の上限はアクティブスロット数 {#active-slots-are-the-real-ceiling}

TorBox の最大の制限は、同時にダウンロードやシーディングができるトレントの数です。Real-Debrid は帯域幅が制限でした。TorBox はスロットです。

| Plan | Active slots |
|---|---|
| Free | 1 but zurg cannot use a free key (see above) |
| Essential | 3 |
| Standard | 5 |
| Pro | 10 |

zurg はアカウントからプランを読み取り、それに基づいてトレントの追加を制限します。プランを読み取れないアカウントは 3 として扱われます。

トレントを追加するほかの仕組みも、同じスロットの枠に収まるように考えてください。Sonarr と Radarr が qBittorrent エンドポイント経由で取得するものや、修復スイープ、ウォッチリストもすべて同じスロットを使います。

## 知っておきたい制限 {#limits-worth-knowing}

**リンクの解決は約100回の呼び出しという「予算」であり、レートではありません。**
2026-08-30に計測。呼び出しをできるだけ速く発行した場合、累計100回目の呼び出しで `Retry-After: 300` 付きの429が返ってきました。1秒に1回のペースに抑えた場合は、94回目で返ってきました。このロックアウトはアカウント全体に及びます。そのときの読み取り1回だけでなく、マウント全体が5分間止まります。

そこから2つのことが言えて、zurgはどちらも自動で行います。

- 誰も要求していないファイルは解決しません。他のバックエンドは次のエピソードを先読みしますが、TorBoxではそのような推測の余裕がありません。メディアサーバーがライブラリを解析するとき、各ファイルは必ず1回ずつ開かれ、そのどれもがコールド状態だからです。
- 複数ボリュームのアーカイブのボリュームは、必ず1つずつ順番に解決します。並列にすると上限を何倍も使い切ってしまい、壊れたボリュームより後ろのボリュームを、それが不要だと分かる前に取得してしまうことになります。

**未キャッシュの追加は1時間に60回です。** キャッシュ済みの追加は代わりに1分あたりの上限に含まれます。

**1つのキーにつき、全エンドポイント合計で1分に300リクエストです。** zurgは300から60を引いた数までペースを抑えます。HTTPクライアントが自動で行うリトライが、予算内のバーストを実際の上限の向こう側まで押し上げないようにするためです。

**1つのCDNホストへの21本目の接続は429になります。** 2026-08-23に、500msごとに1本ずつ接続を開いて保持するテストで計測しました。上限はキーごとではなくホストごとです。読み取りをTorBoxのサーバー群全体に分散させれば回避でき、1台のノードに集中させると回避できません。zurgは20本を超えた分をダイヤルせずにキューに入れます。これにより拒否が短いローカル待機に変わります。

**コンテンツはプランの保持期間を過ぎると削除されます。** 消えたトレントは壊れているのではなく、想定どおりの動作です。修復は明示的に指定しない限りそれに手を付けません。

**ファイル単位の選択はできません。** 追加するとトレント全体を取得し、修復ではリリースを丸ごと再追加します。

ソースを含む全体像は [TorBoxの制限](torbox-limits.md) を参照してください。

## CDNリージョンの選び方 {#choosing-a-cdn-region}

```yaml
tb_cdn_host_preference: "auto"
```

`auto` は TorBox 側の選択をそのままにします。`force_location_<region>` はそのリージョンからダウンロードを配信します。配信ノードを現在公開しているリージョンだけを強制できて、Dashboard のセレクトにはまさにそれらが並びます。ここでは `cdn_host_preference` に手を出さないでください。このキーは Real-Debrid 専用で、その値は Real-Debrid のロケーションコードです。

## 正しく動いたか確認する {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
ls /zurg_mnt/zurg/__all__/ | head
```

アカウントが1つだけの場合、そのアカウント用のフォルダーはマウントのルート一覧から除外されるため、同じファイルが `__all__` の下に表示されます。

## うまくいかないとき {#when-it-goes-wrong}

**ログに `Account <name> refused zurg` と出る、または `TorBox rejected the API key` が繰り返し出る場合。**
プランの期限が切れて、そのキーは今では無料プランになっています。nightly 2026.10.11.2240 からは、zurg はそのキーを使わずに他のアカウントを読み込みます。ダッシュボードのアカウントのカードには `Refused: the account's plan does not include API access` と表示されます。そのアカウントのリリースは一覧に残りますが、再生はできません。このせいで何かが削除されたりゴミ箱に入ったりすることはありません。zurg は 10 分ごとに TorBox へ再確認し、プランが有料に戻ると、そのアカウントを再び読み込みます。古い nightly では、ライブラリ全体の読み込みが終わらなかったため、他のアカウントのコンテンツも表示されなくなっていました。zurg を更新するか、プランを更新してください。`config.yml` の `torbox` プロバイダーをコメントアウトして zurg を再起動する方法でも大丈夫です。

**再生が 5 分間ずつ止まる。** requestdl の枠を使い切っていて、429 はアカウント全体に適用されています。必要以上にリンクを解決しているものがあるはずです。よくある原因は、メディアサーバーがマウント全体を一度にスキャンすることです。全部ではなく、1 つのディレクトリだけを指定してください。

**リリースの取得(grab)が受け付けられなくなる。** アクティブなスロットがすべて埋まっているか、1 時間あたりの追加上限を使い切っているかのどちらかです。どちらも時間が経てば自然に戻るので、再試行しても意味はありません。

**リリースのファイル数が想定より少なく表示される。** `__torbox__` に表示されるのは、TorBox が実際に保持しているものだけです。別のアカウントがそのリリースを丸ごと持っていれば、マウントの残りの部分では全部配信されます。

**torrent が消えた。** 保持期間によるものです。上記を参照してください。zurg は無人では再追加しません。再発見すると、そのアカウントの枠を何も得られないまま使ってしまうためです。
