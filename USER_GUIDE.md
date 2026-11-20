# Inject Z — User Guide

Inject Z turns a normal photograph into a pair of slightly different views, one for each eye. When viewed using the appropriate stereo viewing method, the pair gives an impression of depth.

This guide explains the current photo-conversion app. If you have not installed it yet, start with the [README installation instructions](README.md) and [guided setup preview](SETUP_PREVIEW.md). A download of the source alone is not a ready-to-run installation.

## Your first conversion

1. Open **InjectZ.app** in your **InjectZ** folder, or use your existing Dock icon.
2. Click **Choose Photo…** for a 2D photograph, or drag one image into the window to load it as a 2D photo. See **Open an existing stereo image** for stereo inputs.
3. Select an **engine**: **SHARP (Gaussian splats)**, **IW3**, or **Apple Reframe**. Choose an engine whose setup is complete and whose model terms permit your use.
4. Choose a **depth** setting. With SHARP or Reframe, **Medium** is a useful starting point. With IW3, try **1.0 or 2.0** for an initial comparison; its default of 5.0 is considerably stronger.
5. Check the output format you want. If you are unsure, use **Parallel** for a side-by-side stereo pair, or **Anaglyph Dubois** if you have red/cyan glasses.
6. Leave **Allow window violations** unchecked for your first test. Find it under **Additional Export Options**; the section may remain collapsed.
7. Click **Convert** and wait for completion. If using Reframe, let the app operate Photos without clicking its controls or switching applications during processing.
8. On success, the result is saved beside your original photograph and opened in an Inject Z preview window. Close the preview when finished.

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

## Additional Export Options

The five common stereo-format checkboxes stay on the main screen. Click **Additional Export Options** to expand or collapse the other settings; collapsing it does not clear them. The green window button can expand the app.

- **Left / Right / Left** saves three images across: the first two support parallel free viewing and the last two support cross-eyed viewing.
- **Parallel above Crossview** saves the parallel pair above the crossview pair.
- **Black border** selects a black border around each finished eye. Its percentage is based on the shorter side of the image. **Corners** rounds each finished eye against black. These are finishing operations after conversion.
- **Save separate left/right images** is available for SHARP and imported stereo images. It exports a separate file for each eye.
- **Allow window violations** turns off automatic window protection when checked. Leave it unchecked unless you deliberately want to compare or allow an object to cross the window.

## Open an existing stereo image

You can reformat an existing stereo pair without making a new 2D-to-3D conversion.

1. Choose **File → Open Stereo Image…** and select **Parallel (Left / Right)** or **Crossview (Right / Left)** in the arrangement dialog. A single image dropped onto the app is loaded as a 2D photo.
2. To use two separate eye files, choose **File → Open Left and Right Images…** and select exactly two images, or drag both onto the app. The dialog shows their filenames; choose which is the left eye.
3. Select one or more output formats, optional framing, and, if desired, **Save separate left/right images**. Click **Convert**. Inject Z uses the imported eyes for still-image outputs rather than generating a replacement pair.

Use full-width side-by-side images, with equal-sized left and right halves and an even total width. Separate eye images must have the same pixel dimensions. The app does not automatically identify the eye order or correct a squeezed half-width side-by-side image; expand it to full-width first. Existing stereo inputs are not automatically aligned or cropped. Originals are kept intact.

To make a SHARP wigglegram or view sequence from an existing pair, select **SHARP** and enable the desired option below. Inject Z extracts the **left eye** and builds a new SHARP reconstruction from that eye alone. The right eye is still used for ordinary stereo exports, but does not help construct the wigglegram, whose endpoints may differ from the original pair.

## Multi-frame wigglegrams and PNG views

A wigglegram is a 2D animation that moves through a series of viewpoints and back again. It is not a side-by-side stereo video. This option currently uses **SHARP**.

1. Select a photo or open an existing stereo pair, select **SHARP**, and choose a depth setting. Open **Additional Export Options**.
2. Check **Multi-frame wigglegram (SHARP)** for an MP4. Choose **Middle frames** and the playback speed in frames per second. More middle frames provide more viewpoints; at the same playback speed, they also make each back-and-forth cycle longer. The MP4 contains five cycles.
3. Optionally check **Export all views as PNGs**. The PNGs can be exported on their own or together with the MP4. Click **Convert**. Results are saved beside the source image; the PNGs go in their own numbered folder.

After SHARP builds the scene, a **Choose the wigglegram pivot** preview appears. Click the person or object you want to keep approximately steady, then choose **Use Selected Point**. Other parts at similar depth also stay relatively steady. Choose **Use Automatic** to keep the previous automatic alignment, or **Cancel** to stop. The selected pivot affects the wigglegram and exported PNG views, not the still stereo formats. A selected pivot uses the same-sized crop for every view and removes some material at the sides; SHARP may still produce edge artifacts. Reducing the depth setting can reduce this crop. If no usable geometry is found at the click or the crop would remove the whole image, try another point or a lower depth setting.

The number in **Middle frames** excludes the two end views. For example, 8 middle frames produce 10 PNGs; 60 middle frames produce 62. The PNG sequence runs once from left to right, including both ends, without the repeated return frames from the video. The files are lossless RGB PNGs, named in numeric order, with matching dimensions. If stereo-card framing, a border or rounded corners are selected, those finishing choices are included in the views.

For lenticular printing these images are source views, **not an interlaced print file**. Separate interlacing software and the correct lens pitch and print settings are needed. Ask the printer which number and order of views it needs; more views do not always mean a better print. Large images and many views need more processing time and disk space.

SHARP estimates a scene from a single image. It may invent or blur hidden areas and may produce artifacts, especially with larger depth settings. Window protection can crop the sides of SHARP results, sometimes substantially; compare a lower depth setting if needed.

## Borders and stereo-card framing

**Black border** and **Corners** finish the exported eyes after conversion; they do not change the photo used to estimate depth. To use the arched card design, check **Stereo-card frame**, choose its background with the color well, and optionally enter a **Title**. This selected card design is used in place of the ordinary black-border and corner choices.

The card frame is added after SHARP renders its views. Its arch masks the upper corners of the finished picture. If an old card's existing corners confuse SHARP, first provide a rectangular image without those corners; Inject Z does not automatically reconstruct them before processing.

The card applies to selected still formats, separate-eye exports, wigglegrams and exported PNG views. For a stereo pair, the same frame and caption appear in both eyes at matching positions, at the card/window plane. In a wigglegram there is one centered caption under the moving view. A blank title gives a narrow bottom border; a caption reserves a deeper bottom area and can wrap onto two lines. Extremely long captions may need shortening. You can save these choices in a preset.

## Save and recall presets

1. Set the engine, depth, output formats and other options as desired.
2. Open **Additional Export Options**, click **Save as a Preset…**, enter a name and click **Save**. Reusing a name asks before replacing the saved settings.
3. Choose a saved name from the **Preset** menu to restore its settings. **Delete…** removes the chosen preset after confirmation.

Presets include the selected engine and its settings, formats, separate eyes, window option, SHARP edge softening, advanced IW3 choices, framing, wigglegram, PNG views and their settings. They do not include the selected photo. Saved presets remain available between launches; selecting one does not start a conversion.

## Open other apps from Inject Z

Use the **Apps** menu to open Ted's Video Tool, StereoMask for Mac, VM ReSizer, or Stereo Slideshow. These apps are separate downloads, not bundled inside Inject Z.

If a listed app isn't found, its dialog offers **What is …?** for an offline description, **Download from GitHub** for the project and its installation instructions, or **Navigate to it** to find an already-installed copy. When you locate it, Inject Z remembers the path for that existing menu item. If an old added shortcut points to exactly that same app, Inject Z removes the duplicate shortcut.

To link another installed application, use **Apps → Add an App…** and choose its application file. **Apps → Remove an Added App…** removes a custom shortcut, not the application itself. If an app is moved or renamed, locate it again or replace the custom shortcut.

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

Leave **Allow window violations** unchecked to use the app’s protection. SHARP estimates the nearest foreground and shifts the views to place it behind the window; the common overlap may crop the sides, sometimes substantially. Protection depends on estimated geometry, so it cannot guarantee a perfect result for every photograph.

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

The advanced IW3 panel does not add general video conversion to Inject Z. SHARP can export the wigglegram animation described above.

## Additional controls

- **Save separate left/right images:** In Additional Export Options, save separate eye images for SHARP or an imported stereo pair.
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

## App updates

Choose **Help → Check for Updates…** to check for and install updates; the same command is also in the **Inject Z** menu. **Automatically Update While Closed** appears in both menus and controls the same setting. Finish a conversion and save or close the depth editor before installing an update. Models, runtimes, settings, saved sessions and the icon are retained. For troubleshooting, see `~/InjectZ/Updates/update.log` and `automatic.log`.
