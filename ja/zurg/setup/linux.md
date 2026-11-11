# Linux バイナリのセットアップ {#linux-binary-setup}

## ワンライン オプション {#one-line-option}

任意のスポンサー向けブートストラップでは、システムパッケージのインストール、お使いのCPUに合ったビルドのダウンロード、セットアップと診断の実行を行います:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

GitHubでサインインし、`~/zurg` にインストールします。既存のバイナリと設定ファイルはそのまま残ります。手動で行う場合やインストール先を変えたい場合は、下記を続けて読んでください。

zurg バイナリは、残りのインストールを自分で完了できます。設定ファイルを書き出し、そのマシンに合った正しいrclone（PATHに既にない場合はffprobeも）をダウンロードし、マウントを作成して、有効化された systemd サービスを登録します。

このフローは2026年9月4日に、まっさらな Ubuntu 24.04 ARM64 と x86_64 サーバーで検証されました。

## 1. FUSE 3 をインストール {#1-install-fuse-3}

Debian、Ubuntu とその派生ディストリビューションでは:

```bash
sudo apt-get update
sudo apt-get install -y fuse3
```

他のディストリビューションでも、パッケージ名は `fuse3` です。Fedora では `sudo dnf install fuse3`、Arch では `sudo pacman -S fuse3`、openSUSE では `sudo zypper install fuse3` を使います。

ヘルパーとデバイスがあるか確認します:

```bash
command -v fusermount3
test -c /dev/fuse
```

Plex や Jellyfin などの別のプロセスが別の Unix ユーザーで動いている場合は、一度だけ `allow_other` を有効にします:

```bash
echo user_allow_other | sudo tee -a /etc/fuse.conf
```

この設定がなくてもマウント自体は動きますが、開けるのは zurg を実行しているアカウントだけです。`zurg doctor` を実行すると、この違いが表示されます。

## 2. zurg をダウンロード {#2-download-zurg}

[スポンサー向けリリース](https://github.com/debridmediamanager/zurg/releases)から、お使いの環境に合う Linux アーカイブをダウンロードしてください。Intel または AMD のマシンなら `linux-amd64`、ARM のマシンなら `linux-arm64` を選びます。

最新のナイトリーを取ってください。リストの一番上にあるプレリリースです。GitHub で **Latest** と表示されているリリースは選ばないでください。それは v1.0.0 で、`zurg setup` より古く、`unknown command` と返ってきます。

ナイトリーはスポンサー向けです。GitHub アカウントにアクセス権が付与されるまで、そのページは 404 を返します。アクセス権を得るには [gatekeeper](https://gatekeeper.debridmediamanager.com/) でスポンサーになってください。無料の公開ビルドは [zurg-public](https://github.com/debridmediamanager/zurg-public/releases) の v1.0.0 です。こちらには `zurg setup` がありません。下の手順に従わず、[その README](https://github.com/debridmediamanager/zurg-public#readme) の説明どおりに手動でセットアップしてください。

インストール全体を置くディレクトリに展開してください:

```bash
mkdir -p ~/zurg
cd ~/zurg
# Put the downloaded zurg binary here, then:
chmod +x zurg
```

zurg が保持するものはすべて、そのバイナリの隣に置かれます。`config.yml`、ダウンロードされたヘルパー、ライブラリの状態、ログ、rclone キャッシュなどです。

## 3. セットアップを実行 {#3-run-setup}

```bash
cd ~/zurg
./zurg setup
```

セットアップでは、どのプロバイダーを設定するか聞かれます。1つまたは複数を、優先順位の順に選んでください:

```text
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
```

例えば、TorBox の次に Usenet を使う場合は `2,4` と入力します。セットアップでは、選んだプロバイダーの認証情報だけを聞かれます。その後、次のことを行います:

1. `config.yml` を作成して検証します。
2. 設定ファイルを所有者だけがアクセスできるように、モード `0600` を設定します。
3. ネイティブ版の rclone を `bin/` にダウンロードします。PATH に ffprobe がすでにない場合は、ffprobe もダウンロードします。
4. `/mnt/zurg` に rclone マウントを有効にします。
5. 有効な systemd サービスをインストールして起動します。

`/mnt/zurg` を作成する権限がない場合は、ホームディレクトリ内のマウント先を使ってください:

```bash
./zurg setup --mount-path "$HOME/zurg-mount"
```

セットアップは何度実行しても安全です。生成されたサービスは更新されますが、既存の `config.yml` は置き換えられません。

### systemd のスコープを選ぶ {#choosing-the-systemd-scope}

systemd のユーザーマネージャーが動いている場合、デフォルトの `auto` スコープでは `~/.config/systemd/user/zurg.service` がインストールされます。動いていない場合は、`/etc/systemd/system/zurg.service` がインストールされ、現在のユーザーとして実行するために sudo を求められます。

必要に応じて、明示的に選んでください:

```bash
./zurg setup --service-scope user
./zurg setup --service-scope system --service-user "$USER"
```

再起動後、ユーザーサービスを最初にログインする前から起動させたい場合は、lingering を有効にしてください:

```bash
loginctl show-user "$USER" -p Linger
sudo loginctl enable-linger "$USER"
```

サーバーで `root` としてセットアップを実行すると、root が所有するシステムサービスが選ばれます。

## 4. インストールを確認 {#4-verify-the-install}

```bash
./zurg doctor
curl -fsS http://127.0.0.1:9999/http/version.txt
ls /mnt/zurg/version.txt
```

`doctor` は、設定ファイルとそのパーミッション、ダウンロード済みの両方のツール、FUSE、systemd ユニット、HTTP エンドポイント、そして zurg が報告するマウントをチェックします。

Real-Debrid のライブラリが大きいと、初回実行時の構築に時間がかかります。サービスはすでにアクティブになっていても、最初のマウント一覧はそのスキャンが終わるまで待つことがあります。

`version.txt` は zurg が起動するとすぐに応答します。ライブラリが大きい場合、その後も読み込みが続きます。終わるまでは、フォルダが空に見えたり `Input/output error` と表示されたりします。読み込みが完了したかどうかは `/ready` で確認できます。

```bash
curl -fsS http://127.0.0.1:9999/ready
```

## マウントが使うディスク {#disk-the-mount-uses}

マウントは読み込んだファイルをすべて `~/zurg/data/rclone-cache` の下にキャッシュします。再生が終わっても、ファイル全体をそのまま保持します。

放置すると、そのキャッシュは **256G** まで増え続け、そのまま残ります。動画を止めてもキャッシュはクリアされません。72h の経過期限でも解決しません。rclone はファイルが読まれるたびに「アクセスあり」と数えるため、メディアサーバーの夜間メンテナンスがライブラリ全体を読むと、期限がリセットされてしまいます。

中身を確認してください。

```bash
du -sh ~/zurg/data/rclone-cache
```

256G ではディスクの空きが足りない場合は、`config.yml` でもっと小さい上限を設定してください。

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

その後 zurg を再起動してください。手動で空にしたい場合は、先に zurg を停止してから次のコマンドを実行します。

```bash
rm -rf ~/zurg/data/rclone-cache/vfs/* ~/zurg/data/rclone-cache/vfsMeta/*
```

zurg ディレクトリを移動すると、キャッシュの名前が変わり、古いコピーが残ります。zurg は次回の起動時にそれらを回収し、解放した容量をログに記録します。詳細と無効化の方法は[設定リファレンス](../reference/config.md#disk-the-mount-uses)にあります。

## zurg の管理 {#managing-zurg}

コマンドは zurg ディレクトリから実行してください:

```bash
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` は自動起動だけを削除します。バイナリ、設定、データ、ログ、キャッシュはそのまま残ります。

ユーザーサービスのログを追跡する場合:

```bash
journalctl --user -u zurg.service -f
```

システムサービスの場合:

```bash
sudo journalctl -u zurg.service -f
```

## zurg の更新 {#updating-zurg}

スポンサー向けビルドは自分自身を置き換えます:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` は最新のナイトリーを取得します。新しいバイナリをダウンロードし、そのバイナリが期待したバージョンを報告するかを確認してから、リネームで差し替えます。そのため、実行中のプロセスが上書きされることはありません。インストール済みのビルドがすでに最新の場合は、その旨を表示して何も変更しません。

`update` は、インストールに使ったアカウントで GitHub にサインインします。インストーラーはそのために GitHub CLI を `~/zurg/bin` に置いています。`update` が GitHub の認証情報が見つからないと表示した場合は、インストールがその変更より古いということです。インストーラーの update を一度実行すると、それ以降の `zurg update` はすべて動作します。同じコマンドは、`zurg update` を持たない古いビルドの更新にも使えます。更新されるのはバイナリだけで、ほかには一切触れません。

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

GitHub CLI がないサーバーでは、代わりに `GITHUB_TOKEN` を設定できます。zurg にアクセスできる GitHub アカウントで発行した、`repo` スコープの classic トークンを使ってください。

## 既存の設定と無人設定 {#existing-and-unattended-configs}

セットアップでは既存の `config.yml` を上書きすることは決してありません。無人でセットアップする場合は、`--provider` を繰り返し指定し、対応するトークンファイルまたは `--nntp-*` フラグを渡してください。`REALDEBRID_TOKEN`、`TORBOX_TOKEN`、`ALLDEBRID_TOKEN`、`NNTP_*` 変数も使えます。すべてのオプションは `./zurg setup --help` で確認できます。

すべての設定項目は [設定リファレンス](../reference/config.md) を参照してください。

それでも解決しませんか？ [Discord](https://discord.com/invite/7u4YjMThXP) の **zurg-support** フォーラムで聞いてみてください。何を書けばよいかは [サポートの受け方](../../guides/remote-help.md) に書いてあります。

## 関連項目 {#see-also}

- [Docker](docker.md) — コンテナのセットアップと FUSE マウントの伝播
- [macOS](macos.md) — macFUSE と launchd を使った、同じバイナリインストーラー
- [Windows](windows.md) — WinFsp と対話型のスケジュールタスクを使った、同じバイナリインストーラー
