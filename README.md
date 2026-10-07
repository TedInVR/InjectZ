# Inject Z

Inject Z converts ordinary 2D photographs into stereoscopic 3D images on an Apple Silicon Mac. Choose Apple SHARP, IW3, or Apple Photos Reframe, then generate Parallel, Crossview, and anaglyph images—including Dubois. You can select multiple output formats for a single conversion.

Final images are saved beside the source photograph and displayed using Finder Quick Look. Stereo-window protection is enabled by default, with an option to allow window violations.

Inject Z was vibe-coded with ChatGPT. In plain English, I described what I wanted the app to do, and ChatGPT helped write and revise the code. Development and testing are ongoing.

**Current release: [Inject Z 0.3.0](https://github.com/TedInVR/InjectZ/releases/tag/v0.3.0).** Download **InjectZ-0.3.0.zip** from the release’s Assets section.

**New to Inject Z?** Read the [User Guide](Docs/USER_GUIDE.md) for step-by-step instructions, including the SHARP Manual Depth Editor.

For a brief video introducing you to Inject Z, check out YouTube: https://www.youtube.com/watch?v=9XMi_wGZiH8  

## Conversion engines

- **Apple SHARP:** Gaussian splat reconstruction with adjustable depth and optional softening around depth edges. Includes a correction for distant-sky clipping in the Metal renderer, custom depth strength, and a Manual Depth Editor for adjusting selected parts of the reconstructed scene.
- **IW3:** Depth-map-based conversion with a choice of depth models, strengths from 1 to 6, and advanced photo settings with explanations.
- **Apple Photos Reframe:** Automation of the Reframe feature in the Photos editing tools, using a separate working Photos library.

Inject Z currently converts **photos, not videos**. Upstream IW3 supports video conversion separately.

## Computer requirements

- **Apple Silicon Mac:** M1, M2, M3, M4, or newer. This package targets Apple Silicon; Intel Macs, Windows, and Linux are not supported.
- **macOS and Photos:** For the intended full three-engine configuration, plan on macOS 27 or later with Reframe actually available in Photos. The exact supported OS/hardware combinations have not yet been independently verified. SHARP and IW3 may work on earlier macOS versions, but those configurations are not verified for this package.
- **Free storage:** The setup preview requires at least **15 GB free** before attempting a new installation. Additional IW3 models and working files may require more space. This is an installation check, not a measured final installation size.
- **Internet:** Required to download dependencies and AI models during setup.
- **Apple developer tools:** Xcode Command Line Tools provide the Swift compiler and build tools. The setup menu helps you install them.
- **Python:** The setup preview uses Python **3.13** for the setup worker/SHARP environment and Python **3.12** for IW3. It links to official macOS installers and also recognizes standard Homebrew installations.

Developed and tested on an M2 Max MacBook Pro with 64 GB of memory. Minimum memory requirements have not yet been established.

## Download and installation

Get the current package from [Releases](https://github.com/TedInVR/InjectZ/releases/latest). Under **Assets**, download **InjectZ-0.3.0.zip** and unzip it. This is a source-based package: setup builds the app on your Mac and downloads dependencies/models separately. It is not a self-contained, notarized app download.

### Updating an existing installation

1. Finish any conversions and quit Inject Z with **Command-Q**.
2. Open the unzipped release folder and double-click **UPDATE_EXISTING.command**. Keep Terminal open until it reports success.
3. Reopen **~/InjectZ/InjectZ.app** and check **About Inject Z** for the new version.

The updater creates a backup and updates the app plus support scripts. It preserves installed Python environments, AI models and saved depth-editor sessions. A certificate-signed installation requires its original signing certificate and private key to remain available. Ad-hoc-signed installations may need permission approval again after rebuilding.

The 0.3.0 update has been tested on the developer’s existing installation. A complete installation on a fresh Mac has not yet been verified.

### First-time guided setup

1. Open the unzipped release folder and double-click **START_HERE.command**. This opens Terminal and normal Mac dialogs. Keep Terminal open while setup runs.
2. **macOS may block the initial attempt.** For a downloaded command you trust, go to **System Settings → Privacy & Security**, scroll to the Security section, and look for **Open Anyway**. Follow the prompts, using your password or Touch ID if requested, then continue setup.
3. Choose **1. Check prerequisites**.
4. If anything is missing, use **2. Get Apple developer tools** and **3. Get Python 3.13 and 3.12**. Finish the official installers, then check again.
5. Choose **4. Review engine and model terms** before installing models.
6. Choose **5. Install a NEW Inject Z**. Select IW3/Reframe support, with optional SHARP research setup if your intended use complies with Apple’s model agreement.
7. Complete the engine-specific steps below and test one photograph with each engine you intend to use.

Installation is in **~/InjectZ**, inside your home folder. The app is **~/InjectZ/InjectZ.app**; setup does not install it into the main Applications folder.

**An existing ~/InjectZ folder blocks first-time setup.** Use UPDATE_EXISTING.command to update a working installation. Do not delete your existing folder to bypass this check.

### Getting future updates

Choose **Inject Z → Check for Updates…** in the app menu. It checks published GitHub Releases and offers to open the download page when a newer version is available. Download that release’s ZIP, quit Inject Z, and run its **UPDATE_EXISTING.command**.

Version 0.3.0 does not automatically download or install updates. All of the app’s source and support files are included in one release ZIP; there is no need to download them individually.

## SHARP Manual Depth Editor

If SHARP places an object or background at the wrong depth, select the original photograph and click **Manual Depth Editor…** with the SHARP engine selected. The editor can create its own SHARP reconstruction; you do not have to run a regular conversion first. Viewing a regular conversion first can help you decide what needs correction.

The editor includes:

- Automatic selection boxes and include/exclude samples, followed by precise brushes and rectangles.
- Zoom up to 32×, a visible brush circle, bracket-key brush resizing and Space-drag panning.
- Named saved changes that can be revised, enabled/disabled or merged.
- Shrink/expand selection, edge feathering, uniform shifts, directional gradients and rounded depth adjustments.
- Original and adjusted depth views of the actual SHARP splats.
- **Preview Stereo Pair**, which avoids accumulating final images beside the original, and **Render Stereo Pair** for saving the result.
- Optional reconstruction of exposed sky/background areas. This guesses missing content and can still produce artifacts; it is not intended to recreate faces or lettering.
- Circled **?** buttons beside the controls: hover for **What is this?**, then click for an explanation.

The editor currently previews and saves **Parallel** output, independently of the main app’s multiple-format checkboxes. Save Changes before previewing or rendering so your latest selection is included. See the [User Guide](Docs/USER_GUIDE.md) for the complete workflow and keyboard shortcuts. The main app’s **Help** menu opens its bundled guide.

### What setup does—and what you still do

| Component | Guided setup handles | User action still required |
|---|---|---|
| Developer tools and Python | Checks for them and opens the official installation steps/pages | Finish Apple's and Python's installers |
| Inject Z application | Builds the app and Photos library guard for a new installation | Test the resulting app; grant requested permissions |
| IW3 and shared output tools | Creates the Python environment and installs nunif/IW3 and image libraries | Download selected models through the guided IW3 test below |
| SHARP, if selected | Installs Apple SHARP and the Metal renderer, downloads the official checkpoint, and checks its checksum | Review model terms, confirm permitted use, and test a conversion |
| Photos Reframe | Explains working-library and permission setup | Have Reframe available, create the separate library, and approve permissions |

Dependencies and model weights are downloaded during setup; they are **not bundled in this repository**. Setup assistance is provided by START_HERE.command, not by an automatic repair wizard inside the conversion app.

## My basic use recommendations

IW3 uses depth maps, which is one of the more traditional methods used for conversion, where a depth map (grayscale version of the photo where the depth is approximated and represented with shades of white/gray/black, from foreground to background) is first generated internally, then a renderer uses that as a guide and shifts all the pixels of the image to varying degrees, to create an alternate view.  Depth map conversions can be great, but I haven't perfected them yet myself, and find the other two conversions methods far superior, so I don't use IW3 very much.

Apple SHARP uses gaussian splats, which means it estimates the depth environment and builds it into an actual 3D model with about 1.5 million little semi-translucent, colored dots floating in space.  With that model built, it can then move a virtual camera horizontally to take another picture of it from that new perspective, and generate your 3D view.  Apple SHARP, to me, seems to provide the best results, and is my first choice.  

Apple "Reframe" is a tool in the latest version of the Photos app, and it does something very similar, creating a virtual 3D model and letting you reframe the picture from a different perspective.  I'm not sure the technical difference between what it does, and what SHARP does, but they certainly both provide excellent results, and they clearly interpret the depth environment differently, and yield different results from each other.  So if I get a result with SHARP that I'm unhappy with, I try Reframe.  

Unfortunately Apple seems to have a harsh limit on how many times you can use Reframe in a day (it varies user to user, but for me it seems to be about 8 images within a 24 hour period).  There is no limit to how many times you can use SHARP and IW3.

As far as the depth strength setting, I always try the strongest depth setting first, and only lower it if it's too extreme.  The app also prevents window violations (on all 4 sides) by default, but you can disable that if you like.  And there's an option to add Edge Softening (blur) to a few pixels along the edge of foreground objects.  I don't use this if the photo is nice and high-res and crisp.  But if I'm converting a low-res photo, since the edges around things are already very soft and blurred, I use this feature to prevent the converted image from have too sharp an edge, because that ends up looking unnatural, and can cause a sleight cardboard cut-out effect.  So using the Edge Blur helps counter that.

## Acknowledgments

Inject Z would not have been possible without the work of the developers and researchers behind its conversion engines, AI models, and supporting software.

### Conversion engines and supporting technology

- **Apple’s machine-learning research teams**, for [SHARP](https://github.com/apple-aiml-research/ml-sharp) and [Depth Pro](https://github.com/apple-aiml-research/ml-depth-pro), and the **Apple Photos team** for Reframe.
- **nagadomi and the nunif/IW3 contributors**, for [IW3](https://github.com/nagadomi/nunif), its stereo-conversion methods, and its integration of multiple depth models.
- **Nando Metzger**, for [metal-gauss](https://github.com/nandometzger/metal-gauss), the Metal renderer used by Inject Z’s SHARP pipeline on Apple Silicon.
- The researchers and contributors behind **Depth Anything, Depth Anything V2, ZoeDepth, Distill Any Depth**, and the other models available through IW3.
- The developers and maintainers of **Python, PyTorch, NumPy, SciPy, Pillow, OpenCV, PyAV/FFmpeg**, and the other libraries that support these tools.

### Advice, generosity, and inspiration

- **Tony Lin**, for sharing his experience with stereo conversion, comparing results, and contributing suggestions about depth estimation and Gaussian splats.
- **Okano Izumi**, creator of **Splat Stereo**, for generously sharing his source code, granting permission to learn from and use his work, and pointing us toward helpful technical references.
- **Masuji Suto**, creator of **StereoPhoto Maker** and **MLSharp**, for his longstanding contributions to stereoscopic photography and the tools that have helped so many people create and improve stereo images.
- The members of **Let’s Convert 2D Images to 3D** and the wider stereo-photography community, for their examples, feedback, practical experience, and encouragement.
- **OpenAI and ChatGPT**, for the coding assistance used to develop and revise Inject Z.

These acknowledgments recognize both software used by Inject Z and people whose advice or work helped guide its development. They do not imply that every named project’s code is incorporated into Inject Z, or that its developers endorse this app.

Third-party software and AI models retain their own licenses and attribution requirements. See [Third-party components](Docs/THIRD_PARTY.md) for further information.

### Prepare IW3 models

After setup, open **~/InjectZ/MODEL_SETUP.txt** and double-click **~/InjectZ/DOWNLOAD_IW3_MODELS.command**. This opens upstream IW3 with internet access and the same model cache locations used by Inject Z.

Follow the guide to convert a disposable test photograph using the depth model and method you intend to use. Inject Z's initial settings use **DepthPro**, **forward_inpaint**, and **light_inpaint_v1**. First use downloads the needed depth, warp, and inpainting models. Review their respective terms before use.

Once that test succeeds, quit upstream IW3 and test Inject Z with matching settings. Repeat model preparation when choosing another model or method: Inject Z currently runs IW3 with Hugging Face offline mode and cannot download missing models itself.

Reframe needs the shared Python image libraries installed with IW3 support, but does not require IW3 depth-model downloads.

### Prepare Photos Reframe

Use **6. Set up Photos Reframe** in the setup menu for instructions:

1. Quit Photos, then hold **Option** while opening it.
2. Create a separate library named **InjectZ Working Library.photoslibrary** inside **~/InjectZ/Development**.
3. Do not make this working library your System Photo Library or enable iCloud syncing for it.
4. Grant Inject Z Accessibility and Photos automation permissions when requested.

The library guard blocks import unless it can verify that Photos is using the exact working library. Do not substitute your personal Photos library. Setup cannot supply Reframe if the feature is unavailable on your system.

### If setup fails

Keep the Terminal error and **~/InjectZ/SETUP_LOG.txt**. A partial installation is left in place for inspection; automatic resume is not yet implemented. Do not treat a failed installation as complete or delete files without checking what they contain.

This preview uses developer ad-hoc signing rather than a notarized public release. Permission approval may need to be repeated after rebuilding. Upstream changes can also cause installation incompatibilities. See [Guided setup details](SETUP_PREVIEW.md) for current limitations.

## Current release: 0.3.0

Released October 6, 2026, from a source snapshot collected from the working installation that day. The app now reports **0.3.0**, matching the GitHub release tag **v0.3.0**.

This release includes the integrated SHARP Manual Depth Editor, editor help and updated guide, custom SHARP depth strength, current sky/edge corrections, IW3 photo improvements and a Check for Updates menu. The app build and update checking have been confirmed on the developer’s Mac; fresh-machine setup remains unverified.

For technical details, see [developer setup](Docs/SETUP.md), [architecture](Docs/ARCHITECTURE.md), [development log](Docs/DEVELOPMENT_LOG.md), and [release publishing instructions](Docs/PUBLISH_RELEASE.md). Some older documentation describes earlier manual installation methods and predates the depth editor.

## Source layout

| Folder/file | Contents |
|---|---|
| START_HERE.command | First-time guided setup launcher |
| UPDATE_EXISTING.command | Updates an existing installation with backup and rollback |
| VERSION | Current release version |
| App | Swift AppKit GUI |
| SHARP | Prediction wrapper, stereo renderer, optional edge softening |
| SHARPDepthEditor | Manual editor interface, selection tools, depth adjustments and background repair |
| IW3 | Photo wrapper, settings/help definitions, PSD writer |
| Reframe | Photos scripts, library guard, stereo assembly and formats |
| Assets | App icon and header artwork |
| Setup | Guided setup scripts, build tool, dependency inventory and metadata |
| Docs | Setup, architecture, development history and third-party information |

## Licensing

No public reuse license has yet been selected for Inject Z's original code. Commercial reuse rights have not been granted. Contact the repository owner for permission to reuse or redistribute the original code; making it visible on GitHub does not itself grant a general open-source license.

Third-party engines and AI models retain their own licenses. Apple's SHARP model is restricted to defined non-commercial scientific research and academic development; free or hobby use is not automatically covered. Its agreement excludes commercial product development/use. Downloading it separately does not remove those restrictions.

This repository does not include AI model weights or Okano Izumi's private Splat Stereo source. See [third-party components](Docs/THIRD_PARTY.md) and the official upstream licenses before using external engines or models.
