# 在 Sonarr 和 Radarr 中关注列表 {#following-a-list-in-sonarr-and-radarr}

Sonarr 和 Radarr 可以订阅一个剧集或电影列表。列表上的每个标题都会被添加并搜索。把 zurg 设为下载客户端后，每次抓取的内容都会落到你的 debrid 账户里，并像其他内容一样导入 `__magic__`。所以一个列表就是一个会自动填充的完整媒体库分区。比如一个恐怖片列表会给你一个恐怖片分区，列表变长，新标题就会自动出现。

本页假设 \*arrs 已经通过 zurg 抓取内容。如果还没有，请先看 [Sonarr & Radarr for torrents](sonarr-radarr-torrents.md)。

## 使用 MDBList，而不是 IMDb {#use-mdblist-and-not-imdb}

两个应用仍然显示 IMDb 列表类型，但现在都无法使用普通的 IMDb 列表。

- Radarr 拒绝格式为 `ls12345678` 的列表 ID。它只接受 `top250`、`popular`，或者用户观察列表 `ur12345678`。
- Sonarr 接受该 ID，但 IMDb 返回空结果。Test 按钮显示 `Imdb call resulted in an unexpected StatusCode [Accepted]`。

[MDBList](https://mdblist.com) 可以绕过这两个问题。它把任意列表发布为 JSON 数据源，两个应用都能通过各自的 Custom List 类型读取。电影和剧集分别放在不同的列表中，所以需要在每个应用里分别添加一个。

## 1. 选择一个列表 {#1-pick-a-list}

公开列表不需要账号。在 MDBList 中搜索你想要的类型,然后打开一个列表即可。截至 2026 年 10 月,有两个恐怖片列表可以正常使用:

| 列表 | 内容 | Feed URL |
|---|---|---|
| Horror | 电影 | `https://mdblist.com/lists/garycrawfordgc/horror/json` |
| Horror Shows | 剧集 | `https://mdblist.com/lists/garycrawfordgc/horror-shows/json` |

Feed URL 就是列表页面的网址,末尾加上 `/json`。先在浏览器中打开它。你应该会看到一页以 `[{"id":` 开头的文本。

要创建自己的列表,请登录 MDBList 并新建一个。它可以按类型、最低评分等筛选条件生成,也可以复制你已有的 IMDb 列表。Feed URL 的用法相同。

## 2. 将其添加到 Radarr {#2-add-it-to-radarr}

**Settings → Import Lists → + → Custom Lists**

| Field | Value |
|---|---|
| Name | beliebig, zum Beispiel `Horror` |
| Enable | an |
| Enable Automatic Add | an |
| Search on Add | lies zuerst die Warnung unten |
| Monitor | Movie Only |
| Root Folder | dein Filmordner innerhalb von `__magic__`, zum Beispiel `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` unter macOS, `Z:\__magic__\movies` unter Windows) |
| Quality Profile | das Profil, das du verwendest |
| List URL | die URL des Film-Feeds |

Drücke **Test** und danach **Save**.

## 3. 将其添加到 Sonarr {#3-add-it-to-sonarr}

**Settings → Import Lists → + → Custom List**

| Field | Value |
|---|---|
| Name | 随便起个名字，例如 `Horror Shows` |
| Enable Automatic Add | 开启 |
| Monitor | All Episodes，或者选 Pilot Episode 先试看一部剧 |
| Root Folder | 你放电视剧的文件夹，位于 `__magic__` 里面，例如 `/mnt/zurg/__magic__/tv`（macOS 上是 `/Volumes/Zurg/__magic__/tv`，Windows 上是 `Z:\__magic__\tv`） |
| Quality Profile | 你平时用的那个 |
| Series Type | Standard |
| Season Folder | 开启 |
| Search for Missing Episodes | 先看下面的警告 |
| List URL | 剧集订阅的 URL |

点击 **Test**，然后点 **Save**。

## 大型列表会一次性全部抓取 {#big-lists-grab-everything-at-once}

列表开启了 search on add 后，每次同步都会立即抓取所有条目。上面的电影列表有 400 部，剧集列表有 148 部剧，每集都算在内。一次性要抓这么多，你的 debrid 账户和索引器都会吃不消，而有速率限制的索引器会开始拒绝搜索。

有两种更温和的做法：

- 关闭 search on add。条目会被添加并设为监控，但不会进行搜索。需要的条目再从 Movies 或 Series 页面手动搜索。
- 先用一个较短的列表。等第一批入库后，再添加大的那个列表。

应用也会按自己的计划同步列表。要立即运行一次，请到 **System → Tasks → Import List Sync**。

## 删除列表 {#removing-a-list}

删除列表后，新的标题就不会再进来了，但之前已经添加的内容会保留。在 **Settings → Import Lists** 下，**Clean Library Level** 决定了从列表中移除的标题会如何处理。除非你希望应用替你删除内容，否则请保持其为 Disabled。
