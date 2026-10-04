# Inject Z

A macOS photo-to-stereo app with Apple SHARP Gaussian splats, IW3 depth-based conversion, and automation of Apple Photos Reframe. Choose multiple output formats from a single conversion: parallel, crossview, and anaglyph variants including Dubois. Final images are saved beside the source photograph and presented through Finder Quick Look.

## Current source snapshot: 2026.10.04

This snapshot was collected from the installed app on October 4, 2026. The installed app still reports bundle version **0.2.2**; that number predates several updates. The dated snapshot identifies this source accurately without claiming a newly tested binary release.

Recent changes include the SHARP distant-sky clipping fix, optional SHARP depth-edge softening (off by default), IW3 strengths 1–6, photo-specific advanced settings with explanations and actual default values, and IW3 window protection using all four image borders. See [CHANGELOG](CHANGELOG.md).

**This download is developer source, not an out-of-the-box installer.** AI checkpoints, Python runtimes and third-party engine code are not bundled. The first-time installation and distribution work is described in [Setup](Docs/SETUP.md) and [Release checklist](Docs/RELEASE_CHECKLIST.md).

## Requirements and boundaries

- The current SHARP integration targets Apple Silicon Macs using PyTorch MPS and the Metal Gaussian renderer. Intel, Windows and Linux are not supported by this integration.
- Xcode Command Line Tools are needed to compile the Swift GUI and helpers and to build the renderer's native extension.
- Reframe requires a compatible Apple Photos installation with the Reframe feature, Accessibility/automation approval, and a separate working Photos library. The bundle's macOS minimum of 13.0 is not a claim that Reframe exists on macOS 13.
- Inject Z's IW3 interface handles photos. Video conversion remains a separate feature of upstream IW3.

## Source layout

| Folder | Contents |
|---|---|
| App | Swift AppKit GUI |
| SHARP | SHARP prediction wrapper, stereo renderer, optional edge softening |
| IW3 | Photo wrapper, settings/help definitions, PSD writer |
| Reframe | Photos scripts, library guard, stereo assembly and format conversion |
| Assets | Application icon and header artwork |
| Setup | Captured dependency versions and app metadata |
| Docs | Setup, architecture, development history and third-party information |

## Licensing

Inject Z's original source does not yet have a selected public license. Availability on GitHub does not itself grant an open-source license. Contact the repository owner for permission to reuse it until a license is selected.

Third-party engines and AI models have their own licenses. In particular, Apple's SHARP model is research-restricted; it is not a model with unrestricted commercial permission. See [Third-party components](Docs/THIRD_PARTY.md).
