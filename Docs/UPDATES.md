# Inject Z app updates — 0.3.1 source candidate

## One-time activation

Quit Inject Z and close its conversion/editor workers. Download the repository
with **Code → Download ZIP**, extract it, and run
**Setup/ENABLE_APP_UPDATES.command**. Keep Terminal open until completion.
The command finds an existing Python environment, verifies the downloaded updater,
builds the new app locally, preserves the existing signing identity, installs
the program-only update and opens Inject Z. It does not reinstall models or
Python environments. It requires the already-installed Apple developer tools.

The currently published 0.3.0 release only opens a release-download page; it
cannot acquire this feature without this one activation. The activation script
can be kept as a recovery/update command. Downloaded source folders can be
deleted after installation. Keep your installed `~/InjectZ` folder.

## Daily use

- **Inject Z → Check for Updates…** checks the source-update channel. Download
  and Prepare runs off the UI thread; Install and Relaunch is a separate action.
- **Automatically Update While Closed** enables/disables the per-user background
  agent. It is enabled by default, checks about every 15 minutes while logged in,
  and never deliberately closes the app or its workers. A Mac that is asleep or
  offline checks later. Automatic installation leaves the app closed.
- Opening Inject Z during installation waits and relaunches the new binary.
  Conversions and open editor sessions block unattended installation.

## What is retained

Models, Runtime and IW3 Python environments, nunif, cached reconstructions, local
IW3Settings.json, preferences, custom audio and saved editor sessions are not
update payloads. The installed icon and bundle identifier are retained. Source
scripts and known bundled help/audio resources are updated. A backup of program
files and the previous app is written under `~/InjectZ/Backups/Before-<version>-…`.
Failed code installation restores the previous files and app.

Downloads are pinned to one GitHub commit. Managed payloads are checked against
the manifest, then the Swift app and Reframe guard are compiled locally. The
replacement must pass codesign verification before the installed app changes.
This is a source-update channel, not a notarized binary feed. A certificate-signed
installation requires its original private key in the local Keychain; that key
is never uploaded. The updater stops if the matching signing identity is absent.
Ad-hoc builds remain ad hoc; macOS may require renewed permissions. Signing and
Keychain policy may require an OS prompt on an individual Mac.

## Recovery and validation

Diagnostics: `~/InjectZ/Updates/update.log`; scheduled job output:
`~/InjectZ/Updates/automatic.log`. The user agent is
`~/Library/LaunchAgents/com.injectz.app.dev.automaticupdates.plist`.
Turn automatic updates off before uninstalling the app. If preparation fails,
the working app is unchanged; review the log and report the error without sharing
signing keys or private personal data. A backup can be restored after quitting
the app if necessary.

Automated tests cover archive paths/checksums, code-only mapping, data/icon
preservation, failed-copy rollback, worker blocking and signing command selection.
**The new Swift interface, native compilation/signing and live background
registration have not been verified on macOS from this development environment.**
This is published as a source-update candidate, not as a newly tested stable
release. A fresh-machine install remains separately unverified.
