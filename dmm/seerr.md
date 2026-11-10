# Seerr through DMM

Add DMM to [Seerr](https://github.com/seerr-team/seerr) as Radarr and Sonarr. Approved requests
land on your [DMM wanted list](../zurg/guides/dmm-wanted.md) for zurg to fetch. You do not need
Radarr or Sonarr. Seerr only needs to reach debridmediamanager.com. Overseerr and Jellyseerr work
the same way.

It is for sponsors. Seerr signs in with the DMM API key from [gatekeeper](https://gatekeeper.debridmediamanager.com/).

## What you need

- zurg reading your wanted list with `dmm_api_key` in `config.yml`. See [Fetch what you want from DMM](../zurg/guides/dmm-wanted.md#what-you-need).
- Seerr set up with your Plex or Jellyfin server so it knows which episodes you have.

## Add DMM as Radarr

In Seerr, open **Settings → Services** and press **Add Radarr Server**. Fill it in like this:

| Field | Value |
|---|---|
| Default Server | ticked |
| 4K Server | unticked |
| Server Name | `DMM`, or any name |
| Hostname or IP Address | `debridmediamanager.com` |
| Port | `443` |
| Use SSL | ticked |
| API Key | your DMM API key |
| URL Base | `/api/arr/radarr` |

Press **Test**. When it connects pick **Any** for Quality Profile and **/dmm** for Root Folder.
Leave Minimum Availability as it is. Tick **Enable Scan** and press **Add Server**.

![Seerr's Add Radarr Server dialog filled in for DMM](../assets/seerr-dmm/01-seerr-radarr-dmm.webp)

If Test fails, check the key: it is the one on DMM's [Settings](https://debridmediamanager.com/settings)
page. DMM also refuses it once your sponsorship has lapsed.

## Add DMM as Sonarr

Press **Add Sonarr Server** and use URL Base `/api/arr/sonarr`. After **Test** pick **Any** and
`/dmm` for both profiles and root folders. Tick **Enable Scan** and press **Add Server**.

![Seerr's Add Sonarr Server dialog filled in for DMM](../assets/seerr-dmm/02-seerr-sonarr-dmm.webp)

## Requesting

Request as usual. An approved film goes on your wanted list:

![Requesting a film in Seerr](../assets/seerr-dmm/03-seerr-request-movie.webp)

![The film shows as requested](../assets/seerr-dmm/04-seerr-movie-requested.webp)

For a show pick the seasons you want. A later request can add more. To follow the whole show
including new seasons press **Want all seasons** on its DMM page.

![Picking seasons of a show](../assets/seerr-dmm/05-seerr-request-seasons.webp)

Your [wanted list](https://debridmediamanager.com/wanted) shows each title within seconds. zurg
picks it up within a minute.

## What Seerr shows

Seerr reads DMM's list once a day in **Radarr Scan** and **Sonarr Scan**. To run them now open
**Settings → Jobs & Cache** and press **Run Now** next to each.

- **A film** zurg has fetched shows as **Available**.

  ![A fetched film shows as available](../assets/seerr-dmm/06-seerr-movie-available.webp)

- **A show** stays **Processing** until its episodes reach your Plex or Jellyfin library
  and Seerr's scan of that server finds them. DMM does not know which episodes zurg holds.

## Removing a title

Open the title in Seerr, press the gear button and then **Remove from Radarr** (or
**Remove from Sonarr**). That takes it off your wanted list. What zurg already fetched stays
in your library. **Open in Radarr** next to it opens the title on DMM.

Stuck? Ask in the **dmm-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) says what to include.

## Seerr through DMM or zurg's own Seerr source

zurg can also read Seerr itself, with a [`seerr` source](../zurg/guides/acquisition.md#configuration).
Use one of the two, not both:

- **Through DMM**, Seerr only needs to reach the internet, the requests show on your
  wanted list next to what you added with **Want**, and Seerr's daily scan marks the films
  zurg fetched as available.
- **zurg's own source** treats a 4K request apart from a 1080p one, but zurg has to be
  able to reach Seerr.
