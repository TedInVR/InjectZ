# SHARP Manual Depth Editor — integrated help update

Open from Inject Z’s Manual Depth Editor button. Read the full guide in the app’s Help menu or ../USER_GUIDE.md. Each circled question mark explains its control.

## Navigation
- Hold Space and drag on the image to pan horizontally or vertically. Release Space to return to your editing tool.
- Tap [ or ] to shrink or enlarge the brush; holding repeats. Command-brackets also work.
- Point at an area, hold Z and press + / − to zoom there. Z + 0 returns to Fit; maximum zoom is 32×.
- Undo and Redo cover direct brushes and rectangles (Command-Z / Command-Shift-Z).

## Preview without saving another output
Save Changes first. Click Preview Stereo Pair to see the stereo result below the controls. It uses the same rendering and optional sky repair as final output, but saves no new picture beside your original. The session retains only the latest preview image; temporary renderer outputs are removed.
Click Render Stereo Pair when you want a finished PNG beside the original. Existing outputs are never overwritten.

## Shaping a depth change
1. Select or revise an Object depth adjustment and refine its selected area.
2. Choose Uniform shift, Directional gradient, or Rounded adjustment.
3. For a shaped change, click Draw Shape Guide and drag on the photo:
   - Directional: start where adjustment should be zero, end where it should reach the full entered amount. Between them it changes smoothly in a straight direction.
   - Rounded: start at the strongest center, end at the zero-strength radius. It fades smoothly outward within that circle.
4. Enter the depth adjustment: positive = nearer, negative = farther.
5. Optional Edge feather fades the adjustment inward along all selection boundaries. Its width uses selection-image pixels, not original-resolution pixels. It never expands the mask.
6. Save Changes, then Preview Stereo Pair. Shape settings and guide positions belong to that saved change and return when you choose Revise This.

Sky/background repair deliberately uses Uniform shift because the repaired background is one distant plane. Use an Object depth adjustment for gradients or rounded shaping. SHARP’s original contours remain underneath these adjustments; this is not a new prediction or guaranteed reconstruction of hidden surfaces.

## See the model as depth
Click Update Depth Views. The first time, the editor builds a fresh SHARP reconstruction; subsequent views reuse that session model. This action does not run LaMa background inpainting.
Choose Photo, Original depth, Adjusted depth, or Photo + adjusted depth above the image. White means nearer; dark means farther or uncovered. Original and adjusted views use the same scale from the original model, with extreme values clipped for visibility. The views project the actual splats; they do not run another depth-estimation model. Splats blend at edges, and hidden surfaces are not visible.
When sky repair is enabled and a saved sky change is present, the adjusted depth view includes the distant background plane. After changing saved selections or their settings, click Update Depth Views again. Save your latest working corrections before previewing or updating views.

## Saved changes
Apply in next render enables or disables a saved change without deleting it. Revise This loads its selection and shape. Save Changes replaces that active saved change. New Separate Change starts an independent selection. Merging keeps the newest change’s depth/shape settings; it does not add adjustment amounts together.

## Checks and limits
Geometry, masks, shape falloff, alpha/plane composition, shared depth scaling, session endpoints, keyboard navigation, and mocked preview/final-output orchestration were checked in the development environment. Actual Apple Silicon/Metal rendering and visual quality must be checked on your Mac. No model weights are bundled. Detailed failures are recorded in the session.log path shown by the editor.
