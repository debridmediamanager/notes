# Real-Debridのライブラリを、zurgでPlexに入れる {#a-real-debrid-library-in-plex-with-zurg}

zurg は、Real-Debrid アカウント内のすべてを、コンピューター上のフォルダーとして表示します。それらは `movies` と `shows` にすでに振り分けられています。この 2 つのフォルダーを Plex Media Server に追加すれば、Real-Debrid のライブラリ全体が、どの Plex アプリでも再生できるようになります。何もダウンロードせずに、Real-Debrid からストリーミングされます。zurg はインストールするのが 1 回だけで済みます。rclone も一緒に入っているので、ほかに設定することはありません。

Plex Media Server やマウントしたドライブを動かしたくない場合は、[rex with zurg](../rex/with-zurg.md) を見てください。どちらも使わずに、同じライブラリを Plex アプリに表示する方法が書かれています。

## 必要なもの {#what-you-need}

- **スポンサーシップ。** zurgのナイトリービルドはスポンサー向けです。[gatekeeper](https://gatekeeper.debridmediamanager.com/)でスポンサーになると、あなたのGitHubアカウントでダウンロードできるようになります。詳しくは[スポンサーシップでできること](sponsorship.md)をご覧ください。
- **Real-Debridのプレミアムアカウント**とそのAPIトークン。トークンの場所は[Real-DebridのAPIトークン](real-debrid-api-token.md)に書いてあります。
- **zurgと同じコンピューターにあるPlex Media Server。** Plexはzurgのフォルダーからファイルを読み込むので、そのフォルダーが見えている必要があります。そうすれば、どのPlexアプリからでも視聴できます。
- **常時起動しているコンピューター**: Windows 10または11、Linux、Mac、またはDockerが使えるLinuxマシン。

## 1. zurgをインストールする {#1-install-zurg}

各セットアップページは、1行のインストーラーで始まります。`Choose one or more providers in priority order:` と表示されたら、Real-Debrid には `1` を入力し、トークンを貼り付けてください。

| お使いのコンピューター | インストール方法 | ライブラリの表示場所 |
|---|---|---|
| Windows | [Windows 版 zurg](../zurg/setup/windows.md) | `Z:\movies` と `Z:\shows` |
| Linux | [Linux 版 zurg](../zurg/setup/linux.md) | `/mnt/zurg/movies` と `/mnt/zurg/shows` |
| Mac | [macOS 版 zurg](../zurg/setup/macos.md) | `/Volumes/Zurg/movies` と `/Volumes/Zurg/shows` |
| Docker を使う Linux | [1つの Docker Compose ファイル](../zurg/guides/docker-compose.md)。zurg と並べて Plex Media Server も動かします | `/zurg_mnt/zurg/movies` と `/zurg_mnt/zurg/shows` |

インストーラーは最後に `zurg doctor` を実行します。`PASS` 行の一覧が表示されます。

## 2. フォルダを確認する {#2-check-the-folders}

zurg のドライブまたはフォルダを開いてください。`movies`、`shows`、`__all__`、`__downloads__`、`__unplayable__`、`version.txt` が表示されるはずです。

初回起動時には、Real-Debrid アカウント全体の読み込みが行われます。それが終わるまで、フォルダは空のままです。確認するには、ブラウザで `http://localhost:9999/ready` を開いてください。ライブラリの読み込みが完了すると `ready` と表示されます。

## 3. PlexにフォルダをAddする {#3-add-the-folders-in-plex}

In Plex Web で、サイドバーにあるサーバー名の横の **Add Library** ボタンを押します。

1. **Movies** を選んで **Next** を押します。
2. **Browse for media folder** を押し、上の表にある zurg の `movies` フォルダーを選びます。Windows なら `Z:\movies` のようになります。
3. **Add Library** を押します。

**TV Shows** と `shows` フォルダーでも同じ手順を行います。その後 Plex が両方をスキャンして、ポスターとタイトルを自動で取得します。

## 4. zurgに新しいものをPlexへ知らせてもらう {#4-let-zurg-tell-plex-about-new-things}

Plexは、Real-Debridアカウントに新しいものが追加されても気づきません。zurgがそれをPlexに伝えられます。zurgのダッシュボード`http://localhost:9999/config/`を開き、**Media Server Integration**に進んで**Login with Plex**を押してください。Plexにサインインして、サーバーを選びます。

![The Media Server Integration section of zurg's dashboard, with the Login with Plex button](../assets/real-debrid-plex/01-zurg-login-with-plex.webp)

これ以降、zurgは変更があったフォルダごとにPlexへスキャンを依頼します。また、ストリーミングライブラリでは危険なPlexの設定もいくつか無効にします。たとえば**Empty trash automatically after every scan**などです。対象の設定は[Recommended Plex Settings](../zurg/guides/plex.md#recommended-plex-settings)に一覧があります。

## 問題が起きたとき {#when-something-is-wrong}

| 見えるもの | やること |
|---|---|
| Plexに何も見つからない、またはzurgのフォルダが空 | zurgがまだアカウントを読み込み中です。`http://localhost:9999/ready` に `ready` と表示されるまで待ってから、Plexでもう一度スキャンしてください。 |
| Windowsで `Z:` ドライブがない、またはPlexが `Z:\movies` を見つけられない | `Z:` はWindowsのデスクトップセッションに属しており、zurgのインストーラーはログイン時にそこでzurgを起動します。管理者として開いたPowerShellからも見えません。[Windowsで問題が起きたとき](../zurg/setup/windows.md#when-something-is-wrong)に各ケースの対処がまとめてあります。 |
| Linuxで、Plexが空のフォルダを見る、または開けず、`./zurg doctor` が `user_allow_other is not enabled in /etc/fuse.conf; the mount will be visible only to the zurg service user` と表示する | Plexはzurgとは別のユーザーで動いています。他のユーザーにアクセスを許可するには、<code>echo user_allow_other &#124; sudo tee -a /etc/fuse.conf</code> を実行してから、zurgのフォルダで `./zurg service restart` を実行してください。 |
| Dockerで、zurgの再起動後にPlexのライブラリが空になり、`docker exec plex ls /zurg_mnt/zurg` が `Transport endpoint is not connected` と表示する | Plexのコンテナにzurgのフォルダを `rslave` 付きで渡してください: `/zurg_mnt:/zurg_mnt:rslave`。[Docker Compose ファイルの例](../zurg/guides/docker-compose.md)に記載があります。 |
| zurgのフォルダには新しいものが出てくるが、Plexには出ない | 手順4を実行してください。それまでは、Plexでライブラリの **Scan Library Files** を押してください。 |
| zurgが `bad_token` と表示する | Real-Debridのトークンが間違っているか、途中で切れています。[Real-Debrid APIトークン](real-debrid-api-token.md#when-something-is-wrong)に対処法があります。 |
| ディスクがいっぱいになる | zurgは再生したもののコピーを、デフォルトで最大256Gまで保存します。[キャッシュを小さく保つ](../zurg/setup/windows.md#keeping-the-cache-small)（Windows）または[マウントが使うディスク](../zurg/setup/linux.md#disk-the-mount-uses)（Linux）の手順で上限を設定してください。 |

まだ解決しませんか？[Discord](https://discord.com/invite/7u4YjMThXP)の **zurg-support** フォーラムで聞いてください。[サポートの受け方](remote-help.md)に、何を含めるべきかが書いてあります。

## よくある質問 {#questions}

### DMM、zurg、rcloneをセットアップして、Plexでストリーミングする方法のガイドはありますか？ {#is-there-a-guide-to-set-up-dmm-zurg-and-rclone-to-stream-in-plex}

これはこのページです。rclone を自分で設定する必要はありません。zurg のインストーラーが rclone をダウンロードし、zurg がそれを実行します。DMM ではリリースを探して、Real-Debrid アカウントに追加できます（[What DMM is and how to use it](../dmm/index.md)）。その後、zurg がフォルダーにリリースを表示し、Plex がそれを読み取ります。

### 映画はパソコンにダウンロードされますか？ {#do-the-movies-download-to-my-computer}

いいえ。Plex は再生ボタンを押すと、zurg を経由して Real-Debrid からファイルを読み込みます。zurg は再生したものの履歴をキャッシュとして保存しており、その容量は大きくなることがあります。上の表の disk の行を参照してください。

### Plex Media Serverは使わなくてもいいですか？ {#can-i-skip-plex-media-server}

はい、rexを使えば可能です。[rex with zurg](../rex/with-zurg.md)では、Plex Media Serverもマウントも使わずに、zurgのライブラリをPlexアプリで表示できます。両方を同時に動かすこともできます。[One Docker Compose file](../zurg/guides/docker-compose.md)を使えば、zurg、Plex Media Server、rexを1台のマシンで一度に動かせます。

### TorBoxやUsenetでも使えますか？ {#does-it-work-with-torbox-or-usenet-too}

はい。zurgのインストーラーでは、TorBox、AllDebrid、Premiumize、Debrid-Link、Offcloud、Usenetも選べて、どれも同じ`movies`と`shows`フォルダーにまとめられます。[Providers](../zurg/providers/index.md)には各プロバイダーのページがあります。
