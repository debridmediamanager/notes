# Whisparr

Whisparr は、アダルト映画やシーン向けの Radarr です。qBittorrent クライアントとして zurg を使います。取得したものは、あなたの debrid アカウントに送られます。インポートは `__magic__` 内のパスの名前を変えるだけです。何もダウンロードもコピーもされません。

以下はすべて、2026-10-23 に次の環境でテストしました。Whisparr `3.6.5.1886`（`ghcr.io/hotio/whisparr:v3` イメージ）、Prowlarr、その日の `main` からビルドした zurg、そして Real-Debrid アカウントです。17 GB の映画を取得し、インポートして、マウントから再生しました。

## 始める前に {#before-you-start}

まずは Radarr 用に zurg を設定しましょう。[Sonarr と Radarr（トレント用）](sonarr-radarr-torrents.md)の手順に沿って、トレントを受け付けるアカウントを用意し、`__magic__` と qBittorrent エンドポイントをオンにしてください。Whisparr も同じ設定をそのまま使えます。

## 1. zurg での Whisparr のカテゴリ {#1-whisparrs-category-in-zurg}

Whisparr は取得リクエストを `whisparr` というカテゴリで送信します。3番目の手順にある **Test** ボタンを押すと、zurg にそのカテゴリが作成されるので、追加の作業は必要ありません。それでも `config.yml` に記載したい場合は、既存のカテゴリの横に追加してください:

```yaml
qbittorrent:
  enabled: true
  categories: [tv-sonarr, radarr, whisparr]
```

## 2. Whisparr を起動 {#2-run-whisparr}

Linux ホストでは、Radarr と同じボリュームを Whisparr にも渡します。zurg のマウントの**上**にあるフォルダを `rslave` 付きで渡してください（[理由](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)）:

```yaml
services:
  whisparr:
    image: ghcr.io/hotio/whisparr:v3
    container_name: whisparr
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - ./whisparr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6969:6969
    restart: unless-stopped
```

`PUID` と `PGID` は、Whisparr が実行される Linux ユーザーの ID です。zurg の公式 Docker イメージでは、どのユーザーでもマウントを読めます。通常のバイナリとしてインストールした zurg は、root で実行しているか `user_allow_other` を有効にしている場合だけ読めます（[Linux セットアップ](../setup/linux.md#1-install-fuse-3)）。そうでない場合は、`PUID` と `PGID` を zurg を実行しているユーザーに設定してください（`id -u` と `id -g` で確認できます）。そうしないと、Whisparr からマウントが空に見えます。

macOS と Windows ではこの compose ファイルは使えません。理由は [Usenet ガイドのステップ8](sonarr-radarr.md#8-if-your-arr-is-in-docker) に書いてあります。そちらでは通常のアプリとして Whisparr をインストールしてください。注意点は、そのガイドの [始める前に](sonarr-radarr.md#before-you-start) に載っています。macOS では zurg と同じユーザーで実行すること、Windows では Windows サービスではなくトレイアプリを使うことです。テストしたのは上記の Docker イメージだけです。

ブラウザで `http://<your server>:6969` を開きます。

## 3. zurg をダウンロードクライアントとして追加 {#3-add-zurg-as-the-download-client}

**Settings → Download Clients → + → qBittorrent** で、Radarr と同じように入力します（[項目一覧](sonarr-radarr-torrents.md#what-to-put-in-each-field)）。ただし **Category** は `whisparr` にします。**Remove Completed** はオンのままにしておいてください。**Test** を押して、最後に **Save** を押します。

## 4. ルートフォルダーを追加 {#4-add-the-root-folder}

マウント上にフォルダを作成してから、**Settings → Media Management → Root Folders** に追加します:

+++ Linux

```bash
mkdir -p /mnt/zurg/__magic__/whisparr
```

+++ macOS

```bash
mkdir -p /Volumes/Zurg/__magic__/whisparr
```

+++ Windows

```powershell
New-Item -ItemType Directory -Force Z:\__magic__\whisparr
```

+++

このフォルダは `__magic__/movies` の中ではなく、その横に作ります。Whisparr は各作品をスタジオごとに分けて保存します。形式は `__magic__/whisparr/movies/<Studio>/<Title (Year)>/` です。

## 5. インデクサー {#5-indexers}

DMMのインデクサーにはアダルトカテゴリがないため、Whisparrでは別のインデクサーが必要です。Prowlarrでは、パブリックインデクサーの**Knaben**と**The Pirate Bay**はどちらも動作しました。**XXXClub**はCloudflareの背後にあり、CloudflareソルバーなしではProwlarrに追加できません。

次に、Prowlarrの**Settings → Apps → + → Whisparr**でProwlarrとWhisparrを接続します。Whisparrのアドレスと APIキーは、Whisparrの**Settings → General**で確認できます。Prowlarrは、インデクサーをWhisparr自体に追加します。

zurgは、アカウントにすでにあるリリースだけを受け付けます（`cached_only`、デフォルトでオン）。zurgが拒否した場合、Whisparrは次の検索結果を取得します。

## 6. 1 つ取得する {#6-grab-one}

Whisparrで映画を追加し、**Start search for missing movie** にチェックを入れます。うまくいくと、Whisparrの履歴に数秒以内に **Grabbed** のあと **Imported** と表示され、マウントに映画が現れます:

```bash
$ ls "/mnt/zurg/__magic__/whisparr/movies/<Studio>/<Title (Year)>/"
<Title> 1080p.mkv
```

macOSでは、パスは `/Volumes/Zurg` で始まります。Windowsでは、Explorerで `Z:\__magic__\whisparr\movies` を開いて確認してください。zurgの `data/local` フォルダには何も入りません。ファイルはあなたのアカウントからストリーミングされます。

## 視聴する {#watching-it}

Plex や Jellyfin のライブラリを `/mnt/zurg/__magic__/whisparr`（macOS では `/Volumes/Zurg/__magic__/whisparr`、Windows では `Z:\__magic__\whisparr`）に向けると、これらの作品を専用のライブラリにまとめておけます。

rex では、他のリリースと同じように zurg のフォルダ構成に従ってどのライブラリに入るかが決まります。ほとんどの環境では、それは映画ライブラリになります。
