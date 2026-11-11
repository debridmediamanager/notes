# TorBox ホストの Usenet {#torbox-hosted-usenet}

`type: torbox_nzb`

TorBox Proプランを使うと、Usenetの部分はTorBoxが代わりに行います。zurgは
watchディレクトリにある`.nzb`ファイルをあなたのTorBoxアカウントに投稿します。
TorBoxが各リリースを取得し、修復して、ほかのTorBoxのダウンロードと同じように配信します。
zurgは、TorBoxが取得したものをマウント内でほかのものと並べて表示します。
ニュースサーバーのアカウントは必要なく、Usenetの記事をお使いのマシンでデコードすることもありません。

これは[TorBoxのニュースサーバー](torbox-news-server.md)ではありません。それは`nzb`バックエンド用のログインで、記事を自分で読み込みます。
詳しくは[Usenet](usenet.md)にあります。
また、`torbox`エントリーでもありません。そちらはあなたのtorrentを一覧表示するもので、
[TorBox](torbox.md)のページで説明しています。

## 必要なもの {#what-you-need}

- **Ein TorBox Pro-Abo.** Niedrigere Pläne unterstützen keine NZBs.
- **Dein TorBox-API-Schlüssel** von [torbox.app/settings](https://torbox.app/settings).
  Es ist derselbe Schlüssel, den ein `torbox`-Eintrag verwendet.
- **Eine aktuelle zurg-Nightly.** Nightlies setzen eine aktive Sponsorschaft voraus.
- **Ein normaler Host.** zurg+rex auf Android, ein Plex-Server auf deinem Handy, hat kein `torbox_nzb`-Backend. Auf einem Android-Gerät spielst du von TorBox gehostete NZBs stattdessen über DMM's TorBox Cast oder das Kodi-Addon ab.

## 設定する {#configure-it}

このエントリーは `token` を受け取ります。`nntp` ブロックはありません。`watchlist` は設定できません。NZB アカウントではトレントを追加できないためです。

```yaml
providers:
  - type: torbox_nzb
    token: YOUR_TORBOX_API_KEY
```

コンテナを新規インストールする場合は、まず API キーを `~/zurg/secrets/torbox` に保存してから、セットアップにそれを読み込ませてください。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox_nzb \
  --torbox-token-file /config/secrets/torbox
```

すでに `config.yml` があるインストールの場合は、`http://localhost:9999/config/` のダッシュボードにある **Add provider** を使い、`torbox_nzb` を選ぶこともできます。どちらの場合も、最後に zurg を再起動してください。

```bash
docker compose restart zurg
```

## NZB の取り込み方法 {#how-nzbs-get-in}

`nzb` エントリに届くものは、すべて同じ経路でこのエントリに届きます。DMM の TorBox アクションだけが zurg を経由しない例外です。

- **ウォッチディレクトリ。** 設定ファイルの横にある `nzbs/` にファイルを置いてください（ホストでは `~/zurg/nzbs/`、コンテナ内では `/config/nzbs/`）。zurg がそれを TorBox に送信します。
- **Sonarr と Radarr。** zurg の SABnzbd 互換エンドポイント経由で届きます。[Usenet 向けの Sonarr と Radarr](../guides/sonarr-radarr.md) を参照してください。
- **取得。** Newznab インデクサー、DMM Wanted、ウォッチリストからここに取得されます。[取得](../guides/acquisition.md) を参照してください。
- **Usenet 結果に対する DMM の TorBox アクション。** NZB を TorBox に直接送信します。リリース一覧には zurg にも表示されますが、zurg はそのための NZB を保持していません。そのため、TorBox が削除した後は、修復ボタンでは再取得できません。

TorBox が取得できない投稿は、失敗したダウンロードとして Sonarr や Radarr に報告されます。クライアントはそのリリースをブロックリストに入れて、再検索します。

## `nzb` との違い {#what-differs-from-nzb}

- **ニュースアカウントは不要です。** 同時接続数の設定も、プロバイダーの保持期間を考える必要もありません。TorBox 自身のスプールが、どの投稿を取得できるかを決めます。
- **ここでは記事をデコードしません。** TorBox がリリース全体を取得します。記事の取得、PAR2 修復、記事キャッシュ、記事チェックは関係ありません。デコード済みアーカイブのディスクキャッシュだけは使われます。取得が成功したかどうかは、TorBox が取得できたかで判断されます。
- **キャッシュは 30 日です。** 他の人がすでに TorBox で取得したリリースは、すぐに ready になります。TorBox は、キャッシュしてから 30 日たつとリリースを削除します。ダッシュボードの repair ボタンは、NZB をもう一度投稿して再取得します。そのため、ファイルは `nzbs/` に残しておいてください。zurg は自動で再投稿しません。TorBox は、無人での再ダウンロードを不正利用とみなすためです。
- **処理中の NZB 1 件につきスロットを 1 つ使います。** TorBox がまだ取得中の投稿は、プランのアクティブスロットを 1 つ占有します。同じキーの `torbox` エントリーは、そのトレントにも同じスロットを使います。
- **1 時間あたり 60 件の投稿までです。** TorBox は、キーごとに 1 時間で受け付ける新しい NZB の数がこれだけです。`nzbs/` に大量のファイルがある場合（初回起動時など）は、数時間かけて順に処理されます。

## インスタンスごとに NZB アカウントは 1 つ {#one-nzb-account-per-instance}

インスタンスには `nzb` のエントリか `torbox_nzb` のエントリのどちらか一方だけを指定できます。両方を指定すると `nzbs/` 内のすべてのファイルが両方に一覧されてしまいます。両方を動かしたい場合は、もう一方の種類に専用のインスタンスと専用の作業ディレクトリを用意してください。`dmm_api_key` を両方に設定している場合は、[片方の `dmm-wanted` ソースをオフにしてください](../guides/dmm-wanted.md#two-zurgs-on-one-key)。そうしないと、すべての Wanted タイトルが二度取得されてしまいます。どちらの構成も、Debrid アカウントと並べて使えます。

zurg の Stremio アドオンは、選んだ候補を、そのインスタンスに設定されている NZB アカウントへ投稿します。`torbox_nzb` を使うと、TorBox がすでに保持しているリリースは、ほかに待機中の NZB 投稿がなければアドオンの待ち時間内に再生が始まります。キャッシュされていないリリースは、先に TorBox 側で処理が完了している必要があり、プレイヤーが待てる時間より長くかかります。

## 正しく動いたか確認する {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox_nzb/test
ls /zurg_mnt/zurg/__all__/
curl -s http://localhost:9999/http/__torbox_nzb__/ | head
```

アカウントが1つだけの場合、そのアカウント用のフォルダーはマウントのルート一覧から外されます。
そのため、マウントでは同じファイルが `__all__` の下に表示されます。
ディレクトリー名は項目の名前に従い、名前が設定されていない場合は種類(type)になります。
