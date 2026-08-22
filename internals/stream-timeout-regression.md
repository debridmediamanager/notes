# Proxied stream timeout regression

## Summary

Zurg used `download_timeout_secs` as a wall-clock deadline for proxied HTTP
downloads. Its default is 15 seconds, so any single upstream response whose body
took longer than 15 seconds to finish was cut off even while bytes were arriving
normally.

The defect was reported on Discord on 2026-08-21 against
`2026.08.21.0151-nightly` (`fc2a21f`). Repeated 2 GB ranged requests through zurg
ended at 15.001 seconds after delivering about 1.26 GB at 84 MB/s. The same range
completed directly from Real-Debrid, and raising `download_timeout_secs` to 3600
let the request finish through zurg in 25.8 seconds.

This was a zurg regression, not content filtering, a CDN failure, or a regression
in `fc2a21f`. Commit `6edeaa8c` (`Optimize client`, 2024-11-17) introduced it. The
plain proxied serving path was fixed by `41db7245`, and `eff972b8` then made the
same mistake difficult to reintroduce at the provider API boundary.

## User impact

The affected path was any response body that zurg proxied from an HTTP-backed
debrid provider and that remained open longer than `download_timeout_secs`.
Real-Debrid was affected from November 2024. TorBox and AllDebrid inherited the
same behavior when those providers were added. Locally served NZB reads never
passed through the HTTP download client and were not affected.

The user-visible symptoms included:

- Infuse or another direct WebDAV client freezing during playback;
- playback failing after a seek opened a new ranged request;
- a download ending early despite receiving HTTP `206 Partial Content`; and
- client errors that appeared to implicate the media file or CDN even though a
  direct request completed normally.

The player did not necessarily fail 15 seconds after playback started. At the
reported 84 MB/s, zurg transferred roughly 1.26 GB before the deadline. A player
could consume that buffer for several minutes before it ran dry, which turned an
exact 15-second network cutoff into an apparently variable playback freeze.

## Root cause

Go's `http.Client.Timeout` is a deadline for the entire request lifecycle. It is
not an inactivity or stall timeout. The clock starts when the request begins and
continues while the response body is read, regardless of whether data is flowing.

Before `6edeaa8c`, the download client itself had no whole-request timeout:

```go
client: &http.Client{}
```

`download_timeout_secs` bounded the connection and response-header phases through
the transport's dialer and `ResponseHeaderTimeout`. Once the response body arrived,
the serving path could keep reading for as long as the downstream client needed.

`6edeaa8c` reorganized the HTTP transport and added the configured timeout to the
client itself while removing `ResponseHeaderTimeout`:

```go
client.client = &http.Client{
    Transport: transport,
    Timeout:   time.Duration(timeoutSecs) * time.Second,
}
```

That changed the meaning of the existing 15-second value. It still protected the
connection phase, but it now also imposed an absolute deadline on the response
body. The serving path already fetched media through this client, so the regression
became live as soon as this change landed.

The failure was quiet. Zurg sent the successful upstream status and headers before
copying the body to the player. When the client's deadline interrupted the body,
the copy operation returned an error, but the serving path discarded that error:

```go
n, _ = copyBuffered(resp, body)
```

By then the `206` response was already committed and could not be replaced with an
error status. With request logging disabled, nothing reported why the body was
short. The downstream client therefore saw a successful partial-content response
whose body ended before its advertised length.

## Regression history

The relevant commits form a longer chain than the nightly where the issue was
reported:

| Date | Commit | Effect |
|---|---|---|
| 2024-06-28 | `c3aea427` | Routed the existing serving read through `DownloadFile`. This was behavior-preserving because the download client still had no whole-request timeout. |
| 2024-11-17 | `6edeaa8c` | Added `http.Client.Timeout` to the download client. This is the regression that began truncating ordinary proxied bodies. |
| 2026-02-26 | `dea98d34` | Correctly diagnosed the same 15-second cutoff for RAR archive reads, added a timeout-free streaming client, and moved only the RAR path to it. Ordinary file serving remained on `DownloadFile`. |
| 2026-08-02 | `e9318e66` | Moved downloads behind the multi-provider `debrid.Provider` interface and carried the ordinary serving call forward unchanged. It did not create the Real-Debrid bug, though new HTTP-backed providers inherited the unsafe method. |
| 2026-08-21 | `fc2a21f` | The nightly used in the report. It contained the bug but did not introduce it. |
| 2026-08-21 | `41db7245` | Changed ordinary proxied playback to use `DownloadFileStreaming` and added the first end-to-end timeout regression test. |
| 2026-08-21 | `eff972b8` | Made every HTTP provider's `DownloadFile` timeout-free as a structural guard and expanded coverage to Real-Debrid, AllDebrid, TorBox, and an NZB control. |

The February RAR fix is the important near miss. Its commit message explicitly
states that `http.Client.Timeout` covers the body and that the 15-second default was
killing RAR streams. The diagnosis was correct, but the fix was scoped to the RAR
reader. Keeping separate `DownloadFile` and `DownloadFileStreaming` methods allowed
the ordinary serving path to retain the unsafe choice for another six months.

## Why it stayed hidden

Several effects concealed the regression for about 21 months:

1. Most media-server deployments read zurg through rclone rather than direct
   WebDAV. rclone uses bounded ranged requests. The current managed-mount defaults
   start at 4 MB and grow to a 512 MB limit, so on a fast connection many individual
   upstream requests finish inside 15 seconds. This reduced exposure; it did not
   make the path safe, particularly on slower links.
2. Direct WebDAV clients such as Infuse can issue large or open-ended ranges. Those
   requests keep one upstream response alive long enough to hit the deadline
   reliably, which is why the Discord reproduction was exact at three different
   offsets.
3. Playback buffering separated cause from symptom. The upstream request died at
   15 seconds, but playback stopped only after the player consumed the bytes already
   delivered. The visible delay varied with bitrate, buffering, and seeks.
4. The response looked successful. The CDN returned a valid `206`, zurg forwarded
   it, and the body-copy error was ignored after headers were sent. Direct CDN tests
   stayed healthy and normal logs contained no timeout error.
5. Raising the setting appeared to solve the problem. That made the defect look
   like an undersized tuning value rather than a timeout attached to the wrong
   abstraction.
6. Existing tests used bodies or ranges that completed inside the configured
   timeout. No test deliberately kept a response body flowing beyond the deadline
   and then asserted the complete length and checksum through the serving path.
7. The narrow RAR fix removed the most obvious earlier manifestation without
   removing the unsafe default from ordinary downloads.

## Why a higher timeout appeared to fix it

Changing the setting to 3600 seconds did not change what the timeout covered. It
only moved the wall-clock deadline far enough away for the reported 25.8-second
transfer to finish:

```text
15 seconds   < 25.8-second transfer < 3600 seconds
```

This was a workaround, not a safe fix. Any finite whole-request timeout can still
cut off a sufficiently long body, including a slow client or a paused connection.
The setting also feeds the download client's dial timeout and bounded verification
requests, so increasing it to an hour can make an unreachable host take far longer
to fail. Fixed builds should use the normal configured value; it no longer caps a
proxied media body.

## Fix and guardrails

The immediate fix in `41db7245` changed `streamFileToResponse` to fetch through
`Provider.DownloadFileStreaming`. That client shares the same transport but has no
`http.Client.Timeout`, so body lifetime is no longer tied to
`download_timeout_secs`. The request still uses the downstream request context, so
disconnecting the player cancels the upstream read. Connection establishment and
TLS handshaking remain bounded by the transport.

`eff972b8` then removed reliance on every caller choosing the method with
"Streaming" in its name:

- Real-Debrid's `DownloadFile` now uses `DoStreaming`.
- The shared `debrid.DownloadRanged` helper accepts `StreamingDoer`, which exposes
  only `DoStreaming`; AllDebrid and TorBox use this helper.
- Both provider download methods are therefore safe for a long response body.
- Bounded non-playback reads, such as the two 64 KiB reads used for an OpenSubtitles
  hash, receive their own explicit context deadline instead of borrowing an unsafe
  client-wide body timeout.

The regression tests in `internal/universal/stream_timeout_test.go` use a local
server that sends a 1.6 MB body in 16 chunks over about 1.6 seconds while the
configured timeout is one second. They assert both full length and checksum:

- directly through both provider download methods for Real-Debrid, AllDebrid, and
  TorBox;
- end to end through `streamFileToResponse` for all three HTTP-backed providers;
  and
- through an NZB-shaped local provider as an unaffected control.

The invariant is now explicit: a method that returns a download body must never use
a whole-request timeout. Short probes and metadata reads should carry a deadline on
their own context; streaming bodies should live until completion, downstream
cancellation, or a real transport error.
