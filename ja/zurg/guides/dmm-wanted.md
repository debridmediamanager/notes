# DMMから欲しいものを取り込む {#fetch-what-you-want-from-dmm}

[Debrid Media Manager](https://debridmediamanager.com) で映画や番組の **Want** を押すと、zurg が取得してくれます。Sonarr や Radarr を設定する必要も、マウントする必要もありません。
番組は放送されるたびに新しいエピソードも自動で取得されます。

これはスポンサー向けの機能です。zurg は、あなたの DMM API キーを使ってリストを読み取ります。

## 必要なもの {#what-you-need}

- zurg の 2026-10-25 以降のナイトリービルド。
- zurg の `config.yml` に DMM の API キーを入力します。スポンサーになると [gatekeeper](https://gatekeeper.debridmediamanager.com/) に表示されるキーです:

  ```yaml
  dmm_api_key: YOUR_DMM_API_KEY
  ```

- zurg が取得する先。torrent に対応した debrid アカウント、Usenet 用の `nzb` または `torbox_nzb` プロバイダー、もしくはその両方。

設定はこれで全部です。zurg は起動した瞬間から、1 分ごとにあなたのリストを読みに行きます。

## タイトルを追加する {#adding-titles}

1. DMM の [Settings](https://debridmediamanager.com/settings) ページに、同じキーを貼り付けます。
2. 映画を開いて **Want** を押します。シーズンのページでは、**Want S2** でそのシーズンを追加でき、**Want all seasons** でシリーズ全体を、今後追加されるシーズンも含めて追加できます。
3. あなたのリストは [debridmediamanager.com/wanted](https://debridmediamanager.com/wanted) にあります。zurg がリストを最後に読み込んだ時刻と、各映画を取得した時刻が表示されます。リストが長いときは、1 ページに 120 タイトルずつ表示されます。

Seerr、Overseerr、Jellyseerr からのリクエストも同じリストに入ることがあります。詳しくは [Seerr through DMM](../../dmm/seerr.md) を参照してください。

## リストをフォローする {#following-a-list}

[wanted リスト](https://debridmediamanager.com/wanted)に Trakt または MDBList のリストのページを貼り付けて、**Follow** を押してください。そのリストにあるすべての映画と番組が wanted になります。DMM は 6 時間ごとにリストを読み直すので、後からリストに追加されたものも wanted になります。対応しているページは次のとおりです:

- `https://trakt.tv/users/<user>/lists/<list>` と `https://trakt.tv/lists/<id>`
- `https://trakt.tv/users/<user>/watchlist`（その Trakt プロフィールが公開されている場合）
- `https://mdblist.com/lists/<user>/<list>`

DMM 自身の Trakt ページでは、ウォッチリストと自分の各リストに **Follow with Want** ボタンがあり、同じことができます。

IMDb、Letterboxd、Rotten Tomatoes、Plex のウォッチリストの場合: mdblist.com で、その URL から[外部リスト](https://docs.mdblist.com/docs/external_lists)を作成し、それをフォローしてください。MDBList が元のソースと同期を保ちます。

フォローすると次のようになります:

- 番組は丸ごと wanted になり、新しいシーズンも含まれます。
- 前回読み込んでから新しくリストに追加されたタイトルだけが追加されます。wanted リストから削除したタイトルは削除されたままになり、リストから外れたタイトルは wanted のままになります。**Unfollow** しても、リストが追加したものは残ります。
- ページには各リストについて、タイトル数、これまでに追加された数、最後に読み込まれた日時が表示されます。**Read again** を押すと、今すぐ読み直します。IMDb ID のないタイトルは除外され、その数も表示されます。
- wanted リストには、まだ取得していないタイトルを 10,000 件まで保持できます。対象は、すべての番組と、zurg がまだ取得していない、またはアップグレード待ちの映画です。zurg がすでに取得した映画はこの数に含まれません。入りきらないタイトルは、空きができたあとの次回の読み込みで追加されます。

## RadarrやSonarrから移行する {#moving-from-radarr-or-sonarr}

必要なものをすべて取り込みましょう。

1. RadarrまたはSonarrで、**System → Backup** を開き、**Backup Now** を押して zip をダウンロードします。`Backups` フォルダにある定期バックアップも使えます。
2. [ウォンテッドリスト](https://debridmediamanager.com/wanted) で **Import a Radarr or Sonarr backup** を押し、zip を選びます。もう一方のアプリのバックアップも同じように取り込んでください。

取り込まれるもの：

- Radarr からは、監視対象で、ファイルがなく、最低利用可能日に達している映画すべて。IMDb ID のない映画は除外され、その数はページに表示されます。
- Sonarr からは、監視対象で、放送済みのエピソードが欠けているシリーズすべて。欠けているシーズンだけが対象になります。
- リストにすでにあるタイトルはそのままです。

アップロードされるのは zip 内のデータベースだけです。API キーを含む、バックアップの残りの部分はお使いのコンピューターに残ります。

取り込まれないものが2つあります。

- **品質プロファイル。** zurg は、独自の [取得設定](acquisition.md#configuration) でリリースを選びます。Radarr は通常、カムやテレシンクのコピーを受け付けません。それらを除外するには、[`exclude_words`](acquisition.md#excluding-releases-by-name) に追加してください。

  ```yaml
  acquisition:
    exclude_words: [CAM, CAMRip, HDCAM, TS, HDTS, TELESYNC, TC, HDTC, TELECINE]
  ```

- **番号が異なる場合の Sonarr のシーズン番号。** リストではシーズンを TMDB の番号で数えています。Sonarr は TheTVDB に従うため、長期放送のアニメの一部をより多くのシーズンに分けています。そのため、TMDB に存在しない Sonarr のシーズンは取得されません。そのようなシリーズは DMM のページで確認し、不足しているシーズンに **Want** を押してください。

## zurgが取得するもの {#what-zurg-fetches}

- **1本の映画**を1回だけ取得します。その後、zurg が読むリストから外れます。`quality` で指定した解像度（`best` の場合は 2160p）より低い解像度で取得した映画は、リストに残ります。より良いコピーが出ると zurg はそれを取得し、以前取得したものを削除します。自分で追加したコピーは残ります。zurg の設定の `acquisition:` の下にある `upgrades: false` で、この動作をオフにできます。`/wanted` では、zurg が取得したものと、まだ待っている解像度が表示されます。ただし下記の解像度リストを使っている場合は除きます。
- **1080p と 4K の両方の映画**。たとえば 1080p のテレビで、4K のファイルがトランスコードされずに再生されるように両方欲しい場合です。2026-10-31 のナイトリービルド以降が必要です。zurg の設定で解像度を並べてください:

  ```yaml
  acquisition:
    quality: [1080p, 4k]
  ```

  すると zurg は、各解像度ごとに映画のコピーを1つずつ保持します。各コピーは、その解像度以下で最も良いリリースを選び、独立してアップグレードされるので、1080p のコピーが 2160p に変わることはありません。1080p より良いリリースがまだ出ていない間は、両方とも通常は同じリリースを選ぶため、ファイルは1つだけになります。`720p` も並べられます。シリーズは、最も高い解像度だけを書いた場合と同じように選ばれ、1コピーだけ取得されます。リストを追加する前に zurg が取得していた映画は、各解像度で再取得されます。zurg は以前のコピーを削除しないので、不要なら自分で削除してください。詳しいルールは [複数の解像度ごとのコピー](acquisition.md#a-copy-at-each-of-several-resolutions) にあります。
- **シリーズ**: 選んだシーズンで放送済みのすべてのエピソードを取得します。シーズン全体を1つにまとめたシーズンパックがあればそれを使い、まだ放送中のシーズンは1話ずつ取得します。シリーズを削除するまで、新しいエピソードを確認し続けます。スペシャルは取得されません。

リリースは、NZB として Usenet から、またはデブリッドアカウントにすでにキャッシュされているトレントから取得されます。キャッシュされていないトレントが追加されることはありません。インデクサーを設定していない場合、zurg は DMM 自身のインデクサーを検索します。品質、サイズ制限、避けたい単語、リリースに必要な音声と字幕の言語は、zurg の[取得設定](acquisition.md#configuration)で指定します。これはすべてのソースで共通です。

## KodiやPlexで視聴する {#watching-it-in-kodi-or-plex}

`__magic__` を有効にすると、zurg は取得したファイルをタイトルごとに振り分けて、
`__magic__/__movies__` と `__magic__/__shows__` に保存します。名前は Kodi と Plex が認識できる形式になります。
Movies ライブラリと TV ライブラリをこの 2 つのフォルダに向けてください。`magic.anime` も使う場合は、Anime ライブラリも `__magic__/__anime__` に向けます。詳しくは [`__movies__` and `__shows__`](magic.md#__movies__-and-__shows__-sorted-by-title) を見てください。

```yaml
magic:
  enabled: true
```

## 1つのキーで2つのzurg {#two-zurgs-on-one-key}

各 zurg が同じリストを読み込むので、2つ以上あると同じタイトルを2回ずつ取得してしまいます。リストは1つだけオンのままにして、ほかのものはオフにしてください:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

## 停止したとき {#when-it-stops}

もしスポンサーシップが切れたり、キーをリセットしたりすると、zurg は DMM がキーを拒否したことをログに記録し、1時間ごとに再度確認します。それまでに取得済みのものはライブラリに残ります。

詳しくは、acquisition リファレンスの [DMM wanted list](acquisition.md#dmm-wanted-list) をご覧ください。
