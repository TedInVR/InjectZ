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
| Very Strong (default) | 0.060 |
| Extra Strong | 0.080 |
| Maximum | 0.100 |
| Extreme | 0.120 |

SHARP also offers **Custom depth…**, from 0.001 to 10.000. Large values can reveal serious reconstruction errors; increase gradually. These are camera-separation controls, not distances in feet or meters.

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

The default photo method in this update is **forward_inpaint**, with **Depth Pro** and strength **5.0** retained. In our Whalom Park comparison, this avoided the repeating grid/gray sky from mlbw_l2_inpaint. It can still create halos or inaccurate boundaries. The other methods remain available for experiments.

The advanced panel does not add video support to Inject Z.

## SHARP Manual Depth Editor

Use this when a SHARP conversion puts something at the wrong depth. It changes the reconstructed scene rather than retouching the original photograph.

### Open it

1. Select the **original 2D photo** in the main Inject Z window and select **SHARP**.
2. Click **Manual Depth Editor…**, or choose **SHARP → SHARP Manual Depth Editor…**.
3. If asked, choose **Resume Selection** to continue saved changes for this exact photo, or **Start Fresh**.

You do not have to run a regular conversion first. The editor creates its own SHARP reconstruction on the first preview, final render or depth-view request. It reuses that session model for later adjustments. It does not open the last stereo PNG or reuse a model held in the main app’s memory. The same model and source normally give comparable geometry, but this is not a promise of a pixel-identical final render.

### Example: move the sky farther away

1. Select **Automatic selection box** under Direct tool. Drag a box around the sky region you want the selector to examine.
2. Choose **Automatic include sample (+)** and click a few representative sky areas. Choose **Automatic exclude sample (−)** and click foreground objects that must stay out of the selection.
3. Click **Find Selection**. Inspect the highlighted area. Automatic samples guide the selection; they do not guarantee exact exclusion.
4. Refine it with **Exclude brush** or **Exclude rectangle** to remove unwanted areas, and **Include brush** to add missed sky. Direct corrections stay locked when automatic selection is recalculated. You do not need Find Selection after brushing.
5. Protect lettering: for now, an Exclude rectangle around the whole text block is easier than selecting individual letters. The tool does not automatically recognize and protect text.
6. If the sky selection touches a person’s outline, try **Selection size: −4** to trim all patches inward. Inspect the result before saving. The amount uses selection-image pixels, not full-resolution pixels.
7. Name it **Sky**, choose **Sky/background repair**, set **Depth adjustment** to a modest negative value such as **−0.15**, and use **Uniform shift**.
8. Click **Save As New Change**. The change appears in Saved changes on the right. When revising it later, the button becomes **Save Changes**: click that to commit each round of refinements to the same change.
9. Leave **Repair exposed sky** checked and click **Preview Stereo Pair**. The first use may take longer while the SHARP model is created or background-repair weights download. Inspect the stereo preview below the controls.
10. When satisfied, click **Render Stereo Pair**. It saves a Parallel PNG beside your original without overwriting existing files. Preview does not add output files beside your original.

Sky repair requires exactly one enabled negative Sky/background change. It builds one background shared by both eyes and places it on a distant plane. It guesses hidden content and cannot guarantee correct details. Overlapping object changes and large adjustments may still create artifacts.

### Revise a saved change or start another

- **Revise This** loads that change’s mask, amount and shape. Refine it and click **Save Changes**. Merely brushing does not update the saved mask.
- **New Separate Change** starts a new selection without removing saved changes. Use it for a different object; save the current change first.
- **Apply in next render** is the enable checkbox. Uncheck it to compare without deleting the change.
- **Include in merge** only marks changes for merging; it is not the enable checkbox.
- To combine revisions of the same sky, check them and use **Keep newest selection (revisions)** followed by **Merge Checked Changes**. It keeps the newest mask, amount and shape. **Combine selected areas** unions their masks and may restore pixels removed in a later revision. Amounts are never added together by merging.
- **Use Current Selection** assigns the working mask to a saved change for revision. Click Save Changes to commit it. Usually Revise This is the clearer choice.

### Make a smooth or curved correction

For objects, choose **Object depth adjustment**, not Sky/background repair. This preserves existing SHARP contours while changing their depth.

- **Uniform shift:** the same entered amount throughout the selection.
- **Directional gradient:** choose this, click Draw Shape Guide, and drag from the place needing **zero** adjustment to the place needing the **full** adjustment. For a piece that should move back more on its right side, use a negative amount and drag left-to-right.
- **Rounded adjustment:** drag from the strongest center to the radius where the adjustment should fade to zero. Useful for a localized curved correction.
- **Edge feather:** fades the adjustment inward around the selection boundary. It does not expand the selection or blur the whole photo.

Positive Depth adjustment means nearer; negative means farther. Start small, save, and preview. These controls do not rerun SHARP with verbal instructions or recover guaranteed hidden geometry.

### View the model as a depth map

Click **Update Depth Views**, then choose **Original depth**, **Adjusted depth**, or **Photo + adjusted depth**. White means nearer; dark means farther or uncovered. Both grayscale views use the same scale, based on the original model. They project the actual Gaussian splats, not a new depth estimate. Save changes and update these views after revisions.

### Navigation, selection visibility and help

| Action | How |
|---|---|
| Move around a zoomed image | Hold Space and drag in any direction. |
| Zoom at the cursor | Hold Z and press + / −; Z+0 returns to Fit. Maximum is 32×. |
| Resize a brush | Tap [ or ]; hold to repeat. The circle shows its footprint. |
| Undo/Redo a direct stroke or rectangle | Undo / Redo, or Command-Z / Command-Shift-Z. |
| Remove an automatic sample dot | Point at it and press Delete, then confirm. |
| See the selection more clearly | Choose bright/striped overlay or Mask only; adjust Color, Visibility and Gentle pulse. |
| Explain a control | Hover over its circled **?** for “What is this?”; click for an explanation. Close or Escape dismisses help. |

Undo/Redo covers direct brushes and rectangles. It does not undo every action or restore deleted saved changes. Sample dots may disappear when a saved mask is loaded or a new selection is started; the saved mask itself remains available.

### Close or continue an editor session

Command-W closes the editor window while keeping its session available. Reopen it from the SHARP menu. **New Editor Session for Selected Photo…** stops the old session and starts one for the main app’s selected photo. **Close Editor Session** stops it so you can use regular Convert again. Save changes before either action or before quitting Inject Z. Quitting stops active editor rendering. Saved selections remain on disk for resuming.

The integrated editor currently exports **Parallel** pairs. The main app’s multiple-output checkboxes apply to regular conversions. Do not run the standalone editor alongside the integrated editor.

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

## Editor control reference

The same explanations are available from the circled question marks in the editor.

### Selection tools

**Exclude brush** — Drag to remove selected pixels beneath the brush circle. It changes only your stroke and overrides automatic selection in that area. Find Selection is not needed afterward. Use brackets to adjust radius and Undo to reverse a stroke.

**Include brush** — Drag to add pixels beneath the brush circle to the selection. It changes only your stroke, even if the automatic selection disagrees. You need an existing selection first. Find Selection is not needed afterward.

**Exclude rectangle** — Drag a rectangle to remove all selected pixels inside it. Useful for protecting an entire text block or foreground object. It does not recognize individual letters. This correction stays locked when Find Selection is recalculated.

**Include rectangle** — Drag a rectangle to add every pixel inside it to the selection. It is a direct geometric edit, not automatic object recognition. Undo reverses the last direct rectangle.

**Draw Shape Guide** — Choose Directional gradient or Rounded adjustment first. For a gradient, drag from zero adjustment to full adjustment. For rounded shaping, drag from the strongest center to the zero-strength radius. The guide controls how the entered amount varies inside the selected area.

**Automatic selection box** — Drag a box around the area the automatic selector should examine. Drawing the box alone does not create a mask. Add samples as needed and click Find Selection. A box is not a direct include rectangle; it guides the automatic calculation.

**Automatic exclude sample** — Click to place a red sample on something the automatic selector should exclude, such as a person or propeller. Then click Find Selection to recalculate. Samples are guidance, not hard pixel locks; direct Exclude brush or rectangle corrections provide locks. Point at a sample and press Delete to remove it.

**Automatic include sample** — Click to place a green sample on an area the automatic selector should include, such as the sky. Click Find Selection afterward. Samples guide the calculation but do not guarantee every nearby pixel is included. Use direct Include brush for an exact correction.

### Editor settings

**Direct tool** — Choose how to change the selected area. Automatic tools help create the first selection. Direct brushes and rectangles make precise corrections to the existing highlight. The question mark explains the tool currently selected.

**Brush radius** — Controls the circle painted by an Include or Exclude brush. Radius 5 means about 10 selection-image pixels across. Tap [ to make it smaller or ] to make it larger. The circle follows zoom; it shows what will be painted.

**Zoom** — Fit shows the whole image. Larger values enlarge it for precise work, up to 32×. Point at the desired area, hold Z and press + or −; Z+0 returns to Fit. Hold Space and drag to move your view without painting.

**Selection display** — Bright overlay colors selected pixels. Striped overlay adds a pattern to make small patches easier to see. Mask only shows selected areas in white and unselected areas in black. This changes visibility, not the selection or output.

**Highlight color** — Choose green, magenta or amber so the selection stands out against your photograph. This display color does not change the finished image.

**Visibility** — Controls how strongly the selection highlight covers the photo. Increase it to find tiny selected patches; decrease it to see image details underneath. It does not change depth.

**Gentle pulse** — Slowly varies the selection highlight so small patches attract your attention. Turn it off for a steady highlight. It does not change selected pixels.

**Image view** — Photo shows the source. Original depth shows the unedited SHARP splats as a grayscale depth view. Adjusted depth includes saved enabled changes. Photo + adjusted depth overlays depth on the photo. White means nearer and dark means farther or uncovered. Click Update Depth Views after changing saved changes.

**Shrink or expand selection** — Negative values shrink all selected patches; positive values expand them. Start at 0. Try −4 or −5 to leave space near a foreground edge. Values use the smaller selection image’s pixels, not screen pixels or full-resolution pixels. Each value is measured from the current un-resized mask; it is not added repeatedly.

**Selection size in pixels** — Enter the same shrink/expand value as the slider, from −20 to +20. Negative shrinks; positive expands. Reset to 0 restores the un-resized selection. Save Changes afterward to include this adjustment in the render.

**Change name** — Give this selected area a useful name, such as Sky or Right sleeve. Names help identify saved changes and do not affect depth.

**Change type** — Sky/background repair is for a background you want farther away; it uses a uniform change and can reconstruct exposed background. Object depth adjustment changes existing splats and supports gradients or rounded shaping. These are different operations; use Object for shaped foreground corrections.

**Depth adjustment** — Positive values move selected splats nearer; negative values move them farther away. Start gently, such as −0.15 for sky or +0.15 for an object. This is not a distance in feet or meters and is separate from camera spacing. The change preserves the existing contours, with optional shaping. Range: −0.9 to +2. Save Changes before previewing.

**Depth shape** — Uniform shift applies the full adjustment throughout the selection. Directional gradient smoothly rises from zero at the guide’s start to the full amount at its end. Rounded adjustment is strongest at the guide’s start and fades to zero at the guide’s radius. Click Draw Shape Guide and drag to position it. Sky repair uses Uniform shift.

**Edge feather** — Fades the depth change inward from the selection boundary. 0 means no feather. A larger width makes a smoother transition back into the original model. It does not expand the mask or blur the whole photograph. Width is measured in selection-image pixels.

**Camera spacing** — Sets separation between the two rendered viewpoints, like the SHARP depth strength in the main app. Default is 0.060. Larger values increase visible parallax and may reveal missing geometry or artifacts. This is independent of each saved change’s Depth adjustment. Range: 0.001 to 10.

**Repair exposed sky** — Uses LaMa to reconstruct a shared background and places it behind the scene. Requires exactly one enabled negative Sky/background repair change; object changes may also be enabled. The first use may download repair weights. The same reconstructed background is used for both eyes. It makes a guess, not a guaranteed recovery of hidden detail, and is intended for sky/background rather than faces or lettering.

**Merge method** — Keep newest selection is for several revisions of the same area: it retains the newest mask, including its exclusions. Combine selected areas unions the masks and can bring back pixels excluded in a later revision. Both keep the newest change’s amount and shape; amounts are not added together. Check Include in merge on at least two changes, then Merge Checked Changes.

### Editor buttons

**Find Selection** — First draw an Automatic selection box and add include/exclude samples if needed. This button calculates an automatic mask. It can reconsider areas throughout the box, but direct brush and rectangle corrections are reapplied afterward. After direct painting, you do not need to click this again.

**Undo** — Reverses the most recent direct brush stroke or direct rectangle. Command-Z also works. It does not undo automatic sample dots, saved-change deletion or all other actions.

**Redo** — Restores the last undone direct brush stroke or rectangle. Command-Shift-Z also works. A new direct stroke clears the redo history.

**Update Depth Views** — Builds the editor’s SHARP model on first use, then projects its actual splats as original and adjusted depth views. It does not run another depth estimator or LaMa inpainting. Save Changes first. Both views share the same grayscale scale so you can compare them.

**Shrink by one pixel** — Decreases the selection-size value by 1. It trims all disconnected selected patches at once. Save Changes before previewing.

**Expand by one pixel** — Increases the selection-size value by 1. It expands all disconnected selected patches at once. Save Changes before previewing.

**Reset selection size** — Returns shrink/expand to 0 and restores the un-resized selection. Direct brush and rectangle corrections remain.

**Clear Direct Edits** — Removes all direct brush and rectangle corrections after confirmation. The automatic selection remains. Use this only if you want to start the manual refinement again.

**Save this change** — Save As New Change adds the current mask, name, amount, type and shape to Saved changes. Once revising an existing change, Save Changes updates that same change. Brush strokes are not automatically committed to the saved mask: click Save Changes before a preview or final render.

**New Separate Change** — Starts a fresh independent selection and removes the current highlight and sample dots from the workspace. Existing saved changes remain on the right. Save the current change first if you want to keep it. Use this when changing a different part of the image.

**Draw Shape Guide** — Choose Directional gradient or Rounded adjustment first. For a gradient, drag from zero adjustment to full adjustment. For rounded shaping, drag from the strongest center to the zero-strength radius. The guide controls how the entered amount varies inside the selected area.

**Remove Last Saved Change** — Deletes the last saved change after confirmation. It does not undo a brush stroke. There is no saved-change deletion redo; use Apply in next render to compare without deleting.

**Clear All Saved Changes** — Deletes every saved change after confirmation. Your current working selection stays available. This cannot be undone with the brush Undo button.

**Preview Stereo Pair** — Renders your enabled saved changes and displays the latest Parallel stereo preview below the controls. It does not save another output beside the original. The session keeps only the latest preview. Save Changes first.

**Render Stereo Pair** — Creates a final Parallel PNG beside your original photo. Existing files are not overwritten; a number is added if needed. Use Preview Stereo Pair for repeated tests and render when satisfied. The editor currently saves Parallel, even if other formats are checked in the main app.

**Merge Checked Changes** — Check Include in merge on at least two saved changes and choose a merge method. The selected changes become one, using the newest amount and shape. Merge is not an addition of their depth amounts. Save the working selection before merging.

### Saved-change controls

**Apply in next render** — Enables or disables this saved change without deleting it. Uncheck it to compare your result with and without this change. A disabled change is skipped by previews and final renders.

**Saved change name** — Rename this saved change for reference. Changing this field updates the name immediately; it does not change the selected pixels.

**Saved depth adjustment** — Changes this saved change’s amount immediately. Positive is nearer; negative is farther. Shape and selection stay the same. Preview again to inspect the result.

**Revise This** — Loads this saved mask, name, amount and shape for refinement. After changing the mask or main controls, click Save Changes to update this same saved change. It does not create a second change unless you deliberately start a new one.

**Use Current Selection** — Assigns your current working mask to this saved change for revision. It loads that saved change’s name, amount and shape and marks the mask as unsaved. Click Save Changes to commit it. Use Revise This if you want to load the saved mask instead.

**Delete saved change** — Deletes this saved change after confirmation. This is separate from brush Undo/Redo. Disable Apply in next render if you only want to compare without losing it.

**Include in merge** — Marks this saved change for Merge Checked Changes. It does not enable or disable the change’s effect. Apply in next render controls whether it affects the output.
