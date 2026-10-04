# Inject Z

Inject Z converts ordinary 2D photographs into stereoscopic 3D images on an Apple Silicon Mac. Choose Apple SHARP, IW3, or Apple Photos Reframe, then generate Parallel, Crossview, and anaglyph images—including Dubois. You can select multiple output formats for a single conversion.

Final images are saved beside the source photograph and displayed using Finder Quick Look. Stereo-window protection is enabled by default, with an option to allow window violations.

Inject Z was vibe-coded with ChatGPT. In plain English, I described what I wanted the app to do, and ChatGPT helped write and revise the code. Development and testing are ongoing.

## Conversion engines

- **Apple SHARP:** Gaussian splat reconstruction with adjustable depth and optional softening around depth edges. Includes a correction for distant-sky clipping in the Metal renderer.
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

## Installation: guided setup preview

**A guided setup tool is included, but it is still a preview—not a verified one-click release.** Its menu, prerequisite checks, and protection of an existing installation have been tested on the developer's Mac. The complete download, build, and installation sequence still needs testing on a fresh Mac.

1. On this repository's main page, click **Code → Download ZIP** and unzip the download. Download the whole repository so the setup tool has all its source folders.
2. Open the unzipped folder and double-click **START_HERE.command**. This opens Terminal and a menu of normal Mac dialogs. Keep Terminal open while setup is running.
3. Choose **1. Check prerequisites**.
4. If anything is missing, use **2. Get Apple developer tools** and **3. Get Python 3.13 and 3.12**. Finish the official installers, then run the prerequisite check again.
5. Choose **4. Review engine and model terms** before installing models.
6. Choose **5. Install a NEW Inject Z**. Select IW3/Reframe support, with optional SHARP research setup if your intended use complies with Apple's model agreement.
7. After installation, complete the engine-specific steps below and test one photograph through each engine you intend to use.

The installation location is **~/InjectZ**: an InjectZ folder inside your home folder. The app is **~/InjectZ/InjectZ.app**. This preview does not install into the main Applications folder.

**An existing ~/InjectZ folder blocks automatic installation.** The preview will not replace your working app or upgrade an existing installation. Do not delete an existing folder merely to get past this check.

If macOS blocks the downloaded command, use the normal macOS approval process for a file you trust. Do not disable system security globally.

### What setup does—and what you still do

| Component | Guided setup handles | User action still required |
|---|---|---|
| Developer tools and Python | Checks for them and opens the official installation steps/pages | Finish Apple's and Python's installers |
| Inject Z application | Builds the app and Photos library guard for a new installation | Test the resulting app; grant requested permissions |
| IW3 and shared output tools | Creates the Python environment and installs nunif/IW3 and image libraries | Download selected models through the guided IW3 test below |
| SHARP, if selected | Installs Apple SHARP and the Metal renderer, downloads the official checkpoint, and checks its checksum | Review model terms, confirm permitted use, and test a conversion |
| Photos Reframe | Explains working-library and permission setup | Have Reframe available, create the separate library, and approve permissions |

Dependencies and model weights are downloaded during setup; they are **not bundled in this repository**. Setup assistance is provided by START_HERE.command, not by an automatic repair wizard inside the conversion app.

### Prepare IW3 models

After setup, open **~/InjectZ/MODEL_SETUP.txt** and double-click **~/InjectZ/DOWNLOAD_IW3_MODELS.command**. This opens upstream IW3 with internet access and the same model cache locations used by Inject Z.

Follow the guide to convert a disposable test photograph using the depth model and method you intend to use. Inject Z's initial settings use **DepthPro**, **mlbw_l2_inpaint**, and **light_inpaint_v1**. First use downloads the needed depth, warp, and inpainting models. Review their respective terms before use.

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

## Current source snapshot: 2026.10.04

The conversion source was collected from the installed app on October 4, 2026. The installed app still reports bundle version **0.2.2**, which predates several updates; the dated snapshot identifies this source rather than a newly tested binary release.

Recent changes include the SHARP sky correction, optional depth-edge softening (off by default), IW3 strengths 1–6, photo-specific settings with help and resolved defaults, and window protection using all four image borders. The guided setup preview was added afterward. See the [change history](CHANGELOG.md) and [development log](Docs/DEVELOPMENT_LOG.md).

For technical details, see [developer setup](Docs/SETUP.md), [architecture](Docs/ARCHITECTURE.md), and the [release checklist](Docs/RELEASE_CHECKLIST.md). Some earlier developer setup notes describe the manual process; START_HERE.command and SETUP_PREVIEW.md describe the newer guided preview.

## Source layout

| Folder/file | Contents |
|---|---|
| START_HERE.command | Guided setup launcher |
| App | Swift AppKit GUI |
| SHARP | Prediction wrapper, stereo renderer, optional edge softening |
| IW3 | Photo wrapper, settings/help definitions, PSD writer |
| Reframe | Photos scripts, library guard, stereo assembly and formats |
| Assets | App icon and header artwork |
| Setup | Guided setup scripts, build tool, dependency inventory and metadata |
| Docs | Setup, architecture, development history and third-party information |

## Licensing

No public reuse license has yet been selected for Inject Z's original code. Commercial reuse rights have not been granted. Contact the repository owner for permission to reuse or redistribute the original code; making it visible on GitHub does not itself grant a general open-source license.

Third-party engines and AI models retain their own licenses. Apple's SHARP model is restricted to defined non-commercial scientific research and academic development; free or hobby use is not automatically covered. Its agreement excludes commercial product development/use. Downloading it separately does not remove those restrictions.

This repository does not include AI model weights or Okano Izumi's private Splat Stereo source. See [third-party components](Docs/THIRD_PARTY.md) and the official upstream licenses before using external engines or models.
