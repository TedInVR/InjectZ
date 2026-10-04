# Developer setup and first-install requirements

This is a reconstruction guide for developers, not a tested one-click installation. Do not overwrite a working Inject Z installation with an incomplete environment.

## Current supported target

The working SHARP pipeline is Apple Silicon/macOS using PyTorch MPS. Install Xcode Command Line Tools. The captured installation uses Python 3.13.15 for SHARP and Python 3.12.14 for IW3. See `Setup/DependencyInventory.json` for the observed packages. Exact SHARP/nunif/metal-gauss source commit IDs were not captured; package version labels are not sufficient to reproduce local edits or editable source checkouts.

## Runtime layout required by the current source

- `~/InjectZ/InjectZ.swift` from `App/InjectZ.swift`.
- `~/InjectZ/injectz_engine.py`, `injectz_sharp_render.py`, `EdgeSoftener.py` from `SHARP/`.
- `~/InjectZ/Runtime/python/bin/python3`: SHARP environment with the official Apple SHARP implementation, PyTorch/MPS, metal-gauss, NumPy, Pillow and SciPy plus upstream requirements.
- `~/InjectZ/Models/SHARP/sharp_2572gikvuh.pt`: official SHARP checkpoint. Read the model agreement before obtaining/using it. The tested file SHA-256 is `94211a75198c47f61fca7d739ba08a215418d8d398d48fddf023baccc24f073d`.
- `~/InjectZ/Development/IW3/python/bin/python`: separate IW3 environment with upstream requirements and Pillow/NumPy for shared formats and PSD support.
- `~/InjectZ/Development/IW3/nunif`: official nunif checkout compatible with the captured photo wrapper/settings schema.
- `~/InjectZ/Development/IW3/photo_iw3.py` from `IW3/`.
- `~/InjectZ/IW3Settings.json` and `IW3SettingHelp.json` from `IW3/`.
- `~/InjectZ/Development/create_layered_psd.py` from `IW3/`.
- `~/InjectZ/Development/Reframe/`: contents of repository `Reframe/`; compile `LibraryGuard.swift` as `LibraryGuard` with Cocoa.

Obtain engine implementations from https://github.com/apple-aiml-research/ml-sharp, https://github.com/nandometzger/metal-gauss and https://github.com/nagadomi/nunif. Follow their official dependency installation instructions; never install an unrelated package merely because its name is `sharp`.

Before running IW3 through Inject Z, use the same IW3 environment and the same `HF_HOME`/`TORCH_HOME` paths (`Development/IW3/Cache/huggingface` and `Development/IW3/Cache/torch`) to download each selected depth model and the selected warp/inpaint models online. Inject Z then runs with Hugging Face offline mode. Downloading only a depth model may leave required inpainting/warp weights missing.

## Compile the application

`Setup/BUILD_SOURCE.command` builds an unsigned app into this repository's `build/` directory and compiles the library guard. It stages sources in an installation-layout folder. It does not install dependencies, overwrite your main app or download models. macOS must be used; compilation has not been run in this Linux preparation environment.

For local testing, keep one stable signing identity and bundle identifier. Do not reuse the owner's private key or local certificate. Changing the identity can invalidate Accessibility approval. A public binary release needs its own distribution signing/notarization process; the staged unsigned developer app is not that release.

## Photos Reframe setup

With Photos closed, hold Option while opening Photos and create a separate library named `InjectZ Working Library.photoslibrary` in `~/InjectZ/Development`. Do not designate it as the System Photo Library or enable iCloud syncing for this working library. The guard blocks import if it cannot verify the exact library. Reframe must exist in the installed Photos version; grants for Accessibility and Apple Events/Photos automation may be required. Reframe availability is not guaranteed by the GUI's bundle minimum OS version.

## Planned simple installation

A release installer should offer engine selection, show relevant model terms, create the runtime layout, download verified compatible dependencies and selected models from official locations, compile/preflight the Metal renderer, and guide Photos/permissions setup. It should verify one photo through each selected engine and keep a clear diagnostic log. Downloading every possible IW3 model is not required and would greatly increase size.

Until tested on a fresh Mac, advertise this repository as developer source, not as working out of the box.
