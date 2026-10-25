# POM-v2 Local Self-Shadow Validation (2026-10-19)

## Scope

KKS Unity 2019.4.9f1 / D3D11, RTX 4070 Ti SUPER, current Gamma authoring project
with the unchanged KKSLinear-v1 adapter. All native compilation, temporary
materials/scenes, float rendering and readback used explicit claimed Codex Bridge
commands. No computer use, production scene edits, bundle build, game deployment,
KK adaptation, rectangle self-shadow, Glints or geometry displacement.

`CodexBridge/Reports/BSDF-POMSelfShadow/result.json` is **passed**: 24 aggregate
checks verify completed Bridge results, current source hashes, native programs,
render results, opposite timing orders and static contracts. Every selected run
stamps eleven shader/include/probe files. The independent pre-change POM-v1 source
oracle is `Before-20261018` in that report root, outside Assets. The physical
BRDF/layer/area/coverage libraries remain byte-unchanged; only the height library,
height declarations, forward/Unity light adapters and two property lists change.

## Saved Evidence

Folders are relative to `CodexBridge/Reports/BSDF-POMSelfShadow`. Render directory
names use UTC; native compile names and Bridge result timestamps use local time.

| Batch | Selected folder | Checks / captures |
| --- | --- | --- |
| Disabled / neutral independent-source regression | Render-20261018-155617-609 | 220 / 140 |
| Independent analytic step-field and finite endpoints | Render-20261018-155221-211 | 31 / 16 |
| Directional / point / spot, native map plus local visibility | Render-20261018-155221-472 | 34 / 17 |
| Four-array, mixed pixel lights, layered coat/film and published RGB | Render-20261018-163808-044 | 94 / 55 |
| Bare / metal / anisotropy / independent coat normal / film | Render-20261018-160100-378 | 90 / 50 |
| Original Cutout coverage and native caster | Render-20261018-160102-003 | 22 / 13 |
| Motion, grazing, mirrors, fade, curved coat/film and UV pole | Render-20261018-161808-441 | 45 / 34 |
| Unchanged Realtime / Reference rectangle integration | Render-20261018-160102-777 | 12 / 6 |
| Total selected rendering | Eight batches | **548 / 331** |

The 331 captured PNGs are accompanied by four comparison sheets:

- `Render-20261018-155221-472/pom-local-native-lights-comparison.png`
- `Render-20261018-163808-044/pom-local-four-lights-comparison.png`
- `Render-20261018-160100-378/pom-local-layered-materials-comparison.png`
- `Render-20261018-161808-441/pom-local-curved-layered-comparison.png`

Native/light/layer sheet columns: Off / On / local visibility / difference x16.
Curved sheet: Off / Realtime / Reference / Realtime-Reference difference x16.
Images use the same display mapping; calculations compare linear float targets.

Additional unchanged-material regressions pass: 64 glass checks / 17 captures at
`CodexBridge/Reports/BSDF-Glass/Render-20261018-160826-791`, and 80 POM-neutral
opaque/cutout/Alpha/BackFront checks / 50 captures at
`CodexBridge/Reports/BSDF-POM/Render-20261018-160828-087`.

## Compilation And Results

Sixteen selected native programs pass for BSDF/BSDFCutout: Base screen shadows,
probes/box projection/blending, point/spot soft-shadow Add, four-array/fog,
depth/cube caster, and both full existing rectangle quality paths. Native errors
in the selected compilation reports: zero. No native variant, feature or sample
budget was removed. These are selected-program checks, not exhaustive bundle
compilation. Existing cache was retained. First-request rectangle programs took
approximately 211-226 seconds each; repeated cached caster programs were nearly
instantaneous. No cold-cache performance or whole-project build is implied.

- Disabled self-shadow matches the independent POM-v1 source across both entries,
  both POM qualities and all five material cases. Maximum image MAE: 6.02e-11.
  Zero strength, zero height and disabled POM also retain the accepted paths.
- The dense independent CPU step-field trace agrees with both quality budgets
  on blocked/clear directions and finite lamps before/after the obstacle.
- Each native light equals its unmodified direct response times exactly one
  independently rendered height visibility. Native shadow maps multiply once.
- Complete coat/substrate/film direct response has maximum product MAE 2.68e-12
  in the layer fixture. Probe, SH and emission-only images are unchanged.
- All four published non-pixel sources are handled, including the separate
  layered fallback loop. Combined pixel/fallback lighting matches the actual
  GPU-published RGB-weighted reference with MAE 6.05e-9.
- Cutout coverage and ShadowCaster retain original UVs. No silhouette, native
  depth, light attenuation position or projected relief change is claimed.
- Distance/mip fade and degenerate metrics leave no detached local shadow;
  white defaults and a flat recessed plane do not shadow themselves. Small
  camera/light movements are bounded. Curved coat/film RT/Reference MAE: 3.24e-5.
- Rectangle lighting is unchanged, including both retained quality programs.

Static checks: property/ME/tooltip contract 1085; POM preservation 91; local
self-shadow/preservation 85; Alpha 230; Glass 152. Total: **1643 passed**.
No new carrier material or prefab is required. Existing distribution bundle
SHA256 remains `9EC10C0BF0C4A0563513CED444FBA140D26DBC2DD9859C01A14283B42B138C94`.

To use the existing BSDF/BSDFCutout materials, set ParallaxMode to POM and a
positive HeightScale, then enable POM Local Self Shadow in Height / POM.
Default Strength/Bias Scale are 1/1; the feature itself still defaults Off.
Realtime/Reference follows the existing Parallax Quality control.

## Mixed-Light Diagnosis And Test Corrections

Failed exploratory runs are retained, not deleted. The initial test assumed
four enabled ForceVertex lamps always arrive at their full Inspector intensity.
GPU position/color/attenuation readback disproved that: equal-priority lights
could leave one slot black; distinct priorities retained four nonzero slots but
reduced the last RGB from 0.495 to 0.2089485 in the coexistence fixture. The old
source has the same allocation. A boolean slot-ID subset was therefore also an
incorrect reference; the final test uses actual published RGB gains at an
unchanged active-light set, preserving the original numeric tolerances.

The transient diagnostic retains the full production entry behind a uniform
sentinel and preserves native pass/variant/data requirements. Its expanded
source is saved as `published-light-probe.shader.txt`; raw float position/color
captures and matching source indices remain in the reports. No shader change
was made to force Unity light allocation or compensate for missing input.

Earlier timing runs are superseded: tilted receivers could put some lamps below
the geometric horizon. The final receiver faces the camera, keeping all four
point sources above that horizon. A later diagnostic also exposed the fixture's
fixed readback target being different from the benchmark target; diagnostics now
temporarily render into the fixture target, then restore the benchmark target.
Timing jobs now reject any failed fixture check rather than relying on a written
performance file. Neither correction changes production shading or sampling.

## Performance

Final forward/reverse interleaved runs:
`Render-20261018-163810-096` and `Render-20261018-163813-348`.
Both contain 40 results: 256/512 square, one/three native lights, four fallback
lights, and mixed directional/spot plus four requested fallback lights. The GPU
diagnostic confirms four nonzero mixed fallback slots for this receiver; their
published RGB may still include Unity's allocation fade.

The 2x2 meter quad faces the camera, height depth is 0.045 m, and the material
uses metallic 0.7, roughness 0.32, coat 0.7 and Realtime film weight 0.8. Area,
Probe and SH contributions are off. Each implementation gets 4 warmups and 9
interleaved samples of 3 Camera.Render calls, completed with AsyncGPUReadback.
This is **Editor camera completion latency**, including CPU/driver/readback, not
pure GPU timestamps or actual KKS frame time. No distribution was built.

512-square median milliseconds, forward / reverse order:

| Lighting | Previous source | Current Off | Realtime On | Reference Off | Reference On |
| --- | --- | --- | --- | --- | --- |
| One native | 1.945 / 1.919 | 1.908 / 1.900 | 1.926 / 1.918 | 1.931 / 1.928 | 1.979 / 1.960 |
| Three native | 4.871 / 4.902 | 4.837 / 4.837 | 4.867 / 4.893 | 4.875 / 4.864 | 4.948 / 4.955 |
| Four fallback | 2.196 / 2.186 | 2.169 / 2.199 | 2.218 / 2.273 | 2.409 / 2.487 | 2.761 / 2.847 |
| Mixed | 4.229 / 4.229 | 4.264 / 4.273 | 4.366 / 4.339 | 4.347 / 4.385 | 4.638 / 4.672 |

Compare On against Off at the same POM quality. In these runs the extra median
completion cost was roughly 0.02-0.10 ms Realtime and 0.03-0.36 ms Reference.
Small differences are near Editor/measurement noise; occasional individual
samples were much slower. Off matching appearance does not promise zero binary
or register overhead. Coverage, relief complexity, sampler latency and native
draw/light count can materially increase the cost on other scenes/hardware.
Existing POM camera searches still repeat in Base and each Add.

## Remaining Boundaries

Local planar continuous height field only: no overhangs, alpha-hole-aware rays,
atlas island detection, physical penumbrae, silhouette/depth displacement,
geometry casting onto other objects or reflected inter-bounce transport inside
the relief. Original gradients, finite budgets and bounded neighborhood/grazing
fallback remain approximations. Coat and substrate share one conformal height
surface; separate coat filling geometry is not modeled. SH/Probe occlusion needs
the existing AO/specular-occlusion controls, not a final RGB shadow multiplier.
No new shadow producer, rectangle occlusion, Glints, SSR or KK work is included.
