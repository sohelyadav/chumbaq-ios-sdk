# Chumbaq iOS SDK

Deep linking, deferred deep links, events, in-app messages,
banners, and push notifications for Chumbaq.

Requires iOS 14. No external dependencies — `URLSession` and `Foundation`
only.

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/sohelyadav/chumbaq-ios-sdk", from: "0.1.0")
```

Four products; `ChumbaqCore` is the only mandatory one, and each of the
others depends on it. Take only what the app uses:

| Product | What it does |
|---|---|
| `ChumbaqCore` | Identity, events, deep links, deferred matching, offline queue, sessions |
| `ChumbaqPush` | APNs token registration, campaign engagement, rich notification rendering |
| `ChumbaqBanners` | `BannerCarouselView`, a native carousel of a widget's banners |
| `ChumbaqMessages` | In-app messages: modal, sheet, full screen, and top and bottom banners |

## Getting started

```swift
import ChumbaqCore

let config = ChumbaqConfig.Builder(
    baseUrl: "https://your-chumbaq-host",
    apiKey: "<project API key>",
    projectId: "<project id>"
).build()

Chumbaq.shared.initialize(config: config)

// Where a deep link should take the app.
Chumbaq.shared.onDeepLink = { result in
    router.go(result)
}
```

Then, from the app's own entry points:

```swift
// A universal link or custom-scheme URL.
Chumbaq.shared.handleDeepLink(url: url)

// After a fresh install, to claim the click that led to it.
let match = await Chumbaq.shared.matchDeferredDeepLink()

// Who this is, once they log in.
try await Chumbaq.shared.identify(
    IdentifyParams.Builder().externalUserId("u_42").build()
)
```

## In-app messages

```swift
import ChumbaqMessages

ChumbaqMessages.shared.messageListener = self

ChumbaqMessages.shared.onAppOpen()              // app foreground
ChumbaqMessages.shared.onScreenView("Home")     // screen change
ChumbaqMessages.shared.onEvent("purchase")      // custom event
```

The SDK draws the message itself, in whichever of the five layouts the
campaign chose, with its picture, its theme and its buttons. A tapped
`deep_link` or `url` button is opened after `onButtonAction` runs, so an app
that routes its own links should do it there.

## Push notifications

```swift
import ChumbaqPush

ChumbaqPush.shared.initialize()
try await ChumbaqPush.shared.registerToken(deviceToken)   // Data or String

// From the app's own notification handlers — the SDK never intercepts a
// notification, it reports what it is handed.
ChumbaqPush.shared.reportNotificationDelivered(userInfo: userInfo)

// A tap, from `didReceive(_:withCompletionHandler:)`. Reports the click —
// carrying which button was pressed, when one was — and hands back where it
// leads, if anywhere.
if let destination = ChumbaqPush.shared.reportNotificationResponse(response) {
    router.go(destination)
}
```

### Rich notifications need two app extensions

No push provider carries an image, a carousel or a countdown natively, so
the client draws them — and on iOS the only things allowed to draw on a
notification are app extensions, which belong to the app rather than to a
library. The SDK supplies the contents of both; the targets are the app's.

| Extension | What it adds | Entry point |
|---|---|---|
| Notification **Service** | The campaign's image | `ChumbaqNotificationService.populate(_:withContentHandler:)` |
| Notification **Content** | Carousels and countdowns | `ChumbaqNotificationContent.makeView(for:)` |

Both files document exactly what the target and its `Info.plist` must say;
read them before creating the targets, because every way of getting it wrong
fails silently — the push simply arrives plain.

One thing is not an extension detail and has to be set on the campaign too:
**a campaign with no iOS category never matches a content extension**, so
the carousel never draws.

### Action buttons

A notification's buttons come from a `UNNotificationCategory` — iOS cannot
build them from a payload, it only draws the buttons of the category the
notification names. A campaign's buttons are authored in the dashboard, so
there is no category for them to name, and the notification **service**
extension above is what closes the gap: it registers a category carrying the
campaign's `chumbaq_actions` while the push is in flight. Add that extension
and the buttons appear; the host app's own categories are left untouched.

Which category they go onto matters when the campaign also names an iOS
category for a content extension (a carousel or a countdown). A notification
has only one category identifier, and the content extension is matched on
that string — so the buttons are registered **onto the category the campaign
names**, rather than onto an identifier of the SDK's own, and both the
buttons and the carousel survive. Only that category's actions are replaced;
its intent identifiers, options and hidden-preview copy are kept. Note that
a category is app-wide: while a campaign's buttons are attached to an
identifier, any other notification naming it shows them too.

Two things outside the SDK decide whether they ever get the chance:

- `aps` must carry `mutable-content: 1`, or iOS never wakes the extension.
- A pressed button is reported as `metadata.actionId`, matching Android, but
  only if the tap is reported through `reportNotificationResponse(_:)` (or
  `reportNotificationClicked(userInfo:actionIdentifier:)`). The plain
  `reportNotificationClicked(userInfo:)` cannot tell a button from the
  notification body, because `userInfo` does not say.

## Privacy: consent, do-not-track, deletion and export

These controls help you comply with India's DPDP Act.

### Consent and do-not-track

Consent travels with `identify`; a field you leave unset changes nothing on
the server.

```swift
try await Chumbaq.shared.identify(
    IdentifyParams.Builder()
        .externalUserId("u_42")
        .pushOptIn(false)    // no push to this device
        .emailOptIn(true)
        .smsOptIn(false)
        .doNotTrack(true)    // stop storing behavioural data from this device
        .build()
)
```

- `pushOptIn(false)` makes every push send skip this device. Left unset, push
  is allowed and the iOS notification permission governs.
- `doNotTrack(true)` stops the server storing events, sessions, location and
  campaign sources for this device. It still answers 2xx, so the offline queue
  does not retry. It does not block messages; the channel opt-ins decide those.
- It covers this device only. A person-wide objection is an owner action in
  the dashboard API, and the SDK cannot lift that, or any do-not-track set from
  the dashboard, with `doNotTrack(false)`.
- Every consent change is recorded with its source.
- Known gaps: there is no dedicated consent call (a change needs another
  `identify`); the SDK keeps sending events while do-not-track is on (the
  server drops them); it does not report the notification permission as
  `pushOptIn`, and does not send `whatsappOptIn` yet.

### Deleting or exporting a user's data

There is no SDK call for this, on purpose: the API key ships inside the app,
so anyone can extract it. Have your backend call the server API with a key
created with the server-only `privacy` permission. Never put that key in an
app; SDK routes refuse it.

```sh
curl -X POST https://your-chumbaq-host/api/privacy/erasures \
  -H 'x-api-key: <privacy key>' -H 'content-type: application/json' \
  -d '{"externalUserId": "u_42"}'
```

`POST /api/privacy/exports` takes the same body and returns the user's data.
For an anonymous device, send `{"deviceFingerprint": "..."}` (from
`Chumbaq.shared.deviceFingerprint`) instead. Records that cannot be tied to
one person are kept; the response lists them in `notErased` (`notIncluded`
for exports). After deleting a user, call `Chumbaq.shared.reset()` on the
device so it stops sending their id.

## Related SDKs

- [Android SDK](https://github.com/sohelyadav/chumbaq-android-sdk)
- [Flutter SDK](https://github.com/sohelyadav/chumbaq-flutter-sdk)

## License

Copyright 2026 The Chumbaq Authors.

Licensed under the [Apache License, Version 2.0](LICENSE).
