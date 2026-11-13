# どの構成を使えばいいですか？ {#which-setup-should-i-use}

**[インタラクティブなアンケートで自分に合ったセットアップを見つける](https://debridmediamanager.com/choose-your-setup)**。プレーヤーのアカウントや運用方法について、いくつか質問に答えてください。おすすめのルート、必要なもの、セットアップのリンクが表示されます。ログインは不要です。

**まずは視聴したいアプリから始めましょう。** すべてのパーツが必要なわけではありません。DMM はリリースを選ぶのを手伝います。プロバイダーがファイルを提供します。zurg はそれらを共有ライブラリにまとめられます。rex は Plex アプリ向けにライブラリを見せます。ルールによっては一部のパーツを省くものもあります。

この案内図は **2026 年 11 月 10 日** に確認したサポート対象のルートを扱っています。ステップを減らせる外部の代替手段も含みます。サードパーティのアドオンやデバイスは、動作が異なる場合があります。リンク先のガイドと、そこに書かれたテスト済みの制限に従ってください。

## 今使っているものから選ぶ {#pick-by-what-you-already-use}

スマホでは、表を横にスワイプするとすべての列が見られます。

| 持っているもの・やりたいこと… | 選ぶルート | 選ぶ理由 | 必要な準備 |
|---|---|---|---|
| Stremio と debrid か Easynews のアカウントがあり、サーバーを管理したくない | **DMM Cast → Stremio**、または既存のストリームアドオン | zurg、rex、メディアサーバーを動かさず、自分のアカウント経由で視聴できる | アドオンとプロバイダーが再生可能なストリームを提供する必要があります。再生はデバイスが行います |
| Kodi と debrid、Easynews、または TorBox Pro のアカウントがある | **DMM の Kodi アドオン → 自分のアカウント** | Kodi 内で閲覧、検索、再生できます。スマホからペアリングできます。アドオンの TorBox ライブラリには、ホストされた NZB のダウンロードが含まれます | 再生は Kodi が行います。スポンサーの Wanted list でリクエストを満たすには、引き続き zurg が必要です |
| いつも使っているプレーヤーで1本の映画を見たい | **DMM Watch → 外部プレーヤー** | ライブラリ用のサーバーは不要 | 対応プレーヤーをインストールし、再生できるファイルを選びます |
| Infuse、Kodi、またはその他の WebDAV プレーヤーを使いたい | ホスト不要の **Provider WebDAV**。ホストを常時稼働できる場合は **zurg → WebDAV プレーヤー** | Plex、Jellyfin、Emby、rex を使わずにクラウドライブラリを閲覧できる | Real-Debrid、AllDebrid、Premiumize、TorBox、Debrid-Link は、それぞれ独自のフォルダ構成で独自の WebDAV を提供します。Offcloud には WebDAV がないため、zurg が必要です。zurg は視聴中に稼働しているホストが必要です |
| Plex Media Server がすでに動いている | **zurg → マウントしたフォルダ → Plex Media Server → Plex アプリ** | サーバー、ライブラリ、既存の作業手順をそのまま使える | zurg とファイルシステムのマウントをサーバーと並行して動かします。スキャンではリモートのファイルを読み込みます |
| Plex アプリは使いたいが、マウントしたライブラリは管理したくない | **zurg → rex → Plex アプリ** | zurg がマウントや Plex Media Server なしでライブラリを rex に提供する | 両方のサービスを稼働させたままにします。rex のアプリ互換性とアカウントの案内を確認してください |
| Stremio アドオンは使いたいが、Plex アプリの方が好み | **アドオン → rex-stremio → rex → Plex アプリ** | アドオンのカタログを Plex ライブラリに変換します。zurg は任意です | rex と rex-stremio を動かします。ストリームアドオンは、生のトレントではなく再生可能な URL を返す必要があります |
| プレーヤーが Jellyfin経由でライブラリにアクセスする | **Jellyfin 内のプロバイダープラグイン → 対応クライアント** | 別途 zurg のサービスやマウントは不要 | Jellyfin 12 と対応するプラグイン。プラグインには独自のアーカイブ制限があります |
| プレーヤーが Emby経由でライブラリにアクセスする | **Emby 内のプロバイダープラグイン → 対応クライアント** | すべてを既存の Emby サーバー内に収めておける | 対応する Emby バージョンを使ってください。これら6つのプラグインは debrid に対応し、直接の Usenet には対応していません |
| Jellyfin/Emby に加え、独自のファイルシステムや WebDAV アクセスが必要な利用者がいる | **zurg → マウント → Jellyfin/Emby** | 1つのライブラリで複数の利用者に対応できます | マウントとサーバーのパスを管理します。他の利用者は zurg を直接使えます |
| NZB ファイル、自分の Usenet アカウント、Jellyfin を使いたい | **Jellyfin 内の NZB プラグイン → 対応クライアント** | 別途 zurg のサービスなしで NZB をストリーミングできる | NNTP アクセスと対応する Jellyfin バージョン。プラグインは圧縮・暗号化されたアーカイブのメンバーを除外し、PAR2 による修復は行いません |
| SMB 共有を読み込むハードウェアプレーヤー | **zurg → マウント → ホストの SMB 共有 → プレーヤー** | プレーヤー本来のファイルブラウザと再生機能をそのまま使える | SMB はホストが提供します。zurg 自体が提供するのは WebDAV で、SMB サーバーではありません |
| 自分の Usenet アカウントと Stremio | **Newznab インデクサー → zurg の Stremio アドオン → Stremio** | 再生時に検索し、自分のニュースアカウント経由でストリーミング | 稼働中の zurg、インデクサーへのアクセス、NNTP の認証情報。別のデバイスからは到達可能な HTTPS アドオンのアドレスが必要です |
| 別のコンピューターなしの Android/Google TV デバイス | **zurg+rex Android → そのデバイス上のプレーヤー、またはそのデバイスや家庭内の Plex アプリ** | Android デバイス上で zurg と rex を動かします。スマホやテレビボックスで自分の Plex サーバーを動かし、その画面と家庭内の Plex アプリで使います | スポンサー向けアクセス、サイドロード、バックグラウンド動作が必要です。Usenet には 64 ビットの Android が必要です。TorBox のホスト型 NZB は Android では利用できません |
| ディスク/NAS にすでにあるファイル | **既存のメディアサーバーまたはネットワークプレーヤー**。rex を使いたい場合は **HTTP ソース → rex** | 持っているファイルをそのまま使えます。debrid や Usenet のアカウントは不要 | rex には、フィードAPI経由で送信されるメタデータと、ファイルへの HTTP アクセスが必要です。フィードの提供元とファイルサーバーは別々でも構いません。rex はディスクをスキャンしません |
| ストリーミング可能な HTTP メディアまたは自分の HTTP サーバー | **HTTP ソース + rex フィード → rex → Plex アプリ**、または対応プレーヤーに直接 | debrid や zurg なしで既存のソースを使えます | rex には、識別情報とメディアの詳細を送信するフィードの提供元が必要です。URL だけではそのメタデータは得られません |

最初に見るページ: [DMM Cast](https://debridmediamanager.com/stremio/) · [Kodi](https://debridmediamanager.com/kodi) · [DMM Settings](https://debridmediamanager.com/settings) · [zurg のセットアップ](../zurg/setup/index.md) · [zurg と使う rex](../rex/with-zurg.md) · [Stremio アドオンと使う rex](../rex/stremio.md) · [Jellyfin プラグイン](https://debridmediamanager.com/jellyfin) · [Emby プラグイン](https://debridmediamanager.com/emby) · [zurg の Stremio アドオン](../zurg/guides/stremio.md) · [Android](../zurg/guides/android.md) · [任意のソースと使う rex](../rex/any-source.md)。

Cast のリンクは Real-Debrid から始まります。アカウントを使う場合は、[TorBox](https://debridmediamanager.com/stremio-torbox/) や [AllDebrid](https://debridmediamanager.com/stremio-alldebrid/) や [Premiumize](https://debridmediamanager.com/stremio-premiumize/) や [Offcloud](https://debridmediamanager.com/stremio-offcloud/) や [Debrid-Link](https://debridmediamanager.com/stremio-debridlink/) や [Easynews](https://debridmediamanager.com/stremio-easynews/) のセットアップページを使ってください。ここでの Cast は **DMM アドオン**を意味します。Chromecast や画面ミラーリングのことではありません。

## 再生の全体像 {#the-playback-map}

矢印は「ライブラリまたは再生可能なストリームを提供する先」を意味します。パケットのルーティング図ではありません。ルートによっては、プレーヤーがプロバイダーから直接取得することもあれば、サーバーがデータを中継することもあります。

[再生マップを全画面で開く](../assets/setup-routes/playback.svg)と、拡大表示や保存ができます。

```mermaid
flowchart TD
    A[Debrid account] --> B[DMM Cast]
    E[Easynews account] --> B
    B --> C[Stremio]
    A --> K[DMM Kodi addon]
    E --> K
    K --> KD[Kodi]
    A --> D[Provider WebDAV, when offered]
    D --> W[WebDAV or SMB player]
    D --> KD
    A --> V[DMM Watch]
    E --> V
    V --> F[External player]
    A --> Z[zurg]
    N[Own Usenet account] --> Z
    T2[TorBox hosted NZBs] --> Z
    T2 --> TC[TorBox Cast]
    TC --> C
    T2 --> K
    Z --> W[WebDAV or SMB player]
    Z --> F
    Z --> KD
    Z --> ZA[Stremio NZB search addon]
    ZA --> C
    Z --> M[Filesystem mount]
    M --> SMB[Host SMB share]
    SMB --> W
    M --> S[Plex Media Server, Jellyfin or Emby]
    S --> P[Compatible server clients]
    Z --> R[rex]
    T[Stremio catalogs and URL stream addons] --> X[rex-stremio]
    X --> R
    H[Other HTTP source with rex feed] --> R
    R --> Q[Plex apps]
```

Stremio の NZB 検索ルートには、`nzb` アカウント（TorBox がすでに保持しているリリースの場合は `torbox_nzb`）と Newznab インデクサーが必要です。TorBox でホストされている NZB は、zurg を使わなくても TorBox Cast または Kodi アドオン経由で再生できます。マウントから SMB へのルートには、ホスト側で別途設定した共有フォルダーが必要です。

ほかに、分けて考えておきたい小さなルートが2つあります。

[プラグインマップを全画面で開く](../assets/setup-routes/plugins.svg)。

```mermaid
flowchart LR
    D[Debrid account] --> J[Plugin inside Jellyfin or Emby]
    J --> A[Compatible server clients]
    U[NZBs and own news account] --> N[NZB plugin inside Jellyfin]
    N --> F[Compatible Jellyfin clients]
```

プラグインは別々の連携機能です。プラグイン名に含まれる「zurg」は、zurg アプリケーションを実行しなければならないという意味では **ありません**。また、同じ機能が使えることも保証されません。TorBox プラグインのトレントライブラリは、zurg のホスト型 NZB バックエンドとは別物です。

## ファイルの取得元を選ぶ {#choose-where-the-files-come-from}

**インデクサー**はリリースを探します。**torrent または NZB** は、そのリリースをどう取得するかを説明します。**プロバイダー**が実際のデータ（バイト列）を提供します。**プレーヤー**がそれをデコードします。どれか1つにアクセスできても、他のものまで使えるわけではありません。

| 入力 | 動画を取得・配信するのは？ | 必要なもの | 役立つ場面 |
|---|---|---|---|
| キャッシュ済みの torrent、magnet、torrent ファイル | あなたのデブリッドプロバイダー | 選んだ連携に対応したアカウント | 目的のリリースがすでに利用可能な場合、待ち時間が最も短いことが多いです |
| キャッシュされていない torrent | デブリッドプロバイダーが先にダウンロードします | torrent を受け付けるアカウント、利用可能なソース、制限内の空き容量 | 見たいリリースがキャッシュされていない場合。待ち時間が発生し、失敗することもあります |
| NZB（自分のニュースアカウントを使用） | zurg の **direct Usenet** バックエンド、または Jellyfin の NZB プラグインが、必要に応じて記事を読み込みます | NZB、NNTP アクセス、選んだ連携。検索したい場合はインデクサーへのアクセス | プロバイダーやバックボーンを選び、予備のアカウントを使い、動画全体をローカルに保存しないようにします |
| NZB（TorBox のホスティングサービスを使用） | **TorBox が取得と修復を行い**、完成したファイルを配信します | TorBox Pro。DMM または zurg の **TorBox hosted NZB** バックエンドから送信 | ニュースサーバーの認証情報やローカルでのデコードを管理せずに NZB を使いたい場合 |
| DMM の Usenet 結果を Real-Debrid に送信 | DMM のホスト型転送サービスが取得し、**あなたの Real-Debrid ライブラリ**に渡します | Real-Debrid と、利用可能な DMM 転送枠 | すでに RD で視聴していて、そのリリースをそこに入れたい場合。個人の NNTP アカウントは不要です |
| Easynews の検索結果 | Easynews が直接 HTTP のダウンロード/ストリームを配信します | 自分の Easynews アカウント | NZB ライブラリを作らずに、DMM から視聴や Cast をする場合、または Easynews の Cast/Kodi ルートを使う場合 |
| 直接の HTTP(S) ダウンロードリンク | 対応するプレーヤーや HTTP ソース、またはそのダウンロードに対応するプロバイダー | 実際のメディア URL へのアクセス。そこでインポートや unrestrict をする場合は適切なプロバイダーアカウント | torrent や NZB ではなく、すでにファイルの URL を持っている場合 |
| ディスクや NAS 上のファイル | ファイル／メディアサーバー | ローカルストレージと、それに接続できるプレーヤー | オフラインで所有しているファイル、ホームビデオ、既存のコレクションを残したい場合 |

zurg は **Real-Debrid、AllDebrid、TorBox、Premiumize、Offcloud、Debrid-Link** に対応しています。1つのライブラリに複数のアカウントを組み合わせられます。ただし、キャッシュの上限やファイルの利用可能性はプロバイダーごとに異なります。キャッシュ済みのバッジは目安であり、再生が保証されるわけではありません。詳しくは [プロバイダー](../zurg/providers/index.md) を参照してください。

### 「Usenetアカウントなしのusenet」：どのルートを使う？ {#usenet-without-a-usenet-account-which-route}

[Usenetの図を原寸で開く](../assets/setup-routes/usenet.svg)

```mermaid
flowchart TD
    N[NZB or Usenet search result] --> O{Who fetches it?}
    O --> A[Your news accounts]
    A --> J[Jellyfin NZB plugin]
    J --> F[Compatible Jellyfin clients]
    A --> Z[zurg direct Usenet]
    Z --> V[Your chosen zurg playback route]
    O --> T[TorBox Pro hosted Usenet]
    T --> B[TorBox completed files]
    B --> C[DMM TorBox Cast, the Kodi addon or zurg hosted NZB library]
    O --> D[DMM hosted transfer]
    D --> R[Your Real-Debrid library]
    R --> P[Your chosen RD playback route]
```

**TorBox hosted NZBs を選ぶ**と、ダウンロードと修復はTorBoxが行います。DMMはNZBをTorBoxに送ります。現在のzurgのnightlyでは、プロバイダータイプ`torbox_nzb`を使い、watch directoryとSABnzbdインターフェースから取得したNZBを受け付けます。[TorBox hosted Usenet](../zurg/providers/torbox-nzb.md)にzurgの設定方法があります。キャッシュにない場合は、再生の前にダウンロードが完了している必要があります。ダウンロードはtorrentとスロットを共有します。保存されたファイルは期限切れになることがあり、zurgは期限切れのリリースを再取得することを保証しません。別の取得に備えて、NZBは保存しておいてください。

**直接のUsenetを選ぶ**と、自分のニュースアカウント（フォールバックやブロックのアカウントを含む）を通してzurgに読み込ませられます。これは、NNTPの認証情報とともに`nzb`を使います。TorBoxのニュースサーバーのログインもここに含まれます。TorBox hosted NZBsとは別物です。[TorBox NNTP](../zurg/providers/torbox-news-server.md)と[その料金プラン](https://torbox.app/pricing)を参照してください。

**1つのzurgインスタンスは`nzb`か`torbox_nzb`のどちらか一方を使います。** どちらもNZBのwatch directoryを占有します。両方を使うなら、インスタンスと作業ディレクトリを分けて別々に実行してください。両方で`dmm_api_key`を設定している場合は、[片方の`dmm-wanted`ソースをオフにしてください](../zurg/guides/dmm-wanted.md#two-zurgs-on-one-key)。そうしないと、すべてのWantedタイトルが2回取得されてしまいます。どちらのオプションも、torrentプロバイダーと併用できます。zurgのStremioアドオンは、選んだリリースを、そのインスタンスが持つNZBアカウントに送信します。`torbox_nzb`の場合、TorBoxがすでに保持しているリリースだけが、アドオンの待機時間内に開始されます。しかも、ほかのNZBの投稿が待機中でないときに限られます。

**DMM → Real-Debridを選ぶ**と、リリースをReal-Debridのライブラリに入れられます。これはキューと割り当て量のあるホスト型の転送です。キャッシュにないジョブには時間がかかります。Real-Debridやほかのdebridプロバイダーに、ネイティブのNNTPサポートが追加されるわけではありません。DMMの結果と[転送ページ](https://debridmediamanager.com/transfers)で進行状況を確認できます。

Easynewsでは、**Watch**と**Cast**でそのHTTPファイルを再生し、**Download NZB**でリリースのNZBを保存できます。**Send to zurg**を押すと、そのNZBをスポンサー向けのWantedリストに追加します。これには、設定済みのNZBバックエンドが必要です。DMMにEasynewsのログインをしても、zurgのNZBアカウントは設定されません。

### HTTPリンクの場合は？ {#what-about-http-links}

DMMのTorBoxの**Add**ダイアログは、直接のHTTP(S)リンクをウェブダウンロードとして受け付けます。zurgはそれを`__downloads__`に表示します。ただし、そこにあるアイテムは自動的に識別済みのrexライブラリアイテムになるわけではありません。Real-Debridの無制限ダウンロードも、そこに表示されることがあります。DMM TorBox Castには、完了したウェブおよびUsenetのダウンロードとトレントが含まれます。ウェブページでは、ログインの有効期限切れ、URLの期限切れ、DRM、独自のプレーヤーなどの理由で、別の連携が必要になる場合があります。

**rexは、フィードAPIを通じてストリーミング可能なHTTP(S)メディアに対応しています。** [ソースまたはアドオン](../rex/any-source.md)がメディアのアドレスとメタデータを送信します。すると、rexがそれをPlexアプリで利用できるようにします。ファイルサーバーとフィード提供元は別々にすることもできます。zurgやデブリッドのアカウントは不要です。[rex-stremio](../rex/stremio.md)は、対応しているStremioアドオンでこれを行います。生のマグネットリンクやトレント専用のストリームは動作しません。HLSにはrexのFFmpeg設定が必要です。rexは、ソースが提供するIDをそのまま使います。

## タイトルの追加方法を決める {#decide-how-titles-get-added}

取得と再生は別々に選べます。作品のリクエスト方法を変えても、視聴に使うアプリを替える必要はありません。

| 作品の選び方 | ルート | 使う理由 |
|---|---|---|
| 正確なリリースを選ぶ | DMM search/library → provider; または NZB → 選択した NZB バックエンド | エディション、サイズ、リリースを自分で管理できる |
| Want を押す、または Trakt/MDBList のリストをフォローする | [DMM Wanted](../zurg/guides/dmm-wanted.md) → zurg acquisition | Sonarr/Radarr を動かさずに映画と新しいエピソードを自動取得できる。スポンサーシップが必要 |
| Seerr/Overseerr/Jellyseerr で家族からリクエストを受ける | [Seerr through DMM](../dmm/seerr.md) → Wanted → zurg | arr サーバーなしで、使い慣れたリクエスト UI を使える。スポンサーシップが必要。Seerr の接続先として Plex、Jellyfin、Emby サーバーのセットアップが必要 |
| 既に Plex のウォッチリストやリクエストの仕組みがある | [zurg acquisition](../zurg/guides/acquisition.md) | 既存のリクエスト元を維持できる。検索先とプロバイダーの設定を行う |
| Sonarr/Radarr で詳細な監視と品質プロファイルを使いたい | DMM またはインデクサー → arr → zurg のダウンロードクライアントインターフェース → ライブラリ | arr の判断とインポートの流れを維持できる。サービスとパスの設定が増える |
| 再生ボタンを押したときだけ選びたい | DMM Cast/Kodi、別のストリームアドオン、または zurg の Stremio 検索 | すべての作品を事前に管理ライブラリとして用意する必要がない |

おすすめの DMM + zurg arr ルートでは、**DMM がインデクサー、zurg がダウンロードクライアント**になります。DMM は [Torznab](https://debridmediamanager.com/torznab) と [Newznab](https://debridmediamanager.com/newznab) を提供しています。どちらも有効なスポンサーシップが必要です。Prowlarr は任意です。zurg は [qBittorrent](../zurg/guides/sonarr-radarr-torrents.md) と [SABnzbd](../zurg/guides/sonarr-radarr.md) のインターフェースを提供します。zurg と並べてこれらのダウンロードアプリを用意する必要はありません。[zurg は arr 向けの検索もできます](../zurg/guides/sonarr-radarr-fetch.md)。

**完全なローカルコピー**がほしい場合は、プロバイダーまたは zurg からファイルをダウンロードしてください。プレイヤーのオフラインダウンロード機能や、通常のダウンローダーとディスクライブラリを使うこともできます。クォータを確認してから、ネットワークなしで保存したファイルを再生してください。zurg の仮想ファイル、`.strm` リンク、[ローカル debrid カタログ](../zurg/guides/local-libraries.md) はオフラインコピーではありません。ローカルカタログはレコードだけを保存します。再生には引き続きプロバイダーが必要です。

## インストール前に知っておくべきトレードオフ {#the-tradeoffs-that-matter-before-installing}

| 質問 | 選択を左右するもの |
|---|---|
| 別のマシンを起動したままにする必要がありますか？ | ホスト型の Cast/Kodi ルート、プロバイダーの WebDAV、DMM Watch は、自分のサーバーが不要です。zurg、rex、rex-stremio、メディアサーバーのプラグインは、視聴中にホストが動いている必要があります。zurg+rex Android では、Android デバイスを zurg と rex のホストにできます。rex-stremio とメディアサーバーのプラグインは、通常のホストが必要です。レンタルやマネージドホストは、誰が運用するかを変えるだけで、ルートそのものは変わりません。 |
| テレビでファイルを再生できますか？ | WebDAV とアドオンのルートは、プレーヤーのコーデック、音声、字幕に依存します。zurg はバイトを配信するだけで、動画のトランスコーダーではありません。Plex Media Server、Jellyfin、Emby、または FFmpeg を使う rex は、必要に応じて変換できます（適切なハードウェアとサーバー/アプリの機能が必要です）。 |
| ディスク容量はどれくらい必要ですか？ | ストリーミングなら、コレクション全体を保存する必要はありません。ただし、データベース、アートワーク、キャッシュ、修復・トランスコード・オフラインダウンロードの作業用に、容量は確保しておいてください。「最初に全体をダウンロードしない」は、ディスクをまったく使わないという意味ではありません。 |
| 帯域幅の費用は誰が負担しますか？ | プロバイダーのトラフィック上限は引き続き適用されます。サーバープロキシは再生トラフィックを運び、そのサーバーの送信帯域を使います。直接再生の場合は、接続が視聴者側に移ります。ライブラリの解析でも、リモートのファイルを読むことがあります。 |
| 外出先でも使えますか？ | ホスト型アドオンなら、自分のサーバーを公開せずに済みます。セルフホストのサービスには、安全に到達できるアドレスが必要です。LAN アドレスだけでは、外からは使えません。[rex のリモートアクセス](../rex/any-source.md#use-it-outside-your-home-optional)と[Stremio の HTTPS ガイド](../zurg/guides/stremio.md#installing-it-on-another-device)を参照してください。 |
| 家族が同時に使えますか？ | プロバイダーの IP/同時接続ルールと、サーバーの共有モデルを確認してください。Real-Debrid の利用は、1 つのパブリック IP に限定しておく必要があります。中央のライブラリがリンクを提供していても、別の世帯への直接リンクは、このルールに違反するおそれがあります。ダウンロードの発生元を理解しないままリダイレクトを有効にしないでください。 |
| 何にお金を払いますか？ | プロバイダーの契約、インデクサーへのアクセス、DMM のスポンサー、ホスティング、プレーヤー/サーバーの購入は、それぞれ別に考えてください。DMM の基本ウェブサイトと、個人利用の rex は無料です。[rex for Android](https://github.com/debridmediamanager/rex-android) も無料です。現在の zurg nightlies と DMM のプラグイン配布はスポンサー特典です。Wanted と DMM のインデクサー API もスポンサーが必要です。rex-stremio は必要ありません。[スポンサーシップで得られるもの](sponsorship.md)に、すべての特典と設定場所を一覧にしています。 |
| カタログに載っていれば再生は保証されますか？ | いいえ。アドオンのカタログはタイトルを説明するだけです。クラウドのファイルは期限切れになることがあり、トレントにはソースがないことがあり、Usenet の記事は欠けていることがあります。失敗時や待ち時間の動作が許容できるルートを選んでください。 |

互換性のあるサーバークライアントは、サードパーティのアプリでもかまいません。[Infuse は Plex、Emby、Jellyfin に接続できます](https://support.firecore.com/hc/en-us/articles/360006462093-Streaming-from-Plex-Emby-and-Jellyfin)。別個の zurg マウントは不要な場合もあります。プラグインとクライアントをあわせて確認してください。

Infuse は[WebDAV やその他のネットワーク共有](https://support.firecore.com/hc/en-us/articles/215090977-Streaming-From-a-Mac-PC-or-NAS)に対応しています。`.strm` ファイルは、Kodi などの互換プレーヤーに URL を渡します。これは、マウントの完全な代わりにはなりません。クライアントを確認し、プロキシやフェイルオーバーの動作が異なることを想定してください。通常の Plex Media Server の構成には、`.strm` を使わないでください。

[従来の無料 zurg リリース](https://github.com/debridmediamanager/zurg-public/releases)もあります。これは Real-Debrid のみに対応し、設定形式が異なります。ここで説明する複数プロバイダーの Usenet と Android のルートは、スポンサー向けの nightlies を使います。

**rex には独自の互換性の境界があります。** rex は独立した Plex アプリサーバーです。Plex Media Server でも Plex プラグインでもありません。動作確認済みのデバイス、リモート利用時のトランスコード、新規アカウントの推奨事項については、[FAQ](../rex/faq.md)を参照してください。従来の Plex サーバーは、rex と並行して動かせます。

## ルートを変える可能性のある条件 {#needs-that-can-change-the-route}

| 他に必要なこと… | 選ぶ・確認すること |
|---|---|
| ローカルファイルとクラウドのタイトルを一緒に使う | 今使っている Plex/Jellyfin/Emby サーバーはそのまま使い、マウントまたは対応するプラグインを追加してください。rex は複数のフィードソースをまとめられます。ローカルファイル用の HTTP ソースも使えます。ただし、メタデータは各サーバー側で必要です。 |
| 字幕ファイルを自動で用意する | プレーヤーが提供する字幕や、動画に埋め込まれた字幕で足りることもあります。arr のワークフローを使う場合は、[zurg と組み合わせた Bazarr](../zurg/guides/subtitles.md) が仮想ビデオの横にローカルのサイドカーファイルを書き出します。ただし、そのサイドカーファイルは DMM Cast、Kodi アドオン、DMM Watch、zurg の Stremio アドオンには届きません。Kodi には zurg の WebDAV ソースとして届きます。Bazarr を使わなくても、rex には Search Subtitles があります。 |
| サーバーを変えるときの視聴履歴 | 切り替える前に [Plex からの移行](../rex/from-plex.md)と[視聴状況のインポート](../rex/import-watched.md)を読んでください。ソースを変えても、すべてのアプリの履歴が自動で移行されるわけではありません。 |
| 自分のアカウントを持つ人と選択内容を共有する | DMM の hashlist では、リリースの選択内容を共有して、相手が自分のアカウントに追加できます。相手に自分の認証情報を渡すことも、再生をホストすることもありません。サーバーを共有するのは別の方法で、そのサービスの共有ルールやプロバイダーのルールに従う必要があります。 |
| 帯域幅が限られた VPS やリモートホスト | 再生がプロキシされているか、リダイレクトされているかを確認してください。[rex のダイレクトダウンロード設定](../rex/direct-download.md)にオプションの説明があります。リダイレクトすると、ダウンローダーの公開IPが変わり、プロバイダーの URL が露出することがあります。 |

## その他のメディアと既存の構成 {#other-media-and-existing-setups}

- **音楽:** [DMM Music](https://debridmediamanager.com/music/) では Real-Debrid のブラウザ再生とダウンロードができます。[rex の音楽ソース](../rex/music.md)は Plexamp と対応する Plex アプリに送られます。ソースは音楽用に設定したアドオンまたは zurg です。映画/TV 用のアドオンが音楽も提供するとは限らないので、思い込まないでください。
- **Live TV:** [rex の Live TV ルート](../rex/live-tv.md)は、対応するアプリでチャンネルとガイドを提供します。rex-stremio のライブチャンネルは、チャンネルのライブラリとして表示されます。これはガイドの画面とは別物です。ソースが使えるかどうかは事前に確認してください。rex は DVR 録画には対応していません。
- **ホームビデオ、録画、写真:** 既存のメディアサーバーを使うか、[自分で管理する rex ソース](../rex/addons.md)を使ってください。後者の例は[ホームビデオのチュートリアル](../rex/addon-home-videos.md)にあります。zurg は、コミックブックを写真として rex に渡すこともできます。ただし、アプリごとの対応状況は異なります。
- **既存の Kodi/Stremio アドオン:** 今使っているアドオンで満足しているなら、そのまま使い続けてください。DMM は、プレーヤーを置き換えなくてもリリースの選択と管理に使えます。プロバイダー、Usenet、HTTP への対応はアドオンによって違います。DMM のルートが、すべてのアドオンで動く保証はありません。
- **別のデブリッドマウント/ダウンローダーがすでにインストール済み:** 切り替える前に、[移行の選択肢](../zurg/migrate/index.md)を確認してください。今のセットアップが動いているなら、あるというだけの理由で別のレイヤーを足す必要はありません。
- **開発中のネイティブアプリ:** Usenet TV は、ここでおすすめできる公開済みのアプリストア版セットアップではありません。Yomu TV は読書やオーディオブック向けの別プロジェクトで、この映画/TV のスタックには関係ありません。どちらも上のルートには必要ありません。

## よくある5つの出発点 {#five-common-starting-points}

1. **「Stremio と RD を使っている」場合。** まずは DMM Cast から始めてください。共有ライブラリ、自動化、または別のクライアントが必要になったときだけ zurg を追加します。
2. **「TorBox Pro を持っていて、その投稿の NZB を使いたい」場合。** DMM を通して NZB を TorBox に送ります。Stremio で見るなら TorBox Cast、Kodi で見るなら Kodi アドオン、選んだライブラリ/プレーヤーのルートに流すなら zurg のホスト型 NZB バックエンドを使ってください。
3. **「すでに Jellyfin を使っている」場合。** まずは利用しているプロバイダー用のプラグインから始めてください。共有ファイルシステム、自動化、より広いバックエンド機能が必要になったら、別の zurg を選びます。
4. **「Plex のアプリを使いたい、マウントは不要、今のアドオンもそのまま使いたい」場合。** rex と一緒に rex-stremio を使います。公開したいものが、管理している debrid/Usenet ライブラリなら、代わりに zurg をソースとして使ってください。両方のソースを同じ rex に接続することもできます。
5. **「ニュースサーバーのアカウントがあり、Sonarr/Radarr を使いたい」場合。** DMM Newznab か既存のインデクサー、zurg の NZB/SABnzbd ルート、そして上の表の再生ルートを組み合わせてください。ローカルに永続的なファイルを残したい場合は、通常のダウンローダーを選ぶか、完全なコピーを明示的に保存してください。仮想インポートだけではオフラインファイルにはなりません。

それでも迷う場合は、**使っているデバイスやプレーヤー、既存のアカウント、ホストを常時稼働させられるか、オンデマンド再生と自動ライブラリのどちらを求めているか**を教えてください。これらの答えで、ほとんどの場合ルートが決まります。質問先については [ヘルプを得る](remote-help.md) を参照してください。
