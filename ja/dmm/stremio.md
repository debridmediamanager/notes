# DMM Cast で Stremio から DMM を使う {#use-dmm-in-stremio-with-dmm-cast}

DMM Cast は Debrid Media Manager の Stremio アドオンです。DMM を Stremio から使えるようにするためのものです。DMM でリリースを選び、**Cast** を押すと、Stremio にストリームとして表示され、自分のデブリッドまたは Easynews アカウントから再生されます。手順は簡単です。DMM にサインインし、プロバイダーの Cast ページを開き、Stremio にアドオンをインストールしてから、好きな映画やシリーズで **Cast** を押してください。

ここでの Cast は DMM アドオンのことです。Chromecast や画面ミラーリングのことではありません。

## 必要なもの {#what-you-need}

- DMM で Real-Debrid、TorBox、AllDebrid、Premiumize、Offcloud、Debrid-Link、Easynews のいずれかにサインインします。
- Stremio。[Stremio Web](https://web.stremio.com) は Stremio アカウントなしで使えます。

スポンサーは必要ありません。

## セットアップ {#set-it-up}

1. [debridmediamanager.com](https://debridmediamanager.com) でプロバイダーを使ってサインインします。Easynews は **Settings** からサインインします。
2. DMM のホーム画面で **Cast for RD**、**Cast for TB** などのボタンを押します。複数のアカウントにサインインしている場合は、プロバイダーごとのボタンが並んだ **Cast** の行が1つ表示されます。各プロバイダーには専用の Cast ページがあります:

   | Provider | Cast page |
   |---|---|
   | Real-Debrid | [debridmediamanager.com/stremio](https://debridmediamanager.com/stremio) |
   | TorBox | [debridmediamanager.com/stremio-torbox](https://debridmediamanager.com/stremio-torbox) |
   | AllDebrid | [debridmediamanager.com/stremio-alldebrid](https://debridmediamanager.com/stremio-alldebrid) |
   | Premiumize | [debridmediamanager.com/stremio-premiumize](https://debridmediamanager.com/stremio-premiumize) |
   | Offcloud | [debridmediamanager.com/stremio-offcloud](https://debridmediamanager.com/stremio-offcloud) |
   | Debrid-Link | [debridmediamanager.com/stremio-debridlink](https://debridmediamanager.com/stremio-debridlink) |
   | Easynews | [debridmediamanager.com/stremio-easynews](https://debridmediamanager.com/stremio-easynews) |

   ![Premiumize 用の DMM Cast ページ。アドオンのアドレスはぼかしてあります](../assets/dmm-stremio/01-dmm-cast-page.webp)

3. **Install (web)** を押します。Stremio Web がアドオン付きで開くので、そこで **Install** を押します。

   ![DMM Cast をインストールするか確認する Stremio Web](../assets/dmm-stremio/02-stremio-install.webp)

   別の Stremio を使う場合は、ボタンの下に表示されているアドレスをコピーして、そこに追加します。Stremio Web なら **Addons** → **Add addon** → 貼り付け → **Add** → **Install** の順に進みます。このアドレスはあなたのアカウント専用です。絶対に他人に教えないでください。
4. DMM に戻って映画かシリーズを検索し、開きます。プロバイダーにすでにあるリリースには **Cast** ボタンが表示されます: **Cast (RD)**、**Cast (TB)**、**Cast (AD)**、**Cast (PM)**、**Cast (OC)**、**Cast (DL)** のいずれかです。それを押します。DMM が **Cast started in Stremio** と表示します（シリーズの場合は **Casting succeeded.** と、キャストしたエピソード数が表示されます）。そして Stremio アプリでタイトルを開こうとします。

   ![DMM で Cast (PM) を押したところ](../assets/dmm-stremio/03-dmm-cast-button.webp)

5. Stremio でタイトルを開きます。キャストは **DMM Cast PM (Yours)** として表示されます（他のプロバイダーなら RD、TB などになります）。それを押すと再生できます。

   ![Stremio に DMM Cast PM (Yours) として表示されたキャスト](../assets/dmm-stremio/04-stremio-streams.webp)

## Stremio でほかに何ができるか {#what-else-you-get-in-stremio}

- **DMM Cast PM ✨ · Cast a file inside a torrent** は、すべての映画とエピソードに表示されます。DMM でそのタイトルが開くので、そこからリリースをキャストできます。
- 他の人のキャストや、プロバイダーがすでに持っているリリースから、さらに最大 5 本のストリームを表示できます。数は Cast ページの **Other streams limit** で設定します。スポンサーは 10 本まで増やせます。
- Stremio の Board には次の行があります。**DMM PM Movies** と **DMM PM TV Shows** には、あなたのキャストが入ります。**DMM PM Library** には、アカウント内のすべてのアイテムが入り、各アイテムをクリックするとそのファイルが開きます。Easynews には Library の行はありません。
- 行は表示したくない場合は、代わりに **Without catalogs** → **Install (web)** でアドオンをインストールしてください。ストリームは引き続き表示されます。
- Cast ページの **Manage Casted Links** には、あなたのキャストが一覧表示されます。削除したいものにチェックを入れ（または **Select All**）、**Delete Selected** を押すと、Stremio から削除されます。
- Cast ページの **Hide "Cast a file inside a torrent" option** を使うと、✨ の行が非表示になります。

Debrid-Link の場合、キャストするとそのリリースがアカウントに追加されます。Debrid-Link にまだないリリースは実際のダウンロードが始まり、その日の 50 個のトレントのうち 1 つを使います。

## 問題が起きたとき {#when-something-is-wrong}

| 表示される内容 | 対処方法 |
|---|---|
| **DMM Cast PM ✨ · Cast a file inside a torrent** (RD, TB…) だけが表示され、他のストリームがない | このタイトルはまだ Cast されていません。その行を押すと、DMM でタイトルが開きます。リリースの **Cast** を押してから、Stremio でタイトルをもう一度開いてください。 |
| **⚠️ DMM Cast · Set up DMM Cast for Premiumize again** (またはご利用のプロバイダー) だけがストリームとして表示される | Stremio のアドオンが、DMM へのサインイン情報と合わなくなっています。押すと Cast ページが開くので、サインインしてください。その後、Stremio から古いアドオンを削除し、そのページからもう一度インストールしてください。 |
| **Real-Debrid Required. You must be logged in with Real-Debrid to use the Stremio Cast feature.** (または TorBox、Easynews など) | DMM にそのプロバイダーでサインインしていないか、別のプロバイダーの Cast ページを開いています。**Login with …** を押すか、DMM のホームページにある **Cast for …** ボタンを使ってください。 |
| **No episodes in this release on Premiumize** | DMM がそのリリースのファイルをエピソードと照合できませんでした。別のリリースを Cast してください。 |
| Stremio Web の上部にある検索バーにアドオンのアドレスを貼り付けても何も起きない | あのバーは検索専用です。**Addons** → **Add addon** を使ってください。 |

困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP) の **dmm-cast-support** フォーラムで質問してください。[ヘルプを求めるには](../guides/remote-help.md)に、何を書けばよいかが載っています。

## よくある質問 {#questions}

### Stremio から DMM を検索できますか？ {#can-i-search-dmm-in-stremio}

いいえ。DMM Cast は Stremio に検索機能を追加しないので、Stremio の検索には何も表示されません。[debridmediamanager.com](https://debridmediamanager.com) で検索して **Cast** を押してください。Stremio で既に開いているタイトルからは、✨ の行を押すとその作品の DMM ページに移動できます。

### テレビ、Fire TV、スマホで使えますか？ {#does-it-work-on-my-tv-fire-tv-or-phone}

キャストはお使いのキャスト元のデバイスではなく、DMM上に保存されます。お使いのアドオンのアドレスを登録したStremioであれば、どれにでも表示されます。スマートフォンまたはパソコンからキャストしてから、視聴するどのStremioでも**(Yours)**のストリームを選んでください。

### どのプロバイダーが使えますか？ {#which-providers-work}

Real-Debrid、TorBox、AllDebrid、Premiumize、Offcloud、Debrid-Link、Easynews。それぞれに専用のCastページと専用のアドオンがあります。Stremioで使いたいアカウントごとに1つずつインストールしてください。

### Stremio に Cast だけ表示されて stream が出ないのはなぜ？ {#why-does-stremio-show-only-cast-and-no-stream}

タイトルにはまだ何もキャストされていません。✨ の行を押して、DMM でリリースをキャストしてから、もう一度 Stremio でそのタイトルを開いてください。

### Stremio でデビッドライブラリ全体を再生できますか？ {#can-i-play-my-whole-debrid-library-in-stremio}

はい。Stremio の Board にある **DMM Library** の行には、あなたのアカウントにあるすべてのアイテムが表示されます（Easynews のものは除きます）。アイテムを開くと、そのファイルが見られます。

### スポンサーになる必要はありますか？ {#do-i-need-a-sponsorship}

いいえ。DMM Cast では、スポンサーになると **Other streams limit** が 5 から 10 に上がるだけです。[gatekeeper](https://gatekeeper.debridmediamanager.com/) で DMM の API キーを取得して、DMM の **Settings** に貼り付けてください。
