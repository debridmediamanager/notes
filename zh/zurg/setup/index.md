# 设置 {#setup}

二进制安装程序是 Linux、macOS 和 Windows 上最快的方式。如果容器更合适，Linux 主机上仍然可以使用 Docker。macOS 和 Windows 上的 Docker Desktop 会在虚拟机中运行容器，因此挂载点无法显示在 Finder 或资源管理器中，rex 也无法连接到 zurg：在这些系统上请使用二进制版本。

## 单行便捷安装脚本 {#one-line-convenience-installers}

安装程序会下载赞助者每日构建版。请先在 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 上成为赞助者,它会为你的 GitHub 账号开通访问权限。

全新安装赞助者版本时,请根据你的主机选择对应命令:

+++ Linux 和 macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```
+++ Linux 上的 Docker
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```
+++ Windows
在 PowerShell 中运行:
```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```
+++

引导脚本会检查平台的前置条件,登录 GitHub 以验证赞助者权限,下载对应的构建版本,然后运行提供商选择器。已有的二进制文件和配置文件会保留。下面每个指南也都保留了完整的手动安装步骤。

- [Linux](linux.md)
- [Docker](docker.md)(Linux 主机)
- [macOS](macos.md)
- [Windows](windows.md)

安装好 zurg 之后,[提供商](../providers/index.md)页面会介绍如何将它指向某个账号。每项服务都有单独的页面,包含所需凭据、`config.yml` 配置项,以及该服务的特殊之处。这些页面是按 Docker 编写的。如果是二进制安装,提供商的 `config.yml` 配置项和 Dashboard 步骤完全相同,只需把 `docker compose restart zurg` 换成 `./zurg service restart`(Windows 上为 `.\zurg.exe service restart`)。页面中的 `docker compose run --rm zurg setup` 命令则要换成 `./zurg setup`(Windows 上为 `.\zurg.exe setup`),参数相同,但需去掉容器专用的 `--no-service --skip-downloads --mount-path /zurg_mnt/zurg`。之后,`--…-file` 参数指向的是你本机上的文件,而不是 `/config` 下的文件。
