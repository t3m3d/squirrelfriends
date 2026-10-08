#!/usr/bin/env python3
"""Exercise the actual Krypton playback callbacks in a disposable simulator app."""
import argparse
import json
from pathlib import Path
import selectors
import shutil
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument('--krypton-root', required=True)
parser.add_argument('--simulator', required=True, help='UUID of a booted iOS simulator')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
bundle = 'org.squirrelfriends.media-check'
probe = '''
let mediaIndex = 0
let mediaCompleting = 0
// Start after launch so activation does not interrupt the synthetic play tap.
func mediaButton(index) {
    let i = 0
    while i < msg(mediaButtons, "count") {
        let candidate = msg_1(mediaButtons, "objectAtIndex:", i)
        if msg(candidate, "tag") == index { emit candidate }
        i += 1
    }
    emit 0
}
func mediaStart(self, cmd, timer) {
    playTapped(self, 0, playButton)
    msg_timer(cls("NSTimer"), "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:", 3000, self, "mediaCheck:", 0, 0)
    emit 0
}
func mediaCheck(self, cmd, timer) {
    if player == 0 { kp("MEDIA_CHECK_FAIL: no audio player") emit 0 }
    let button = mediaButton(mediaIndex)
    if button == 0 { kp("MEDIA_CHECK_FAIL: missing recording control") emit 0 }
    if mediaCompleting == 1 {
        if msg(player, "isPlaying") != 0 { kp("MEDIA_CHECK_FAIL: completion did not stop") emit 0 }
        if msg_1(msg(button, "currentTitle"), "isEqualToString:", nsString("Play recording")) != 1 {
            kp("MEDIA_CHECK_FAIL: completion label did not reset") emit 0
        }
        playTapped(self, cmd, button)
        if msg(player, "isPlaying") == 0 { kp("MEDIA_CHECK_FAIL: replay after completion failed") emit 0 }
        pausePlayback()
        kp("MEDIA_CHECK_PASS: all bundled recordings played, paused, resumed and switched; completion and four photos passed")
        emit 0
    }
    kp("MEDIA recording: " + mediaIndex)
    kp("MEDIA elapsed: " + audioSeconds("currentTime"))
    kp("MEDIA duration: " + audioSeconds("duration"))
    if msg(player, "isPlaying") == 0 { kp("MEDIA_CHECK_FAIL: playback not active") emit 0 }
    if audioSeconds("currentTime") <= 0 { kp("MEDIA_CHECK_FAIL: audio did not advance") emit 0 }
    let expected = msg(field(msg_1(recordings, "objectAtIndex:", mediaIndex), "durationSeconds"), "integerValue")
    let difference = audioSeconds("duration") - expected
    if difference < -1 || difference > 1 { kp("MEDIA_CHECK_FAIL: wrong recording duration") emit 0 }
    let image = msg_1(cls("UIImage"), "imageNamed:", field(msg_1(recordings, "objectAtIndex:", 0), "artwork"))
    if image == 0 { kp("MEDIA_CHECK_FAIL: image did not decode") emit 0 }
    let photoIndex = 0
    while photoIndex < msg(galleryItems, "count") {
        image = msg_1(cls("UIImage"), "imageNamed:", field(msg_1(galleryItems, "objectAtIndex:", photoIndex), "filename"))
        if image == 0 { kp("MEDIA_CHECK_FAIL: gallery photo did not decode") emit 0 }
        photoIndex += 1
    }
    if msg(galleryItems, "count") != 3 { kp("MEDIA_CHECK_FAIL: missing supplied photos") emit 0 }
    galleryNext(self, cmd, 0)
    if galleryIndex != 1 || msgPointX(galleryScroll, "contentOffset", 0) != 346 {
        kp("MEDIA_CHECK_FAIL: next photo failed") emit 0
    }
    galleryNext(self, cmd, 0)
    if msg(galleryNextButton, "isEnabled") != 0 { kp("MEDIA_CHECK_FAIL: next should stop at last photo") emit 0 }
    galleryBack(self, cmd, 0)
    galleryBack(self, cmd, 0)
    if galleryIndex != 0 || msg(galleryBackButton, "isEnabled") != 0 {
        kp("MEDIA_CHECK_FAIL: back should stop at first photo") emit 0
    }
    pausePlayback()
    if msg(player, "isPlaying") != 0 { kp("MEDIA_CHECK_FAIL: pause failed") emit 0 }
    if msg_1(msg(button, "currentTitle"), "isEqualToString:", nsString("Play recording")) != 1 {
        kp("MEDIA_CHECK_FAIL: pause label did not reset") emit 0
    }
    playTapped(self, cmd, button)
    if msg(player, "isPlaying") == 0 { kp("MEDIA_CHECK_FAIL: resume failed") emit 0 }
    if mediaIndex + 1 < msg(recordings, "count") - 1 {
        let previous = player
        objc_retain(previous)
        mediaIndex += 1
        let next = mediaButton(mediaIndex)
        playTapped(self, cmd, next)
        if msg(previous, "isPlaying") != 0 { kp("MEDIA_CHECK_FAIL: old recording still playing") emit 0 }
        if msg_1(msg(button, "currentTitle"), "isEqualToString:", nsString("Play recording")) != 1 {
            kp("MEDIA_CHECK_FAIL: old card label not reset") emit 0
        }
        audioFinished(self, cmd, previous, 1)
        if msg(player, "isPlaying") == 0 { kp("MEDIA_CHECK_FAIL: old completion paused new audio") emit 0 }
        objc_release(previous)
        msg_timer(cls("NSTimer"), "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:", 2500, self, "mediaCheck:", 0, 0)
    } else {
        mediaCompleting = 1
        msg_d1(player, "setCurrentTime:", audioSeconds("duration") - 1)
        msg_timer(cls("NSTimer"), "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:", 3000, self, "mediaCheck:", 0, 0)
    }
    emit 0
}
'''

with tempfile.TemporaryDirectory(prefix='squirrel-media-test-') as folder:
    stage = Path(folder)
    for name in ('src', 'resources', 'scripts'):
        shutil.copytree(root / name, stage / name)
    main = stage / 'src/main.ks'
    text = main.read_text()
    assert text.count('just run {') == 1
    assert text.count('    doIosShow(win)') == 1
    text = text.replace('let activePlayButton = 0', 'let activePlayButton = 0\nlet mediaButtons = 0')
    text = text.replace('    doIosBackground(play, forest())', '''    if mediaButtons == 0 { mediaButtons = allocInit("NSMutableArray") }
    msg_1(mediaButtons, "addObject:", play)
    doIosBackground(play, forest())''')
    text = text.replace('just run {', probe + '\njust run {')
    text = text.replace('    objc_registerClassPair(c)',
        '    class_addMethod(c, sel("mediaCheck:"), funcptr(mediaCheck), "v@:@")\n    class_addMethod(c, sel("mediaStart:"), funcptr(mediaStart), "v@:@")\n    objc_registerClassPair(c)')
    text = text.replace('    doIosShow(win)', '''    doIosShow(win)
    msg_timer(cls("NSTimer"), "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:", 1500, self, "mediaStart:", 0, 0)''')
    main.write_text(text)
    subprocess.run(['python3', str(stage / 'scripts/build.py'), '--krypton-root', args.krypton_root,
                    '--bundle-id', bundle], check=True)
    sim = ['xcrun', 'simctl']
    subprocess.run(sim + ['install', args.simulator, str(stage / 'build/simulator/SquirrelFriends.app')], check=True)
    process = None
    try:
        process = subprocess.Popen(sim + ['launch', '--console', args.simulator, bundle],
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)
        output = b''
        deadline = time.monotonic() + 25 + 4 * sum(len(animal['sounds']) for animal in json.loads((root / 'resources/animals.json').read_text()))
        while time.monotonic() < deadline:
            if selector.select(timeout=1):
                chunk = process.stdout.read1(8192)
                if not chunk:
                    break
                output += chunk
                print(chunk.decode(errors='replace'), end='', flush=True)
                if b'MEDIA_CHECK_PASS:' in output or b'MEDIA_CHECK_FAIL:' in output:
                    break
        if b'MEDIA_CHECK_PASS:' not in output:
            raise SystemExit('Media smoke check failed or timed out')
    finally:
        subprocess.run(sim + ['terminate', args.simulator, bundle], capture_output=True)
        if process is not None:
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=5)
        subprocess.run(sim + ['uninstall', args.simulator, bundle], check=True)
