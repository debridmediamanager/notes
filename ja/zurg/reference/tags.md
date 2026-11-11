# zurg タグのドキュメント {#zurg-tags-documentation}

このドキュメントでは、zurg で torrent に自動的に付与されうるタグをすべて説明します。

## 解像度タグ {#resolution-tags}

解像度タグは、動画の幅と高さを基準に付けられます。許容誤差は5%です。ストリームは、幅と高さの両方が一覧の値の95%以上あれば、その段階に一致します。埋め込み画像(カバーアートやサムネイル)は無視されます。一致した中で最も高い解像度タグだけが付きます。

| タグ | 説明 |
|-----|-------------|
| `zurg_8k` | 解像度 >= 7680x4320 |
| `zurg_4k` | 解像度 >= 3840x2160 |
| `zurg_1440p` | 解像度 >= 2560x1440 |
| `zurg_1080p` | 解像度 >= 1920x1080 |
| `zurg_720p` | 解像度 >= 1280x720 |
| `zurg_480p` | 解像度 >= 720x480 |

## ダイナミックレンジタグ {#dynamic-range-tags}

映像のダイナミックレンジに応じて、付くタグは1つだけです。

| タグ | 説明 |
|-----|-------------|
| `zurg_hdr` | HDR コンテンツ(BT.2020 のカラースペースで検出) |
| `zurg_dv` | Dolby Vision コンテンツ |
| `zurg_sdr` | 標準ダイナミックレンジ(SDR)のコンテンツ(HDR も DV も検出されなかった場合に付与) |

HDR と Dolby Vision のメタデータが両方ある場合は、Dolby Vision のタグが優先され、`zurg_hdr` は付与されません。

## ビデオビットレートタグ {#video-bitrate-tags}

ビデオビットレートのタグは、解析したすべてのファイルの中で見つかった最も高いビデオストリームのビットレートに基づいて付けられます。埋め込み画像(カバーアート、サムネイル)は無視します。一致したなかで最も高い階層のタグだけが適用されます。

| Tag | Description |
|-----|-------------|
| `zurg_ultra_high_video_bitrate` | ビデオビットレート ≥ 100 Mbps |
| `zurg_high_video_bitrate` | ビデオビットレート ≥ 70 Mbps かつ < 100 Mbps |
| `zurg_moderate_video_bitrate` | ビデオビットレート ≥ 40 Mbps かつ < 70 Mbps |
| `zurg_low_video_bitrate` | ビデオビットレート ≥ 10 Mbps かつ < 40 Mbps |
| `zurg_very_low_video_bitrate` | ビデオビットレート ≥ 0 Mbps かつ < 10 Mbps |

## オーディオビットレートタグ {#audio-bitrate-tags}

オーディオのビットレートタグは、すべてのオーディオストリームの中で見つかった最も高いオーディオビットレートに基づきます。一致する中で最も高いティアだけが適用されます。

| タグ | 説明 |
|-----|-------------|
| `zurg_ultra_high_audio_bitrate` | オーディオビットレートが 2000 kbps 以上 (例: DTS-HD MA、TrueHD、LPCM) |
| `zurg_high_audio_bitrate` | オーディオビットレートが 768 kbps 以上かつ 2000 kbps 未満 (例: DTS、高ビットレートの AC3) |
| `zurg_moderate_audio_bitrate` | オーディオビットレートが 384 kbps 以上かつ 768 kbps 未満 (例: 標準的な AC3、5.1 AAC) |
| `zurg_low_audio_bitrate` | オーディオビットレートが 128 kbps 以上かつ 384 kbps 未満 (例: ステレオ AAC、MP3) |
| `zurg_very_low_audio_bitrate` | オーディオビットレートが 0 kbps 以上かつ 128 kbps 未満 (例: 低品質のステレオ) |

## 再生時間タグ {#duration-tags}

Duration タグは、解析したすべてのファイル（音声のみのファイルを含む）の中で最も長い再生時間をもとに付けられます。条件に合う中で最も上の階層のタグだけが適用されます。

| Tag | Description |
|-----|-------------|
| `zurg_80minsplus_duration` | 再生時間が 80 分以上 |
| `zurg_60to80mins_duration` | 再生時間が 60 分以上 80 分未満 |
| `zurg_40to60mins_duration` | 再生時間が 40 分以上 60 分未満 |
| `zurg_20to40mins_duration` | 再生時間が 20 分以上 40 分未満 |
| `zurg_0to20mins_duration` | 再生時間が 0 分以上 20 分未満 |

## 言語タグ {#language-tags}

言語タグは、音声と字幕のストリームで検出された言語ごとに1つずつ付けられます。検出は、トレントに含まれるすべての解析済みファイルを対象に集計されるので、シーズンパックには各エピソードの言語の和集合が入ります。数えられるのは、解析された動画/音声ファイルの中にあるストリームだけです。その横にある単独の `.srt` は読まれません。また、言語が宣言されていないストリームは `und` になります。

### オーディオ言語タグ {#audio-language-tags}
以下の形式:`zurg_aud_[language_code]`

例:
- `zurg_aud_eng` - 英語の音声トラック
- `zurg_aud_jpn` - 日本語の音声トラック

### 字幕言語タグ {#subtitle-language-tags}
形式: `zurg_sub_[language_code]`

例:
- `zurg_sub_eng` - 英語字幕
- `zurg_sub_spa` - スペイン語字幕

## タグを使ったフィルタリング {#using-tags-for-filtering}

設定ファイルでタグを使うと、トレントを特定のディレクトリに振り分けられます。リストベースのタグフィルターは4種類あり、さらに単一タグの条件が2つあります。

### タグフィルタの種類 {#tag-filter-types}

1. `tags_match_all`: 指定したタグがすべて存在している必要があります
   ```yaml
   tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
   ```

2. `tags_match_any`: 指定したタグのうち少なくとも1つが存在している必要があります
   ```yaml
   tags_match_any: ["zurg_aud_eng", "zurg_sub_eng"]  # Must have either English audio or subtitles
   ```

3. `tags_missing_all`: フィルターのタグがどれも存在しない場合に true を返します（"tags_match_any" の逆です）
    ```yaml
    tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng"]  # Must not have English audio or subtitles
    ```

4. `tags_missing_any`: フィルターのタグのうち少なくとも1つが欠けている場合に true を返します（"tags_match_all" の逆です）
    ```yaml
    tags_missing_any: ["zurg_4k", "zurg_hdr"]  # Must be missing either 4K or HDR (or both)
    ```

これら4つのフィルターでは、タグ名の大文字と小文字は区別されずに比較されます。タグが1つもない torrent は `tags_match_all` と `tags_match_any` に失敗し、`tags_missing_all` と `tags_missing_any` には合格します。まだ一度も分析されていない torrent は、このような状態になります。

4つのキーは上から順に確認され、最初に見つかったキーでフィルターブロック全体の動作が決まります。そのため、タグフィルターを1つのブロックにまとめるのではなく、`and:`/`or:` の下にそれぞれ別のエントリーとして書いてください。

### 単一タグの条件 {#single-tag-conditions}

`has_tag` と `not_has_tag` は、リストではなくタグ名を1つだけ受け取ります。大文字と小文字を区別して一致を判定します。上の4つのフィルターと違い、単独で torrent を選ぶことはできず、除外するためにしか使えません。`has_tag` だけを含むフィルターブロックは何にも一致しないので、同じブロック内に別の条件を一緒に書く必要があります。

```yaml
- has_tag: zurg_4k       # gate: torrent must carry this tag
  regex: /.*/            # and a condition that can match on its own
```

### ディレクトリ設定の例 {#example-directory-configuration}

タグフィルターをディレクトリ設定で使う例です：

```yaml
"quality movies":
  filters:
    - and:
      - tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
      - tags_match_any: ["zurg_high_video_bitrate", "zurg_ultra_high_video_bitrate"]  # Must have either high or ultra-high video bitrate
      - tags_match_any: ["zurg_high_audio_bitrate", "zurg_ultra_high_audio_bitrate"]  # Must have either high or ultra-high audio bitrate
      - tags_match_any: ["zurg_60to80mins_duration", "zurg_80minsplus_duration"]  # Must be at least 60 minutes long
      - tags_missing_all: ["zurg_sdr", "zurg_very_low_video_bitrate"]  # Must not have SDR or very low video bitrate
      - tags_missing_any: ["zurg_dv"]  # Must be missing Dolby Vision (prefer HDR10)
```

## ノート {#notes}

- タグはメディア解析に基づいて自動で付けられます。解析には `ffprobe` バイナリが必要で、新しく追加されたトレントに対して自動で実行されるのは `auto_analyze_new_torrents` が有効なときだけです。ダッシュボードの解析アクションや、管理ページのトレントごとのメディア情報アクションを使えば、好きなタイミングで手動で解析できます。
- 少なくとも1つのファイルが解析されるまで、タグは何も付きません。解析されていないトレントには、`zurg_sdr`、ビットレートのティア、長さのティアのどれも付かないということです。
- `zurg_*` のタグは、解析を実行するたびにすべて削除されてから再計算されます。接頭辞のないタグ（ユーザーが付けたタグやディレクトリの割り当て）は残ります。
- 言語タグは、複数同時に付けられます。
- 解像度タグは1つだけ付きます（条件に一致する中で最も高いもの）。
- ダイナミックレンジのタグは1つだけ付きます。
- 映像ビットレートのティアタグは1つだけ付きます（条件に一致する中で最も高いもの）。
- 音声ビットレートのティアタグは1つだけ付きます（条件に一致する中で最も高いもの）。
- 長さのティアタグは1つだけ付きます（条件に一致する中で最も高いもの）。
- 解像度の判定には、5%の許容係数が適用されます。
- 映像ビットレートは、平均ではなく最も高いビットレートのストリームを基準にします。
- 音声ビットレートも、平均ではなく最も高いビットレートのストリームを基準にします。
- ビットレートの情報がないストリームは0として扱われます。そのため、ストリームにビットレートのメタデータがないファイルは `very_low` のティアに入ります。
- 長さは、トレント内で最も長く解析されたファイルを基準にします（音声のみのファイルも含みます）。
- タグのフィルターは、他のフィルターと組み合わせて使えます。これで、コンテンツをより細かく整理できます。
