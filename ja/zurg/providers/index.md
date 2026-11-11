# プロバイダー {#providers}

プロバイダーとは、zurg がライブラリを組み立てる元になるアカウント 1 つのことです。アカウントごとに `config.yml` の `providers:` の下に 1 件ずつ書きます。1 つだけ動かしても 6 つ動かしても構いません。複数のアカウントが同じリリースを持っている場合、一覧には 1 回だけ表示され、そのときに利用できるアカウントから読み込まれます。

| サービス | `type` | ページ |
|---|---|---|
| Real-Debrid | `realdebrid` | [Real-Debrid](realdebrid.md) |
| TorBox | `torbox` | [TorBox](torbox.md) |
| AllDebrid | `alldebrid` | [AllDebrid](alldebrid.md) |
| Premiumize | `premiumize` | [Premiumize](premiumize.md) |
| Debrid-Link | `debridlink` | [Debrid-Link](debridlink.md) |
| Offcloud | `offcloud` | [Offcloud](offcloud.md) |
| Usenet | `nzb` | [Usenet](usenet.md) |
| TorBox hosted Usenet | `torbox_nzb` | [TorBox hosted Usenet](torbox-nzb.md) |

セットアップ以上の詳しい内容は、3 つのページにまとめています。[TorBox の制限](torbox-limits.md)には、TorBox のスロットリングの根拠となる測定値が載っています。[TorBox ニュースサーバー](torbox-news-server.md)と[ElfHosted ニュースサーバー](elfhosted-news-server.md)では、それぞれのプランに含まれる Usenet アカウントの実際の中身を記録しています。プロバイダー枠を使う前に、まずこれらを読んで判断してください。

このページのすべての内容は、[Docker セットアップ](../setup/docker.md)のコンテナ版インストールを前提としています。`~/zurg` はホスト上の compose ディレクトリです。`/config` は、同じディレクトリをコンテナの中から見たパスです。`config.yml` は 1 つだけで、どちらの名前からでも同じファイルにアクセスできます。

Linux、macOS、Windows のバイナリ版インストールでは、`docker compose restart zurg` と `setup` の行の代わりに何を使うかは [セットアップ](../setup/index.md)に載っています。チェックも同じように読み替えてください。zurg のフォルダーから実行してください。`docker compose logs` の代わりに `logs/zurg.log` を読んでください（PowerShell では `Get-Content logs\zurg.log -Tail 100 -Wait`）。`--working-dir /config` を付けずに `./zurg doctor`（`.\zurg.exe doctor`）を実行してください。`/zurg_mnt/zurg` の代わりに、自分のマウント先を使ってください。`mount_path` を変更していない場合は、`/mnt/zurg`、`/Volumes/Zurg`、`Z:\` のいずれかです。Windows PowerShell 5.1 では `curl` ではなく `curl.exe` と入力してください。

## アカウントを追加する3つの方法 {#three-ways-to-add-an-account}

どちらを使うかは、`config.yml` がもう存在するかどうかで決まります。

### 新規インストールならセットアップを使う {#on-a-fresh-install-use-setup}

`zurg setup` は、設定するプロバイダーを尋ねてきて、その認証情報だけを入力させます。アカウントを書き込むのは **`config.yml` がまだないときだけ** です。
後からもう一度実行しても、既存のアカウントには触れずにインストールを更新してくれるので安心です。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

選択肢は番号でも名前でも入力できて、一度に複数選ぶこともできます。

```
Choose one or more providers in priority order:
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
Providers (comma-separated numbers or names): 2,4
```

入力した内容は、compose ファイルにもシェルの履歴にも残りません。トークンは `config.yml` に直接書き込まれ、ファイルは所有者だけが読み書きできる権限で保存されます。

### 既存のインストールならダッシュボードを使う {#on-an-existing-install-use-the-dashboard}

`http://localhost:9999/config/` を開き、Essentials の下にある **Add provider** を使ってください。

種類を選びます。トークンを貼り付けます。Save を押します。Dashboard は、その項目を compose ファイルと同じ場所にある `config.yml` に書き戻します。

プロバイダーの変更は、反映される前に再起動が必要です。Dashboard にもそう表示されますし、再起動はコマンド1つで済みます。

```bash
docker compose restart zurg
```

### または config.yml を手作業で編集する {#or-edit-configyml-by-hand}

ファイルはホストの `~/zurg/config.yml` です。エントリを追加して再起動してください。

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

コンテナ内では `mount_path` は `/zurg_mnt/zurg` になり、マウントをホストに届けるには compose ファイルで `/zurg_mnt:/zurg_mnt:rshared` をバインドする必要があります。これは [Docker setup](../setup/docker.md) ページの内容で、コンテナ版のインストールでバイナリ版と違う唯一の部分です。

## 無人インストール {#unattended-installs}

各プロバイダーには、トークンファイル用のフラグと環境変数があります。アカウントごとに `--provider` を繰り返し指定してください。

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

| `type` | フラグ | 環境変数 |
|---|---|---|
| `realdebrid` | `--realdebrid-token-file` | `REALDEBRID_TOKEN` または `TOKEN` または `RD_TOKEN` |
| `torbox` | `--torbox-token-file` | `TORBOX_TOKEN` |
| `alldebrid` | `--alldebrid-token-file` | `ALLDEBRID_TOKEN` |
| `premiumize` | `--premiumize-token-file` | `PREMIUMIZE_TOKEN` |
| `debridlink` | `--debridlink-token-file` | `DEBRIDLINK_TOKEN` |
| `offcloud` | `--offcloud-token-file` | `OFFCLOUD_TOKEN` |
| `nzb` | `--nntp-host` と `--nntp-username` を付けた `--nntp-password-file` | `NNTP_HOST` など |
| `torbox_nzb` | `--torbox-token-file` | `TORBOX_TOKEN` |

`torbox_nzb` は、`TORBOX_TOKEN` や `--torbox-token-file` だけでは自動判定されません。`--provider torbox_nzb` を指定してください。

`--non-interactive` を使い、`--provider` をまったく指定しない場合は、上記の変数のうち設定されているものがセットアップで使われます。

!!!warning 実行中のコンテナがシードするのは Real-Debrid だけです
zurg デーモン自体が読み取るのは、`config.yml` を作成する初回実行時の `TOKEN`、`RD_TOKEN`、`MOUNT_PATH` だけです。これがすべてです。`TORBOX_TOKEN` などのその他の変数は `zurg setup` が読み取ります。compose の `environment:` ブロックに書いてコンテナを起動しても、それだけでは何も起こりません。セットアップを実行するか、Dashboard からアカウントを追加してください。
!!!

## 各エントリで指定できる内容 {#what-every-entry-accepts}

| キー | 役割 |
|---|---|
| `type` | 必須です。上記の8種類のいずれかを指定します。 |
| `name` | 省略時は `type` の値になります。同じサービスのアカウントが2つあるときに区別するための名前です。 |
| `token` | APIキーです。`nzb` では使われません。 |
| `disabled` | 認証情報は消さずに、アカウントを一時的に停止します。 |
| `watchlist` | 新しいtorrentの追加を最初に試すアカウントとして指定します。 |
| `add_torrents` | `false` にすると、そのアカウントは配信には使われますが、新しいものは割り当てられません。 |
| `warm_connections` | ホストごとに開いたままにしておく接続数です。読み込みのたびに接続を張り直す手間を省けます。 |

すべての詳しい説明や、その他の項目については、[設定リファレンス](../reference/config.md#accounts)をご覧ください。

## ローダーが適用するルール {#rules-the-loader-enforces}

- 名前は一意である必要があります。Real-Debrid のアカウントを 2 つ使う場合は、`name: rd-main` と `name: rd-backup` のように別々の名前を付けてください。付けないと読み込みに失敗します。
- 名前 `e` は `.strm` のリンク振り分け用に予約されています。別の名前を選んでください。
- `watchlist: true` を設定できるエントリは 1 つまでです。
- 同じエントリで `watchlist: true` と `add_torrents: false` を両方設定することはできません。設定すると拒否されます。
- 有効な `nzb` または `torbox_nzb` エントリは 1 つだけサポートされています。追加のニュースサーバーは、`nzb` エントリの `nntp.servers` に記述してください。
- すべてのエントリが無効になっていると、読み込みに失敗します。
- Premiumize、Debrid-Link、Offcloud では、`download_tokens` と、`token` と異なる `strm_link_token` は使えません。ファイル ID が 1 つのアカウントに紐づいているため、2 つ目のアカウントは別のエントリとして追加する必要があります。

## 正しく動いたか確認する {#check-it-worked}

```bash
docker compose logs -f --tail=100 zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`WARN service zurg is not installed` は、Docker では想定どおりの表示です。自動起動は Compose が管理しているためです。警告があっても doctor は失敗しません。失敗するのは `FAIL` のときだけです。

次に、アカウント自体を Dashboard かシェルから確認します。

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
```

`{"success":true}` が返れば、認証情報は通っています。パスに出てくる名前はアカウントの `name` です。デフォルトでは `type` が使われます。`config.yml` に `username` を設定している場合は、`-u user:pass` を追加してください。設定していなければ、公開したポートで Dashboard とその API が開いたままになります。

最後に、マウント上のライブラリを見てみましょう。

```bash
ls /zurg_mnt/zurg/__all__/
```

設定したアカウントごとに `__<name>__` ディレクトリが作られます。そのアカウントが持つすべてのデータが入っており、読み込み先もそのアカウントに固定されます。`__torbox__/Some.Release/` は TorBox からだけ配信され、他からは取得しません。単一アカウントのフォルダは、マウントのルート一覧からは外されています。`__all__` と同じライブラリだからです。`/http/__torbox__/` のような直接の HTTP や WebDAV パスは、今も応答します。ただし、マウント経由ではもう解決されません。`__<name>__` を使っていたライブラリやスクリプトは、`__all__` に向け直してください。

大きなライブラリは、最初の読み込みに時間がかかります。読み込みが終わるまで `/dav/movies/` は 503 を返し、マウントは何も一覧表示しないこともあります。

## 複数のアカウントを動かす {#running-several-accounts}

`providers:` リストの順序は、追加(adds)を受け付けるアカウントを試す順番です。`watchlist: true` のアカウントは、リスト内のどの位置にあっても最初に試されます。一覧表示や読み取りの場合は、順序は関係ありません。

media server に向ける前に知っておくとよいことが 2 つあります。

- 同じリリースは、フィルタ済みのディレクトリ**と**、それを持つすべての `__<name>__` ディレクトリに表示されます。Plex や Jellyfin は、マウント全体ではなく一部のディレクトリを指定してください。全体を指定すると、同じコンテンツを何度もスキャンしてしまいます。
- `__<name>__` ディレクトリの中では、黙って別のアカウントに切り替える仕組みはありません。あるアカウントで無効になったファイルは、そのディレクトリでは 404 になります。別のアカウントのディレクトリでは再生できます。マウントの残りの部分は、通常どおり配信されます。
