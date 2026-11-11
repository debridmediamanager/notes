# Bazarrで字幕を追加 {#subtitles-with-bazarr}

Bazarr は Sonarr や Radarr がインポートした作品の字幕を探して、それぞれの動画の横に保存します。zurg を使うと、動画も字幕も `__magic__` に置かれます。`__magic__` を指定した Plex や Jellyfin のライブラリは、字幕をディスク上の字幕と同じように読み込みます。rex も字幕メニューに **English (SRT External)** として表示します。

これを使うには、2026-10-24 以降のナイトリー版の zurg と rex が必要です。

以下の内容はすべて、2026-10-23 に、Radarr `6.3.0.10514`、現在の `lscr.io/linuxserver/bazarr` イメージ、その日の zurg と rex、そして Real-Debrid アカウントを使ってテストしました。

（以前の翻訳は、コードスパンが一致しないという理由で差し戻されました。構造はそのまま維持してください。）

## 始める前に {#before-you-start}

Radarr（または Sonarr）が、ルートフォルダーを `__magic__` 内に置いた状態で、すでに zurg 経由でインポートできている必要があります。例：`/mnt/zurg/__magic__/movies`（macOS では `/Volumes/Zurg/__magic__/movies`、Windows では `Z:\__magic__\movies`）。まだの場合は、先に [torrent 向けの Sonarr & Radarr](sonarr-radarr-torrents.md) か、[Usenet 向け](sonarr-radarr.md) の手順に従ってください。

## 1. Bazarrを起動 {#1-run-bazarr}

Linux ホストでは、Radarr と同じボリュームを Bazarr にも渡してください。そうすると両方が同じパスで映画を見るので、パスマッピングは不要です:

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./bazarr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6767:6767
    restart: unless-stopped
```

マウントしている先ではなく、zurg のマウントの **1つ上** のフォルダ（`/mnt/zurg` を含む `/mnt`）をバインドしてください。マウントそのものをバインドしたコンテナは、zurg を再起動すると古いマウントが残ってしまい、すべての読み取りで `Socket not connected` が返ります。理由は [torrent ガイドの Docker の手順](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)に書かれています。`PUID` と `PGID` の扱いは Whisparr と同じように注意してください: [こちらを参照](whisparr.md#2-run-whisparr)。

macOS と Windows では、この compose ファイルは使えません。理由は [Usenet ガイドのステップ8](sonarr-radarr.md#8-if-your-arr-is-in-docker)に書かれています。その場合は、Radarr や zurg と同じマシンで、zurg と同じユーザーとして、ソースから Bazarr を起動してください（`python bazarr.py`）。手順は Bazarr 公式の [macOS](https://wiki.bazarr.media/Getting-Started/Installation/MacOS/macos/) と [Windows](https://wiki.bazarr.media/Getting-Started/Installation/Windows/source/) のページに従ってください。Windows では Bazarr のインストーラーは使わないでください。インストーラーは Bazarr を Windows サービスとして設定しますが、サービスからは zurg の `Z:` ドライブが見えません（[理由](sonarr-radarr.md#before-you-start)）。代わりに、ログイン中の自分のセッションから `bazarr.py` を起動してください。そうすると Radarr が報告するパスで各映画が見えるので、パスマッピングは不要です。上記の Docker イメージだけが動作確認済みです。

`http://<your server>:6767` を開いてください。

## 2. RadarrとSonarrに接続 {#2-connect-it-to-radarr-and-sonarr}

**Settings → Radarr**: オンにして、Radarr のアドレス、ポート、API キーを入力します（Radarr の **Settings → General** にあります）。コンテナの中から使う場合は、`localhost` ではなくホストの LAN IP を使ってください。**Test** を押してから **Save** を押します。Sonarr も **Settings → Sonarr** で同じように設定できます。

## 3. 言語 {#3-languages}

**Settings → Languages**: 言語を追加して、それらを使って言語プロファイルを作り、映画用とシリーズ用の両方のデフォルトプロファイルに設定してください。そうすると、Bazarr は Radarr と Sonarr がすでに持っているすべてのコンテンツについて字幕を要求します。

## 4. プロバイダー {#4-providers}

**Settings → Providers**: 字幕サイトのうち、Bazarr が検索するものを追加します。アカウントが必要なものもあれば、不要なものもあります。テストで遭遇した点が 2 つあります。

- **subf2m** は、プロバイダー設定で User-Agent を入力する必要があります。入力しないと、最初の検索で Bazarr がこのプロバイダーを 12 時間停止します。
- Bazarr は、一定時間失敗したプロバイダーを一時停止します。すべてのプロバイダーが停止していると、検索は何も見つけられません。**System → Providers** で停止中のプロバイダーを確認し、リセットできます。

## 5. 埋め込み字幕 {#5-embedded-subtitles}

多くのリリースには、動画ファイルの中にすでに英語のトラックが入っています。Bazarr はそれを英語があるとみなし、字幕は何もダウンロードしません。それでも字幕ファイルがほしい場合は、**Settings → Subtitles** で **Use Embedded Subtitles** をオフにしてください。

## 6. 1つ確認 {#6-check-one}

Bazarr の **Movies** ページには、各映画で何の字幕が不足しているかが表示されます。そのページから検索すると、字幕が動画の隣に保存されます（Windows では、エクスプローラーで `Z:\__magic__\movies` の同じフォルダを確認してください）:

```bash
$ ls "/mnt/zurg/__magic__/movies/Night of the Living Dead (1968)/"
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.en.hi.srt
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.mkv
```

字幕は zurg のディスク上にある実際のファイルで、`data/local/__magic__/` に置かれます（[サイドカー](magic.md#sidecars-nfo-posters-subtitles) を参照）。動画は引き続きアカウントからストリーミングされます。

## rexでは {#in-rex}

zurg は、Radarr や Sonarr が動画を移動させた先がどこであっても、`__magic__` 内で動画の隣にあるすべての字幕を rex に送ります。zurg は 1 分ごとに新規・変更・削除された字幕を確認します。そのため、Bazarr が保存した字幕は約 1 分以内に rex に表示され、削除した字幕も同じくらい素早く消えます。

設定は、zurg の設定で `rex_url` を指定するだけで済みます。これは [rex ガイド](../../rex/with-zurg.md) で既に設定しているはずです。

Plex が字幕名を読むのと同じように、ファイル名で字幕の種類が決まります:

| ファイル名の末尾 | rex での表示 |
|---|---|
| `.srt` | Unknown (SRT External) |
| `.en.srt` | English (SRT External) |
| `.en.forced.srt` | English Forced (SRT External) |
| `.en.hi.srt`, `.en.sdh.srt`, `.en.cc.srt` | English SDH (SRT External) |

`.srt`、`.ass`、`.ssa`、`.smi`、`.txt` のファイルが読み込まれます。

言語は 2 文字または 3 文字のコード（`en`、`eng`、`de`、`ger`）で指定できます。その前の名前は、Bazarr が書き込む形式の動画自体の名前と一致している必要があります。

rex に送られるのは `__magic__` 内の字幕だけです。`/mnt/zurg/movies` など、zurg の別のフォルダ内にあるファイルの隣に保存された字幕は送信されません。

rex は字幕を自分で検索することもできます。どの Plex アプリでも **Search Subtitles** を使えば、Bazarr は一切不要です。詳しくは [rex の字幕](../../rex/with-zurg.md#subtitles) をご覧ください。
