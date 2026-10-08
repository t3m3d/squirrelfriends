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
let personalStatus = 0
let personalPlayButton = 0
let activePlayButton = 0
let galleryItems = 0
let galleryScroll = 0
let galleryIndex = 0
let galleryCounter = 0
let galleryBackButton = 0
let galleryNextButton = 0

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
    put(sound, "animalName", nsString("Your recording"))
    put(sound, "title", nsString("My field recording"))
    put(sound, "description", nsString("Your own audio, stored on this device. Imported recordings are not verified or identified by the app."))
    put(sound, "credit", nsString("Imported by you. Keep the creator’s permission and credit with any audio you share. This file is separate from the bundled sound collection."))
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
    if activePlayButton != 0 { msg_2(activePlayButton, "setTitle:forState:", nsString("Play recording"), 0) }
    emit 0
}
func stopPlayback() {
    pausePlayback()
    if player != 0 {
        msg(player, "stop")
        objc_release(player)
        player = 0
    }
    playingID = 0
    activePlayButton = 0
    emit 0
}
func paused(self, cmd, notice) { pausePlayback() emit 0 }
func routeChanged(self, cmd, notice) {
    let reason = field(msg(notice, "userInfo"), "AVAudioSessionRouteChangeReasonKey")
    if msg(reason, "integerValue") == 2 { pausePlayback() }
    emit 0
}
// KVC boxes TimeInterval values, avoiding the current compiler's float-return bridge.
func audioSeconds(key) {
    emit msg(msg_1(player, "valueForKey:", nsString(key)), "integerValue")
}
func timerTick(self, cmd, timer) {
    if player != 0 {
        if clockLabel != 0 {
            let elapsed = audioSeconds("currentTime")
            let duration = audioSeconds("duration")
            doIosText(clockLabel, "" + elapsed + "s / " + duration + "s")
        }
        if playButton != 0 {
            if msg(player, "isPlaying") == 0 { buttonTitle(playButton, "Play recording") }
        }
    }
    emit 0
}
func playTapped(self, cmd, sender) {
    selected = msg_1(recordings, "objectAtIndex:", msg(sender, "tag"))
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
        msg_1(player, "setDelegate:", delegateObject)
    }
    if player == 0 { alert("Couldn’t play this audio", "Choose a supported MP3, M4A, or WAV recording and try again.") emit 0 }
    if msg(player, "play") == 1 {
        activePlayButton = sender
        msg_2(sender, "setTitle:forState:", nsString("Pause recording"), 0)
    }
    else { alert("Playback unavailable", "The audio could not start. Please try a different recording.") }
    emit 0
}
func backTen(self, cmd, sender) {
    if player != 0 {
        let value = audioSeconds("currentTime") - 10
        if value < 0 { value = 0 }
        msg_d1(player, "setCurrentTime:", value)
        timerTick(self, cmd, 0)
    }
    emit 0
}
func forwardTen(self, cmd, sender) {
    if player != 0 {
        let value = audioSeconds("currentTime") + 10
        let duration = audioSeconds("duration")
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
    let title = "♡  Save"
    if value == 1 { title = "♥  Saved" }
    msg_2(sender, "setTitle:forState:", nsString(title), 0)
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
    selected = msg_1(recordings, "objectAtIndex:", msg(sender, "tag"))
    let value = field(selected, "sourceURL")
    if value != 0 {
        let url = msg_1(cls("NSURL"), "URLWithString:", value)
        msg_3(iosApp(), "openURL:options:completionHandler:", url, fresh("NSDictionary"), 0)
    }
    emit 0
}
func creditsTapped(self, cmd, sender) {
    let sound = msg_1(recordings, "objectAtIndex:", msg(sender, "tag"))
    alert("Recording credits", textValue(field(sound, "credit")))
    emit 0
}
func licenseTapped(self, cmd, sender) {
    let sound = msg_1(recordings, "objectAtIndex:", msg(sender, "tag"))
    let value = field(sound, "licenseURL")
    if value != 0 {
        let url = msg_1(cls("NSURL"), "URLWithString:", value)
        msg_3(iosApp(), "openURL:options:completionHandler:", url, fresh("NSDictionary"), 0)
    }
    emit 0
}
func audioFinished(self, cmd, audio, success) {
    if msg_1(audio, "isEqual:", player) == 1 { pausePlayback() }
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
    if personalStatus != 0 { doIosText(personalStatus, "Your audio is ready for offline listening.") }
    if personalPlayButton != 0 {
        msg_1(personalPlayButton, "setEnabled:", 1)
        msg_2(personalPlayButton, "setTitle:forState:", nsString("Play recording"), 0)
        msg_3(personalPlayButton, "removeTarget:action:forControlEvents:", delegateObject, sel("import:"), 64)
        msg_3(personalPlayButton, "addTarget:action:forControlEvents:", delegateObject, sel("play:"), 64)
    }
    alert("Recording added", "Your audio is saved on this device and kept separate from the credited library recordings.")
    emit 0
}
func simpleButton(root, title, x, y, w, h, selector, value) {
    let button = iosButton(root, title, x, y, w, h)
    msg_1(button, "setTag:", value)
    msg_2(button, "setTitleColor:forState:", forest(), 0)
    msg_2(button, "setTitleColor:forState:", muted(), 2)
    msg_3(button, "addTarget:action:forControlEvents:", delegateObject, sel(selector), 64)
    msg_1(button, "setAccessibilityIdentifier:", nsString("sf." + selector + value))
    emit button
}
func simpleCard(root, sound, index, y) {
    let title = textValue(field(sound, "title"))
    let animal = textValue(field(sound, "animalName"))
    let isPersonal = msg_1(field(sound, "id"), "isEqualToString:", nsString("personal-recording")) == 1
    let artwork = field(sound, "artwork")
    let picture = 0
    if artwork != 0 { picture = msg_1(cls("UIImage"), "imageNamed:", artwork) }
    let imageHeight = 0
    if picture != 0 {
        imageHeight = 346
        let configuredHeight = field(sound, "artworkHeight")
        if configuredHeight != 0 { imageHeight = msg(configuredHeight, "integerValue") }
    }
    let height = imageHeight + 190
    let card = msg_frame(msg(cls("UIView"), "alloc"), "initWithFrame:", 22, y, 346, height)
    msg_1(root, "addSubview:", card)
    doIosBackground(card, white())
    msg_d1(msg(card, "layer"), "setCornerRadius:", 25)
    msg_1(card, "setClipsToBounds:", 1)
    if picture != 0 {
        let photo = msg_frame(msg(cls("UIImageView"), "alloc"), "initWithFrame:", 0, 0, 346, imageHeight)
        msg_1(photo, "setImage:", picture)
        msg_1(photo, "setContentMode:", 1)
        msg_1(photo, "setIsAccessibilityElement:", 1)
        let description = field(sound, "artworkDescription")
        if description == 0 { description = nsString("Picture of " + animal) }
        msg_1(photo, "setAccessibilityLabel:", description)
        msg_1(photo, "setAccessibilityIdentifier:", nsString("artwork." + index))
        msg_1(card, "addSubview:", photo)
    }
    let animalLabel = iosLabel(card, animal, 20, imageHeight + 14, 306, 25)
    msg_1(animalLabel, "setFont:", msg_d1(cls("UIFont"), "boldSystemFontOfSize:", 16))
    msg_1(animalLabel, "setTextColor:", forest())
    let detailTitle = iosLabel(card, title, 20, imageHeight + 40, 306, 27)
    msg_1(detailTitle, "setFont:", msg_d1(cls("UIFont"), "systemFontOfSize:", 19))
    msg_1(detailTitle, "setTextColor:", ink())
    let status = "Recording not installed"
    if soundURL(sound) != 0 {
        status = "Ready for offline listening"
        let duration = field(sound, "durationLabel")
        if duration != 0 { status = textValue(duration) + " • Offline" }
    }
    if isPersonal && personalExists() == 0 { status = "Import audio you own from Files" }
    let statusView = iosLabel(card, status, 20, imageHeight + 68, 306, 24)
    msg_1(statusView, "setFont:", msg_d1(cls("UIFont"), "systemFontOfSize:", 14))
    msg_1(statusView, "setTextColor:", muted())
    let firstTitle = "Play recording"
    let firstAction = "play:"
    if isPersonal && personalExists() == 0 { firstTitle = "Import audio" firstAction = "import:" }
    let play = simpleButton(card, firstTitle, 16, imageHeight + 100, 172, 44, firstAction, index)
    doIosBackground(play, forest())
    msg_2(play, "setTitleColor:forState:", white(), 0)
    msg_d1(msg(play, "layer"), "setCornerRadius:", 16)
    let url = soundURL(sound)
    if !isPersonal { msg_1(play, "setEnabled:", url != 0) }
    if isPersonal { personalPlayButton = play }
    if index == 0 { playButton = play }
    let heart = "♡  Save"
    if isFavorite(sound) == 1 { heart = "♥  Saved" }
    simpleButton(card, heart, 198, imageHeight + 100, 132, 44, "favorite:", index)
    if !isPersonal {
        simpleButton(card, "Source ↗", 16, imageHeight + 145, 100, 44, "source:", index)
        simpleButton(card, "Credits", 123, imageHeight + 145, 100, 44, "credits:", index)
        simpleButton(card, "License ↗", 230, imageHeight + 145, 100, 44, "license:", index)
    } else {
        simpleButton(card, "Choose another file", 24, imageHeight + 145, 298, 44, "import:", index)
    }
    emit height
}
func galleryUpdate() {
    let count = msg(galleryItems, "count")
    doIosText(galleryCounter, "" + (galleryIndex + 1) + " / " + count)
    msg_1(galleryBackButton, "setEnabled:", galleryIndex > 0)
    msg_1(galleryNextButton, "setEnabled:", galleryIndex + 1 < count)
    emit 0
}
func galleryNext(self, cmd, sender) {
    if galleryIndex + 1 < msg(galleryItems, "count") { galleryIndex += 1 }
    msg_d2(galleryScroll, "setContentOffset:", galleryIndex * 346, 0)
    galleryUpdate()
    emit 0
}
func galleryBack(self, cmd, sender) {
    if galleryIndex > 0 { galleryIndex -= 1 }
    msg_d2(galleryScroll, "setContentOffset:", galleryIndex * 346, 0)
    galleryUpdate()
    emit 0
}
func galleryScrolled(self, cmd, scroll) {
    galleryIndex = (msgPointX(scroll, "contentOffset", 0) + 173) / 346
    if galleryIndex < 0 { galleryIndex = 0 }
    if galleryIndex >= msg(galleryItems, "count") { galleryIndex = msg(galleryItems, "count") - 1 }
    galleryUpdate()
    emit 0
}
func galleryDragged(self, cmd, scroll, decelerate) {
    if decelerate == 0 { galleryScrolled(self, cmd, scroll) }
    emit 0
}
func galleryPhoto(item, index) {
    let photo = msg_frame(msg(cls("UIImageView"), "alloc"), "initWithFrame:", index * 346, 0, 346, 266)
    msg_1(photo, "setImage:", msg_1(cls("UIImage"), "imageNamed:", field(item, "filename")))
    msg_1(photo, "setContentMode:", 1)
    msg_1(photo, "setIsAccessibilityElement:", 1)
    msg_1(photo, "setAccessibilityLabel:", field(item, "description"))
    msg_1(photo, "setAccessibilityIdentifier:", field(item, "id"))
    msg_1(galleryScroll, "addSubview:", photo)
    let caption = iosLabel(galleryScroll, textValue(field(item, "title")), index * 346 + 18, 272, 310, 28)
    msg_1(caption, "setFont:", msg_d1(cls("UIFont"), "boldSystemFontOfSize:", 16))
    msg_1(caption, "setTextColor:", forest())
    msg_1(caption, "setTextAlignment:", 1)
    emit 0
}
func photoGallery(page, y) {
    let path = msg_2(msg(cls("NSBundle"), "mainBundle"), "URLForResource:withExtension:", nsString("photos"), nsString("json"))
    let data = msg_1(cls("NSData"), "dataWithContentsOfURL:", path)
    galleryItems = msg_3(cls("NSJSONSerialization"), "JSONObjectWithData:options:error:", data, 0, 0)
    objc_retain(galleryItems)
    if msg(galleryItems, "count") == 0 { emit 0 }
    creamPanel(page, y, 48)
    let title = iosLabel(page, "SQUIRREL MOMENTS", 26, y + 12, 338, 25)
    msg_1(title, "setFont:", msg_d1(cls("UIFont"), "systemFontOfSize:", 13))
    msg_1(title, "setTextColor:", forest())
    let card = msg_frame(msg(cls("UIView"), "alloc"), "initWithFrame:", 22, y + 58, 346, 376)
    doIosBackground(card, white())
    msg_d1(msg(card, "layer"), "setCornerRadius:", 25)
    msg_1(card, "setClipsToBounds:", 1)
    msg_1(page, "addSubview:", card)
    galleryScroll = msg_frame(msg(cls("UIScrollView"), "alloc"), "initWithFrame:", 0, 0, 346, 306)
    msg_1(galleryScroll, "setPagingEnabled:", 1)
    msg_1(galleryScroll, "setShowsHorizontalScrollIndicator:", 0)
    msg_1(galleryScroll, "setDirectionalLockEnabled:", 1)
    msg_1(galleryScroll, "setContentInsetAdjustmentBehavior:", 2)
    msg_1(galleryScroll, "setDelegate:", delegateObject)
    msg_1(galleryScroll, "setAccessibilityIdentifier:", nsString("photo.gallery"))
    msg_d2(galleryScroll, "setContentSize:", msg(galleryItems, "count") * 346, 306)
    msg_1(card, "addSubview:", galleryScroll)
    let index = 0
    while index < msg(galleryItems, "count") {
        galleryPhoto(msg_1(galleryItems, "objectAtIndex:", index), index)
        index += 1
    }
    galleryBackButton = simpleButton(card, "‹ Back", 14, 318, 90, 44, "galleryBack:", 0)
    galleryNextButton = simpleButton(card, "Next ›", 242, 318, 90, 44, "galleryNext:", 0)
    galleryCounter = iosLabel(card, "", 108, 318, 130, 44)
    msg_1(galleryCounter, "setTextAlignment:", 1)
    msg_1(galleryCounter, "setTextColor:", muted())
    msg_1(galleryCounter, "setAccessibilityIdentifier:", nsString("gallery.counter"))
    galleryUpdate()
    emit 450
}
func pageBackdrop(root) {
    let picture = msg_1(cls("UIImage"), "imageNamed:", nsString("woodland-background.jpg"))
    if picture == 0 { emit 0 }
    let backdrop = msg_frame(msg(cls("UIImageView"), "alloc"), "initWithFrame:", 0, 0, 390, 844)
    msg_1(backdrop, "setImage:", picture)
    msg_1(backdrop, "setContentMode:", 2)
    msg_1(backdrop, "setClipsToBounds:", 1)
    msg_1(backdrop, "setAutoresizingMask:", 18)
    msg_1(backdrop, "setIsAccessibilityElement:", 0)
    msg_1(backdrop, "setUserInteractionEnabled:", 0)
    msg_1(root, "addSubview:", backdrop)
    // Keep the dark system status text legible above the scrolling collection.
    let statusRail = msg_frame(msg(cls("UIView"), "alloc"), "initWithFrame:", 0, 0, 390, 60)
    doIosBackground(statusRail, cream())
    msg_1(statusRail, "setAutoresizingMask:", 2)
    msg_1(statusRail, "setUserInteractionEnabled:", 0)
    msg_1(root, "addSubview:", statusRail)
    emit 0
}
func creamPanel(parent, y, height) {
    let panel = msg_frame(msg(cls("UIView"), "alloc"), "initWithFrame:", 12, y, 366, height)
    doIosBackground(panel, cream())
    msg_d1(msg(panel, "layer"), "setCornerRadius:", 22)
    msg_1(panel, "setUserInteractionEnabled:", 0)
    msg_1(parent, "addSubview:", panel)
    emit 0
}
func simplePage(root) {
    pageBackdrop(root)
    let scroll = msg_frame(msg(cls("UIScrollView"), "alloc"), "initWithFrame:", 0, 0, 390, 844)
    msg_1(scroll, "setAutoresizingMask:", 18)
    msg_1(root, "addSubview:", scroll)
    msg_1(scroll, "setAlwaysBounceVertical:", 1)
    let page = fresh("UIView")
    msg_1(page, "setTranslatesAutoresizingMaskIntoConstraints:", 0)
    msg_1(scroll, "addSubview:", page)
    msg_frame(page, "setFrame:", 0, 0, 390, 1200)
    msg_1(page, "setTranslatesAutoresizingMaskIntoConstraints:", 1)
    pageHeader(page)
    let height = pageCards(page)
    msg_frame(page, "setFrame:", 0, 0, 390, height)
    msg_d2(scroll, "setContentSize:", 390, height)
    emit 0
}
func pageHeader(page) {
    creamPanel(page, 0, 231)
    let eyebrow = iosLabel(page, "THE WOODLAND COLLECTION", 26, 14, 338, 25)
    msg_1(eyebrow, "setFont:", msg_d1(cls("UIFont"), "systemFontOfSize:", 13))
    msg_1(eyebrow, "setTextColor:", forest())
    let title = iosLabel(page, "Small voices.\nWild stories.", 24, 48, 338, 86)
    msg_1(title, "setNumberOfLines:", 2)
    msg_1(title, "setFont:", msg_d1(cls("UIFont"), "systemFontOfSize:", 34))
    msg_1(title, "setTextColor:", ink())
    let intro = iosLabel(page, "Meet your woodland neighbors.\nListen with care. Give wildlife space.", 26, 143, 338, 46)
    msg_1(intro, "setFont:", msg_d1(cls("UIFont"), "systemFontOfSize:", 16))
    msg_1(intro, "setNumberOfLines:", 2)
    msg_1(intro, "setTextColor:", muted())
    let section = iosLabel(page, "THE SOUND COLLECTION", 26, 202, 338, 25)
    msg_1(section, "setFont:", msg_d1(cls("UIFont"), "systemFontOfSize:", 13))
    msg_1(section, "setTextColor:", forest())
    emit 0
}
// Group by catalog labels while keeping recording tags stable for playback and favorites.
func soundCategory(sound) {
    if msg_1(field(sound, "id"), "isEqualToString:", nsString("personal-recording")) == 1 {
        emit nsString("Your recording")
    }
    let category = field(sound, "category")
    if category == 0 { category = nsString("Field calls") }
    emit category
}
func pageCards(page) {
    let y = 239
    let categories = allocInit("NSMutableArray")
    let index = 0
    while index < msg(recordings, "count") {
        let category = soundCategory(msg_1(recordings, "objectAtIndex:", index))
        if msg_1(categories, "containsObject:", category) == 0 { msg_1(categories, "addObject:", category) }
        index += 1
    }
    let groupIndex = 0
    while groupIndex < msg(categories, "count") {
        let category = msg_1(categories, "objectAtIndex:", groupIndex)
        creamPanel(page, y, 42)
        let heading = iosLabel(page, textValue(category), 28, y + 7, 334, 28)
        msg_1(heading, "setFont:", msg_d1(cls("UIFont"), "boldSystemFontOfSize:", 17))
        msg_1(heading, "setTextColor:", forest())
        msg_1(heading, "setAccessibilityIdentifier:", nsString("category." + textValue(category)))
        y += 54
        index = 0
        while index < msg(recordings, "count") {
            let sound = msg_1(recordings, "objectAtIndex:", index)
            if msg_1(soundCategory(sound), "isEqualToString:", category) == 1 {
                let cardHeight = simpleCard(page, sound, index, y)
                y = y + cardHeight + 16
            }
            index += 1
        }
        groupIndex += 1
    }
    objc_release(categories)
    let galleryHeight = photoGallery(page, y)
    y += galleryHeight
    creamPanel(page, y, 96)
    personalStatus = iosLabel(page, "Your recording stays on this device.", 28, y + 8, 334, 27)
    msg_1(personalStatus, "setTextColor:", muted())
    msg_1(personalStatus, "setFont:", msg_d1(cls("UIFont"), "systemFontOfSize:", 14))
    msg_1(personalStatus, "setAccessibilityIdentifier:", nsString("personal.status"))
    simpleButton(page, "Listening with care", 26, y + 38, 338, 50, "notes:", 0)
    emit y + 108
}
func notesTapped(self, cmd, sender) {
    alert("A good neighbor gives space", "Listen with headphones. Watch wildlife from a distance, and let animals choose where to go. Never use recordings to lure, touch, or feed wild animals.")
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
    delegateObject = self
    let avBundle = msg_1(cls("NSBundle"), "bundleWithPath:", nsString("/System/Library/Frameworks/AVFoundation.framework"))
    msg(avBundle, "load")
    let path = msg_2(msg(cls("NSBundle"), "mainBundle"), "URLForResource:withExtension:", nsString("animals"), nsString("json"))
    let data = msg_1(cls("NSData"), "dataWithContentsOfURL:", path)
    catalog = msg_3(cls("NSJSONSerialization"), "JSONObjectWithData:options:error:", data, 0, 0)
    objc_retain(catalog)
    recordings = allocInit("NSMutableArray")
    let i = 0
    while i < msg(catalog, "count") {
        let animal = msg_1(catalog, "objectAtIndex:", i)
        let sounds = field(animal, "sounds")
        let j = 0
        while j < msg(sounds, "count") {
            let sound = msg(msg_1(sounds, "objectAtIndex:", j), "mutableCopy")
            put(sound, "animalName", field(animal, "name"))
            let artwork = field(animal, "artwork")
            if artwork != 0 { put(sound, "artwork", artwork) }
            let artworkHeight = field(animal, "artworkHeight")
            if artworkHeight != 0 { put(sound, "artworkHeight", artworkHeight) }
            let artworkDescription = field(animal, "artworkDescription")
            if artworkDescription != 0 { put(sound, "artworkDescription", artworkDescription) }
            msg_1(recordings, "addObject:", sound)
            objc_release(sound)
            j += 1
        }
        i += 1
    }
    msg_1(recordings, "addObject:", personalSound())
    let win = iosWindow(390, 844)
    msg_1(win, "setOverrideUserInterfaceStyle:", 1)
    controller = iosController()
    doIosRoot(win, controller)
    let root = iosRootView(controller)
    doIosBackground(root, cream())
    simplePage(root)
    let center = msg(cls("NSNotificationCenter"), "defaultCenter")
    msg_4(center, "addObserver:selector:name:object:", self, sel("paused:"), nsString("AVAudioSessionInterruptionNotification"), 0)
    msg_4(center, "addObserver:selector:name:object:", self, sel("route:"), nsString("AVAudioSessionRouteChangeNotification"), 0)
    doIosKeep(self, win)
    doIosShow(win)
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
    class_addMethod(c, sel("credits:"), funcptr(creditsTapped), "v@:@")
    class_addMethod(c, sel("license:"), funcptr(licenseTapped), "v@:@")
    class_addMethod(c, sel("audioPlayerDidFinishPlaying:successfully:"), funcptr(audioFinished), "v@:@B")
    class_addMethod(c, sel("import:"), funcptr(importTapped), "v@:@")
    class_addMethod(c, sel("notes:"), funcptr(notesTapped), "v@:@")
    class_addMethod(c, sel("galleryNext:"), funcptr(galleryNext), "v@:@")
    class_addMethod(c, sel("galleryBack:"), funcptr(galleryBack), "v@:@")
    class_addMethod(c, sel("scrollViewDidEndDecelerating:"), funcptr(galleryScrolled), "v@:@")
    class_addMethod(c, sel("scrollViewDidEndDragging:willDecelerate:"), funcptr(galleryDragged), "v@:@B")
    class_addMethod(c, sel("documentPicker:didPickDocumentsAtURLs:"), funcptr(imported), "v@:@@")
    objc_registerClassPair(c)
    doIosRun("SquirrelFriendsDelegate")
}
