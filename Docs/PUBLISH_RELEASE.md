# Publishing Inject Z 0.3.0

First install this candidate on the working Mac and confirm About reports 0.3.0, all three conversions still work, the editor/help open, and Check for Updates reports no release (before publishing). macOS compilation cannot be verified on the development Linux host. A clean new-user installation also remains to be tested.

Then update the repository with this package's contents at the repository root. Replace existing source files with the corresponding new files; do not upload Python caches, build folders, models, photos or signing keys.

On GitHub's repository page, choose Releases → Draft a new release. Create tag **v0.3.0** targeting the commit containing these sources. Title: **Inject Z 0.3.0**. Attach **InjectZ-0.3.0.zip**. Use the notes below. Until full clean-install testing is complete, describe it as a source-based developer release. To allow the current stable-release checker to see it, it must be a published non-prerelease release; drafts and prereleases are excluded by GitHub's latest-release endpoint. Do not publish a candidate as stable until the working-install checks pass.

Release notes:

- Integrated SHARP Manual Depth Editor with named selections, gradients, depth views, previews and per-control question-mark help.
- Custom SHARP depth, updated user guide, current sky/edge fixes and IW3 improvements.
- Added Check for Updates, which opens newer GitHub releases; automatic installation is not included.
- Existing users: run UPDATE_EXISTING.command after quitting Inject Z. New users: START_HERE.command. Source-based installation needs development tools and separately downloaded dependencies/models.

For future versions, increase VERSION, both plist version values in BUILD_SOURCE.command and UPDATE_EXISTING.command, the update checker User-Agent/fallback version, source update backup/log labels, archive filename and matching GitHub tag. Never change the app's bundle identifier or established signing identity as part of ordinary updates.

A later automatic updater needs authenticated signed update archives, a consistent public signing strategy and migration of external scripts. This source-based release checker does not execute network-downloaded code.
