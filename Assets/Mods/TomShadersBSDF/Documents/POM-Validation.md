# POM-v1 Validation (2026-10-18)

## Scope And Environment

Unity 2019.4.9f1 / D3D11, NVIDIA GeForce RTX 4070 Ti SUPER, Gamma authoring
project with the unchanged KKSLinear-v1 adapter. All native compilation,
temporary materials/scenes/textures and camera rendering ran through explicitly
claimed Codex Bridge commands. No computer use, full bundle build, deployment,
KK port, self-shadow, Glints or true displacement was performed.

`CodexBridge/Reports/BSDF-POM/result.json` is **passed**. The aggregate verifies
source hashes and completed Bridge results, not merely the existence of a PNG
or partial report. Every selected run records the nine relevant shader/include
hashes in `source-hashes.json`. The independent pre-change source is preserved
in `CodexBridge/Reports/BSDF-POM/Before-20261018`.

## Evidence

Folders below are relative to `CodexBridge/Reports/BSDF-POM`.

| Batch | Report folder | Checks / PNGs |
| --- | --- | --- |
| Neutral regression | Render-20261017-190343-757 | 80 / 50 |
| Analytic height / coordinates | Render-20261017-192450-797 | 60 / 35 |
| Material maps / layered appearance | Render-20261017-192202-937 | 31 / 19 |
| Raw Cutout coverage / native shadows | Render-20261017-192203-786 | 19 / 11 |
| Motion / grazing / curvature / UV pole | Render-20261017-192451-227 | 34 / 28 |
| Realtime / Reference rectangle integration | Render-20261017-192451-725 | 12 / 6 |
| Total selected POM rendering | Six completed batches | **236 / 149** |

Additional unchanged-glass smoke regression passes **64 checks / 17 PNGs** at
`CodexBridge/Reports/BSDF-Glass/Render-20261017-193158-222`. Its Bridge result is
`CodexBridge/Outbox/20261018-pom-013-glass.result.json`.

Sixteen selected native programs pass for BSDF and BSDFCutout: Base with native
screen shadows/Probe support, point and spot soft-shadow Add, depth/cube caster,
vertex-light fallback/fog, and both rectangle quality programs. These are
selected-program checks, not exhaustive compilation of all native combinations
and not a distribution build. Native errors: zero. Existing duplicate immutable
AssetBundle Browser GUID errors during AssetDatabase refresh are unrelated and
remain recorded in the original Editor/Bridge logs.

Compilation remains expensive: selected first-request Cutout rectangle programs
took approximately 195 s Realtime and 187 s Reference. Other requests reuse
existing cache, so near-zero repeated times are not a cold-cache benchmark.
No cache clearing, sample reduction, variant removal or physical-core rewrite
was used to obtain acceptance.

## Results

- Opaque/Cutout Off and zero-height images match the independent pre-change
  source exactly in tested bare/metal/anisotropic/coat/film cases. Alpha and
  Back/Front also match their pre-change source exactly, with no POM controls.
- All shifted main/material/ORM/normal/detail/anisotropy/emission/coat/film maps
  match an independently baked constant raw-UV offset exactly, including each
  map's own ST. The unshifted positive control differs by MAE 0.01623.
- Constant-height world-metric center errors are at most 2.69e-7; the sloped
  height, independent ST and reverse analytic cases are below 6.86e-7.
- Height's own Repeat/Clamp sampler genuinely changes the result; it does not
  silently use the RoughnessMap sampler. White envelope and far fade are exact.
- Cutout main alpha/red mask stay unshifted. Directional, point and spot
  caster images are unchanged by POM; removing the caster is a positive control.
- Five material sheets show visible relief. Realtime/Reference image MAE is
  at most 2.633e-4 here; curved-metal MAE is 2.295e-5. Reference is still finite
  height sampling, not ground truth for arbitrarily narrow features.
- Repeated frames are deterministic. Tested subpixel camera-motion per-frame
  MAE stays below 8.78e-4. Grazing, minified and UV-pole captures are finite.
  This bounded sequence is not a guarantee for every animated/atlas material.
- Both rectangle qualities match the baked-offset material exactly and have
  positive light-on/light-zero controls. Existing BRDF and layer transport are
  not modified; the physical/lighting/platform source hashes remain unchanged.

The planar comparison is
`Render-20261017-192202-937/pom-materials-comparison.png`: rows are bare, metal,
anisotropic, coat, film; columns are Off, Realtime, Reference, abs(Off-RT)*16.
The curved comparison is
`Render-20261017-192451-227/pom-curved-surfaces-comparison.png` with the same
columns. Float data is authoritative; PNGs share the established Reinhard/sRGB
display transform. These images were visually inspected, not only counted.

## Completion Timing

Two opposite interleaved orders, each containing twenty records: 256/512 square
ARGBFloat targets, one or three native pixel lights, before/Off/zero/Realtime/
Reference. A 2x2 world-unit quad at 55 degrees covers most of the camera; height
is 0.045 m. Area lighting is disabled. Four warmup frames, nine samples and three
Camera.Render calls per sample, followed by GPU-complete AsyncGPUReadback.

| 512 square / 3 lights | Forward order median ms | Reverse order median ms |
| --- | --- | --- |
| Pre-change | 0.55 | 0.73 |
| POM Off | 0.55 | 0.67 |
| Zero height | 0.53 | 0.70 |
| Realtime | 0.60 | 0.78 |
| Reference | 0.68 | 0.84 |

Raw samples and all other cases are saved in `performance.json` under
`Render-20261017-193159-598` and `Render-20261017-193200-098`, and included in
the aggregate result. These completion latencies include CPU submission,
driver/readback and Editor costs. They are **not pure GPU shader timings or
actual KKS frame-time certification**. Small low-load differences are noisy;
do not infer that enabled POM is faster than Off or promise a fixed percentage.

## Contracts And Remaining Work

`validate_contract.ps1` passes 1064 checks, `validate_pom.ps1` 76,
`validate_alpha.ps1` 230 and `validate_glass.ps1` 152. Historical freeze guards
explicitly distinguish the authorized POM sampler adapters from the frozen
physical code; the new adapter behavior is checked with the independent oracle.

Existing shader identities and carriers are retained. No new material/prefab
binding is needed; no runtime DLL change or new keyword synchronization is
required. Distribution bundle SHA256 is unchanged:
`9EC10C0BF0C4A0563513CED444FBA140D26DBC2DD9859C01A14283B42B138C94`.

See [POM-Contract.md](POM-Contract.md) for finite-step, atlas/padding, gradient
approximation and UV-only depth/shadow limits. No self-shadow or height-normal
reconstruction was added. Live ME persistence/Studio acceptance and target-GPU
profiling remain separate. Glints, real displacement, SSR, full packaging and
KK adaptation are not part of this acceptance.
