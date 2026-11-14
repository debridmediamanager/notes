# DMM 哈希列表：把别人的库加到你的库里 {#dmm-hash-lists-add-someones-library-to-yours}

哈希列表是有人通过 DMM 从自己的 debrid 库中分享出来的一组资源列表。打开一个列表，用你的 debrid 服务登录 DMM，然后点击对应服务的按钮：资源就会被添加到你自己的账户中。分享的列表可以在 [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com) 查看，你也可以在 DMM 的 **Library** 中点击 **Share List** 分享自己的列表。

列表只包含资源名称、哈希值和大小，不包含任何文件，也不包含账户信息。

## 查找列表 {#find-a-list}

- 在 DMM 的首页，点击 **Hash lists**。它会打开 [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com)，并显示一个随机的列表。**Previous hash list**、**Random hash list** 和 **Next hash list** 可以在列表之间切换。
- 大家会在 [Discord](https://discord.com/invite/7u4YjMThXP) 的 **hashlists** 论坛里发布列表。每个列表都是一个类似 `https://hashlists.debridmediamanager.com/<id>.html` 的链接。打开它就会在 DMM 中打开这个列表。

## 将列表添加到你的库 {#add-a-list-to-your-library}

1. 打开列表。如果按钮显示 **Login to RD/AD/TB/PM/OC/DL to download**，先在同一个浏览器里登录 [DMM](https://debridmediamanager.com)（参见[如何登录](index.md#sign-in)），然后再重新打开列表。
2. DMM 会检查你的服务已经有哪些版本。它只显示这些版本，并把你库里已有的内容去掉。绿色的 **hidden** 框显示被去掉的数量。
3. 如果需要，可以进一步筛选：
   - **Movies** 和 **TV Shows** 只显示一种类型。数字统计的是标题数，不是文件数。
   - **One per title** 会保留每个标题的最佳版本。
   - 标题旁边绿色的 **other files** 标签会列出该标题的所有版本。
   - **quick search on filename, hash, or id; supports regex** 用于搜索列表。
4. 点击某一行上的按钮（**RD**、**TB**、**AD**、**PM**、**OC** 或 **DL**），只添加该版本。
5. 或者点击 **RD Download**（**TB Download**、**PM Download** 等）来添加显示的所有版本。按钮上的数字就是数量。它会立即开始，不会弹出"你确定吗"之类的确认。

![A shared hash list of open movies in DMM, signed in with Premiumize](../assets/dmm-hashlists/01-hash-list.webp)

在 Real-Debrid、AllDebrid 和 TorBox 上，**Show All** 还会列出你的服务没有的版本，**Show Instant** 则切换回已缓存的版本。

**RD Download** 只添加 Real-Debrid 已经有的版本，每分钟一个，因为 Real-Debrid 在账户添加得太快时会暂停。六十个版本大约需要一小时。添加操作在页面中运行，所以请保持标签页打开，直到显示 **Started 60 downloads.**。TorBox 和 AllDebrid 会跳过没有缓存的版本。

## 分享你自己的库 {#share-your-own-library}

1. 在 DMM 的主页上，点击 **Library**。
2. 搜索或勾选你想分享的版本。如果一个都没勾选，则会分享显示的所有内容。
3. 点击 **Share List**（如果你勾选了三个，按钮会显示为 **Share (3)**）。在 **Enter a title for the hash list** 处输入名称，然后点击 **OK**。
4. DMM 会打开你列表的新地址，位于 hashlists.debridmediamanager.com。发布期间，它可能会显示一两分钟的 404。刷新页面，然后分享该地址。

![点击 Share List 后出现的标题提示](../assets/dmm-hashlists/02-share-list.webp)

分享的列表是公开的。任何拿到地址的人都能打开它们，**Random hash list** 也可能把你的列表展示给陌生人。列表中只包含名称、哈希值和大小：绝不会包含你的账户、密钥或 tracker 地址。

如果只想分享单个版本而不发布任何内容，请点击资料库中该版本那一行末尾的分享图标（或其详情页中的 **Hashlist**）。DMM 会打开一个只包含该版本的列表。复制该页面的地址并发送即可。

## 出现问题时 {#when-something-is-wrong}

| 你看到的内容 | 你该怎么做 |
|---|---|
| **Login to RD/AD/TB/PM/OC/DL to download** | 你在这个浏览器里还没有登录 DMM。登录后重新打开列表。 |
| 所有内容都是 **hidden**，列表看起来是空的 | 被隐藏的行要么已经在你的库里，要么你的服务里没有它们。在 Real-Debrid、AllDebrid 或 TorBox 上，点击 **Show All**。 |
| **This hash list is still being published; refresh in a minute or two.** | 这个列表刚刚才分享出来。等一两分钟再刷新。 |
| **0 files** 且没有任何行 | 这个列表是空的。点击 **Next hash list** 或 **Random hash list**。 |
| **Everything already downloaded** | 显示的每个资源都已经在你的库里了。 |
| **Torrent not instant in TorBox; skipped.** 或 **Torrent not instant in AD; skipped.** | 你的服务上没有这个种子的缓存，所以 DMM 跳过了它，没有开始下载。 |
| **Skipping 3 items with no info hash — they cannot be shared.** | 这些行（例如 TorBox 网页下载）没有可分享的 hash。列表中的其余部分会正常分享。 |
| **Failed to generate hash list; try again soon.** | 发布列表失败了。稍后再试。 |

还有问题？到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **dmm-support** 论坛提问。

## 常见问题 {#questions}

### 如何把哈希列表添加到我自己的库？ {#how-do-i-add-hash-lists-to-my-own-library}

打开列表，用你的网盘服务登录 DMM，然后在某一行上点击对应服务的按钮，或者点击 **RD Download**（或你所用服务的 **Download**）来下载所有显示的内容。参见[将列表添加到你的库](#add-a-list-to-your-library)。

### 为什么我哈希列表里的所有条目都被隐藏了？ {#why-are-all-the-items-in-my-hash-list-hidden}

DMM 会隐藏你库中已有的内容，以及你的服务中没有缓存的内容。**hidden** 框会显示隐藏了多少项。在 Real-Debrid、AllDebrid 或 TorBox 上，点击 **Show All** 即可显示其余内容。

### 为什么哈希列表里看不到电视剧？ {#why-dont-tv-shows-show-up-in-a-hash-list}

在列表顶部点击 **TV Shows**。如果它显示 **0 TV Shows**，说明这个列表里没有剧集：大多数共享列表都是电影。你的服务没有的剧集也会被隐藏，所以可以试试 **Show All**。

### 为什么添加哈希列表这么慢？ {#why-is-adding-a-hash-list-so-slow}

在 Real-Debrid 上,DMM 每分钟只添加一个资源,这样 Real-Debrid 就不会暂停你的账户。其他服务的速度会更快。

### 有没有可以查询哈希列表的 API？ {#is-there-an-api-to-query-the-hash-lists}

ⓘ没有搜索 API。每个共享列表都是 GitHub 上公开 [hashlists 仓库](https://github.com/debridmediamanager/hashlists) 里的一个文件。每个页面都会把列表打包在 `#` 后面的链接里，把它指向 DMM（经 lz-string 压缩的 JSON，包含名称、哈希和大小）。非常大的列表则会以 `lists/<id>.txt` 的形式放在旁边。

### 分享列表会分享我的账号吗？ {#does-sharing-a-list-share-my-account}

不是。列表里只有发布名、哈希值和文件大小。
