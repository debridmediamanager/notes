# Usenet

`type: nzb`

Usenetはプロバイダーの一種ですが、debridサービスではありません。APIトークンもリモートライブラリもありません。`.nzb`ファイルをwatchディレクトリに入れると、zurgが1つずつリリースに変換します。記事はニュースサーバーから取得され、プレーヤーがそのバイト列を要求した時点でデコードされます。

このページでは、プロバイダーの項目とDocker固有の内容だけを扱います。zurgでUsenetを動かすそのほかの内容は、[zurgでのUsenet](../guides/usenet.md)にまとめています。ニュースアカウント、NZB、マウント、Plexまで含めた完全な手順です。こちらは2番目に読むページです。

## 設定する {#configure-it}

`token` はありません。有効なエントリになるのは、ホストを持つ `nntp` ブロックです。

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
mount_path: "/zurg_mnt/zurg"
```

`connections` は、お使いのプランで実際に許可されている数に設定してください。zurg はその数で読み込みを行います。1 本の接続が出せる速度はプラン全体の速度のごく一部だからです。ストリーミングでは、記事を 1 つずつ取得するのではなく、許可された接続数をフルに使います。プランで許可された数を超えると、接続が拒否されます。

コンテナを新規にインストールした場合、セットアップですべての項目を聞かれます。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb
```

無人インストールの場合、パスワードはファイルから、それ以外の項目はフラグから読み込まれます。

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb \
  --nntp-host news.example.com \
  --nntp-username YOUR_USENET_USERNAME \
  --nntp-password-file /config/secrets/nntp \
  --nntp-connections 8
```

`--nntp-tls` のデフォルトは true で、`--nntp-port` のデフォルトは、TLS ありの場合 563、なしの場合 119 です。

すでに `config.yml` があるインストールの場合は、`http://localhost:9999/config/` にある Dashboard の **Add provider** を使うか、ファイルを直接編集してください。どちらの場合も、最後に再起動してください。

```bash
docker compose restart zurg
```

## NZBが格納されるコンテナ内の場所 {#where-the-nzbs-go-in-a-container}

監視ディレクトリは設定ファイルの隣にある `nzbs/` です。つまり、ホスト側では `~/zurg/nzbs/`、コンテナ内では `/config/nzbs/` になります。同じディレクトリです。ファイルはホスト側から入れてください。

```bash
mkdir -p ~/zurg/nzbs
cp /path/to/some.nzb ~/zurg/nzbs/
ls /zurg_mnt/zurg/__all__/
```

アカウントが1つだけの場合、`__nzb__` フォルダはマウントのルート一覧から外されます。そのため `__all__` の下を確認してください。

監視ディレクトリは15秒ほどおきに読み込まれます。`./:/config` のバインドの中にあるので、他のファイルと同じように `docker compose pull` やコンテナの再作成をしても消えません。

## このタイプ特有のルール {#rules-specific-to-this-type}

- **Nur ein aktivierter `nzb`-Eintrag.** Zwei würden dasselbe Verzeichnis scannen und jede Veröffentlichung doppelt anlegen. Weitere News-Server gehören unter `nntp.servers` dieses einen Eintrags. Dort bedienen sie dieselbe Bibliothek, statt eine zweite Kopie davon zu liefern. Ein `nzb`-Eintrag neben einem [`torbox_nzb`](torbox-nzb.md)-Eintrag wird aus demselben Grund abgelehnt.
- **`watchlist: true` wird abgelehnt.** Ein News-Server bekommt nie einen Torrent.
- **`add_torrents` wird ignoriert,** und beim Start gibt es dazu eine Warnung, aus demselben Grund.
- **`download_tokens` und `strm_link_token` tun nichts.** Es gibt keine Zugangsdaten, die man rotieren müsste.
- **Das Verzeichnis heißt `__nzb__`,** weil der Name standardmäßig dem Typ entspricht. Wenn du lieber `__usenet__` durchsuchen willst, setz `name: usenet` für den Eintrag.

## 2つ目のニュースサーバーは思った以上に価値がある {#a-second-news-server-is-worth-more-than-it-looks}

保存期間はプロバイダーごとに決まります。あるサーバーで期限切れになった記事が、別のサーバーにはまだ残っていることがよくあります。アカウントが1つしかない場合、消えた記事を取り戻す方法は PAR2 しかなく、その場合は **リリース全体** を読み直す必要があります。つまり、2つ目のサーバーがあるかどうかで、記事1つを取得するだけで済むか、全部を読み直すことになるかが分かれます。

追加のアカウントは、2つ目の `nzb` エントリではなく、このエントリの `nntp.servers` に入れてください。`priority`、`backup`、`backbone` で、どのサーバーに、どの順番で問い合わせるかが決まります。読み込みは、`backup` が付いていないアカウントを合わせた上限に合わせて行われます。設定例と各キーの役割は [zurg での Usenet](../guides/usenet.md#more-than-one-usenet-provider) にまとめてあります。

## 正しく動いたか確認する {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/nzb/test
docker compose logs --tail=100 zurg
ls /zurg_mnt/zurg/__all__/
```

アカウントが1つだけだと、そのアカウント用のフォルダはマウントのルート一覧から外されます。そのためマウントでは、同じファイルが `__all__` の下に表示されます。

ここでのプローブは、既存のプールから最大1つの接続だけを使ってニュースサーバーに認証します。アカウントの情報を問い合わせる API はありません。

## うまくいかないとき {#when-it-goes-wrong}

この2つの症状は、ライブラリではなく、プロバイダーのエントリー自体が原因です。

**読み込みが途切れ、zurg が一度に1記事ずつしか取得しなくなります。** `pipeline_depth` の値がサーバーの許容範囲を超えています。zurg は自動的に値を下げて警告を出します。同時に複数のコマンドを処理できないサーバーでは、`1` を明示的に設定してください。

**レイテンシーの高い回線で速度が出ません。** `socket_receive_buffer_kb` は未設定のままにしてください。値を固定したバッファーは、カーネルがチューニングをやめてしまいます。Linux では、これによって受信ウィンドウが約 64 KiB に抑えられ、アカウントの速度のほとんどが失われます。

それ以外の症状は、[zurg を使った Usenet](../guides/usenet.md#troubleshooting) のトラブルシューティング表に載っています。接続拒否、ストリーミングの遅さ、一度も問い合わせられないプロバイダー、Dashboard での編集で `nntp.servers` が消えてしまった場合なども、すべてそこにあります。
