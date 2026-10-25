# Stage 3 Appearance Calibration (2026-10-13)

KKS, Unity 2019.4.9f1, Built-in Forward, D3D11, Gamma host,
RTX 4070 Ti SUPER. Only the modern `tom/BSDF` and `tom/BSDFCutout` core is
changed. No stage-4 features, KK port, new properties, carrier assets or game
installation are included. The three xukmi prototypes remain frozen.

## Baseline and scope

This follows the independent energy audit, not the defective stage-2 baseline.
The accepted corrected stage-3 package was preserved in
`CodexBridge/Reports/BSDF-Stage3Calibration/Before-20261013/stage3.bundle`:

```
SHA256 06504cc7c652469173f100733dddf1ec8e85e232ce9b055feb743f421af205ba
```

Zero CoatWeight preserves this accepted bare model. Four reference-scene
controls (plastic, mixed metal, metal, Lambert) have exactly zero image MAE
against the independently loaded package. Disabled layer inputs and black coat
mask also remain regression requirements. This does not restore the earlier
bare energy-loss bug that the user explicitly authorized us to correct.

## Correct comparison semantics

The reference stays pinned to unmodified Adobe OpenPBR 1.1.1 source at commit
`c91aad1d`, with the full revision, repositories and license in
`Tests/reference-lock.json`; adapter/source hashes are saved in the external
`BSDF-Stage3Audit/Reference/build-provenance.json`. The C++ adapter exposes diagnostic lobe/coefficient
evaluations but does not change vendor equations. Optional rasterizer-specific
desaturation is not enabled.

OpenPBR's fractional coat modifies intermediate IOR/roughness. Tom uses coverage
of two complete materials. Comparisons now evaluate OpenPBR at coat weights 0
and 1, disable film on the uncoated endpoint, then mix the resulting **complete
BRDFs** by the same coverage. They do not set canonical coat weight to .5 and
claim identical semantics. The earlier canonical-weight comparison is retained
as historical evidence, not the final coverage-matched comparison.

All 32 image cases use the actual Unity-rasterized positions/normal/tangent
frames, one direct light and identical linear material/light values. AA, AO,
IBL and emission are disabled for these comparisons. Metrics use raw linear
RGB before display mapping; every preview uses the same Reinhard + sRGB
display mapping and exposure. The Lambert calibration passes its existing
MAE < 1e-5 and NRMSE < .0001 thresholds. These are BRDF evaluator images, not
path-traced scene comparisons.

Metal BaseColor in Tom means air-interface F0. Covered plain conductor reflection
adjusts that same fitted n,k to the coat medium; film uses the same n,k. The
pinned plain OpenPBR uses its artist F0 convention. Thus same-parameter full
images are useful appearance comparisons but **not matched optical-data
equivalence**. A separate 12-case test at identical n,k, interfaces and three
wavelengths isolates the thin-film Fresnel math: max difference 4.621e-6.

## Model changes and isolated diagnostics

- Internal coat reflection now interpolates smooth/rough hemispheric estimates
  using substrate roughness and specular fraction. Previously every substrate
  used the fully rough internal estimate, darkening colored metals unnecessarily.
- Direct absorption uses the actual incident light and escaping view angles.
  Indirect incident absorption and interior round-trip absorption have separate
  16-point cosine averages; view absorption is no longer reused for both legs.
- Plain and film metal optics share the neutral-edge Gulbrandsen air-F0 fit.
  The near-perfect conductor complex root uses a cancellation-resistant
  float32 expression. 90 GPU/double optical cases pass; max error 1.789e-7.
- Substrate roughening uses a bounded RMS fit, not loop-amplified variance that
  could saturate roughness and erase anisotropy. Intrinsic axis ratio is retained.
  AA is applied once afterwards; D, Smith, energy and IBL use the resulting axes.
- Generalized plain-metal directional energy uses 64 VNDF samples. Film uses
  256, smoothly rising toward 512 only for low-index critical-angle interfaces
  that are both rough and strongly anisotropic. This retains deterministic
  sampling and avoids doubling the cost of every low-index film.

`Tests/diagnose_stage3_calibration.py` compares six ablation choices over six
colored-metal profiles: old closure, internal-only, optics-only, combined
transport/optics, isotropic spread and axis-ratio-preserving RMS spread. It saves
both angular axes, full profiles, peak, half-width and 1D tail fractions outside
20 degrees, not only a peak brightness adjustment. Those tail fractions are not
hemispheric energy integrals. An isolated exact-IOR single-scatter Coat control
matches the pinned minimal Coat lobe (max profile NRMSE 2.596e-7). Production Tom
Coat deliberately keeps Schlick and multiple-scatter compensation; the pinned
minimal Coat uses exact dielectric Fresnel and no microfacet MS term. Its rough
Coat is therefore not a strict target for our compensated Coat brightness.
For example, the moderate coat/aniso profile NRMSE decreases .2426 -> .0402;
the rough-coat/strong-aniso no-film profile decreases .7842 -> .0699 on the major
axis and .6999 -> .0664 on the minor axis.
An isotropic-spread candidate can fit one profile slightly better but suppresses
directionality on rough coats; it is not the selected model.

Selected coverage-matched Unity/OpenPBR full-image NRMSE:

| Case | Before | Calibrated |
| --- | ---: | ---: |
| Mixed metal, full coat | .1868 | .0351 |
| Colored metal, full coat | .3181 | .0634 |
| Coat roughness .5, anisotropy .85 | .7225 | .0821 |
| Coat roughness .9, anisotropy .85 | .7456 | .1015 |
| Metal film 400 nm | .3596 | .0530 |
| Metal film 900 nm | .4587 | .1631 |
| Tinted coat, light +65 degrees | .0825 | .0479 |

These are individual fixture results, not universal error bounds. The dielectric
400-nm film case slightly increases .1131 -> .1139; not every spectral appearance
converges toward the three-wavelength reference.

## Independent furnace and numerical results

- 8748 complete-BRDF double-precision cases, 4096 MIS samples each: no invalid
  output or over-energy cases at the existing 1.5% acceptance threshold.
  Worst white error over bare, fractional and covered material: .008100 (0.81%).
- 109 refined cases at 16,384 / 65,536 MIS samples include colored material,
  directional absorption and differing normals. Max convergence difference
  .003989; refined worst lossless error .008054.
- 26,571 GPU production-BRDF point evaluations: no mismatch; max relative error
  for reference peaks above .01 is .000654. The original tolerance remains
  `.0002 + .012 * peak`, with max used tolerance fraction .0395.
- 109 independent GPU furnace sums vs CPU: max difference 5.719e-5;
  worst GPU lossless error .007980. No output clamp after lighting is used to
  hide energy gain. Per-component bounded RGB Fresnel projection remains explicit.
- 507 Unity audit checks pass, including the optics test and reference controls.
- Eight standalone transport/Airy/VNDF tests pass. Sixteen-harmonic max error vs
  128 harmonics is .0160; adaptive VNDF max error vs 16k samples is .007685.
- Static audit passes 16 groups, containing 504 contract, 68 layering,
  116 anisotropy and 973 hard-surface checks. Manifest and public property
  defaults/ranges are identical to the accepted pre-calibration snapshot.

Fresh explicit Bridge regressions also pass:

| Suite | Checks | Captures | Saved directory |
| --- | ---: | ---: | --- |
| Foundation | 122 | 72 | BSDF-Foundation/Render-20261013-120724-777 |
| Hard-surface / probe / SH / AA | 139 | 75 | BSDF-HardSurface/Render-20261013-121226-066 |
| Anisotropy / mirror UV / motion / AA | 145 | 86 | BSDF-Anisotropy/Render-20261013-121328-993 |
| Layering / disabled controls / film / AA | 173 | 95 | BSDF-Layering/Render-20261013-121522-751 |
| Independently loaded package | 448 | 245 | BSDF-Foundation/Render-20261013-121946-854 |

All directories above are under `CodexBridge/Reports`. The package test checks
Editor parity for fresh and Standard-switched materials, both shader entries,
native point/spot light variants and shader-owned energy resources. Foundation
shadow/cookie/cutout tests remain passing. These are Editor regressions, not
runtime-game acceptance. Including the 507 calibration assertions, all six GPU
suites pass 1534 assertions; overlapping assertions are counted per suite.

The pinned reference still returns about 1.62-1.64 energy in the documented
thin-film boundary case under both its sampler and independent eval/MIS.
Tom returns about .995. This particular reference gain is not an appearance
target or a claim about all OpenPBR implementations.

## Performance observation

The saved benchmark is an isolated 512x512 quad, six warmed samples of eight
Camera.Render calls followed by an explicit GPU-complete readback wait. It
measures **CPU + GPU + driver/readback completed latency**, not GPU timestamps
or live KKS frame time. Identical old/current materials are compared on the
same Editor/GPU; variability and all individual samples are saved.

| Material | Before median ms | Calibrated median ms |
| --- | ---: | ---: |
| Bare | .193 | .196 |
| Plain metal coat | .428 | .340 |
| Film metal | 12.423 | 12.190 |
| Film mixed metal | 21.193 | 21.489 |
| Low-index film, moderate roughness | 7.544 | 7.335 |
| Low-index film, rough + strong anisotropy | 5.251 | 10.927 |
| Absorbing coat | .402 | .322 |
| Plain coat, three pixel lights | .842 | .630 |

Plain coat and zero-coat costs are acceptable within this narrow observation.
Film is still very expensive, and the high-risk upsampled case approximately
doubles here. This is a measured cost of the accuracy correction, not a
production performance pass. Live KKS profiling and a faster film-energy
representation remain necessary; do not assume the benchmark proves realtime
readiness at full-screen coverage or many lights.

## Remaining approximation boundaries

The RMS rough-transmission fit improves width/tails and anisotropic shape but
is not exact GGX convolution or exact refraction of the lobe mean. Internal
reflection/Beer averages factorize angular populations, so reciprocity and
strongly mismatched normals are not exact. Very rough coat and grazing-angle
shape still differ from the pinned reference.
The rough Coat lobe itself also differs because production Tom uses compensated
Schlick GGX, while the pinned reference's minimal Coat is uncompensated exact-IOR
single scattering. This difference is isolated in the saved profile controls,
not silently attributed to substrate transmission.

Film uses finite band-integrated sensitivity fits with RGB-fitted metal optics,
not measured spectral dispersion; the reference uses three wavelengths. Color
differences remain, especially at 900 nm. Frustrated total-internal transmission
and polarization outputs are not represented. Native probe IBL remains a
bent-vector anisotropic approximation. These are deliberately deferred, along
with exact spectral rendering and full refractive transport. This calibration
does not add transmission, stage 4 or KK compatibility.

## Saved evidence and reproduction

Latest accepted calibration directory:
`CodexBridge/Reports/BSDF-Stage3Calibration/Render-20261013-120515-868`.

- `report.json`: Unity audit, unchanged thresholds and zero-coat controls.
- `pointwise-gpu.bin`, `pointwise-summary.json`, `furnace-gpu.bin`: raw values.
- `reference-sources.json` and geometry bins: exact fixture/reference inputs.
- `performance.json`: every before/current timing sample and measurement scope.
- `OpenPBR/comparison-1.png` through `comparison-4.png`: old/new/reference/error.
- `OpenPBR/*-openpbr.npy`: raw linear reference pixels.
- `OpenPBR/comparison-report.json`: image metrics, source hashes, ablations.
- `OpenPBR/joint-white-furnace.png`, `furnace-convergence.png`, `performance.png`.
- `Data/diagnosis.json`, `ablation-lobes.png`, `ablation-profiles.npz`: isolated
  Coat and full-lobe major/minor profiles, widths and tail fractions.
- `Data/isolated-optics.png`, `optical-curves.npz`, `metal-optics.json`: separate
  plain/film and matched-optical-data tests.
- `Final/joint-furnace.json`, `Data/refined-furnace.json`: independent integrals.
- `Final/calibrated-20261013.bundle`: independently built, loaded and tested
  calibration package, SHA256
  `7ff046001ac0318b5d14686dd99ff8a4ba8ddcd75abc4c42e846b152fbc74811`.
- `acceptance-index.json`: links the final numerical, visual, regression and
  package evidence without overwriting the earlier audit's baseline/results.

The earlier `Render-20261013-115115-480` is retained as a **failed diagnostic**:
only the near-perfect conductor precision check failed. It is not final
acceptance and was not replayed automatically.

```powershell
C:/ProgramData/anaconda3/python.exe -B Assets/Mods/TomShadersBSDF/Tests/scan_stage3.py --corrected --calibrated --label Final
C:/ProgramData/anaconda3/python.exe -B Assets/Mods/TomShadersBSDF/Tests/prepare_stage3_audit.py --report Final --calibrated
C:/ProgramData/anaconda3/python.exe -B Assets/Mods/TomShadersBSDF/Tests/diagnose_stage3_calibration.py
pwsh -NoProfile -File Assets/Mods/TomShadersBSDF/Tests/validate_stage3.ps1 -Calibrated
```

After an explicit `renderbsdfstage3audit` Bridge command completes successfully:

```powershell
C:/ProgramData/anaconda3/python.exe -B Assets/Mods/TomShadersBSDF/Tests/compare_openpbr_stage3.py --calibrated --render <successful-render-directory>
```

No GPU work runs on startup. A claimed command is never retried automatically
after a crash, and test scenes are isolated from the user's work.
