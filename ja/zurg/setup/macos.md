# macOS チュートリアル {#macos-tutorial}

## ワンライン オプション {#one-line-option}

オプションの sponsor bootstrap は、必要に応じて macFUSE をインストールし、
Intel 版または Apple silicon 版のビルドをダウンロードして、
provider chooser と診断を実行します:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

GitHub のブラウザサインインを使います。macOS では、**System Settings > Privacy & Security** で承認が必要になる場合があり、
再起動も必要かもしれません。既存のバイナリと設定はそのまま残ります。手動で進める方法は下に続きます。

## ステップ 1: macFUSE をインストール {#step-1-install-macfuse}

macFUSEを使うと、rcloneでzurgの仮想ファイルシステムをMac上の実際のディレクトリとしてマウントできます。

1. [macfuse.io](https://macfuse.io)から最新の`.dmg`をダウンロードします
2. `.dmg`を開いて、インストーラーを実行します
3. インストール中に、macOSがシステム拡張機能をブロックします。**System Settings > Privacy & Security**を開き、下にスクロールして**Allow**をクリックしてください
4. **Macを再起動してください**(カーネル拡張機能を読み込むために必要です)

再起動したら、**Terminal**を開き(`Cmd + Space`を押して「Terminal」と入力し、Enterを押します)、macOSがmacFUSEを読み込めるか確認してください。これは`zurg setup`が行うのと同じチェックです:

```bash
/Library/Filesystems/macfuse.fs/Contents/Resources/load_macfuse && echo "macFUSE is ready"
```

`macFUSE is ready`が表示されない場合、macOSがまだ拡張機能を許可していません。Apple シリコン搭載のMacでは、リカバリモードでサードパーティのカーネル拡張機能を有効にし、**System Settings > Privacy & Security**でmacFUSEを許可してから、再起動してもう一度確認してください。

## ステップ 2: zurg をダウンロード {#step-2-download-zurg}

[GitHub Releases](https://github.com/debridmediamanager/zurg/releases) を、zurg にアクセスできる GitHub アカウントでサインインしたブラウザで開いてください。いちばん新しいナイトリービルド、つまりリストの一番上にあるプレリリースを選びます。`darwin-arm64` の zip を取ってください。Intel Mac の場合は `darwin-amd64` を選びます。

GitHub で **Latest** と表示されているリリースは選ばないでください。それは v1.0.0 です。`zurg setup` より古く、`unknown command` と返されてしまいます。

ナイトリービルドはスポンサー向けです。GitHub アカウントにアクセス権がないと、そのページは 404 を返します。アクセス権を得るには [gatekeeper](https://gatekeeper.debridmediamanager.com/) でスポンサーになってください。無料の公開ビルドは v1.0.0 で、[zurg-public](https://github.com/debridmediamanager/zurg-public/releases) のリリースページにあります。こちらには `zurg setup` がないので、以下の手順ではなく、[README](https://github.com/debridmediamanager/zurg-public#readme) の説明に従って手動で設定してください。

次に、ダウンロードした zip を展開します。

```bash
mkdir -p ~/zurg && cd ~/zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
```

確認:

```bash
./zurg version
```

## おすすめ: セットアップは zurg に任せる {#recommended-let-zurg-finish-the-setup}

从解压后的目录运行：

```bash
./zurg setup
./zurg doctor
```

`setup` 会询问要配置哪些服务。按优先级顺序，从 Real-Debrid、TorBox、AllDebrid、Usenet、Premiumize、Debrid-Link 和 Offcloud 中选择一个或多个。比如输入 `2,4`，就是先 TorBox，再 Usenet。它只会询问你所选服务的凭据，然后创建 `config.yml`（权限为 `0600`），下载 rclone（如果 PATH 里没有 ffprobe，也会一并下载），准备 `/Volumes/Zurg`，并安装自动启动。

如果当前用户有 GUI launchd 域，它会选择 LaunchAgent。如果是没有登录 GUI 用户的无头 Mac，它会安装系统级 LaunchDaemon，仍然以当前用户身份运行 zurg。这种方式不需要开启自动登录。

先决条件检查会区分已安装的 macFUSE 软件包和 macOS 真正能加载的扩展。在 Apple silicon 上，第一次安装 macFUSE 时，可能仍需要在 Recovery 中做一次安全性设置更改，还要在 **System Settings > Privacy & Security** 中批准，然后重启。任何安装程序都无法绕过这些确认步骤。

重复运行 setup 是安全的。它会更新生成的 launchd 服务，但不会替换已有的 `config.yml`。

在通过挂载点串流之前，请打开 `config.yml` 或 `http://localhost:9999/config/` 上的 Dashboard，在 `rclone_extra_args` 下同时设置 `--vfs-cache-max-size` 和 `--vfs-cache-min-free-space`。最大缓存大小要低于当前可用磁盘空间的一半，并用最小可用空间设置至少保留 `20G`。然后运行 `./zurg service restart`。

本页其余部分说明配置和 Plex 设置。第 3、4、5、7 步是手动方式，`zurg setup` 成功后可以跳过。

## ステップ 3: zurg を手動で設定 {#step-3-configure-zurg-manually}

Real-Debrid の API トークンを使って設定ファイルを作成します:

```bash
cd ~/zurg
cat > config.yml << 'EOF'
# Minimal config - use Dashboard at http://localhost:9999/config/ for more settings
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN_HERE

rclone_enabled: true
mount_path: /Volumes/Zurg

rclone_extra_args:
  - "--vfs-cache-max-size"
  - "100G"
  - "--vfs-cache-min-free-space"
  - "20G"

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
EOF
```

プレースホルダーのトークンを、[real-debrid.com/apitoken](http://real-debrid.com/?id=20476354) で取得した実際のトークンに置き換えてください:

```bash
sed -i '' "s|YOUR_RD_API_TOKEN_HERE|PASTE_YOUR_TOKEN_HERE|g" ~/zurg/config.yml
```

> **`mount_path` は削除しないでください。** これがないと、macOS では rclone が `/Volumes/Zurg` をデフォルトとして使います。ただし、メディアサーバーのスキャンは `mount_path` を明示的に設定したときだけ有効になります。これを省くと、Plex に更新が通知されなくなります（ステップ6を参照）。

> **キャッシュのサイズ設定はとても重要です。** VFS キャッシュは、ストリーミングしたファイルのチャンクをローカルディスクに保存します。ディスクがいっぱいになると、macOS の動作が大きく遅くなります。Spotlight、Plex、さらには OS 自体が応答しなくなることもあります。必ず **両方** の上限を設定してください:
>
> - `--vfs-cache-max-size` — キャッシュ全体の合計サイズの上限です。**空きディスク容量の 50% 以下**に設定してください。`df -h /` で確認できます。
> - `--vfs-cache-min-free-space` — 空き容量がこの値を下回ったら、キャッシュへの保存を止めます。安全のため、**20G 以上**に保ってください。
>
> 例えば、空き容量 100GB の 256GB ドライブなら、最大サイズは `50G`、最小空き容量は `20G` にします。

## ステップ 4: 依存関係を手動でダウンロード {#step-4-download-dependencies-manually}

zurg には、rclone と ffprobe をダウンロードして、そのパスを `config.yml` に書き込む組み込みコマンドがあります:

```bash
cd ~/zurg
./zurg download-requirements
```

マウントポイントとログ用ディレクトリを作成します。`/Volumes` は root の所有なので、zurg は `/Volumes/Zurg` を自分では作成できません。ログディレクトリは、ステップ7で launchd が出力ファイルを開く前に存在している必要があります:

```bash
sudo mkdir -p /Volumes/Zurg
sudo chown "$(whoami)" /Volumes/Zurg
mkdir -p ~/zurg/logs
```

利用可能なすべてのオプションは [設定リファレンス](../reference/config.md) を見てください。zurg を起動したあとは、`http://localhost:9999/config/` の Web Dashboard から設定することもできます。

## ステップ 5: zurg を手動でテスト {#step-5-test-zurg-manually}

自動起動を設定する前に、すべてが動くか確認しましょう:

```bash
cd ~/zurg && ./zurg
```

ログに zurg の起動、Real-Debrid への接続、rclone によるマウントが表示されるはずです。別のターミナルウィンドウで、次を確認してください:

```bash
# Check the HTTP endpoint
curl -s http://localhost:9999/http/version.txt

# Check the mount
ls /Volumes/Zurg/
# Expected: __all__  __downloads__  __unplayable__  movies  shows  version.txt
```

問題なければ、`Ctrl+C` で zurg を停止します。

## ステップ 6: Plex Media Server をインストール {#step-6-install-plex-media-server}

1. Download von [plex.tv/media-server-downloads](https://www.plex.tv/media-server-downloads/) und wähle **macOS** (Universal)
2. Öffne die `.dmg` und zieh **Plex Media Server** nach `/Applications`
3. Starte Plex Media Server aus Applications (oder über Spotlight: `Cmd + Space` → „Plex Media Server“)
4. Dein Browser sollte den Plex-Einrichtungsassistenten öffnen. Folge ihm, um deinen Server zu beanspruchen
5. **Autostart aktivieren:** Klick mit der rechten Maustaste auf das Plex-Symbol in der Menüleiste und aktiviere **Launch at Login**
6. Hol dir dein Plex-Token. Am einfachsten geht das so:
   - Öffne ein beliebiges Medienelement in Plex Web
   - Klick auf **Get Info** (oder **...** → **Get Info**)
   - Klick auf **View XML**
   - Such in der URL-Leiste nach `X-Plex-Token=`

Trag das Plex-Token in deine zurg-Konfiguration ein, indem du `config.yml` bearbeitest:

```yaml
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
```

## ステップ 7: zurg の自動起動を手動で設定 {#step-7-set-up-zurg-auto-start-manually}

macOS LaunchAgentは、ログインしたときにサービスを自動で起動します。Plexは自動起動を自分で処理するため（ステップ6）、zurgのLaunchAgentだけが必要です。

### zurg LaunchAgent

```bash
cat > ~/Library/LaunchAgents/com.zurg.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zurg</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/zurg/zurg</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${HOME}/zurg</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME}/zurg/logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME}/zurg/logs/launchd-stderr.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST
```

主な設定:
- **RunAtLoad** — ログイン時に zurg を起動します
- **KeepAlive / SuccessfulExit: false** — zurg がクラッシュした場合、launchd が自動で再起動します
- **ThrottleInterval: 10** — 再起動を試みる間隔を 10 秒空けます

### LaunchAgent を読み込む {#load-the-launchagent}

```bash
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

登録されているか確認してみてください:

```bash
launchctl list | grep zurg
# Should show com.zurg with a PID
```

## ステップ 8: Plex ライブラリを設定 {#step-8-configure-plex-libraries}

zurg が動いていて、マウントも有効になったら:

1. [http://localhost:32400/web](http://localhost:32400/web) を開きます
2. **Settings**（レンチアイコン）→ **Manage** → **Libraries** に進みます
3. **Add Library** をクリックします

**Movies ライブラリを追加:**
- Type: **Movies**
- **Browse for media folder** をクリックします
- `/Volumes/Zurg/movies` まで移動します
- **Add Library** をクリックします

**TV Shows ライブラリを追加:**
- Type: **TV Shows**
- **Browse for media folder** をクリックします
- `/Volumes/Zurg/shows` まで移動します
- **Add Library** をクリックします

**おすすめのライブラリ設定**（各ライブラリの Edit → Advanced で設定）:
- **Empty trash automatically after every scan** のチェックを外します。コンテンツの管理は zurg がやってくれるからです
- **Generate video preview thumbnails** のチェックを外します。ファイルは Real-Debrid からストリーミングされるので、帯域幅の節約になります

## ステップ 9: すべて動いているか確認 {#step-9-verify-everything-works}

```bash
# 1. zurg is running
curl -s http://localhost:9999/http/version.txt && echo " - zurg is up"

# 2. Mount is active
ls /Volumes/Zurg/movies > /dev/null 2>&1 && echo "Mount is active"

# 3. Plex is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:32400/identity && echo " - Plex is up"

# 4. Processes
ps -eo pid,command | grep -E "[z]urg|[r]clone.*mount|[P]lex Media Server" | head -5

# 5. zurg service (for the manual LaunchAgent from Step 7: launchctl list | grep com.zurg)
cd ~/zurg && ./zurg service status
```

## ステップ 10: 自動ログインを有効にする（任意） {#step-10-enable-auto-login-optional}

この設定は手動の LaunchAgent を使う場合にだけ必要です。LaunchAgent は再起動のたびにユーザーがログインしないと動きません。ヘッドレス Mac では、組み込みのインストーラーが LaunchDaemon を使うので、この手順は不要です。

ヘッドレスサーバーで手動の LaunchAgent をあえて使う場合は、無人で起動するように自動ログインを有効にしてください。

1. **システム設定** を開きます
2. **ユーザとグループ** に進みます
3. **自動ログイン** をクリックし、使用しているユーザーを選びます
4. パスワードを入力します

> **セキュリティに関する注意:** 自動ログインを有効にすると、Mac に物理的にアクセスできる人は誰でもあなたのアカウントを使えてしまいます。信頼できる場所にある Mac でだけ使ってください。

---

## サービスの管理 {#managing-the-services}

`zurg setup` で作成したインストールでは、どのプラットフォームでも同じコマンドを使います:

```bash
cd ~/zurg
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` が削除するのは自動起動だけです。バイナリ、設定、データ、ログ、キャッシュはそのまま残ります。以下の launchctl コマンドは、ステップ 7 で手動作成した LaunchAgent (`com.zurg`) 用です。`zurg setup` では、自分で `com.zurg.zurg` という名前を付けます。

### 起動 / 停止 / 再起動 {#start--stop--restart}

```bash
# Stop zurg (and its rclone child process)
launchctl stop com.zurg

# Start zurg
launchctl start com.zurg

# Restart zurg
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### ログを見る {#view-logs}

```bash
# zurg logs
tail -50 ~/zurg/logs/zurg.log

# Rclone logs
tail -50 ~/zurg/logs/rclone.log
```

### 設定変更後に再読み込み {#reload-after-config-change}

If you edit a `.plist` file:

```bash
launchctl unload ~/Library/LaunchAgents/com.zurg.plist
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

If you edit `config.yml`, just restart zurg:

```bash
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### zurg を更新 {#update-zurg}

スポンサー向けビルドは、自分自身を置き換えます:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` は最新のナイトリーを取得します。ダウンロードしたバイナリが想定どおりのバージョンを表示するか確認してから、名前の変更によって差し替えます。そのため、実行中のプロセスが上書きされることはありません。インストール済みのビルドがすでに最新なら、その旨を表示して何も変更しません。

`update` は、インストール時に使ったアカウントで GitHub にサインインします。そのためにインストーラーが GitHub CLI を `~/zurg/bin` に置いています。`update` が GitHub の認証情報が見つからないと表示したら、インストールがその変更より古いということです。インストーラーのアップデートを一度実行すれば、それ以降の `zurg update` は動くようになります。`zurg update` がない古いビルドでも、同じコマンドで更新できます。

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

代わりに `GITHUB_TOKEN` を設定することもできます。zurg にアクセスできる GitHub アカウントの、`repo` スコープを持つ classic トークンを使ってください。

手動で更新する場合は、ステップ 2 と同じ方法で [リリース](https://github.com/debridmediamanager/zurg/releases) から新しい `darwin-arm64` の zip（Intel Mac なら `darwin-amd64`）をダウンロードしてから、次を実行します:

```bash
cd ~/zurg
./zurg service stop && sleep 2     # manual LaunchAgent: launchctl stop com.zurg
rm -f zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
./zurg service start               # manual LaunchAgent: launchctl start com.zurg
```

古いバイナリは上書きせず、削除してください。ファイルを書き換えると inode が同じままになり、ad-hoc のコード署名が無効になります。すると macOS が新しいビルドの起動時に強制終了させます。症状は、何も出力されずに即座に終了することです。`zurg update` が名前の変更で差し替えるのも、まさにこの理由からです。

## トラブルシューティング {#troubleshooting}

### マウント時の "Operation not permitted" {#operation-not-permitted-when-mounting}

macFUSE は System Settings で許可する必要があります:
1. **System Settings > Privacy & Security** に移動します
2. 下にスクロールして、ブロックされたシステム拡張機能のメッセージを探します
3. **Allow** をクリックしてから、**reboot** します

### マウントが "not a directory" になる、またはフリーズする {#mount-shows-as-not-a-directory-or-hangs}

以前のクラッシュの影響で、マウントポイントが古い状態のまま残っている可能性があります:

```bash
umount -f /Volumes/Zurg 2>/dev/null
diskutil unmount force /Volumes/Zurg 2>/dev/null
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### zurg が再起動を繰り返す（クラッシュループ） {#zurg-keeps-restarting-crash-loop}

エラーについてログを確認してください:

```bash
tail -100 ~/zurg/logs/service-stderr.log   # manual LaunchAgent: launchd-stderr.log
```

主な原因:
- `config.yml` の構文が不正 — `cd ~/zurg && ./zurg` で手動に確認してください
- 期限切れの Real-Debrid トークン — [real-debrid.com/apitoken](http://real-debrid.com/?id=20476410) で新しいトークンを取得してください
- `/Volumes/Zurg` が存在しない、またはあなたのユーザーの所有ではない — zurg はこのフォルダを作成できず、`ensure mount path: permission denied` で失敗します（ステップ 4）
- ポート 9999 がすでに使用中 — `lsof -i :9999` で確認してください

### macOS のアップデート後に macFUSE が壊れる {#macfuse-breaks-after-macos-update}

macOSの大きなアップデートの後、カーネル拡張が無効になることがあります。その場合は、macFUSEを再インストールしてください:
1. [macfuse.io](https://macfuse.io) から最新版をダウンロードします
2. インストールします
3. **System Settings > Privacy & Security** で拡張機能を承認します
4. 再起動します

### すべて動いていたのに再起動後に止まった {#everything-was-working-but-stopped-after-reboot}

手動の LaunchAgent をインストールしていて、自動ログインが有効になっていない場合は、起動する前にログインが必要です。次のいずれかの方法で対応してください。

- 自動ログインを有効にする（手順 10 を参照）
- SSH で接続する。ユーザーセッションが作成されれば、LaunchAgent は読み込まれた状態になります
- VNC／画面共有を使ってリモートからログインする

ヘッドレス Mac で `zurg setup` を実行して作成したインストールは LaunchDaemon を使うため、GUI へのログインは不要です。`cd ~/zurg && ./zurg service status` で確認できます。

それでも解決しない場合は、[Discord](https://discord.com/invite/7u4YjMThXP) の **zurg-support** フォーラムで質問してください。何を書けばよいかは [サポートの受け方](../../guides/remote-help.md) に書かれています。

## アーキテクチャの概要 {#architecture-overview}

```
launchd (PID 1)

  com.zurg LaunchAgent
    └── ./zurg
          ├── HTTP/WebDAV server (:9999)
          ├── Dashboard UI (:9999/config/)
          ├── Real-Debrid API client
          └── rclone mount (child process)
                └── /Volumes/Zurg/
                      ├── movies/
                      └── shows/

  Plex Media Server (:32400)  — Launch at Login via menu bar
    ├── Movies library  → /Volumes/Zurg/movies
    └── Shows library   → /Volumes/Zurg/shows

  macFUSE kernel extension
    └── Enables FUSE mounts for rclone
```

## クイックリファレンス {#quick-reference}

`~/zurg` で以下のコマンドを実行してください。`zurg service` の行は `zurg setup` でインストールした場合向けです。手動で設定した LaunchAgent の場合は、[サービスの管理](#managing-the-services) にある launchctl コマンドを使ってください。

| 操作 | コマンド |
|------|----------|
| zurg を起動 | `./zurg service start` |
| zurg を停止 | `./zurg service stop` |
| zurg を再起動 | `./zurg service restart` |
| インストールを確認 | `./zurg doctor` |
| 自動起動を解除 | `./zurg service uninstall` |
| zurg のログを表示 | `tail -f ~/zurg/logs/zurg.log` |
| rclone のログを表示 | `tail -f ~/zurg/logs/rclone.log` |
| マウントを確認 | `ls /Volumes/Zurg/` |
| zurg の状態を確認 | `curl http://localhost:9999/http/version.txt` |
| Plex の状態を確認 | `curl http://localhost:32400/identity` |
| ダッシュボード | `open http://localhost:9999/config/` |
| 強制アンマウント | `umount -f /Volumes/Zurg` |
