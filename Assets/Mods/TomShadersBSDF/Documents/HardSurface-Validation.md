# TomBSDF Hard-Surface Environment Stage

Scope: KKS, Unity 2019.4.9f1, D3D11 Built-in Forward. Only `tom/BSDF` and
`tom/BSDFCutout` are extended. The three `xukmi/` prototypes, X shaders, probe
plugin/mod and KK sibling are preserved. The original batch below did not add
anisotropy, coat or transmission. The subsequent anisotropy extension is recorded
at the end. This is not a claim of full OpenPBR parity.

## Implementation

- `Platform/Unity2019/TomBSDFProbeAdapter.cginc`: native probe HDR decoding,
  independent per-probe box projection, Unity receiver blending weights, sky
  fallback and the existing Tom SH Volume MPB protocol. Each probe is decoded
  before interpolation. Only ForwardBase evaluates indirect illumination.
- `Material/TomBSDFSurface.cginc`: independently transformed detail normal,
  with its own UnityPacked/RGB/AG decoding, Y convention, data restoration and
  strength. RNM operates on decoded tangent-space vectors, not texture colors.
- `Core/TomBSDFNormalFiltering.cginc`: RNM and bounded isotropic NDF filtering.
  AA broadens microfacet alpha squared using derivatives of the final normalized
  shading normal. One effective roughness is used by D, G, DFG compensation and
  probe mip selection, identically in Base and Add.
- `Lighting/TomBSDFOcclusion.cginc`: Lagarde-style view/roughness-dependent
  ambient visibility and a geometric-horizon fade. Both affect indirect
  specular only; diffuse retains its separate AO multiplication. Direct light,
  real-time shadow attenuation and emission are not multiplied by these terms.

## Main Controls

| Control | Default | Meaning |
| --- | --- | --- |
| `NormalMapDetail` | bump | Independent detail map and UV scale/offset |
| `DetailNormalMapScale` | 0 | Off by default; no detail texture sample at zero |
| `DetailNormalEncoding` | 0 | 0 UnityPacked, 1 raw RGB, 2 raw AG |
| `DetailNormalFlipY`, `DetailNormalDataRestore` | 0 | Separate detail conventions |
| `ProbeBoxProjection`, `ProbeBlending` | 1 | Native per-probe parallax and two-probe blend |
| `CustomSHVolumeBlend` | 1 | Use assigned Tom SH volume; otherwise native SH |
| `SpecularOcclusionStrength` | 1 | AO-derived probe-specular visibility |
| `SpecularHorizonStrength` | 1 | Suppress reflection directions below geometry |
| `SpecularAAStrength` | 1 | Filter GGX roughness from normal variation |
| `SpecularAAVariance` | 0.15 | Normal-derivative variance scale |
| `SpecularAAThreshold` | 0.2 | Bound on alpha-space filtering kernel |
| `ReflectionColorMode`, `CustomSHColorMode` | 0 | Host convention; 1 explicit sRGB; 2 linear |

Default probe/SH/AA switches may improve/change the new shader's appearance.
To reproduce the foundation comparison, set detail strength, both probe
switches, custom SH blend, both specular-occlusion controls and AA strength to
zero. Keep all pre-existing material inputs and scene settings identical.
This comparison uses the old packaged shader, not a restatement of the new code.
When switching an existing Unity/ME material, matching property names keep their
saved values. In particular, Standard's `DetailNormalMapScale=1` can survive the
switch; a freshly created BSDF material defaults to 0. Reset it explicitly for
an equal-input comparison. The shader does not erase user material state.

ME keeps textures first. Controls are in Normal, Specular Filtering, Environment
and Input Contract. Debug views add 8=decoded probe radiance, 9=specular visibility,
10=effective roughness and 11=custom SH blend weight. View 7 now shows blended SH.

## Reusing Tom Lighting Probes

No second capture plugin or separate BSDF probes are needed. Native reflection
probes work through Unity's renderer bindings. The SH manager recognizes the
existing `_CustomSHVolumeBlend` property, not an X shader-name whitelist.
The atlas is seven horizontally packed RGBA blocks per grid sample, delivered
through `_TomSHVolumeTex`, bounds, grid, transform and parameter MPB fields.
Missing, suppressed, disabled or out-of-bounds volumes fall back to native SH;
edge fading is evaluated per pixel. Receiver selection remains one volume per
renderer, based on renderer bounds center and volume priority.

Two-probe blending requires the receiver's ReflectionProbeUsage to allow it.
Box projection requires probe box data; enabling a material switch alone cannot
create those data. The current TomProbe runtime plugin runs in CharaStudio.
Installing it does not automatically add capture objects to a scene.

### SH Units and Gamma

TomProbe 0.2.x calls Unity 2019 `SphericalHarmonicsL2.AddDirectionalLight` with
solid-angle/pi weights. Unity's API doubles directional input and uses a
peak-normalized L2 cosine kernel: forward-light coefficients 0, 2, 6 are
8/17, 16/17, 5/17. A full constant environment therefore has gain 32/17,
plus numerical cubemap-integration error. The BSDF adapter multiplies evaluated
SH by **17/32** before color decoding and intensity, producing irradiance/pi.
This is a version-specific data conversion, not an artist exposure correction.
The shared atlas/plugin and X receiver math are deliberately unchanged.
Tests verify the Unity API coefficients and a real constant-environment capture.

The legacy runtime integrates camera output as-is. A Linear render target does
not make Gamma shader output linear. Auto/sRGB modes decode after SH evaluation;
this matches constant colors but is only an approximation for mixed radiance.
Decoding an integral is not equivalent to integrating decoded radiance. Mode 2
is for a known linear capture. Correct mixed-scene linear GI needs a future
versioned capture-service contract, not another gain slider or a silent X change.
Native Unity SH is already treated as linear and does not get this correction.

Reflection color mode likewise describes input after Unity HDR decode. Existing
native Gamma capture uses the host convention; a linear-HDR capture service can
explicitly choose mode 2. BSDF cannot infer the encoding of every third-party
capture texture from its pixel format.
Native probe intensity may already be folded into Unity HDR decode parameters;
its Gamma-host scaling is not guaranteed to be linear. Use BSDF's
`ReflectionIntensity` for a gain applied after decoding.

## Validation

Use PowerShell 7 for the property scripts. All GPU jobs are explicitly issued
through Bridge and claimed before execution; none run on Editor startup.

- `Tests/validate_contract.ps1`: shader/manifest/tooltips/defaults and 66 frozen
  prototype/KK baseline files.
- `Tests/validate_hard_surface.ps1`: protected X/probe files, legacy manifest
  blocks, category continuity and integration contracts.
- `renderbsdffoundation`: existing BRDF, inputs, lights, shadows, coverage and
  fog regression tests.
- `renderbsdfhardsurface`: packaged-foundation comparison; RNM/encodings/ST;
  real Unity probe allocation/blending/box/mips/fallback; AO/horizon isolation;
  AA limits, highlight motion and Base/Add consistency; actual TomProbeRuntime
  capture/MPB selection/edge/refresh/suppression with constant-color calibration.
- `buildbsdffoundation`: build and load an isolated test bundle, compare fresh
  and reassigned shader materials, then repeat hard-surface tests using the
  independently loaded packaged shaders. It does not install files into KKS.

The optional SH integration test requires the existing TomProbe.Runtime
authoring DLL. The shader and its bundle do not depend on that DLL to compile
or render native probes/SH. Editor test helpers late-bind the optional DLL so
the BSDF source project also compiles without it. Editor tests use isolated scenes and restore
renderer property blocks, lights, probes and global settings. Runtime Awake
is invoked explicitly in the Edit Mode harness; no plugin startup logic changed.

Reports and PNG captures are under `CodexBridge/Reports/BSDF-HardSurface/`.
Foundation and bundle regression reports remain under
`CodexBridge/Reports/BSDF-Foundation/`. PNGs use the same fixed display mapping
as the foundation tests; numerical checks use unclamped linear float readbacks.
The unchanged SH capture plugin uses its existing RGBAHalf ReadPixels path in
Unity 2019. The BSDF receiver-image comparisons use AsyncGPUReadback; no Unity
5.6 GPU test or automatic startup capture is introduced.

Verified 2026-10-10 (local time):

- Six numerical checks pass; the LUT SHA-256 remains
  `930feee8eec9bc52608e3755cd251b25e1ea5cfb8f82c0352516b26b3d84e274`.
- 364 property/manifest/tooltip/prototype/KK checks pass.
- Foundation regression: 122 checks, 72 captures,
  `../BSDF-Foundation/Render-20261009-161252-397/` under Reports.
- New stage: 139 checks, 75 captures,
  `Render-20261009-161701-255/` under BSDF-HardSurface.
- Packaged shader verification: 155 checks, 77 captures,
  `../BSDF-Foundation/Render-20261009-161704-464/`; summary in
  `../BSDF-Foundation/BundleSmoke/report.json`.
- The frozen 66-file prototype/KK baseline and probe mod/runtime files match.
  Concurrent edits appeared in the separate X project during this session;
  they are recorded as snapshot drift, not overwritten or attributed to BSDF.
  Strict `validate_hard_surface.ps1` reports that drift; use its explicit
  `-AllowExternalXChanges` audit mode for parallel development. The baseline is
  retained, and all non-X checks still run.

The dated folder names are UTC. Useful image pairs in the new-stage directory:
`parity-BSDF-old.png` / `parity-BSDF-new.png`,
`probe-box-off.png` / `probe-box-on.png`,
`occlusion-probe-reference.png` / `occlusion-probe-mid.png`,
`detail-main-reference.png` / `detail-rnm-combined.png`,
`aa-specular-off.png` / `aa-specular-on.png`, and
`sh-runtime-linear.png` / `sh-after-recapture.png`.

## Limits

- Native Gamma framebuffer multi-pass addition remains a display-space
  approximation. Controlled linear-reference captures are labelled separately.
- Specular AO is empirical, not geometry-aware ray tracing or bent-normal AO.
- Derivative AA filters visible geometric/normal variation. It is not TAA,
  LEAN or Toksvig prefiltered variance recovery. AG compression reconstructs Z
  and cannot preserve the original mean-normal length. Very distant detail
  still needs suitable mipmaps or offline normal-to-roughness preprocessing.
- The AA motion metric is image MAE normalized by signal mean, plus peak checks.
  An unfiltered, undersampled needle highlight can lose most energy; raw MAE
  alone can misleadingly prefer that near-black result. No path-traced image
  parity or universal temporal-AA guarantee is implied by this test.
- Additional costs: one optional detail fetch, up to two cube samples, seven
  3D atlas fetches when SH is active, and normal derivatives/filter arithmetic.
  No in-game GPU milliseconds or performance improvement is claimed.
- Actual KKS/ME save/load, capture scheduling and third-party Graphics-plugin
  combinations still need in-game acceptance. No KK changes in this batch.

## References

- [RNM, Barre-Brisebois and Hill](https://blog.selfshadow.com/publications/blending-in-detail/)
- [Improved Geometric Specular AA, Tokuyoshi and Kaplanyan](https://www.jp.square-enix.com/tech/library/pdf/ImprovedGeometricSpecularAA.pdf)
- [Filament ambient and horizon specular occlusion](https://google.github.io/filament/main/filament.html#lighting/occlusion/specularocclusion)
- [Unity 2019 SphericalHarmonicsL2 source](https://github.com/Unity-Technologies/UnityCsReference/blob/2019.4/Runtime/Export/Math/SphericalHarmonicsL2.bindings.cs)
- [Unity 2019 reflection probe blending and box projection](https://docs.unity3d.com/2019.4/Documentation/Manual/AdvancedRefProbe.html)

## Anisotropy Extension

The prior KKS acceptance was confirmed by the user on 2026-10-11. The extension
targets the same two modern entries. Existing prototype shaders, probe service,
X and KK are not part of this change. Public property contract v3 adds:

| Property | Default | Meaning |
| --- | --- | --- |
| `Anisotropy` | 0 | Strength in [0,1], multiplied by the strength map |
| `AnisotropyMap` | white | Linear R strength; independent UV/ST |
| `AnisotropyRotation` | 0 | Degrees in [0,360] in the mesh UV frame |
| `AnisotropyRotationMap` | black | Linear R adds 0..360 degrees; independent UV/ST |

Maps stay in Textures; scalar controls are in Anisotropy, after Normal. The two
data maps share RoughnessMap's sampler state, including wrap/filter settings,
to stay within the D3D11 sampler budget. Import as data; the existing
DataTextureRestore control also covers these two maps. At zero scalar strength
neither map is sampled. A black strength mask returns the isotropic lobe.
Use continuous rotation textures: filtering across a 0/1 angle seam averages
numbers, not circular directions. A 180-degree reversal describes the same
unoriented anisotropic lobe; a 90-degree rotation exchanges its axes.

### Model and Tangent Frame

The new core uses OpenPBR's mean-squared-alpha preserving mapping:
`alphaT = roughness^2 * sqrt(2 / (1 + (1-anisotropy)^2))`,
`alphaB = (1-anisotropy) * alphaT`, with each evaluated axis floored at 0.001
for numerical stability. Strength 1 is a finite regularized limit, not an
infinite ideal line distribution. Direct lights use anisotropic GGX and
height-correlated Smith, including ForwardAdd and the existing fallback lights.

The UV tangent is minimally rotated onto the final main/detail shading normal.
Rotation is applied in this transported frame. UV mirror handedness, negative
object scale and two-sided orientation remain explicit. Explicit zero/degenerate
tangents use derivative UV recovery, also tested with a mirrored normal map.
An absent tangent channel can receive a nonzero constant from Unity, which cannot
be distinguished from authored tangent data in the shader. Import/recalculate
mesh tangents for general normal-mapped anisotropy; missing-channel recovery is
not guaranteed. Geometric/shading hemisphere guards remain
unchanged. Strength 0 selects the existing isotropic D/G and 2D energy table.

### Directional Compensation

`TomBSDFAnisotropyEnergyV1.asset` is a separate shader-owned 3D RGBAFloat resource.
Its logical dimensions are 65 view-cosine nodes, 33 roughness nodes, 33 anisotropy
nodes and 33 azimuth nodes. The physical texture is 65x33x1089, about 35.64 MiB
without mips. RG stores Schlick DFG coefficients, B stores missing hemispherical
average energy, A is the 0.625 contract marker. There is no sRGB conversion or
lossy compression. Unity's ShaderImporter binds it as NonModifiableTextureData,
so it is also a dependency of the existing material/prefab bundle carriers.

Coordinates are `cbrt(NdotV)`, `sqrt(roughness)`,
`-log2(1-anisotropy*1023/1024)/10` and `1-cbrt(1-phi/(pi/2))`. Each anisotropy slab contains
33 azimuth slices; two trilinear reads implement interpolation between slabs.
The warped azimuth grid resolves the narrow-axis grazing boundary; a uniformly
spaced first draft failed expanded angular checks and is not the shipped data.
The missing-average integral accounts for both coordinate Jacobians.

The generator uses a deterministic 4096-sample Heitz VNDF estimator of correlated
Smith G2/G1. Direct-light compensation reads separate directional energies for
view and light; the reciprocal missing-energy lobe is not an isotropic LUT
substitution. The same view integral supplies IBL energy and diffuse coupling.
Missing active anisotropy data produces the established magenta diagnostic,
not an undocumented fallback. Zero scalar strength does not require this table.

### IBL and Filtering Boundaries

Native probe IBL uses the bent-reflection-vector approximation described in
Filament, based on the filtered axes and their frame. The RMS roughness retains
Unity's existing mip convention. Each probe still performs its own box projection
and HDR decode before blending. Horizon visibility uses that same bent direction.
SH diffuse is not bent and is not sampled again in ForwardAdd.

This is NOT an exact elliptical GGX convolution of the environment. In particular,
at normal incidence the bent direction is unchanged: a front-facing flat surface
cannot show a correctly elongated HDR light source using this single-direction
approximation. High-contrast small lights and strong anisotropy can differ from
path-traced IBL. The directional DFG is calibrated; the environment's angular
distribution remains approximate. No extra capture plugin or changed SH protocol
is introduced. Native Gamma and legacy SH-capture limitations above still apply.

AA adds its bounded footprint to both squared slope axes before recovering
effective roughness and anisotropy. This avoids reintroducing a thin axis after
filtering. Direction-field variation additionally isotropizes the covariance at
constant trace. Zero AA strength or threshold is neutral. Effective axes/roughness
are shared by D, G, directional DFG, probe bending and mip selection. This remains
a derivative approximation, not LEAN/Toksvig reconstruction or temporal filtering.

Debug views add 12=world tangent, 13=alphaT/alphaB/effective anisotropy,
14=directional DFG A/B/missing average. Existing debug values retain their meaning.

### Commands and Acceptance

- Generate data outside Assets with `Tests/anisotropy_math.py`; its numerical
  report, binary and CPU cases are in `CodexBridge/Reports/BSDF-Anisotropy/Data`.
- `preparebsdfanisotropy` imports and binds that resource through Unity APIs.
- `renderbsdfanisotropy` runs isolated explicit fixtures. It compares zero strength
  to the independently preserved pre-extension AssetBundle, checks HLSL/CPU BRDF
  and 4D interpolation, maps/ST, frame mirrors, grazing, Base/Add, IBL and AA motion.
- `buildbsdffoundation` now repeats anisotropic rendering using independently
  loaded packaged shaders, including fresh and Standard-switched materials.
- `Tests/validate_anisotropy.ps1` checks preserved inputs/prototypes, new properties,
  binary/report consistency and claimed-before-execution Bridge commands.

All GPU jobs are explicit and claimed before execution. PNGs and float-readback
metrics are stored below `CodexBridge/Reports/BSDF-Anisotropy/`; regression and
bundle checks retain their existing BSDF-Foundation report location. Synthetic
probe fixtures test bindings and deterministic response, not photorealistic
HDR-environment ground truth. No in-game GPU millisecond claim is made.

Verified 2026-10-11, Unity 2019.4.9f1, D3D11, RTX 4070 Ti SUPER:

- 388 contract checks, 116 anisotropy checks and 971 hard-surface checks pass.
  The last uses `-AllowExternalXChanges` to report concurrent X work without
  treating it as a BSDF edit. Prototypes, KK and probe service remain unchanged.
- Numerical integration: maximum DFG absolute error 0.0027745 against 65536-sample
  references; compensated F1 white-furnace error 0.0034229. Reciprocity and
  missing-energy hemispherical averages pass. Binary SHA-256:
  `1072dfebb5a413741c96e7cfc7b82fb06f97f815ab8c5a7b8c85febc5d73934c`.
- Anisotropy Editor acceptance: 145 checks, 86 captures, including an independent
  pre-extension packaged-shader comparison at zero strength. The observed image
  MAE is 0.00000613 for BSDF and zero for Cutout, not a bit-identical compiler claim.
- HLSL BRDF arithmetic error is 0.000000532 relative (denominator floor 0.001)
  against a double-precision CPU evaluation of the same float32 inputs.
  Float32 DFG input rounding adds at most 0.00004534 absolute BRDF error; hardware
  interpolation adds up to 0.0002592 absolute DFG error. Full GPU BRDF versus the
  unrounded reference differs by at most 0.00007413 absolute. Very weak lobes can
  have larger relative errors: about 3.36% in the measured low-roughness case.
  These are recorded separately from model/integration error; they are not
  hidden by clamping the output or loosening the core arithmetic check.
- Existing foundation regression: 122 checks / 72 captures. Existing
  hard-surface regression: 139 checks / 75 captures. Packaged shader tests:
  301 checks / 165 captures, including the new 3D resource, fresh materials,
  Standard-to-BSDF switches and repeated anisotropic rendering.
- Captures visually checked: direct-light 0/90-degree brushed spheres, native
  synthetic-probe 0/90-degree pairs and AA-off/on high-frequency normal surfaces.
  Numerical motion tests verify repeatability, small camera/object changes and
  relative subtexel stability; this is not a claim of TAA or zero shimmer.

Final run directories under `CodexBridge/Reports/` (UTC folder timestamps):

- `BSDF-Anisotropy/Render-20261011-075814-854/`: 145 checks / 86 captures.
- `BSDF-Foundation/Render-20261011-075840-221/`: 301 packaged checks / 165 captures.
- `BSDF-Foundation/Render-20261011-072433-581/`: 122 foundation checks / 72 captures.
- `BSDF-HardSurface/Render-20261011-073726-913/`: 139 checks / 75 captures.

Start with `BSDF-brushed-000.png` / `BSDF-brushed-090.png`,
`frame-mirror-normal-recovered.png` / `frame-mirror-normal-authored.png`,
`grazing-front.png`, `ibl-brushed-000.png` / `ibl-brushed-090.png`,
`aniso-aa-specular-off.png` / `aniso-aa-specular-on.png`, and `motion-*.png`.
Each directory contains its own `report.json`; failed exploratory runs are kept
as diagnostic history rather than presented as the final acceptance.

The new table is shared, not duplicated per material. Its uncompressed GPU cost
is about 35.64 MiB (Unity serialized source is larger). An active directional
integral uses two trilinear 3D fetches; direct lighting evaluates view and light
integrals. Two optional material maps reuse the roughness sampler. The table is
included in the shader bundle even when an individual material uses strength 0.
No new m_/a_ carrier is required. The smoke bundle stays in Reports and has not
been installed into the game; actual KKS/ME load/save and scene acceptance remain
the user's next check before moving on to stage 3 coat/layering.

References: [OpenPBR anisotropy](https://academysoftwarefoundation.github.io/OpenPBR/),
[Heitz GGX visible-normal sampling](https://jcgt.org/published/0007/04/01/),
[Filament anisotropic IBL](https://google.github.io/filament/main/filament.html#lighting/imagebasedlights/anisotropy).
