# Usenet と zurg {#usenet-with-zurg}

zurgの`nzb`バックエンドは`.nzb`ファイルをマウントされたライブラリに変換します。ダウンローダーや完了フォルダーはありません。

再生する前に何もダウンロードされません。NZBと上限付きのキャッシュ（`data/bytecache`と`data/par2`）、およびインデックスのレコードを保存します。`nzb_article_disk_cache_mb`の既定値は512 MiBです。シークすると、zurgはその範囲のバイトをカバーする記事だけを取得します。60 GBのremuxでも、60 GBのディスクは必要ありません。

Usenetは、debridバックエンドと同じライブラリフィルター、マウント、メディアサーバー連携を使います。Usenetのリリースは、Real-DebridやTorBoxのコンテンツと並べて置けます。Usenetだけを使うこともできます。

**複数のUsenetプロバイダーに対応しています。** 1つの`nzb`エントリーには、いくつでもニュースアカウントを入れられます。プロバイダーの数に上限はなく、ブロックアカウントでも、持っているものなら何でも構いません。zurgは記事ごとに、それらを順番に試していきます。ここでは冗長性よりも重要な点です。保存期間（retention）はプロバイダーごとに違うため、2つ目のアカウントがあると、余分に1回取得するだけで済むか、PAR2からリリース全体を組み直すかの差になることがよくあります。[複数のUsenetプロバイダー](#more-than-one-usenet-provider)を参照してください。

このガイドでは、ニュースアカウント、NZB、マウント、Plexについて説明します。

| | |
|---|---|
| 設定リファレンス | [config.md → Usenet accounts](../reference/config.md#usenet-accounts) |
| ダッシュボード | `http://localhost:9999/config/` → Essentials → Providers |
| コードの場所 | `internal/nzb`（バックエンド）、`internal/nntp`（ニュースクライアント）、`internal/par2`（修復の計算） |
| 監視ディレクトリ | `nzbs/`、zurgの作業ディレクトリ内（Dockerでは`/config`） |
| 修復キャッシュ | `data/par2/` |
| 解決済みのファイル名 | `data/nzb-names/`。難読化されたリリースの名前は、再起動のたびではなく一度だけ読み取られます |
| 記事インデックス | `data/nzb-index/`。`nzb_segments: mmap`の下に保存されます（Linux、macOS、BSDでは既定値） |

---

## 必要なもの {#what-you-need}

- **少なくとも1つの Usenet プロバイダーアカウント。** 最も重要なのは保持期間です。4000日以上のプロバイダーなら、1000日で古くなった投稿もまだ残っています。2つ目に知っておきたいのは、プランの *接続数の上限* です。zurg はこの数値を見て動作します。
- **必要ならアカウントを増やす。** 別のバックボーンにある2つ目の無制限プロバイダー、または欠けている投稿を補う安価なブロックアカウントは、Usenet 環境に追加できるものの中で最も効果の高いものです。詳しくは [複数の Usenet プロバイダー](#more-than-one-usenet-provider) を参照してください。
- **NZB ファイル、または NZB を取得してくれる仕組み。** インデクサーから NZB をダウンロードして `nzbs/` に入れてください。または [SABnzbd 互換エンドポイント](sonarr-radarr.md) を有効にして、Sonarr と Radarr に NZB を渡させることもできます。書き込み先は同じディレクトリです。zurg は Newznab インデクサーを自分で検索することもできます。[Stremio](stremio.md) で再生を押したときや、ウォッチリストや Seerr、\*arrs からのリクエストを [取得機能](acquisition.md) 経由で処理するときに検索します。デバッドアカウント用のトレントには専用のエンドポイントがあり、[qBittorrent](sonarr-radarr-torrents.md) 互換で動作します。
- **zurg**。ファイルシステムとしてマウントしたい場合は `rclone` も必要です。zurg は初回起動時に rclone を自動でダウンロードします。

---

## 1. ニュースアカウントを設定する {#1-configure-your-news-accounts}

zurg の各アカウントは `providers:` の下の 1 つのエントリです。Usenet のアカウントは API トークンではなくサーバーの認証情報で認証するので、`token` の代わりに `nntp` ブロックを持ちます:

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 30        # your plan's allowance — see below
      cache_size_mb: 512     # decoded articles held in memory, across all files
```

これだけです。debrid アカウントも持っていれば、その横に追加してください:

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: nzb
    nntp:
      host: news.example.com
      ...
```

| キー | デフォルト | 説明 |
|---|---|---|
| `host` | *(必須)* | ニュースサーバーです。host が空または未指定の場合は起動時エラーになります。 |
| `port` | `563`（TLS あり）、`119`（TLS なし） | |
| `tls` | `false` | 有効にしてください。平文の NNTP では、パスワードが平文で送られ、読み込み内容も経路上の第三者に見えてしまいます。 |
| `username` / `password` | `""` | |
| `connections` | `8` | **ご契約プランで実際に許可された接続数を設定してください。** これは遠慮して控えめにするようなレート制限ではありません。1 つの接続が扱えるのはプロバイダーのスループットの一部だけなので、zurg はこの数に合わせて読み込みを行います。少なすぎるとストリーミングが遅くなり、プランの上限を超えるとサーバーが接続を拒否し始めます。 |
| `warm_connections` | `4` | 認証済みのアイドル接続を開いたままにして、読み込みが接続の確立を待たないようにします。接続の確立には約 0.8 秒かかります（TCP、TLS、挨拶、`AUTHINFO`）。下限がないと、起動のたびや一時的に静かな状態のあとに、その遅延がデマンド時に発生していました。これらは追加分ではなく `connections` の中から使われます。プランでは開いている接続として数えられ、zurg は定期的な `DATE` で接続を維持します。そのため下限は許可数が上限になります。`-1` にすると接続を保持しません。接続時間で課金されるプランにはこちらが向いています。トップレベルの `warm_connections` は、何も指定していないアカウントのデフォルトを設定します。[ウォーム接続](../reference/config.md#warm-connections)を参照してください。 |
| `cache_size_mb` | `512` | デコード済みの記事データをメモリに保持します。ファイルごとではなく、読み込まれるすべてのファイルで共有されます。 |
| `servers` | `[]` | 追加のニュースアカウントです。[複数の Usenet プロバイダー](#more-than-one-usenet-provider)を参照してください。 |

設定のバリデーターが適用する 2 つのルールがあります:

- **有効な `nzb` プロバイダーのエントリは 1 つだけにしてください。** 2 つあると、それぞれが同じ `nzbs/` ディレクトリをスキャンし、すべてのリリースが重複してしまいます。これは *Usenet プロバイダー* の数に制限があるという意味ではありません。追加のニュースアカウントは、その 1 つのエントリの `nntp.servers` の下に入れてください。そうすれば 2 つ目のコピーではなく、同じライブラリを提供します。
- **`watchlist: true` は指定できません。** Usenet バックエンドはコンテンツを追加できないため、Plex のウォッチリストへの追加先にはなりえません。

### Usenet プロバイダーを複数使う {#more-than-one-usenet-provider}

 retention はプロバイダーごとに決まります。1 回の余分な取得で済むか、リリース全体の PAR2 再構築が必要になるかは、別のアカウントがその記事をまだ持っているかどうかで決まります。そのため、ここでは 2 つ目のアカウントが、一般的な冗長化よりも大きな価値を持ちます。

`nntp` ブロックにあるキーは 1 つ目のアカウントを表します。`servers` の下にあるものは、別のアカウントです。同じ `priority` のアカウントは負荷を分け合います。数値が大きいほど、小さい数値のアカウントの後にだけ問い合わせられます。`backup` のアカウントは、すべてのプライマリーが記事を届けられなかった後にだけ使われます。既存の単一アカウントの設定は、そのまま動き続けます:

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # first account: the workhorse
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com   # different backbone = different retention
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com              # metered — only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

各アカウントは、それぞれ独自の接続上限を持ちます。読み込みは、最も小さい、稼働中の `priority` を共有する非バックアップアカウントの**合計上限**で進められます。上の例では 30 + 20 = 50 です。どちらも既定の priority にあるためです。同じ priority にもう 1 つ無制限のプロバイダーを追加すると、保持期間の保険になるだけでなく、スループットも上がります。一方、`backup` のアカウントは、設計上どちらももたらしません。使われるのは、プライマリーが供給できなかった分だけです。これを数えてしまうと、通常の再生では決して使われない容量のために、先読みのウィンドウがすべて広がってしまうからです。

誰に問い合わせるかは、次の 3 つのキーで決まります。

| キー | 既定値 | 効果 |
|---|---|---|
| `name` | `host` の値 | ログ上でアカウントに名前を付けます。 |
| `priority` | `0` | 最初に問い合わせる先を決めます。小さい値から順に問い合わせます。同じ priority のアカウントは、書かれた順に問い合わせられます。ただし、空き接続があるアカウントは、上限を使い切ったアカウントより優先されます。つまり、同じ条件の 2 つのアカウントは、1 つに待たされるのではなく、負荷を分け合います。 |
| `backup` | `false` | 従量課金のブロックアカウントであることを示します。すべてのプライマリーが、記事がないと答えた、壊れたコピーを送ってきた、途中で失敗した、または接続できなかった場合にだけ参照されます。プライマリーが**busy** なだけでは不十分です。無制限のアカウントで済むものに従量課金のバイトを使わないよう、zurg は待機します。 |
| `backbone` | `""` | アカウントが解決先とする記事スプールの名前を指定します。同じ backbone の 2 つのアカウントは同じ記事を持っています。そのため、1 つが記事がないと答えた後は、同じスプール上の他のアカウントは飛ばされます。同じ答えのために往復の時間を無駄にしないためです。 |

各アカウントは、自分の上限の中から、独自のウォーム枠も確保します。保持期間の隙間があると、読み込みはプライマリーを飛ばして直接先へ進みます。そのため、初めて使われるアカウントは、まだ誰も接続コストを払っていないアカウントになります。従量課金のブロックアカウントで、ウォーム接続を一切持たせたくない場合は、`warm_connections: -1` と指定できます。

再販は横行しているので、`backbone` を埋めておく価値があります。別々の会社から購入した 2 つのアカウントが、同じスプールに載っていることがあります。それを指定しないと、どの欠落も 2 回問い合わせることになります。グループ名は好きな文字列で構いません。その文字列は、他のエントリーとの比較にだけ使われます。

起動時に、zurg は使用するすべてのアカウントに名前を付けて表示します:

```
Usenet account nzb connected: nntps://unlimited.example.com:563 (30 connections) + nntps://second-unlimited.example.com:563 (20 connections) [usenetexpress] + nntps://block.example.com:563 (10 connections) [backup] [omicron]
```

リリースを修復する必要があるかを判断する集計では、記事が欠けていると判断する前に、すべてのアカウントに問い合わせます。そして、各アカウントには、前のアカウントが持っていなかったものだけを問い合わせます。転送の失敗は、期限切れになった記事と取り違えられることは決してありません。アカウントがタイムアウトした場合や、途中で記事を落とした場合は、その失敗が報告されます。そのため、タイムアウトによって沈黙が返されたり、存在していたものに対して修復がスケジュールされたりすることはありません。まったく接続できなかったアカウントは数に入りません。別のアカウントが記事は消えたと答えた場合は、消えたものとして扱われます。

### ダッシュボードでプロバイダーを設定する {#configuring-providers-in-the-dashboard}

`http://localhost:9999/config/` → **Essentials** → **Providers** を開くと、YAML を編集せずに同じことができます。テーブルには、設定の順番どおりにすべてのアカウントが並びます:

```
#  Name        Type        Token                Flags
1  realdebrid  realdebrid  …DFFND4OA            —          [Edit] [Delete]
2  nzb         nzb         news.example.com     —          [Edit] [Delete]
```

`nzb` の行では、Token 列にトークンのヒントは出ません。代わりに **news server host**（ニュースサーバーのホスト名）が表示され、その後ろに追加のニュースサーバーの数が続きます。トークンがないので、隠す値がないためです。

**Usenet アカウントを追加する手順:**

1. **Add provider** をクリックします。
2. **Type** を `nzb` に設定します。トークン用の欄が消えて、その場所に NNTP の欄が表示されます。
3. **Name** は、`nzb` 以外にしたい場合だけ入力します。これはアカウントごとのディレクトリ名になります。たとえば `usenet` と入力すると、マウント内では `__usenet__` になります。空欄のままでも構いません。
4. **NNTP host**、**Port**、**TLS**、**Username**、**Password**、**Connections**、**Cache size MB** を入力します。**TLS** はデフォルトでオンになっているので、そのままにしてください。**Connections** の placeholder は `8` です。契約プランで使える接続数を入力してください。**Cache size MB** の placeholder は `512` です。
5. **Watchlist target** はオフのままにします。バックエンドはコンテンツを追加できないため、オンにして保存するとエラーになります。**Disabled** をオンにすると、そのエントリは `config.yml` に残りますが、読み込まれません。
6. **Save** をクリックします。

フォームは、変更が適用された場合と同じように検証されます。そのため、入力ミスがあると壊れた設定になる前にアラートで知らされます。**2つ目**の `nzb` プロバイダーを追加しようとすると、そこでは受け付けられません。エラーは **Further news servers**（または `nntp.servers`）を案内します。追加のニュースアカウントは、そちらに入れるものです。

**別のニュースサーバーを追加する**（2つ目のアカウントや、別のバックボーンのブロックアカウント）には、`nzb` の行で **Edit** をクリックし、**Further news servers** の下にある **Add news server** をクリックします。各サーバーには、**Name**、**NNTP host**、**Port**、**TLS**、**Username**、**Password**、**Connections**、**Priority**、**Backbone**、**Backup only** を設定できます。**Remove server** を押すと、そのサーバーを削除できます。**Save** を押すと、すべてのサーバーが `nntp.servers` に書き込まれます。

**1つを編集するには**、その行の **Edit** をクリックします。フォームにはパスワードを除くすべての情報が読み込まれます。最初のアカウントも、追加した各ニュースサーバーも、パスワード欄は空欄のままになります。空欄は *既存のものを維持する* という意味です。パスワードを変更する場合だけ、新しいパスワードを入力してください。フォームに入力欄がない設定は、`config.yml` の内容のまま残ります。

**Delete** をクリックすると確認が出ます。確定すると、そのプロバイダーのエントリが `config.yml` から削除されます。`nzbs/` ディレクトリは削除されません。NZB ファイルはそのまま残り、プロバイダーを再び追加すると戻ってきます。有効なプロバイダーが1つしかない場合は、削除も無効化もできません。

ここでの変更はすべて `config.yml` に直接書き込まれ、次のメッセージが表示されます:

> Provider changes saved to config.yml — restart zurg to apply

プロバイダーの変更は、**ホットリロードされません**。変更を反映させるには、zurg を再起動してください。

---

## 2. zurg を起動してアカウントを確認する {#2-start-zurg-and-confirm-the-accounts}

+++ Linux と macOS
```bash
./zurg
```
+++ Windows
```powershell
.\zurg.exe
```
+++

`zurg setup` で zurg が自動起動するように設定されている場合は、代わりに `zurg service restart` で再起動してください（Linux/macOS なら `./zurg service restart`、Windows なら `.\zurg.exe service restart`）。

zurg は起動時に Usenet アカウントを一度だけ確認します。パスワードが間違っていると、そのままでは後になって全ファイルの再生が失敗するだけなので、原因がわかりにくいからです:

```
Usenet account nzb connected: nntps://news.example.com:563 (30 connections)
```

全部失敗した場合も、同じくらいはっきり表示されます:

```
Cannot reach the news server for nzb: <reason>
```

まずポートと TLS の組み合わせを確認してください（`563`+`tls: true`、または `119`+`tls: false`）。次に認証情報、最後にプランが実際に有効かどうかを確認します。

**アカウントが複数ある場合は、connected の行だけでなく警告も読んでください。** 接続できなかったアカウントごとに、それぞれ警告が 1 件ずつ出ます。起動は *1 つでも* アカウントが応答すれば続行されるので、上のエラーが出るのは全アカウントに接続できなかった場合だけです。そのため、2 つ目のプロバイダーが動いていなくても、警告に気づかなければ正常に起動したように見えてしまいます:

```
Usenet account block.example.com is not reachable: <reason>
```

---

## 3. NZB ファイルを追加する {#3-add-nzb-files}

zurg は起動すると `nzbs/` という監視フォルダを作ります。zurg を実行しているフォルダの中にできます。NZB ファイルをそのフォルダにコピーしてください。

+++ Linux と macOS
```bash
cp ~/Downloads/Some.Release.2024.2160p.nzb nzbs/
```
+++ Windows
```powershell
Copy-Item "$HOME\Downloads\Some.Release.2024.2160p.nzb" nzbs\
```
+++

1〜2 秒以内に zurg がファイルに気づいて読み込みます。読み込みが終わるとすぐにライブラリに表示されます。ログには何を読み込んだかが出ます:

```
Loaded NZB Some.Release.2024.2160p.nzb: 94 files
```

### 反映されるまでの時間 {#how-quickly-it-appears}

zurg は `nzbs/` そのものを監視しています。約1秒ごとに確認しますが、その確認コストはディレクトリ内の NZB の数に関係なく、システムコール1回分だけです。そのため、ファイルが届くと、次のライブラリ変更チェックの順番を待つことなく、ほぼすぐに読み込まれます。[難読化されたリリース](#obfuscated-releases)は少しだけ時間がかかります。実際のファイル名をその記事から先に読み出す必要があるためで、通常は1秒もかかりません。読み出しが終わった時点で一覧に表示されます。どちらの待ち時間も、もう `check_for_changes_every_secs` には依存しません。以前は依存していました。難読化されたリリースは、ディレクトリの読み込みを待つ1インターバル分と、チェックの直後に名前が解決されたことによるもう1インターバル分、最大で合計2インターバル分も一覧に出てこないことがありました。間隔を10秒にして計測したところ、ドロップからリリースが表示されるまで17.7秒かかっていました。そのうち作業そのものにかかっていたのは0.67秒だけです。

定期チェックは今もあり、最後の砦として残っています。監視対象のディレクトリだけでは検知できない2つのケースを拾うためのものです。1つ目は、すでにある名前のまま NZB が**その場で置き換えられた**場合。2つ目は、ディレクトリのタイムスタンプの精度が粗く、同じ秒内に行われた2つの変更を区別できないファイルシステムの場合です。

### 取り込まれる対象 {#what-gets-picked-up}

- **`nzbs/` の直下にあるファイル**で、名前が `.nzb` で終わるもの（大文字・小文字は区別しません）。
- **サブディレクトリはスキップされます。** `nzbs/movies/foo.nzb` は見えません。整理するのではなく、フラットに置いてください。ライブラリの整理はこのフォルダーではなく、ディレクトリフィルターで行います。
- **プレーンな XML のみ対応です。** `.nzb.gz` は展開も読み込みもされません。先に解凍してください。
- 解析に失敗したファイルは警告とともにスキップされ、スキャンは止まりません。

### リリース名の扱い {#what-the-release-is-called}

zurgが表示する名前、つまりPlexが見るフォルダ名は次のとおりです:

1. NZB自身の `<meta type="name">` の値（その値があって、サニタイズを通っても残る場合）。そうでなければ、
2. **`.nzb` を取り除いたファイル名**。

なので、ほとんどの場合、*NZBのファイル名がそのままリリース名になります*。メディアサーバーはまさにその名前でマッチングを試みるので、リリース名を付けるつもりでファイルに名前を付けてください:

```bash
# good
nzbs/Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb

# bad — Plex has nothing to work with
nzbs/indexer_download_48213.nzb
```

同じ名前になってしまった別々のリリースは、zurgの他の場所と同じく、短いハッシュタグ（`Some.Release {a1b2c3}`）で区別されます。

### パスワード付きのリリース {#password-protected-releases}

インデクサーが NZB のメタデータブロックにアーカイブのパスワードを記録している場合、zurg は RAR セットからストリーミングするときにそれを使います:

```xml
<head>
  <meta type="password">thepassword</meta>
</head>
```

ほかに必要なことはありません。パスワードのメタデータが入っていない NZB のパスワード付きリリースは、開けません。

### 難読化されたリリース {#obfuscated-releases}

ファイル名がランダムな投稿も扱えます。その代わり、コストはスキャン時に一度だけ払われます。

zurgはまず手軽な情報源を試します。それは、記事のyEncヘッダーにまだ宣言されているファイル名です（記事1つにつきファイル1つ）。それでだめなら、リリースのPAR2インデックスにフォールバックします。PAR2インデックスには、各ファイルの本当の名前が、先頭16 KiBのMD5とともに記録されています。

名前と正確なサイズはどちらも記事のヘッダーに入っています。そのため、スキャンはヘッダーが届いた時点で結果を返せます。本体のデータは、後で読み込むためにキャッシュへ取り込まれ続けます。そのため、難読化されたリリースも同じ記事から名前とサイズが決まります。復元した内容はログに記録されます:

```
Recovered 27 filename(s) in Some.Release
```

命名処理全体は、NZBごとに90秒を上限としています。そのため、サーバーに接続できなくても、スキャンが止まることはなく遅れるだけです。ライブラリはファイル名をキーにして作られるため、名前は*ライブラリを作る前に*確定させます。後から名前を変えると、ファイルを見失ってしまうからです。

完全に難読化された投稿には、復元できる本当の名前がありません。投稿者によっては、リカバリーセットを作る前に難読化してしまいます。そのため、PAR2インデックスが復元する名前自体もランダムになります（`aJPSgA7eYizyzjJXT.part01.rar`）。さらに、アーカイブ内のファイルもハッシュ値になっています。投稿の中には、そのリリースが何なのかを示すものがありません。わかるのはNZB自体の名前だけです。

そのため、zurgは中身のファイルをリリース名で表示します。これはSABnzbdが展開の最後に行うのと同じ処理です:

```
Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR/
└── Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR.mkv
```

名前を変えるのは、明らかにリリース本体であるファイルだけです。具体的には、アーカイブ内で最も大きいエントリーで、かつ2番目に大きいものの3倍以上のサイズがあり、拡張子がディスク構造の一部ではなく（`.vob`、`.m2ts`、`.mpls`ではなく）、名前から中身が何も読み取れない場合に限ります。同じ名前を共有する字幕やサンプルも、それに続いて名前が変わります。

似たサイズのファイルが複数入っているアーカイブ（シーズンパックなど）は、どれもリリース本体ではないため、そのままにします。アーカイブ側の元の名前も、引き続きアドレスとして使えます。そのため、再スキャン前に再生を始めたプレイヤーがファイルを見失うことはありません。

### 置き換えと削除 {#replacing-and-removing}

- **Entfernen** einer NZB aus `nzbs/` entfernt das Release aus der Bibliothek, verwirft seinen zwischengespeicherten Reader und den Artikel-Cache und vergisst alle reparierten Bytes, die es gehalten hat.
- **Ein Usenet-Release im Dashboard zu löschen, löscht die `.nzb`-Datei von der Festplatte.** Sie hat keinen anderen Ort, an dem sie liegen könnte. Das ist nicht dasselbe wie ein Torrent aus einem Debrid-Konto zu löschen, bei dem die Datei beim Dienst bleibt.
- **Eine NZB direkt zu überschreiben ist der langsame Weg.** Wenn du über eine Datei schreibst, ändert sich das Verzeichnis nicht, deshalb bekommt die oben beschriebene Überwachung das nicht mit. Stattdessen merkt es die regelmäßige Änderungsprüfung: Sie liest die Änderungszeit der Datei und parst sie neu, und zwar bei der ersten `check_for_changes_every_secs`-Prüfung, die mehr als 15 Sekunden nach dem letzten Verzeichnislesen kommt (bei der Standardeinstellung etwa 30 Sekunden). Wenn du die alte Datei entfernst und die neue hinzufügst, wird das innerhalb von ein oder zwei Sekunden bemerkt. Genau so machen es ohnehin ein Indexer oder der SABnzbd-Endpunkt.

## 4. リリースがマウントのどこに現れるか {#4-where-releases-land-in-the-mount}

Usenet のリリースも通常のライブラリエントリなので、既存の `directories:` フィルターがそのまま適用されます:

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

それとは別に、アカウントには専用のディレクトリが追加されます。デフォルトは `__nzb__` で、プロバイダーエントリに `name:` を設定している場合は `__<name>__` になります。このディレクトリは単なるビューではなく、その下での読み取りは Usenet アカウントに**固定**され、フェイルオーバーはありません。そのため、debrid アカウントが裏で応答していないかを確かめて Usenet 再生をテストするのに最適な場所です。Usenet だけをアカウントとして使っている場合、このフォルダはマウントのルート一覧から外され、同じファイルは `__all__` に入ります。マウント上の `__all__` 配下で再生をテストするか、直接の HTTP パス `http://localhost:9999/http/__nzb__/` を開いてください。

フィルターを書くときに知っておきたい Usenet 固有の点が4つあります。

- **タグフィルターは、Usenet のコンテンツが解析された後に一致します。** `zurg_*` タグ（解像度、HDR、ビットレート、長さ、言語）はすべて ffprobe から得られます。zurg は Usenet ファイルに対しても自分で ffprobe を実行します。自分のサーバー経由で、ニュースサーバーが耐えられる速度で動かすので、解析が済めば Usenet のリリースも他と同じようにタグが付きます。それまでは `tags_match_any` で絞ったディレクトリにはそのリリースは入りません。
- **`.par2` と `.sfv` ファイルは非表示になります。** これらは修復用の補助ファイルです。zurg 自身が読むので、シーズンパックごとに8個もあってもメディアサーバーには不要です。`.nfo` は Kodi、Emby、Jellyfin が読むので残します。
- **RAR セットは展開するアーカイブではなく、コンテンツとして扱われます。** `.rar` と `.rNN` は表示されたままで、ボリュームセットはマウント内に*フォルダ*として現れ、中のファイルがその内容になります。zurg は展開せずに、アーカイブから直接動画をストリーミングします。リリースが*ボリュームセット1つだけ*の場合は、アーカイブフォルダを挟まず、そのリリースが中身を直接表します。ペイロードはリリースフォルダ直下に置かれるので、メディアサーバーもそこを探します。セットと一緒に投稿されたファイル（`.nfo`、投稿者の `.txt`、アートワーク、字幕など）も、そこに引き続き表示されます。
- **`force_select_playable_files` は適用されません。** Usenet の投稿は丸ごと1つなので、選ぶものがありません。コンテンツファイルはすべて最初から提供されます。

メディアサーバーを使う前に中身を確認してください。`http://localhost:9999/http/` は、マウントに表示される内容をそのまま示すシンプルな HTML インデックスです:

+++ Linux と macOS
```bash
curl -s http://localhost:9999/http/__nzb__/ | head
```
+++ Windows
`curl` ではなく `curl.exe` と入力してください。Windows PowerShell 5.1 では `curl` は `Invoke-WebRequest` の別名だからです。

```powershell
curl.exe -s http://localhost:9999/http/__nzb__/ | Select-Object -First 10
```
+++

---

## 5. rclone でマウントする {#5-mount-it-with-rclone}

### 手軽な方法: zurg に rclone を実行させる {#the-easy-path-let-zurg-run-rclone}

```yaml
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run
mount_path: "/mnt/zurg"        # /Volumes/Zurg on macOS, Z: on Windows
```

zurg は、読み取りパターンに合わせてあらかじめ調整された VFS プロファイル（バッファサイズ、チャンクサイズ、キャッシュモード、dir-cache の時間、タイムアウト）を使って rclone を起動し、マウントを維持して、ライブラリが変わったときに正しい dircache エントリを無効化します。`mount_path` は、zurg が Plex にスキャンすべきパスを伝えるときのプレフィックスでもあるので、別の場所にマウントする場合でも必ず設定してください。

確認方法:

+++ Linux
```bash
ls /mnt/zurg/
ls /mnt/zurg/__all__/
```
+++ macOS
```bash
ls /Volumes/Zurg/
ls /Volumes/Zurg/__all__/
```
+++ Windows
デスクトップ上の PowerShell ウィンドウで実行してください。ドライブは、マウントしたログオンセッションからしか見えません（[セッションのルール](../setup/windows.md#keeping-it-running-the-session-rules)）。

```powershell
Get-ChildItem Z:\
Get-ChildItem Z:\__all__\
```
+++

### 手動の方法: 自分で rclone を使う {#the-manual-path-your-own-rclone}

すでに rclone を使っているなら、zurg を指す WebDAV リモートを設定してください:

```ini
[zurg]
type = webdav
url = http://localhost:9999/dav/
vendor = other
pacer_min_sleep = 0
```

+++ Linux
rclone はマウントポイントを作成しません。また `/mnt` は root の所有です:

```bash
sudo mkdir -p /mnt/zurg && sudo chown "$USER" /mnt/zurg
rclone mount zurg: /mnt/zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ macOS
[macFUSE](../setup/macos.md#step-1-install-macfuse) と [rclone.org](https://rclone.org/downloads/) の rclone が必要です。Homebrew 版の rclone ではマウントできません。rclone はマウントポイントを作成しません。また `/Volumes` は root の所有です:

```bash
sudo mkdir -p /Volumes/Zurg && sudo chown "$USER" /Volumes/Zurg
rclone mount zurg: /Volumes/Zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ Windows
[WinFsp](https://winfsp.dev) が必要です。ドライブレターが使用中でないことが必要で、マウントは rclone を実行しているログオンセッション内のプログラムからしか見えません（[セッションのルール](../setup/windows.md#keeping-it-running-the-session-rules)を参照）。

```powershell
rclone mount zurg: Z: --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++

`--vfs-handle-caching 0` には rclone 1.74 以降が必要です。これを指定すると、読み取り側がファイルを閉じた後も rclone が 5 秒間ダウンロードを続けるのを防げます。省略した場合のコストについては README で説明しています。

それでも `config.yml` の `mount_path` には、マウントした場所を設定してください。設定しないと、メディアサーバーのスキャン通知が間違ったプレフィックスで作られてしまいます。

### Docker

zurg の作業ディレクトリはイメージ内で `/config` です。監視ディレクトリと修復キャッシュはどちらもその下にあります。1 つのバインドマウントで、それらすべてをまとめて渡せます:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:latest
    volumes:
      - ./:/config
    ports:
      - 9999:9999
```

ホスト側の `./nzbs` に NZB を置くと、再起動なしでコンテナ内でも自動的に読み取られます。

このマウントには Linux ホストが必要です。macOS と Windows の Docker Desktop は、コンテナを VM 内で動かすため、マウントは Finder、エクスプローラー、ホストにインストールした Plex まで届きません。そちらでは [macOS](../setup/macos.md) または [Windows](../setup/windows.md) 版のバイナリを使ってください ([理由](../setup/docker.md))。

> `/config` が `/app/config.yml`、`/app/nzbs`、`/app/data` を個別にバインドマウントする前にインストールした環境は、以前と同じように今まで通り動きます。詳しくは [docker.md](../setup/docker.md#upgrading-an-install-that-mounted-app) を参照してください。

---

## 6. Plex を接続する {#6-point-plex-at-it}

1. **zurgにPlexの認証情報を渡してください。** そうすると、定期的なフルスキャンを待たなくても、変更されたパスだけをスキャンするようPlexに依頼できます。一番簡単なのはDashboardのPlex認証フローを使う方法です。その値が`config.yml`に書き戻されます:

   ```yaml
   plex_server_url: "http://localhost:32400"
   plex_token: YOUR_PLEX_TOKEN
   ```

2. **ライブラリは、マウントのルートではなく、マウント内のサブディレクトリを指すように追加してください:**

   - Movies → `/mnt/zurg/movies`（macOSでは`/Volumes/Zurg/movies`、Windowsでは`Z:\movies`）
   - TV Shows → `/mnt/zurg/shows`（macOSでは`/Volumes/Zurg/shows`、Windowsでは`Z:\shows`）

   Windowsでは、Plexがzurgと同じログオンセッションで動いている場合にのみ`Z:`が見えます。`zurg setup`のログオンタスクがこれを用意してくれます。詳しくは[セッションのルール](../setup/windows.md#keeping-it-running-the-session-rules)をご覧ください。

   同じリリースは、そのリリースにフィルターが一致するすべてのディレクトリに加えて、`__all__`と`__nzb__`の下にも現れます。Plexをルートに向けると、同じファイルを何度もスキャンしてしまいます。

3. **各ライブラリのEdit → Advancedで、次の2つのオプションを設定してください:**

   - **"Empty trash automatically after every scan"のチェックを外してください。** これが一番重要です。スキャン中にマウントが一瞬途切れると（zurgの再起動やrcloneの再マウントなど）、Plexはすべてのファイルが削除されたと判断します。この設定が有効だと、ファイルは即座に完全に削除されます。無効なら、ゴミ箱に残り、マウントが戻ったときに再び表示されます。以前、30,000件のライブラリでこの被害が出たことがあります。
   - **"Generate video preview thumbnails"のチェックを外してください。** サムネイルは1枚ごとにファイル全体へのシークになります。Usenetでは、それはリリース全体を接続の許容量を使って読み込むことを意味します。

4. **Plexのスキャン中はzurgを絶対に再起動しないでください。** 再起動する前に確認してください:

   ```bash
   TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
   curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'
   curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l
   ```

   Windowsでは、zurgのフォルダーからPowerShellで実行してください:

   ```powershell
   $TOKEN = ((Select-String -Path config.yml -Pattern '^plex_token:').Line -split '\s+')[1].Trim('"', "'")
   (Invoke-RestMethod "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN").MediaContainer.size
   @((Invoke-RestMethod "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN").MediaContainer.Directory | Where-Object refreshing -eq 1).Count
   ```

   `size="0"`（Windowsでは`0`）のセッションがあり、更新されるカウントが`0`であれば安全です。セッションの行が何も表示されない場合、Plexがトークンを拒否したか応答しなかったことを意味します。その下の`0`は意味がありません。再起動前に`plex_token`を確認してください。（PowerShellでは代わりに`401`エラーとして表示されます。）
   （`grep -c`ではなく`grep -o … | wc -l`を使ってください。grepは何も見つからないと非ゼロで終了します。それはむしろ*良い*ケースですが、守ろうとしていた再起動の直前に`&&`チェーンを中断させてしまいます。）

5. **部分スキャン。** `on_library_update`には、変更されたすべてのパスが渡されます。リポジトリのルートにある`plex_update.sh`が参考スクリプトです:

   ```yaml
   on_library_update: sh plex_update.sh "$@"
   ```

   このスクリプトには`curl`、`xmllint`、`python3`が必要です。Dockerイメージにはこれらが入っています。また、`zurg_mount`の行をマウントのパスに設定してください。Windowsでは、フックは`sh`ではなくPowerShellで動くため、このスクリプトはそこでは動きません。変更された各パスは`$args`の1つの要素として渡されます。マウントからの相対パスで、スラッシュは前向きです（`movies/Big Buck Bunny`）。PowerShellスクリプトには`@args`で渡してください:

   ```yaml
   on_library_update: '& C:\zurg\my_update.ps1 @args'
   ```

   手順1が終わり`mount_path`が設定されていれば、zurgはすでに変更されたパスのスキャンをPlexに依頼しています。そのため、フックが必要なのはそれ以外の場合だけです。

**Usenetのコンテンツでは、Plexがすぐに得られないもの:** zurgが解析を終えるまでは何もありません（セクション4を参照）。そのため、ローカルファイルと同様に、最初の再生時にPlexが独自に解析する場合があります。ファイルサイズは、リリースがスキャンされた後すぐに確定します。最初の一覧では記事数から求めた概算値が表示されることがあり、正確なサイズはその後に届きます。リカバリーインデックスがあればそこから、なければ各ファイルの1記事から得られます。リカバリーインデックスにすべての正確なサイズが記載されている大きなマルチボリュームのアーカイブでは、検証済みの1ボリュームから共通の記事ストライドを確定できます。同じアーカイブの他の各ボリュームは、最初のバイトを返す前に、その推論を自身のヘッダーと照合します。サイズが確定すると、ライブラリにはリリースが変更されたと通知されるため、マウントとPlexの両方が実際のサイズを認識します。

zurgは、接続数が12以下のアカウントでは一度に最大8つのリリースのサイズを確認します（アカウントの接続数を超えることはありません）。接続数が多いアカウントではさらに多くなります（16接続では12、20接続以上では16）。取得処理がニュースサーバーでリリースを確認するときは、その確認はこのサイズ確認や先読みと並んでキューに入ります。プレーヤーが待っている読み込み用の接続を奪うことは決してありません。

### Jellyfin / Emby / Infuse

Jellyfin と Emby は `jellyfin_server_url` / `jellyfin_token` と `emby_server_url` / `emby_token` を使い、同じスキャン通知を受け取ります。詳しくは [jellyfin.md](jellyfin.md) を見てください。Infuse は `http://<host>:9999/dav/` に直接つなげるので、rclone はまったく不要です。

---

## 7. 記事が見つからないとき {#7-when-an-article-is-missing}

これは Usenet にあって、debrid にはない故障パターンです。記事はプロバイダーの保持期間を過ぎて消えたり、削除されたりします。リリースは一覧にはきちんと出ていても、一部の記事だけがなくなっていることがあります。

zurg の対応策は、優先度の高い順に次のとおりです:

1. **別のニュースサーバーに問い合わせる。** あるプロバイダーで期限切れになった記事が、別のプロバイダーにはまだ残っていることがよくあります。取得は1回だけです。[複数の Usenet プロバイダー](#more-than-one-usenet-provider) を参照してください。
2. **リリース自身の PAR2 ファイルから復元する。** PAR2 はそのためにポストされているものです。ただし、*リリース全体*を読み込む必要があります。Reed-Solomon は、欠けた部分を求めるために残っているすべてのスライスを畳み込み計算しなければならないからです。つまり 200 GB の投稿であれば、数メガバイトを復元するのに 200 GB を読むことになります。
3. **無音を返す。** 上記のどちらも応答できない場合にのみ行います。

PAR2 の修復はバックグラウンドジョブとして動作し、同時に処理するリリースは最大2つまでです。必要なものは次のとおりです:

```yaml
enable_repair: true            # the default; set false to turn PAR2 repair off
par2_patch_cache_mb: 512       # budget for data/par2/; -1 keeps repairs in memory only
```

復元されたバイト列は `data/par2/<nzb-id>/` 以下に書き込まれ、次回そのファイルを開いたときに再利用されます。そのため、再起動してもリリース全体を読み直す必要はありません。実際に欠けている範囲だけが保存されます。損傷したリリースの場合、通常は数メガバイトで済みます。上限を超えた場合は、リリース全体が最も長く使われていないものから順に削除されます。各リリースの範囲には、復元元となった NZB の更新日時が記録されます。そのため NZB を保存し直すと、それらの範囲は破棄され、位置がずれているかもしれないバイト列を返すことはありません。

修復は開始時にそのことを知らせ、その後かかったコストを報告します:

```
PAR2 repair of Some.Release: 5 slice(s) missing; reading the release to rebuild them
PAR2 repair of Some.Release rebuilt 5 slice(s) in 55s on the avx2 kernel, keeping 3.4 MiB of them (library holds 3.4 MiB in memory, 3.4 MiB on disk)
```

知っておくと良いことが2つあります:

- **再生は常に修復より優先されます。** 接続は待っている処理の順に割り当てられます。まず要求された読み込み、次に先読み、修復は最後です。ただし修復には、先読みに対して許容数の4分の1が保証されています。そのため、再生中のファイルは、詰まっている欠損部分を今でも修復できます。
- **zurg のライブラリレベルの修復では、ここでは役に立ちません。** その仕組みは、トレントを元のアカウントに再追加するものです。コンテンツを追加できないバックエンドは、リリースが壊れていると報告することはできても、修復はできません。Usenet の場合は、PAR2 *こそ*が修復手段です。

NZB に PAR2 ファイルがなく、2つ目のニュースアカウントもないリリースには、復旧の手段が一切ありません。これは投稿そのものの性質であり、zurg の問題ではありません。

---

## パフォーマンス {#performance}

| | |
|---|---|
| 単一ストリーム、直接ファイル | ~100 Mbit/s |
| 単一ストリーム、RAR セットから | 90–106 Mbit/s |
| 同時 2 ストリーム、合計 | ~124 Mbit/s |

単一ストリームの速度の最初の上限を決めるのは、接続数の上限です。zurg は、記事とバイト数の両方で先読み量を決めて、この上限を使い切るようにしています。小さい記事のアーカイブ投稿では、最低 64 MiB 先まで読みます。数 MB の投稿では、今まで通りの接続数とパイプラインの幅を使います。だから次のようになります。

- **`connections` は、契約プランの実際の数に設定してください。** これが調整のつまみです。8 接続では remux はストリーミングできません。
- **プライマリアカウントを 2 つ使うと、合計されます。** 読み込みは、現在有効な最も低い `priority` を持つ、`backup` 以外のアカウントの接続数の合計で行われます。同じ優先度の 2 つ目の無制限プロバイダーがあれば、上限が上がるだけでなく、1 つ目の保持期間の欠落もカバーできます。`backup` アカウントは、この合計には含まれません。
- **`warm_connections`（デフォルトは 4）は、スループットではなくレイテンシを改善します。** この数の接続を、アイドル状態で認証済みのまま開いておきます。そのため、起動直後や静かな時間帯のあとの最初の読み込みで、最初のバイトが届くまでに約 0.8 秒の接続時間を使わずに済みます。コールドでは最初のバイトまで 1.5 秒、ウォームでは 0.15 秒です。ストリームが動き始めると、この設定は何も変えません。
- **発生する接続は 1 つのバックエンドに固定されるので、TLS セッションが再開されます。** 1 回の接続には約 0.8 秒かかります。これは 2026-08-29 に、実際のニュースサーバーで測定した値です。内訳は、TCP が 106ms、TLS ハンドシェイクが 213ms、挨拶が 256ms、`AUTHINFO` のやり取り 2 回で 218ms です。プロバイダーのホスト名は、ローテーションされるアドレスの集まりになります（このホストは 11 個のアドレスに解決されます）。また TLS セッションチケットは、発行したマシンでしか使えません。そのため、リゾルバーが最初に返したアドレスに毎回接続し直すと、セッションは **3 件中 0 件**しか再開されませんでした。同じアドレスに接続し直すと、**3 件中 3 件**が再開されました。今では各アカウントが、直前の接続で使ったアドレスに再接続します。これにより、再接続のたびに **110〜140ms** 短縮されます。再開されたハンドシェイクは 109〜141ms で、フルのハンドシェイクは 225〜261ms です。ラウンドトリップが約 18ms のサーバーでは、短縮効果はこれより小さくなります。そのアドレスが応答しなくなると、固定は解除され、名前が改めて解決されます。そのため、プロバイダーが廃止したマシンに固定されたままになることはありません。ただし、NNTP まで届いた拒否は固定を維持します。たとえば、アカウントが接続上限に達している場合や、パスワードが拒否された場合です。それはバックエンドの判断ではなく、アカウントの応答だからです。接続のたびに、各フェーズを debug レベルでログに出します。`resumed=` も含まれます。
- `cache_size_mb`（デフォルトは 512）は、読み込み中のすべてのファイルで共有されます。同時に複数のストリームを動かすなら、この値を上げてください。ただし、1 ストリームが速くなるわけではありません。投機的な読み込みが確保できるのは、その半分までで、かつ最大 2 つのリーダーまでです。残りの半分は、すでに消費した記事や、これから消費する記事のために空けておきます。
- RAR でパックされているか、普通のファイルとして投稿されているかは、もはやスループットにはほとんど影響しません。

**遅い記事 1 本で、ストリームが止まることはなくなりました。** 平均 約 90 MB/s で順番に読み込んでいても、1 秒ほど 1〜5 MB/s に落ち込むことがあります。その落ち込みはすべて同じ原因です。ほかの接続が自分の記事を終えてアイドルになる間に、ある記事が届かなくなっているのです。読み込みが 1 つの記事で、そのリーダーが普段想定している時間より長く待たされると、zurg は同じ記事を **2 本目の接続**に要求し、先に届いた方を返します。パイプライン処理された止まったバッチは、同じ死んだソケット上で連続する再生ヘッドの記事を複数ブロックすることがあります。そのため、1 つのリーダーから最大 5 本の異なる記事を、まとめてヘッジすることがあります。投稿の記事が 1 MiB 未満の場合は、1〜2 本です。同じ記事を 2 回要求することはありません。アカウントが払うのは、2 本目の要求を 1 分あたり最大 20 件までです。締め切りは、そのリーダー自身の直近の待ち時間の 2 倍です。下限は 250 ms（1 MiB 未満の記事の投稿では 125 ms）、上限は 2 s です。ヘッジされるのは、クライアントが実際に待っている読み込みだけです。先読み、次のボリュームのプリフェッチ、修復はヘッジされません。サーバーがたった今 *拒否* した記事も、ヘッジされません。その記事はすでに 1 秒後の確認を待っていて、その時間内に要求しても、何も証明できないからです。ヘッジのたびに、読み込みが何ミリ秒ブロックされたかを示す行を debug レベルで 1 行出力します。その次の行は、2 本目の要求が勝ったかどうかを示します。

宣言された範囲については、後のバイトが提供される前に、再生ヘッドの記事が優先度スケジューラに入ります。パイプライン処理された接続には、連続したチャンクではなく、連続する記事のラウンドが割り当てられます。そのため、最初に役立つ記事が接続枠全体に分散されます。64 MiB 以上のリクエストは再生として扱われ、範囲のフロンティア全体を使います。小さなシークは probe のままで、狭いランプだけを開きます。

### ボリューム境界をまたぐ場合 {#crossing-a-volume-boundary}

RAR セット内のファイルは、一度に1ボリュームずつ配信されます。各ボリュームは、ニュースアカウントへの個別の読み込みになります。zurg は、現在のボリュームの再生中に次のボリュームを開き、その先頭4 MB を読み込みます。そのため、ボリュームの切り替え時に読み込みがゼロから始まることはありません。小さなボリュームで投稿されたリリースでは、この先頭部分だけでは不十分です。4 MB は ~395 KB のパートで投稿されたリリースの約10記事分にあたり、~26 MB のボリュームだと再生1.7秒ごとに境界が来てしまいます。そのため、ストリームはメモリ上の先頭部分を0.25秒で使い切り、その後は残りのデータを待つ往復通信を繰り返していました。Hetzner CCX23 で10接続を使い、2026年9月8日に測定したところ、このリリースの配信速度は **14〜16 MB/s** でした。同じアカウント上の通常のファイルは **86〜99 MB/s** に達していたので、大きな差があります。1秒あたりの速度も 1 MB/s から 29 MB/s の間で大きく揺れていました。さらに、アカウントの先読みスロット60個のうち、46〜55個が使われずに余っていました。

zurg は、ストリームが境界から 32 MiB 以内に近づくと、次のボリュームを先読みウィンドウ1つ分まで深く温めるようになりました。また、ストリームが切り替わったばかりのボリュームは、最初の2記事からやり直すのではなく、それまでに獲得したウィンドウを維持します。再生位置がまだ数秒先にならないボリュームは、これまでどおり先頭部分だけを温めます。これにより、ライブラリスキャン（各エントリに対するリーダーが、それぞれ数 MB ずつ読む処理）が、読まれることのない次のボリュームすべてのウィンドウを読み込んでしまうことを防げます。この変更に設定は必要なく、メモリの上限も変わりません。アカウントは引き続き、再生中のボリュームと温めている次のボリュームの2つ分の先読みウィンドウを、`cache_size_mb` の範囲内で使います。

修復処理は本質的に時間がかかります。リリース全体を読むためです。ただし、修復はバックグラウンド優先度で実行され、速度はzurg の計算ではなく、ニュースサーバー側の制限によって決まります。

### メモリ: ウォッチディレクトリのコスト {#memory-what-a-watch-directory-costs}

NZB は記事のリストで、大きなライブラリには記事がたくさんあります。パースすると、各記事のメッセージ ID とそのオフセットがメモリに保持され、読み取り時にそれらを見つけられるようになっています。以前のビルドでは、プロセスが動いている間ずっとすべての記事を保持していました。2,636 個の NZB を入れた監視ディレクトリ（`<segment>` 要素 2,760 万個）で測ったところ、記事 1 件あたり約 58 バイト、**1.52 GB のライブヒープ**を使っていました。記事キャッシュとは別です。そのほとんどは実際には使われていません。一覧表示に必要なのは名前、サイズ、数だけで、記事の名前がわかる必要があるのは、実際に読み取られているか修復されているファイルだけです。

`nzb_segments` で、zurg がこれらを保持するかどうかを決めます。

```yaml
nzb_segments: mmap             # mmap (default) | reparse | resident
nzb_segments_idle_secs: 120    # how long a release's articles are kept after the last read
```

- **`mmap`**：リストは `data/nzb-index/<id>.bin` に書き出され、そのファイルはオンデマンドでマップされます。そのためデータは zurg のヒープではなくページキャッシュに置かれ、メモリが逼迫するとカーネルが回収します。**Linux、macOS、BSD でのデフォルトです。** ディスク容量はリスト自体とほぼ同じだけ使います。
- **`reparse`**：リリースが落ち着いたらリストを解放し、読み取りや修復が必要になったときに NZB をディスクから読み直します。ディスクは一切使いません。これを選ぶ理由はそこにあります。`data/` が大きくなってはいけないホストで使います。
- **`resident`**：すべての記事リストを常にメモリに置きます。**以前の動作**で、それ以前のすべてのビルドがこの方式でした。今も対応していますが、もうデフォルトではありません。

どの設定でも、一覧表示では何も読み込みません。ファイル名、サイズ、記事数は、記事リストをメモリに置かずに返されます。そのため、ライブラリの更新、フィンガープリントの確認、*arr がジョブの完了を問い合わせる処理は、どれもメモリを消費しません。遅延モードのコストは、`nzb_segments_idle_secs` の間（スイープは 30 秒ごとに実行されます）誰も触れていないリリースを初めて読むときに出ます。また、リリースのファイルは全部まとめて読み込まれます。そのため、シーズンパックの rar ボリュームを順番にたどると、読み込みコストは一度だけ払うことになります。

60 ファイル、記事 30,000 件のリリースで測ると次のようになりました。

| | リリースごとのヒープ | 停止中リリースの初回読み取り | 読み取りパスでの記事 1 件あたり |
|---|---|---|---|
| `resident` | 1.74 MB | — | 6 ns |
| `reparse` | 21.3 kB | 39 ms | 52 ns |
| `mmap` | 16.6 kB | 0.27 ms | 63 ns |

記事 1 件あたり 50 ナノ秒は、1 件取得するのにかかるミリ秒単位の時間に比べれば無視できる量です。そのため、読み取りパスの数字は見た目ほど重要ではありません。注目すべきは再読み込みです。`reparse` は XML 文書全体を読み直してパースし直します。シーズンパックでは、最初のバイトが動くまでに数十ミリ秒かかります。`mmap` の場合は `mmap` 呼び出し、ファイルごとのスライスヘッダー、そして今マップしたインデックスのチェックサム計算だけです。合計 0.08 ms で、残りの 0.19 ms は不正なバイトを、メッセージ ID として配信する前に検出するための代償です。

リリース 1 件ではなく、ライブラリ全体で測るとこうなります。2,636 個の NZB、記事 2,760 万件。同じコーパスで同じバイナリを 3 回実行し、スキャン後にアイドル状態にしました。

| | 常駐セット | ライブヒープ | アイドル時の CPU | コールドオープン（p50） | ディスク上のインデックス |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

ウォームオープン（1 ms）、ストリーミングのスループット（38〜39 MB/s）、起動時間は、3 つのモードでほとんど差がありませんでした。`mmap` は、コールドのリリースを全部メモリに置いておくより*速く*開けます。`resident` でも、この実行中に一度も開かれていないリリースはパースしなければならないからです。書き出されたアリーナをマップするのはシステムコール 1 回で済みますが、パースには数メガバイトの XML 処理が必要です。

インデックスは NZB が変わるたびに自動で書き直されます。読めなくなったときは自分で修復します。NZB に戻って書き出し直すのです。NZB が監視ディレクトリから消えると、インデックスも削除されます。ヘッダーと中身の両方にチェックサムが付いているので、不正なバイトは、誰も投稿していないメッセージ ID として配信される前に検出されます。現在のサイズは、ダッシュボードのトップページの **Article Index** に表示されます。起動時にバックエンドが出力するログの行にも書かれています。**Windows** にはマッピングがありません。代わりにインデックスをヒープに読み込むことになりますが、それは常駐メモリに加えて再読み込みも発生する形になります。そのため Windows のデフォルトは `resident` のままで、遅延モードを選ぶなら `reparse` が候補になります。

## トラブルシューティング {#troubleshooting}

| 症状 | 原因 | 対処法 |
|---|---|---|
| 起動時に `Cannot reach the news server for nzb` と表示される | host/port/TLS の組み合わせが間違っている、認証情報が正しくない、またはプランが有効でない | `563` は `tls: true`、`119` は `tls: false` にします。そのあと認証情報を確認し直してください |
| ライブラリが空で、`Loaded NZB` の行がない | `nzbs/` がない、または置き場所が違う | zurg の**作業ディレクトリ**からの相対パスです。systemd ユニットの `WorkingDirectory=`、Docker の場合は `/config` にマウントされているディレクトリ（compose ファイルの横にある `nzbs/`）を確認してください。`/config` より前のインストールだけが `/app/nzbs` を監視します |
| 特定の NZB が表示されない | サブディレクトリにある、`.nzb.gz` という名前になっている、または解析できない | `nzbs/` 直下に移動し、展開してください。ログで `Skipping` の警告がないか確認してください |
| リリースが意味のない名前で表示される | `<meta type="name">` がない場合、NZB のファイル名がそのまま名前になる | `.nzb` ファイルの名前をリリース名に変更してください |
| リリース内のファイル名がランダムになっている | 難読化された投稿で、復元に失敗している | `Recovered N filename(s)` があるか確認してください。NZB に PAR2 ファイルが含まれていないと、本当の名前を取得する元がありません |
| フォルダは正しいのに動画名がランダムのまま | 完全に難読化された投稿で、アーカイブに似たサイズのファイルが複数入っている | はっきりした単一のメインファイルだけがリリース名に変更されます。1 つのアーカイブにまとめられたシーズンパックは、アーカイブが持っていた名前のままになります |
| ストリーミングが遅い | `connections` がデフォルトの 8 のまま | プランで許可されている数に設定してください |
| しばらく再生していなかった後の最初の再生が、開始まで 1 秒ほどかかる（その後は問題ない） | warm floor がオフになっているか、1 接続のアカウントによって 0 に制限されている | `warm_connections` は未設定のままにしてください（デフォルトは 4）。`warm_connections` と、トップレベルの `warm_connections` のどちらも負の値に設定されていないか確認してください |
| プロバイダーに接続が拒否される | `connections` がプランの上限を超えている | 実際の上限値まで下げてください |
| 再生がカクつく、またはギャップが無音になる | 記事が欠けている | ログで `PAR2 repair of …` を探してください。`enable_repair: true` になっているか確認し、[別の Usenet プロバイダー](#more-than-one-usenet-provider)を追加してください |
| ギャップが無音のままで、修復の行が一切出ない | `enable_repair` がオフになっているか、NZB に `.par2` ファイルが含まれていない | `enable_repair: true` に設定してください。投稿に復旧用ファイルがない場合、別のニュースアカウントしか助けになりません |
| 2 つ目のプロバイダーに一度も問い合わせられていないようだ | 両方のアカウントが同じ `backbone` を持っていて、1 つ目が記事なしと答えた時点で 2 つ目がスキップされている | `backbone` の値を修正してください。本当に同じスプールにあるアカウントだけが同じ名前を共有すべきです |
| 複数のアカウントのうち 1 つが使えないのに、起動は正常に見えた | 起動に失敗するのは、*すべての*アカウントに接続できない場合だけ | ログで `is not reachable` を検索してください。問題のあるアカウントごとに名前付きで警告が出ます |
| 無制限のアカウントが持っている記事について、従量課金のアカウントに課金されている | そのアカウントに `backup: true` が設定されていない | 設定してください。これでプライマリが単に混雑しているだけの場合に、読み取りが従量課金のアカウントへ回されなくなります |
| タグでフィルタしたディレクトリにリリースが表示されない | まだ解析されていないため、`zurg_*` タグが付いていない | 解析が終わるのを待つか、Dashboard から Analyze & Tag Library を実行してください |
| マウントに `.par2` ファイルが表示されない | 意図的な仕様で、修復用の補助ファイルとして非表示になっている | 対処は不要です。zurg は引き続きこれらを読み込みます |
| Dashboard でプロバイダーを変更したが何も起きない | プロバイダーの変更は `config.yml` に書き込まれるが、ホットリロードはされない | zurg を再起動してください。プロバイダー表の下のバナーにもその旨が書かれています |
| zurg の再起動後に Plex のライブラリが空になった | マウントが切れている間にスキャンが進行中で、auto-empty-trash が有効だった | auto-empty-trash を無効にし、再起動の前には必ずセッションを確認して、状態を更新してください |
| リリースが表示された直後、ファイルサイズがわずかに変わった | 最初の一覧は記事数からの推定しかできず、正確なサイズは後から PAR2 インデックスまたはファイル自身の yEnc ヘッダーから届く | 想定どおりの動作で、一度で落ち着きます。サイズは `data/nzb-sizes/` に保存され、NZB が変わるまで保持されます |

### 1 つの記事について問い合わせる {#asking-about-one-article}

`GET /debug/nzb/probe` は、zurg がすでに使っているプールを通じて、ニュースアカウントに 1 件の問い合わせを送ります。優先度は通常のデマンド読み取りと同じです。このエンドポイントがあるのは、ほかの方法がうまくいかなかったからです。アカウントの接続数は 8 本で、zurg がその 8 本をすべて使ってしまいます。そのため投稿を手動で確認しようとすると、別のアカウントを用意するか、サーバーを止めるしかありませんでした。しかしサーバーを止めると、調べたい状態そのものが消えてしまいます。

Windows では、これらのコマンドで `curl` ではなく `curl.exe` を入力してください。

```bash
# Is this article still there? A STAT, so nothing is transferred.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?message_id=abc@news.example'

# The same question addressed the way you have it: a release id from the
# library, a file index counting from zero, an article number counting from one.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&file=0&article=3'

# &body=1 fetches the one article and reports what actually arrived against what
# the article says should have. This is how a provider that strips trailing
# bytes is identified: `short: true` with `decoded_bytes` below `span_bytes`.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&article=3&body=1'
```

レスポンスは `{"probes": [...]}` の形で返ります。`nzb` プロバイダーの 1 件のオブジェクトに、`found`(見つかったか)、`missing`(見つからなかったか)、かかった時間が入ります。ニュースアカウントには優先順に問い合わせていき、どれかが記事を持っていた時点で止まります。バックアップのアカウントは、プライマリがすべて見つけられなかった場合にだけ問い合わせます。どのニュースアカウントが記事を持っていたかは返りません。このエンドポイントは読み取り専用です。取得したデータが記事キャッシュに入ることはありません。また、見つからなかった記事が「dead」として記録されることもないので、再生できているファイルがこの問い合わせで止められることはありません。

---

まだ解決しませんか？ [Discord](https://discord.com/invite/7u4YjMThXP) の **zurg-support** フォーラムで質問してください。何を書けばよいかは [サポートの受け方](../../guides/remote-help.md) にまとめてあります。

## 関連項目 {#see-also}

- [config.md](../reference/config.md) — すべてのオプション。[Usenet アカウントのリファレンス](../reference/config.md#usenet-accounts)と[ディレクトリフィルターのリファレンス](../reference/config.md#7-directories--filters)も含みます。
- [plex.md](plex.md) — zurg が Plex のスキャン、マッチング、ゴミ箱掃除をどう動かすか
- [jellyfin.md](jellyfin.md) — Jellyfin との連携
- [docker.md](../setup/docker.md) — Docker のセットアップ、FUSE の伝播、トラブルシューティング
- [tags.md](../reference/tags.md) — タグシステム
- [architecture.md](../internals/architecture.md) — 全体の中での `internal/nzb` と `internal/nntp`
