# 変更履歴 {#changelog}

## zurg が Sonarr 向けにアニメ、毎日放送の番組、スペシャルを見つけるように {#zurg-finds-anime-daily-shows-and-specials-for-sonarr}

Sonarr のソースは、これまで毎日配信の番組、アニメ、スペシャル（特別編）をスキップしていて、それぞれ警告を1件ずつ出していました。今では、毎日配信番組の欠けているエピソードは放送日（`The Daily Show 2026.11.03`）で、アニメは作品側が数えている番号（`Jujutsu Kaisen 30` は2期の6話目）で、スペシャルはシーズン `00` として、通常のシーズンとエピソードによる検索と並べて問い合わせられます。どのリリースがどのエピソードかは、どの番組でもそうであるように Sonarr 自身のパーサーが判断し、品質プロファイルは以前と同じように評価します。

アニメや毎日配信番組向けに配置される動画は `JUJUTSU KAISEN - S02E06 - <the release's own name>` の形式で名付けられます。Sonarr の再スキャンはファイル名だけを見てファイルを振り分けるため、`2nd Season - 06` のままだとシーズン1に入ってしまうからです。通常のシリーズとスペシャルの動画は、元の名前のままです。スペシャルは **Specials Folder Format** で指定されたフォルダに入ります。一致するのは `S00Exx` と名付けられたリリースだけです。詳しくは [zurg が Sonarr に何を問い合わせるか](../guides/acquisition.md#what-zurg-asks-sonarr-for) を参照してください。

## 見たい映画を 1080p と 4K の両方で保持 {#keep-a-wanted-film-at-1080p-and-at-4k}

`quality: [1080p, 4k]` in the `acquisition:` block keeps two copies of each film on your DMM wanted list, so a 1080p TV can play one without transcoding the 4K file. Each copy takes the best release at or below its own resolution and upgrades up to it on its own. While nothing better than 1080p is out, the two share one copy. Shows, and every other source, still get one copy. See [a copy at each of several resolutions](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

## one-line install の後でも zurg update が動くように {#zurg-update-works-after-the-one-line-install}

一行インストーラーは、GitHub CLI を使ってGitHubへのサインインを行います。インストーラーはそのために GitHub CLI をダウンロードし、作業が終わると削除します。すると `zurg update` は GitHub CLI を探しても見つからず、サインインが保存されているにもかかわらず、"no GitHub credential found" と表示して止まってしまいました。Ubuntu 付属の GitHub CLI は古すぎて、サインイン情報を引き渡せません。そのため Ubuntu でも同じように更新が止まっていました。

`zurg update` は、zurg の隣の `bin` にインストーラーが置いた GitHub CLI も使うようになりました。GitHub CLI がキーリングなしで保存したサインインは、CLI 本体が消えていても使えるようになります。それでも見つからない場合は、問題を解決するコマンドを 1 つ表示します。インストーラーの更新を一度実行すれば、以降の `zurg update` は自動でサインインします。

## 古い Real-Debrid リンクが一斉に切れても、もうoutage とは呼ばれなくなりました {#many-old-real-debrid-links-failing-at-once-is-no-longer-called-an-outage}

Real-Debrid のリンクは作成から数か月たつと動かなくなるので、同じころに追加されたリリースも同じころに再生できなくなります。1回の修復パスで5件を超えて失敗すると、zurg は "suspected provider-wide outage" とログに残し、5件を除く残りの修復を保留していました。そのため大量のバッチがずっと壊れたままになり、Real-Debrid がダウンしているように見えていました。今の zurg は、まず同じアカウントで再生できるリリースがないか Real-Debrid に問い合わせます。再生できれば、失敗したリンクが単に古いだけなので、すべてのリリースを通常どおり修復します。Real-Debrid が動くリンクも拒否した場合にのみ、zurg は障害とみなして待機します。

## ダッシュボードの Emby セッションのリンクが Emby のダッシュボードを開くように {#the-dashboards-emby-session-links-open-embys-dashboard}

ダッシュボードのEmbyパネルにある "active sessions" と "transcodes" のリンクが、`/web/#/dashboard` を開いていました。これはJellyfinがそのページに使うアドレスで、Embyはそこでスプラッシュ画面のまま止まってしまっていました。両方のリンクは、Embyが自分で使っている `/web/index.html#!/dashboard` を開くようになりました。Jellyfinパネルのリンクは変更していません。

## 不足している .nfo があっても Usenet のリリースを repair に回さないように {#a-missing-nfo-no-longer-sends-a-usenet-release-to-repair}

古い Usenet の投稿では、.nfo ファイルが最初に失われることがよくあります。その間も動画やアーカイブの各パートはすべて残っています。zurg はそのような .nfo を見つけると、それをリリース全体の破損として扱っていました。そのため、.nfo を見つけるたびに修復を開始し、再起動するたびに同じことが繰り返されました。本当に必要な修復は、無意味な修復が何百件も終わるまで待たされていました。再生できていたリリースの中にも修復不可能とマークされたものがあり、元に戻す唯一の方法は .nfo を削除することでした。

動画のそばにある .nfo やその他の小さなファイルが欠けている場合、今後はそれを空として扱い、修復は要求しません。そのためリリースが修復不可能としてマークされることもなくなりました。動画の隣にある .nfo がなくなっていれば、破損した動画を再び修復できるようになります。この理由で修復不可能とマークされていたリリースは、約1日以内に再チェックされ、自動的に元に戻ります。

## Usenet のファイルが、サーバーが別のアップロードの記事を送った箇所で無音になる問題を修正 {#usenet-files-no-longer-play-silence-where-a-server-sent-another-uploads-article}

一部のニュースサーバーは、ファイルの1つの記事を求められたときに、同じ番号を持つ別のアップロードの記事を返すことがあります。zurgがこれに気づけたのは、別のアップロードの記事数がお使いのファイルより少ない場合だけでした。RARボリュームや短いエピソードのような小さめのファイルでは、間違った記事を取り込んでしまい、その区間が無音で再生されていました。

ログには `an internal mapping failure in zurg` と表示され、オフセットは `falls between two articles that are both present and neither covers` と記録されていました。

zurgは今では、各記事が宣言しているファイルサイズも確認します。別のファイルの記事は受け取りを拒否し、他のニュースアカウントに正しい記事を要求します。古いビルドがすでに記事キャッシュに保存していた記事も同様に拒否されます。

アカウントが1つだけの場合、その区間は引き続き無音で再生されます。ログには、zurgのせいにするのではなく、サーバーが別ファイルの記事を送ってきたことが表示されるようになりました。

## 別のアプリがアカウントを使い終わると、Usenet の接続が全速度に戻るように {#usenet-connections-come-back-at-full-speed-after-another-app-stops-using-the-account}

ニュースプロバイダーが接続数の多さを理由に zurg の接続を拒否したことがある場合（たとえば別のプログラムや以前の zurg がまだ接続を使っていたとき）、zurg は実行中ずっと 1 秒に 1 本ずつ接続を増やし続けていました。空きが戻った後も同じでした。静かな時間のあとには、2 本のウォーム接続からダウンロードが一斉に再開されるため、大きなアカウントでは全速力に戻るまで 1 分以上かかり、インポートがその後ろで待たされていました。デバッグログには "waited 5s for a connection (queued for the account's allowance)" と出ていました。
今では、プロバイダーが接続を再び受け入れ、その後 1 分間拒否されなければ、zurg は必要な分の接続をすぐに開くようになりました。

## 複数の news server を設定している場合、デバッグログに接続待ちの fetch が表示されるように {#the-debug-log-says-when-a-fetch-waits-for-a-connection-with-several-news-servers-configured}

ニュースサーバーが1台だけの場合、接続を5秒以上待った取得では、その旨のデバッグログが出ていました。2台以上の場合はこのログが一度も出ず、サーバーを2台目に追加するとログが消えていました。待機が止まったかどうかは関係ありませんでした。今回の修正で、複数サーバーの構成でもこのログが出るようになりました。取得が待っていたサーバーの名前も表示されます。

## repair ファイルがなく、最初の記事も壊れている Usenet の grab は即座に失敗するように {#a-usenet-grab-with-no-repair-files-and-a-dead-first-article-fails-at-once}

PAR2 ファイルなしで投稿され、最初のアーティクルがすべてのニュースサーバーから消えていたリリースは、Radarr や Sonarr に失敗が伝わるまで 5分間保留されていました。修復に使うものが何もないのに、修復を待っていたのです。現在 zurg は、リカバリーデータがないことを認識し、グラブが失敗したことをすぐに報告します。そのため、クライアントはそのリリースをブロックリストに登録して、次に進みます。

## repair で直った Usenet の grab が、5分後に失敗として報告されなくなりました {#a-usenet-grab-that-repair-fixed-is-no-longer-reported-failed-five-minutes-later}

 grabに数本の記事が欠けていても、そのPAR2ファイルで復元できる場合、zurgは修復を行います。ただ、修復中に動いていた先読みが欠けた記事を再度要求し、修復が終わった直後に拒否されることがありました。この拒否によってリリースが再び破損リストに戻り、grabは5分間保留されたあと失敗と報告されていました。その結果、RadarrやSonarrは再生に問題のないリリースをブロックリストに入れていました。修復ですでに復元された記事に対する拒否は、もう破損とはみなされなくなりました。

## アップグレードしたダウンロードに付いていた .nfo や字幕も削除されるように {#upgraded-downloads-that-came-with-an-nfo-or-subtitles-are-deleted-too}

`magic.allow_delete` を有効にしているとき、RAR アーカイブに入っていなかった動画を削除すると、その動画だけが削除されていました。動画と一緒に置かれた `.nfo`、字幕、ポスターはライブラリに残り、ダウンロードも残っていました。NZB は `nzbs/` に残り、torrent はデビッドアカウントに残っていました。このようなダウンロードをアップグレードするたびに、残りが増えていました。今後は、`__magic__` のどこからも使われなくなった時点で、ダウンロード全体が削除されます。ダウンロードの別のエピソードがまだライブラリにあるか、自分のフォルダーでインポートを待っている場合は、そのダウンロードは残ります。Sonarr や Radarr が動画の横にインポートした字幕は、それらが削除されるまで動画を残します。

## 置き換えられた、または失敗した Usenet のダウンロードがたまり続けなくなりました {#replaced-and-failed-usenet-downloads-no-longer-pile-up}

`magic.allow_delete` を使っているとき、RAR アーカイブから取り出したエピソードや映画を削除すると、以前はそれが非表示になるだけでした。元のダウンロードはライブラリに残り、その NZB も `nzbs/` にずっと残っていました。エピソードを単体でシーズンパックにアップグレードすると、エピソードごとに残骸が 1 つずつ出てしまっていました。今後は、`__magic__` のどこからも使われなくなった時点で、ダウンロード全体を削除します。同じアーカイブの別のエピソードがライブラリにまだあるあいだは、そのダウンロードは残ります。フォルダー内にまだインポートできるものが残っている場合も同様です。

Sonarr と Radarr は、失敗したダウンロードを削除するときにそのファイルの削除を求めます。以前の zurg は、それでも NZB を残していました。今後は、そのリリースから何もインポートされていなければ NZB も削除します。完了してインポートされたダウンロードは、インポートされたファイルがそこから再生されるため、これまでどおり NZB を残します。

## ライブラリの読み込みが終わったことを zurg が表示するように {#zurg-now-says-when-the-library-has-finished-loading}

Docker は zurg が起動した時点で healthy と判断します。大きなライブラリでは、その後も 1 時間以上読み込みが続くことがあります。その間、マウント内のフォルダはずっと `Input/output error` で失敗するため、インストールが壊れているように見えてしまいます。新しい `/ready` アドレスは、この 2 つを見分けるためのものです。ライブラリの読み込みが終わるまでは 503 を返し、終わると 200 を返します。パスワードは不要です。コンテナ内で `/app/healthcheck.sh --ready` を実行すると、同じことを確認できます。

コンテナ自体のヘルスチェックは、これまでどおり zurg が起動しているかどうかだけを確認します。そのため、初回の長い読み込み中にコンテナが再起動されたり、それに依存するマウントが待たされたりすることはありません。

また、ヘルスチェックが `PORT` 環境変数を読むようになりました。以前は `PORT` を設定しているコンテナで、間違ったポートを確認していました。

## Acquisition がリリース名に含まれる単語でリリースをスキップできるように {#acquisition-can-skip-releases-by-words-in-their-names}

`acquisition:` ブロックで `exclude_words` を設定すると、zurg は名前にそれらの単語のいずれかを含むリリースを一切取得しなくなります。`exclude_words: [DV, HDR10+]` と書くと、再生できないテレビに Dolby Vision と HDR10+ が届かないようにしつつ、通常の HDR の 4K は取得し続けます。

この設定は Plex のウォッチリスト、Seerr、Radarr、Sonarr、そして Usenet とトレントで動作します。

単語単位でのみ一致します。`DV` は `DVDRip` や Adventures という名前の映画にはマッチしません。`DV`、`DoVi`、`Dolby Vision` はすべて同じ意味で、`HDR10+` と `HDR10Plus` も同じです。

除外されたリリースについて、Radarr と Sonarr に問い合わせることは一切ありません。

## Radarr と Sonarr が、プロファイルの最高画質を最初に取得できるように {#radarr-and-sonarr-can-take-the-profiles-best-quality-first}

zurg は通常、確認が最も速く終わる許可済みのリリースを選びます。映画の場合、それは通常 1080p WEB-DL です。アップグレード処理では、その後プロファイルのカットオフに向けて品質を上げていきます。シリーズでは、バラのエピソードより先にシーズンパックを取ります。そのため、2160p のエピソードがあった場合でも、1080p のパックでシーズン全体が埋まることがあります。

`acquisition:` の下に `best_first: true` を設定すると、最初の取得は代わりに Radarr または Sonarr の品質プロファイルに従います。許可されている中で最も高い解像度が最初に来ます。カットオフと同等以上のものは、十分良いものとして扱われます。リリースが消えていることが分かった場合、zurg はプロファイルを下に向かって順に試していきます。最良のリリースは大きなマルチパートの投稿であることが多いため、最初のファイルが届くまで時間がかかることがあります。デフォルトではオフになっています。

## NZB を受け付けるアカウントがない場合、torrent の検索結果が NZB を押しのけなくなりました {#torrent-results-no-longer-crowd-out-nzbs-where-no-account-takes-torrents}

debrid アカウントがなく、トレントを受け付けない NZB プロバイダーだけのインスタンスでも、取得処理は Torznab インデクサーを検索していました。そして見つかったトレントごとに、エピソードやシーズンパックに割り当てられる試行回数 3 回のうち 1 回を消費していました。`prefer: torrents` を設定している場合や、4K のトレントが 1080p の NZB より上位にランクされている場合、NZB は一度も試されずにエピソードが失敗していました。

このようなインスタンスでは Torznab インデクサーをスキップするようになり、その旨が 1 行ログに出ます。また、インスタンスに置き場所がないリリースは試行回数にカウントされなくなりました。映画についても、そうしたトレントについて Radarr に問い合わせなくなっています。

## 再生できるものがない場合、Acquisition が NZB を完了扱いにしなくなりました {#acquisition-no-longer-counts-an-nzb-as-done-where-nothing-can-play-it}

debrid アカウントがあって NZB プロバイダーがないインスタンスでは、取得処理が引き続き Newznab インデクサーを検索し、取得した NZB を何のチェックもせずに完了扱いにしていました。そのため、そのインスタンスでは再生できないファイルのせいで、Plex のウォッチリストからタイトルが外れることがありました。今後は、このようなインスタンスでは Newznab インデクサーをスキップし、その旨を 1 行ログに出します。また、NZB プロバイダーがないインスタンスでは、NZB が完了扱いになることはありません。

## 再生できるファイルが残っていないリリースは、毎日ではなく一度だけ報告されるように {#a-release-with-nothing-left-to-play-is-reported-once-instead-of-every-day}

zurgは、リリースの再生可能なファイルがすべて削除されると、「has no playable file that still reads」という警告を毎日繰り返し出していました。100本のリリースがあるライブラリでは、誰も触っていないリリースについて、1日に100件もこの警告がログに出ていました。今後は警告は1回だけ表示され、そのリリースは何かが変わったときにだけ再確認されます。ファイルを復元した場合は、すぐに元どおりになります。

## AllDebrid と TorBox で壊れたリリースも、ファイルが再生できるなら復活するように {#broken-releases-on-alldebrid-and-torbox-come-back-when-the-files-still-play}

AllDebrid、TorBox、Premiumize、Offcloud、Debrid-Link のどれか一つだけにあるリリースは、アカウント側でまだ配信されていても、数週間にわたって壊れたまま非表示になることがありました。これらのサービスは内容を意図的に削除するため、Repair はそれらのリリースを自動では再追加しません。また、ファイルが再び動くようになったかを確認する仕組みもありませんでした。

今では Repair が、壊れたリリースのファイルがまだ再生できるかを 1 日 1 回アカウントに問い合わせます。再生できるものは元に戻しますが、何かを新たに追加することはありません。アカウントから実際に削除されたものは、これまでどおり Repair ボタンで対応する必要があります。

MCP の repair outlook も同じ内容を表示するようになりました。以前のように「どの sweep も対応しない」とは表示しません。

## 空きスロットを待つ TorBox のキューが queued と表示され、完了するように {#grabs-torbox-queues-for-a-free-slot-show-as-queued-and-finish}

TorBox の download slot がすべて埋まっていると、TorBox は Sonarr と Radarr から新しく送られた grab をキューに入れます。そのとき zurg はそれらを見失っていました。grab は約 10 分間 fetching metadata と表示されたあとエラーになり、Sonarr と Radarr はそれを破棄していました。その後 TorBox がダウンロードしても、何もインポートされませんでした。

zurg は、キューに入った grab を TorBox が開始するまで、そして完了するまで追跡するようになりました。待機中は queued と表示されます。no-progress timeout は、TorBox が開始するまで動きません。

## `__magic__` ページで 1 つのリリースを検索できるように {#you-can-search-for-one-release-on-the-__magic__-page}

Sonarr や Radarr が整理しているライブラリでは、インポートのたびに、非表示のジョブフォルダが残ります。`__magic__` ページには保存された行のうち最初の1000件しか表示されません。探しているリリースはたいてい含まれていなかったため、その Unhide と Reset ボタンには手が届かず、リストの下の注記では data/magic.json を見るように書かれていました。zurg の実行中にそのファイルを編集してもうまくいきません。zurg は停止時にメモリの内容でファイルを書き直すため、再起動すると行が戻ってしまいます。

保存された行と宙ぶらりんのページに、検索ボックスが付くようになりました。リリース名、マウント上のパス、またはハッシュを入力すると、そのリリースに関して保存されている行がすべて、ボタン付きで一覧に出ます。テーブルがどれだけ大きくても表示されます。

`__all__` にはあるのに `__magic__/__all__.` に表示されないリリースを戻す際にも使えます。リリースを削除して追加し直すか、DMM から再挿入すると、そのハッシュは保たれるため、インポート後に削除されたジョブフォルダを含め、`__magic__` に保存されていた情報がすべて戻ってきます。そのリリースを検索して、リリースのトゥームストーン行にある Unhide を押してください。

## Windows の `__magic__` で、ジャーナルが無限に増え続けなくなりました {#__magic__-on-windows-stops-growing-its-journal-forever}

On Windows, zurg logged `cannot truncate data\magic.journal ... Access is
denied.` every time it tried to tidy the file where `__magic__` records your
moves and folders. The file was never emptied, so it grew with every change
and every start read all of it again. After a few thousand changes in one run,
each further change also rewrote the whole saved layout. zurg now empties it
on Windows as it always did elsewhere, and the first start after updating
clears what has piled up. If tidying ever fails, zurg tries again after more
changes instead of on every one.

## MCP でファイルを復元すると、そのリリースもすぐに戻るように {#restoring-a-file-over-mcp-puts-its-release-back-right-away}

Ｚ`zurg_release_file_restore` MCPツールでファイルを復元したところ、ファイルは戻ったものの、リリースは壊れた状態のまま `__unplayable__` に残り、次のライブラリ更新まで戻りませんでした。今回からは、トレントマネージャーの Restore ボタンと同じ動作をします。リリースは `__unplayable__` から出て、.strm ファイルを含めて元のフォルダに戻され、その状態で保存されます。以前と同じく、Plex、Jellyfin、on_library_update スクリプトに再スキャンを依頼することはありません。

## 失敗した repair で隠れていたファイルを戻すように {#bring-back-files-a-failed-repair-hid}

古いビルドでは、ある1つのアカウントで修復が諦められたとき、別のアカウントでまだ再生できる場合でも、ファイルが削除済みとしてマークされていました。その結果、リリースがすべてのフォルダーから消えてしまっていました。

torrent managerには新しい「Deleted, still served」フィルターができました。このフィルターは、再生できるものが何も残っておらず、削除されたファイルをまだいずれかのアカウントが配信しているリリースを一覧表示します。そのRestoreボタンを長押しすると、zurgが各ファイルのリンクを確認し、再生できるものをフォルダーに戻します。これは、各ファイルでRestoreを押すのと同じ動作です。

zurgは自動では行いません。意図的に削除したファイルも同じ形で保存されているため、一覧を確認して、削除していないものだけを復元してください。何かしら再生できるリリースは一覧に含まれません。特典映像やエピソードを削除するのは、通常は意図的な削除だからです。

## Acquisition が検索結果の最初のページだけでなく、その先まで見るように {#acquisition-looks-past-the-first-page-of-search-results}

取得処理は以前、インデクサーが返した最初のページだけを読んでいました。DMM は 1 ページに 10 件の結果を、大きいものから順に返すため、サイズ制限に引っかかると、その 10 件がすべて除外されてしまうことがありました。そうなると、小さいリリースが次のページにあるのに、映画が「no eligible releases」で何時間おきにも失敗していました。今は、制限に合うリリースが十分に集まるまで、最大 10 ページまで追加で取得するようになりました。シリーズの場合は、シーズン検索で見つからなかったエピソード（たいてい、最新のエピソードで結果が埋まったときの古いエピソード）を、単独で検索するようになりました。

## `__magic__` の映画フォルダと番組フォルダにある壊れたファイルは外れるようになり、Radarr と Sonarr が気づくように {#dead-files-in-__magic__-movie-and-show-folders-now-drop-out-so-radarr-and-sonarr-notice}

Radarr や Sonarr が `__magic__` 配下のフォルダにインポートしたファイルは、リリースが動かなくなった後もフルサイズのまま表示され続けていました。そのため再スキャンでもまだ見つかってしまい、映画やエピソードが wanted に戻らなかったんです。

今後は、他のすべての一覧から消えるタイミングと同じときに、このフォルダからも消えます。修復がもう復旧できなくなったとき、または修復が無効になっている場合は壊れてから1日後です。次の再スキャンでそのファイルは missing とマークされ、取得処理が代わりのリリースを探します。ファイルが再び動くようになると、元の場所にまた表示されます。

## Season Fix が複数シーズンのパックと番号付きのエクストラを並べ替えるように {#season-fix-sorts-multi-season-packs-and-numbered-extras}

Season Fix は、各ファイルが名前で示しているシーズンを自分で読み取るようになりました。そのため、`Full Metal Panic S2 - 01`、`Bakuman II - 01`、`KonoSuba 2 - 01`、`Demon Slayer Mugen Train Arc - 01` のようなパックでも、すべてのエピソードがそれぞれ正しいシーズンに入ります。以前は Plex がすべてをシーズン1に重ねてしまっていました。

ローマ字や接尾辞付きの名前のバッチ（例: `Sergeant Keroro 001-358`、`Dragon Ball Z COMPLETE`）も、ファイルが同じタイトルを共有していれば認識されます。アンダースコアを含む名前、`Ep01`、`1.01.`、エピソードタイトルの中の数字も、意図どおりに読み取られるようになりました。

`Special 01`、`OVA 01`、`- 11 (OVA)`、`24.5` のような番号付きの特典（おまけ）やリキャップは、以前は本編エピソードの別バージョンとして扱われ、Play で特典の方が選ばれることがありました。今では Plex の `-other` 接尾辞を付けて名前が変わるので、特典としてちゃんと表示されます。

## 壊れた Real-Debrid リンクが、ライブラリのスキャンを何分も止めなくなりました {#a-dead-real-debrid-link-no-longer-holds-a-library-scan-for-minutes}

Real-Debrid が同じ無効化されたリンクを何度も返してくるとき、zurg はダウンロードを削除した直後なら普通のことなので、数分待ちます。その方法で 5 分経っても拒否され続けるファイルは、もう「また後で来てください」と伝えるのではなく、壊れたリンクとして扱われ、repair に回されるようになりました。以前は、1 つの壊れたファイルが Plex のスキャンを約 10 分も止めてしまうことがありました。

## 失敗したり止まったりした Usenet のジョブは `__magic__` ページからクリアできるように {#failed-and-stuck-usenet-jobs-can-be-cleared-from-the-__magic__-page}

SABnzbdのリストで、Sonarr や Radarr が zurg をダウンロードクライアントとして使わなくなったあと、Failed や Stuck のジョブがずっと残ったままになることがありました。再起動しても消えません。`data/sabnzbd-jobs.json` を手で削除するしか方法がありませんでした。

`__magic__` ページのジョブ一覧では、Failed や Stuck のジョブそれぞれに **Clear** ボタンが付くようになりました。一覧の上にあるボタンを使えば、それらをまとめて消去できます。バーが埋まるまで長押ししてください。

Queued と Completed のジョブには一切触れません。`__magic__` のインポートでそのリリースがまだ使われていない場合は、ジョブの NZB も一緒に削除されます。

## Stremio アドオンが https を必要とする場合にそれを表示するように {#the-stremio-addon-says-when-it-needs-https}

Stremioは、アドオンを動かしているコンピューター上でだけ、httpのプレーンな接続からアドオンを読み込みます。テレビ、スマホ、別のコンピューターでは、デバイスからzurgに届いていても、httpのアドレスだと「failed to load manifest」で失敗します。設定ページでは、そうしたアドレスをhttpで開いた場合に、アドオンのURLの横にその旨が表示されるようになりました。Stremioガイドには、zurgをhttpsの後ろに置く方法が3つ載っています。Tailscale Serve、自分のリバースプロキシ、Cloudflare tunnelです。

## Radarr や Sonarr が `__magic__` に取り込んだ映画や番組を、Plex がすぐに認識するように {#plex-picks-up-a-movie-or-episode-as-soon-as-radarr-or-sonarr-imports-it-into-__magic__}

Radarr や Sonarr が `__magic__` 配下のフォルダにファイルを移動した後、zurg はファイル単体ではなくそのファイルを Plex にスキャンするよう依頼していました。Plex はフォルダ単位でしかスキャンしないため、Plex は問題なしと返すだけで何も追加せず、次回の定期スキャンまで映画が表示されないままでした。zurg は今後、ファイルが置かれたフォルダを Plex にスキャンするよう依頼します。アップグレードで置き換えられる古いファイルについても同じ対応を行うため、古いバージョンはライブラリから消えます。手動スキャンのエンドポイント、MCP の `zurg_plex_scan_releases` ツール、リネームやファイル削除後のスキャン、`on_library_update` に渡されるパスも同様です。

## Manage ページに重複したリリースと、Radarr や Sonarr がどれを使っているかが表示されるように {#the-manage-page-lists-duplicate-releases-and-which-one-radarr-or-sonarr-uses}

アップグレードすると、置き換えられた旧リリースがライブラリに残ります。また、異なるインデクサーからの取得によって、同じ映画やシーズンのコピーが複数できることもあります。Manage ページの新しい Duplicates ビューでは、同じ映画または同じエピソードを含むリリースがグループ化され、Radarr または Sonarr がどれを使用しているかが表示されます。zurg は、リリース名ではなく、ファイルが `__magic__` のどこにあるかからこれを判断します。

シーズンの場合は、複数のリリースが保持しているエピソードごとに一覧が表示され、Sonarr のファイルがどのリリースにあるかも示されます。そのため、Sonarr が数話だけを取り込んだパックも、使用中として表示されます。

それ以外のリリースには、理由とともに "No reference found" または "Unknown" と表示されます。削除したいものを選択すると、zurg は削除の前に Radarr と Sonarr を再度読み込み、その後に使用中になったものは除外します。自動的に削除されることは一切ありません。

## TorBox の使用中のダウンロードスロットを、TorBox の数え方に合わせて数えるように {#torboxs-busy-download-slots-are-counted-the-way-torbox-counts-them}

Zurgがrepairや初回再生の前にtorrentをTorBoxへ追加する際、アカウントに空きのダウンロードスロットがあるかを確認するようになりました。以前は、完全にダウンロードされていないtorrentをすべて数えていました。そのため、シーディング中のtorrentを数えず、TorBoxがプランに対して最大30日間カウントするものを見逃していました。一方で、コンテンツの期限が切れたtorrentは数えていました。期限切れのtorrentはスロットを一切使わないのにです。ライブラリに期限切れのtorrentが数件あるだけで、すべてのスロットが埋まっているかのようにrepairが待機してしまうことがありました。
zurgは現在、TorBoxがアクティブとしてマークしているtorrentだけを正確に数えます。

## TorBox で private tracker 向けにシードできるように {#torbox-can-seed-for-private-trackers}

ああ、新しい設定 `tb_seed_torrents` が追加されました。これは、zurg が TorBox に追加したトレントをシードするかどうかを決めるものです。何も変更しなければ `never` のままなので、何も変わりません。プライベートトラッカーでレシオが必要なら `always` に、TorBox アカウントのシード設定に任せたいなら `auto` にしてください。変更はダッシュボードの Health & Repairs セクションからできて、次回の追加から反映されます。

シード中のトレントは、シードしている間ずっと TorBox プランのアクティブスロットを1つ使います。Pro なら最長30日です。シード中のトレントですべてのスロットが埋まると、そのアカウントでの新しい取得や修復は、どれかのスロットが空くまで待つことになります。

## ボリューム名の順番がバラバラな RAR セットも再生できるように {#rar-sets-whose-volumes-are-named-out-of-order-now-play}

ランダムな名前や `Movie 2026 part1.rar` のように、RAR ボリュームごとに名前がバラバラなリリースは、以前はボリュームごとに別々のアーカイブとして表示されていました。最初のものには映画の情報が出ていましたが、最初のパートの後で再生できなくなり、残りには何も表示されませんでした。今の zurg は、各ボリュームがどこに属するかをボリューム内部から読み取り、一つのセットとして組み直します。以前は、ボリュームを `part001.rar` からの名前に手動で変えることで直していた作業です。

これは、ボリュームが番号によって一つの完全なセットになる場合にだけ行われます。一つでも欠けていたり、二つが同じ位置を主張していたりする場合は、リリースはそのままの状態で残り、ログにその理由が書かれます。また、投稿順がバラバラになっている圧縮アーカイブも再生できるようになりました。

## 解析中の Plex スキャンを、止まっていると報告しなくなりました {#a-plex-scan-that-is-still-analysing-is-no-longer-reported-as-stuck}

Plexは、スキャンで見つけたファイルを解析している間、スキャンの進捗と現在のフォルダーを変えないままにします。大きなライブラリやリモートのライブラリでは、これに長い時間がかかることがあります。以前のダッシュボードは、これを「スキャンが止まっている」と判断し、スキャンの途中でPlexの再起動を提案していました。今のzurgはPlex自身の更新フィードを監視し、Plexが処理中と報告しているアイテムを数えるので、本当に止まっているスキャンだけがフラグされます。

## キャッシュ済みの torrent だけを追加する場合、レート制限のあるプロバイダーでも拒否された追加を保持するように {#cached-only-torrent-uploads-preserve-the-refusing-add-on-rate-paced-providers}

`.torrent` をキャッシュのみモード（cached-only）で送信すると、時間あたりの追加上限でバックエンドが止まっている場合でも、TorBox の refusing add に届くようになりました。キャッシュにないミス（uncached miss）では転送は作られず、アクティブ枠も使いません。ただし、TorBox の 1 時間あたり 60 件の uncached add のうち 1 件は消費します。通常の追加は、元のファイルをそのままアップロードし続けます。
qBittorrent ガイドには、6 つすべての torrent アップロードプロバイダーが載るようになりました。また、Debrid-Link と TorBox のキャッシュのみの処理経路が別々であることも説明しています。

## 復元中に削除したファイルは、削除されたままになるように {#a-file-you-delete-while-it-is-being-restored-stays-deleted}

削除ですか、それとも復元を実行しているか、もう一度整理して書いた内容について答えてください。

リリースや file を削除するとき、その復元がまだリンクを確認している最中でも、今は確認が終わるまで待ってから削除が勝つようになりました。すでに走っていたライブラリの更新で、削除したばかりのリリースが戻ってくることもなくなります。

## 圧縮アーカイブの奥へのシークでリーダーが固まらなくなりました {#a-seek-far-into-a-compressed-archive-no-longer-hangs-the-reader}

圧縮された RAR や zip の中にあるファイルは、先頭からしか展開できません。そのため、大きなアーカイブの末尾近くを読もうとすると、以前は応答がないまま全体の処理が終わるのを待つ必要がありました。Plex がこのような読み込みで 1 時間以上待たされることもあり、その結果データベースがロックされてしまうこともありました。zurg は今では 20 秒以内に応答し、それまでに進めた分の処理を保持しつつ、ファイルの末尾を裏で準備します。そのため、次にそこを読むときはすぐに応答が返ります。

## Real-Debrid の拒否が公開されたファイル名ルールに沿うように {#real-debrid-refusals-follow-the-published-filename-rules}

Real-Debrid が repair 中に release の再追加を拒否した場合、zurg は今、その release の名前と
ファイル名を公開されているファイル名ルールと照らし合わせて確認します。ルールに引っかかった
release は、infringing（権利侵害）として恒久的にマークされます。それ以外の拒否は、
Real-Debrid が追加処理を遅くしているものとして扱われます。その release は削除されず、
次の repair パスまで順番待ちのままになります。

（以前の翻訳はコードスパンが一致しないとして却下されました。構造はそのまま維持してください。）

## ファイルを復元すると、すぐに元の場所へ戻ります {#restoring-a-file-puts-it-back-where-it-belongs-straight-away}

The Restore action on a release's manage page now re-files the release into its
directories, saves the recovered state and writes its STRM file as soon as the
file checks out. A restored file no longer sits in the unplayable directory
until the next provider refresh, and a release whose last broken file was
restored is no longer reported broken after a restart. Files you deleted still
stay deleted until you restore them.

## バイトを配信する前に、無関係な Usenet 記事を除外 {#reject-foreign-usenet-articles-before-serving-bytes}

Positive yEnc の合計が NZB に記載されている最大番号より小さい、同じ番号の Usenet 記事を拒否するようにします。永続化されたキャッシュや段階的なパスも含めて対象にして、有効なアカウントのフォールバックがデータを供給できるようにします。

## 証拠に基づく RD 拒否の分類を維持 {#preserve-evidence-backed-rd-refusal-classification}

アカウント単位のスロットリングの証拠が操作全体にわたっていない限り、addMagnet の 451 レスポンスは、リリース拒否として静かに扱ってください。また、一時的なエラーは修復の後も保持してください。

## 期限切れの壊れたファイルの読み取り期間をわかりやすく {#clarify-expired-broken-file-read-windows}

ブロークンファイルの読み取り再試行ウィンドウが期限切れになったことを報告しますが、修復を諦めたとは書かないでください。

## 記録済みのファイルヘルスを MCP で公開 {#expose-recorded-file-health-in-mcp}

MCP のリリース表示で、ファイルごとの記録済みヘルス件数を見えるようにしつつ、遅延読み込みのファイル表を安全に確認できる状態を保ちます。ライフサイクルの状態をライブの配信確認だと誤って表示することはありません。

## 重複するサイドカー操作を処理 {#handle-duplicate-sidecar-operations}

Typed missing-source レスポンスを、重複した WebDAV エイリアスから返されるものとして認識しつつ、本当の all-failed エラーや権限エラーはそのまま残す。

## 同じ名前での再取得が失敗ではなく修復されるように {#a-re-grab-under-the-same-name-is-repaired-instead-of-failed}

Zurgで既に保持している名前で NZB をもう一度取得すると、新しいファイルを読み込んでいる間に古いコピーをチェックして修復することはなくなりました。取得は新しいファイルが届くまで待つので、欠損記事があっても PAR2 で復元できるリリースは、失敗扱いにならず修復されて完了します。

## 修復の失敗がユーザーによる削除に見えなくなりました {#repair-failures-no-longer-masquerade-as-user-deletions}

自動修復が失敗したときは、失敗したプロバイダーのソースだけを壊れたとマークするようになりました。正常な別のコピーはそのまま残り、後でプロバイダーを更新したときにファイルが再び見えるようになります。

## IMDb ID のないトレントは DMM を通じてリリース名で識別されます {#torrents-without-an-imdb-id-are-identified-by-release-name-through-dmm}

`dmm_metadata_secret` を設定すると、IMDb ジョブに OpenSubtitles のキーはもう必要ありません。id がないトレント、または OpenSubtitles の「見つからなかった」マーカーだけが付いたトレントは、起動時に名前内の `imdb-tt…` タグから識別されます。タグがない場合は、DMM のリゾルバーが識別を試みます。リゾルバーは、タイトルが 1 つだけ完全に一致したときにのみ答えを返します。「Kaijuu 8-gou」のようなファンサブのローマ字表記は、DMM のエイリアスを通じて Kaiju No. 8 として解決されます。複数の番組で共有されている名前は、そのままにされます。DMM が名前を特定できないトレントは id が空のままになるので、Plex のマッチで後から埋めることができます。

## どのインデクサーも ID で認識しない Radarr の映画は、名前で検索されます {#a-radarr-movie-that-no-indexer-knows-by-id-is-searched-for-by-name}

多くの Usenet 投稿には IMDb や TMDB の ID が付いていません。zurg は Radarr の映画を ID だけで検索していたため、どのインデクサーも ID では何も返さないドキュメンタリーは "no eligible releases" で失敗していました。一方で Radarr 自身の名前検索では、きれいなリリースが見つかっていました。ID 検索で取れるものが何もないときは、zurg がタイトルと公開年でも検索するようになりました。各結果が映画本人かどうかは、今も Radarr 自身のパーサーが判断します。ID 検索が本当に何も見つけなかった場合にだけ、名前での検索を続けて行います。ID 検索で映画が見つかった場合は ID でインデックスするので、名前で聞き直しても同じ投稿が返ってくるだけです。そのため、名前での再検索はしません。

## Prowlarr で見つかった NZB をダウンロードできるように {#nzbs-found-through-prowlarr-can-be-downloaded}

Prowlarr は Usenet の NZB をすべて、インデクサーへのリダイレクトで渡してきます。この動作はオフにできません。zurg は同じホストへのリダイレクトしかたどらなかったため、Prowlarr 経由でインデクサーを設定していると、NZB の取得はすべて「answered 301 Moved Permanently」で失敗し、何も取得できませんでした。今はリダイレクトをたどるようになりました。ただし、リンク自体の API キーが別のホストに送られることはありません。また、HTTPS から平文の HTTP へのリダイレクトは、引き続き拒否されます。

## 数時間拒否し続けるインデクサーが取得を止めなくなりました {#an-indexer-that-refuses-for-hours-no-longer-stalls-acquisition}

Prowlarr が無効にしているインデクサーへの検索に、`429` と、数時間後を指す `Retry-After` が返ってきます。zurg は 2 分待ってから再度問い合わせ、それを 3 回繰り返していたので、そのインデクサー 1 つだけで毎回 6 分かかっていました。Acquisition は各タイトルを 5 回目で諦め、他のインデクサーがすでに返した結果も捨ててしまっていたため、そのインデクサーが復活するまで何も取得できていませんでした。今後は、2 分より長く待つように求めてきたインデクサーを指定された時刻までスキップし、残りのインデクサーで検索を進めるようになります。

## 取得後に削除されたタイトルを再検索するように {#a-title-deleted-after-acquisition-is-searched-for-again}

Sonarr や Radarr 用に zurg が確保したファイルが、希望のバージョンではなかったなどの理由で削除され、そのタイトルが missing リストに戻ってきても、zurg は "completed without a search, the release was already held" と返すだけで、二度と探しにいきませんでした。今の zurg は、まず `__magic__` 内のシーズンフォルダや映画フォルダを確認します。動画がなくなっているエピソードや映画は、もう一度検索されます。動画がまだ残っているものは、Sonarr がまだ再スキャンしていない間の状態なので、そのまま放置されます。

## 未検出リストの "Scan in Plex" が結果を待つように {#scan-in-plex-on-the-undetected-list-waits-for-the-result}

undetected リストの hold-to-scan ボタンは、押してから 2 秒後にページを再読み込みしていました。その時点では、Plex とのマッチングがまだ始まっていなかったためです。ライブラリが大きいとマッチングには数分かかるので、リストはいつも変わらないまま戻ってきて、ボタンが何もしていないように見えていました。今回の修正では、ボタンがマッチングの実行中であることを表示し、完了を待ってから、マッチしたリリースの件数を表示して、そのあとでページを再読み込みするようになりました。

## 末尾にスペースがあるリリース名も Plex と照合されるように {#a-release-whose-name-ends-in-a-space-is-matched-to-plex}

A release whose file name has a space before the extension, such as
`... [Hurtom] v2 .mkv`, gets a directory whose name ends in a space. Plexは見つけていたものの、zurgはどうしてもマッチできず、スキャンするたびに未検出リストに残っていました。今は正しくマッチするようになりました。

## 管理ページでファイルを削除しても位置が保たれます {#deleting-a-file-on-the-manage-page-keeps-your-place}

ファイル単位で削除、復元、名前変更、強制表示を行うと、以前はページが最上部に戻っていました。そのため大きなパックを整理するたびに、クリックのあとで下までスクロールし直す必要がありました。今後はそのファイルの行の位置に戻り、その行がハイライトされます。

## ダッシュボードが引用符付きのマウントパスを受け付けます {#the-dashboard-takes-a-mount-path-typed-with-quotes}

config.yml に書かれている形式のままダッシュボードに貼り付けたマウントパス（例: `"/Users/me/Plex Media Server/ZurgMount"` や `'Z:\'`）は、引用符がパスの一部として読み取られたため、"mount path should be absolute" と表示されて拒否されていました。ダッシュボードは、値を囲んでいる対になった引用符を自動で取り除き、パスだけを保存するようになりました。

## Plex のウォッチリスト取得に失敗した場合、その理由を表示します {#a-failed-plex-watchlist-fetch-says-why}

Plex がウォッチリストのリクエストを拒否すると、ログにはステータスコードだけでなく、`unexpected status: 401: Invalid token` のような Plex 自身の理由も出力されるようになりました。

ログに `Failed to fetch watchlist: ... unexpected status: 400` が表示される場合、そのメッセージは8月より前のビルドのものです。zurg を更新してください。最新のビルドでは、Plex が受け付けるページ単位でウォッチリストを要求します。

## repair のメモリに対して損傷が大きすぎるリリースは即座に失敗します {#a-release-too-damaged-for-repairs-memory-fails-at-once}

Usenetのリリースで、PAR2の修復がメモリ上で一度に扱える量を超えて欠損している場合、zurgは今その旨を表示して処理を止めます。そうすると、SonarrやRadarrは別のリリースを選びます。
以前は、取得を待たせたまま数分おきに再試行していて、そのたびに同じ答えを得るためにリリース全体を再チェックしていました。サーバーが応答しなかった記事のように、まだ消失が確定していない欠損は、今も再試行されます。

## 設定が空でも進めるようになり、トークン入力が非表示のときはそれを通知します {#setup-gets-past-an-empty-config-and-says-when-the-token-prompt-is-hidden}

`zurg setup` と、それを実行するインストーラーは、空の `config.yml` が残っていると先に進まず、エラーメッセージの最後が空欄のままになっていました。今では空の設定ファイルは置き換えられます。内容が入っているファイルは、今でも上書きされることはありません。エラーには、どのファイルが問題なのか、やり直すにはどうすればよいかが表示されるようになりました。トークンの入力プロンプトには、入力や貼り付けした内容は非表示になると書かれるようになりました。以前はそれが、端末が入力を受け付けていないように見えていました。`config.yml` のタイプミスは、内部の "outbound identity config" ではなく、`config.yml` のエラーとして報告されるようになりました。

## バックアップのニュースサーバーが、メインサーバーの誤った応答の記事を補うように {#a-backup-news-server-now-fills-in-articles-the-main-server-answers-wrongly}

一部のニュースサーバーは、ある記事のリクエストに対して、別のアップロードの一部を返すことがあります。zurgは間違ったデータだと認識していましたが、正しいデータをバックアップサーバーに一度も要求しませんでした。そのため、欠けた部分は無音になるか、ファイルが開けなくなっていました。正しいデータを持っているバックアップサーバーがあったとしてもです。zurgは、SABnzbdと同じように、次のサーバーに要求するようになりました。

## RAR 化された Usenet リリースが再起動なしでディレクトリに現れます {#a-rard-usenet-release-reaches-its-directory-without-a-restart}

RAR形式でまとめて投稿されたリリースは、アーカイブが開かれるまではボリューム名をもとにディレクトリへ振り分けられ、開いた後は中のファイルをもとに振り分けられます。ただ、アーカイブを開いた後に振り分けをやり直す処理がなかったため、新しく取得したRAR形式のリリースは、`.mkv` やエピソード番号を探すディレクトリで見つからず、zurgを再起動するまで Plex と Jellyfin からも見えませんでした。このリリースは、アーカイブが初めて一覧表示された時点で、正しいディレクトリへ移動するようになりました。

## ランダムな名前で投稿された映画がリリース名で命名されるように {#a-movie-posted-under-a-random-name-is-named-after-its-release}

一部の Usenet 投稿では、映画に `eq5KVi5Y3iTwFEn1Nub8yPY9yd6oUzTu.mkv` のようなランダムな名前が付けられていて、本当の名前が入りうる投稿内のあちこちで同じ名前が繰り返されています。zurg はその名前をそのまま残していたので、Radarr と Sonarr はファイル名から手がかりを得られませんでした。zurg は今、SABnzbd と同じように、リリース名をもとにファイル名を付けるようになりました。ただし、それがリリースの中で明らかに一つだけの大きなファイルである場合に限り、動画ファイルのときだけです。ディスク構造やアーカイブには決して付けません。これは今後取得するリリースに適用され、すでにライブラリにあるものは名前がそのまま残ります。

## サイズルールがアーカイブ内のファイルにも適用されるように {#size-rules-now-apply-to-files-inside-archives}

A Usenet movie posted as a RAR set is shown as the files inside the archive.
Those files skipped a directory's `only_show_the_biggest_file` and
`only_show_files_with_size_gte`/`_lte` settings, so anything else the post
carried stayed visible beside the movie. Many posts include a small image named
after the movie, a sheet of timestamped stills, and Jellyfin used it as the
poster. The size settings now apply to archive contents the same way they apply
to every other file.

## 最大の PAR2 ファイルが 512 MB を超える Usenet リリースも修復できるように {#usenet-releases-whose-largest-par2-file-is-over-512-mb-can-be-repaired}

zurg は、リリースに欠けている部分があるとき、そのリリース自身の PAR2 ファイルを使って修復します。以前は 512 MB を超える PAR2 ファイルを読み込まなかったのですが、大きなリリースでは、その PAR2 ファイルに修復データが最も多く含まれていることが多く、場合によっては唯一の PAR2 ファイルです。そのため、欠けている部分がどれだけ少なくても、そのようなリリースは修復できませんでした。さらに zurg は、諦めるまでの間、そのたびに小さい方の PAR2 ファイルをすべてダウンロードし直して、何度も再試行していました。今後は、サイズに関係なく任意の PAR2 ファイルを読み込めるようになりました。

損傷が一度の修復でメモリに収まる量を超えているリリースは、損傷の量を数えた時点ですぐに除外されます。そのため、PAR2 ファイルはどれもダウンロードされません。

## Sonarr は不足しているエピソードを zurg に渡せるように {#sonarr-can-hand-its-missing-episodes-to-zurg}

zurg は Sonarr からもリストを取得できるようになりました。`acquisition.sources` に `sonarr` ソースを追加し、Sonarr の URL と API キーを指定してください。zurg は Sonarr が不足しているとしているエピソードと、アップグレード対象のエピソードファイルを順番に処理します。インデクサーを検索し、ニュースサーバーにそのリリースがまだ残っているかを確認します。エピソードは `__magic__` 内のシーズンフォルダーに配置され、その後 Sonarr にシリーズの再スキャンを依頼します。この機能に Sonarr 側のインデクサーやダウンロードクライアントは必要ありません。

シーズン全体が欠けていて放送が終わっている場合は、1つのシーズンパックとして取得されることがあります。それ以外は、エピソードごとに取得します。すべてのリリースは、まず Sonarr 独自のパーサーで確認されます。正しいシリーズと正しいエピソードであること、そしてそのシリーズのクォリティプロファイルに合うことが必要です。アップグレードでは、アップグレードされるエピソードだけが置き換えられます。シーズン内の一部のエピソードにまだリリースがない場合でも、残りのエピソードは配置され、それらについて Sonarr が再スキャンされます。デイリー番組とアニメシリーズは今のところスキップされ、その旨がログに記録されます。Sonarr 側の設定については `docs/acquisition.md` を参照してください。

## 取得処理が多数のタイトルを同時に扱えるように {#acquisition-works-on-many-titles-at-once}

ウォッチリストやリクエストサービスから来たタイトルは、以前は一つずつ順番に取得されていたため、長いリストは全タイトルを合計した時間がかかっていました。zurgは今では一度に最大8件まで並行して処理します。その数は`acquisition.concurrency`で設定します。リストの後のほうに現れたタイトルは、前のタイトルが終わるまで待たなくなりました。

新しいリリースは、zurgがチェックを始めるまで2分間待たされることがなくなりました。リリースがライブラリに現れるまで、zurgは1秒ごとにチェックします。チェックは最大1分30秒続きます。ニュースサーバーにそのリリースがもう残っていない場合、zurgは5分後に再試行するのではなく、すぐ次の候補に進みます。

リリースのチェックは、検索の後に残った時間内に収める必要がなくなりました。そのため、長いリストでの検索が遅くても、タイトルが何分も遅れることはなくなりました。すでに持っているタイトルのアップグレードは、同じリストにある未取得のタイトルが終わるまで待つようになりました。こうすることで、インデクサーへのリクエストやニュース接続を奪い合うことがありません。

## PAR2 で修復された Usenet リリースは、読み取り中も修復済みのままです {#a-usenet-release-repaired-with-par2-stays-repaired-while-it-is-read}

ニュースサーバーから一部の記事がなくなったリリースでも、zurg は PAR2 ファイルを使ってそれらを復元し、復元したデータを配信します。ただ、プレイヤーより先にデータを取得しておく zurg の部分は、復元されたパーツのことを知りませんでした。そのため、欠けている記事を再びサーバーに要求していました。記事はまだ欠けたままなので、zurg は、配信したデータがすべて正しかったにもかかわらず、リリースをまた破損と報告していました。インポート中に修復されたリリースが、その直後に失敗扱いになることもありました。そうなると、ダウンロードクライアントは正常なコピーを捨てて、別のコピーを取りに行ってしまいます。zurg は、もう復元済みのものをサーバーに要求しなくなりました。

## Radarr は必要な映画を zurg に渡せるように {#radarr-can-hand-its-wanted-movies-to-zurg}

zurgはRadarrからリストを取得できるようになりました。`acquisition.sources`の下に`radarr`ソースを追加し、RadarrのURLとAPIキーを設定してください。すると、zurgはRadarrが不足していたりアップグレードを求めていたりする映画を順に処理します。zurgはインデクサーを検索し、ニュースサーバーにそのリリースがまだ残っているかを確認します。次に動画を`__magic__`内の映画フォルダーに配置し、その映画について再スキャンをRadarrに依頼します。この機能のためにRadarr側でインデクサーやダウンロードクライアントを設定する必要はありません。

zurgが採用するリリースはすべて、先にRadarr自身のパーサーを通過したものです。つまり正しい映画であり、映画の品質プロファイルにも合っている必要があります。具体的には、許可された品質であること、最低限のカスタムフォーマットスコアを満たしていること、サイズの制限内であること、そしてカットオフに向けたアップグレードであることが条件です。zurgは、確認が最も早く終わるリリースを優先し、許可された最初のものを選びます。ウェブリリースが先に選ばれます。プロファイルで優先される品質の選択は、後に続くアップグレードの処理に任せます。

zurgがRadarrにリリースについて問い合わせるのは、そのリリースを確認しようとするときだけで、一度に一件ずつです。タイトルに、プロファイルに対応する品質がない解像度が含まれているリリースについては、問い合わせを行いません。そのため、混雑しているRadarrでも、検索結果の件数ぶん問い合わせるのではなく、ほとんどの映画で一〜三回の問い合わせで済みます。

Radarrからzurgのマウントが別のパスに見えている場合は、`library_path`に、Radarrから見た`__magic__`の場所を設定してください。

ダッシュボードには新しい「Acquisition」ページが追加されました。zurgが現在処理しているすべてのタイトル、それぞれが今何をしているか、そして各リリースをどこに配置したかが表示されます。

Radarr側の設定については`docs/acquisition.md`を参照してください。

## 取得では、最も早く確認できる Usenet リリースを選びます {#acquisition-picks-the-usenet-release-that-is-quickest-to-confirm}

zurgが映画を取得するとき、まず単一の動画ファイルを含む投稿を探すようになりました。こうした投稿はニュースサーバー上で完全な状態で残っている可能性がずっと高く、確認に記事の読み取りが2回で済みます。候補ごとにNZBを読み込んでから何かを保存します。見つかった最初の単一動画の投稿を保存し、提供されているものがない場合にのみ、複数ボリュームのアーカイブセットに切り替えます。その際は小さいセットから順に、同時に処理するのは最大6つまでです。分割投稿の一部の名前が付いた結果はスキップされます。

IMDb Top 100 でテストしたところ、この方法にすると zurg が取得する必要のあった NZB の数が 517 から 156 に減りました。

検索とNZBのダウンロードは、インデクサーごとに同時に進行中のリクエスト数の上限を共有するようになりました。インデクサーが混雑していると返してきた場合は、その混雑が解消されるまで待機します。

品質プロファイルが設定されていない映画リクエストでも、まずリクエストされた解像度が優先されます。

シリーズの取得は変更ありません。

## zurg がサイズを把握したら、取得時にリリースを確認します {#acquisition-checks-a-release-once-zurg-knows-its-sizes}

zurgは、リリースがライブラリに現れた瞬間にニュースサーバーでそのリリースを確認していました。同じリリースのファイルサイズを調べるために読み込んでいる最中でも、確認を始めていたのです。両方が同じ接続で同じ記事を求めていたので、長いリストだとどちらも遅くなっていました。99本の映画のリストでは、最後の1本がRadarrに届くまでに9分近くかかっていました。

zurgは今、リリースのサイズが分かった後に確認するようになりました。これは、SABnzbdエンドポイント経由でSonarrとRadarrに対してすでに行っている方法と同じです。同時に確認するリリースは6本までです。サイズ確認ですでにダウンロードした最初の記事は、まだ手元にあれば再利用します。保存されたリリースが一度に大量に来ても、ライブラリの更新は1リリースごとではなく1回にまとめられるようになりました。

リリースの確認は、他のリリースのサイズ確認よりも優先して進みます。ただし、再生より優先されることはありません。また、接続数が12を超えるアカウントでは、同時にサイズを調べるリリースの数が8本から最大16本に増えました。

## 数個のピースが欠けている取得済み Usenet リリースは、失敗させる前に修復されます {#a-grabbed-usenet-release-with-a-few-missing-pieces-is-repaired-before-it-is-failed}

Radarr や Sonarr にダウンロード完了を伝える前に、zurg はリリースのピースがまだニュースサーバーにあるかを確認します。その確認で欠けているものが見つかると、リリース自身の PAR2 ファイルで欠けた分を復元できるかどうかに関係なく、その場でダウンロードを失敗扱いにしていました。すると Radarr はそのリリースを捨てて、別のものを探しに行き、多くの場合はもっと質の悪いものになっていました。今の zurg は、まず欠けたピースの復元を試み、それでもうまくいかない場合にだけダウンロード失敗として報告します。実際のグラブを 1 週間試したところ、この理由で失敗していたリリースのほとんどには、救えたはずの PAR2 ファイルが付いていました。

## 損傷した Usenet リリースは、失敗扱いされず修復の順番を待ちます {#damaged-usenet-releases-wait-their-turn-for-a-repair-instead-of-being-failed}

zurgは一度に修復できるのは壊れたリリースを最大2つまでです。修復にかかる時間は数分から1時間以上までばらつきます。3つ目の壊れたダウンロードは開始まで5分しか待てず、その後zurgがRadarrまたはSonarrに失敗を報告していました。そのため、複数が同時に届くと、修復の順番が来ないまま2つ以外はすべて破棄されていました。ログにもそのことは何も書かれていませんでした。
zurgは、修復の順番待ちの間、ダウンロードを最大3時間まで保留するようになりました。修復が順番待ちになっているときは、その旨がログに記録されます。

## Usenet のダウンロードが、いつまでもサイズ情報を待たなくなりました {#a-usenet-download-no-longer-waits-for-ever-on-file-sizes-nothing-is-going-to-learn}

zurg は、Radarr や Sonarr にダウンロードを渡す前に、各ファイルの正確なサイズがわかるまで完了を保留します。クライアントがインポート時にサイズを確認するためです。特定の再取得の後、zurg はサイズの確認を続けるのをやめたのに、まだサイズを待ち続けてしまうことがありました。そのためダウンロードはキューに残ったままになり、クライアントがあきらめるまで（多くの場合2時間後まで）止まっていました。今の zurg は、そのようなリリースのサイズを改めて確認します。さらにこれ以上サイズを確認できず、リリースのすべての部分がニュースサーバー上にそろっている場合は、クライアントに「ダウンロード完了」を通知します。

## 投稿者が最初のアーカイブボリュームだけ名前を変えた Usenet リリースが再生できるように {#usenet-releases-whose-poster-renamed-only-the-first-archive-volume-play-again}

投稿者によっては、アーカイブの最初のボリュームだけをリリース名に変更し、残りは元の名前のままにすることがあります。そのため、リリースは `Show.S02E03.part03.rar` と `show.203.r00` から `show.203.r19` までの組み合わせで届きます。

zurg はボリュームを名前でグループ化したため、不完全なアーカイブが2つあると判断し、どちらも開けませんでした。

現在は、最初のボリュームのヘッダーを読み取り、どのボリュームと一緒にすべきかを認識して、それに合わせて名前を付け直します。これにより、エピソードが再生でき、インポートもできるようになりました。

アーカイブに本当にボリュームが欠けているフォルダーでは、一般的なサーバーエラーではなく、はっきりしたメッセージで欠けていることを表示するようになりました。

## ボリュームが単に番号付けされただけの難読化 Usenet リリースが再生できるように {#obfuscated-usenet-releases-whose-volumes-are-just-numbered-now-play}

一部のリリースは、すべてのファイル名をランダムな文字列と番号の後ろに隠しています。そのため映画が `f342c135….01`、`….02` のようなファイルとして届き、テキストファイルやカバー画像も番号付きで混ざっています。zurg はこれらを1つのアーカイブの分割ファイルとして認識できず、バラバラのファイルとして一覧に出していました。その結果、Radarr と Sonarr はインポートするものを見つけられませんでした。今の zurg は番号付きファイルの先頭部分を読み、アーカイブのパートを正しい順番につなぎ合わせます（最初のパートが最後に投稿されていた場合でも）。テキストファイルと画像はその対象から外れます。

## 32 MB を超えるシーズンパックの NZB を受け付けます {#season-pack-nzbs-over-32-mb-are-accepted}

zurgは、SABnzbdエンドポイント経由で送られてくる32 MBを超えるNZBを拒否して、"request body too large"と返していました。大きなシーズンパックのNZBは、そのサイズを超えることがよくあります。526 GBのシーズンが49 MBのNZBで届いたこともあります。zurgは今、最大256 MBのNZBを受け付けます。ほぼ50万ピースある49 MBのNZBも、30秒もかからずに読み込めます。

## ラップされた Usenet 投稿のファイルが本来の名前を保持するように {#files-from-wrapped-usenet-posts-keep-their-real-names}

一部の投稿ツールは、件名の中で各ファイル名を囲みつつ、通常の引用符付きファイル名は空のままにします。例えば `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv]-[3/4]` のような形です。zurg はこのラッパーを名前の一部として残していたため、エピソードが `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv` という名前で表示され、Sonarr やメディアサーバーがそれを一致させられませんでした。zurg はこれでラッパーから名前を取り出すようになりました。ライブラリにすでにあるリリースは、修正された名前を反映させるために一度だけ読み直されます。

## 既に失敗として報告されたダウンロードは、新しいものの修復スロットを奪わなくなりました {#downloads-already-reported-failed-no-longer-take-repair-slots-from-new-ones}

zurgがRadarrやSonarrにダウンロードが失敗したと伝えると、クライアントはそれを破棄して別のものを探します。以前のzurgは、再起動のたびにそうしたダウンロードの修復を試み続けていました。その意味のない修復が修復枠を両方とも埋めてしまい、まだ救えたはずの新しいダウンロードが待たされることがありました。現在のzurgは、失敗したと報告したダウンロードの修復を行わなくなりました。

## 破損レポートにすべてのファイル名が表示されます {#damage-reports-name-every-file}

Usenetのリリースでピースが欠けていたとき、zurgの失敗メッセージには壊れたファイルの名前が並んでいました。ただ、投稿側がそもそも名前を書いていないファイルは、空欄として表示されていました: "across 4 file(s): , , , "。こうしたファイルは、リリース内での位置で表示されるようになりました。たとえば "file 12 of 73" のように書かれるので、どのファイルが影響を受けているかがメッセージでわかります。

## Stremio は、映像が空で始まるリリースをスキップします {#stremio-skips-a-release-whose-video-starts-with-nothing}

Usenetリリースの動画の先頭部分がニュースサーバーから消えていると、zurgはその部分を無音で埋めて、問題ないかのようにStremioへ渡していました。そのため、プレイヤーには何も表示されず、映画が壊れているように見えていました。zurgは再生を始める前に、最初のバイト列を確認するようになりました。そこに実際のデータがない場合は、リストの次のリリースへ移ります。これは、再生可能な中身がないリリースの場合にすでに行っている動作と同じです。途中に欠けた部分がある映画は、今まで通り再生されます。

## 破損したファイルはライブラリに残りますが、zurg は引き続き再試行します {#broken-files-stay-in-the-library-while-zurg-will-still-retry-them}

ずるぐ (zurg) が最初の試行で壊れたファイルを修復できなかったとき、翌日に再試行する予定があっても、そのファイルをマウントから取り除いていました。Plex はなくなったファイルを削除されたファイルとして扱うため、ライブラリを 1 回スキャンするだけで、エピソード、シーズン、番組全体がゴミ箱に移されてしまうことがありました。今では、zurg が次の修復試行を予定している限り、壊れたファイルはマウントに残ります。サービスがリリースを明確に拒否した場合や、中に再生可能なものが何も残っていない場合など、zurg がコンテンツが本当になくなったと確信したときにだけ取り除かれます。

## Radarr と Sonarr は、二重に取得したリリースが無効だった場合に再検索します {#radarr-and-sonarr-search-again-when-a-release-they-grab-twice-is-dead}

最初にRadarrが取得したリリースが壊れていたとき、次の検索では別のインデクサーから同じ名前のリリースが選ばれることがよくありました。zurgはその2回目の取得を、1回目と同じジョブIDで記録していました。RadarrとSonarrは失敗したダウンロードをすべてそのIDで覚えているので、新しい取得も古い失敗だと判断し、二度と確認しませんでした。失敗の記録もblocklistへの追加も、新しい検索も行われず、映画はそのまま止まってしまいました。IMDb Top 100をRadarrで実行したところ、25本の映画がこの状態で止まりました。

zurgがすでに応答済みのリリースを取得した場合、SABnzbdがすべてのダウンロードに名前を付けるのと同じように、そのリリースには独自のジョブIDが付くようになりました。そのリリースも壊れていた場合、Radarrは2回目の失敗を検知し、blocklistに追加して、再度検索します。

## 無効な Usenet リリースは、最大30分ではなく数分で失敗として報告されます {#dead-usenet-releases-are-reported-failed-in-minutes-instead-of-up-to-half-an-hour}

zurgは、取得したリリースの記事を確認してから、RadarrやSonarrに完了を伝えます。その前に、リリースのファイルサイズが確定するまで待つ仕組みになっていました。dead な投稿は、そのサイズが永遠に届かないので、確認処理が30分の待ち時間の後ろに詰まり、クライアントは何分も待たされていました。zurgがサイズの取得を試して失敗すると、今は記事をすぐに確認するようになりました。記事が消えているリリースは失敗として報告されるので、クライアントは別のリリースに移れます。

読み取り中に破損が見つかったリリースは、`enable_repair: false` の場合でもPAR2修復のために5分待たされていました。修復が走らない場合、この待ち時間は省略されるようになりました。

IMDb Top 100 を Radarr 経由で実行したところ、取得したリリースの半分以上が dead でした。このケースでは、この2つの待ち時間が、映画が zurg 内で過ごす時間のほとんどを占めていました。

## インポート中に破損していると判明したリリースは失敗扱いになるため、Radarr は別のものを取得します {#a-release-that-turns-out-damaged-during-import-is-failed-so-radarr-grabs-another}

zurg は、Radarr にリリースの準備ができたと伝える前に、ファイルごとに 1 記事だけをチェックします。そのため、ファイルの途中にギャップがあるリリースでもチェックを通過してしまうことがあります。その後 Radarr のインポートがそのギャップに達すると、zurg はファイルの移動を拒否します。これは正しい動作ですが、ダウンロードが失敗ではなく未完了のまま残ってしまっていました。その結果、Radarr は映画を "import blocked" 状態で止めてしまい、別のコピーを探すことはありませんでした。IMDb Top 100 を Radarr で流したとき、5 本の映画がこの状態で止まりました。

インポートが拒否された場合は、ダウンロードを失敗としてマークするようになりました。Radarr はそのリリースをブロックリストに入れ、別のリリースを検索します。

## 完全に難読化されたリリースでも、名前のない映像ファイルが出力されなくなりました {#a-fully-obfuscated-release-no-longer-comes-out-with-a-nameless-video-file}

When a Usenet post hides every filename, zurg works out what the main file is from its first bytes and names it after the release, the way SABnzbd does. That check came last in a pass with a ninety-second limit, and when grabs arrived in a burst the limit could run out first. The video file was then published under the release's name with no extension at all, which Radarr and Sonarr skip, so the download sat in their queue waiting for a file they could import.

Usenet の投稿でファイル名がすべて隠されている場合、zurg は最初のバイト列からメインのファイルを特定し、SABnzbd と同じようにリリース名を付けます。このチェックは、90 秒の制限がある処理パスの最後に行われていました。grab が一気に届くと、この制限時間が先に切れることがありました。すると動画ファイルは拡張子のないリリース名のまま公開され、Radarr と Sonarr はそれを読み飛ばしてしまいます。その結果、ダウンロードは取り込めるファイルを待ったまま、キューで止まっていました。

Now a release is named again, up to three times, until zurg has been able to look at the file, and only then shown to your library and your *arr. In a run of the IMDb Top 100 through Radarr this was Seven Samurai, a 42 GB .mkv.

今では、zurg がファイルを確認できるまで、リリースは最大 3 回まで名前付けし直されます。その後で初めてライブラリと *arr に表示されます。IMDb Top 100 を Radarr 経由で実行したときの例が Seven Samurai で、42 GB の .mkv でした。

## ファイル名にアクセント記号や CJK 文字を含むリリースも、名前全体が保持されます {#releases-with-accents-or-cjk-in-their-filenames-keep-their-whole-names}

A release whose files are named with anything outside plain English letters came
out of zurg with the front of every name missing. `Détective Conan S11E01 - 286
[MULTI] [AVC].mkv` was served as `tective Conan S11E01 - 286 [MULTI] [AVC].mkv`,
and a Chinese or Japanese title lost even more, because everything up to the last
such character was dropped.

Sonarr and Radarr could not do anything with what was left. A name like `tective
Conan S11E01` matches no series, so they fell back to the download's grab history,
refused to import on that alone, and parked the item with "release was matched to
series by ID. Automatic import is not possible." The release sat in the queue and
nothing moved it.

It could also cost you files. When the only thing telling two files apart sits
after the last accented character, both come out with the same name, and a name
is a path. One French release with ten repair volumes had all ten reduced to the
same name and published four files where the post holds thirteen, leaving the
repair data with no way to reach it.

zurg now reads every character above plain ASCII as part of the filename, which
is what it always is: the part counters, the `yEnc` marker, the brackets and the
file extensions posters write are all plain ASCII, so anything else belongs to
the title. Releases named in plain ASCII are unaffected and come out exactly as
before.

Releases already in your library keep the names they were filed under, since
zurg does not revisit a file list it has already recorded. Re-adding an affected
release picks up the corrected names.

## 日本語、韓国語、中国語、タイ語、アラビア語で書かれた名前はそのまま残ります {#a-name-written-in-japanese-korean-chinese-thai-or-arabic-is-left-alone}

zurgは、アーカイブ内のファイル名がその中身について何も語っていない場合に、そのファイルの名前を変更します。そのため、ハッシュ値のような名前で投稿されたリリースは、代わりにリリース本来の名前で届くようになります。その判断では大文字と小文字を比べる必要がありましたが、多くの文字体系には大文字も小文字もありません。`오징어 게임 S01E01`というファイルは大文字と小文字がそれぞれ0個と数えられ、通常の名前のテストに落ちてしまいました。その結果、ハッシュであるかのように名前が変えられ、S01E01まで含めて書き換えられていました。漢字、かな、ハングル、タイ文字、ヘブライ文字、アラビア文字はすべて影響を受けていました。

大文字・小文字のない文字は、判断を失敗にするのではなく、そこで判断を終えるようになりました。これらの文字体系の名前は投稿されたとおりに残ります。ハッシュの名前変更はこれまでどおり行われます。

また、zurgは1つのリリース内の2つのファイルが同じ名前になった場合に、ログにその旨を表示するようになりました。名前はパスなので、こうなるとリリースが持っているより少ないファイルしか提供されず、余分なファイルは開けなくなります。以前は何も報告されていなかったため、前のエントリーのアクセント付きファイル名の不具合にも気づけませんでした。それに気づく手がかりは、フォルダーの一覧の行数が想定より少ないことだけだったのです。

## ファイル名の修正が、既に持っているリリースにも反映されるようになりました {#the-filename-fixes-now-reach-releases-you-already-have}

上の2つのエントリで、zurgがUsenetの投稿からファイル名を読み取る方法を変えました。ただ、zurgは各NZBを読んだ結果を保存しておき、起動のたびにその結果を再利用します。監視ディレクトリ全体を毎回読み直すわけではありません。保存されていた結果がまだ古いままだったので、アップグレード後も、すでに持っていたリリースは以前と同じ間違った名前で表示され続けていました。修正後の名前になったのは、新しく追加されたNZBだけでした。

zurgは、投稿の読み方が保存済みの結果を作ったときと違うことを検出すると、NZBを読み直すようになりました。アップグレード後の最初の起動では、監視ディレクトリ内のNZBをすべて1回ずつ読み直します。そのぶん少し時間がかかりますが、その後は通常どおりに戻ります。ダウンロードし直すことはなく、記事を取得することもありません。ディスク上にすでにあるファイルを読み直すだけです。

影響を受けていたリリースがあれば、そのファイルは投稿で付けられていた名前で表示されるようになります。ダウンロードクライアントに以前の失敗したインポートがまだ残っている場合があります。そのため、SonarrやRadarrでインポートできずに止まっていたリリースは、再度試す前にそのキューのアイテムを削除する必要があります。

## 句読点を含むタイトルも、名前全体が保持されます {#titles-with-punctuation-in-them-keep-their-whole-names-too}

このリストの上のほうにあるファイル名の修正で、zurg がアクセント付きの文字や中国語の文字で名前を切ってしまう問題は解決しました。ただ、まだ不十分でした。zurg はファイル名として使える文字を一覧にして判断していましたが、その一覧には普通によく使われる記号が 20 個抜けていました。そのため、それらの記号を含むタイトルは同じように、その記号のところで切られていました:

    Tom & Jerry - The Movie.1992.1080p.mkv   ->   Jerry - The Movie.1992.1080p.mkv
    Mairimashita! Iruma-kun (2026) [22].mp4  ->   Iruma-kun (2026) [22].mp4

`!`、`&`、`#`、`$`、`%`、`@`、`~`、`;`、`=`、`^` のすべてがこの原因でした。

タイトルに使われうる文字を一覧にしておく方法はきりがありません。そこで zurg はもうそれをやめました。名前はそのままファイル名になります。ファイル名に確実に使えない文字は、どのファイルシステムも受け付けないものだけです: `/ \ : * ? " < > |`。それ以外の文字はすべてタイトルの一部として扱うようになりました。

大きな監視ディレクトリにあるすべての NZB で確認しました。単純なファイル名になっている subject のうち、この変更前に短くなっていたものは、ほぼすべて今では名前全体が残ります。まだ短くなるのは、インデクサーがダウンロードごとに付ける刻印を取り除いたものだけです。これは正しい動作です。

（以前の翻訳は、コードスパンが一致しないため却下されました。構造をそのまま保ってください。）

## ファイル名が変更されたリリースは、新しい名前を自動的に取り込みます {#a-release-whose-files-were-renamed-picks-the-new-names-up-on-its-own}

上の修正でファイル名の付け方が変わったため、zurgがUsenetリリース内のファイルをどう呼ぶかも変わりました。ただ、ライブラリにすでにあるリリースは、必ずしもその変更に気づいていませんでした。zurgは既知のリリースを、新しく取得したリストと、各ファイルに保存されたリンクで照合します。Usenetのリンクにはリリース内でのファイルの位置が含まれています。修正後の名前が古い名前と並び順が変わると、その位置も変わります。すると保存されたリンクは同じファイルを指さなくなり、照合する手がかりがなくなるため、古い名前のままになっていました。

今回からは、位置の代わりにファイルサイズを使うようになりました。サイズは変わりません。リリース内で同じサイズのファイルがちょうど1つだけあれば、そのファイルだと判断して新しい名前を付けます。同じサイズのファイルが2つ以上あるときは、推測して別のエピソードの名前を付けてしまうのを避けるため、名前を変更しません。

位置が変わらなかったリリースは、以前から新しい名前が反映されていたので影響ありません。また、ファイル名を変更してもリンクが動かないその他のバックエンドも影響を受けません。

## マウントが読み取れないファイルがあっても、他のものの処理を止めなくなりました {#a-file-the-mount-cannot-read-stops-holding-everything-else-up}

読み込みが失敗し、その原因を zurg が特定できなかった場合、zurg はクライアントに再試行するよう伝えていました。そしてそのファイルが失敗し続けるあいだ、ずっとそう伝え続けていました。rclone はこれを真剣に受け取ります。そのようなファイルを1回読むだけで、諦めるまでに 55 秒と 36 回ほどのリクエストを費やしていました。さらに rclone はエラーを返し続けるサーバーへの接続全体の速度を落とすため、次の正常なファイルを開くのに、本来の 0.04 秒ではなく 3.66 秒かかっていました。

今では、同じ失敗が 1 分続いた時点で再試行をやめます。読み込みへの応答は、壊れたファイルの読み込みがすでにそうだったのと同じ形になります。ファイルはライブラリの一覧に残り続け、同じ読み込みは 0.5 秒で終わります。

zurg は今でも毎回ダウンロードを試みるので、戻ってきたファイルは次の読み込みで取り込まれます。

## 読み取りをやめると、マウントはダウンロードを停止します {#the-mount-stops-downloading-once-you-stop-reading}

ライブラリのスキャンや字幕チェックなど、短時間に多くのファイルに触れる処理で、読み込んだ量よりはるかに多くのデータを debrid アカウントから取得していました。

rclone 1.74 では、最後にプログラムがファイルを閉じた後も、そのファイルのダウンロードを5秒間続けるようになりました。それらのバイトを待っているものは何もなく、高速なアカウントでは5秒間で1ファイルあたり数百MBになります。20ファイルからそれぞれ1 MiBずつ読むと、以前は80 MiBだったのに、4.2 GiB取得されていました。

zurg ではこの動作をオフにしました。rclone 1.73 以前のバージョンでマウントしている場合は影響がなく、動作も変わりません。そのオプション自体が存在しないためです。

zurg のマウントではなく、自分で rclone を実行している場合は、rclone 1.74 以降でマウントコマンドに `--vfs-handle-caching 0` を追加してください。詳しくは README を参照してください。

## あるリリースのアーカイブボリュームが1つ欠けても、残りを失わなくなりました {#a-release-that-loses-one-archive-volume-no-longer-loses-the-rest}

複数パートの rar または 7z セットとして投稿された Usenet リリースは、インポートがまったく進まなくなることがありました。Sonarr と Radarr は "Waiting for import" のまま止まり、次に進むことがありませんでした。リリースのフォルダーには rar パートだけが残るか、そもそも存在しなくなっていました。

zurg はセット内のボリュームを 1 つ読めないと、そのボリュームを除外して、次のリスティングをそれ抜きで進めていました。そのリスティングではセットが 1 ボリューム足りない状態と判断され、その後ろのボリュームで処理を止めて、そのボリュームも除外していました。リリースのボリュームは、リスティングのたびに 1 つずつ(おおよそ 10 分に 1 つ)失われていき、なくなると、ライブラリからも、ダウンロードクライアントがインポート元にしているフォルダーからも消えていました。Sonarr にとって、パスが存在しないのは空のフォルダーがあるのとは違います。永遠に失敗し続けるインポートになってしまうんです。

読めないと分かっているボリュームは、今ではセットに残るようになりました。どのリスティングも同じボリュームで止まり、そのボリュームについて同じ内容を報告します。そのため、投稿の一部が欠けているリリースは一度だけそう報告され、クライアントはそれをブロックリストに入れて、別のコピーを探しに行けます。

すべてのボリュームが読めるリリースには影響ありません。

## スキャンは、ライブラリが `__magic__` 配下の新しい場所に移動しても追従します {#scans-follow-the-library-into-its-new-home-under-__magic__}

2026.09.17.2240-nightly で、ライブラリーのミラーが `__magic__` から `__magic__/__all__` の下に移動しました。zurg の一部は、まだ古い場所を指し続けていました。

新しいリリースが届くと、zurg が Plex や Jellyfin にスキャンを依頼する先は、そのリリース以降存在しないフォルダーになっていました。そのため何もキューに入らず、新しいコンテンツはメディアサーバー自身の定期スキャンを待つことになっていました。`on_library_update` スクリプトを使っている人にも、同じパスが渡されていました。

現在は、どちらもダウンロードクライアントがインポート元として指定されたフォルダーを指すようになりました。リリースが追加されたり削除されたりしたときに、zurg がマウントのキャッシュから削除する一覧も、同じフォルダーを使います。

## ウォッチリストは、Torznab インデクサーからのトレントも扱えるようになりました {#the-watchlist-can-take-torrents-now-from-torznab-indexers}

これまで、ウォッチリストや Seerr のリクエストは Usenet からしか満たせませんでした。インデクサーに `type: torznab` を追加すると、zurg はそこも検索するようになります。torrent の結果は `nzbs/` に書き込まれる代わりに、debrid アカウントに渡されます。

**渡されるのは、すでにそのリリースをキャッシュしているアカウントだけです。** キャッシュはアカウントごとに独立しているため、アドを受け付けるすべてのアカウントにハッシュが提示されます。そして、そのリリースを最初に持っていたアカウントがそれを受け取ります。どこにもなければ、単にうまくいかなかった候補というだけなので、zurg は次のリリースに移ります。次のリリースは別の torrent の場合も、NZB の場合もあります。アカウントに何かがダウンロードされることも、uncached のアド枠を消費されることも、誰も待っていないものが動き続けることもありません。

両方の種類のインデクサーが応答できる場合は、`prefer` がどちらを先に試すかを決めます。指定しなければ `usenet` になるので、Newznab インデクサーしかない環境は以前とまったく同じように動作します。`torrents` にすると順序が逆になります。`best` にすると、torrent かどうかに関係なく、ランキングで一番上に来たものを使います。

torrent の取得も、ほかのものと同じようにチェックされますが、確認される内容が違います。アカウントはすでにそのコンテンツを持っていると答えているので、チェックするのは、リリースがファイル付きでライブラリに届いたかどうかです。中身が空と表示されたリリースは取り除かれ、次のリリースに順番が回ります。

Torznab インデクサーだけで取得を実行することもできます。その場合、`nzb` プロバイダーは必要ありません。

## ライブラリを読み取るエージェントが、すべてのリリースを空と判断しなくなりました {#an-agent-reading-the-library-no-longer-calls-every-release-empty}

zurg の MCP の一覧は、リクエストされたときだけリリースのサイズを計測します。ライブラリ全体のファイルテーブルを走査するには実際に時間がかかるためです。計測していないリリースについては、サイズとファイル数をゼロとして返していました。しかし回答のどこにも、そのゼロが「未計測」を意味するのか「何もない」を意味するのかは書かれていませんでした。そのため、ディレクトリの一覧を頼まれたエージェントは、6.6 GB の映画にはファイルがないと答えてしまうことがありました。一方、単一リリース用のツールは最初から正しい答えを返せていたのです。

計測していない一覧では、ゼロを返す代わりに両方の数値を省くようになりました。取得したい場合は `with_size` を指定するか、サイズでソートするか、サイズのフィルターを使ってください。`zurg_library_search` も `with_size` を受け付けるようになりました。以前は受け付けていなかったため、サイズを取得するために結果を絞り込んだり並べ替えたりする必要はなくなりました。

## zurg doctor で MCP エンドポイントが応答しているかを確認できます {#zurg-doctor-says-whether-the-mcp-endpoint-is-answering}

`zurg doctor` は、ダッシュボードのポートが応答するかを確認するだけで終わっていたため、`/mcp` については何も分かりませんでした。設定で有効になっているのに、`username` が空などの理由でサーバーが提供を拒否しているエンドポイントは、外から見ると正常に見えます。その理由は起動ログの1行にだけ出て、ほかには何も表示されませんでした。

`mcp.enabled` が設定されている場合、`doctor` は `/mcp` に対してプロトコルで実際に通信し、その結果を報告するようになりました。結果は「応答している」「設定された認証情報を拒否している」「有効だが提供されていない」のいずれかです。エンドポイントが無効になっているインスタンスには問い合わせを行わず、この項目の行も表示されません。

## ブラウザで MCP エンドポイントを開くと、それが何であるかが表示されます {#opening-the-mcp-endpoint-in-a-browser-now-tells-you-what-it-is}

`/mcp` をブラウザで開くと、「Bad Request: GET requires an Mcp-Session-Id header」と表示されていました。これは正しい応答ですが、誰も聞いていない質問への答えでした。このエンドポイントは、ブラウザで開かれたときに自分自身の説明を表示するようになりました。表示される内容は、話している プロトコル、クライアントに指定するアドレス、stdio ブリッジ用のスニペット、このビルドのバージョン、そして現在提供しているすべてのツールです。ツールはツールセットごとにまとめられ、ツールが何をするかを説明するだけで確認を待つものには印が付きます。

この一覧は、手で別に管理しているコピーではなく、ツール登録の結果そのものです。そのため、`read_only`、ツールセットの設定、またはライフサイクルの切り替えによって非表示になったツールは、呼び出せるものとして表示されません。エンドポイントが認証なしで提供されている場合も、そのことをページに表示します。

既存のクライアントには影響ありません。このページは、HTML を要求し、セッションを持たない GET に対してだけ返されます。これはブラウザであり、MCP クライアントではありません。クライアント自身が送る GET は、これまで通りイベントストリームを開きます。

## Usenet 再生で接続の許容枠をより早く使い切るようになりました {#usenet-playback-fills-the-connection-allowance-sooner}

Usenetの読み取りでは、要求された範囲の残りを提供する前に、再生ヘッドにある記事をアカウントスケジューラに入れるようになりました。大きな範囲がパイプライン接続に分割される場合、連続する記事は各接続に順番に割り振られます。以前のように、最初の接続が最初の4記事、2番目の接続が次の4記事を受け持つ方式ではありません。そのため、最初に役立つ記事は後ろのバイトを待たずに、最初の接続ラウンドで返ってきます。

小さな記事のアーカイブ投稿では、少なくとも64 MiBにわたる先読みウィンドウが使われます。記事サイズが数MBある最近の投稿では、既存のウィンドウをそのまま使います。記事数が増えてもメモリ使用量は増えません。投機的な本文は2つのリーダーと`cache_size_mb`の半分(デフォルトでは256 MiB)に制限され、記事キャッシュには既存のハードリミットがそのまま適用されます。再生サイズのリクエストは128 MiBではなく64 MiBから始まるため、90 MiBのプレイヤーバッファはシーク/プローブ経路に入らなくなります。小さなシークは引き続きこの経路を使います。

停止したパイプラインバッチでは、異なる記事を最大5件まで同時にヘッジできます。アカウントごとの「シーク要求は1分あたり20件」という既存の上限は変わりません。また、先読み、修復、クライアントがブロックされていないその他の作業は、引き続きヘッジされません。

複数ボリュームのアーカイブを開く処理も軽くなりました。PAR2によって各ボリュームの正確な長さがすでにわかっている場合、1つのボリュームの検証済みyEncヘッダーから、大きな兄弟セット全体に共通する記事のストライドを求められます。各兄弟ボリュームは、最初のバイトを返す前に、自分のヘッダーからその推定を検証します。そのため、ボリュームごとに記事を1つずつ直列に取得する必要がなくなり、データに対して推定されたジオメトリを信用しすぎることもありません。ファイル名の復元も、記事全体のダウンロードを待つ代わりにyEncヘッダーから答えを返すようになりました。

## 保存された .strm ファイルは Base URL の変更に追従します {#saved-strm-files-follow-a-base-url-change}

Base URL を変えても、`strm/` にすでにあった `.strm` は古いアドレスを指したままでした。再起動しても直らなかったのは、zurg が存在しないファイルしか書いていなかったからです。今回から、zurg が書くはずの URL と違う `.strm` は、その場で書き直されるようになりました。これは起動のたびに行われ、ダッシュボードで Base URL を変更したときや、そこで `save_strm_files` をオンにしたときにもすぐ実行されます。すでに正しいファイルはそのまま残すので、メディアサーバーがフォルダー全体を毎回スキャンし直すことはありません。

Jellyfin は `.strm` から読み込んだ URL を覚えていて、新しい URL には次回のライブラリスキャンで切り替わります。古いビルドのアカウントリンクがまだ入っている `.strm` も書き直され、アカウントを自動で切り替えられて修復にも耐える形式になります。`strm/` 内で手で編集した `.strm` は上書きされるので、使いたいアドレスは Base URL に設定してください。

## Plex ウォッチリストを有効にしても空になりません {#turning-the-plex-watchlist-on-no-longer-empties-it}

ウォッチリストを有効にすると、以前は全体を未処理の一覧として読み込み、1件ずつ削除しながら処理していました。最初の実行では、163件のリストから121件のタイトルが約4分で取り除かれました。Plexは削除されたウォッチリストの項目を記録しないため、元に戻す方法は事前に取ったスナップショットだけでした。しかも、設定にもログにも、これから何が起きるかの説明はありませんでした。

今では、取得がリストに何をするかを決める2つの設定があります。これらはzurgではなく、あなたのリストに対する設定です。

**`watchlist.only_new_items`** はデフォルトでオンです。ウォッチリストをオンにすると、その監視が始まります。リストに既にある項目は処理済みとして扱われ、その後に追加した項目が取得されます。この設定は最初の実行時に1回だけ適用され、既存のキューを上書きすることはありません。そのため、ウォッチリストを順番に処理していた環境は、これまでどおり動き続けます。

**`watchlist.remove_after_grab`** もデフォルトでオンで、この機能が以前からしてきた動作です。そのため、自分で変更しない限り何も変わりません。オフにすると、ウォッチリストはウォッチリストのまま残ります。何を見るかを決めるために閲覧するリストであり続け、zurgはリストを編集せずにバックグラウンドで条件を満たしていきます。リストに残したままのタイトルを再確認する負担はありません。記録がすでにそのタイトルをカバーしているため、インデクサーに改めて問い合わせることもないからです。

どちらの設定も設定ページにあり、次回の再起動時に反映されます。`acquisition.sources` で個別に指定した取得ソースでは、ソースごとにどちらも設定できます。Seerrのソースには意味がありません。zurgが書き込むリストを持たないためです。

## ウォッチリストと Seerr のリクエストは、ニュースサーバーの応答を待ってからクリアされます {#watchlist-and-seerr-requests-wait-for-the-news-servers-before-they-are-cleared}

以前は、NZB が監視ディレクトリに届いた時点でグラブが完了扱いになっていました。インデクサーが応答し、その応答が NZB として解析でき、ファイルが書き込まれた。これらはインデクサーについての3つの事実にすぎず、投稿そのものについては何も分かっていません。それを根拠にリクエストがクリアされ、Plex のウォッチリストの場合はエントリが削除されます。削除されたエントリを Plex は記録しません。つまり、壊れた投稿は、中身を1バイトも読まれる前に、そのタイトルを求めていたという唯一の記録を消してしまっていたのです。163件のウォッチリストを1回実行したところ、121タイトルが削除され、その背後にあったリリースのうち12件は読み込めませんでした。

取得したリリースは、何かを承認する前に、ニュースサーバーで中身を確認するようになりました。これは 08.28 nightly 以降、SABnzbd エンドポイントが行ってきたのと同じチェックです。結果は3つあり、それぞれ別々に扱います。

- **記事がありません。** そのグラブは数えません。タイトルはウォッチリストに残り、リクエストは未完了のままになります。リリースは壊れていたものとして記憶されるので、次の試行では、ライブラリにすでにあるものを選び直すのではなく、次の候補が順位に従って選ばれます。既知の壊れたリリースは、コストがまったくかかりません。取得されず、1回の試行で試される3つの候補にも数えられません。そのため、ランキングの上位に壊れた投稿が並んでいても、何度も再試行して止まることはなく、順に飛ばされていきます。壊れていると判明したシーズンパックは、そのシーズン全体が再び求められた状態に戻るので、個別のエピソードが代わりに取得されます。
- **サーバーに問い合わせられませんでした。** プールがダウンしている、アカウントがスロットリングされている、あるいは単にライブラリがまだ新しい NZB を一覧に出していない、といった場合です。何も確認できていないので、何も判定しません。リクエストは待機し、もう一度確認されます。待機中はリトライ回数を消費しません。約2時間経っても確認できないリリースは、壊れたものと同じ扱いで脇に置かれ、次のリリースに順番が回ります。確認できなかったリリースで、タイトルがクリアされることは決してありません。
- **リリースは存在します。** 以前と同じです。

Usenet アカウントがない環境では、問い合わせる先がないため、これまでと変わりありません。

## 遅いニュースサーバーでも、大きなリリースの確認が時間切れにならなくなりました {#checking-a-big-release-no-longer-runs-out-of-time-on-a-slow-news-server}

zurgは、グラブが完了と報告される前に、その中のすべてのファイルについてニュースサーバーに問い合わせます。以前はファイルを1つずつ問い合わせていました。なかには、一度に1つずつ順番にしか答えないアカウントがあり、すべてをひとつの接続で一斉に送っても速くなりません。あるプロバイダーのサーバーは、1ファイルあたり5秒以上かかりました。そのため、133ボリュームの4Kリリースでは問い合わせだけで約12分かかり、どのチェックにも5分しか与えられていませんでした。チェックは最後まで終わらず、Sonarr と Radarr は3時間待ったあとに、グラブが失敗したと判断しました。ウォッチリストもいつまでも待ち続けていました。

今は、いくつかのファイルをまとめて同時に問い合わせるようになりました。アカウントで使える接続のうち、再生用に確保しておく1本を除いたすべてを使います。そのため、アカウントで許可される接続が多いほど、大きなリリースのチェックも速く終わります。以前は一度も完了できなかった133ボリュームのリリースで測ると、12接続では2分未満で終わります。4接続では、まだ時間切れになります。問い合わせ自体に時間がかかるためです。小さなリリースでは、以前と比べて遅くなることはありません。

時間内にチェックを通せないリリースは、もうタイトルをブロックし続けることはありません。ウォッチリストは、壊れたリリースと同じように除外して、次のリリースを試します。SABnzbd のエンドポイントは、これまでどおり失敗として報告するので、Sonarr と Radarr は別のリリースを探しに行きます。

## TorBox でのキャッシュ済みのみの取得が、本来スキップすべきリリースをダウンロードしなくなりました {#cached-only-grabs-on-torbox-no-longer-download-the-releases-they-were-meant-to-skip}

TorBox には、持っていないものを追加しようとすると拒否するフラグがあります。API にはありますが、ドキュメントにはどこにも書かれていません。zurg はこれを使っていませんでした。そのため、キャッシュのみの取得では、まずトレントを追加して完了するかを待ち、実際にはダウンロードが必要だとわかると削除していました。その結果、アカウントの 1 時間あたり 60 回の追加枠を 1 つ消費し、転送スロットを占有し、*arr がすでにスキップするよう指示していたリリースのデータを取得してしまっていました。

キャッシュのみの取得では、コンテンツを指定して追加するようになりました。TorBox が持っていない場合は、1 秒以内に拒否され、アカウントには何も残りません。それでもミス時には 1 時間あたり 60 回の追加枠を 1 回消費するため、zurg は今まで通りその追加をペース調整します。ヒットした場合も、そのまま信じるのではなく確認します。TorBox のキャッシュは、実際には配信できないコンテンツに対して「あり」と答えることがあるためです。そのため、zurg はリリースを報告する前に、ダウンロードが完了するまで待ちます。

## Debrid-Link でのキャッシュ済みのみの取得が、1日あたりの追加許容数を消費しなくなりました {#cached-only-grabs-on-debrid-link-no-longer-spend-the-daily-add-allowance}

Debrid-Linkは、magnetだけでなく生のinfo hashも受け付けます。ただし、Debrid-Linkがすでにそのコンテンツを持っている場合にしか、hashを追加しません。

以前のzurgはmagnetを送っていました。magnetは「取得しろ」という指示です。そのため、キャッシュ専用の取得で外れたものも、すべて受け入れられていました。そしてアカウントの1日50件の未キャッシュ追加枠と20個の転送スロットのうち1つを消費し、そのあと枠を取り戻すために削除されていました。外れが50件になると、日次リセットまでアカウントは他に何も追加できなくなっていました。

キャッシュ専用の取得では、今後hashを送るようになりました。外れは約0.1秒で即座に拒否され、アカウントには何も残りません。そのため、*arrは長いリリース一覧を、誰も持っていないものに枠を使うことなく順番に処理できます。

これは.torrentファイルとして届いた取得にも当てはまります。.torrentファイルは、生のhashだと必要になるメタデータの照会をサービス側で省くためのものです。しかし、キャッシュの確認にはそのような照会は不要です。

## Debrid-Link のレート制限によるロックアウトの後、再試行の間隔を空けるようになりました {#debrid-link-rate-limit-lockouts-are-backed-off-from-again}

Debrid-Link は、エンドポイントごとに1時間続くロックアウトを HTTP 503 とボディ内の理由で通知します。zurg はすべての 503 をサービスが一時的にダウンしているものとして扱っていたため、理由を読み取らず、1時間待つよう指示されているエンドポイントに再試行を続けていました。現在は、このロックアウトを認識し、解除されるまでそのエンドポイントを使わないようになっています。

## `__magic__` はライブラリを `__magic__/__all__` に反映するようになり、ルートは自由に使えます {#__magic__-now-mirrors-your-library-at-__magic____all__-leaving-its-root-to-you}

名前空間はもともとルート直下に `__all__` のミラーを持っていました。そのため、ダウンロードクライアントがインポートするフォルダーが、すべてのリリースがすでに置かれているフォルダーと同じになっていました。Sonarr や Radarr のルートフォルダーは、この構成で出る2つのヘルスチェックを避けるために、ダウンロードフォルダーの *内側* に入れる必要がありました。また、ダウンロードフォルダーを指定して手動インポートすると、1つのリリースを探すためにライブラリ全体を歩き回っていました。

ミラーは1階層下に移動しました。`__magic__/__all__` は `__all__` が一覧にしているライブラリで、`sabnzbd.complete_dir` と `qbittorrent.save_path` が今これを計算します。`__magic__` 直下はあなたのものです。\*arr に指定する `tv`、`movies`、`anime` のフォルダーはここに置きます。この2つは兄弟関係なので、どちらかがもう一方を含むことはなく、どちらのクライアントも警告を出しません。

**パスが変わります。** `sabnzbd.complete_dir` や `qbittorrent.save_path` を手動で設定している場合（コンテナーのマッピングを使っている場合など）は、末尾に `/__all__` を追加してください。Plex や Jellyfin のライブラリを `__magic__` そのものに向けていた場合（フォルダーの中ではなく）、パスは1階層ずれます。`__magic__/__all__` か、インポート先のフォルダーに向け直してください。ルートフォルダーは動きませんし、テーブルに保存されているものも何も動きません。配置先は自分で作ったフォルダー配下のパスで、tombstones はリリース単位でキー付けされているので、既存のレイアウトはそのままです。アップグレードしたときに、まだ処理中の grab は古いパスを持っているので、もう一度 grab し直す必要があります。

`__magic__/__all__` には何も書き込めません。そこに行を作ると、すでにアドレスを持っているリリースに2つ目のアドレスができてしまうためです。そのため、そこを狙った MOVE、MKCOL、DELETE は拒否されます。リリースフォルダーの *内側* への書き込みは変わりません。\*arr が、インポートしたファイルの横に .nfo を置くときがこれにあたります。

## ログのエクスポートで、リンクの行き先と有効期間が分かるようになりました {#export-logs-now-tells-you-where-your-links-went-and-how-long-they-last}

Export Logs は複数のペーストホストを順に試し、ファイルを受け付けた最初のホストのリンクを渡します。どのホストを使ったかは表示されていませんでしたが、ホストによって保持期間が同じではありません。優先ホストはペーストを 180 日間保持し、誰かが読むたびに期限を延長します。一方、フォールバックのホストは 3 日後に削除します。見た目が同じリンクなのに、金曜日に提出したレポートが月曜日には 2 つとも無効なリンクになっていて、理由もわかりませんでした。今後は、リンクと一緒に、保持しているホストとその期限が表示されるようになりました。

フォールバックのホストに振り分けられていた理由が、この件の後半です。優先ホストは、短時間に何度もアップロードするアドレスをブロックします。エクスポートは 1 回のクリックで 2 つのファイルを公開するため、バグレポートが続くとそのアドレスは拒否されていました。その後は、そのマシンからのリクエストがすべて拒否され、保存済みのペーストを読み戻すことさえできなくなっていました。それでも zurg は、その後のエクスポートのたびに両方のファイルをそのホストへ送ろうとし、毎回アップロードの失敗としてログに記録していました。そのため、原因がアドレスではなくファイルにあるように見えていました。今では、マシンを拒否したホストには 1 日間アクセスしないようになっています。ログにも、その理由が記録されます。

## デバッグ情報をアップロードしても、インデクサーとダウンロードクライアントのキーが公開されなくなりました {#uploading-debug-info-no-longer-publishes-your-indexer-and-download-client-keys}

Export Logs は、設定ファイルをペーストサイトに送る前に、見つけた認証情報をすべて伏せ字にしています。ただし、チェックしていたのは最上位の項目だけでした。ネストされたブロックの中のキーはそのまま平文で送信されていたのです。対象になっていたのは、Stremio リストと watchlist リストの両方にある Newznab インデクサーの API キー、Stremio アドオンのトークン、SABnzbd と qBittorrent の API キー、zrok のアカウントトークン、Plex のスキャントークンです。特に注意が必要なのはインデクサーの API キーです。これは zurg のものではなく、あなたの Usenet アカウントのものだからです。

これらはすべて伏せ字になりました。プロバイダーのトークンとニュースサーバーのパスワードは、もともと影響を受けていませんでした。

## zurg は AI エージェントから操作できます {#zurg-can-be-driven-by-an-ai-agent}

新しく `/mcp` エンドポイントが追加されました。Model Context Protocol (MCP) に対応しているので、Claude のようなクライアントから、ライブラリを検索したり、リリースが再生できない理由を調べたり、修復したりできます。ダッシュボードの HTML を読む代わりに、型付きのツールとして操作できます。

この機能はデフォルトでは無効です。`mcp: {enabled: true}` を設定して有効にしてから、クライアントで `http://your-zurg:9999/mcp` を指定してください。認証にはダッシュボードと同じユーザー名とパスワードを使います。stdio のみに対応しているクライアントは `zurg mcp` を使います。これは新しいインスタンスを起動せず、すでに動いているインスタンスに接続します。

ツールに加えて、zurg 自身のドキュメントとライブの状態を、クライアントが直接読めるリソースとして提供します。また、確実に従うべき手順をまとめた 6 つのプロンプトも用意しています。たとえば、再生できないリリースの診断、Plex スキャンを安全に準備する手順、修復が諦めたものの仕分けなどです。

勝手に行ってはいけない操作も理解しています。何かを削除するような操作は、まず何をするかを説明し、表示された計画をあなたが正確に確認した場合にのみ実行します。`read_only: true` を設定すると、変更を伴うツールはすべて提供されなくなります。zurg やそのマウントを停止できるツールは、それぞれ専用のスイッチの背後に置いてあります。どの結果にも、トークン、パスワード、解決済みリンクは含まれません。

詳しくは [MCP サーバー](mcp.md) をご覧ください。

## zurg は、ビルドが古くなっているときにそれを知らせます {#zurg-says-when-your-build-is-out-of-date}

zurgは、これまでビルドが何日前に作られたものかを一切表示していませんでした。そのため、8月に修正されたバグが9月のバグレポートに出てきて、そのときにはすでに修正から3週間経っていた、という事態が起きました。スレッドの中で、それを疑う理由を持つ人は誰もいませんでした。

現在のzurgは、1日に1回、公開リポジトリに最新リリースを問い合わせます。使用中のビルドがそれより古い場合は、リリース名、そのリリースの日付、そしてあなたのビルドの日付を書いた1行をログに出力します。

それ以外のときは静かです。最新版を使っている場合は何も表示されず、GitHubに接続できない場合も何も表示されません。また、ビルドの作成日時がわからないビルド（Dockerイメージがこれにあたります）については、推測は行いません。

nightlyビルドを使っているスポンサーは、常に最後の公開リリースより新しいため、この通知は一切表示されません。

結果は1日キャッシュされるため、再起動してもリクエストは発生しません。リクエストが拒否された場合は、翌日まで再試行しません。機能全体は `disable_update_check: true` で無効にできます。

## アーカイブされたリリース内の無効なリンクは、毎回の確認で正常と判定されなくなりました {#a-dead-link-inside-an-archived-release-stops-being-declared-healthy-every-sweep}

単一のアーカイブとして配信されているリリースで、修復では再追加をこれ以上絞り込めない場合、zurg はアーカイブ自体がまだ読めるかどうかを確認します。読めるなら、リリースを切り捨てる代わりに、壊れているマークを外します。

ただ、その処理はすべてのマークを外していました。アカウントが個別のリンクで直接指定しているファイルのマークも含めてです。検証済みのアーカイブリンクが示すのは、アーカイブが読めることだけです。そうしたファイルについては、何も証明しません。

そのため、アカウントがリンクの配信を止めていたファイルが、関係のない読み取り結果だけで正常に戻されていました。次のスイープでそのファイルの制限を解除すると、また壊れていることがわかります。リリースは再び切り捨てられ、その切り捨てを行ったパスは、最後にまたそのファイルを復元して終わっていました。

64ファイルで9件のリンクが配信停止になっていたリリースでは、これが1週間で111回起きました。そのうち2回は同じ40秒以内に起きていて、1回のパスで2回のマグネット追加が発生していました。

今回の修正で、取り消しは実際にアーカイブから配信されているファイル、つまり独自のリンクを持たないファイルだけに適用されるようになりました。アカウントが個別に指定しているファイルは、そのリンク自体が得た判定を保ったまま修復に回されます。動くリンクを新たに発行できるのは修復だけだからです。

## 一部しか届かなかったダウンロードが、キューに永久に残らなくなりました {#downloads-that-only-partly-arrive-no-longer-sit-in-the-queue-for-ever}

一部のファイルが読めなかったとき、zurg はそのリリースのダウンロードを、もう分かるはずのないファイルサイズを待つためにキューに残していました。問題を見つけるチェックは、そのサイズが届いたあとにしか動かなかったのです。Sonarr と Radarr では、こうしたダウンロードが 0% で残り時間なしと表示され、zurg が動いている間はずっとそのままでした。リリースがブロックリストに入ることも、別のリリースを検索されることもありませんでした。

zurg は、30分待っているリリースについてニュースサーバーに問い合わせるようになりました。記事が消えている場合や、サーバーに問い合わせすらできなかった場合は、ダウンロードが失敗したと報告します。サイズがまだ届いている途中のリリースには影響がなく、届くまでこれまで通り保留されます。

## あるアカウントで修復を諦めたリリースは、別のアカウントから修復できます {#a-release-one-account-gave-up-on-can-be-repaired-from-another}

デブリッド(debrid)サービスはそれぞれ独立したキャッシュを持っています。Real-Debrid で削除されたリリースや、ファイル名だけで拒否されたリリースでも、同じハッシュで AllDebrid にキャッシュされていることがあります。これまで zurg はそれを利用できませんでした。修復(repair)は常にリリースを元のアカウントに再追加していたため、そのアカウントが諦めてしまうと試せる手段が残らず、別の支払い済みアカウントがそのリリースを持っていても、ライブラリ内で壊れたままになっていました。

今では、そのリリースを持つすべてのアカウントが諦めたリリースは、ほかのアカウントに提示されるようになりました。最初にそれを既に持っているアカウントがリリースを受け取り、そのリリースには両方のアカウントが紐づいた状態で戻ってきます。2つのアカウントが持つリリースと同じように、アカウント間で自動的にフェイルオーバーします。

設定は不要です。2つ目のアカウントを設定していて修復が有効になっていれば、他に試せる手段がなくなったときに、修復がこの処理を自動で行います。

アカウントに渡されるのは、そのアカウントがすでに持っているコンテンツだけです。リリースを取得する必要がある場合は、追加を取り消してすぐに削除します。そのため何もダウンロードされず、転送枠も消費されません。「no」と答えたアカウントには、1日後、2日後、4日後と間隔を延ばして、約2週間まで再確認します。完全に消えたリリースでも、問い合わせを続けてコストがかかることはありません。

## キャッシュ済みのみの取得は、キャッシュ検索ではなくお使いのアカウントの状態で判断されます {#cached-only-grabs-are-judged-by-your-account-not-by-a-cache-lookup}

cached-only モードでは、以前 zurg が TorBox、Premiumize、Offcloud にリリースがキャッシュにあるかを尋ね、その答えをそのまま Sonarr に返していました。ただ、これらのエンドポイントが答えているのは、実際に聞かれている内容とは別の質問です。わかるのは、そのコンテンツがサービスのキャッシュにあるということだけで、あなたのアカウントに最終的にそれが入るとは限りません。しかも、その後でトレントを確認する処理もありませんでした。キャッシュがあるという答えが実際のダウンロードにつながると、約束された即時取得として Sonarr に届いてしまいます。cached-only があえて防いでいるのは、まさにこの事態です。

今は、どのアカウントも同じ方法で判断します。トレントを追加して、インスタンスを監視し、制限時間内に完了したものだけをキャッシュ済みとして扱います。それ以外は削除して、取得は拒否します。これにより、Sonarr は一覧の次のリリースに進みます。ただし、この3つのサービスでキャッシュ照会がはずれた場合は、追加枠を1つ使うようになりました。以前はキャッシュ照会では何も消費しませんでした。

## AllDebrid のバックアップキーがライブラリへの応答に使われなくなりました {#an-alldebrid-backup-key-no-longer-answers-for-your-library}

`download_tokens` は、AllDebrid アカウントに紐づく別の AllDebrid アカウントのことで、ダウンロード枠の確保用に保持されています。アカウント自身のキーが上限に達してローテーションから外れると、それ以外のすべての呼び出しもバックアップキーで行われていました。マグネット一覧、リリースのファイル一覧、追加、削除、再起動、`__downloads__` の背後にある保存済みリンク、変更検出のプローブがこれに含まれます。そのため、ライブラリ更新でバックアップアカウントのマグネットを一覧取得して自分のものとして取り込んでしまったり、そのマグネットを一度も持っていないアカウントに削除を送ってしまい、すでに削除済みだという結果が返ってきたりしていました。さらに、すべてのキーが上限に達すると、単にバイト数の制限にすぎないことを理由にカタログ全体が見えなくなっていました。現在ローテーションが行われるのは、リンクのアンロックのときだけです。アカウントに関わるものはすべて、ご自身のアカウントに対して実行されます。

## 正常なリリースが壊れたリストに出入りを繰り返さなくなりました {#a-healthy-release-stops-flapping-in-and-out-of-the-broken-list}

リリースのアカウントが死んだリンクを1つだけ返し続けると、その中のファイルがすべて問題なく再生できていても、ダッシュボードの Broken リストに毎時の半分ほど載ってしまうことがありました。Repair は、`hoster_unavailable` を3サイクル連続で返したリンクを外し、代わりにリリースを再アドレスできるようにします。また、次のリスト取得で同じリンクが戻ってこないように、その除外を記憶しておきます。

ところが、その記憶が誤ったきっかけで消えていました。正常に終わった repair であれば、どれも記憶を消していたのです。新しいものは何も作らず、エントリがすでに持っているアドレスがまだ読めることを確かめるだけの repair でも消えていました。「そのアーカイブがまだ読める」というのは極端な例です。リリースを配信している1つのリンクが動くことは証明しますが、アカウントが拒否したリンクについては何も言えません。そのため、除外したことが忘れられ、次の更新で同じ死んだリンクが採用されました。repair はそれに再びアドレスを割り当てられず、エントリをまた除外してしまいます。この流れが30分ごとに繰り返され、終わることがありませんでした。

ライブのライブラリで3日間計測したところ、1つのリリースが129回も再除外され、1週間でライブラリ全体では556回の除外が発生していました。さらに、サイクルごとに magnet の追加が2〜4回ずつ発生していました。

現在は、リリースを実際に再アドレスできた repair だけが除外の記憶を消すようになっています。一方、手動の repair は今でも除外をすべて忘れます。そのため、オペレーターは手作業でリンクを戻すことができます。

## 一つのアーカイブで提供されるリリースは、スイープのたびに壊れたものとして扱われなくなりました {#a-release-served-as-one-archive-is-no-longer-marked-broken-every-sweep}

一部のリリースは、単一のアーカイブとして配信されます。`.rar` にはアカウントの唯一のリンクが入っていて、中の各エピソードは個別のファイルとして一覧に出ますが、どれにもリンクはありません。修復スイープは、それでも中のファイルについてアカウントに問い合わせていました。問い合わせに使えるものがなかったので、どのアカウントにも聞かれず、何も測定されませんでした。それなのに答えは「file is broken」と返ってきて、スイープはそれを各ファイルに書き込み、そのままリリース全体を壊れた扱いにしていました。

その後、magnet の追加が 2 回発生しました。壊れたファイルだけをアカウントに問い合わせると、返ってきたのは元々あった単一のアーカイブのリンクでした。するとアーカイブのフォールバックがそのリンクを検証し、たった今壊れた扱いにされたばかりのファイルをすべて復元してしまいました。稼働中のライブラリで測定したところ、4.9 GB のアーカイブ 1 つに含まれる 44 エピソードが、このサイクルを 30 分ごとに繰り返していました。

今後は、どのアカウントもリンクを持っていないファイルはそのまま放置されます。アーカイブ自身のファイルは、これまでと同じ基準で判定されます。リリースを配信しているリンクが解決できなくなった場合は、そのファイルが壊れた扱いになり、リリースも一緒に壊れた扱いになります。

## トラフィックは、許容量がリセットされると自分のアカウントのトークンに戻ります {#traffic-goes-back-to-your-own-accounts-token-once-its-allowance-resets}

1日の割り当てを使い切った Real-Debrid アカウントは、トラフィックを `download_tokens` の中で残りがある最初のエントリに移します。ウォッチャーは、そのアカウント自身のトークンがまた配信できる状態になるとすぐにローテーションへ戻します。

しかし、トークンが戻ってもトラフィックは戻りませんでした。ローテーションは前回止まった位置から再開し、そのトークンが上限に達しているかどうかだけを確認していました。そのため、メインアカウントのカウンターがすでに 0 になっていても、バックアップアカウントが1日中すべてのバイトを受け持ち続けていました。

`download_tokens` の順序は、今では順番にたどる位置ではなく、優先順位になりました。先頭に近く、配信できる状態にあるトークンが配信を担当します。これにより、メインアカウントはカウンターがリセットされてから1分以内にトラフィックを取り戻します。

## 間違ったアドレスを指している rclone リモートは、そのことを表示するようになりました {#an-rclone-remote-pointed-at-the-wrong-address-now-says-so}

rclone の WebDAV リモートの URL 末尾に `/dav/` が抜けていると、すべての一覧取得が "couldn't list files: 405 Method Not Allowed" で失敗していました。しかも、どこにもその理由は出ていませんでした。ブラウザでダッシュボードは普通に表示されるので zurg は正常に見えますし、zurg 自身のログも、数秒ごとに失敗し続けているクライアントについて何も書いていませんでした。今の zurg は、`/dav/` の外に届いた WebDAV リクエストに対して、使うべきアドレスを返すようになりました。rclone はそれを自分のエラーの一部として表示します。さらに、そのリクエストを送ったクライアントの名前を含む警告を 1 行ログに書きます。

## Windows へのインストールで、メディアサーバーのスキャン送信が再び行われるようになりました {#windows-installs-now-send-media-server-scans-again}

`Z:` という `mount_path` は、Windows で `zurg setup` が書き込む値です。ただ、これまではスキャンのパスがドライブのルートではなく、そのドライブのカレントディレクトリからの相対パスとして作られていました。そのため、どのパスも所属するライブラリセクションに一致せず、スキャンリクエストは一度も送信されていませんでした。その後に出ていた警告は、すでに正しい `mount_path` を確認するよう求めるものでした。既存の設定ファイルを編集する必要はありません。

## 一括スキャンは、トレントごとではなく Plex ライブラリを一度だけ読み取ります {#bulk-scan-reads-the-plex-library-once-instead-of-once-per-torrent}

ダッシュボードの一括スキャン後のマッチングでは、バッチ内のトレントごとにPlexライブラリ全体を読み直していました。そのため大きなライブラリをスキャンすると、たいてい別の処理で忙しいPlexサーバーに、同じ内容のライブラリ全体取得が何百回も飛んでいた、という状態でした。

## Windows のライブラリパスは大文字小文字を区別せずに一致します {#windows-library-paths-match-regardless-of-case}

Plex、Jellyfin、Emby のライブラリが `Z:\Movies` として記録されていても、zurg がディレクトリ名から組み立てた `Z:\movies` を見逃さなくなりました。NTFS は大文字と小文字を区別しないため、この2つは同じディレクトリを指します。以前は完全一致で比較していたため、スキャンが失敗し、mount_path が間違っていると報告されていました。

## 配信が止まったファイルがあっても、Plex のスキャンが止まることはなくなりました {#a-file-that-stops-serving-no-longer-stalls-a-plex-scan}

壊れたファイルはディレクトリの一覧に載ったままで、読み込みには `503 File temporarily unavailable (being repaired)` を返していました。これは何かが判定を解除するまで続き、修復中であれば修復が終わるまで続きます。Plex は 503 で処理を止めるため、そうしたファイルが一つあるだけでライブラリのスキャンが止まります。壊れたファイルを多く含むライブラリでは、スキャンが最後まで終わることがありません。一方 Jellyfin はそうしたファイルを飛ばして進むので、問題なく見えます。

ここには別々に判断すべき二つの事柄があり、今はそれぞれ別の答えになっています。エントリは、戻ってくる可能性がある限り一覧に残します。フォルダからエントリが消えると、メディアスキャナーはそれを削除と受け取り、アイテムをゴミ箱に入れてしまうからです。この点は変わりません。変わるのは読み込みの応答です。ファイルの配信が止まってから一分間は 503 を返し、その後は 404 を返します。一分という長さには理由があります。rclone は 503 をリトライし、およそその時点で読み込みを諦めます。そのため短い不調なら吸収されて読み込みは成功します。一分を過ぎると、503 はどのみち読み込みを失敗させ、その後ろに続くすべてのスキャンの足を引っ張っていたからです。

実際の Plex で検証しました。15本の映画があるライブラリで、10ファイルは読み込みを拒否し、すべてのファイルは一覧に載ったままにしました。404 を返した場合は 5 秒でスキャンが完了しました。一方、解除されなかった 503 の場合は、10分で打ち切ったとき 15本のうち 3本しか見つけられませんでした。

## 新しい SABnzbd ジョブが、ライブラリ全体のサイズチェックの完了を待たなくなりました {#new-sabnzbd-jobs-no-longer-wait-behind-a-full-librarys-size-checks}

zurg が大きな Usenet ライブラリで再起動すると、すべてのリリースに対してサイズチェックをキューに入れてしまい、1 時間のリトライ待ち中だった失敗チェックの情報を忘れていました。そのため、新しく取得したリリースが、Sonarr や Radarr が正確なファイルサイズを待っている間に、何千ものバックグラウンドチェックの後ろで止まってしまうことがありました。

今は、サイズチェックに固定のワーカーキューを使っています。SABnzbd のジョブが待機中のリリースは先頭に移動します。完了したチェックとリトライ待ちの情報も、再起動後に `data/nzb-sizes/` へ残るようになりました。キューに作業が溜まっている間、zurg は待機中、クライアント優先、実行中の件数を 1 分ごとに報告します。

## クライアントが消去しないダウンロードがあっても、新しいダウンロードのインポートを妨げなくなりました {#downloads-a-client-never-clears-no-longer-stop-new-ones-from-being-imported}

zurgは、Sonarr、Radarrなどのダウンロードクライアントに完了したダウンロードのページを表示し、クライアントが削除するまで各項目をそのページに残します。クライアントが削除するのは、インポートできたものか失敗したものだけです。そのため、タイトルを照合できないなど、クライアントがインポートをブロックしたダウンロードは、ページに残ったままになっていました。そのようなものでページがいっぱいになると、新たに完了したダウンロードはキューで待つだけで、一度もインポートされませんでした。

ページに10分間残ったまま削除されなかったダウンロードは、待機中のものに場所を譲るようになりました。SABnzbdが新しい行が追加されると古い行を履歴ページから落としていくのと同じ仕組みです。ページに空きがあるうちは何も変わりません。また、リリースを再度grabすると、そのリリースは独自の場所を得ます。

## ID で指定したダウンロードは、完了するとすぐに見つかるようになりました {#a-download-looked-up-by-its-id-is-found-as-soon-as-it-finishes}

ダウンロードを1件ずつ id で zurg に問い合わせるツール（LazyLibrarian など）は、ダウンロードが完了するとすぐに完了したと伝えられるようになりました。完了したダウンロードの一覧ページが Sonarr や Radarr の読み取るぶんでいっぱいの場合でも同じです。以前は、そのページに空きができるまで、こうしたダウンロードが Sonarr や Radarr には未完了に見えることがありました。

## シーズン修正がダッシュボードにページとして表示されるようになりました {#season-fix-has-a-page-in-the-dashboard}

ライブラリ全体で、ファンサブの連番エピソードを Plex が読めるファイル名にリネームする機能は、リリース以来 `/torrents/season-fix/plan` と `/torrents/season-fix/apply` という 2 つの HTTP エンドポイントとしてしか使えませんでした。ダッシュボードには操作できる場所がなく、ネーミングのリファレンスに説明が 1 段落あるだけでした。見つけられない機能は存在しないのと同じです。この機能は今月も要望チャンネルで求められていましたが、すでに実装されていることを知らない人たちからの要望でした。

`/season-fix/` では、この処理が何をするのかを説明し、置き換え対象のファンサブ名に対して生成される正規の形を表示します。また、シーズンの構造がどこから来るのかも説明します。それは Plex 自身のメタデータプロバイダーからで、ローカルのライブラリからではありません。シーズンが崩れてしまったライブラリこそが修正の対象だからです。さらに、マッパーが触らないものとその理由も一覧にしています。スキャンの結果がほぼ空で返ってきても、それは不具合ではなく、慎重な判断が正しく働いている結果です。

スキャンは引き続きボタンの裏に置いています。計画の作成では、すべてのトレントを走査し、一致した番組ごとに Plex へ問い合わせるため、ページを開いただけでは始まりません。結果は番組ごとにまとめられ、各リネームは変更前から変更後まで表示されます。スキップされたファイルは開閉式の項目の中にあります。誤った番組に一致した可能性があるとフラグが付いた項目は、チェックが外れた状態で表示され、確認画面でもその旨が再度示されます。そのため、すべてを一度に適用しても、誤った番組に一致したリリースが黙ってリネームされることはありません。

## 複数のボリュームに分割された圧縮リリースを再生できます {#play-a-compressed-release-that-is-split-across-several-volumes}

リリースが、丸ごと保存されるのではなく圧縮されてパックされていた場合、最初のボリュームの終わりで止まっていました。内部のすべてのファイルは正しい名前とサイズで表示されるのに、再生できず、ログには bad header CRC が残っていました。zurg はこれで各ボリュームの継ぎ目をまたいで解凍処理を引き継ぐようになったので、こうしたリリースも最初から最後まで再生できます。

## アカウントに失敗したトレントがたくさんあっても、すばやく起動します {#start-up-quickly-when-your-account-holds-failed-torrents}

ライブラリを更新するたびに、debrid サービスで failed とマークされた torrent を 1 件ずつ再チェックしていました。サービスが 1 秒あたりに許可するリクエストは数件だけなので、数百件を抱えるアカウントでは、それだけで 1 分以上かかっていました。更新のたびに、その時間だけライブラリが読めない状態が続き、起動のたびにも同じことが起きていました。Plex がまだ存在しないフォルダーをスキャンして、その中身をすべて利用不可としてマークしてしまうには、この時間で十分です。今では zurg は、failed になった torrent についてすでに知っている情報をディスクから読み込みます。サービスに問い合わせ直すのは、サービスがその torrent はもう failed ではないと伝えてきたときだけです。

## AllDebrid で再試行しないと判断済みのマグネットに対して、再度問い合わせなくなりました {#stop-re-asking-alldebrid-about-magnets-it-has-already-refused-to-retry}

マグネットリンクの取得に失敗すると、zurg は AllDebrid にもう一度取得を依頼します。AllDebrid は一部のリクエストを拒否しますが、その拒否はトレントごとの 2 回の試行回数にカウントされていませんでした。そのため zurg の稼働中は、ライブラリの更新のたびに同じマグネットについて問い合わせが繰り返されていました。今では、その応答を 1 時間覚えておくようになりました。また、アカウントが返したステータスも覚えるので、マグネットの状態が変われば改めて問い合わせが行われます。試行回数もディスクに保存されるようになりました。以前は再起動のたびに忘れられて、同じ回数をまた最初から使い切っていました。

## アカウントに2つ持っているリリースでも、リンクが安定したままになります {#keep-the-link-steady-for-a-release-your-account-holds-twice}

A release added twice to one account has two of everything, including two download links per file. zurg kept one link per account, so each copy replaced the other's on every refresh and the entry never settled. Nothing was unplayable, but the log filled with re-pointing and the library was rewritten to disk every few seconds. zurg now leaves the link alone when it can only see part of what the account holds.

Japanese translation:

同じリリースを1つのアカウントに2回追加すると、すべてが2つずつになります。ファイルごとのダウンロードリンクも2つです。zurg はアカウントごとに1つのリンクしか保持していなかったため、更新のたびにコピーどうしがお互いのリンクを置き換えてしまい、エントリーが落ち着きませんでした。再生できなくなるものはありませんでしたが、ログはリンクの張り直しで埋まり、ライブラリは数秒ごとにディスクへ書き直されていました。zurg は、アカウントが保持している内容の一部しか見えないときはリンクをそのままにするようになりました。

## アカウントに失敗したトレントがある場合でも、TorBox の変更チェックが速くなりました {#faster-change-checks-on-torbox-when-the-account-holds-failed-torrents}

TorBox にはアカウントが変わったかどうかを問い合わせる方法がないので、zurg は新しいトレントの小さなページを読み込み、まだ完了していないものを監視します。TorBox で失敗したトレントは完了することがないため、古い失敗が 1 件あるだけで、アカウントを使い続ける限りすべてのチェックがずっと大きなページを読むことになっていました。失敗したトレントは、もう動くはずのない状態を監視しなくなりました。

## *arr がインポートできなかったリリースは、その試行によって削除されなくなりました {#a-release-your-arr-could-not-import-is-no-longer-deleted-by-the-attempt}

zurg が、ニュースサーバーから読めないという理由で Usenet のステージングフォルダからリリースを移動させることを拒否すると、Sonarr と Radarr はそこで諦めるわけではありません。.NET は移動に失敗すると、ファイルをコピーしてから元のファイルを削除します。以前の zurg はこの削除をそのまま実行していたため、リリースが消え、インポート先には空のファイルだけが残っていました。移動が拒否された後に続く削除も、同じ理由で拒否されるようになりました。これでリリースはそのまま残ります。

## Usenet の読み取りで、遅いバッチと止まってしまったバッチを区別できるようになりました {#usenet-reads-tell-a-slow-batch-from-a-stalled-one}

zurgは、待ち時間が長くなった記事について2つ目のUsenetコネクションに問い合わせ、先に届いた応答を採用します。待ち時間が長すぎるかどうかの判断は時計で行われていたため、高速なアカウントで大きな記事を普通に取得している最中に、最初の記事がまだ届いている段階で、同じ記事が2回要求されてしまっていました。

この判断は、今ではネットワーク上を流れるデータそのものから行われます。Usenetコネクションは、データが届くたびにすでにタイムアウトを更新しており、リーダーもその証拠を見ています。大きな記事の途中まで届いているバッチは、その記事にどれだけ時間がかかっても、そのまま放置されます。データの流れが止まったバッチだけが、別の場所に要求されます。

あるコネクションがまとめて記事のバッチを受け取ったのに、そのどれにも応答しない場合、zurgは欠けている記事を1つずつ探すのではなく、そのバッチの残り全体を一度に別のコネクションへ要求します。応答のないコネクションは切断されないので、後から届いた記事もちゃんと有効です。届かなかった記事だけが再要求され、その回数はバッチごとに最大1回です。再生位置に最も近い記事が最初に要求されます。また、2つ目の要求用に1つ分を常に残しておくので、次に読み取りが止まったときにも、自分の記事を要求できます。

読み取りは、2つ目の要求を出すまでに待った時間を、通常の速度として扱わなくなりました。学習されるのは、zurgが待つことを許容した時間だけで、それ以上ではありません。どの記事も正当に1秒以上かかるアカウントでは、しきい値はそのアカウントが実際に届けられる速度の近くに落ち着くようになりました。以前のように最短の設定まで下がって、ほとんどの記事で2回要求してしまうことはなくなります。

## Usenet の先読みは、記事やボリュームをまたいでも窓を満たし続けます {#usenet-read-ahead-keeps-its-window-full-across-articles-and-volumes}

私たちが提供する文書は日本語で書かれている必要があります。

Read-ahead（先読み）は、前の記事の到着が遅れると新しいバイトの要求を止めていたため、遅い記事が1本あるだけで、それまで溜めていた先読みのウィンドウが空になっていました。zurgは現在、それでも要求済みバイトの上限付きウィンドウを常に送信中に保つようにしています。また、1つのバッチの記事は、保存された2つのRARボリュームの継ぎ目で終わるのではなく、その継ぎ目をまたぐこともできるようになりました。

ウィンドウが使うのは、設定したRAMキャッシュの最大4分の1までで、128 MiBを超えることはありません。そのため、キャッシュを小さくすると、ウィンドウも小さくなります。各リクエストは、それぞれ独自のキャンセル処理と、アカウントごとの接続数・キャッシュ上限を引き続き守ります。

## 古いプロセッサーでも、Usenet 再生の CPU 負荷が下がりました {#usenet-playback-costs-less-cpu-on-older-processors}

キャッシュの読み込みを速くしました。

読み込みキャッシュは、保存するすべてのレコードにチェックサムを付けています。SSE4.1 はあるが AVX はない Intel および AMD のプロセッサでは、SHA-256 がハードウェアの支援なしで動いてしまい、そのコストが再生中に目立っていました。zurg はこれらのプロセッサで、より速い 256 ビットのチェックサムを使うようになりました。

レコードにはバージョンが付くので、破損は今まで通り検出されます。既存のキャッシュも引き続き読めます。それ以外のプロセッサでは、従来どおり SHA-256 を使います。

## NZB 共有が、それを取得したアカウントを指さなくなりました {#nzb-shares-no-longer-point-back-to-the-account-that-grabbed-them}

一部のインデクサーは、すべてのダウンロードに、あなたのアカウントにたどれる情報を埋め込みます。その一部は、共有を行う人が保持していたフィールドに残っていました。あるインデクサーは、リリース名に新しいトークンを隠し、多くの場合パスワードにも入れます。さらに、ファイルごとに投稿者、日付、ニュースグループを変えます。別のインデクサーは、あるファイルの subject の先頭にアカウント番号を入れます。3つ目は、すべての投稿者にアカウントの目印を入れます。

`zurg nzb-share` は、投稿者と日付を取り除き、すべてのファイルに同じ固定のニュースグループを設定し、subject の目印を削除して、どこにあってもトークンを無視するようになりました。名前とタイトルが食い違う場合は、名前を優先します。同じリリースを取得した2人が、同じファイルを公開するようになります。

また、共有からLatin-1 エンコーディングで保存された NZB が除外されることがなくなりました。subject に含まれるバックスラッシュが二重になる問題も直っています。

クリーニングで何が取り除かれるかは、[`zurg nzb-share`](cli.md#zurg-nzb-share) に書いてあります。

## ローカルライブラリで、AllDebrid、Premiumize、Offcloud のハッシュが追加されるようになりました {#local-libraries-add-the-hash-on-alldebrid-premiumize-and-offcloud}

ローカルライブラリのマニフェストにポータブルなリンクがない場合、初回再生時にそのハッシュがアカウントに追加されます。TorBox から書き出したマニフェストは、必ずこの形式になります。AllDebrid のリンクが期限切れになっているマニフェストも同様です。AllDebrid、Premiumize、Offcloud では、こうした再生がすべて "provider did not report an active torrent allowance" というエラーで失敗していました。zurg は追加する前に、アカウントのトレントスロット上限を取得しようとしていました。しかし、この3つのプロバイダーはどれも上限を報告しません。そこで zurg は、repair と同じように、宣言されたスロット数にフォールバックするようになりました。どちらもない場合は、ハッシュを追加したうえで、アカウントが満杯なら proバイダー側に拒否させます。

## Offcloud のファイルで長さが表示されるようになりました {#offcloud-files-report-their-length}

Offcloud のファイルを解決したとき、長さ(サイズ)が設定されていませんでした。ローカルのライブラリはその長さをマニフェストと照合するため、Offcloud の再生はすべて "resolved file size does not match the portable manifest" というエラーで拒否されていました。通常の再生でも、長さが必要な range 処理が効かなくなっていました。zurg は今、Offcloud の一覧表示ですでに行っている方法で、配信サーバーに長さを問い合わせるようになりました。

## zurg が Android スマホと Google TV で動作します {#zurg-runs-on-android-phones-and-google-tv}

新しい Android アプリで、ライブラリをデバイス本体でホストします。スマートフォンやタブレットに加え、Android TV や Google TV にも対応しています。Android 8.0 以降が必要で、Usenet を使うには 64-bit の Android が必要です。アプリでプロバイダーのアカウントとデバイスプロファイルを設定すると、ライブラリが起動します。ライブラリはアプリ内か Android の Files で閲覧でき、好きな外部プレイヤーで再生できます。シークも自由にできます。すべての画面は TV のリモコンで操作できます。MediaInfo は追加ツールなしでデバイス上で動作します。ライブラリは、ローカルネットワーク上の他のデバイスとパスワード付きで共有することもできます。そのパスワードがプレイヤーに送られることはありません。

APK はスポンサー向けの nightly リリースにあります。このアプリに zurg 本体は含まれていません。GitHub にサインインすると、zurg エンジンを 2 つ目のパッケージとしてインストールします。アプリとエンジンは別々に更新されます。Updates には、公開されているエンジンのバージョンがすべて表示されます。そのため、デバイスで不具合のある nightly があっても、正常に動いていたバージョンに戻せます。最初の Android ビルドをインストールしていた方は、一度 Updates からエンジンをインストールしてください。プロバイダーとライブラリの設定はそのまま引き継がれます。

64-bit ARM デバイス向けのエンジンは、プロバイダーのアドレスを Android 標準のリゾルバーで検索するようになりました。最初のビルドのエンジンでは、どのプロバイダーにも接続できない場合がありました。

セットアップとプレイヤーの注意点は [Android](../guides/android.md) にあります。

## 新しい NZB が数秒以内にライブラリに表示されます {#a-new-nzb-shows-up-in-the-library-within-seconds}

以前は、NZB をウォッチディレクトリに入れると、次の定期的な変更チェックまで待つ必要がありました。難読化されたリリースの場合は、本当のファイル名を読むためにさらに 1 回分の間隔を待ちます。デフォルトの間隔だと合計 20〜30 秒かかり、その間ずっと Sonarr や Radarr の取得は Queued のままでした。

zurg は今、ウォッチディレクトリを 1 秒ごとに自分でチェックするようになりました。ファイルシステムのイベントには頼らないので、NAS 上でもコンテナの中でも同じように動きます。リリースは、ファイル名を読み終えた瞬間に一覧へ表示されます。20 個のリリースからなるシーズンパックでも、一覧表示は 1 回で済みます。定期的なチェックは残しており、既に持っている名前で NZB が差し替えられた場合の最終的な保険として働きます。

## Usenet のストリームで速度が安定したままになります {#usenet-streams-hold-their-speed}

RAR セットの中のファイルは、ニュースアカウントから 1 ボリュームずつ届きます。zurg は、次のボリュームを前もって開いておくようにしました。こうすると、切り替わりのときに冷えた状態から始まりません。以前は最初の 4 MB だけを温めていたので、小さなボリュームに分かれたリリースでは、再生が 1、2 秒ごとに境目にぶつかり、そのたびに止まっていました。あるリリースでは 14～16 MB/s しか出ず、同じアカウントの普通のファイルは 86～99 MB/s で流れていました。

今は、ストリームが次のボリュームから 32 MiB 以内に近づくと、そのボリュームを先読みウィンドウ 1 つ分の深さまで温めます。ストリームが今まさに切り替わったばかりのボリュームは、そこで得た先読み分をそのまま保ちます。近くに何もないボリュームは、先頭だけを温めたままです。こうすることで、ライブラリのスキャンが読まれないデータまで取りに行くことを防いでいます。

通常の読み込みでも、約 20 回に 1 回は 1 つの遅い記事で止まり、他の接続がその後ろで待たされていました。今は、待ち時間が長くなったら別の接続にもその記事を要求し、先に届いた方を使います。これはプレイヤーが待っている読み込みに限って行います。先読みと修復が同じ記事を二重に取りにいくことはありません。また、アカウントごとに追加の要求は 1 分あたり 20 回までに制限しています。

プレイヤーが待っている読み込みを、さらに多くの場面で優先するようになりました。先読みは、アカウントの最後の空き接続を取らなくなりました。起動時のサイズ確認の処理も、空き接続を 1 つ残します。読み込みは、新たに接続を開く代わりに、アカウントがすでに持っている接続を使います。また、新しい接続を開くお金を払うより、すでに開いている途中の接続を待つようにしました。プレイヤーが止まっている記事は、後のバイトのためにキューに並んでいる取得を追い越せます。ある計測では、読み込みの最初のバイトが 354 ms ではなく 177 ms で届きました。ウォームアップ、keep-alive、読み込みは、今では同じ接続上限を共有します。zurg がアカウントの許容数を超えて接続を開くことはありません。

デコード済みの記事をディスクキャッシュに保存しても、その記事を取得した読み込みを待たせることはなくなりました。以前は、他のすべての読み込みが必要とするロックの中で書き込みを行っていました。今は、バイトがプレイヤーに届いた後に書き込みます。キャッシュが追いつけないほどの急増があった場合は、再生を遅らせる代わりに余分なレコードを飛ばします。既存のキャッシュはそのまま引き継がれます。

## Sonarr と Radarr が、完了しないグラブを待ち続けなくなりました {#sonarr-and-radarr-stop-waiting-on-grabs-that-can-never-finish}

以前のSABnzbd用エンドポイントでは、一部のジョブがキューに入ったまま永久に残ることがありました。クライアントはそれらをブロックリストに入れず、別のリリースを取得することもありませんでした。下記の各ケースは、現在は理由を示すメッセージ付きで Failed と報告されます。Failed になると、Sonarr と Radarr はそのリリースをブロックリストに入れて、再度検索します。

リリースは取得後にライブラリから消えることがあります。ダッシュボードから削除されたり、監視ディレクトリから取り除かれたり、すべてのアカウントで失われたりする場合です。以前のジョブは 0% のまま、それを動かす仕組みがありませんでした。現在は、リリースが15分間見当たらないままだとジョブが失敗します。再起動直後の最初の15分間は、ライブラリの読み込み中なので何も失敗しません。

取得が、以前のインポートですでに空になったリリースに当たることがあります。アップグレードでインポート済みのファイルが削除された後、検索が同じリリースをもう一度選んだ場合に起こります。以前の zurg は Completed を返し、中身の空のフォルダーをクライアントに指していました。空になったリリースへの後続の取得は、現在すぐに失敗します。15分間空のままのフォルダーも、そのジョブを失敗させます。これには、手動での移動や、別のジョブ配下のインポートによって空になったフォルダーも含まれます。インポートを行っている取得は、完了処理の間も Completed と表示されます。

記事の確認が終わらないリリースもあります。zurg は、取得を完了と報告する前に、リリースの記事がまだ残っているかをニュースサーバーに問い合わせます。確認が完了できなかった場合、以前は毎分無限に再試行されていました。現在は、少なくとも3時間にわたって連続30回失敗すると失敗します。1時間ダウンしているニュースアカウントのせいで、待機中のすべてのジョブがブロックリストに入ることはありません。確認が最終的に応答すると、カウントはリセットされます。

リリースによっては、アーカイブ全体を含んでいないものがあります。ファイルの先頭を含むボリュームがない場合があります。途中のボリュームが欠けている場合もあります。最初のボリュームではない場所から始まる場合もあります。以前は、Sonarr がインポートできないフォルダーを指してしまい、永久に再試行していました。現在は取得が失敗します。この判定は、判定時に確認した正確なボリュームに結び付けられています。PAR2 による修復、再取得、欠けているボリュームを持つ別のアカウントがあれば、そのリリースは再度確認されます。

## 1日の許容量を使い切ったら、バックアップのダウンロードトークンに切り替わります {#backup-download-tokens-take-over-when-the-daily-allowance-runs-out}

Real-Debrid は、トークンが1日の割り当て分を使い切ると、ダウンロードを拒否するようになります。zurg は本来、そのトークンを退役させて `download_tokens` の次のエントリに移るはずでした。ところが、プロキシ経由のストリームが新しいHTTPクライアントに移行したあと、再生中にそれが動かなくなりました。拒否の応答は通常のレスポンスとして返ってきて、トークンが使い切られたという印は付きませんでした。そのため、予備のトークンはすべて未使用のままで、制限のあるトークンばかりが何度も消費されていました。

拒否は、zurg が遭遇するあらゆる箇所で認識されるようになりました。再生時だけでなく、リフレッシュループや修復処理も含まれます。どちらも再生中かどうかに関係なくリンクを確認するためです。Real-Debrid の通常のヘッダーが付いていない拒否応答でも、そのトークンは退役扱いになります。

退役したトークンは、割り当てが戻ったらすぐ復帰できるように1分ごとにテストされます。ただ、このテストは退役したトークン自身でキャッシュされたリンクを使っていました。トークンが機能しなくなると、そのキャッシュを補充するものがないため、テストは何も見つけられず、トークンは夜間リセットか再起動まで除外されたままでした。今後は、まだ動いているトークンのどれかからリンクを借りてテストするようになります。

夜間リセットも1日遅れていました。Real-Debrid は CET で深夜0時を少し過ぎた数分後に割り当てをリセットしますが、zurg は起動後の最初の深夜0時をスキップし、2回目にリセットしていました。そのため、割り当てを使い切ったアカウントは、バックアップトークンでさらに1日余計にサービスを続けていました。また、zurg はその深夜0時をホストマシンの日付から計算していたため、ヨーロッパより西のタイムゾーンでは、リセットが zurg の起動時刻に依存していました。すべてのリセットは CET の日付を基準にスケジュールされるようになりました。

## マグネットのグラブでリリース名が debrid アカウントに保持されるようになりました {#a-magnet-grab-keeps-its-release-name-on-the-debrid-account}

Sonarr と Radarr は、qBittorrent のエンドポイントにインデクサーのマグネットリンク全体を渡します。以前の zurg は、追加する前にそれを info hash だけに切り詰めていました。表示名とトラッカーは、アカウントに一度も届いていませんでした。マグネットリンクだけを提供するインデクサーでは、表示名だけがリリース名が記録されている場所です。するとキャッシュされていないトレントは、40文字のハッシュ名のままアカウントの一覧に並んでいました。誰もシードしていないトレントにとっては、それが唯一の名前になってしまいます。

マグネットリンクは、クライアントが送ってきたままの形でアカウントに届くようになりました。Repair、Plex のウォッチリスト、ポータブルライブラリからの追加では、渡せる名前がないため、今も裸のハッシュだけを追加します。

## .strm のダンプには、プレーヤーで開けるファイルだけが含まれます {#the-strm-dump-holds-only-files-a-player-can-open}

`save_strm_files`は以前、リリースで選択された全ファイルごとに.strmを書き出していました。字幕、ポスター、NFO、PAR2ボリュームもそれぞれライブラリのエントリになり、開いても何も再生されませんでした。TorBoxとAllDebridは、すべてのファイルを選択済みとしてマークします。修復用ファイルが動画と並んでいるUsenet投稿も同様です。現在は、認識された動画と音声、そして`addl_playable_extensions`に指定されたものだけに.strmが作られます。RARセット内の動画は引き続き書き出されますが、その周りのボリュームは書き出されません。以前のビルドで書き出されたエントリは、次回そのリリースを走査したときに削除されます。

いくつかの書き出し経路では、.strmファイルが存在する前にメディアサーバーへスキャンを指示していました。Plex、Jellyfin、Embyは空のフォルダーを見て、何もインデックスしないことがありました。リリースが変わるまで、再度確認するよう指示されることもありませんでした。現在はすべての経路で、先にファイルを書き出すようになりました。

## zurg フォルダーを移動しても、マウントキャッシュが孤立しなくなりました {#moving-the-zurg-folder-no-longer-strands-the-mount-cache}

rclone マウントは、読み込んだ内容を `data/rclone-cache` に保存します。rclone はそのキャッシュの名前を、自身の設定から決めます。その設定には、zurg の `data/local` フォルダーのフルパスが含まれています。zurg フォルダーを移動したり `union_writable` を変更したりすると、キャッシュの名前が変わっていました。古いツリーはディスク上に残りますが、サイズ上限の計算対象にならず、掃除もされませんでした。何度か移動するだけで、テラバイト単位のデータが取り残される場合もありました。

マウントの起動時に、zurg は rclone に「今使われているキャッシュツリーはどれか」を尋ねるようになり、それ以外のツリーを削除します。解放した内容はログに記録されます。`rclone_extra_args` で独自の `--cache-dir` を指定している場合は、この掃除をスキップします。古いツリーを残したい場合は、`rclone_cache_reclaim: false` を設定してください。

使用中のキャッシュは、多くの人が想像するより大きくなります。デフォルトでは 256G まで増え、そのサイズのまま維持されます。メディアサーバーの夜間スキャンはすべてのファイルに触れるため、72 時間の経過期限では、ほとんど何も削除されません。サイズ上限を基準に計画してください。上限の下げ方は [設定リファレンス](config.md#disk-the-mount-uses) に書いてあります。

## ポスターと .nfo ファイルが `__magic__` に入り続ける問題を修正しました {#posters-and-nfo-files-keep-landing-in-__magic__}

zurg のマウント経由で書き込むクライアントは、新しいファイルを `data/local` に置きます。このフォルダは `__magic__` がサイドカーを置いている場所です。zurg は、そこにあるすべてのファイルを `sidecar_budget_mb` に数えていました。\*arr がマウント経由で書き込んだ動画が数本あるだけで、予算をすべて使い切ってしまうことがありました。その後の .nfo やポスターはすべて、ツリーがいっぱいであるかのように拒否されていました。予算を増やしても効果はありませんでした。

`sidecar_max_mb` より大きいファイルは、zurg のサイドカー経路を通ってきたはずがありません。そうしたファイルは、もう予算に数えられなくなりました。ただし、ディスク容量は依然として使うため、zurg は起動時に一度だけそれらを一覧で表示します。

すでに存在しない `__magic__` のパスを削除しても、今後は成功するようになりました。マウントから共有サイドカーを両側から削除できるようになり、インポートのクリーンアップが壊れることもなくなりました。

## 最初のリリースが古くなっていた場合、Stremio の再生で次のリリースを試すようになりました {#a-stremio-play-tries-the-next-release-when-the-first-has-aged-off}

Stremioでクリックすると、以前は1つのリリースだけが再生対象になっていました。そのリリースに再生可能なものが入っていないと、再生は404で失敗していました。よくある原因は、ニュースサーバーから古い投稿が消えてしまうことです。ストリーム一覧には、ほかにも十数個のリリースが表示されていたかもしれません。

再生が拒否された場合、同じランク付けされたリストから最大2つまで別の行を試すようになりました。試すのは選んだ行の次からです。そのため、フォールバックは同じ解像度でより小さいリリース、または一つ下のティアのリリースになります。飛ばされた大きいリリースが選ばれることは決してありません。まだ取得中のリリースには、これまで通り503が返ります。もう一度再生を押せば、そのリリースが拾われます。試行ごとにインデクサーへのgrabが1回使われ、そのリリースはライブラリに残ります。この変更の前に作られた再生リンクは、これまで通りに動作します。

## Stremio のリストには、すべての解像度とさまざまなサイズが表示されます {#stremio-lists-show-every-resolution-and-a-spread-of-sizes}

ストリーム一覧の上限は、以前は一覧全体で数えられていました。4K の結果が先に並ぶため、人気のあるタイトルでは 4K だけで上限を超えてしまいます。その結果、一覧が 20〜40 GB のremuxで埋まり、検索で見つかった 1080p と 720p のリリースがすべて隠れることがありました。`stremio.max_results` は解像度ごとに数えるようになり、デフォルトは 5 になりました。手動で設定した値はそのまま使われ、今後は解像度ごとに適用されます。

解像度の中では、以前は最も大きいリリースだけが残っていました。そのため、スマホやノートPCで再生できる 4 GB のエンコードが切られていました。今後は各解像度で、最も大きいリリースから最も小さいリリースまで、等間隔に選ばれたものを残します。両端は必ず含まれます。

各ストリームの説明は、リリースが投稿されてから何日・何年経ったかで終わるようになりました。表示は `3d`、`126d`、`2y` のような形式です。投稿経過時間は、投稿がニュースサーバーから消えている可能性を判断する一番の手がかりになります。この変更より前にキャッシュされた結果は、そのタイトルのキャッシュが更新されるまで経過時間が表示されません。

アドオンのマニフェストには、`0.1.0` ではなく実際のビルドバージョンが入るようになりました。`zurg --version` は `zurg version` と同じビルド情報を表示し、設定ファイルも不要です。

## 健全なリリースがライブラリから消え続けなくなりました {#healthy-releases-stop-disappearing-from-the-library}

Real-Debrid APIへの接続失敗やDNSの名前解決の失敗が起きると、アカウントが一時的に利用不可としてマークされるようになりました。以前は、正常なファイルを壊れたものとしてマークしてしまっていました。その結果、ネットワークが復旧した後も、そのファイルは修復待ちのまま放置されていました。

ライブラリ更新後のクリーンアップは、以前はバックグラウンドのメディア解析が終わるまで待たされていました。クリーンアップが実行される頃には、新しい更新で作品のリリースが再び追加されている可能性がありました。その遅れたクリーンアップが、そのリリースを再び削除してしまっていました。現在は、更新が返ってくる前にクリーンアップが完了します。メディア解析は引き続きバックグラウンドで実行されます。

## Kodi で WebDAV 共有を閲覧できます {#kodi-can-browse-the-webdav-share}

WebDAVのリスト表示では、すべてのフォルダとファイルのフルパスに`/dav/`プレフィックスが付くようになりました。以前は、Kodiなどの厳格なプレイヤーがこのプレフィックスを落としてしまい、フォルダやメディアを開けませんでした。エスケープされた文字を含む名前や、アーカイブ内のパスもアドレスはそのまま維持されます。

## 混雑したニュースサーバーでも、ストリームに穴が開かなくなりました {#a-busy-news-server-no-longer-puts-holes-in-a-stream}

ニュースサーバーは、記事を持っているのに、忙しいときに「そのような記事はありません」と答えることがあります。以前の zurg は、その答えを数百ミリ秒後に同じ接続で確認していました。すると、その範囲をゼロとして返し、その記事を1日の間使えないものとして扱っていました。ある 32 MiB の読み取りでは、サーバーが1分後には正しく返した記事から、384,000 バイトのゼロが返ってきたことがありました。

拒否された記事は、1秒後にもう一度だけ問い合わせるようになりました。2回目の問い合わせは、空いている別の接続を使います。読み取りは隙間を埋めるのではなく、その答えを待ちます。本当に存在しない記事は、これまでどおり無音として返され、修復されます。そのため、破損したリリースが無音の状態になるまで、約1秒余計にかかるようになります。

接続が止まってしまった記事も、別の接続で一度だけ再度問い合わせるようになりました。以前は、この時点でレスポンス全体が失敗していました。RAR ストリームでは、プロバイダーの送信が遅いだけの記事に対して 500 が返されていました。

## zurg が呼び出すサービスに対して、自身をどう識別するかを選べます {#choose-how-zurg-identifies-itself-to-the-services-it-calls}

デバッグサービスやインデクサーへのリクエストには、デフォルトで一般的なブラウザーの User-Agent が使われるようになりました。字幕の検索でも同じものを使うので、もう `zurg v0` は送られません。また、zurg 独自のヘッダーと一緒に、origin と referrer のヘッダーも送られなくなります。これはリダイレクトをまたいでも同じです。リダイレクトで、前の URL の非公開パスや API キーが漏れることはありません。

`user_agent` で別のエージェントを設定でき、`omit_user_agent` を使うと何も送らなくなります。`outbound_*` のキーは、Plex、Jellyfin、Emby に表示されるクライアント名とデバイス名を設定します。これらはすべてダッシュボードの Network & Connectivity にあり、再起動後に反映されます。Usenet への接続では、ソフトウェアを示す識別子は一切送られません。これで zurg 独自の識別子はなくなりますが、匿名になるわけではありません。

詳しくは [Outbound identity](outbound-identity.md) を見てください。

## zurg は、デフォルトで Plex のゴミ箱を空にします {#zurg-empties-the-plex-trash-by-default}

zurgは、Plexの「Empty trash automatically after every scan」をオフにします。そうしないと、一時的に読めなくなったマウントに当たったスキャンが、ライブラリを退避させる代わりに削除してしまいます。そのときに残ったものは、誰にも気づかれませんでした。Plexはもう不要になったエントリを回収しなくなり、zurg自身による削除はオプトインでした。そのため、デフォルトでは何もそれらを回収していませんでした。ファイルがとうに消えたエントリが溜まっていきました。いちばん目立ったのは、ライブラリのフォルダー間で移動されたファイルの場合で、古いエントリが永遠に残り続けていました。

`plex_trash_sweep_every_mins` を未設定にすると、ごみ箱の掃除が60分ごとに実行されるようになりました。Plexがまだ自分のごみ箱を空にしている最中は、掃除は動きを止めます。一度に1件ずつエントリを削除し、ファイルが残っているエントリは決して削除しません。読み取れるマウントに対してのみ実行されます。判断できないものは、まず14日間、壊れた状態として表示され続けます。削除を行わないようにしたい場合は、`plex_trash_sweep_every_mins: 0` と書いてください。ごみ箱は自分で空にします。

この設定を使っても、ごみ箱を空にする役割がPlexに戻るわけではありません。そのために、設定ページに「Let Plex Empty Its Own Trash」スイッチが追加されました。そのリスクはスイッチの横に書かれています。

復元も動くようになりました。Plexは、すでにスキャンしたフォルダーへの通常のスキャンをスキップします。ファイルがすべて戻っているのにごみ箱に入ったままの番組が、何度スキャンしても残り続けることがありました。掃除は、そのフォルダーの強制スキャンをPlexに依頼するようになりました。ダッシュボードから手動で開始したスキャンも、Usenetライブラリのインデックス元である`__magic__`パスに届くようになりました。以前は、Plexのセクションが見つからず、何も行われませんでした。

2つの回収機能がこの作業をどう分担しているかは、[Plex](../guides/plex.md#who-empties-the-trash)に書いてあります。

## 壊れたアーカイブは、正しいバイト数を表示するか、何も表示しません {#damaged-archives-list-the-right-bytes-or-nothing-at-all}

以前は、壊れた RAR セットの一部が、間違ったバイト列を再生する動画として一覧に出てしまうことがありました。途中のボリュームが欠けているセットでは、残りの部分がずれた状態で、末尾にゼロが続く形で配信されていました。そのようなセットは、今では拒否されます。

最初のヘッダーを読めなかったセットでは、後ろのバイトがずれていました。zurg は、すべてのオフセットが正しく保たれるように、まず継続ヘッダーを読むようになりました。最後のボリューム内で、映画の後ろにあるファイルも残るようになりました。

以前は、RAR4 の終端マーカーが暗号化と誤認されていました。終端ブロックがパディングされている分割セットでは、最初のボリュームが失われていました。今では、完全な動画が一覧に表示されます。

記事の 10% 以上が欠けている NZB は、何も配信される前に拒否されます。PAR2 で修復済みのコンテンツは、引き続き再生できます。

既存のアーカイブ一覧は再構築されるので、これらの修正はライブラリにすでにあるリリースにも反映されます。

## 大きなライブラリでもアイドル時のメモリを返せるようになりました {#large-libraries-can-give-idle-memory-back}

`library_detail` は、各リリースのファイル一覧をメモリに残し続けるかどうかを決めます。`resident` はすべてのファイル一覧を残し続けるので、こちらがデフォルトです。`lazy` は、`library_detail_idle_secs` の間だれも読んでいないファイル一覧をメモリから解放します。一覧自体は引き続き見られ、だれかが読むときにディスクから戻されます。`auto` は、ホストやコンテナのメモリが長時間逼迫しているときだけ同じことをします。大きなシーズンパックは、どちらのモードでもメモリをかなり少なく使います。圧縮された復旧用のコピーがあれば、ディスクキャッシュが壊れたときにファイル一覧を守れます。未保存の変更は、解放されることはありません。ダッシュボードには3つのモードすべてが表示されます。変更を反映するには再起動が必要です。

Real-Debrid のダウンロード履歴が多いときも、起動時のメモリ使用量が少なくなりました。履歴とライブラリのキャッシュを保存・読み込みする際に、余分なコピーを作らなくなっています。

トレードオフについては、[設定リファレンス](config.md#library-detail) を参照してください。

## PlexのウォッチリストとSeerrのリクエストが1つのキューを共有 {#plex-watchlist-and-seerr-requests-share-one-queue}

`acquisition:` ブロックは、Plex のウォッチリストの項目と Seerr のリクエストを、ひとつのキューにまとめます。どちらも Newznab インデクサーで検索され、結果は Usenet バックエンドに入ります。Seerr のリクエストは、承認されたあとにだけ追跡されます。取得されるのは、リクエストされたシーズンだけです。4K のリクエストは 1080p のリクエストとは別に管理されます。未完了の Seerr リクエストは、新しく放送されたエピソードがないか再チェックされます。

進行状況は再起動後も残るようになりました。再試行の期限、試行回数、どのエピソードが完了したかが対象です。中断された取得は、止まったところから再開されます。すでに完了していた取得は、ウォッチリストから項目を削除する再試行だけを行い、再検索はしません。保存された状態は通常のバックアップにも含まれます。既存の `watchlist:` の設定は、これまでどおり動作します。

セットアップについては [取得](../guides/acquisition.md) を参照してください。

## デブリッドのライブラリをポータブルなローカルファイルとして置けるように {#debrid-libraries-can-live-in-portable-local-files}

デビッドアカウントは、アカウント自体のリストではなく、`.zurgtorrent` ファイルのフォルダからライブラリを読み込めるようになりました。`zurg export-torrents` を使うと、既存のライブラリをそのようなファイルとして書き出せます。ファイルにはコンテンツの情報だけが含まれ、認証情報やダウンロードリンクは入っていません。そのため、ライブラリを共有できます。受け取った人は自分のアカウントで再生し、プロバイダーの制限も自分のアカウントに適用されます。ファイルのインポート、一覧表示、更新をしても、アカウントには何も追加されません。

既存の設定はそのまま動きます。新しいバックアップは形式 2 で作られ、復元するにはこのビルド以降が必要です。

書き出しと設定の方法は [ローカルライブラリ](../guides/local-libraries.md) にあります。

## 読み取りキャッシュは再起動後も残ります {#read-caches-survive-a-restart}

zurg は読み取りキャッシュを再起動後もディスクに保持するようになりました。対象は、解析済みの NZB、デコード済みの Usenet 記事、アーカイブのレイアウトとデコード済みのアーカイブブロック、そして配信リンクです。再起動後、zurg はすべての NZB を解析し直したり、すべてのアーカイブヘッダーを読み直したりする必要がありません。各バイトキャッシュの上限は、デフォルトで 512 MiB です。`zurg backup --include-caches` を使うと、キャッシュをバックアップに含めて、起動直後から速く動くようにできます。

同じ AllDebrid または TorBox のファイルに対するリクエストが同時に届いた場合、リンクの照会は 1 回にまとめられるようになりました。

設定と上限値は [永続キャッシュ](../internals/persistent-caches.md) にまとめています。

## Usenetの取得は、Completedになる前により慎重にチェックされます {#usenet-grabs-are-checked-more-closely-before-they-read-completed}

「Completed」と表示された grab の前に、zurg はニュースサーバーに、各コンテンツファイルの最初の16記事と最後の記事を確認します。以前は最初の記事だけを確認していたため、メディアヘッダーの欠落を見逃していました。確認はファイルごとに1つのバッチとして送られるようになったので、大きなアーカイブでも時間切れになりにくくなりました。

欠落した記事の PAR2 修復が完全に完了したリリースは、インポートできるようになりました。以前は、元の記事がサーバーからまだ消えたままだったため失敗していました。部分的な修復は、これまでどおり対象になりません。

`sabnzbd.history_limit` で、Sonarr や Radarr の大きな履歴上限に合わせられるようになりました。これにより、完了済みジョブの大きなバックログを、より大きなバッチで処理できます。両側で同じ数値を設定してください。デフォルトは60のままです。

## `enforce`は見えているPlexの機能に影響しません {#enforce-leaves-the-plex-features-you-can-see-alone}

`plex_settings_policy: enforce` はもう、サムネイルプレビューやチャプター画像の生成をオフにしません。音量の平準化やソニック解析もオフにしません。どれもファイル全体をデコードするので、デバッグマウントでは帯域を消費します。ただし、どれも見て分かる結果を出します。今後はスキップイントロやスキップクレジットと同じく、好みで決める項目になります。zurg は引き続き、それぞれのコストを報告します。ただ、選択を代わりに決めることはもうしません。帯域グループに残るのは、その出力を誰も見ない解析だけです。

## 期限切れのデブリッドリンクは、再生を失敗させずに自動で復旧します {#expired-debrid-links-recover-without-failing-playback}

TorBox のリンクで署名トークンが古くなったものは、今後は新しいものを取得するようになりました。同じファイルを待っている読み込みは、その 1 回の検索結果を共有します。失敗が繰り返されても、ファイルを壊れたものとして扱わず、再生だけを一時停止します。

TorBox、Real-Debrid、AllDebrid のダウンロードサーバーが zurg に待つように指示してきた場合、今後は指示された時間だけ待つようになりました。また、拒否し続けるサーバーへの再試行も止めるようになりました。これは再生、リンクチェック、アーカイブの読み取りのすべてに当てはまります。`__downloads__` から開いた無効になったリンクも、新しいものを取得するようになりました。

## zurgは自分でアップデートします {#zurg-updates-itself}

`zurg update` は、実行中のバイナリを最新のスポンサー向けナイトリービルドに置き換えます。GitHub CLI にサインインしていればそのログインを使い、なければ `GITHUB_TOKEN` または `GH_TOKEN` を使ってリリースフィードを読みます。置き換える前にダウンロードの中身を確認し、想定されるバージョンを報告します。置き換えはリネームで行うので、zurg の実行中でもアップデートが失敗することはありません。すでに最新のナイトリーか、それより新しいビルドなら、何もせずそのままにします。コンテナ内ではこのコマンドは実行を拒否し、代わりにイメージの pull を案内します。置き換えたバイナリはコンテナを再作成すると失われるためです。`--force` を付けると上書きできます。インストーラーには、このコマンドを持たない古いビルド向けに、対応する `update` モードが追加されました。

プラットフォーム別: [Linux](../setup/linux.md#updating-zurg)、[macOS](../setup/macos.md#update-zurg)、[Windows](../setup/windows.md#updating-zurg)、[Docker](../setup/docker.md)。

## Plexの設定1つだけはポリシーからオプトアウトできます {#one-plex-setting-can-be-opted-out-of-the-policy}

`plex_settings_ignore` は、`plex_settings_policy` の設定に関係なく zurg が触らない Plex の設定項目を指定するものです。

これは、そのうちのひとつを本当に必要とする構成のためにあります。たとえばファイルがフォルダ間で移動するライブラリでは、残ったエントリを消すために Plex が自分のゴミ箱を空にすることに頼っています。ところがデフォルトのポリシーはこれをオフにしています。かといって `warn` に下げてこの設定を取り戻すと、その横にあるファイルシステムイベントのガードも手放すことになってしまいます。

無視された設定も、引き続き読み取られ、ダッシュボードや `zurg plex-settings` の `skip` として報告されます。違うのは、書き込まれることも、警告されることも、ゴミ箱バナーの対象になることもない、という点だけです。

安全のための設定を無視するのは自己責任です。zurg は起動時に一度だけそのことを伝えます。どの設定も指さない ID は報告され、その設定は引き続き保護されたままになります。そのため、入力ミスがオプトアウトとして扱われることはありません。

設定項目そのものと、各ポリシーレベルがそれらをどう扱うかについては、[Plex](../guides/plex.md#recommended-plex-settings) を参照してください。

## 対応するすべてのホスト向けのワンラインインストーラー {#one-line-installers-for-every-supported-host}

新しいインストールでは、Linux、macOS、Windows、Linux 上の Docker 向けに、1 行で済む任意のブートストラップが使えるようになりました。プラットフォームの前提条件を確認またはインストールし、スポンサー向けアクセスには GitHub のブラウザサインインを使い、正しいアーキテクチャをダウンロードして、`zurg setup` と `zurg doctor` に引き継ぎます。既存のバイナリと設定はそのまま残り、手動ガイドもすべて引き続き利用できます。

## セットアップで設定するプロバイダーを聞かれます {#setup-asks-which-providers-to-configure}

新規の `zurg setup` インストールでは、もう Real-Debrid が前提になりません。対話式インストーラーは、優先順位の順にプロバイダーを1つ以上尋ね、選択されたプロバイダーの認証情報だけを集めます。非対話式のインストールでは、`--provider` を繰り返し指定し、プロバイダーごとのトークンファイル用フラグや環境変数を使えます。既存の設定は引き続き保持されます。また、従来の Real-Debrid 向けの `--token-file`、`TOKEN`、`RD_TOKEN` の入力も、明示的に指定すれば引き続き使えます。

## Sonarrの履歴ウィンドウより大きなバーストでも、インポートが失われなくなりました {#a-burst-larger-than-sonarrs-history-window-no-longer-loses-imports}

SonarrとRadarrは、キューにあるジョブをすべてSABnzbdに問い合わせますが、履歴は新しい方の60件だけを取得します。これは本物のダウンローダーであれば通常うまく合います。完了は少しずつ届き、クライアントは取り込みが終わるたびに各ジョブを削除するからです。一方、キャッシュ済みNZBライブラリは違います。シーズンの一括検索では、クライアントが次にポーリングする前に、個々のエピソードのジョブが数百件完了することがあります。以前のzurgは、その全部をキューから削除する一方で、履歴には60件しか返していませんでした。そのページより後のジョブは両方のレスポンスから消えてしまうため、クライアントはそれを取り込みも失敗扱いもできず、そのリリースは`__magic__`の直下に無期限に残り続けていました。

zurgは、表示されているページより後の完了済みジョブをキューに残すようになりました。クライアントが最初の60件を取り込んで削除すると、次の完了分が履歴に繰り上がります。そのため、エピソード単位で取得したシーズンは、固定サイズのウィンドウと競争するのではなく、上限のあるバッチに分けて順番に処理されます。シーズンパックは従来どおり1つのジョブとして扱われます。

## マウント経由の削除は常に成功するようになり、`dav_allow_delete`は削除されました {#a-delete-through-the-mount-always-works-and-dav_allow_delete-is-gone}

マウントを指しているメディアサーバーからファイルを削除しても、以前は目に見える反応がありませんでした。zurg が WebDAV の DELETE を 403 で拒否し、rclone がそれを I/O error に変換し、クライアントは原因が分からないまま失敗を報告していました。Plex は単に `400 Bad Request` を返し、ログも残さないため、ボタンはただ動かず、理由も表示されませんでした。

それを許可していたキー `dav_allow_delete` は削除されました。マウント経由の DELETE は、設定なしでどこでも受け付けられるようになっています。このキーをまだ設定している設定ファイルもエラーにはなりません。未知のキーは無視されるだけで、もう何の効果もありません。

このキーが守っていたものがなくなったわけではないので、はっきり書いておきます。rclone には「上書き」を表す方法がなく、書き換えたファイルを DELETE の後に PUT として書き出します。つまり、ファイルをその場で書き換えるプログラム（`.nfo` を書き込むツール、trickplay の処理、\*arr のリネーム、うっかりの `touch` など）は、ファイルを置き換えるのではなく、debrid アカウントからリリースを削除してしまいます。しかもマウントは rclone 自身の認証情報を使うため、上流からは意図的な削除と区別できません。

PUT の方は引き続き拒否されるので、この一連の流れが静かに完了してしまうことはありません。マウントに何か書き込むものがあるなら、`mount_read_only: true` を設定してください。これで書き込みは zurg に届く前に、カーネルの段階で失敗します。

## Plexのウォッチリストが、Newznab indexerを通じて取得を行います {#the-plex-watchlist-acquires-through-your-newznab-indexers}

ウォッチリストモニターが動くようになりました。しかも、ご自身のインデクサーを使って動作します。古いバージョンでは DMM の API キーを使って検索していましたが、Plex がウォッチリストを discover ホストに移行したあと、ポーリングしていたエンドポイントが 404 を返すようになり、いつの間にか動かなくなっていました。現在は正しいホストをポーリングし、新しく追加されたウォッチリストの項目はすべて、設定済みの Newznab インデクサーで検索されます。映画は最も条件に合うリリースが 1 つ選ばれます。ショウはシーズン単位で取得され、その際は**シーズンパック**を個別のエピソードより優先します。パックがないシーズンは個別のエピソードにフォールバックし、エピソードごとに最良のリリースを選びます。選ばれたリリースの NZB リンクの取得に失敗した場合（たとえばインデクサーのバースト制限による 429 など）は、項目を失うのではなく、次に順位の高い候補に切り替わります。選ばれた NZB は、SABnzbd エンドポイントや Stremio アドオンと同じ命名ルールで Usenet バックエンドに投入されるため、3 つのサーフェスが互いの取得を見つけ合い、同じものを重複して取得することがなくなります。項目は、実際に何かが取得された後でのみウォッチリストから削除されます。以前は先に削除してから確認していたため、失敗するたびに項目が静かにリストから消えていました。

`watchlist:` ブロックで設定します。設定できるキーは、`enabled`、`check_every_secs`（デフォルトは 60）、`indexers`（空の場合は `stremio.indexers` を借用します）、`max_size_gb`（デフォルトは 40、映画と単一エピソードに適用）、`max_season_size_gb`（デフォルトは 100、シーズンパックに適用）、`quality`（`best`、`4k`、`1080p`、`720p`、`smallest`）です。従来の `plex_watchlist_*` キーは以前と同じ意味のままです。必要な Plex の設定は `plex_token` だけです。モニターは Plex のクラウドサービスと通信するため、`plex_server_url` がないインスタンスでも問題なく動作します。TV の検索はまず TVDB ID で行い、見つからなかった場合に IMDb ID で 1 回だけ再試行します。インデクサーは TV を TVDB で管理しており、ショウレベルの IMDb マッピングは不完全なことがあるため、インデックスの多いショウでも imdbid 検索の結果が 0 件になることがあるからです。

すべてのキーは設定ページの **Plex Watchlist** の下にあり、[設定リファレンス](config.md#watchlist)にも記載されています。

## Newznab indexerを使うStremioアドオン {#a-stremio-addon-over-your-newznab-indexers}

Stremioに直接応答できるようになりました。`stremio:` ブロックを有効にして、Newznab インデクサーを一覧に登録し、ログに出た `/stremio/<token>/manifest.json` の URL を Stremio に貼り付けてください。クライアントは IMDb ID でストリームを要求し、zurg がインデクサーを検索します（映画は `t=movie`、エピソードはシーズンとエピソード番号付きの `t=tvsearch`）。結果は解像度を優先して並べ替えられ、再生可能なストリームとして返されます。どれかを選ぶと、その NZB が Usenet バックエンドに取り込まれます。取り込みには SABnzbd エンドポイントと同じ命名ルールが使われるため、同じリリースを二度取得した場合は重複させず既存のものが見つかります。再生は署名付きの `/strm/e/` エンドポイント経由で行われ、範囲リクエスト、フェイルオーバー、アーカイブ内部のファイルにも対応しています。再生したものはすべてライブラリに入るので、ほかのリリースと同じように Plex に表示されます。

トークンはパスの中にあり、これが認可のすべてです。設定でトークンを指定しなければ、自動で生成されて `data/stremio-token` に保存されます。検索結果は `data/stremio-cache` にキャッシュされるため、同じタイトルを開き直してもインデクサーへの問い合わせは発生しません。キャッシュの有効期間は検索でヒットした件数に応じて変わります。結果が4件まではリリース1件あたり1時間、5件以上になると `stremio.cache_hours`（既定値は24）です。結果が空の場合はキャッシュしません。キャッシュされたストリーム一覧には更新項目があり、選ぶとそのタイトルのキャッシュを消去します。

`stremio.max_size_gb`（既定値は40）を超えるリリースは一覧から除外されます。これにより、ディスク全体をそのまま収めたremuxが、再生可能な選択肢をすべて押しのけて上位に来ることを防げます。

初回再生にかかる時間も含めた全体の流れは、こちらをご覧ください：[The Stremio addon](../guides/stremio.md)

## 1つのフォルダがDockerインストール全体で、初回起動時にマウントされます {#one-folder-is-the-whole-docker-install-and-it-mounts-on-the-first-run}

以前、Docker で zurg を起動する公式の方法は、`TOKEN` を含む `docker run` を 1 回実行するものでした。しかしその結果できたコンテナは何もマウントしていませんでした。生成された設定では `rclone_enabled` がオフのままで、`mount_path` も未設定だったため、ダッシュボードでこの 2 つの項目を見つけて変更するまで `/zurg_mnt/zurg` は空のままでした。さらに、その設定はコンテナ内に書き込まれていたため、次の `docker pull` でライブラリのキャッシュとともに消えてしまいました。クイックスタートには、この 2 つの項目を列挙した脚注が必要でした。これでは、クイックスタートが動かないことを自ら認めているようなものです。

`MOUNT_PATH` を指定すると、設定を作成する実行時に、`TOKEN` がすでに設定していた項目と並べて `rclone_enabled: true` と `mount_path` も書き込まれるようになりました。イメージの作業ディレクトリは `/config` で、zurg が保存するものはすべてこの下に解決されます。`config.yml`、`data/`、`logs/`、`dump/`、`strm/`、`nzbs/`、そして rclone のキャッシュがそれにあたります。そのため `-v ~/zurg:/config` を 1 つ指定するだけでインストール全体が収まり、イメージを更新しても何も移動しません。初回起動はコマンド 1 つで済み、ダッシュボードで作業しなくても、マウントされたライブラリが使える状態で終わります。

どちらの変数も、**設定ファイルがまだ存在しない場合にのみ**読み込まれ、それ以降は無視されます。これは `log_level` が `LOG_LEVEL` に対して既に取っているルールと同じで、理由も同じです。compose ファイルに残っていた `MOUNT_PATH` が、後からダッシュボードで変更したマウントパスを黙って元に戻すようなことがあってはなりません。今回から、設定されている値が設定ファイルと食い違う場合には起動時に警告が出るようになりました。そのため、効果のない設定のまま再デプロイしてしまったオペレーターにも、その理由が伝わります。

古いレイアウトで作られたインストールには影響しません。Docker はバインドマウントのすべての接続先を作成するため、`/app/config.yml`、`/app/data`、`/app/logs` のいずれかが存在すれば、それは古いレイアウトであることを示しています。コンテナはそれらのどれかを見つけた場合、引き続き `/app` を使います。セットアップの全体と、ホストから見えるマウントを壊す要因については、[Docker](../setup/docker.md) を参照してください。

## TorBoxとAllDebridにも`.torrent`を渡すので、非公開の取得が放置されません {#torbox-and-alldebrid-are-handed-the-torrent-too-so-a-private-grab-is-not-left-hanging}

\*arr が送ってくる `.torrent` ファイルは、前回のリリースからアドイン時に送られるようになりました。ただし対応していたのは Real-Debrid だけで、残りの 2 つのアカウントにはインフォハッシュだけが渡されていました。プライベートトラッカーのリリースでは、これは使えない唯一の形式です。

何も失敗しなかったため、問題が見えにくくなっていました。ライブの TorBox アカウントで確認したところ、公開スワームのないハッシュは torrent id 付きで受け付けられ、その後は `checking` のまま `size: -1`、ファイル一覧なし、100 日ほどの推定時間と報告していました。TorrentLeech からの取得で「ただハングして、何もダウンロードされない」と報告されたのと同じ状態です。同じリリースのファイルは、実際の名前、サイズ、ファイル一覧がすぐに返ってきました。そして qBittorrent のエンドポイントも作業を進められました。

両方のアカウントがファイルを受け付けるようになりました。TorBox の `createtorrent` と AllDebrid の `magnet/upload/file` は、マグネットの代わりにファイルを受け付けます。応答の形式もマグネットのアドで返していたものと同じなので、アド以降の処理は何も変わりません。AllDebrid は、アップロードの時点でコンテンツをすでに持っていたかどうかを今も報告します。これは同アカウントが返す唯一のキャッシュ情報です。

両方について、zurg 自身のアドパスを通してライブで検証しました。キャッシュ済みのリリースは、数秒以内にアップロードされ、`done` で 100% のファイル一覧付きで読み戻されました。誰も持っていないリリースは、名前とサイズが付き、ピア不足で停滞した状態で読み戻されました。これはエンドポイントが対応できる状態です。ハッシュの場合は、解決もせず完了もしない torrent になっていました。

拒否の理由も分かるようになりました。TorBox が 4xx で拒否した呼び出しは、共有 HTTP クライアントの "unexpected status code: 400" だけが呼び出し元に届いていました。TorBox は独自のエラーコードと詳細をレスポンスボディに入れているのですが、そのボディは捨てられ、ステータスエラーに置き換えられていました。そのため、TorBox が処理しない `.torrent` は、\*arr にはステータス番号としてしか報告されませんでした。今はまずボディを読むので、そのアカウントが返した理由が拒否と一緒に伝わります。

インデクサーを設定するときは、[Sonarr と Radarr、torrent の利用について](../guides/sonarr-radarr-torrents.md) を参照してください。

(前回の翻訳は却下されました。コードスパンが一致していませんでした。構造をそのまま保ってください。)

## 圧縮アーカイブのエントリは、必要に応じてデコードしながらストリーミングされます {#compressed-archive-entries-stream-decoded-on-demand}

圧縮された RAR や deflate の zip エントリは、無圧縮エントリのように範囲指定の読み取りに応えられません。そのバイト列は、エントリの先頭から実行しないと得られないデコーダの後ろにしかないからです。そのため zurg はこれらを拒否していました。圧縮だけのリリースには 415 を返し、無圧縮エントリと並んでいる圧縮エントリはスキップしていました。ストリーミング利用者にとっては正直な答えでしたが、その結果、Usenet の古いカタログの大部分が隠れていました。圧縮してまとめて投稿された、あらゆる投稿がこれに当たります。

これらのエントリは、必要に応じて前方にデコードしながら、有界なメモリ内ウィンドウに載せて配信するようになりました。ディスクには何も書き込まず、どの読み取りも要求していない部分はデコードしません。プレイヤーが発行する順次再生は、ウィンドウの端に当たり、読み取りのたびに少しずつ進みます。ウィンドウが保持している範囲より前へシークすると、エントリの先頭からデコードをやり直します。エントリ全体のバイト列は、unrar が展開するものと同じになります。実際の圧縮 RAR4 ボリュームにある 3 つの jpg エントリは、独立したデコーダで読んだ同じフィクスチャと比べて、md5 がすべて一致し、バイト単位で正確にデコードされることを確認しています。

分割セットのボリュームをたどるには、rardecode のボリュームチェーンが必要でした。これは `.part02.rar` をファイルシステムから開きます。一方 zurg のボリュームは、範囲指定のネットワークリーダーの向こう側にあります。そこで、デコーダを `internal/rardecode` に取り込みました（MIT ライセンス、上流 v1.1.3）。変更点は 1 つだけです。`OpenReaderOver` がオープナーを受け取るようになったため、次のボリュームは、アーカイブ自身が導出した名前でセットから取得できます。

これに合わせて、リストの形も変わりました。圧縮だけのリリースは中身のペイロードを表示します（`stream_compressed_archives: false` を設定すると、以前の拒否動作に戻ります）。混在したアーカイブでは、無圧縮のエントリと並べて圧縮されたエントリも一覧に表示されます。リストのバージョンは 15 です。

## SonarrとRadarrはtorrentを取得でき、Prowlarrはそれを送り込めます {#sonarr-and-radarr-can-grab-torrents-and-prowlarr-can-push-them}

zurg は \*arrs に対して qBittorrent のように応答できます。\*arrs が magnet リンクや `.torrent` を渡すと、zurg はその info hash を debrid アカウントに追加します。アカウントは設定されているもの（Real-Debrid、TorBox、AllDebrid のいずれか）が使われます。リリースがライブラリに入ると、torrent は完了と表示され、インポート元として `__magic__` 配下のフォルダが現れます。インポートは、SABnzbd エンドポイントが Usenet の grab に対してずっと行ってきたのと同じリネームです。`__magic__` テーブルに 1 行追加されるだけで、データは移動しません。

このエンドポイントは `/api/v2` と `/qbittorrent/api/v2` に登録されます。要求があるまでは無効です。クライアントは API キーを bearer token として送信し、それで認証されます。grab は、torrent を扱えるすべてのアカウントに対して `providers:` の順番で提示されます。grab が止まってしまった場合、つまりステージが変わらず、進捗も上がらない状態が `qbittorrent.download_timeout_mins` 分続いた場合（デフォルトは 15 分）は、そのアカウントから外され、次のアカウントで再度試されます。`0` を設定すると、アカウントにキャッシュ済みのコンテンツだけを受け付け、それ以外は追加の時点で拒否します。\*arrs が動作に移すのは、この拒否だけです。アカウント側でのダウンロードの状態は、クライアントが理解できる状態に対応付けられます。レート、スワーム、残り時間は、アカウントが報告している場合にそのまま表示されます。

ひとつ正直に言うと、制限があります。qBittorrent の API には、ダウンロードが失敗したことを伝える方法がありません。そのため、どのアカウントも受け付けなかったリリースは、ブロックリストへの登録ではなく警告としてクライアントに届きます。理由付きでキューには表示されますが、自動では再 grab されません。SABnzbd エンドポイントにはこの問題はありません。

Prowlarr も、ダウンロードクライアントに対するのと同じこのエンドポイントを使います。その用途は、リリースをアカウントに手動で送ることです。Prowlarr から送ったあとは何もインポートされません。インポートは \*arrs の役目です。

実際のインストールで取得した完全な手順は、こちらをご覧ください: [Sonarr & Radarr、torrent の場合](../guides/sonarr-radarr-torrents.md)。

## `__magic__`、整理できるディレクトリ {#__magic__-a-directory-you-can-organise}

zurg が配信するディレクトリはどれも、保存されたフィルターです。リリースは movies フィルターに一致するから `movies` に入っており、同時に `__all__`、`recent`、`movies` にも入っています。そのため、ライブラリの中に何かを*置く*場所は一度もありませんでした。ふつうはそれで問題ありませんが、プログラムがファイルを移動したいと思うまでは、の話です。Radarr と Sonarr はファイルを移動してインポートします。移動を受け付けられないマウントだと、代わりにコピーになってしまいます。そうなると、インポートのたびにリリース全体をデブリッドホストや Usenet から引っ張ってくることになり、マウントが本来避けるべきことそのものになってしまいます。

`__magic__` は新しいトップレベルのディレクトリです。最初は `__all__` の完全なコピーとして始まります。すべてのリリースがフォルダとして並び、`__all__/<release>/` が持っているものがそのまま入っています（仮想化されたアーカイブの中身も含みます）。そして、この中では何でもどこへでも移動できます。

`mkdir -p /mnt/zurg/__magic__/tv/Show/Season 01` を実行して、そこにエピソードを `mv` すると、そのエピソードはそこにあります。バイトは移動せず、torrent の名前も変わらず、何も再ダウンロードされず、`__all__` も変わりません。移動は小さなテーブルの 1 行を書き換えるだけです。このテーブルは、リリースのコンテンツハッシュと、その中にあるファイル自身のパスをキーにしています。そのため、リリースを追加し直して周りの ID をすべて作り直す修復を行っても、置いた場所は失われません。ダッシュボードからリリース名を変えても、同じく失われません。

移動は双方向です。ファイルはリリースフォルダの外へ出すだけでなく、*中へ*移動することもできます。その場合、フォルダにはリリース自身のエントリと並んでそのファイルが表示されます。インポート元のフォルダに何かを戻すプログラムには、まさにこれが必要です。同じ名前が2か所から同時に来た場合は、意図的に置いた方が優先されます。移動したファイルは、リリースがその名前で持っているものに勝ち、それは `data/local` にあるファイルに勝ちます。負けた方は二重に表示されるのではなく、一覧から外れます。

削除はもう一方の側面です。デフォルトでは、破棄ではなく非表示になります。`__magic__` 内での `rm` はエントリを `__magic__` から外しますが、`__all__` とすべてのフィルターディレクトリには残ります。そのため、ライブラリを整理しているクライアントが何かを失うことはありません。リリースフォルダも同じように消えることができます。これにより、Sonarr はインポートの後でジョブフォルダを削除しても、インポート元のリリースには手をつけずに済みます。`magic.allow_delete: true` を設定すると、ファイルについては強い意味（中身も消える）を選べます。リリースフォルダとディレクトリは、この設定に関係なく常に非表示になるだけです。

デフォルトではオフになっています。書き込み可能なツリーであり、間違ったルートフォルダを指している \*arr がライブラリを作り替えてしまう可能性があるためです。

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

`sidecar_` で始まる2つのキーは、zurg 自身のマウントを経由せず、`/dav` を直接マウントするクライアント向けです。こうしたクライアントは、新しい `.nfo`、ポスター、字幕トラックを `PUT` で zurg に送ります。すると zurg は、その中身を `data/local/__magic__/…` に書き込みます。これは、zurg 自身のマウントがすでにそうしたファイルを書き込んでいるのと同じツリーです。そのため2つのビューは、ディレクトリを2つではなく1つとして表示します。また、ファイルは他のファイルと同じように、レンジ読み出し、長さ、更新日時付きで読み戻せます。上限があるので、これが黙って汎用のファイルストアになることはありません。`sidecar_max_mb` を超えるファイルは 413 で拒否されます。ツリーが `sidecar_budget_mb` を超えてしまう場合は 507 で拒否されます。ライブラリが応答しているものは上書きできません。リリースフォルダ、そのエントリ、移動先にされたパスへの書き込みは 403 になります。また、移動によって行のために実ファイルを破壊することは決してありません。

何かを向ける前に知っておきたいことが2つあります。フィルターディレクトリは仕様上そのままにしてあります。そのため、`__magic__` 内で移動したリリースも、元の名前のまま `recent` と `movies` に残ります。メディアサーバーは `__magic__` **か**フィルターのどちらかを指定してください。両方を指定してはいけません。また、マウントは以前から一方向だけ書き込み可能でした。そこに本当に新しく書き込まれたもの（`.nfo`、字幕、ポスターなど）は、zurg 自身の `data/local` に保存され、一覧にマージされます。だからこそ、リリースの横に置いたサイドカーはそのまま機能しますし、\*arr のルートフォルダの書き込みテストも通るわけです。

`dav_allow_rename` と `dav_allow_delete` は、ここでの話とは一切関係ありません。これらは、デブリッドアカウントが保持しているものをリネームおよび削除する経路を守るものです。`__magic__` 配下への書き込みはどのアカウントにも届きません。`mount_read_only: true` は、これまで通りすべてに優先します。

ダッシュボードには専用のページがあり、`/magic/` で開けます。テーブルが保持しているすべての行を表示します。リリースごとにグループ化し、各行が何であるか、どのリリースのどのファイルから来たか、そのファイルが今どこから配信されているかを示します。あわせて、行数、ジャーナルとスナップショットがディスク上で占めるサイズ、ライブラリ横の実ファイルが `sidecar_budget_mb` のうちどれだけ使われているかも表示します。また、`data/local` 全体のサイズも報告します。この数字を見れば、インポートがコピーで行われているかどうかがわかります。移動の代わりにコピーするクライアントは、バイトをここに書き込みます。ダッシュボードの他のどこにも、それは表示されません。

表示される状態のうち3つは、クライアントからは一切到達できないものです。配置は **reset**（リセット）でき、そのファイルはライブラリが本来置く場所に戻ります。墓標（tombstone）は **unhidden**（非表示解除）でき、そのエントリは再び一覧に表示されます。そして **dangling**（宙ぶらりん）の行は、そのリリース、またはその中のファイルがライブラリにもう存在しない行です。これは1行ずつでも、一括でも削除できます。最後のものは新しい扱いです。このような行は何にも解決されないため、クライアントはそれを一覧表示も、移動も、削除もできません。また、削除されずに残すのは意図的です。リリースを戻す修復を行えば、配置も一緒に戻るためです。これまでは、そうした行を片付ける場所がありませんでした。サイドカーも一覧に表示され、同じ分類が適用されます。もう何にも紐づいていないフォルダ内の実ファイルは、たとえばライブラリから消えたリリースの横にある `.nfo`、あるいは忘れられた配置の中にある `.nfo` などですが、これは **orphaned**（孤立）と表示され、他とは別にカウントされます。宙ぶらりんの行と同じ理由で、自動で掃除されることはありません。ファイルはまだあなたのものであり、リリースを戻す修復を行えば、そのフォルダも再び紐づけられるからです。そこにあるものを削除すると、マウント経由の `DELETE` と同じように、実際にファイルが削除されます。これらのボタンはどれも、変更された一覧をマウントに忘れさせます。ポーリングがオフの状態では、マウントはディレクトリを12時間キャッシュするためです。

`magic:` と `sabnzbd:` は、今では設定ページから編集できます。どちらも **Restart Required**（再起動が必要）と表示されています。これは本当に再起動が必要だからです。`__magic__` を配信するルートと SABnzbd のエンドポイントは、起動時に一度だけ、まさにこれらの値から決められます。どちらかをオンにすると `config.yml` に書き込まれますが、その時点で応答している実行には何の変更も加えません。また `__magic__` のページでは、そのことをはっきり明記します。すべてが正常であるかのように空の名前空間を表示することはありません。

### SonarrとRadarrが、NZBをzurgに直接渡せるようになりました {#sonarr-and-radarr-can-now-hand-zurg-an-nzb}

`__magic__` が存在する理由は、\*arr がインポート元にできる場所を用意するためです。zurg は今、その反対側の役割も担うようになりました。`/api` にあるエンドポイントは、SABnzbd のふりをして Sonarr と Radarr に応答します。両者を zurg のホストとポートに向け、API キーを貼り付けてください。するとグラブは Usenet バックエンド用の `nzbs/` に届きます。リリースがライブラリに入ると、ジョブは Completed と報告し、`__magic__` 配下のフォルダを示します。インポートはマウント内での名前変更にすぎません。テーブルの 1 行で済み、バイトは読まれず、シリーズフォルダに入れるために Usenet から何かをダウンロードすることもありません。

```yaml
sabnzbd:
  enabled: true
  api_key: ""          # left empty, zurg generates one and logs it once
  categories: [tv, movies]
  complete_dir: ""     # defaults to <mount_path>/__magic__; set it to what a containerised *arr sees
```

初期状態ではオフです。両方の要素が揃って初めて役立ちます。NZB を読むための `nzb` プロバイダーと、インポート元を用意するための `magic.enabled` です。このエンドポイントは zurg の basic 認証の背後にはありません。どちらの \*arr も、ダウンロードクライアントに認証情報を送ることはなく、HTTP 層は 401 を「接続できない」と解釈するためです。API キーだけが唯一の防御になるので、そのポートは相応に扱ってください。ルートフォルダは **`__magic__` の内側** に置いてください（`__magic__/tv`、`__magic__/movies`）。`__magic__` そのものや、その上には置かないでください。クライアントのルートフォルダのヘルスチェックが問題を指摘するためです。

ライブラリを切り替える前に知っておいてほしいことが一つあります。**失敗の検出は部分的です。** ライブラリが保持しているものの、インポートできるものが何もないリリース（すべてのファイルが壊れている、削除されている、またはフィルタで除外されている場合。あるいは修復用の足場ファイルとサイドカーしかない場合。リカバリボリュームだけの NZB がまさにこれです）は `Failed` と報告されます。これにより両方のクライアントはそのリリースをブロックリストに載せ、代わりの候補を取得します。RAR セットはコンテンツとして扱われます。zurg は動画をそこから直接ストリームするためです。ただし、圧縮エントリだけを含み zurg がまったくストリームできないものは例外です。このような場合、何かがそれを開いて中身を確認した時点で `Failed` と報告されます。その判定はリリースに保持されます。判定を得るには、セット内のすべてのボリュームを読む必要があるためです。

報告されないのは、記事がニュースサーバーから失効した投稿です。zurg はまだそれをチェックしないため、死んだリリースも他と同じく Completed と報告され、最初の読み取りで失敗します。その結果、Sonarr はダウンロードの失敗ではなくインポートの失敗として認識します。この点は今のところ手動で判断する必要があります。それ以外のフローはすべて動作します。インポート後のクリーンアップも含みます。Sonarr が削除するジョブフォルダはトゥームストーンになり、リリースは `__all__` に残ります。

グラブは次の変更ポーリングを待ちません。zurg は、ローカルファイルを書き込んだ直後に監視ディレクトリを再読み込みします。これは Usenet アカウントに限られます。シーズンパックは数秒で 20 件のグラブになり、数万件のトレントがある debrid ライブラリを再一覧して、ローカルファイルに気づくのは 20 倍の無駄な作業になるからです。`nzb` プロバイダーがまったく設定されていない場合、zurg は起動時にその旨を伝えます。何も読まれないグラブを受け付けるのではなく。

`__magic__` ページはジョブを一覧表示します（読み取り専用）。表示される内容は、各クライアントがグラブを識別する `nzo_id`、そのカテゴリ、到着時刻、ライブラリがそのリリースをすでに一覧に載せているかどうか、そして載せた後に \*arr がインポート元とするフォルダです。

リモートパスマッピング（コンテナ化された \*arr 向け）や、各接続テストエラーの意味を含む完全なセットアップは `docs/sabnzbd.md` にあります。

## マウントが、利用可能な帯域幅をより多く使えるようになりました {#the-mount-reaches-more-of-the-bandwidth-it-has}

rclone マウント経由でファイルを読むと、同じデータを HTTP で取得するより遅くなっていました。原因は読み込みの「速度」ではなく、読み込みの「開始の仕方」にありました。最初のチャンクは 4 MB で要求され、そこから倍々に増えていく仕組みだったため、オフセットがゼロの状態から始まる読み込みは、大半の時間を接続が本来出せる速度より低い状態で過ごしていました。しかもシークするたびに新しい読み込みが始まります。最初のチャンクは 32 MB で要求されるようになりました。

約 70 MB/s の利用可能なダウンロード帯域を持つホストで計測しました。各設定は交互に測定し、遅い時間帯の影響が一方だけに出ないようにしています。Real-Debrid での mount のスループット中央値は 49 MB/s から 57 MB/s に上がり、TorBox も同様の傾向でした。AllDebrid は上限がアカウント単位ではなく接続単位のため、ここでの改善は小さくなっています。

効果はチャンクサイズによるものがすべてです。テスト中に FUSE の read-ahead も一緒に上げてみましたが、結果には変化がありませんでした。

追加の帯域も消費しません。チャンクサイズは「要求する量」であって「転送される量」ではなく、再生が止まれば rclone も取得を止めます。4 MB の読み込みでも 6 MB 取得されていましたが、これは read-ahead を完全に無効にした場合と同じです。そのため、最初から最後まで視聴するのではなく、閲覧やサンプリングだけを行うライブラリでも、ダウンロード量はこれまでと変わりません。

設定の変更は不要です。新しい値がデフォルトとして適用され、`rclone_extra_args` で引き続き上書きできます。

## `zurg benchmark-my-setup`で、セットアップが実際にどれくらい速いかを確認できます {#zurg-benchmark-my-setup-answers-how-fast-the-setup-actually-is}

これまでは、ストリームが遅いときに、原因がアカウント、ホスト、マウントのどれなのかは推測するしかありませんでした。新しいコマンドは、プレイヤーが使うのと同じ経路で実際のバイトを読み込み、その分布を報告します。min、median、average、max、そして最初のバイトまでの時間（time to first byte）です。たまたま運の悪かった1回のサンプルで決まってしまうような単一の数値ではありません。

実行は3つのフェーズに分かれます。まず、アカウントを1つずつ個別に測定します。これがサービスの保証値と比べるべき数字です。次に、設定されたすべてのアカウントを同時に測定します。これが、遅いプロバイダーと飽和したアップリンクを見分けられる唯一のフェーズです。単独では各アカウントが70 MiB/s出るのに、一緒にすると25 MiB/sになる場合、それは3つの問題ではなく1つのボトルネックです。レポートには、今見ているのがどちらなのかが書かれます。最後に、rcloneマウント経由で同じ読み込みを行います。最初のフェーズとの差が、FUSEとVFSのコストになります。`rclone_enabled` がオフの場合、マウントのフェーズはスキップされます。

サンプルの位置はランダムなオフセットに置かれ、これは細かい話ではありません。どの層も下位でキャッシュしています。rcloneのVFSは取得済みのデータを保持し、デブリッドCDNのエッジも配信済みのデータを保持します。そのため同じオフセットを再読み込みすると、リンクではなくキャッシュを測ることになってしまいます。実際の環境では、同じファイルが1回目の読み込み（コールド）で47 MiB/s、同じ領域の2回目では285 MiB/sと報告されたことがあります。

サンプルサイズによってマウントの数値の意味が変わるので、レポートではそれを明記します。rcloneは `vfs_read_chunk_size` でファイルを開き、そこから倍々に増やしていきます。そのため短いサンプルでは、ほとんどの時間が立ち上がり途中になります。ある環境で測ったところ、256 MiBのサンプルでは47 MiB/s、1 GiBでは88 MiB/sでした。HTTPは両方とも約70で安定していました。デフォルトの128 MiBはシークとスクラブ時の数値で、`--sample-mb 1024` は持続的な上限の数値です。どちらが間違いというわけではなく、実行結果でどちらを測ったのかが分かるようになっています。

`-n` は反復回数、`--provider` は指定した名前のアカウントだけに実行を絞り込みます。`--skip-mount` と `--skip-concurrent` は各フェーズを除外します。`--json` はスクリプト用にレポートを出力します。これは運用者自身のアカウントの実際の帯域を消費します。アカウントごとに反復回数×サンプルサイズを2回分、さらにマウントのフェーズ分です。zurgのディレクトリから実行してください。NZBバックエンドは作業ディレクトリからの相対パスで `nzbs/` フォルダを読みます。また、何も一覧できなかったアカウントは、大きなファイルがないアカウントとしてではなく、そう報告されます。

## 動作しているReal-Debridのリリースが、リンクチェック後に壊れた扱いされなくなりました {#working-real-debrid-releases-are-no-longer-marked-broken-after-a-link-check}

2026-08-20 の nightly 以降、健全なライブラリでもログに `Link verification failed during refresh` と `keeping files as broken` が大量に出ることがありました。それぞれに `404 Not Found` と、ダウンロードホストに対する `invalid_download_code` が付いています。ただ、リリース自体には何の問題もありませんでした。

その nightly で、Real-Debrid の My Downloads に作られる行を整理する処理が追加されました。zurg が検証したリンクはすべて1行を作成します。放置すると、cold build のたびに torrent ごとに行が増え、起動時には数万行をページングすることになります。整理処理はその行をバックグラウンドで削除しますが、行と、その行が発行した URL は別物だという前提でした。

実際には別物ではありません。行を削除するとダウンロードコードが無効になり、それを生かしておく唯一のものは、すでにそのコードを取得済みのホストです。2026-08-22 に計測したところ、`124-4` で発行され `44-4` で一度取得されたコードは、`44-4` では `200` を返し続けました。一方、`124-4` と、まったく使われていない `125-4` は、どちらも `404 invalid_download_code` を返しました。zurg は高速な数台の中からリクエストごとにダウンロードホストを選ぶため、リンクを検証したホストが次にリクエストを受けるホストであることはほとんどありません。解決結果は4時間キャッシュされ、その間のリクエストはすべて `404` を返しました。これがリンク切れと解釈され、リリースが壊れたものとしてマークされていたのです。

現在は、行が削除待ちに入った時点で解決結果をリンクキャッシュから外すようになりました。消えかけの URL が再利用されることはなく、次のリクエストで新しい URL が解決されます。行の整理自体は引き続き行われます。誤って壊れたとマークされたリリースは、次の refresh で自動的に回復するので、何かを再度追加したり再スキャンしたりする必要はありません。

## 日付で名前が付けられた番組が、映画ではなく番組として整理されます {#shows-named-by-air-date-are-filed-as-shows-not-movies}

`WWE SmackDown 2026-08-21` のように、季節番号やエピソード番号がない番組は放送日で名前が付けられます。それ以降のデイリー番組や深夜番組もすべて同じです。以前のエピソードテストはこの慣習をまったく知りませんでした。`S01E01` を探し、季節番号やエピソード番号が書かれているかを確認し、アニメのリリースのハッシュを探し、どれも見つからなければ番号付きのファイルが連続しているかを探していました。デイリーリリースは日付が1つだけ入った単一のファイルなので、答えは「いいえ」になり、そのリリースは受け入れてくれる最初のディレクトリに振り分けられてしまいました。ほとんどの構成では、それは映画用のディレクトリでした。

放送日がマーカーとして認識されるようになりました。対応する形式は `2026-08-21`、`2026.08.21`、`2026 08 21`、`2026_08_21`、`20260821` です。対象は実在する日付だけです。月は12か月のいずれか、日は31日のいずれかでなければなりません。そのため、`Movie.2026.05.1080p` のように解像度の隣にある年が日付として読まれることはありません。6755 件のリリースからなるライブラリで測定したところ、映画がディレクトリを移動することはありませんでした。実際のデイリー番組のリリース 4734 件で測定したところ、4633 件が認識されるようになりました。残りは、年を2桁に省略していたり、年を末尾に置いていたりする古い scene 名のリリースです。これらは、十分に信頼できる精度で音声チャンネル構成と区別することができません。

すでにディスク上にあるライブラリは、起動時に自動的に振り分け直されます。次回の再起動だけで十分です。再スキャンや再インポートは必要ありません。
