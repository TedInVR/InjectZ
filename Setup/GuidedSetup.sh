#!/bin/bash
set -euo pipefail
repo="$1"
say() {
 /usr/bin/osascript - "$1" <<'APPLESCRIPT'
on run argv
 display dialog item 1 of argv with title "Inject Z Guided Setup" buttons {"OK"} default button "OK"
end run
APPLESCRIPT
}
find_python() {
 local version="$1" candidate
 for candidate in "/opt/homebrew/bin/python$version" "/usr/local/bin/python$version" "/Library/Frameworks/Python.framework/Versions/$version/bin/python$version"; do
  if [[ -x "$candidate" ]] && "$candidate" -c 'import sys; assert sys.platform == "darwin"' >/dev/null 2>&1; then printf '%s' "$candidate"; return; fi
 done
 return 1
}
say 'This is a guided setup preview for Apple Silicon Macs. It can prepare a NEW installation, but it will never overwrite an existing ~/InjectZ folder. It downloads external software from official projects. Fresh-Mac testing is still pending. You can quit at any time before installation.' >/dev/null
while true; do
 choice=$(/usr/bin/osascript <<'APPLESCRIPT'
set selected to choose from list {"1. Check prerequisites", "2. Get Apple developer tools", "3. Get Python 3.13 and 3.12", "4. Review engine and model terms", "5. Install a NEW Inject Z", "6. Set up Photos Reframe", "7. Open installation folder", "Quit"} with title "Inject Z Guided Setup" with prompt "Choose a step. Start with Check prerequisites." default items {"1. Check prerequisites"}
if selected is false then return "Quit"
return item 1 of selected
APPLESCRIPT
 )
 case "$choice" in
 '1.'*)
  report="macOS: $(/usr/bin/sw_vers -productVersion)
Architecture: $(/usr/bin/uname -m)"
  if /usr/bin/xcrun --find swiftc >/dev/null 2>&1; then report="$report
Apple developer tools: found"; else report="$report
Apple developer tools: MISSING — choose step 2"; fi
  for v in 3.13 3.12; do
   if find_python "$v" >/dev/null; then report="$report
Python $v: found"; else report="$report
Python $v: MISSING — choose step 3"; fi
  done
  if [[ -e "$HOME/InjectZ" ]]; then report="$report
Existing ~/InjectZ folder detected: automatic installation is blocked to preserve it."; else report="$report
No existing installation folder: new setup is available."; fi
  say "$report" >/dev/null ;;
 '2.'*)
  say 'Apple developer tools provide the Swift compiler and Metal build tools. An Apple installation prompt may appear next. Finish it, then return here and check prerequisites again.' >/dev/null
  /usr/bin/xcode-select --install || true ;;
 '3.'*)
  say 'The official Python download page will open. Install the macOS universal2 installer for Python 3.13, then Python 3.12. These are separate environments for SHARP and IW3. Return here and check prerequisites again. Homebrew installations of these versions are also recognized.' >/dev/null
  /usr/bin/open 'https://www.python.org/downloads/macos/' ;;
 '4.'*)
  say 'SHARP model use is restricted to defined non-commercial scientific research and academic development. Free or hobby use is not automatically covered. Review the agreement before selecting SHARP. IW3 depth and inpainting models also have separate terms. This setup does not grant commercial rights.' >/dev/null
  /usr/bin/open 'https://github.com/apple-aiml-research/ml-sharp/blob/main/LICENSE_MODEL'
  /usr/bin/open 'https://github.com/nagadomi/nunif/blob/master/iw3/README.md' ;;
 '5.'*)
  if [[ -e "$HOME/InjectZ" ]]; then say 'Your existing ~/InjectZ folder will not be changed. This preview only installs on a Mac without that folder. You can use the other setup guidance steps safely.' >/dev/null; continue; fi
  if [[ "$(/usr/bin/uname -m)" != arm64 ]]; then say 'This installer requires native Apple Silicon execution. Intel Macs and Terminal running through Rosetta are not supported.' >/dev/null; continue; fi
  if ! /usr/bin/xcrun --find swiftc >/dev/null 2>&1; then say 'Install Apple developer tools using step 2 first.' >/dev/null; continue; fi
  if ! pysharp=$(find_python 3.13) || ! pyiw3=$(find_python 3.12); then say 'Install both Python versions using step 3 first.' >/dev/null; continue; fi
  mode=$(/usr/bin/osascript <<'APPLESCRIPT'
set selected to choose from list {"IW3 and Reframe support", "IW3, Reframe support, and SHARP research setup"} with title "Choose components" with prompt "IW3 also supplies image libraries used by Reframe. Selected AI models will download separately. SHARP requires its research license." default items {"IW3 and Reframe support"}
if selected is false then return "Cancel"
return item 1 of selected
APPLESCRIPT
  )
  [[ "$mode" != Cancel ]] || continue
  sharp=no
  if [[ "$mode" == *SHARP* ]]; then
   answer=$(/usr/bin/osascript <<'APPLESCRIPT'
display dialog "Only continue if you have read Apple's SHARP model agreement and your intended use is permitted by it. The model is research-restricted; this is not permission to sell a SHARP-powered product." with title "SHARP model terms" buttons {"Cancel", "Open terms", "My use complies"} default button "Open terms"
return button returned of result
APPLESCRIPT
   ) || continue
   if [[ "$answer" == 'Open terms' ]]; then /usr/bin/open 'https://github.com/apple-aiml-research/ml-sharp/blob/main/LICENSE_MODEL'; continue; fi
   [[ "$answer" == 'My use complies' ]] || continue
   sharp=yes
  fi
  say 'Installation will now run in Terminal. Downloads and compilation can take a while and require several gigabytes. Keep this window open. You will choose and download IW3 models through the upstream IW3 interface afterward. A failure is recorded in a setup log and will not be reported as success.' >/dev/null
  if "$pysharp" "$repo/Setup/install_new.py" --repo "$repo" --iw3-python "$pyiw3" --sharp "$sharp"; then
   say 'Source and runtime installation completed. Next: open the IW3 model setup guide in the installation folder and run DOWNLOAD_IW3_MODELS.command. For Reframe, use step 6. A successful installation check is not yet proof that every conversion engine works; test one photo before relying on this preview.' >/dev/null
  else
   say 'Setup stopped. The Terminal window contains the error. Any partially prepared ~/InjectZ folder was left in place for inspection; it has not been opened as a finished app. Save the setup log and ask for help before deleting anything.' >/dev/null
  fi ;;
 '6.'*)
  say 'Reframe needs a compatible Photos version with Reframe available. Create a separate working library: quit Photos, hold Option while opening Photos, click Create New, and save InjectZ Working Library.photoslibrary inside your home folder > InjectZ > Development. Do not make it your System Photo Library or enable iCloud for it. Do not use your personal library. Grant Inject Z Accessibility and Photos automation permissions when requested. Availability is checked by trying the feature; an OS number alone is not proof.' >/dev/null
  /usr/bin/open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility' ;;
 '7.'*) [[ ! -d "$HOME/InjectZ" ]] || /usr/bin/open "$HOME/InjectZ" ;;
 *) exit 0 ;;
 esac
done
