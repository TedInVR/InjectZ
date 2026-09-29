# InjectZ

InjectZ is a macOS photo-to-stereo app that can use IW3, Apple SHARP, or Apple Photos Reframe. Its interface offers Parallel, Crossview, and three anaglyph formats, with multiple outputs selected for one conversion.

This repository is a **source snapshot**, assembled from the current Mac source on September 29, 2026. It is not a self-contained installer or a verified build recipe. The app currently uses separate local IW3 and SHARP installations, Python environments, model weights, and a dedicated Photos working library. The GUI source is marked “Multi output R14”; the Reframe finish helper contains the later R15 image-dimension fix. Do not assume every feature has been fully regression tested.

## Source layout

- `App/InjectZ.swift` — AppKit interface, engine selection, conversion orchestration, Photos automation, output handling.
- `IW3/create_layered_psd.py` — editable depth PSD helper.
- `SHARP/` — InjectZ integration and rendering wrappers; Apple's SHARP repository and weights are separate.
- `Reframe/` — Photos import/export automation, library guard, stereo assembly, window correction, and format generation.
- `Assets/InjectZ.iconset/` — app icon artwork from the available asset archive.
- `Docs/` — architecture, third-party components, and development status.

The source was compared byte for byte with the earlier exchange snapshot for overlapping files. It does not include personal photos, generated images, Photos libraries, installed runtimes, model weights, app bundles, signing materials, or backups.

## Development status

See [architecture](Docs/ARCHITECTURE.md) and [development log](Docs/DEVELOPMENT_LOG.md). Building and installing on a fresh Mac still needs a documented environment, dependency versions, Info.plist/resource packaging, and the user's own signing identity. The Mac installation uses `~/InjectZ` paths; do not run a compiled copy against an unrelated Photos library.

No license for the original InjectZ source has been selected. See [third-party notes](Docs/THIRD_PARTY.md) for separately maintained components.
