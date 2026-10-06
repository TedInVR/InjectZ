
## 2026-10-03 — IW3 settings expansion
- Restore IW3 strengths 1–6 and retain default 5.
- Remove repair/version suffix from main window; display Inject Z.
- Add scrolling controls generated from installed IW3 argparse source.
- Keep Inject Z's routing, output formats and normal stereo assembly authoritative.
- Patch current installed source; preserve bundle identity and original certificate.
- Do not replace Reframe/SHARP helpers or cached reconstructions.
- Linux checks passed; macOS compile/UI/conversion verification pending.

## 2026-10-03 — Photo-only advanced IW3 settings follow-up
- Filter the generated additional controls through an explicit photo allowlist.
- Hide video encoding, temporal processing, extraction and scene cache controls.
- Hide deprecated/deleted options; retain shared photo processing controls.
- Change IW3Settings.json only; preserve executable, bundle identity and signature.
- Back up previous schema and append this entry to the installed development log.
- Reviewed against official iw3/utils.py create_parser; extraction and JSON compatibility checked.
- Future unknown options require photo-applicability review before exposure.

## 2026-10-03 — In-app IW3 photo setting explanations
- Add What is this? buttons to all 30 photo settings plus 5 original controls.
- Load plain-language descriptions from ~/InjectZ/IW3SettingHelp.json.
- Explain choices, numeric units/examples, dependencies and practical tradeoffs.
- Use NSAlert sheets attached to Advanced IW3 Settings; retain current values.
- Narrow scrolling labels/controls to accommodate 120-point help buttons.
- Patch current source, stage compile and signature verification, preserve original
  certificate/bundle ID, back up app/source/help, roll back failed installation.
- Leave IW3Settings.json, Reframe/SHARP helpers and caches unchanged.
- Verified schema coverage and patch on latest generated source; macOS build/UI pending.
- References: official nagadomi/nunif iw3/utils.py create_parser and iw3/README.md.

## 2026-10-03 — Visible IW3 defaults and four-edge convergence guard
- Read actual argparse defaults from installed iw3.utils.create_parser.
- Show concrete default labels while preserving omission semantics for defaults;
  display Auto Crop None as Off and app inpainting override light_inpaint_v1.
- Use popup item tags for boolean action handling; leave numeric fields blank
  with explicit default placeholders to avoid freezing conditional defaults.
- New photo_iw3.py imports IW3 from its working directory; changes only this
  process's apply_divergence function after depth remapping, before synthesis.
- Set convergence >= maximum mapped border-strip depth plus .002. Inspect left,
  right, top and bottom; width covers potential shifts. Preserve larger existing
  convergence; allow nearer isolated interior depth to remain forward.
- Check mapped tensors for finite values; refuse incompatible IW3 hook layout.
- Allow Window Violations bypasses guard; depth-map export remains ordinary.
- Standalone IW3, Reframe, SHARP, source photo, caches and model weights unchanged.
- Preserve signing identity; backup app/source/schema/wrapper and rollback failed writes.
- Synthetic numeric tests passed using NumPy adapter; real torch compatibility and
  depth tests run pre-install on Mac. Native compilation/UI/real-photo test pending.
- Limit: guard follows estimated depth; no semantic-object guarantee with wrong
  depth or synth artifacts. Post-synthesis changes can affect screen placement.
- References: official iw3/utils.py, backward_warp.py, cli.py and README.md.

## 2026-10-03 — SHARP sky diagnostic sequence and confirmed renderer correction
- First user report DesertMuseum-Circa1988 3678x2575:
  - Cached and fresh PLY SHA256 identical; repeated zero and stereo render outputs
    identical. No stale reconstruction or repeated-render nondeterminism observed.
  - Sky gaps take white/black background color. Investigate rendered coverage.
- Distance follow-up captured installed Metal API, code and actual geometry:
  - Default far=100, total splats 1,179,648; excluded at/beyond far: 308,549.
  - Median Z 8.594; 90th percentile 133.635; max Z 140.31808471679688.
  - Test far=155.34989318847659 restored sky visually at zero and stereo .06.
  - Same PLY, focal geometry, camera, background and window settings as controls.
- Root cause confirmed for this image: finite far-plane clipping of sky geometry.
  Stale basename cache is a separate confirmed weakness, not this run's cause.
- Patch the CURRENT installed helper via guarded anchors, not an older full app.
- Local rendering adapter forwards same geometry/cameras/SH/background/backend to
  metal_gauss.api.render, explicitly passing scene-aware far for both eye renders.
- Formula max(100,max finite positive model Z*1.1+1); current eye camera rotations
  identity and translations horizontal. Future rotated cameras require camera-Z.
- Reject absent/invalid positive depths or excessive cutoff >1e25.
- Installer verifies far keyword support and Python syntax before replacing helper;
  preserves a backup, aborts if app/SHARP task running and appends this log.
- App executable/signing identity/cert, icon, permissions, engine/cache/checkpoint,
  Reframe, IW3, output naming/selection, depth strength and window handling intact.
- Tests: user GPU controls succeeded; source patch plus two-eye forwarded-parameter
  tests passed. Regular installed GUI conversion and other failing images pending.
- Source report SHA256 cached PLY:
  86172fede0d312bf48efa0cdab2f4b2663a4c37d367c8e62791b1a3bf8b14a0b.
- Report folders in this workspace: sky_report_review and distance_report_review;
  user Mac first diagnostic Desktop/InjectZ-SHARP-Sky-20261003-095703.
- Next: user install, retry Desert Museum and multiple previously blotchy sources.
  No renderer replacement with Spark needed for this demonstrated clipping issue.

## 2026-10-03 — Optional SHARP silhouette/depth-boundary softening
- User reports excessively crisp shifted outlines despite good internal body depth;
  manual narrow blur improves perceived naturalness. Implement SHARP first.
- Add SHARP Edge Softening panel, off-by-default checkbox, radius .5–6 pixels,
  strength0–100%, defaults2px/35%; current-session controls and live value labels.
- Show SHARP button only for SHARP; shrink keepEyes field width to avoid overlap.
- Forward three options GUI -> installed engine -> renderer. Off path unchanged.
- New ~/InjectZ/EdgeSoftener.py renders explicit inverse-Z colors through the same
  splat geometry, per-eye pose/intrinsics and scene-aware far plane. Normalize by
  alpha then derive pixel disparity = fx*baseline/Z; require reliable alpha>.85.
- Seed adjacent horizontal/vertical disparity jumps>=1.5px; compact-support distance
  band radius+.5. Blend per-eye Gaussian RGB using strength*band weight after RGB
  quantization/write_png, before SBS assembly. Save softened separate eye PNGs too.
- Color/texture edges alone never seed masks; face interiors can stay untouched
  where depth is continuous. No semantic guarantee for faces/text if depth is wrong.
- Zero baseline/strength/seed gives no pixel changes. Outside compact band exact.
- Radius widens both Gaussian and blending band. Strength controls blend amount.
- Adds two optional explicit-color geometry passes; projection uses reference torch
  covariance path with Metal rasterization. May cost time/memory; no model reload.
- Preserve sky fix, window protection, naming, formats, non-overwrite outputs and
  certificate/root F676FD4BC9E1160E9F1E0C29FF8F3F0D06F4C592, bundle com.injectz.app.dev.
- Installer stages source patch/Swift compilation/Python+API checks before writes;
  backs up app, Swift, engine, renderer/helper and rolls back copy/signature failures.
- Tests passed: depth-only masks; eye-displacement mask differences; weak separation
  ignored; unchanged face-like internal color edge; exact outside-band pixels;
  zero-strength/flat-depth identity; radius/strength monotonic support/effect.
- Patch tested after chaining today's expanded IW3, help, defaults/window changes.
- Actual MPS/Metal depth pass and Cocoa GUI require user Mac testing; not verified here.
- Current fixed-rotation horizontal cameras permit model Z for depth. Rotated-camera
  extensions must change guide to camera Z. Smooth/incorrect depth and fine hair
  can be missed/affected; calibrate on real user photo before further algorithm work.
- IW3/Reframe edge-softening not added in this revision. Standalone movie untouched.

## 2026-10-05 — Additional SHARP and Reframe depth presets
- Added Extra Strong 0.080, Maximum 0.100, Extreme 0.120; initial selection remains Very Strong 0.060.
- Updated both GUI lists, SHARP token mapping, engine presets, output lookup, and Reframe numerical selection. IW3 strengths untouched.
- Retained Reframe actual-pan readback and image-dependent limiting warning.
- Installer patches installed source with exact-match guards; stages compilation/signing using original certificate before installation; backs up and rolls back affected files.
- Renderer, sky far-plane correction, stereo-window guards and optional edge softening unchanged.
- Verified patch against October 4 actual source, Python parsing and shell syntax locally; macOS Swift compilation and end-to-end conversions require user's Mac.
- Larger baseline can expose more missing-background artifacts; it does not improve the predicted geometry or recover missing depth.

## 2026-10-05 — About credits and bundled Help
- Standard About panel retains icon/version, adds Developed by Ted Witten, Vibe coded with ChatGPT, and clickable GitHub link.
- App menu Help opens bundled offline HTML guide through NSWorkspace; reports missing guide/open failure.
- Guide updated with higher-depth options, marked as requiring separate depth update.
- Installer patches installed source rather than replacing it; preserves prior depth changes and original signing identity, bundles guide before signing, backs up and rolls back app/source.
- Patch exercised against both October 4 source and higher-depth-patched source; Python/shell syntax checked. Swift compilation and interactive panel/link verification require macOS.

- Corrected developer surname to Whitten; patch also accepts the previously installed About/Help update and corrects it without duplicating menus.

## 2026-10-05 — Standard window closing and consistent display name
- Added File > Close Window, Command-W, nil-target NSWindow.performClose responder-chain routing for the active closable window, including standard About and NSPanels.
- Centered About credits including GitHub link; developer name Ted Whitten.
- Display name/menu/quit use Inject Z; preserve bundle identifier, executable filename, paths, output naming and signing certificate.
- Main window retained after closing; Dock reopen re-shows it. Closing a window does not cancel conversion.
- Installer also includes prior About/Help feature if not yet installed. Existing depth settings preserved by patching installed source.
- Source patches checked against original source and both prior About revisions with higher-depth settings; shell syntax passed. Runtime Command-W/panel/layout testing requires macOS.

## 2026-10-05 — Custom SHARP camera baseline
- Added SHARP-only Custom depth menu/dialog; finite range 0.001–10.000 rounded to 0.001 to match renderer output filenames. Default stays Very Strong 0.060.
- Pass custom baseline using existing engine --baseline override; capture numeric depth for completion lookup/shared output names.
- Preserve higher presets and include them if missing; remove custom menu when switching to Reframe/IW3 to prevent index crashes. Custom value remembered during app session, not across launches.
- Patch installed source, preserve menus/credits/signing certificate/rendering fixes; back up and roll back app/Swift/engine.
- Source patch tested with original October 4 and subsequent window-menu/higher-depth source; shell and Python syntax checked. Actual rendering/Swift compilation requires Mac.
- Wide-baseline experiments expose unseen geometry and reconstruction errors. No claim of quality or real-world distance accuracy.

- Compile repair R2: NSPopUpButton removal uses removeItem(withTitle:) rather than an NSMenuItem argument. Prior installer failed during staged compilation before changing installed files. macOS full compilation still occurs on target Mac.

## 2026-10-05 — Guided SHARP depth experimental editor
- Standalone localhost token-protected browser UI, original photo selected through native Mac dialog. Existing app files and caches untouched.
- Source EXIF normalized to session PNG; selection thumbnail and fresh SHARP model share same orientation. First render predicts fresh session model to avoid basename cache collisions.
- Box + foreground/background seeds use OpenCV GrabCut in an existing environment. This is color segmentation, not semantic object recognition. No new dependencies/model downloaded; missing OpenCV fails with explanation.
- Region masks project onto splats through installed renderer intrinsics. Modify inverse depth with region-relative additive offset; scale xyz along original rays and Gaussian scales together. Approximate original composition retained; orientation/covariance complications, occluded layer selection and artifacts remain.
- Sequential masks derived from original projection; undo/reset recompute from pristine PLY each render. Regions saved session-local; no resume UI yet.
- Copy installed renderer into session and inject geometry hook after intrinsics; preserve sky clipping fix (recompute far after edits) and window protection. Main app renderer untouched.
- Parallel-only prototype; browser preview, non-overwriting output beside source. Multi-format/main-GUI integration deferred until user quality validation.
- Geometry projection/direction/unselected/inverse-depth tests passed locally. Python/shell and JavaScript syntax checked. Actual macOS/PyTorch/Metal and image quality validation pending. Do not claim end-to-end success.

## 2026-10-05 — Shared background repair experiment
- Added one-negative-region sky/background repair, opt-out comparison with existing guided renderer, distinct GuidedRepair filenames.
- Original image plus inverse selection builds one LaMa background. Dilate foreground mask to remove fringes; CPU TorchScript inference padded to multiples of eight, longest side capped at 1024. Composite original known sky outside hole exactly.
- Download only released big-lama.pt into separate model folder, validate TorchScript load before atomic publish, log observed hash (not trusted checksum). Existing runtime packages unchanged.
- Source-projected mask removes selected sky splats, foreground remains SHARP, black-background foreground render supplies premultiplied RGB/alpha. Composite shared texture warped per virtual camera and convergence intrinsics onto single distant plane. No separate inpainting per eye.
- Preserve existing window guard and scene-aware far clipping in copied renderer; source renderer, app identity, original cache untouched.
- Resume latest matching session by copying masks/selection/regions; persist region state after add/undo/reset. Clarify Include/Exclude labels. Old sessions retained.
- Local tests passed: inverse-depth geometry from original prototype, shared background camera/convergence shift, premultiplied alpha foreground preservation, exact known background pixels, Python/shell/JS syntax and actual renderer anchor. LaMa model and macOS/Metal execution not tested here; user image test pending.
- Limitations: single sky plane, imperfect hidden-layer membership, selection can accidentally remove foreground, bounded-resolution inpainting can be soft. No claim of artifact-free or semantic reconstruction.

## 2026-10-05 — Guided Selection R2: deterministic manual correction
- User's GuidedRepair output improved foreground edges but corrupted upper-right lettering. User reports global GrabCut changes distant propeller/clothing when refining letters. Root cause: point circles are hard seed samples, not whole-object exclusions; global classifier recomputes probable membership from color models.
- Add direct include/exclude brushes and rectangles. Pixel edits are exact and local; no classifier invocation. Store ordered stroke history and pristine automatic mask separately. Reapply manual history after every automatic segmentation, so manual exclusions remain fixed. Most recent overlapping manual edit wins. Undo removes last stroke and replays; reset saved regions leaves current manual edits intact.
- Restore automatic/manual masks and stroke history on resume. Older sessions without automatic-mask file use their current mask as the starting base. Legacy hard seed circles explicitly reapplied after GrabCut.
- Zoom Fit/2x/4x/8x in scrollable viewport; image-coordinate brush radius 1–100, continuous line strokes and pointer capture, pending-action controls disabled. Rectangles allow protecting whole text blocks without tiny letter-by-letter samples. Labels distinguish automatic seeds from direct edits.
- Saved regions remain independent mask snapshots; guide and UI instruct Reset All Regions / Add Region after manual corrections. Rendering/inpainting geometry unchanged.
- Tests passed locally: manual locality, full rectangle persistence under changed automatic masks, continuous brush coverage, ordered overrides, undo replay, outside-mask byte equality; existing background/geometry suites; Python/JS/shell syntax. macOS interactive operation pending user test. Still color-based automatic segmentation; no semantic selection promise.

## 2026-10-05 — Guided Brush R3: visible cursor and mask availability
- User screenshot showed visible green mask but brush alert required Find Selection after radius change. Radius was not the cause: automatic box/sample changes invalidate selected flag while leaving displayed mask available. Gate direct painting on mask availability instead; /paint uses the existing current mask and subsequent load marks it ready.
- Move Find Selection out of collapsed automatic-tools section into main controls. No-mask guidance identifies the visible button and starting-box workflow.
- Add fixed pointer-events-none circular cursor overlay, footprint diameter 2*radius*displayedCanvasWidth/nativeCanvasWidth. Update on pointer movement, radius/tool changes and zoom; hide on leave/viewport scroll/busy, hide OS cursor for brush and retain crosshair for rectangles/seeds.
- Tests: Node VM DOM/event harness verifies stale selected flag + visible mask permits painting, radius 5 with display scale 4 yields diameter 40 CSS px, radius changes update footprint, non-brush hides circle, absent mask provides clear workflow and one visible Find Selection button. Existing deterministic selection tests pass; Python/shell/JS checks pass. Actual macOS visual test pending.
- Renderer, repair model, session/history format and original app untouched. Full selection-wide undo/redo, overlay patterns and automatic text protection discussed but not implemented in this focused fix.

## 2026-10-05 — Guided Zoom R4: pointer-centered Z +/- keyboard controls
- User has not downloaded R3 yet; R4 includes its circular brush cursor and gating fix along with all previous R2/background repair code.
- Hold physical KeyZ plus +/= (including numpad add) or minus/numpad subtract. Initial keydown applies 1.12x multiplicative tap; animation frame loop applies exp(direction*.95*dt) while held. Native key-repeat ignored to avoid speed variation. Clamp zoom Fit–8x, update custom dropdown option.
- Keep source-image fraction under cursor invariant by recording pre-scale canvas rectangle and adjusting viewport scroll after CSS width change. Cursor remembered independently of hover brush state. Outside image use visible viewport center, clamped to image. Browser scroll bounds can limit anchor at edges/fit.
- Stop on release of Z/direction or window blur; do not intercept input/textarea/select/contenteditable, Cmd/Ctrl/Alt shortcuts, busy operations or active drawing. Existing preset dropdown remains usable.
- Node headless DOM/event regression checks passed for anchor invariance, tap and continuous progression, key release and blur stop, input-field protection, numeric keypad, zoom clamping. Existing brush and mask regression suites pass; Python/shell and parsed JavaScript checks pass. Actual Mac browser interaction pending user verification; AI/renderer unchanged.
- Outstanding requests retained: clearer overlay/mask view, selection-wide undo/redo with Cmd-Z/Shift-Cmd-Z, tentative text-protection tool. No claim those features shipped in R4.

## 2026-10-05 — Guided Zoom R5: focus, locked target and Z+0
- User reports no zoom until clicking blank page, top/center zoom instead of cursor upper-right, intermittent no response. Code review: keyboard ignores SELECT targets, dropdown retains focus; per-frame source-fraction recalculation drifts while browser clamps horizontal scroll to zero before image exceeds viewport width. Pointer-leave also discarded anchor during layout changes.
- Focusable canvas gets preventScroll focus on pointer enter/movement (no drawing required). Numeric/menu shortcuts remain typing-safe until pointer moves into image.
- Capture image fraction + screen point once per target, persist across frames/repeated taps and layout-driven pointer-leave. Genuine pointer-coordinate movement >1px resets target. Frame zoom uses stored image fraction even while scroll is clamped.
- Add Z+0 and numpad0 to stop zoom and reset Fit + viewport scroll. Fixed-height responsive viewport (min 650px/65vh), fit considers both width and height. Existing dropdown preserved; native Command +/-/0 remains future integration, not claimed implemented here.
- Prior tests did not model real browser scroll clamping. Add regression harness with bounded scroll setters, transition from sub-viewport width to horizontal overflow, preserve 90%-right target, hover clears dropdown focus, full-image fit bounds and Z+0. All previous/new JS event and brush tests pass; Python/shell checks pass. Actual Firefox/Mac visual operation pending user confirmation. No renderer/background/model/session modifications.

## 2026-10-05 — Guided Shortcuts R6: Command-brackets and individual sample deletion
- User confirms R5 target-centered zoom works great. Keep its controls and focus/anchor behavior unchanged.
- Add Command+[ / Command+] for Include/Exclude brushes while pointer hovers image. One-radius-pixel steps, native key-repeat supports hold, clamp 1–100. Update input and brush cursor synchronously. Do not intercept typing fields or non-brush/no-hover contexts; consume bracket shortcut before general Cmd filtering.
- Delete/Backspace over red/green automatic sample dot finds nearest dot within 10 selection-image pixels, prompts confirmation, saves remaining sample list without recomputing selection. Dot cancellation leaves state intact; repeats ignored to avoid multiple prompts. Recompute deferred to explicit Find Selection, retaining deterministic manual masks. Saved depth regions still need replacement after mask changes.
- Add /samples endpoint to persist rect+points in selection.json with finite-coordinate/type/count checks. No mask/renderer/model changes. User guidance distinguishes automatic sample dots from direct paint history and explains removal does not immediately change current green mask.
- New Node event test passes: bracket direction/repeat/clamps/input safety, nearest sample detection/deletion persistence, confirmation cancellation and off-dot miss. Existing zoom, circular cursor and local mask tests pass; Python/shell checks pass. Actual Mac browser shortcut handling remains user test.
- Pending earlier requests preserved: full undo/redo, clearer mask overlay/view and tentative text protection.

## 2026-10-05 — Manual Depth Estimation Editor R7: visible masks and named edits
- User has not downloaded R6; R7 includes its Command-bracket radius and Delete sample controls, retaining user-confirmed R5 zoom. Rename browser title/header Manual Depth Estimation Editor.
- Add bright/color-selectable overlay, strength slider, gentle optional 3.6-second sinusoidal pulse at 10 draw updates/sec, striped view and mask-only white/black view. Cache colorized overlay until mask/mode/color changes rather than recalculating per pulse frame. Display never changes mask bytes.
- Responsive right-side Saved edits panel (stacks on smaller screens), names/amounts/enabled switches, load and delete. Start Another Edit clears current mask/samples/direct strokes while preserving saved region snapshots. Loading uses saved mask as editable automatic base with strokes cleared; Update Saved Edit replaces specified snapshot. Confirm bulk clear; last-remove clears edit target to avoid stale index.
- Server adds named role/enabled fields and migrates older snapshots: first negative edit becomes Sky/background, others Object depth. Preserve region files and existing geometry sequencing; renderer receives only enabled regions. Save/update/delete/load/new-selection persist edits in session files.
- Repair now allows exactly one enabled negative background edit plus multiple object edits. LaMa background derives from explicit background role mask; hook selects that role instead of hard-coded first region. Object edits modify original splats, then foreground alpha composes against repaired shared plane. Hidden object surfaces remain limitations; no claim of reliable new foreground reconstruction.
- Tests passed: region migration and repair validation including multiple objects/toggles, actual Handler endpoints in isolated temp session for independent masks/save/load/update/delete/new-selection preservation; prior geometry, masks, background compositing and all JS zoom/brush/shortcut tests. Python/shell parsed checks pass. Mac R7 UI and combined render pending user test.
- README rewritten around new workflow instead of obsolete reset-all/one-region-only instructions. Foreground inpainting limitations, single sky plane, saved mask snapshot behavior documented. Pending full undo/redo and automatic text protection retained.

## 2026-10-05 — Manual Depth Editor R8: active edit binding and revision merge
- User confusion: repeated Save This Edit created three enabled Sky/background snapshots (Sky / Sky revisions / Sky revised), all -0.15, shown in screenshot. They interpreted a flashing current mask as an existing edit, which is reasonable. R7 cleared frontend editingIndex after save and failed to persist active target, creating duplicate snapshots.
- Persist active editing_index in edits/session export; restore it on resume. For older sessions, match current mask bytes to saved masks, otherwise use sole enabled region or newest enabled region when all enabled roles are sky/background. Current working mask remains intact; do not silently load an older mask. Expose draft dirty comparison/current target on /selection.
- /add updates active target and returns index; UI retains that target after Save. Banner names active edit and unsaved state; active saved card bordered. New Separate Edit clears mask/overlay/seeds/direct edits, retains saved regions, warns about unsaved loss. Use Current Selection binds current working mask to an existing target without loading saved pixels; Edit This loads saved mask with discard warning.
- Save Changes updates active saved snapshot. Brush actions persist working draft but do not silently change render snapshot; UI says unsaved until saved. Remove/delete reindex or clear backend binding; UI clears target conservatively. Actual rendering unchanged.
- Add Merge checkboxes, method choice and confirmed /region-merge. Latest method (default for revisions) retains newest selected saved mask and amount once; union explicitly combines selected pixels using ImageChops.lighter and also retains newest amount once. Must share role; index validation and at least two snapshots. Originals remain on disk/session backups; resulting list has one enabled merged record. Merge warns/blocks unsaved draft until saved. For screenshot's sky revisions, default latest avoids reintroducing excluded areas.
- Tests passed: backend Handler repeated-save active update without duplicate, new-edit preservation, loaded target persistence, three-to-one merge amount not compounded; exact latest-mask exclusions vs explicit union; prior zoom/cursor/shortcuts/mask/region validation. Python/shell/JS parsing checks passed. Mac R8 user workflow pending validation.
- Earlier pending full undo/redo and text detection remain unimplemented; no renderer quality promises. README starts with concrete rescue steps for three sky snapshots and distinguishes draft vs saved render state.

## 2026-10-05 — Manual Depth Editor R9: 32x zoom, direct redo and clearer workflow
- User requests at least 16x magnification, missing redo and clearer order/safer layout. Raise keyboard clamp and dropdown to 32x, adding 16/32 presets. Above 4x show pixelated working image; Fit uses normal interpolation. Selection thumbnail remains max1100, so magnification does not offer full-source pixel precision or recover detail.
- Add persistent redo_strokes stack/manual-redo.json, undo pops stroke to redo, redo restores, new direct paint clears redo branch. Clear/load/new-selection clears both histories. Redo survives session resume. Mask operations reply with undo/redo availability so buttons update immediately rather than waiting for state polling.
- Adjacent Undo Brush/Rectangle + Redo Brush/Rectangle controls, Cmd-Z/Shift-Cmd-Z when canvas/context active and no typing/busy operation. Explicit scope is direct painting only; full automatic samples/box/card history still pending and not claimed implemented.
- Four-step guidance at top and numbered selection/save/render headings. Pending draft changes block render with Save Changes instruction. Fold bulk saved-edit removal under details, confirm removing last saved item. Merge checkbox label laid out full-width flex/nowrap on own row to repair screenshot's detached Merge word.
- Existing JS zoom tests updated to32 limit; brush/keyboard regressions passed. Handler tests undo/redo exact mask bytes and branch invalidation passed alongside saved-edit/merge tests. Python/shell syntax passes. Mac R9 UI and keyboard operation pending user verification; renderer untouched.

## 2026-10-05 — Manual Depth Editor R10: changes terminology and selection margins
- User asks Enabled meaning, Saved changes terminology with numbered records, plain Undo/Redo labels, shrink/expand whole mask slider. Explain Enabled as application in next output; visible checkbox now Apply in next render. Number current list Change Number N, preserve user names. Visible change terminology replaces noun edit labels; internal routes/session keys kept compatible.
- Add selection_size integer slider -20..20, centered0, number input, ±1 buttons and Reset0. Commit on slider release/number change for responsive deterministic operation. Shrink uses PIL MinFilter(2*abs(offset)+1), expand uses MaxFilter; all disconnected patches/holes affected. Non-compounding: apply offset to base automatic mask + direct strokes every refresh. Current offset persisted separately in selection-size.json and copied on resume.
- Loading saved mask/new-selection resets offset0 to avoid double-applying saved morphology. /selection-size checks active selection/int/range before update; server replies include offset so controls sync after load/merge/new. Mark draft dirty; Save Changes required before renderer uses new mask. Undo/Redo remain direct strokes, morphology reversed with Reset0/slider; no promise of all-operation history.
- Tests pass disconnected mask shrink/expand, exact0 reset, baseline byte preservation, non-compounding behavior and bounds. Existing cursor/zoom/shortcuts/server saved-change/redo/merge suites pass. Python/JS checks pass. Real-image artifacts improvement pending Mac render comparison.
- Margin units are capped1100 working selection pixels, not necessarily original image pixels. Square-neighborhood morphology can remove small islands or fill holes; expanding can include previously excluded foreground. Explicitly document. Renderer/repair algorithm unchanged.


## 2026-10-05 — R11 combined editor update
Added SHARP Manual Depth Editor title; temporary stereo preview; Space-drag panning; plain bracket brush size; persisted directional and rounded adjustment guides; inward-only edge feathering; actual-splat original/adjusted depth visualization with shared scale and repaired-plane representation; stale-view notice. Cached shared background by source/mask hash. Preview intermediates cleaned, latest result reused, revision counters refresh short renders. Preserved main application and prior packages. Pure-Python, Node UI, endpoint and mocked render-orchestration checks passed; real Mac Metal/visual validation pending.


## 2026-10-06 — SHARP Manual Depth Editor integrated into Inject Z
- Request: incorporate the standalone editor into the main signed app.
- Native resizable WKWebView window wraps the existing R11 token-protected localhost editor. AppDelegate opens it for selectedPhoto; SHARP button and menu actions expose reopening/new/close session.
- Server accepts the selected photo argument and embedded URL-file handshake; no browser launch. Existing exact-photo session resume migration remains.
- Closing a window keeps its controller/process; app termination stops a dedicated process group, including renderer subprocesses. JS alerts/confirmation have native WKUIDelegate handlers. Nonlocal navigation opens externally.
- Conversion is gated while an editor session is running. Editor final output remains Parallel; main multiple-output conversion is unchanged. Default editor camera separation remains 0.060.
- Installer patches current installed Swift source (does not replace with historical snapshot), adds WebKit link, compiles before mutation, preserves com.injectz.app.dev and original certificate root F676FD4BC9E1160E9F1E0C29FF8F3F0D06F4C592, creates timestamped backup and rolls back affected files on failed installation. No engine/renderer changes.
- Files: ~/InjectZ/Development/SHARPDepthEditor (editor modules); source appended with DepthEditor.swift controller. Sessions remain ~/InjectZ/Development/GuidedDepthSessions. Startup log is /tmp/InjectZ-Editor-UUID/startup.log, per-render diagnostics in session.log.
- Checks: all 11 R11 tests pass; corrected latest-source patch integration passes; duplicate-patch rejection passes; Python compileall and bash -n pass. Native Swift/WebKit compilation and Metal image-quality validation cannot run on Linux; required compilation/signature checks run before replacement on the Mac.
- Next: Ted installs, opens selected photo in native editor, confirms shortcuts/dialogs/resume and previews an edited sky. Preserve certificate and conversion engines in any follow-up.

## 2026-10-05 — Guided SHARP depth experimental editor
- Standalone localhost token-protected browser UI, original photo selected through native Mac dialog. Existing app files and caches untouched.
- Source EXIF normalized to session PNG; selection thumbnail and fresh SHARP model share same orientation. First render predicts fresh session model to avoid basename cache collisions.
- Box + foreground/background seeds use OpenCV GrabCut in an existing environment. This is color segmentation, not semantic object recognition. No new dependencies/model downloaded; missing OpenCV fails with explanation.
- Region masks project onto splats through installed renderer intrinsics. Modify inverse depth with region-relative additive offset; scale xyz along original rays and Gaussian scales together. Approximate original composition retained; orientation/covariance complications, occluded layer selection and artifacts remain.
- Sequential masks derived from original projection; undo/reset recompute from pristine PLY each render. Regions saved session-local; no resume UI yet.
- Copy installed renderer into session and inject geometry hook after intrinsics; preserve sky clipping fix (recompute far after edits) and window protection. Main app renderer untouched.
- Parallel-only prototype; browser preview, non-overwriting output beside source. Multi-format/main-GUI integration deferred until user quality validation.
- Geometry projection/direction/unselected/inverse-depth tests passed locally. Python/shell and JavaScript syntax checked. Actual macOS/PyTorch/Metal and image quality validation pending. Do not claim end-to-end success.

## 2026-10-05 — Shared background repair experiment
- Added one-negative-region sky/background repair, opt-out comparison with existing guided renderer, distinct GuidedRepair filenames.
- Original image plus inverse selection builds one LaMa background. Dilate foreground mask to remove fringes; CPU TorchScript inference padded to multiples of eight, longest side capped at 1024. Composite original known sky outside hole exactly.
- Download only released big-lama.pt into separate model folder, validate TorchScript load before atomic publish, log observed hash (not trusted checksum). Existing runtime packages unchanged.
- Source-projected mask removes selected sky splats, foreground remains SHARP, black-background foreground render supplies premultiplied RGB/alpha. Composite shared texture warped per virtual camera and convergence intrinsics onto single distant plane. No separate inpainting per eye.
- Preserve existing window guard and scene-aware far clipping in copied renderer; source renderer, app identity, original cache untouched.
- Resume latest matching session by copying masks/selection/regions; persist region state after add/undo/reset. Clarify Include/Exclude labels. Old sessions retained.
- Local tests passed: inverse-depth geometry from original prototype, shared background camera/convergence shift, premultiplied alpha foreground preservation, exact known background pixels, Python/shell/JS syntax and actual renderer anchor. LaMa model and macOS/Metal execution not tested here; user image test pending.
- Limitations: single sky plane, imperfect hidden-layer membership, selection can accidentally remove foreground, bounded-resolution inpainting can be soft. No claim of artifact-free or semantic reconstruction.

## 2026-10-05 — Guided Selection R2: deterministic manual correction
- User's GuidedRepair output improved foreground edges but corrupted upper-right lettering. User reports global GrabCut changes distant propeller/clothing when refining letters. Root cause: point circles are hard seed samples, not whole-object exclusions; global classifier recomputes probable membership from color models.
- Add direct include/exclude brushes and rectangles. Pixel edits are exact and local; no classifier invocation. Store ordered stroke history and pristine automatic mask separately. Reapply manual history after every automatic segmentation, so manual exclusions remain fixed. Most recent overlapping manual edit wins. Undo removes last stroke and replays; reset saved regions leaves current manual edits intact.
- Restore automatic/manual masks and stroke history on resume. Older sessions without automatic-mask file use their current mask as the starting base. Legacy hard seed circles explicitly reapplied after GrabCut.
- Zoom Fit/2x/4x/8x in scrollable viewport; image-coordinate brush radius 1–100, continuous line strokes and pointer capture, pending-action controls disabled. Rectangles allow protecting whole text blocks without tiny letter-by-letter samples. Labels distinguish automatic seeds from direct edits.
- Saved regions remain independent mask snapshots; guide and UI instruct Reset All Regions / Add Region after manual corrections. Rendering/inpainting geometry unchanged.
- Tests passed locally: manual locality, full rectangle persistence under changed automatic masks, continuous brush coverage, ordered overrides, undo replay, outside-mask byte equality; existing background/geometry suites; Python/JS/shell syntax. macOS interactive operation pending user test. Still color-based automatic segmentation; no semantic selection promise.

## 2026-10-05 — Guided Brush R3: visible cursor and mask availability
- User screenshot showed visible green mask but brush alert required Find Selection after radius change. Radius was not the cause: automatic box/sample changes invalidate selected flag while leaving displayed mask available. Gate direct painting on mask availability instead; /paint uses the existing current mask and subsequent load marks it ready.
- Move Find Selection out of collapsed automatic-tools section into main controls. No-mask guidance identifies the visible button and starting-box workflow.
- Add fixed pointer-events-none circular cursor overlay, footprint diameter 2*radius*displayedCanvasWidth/nativeCanvasWidth. Update on pointer movement, radius/tool changes and zoom; hide on leave/viewport scroll/busy, hide OS cursor for brush and retain crosshair for rectangles/seeds.
- Tests: Node VM DOM/event harness verifies stale selected flag + visible mask permits painting, radius 5 with display scale 4 yields diameter 40 CSS px, radius changes update footprint, non-brush hides circle, absent mask provides clear workflow and one visible Find Selection button. Existing deterministic selection tests pass; Python/shell/JS checks pass. Actual macOS visual test pending.
- Renderer, repair model, session/history format and original app untouched. Full selection-wide undo/redo, overlay patterns and automatic text protection discussed but not implemented in this focused fix.

## 2026-10-05 — Guided Zoom R4: pointer-centered Z +/- keyboard controls
- User has not downloaded R3 yet; R4 includes its circular brush cursor and gating fix along with all previous R2/background repair code.
- Hold physical KeyZ plus +/= (including numpad add) or minus/numpad subtract. Initial keydown applies 1.12x multiplicative tap; animation frame loop applies exp(direction*.95*dt) while held. Native key-repeat ignored to avoid speed variation. Clamp zoom Fit–8x, update custom dropdown option.
- Keep source-image fraction under cursor invariant by recording pre-scale canvas rectangle and adjusting viewport scroll after CSS width change. Cursor remembered independently of hover brush state. Outside image use visible viewport center, clamped to image. Browser scroll bounds can limit anchor at edges/fit.
- Stop on release of Z/direction or window blur; do not intercept input/textarea/select/contenteditable, Cmd/Ctrl/Alt shortcuts, busy operations or active drawing. Existing preset dropdown remains usable.
- Node headless DOM/event regression checks passed for anchor invariance, tap and continuous progression, key release and blur stop, input-field protection, numeric keypad, zoom clamping. Existing brush and mask regression suites pass; Python/shell and parsed JavaScript checks pass. Actual Mac browser interaction pending user verification; AI/renderer unchanged.
- Outstanding requests retained: clearer overlay/mask view, selection-wide undo/redo with Cmd-Z/Shift-Cmd-Z, tentative text-protection tool. No claim those features shipped in R4.

## 2026-10-05 — Guided Zoom R5: focus, locked target and Z+0
- User reports no zoom until clicking blank page, top/center zoom instead of cursor upper-right, intermittent no response. Code review: keyboard ignores SELECT targets, dropdown retains focus; per-frame source-fraction recalculation drifts while browser clamps horizontal scroll to zero before image exceeds viewport width. Pointer-leave also discarded anchor during layout changes.
- Focusable canvas gets preventScroll focus on pointer enter/movement (no drawing required). Numeric/menu shortcuts remain typing-safe until pointer moves into image.
- Capture image fraction + screen point once per target, persist across frames/repeated taps and layout-driven pointer-leave. Genuine pointer-coordinate movement >1px resets target. Frame zoom uses stored image fraction even while scroll is clamped.
- Add Z+0 and numpad0 to stop zoom and reset Fit + viewport scroll. Fixed-height responsive viewport (min 650px/65vh), fit considers both width and height. Existing dropdown preserved; native Command +/-/0 remains future integration, not claimed implemented here.
- Prior tests did not model real browser scroll clamping. Add regression harness with bounded scroll setters, transition from sub-viewport width to horizontal overflow, preserve 90%-right target, hover clears dropdown focus, full-image fit bounds and Z+0. All previous/new JS event and brush tests pass; Python/shell checks pass. Actual Firefox/Mac visual operation pending user confirmation. No renderer/background/model/session modifications.

## 2026-10-05 — Guided Shortcuts R6: Command-brackets and individual sample deletion
- User confirms R5 target-centered zoom works great. Keep its controls and focus/anchor behavior unchanged.
- Add Command+[ / Command+] for Include/Exclude brushes while pointer hovers image. One-radius-pixel steps, native key-repeat supports hold, clamp 1–100. Update input and brush cursor synchronously. Do not intercept typing fields or non-brush/no-hover contexts; consume bracket shortcut before general Cmd filtering.
- Delete/Backspace over red/green automatic sample dot finds nearest dot within 10 selection-image pixels, prompts confirmation, saves remaining sample list without recomputing selection. Dot cancellation leaves state intact; repeats ignored to avoid multiple prompts. Recompute deferred to explicit Find Selection, retaining deterministic manual masks. Saved depth regions still need replacement after mask changes.
- Add /samples endpoint to persist rect+points in selection.json with finite-coordinate/type/count checks. No mask/renderer/model changes. User guidance distinguishes automatic sample dots from direct paint history and explains removal does not immediately change current green mask.
- New Node event test passes: bracket direction/repeat/clamps/input safety, nearest sample detection/deletion persistence, confirmation cancellation and off-dot miss. Existing zoom, circular cursor and local mask tests pass; Python/shell checks pass. Actual Mac browser shortcut handling remains user test.
- Pending earlier requests preserved: full undo/redo, clearer mask overlay/view and tentative text protection.

## 2026-10-05 — Manual Depth Estimation Editor R7: visible masks and named edits
- User has not downloaded R6; R7 includes its Command-bracket radius and Delete sample controls, retaining user-confirmed R5 zoom. Rename browser title/header Manual Depth Estimation Editor.
- Add bright/color-selectable overlay, strength slider, gentle optional 3.6-second sinusoidal pulse at 10 draw updates/sec, striped view and mask-only white/black view. Cache colorized overlay until mask/mode/color changes rather than recalculating per pulse frame. Display never changes mask bytes.
- Responsive right-side Saved edits panel (stacks on smaller screens), names/amounts/enabled switches, load and delete. Start Another Edit clears current mask/samples/direct strokes while preserving saved region snapshots. Loading uses saved mask as editable automatic base with strokes cleared; Update Saved Edit replaces specified snapshot. Confirm bulk clear; last-remove clears edit target to avoid stale index.
- Server adds named role/enabled fields and migrates older snapshots: first negative edit becomes Sky/background, others Object depth. Preserve region files and existing geometry sequencing; renderer receives only enabled regions. Save/update/delete/load/new-selection persist edits in session files.
- Repair now allows exactly one enabled negative background edit plus multiple object edits. LaMa background derives from explicit background role mask; hook selects that role instead of hard-coded first region. Object edits modify original splats, then foreground alpha composes against repaired shared plane. Hidden object surfaces remain limitations; no claim of reliable new foreground reconstruction.
- Tests passed: region migration and repair validation including multiple objects/toggles, actual Handler endpoints in isolated temp session for independent masks/save/load/update/delete/new-selection preservation; prior geometry, masks, background compositing and all JS zoom/brush/shortcut tests. Python/shell parsed checks pass. Mac R7 UI and combined render pending user test.
- README rewritten around new workflow instead of obsolete reset-all/one-region-only instructions. Foreground inpainting limitations, single sky plane, saved mask snapshot behavior documented. Pending full undo/redo and automatic text protection retained.

## 2026-10-05 — Manual Depth Editor R8: active edit binding and revision merge
- User confusion: repeated Save This Edit created three enabled Sky/background snapshots (Sky / Sky revisions / Sky revised), all -0.15, shown in screenshot. They interpreted a flashing current mask as an existing edit, which is reasonable. R7 cleared frontend editingIndex after save and failed to persist active target, creating duplicate snapshots.
- Persist active editing_index in edits/session export; restore it on resume. For older sessions, match current mask bytes to saved masks, otherwise use sole enabled region or newest enabled region when all enabled roles are sky/background. Current working mask remains intact; do not silently load an older mask. Expose draft dirty comparison/current target on /selection.
- /add updates active target and returns index; UI retains that target after Save. Banner names active edit and unsaved state; active saved card bordered. New Separate Edit clears mask/overlay/seeds/direct edits, retains saved regions, warns about unsaved loss. Use Current Selection binds current working mask to an existing target without loading saved pixels; Edit This loads saved mask with discard warning.
- Save Changes updates active saved snapshot. Brush actions persist working draft but do not silently change render snapshot; UI says unsaved until saved. Remove/delete reindex or clear backend binding; UI clears target conservatively. Actual rendering unchanged.
- Add Merge checkboxes, method choice and confirmed /region-merge. Latest method (default for revisions) retains newest selected saved mask and amount once; union explicitly combines selected pixels using ImageChops.lighter and also retains newest amount once. Must share role; index validation and at least two snapshots. Originals remain on disk/session backups; resulting list has one enabled merged record. Merge warns/blocks unsaved draft until saved. For screenshot's sky revisions, default latest avoids reintroducing excluded areas.
- Tests passed: backend Handler repeated-save active update without duplicate, new-edit preservation, loaded target persistence, three-to-one merge amount not compounded; exact latest-mask exclusions vs explicit union; prior zoom/cursor/shortcuts/mask/region validation. Python/shell/JS parsing checks passed. Mac R8 user workflow pending validation.
- Earlier pending full undo/redo and text detection remain unimplemented; no renderer quality promises. README starts with concrete rescue steps for three sky snapshots and distinguishes draft vs saved render state.

## 2026-10-05 — Manual Depth Editor R9: 32x zoom, direct redo and clearer workflow
- User requests at least 16x magnification, missing redo and clearer order/safer layout. Raise keyboard clamp and dropdown to 32x, adding 16/32 presets. Above 4x show pixelated working image; Fit uses normal interpolation. Selection thumbnail remains max1100, so magnification does not offer full-source pixel precision or recover detail.
- Add persistent redo_strokes stack/manual-redo.json, undo pops stroke to redo, redo restores, new direct paint clears redo branch. Clear/load/new-selection clears both histories. Redo survives session resume. Mask operations reply with undo/redo availability so buttons update immediately rather than waiting for state polling.
- Adjacent Undo Brush/Rectangle + Redo Brush/Rectangle controls, Cmd-Z/Shift-Cmd-Z when canvas/context active and no typing/busy operation. Explicit scope is direct painting only; full automatic samples/box/card history still pending and not claimed implemented.
- Four-step guidance at top and numbered selection/save/render headings. Pending draft changes block render with Save Changes instruction. Fold bulk saved-edit removal under details, confirm removing last saved item. Merge checkbox label laid out full-width flex/nowrap on own row to repair screenshot's detached Merge word.
- Existing JS zoom tests updated to32 limit; brush/keyboard regressions passed. Handler tests undo/redo exact mask bytes and branch invalidation passed alongside saved-edit/merge tests. Python/shell syntax passes. Mac R9 UI and keyboard operation pending user verification; renderer untouched.

## 2026-10-05 — Manual Depth Editor R10: changes terminology and selection margins
- User asks Enabled meaning, Saved changes terminology with numbered records, plain Undo/Redo labels, shrink/expand whole mask slider. Explain Enabled as application in next output; visible checkbox now Apply in next render. Number current list Change Number N, preserve user names. Visible change terminology replaces noun edit labels; internal routes/session keys kept compatible.
- Add selection_size integer slider -20..20, centered0, number input, ±1 buttons and Reset0. Commit on slider release/number change for responsive deterministic operation. Shrink uses PIL MinFilter(2*abs(offset)+1), expand uses MaxFilter; all disconnected patches/holes affected. Non-compounding: apply offset to base automatic mask + direct strokes every refresh. Current offset persisted separately in selection-size.json and copied on resume.
- Loading saved mask/new-selection resets offset0 to avoid double-applying saved morphology. /selection-size checks active selection/int/range before update; server replies include offset so controls sync after load/merge/new. Mark draft dirty; Save Changes required before renderer uses new mask. Undo/Redo remain direct strokes, morphology reversed with Reset0/slider; no promise of all-operation history.
- Tests pass disconnected mask shrink/expand, exact0 reset, baseline byte preservation, non-compounding behavior and bounds. Existing cursor/zoom/shortcuts/server saved-change/redo/merge suites pass. Python/JS checks pass. Real-image artifacts improvement pending Mac render comparison.
- Margin units are capped1100 working selection pixels, not necessarily original image pixels. Square-neighborhood morphology can remove small islands or fill holes; expanding can include previously excluded foreground. Explicitly document. Renderer/repair algorithm unchanged.


## 2026-10-05 — R11 combined editor update
Added SHARP Manual Depth Editor title; temporary stereo preview; Space-drag panning; plain bracket brush size; persisted directional and rounded adjustment guides; inward-only edge feathering; actual-splat original/adjusted depth visualization with shared scale and repaired-plane representation; stale-view notice. Cached shared background by source/mask hash. Preview intermediates cleaned, latest result reused, revision counters refresh short renders. Preserved main application and prior packages. Pure-Python, Node UI, endpoint and mocked render-orchestration checks passed; real Mac Metal/visual validation pending.


## 2026-10-06 — SHARP Manual Depth Editor integrated into Inject Z
- Request: incorporate the standalone editor into the main signed app.
- Native resizable WKWebView window wraps the existing R11 token-protected localhost editor. AppDelegate opens it for selectedPhoto; SHARP button and menu actions expose reopening/new/close session.
- Server accepts the selected photo argument and embedded URL-file handshake; no browser launch. Existing exact-photo session resume migration remains.
- Closing a window keeps its controller/process; app termination stops a dedicated process group, including renderer subprocesses. JS alerts/confirmation have native WKUIDelegate handlers. Nonlocal navigation opens externally.
- Conversion is gated while an editor session is running. Editor final output remains Parallel; main multiple-output conversion is unchanged. Default editor camera separation remains 0.060.
- Installer patches current installed Swift source (does not replace with historical snapshot), adds WebKit link, compiles before mutation, preserves com.injectz.app.dev and original certificate root F676FD4BC9E1160E9F1E0C29FF8F3F0D06F4C592, creates timestamped backup and rolls back affected files on failed installation. No engine/renderer changes.
- Files: ~/InjectZ/Development/SHARPDepthEditor (editor modules); source appended with DepthEditor.swift controller. Sessions remain ~/InjectZ/Development/GuidedDepthSessions. Startup log is /tmp/InjectZ-Editor-UUID/startup.log, per-render diagnostics in session.log.
- Checks: all 11 R11 tests pass; corrected latest-source patch integration passes; duplicate-patch rejection passes; Python compileall and bash -n pass. Native Swift/WebKit compilation and Metal image-quality validation cannot run on Linux; required compilation/signature checks run before replacement on the Mac.
- Next: Ted installs, opens selected photo in native editor, confirms shortcuts/dialogs/resume and previews an edited sky. Preserve certificate and conversion engines in any follow-up.


## 2026-10-06 — context help, guide and tested IW3 default
- Ted requested compact circled question marks, hover What is this?, and clickable explanations for all depth-editor features. Added accessible buttons beside all static settings/actions, all 8 selected tools, and 7 saved-change control types.
- Native HTML dialog uses textContent (not HTML injection), modal focus, Close/Escape, return focus, and capture-phase editing-shortcut isolation. Help remains enabled while a renderer request is pending/busy. Dynamic saved cards receive help via MutationObserver; insertion is idempotent. No mask/geometry/render logic changed.
- Updated bundled InjectZ_User_Guide.html plus repository-friendly USER_GUIDE.md with editor workflow, a sky example, save semantics, gradient/rounded/feather, depth views, keyboard controls, output/session limitations and detailed control reference. Removed obsolete Keep Terminal open guidance from integrated interface.
- As authorized after the Whalom comparison: methodPopup initially selects forward_inpaint and nil fallback uses it. Depth Pro/strength choices and all other methods preserved. Evidence: mlbw_l2_inpaint gray-grid output; mlbw_l2 removed grid but doubled edges; forward_inpaint user reports markedly improved output. Root cause inside mlbw_l2_inpaint remains unproven; no upstream engine upgrade.
- patch_help.py handles pre-integration current source by applying integration once, or already-integrated source without duplication. Existing Custom Depth, centered Whitten credits, Help, Command-W and engine features retained. Resource guide replacement occurs in staged app before original-certificate signing.
- Tests: all 11 editor tests pass; help coverage and JS parse checks pass; modal behavior/current-tool topic/Escape/focus checks pass; patch accepts both source states and is idempotent; Python compileall and bash syntax pass. AppKit/WebKit/Metal validation remains on Ted's Mac.
- GitHub releases API currently returns []; documented Sparkle+signed appcast/public packaging plan in UPDATE_PLAN.md. No updater installed or automatic-update claim.
- Next: install INSTALL_EDITOR_HELP.command, inspect help buttons in embedded WebKit and app-menu guide, confirm IW3 new default on relaunch. Later define public versions/signing/helper packaging before implementing auto-updates.


## 2026-10-06 — integrated editor process-group startup repair
- User screenshot: server.py line 13 os.setsid(), PermissionError EPERM. Native window started but Python editor exited before URL handshake.
- Root cause: Foundation Process launches helper as process-group leader. POSIX setsid rejects group leaders; this is not a Photos/Accessibility privacy failure.
- Repair: create a session only when os.getpgrp()!=os.getpid(); preserve own-group SIGTERM cleanup of renderer children.
- Exact-source patch, staged compile and server.py backup only; no app/signature/source/model changes.
- Verified with actual Linux subprocess launches for existing group leader and inherited parent group, each produces helper PID==PGID and exits via isolated group cleanup. Source compile/parse and installer bash -n passed. No macOS execution available here.
- Next: Ted quits app, installs INSTALL_STARTUP_FIX.command, reopens editor; examine any subsequent URL/WebKit failure separately.

## 2026-10-05 — Guided SHARP depth experimental editor
- Standalone localhost token-protected browser UI, original photo selected through native Mac dialog. Existing app files and caches untouched.
- Source EXIF normalized to session PNG; selection thumbnail and fresh SHARP model share same orientation. First render predicts fresh session model to avoid basename cache collisions.
- Box + foreground/background seeds use OpenCV GrabCut in an existing environment. This is color segmentation, not semantic object recognition. No new dependencies/model downloaded; missing OpenCV fails with explanation.
- Region masks project onto splats through installed renderer intrinsics. Modify inverse depth with region-relative additive offset; scale xyz along original rays and Gaussian scales together. Approximate original composition retained; orientation/covariance complications, occluded layer selection and artifacts remain.
- Sequential masks derived from original projection; undo/reset recompute from pristine PLY each render. Regions saved session-local; no resume UI yet.
- Copy installed renderer into session and inject geometry hook after intrinsics; preserve sky clipping fix (recompute far after edits) and window protection. Main app renderer untouched.
- Parallel-only prototype; browser preview, non-overwriting output beside source. Multi-format/main-GUI integration deferred until user quality validation.
- Geometry projection/direction/unselected/inverse-depth tests passed locally. Python/shell and JavaScript syntax checked. Actual macOS/PyTorch/Metal and image quality validation pending. Do not claim end-to-end success.

## 2026-10-05 — Shared background repair experiment
- Added one-negative-region sky/background repair, opt-out comparison with existing guided renderer, distinct GuidedRepair filenames.
- Original image plus inverse selection builds one LaMa background. Dilate foreground mask to remove fringes; CPU TorchScript inference padded to multiples of eight, longest side capped at 1024. Composite original known sky outside hole exactly.
- Download only released big-lama.pt into separate model folder, validate TorchScript load before atomic publish, log observed hash (not trusted checksum). Existing runtime packages unchanged.
- Source-projected mask removes selected sky splats, foreground remains SHARP, black-background foreground render supplies premultiplied RGB/alpha. Composite shared texture warped per virtual camera and convergence intrinsics onto single distant plane. No separate inpainting per eye.
- Preserve existing window guard and scene-aware far clipping in copied renderer; source renderer, app identity, original cache untouched.
- Resume latest matching session by copying masks/selection/regions; persist region state after add/undo/reset. Clarify Include/Exclude labels. Old sessions retained.
- Local tests passed: inverse-depth geometry from original prototype, shared background camera/convergence shift, premultiplied alpha foreground preservation, exact known background pixels, Python/shell/JS syntax and actual renderer anchor. LaMa model and macOS/Metal execution not tested here; user image test pending.
- Limitations: single sky plane, imperfect hidden-layer membership, selection can accidentally remove foreground, bounded-resolution inpainting can be soft. No claim of artifact-free or semantic reconstruction.

## 2026-10-05 — Guided Selection R2: deterministic manual correction
- User's GuidedRepair output improved foreground edges but corrupted upper-right lettering. User reports global GrabCut changes distant propeller/clothing when refining letters. Root cause: point circles are hard seed samples, not whole-object exclusions; global classifier recomputes probable membership from color models.
- Add direct include/exclude brushes and rectangles. Pixel edits are exact and local; no classifier invocation. Store ordered stroke history and pristine automatic mask separately. Reapply manual history after every automatic segmentation, so manual exclusions remain fixed. Most recent overlapping manual edit wins. Undo removes last stroke and replays; reset saved regions leaves current manual edits intact.
- Restore automatic/manual masks and stroke history on resume. Older sessions without automatic-mask file use their current mask as the starting base. Legacy hard seed circles explicitly reapplied after GrabCut.
- Zoom Fit/2x/4x/8x in scrollable viewport; image-coordinate brush radius 1–100, continuous line strokes and pointer capture, pending-action controls disabled. Rectangles allow protecting whole text blocks without tiny letter-by-letter samples. Labels distinguish automatic seeds from direct edits.
- Saved regions remain independent mask snapshots; guide and UI instruct Reset All Regions / Add Region after manual corrections. Rendering/inpainting geometry unchanged.
- Tests passed locally: manual locality, full rectangle persistence under changed automatic masks, continuous brush coverage, ordered overrides, undo replay, outside-mask byte equality; existing background/geometry suites; Python/JS/shell syntax. macOS interactive operation pending user test. Still color-based automatic segmentation; no semantic selection promise.

## 2026-10-05 — Guided Brush R3: visible cursor and mask availability
- User screenshot showed visible green mask but brush alert required Find Selection after radius change. Radius was not the cause: automatic box/sample changes invalidate selected flag while leaving displayed mask available. Gate direct painting on mask availability instead; /paint uses the existing current mask and subsequent load marks it ready.
- Move Find Selection out of collapsed automatic-tools section into main controls. No-mask guidance identifies the visible button and starting-box workflow.
- Add fixed pointer-events-none circular cursor overlay, footprint diameter 2*radius*displayedCanvasWidth/nativeCanvasWidth. Update on pointer movement, radius/tool changes and zoom; hide on leave/viewport scroll/busy, hide OS cursor for brush and retain crosshair for rectangles/seeds.
- Tests: Node VM DOM/event harness verifies stale selected flag + visible mask permits painting, radius 5 with display scale 4 yields diameter 40 CSS px, radius changes update footprint, non-brush hides circle, absent mask provides clear workflow and one visible Find Selection button. Existing deterministic selection tests pass; Python/shell/JS checks pass. Actual macOS visual test pending.
- Renderer, repair model, session/history format and original app untouched. Full selection-wide undo/redo, overlay patterns and automatic text protection discussed but not implemented in this focused fix.

## 2026-10-05 — Guided Zoom R4: pointer-centered Z +/- keyboard controls
- User has not downloaded R3 yet; R4 includes its circular brush cursor and gating fix along with all previous R2/background repair code.
- Hold physical KeyZ plus +/= (including numpad add) or minus/numpad subtract. Initial keydown applies 1.12x multiplicative tap; animation frame loop applies exp(direction*.95*dt) while held. Native key-repeat ignored to avoid speed variation. Clamp zoom Fit–8x, update custom dropdown option.
- Keep source-image fraction under cursor invariant by recording pre-scale canvas rectangle and adjusting viewport scroll after CSS width change. Cursor remembered independently of hover brush state. Outside image use visible viewport center, clamped to image. Browser scroll bounds can limit anchor at edges/fit.
- Stop on release of Z/direction or window blur; do not intercept input/textarea/select/contenteditable, Cmd/Ctrl/Alt shortcuts, busy operations or active drawing. Existing preset dropdown remains usable.
- Node headless DOM/event regression checks passed for anchor invariance, tap and continuous progression, key release and blur stop, input-field protection, numeric keypad, zoom clamping. Existing brush and mask regression suites pass; Python/shell and parsed JavaScript checks pass. Actual Mac browser interaction pending user verification; AI/renderer unchanged.
- Outstanding requests retained: clearer overlay/mask view, selection-wide undo/redo with Cmd-Z/Shift-Cmd-Z, tentative text-protection tool. No claim those features shipped in R4.

## 2026-10-05 — Guided Zoom R5: focus, locked target and Z+0
- User reports no zoom until clicking blank page, top/center zoom instead of cursor upper-right, intermittent no response. Code review: keyboard ignores SELECT targets, dropdown retains focus; per-frame source-fraction recalculation drifts while browser clamps horizontal scroll to zero before image exceeds viewport width. Pointer-leave also discarded anchor during layout changes.
- Focusable canvas gets preventScroll focus on pointer enter/movement (no drawing required). Numeric/menu shortcuts remain typing-safe until pointer moves into image.
- Capture image fraction + screen point once per target, persist across frames/repeated taps and layout-driven pointer-leave. Genuine pointer-coordinate movement >1px resets target. Frame zoom uses stored image fraction even while scroll is clamped.
- Add Z+0 and numpad0 to stop zoom and reset Fit + viewport scroll. Fixed-height responsive viewport (min 650px/65vh), fit considers both width and height. Existing dropdown preserved; native Command +/-/0 remains future integration, not claimed implemented here.
- Prior tests did not model real browser scroll clamping. Add regression harness with bounded scroll setters, transition from sub-viewport width to horizontal overflow, preserve 90%-right target, hover clears dropdown focus, full-image fit bounds and Z+0. All previous/new JS event and brush tests pass; Python/shell checks pass. Actual Firefox/Mac visual operation pending user confirmation. No renderer/background/model/session modifications.

## 2026-10-05 — Guided Shortcuts R6: Command-brackets and individual sample deletion
- User confirms R5 target-centered zoom works great. Keep its controls and focus/anchor behavior unchanged.
- Add Command+[ / Command+] for Include/Exclude brushes while pointer hovers image. One-radius-pixel steps, native key-repeat supports hold, clamp 1–100. Update input and brush cursor synchronously. Do not intercept typing fields or non-brush/no-hover contexts; consume bracket shortcut before general Cmd filtering.
- Delete/Backspace over red/green automatic sample dot finds nearest dot within 10 selection-image pixels, prompts confirmation, saves remaining sample list without recomputing selection. Dot cancellation leaves state intact; repeats ignored to avoid multiple prompts. Recompute deferred to explicit Find Selection, retaining deterministic manual masks. Saved depth regions still need replacement after mask changes.
- Add /samples endpoint to persist rect+points in selection.json with finite-coordinate/type/count checks. No mask/renderer/model changes. User guidance distinguishes automatic sample dots from direct paint history and explains removal does not immediately change current green mask.
- New Node event test passes: bracket direction/repeat/clamps/input safety, nearest sample detection/deletion persistence, confirmation cancellation and off-dot miss. Existing zoom, circular cursor and local mask tests pass; Python/shell checks pass. Actual Mac browser shortcut handling remains user test.
- Pending earlier requests preserved: full undo/redo, clearer mask overlay/view and tentative text protection.

## 2026-10-05 — Manual Depth Estimation Editor R7: visible masks and named edits
- User has not downloaded R6; R7 includes its Command-bracket radius and Delete sample controls, retaining user-confirmed R5 zoom. Rename browser title/header Manual Depth Estimation Editor.
- Add bright/color-selectable overlay, strength slider, gentle optional 3.6-second sinusoidal pulse at 10 draw updates/sec, striped view and mask-only white/black view. Cache colorized overlay until mask/mode/color changes rather than recalculating per pulse frame. Display never changes mask bytes.
- Responsive right-side Saved edits panel (stacks on smaller screens), names/amounts/enabled switches, load and delete. Start Another Edit clears current mask/samples/direct strokes while preserving saved region snapshots. Loading uses saved mask as editable automatic base with strokes cleared; Update Saved Edit replaces specified snapshot. Confirm bulk clear; last-remove clears edit target to avoid stale index.
- Server adds named role/enabled fields and migrates older snapshots: first negative edit becomes Sky/background, others Object depth. Preserve region files and existing geometry sequencing; renderer receives only enabled regions. Save/update/delete/load/new-selection persist edits in session files.
- Repair now allows exactly one enabled negative background edit plus multiple object edits. LaMa background derives from explicit background role mask; hook selects that role instead of hard-coded first region. Object edits modify original splats, then foreground alpha composes against repaired shared plane. Hidden object surfaces remain limitations; no claim of reliable new foreground reconstruction.
- Tests passed: region migration and repair validation including multiple objects/toggles, actual Handler endpoints in isolated temp session for independent masks/save/load/update/delete/new-selection preservation; prior geometry, masks, background compositing and all JS zoom/brush/shortcut tests. Python/shell parsed checks pass. Mac R7 UI and combined render pending user test.
- README rewritten around new workflow instead of obsolete reset-all/one-region-only instructions. Foreground inpainting limitations, single sky plane, saved mask snapshot behavior documented. Pending full undo/redo and automatic text protection retained.

## 2026-10-05 — Manual Depth Editor R8: active edit binding and revision merge
- User confusion: repeated Save This Edit created three enabled Sky/background snapshots (Sky / Sky revisions / Sky revised), all -0.15, shown in screenshot. They interpreted a flashing current mask as an existing edit, which is reasonable. R7 cleared frontend editingIndex after save and failed to persist active target, creating duplicate snapshots.
- Persist active editing_index in edits/session export; restore it on resume. For older sessions, match current mask bytes to saved masks, otherwise use sole enabled region or newest enabled region when all enabled roles are sky/background. Current working mask remains intact; do not silently load an older mask. Expose draft dirty comparison/current target on /selection.
- /add updates active target and returns index; UI retains that target after Save. Banner names active edit and unsaved state; active saved card bordered. New Separate Edit clears mask/overlay/seeds/direct edits, retains saved regions, warns about unsaved loss. Use Current Selection binds current working mask to an existing target without loading saved pixels; Edit This loads saved mask with discard warning.
- Save Changes updates active saved snapshot. Brush actions persist working draft but do not silently change render snapshot; UI says unsaved until saved. Remove/delete reindex or clear backend binding; UI clears target conservatively. Actual rendering unchanged.
- Add Merge checkboxes, method choice and confirmed /region-merge. Latest method (default for revisions) retains newest selected saved mask and amount once; union explicitly combines selected pixels using ImageChops.lighter and also retains newest amount once. Must share role; index validation and at least two snapshots. Originals remain on disk/session backups; resulting list has one enabled merged record. Merge warns/blocks unsaved draft until saved. For screenshot's sky revisions, default latest avoids reintroducing excluded areas.
- Tests passed: backend Handler repeated-save active update without duplicate, new-edit preservation, loaded target persistence, three-to-one merge amount not compounded; exact latest-mask exclusions vs explicit union; prior zoom/cursor/shortcuts/mask/region validation. Python/shell/JS parsing checks passed. Mac R8 user workflow pending validation.
- Earlier pending full undo/redo and text detection remain unimplemented; no renderer quality promises. README starts with concrete rescue steps for three sky snapshots and distinguishes draft vs saved render state.

## 2026-10-05 — Manual Depth Editor R9: 32x zoom, direct redo and clearer workflow
- User requests at least 16x magnification, missing redo and clearer order/safer layout. Raise keyboard clamp and dropdown to 32x, adding 16/32 presets. Above 4x show pixelated working image; Fit uses normal interpolation. Selection thumbnail remains max1100, so magnification does not offer full-source pixel precision or recover detail.
- Add persistent redo_strokes stack/manual-redo.json, undo pops stroke to redo, redo restores, new direct paint clears redo branch. Clear/load/new-selection clears both histories. Redo survives session resume. Mask operations reply with undo/redo availability so buttons update immediately rather than waiting for state polling.
- Adjacent Undo Brush/Rectangle + Redo Brush/Rectangle controls, Cmd-Z/Shift-Cmd-Z when canvas/context active and no typing/busy operation. Explicit scope is direct painting only; full automatic samples/box/card history still pending and not claimed implemented.
- Four-step guidance at top and numbered selection/save/render headings. Pending draft changes block render with Save Changes instruction. Fold bulk saved-edit removal under details, confirm removing last saved item. Merge checkbox label laid out full-width flex/nowrap on own row to repair screenshot's detached Merge word.
- Existing JS zoom tests updated to32 limit; brush/keyboard regressions passed. Handler tests undo/redo exact mask bytes and branch invalidation passed alongside saved-edit/merge tests. Python/shell syntax passes. Mac R9 UI and keyboard operation pending user verification; renderer untouched.

## 2026-10-05 — Manual Depth Editor R10: changes terminology and selection margins
- User asks Enabled meaning, Saved changes terminology with numbered records, plain Undo/Redo labels, shrink/expand whole mask slider. Explain Enabled as application in next output; visible checkbox now Apply in next render. Number current list Change Number N, preserve user names. Visible change terminology replaces noun edit labels; internal routes/session keys kept compatible.
- Add selection_size integer slider -20..20, centered0, number input, ±1 buttons and Reset0. Commit on slider release/number change for responsive deterministic operation. Shrink uses PIL MinFilter(2*abs(offset)+1), expand uses MaxFilter; all disconnected patches/holes affected. Non-compounding: apply offset to base automatic mask + direct strokes every refresh. Current offset persisted separately in selection-size.json and copied on resume.
- Loading saved mask/new-selection resets offset0 to avoid double-applying saved morphology. /selection-size checks active selection/int/range before update; server replies include offset so controls sync after load/merge/new. Mark draft dirty; Save Changes required before renderer uses new mask. Undo/Redo remain direct strokes, morphology reversed with Reset0/slider; no promise of all-operation history.
- Tests pass disconnected mask shrink/expand, exact0 reset, baseline byte preservation, non-compounding behavior and bounds. Existing cursor/zoom/shortcuts/server saved-change/redo/merge suites pass. Python/JS checks pass. Real-image artifacts improvement pending Mac render comparison.
- Margin units are capped1100 working selection pixels, not necessarily original image pixels. Square-neighborhood morphology can remove small islands or fill holes; expanding can include previously excluded foreground. Explicitly document. Renderer/repair algorithm unchanged.


## 2026-10-05 — R11 combined editor update
Added SHARP Manual Depth Editor title; temporary stereo preview; Space-drag panning; plain bracket brush size; persisted directional and rounded adjustment guides; inward-only edge feathering; actual-splat original/adjusted depth visualization with shared scale and repaired-plane representation; stale-view notice. Cached shared background by source/mask hash. Preview intermediates cleaned, latest result reused, revision counters refresh short renders. Preserved main application and prior packages. Pure-Python, Node UI, endpoint and mocked render-orchestration checks passed; real Mac Metal/visual validation pending.


## 2026-10-06 — SHARP Manual Depth Editor integrated into Inject Z
- Request: incorporate the standalone editor into the main signed app.
- Native resizable WKWebView window wraps the existing R11 token-protected localhost editor. AppDelegate opens it for selectedPhoto; SHARP button and menu actions expose reopening/new/close session.
- Server accepts the selected photo argument and embedded URL-file handshake; no browser launch. Existing exact-photo session resume migration remains.
- Closing a window keeps its controller/process; app termination stops a dedicated process group, including renderer subprocesses. JS alerts/confirmation have native WKUIDelegate handlers. Nonlocal navigation opens externally.
- Conversion is gated while an editor session is running. Editor final output remains Parallel; main multiple-output conversion is unchanged. Default editor camera separation remains 0.060.
- Installer patches current installed Swift source (does not replace with historical snapshot), adds WebKit link, compiles before mutation, preserves com.injectz.app.dev and original certificate root F676FD4BC9E1160E9F1E0C29FF8F3F0D06F4C592, creates timestamped backup and rolls back affected files on failed installation. No engine/renderer changes.
- Files: ~/InjectZ/Development/SHARPDepthEditor (editor modules); source appended with DepthEditor.swift controller. Sessions remain ~/InjectZ/Development/GuidedDepthSessions. Startup log is /tmp/InjectZ-Editor-UUID/startup.log, per-render diagnostics in session.log.
- Checks: all 11 R11 tests pass; corrected latest-source patch integration passes; duplicate-patch rejection passes; Python compileall and bash -n pass. Native Swift/WebKit compilation and Metal image-quality validation cannot run on Linux; required compilation/signature checks run before replacement on the Mac.
- Next: Ted installs, opens selected photo in native editor, confirms shortcuts/dialogs/resume and previews an edited sky. Preserve certificate and conversion engines in any follow-up.


## 2026-10-06 — context help, guide and tested IW3 default
- Ted requested compact circled question marks, hover What is this?, and clickable explanations for all depth-editor features. Added accessible buttons beside all static settings/actions, all 8 selected tools, and 7 saved-change control types.
- Native HTML dialog uses textContent (not HTML injection), modal focus, Close/Escape, return focus, and capture-phase editing-shortcut isolation. Help remains enabled while a renderer request is pending/busy. Dynamic saved cards receive help via MutationObserver; insertion is idempotent. No mask/geometry/render logic changed.
- Updated bundled InjectZ_User_Guide.html plus repository-friendly USER_GUIDE.md with editor workflow, a sky example, save semantics, gradient/rounded/feather, depth views, keyboard controls, output/session limitations and detailed control reference. Removed obsolete Keep Terminal open guidance from integrated interface.
- As authorized after the Whalom comparison: methodPopup initially selects forward_inpaint and nil fallback uses it. Depth Pro/strength choices and all other methods preserved. Evidence: mlbw_l2_inpaint gray-grid output; mlbw_l2 removed grid but doubled edges; forward_inpaint user reports markedly improved output. Root cause inside mlbw_l2_inpaint remains unproven; no upstream engine upgrade.
- patch_help.py handles pre-integration current source by applying integration once, or already-integrated source without duplication. Existing Custom Depth, centered Whitten credits, Help, Command-W and engine features retained. Resource guide replacement occurs in staged app before original-certificate signing.
- Tests: all 11 editor tests pass; help coverage and JS parse checks pass; modal behavior/current-tool topic/Escape/focus checks pass; patch accepts both source states and is idempotent; Python compileall and bash syntax pass. AppKit/WebKit/Metal validation remains on Ted's Mac.
- GitHub releases API currently returns []; documented Sparkle+signed appcast/public packaging plan in UPDATE_PLAN.md. No updater installed or automatic-update claim.
- Next: install INSTALL_EDITOR_HELP.command, inspect help buttons in embedded WebKit and app-menu guide, confirm IW3 new default on relaunch. Later define public versions/signing/helper packaging before implementing auto-updates.

## 2026-10-06 — Combined editor help and startup repair
- Installed editor reported no makeHelp function. Combined previously tested question-mark help and guide with the conditional process-group startup fix.
- Original app identity/signing preserved by existing installer; backups and rollback retained.
- Help coverage and UI tests passed; actual Mac display still requires user verification.

## 2026-10-06 — 0.3.0 release candidate
- Collected actual installed source from Ted; included working editor help/startup and current IW3 wrapper.
- Version/build metadata 0.3.0; added manual GitHub latest-release check with numeric semantic version comparison. No automatic download/execution.
- New setup/build includes WebKit, editor scripts and bundled guide. Existing-install update stages/signs/verifies before replacement and preserves external models/environments/sessions.
- macOS compilation and runtime verification pending on Ted’s Mac; do not publish as tested release until confirmed.
