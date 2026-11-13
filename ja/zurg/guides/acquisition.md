# 取得元 {#acquisition-sources}

Plex のウォッチリスト、[DMM の希望リスト](#dmm-wanted-list)、[Seerr](https://github.com/seerr-team/seerr)、
[Radarr](https://radarr.video) と [Sonarr](https://sonarr.tv) は、ひとつの取得エンジンを使います。エンジンは進捗、再試行、確認応答を追跡します。
Newznab の結果は zurg の Usenet バックエンド用の NZB になります。Torznab の結果は、デビッドアカウント用の info hash になります。
[Newznab と Torznab](#newznab-and-torznab) を参照してください。

エンジンは、取得内容を確認してからでないと確認応答を返しません。NZB はニュースサーバーに届いている必要があります。`torbox_nzb` アカウントの場合は、代わりに TorBox が取得する必要があります。torrent はファイル付きでライブラリに現れている必要があります。
[取得の確認](#verifying-a-grab) を参照してください。

zurg が取得したリリースは、取得元のタイトルの ID を保持します。その ID は、Plex がタイトルの照合に使うものすべて、つまり IMDb、TMDB、そしてシリーズの場合は TVDB です。名前から再度特定されることはありません。これらの ID は、DMM やリリース名が付けた ID を置き換えます。ただし、あなたが手動で設定した ID は置き換えません。zurg が選んだ時点で既にライブラリにあったリリースは、別の目的で追加された可能性があるため、ID がないか、同じ ID をすでに持っている場合にのみ、これらの ID を取り込みます。[`rex_url`](../reference/config.md#rex) を設定していると、取得した映画は、DMM が配置できなかった場合でも、これらの ID を使って映画として rex に送られます。シリーズのエピソードは、引き続き DMM の配置による番号が付き、シリーズの ID を持ちます。起動時には、zurg は保存済みジョブが以前に取得したすべてのリリースに対して同じ処理を行います。これにより、この変更の前に ID を失ったリリースが修復されます。

## 設定 {#configuration}

```yaml
acquisition:
  quality: best
  prefer: usenet          # usenet (default), torrents, or best
  best_first: false       # true makes Radarr and Sonarr take the profile's best quality first
  max_size_gb: 0          # a cap on a film or episode, and each episode of a season pack; 0, the default, is none
  max_season_size_gb: 0   # a cap on each season a pack holds; 0, the default, is none
  exclude_words: [DV, HDR10+]  # never take a release whose name says these
  prefer_words: [FraMeSToR]    # take a release whose name says these first, within its resolution
  audio_languages: [original]  # take only releases with this audio (any one), read from the streams
  subtitle_languages: [en]     # and with these subtitles
  concurrency: 8          # titles worked on at once (default 8, at most 200)
  indexer_concurrency: 3  # calls to one indexer at once (default 3, at most 16)
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
      # type: newznab      # default, a Usenet indexer
    - name: my-trackers
      url: https://prowlarr.example
      api_key: YOUR_PROWLARR_API_KEY
      type: torznab        # a torrent indexer, handed to a debrid account
    - name: zilean
      url: http://zilean:8181/torznab
      type: torznab        # no api_key: Zilean takes none, and is asked without one
  sources:
    - name: plex-watchlist
      type: plex_watchlist
      enabled: true
      check_every_secs: 60
      remove_after_grab: true   # default; false keeps the watchlist intact
      only_new_items: true      # default; false works through the existing list
    - name: requests
      type: seerr
      enabled: true
      url: http://seerr:5055
      api_key: YOUR_SEERR_API_KEY
      check_every_secs: 60
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Radarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Sonarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
```

zurgのインスタンスで、`nzb`プロバイダーまたは`torbox_nzb`アカウント（TorBox Pro）、あるいはトレントに対応するdebridアカウント、またはその両方を使っている場合に、これを実行してください。
Newznabインデクサーからの NZB は、`nzbs/` ディレクトリに保存されます。
`torbox_nzb`アカウントには照合するニュースサーバーがありません。そのアカウントでの取得は、TorBoxが取得できたかどうかで確認されます。
Torznabインデクサーからのトレントはdebridアカウントに送られます。そのアカウントにキャッシュ済みのものだけが追加されます。どちらのアカウントもない場合、ソースは開始されません。その理由は取得ページに表示されます。
Plexには既存の`plex_token`が必要です。Seerrには、zurg の Plex 設定とは独立して、ベース URL と API キーが必要です。URL のサブパスと、`/api/v1`で終わる URL に対応しています。Radarrには、ベース URL（`/radarr`のような URL ベースや、末尾の`/api/v3`も使えます）、**Settings > General**にある API キー、そしてzurgのマウントが別のパスに見える場合は`library_path`が必要です。詳しくは[Radarr の動作](#radarr-behavior)を参照してください。Sonarrも同じ3つの設定を使います。詳しくは[Sonarr の動作](#sonarr-behavior)を参照してください。

この2つは、ブロック内の他の設定と同様に、zurgの起動時に読み込まれます。`indexer_concurrency`は検索とNZBダウンロードの両方に適用されます。インデクサーはエンドポイントではなくキーごとに利用量を制限するためです。インデクサーのキーは他のアプリケーションと共有されることが多く、キーごとに3件の同時リクエストであれば、他のアプリも使っているキーでも安全だと実測で確認されています。

名前とSeerrのURLは変更しないでください。これらは保存済みのキューを識別するためです。Seerrのキーを更新しても、キューは保持されます。ソースを追加したり、そのURLや認証情報を変更したりした後は、再起動してください。既存の`watchlist:`と`plex_watchlist_enabled`の設定は、自動的に作られる`plex-watchlist`アダプターを通じて引き続き動作します。明示的な`plex_watchlist`ソースは、無効になっていても従来の有効化スイッチより優先されます。設定された Plex アカウントを使えるPlexソースは1つだけです。共通の検索設定は`watchlist:`とその既存のデフォルト値にフォールバックします。省略されたインデクサーはwatchlist/Stremioのインデクサーにフォールバックします。

## 名前で除外するリリース {#excluding-releases-by-name}

```yaml
acquisition:
  exclude_words: [DV, HDR10+]
```

`exclude_words` は、取得するどのリリース名にも含まれてはいけない単語のリストです。
Dolby Vision や HDR10+ を表示できないプレイヤーに入れないようにしつつ、4K は取得したいときに使ってください。すべてのソースに同じように適用されます。Plex のウォッチリスト、Seerr、Radarr、Sonarr が対象です。Usenet と torrent の結果も同じように扱われます。除外されたリリースは、取得されることも、保存されることも、debrid アカウントに追加されることも、Radarr や Sonarr に渡されることもありません。何も除外したくないなら、このキーは省略してください。zurg は起動時に、`config.yml` の他の設定と同じようにこれを読み込みます。

## 名前で優先するリリース {#preferring-releases-by-name}

```yaml
acquisition:
  prefer_words: [FraMeSToR, CiNEPHiLES]
```

`prefer_words` は、リリースグループなどの単語を並べるリストです。同じ解像度のリリースの中で、その単語を持つものを先頭に持ってきます。照合のしかたは `exclude_words` と同じで、単語全体の一致、大文字小文字は区別しません。リストは順番どおりに扱われます。最初の単語を持つリリースが、2番目の単語を持つリリースより前に来る、という具合です。これは優先設定であってフィルターではありません。どのリリースもリストの単語を持たない場合、zurg は単語がなかったときと同じものを選びます。

優先されたリリースが解像度を飛び越えることはありません。`quality: best` の場合、どのグループの 2160p リリースも、優先されている 1080p リリースより前に来ます。`quality: 1080p` の場合、優先されている 2160p リリースが 1080p のリリースより前に来ることはありません。優先されたグループにその解像度のリリースがない場合でも、より高い解像度へのアップグレードは行われます。

これはすべてのソースに適用され、Usenet と torrent の両方の結果に効きます。`radarr` や `sonarr` のソースを使う場合、プロファイルが優先リリースを受け入れる必要があります。Radarr や Sonarr がダウンロードクライアントとして zurg を使うときは、リリースを自分で選ぶので、`prefer_words` はそこでは適用されません。何も優先させたくなければ、このキーを省いてください。

映画のリリースは、名前に含まれる年が映画の年と 1 年以上ずれている場合、ソースに関係なく採用されません。インデクサーの中には、別の映画の IMDb ID で投稿を登録しているものがあります。例えば DrunkenSlug は *The Aswang Chronicles* (2012) を、その続編である 2014 年の作品の下に登録しています。年の書かれていない名前は、この理由では除外されません。DMM の wanted リストは、映画が知られているすべてのタイトル（原題、別名、翻訳）を送ります。このリストでは、名前がそのうちのいずれかのタイトルを丸ごと含んでいないリリースも除外されます。例えば DrunkenSlug は *Przesluchanie* (1982) を *An Affair* (1982) の下に登録しています。また `Rocky.2015` は *Rocky Horror Show Live* ではありません。名前は、タイトルのサブタイトルが始まるところで止まっていてもかまいません。コロンや、スペースで挟まれたダッシュの後がそれにあたります。そのため `Diana.2021` は *Diana: The Musical* として扱われます。アクセント記号やウムラウトは、どちらの表記でも一致します。つまり `Les.Miserables` や `Verwuenscht.nochmal` も一致として扱われます。

名前の照合のしかたは次のとおりです。

- **単語全体だけを照合します。** 名前は、文字と数字からなる単語として読まれます。ドット、スペース、ダッシュ、アンダースコア、角かっこ、丸かっこは、どれも単語を区切ります。大文字小文字は区別しません。`DV` は `Avengers.Infinity.War.2018.DV.2160p.WEB.H265-RVKD` と `Mortal_Kombat_II_2026_COMPLETE_BLURAY_2160p_DV_HDR_TrueHD` を除外します。一方、`DVDRip`、`DVD9`、`Come and See DvD 1`、*Adventures* のようなタイトルは、DV という単語を含まないので除外しません。
- **フレーズは順番どおりに一致します。** `Dolby Vision` や `DV HDR` は、その単語が指定した順番で並んでいれば、間に何が挟まっていても一致します。
- **末尾の `+` は単語の一部です。** `HDR10+` は独立した単語になります。`HDR10` を除外しても HDR10+ のリリースは除外されず、`HDR10+` を除外しても普通の HDR10 は除外されません。両方を除外したい場合は、両方を並べてください。2つの単語の間にある `+` は区切りとして扱われ、`DD+7.1` や `DV+HDR10` のように使われます。
- **2つの表記のグループは、1つの単語として扱われます。** リストにあるどれか1つの表記は、そのグループに属するすべての表記を除外します。

  | Write any of | Excludes names with any of |
  |---|---|
  | `DV`, `DoVi`, `Dolby Vision`, `DolbyVision` | `DV`, `DoVi`, `Dolby.Vision`, `Dolby-Vision`, `Dolby Vision`, `DolbyVision` |
  | `HDR10+`, `HDR10Plus` | `HDR10+`, `HDR10Plus` |

  それ以外の表記は別名として扱われません。`HDR` は HDR という単語を持つ名前を除外しますが、`HDR10`、`HDR10+`、`HDRip` は除外しません。`WEB-DL` は `WEB-DL`、`WEB.DL`、`WEB DL` に一致しますが、`WEBDL` には一致しません。
- **読まれるのはリリース名だけです。** これは、ダウンロードされる前にインデクサーが返すタイトルです。中のファイルは読まれません。Dolby Vision のリリースでも、名前にそう書かれていなければ除外されません。

単語を除外しても解像度には影響しません。`DV` を除外しても、plain HDR や HDR10 の 2160p リリースは採用されます。また `quality: 4k` を指定すると、2160p が引き続き先頭に来ます。除外されたリリースは、見つからなかったものとして扱われます。映画やエピソードの検索は、採用できるリリースが 10 件になるか、インデクサーの結果が尽きるか、10 ページ読み終わるまで、各インデクサーのページを送り続けます。シーズン検索は 1 ページだけを読み、そのページに含まれないエピソードは個別に検索し直します。すべてのリリースが除外されたタイトルや、すべてのリリースが `max_size_gb` を超えたタイトルは、"no eligible releases" で失敗し、後でもう一度試されます。Seerr の 4K リクエストは 2160p のリリースだけを採用するので、すべての 2160p リリースが除外されている場合は待機します。

### 除外設定と Radarr または Sonarr のプロファイル {#exclusions-and-radarr-or-sonarr-profiles}

`radarr` または `sonarr` のソースでは、まず除外が適用されます。除外されたリリースは、Radarr や Sonarr のパーサーに渡されることはありません。カスタムフォーマットのスコアでも復活せず、プロファイルによる拒否としても数えられません。それ以外のリリースは、[Radarr の動作](#radarr-behavior)と[Sonarr の動作](#sonarr-behavior)で説明されているとおり、プロファイルで判定されます。リリースは両方を通過する必要があります。Dolby Vision のスコアをプロファイルの最低値より下げるカスタムフォーマットは、*arr の中で同じ役割を果たします。残しておいても問題はありません。

アップグレードも同じルールに従います。ファイルをプロファイルのカットオフまで引き上げられるリリースが、すべて除外されている場合、そのファイルはカットオフ未満のままになります。zurg のアップグレード処理は探し続けますが、何も取り込みません。これは、カスタムフォーマットが Dolby Vision に高いスコアを与えていて、カットオフのスコアがそれを必要とする場合に起こります。カットオフのスコアを下げるか、そのスコアをカスタムフォーマットから外してください。

Radarr や Sonarr が `sabnzbd:` または `qbittorrent:` ブロックを通じて zurg をダウンロードクライアントとして使う場合、それぞれ独自のインデクサーを検索して、リリースを自分で選びます。その場合、`exclude_words` は適用されません。同じ単語を *arr 側で除外してください。方法は、プロファイルの最低値より低いスコアのカスタムフォーマットを使うか、リリースプロファイルの **Must Not Contain** を使うかのどちらかです。

## 音声と字幕の言語で選ぶ {#choosing-by-audio-and-subtitle-language}

```yaml
acquisition:
  audio_languages: [original]   # or [de], [de, en], ...
  subtitle_languages: [en]
```

`audio_languages` は、指定した言語のいずれかの音声トラックを持つリリースだけを取得します。`subtitle_languages` は、指定した言語のいずれかの字幕トラックを持つリリースだけを取得します。どちらも省略すると、何も条件を付けません。どちらもすべてのソースに適用されます。

各リストは優先順位にもなります。前にある言語を持つトーレントが、後ろの言語だけを持つトーレントより先に来ます。`[de, original]` と書くと、ドイツ語吹き替えがあればそれを取得し、なければ原語を取得します。

zurg は、言語をリリース名ではなくストリームから読み取ります。ほとんどのリリースは言語名を書いていません。Parasite のリリースでも KOREAN と書かれているものはほぼありません。言語は ISO 639 のコードで、2 文字または 3 文字で書いてください。`en`、`eng`、`de`、`deu`、`ger` はすべて使えます。`german` のような名前は、起動時にエラーになります。

言語によっては、吹き替えや字幕が地域ごとに分かれていて、コードでその違いを指定できます。

| 書き方 | 対象 |
|---|---|
| `es-419`、`es-ES` | ラテンアメリカ系（Latino）またはカスティーリャ系のスペイン語 |
| `pt-BR`、`pt-PT` | ブラジルまたはヨーロッパのポルトガル語 |
| `fr-CA`、`fr-FR` | ケベック語（VFQ）またはフランス本国のフランス語（VFF、VFI） |
| `nl-BE` | フラマン語 |
| `yue`、`cmn` | 広東語または北京語 |
| `zh-Hant`、`zh-Hans` | 繁体字または簡体字の中国語字幕（`zh-TW` と `zh-HK` は繁体字、`zh-CN` は簡体字として扱われます。広東語の音声には `yue` と書いてください） |
| `nb`、`nn` | ノルウェー語のブークモール（Bokmål）またはニーノシュク（Nynorsk） |

言語だけのコードを書くと、そのすべてが対象になります。たとえば `es` はラテンアメリカ系とカスティーリャ系の両方を取得し、`zh` は広東語と北京語の両方、`no` はブークモールとニーノシュクの両方を取得します。zurg が読めない地域指定（`es-latam` など）を言語の後ろに付けると、起動時にエラーになります。

zurg は、どの地域のトラックかをストリームではなくトラックのタイトルから判断します。ストリームには、zurg が読める形で地域情報が入っていないためです。判断に使うタイトルは、"Latino"、"Spanish (Latin American)"、"Castellano"、"French (Canada)"、"VFQ"、"Portuguese (Brazilian)"、"Chinese (Cantonese)"、"繁体中字" などです。タイトルに地域情報がないトラックが、そのせいで除外されることはありません。タイトルに情報がない場合は、リリース名で判断します。`Dual-Lat`、`[Castellano]`、`MULTi.VFQ`、`VF2`、`PT-BR`、`[ES-LA]` などがリリース名に含まれていれば、それを使います。リリース名だけで何かが除外されることはなく、トラックのタイトルがリリース名より優先されます。`[es-419, es]` の場合、zurg は次の順番で選びます。(1) タイトルが Latino のトラック、(2) タイトルがなく、リリース名が Latino のトラック、(3) タイトルがないトラック、(4) タイトルがなく、リリース名が Castellano のトラック、(5) タイトルが Castellano のトラック。ラテンアメリカ系の家庭向けには、次のように設定します。

```yaml
acquisition:
  audio_languages: [es-419, es]  # Latino first, then Castilian
  subtitle_languages: [es]
  audio_or_subtitles: true       # or any audio with Spanish subtitles
```

`audio_or_subtitles: true` を指定すると、音声と字幕の両方ではなく、どちらか一方を持つリリースを取得します。音声があるリリースは、字幕だけのリリースより先に来ます。

`original` は、TMDB に記録されている作品の制作言語を意味します。たとえば Parasite なら韓国語、Anatomy of a Fall ならフランス語です。zurg はこの情報を DMM に問い合わせるため、`dmm_api_key` が必要です。キーがない場合、`original` は何も条件を付けません。

### リリースの評価方法 {#how-a-release-is-judged}

- **追加される前。** DMM は zurg が解析したすべてのリリースの ffprobe データを保持しています。`dmm_api_key` を設定しておくと、zurg は torrent の検索結果すべてについてこのデータを 1 回の呼び出しで読み取ります。指定の言語がストリームに含まれない torrent は追加されません。含まれているものは、内容が何もわからない torrent より優先されます。2026-10-25 に 5 本の映画で測定したところ、DMM は Real-Debrid がキャッシュしていた torrent のおよそ 3 分の 1 について、このデータを持っていました。
- **取得後。** torrent でも Usenet でも、取得したものはライブラリに入った後に一度プローブされます。DMM がデータを持っている場合はそれを使い、なければ ffprobe を使います。指定の言語がストリームに含まれないものは、dead post と同じように脇に置かれます。デビッドアカウントから削除されるか、ウォッチディレクトリから取り出され、次の候補がすぐに試されます。ダッシュボードには理由が表示されます。たとえば「英語の音声がなく、フランス語のみです」のように表示されます。
- **アップグレードでも言語は維持されます。** DMM の wanted list で映画がより高い解像度にアップグレードされる場合、新しいリリースには、置き換えられるコピーと同等以上に優先度の高い言語が含まれている必要があります。ラテンアメリカ系スペイン語の 1080p のコピーを、カスティーリャ語の 2160p のコピーと交換することはありません。
- **不明なものは採用されます。** 読み取れなかったという理由でリリースが拒否されることは決してありません。対象は、タグのない音声トラック、`und` または `mul` とタグ付けされたトラック、アーカイブ経由でしか到達できないリリース、1 分以内にプローブできなかったリリースなどです。zurg は、そのまま採用したことをログに記録します。

解説音声や音声解説トラックは、映画の音声としては扱いません。また、解説字幕は映画の字幕としては扱いません。タイトルにしか解説であることが書かれていないものも含みます。たとえば、Parasite の "Commentary by Bong Joon Ho" がそうです。タイトルに forced（forzados、forcés）、signs、songs と書かれた字幕トラックも、字幕としては扱いません。forced フラグだけでは、トラックは除外されません。外国映画のリミックスでは、英語字幕をすべて forced としてマークし、プレーヤーで表示されるようにしていることがあるためです。

判定の対象になるのは、リリースのメインの動画ファイルだけです。対象は、最も長いファイルの 5 分の 1 以上の長さのものです。特典映像は、映画本編より吹き替えの数が少ないことがよくあります。シーズンパックでは、すべてのエピソードに指定の言語が必要です。

言語が理由で脇に置かれたリリースは、dead post と同じく 30 日間そのままになります。その間に言語設定を変更しても、この扱いは変わりません。

## DMM の希望リスト {#dmm-wanted-list}

DMM のスポンサーは、debridmediamanager.com のページにある **Want** ボタンで映画や番組を wanted リストに追加できます。リストは `/wanted` に表示されます。`dmm_api_key` を設定すると、zurg は毎回このリストを読み込みます。ほかに書くことはありません。マウントも不要で、Sonarr や Radarr も関係しません。ソースの名前は `dmm-wanted` で、60 秒ごとに確認されます。

- **取得されるもの。** 映画は 1 回取得され、その後はアップグレード（下記）があれば取得されます。`quality` がリストの場合は、解像度ごとにコピーが取得されます（下記）。番組は、ほしいとしたシーズンの放送済みエピソードを取得します。番組全体がほしい場合は、すべてのシーズンを取得します。放送中の新しいエピソードも取得されます。
  DMM は各タイトルの IMDb、TMDB、TVDB の ID、公開年、そして番組の場合は放送済みのエピソードを送ります。エピソード番号は TMDB の番号づけに従います。スペシャルは一覧に含まれません。放送中のシーズンは、まだパックがないので個別のエピソードとして取得されます。
- **検索のタイミング。** 映画は、家庭向けに公開されたときから検索されます。DMM は、TMDB が把握している最も早いデジタル、フィジカル、または TV の公開日を送ります。zurg はその日まで待ち、その後は 6 時間のあいだ 2 分ごとに検索します。そして 2 日後までは 10 分ごとに検索します。これは[新しいエピソード](#sonarr-behavior)と同じ扱いです。映画館での公開日は使いません。WEB-DL はデジタル公開日に投稿されるためです。番組の最新エピソードも同じ方法で日付が決まります。DMM が把握していれば、放送された時刻から計算されます。日付のないタイトルは通常の再試行を続けます。再試行の間隔は最大で 1 週間です。リストのものが[保留](#persistence-and-recovery)になることはありません。次の試行を待っている映画は、DMM がその映画の名前を含む新しい Usenet 投稿を見つけたとき、次の確認で検索されます。
- **取得先。** ほかのソースと同じです。Newznab インデクサーの NZB は、このインスタンスの Usenet バックエンドに送られます。Torznab インデクサーのトーレントは、すでにキャッシュされているデブリッドアカウントに送られます。どちらを優先するかは `prefer` で決まります。`quality`、`max_size_gb`（シーズンパックの場合はエピソードごと）、`exclude_words`、[言語](#choosing-by-audio-and-subtitle-language)が適用されます。`max_season_size_gb` を書いている場合はそれも適用されます。
- **インデクサー。** `acquisition:`、`watchlist:`、`stremio:` のどこにもインデクサーを書いていない場合、このキーは DMM 自身のインデクサーも検索します。DMM の Usenet インデクサーと、Real-Debrid または AllDebrid にあることがわかっているトーレント（`/api/torznab/cached`）が対象です。インデクサーを書くと、どちらも置き換えられます。
- **完了の通知。** 映画の取得が確認されると、zurg は DMM に通知します。そして、アップグレードや別のコピーを待つ場合（下記）を除き、映画は zurg が読むリストから外れます。いつ外れたかは `/wanted` で確認できます。番組はリストに残り、リストから削除するまで追跡が続きます。タイトルを削除すると、そのタイトルの作業は止まります。
- **アップグレード。** リリース名に示された解像度が、`quality` が目指す解像度より低い映画は、リストに残ります。目指す解像度は、`best` と `4k` は 2160p、`1080p` は 1080p、`720p` は 720p です。zurg は、手元のコピーより高い解像度を示すリリースが出ると、それを取得します。手元に目指す解像度のコピーができるまで続きます。新しいコピーが確認を通過すると、古いコピーは削除されます。ただし、zurg が取得したものに限ります。削除は 2026-10-30 の夜間処理から行われます。対象は、zurg が追加したアカウントのトーレントと、監視ディレクトリの NZB です。もともと持っていたコピーは残ります。`__magic__` 以下に配置されたものがあるコピーも残ります。たとえば Radarr のインポートでそうなります。リリース名に解像度が書かれていないリリースはアップグレードされません。`quality: smallest` を指定すると、アップグレードは一切行われません。より良いリリースが出るまで、映画はおよそ週に 1 回検索されます。この映画が[保留](#persistence-and-recovery)になることはありません。デフォルトで有効です。`acquisition:` ブロックに `upgrades: false` と書くと無効になります。
- **複数の解像度のコピー。** `quality` を `[1080p, 4k]` のようにリストで書くと、映画ごとに、リストに含まれる各解像度のコピーが保持されます。詳しくは[複数の解像度のコピー](#a-copy-at-each-of-several-resolutions)をご覧ください。
- **取得用のアカウントがない場合。** `nzb` プロバイダーも、`torbox_nzb` アカウント（TorBox Pro）も、トーレントを扱えるデブリッドアカウントもないインスタンスでは、リストは読み込まれません。

**同じキーを使う 2 つの zurg は、どちらもすべてのタイトルを取得します。** どちらも同じリストを読み込みます。そのため、wanted リストは片方だけで動かし、もう片方では無効にしてください。

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

スポンサーシップが切れたり、キーがリセットされたりすると、リストは止まります。zurg は DMM が `dmm_api_key` を拒否したという警告をログに出し、1 時間後にもう一度確認します。新しいキーを設定した場合は、すぐに確認します。それまでに取得済みのものは、ライブラリに残ります。

### 複数の解像度ごとのコピー {#a-copy-at-each-of-several-resolutions}

`quality` をリストで書くと、ウォントリストにある各映画をリスト内の解像度ごとに1つずつ保持できます。たとえば1080pのテレビで4Kファイルをトランスコードせずに再生できるようになります:

```yaml
acquisition:
  quality: [1080p, 4k]
```

各コピーは、自分の解像度以下で最も良いリリースを取得し、それより高いものは決して取得しません。1080pのコピーは2160pのリリースを取得せず、名前に解像度が書かれていないリリースも取得しません。それが何であるかわからないからです。4Kのコピーは、解像度が書かれたリリースを取得できない場合にのみ、そのようなリリースを取得し、そのまま保持します。解像度が書かれていないリリースは決してアップグレードされないからです。各コピーは個別にアップグレードされ、上限は自分の解像度までです。2つのコピーが同じリリースを取得する場合は、1つのコピーを共有し、どちらもそれを保持しなくなったときにのみ削除されます:

| 出たリリース | 1080pのコピー | 4Kのコピー | ライブラリ内 |
|---|---|---|---|
| 720p | 720p | 同じ720p | 720p |
| + 1080p | 1080pにアップグレード | 1080pにアップグレード | 1080p |
| + 2160p | そのまま | 2160pにアップグレード | 1080pと2160p |

2160pでしか出ていない映画は、4Kのコピーがすぐに取得されます。1080p以下のリリースが出たときに、1080pのコピーも取得されます。それまでは約1週間ごとに検索され、保留にされることはありません。映画は、すべてのコピーが、それ以上の要望がないリリースを保持した時点で、zurgが読み込むリストから外れます。

- **リストに書けるもの。** `4k`(または`2160p`)、`1080p`、`720p`のうち2つ以上を、それぞれ1回ずつ、順番と大文字小文字を問わず書きます。それ以外を書くと、zurgは起動を拒否し、`acquisition.quality lists resolutions, each once: 4k, 1080p or 720p`と表示します。要素が1つだけのリストは、その1つの値として読まれます。そのため`[1080p]`は`quality: 1080p`と同じで、コピーは1つだけになります。ここは`4k`と書いてください。`[2160p]`は拒否されます。
- **`acquisition:` ブロックの中だけ。** `watchlist:` の下の`quality`は1つの値です。そこにリストを書くと、zurgは起動しなくなります。設定ページの画質設定は`watchlist.quality`だけを編集し、`acquisition.quality`が書かれている間は何も変えません。
- **DMMのウォントリストにある映画だけ。** そこにあるシリーズや、それ以外のすべてのソースは、引き続きコピーを1つだけ取得します。その場合は、`quality`にリストされた中で最も高い解像度だけを書いたものとして扱われます。`[1080p, 4k]`は彼らにとって`quality: 4k`として、`[720p, 1080p]`は`quality: 1080p`として動作します。後者は1080pのリリースが出ていない場合、2160pのリリースを取得することもあります。
- **`upgrades: false` の場合**、各コピーは最初に取得したリリースをそのまま保持します。720pしか出ていない間は、両方のコピーがその720pのまま固定されます。
- **リストを書く前に取得した映画**は、解像度ごとにコピーが改めて取得されます。最良のリリースがすでにライブラリにあるコピーは、それをそのまま使います。zurgは以前取得したコピーを削除することはありません。新しいコピーが置き換えるなら、自分で削除してください。
- **1つの値に戻した場合**、コピーはそのまま残ります。
- **`/wanted` は、最初のコピーが入ると映画を取得済みと表示**し、zurgが取得した最初のリリースを示します。どの解像度がまだ待機中かは表示されません。リストを書く前に取得された映画は、そのときに待っていた解像度について"waiting for"と表示され続けることがあります。

### YouTube から映画をストリーミングする {#streaming-a-film-from-youtube}

Many wanted films no indexer carries are on YouTube, uploaded whole by the studio that
made them. With `acquisition.youtube` set, zurg streams such a film from that upload
instead of leaving it unfetched. Nothing is downloaded.

```yaml
acquisition:
  youtube:
    cookies: /home/you/zurg/youtube-cookies.txt   # required: a signed-in account's cookies (Netscape format)
    # ytdlp_binary: yt-dlp                        # default; the standalone build
    # js_runtime: node                            # default; yt-dlp needs one to read YouTube's player
    # channels: [UC1D36wr10qyCfisHulZ5G8Q]       # the channel ids uploads are taken from
    # searches_per_hour: 20                       # default; films looked for on YouTube in an hour
```

- **When.** Only for a film on the DMM wanted list, and only when nothing the indexers
  return can be taken: no release passes `quality`, `max_size_gb`, `exclude_words` and
  the title and year checks, or every one was found gone, with every indexer answering.
  Never for a show or an upgrade, nor with `audio_languages` or `subtitle_languages`
  set, since an upload's languages cannot be read. Only the wanted list takes a stream:
  a film the Plex watchlist also wants is not settled for it by one, since Plex cannot
  play it, and the watchlist keeps looking for a release.
- **How often.** At most `searches_per_hour` films are looked for in an hour (20 by
  default: 1,820 films take four days), one at a time. A film YouTube has nothing for is
  asked about again a day later, restarts included.
- **Which upload.** zurg searches YouTube for the title and year, and for the original
  title when DMM sends one, and takes an upload only when all of these hold: it is on
  one of `channels`; it runs at least 90% of the film's runtime, or an hour when DMM does
  not know the runtime; its title begins with the film's title (`'Separada' FULL MOVIE |
  ...`), states no other year, and is no trailer, teaser, clip or `Part N`. Of those it
  takes the longest, then the most watched, and checks that YouTube streams it with
  picture and sound together.
- **Channels.** The default list is the Philippine studios' own channels: ABS-CBN Star
  Cinema, Regal Entertainment, VIVA Films, SOLAR WATCH NOW, OctoArts Films, CineMo and
  Cinema One. Of 100 random unfetched films on one wanted list (2026-10-31), 65 had a
  full-length upload and 33 were on these channels; the rest were re-uploads (every
  Disney one) and, for new releases, scams titled "full movie". Writing `channels`
  replaces the list. A channel's id is the `UC...` part of its address, or what
  `yt-dlp --print channel_id <a video's page>` prints.
- **What you get.** The film is named `Title.Year.1080p.YouTube.WEB-DL` and DMM is told
  it was fetched (`youtube:<video id>`). rex gets it as an HLS item in your movies
  library, read through zurg. Jellyfin and Kodi get
  `__magic__/__movies__/Title (Year) {tmdb-N}/Title (Year) {tmdb-N}.strm`, with `__magic__`
  on. The address in the `.strm` is zurg's own, from [`base_url`](../reference/config.md), and needs
  no login. Either address is the stream's playlist served by zurg, every segment in it
  an address on zurg too, which zurg fetches from YouTube itself. zurg resolves the
  stream with yt-dlp and keeps it until an hour before it expires. A segment's address
  is good for a day; a player that comes back later reads the playlist again.
- **Upgrades.** A streamed film stays on the wanted list while `upgrades` is on, and any
  release of it that comes out replaces the stream, whatever its resolution: the stream,
  its `.strm` and its rex item go once the release has passed its check.

Limits:

- **Plex cannot play it.** It is no file on the mount. Use rex, Jellyfin or Kodi.
- **Cookies are required.** Without a signed-in account's cookies YouTube offers an
  address that fetches much only video and audio apart, or nothing, so zurg starts with
  the fallback off and says why. Export them from a browser signed in to YouTube, ideally
  on the same network. Signing out in that browser ends them.
- **Every byte passes through zurg.** Nothing is redirected to YouTube: rex sends its
  source's login with every request its transcoder makes, redirected ones included, and
  YouTube ties a stream to the address that resolved it. So any player that reaches
  zurg plays it, and zurg carries the film's traffic.

## Seerr の動作 {#seerr-behavior}

アダプターは seerr-team/seerr の [リクエストのルート](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/routes/request.ts)、[ステータスの定義](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/constants/media.ts)、[API の仕様](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/seerr-api.yml) に沿って動きます。

- `X-Api-Key` を使って、承認済みリクエストのすべてのページをポーリングします。ページの取得に失敗した場合は、前回のキューをそのまま残し、そのソースの作業を一時停止します。
- 取得を始める前に、承認状態を再確認します。Pending、declined、failed、completed、removed、すでに available のリクエストでは、取得を始めません。
- ID は Seerr を通じて解決します。TV の取得は、承認されて要求されたシーズンと、既知の放送済みエピソードに限定されます。一部だけ揃ったシーズンは pending のままになります。
- 4K と非 4K は別々に扱います。1080p のリリースでは 4K のリクエストを満たせません。
- 取得に成功した後も、30 分ごとに未完了のリクエストを再確認して、要求されたシーズンで新しく放送されたエピソードを探します。告知されていないエピソードは、Seerr のメタデータに現れて初めて作業対象になります。
- パックは、既知のエピソードがすべて放送された後に優先します。放送中のシーズンでは、個別のエピソードを使います。スペシャル（シーズン 0）はサポート対象外です。シーズン 0 を含むリクエストが承認されていても取得は行われず、保留扱いになるまで失敗として扱われます。
- リクエストのステータスや available の状態は書き換えません。実際に利用可能かどうかは、Seerr のメディアサーバーのスキャンが判断し、リクエストした人に通知されます。NZB を保存しても、インデックスされて再生できる保証はありません。そのため、エンジンはシーズンを取得済みとして数える前に、その点を確認します。

Seerr のライブラリスキャンに、このインスタンスが提供するライブラリを含めるように設定してください。Sonarr/Radarr がすでに同じリクエストを取得している場合は、このアダプターを有効にする前に、その重複するワークフローを無効にしてください。アダプターは *arr サーバーを再現したり、Seerr のサービス構成を変更したりはしません。ポーリングが再起動後の復旧を担うため、Webhook は必要ありません。

## Radarr の動作 {#radarr-behavior}

Radarrはリストを管理し、ライブラリを所有します。検索とダウンロードを行うのはzurgです。Radarrが検索や取得を行うことはありません。zurgはRadarrが求めている内容を読み取り、自分のインデクサーから適切なリリースを選びます。次に、ニュースサーバー（`torbox_nzb`アカウントの場合はTorBoxのfetch）またはそのリリースを持っているdebridアカウントで内容を確認します。そして、動画を`__magic__`内にある映画のフォルダーに配置し、その映画だけを再スキャンするようRadarrに依頼します。コピーは行われません。動画はzurgのライブラリ内のファイルで、Radarrはそれを自分のフォルダー内に見ることになります。

### Radarr のセットアップ {#setting-up-radarr}

1. **Ordner-Root innerhalb von `__magic__`, eine Ebene tiefer.** Zum Beispiel
   `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` unter macOS,
   `Z:\__magic__\movies` unter Windows). Nicht `__magic__` selbst und auch nicht
   `__magic__/__all__`, denn dort sind alle Releases der Bibliothek aufgelistet. Ein Film,
   dessen Ordner woanders liegt, wird übersprungen, und in zurgs Log gibt es dazu eine Warnung.
   Unter Windows sieht Radarr `Z:` nur, wenn es in derselben Anmeldesitzung wie zurg läuft,
   also nicht als Windows-Dienst. Siehe dazu
   [die Sitzungsregeln](../setup/windows.md#keeping-it-running-the-session-rules).
2. **Importlisten mit Suche beim Hinzufügen aus.** Füge Filme hinzu, wie du willst (von Hand, über Listen,
   oder Seerr mit Radarr als Ziel). Lass **Search for Movie** beim Hinzufügen aus,
   denn die Suche übernimmt zurg.
3. **Keine Indexer und kein Download-Client nötig.** Wenn Radarr welche hat, kann es
   zusätzlich zu zurg suchen. Schalte deshalb die automatische Suche bei seinen Indexern aus
   (oder entferne sie) für die Filme, um die sich zurg kümmert.
4. **`library_path` ist der Pfad, unter dem Radarr `__magic__` sieht.** Wenn Radarr auf demselben Rechner
   wie zurg läuft und den Mount dort sieht, wo zurg ihn einhängt, lass die Option weg:
   Standardmäßig ist es zurgs `mount_path` plus `/__magic__`. Wenn Radarr in einem Container
   läuft, der zurg an einem anderen Ort einhängt, setze den Pfad dorthin, zum Beispiel
   `/data/zurg/__magic__`. Ein Film unter
   `/data/zurg/__magic__/movies/Heat (1995)` wird dann in
   `movies/Heat (1995)` innerhalb von zurgs `__magic__` abgelegt. Windows-Pfade wie
   `Z:\__magic__` funktionieren ebenfalls. Ein Radarr-Container wird nur auf einem Linux-Host
   unterstützt: Docker Desktop unter macOS und Windows läuft in einer VM, und zurgs Mount
   dorthin weiterzureichen ist nicht getestet. Betreibe Radarr dort daher nativ.

   Wenn Radarr außerdem Downloads über zurgs [SABnzbd](sonarr-radarr.md)- oder
   [qBittorrent](sonarr-radarr-torrents.md)-Endpunkt entgegennimmt, muss es deren Download-Ordner
   unter `library_path/__all__` sehen, und zwar über denselben Volume wie seine Root-Ordner. Sonst ist jeder Import daraus
   eine Kopie der ganzen Datei. zurg fragt Radarr, wo es beide sieht, und meldet das auf der
   Acquisition-Seite, im Log und in `zurg doctor`, falls sie sich keinen Mount teilen können. Siehe
   [Ein Volume für den Download-Ordner und die Root-Ordner](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

### zurg が Radarr に求めるもの {#what-zurg-asks-radarr-for}

各ポーリングでは Radarr の映画リストを読み込み、次の条件をすべて満たす映画に対して処理を行います。映画が **monitored** になっていて、最低利用可能性（minimum availability）の時点で **available** になっており、かつファイルがないか、クオリティプロファイルでアップグレードが許可されている場合にカットオフより低いファイルを持っていることです。カットオフ未満とは、Radarr が数える「カットオフ品質未満」または「カットオフのカスタムフォーマットスコア未満」を指します。数か月先の日付の映画など、まだ公開されていない映画は、Radarr が available と判断するまで待機します。

zurg が検査しようとしている候補リリースはそれぞれ、Radarr 自身のパーサー（`/api/v3/parse`）に渡され、その映画のクオリティプロファイルで判定されます。つまり zurg が受け入れたものは、Radarr も受け入れるものです。

- **作品が一致していること。** Radarr はタイトルを同じ映画に一致させる必要があります。インデクサーの ID 検索は別の映画も返すことがあります（*Psycho* を検索すると *Ed Gein: The Real Psycho* が返ってきた例があります）。どの映画にも一致しないタイトルは拒否されます。タイトルに含まれる年が映画の年と1年以上ずれている場合も拒否されます。
- **プロファイルの許可リストと最低スコアが最初に適用されます。** 解析された品質はプロファイルで許可されている必要があります。カスタムフォーマットスコアはプロファイルの最低スコアに達している必要があります。サイズは映画のランタイムに対して **Settings > Quality** の品質ごとの上限内に収まる必要があります。
- **リリースはプロファイルの言語である必要があります。** **Original**（デフォルト）の場合、Radarr はタイトルを映画の原語として読み取る必要があるため、フランス語版のみの英語映画のリリースは拒否されます。言語が書かれていないタイトルは原語とみなされます。言語名が指定されている場合はその言語を求め、**Any** はすべての言語を受け入れます。これは初回ファイルでもアップグレードでも同じです。
- **アップグレードは後からカットオフを目指します。** ファイルのない映画は、上記のチェックを通過するどのリリースでも取得します。カットオフ未満のファイルがある場合は、より良いリリースのみ取得されます。ファイルがカットオフ品質未満のときは、プロファイルの順序でより上位の品質を、ファイルがカットオフスコア未満のときは、アップグレードステップ以上高いカスタムフォーマットスコアを持つリリースです。低い品質のリリースは決して取得されません。同じ品質の PROPER と REPACK はアップグレードとして扱われません。

プロファイルは、zurg が取得しようとしているリリースに対して許可リストとして適用されます。対象の映画であること、許可された品質であること、最低スコア、言語、サイズの上限を満たす必要があります。既定では、プロファイルの優先順位は許可されたリリースから選ぶ際には使われません。zurg は許可されたリリースのうち、確認が最も安いものを最初に取得します。単一ファイルとして投稿されることが多い Web リリース（WEB-DL、WEBRip）を Blu-ray より先に、その他のものより先に試します。プロファイルがより良い品質を優先していて、かつアップグレードを許可している場合、届いたファイルはカットオフ未満と見なされます。その映画が何らかのファイルを持つと、zurg のアップグレードパスがより良いリリースを探します。最初のファイルは素早く届き、プロファイルの順序はアップグレードで反映されます。最初の取得もプロファイルの順序に従わせるには `best_first: true` を設定します。詳しくは [プロファイルの最優先を最初に取得する](#taking-the-profiles-best-first) を参照してください。

IMDb または TMDB の ID による検索で結果が一切返ってこない場合、zurg は Radarr と同じように、タイトルと年で再検索します。多くの投稿、特に小規模なドキュメンタリーは ID がまったく付けられずにインデックスされています。各検索結果が対象の映画かどうかは Radarr のパーサーが判断するため、同名の別作品は他の誤一致と同じく拒否されます。

Radarr への問い合わせは、zurg がリリースを検査しようとするときだけ、一度に1件ずつ行われます。そのため、単一ファイルのリリースがある映画では、問い合わせは1〜3回で済みます。直接投稿が保存された後は、それ以上問い合わせません。プロファイルで許可されていない解像度がタイトルに含まれている場合（例：HD-1080p のプロファイルに対する 2160p のリリース）は、Radarr に問い合わせることなく拒否します。解像度が含まれていないタイトル、または複数の解像度が含まれるタイトルは、常に Radarr に問い合わせます。プロファイルが名前に解像度を含まない品質（SDTV、DVD、Unknown、Raw-HD、BR-DISK）を許可している場合は、すべてのタイトルが Radarr に問い合わせられます。zurg が1台の Radarr に同時に送る呼び出しは最大8件です。

Radarr に接続できない場合は、何も判断されません。映画は次のポーリングまで待機し、Radarr が応答しなかったという理由でリリースが除外されることはありません。

### ファイルの配置 {#placing-the-file}

リリースがチェックされると、zurg はそのビデオを Radarr がインポートしたときと同じように、映画のフォルダーに配置します。配置は `__magic__` 内での移動で行われ、コピーやダウンロードは行いません。

- **配置されるのは最も大きいビデオです。** リリース内の `.mkv`、`.mp4`、`.m4v`、`.avi`、`.mov`、`.ts` ファイルのうち最大のものが対象になります。アーカイブの中身も含めて数えます。1 つのアーカイブで提供されているリリースは、そのアーカイブの中身がリリースの中身になります。サンプルや `.nfo` を含むシーン系の投稿のように、RAR セットの横に単体ファイルが付いている場合は、リリースのフォルダーとして参照され、その中のビデオがそこから配置されます。サンプル、特典映像、字幕、`.nfo` ファイルは `__magic__/__all__` に残ります。ファイルは、リリース内での名前をそのまま使います。ただし、その名前から映画の内容がわからない場合（年もタイトルの単語も含まれていない場合）は、リリースの名前に変わります。そうすることで Radarr が画質を読み取れるようになります。
- **サンプルは決して配置されません。** サンプルと判断されるビデオ（`sample-…`、`….sample.mkv`、`Sample/` フォルダー内のもの）は、どれだけ大きくても除外されます。ただし、リリース名自体にも sample と書かれている場合は除外しません。タイトルに単語だけ含まれる映画（`Sample.Size.2019`、`Death.Proof.2007`）も、リリース名にその単語が入っています。この場合は、ビデオがリリース全体の 5 分の 1 未満のときだけ除外されます。唯一のビデオがサンプルであるリリース（サンプルだけの投稿も含む）は取り分けられ、次の候補が試されます。これにより、アップグレードで 1 分のクリップに差し替えられることはありません。
- **読み取れないファイルは、移動される前に拒否されます。** これは、マウント経由で Sonarr や Radarr のインポートが受けるのと同じチェックです。ニュースサーバーにもう記事が残っていないリリース、またはアーカイブが決して開けないリリースは、無効な投稿と同じように取り分けられ、次の候補が試されます。今は読み取れないリリース（たとえばクールダウン中のアカウントにあるもの）は、後でもう一度試されます。
- **Radarr は 1 本の映画につきファイルを 1 つだけ保持するため、アップグレードでは古いファイルが置き換えられます。** 新しいビデオがフォルダーに入ると、zurg のライブラリがそこに置いた他のビデオはすべてフォルダーから非表示になります。非表示は、マウント経由で削除したときと同じく tombstone（削除マーク）が付くことを意味します。古いリリースは `__all__` とそのアカウントに残ります。自分でフォルダーに置いた実ファイルはそのまま残ります。古いファイルは新しいファイルの配置後に非表示になるので、配置が失敗した場合は映画が元のファイルを保持したままになります。
- **その後 Radarr が再スキャンします。** zurg はどのフォルダーが変わったかをマウントに伝えます。これにより、マウントがまだ空だと記憶しているフォルダーを再スキャンで読んでしまうことがなくなります。そのうえで、zurg は Radarr にその映画 1 本だけを再スキャンするよう依頼します。

Radarr のソースには `__magic__`（`magic.enabled`）が必要です。これがないとソースは起動せず、その旨がログと取得ページに表示されます。

### Radarr の表示内容 {#what-radarr-shows}

**Activity** は空のままです。キューのエントリも grab や import のイベントもありません。Radarr は何も grab していないからです。zurg が求める再スキャンの後に映画にファイルができるだけで、その品質やカスタムフォーマットは、そのファイルを Radarr が読み取った結果です。zurg のログには完了した映画ごとに記録が残ります。

`only_new_items` と `remove_after_grab` は Radarr のソースでは何もしません。Radarr で監視中の映画は、Seerr の承認済みリクエストと同じく作業対象です。映画が対象から外れるタイミングは Radarr が決めます。ソースの `name` は変えないでください。保存されたキューを識別するためのものなので、URL とキーは自由に変えて構いません。

## Sonarr の動作 {#sonarr-behavior}

Sonarrは、Radarrと同じ仕組みで動きます。Sonarrはリストを管理し、ライブラリを所有します。
zurgが検索とダウンロードを担当します。Sonarrが検索することも、grabすることもありません。zurgはSonarrが不足しているエピソードを読み取り、独自のindexersからリリースを1つ選びます。そのリリースは、ニュースサーバー（`torbox_nzb`アカウントでのTorBoxのfetch）またはそれを保持しているdebridアカウントで確認されます。そして各エピソードの動画を、`__magic__`内のシリーズのシーズンフォルダーに配置します。その後、Sonarrにそのシリーズだけを再スキャンするよう依頼します。コピーは一切行われません。

### Sonarr のセットアップ {#setting-up-sonarr}

1. **`__magic__` の直下、1 階層目にあるルートフォルダー。** 例えば
   `/mnt/zurg/__magic__/tv`（macOS では `/Volumes/Zurg/__magic__/tv`、Windows では `Z:\__magic__\tv`）。フォルダーがこれ以外の場所にあるシリーズは、zurg のログに警告が 1 件出て、スキップされます。
   Windows では、Radarr と同じく、Sonarr も zurg と同じログオンセッションで実行する必要があります。

2. **Search on add をオフにする。** シリーズは好きな方法で追加してください。**Start search for missing episodes** はオフのままにしてください。検索は zurg が行うためです。

3. **インデクサーとダウンロードクライアントは不要です。** Sonarr に設定がある場合、zurg と並行して取得してしまうことがあります。そのため、zurg が管理するシリーズについては、インデクサーの自動検索をオフにしてください。

4. **`library_path` は、Sonarr から見た `__magic__` の場所です。** Radarr の場合とまったく同じように動作します。Sonarr が zurg のダウンロードフォルダーとルートフォルダーを同じボリューム経由で参照できるかの確認も含まれます。Sonarr が zurg と同じマウントポイントを見ている場合は、省略してください。

### zurg が Sonarr に求めるもの {#what-zurg-asks-sonarr-for}

毎回のポーリングで、Sonarr の missing episodes を読み込みます。これは、監視対象のシリーズの監視対象エピソードのうち、放送済みでファイルがないものです。zurg はそれらをシーズンごとにまとめ、各シーズンを一つの作業単位として扱います。

- **放送が終わったシーズン全体は、パックで届くことがあります。** シーズンの全エピソードが欠落していて、まだ放送予定のものがない場合は、まずシーズンパックを試します。そうでなければ、そのシーズンの欠落エピソードを、シーズンの検索結果から一つずつ取得します。一部のファイルがすでにあるシーズンでは、パックは決して使いません。そうしないと、それらのエピソードがフォルダーに二つ目のコピーとして入ってしまうためです。
- **新しいエピソードは、新しい作業です。** 来週のエピソードが放送されると、そのエピソードを含めてシーズンが再び一覧に載ります。zurg は、すでに持っているエピソードについては再検索しません。
- **新しいエピソードは数分以内に再検索されます。** リリースは通常、放送後一時間以内に投稿されるため、放送直後に検索しても何も見つからないことがよくあります。エピソードの放送から六時間は二分ごとに再試行し、その後は二日後まで十分ごとに再試行します。それ以降は、他の場合と同じように間隔を空けていきます（[persistence and recovery](#persistence-and-recovery) を参照）。デビッドアカウントの場合は、zurg はアカウントが持っているものだけを追加するため、そのリリースがすでにアカウントにキャッシュされている必要があります。
- **削除されたエピソードは、再び探されます。** zurg がすでに取得したエピソードを Sonarr が一覧に載せた場合、zurg はシーズンのフォルダーを確認します。そのエピソードの動画ファイルがもうなければ、再検索されます。ある場合は、Sonarr がまだ再スキャンしていないだけなので、何も検索されません。
- **アップグレードはファイル単位で判断されます。** エピソードのファイルが、品質プロファイルのカットオフを下回っていて、かつプロファイルがアップグレードを許可している場合、それはアップグレード対象になります。ここでいう「カットオフを下回る」とは、カットオフの品質を下回ること、またはカットオフのカスタムフォーマットスコアを下回ることを意味します。Sonarr 自身の Cutoff Unmet の一覧は、品質だけを数えます。Sonarr 4.0.20 では、カットオフの品質に一致していても、カットオフスコア 40 に対してスコアが 0 のファイルは、その一覧に載りません。zurg は、Sonarr 自身のアップグレードルールと同じように、両方を数えます。二つのエピソードを含むファイルは、両方のエピソードに対して一回のアップグレードとして扱われます。
- **デイリー番組のエピソードは、放送日で探されます。** デイリー番組のリリースは、エピソード番号ではなく日付で名前が付けられています（例: `The.Daily.Show.2026.11.03.Min.Jin.Lee...`）。インデクサーはエピソード番号では見つけられないため、欠落している各エピソードについては、シリーズ名と日付による文字列検索も行います（`The Daily Show 2026.11.03`）。Sonarr のパーサーは、その日付を元のエピソード（S31E124）に変換します。これは、シーズン番号で付けられたタイトルと同じ仕組みです。
- **アニメのエピソードは、番組が数えている番号で探されます。** ファンサブのリリースは、番組の最初のエピソードから番号が振られています（例: `[SubsPlease] Jujutsu Kaisen - 30` は二期の六話目）。そのため、欠落している各エピソードについては、シリーズ名とその番号による文字列検索も行います（`JUJUTSU KAISEN 30`）。また、シーズンの番号範囲にまたがるバッチ（`(25-47)`）は、そのシーズンのパックとして扱います。Sonarr のパーサーは、番号をエピソードに対応付けます。その際、シーズンごとのシーン上の名前（`Jujutsu Kaisen 2nd Season`、`Jujutsu Kaisen S2`）も使うため、どちらの番号で付けられたタイトルでも、正しいエピソードとして判断されます。Sonarr がどのシリーズにも一致させられないリリース（例: Sonarr が知らないシーン名で付けられたもの）は、他と同じく拒否されます。
- **スペシャルはシーズン 0 として扱われます。** Sonarr の監視対象スペシャルも、他のシーズンと同じように一覧に載り、シーズン `00` として要求されます（シーズン `0` で要求すると、インデクサーは別のシーズンを返してしまいます）。一致するのは `S00Exx` と書かれたリリースだけです。タイトルだけで名前が付けられたスペシャルは、Sonarr でも解析されず、何にも一致しません。スペシャルは、Sonarr の **Specials Folder Format** で指定されたフォルダーに配置されます。

各候補リリースは、Sonarr 自身のパーサー（`/api/v3/parse`）に渡され、シリーズの品質プロファイルで判断されます。zurg が受け入れるものは、Sonarr が受け入れたであろうものと同じです。

- **同じシリーズ、同じシーズンでなければなりません。** Sonarr は、タイトルを同じシリーズに一致させる必要があります。Sonarr がどのシリーズにも一致させられないタイトルは拒否されます。ただし、そのシリーズがシーン番号付けを使っておらず、タイトル中の名前で Sonarr のシリーズ検索が最初にこのシリーズを返す場合（例: 外国語のタイトル）は、例外として扱われます。
- **パックはシーズン全体でなければなりません。** 一部のみのパックは拒否されます。`Season 1 E01-E07` のように範囲で書かれたパックは、その範囲がシーズン全体であれば認められます。複数シーズンのパックは、それが指定する各シーズンに対して数えられます（[Packs of several seasons](#packs-of-several-seasons) を参照）。Sonarr は `S01-S05` をシーズン 1 のみとして読み、どこまで続くかは示さないため、zurg はタイトルから範囲を読み取ります。ただし、Sonarr がそれをこのシリーズに一致させ、完全な複数シーズンのパックとして認識している必要があります。サイズは、そのパックが指定するすべてのシーズンの再生時間に対して判断されます。
- **エピソードは、その一話だけでなければなりません。** 二つのエピソードを含むリリースは、単一エピソードとしては拒否されます。
- **プロファイルは Radarr と同じように適用されます。** 品質が許可されている必要があります。カスタムフォーマットのスコアがプロファイルの最低値に達している必要があります。サイズは、リリースに含まれるエピソードの再生時間に対して、**Settings > Quality** での品質の上下限に収まっている必要があります。アップグレードの場合は、Sonarr のルールに従って現在のファイルを上回っている必要があります。Sonarr のプロファイルには言語設定がないため、言語は Sonarr と同じく、カスタムフォーマットのスコアを通じてのみ評価されます。

許可されたリリースのどれを先に選ぶかは、Radarr とは異なる方法で決まります。パックは、複数のエピソードを個別に取得するよりも一回の取得で済むため、個別のエピソードより先に試されます。Sonarr が許可したリリースの中では、`quality` 設定で最上位にランクされるものを選びます。`best` の場合は、まず最も高い解像度、次に最も大きいサイズが選ばれます。パックの場合は、エピソードあたりの中身で比較されます。そのため、放送が終わったシーズンで 1080p のパックがあれば、同じ検索結果に 2160p ですべてのエピソードがあっても、そのパックで埋められます。その後、アップグレード処理がエピソードごとに置き換えていきます。エピソードあたり `max_size_gb` を超えるパック、または指定した `max_season_size_gb` を超えるパックは、候補になりません。`best_first: true` を設定すると、これらの動作が変わります。詳しくは [Taking the profile's best first](#taking-the-profiles-best-first) を参照してください。

プロファイルに許可された品質がない解像度がタイトルに含まれている場合は、Sonarr に問い合わせることなく拒否されます。zurg は、一つの Sonarr に対して同時に最大八件までリクエストを送ります。Sonarr に接続できない場合、何も判断されません。そのシーズンは次のポーリングまで待機し、どのリリースも除外されることはありません。

### ファイルの配置（複数ファイル） {#placing-the-files}

リリースが確認されたら、各エピソードの動画はシーズンフォルダに入ります。これは、そのシーズンに既にあるファイルが入っているフォルダです。まだファイルがないシーズンでは、Sonarr の **Season Folder Format** で決まったフォルダ（例: `Season 1`）になります。シーズンフォルダを使わない設定のシリーズは、ファイルをシリーズフォルダに入れます。

- **エピソードごとに、それぞれの動画があります。** 動画は、ファイル名にあるエピソード番号で見つけます。リリースのアーカイブの中も対象です。パックには、取得対象になった全エピソードが配置されます。サンプルと `.nfo` ファイルは `__magic__/__all__` に残し、サンプルがエピソードとして配置されることはありません。
- **エピソードが欠けているパックは、何も移動する前に除外されます。** 壊れた投稿と同じ扱いで脇に置かれ、次のパックor単体のエピソードが試されます。
- **ファイル名からエピソードがわからない単体の動画は、リリース内で最も大きい動画が使われます。** 難読化された投稿では、こうなることがよくあります。
- **アニメや日次番組の動画は、シリーズとエピソードの下に配置されます。** 再スキャンはファイル名だけを読み、scene の番号付けは知りません。たとえばシリーズフォルダにある `[Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv` は、S01E08 として取り込まれていました。一方、Sonarr のパーサーは同じタイトルを S02E08 として読みます。そのため、動画は `JUJUTSU KAISEN - S02E08 - [Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv` という名前で配置されます。これで正しく取り込まれ、元のファイル名はエピソード番号の後ろに残るので、Sonarr は画質やグループも読み取れます。通常のシリーズやスペシャルの動画は、もともとエピソードがわかる名前なので、そのままの名前を使います。
- **アップグレードは、そのエピソードの動画だけを置き換えます。** 新しい動画が入ったら、そのエピソードの古い動画はシーズンフォルダから隠されます。同じフォルダにある他のエピソードには触れません。ここでの「隠す」は、Radarr と同じく tombstone（墓石マーカー）にすることです。
- **その後、Sonarr が再スキャンします。** zurg はマウントに、変更があったフォルダを伝え、Sonarr にシリーズの再スキャンを依頼します。
- **1つのエピソードが見つからなくても、他のエピソードは止まりません。** zurg がまだ取得できるリリースがないエピソードがあっても、見つかったエピソードは確認されて配置されます。それらについては、すぐに Sonarr に再スキャンが依頼されます。見つからなかったエピソードは、通常のリトライのスケジュールで改めて探されます。

Sonarr のソースには `__magic__`（`magic.enabled`）が必要です。これがないとソースは起動せず、その旨がログと取得ページに表示されます。

Sonarr の **Activity** は、Radarr と同じく空のままです。zurg が再スキャンを依頼すると、エピソードに単にファイルが付きます。`only_new_items` と `remove_after_grab` は、Sonarr のソースでは何もしません。

## 複数シーズンのパック {#packs-of-several-seasons}

複数のシーズンを含むパック（例: `Game.of.Thrones.S01-08.BDRip.1080p` や `Breaking Bad Season 1-5`）からも、シーズンを取り出せます。インデクサーは、そうしたパックをそれがカバーするすべてのシーズンとして登録します。DMM のフィードでは、Breaking Bad season 3 の検索結果 691 件のうち 72 件が複数シーズンのパックでした。シーズンによっては、そのパックがアカウントにある唯一のコピーということもあります。

- **タイトルでシーズンが分かります。** `S01-S05`、`S01-05`、`[S01-08]`、`S1-9`、`Seasons 1-8`、`Season 1 to 5`、`Season 1 · 2 · 3`、`Stagioni 01-05`、`Temporadas 1-4` はどれも読み取られます。`Complete Series` のようにシーズン番号がないタイトルは取り込まれません。`Season 3 Complete` のように、単一のシーズンを単語としてだけ書いているものも同様です。これらはパックとして読み取られることはありませんでした。
- **配置されるのはそのシーズンだけです。** シーズン 4 のために取り出されたパックでは、シーズン 4 のエピソードだけがシーズンフォルダーに配置されます。他のシーズンのファイルは、ライブラリが一覧に載せている場所のまま残ります。ファイルがそのシーズンのエピソードをすべて含んでいないパックは、タイトルの内容に関係なく、何も移動される前に拒否されます。
- **サイズはエピソード単位で判断されます。** パックのサイズは、そのパックが示すシーズン数で割り、さらにそのシーズンのエピソード数で割ったうえで、`max_size_gb` と照らし合わせられます。これは、同じエンコードをエピソードごとに投稿した場合と同じ扱いです。10 エピソードのシーズンが 8 つある 346 GB のパックは、1 エピソードあたり 4.3 GB です。I Love Lucy のシーズン 2（31 エピソード）のリミックスは 106 GiB で、1 エピソードあたり 3.4 GiB となり、設定した 40 の上限に収まります。ソースにそのシーズンのエピソード一覧がない場合、パックにはエピソード単位の上限は適用されません。`max_season_size_gb` を設定すると、パックが示す各シーズンに対して、さらに上乗せの上限がかかります。デフォルトでは設定されていません。
- **品質が引き続き最優先です。** パックも他のリリースと同じように順位付けされます。順位は、解像度、次にエピソード 1 本あたりの内容の順で、DMM のシーズンページの並び方と同じです。1 シーズンだけの 2160p パックは、8 シーズンの 1080p パックより先に選ばれます。同じ解像度の中では、そのシーズン専用のリミックスが、合計では大きいものの 1 エピソードあたりでは小さい 8 シーズンのパックより先に来ます。
- **同じ番組の他のシーズンも同じパックを使います。** あるシーズンが複数シーズンのパックを取ったら、その番組の他のシーズンは、自分の検索で見つかった同じ解像度のどのパックより前に、まずそのパックを試します。そのパックはすでにアカウントにあるので、追加のコストはかかりません。番組のシーズンが複数シーズンのパックから選んでいる間は、一度に 1 つずつ選びます。そのため、まとめて要求されたシーズン（Sonarr のシリーズで、1 回のポーリングでそのすべてのシーズン）が、それぞれ別のコピーを選んでしまうことはありません。どれかのシーズンが、そうしたパックなしで選び終わったら（アカウントになかった、またはプロファイルでパックが許可されていなかったため）、残りのシーズンは一度に選びます。1 時間後に要求されたシーズンは、改めて検索します。

## 動作を確認する {#watching-it-work}

ダッシュボードの**Acquisition**リンクを開くと、zurg自身のポートで`/acquisition/`が開きます。
各ソースには1行ずつ表示され、そのソースのタイトルのうち完了、実行中、待機中、保留、キュー入りの数が並びます。あわせて、zurgが同時に処理するタイトル数、1つのインデクサーに同時に送る呼び出し数、そして`nzb`アカウントに許可されたニュース接続数も表示されます。
その下には、各ソースごとに表があり、タイトル1件につき1行が並びます。
各行には、状態、実行中のタイトルが今まさに何をしているか（検索、これまでに判定され許可された結果の数、検査中の候補、ニュースサーバーでの確認、配置）、試行回数、選ばれたリリースとソースが付けた画質とスコア、配置先、そして待機中のタイトルが次に試される時刻が表示されます。
試せるリリースが一つも残っていないタイトルには、その理由が表示されます。ソースによる拒否はルールごとに数えられます: `14 refused by the source's own rules
(title mismatch 7, quality 5, size 2)`.
ソースに問い合わせずに解像度を理由に拒否されたリリースは、画質として数えられます。
ページは5秒ごとに自動で更新されます。
同じスナップショットは`/acquisition/status.json`にあります。そこでは、その理由がタイトルの`detail`になります。
どのソースも有効になっていない場合、または取得が設定されているものの一時停止中の場合、ページにその旨と理由が表示されます。

リリースが選ばれた映画ごとに、ログに1行出力されます。時間がどこに使われているかを計測するためです:

```
Acquisition: chose <release> for <title>: results=143 local_refusals=97 radarr_refusals=1 inspected=2 radarr_calls=3 in 4.2s
```

`results`は検索が返した結果数、`local_refusals`はソースに問い合わせずに拒否された結果の数、`radarr_refusals`はソース自身のルールで拒否されたもの、`inspected`は読み込まれたNZBの数、`radarr_calls`はソースへの問い合わせ数（ソースがRadarrの場合は、読み込んだNZBと、そこへ至るまでの拒否分を含む）です。時間は検索の開始時点から計ります。
ソースに問い合わせずに拒否されたリリースは、debugレベルでのみ1件ずつログに記録されます。

（前回の翻訳は却下されました：コードスパンが一致しませんでした。構造をそのまま保ってください。）

## zurg だけをダウンロードクライアントにしている \*arr を確認する {#checking-an-arr-that-only-uses-zurg-as-its-download-client}

A Sonarr or Radarr pointed at zurg's [SABnzbd](sonarr-radarr.md) or
[qBittorrent](sonarr-radarr-torrents.md) endpoint does its own searching, so it doesn't
need a source here. zurg still wants its API key, because three of its settings
decide whether every import is a free rename or a whole release downloaded
from the debrid account and written to zurg's disk: Remove Completed on a
qBittorrent client, the download folder and the root folders on one volume,
and root folders inside `__magic__`. With the key, zurg turns Remove Completed
on by itself (see [qbittorrent.md](sonarr-radarr-torrents.md#what-to-put-in-each-field))
and warns about the other two. See
[One volume for the download folder and the root folders](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

The easiest way to give zurg the key is the banner on the main dashboard,
described below. Or add it as a source that is switched off:

```yaml
acquisition:
  sources:
    - name: sonarr
      type: sonarr
      enabled: false
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
```

A Radarr or Sonarr source with `enabled: false` acquires nothing. zurg never
reads its wanted list and never searches for it. With its `url` and `api_key`
set, and one of the two endpoints on, zurg only reads the \*arr's root folders,
remote path mappings and download clients, at start, every ten minutes and as
soon as the \*arr first calls one of the endpoints. It turns Remove Completed
on for the \*arr's zurg qBittorrent client when it is off, the one change zurg
makes, and reports a layout that makes imports copies. Every source with a URL
and an API key, enabled or not, is checked and corrected the same way. It is
listed on the acquisition page under **Checked, never searched for**, with
what zurg changed. The findings go to the log, and `zurg doctor` shows them as
`imports (<name>)`. `library_path` is not judged for such a source, since
nothing is placed for it. A source added to config.yml by hand is read at
start, so restart zurg after adding one that way.

zurg also notices a Sonarr or Radarr it cannot check. Both send their name in
every request to the endpoints (`Sonarr/4.0.20.3014 (alpine 3.24.1)`), so zurg
records which ones call it and from which address. When one calls and no
source of its kind has a URL and an API key, zurg logs one warning, `zurg
doctor` reports it on its `*arr settings` line, and the main dashboard shows a
banner with a form for its URL and API key. The URL is filled in with a guess:
the address the \*arr calls from, on its default port (8989 for Sonarr, 7878
for Radarr). That address is often a container's own, which zurg may or may
not reach, so change it to whatever URL reaches the \*arr from where zurg
runs. The API key is in the \*arr under Settings, General, Security. zurg
first asks the \*arr for its status with that key, and saves nothing unless it
answers as the app it was named as. It then adds the source above to
config.yml with `enabled: false`, keeping everything else in the file as it
was, and checks it straight away, with no restart. The form shows what zurg
found and changed. The key is written to config.yml and sent to the \*arr, and
nowhere else.

The banner matches by kind, not by address: an \*arr calls zurg from inside
its container, on an address that has nothing to do with the URL zurg reaches
it on, so one Sonarr source with a key silences the banner for every Sonarr.

## 重複するリリースを探す {#finding-duplicate-releases}

アップグレードすると、置き換えられた旧リリースがライブラリに残ります。`magic.allow_delete` がオフの場合、Radarr や Sonarr が古いファイルを削除しても、`__magic__` に隠されるだけです。そのため旧リリースは `__all__` に残ったままで、そのアカウントにも残ります。

複数のインデクサーからグラブした場合や、シーズンパックと単体エピソードが混在している場合も、同じものの複数のリリースが残ります。**Manage > Duplicates**（`/manage/duplicates/`）には、それらが一覧表示されます。どれを Radarr や Sonarr が使っているかも示され、使っていないものを削除できます。自動で何かを削除することは一切ありません。

**使用中のリリースは、名前ではなくパスから判定します。** Radarr と Sonarr が保持するファイルはすべて `__magic__` 配下のパスで管理されています。zurg は、そのパスがどのリリースから来たかを知っています。ファイルをそこへ移動したときに記録しているからです。この画面では、各 \*arr がインポート、監視、カットオフの状態にかかわらず保持しているすべてのファイルを読み取り、それぞれをリリースまで辿ります。Sonarr のファイルはエピソード単位で辿るので、Sonarr が3エピソードを取り込んだシーズンパックは、その3エピソードについて使用中と表示されます。

**どのリリースがコピーかもしれないかは推測であり、画面にもそう表示されます。** 次の場合に、リリースは映画またはシーズンのグループに入ります:

- \*arr のファイルがそのリリースに含まれている
- \*arr の履歴が、そのリリースからインポートしたと示している、またはそのリリースから来たファイルを削除したと示している（アップグレード、手動、ディスク上の欠落のいずれか）
- zurg が、そのリリースを映画または番組の IMDb ID と判定している
- リリース名が、タイトルと年（年が1つずれている場合や、Radarr が映画に持つ2つ目の年も含む）、またはシリーズ名とシーズンに一致している

各リリースには、どの条件でそのグループに入ったかが表示されます。シーズンは、リリース同士が同じエピソードを含んでいる場合にだけグループになります。同じシーズンの単一エピソードのリリースが60本あっても、それは60の異なるエピソードです。シーズンのグループには、複数のリリースが保持しているエピソード、各エピソードを保持しているリリース、Sonarr のファイルが入っているリリース、そして同じグループの他のリリースにはない、各リリース固有のエピソード数が表示されます。どのリリースも勝者としては選ばれません。Radarr や Sonarr のアイテムに一致しないリリースは、名前と IMDb ID ごとにまとめて **Name matches only** の下に表示されます。

**各リリースは In use、No reference found、Unknown のいずれかです。**

| 状態 | 意味 |
|---|---|
| In use | Radarr または Sonarr が今保持しているファイルが、このリリースに含まれています。選択できません。 |
| No reference found | 設定されているすべての Radarr と Sonarr を最後まで読み取り、そのファイルのどれもこのリリースに含まれていません。Plex、Jellyfin などマウントを読んでいるクライアントはここからは見えないため、これは何にも再生されていない証明ではありません。 |
| Unknown | zurg では判定できません。\*arr を読み取れない場合、ライブラリがまだ読み込み中の場合、`__magic__` がオフの場合は、すべてのリリースが Unknown になります。同じ映画またはエピソードの \*arr のファイルがどのリリースまでも辿れない場合や、\*arr の履歴で、このリリースのファイルがディスクから消えていて、その映画またはエピソードにその後ファイルがない場合も Unknown になります。 |

**品質は、プロファイルの基準で表示されます。** \*arr が使っているリリースの場合は、\*arr 自身がそのファイルに付けた評価です。以前インポートしたリリースの場合は、そのときに付けられた評価です。それ以外の場合は、リリース名から読み取り、そのことを表示します。いずれも、アイテムの品質プロファイル内での位置として表示されます。例えば "rank 15 of 17 in 4K or best available (cutoff at 17)" のように表示されます。

**削除の前に、まず読み直します。** リリースを選択して **Check again and delete** を選びます。zurg はすべての \*arr の現在のファイルを読み直してから、削除を提示します。ページを読み込んだ後に使用中になったリリースは対象から外れます。Unknown のリリースは、削除の確認ダイアログで改めてチェックを入れた場合にのみ削除されます。削除自体は管理ページの一括削除で行われ、そのリリースを保持しているすべてのアカウントから、そのリリースのすべてのコピーが削除されます。

**いつ読み取るか。** ページを初めて開くと、`acquisition.sources` 配下のすべての Radarr と Sonarr を、インポートと削除の履歴を含めて読み取ります。大きなライブラリの履歴を読むには1分ほどかかることがあります。その後は、最後に読み取った内容と時刻が表示されます。**Read Radarr and Sonarr again** を選ぶまで、この表示が続きます。`enabled: false` のソースも読み取られます。アクイジションをオフにしても、\*arr が保持しているものは変わらないからです。ページには、ソースごとの件数も表示されます。読み取ったファイル数、リリースまで辿れたファイル数、`library_path` の外にあるパス上のファイル数、`__magic__` 内にあるのにどのリリースにもつながらないファイル数です。あるソースのファイルがどれもリリースまで辿れない場合は、その `library_path` を確認してください。

同じレポートは `/manage/duplicates/report.json` にもあります。また、`POST /manage/duplicates/check` に `{"hashes": [...]}` を送ると、\*arr を読み直し、各リリースの状態を返します。

## Newznab と Torznab {#newznab-and-torznab}

インデクサーのエントリーは `type` で種類を指定します。`type` がない場合は `newznab` として扱われます。これは、このフィールドができる前に書かれたすべてのエントリーが意味していたものです。問い合わせはどちらも同じですが、返ってくる結果は違います。Newznab の結果は NZB で、取得されて Usenet バックエンド用に `nzbs/` に書き込まれます。Torznab の結果は info hash で、デブリッドアカウントに渡されます。magnet も `infohash` 属性もない Torznab の結果はスキップされます。zurg は `.torrent` をダウンロードしないので、それでしか辿れない結果は zurg では扱えないためです。

**トレントは、すでにそれを持っているアカウントにのみ追加されます。** 追加を受け付けるアカウントはすべてハッシュを提示されます。ただし、Real-Debrid アカウントは、そのリリース名を完全に拒否する場合はスキップされます。キャッシュはアカウントごとに独立しているので、あるアカウントがリリースを削除していても、次のアカウントに同じことが当てはまるとは限らないからです。最初にそれを持っているアカウントが取得します。どこにもなければ通常の失敗した候補として扱われ、ランキングの次のリリースに進みます。次のリリースは別のトレントでも NZB でもかまいません。

TorBox と Debrid-Link では、見つからなかった場合は何も追加されません。AllDebrid と Offcloud では、その場で削除されます。Real-Debrid と Premiumize ではトレントが追加され、最大 20 秒間監視されます。キャッシュ済みのコンテンツは 1、2 秒以内に準備ができます。それ以降もダウンロード中のものは削除されます。そのため、アカウント上でダウンロードが実行されたままになることはありません。ただし、見つからなかった場合でも、アカウントの追加回数の上限にはカウントされることがあります。TorBox では、1 時間に許可された 60 回の未キャッシュ追加のうち 1 回を使います。

`watchlist: true` が設定されたアカウントには、最初にトレントが提示されます。残りのアカウントは `providers:` リストの順番に提示されます。`add_torrents: false` が設定されたアカウントには、トレントが提示されることはありません。

`prefer` は、同じ解像度で両方の種類が目標を満たせる場合に、どちらを先に試すかを決めます。解像度が優先されます。たとえば、アカウントがすでに持っている 2160p のトレントは、`prefer` の設定に関係なく 1080p の NZB より先に取得されます。`usenet` がデフォルトです。Usenet の取得はダウンロードを 1 回消費しますが、トレントはアカウントの追加枠を 1 つ使うからです。`torrents` を設定すると順序が逆になります。`best` を設定すると種類による区別をなくし、ランキングで一番上にあるものを、つまり同じ解像度の中でより大きいリリースを取得します。

映画では、1 回の試行で最大 3 つのトレントを試します。それぞれが追加 1 回分を消費します。そのうち最大 24 個の NZB は、[choosing a movie's release](#choosing-a-movies-release) で説明しているとおり、個別に確認されます。`usenet` の場合は、ある解像度の NZB がその解像度のトレントより先に試されます。`torrents` の場合は、トレントが先に試されます。`best` の場合は、各トレントがランキングの順番を待ちます。ある解像度の NZB は、その中で最も良いものの位置にまとめて試されます。Radarr をソースにしている場合は、すべての解像度の NZB が最も良いものの位置にまとめて試されます。その際は、そのセクションで説明しているとおり、安いものから順に試されます。シーズンパックは、どちらの種類でも 1 回の試行で 3 つのリリースを試します。個別のエピソードも同様です。

取得が待つ検証は、ソースによって異なります。Usenet のリリースはニュースサーバーに照会されます。これが、投稿がまだ残っているかどうかを確かめる唯一の方法だからです。`torbox_nzb` アカウントには照合先のニュースサーバーがありません。そのため、そこでの取得は TorBox が NZB を取得できたかどうかで確認されます。トレントは、アカウントがすでにコンテンツを持っていると示したから追加されたものです。そのため、残る確認事項は、リリースがファイル付きでライブラリに届いたかどうかだけです。チェックはそれだけを確かめ、アカウントが空と表示するリリースは、死んだ投稿と同じように除外されます。

NZB アカウント（`nzb` または `torbox_nzb`）がないインストールでも、Torznab インデクサーだけでacquisitionを実行できます。ただし、そのインストールでは Newznab インデクサーは検索されません。そのインストールでは NZB を再生できないからです。ログには、それぞれのインデクサーについて一度だけそのことが記録されます。トレントを受け付けるアカウントがないインストールでは、同じ理由で Torznab インデクサーは検索されません。どちらの場合でも、インストールに置き場所がない種類のリリースは候補になりません。そのため、試行で試すリリースの数も消費せず、Radarr などのソースにもそれについて問い合わせられることはありません。

### インデクサーの制限と拒否されたキー {#indexer-limits-and-refused-keys}

**zurg は DMM の上限にぶつからないよう、上限の内側に収まるように動きます。** DMM では、スポンサーのキーで全 torrent フィードを合わせて 1 分あたり 20 回まで検索できます。そのため zurg が DMM に送る検索は、3 秒に 1 回までです。それを超える検索は順番を待ちます。待つことは検索の失敗ではありません。順番が、その題名の試行が終わる時点より後になる場合や、2 分以上先になる場合は、検索は行われません。その題名は、ほかのインデクサーが見つけた結果だけで処理を続けます。

**429 または 503 を返したインデクサーは、要求された時間そっとしておきます。** すべての検索、NZB ダウンロード、機能確認は、順番待ち中のものも含めて、`Retry-After` で指定された時間を待ちます。待つ時間は最長 2 分です。2 分より長く待つよう求めてきたインデクサーには、その時間が過ぎるまで問い合わせません。

**1 つの DMM キーを複数の zurg で使うと、その 20 回の検索を分け合うことになります。** それぞれの zurg は、DMM の上限全体を守ろうとします。そのため、1 つのキーを 2 台か 3 台の zurg で使うと、DMM の上限にはまだぶつかります。DMM から拒否されるたびに、その zurg の DMM 検索は 1 分間止まります。その結果、題名の検索やグラブまで長く待たされることがあります。

**拒否されたキーは 1 時間そっとしておきます。** エラー 100 (キーが間違っている) または 101 (アカウント停止。スポンサー契約が切れたときに DMM が返すエラー) を返したインデクサーには、検索でも NZB ダウンロードでも 1 時間は問い合わせません。ログには一度だけ、たとえば `DMM torrents refused the API key: check dmm_api_key` と出力され、取得ページの **Indexers not asked now** に表示されます。`config.yml` でキーを変更すると、すぐに問い合わせが再開されます。それ以外のエラーは、その 1 回の検索だけに影響します。

## 映画のリリースを選ぶ {#choosing-a-movies-release}

映画の Usenet 候補は、品質の良さだけでなく、確認にかかるコストの順に試されます。名前の付いた動画が1本だけ入った投稿は、zurg が記事を2回読むだけで済み、たいてい完全なものです。40ボリュームのアーカイブセットは、サイズ確認の走査と、各ボリュームの両端の読み取りが必要になります。また、インデクサー上の複数ボリュームの remux セットの約3分の2はすでになくなっています。

インデクサー自身の `files` 数で投稿の形が予測できるため、候補はこの数で並べられます。10ファイル以下、次に30ファイルまで、次に30ファイル超、次に不明、の順です。同じ区分の中では、ファイル数の少ない順になります。同じコストの投稿の中で、Radarr などのソースが独自のプロファイルでリリースを判断する場合は、タイトルに WEB-DL または WEBRip と書かれたものが最初に来ます。次に Blu-ray、その次に残りです。各グループの中では、サイズの大きい投稿が先になります。ソース側の順位はここでは使われません。順位はソースに問い合わせないとわからず、zurg はリリースを検査する直前にしか問い合わせないためです。

ソースがない場合は、品質の順位、次にサイズで決まります。どのソースも候補を判断しない場合は、`quality` 設定で指定された解像度がコストより優先されます。そのため、ウォッチリストが `best` に設定されていても、提供されている最も高い解像度が選ばれます。その解像度の中では、最もコストの低い投稿が先になります。分割投稿の一部を指すタイトル（`[1/9] "Movie.part1.rar"`）の結果は候補にはなりません。また、同じ名前の2つの投稿のうち、ファイル数の少ない方だけが残ります。ライブラリには1つしか保存できないためです。

その後、最大24件の候補が検査されます。各 NZB は取得され、zurg 独自のパーサーで読み取られます。コンテンツファイルが最大2つで、そのうち1つが名前付きの `.mkv`、`.mp4`、`.m4v`、`.avi`、`.mov`、`.ts` のいずれかの動画で、500 MB 以上のものは、直接投稿です。PAR2 ボリュームや、`.nfo`、`.sfv`、`.srr`、`.nzb`、画像、`.txt`、`.url`、`.exe` などのサイドカーファイルは、コンテンツとしては数えません。最初の直接投稿は、すぐに保存されます。

アーカイブ投稿は、表示されている直接投稿が尽きるまで保留されます。その後、ボリューム数の少ない順に試されます。この際、ニュースサーバーで同時に待機できるアーカイブリリースは6件までに制限するゲートを通ります。修復データとサイドカーだけの投稿は、保存されることはありません。

検査済みの NZB はメモリに記憶されます。そのため、保存したリリースが無効だったとわかり、同じタイトルを再度試す場合は、前に取得したものを再び取得することなく、次の候補に進みます。

検索と NZB のダウンロードは、インデクサーごとに同時実行中リクエストの上限を共有します。インデクサーが `429` または `503` を返した場合は、少し待ってから再度リクエストし、その `Retry-After` に従います。

ダッシュボードには各ステップが表示されます。検索、検査中の候補、保存された内容です。

シリーズは前半の探索方式を使います。つまり、除外されていないランキング上位3件のリリースです。Sonarr のようにソースがリリースを判断する場合は、まず各リリースをソースに渡します。ソースが拒否したリリースは、3件の枠を消費しません。

`best_first` は、次のセクションで説明するように、両方の探索の順序を変更します。

## プロファイルの最優先項目を先に取得する {#taking-the-profiles-best-first}

```yaml
acquisition:
  best_first: true
```

デフォルトではオフです。オンにすると、Radarr または Sonarr のソースの最初の取得が、リリースの確認コストではなく、品質プロファイルの優先順位に従うようになります。Plex のウォッチリストと Seerr にはプロファイルがないので、影響を受けません。取得ページには、オンになっているかどうかが表示されます。

- **プロファイルの最高解像度が最初に来ます。** 各リリースは、タイトルに書かれた解像度によって配置されます。その位置は、その解像度でプロファイルが許可する最高品質です。zurg はこれを既に保持しているプロファイルから読み取り、Radarr と Sonarr に追加で問い合わせることはしません。同じ解像度の WEB-DL、Blu-ray、remux は同じ位置を共有します。同じ位置の中では、映画は依然として確認コストが最も低いリリースを取ります。シリーズは `quality` が最も高くランク付けしたものを取ります。解像度が書かれていないタイトルは最後になります。
- **カットオフが最上位として扱われます。** プロファイルがアップグレードを許可している間、カットオフ以上のすべての品質はカットオフと同じものとして扱われます。アップグレードパスがそれらのいずれかを置き換えることはありません。WEB 1080p までアップグレードするプロファイルは、2160p を許可していても、best first からは何も得られません。アップグレードを許可しないプロファイルは、順序全体を保持します。その最初のファイルが、そのまま保持されるファイルになります。
- **プロファイル内を順に下へフォールバックします。** NZB を取得できない、または読み取れないリリースは飛ばされます。ニュースサーバーが拒否したものは、これまで通り除外されます。プロファイルの順序で次のリリースが試されます。1回の試行で読み取る NZB は、位置に関係なく合計 24 件までです。
- **Usenet またはトレントの優先設定より先に評価されます。** アカウントが既に持っているトレントは、プロファイルでより低く配置された NZB より先に取得されます。同じ位置の NZB とトレントの間では、依然として `prefer` が決定します。
- **シーズンパックは単独のエピソードと同じくらい良くなければなりません。** 同じ検索内で単独のエピソードより低くランク付けされたパックは飛ばされます。その後、エピソードは1つずつ取得されます。Sonarr も同じ選択をします。比較されるのはその1回の検索だけです。より良いリリースがあるかもしれないからといって、エピソードが単独で再検索されることはありません。

これにはコストがあります。2160p プロファイルの上位は、ほとんどが単体の動画ファイルではなく、40 巻以上の remux や Blu-ray のセットです。そうしたセットは確認に時間がかかります。ニュースサーバーから消えている可能性も高くなります。また、アーカイブゲートでの順番待ちもあります。そのため、最初のファイルは通常より遅く届きます。最良のリリースがすべて消えているタイトルでは、zurg がプロファイルを下へ移る前に、それぞれが取得され、確認され、除外されます。パックなら1回で済んだシーズンを、単独のエピソードとして取得すると、取得は複数回になります。節約されるのは2回目の取得です。カットオフに達した最初のファイルは、決してアップグレードされません。

## 取得がソースの一覧に与える影響 {#what-acquiring-does-to-the-sources-own-list}

Plex のウォッチリストは、誰かが選んでまとめたリストです。項目を削除しても Plex には履歴が残らないため、そのタイトルを本当に欲しかったことを示す記録は、ウォッチリストだけです。zurg がそれをどう扱えるかは、2 つの設定で決まります。どちらも `plex_watchlist` ソースに適用されます。Seerr と Radarr のソースは zurg が書き込むリストを持たないため、そこではどちらも効果がありません。

`remove_after_grab`（デフォルトは `true`）は、取得したタイトルに対応するリリースのチェックが終わった後、そのタイトルをウォッチリストから削除します。これは従来からの動作です。ウォッチリストは「取得すべきもののキュー」として読まれ、zurg が手に入れたタイトルは完了扱いになります。`false` に設定すると、ウォッチリストはウォッチリストのまま残ります。閲覧用の永続的なリストとして残り、zurg はリストを編集せずにバックグラウンドで条件を満たしていきます。タイトルを残しておいても再チェックのコストはかかりません。受領記録がすでにそのタイトルを対象にしているので、インデクサーに再度問い合わせることはないからです。

zurg が何も取得できなかったタイトルは、この設定に関係なくウォッチリストに残ります。そのタイトルを確定させるすべてのリリースが、すでにライブラリにあった場合（自分で持っていたものや、別のリクエストで取り込まれていたもの）、何も取得も追加もされていません。その状態で削除しても、リストを編集するだけになってしまいます。これらのリリースも引き続きチェックされ、タイトルは完了扱いになるので、リストに載っている間は再び検索されません。削除してからもう一度追加した場合は、また残ります。zurg がいずれかのシーズンやエピソードを取得したタイトルは取得済みとみなされ、これまで通りリストから削除されます。

`only_new_items`（デフォルトは `true`）は、ソースが初めて実行されたときにリストにすでにある項目を取り込み、その後に追加された項目だけに対して動作します。この機能を有効にしたときは、リストを監視し始めるだけで、リストの全項目を一度に処理する必要はありません。`false` に設定すると、既存のリストをバックログとして扱います。

この設定が効くのは、**ソースの初回実行時の 1 回だけ**です。すでにキューを持つソースは実行中だったわけで、何を済ませて何を済ませていないかを記録しているのはそのキューです。この設定ではありません。そのため、後から有効にしても、処理中のバックログが失われることはありません。取り込まれたタイトルは、リストに残っている限り取り込まれたままです。削除してから再度追加するのは、通常の新しいリクエストとして扱われます。

## 取得の検証 {#verifying-a-grab}

保存されたNZBは、それだけではリリースとは言えません。インデクサーが応答したこと、その応答がNZBとして解析できたこと、そしてファイルが`nzbs/`に届いたことは、いずれもインデクサーについての事実で、投稿そのものについての事実ではありません。そこで、取得したNZBはすべて、エンジンがリクエストを受け付ける前に、設定されたニュースアカウントに問い合わせます。最初の16記事と、各コンテンツファイルの最後の記事を`STAT`で確認します。さらに、各ファイルの最初の記事と、ファイル数が少ないリリースではその他いくつかの記事を、丸ごと取得します（最大64記事）。ニュースサーバーは、内容を削除済みの記事に対しても`STAT`に応答することがあるからです。`STAT`で拒否された記事も、消えたと判断する前に丸ごと取得します。ニュースサーバーは、まだ配信している記事に対して`STAT`を拒否することもあるためです（NewsDemonでは2026-10-21にそれが起きました）。ただし、この取得はリリースごとに最大16記事までです。この確認は、`/api?mode=addfile`がSonarrやRadarrに対して行うのと同じ流れです。結果は3つあり、それぞれを区別することがこの仕組みの要点です。

- **記事が消えている。** そのグラブは数えません。レシートは開き直され、対象はまた「取得待ち」になります。さらに、そのリリースは30日間「dead」として記録されるので、次の試行では、すでにライブラリにあるものではなく、次の候補がランキングから選ばれます。この一覧に載ったリリースは候補になりません。取得もされず、試行が試す候補の数にも入りません。そのため、ランキングの上位に dead な投稿が並んでいても、その下にあるものが手の届かないままになることはなく、順に飛ばして評価されます。dead なシーズンパックがあった場合、そのシーズン全体が再び「取得待ち」に戻ります。代わりに、個別のエピソードが取得されます。自分で保存したNZBの取得であれば、そのNZBは監視ディレクトリから削除されます。そうしないと、ライブラリが開く前に再起動のたびに読み込まれて確認されてしまうからです。すでに監視ディレクトリやライブラリにあったNZB、そしてSonarrやRadarrが取り込んだNZBは、そのまま残します。
- **アカウントに問い合わせられなかった。** プールがダウンしている、アカウントが速度制限を受けている、あるいはライブラリがまだ新しいNZBを一覧にしていない、といった通常のケースです。何も確認できていないので、何も判断しません。リクエストは20秒後に再確認され、その後は40秒後と80秒後、以降は2分ごとに再確認されます。この待ち時間は再試行回数を消費しません。単に時間切れになった確認は別扱いです。その場合は、フルの時間を使ってすぐに再開されます。最大3回までで、その後に待機に入ります。この確認の時間は通常5分ですが、ファイル数が多く接続数の少ないアカウントのリリースでは、もっと長くなります。zurgは、接続数、確認の最も遅かった実測値、そして同時に走る6つの確認から時間を算出し、そのうえで2倍にします。たとえば接続が4つで90ボリュームのリリースなら、約53分が割り当てられます。以前は5分で時間切れになり、リリースが未確認のまま脇に置かれていました。何も確立できない確認が2時間の間に20回続いた場合、そのリリースは dead なものと同じように脇に置かれ、次の試行では別のリリースが試されます。確認できなかったリリースでリクエストが受け付けられることは、決してありません。
- **リリースは存在している。** レシートが保持していたものを手放し、受け付けの処理が進みます。

確認は、zurgがリリースの正確なファイルサイズを把握し終えるか、把握を諦めるまで待機します。SABnzbdエンドポイントが確認するのも、この時点です。サイズの把握では各ファイルの最初の記事を読み込み、確認でも同じ記事を読むため、両方を同時に走らせると、どちらも遅くなるだけでした。99本の映画の一覧で、各リリースを一覧に載った瞬間に確認したところ、最後のファイルがRadarrのフォルダに入るまで、ほぼ9分かかりました。サイズ把握を待っている間に時間切れになった確認も、時間切れになった確認と同じく、すぐに再開されます。30分経ってもまだサイズ把握中のリリースは、それでも確認されます。同時に確認されるリリースは最大6つで、残りは順番を待ちます。

確認は読み取りだけを行います。記事の本体をキャッシュに移すことも、dead な記事を記録することもないので、再生できるファイルを黙らせてしまうことはありません。サイズ把握の処理がちょうどファイルの最初の記事を取得したところであれば、確認はその取得済みのコピーを読み、同じ記事を二度取得することはしません。

NZBアカウント（`nzb`または`torbox_nzb`）がないインストールでは、NZBのグラブを確認する手段がありません。ただし、デビッドアカウントがトレントを受け付けている場合は、取得処理はそのまま動きます。各トレントは、[Newznab と Torznab](#newznab-and-torznab)で説明しているとおり、ファイルが入った状態でライブラリに届くかどうかで確認されます。また、再生するための中身も必要です。動画、音声、またはzurgがストリーミングできるアーカイブ（RAR、7z、zip、または番号付きパーツ）のいずれかが含まれている必要があります。プログラム、ディスクイメージ、テキストだけのトレントは偽物です。新しいエピソードは放送後の数時間に、こうした偽物を引き寄せがちです。その場合は、dead な投稿と同じように脇に置かれ、次のリリースがすぐに試されます。このリクエストのためにzurgがアカウントに追加したトレントであれば、アカウントから削除されます。すでにアカウントにあったトレントは、そのまま残します。NZBアカウントがなければ、NZBのグラブが受け付けられることは決してありません。確認も再生もできないからです。最後のNZBアカウントが削除される前から待機していたものは、dead な投稿と同じように脇に置かれ、次のリリースが試されます。

## 保存と復旧 {#persistence-and-recovery}

`data/acquisition.json` は、個々の取得（エピソードを含む）のソースIDとリクエストID、試行回数、再試行期限、処理中の作業、受領記録を保存します。また、ソースごとに最初のスナップショットを採用したことも記録するため、`only_new_items` は再起動のたびではなく一度だけ決められます。

対象のメディアやエディションが一致する場合、ソースをまたいで受領記録を再利用します。リリースのファイル名も、ライブラリと保存済みNZBに対して重複チェックを行います。受領記録には、ニュースサーバーからの回答をまだ待っている取得（grab）も含まれ、台帳には既に死んでいると判明したリリースも記録されます。そのため、待機中に再起動しても、未確認の取得を完了扱いにすることも、死んだリリースをランキングに戻すこともありません。

受領記録は永久に信頼されるわけではありません。タイトルを保有済みとみなす前に、zurg は、それを確定させたものがまだ存在するかを確認します。Radarr や Sonarr のフォルダに配置された動画、または DMM の wanted、Plex のウォッチリスト、Seerr のタイトルの場合は、ライブラリ内にそのリリース自体があるかを確認します。その後に削除されたものは、タイトルがまだ一覧にあり、ジョブが完了していても、再度検索されます。ただし、管理ページから削除されたリリースは、再び取得されることはありません。

保存されたリリースは、そのたびすぐにディスクへ書き込まれます。試行回数と再試行時刻は1分以内に書き込まれるため、クラッシュすると最大1分分を失う可能性がありますが、取得そのものが失われることはありません。
書き込みでは、一時ファイルをフラッシュしてから台帳を置き換え、対応している環境では親ディレクトリもフラッシュします。クラッシュ前に書き込まれたNZBは、最後の台帳書き込みが完了していなくても再利用されます。取得が記録されたら、Plex の削除の再試行で同じタイトルを再度取得することはありません。

失敗したものは、5分、10分、15分の後に再試行され、その後は1時間、6時間の間隔になります。それ以降は、失敗し続けた時間の半分だけ待つため、待ち時間は徐々に長くなります。失敗が1日続いた後はおよそ半日、4日続いた後は2日、最長でおよそ1週間になります（±4分の1程度）。これは、一緒に失敗したタイトル同士が同時に再試行しないようにするためです。5分の試行時間を使い切っても何も見つからなかった場合も、失敗として扱われます。
何も見つからなかった理由が、インデクサーに問い合わせできなかったためで、そのインデクサーが `Retry-After`（最大1日先の時刻）で問い合わせを控えるよう求めている場合、これは失敗にはカウントされません。そのタイトルは、その時刻の後に再試行され、さらにその後も最大で同じ長さだけ遅らされます。こうすることで、タイトルの待機列がインデクサーに一斉に問い合わせることを防ぎます。インデクサーが10分間休止を求めている場合は、10分後から20分以内に再試行されます。これは連続して最大3回まで行われ、その後は通常どおり失敗としてカウントされます。時刻を指定しないインデクサー（410 Gone を返したり、APIキーを拒否したりするもの）は、待機対象になりません。
2週間以上（かつ8回以上の試行）失敗し続けたタイトルは**parked**（保留）になります。zurg はそのタイトルについてインデクサーへの問い合わせを停止します。取得ページには parked として、失敗していた期間と理由とともに表示され、ログにも一度だけ記録されます。そのページの **Resume** を使うと、1つのタイトル、またはソースのすべての parked タイトルを、最初の短い再試行から再開できます。ソースが一度タイトルを一覧から外し、その後また一覧に載せた場合は、そのタイトルを改めて求めたとみなされるため、同じく再開されます。ニュースサーバーが確認した取得があると、そのタイトルの2週間は改めて数え直されるため、まだエピソードを見つけ続けているシーズンが保留になることはありません。
アップグレードも、どのソースからのものであっても保留にはなりません。より良いリリースは数か月後に出てくることがあり、タイトルは一覧に残り続けるため、代わりに再試行間隔は最大1週間に保たれます。DMM の wanted リストにあるものも同じ理由で保留にはなりません。まだ公開されていない映画や、誰も投稿していない古い映画は、取得されるか、あなたが削除するまで wanted のままです。回数と期限は、長時間のシャットダウンを含め、再起動をまたいでも保持されます。

永遠に失敗し続けるキューは、タイトル一覧には表示されない形でコストがかかります。ある環境では、Radarr と Sonarr の何千ものタイトルについて、何も見つからないまま6時間ごとに再試行され続けた結果、インデクサーへのクエリが1日数百回から数万回に増え、インデクサー側がアカウントを停止しました。その多くは、Usenet のリリースがない映画や、プロファイルで許可されたすべてのリリースが既に拒否されたアップグレードでした。未処理の Seerr リクエストは引き続き監視されます。Plex のアイテムは、計画されたすべてのシーズンが取得され、かつ確認された後にのみウォッチリストから削除されます。確認方法は、NZB の場合はニュースサーバーとの照合、`torbox_nzb` アカウントの場合は TorBox が取得したかどうか、トレントの場合はライブラリに到達して再生可能なものがあるかどうかです。さらに、`remove_after_grab` が許可している場合に限り、かつ zurg が何かを取得した場合に限ります。エピソード単位のフォールバック（loose-episode fallback）は、引き続きインデクサーの結果に含まれるエピソードに限定されます。

利用できないソースは、そのソース自身の作業を一時停止します。状態の書き込みに失敗した場合は、保存が成功するまで以後の取得を一時停止します。台帳が読めない、またはサポートされていない場合は、取得を一時停止し、ファイルを保持します。ファイルを修復または復元して、zurg を再起動してください。他の zurg のサービスは動き続けます。

以前の `data/plex-watchlist.json` は、履歴と、Plex の削除待ちだけの再試行・試行回数をそのまま保って一度だけインポートされます。元のファイルは残されます。両方の台帳は、`--include-caches` を付けない通常のバックアップに含まれます。コンテナを入れ替えても `data/` と `nzbs/` は保持してください。

## 別のアダプターを追加する {#adding-another-adapter}

独自のパッケージに `acquisition.Source` を実装してください:

1. `ID()` で、再起動をまたいでもインスタンスを識別できるようにします。
2. `List(ctx)` は `Item` の参照を完全なスナップショットとして返します。ページネーションでエラーが出た場合は、スナップショット全体を失敗扱いにします。保存するのはメタデータだけにしてください。認証情報や、API のユーザーオブジェクトをまるごと保存してはいけません。
3. `Resolve(ctx, item)` は item を再検証し、正規化された movie、season、episode のターゲットを返します。`Gone` を返すと不要な作業がキャンセルされます。`Follow` を返すと、現在のターゲットを取得したあとも、開いているリクエストを監視し続けます。
4. `Complete(ctx, item)` はワンショットの取得を確定させます。クラッシュ後に繰り返し呼ばれても問題ないようにしてください。読み取り専用のリストなら no-op で構いません。エンジンは、その item に紐づくすべての grab が応答を返したあとにだけこれを呼びます。そのため、アダプターがリリースを自分でチェックする必要はありません。また、呼ばれたという事実を、それ以上の何かの証拠とみなしてはいけません。

品質プロファイルを独自に持つソースは、`acquisition.Assessor` も実装できます。これを実装すると、各候補リリースをそのソース独自のルールで判定できます。Radarr と Sonarr のアダプターは、それぞれ自前のパーサーを通じてこれを行っています。

ソースの設定型とファクトリーは、acquisition サービスに登録してください。キュー、永続化、リトライ、エグゼキューターにソース固有の分岐を入れる必要はありません。Trakt、MDBList、Simkl はこのコントラクトに当てはめられますが、まだ実装されていません。

（以前の翻訳は、コードスパンが一致しないため却下されました。構造はそのまま維持してください。）
