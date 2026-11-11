# rex でKometa を使う {#kometa-with-rex}

[Kometa](https://kometa.wiki) はコレクションを作ったり、ポスターにバッジ（4K、HDR、評価など）を付けたり、Plex サーバー上で評価やジャンルを補完したりします。rex は Plex サーバーと同じように Kometa に応答するので、同じ設定が rex のライブラリでもそのまま使えます。

以下の内容はすべて、Kometa 2.5.3（`kometateam/kometa` Docker イメージ）と、映画とシリーズを入れた claim 済みの rex を使って 2026-10-23 にテストしたものです。

## 始める前に {#before-you-start}

| 必要なもの | 理由 |
|---|---|
| rex をセットアップして Plex アカウントに追加済みであること([Plex アカウントに追加する](any-source.md#step-3-add-it-to-a-plex-account)を参照) | Kometa はライブラリを編集しますが、それができるのは rex が登録されているアカウントだけです。どのアカウントにも登録されていない rex は誰にも使われません |
| rex nightly **2026.10.24 以降** | [rex の Updating セクション](any-source.md#updating)の手順で更新してください |
| rex にアクセスできる任意のマシンの Docker | Kometa はコンテナとして動きます。Kometa の公式ドキュメントには[その他のインストール方法](https://kometa.wiki/en/latest/kometa/install/overview/)も載っています |
| 無料の TMDb API キー | rex には不要ですが、Kometa 自身が必要とします。themoviedb.org の **Settings → API** から作成できます。手順は [TMDb の getting started ページ](https://developer.themoviedb.org/docs/getting-started)に書かれています |

## 1. rex のトークンを取得 {#1-get-rexs-token}

Kometa は Plex トークンを使って rex にサインインします。rex を登録したときに渡されたトークンを使ってください。rex を動かしているマシンで:

+++ Linux と macOS
```bash
grep -o '"token": "[^"]*"' ~/rex/claim_state.json
```
+++ Windows
```powershell
(Select-String '"token": "[^"]*"' $HOME\rex\claim_state.json).Matches.Value
```
+++

[Docker で rex を動かしている](any-source.md#run-rex-in-docker)場合、ファイルは root しか読めません。そのときは `sudo grep -o '"token": "[^"]*"' ~/rex/config/claim_state.json` を使ってください。

**表示されるもの。** `"token": "..."` という行が 1 つ出ます。2 番目の引用符のペアの間にある文字列をコピーしてください。これはパスワードと同じように扱ってください。サーバー全体を操作できてしまうからです。rex をもう一度登録すると値が変わるので、そのときは Kometa に新しいトークンを設定し直す必要があります。

**自分のアカウントのトークンではないものを使わないでください。** [自分のアカウントで共有する](any-source.md#share-it-with-your-own-account)手順では、自分のアカウントに rex が共有として渡されています。共有は見るだけで編集はできないので、そのトークンを使うと Kometa は `Plex Token is read only` で止まります。共有でダウンロードが許可されている場合は、最初の変更で失敗します。

## 2. Kometa の設定を書く {#2-write-kometas-config}

`~/kometa/config`（Windows では `$HOME\kometa\config`）のような Kometa 用フォルダを作って、その中の `config.yml` に次の内容を入れてください:

```yaml
libraries:
  Movies:
    collection_files:
      - default: genre
    overlay_files:
      - default: resolution
      - default: ratings
        template_variables:
          rating1: critic
          rating1_image: tmdb
    operations:
      mass_critic_rating_update: tmdb
  TV Shows:
    overlay_files:
      - default: resolution
plex:
  url: http://192.168.1.20:32400
  token: the token from step 1
tmdb:
  apikey: your TMDb API key
```

- `url` は rex の LAN IP とポートです。[rex をインストールする](any-source.md#step-1-install-rex) の手順にあるアドレスを使ってください。`127.0.0.1` や `localhost` は使わないでください。Kometa のコンテナの中では、それらはコンテナ自身を指してしまうからです。
- `libraries:` の下の名前は、rex のライブラリ名と完全に一致させる必要があります。**Movies** と **TV Shows**、それに追加したり名前を変えたりしたライブラリがあれば、それも入れてください。Kometa に触ってほしくないライブラリは省いてください。

これは小さなスタートです。Kometa のドキュメントには[デフォルトのコレクションとオーバーレイの一覧](https://kometa.wiki/en/latest/defaults/guide/)が載っていますし、自分で作ったコレクションファイルも使えます。

## 3. 一度実行する {#3-run-it-once}

+++ Linux と macOS
```bash
docker run --rm -v ~/kometa/config:/config kometateam/kometa:latest --run
```
+++ Windows
```powershell
docker run --rm -v "$HOME\kometa\config:/config" kometateam/kometa:latest --run
```
+++

`--run` を付けると、Kometa は今回だけ一度実行して終了します。付けないと、Kometa は起動したままデイリースケジュールを待ちます。

**実行結果の見方。** Kometa の出力では、ライブラリごとに次のような行が表示されます:

```
Movies Library Connection Successful
...
Overlays Applied: Overlay File (0) 1080P, Overlay File (1) Rating1Fresh
```

Plex アプリでは、映画ライブラリに **Collections** タブがあり、ジャンル別のコレクションが並んでいます。ポスターにはバッジも付いています。自分のアカウントも、rex を共有している他の人も、同じコレクションとバッジが見えます。大きなライブラリでの初回実行は時間がかかります。Kometa はすべてのタイトルを読み込み、バッジを付けたポスターを全部描き直すためです。

## うまくいかない場合 {#if-it-does-not-work}

| Kometaの表示 | 意味 |
|---|---|
| `Plex Token is read only. Please get a new token` | rexがまだPlexアカウントに追加されていない、またはトークンが手順1のものではなく、自分のアカウントのものである |
| Kometaには接続できるが、すべての変更が失敗する | トークンが自分のアカウントのものです。手順1のものを使ってください。 |
| `url_poster failed to update poster` | rexのマシンが、画像のあるサイトに接続できない |
| `Plex URL is probably invalid` またはタイムアウト | Kometaを実行している場所から`url`でrexに届きません。そのマシンで`http://192.168.1.20:32400/identity`を開いてください。rexの`machineIdentifier`が表示されるはずです。 |
| `Plex Error: Plex Library '...' not found. Options: [...]` | `libraries:`の下の名前が一致していません。表示されたリストから名前をコピーしてください。 |

それでも解決しない場合は、[Discord](https://discord.com/invite/7u4YjMThXP)の**rex-support**フォーラムで質問してください。何を含めればよいかは[サポートの頼み方](../guides/remote-help.md)に書いてあります。

## Kometa が見えるものと見えないもの {#what-kometa-can-and-cannot-see}

Kometa は、rex が表示する TMDb、TVDb、IMDb の ID を使ってタイトルを照合します。ソースが識別できなかったタイトル、つまりファイル名がそのまま表示されていてポスターがないものには ID がないため、Kometa はそれらを ID から作るコレクションには含めません。まず Plex アプリで Fix Match を実行してください。

rex でテスト済みの項目は次のとおりです。タイトル検索と TMDb ID によるコレクション、スマートコレクション、ポスター付きのジャンルのデフォルトコレクション、解像度と評価のオーバーレイ、TMDb からの批評家評価とジャンルの更新。

まだテストしていない項目は、プレイリスト、音楽ライブラリ、Kometa のその他の操作です。もし何かが失敗したら、Kometa 自身のログに失敗したリクエストの名前が出るので、それを Discord で報告していただけると助かります。
