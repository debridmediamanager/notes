# 与家人和朋友分享 rex {#share-rex-with-family-and-friends}

分享 rex 的方式是通过 Plex 的 **Manage Library Access**，从注册 rex 的账号中分享出去。每个人都用自己的 Plex 账号登录，就能在他们的其他服务器旁边看到 rex，并且保留各自的观看记录。

请先在一个全新的 Plex 账号上设置 rex。可以参考 [使用你自己的应用配置 rex](any-source.md)、[在 Stremio 插件中使用 rex](stremio.md) 或 [配合 zurg 使用 rex](with-zurg.md)。下文中的 **所有者** 指的就是这个账号。

## 谁是谁 {#who-is-who}

| 账户 | 用途 |
|---|---|
| 所有者，即注册 rex 所用的全新账户 | 共享、设置、**Fix Match** 和删除。仅在这些操作时才用它登录 |
| 你自己的账户 | 用来观看。rex 会像共享给其他人一样共享给它 |
| 家人和朋友 | 他们自己的 Plex 账户，或为儿童设置的受管用户（见下文） |

你自己的账户获得的权限不会超过你共享给的其他任何人。原因见：[我的 Plex 账户有风险吗？](faq.md#is-my-plex-account-at-risk)

## 邀请别人 {#invite-someone}

1. 以**所有者**身份登录 [app.plex.tv](https://app.plex.tv),然后打开 **Settings**(扳手图标)、**Manage Library Access** 和 **Grant Library Access**。
2. 输入对方的 Plex 用户名或邮箱,选择 rex 服务器和要共享的媒体库,然后发送邀请。
3. 对方以自己的账号登录后接受邀请。邀请会通过邮件和 app.plex.tv 送达。每个邀请需要单独接受。

![Grant Library Access 对话框,其中 rex 服务器的 Movies 和 TV Shows 已勾选](../assets/rex/21-plex-grant-library-access.webp)

**之后新增的媒体库**(来源声明的媒体库,例如 **Anime** 媒体库或 rex-stremio 目录的媒体库,或通过 **Add Library** 创建的媒体库)还没有加入任何人的共享。请在 Manage Library Access 中把它添加到每个共享里。

**对方会看到什么。** 对方以自己的账号登录后,Plex 应用里会在他们自己的服务器旁边列出 rex。在家里这样就够了。不在家的话,请继续往下看。

## 在家和外出时 {#at-home-and-away}

**在家里**时，如果 rex 使用端口 32400，Plex 应用会自动在你的网络中找到 rex。

**不在家里**时（朋友住在另一栋房子里，就属于这种情况），他们的应用需要 rex 的 HTTPS 地址。rex 没有中继服务。最简单的方法是 rex-direct：在路由器上把端口 32400 转发到运行 rex 的机器。如果你没有公网 IPv4 但有 IPv6，请改用[通过 IPv6 放行](any-source.md#rex-direct-over-ipv6)；这时朋友的网络也需要支持 IPv6。[在家以外使用](any-source.md#use-it-outside-your-home-optional)一节介绍了这种方法以及其他方式。

**你的上传速度是瓶颈。** 每一路在家以外观看的视频流，都要经过你家宽带的上传带宽发出去。如果不转码，码率就是文件本身的码率。所以两个人同时看，就需要两人份的上传带宽。以下三点可以帮上忙：

- **降低画质。** 如果用户在播放器里选择低于 Original 的画质，就会得到转码后的视频流，文件更小。这需要在运行 rex 的机器上安装 FFmpeg（参见[视频转码](any-source.md#converting-video-optional)）。在移动数据网络下，Plex 手机应用会把画质上限限制在 720p 和 4 Mbps。所以如果没有 FFmpeg，在那里播放 1080p 的影片会被拒绝，直到他们把移动网络画质设为 Original。
  ![Plex 网页播放器的画质菜单，Play Original Quality 位于 Convert to 选项之上](../assets/rex/50-plex-quality-original.webp)

- **让应用从你的服务商下载。** Plezy 和 Android 版 Plex 可以直接从你的数据源提供的链接（例如你的网盘服务的链接）获取文件，因此这部分流量不会经过你的网络：[让应用从服务商下载](direct-download.md)。不过，服务商会看到每个人都从各自的地址下载，所以在这样分享之前，请先查看服务商的规则。
- **为每人设置限速**（见下文）。

**无需 Plex Pass。** 你的朋友在家以外观看时，不需要 Plex Pass 或 Remote Watch Pass。这一点是在双方都使用免费账户的 Plex 网页版上验证的；其他应用在外出场景下尚未测试。

## 孩子：托管用户 {#children-managed-users}

如果所有者有带托管用户的 **Plex Home**，托管用户在 rex 上的使用方式与在 Plex 服务器上一样。像对待其他人一样，从 Manage Library Access 把 rex 分享给他们，然后限制他们能看到的内容（见下文）。他们会有各自的观看记录。我们已经用托管用户的分享设置做过检查：只分享电影库、只显示 G 和 PG 级别的内容、不允许下载，rex 均可正常工作。

## 每个人能看到和做什么 {#what-each-person-may-see-and-do}

你在 Manage Library Access 里为每个人单独设置,就像在任何 Plex 服务器上一样。rex 在各处都会遵守这些设置:资源库列表、搜索、主页行和影片详情页。

| 设置 | 在 rex 上的作用 |
|---|---|
| Libraries | 他们只能看到你共享的资源库。其他资源库对他们来说不存在 |
| Ratings | 只显示你允许的分级的影片,例如 G 和 PG。没有分级的影片也会被隐藏 |
| Labels | 隐藏你加了标签的影片,或只显示这些影片 |
| Downloads | 他们的 Plex 应用是否可以下载以供离线观看 |

只有当资源库所有者账户拥有 Plex Pass 时,Plex 才会在共享设置里显示 **Ratings** 和 **Labels**。在免费的新账户上,共享设置里只有 **Allow Downloads**。不过下面说的 rex 自己的限制,不需要它也能设置分级和标签。

![免费账户上 Grant Library Access 的限制步骤,只有 Allow Downloads](../assets/rex/22-plex-share-restrictions.webp)

rex 会在你做出更改时从 plex.tv 收到通知。如果某个更改没有显示,请重启 rex。

rex 还可以为某个共享设置它自己的限制,叠加在 Plex 的限制之上。这些限制只能收紧 Plex 允许的范围。它们不是在 Plex 应用里设置的,而是通过命令来设置:[本地所有者控制](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#local-owner-controls)。

## 谁能做什么 {#who-can-do-what}

| | 所有者 | 其他所有人，包括你 |
|---|---|---|
| 观看（使用各自的观看状态）、继续观看、评分和播放列表 | 是 | 是 |
| 下载以供离线观看 | 是 | 如果他们的分享允许 |
| **Fix Match** 以及编辑影片 | 是 | 否 |
| 删除影片（会在源头删除，对所有人生效） | 是 | 否 |
| 服务器设置，以及当前正在观看的人 | 是 | 否 |

合集和海报属于服务器，所以所有人看到的都是同一套。

## 带上每个人的历史记录 {#bring-each-persons-history}

每个你分享给的人，都可以把他们在另一台 Plex 服务器上看过和评过分的记录复制过来，各自使用自己的令牌：[带上你的观看历史](import-watched.md)。运行它不会改变其他任何人的历史记录。

## 同时能有多少人使用 {#how-many-at-once}

rex 自己不限制同时观看的人数。上传速度、你的机器和片源共同决定能同时播放多少路。每次转码都会在 rex 所在的机器上运行 FFmpeg。你的机器能同时跑几路，取决于机器性能，两路同时跑的情况我们还没有测试过。直接复制视频（只转换声音）几乎不耗资源。

要设置限制，请以服务器所有者身份登录，然后打开服务器的设置：

| Setting | Where | Default |
|---|---|---|
| **Remote streams allowed per user** | Network, under the advanced settings | 0, no limit. Counts streams away from home only |
| **Maximum simultaneous CPU transcodes** | Transcoder | 0, no limit. Counts every video conversion, on the graphics chip too. A copied video is never counted |

超过限制时，rex 会拒绝播放。

![rex 服务器的 Network 和 Transcoder 设置，其中 Remote streams allowed per user 和转码限制已被框出](../assets/rex/33-plex-server-limits.webp)
