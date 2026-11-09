# announcements

Optional extras for Beamtalk's typed Observer framework.

The core of the framework (`Announcement`, `Announcer`, `SystemAnnouncer`,
`Subscription`) ships in the Beamtalk standard library. This package adds the
parts most programs don't need (ADR 0093, Layer 3):

- **`RecordingAnnouncer`**: a test double that records announcements instead of
  dispatching them.
- **`AnnouncementTelemetry`**: a bridge that re-emits announcements as
  `telemetry` events, for metrics exporters, LiveDashboard and
  `opentelemetry_telemetry`.

Hardened distributed delivery (netsplit tolerance, buffering and replay,
workspace clusters) is planned separately (BT-4600).

## Install

```bash
beamtalk deps add announcements --git https://github.com/jamesc/beamtalk-announcements
```

## RecordingAnnouncer

Pass a `RecordingAnnouncer` to the code under test wherever it expects an
`Announcer`, then assert on what it announced. Subscribers never run.

```beamtalk
recorder := RecordingAnnouncer new
shop := Shop announcer: recorder
shop changePrice: 42

recorder hasAnnounced: PriceChanged             // => true
(recorder announcementsOf: ShopEvent) size      // subclasses match too
recorder announcements                          // every event, oldest first
recorder reset                                  // clear the log, keep subscriptions
```

`announce:`, `announceAndWait:` and `announceAndWait:timeout:` all record.
Subscribing works as on a real `Announcer`, so `subscriptionCount` and
`subscribersOf:` show what the code under test subscribed to.

The log belongs to the process that created the recorder and goes away when
that process exits. Any process may announce into it.

## AnnouncementTelemetry

Measure with `telemetry`, react with announcements. When one event should feed
both, forward it:

```beamtalk
sub := AnnouncementTelemetry forward: ShopEvent from: announcer
// each ShopEvent now also emits #(#beamtalk, #announcement, <its class name>)

AnnouncementTelemetry forward: ShopEvent from: announcer prefix: #(#shop, #events)

sub unsubscribe
```

Each announcement becomes one `Telemetry execute:` event:

| Part | Value |
|---|---|
| name | `prefix ++ #(<event class name>)`, using the event's own class |
| measurements | `#{#count => 1, #system_time => <native units>}` |
| metadata | `#{#announcement => <the event>, #class => <its class>}` |

The bridge is an ordinary subscription, so it lasts as long as the process that
created it. Start a long-lived bridge from an actor or supervisor child.

## Development

```bash
just build
just test
just ci     # fmt + lint + build + test
```
