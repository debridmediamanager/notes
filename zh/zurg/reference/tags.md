# zurg 标签文档 {#zurg-tags-documentation}

这份文档介绍了 zurg 中可以自动应用到种子上的所有标签。

## 分辨率标签 {#resolution-tags}

分辨率标签会根据视频尺寸添加，并允许 5% 的误差：只要流的宽度和高度都至少达到所列尺寸的 95%，就会匹配该档位。内嵌图片（封面图、缩略图）会被忽略。只会应用匹配到的最高分辨率标签。

| 标签 | 说明 |
|-----|-------------|
| `zurg_8k` | 分辨率 >= 7680x4320 |
| `zurg_4k` | 分辨率 >= 3840x2160 |
| `zurg_1440p` | 分辨率 >= 2560x1440 |
| `zurg_1080p` | 分辨率 >= 1920x1080 |
| `zurg_720p` | 分辨率 >= 1280x720 |
| `zurg_480p` | 分辨率 >= 720x480 |

## 动态范围标签 {#dynamic-range-tags}

只会根据视频的动态范围特性应用这些标签中的一个：

| 标签 | 说明 |
|-----|-------------|
| `zurg_hdr` | HDR 内容（通过 BT.2020 色彩空间检测） |
| `zurg_dv` | Dolby Vision 内容 |
| `zurg_sdr` | 标准动态范围（SDR）内容（在未检测到 HDR 或 DV 时应用） |

当同时存在 HDR 和 Dolby Vision 元数据时，Dolby Vision 标签优先，不会应用 `zurg_hdr`。

## 视频码率标签 {#video-bitrate-tags}

视频码率标签基于所有已分析文件中找到的最高视频流码率，忽略内嵌图片（封面、缩略图）。只应用最高的匹配档位。

| 标签 | 说明 |
|-----|-------------|
| `zurg_ultra_high_video_bitrate` | 视频码率 ≥ 100 Mbps |
| `zurg_high_video_bitrate` | 视频码率 ≥ 70 Mbps 且 < 100 Mbps |
| `zurg_moderate_video_bitrate` | 视频码率 ≥ 40 Mbps 且 < 70 Mbps |
| `zurg_low_video_bitrate` | 视频码率 ≥ 10 Mbps 且 < 40 Mbps |
| `zurg_very_low_video_bitrate` | 视频码率 ≥ 0 Mbps 且 < 10 Mbps |

## 音频码率标签 {#audio-bitrate-tags}

音频码率标签基于所有音轨中找到的最高音频码率。只应用最高的匹配等级。

| Tag | Description |
|-----|-------------|
| `zurg_ultra_high_audio_bitrate` | 音频码率 ≥ 2000 kbps(例如 DTS-HD MA、TrueHD、LPCM) |
| `zurg_high_audio_bitrate` | 音频码率 ≥ 768 kbps 且 < 2000 kbps(例如 DTS、高码率 AC3) |
| `zurg_moderate_audio_bitrate` | 音频码率 ≥ 384 kbps 且 < 768 kbps(例如标准 AC3、5.1 AAC) |
| `zurg_low_audio_bitrate` | 音频码率 ≥ 128 kbps 且 < 384 kbps(例如立体声 AAC、MP3) |
| `zurg_very_low_audio_bitrate` | 音频码率 ≥ 0 kbps 且 < 128 kbps(例如低质量立体声) |

## 时长标签 {#duration-tags}

持续时间标签基于所有已分析文件中找到的最长时长，包括纯音频文件。只会应用匹配的最高档位。

| 标签 | 说明 |
|-----|-------------|
| `zurg_80minsplus_duration` | 时长 ≥ 80 分钟 |
| `zurg_60to80mins_duration` | 时长 ≥ 60 分钟且 < 80 分钟 |
| `zurg_40to60mins_duration` | 时长 ≥ 40 分钟且 < 60 分钟 |
| `zurg_20to40mins_duration` | 时长 ≥ 20 分钟且 < 40 分钟 |
| `zurg_0to20mins_duration` | 时长 ≥ 0 分钟且 < 20 分钟 |

## 语言标签 {#language-tags}

语言标签会为音频和字幕流中检测到的每种唯一语言分别添加。检测会汇总种子中每一个被分析过的文件，所以整季合集会包含所有集数语言的并集。只有已分析的视频/音频文件内部的流才会被计入，它们旁边单独的 `.srt` 文件永远不会被读取；没有声明语言的流默认为 `und`。

### 音频语言标签 {#audio-language-tags}
- `zurg_aud_[language_code]` - 格式

- `zurg_aud_eng` - 英语音轨
- `zurg_aud_jpn` - 日语音轨

### 字幕语言标签 {#subtitle-language-tags}
- `zurg_sub_[language_code]`

Example:
- `zurg_sub_eng` - 英文字幕
- `zurg_sub_spa` - 西班牙语字幕

## 使用标签进行筛选 {#using-tags-for-filtering}

标签可以在配置文件中使用，把种子过滤到特定目录。共有四种基于列表的标签过滤器，另外还有两种单标签条件：

### 标签筛选类型 {#tag-filter-types}

1. `tags_match_all`: 所有指定的标签都必须存在
   ```yaml
   tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
   ```

2. `tags_match_any`: 至少要存在一个指定的标签
   ```yaml
   tags_match_any: ["zurg_aud_eng", "zurg_sub_eng"]  # Must have either English audio or subtitles
   ```

3. `tags_missing_all`: 如果过滤器中的标签一个都不存在，则返回 true（与 "tags_match_any" 相反）
    ```yaml
    tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng"]  # Must not have English audio or subtitles
    ```

4. `tags_missing_any`: 如果至少缺少一个过滤器中的标签，则返回 true（与 "tags_match_all" 相反）
    ```yaml
    tags_missing_any: ["zurg_4k", "zurg_hdr"]  # Must be missing either 4K or HDR (or both)
    ```

这四个过滤器中的标签名不区分大小写。完全没有标签的种子会无法通过 `tags_match_all` 和 `tags_match_any`，但会通过 `tags_missing_all` 和 `tags_missing_any`。那些从未被分析过的种子最后就是落在后两者里。

这四个键会按上面的顺序检查，第一个出现的键就决定整个过滤块的结果。所以请把每个标签过滤器单独放在 `and:`/`or:` 下面的一个条目里，不要把多个标签过滤器合并到同一个块中。

### 单标签条件 {#single-tag-conditions}

`has_tag` 和 `not_has_tag` 接受的是单个标签名，而不是列表，并且区分大小写。与上面四个过滤器不同，它们不能单独用来选中种子，只能用来排除。如果一个过滤块里只有 `has_tag`，它将什么都匹配不到，所以必须和同一块里的其他条件搭配使用。

```yaml
- has_tag: zurg_4k       # gate: torrent must carry this tag
  regex: /.*/            # and a condition that can match on its own
```

### 目录配置示例 {#example-directory-configuration}

下面是一个在目录配置中使用标签过滤器的示例：

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

## 注意事项 {#notes}

- 标签会根据媒体分析自动应用，这需要 `ffprobe` 可执行文件。只有启用 `auto_analyze_new_torrents` 时，才会对新添加的种子运行分析。仪表盘的分析操作和管理页面中每个种子的媒体信息操作，可以随时手动触发分析。
- 在至少一个文件完成分析之前，不会打任何标签。未分析的种子不会带有 `zurg_sdr`、码率等级或时长等级标签。
- 每次分析运行时，所有 `zurg_*` 标签都会被清除并重新计算。没有这个前缀的标签（用户标签、目录分配）会保留不动。
- 同一个种子可以同时带有多个语言标签。
- 只会应用一个分辨率标签（取最高的匹配项）。
- 只会应用一个动态范围标签。
- 只会应用一个视频码率等级标签（取最高的匹配项）。
- 只会应用一个音频码率等级标签（取最高的匹配项）。
- 只会应用一个时长等级标签（取最高的匹配项）。
- 分辨率检查使用 5% 的容差系数。
- 视频码率以码率最高的流为准，而不是平均值。
- 音频码率以码率最高的流为准，而不是平均值。
- 没有报告码率的流按 0 计算。因此，流中没有任何码率元数据的文件会被归入 `very_low` 等级。
- 时长以种子中分析过的最长文件为准（包括纯音频文件）。
- 标签筛选可以和其他筛选条件组合使用，方便精确地整理内容。
