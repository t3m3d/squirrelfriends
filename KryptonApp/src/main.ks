#!/usr/bin/env kr
import "k:okui"
import "ui.k"

let controller = 0
let delegateObject = 0
let bodyStack = 0
let tabs = 0
let catalog = 0
let recordings = 0
let selected = 0
let player = 0
let playButton = 0
let clockLabel = 0
let statusLabel = 0
let scrubBack = 0
let scrubForward = 0
let playingID = 0

func defaults() { emit msg(cls("NSUserDefaults"), "standardUserDefaults") }
func isFavorite(sound) { emit msg_1(defaults(), "boolForKey:", field(sound, "id")) }
func documentsURL() {
    let manager = msg(cls("NSFileManager"), "defaultManager")
    emit msg(msg_2(manager, "URLsForDirectory:inDomains:", 9, 1), "firstObject")
}
func personalURL() { emit msg_1(documentsURL(), "URLByAppendingPathComponent:", nsString("personal-recording.audio")) }
func personalExists() {
    emit msg_1(msg(cls("NSFileManager"), "defaultManager"), "fileExistsAtPath:", msg(personalURL(), "path"))
}
func bundledURL(sound) {
    emit msg_2(msg(cls("NSBundle"), "mainBundle"), "URLForResource:withExtension:", field(sound, "filename"), 0)
}
func soundURL(sound) {
    if msg_1(field(sound, "id"), "isEqualToString:", nsString("personal-recording")) == 1 {
        if personalExists() == 1 { emit personalURL() }
        emit 0
    }
    emit bundledURL(sound)
}
func personalSound() {
    let sound = fresh("NSMutableDictionary")
    put(sound, "id", nsString("personal-recording"))
    put(sound, "title", nsString("My field recording"))
    put(sound, "description", nsString("Your own audio, stored on this device. Imported recordings are not verified or identified by the app."))
    put(sound, "credit", nsString("Imported by you. Keep the creator’s permission and credit with any audio you share. This file is not the British Library recording."))
    put(sound, "filename", nsString("personal-recording.audio"))
    emit sound
}
func alert(title, message) {
    let sheet = msg_3(cls("UIAlertController"), "alertControllerWithTitle:message:preferredStyle:", nsString(title), nsString(message), 1)
    msg_1(sheet, "addAction:", msg_3(cls("UIAlertAction"), "actionWithTitle:style:handler:", nsString("Got it"), 0, 0))
    msg_3(controller, "presentViewController:animated:completion:", sheet, 1, 0)
    emit 0
}
func clearBody() {
    playButton = 0
    clockLabel = 0
    statusLabel = 0
    scrubBack = 0
    scrubForward = 0
    let views = msg(bodyStack, "arrangedSubviews")
    let i = msg(views, "count")
    while i > 0 {
        i -= 1
        let view = msg_1(views, "objectAtIndex:", i)
        msg_1(bodyStack, "removeArrangedSubview:", view)
        msg(view, "removeFromSuperview")
    }
    emit 0
}
func pausePlayback() {
    if player != 0 { msg(player, "pause") }
    if playButton != 0 { buttonTitle(playButton, "Play recording") }
    emit 0
}
func stopPlayback() {
    if player != 0 {
        msg(player, "stop")
        objc_release(player)
        player = 0
    }
    playingID = 0
    emit 0
}
func paused(self, cmd, notice) { pausePlayback() emit 0 }
func routeChanged(self, cmd, notice) {
    let reason = field(msg(notice, "userInfo"), "AVAudioSessionRouteChangeReasonKey")
    if msg(reason, "integerValue") == 2 { pausePlayback() }
    emit 0
}
func timerTick(self, cmd, timer) {
    if player != 0 {
        if clockLabel != 0 {
            let elapsed = msg_fp(player, "currentTime")
            let duration = msg_fp(player, "duration")
            doIosText(clockLabel, "" + elapsed + "s / " + duration + "s")
        }
        if playButton != 0 {
            if msg(player, "isPlaying") == 0 { buttonTitle(playButton, "Play recording") }
        }
    }
    emit 0
}
func playTapped(self, cmd, sender) {
    let url = soundURL(selected)
    if url == 0 { alert("Recording not installed", "Add a recording from Files, or install the credited recording when it is available.") emit 0 }
    if player != 0 {
        if msg_1(playingID, "isEqualToString:", field(selected, "id")) == 1 {
            if msg(player, "isPlaying") == 1 { pausePlayback() emit 0 }
        } else { stopPlayback() }
    }
    let session = msg(cls("AVAudioSession"), "sharedInstance")
    msg_2(session, "setCategory:error:", nsString("AVAudioSessionCategoryPlayback"), 0)
    msg_2(session, "setActive:error:", 1, 0)
    if player == 0 {
        player = msg_2(msg(cls("AVAudioPlayer"), "alloc"), "initWithContentsOfURL:error:", url, 0)
        playingID = field(selected, "id")
    }
    if player == 0 { alert("Couldn’t play this audio", "Choose a supported MP3, M4A, or WAV recording and try again.") emit 0 }
    if msg(player, "play") == 1 { buttonTitle(playButton, "Pause recording") }
    else { alert("Playback unavailable", "The audio could not start. Please try a different recording.") }
    emit 0
}
func backTen(self, cmd, sender) {
    if player != 0 {
        let value = msg_fp(player, "currentTime") - 10
        if value < 0 { value = 0 }
        msg_d1(player, "setCurrentTime:", value)
        timerTick(self, cmd, 0)
    }
    emit 0
}
func forwardTen(self, cmd, sender) {
    if player != 0 {
        let value = msg_fp(player, "currentTime") + 10
        let duration = msg_fp(player, "duration")
        if value > duration { value = duration }
        msg_d1(player, "setCurrentTime:", value)
        timerTick(self, cmd, 0)
    }
    emit 0
}
func favoriteTapped(self, cmd, sender) {
    let index = msg(sender, "tag")
    let sound = msg_1(recordings, "objectAtIndex:", index)
    let value = 1
    if isFavorite(sound) == 1 { value = 0 }
    msg_2(defaults(), "setBool:forKey:", value, field(sound, "id"))
    if selected == 0 { renderLibrary() }
    else { renderDetail(selected) }
    emit 0
}
func selectTapped(self, cmd, sender) {
    let index = msg(sender, "tag")
    renderDetail(msg_1(recordings, "objectAtIndex:", index))
    emit 0
}
func goBack(self, cmd, sender) { pausePlayback() selected = 0 renderLibrary() emit 0 }
func tabChanged(self, cmd, sender) { pausePlayback() selected = 0 renderLibrary() emit 0 }
func sourceTapped(self, cmd, sender) {
    let key = "sourceURL"
    if msg(sender, "tag") == 1 { key = "licenseURL" }
    let value = field(selected, key)
    if value != 0 {
        let url = msg_1(cls("NSURL"), "URLWithString:", value)
        msg_3(iosApp(), "openURL:options:completionHandler:", url, fresh("NSDictionary"), 0)
    }
    emit 0
}
func importTapped(self, cmd, sender) {
    pausePlayback()
    let types = msg_1(cls("NSArray"), "arrayWithObject:", nsString("public.audio"))
    let picker = msg_2(msg(cls("UIDocumentPickerViewController"), "alloc"), "initWithDocumentTypes:inMode:", types, 0)
    msg_1(picker, "setDelegate:", delegateObject)
    msg_1(picker, "setAllowsMultipleSelection:", 0)
    msg_3(controller, "presentViewController:animated:completion:", picker, 1, 0)
    objc_release(picker)
    emit 0
}
func imported(self, cmd, picker, urls) {
    let url = msg(urls, "firstObject")
    if url == 0 { emit 0 }
    let access = msg(url, "startAccessingSecurityScopedResource")
    let candidate = msg_2(msg(cls("AVAudioPlayer"), "alloc"), "initWithContentsOfURL:error:", url, 0)
    if candidate == 0 {
        if access == 1 { msg(url, "stopAccessingSecurityScopedResource") }
        alert("Unsupported recording", "Please choose a playable MP3, M4A, or WAV audio file.")
        emit 0
    }
    objc_release(candidate)
    // Atomic write preserves any previous recording if the import fails.
    let data = msg_1(cls("NSData"), "dataWithContentsOfURL:", url)
    let success = msg_2(data, "writeToURL:atomically:", personalURL(), 1)
    if access == 1 { msg(url, "stopAccessingSecurityScopedResource") }
    if success == 0 { alert("Import didn’t finish", "Your previous recording is unchanged. Check free storage and try again.") emit 0 }
    stopPlayback()
    renderDetail(msg(recordings, "lastObject"))
    emit 0
}
func renderDetail(sound) {
    selected = sound
    clearBody()
    add(bodyStack, identify(action("‹  Back to collection", delegateObject, "goBack:", 0), "detail.back"))
    add(bodyStack, label("LISTEN CLOSELY", "UICTFontTextStyleCaption1", muted()))
    add(bodyStack, titleLabel(textValue(field(sound, "title")), 32, ink()))
    add(bodyStack, label(textValue(field(sound, "description")), "UICTFontTextStyleBody", muted()))
    let panel = rounded(pad(stack(1, 18), 24), 26, white())
    add(bodyStack, panel)
    let installed = soundURL(sound)
    let status = "Recording not installed"
    if installed != 0 { status = "Ready for offline listening" }
    statusLabel = add(panel, label(status, "UICTFontTextStyleSubhead", muted()))
    clockLabel = add(panel, label("", "UICTFontTextStyleCaption1", muted()))
    playButton = add(panel, identify(action("Play recording", delegateObject, "play:", 1), "audio.play"))
    msg_1(playButton, "setEnabled:", installed != 0)
    let skip = stack(0, 12)
    msg_1(skip, "setDistribution:", 1)
    scrubBack = add(skip, action("−10 seconds", delegateObject, "backTen:", 0))
    scrubForward = add(skip, action("+10 seconds", delegateObject, "forwardTen:", 0))
    msg_1(scrubBack, "setEnabled:", installed != 0)
    msg_1(scrubForward, "setEnabled:", installed != 0)
    add(panel, skip)
    let favoriteTitle = "♡  Save to favorites"
    if isFavorite(sound) == 1 { favoriteTitle = "♥  Saved to favorites" }
    let save = action(favoriteTitle, delegateObject, "favorite:", 0)
    msg_1(save, "setTag:", msg_1(recordings, "indexOfObject:", sound))
    add(panel, identify(save, "detail.favorite"))
    if msg_1(field(sound, "id"), "isEqualToString:", nsString("personal-recording")) == 1 {
        add(panel, identify(action("Import from Files", delegateObject, "import:", 0), "audio.import"))
    }
    add(bodyStack, label("THE RECORDING", "UICTFontTextStyleCaption1", muted()))
    add(bodyStack, label(textValue(field(sound, "credit")), "UICTFontTextStyleFootnote", muted()))
    if field(sound, "sourceURL") != 0 {
        add(bodyStack, action("Recording source ↗", delegateObject, "source:", 0))
        let license = action("CC BY-SA 4.0 license ↗", delegateObject, "source:", 0)
        msg_1(license, "setTag:", 1)
        add(bodyStack, license)
    }
    add(bodyStack, label("Headphones on. Let the woodland carry on.", "UICTFontTextStyleFootnote", muted()))
    timerTick(0, 0, 0)
    emit 0
}
func soundCard(sound, index) {
    let card = rounded(pad(stack(1, 12), 20), 24, white())
    let top = stack(0, 12)
    add(top, label(textValue(field(sound, "title")), "UICTFontTextStyleHeadline", ink()))
    let heart = "♡"
    if isFavorite(sound) == 1 { heart = "♥" }
    let save = action(heart, delegateObject, "favorite:", 0)
    msg_1(save, "setTag:", index)
    msg_1(save, "setAccessibilityLabel:", nsString("Toggle favorite for " + textValue(field(sound, "title"))))
    add(top, save)
    add(card, top)
    let subtitle = "Recording not installed"
    if soundURL(sound) != 0 { subtitle = "OFFLINE • READY TO LISTEN" }
    if msg_1(field(sound, "id"), "isEqualToString:", nsString("personal-recording")) == 1 {
        if personalExists() == 0 { subtitle = "Bring your own audio into the collection." }
    }
    add(card, label(subtitle, "UICTFontTextStyleSubhead", muted()))
    let open = action("Explore recording  →", delegateObject, "select:", 0)
    msg_1(open, "setTag:", index)
    identify(open, "recording." + index)
    add(card, open)
    emit card
}
func renderLibrary() {
    clearBody()
    let tab = msg(tabs, "selectedSegmentIndex")
    if tab == 2 {
        add(bodyStack, label("A QUIETER KIND OF CONNECTION", "UICTFontTextStyleCaption1", muted()))
        add(bodyStack, titleLabel("Good neighbors\ngive space.", 34, ink()))
        add(bodyStack, label("Listen with headphones. Observe squirrels from a distance, and let them choose where to go. Don’t play calls to lure, touch, or feed wildlife.", "UICTFontTextStyleBody", ink()))
        let notes = rounded(pad(stack(1, 16), 24), 24, white())
        add(notes, label("Try a listening moment", "UICTFontTextStyleHeadline", ink()))
        add(notes, label("Find a quiet spot. Stay still. Notice which sounds repeat, where they come from, and what else you can hear.", "UICTFontTextStyleBody", muted()))
        add(bodyStack, notes)
        add(bodyStack, label("Private by nature", "UICTFontTextStyleHeadline", ink()))
        add(bodyStack, label("Your favorites and imported audio stay on this device. No accounts, ads, analytics, microphone, or location access. Source links open external websites.", "UICTFontTextStyleBody", muted()))
        add(bodyStack, label("Wildlife guidance: nps.gov/subjects/watchingwildlife/7ways.htm", "UICTFontTextStyleFootnote", muted()))
        emit 0
    }
    if tab == 0 {
        let hero = rounded(pad(stack(1, 16), 26), 28, forest())
        add(hero, label("THE WOODLAND COLLECTION", "UICTFontTextStyleCaption1", color(207, 221, 181)))
        let ornament = label("🐿️", "UICTFontTextStyleLargeTitle", white())
        msg_1(ornament, "setFont:", msg_d1(cls("UIFont"), "systemFontOfSize:", 66))
        msg_1(ornament, "setIsAccessibilityElement:", 0)
        add(hero, ornament)
        add(hero, titleLabel("Small voices.\nWild stories.", 34, cream()))
        add(hero, label("Get to know the neighbors\nbeyond your window.", "UICTFontTextStyleBody", color(225, 233, 213)))
        add(bodyStack, hero)
    } else {
        add(bodyStack, titleLabel("Your favorites", 32, ink()))
        add(bodyStack, label("A little collection of sounds to return to.", "UICTFontTextStyleBody", muted()))
    }
    let count = msg(recordings, "count")
    let i = 0
    let shown = 0
    while i < count {
        let sound = msg_1(recordings, "objectAtIndex:", i)
        if tab == 0 || isFavorite(sound) == 1 {
            let animalName = field(sound, "animalName")
            if animalName != 0 { add(bodyStack, label(textValue(animalName), "UICTFontTextStyleHeadline", ink())) }
            add(bodyStack, soundCard(sound, i))
            shown += 1
        }
        i += 1
    }
    if shown == 0 {
        add(bodyStack, label("Nothing saved just yet. Tap a heart in the collection to keep a recording here.", "UICTFontTextStyleBody", muted()))
    }
    add(bodyStack, label("Listen to learn. Leave room for the wild.", "UICTFontTextStyleFootnote", muted()))
    emit 0
}
func launched(self, cmd, app, options) {
    kp("SP: entered launch callback")
    delegateObject = self
    let avBundle = msg_1(cls("NSBundle"), "bundleWithPath:", nsString("/System/Library/Frameworks/AVFoundation.framework"))
    msg(avBundle, "load")
    kp("SP: loaded playback framework")
    let path = msg_2(msg(cls("NSBundle"), "mainBundle"), "URLForResource:withExtension:", nsString("animals"), nsString("json"))
    let data = msg_1(cls("NSData"), "dataWithContentsOfURL:", path)
    catalog = msg_3(cls("NSJSONSerialization"), "JSONObjectWithData:options:error:", data, 0, 0)
    objc_retain(catalog)
    kp("SP: parsed catalog")
    recordings = allocInit("NSMutableArray")
    let i = 0
    while i < msg(catalog, "count") {
        let animal = msg_1(catalog, "objectAtIndex:", i)
        let sounds = field(animal, "sounds")
        let j = 0
        while j < msg(sounds, "count") {
            let sound = msg(msg_1(sounds, "objectAtIndex:", j), "mutableCopy")
            put(sound, "animalName", field(animal, "name"))
            msg_1(recordings, "addObject:", sound)
            objc_release(sound)
            j += 1
        }
        i += 1
    }
    msg_1(recordings, "addObject:", personalSound())
    kp("SP: prepared recording collection")
    let win = iosWindow(390, 844)
    msg_1(win, "setOverrideUserInterfaceStyle:", 1)
    controller = iosController()
    doIosRoot(win, controller)
    kp("SP: created root window")
    let root = iosRootView(controller)
    doIosBackground(root, cream())
    let outer = stack(1, 16)
    msg_1(outer, "setTranslatesAutoresizingMaskIntoConstraints:", 0)
    msg_1(root, "addSubview:", outer)
    let safe = msg(root, "safeAreaLayoutGuide")
    join(outer, "topAnchor", safe, "topAnchor")
    join(outer, "bottomAnchor", safe, "bottomAnchor")
    join(outer, "leadingAnchor", safe, "leadingAnchor")
    join(outer, "trailingAnchor", safe, "trailingAnchor")
    let header = pad(stack(1, 12), 20)
    add(header, titleLabel("Squirrel Friends", 26, ink()))
    let items = fresh("NSMutableArray")
    msg_1(items, "addObject:", nsString("Discover"))
    msg_1(items, "addObject:", nsString("Saved"))
    msg_1(items, "addObject:", nsString("Field notes"))
    tabs = msg_1(msg(cls("UISegmentedControl"), "alloc"), "initWithItems:", items)
    msg_1(tabs, "setSelectedSegmentIndex:", 0)
    msg_3(tabs, "addTarget:action:forControlEvents:", self, sel("tab:"), 4096)
    identify(tabs, "library.tabs")
    add(header, tabs)
    add(outer, header)
    let scroll = fresh("UIScrollView")
    msg_1(scroll, "setAlwaysBounceVertical:", 1)
    add(outer, scroll)
    bodyStack = pad(stack(1, 20), 20)
    msg_1(bodyStack, "setTranslatesAutoresizingMaskIntoConstraints:", 0)
    msg_1(scroll, "addSubview:", bodyStack)
    let content = msg(scroll, "contentLayoutGuide")
    join(bodyStack, "topAnchor", content, "topAnchor")
    join(bodyStack, "bottomAnchor", content, "bottomAnchor")
    join(bodyStack, "leadingAnchor", content, "leadingAnchor")
    join(bodyStack, "trailingAnchor", content, "trailingAnchor")
    join(bodyStack, "widthAnchor", msg(scroll, "frameLayoutGuide"), "widthAnchor")
    let center = msg(cls("NSNotificationCenter"), "defaultCenter")
    msg_4(center, "addObserver:selector:name:object:", self, sel("paused:"), nsString("AVAudioSessionInterruptionNotification"), 0)
    msg_4(center, "addObserver:selector:name:object:", self, sel("route:"), nsString("AVAudioSessionRouteChangeNotification"), 0)
    msg_timer(cls("NSTimer"), "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:", 500, self, "tick:", 0, 1)
    let launchTitle = iosLabel(root, "Squirrel Friends", 32, 120, 326, 48)
    doIosTextColor(launchTitle, iosWhite())
    let launchDetail = iosLabel(root, "A woodland sound collection", 32, 176, 326, 40)
    doIosTextColor(launchDetail, iosWhite())
    doIosKeep(self, win)
    doIosShow(win)
    kp("SP: showed root window")
    emit 1
}

just run {
    let c = objc_allocateClassPair(cls("NSObject"), "SquirrelFriendsDelegate", 0)
    class_addMethod(c, sel("application:didFinishLaunchingWithOptions:"), funcptr(launched), "B@:@@")
    class_addMethod(c, sel("applicationWillResignActive:"), funcptr(paused), "v@:@")
    class_addMethod(c, sel("paused:"), funcptr(paused), "v@:@")
    class_addMethod(c, sel("route:"), funcptr(routeChanged), "v@:@")
    class_addMethod(c, sel("tick:"), funcptr(timerTick), "v@:@")
    class_addMethod(c, sel("play:"), funcptr(playTapped), "v@:@")
    class_addMethod(c, sel("backTen:"), funcptr(backTen), "v@:@")
    class_addMethod(c, sel("forwardTen:"), funcptr(forwardTen), "v@:@")
    class_addMethod(c, sel("favorite:"), funcptr(favoriteTapped), "v@:@")
    class_addMethod(c, sel("select:"), funcptr(selectTapped), "v@:@")
    class_addMethod(c, sel("goBack:"), funcptr(goBack), "v@:@")
    class_addMethod(c, sel("tab:"), funcptr(tabChanged), "v@:@")
    class_addMethod(c, sel("source:"), funcptr(sourceTapped), "v@:@")
    class_addMethod(c, sel("import:"), funcptr(importTapped), "v@:@")
    class_addMethod(c, sel("documentPicker:didPickDocumentsAtURLs:"), funcptr(imported), "v@:@@")
    objc_registerClassPair(c)
    doIosRun("SquirrelFriendsDelegate")
}
