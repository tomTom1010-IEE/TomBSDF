# Glints v1 Contract

Glints v1 is a UV-anchored statistical redistribution of the substrate's GGX
single-scattering reflection, not an emissive overlay or a second metal-flake
material. It is implemented only by modern `tom/BSDF` and `tom/BSDFCutout`.
Native directional, point and spot lights, ForwardAdd and Unity's actual
four-array fallback use the same estimator. Probe, SH and rectangles retain
their existing smooth response. Alpha, Back/Front, Glass and legacy xukmi
entries do not compile the Glints implementation.

## Material Inputs

| Property | Default / range | Contract |
| --- | --- | --- |
| `_GlintWeight` | 0 / 0..1 | Interpolates the smooth and statistical single-scattering distributions. Zero branches to the original evaluator before count/mask work. |
| `_GlintMask` | White / R | Decoded non-color weight, not coverage. Its ST affects only this mask. Shares `sampler_RoughnessMap` filtering and wrap. |
| `_GlintDensity` | 6 / 0..8 | `rho = 10^value` expected microstructures per unit original UV area, not per square meter. |
| `_GlintContrast` | 0.5 / 0..1 | `R = 10^(-3*value)`. Higher values give rarer/brighter events with unchanged target mean, not extra energy. |
| `_GlintSeed` | 0 / 0..65535 | Rounded, clamped integer material seed. No frame, time, light index or screen-position seed. |

The two existing ME entries expose the mask in `Textures` and four floats in
`Glints`; matching tooltips and Foundation-Properties v10 describe the same
inputs. No new carrier shader/material/prefab identity is required. The existing
KKSLinear-v1 and `_DataTextureRestore` conventions apply. No companion plugin,
compute generation or runtime random texture is required for base functionality.

## Statistical Model

For the current filtered GGX distribution `D`, axes `alphaT, alphaB`, footprint
count `N` and decoded weight `w`:

```text
D_peak = max(1, alphaT, alphaB)^4 / (pi * alphaT * alphaB)
p = R * D / D_peak
D_sample = (D_peak / R) * count(N, p) / N
D_effective = lerp(D, D_sample, w)
singleScatter = D_effective * existingSmithVisibility * existingFresnel
```

The upper bound includes axes above one; assuming `D(normal)` is always the
peak would bias rough anisotropic materials. Existing diffuse, multiple
scattering, energy tables and layer budgets are not multiplied by noise.

Production counts use a positive smooth-gated conditional lognormal
approximation. For integer trials its first two moments are calibrated to the
binomial moments; its PMF and higher moments are not an exact binomial.
Fractional counts introduced by continuous interpolation are an approximation.
The smooth gate's second moment is included in that calibration. Stable
small-probability formulas avoid cancellation. Below occurrence probability
`2e-6` the estimator returns its mean, continuously blending to the random
estimator by `2e-4`; this avoids unresolved tails in 24-bit random variates.
It is not final RGB clipping or a probability floor that adds energy.

The independent CPU reference retains exact binomial PMFs, explicit binomial
sampling and numerical quadrature for the approximate count's moments. The
full production BRDF is also integrated separately on the GPU over many fixed
material seeds. These expensive tests are outside all shipping Passes.

The statistical target is `E[D_sample] = D`, not strict normalization of every
random material, pixel or individual microfacet. Local HDR peaks may exceed one.
This implementation follows footprint-counting ideas from
[Deliot and Belcour 2023](https://arxiv.org/html/2306.05051v1), but is an
independent approximation, not a literal implementation of their count law.

## Filtering And Coordinates

The material stage prepares the UV ellipse and random keys once before light
evaluation, using the POM coordinates and explicit gradients. Without POM,
gradients are explicitly initialized. Coverage and ShadowCaster still use their
original UV contract. MainTex ST does not move the microstructure field.

Tetrahedral interpolation selects at most four ellipse parameter grids; each
uses three triangular spatial nodes and three triangular half-vector nodes.
There are at most 36 bounded count queries per native lamp, independent of the
actual number of microstructures. Canonically identical isotropic grids merge
their allocated trial counts before sampling. Direction interpolation is
periodic over the ellipse orientation. No derivative is evaluated inside the
count or native-light loops.

The half-vector lattice uses `h.xy * 32` in the material's anisotropic frame.
This is a finite angular-correlation model, not explicit shared flake geometry.
Mirrored/overlapping UVs mirror/repeat the field; UV seams and unequal texel
density are not automatically repaired. Existing tangent handedness, negative
scale and anisotropy rotation remain authoritative.

## Coat, Film And AA

Only substrate single scattering is redistributed. Coat-surface reflection
remains smooth. Relative IOR, incoming/outgoing absorption, layer escape budget,
roughening, multi-scatter and both film quality paths remain the existing model.
An index-matched dielectric can legitimately have no substrate Glints.
The same macro half vector supplies film color; no per-node spectral integral
is added. Independent colored metal flakes inside a nonmetallic binder require
a future separate material/layer model.

AA and coat roughening retain their existing broadened mean GGX lobe. Extra
angular spread increases effective trials by
`1 + 1024 * max(filteredRoughness^4 - intrinsicRoughness^4, 0)`, and the same
factor divides the count sum. This suppresses variance without changing the
target mean or seed. It is a calibrated statistical filter, not exact angular
refraction/convolution through a rough coat. The intrinsic roughness is captured
before normal AA. Coat and substrate continue to have separate normal/AA inputs.

Native shadow, cookie, distance and POM visibility retain their existing light
semantics. POM local visibility multiplies each complete layered lamp response
once; it does not multiply coverage, emission, SH, Probe or rectangles.
Unity's four-array fallback supplies no per-lamp native shadow map/cookie;
Glints preserves that limitation. Native real-time map shadows require the
corresponding per-pixel light path; local height visibility is a separate feature.

## Isolation And Cost

`Core/TomBSDFGlints.cginc` owns count mathematics, `Material/TomBSDFGlints.cginc`
owns input/footprint preparation, and `Lighting/TomBSDFGlintsLighting.cginc`
owns the isolated native evaluators. The existing physical core stays unchanged.
Only Opaque/Cutout Base/Add define `TOM_BSDF_GLINTS`; no public Glints keyword
dimension or sample-budget change is introduced. No reference algorithm is
inserted in the rectangle integration loop.

Each ForwardAdd draw repeats material/footprint work; there is no cross-Pass
cache. Per-lamp hash/log/exp/trigonometric work can be substantial, especially at
4K and with many pixel lights. Editor Camera.Render plus GPU completion timings
include CPU/driver overhead and are not KKS GPU timestamps. Reference film and
Reference rectangles retain their pre-existing high cost. See
[validation](Glints-Validation.md) for measurements and delivery status.

## Deferred Scope

Discrete Probe/area Glints, coat-surface flakes, Alpha/Glass Glints, explicit
facet occlusion, exact spectral/rough-layer correlation, SSS/BSSRDF, displacement
and KK adaptation remain separate work. Optional real displacement is the next
stage-5 feature, not part of this implementation.
