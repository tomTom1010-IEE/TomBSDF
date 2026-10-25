# Thin Film Realtime / Reference (2026-10-14)

Scope: modern KKS `tom/BSDF` and `tom/BSDFCutout`, Unity 2019.4.9f1, Built-in
Forward, D3D11, RTX 4070 Ti SUPER. No stage 4, KK port, xukmi prototype change,
V+ or lilToon source changes. Public property contract is now version 5.

## Quality contract

`ThinFilmQuality` is the only new public control, under **Thin Film**:

- 0, Realtime (default): geometry-only precomputed positive Fresnel projection
  weights, 32 angular film evaluations, reused for directional and average energy.
- 1, Reference: the preserved 256-512 VNDF directional integral and 32-point
  cosine average. It is a reference for our model, not exact spectral path tracing.

Direct-light interference uses the same band-integrated Airy implementation in
both modes. Plain and film metal optical data, transport, roughening and shading
normals are unchanged. Only the generalized Fresnel **energy preparation** is
approximated. Zero film / zero coat ignores the quality setting.

The original core file `Core/TomBSDFThinFilm.cginc` is byte-identical to the
preserved package snapshot. Reference-mode Editor images match that independently
loaded package with MAE about 1.795e-10 for both shader entries.

## Positive geometric projection

The table stores expectations of piecewise-linear angular basis functions under
the GGX visible-normal reflected-energy distribution. It contains no material
color, thickness or IOR data. Runtime film values are evaluated at 32 uniform
microfacet cosines; nonnegative weights form a normalized partition. Unit Fresnel
stays unit Fresnel, bounded Fresnel remains bounded, and the existing accurate
F=1 geometric energy is retained as the control variate. No final lighting clamp
is introduced. The same evaluations supply the exact cosine integrals of the
piecewise-linear reconstruction for average Fresnel/MS compensation.

Axes: 65 view-cosine samples, 17 perceptual-roughness samples, 17 warped anisotropy
samples and 9 warped azimuth samples. Eight RGBA groups hold the 32 coefficients.
The shipping resource is `ResourcesData/TomBSDFFilmEnergyV1.asset`,
65x17x1224 RGBAHalf, about **10.32 MiB** GPU data, no mipmaps. Its sampler state is
shared with the anisotropic energy lookup; no additional sampler state is needed.
The data is shared by materials, not generated separately per material.

`generate_film_energy.py` bakes 2048 deterministic VNDF samples per state.
The proof records no negative coefficients and max partition error 1.193e-7.
The independent CPU oracle includes RGBAHalf quantization and multilinear lookup,
not just an ideal unquantized/exact-coordinate table.

The Bridge generates and binds this native asset using ShaderImporter
SetNonModifiableTextures. It is not a user texture slot. Both shaders diagnose
missing/wrong-size projection data in Realtime mode; Reference needs no fast table.
Sharing the Unity project requires this asset and Unity-generated metadata;
existing `m_BSDF`/`a_BSDF` carriers do not need replacement or manual rebinding.

## Conservative continuous fallback

Realtime is not promised to be faster for every material/angle. Preliminary
unprotected fits failed the white furnace for steep critical-angle responses.
The existing 1.5% acceptance bound was not loosened. Realtime smoothly blends
back toward Reference for:

- large incident/film index contrast (ratio 1.1 to 1.25);
- low-index films becoming thick (400 to 800 nm);
- narrow GGX distributions viewing near the critical angle (roughness .15 to .35,
  distance from critical cosine .02 to .08).

The max of these continuous guards chooses the reference fraction. At full
fallback no table-based evaluation is performed. Transitions may evaluate both
paths and remain expensive. This is an explicit approximation/safety boundary,
not a hidden claim that low-index/thick or narrow/grazing films are cheap.
Existing phase-variance filtering is used at every film node; no frame-dependent
random noise is introduced. AA-filtered intrinsic axes select the projection.

## Numerical and image evidence

- 8748 joint independent complete-BRDF CPU cases, 4096 MIS samples: max white
  error .008607; invalid and over-energy counts zero at the unchanged 1.5% bound.
- 109 refined CPU cases, 16,384 / 65,536 MIS samples: max lossless error .008876,
  max convergence .003989. Includes colored/absorbing material and normal limits.
- 26,571 GPU production points vs independent double precision: zero mismatches;
  max relative error for reference peaks above .01 is .000707.
- 109 GPU production furnace sums: max CPU difference .000372,
  max lossless white error .008896. Original per-point and furnace tolerances hold.
- 443 explicit Unity film checks pass, 50 captures. Zero weights, missing
  resources, archived Reference parity, 400/800-nm guard boundaries and coat AA
  controls are included.
- Six standard film sphere pairs, raw linear image max NRMSE .000505 (0.051%).
  Critical-interface fixtures also pass their declared 5% NRMSE bound. These
  fixture results are not a universal appearance-error guarantee.
- Static preservation audit: 86 groups pass, including 512 input/manifest,
  68 layer, 116 anisotropy and 973 hard-surface checks. The only additional public
  property is ThinFilmQuality. Existing property defaults/ranges are unchanged.
- Separate followup passes 56 probe/motion/AA assertions: directional Probe-only
  and Probe + direct light at anisotropy 0/.85/1 differ from Reference by at most
  .273% image NRMSE. Nine critical narrow-lobe frames with main/detail normal
  and AA differ by at most .510%; no excess motion jump at the declared bound.
  A 400-800-nm thickness-map/phase-filter/fallback fixture differs by .281%.
  Saved in `Render-20261013-192728-483`. These are targeted fixtures, not general
  reciprocity/spectral or all-camera stability guarantees.
- Foundation regression passes 122 assertions/72 captures, including point/spot
  shadows, cookies, fog and cutout, in
  `BSDF-Foundation/Render-20261013-191444-507` under the common report root.
- Final independently loaded package passes 448 assertions/245 captures, including
  Editor parity, fresh/Standard-switched materials, full layer behavior, probes,
  SH, specular occlusion, detail normals, AA, anisotropy and mirrored frames.
  Saved in `BSDF-Foundation/Render-20261013-193809-209`. The new film table is a
  verified bundle dependency. All four GPU suites pass 1069 assertions; overlapping
  assertions are counted per suite. No game installation is updated.

## Same-scene performance

Identical quad/camera/RT/light setup, no shadows/outline/MSAA/postprocessing,
6 warmed samples, 8 Camera.Render calls per sample followed by GPU-complete
readback. This is **CPU + GPU + driver/readback completed latency**, not GPU
timestamps, and is not an in-game FPS prediction. All individual samples/p95s
and 72 material/resolution/light configurations are saved.

Compared local shader entries: KKS port `lilToon` and V+ LTS
`xukmi/MainOpaquePlus`. Their regular opaque paths are measured, not fur,
transparency, tessellation or all features enabled. xukmi's ForwardAdd control
is explicitly enabled for the pixel-light comparison; neither sibling source
nor their serialized materials is changed. Same scene does not imply identical
BRDF, colors or photometric output across toon and PBR.

512x512 medians in ms:

| Configuration | One pixel light | Three pixel lights |
| --- | ---: | ---: |
| BSDF bare | .247 | .254 |
| BSDF plain coat | .395 | .631 |
| Film metal Realtime | 1.438 | 3.687 |
| Film metal Reference | 9.223 | 24.113 |
| Film mixed metal Realtime | 2.258 | 6.187 |
| Film mixed metal Reference | 17.172 | 45.398 |
| Rough/aniso low-index film Realtime | .726 | 1.641 |
| Rough/aniso low-index film Reference | 7.477 | 21.558 |
| lilToon basic | .261 | .304 |
| lilToon reflection | .255 | .304 |
| xukmi basic | .234 | .275 |
| xukmi MatCap | .311 | .274 |

Metal/mixed-film speedups are about 6.4-7.6x at 512x512. The tested rough low-index
400-nm film gains 10.3-13.1x; it is not a fully guarded thick-film case. Small
differences between toon feature toggles are within the timing/host-overhead
scale and should not be interpreted as reflection making shaders faster.

Realtime film is still materially more expensive than ordinary toon. At
1024x1024 with three lights, mixed-film Realtime is 24.744 ms vs Reference
170.628 ms in this fixture. Large coverage/many lights are not declared
production-performance accepted. Native ForwardAdd repeats material preparation;
further spectral/node-work optimization or shared preparation remains possible,
but no new scene buffer/companion pipeline is introduced in this batch.

## Saved results and commands

All paths below are under `CodexBridge/Reports/BSDF-FilmOptimization`:

- `Before-20261014/reference.bundle`: immutable accepted high-precision package,
  SHA256 `7ff046001ac0318b5d14686dd99ff8a4ba8ddcd75abc4c42e846b152fbc74811`.
- `Data/film-kernel.bin`, `kernel-proof.json`: reproducible projection and hash.
- `Final/joint-furnace.json`, `Data/refined-furnace.json`: independent integrals.
- `Render-20261013-190834-420/report.json`: accepted film GPU run.
- That render's `Analysis/summary.json`: image errors, speedups and source hashes.
- `Analysis/performance-1-lights.png`, `performance-3-lights.png`: all resolutions.
- `Analysis/film-metal-*-nm-*.png`: Reference/Realtime/raw error comparisons.
- `Final/film-realtime-20261014.bundle`: tested package, SHA256
  `a5a2e832d2f95aed99c3d361ed217798d073d795b63f921fb36eaec56ce5cfbd`.
- `acceptance-index.json`: final numerical, GPU, performance and package paths.

The render folder uses UTC naming; the local run date is 2026-10-14.
The first preparation command was consumed by the old Bridge assembly before
script reload and returned "unknown operation". It created no resource; a fresh
explicit command after reload completed successfully. No GPU job was replayed
automatically after a crash, and user scenes were not edited.

```powershell
C:/ProgramData/anaconda3/python.exe -B Assets/Mods/TomShadersBSDF/Tests/generate_film_energy.py --samples 2048
C:/ProgramData/anaconda3/python.exe -B Assets/Mods/TomShadersBSDF/Tests/scan_stage3.py --calibrated --film-fast --label Final
C:/ProgramData/anaconda3/python.exe -B Assets/Mods/TomShadersBSDF/Tests/prepare_stage3_audit.py --calibrated --film-fast --report Final
pwsh -NoProfile -File Assets/Mods/TomShadersBSDF/Tests/validate_film_optimization.ps1
```

Explicit Bridge commands: `preparebsdffilm`, then `renderbsdffilm`. After a
successful result, run `analyze_film_optimization.py --render <render-directory>`.
Do not queue GPU jobs on startup or automatically retry a crashed command.
