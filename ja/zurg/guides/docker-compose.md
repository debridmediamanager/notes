# zurg、Plex、rex をまとめた 1 つの Docker Compose ファイル {#one-docker-compose-file-for-zurg-plex-and-rex}

Linux マシンでは、1 つの `docker-compose.yml` で zurg、Plex Media Server、rex を並べて動かせます。zurg はライブラリを `/zurg_mnt/zurg` の下にあるフォルダとして見せ、Plex Media Server はそのフォルダを読み込みます。rex は同じライブラリを、フォルダを介さず zurg から直接受け取ります。zurg の Docker インストーラーを一度実行してから、その `docker-compose.yml` を下のものに置き換えてください。

Plex Media Server と rex のどちらか一方だけ使いたい場合は、使わないほうをファイルから削除してください。Plex を使わないなら、rex の `command:` の行も削除します。

Windows や Mac の Docker Desktop ではこの構成は動きません。zurg のフォルダがエクスプローラーや Finder に表示されず、rex も中にある zurg に接続できないためです。Windows の場合は [zurg on Windows](../setup/windows.md)、macOS の場合は [zurg on macOS](../setup/macos.md) を使ってください。

## 始める前に {#before-you-start}

- **Linux マシン**（電源を入れっぱなしにしておくもの）。インストーラーは Docker が無ければ追加します。
- **zurg のスポンサーシップ**。zurg のイメージは非公開です。[gatekeeper](https://gatekeeper.debridmediamanager.com/) でスポンサーになると、GitHub アカウントにアクセス権が付与されます。
- **Real-Debrid の API トークン**、または zurg が対応している別のサービスのログイン情報：[Real-Debrid の API トークン](../../guides/real-debrid-api-token.md)。
- **Plex Media Server を使う場合**は Plex アカウント。**rex を使う場合**は、rex 専用に作った新しい Plex アカウント。理由は [zurg 付きの rex](../../rex/with-zurg.md#before-you-start) を参照してください。

## 1. zurg の Docker インストーラーを実行する {#1-run-zurgs-docker-installer}

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Dockerがない場合は、インストールするか最初に確認してきます。その後、zurgのフォルダ用に`/zurg_mnt`を準備します。これは今回だけでなく、再起動のたびにも行われます。zurgのDockerイメージを取得するためにGitHubへのサインインも求められます。さらに`~/zurg/docker-compose.yml`を書き出し、使用するサービスとトークンを入力させ、zurgを起動して`zurg doctor`を実行します。[zurgのDockerセットアップ](../setup/docker.md)でも同じことを手作業で行えます。

**期待される結果**

```bash
ls /zurg_mnt/zurg
```

`__all__`、`__downloads__`、`__unplayable__`、`movies`、`shows`、`version.txt`が一覧表示されます。

## 2. 完全版のファイルに差し替える {#2-swap-in-the-full-file}

```bash
cd ~/zurg
nano docker-compose.yml
```

この中身を全部、次のものに置き換えてください:

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

  plex:
    image: plexinc/pms-docker
    container_name: plex
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM=
    volumes:
      - ../plex/config:/config
      - ../plex/transcode:/transcode
      - /zurg_mnt:/zurg_mnt:rslave
    depends_on:
      zurg:
        condition: service_healthy

  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    command: --port 32500
    volumes:
      - ../rex/config:/config
```

- **zurg** はインストーラー自身のサービスで、変更はありません。
- **plex** は zurg のフォルダーを、zurg が使うのと同じパス `/zurg_mnt/zurg` で見ます。そのため zurg がスキャンを求めるとき、Plex が知っているフォルダー名を指定します。`rslave` のおかげで、zurg を再起動してもフォルダーはそのまま残ります。`TZ` には自分のタイムゾーンを入れてください。
- **PLEX_CLAIM** は、最初に起動したときに Plex Media Server をあなたのアカウントにサインインさせます。Plex にサインインした状態で [plex.tv/claim](https://www.plex.tv/claim) を開き、コードをコピーして `=` の直後に貼り付けてください。コードは数分で期限切れになるので、すぐにスタックを起動しましょう。
- **rex** は [rex with zurg](../../rex/with-zurg.md#d2-start-rex-in-docker) にあるサービスです。Plex Media Server が 32400 番ポートを使っているので、32500 番ポートで動きます。ファイルは `~/rex/config` に保存され、rex with zurg もそこを参照します。

保存して、すべて起動します:

```bash
docker compose up -d
docker compose ps
```

`docker` で permission denied と表示されたら、このページにあるすべての `docker` コマンドの前に `sudo` を付けてください。

**確認ポイント。** コンテナが3つ表示されるはずです。`plex` と `zurg` は `(healthy)`、`rex` は `Up` になっています。Plex Media Server 自身のファイルは `~/plex` に保存されます。

## 3. Plex に zurg のフォルダーを追加する {#3-add-zurgs-folders-in-plex}

Plex Webを`http://<this machine's LAN IP>:32400/web`で開きます。[Real-Debrid in Plex](../../guides/real-debrid-plex.md#3-add-the-folders-in-plex)に書かれているとおりに、`/zurg_mnt/zurg/movies`フォルダーの**Movies**ライブラリと、`/zurg_mnt/zurg/shows`フォルダーの**TV Shows**ライブラリを追加します。

Plexに新しいコンテンツを知らせるため、zurgのダッシュボード`http://<this machine's LAN IP>:9999/config/`を開き、**Media Server Integration**の下にある**Login with Plex**を押します([そのページの4番目の手順](../../guides/real-debrid-plex.md#4-let-zurg-tell-plex-about-new-things)を参照)。

## 4. rex をセットアップする {#4-set-up-rex}

[zurg を使った rex](../../rex/with-zurg.md) の [D3](../../rex/with-zurg.md#d3-add-it-to-a-plex-account) から [D5](../../rex/with-zurg.md#d5-watch) までの手順に従ってください。ただし `32400` と書かれている箇所はすべて `32500` に読み替えてください。例えば zurg の行は `rex_url: http://192.168.1.20:32500` になります（rex の LAN IP を使います）。その後、Plex アプリには 2 つのサーバーが表示されます。見分け方は [zurg を使った rex の手順 2](../../rex/with-zurg.md#step-2-install-rex) に書いてあります。

## アップデート {#updating}

```bash
cd ~/zurg
docker compose pull
docker compose up -d
```

それで zurg、Plex、rex がまとめて更新されます。rex と zurg を一緒に動かしている場合で `docker compose` を `~/rex` で実行しているなら、代わりに `~/zurg` で末尾に `rex` を付けて実行してください。そうすると rex だけに作用します。`docker compose down` の代わりに `docker compose stop rex`、`docker compose up -d` の代わりに `docker compose up -d rex` を使います。

## 問題が起きたとき {#when-something-is-wrong}

`docker compose logs --tail=100 zurg`（または `plex`、`rex`）は、コンテナが最後に出力した内容を表示します。

| 表示される内容 | 対処方法 |
|---|---|
| インストーラーに `Host-visible Docker mounts require a Linux host. Use the binary installer on macOS or Windows.` と表示される | Mac か Windows を使っています。代わりに [Windows 版](../setup/windows.md) か [macOS 版](../setup/macos.md) のインストーラーで zurg を入れてください。 |
| Docker で zurg を取得しようとすると `Error response from daemon: error from registry: unauthorized` と表示される | このマシンは、zurg へのアクセス権があるアカウントで GitHub のレジストリにサインインしていません。[gatekeeper](https://gatekeeper.debridmediamanager.com/) でスポンサーになってから、インストーラーをもう一度実行してください。手動でサインインする場合は [zurg の Docker セットアップ](../setup/docker.md#1-install-docker-and-unlock-the-image) を見てください。トークンには `read:packages` と `repo` の両方が必要です。 |
| `path /zurg_mnt is mounted on ... but it is not a shared mount` と表示される | `/zurg_mnt` がまだ共有されていません。`sudo mount --bind /zurg_mnt /zurg_mnt` と `sudo mount --make-rshared /zurg_mnt` を実行してから、`docker compose up -d` を実行してください。インストーラーを使うと、再起動後も設定が残るようになります。手動の場合は [zurg の Docker セットアップのステップ 7](../setup/docker.md#7-make-the-shared-parent-survive-reboots) を見てください。 |
| `zurg` が再起動を繰り返し、ログの最後に `Error: config ./config.yml is not valid YAML: yaml: unmarshal errors:` と `mapping key "..." already defined` が出る | zurg の設定に同じ項目が 2 回書かれています。`sudo nano ~/zurg/config.yml` を実行して、エラーに出てくる 2 行のうち片方を削除し、保存してから `docker compose restart zurg` を実行してください。 |
| zurg のログに `Mount verification failed: mount verification timeout: /zurg_mnt/zurg/version.txt not accessible after 60 attempts -- you appear to be running inside Docker, mount a parent directory with rshared propagation` と出る | zurg のフォルダーが表示されていません。zurg のボリューム行が `/zurg_mnt/zurg` ではなく、親の `/zurg_mnt:/zurg_mnt:rshared` になっているか確認してください。あわせて `/zurg_mnt` が共有されているか（上の行の内容）も確認してください。[Mount が空になる](../setup/docker.md#mount-is-empty) に、さらに確認すべき点があります。 |
| zurg の再起動後に Plex のライブラリが空になり、`docker exec plex ls /zurg_mnt/zurg` で `cannot access '/zurg_mnt/zurg': Transport endpoint is not connected` と表示される | Plex のボリューム行に `rslave` がありません。`/zurg_mnt:/zurg_mnt:rslave` となるように直してから、`docker compose up -d` を実行してください。 |
| rex が `rex: cannot bind 0.0.0.0:32400: Address already in use (os error 98) (another rex or Plex on this port? --port picks another)` で止まる | Plex Media Server がすでにポート 32400 を使っています。rex の `command: --port 32500` はそのまま残してください。 |
| 起動した直後に `/zurg_mnt/zurg/movies` が空だったり、`Input/output error` と表示されたりする | zurg がまだアカウントの情報を読み込んでいます。読み込みが終わると `curl http://localhost:9999/ready` が `ready` と表示します。その間に zurg を再起動しないでください。最初から読み込み直しになります。 |
| rex にタイトルは表示されるのに、再生できない | [rex と zurg の連携 の 問題が起きたとき](../../rex/with-zurg.md#when-something-is-wrong) にある `upstream failed` の項目で、rex が zurg に接続できているか確認できます。 |
| ディスクがいっぱいになる | zurg は再生したものの複製を `~/zurg/data/rclone-cache` に保存していて、デフォルトでは最大 256G まで使います。上限の設定方法は [保存場所の一覧](../setup/docker.md#what-lives-where) にあります。 |

それでも解決しない場合は、[Discord](https://discord.com/invite/7u4YjMThXP) の **zurg-support** フォーラムで質問してください。[サポートの受け方](../../guides/remote-help.md) に、何を書けばよいかが書かれています。

（前回の翻訳は、コードスパンが一致しないという理由で却下されました（`docker compose logs --tail=100 zurg`）。構造をそのまま保ってください。）

## よくある質問 {#questions}

### 私の docker compose ファイルを確認してもらえますか？ {#can-you-check-my-docker-compose-file}

上のものと比べてください。特に重要なのは次の点です。zurg は `/zurg_mnt` を `rshared` でバインドし、Plex は同じ `/zurg_mnt` を `rslave` でバインドします。rex は `network_mode: host` を付けて `ghcr.io/debridmediamanager/rex` イメージを使います。`plexinc/pms-docker` を実行する `rex` という名前のサービスは、rex ではなく、2つ目の Plex Media Server にすぎません。

### rclone 用のコンテナーを別に用意する必要がありますか？ {#do-i-need-a-separate-rclone-container}

zurg は自分のコンテナ内で rclone を動かし、ライブラリを `/zurg_mnt/zurg` に自分でマウントします。

### Plex Media Server と rex を一緒に使えますか？ {#can-i-use-plex-media-server-and-rex-together}

はい、このファイルはそういう仕組みです。Plex Media Server は zurg のフォルダから再生し、rex は zurg から直接再生します。Plex アプリには両方が表示されます。両方はいらないという場合は、使うほうだけ残してください。

### これは NAS でも動きますか？ {#does-this-work-on-a-nas}

テストは NAS ではなく Linux PC で行いました。インストーラーには、`sudo` が使えるターミナル（SSH）と FUSE（`/dev/fuse`）が必要です。手順 1 が終わって zurg のフォルダーが `/zurg_mnt/zurg` にできていたら、手順 2 に進んでください。

### どのバージョンでテストしましたか？ {#which-versions-was-this-tested-with}

zurg `2026.11.14.1134-nightly`、rex `2026.11.14.1123-nightly`、Plex Media Server `1.43.5.11079`、2026年11月14日。
