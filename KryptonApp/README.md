# Squirrel Friends — Krypton

The Krypton version is a native iOS prototype, currently tested on the iPhone 17 Pro simulator. Its screens, interaction, catalog loading, favorites, and audio logic are written in Krypton and call Apple’s UIKit/Foundation/AVFoundation APIs through the existing Objective-K bridge. It builds as a regular self-contained iOS app; it does not interpret downloaded code.

The catalog contains four recordings across three squirrel groups and is data-driven. Add a species and its recording entries to `resources/animals.json`; each recording has a stable ID, title, description, original source, license, and exact attribution. The app has a personal recording slot available through **Files**. Imported audio is saved on this device and shown separately from the attributed library recordings.

## Build on macOS

Requires Apple Silicon, Xcode with an iOS simulator runtime, and the Krypton repository at `../../krypton` (or pass its location explicitly):

```sh
python3 scripts/build.py
```

Set a distinct development or distribution identifier with `--bundle-id`. The simulator build is ad-hoc signed. A device build can be produced using `--target device`; it still needs your Apple developer signing identity and provisioning profile before installation or App Store upload.

In Xcode, boot an iPhone simulator, open **Devices and Simulators**, and install `build/simulator/SquirrelFriends.app`. Or use `xcrun simctl install booted build/simulator/SquirrelFriends.app` followed by `xcrun simctl launch booted org.squirrelfriends.app`.

## Recordings and licenses

The app includes a roughly 66-second gray squirrel field recording by Aubrey John Williams, recorded in Camberley, England on 31 July 1977. Copyright belongs to The British Library Board; the recording is licensed CC BY-SA 4.0. The bundled `gray-squirrel-call.mp3` is Wikimedia Commons' MP3 transcode, with no further audio edits. Source, credits, and license controls are available on the recording card; `resources/RECORDING-CREDITS.txt` also ships in the app.

Three additional clips are bundled: Yellowstone red squirrel chatter (about 13 seconds, NPS / Shan Burson, public domain), Michigan American red squirrel chatter (about 44 seconds, philberts on Freesound, CC0), and Denali ground squirrel calls (about 8 seconds, NPS, public domain). The Michigan file is Freesound's public HQ MP3 preview, not the original WAV. The Denali audio source does not specify the species. Its playback copy has a 6.79 dB volume boost with a -2 dBFS sample peak; the original MP3 is retained. The collection groups cards by their sound-type category (currently Field calls and Chatter), with personal audio in its own section. Additional category labels in the catalog become sections automatically. Each card links its own source and reuse terms; `ASSETS.md` and `resources/RECORDING-CREDITS.txt` document provenance. Cards display approximate durations, and the build validates audio files and their recorded checksums.

The user-supplied `peeking.jpg` is the recording cover. `happy.jpg`, `itsmesquirrel.jpg`, and `reach.jpg` appear in a swipeable Squirrel Moments gallery with Back/Next controls. All images are bundled offline and shown in full, preserving printed credits. Photo provenance is documented in `ASSETS.md`. These photos are separate from the field recording; they do not identify its recorded animal. The earlier generated illustration is retained as an unused resource.

The personal Files import accepts playable audio the user already has. The app does not identify or verify imported recordings; sharing them may require the creator’s permission and credit. No audio is uploaded.

New chirping, barking, and eating candidates are documented in `AUDIO-SOURCES.md`; they are not yet bundled because local download access is blocked.

## Current scope

- Native UIKit interface with a vertically scrolling collection and photo recording cards and a photo gallery.
- A collection, persistent favorite toggles, and wildlife listening guidance.
- Recording source and reuse-terms links.
- Local file import for a personal recording.
- Offline audio playback, pause/resume, completion-label reset, and interruption pause.
- Favorites stored on device; no account, server, analytics, microphone, or location access.
- The screen renders every catalog recording; add species and attributed recordings to `resources/animals.json`. An optional `artwork` filename, `artworkHeight`, and `artworkDescription` configure that species’ cover. `resources/photos.json` configures the general squirrel gallery separately from species recordings.

The Krypton compiler in this repository documents and verifies iOS targets. Android still requires an Android compiler/runtime path, so this Krypton version currently targets Apple devices.

## Verification and remaining work

Run the simulator media smoke check against a booted simulator:

```sh
python3 tests/check_media.py --krypton-root ../../krypton --simulator SIMULATOR_UUID
```

The check builds a disposable test app from the current Krypton source, exercises its real playback callbacks, checks that every bundled recording advances, pause and resume, verifies switching and completion, and verifies that UIKit decodes the four supplied photos and that gallery navigation stops at the first and last photo. It removes the test app afterward. It does not modify personal recordings or favorites in the normal app.

The current screen uses a 390-point frame-based layout. Smaller screens, landscape, iPad, and Dynamic Type still need layout work and validation. Personal Files import remains implemented but has not yet been exercised end to end. Device signing, app icons, and App Store release preparation are still pending.
