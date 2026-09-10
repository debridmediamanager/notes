# Outbound request identity

`user_agent` controls the shared HTTP User-Agent for debrid APIs and CDN reads,
Newznab searches, NZB downloads, OpenSubtitles, ffprobe probes, media-server
integrations, dependency downloads, updates and optional sharing/log exports.
The default is a generic browser agent. Blank restores that default; an explicit
custom value is sent as entered, even if it identifies the application.
`omit_user_agent: true` suppresses Go HTTP clients' User-Agent header and gives
ffprobe an empty agent, overriding the configured string. Some services may
reject requests without an agent.

Plex, Jellyfin and Emby also require client/device metadata. Configure it with
`outbound_client_name`, `outbound_client_id`, `outbound_client_version`,
`outbound_device_name`, `outbound_device_id` and `outbound_platform`. Defaults
are `Media Client`, `media-client`, `1.0`, `Media Client`, `media-client` and
`Desktop`, respectively. Plex uses the client ID for authentication, scanning
and metadata requests; Jellyfin/Emby use the device ID in their authentication
metadata. Fields are used only where the protocol supports them. Changing IDs
can appear as a different client/device in the media server.

All these settings are available under Network & Connectivity in the dashboard.
The dashboard shows saved values with defaults resolved. Restart applies the
settings together; saving does not change the running identity. Values must be
printable ASCII, at most 2048 characters; client/device fields cannot contain
quotes or backslashes. Authentication tokens and protocol header names remain
unchanged, including DMM's required `X-Zurg-Token` credential.

Provider/indexer clients remove `Referer`, `Origin` and `X-Zurg*` headers before
sending requests, including redirects. Redirects cannot disclose preceding
URLs' private paths or API-key query parameters through a Referer. Authentication,
range requests, provider cookies and redirect limits remain in place. No
application client/device identifiers are added to these requests.

NNTP sends `AUTHINFO USER`, `AUTHINFO PASS`, `BODY`, `STAT`, `DATE` and `QUIT` as
needed, with no software-identification command. There is no NNTP software ID
to configure. Usernames/passwords remain in each provider's NNTP configuration.
TLS and plaintext transcript tests cover authentication, article access,
keep-alive and shutdown.

This minimizes explicit application identifiers; it does not provide anonymity.
Remote services still see credentials, source IPs, requested content and timing.
TLS/HTTP behavior, custom identities, application-registered API keys and access
patterns (including Real-Debrid network-test links) can support correlation.
Externally supplied URLs, torrent metadata, article IDs, share payloads and
exported log/config contents are not rewritten. Software download URLs identify
the software being requested. External players and separately launched tools
use their own settings.

Socket-level regression tests cover defaults, custom and omitted agents,
redirects, preserved authentication and media-server metadata. Config/dashboard
tests cover validation, YAML round trips and applying settings at restart.
