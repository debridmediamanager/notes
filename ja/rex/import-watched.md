# rex に視聴履歴を移行する {#bring-your-watch-history-to-rex}

rex は最初、視聴履歴が空の状態で始まります。別の Plex サーバーから、視聴済みのタイトル、再開位置、星評価をコピーできます。
視聴済みのタイトルはそのまま視聴済みになります。途中まで見たタイトルは **Continue Watching** に戻ります。シリーズとシーズンは、エピソードを数え直します。

自宅のどのコンピューターからでも一度実行すれば大丈夫です。rex を使う人はみんな、自分の履歴をインポートできます。

## 始める前に {#before-you-start}

| 必要なもの | 理由 |
|---|---|
| ライブラリを入れた rex のセットアップ。[rex を自分のアプリで使う](any-source.md)、[rex を Stremio アドオンと使う](stremio.md)、[rex を zurg と使う](with-zurg.md) のいずれかの手順で行います | rex は履歴を、すでに持っているタイトルにしかコピーしません。ライブラリがまだ埋まっている途中なら、後で import をもう一度実行してください。新しく追加された分だけが足されます |
| rex nightly **2026.10.31 以降** | [rex の更新方法](any-source.md#updating) を参照して更新してください |
| 古い Plex サーバーが起動していること | rex は履歴をこのサーバーから読み取ります。rex に移行したときに停止していたら、起動し直してください |
| ホームネットワーク上のコンピューターと `curl` | import はホームネットワークからしか実行できません。Windows 10 と 11、macOS、Linux にはすべて `curl` が入っています |

## 1. 古いサーバーのアドレスをコピーする {#1-copy-your-old-servers-address}

1. Öffne [app.plex.tv](https://app.plex.tv) im Browser und melde dich als **du selbst** an, also mit dem Konto, dessen Verlauf du übernehmen willst.
2. Wähle deinen alten Server aus und öffne einen beliebigen Film darauf.
3. Klicke auf **⋯** (More) und dann auf **Get Info**.
4. Klicke unten links im sich öffnenden **Media Info**-Fenster auf **View XML**. Ein neuer Tab öffnet sich, voller Text.

   ![Das Media-Info-Fenster, das Get Info öffnet, mit View XML unten links](../assets/rex/40-plex-get-info.webp)
5. Kopiere die **gesamte Adresse** aus der Adressleiste dieses Tabs.

Sie sieht so aus, alles in einer Zeile, und endet mit `X-Plex-Token=` gefolgt von einem Code:

```
https://192-168-1-5.0123456789abcdef.plex.direct:32400/library/metadata/1234?checkFiles=1&includeAllConcerts=1&X-Plex-Token=AbCdEfGh1234567890xy
```

Dieser Code ist dein **Plex-Token** für diesen Server. Er funktioniert wie ein Passwort für dein Plex-Konto: Füge ihn nie in Discord, einen Support-Beitrag oder einen Screenshot ein.

**Kein View XML in Schritt 4?** Plex Web zeigt es nur bei einem Server, der dir gehört. Bei einem Server, den dir jemand freigegeben hat, gibt es das also nicht. Nutze stattdessen die Entwicklertools des Browsers auf deinem alten Server, wie in [Schritt 2](#2-get-your-token-on-rex), und wähle eine Anfrage an deinen alten Server aus (ihre Adresse enthält `plex.direct`). Klicke sie mit der rechten Maustaste an und kopiere ihre Adresse: **Copy**, **Copy URL** in Chrome und Edge, **Copy Value**, **Copy URL** in Firefox. Diese Adresse brauchst du. Sie enthält `X-Plex-Token=` und den Code zusammen mit weiteren `X-Plex-`-Teilen: Füge alles ein.

## 2. rex でトークンを取得する {#2-get-your-token-on-rex}

rex は共有されているものなので、rex の **Get Info** には **View XML** が表示されません。Plex Web ではサーバーの所有者にしか表示されないためです。代わりに、app.plex.tv が rex に送っているトークンをブラウザーから読み取ってください:

1. app.plex.tv に、自分のアカウントでサインインしたまま、ブラウザーの開発者ツールを開きます。**F12** を押すか、Mac では **⌥ ⌘ I** です。Safari では、先に **Settings**、**Advanced** の **Show features for web developers** をオンにしてください。
2. **Network** タブを開き、そのフィルター欄に `X-Plex-Token` と入力します。
3. **rex** サーバー上の映画を 1 本開きます。リクエストの一覧が表示されます。
4. アドレスが rex のものを 1 つクリックします。rex-direct を使っている場合は `rex-direct.debridmediamanager.com` を含むもの、または自分で設定した HTTPS アドレスです。`plex.tv` へのものではありません。
5. `X-Plex-Token` の値をコピーします。Chrome と Edge では **Payload** の下に、Firefox では **Request** の下にあります。または、リクエストのアドレスをコピーして、`X-Plex-Token=` の後ろから次の `&` までの部分を取り出します。

これは手順 1 のコードとは別のものです。サーバーごとに、アカウントへ別々のトークンが発行されます。rex は、このトークンを使って誰の視聴履歴かを判別します。

## 3. インポートを実行する {#3-run-the-import}

自宅のパソコンで、以下のコマンドを2つの値を入れ替えて実行してください。`192.168.1.20` は rex のLAN IPを表すので、ご自身のLAN IPに置き換えてください。

```bash
curl -d "ADDRESS-FROM-STEP-1" "http://192.168.1.20:32400/rex/import-watched?X-Plex-Token=TOKEN-FROM-STEP-2"
```

Windowsの場合は、**PowerShell** を開き、`curl` ではなく `curl.exe` と入力します。ダブルクォートのペアは両方残してください。手順1のアドレスには `&` 文字が含まれているため、クォートがないとコマンドが壊れます。

数秒かかります。ライブラリが大きいと、もっと時間がかかります。rex は古いサーバー上のすべての映画とエピソードを読み取るためです。

**結果の見方。** 次のような行が1行表示されます。

```json
{"watched":412,"inProgress":7,"rated":38,"alreadyHere":0,"notInRex":55}
```

| 数 | 意味 |
|---|---|
| `watched` | rex が視聴済みとしてマークしたタイトル。古いサーバーの再生回数と日付も含みます |
| `inProgress` | 途中まで見ていたタイトル。中断した場所から再開されます |
| `rated` | 星評価がつけられたタイトル |
| `alreadyHere` | rex ですでに視聴済み、または視聴を開始していたタイトル。rex は既存のデータを保持し、そこは変更しません |
| `notInRex` | 古いサーバーに履歴はあるものの、rex にはない、または同じタイトルとしては存在しないタイトル |

結果を確認するには、Plex アプリをもう一度開いてください(または app.plex.tv を再読み込みしてください)。

## いつでも再実行できます {#run-it-again-any-time}

再度実行しても、すでに持っているものは変わりません。ライブラリに新しいものが届いたら、そのたびに実行してください。最初の実行の直後にもう一度実行すると、`"watched":0` と表示され、前回のものは `alreadyHere` の下に入ります。

## コピーされないもの {#what-is-not-copied}

- 古いサーバー上の他のユーザーの履歴。各ユーザーが自分の2つのトークンを使ってインポートを実行します。
- サーバーの再生履歴リスト、プレイリスト、コレクション。
- 番組全体やシーズンの星評価。映画とエピソードの評価はコピーされます。
- 古いサーバーでエージェントが **Plex Movie** でも **Plex TV Series** でもないライブラリ内のタイトル（Plex Movie (Legacy) や TheTVDB などの旧エージェント）。rex は Plex の現在のエージェントが付与するIDでタイトルを探しますが、旧エージェントは別のIDを付与するため、これらは `notInRex` に数えられます。

## うまくいかない場合 {#if-it-does-not-work}

| What you see | What to do |
|---|---|
| `that address has no X-Plex-Token: copy it whole from the tab View XML opens` | 貼り付けたアドレスは、トークンの手前で切れています。アドレスバーか開発者ツールからもう一度コピーして、全体を貼り付けてください |
| `send the address View XML opens on your old Plex server, starting http:// or https://` | `-d` の後の引用符に、アドレス以外のものが入っています |
| `... refused the token: copy the address from View XML again` | 古いサーバーがトークンを受け付けませんでした。手順 1 をもう一度行ってください。サーバーが他の人と共有されている場合は、開発者ツールを使ってください |
| `could not reach https://...` | rex が古いサーバーに接続できませんでした。古いサーバーが起動している必要があり、**rex のマシン**からも到達できる必要があります。rex はあなたのコンピューターではなく、そのサーバーからデータを読み取るためです |
| `run the import from your home network` | コマンドを rex の外部アドレスに送っています。手順 3 にあるように、rex の LAN IP を使ってください |
| `Unauthorized` のページが表示される | rex が手順 2 のトークンを受け付けませんでした。`plex.tv` へのリクエストではなく、rex へのリクエストから、もう一度コピーしてください |
| `notInRex` が想定よりずっと多い | ライブラリの大部分がまだ rex に入っていないか、古いライブラリが Plex の古いエージェントを使っています。ライブラリが届いてから、もう一度実行してください |

それでも解決しない場合は、[Discord](https://discord.com/invite/7u4YjMThXP) の **rex-support** フォーラムで質問してください。[ヘルプの求め方](../guides/remote-help.md) に、含めるべき情報が書かれています。
