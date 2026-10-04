# Third-party components and distribution

Checked October 4, 2026. Upstream terms are authoritative; do not treat this summary as a substitute for their license text. No third-party engine sources, runtime binaries or model weights are bundled in this source snapshot.

| Component | Official source | Distribution considerations |
|---|---|---|
| Apple SHARP code | https://github.com/apple-aiml-research/ml-sharp | Read LICENSE and ACKNOWLEDGEMENTS; code terms differ from model terms. |
| SHARP model weights | https://github.com/apple-aiml-research/ml-sharp/blob/main/LICENSE_MODEL | Apple's research model agreement restricts use and derivatives to non-commercial scientific research/academic development. It excludes commercial exploitation and product development/use in a commercial product/service. Redistribution requires the agreement and specified attribution. Automatic download does not change these terms. |
| nunif / IW3 | https://github.com/nagadomi/nunif | Project code is MIT; retain notices. Each selected depth/inpainting model needs its own license review. |
| metal-gauss | https://github.com/nandometzger/metal-gauss | Capture the license/notices from the exact installed revision before distributing binaries or vendoring code. Current version label alone does not establish the revision. |
| PyTorch and Python packages | See Setup/DependencyInventory.json | Inventory is evidence of installed versions, not a verified redistributable lockfile. Capture licenses of every included package and native component. |
| PyAV / FFmpeg | https://github.com/nagadomi/nunif | Upstream warns binary builds may be GPL because PyAV wheels can include GPL FFmpeg. Check the actual build and fulfill its corresponding source/license obligations if bundling. |
| Photos Reframe | Apple operating system feature | Not redistributed here. Availability and permissions depend on the user's system. |

Do not include personal photographs, Photos libraries, signing private keys, certificates used for the owner's local trust, cached reconstructions or private correspondence in a public package. Okano Izumi's private Splat Stereo source is not included or integrated in this snapshot.

No open-source license has yet been selected for original Inject Z code. Preserve this status until the owner chooses a license; do not invent a license on their behalf.
