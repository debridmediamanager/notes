# Offcloud

`type: offcloud`

Offcloud は cloud explore エンドポイントを通じてファイルハンドルを解決します。ファイルサイズは一覧の値を信用するのではなく、配信サーバー側で確認されます。キャッシュされた torrent のメタデータは、曖昧さなく一致できる場合に限り、フォルダのパスを提供します。

## APIキーを取得する {#get-the-api-key}

ログインして、[offcloud.com/#/account](https://offcloud.com/#/account) を開きます。API キーはそのページにあります。

## 設定する {#configure-it}

```yaml
zurg: v1
providers:
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
mount_path: "/zurg_mnt/zurg"
```

まっさらなコンテナにインストールしたときは、セットアップに任せて書き込んでもらいましょう。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider offcloud
```

すでに `config.yml` があるインストールでは、`http://localhost:9999/config/` のダッシュボードで **Add provider** を使うか、ファイルを直接編集してください。どちらの場合も、最後に再起動してください。

```bash
docker compose restart zurg
```

`OFFCLOUD_TOKEN` は `zurg setup` で読み込まれますが、実行中のデーモンでは読み込まれません。

## エントリごとに認証情報は1つ {#one-credential-per-entry}

Offcloudのファイルハンドルは、それを一覧表示したアカウントに紐づいています。ローテーションできる2つ目のキーはありません。`download_tokens`は拒否されますし、`token`と異なる`strm_link_token`も拒否されます。2つ目のアカウントを使いたい場合は、独自の`name`を持つ別のエントリを追加してください。

```yaml
providers:
  - type: offcloud
    name: oc-main
    token: FIRST_OFFCLOUD_API_KEY
  - type: offcloud
    name: oc-second
    token: SECOND_OFFCLOUD_API_KEY
```

## ここで使えるもの {#what-works-here}

ライブラリの閲覧、ストリーミング読み込み、リダイレクト読み込み、STRM、マグネットの追加、`.torrent` のアップロード、削除はすべて動作します。アカウントごとに専用の `__offcloud__` ディレクトリが作られます。

## 知っておきたい制限 {#limits-worth-knowing}

**同時 API リクエストは 8 件までです。** マルチボリュームのアーカイブでは、4 つのボリュームを同時に解決します。

**コンテンツは期限切れになります。** 消えてしまったリリースは、壊れているのではなく想定どおりの状態です。Repair は、頼まない限りそのリリースには触れません。

**torrent の一覧にはファイルの詳細が含まれていません。** そのため、初回はリリースごとに個別の問い合わせが必要になります。

**ファイル一覧が曖昧な場合は、推測せずエラーにします。** キャッシュされた torrent のメタデータが、ひとつのリリースに一致しないことがあります。その場合、別のものに属しているかもしれないフォルダーパスを選ぶのではなく、zurg がそれを報告します。

**不正な magnet はローカルで拒否されます。** サービスには送られません。不正な magnet でも、コストはかかりません。

Offcloud が返す失敗の種類は少ないです。`NOAUTH` が、zurg が対応できる唯一のコードです。これは認証情報が拒否されたことを意味します。それ以外のエラーは、理由のない拒否として返ってきます。

## 正しく動いたか確認する {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/offcloud/test
ls /zurg_mnt/zurg/__all__/ | head
```

アカウントが1つだけの場合、そのアカウント専用のフォルダはマウントのルート一覧から除外されるため、同じファイルが `__all__` の下に表示されます。

## うまくいかないとき {#when-it-goes-wrong}

**`NOAUTH` がログに出る。** キーが無効化されたか、再生成された可能性があります。[offcloud.com/#/account](https://offcloud.com/#/account) で新しいキーを取得して、エントリを更新してください。

**`API refused request` だけが出る。** Offcloud は理由を教えてくれていません。zurg が原因だと決めつける前に、ブラウザでアカウントを確認してください。

**リリースにフォルダが表示されない。** キャッシュされた torrent のメタデータを、1 つのリリースに一致させられませんでした。ファイル自体はストリーミングできます。ただ、フラットに並んでいるだけです。

**生成された URL は、持っている人なら誰でも使える。** 配信 URL は、キャッシュの期限が切れたときや、読み込みで無効になったときに更新されます。消費されるクォータはアカウント自身のものです。URL と `.strm` へのアクセスは非公開にしておいてください。
