# ElfHosted ニュースサーバー {#elfhosted-news-server}

ElfHostedは、Stremioアドオンのプランに Usenet アカウントを同梱しており、それを Usenet Essential と呼んでいます。このページでは、そのサーバーが何であるかを記録します。以下の内容はすべて2026-09-04に1台のホストから計測したものです。アカウント自体は計測できませんでした。ElfHostedが公開した唯一の認証情報は無効になっており、これが最初の発見です。

## ワイヤー上で応答する内容 {#what-answers-on-the-wire}

`news.elfhosted.com` は `94.232.116.124` に解決され、563 番ポートで TLS 1.3 を使った NNTP に応答します。証明書は Let's Encrypt のもので、`news.elfhosted.com` という名前だけが入っています。発行日は 2026-08-17 です。
同じサーバーは 119 番の平文でも同じ挨拶を返します。挨拶は `200 Welcome to elfhosted` です。

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
AUTHINFO USER
```

これは [TorBox リーダー](torbox-news-server.md) が報告するのと同じ `nntpswitch2` 文字列です。この一覧は認証なしのものなので、`POST` ではなく `AUTHINFO USER` で終わっています。`HELP` は認証情報がなくても応答し、`POST`、`IHAVE`、`XPAT`、`XGTITLE` を含む全コマンドを挙げます。つまり `POST` が見当たらないのはサーバーの問題ではなく、今のセッションの状態によるものです。

認証前に使えるのは次の 3 つだけで、ほかは何も使えません。

| コマンド | 応答 |
|---|---|
| `DATE` | `111 20260903225242` |
| `HELP` | `100 Help follows.` |
| `CAPABILITIES` | `101 Capabilities.` |
| `MODE READER` | `480 Authentication required for command.` |
| `GROUP` と `LIST`、`STAT`、`POST` | `480 Authentication required for command.` |

## 運営者 {#who-runs-it}

TorBoxのページでは隣接関係から運営者を推定しましたが、こちらは推定に頼りません。`news.elfhosted.com`はAbaviaのリーダーブロックそのものの中にあります。

`94.232.116.124`は`94.232.112.0/21`にあり、`AS48345 AS-ABAVIA`に属し、サンマリノのAbavia S.r.l.に登録されています。`94.232.116.0/24`を逆引きで走査すると79件の名前が返ってきます。そのうち45件がポート563でNNTPに応答し、45件すべてが`nntpswitch2 (local-dev)`と報告し、バイト単位で同一のcapabilityリストを同じ順序で返します。Abavia自身のボーダールーターも同じ/24にあり、XS Newsのフィーダー、ウェブホスト、ネームサーバーも同じ/24にあります。

| アドレス | リーダー | グリーティング |
|---|---|---|
| `94.232.116.122` | `reader2.newsxs.nl` | `200 Welcome to Newsxs` |
| `94.232.116.124` | `news.elfhosted.com` | `200 Welcome to elfhosted` |
| `94.232.116.125` | `reader.spotnews.nl` | `200 Welcome to Spotnews` |
| `94.232.116.128` | `reader.easyusenet.nl` | `200 Welcome to Easyusenet` |
| `94.232.116.131` | `reader.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.135` | `reader-usenetfarm.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.136` | `reader.torrentclaw.com` | `200 Welcome to TorrentClaw` |
| `94.232.116.140` | `reader.usenet.nl` | `200 Usenet.nl S.r.l.` |
| `94.232.116.147` | `giganews.hostredirects.com` | `200 Welcome to giganews` |
| `94.232.116.150` | `news.usenext.de` | `200 Welcome to Aviteo Ltd DE` |
| `94.232.116.174` | `news.hitnews.com` | `200 Welcome to Hitnews` |

ElfHostedは、Easyusenetのアドレスから4つ、XS Newsから7つ、TorrentClawから12つ離れています。TorrentClawは、同じプラットフォームの前に立つ別のStremioアドオンです。

名前ベースの多重化はありません。`reader.xsnews.nl`というservername、または存在しないservernameで接続しても、同じ証明書と同じ`200 Welcome to elfhosted`のグリーティングが返ってきます。ブランドごとにアドレスが1つずつあります。

TorBoxはこのブロックにはありません。TorBoxはオランダの`AS3257 GTT`にある`78.152.55.171`で動いています。したがって、ElfHostedの帰属の方が2つのうちで確かな方です。TorBoxは同じソフトウェアを、このファミリーのブランドの隣で動かしています。ElfHostedは同じソフトウェアを、Abavia自身のアドレス空間で動かしています。

**測定**されたのは、ソフトウェアのフィンガープリント、アドレスの所有者、証明書、そして名前ベースの多重化がないことです。**推定**なのは、その背後のスプールがElfHostedが組み立てた寄せ集めではなく、Abavia自身のものだということです。認証情報がなければ、ワイヤー上ではこの2つを区別できません。

(以前の翻訳は却下されました: コードスパンが一致していません。構造をそのまま保ってください。)

## 公開されている認証情報は無効です {#the-published-credential-is-dead}

2025-12-20、ElfHosted は NzbDav に同梱する NNTP アクセスを、2か月間の概念実証（proof of concept）として発表しました。提携先は名前の明かされていない Usenet インフラ事業者で、発表では共有の認証情報を 1 つ公開していました。

| 項目 | 公開時の内容（2025-12-20） |
|---|---|
| Host | `news.elfhosted.com` |
| Port | 563 SSL |
| Username | `elfie` |
| Password | `elfie` |
| Connections | 100 |
| Cost | 2026年2月まで無料 |

新規ユーザー向けに NzbDav であらかじめ設定されていました。投稿では、概念実証が終わったあとに取り決めを見直すとされていました。実際に終わりました。この認証情報はもう認証できません。

```
200 Welcome to elfhosted
381 Need more.
482 Invalid username or password
```

このソフトウェアでは `482 Invalid username or password` が本当に「無効」という意味の応答で、接続数の上限ではありません。接続数の上限は `482 too many connections for your user` と表示されます。タイミングもそれを裏付けています。存在しなかったユーザー名での 5 回の接続と、`elfie` での 2 回の接続は、同じ応答を同じ時間帯に返されています。

| 接続テスト | 応答 | 所要時間 |
|---|---|---|
| ランダムなユーザー名、5 回の接続 | `482 Invalid username or password` | 中央値 2066 ms、範囲 2043 から 2070 ms |
| `elfie` と `elfie`、2 回の接続 | `482 Invalid username or password` | 2043 ms と 2212 ms |

無効になった認証情報と、一度も発行されたことのないユーザー名は、ここでは区別できません。コードでも、応答時間でも同じです。このソフトウェアが「ダメ」と答えるまでに約2秒かかるのですが、これは TorBox のリーダーでも同じです。

つまり 100 接続という数字は、終了した提供内容のものです。ElfHosted がこのサーバーについて公開した唯一の数字ですが、今日購入できるものには当てはまりません。有料の Usenet Essential では、顧客ごとに認証情報が発行されていると思われますが、外部からは確認できません。

同じ発表では、`elfhosted-internal.zyclops` に内部向けの Newznab エンドポイントも公開されていました。このエンドポイントは任意の API キーを受け付け、特定のバックボーンで正常に動作している結果だけに絞り込めます。ElfHosted のストアで Usenet プランにインデクサーが含まれると言っているのは、このエンドポイントのことです。コンテンツではなく、可用性と健全性の情報を示すものです。彼ら自身の言葉を借りると、インフラの健全性を映す水晶玉であって、宝の地図ではありません。ただし、プランには別途、実際のインデクサーも必要です。

## 測定できなかったこと {#what-could-not-be-measured}

プロバイダーの接続枠を使う価値があるかを決めるすべての項目です。どれも認証情報が必要です。

| Property | State |
|---|---|
| Connection cap | 不明。100 は廃止された概念実証（PoC）にのみ適用されていました |
| Retention | 公開されていない |
| Groups in `LIST ACTIVE` | 認証が必要 |
| Article number window | 認証が必要 |
| Coverage against other backbones | 認証が必要 |
| Single connection throughput | 認証が必要 |
| Posting | サーバーは `POST` を提供しているが、アカウントの状態は不明 |

7日間のトライアルは1ドルで、認証情報が手に入ります。その1週間内に、[TorBox page](torbox-news-server.md#what-it-actually-holds) で使ったのと同じ 531 件のメッセージID検査を実行すれば、上の表のすべての項目がわかります。

## プラットフォームが既に教えてくれること {#what-the-platform-already-tells-you}

TorBox での計測から、二つの事実はそのまま引き継げて、一つは引き継げません。

引き継げるもの: 拒否の仕組みと拒否のタイミングです。同じソフトウェアなので、返ってくる答えも同じです。つまり、ここでも `482 Invalid username or password` は無効な認証情報を意味します。上限(cap)の場合は別の文字列になります。

引き継げるもの: 記事番号の範囲です。`nntpswitch2` のリーダーは短い範囲だけで記事番号を生成するため、メッセージIDではなく番号をたどる処理には、二週間分の Usenet しか見えません。これはアカウント単体ではなくプラットフォームの性質です。NZB による読み取りは記事をメッセージIDで指定するので、影響を受けません。

引き継げないもの: カバレッジです。TorBox のリーダーは、Omicron アカウントの厳密な部分集合で、71.2 パーセントの範囲をカバーしており、531 件のうち独自の記事は0件でした。これは TorBox のエンドポイントでの結果で、こちらのエンドポイントのものではありません。しかも TorBox はこのブロックには含まれていません。同じソフトウェアと同じ運営者に関する最も近い事前予測ではありますが、ElfHosted の計測結果ではありません。答えではなく、検証すべき仮説として扱ってください。

## zurg での設定 {#configuring-it-in-zurg}

認証情報を取得できたら、主要サーバーと並べて追加する、通常の `type: nzb` のサーバーエントリになります。

```yaml
providers:
  - type: nzb
    nntp:
      host: your-primary.example.com
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 40
      backbone: primary-backbone
      servers:
        - name: elfhosted-news
          host: news.elfhosted.com
          port: 563
          tls: true
          username: YOUR_ELFHOSTED_USERNAME
          password: YOUR_ELFHOSTED_PASSWORD
          connections: 8
          backbone: abavia
          backup: true
```

接続数は 8 から始めて、実際の上限を測ってから増やしてください。公表されている 100 はもう使われておらず、上限が分からないまま接続プールを開くと、コールドスタート時に自分で接続を拒否されてしまいます。ブランド名ではなく `backbone: abavia` と設定してください。XS News、Easyusenet、Hitnews、UseNeXT、そしてこのサービスは同じプラットフォームなので、別々のバックボーンとして扱うと、プールが 1 つのスプールを複数として数えてしまいます。`backup: true` にすると、すべての主要サーバーに拒否された記事のためだけに使われます。

同じ認証情報を 2 つ目のクライアントで使わないでください。サーバーは新しい方ではなく古い方の接続を切るため、2 つ目のクライアントを追加すると最初のクライアントが犠牲になります。

## スロットを使う価値はあるか {#is-it-worth-a-slot}

これ単体では買えません。月額9ドルの Stremio アドオンプランに含まれていて、そのプランにはホスト型アドオン、NzbDav インスタンス、TorBox Essentials アカウントも付いてきます。その中の一項目として見れば追加費用はかかりません。認証情報がなくても言える一番のメリットはそこです。

すでに Omicron アカウントと Eweka、Frugal を使っている環境に、このプラットフォームを4つ目の読み取り元として足すのは、TorBox のページで試して外れた賭けと同じです。ここではその賭けをまだ測っていないので、判定ではなく事前の見立てです。結論を出すには、1ドルと1週間、そして531 id のスイープが必要です。
