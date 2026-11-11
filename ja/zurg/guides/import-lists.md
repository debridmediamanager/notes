# Sonarr と Radarr でリストをフォローする {#following-a-list-in-sonarr-and-radarr}

Sonarr と Radarr は、番組や映画のリストをフォローできます。リストに載っているタイトルはすべて追加されて検索されます。ダウンロードクライアントに zurg を使うと、取得したものはそれぞれ debrid アカウントに入り、ほかと同じように `__magic__` へインポートされます。つまりリストは、勝手に埋まっていくライブラリのセクションのようなものです。ホラーのリストを作ればホラー用のセクションができ、リストが増えるたびに新しいタイトルが現れます。

このページは、\*arr がすでに zurg 経由で取得していることを前提にしています。まだの場合は、まず [Sonarr & Radarr for torrents](sonarr-radarr-torrents.md) から始めてください。

## IMDb ではなく MDBList を使う {#use-mdblist-and-not-imdb}

両方のアプリには今でも IMDb リストの種類が表示されていますが、通常の IMDb リストはもう使えません。

- Radarr は `ls12345678` の形式のリスト ID を受け付けません。使えるのは `top250` か `popular`、またはユーザーのウォッチリスト `ur12345678` だけです。
- Sonarr は ID を受け付けますが、IMDb から空の応答が返ってきます。Test ボタンを押すと `Imdb call resulted in an unexpected StatusCode [Accepted]` と表示されます。

どちらの問題も [MDBList](https://mdblist.com) を使えば回避できます。MDBList は任意のリストを JSON フィードとして公開してくれるので、両方のアプリが Custom List タイプで読み込めます。映画とドラマは別々のリストになっているので、それぞれのアプリに 1 つずつ追加してください。

## 1. リストを選ぶ {#1-pick-a-list}

公開リストならアカウントは不要です。MDBList でジャンルを検索して、好きなリストを開いてください。2026年10月時点で動作するホラーのリストが2つあります。

| リスト | 内容 | フィード URL |
|---|---|---|
| ホラー | 映画 | `https://mdblist.com/lists/garycrawfordgc/horror/json` |
| ホラー番組 | 番組 | `https://mdblist.com/lists/garycrawfordgc/horror-shows/json` |

フィード URL は、リストのページ URL の末尾に `/json` を付けたものです。まずブラウザで開いてみてください。`[{"id":` で始まるテキストのページが表示されれば成功です。

自分でリストを作るには、MDBList にサインインして新しいリストを作成します。ジャンルや最低評価などのフィルターで絞り込むこともできますし、すでに持っている IMDb のリストをコピーすることもできます。フィード URL の使い方は同じです。

## 2. Radarr に追加する {#2-add-it-to-radarr}

**設定 → Import Lists → + → Custom Lists**

| Field | Value |
|---|---|
| Name | 何でもOK。例：`Horror` |
| Enable | オン |
| Enable Automatic Add | オン |
| Search on Add | 下の警告を先に読んでください |
| Monitor | Movie Only |
| Root Folder | `__magic__` の中にある映画フォルダ。例：`/mnt/zurg/__magic__/movies`（macOS では `/Volumes/Zurg/__magic__/movies`、Windows では `Z:\__magic__\movies`） |
| Quality Profile | 普段使っているもの |
| List URL | 映画フィードの URL |

**Test** を押してから **Save** を押します。

## 3. Sonarr に追加する {#3-add-it-to-sonarr}

**Settings → Import Lists → + → Custom List**

| Field | Value |
|---|---|
| Name | 何でもOK。例: `Horror Shows` |
| Enable Automatic Add | オン |
| Monitor | All Episodes、または番組を試しに見るなら Pilot Episode |
| Root Folder | `__magic__` 内のTVフォルダ。例: `/mnt/zurg/__magic__/tv`（macOSでは `/Volumes/Zurg/__magic__/tv`、Windowsでは `Z:\__magic__\tv`） |
| Quality Profile | 普段使っているもの |
| Series Type | Standard |
| Season Folder | オン |
| Search for Missing Episodes | 先に下の警告を読んでください |
| List URL | 番組フィードのURL |

**Test** を押してから **Save** を押します。

## 大きなリストは一度にまとめて取得される {#big-lists-grab-everything-at-once}

リストで search on add を有効にしていると、同期された瞬間にすべてのタイトルが grab されてしまいます。上のムービーリストには 400 タイトル、シリーズリストには全エピソード付きで 148 シリーズがあります。一度にこれだけ grab すると、debrid アカウントもインデクサーも負荷を受けますし、レート制限のあるインデクサーは検索を拒否し始めるでしょう。

もっと穏やかに始める方法が 2 つあります。

- search on add をオフのままにします。タイトルは追加されて監視対象になりますが、検索はされません。欲しいものだけ Movies か Series ページから検索してください。
- 短いリストから始めます。最初のバッチが入ってから、大きいリストを追加します。

アプリはリストを独自のスケジュールで同期します。**System → Tasks → Import List Sync** を使えば、今すぐ実行できます。

## リストを削除する {#removing-a-list}

リストを削除すると、新しいタイトルは追加されなくなります。すでに追加されたタイトルはそのまま残ります。**Settings → Import Lists** の **Clean Library Level** で、リストから外れたタイトルをどう扱うかを決めます。アプリに自動で削除させたくなければ、Disabled のままにしておいてください。
