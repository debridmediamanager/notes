# DMMとは何か、そして使い方は? {#what-is-dmm-and-how-do-i-use-it}

[Debrid Media Manager](https://debridmediamanager.com)（DMM）は、映画や番組を探して、デビッドアカウントに追加できる無料のウェブサイトです。対応サービスは Real-Debrid、AllDebrid、TorBox、Premiumize、Offcloud、Debrid-Link です。そのアカウントでサインインし、タイトルを検索して、リリースの **Instant RD**（またはご利用サービスのボタン）を押します。するとすぐにライブラリに入り、DMM、Stremio、Kodi で見られるほか、[zurg](../zurg/index.md) を通じて Plex でも再生できます。

DMM はオープンソースで、Real-Debrid やその他のサービスの一部ではありません。ファイルはご利用のデビッドサービスに残ります。

## サインイン {#sign-in}

1. [debridmediamanager.com](https://debridmediamanager.com) を開き、使っているサービスのボタンを押します: **Login with Real Debrid**、**Login with AllDebrid**、**Login with Torbox**、**Login with Premiumize**、**Login with Offcloud**、**Login with Debrid-Link** のいずれか。
2. Real-Debrid の場合は **Sign in with Real-Debrid** を押します。DMM にコードが表示されるので、**Open real-debrid.com/device** を押して、そこにコードを入力し承認してください。DMM のページは自動で完了します。また、[API token](../guides/real-debrid-api-token.md) を **or paste an API key** の下に貼り付けて **Save API Key** を押すこともできます。
3. その他のサービスは、それぞれのログインページの手順に従ってください。API key を求められたら、そのサービスのアカウントからコピーして貼り付け、**Save API Key** を押します。

![DMM のサインインページ](../assets/dmm-index/01-sign-in.webp)

別のサービスも使いたい場合は? DMM のホームページで **Debrid services** を開き、そのサービスの **Login** ボタンを押します。たとえば **AllDebrid Login** です。

Easynews しか持っていない場合は **Login with Easynews** を押してください。Easynews を検索して Stremio に送ることはできますが、ライブラリには debrid アカウントが必要です。スポンサーは **Login with DMM key** でサインインすることもできます。

## 映画や番組を検索する {#search-a-movie-or-show}

1. ホームページの **Search movies & shows...** にタイトルを入力します。候補から選ぶか、**Search** を押すと全件の一覧が表示されます。
2. ポスターを押します。タイトルのページに、DMM が見つけたリリースが一覧表示されます。
3. 結果の上にあるサービスのチップ（**RD**、**PM** など）を押すと、そのサービスにすでにあるリリースだけが表示されます。

![DMM's home page after signing in](../assets/dmm-index/02-home.webp)

## リリースのボタンの意味 {#what-the-buttons-on-a-release-mean}

![DMMでのSintelのリリース一覧、Premiumizeでサインイン中](../assets/dmm-index/03-results.webp)

| ボタン | 動作 |
|---|---|
| **Instant RD** (**Instant TB**, **Instant AD**, **Instant PM**, **Instant OC**, **Instant DL**) | サービスにすでにこのリリースがあります。押すとすぐにライブラリに入ります。 |
| **DL with RD** (**DL with TB** など。Debrid-Link では **Add to DL**) | サービスにはまだありません。押すとそれでも追加され、サービスがまず先にダウンロードします。今すぐ見たいなら **Instant** のものを選んでください。[こうなる理由](../guides/torrent-being-downloaded-to-debrid.md) |
| **RD (100%)** (**PM (100%)** など) | ライブラリに入っています。数字はダウンロードの進み具合です。押すとライブラリから削除されます。 |
| **Check RD** (**Check AD**, **Check DL**) | そのサービスに、このリリースが今キャッシュされているかを問い合わせます。 |
| **Cast (RD)** (**Cast (PM)** など) | リリースを Stremio に送ります。[StremioでのDMM](stremio.md)を参照してください。 |
| **Watch** | **Ready to play** タブを開きます。**Play** を押すとプレーヤーが開きます。プレーヤーは **Settings** → **Video player** で選べます。 |
| **Copy** | リリースのマグネットリンクをコピーし、**Magnet link copied.** と表示します。**Settings** で **Download .magnet files instead of copy** にチェックを入れていると、ボタンは **Download** と表示され、.magnet ファイルを保存します。 |
| **Report** | 悪いリリースを報告します。選択肢は **XXX / Porn Content**、**Incorrect IMDB ID**、**Malware / Executable File**、そしてシリーズでは **Tagged for Wrong Season** です。 |

**Torrents** の隣にある **Usenet** タブには、同じタイトルの Usenet リリースが一覧表示されます。**NZB** はそのうち1つをダウンロードします。ライブラリに送るには Real-Debrid か TorBox が必要です。Easynews をお使いですか？ **Settings** で追加すると、ここでも検索されます。

## あなたのライブラリ {#your-library}

ホームページで **Library** を押します。サインインしたアカウントにあるすべての項目が一覧で表示されます。名前、サイズ、ステータス、追加日時です。

![ライブラリの検索ボックスとボタン](../assets/dmm-index/04-library.webp)

- **search by filename/hash/id, supports regex** で検索するか、**Movies**、**TV shows**、**Others** で絞り込みます。
- 行を押すと詳細と、**Hashlist**、**Delete**、**Cast**、**Copy** ボタンが表示されます。各行の末尾にあるアイコンも同じ働きをします。
- **Backup** で一覧を `.dmm.json` ファイルに保存します。**RD Restore**（**PM Restore** など）で保存したリストを戻せます。
- **Share List** は、表示されているもの、または選択したものを、他の人が自分のアカウントに追加できる[ハッシュリスト](hashlists.md)にします。
- **Delete List** は、表示されているものすべてを **Yes, delete!** の確認後に削除します。先に検索するか選択してください。

## 次に読むページ {#where-to-go-next}

- [Stremio での DMM](stremio.md): DMM Cast アドオンを使って、Stremio で見つけた作品をそのまま視聴します。
- [ハッシュリスト](hashlists.md): 共有ライブラリ全体を自分のライブラリに追加したり、自分のライブラリを共有したりできます。
- [DMM での TorBox](torbox.md): TorBox の各プランが DMM でどんな機能を持つか、そして Usenet のリリースを TorBox Pro に送る方法を説明します。
- [「Torrent is being downloaded to debrid」](../guides/torrent-being-downloaded-to-debrid.md): Stremio に出るその画面の意味と、DMM がキャッシュ済みかどうかをどう表示するかを説明します。
- [Safari での DMM ボタン](safari.md): ブラウザ拡張機能を入れると、IMDb や Trakt などの映画・ドラマサイトに DMM ボタンが追加されます。

DMM は他のプロジェクトにも情報を提供しています:

- **zurg** は、各ファイルがどの映画やエピソードかを DMM に問い合わせます。スポンサーは [gatekeeper](https://gatekeeper.debridmediamanager.com/) で DMM API キーを取得できます。キーがないと zurg はファイル名だけに頼るため、一致する作品が減ります。違いについては [zurg と組み合わせた rex](../rex/with-zurg.md#why-dmm-places-the-files) で説明しています。
- **Sonarr Radarr and Prowlarr** は、DMM を Torznab のトレントインデクサー、または Newznab の Usenet インデクサーとして検索できます。どちらもスポンサーシップが有効で、DMM API キーが必要です。設定方法は [Torznab](https://debridmediamanager.com/torznab) と [Newznab](https://debridmediamanager.com/newznab) のページにあります。
- **Your wanted list**: **Want** を押すか、Trakt、MDBList、TMDB のリストをフォローします。zurg がそのリストを取得し、新しいエピソードが放送されるたびに追加します。スポンサーシップが必要です。詳しくは [DMM の wanted list](../zurg/guides/dmm-wanted.md) を参照してください。
- **Seerr Overseerr and Jellyseerr** は、DMM を Radarr や Sonarr の代わりに使えます。その場合、リクエストは wanted list に入り、zurg が取得します。スポンサーシップが必要です。詳しくは [DMM 経由の Seerr](seerr.md) を参照してください。
- **rex-direct** は、認証済みの rex に専用のアドレスと証明書を与えます。詳しくは [rex-direct](../rex/any-source.md#rex-direct) を参照してください。

スポンサーシップで利用できる機能と、それぞれの設定場所については [スポンサーシップで得られるもの](../guides/sponsorship.md) にまとめています。

## 問題が起きたとき {#when-something-is-wrong}

| 見えるもの | 対処法 |
|---|---|
| **Real-Debrid rejected that API key.** | 貼り付けたトークンは有効なものではありません。[real-debrid.com/apitoken](https://real-debrid.com/apitoken) からもう一度コピーするか、代わりに **Sign in with Real-Debrid** を押してください。詳しくは [Your Real-Debrid API token](../guides/real-debrid-api-token.md) を参照してください。 |
| **That code expired before it was approved. Try again.** | Real-Debrid のコードがタイムアウトしました。**Sign in with Real-Debrid** をもう一度押し、新しいコードをもっと早めに承認してください。 |
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | TorBox の無料プランでは DMM を使えません。有料プランにアップグレードするか、別のサービスでサインインしてください。 |
| Only **DL with RD** buttons, no **Instant RD** | お使いのサービスにはこれらのリリースがキャッシュされていません。**DL with RD** を押してダウンロードが終わるのを待つか、別のリリースを試してください。 |

困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP) の **dmm-support** フォーラムで質問してください。何を伝えればよいかは [ヘルプの入手方法](../guides/remote-help.md) に書かれています。

## よくある質問 {#questions}

### DMMって結局なに? {#what-actually-is-dmm}

DMMはあなたのデバッドアカウント向けの検索サイトです。映画や番組のリリースを探し、どれがすでにあなたのサービスにあるかを教えてくれます。選んだものはアカウントに追加されます。DMM自体はファイルを一切保存しません。

### 使い方は? {#how-do-i-use-it}

サインインしたら、デブリッドサービスで作品を検索し、開いたうえでリリースの **Instant RD**（またはご利用のサービスの **Instant** ボタン）を押してください。そのあとは **Watch** を押すか、Stremio にキャストするか、zurg に Plex へ入れてもらいます。

### DMMはReal-Debridが作っているの? {#is-dmm-made-by-real-debrid}

DMMはオープンソースのプロジェクトで、Real-Debridを含む6つのサービスに対応しています。検索では「Real-Debrid Media Manager」という名前で探す人も多いです。

### 無料ですか? {#is-it-free}

はい。独自のデブリッドアカウントが必要で、これは有料サービスです。DMMのスポンサーシップに加入すると、ウォントリストやインデクサーなどの追加機能が使えます: [スポンサーシップで得られるもの](../guides/sponsorship.md)。

### どのサービスが使えますか? {#which-services-work}

Real-Debrid、AllDebrid、TorBox（有料プラン）、Premiumize、Offcloud、Debrid-Link。Easynews は検索とキャスト用に使えますが、ライブラリ用には使えません。
