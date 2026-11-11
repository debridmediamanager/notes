# ディレクトリ設定 UI/UX 評価 {#directory-configuration-uiux-assessment}

## 範囲と現状 {#scope-and-current-state}
- Page: `Directory Configuration` at `http://localhost:9999/directories/`.
- Current UI: 見出し「MEDIA」と「RECENT」の下に、ディレクトリ名、数値の順序、アクションリンク（「Edit」「Delete」）の列を持つ、ひとつのフラットな表でディレクトリを一覧表示します。
- Behavior: Edit と Delete は、どちらもシンプルな操作を実行するだけです。見出し以外のグループ分けはなく、完全な YAML オプションを扱う専用の作成・編集画面もありません。

## 主な UX の課題 {#key-ux-gaps}
- **Informationsarchitektur**
  - Gruppen sind optisch zusammengeschoben; Nutzer können sich nicht auf eine Gruppe konzentrieren.
  - Die Reihenfolge hängt von manuellen Zahlen ab (`group_order`). Das ist unintuitiv und fehleranfällig.
  - Keine Such- oder Filterleiste, um Verzeichnisse schnell zu finden.
  - Keine Massenaktionen (löschen/verschieben) und keine Auswahlmöglichkeiten.
- **Erstellen und Bearbeiten**
  - Die Bearbeiten- und Hinzufügen-Abläufe zeigen nicht das komplette YAML-Schema (allgemeine Einstellungen, Größen-, Datei-, Tag- und Zeitfilter).
  - Kein strukturiertes Layout; Felder sind nicht gruppiert, was bei wachsender Optionsanzahl zu einer Überlastung führt.
  - Kein verschachtelter UND/ODER-Regeleditor, der die verschachtelte Filterlogik von YAML abbildet.
  - Tag-Felder (`tags_match_all`, `tags_match_any`) sind schlecht auffindbar und bieten kaum Hilfe bei der Auswahl.
  - Keine Live-Vorschau der Torrents, die zu den aktuellen Filtereinstellungen passen.
- **Hilfe und Validierung**
  - Fehlende Tooltips/Info-Symbole pro Feld und Links zu ausführlicheren Dokumenten (z. B. `tags.md`).
  - Keine frühzeitige Warnung, wenn ein Verzeichnis keine Torrents liefern würde oder erforderliche Filter fehlen.
  - Regex- und andere Mustervorgaben liefern keine Echtzeit-Rückmeldung zur Gültigkeit.
  - Löschvorgänge erfolgen ohne Bestätigung oder Rückgängig-Option.
- **Barrierefreiheit und Responsivität**
  - Kontrast und Lesbarkeit sind nicht gegen WCAG geprüft; Aktionen, die nur aus Symbolen bestehen, haben womöglich keine Beschriftung.
  - Kein Drag-and-drop; keine tastaturbedienbare Möglichkeit zum Umsortieren.
  - Das mobile Layout ist nicht optimiert (die Tabelle passt sich nicht an gestapelte Karten an; Formulare lassen sich eventuell schlecht scrollen).
  - Aktionen sind nur als Textlinks umgesetzt; Symbole und klare Klickflächen fehlen.
- **Performance und Feinschliff bei der Interaktion**
  - Suche und Filter (sobald sie da sind) brauchen Debouncing sowie Paginierung oder Virtualisierung für große Listen.
  - Drag-and-drop (sobald es da ist) braucht Persistenz und eine saubere Rückfalloption, falls das Speichern fehlschlägt.

## 推奨する UI/UX の変更 {#recommended-uiux-changes}
- **グループ表示**
  - 最上位の各 `group`（例: media/recent/example）を、独自のリストを持つカードまたは折りたたみセクションとして表示します。
  - グループごとにクイック操作を用意します（折りたたみ/展開、一括選択）。
- **並び順**
  - 数値の順序列をドラッグハンドルに置き換え、グループ内で並べ替えできるようにします。計算された順序はツールチップかインラインのバッジで表示します。
  - アクセシビリティとモバイル向けの代替手段として、キーボードで操作しやすい並べ替えコントロール（上/下に移動するボタン）を用意します。
- **検索と一括操作**
  - リストの上に検索/フィルターバーを追加します。入力にはデバウンスをかけます。
  - 一括削除/移動用のチェックボックスを追加します。「select all in group」のアフォーダンスも含めます。
- **追加/編集の画面**
  - モーダルまたはサイドパネルを使い、General、Size Filters、File Filters、Tag Filters、Time Filters、Advanced のセクションに分けたレイアウトにします。
  - 折りたたみ可能なサブセクションを追加して、情報の多さによる負担を減らします。展開状態はセッション中保持します。
- **ルールビルダー**
  - YAML の構造を反映したビジュアルな AND/OR ビルダーを用意します。ネストされたグループ、条件のピル、プロパティ/演算子/値のセレクター（例: has_episodes、matches/does not match を使う正規表現）を含みます。
  - 各ノードで AND と OR を切り替えられるようにし、結果の式をプレビューとして表示します。
- **タグセレクター**
  - 利用可能なタグから候補を出すオートコンプリート付きの複数選択にします。タグの説明はツールチップで、件数も分かる場合は表示します。
  - `tags_match_all` と `tags_match_any` の違いが一目で分かるようにします。
- **プレビュー**
  - 「Preview matching torrents」を追加し、現在のフィルター状態に一致するサンプル結果を取得できるようにします。読み込み中はスケルトン表示にし、エラー処理も用意します。
- **ガイダンス**
  - 各項目にインラインのツールチップor情報アイコンを付け、必要に応じて詳しいドキュメントへのリンクを置きます（例: [tags.md](../reference/tags.md)）。
  - 文脈に応じたヒントを表示します（例: 「Only show largest file」で、この設定が他に与える影響を説明します）。
- **検証と安全性**
  - 必須のフィルターが空だったり検証に失敗したりした場合は保存をブロックし、インラインでエラーを表示します。
  - クライアント側でリアルタイムに正規表現を検証し、送信時にはサーバー側でも確認して、両者の食い違いを防ぎます。
  - 設定が一致するトルレントを 0 件にしてしまう場合は警告します（プレビューまたはヒューリスティックに基づく）。
  - 削除時は確認ダイアログを表示します。可能であれば短い取り消し用のアンドゥ/スナックバーも提供します（サポートされていればソフト削除）。
- **アクセシビリティとレスポンシブデザイン**
  - 採用したパレットのコントラストを確認し、コントロールにフォーカス状態と ARIA ラベルを用意します。
  - 折りたたみ、ドラッグハンドル、各種操作がキーボードで扱えるようにします。
  - モバイルでは、グループを積み重ねたカードとして表示します。モーダルやパネルはスクロール可能にし、操作ボタンは固定ヘッダーに置きます。
  - 主要な操作にはアイコンとラベルを組み合わせます。アイコンだけのターゲットには、アクセシブルな名前を付けます。
- **見た目の仕上げ**
  - 編集・削除・並べ替えのアイコンは統一します。グループの文脈や状態を示すために、控えめな区切り線とチップを使います。
  - グループごとに色分けして、ひと目で把握しやすくします（アクセシブルなコントラストを保ちます）。

## 依存関係と確認が必要な前提 {#dependencies-and-assumptions-to-confirm}
- API対応: グループの並び順の保存、一括操作、ネストされたAND/ORのシリアライズ、タグのメタデータソース、プレビュー用クエリエンドポイント。
- 削除の動作: ソフト削除とハード削除、元に戻せる時間枠、監査の要件。
- 所有権と権限のモデル(複数ユーザー対応の場合): 最終編集者のメタデータ表示と、競合の防止のため。
- プレビュー・検索のパフォーマンス制約: 大規模データセットに対するページング、または仮想化の方針。

## 実装の優先順位 {#implementation-priorities}
1) リストをグループ分けしたカード/折りたたみ式に再構成し、検索・絞り込みバーと確認ダイアログを追加する。
2) セクション分けした追加/編集モーダルまたはサイドパネルを導入し、ツールチップと基本的な検証を加える。あわせてタグの複数選択を追加する。
3) ドラッグ&ドロップとキーボードでの並べ替えを追加し、順序を保存されるようにする。AND/OR ルールビルダーも実装する。
4) デバウンス付きリクエストとエラー処理で、一致するトレントをプレビューする機能を追加する。
5) アクセシビリティ(キーボード操作の経路、ARIA)を仕上げ、モバイル向けにカードを縦に積み重ねるレスポンシブレイアウトに対応する。
