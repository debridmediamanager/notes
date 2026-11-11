# 移动被拒绝后导入为空 {#empty-imports-after-a-refused-move}

使用 rclone 1.72.0、本地优先的 union、VFS 完整缓存，以及
Sonarr 4.0.19.2979 所用的 .NET 6 `File.Move(source, destination)` 复现了该问题。

当后端拒绝 MOVE 时，rclone 的 `vfs.File.rename` 会让文件的
目录和名称仍指向尝试的目标位置。随后 .NET 退回到复制。创建目标文件会生成一个空的 VFS 缓存条目；打开源文件时会命中同一个条目，因此复制读到 EOF 并报告成功。
复现预期读到 4096 字节，实际得到 0 字节。把 WebDAV 的拒绝状态码从 409 改为 422，结果没有变化。

`scripts/patches/rclone-v1.72.0-rename.patch` 中的补丁会在即时重命名失败时，恢复原始的
目录和名称。补丁包含一个上游 VFS 回归测试。挂载测试会用一个假的归档文件、不使用任何提供商凭据，走完整的 WebDAV、union、FUSE 和 .NET 路径。它的损坏判定是在测试样本字节仍可读时注入的：.NET 可能会成功复制这些字节，但不能把它们变成空文件。

在已安装的版本旁边构建一个新的二进制文件：

```sh
./scripts/build-rclone-move-fix.sh /absolute/path/to/rclone-fixed
RCLONE_TEST_BIN=/absolute/path/to/rclone-fixed ./integration/magic_move_refusal.sh
```

构建会固定上游提交 `38ab3dd5b1df946aecf5bd085c671c86f46f68eb` (1.72.0)。
构建前会先运行 VFS 重命名测试。挂载测试需要 Linux
FUSE 和 Docker，或者使用由 `integration/dotnet-move-probe` 构建的独立 `DOTNET_MOVE_PROBE_BIN`。
它对未打补丁的二进制会有意失败。`make integration-test` 包含此项检查；运行套件时，把 `RCLONE_TEST_BIN` 和 `RCLONE_BIN` 指向修正后的二进制文件。

安装时需要使用部署中常规的媒体服务器保护措施重启挂载。保留旧的二进制文件以便回滚。
union 本地上游中已存在的空文件在挂载重启后依然保留；只保留并删除已确认的空导入残留文件。
重启会清除过期的 VFS 节点，但不会修复缺失的 Usenet 文章。

此修正不会抑制 .NET 的复制回退，也不会让损坏的内容变得可读。
zurg 在 SABnzbd 完成前的可用性检查，以及被拒绝的 MOVE，仍是各自独立的保护。
可用性抽样不是完整文件校验；请参阅 `sabnzbd-client-contract.md`。

固定的补丁还包含内嵌 union 所用的文件别名修正。
当 `action_policy: all` 时，本地和 WebDAV 都可能收到同一个文件操作。
本地的 Move 或 Remove 成功，同时 WebDAV 返回 404，只有在重新查询确认失败的上游源已不存在后，才会被接受。
所有上游都失败的操作、源仍然存在的情况、目标父目录缺失，以及其他 I/O 或权限错误，仍然算作失败。
构建出的二进制会报告 `v1.72.0-zurg-rename-sidecar-fix`，以便与原始的仅 VFS 版本区分开。
