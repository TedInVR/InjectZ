import Quartz
import Darwin
import Cocoa
import UniformTypeIdentifiers
import ApplicationServices

final class DropView: NSView {
    var onDrop: (([URL]) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], urls.first != nil else { return [] }
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !urls.isEmpty else { return false }
        onDrop?(urls)
        return true
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var outputPreviewController: InjectZOutputPreviewController?
    // INJECTZ_DEFER_OPEN_UNTIL_READY_20261007
    private var mainUIReady = false
    private var pendingLaunchPhoto: URL?

    var window: NSWindow!
    var automaticUpdateItems: [NSMenuItem] = []
    var sharpDepthEditor: SharpDepthEditorController?
    var sharpDepthEditorButton: NSButton!
    var photoField: NSTextField!
    var enginePopup: NSPopUpButton!
    var depthPopup: NSPopUpButton!
    var customSharpDepth: Double = 0.250
    var depthLabel: NSTextField!
    var iw3ModelLabel: NSTextField!
    var iw3ModelPopup: NSPopUpButton!
    var formatButtons: [NSButton] = []
    let formatIDs = ["Parallel", "Crossview", "Anaglyph_FullColor", "Anaglyph_HalfColor", "Anaglyph_Dubois", "Left_Right_Left", "Parallel_Over_Crossview"]
    var borderPopup: NSPopUpButton!
    var cornersPopup: NSPopUpButton!
    var presetPopup: NSPopUpButton!
    var wiggleOption: NSButton!
    var wiggleViews: NSButton!
    var wiggleFrames: NSPopUpButton!
    var wiggleFPS: NSPopUpButton!
    var wiggleCard: NSButton!
    var wiggleCardColor: NSColorWell!
    var wiggleCardTitle: NSTextField!
    var additionalSection: NSView!
    var additionalToggle: NSButton!
    var elevatedViews: [NSView] = []
    var additionalExpanded = false
    let presetsKey = "InjectZConversionPresetsV1"
    func cardColorHex() -> String {
        let c = wiggleCardColor.color.usingColorSpace(.sRGB) ?? .black
        func byte(_ x: CGFloat) -> Int { Int((min(1, max(0, x)) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(c.redComponent), byte(c.greenComponent), byte(c.blueComponent))
    }
    func finishingArguments() -> [String] {
        let borders = [0, 1, 2, 5, 10]
        let corners = [0, 2, 5, 10, 20]
        var result = ["--border-percent", String(borders[max(0, borderPopup.indexOfSelectedItem)]),
                      "--corner-percent", String(corners[max(0, cornersPopup.indexOfSelectedItem)])]
        if wiggleCard.state == .on { result += ["--card-color", cardColorHex(), "--card-title", wiggleCardTitle.stringValue] }
        return result
    }
    func selectedFormats() -> [String] { zip(formatButtons, formatIDs).compactMap { $0.0.state == .on ? $0.1 : nil } }
    var advancedButton: NSButton!
    var advancedPanel: NSPanel?
    var methodPopup: NSPopUpButton!
    var convergenceField: NSTextField!
    var foregroundField: NSTextField!
    var preserveBorder: NSButton!
    var depthAA: NSButton!
    var keepEyes: NSButton!
    var allowWindowViolations: NSButton!
    var convertButton: NSButton!
    var depthMapButton: NSButton!
    var statusLabel: NSTextField!
    var revealButton: NSButton!
    var resumeReframeButton: NSButton!
    var selectedPhoto: URL?
    var stereoInputFormat: String?
    var stereoRightEye: URL?
    var relatedAppsMenu: NSMenu!
    let relatedAppsKey = "InjectZRelatedAppsV1"
    var lastOutput: URL?
    var sharpEdgesButton: NSButton!
    var sharpEdgesPanel: NSPanel?
    var softenSharpEdges: NSButton?
    var edgeRadius: NSSlider?
    var edgeStrength: NSSlider?
    var edgeRadiusLabel: NSTextField?
    var edgeStrengthLabel: NSTextField?
    @objc func edgeValuesChanged() {
        edgeRadiusLabel?.stringValue = String(format: "Radius: %.1f pixels", edgeRadius?.doubleValue ?? 2)
        edgeStrengthLabel?.stringValue = String(format: "Strength: %.0f%%", (edgeStrength?.doubleValue ?? 0.35) * 100)
        let enabled = softenSharpEdges?.state == .on
        edgeRadius?.isEnabled = enabled
        edgeStrength?.isEnabled = enabled
    }
    @objc func showSharpEdges() {
        ensureSharpEdges()
        sharpEdgesPanel?.makeKeyAndOrderFront(nil)
    }
    func ensureSharpEdges() {
        if sharpEdgesPanel != nil { return }
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
                            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.title = "SHARP Edge Softening"
        panel.center()
        guard let content = panel.contentView else { return }
        let toggle = NSButton(checkboxWithTitle: "Soften depth edges", target: self, action: #selector(edgeValuesChanged))
        toggle.frame = NSRect(x: 20, y: 249, width: 300, height: 26)
        toggle.state = .off
        content.addSubview(toggle); softenSharpEdges = toggle
        let radiusLabel = NSTextField(labelWithString: "Radius: 2.0 pixels")
        radiusLabel.frame = NSRect(x: 20, y: 210, width: 200, height: 24)
        content.addSubview(radiusLabel); edgeRadiusLabel = radiusLabel
        let radius = NSSlider(value: 2, minValue: 0.5, maxValue: 6, target: self, action: #selector(edgeValuesChanged))
        radius.frame = NSRect(x: 220, y: 207, width: 245, height: 26)
        content.addSubview(radius); edgeRadius = radius
        let strengthLabel = NSTextField(labelWithString: "Strength: 35%")
        strengthLabel.frame = NSRect(x: 20, y: 165, width: 200, height: 24)
        content.addSubview(strengthLabel); edgeStrengthLabel = strengthLabel
        let strength = NSSlider(value: 0.35, minValue: 0, maxValue: 1, target: self, action: #selector(edgeValuesChanged))
        strength.frame = NSRect(x: 220, y: 162, width: 245, height: 26)
        content.addSubview(strength); edgeStrength = strength
        let hint = NSTextField(wrappingLabelWithString: "Softens only a narrow band at significant depth boundaries. Larger radius widens the band; strength controls the blend. Image detail outside that band is preserved. Fine hair or incorrectly estimated depth may still be affected. Adds two geometry passes when enabled. Start with 2 pixels and 35%.")
        hint.frame = NSRect(x: 20, y: 25, width: 460, height: 100)
        hint.textColor = .secondaryLabelColor
        content.addSubview(hint)
        sharpEdgesPanel = panel
        edgeValuesChanged()
    }

    var sharpDepthSelection = 3
    var iw3StrengthSelection = 4
    var reframeAppliedPan: Double = 0
    var reframeRequestedPan: Double = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        buildUI()
        InjectZUpdates.shared.register()
        mainUIReady = true
        if let photo = pendingLaunchPhoto {
            pendingLaunchPhoto = nil
            selectPhoto(photo)
        }
    }

    @objc func checkForInjectZUpdates(_ sender: Any?) {
        InjectZUpdates.shared.check(owner: self)
    }
    @objc func toggleAutomaticInjectZUpdates(_ sender: NSMenuItem) {
        for item in automaticUpdateItems { item.isEnabled = false }
        InjectZUpdates.shared.setAutomatic(sender) { value in
            for item in self.automaticUpdateItems {
                if let value = value { item.state = value ? .on : .off }
                item.isEnabled = true
            }
        }
    }

    @objc func showInjectZAbout(_ sender: Any?) {
        let credits = NSMutableAttributedString(string: "Developed by Ted Whitten\nVibe coded with ChatGPT\n\n")
        credits.append(NSAttributedString(string: "Inject Z on GitHub", attributes: [
            .link: URL(string: "https://github.com/TedInVR/InjectZ")!,
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        credits.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: credits.length))
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Inject Z",
            .credits: credits
        ])
    }

    @objc func showInjectZHelp(_ sender: Any?) {
        guard let guide = Bundle.main.url(forResource: "InjectZ_User_Guide", withExtension: "html") else {
            let alert = NSAlert()
            alert.messageText = "User guide is missing"
            alert.informativeText = "Reinstall the About and Help update to restore the bundled guide."
            alert.runModal()
            return
        }
        if !NSWorkspace.shared.open(guide) {
            let alert = NSAlert()
            alert.messageText = "Could not open the user guide"
            alert.informativeText = "The guide is in InjectZ.app/Contents/Resources/InjectZ_User_Guide.html."
            alert.runModal()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { window?.makeKeyAndOrderFront(nil) }
        return true
    }

    func buildMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu(title: "Inject Z")
        appMenuItem.submenu = appMenu

        let aboutItem = NSMenuItem(
            title: "About Inject Z",
            action: #selector(showInjectZAbout(_:)),
            keyEquivalent: ""
        )
        aboutItem.target = self
        appMenu.addItem(aboutItem)
        let helpItem = NSMenuItem(title: "Help", action: #selector(showInjectZHelp(_:)), keyEquivalent: "")
        helpItem.target = self
        appMenu.addItem(helpItem)
        let updateItem = NSMenuItem(title: "Check for Updates…", action: #selector(checkForInjectZUpdates(_:)), keyEquivalent: "")
        updateItem.target = self
        appMenu.addItem(updateItem)
        let automaticItem = NSMenuItem(title: "Automatically Update While Closed", action: #selector(toggleAutomaticInjectZUpdates(_:)), keyEquivalent: "")
        automaticItem.target = self; automaticItem.state = InjectZUpdates.automatic ? .on : .off
        appMenu.addItem(automaticItem)
        automaticUpdateItems.append(automaticItem)
        let audioItem = NSMenuItem(title: "Audio Alerts…", action: #selector(InjectZAudioAlerts.showSettings), keyEquivalent: "")
        audioItem.target = InjectZAudioAlerts.shared
        appMenu.addItem(audioItem)
        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit Inject Z",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        appMenu.addItem(quitItem)

        // A nil target uses AppKit's responder chain, so Close reaches the active window.
        let fileItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        let stereoItem = NSMenuItem(title: "Open Stereo Image…", action: #selector(openStereoImage), keyEquivalent: "")
        stereoItem.target = self; fileMenu.addItem(stereoItem)
        let eyesItem = NSMenuItem(title: "Open Left and Right Images…", action: #selector(openStereoEyes), keyEquivalent: "")
        eyesItem.target = self; fileMenu.addItem(eyesItem)
        fileMenu.addItem(NSMenuItem.separator())
        let closeItem = NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        closeItem.keyEquivalentModifierMask = [.command]
        fileMenu.addItem(closeItem)
        fileItem.submenu = fileMenu
        mainMenu.addItem(fileItem)

        let appsItem = NSMenuItem(title: "Apps", action: nil, keyEquivalent: "")
        relatedAppsMenu = NSMenu(title: "Apps"); appsItem.submenu = relatedAppsMenu
        mainMenu.addItem(appsItem)
        refreshRelatedApps()

        let depthMenuItem = NSMenuItem(title: "SHARP", action: nil, keyEquivalent: "")
        let depthMenu = NSMenu(title: "SHARP")
        let openEditor = NSMenuItem(title: "SHARP Manual Depth Editor…", action: #selector(showSharpDepthEditor), keyEquivalent: "d")
        openEditor.keyEquivalentModifierMask = [.command, .shift]
        openEditor.target = self
        depthMenu.addItem(openEditor)
        let newEditor = NSMenuItem(title: "New Editor Session for Selected Photo…", action: #selector(newSharpDepthEditorSession), keyEquivalent: "")
        newEditor.target = self
        depthMenu.addItem(newEditor)
        let stopEditor = NSMenuItem(title: "Close Editor Session", action: #selector(closeSharpDepthEditorSession), keyEquivalent: "")
        stopEditor.target = self
        depthMenu.addItem(stopEditor)
        depthMenuItem.submenu = depthMenu
        mainMenu.addItem(depthMenuItem)
        // Optional donation support; no automatic prompts.
        let supportHelpMenuItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        let supportHelpMenu = NSMenu(title: "Help")
        let supportGuideItem = NSMenuItem(title: "Inject Z User Guide", action: #selector(showInjectZHelp(_:)), keyEquivalent: "?")
        supportGuideItem.keyEquivalentModifierMask = [.command]
        supportGuideItem.target = self
        supportHelpMenu.addItem(supportGuideItem)
        supportHelpMenu.addItem(NSMenuItem.separator())
        let helpUpdateItem = NSMenuItem(title: "Check for Updates…", action: #selector(checkForInjectZUpdates(_:)), keyEquivalent: "")
        helpUpdateItem.target = self
        supportHelpMenu.addItem(helpUpdateItem)
        let helpAutomaticItem = NSMenuItem(title: "Automatically Update While Closed", action: #selector(toggleAutomaticInjectZUpdates(_:)), keyEquivalent: "")
        helpAutomaticItem.target = self
        helpAutomaticItem.state = InjectZUpdates.automatic ? .on : .off
        supportHelpMenu.addItem(helpAutomaticItem)
        automaticUpdateItems.append(helpAutomaticItem)
        supportHelpMenu.addItem(NSMenuItem.separator())
        let supportMenuItem = NSMenuItem(title: "Support Inject Z…", action: #selector(InjectZSupportPanel.showSupport(_:)), keyEquivalent: "")
        supportMenuItem.target = InjectZSupportPanel.shared
        supportHelpMenu.addItem(supportMenuItem)
        supportHelpMenuItem.submenu = supportHelpMenu
        mainMenu.addItem(supportHelpMenuItem)
        NSApp.helpMenu = supportHelpMenu
        NSApp.mainMenu = mainMenu
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let photo = urls.first else { return }
        selectPhoto(photo)
        if mainUIReady {
            window?.makeKeyAndOrderFront(nil)
            NSRunningApplication.current.activate(options: [.activateAllWindows])
        }
    }

    func buildUI() {
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in self?.sharpDepthEditor?.stop() }
        let frame = NSRect(x: 0, y: 0, width: 600, height: 635)
        window = NSWindow(contentRect: frame,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Inject Z"
        window.isReleasedWhenClosed = false
        window.center()

        let c = DropView(frame: frame)
        c.onDrop = { [weak self] urls in self?.receiveDroppedImages(urls) }
        window.contentView = c

        func addLabel(_ text: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat = 120) {
            let f = NSTextField(labelWithString: text)
            f.frame = NSRect(x: x, y: y, width: w, height: 24)
            c.addSubview(f)
        }

        let title = NSTextField(labelWithString: "Inject Z")
        title.font = .systemFont(ofSize: 28, weight: .semibold)
        title.frame = NSRect(x: 30, y: 405, width: 200, height: 40)
        c.addSubview(title)

        let subtitle = NSTextField(labelWithString: "2D → Stereoscopic 3D")
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 31, y: 383, width: 260, height: 24)
        c.addSubview(subtitle)

        if let icon = NSImage(named: "InjectZHeader") {
            let iconView = NSImageView(frame: NSRect(x: 492, y: 375, width: 64, height: 64))
            iconView.image = icon
            iconView.imageScaling = .scaleProportionallyUpOrDown
            c.addSubview(iconView)
        }

        addLabel("Photo", 30, 340)
        photoField = NSTextField(labelWithString: "Drop a photo here or choose one…")
        photoField.lineBreakMode = .byTruncatingMiddle
        photoField.frame = NSRect(x: 145, y: 340, width: 280, height: 24)
        c.addSubview(photoField)

        let choose = NSButton(title: "Choose Photo…", target: self, action: #selector(choosePhoto))
        choose.frame = NSRect(x: 435, y: 334, width: 135, height: 32)
        c.addSubview(choose)

        addLabel("Engine", 30, 295)
        enginePopup = NSPopUpButton(frame: NSRect(x: 145, y: 291, width: 220, height: 30))
        enginePopup.addItems(withTitles: ["SHARP (Gaussian splats)", "IW3", "Apple Reframe"])
        enginePopup.target = self
        enginePopup.action = #selector(engineChanged)
        c.addSubview(enginePopup)
        sharpDepthEditorButton = NSButton(title: "Manual Depth Editor…", target: self, action: #selector(showSharpDepthEditor))
        sharpDepthEditorButton.frame = NSRect(x: 375, y: 291, width: 195, height: 30)
        c.addSubview(sharpDepthEditorButton)

        depthLabel = NSTextField(labelWithString: "Depth")
        depthLabel.frame = NSRect(x: 30, y: 255, width: 120, height: 24)
        c.addSubview(depthLabel)
        depthPopup = NSPopUpButton(frame: NSRect(x: 145, y: 251, width: 220, height: 30))
        depthPopup.addItems(withTitles: ["Low (0.010)", "Medium (0.020)", "Strong (0.040)", "Very Strong (0.060)", "Extra Strong (0.080)", "Maximum (0.100)", "Extreme (0.120)"])
        depthPopup.addItem(withTitle: "Custom depth…")
        depthPopup.target = self
        depthPopup.action = #selector(depthChanged(_:))
        depthPopup.selectItem(at: 3)
        c.addSubview(depthPopup)

        iw3ModelLabel = NSTextField(labelWithString: "IW3 Model")
        iw3ModelLabel.frame = NSRect(x: 380, y: 295, width: 160, height: 24)
        c.addSubview(iw3ModelLabel)
        iw3ModelPopup = NSPopUpButton(frame: NSRect(x: 375, y: 251, width: 195, height: 30))
        iw3ModelPopup.addItems(withTitles: ["DepthPro", "ZoeD_N", "ZoeD_K", "ZoeD_NK", "Any_S", "Any_B", "Any_L", "ZoeD_Any_N", "ZoeD_Any_K", "Any_V2_S", "Any_V2_B", "Any_V2_L", "Any_V2_N", "Any_V2_K", "Any_V2_N_S", "Any_V2_N_B", "Any_V2_N_L", "Any_V2_K_S", "Any_V2_K_B", "Any_V2_K_L", "Distill_Any_S", "Distill_Any_B", "Distill_Any_L", "Any_V3_Mono", "Any_V3_Mono_01", "DepthPro_S", "VDA_S", "VDA_B", "VDA_L", "VDA_Metric", "VDA_Metric_S", "VDA_Metric_B", "VDA_Metric_L", "VDA_Stream_S", "VDA_Stream_B", "VDA_Stream_L", "VDA_Stream_Metric_S", "VDA_Stream_Metric_B", "VDA_Stream_Metric_L"])
        c.addSubview(iw3ModelPopup)
        iw3ModelLabel.isHidden = true
        iw3ModelPopup.isHidden = true

        addLabel("Stereo Formats", 30, 215)
        let names = ["Parallel", "Crossview", "Anaglyph Full Color", "Anaglyph Half Color", "Anaglyph Dubois"]
        let positions: [(CGFloat, CGFloat, CGFloat)] = [(145, 211, 110), (265, 211, 110), (385, 211, 205),
                                                       (145, 187, 200), (355, 187, 200)]
        for i in names.indices {
            let button = NSButton(checkboxWithTitle: names[i], target: nil, action: nil)
            button.frame = NSRect(x: positions[i].0, y: positions[i].1, width: positions[i].2, height: 24)
            button.state = i == 0 ? .on : .off
            c.addSubview(button)
            formatButtons.append(button)
        }
        advancedButton = NSButton(title: "Advanced IW3 Settings…", target: self, action: #selector(showAdvanced))
        advancedButton.frame = NSRect(x: 380, y: 147, width: 205, height: 30)
        advancedButton.isHidden = true
        c.addSubview(advancedButton)
        sharpEdgesButton = NSButton(title: "SHARP Edge Softening…", target: self, action: #selector(showSharpEdges))
        sharpEdgesButton.frame = NSRect(x: 380, y: 147, width: 205, height: 30)
        c.addSubview(sharpEdgesButton)

        keepEyes = NSButton(checkboxWithTitle: "Save separate left/right images", target: nil, action: nil)
        keepEyes.frame = NSRect(x: 145, y: 151, width: 225, height: 24)
        c.addSubview(keepEyes)

        allowWindowViolations = NSButton(checkboxWithTitle: "Allow window violations", target: nil, action: nil)
        allowWindowViolations.frame = NSRect(x: 145, y: 123, width: 260, height: 24)
        allowWindowViolations.state = .off
        c.addSubview(allowWindowViolations)

        convertButton = NSButton(title: "Convert", target: self, action: #selector(convert))
        convertButton.bezelStyle = .rounded
        convertButton.keyEquivalent = "\r"
        convertButton.frame = NSRect(x: 145, y: 82, width: 105, height: 34)
        c.addSubview(convertButton)

        depthMapButton = NSButton(title: "Generate Depth Map", target: self, action: #selector(generateDepthMap))
        depthMapButton.frame = NSRect(x: 253, y: 82, width: 170, height: 34)
        depthMapButton.isEnabled = false
        c.addSubview(depthMapButton)

        revealButton = NSButton(title: "Show Result in Finder", target: self, action: #selector(reveal))
        revealButton.frame = NSRect(x: 427, y: 82, width: 160, height: 34)
        revealButton.isEnabled = false
        c.addSubview(revealButton)

        resumeReframeButton = NSButton(title: "Resume Reframe…", target: self, action: #selector(resumeReframe))
        resumeReframeButton.frame = NSRect(x: 380, y: 147, width: 200, height: 27)
        resumeReframeButton.isHidden = true
        c.addSubview(resumeReframeButton)

        statusLabel = NSTextField(labelWithString: "Ready — Multi output R14. Drop a photo here.")
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingMiddle
        statusLabel.frame = NSRect(x: 30, y: 35, width: 540, height: 28)
        c.addSubview(statusLabel)

        // Make room for additional output controls below the format list.
        for view in c.subviews where view.frame.origin.y >= 180 {
            view.setFrameOrigin(NSPoint(x: view.frame.origin.x, y: view.frame.origin.y + 110))
        }
        for (index, title) in ["Left / Right / Left", "Parallel above Crossview"].enumerated() {
            let button = NSButton(checkboxWithTitle: title, target: nil, action: nil)
            button.frame = NSRect(x: index == 0 ? 145 : 355, y: 272, width: 220, height: 24)
            c.addSubview(button)
            formatButtons.append(button)
        }
        addLabel("Black border", 30, 234)
        borderPopup = NSPopUpButton(frame: NSRect(x: 145, y: 230, width: 150, height: 30))
        borderPopup.addItems(withTitles: ["None", "1%", "2%", "5%", "10%"])
        borderPopup.toolTip = "Black border added around each finished eye; percentage of the shorter image side."
        c.addSubview(borderPopup)
        addLabel("Corners", 310, 234, 75)
        cornersPopup = NSPopUpButton(frame: NSRect(x: 385, y: 230, width: 185, height: 30))
        cornersPopup.addItems(withTitles: ["Square", "Small (2%)", "Medium (5%)", "Large (10%)", "View-Master (20%)"])
        cornersPopup.toolTip = "Rounds each eye against black after conversion."
        c.addSubview(cornersPopup)

        for view in c.subviews {
            view.setFrameOrigin(NSPoint(x: view.frame.origin.x, y: view.frame.origin.y + 55))
        }
        addLabel("Preset", 30, 26, 70)
        presetPopup = NSPopUpButton(frame: NSRect(x: 98, y: 21, width: 205, height: 30))
        presetPopup.target = self
        presetPopup.action = #selector(loadPreset)
        c.addSubview(presetPopup)
        let savePresetButton = NSButton(title: "Save as a Preset…", target: self, action: #selector(savePreset))
        savePresetButton.frame = NSRect(x: 310, y: 21, width: 165, height: 30)
        c.addSubview(savePresetButton)
        let deletePresetButton = NSButton(title: "Delete…", target: self, action: #selector(deletePreset))
        deletePresetButton.frame = NSRect(x: 478, y: 21, width: 92, height: 30)
        c.addSubview(deletePresetButton)
        refreshPresets()

        // Keep the five common formats visible and move the other options into
        // a disclosure area. Reparenting keeps all existing targets and state.
        for view in c.subviews where view.frame.origin.y >= 340 {
            view.setFrameOrigin(NSPoint(x: view.frame.origin.x, y: view.frame.origin.y - 165))
            elevatedViews.append(view)
        }
        for view in [advancedButton!, sharpEdgesButton!, resumeReframeButton!] {
            view.setFrameOrigin(NSPoint(x: view.frame.origin.x, y: 147))
            elevatedViews.append(view)
        }
        for view in [convertButton!, depthMapButton!, revealButton!, statusLabel!] {
            view.setFrameOrigin(NSPoint(x: view.frame.origin.x, y: view.frame.origin.y - 55))
        }
        for view in c.subviews {
            if let label = view as? NSTextField, ["Black border", "Corners", "Preset"].contains(label.stringValue) {
                label.removeFromSuperview()
            }
        }
        additionalSection = NSView(frame: NSRect(x: 0, y: 115, width: 600, height: 290))
        c.addSubview(additionalSection)
        func inSection(_ view: NSView, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat = 25) {
            view.removeFromSuperview(); view.frame = NSRect(x: x, y: y, width: w, height: h)
            additionalSection.addSubview(view)
        }
        inSection(formatButtons[5], 20, 175, 190)
        inSection(formatButtons[6], 220, 175, 230)
        inSection(keepEyes, 20, 145, 250)
        inSection(allowWindowViolations, 290, 145, 260)
        let borderLabel = NSTextField(labelWithString: "Black border")
        inSection(borderLabel, 20, 112, 100)
        inSection(borderPopup, 120, 109, 125, 30)
        let cornerLabel = NSTextField(labelWithString: "Corners")
        inSection(cornerLabel, 260, 112, 70)
        inSection(cornersPopup, 330, 109, 215, 30)
        wiggleOption = NSButton(checkboxWithTitle: "Multi-frame wigglegram (SHARP)", target: nil, action: nil)
        wiggleOption.toolTip = "For an imported stereo pair SHARP reconstructs the left eye; the wigglegram does not use the right eye."
        inSection(wiggleOption, 20, 78, 270)
        let framesLabel = NSTextField(labelWithString: "Middle frames")
        inSection(framesLabel, 290, 78, 100)
        wiggleFrames = NSPopUpButton(frame: .zero)
        wiggleFrames.addItems(withTitles: ["4", "8", "16", "20", "24", "25", "32", "48", "50", "60"]); wiggleFrames.selectItem(at: 1)
        wiggleFrames.toolTip = "The exported sequence includes both end views in addition to these middle views."
        inSection(wiggleFrames, 390, 75, 62, 30)
        wiggleFPS = NSPopUpButton(frame: .zero)
        wiggleFPS.addItems(withTitles: ["12 fps", "24 fps", "30 fps", "60 fps"]); wiggleFPS.selectItem(at: 1)
        inSection(wiggleFPS, 455, 75, 100, 30)
        let presetLabel = NSTextField(labelWithString: "Preset")
        inSection(presetLabel, 20, 38, 55)
        inSection(presetPopup, 75, 34, 190, 30)
        inSection(savePresetButton, 270, 34, 165, 30)
        inSection(deletePresetButton, 440, 34, 100, 30)
        for view in additionalSection.subviews {
            view.setFrameOrigin(NSPoint(x: view.frame.origin.x, y: view.frame.origin.y + 85))
        }
        wiggleViews = NSButton(checkboxWithTitle: "Export all views as PNGs", target: nil, action: nil)
        wiggleViews.toolTip = "Save one numbered left-to-right sequence including both end views; no interlacing is performed."
        inSection(wiggleViews, 20, 82, 280)
        wiggleCard = NSButton(checkboxWithTitle: "Stereo-card frame", target: nil, action: nil)
        wiggleCard.toolTip = "Frame all finished stereo exports and wigglegram views after rendering."
        inSection(wiggleCard, 20, 45, 180)
        wiggleCardColor = NSColorWell(frame: .zero)
        wiggleCardColor.color = NSColor(srgbRed: 0.88, green: 0.79, blue: 0.62, alpha: 1)
        wiggleCardColor.toolTip = "Stereo-card background color"
        inSection(wiggleCardColor, 202, 41, 48, 30)
        let titleLabel = NSTextField(labelWithString: "Title")
        inSection(titleLabel, 260, 45, 45)
        wiggleCardTitle = NSTextField(frame: .zero)
        wiggleCardTitle.placeholderString = "Optional caption"
        inSection(wiggleCardTitle, 305, 42, 250, 26)
        additionalSection.isHidden = true
        additionalToggle = NSButton(title: "▸ Additional Export Options", target: self, action: #selector(toggleAdditional))
        additionalToggle.frame = NSRect(x: 25, y: 121, width: 245, height: 27)
        additionalToggle.bezelStyle = .recessed
        c.addSubview(additionalToggle)
        elevatedViews.append(additionalToggle)
        window.contentMinSize = NSSize(width: 600, height: 470)
        window.setContentSize(NSSize(width: 600, height: 470))
        window.center()

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func toggleAdditional() {
        let delta: CGFloat = additionalExpanded ? -290 : 290
        additionalExpanded.toggle()
        for view in elevatedViews { view.setFrameOrigin(NSPoint(x: view.frame.origin.x, y: view.frame.origin.y + delta)) }
        additionalSection.isHidden = !additionalExpanded
        additionalToggle.title = additionalExpanded ? "▾ Additional Export Options" : "▸ Additional Export Options"
        if !additionalExpanded { window.contentMinSize = NSSize(width: 600, height: 470) }
        var frame = window.frame
        frame.origin.y -= delta; frame.size.height += delta
        window.setFrame(frame, display: true, animate: true)
        if additionalExpanded { window.contentMinSize = NSSize(width: 600, height: 760) }
    }

    func allPresets() -> [String: [String: Any]] {
        UserDefaults.standard.dictionary(forKey: presetsKey) as? [String: [String: Any]] ?? [:]
    }

    func refreshPresets(select name: String? = nil) {
        presetPopup.removeAllItems()
        presetPopup.addItem(withTitle: "Choose a preset…")
        presetPopup.addItems(withTitles: allPresets().keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        if let name = name { presetPopup.selectItem(withTitle: name) }
    }

    @objc func savePreset() {
        let alert = NSAlert()
        alert.messageText = "Save as a Preset"
        alert.informativeText = "Name this combination of conversion and output settings."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 26))
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty && name != "Choose a preset…" else {
            statusLabel.stringValue = "Enter a name for the preset."; return
        }
        var presets = allPresets()
        if presets[name] != nil {
            let confirm = NSAlert()
            confirm.messageText = "Replace preset ‘\(name)’?"
            confirm.informativeText = "Its saved settings will be replaced with the current settings."
            confirm.addButton(withTitle: "Replace")
            confirm.addButton(withTitle: "Cancel")
            guard confirm.runModal() == .alertFirstButtonReturn else { return }
        }
        ensureAdvanced()
        ensureSharpEdges()
        var extra: [String: String] = [:]
        for (flag, control, _) in extraIW3Controls {
            if let popup = control as? NSPopUpButton { extra[flag] = popup.titleOfSelectedItem ?? "" }
            else if let field = control as? NSTextField { extra[flag] = field.stringValue }
        }
        presets[name] = [
            "engine": enginePopup.indexOfSelectedItem,
            "depth": depthPopup.indexOfSelectedItem,
            "customDepth": customSharpDepth,
            "model": iw3ModelPopup.titleOfSelectedItem ?? "DepthPro",
            "formats": selectedFormats(),
            "border": borderPopup.indexOfSelectedItem,
            "corners": cornersPopup.indexOfSelectedItem,
            "keepEyes": keepEyes.state == .on,
            "allowWindow": allowWindowViolations.state == .on,
            "soften": softenSharpEdges?.state == .on,
            "edgeRadius": edgeRadius?.doubleValue ?? 2,
            "edgeStrength": edgeStrength?.doubleValue ?? 0.35,
            "wiggle": wiggleOption.state == .on,
            "wiggleViews": wiggleViews.state == .on,
            "wiggleFrames": wiggleFrames.indexOfSelectedItem,
            "wiggleFramesValue": wiggleFrames.titleOfSelectedItem ?? "8",
            "wiggleFPS": wiggleFPS.indexOfSelectedItem,
            "wiggleCard": wiggleCard.state == .on,
            "wiggleCardColor": cardColorHex(),
            "wiggleCardTitle": wiggleCardTitle.stringValue,
            "method": methodPopup.titleOfSelectedItem ?? "forward_inpaint",
            "convergence": convergenceField.stringValue,
            "foreground": foregroundField.stringValue,
            "preserveBorder": preserveBorder.state == .on,
            "depthAA": depthAA.state == .on,
            "extraIW3": extra
        ]
        UserDefaults.standard.set(presets, forKey: presetsKey)
        refreshPresets(select: name)
        statusLabel.stringValue = "Preset saved: \(name)"
    }

    @objc func loadPreset() {
        guard presetPopup.indexOfSelectedItem > 0,
              let name = presetPopup.titleOfSelectedItem, let p = allPresets()[name],
              let engine = p["engine"] as? Int, (0..<enginePopup.numberOfItems).contains(engine) else { return }
        ensureAdvanced()
        ensureSharpEdges()
        customSharpDepth = p["customDepth"] as? Double ?? 0.250
        enginePopup.selectItem(at: engine)
        engineChanged()
        if let item = depthPopup.itemArray.first(where: { $0.title.hasPrefix("Custom depth") }) {
            item.title = String(format: "Custom depth (%.3f)…", customSharpDepth)
        }
        if let depth = p["depth"] as? Int, (0..<depthPopup.numberOfItems).contains(depth) { depthPopup.selectItem(at: depth) }
        if let model = p["model"] as? String, iw3ModelPopup.itemTitles.contains(model) { iw3ModelPopup.selectItem(withTitle: model) }
        let formats = Set(p["formats"] as? [String] ?? [])
        for (button, id) in zip(formatButtons, formatIDs) { button.state = formats.contains(id) ? .on : .off }
        if let index = p["border"] as? Int, (0..<borderPopup.numberOfItems).contains(index) { borderPopup.selectItem(at: index) }
        if let index = p["corners"] as? Int, (0..<cornersPopup.numberOfItems).contains(index) { cornersPopup.selectItem(at: index) }
        keepEyes.state = (p["keepEyes"] as? Bool ?? false) ? .on : .off
        allowWindowViolations.state = (p["allowWindow"] as? Bool ?? false) ? .on : .off
        softenSharpEdges?.state = (p["soften"] as? Bool ?? false) ? .on : .off
        edgeRadius?.doubleValue = p["edgeRadius"] as? Double ?? 2
        edgeStrength?.doubleValue = p["edgeStrength"] as? Double ?? 0.35
        wiggleOption.state = (p["wiggle"] as? Bool ?? false) ? .on : .off
        wiggleViews.state = (p["wiggleViews"] as? Bool ?? false) ? .on : .off
        if let value = p["wiggleFramesValue"] as? String, wiggleFrames.itemTitles.contains(value) {
            wiggleFrames.selectItem(withTitle: value)
        } else if let index = p["wiggleFrames"] as? Int, (0..<4).contains(index) {
            wiggleFrames.selectItem(withTitle: ["4", "8", "16", "32"][index])
        }
        if let value = p["wiggleFPS"] as? Int, (0..<wiggleFPS.numberOfItems).contains(value) { wiggleFPS.selectItem(at: value) }
        wiggleCard.state = (p["wiggleCard"] as? Bool ?? false) ? .on : .off
        wiggleCardTitle.stringValue = p["wiggleCardTitle"] as? String ?? ""
        if let hex = p["wiggleCardColor"] as? String, hex.hasPrefix("#"), hex.count == 7,
           let value = Int(hex.dropFirst(), radix: 16) {
            wiggleCardColor.color = NSColor(srgbRed: CGFloat((value >> 16) & 255) / 255,
                                           green: CGFloat((value >> 8) & 255) / 255,
                                           blue: CGFloat(value & 255) / 255, alpha: 1)
        }
        edgeValuesChanged()
        if let method = p["method"] as? String, methodPopup.itemTitles.contains(method) { methodPopup.selectItem(withTitle: method) }
        convergenceField.stringValue = p["convergence"] as? String ?? "0.25"
        foregroundField.stringValue = p["foreground"] as? String ?? "0"
        preserveBorder.state = (p["preserveBorder"] as? Bool ?? true) ? .on : .off
        depthAA.state = (p["depthAA"] as? Bool ?? false) ? .on : .off
        let extra = p["extraIW3"] as? [String: String] ?? [:]
        for (flag, control, _) in extraIW3Controls {
            if let popup = control as? NSPopUpButton {
                if let value = extra[flag], popup.itemTitles.contains(value) { popup.selectItem(withTitle: value) }
                else { popup.selectItem(at: 0) }
            } else if let field = control as? NSTextField { field.stringValue = extra[flag] ?? "" }
        }
        statusLabel.stringValue = "Preset loaded: \(name)"
    }

    @objc func deletePreset() {
        guard presetPopup.indexOfSelectedItem > 0, let name = presetPopup.titleOfSelectedItem else { return }
        let alert = NSAlert()
        alert.messageText = "Delete preset ‘\(name)’?"
        alert.informativeText = "Your current conversion settings will remain in place."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        var presets = allPresets(); presets.removeValue(forKey: name)
        UserDefaults.standard.set(presets, forKey: presetsKey)
        refreshPresets()
        statusLabel.stringValue = "Preset deleted: \(name)"
    }

    @objc func depthChanged(_ sender: NSPopUpButton) {
        guard enginePopup.indexOfSelectedItem == 0,
              sender.titleOfSelectedItem?.hasPrefix("Custom depth") == true else { return }
        let alert = NSAlert()
        alert.messageText = "Custom SHARP depth"
        alert.informativeText = "Enter a camera separation from 0.001 to 10.000 (up to three decimal places). Try 0.250, then 0.500. Larger values may reveal reconstruction artifacts."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 26))
        field.stringValue = String(format: "%.3f", customSharpDepth)
        alert.accessoryView = field
        alert.addButton(withTitle: "Use Depth")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        while true {
            guard alert.runModal() == .alertFirstButtonReturn else {
                sender.selectItem(at: 3)
                return
            }
            let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
            if let value = Double(text), value.isFinite, value >= 0.001, value <= 10.0 {
                customSharpDepth = (value * 1000).rounded() / 1000
                sender.selectedItem?.title = String(format: "Custom depth (%.3f)…", customSharpDepth)
                return
            }
            alert.informativeText = "Please enter a number between 0.001 and 10.000."
        }
    }

    @objc func engineChanged() {
        sharpDepthEditorButton?.isHidden = enginePopup.indexOfSelectedItem != 0
        if enginePopup.indexOfSelectedItem != 0,
           let item = depthPopup.itemArray.first(where: { $0.title.hasPrefix("Custom depth") }) {
            if depthPopup.selectedItem === item { depthPopup.selectItem(at: 3) }
            depthPopup.removeItem(withTitle: item.title)
            if sharpDepthSelection > 6 { sharpDepthSelection = 3 }
        }
        let iw3 = enginePopup.indexOfSelectedItem == 1
        if iw3 {
            sharpDepthSelection = depthPopup.indexOfSelectedItem
            depthLabel.stringValue = "3D Strength"
            depthPopup.removeAllItems()
            depthPopup.addItems(withTitles: ["1.0", "2.0", "3.0", "4.0", "5.0", "6.0"])
            depthPopup.selectItem(at: iw3StrengthSelection)
        } else {
            if depthLabel.stringValue == "3D Strength" {
                iw3StrengthSelection = depthPopup.indexOfSelectedItem
                depthPopup.removeAllItems()
                depthPopup.addItems(withTitles: ["Low (0.010)", "Medium (0.020)", "Strong (0.040)", "Very Strong (0.060)", "Extra Strong (0.080)", "Maximum (0.100)", "Extreme (0.120)"])
                depthPopup.selectItem(at: sharpDepthSelection)
            }
            depthLabel.stringValue = "Depth"
        }
        if enginePopup.indexOfSelectedItem == 0,
           !depthPopup.itemArray.contains(where: { $0.title.hasPrefix("Custom depth") }) {
            depthPopup.addItem(withTitle: String(format: "Custom depth (%.3f)…", customSharpDepth))
        }
        iw3ModelLabel.isHidden = !iw3
        iw3ModelPopup.isHidden = !iw3
        advancedButton.isHidden = !iw3
        sharpEdgesButton.isHidden = enginePopup.indexOfSelectedItem != 0
        depthMapButton.isEnabled = iw3
        keepEyes.isEnabled = stereoInputFormat != nil || !iw3
        keepEyes.isHidden = stereoInputFormat == nil && (iw3 || enginePopup.indexOfSelectedItem == 2)
        allowWindowViolations.isEnabled = true
        resumeReframeButton.isHidden = enginePopup.indexOfSelectedItem != 2
        if enginePopup.indexOfSelectedItem == 2 {
            statusLabel.stringValue = "Apple Reframe uses the dedicated Photos working library."
        } else {
            statusLabel.stringValue = "Ready"
        }
    }

    var iw3SettingHelp: [String: String] = [:]
    func loadIW3SettingHelp() {
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("InjectZ/IW3SettingHelp.json")
        if let data = try? Data(contentsOf: url),
           let help = (try? JSONSerialization.jsonObject(with: data)) as? [String: String] {
            iw3SettingHelp = help
        }
    }
    func addIW3HelpButton(_ parent: NSView, _ flag: String, _ x: CGFloat, _ y: CGFloat) {
        let button = NSButton(title: "What is this?", target: self, action: #selector(showIW3SettingHelp(_:)))
        button.frame = NSRect(x: x, y: y, width: 120, height: 28)
        button.bezelStyle = .rounded
        button.identifier = NSUserInterfaceItemIdentifier(flag)
        parent.addSubview(button)
    }
    @objc func showIW3SettingHelp(_ sender: NSButton) {
        guard let flag = sender.identifier?.rawValue else { return }
        let alert = NSAlert()
        alert.messageText = flag.replacingOccurrences(of: "--", with: "").replacingOccurrences(of: "-", with: " ").capitalized
        alert.informativeText = iw3SettingHelp[flag] ?? "This setting’s explanation is unavailable. Reinstall the setting-help update."
        alert.addButton(withTitle: "OK")
        if let panel = advancedPanel {
            alert.beginSheetModal(for: panel, completionHandler: { _ in })
        } else {
            alert.runModal()
        }
    }

    var extraIW3Controls: [(String, NSControl, Bool)] = []
    func buildExtraIW3Settings(_ content: NSView) {
        let path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("InjectZ/IW3Settings.json")
        guard let data = try? Data(contentsOf: path),
              let rows = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { return }
        let scroll = NSScrollView(frame: NSRect(x: 15, y: 15, width: 680, height: 390))
        scroll.hasVerticalScroller = true
        let doc = NSView(frame: NSRect(x: 0, y: 0, width: 650, height: CGFloat(rows.count * 76)))
        scroll.documentView = doc
        content.addSubview(scroll)
        for (i, row) in rows.enumerated() {
            guard let flag = row["flag"] as? String else { continue }
            let y = doc.frame.height - CGFloat((i + 1) * 76)
            let label = NSTextField(labelWithString: flag.replacingOccurrences(of: "--", with: "").replacingOccurrences(of: "-", with: " ").capitalized)
            label.frame = NSRect(x: 8, y: y + 44, width: 275, height: 22)
            doc.addSubview(label)
            let action = row["action"] as? String ?? ""
            let defaultLabel = row["defaultLabel"] as? String ?? "Not set"
            let choices = row["choices"] as? [Any] ?? []
            let control: NSControl
            if !action.isEmpty {
                let popup = NSPopUpButton(frame: NSRect(x: 285, y: y + 40, width: 225, height: 28))
                popup.addItems(withTitles: [defaultLabel, action == "store_false" ? "Off" : "On"])
                popup.item(at: 1)?.tag = 1
                control = popup
            } else if !choices.isEmpty {
                let popup = NSPopUpButton(frame: NSRect(x: 285, y: y + 40, width: 225, height: 28))
                popup.addItems(withTitles: [defaultLabel] + choices.map { String(describing: $0) }.filter { $0 != defaultLabel })
                control = popup
            } else {
                let field = NSTextField(frame: NSRect(x: 285, y: y + 40, width: 225, height: 26))
                field.placeholderString = defaultLabel
                control = field
            }
            control.toolTip = row["help"] as? String
            doc.addSubview(control)
            addIW3HelpButton(doc, flag, 520, y + 40)
            extraIW3Controls.append((flag, control, row["multiple"] as? Bool ?? false))
            let hint = NSTextField(wrappingLabelWithString: row["help"] as? String ?? "")
            hint.frame = NSRect(x: 8, y: y + 3, width: 620, height: 36)
            hint.font = NSFont.systemFont(ofSize: 11)
            hint.textColor = .secondaryLabelColor
            hint.maximumNumberOfLines = 2
            doc.addSubview(hint)
        }
        doc.scroll(NSPoint(x: 0, y: doc.frame.height))
    }
    func extraIW3Arguments() -> [String] {
        var args: [String] = []
        for (flag, control, multiple) in extraIW3Controls {
            if let popup = control as? NSPopUpButton {
                if popup.indexOfSelectedItem > 0 {
                    args.append(flag)
                    let value = popup.titleOfSelectedItem ?? ""
                    if popup.selectedItem?.tag != 1 { args.append(value) }
                }
            } else if let field = control as? NSTextField {
                let value = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    args.append(flag)
                    args += multiple ? value.split(whereSeparator: { $0.isWhitespace }).map(String.init) : [value]
                }
            }
        }
        return args
    }

    @objc func showAdvanced() {
        ensureAdvanced()
        advancedPanel?.makeKeyAndOrderFront(nil)
    }
    func ensureAdvanced() {
        if advancedPanel != nil { return }
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 410, width: 710, height: 740),
                            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.title = "Advanced IW3 Settings"
        panel.center()
        guard let content = panel.contentView else { return }
        func label(_ title: String, _ y: CGFloat) {
            let view = NSTextField(labelWithString: title)
            view.frame = NSRect(x: 20, y: y, width: 175, height: 24)
            content.addSubview(view)
        }
        label("Stereo generation method", 677)
        methodPopup = NSPopUpButton(frame: NSRect(x: 200, y: 673, width: 265, height: 28))
        methodPopup.addItems(withTitles: ["mlbw_l2_inpaint", "row_flow", "row_flow_v3", "grid_sample", "backward", "forward", "forward_fill", "forward_inpaint", "mlbw_l2", "mlbw_l4", "mlbw_l2s", "mlbw_l4s", "mask_mlbw_l2", "row_flow_sym", "row_flow_v3_sym", "row_flow_v2"])
        methodPopup.selectItem(withTitle: "forward_inpaint")
        content.addSubview(methodPopup)
        label("Convergence (0–1)", 630)
        convergenceField = NSTextField(frame: NSRect(x: 200, y: 627, width: 100, height: 26))
        convergenceField.stringValue = "0.25"
        content.addSubview(convergenceField)
        label("Foreground scale (-3–3)", 585)
        foregroundField = NSTextField(frame: NSRect(x: 200, y: 582, width: 100, height: 26))
        foregroundField.stringValue = "0"
        content.addSubview(foregroundField)
        preserveBorder = NSButton(checkboxWithTitle: "Use IW3 border preservation (experimental)", target: nil, action: nil)
        preserveBorder.frame = NSRect(x: 20, y: 535, width: 400, height: 25)
        preserveBorder.state = .on
        content.addSubview(preserveBorder)
        depthAA = NSButton(checkboxWithTitle: "Depth anti-aliasing (supported models only)", target: nil, action: nil)
        depthAA.frame = NSRect(x: 20, y: 503, width: 400, height: 25)
        content.addSubview(depthAA)
        let hint = NSTextField(labelWithString: "Four-edge depth protection is active unless Allow window violations is checked.")
        hint.frame = NSRect(x: 20, y: 435, width: 450, height: 44)
        hint.maximumNumberOfLines = 2
        hint.textColor = .secondaryLabelColor
        content.addSubview(hint)
        loadIW3SettingHelp()
        addIW3HelpButton(content, "--method", 485, 673)
        addIW3HelpButton(content, "--convergence", 485, 627)
        addIW3HelpButton(content, "--foreground-scale", 485, 582)
        addIW3HelpButton(content, "--preserve-screen-border", 485, 533)
        addIW3HelpButton(content, "--depth-aa", 485, 501)
        buildExtraIW3Settings(content)
        advancedPanel = panel
    }

    func refreshRelatedApps() {
        guard let menu = relatedAppsMenu else { return }
        menu.removeAllItems()
        let builtins: [(String, [String], String)] = [
            ("Ted's Video Tool", ["TVT.app", "TVT_Ted's Video Tool.app"], "https://github.com/TedInVR/TVT-Teds_Video_Tool"),
            ("StereoMask for Mac", ["StereoMask.app"], "https://github.com/TedInVR/StereoMask-Mac"),
            ("VM ReSizer", ["VM Re-Sizer.app", "VM ReSizer.app", "VMReSizer.app"], "https://github.com/TedInVR/VMReSizer"),
            ("Stereo Slideshow", ["Stereo Slideshow.app", "StereoSlideshow.app"], "https://github.com/TedInVR/StereoSlideshow")
        ]
        for (name, names, link) in builtins {
            let item = NSMenuItem(title: name + "…", action: #selector(openRelatedApp(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = ["names": names, "url": link]
            menu.addItem(item)
        }
        let custom = UserDefaults.standard.array(forKey: relatedAppsKey) as? [[String: String]] ?? []
        if !custom.isEmpty { menu.addItem(NSMenuItem.separator()) }
        for app in custom {
            guard let name = app["name"], let path = app["path"] else { continue }
            let item = NSMenuItem(title: name, action: #selector(openRelatedApp(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = ["path": path]; menu.addItem(item)
        }
        menu.addItem(NSMenuItem.separator())
        let add = NSMenuItem(title: "Add an App…", action: #selector(addRelatedApp), keyEquivalent: "")
        add.target = self; menu.addItem(add)
        if !custom.isEmpty {
            let remove = NSMenuItem(title: "Remove an Added App…", action: #selector(removeRelatedApp), keyEquivalent: "")
            remove.target = self; menu.addItem(remove)
        }
    }

    @objc func openRelatedApp(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? [String: Any] else { return }
        var paths: [URL] = []
        if let path = info["path"] as? String { paths.append(URL(fileURLWithPath: path)) }
        if let names = info["names"] as? [String] {
            for name in names { paths.append(URL(fileURLWithPath: "/Applications").appendingPathComponent(name)) }
        }
        if let found = paths.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            NSWorkspace.shared.open(found); return
        }
        let link = info["url"] as? String ?? ""
        let alert = NSAlert(); alert.messageText = "\(sender.title.replacingOccurrences(of: "…", with: "")) was not found"
        alert.informativeText = link.isEmpty ? "If it is installed elsewhere, use Apps → Add an App to locate it. A public download is not yet available." : "Open the project's GitHub page for its download and installation instructions. If it is already installed elsewhere, use Apps → Add an App."
        if !link.isEmpty { alert.addButton(withTitle: "Open Project Page") }
        alert.addButton(withTitle: "OK")
        if alert.runModal() == .alertFirstButtonReturn, let url = URL(string: link), !link.isEmpty { NSWorkspace.shared.open(url) }
    }

    @objc func addRelatedApp() {
        let p = NSOpenPanel(); p.message = "Choose an installed application."; p.allowedContentTypes = [.applicationBundle]
        p.canChooseFiles = true; p.canChooseDirectories = false
        guard p.runModal() == .OK, let url = p.url else { return }
        var apps = UserDefaults.standard.array(forKey: relatedAppsKey) as? [[String: String]] ?? []
        guard !apps.contains(where: { $0["path"] == url.path }) else { return }
        apps.append(["name": url.deletingPathExtension().lastPathComponent, "path": url.path])
        UserDefaults.standard.set(apps, forKey: relatedAppsKey); refreshRelatedApps()
    }

    @objc func removeRelatedApp() {
        var apps = UserDefaults.standard.array(forKey: relatedAppsKey) as? [[String: String]] ?? []
        guard !apps.isEmpty else { return }
        let alert = NSAlert(); alert.messageText = "Remove an Added App"
        alert.informativeText = "This removes the shortcut, not the app."
        let choices = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 30))
        choices.addItems(withTitles: apps.map { $0["name"] ?? "App" }); alert.accessoryView = choices
        alert.addButton(withTitle: "Remove"); alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        apps.remove(at: choices.indexOfSelectedItem); UserDefaults.standard.set(apps, forKey: relatedAppsKey); refreshRelatedApps()
    }

    @objc func choosePhoto() {
        let p = NSOpenPanel()
        p.allowsMultipleSelection = false
        p.canChooseDirectories = false
        p.allowedContentTypes = [.image]
        if p.runModal() == .OK, let u = p.url { selectPhoto(u) }
    }

    func selectPhoto(_ u: URL) {
        // Launch Services may deliver the dropped photo before buildUI finishes.
        // Queue it without dereferencing any implicitly unwrapped UI controls.
        guard mainUIReady, photoField != nil, statusLabel != nil, revealButton != nil else {
            pendingLaunchPhoto = u
            return
        }
        selectedPhoto = u
        stereoInputFormat = nil
        stereoRightEye = nil
        keepEyes?.isHidden = enginePopup.indexOfSelectedItem != 0
        keepEyes?.isEnabled = enginePopup.indexOfSelectedItem == 0
        photoField.stringValue = u.lastPathComponent
        statusLabel.stringValue = "Ready"
        revealButton.isEnabled = false
        lastOutput = nil
    }

    func chooseStereoOrder(_ url: URL, includePhotoChoice: Bool) {
        let alert = NSAlert(); alert.messageText = "How is this image arranged?"
        alert.informativeText = "For stereo images choose the order of the full-width eye views."
        alert.addButton(withTitle: "Parallel (Left / Right)")
        alert.addButton(withTitle: "Crossview (Right / Left)")
        alert.addButton(withTitle: includePhotoChoice ? "Single 2D Photo" : "Cancel")
        let result = alert.runModal()
        if result == .alertThirdButtonReturn { if includePhotoChoice { selectPhoto(url) }; return }
        guard result == .alertFirstButtonReturn || result == .alertSecondButtonReturn else { return }
        selectPhoto(url)
        stereoInputFormat = result == .alertFirstButtonReturn ? "parallel" : "crossview"
        keepEyes.isHidden = false; keepEyes.isEnabled = true
        photoField.stringValue = "Stereo \(stereoInputFormat!): \(url.lastPathComponent)"
        statusLabel.stringValue = "Stereo image ready to export."
    }

    func chooseEyeOrder(_ urls: [URL]) {
        guard urls.count == 2 else { statusLabel.stringValue = "Select exactly two eye images."; return }
        let alert = NSAlert(); alert.messageText = "Which image is the left eye?"
        alert.informativeText = "First: \(urls[0].lastPathComponent)\nSecond: \(urls[1].lastPathComponent)"
        alert.addButton(withTitle: "First is Left"); alert.addButton(withTitle: "Second is Left"); alert.addButton(withTitle: "Cancel")
        let choice = alert.runModal()
        guard choice == .alertFirstButtonReturn || choice == .alertSecondButtonReturn else { return }
        let left = choice == .alertFirstButtonReturn ? urls[0] : urls[1]
        let right = choice == .alertFirstButtonReturn ? urls[1] : urls[0]
        selectPhoto(left); stereoInputFormat = "eyes"; stereoRightEye = right
        keepEyes.isHidden = false; keepEyes.isEnabled = true
        photoField.stringValue = "L: \(left.lastPathComponent)  R: \(right.lastPathComponent)"
        statusLabel.stringValue = "Separate left and right eyes ready to export."
    }

    func receiveDroppedImages(_ urls: [URL]) {
        if urls.count == 1 { chooseStereoOrder(urls[0], includePhotoChoice: true) }
        else { chooseEyeOrder(urls) }
    }

    @objc func openStereoImage() {
        let p = NSOpenPanel(); p.allowsMultipleSelection = false; p.allowedContentTypes = [.image]
        if p.runModal() == .OK, let u = p.url { chooseStereoOrder(u, includePhotoChoice: false) }
    }

    @objc func openStereoEyes() {
        let p = NSOpenPanel(); p.allowsMultipleSelection = true; p.allowedContentTypes = [.image]
        p.message = "Select exactly two images, then identify the left eye."
        if p.runModal() == .OK { chooseEyeOrder(p.urls) }
    }

    @objc func convert() {
        if let editor = sharpDepthEditor, editor.task.isRunning {
            statusLabel.stringValue = "Finish the editor session first: SHARP menu → Close Editor Session."
            return
        }
        runConversion(depthMapOnly: false)
    }

    @objc func generateDepthMap() {
        runConversion(depthMapOnly: true)
    }

    func extractStereoLeft(_ source: URL, inputFormat: String, rightEye: URL?) -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let helper = home.appendingPathComponent("InjectZ/Development/Reframe/SharedStereoFormats.py")
        let python = home.appendingPathComponent("InjectZ/Development/IW3/python/bin/python")
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("InjectZ-Stereo-" + UUID().uuidString)
        do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) } catch { return nil }
        let prefix = folder.appendingPathComponent("Left-" + UUID().uuidString)
        let process = Process(); process.executableURL = python
        var args = [helper.path, source.path, "--input-format", inputFormat, "--output-prefix", prefix.path,
                    "--depth-token", "Source"]
        if let rightEye = rightEye { args += ["--right-eye", rightEye.path] }
        process.arguments = args + ["--formats", "LeftEye"]
        process.standardOutput = FileHandle.nullDevice; process.standardError = FileHandle.nullDevice
        do {
            try process.run(); process.waitUntilExit()
            let output = URL(fileURLWithPath: prefix.path + "_LeftEye_DepthSource.png")
            guard process.terminationStatus == 0, FileManager.default.fileExists(atPath: output.path) else { return nil }
            return output
        } catch { return nil }
    }

    func runConversion(depthMapOnly: Bool) {
        guard let originalPhoto = selectedPhoto else {
            NSSound.beep()
            statusLabel.stringValue = "Choose or drop a photo first."
            return
        }
        let formats = selectedFormats() + (stereoInputFormat == nil && enginePopup.indexOfSelectedItem == 0 && keepEyes.state == .on ? ["LeftEye", "RightEye"] : [])
        let wantsAnimation = wiggleOption.state == .on && !depthMapOnly
        let wantsViews = wiggleViews.state == .on && !depthMapOnly
        let wantsWiggle = wantsAnimation || wantsViews
        var workingPhoto = originalPhoto
        var importedOutputs: [URL] = []
        if let inputFormat = stereoInputFormat {
            guard !depthMapOnly else { statusLabel.stringValue = "Depth-map generation is not available for imported stereo yet."; return }
            guard !wantsWiggle || enginePopup.indexOfSelectedItem == 0 else {
                statusLabel.stringValue = "Choose SHARP to make a wigglegram from the left eye."; return
            }
            var importedFormats = formats
            if keepEyes.state == .on { importedFormats += ["LeftEye", "RightEye"] }
            guard !importedFormats.isEmpty || wantsWiggle else { statusLabel.stringValue = "Select at least one output format."; return }
            if !importedFormats.isEmpty {
                guard let outputs = emitFormats(from: originalPhoto, source: originalPhoto, engine: "Stereo", depth: "Imported", formats: importedFormats,
                                                inputFormat: inputFormat, rightEye: stereoRightEye) else {
                    statusLabel.stringValue = "Stereo export failed. Check eye dimensions and image format."; return
                }
                importedOutputs = outputs
            }
            if !wantsWiggle {
                if let result = importedOutputs.first {
                    lastOutput = result; revealButton.isEnabled = true
                    statusLabel.stringValue = "Created \(importedFormats.count) stereo export(s)."
                    revealOutput(result, openImage: true)
                }
                return
            }
            guard let left = extractStereoLeft(originalPhoto, inputFormat: inputFormat, rightEye: stereoRightEye) else {
                statusLabel.stringValue = "Could not prepare the left eye for SHARP. Check the input images."; return
            }
            workingPhoto = left
        }
        let photo = workingPhoto
        let existingStereo = stereoInputFormat != nil
        let existingStereoOutputs = importedOutputs
        guard !formats.isEmpty || wantsWiggle || depthMapOnly else { statusLabel.stringValue = "Select at least one output format."; return }
        let selectedEngine = enginePopup.indexOfSelectedItem
        guard !wantsWiggle || selectedEngine == 0 else {
            statusLabel.stringValue = "Multi-frame wigglegram currently requires the SHARP engine."; return
        }
        if selectedEngine == 2 {
            if depthMapOnly { statusLabel.stringValue = "Reframe does not generate a depth map."; return }
            runGuidedReframe(photo: photo, formats: formats)
            return
        }
        let isIW3 = selectedEngine == 1
        if depthMapOnly && !isIW3 {
            statusLabel.stringValue = "Depth map export currently requires IW3."
            return
        }
        let format = "parallel" // Render once; the format helper creates every checked output.
        let home = FileManager.default.homeDirectoryForCurrentUser
        let root = home.appendingPathComponent("InjectZ")
        let outputDir: URL
        let task = Process()
        var env = ProcessInfo.processInfo.environment
        let existingPath = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + existingPath
        let depth: String

        if isIW3 {
            // Each conversion gets its own output directory so the resulting
            // filename can be discovered without guessing IW3's naming scheme.
            let iw3Root = root.appendingPathComponent("Development/IW3")
            let source = iw3Root.appendingPathComponent("nunif")
            let python = iw3Root.appendingPathComponent("python/bin/python")
            let runDir = iw3Root.appendingPathComponent("TestOutput/InjectZ-" + UUID().uuidString)
            let cache = iw3Root.appendingPathComponent("Cache")
            do {
                try FileManager.default.createDirectory(at: runDir, withIntermediateDirectories: true)
                try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
            } catch {
                statusLabel.stringValue = "Could not create IW3 output folder: \(error.localizedDescription)"
                return
            }
            guard FileManager.default.isExecutableFile(atPath: python.path),
                  FileManager.default.fileExists(atPath: source.appendingPathComponent("iw3/__main__.py").path) else {
                statusLabel.stringValue = "IW3 development runtime is missing."
                return
            }
            depth = depthPopup.titleOfSelectedItem ?? "5.0"
            outputDir = runDir
            task.executableURL = python
            task.currentDirectoryURL = source
            let convergence = Double(convergenceField?.stringValue ?? "0.25") ?? 0.25
            let foreground = Double(foregroundField?.stringValue ?? "0") ?? 0
            guard (0...1).contains(convergence), (-3...3).contains(foreground) else {
                statusLabel.stringValue = "Advanced convergence or foreground scale is out of range."
                return
            }
            var args = [root.appendingPathComponent("Development/IW3/photo_iw3.py").path, "-i", photo.path, "-o", runDir.path,
                        "--method", methodPopup?.titleOfSelectedItem ?? "forward_inpaint", "--divergence", depth,
                        "--convergence", String(convergence), "--depth-model",
                        self.iw3ModelPopup.titleOfSelectedItem ?? "DepthPro"]
            if foreground != 0 { args += ["--foreground-scale", String(foreground)] }
            if allowWindowViolations.state == .off && preserveBorder?.state != .off { args.append("--preserve-screen-border") }
            if depthAA?.state == .on { args.append("--depth-aa") }
            if depthMapOnly { args += ["--export", "--export-depth-fit"] }
            else if allowWindowViolations.state == .off { args.append("--injectz-protect-window") }
            args += ["--yes"]
            let extra = extraIW3Arguments()
            if !extra.contains("--inpaint-model") { args += ["--inpaint-model", "light_inpaint_v1"] }
            if !extra.contains("--video-codec") { args += ["--video-codec", "libx264"] }
            args += extra
            task.arguments = args
            env["HF_HOME"] = cache.appendingPathComponent("huggingface").path
            env["TORCH_HOME"] = cache.appendingPathComponent("torch").path
            env["HF_HUB_OFFLINE"] = "1"
        } else {
            let isCustom = depthPopup.titleOfSelectedItem?.hasPrefix("Custom depth") == true
            let sharpDepth = isCustom ? "very-strong" : ["low", "medium", "strong", "very-strong", "extra-strong", "maximum", "extreme"][depthPopup.indexOfSelectedItem]
            depth = isCustom ? String(format: "%.3f", customSharpDepth) : sharpDepth
            outputDir = root.appendingPathComponent("output/InjectZ-" + UUID().uuidString)
            do { try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true) }
            catch { statusLabel.stringValue = "Could not create SHARP working folder: \(error.localizedDescription)"; return }
            task.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            var args = [root.appendingPathComponent("injectz_engine.py").path,
                        photo.path, "--depth", sharpDepth, "--format", format, "--output-dir", outputDir.path]
            if isCustom { args += ["--baseline", depth] }
            if keepEyes.state == .on && !existingStereo { args.append("--keep-eyes") }
            if wantsWiggle {
                let finish = finishingArguments()
                args += ["--wiggle-frames", wiggleFrames.titleOfSelectedItem ?? "8",
                         "--wiggle-fps", ["12", "24", "30", "60"][max(0, wiggleFPS.indexOfSelectedItem)],
                         "--wiggle-border", finish[1], "--wiggle-corners", finish[3]]
                if wiggleCard.state == .on {
                    args += ["--wiggle-card-color", cardColorHex(), "--wiggle-card-title", wiggleCardTitle.stringValue]
                }
                if wantsViews { args.append("--export-wiggle-views") }
                if !wantsAnimation { args.append("--no-wiggle-video") }
            }
            if softenSharpEdges?.state == .on {
                args += ["--soften-depth-edges", "--edge-soften-radius", String(edgeRadius?.doubleValue ?? 2),
                         "--edge-soften-strength", String(edgeStrength?.doubleValue ?? 0.35)]
            }
            if allowWindowViolations.state == .on { args.append("--allow-window-violations") }
            task.arguments = args
        }
        task.environment = env
        let conversionStarted = Date()
        convertButton.isEnabled = false
        depthMapButton.isEnabled = false
        revealButton.isEnabled = false
        statusLabel.stringValue = depthMapOnly ? "Generating depth map…" : (existingStereo ? "Generating SHARP wiggle from the left eye…" : "Converting…")

        // Read output concurrently to avoid blocking if a model prints extensive logs.
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let logLock = NSLock()
        var captured = Data()
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if !chunk.isEmpty {
                logLock.lock()
                captured.append(chunk)
                logLock.unlock()
            }
        }
        do {
            try task.run()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            convertButton.isEnabled = true
            depthMapButton.isEnabled = isIW3
            statusLabel.stringValue = "Could not start engine: \(error.localizedDescription)"
            NSRunningApplication.current.activate(options: [])
            window.makeKeyAndOrderFront(nil)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            task.waitUntilExit()
            if existingStereo {
                let stem = photo.deletingPathExtension().lastPathComponent
                let cached = root.appendingPathComponent("cache/sharp/" + stem + ".ply")
                try? FileManager.default.removeItem(at: cached)
                try? FileManager.default.removeItem(at: photo.deletingLastPathComponent())
            }
            pipe.fileHandleForReading.readabilityHandler = nil
            let remainder = pipe.fileHandleForReading.readDataToEndOfFile()
            logLock.lock()
            captured.append(remainder)
            let text = String(data: captured, encoding: .utf8) ?? ""
            logLock.unlock()
            DispatchQueue.main.async {
                self.convertButton.isEnabled = true
                self.depthMapButton.isEnabled = isIW3
                if task.terminationStatus == 0 {
                    var result: URL? = existingStereoOutputs.first
                    var completionNote = ""
                    let fm = FileManager.default
                    let stem = photo.deletingPathExtension().lastPathComponent
                    let photoFolder = originalPhoto.deletingLastPathComponent()
                    func unusedDestination(_ basename: String, _ ext: String) -> URL {
                        var dest = photoFolder.appendingPathComponent(basename).appendingPathExtension(ext)
                        var number = 2
                        while fm.fileExists(atPath: dest.path) {
                            dest = photoFolder.appendingPathComponent("\(basename)_\(number)").appendingPathExtension(ext)
                            number += 1
                        }
                        return dest
                    }
                    if isIW3 {
                        if depthMapOnly {
                            let depthFile = outputDir.appendingPathComponent("depth/\(stem).png")
                            let rgbFile = outputDir.appendingPathComponent("rgb/\(stem).png")
                            if fm.fileExists(atPath: depthFile.path) && fm.fileExists(atPath: rgbFile.path) {
                                // Keep native 16-bit depth in IW3's internal run directory.
                                // Export only the layered PSD beside the source photograph.
                                let helper = root.appendingPathComponent("Development/create_layered_psd.py")
                                if fm.fileExists(atPath: helper.path) {
                                    let psd = unusedDestination("\(stem)_InjectZ_IW3_EditableDepth_Depth\(depth)", "psd")
                                    let makePSD = Process()
                                    makePSD.executableURL = root.appendingPathComponent("Development/IW3/python/bin/python")
                                    makePSD.arguments = [helper.path, photo.path, depthFile.path, psd.path]
                                    makePSD.standardOutput = Pipe()
                                    makePSD.standardError = Pipe()
                                    do {
                                        try makePSD.run()
                                        makePSD.waitUntilExit()
                                        if makePSD.terminationStatus == 0 && fm.fileExists(atPath: psd.path) {
                                            result = psd
                                            completionNote = ""
                                        } else {
                                            completionNote = " (PSD creation failed; internal depth map retained)"
                                        }
                                    } catch {
                                        completionNote = " (PSD creation failed: \(error.localizedDescription))"
                                    }
                                } else {
                                    completionNote = " (PSD helper missing)"
                                }
                            }
                        } else {
                            let files = (try? fm.contentsOfDirectory(at: outputDir, includingPropertiesForKeys: nil)) ?? []
                            if let generated = files.filter({ ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }).first {
                                let emitted = self.emitFormats(from: generated, source: photo, engine: "IW3", depth: depth, formats: formats)
                                result = emitted?.first
                                if emitted == nil { completionNote = " (format generation failed; internal parallel render retained)" }
                            }
                        }
                    } else {
                        let baseline = ["low":"0.010", "medium":"0.020", "strong":"0.040", "very-strong":"0.060", "extra-strong":"0.080", "maximum":"0.100", "extreme":"0.120"][depth] ?? depth
                        let generated = outputDir.appendingPathComponent("\(stem)_Parallel_InjectZ_SHARP_Baseline\(baseline).png")
                        let generatedDate = try? generated.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                        if let generatedDate, generatedDate >= conversionStarted.addingTimeInterval(-2) {
                            if !formats.isEmpty && !existingStereo {
                                let emitted = self.emitFormats(from: generated, source: photo, engine: "SHARP", depth: baseline, formats: formats)
                                result = emitted?.first
                                if emitted == nil { completionNote = " (format generation failed; internal parallel render retained)" }
                            }
                            if wantsAnimation {
                                let video = outputDir.appendingPathComponent("\(stem)_InjectZ_SHARP_Wiggle_Baseline\(baseline).mp4")
                                if fm.fileExists(atPath: video.path) {
                                    let destination = unusedDestination("\(originalPhoto.deletingPathExtension().lastPathComponent)_InjectZ_SHARP_MultiFrameWiggle_Depth\(baseline)", "mp4")
                                    do { try fm.copyItem(at: video, to: destination); if result == nil { result = destination } }
                                    catch { completionNote += " (wiggle could not be copied to the photo folder)" }
                                } else { completionNote += " (wiggle output was not found)" }
                            }
                            if wantsViews {
                                let views = outputDir.appendingPathComponent("\(stem)_InjectZ_SHARP_Views_Baseline\(baseline)", isDirectory: true)
                                let base = "\(originalPhoto.deletingPathExtension().lastPathComponent)_InjectZ_SHARP_Views_Depth\(baseline)"
                                var destination = photoFolder.appendingPathComponent(base, isDirectory: true)
                                var number = 2
                                while fm.fileExists(atPath: destination.path) {
                                    destination = photoFolder.appendingPathComponent("\(base)_\(number)", isDirectory: true)
                                    number += 1
                                }
                                if fm.fileExists(atPath: views.path) {
                                    do {
                                        try fm.copyItem(at: views, to: destination)
                                        if result == nil { result = destination.appendingPathComponent("view_0001.png") }
                                    } catch { completionNote += " (view sequence could not be copied to the photo folder)" }
                                } else { completionNote += " (view sequence was not found)" }
                            }
                        }
                    }
                    if let result = result, FileManager.default.fileExists(atPath: result.path) {
                        self.lastOutput = result
                        self.revealButton.isEnabled = true
                        self.statusLabel.stringValue = depthMapOnly ? "Depth map complete — \(result.lastPathComponent)\(completionNote)" : "Created exports — \(result.lastPathComponent)\(completionNote)"
                        self.revealOutput(result, openImage: true)
                        InjectZAudioAlerts.shared.playCompletion()
                    } else {
                        self.statusLabel.stringValue = "Engine finished, but no output image was found."
                        NSRunningApplication.current.activate(options: [])
                        self.window.makeKeyAndOrderFront(nil)
                        let log = home.appendingPathComponent("Desktop/InjectZ Error Log.txt")
                        try? text.write(to: log, atomically: true, encoding: .utf8)
                    }
                } else {
                    self.statusLabel.stringValue = "Conversion failed. See InjectZ Error Log on Desktop."
                    NSRunningApplication.current.activate(options: [])
                    self.window.makeKeyAndOrderFront(nil)
                    let log = home.appendingPathComponent("Desktop/InjectZ Error Log.txt")
                    try? text.write(to: log, atomically: true, encoding: .utf8)
                }
            }
        }
    }

    func emitFormats(from parallel: URL, source: URL, engine: String, depth: String, formats: [String], inputFormat: String = "parallel", rightEye: URL? = nil) -> [URL]? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let helper = home.appendingPathComponent("InjectZ/Development/Reframe/SharedStereoFormats.py")
        let python = home.appendingPathComponent("InjectZ/Development/IW3/python/bin/python")
        guard FileManager.default.fileExists(atPath: helper.path),
              FileManager.default.isExecutableFile(atPath: python.path) else { return nil }
        let task = Process()
        task.executableURL = python
        let prefix = source.deletingPathExtension().path + "_InjectZ_" + engine
        var arguments = [helper.path, parallel.path, "--output-prefix", prefix,
                         "--depth-token", depth, "--input-format", inputFormat] + finishingArguments()
        if let rightEye = rightEye { arguments += ["--right-eye", rightEye.path] }
        task.arguments = arguments + ["--formats"] + formats
        let log = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("InjectZ-formats-" + UUID().uuidString + ".log")
        FileManager.default.createFile(atPath: log.path, contents: nil)
        guard let handle = FileHandle(forWritingAtPath: log.path) else { return nil }
        defer { try? handle.close(); try? FileManager.default.removeItem(at: log) }
        task.standardOutput = handle; task.standardError = handle
        do {
            try task.run()
            while task.isRunning { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
            task.waitUntilExit()
            let data = (try? Data(contentsOf: log)) ?? Data()
            let lines = (String(data: data, encoding: .utf8) ?? "").components(separatedBy: .newlines)
            let outputs = lines.filter { $0.hasPrefix("SUCCESS ") }.map { URL(fileURLWithPath: String($0.dropFirst(8))) }
            guard task.terminationStatus == 0, outputs.count == formats.count,
                  outputs.allSatisfy({ FileManager.default.fileExists(atPath: $0.path) }) else { return nil }
            return outputs
        } catch { return nil }
    }

    // Resume uses the existing unique working folder and Photos album. It NEVER imports.
    @objc func resumeReframe() {
        guard enginePopup.indexOfSelectedItem == 2 else { return }
        guard let photo = selectedPhoto, FileManager.default.fileExists(atPath: photo.path) else {
            let a = NSAlert(); a.messageText = "Choose the original photograph first"
            a.informativeText = "Select the SAME original photograph used for the interrupted run. This is needed only to name and locate the final output; no new photographs will be imported."
            a.runModal(); return
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        let reframeDir = home.appendingPathComponent("InjectZ/Development/Reframe")
        let picker = NSOpenPanel()
        picker.message = "Select the EXISTING UUID-named folder inside Reframe/Working"
        picker.directoryURL = reframeDir.appendingPathComponent("Working")
        picker.canChooseFiles = false
        picker.canChooseDirectories = true
        picker.allowsMultipleSelection = false
        guard picker.runModal() == .OK, let work = picker.url else { return }
        let id = work.lastPathComponent
        let expectedParent = reframeDir.appendingPathComponent("Working").standardizedFileURL
        guard work.deletingLastPathComponent().standardizedFileURL == expectedParent,
              UUID(uuidString: id) != nil else {
            let a = NSAlert(); a.messageText = "Invalid working folder"
            a.informativeText = "Choose an existing UUID-named folder directly inside Reframe/Working."
            a.runModal(); return
        }
        let contents = (try? FileManager.default.contentsOfDirectory(at: work, includingPropertiesForKeys: nil)) ?? []
        let left = contents.filter { $0.lastPathComponent.hasPrefix("InjectZ_\(id)_LEFT.") }
        let right = contents.filter { $0.lastPathComponent.hasPrefix("InjectZ_\(id)_RIGHT.") }
        guard left.count == 1, right.count == 1 else {
            let a = NSAlert(); a.messageText = "Working copies are missing or ambiguous"
            a.informativeText = "No changes made. This folder must contain exactly one LEFT and one RIGHT original working file."
            a.runModal(); return
        }
        let confirm = NSAlert()
        confirm.messageText = "Resume existing Reframe conversion?"
        confirm.informativeText = "Working album: InjectZ-\(id)\nOriginal for output: \(photo.lastPathComponent)\n\nNo new images will be imported. Confirm that the original is correct and that Photos has this exact working album. The app will attempt automatic RIGHT selection after resuming."
        confirm.addButton(withTitle: "Resume")
        confirm.addButton(withTitle: "Cancel")
        guard confirm.runModal() == .alertFirstButtonReturn else { return }
        guard checkReframePermission() else { return }
        let guardURL = reframeDir.appendingPathComponent("LibraryGuard")
        guard FileManager.default.isExecutableFile(atPath: guardURL.path) else {
            let a = NSAlert(); a.messageText = "Required Reframe helpers missing"; a.runModal(); return
        }
        let libraryGuard = Process()
        libraryGuard.executableURL = guardURL
        let output = Pipe(); libraryGuard.standardOutput = output; libraryGuard.standardError = output
        do {
            try libraryGuard.run()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            libraryGuard.waitUntilExit()
            guard libraryGuard.terminationStatus == 0 else {
                let a = NSAlert(); a.messageText = "Resume safely blocked"
                a.informativeText = "The working Photos library could not be verified. No changes made.\n" + (String(data: data, encoding: .utf8) ?? "")
                a.runModal(); return
            }
        } catch {
            let a = NSAlert(); a.messageText = "Library verification failed"; a.informativeText = error.localizedDescription; a.runModal(); return
        }
        let formats = selectedFormats()
        guard !formats.isEmpty else { statusLabel.stringValue = "Select at least one stereo format."; return }
        startEmbeddedReframe(album: "InjectZ-" + id, work: work, source: photo, formats: formats)

    }

    func runGuidedReframe(photo: URL, formats: [String]) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let reframeDir = home.appendingPathComponent("InjectZ/Development/Reframe")
        let importer = reframeDir.appendingPathComponent("ImportWorkingCopies.applescript")
        let library = home.appendingPathComponent("InjectZ/Development/InjectZ Working Library.photoslibrary")
        guard FileManager.default.fileExists(atPath: library.path) else {
            statusLabel.stringValue = "Working Photos library not found in InjectZ/Development."
            return
        }
        guard FileManager.default.fileExists(atPath: importer.path) else {
            statusLabel.stringValue = "Reframe components missing. Reinstall development update."
            return
        }
        guard checkReframePermission() else { return }
        // LibraryGuard fails closed if Photos is using the personal library or
        // if macOS prevents verification. No Photos import is attempted on failure.
        let guardTask = Process()
        guardTask.executableURL = reframeDir.appendingPathComponent("LibraryGuard")
        guard FileManager.default.isExecutableFile(atPath: guardTask.executableURL!.path) else {
            statusLabel.stringValue = "Library guard missing. Reinstall development update."
            return
        }
        let guardPipe = Pipe()
        guardTask.standardOutput = guardPipe
        guardTask.standardError = guardPipe
        do {
            try guardTask.run()
            let output = guardPipe.fileHandleForReading.readDataToEndOfFile()
            guardTask.waitUntilExit()
            guard guardTask.terminationStatus == 0 else {
                let alert = NSAlert()
                alert.messageText = "Reframe import safely blocked"
                alert.informativeText = (String(data: output, encoding: .utf8) ?? "Library verification failed.") + "\n\nNo photographs were imported."
                alert.runModal()
                statusLabel.stringValue = "Library verification failed; no import performed."
                return
            }
        } catch {
            statusLabel.stringValue = "Could not start library guard: \(error.localizedDescription)"
            return
        }
        let fm = FileManager.default
        let id = UUID().uuidString
        let work = reframeDir.appendingPathComponent("Working/" + id)
        do { try fm.createDirectory(at: work, withIntermediateDirectories: true) }
        catch { statusLabel.stringValue = "Could not create working folder: \(error.localizedDescription)"; return }
        let ext = photo.pathExtension.isEmpty ? "jpg" : photo.pathExtension
        let left = work.appendingPathComponent("InjectZ_\(id)_LEFT.\(ext)")
        let right = work.appendingPathComponent("InjectZ_\(id)_RIGHT.\(ext)")
        do {
            try fm.copyItem(at: photo, to: left)
            try fm.copyItem(at: photo, to: right)
        } catch {
            statusLabel.stringValue = "Could not prepare copies: \(error.localizedDescription)"
            return
        }
        let album = "InjectZ-" + id
        let importTask = Process()
        importTask.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        importTask.arguments = [importer.path, left.path, right.path, album]
        // Use a regular log file, not Pipe.readDataToEndOfFile(). AppleScript
        // can launch Photos helpers that retain the pipe's write descriptor;
        // waiting for EOF can then hang even after osascript has exited.
        let importLog = work.appendingPathComponent("ImportWorkingCopies.log")
        guard fm.createFile(atPath: importLog.path, contents: nil),
              let logHandle = FileHandle(forWritingAtPath: importLog.path) else {
            statusLabel.stringValue = "Cannot create import log; no import attempted."
            return
        }
        importTask.standardError = logHandle
        importTask.standardOutput = logHandle
        convertButton.isEnabled = false
        statusLabel.stringValue = "Importing two working copies into Photos…"
        DispatchQueue.global(qos: .userInitiated).async {
            var message = ""
            var succeeded = false
            var timedOut = false
            do {
                try importTask.run()
                // Bound the import wait; don't leave the interface stuck forever.
                let deadline = Date().addingTimeInterval(90)
                while importTask.isRunning && Date() < deadline {
                    Thread.sleep(forTimeInterval: 0.25)
                }
                if importTask.isRunning {
                    timedOut = true
                    importTask.terminate()
                }
                importTask.waitUntilExit()
                succeeded = !timedOut && importTask.terminationStatus == 0
            } catch { message = error.localizedDescription }
            try? logHandle.close()
            if let data = try? Data(contentsOf: importLog),
               let logText = String(data: data, encoding: .utf8), !logText.isEmpty {
                message += (message.isEmpty ? "" : "\n") + logText
            }
            DispatchQueue.main.async {
                self.convertButton.isEnabled = true
                guard succeeded else {
                    NSRunningApplication.current.activate(options: [])
                    self.window.makeKeyAndOrderFront(nil)
                    self.statusLabel.stringValue = timedOut
                        ? "Photos import timed out (90 seconds). Working copies preserved."
                        : "Photos import failed; working copies preserved."
                    let alert = NSAlert()
                    alert.messageText = timedOut ? "Photos import timed out" : "Photos import failed"
                    alert.informativeText = (message.isEmpty ? "No script details were returned." : message)
                        + "\n\nWorking copies and import log: " + work.path
                        + "\n\nCheck the exact new album before retrying; no automatic re-import."
                    alert.runModal()
                    return
                }
                self.statusLabel.stringValue = "Import script completed; locating exact working album…"
                self.startEmbeddedReframe(album: album, work: work, source: photo, formats: formats)
            }
        }
    }


    // Embedded Accessibility controller: macOS authorizes InjectZ, not a separately launched binary.
    // Do not show the OS permission prompt in the middle of a conversion.
    func checkReframePermission() -> Bool {
        if AXIsProcessTrusted() { return true }
        let a = NSAlert()
        a.messageText = "Inject Z needs Accessibility permission"
        a.informativeText = "Grant Accessibility access to the main ~/InjectZ/InjectZ.app in System Settings > Privacy & Security > Accessibility. If several Inject Z entries appear, remove the duplicates and add that exact app path once. No photos were imported."
        a.addButton(withTitle: "Open Accessibility Settings")
        a.addButton(withTitle: "Cancel")
        if a.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
        statusLabel.stringValue = "Accessibility not ready; no import or edits performed."
        return false
    }

    func axAttr(_ e: AXUIElement, _ key: String) -> AnyObject? {
        var v: CFTypeRef?
        return AXUIElementCopyAttributeValue(e, key as CFString, &v) == .success ? v : nil
    }
    func axElements(_ root: AXUIElement) -> [AXUIElement] {
        var result: [AXUIElement] = []
        func visit(_ e: AXUIElement, _ depth: Int) {
            if depth > 35 || result.count >= 2000 { return }
            result.append(e)
            if let kids = axAttr(e, kAXChildrenAttribute as String) as? [AXUIElement] {
                for child in kids { visit(child, depth + 1) }
            }
        }
        visit(root, 0)
        return result
    }
    func reframeAlert(_ title: String, _ info: String) -> Bool {
        let a = NSAlert(); a.messageText = title; a.informativeText = info
        a.addButton(withTitle: "Continue"); a.addButton(withTitle: "Cancel")
        return a.runModal() == .alertFirstButtonReturn
    }
    // Single-eye Reframe: the source file is the unmodified LEFT eye.
    // Only RIGHT is rendered. Rotation stays at zero. All failures preserve source and Photos items.
    func editReframeRight(pan: Double) -> Bool {
        reframeRequestedPan = pan
        reframeAppliedPan = 0
        guard AXIsProcessTrusted(),
              let photos = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Photos").first else {
            statusLabel.stringValue = "Photos or Accessibility unavailable; no Reframe performed."
            return false
        }
        func currentElements() -> [AXUIElement] {
            axElements(AXUIElementCreateApplication(photos.processIdentifier))
        }
        // Separate helper avoids reliance on a fixed delay while Photos processes the image.
        func namedButton(_ elements: [AXUIElement], _ name: String) -> AXUIElement? {
            for e in elements where (axAttr(e, kAXRoleAttribute as String) as? String) == (kAXButtonRole as String) {
                let title = axAttr(e, kAXTitleAttribute as String) as? String
                let desc = axAttr(e, kAXDescriptionAttribute as String) as? String
                if title == name || desc == name { return e }
            }
            return nil
        }
        let elements = currentElements()
        let sliders = elements.filter { (axAttr($0, kAXRoleAttribute as String) as? String) == (kAXSliderRole as String) }
        guard sliders.count == 6,
              (axAttr(sliders[1], kAXDescriptionAttribute as String) as? String) == "Horizontal",
              (axAttr(sliders[3], kAXDescriptionAttribute as String) as? String) == "Horizontal",
              abs(((axAttr(sliders[3], kAXMinValueAttribute as String) as? NSNumber)?.doubleValue ?? 999) + 0.17) < 0.01 else {
            statusLabel.stringValue = "Reframe sliders not recognized; no adjustments made."
            return false
        }
        // Explicitly reset rotation and vertical pan/rotation; adjust only horizontal pan.
        for (sliderIndex, pair) in [(sliders[0], 0.0), (sliders[1], 0.0), (sliders[2], 0.0), (sliders[3], pan)].enumerated() {
            let (slider, value) = pair
            guard AXUIElementSetAttributeValue(slider, kAXValueAttribute as CFString, NSNumber(value: value)) == .success else {
                statusLabel.stringValue = "Could not set a Reframe slider; conversion stopped."
                return false
            }
            var actual = Double.nan
            var matched = false
            for _ in 0..<15 {
                RunLoop.current.run(until: Date().addingTimeInterval(0.2))
                actual = (axAttr(slider, kAXValueAttribute as String) as? NSNumber)?.doubleValue ?? .nan
                if actual.isFinite && abs(actual - value) < 0.003 { matched = true; break }
            }
            if !matched {
                // Photos can limit Reframe motion for a particular photograph.
                // Accept a real, positive pan only for the requested pan slider;
                // never treat a failed rotation reset or a reversed shift as success.
                guard sliderIndex == 3, actual.isFinite,
                      actual > 0.001, actual < value else {
                    statusLabel.stringValue = "Reframe slider \(sliderIndex + 1) expected \(value), read \(actual); no render started."
                    return false
                }
            }
            if sliderIndex == 3 { reframeAppliedPan = actual }
        }
        guard let reframe = namedButton(currentElements(), "Reframe") else {
            statusLabel.stringValue = "Reframe button not exposed to Accessibility. No automatic render started."
            return false
        }
        statusLabel.stringValue = "Starting yellow Reframe button…"
        let pressResult = AXUIElementPerformAction(reframe, kAXPressAction as CFString)
        // Photos sometimes reports AXPress success while the button remains
        // available. Look for an actual transition before trying a mouse click.
        var renderStarted = false
        for _ in 0..<10 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            let now = currentElements()
            if let save = namedButton(now, "Save Changes"),
               (axAttr(save, kAXEnabledAttribute as String) as? Bool) == true {
                renderStarted = true; break
            }
            if let button = namedButton(now, "Reframe"),
               (axAttr(button, kAXEnabledAttribute as String) as? Bool) == false {
                renderStarted = true; break
            }
        }
        if !renderStarted {
            // Use the current button's AX geometry; never a hard-coded screen coordinate.
            guard let button = namedButton(currentElements(), "Reframe"),
                  let p = axAttr(button, kAXPositionAttribute as String),
                  let s = axAttr(button, kAXSizeAttribute as String) else {
                statusLabel.stringValue = "Reframe did not start (AX \(pressResult.rawValue)); button geometry unavailable."
                return false
            }
            var point = CGPoint.zero; var size = CGSize.zero
            guard AXValueGetValue(p as! AXValue, .cgPoint, &point), AXValueGetValue(s as! AXValue, .cgSize, &size),
                  size.width > 20, size.height > 10,
                  let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                                     mouseCursorPosition: CGPoint(x: point.x + size.width/2, y: point.y + size.height/2), mouseButton: .left),
                  let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                                   mouseCursorPosition: CGPoint(x: point.x + size.width/2, y: point.y + size.height/2), mouseButton: .left) else {
                statusLabel.stringValue = "Reframe button has invalid click geometry; working copy preserved."
                return false
            }
            down.post(tap: .cghidEventTap)
            Thread.sleep(forTimeInterval: 0.08)
            up.post(tap: .cghidEventTap)
        }
        // Poll for Save Changes becoming enabled; don't press it during rendering.
        var save: AXUIElement? = nil
        for _ in 0..<45 {
            Thread.sleep(forTimeInterval: 1)
            if let candidate = namedButton(currentElements(), "Save Changes"),
               (axAttr(candidate, kAXEnabledAttribute as String) as? Bool) == true {
                save = candidate
                break
            }
        }
        guard let saveButton = save else {
            statusLabel.stringValue = "Reframe started, but Save Changes did not become available. Working copy preserved."
            return false
        }
        let saveResult = AXUIElementPerformAction(saveButton, kAXPressAction as CFString)
        guard saveResult == .success else {
            statusLabel.stringValue = "Reframe rendered but automatic Save Changes failed (AX code \(saveResult.rawValue))."
            return false
        }
        Thread.sleep(forTimeInterval: 2)
        return true
    }

    // All UI operations require the verified disposable Photos library (checked by caller).
    // Do not use absolute screen coordinates: target AX thumbnail geometry only.
    func openFirstWorkingPhoto(album: String) -> Bool {
        // AppleScript can finish its import while Photos is still launching or
        // before Launch Services has registered the process. Wait for the
        // actual process and the expected working album's sidebar entry.
        var photos: NSRunningApplication? = nil
        for _ in 0..<100 {
            photos = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Photos")
                .first(where: { !$0.isTerminated })
            if photos != nil { break }
            Thread.sleep(forTimeInterval: 0.2)
        }
        guard let photos = photos else {
            statusLabel.stringValue = "Timed out waiting for Photos to launch after import."; return false
        }
        photos.activate(options: [.activateIgnoringOtherApps])
        let root = AXUIElementCreateApplication(photos.processIdentifier)
        func matches(_ e: AXUIElement, _ id: String) -> Bool {
            (axAttr(e, kAXIdentifierAttribute as String) as? String) == id
        }
        // Photos may show All Albums for several seconds after AppleScript
        // returns. Wait until the exact new album appears in the AX tree.
        var all = axElements(root)
        for _ in 0..<100 {
            if all.contains(where: { matches($0, "textField_" + album) }) ||
                all.contains(where: { (axAttr($0, kAXTitleAttribute as String) as? String ?? "").contains(album) &&
                    (axAttr($0, kAXRoleAttribute as String) as? String) == (kAXWindowRole as String) }) { break }
            Thread.sleep(forTimeInterval: 0.2)
            all = axElements(root)
        }
        if !(all.contains { (axAttr($0, kAXTitleAttribute as String) as? String ?? "").contains(album) &&
              (axAttr($0, kAXRoleAttribute as String) as? String) == (kAXWindowRole as String) }) {
            guard let albumField = all.first(where: { matches($0, "textField_" + album) }) else {
                statusLabel.stringValue = "Working album not found in Photos sidebar."; return false
            }
            var parent: CFTypeRef?
            guard AXUIElementCopyAttributeValue(albumField, kAXParentAttribute as CFString, &parent) == .success,
                  let cell = parent else { statusLabel.stringValue = "Cannot navigate to working album."; return false }
            var rowParent: CFTypeRef?
            guard AXUIElementCopyAttributeValue(cell as! AXUIElement, kAXParentAttribute as CFString, &rowParent) == .success,
                  let row = rowParent else { statusLabel.stringValue = "Working album row unavailable."; return false }
            // Photos sidebar AXRow does not implement AXPress on this macOS
            // (AX -25206). Select its row, then fall back to a physical single click
            // using the row's own AX geometry. Never use guessed screen coordinates.
            let sidebarRow = row as! AXUIElement
            let selectResult = AXUIElementSetAttributeValue(sidebarRow, kAXSelectedAttribute as CFString, kCFBooleanTrue)
            Thread.sleep(forTimeInterval: 0.35)
            var current = axElements(root)
            let opened = current.contains { (axAttr($0, kAXTitleAttribute as String) as? String ?? "").contains(album) &&
                (axAttr($0, kAXRoleAttribute as String) as? String) == (kAXWindowRole as String) }
            if !opened {
                var positionRef: CFTypeRef?; var sizeRef: CFTypeRef?
                guard AXUIElementCopyAttributeValue(sidebarRow, kAXPositionAttribute as CFString, &positionRef) == .success,
                      AXUIElementCopyAttributeValue(sidebarRow, kAXSizeAttribute as CFString, &sizeRef) == .success,
                      let positionRef = positionRef, let sizeRef = sizeRef else {
                    statusLabel.stringValue = "Cannot locate album row on screen (AX select \(selectResult.rawValue))."; return false
                }
                var pos = CGPoint.zero; var sz = CGSize.zero
                guard AXValueGetValue(positionRef as! AXValue, .cgPoint, &pos),
                      AXValueGetValue(sizeRef as! AXValue, .cgSize, &sz),
                      sz.width > 20, sz.height > 10 else {
                    statusLabel.stringValue = "Working album row has invalid bounds."; return false
                }
                let clickPoint = CGPoint(x: pos.x + min(sz.width / 2, 80), y: pos.y + sz.height / 2)
                guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: clickPoint, mouseButton: .left),
                      let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: clickPoint, mouseButton: .left) else {
                    statusLabel.stringValue = "Cannot create Photos navigation click."; return false
                }
                down.post(tap: .cghidEventTap)
                up.post(tap: .cghidEventTap)
            }
            Thread.sleep(forTimeInterval: 1.2)
            all = axElements(root)
        }
        guard all.contains(where: { (axAttr($0, kAXTitleAttribute as String) as? String ?? "").contains(album) &&
            (axAttr($0, kAXRoleAttribute as String) as? String) == (kAXWindowRole as String) }) else {
            statusLabel.stringValue = "Photos is not displaying the intended working album."; return false
        }
        guard let collection = all.first(where: { matches($0, "photos_collection_view") }),
              let lists = axAttr(collection, kAXChildrenAttribute as String) as? [AXUIElement],
              let albumList = lists.first,
              let photosGroups = axAttr(albumList, kAXChildrenAttribute as String) as? [AXUIElement],
              photosGroups.count == 2,
              photosGroups.allSatisfy({ matches($0, "mediaKind_asset") }) else {
            statusLabel.stringValue = "Expected exactly two thumbnail items; no edits made."; return false
        }
        let target = photosGroups[0]
        // Prefer the native AX action. Photos sometimes exposes thumbnail groups without it.
        // A thumbnail AXPress may only select it, so use its own geometry for a double-click.
        if true {
            var pointRef: CFTypeRef?; var sizeRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(target, kAXPositionAttribute as CFString, &pointRef) == .success,
                  AXUIElementCopyAttributeValue(target, kAXSizeAttribute as CFString, &sizeRef) == .success,
                  let pointRef = pointRef, let sizeRef = sizeRef else {
                statusLabel.stringValue = "Thumbnail has no clickable Accessibility geometry."; return false
            }
            var pt = CGPoint.zero; var size = CGSize.zero
            guard AXValueGetValue(pointRef as! AXValue, .cgPoint, &pt),
                  AXValueGetValue(sizeRef as! AXValue, .cgSize, &size), size.width > 10, size.height > 10 else {
                statusLabel.stringValue = "Thumbnail bounds unavailable."; return false
            }
            let center = CGPoint(x: pt.x + size.width/2, y: pt.y + size.height/2)
            guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: center, mouseButton: .left),
                  let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: center, mouseButton: .left) else { return false }
            // A real double-click requires two complete down/up pairs. A lone
            // pair labeled clickState=2 only selects the Photos thumbnail.
            down.setIntegerValueField(.mouseEventClickState, value: 1)
            up.setIntegerValueField(.mouseEventClickState, value: 1)
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
            Thread.sleep(forTimeInterval: 0.10)
            guard let secondDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: center, mouseButton: .left),
                  let secondUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: center, mouseButton: .left) else { return false }
            secondDown.setIntegerValueField(.mouseEventClickState, value: 2)
            secondUp.setIntegerValueField(.mouseEventClickState, value: 2)
            secondDown.post(tap: .cghidEventTap)
            secondUp.post(tap: .cghidEventTap)
        }
        // Photos can take a moment to replace the grid with the photo viewer.
        var viewerOpened = false
        for _ in 0..<12 {
            Thread.sleep(forTimeInterval: 0.35)
            all = axElements(root)
            if all.contains(where: { (axAttr($0, kAXRoleAttribute as String) as? String) == (kAXButtonRole as String) &&
                ((axAttr($0, kAXDescriptionAttribute as String) as? String) == "Edit" || (axAttr($0, kAXTitleAttribute as String) as? String) == "Edit") }) {
                viewerOpened = true
                break
            }
        }
        guard viewerOpened else {
            statusLabel.stringValue = "Thumbnail double-click did not open photo viewer; no edit performed."; return false
        }
        return true
    }

    // Photos may already have entered Edit while our previous AX call returns
    // an error. Detect the actual UI state, not the result of a stale AXPress.
    func physicalClick(_ element: AXUIElement) -> Bool {
        var p: CFTypeRef?; var z: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &p) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &z) == .success,
              let p = p, let z = z else { return false }
        var pt = CGPoint.zero; var size = CGSize.zero
        guard AXValueGetValue(p as! AXValue, .cgPoint, &pt),
              AXValueGetValue(z as! AXValue, .cgSize, &size),
              size.width > 15, size.height > 10 else { return false }
        let center = CGPoint(x: pt.x + size.width/2, y: pt.y + size.height/2)
        guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                                 mouseCursorPosition: center, mouseButton: .left),
              let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                               mouseCursorPosition: center, mouseButton: .left) else { return false }
        down.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.07)
        up.post(tap: .cghidEventTap)
        return true
    }

    func enterReframeEditor() -> Bool {
        guard let photos = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Photos").first else { return false }
        photos.activate(options: [.activateIgnoringOtherApps])
        let root = AXUIElementCreateApplication(photos.processIdentifier)
        func named(_ name: String) -> AXUIElement? {
            axElements(root).first { e in
                let role = axAttr(e, kAXRoleAttribute as String) as? String ?? ""
                guard role != (kAXWindowRole as String) else { return false }
                let fields = [kAXTitleAttribute as String, kAXDescriptionAttribute as String,
                              kAXValueAttribute as String, kAXHelpAttribute as String]
                return fields.contains { (axAttr(e, $0) as? String) == name }
            }
        }
        func click(_ element: AXUIElement) -> Bool {
            if AXUIElementPerformAction(element, kAXPressAction as CFString) == .success { return true }
            var p: CFTypeRef?; var z: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &p) == .success,
                  AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &z) == .success,
                  let p = p, let z = z else { return false }
            var pt = CGPoint.zero; var size = CGSize.zero
            guard AXValueGetValue(p as! AXValue, .cgPoint, &pt),
                  AXValueGetValue(z as! AXValue, .cgSize, &size),
                  size.width > 10, size.height > 10 else { return false }
            let center = CGPoint(x: pt.x + size.width/2, y: pt.y + size.height/2)
            guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                                     mouseCursorPosition: center, mouseButton: .left),
                  let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                                   mouseCursorPosition: center, mouseButton: .left) else { return false }
            down.post(tap: .cghidEventTap); up.post(tap: .cghidEventTap)
            return true
        }
        // The Done control is reliable evidence that Photos is already editing.
        // Never press an obsolete Edit button after Done becomes visible.
        var editing = false
        for _ in 0..<15 {
            if named("Done") != nil { editing = true; break }
            Thread.sleep(forTimeInterval: 0.25)
        }
        if !editing {
            guard let edit = named("Edit") else {
                statusLabel.stringValue = "Neither Edit nor Done was found in Photos."; return false
            }
            _ = click(edit)
            for _ in 0..<20 {
                Thread.sleep(forTimeInterval: 0.3)
                if named("Done") != nil { editing = true; break }
            }
            guard editing else {
                statusLabel.stringValue = "Photos did not show editing controls after Edit."; return false
            }
        }
        // The Tools segmented control can return AXPress success merely from
        // becoming focused. Verify its panel by finding its unique buttons.
        func visibleButton(_ name: String) -> AXUIElement? {
            for e in axElements(root) {
                let role = axAttr(e, kAXRoleAttribute as String) as? String ?? ""
                guard role == (kAXButtonRole as String) else { continue }
                let title = axAttr(e, kAXTitleAttribute as String) as? String ?? ""
                let desc = axAttr(e, kAXDescriptionAttribute as String) as? String ?? ""
                guard title == name || desc == name else { continue }
                var pos: CFTypeRef?; var sz: CFTypeRef?
                if AXUIElementCopyAttributeValue(e, kAXPositionAttribute as CFString, &pos) == .success,
                   AXUIElementCopyAttributeValue(e, kAXSizeAttribute as CFString, &sz) == .success,
                   let sz = sz {
                    var size = CGSize.zero
                    if AXValueGetValue(sz as! AXValue, .cgSize, &size), size.width > 15, size.height > 10 { return e }
                }
            }
            return nil
        }
        func sixSlidersPresent() -> Bool {
            axElements(root).filter { (axAttr($0, kAXRoleAttribute as String) as? String) == (kAXSliderRole as String) }.count == 6
        }
        if visibleButton("Reframe") == nil {
            guard let tools = named("Tools") else {
                statusLabel.stringValue = "Editor opened, but Tools control was not found."; return false
            }
            _ = click(tools)
            var toolsOpened = false
            for _ in 0..<12 {
                Thread.sleep(forTimeInterval: 0.25)
                if visibleButton("Reframe") != nil { toolsOpened = true; break }
            }
            if !toolsOpened {
                // If AXPress focused the segment without activating it, send
                // a physical click at its AX-reported location.
                _ = physicalClick(tools)
                for _ in 0..<12 {
                    Thread.sleep(forTimeInterval: 0.25)
                    if visibleButton("Reframe") != nil { toolsOpened = true; break }
                }
            }
            guard toolsOpened else {
                statusLabel.stringValue = "Tools was targeted, but its Reframe button did not appear."; return false
            }
        }
        // The Reframe AX button can likewise acknowledge AXPress without
        // opening the panel. Require six sliders, and retry with a real click.
        guard let reframe = visibleButton("Reframe") else {
            statusLabel.stringValue = "Tools opened, but visible Reframe button was not found."; return false
        }
        _ = click(reframe)
        for _ in 0..<12 {
            Thread.sleep(forTimeInterval: 0.3)
            if sixSlidersPresent() { return true }
        }
        // Re-query: Photos may have recreated the button after first press.
        if let retry = visibleButton("Reframe") { _ = physicalClick(retry) }
        for _ in 0..<18 {
            Thread.sleep(forTimeInterval: 0.35)
            if sixSlidersPresent() { return true }
        }
        statusLabel.stringValue = "Tools opened, but clicking Reframe did not reveal six sliders. No edits made."
        return false
    }

    func startEmbeddedReframe(album: String, work: URL, source: URL, formats: [String]) {
        var completed = false
        defer {
            if !completed {
                NSRunningApplication.current.activate(options: [])
                window.makeKeyAndOrderFront(nil)
            }
        }
        guard checkReframePermission() else { return }
        // AX navigation uses the first of two identical working photos.
        guard openFirstWorkingPhoto(album: album) else { return }
        // Photos may reorder imported copies. Read the selected filename after AX navigation;
        // never assume the first thumbnail corresponds to the _RIGHT filename.
        statusLabel.stringValue = "Working photo opened; verifying the selected copy…"
        let selectedName: String
        do {
            let reader = Process()
            reader.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            reader.arguments = [FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("InjectZ/Development/Reframe/ReadSelectedFilename.applescript").path, album]
            // Photos can inherit a pipe's write end and prevent EOF after osascript exits.
            // Use a file and a bounded process wait, just as for the import step.
            let selectionLog = work.appendingPathComponent("ReadSelectedFilename.log")
            guard FileManager.default.createFile(atPath: selectionLog.path, contents: nil),
                  let logHandle = FileHandle(forWritingAtPath: selectionLog.path) else {
                statusLabel.stringValue = "Cannot create filename verification log; no edit performed."
                return
            }
            reader.standardOutput = logHandle
            reader.standardError = logHandle
            defer { try? logHandle.close() }
            try reader.run()
            let deadline = Date().addingTimeInterval(20)
            while reader.isRunning && Date() < deadline {
                // Pump the app event loop so the window can report progress.
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            }
            if reader.isRunning { reader.terminate() }
            reader.waitUntilExit()
            guard Date() < deadline else {
                statusLabel.stringValue = "Photos filename verification timed out; working album preserved."
                return
            }
            let data = (try? Data(contentsOf: selectionLog)) ?? Data()
            let value = (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard reader.terminationStatus == 0, value.contains("InjectZ_"),
                  (value.contains("_LEFT.") || value.contains("_RIGHT.")) else {
                statusLabel.stringValue = "Photos did not identify the opened thumbnail; no editing performed. " + value
                return
            }
            selectedName = value
        } catch {
            statusLabel.stringValue = "Could not verify selected photo: \(error.localizedDescription)"
            return
        }
        statusLabel.stringValue = "Selected photo verified; opening Reframe editor…"
        guard enterReframeEditor() else { return }
         // No assumption that selecting an item opens its Reframe editor.
         // Require the expected controls before changing any sliders.
        guard editReframeRight(pan: [0.010, 0.020, 0.040, 0.060, 0.080, 0.100, 0.120][max(0, min(6, depthPopup.indexOfSelectedItem))]) else { return }
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("InjectZ/Development/Reframe")
        let exporter = Process()
        exporter.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        exporter.arguments = [dir.appendingPathComponent("ExportSelectedEye.applescript").path, album, work.appendingPathComponent("Exports").path, selectedName]
        let log = Pipe(); exporter.standardOutput = log; exporter.standardError = log
        do {
            try exporter.run()
            exporter.waitUntilExit()
            guard exporter.terminationStatus == 0 else {
                statusLabel.stringValue = "RIGHT edited export failed. Working album preserved."
                return
            }
            let finisher = Process()
            // The dedicated IW3 environment has Pillow; macOS /usr/bin/python3 does not.
            // Do not modify system Python or touch the existing IW3 installation.
            let python = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("InjectZ/Development/IW3/python/bin/python")
            guard FileManager.default.isExecutableFile(atPath: python.path) else {
                statusLabel.stringValue = "RIGHT export preserved; IW3 Python environment not found."
                return
            }
            finisher.executableURL = python
            var finishArguments = [dir.appendingPathComponent("FinishSingleRight.py").path, work.path, source.path,
                                   "--pan", String(format: "%.4f", reframeAppliedPan)] + finishingArguments() + ["--formats"] + formats
            if allowWindowViolations.state == .on { finishArguments.append("--allow-window-violations") }
            finisher.arguments = finishArguments
            let finishLog = Pipe()
            finisher.standardOutput = finishLog
            finisher.standardError = finishLog
            try finisher.run()
            let finishText = String(data: finishLog.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            finisher.waitUntilExit()
            if finisher.terminationStatus == 0 {
                let outputs = finishText.split(separator: "\n").filter { $0.hasPrefix("SUCCESS ") }
                    .map { String($0.dropFirst("SUCCESS ".count)) }
                if outputs.count == formats.count, outputs.allSatisfy({ FileManager.default.fileExists(atPath: $0) }),
                   let output = outputs.first {
                    lastOutput = URL(fileURLWithPath: output)
                    revealButton.isEnabled = true
                    let limited = reframeAppliedPan < reframeRequestedPan - 0.003
                    statusLabel.stringValue = limited
                        ? "Reframe saved. Photos limited pan to \(String(format: "%.4f", reframeAppliedPan)); depth may be weak (requested \(String(format: "%.4f", reframeRequestedPan)))."
                        : "Reframe complete: \(formats.count) format(s) — \(lastOutput!.lastPathComponent)"
                    completed = true
                    if !removeCompletedWorkingAlbum(album: album, work: work) {
                        statusLabel.stringValue += " Conversion saved, but Photos cleanup/quit was not confirmed; see RemoveCompletedAlbum.log in the working session."
                    }
                    revealOutput(lastOutput!, openImage: true)
                    InjectZAudioAlerts.shared.playCompletion()
                } else {
                    statusLabel.stringValue = "Reframe assembly exited successfully, but its output was not verified."
                }
            } else {
                let detail = finishText.trimmingCharacters(in: .whitespacesAndNewlines)
                statusLabel.stringValue = "RIGHT export preserved; assembly failed: " + String(detail.suffix(500))
            }
        } catch { statusLabel.stringValue = "Reframe export could not start: \(error.localizedDescription)" }
    }

    @objc func reveal() {
        if let u = lastOutput {
            revealOutput(u)
        }
    }

    func removeCompletedWorkingAlbum(album: String, work: URL) -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dir = home.appendingPathComponent("InjectZ/Development/Reframe")
        guard album == "InjectZ-" + work.lastPathComponent,
              UUID(uuidString: work.lastPathComponent) != nil else { return false }
        let guardURL = dir.appendingPathComponent("LibraryGuard")
        let script = dir.appendingPathComponent("RemoveCompletedAlbum.applescript")
        guard FileManager.default.isExecutableFile(atPath: guardURL.path),
              FileManager.default.fileExists(atPath: script.path) else { return false }
        let guardTask = Process()
        guardTask.executableURL = guardURL
        guardTask.standardOutput = FileHandle.nullDevice
        guardTask.standardError = FileHandle.nullDevice
        do {
            try guardTask.run()
            guardTask.waitUntilExit()
            guard guardTask.terminationStatus == 0 else { return false }
            let cleanup = Process()
            cleanup.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            cleanup.arguments = [script.path, album, guardURL.path]
            let log = work.appendingPathComponent("RemoveCompletedAlbum.log")
            FileManager.default.createFile(atPath: log.path, contents: nil)
            guard let handle = FileHandle(forWritingAtPath: log.path) else { return false }
            defer { try? handle.close() }
            cleanup.standardOutput = handle
            cleanup.standardError = handle
            try cleanup.run()
            let deadline = Date().addingTimeInterval(20)
            while cleanup.isRunning && Date() < deadline {
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            }
            if cleanup.isRunning { cleanup.terminate() }
            cleanup.waitUntilExit()
            return cleanup.terminationStatus == 0
        } catch { return false }
    }

    func revealOutput(_ url: URL, openImage: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard FileManager.default.fileExists(atPath: url.path) else {
                self.statusLabel.stringValue = "Output image could not be found: \(url.lastPathComponent)"
                NSRunningApplication.current.activate(options: [])
                return
            }
            if openImage {
                // Quick Look is presented directly. No Finder focus test, simulated
                // Space key, or extra Accessibility/Automation approval is needed.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if self.outputPreviewController == nil {
                        self.outputPreviewController = InjectZOutputPreviewController()
                    }
                    if self.outputPreviewController?.showImage(url) != true {
                        self.statusLabel.stringValue = "Image saved, but its preview could not be opened. Use Show Result in Finder to find it."
                    }
                }
            } else {
                NSWorkspace.shared.activateFileViewerSelecting([url])
                _ = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder")
                    .first?.activate(options: [.activateAllWindows])
            }
        }
    }
}

// INJECTZ_DIRECT_QUICK_LOOK_20261007
final class InjectZOutputPreviewWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 || event.keyCode == 53 {
            performClose(nil)
        } else {
            super.keyDown(with: event)
        }
    }
}

final class InjectZOutputPreviewController: NSWindowController {
    private var preview: QLPreviewView?

    init() {
        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let frame = NSRect(x: 0, y: 0, width: visible.width, height: visible.height)
        let panel = InjectZOutputPreviewWindow(contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 400, height: 300)
        panel.collectionBehavior = [.fullScreenPrimary]
        panel.center()
        super.init(window: panel)
        if let content = panel.contentView, let view = QLPreviewView(frame: content.bounds, style: .normal) {
            view.autoresizingMask = [.width, .height]
            view.shouldCloseWithWindow = false
            content.addSubview(view)
            preview = view
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func showImage(_ url: URL) -> Bool {
        guard let preview = preview, let window = window else { return false }
        // INJECTZ_FULL_WIDTH_PREVIEW_20261007
        // Use the outer frame so the title bar also stays within the screen.
        let screen = window.screen ?? NSScreen.main
        if let visible = screen?.visibleFrame {
            window.setFrame(visible, display: true)
        }
        window.title = url.lastPathComponent
        preview.previewItem = url as NSURL
        preview.refreshPreviewItem()
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        return true
    }
}

let injectZUpdateLockDescriptor = injectZStartupUpdateLock()
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()

import Cocoa
import WebKit

// One retained editor session; closing the window preserves unsaved selections.
final class SharpDepthEditorController: NSObject, NSWindowDelegate, WKNavigationDelegate, WKUIDelegate {
    let window: NSWindow
    let web: WKWebView
    let task = Process()
    let sessionDirectory: URL
    let photo: URL
    var readyTimer: Timer?
    var elapsed = 0
    var logHandle: FileHandle?

    init(photo: URL) throws {
        self.photo = photo
        sessionDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("InjectZ-Editor-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: sessionDirectory, withIntermediateDirectories: true)
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        web = WKWebView(frame: .zero, configuration: config)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 850), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init()
        window.title = "SHARP Manual Depth Editor — " + photo.lastPathComponent
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = web
        window.minSize = NSSize(width: 820, height: 600)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.loadHTMLString("<body style='font:20px system-ui;padding:40px'>Opening SHARP Manual Depth Editor…<p>If a saved selection exists, choose Resume or Start Fresh in the Mac dialog.</p></body>", baseURL: nil)
        let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("InjectZ")
        task.executableURL = root.appendingPathComponent("Runtime/python/bin/python3")
        task.arguments = [root.appendingPathComponent("Development/SHARPDepthEditor/server.py").path, photo.path]
        task.currentDirectoryURL = root.appendingPathComponent("Development/SHARPDepthEditor")
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["PYTHONUNBUFFERED"] = "1"
        env["INJECTZ_EDITOR_EMBEDDED"] = "1"
        env["INJECTZ_EDITOR_URL_FILE"] = sessionDirectory.appendingPathComponent("url.txt").path
        task.environment = env
        let log = sessionDirectory.appendingPathComponent("startup.log")
        FileManager.default.createFile(atPath: log.path, contents: nil)
        logHandle = try FileHandle(forWritingTo: log)
        task.standardOutput = logHandle
        task.standardError = logHandle
        try task.run()
        readyTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in self?.checkReady() }
        window.center()
        show()
    }
    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    func checkReady() {
        elapsed += 1
        let urlFile = sessionDirectory.appendingPathComponent("url.txt")
        if let text = try? String(contentsOf: urlFile, encoding: .utf8),
           let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
           url.host == "127.0.0.1" {
            readyTimer?.invalidate(); readyTimer = nil
            web.load(URLRequest(url: url)); return
        }
        // Resume dialogs can legitimately remain open; don't time out a user's choice.
        if !task.isRunning {
            readyTimer?.invalidate(); readyTimer = nil
            let log = (try? String(contentsOf: sessionDirectory.appendingPathComponent("startup.log"), encoding: .utf8)) ?? "No diagnostic output."
            let alert = NSAlert()
            alert.messageText = "Could not open SHARP Manual Depth Editor"
            alert.informativeText = String(log.suffix(3500))
            alert.runModal()
        }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.host == "127.0.0.1" || url.scheme == "about" { decisionHandler(.allow) }
        else { decisionHandler(.cancel); NSWorkspace.shared.open(url) }
    }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = "SHARP Manual Depth Editor"
        alert.informativeText = message
        alert.runModal()
        completionHandler()
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "SHARP Manual Depth Editor"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        completionHandler(alert.runModal() == .alertFirstButtonReturn)
    }
    func stop() {
        readyTimer?.invalidate(); readyTimer = nil
        if task.isRunning { task.terminate() }
        try? logHandle?.close()
    }
    deinit { stop() }
}

extension AppDelegate {
    @objc func showSharpDepthEditor() {
        guard convertButton.isEnabled else {
            statusLabel.stringValue = "Wait for the current conversion to finish before editing depth."
            return
        }
        if let editor = sharpDepthEditor, editor.task.isRunning { editor.show(); return }
        sharpDepthEditor?.stop(); sharpDepthEditor = nil
        if selectedPhoto == nil { choosePhoto() }
        guard let photo = selectedPhoto else { return }
        do { sharpDepthEditor = try SharpDepthEditorController(photo: photo) }
        catch {
            let alert = NSAlert()
            alert.messageText = "Could not start SHARP Manual Depth Editor"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
    @objc func closeSharpDepthEditorSession() {
        guard let editor = sharpDepthEditor else { return }
        let alert = NSAlert()
        alert.messageText = "Close the editor session?"
        alert.informativeText = "Any running preview will stop. Save your current selection changes before closing; saved changes can be resumed later."
        alert.addButton(withTitle: "Close Session")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        editor.stop(); editor.window.close(); sharpDepthEditor = nil
    }
    @objc func newSharpDepthEditorSession() {
        if let editor = sharpDepthEditor, editor.task.isRunning {
            let alert = NSAlert()
            alert.messageText = "Start a different editor session?"
            alert.informativeText = "This stops the current editor and any preview it is rendering. Saved changes remain available when you select that photograph again."
            alert.addButton(withTitle: "Start New Session")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            editor.stop(); editor.window.close(); sharpDepthEditor = nil
        }
        showSharpDepthEditor()
    }
}


// Completion audio preferences and persistent shuffle cycle.
final class InjectZAudioAlerts: NSObject {
    static let shared = InjectZAudioAlerts()
    private let defaults = UserDefaults.standard
    private var sound: NSSound?
    private var panel: NSPanel?
    private var list: NSStackView?
    private var toggle: NSButton?
    private var message: NSTextField?
    private var files: [URL] = []
    private let enabledKey = "InjectZAudioEnabled"
    private let excludedKey = "InjectZAudioExcluded"
    private let queueKey = "InjectZAudioQueue"
    private let lastKey = "InjectZAudioLast"
    private var folder: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/InjectZ/AudioAlerts", isDirectory: true)
    }
    private var enabled: Bool { defaults.object(forKey: enabledKey) == nil || defaults.bool(forKey: enabledKey) }
    private func scan() -> [URL] {
        let fm = FileManager.default
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        // Seed bundled melodies once per filename, preserving user choices and deletions.
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("AudioAlerts", isDirectory: true),
           let tracks = try? fm.contentsOfDirectory(at: bundled, includingPropertiesForKeys: nil) {
            var installed = Set(defaults.stringArray(forKey: "InjectZAudioBundledInstalled") ?? [])
            for track in tracks where track.pathExtension.lowercased() == "m4a" {
                let name = track.lastPathComponent
                guard !installed.contains(name) else { continue }
                let target = folder.appendingPathComponent(name)
                if fm.fileExists(atPath: target.path) { installed.insert(name) }
                else if (try? fm.copyItem(at: track, to: target)) != nil { installed.insert(name) }
            }
            defaults.set(Array(installed), forKey: "InjectZAudioBundledInstalled")
        }
        return ((try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
            .filter { ["m4a", "mp3", "wav", "aiff", "aif", "caf"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
    func playCompletion() {
        guard enabled else { return }
        let excluded = Set(defaults.stringArray(forKey: excludedKey) ?? [])
        let available = scan().filter { !excluded.contains($0.lastPathComponent) }
        let names = available.map { $0.lastPathComponent }
        guard !names.isEmpty else { return }
        let known = defaults.stringArray(forKey: "InjectZAudioKnown") ?? []
        var queue = (defaults.stringArray(forKey: queueKey) ?? []).filter { names.contains($0) }
        queue += names.filter { !known.contains($0) && !queue.contains($0) }.shuffled()
        if queue.isEmpty {
            queue = names.shuffled()
            if queue.count > 1, queue.first == defaults.string(forKey: lastKey) { queue.swapAt(0, 1) }
        }
        defaults.set(names, forKey: "InjectZAudioKnown")
        while !queue.isEmpty {
            let name = queue.removeFirst()
            defaults.set(queue, forKey: queueKey)
            guard let url = available.first(where: { $0.lastPathComponent == name }),
                  let next = NSSound(contentsOf: url, byReference: false) else { continue }
            sound?.stop(); sound = next
            if next.play() { defaults.set(name, forKey: lastKey); break }
        }
    }
    @objc func showSettings() {
        if let panel = panel { reload(); panel.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 620, height: 520), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        p.title = "Audio Alerts"; p.isReleasedWhenClosed = false; p.center()
        guard let c = p.contentView else { return }
        let t = NSButton(checkboxWithTitle: "Play an audio alert when a conversion finishes", target: self, action: #selector(enabledChanged(_:)))
        t.frame = NSRect(x: 20, y: 470, width: 580, height: 28); c.addSubview(t); toggle = t
        let hint = NSTextField(labelWithString: "Checked melodies play in shuffled order, once each per round.")
        hint.frame = NSRect(x: 20, y: 438, width: 580, height: 24); c.addSubview(hint)
        let scroll = NSScrollView(frame: NSRect(x: 20, y: 105, width: 580, height: 325))
        scroll.hasVerticalScroller = true; scroll.borderType = .bezelBorder
        let stack = NSStackView(); stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        let document = NSView(); document.addSubview(stack); scroll.documentView = document
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: document.topAnchor, constant: 8), stack.leadingAnchor.constraint(equalTo: document.leadingAnchor, constant: 8), stack.trailingAnchor.constraint(equalTo: document.trailingAnchor, constant: -8), stack.bottomAnchor.constraint(equalTo: document.bottomAnchor, constant: -8), document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor)])
        document.translatesAutoresizingMaskIntoConstraints = false
        c.addSubview(scroll); list = stack
        let add = NSButton(title: "Add Audio Files…", target: self, action: #selector(addFiles))
        add.frame = NSRect(x: 20, y: 62, width: 170, height: 32); c.addSubview(add)
        let stop = NSButton(title: "Stop Audio", target: self, action: #selector(stopAudio))
        stop.frame = NSRect(x: 205, y: 62, width: 130, height: 32); c.addSubview(stop)
        let all = NSButton(title: "Select All", target: self, action: #selector(selectAll))
        all.frame = NSRect(x: 350, y: 62, width: 115, height: 32); c.addSubview(all)
        let none = NSButton(title: "Select None", target: self, action: #selector(selectNone))
        none.frame = NSRect(x: 475, y: 62, width: 125, height: 32); c.addSubview(none)
        let m = NSTextField(labelWithString: ""); m.frame = NSRect(x: 20, y: 20, width: 580, height: 30); m.maximumNumberOfLines = 2
        c.addSubview(m); message = m; panel = p; reload(); p.makeKeyAndOrderFront(nil)
    }
    private func reload() {
        files = scan(); toggle?.state = enabled ? .on : .off
        guard let list = list else { return }
        for v in list.arrangedSubviews { list.removeArrangedSubview(v); v.removeFromSuperview() }
        let excluded = Set(defaults.stringArray(forKey: excludedKey) ?? [])
        for (index, url) in files.enumerated() {
            let row = NSStackView(); row.orientation = .horizontal; row.spacing = 10
            let check = NSButton(checkboxWithTitle: url.deletingPathExtension().lastPathComponent, target: self, action: #selector(selectionChanged(_:)))
            check.tag = index; check.state = excluded.contains(url.lastPathComponent) ? .off : .on
            check.lineBreakMode = .byTruncatingMiddle; check.widthAnchor.constraint(equalToConstant: 445).isActive = true
            let preview = NSButton(title: "Preview", target: self, action: #selector(preview(_:))); preview.tag = index
            row.addArrangedSubview(check); row.addArrangedSubview(preview); list.addArrangedSubview(row)
        }
        message?.stringValue = files.isEmpty ? "No audio files yet. Click Add Audio Files to choose your melodies." : "\(files.count - files.filter { excluded.contains($0.lastPathComponent) }.count) of \(files.count) melodies enabled. Changes are saved automatically."
    }
    @objc private func enabledChanged(_ sender: NSButton) { defaults.set(sender.state == .on, forKey: enabledKey); if sender.state == .off { stopAudio() } }
    @objc private func selectionChanged(_ sender: NSButton) {
        guard files.indices.contains(sender.tag) else { return }
        var excluded = Set(defaults.stringArray(forKey: excludedKey) ?? [])
        let name = files[sender.tag].lastPathComponent
        if sender.state == .on { excluded.remove(name) } else { excluded.insert(name) }
        defaults.set(Array(excluded), forKey: excludedKey); reload()
    }
    @objc private func preview(_ sender: NSButton) {
        guard files.indices.contains(sender.tag) else { return }
        stopAudio(); sound = NSSound(contentsOf: files[sender.tag], byReference: false)
        if sound?.play() != true { message?.stringValue = "This recording could not be played." }
    }
    @objc private func stopAudio() { sound?.stop(); sound = nil }
    @objc private func selectAll() { defaults.set([String](), forKey: excludedKey); reload() }
    @objc private func selectNone() { defaults.set(files.map { $0.lastPathComponent }, forKey: excludedKey); reload() }
    @objc private func addFiles() {
        let chooser = NSOpenPanel(); chooser.allowsMultipleSelection = true; chooser.canChooseDirectories = false
        chooser.allowedContentTypes = [.audio]; chooser.message = "Choose melodies to add to your completion alerts."
        guard chooser.runModal() == .OK else { return }
        var failures = 0
        for url in chooser.urls {
            guard NSSound(contentsOf: url, byReference: false) != nil else { failures += 1; continue }
            var dest = folder.appendingPathComponent(url.lastPathComponent); var n = 2
            while FileManager.default.fileExists(atPath: dest.path) {
                dest = folder.appendingPathComponent("\(url.deletingPathExtension().lastPathComponent) (\(n)).\(url.pathExtension)"); n += 1
            }
            do { try FileManager.default.copyItem(at: url, to: dest) } catch { failures += 1 }
        }
        reload(); if failures > 0 { message?.stringValue = "\(failures) file(s) could not be added. Other files were imported." }
    }
}



// Inject Z optional support panel — 2026-10-18.
// Only an explicit Help menu action presents this window or opens a URL.
final class InjectZSupportPanel: NSObject {
    static let shared = InjectZSupportPanel()
    private var supportWindow: NSWindow?
    private let destinations = [
        "https://ko-fi.com/tedwhitten",
        "https://paypal.me/theodorewhitten1",
        "https://patreon.com/TedWhitten"
    ]

    @objc func showSupport(_ sender: Any?) {
        if let existing = supportWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 510, height: 540),
                             styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.title = "Support Inject Z"
        panel.isReleasedWhenClosed = false
        guard let content = panel.contentView else { return }
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor)
        ])
        let heart = NSImageView()
        heart.image = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: "Support")
        heart.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        heart.contentTintColor = .systemPink
        heart.setAccessibilityElement(false)
        stack.addArrangedSubview(heart)
        heart.heightAnchor.constraint(equalToConstant: 36).isActive = true

        func label(_ text: String, size: CGFloat, bold: Bool = false) -> NSTextField {
            let field = NSTextField(wrappingLabelWithString: text)
            field.alignment = .center
            field.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
            field.textColor = .labelColor
            stack.addArrangedSubview(field)
            field.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            return field
        }
        _ = label("Support Inject Z", size: 21, bold: true)
        _ = label("Inject Z is independently developed and provided free of charge.", size: 13)
        _ = label("If you enjoy using the app and would like to support its continued development, voluntary contributions are greatly appreciated.", size: 13)
        let titles = ["Ko-fi — Leave a Tip", "PayPal — Make a Donation", "Patreon — Become a Supporter"]
        for (index, title) in titles.enumerated() {
            let button = NSButton(title: title, target: self, action: #selector(openDestination(_:)))
            button.bezelStyle = .rounded
            button.controlSize = .large
            button.font = .systemFont(ofSize: 14)
            button.tag = index
            button.toolTip = "Open \(destinations[index]) in your default browser"
            button.setAccessibilityHelp(button.toolTip)
            stack.addArrangedSubview(button)
            button.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true
        }
        let thanks = label("Thank you for supporting Inject Z!", size: 12)
        thanks.textColor = .secondaryLabelColor
        let close = NSButton(title: "Close", target: self, action: #selector(closeSupport(_:)))
        close.bezelStyle = .rounded
        close.keyEquivalent = "\u{1b}"
        stack.addArrangedSubview(close)
        supportWindow = panel
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func closeSupport(_ sender: Any?) {
        supportWindow?.performClose(sender)
    }

    @objc private func openDestination(_ sender: NSButton) {
        guard destinations.indices.contains(sender.tag),
              let url = URL(string: destinations[sender.tag]) else { return }
        if !NSWorkspace.shared.open(url) {
            let alert = NSAlert()
            alert.messageText = "Could not open your browser"
            alert.informativeText = "You can visit this address directly:\n\(url.absoluteString)"
            if let panel = supportWindow { alert.beginSheetModal(for: panel, completionHandler: nil) }
        }
    }
}



// Native source-update controls. Download/build/sign happen off the main thread.
final class InjectZUpdates {
    static let shared = InjectZUpdates()
    private let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("InjectZ")
    private var checking = false
    static var automatic: Bool {
        let file = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("InjectZ/Updates/preferences.json")
        guard let data = try? Data(contentsOf: file), let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return true }
        return object["automatic"] as? Bool ?? false
    }
    private var python: URL? {
        ["Runtime/python/bin/python3", "Development/IW3/python/bin/python"].map { root.appendingPathComponent($0) }.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
    private var helper: URL { root.appendingPathComponent("Development/Updater/injectz_update.py") }
    private func show(_ title: String, _ message: String) {
        let alert = NSAlert(); alert.messageText = title; alert.informativeText = message; alert.runModal()
    }
    private func execute(_ arguments: [String], completion: @escaping ([String: Any]) -> Void) {
        guard let python, FileManager.default.fileExists(atPath: helper.path) else {
            completion(["error": "Update components are missing. Run Setup/ENABLE_APP_UPDATES.command from the current GitHub source once. Your installed models and settings are retained."]); return
        }
        let path = helper, base = root, appPath = Bundle.main.bundleURL.path
        DispatchQueue.global(qos: .utility).async {
            let process = Process(), output = Pipe()
            process.executableURL = python
            process.arguments = [path.path, "--root", base.path, "--app", appPath] + arguments
            process.standardOutput = output; process.standardError = FileHandle.nullDevice
            do {
                try process.run()
                let data = output.fileHandleForReading.readDataToEndOfFile(); process.waitUntilExit()
                let result = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? ["error": "Could not read updater output. See ~/InjectZ/Updates/update.log."]
                DispatchQueue.main.async { completion(result) }
            } catch { DispatchQueue.main.async { completion(["error": error.localizedDescription]) } }
        }
    }
    func register() {
        execute(["--register"]) { result in
            if let error = result["error"] as? String { NSLog("Inject Z updater registration: %@", error) }
        }
    }
    func setAutomatic(_ item: NSMenuItem, completion: @escaping (Bool?) -> Void) {
        let value = item.state != .on
        execute(["--set-automatic", value ? "yes" : "no"]) { result in
            if let error = result["error"] as? String {
                self.show("Could not change automatic updates", error)
                completion(nil)
            } else { completion(value) }
        }
    }
    private func busy(_ owner: AppDelegate) -> Bool {
        if owner.convertButton?.isEnabled == false { return true }
        if let editor = owner.sharpDepthEditor, editor.task.isRunning { return true }
        return false
    }
    func check(owner: AppDelegate) {
        if checking { return }
        checking = true
        execute(["--check"]) { result in
            self.checking = false
            if let error = result["error"] as? String { self.show("Could not check for updates", error); return }
            guard result["available"] as? Bool == true, let version = result["version"] as? String else {
                self.show("Inject Z is up to date", "Installed version: \(result["current"] as? String ?? "unknown"). Automatic updates install only while Inject Z and its engine/editor workers are closed."); return
            }
            let alert = NSAlert(); alert.messageText = "Inject Z \(version) is available"
            alert.informativeText = "Download, verify and build the new app locally, preserving the current signing identity, models and settings. A successful build can be installed after closing Inject Z. This may take a few minutes."
            alert.addButton(withTitle: "Download and Prepare"); alert.addButton(withTitle: "Later")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            if self.busy(owner) { self.show("Finish your work first", "Finish the conversion and save/close the depth editor before updating."); return }
            self.checking = true; owner.statusLabel.stringValue = "Preparing update — downloading, building and verifying…"
            self.execute(["--prepare"]) { prepared in
                self.checking = false; owner.statusLabel.stringValue = "Update preparation finished."
                if let error = prepared["error"] as? String { self.show("The installed app was not changed", error); return }
                guard let job = prepared["job"] as? String else { self.show("Inject Z is up to date", "No installation is needed."); return }
                if self.busy(owner) {
                    self.execute(["--discard-job", job]) { _ in }
                    self.show("Finish your work first", "The download was discarded. Finish your work, then check again. No running work was stopped."); return
                }
                let confirm = NSAlert(); confirm.messageText = "Install and relaunch Inject Z?"
                confirm.informativeText = "The replacement is built and verified. Program files will be backed up. Models, environments, preferences and saved sessions remain in place."
                confirm.addButton(withTitle: "Install and Relaunch"); confirm.addButton(withTitle: "Later")
                guard confirm.runModal() == .alertFirstButtonReturn else {
                    self.execute(["--discard-job", job]) { _ in }; return
                }
                guard let python = self.python else { return }
                let process = Process(); process.executableURL = python
                process.arguments = [job + "/apply.py", "--root", self.root.path, "--app", Bundle.main.bundleURL.path, "--finish", job, "--wait-pid", String(ProcessInfo.processInfo.processIdentifier), "--reopen"]
                process.standardOutput = FileHandle.nullDevice; process.standardError = FileHandle.nullDevice
                do { try process.run(); NSApp.terminate(nil) }
                catch { self.show("Could not start installation", error.localizedDescription) }
            }
        }
    }
}

// Share the lock for this entire native process. Installation takes it exclusively.
func injectZStartupUpdateLock() -> Int32 {
    let directory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("InjectZ/Updates")
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let descriptor = Darwin.open(directory.appendingPathComponent("install.lock").path, O_CREAT | O_RDWR | O_CLOEXEC, mode_t(0o600))
    guard descriptor >= 0 else { return -1 }
    if flock(descriptor, LOCK_SH | LOCK_NB) == 0 { return descriptor }
    let deadline = Date().addingTimeInterval(120)
    while Date() < deadline {
        usleep(200_000)
        if flock(descriptor, LOCK_SH | LOCK_NB) == 0 {
            flock(descriptor, LOCK_UN); Darwin.close(descriptor)
            let reopen = Process(); reopen.executableURL = URL(fileURLWithPath: "/usr/bin/open"); reopen.arguments = ["-n", Bundle.main.bundleURL.path]
            try? reopen.run(); exit(0)
        }
    }
    Darwin.close(descriptor); exit(1)
}

