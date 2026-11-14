# TorBox での DMM {#torbox-in-dmm}

DMMはTorBoxの有料プラン（Essential、Standard、Pro）で動作します。[torbox.app/settings](https://torbox.app/settings)からAPIキーをコピーして、DMMの**Connect Torbox**ページに貼り付けてください。その後検索すると、TorBoxにすでにあるリリースには**Instant TB**が表示されます。無料プランはAPIアクセスがないため、DMMでは使えません。また、UsenetのリリースをTorBoxに送るにはProプランが必要です。

## サインイン {#sign-in}

1. [debridmediamanager.com](https://debridmediamanager.com) で **Login with Torbox** を押します。すでに別のサービスでサインインしている場合は、ホームページの **Debrid services** を開き、**Torbox Login** を押します。
2. **Get API Key from Torbox** を押します。[torbox.app/settings](https://torbox.app/settings) が開き、そこにAPIキーがあります。
3. キーを **API Key** に貼り付け、**Save API Key** を押します。

![DMM's Connect Torbox page turning down a free-plan key, key blurred](../assets/dmm-torbox/01-free-plan.webp)

サインインできたら、ホームページに **Cast for TB** と **Requests** が表示されます。**Debrid services** には、TorBoxアカウントが ✓ 付きで一覧されます。それを押すと、プランと期限を確認できます。また、**Add another account** や **Logout** もここから操作できます。

## 各プランでできること {#what-each-plan-can-do}

| | Free | Essential or Standard | Pro |
|---|---|---|---|
| DMMにサインイン | No | Yes | Yes |
| **Instant TB**、**DL with TB**、ライブラリ、**Cast (TB)** | No | Yes | Yes |
| Usenetのリリースをtorboxに送信 | No | No | Yes |
| 同時ダウンロード数（TorBoxのアクティブスロット） | 1 | 3 or 5 | 10 |

無料プランのキーでサインインすると、DMMは **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** と表示します。TorBoxの[料金ページ](https://torbox.app/pricing)では、APIアクセスは無料プランには含まれず、UsenetはProプランのみと記載されています。

## TorBox にすでにあるものを探す {#find-what-torbox-already-has}

1. 映画かシリーズを検索して開きます。
2. DMM が TorBox に、どのリリースがキャッシュ済みかを問い合わせます。キャッシュ済みのものには **Instant TB** と **Cast (TB)** が表示され、一覧の先頭に並びます。結果の上にある **TB ✓** チップを押すと、これらだけに絞り込まれます。そのとき入力欄には `is:tb` と書かれます。もう一度押すと、すべて表示に戻ります。
3. **Instant TB** を押します。そのリリースはすぐに TorBox のライブラリに入ります。

![Night of the Living Dead (1968) on DMM with TorBox: Instant TB, Cast (TB) and DL with TB](../assets/dmm-torbox/02-results.webp)

TorBox にないリリースには **DL with TB** が表示されます。これを押すと、まず TorBox がそのリリースをダウンロードします。ダウンロード中は、アクティブなスロットを 1 つ使います。サイズの横に **No seeders** と出ている場合は、今は誰も共有していないということなので、完了しない可能性があります。TorBox ではリリース全体がまとめて追加されます。個別のファイルだけを選ぶことはできません。

## あなたのライブラリ {#your-library}

**Library** を押します。TorBox のトレントとウェブダウンロードの一覧が表示されます。

- **TB Add** を押すと **Add to your TB library** が開きます。マグネットリンクを貼り付けたり、`.torrent` ファイルをアップロードしたりできます。直接ダウンロードリンクを貼り付けると、TorBox がウェブダウンロードとして取得します。
- **Backup** で一覧をファイルに保存できます。**TB Restore** を使うと、保存した一覧を元に戻せます。
- それ以外の操作は、ほかのサービスと同じです。[your library](index.md#your-library) を参照してください。

TorBox に送った Usenet のダウンロードは、DMM のライブラリには表示されません。TorBox のサイトで確認するか、Stremio の DMM Cast にある **DMM TB Library** の行で探すか、zurg の [TorBox でホストされている Usenet](../zurg/providers/torbox-nzb.md) から確認してください。

## Stremio で視聴する {#watch-in-stremio}

ホームページで**Cast for TB**を押して、そこからアドオンをインストールしてください。その後、TorBoxでキャッシュ済みの任意のリリースで**Cast (TB)**を押します。手順はすべて[Stremio で DMM を使う](stremio.md)にあります。

Stremioではアドオン名は**DMM Cast for TorBox**です。**DMM TB Library**の行には、TorBoxのトレントと、完了したWebおよびUsenetのダウンロードが表示されます。

## Usenet のリリースを TorBox に送る (Pro) {#send-usenet-releases-to-torbox-pro}

1. 映画や番組を開いて、**Usenet** タブを押します。
2. TorBox Pro の場合、リストの見出しは **Send to TorBox** になり、各リリースに **TorBox** ボタンがあります。それを押します。
3. DMM が TorBox の処理結果を表示します:
   - **Usenet → TorBox: TorBox already had it, it is ready in your TorBox Usenet downloads.**
   - **Usenet → TorBox: TorBox is downloading it, usually ready within a few minutes.**
   - **Usenet → TorBox: queued, it starts when one of your TorBox active slots frees up.**

![DMM's Usenet tab with TorBox Pro: Send to TorBox](../assets/dmm-torbox/03-usenet-tab.webp)

Real-Debrid にもサインインしていますか？その場合、リストの見出しは **Send to Real-Debrid or TorBox** になり、両方のボタンが表示されます。行の末尾にあるファイルアイコンを押すと、代わりに NZB を保存できます。Usenet が初めてなら、まず [Usenet入門](../guides/usenet-for-beginners.md) を読んでください。

TorBox は、Usenet のダウンロードをキャッシュしてから 30 日後に削除します。元に戻すには、もう一度送信してください。

## TorBox でリクエストを満たす {#fill-requests-with-torbox}

Real-Debrid のユーザーは、DMM の[リクエストボード](https://debridmediamanager.com/requests)でリリースを頼めます。ホームページで **Requests** を押し、TorBox にキャッシュ済みのリリースで **Fulfil** を押してください。TorBox 側のリリースが Real-Debrid のアカウントに送られます。10 回送るごとに DMM のスポンサー特典が 7 日分もらえます。[お金を払わずに獲得する方法](../guides/sponsorship.md#earn-it-without-paying)を参照してください。

## 問題が起きたとき {#when-something-is-wrong}

| 表示されるもの | やること |
|---|---|
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | そのキーはTorBoxの無料プランのものです。TorBoxでアップグレードまたは更新してから、もう一度サインインしてください。 |
| **Failed to refresh torbox: Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | サインインしたあとに有料プランの期限が切れています。TorBoxで更新してください。 |
| **API Error: Request failed with status code 403. Status: 403** | TorBoxがそのキーを受け付けませんでした。[torbox.app/settings](https://torbox.app/settings)から、キー全体をコピーし直してください。 |
| **Usenet**タブに**TorBox**ボタンがない | TorBoxへのUsenetリリース送信にはProが必要です。EssentialとStandardではこのボタンは表示されません。 |
| **Usenet → TorBox: TorBox Usenet needs a Pro plan** | プランがProではないため、TorBoxがそのNZBを受け付けませんでした。 |
| **DL with TB**だけが表示され、**Instant TB**がない | TorBoxにはこれらのリリースのキャッシュが一つもありません。どれかを押してダウンロードが終わるまで待つか、別のリリースを選んでください。 |
| **Instant TB**のリリースだけが表示される | **TB ✓**チップがオンになっています（フィルター欄の`is:tb`）。もう一度押すか、**Reset**を押してください。 |
| **No torrents found yet. Use Want above to have zurg fetch it once one turns up, or try the Usenet tab.** | DMMにはこのタイトルのtorrentがまだありません。新しいエピソードは時間がかかることがあります。**Usenet**タブを試すか、後でもう一度確認してください。 |
| Stremioで **⚠️ TorBox refused your account** と表示される | TorBoxはアドオンのキーを受け付けますが、アカウントの提供を拒否しています。多くの場合、プランの期限切れが原因です。[torbox.app/settings](https://torbox.app/settings)で確認してください。DMM側で変更する必要はありません。 |
| zurg: `Acquisition: dmm-torbox refused the search: No TorBox key linked.` | DMMの[Torznabページ](https://debridmediamanager.com/torznab)にあるスポンサーの`tb/cached`フィードには、そのページの**Link a provider key**でTorBoxキーをリンクする必要があります。DMMにTorBoxでサインインしているだけでは足りません。zurgの`api_key`はDMMのAPIキーのままで大丈夫です。 |

TorBox自体がダウンしていないか確認するには、[TorBoxは今ダウン中？それとも自分だけ？](https://debridmediamanager.com/is-torbox-down-or-just-me)を見てください。困ったときは、[Discord](https://discord.com/invite/7u4YjMThXP)の**dmm-support**フォーラムで聞いてください。[サポートの受け方](../guides/remote-help.md)に、何を伝えればよいかが書いてあります。

## よくある質問 {#questions}

### zurg の無料プランでは TorBox に対応していないのですか? {#is-torbox-support-not-on-the-free-tier-of-zurg}

zurgの無料の公開ビルドはReal-Debridのみ対応しています。TorBox、その他のサービス、Usenetは、スポンサー向けのzurgのnightlyビルドに含まれています。zurgは無料アカウントを読み取れないため、TorBoxのプランも有料である必要があります。設定は[zurgでのTorBoxの設定](../zurg/providers/torbox.md)を参照してください。

### zurg が間違った TorBox プランを使っている? {#zurg-uses-the-wrong-torbox-plan}

zurgのnightly版で2026年10月3日より前のものは、TorBoxのPro planをStandardとして扱い、同時ダウンロード数を10ではなく5にしてしまいます。zurgを更新してください。残りの内容は[zurgでのTorBoxの制限](../zurg/providers/torbox-limits.md)にあります。

### TB で検索結果が出てこない? {#no-search-results-with-tb}

DMMの検索は、どのサービスでサインインしていても同じです。TorBoxは、どのリリースに**Instant TB**と表示するかを決めるだけです。何も表示されない場合は、**TB ✓**チップがオフになっているか確認し、ページを再読み込みするか、一番下の**Show More Results**を押してください。放送されたばかりの新しいエピソードは、まだDMMにトレントがない場合があります。その場合は**Usenet**タブを試してください。

### TorBox と Real-Debrid は一緒に使えますか? {#can-i-use-torbox-and-real-debrid-together}

はい。両方のサービスにサインインすると、各リリースに両方のサービスのボタンが表示されます。TorBox にはキャッシュされているのに Real-Debrid にはないリリースには **TB → RD** ボタンが付き、クリックするとそのリリースを TorBox から自分の Real-Debrid に送れます。

### DMM にはどの TorBox プランが必要ですか? {#which-torbox-plan-do-i-need-for-dmm}

どの有料プランでも構いません。Usenetのリリースを TorBox に送りたい場合や、同時に10件のダウンロードをしたい場合は Pro を選んでください。
