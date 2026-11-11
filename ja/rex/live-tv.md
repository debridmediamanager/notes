# rex でライブ TV を見る {#live-tv-with-rex}

rex は、アドオンのチャンネルを Plex Web と Plex for Android の **Live TV** に表示します。ガイドと What's On も使えます。チャンネルを選ぶと、すぐに再生されます。[rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) は、ライブスポーツ用サーバーと組み合わせてすぐに使えます。IPTV の M3U と XMLTV ガイドについては、[チュートリアル: IPTV アドオン](addon-iptv.md) を参照してください。

提供される機能:

- **ガイド。** 各チャンネルを番号付きで表示し、今放送中の番組と次の番組を示します。
- **What's On。** 今放送中の番組、これから始まる番組、今後公開される映画を表示します。
- **検索。** 番組名で検索すると、ライブラリだけでなく Live TV にも表示されます。
- **視聴。** チャンネルを選ぶとライブで再生されます。チャンネルは再開位置を保存せず、視聴済みにもなりません。
- **テレビ事業者のような番組表。** rex-live-sports は米国の番組表から始まります。番号が変わらない約 30 のスポーツ局（ESPN は 2、CBS は 7）、ESPN の試合スケジュール、そしてスロットチャンネル（`NFL 1`、`NBA 1` など）があります。スロットチャンネルは、その日の試合を開始前に一覧表示し、各試合をライブで再生します。英国とドイツの番組表もあります。
- **ライブラリにも表示。** チャンネルは専用の **Live Sports** ライブラリに残り、グループごとにコレクションに整理されます。

## 始める前に {#before-you-start}

| 必要なもの | 理由 |
|---|---|
| rex の nightly ビルドで、2026.11.02 以降のもの | ライブTV機能はそのビルドから入りました |
| [rex with your own app](any-source.md) の手順どおりに設定済みで、[動画の変換](any-source.md#converting-video-optional) も設定済み | rex は視聴中に各チャンネルを変換します（コピーなので負荷は軽いです） |
| rex を動かすマシンか自宅ネットワーク上のライブスポーツサーバー | rex-live-sports はチャンネルをそこから取得します |
| Docker | ステップ2 で live-sports を動かすのに使います。ほかの方法も [README](https://github.com/yowmamasita/live-sports-public) に載っています |
| rex を動かすマシンに Python 3.9 以降、`git`、`ffmpeg`、`ffprobe` | rex-live-sports は ffprobe で各チャンネルのストリームを確認し、ffmpeg でポスターを作ります |

## ステップ 1. rex をインストールして Plex アカウントに追加する {#step-1-install-rex-and-add-it-to-a-plex-account}

[rex を自分のアプリで使う](any-source.md) の手順に従ってください:

1. [ステップ 1. rex をインストールする](any-source.md#step-1-install-rex)。rex の LAN IP の調べ方も含みます。このページでは `192.168.1.20` と書いています。ご自身の IP アドレスに置き換えてください。
2. [ステップ 3. Plex アカウントに追加する](any-source.md#step-3-add-it-to-a-plex-account): 新しいアカウントに rex を登録し、自分のアカウントと共有します。
3. [動画の変換](any-source.md#converting-video-optional)

そこではステップ 2 と 4 は飛ばしてください。rex-live-sports はご自身のアプリです。

## ステップ 2. ライブスポーツサーバーを起動する {#step-2-start-a-live-sports-server}

**機能.** live-sports を実行すると、スポーツチャンネルを見つけ、そのうちどれが放送中かを数分ごとに確認します。

```bash
docker run -d --name live-sports --restart unless-stopped -p 8765:8765 ghcr.io/yowmamasita/live-sports:latest
```

**表示されるはずの画面.** ブラウザで `http://192.168.1.20:8765` を開くと、live-sports のダッシュボードが表示されます。各チャンネルの最初のチェックには数分かかります。

## ステップ 3. rex-live-sports をインストールする {#step-3-install-rex-live-sports}

**何をするか。** rex マシン上の `~/rex-live-sports` に rex-live-sports をダウンロードして、起動します。

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

`config.json` で `live_sports_url` を `http://192.168.1.20:8765`、`rex_url` を `http://192.168.1.20:32400` に設定します。そのあと:

```bash
mkdir -p ~/.config/systemd/user
cp ~/rex-live-sports/rex-live-sports.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-live-sports
journalctl --user -u rex-live-sports -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

`config.json` で `live_sports_url` を `http://192.168.1.20:8765`、`rex_url` を `http://192.168.1.20:32400` に設定します。そのあと:

```bash
python3 rex_live_sports.py
```

そのターミナルウィンドウを開いたままにしている間、動き続けます。
+++

**表示されるもの。** 次のような行が出ます:

```
INFO relay on http://127.0.0.1:9983/, live-sports at http://192.168.1.20:8765, rex at http://192.168.1.20:32400
```

live-sports の最初のチェックが終わるまでは、`live-sports lists no channel that plays yet` とログに出ます。その後、最初の同期で live-sports が持っている各ラインナップチャンネルのストリームをチェックします。30 チャンネルで約1分かかります。そして次のログが出ます:

```
INFO pushed 38 of 30 channels, 38 with their Live TV channel: ...
```

これは live-sports が持つ 30 のラインナップチャンネルに、その日試合のあるスロットを加えた数です。5分ごとに再び同期し、その日まだ確認していないチャンネルだけをチェックします。

## ステップ 4. ライブラリを共有して Live TV を開く {#step-4-share-the-library-and-open-live-tv}

**Live Sports** ライブラリは新しいので、まだ誰の共有にも入っていません。新しいアカウントでサインインした状態で、**Manage Library Access** ([rex を共有](sharing.md)) から、自分のアカウントの共有と、ほかの全員の共有の両方に追加してください。共有を受けたアカウントは、そのアカウントで Live TV を無効にしていない限り、Live TV を視聴できます。

次に、自分のアカウントで Plex アプリを開きます:

- **Plex Web**: サイドバーに **Live TV & DVR** があり、rex のライブラリもそこに表示されます。
- **Plex for Android**: 画面下部の **Live TV** タブを開き、上部で rex を選択します。**Live TV & DVR** も rex のライブラリと一緒に一覧に出ます。

**表示されるはずの内容。** 上部に **Guide** と **What's On** があります。ガイドには、各チャンネルが番号付きで、放送中の番組とともに並びます。番組を選んで **Watch Now** を押します。

## チャンネル、番号、番組表 {#channels-numbers-and-guides}

`config.json` でラインナップを指定します: `lineups/us.json` (そのままコピーしたもの)、イギリスやドイツの局なら `lineups/uk.json` または `lineups/de.json` です。ラインナップのチャンネルは、その番号に表示されます。実際に再生されるのは live-sports にあるそのコピーです。

米国の局は ESPN の番組表から試合の情報を取得します (`Chicago Bears at Seattle Seahawks`。キックオフから、そのスポーツの通常の試合時間分まで表示されます。対象は NFL、大学フットボール、NBA、NHL、MLB、欧州の主要リーグ、MLS、F1 です)。ESPN が扱うのは米国の放送局だけです。そのため、イギリスやドイツの局は代わりに [epgshare01](https://epgshare01.online/) で同じ名前のチャンネルの番組表を使います。どのチャンネルも試合の前後は同じ扱いになります。どの番組表にも載っていないチャンネルは、自分の名前を 6 時間ごとのブロックで表示します。

スロットは局の後に続きます。`NFL 1` から `NFL 10` は `700.1` から `700.10` に、`NBA 1` から `NBA 6` は `701.1` から並びます。その後に NHL、MLB、Soccer、F1 が続きます。その日の各試合は、そのスポーツの最初の空いているスロットに割り当てられます。そのため、試合が始まる前から番組表に表示されます。キックオフの 15 分前から試合が終わるまで、そのスロットには両チームの名前で見つかったライブスポーツのストリームが再生されます。試合と試合の間は、スロットには何も再生されません。スロットは、初めて試合を再生したときに表示されるようになります。

`config.json` で `"lineup": ""` とラインナップを空にすると、live-sports の `Live:` と `Sports` グループにあるすべてのチャンネルが代わりに表示されます。番号はグループごとに振られます。最初のグループは `100.1`、`100.2` となり、次のグループは `101.1` です。これは、チューナーや別のソースが使う低い番号とぶつからないようにするためです。live-sports が週に 1 回以上そのチャンネルを載せていれば、チャンネルは同じ番号を保ちます。Pluto TV のチャンネルには Pluto TV 独自の番組表が使われます。これらは、指定しない限り除外されます。含めたい場合は `"groups": ["Live:", "Sports", "Pluto:"]` と設定します。すべての設定は rex-live-sports の [README](https://github.com/debridmediamanager/rex-live-sports#settings) にあります。

## アップデート {#updating}

```bash
cd ~/rex-live-sports && git pull && systemctl --user restart rex-live-sports
```

macOSでは Ctrl+C で止めて、`~/rex-live-sports` で `git pull` を実行してから、もう一度起動してください。

## できないこと {#what-it-cannot-do}

・**録画はできません。** Plex Web と Plex for Android には録画ボタンが表示されません。
・**ガイドは名前で照合されます。** チャンネルが同じブランドの別フィードのガイドを取得してしまうことがあり、多くのイベントチャンネルにはガイドがありません。
・**スロットは名前に含まれるチームで試合のストリームを探します。** 別の名前のストリーム(`nfl ravens` など)は見つからず、どのストリームもない試合はガイドに載っても再生できません。
・**Plex は、エピソード番号のない番組を、どの TV ガイドでもそうするように映画として扱います。** そのため、一致した番組も What's On の映画に表示されます。
・**ライブTVは Plex Web と Plex for Android でテストしました。** 他の Plex アプリはまだ試していません。
・**rex-live-sports のアドレスに接続できる人は、誰でもこれを経由して再生できます。** `listen` は `127.0.0.1` のままにしてください。

既に持っているガイドで自分のチャンネルを追加したい場合は、[rex アドオンの作成](addons.md#live-tv)を参照してください。
