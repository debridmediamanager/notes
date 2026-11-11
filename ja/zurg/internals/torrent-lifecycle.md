# Real-Debrid、AllDebrid、TorBox でのトレントのライフサイクル {#torrent-lifecycle-on-real-debrid-alldebrid-and-torbox}

2026-08-30 に、ライブのアカウントに対して測定しました。**観測済み** と書いたものはキャプチャから得られた内容です。**推定** と書いたものはキャプチャでは確認できず、その理由も書いてあります。

zurg でこれが必要なのは、qBittorrent 互換シムが Sonarr と Radarr に、ダウンロードが今どの段階にあるかを伝える必要があるからです。今はそれができません。`TorrentInfo.Status` には Real-Debrid のステータス用語が入っていて、AllDebrid と TorBox のパッケージは zurg 自身のコードがトレントを見る前に、その用語へ変換しています。TorBox の `stalled (no seeds)` は `queued` として届きます。シーダー数、速度、残り時間は、そもそも何も渡されていません。そのため段階表は、すでに値を正規化して捨ててしまっているプロバイダーパッケージからではなく、ワイヤー上の値から作る必要がありました。

ハーネスは `scripts/torrent_lifecycle_probe.py` です。各プロバイダーの生の REST API を直接呼び出すので、キャプチャはワイヤー上のステータスになります。途中で追加したものはすべて、Ctrl-C で中断した場合も含めて、最後に削除されます。

---

## 測定方法 {#how-this-was-measured}

### アカウント {#the-accounts}

| Provider | Account | Why this one |
|---|---|---|
| Real-Debrid | テスト用アカウント | 実行中に zurg を使っているものがないので、テスト中に他から触られることはなかった |
| AllDebrid | テスト用キー | このアカウントには既に他のマグネットが入っていたので、テストで作成した ID のものだけが削除された |
| TorBox | ライブキー | **同じアカウントに別の zurg インスタンスが読み込まれていた**。これは脚注程度の話ではない。[ハザード](#hazards-found-on-the-way)を参照 |

認証情報は環境変数 `RD_TOKEN` `AD_KEY` `TB_KEY` から取得します。キャプチャには何も書き出しません。

### トレント {#the-torrents}

すべて合法的なものです。FOSS のイメージとパブリックドメインの映画を使っています。`.torrent` から取得した info hash は、すべてハーネスがファイルから再計算したもので、手で入力してはいません。スウォームのサイズは、同じ日にトラッカーをスクレイプして得た値です。

| Case | Torrent | Info hash | Size | Tracker seeders | Webseeds |
|---|---|---|---|---|---|
| cached | ビッグ・バック・バニー | `dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c` | 264 MiB | 該当なし | 該当なし |
| cached | シンテル | `08ada5a7a6183aae1e09d831df6748d566095a10` | 123 MiB | 該当なし | 該当なし |
| cached | ubuntu-26.04.1-desktop-amd64.iso | `5b1e0d988fc7a0c9e99bd852071681a59974b39f` | 6.04 GiB | 22 to 27 | なし |
| uncached | debian-13.6.0-arm64-DVD-1.iso | `4d38178b8f08447ea8609e844b0071354ed65887` | 3.72 GiB | 212 | 2 |
| uncached | debian-13.2.0-amd64-DVD-1.iso | `7f23b66ebc763f6d931e999583adfd22a7d796fa` | 3.71 GiB | 328 | 2 |
| webseed | Prelinger `205882_Home_Movie_005588` | `69e7bba940b3c2edf7ce517330e3ca904877d8d1` | 0.71 GiB | 0 seeders and 0 leechers | 3 |
| seedless | ubuntu-16.04.6-desktop-i386.iso | `c16796a74dc24cc7c6df2f7b66b861e22dec69b1` | 1.56 GiB | 0 | なし |
| seedless | ubuntu-24.04-beta-live-server-s390x.iso | `8e693ebcdda44f741e2034cedbb552e93944143d` | 1.18 GiB | 0 | なし |
| nometa | ランダムな40桁の16進数 | `3f9c1a77b0e4d2568af3c01e9b7d4a5268c1f0e3` | なし | なし | なし |

これらの 0 は本当の値で、トラッカーが死んでいるわけではありません。同じループの中で、3 つの Ubuntu エントリすべてについて `torrent.ubuntu.com` を 2 回スクレイプしました。26.04.1 では 22 と 27 のシーダー数が返ってきましたが、seedless の 2 つでは空の `d5:filesdee` が返ってきました。`bt1.archive.org` と Prelinger のアイテムも同じです。

TorBox の `checkcached` は、何かを追加する前にすべての hash に対して問い合わせました。3 つのキャッシュ行の 3 つ（cached）でキャッシュ済みと返り、残り 6 つは未キャッシュと返ってきました。これは、ケース名が示している区分と一致しています。このプローブは 3 つの方法のうち唯一、非破壊的なキャッシュ確認です。

### ポーリング間隔と上限 {#poll-cadence-and-caps}

最初の2分間は3秒、その後は15秒です。キャッシュ済みの場合は1秒にしています。そのケースでは、ライフサイクル全体が通常の1回のポーリングの中で終わってしまうことがあるからです。

キャンペーンでは、torrentごとの上限を、スクリプトのデフォルトの30分ではなく15分にしています。shimが提案しているデフォルトのタイムアウトは10分です。15分経ってもまだ進行中のtorrentは、重要な時間帯をすでに過ぎています。

Real-Debridへの追加は、最低20秒間隔をあけています。

各プロバイダーは、それぞれ専用の出力ディレクトリに対して、独立したプロセスとして実行されます。こうすることで、1つのプロセス内でReal-Debridの追加間隔を正しく保てますし、3つを同時に実行することもできます。

---

## Real-Debrid

### エンドポイント {#endpoints}

```
POST   /rest/1.0/torrents/addMagnet          magnet=magnet:?xt=urn:btih:<hash>   -> 201 {"id","uri"}
POST   /rest/1.0/torrents/selectFiles/{id}   files=all                           -> 204
GET    /rest/1.0/torrents/info/{id}                                              -> 200 object
DELETE /rest/1.0/torrents/delete/{id}                                            -> 204
```

### 観測されたステータス値 {#status-values-observed}

`waiting_files_selection` `magnet_conversion` `magnet_error` `queued` `downloading` `uploading`
`downloaded`

ここでは確認されていません。`compressing` `virus` `error` `dead` は、このキャンペーンが正規の方法では用意できなかったコンテンツを必要とするものです。

### どのステータスでどのワイヤーフィールドが存在するか {#which-wire-fields-exist-in-which-status}

ちゃんと覚えておいてほしいのは、語彙よりこちらの方が大事だということです。フィールドは増えたり消えたりします。`speed` をどの状態でも読むマッパーは、半分くらいの確率でキーがない値を読んでしまいます。

| Field | magnet_conversion | queued | downloading | uploading | downloaded |
|---|---|---|---|---|---|
| `status` | あり | あり | あり | あり | あり |
| `progress` | 0 | 0 | **浮動小数点のパーセント**（0〜100） | **0 に戻り**、100 まで増える | 100 |
| `seeders` | あり | **キーなし** | あり | **キーなし** | **キーなし** |
| `speed` | **キーなし** | **キーなし** | あり、バイト/秒 | あり、キャプチャ中は常に 0 | **キーなし** |
| `bytes` / `original_bytes` | 0 | 実際のサイズ | 実際のサイズ | 実際のサイズ | 実際のサイズ |
| `filename` | `"Magnet"` | 実際の名前 | 実際の名前 | 実際の名前 | 実際の名前 |
| `files` | `[]` | 中身あり | 中身あり | 中身あり | 中身あり |
| `links` | `[]` | `[]` | `[]` | フェーズ中に埋まる | 中身あり |
| `ended` | キーなし | キーなし | キーなし | キーなし | あり |

`progress` は整数ではなく**浮動小数点数**です。キャプチャには 100 と並んで 0.4、0.8、1.4 もあります。整数に丸めたパーセントで停止を判定すると、100 GB のリリースが 1 MB/s で動いているだけなのに停止と判断されてしまいます。

`progress` は**わざと逆戻りします**。ステータスが `uploading` に変わると 0 にリセットされ、また 100 まで増えていきます。進行の判定は、単調増加するパーセントではなく、ステージの変化か progress の増加として定義する必要があります。

`seeders` は、トレントが `downloading` を出ると 0 になるのではなく、キーごと消えます。`speed` も同じです。マッパーは、キーがない場合を 0 ではなく不明として扱わなければなりません。

（以前の翻訳は却下されました：コードスパンが違っていました（`speed`）。構造はそのまま維持してください。）

### 各ケースの結果 {#what-each-case-did}

| ケース | トレント | 追加からの秒数付き遷移 | 結果 |
|---|---|---|---|
| キャッシュ済み | Big Buck Bunny | `downloaded`@0.0 | 最初から最後まで 1.32 秒で完了 |
| キャッシュ済み | Sintel | `downloaded`@0.0 | 0.73 秒で完了 |
| キャッシュ済み | Ubuntu 26.04.1 | `downloaded`@0.0 | 0.32 秒で完了 |
| 未キャッシュ | Debian 13.6.0 arm64 DVD-1 | `downloaded`@0.0 | このアカウントではすでにキャッシュ済み |
| 未キャッシュ | Debian 13.2.0 amd64 DVD-1 | `queued`@0.0 `downloading`@3.1 `uploading`@166.5 `downloaded`@196.8 | 完了。3.71 GiB を 197 秒で処理 |
| webseed | Prelinger home movie | `magnet_conversion`@0.0 `magnet_error`@318.0 | 失敗 |
| seedless | ubuntu-16.04.6-desktop-i386 | `queued`@0.0 `downloading`@3.1 `uploading` `downloaded`@166.8 | 完了。このケースは再現しませんでした |
| seedless | ubuntu-24.04-beta-live-server-s390x | `queued`@0.0 `downloading`@3.1 その後は何もなし | **907.6 秒で打ち切り、まだ `downloading` のまま**。これが停止時のパターンです |
| メタデータなし | ランダムな40桁の16進数 | `magnet_conversion`@0.0 `magnet_error`@317.9 | 失敗 |

### キャッシュ済み追加のレイテンシ {#the-cached-add-latency}

これは、シムのキャッシュ専用モードの土台になっている数値です。

| トレント | addMagnet の戻り値 | selectFiles の戻り値 | 最初の `/torrents/info` | ステータス |
|---|---|---|---|---|
| Big Buck Bunny | t=0 | t+1.211 s | t+1.318 s | `downloaded` |
| Sintel | t=0 | t+0.632 s | t+0.729 s | `downloaded` |
| Ubuntu 26.04.1 | t=0 | t+0.215 s | t+0.320 s | `downloaded` |

**観測結果。** キャッシュ済みのトレントは、`selectFiles` の後の最初の読み取りで `downloaded` になっています。同期的にかかるコストは、往復 2 回分だけです。`queued` の状態を経由することも、`downloading` の状態を経由することもありません。

2 回目の実行では、`addMagnet` と `selectFiles` の間の時間も含め、0.25 秒おきに `/torrents/info` を問い合わせました。`--rd-select-detail` はまさにこれをやるオプションで、これで流れの形がはっきりしました。

| トレント | `selectFiles` の前のステータス | `selectFiles` | その後の最初の読み取り | addMagnet から `downloaded` まで |
|---|---|---|---|---|
| Big Buck Bunny | `waiting_files_selection`（ファイル 3 件を表示、`links` は空） | t+1.314 s で 204 | `downloaded` `progress` 100 `links` 1 | **1.535 s** |
| Sintel | `waiting_files_selection`（ファイル 11 件を表示） | t+0.627 s で 204 | `downloaded` `progress` 100 `links` 1 | **0.841 s** |
| Ubuntu 26.04.1 | `waiting_files_selection`（ファイル 1 件を表示） | t+0.219 s で 204 | `downloaded` `progress` 100 `links` 1 | **0.430 s** |

つまりキャッシュ済みの流れ全体は `waiting_files_selection` のあと `downloaded` になり、その間に別の状態は入りません。ファイル一覧は `selectFiles` の前にすでにあります。`links` を埋めるのが `selectFiles` です。

**キャッシュ専用のプローブ待ち時間は、ポーリング 1 回分で足ります。** 123 MiB、264 MiB、6.04 GiB の 3 つのトレントで、端から端まで 0.43 秒から 1.54 秒でした。0.25 秒間隔のポーリングで 2 秒の待ち時間があれば、十分余裕があります。

Sonarr と Radarr が `torrents/add` の呼び出しに許している 100 秒（[qbittorrent-client-contract.md §1.7a](qbittorrent-client-contract.md) を参照）に比べれば、数秒のキャッシュ専用プローブ待ち時間は負担になりません。数十秒に設定する理由はありません。

### ステージマッパーが対処すべき癖 {#quirks-a-stage-mapper-has-to-survive}

- **`selectFiles` は、トレントがまだ `magnet_conversion` の間に 404 を返し、そのエラー内容は誤解を招きます。**
  本文は `{"error":"parameter_missing","error_code":1,"error_details":"{files} is missing"}` ですが、
  `files=all` を送っていた場合でもです。ファイルがまだ存在しないだけです。追加の失敗ではなく、トレントは生きたままです。
  これに当たった両方の実行は、さらに 318 s 生き続けました。
- **プライベートトラッカーのハッシュは、318 s 後ではなく即座に失格になることがあります。** 2026-08-31 の qBittorrent レポートにあったハッシュ（UNIT3D インデクサー由来の CiNEPHiLES リミックス、`45e1ec0d…`）は、addMagnet 直後の最初の読み取りで、ファイル 0 件の `magnet_error` を返しました。`magnet_conversion` の期間はまったくなく、追加からわずか数秒後でした。Real-Debrid がそのハッシュを認識したのか、すぐに失敗させたのかはわかりませんが、観測される結果は同じです。プライベートハッシュには DHT のスウォームがないため、addMagnet は決して成功しません。そして失敗したインスタンスに対する selectFiles は、上記の偽の 404 を返します。
- **`addTorrent` は、キャッシュされていないコンテンツに対しては何もスキップせず、キャッシュ済みのものに対してはすべてスキップします。** Real-Debrid が保持していないコンテンツ向けにアップロードした `.torrent`（archive.org の Big Buck Bunny。シードはされているがキャッシュはない）は、ただのマグネットと同じく `magnet_conversion` に入りました。ファイルのメタデータはメタデータ解決に使われていません。キャッシュ済みのもの（Ubuntu ISO）は、最初の読み取りでファイル一覧付きの `waiting_files_selection` を返し、選択後、2 秒以内に `downloaded` で完了しました。`magnet_conversion` はまったく通りませんでした。つまり、アップロードの価値は即座のハッシュ→キャッシュ検索にあります。これにより、プライベートトラッカーのリリースは、コンテンツがキャッシュされていれば追加でき、マグネットとしては決して追加できない、という状況が生まれます。
- **メタデータ解決は 318 s で諦めます。** 独立した 2 回の実行で、`magnet_conversion` から `magnet_error` へ、317.9 s と 318.0 s で移行しました。これは、到達可能なピアがないマグネットが当たる壁です。そのハッシュのトレントが存在するかどうかに関係なく、同じです。
- **`seeders` は `magnet_conversion` 中に嘘をつきます。** ランダムな 40 桁 16 進ハッシュが 80.9 s の時点で `seeders: 1` を報告しました。そのハッシュのトレントは存在しません。
- **キャッシュ済みの新規追加トレントの `ended` は古い日付を持ちます。** キャプチャには、2026-08-30 に追加されたトレントに対して `2025-12-28` と `2026-07-28` が入っています。これは Real-Debrid が最初にそのコンテンツを持った日付であり、このインスタンスが完了した日ではありません。この値から経過時間を計算しないでください。
- **ピアゼロのマグネットはメタデータ解決の段階で失敗し、webseed には到達しません。** Real-Debrid は、トレントを手に入れてしまえば webseed を尊重します。しかし、ピアのないマグネットからトレントを取得することはできません。そのため、webseed だけを持つアイテムをマグネットとして追加すると、`magnet_error` で終わります。これは webseed の失敗ではなく、メタデータの失敗であり、`/torrents/info` からは両者が同じに見えます。

---

## AllDebrid

### エンドポイント {#endpoints-1}

`v4` と `v4.1` は互換性がなく、今回の検証でその違いに痛い目を見ました。

```
POST /v4/magnet/upload      magnets[]=magnet:?xt=urn:btih:<hash>   -> 200, per-magnet `ready` flag
POST /v4/magnet/upload/file multipart files[]=<the .torrent>       -> 200, per-file `ready` flag
GET  /v4.1/magnet/status?id=<id>                                   -> 200, data.magnets is an OBJECT
GET  /v4.1/magnet/status                                           -> 200, data.magnets is a LIST
POST /v4/magnet/delete      id=<id>                                -> 200
```

**ファイルのアップロードの応答は `magnets` ではなく `files` の下に返ります。** 各エントリのフィールドは同じです（`id`、`hash`、`name`、`ready`、任意のエントリごとの `error`）。そのため、下の `ready` フラグはどちらの場合もキャッシュの回答になります。ただし magnet の応答用に書かれたデコーダーだと、空のリストとして読んでしまいます。

**そして、AllDebrid が swarm（ピア群）なしで説明できるリリースの形式は、ファイルとしてのアップロードだけです。** 2026-09-01 にテストアカウントで計測しました。同じ形の合成プライベート torrent を2つ使い、そのハッシュはどの swarm でも一度も見られたことがないものです。ファイルとしてアップロードすると、本来の名前とサイズが返ってきました（`"name":"zurg.private.ad.probe","size":65536`）。一覧では `In queue` と表示され、カウントはまだ動いていませんでした。`magnets[]` にハッシュだけを送ると、応答は `"name":"noname","size":0` でした。AllDebrid は受け付けはしましたが、その中身は何も知りませんでした。これはプライベートトラッカーのリリースをハッシュで追加したときと同じ状況です。

**`/v4/magnet/status` はもう使えません。** id の有無に関係なく、HTTP 200 で `{"status":"error","error":{"code":"DISCONTINUED"},"deprecated":true}` を返します。`/v4/magnet/upload` と `/v4/magnet/delete` は今も動きます。そのため、計画では「v4 のステータスエンドポイントを使い、比較用に v4.1 を一度だけサンプリングできる」と想定していましたが、これは逆でした。v4.1 が唯一のステータスエンドポイントです。ハーネスでは torrent ごとに v4 の読み取りを1回記録し、主張ではなく証拠がキャプチャに残るようにしています。

認証は `Authorization: Bearer <apikey>` です。`agent` パラメータは不要です。

### 観測されたステータス値 {#status-values-observed-1}

| `statusCode` | `status` | 確認済み |
|---|---|---|
| 0 | `In queue` | はい |
| 1 | `Downloading` | はい |
| 2 | `Compressing / Moving` | **いいえ** |
| 3 | `Uploading` | はい |
| 4 | `Ready` | はい |
| 5 以上 | エラーコード | **いいえ** |

### どのステータスでどのワイヤーフィールドが存在するか {#which-wire-fields-exist-in-which-status-1}

| フィールド | In queue (0) | Downloading (1) | Uploading (3) | Ready (4) |
|---|---|---|---|---|
| `status` / `statusCode` | あり | あり | あり | あり |
| `version` | 1 | 2 | 2 | 2 |
| `filename` | メタデータが届くまでは `"noname"` | メタデータが届いたら実際のファイル名 | 実際のファイル名 | 実際のファイル名 |
| `size` | メタデータが届くまでは 0 | 実際のサイズ | 実際のサイズ | 実際のサイズ |
| `downloaded` | 0 | **進捗の値（バイト単位）** | `size` と同じ値 | **なし** |
| `downloadSpeed` | 0 | あり（バイト/秒） | 0 | **なし** |
| `seeders` | 0 | あり | 0 | **なし** |
| `uploaded` / `uploadSpeed` | 0 | 0 | **そのフェーズの進捗の値** | **なし** |
| `processingPerc` | 0 | 0 | 0 | **なし** |
| `files` / `nbLinks` | なし | なし | なし | あり |
| `completionDate` | 0 | 0 | 0 | 設定される |

**パーセンテージの値はどこにもありません。** AllDebrid の進捗は `downloaded / size` で計算します。どちらもバイト単位の整数です。`processingPerc` は、すべてのキャプチャで、どの状態でも 0 のままでした。

`Uploading` は、AllDebrid が完了したダウンロードを自分のストレージへ移動している段階です。この段階には専用の進捗カウンターがあり、`uploaded` と `uploadSpeed` がそれを表します。この間、`downloadSpeed` は 0 のままです。`downloaded` だけを見てストール判定をすると、正常に動いている `Uploading` の段階をストールと誤判定してしまいます。

### 各ケースの結果 {#what-each-case-did-1}

| ケース | トレント | アップロード時の `ready` | 追加からの経過秒と状態遷移 | 結果 |
|---|---|---|---|---|
| キャッシュ済み | Big Buck Bunny | true | `Ready`@0.0 | 0.11 秒で完了 |
| キャッシュ済み | Sintel | true | `Ready`@0.0 | 0.12 秒で完了 |
| キャッシュ済み | Ubuntu 26.04.1 | true | `Ready`@0.0 | 0.11 秒で完了 |
| 未キャッシュ | Debian 13.6.0 arm64 DVD-1 | true | `Ready`@0.0 | すでにキャッシュ済み |
| 未キャッシュ | Debian 13.2.0 amd64 DVD-1 | false | `In queue`@0.0 `Downloading`@12.5 634.9 秒までカウンターがすべてゼロのまま `Uploading`@650.1 `Ready`@876.9 | 877 秒で完了 |
| webseed | Prelinger home movie | false | `In queue`@0.0 `Downloading`@6.3 その後はすべてのカウンターがゼロのまま | **907.8 秒で打ち切り、まだ `Downloading`** |
| seedless | ubuntu-16.04.6-desktop-i386 | false | `In queue`@0.0 `Downloading`@9.4 589.6 秒までカウンターがすべてゼロのまま `Uploading`@619.9 `Ready`@650.2 | 650 秒で完了 |
| seedless | ubuntu-24.04-beta-live-server-s390x | false | `In queue`@0.0 `Downloading`@3.2 その後はすべてのカウンターがゼロのまま | **907.0 秒で打ち切り、まだ `Downloading`** |
| nometa | ランダムな40桁の16進数 | false | `In queue`@0.0 `Downloading`@9.4 その後はすべてのカウンターがゼロのまま | **907.4 秒で打ち切り、まだ `Downloading`** |

未キャッシュの一連の流れを完全に捉えた、Debian 13.3.0 arm64 DVD-1（`6aa9b0a4709a0d6c4982fd0363614d9006877223`）の別の実行結果を、基準となるシーケンスとして使います。

| 秒数 | 状態 | 変化した内容 |
|---|---|---|
| 0.0 | `In queue` 0 バージョン 1 | `filename` は `"noname"` で `size` は 0 |
| 2.2 | `Downloading` 1 バージョン 2 | まだ名前もサイズもない |
| 4.3 | `Downloading` | `filename` と `size` が確定する |
| 6.5 から 55.1 | `Downloading` | `downloaded` が `size` まで増えていく。`downloadSpeed` は 110 MB/s 付近でピークに達する。`seeders` は 8 から 9 |
| 57.2 | `Uploading` 3 | `downloadSpeed` が 0 に下がる。`uploadSpeed` と `uploaded` が増え始める |
| 65.6 | `Ready` 4 | `files` と `nbLinks` が現れる。進捗フィールドの 6 つが消える |

65.6 秒で 3.72 GiB です。

### AllDebrid は、自前のインフラを待っているジョブについて進捗をまったく報告しない {#alldebrid-reports-no-progress-at-all-while-a-job-waits-for-its-own-infrastructure}

この発見がタイムアウトの設計を最も大きく変えるもので、信頼するまでに独立した2回の実行が必要でした。

`statusCode` 1 の `Downloading` は、アップロードから数秒以内に届きます。その後しばらくの間、AllDebrid は `downloaded` 0、`downloadSpeed` 0、`seeders` 0、`uploaded` 0、`uploadSpeed` 0、`processingPerc` 0 を報告します。さらに、すでに `size` と `filename` を正しく報告していた場合でも、それらを 0 と info hash に戻してしまいます。

| 実行 | すべてのカウンターが 0 のままだった時間 | その後の動き |
|---|---|---|
| Debian 13.2.0 amd64 DVD-1 | 12.5 s から 634.9 s までの **622 s** | 15 s で 3.71 GiB をダウンロードし、その後 `Uploading`、876.9 s で `Ready` |
| ubuntu-16.04.6-desktop-i386 | 9.4 s から 589.6 s までの **580 s** | 30 s で 1.56 GiB をダウンロードし、その後 `Uploading`、650.2 s で `Ready` |

どちらも最後まで完了しました。ただ、最初の10分間は1バイトの動きも報告されませんでした。

**10分間の「動きなし」タイムアウトだと、正常に動いている AllDebrid のジョブを中断してしまいます。** 提案されている `download_timeout_mins` のデフォルト 10 は、2回中2回ともこの待ち時間の中に入ってしまいます。そのため、タイムアウトを今より長くするか、`size` が 0 の AllDebrid `Downloading` を、タイマーの対象外になる独立したステージとして扱うかのどちらかが必要です。名前とサイズが消えるのは、AllDebrid がジョブを割り当て済みだがまだ開始されていない状態を示す合図で、失敗ではありません。

すぐに開始した実行と比べると、違いがよく分かります。Debian 13.3.0 arm64 DVD-1 は `In queue` から 6.5 s でバイトカウンターの実値が出ました。つまり、この待ち時間は固定の遅延ではなく、キューによる待ちだということです。

### `ready` フラグは本物のキャッシュ回答です {#the-ready-flag-is-a-real-cache-answer}

`/v4/magnet/upload` のレスポンスにある `ready` は、TorBox でもキャッシュ済みと判定されたすべてのハッシュで true、キャンペーンでダウンロードした 2 つのハッシュでは false でした。

AllDebrid には独立したキャッシュ確認の仕組みがないので、このフラグがキャッシュ情報のすべてです。zurg は現在、マグネットの追加とファイルアップロードの両方のパスからこの値を取り出し、`CacheKnown` を設定した状態で `MagnetResponse.Cached` として渡しています。これにより、回答できないバックエンドが「キャッシュなし」と誤判定されることはありません。

---

**`ready` が false の場合、そのマグネットはすでに追加されています。**
追加せずにハッシュがキャッシュ済みかどうかを AllDebrid に問い合わせる方法はありません。AllDebrid でキャッシュ済みのものだけを扱う処理では、キャッシュにない（miss した）マグネットを削除する必要があります。

## TorBox

### エンドポイント {#endpoints-2}

```
GET  /v1/api/torrents/checkcached?hash=<hash>&format=list
POST /v1/api/torrents/createtorrent      magnet=…&seed=3&allow_zip=false   -> {"success":true,"data":{"torrent_id":N}}
POST /v1/api/torrents/createtorrent      multipart file=<the .torrent>    -> the same shape; `detail` says whether it was cached
GET  /v1/api/torrents/mylist?id=<id>&bypass_cache=true
POST /v1/api/torrents/controltorrent     {"torrent_id":N,"operation":"delete"}
```

### 観測されたステータス値 {#status-values-observed-2}

`metaDL` `checking` `stalledDL` `stalled (no seeds)` `downloading` `processing`
`uploading (no peers)` `uploading` `cached`

`processing`、`checking`、`stalledDL` は **zurg の変換テーブル（`internal/torbox/types.go` の `normalizeStatus`）に含まれていません**。
この3つはすべてデフォルトの分岐に落ち、`downloading` として報告されます。

`checking` は、TorBox がハッシュを検証している状態ではなく、メタデータを待っている状態です。swarm が応答しない magnet は `metaDL` から `checking` に進み、そのまま留まります。ランダムな40桁の16進ハッシュは910秒の上限時点でもまだ `checking` で、ピアがゼロの Prelinger アイテムも911秒時点で同じでした。TorBox は Real-Debrid が318秒で諦めるようには、決して諦めません。

**`.torrent` をアップロードすると、その待ち時間はまるごと省略されます。プライベートトラッカーのリリースでは、これが違いのすべてです。**
上記のアカウントで2026-09-01に計測したところ、同じ合成プライベートトーレントを両方の方法で送りました。ハッシュとして送った場合は、`torrent_id` 付きで受け付けられ、その後 `checking` になります。`name` は素のハッシュ、`size: -1`、`files: null`、`eta: 8640000` です。これは TorBox が DHT にない swarm を探している状態で、上限に達するまでそれを続け、何も報告しません。

ファイルとして送った場合は、バイト列を multipart の `file` パートに入れて `POST /torrents/createtorrent` に送りました。3秒後に読み戻すと、トーレント自体の名前、実際のサイズ、`stalled (no seeds)` が返ってきます。誰も持っていないコンテンツは同じですが、今度は内容が説明されています。
重要なのはステージです。`size: -1` の `checking` は `StageResolvingMetadata` に対応し、作業中で何も結論できないことを示します。`stalled (no seeds)` は `StageStalledNoPeers` に対応し、qBittorrent エンドポイントがそれに基づいて動けます。キャッシュ済みのリリースは、同じ3秒以内に、ファイル一覧とともに100%の `done` として読み戻されました。
パートの名前は重要です。別の名前で送られたファイルは一切認識されず、エンドポイントは `MISSING_REQUIRED_OPTION`、"You must provide either a file or magnet link" と応答します。

（以前の翻訳は却下されました：コードスパンが異なっていました（` maps to `）。構造はそのまま維持してください。）

### どのステータスでどのワイヤーフィールドが存在するか {#which-wire-fields-exist-in-which-status-2}

TorBox は、どの状態でも同じキーの集合を送ってきて、値だけを変えます。そのため、3つのサービスの中では最も読みやすいです。
意味を運んでいるのは値のほうです。

| 状態 | `download_finished` | `download_present` | `cached` | `active` | `progress` | `eta` | `size` |
|---|---|---|---|---|---|---|---|
| `metaDL` | false | false | false | true | 0 | 8640000 | 0 |
| `checking` | false | false | false | true | 0 | 8640000 | **-1** |
| `stalledDL` | false | false | false | true | ごく小さい | 8640000 | 実際の値 |
| `stalled (no seeds)` | false | false | false | true | 0 | 8640000 | 実際の値 |
| `downloading` | false のあと **true** | false | false | true | 小数 | 秒 | 実際の値 |
| `processing` | **true** | **false** | false | true | 1 | 秒 | 実際の値 |
| `uploading (no peers)` | **true** | **false** | false | true | 1 | 2591994 | 実際の値 |
| `uploading` | true | **true** | true | true | 1 | 0 | 実際の値 |
| `cached` | true | true | true | false | 1 | 0 | 実際の値 |

フィールド名。計画では、これらはすべて未検証として挙げられていました。

| 内容 | TorBox のフィールド | 形式 |
|---|---|---|
| progress | `progress` | **パーセントではなく、1 に対する割合**です。`0.0793719` |
| seeders | `seeds` | 整数 |
| leechers | `peers` | 整数 |
| download rate | `download_speed` | 毎秒のバイト数 |
| upload rate | `upload_speed` | 毎秒のバイト数 |
| eta | `eta` | 秒。`8640000` は「不明」を表すプレースホルダーです |
| bytes fetched | `total_downloaded` | 整数 |
| swarm health | `availability` | 浮動小数点数。`uploading (no peers)` では **-1** になります |
| where the data is | `download_path` | データが存在するまでは null です |

`8640000` は 100 日です。TorBox が「わからない」ことを伝える方法です。
また、zurg の shim が報告する内容がないときに、今 Sonarr へ渡しているのと同じ定数でもあります。

### 各ケースの結果 {#what-each-case-did-2}

| Case | Torrent | `checkcached` | Transitions with seconds from add | Verdict |
|---|---|---|---|---|
| キャッシュ済み | Big Buck Bunny | true | `cached`@0.0 | 0.83 秒で done |
| キャッシュ済み | Sintel | true | `cached`@0.0 | 0.94 秒で done |
| キャッシュ please | Ubuntu 26.04.1 | true | `cached`@0.0 | 0.69 秒で done |
| キャッシュなし | Debian 13.6.0 arm64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@7.3 `downloading`@24.1 その後 **gone**@48.6 | 86.7% の時点で別の zurg に削除された |
| キャッシュなし | Debian 13.2.0 amd64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@13.8 `downloading`@27.8 `processing`@69.4 `downloading`@72.7 `uploading (no peers)`@83.1 その後 **gone**@86.7 | 別の zurg に削除された |
| webseed | Prelinger home movie | false | `metaDL`@0.0 `checking`@23.3 のあと何も遷移しない | **`checking` で 911.3 秒で頭打ち**。TorBox は webseed を使わなかった |
| シードなし | ubuntu-16.04.6-desktop-i386 | false | `metaDL`@0.0 `checking`@10.5 `downloading`@20.6 `processing`@184.4 その後 **gone**@200.4 | `processing` の段階で別の zurg に削除された |
| シードなし | ubuntu-24.04-beta-live-server-s390x | false | `metaDL`@0.0 `checking`@18.9 `stalled (no seeds)`@169.3 `downloading`@230.9 その後 **gone**@462.3 | 91.9 パーセントの時点で別の zurg に削除された |
| nometa | random 40-hex | false | `metaDL`@0.0 `checking`@10.2 のあと何も遷移しない | **`checking` で 910.3 秒で頭打ち** |

0.5 秒間隔のポーリングで別に実行した、Debian 13.5.0 amd64 netinst
(`58846860f0a766f8a42b0bb214d8c713fdf1b167`) は、途中で消えずに done まで到達しました。こちらを基準となる遷移として使ってください。

| 秒 | State | `download_finished` | `download_present` | `progress` |
|---|---|---|---|---|
| 0.0 | `stalledDL` | false | false | 0.000289735 |
| 16.3 | `downloading` | false | false | 0.0608651 |
| 54.8 | `processing` | **true** | **false** | 1 |
| 59.1 | `downloading` | **true** | **false** | 0.997972 |
| 64.4 | `uploading` | true | **true** | 1 |

754 MiB を 64.4 秒で取得。

最後の3行は2回読んでください。TorBox は、データが実際に揃う**約10秒前**に `download_finished` を true に、`progress` を 1 にしてしまいます。その後、直前に報告した値より低い progress の `downloading` に戻ります。正常なダウンロードでも、`progress` と `download_state` の両方が後退します。

---

## ステージ表 {#the-stage-table}

shim が話す stage の enum はこれです。
`resolving-metadata` `queued` `downloading` `stalled-no-peers`
`finalizing` `done` `failed`、それと unknown を表す空文字列です。

### Real-Debrid

| Raw `status` | Stage | Basis |
|---|---|---|
| `magnet_conversion` | `resolving-metadata` | **観測済み**。`bytes` が 0、`files` が空、`filename` がそのままの `"Magnet"` |
| `waiting_files_selection` | `queued` | `--rd-select-detail` を付けて **観測済み**。ファイルはすでに一覧に出ています。`links` は空 |
| `queued` | `queued` | **観測済み**。実際のサイズと名前はすでにわかっています。`seeders` と `speed` はありません |
| `downloading` | `downloading` | **観測済み** |
| `downloading` で `seeders` が 0 | `stalled-no-peers` | **観測済み**。92 回のポーリングの間、904 秒にわたって `progress` が 0、`seeders` が 0、`speed` が 0 でした |
| `compressing` | `finalizing` | **推定**。見たことはありません |
| `uploading` | `finalizing` | **観測済み**。進捗は 0 からやり直しになり、`seeders` は表示されなくなります |
| `downloaded` | `done` | **観測済み** |
| `magnet_error` | `failed` | `magnet_conversion` で 318 秒たった後に **観測済み** |
| `error` `virus` `dead` | `failed` | **推定**。見たことはありません |

### AllDebrid

| `statusCode` | Stage | Basis |
|---|---|---|
| 0 `In queue` | `queued` | **観測済み**。数秒ほど続きます。`filename` が `"noname"` のままで、`size` が 0 のこともあります |
| 1 `Downloading` with `size` 0 | `queued` | **観測済み**。`downloading` でも `stalled-no-peers` でもありません。AllDebrid がジョブを受け付けたものの、まだ開始していない状態です。2 回の試行では 622 秒と 580 秒待たされましたが、その後完了しました |
| 1 `Downloading` with a real `size` | `downloading` | **観測済み** |
| 1 `Downloading` with `seeders` 0 and `downloaded` flat | `stalled-no-peers` | **観測されておらず、安全に推定もできません**。下記を参照 |
| 2 `Compressing / Moving` | `finalizing` | **推定**。実際には見ていません |
| 3 `Uploading` | `finalizing` | **観測済み**。ここでは `uploaded` と `uploadSpeed` が進捗を示し、`downloadSpeed` は 0 です |
| 4 `Ready` | `done` | **観測済み** |
| 5 and above | `failed` | **推定**。実際には見ていません |

**AllDebrid には、停止を見分けられる特徴がありません。** AllDebrid がキューに入れたジョブと、AllDebrid 側で進められないジョブは、通信上では同じに見えます。どちらも `statusCode` は 1、`size` は 0、すべてのカウンターが 0 です。Prelinger のアイテムは、上限の 907.8 秒の間ずっとこの状態でした。ほかの 2 つのトレントも、それぞれ 10 分間この状態が続いたあとに完了しました。そのため、AllDebrid のレスポンスだけでは両者を区別できず、AllDebrid について停止と判定できるのは、時間経過に基づく判断だけです。

### TorBox

| Raw `download_state` | Stage | Basis |
|---|---|---|
| `metaDL` | `resolving-metadata` | **observed**。`size` は 0 で、`name` はハッシュと同じ |
| `checking` | `resolving-metadata` | **observed**。この間は `size` が **-1** になります。TorBox がハッシュ検証ではなく、torrent を待っている段階です。zurg の現在の表にはありません |
| `stalledDL` | `stalled-no-peers` | **observed**。zurg の現在の表にはありません |
| `stalled (no seeds)` | `stalled-no-peers` | **observed**。名前は大げさです。この状態のキャプチャ 2 件では `seeds` が 1 と 2 でした。zurg は現在これを `queued` にマッピングしています |
| `downloading` | `downloading` | **observed** |
| `processing` | `finalizing` | **observed**。zurg の現在の表にはありません |
| `uploading (no peers)` | `finalizing` | `download_present` が false のとき **observed** |
| `uploading` | `done` | `download_present` が true のとき **observed** |
| `cached` `completed` `seeding` | `done` | `cached` は **observed**。残りの 2 つは **inferred** |
| `expired` `reported missing` `failed` `error` `missingfiles` | `failed` | **inferred**。実際には見たことがありません |

**`download_finished` と `download_present` の組み合わせは、状態の文字列の代わりにはなりません。** `processing`、`uploading (no peers)`、そして `downloading` の一部は、どれも `download_finished: true` と `download_present: false` の組み合わせになります。この組み合わせは正常な finalizing の段階であり、死んだ torrent ではありません。下の注意点を参照してください。

---

## 測定できなかったこと {#what-could-not-be-measured}

- **シードなしの状況は、2つの候補のうち1つで再現しました。** どちらもトラッカーのピア数はゼロでした。
  ubuntu-16.04.6-desktop-i386 は、トラッカーが把握していない DHT 経由のピアが見つかったため、3つのプロバイダーすべてでダウンロードできました。ubuntu-24.04-beta-live-server-s390x は Real-Debrid 上で上限時間いっぱい停止したままで、上で述べた停止の観測結果がこれにあたります。トラッカーのスクレイプでピア数がゼロでも、それは弱い目安にすぎません。ケースには候補を2つ残しておきます。Real-Debrid は、どちらの候補についても結果にかかわらずメタデータを保持していました。また、最初の `queued` の読み取りで `bytes` と `filename` を正しく返しました。
- **Real-Debrid の `compressing` は一度も観測されませんでした。** 完了したすべての実行は、`downloading` から直接 `uploading` に移りました。
- **AllDebrid のステータスコード 2 は一度も観測されませんでした。** すべての取得で、1 から直接 3 に移りました。
- **どのプロバイダーも、独自のエラー状態までは確認できていません。** Real-Debrid の `error`、`virus`、`dead`、上のすべての AllDebrid のコード 4 より大きいもの、そして TorBox のすべての失敗状態は、未確認のままです。これらを発生させるには、FOSS の ISO ではなく、ブロックされている、感染している、または期限切れのコンテンツが必要です。
- **TorBox は、完了まで見届けられたことがほとんどありませんでした。** キャンペーンのトレント4件と追加の1件が、同じアカウントの別の zurg によってダウンロード途中で削除されました。下の注意点を参照してください。完了できたのは、そのプロセスが次にポーリングする前に終わった 754 MiB のイメージ1つだけです。

---

## 途中で見つかった危険な挙動 {#hazards-found-on-the-way}

### TorBox のアカウントで 2 つ目の zurg が正常なダウンロードを削除してしまう {#a-second-zurg-on-the-torbox-account-deletes-healthy-downloads}

別の zurg インスタンスが、同じ TorBox アカウントで読み込まれていました。その設定はこうです。

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

**5 つ**のプローブ用トレントが、正常にダウンロード中だったのに削除されました。これは両方の側で**確認済み**です。テストハーネスは各トレントが消えるのを見ていて、もう一方のインスタンスのジャーナルがその理由を記録していました。

```
Aug 30 12:43:26 zurg-host zurg: INFO manager Deleting torrent 86695315 because it encountered an error status: error
Aug 30 12:43:27 zurg-host zurg: DEBUG torbox Deleted TorBox torrent id=86695315
Aug 30 12:44:56 zurg-host zurg: INFO manager Deleting torrent 86695708 because it encountered an error status: error
Aug 30 12:47:41 zurg-host zurg: INFO manager Deleting torrent 86697191 because it encountered an error status: error
```

対象は `86695315` `86695708` `86697191` `86702627` `86704212` の 5 つです。どれにも同じ理由が付いていました。どれも壊れてはいませんでした。

原因は `internal/torbox/types.go` の `normalizeStatus` にある 2 つ目のルールです。

```go
if w.DownloadFinished && !w.DownloadPresent {
    return "error"
}
```

この組み合わせは、TorBox の通常の仕上げ段階です。0.5 秒間隔のキャプチャで時間を測れました。754 MiB のイメージでは、`download_finished` が true になってから `download_present` が true になるまでの間が **9.6 秒**でした。3.7 GiB のイメージでは少なくとも 17 秒あり、掃除処理がその間に走ってしまいました。もう一方の zurg は約 15 秒ごとにライブラリをポーリングしています。正常な TorBox のダウンロードが完了後も残るかどうかは、ほぼ五分五分です。

ここから 3 つのことが言えます。ユーザーが TorBox の UI で完了を見届けたダウンロードが、zurg のライブラリから消えることがあります。`delete_error_torrents` は、プロバイダーが壊れていると判断したトレントを削除する機能として文書化されていますが、ここではプロバイダーが問題ないと判断したトレントを削除していました。そして、このアカウントで TorBox を測定するものはすべて、この掃除処理と競合していることになります。

**ここでは修正しません。** フェーズ 0 は測定のみです。修正はステージの作業と一緒に行います。そこで `download_finished && !download_present` を `failed` ではなく `finalizing` として扱うようにします。

### AllDebrid のアカウントでは 2 つ目の zurg でも問題が起きなかった {#a-second-zurg-on-the-alldebrid-account-got-away-with-it}

このキャンペーンで使った AllDebrid のキーは、TorBox と同じ 3 つの sweep 設定を持つ別の zurg インスタンスにも読み込まれていました。

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

AllDebrid のプローブは 1 つも削除していません。理由は運ではなく、コードにあります。`internal/alldebrid/types.go` の `normalizeStatus` は、ステータスコードが 5 以上のものだけを `error` にマッピングしていて、`download_finished && !download_present` のような構造的なルールはありません。そのため、正常な AllDebrid のダウンロードが壊れているように読まれることはありません。TorBox のバグは、その余計なルールが 1 つあることが原因で、sweep 全般の問題ではありません。

Real-Debrid は例外です。テスト用アカウントを読み込んでいた zurg は他になく、何も sweep しておらず、邪魔するものもありませんでした。

### TorBox は未知の id への削除に HTTP 500 を返す {#torbox-answers-a-delete-for-an-unknown-id-with-http-500}

```
POST /v1/api/torrents/controltorrent  {"torrent_id":86695315,"operation":"delete"}
-> HTTP 500 {"success":false,"error":"DATABASE_ERROR","detail":"There was an error processing your request. Please try again later."}
```

`GET /torrents/mylist?id=<gone>` も同じ応答を返します。そのため、存在しなくなった torrent は、ステータスコードだけでは TorBox の障害と区別できません。zurg はこれを `account temporarily unavailable` と報告します。もう一方のインスタンスのジャーナルには、すでに削除された id の削除を 15 秒ごとに再試行している様子が表示されています。ハーネスは、削除に失敗した後に `mylist` に問い合わせ、存在しなくなった torrent を削除済みとして扱うことで、この問題を回避しています。

### Real-Debrid のスロットリングは現れなかった {#real-debrid-throttling-did-not-appear}

9件の追加を20秒間隔で行ったところ、キャンペーン全体で451も429も0件でした。これは、ルートの `CLAUDE.md` にあるメモ、つまり10秒間隔で6件追加したら0/6、同じ6件を20秒間隔にしたら6/6だった、という内容と一致します。20秒の下限はちゃんと効いているので、迷信ではありません。

---

## キャンペーンを再実行する {#re-running-the-campaign}

```bash
export RD_TOKEN=…   # a Real-Debrid test account
export AD_KEY=…     # AllDebrid test
export TB_KEY=…     # TorBox

# 1. check the catalog still resolves and the swarms are still what the tables claim
./scripts/torrent_lifecycle_probe.py --inspect-torrents

# 2. non-destructive. Confirms the cached/uncached split before anything is added
./scripts/torrent_lifecycle_probe.py --cache-probe

# 3. record what each account holds now, so step 6 has something to compare against
./scripts/torrent_lifecycle_probe.py --list

# 4. the campaign. One process per provider, each with its own output directory
for p in rd ad tb; do
  LIFECYCLE_OUTDIR=~/lifecycle/$p ./scripts/torrent_lifecycle_probe.py \
    --provider $p --case all --cap-mins 15 > ~/lifecycle/$p.out 2>&1 &
done

# 5. the two follow-ups the campaign cannot do
./scripts/torrent_lifecycle_probe.py --provider rd --case cached --rd-select-detail
./scripts/torrent_lifecycle_probe.py --provider tb --case adhoc --fast-poll 0.5 --fast-window 480 \
  --extra-hash 58846860f0a766f8a42b0bb214d8c713fdf1b167:debian-netinst

# 6. verify nothing was left behind
./scripts/torrent_lifecycle_probe.py --cleanup-only
./scripts/torrent_lifecycle_probe.py --list
```

Führ es von einem Rechner mit Residential-Egress aus. AllDebrid antwortet auf Datacenter-IPs mit `NO_SERVER`.

Schritt 6 ist nicht optional, und Schritt 3 ist der, der ihn erst sinnvoll macht. Nach der Kampagne vom 2026-08-30 war keine einzige der 34 Instanz-IDs, die das Harness beansprucht hatte, mehr auf einem der drei Accounts übrig. Auch keiner der neun Probe-Hashes.

Bevor du TorBox anfasst, prüf, ob ein anderer zurg mit demselben Account geladen ist. Lies dessen Sweep-Einstellungen und erwarte den oben beschriebenen Sweep.

```bash
grep -E "delete_error_torrents|stalled_download_mins|enable_repair" config.yml
```

Nie ändern. Ein Probe, der mitten im Run verschwindet, ist eine Information.
