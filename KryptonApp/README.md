# Squirrel Friends — Krypton

The Krypton version is a native iPhone/iPad app. Its screens, interaction, catalog loading, favorites, and audio logic are written in Krypton and call Apple’s UIKit/Foundation/AVFoundation APIs through the existing Objective-K bridge. It builds as a regular self-contained iOS app; it does not interpret downloaded code.

The one species and recording catalog is data-driven. Add a species and its recording entries to `resources/animals.json`; each recording has a stable ID, title, description, original source, license, and exact attribution. The app has a personal recording slot available through **Files**. Imported audio is saved on this device and shown separately from the attributed library recording.

## Build on macOS

Requires Apple Silicon, Xcode with an iOS simulator runtime, and the Krypton repository at `../krypton` (or pass its location explicitly):

```sh
python3 scripts/build.py
```

Set a distinct development or distribution identifier with `--bundle-id`. The simulator build is ad-hoc signed. A device build can be produced using `--target device`; it still needs your Apple developer signing identity and provisioning profile before installation or App Store upload.

In Xcode, boot an iPhone simulator, open **Devices and Simulators**, and install `build/simulator/SquirrelFriends.app`. Or use `xcrun simctl install booted build/simulator/SquirrelFriends.app` followed by `xcrun simctl launch booted org.squirrelfriends.app`.

## Recording and license

The bundled gray squirrel audio has not been downloaded, so its play control stays disabled. The entry identifies Aubrey John Williams’s British Library recording and links to the Commons source and CC BY-SA 4.0 terms. Add the licensed source file as `resources/gray-squirrel-call.mp3` before packaging to enable it. If you redistribute a modified copy, record what you changed and meet the share-alike attribution terms. No substitute sound is presented as this wildlife recording.

The personal Files import accepts playable audio the user already has. The app does not identify or verify imported recordings; sharing them may require the creator’s permission and credit. No audio is uploaded.

## Current scope

- Native UIKit interface, adapted to iPad and Dynamic Type.
- Discovery, saved favorites, and wildlife listening guidance.
- Recording source and Creative Commons license links.
- Local file import for a personal recording.
- Local audio playback, pause, skip by 10 seconds, and interruption pause.
- Favorites stored on device; no account, server, analytics, microphone, or location access.
- Expansion-ready catalog; additional species require catalog and attributed sound data, not a new screen implementation.

The Krypton compiler in this repository documents and verifies iOS targets. Android still requires an Android compiler/runtime path, so this Krypton version currently targets Apple devices.
