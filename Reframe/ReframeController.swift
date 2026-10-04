import Cocoa
import ApplicationServices

// Guided two-view Photos controller. Never changes an existing Photos item without explicit user action.
let args = CommandLine.arguments
func alert(_ title: String, _ message: String, _ buttons: [String] = ["Continue", "Cancel"]) -> Bool {
    let a = NSAlert(); a.messageText = title; a.informativeText = message
    for b in buttons { a.addButton(withTitle: b) }
    return a.runModal() == .alertFirstButtonReturn
}
func fail(_ message: String) -> Never { _ = alert("Reframe stopped", message, ["OK"]); exit(1) }
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
if !AXIsProcessTrustedWithOptions(options) { fail("Grant Accessibility permission to InjectZ and its ReframeController helper if macOS requests it. Then restart the development app and use Resume Reframe; do not click Convert again.") }
func attr(_ e: AXUIElement, _ key: String) -> AnyObject? {
    var value: CFTypeRef?
    return AXUIElementCopyAttributeValue(e, key as CFString, &value) == .success ? value : nil
}
func elements(_ root: AXUIElement) -> [AXUIElement] {
    var found: [AXUIElement] = []
    func visit(_ e: AXUIElement, _ depth: Int) {
        if depth > 35 || found.count > 2000 { return }
        found.append(e)
        if let kids = attr(e, kAXChildrenAttribute as String) as? [AXUIElement] { for k in kids { visit(k, depth + 1) } }
    }
    visit(root, 0); return found
}
func control(_ side: String, pan: Double, rotation: Double) {
    guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Photos").first else { fail("Open Photos first.") }
    let all = elements(AXUIElementCreateApplication(app.processIdentifier))
    let sliders = all.filter { (attr($0, kAXRoleAttribute as String) as? String) == (kAXSliderRole as String) }
    guard sliders.count == 6,
        (attr(sliders[1], kAXDescriptionAttribute as String) as? String) == "Horizontal",
        (attr(sliders[3], kAXDescriptionAttribute as String) as? String) == "Horizontal",
        abs(((attr(sliders[1], kAXMinValueAttribute as String) as? NSNumber)?.doubleValue ?? 999) + 30) < 0.01,
        abs(((attr(sliders[3], kAXMinValueAttribute as String) as? NSNumber)?.doubleValue ?? 999) + 0.17) < 0.01 else {
        fail("Photos isn't displaying the expected Reframe controls. Open the Reframe editor for the \(side) photo and retry.")
    }
    let settings = [(sliders[1], rotation), (sliders[3], pan)]
    for (slider, value) in settings {
        guard AXUIElementSetAttributeValue(slider, kAXValueAttribute as CFString, NSNumber(value: value)) == .success else { fail("Could not set \(side) perspective.") }
        Thread.sleep(forTimeInterval: 0.25)
        let readback = (attr(slider, kAXValueAttribute as String) as? NSNumber)?.doubleValue ?? 999
        guard abs(readback - value) < 0.003 else { fail("Photos did not retain requested value \(value). Got \(readback).") }
    }
    let reframe = all.first { (attr($0, kAXRoleAttribute as String) as? String) == (kAXButtonRole as String) && (attr($0, kAXDescriptionAttribute as String) as? String) == "Reframe" }
    guard let button = reframe else { fail("Couldn't locate Reframe button.") }
    guard AXUIElementPerformAction(button, kAXPressAction as CFString) == .success else { fail("Could not activate Reframe.") }
    Thread.sleep(forTimeInterval: 8)
    let updated = elements(AXUIElementCreateApplication(app.processIdentifier))
    let save = updated.first { (attr($0, kAXRoleAttribute as String) as? String) == (kAXButtonRole as String) && (attr($0, kAXDescriptionAttribute as String) as? String) == "Save Changes" }
    guard let saveButton = save else { fail("Photos did not expose Save Changes. Check Photos before proceeding.") }
    guard alert("\(side) view generated", "Inspect the image in Photos. Save Changes will be pressed only if you continue.") else { exit(2) }
    guard AXUIElementPerformAction(saveButton, kAXPressAction as CFString) == .success else { fail("Could not save \(side) view.") }
    Thread.sleep(forTimeInterval: 1)
}
let strength = args.count > 1 ? min(max(Double(args[1]) ?? 0.01, 0.001), 0.05) : 0.01
let rotation = args.count > 2 ? min(max(Double(args[2]) ?? 0.5, 0), 3) : 0.5
_ = NSApplication.shared
if !args.contains("--imported") {
    if !alert("InjectZ Reframe — guided stereo", "Open the LEFT copy in Reframe editing mode, then continue. This version still requires manual export.") { exit(2) }
}
control("LEFT", pan: -strength, rotation: -rotation)
if !alert("Prepare right-eye photo", "Open the RIGHT duplicate in Photos and enter Reframe editing mode. Do not reuse the already edited left copy.") { exit(2) }
control("RIGHT", pan: strength, rotation: rotation)
if args.count >= 7 && args[3] == "--auto-export" {
    let album = args[4], workingDir = args[5], sourcePhoto = args[6]
    let format = args.count > 7 ? args[7] : "Parallel"
    guard alert("Export both edited views?", "Photos has saved both perspectives. InjectZ will export their edited versions from the uniquely named working album and assemble a stereo PNG beside the source. No Photos items will be deleted.") else { exit(2) }
    let folder = URL(fileURLWithPath: workingDir)
    let script = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("InjectZ/Development/Reframe/ExportEditedAlbum.applescript")
    let exporter = Process(); exporter.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    exporter.arguments = [script.path, album, folder.appendingPathComponent("Exports").path]
    do { try exporter.run(); exporter.waitUntilExit() } catch { fail("Could not launch edited-image export: \(error)") }
    guard exporter.terminationStatus == 0 else { fail("Photos edited-image export failed. No files were deleted. See the Terminal report or inspect the working album.") }
    let finisher = Process(); finisher.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
    finisher.arguments = [URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("InjectZ/Development/Reframe/FinishReframe.py").path, workingDir, sourcePhoto, "--format", format]
    do { try finisher.run(); finisher.waitUntilExit() } catch { fail("Stereo assembly could not start: \(error)") }
    guard finisher.terminationStatus == 0 else { fail("Export succeeded but stereo assembly failed. All exports remain in the working folder.") }
    _ = alert("Reframe conversion finished", "Stereo output has been saved beside the original. Working Photos album and exports are preserved for review.", ["OK"])
} else {
    _ = alert("Both views generated", "Both Photos copies have been saved. Export each as a full-size image from Photos. The separate StereoAssembler.command combines them into Parallel or Crossview without resizing either eye.", ["OK"])
}
