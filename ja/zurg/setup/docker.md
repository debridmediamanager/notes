# Docker でのセットアップ {#docker-setup}

このガイドでは、zurg を Docker で動かし、その FUSE マウントを Linux ホストで公開します。Docker が zurg、rclone、ffprobe を用意してくれます。組み込みの `setup` コマンドで設定ファイルを作成します。`doctor` はインストールを確認するためのコマンドです。

この手順は2026年9月4日に Docker Engine 29.1.1 で動作確認しました。下にある provider の選択画面を表示させるため、最新の日付付き nightly を使ってください。

> **Sponsor 専用イメージ:** `ghcr.io/debridmediamanager/zurg` は sponsor 向けです。[gatekeeper](https://gatekeeper.debridmediamanager.com/) で sponsor になってください。これで GitHub アカウントがこのイメージを使えるようになります。

> **Linux ホストが必要:** 下のホスト側マウントは Linux のマウント伝播（mount propagation）に依存します。Docker Desktop は macOS と Windows でコンテナを VM の中で動かすため、この FUSE マウントを Finder や Explorer に伝播できません。rex も VM 内の zurg に接続できないので、何も再生できません。どちらのホストでも [macOS](https://notes.debridmediamanager.com/ja/zurg/setup/macos/) または [Windows](https://notes.debridmediamanager.com/ja/zurg/setup/windows/) のバイナリ向けガイドを使ってください。rex を別のマシンで動かす Linux の場合は、[rex と zurg の連携](../../rex/with-zurg.md#d4-connect-zurg-to-rex) で示されているとおり、zurg コンテナに `network_mode: host` を設定してください。

## ワンライン オプション {#one-line-option}

On a fresh Linux host, the optional bootstrap can install Docker when you approve it, set up persistent FUSE mount propagation, log in to the sponsor registry, write the Compose project, run the provider chooser, and verify the result:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Existing Compose files and configs are preserved. The sections below show every step for those who prefer the manual route.

## コンテナ内でインストーラーが行うこと {#what-the-installer-does-in-a-container}

これらのフラグは意図的に付けています:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

- `setup` は設定するプロバイダーを尋ね、そのプロバイダーの認証情報だけを入力させ、`0600` のモードで `config.yml` を書き出します。
- `--no-service` は自動起動を Docker の `restart: unless-stopped` ポリシーに任せます。Alpine に systemd を入れようとはしません。
- `--skip-downloads` は、イメージにすでに入っている rclone と ffprobe をそのまま使います。
- `--mount-path` は、FUSE マウントをホストに伝播させるサブディレクトリを記録します。

setup は何度実行しても安全です。インストールの検証と更新は行いますが、既存の `config.yml` は置き換えません。

## 1. Docker をインストールしてイメージのロックを解除 {#1-install-docker-and-unlock-the-image}

Linux ホストに Docker Engine と Compose プラグインをインストールしてください。次に進む前に、両方のコマンドを確認してください:

```bash
docker version
docker compose version
```

GitHub のユーザー名を使って GitHub Container Registry にサインインします。パスワードを求められたら、`read:packages` と `repo` の両方のスコープを持つ classic パーソナルアクセストークンを貼り付けてください。このイメージはプライベートリポジトリにあるため、`read:packages` だけのトークンではログインはできても、pull に失敗することがあります:

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

`ZURG_TAG` には、最新の日付付きスポンサーリリースを設定してください。`.env` に書いておくと、戻せるバージョンが分かり、アップグレードも明示的になります:

```bash
printf 'ZURG_TAG=YYYY.MM.DD.HHMM-nightly\n' > .env
```

次に進む前に、プレースホルダーを実際のリリースタグに置き換えてください。

## 2. FUSE マウントの伝播を準備 {#2-prepare-fuse-mount-propagation}

FUSE マウントは、共有の親マウントの下に作成する必要があります。最初のコンテナを起動する前に、一度だけ次を実行してください:

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

デバイスとプロパゲーションモードを確認します:

```bash
test -c /dev/fuse
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

2つ目のコマンドの `PROPAGATION` の欄に `shared` と表示されていれば OK です。

## 3. Compose プロジェクトを作成 {#3-create-the-compose-project}

```bash
mkdir -p ~/zurg
cd ~/zurg
```

`docker-compose.yml` を作成します:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:${ZURG_TAG}
    container_name: zurg
    restart: unless-stopped
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    ports:
      - 9999:9999
    volumes:
      - ./:/config
      - /zurg_mnt:/zurg_mnt:rshared
```

`privileged: true` は必要ありません。マウントに使われるのは、FUSE デバイス、`SYS_ADMIN` ケーパビリティ、unconfined の AppArmor プロファイルという、より狭い範囲の設定です。

`/zurg_mnt/zurg` を直接バインドしないでください。FUSE マウントは `rshared` バインドの子である必要があり、そうしないとマウントイベントがホストに届きません。

マウントを読み取るコンテナ、特に Sonarr と Radarr も、反対側から同じルールに従います。親の `/zurg_mnt` を `rslave` で一度だけバインドし、すべてのフォルダをその一つのバインド経由でたどってください。`__magic__/__all__` と `__magic__/tv` を \*arr に 2 つのボリュームとしてバインドすると、インポートのたびにファイル全体のコピーが作られてしまいます。詳しくは [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) を参照してください。

## 4. 組み込みのセットアップを実行 {#4-run-the-built-in-setup}

`~/zurg` から次を実行します:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

優先順位の高い順に、プロバイダーを 1 つ以上選びます。たとえば、TorBox の後に Usenet を使う場合は `2,4` と入力します。セットアップでは認証情報だけを尋ねられ、`~/zurg` に `config.yml` を作成し、rclone を有効にして `/zurg_mnt/zurg` を作成します。認証情報が compose ファイルやシェルの履歴に保存されることはありません。

自動化する場合は、`--provider` を繰り返し指定し、プロバイダーごとの token-file または `--nntp-*` フラグを渡します。セットアップは、後の実行時に既存の設定を残します。

アカウントが書き込まれるのは `config.yml` を作成する実行時だけです。すでに設定があるインストールに追加するには、Dashboard の **Add provider** を使うか、ファイルを編集してから再起動してください。各サービスには、認証情報、設定ブロック、知っておくと良い制限をまとめたページがあります: [プロバイダー](../providers/index.md)。

## 5. zurg を起動 {#5-start-zurg}

```bash
docker compose up -d
docker compose logs -f --tail=100 zurg
```

`Ctrl+C` でログ表示を終了できます。コンテナは動き続けます。Dashboard は `http://localhost:9999/config/` にあり、compose ファイルと同じ場所にある `config.yml` を編集します。

ライブラリが大きいと、読み込みに時間がかかることがあります。読み込みが終わるまで、マウント内のフォルダは一覧を取得できません。そのあいだ、フォルダは空に見えたり `Input/output error` と表示されたりします。一方で Dashboard と `version.txt` は普通に動きます。これは zurg がまだ読み込み中という意味で、マウントが壊れているわけではありません。読み込みが終わったかどうかの見分け方は [起動中と準備完了の違い](#up-versus-ready) で説明しています。

## 6. doctor で検証 {#6-verify-with-doctor}

ライブラリの準備ができたら、バイナリインストールで使うのと同じ診断ツールを実行します:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`doctor` は、設定ファイルとそのパーミッション、ffprobe、rclone、FUSE、HTTP エンドポイント、そして zurg が報告するマウントを確認します。Docker では `WARN service zurg is not installed` と表示されるのが正常です。自動起動は Compose が管理しているためです。WARN があってもコマンドは失敗しません。`FAIL` が出た場合のみ失敗します。

コンテナの外からも、伝播されたマウントが見えることを確認します:

```bash
cat /zurg_mnt/zurg/version.txt
ls -la /zurg_mnt/zurg/
```

## 7. 共有の親ディレクトリを再起動後も維持する {#7-make-the-shared-parent-survive-reboots}

手順 2 のセルフバインドは、再起動すると維持されません。ホストに systemd の oneshot ユニットを作成してください:

```bash
sudo tee /etc/systemd/system/rshared-zurg-mnt.service << 'EOF'
[Unit]
Description=Make /zurg_mnt rshared for Docker FUSE mounts
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "mount --bind /zurg_mnt /zurg_mnt && mount --make-rshared /zurg_mnt"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable rshared-zurg-mnt.service
```

次回の再起動時には、Docker が zurg コンテナを復元する前に、ホストが共有の親ディレクトリを準備します。

## Up と ready の違い {#up-versus-ready}

zurg は HTTP で 2 種類の問い合わせに答えます。`username` を設定していても、どちらもパスワードは不要です。

| アドレス | 200 を返すタイミング | ライブラリの読み込み中 |
|---|---|---|
| `/http/version.txt` | zurg が起動している | 200 |
| `/ready` | ライブラリの読み込みが完了している | `Retry-After: 5` 付きの 503 |

コンテナのヘルスチェックは最初のアドレスを使います。zurg が起動するとすぐに、`docker compose ps` で `healthy` と表示されます。ただ、ライブラリが大きいと、その後もかなり長く読み込みが続くことがあります。ライブラリ全体が必要なときは `/ready` に問い合わせてください。読み込みが終わると `ready` と表示されます。

```bash
curl -fsS http://localhost:9999/ready
docker compose exec zurg /app/healthcheck.sh --ready && echo ready
```

スクリプトでは次のように待機できます。

```bash
until curl -fsS http://localhost:9999/ready >/dev/null; do sleep 10; done
```

### ヘルスチェックがライブラリを待たない理由 {#why-the-health-check-does-not-wait-for-the-library}

Docker は、コンテナごとに 1 つのヘルス状態を保持しています。それを読むツールは、これを「zurg が生きているか」という意味だと受け取ります。autoheal と Docker Swarm は、unhealthy になったコンテナを再起動します。`condition: service_healthy` を付けた `depends_on` は、zurg が healthy になるまで他のサービスを待たせます。

大きなライブラリでは、コールドスタートに 15 分から 90 分かかったという報告があります。ヘルスチェックがライブラリの読み込みを待つ設計だと、依存するサービスはすべてその時間ずっと止まってしまいます。zurg の前に rclone コンテナを置くと、その間ずっとマウントフォルダーが空のままになります。メディアサーバーから見ると、空のフォルダーはライブラリが削除されたように見えます。さらに、読み込みがヘルスチェックのリトライ回数を超えて続くと、そのコンテナも unhealthy と判定されます。unhealthy のコンテナを再起動する仕組みがあると、読み込みは最初からやり直しになります。そうなると、読み込みは永遠に終わりません。

### Compose で readiness を使う {#using-readiness-with-compose}

マウント用のコンテナは、デフォルトのヘルスチェックのままにしておくと便利です。そうすれば、zurg が起動するとすぐにマウントが立ち上がります。

```yaml
services:
  rclone:
    depends_on:
      zurg:
        condition: service_healthy
```

ライブラリ全体を必要とするもの（スキャンスクリプトやインポートジョブなど）では、`/ready` を待つようにしてください。

zurg コンテナ自体を、ライブラリの読み込みが終わってから初めて healthy を返すようにすることもできます。`docker-compose.yml` でそのコンテナのヘルスチェックを上書きし、`start_period` を最も遅い読み込み時間より長く設定してください。Docker は start_period 内の失敗をカウントしません。こうすると、zurg に依存するサービスも、ライブラリの準備ができるまで待つようになります。これは autoheal と組み合わせないでください。

```yaml
services:
  zurg:
    healthcheck:
      test: ["CMD", "/app/healthcheck.sh", "--ready"]
      interval: 30s
      timeout: 10s
      start_period: 3h
      retries: 3
```

## zurg の管理と更新 {#managing-and-updating-zurg}

`~/zurg` のディレクトリで次のコマンドを実行してください:

```bash
docker compose ps
docker compose logs -f --tail=100 zurg
docker compose restart zurg
docker compose stop zurg
docker compose start zurg
```

compose プロジェクトは `.env` の `ZURG_TAG` を参照しています。インストーラーがこれを `latest` に設定しているので、pull すると常に最新の nightly が取得されます。アップグレードするには、イメージを pull してコンテナを作り直し、その後 doctor を実行してください:

```bash
docker compose pull zurg
docker compose up -d zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

ここでは `zurg update` は使わないでください。コンテナの中では実行を拒否されます。書き込まれるバイナリはコンテナのレイヤーに置かれるため、コンテナを作り直した瞬間に消えてしまいます。そうなると次の `up` で、気づかないうちに古いビルドに戻ってしまいます。代わりにイメージを pull してください。残しておくつもりのコンテナなら、`--force` を付ければ拒否を回避できます。

前のバージョンに戻すには、`.env` の `ZURG_TAG` を特定の nightly タグに設定して、上の 3 つのコマンドをもう一度実行してください。バインドマウントされた設定、ライブラリの状態、ログ、キャッシュは、コンテナと一緒に移動したりはしません。

`docker compose down` はコンテナとネットワークを削除しますが、`~/zurg` にあるバインドマウントのファイルと、マウント元の親ディレクトリ `/zurg_mnt` はそのまま残します。

## 各データの保存場所 {#what-lives-where}

zurg が書き込むものはすべて `/config` を基準に解決されるので、`./:/config` の単一のバインドでインストール全体をまとめて保持します。

| パス | 内容 |
|---|---|
| `config.yml` | 設定とプロバイダーの認証情報。Dashboard での編集はここに書き戻されます |
| `data/` | ライブラリの状態、ローカルファイル、生成されたキー、rclone VFS キャッシュ |
| `logs/` | zurg と rclone のログ |
| `dump/` | 有効にした場合のトレントダンプ |
| `strm/` | `save_strm_files` が有効なときの `.strm` ファイル |
| `nzbs/` | Usenet バックエンド用の監視ディレクトリ |

イメージを pull したり再作成したりしても、これらのファイルは一切変わりません。

`data/rclone-cache` は増え続けるほうです。マウントは読み込んだファイルをすべて完全にダウンロードし、再生が終わったあとも保持します。デフォルトでは **256G** まで使われるので、バインドのディレクトリには他のものに加えてキャッシュ分の空き容量が必要です。72 時間の経過期限は、実際には上限としてはたらきません。メディアサーバーの夜間スキャンを含め、ライブラリを読み取るものはすべてファイルに触れた扱いになります。

```bash
du -sh ./data/rclone-cache
```

ホストのディスクにそれだけの余裕がない場合は、`config.yml` で上限を下げてください:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

`/config` に対応するホスト側のパスを変更すると、キャッシュの名前が変わり、古いコピーが取り残されます。zurg は次回の起動時に取り残されたツリーを回収し、解放した内容をログに記録します。詳しくは [config.md](../reference/config.md#disk-the-mount-uses) を参照してください。

### 無人インストール向けの環境変数シード {#environment-seeding-for-unattended-installs}

このイメージでは、古い初回起動の方法もまだ使えます。`config.yml` が存在しない場合、`TOKEN` または `RD_TOKEN` でアカウントを設定し、`MOUNT_PATH` でマウントを有効にします。これらの変数は、ファイルを作成するときにだけ読み込まれます。それ以降の起動では、常にファイルの設定が優先されます。

この方法で実行中のコンテナが設定できるアカウントは Real-Debrid だけです。`TORBOX_TOKEN`、`ALLDEBRID_TOKEN`、`PREMIUMIZE_TOKEN`、`DEBRIDLINK_TOKEN`、`OFFCLOUD_TOKEN`、`NNTP_HOST` は `zurg setup` で読み込まれます。そのため、これらは上記のワンショットのセットアップコンテナでのみ有効になり、サービスの `environment:` ブロックに書いても何の効果もありません。

ターミナルの前で操作する場合は、対話式の `setup` コマンドがおすすめです。トークンが compose ファイルに書き込まれることがないからです。環境変数による設定は、すでにシークレットストアを使っている自動化には引き続き便利です。

### `/app` をマウントしていたインストールのアップグレード {#upgrading-an-install-that-mounted-app}

古い compose プロジェクトでは、`/app/config.yml`、`/app/data` などのパスをそれぞれ個別にバインドマウントしていました。エントリポイントは、そのレイアウトを見つけると今でも `/app` を選んでしまいます。そのため、新しいイメージを pull しても、古い設定とキャッシュがそのまま使われ続けます。

単一フォルダのレイアウトに移行するには、まずコンテナを停止します。次に、既存の `config.yml`、`data/` などの状態ディレクトリをすべて、ホスト上の 1 つのディレクトリにコピーします。最後に、そのディレクトリを `/config` にバインドします。

## トラブルシューティング {#troubleshooting}

まず診断と現在のログを確認しましょう：

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
docker compose logs --tail=200 zurg
```

### `unknown command "setup"` または `unknown command "doctor"` {#unknown-command-setup-or-unknown-command-doctor}

このコンテナは、組み込みインストーラーが入る前のものです。`2026.09.04.1449-nightly` か、それより新しい日付付きの zurg イメージを使ってから、コンテナを作り直してください：

```bash
docker compose pull zurg
docker compose up -d zurg
```

### `Transport endpoint is not connected`

古い FUSE マウントが残ったままになっています:

```bash
sudo umount -l /zurg_mnt/zurg
docker compose restart zurg
```

### FUSE デバイスが利用できない {#fuse-device-is-unavailable}

今すぐモジュールを読み込み、次回以降の起動時にも読み込まれるようにします:

```bash
sudo modprobe fuse
echo fuse | sudo tee /etc/modules-load.d/fuse.conf
```

そのあと、composeサービスに `/dev/fuse`、`SYS_ADMIN`、AppArmorの設定がまだ含まれているか確認してください。

### マウントが空 {#mount-is-empty}

順番にそれぞれのレイヤーを確認してください:

```bash
docker compose logs zurg 2>&1 | grep -i rclone
docker compose exec zurg ls -la /zurg_mnt/zurg
curl -fsS http://localhost:9999/http/version.txt
curl -fsS http://localhost:9999/ready
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

ホストのパスは shared bind mount になっている必要があります。また、compose の volume で親フォルダを `/zurg_mnt:/zurg_mnt:rshared` としてバインドしてください。

`/ready` がエラー 503 で失敗する場合、ライブラリはまだ読み込み中で、マウントは問題ありません。読み込みが終わるまで、フォルダは空として表示されたり、`Input/output error` と表示されたりします。zurg を再起動する代わりに、そのまま待ってください。再起動すると、読み込みが最初からやり直しになります。

### `mount` の出力にマウントが 2 回表示される {#mount-appears-twice-in-mount-output}

それは正常です。伝播が機能しているため、同じ FUSE マウントがコンテナ側とホスト側のマウント名前空間の両方から見えています。

まだ行き詰まっていますか？ [Discord](https://discord.com/invite/7u4YjMThXP) の **zurg-support** フォーラムで聞いてください。何を含めればよいかは [サポートの受け方](../../guides/remote-help.md) に書かれています。
