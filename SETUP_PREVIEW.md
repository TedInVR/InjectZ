# Inject Z guided setup preview

Double-click **START_HERE.command** in the downloaded repository folder. The menu uses native Mac dialogs and does not require Python just to show prerequisite guidance.

It checks developer tools and Python, opens official prerequisite and license pages, offers a new installation, and explains Photos library/permission setup. It refuses to overwrite any existing `~/InjectZ` folder. The installation folder stays in the user's home; the preview does not require administrator access to place the app there.

For a new installation, install the macOS Python 3.13 and 3.12 universal2 packages from python.org (or equivalent Homebrew versions). Install Apple's Command Line Tools through the setup menu. Then select Install a NEW Inject Z. Installation creates separate environments, downloads official nunif/SHARP sources, installs dependencies, checks MPS and required APIs, resolves IW3 defaults, builds the app/library guard and creates a developer-signed app. Optional SHARP model download requires acknowledgement of the research terms and is checksum-verified.

## What still requires user action

- Python and Apple developer tools use their own installers.
- IW3's selected depth/warp/inpaint weights download through a guided test conversion in upstream IW3, launched using `DOWNLOAD_IW3_MODELS.command`. It shares Inject Z's cache paths. Repeat this for additional models.
- Reframe requires creating a separate Photos working library and granting permissions. Setup cannot silently grant macOS permissions or supply an unavailable Photos feature.
- Test real photos through the selected engines. Runtime checks alone do not certify conversion results.

## Preview limitations

This is **not a verified public installer or an upgrade tool**. The wizard and network installs have not been run on a fresh Mac. The script checks against current upstream source and records commits, but it does not yet use a tested revision lock. Upstream changes can cause compatibility or package installation failures. Interrupted/failed installs leave files and a log for inspection; automatic resume is not implemented. No existing files are deleted to retry.

The developer app uses ad-hoc signing, not Developer ID signing/notarization. Accessibility approval may need to be re-granted after rebuilding. No distribution signing certificate or private key is included. macOS may require explicitly allowing the downloaded command to open; do not disable system security globally.

The setup menu is separate from the conversion GUI. Missing-component guidance is not yet integrated into the main app. SHARP licensing restrictions remain in effect even if its checkpoint is downloaded from Apple rather than bundled.

## Add this preview to the existing repository

Upload only **START_HERE.command**, **SETUP_PREVIEW.md**, the contents of this package's **Setup** folder, and **Docs/DEVELOPMENT_LOG.md** to the matching repository locations. Do not replace your edited README or your installed app. The other source folders included here let this ZIP work independently for testing.

Suggested README addition: “A guided setup preview is available: double-click START_HERE.command. It checks prerequisites and assists with a new installation. Python/developer-tool installation, IW3 model preparation, and Photos permissions still involve user steps. Fresh-Mac validation is pending; this is not yet a tested one-click release.”
