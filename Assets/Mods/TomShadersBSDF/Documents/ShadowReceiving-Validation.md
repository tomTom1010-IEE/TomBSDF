# Native Shadow Receiving Validation

Date: 2026-10-17. Unity 2019.4.9f1, D3D11, RTX 4070 Ti SUPER.
Gamma authoring with the unchanged KKSLinear-v1 adapter and linear float
validation targets. All Editor actions were explicit Codex Bridge commands.
No game/computer use, full distribution build, glass, SSR or KK port.

## Accepted Camera Regression

`CodexBridge/Reports/BSDF-ShadowReceiving/Render-20261016-184328-190`
passes **349 checks**, with **199 capture PNGs** and
`native-shadow-materials-comparison.png`. Receipt:
`CodexBridge/Outbox/20261017-receivers-026-full-render.result.json`.
The full report is UTF-8 JSON; individual checks retain errors and tolerances.

The comparison sheet has four columns: receiving off, receiving on, on repeated,
absolute RGB difference x16. Rows are plastic, metal, anisotropy, coat and film,
first ordinary Alpha and then BackFront. Images were inspected: changes follow
the caster footprint, while the environment reflection and layer features stay
visible. This is reflection/coverage, not glass transmission.

| Check | Result |
| --- | --- |
| Both entries, native directional/spot/point hard and soft shadows | Passed |
| Associated colored native lights: combined vs sum of single-light contributions | RGB MAE 6.2416e-10 for each entry |
| Emission + SH + Probe increment: shadowed vs unshadowed | RGB MAE 7.8505e-10 |
| Coverage/alpha unchanged by visibility | Exact in tested cases |
| Nested-camera parent image and capture-scope restoration | Exact in both entries |
| Opaque positive control while native copies are active | Exact |
| Perspective StableFit / CloseFit, native 1/2/4 cascade policies | Worst reference MAE 0.001354, under the 0.003 bound |
| Point six cube faces plus a face seam | Worst reference MAE 2.7373e-5 |
| Moving spot: transform, angle, near plane and range changes | Worst reference MAE 5.9019e-5; each case also proves a nonzero receiving contribution |
| Back faces: directional Base, local-light Add | Passed |
| Missing/disabled companion/resource, master off and map absence | Previous material output retained |
| Skipped native event and stale packet, abort cleanup, copy budget overflow | Passed |
| Renderer receiveShadows=false and indexed/non-indexed property blocks | Passed, original blocks restored |
| Coincident shadowed/unshadowed light keys | Safe native fallback, no cross-shadowing |

Reference MAEs include the declared raw-depth/filter approximation, not changes
to GGX or layered transport. The comparison uses an ordinary visible opaque
backdrop to make Unity schedule its native shadow maps. It is part of the test
scene, not a runtime proxy, and keeps a different opaque depth behind the Alpha
surface. Sampling follows the transparent surface position, not that backdrop.

## Native Availability Is Separate

`alpha-only-capabilities.json` in the same report records all six entry/light
combinations without an opaque receiver. On this host Unity did not generate a
native map; extension on/off RGB difference is exactly zero. These are **safe
resource fallback cases, not successful receiving support**. No extra shadow
camera, replacement caster renderer or invisible scheduling proxy was added.

Unsupported host/XR, more than eight selected native lights, copy-budget overflow
or ambiguous coincident light keys also retain the previous native transparent
path. The companion does not promote vertex/four-array lights to shadowed pixel
lights. See the contract for the eight-camera cache and 128-MiB default budget.

## Acquisition Defects Found And Corrected

Initial static native acquisition probes are saved as
`Render-20261016-171605-439` and `Render-20261016-171948-153`. Static cameras alone
were insufficient to verify metadata freshness. Subsequent failed smoke/full
reports are retained rather than overwritten:

- Alpha-only `Render-20261016-173636-491` exposed missing native scheduling.
- `Render-20261016-174539-483` exposed nested state and multi-light comparison issues.
- `Render-20261016-180555-990` proved early directional matrices can belong to another camera.
- `Render-20261016-182435-781` showed stale event light colors and spot matrices in mixed lighting.
- `Render-20261016-182826-689` compared native spot caster VP after the shadow pass and map events.

The corrected implementation establishes capture ownership before culling,
uses stable per-light hooks with GPU camera-target guards, pairs directional
late matrices with an actual depth-generation stamp, derives spot texture
coordinates from native caster VP, and does not use event color for identity.
Position/type collisions fail closed, including active unshadowed lights.
An earlier multi-light oracle also subtracted the transparent backdrop too many
times; it now subtracts the measured no-light composite for each contribution.
The final tests retain the original strict multi-light/nested tolerances.

## Compilation And Regression Receipts

The machine-readable aggregate is
`CodexBridge/Reports/BSDF-ShadowReceiving/result.json`, generated by
`Tests/summarize_shadow_receivers.ps1`. It requires the latest explicit full-render
receipt, selected Alpha native pass compilation, Realtime and Reference composite
compilation receipts, and the scene-buffer regression. An old passed image or
the existence of a bundle file cannot substitute for a failed/missing receipt.
Exact report paths and totals are recorded in that aggregate.

Final aggregate status: **passed**. Completed receipts are:

| Job | Saved Report | Result |
| --- | --- | --- |
| Alpha native pass compilation | `BSDF-Alpha/Compile-20261017-025020-858` | 18 / 18 selected programs |
| Realtime + native directional shadows, dual Probe and fog | `BSDF-AreaQuality/Compile-20261017-025943-928` | Passed, 214.355 s |
| BackFront front Base Reference + the same native features | `BSDF-AreaQuality/Compile-20261017-030318-287` | Passed, 202.562 s |
| Scene-color/depth-buffer regression | `BSDF-Stage4/SceneBuffers/Render-20261016-190640-853` | 168 checks, 65 captures |

Report paths in this table are relative to `CodexBridge/Reports/`. The six
static contract suites also pass; the aggregate verifies unchanged public
manifest and distribution-bundle hashes and records runtime/shader hashes.

These are selected native program and explicit camera checks, not an exhaustive
distribution build or live KKS performance/save-import acceptance. Shader import
and native compilation are still expensive. Existing AssetBundle Browser duplicate
immutable GUID errors are an unrelated template issue; source warnings and all
native command results remain in the Bridge logs/reports.

## Delivery Boundary

Companion/runtime 0.4.0 sources are built without warnings/errors and the authoring
runtime DLL matches the source build. The resource asset and copy-shader dependency
were bound through `preparebsdfreceivers` / AssetDatabase to the existing BSDF
bundle. No carrier material/prefab or public manifest property was added.

`manifest.xml` remains byte-identical to the before snapshot, including
`Koikatsu Sunshine`. The accepted BRDF/coat/film/Probe/AA source is frozen; the
Forward change is exactly an Alpha-gated adapter include and attenuation call.
The distribution bundle remains unchanged at SHA256
`9EC10C0BF0C4A0563513CED444FBA140D26DBC2DD9859C01A14283B42B138C94`.
No new binaries or package were deployed to the game.
