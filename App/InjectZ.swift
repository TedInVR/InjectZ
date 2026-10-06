import Cocoa
import UniformTypeIdentifiers
import ApplicationServices

final class DropView: NSView {
    var onDrop: ((URL) -> Void)?

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
        ) as? [URL], let url = urls.first else { return false }
        onDrop?(url)
        return true
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
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
    let formatIDs = ["Parallel", "Crossview", "Anaglyph_FullColor", "Anaglyph_HalfColor", "Anaglyph_Dubois"]
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
        if let panel = sharpEdgesPanel { panel.makeKeyAndOrderFront(nil); return }
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
        panel.makeKeyAndOrderFront(nil)
    }

    var sharpDepthSelection = 3
    var iw3StrengthSelection = 4
    var reframeAppliedPan: Double = 0
    var reframeRequestedPan: Double = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        buildUI()
    }

    @objc func checkForInjectZUpdates(_ sender: Any?) {
        let url = URL(string: "https://api.github.com/repos/TedInVR/InjectZ/releases/latest")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("InjectZ/0.3.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                let alert = NSAlert()
                let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.3.0"
                if (response as? HTTPURLResponse)?.statusCode == 404 {
                    alert.messageText = "No published release yet"
                    alert.informativeText = "You have Inject Z \(current). Releases will appear on GitHub when published."
                } else if error == nil, (response as? HTTPURLResponse)?.statusCode == 200,
                          let data, let info = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                          let tag = info["tag_name"] as? String {
                    let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
                    let valid = latest.range(of: "^[0-9]+\\.[0-9]+\\.[0-9]+$", options: .regularExpression) != nil
                    if valid && latest.compare(current, options: .numeric) == .orderedDescending {
                        alert.messageText = "Inject Z \(latest) is available"
                        alert.informativeText = "You have \(current). Open the release page to read the changes and download the update. Quit Inject Z before running UPDATE_EXISTING.command from the downloaded package."
                        alert.addButton(withTitle: "Open Release Page")
                        alert.addButton(withTitle: "Later")
                        if alert.runModal() == .alertFirstButtonReturn {
                            NSWorkspace.shared.open(URL(string: "https://github.com/TedInVR/InjectZ/releases/latest")!)
                        }
                        return
                    }
                    alert.messageText = valid ? "Inject Z is up to date" : "Could not read the release version"
                    alert.informativeText = "Installed version: \(current). Latest published tag: \(tag)."
                } else {
                    alert.messageText = "Could not check for updates"
                    alert.informativeText = "Check your internet connection and try again. You can also visit github.com/TedInVR/InjectZ/releases."
                }
                alert.runModal()
            }
        }.resume()
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
        let closeItem = NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        closeItem.keyEquivalentModifierMask = [.command]
        fileMenu.addItem(closeItem)
        fileItem.submenu = fileMenu
        mainMenu.addItem(fileItem)

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
        NSApp.mainMenu = mainMenu
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let u = urls.first { selectPhoto(u) }
    }

    func buildUI() {
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in self?.sharpDepthEditor?.stop() }
        let frame = NSRect(x: 0, y: 0, width: 600, height: 470)
        window = NSWindow(contentRect: frame,
                          styleMask: [.titled, .closable, .miniaturizable],
                          backing: .buffered, defer: false)
        window.title = "Inject Z"
        window.isReleasedWhenClosed = false
        window.center()

        let c = DropView(frame: frame)
        c.onDrop = { [weak self] url in self?.selectPhoto(url) }
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

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
        keepEyes.isEnabled = !iw3
        keepEyes.isHidden = iw3 || enginePopup.indexOfSelectedItem == 2
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
        if let panel = advancedPanel { panel.makeKeyAndOrderFront(nil); return }
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
        panel.makeKeyAndOrderFront(nil)
    }

    @objc func choosePhoto() {
        let p = NSOpenPanel()
        p.allowsMultipleSelection = false
        p.canChooseDirectories = false
        p.allowedContentTypes = [.image]
        if p.runModal() == .OK, let u = p.url { selectPhoto(u) }
    }

    func selectPhoto(_ u: URL) {
        selectedPhoto = u
        photoField.stringValue = u.lastPathComponent
        statusLabel.stringValue = "Ready"
        revealButton.isEnabled = false
        lastOutput = nil
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

    func runConversion(depthMapOnly: Bool) {
        guard let photo = selectedPhoto else {
            NSSound.beep()
            statusLabel.stringValue = "Choose or drop a photo first."
            return
        }
        let formats = selectedFormats()
        guard !formats.isEmpty else { statusLabel.stringValue = "Select at least one stereo format."; return }
        let selectedEngine = enginePopup.indexOfSelectedItem
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
            if keepEyes.state == .on { args.append("--keep-eyes") }
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
        statusLabel.stringValue = depthMapOnly ? "Generating depth map…" : "Converting…"

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
                    var result: URL?
                    var completionNote = ""
                    let fm = FileManager.default
                    let stem = photo.deletingPathExtension().lastPathComponent
                    let photoFolder = photo.deletingLastPathComponent()
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
                            let emitted = self.emitFormats(from: generated, source: photo, engine: "SHARP", depth: baseline, formats: formats)
                            result = emitted?.first
                            if emitted == nil { completionNote = " (format generation failed; internal parallel render retained)" }
                        }
                    }
                    if let result = result, FileManager.default.fileExists(atPath: result.path) {
                        self.lastOutput = result
                        self.revealButton.isEnabled = true
                        self.statusLabel.stringValue = depthMapOnly ? "Depth map complete — \(result.lastPathComponent)\(completionNote)" : "Created \(formats.count) format(s) — \(result.lastPathComponent)"
                        self.revealOutput(result, openImage: true)
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

    func emitFormats(from parallel: URL, source: URL, engine: String, depth: String, formats: [String]) -> [URL]? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let helper = home.appendingPathComponent("InjectZ/Development/Reframe/SharedStereoFormats.py")
        let python = home.appendingPathComponent("InjectZ/Development/IW3/python/bin/python")
        guard FileManager.default.fileExists(atPath: helper.path),
              FileManager.default.isExecutableFile(atPath: python.path) else { return nil }
        let task = Process()
        task.executableURL = python
        let prefix = source.deletingPathExtension().path + "_InjectZ_" + engine
        task.arguments = [helper.path, parallel.path, "--output-prefix", prefix,
                          "--depth-token", depth, "--formats"] + formats
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
                                   "--pan", String(format: "%.4f", reframeAppliedPan), "--formats"] + formats
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
                        statusLabel.stringValue += " Working Photos album retained; remove it manually if desired."
                    }
                    revealOutput(lastOutput!, openImage: true)
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
            cleanup.arguments = [script.path, album]
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
        // Finder selection can happen behind Photos if invoked immediately
        // after Photos' export. Start Finder's own reveal command once Photos
        // and the exporter have settled, then explicitly activate Finder.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let reveal = Process()
            reveal.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            reveal.arguments = ["-R", url.path]
            do { try reveal.run() }
            catch { self.statusLabel.stringValue = "Image saved; Finder reveal failed: \(error.localizedDescription)"; return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
                _ = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder")
                    .first?.activate(options: [.activateAllWindows])
                if openImage {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        // Finder's Space key presents Quick Look without opening Preview.
                        // Accessibility permission already required by Reframe permits the key event.
                        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder",
                              let down = CGEvent(keyboardEventSource: nil, virtualKey: 49, keyDown: true),
                              let up = CGEvent(keyboardEventSource: nil, virtualKey: 49, keyDown: false) else {
                            self.statusLabel.stringValue = "Image saved and selected in Finder; press Space for Quick Look."
                            return
                        }
                        down.post(tap: .cghidEventTap)
                        up.post(tap: .cghidEventTap)
                    }
                }
            }
        }
    }
}

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
