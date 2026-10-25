# TomBSDF Stage 3 Validation

This is the historical 2026-10-11 report. The later complete-BRDF audit found
energy defects not detected by these component/IBL-budget checks. Its corrected
results and explicitly approved zero-coat baseline update supersede the energy
and archive-parity claims below; see [Stage3-Audit-Validation.md](Stage3-Audit-Validation.md).

Date: 2026-10-11. Scope: `tom/BSDF` and `tom/BSDFCutout`, KKS Unity
2019.4.9f1, Windows D3D11, NVIDIA RTX 4070 Ti SUPER. This is an explicit isolated
Editor fixture, not live KKS or a reference path tracer. The user accepted stage 2
before this batch. KK, V+, X and the three xukmi prototypes are not ported or changed.

## Implementation

Coat coverage, independent coat normals, Beer-Lambert absorption, interlayer
multiple-reflection energy closure, substrate roughening and band-integrated thin
film are connected to direct lights, native probes and the existing Tom SH input.
AA filters coat and substrate separately, with substrate broadening before AA.
Emission uses escape attenuation instead of the reflection round trip.

See [Layering-Contract.md](Layering-Contract.md) for units, input semantics,
sampler sharing and approximation boundaries. This is not exact refractive
layer transport or full OpenPBR equivalence. No transmission/transparent entry,
SSS, fuzz or new carrier assets are introduced.

## Verified

- [x] Explicit reimport of both modern shader assets after importer recovery.
- [x] 8 independent double-precision numerical checks.
- [x] 68 layering, 502 contract, 116 anisotropy and 979 hard-surface static checks.
- [x] 167 Editor layer checks with 91 captures, including GPU/CPU comparison.
- [x] Visual inspection of bare/clear/tinted lacquer, brushed metal and thin film.
- [x] Foundation regression: 122 checks, 72 captures.
- [x] Environment/detail-normal/AA regression: 139 checks, 75 captures.
- [x] Anisotropy regression: 145 checks, 86 captures.
- [x] Independently loaded AssetBundle: 448 checks, 245 captures; fresh and
  Standard-switched layered materials match Editor rendering with zero MAE.
- [x] Property generation is idempotent, including file timestamps. No redundant
  shader reimport is triggered when the generated contents are unchanged.

The hard-surface static check explicitly allows 42 pre-existing/concurrent X
snapshot differences; it does not treat them as BSDF edits or revert them.

## Measured Results

| Measurement | Observed |
| --- | --- |
| Coat zero vs independent stage-2 packaged BSDF, linear RGB MAE | 6.927e-10 |
| Coat zero vs independent stage-2 packaged BSDFCutout, MAE | 6.927e-10 |
| Mirrored coat normal vs equivalent tangent-normal reference, MAE | 1.808e-7 |
| Mirrored-coat test mean linear intensity (nonblack validity check) | 0.80705 |
| Mirrored vs unmirrored negative-control MAE | 0.80693 |
| Coat AA relative subtexel-motion change, filtered/unfiltered | 0.23595 |
| Coat AA peak, filtered/unfiltered | 0.00703 |
| Layered small-camera-motion relative image change | 0.00526 |
| HLSL complex Airy vs CPU equations, max absolute error | 1.0431e-5 |
| HLSL 32-sample Fresnel average vs 16384-sample CPU, max error | 0.026846 |
| 16-harmonic Airy vs 128-harmonic CPU, tested-domain max error | 0.01600 |
| Ideal conductor film white-furnace peak | 0.9999455 |
| One-way emission attenuation comparison, max error | 2.9803e-8 |

These AA and motion numbers describe the saved fixtures, not a universal quality
guarantee. CPU film comparisons sample several dielectric/metal interfaces,
thicknesses 50-2000 nm and grazing angles; they do not establish a global error
bound for every permitted input. The sub-30 nm neutral fade is a compatibility
transition, not calibrated oxide physics.

## Saved Evidence

All paths below are relative to the Unity project root.

- `CodexBridge/Reports/BSDF-Layering/Render-20261011-105113-564/report.json`
- PNGs in the same folder: `showcase-01-red-base.png`,
  `showcase-02-red-lacquer.png`, `showcase-03-coated-brushed-metal.png`,
  `showcase-04-tinted-coat.png`, `showcase-05-thin-film.png`,
  `showcase-06-varying-film.png`, plus motion and technical comparisons.
- `CodexBridge/Reports/BSDF-Layering/Data/numerical-report.json`
- `CodexBridge/Reports/BSDF-Layering/Before-20261011/stage2.bundle`
- `CodexBridge/Reports/BSDF-Foundation/Render-20261011-104152-989/report.json`
- `CodexBridge/Reports/BSDF-HardSurface/Render-20261011-104434-167/report.json`
- `CodexBridge/Reports/BSDF-Anisotropy/Render-20261011-104509-618/report.json`
- Packaged-shader report and PNGs:
  `CodexBridge/Reports/BSDF-Foundation/Render-20261011-105131-288/`.
- Smoke bundle: `CodexBridge/Reports/BSDF-Foundation/BundleSmoke/tombsdf-foundation-test`,
  SHA256 `3567936869d487fff2e75292f36fe76addb293e0047b7d60eae460ff45b30de8`.

Captures use a 256x256 linear ARGBFloat target and AsyncGPUReadback. PNGs are
display-mapped for inspection; numerical checks use float pixels before mapping.
The stage-2 bundle is immutable and independent of the current source shader.
The first post-recovery layer run also passed, but its mirror fixture was too dim
to be a useful comparison. The final run moves the light into the coat lobe and
requires both a visible highlight and a strong incorrect-orientation negative
control. Only the strengthened mirror measurement is tabulated above.

## Import Recovery

An intermediate import crashed and Unity subsequently classified BSDF.shader as
a DefaultAsset. Later rendering correctly failed validation. Forced branch hints
were removed, the previously successful control-flow form was restored, and the
user authorized an explicit two-shader reimport. It succeeded before the final
layer run. The available logs do not prove the compiler crash's precise cause.
Failed/intermediate runs are retained for diagnosis, not counted as acceptance.
GPU jobs are claimed before execution and never retried on Editor startup.
Existing duplicate AssetBundleBrowser package GUID warnings remain unrelated to
these shaders. They were not repaired as part of this work; explicit shader
validation, scene rendering and the strict smoke-bundle build succeeded.

## Remaining Acceptance

Native anisotropic probe filtering remains a bent-vector approximation. Layer
transport is a directional moment/energy closure, not guaranteed reciprocal
refraction. The film integrals are expensive; real KKS frame-time profiling and
ME material-switch testing are still required. Native Gamma framebuffer addition
and the existing SH capture limitations are unchanged. No game installation or
user scene is updated by these tests.
