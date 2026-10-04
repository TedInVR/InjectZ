# Before offering an out-of-the-box release

- Record exact SHARP, nunif and metal-gauss commit IDs and any local third-party changes. Inspect the installed source locations and package provenance; the current export only records versions.
- Verify all required model download URLs, hashes, licenses, sizes and compatible versions. Retain full license/notice texts for bundled components; show research restrictions for SHARP.
- Choose a license for Inject Z's original code and artwork.
- Make and test a first-time installer on a fresh Apple Silicon Mac; test missing models, failed/interrupted downloads, disk-space failures and reruns.
- Prepare stable distribution signing/notarization without shipping signing secrets. Verify permission persistence across upgrades.
- Validate all selected output formats, original file preservation, non-overwriting final outputs and Finder Quick Look.
- Validate IW3 photo wrapper against the pinned nunif commit and confirm its all-border window behavior.
- Verify SHARP sky repair and optional softening on diverse photos. Fix basename-only cache collisions and extension-lock ownership before concurrent work is supported.
- Verify Reframe OS availability, library isolation, import/export, dimension normalization and cleanup. Do not promise an unverified quota or complete media purge.
- Publish source and a versioned release ZIP separately, with a clearly described support matrix. Keep model/runtime binaries out of source control.
