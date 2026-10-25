# Current Development Status

As of **2026-10-25**, the hard-surface release checkpoint is **TomBSDF 0.2.0 RC1**.
The native Bundle / archive audit and packaged Editor material regression passed.
The maintainer subsequently reported KKS / ME manual acceptance passed.

Use [Release Status](Release-Status.md) for current program counts, artifact hashes
and evidence boundaries; older milestone summaries do not override it.

| Stage | Implemented | Remaining boundary |
| --- | --- | --- |
| Foundation | Versioned inputs, KKSLinear-v1, compensated GGX / Smith, EON diffuse, native Base / Add / caster | Host resources and normal encoding remain explicit contracts |
| Hard surfaces | Probe / SH, AO / specular occlusion, detail normals, AA, anisotropy | Anisotropic Probe prefiltering remains approximate |
| Layers | Coat, independent normals, absorption, layer transport / roughening, metal optics, optimized / reference film | RGB optics and rough-layer approximations, not exact spectral OpenPBR |
| Scene | Optional companion, rectangles, buffers, coverage Alpha / BackFront, native transparent-map reuse, finite glass | No extra shadow generation, area shadows, exact BTDF, nested media or SSR |
| Surface detail | POM, native-light local self-shadow, stable statistical Glints, separate Tess / CutoutTess geometry | No Alpha / Glass POM / Glints / Tess or screen-space subdivision LOD |
| Release | Profiles, English support docs, native-program / zip auditing, packaged images and user acceptance | No independent cold-build guarantee or universal player performance claim |

The release uses [controlled incremental delivery](Delivery-Build-Workflow.md),
not a declaration that the historical Unity FXC defect is solved. No hardware
cause is inferred from the old worker failures. Existing successful caches and
failed diagnostic evidence remain preserved.

[Architecture](Architecture.md) describes the current modules.
[Release profiles](HardSurface-Release.md) and [presets](Release-Presets.json)
describe optional costs and dependencies. The ordinary source overlay excludes
developer-only fixtures and obsolete duplicate shader / Linear-build tools.
Modern KK adaptation remains deferred.
