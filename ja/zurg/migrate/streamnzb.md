# streamnzb v5.1.0 から zurg への移行 {#migrating-from-streamnzb-v510-to-zurg}

streamnzb は Stremio アドオンです。再生ボタンを押すと Newznab インデクサーを検索し、当選したリリースをストリーミングします。
何も保存されません。ファイルシステムの WebDAV マウントも Plex ライブラリもありません。

**ディスク上に守るべきライブラリはなく、失われる Plex の視聴状態もありません。** 他の移行ガイドにあるパス保持の手順は、このケースでは不要です。

zurg は 2 通りの方法で streamnzb の代わりになれます。どちらか一方、または両方を使えます。

- **Stremio を続ける。** zurg には独自の [Stremio アドオン](../guides/stremio.md) があります。再生ボタンを押すと Newznab インデクサーを検索し、選んだリリースをニュースアカウント経由でストリーミングします。streamnzb と同じ仕組みです。必要なのは zurg だけです。rclone もメディアサーバーも要りません。この方法で再生したリリースはすべて zurg のライブラリにも残ります。
- **ライブラリを作る。** zurg はリリースをライブラリに保存し、Plex、Jellyfin、Emby 向けにマウントします。Sonarr と Radarr でライブラリを埋められます。zurg 自体もウォッチリストからライブラリを埋められます。

streamnzb にあって zurg に同等の機能がないものがいくつかあります。このガイドではそれを説明します。

このガイドは、対象となる問題が小さいため、兄弟ガイドより短くしてあります。

## 再スキャンが必要なもの、新たに表示されるコンテンツ {#what-needs-rescanning-and-what-new-content-shows-up}

[他の移行ガイド](index.md)で扱っている2つの質問は、ここではあまり当てはまりません。その理由を書いておきます。そうしないと迷わせてしまうと思うので。

**再スキャンは必要ありません。対象がないからです。** streamnzb はライブラリを持たず、Plex にもどのパスにも紐づいたアイテムがありません。そのため、共通ページにあるトラッシュガードの仕組みはここでは必要ありません。守るべき古いアイテムはなく、ミスで削除されるものもありません。

**すべてが新しいコンテンツです。** zurg の `nzbs/` に入れたものは、空のライブラリへの初回スキャンになります。最初のスキャンの前に、ライブラリを好みの形に整えておきましょう。後から直すより楽です。先に設定しておくとよい項目が2つあります。

- メディアライブラリがスキャンするディレクトリには [`only_show_the_biggest_file: true`](../reference/config.md) を設定しておくとよいです。これがないと、サンプル動画や `.nfo` ファイル、投稿者の `.url` 広告ファイルまで表示されてしまいます。
- それらのライブラリでは「Generate video preview thumbnails」を**オフ**にしてください。ストリーミングマウントでは、サムネイルを作るたびにリリース全体をニュースサーバーの利用枠から読み込むことになります。初回スキャンではライブラリ全体が一度に Plex に渡されるので、特に注意が必要です。

---

## モデルの変更 {#the-model-change}

| | streamnzb | zurg |
|---|---|---|
| コンテンツの取得 | 再生リクエストごとに Newznab インデクサーを検索 | [Stremio アドオン](../guides/stremio.md)は再生リクエストごとに Newznab インデクサーを検索します。ライブラリは `.nzb` ファイルと SABnzbd エンドポイントからも埋まり、[取得](../guides/acquisition.md)の仕組みも使えます |
| ランキングと選択 | jhin traits とフィルタープロファイル、AvailNZB チェック | まず解像度で並べ、そのあと各解像度の中でサイズを幅広く分けます。traits もフィルタープロファイルもありません |
| 保持 | 何も残しません。再生のたびに新しく検索します | 永続的なライブラリです。アドオン経由で再生したリリースはライブラリに残ります |
| クライアント | Stremio。アドオンがメタデータプロバイダーも兼ねます | zurg のアドオン経由の Stremio（ストリームのみ応答）。マウント経由ならどのメディアサーバーでも使えます。Infuse には WebDAV を直接使えます |
| ファイルシステム | なし | rclone FUSE マウント + WebDAV + シンプルな HTTP インデックス |
| アーカイブ | RAR と 7z は **STORE のみ**。圧縮されたリリースは再生できません | 圧縮された RAR と 7z も透過的にストリーミングします |
| 難読化された投稿 | 拒否 | yEnc ヘッダーと PAR2 から名前を復元します。ペイロードはリリース名で表示されます |
| 破損した投稿 | AvailNZB でスキップ | PAR2 で欠けた記事を再構築します。先頭が消えているリリースはアドオンがスキップして、次のリリースを試します |
| SABnzbd API | なし。代わりにポート 119 で NNTP プロキシがあります | あります（オプトイン）。取得のたびにニュースサーバーで確認します。PAR2 で再構築できない死んだ投稿は **Failed** と報告されます |

普段の使い方なら、Stremio はそのままで大丈夫です。zurg のアドオンを追加して、いつもどおりタイトルを選ぶだけです。zurg がインデクサーを検索し、選んだものを再生します。セットアップは [Stremio のページ](../guides/stremio.md)にまとめてあります。リリースを最初に再生するときは、zurg が NZB を取得してリリースを一覧にするため少し待ちます。普通は数秒ほどです。そのリリースの2回目以降の再生は、すぐに始まります。

メディアサーバー用のライブラリには、中身を入れる仕組みが必要です。

- **SABnzbd エンドポイント。** `sabnzbd.enabled: true` を設定すると、zurg がダウンロードクライアントとして Sonarr と Radarr に応答するようになります。インポートは `__magic__` 内のリネームです。取得したものは `__magic__/__all__` に入ります。インポートでは、そこから隣に作ったルートフォルダへファイルを移動します。コピーは行われません。ほとんどのライブラリ構成ではこれを使うのがおすすめです。詳しくは [Sonarr と Radarr](../guides/sonarr-radarr.md) を参照してください。zurg は完了を報告する前に、取得のたびにニュースサーバーで確認します。すべてのファイルについて先頭と末尾を問い合わせます。さらに各ファイルの先頭記事もダウンロードします。ファイル数が少ないリリースでも、最大64記事に加えてもう少し確認します。ニュースサーバーによっては、内容が削除された後も記事があると答えることがあり、実際にダウンロードしてみないとわからない場合があります。zurg は、記事が欠けていても PAR2 ファイルから再構築できる場合は再構築します。再構築できないものは **Failed** と報告されます。すると \*arr がそれをブロックリストに入れ、別のものを取得します。
- **取得機能。** zurg は自分でリクエストを取得することもできます。リクエストは Plex のウォッチリストや Seerr、\*arr から来ます。zurg は Newznab インデクサーを検索し、取得したものを同じ方法で確認します。詳しくは [取得](../guides/acquisition.md)を参照してください。
- **手動でのドロップ。** インデクサーのサイトから `.nzb` をダウンロードして、`nzbs/` にコピーします。ファイル名は固定で、ディレクトリは15秒ほどごとに再スキャンされます。ファイルは移動も消費もされません。いつでも動く確実な基本の方法です。
- **Sonarr と Radarr の "Usenet Blackhole"。** \*arr は、*Nzb Folder* を zurg の `nzbs/` に指定した Blackhole ダウンロードクライアントを使うように設定できます。これで、エンドポイントなしでも検索と取得の自動化を取り戻せます。ただし代償があります。\*arr は、ウォッチフォルダーに完了したダウンロードが現れるのを待ってからインポートします。zurg はリリースをマウントに表示するだけで、そのようなファイルは作りません。そのため \*arr のキューでは、そのアイテムは完了しないままに見えます。得られるのは自動化された NZB 配信であり、\*arr のインポートとリネームの流れではありません。この方法の \*arr 側は、ガイド用に再確認していません。zurg 側は `internal/nzb/provider.go:30` のコードで確認しています。
- **インデクサー独自の RSS やカートからディレクトリへのダウンロード。** これは完全にインデクサー次第で、取得をスクリプトで組む必要があります。未検証で、一部のインデクサーが提供している、という点だけ触れておきます。

**ドロップする前にファイル名を付けてください。** マウント内のリリースフォルダーの名前は NZB の *ファイル名* から付けられます。`<meta type="name">` ヘッダーは、ファイル名がハッシュのように見える場合にのみ使われます。これは 2026-08-19 に5つのサーバーすべてで確認しました。`indexer_download_48213.nzb` のようなファイルでは、Plex が照合する材料がありません。そのため、先にリリース名へリネームしてください。こうすればフォルダー名は完全に自分の管理下に置けます。同じ名前の別々のリリースには、` {shorthash}` のサフィックスが付きます。

## 引き継がれる設定 {#configuration-that-carries-over}

移行できるものは2つあります。

1つ目は Usenet プロバイダーです。streamnzb ではプロバイダーを **Settings → Providers** で設定します。ホスト、ポート、ユーザー名、パスワード、接続数を指定します。環境変数でも設定できます。同じアカウントは zurg の `nntp` ブロックになります。

変更前（streamnzb）。ドキュメントに記載のキー名を使った環境変数の形式です。

```
PROVIDER_1_HOST=news.example.com
PROVIDER_1_PORT=563
PROVIDER_1_SSL=true
PROVIDER_1_USERNAME=USERNAME
PROVIDER_1_PASSWORD=PASSWORD
PROVIDER_1_CONNECTIONS=30
PROVIDER_1_PRIORITY=1
```

変更後（zurg の `config.yml`）。

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true            # streamnzb's SSL flag
      username: USERNAME
      password: PASSWORD
      connections: 30      # your plan's real allowance and the tuning knob
      cache_size_mb: 512
```

`PROVIDER_2_*` のような2つ目の streamnzb プロバイダーは `nntp.servers` に入れます。zurg は記事ごとにアカウントを順番に試します。`priority` はそのまま対応します。zurg には streamnzb にない概念が2つあります。`backup: true` を設定すると、従量課金のブロックアカウントになり、すべてのプライマリが *no such article* と返した場合にのみ使われます。`backbone` を設定すると、同じ spool にある2つのアカウントに同じ問い合わせを二重に送ることを防ぎます。`nzb` プロバイダーのエントリーは1つしか作れません。追加のニュースアカウントは、その隣ではなく、このエントリーの中に入れます。

2つ目はインデクサーです。`stremio.indexers` の下に、同じ URL と API キーを入れます。Acquisition は独自のリストがない場合、同じリストを使います。

```yaml
stremio:
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
```

streamnzb の `data/config.json` のそれ以外の内容は移行できません。`streams` と `filter_profiles` のブロックは、streamnzb のアドオンが提供する内容を決めていました。zurg のアドオンは、タイトルごとに1つのリストと独自のランキングを持っています。近い設定は2つだけです。`max_size_gb` は、指定したサイズを超えるリリースを除外します。`max_results` は、解像度ごとに残すリリースの数を指定します。その他は [Stremio ページ](../guides/stremio.md) を参照してください。

---

## 視聴履歴 {#watch-history}

streamnzb は、ストリームごとの再生履歴をデータベースに保存します。デフォルトでは `data/streamnzb.db` の SQLite ですが、Postgres も選べます。Continue Watching と Because You Watched の行は、このデータから作られています。ドキュメントでは中身を「library, search and play history, bad releases, and metrics」と説明しています。

**このデータは、Plex のライブラリには移せません。** Plex の視聴状態は Plex 独自のデータベースにアイテム単位で保存され、そのアイテムがまずライブラリに存在している必要があります。また、どちら側にもインポーターはありません。これは、データを失うというより、データの持ち方がそもそも違うということです。streamnzb の履歴は、ファイルではなく検索やストリームを参照しています。移行前に記録を残しておきたいなら、データベースは普通の SQLite なので、直接読めます。

```bash
sqlite3 data/streamnzb.db .tables
sqlite3 data/streamnzb.db "select * from <table> limit 20;"
```

テーブル名は正式にはドキュメントに書かれておらず、このガイドでも確認していません。`.tables` を実行すると確認できます。Postgres の場合は、`DATABASE_URL` が指しているデータベースに同じデータがあります。新しい環境の視聴状態はゼロから始まり、最初に再生したときから Plex に記録されていきます。

---

## 得られるもの {#what-you-gain}

- **本物のライブラリ。** Plex、Jellyfin、Emby はファイルシステムをスキャンして、メタデータを保持し、対応しているすべてのクライアントで視聴状況を管理します。Stremio だけではありません。
- **PAR2 による修復。** 記事が欠けているリリースは、バックグラウンドでそのリリース自身のリカバリーファイルを使って再構築されます。streamnzb は不良リリースをスキップする方式でした。zurg はそれを修復します。
- **難読化されたリリース。** zurg は yEnc ヘッダーと PAR2 インデックスから本来のファイル名を復元し、完全に難読化されたペイロードを、リリース名のもとで提供します。ベンチ上で `Obfuscated.nzb` を再生したところ、きれいな `Toy.Story.5.2026...KyoGo.mkv` が再生されました。streamnzb はこれらを一律に拒否します。
- **圧縮された RAR と 7z。** streamnzb がストリーミングできるのは STORE 形式のアーカイブだけで、その README にも「圧縮された RAR リリースは再生できません」と明記されています。zurg は圧縮アーカイブから動画をストリーミングし、その際に内部のディレクトリ構造も再現します。
- **2回目以降の再生はすぐ始まります。** streamnzb は再生のたびに検索と確認を行います。zurg は一度再生したものを保持します。ライブラリにあるリリースはすぐに再生できます。Sonarr や Radarr が取得したものは、最初からこの状態になっています。
- **複数アカウントへの対応力。** 優先度の設定、従量課金の `backup` アカウント、`backbone` による重複排除があり、すべてのアカウントで見つからなかった場合の修復経路もあります。

## 失われるもの {#what-you-lose}

- **jhin とフィルタープロファイル。** zurg のアドオンもインデクサーを検索します。ランク付けは解像度とサイズだけで行います。jhin の特性、フィルタープロファイル、スコアはありません。
- **AvailNZB チェック。** zurg は、リリースが生きているかどうかを他に誰にも問い合わせません。アドオンは、選んだリリースの先頭を読んで確かめます。その先頭が欠けていれば、リストの次のリリースに移ります。Sonarr や Radarr からの取得は、ニュースサーバーに照合してから完了扱いになります。ファイルの奥で壊れている箇所は、読み取りがそこに届いたときに見つかります。投稿に十分なリカバリーデータがあれば、PAR2 修復で再構築されます。2026-08-19 には、ボリュームが丸ごと欠けた RAR セットがエラーではなく空のフォルダーとして表示されていました。
- **streamnzb のカタログと行。** 組み込みのカタログとメタデータ、そして Continue Watching と Because You Watched の行は、streamnzb 自身の履歴から作られていました。zurg のアドオンはストリームにだけ応答します。メディアサーバーには、ライブラリ用にそれらの行の独自版があります。
- **ポート 119 の NNTP プロキシ。** SABnzbd や NZBGet をニュースサーバーとして streamnzb に向けていた場合、再び本物のプロバイダーの認証情報が必要になります。

## zurg のセットアップ {#standing-up-zurg}

Usenet専用の動作する `config.yml`です。

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30          # the plan's full allowance once streamnzb is gone
      cache_size_mb: 512

enable_repair: true            # PAR2 repair does not run without this
par2_patch_cache_mb: 512

stremio:                       # keeps Stremio working. Leave it out for a library alone
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY

mount_path: "/mnt/zurg"
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run

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

Usenetのコンテンツに `tags_match_any` フィルターは使わないでください。`zurg_*` タグは ffprobe から来ますが、このバックエンドでは ffprobe は一切実行されません。そのため、そのようなディレクトリには Usenet のリリースが決して入りません。代わりに、名前、拡張子、サイズ、`has_episodes` でフィルターしてください。

そのあと起動してください。

```bash
./zurg               # startup verifies the news account and says so, loudly, and makes nzbs/
ls /mnt/zurg/__all__/
```

Usenet だけをアカウントとして使っている場合、`__nzb__` フォルダーはマウントのルート一覧から外されます。その代わり `__all__` に同じファイルが入っています。そのため、マウント上の `__all__` の下で再生を試すか、直接の HTTP パス `http://localhost:9999/http/__nzb__/` を開いてください。`nzbs/` のサブディレクトリはスキップされ、`.nzb.gz` は読み込まれません。

### 最初の Plex ライブラリ {#the-first-plex-library}

ライブラリは、マウントのルートではなく `/mnt/zurg/movies` や `/mnt/zurg/shows` のような**サブディレクトリ**に向けてください。ルートは絶対に指定しないでください。同じリリースが `__all__` と該当するすべてのディレクトリに現れるため、ルートを指定するとスキャンが何度も重複してしまいます。
Usenet だけをアカウントとして使っている場合、`__nzb__` はマウントのルート一覧から外れており、マウント経由では解決されません。`__all__` に同じファイルが入っているためです。
zurg には `plex_server_url` と `plex_token` を設定してください。部分スキャンを要求できるようになります。

ライブラリが新規かどうかに関係なく、最初のスキャンから重要になる設定が2つあります。これらが防ぐのは、スキャン**中に**マウントが一時的に途切れる障害です。

1. **"Empty trash automatically after every scan"** のチェックを外して、`autoEmptyTrash` を 0 にしてください。スキャン中にマウントが消えると、Plex はすべてのファイルが削除されたと判断してしまいます。zurg の再起動や rclone の再マウントだけでも起きえます。自動削除が有効だと、ファイルは即座に完全に削除されます。無効にしておけば、ゴミ箱に残り、マウントが戻ったときに復活します。過去にはこれで数万件のアイテムが失われたことがあります。
2. **"Generate video preview thumbnails"** のチェックを外してください。Usenet では、サムネイル生成のたびにリリース全体を読み込むことになり、接続の利用枠を大きく消費します。

また、Plex がスキャン中は zurg を絶対に再起動しないでください。事前チェックの結果がゼロであり、上記2つの設定もどちらも済んでいる必要があります。

```bash
TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

`grep -c` ではなく `grep -o … | wc -l` を使ってください。grep は一致するものが見つからないと非ゼロで終了しますが、ここではそれが*正常な*ケースです。その結果、`&&` のチェーンや `set -e` のスクリプトが、守るべき再起動の直前で中断されてしまいます。

リリースが初めて一覧に出た直後は、ファイルサイズが少し後で確定します。NZB にはファイルの長さが書かれていないため、最初の一覧では NZB に記録された記事サイズから推定します。その推定値は最大で約3パーセント多めに出ることがあります。その後 zurg はバックグラウンドで正確な長さを取得して保持します。それより前に実行されたスキャンは推定値を見てしまいます。すると Plex はファイルが変更されたとみなし、もう一度だけ解析し直します。削除されるものは何もありません。

---

## 両方を並行して動かす {#running-both-side-by-side}

ポートは競合しません。streamnzb は 7000 と 119 を、zurg は 9999 を使います。
そのため、移行は現実的な方法で進めるのがおすすめです。zurg のライブラリが埋まるまで、streamnzb で Stremio への配信を続けてください。

共有リソースは 1 つだけで、ニュースアカウントです。**両方とも同じ接続数の枠から読み込み、プロバイダーは両方を合わせて制限します。**
接続数 50 のプランでは、streamnzb を 50、zurg を 30 にはできません。
超過分の接続は拒否され、zurg 側では再生が遅い、または止まるように見えます。
接続数は明示的に分けてください。streamnzb で `PROVIDER_1_CONNECTIONS=20` を試し、zurg では `connections: 30` にします。
streamnzb を引退させたら、zurg に枠の全部を渡してください。zurg の単一ストリームのスループットは、この数値で決まるからです。

streamnzb をオフにするときは、クライアントから streamnzb の Stremio アドオンを削除してください。
履歴を残したい場合は `data/` のコピーを保存しておきます。
その中の `config.json` と `streamnzb.db` が、streamnzb の状態のすべてです。
最後に、119 の NNTP プロキシを使っていたものは、プロバイダーに直接接続するように設定し直してください。
