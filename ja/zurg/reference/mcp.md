# MCPエンドポイント {#the-mcp-endpoint}

zurg は [モデルコンテキストプロトコル](https://modelcontextprotocol.io) を使って AI エージェントに応答できます。
クライアントが使えるツールの一覧を尋ねると、zurg がそれぞれを説明し、エージェントがそのツールを呼び出します。
ライブラリを読んだり、リリースが再生されない理由を調べたり、修復したり、メディアサーバーを操作したりできます。
ダッシュボードや CLI で使えるのと同じ操作を、HTML や 303 リダイレクトではなく、スキーマ付きの型付きツールとして提供します。

このエンドポイントはデフォルトでは無効です。ダッシュボードと同じベーシック認証で保護されています。ユーザー名が設定されていない場合、zurg はこのエンドポイントを一切提供しません。ユーザー名が空だと、サーバー上のすべてのルートが公開状態になってしまい、しかもこれらのツールはリリースを削除できるためです。

## 設定 {#configuration}

```yaml
mcp:
  enabled: true
```

通常のインストールであれば、これで全部です。残りの項目にはデフォルト値があるので、知っておくと便利です:

```yaml
mcp:
  enabled: true
  toolsets: [library, releases, repair]   # the default; see below
  read_only: false                        # withhold every tool that changes anything
  allow_unauthenticated: false            # serve /mcp with no username set
  allow_lifecycle: false                  # admit the tools that stop zurg or its mount
  page_limit: 50                          # items a listing returns by default; 500 is the cap
  max_result_kb: 256                      # ceiling on one result; a page over it is trimmed
  session_timeout_mins: 30                # -1 keeps sessions for the life of the process
```

他の機能のブロックと同様に、これは起動時に一度だけ読み込まれます。変更するには再起動が必要です。

## 接続 {#connecting}

### HTTP経由 {#over-http}

エンドポイントは zurg の通常のポート上の `/mcp` で、Streamable HTTP で通信します。クライアントを `http://<host>:9999/mcp` に向けて、ダッシュボードの認証情報を入力してください。

```bash
npx @modelcontextprotocol/inspector
# Transport:  Streamable HTTP
# URL:        http://localhost:9999/mcp
# Header:     Authorization: Basic <base64 of user:password>
```

### stdio経由 {#over-stdio}

stdio しか話せないクライアントは、`zurg mcp` サブコマンドを使います。これは起動中のインスタンスへブリッジしてくれます:

```json
{
  "mcpServers": {
    "zurg": {
      "command": "/path/to/zurg",
      "args": ["mcp"],
      "cwd": "/path/to/your/zurg/directory"
    }
  }
}
```

`cwd` が重要です。zurg のパスはすべて作業ディレクトリを基準に解決されます。また `zurg mcp` は、ポートと認証情報を取得するために、その作業ディレクトリの `config.yml` を読みます。

これらがそろっていれば、引数は不要です。`--username` と `--password` を指定すると、ローカルの認証情報より優先されます。

カスタムの `--url` は、ローカルの設定から認証情報を引き継ぐことは決してありません。そのエンドポイントで認証が必要な場合は、両方の認証フラグを明示的に指定してください。そうすれば、ローカルのパスワードがうっかり別のホストへ送られる心配がありません。

これは2つ目のインスタンスを起動しません。2つ目の zurg を立ち上げると、ライブラリ全体を読み込み、従量課金のアカウントに対してプロバイダーの枠をもう一組使い、マウントを最初のインスタンスと取り合うことになってしまいます。なので、このコマンドはデーモンへのパイプにすぎず、デーモンが起動していないときは何も提供しません。

診断メッセージは stderr に出力されます。stdout はプロトコルのやり取りに使われるからです。

制限が一つあります。サーバーが呼び出しの外で発生させた通知は、ブリッジを越えて届きません。呼び出し*中*に発生した進捗やログの行は、その呼び出し自身のレスポンスに乗って通常どおり届きます。zurg が送るものはすべてこれでカバーされています。

## ツールセット {#toolsets}

zurg の全機能は数百のツールに及びますが、クライアントがうまく扱える量を超えています。およそ80を超えると、モデルは誤ったツールを選ぶことが増え、スキーマだけで数万トークンもかかってしまいます。そのため `toolsets` ではグループを選択でき、デフォルトではすべてではなく、実用的なサブセットが有効になります。

| ツールセット | デフォルトで有効 | 対象範囲 |
|---|:-:|---|
| `library` | はい | 検索、ディレクトリ一覧、タグ数 |
| `releases` | はい | 1つのリリースの詳細: ファイル、アカウントごとのコピー、各ファイルを配信できるもの |
| `repair` | はい | 壊れているもの、修復が対象にするか、修復の強制実行 |
| `releases_write` | | 削除、名前変更、タグ付け、強制表示、`.strm` ファイルの書き込み |
| `magic` | | `__magic__` 名前空間: 保存されたレイアウト、その行、ものの移動 |
| `plex` | | Plex、Jellyfin、Emby: ステータス、マッチング、ガード付きスキャン |
| `providers` | | 設定済みのアカウント: それぞれができること、到達可能かどうか、使った額 |
| `usenet` | | NZB バックエンド: ニュースアカウント、記事プローブ、破損、記事キャッシュ |
| `clients` | | Sonarr と Radarr が通信する SABnzbd、qBittorrent、Stremio のエンドポイント |
| `diagnostics` | | ログ、バイトカウンター、メモリ、goroutine |
| `config` | | 設定の読み取り、ドリフトの検出、厳選されたキーの書き込み |
| `mount` | | rclone マウント: ステータス、キャッシュ済み一覧の破棄、再起動 |
| `system` | | ビルド情報、`doctor`、サービス、バックアップ、アップデート |

`toolsets: [all]` で全グループを有効にします。名前の前に `-` を付けると除外になります。たとえば `[all, -config, -system]` は、ライブラリではなくマシンを変更する2つを除いた全機能になります。認識されない名前は起動時に警告が出て無視されます。タイプミスでエンドポイントが使えなくなってはいけないためです。

zurg を停止したり、そのサービスを制御したり、マウントを再起動したりするツールは、独自のグループではありません。これらは `system` と `mount` に含まれ、`toolsets` の設定に関係なく、`allow_lifecycle` が設定されるまで非公開のままです。

小さな `server` グループ（このビルドが何か、ライブラリの読み込みが完了したかどうか）は、`toolsets` の設定に関係なく常に登録されます。これを非公開にすると、クライアントは他のすべての回答が現在一部だけであることを知る手段がなくなってしまうためです。

## 頼まれていない限りやらないこと {#what-it-will-not-do-without-being-asked}

**Bestätigung.** Ein Tool, das etwas wegnimmt, beschreibt zuerst, was es tun würde,
und gibt ein Token zurück; es handelt erst, wenn es noch einmal mit diesem Token
aufgerufen wird. Das Token wird aus dem Plan abgeleitet, daher lässt sich eine
Bestätigung nicht auf einen anderen Plan übertragen. Hat sich die Bibliothek in der
Zwischenzeit geändert, beschreibt der zweite Aufruf erneut, statt etwas zu tun.
Tokens können nur einmal verwendet werden, sind zwei Minuten gültig und überstehen
keinen Neustart.

**`read_only`.** Ein einziger Schalter, der alle Tools ausblendet, die etwas
verändern, egal was `toolsets` sagt. Die Frage, die sich ein Betreiber wirklich
stellt, lautet „kann das meine Bibliothek kaputt machen?“ und nicht „welches dieser
Tools schreibt?“. Diese Tools fehlen in `tools/list`, sodass ein Client keine
Funktion auswählen kann, die dieser Endpunkt nie zulassen wird. Die Prüfung beim
Aufruf bleibt als zusätzliche Absicherung bestehen, falls sich die laufende
Einstellung nach dem Start des Servers ändert.

**`allow_lifecycle`.** Die Tools, die zurg stoppen, seinen Dienst steuern oder den
Mount neu starten, werden über einen eigenen Schalter ebenso ausgeblendet. Jedes
davon kann die gesamte Bibliothek auf einen Schlag verschwinden lassen. Außerdem
können die Prozess- und Dienstaktionen ihr eigenes Ergebnis nicht melden, weil sie
den Prozess beenden könnten, der gerade den Aufruf beantwortet.

**Geheimnisse.** Kein Tool-Ergebnis enthält ein Provider-Token, einen API-Key, ein
News-Server-Passwort, einen aufgelösten CDN-Link oder eine signierte `.strm`-URL.
Log-Ausgaben werden beim Verlassen des Systems geschwärzt. Ein aufgelöster Link
kann von jedem eingelöst werden, der ihn hat, und zwar über das Konto, für das er
erzeugt wurde. Ein Transkript ist deshalb kein Ort dafür.

**Größe.** Jede Auflistung ist doppelt begrenzt: durch ein Seitenlimit und durch eine
Obergrenze für das marshallierte Ergebnis. Ein Konto, das wir dagegen gemessen
haben, hat 84.000 Releases, was etwa zwölf Megabyte an Namen ergibt, noch bevor
eine einzige Datei aufgelistet wird. Ein Ergebnis über der Obergrenze wird
gekürzt, und das wird auch angegeben.

## ノート {#notes}

このエンドポイントは、ダッシュボードの内側に登録されているため、ダッシュボードのベーシック認証をそのまま引き継ぎます。
クロスオリジンのリクエストは拒否されます。`/mcp` はウェブページ用ではなく、ローカルのエージェント用です。
zurg の前段にリバースプロキシを置いても動作します。プロキシが自分の `Host` を転送しながら `127.0.0.1` に接続する場合、プロトコルライブラリの DNS リバインディング対策のチェックでプロキシが弾かれてしまいます。そのため zurg はこのチェックをオフにし、アクセス制御はベーシック認証に任せています。

`zurg mcp --help` で、ブリッジのフラグを一覧できます。`zurg doctor` では、エンドポイントが応答しているかどうかを確認できます。
