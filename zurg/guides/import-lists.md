---
label: Lists in Sonarr & Radarr
icon: list-unordered
order: 76
---

# Following a list in Sonarr and Radarr

Sonarr and Radarr can follow a list of shows or movies. Every title on it gets added and searched. With zurg as the download client each grab lands on your debrid account and imports into `__magic__` like any other. So a list is a whole library section that fills itself. A horror list gives you a horror section and new titles show up as the list grows.

This page assumes the \*arrs already grab through zurg. If they do not yet then start with [Sonarr & Radarr for torrents](sonarr-radarr-torrents.md).

## Use MDBList and not IMDb

Both apps still show an IMDb list type and neither works with a normal IMDb list anymore.

- Radarr refuses a list ID of the form `ls12345678`. It only takes `top250` or `popular` or a user watchlist `ur12345678`.
- Sonarr accepts the ID and then gets an empty answer from IMDb. The Test button says `Imdb call resulted in an unexpected StatusCode [Accepted]`.

[MDBList](https://mdblist.com) is the way around both. It publishes any list as a JSON feed that both apps read with their Custom List type. Movies and shows sit on separate lists so you add one to each app.

## 1. Pick a list

Public lists need no account. Search MDBList for the genre you want and open a list. Two horror lists that work as of October 2026

| List | Holds | Feed URL |
|---|---|---|
| Horror | movies | `https://mdblist.com/lists/garycrawfordgc/horror/json` |
| Horror Shows | shows | `https://mdblist.com/lists/garycrawfordgc/horror-shows/json` |

The feed URL is the list's page URL with `/json` on the end. Open it in a browser first. You should see a page of text that starts with `[{"id":`.

To build your own list sign in to MDBList and create one. It can follow filters such as a genre and a minimum rating or it can copy an IMDb list you already have. The feed URL works the same way.

## 2. Add it to Radarr

**Settings → Import Lists → + → Custom Lists**

| Field | Value |
|---|---|
| Name | anything, for example `Horror` |
| Enable | on |
| Enable Automatic Add | on |
| Search on Add | read the warning below first |
| Monitor | Movie Only |
| Root Folder | your movies folder inside `__magic__`, for example `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` on macOS, `Z:\__magic__\movies` on Windows) |
| Quality Profile | the one you use |
| List URL | the movie feed URL |

Press **Test** and then **Save**.

## 3. Add it to Sonarr

**Settings → Import Lists → + → Custom List**

| Field | Value |
|---|---|
| Name | anything, for example `Horror Shows` |
| Enable Automatic Add | on |
| Monitor | All Episodes, or Pilot Episode to try a show first |
| Root Folder | your TV folder inside `__magic__`, for example `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` on macOS, `Z:\__magic__\tv` on Windows) |
| Quality Profile | the one you use |
| Series Type | Standard |
| Season Folder | on |
| Search for Missing Episodes | read the warning below first |
| List URL | the show feed URL |

Press **Test** and then **Save**.

## Big lists grab everything at once

A list with search on add switched on grabs every title the moment it syncs. The movie list above holds 400 titles and the show list holds 148 shows with every episode. That is a lot of grabs in one go. Your debrid account and your indexers will feel it and an indexer with a rate limit will start refusing searches.

There are two gentler ways in.

- Leave search on add off. The titles get added and monitored and nothing is searched. Search the ones you want from the Movies or Series page.
- Start with a short list. Add the big one once the first batch has landed.

The apps also sync lists on their own schedule. **System → Tasks → Import List Sync** runs one now.

## Removing a list

Deleting a list stops new titles from coming in. What it already added stays. Under **Settings → Import Lists** the **Clean Library Level** decides what happens to titles that drop off a list. Leave it on Disabled unless you want the apps to remove things for you.
