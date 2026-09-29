# Architecture and current boundaries

The AppKit GUI in `App/InjectZ.swift` selects an engine and one or more output formats. The current Mac installation expects files below `~/InjectZ/Development/` and emits final photos next to the original image. The source here reflects the current Mac collector ZIP from September 29, 2026.

## Engines

- **IW3:** The GUI launches a separate nunif/IW3 Python runtime, finds its generated stereo image and depth data, and can call `IW3/create_layered_psd.py`. Requested display formats are handled by `Reframe/SharedStereoFormats.py`. The nunif source, models, and environment are external.
- **SHARP:** `SHARP/injectz_engine.py` invokes an external Apple SHARP installation and checkpoint, while `SHARP/injectz_sharp_render.py` renders left/right views from the splat representation. The GUI then emits selected formats. Apple's SHARP source and model are external.
- **Apple Reframe:** The GUI checks Photos Accessibility access and runs `Reframe/LibraryGuard.swift`'s compiled guard before import. AppleScript imports working copies and exports the edited eye. `Reframe/FinishSingleRight.py` normalizes modest size differences, applies `WindowGuard.py`, and calls stereo assembly and shared output formatting. Completed-album removal is best effort; imported media storage is not confirmed purged.

`Assets/InjectZ.iconset/` contains the available artwork, but this snapshot does not include an authoritative Info.plist, built `.icns`, or installer. Those belong in a future reproducible build process. The current signing identity and macOS Accessibility permission must not be copied to GitHub.

## Known issues and verification gaps

- SHARP produces blotchy skies on some images. No verified correction exists.
- Photos Reframe can reject particular images with a processing alert or restrict the available pan. This snapshot does not diagnose a daily quota.
- The R14 multi-format UI and R15 Reframe dimension handling need broader end-to-end testing; one failed Reframe export was recovered with the R15 helper.
- IW3 stereo-window protection and the placement of all optional outputs need checking against real conversions.
- The app relies on installed runtimes, fixed paths, and Photos UI behavior. This is source for collaboration, not a claim of portability.
