# Inject Z — User Guide

Inject Z turns a normal photograph into a pair of slightly different views, one for each eye. When viewed using the appropriate stereo viewing method, the pair gives an impression of depth.

This guide explains the current photo-conversion app. If you have not installed it yet, start with the [README installation instructions](README.md) and [guided setup preview](SETUP_PREVIEW.md). A download of the source alone is not a ready-to-run installation.

## Your first conversion

1. Open **InjectZ.app** in the **InjectZ** folder inside your home folder.
2. Click **Choose Photo…** and select a photograph. You can also drag a photo into the main app window. The current interface selects one photograph at a time.
3. Select an **engine**: **SHARP (Gaussian splats)**, **IW3**, or **Apple Reframe**. Choose an engine whose setup is complete and whose model terms permit your use.
4. Choose a **depth** setting. With SHARP or Reframe, **Medium** is a useful starting point. With IW3, try **1.0 or 2.0** for an initial comparison; its default of 5.0 is considerably stronger.
5. Check the output format you want. If you are unsure, use **Parallel** for a side-by-side stereo pair, or **Anaglyph Dubois** if you have red/cyan glasses.
6. Leave **Allow window violations** unchecked for your first test. Leave the other optional controls alone.
7. Click **Convert** and wait for completion. If using Reframe, let the app operate Photos without clicking its controls or switching applications during processing.
8. On success, the result is saved beside your original photograph and opened using **Finder Quick Look**. Press **Space** or **Escape** to close Quick Look.

The app creates a separate result; it does not replace your original photograph. If a final output filename already exists, the app adds a number rather than overwriting it.

## Choosing an engine

### SHARP (Gaussian splats)

SHARP builds a representation of the scene, then renders two viewpoints. It can separate foreground objects from the background and create body/face contours, although its interpretation can still be wrong.

Use the **Depth** menu to adjust separation. If a shifted outline looks unnaturally sharp, see **SHARP Edge Softening** below.

SHARP needs its separate runtime, renderer and model. Its model is research-restricted: free or personal use does not automatically satisfy its agreement. See [third-party information](Docs/THIRD_PARTY.md).

### IW3

IW3 estimates a depth map, then uses it to construct stereo views. A depth map is an image that represents distance rather than ordinary colors.

When you select IW3, the **IW3 Model** menu appears. Choose a model you have already downloaded and prepared during setup. Selecting another model does not automatically install it.

Different models can interpret a photograph differently. If a result has halos, stretched backgrounds or incorrect object depth, try lower strength or compare another prepared model before changing many advanced settings.

### Apple Reframe

This uses the Reframe feature in Photos. Inject Z prepares two working copies and changes one eye's view, preserving the intentional one-eye workflow.

Photos must have Reframe available and use the separate **InjectZ Working Library.photoslibrary**. Accessibility and Photos automation permissions must be approved. The library guard blocks imports if it cannot verify the correct library.

During conversion, Photos comes to the front and its editor is operated automatically. Leave the controls alone until the run finishes or reports an error. Processing failures and available pan limits can vary by photograph. A daily quota has not been independently confirmed.

After successful completion, the app attempts to remove the temporary album. This cleanup is best effort; do not assume it permanently purges all imported media from Photos storage.

## Choosing output formats

You can check more than one format before clicking Convert. The app makes separate output files from the same stereo conversion.

| Format | What it means |
|---|---|
| **Parallel** | Full side-by-side stereo: left-eye view on the left, right-eye view on the right. Use a compatible stereo viewer or parallel free-viewing method. |
| **Crossview** | Side-by-side stereo with the eye order reversed, intended for cross-eyed viewing. |
| **Anaglyph Full Color** | Combines the eye views into a red/cyan image, preserving more color but potentially producing color conflicts or ghosting. |
| **Anaglyph Half Color** | A different red/cyan color treatment that reduces some color conflicts. |
| **Anaglyph Dubois** | Uses a color transformation intended to balance color and ghosting for red/cyan viewing. |

Anaglyphs require **red over the left eye and cyan over the right eye**. Their appearance also depends on the glasses and display. Ordinary side-by-side pairs require an appropriate stereo viewing method; simply looking at both halves normally will not produce the intended effect.

For comfortable viewing, reduce depth if the pair is difficult to fuse or causes eye strain.

## Understanding depth strength

More depth means greater separation between the two eye views. It can make the 3D effect stronger, but can also expose reconstruction errors, missing-background artifacts or uncomfortable disparities.

| SHARP / Reframe setting | Value |
|---|---|
| Low | 0.010 |
| Medium | 0.020 |
| Strong | 0.040 |
| Very Strong | 0.060 |

IW3 uses a separate **3D Strength** scale from **1.0 to 6.0**. Its numbers are not directly comparable to SHARP or Reframe numbers. A value of 0.060 and a value of 6.0 do not mean the same thing.

The appearance also depends on the photograph. The same setting can produce a strong effect on one photo and a weak effect on another. Reframe may not retain the full requested pan for every image; report any mismatch rather than assuming all slider settings produce identical depth.

## Stereo-window protection

Think of the stereo window as the frame around the picture. A distracting conflict can occur when an object appears in front of that frame while being cut off by its border.

Leave **Allow window violations** unchecked to use the app's protection. This is intended to keep border-cut objects behind the frame while allowing suitable fully visible objects to come forward. The protection depends on estimated depth/geometry, so it cannot guarantee a perfect result for every photograph.

Check **Allow window violations** only when you intentionally want to disable that protection and compare the result. IW3 also has a border-preservation option in its advanced panel; leave its default enabled for ordinary protected conversions.

## SHARP Edge Softening

This optional feature softens a narrow band around sufficiently large depth discontinuities. It does not apply a general blur to the whole photograph and does not simply blur every visible color edge.

1. Select **SHARP (Gaussian splats)**.
2. Click **SHARP Edge Softening…**.
3. Check **Soften depth edges**.
4. Start with **Radius: 2 pixels** and **Strength: 35%**.
5. Close the panel and convert. Compare with a conversion made with softening off.

**Radius** controls how wide the affected edge area is. **Strength** controls how much softening is blended into that area. Excessive values can produce halos or soften details unnecessarily.

Softening is off by default and resets to off when you relaunch the app. It adds processing work. It is not semantic protection for faces, text or hair: incorrect depth boundaries can affect details you wanted to keep. Image-quality testing of this new feature is ongoing.

## Advanced IW3 Settings

Click **Advanced IW3 Settings…** when IW3 is selected. The panel contains photo-related settings. Each **What is this?** button explains its setting and options.

For a first conversion, leave the advanced defaults alone. Change one setting at a time so you can tell which change helped. The displayed default is resolved from the installed IW3 version, with certain Inject Z overrides.

Depth resolution affects the depth-estimation work, not merely the saved photo's dimensions. Increasing it may improve some boundaries but can increase processing time; it does not guarantee better depth or preserve individual hair strands.

The advanced panel does not add video support to Inject Z.

## Additional controls

- **Save separate left/right images:** Requests separate eye images where supported by the selected engine. Check the files created after the run; support and retention differ between engine paths.
- **Generate Depth Map:** Currently available through IW3. The current GUI exports an editable layered PSD beside the source when the PSD helper succeeds; the native depth data stays in its internal run folder. This button does not itself generate the normal stereo output. SHARP and Reframe do not provide this export through the current GUI.
- **Show Result in Finder:** Reveals the last recorded result in Finder if you closed its preview or want to locate it again.
- **Resume Reframe…:** A recovery control for an interrupted run. Select the same original photo, then choose the existing run folder requested by the dialog. Use it only when you know which run you are recovering; do not guess among working folders.

## Where results go

Completed display images are saved in the same folder as your source photograph. Their names identify Inject Z, the engine, the output format and depth, for example:

`FamilyPhoto_InjectZ_SHARP_Parallel_Depth0.040.png`

Repeated conversions add a number when necessary. A run with several formats opens one result automatically; the other outputs are beside it in Finder. Internal working files and logs may remain under the InjectZ installation folder.

## Common problems

| Problem | What to do |
|---|---|
| Missing runtime, model or helper | Revisit the setup documentation. START_HERE.command assists with a new installation but does not repair an existing one automatically. |
| A newly selected IW3 model fails | Run DOWNLOAD_IW3_MODELS.command and prepare that model/method using the same cache paths. |
| Photos reports the wrong library or library verification fails | Stop. Open the dedicated working library; do not bypass the guard or use your personal library. |
| Reframe permission prompt repeats | Confirm that the correct installed app has Accessibility permission and that Photos automation is approved. Save the exact error; rebuilding or changing signing identity can invalidate approval. |
| Depth seems too weak or too strong | Try another strength on the same photo. Compare using the same viewing method and image size. |
| A shifted edge looks too sharp | Compare optional SHARP edge softening at modest settings. |
| SHARP reuses an incorrect scene after you edit/replace a same-named photo | Report it. The current reconstruction cache uses the photo's basename; stale cache reuse is a known limitation. Do not delete model weights or the whole installation as a remedy. |
| Conversion fails | Read the app's status and exact error. Some engine failures save an InjectZ Error Log on the Desktop; Reframe errors may identify preserved working files. Keep those for diagnosis. |

If asking for help, include the engine, selected model, depth, output formats and exact error. For quality problems, supply the original and the generated result if you are comfortable sharing them.

## Current limitations

The guided installer is a preview, model licenses differ, and conversions are AI estimates rather than exact reconstructions. Individual photos may contain incorrect depth, halos or invented background areas. Multiple concurrent SHARP conversions are not supported safely by the current extension-lock handling. Use one conversion at a time, and keep your original photographs.
