# Plexのトラッシュ掃除をzurg自身のファイル状態に合わせる {#aligning-the-plex-trash-sweep-with-zurgs-own-file-status}

## このドキュメントの目的 {#purpose-of-this-document}

Plex の trash sweep は、現在、Plex ライブラリから何を削除するかを**ファイルの不在とタイマー**で判断しています。zurg はそれよりずっと良い情報、つまりそのファイルの中身が修復可能か完全に死んでいるか、をすでに把握していますが、その情報は参照していません。

この文書は、タイマーをその情報に置き換える計画です。メディアライブラリから何が削除されるかを決める変更なので、コードを書く**前に**レビューしてもらうために作りました。現在の動作は両方向で間違っています。最初の日にすでに死んでいることがわかっているコンテンツを2週間待ってから削除し、zurg がまだ積極的に修復しているコンテンツを削除してしまいます。

ここには、コードで確認したこと、実際のライブラリで確認したこと、提案する内容、そして意図的に変更しないことを記録しています。以下で事実として書かれていることはすべて、2026-08-16 に動作中のシステムで確認したものです。名前から推測したものではありません。

対象範囲: `internal/plexsweep`、`internal/plexdb`、そして `internal/torrent` への新しい読み取り専用クエリです。修復の動作そのものは変更しません。

---

## 1. 背景 ― 何がリリースされ、なぜ見直しが必要か {#1-background--what-shipped-and-why-it-needs-revisiting}

| コミット | 内容 |
|---|---|
| `4737b677` | Plex の `autoEmptyTrash` が有効なときに警告を出す |
| `020042a3` | スイーパー本体：検出、ガード、修復、アイテム単位の削除 |
| `51cc9f69` | ダッシュボードの設定 UI とドキュメント |
| `1a481a8f` | 修復も上限にカウントする（削除だけでなく） |
| `c6f41621` | `plex_trash_sweep_min_age_days` を追加（デフォルトは 14） |

スイープの大原則は変わらず、このままです：**まだファイルが残っているものは、絶対に削除しない。**
ファイルが有効なアイテムは修復するか、ゴミ箱アイコン付きのまま放置します。有効なエピソードがあるシリーズやシーズンには、一切手を付けません。削除はアイテム単位で行い、Plex のセクション全体を対象にする `emptyTrash` は使いません。

見直しているのは、*本当に存在しないエントリをいつ削除してよいか*というルールだけです。

### タイマーはzurgが直接答えられる問いの代わりにすぎない {#the-timer-is-a-proxy-for-a-question-zurg-can-answer-directly}

`plex_trash_sweep_min_age_days` は、エントリを削除する前に 14 日待ちます。その理由は、赤いゴミ箱アイコンが、コンテンツが消えたことを運用者に知らせる唯一の通知だからです。エントリを消してしまうと、その通知も一緒に消えてしまいます。

考え方自体は正しいのですが、仕組みは当て推量になっています。そのため、両方向で間違っています。

- `infringing torrent` とマークされたトレントは、**すぐに使えないと分かっています**。Plex のエントリを 2 週間残しても誰の役にも立ちません。待っても元に戻ることはないからです。
- まだ再試行中のトレントは、戻ってくるまでに **14 日より長く** かかることがあります。その場合、zurg がまだ作業中なのに、タイマーがエントリを削除してしまいます。これはより深刻な間違いです。ライブラリのエントリを消してしまい、そのコンテンツが後で戻ってくるからです。

---

## 2. 検証済みの事実 {#2-verified-facts}

### 2.1 zurgの状態モデル {#21-zurgs-state-model}

`internal/torrent` 内（テストを除く）を数えると、ファイルの状態は3つ、torrent の状態は2つあります:

| レベル | 状態 |
|---|---|
| `File.State` | `ok_file`, `broken_file`, `deleted_file` |
| `Torrent.State` | `ok_torrent`, `broken_torrent` |

どちらも `pkg/fsm` で作られた状態機械です。`FSMWithTime` は各遷移の unix タイムスタンプを記録し、`SinceWhen` にも対応しています。そのため「どれくらい壊れたままか」は、何も追加しなくても既に答えられます。

**壊れたファイルが1つあると、torrent 全体が不良扱いになります。**
`MarkFileBrokenAndEnqueueRepair`（`internal/torrent/hooks.go:215-234`）:

```go
changed := file.State.Set("broken_file", torrent.State.GetMutex()) == nil
...
if err := torrent.State.Set("broken_torrent"); err == nil {
    t.repairLog.Infof("Torrent state changed: %s [? -> broken_torrent] (has broken file)", ...)
}
```

ログには *"has broken file"* と単数形で出ます。10個中1個が壊れている場合も、10個すべてが壊れている場合も、torrent の状態は同じになります。ファイルの状態をまとめる仕組みはありません。

**`Unfixable` はファイルではなく、アカウントごとに集計します。**
`markAsUnrepairable`（`internal/torrent/unplayable_unrepairable.go:44-71`）:

```go
if cp != nil {
    cp.SetUnrepairableReasonIfEmpty(reason)      // one account's copy
    entryCondemned = t.repairableCopy(torrent) == nil
}
if entryCondemned {
    torrent.SetUnrepairableReasonIfEmpty(reason) // the entry
}
```

エントリは、**修復可能なコピーが1つも残っていない**場合に不良扱いになります。「すべてのコピーに理由がある」という条件にはあえてしていません。もともと修復できないコピー（Usenet バックエンドには magnet adder がありません）があると、死んだリリースが永遠に修復対象に残ってしまうからです。`File` には修復不可のフィールドが一切ありません（`internal/torrent/file_types.go`）。

つまり、3つのレベルはそれぞれ違う質問に答えていて、**どれも影響範囲には答えられません**:

| レベル | 分かること | 分からないこと |
|---|---|---|
| `File.State` | このファイルが ok / broken / deleted のどれか | 完全に死んでいるかどうか |
| `TorrentCopy.UnrepairableReason` | このアカウントのコピーが死んでいるかどうか | 他のアカウントについては何も分からない |
| `Torrent.UnrepairableReason` | どのアカウントでも修復できないかどうか | リリースのどれくらいが影響を受けているか |

### 2.2 実測値(本番ライブラリ、2026-08-16) {#22-live-measurements-a-production-library-2026-08-16}

共有した数値は、壊れた torrent の分です。ライブラリ全体の **3%** にあたります。

**壊れたものの、ほぼすべて（98%）には `Unfixable` の理由が付いています**:

| Reason | 壊れたものの割合 |
|---|---|
| stalled download | 38% |
| infringing torrent | 37% |
| repair failed | 15% |
| duplicate file IDs (pack torrent) | 4% |
| rar'ed by RD | 1% |
| repair failed, no seeders | 1% |
| the lone cached file is broken | under 1% |
| invalid file ids | under 1% |
| repair failed, download status: error | under 1% |
| provider cannot re-add torrents | under 1% |

**残りの 2% には理由がありません。ただ、まだ修復できる可能性があります。**

**ただし、`Unfixable` は「完全に終わった」という意味ではありません。** zurg はこれらの理由を、もう二度と直らないものと、回復できるものに既に分けています（`internal/torrent/unrepairable_reasons.go:44-70`）。`permanentReasons` には、何度リトライしても変わらない 8 つの判定が入っています。infringing、unsupported、unavailable、invalid、too big、not allowed、no repairable files、invalid file ids です。それに加えて、`repair failed, download status:` で始まる理由もすべて含まれます。それ以外は、上で一番多い 2 つを含めて、明示的に一時的なものとして扱われます。`stalled download`、`repair failed`、`duplicate file IDs`、`rar'ed by RD`、`not cached`、`the lone cached file is broken`、`full torrent repair failed` がそうです。

`repair failed, no seeders` は、上の数値を取った時点では 9 番目の理由でした。ここに残っているエントリがこの理由を持っているのは、もうそうではなくなった理由があるからです。zurg が扱えるどのバックエンドも seeders を報告しないため、この判定は一度も実測されていませんでした。修復が時間切れになったことから推測されていただけです。今では一時的な扱いになり、さらに記録もできません（`verdictClaims`）。そのため、このエントリは消えて、ほかと同じように再試行されます。

上の数値にこの分類を当てはめると、次のようになります。

| | 壊れたものの割合 |
|---|---|
| Permanently unrepairable（完全に修復不能） | **39%** |
| Unrepairable but recoverable（修復不能だが回復の可能性あり） | **59%** |
| Broken, no reason yet（壊れているが理由はまだない） | 2% |

どの一覧にも入らない理由が 1 つだけあります（`provider cannot re-add torrents`、ここでは 1 件）。この理由は `IsPermanentlyUnrepairable` が false を返します。慎重な答えで、これこそ私たちが望む挙動です。

これは設計にとって最も重要な発見です。**「`Unfixable` が設定されているか」を基準にしたルールは、実際に死んでいるリリースの 2.5 倍もの数の Plex エントリを削除してしまいます。**

決定的なのは、壊れた torrent がマウントに対してどこにあるかです。

| | 壊れたものの割合 | Plex から見えるもの |
|---|---|---|
| 壊れていて、**まだマウント上にある** | 約 4 分の 3 | ファイルは存在しているように見える → tombstone 化されない。trash icon は出ず、再生時にだけ失敗する |
| 壊れていて、**マウントから消えた** | 約 4 分の 1 | ファイルが見つからない → tombstone 化される → **これらがスイープの対象です** |

これが重要な計測結果です。つまり、スイープが出会うのは 2 つ目のグループだけで、そのグループについては zurg がたいてい既に判定を持っている、ということです。

Plex 側（同じホスト）には、ゴミ箱に入った leaves が溜まっています。ただし、14 日間の期間をすぎたものは **1 件もありません**（一番古い tombstone は 2026-08-11）。あわせて、空のシリーズ shell が少数と、空のシーズン shell が数十件あります。

---

## 3. ギャップ {#3-the-gap}

`broken_torrent` は「何か一つでも壊れている」という意味です。掃除（sweep）で扱うには粒度が違いすぎます。

具体的に言うと、10話入りのパックのうち1話のファイルが完全に消えてしまったのに、パック全体はまだ修復可能な場合です。その torrent に問い合わせると「まだ修復可能」と返るので、sweep はその壊れた1話の Plex エントリーを **永遠に** 残してしまいます。

「この release 全体が死んでいる」という状態と、「release 内のどこかが壊れている」という状態を区別する状態は存在しません。

---

## 4. 設計 {#4-design}

### 4.1 永続化する状態を4つ目に増やさない {#41-do-not-add-a-fourth-persisted-state}

一番わかりやすいのは、新しいtorrentの状態を追加することです。`dead_torrent` などですね。**却下です。**

torrentの状態を変えるすべての箇所で、この状態を管理しなければなりません。そして古い「すべてのファイルが壊れている」フラグは、フラグが無いより悪いです。*削除を許可してしまう*からです。情報はファイルの状態として、すでに存在しています。ただ、集約されていないだけです。

代わりに、そこから導き出します:

```go
// AllFilesBroken reports whether nothing in this release still reads.
// Derived from the file states rather than stored, so it cannot go stale
// and needs no migration or new transitions.
func (t *Torrent) AllFilesBroken() bool
```

コストが低く、常に整合性が保たれ、保存しなくてもダッシュボードに表示できます。

実装中に決めておく定義があります。`deleted_file` は `broken_file` と同じく「読めていない」扱いにしてください。また、ファイルが**0個**のtorrentは、空真として true を返すのではなく false を返す必要があります。空のリリースは死んでいる証拠にはならないからです。

### 4.2 ファイルに尋ね、ダメならトレントに戻る {#42-ask-the-file-fall-back-to-the-torrent}

スイープは Plex のパスを zurg のファイルに対応づけてから、次のように処理します。

| zurg の判定 | スイープ |
|---|---|
| ファイルが `ok_file` | **保持** — 実際には消えていません |
| `broken_file` で、torrent に修復不能の理由がない | **保持** — 修復で戻るかもしれません。どれだけ時間がかかっても |
| `broken_file` で、理由はあるが**永続的ではない** | **保持** — zurg はまだ回復可能だと見ています |
| `broken_file` で、理由が**永続的に**修復不能 | **削除** — 何度再試行しても、この判定は変わりません |
| zurg にこのパスの torrent がない | **年齢の期間にフォールバック** |

永続性の判定には `IsPermanentlyUnrepairable(reason)`（`internal/torrent/unrepairable_reasons.go:59`）を使います。`ForceRepairTorrent` で使われているのと同じ方法です。リストを作り直さず既存の関数を再利用することが大切です。後から `permanentReasons` に理由を追加すれば、スイープの動作も自動的に変わります。認識されない理由は永続的とは見なされず、非永続のままになります。

`AllFilesBroken()` だけでは削除の根拠になりません。理由が回復可能なまま全体が壊れたリリースは、今も対応中です。この関数はレポートとダッシュボードの表示を整理するためのもので、ログを読む人が「10 話のうち 1 話が消えた」のか「パック全体が消えた」のかを区別できるようにします。

最後の行が `plex_trash_sweep_min_age_days` を残す理由です。torrent がアカウントから完全になくなると、その `.zurgtorrent` も一緒に消えます。そうなると zurg にはもう判断材料がありません。タイマーはもはや主要なルールではなく、他に手段がない場合だけ使うフォールバックになります。

これにより、UI 上でもこの設定の位置づけが下がります。「Keep Broken Entries Visible」というラベルは、アクションではなく副作用を説明していたため、その不満もこれで解消されます。

### 4.3 パス → トレント → ファイルのルックアップ {#43-path--torrent--file-lookup}

既存の Plex マッチャーは *逆向き* に動きます。`buildPlexDirIndex`（`internal/plex/matcher.go:539`）は Plex のパスの各要素をインデックスにして、torrent のキーで検索します。スイープ処理には逆の仕組みが必要で、同じ考え方で次のように作ります。

1. `DirectoryMap.Get(INT_ALL)` から `map[strings.ToLower(GetKey(torrent))] *Torrent` を作ります。
2. Plex のパスを、`splitPathComponents`（`matcher.go:525`）と同じ正規化ルールで要素に分割し、それぞれを検索します。ヒットしたものがリリースのディレクトリです。
3. その torrent の中で、残りのパスの末尾を `File.Path`（`internal/debrid/types.go:133`）と照合して、目的のファイルを特定します。

この処理は `TorrentManager` を通す必要があり、`data/*.zurgtorrent` を文字列でマッチさせるのはダメです。理由は、区別用の接尾辞が付いた名前（`Some.Release {a1b2c3}`）、複数アカウントのコピー、名前変更の3つを正しく扱えるのは `GetKey` だけだからです。

**検索に失敗しても削除してはいけません。** 解決できなかった場合は「zurg は判断しない」と扱い、経過時間のウィンドウによるフォールバックに任せてください。

### 4.4 変更しない部分 {#44-what-does-not-change}

- 不変条件：ライブのファイルがあるものは、何も削除されません。
- 配下にライブのものがある Show や Season には、決して手を付けません。
- 削除はアイテムごとに `DELETE` で行い、`emptyTrash` は使いません。
- ガード：rclone が管理下で稼働中であること、マウントから読み取れること、Plex がスキャン中でないこと。
- 変更の前にスナップショットを取ります。上限は修復と削除の両方にかかります。

新しいルールは、スイープをより慎重に、またはより正確にするだけです。現在のコードが拒否する削除を許可することは決してありません。

---

## 5. 実装計画 {#5-implementation-plan}

| # | Step | Files |
|---|---|---|
| 0 | 何かを削除する前に、ライブのライブラリに対してドライラン件数を取り、永久削除と復元可能の振り分けがこの判定条件で正しいか確認する | — |
| 1 | `AllFilesBroken()` と単体テストを追加する（空のリリース、混在、すべて壊れている、すべて削除済み） | `internal/torrent/` |
| 2 | 読み取り専用の状態照会を追加する：パス → torrent → ファイル の順にたどり、小さな判定値を返す | `internal/torrent/` または `internal/plexsweep/` の新しいファイル |
| 3 | 判定の型（`StatusOK`、`StatusRecoverable`、`StatusPermanentlyDead`、`StatusUnknown`）を定義し、sweep が zurg の内部を直接扱わないようにする | `internal/plexsweep` |
| 4 | `Mount`/`Library`/`Trash` と同じように、照会を interface 経由で `Sweeper` に組み込む | `internal/plexsweep/sweep.go` |
| 5 | 判定表を適用する。経過日数の範囲は `StatusUnknown` の場合のフォールバックとして残す | `internal/plexsweep/sweep.go` |
| 6 | 呼び出し元で `TorrentManager` を注入する | `internal/app.go` |
| 7 | テスト：判定表の行ごとに1つずつ用意し、さらに照会の失敗テストで、解決できない場合は絶対に削除されないことを確認する | `internal/plexsweep/sweep_test.go` |
| 8 | ドキュメント：`docs/config.md`、`config.example.yml`、`docs/CHANGELOG.md` を更新し、ダッシュボードのラベルの文言も直す | ドキュメントとテンプレート |

順序の注意：ステップ 1〜3 は動作を変えない追加だけなので、1 つのコミットにまとめて入れて構いません。削除対象が実際に変わるのはステップ 5 だけです。

## 6. リスクと未解決の問題 {#6-risks-and-open-questions}

1. **配線の順序。** 確認しました: `startPlexTrashSweep` は `internal/app.go:268` で呼ばれていますが、`TorrentManager` は `internal/app.go:285` で作られていて、それより後です。呼び出しを後ろに移すか、setter を使う必要があります。現在の位置に依存しているものが他にないかも確認が必要です。

2. **検索の曖昧さ。** 同じパスの要素と衝突するキーを持つ torrent が二つあるケースです。解決策: 候補が一つより多くマッチしたら、どちらかを選ぶのではなく `StatusUnknown` として扱います。

3. **`only_show_the_biggest_file`。** movies ディレクトリはファイルを隠すので、Plex のパスは zurg が配信するファイルとは別のファイルを指しているかもしれません。検索では、Plex のファイル名が `File.Path` にそのまま含まれていると決めつけてはいけません。

4. **コスト。** sweep ごとにキーのインデックスを作ると、コストは O(ライブラリ) になります。数千 torrent なら問題ないですし、sweep は毎日一回しか走りません。インデックスは item ごとではなく、sweep ごとに作りましょう。

5. ~~**`Unfixable` は元に戻るの?**~~ **解決済み: 戻ります。** `refresh.go:851-857` で、torrent が問題なく検証されて `ok_torrent`（"all links intact, no broken files"）に戻ると、フラグがクリアされます。`repair.go:165-181` でも、repair を強制すると、エントリとすべてのコピーの両方からクリアされます。つまり、復旧したリリースに古い「壊れている」判定が残ることはないので、この設計でそれに備える必要はありません。

6. **壊れているけど存在する torrent。** ここではスコープ外です。Plex はそれらを tombstone にしないので、sweep からは見えません。この機能からも、再生が失敗するまでは見えないままだという点は覚えておく価値があります。

## 7. 実装の経緯(2026-08-16) {#7-how-it-was-implemented-2026-08-16}

`feat: decide plex trash sweep removals from zurg's repair verdicts` として取り込まれました。実装が、このドキュメントで未決のままだった問題に結論を出した場合や、§4 から外れた場合は、その決定と理由を以下に示します:

- **検索は、パスの親ディレクトリと `DirectoryMap[INT_ALL]` を完全一致で照合します。** パスの各要素を順に調べる方式 (§4.3) はやめました。マウントはリリースをフラットに配置します (`<library dir>/<key>/<visible name>`)。Plex もマウントからパスを記録しており、そのパスはキーをそのまま使います。完全一致しなかった場合は不明と返します。完全一致のキー同士は衝突しないので、キーの衝突による曖昧さ (リスク 2) はなくなります。
- **判定表の 1 行目を変更しました。** `ok_file` なのにマウントに存在しないファイルは、フィルターで隠れているだけです。「実際には消えていない」わけではありません。これを永久に残すと、フィルター変更後もゴミ箱アイコンが消えなくなります。そのため、代わりに経過日数の窓による判定に任せます。
- **`deleted_file` も `broken_file` と同じ扱いにしました。** `AllFilesBroken()` だけでなく、すべてのルールで対象です。判定表の各行は「`ok_file` ではない」と読むべきものだからです。
- **複数バージョンのアイテムは一つの単位として判定します** (判定表はファイル単位でしたが、スイープの単位は部品を持つ Plex のアイテムです)。復旧可能な部品が一つでもあれば、アイテム全体を残します。アイテムが死んでいると判定されるのは、すべての部品が死んでいる場合だけです。それ以外の組み合わせは、経過日数の窓による判定に任せます。
- **ファイル名がファイルではなく torrent に解決される場合** (リネーム、アーカイブの一覧、`only_show_the_biggest_file` — リスク 3) は、エントリーの理由が恒久的 **かつ** `AllFilesBroken()` のときだけ死亡扱いです。torrent が壊れているが恒久的な判定ではない場合は復旧可能です。それ以外は不明です。読めるファイルが一つでも残っている間は、一致しなかった名前を関連付けだけで死亡扱いにすることはありません。
- **接続 (リスク 1):** `startPlexTrashSweep` を `internal/app.go` の中で、マネージャーの生成より後ろに移しました。以前の位置に依存しているものはありませんでした。判定は `plexsweep.Verdicts` の裏側でスイープに渡します。実装は `TorrentManager.FileStatusForMountPath` です。最初のリフレッシュで `INT_ALL` が埋まるまでは、すべての検索が不明を返します。その間、スイープは経過日数の窓による旧バージョンとまったく同じ動きをします。

## 8. 対象外であることを明示する項目 {#8-explicitly-out-of-scope}

- **空のシリーズとシーズンの残骸。** スイープはリーフ（個々のエピソードやファイル）だけを削除するため、全部壊れているシリーズは殻だけ残ります（測定したライブラリでは数シリーズと数十シーズン）。これは別の問題で、順番に気をつける必要があります。リーフを削除し、親を再確認して、子がゼロになったときだけ削除します。
- 修復の動作、修復キュー、zurg がいつ何かを修復不可能とマークするかに関する変更すべて。
- Plex 自身の `autoEmptyTrash`。これは `4737b677` の警告ですでに対応済みです。
- 測定したライブラリに既にたまっているバックログ。これは意図的に手動で判断するために残しています。
