// Native UIKit components. Application logic and UI are compiled Krypton.
module squirrel_ui

func fresh(name) { emit msg(allocInit(name), "autorelease") }
func color(r, g, b) { emit msg_rgb(cls("UIColor"), "colorWithRed:green:blue:alpha:", r, g, b) }
func forest() { emit color(33, 65, 49) }
func cream() { emit color(247, 245, 236) }
func ink() { emit color(36, 48, 39) }
func muted() { emit color(99, 110, 100) }
func white() { emit color(255, 255, 255) }
func textValue(value) { emit msg(value, "UTF8String") }
func field(object, key) { emit msg_1(object, "objectForKey:", nsString(key)) }
func put(object, key, value) { msg_2(object, "setObject:forKey:", value, nsString(key)) emit value }

func label(text, style, tint) {
    let view = fresh("UILabel")
    msg_1(view, "setText:", nsString(text))
    msg_1(view, "setNumberOfLines:", 0)
    msg_1(view, "setFont:", msg_1(cls("UIFont"), "preferredFontForTextStyle:", nsString(style)))
    msg_1(view, "setAdjustsFontForContentSizeCategory:", 1)
    msg_1(view, "setTextColor:", tint)
    emit view
}

func titleLabel(text, size, tint) {
    let view = label(text, "UICTFontTextStyleTitle1", tint)
    // arm64: fontWithName:size: takes its pointer in x2 and its CGFloat in d0.
    let font = msg_rectp(cls("UIFont"), "fontWithName:size:", size, 0, 0, 0, nsString("Georgia-Bold"))
    let metrics = msg(cls("UIFontMetrics"), "defaultMetrics")
    msg_1(view, "setFont:", msg_1(metrics, "scaledFontForFont:", font))
    emit view
}

func stack(axis, spacing) {
    let view = fresh("UIStackView")
    msg_1(view, "setAxis:", axis)
    msg_d1(view, "setSpacing:", spacing)
    emit view
}
func add(parent, child) { msg_1(parent, "addArrangedSubview:", child) emit child }
func pad(view, inset) {
    msg_1(view, "setLayoutMarginsRelativeArrangement:", 1)
    // UIEdgeInsets and CGRect have the same four-CGFloat arm64 argument ABI.
    msg_frame(view, "setLayoutMargins:", inset, inset, inset, inset)
    emit view
}
func rounded(view, radius, tint) {
    msg_1(view, "setBackgroundColor:", tint)
    msg_d1(msg(view, "layer"), "setCornerRadius:", radius)
    msg_1(view, "setClipsToBounds:", 1)
    emit view
}
func join(view, edge, other, otherEdge) {
    let constraint = msg_1(msg(view, edge), "constraintEqualToAnchor:", msg(other, otherEdge))
    msg_1(constraint, "setActive:", 1)
    emit constraint
}
func sizeAtLeast(view, dimension, value) {
    let constraint = msg_d1(msg(view, dimension), "constraintGreaterThanOrEqualToConstant:", value)
    msg_1(constraint, "setActive:", 1)
    emit view
}
func action(title, target, selector, primary) {
    let view = msg_1(cls("UIButton"), "buttonWithType:", 1)
    let config = msg(cls("UIButtonConfiguration"), "tintedButtonConfiguration")
    if primary == 1 { config = msg(cls("UIButtonConfiguration"), "filledButtonConfiguration") }
    msg_1(config, "setTitle:", nsString(title))
    msg_1(config, "setBaseBackgroundColor:", forest())
    msg_1(config, "setBaseForegroundColor:", forest())
    if primary == 1 { msg_1(config, "setBaseForegroundColor:", white()) }
    msg_1(config, "setCornerStyle:", 3)
    msg_1(view, "setConfiguration:", config)
    sizeAtLeast(view, "heightAnchor", 50)
    msg_3(view, "addTarget:action:forControlEvents:", target, sel(selector), 64)
    emit view
}
func buttonTitle(view, title) {
    let config = msg(view, "configuration")
    msg_1(config, "setTitle:", nsString(title))
    msg_1(view, "setConfiguration:", config)
    emit 0
}
func identify(view, value) { msg_1(view, "setAccessibilityIdentifier:", nsString(value)) emit view }
