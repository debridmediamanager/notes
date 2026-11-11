# Safari 中的 DMM 按钮 {#dmm-buttons-in-safari}

DMM 浏览器扩展会在电影和电视剧网站上添加一个 **DMM🔎** 按钮。点击后会在 DMM 中打开对应的影片。在磁力链接旁边，它还会添加一个 **DMM🧲** 按钮，用来把种子添加到你的 DMM 库中。

在 Chrome 和 Firefox 上，安装 [Chrome 扩展](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm)或 [Firefox 附加组件](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/)即可。Safari 使用同样的代码，以 [Greasy Fork 用户脚本](https://greasyfork.org/en/scripts/463268-debrid-media-manager)的形式提供，需要配合用户脚本管理器使用。

选择一个管理器：

| 管理器 | 价格 | 运行平台 | 脚本更新方式 |
|---|---|---|---|
| [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) | 免费 | Mac、iPhone、iPad | 在其弹窗中点击 **Update** 时更新 |
| [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) | 2.99 美元 | Mac、iPhone、iPad | 自动更新 |

## 使用 Userscripts {#with-userscripts}

1. 从 App Store 安装 [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887)，然后打开一次。
2. 启用扩展：
   - **Mac：** Safari > **Settings** > **Extensions**，勾选 **Userscripts**。
   - **iPhone 和 iPad：** **Settings** > **Apps** > **Safari** > **Extensions** > **Userscripts**，打开 **Allow Extension**。
3. 让它在所有网站上运行。磁力链接可能出现在任何网站上，所以脚本必须在所有网站上运行。
   - **Mac：** 在同一个 **Extensions** 页面中，点击 **Edit Websites…**，并把 **When visiting other websites** 设为 **Allow**。
   - **iPhone 和 iPad：** 在同一个 **Userscripts** 界面中，把 **All Websites** 设为 **Allow**。
4. 在 Safari 中打开 [DMM 用户脚本文件](https://update.greasyfork.org/scripts/463268/Debrid%20Media%20Manager.user.js)。它会以纯文本形式显示。
5. 打开 Userscripts 弹窗：在 Mac 上点击工具栏按钮，在 iPhone 上点击地址栏中的 **aA** 按钮。点击它显示的安装提示并确认。

以后要更新时，打开 Userscripts 弹窗，当它列出 DMM 脚本时点击 **Update**。

## 使用 Tampermonkey {#with-tampermonkey}

1. 从 App Store 安装 [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400)。
2. 打开它并让它在所有网站上运行，操作方式与上面第 2 步和第 3 步相同，只是把 **Userscripts** 换成 **Tampermonkey**。
3. 在 Safari 中打开该脚本的 [Greasy Fork 页面](https://greasyfork.org/en/scripts/463268-debrid-media-manager)，然后点击 **Install this script**。
4. Tampermonkey 会打开它的安装页面。点击 **Install**。

Tampermonkey 每天检查一次新版本。

## 检查是否正常工作 {#check-it-works}

打开 [Letterboxd 上的 Dune: Part Two](https://letterboxd.com/film/dune-part-two/)。片名旁边会出现一个青绿色的 **DMM🔎** 按钮，点击后会在 DMM 中打开这部电影。

没有看到按钮？请检查以下几点：

- 管理器的弹出窗口中列出了 **Debrid Media Manager**，并且它的开关是打开的。
- Safari 允许管理器在该网站上运行。如果弹出提示，请选择 **Always Allow on Every Website**。
- 页面已经加载完成。TMDB、Wikipedia 和 AniList 等网站会在页面加载完成后稍等片刻才显示按钮。
