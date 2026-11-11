# zurgとrexのサポートを受ける {#getting-help-with-zurg-and-rex}

## Discordで質問する {#ask-in-discord}

[Discord](https://discord.com/invite/7u4YjMThXP) のフォーラムに、使っているものに合わせて投稿してください: **zurg-support**、**rex-support**、または **dmm-support**。問題ごとにスレッドを1つ作ってください。何をしたか、何を期待したか、実際に何が起きたかを書いてください。以下の詳細も追加してください。

**zurg の場合**、zurg のダッシュボードで **Export Logs** をクリックし、表示されたリンクを貼り付けてください。zurg のログと設定を、トークン、パスワード、API キーを取り除いた状態でアップロードします。アップロードできない場合は、**Download Logs** で同じものをファイルとして取得し、添付してください。あわせて `zurg doctor` の出力も貼り付けてください。

| zurg の実行方法 | 実行するコマンド |
|---|---|
| Linux または macOS でバイナリを実行 | zurg のフォルダで `./zurg doctor` |
| Windows でバイナリを実行 | zurg のフォルダで `.\zurg.exe doctor` |
| Docker | `docker compose exec zurg /app/zurg doctor --working-dir /config` |

**rex の場合**、失敗する操作で一度 **Play** を押してから、rex のログの末尾を貼り付けてください。rex はログ内の Plex トークンをマスクします。

| rex の実行方法 | 実行するコマンド |
|---|---|
| Linux で systemd サービスとして実行 | `journalctl --user -u rex -n 200 --no-pager` |
| macOS で launchd を使用 | `tail -n 200 ~/rex/rex.log` |
| Windows で Task Scheduler を使用 | `Get-Content $HOME\rex\rex.log -Tail 200` |
| Docker | `docker compose logs --tail=200 rex` |
| ターミナルウィンドウで実行 | そのウィンドウの最後の200行 |

長いログでは、特に大事なのはエラー、警告、そして rex が各再生について下した判断です。Linux、macOS、Docker のコマンドの末尾に `| grep -E 'ERROR|WARN|upstream|DECISION'` を追加すると、それだけを表示できます。Windows では `Select-String 'ERROR|WARN|upstream|DECISION' $HOME\rex\rex.log | Select-Object -Last 50` を実行してください。

## スポンサー向けのリモートサポート {#remote-help-for-sponsors}

スレッドで解決しない場合、ヘルパーがあなたのターミナルを見ながら操作してくれます。**zurg と rex のリモートサポートはスポンサー向けで、無料です。** [gatekeeper でスポンサーになる](https://gatekeeper.debridmediamanager.com/)。そこで Discord を接続するとスポンサーロールがもらえるので、そのあとサポートスレッドで質問してください。

このページでは [upterm](https://github.com/owenthereal/upterm) を `upterm.debridmediamanager.com` 経由で設定します。Linux、macOS、Windows で動きます。

アカウントのパスワードも、ルーターの変更も、事前のインストールも必要ありません。コマンドが upterm をダウンロードして起動します。すべてのコマンドは同じターミナルで実行されるので、その画面を見ていてください。セッションを終えるときは `exit` と入力します。

### 1. マシンを選ぶ {#1-pick-the-machine}

upterm は、zurg または rex を動かしているマシンで実行してください。目の前のコンピューターではなく、サーバーの場合もあります。

| 実行場所 | やること |
|---|---|
| このコンピューター | ここでターミナルを開き、手順2に進みます。 |
| Hetzner や Oracle、VPS などのクラウドサーバー | まず SSH で接続します。その SSH のウィンドウで、手順2の Linux の行を使ってください。 |
| Synology や Unraid などの自宅の NAS またはサーバー | そのターミナルを開きます。そこで手順2の Linux の行を使ってください。 |
| Docker | コンテナではなく、Docker を動かしているマシンを使ってください。 |

Windows からも SSH を使えます。PowerShell には `ssh` が最初から入っています。

```bash
ssh you@your-server
```

**Synology** では SSH がデフォルトでオフになっています。Control Panel > Terminal & SNMP > Enable SSH service でオンにしてください。そのあと、管理者アカウントでログインします。NAS のアドレスは、ルーターの画面か Synology Assistant で確認できます。

手順2で `cannot create directory` と表示された場合は、Control Panel > User & Group > Advanced > Enable user home service をオンにしてから、もう一度実行してください。

**Unraid** には Web 画面にターミナルがあります。右上の `>_` アイコンをクリックしてください。

### 2. セッションを開始する {#2-start-a-session}

ステップ1で選んだシステムの行を貼り付けてください。

#### Linux と macOS {#linux-and-macos}

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

#### Windows

PowerShell を開きます。管理者として実行する必要はありません。

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz" -UseBasicParsing; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

Surface Pro X のような ARM ノートパソコンでは、`amd64` を `arm64` に置き換えてください。

初回は、upterm が `upterm.debridmediamanager.com` を信頼するかどうか尋ねてきます。`yes` と入力してください。表示されるフィンガープリントがこれと同じであるはずです。

```
SHA256:r1LtSiydnfetLGxGt8hy+ULyqtN2KgnZSHtRgHzDr58
```

### 3. SSH の行をサポート担当者に送る {#3-send-the-ssh-line-to-your-helper}

upterm は数行を表示します。**SSH** の下にある行をコピーしてください。見た目はこんな感じです。

```
ssh AbCdEfGhIjKlMnOpQrSt:dXB0ZXJt...@upterm.debridmediamanager.com -p 2222
```

**プライベートメッセージで送ってください。** 公開チャンネルには絶対に投稿しないでください。これを持っている人は誰でもあなたのマシンで入力できてしまいます。

そのあとはウィンドウを開いたままにして、中をクリックしないでください。Windows では PowerShell のウィンドウをクリックすると、中で動いているものが `Esc` を押すまで一時停止することがあります。ヘルパーが入力する内容は、入力されるそばから、そのウィンドウにすべて表示されます。

### 4. セッションを終了する {#4-end-it}

**作業が終わったら、そのウィンドウに `exit` と入力してください。** セッションが終了し、接続はすぐに使えなくなります。

ウィンドウを閉じるだけでは不十分です。セッションは動き続けます。ウィンドウを閉じてしまった場合は、新しいターミナルを開いて `~/upterm/upterm session list` を実行してください(Windows では `& "$env:LOCALAPPDATA\upterm\upterm.exe" session list`)。そのあと、同じプログラムを `session stop` と、表示された名前とともに実行します。

後でもう一度ヘルプが必要になったら、手順 2 の行をもう一度貼り付けてください。セッションごとに新しい行が発行されます。

## サポート担当者向け {#for-helpers}

送られてきた SSH のコマンドを実行してください。どの SSH 鍵でも使えます。持っていない場合は、先に `ssh-keygen -t ed25519` を一度実行してください。

接続すると相手のターミナルに入ります。Windows では PowerShell、Linux と macOS では相手の通常のシェルです。

ファイルをコピーするときは、セッション ID の `:` が `scp` を混乱させるので、代わりにユーザー名として渡してください：

`scp -P 2222 -o User=<everything before the @> file upterm.debridmediamanager.com:file`

終わったら、相手に `exit` と入力してもらってください。
