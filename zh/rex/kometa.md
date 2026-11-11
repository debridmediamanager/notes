# 用 rex 配置 Kometa {#kometa-with-rex}

[Kometa](https://kometa.wiki) 可以在 Plex 服务器上创建合集、在海报上加标记（4K、HDR、评分），并补全评分和类型信息。rex 会像 Plex 服务器一样响应 Kometa，因此同一份配置也能用于你的 rex 媒体库。

以下所有内容均于 2026-10-23 使用 Kometa 2.5.3（`kometateam/kometa` Docker 镜像）和一个已认领、包含电影与剧集的 rex 进行了测试。

## 开始之前 {#before-you-start}

| 你需要 | 原因 |
|---|---|
| 已设置好 rex 并添加到 Plex 账户，参见 [将其添加到 Plex 账户](any-source.md#step-3-add-it-to-a-plex-account) | Kometa 会编辑媒体库，而只有 rex 所登记的那个账户才能进行此操作。未认领的 rex 对谁都没用 |
| rex nightly **2026.10.24 或更新版本** | 按照 [rex 的更新部分](any-source.md#updating) 进行更新 |
| 任何能访问 rex 的机器上安装 Docker | Kometa 以容器方式运行。Kometa 官方文档介绍了[其他安装方式](https://kometa.wiki/en/latest/kometa/install/overview/) |
| 一个免费的 TMDb API 密钥 | Kometa 自己需要它，即使 rex 不需要。请在 themoviedb.org 的 **Settings → API** 下申请，具体步骤参见 [TMDb 入门页面](https://developer.themoviedb.org/docs/getting-started) |

## 1. 获取 rex 的 token {#1-get-rexs-token}

Kometa 使用 Plex token 登录 rex。请使用你注册 rex 时 rex 分配给你的 token。在运行 rex 的机器上：

+++ Linux 和 macOS
```bash
grep -o '"token": "[^"]*"' ~/rex/claim_state.json
```
+++ Windows
```powershell
(Select-String '"token": "[^"]*"' $HOME\rex\claim_state.json).Matches.Value
```
+++

如果是 [Docker 中的 rex](any-source.md#run-rex-in-docker)，该文件仅 root 可读：`sudo grep -o '"token": "[^"]*"' ~/rex/config/claim_state.json`。

**你应该看到的内容。** 一行 `"token": "..."`。复制第二对引号之间的内容。把它当作密码对待：它能打开整个服务器。如果你以后重新注册 rex，token 会变，Kometa 也需要换成新的。

**不要用你自己账户的 token。** 在 [与你自己的账户共享](any-source.md#share-it-with-your-own-account) 中，你自己的账户是以共享的方式获得 rex 的。共享只能观看、不能编辑，所以用它的 token 时，Kometa 会因 `Plex Token is read only` 而停止；如果共享允许下载，则会在第一次修改时失败。

## 2. 编写 Kometa 的配置 {#2-write-kometas-config}

为 Kometa 建一个文件夹，比如 `~/kometa/config`（Windows 上是 `$HOME\kometa\config`），然后把下面这段内容放进其中的 `config.yml`：

```yaml
libraries:
  Movies:
    collection_files:
      - default: genre
    overlay_files:
      - default: resolution
      - default: ratings
        template_variables:
          rating1: critic
          rating1_image: tmdb
    operations:
      mass_critic_rating_update: tmdb
  TV Shows:
    overlay_files:
      - default: resolution
plex:
  url: http://192.168.1.20:32400
  token: the token from step 1
tmdb:
  apikey: your TMDb API key
```

- `url` 填 rex 的局域网 IP 和端口，也就是 [Install rex](any-source.md#step-1-install-rex) 里的那个地址。不要填 `127.0.0.1` 或 `localhost`，因为在 Kometa 的容器里，这两个地址指向的是容器自己。
- `libraries:` 下面的名字必须和 rex 里的库名完全一致，比如 **Movies** 和 **TV Shows**，以及你另外添加或改过名的库。不想让 Kometa 处理的库，就不要列在这里。

这只是个简单的开始。Kometa 的文档列出了[所有默认的合集和叠加层](https://kometa.wiki/en/latest/defaults/guide/)，你也可以使用自己的合集文件。

## 3. 运行一次 {#3-run-it-once}

+++ Linux 和 macOS
```bash
docker run --rm -v ~/kometa/config:/config kometateam/kometa:latest --run
```
+++ Windows
```powershell
docker run --rm -v "$HOME\kometa\config:/config" kometateam/kometa:latest --run
```
+++

`--run` 会让 Kometa 立即执行一轮然后退出。不加这个参数的话，Kometa 会保持运行，并等待每天的定时任务。

**你应该看到的内容。** 在 Kometa 的输出里，每个媒体库都会有如下内容：

```
Movies Library Connection Successful
...
Overlays Applied: Overlay File (0) 1080P, Overlay File (1) Rating1Fresh
```

在 Plex 应用里，电影库会有一个 **Collections** 标签页，里面是按类型划分的合集，海报上也会带有标记。你自己的账号，以及你共享 rex 的其他人，看到的合集和标记都是一样的。第一次在大型媒体库上运行会比较慢，因为 Kometa 需要读取每一个条目，并为每张加了标记的海报重新绘制。

## 如果无法正常工作 {#if-it-does-not-work}

| Kometa 显示 | 含义 |
|---|---|
| `Plex Token is read only. Please get a new token` | rex 还没有添加到 Plex 账号中，或者你用的 token 是你自己账号的，而不是第 1 步中的那个 |
| Kometa 能连上，但每次更改都失败 | 这个 token 是你自己账号的。请使用第 1 步中的那个 |
| `url_poster failed to update poster` | rex 所在的机器无法访问图片所在的网站 |
| `Plex URL is probably invalid` 或超时 | 在运行 Kometa 的机器上，`url` 无法访问到 rex。请在该机器上打开 `http://192.168.1.20:32400/identity`：应该会显示 rex 的 `machineIdentifier` |
| `Plex Error: Plex Library '...' not found. Options: [...]` | `libraries:` 下面的某个名称不匹配。请从它打印的列表中复制一个 |

还是搞不定？可以到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **rex-support** 论坛提问。[获取帮助](../guides/remote-help.md) 里写了需要提供哪些信息。

## Kometa 能看到和看不到的内容 {#what-kometa-can-and-cannot-see}

Kometa 根据 rex 提供的 TMDb、TVDb 和 IMDb id 匹配影片名称。如果某个标题没有被其来源识别，仍然显示文件名且没有海报，那它就没有这些 id，所以 Kometa 会把它排除在基于这些 id 构建的内容之外。请先在 Plex 应用中使用 Fix Match 修复它。

在 rex 上测试过：按标题搜索和按 TMDb id 创建的合集，以及智能合集；带海报的流派默认合集；分辨率和评分叠加层；以及从 TMDb 更新的评论家评分和流派。尚未测试：播放列表、音乐库和 Kometa 的其他操作。如果某项出错，Kometa 自己的日志会指明是哪个请求失败的，值得到 Discord 上反馈。
