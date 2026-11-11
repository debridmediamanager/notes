# 出站请求身份 {#outbound-request-identity}

`user_agent` 用于控制共享的 HTTP User-Agent，适用于 debrid API 和 CDN 读取、Newznab 搜索、NZB 下载、OpenSubtitles、ffprobe 探测、媒体服务器集成、依赖下载、更新以及可选的分享或日志导出。
默认值是通用的浏览器 agent。留空会恢复这个默认值；手动填写的自定义值会原样发送，即使它标明了应用本身。
`omit_user_agent: true` 会取消 Go HTTP 客户端的 User-Agent 请求头，并让 ffprobe 使用空 agent，覆盖你配置的字符串。有些服务在没有 agent 时会拒绝请求。GitHub 对每个没有 agent 的请求都会返回 403，所以发给 GitHub 的请求（`zurg update`，以及 rclone 和 ffprobe 的下载）仍会带上你配置的 agent；如果没设置，就用通用浏览器 agent。

Plex、Jellyfin 和 Emby 也需要客户端/设备元数据。用 `outbound_client_name`、`outbound_client_id`、`outbound_client_version`、`outbound_device_name`、`outbound_device_id` 和 `outbound_platform` 来配置。默认值分别是 `Media Client`、`media-client`、`1.0`、`Media Client`、`media-client` 和 `Desktop`。Plex 用客户端 ID 进行认证、扫描和元数据请求；Jellyfin/Emby 则在认证元数据中使用设备 ID。只有协议支持的字段才会被使用。修改 ID 后，媒体服务器里可能会显示成另一个客户端或设备。

以上这些设置都可以在仪表盘的 Network & Connectivity 下找到。仪表盘会显示已保存的值，并解析出默认值。Restart 会一起应用这些设置；仅保存不会改变正在运行的身份标识。值必须是可打印的 ASCII 字符，最多 2048 个字符；客户端/设备字段不能包含引号或反斜杠。认证令牌和协议请求头名称保持不变，包括 DMM 必需的 `X-Zurg-Token` 凭据。

提供商/索引器客户端在发送请求之前会移除 `Referer`、`Origin` 和 `X-Zurg*` 请求头，包括重定向之后的请求。这样重定向就不会通过 Referer 泄露之前 URL 的私有路径或 API 密钥查询参数。认证、范围请求、提供商 cookie 和重定向次数限制都保持不变。这些请求中不会添加任何应用客户端/设备标识符。

NNTP 会按需发送 `AUTHINFO USER`、`AUTHINFO PASS`、`BODY`、`STAT`、`DATE` 和 `QUIT`，不会发送任何软件标识命令。没有可配置的 NNTP 软件 ID。用户名和密码仍保存在每个提供商的 NNTP 配置中。TLS 和明文传输记录测试覆盖了认证、文章访问、keep-alive 和关闭过程。

这些做法只是尽量减少明确的应用标识，并不能提供匿名性。远程服务仍然能看到凭据、源 IP、请求的内容和时间。TLS/HTTP 行为、自定义身份、应用注册的 API 密钥以及访问模式（包括 Real-Debrid 网络测试链接），都可能被用来关联请求。外部提供的 URL、种子元数据、文章 ID、分享内容和导出的日志或配置内容不会被改写。软件下载 URL 本身标明了所请求的软件。外部播放器和单独启动的工具使用它们自己的设置。

Socket 级别的回归测试覆盖了默认值、自定义和省略的 agent、重定向、保留的认证信息以及媒体服务器元数据。配置和仪表盘测试覆盖了校验、YAML 往返，以及在重启时应用设置。
