# Premiumize

`type: premiumize`

Premiumize 会挂载已完成的传输**以及**清空传输列表后仍保留在云端的文件。嵌套文件夹会保留其路径。你在 Premiumize 上整理好的媒体库，在挂载中会保持你原来的排列方式。

## 获取 API 密钥 {#get-the-api-key}

登录并打开 [premiumize.me/account](https://www.premiumize.me/account)。API 密钥就在该页面上。

## 配置它 {#configure-it}

```yaml
zurg: v1
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY
mount_path: "/zurg_mnt/zurg"
```

在全新安装的容器里，让 setup 来写入即可。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider premiumize
```

如果已经有了 `config.yml`，就在 `http://localhost:9999/config/` 的仪表盘里点击 **Add provider**，或者直接编辑这个文件。两种方式都需要重启。

```bash
docker compose restart zurg
```

`PREMIUMIZE_TOKEN` 是由 `zurg setup` 读取的，而不是正在运行的守护进程。只放在 compose 的 `environment:` 块里，它本身不会起任何作用。

## 每个条目一个凭据 {#one-credential-per-entry}

Premiumize 的文件 ID 属于列出它们的那个账户,没有可以轮换切换的第二个密钥。`download_tokens` 会被直接拒绝,`strm_link_token` 与 `token` 不同时也会被拒绝。第二个 Premiumize 账户就是另一个条目,使用它自己的 `name`。

```yaml
providers:
  - type: premiumize
    name: pm-main
    token: FIRST_PREMIUMIZE_API_KEY
  - type: premiumize
    name: pm-second
    token: SECOND_PREMIUMIZE_API_KEY
```

加载器对此会明确报错,而不是悄悄忽略这些键。它会拒绝该配置并指出是哪个条目出了问题。

## 这里能用的功能 {#what-works-here}

库浏览、流式读取、重定向读取、STRM、magnet 添加、`.torrent` 上传和删除都可以正常使用。每个账户都会像其他账户一样,拥有自己的 `__premiumize__` 目录。

## 哈希值会保存在磁盘上 {#hashes-are-remembered-on-disk}

通过 zurg 提供的哈希值会写入
`data/premiumize/<account>/sources.json`，位于 `/config` 挂载目录中。跨账户匹配
在重启后仍然有效，清空已完成的传输
列表后也一样。

你通过其他方式导入的云端内容没有记录哈希值，但仍然可以
播放。它无法通过哈希修复，也无法和另一个
账户通过哈希进行匹配。

!!!warning 删除传输会删除其文件
通过 zurg 删除 Premiumize 传输时，
也会删除该传输拥有的文件。这是 Premiumize 自身的行为，
而不是 zurg 额外添加的功能。
!!!

## 值得了解的限制 {#limits-worth-knowing}

**Cloud-Speicher und Fair Use sind die eigenen Grenzen des Kontos.** zurg hebt sie nicht auf und umgeht sie auch nicht.

Hier ist die deutsche Fassung, aber der Text ist Simplified Chinese, also hier die richtige Übersetzung:

**云存储和合理使用是账户本身的限制。** zurg 不会提高这些限制，也不会绕过它们。

**同时最多 8 个 API 请求。** 多卷压缩包的四个分卷会同时解析。

**内容会过期。** 资源已失效是预期中的结果，而不是故障。除非你主动要求，修复操作不会去动它。

**种子列表不包含文件详情。** 每个资源第一次都需要单独查询一次。

zurg 会把服务返回的错误代码映射成它接下来应该做的事。

| Premiumize 返回的代码 | zurg 的处理方式 |
|---|---|
| `authentication_failed` | 报告凭据有误。请修正 key。 |
| `rate_limit_reached` | 暂停该账户一分钟。 |
| `account_limit_reached` 或 `service_limit_reached` | 报告配额已用完。 |
| `service_down` | 将该账户视为暂时不可用。 |
| `not_found` | 将该种子视为已失效。 |

## 检查是否生效 {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/premiumize/test
ls /zurg_mnt/zurg/__all__/ | head
```

只有一个账号时，它自己的文件夹会被排除在挂载的根目录列表之外，所以挂载点会在 `__all__` 下显示同样的文件。

## 出错时怎么办 {#when-it-goes-wrong}

**任何操作都因凭据错误而失败。** 请到 [premiumize.me/account](https://www.premiumize.me/account) 重新生成密钥,然后更新该条目。
注意,Premiumize 对缺失的密钥和错误的密钥给出的回应完全相同,提示信息无法告诉你究竟是哪一种情况。

**某个版本能流式播放,但无法修复。** 它没有记录哈希值。这说明它是通过 zurg 以外的途径进入账户的。参见上文。

**读取操作每次暂停一分钟。** 已达到速率限制,zurg 有意暂停了该账户。它会自动恢复。

**生成的链接对任何拿到它的人都有效。** 投递链接和 `.strm` 访问应当保密。它们消耗的配额属于账户本身。
