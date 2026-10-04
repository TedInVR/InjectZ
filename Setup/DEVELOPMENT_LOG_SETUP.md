# October 4, 2026 — guided first-install preview

- Added native AppleScript-dialog setup menu launched through START_HERE.command.
- Added prerequisite detection and official links for Python/developer tools, model terms and Photos permissions.
- Added new-install-only worker; atomically refuses existing installation roots. Existing owner installation is preserved.
- Builds separate Python environments, installs upstream sources/dependencies, checks MPS/API/window-guard compatibility, resolves defaults and records upstream commits. No models are bundled.
- Optional SHARP official checkpoint download uses a known SHA-256 before installation. IW3 model preparation remains an upstream guided test with shared cache paths.
- Build is ad-hoc developer signed. Fresh-Mac end-to-end validation, dependency locks, resumability, public distribution signing, and integration of setup prompts into the conversion GUI remain open.
- Tested shell syntax, source syntax, existing-install refusal and checkpoint checksum acceptance/rejection in Linux. Mac dialogs, network installation and conversion tests are pending.
