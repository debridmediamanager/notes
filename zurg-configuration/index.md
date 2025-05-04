---
label: Zurg Configuration
icon: gear
order: 100
---

# Zurg Configuration Guide

This guide provides a comprehensive explanation of all configuration options available in Zurg, along with their use cases and examples. Zurg offers extensive configurability through its `config.yml` file, allowing you to tailor its behavior to your specific needs.

## Core Configuration

### Basic Settings

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `zurg` | Configuration version | `v1` | `zurg: v1` |
| `token` | Your Real-Debrid API token, required for all Real-Debrid API interactions | - | `token: YOUR_RD_API_TOKEN` |
| `strm_link_token` | Alternative RD token for STRM files, useful when you want to use a separate Real-Debrid account for STRM file access | Falls back to main token | `strm_link_token: ALTERNATIVE_TOKEN` |
| `download_tokens` | Additional RD tokens for when daily bandwidth limit is reached, helpful for Plex analysis that requires extensive file access | `[]` | `download_tokens: [TOKEN1, TOKEN2]` |

### Network & Server Configuration

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `host` | Host address to bind to | `[::]` | `host: "[::]"` |
| `port` | Port to listen on | `9999` | `port: 9999` |
| `base_url` | Override scheme and host for URLs, essential when behind a reverse proxy or when needs to generate correct URLs in responses | - | `base_url: "http://fun:9999"` |
| `proxy` | Proxy configuration for all requests, useful in restrictive network environments or to route traffic through specific gateways | - | `proxy: "http://host:port"` |
| `force_ipv6` | Force IPv6 usage for all network tests | `false` | `force_ipv6: true` |
| `number_of_hosts` | Limit to N fastest hosts, helps optimize download speeds by selecting only the fastest CDN hosts | - | `number_of_hosts: 3` |
| `unrestrict_ip` | IP to use for unrestricting links, useful when you need to specify a particular IP for geographic content restrictions | - | `unrestrict_ip: "192.168.1.100"` |
| `user_agent` | User agent for requests | Chrome UA | `user_agent: "Mozilla/5.0..."` |
| `do_not_use_cdn_hosts` | Disable using CDN hosts for downloads, helpful if CDN connections are unreliable in your region | `false` | `do_not_use_cdn_hosts: true` |
| `cache_network_test_results` | Cache network test results to reduce startup time by reusing previous network test results | `false` | `cache_network_test_results: true` |

### Authentication

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `username` | HTTP basic auth username, protects your Zurg server from unauthorized access | - | `username: "admin"` |
| `password` | HTTP basic auth password, implements simple access control for multi-user environments | - | `password: "secure123"` |

## Performance & Rate Limits

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `api_rate_limit_per_minute` | Rate limit for general API calls, prevents API throttling from Real-Debrid | `250` | `api_rate_limit_per_minute: 200` |
| `torrents_rate_limit_per_minute` | Rate limit for /torrents endpoint, helps prevent API throttling from Real-Debrid | `75` | `torrents_rate_limit_per_minute: 50` |
| `api_timeout_secs` | Timeout for all API calls, can be optimized for your network conditions | `60` | `api_timeout_secs: 30` |
| `download_timeout_secs` | Timeout for all download calls, lower values for faster response to failures, higher for more reliable completion in slower networks | `15` | `download_timeout_secs: 10` |
| `retries_until_failed` | Number of retries before marking a request as failed | `2` | `retries_until_failed: 3` |
| `retry_503_errors` | Retry on 503 errors specifically, useful when Real-Debrid is experiencing temporary service issues | `false` | `retry_503_errors: true` |
| `fetch_torrents_page_size` | Number of torrents per page in /torrents call, balances between fetch speed and memory usage | `250` | `fetch_torrents_page_size: 100` |

## File & Content Management

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `enable_repair` | Enable automatic torrent repair, essential for maintaining a healthy library by automatically fixing broken torrents | `false` | `enable_repair: true` |
| `restrict_repair_to_cached` | Only use cached torrents for repair, prevents adding new torrents that might get stuck in "downloading" status | `false` | `restrict_repair_to_cached: true` |
| `rar_action` | Action for RAR files (extract, delete, none). "Extract" is useful for accessing content inside RAR archives; "delete" helps save space | `none` | `rar_action: extract` |
| `addl_playable_extensions` | Additional file extensions to consider playable, customize which file types are treated as media (e.g., audiobooks, comic books) | `[]` | `addl_playable_extensions: [m4b, cbz]` |
| `delete_torrent_if_extensions_found` | Delete torrents with these extensions, filters out potentially unwanted or dangerous file types | `[]` | `delete_torrent_if_extensions_found: [exe, zip]` |
| `delete_error_torrents` | Delete torrents with errors | `false` | `delete_error_torrents: true` |
| `hide_broken_torrents` | Hide broken/unplayable torrents, cleans up your library view by hiding content that can't be played | `false` | `hide_broken_torrents: true` |
| `ignore_renames` | Ignore rename values in torrents | `false` | `ignore_renames: true` |
| `get_downloads_limit` | Limit downloads to fetch from RD, set to 0 to disable downloads caching | `-1` (no limit) | `get_downloads_limit: 0` |
| `load_dumped_torrents` | Load torrents from dump folder on startup, useful as a recovery option | `false` | `load_dumped_torrents: true` |

### File Naming & Structure

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `force_select_playable_files` | Select all playable files even when not initially selected in the torrent, ensures all media files are available | `false` | `force_select_playable_files: true` |
| `retain_folder_name_extension` | Keep extensions in folder names, useful for single-file torrents where the extension helps identify content type | `false` | `retain_folder_name_extension: true` |
| `retain_rd_torrent_name` | Use RD torrent name instead of original name, keeps more descriptive naming in some cases | `false` | `retain_rd_torrent_name: true` |
| `serve_strm_files` | Serve .strm files instead of direct video, works well with media servers that support STRM files | `false` | `serve_strm_files: true` |
| `save_strm_files` | Create .strm files in the "strm" directory, creates physical files that can be used by external applications | `false` | `save_strm_files: true` |

## Scheduling & Updates

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `check_for_changes_every_secs` | How often to check for library changes, balance between responsiveness and resource usage | `15` | `check_for_changes_every_secs: 30` |
| `repair_every_mins` | How often to check for and repair broken torrents, set based on how critical immediate repairs are | `60` | `repair_every_mins: 120` |
| `downloads_every_mins` | How often to check for new downloads, adjust based on how frequently you add new content | `720` | `downloads_every_mins: 360` |

## Media Analysis & Library Integration

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `auto_analyze_new_torrents` | Run ffprobe on newly added torrents, enables accurate media information collection for categorization and tag-based filtering | `false` | `auto_analyze_new_torrents: true` |
| `on_library_update` | Command to run when library updates, executes custom scripts like triggering Plex library scans | - | See example below |

**Example for `on_library_update`:**
```yaml
on_library_update: |
  for arg in "$@"
  do
    echo "detected update on: $arg"
    curl -s "http://plex:32400/library/sections/1/refresh?path=$arg&X-Plex-Token=YOUR_TOKEN"
  done
```

## Media Server Integration

### Plex, Jellyfin, and Emby Integration

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `plex_server_url` | Plex server URL for seamless integration | - | `plex_server_url: "http://localhost:32400"` |
| `plex_token` | Plex authentication token | - | `plex_token: "McrxzsgyTStQNue2j3iu"` |
| `jellyfin_server_url` | Jellyfin server URL | - | `jellyfin_server_url: "http://localhost:8096"` |
| `jellyfin_token` | Jellyfin authentication token | - | `jellyfin_token: "your-token"` |
| `emby_server_url` | Emby server URL | - | `emby_server_url: "http://localhost:8096"` |
| `emby_token` | Emby authentication token | - | `emby_token: "your-token"` |
| `mount_path` | Path prefix for media servers, critical when your media server accesses Zurg's content through a different path | - | `mount_path: "/mnt/zurg"` |

## Advanced Features

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `log_requests` | Log download request stats, helpful for debugging or monitoring bandwidth usage | `false` | `log_requests: true` |
| `disable_stream_proxy` | Disable stream proxy and pass RD link directly, useful with Rclone or for better performance | `false` | `disable_stream_proxy: true` |

## Directory Configuration

Zurg allows you to define custom directories with filtering rules. This powerful feature lets you organize your content based on various criteria.

### Basic Directory Structure

```yaml
directories:
  my_directory_name:
    group: media              # Directories group
    group_order: 10           # Priority within the group
    only_show_the_biggest_file: true  # Optional: show only largest file
    only_show_files_with_size_lte: 10000000000  # Optional: max file size (10GB)
    only_show_files_with_size_gte: 1000000000   # Optional: min file size (1GB)
    filters:
      - filter_type: value    # Filters determine which torrents appear here
```

### Filter Types

Zurg supports a wide range of filters for directory configuration:

#### Basic Filters

| Filter | Description | Example |
|--------|-------------|---------|
| `id` | Match specific torrent ID | `id: "torrent-id-123"` |
| `regex` | Match regex pattern | `regex: /pattern/i` |
| `contains` | Match text (case-insensitive) | `contains: "One Piece"` |
| `contains_strict` | Match text (case-sensitive) | `contains_strict: "HD"` |
| `not_regex` | Don't match regex pattern | `not_regex: /cam/i` |
| `not_contains` | Don't contain text (case-insensitive) | `not_contains: "sample"` |
| `not_contains_strict` | Don't contain text (case-sensitive) | `not_contains_strict: "SAMPLE"` |
| `size_gte` | Size greater than or equal | `size_gte: 1000000000` |
| `size_lte` | Size less than or equal | `size_lte: 10000000000` |

#### File Inside Torrent Filters

| Filter | Description | Example |
|--------|-------------|---------|
| `any_file_inside_regex` | Any file matches regex | `any_file_inside_regex: /\b[a-fA-F0-9]{8}\b/` |
| `any_file_inside_contains` | Any file contains text | `any_file_inside_contains: "sample"` |
| `any_file_inside_contains_strict` | Any file contains text (case-sensitive) | `any_file_inside_contains_strict: "SAMPLE"` |
| `any_file_inside_not_regex` | No file matches regex | `any_file_inside_not_regex: /\.txt$/` |
| `any_file_inside_not_contains` | No file contains text | `any_file_inside_not_contains: "trailer"` |
| `any_file_inside_not_contains_strict` | No file contains text (case-sensitive) | `any_file_inside_not_contains_strict: "TRAILER"` |
| `any_file_inside_size_gte` | Any file size >= value | `any_file_inside_size_gte: 500000000` |
| `any_file_inside_size_lte` | Any file size <= value | `any_file_inside_size_lte: 5000000000` |

#### Content Type Filters

| Filter | Description | Example |
|--------|-------------|---------|
| `has_episodes` | Contains TV episodes | `has_episodes: true` |
| `is_music` | Contains music files | `is_music: true` |

#### Tag Filters

| Filter | Description | Example |
|--------|-------------|---------|
| `tags_match_all` | Must have all these tags | `tags_match_all: ["zurg_4k", "zurg_aud_eng"]` |
| `tags_match_any` | Must have at least one of these tags | `tags_match_any: ["x265", "x264"]` |
| `tags_match_none` | Must not have any of these tags | `tags_match_none: ["cam", "ts"]` |
| `tags_not_match_all` | Must not have all these tags | `tags_not_match_all: ["zurg_aud_eng"]` |
| `tags_missing_all` | Must not have any of these tags | `tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng"]` |

### Complex Filter Examples

You can combine filters using logical operators:

```yaml
directories:
  anime:
    group: media
    group_order: 10
    filters:
      - and:  # All conditions must match
        - has_episodes: true
        - any_file_inside_regex: /^\[/
        - any_file_inside_not_regex: /s\d\de\d\d/i

  quality_movies:
    group: media
    group_order: 20
    filters:
      - or:  # Any condition can match
        - and:
          - size_gte: 5000000000
          - any_file_inside_regex: /\.mkv$/
        - tags_match_all: ["bluray", "x265"]
```

### Using Tags for Organization

Tags are especially powerful when combined with media analysis. Zurg can apply tags automatically after analyzing your media files. For example, you can organize content by:

- Audio language: `zurg_aud_eng`, `zurg_aud_ger`, etc.
- Subtitle availability: `zurg_sub_eng`, etc.
- Resolution: `zurg_4k`, `zurg_1080p`, etc.

This allows for sophisticated filtering like:

```yaml
"4k english shows":
  group: tags1
  group_order: 10
  filters:
    - and:
      - tags_match_all: ["zurg_4k", "zurg_aud_eng"]
      - has_episodes: true

"foreign films with english subtitles":
  group: tags2
  group_order: 10
  filters:
    - and:
      - tags_match_all: ["zurg_sub_eng"]
      - tags_not_match_all: ["zurg_aud_eng"]
```

Note that tags like `zurg_4k`, `zurg_aud_eng`, etc. are applied only after media analysis is performed on the torrents.

## Real-World Configuration Examples

### Basic Media Server Setup

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
port: 9999
enable_repair: true
rar_action: extract
cache_network_test_results: true
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
mount_path: /mnt/zurg

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true

  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
    filters:
      - regex: /.*/
```

### Advanced Configuration with Tag-Based Organization

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
port: 9999
enable_repair: true
restrict_repair_to_cached: true
addl_playable_extensions:
- m4b
- cbz
rar_action: extract
cache_network_test_results: true
get_downloads_limit: 0
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
mount_path: /mnt/zurg
base_url: http://fun:9999

directories:
  # Specific content directories
  "fishman":
    group_order: 1
    group: media
    filters:
      - contains: fish-man

  "One_Piece":
    group_order: 2
    group: media
    filters:
      - contains: One Piece

  # Content type directories
  music:
    group_order: 5
    group: media
    filters:
      - is_music: true

  "One Pace":
    group_order: 10
    group: media
    filters:
      - contains: One Pace

  "solo_leveling":
    group_order: 11
    group: media
    filters:
      - contains: Solo Leveling

  # General content organization
  anime:
    group_order: 15
    group: media
    filters:
      - regex: /\b[a-fA-F0-9]{8}\b/
      - any_file_inside_regex: /\b[a-fA-F0-9]{8}\b/

  shows:
    group_order: 20
    group: media
    filters:
      - has_episodes: true

  movies:
    group_order: 30
    group: media
    only_show_the_biggest_file: true
    filters:
      - regex: /.*/

  # Tag-based organization
  "german shows":
    group: tags0
    group_order: 10
    filters:
      - and:
        - tags_match_all: ["zurg_aud_ger"]
        - has_episodes: true

  "german movies":
    group: tags0
    group_order: 20
    filters:
      - tags_match_all: ["zurg_aud_ger"]

  "4k english shows":
    group: tags1
    group_order: 10
    filters:
      - and:
        - tags_match_all: ["zurg_4k", "zurg_aud_eng"]
        - has_episodes: true

  "4k english movies":
    group: tags1
    group_order: 20
    filters:
      - tags_match_all: ["zurg_4k", "zurg_aud_eng"]

  "4k foreign shows":
    group: tags2
    group_order: 10
    filters:
      - and:
        - tags_match_all: ["zurg_4k", "zurg_sub_eng"]
        - tags_not_match_all: ["zurg_aud_eng"]
        - has_episodes: true

  "4k foreign movies":
    group: tags2
    group_order: 20
    filters:
      - and:
        - tags_match_all: ["zurg_4k", "zurg_sub_eng"]
        - tags_not_match_all: ["zurg_aud_eng"]

  "how can i understand these shows":
    group: tags3
    group_order: 10
    filters:
      - and:
        - tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng", "zurg_aud_und"]
        - has_episodes: true

  "how can i understand these movies":
    group: tags3
    group_order: 20
    filters:
      - tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng", "zurg_aud_und"]

  "1080p shows":
    group: tags4
    group_order: 10
    filters:
      - and:
        - tags_match_all: ["zurg_1080p"]
        - has_episodes: true

  "1080p movies":
    group: tags4
    group_order: 20
    filters:
      - tags_match_all: ["zurg_1080p"]

  "low quality shows":
    group: tags5
    group_order: 10
    filters:
      - and:
        - tags_missing_all: ["zurg_4k", "zurg_1080p"]
        - has_episodes: true

  "low quality movies":
    group: tags5
    group_order: 20
    filters:
      - tags_missing_all: ["zurg_4k", "zurg_1080p"]

  "audiobooks":
    filters:
      - and:
        - any_file_inside_regex: /\.(mp3|m4b)$/
```

## Best Practices

1. **Start Simple**: Begin with core settings and gradually add more complex configurations as needed.
2. **Directory Organization**: Create a logical directory structure that mirrors your media organization.
3. **Group Strategy**: Use the group and group_order parameters to prioritize which directories "claim" content first.
4. **Tag-Based Organization**: Leverage tags for advanced filtering, especially after media analysis.
5. **Performance Tuning**: Adjust timeouts and rate limits based on your network conditions and Real-Debrid account limitations.
6. **Security**: Always use authentication when exposing Zurg to the internet.
7. **Backup**: Keep a backup of your working configuration before making significant changes.

By properly configuring Zurg, you can create a powerful, automated media server that seamlessly integrates with Real-Debrid and your preferred media management software.
