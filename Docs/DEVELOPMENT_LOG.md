# InjectZ development log

Append new entries for later changes. This initial entry records the repository snapshot, not a new app release.

## September 29, 2026 — initial source repository snapshot

- Collected 13 source files from the user's current Mac: R14 Swift GUI; Reframe automation, guard, assembly and R15 finish helper; SHARP wrappers; IW3 layered PSD helper.
- Compared the 11 overlapping source files against the earlier exchange snapshot; they matched byte for byte.
- Added the available icon artwork, source layout, architecture notes, and third-party attribution. Excluded installed dependencies, model checkpoints, app bundle, photos, outputs, logs, and signing materials.
- No source modifications to conversion behavior and no macOS end-to-end test in this repository preparation step.
- Remaining setup work: document a reproducible build, pin external dependencies, verify packaging and code signing on the owner's Mac, and test all three engines and output formats.

## October 4, 2026 — current installed source export and GitHub preparation

- Updated the repository from the owner’s actual 07:32 source export. GUI bundle metadata remains 0.2.2; source snapshot version is 2026.10.04.
- Included SHARP scene far-plane fix and optional edge softening, IW3 photo wrapper/settings/help/defaults, Reframe helper source, built icon and header asset.
- Removed an obsolete BeforeR15 backup. Preserved exported active source bytes unchanged.
- Owner confirmed the SHARP sky repair and IW3 default/window fixes; edge softening installed source is present but broad quality validation remains pending.
- Added setup requirements, captured dependency inventories, development build staging, third-party terms and fresh-Mac release checklist. No AI models/runtimes/private signing files or personal photographs are included.
- Python sources syntax-checked in preparation. Swift/Metal/AppKit execution requires macOS and was not tested here. Dependency inventories are not lockfiles; upstream commit/provenance capture remains necessary for reproducible installation.
- The repository preparation does not claim a ready-to-install app, and no GitHub publication has occurred automatically.

# October 4, 2026 — guided first-install preview

- Added native AppleScript-dialog setup menu launched through START_HERE.command.
- Added prerequisite detection and official links for Python/developer tools, model terms and Photos permissions.
- Added new-install-only worker; atomically refuses existing installation roots. Existing owner installation is preserved.
- Builds separate Python environments, installs upstream sources/dependencies, checks MPS/API/window-guard compatibility, resolves defaults and records upstream commits. No models are bundled.
- Optional SHARP official checkpoint download uses a known SHA-256 before installation. IW3 model preparation remains an upstream guided test with shared cache paths.
- Build is ad-hoc developer signed. Fresh-Mac end-to-end validation, dependency locks, resumability, public distribution signing, and integration of setup prompts into the conversion GUI remain open.
- Tested shell syntax, source syntax, existing-install refusal and checkpoint checksum acceptance/rejection in Linux. Mac dialogs, network installation and conversion tests are pending.
