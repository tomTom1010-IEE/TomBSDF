# KKS Layering Contract v3

This is the stage-3 real-time coat/film implementation for `tom/BSDF` and
`tom/BSDFCutout`. The xukmi prototypes, V+ and KK implementations are unchanged.
It is not full OpenPBR, a spectral path tracer, or a transmission material.

## Composition and zero contract

Air -> isotropic GGX coat -> absorbing medium -> optional thin film -> existing
anisotropic GGX/EON substrate. Film belongs to the coated coverage in this version.
The final result is `(1-weight)*bare + weight*covered`, with
`weight = CoatWeight * CoatMask.r`. There is no extra render pass or keyword.
The uniform zero branch executes the corrected bare material lighting, probes,
SH, emission, AA and shadows without evaluating layer inputs. On 2026-10-13 the
user approved changing this bare baseline to fix its energy loss; zero coat no
longer promises image identity with the defective stage-2 mixed-metal/dielectric
model. Pure-metal and IOR=1 Lambert archive controls remain unchanged. A black coat
mask also returns the bare result, although it does not skip all input work.

## Properties and units

The property source of truth is `Foundation-Properties.json` v5. Run
`Tests/sync_property_contract.ps1 -Write` to regenerate the two Properties blocks,
their manifest blocks and tooltips. Existing property names/defaults/ranges stay
unchanged. New categories are Coat, Coat Normal, Coat Absorption, Thin Film.
The 2026-10-14 film optimization adds only ThinFilmQuality: Realtime=0 by default,
Reference=1 preserves the accepted high-precision model. Other properties stay unchanged.

- CoatWeight and ThinFilmWeight default to zero. Scalar maps default to white.
- Coat roughness is perceptual roughness, default .1, with GGX alpha = r squared.
- CoatIOR defaults to 1.5. The coat has no metallic mode or anisotropy in v1.
- CoatNormalMap has the existing explicit UnityPacked/RGB/AG decoder, scale,
  Y flip and data-restore controls. Default base-normal inheritance is zero.
  Inheritance happens before RNM; anisotropy rotation never rotates coat UVs.
- CoatAbsorptionColor is single-pass transmission at CoatAbsorptionDistance.
  Both reference distance and coat thickness use **millimeters**. White is
  nonabsorbing; zero thickness removes absorption. Thickness defaults to .05 mm.
- ThinFilmThickness uses **nanometers**, default 400, not medium thickness.
  Film IOR defaults to 1.4. Film weight/mask zero, thickness zero, and an
  index-matched film/coat interface are neutral. Below 30 nm the film contribution
  smoothly transitions to the plain substrate reflection, preventing a discontinuity
  at black thickness texels. This is not a calibrated ultrathin oxide model.
- New maps share the RoughnessMap sampler to stay within D3D11's 16-sampler
  limit. Their UV transforms are independent, but filter/wrap settings are shared.
  Scalar data obeys DataTextureRestore; colors obey ColorValueMode.

## Energy and transport

The medium uses Beer-Lambert optical depth `-log(transmission)*thickness/distance`.
Snell's internal cosine determines the slant absorption path. Direct reflection
uses the actual light direction for entry and the view direction for escape.
Indirect entry uses a 16-sample external cosine average; the internal repeated
population uses a separate 16-sample interior round-trip Beer average. These
angular averages are a factorized approximation, not traced ray paths.
Emission includes only escape attenuation. Repeated internal
reflection is summed separately from GGX microfacet multiple scattering:

```
loop = R_inside * R_substrate * AverageInteriorRoundTripBeer
escape = (1-R_inside) * A_up / (1-loop)
substrate_energy = (1-R_coat) * A_down * R_substrate * escape
```

Internal coat reflectance interpolates smooth/rough estimates, rather than using
the rough-interior estimate for every substrate. The mixing roughness reflects
dielectric specularity, metalness and the broadened substrate roughness. It is a
hemispheric flux approximation including the statistically trapped population.
A lossless unit-reflecting substrate closes
to white; colored/absorbing substrates can only lose energy in this closure.
Diffuse and specular divide the substrate budget using their directional albedos.
Dielectric and conductor responses (including film averages and nonlinear
multiple-scattering compensation) are prepared separately before metalness
interpolation. Diffuse uses the dielectric budget only. The furnace audit found
that mixing F0 before compensation could lose about 75% of white energy.
Each normalized GGX/EON lobe uses its own shading normal cosine. All lobes still
obey the geometric-normal horizon. Light attenuation is applied once. AO affects
only indirect lighting, separately for coat and substrate; emission is not AO'd.

Base dielectric F0 uses base/coat relative IOR, not the air/base IOR. The existing
RGB metalness interface cannot specify measured complex optical constants. Metals
use the neutral-edge-tint Gulbrandsen fit `n=(1-F0)/(1+F0)`,
`k=2*sqrt(F0)/(1+F0)` in each channel. BaseColor on a metal means **air-interface
F0**. Covered plain reflection and thin film share these optical data; plain
reflection uses conductor Fresnel in the coat medium, not a different n=1 fit.
The accepted bare path still uses its Schlick approximation of the same air F0.
These RGB optical fits are not measured wavelength-dependent metal dispersion.
Near-perfect conductor evaluation uses a stable complex-root identity to avoid
float32 cancellation at grazing incidence.

Rough transmission uses a bounded RMS fit, calibrated using separate peak,
width/tail and anisotropic lobe profiles:
`effectiveRoughness^4 = min(baseRoughness^4 + (1-1/coatIOR)*coatRoughness^4, 1)`.
Intrinsic axis ratio is retained. The previous loop-amplified moment proxy could
clamp the base to unit roughness and wash out anisotropy; it is no longer active.
The new fit vanishes for index matching or zero coat roughness. It is not an
exact isotropic GGX convolution or an exact refractive scattering distribution.
AA is applied once after this intrinsic broadening. Coat AA uses its own normal
derivatives. The same effective axes feed D, Smith, integral lookup and probe mip.

**Approximation boundary:** this is a directional, energy-normalized moment closure
inspired by adding-doubling, not an implementation of all Belcour/Weier equations.
It does not trace refracted ray paths, exactly remap lobe mean directions, or
guarantee BRDF reciprocity. Large coat/base normal disagreement, very rough coats,
grazing angles and strongly directional lighting can differ from a reference path
tracer. Final energy uses actual plain/film Fresnel. No claim of full OpenPBR
layer equivalence is made. Canonical OpenPBR also has different metal-F0 and
partial-coat IOR conventions; numerical appearance comparisons must label these.

## Thin film and IBL

Thin film uses complex s/p Fresnel amplitudes and an Airy Fourier series, integrated
with the published Gaussian XYZ sensitivity fits. Up to 16 harmonics are evaluated;
negligible terms terminate early. Spectral averaging is not a three-wavelength
rainbow lookup. Thickness derivatives damp unresolved phase variation. Colors are
projected into bounded RGB reflectance per dielectric/conductor component at the Fresnel boundary, not clamped after
lighting. Evanescent/frustrated total-internal transmission and polarization output
are not represented. RGB metal dispersion and the finite series remain approximations.

The analytic generalized Fresnel is shared by direct light, its cosine average,
multiple-scatter compensation and the IBL directional-energy estimate. The latter
in Reference quality uses 256 deterministic anisotropic VNDF samples and the existing accurate F=1
geometric energy as a control variate. The old Schlick A/B table is **not** used
as a film-color fit. There is no per-frame random noise and no extra 4D LUT.

Coat and substrate sample probes independently, with their own normal, roughness,
specular occlusion and horizon. SH illuminates only the substrate diffuse lobe.
Two native probes can mean four cubemap samples at full coating and six at
fractional coverage. Native anisotropic probe filtering is still the documented
bent-vector approximation, not an exact elliptical convolution. The film path is
substantially more expensive than plain coat; the joint audit increased this
directional quadrature from 32 to 256 to remove critical-angle energy aliasing.
Critical-angle interfaces smoothly increase this count up to 512 only when the
effective substrate is both rough and strongly anisotropic. This avoids doubling
the cost for every low-index film. Covered plain metal uses 64 samples for its
generalized directional energy and the same optical curve as the film path.
The cosine-average quadrature remains 32. Production frame-time profiling on
real KKS scenes remains necessary. Built-in Gamma multipass limitations remain.

Realtime quality replaces energy quadrature with a shader-owned positive
geometry-only projection table and 32 film evaluations shared by directional
and cosine-average preparation. Direct interference is unchanged. Smooth
critical-angle/index-contrast/thickness guards fall back to Reference where the
low-order fit is not sufficiently safe. See
[FilmOptimization-Validation.md](FilmOptimization-Validation.md) for the data
contract, preserved reference, energy bounds and same-scene toon comparison.

## Files and validation

- Core/TomBSDFLayerTransport.cginc: closure, absorption, relative metal F0, spread.
- Core/TomBSDFMetalOptics.cginc: shared air-F0 optical fit and conductor Fresnel.
- Core/TomBSDFThinFilm.cginc: band integration, complex amplitudes, generalized DFG.
- Material/TomBSDFLayers.cginc: maps, normal frames, AA, energy budgets.
- Material/TomBSDFFilmEnergy.cginc: positive projection, quality and safety guards.
- Lighting/TomBSDFLayerLighting.cginc: direct lobe composition.
- Unity2019 lighting adapter: separate coat/substrate probes and fallback lights.
- Editor/TomBSDFLayeringBridge.cs: explicit isolated fixtures; no startup rendering.
- Tests/validate_layering.py and LayeringCore.compute: CPU/GPU reference checks.
- Tests/validate_layering.ps1: original properties, legacy shaders and manifest audit.

The preserved stage-2 bundle is at
`CodexBridge/Reports/BSDF-Layering/Before-20261011/stage2.bundle`, SHA256
`7102b4d1e2adeec174411ea104e852a84b94c1b28267bca4f800641a49d7c491`.
Bridge `renderbsdflayering` tests unchanged pure-metal controls against it, and
tests disabled layer controls against the corrected bare result. Bridge
`buildbsdffoundation` now also tests layered materials in independently loaded
packaged shaders, including fresh materials and Standard-to-BSDF reassignment.
Historical results are in [Layering-Validation.md](Layering-Validation.md).
The independent full-BRDF audit, approved bare-baseline update and pinned
OpenPBR comparison are in [Stage3-Audit-Validation.md](Stage3-Audit-Validation.md).
The subsequent model calibration and correctly matched coverage reference are in
[Stage3-Calibration-Validation.md](Stage3-Calibration-Validation.md). Its baseline
is the accepted corrected stage-3 package; zero coat remains unchanged against it.

References: [Belcour 2018](https://belcour.github.io/blog/research/publication/2018/05/05/brdf-realtime-layered.html),
[Weier/Belcour 2020](https://jcgt.org/published/0009/02/03/),
[Belcour/Barla 2017](https://belcour.github.io/blog/research/publication/2017/05/01/brdf-thin-film.html),
[Heitz 2018](https://jcgt.org/published/0007/04/01/).
The implementation is local and does not copy or depend on HDRP shader code.
