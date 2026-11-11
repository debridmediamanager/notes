# Real-Debrid

`type: realdebrid`

zurg は [Real-Debrid](http://real-debrid.com/?id=20476302) のサーバーとして始まり、今でもそれが一番得意です。per-file selection、専用の `__downloads__` リスト、CDN host selection、専用の `.strm` トークンを備えた唯一のバックエンドです。

## APIトークンを取得する {#get-the-api-token}

サインインして [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354) を開きます。
トークンは長い16進数の文字列です。全体をコピーしてください。

!!!warning まず自動リモートトラフィックをオフにする
[アカウントページ](http://real-debrid.com/?id=20476410) で **Use my
Remote Traffic automatically when needed** のチェックが外れていることを確認してください。オンのままだと、通常のストリーミングでリモートトラフィックの枠を、何も知らせずに使ってしまいます。
!!!

## 設定する {#configure-it}

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/zurg_mnt/zurg"
```

新しいコンテナをインストールした場合は、セットアップにその設定を書き込ませてください。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider realdebrid
```

すでに `config.yml` があるインストールでは、`http://localhost:9999/config/` の Dashboard を使うか、ファイルを直接編集してください。そのあと再起動します。

```bash
docker compose restart zurg
```

### コンテナが環境変数から初期設定できる唯一のプロバイダー {#the-one-provider-a-container-can-seed-from-the-environment}

Real-Debrid は、実行中のデーモンが単独で設定ファイルを作成できる唯一のアカウントです。Compose の `environment:` ブロックにある `TOKEN` または `RD_TOKEN` は、そのファイルを新しく作る最初の実行時に `config.yml` の初期値として使われます。`MOUNT_PATH` はマウントの初期値になります。

```yaml
    environment:
      - TOKEN=YOUR_RD_API_TOKEN
      - MOUNT_PATH=/zurg_mnt/zurg
```

どちらも読み込まれるのは **最初の実行時だけ** です。いったんファイルができれば、それが唯一の正となる設定元になります。古い変数が Dashboard で設定したマウントパスを黙って上書きすることはありません。その理由で `MOUNT_PATH` が無視される場合は、起動時に警告が表示されます。

## このバックエンドが使う追加のキー {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: realdebrid
    token: PRIMARY_RD_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
    download_tokens:
      - SECOND_RD_TOKEN
      - THIRD_RD_TOKEN
```

`download_tokens` は、同じサービス上のバックアップ API トークンです。有効なトークンの帯域幅の枠を使い切ったときに、そのトークンが代わりに使われます。このエントリのカタログを使い、各トークン自身のトレントライブラリはインポートされません。

`strm_link_token` は `/strm/` に届く読み込みを処理します。そのため、プレーヤーが `.strm` ファイルを開いても、ライブマウントがストリーミングに使っているトークンは消費されません。未設定の場合は `token` にフォールバックします。

Real-Debrid は、認証情報をローテーションできる 2 つのバックエンドのうちの 1 つなので、ここではどちらも設定しておく価値があります。

## 他のプロバイダーにはない Real-Debrid の特徴 {#what-real-debrid-does-that-the-others-do-not}

- **ファイル単位の選択。** リリースを追加すると、その一部だけが取得されることがあります。そのため `force_select_playable_files` が処理できる対象ができ、repair はリリース全体を追加し直すのではなく、壊れたファイルだけに絞って修復できます。
- **downloads という2つ目のリスト。** マウントのルートにある `__downloads__` は、Real-Debrid にしかない unrestricted リンクのリストです。一括で消去するには Web セッションの cookie が必要なので、Dashboard のボタンが唯一の方法になります。Real-Debrid アカウントがない環境では、成功したように見せるのではなく、その旨が表示されます。
- **CDN ホストの選択。** `rd_cdn_host_preference` は、Real-Debrid 自身の選択、Cloudflare の代替ホスト、特定の国のいずれかを選びます。詳しくは [CDN とホストの選択](../reference/config.md#cdn--host-selection) を参照してください。
- **Repair。** Real-Debrid のリンクがファイルに紐づいたまま、torrent は正常と表示していても動かなくなることがあります。zurg に repair サブシステムがあるのはまさにこのためで、repair が必要なバックエンドはこれだけです。

## 知っておきたい制限 {#limits-worth-knowing}

**同じアカウントで2件続けて追加するには、間を20秒あけてください。** 2026-08-17 時点のライブ API で計測しました。クリーンなリリース名6件を10秒間隔で追加したところ、6件すべて拒否されました。同じ6件を20秒間隔で追加したら、6件すべて受理されました。zurg は自分の追加を、この下限に合わせて間隔をあけます。

**拒否された追加は、ブロックされたファイル名と見分けがつきません。** Real-Debrid は、どちらの場合も `451 infringing_file` を返します。スロットルには「記憶」もあります。一度発動すると、何分も何もしていないあとでも拒否が続きます。本番環境の修復スイープでは、開始直後に3件の追加が13秒以内に重なったせいで、4時間まったく何も追加できなかったことがありました。

**名前だけで拒否されるリリースもあります。** 2026年10月14日以降、その対象は11種類の文字列です。WEB-DL、WEB.x264、WEB.H264 は、その完全に一致する場合にだけ対象になります。そのため web-dl、Web-Dl、シーン系の WEB.h264 は通ります。WEBRip、BDRip、HDRip、DVDRip、HDTV.x264、HDTV.XviD、BluRay.x264、p.BluRay.DTS は、大文字小文字を問わず対象になります。最後のものは、1080p.BluRay.DTS のように直前に p が必要です。2002.BluRay.DTS というリリースは問題ありません。区切り文字も完全一致のものだけが対象です。WEB.DL、WEB-x264、BluRay-x264 はすべて通ります。これらのいずれかの名前が付いたリリースは、中身に関係なく、毎回最初のリクエストで必ず拒否されます。名前が一致したリリース内のファイルは受理されますが、ストリーミングはできません。zurg はこれらのパターンを把握しているので、確実に失敗する追加に追加スロットを使ったり、60秒のリトライを2回もしたりする代わりに、ローカルで取得を拒否します。

**アカウントがすでに持っているコンテンツの2つ目のコピーは、まったくダウンロードされません。** Real-Debrid は追加を受け付けますが、そのあと何も取得しません。インスタンスは 0 パーセント、シーダー 0 のまま、ずっと止まったままになります。

**トレントの一覧にはファイルの詳細が含まれません。** トレントごとに個別の info 呼び出しが必要です。そのため zurg はディスク上に info キャッシュを保持しています。大きなライブラリのコールドスキャンは特に負荷が高く、キャッシュがあるおかげで同じ処理を繰り返さずに済みます。

3つのキーで API のペースを調整しており、デフォルト値は一般的なアカウントに合うように設定されています。

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

## 正しく動いたか確認する {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/realdebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

アカウントが1つだけの場合、そのフォルダはマウントのルート一覧から除外されるため、同じファイルが `__all__` の下に表示されます。

## うまくいかないとき {#when-it-goes-wrong}

**`RD Permission denied` がログに出る。** APIキーが取り消されたか、ローテーションされています。[real-debrid.com/apitoken](http://real-debrid.com/?id=20476302) で新しいキーを取得し、ダッシュボードまたは `config.yml` のエントリを更新してください。

**毎回の取得が451で返ってくる。** Real-Debrid が完全に拒否するリリース名か、追加のタイミングが近すぎて、スロットルがまだ効いている場合があります。これは再試行では解消せず、しばらく静かに放置すれば解消します。

**初回起動時にマウントに何も表示されない。** 大きなライブラリは読み込みに時間がかかります。読み込みが終わるまで `/dav/movies/` は503を返します。

**リンクは検証を通過するのに、何も配信されない。** `use_range_verification` を有効にしてください。そうすると zurg は `HEAD` ではなく1バイトの範囲指定GETで確認します。ネットワークや一部の Real-Debrid サーバーでは、`HEAD` に対して誤った応答が返ることがあります。
