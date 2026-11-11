# MCP 端点 {#the-mcp-endpoint}

zurg 可以通过 [Model Context Protocol](https://modelcontextprotocol.io) 回应 AI 智能体：
客户端询问有哪些工具，zurg 把它们描述出来，然后智能体调用这些工具，
用来读取媒体库、排查某个资源为什么无法播放、修复它，或者控制媒体服务器。
这些操作和仪表盘与 CLI 提供的一样，只是以带有 schema 的类型化工具形式提供，
而不是 HTML 和 303 重定向。

该端点默认关闭。它和仪表盘使用相同的 basic auth 保护，并且当没有配置用户名时，
zurg 会完全拒绝提供该服务。如果用户名为空，服务器上的所有路由都会变成公开的，
而这些工具会删除资源。

## 配置 {#configuration}

```yaml
mcp:
  enabled: true
```

对于普通安装来说，这些就是全部了。其余的设置都有默认值，值得了解一下：

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

和其他功能模块一样，这部分配置只在启动时读取一次。修改后需要重启才能生效。

## 连接 {#connecting}

### 通过 HTTP {#over-http}

端点是 `/mcp`，位于 zurg 的常用端口上，使用 Streamable HTTP 协议。把客户端指向 `http://<host>:9999/mcp`，并使用仪表板的凭据。

```bash
npx @modelcontextprotocol/inspector
# Transport:  Streamable HTTP
# URL:        http://localhost:9999/mcp
# Header:     Authorization: Basic <base64 of user:password>
```

### 通过 stdio {#over-stdio}

只支持 stdio 的客户端可以使用 `zurg mcp` 子命令，它会桥接到一个正在运行的实例：

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

`cwd` 很重要：zurg 的所有路径都相对于工作目录解析，`zurg mcp` 也正是从这个目录读取 `config.yml`，获取端口和凭据。有了这些，它就不需要任何参数。`--username` 和 `--password` 会覆盖本地凭据。自定义的 `--url` 永远不会继承本地配置中的凭据。如果该端点需要凭据，请显式传入两个凭据参数，这样本地密码就不会意外发送到其他主机。

它不会启动第二个实例。第二个 zurg 会加载整个库，在按用量计费的账户上占用另一组提供方连接数，还会和第一个实例争抢挂载点。所以这个命令只是通向守护进程的管道，守护进程没有运行时，它也不提供任何服务。它的诊断信息输出到 stderr，因为 stdout 承载的是协议数据。

有一个限制：服务器在任何调用之外发出的通知，不会穿过这个桥接。在调用*期间*发出的进度和日志信息会随该调用自己的响应一起返回，能正常送达。zurg 发送的所有内容都属于这种情况。

## 工具集 {#toolsets}

| 工具组 | 默认启用 | 涵盖内容 |
|---|:-:|---|
| `library` | 是 | 搜索、目录列表、标签计数 |
| `releases` | 是 | 单个资源的详细信息：文件、各账户的副本，以及每个文件由什么提供服务 |
| `repair` | 是 | 哪些内容损坏了、修复能否覆盖到它们，以及强制修复 |
| `releases_write` | | 删除、重命名、打标签、强制显示，以及写入 `.strm` 文件 |
| `magic` | | `__magic__` 命名空间：存储布局、其中的行，以及移动内容 |
| `plex` | | Plex、Jellyfin 和 Emby：状态、匹配，以及受保护的扫描 |
| `providers` | | 已配置的账户：每个账户能做什么、能否连通，以及花费了多少 |
| `usenet` | | NZB 后端：新闻账户、文章探测、损坏情况以及文章缓存 |
| `clients` | | Sonarr 和 Radarr 所连接的 SABnzbd、qBittorrent 与 Stremio 端点 |
| `diagnostics` | | 日志、字节计数器、内存和 goroutine |
| `config` | | 读取配置、发现配置漂移，以及写入一组精选的配置项 |
| `mount` | | rclone 挂载：状态、清除缓存的列表，以及重启挂载 |
| `system` | | 构建信息、`doctor`、服务、备份和更新 |

zurg 的完整工具集有几百个工具，这比客户端能好好应对的数量还多。超过大约八十个之后，模型选错工具的概率就会上升，光是 schema 就要消耗几万个 token。所以 `toolsets` 用来选择工具组，默认值是一个可用的子集，而不是全部。

`toolsets: [all]` 会启用所有工具组。名称前加 `-` 表示减去该组，所以 `[all, -config, -system]` 就是去掉那两个组之后的完整工具集，去掉的是会改动机器本身、而不是媒体库的部分。无法识别的名称会在启动时给出警告并被忽略：拼错一个字，不能让整个端点就此失效。

那些会停止 zurg、控制其服务或循环重启挂载的工具，并不单独成组，它们分别位于 `system` 和 `mount` 中。在设置 `allow_lifecycle` 之前，这些工具会一直被隐藏，不管 `toolsets` 怎么设置。

一个很小的 `server` 组，用来说明当前构建版本以及媒体库是否加载完成，不管 `toolsets` 怎么设置，它都会被注册。如果把它藏起来，客户端就无法得知其他所有回答目前都是不完整的。

## 未经请求它不会执行的操作 {#what-it-will-not-do-without-being-asked}

**确认。** 会删除或改动内容的工具，先只描述它要做什么，并返回一个令牌；只有带着这个令牌再次调用时，才会真正执行。令牌由计划本身生成，因此确认无法套用到另一个计划上——如果期间库发生了变化，第二次调用会退回到只描述、不执行。令牌只能用一次，有效期两分钟，重启后失效。

**`read_only`。** 一个总开关，会隐藏所有会改动内容的工具，不管 `toolsets` 怎么设置。运维人员真正关心的问题是"这会不会弄坏我的库"，而不是"这些工具里哪个会写入"。这些工具不会出现在 `tools/list` 里，因此客户端无法选中这个端点永远不会允许的能力。如果服务器启动后这个设置被实时修改，调用时的检查仍然会生效，作为纵深防御。

**`allow_lifecycle`。** 用来停止 zurg、控制其服务或重启挂载的工具，同样由一个单独的开关隐藏。这些操作可能让整个库一下子全部消失，而且进程或服务类操作无法报告自己的结果，因为它们可能会在回复这次调用之前就结束进程。

**密钥。** 任何工具的返回结果都不会包含提供商令牌、API 密钥、新闻服务器密码、解析后的 CDN 链接或带签名的 `.strm` 地址。日志输出在离开程序前会做脱敏处理。解析后的链接任何持有它的人都可以用来访问生成它的账户，而聊天记录不是存放这种链接的地方。

**大小。** 每次列表都有两道限制：一是页数上限，二是序列化后结果的大小上限。有一个账户按这套规则测过，共有 84,000 个版本，光是文件名就约有 12 MB，还没开始列出任何文件。超过上限的结果会被裁剪，并明确说明已被裁剪。

## 注意事项 {#notes}

端点通过注册在仪表板内部来继承仪表板的基本认证。
跨域请求会被拒绝：`/mcp` 是给本地 agent 用的，不是给网页用的。
反向代理放在 zurg 前面是可以正常工作的。协议库的 DNS 重绑定检查会拒绝这样的代理：代理转发自己的 `Host`，同时连接 `127.0.0.1`。所以 zurg 关闭了这项检查，把访问控制交给基本认证。

`zurg mcp --help` 会列出桥接程序的所有参数。`zurg doctor` 用来检查端点到底有没有响应。
