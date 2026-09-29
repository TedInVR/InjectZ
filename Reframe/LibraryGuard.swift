import Cocoa
import Darwin

// Fail-closed guard. Never imports unless the running Photos process is observed
// accessing a file inside the exact working library bundle.
let fm = FileManager.default
let home = fm.homeDirectoryForCurrentUser
let work = home.appendingPathComponent("InjectZ/Development/InjectZ Working Library.photoslibrary").standardizedFileURL
func fail(_ message: String) -> Never { fputs("LIBRARY GUARD: \(message)\n", stderr); exit(2) }
guard fm.fileExists(atPath: work.path) else { fail("Working library missing: \(work.path)") }
let photos = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Photos")
if photos.isEmpty {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    task.arguments = ["-a", "Photos", work.path]
    do { try task.run(); task.waitUntilExit() } catch { fail("Could not open working library: \(error)") }
    guard task.terminationStatus == 0 else { fail("Photos refused to open working library") }
} else {
    // An already-running Photos instance could be using the personal library.
    // Do not force-switch or quit it without an independently safe mechanism.
    print("Photos is already running. Verifying its active library before import.")
}
func runningPIDs() -> [pid_t] {
    NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Photos").map { $0.processIdentifier }
}
var verified = false
for _ in 0..<20 {
    for pid in runningPIDs() {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-Fn", "-p", String(pid)]
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            let paths = (String(data: data, encoding: .utf8) ?? "").split(separator: "\n")
            let prefix = work.path + "/"
            if paths.contains(where: { $0.hasPrefix("n" + prefix) }) { verified = true; break }
        } catch { fail("Cannot inspect Photos' open files; import blocked") }
    }
    if verified { break }
    Thread.sleep(forTimeInterval: 0.5)
}
guard verified else {
    fail("Could not independently confirm that Photos is using the InjectZ Working Library. No import performed. Quit Photos and retry, or inspect permissions.")
}
print("VERIFIED: Photos has open files inside \(work.path)")
