# セットアップ {#setup}

バイナリインストーラーは、Linux、macOS、Windows で最短の方法です。コンテナの方が合う場合は、Linux ホストで Docker も使えます。macOS と Windows の Docker Desktop は、コンテナを VM 内で動かすため、マウントが Finder や Explorer に表示されず、rex が zurg に接続できません。そのため、この場合はバイナリを使ってください。

## ワンライン簡易インストーラー {#one-line-convenience-installers}

スポンサー向けのナイトリービルドをインストーラーがダウンロードします。まず [gatekeeper](https://gatekeeper.debridmediamanager.com/) でスポンサーになってください。そうすると GitHub アカウントにアクセス権が付与されます。

新規のスポンサー版インストールでは、お使いのホストに合ったコマンドを選んでください。

+++ Linux と macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```
+++ Linux 上の Docker
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```
+++ Windows
PowerShell で:
```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```
+++

ブートストラップは、プラットフォームの前提条件を確認し、スポンサーアクセスのために GitHub にサインインし、対応するビルドをダウンロードして、プロバイダー選択画面を起動します。既存のバイナリと設定はそのまま残ります。以下の各ガイドには、手動で行う完全な手順も載っています。

- [Linux](linux.md)
- [Docker](docker.md)（Linux ホスト）
- [macOS](macos.md)
- [Windows](windows.md)

zurg をインストールしたら、[プロバイダー](../providers/index.md) でアカウントを指定する方法を確認できます。サービスごとにページがあり、必要な認証情報と `config.yml` の設定例、そして各サービスの違いが書かれています。これらのページは Docker 向けに書かれています。バイナリでインストールした場合も、プロバイダーの `config.yml` の設定と Dashboard の手順は同じです。違うのは、`docker compose restart zurg` の代わりに `./zurg service restart`（Windows では `.\zurg.exe service restart`）を使うことです。また、`docker compose run --rm zurg setup` の行は `./zurg setup`（Windows では `.\zurg.exe setup`）になり、フラグはコンテナ版と同じですが、`--no-service --skip-downloads --mount-path /zurg_mnt/zurg` は除きます。`--…-file` フラグは、`/config` 配下のファイルではなく、お使いのマシン上のファイルを指定します。
