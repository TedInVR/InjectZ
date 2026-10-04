# Architecture and current boundaries

The AppKit GUI in `App/InjectZ.swift` selects an engine and one or more output formats. Final deliverables go next to the input photo. The installed layout is rooted at `~/InjectZ`.

## Engines

SHARP uses `Runtime/python/bin/python3`, Apple SHARP and `Models/SHARP/sharp_2572gikvuh.pt`. Prediction produces a cached PLY; `injectz_sharp_render.py` renders stereo through metal-gauss. `EdgeSoftener.py` optionally renders a per-eye inverse-depth guide and softens a narrow band around sufficiently large disparity discontinuities. Texture edges in flat-depth regions do not trigger the mask. This is not semantic face/text protection; noisy geometry can produce unwanted boundaries.

The sky repair uses `max(100, maxPositiveFiniteZ * 1.1 + 1)` for the render far plane. This matches the current identity-rotation cameras with horizontal translation. Future rotated cameras require camera-space depth bounds. Testing on a failing sky image found identical cached/fresh PLYs and repeat renders; geometry beyond 100 was clipped. Increasing the far plane restored the sky without replacing SHARP or the renderer.

IW3 uses `Development/IW3/python/bin/python` and a nunif checkout at `Development/IW3/nunif`. `photo_iw3.py` patches a guarded upstream divergence hook to adjust convergence based on the mapped depth at all four borders. It relies on a particular upstream source structure and must be checked when nunif changes. The GUI sets `HF_HUB_OFFLINE=1`: model assets must be downloaded before normal conversions. Help/default files are `IW3Settings.json` and `IW3SettingHelp.json` at the installation root.

Reframe uses the separately compiled `Development/Reframe/LibraryGuard`. The guard verifies that Photos has open files within the exact working library before importing. A dedicated library must be created at `Development/InjectZ Working Library.photoslibrary`. The main automation is in the Swift GUI; additional scripts/controllers are retained for development and recovery. Exported eye dimensions are normalized by `FinishSingleRight.py`, then window protection and stereo formatting are applied. Completed-album deletion is best effort and is not proof of permanent deletion of every imported media file.

Shared formatting is implemented in `Development/Reframe/SharedStereoFormats.py`, executed using the IW3 Python environment, including for SHARP outputs. Reframe therefore also needs the image-processing environment, even when IW3 conversion is not used.

## Known issues / validation gaps

- SHARP's PLY cache is keyed by source basename, so same-named photos or modified input content can reuse stale reconstruction. CLI `--rebuild` forces reconstruction. This is separate from the confirmed far-plane sky bug.
- The engine removes a Metal extension lock without checking its owner; do not run multiple SHARP conversions concurrently until this is hardened.
- Reframe pan limits and processing failures vary by image/service state; a daily quota has not been independently established.
- Edge softening can create halos at excessive settings; two extra guide renders add overhead when enabled.
- Window protection depends on estimated geometry/depth, which can be wrong. It is not a semantic guarantee for all images.
- A clean-machine installation, supported OS matrix, stable dependency revision lock and public signing/notarization are still outstanding.
