---
label: Tags
icon: tag
order: 80
---

# Zurg Tags Documentation

This document describes all possible tags that can be automatically applied to torrents in Zurg.

## Resolution Tags

Resolution tags are applied based on video dimensions with a 5% tolerance factor: a stream matches a tier when both its width and height are at least 95% of the listed dimensions. Embedded images (cover art, thumbnails) are ignored. Only the highest matching resolution tag is applied.

| Tag | Description |
|-----|-------------|
| `zurg_8k` | Resolution >= 7680x4320 |
| `zurg_4k` | Resolution >= 3840x2160 |
| `zurg_1440p` | Resolution >= 2560x1440 |
| `zurg_1080p` | Resolution >= 1920x1080 |
| `zurg_720p` | Resolution >= 1280x720 |
| `zurg_480p` | Resolution >= 720x480 |

## Dynamic Range Tags

Only one of these tags is applied based on the video's dynamic range characteristics:

| Tag | Description |
|-----|-------------|
| `zurg_hdr` | HDR content (detected by BT.2020 color space) |
| `zurg_dv` | Dolby Vision content |
| `zurg_sdr` | Standard Dynamic Range content (applied when neither HDR nor DV is detected) |

When both HDR and Dolby Vision metadata are present, the Dolby Vision tag takes priority and `zurg_hdr` is not applied.

## Video Bitrate Tags

Video bitrate tags are based on the highest video stream bitrate found across all analyzed files, ignoring embedded images (cover art, thumbnails). Only the highest matching tier is applied.

| Tag | Description |
|-----|-------------|
| `zurg_ultra_high_video_bitrate` | Video bitrate ≥ 100 Mbps |
| `zurg_high_video_bitrate` | Video bitrate ≥ 70 Mbps and < 100 Mbps |
| `zurg_moderate_video_bitrate` | Video bitrate ≥ 40 Mbps and < 70 Mbps |
| `zurg_low_video_bitrate` | Video bitrate ≥ 10 Mbps and < 40 Mbps |
| `zurg_very_low_video_bitrate` | Video bitrate ≥ 0 Mbps and < 10 Mbps |

## Audio Bitrate Tags

Audio bitrate tags are based on the highest audio bitrate found across all audio streams. Only the highest matching tier is applied.

| Tag | Description |
|-----|-------------|
| `zurg_ultra_high_audio_bitrate` | Audio bitrate ≥ 2000 kbps (e.g., DTS-HD MA, TrueHD, LPCM) |
| `zurg_high_audio_bitrate` | Audio bitrate ≥ 768 kbps and < 2000 kbps (e.g., DTS, high-bitrate AC3) |
| `zurg_moderate_audio_bitrate` | Audio bitrate ≥ 384 kbps and < 768 kbps (e.g., standard AC3, 5.1 AAC) |
| `zurg_low_audio_bitrate` | Audio bitrate ≥ 128 kbps and < 384 kbps (e.g., stereo AAC, MP3) |
| `zurg_very_low_audio_bitrate` | Audio bitrate ≥ 0 kbps and < 128 kbps (e.g., low-quality stereo) |

## Duration Tags

Duration tags are based on the longest duration found across all analyzed files, audio-only files included. Only the highest matching tier is applied.

| Tag | Description |
|-----|-------------|
| `zurg_80minsplus_duration` | Duration ≥ 80 minutes |
| `zurg_60to80mins_duration` | Duration ≥ 60 minutes and < 80 minutes |
| `zurg_40to60mins_duration` | Duration ≥ 40 minutes and < 60 minutes |
| `zurg_20to40mins_duration` | Duration ≥ 20 minutes and < 40 minutes |
| `zurg_0to20mins_duration` | Duration ≥ 0 minutes and < 20 minutes |

## Language Tags

Language tags are applied for each unique language detected in audio and subtitle streams. Detection aggregates every analyzed file in the torrent, so a season pack carries the union of its episodes' languages. Only streams inside analyzed video/audio files count — a standalone `.srt` beside them is never read — and streams without a declared language default to `und`.

### Audio Language Tags
Format: `zurg_aud_[language_code]`

Example:
- `zurg_aud_eng` - English audio track
- `zurg_aud_jpn` - Japanese audio track

### Subtitle Language Tags
Format: `zurg_sub_[language_code]`

Example:
- `zurg_sub_eng` - English subtitles
- `zurg_sub_spa` - Spanish subtitles

## Using Tags for Filtering

Tags can be used in the configuration file to filter torrents into specific directories. There are four list-based tag filters available, plus two single-tag conditions:

### Tag Filter Types

1. `tags_match_all`: All specified tags must be present
   ```yaml
   tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
   ```

2. `tags_match_any`: At least one of the specified tags must be present
   ```yaml
   tags_match_any: ["zurg_aud_eng", "zurg_sub_eng"]  # Must have either English audio or subtitles
   ```

3. `tags_missing_all`: Returns true if none of the filter tags are present (the reverse of "tags_match_any")
    ```yaml
    tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng"]  # Must not have English audio or subtitles
    ```

4. `tags_missing_any`: Returns true if at least one of the filter tags is missing (the reverse of "tags_match_all")
    ```yaml
    tags_missing_any: ["zurg_4k", "zurg_hdr"]  # Must be missing either 4K or HDR (or both)
    ```

Tag names in these four filters are compared case-insensitively. A torrent carrying no tags at all fails `tags_match_all` and `tags_match_any`, and passes `tags_missing_all` and `tags_missing_any` — which is where torrents that have never been analyzed end up.

The four keys are checked in the order above and the first one present decides the whole filter block, so give each tag filter its own entry under `and:`/`or:` instead of combining several in one block.

### Single-Tag Conditions

`has_tag` and `not_has_tag` take one tag name instead of a list, and match case-sensitively. Unlike the four filters above they can only reject a torrent, never select one on their own: a filter block containing nothing but `has_tag` matches nothing, so they must sit alongside another condition in the same block.

```yaml
- has_tag: zurg_4k       # gate: torrent must carry this tag
  regex: /.*/            # and a condition that can match on its own
```

### Example Directory Configuration

Here's an example of how to use tag filters in a directory configuration:

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

## Notes

- Tags are applied automatically based on media analysis, which needs an `ffprobe` binary and runs on newly added torrents only when `auto_analyze_new_torrents` is enabled; the dashboard's analyze action and the per-torrent media info action on the manage page trigger it on demand
- Nothing is tagged until at least one file has been analyzed — an unanalyzed torrent carries no `zurg_sdr`, no bitrate tier and no duration tier
- Every `zurg_*` tag is cleared and recomputed on each analysis run; tags without that prefix (user tags, directory assignments) are preserved
- Multiple language tags can be present simultaneously
- Only one resolution tag is applied (highest matching)
- Only one dynamic range tag is applied
- Only one video bitrate tier tag is applied (highest matching)
- Only one audio bitrate tier tag is applied (highest matching)
- Only one duration tier tag is applied (highest matching)
- A 5% tolerance factor is applied for resolution checks
- Video bitrates are based on the highest bitrate stream (not average)
- Audio bitrates are based on the highest bitrate stream (not average)
- A stream that reports no bitrate counts as 0, so a file whose streams carry no bitrate metadata lands in the `very_low` tier
- Duration is based on the longest analyzed file in the torrent (audio-only files included)
- Tag filters can be combined with other filters for precise content organization
