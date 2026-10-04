# Change history

## Source snapshot 2026.10.04

- Captured the currently installed Swift GUI, helpers, icon/header assets and dependency version inventories.
- SHARP: compute a scene-dependent far clipping distance rather than truncating distant geometry at the renderer's default of 100. The sky correction was confirmed by the owner in normal conversions.
- SHARP: optional narrow depth-boundary softening with independent radius and strength controls, disabled by default. Installed source verified; broad image-quality testing remains pending.
- IW3: restore strengths 1.0 through 6.0; retain the plain Inject Z window title.
- IW3: expose photo settings only, add per-setting explanations and display resolved defaults.
- IW3: use all four border strips when calculating protected convergence, while allowing interior objects to protrude when their depth permits.
- Retain multi-format output, Depth filename tokens, Reframe dimension normalization and window protection, successful-output Quick Look, error foregrounding, and completed-album cleanup.
- Remove the exported obsolete BeforeR15 backup from the repository package.
- Add setup/distribution documentation. No conversion behavior was changed during repository preparation.

## Source snapshot 2026.09.29

- Initial source upload for collaboration; includes multi-output GUI and Reframe size-normalization recovery.
