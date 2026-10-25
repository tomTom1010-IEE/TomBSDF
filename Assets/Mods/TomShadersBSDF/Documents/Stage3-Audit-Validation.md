# Stage 3 Joint Scan, Independent White Furnace And OpenPBR Comparison

Historical audit: 2026-10-13, KKS modern Opaque / Cutout, Unity 2019.4.9f1,
D3D11, controlled linear output in the Gamma authoring template. The later
[appearance calibration](Stage3-Calibration-Validation.md) corrected partial-coat
reference semantics and updated internal reflection, conductor optics and roughening.
The canonical differences below are not the final semantically aligned comparison.

## Corrections

- Evaluate dielectric / conductor multiple scattering and film separately, then
  blend complete responses by metallic. Mixing F0 before nonlinear compensation
  caused severe mixed-metal energy loss.
- Use only the dielectric remaining energy for diffuse, without repeatedly
  reducing it by the mixed conductor response.
- Close bare dielectric energy for the viewing direction, removing extra
  double-ended attenuation. The user explicitly approved updating zero-coat
  appearance. Zero coat still ignores layer controls; pure-metal / IOR1 Lambert
  controls remain neutral.
- Project dielectric / conductor film RGB separately, not by clipping final light.
  Directional Fresnel increased from32 to256 fixed VNDF samples at this milestone.
- Use stable small-argument log / exp evaluation in layer roughening.

The corrected closure prioritizes the directional white furnace; it does not
prove full-material reciprocity. EON / microfacet components remain reciprocal.
Layer energy / moments, normal perturbation and geometric horizon limits are not
exact refractive path tracing.

## Independent Method

8748 joint cases varied metallic, roughness, base / coat IOR, coat roughness,
anisotropy, NdotV, film and coat weight, using4096 balance-MIS samples.88 refined
cases used16384 /65536 samples for endpoints, grazing, independent normals,
absorption, coverage and0-2000nm film.

NumPy float64 evaluated the actual complete pointwise BRDF and integrated
`f*cos/pdf`. It did not report runtime IBL / layer budgets as measured furnace
energy. Samples below the geometric hemisphere retained their sampling PDF and
zero response rather than changing the estimator by rejection. GPU production
material / layered-light functions were compared at26244 points and integrated
with the same88 sample sets via ARGBFloat / AsyncGPUReadback.

23 appearance cases used exported rasterized geometry / tangent / handedness,
fixed light / exposure and linear inputs. IBL / AO / emission / AA were disabled.
Images used Reinhard+sRGB for display; numerical metrics were computed beforehand.

| Measurement | Before | After |
| --- | --- | --- |
| Worst joint-furnace RGB error | 0.749808 | 0.008107 |
| Joint cases above1.015 | 18 | 0 |
| Nonfinite / negative cases | 0 | 0 |
| Refined nonabsorbing CPU maximum error | Not measured at this stage | 0.006777 |
|16k /65k convergence difference | Not measured at this stage | 0.003988 |
| GPU furnace maximum error | New check | 0.007446 |
| Same-sample GPU / CPU integral difference | New check | 0.000280 |
| Out-of-tolerance GPU / CPU points |14 in an earlier correction |0 of26244 |

GPU furnace tolerance was1.5%; same-sample integral tolerance0.004. Pointwise
tolerance was `0.0002+0.012*max(0.001,peakReferenceRGB)`; final maximum tolerance
usage0.579.393 GPU checks passed,138 scene / geometry images were retained.
These finite-domain results are not a global proof over every allowed parameter.

## OpenPBR Reference

Unmodified Adobe openpbr-bsdf1.1.1 was pinned to
`c91aad1d1ce1693e803f039d7c92c2965c4eb013`, GLM1.0.1 to
`0af55ccecd98d4e5a8d1fad7de25ba429d60e863`. The upstream default nonreciprocal
coat configuration and620/540/450nm RGB wavelengths were retained. Reference
code was test-only, not included in shipping Passes. Units / absorption mapping
were explicit; Lambert raw RGB MAE2.80e-8 calibrated geometry / light conventions.

| Single-light raw linear image NRMSE | Before | After |
| --- | --- | --- |
| Bare plastic |10.03%|1.81%|
| Bare mixed metallic |18.95%|0.73%|
| White mixed metal, roughness0.15 |73.58%|7.83%|
| White mixed metal, roughness0.75 |74.44%|2.81%|

This was **not appearance parity**. Rough coat / metal cases still reached about
32% NRMSE and some film metals about46%. Roughening moments, fitted conductor
index, RGB film integration and environment filtering differ from the reference.
Equal total energy must not be presented as equal appearance.

A separately recorded reference boundary case gave upstream sampling and
independent eval/PDF MIS energy approximately1.63 at131072 samples, versus
Tom about0.995. Agreement of two reference estimators made this an explicit
out-of-domain target, not an energy gain for Tom to imitate. This is not a claim
that every OpenPBR configuration has that behavior.

## Evidence And Regression

Developer evidence remains under `CodexBridge/Reports/BSDF-Stage3Audit`, including
BeforeExact / Final furnace JSON, refined inputs / PDFs, production GPU results,
23 OpenPBR comparisons and immutable pre-change source. Failed intermediate
runs remain failed. Raw evidence and CPU / GPU fixtures are not in this overlay.

Historical regressions passed: foundation122 checks /72 images; environment139
/75; anisotropy145 /86; layers173 /95; independent Bundle448 /245.
Static checks passed502 contract,68 layers,116 anisotropy and973 hard-surface
checks. Six basic math and eight film / absorption checks passed. Film Fresnel
256/16k discrepancy was0.007684, versus the old32-sample value about0.026846.
No new public properties / carriers were introduced by this audit.

The directional Fresnel integration change was about8x for that integral, not
8x for the whole shader / frame. Later optimized film is separately documented.
The historical batch was not game deployment, KK porting, stage4 or a KKS GPU
performance certification. Current release acceptance is in [Release Status](Release-Status.md).

References: [pinned Adobe implementation](https://github.com/adobe/openpbr-bsdf/tree/c91aad1d1ce1693e803f039d7c92c2965c4eb013)
and [OpenPBR specification](https://github.com/AcademySoftwareFoundation/OpenPBR).
