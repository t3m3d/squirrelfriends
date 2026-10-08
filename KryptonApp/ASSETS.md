# Bundled assets

## Woodland background

- File: `resources/woodland-background.jpg`
- Source: user-provided `../SquirrelPics/background.jpg`, copied unchanged.
- Displayed behind the collection with opaque panels to preserve text contrast.
- The supplied image includes Adobe Stock preview watermarks and asset number 246303918. No stock license documentation was provided; retain this provenance when preparing release assets.

## Earlier Eastern gray squirrel illustration (retained, no longer displayed)

- File: `resources/eastern-gray-squirrel.png`
- Created September 24, 2026 using the built-in OpenAI image-generation tool.
- Original illustration generated for Squirrel Friends; no reference image supplied.
- The generated PNG is bundled unchanged. It is not a documentary photograph.

Prompt:

> Use case: illustration-story. Asset type: original squirrel illustration for the Squirrel Friends native iOS app. Create a polished natural-history watercolor and colored-pencil illustration of a single Eastern gray squirrel (Sciurus carolinensis), anatomically believable, soft silver-gray fur, white belly, full bushy tail curving upward, small rounded ears, dark alert eye. The entire squirrel including tail is visible, seated naturally on a mossy fallen oak branch, three-quarter side view. Quiet woodland backdrop in soft sage and warm cream, gentle natural daylight, subtle paper texture, calm welcoming mood. Square composition with generous breathing room around the animal so it can also crop into a wide app card. Beautiful detailed fur and restrained forest-green palette complementing a cream and deep-green app. No clothing, no human hands, no text, no logos, no watermark. This is illustration, not a photograph.

## Gray squirrel field recording

- File: `resources/gray-squirrel-call.mp3`
- Duration: approximately 65.88 seconds; stereo MP3, 44.1 kHz.
- Recordist: Aubrey John Williams. Copyright: The British Library Board.
- Recorded July 31, 1977 in Camberley, Surrey, England.
- Shelfmark: W1CDR0001470 BD12.
- [Source](https://commons.wikimedia.org/wiki/File:Grey_Squirrel_(Sciurus_carolinensis)_(W1CDR0001470_BD12).ogg)
- [CC BY-SA 4.0 license](https://creativecommons.org/licenses/by-sa/4.0/)
- Wikimedia Commons supplied the MP3 transcode; Squirrel Friends made no further audio edits.
- The recording's license and attribution also appear in the app and in `resources/RECORDING-CREDITS.txt`.

## User-supplied squirrel photos

The following originals were copied byte-for-byte from `../SquirrelPics/` into `resources/`. UIImageView uses aspect fit so each full photo and any printed credits remain visible. These photos are independent from the British Library field recording. No species identification is assigned to the general gallery.

| File | Placement | Credit visible on the supplied image |
| --- | --- | --- |
| `peeking.jpg` | Main recording cover | Linda Black; www.nwf.org/PhotoContest |
| `happy.jpg` | Gallery: Hello there | Christine Haines |
| `itsmesquirrel.jpg` | Gallery: Reaching up | None visible |
| `reach.jpg` | Gallery: Tree acrobat | None visible |

The user authorized use of these files in the app. No further authorship or license claims are made here. Gallery descriptions and credit strings are stored in `resources/photos.json`.

## Additional squirrel recordings

Sources and reuse terms checked September 24, 2026. All three recordings are bundled for offline playback. Denali has a volume adjustment described below; Yellowstone and Michigan have no further audio edits. File SHA-256 hashes and measured durations are stored in `resources/animals.json`.

### Yellowstone chatter

- File: `resources/red-squirrel-yellowstone.mp3`
- Duration: approximately 12.532 seconds (MP3).
- NPS / Shan Burson. Red Squirrel, Yellowstone National Park. Source creation date: March 20, 2004. Public domain U.S. Government recording; downloaded as MP3 without further edits. No claim to original U.S. Government works. No NPS endorsement is implied.
- [Source](https://www.nps.gov/yell/learn/photosmultimedia/sounds-redsquirrel.htm) · [Reuse terms](https://www.nps.gov/aboutus/disclaimer.htm)
- [Downloaded MP3](https://www.nps.gov/nps-audiovideo/legacy/mp3/imr/avElement/yell-YELLSGYredsquirrel2004320.mp3)

### Michigan morning chatter

- File: `resources/red-squirrel-michigan.mp3`
- Duration: approximately 44.304 seconds (MP3).
- Red_Squirrel_chatter.wav by philberts on Freesound. Recorded in Silver City, Michigan, USA; uploaded January 4, 2011 (recording year unspecified). CC0 1.0. Bundled file is Freesound’s publicly available HQ MP3 preview of the original WAV; no further audio edits. No endorsement is implied.
- [Source](https://freesound.org/people/philberts/sounds/111393/) · [Reuse terms](https://creativecommons.org/publicdomain/zero/1.0/)
- [Downloaded MP3](https://cdn.freesound.org/previews/111/111393_835438-hq.mp3)

### Denali calls

- Playback file: `resources/ground-squirrel-denali-boosted.wav`
- Original retained unchanged: `resources/ground-squirrel-denali.mp3` (SHA-256 `7d52d0262899d10d95eb8a874b06cd3c4094637b7c54505a3eb8b21d343bdbdb`).
- Duration: approximately 7.706122 seconds (mono, 44.1 kHz, 16-bit PCM WAV).
- National Park Service. Ground Squirrel, recorded at Denali National Park & Preserve, Alaska. Public domain per the NPS Sound Gallery. Volume increased by 6.79 dB to a -2 dBFS sample peak; decoded from the NPS MP3 and saved as 16-bit PCM WAV. No trimming, compression, or noise reduction. No claim to original U.S. Government works. No NPS endorsement is implied. The audio source does not identify the species.
- [Source](https://www.nps.gov/subjects/sound/sounds-ground-squirrel.htm) · [Reuse terms](https://www.nps.gov/subjects/sound/gallery.htm)
- [Downloaded MP3](https://www.nps.gov/nps-audiovideo/legacy/mp3/nri/avElement/nri-GroundSquirrelDENA.mp3)
