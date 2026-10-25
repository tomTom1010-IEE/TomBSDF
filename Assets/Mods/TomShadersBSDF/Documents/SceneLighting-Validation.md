# Stage 4.0 / 4.1 Validation (2026-10-15)

Scope: modern KKS opaque/cutout, optional scene service and unshadowed rectangle
prototype. Not stage 4 Alpha, transmission, scene buffers, SSR or KK adaptation.
The later on-demand color/depth extension is recorded separately in
[SceneBuffers-Validation.md](SceneBuffers-Validation.md); it does not change the
historical area/color acceptance scopes below.

## Current Host Gate

Actual Studio inspection records Unity 2019.4.9f1 / D3D11 / Linear, ME 4.0.3.0,
and the three new registry entries. The original authoring-template Gamma bundle
is rejected for KKS: saved float pixels show emission 0.25 encoded to 0.537099.
The native output/Auto input checks exposed this; controlled linear test output
alone had hidden it. Old actual-player checks could not be fully serialized by
player JsonUtility and must not be counted as passing. Composite diagnostic DTOs
now use System.Runtime.Serialization's JSON serializer, without an extra plugin
dependency. An empty report cannot authorize packaging.

The main authoring project stays Gamma. The isolated Linear build was cancelled,
not completed. The corrected `KKSLinear-v1` adapter now makes sampled Auto input,
data restoration, Probe HDR decoding, fog and scene output independent of build
color-space macros and of the companion plugin. Normal main-project building is
restored; no new color LUT or material-local grading is introduced. The original
reference/source are retained. Core/Lighting BRDF files and xukmi/TomX code are
unchanged. Full same-bundle shared Editor acceptance remains a separate gate.

Current correction: 32 color-contract static checks and 184 stage-4 regression
groups pass, including the 532-check shader/manifest/tooltip contract. Runtime
sources build with zero warnings/errors. The historical Gamma package results
do not validate this corrected version; the new checks are scoped below.

## KKS Color Correction (2026-10-16)

All Unity operations used the main project's Codex Bridge. Project color space
remains Gamma; no second Editor/project or Studio automation was launched.

- Production color-helper GPU checks: **112/112 pass**, including Auto/explicit
  input, scalar restoration, raw alpha/coverage, HDR, linear light sums/fog,
  native-HDR alpha handling, RGBM exponent decoding and an inert legacy global.
- The same shader was built into a **13,253-byte Gamma-project AssetBundle**,
  loaded back and checked: **112/112 pass**, maximum RGBA absolute error
  `5.960464477539063e-8` against independent CPU formulas.
- Both complete modern production shaders render successfully: **8/8 smoke
  checks pass**, four saved PNGs. Default emission returns **0.25 linear** in
  both shaders with the old output override at 0 or 1, rather than 0.537099.
- Static validation: 32 color-contract checks, 184 scene regression groups and
  155 film regression groups pass. The film checks verify the existing furnace
  evidence; a new furnace integration was not run. Core/Lighting hashes match
  the accepted math, and the three legacy prototypes remain frozen.

Evidence (directory timestamps are UTC):

- `Color-20261015-155523-611/color-contract.json`: source helper GPU checks.
- `Color-20261015-155551-500/color-contract.json`: packaged helper GPU checks.
- Color-only bundle SHA256:
  `1f676990891bee152e908b9d2f1aef7a3e344e89dce85f8bf2a854757da13381`.
- `ColorModern/Render-20261015-155628-865/report.json`: full shader smoke checks.
- `Data/color-static.json`, `Data/scene-static.json`,
  `Data/color-film-regression.json`: current static regression results.

These are Gamma-authoring/linear-float-target Editor results, **not actual KKS
player acceptance**. The small bundle validates shared color code through
serialization/build, not the complete BSDF distribution. No new full BSDF
package was built or deployed in this correction; the user must rebuild before
testing in KKS. Old installed packages do not acquire source fixes automatically.
Existing material/prefab bindings and public property defaults need no changes.

User decision: final Studio visual/save-import/performance acceptance is manual.
No computer use, no further automated Studio operation, and no automatic GPU
commands on game/Editor startup. See [the manual checklist](KKS-ME-Acceptance.md).

## Evidence So Far

### Full Material Color Regression (2026-10-16)

Explicit Codex Bridge command `appearancebsdfcolor` passed **212 checks** and
saved **81 rendered PNGs, 81 RGBA float buffers and four comparison sheets**.
No AssetBundle build, game launch/deployment or production shader modification
was performed. The main Editor remains responsive with Gamma project settings.

Coverage is both modern opaque/cutout shaders, front/oblique cameras and six
material cases: red plastic, gold, anisotropic aluminum, absorbing coat on red
plastic, dielectric thin film and metallic thin film. Shared main/roughness/AO,
base/detail normals and independent coat normals are active. Native directional
light, HDR Probe and native SH use fixed inputs and one display transform.

The reference is the already preserved stage-3 bundle, SHA256
`a5a2e832d2f95aed99c3d361ed217798d073d795b63f921fb36eaec56ce5cfbd`,
with explicit linear inputs and its original linear-output override. This is
the accepted material math, not the defective old Gamma default appearance.
Reference loading does not rebuild or reimport any shader. The current shader
uses Auto inputs without the old output override. A third column uses current
explicit-linear inputs; the fourth displays absolute RGB error times 16.

Across **24 material/view/shader comparisons**:

- Current Auto versus current explicit linear: image MAE **0** in every case.
- Current Auto versus preserved linear reference: maximum image MAE
  **6.3854e-9**, maximum normalized RMS error **1.2834e-5** (about **0.00128%**).
- Largest isolated RGB-channel difference: **3.5748e-4**; inspect authoritative
  float buffers rather than rounded display PNGs for that precision boundary.
- All frames are finite/nonnegative and the material subjects are genuinely lit.
- Negative controls detect old display encoding and duplicate input decoding.
  Metallic, anisotropic, coat and film toggles visibly change the result;
  zero coat ignores layer controls and zero Cutout coverage remains empty.

Evidence root (directory timestamp is UTC):
`ColorAppearance/Render-20261015-165125-617`.
`report.json` contains checks/captures; `appearance.json` records reference,
row/column order and per-comparison errors. The four `*-comparison.png` sheets
were visually inspected. Top-to-bottom rows follow the six cases listed above.

Conclusion: no new material appearance regression from the color adapter was
found in these controlled Editor cases. Existing point-sampled normal/mesh
detail is also present in the reference, not a newly introduced color artifact.
This is not temporal/whole-game performance, actual ME texture import, full
distribution-build or actual KKS player acceptance. No new white-furnace or
OpenPBR reference computation was needed/performed; BRDF math is unchanged.

### Prior Area-Light Evidence

- Both imported shaders compile. The three legacy xukmi entries and accepted
  material math are unchanged. Static stage-4 checks: 118 groups pass; modern
  shader/manifest/tooltip contract: 532 checks pass.
- Independent float64 reference: 38 full-BRDF rectangular integrals, 163840
  directions each, with a separate lower-count convergence check.
- Explicit Bridge Editor render: 191 checks pass, 60 PNG captures, plus raw
  numerical buffers. Realtime maximum normalized RGB error 5.0799%, mean 1.0838%;
  2048-sample/proposal GPU reference maximum 0.6338%, mean 0.1365%.
- Tested local/global disable and restore, native Base/Add coexistence, camera
  state clearing, four-of-five selection and clearing the last emitter.
- Additional geometry checks: distance 4/8 gives a 3.99939 ratio; four times
  emitter area gives 3.99752 times the center irradiance. Studio renderer hiding,
  zero height, incompatible protocol and direct-light AO isolation pass.
- Source, LTC provenance and the accepted stage-3 bundle are preserved under
  `CodexBridge/Reports/BSDF-Stage4/Before-20261015`, `Source` and `Data`.
- The first Editor render left a temporary numerical target active on disposal;
  the numerical fixture now restores RenderTexture.active in its finally block.
  This was test cleanup, not a material shading change.

Editor render evidence:
`CodexBridge/Reports/BSDF-Stage4/Render-20261015-134648-048`.

## Historical Gamma Editor Package

The Gamma bundle passed 123 shared-harness checks, including genuinely lit
stage-3 comparison, local disable, missing service, resource binding, emitter
side, radiance scaling, cutout, native output and service lifetime. This is
historical Gamma Editor evidence, not acceptance of a Linear KKS package.

Bundle SHA256: `90e0467e878cc7eda7f7c7a9609f84de25665e9646bf8029a2823b5f202f41ad`.
The prior timing evidence is `SharedEditor-20261015-134115-250`; the final Gamma
color/lifecycle harness is `SharedEditor-20261015-140047-150` under the report root.

256x256 Editor medians, one native directional light, no shadows/MSAA/postprocess:

| Material | Accepted stage 3 | Stage 4 no rectangle | Stage 4 one rectangle |
| --- | ---: | ---: | ---: |
| Bare | 0.445 ms | 0.487 ms | 1.793 ms |
| Coat | 0.578 ms | 0.594 ms | 4.556 ms |
| Anisotropic | 0.202 ms | 0.195 ms | 0.364 ms |
| Thin film | 0.591 ms | 0.746 ms | 2.132 ms |

These are CPU+GPU+driver/readback **completed latencies**, not GPU timestamps,
material-independent relative rankings, or full-game FPS. Complex numerical
area integration remains expensive. Even the no-emitter case can have shader
register/dispatch overhead; no zero-overhead or production-performance claim is made.

The first build was interrupted by a Windows upgrade restart; there was no
Unity native crash stack. Its command was archived, not replayed, and a fresh
explicit build completed. The prematurely queued acceptance failed before
scene/GPU work because its payload did not yet exist. Interruption evidence is
preserved in `Interruption-20261015`.

## Remaining Gates

Actual KKS/ME acceptance is not implied by the source/Editor checks above.
It is now reserved for the user's manual validation. Whole-game FrameTiming data, isolated
completed latency and Editor measurements must remain separately labeled.

The shared harness compares extension-off and missing-service output against
the preserved stage-3 bundle under a genuinely lit native-light setup, not two
black frames. Runtime ME checks use the real shader registry and MaterialAPI;
typed-record serializer roundtrip is distinct from interactive Studio scene
save/import UI acceptance.

See [SceneLighting-Contract.md](SceneLighting-Contract.md) for sampling counts,
low-sample and near-field approximation boundaries, radiance units, camera
scope, visibility and the explicit absence of area-light shadows/occlusion.
