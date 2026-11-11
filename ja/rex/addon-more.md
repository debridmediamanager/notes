# アドオンのその他の機能 {#more-from-your-addon}

[rex アドオンの作り方](addons.md)では基本を扱っています。このページでは、字幕、予告編、チャプター、コレクション、
プレイリスト、アーティスト画像、既知の映画、大規模ライブラリ、修正と削除について追加で説明します。各セクションは
[Step 5](addons.md#step-5-send-it) にフィールドを追加します。試すときは [home videos](addon-home-videos.md)、[music](addon-music.md)、
または [IPTV](addon-iptv.md) のチュートリアルを使ってください。

すべての例は rex nightly 2026.11.02 に送信して確認しています。完全なリファレンスは [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md) にあります。

## Plex が認識している映画・番組 {#films-and-shows-plex-knows}

**何をするか。** ファイル名の代わりに、Plex に映画やエピソードの名前、ポスター、キャスト、あらすじ、評価を表示させます。`display` の代わりになります。

`kind` と作品の ID を送ります。映画なら IMDb（`tt...`）または TMDB の ID、エピソードなら**番組**の ID を指定します。`season` と `episode` は TMDB の番号付けで指定します:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv",
 "kind": "movie", "ids": {"tmdb": 10378}, "media_info": { "...": "ffprobe's output" }}
```

**表示されるもの。** ファイル名が何であっても、映画は **Big Buck Bunny (2008)** として Plex のアートワーク付きで表示されます。rex はファイル名から何も読み取りません。送った内容がそのまま表示されます。エピソードを含めた詳しい説明は [rex と自分のアプリ](any-source.md)にあります。

(以前の翻訳は却下されました: コードスパンが一致しません。構造をそのまま保ってください。)

## 字幕 {#subtitles}

**何をするか。** 動画の横に置いた字幕ファイルを、その動画の字幕として提供します。ユーザーはアップロードした字幕と同じように、それを選んだり、ダウンロードしたり、焼き込んだりできます。

```json
"subtitles": [{"path": "films/Big Buck/film.en.srt", "language": "en", "size": 82}]
```

| Field | Meaning |
|---|---|
| `path` | アドオン上のファイルの場所です。動画の場合と同じです。拡張子がそのまま形式になります: `srt`、`ass`、`ssa`、`smi`、`txt`、`psb` のいずれか |
| `language` | `en` や `eng` のように、わかっている言語を書きます。rex はファイル名から言語を読み取りません |
| `forced`, `hearing_impaired` | そうする場合は `true` を指定します |
| `size` | バイト単位のサイズです。rex がファイルを読み直すのは、パスが新しいとき、またはサイズが変わったときだけです |

**見え方。** 動画に **English (SRT External)** の字幕が表示されます。`subtitles` を省略すると、前に送ったものがそのまま残ります。`[]` を指定すると、あなたが送った字幕は削除されます（アップロードした字幕やダウンロードした字幕は残ります）。rex が読めないファイルは除外されてログに記録されますが、動画自体は引き続き取り込まれます。

## 予告編とその他のエクストラ {#trailers-and-other-extras}

**何をするか。** 予告編、特典映像、削除シーンを、映画やドラマ本体の下の **Extras** に入れます。独立したタイトルとしては追加されません。

```json
{"id": "films/Big Buck/trailer.mp4", "path": "films/Big Buck/trailer.mp4",
 "kind": "extra", "extra_type": "trailer", "media_info": { "...": "ffprobe's output" }}
```

特典映像は、同じ `release` にある他の動画のタイトルに属します（デフォルトでは、そのフォルダ）。`extra_type` は `trailer`、`deleted`、`featurette`、`behindthescenes`、`interview`、`scene`、`short`、`opening`、`ending`、`other` のいずれかです。rex は、ファイル名やフォルダ名だけで動画を特典映像と判断することはありません。`kind: "extra"` を指定したものだけが特典映像になります。

**見え方。** 映画のページの Extras に予告編が表示され、ライブラリには一覧されません。

## チャプター {#chapters}

**何をするもの。** プレイヤーでチャプター間を簡単に移動できるようになります。

`-show_chapters` を付けて `ffprobe` も実行し、その出力をそのまま送ってください:

```bash
ffprobe -v error -print_format json -show_format -show_streams -show_chapters film.mkv
```

**表示されるはずのもの。** 動画のチャプターが、名前と時間付きで表示されます。rex がすでに持っている動画にチャプターを追加する場合は、次のスナップショットで `-show_chapters` を付けて、それらのプローブをもう一度送ってください。

## コレクションとプレイリスト {#collections-and-playlists}

**何をするか。** タイトルをライブラリのコレクションにまとめ、曲や動画をプレイリストにまとめます。どちらもアドオンが作成して、最新の状態に保ちます。

```json
"collections": ["Summer 2026"],
"playlists": {"Road trip": 1}
```

| Field | Meaning |
|---|---|
| `collections` | タイトルが入っているコレクションの名前一覧です。タイトルが初めてその名前を指定したときに作成されます |
| `playlists` | ファイルが入っているプレイリストのタイトル一覧です。各プレイリス内の位置は 1 から始まります。各プレイリストはサーバー所有者のもので、最初の曲がトラックなら音声、それ以外なら動画になります |

ユーザーの変更は残ります。誰かがコレクションから外したタイトルは、外れたままになります。プレイリストに追加された曲は、その位置を保ちます。名前を変えられたプレイリストは、その人のものとして残ります。

フィールドを省略すると、以前送った内容がそのまま残ります。`[]`（プレイリストの場合は `{}`）を指定すると、アドオンがそのファイルを入れたすべての場所から外します。

**表示される内容。** ライブラリの Collections タブに **Summer 2026** が表示され、Playlists には **Road trip** が順番どおりに表示されます。

## アーティスト画像 {#artist-pictures}

**何をするか。** 音楽アドオンが送ってくるアーティストの画像を表示します。Plex が知っていて自分で画像を選ぶようなアーティストでも表示されます。

`"artwork": "source"` で登録し、各トラックに画像を送ってください:

```json
"display": {"artist": {"title": "Radiohead", "poster": "http://127.0.0.1:9982/music/Radiohead/artist.jpg"}}
```

`artwork: "source"` を付けない場合、Plex が知っているアーティストは Plex の画像のままになり、`display.artist` は Plex が知らないアーティストにしか表示されません。どちらの場合でも、Plex のアプリで誰かが選んだり、アップロードしたりした画像はそのまま残ります。

## 大きなライブラリ: プローブは一度だけ送信 {#big-libraries-send-probes-once}

**What it does.** 数千本の動画のスナップショットを送るときに、`ffprobe` の出力をほとんど送らずに済ませられます。そのため、データが小さく、処理も速くなります。

`probe` を送ります。これは、動画のprobeが変わったときに変わる短いテキストで、自分で用意します（`ffprobe` 出力のハッシュ値が使えます）。rex がその `probe` を持つ動画を把握したら、`media_info` を付けずに `probe` だけを送ります:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv", "kind": "movie", "ids": {"tmdb": 10378}, "probe": "v1"}
```

rex は `"unchanged": 1` と返します。rex がその `probe` を持っていない場合（新しい動画、または probe が変わった動画）は、何も変更せず、その情報を求めてきます:

```json
{"created": 0, "updated": 0, "held": 0, "unchanged": 0, "wants": ["films/Big Buck/film.mkv"]}
```

その項目を `media_info` 付きで改めて送ってください。スナップショットでは、送信済みとして扱われた wanted 項目は、そのために削除されることはありません。お使いの rex がこの機能に対応しているか確認してください。[登録](addons.md#step-2-register-with-rex)の応答に `"features": ["probe_digest"]` が含まれていれば対応しています。

## みんなが直したこと: Fix Match {#what-people-fixed-fix-match}

**何をするか。** アドオンに、Plex アプリで手動で（Fix Match から）正しくマッチさせたビデオを教えます。これにより、以降はそのビデオを正しく送れるようになります。

```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/matches
```

```json
{"size": 1, "matches": [{"release": "films/Mystery Reel", "ids": {"tmdb": 45745, "imdb": "tt1727587", "tvdb": 9413}, "kind": "movie", "matched_at": 1793751999}]}
```

各エントリーは `release`（フォルダー。`release` を送らない限り）と、マッチさせた映画やシリーズの ID からなります。rex は次に何を送ってもマッチを保持するので、これを無視しても何も壊れません。ただ、読み取ればアドオンが `kind` と `ids` を自分で送れるようになり、rex の行が再構築されても修正内容を覚えていられます。マッチがなければ答えは `{"size": 0}` です。

## アドオンの削除 {#removing-your-addon}

**何をするか。** rex から、アドオンとそれが送り出したものすべてを、ファイルには触れずに取り除きます。

リクエストは2回送ります。1回目は、どれだけ削除されるかを返し、5分間有効なリンクをくれます。2回目は、そのリンクを使って削除を実行します。

```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon
# {"confirm": "/rex/sources/myaddon/confirm/eae4...", "items": 4, "expires_in": 300}
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon/confirm/eae4...
# {"deleted": true, "removed": 4}
```

視聴履歴は行と一緒に消えます。あとで登録し直して送り直すと、まっさらな状態から新しい行ができます。代わりにアドオンを新しいバージョンに**置き換える**場合は、名前、ID、パスの最初のセグメントを同じままにしてください。そうすると新しいものが同じ行を更新します。ライブラリは rex が削除することはありません。どうしても消したい場合は Plex アプリで削除してください。

## rex に送信できるのは誰か {#who-may-send-to-rex}

rex のフィード（`/rex/sources` と `/rex/feed`）はトークンを必要としません。アクセスに応答するのは、rex 本体と同じマシン上のプログラム、ご自宅のネットワーク（`192.168.x.x`、`10.x.x.x`、`172.16-31.x.x` およびプライベート IPv6 アドレス）、そして Tailscale（`100.64-127.x.x`）からのリクエストだけです。それ以外の相手には存在しないものとして扱われます。rex-direct 用に rex のポートを転送したり、IPv6 経由で通したりしても同じです。リバースプロキシを rex のマシン上で使っている場合、プロキシはローカルのプログラムとして rex にアクセスするので、rex の前に置くなら、そこで `/rex/` をブロックしてください。
