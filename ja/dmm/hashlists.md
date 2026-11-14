# DMMハッシュリスト：他の人のライブラリを自分のものに追加 {#dmm-hash-lists-add-someones-library-to-yours}

ハッシュリストとは、DMM を使ってだれかがデブリッドのライブラリから共有したリリースの一覧です。リストを開き、DMM にデブリッドサービスでサインインして、サービスのボタンを押してください。リリースが自分のアカウントに追加されます。共有リストは [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com) にあり、DMM の **Library** にある **Share List** から自分のリストを共有できます。

リストにはリリース名、そのハッシュ、サイズが入っています。ファイルやアカウントは含まれません。

## リストを探す {#find-a-list}

- DMM のホームページで **Hash lists** を押します。[hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com) が開き、ランダムなリストが表示されます。**Previous hash list**、**Random hash list**、**Next hash list** でリストを移動できます。
- リストは [Discord](https://discord.com/invite/7u4YjMThXP) の **hashlists** フォーラムに投稿されています。各リストは `https://hashlists.debridmediamanager.com/<id>.html` のようなリンクになっています。それを開くと、DMM でそのリストが開きます。

## リストを自分のライブラリに追加 {#add-a-list-to-your-library}

1. リストを開きます。**Login to RD/AD/TB/PM/OC/DL to download** と表示されている場合は、同じブラウザで先に [DMM](https://debridmediamanager.com) にサインインし([サインインの方法](index.md#sign-in)を参照)、その後にリストをもう一度開きます。
2. DMM は、お使いのサービスにすでにあるリリースを確認します。表示されるのはそれらだけで、ライブラリにすでにあるものは除外されます。緑色の **hidden** ボックスには、除外された件数が表示されます。
3. 必要に応じて絞り込みます:
   - **Movies** と **TV Shows** では、どちらか一方の種類だけを表示します。数字はファイル数ではなくタイトル数です。
   - **One per title** は、各タイトルで最も良いリリースを 1 つだけ残します。
   - タイトルの横にある緑色の **other files** チップを押すと、そのタイトルのすべてのリリースが表示されます。
   - **quick search on filename, hash, or id; supports regex** で、リストを検索できます。
4. 行のボタン(**RD**、**TB**、**AD**、**PM**、**OC**、**DL**)を押すと、そのリリースを 1 つだけ追加します。
5. または **RD Download**(**TB Download**、**PM Download** など)を押すと、表示されているすべてのリリースを追加します。ボタンの数字は追加する件数です。DMM は先に確認します。たとえば **Add 11 releases to Premiumize?** と表示されたら、**Add 11** を押して開始します。

![Premiumize でサインインした DMM の共有ハッシュリスト(オープンな映画)](../assets/dmm-hashlists/01-hash-list.webp)

**Show All** を押すと、お使いのサービスにないリリースも表示されます。**Show Instant** を押すと、キャッシュ済みのリリースだけの表示に戻ります。

**RD Download** は、Real-Debrid にすでにあるリリースだけを追加します。Real-Debrid は、短時間に追加しすぎるアカウントを一時停止するため、1 分に 1 件ずつ追加されます。60 件なら約 1 時間かかります。追加はページ内で行われるため、**Started 60 downloads.** と表示されるまでタブを開いたままにしてください。TorBox と AllDebrid は、キャッシュされていないものを飛ばします。

## 自分のライブラリを共有 {#share-your-own-library}

1. DMMのホームページで**Library**を押します。
2. 共有したいリリースを検索するか、チェックを入れます。何もチェックしなければ、表示されているすべてが共有されます。
3. **Share List**を押します（3つチェックを入れていれば**Share (3)**と表示されます）。**Enter a title for the hash list**に名前を入力して**OK**を押します。
4. DMMが、リストの新しいアドレスをhashlists.debridmediamanager.comで開きます。公開されるまでの1〜2分間は404と表示されることがあります。更新してから、そのアドレスを共有してください。

![Share Listを押した後のタイトル入力画面](../assets/dmm-hashlists/02-share-list.webp)

共有リストは公開されます。アドレスを知っている人なら誰でも開けますし、**Random hash list**では見知らぬ人にもあなたのリストが表示される場合があります。含まれるのは名前、ハッシュ、サイズだけです。アカウント、キー、トラッカーのアドレスは含まれません。

何も公開せずに1つのリリースだけを共有したい場合は、ライブラリでその行の末尾にある共有アイコンを押します（または詳細画面の**Hashlist**を押します）。DMMが1リリースだけのリストを開きます。そのページのアドレスをコピーして送ってください。

## 問題が起きたとき {#when-something-is-wrong}

| 画面に表示されるもの | 対処方法 |
|---|---|
| **Login to RD/AD/TB/PM/OC/DL to download** | このブラウザではDMMにサインインしていません。サインインしてから、リストをもう一度開いてください。 |
| 何もかも **hidden** になっていて、リストが空に見える | 非表示の行はすでにライブラリにあるか、お使いのサービスにないものです。**Show All** を押してください。 |
| **This hash list is still being published; refresh in a minute or two.** | このリストは公開されたばかりです。1〜2分待ってから再読み込みしてください。 |
| **0 files** で行が表示されない | そのリストは空です。**Next hash list** か **Random hash list** を押してください。 |
| **Everything already downloaded** | 表示されているリリースはすべて、ライブラリにすでにあります。 |
| **Torrent not instant in TorBox; skipped.** または **Torrent not instant in AD; skipped.** | お使いのサービスではそのトレントがキャッシュされていないため、DMMはダウンロードを開始せずにスキップしました。 |
| **Skipping 3 items with no info hash — they cannot be shared.** | それらの行（たとえばTorBoxのWebダウンロード）には共有できるハッシュがありません。リストの残りは共有されます。 |
| **Failed to generate hash list; try again soon.** | リストの公開に失敗しました。しばらくしてからもう一度お試しください。 |

困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP) の **dmm-support** フォーラムで聞いてみてください。

## よくある質問 {#questions}

### 自分のライブラリにハッシュリストを追加するには？ {#how-do-i-add-hash-lists-to-my-own-library}

リストを開き、DMM にデブリッドサービスでサインインしてから、行ごとにサービスのボタンを押すか、表示されているすべてのものに対して **RD Download**（またはサービスの **Download**）を押します。詳しくは [Add a list to your library](#add-a-list-to-your-library) を参照してください。

### ハッシュリストのアイテムがすべて非表示になるのはなぜ？ {#why-are-all-the-items-in-my-hash-list-hidden}

DMMは、ライブラリにすでにあるものや、サービスにキャッシュされていないものを隠します。**hidden**の箱には、その数が表示されます。**Show All**を押すと、残りが表示されます。

### ハッシュリストにTV番組が表示されないのはなぜ？ {#why-dont-tv-shows-show-up-in-a-hash-list}

**TV Shows**を上のリストで押してください。**0 TV Shows**と表示されている場合、そのリストにはドラマがないということです。共有リストのほとんどは映画です。サービスにないドラマは非表示になっているので、**Show All**を試してください。

### ハッシュリストの追加がこんなに遅いのはなぜ？ {#why-is-adding-a-hash-list-so-slow}

Real-Debridでは、DMMはリリースを1分に1件ずつ追加するので、Real-Debridによってアカウントが一時停止されることはありません。他のサービスではもっと速く追加されます。

### ハッシュリストを検索できるAPIはありますか？ {#is-there-an-api-to-query-the-hash-lists}

検索用のAPIはありません。共有リストはすべて、GitHub上の公開 [hashlistsリポジトリ](https://github.com/debridmediamanager/hashlists) 内のファイルです。各ページは、`#`の後のリンクにリストを詰め込んで DMM を指しています（名前、ハッシュ、サイズを lz-string で圧縮した JSON）。非常に大きなリストの場合は、代わりに `lists/<id>.txt` として隣に置かれています。

### リストを共有すると、自分のアカウントも共有されますか？ {#does-sharing-a-list-share-my-account}

いいえ。リストにはリリース名、ハッシュ、サイズしか含まれていません。
