# Tess-v1 Validation (2026-10-24)

## Result And Scope

Implemented independent `tom/BSDFTess` / `tom/BSDFCutoutTess` on KKS Unity
2019.4.9f1 Built-in Forward / D3D11. **24 selected native pass tests and 355
Editor render checks pass**, with 191 captures plus one comparison sheet.
Two opposite-order timing runs contain 40 measured series in total. This is
not a full new bundle/zip audit, actual Studio acceptance or KK qualification.

See [contract](Tessellation-Contract.md) for geometry, normal frames, filtering,
UV seams, optional culling support and explicitly deferred features.

Evidence paths below are relative to the Unity project root:

- Index: `CodexBridge/Reports/BSDF-Tess/validation-index.json`.
- CPU/contract reference: `BSDF-Tess/cpu-static.json` under the Reports root.
- Native matrix: `BSDF-Tess/Batch-Compile-20261024-091542-495/results.json`.
- Final ShaderUtil sources/messages:
  `BSDF-Compiler/Inspect-20261024-182352-095/report.json`.
- Source-stamped pre-change snapshot: `BSDF-Tess/Before-20261024`.

The native matrix and all accepted camera runs match the final 56 production
shader/include hashes. Final camera/timing runs also match the final runtime
DLL. A later bounds-only static-batch safety guard changed the runtime after the
native matrix, not shader inputs or generated VS/HS/DS/PS.

## Accepted Camera Runs

All directories in this table are below `CodexBridge/Reports/BSDF-Tess`.

| Batch | Directory | Checks | Captures |
| --- | --- | ---: | ---: |
| Analytic geometry, meters, reverse, mip, mask, tangent | Render-20261024-094600-479 | 34 | 19 |
| Actual native camera depth, both projection modes/entries | Render-20261024-094601-493 | 10 | 4 |
| Mesh/skin bounds, near clip, nesting/abort/restoration | Render-20261024-094602-514 | 21 | 4 |
| Mirrored UV, negative/nonuniform scale, normal/detail/layers | Render-20261024-094603-536 | 80 | 40 |
| Sealed old-family oracle, zero height, envelope isolation | Render-20261024-100128-403 | 85 | 50 |
| Plastic, metal, anisotropy, coat, film, Glints | Render-20261024-100132-168 | 60 | 36 |
| Directional/spot/point caster, both entries | Render-20261024-100133-535 | 30 | 18 |
| Native lights/SH/Probe/fog/four-array/area/fallback | Render-20261024-100442-099 | 23 | 10 |
| Camera motion and deterministic return | Render-20261024-102223-264 | 12 | 10 |

Visually inspected sheet:
`Render-20261024-100132-168/tess-hard-surfaces-comparison.png`.
Rows are Opaque then Cutout, each plastic/metal/anisotropy/coat/film/Glints;
columns are no displacement, fine height, mip-2 height, amplified difference.
Relief and real silhouette/coverage changes are visible; the last column is
an error/feature-difference view, not another intended material appearance.

## Numerical Findings

- Fifteen old-family comparisons against the independently sealed Glints
  bundle are exactly equal: Opaque, Cutout, Alpha, BackFront, Glass across
  bare/anisotropic/film cases. The three shared adapter edits also emit
  token-identical old HLSL under six real-preprocessor combinations.
- Zero height versus the ordinary entry: mean RGB error approximately
  `1.29e-9` / `2.36e-9`. Geometry sampling is bypassed and factors return to 1.
- True tessellated caster versus independently shifted baked geometry:
  directional/point error 0; spot maximum MAE `1.72e-6`. Positive controls
  without displacement differ by `8.27e-4` to `8.10e-3`.
- Native lighting/SH/Probe/fog against baked geometry: MAE `1.60e-7`;
  four-array fallback `2.67e-7`, with a nonzero lighting control. The test uses
  real Unity rendering/allocation, not a hand-added sum of Inspector intensities.
- Rectangle Realtime/Reference versus baked geometry: `5.14e-8` / `9.15e-8`.
  Extension off contributes zero rectangle lighting, restores transient
  quality keywords and still maintains native geometry bounds.
- Quantitative camera depth is 3.06 meters for the supplied constant relief;
  Cutout holes remain clear. Perspective and orthographic cases both pass.

White-map/black-mask NONZERO height still subdivides. On the sphere, four
silhouette pixels change ownership and interpolant differences are consistent
with D3D11's snapped raster vertices. Common-surface position MAE is `5.79e-6`
meters; normal/tangent MAE approximately `1.17e-5` / `1.06e-5`. The smooth
layered image changes by `5.74e-6`; Glints amplify this to `9.55e-5`, about 0.16%
of the image's mean. These are not changed physical equations or real relief.
Strict zero-height parity is kept separate from retriangulation acceptance.
The diagnostic records common coverage, edge pixel count and a viewport-derived
subpixel budget; its initial overly strict failures are preserved.
The precision basis is the [Microsoft D3D11 functional specification](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm).

## Bounds Fix And Limits

The first skin test genuinely failed: `updateWhenOffscreen=true` in Unity 2019
recomputed the AABB and overwrote the expansion. Fixed by suspending that flag
only inside a camera/culling scope, preserving visible skinning and restoring
the flag at outer post-render, abort or disposal. Negative/nonuniform padding,
source-mesh ownership, shader switches, nested cameras, bone motion versus a
baked reference and a reproduced near-clip disappearance now pass.

Already precombined static batches are deliberately not cloned/patched; unbatch
or author bounds. No companion means manual mesh/skinned bounds are required.
UV/normal seams need matching input or a seam mask/explicit triangle-edge pinning.
No screen-space LOD, automatic old DepthNormals replacement, collision deformation,
Alpha/Glass tessellation or area-light shadowing is claimed.

## Performance

GPU: RTX 4070 Ti SUPER. 1920x1080 float target, fully covered. Twelve warmups,
seven interleaved samples, then an opposite-order run. Values include CPU
submission, Editor/driver overhead and a one-pixel GPU completion readback;
**they are not GPU timestamps or actual KKS frame timings**. No shadow maps,
coat/film or active rectangle lights in this timing fixture.

| Source triangles | Native lights | Plain | Tess, height 0 | Factor 4 | Factor 16 | Factor 32 |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2 | 1 | 0.47-0.53 | 0.48-0.54 | 0.44-0.53 | 0.48-0.54 | 0.48-0.59 |
| 2 | 3 | 0.94-1.01 | 0.86-0.90 | 0.85-0.95 | 0.91-0.97 | 0.92-1.06 |
| 512 | 1 | 0.48-0.51 | 0.46-0.52 | 0.52-0.56 | 0.71-0.76 | 0.94-0.98 |
| 512 | 3 | 0.89-1.00 | 0.82-0.93 | 0.95-1.04 | 1.32-1.41 | 1.87-1.93 |

Milliseconds, range of the two medians. The plain shader still owns the existing
uniform-off POM path; small differences include code shape and timing noise.
Do not interpret zero-height Tess as guaranteed faster/free. Dense source meshes,
high factors, multiple lights and shadow draws compound geometry amplification.
WorldEdge mode and a conservative cap are preferable to a large universal factor.
Raw series: `Render-20261024-102319-830` / `Render-20261024-102320-851`.

## Diagnostics And Delivery

Current static/mathematical checks: 2129 Tess reference, 1633 shared property
contract, 178 Glints checks, 20 build-auditor unit tests. Runtime/plugin build
passes with zero C# compiler warnings/errors. All final ShaderUtil messages are
Warnings (67 cached records across seven entries), not Errors. They include
the existing FXC potential-uninitialized diagnostics and the new domain evaluator;
the latter's returned fields/branches are assigned, and tested paths are finite.
Warnings remain archived and are not described as repaired or silently cleared.

An independent X release audit used this same Editor during the run. Its
separate failure and known duplicate AssetBundle Browser GUID diagnostics are
not BSDF compiler failures. Timing started only after the command queue drained.
The isolated BSDF camera tests do not certify the X task.

Both m_/a_BSDFTess and m_/a_BSDFCutoutTess were created/bound by Codex Bridge;
all four existing shader-owned tables are dependencies. No native Unity asset
was authored as text. Companion 0.6.0 source/binaries are built locally, not
deployed to the game. Existing prefab/material bindings are retained.

The production Bundle is still the accepted pre-Tess Glints version, SHA256
`bd3f2b02234739cfd27bb134f5dc6cc3cd1c91e0386adbdbd77d2e3deed383c4`.
No new full bundle/zip was built or promoted. Next release work must audit the
new seven-entry native submission, including actual Hull/Domain programs,
resource bindings, exact zip payload and packaged-material regression.
Do not combine the new manifest with the old bundle. KK remains untouched.
