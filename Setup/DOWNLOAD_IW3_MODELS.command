#!/bin/bash
set -euo pipefail
root="$HOME/InjectZ/Development/IW3"
[[ -x "$root/python/bin/python" && -d "$root/nunif" ]] || { echo 'IW3 environment missing. Run guided setup first.'; exit 1; }
mkdir -p "$root/Cache/huggingface" "$root/Cache/torch" "$root/ModelSetupOutput"
export HF_HOME="$root/Cache/huggingface"
export TORCH_HOME="$root/Cache/torch"
export HF_HUB_OFFLINE=0
cd "$root/nunif"
echo 'Use a disposable test photo to download your chosen models and test IW3.'
echo 'Read ~/InjectZ/MODEL_SETUP.txt for the settings needed by Inject Z.'
exec "$root/python/bin/python" -m iw3.gui
