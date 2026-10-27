# Material Guide

Names below are ME properties without the shader's leading `_`. Use exact
integer enum values. Each entry exposes only its supported controls.

| Need | Entry |
| --- | --- |
| Solid hard surface | `tom/BSDF` |
| Binary holes | `tom/BSDFCutout` |
| Soft coverage / fades | `tom/BSDFAlpha` |
| Back-then-front ordering for suitable shells | `tom/BSDFAlphaBackFront` |
| Optical transmission and optional refraction | `tom/BSDFGlass` |
| Subdivided real inward displacement | `tom/BSDFTess` / `tom/BSDFCutoutTess` |

Back/Front is not OIT. Glass is not Alpha with reduced opacity. Tess is not POM.

## Textures And Color

| Input | Meaning / neutral value |
| --- | --- |
| MainTex + BaseColor | Base color; white permits color-only authoring. Texture alpha is separate coverage where supported |
| MetallicMap + Metallic | Linear R times scalar; white preserves scalar |
| RoughnessMap + Roughness | Linear R times perceptual roughness; white preserves scalar |
| OcclusionMap + Occlusion / OcclusionStrength | Indirect attenuation; white is unoccluded, not a GI source |
| ORMMap + UseORM | Packed R=AO, G=roughness, B=metallic in place of separate maps |
| NormalMap / NormalMapDetail | Base / RNM detail tangent-space direction; neutral bump. Detail strength defaults to zero |
| EmissionMask + EmissionColor / EmissionIntensity | Emission color and gain; default map is black |
| AlphaMask + Coverage | Raw-UV R coverage on Cutout / Alpha / Glass |
| HeightMap | Linear R Height-v1 data, not a normal map |

Keep Input Contract modes on Auto unless the actual encoding is known.
DataTextureRestore and separate normal restoration switches correct a specific
sRGB sampling mismatch; they are not general quality boosts or artistic grading.

NormalEncoding / DetailNormalEncoding are **0 UnityPacked, 1 RGB, 2 AG**.
Choose by the actual sampled representation after import: RGB for unchanged RGB
vectors, AG for known A/G data, UnityPacked for Unity-packed resources. A blue
source PNG can be converted to packed data by ME's NormalMap/NormalMapDetail
import route, so its original color is not enough to select RGB. Independent
coat slots can use a different import path and need separate verification.
FlipY changes tangent convention, not light direction. Base, detail and coat
have independent encoding. See [input diagnostics](RenderDocs/MaterialContracts.md).

## Layers And Units

Anisotropy changes the GGX directional lobe; rotation follows the UV tangent
frame, including mirrored handedness. Zero strength restores isotropy. It does
not generate scratches. Coat has an independent normal, optional base-normal
inheritance, roughness, IOR, absorption and thickness. CoatWeight=0 returns the
accepted bare model and ignores layer controls. Film is below the coat;
CoatWeight=0 disables film too. ThinFilmQuality=0 is optimized Realtime and 1
is the retained expensive Reference path.

| Quantity | Unit |
| --- | --- |
| HeightScale, TessEdgeLength, GlassThickness / GlassAbsorptionDistance | World meters |
| CoatThickness / CoatAbsorptionDistance | Millimeters |
| ThinFilmThickness | Nanometers |
| AnisotropyRotation | Degrees |
| GlintDensity | Log10 expected microstructures per original UV area |

White high-F0 metal can legitimately show little film color. Layer / conductor
optics are calibrated real-time approximations, not exact spectral OpenPBR parity.

## Coverage Versus Glass

```text
coverage = saturate(MainTex.a * decoded(AlphaMask.r) * Coverage)
```

BaseColor.a is not coverage. Alpha premultiplies complete surface reflection,
emission and fog by coverage. Zero leaves no reflection film. AlphaClip=1
enables Cutoff. AlphaDepthMode is 0 Off, 1 NearestSurface, 2 BackShell; depth
policies deliberately change layer visibility. AlphaShadowMode is 0 Off, 1
Cutout, 2 Dither. Shadow casting is separate from receiving.

Keep Glass Coverage=1 for intact glass. IOR, world thickness and reference
absorption color describe transmission. MainTex RGB / BaseColor / absorption
color form its reference color. White is clear; thickness increases absorption.
GlassBufferResolution is 1 Full, 2 Half. Missing / rejected scene data retains
unshifted RGB transmission plus reflection. Only captured opaque / cutout content
can be screen-refracted, not arbitrary transparent or offscreen objects. Glass
has no ShadowCaster in this version.

## Height, POM And Tess

Height-v1 is linear R: **white is the original envelope, black is maximum inward
depth**. IsHeightReverse flips it. HeightScale uses world meters; start around
0.005-0.01, not the 0.2 maximum.

Opaque / Cutout use ParallaxMode=1 and Realtime / Reference quality. POM changes
shading UV, not geometry or raw coverage. ParallaxSelfShadow affects each native
direct light, including actual four-array fallback, not emission / SH / Probe /
rectangles. Off or zero height restores the neutral path.

Tess entries use Fixed / WorldEdge subdivision, independent DisplacementMask,
explicit mip and optional edge pinning. Forward / caster / Built-in camera
depth share displaced geometry. There is no same-layer POM. HeightScale=0
restores vertices / frames and factor 1, but the Tess entry still has HS / DS
overhead. UV / normal seams need continuous data or a mask. Bounds need the
companion or manual authoring; colliders, picking and old DepthNormals
replacement are not displaced automatically.

## Glints, AA And Environment

Glints redistribute substrate direct single scattering, not emission. Use a
fixed seed. Zero weight / black mask restores smooth GGX; density / footprint
growth approaches its mean. Probe, SH and rectangles remain smooth. The four
Opaque / Cutout / Tess entries support it; Alpha / BackFront / Glass do not.

Native Probe and SH require real scene data. ReflectionIntensity does not create
a probe; AO and IndirectDiffuseIntensity do not create indirect light. Specular
AA reduces unresolved normal-lobe aliasing without randomizing Glints per frame.
