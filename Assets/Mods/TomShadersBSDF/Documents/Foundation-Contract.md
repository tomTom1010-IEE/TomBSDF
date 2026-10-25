# TomBSDF Foundation Contract v1

Target: KKS, Unity 2019.4.9f1, Built-in Forward, D3D11/SM4.5. The legacy
`xukmi/TomBSDFBase`, `xukmi/TomBSDF`, and `xukmi/TomBSDFAlpha` remain unchanged.
New entries are `tom/BSDF` and `tom/BSDFCutout`. KK is frozen during this work.
The machine-readable public property contract is `Foundation-Properties.json`.

This document records the initial foundation. The property contract is now v3;
probe/SH, detail-normal and specular-filtering additions are documented in
[the hard-surface stage](HardSurface-Validation.md). Its additions supersede the
deferred-feature statements below without changing the v1 energy LUT contract.
Anisotropy adds a separate directional integral resource, leaving the original
isotropic table intact. See the anisotropy section of the hard-surface report.
The 2026-10-13 stage-3 audit also corrects the bare material energy model;
the user explicitly approved updating the zero-coat baseline. The initial
two-ended diffuse attenuation is no longer the shipping behavior.

## Physical model

- Perceptual roughness is in [0,1]; GGX alpha = max(roughness squared, 0.001).
  The floor is numerical regularization, not the old global roughness=0.04 clamp.
  Subpixel mirror highlights can still alias; normal/specular AA is next-stage work.
- Height-correlated Smith visibility, Schlick Fresnel, and reciprocal Kulla/Conty
  multiple-scattering compensation share exactly the same GGX integral resource.
- Dielectric F0 comes from IOR relative to air. SpecularWeight scales that
  dielectric lobe, including grazing reflection. Metallic is a conductor mixture;
  its F0 is baseColor and it has no diffuse. IOR=1 disables the dielectric interface.
- Diffuse uses EON with single-scattering albedo=baseColor and independent
  diffuse roughness. Zero diffuse roughness reduces to Lambert.
- Dielectric and conductor multiple scattering are evaluated separately before
  metalness interpolation. Interpolating F0 before nonlinear compensation loses
  energy for intermediate metalness. Diffuse couples only to the dielectric
  directional specular energy, not to the already mixed conductor response.
- The opaque dielectric substrate uses view-side remaining specular energy.
  This fixed-view closure restores the white furnace but is not reciprocal;
  EON and the microfacet specular terms individually remain reciprocal. This is
  a documented real-time closure, not exact dielectric/diffuse interreflection.
- Both geometric and shading normals must face the light and viewer for direct
  reflection. The microfacet G term and the scene shadow visibility are separate.
- Core types/math have no Unity light globals, texture sampling or color decoding.

Algorithm references: [EON](https://arxiv.org/html/2410.18026v3), especially
equations 10, 14, 15 and 19; [Filament multiple scattering discussion](https://google.github.io/filament/main/filament.html#materialsystem/standardmodel/energycompensation).
The EON polynomial coefficients are attributed to Portsmouth, Kutz and Hill.
The implementation is an HLSL expression of the equations, not an imported
renderer. The numerical reference and resource generator are project-local.

## Texture and value contract

- MainTex RGB times BaseColor enters the core as linear reflectance. Alpha is
  coverage data and is never color-decoded. White/no texture leaves BaseColor.
- Metallic, Roughness and Occlusion maps use R, each multiplied by its scalar.
  White/no map preserves the scalar. Optional ORM packs AO/Roughness/Metallic in
  RGB and uses the same scalar multipliers. AO strength interpolates from 1.
- AO affects indirect diffuse only in this foundation. It never attenuates
  direct light, scene shadow visibility or emission. Specular occlusion is later.
- NormalEncoding is explicit: 0 Unity-imported packed, 1 raw RGB XYZ, 2 raw AG XY
  with positive Z reconstruction. Raw normals are normalized, XY strength and
  optional Y flip are applied. Scale=0 is flat. The default native bump texture
  is neutral for the default UnityPacked mode; selecting RGB/AG requires a map
  of that encoding. No heuristic guesses based on a texture's displayed color.
- Emission uses EmissionMask RGB times EmissionColor times linear intensity;
  black/no map gives zero. It is added once in ForwardBase.
- BSDFCutout coverage = MainTex.a * AlphaMask.r * Coverage. All three passes use
  the same UV/ST and threshold; exactly zero coverage is always removed. BSDF
  opaque ignores texture alpha. This is not translucency or optical transmission.
- Each texture retains its own ST. There is no implicit skin alpha_a/alpha_b,
  reverse shadow alpha, ramp, matcap, outline, liquid or old PBRSpecular curve.

The color-input controls describe the values *after texture sampling* or as
uniforms. Auto now follows the explicit **KKS Linear** contract, independent of
the Gamma authoring/build setting. Explicit sRGB/Linear modes handle ME-created
textures and script-written colors without guessing their importer.
DataTextureRestore and NormalDataRestore undo unwanted sRGB sampling of data
in the Linear player; correctly imported data leaves them at 0. Alpha channels
are never color-decoded or restored.
These adapters cannot inspect or fix a runtime Texture object's import metadata.

## Light and display contract

One Unity numeric light unit maps to pi incident irradiance at normal incidence,
so a white Lambert surface under a unit unattenuated light produces one linear
unit. This is a reproducible legacy-light calibration, not a lumens/lux claim.
The default treats Unity's combined RGB/intensity as linear numeric input and
preserves intensity ratios. Optional sRGB-composite decoding cannot recover
separate color and intensity from Gamma-host light constants. A future runtime
adapter can provide calibrated linear light data without changing core math.

ForwardBase adds the main light, VERTEXLIGHT_ON fallback lights, SH/probe and
emission. ForwardAdd adds only the currently assigned light with full Unity
shadow variants. Unity attenuation includes distance, cookie and visibility and
is applied once. Add uses black fog and never repeats indirect light or emission.
Non-pixel fallback lights have Unity's unshadowed fallback behavior; full shadows
require per-pixel assignment and enabled host shadow resources. Pixel-light
budgets and Unity's transitional allocation remain engine responsibilities.

Modern shaders now always output linear scene light for KKS, including Base,
Add, fog and emission. `_TomBSDFLinearOutput` is no longer read by production
shaders; no companion or test global is needed for correct basic color. The
Gamma authoring Scene/material preview is not a KKS display reference; Bridge
checks use linear float targets and encode only saved display PNGs. No
material-level tone mapper or project-wide color-space change is installed.
See [the current host contract](SceneLighting-Contract.md#host-color-profile-and-packaging)
for Gamma-main-project packaging and explicit HDR Probe decoding.

The foundation environment adapter evaluates Unity SH and one prefiltered
reflection probe. Probe0 uses Unity's roughness-to-mip mapping and HDR decoding;
its response uses matching directional energy. Full box projection, probe
blending, lightmaps/LPPV, anisotropic IBL, detail normals and specular AA have not
been implemented in this milestone. Their controls are not exposed.
Unity's replacement DepthNormals shader is also outside this material's pass
dispatch: its built-in cutout test does not know the custom AlphaMask/Coverage.
No claim is made that custom coverage already appears in every postprocess buffer.

## Energy resource and ME delivery

`Tests/foundation_math.py` deterministically generates a 65x65 table with 16384
visible-normal samples/node. Coordinates cover cbrt(mu) and sqrt(perceptual roughness),
including endpoints. R/G are Schlick DFG A/B; B is **missing average energy**;
A is the contract marker 0.5. Texture format is RGBAFloat, linear, bilinear,
clamp, no mips/compression. Sampling uses endpoint-to-texel-center remapping.

The table is independent of any material preset. `preparebsdffoundation` creates
the native asset and uses ShaderImporter.SetNonModifiableTextures for each shader,
paired with the NonModifiableTextureData property flag. The ordinary default-texture
list must not contain a duplicate entry, even a null one: it overrides this binding.
Ordinary SetDefaultTextures alone only passed the Editor check, not the packaged
shader reassignment check. Both fresh materials and assignment from Standard are
tested by rendering the packaged shaders against the source-asset shaders.

The hidden resource is not exposed in ME or editable in the default Inspector.
This is not a security boundary: scripts can still override it, including with
null. A missing/incompatible marker displays magenta in Base and zero in Add
rather than silently losing compensation. Restore the actual resource reference
after an explicit override; setting null does not restore it. The texture asset
and Unity-generated shader importer metadata must be included when sharing this
Unity project. No runtime resource plugin is required for this foundation.

## Validation and assets

Run the offline test with Python/NumPy:

```powershell
python Assets/Mods/TomShadersBSDF/Tests/foundation_math.py --output CodexBridge/Reports/BSDF-Foundation/Data
```

Explicit Bridge operations: `inspectbsdffoundation`, `preparebsdffoundation`,
`renderbsdffoundation`, `buildbsdffoundation`. Reports and fixed-display PNGs are
written under `CodexBridge/Reports/BSDF-Foundation`, outside Assets. GPU work uses
an isolated temporary scene and AsyncGPUReadback; no floating-point ReadPixels
or automatic startup tests. Claimed `.running` commands never restart after a crash.

Editor-created carriers are `m_BSDF`/`a_BSDF` and `m_BSDFCutout`/`a_BSDFCutout`.
Their bundle is `chara/tom/shaders/tombsdf.unity3d`. Build smoke output is a test
bundle outside the game installation. Live KKS/ME acceptance is separate from
these Editor fixtures and must not be inferred from them.
