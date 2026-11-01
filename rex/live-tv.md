---
label: Live TV with rex
icon: broadcast
order: 89
---

# Live TV with rex

rex shows live channels in the Plex apps' **Live TV**, the way a Plex server with a TV tuner does: a guide of what is on each channel, What's On, and the channel playing the moment you pick it. The channels and their guide come from an addon. [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) is the ready-made one. It takes the sports channels of a live-sports server, gives each a number and finds its guide. Nothing is recorded.

What you get:

- **A guide.** Every channel at its number, with what is on now and next.
- **What's On.** What is on right now, what starts later, and the films and sports coming up.
- **Search.** A programme's name finds it in Live TV as well as in your libraries.
- **Watching.** Pick a channel and it plays live. A channel keeps no resume point and is never marked watched.
- **The library too.** The channels stay in their own **Live Sports** library, sorted into a collection per group.

Live TV was tested in Plex Web and Plex for Android.

## Before you start

| You need | Why |
|---|---|
| A rex nightly dated 2026.11.02 or newer | Live TV came in that build |
| rex set up as in [rex with your own app](any-source.md), with [Converting video](any-source.md#converting-video-optional) | rex converts each channel while you watch it (a copy, cheap) |
| A live-sports server, on the rex machine or your home network | rex-live-sports takes its channels from it |
| Python 3.9 or newer, `git`, `ffmpeg` and `ffprobe` on the rex machine | rex-live-sports checks each channel's stream with ffprobe and draws its poster with ffmpeg |

## Step 1. Install rex and add it to a Plex account

Follow [rex with your own app](any-source.md):

1. [Step 1. Install rex](any-source.md#step-1-install-rex), including finding rex's LAN IP. This page writes it as `192.168.1.20`: put yours in its place.
2. [Step 3. Add it to a Plex account](any-source.md#step-3-add-it-to-a-plex-account): register rex on the fresh account and share it with your own.
3. [Converting video](any-source.md#converting-video-optional): every channel plays through it.

Skip steps 2 and 4 there: rex-live-sports is your app.

## Step 2. Start a live-sports server

**What it does.** Runs live-sports, which finds sports channels and checks every few minutes which of them play.

```bash
docker run -d --name live-sports --restart unless-stopped -p 8765:8765 ghcr.io/yowmamasita/live-sports:latest
```

Its [README](https://github.com/yowmamasita/live-sports-public) has the other ways to run it.

**What you should see.** `http://192.168.1.20:8765` answers in a browser.

## Step 3. Install rex-live-sports

**What it does.** Downloads rex-live-sports into `~/rex-live-sports` on the rex machine and starts it as a service.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

In `config.json`, set `live_sports_url` to `http://192.168.1.20:8765` and `rex_url` to `http://192.168.1.20:32400`. Then:

```bash
mkdir -p ~/.config/systemd/user
cp ~/rex-live-sports/rex-live-sports.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-live-sports
journalctl --user -u rex-live-sports -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

In `config.json`, set `live_sports_url` to `http://192.168.1.20:8765` and `rex_url` to `http://192.168.1.20:32400`. Then:

```bash
python3 rex_live_sports.py
```

It runs while that Terminal window stays open.
+++

**What you should see.** A line like:

```
INFO relay on http://127.0.0.1:9983/, live-sports at http://192.168.1.20:8765, rex at http://192.168.1.20:32400
```

The first sync checks every channel's stream, which takes several minutes for several hundred channels. Then:

```
INFO pushed 277 of 321 channels, ...
```

It syncs again every five minutes and checks only the channels it has not seen that day.

## Step 4. Share the library and open Live TV

The **Live Sports** library is new, so your own account cannot see it yet. Signed in as the fresh account, share it with your own account as in [step 3](any-source.md#share-it-with-your-own-account), and with anyone else you share rex with. A share lets its account watch Live TV unless you turned that off for it.

Then open a Plex app as yourself:

- **Plex Web**: **Live TV** is in the sidebar, under the rex server.
- **Plex for Android**: **Live TV** is in the menu with your libraries.

**What you should see.** The guide, with each channel at its number and what is on it. Pick a channel and it plays.

## Channel numbers and guides

rex-live-sports numbers the channels by group: `100.1`, `100.2` for the first group, `101.1` for the next, so they never clash with another source's low numbers. A channel keeps its number while live-sports lists it at least once a week.

Pluto TV channels get Pluto TV's own schedule. Any other channel gets the guide [epgshare01](https://epgshare01.online/) has for a channel of its name in its country. Both are free and need no key. A channel no guide lists, such as a single match, shows its own name in blocks of six hours.

Pluto TV's channels are left out unless you ask for them: add `"Pluto:"` to `groups` in `config.json`. Every setting is in rex-live-sports' [README](https://github.com/debridmediamanager/rex-live-sports#settings).

## Updating

```bash
cd ~/rex-live-sports && git pull && systemctl --user restart rex-live-sports
```

On macOS, stop it with Ctrl+C, run `git pull` in `~/rex-live-sports` and start it again.

## What it cannot do

- **Nothing records.** The Plex apps show no Record button.
- **Guides are matched by name.** A channel can get the guide of another feed of the same brand, and many event channels have none.
- **Plex files a programme with no episode number as a film**, as it does with any TV guide, so matches also show under What's On's films.
- **Live TV was tested in Plex Web and Plex for Android.** Other Plex apps have not been tried.
- **Anyone who can reach rex-live-sports' address can play through it.** Leave `listen` on `127.0.0.1` unless rex runs on another machine.

To bring channels of your own, with a guide you already have, see [Building rex addons](addons.md#live-tv).
