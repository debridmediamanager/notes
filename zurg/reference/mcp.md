---
label: MCP server
icon: plug
order: 70
---

# The MCP endpoint

zurg can answer an AI agent over the [Model Context Protocol](https://modelcontextprotocol.io):
the client asks what tools exist, zurg describes them, and the agent calls them
to read the library, work out why a release is not playing, repair it, or drive
the media servers. It is the same set of operations the dashboard and the CLI
expose, as typed tools with schemas rather than as HTML and 303 redirects.

The endpoint is off by default. It sits behind the same basic auth as the
dashboard, and zurg refuses to serve it at all when no username is configured —
with one empty, every route on the server is public, and these tools delete
releases.

## Configuration

```yaml
mcp:
  enabled: true
```

That is the whole of it for a normal install. The rest has defaults worth
knowing about:

```yaml
mcp:
  enabled: true
  toolsets: [library, releases, repair]   # the default; see below
  read_only: false                        # withhold every tool that changes anything
  allow_unauthenticated: false            # serve /mcp with no username set
  allow_lifecycle: false                  # admit the tools that stop zurg or its mount
  page_limit: 50                          # items a listing returns by default; 500 is the cap
  max_result_kb: 256                      # ceiling on one result; a page over it is trimmed
  session_timeout_mins: 30                # -1 keeps sessions for the life of the process
```

Like the other feature blocks, this is read once at startup: changing it takes
a restart.

## Connecting

### Over HTTP

The endpoint is `/mcp` on zurg's usual port, speaking Streamable HTTP. Point a
client at `http://<host>:9999/mcp` with the dashboard's credentials.

```bash
npx @modelcontextprotocol/inspector
# Transport:  Streamable HTTP
# URL:        http://localhost:9999/mcp
# Header:     Authorization: Basic <base64 of user:password>
```

### Over stdio

Clients that only speak stdio use the `zurg mcp` subcommand, which bridges to a
running instance:

```json
{
  "mcpServers": {
    "zurg": {
      "command": "/path/to/zurg",
      "args": ["mcp"],
      "cwd": "/path/to/your/zurg/directory"
    }
  }
}
```

The `cwd` matters: every zurg path resolves against the working directory, and
that is where `zurg mcp` reads `config.yml` for the port and the credentials.
With those it needs no arguments. `--username` and `--password` override the
local credentials. A custom `--url` never inherits credentials from the local
config — pass both credential flags explicitly when that endpoint needs them,
so a local password cannot be sent to another host by accident.

It starts no second instance. A second zurg would load the whole library, take
a second set of provider slots against accounts that meter them, and fight the
first for the mount — so the command is a pipe to the daemon, and it serves
nothing when the daemon is not up. Its diagnostics go to stderr, because stdout
carries the protocol.

One limitation: a notification the server raises outside any call does not
cross the bridge. Progress and log lines raised *during* a call ride that
call's own response and arrive normally, which covers everything zurg sends.

## Toolsets

zurg's full surface is a few hundred tools, which is more than a client reasons
over well — past roughly eighty, a model picks the wrong tool more often and
the schemas alone cost tens of thousands of tokens. So `toolsets` selects
groups, and the default is a working subset rather than everything.

| Toolset | In the default | What it covers |
|---|:-:|---|
| `library` | yes | Search, directory listings, tag counts |
| `releases` | yes | One release in detail: files, per-account copies, what can serve each file |
| `repair` | yes | What is broken, whether repair will reach it, forcing a repair |
| `releases_write` | | Deleting, renaming, tagging, force-showing, writing `.strm` files |
| `magic` | | The `__magic__` namespace: the stored layout, its rows, and moving things about |
| `plex` | | Plex, Jellyfin and Emby: status, matching, and guarded scanning |
| `providers` | | The configured accounts: what each can do, whether it is reachable, what it has spent |
| `usenet` | | The NZB backend: news accounts, article probes, damage and the article cache |
| `clients` | | The SABnzbd, qBittorrent and Stremio endpoints Sonarr and Radarr talk to |
| `diagnostics` | | The log, the byte counters, memory and goroutines |
| `config` | | Reading the configuration, finding drift, and writing a curated set of keys |
| `mount` | | The rclone mount: status, forgetting cached listings, restarting it |
| `system` | | Build facts, `doctor`, the service, backups and updating |

`toolsets: [all]` enables every group. A name prefixed with `-` subtracts, so
`[all, -config, -system]` is the whole surface without the two that change the
machine rather than the library. An unrecognised name warns at startup and is
ignored: a typo must not take the endpoint away.

The tools that stop zurg, control its service or cycle the mount are not a
group of their own — they live in `system` and `mount`, and stay withheld until
`allow_lifecycle` is set, whatever `toolsets` says.

A small `server` group — what this build is, and whether the library has
finished loading — is always registered whatever `toolsets` says. Withholding
it would leave a client unable to find out that every other answer is currently
partial.

## What it will not do without being asked

**Confirmation.** A tool that takes something away describes what it would do
and hands back a token; it acts only when called again with that token. The
token is derived from the plan, so a confirmation cannot carry to a different
one — if the library changed in between, the second call goes back to
describing rather than doing. Tokens are single-use, last two minutes and do
not survive a restart.

**`read_only`.** One switch that withholds every tool that changes anything,
whatever `toolsets` says. The question an operator actually asks is "can this
break my library", not "which of these tools writes". They are omitted from
`tools/list`, so a client cannot select a capability this endpoint will never
admit. The call-time gate remains as defence in depth if the live setting
changes after the server was built.

**`allow_lifecycle`.** The tools that stop zurg, control its service or cycle
the mount are withheld the same way behind a separate switch. Each can make
the entire library disappear at once, and the process/service actions cannot
report their own outcome because they may end the process answering the call.

**Secrets.** No tool result carries a provider token, an API key, a news-server
password, a resolved CDN link or a signed `.strm` URL. Log output is redacted
on the way out. A resolved link is redeemable by anyone holding it against the
account that minted it, and a transcript is not a place to put one.

**Size.** Every listing is bounded twice: by a page limit, and by a ceiling on
the marshalled result. One account measured against this holds 84,000 releases,
which is about twelve megabytes of names before a single file is listed. A
result over the ceiling is trimmed and says that it was trimmed.

## Notes

The endpoint inherits the dashboard's basic auth by being registered inside it.
A cross-origin request is refused: `/mcp` is for a local agent, not a web page.
A reverse proxy in front of zurg works — the protocol library's DNS-rebinding
check would otherwise reject a proxy that forwards its own `Host` while dialling
`127.0.0.1`, so zurg turns that check off and leaves the gate to basic auth.

`zurg mcp --help` lists the bridge's flags. `zurg doctor` checks whether the
endpoint is answering at all.
