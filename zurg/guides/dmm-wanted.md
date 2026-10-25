# Fetch what you want from DMM

Press **Want** on a film or show on [Debrid Media Manager](https://debridmediamanager.com),
and your zurg fetches it. There is no Sonarr or Radarr to set up and nothing to mount.
Shows keep getting their new episodes as they air.

It is for sponsors: zurg reads your list with your DMM API key.

## What you need

- A zurg nightly from 2026-10-25 or later.
- Your DMM API key in zurg's `config.yml`. It is the key you get for sponsoring DMM:

  ```yaml
  dmm_api_key: YOUR_DMM_API_KEY
  ```

- Something for zurg to fetch onto: a debrid account that takes torrents, an `nzb`
  provider for Usenet, or both.

That is the whole setup. zurg reads your list once a minute from the moment it starts.

## Adding titles

1. Paste the same key on DMM's [Settings](https://debridmediamanager.com/settings) page.
2. Open a film and press **Want**. On a show's season page, **Want S2** adds that season
   and **Want all seasons** adds the whole show, new seasons included.
3. Your list is at [debridmediamanager.com/wanted](https://debridmediamanager.com/wanted).
   It says when your zurg last read it, and when it fetched each film.

## What zurg fetches

- **A film** once. It then leaves the list zurg reads.
- **A show**: every aired episode of the seasons you picked, as a season pack where one
  covers the season and as single episodes where it is still airing. It keeps checking
  for new episodes until you remove the show. Specials are not fetched.

Releases come from Usenet as NZBs and from torrents your debrid account already has
cached; uncached torrents are never added. If you have not set up any indexers, zurg
searches DMM's own. Quality, size limits, words to avoid and the audio and subtitle
languages a release must have are zurg's [acquisition settings](acquisition.md#configuration),
the same for every source.

## Two zurgs on one key

Each zurg reads the same list, so two of them fetch every title twice. Keep the list on
one and turn it off on the others:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

## When it stops

If your sponsorship lapses or you reset your key, zurg logs that DMM refused the key and
asks again every hour. What it already fetched stays in your library.

More detail: [DMM wanted list](acquisition.md#dmm-wanted-list) in the acquisition reference.
