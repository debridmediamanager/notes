# Usenetのはじめの一歩：何を買うか、zurgとどう組み合わせるか {#usenet-for-beginners-what-to-buy-and-how-it-fits-with-zurg}

zurgでUsenetをストリーミングするには、ファイルを保存している**Usenetプロバイダー**のアカウントと、各リリースの場所を示す**NZBファイル**が必要です。**インデクサー**はNZBを検索するサイトですが、購入する必要はありません。DMMの**Usenet**タブなら、どの映画や番組のNZBでも見つけられます。その後、zurgは何もダウンロードせずに、プロバイダーから直接リリースを再生します。

## 3つの構成要素 {#the-three-pieces}

| 部品 | それが何か | 料金は必要? |
|---|---|---|
| プロバイダー、またはニュースサーバー | 投稿を保存しているサービスです。サーバーアドレス、ユーザー名、パスワード、接続数の情報が届きます。zurg はここから読み込みます。 | はい。唯一、買う必要があるものです。 |
| NZB | 1つのリリースの断片一覧が書かれた小さなファイルです。torrent の `.torrent` ファイルに似ています。 | いいえ。 |
| インデクサー | NZB を作る検索サイトです。Sonarr、Radarr、Prowlarr がここを検索します。 | 任意です。 |

Usenet 上のリリースは、何千もの小さな断片として投稿されています。NZB がその断片を一覧にし、プロバイダーがそれを提供し、zurg が断片をつなぎ合わせて、プレーヤーが求める動画に戻します。

## 必要なもの {#what-you-need}

1. **zurg のスポンサーシップ。** Usenet は zurg の夜間ビルドに入っていて、これは [スポンサーシップ](sponsorship.md) が必要です。無料で公開されている zurg は Real-Debrid のみ対応です。
2. **Usenet プロバイダーのアカウントを 1 つ。** プランを比べるときは次の 2 つの数字が大事です。
   - **保持期間**: サーバーが投稿を何日分残しておくか。古い映画やドラマほど長い期間が必要です。
   - **同時接続数**: プランで同時に使える接続の数。zurg はこの数で読み込むので、設定ファイルにはプランの実際の数字を入れてください。
3. **NZB。** DMM の Usenet タブから保存するか、自分のインデクサーから取得するか、Sonarr、Radarr、zurg に探してもらいます。

次のものは必要ありません:

- **SABnzbd や NZBGet のようなダウンロードクライアント。** zurg がリリースをストリーミングします。Sonarr と Radarr では、zurg が SABnzbd の代わりを務めます。詳しくは [Sonarr と Radarr で Usenet を使う](../zurg/guides/sonarr-radarr.md) を見てください。
- **リリース全体を入れるディスク。** zurg は再生中の部分を cover する分だけ取得します。60 GB のリミックス映像でも 60 GB のディスクは要りません。
- **展開や修復のツール。** zurg は RAR セットの中から直接再生し、足りない部分はリリースの PAR2 ファイルから自分で復元します。
- **デブリッドのアカウント。** Usenet だけでも使えますし、同じ zurg のライブラリで Real-Debrid や TorBox と並べて使うこともできます。
- **インデクサーの会員登録。** 少なくとも最初は不要です。下の [インデクサーの話](#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers) を見てください。

後から追加するとよいもの: **2 つ目のプロバイダー。** あるプロバイダーで失われた投稿が、別のプロバイダーにはまだ残っていることがよくあります。1 つのプロバイダーが部品を持っていないとき、zurg は次のプロバイダーに問い合わせます。プロバイダーが 1 つしかないと、zurg はその部品を復元するためにリリース全体を読まなければなりません。詳しくは [2 つ目のニュースサーバーの価値](../zurg/providers/usenet.md#a-second-news-server-is-worth-more-than-it-looks) を見てください。

## zurgの仕組み {#how-zurg-plays-it}

1. NZB が zurg の `nzbs/` フォルダに置かれます。これはあなたが置くこともあれば、Sonarr、Radarr、または zurg 自身が置くこともあります。
2. 1〜2秒以内に zurg がそれを読み込み、NZB にちなんだ名前でライブラリにリリースを表示します。
3. Plex、Jellyfin、または rex で再生を押します。zurg はその位置に該当する部分をプロバイダーから取得して渡します。途中へ飛ばすと、そこから取得し直します。

ダウンロードが終わるのを待つ必要はありません。手順を追って設定するには、[Usenet と zurg](../zurg/guides/usenet.md) に従ってください。プロバイダーの設定と Docker の詳細は [Usenet provider](../zurg/providers/usenet.md) にあります。

## DMMの役割 {#where-dmm-fits}

[DMM](https://debridmediamanager.com) の映画・番組ページには、**Torrents** の隣に **Usenet** タブがあります。このタブには、DMM のインデクサーから取得したそのタイトルの Usenet リリースが一覧表示されます。DMM にサインインしていれば誰でも使えます。

![サインイン済み（TorBox Pro）の DMM の Night of the Living Dead (1968) の Usenet タブ](../assets/usenet-for-beginners/01-dmm-usenet-tab.webp)

各行でできることは、サインインしているサービスによって変わります。

| ボタン | 機能 | 必要なもの |
|---|---|---|
| 末尾のファイルアイコン、またはボタンがこれだけの場合の **NZB** | リリース名を付けた NZB を保存します。インデクサーの透かしは取り除かれます。保存したファイルは zurg の `nzbs/` フォルダーに入れてください。 | DMM へのサインイン |
| **Send** | DMM が Usenet からリリースを取得し、Real-Debrid のライブラリに追加します。この操作に Usenet アカウントは不要です。 | Real-Debrid |
| **TorBox** | NZB を TorBox に送信し、TorBox がリリースをダウンロードします。 | TorBox Pro。詳しくは [DMM での TorBox](../dmm/torbox.md) を参照 |

スポンサーの方は、さらに次の 2 つが使えます。

- **zurg が DMM のインデクサーを代わりに検索します。** zurg の設定ファイルに DMM の API キーを `dmm_api_key` として書き、自分のインデクサーを設定しない場合、zurg は [DMM のウィッシュリスト](../zurg/guides/dmm-wanted.md)や[ウォッチリスト](../zurg/guides/acquisition.md)を取得するときに DMM のインデクサーを検索します。
- **Sonarr、Radarr、Prowlarr 向けの Newznab インデクサーとしての DMM。** DMM の [Newznab ページ](https://debridmediamanager.com/newznab)で設定できます。キーごとに、1 分あたり 30 回の検索と 15 回の取得、1 日あたり 250 回の取得が可能です。

## 問題が起きたとき {#when-something-is-wrong}

| 見えるもの | やること |
|---|---|
| zurgのログ: `Cannot reach the news server for nzb` | zurgがプロバイダにサインインできていません。サーバーアドレス、ユーザー名、パスワードを確認してください。ポート`563`には`tls: true`、ポート`119`には`tls: false`を組み合わせます。 |
| zurgのログ: `Usenet account <name> is not reachable` | 複数のアカウントのうち1つが失敗していますが、ほかのアカウントは動いています。そのアカウントの設定を直してください。 |
| プロバイダが接続を拒否する。例: `502 Too many connections` | zurgの設定の`connections`がプランの上限を超えているか、同じログインを別のアプリも使っています。プランの数値まで下げてください。 |
| リリースが`indexer_download_48213`などの名前で表示される | zurgはリリースをNZBファイルの名前で表示します。`.nzb`の名前をリリース名に変えてください。 |
| リリース内のファイル名がランダムな文字列になっている | 投稿者がファイル名を隠しており、zurgが元の名前を取得できませんでした。別のリリースを選んでください。 |
| zurgのログ: `rar: RAR4 header-encrypted archives are not supported` | そのリリースのアーカイブは、zurgが開けない古い形式で暗号化されています。別のリリースを選んでください。 |
| 再生がカクついたり、一部が無音になる | リリースの一部のデータがプロバイダから消えています。投稿にPAR2ファイルがあれば、zurgがそこから欠けた部分を復元します。プロバイダを2つ目に追加すると、ほとんどの場合これで直ります。 |
| DMM: **No Usenet results found.** | DMMのインデクサーにこのタイトルの結果がありません。**Torrents**タブを試すか、自分のインデクサーを使ってください。 |

トラブルシューティングの表全体は[Usenet と zurg](../zurg/guides/usenet.md#troubleshooting)にあります。それでも解決しない場合は、[Discord](https://discord.com/invite/7u4YjMThXP)の**zurg-support**フォーラムで聞いてください。何を伝えればよいかは[ヘルプの入手方法](remote-help.md)に書いてあります。

## よくある質問 {#questions}

### Usenetのシステムを説明してもらえますか？ {#can-someone-explain-the-usenet-system-to-me}

Usenetは、投稿を保存するニュースサーバーのネットワークです。1つのリリースは、数千の小さな断片として投稿されます。プロバイダーはそのサーバーへのアクセスを販売しています。NZBは1つのリリースの断片を一覧にしたファイルで、インデクサーはNZBを検索する場所です。zurgはNZBを受け取り、プロバイダーから直接リリースを再生します。

### Usenetのインデクサーは買い切り（ライフタイム）会員である必要がありますか？ {#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers}

いいえ、始めるのにインデクサーは不要です。DMMのUsenetタブがNZBを探してくれますし、スポンサーのzurgならDMMのインデクサーを自分で検索できます。より多くの結果が欲しい場合は、どのプランを選んでも、Newznab対応のインデクサーならzurg、Sonarr、Radarrで使えます。

### Usenetのファイル名はどう付ければいいですか？ {#how-are-the-files-supposed-to-be-named-for-usenet}

NZB のファイル名は、リリース名にしてください（例: `Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb`）。zurg はこの名前をリリースのフォルダ名として使い、Plex などもこの名前でマッチングします。NZB の中に名前が入っている場合は、そちらが優先されます。DMM の NZB ボタンは、リリース名でファイルを保存するので、そのままで問題ありません。

### zurgはUsenetに対応していますか？ {#does-zurg-do-usenet}

はい、スポンサー向けのナイトリービルドで使えます。プロバイダーの情報を設定して、NZB を `nzbs/` に入れれば再生できます。手順は [zurg で Usenet を使う](../zurg/guides/usenet.md) にまとめてあります。

### TorBox NNTPとは何ですか？ {#what-is-torbox-nntp}

**TorBox の Pro プラン**には Usenet の機能が 2 つあります。料金ページでも Usenet は Pro プランだけに記載されています(2026年11月14日に確認)。

- **Hosted Usenet downloads(TorBox でのホスト型 Usenet ダウンロード)。** TorBox がリリース全体をダウンロードしてくれて、ほかの TorBox のダウンロードと同じように配信します。NZB は DMM の Usenet タブか、zurg の `torbox_nzb` プロバイダーから送ってください。ニュースサーバーへのログインは不要です。詳しくは [TorBox でホストされている Usenet](../zurg/providers/torbox-nzb.md) を見てください。
- **ニュースサーバーのログイン(NNTP)。** zurg ではほかのプロバイダーと同じように使えます。接続数は 10 本までです。2026年9月の計測では、有料の他社プロバイダー 3 社と比べてライブラリの実際の見つかり方が少なかったので、予備として使うのがおすすめです。詳しくは [TorBox ニュースサーバー](../zurg/providers/torbox-news-server.md) を見てください。

### 1つのUsenetアカウントを2か所で使えますか？ {#can-i-use-one-usenet-account-in-two-places}

やめておいたほうがいいです。同じログインで2つのアプリが接続を共有すると、互いを押し出し合ってしまいます。サーバーは新しい接続を受け入れるために古い接続を切ることがあります。プロバイダーによっては、アカウントの共有を規約で禁止しているところもあります。zurgごとに別々のアカウントを用意してください。
