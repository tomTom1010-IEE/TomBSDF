# TomBSDF User Manual

For **0.2.0 RC1**, KKS, Unity 2019.4.9f1 runtime, Built-in Forward / D3D11. Companion **0.6.0 + matching Runtime** is optional for core shading. Property names follow ME without a leading underscore.

The maintainer reported KKS / ME acceptance passed on 2026-10-25. Showcase illustrations are separate Editor renders, not player frame-time measurements.

## Installation

**[Download the complete KKS release](https://github.com/tomTom1010-IEE/TomBSDF/releases/tag/v0.2.0-rc1)**.
The Complete zip contains both zipmods and matching optional providers; copy its
`mods` and `BepInEx` directories into the game root. The standalone zipmod is
also available for existing matched installations. Do not use GitHub's automatic
source-code archives as a game installer.

### Supported Host

TomBSDF 0.2.0 RC1 targets **KKS / Unity 2019.4.9f1 runtime / Built-in Forward /
D3D11**. The player is Linear; the authoring template may remain Gamma.
KKSLinear-v1 handles that boundary without a color-grading cube or the companion.
Do not change the game's color space. KK / Unity 5.6 is not supported by this release.

Keep a working BepInEx, KKS API, Sideloader, Extended Save and MaterialEditor
installation. ME tooltip-catalog support is optional, not a rendering dependency.

### Game Files

Close Studio / KKS before replacing DLLs. Back up previous BSDF files outside
the `mods` and `BepInEx/plugins` trees. Keep only one mod GUID
`tom.Shaders.BSDF` and one copy of each runtime assembly.
Paths below are relative to the game root, for example `D:/Program Files/KoikatuSunshine`.

| File | Install location | Required for |
| --- | --- | --- |
| `TomBSDF-KKS-0.2.0-RC1.zipmod` | `mods/` | Shaders, carriers, LUTs, tooltip catalog and rectangle item lists |
| `KKS_TomBSDF.dll` 0.6.0 | `BepInEx/plugins/TomBSDF/` | Optional scene companion |
| Matching `TomBSDF.Runtime.dll` | `BepInEx/plugins/TomBSDF/` | Matching scene services and resource types |

Install both DLLs together. A source build produces the pair in
`Tools/TomBSDFRuntime/KKS_TomBSDF/bin/Release`. Do not copy game, UnityEngine
or BepInEx reference DLLs. Windows FileVersion is not the feature version;
check startup plugin version and release hashes.

The published zipmod is byte-identical to the accepted authoring output named
`[tomTom][KKS] Tom Shaders BSDF v0.2.0.zipmod`. Its filename does not change
the internal mod GUID or version. Keep only one of these same-GUID copies.

Do not unpack zipmods over game `abdata` or install LUT / prefab / material /
`.meta` files separately. A repository clone is source, not an installable
zipmod; see [Build Guide](https://github.com/tomTom1010-IEE/TomBSDF/blob/main/Assets/Mods/TomShadersBSDF/Documents/Build-Guide.md).

### Configuration

The plugin creates `BepInEx/config/com.tomtom1010.tombsdf.scene.cfg`:

```ini
[Scene Lighting]
Enabled = true

[Scene Buffers]
Enabled = true

[Area Light Quality]
Screenshot Reference = true

[Alpha Shadows]
Receive Native Shadows = true
Copy Memory Budget MB = 128

[Validation]
File Bridge = false
```

The master switch disables rectangles, screen buffers and additional transparent
native-shadow reuse. It leaves native lights, Probe / SH, physical shading and
the separate tessellation bounds service available. The shadow budget is a
per-camera limit, not reserved memory. Keep File Bridge off during normal use;
there are no automatic startup rendering tests.

The companion can load in Studio and the KKS game process. The reported RC1
acceptance does not assert individual coverage of every Maker, gameplay or
third-party exporter combination.

### Optional Probe And Capture Tools

Tom Lighting Probes **0.2.1** uses its own zipmod in `mods/` and both
`KKS_TomProbe.dll` / `TomProbe.Runtime.dll` in `BepInEx/plugins/TomProbe/`.
Items appear under **Tom Lighting / Probes**. It is an independent Studio-only
tool; installing the full TomShadersX pack is unnecessary. Native environment
lighting remains available without it. Reflection capture requires the game's
Realtime Reflection Probes quality setting and a completed capture.

Existing Screenshot Manager / Screencap integration is optional. A compatible
lifecycle API and matching camera target allow temporary rectangle Reference
quality. Unsupported APIs keep material-selected quality. Thin-film, POM and
tessellation do not automatically promote. No replacement capture plugin is bundled.

### First Launch

1. Check `BepInEx/LogOutput.log` for Companion 0.6.0 and missing / duplicate assembly errors.
2. Select all seven modern `tom/BSDF*` entries on independent test materials.
3. For area lighting, add **Tom BSDF / Lighting / Tom Rectangle Area Light Prototype**. It is intentionally invisible and emits along local +Z.
4. Complete [Manual Acceptance](https://github.com/tomTom1010-IEE/TomBSDF/blob/main/Assets/Mods/TomShadersBSDF/Documents/KKS-ME-Acceptance.md), including scene save / reload / import.

The three legacy `xukmi/TomBSDF*` entries remain for existing scenes. A modern
shader switch is not a semantic migration: duplicate the old material first
and explicitly initialize new coverage / optical inputs.


## Material Guide

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

### Textures And Color

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
Choose RGB for known ordinary blue-purple maps, AG for known A/G packed data.
A red-looking preview alone does not establish packing. FlipY changes tangent
convention, not light direction. Base, detail and coat have independent encoding.

### Layers And Units

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

### Coverage Versus Glass

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

### Height, POM And Tess

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

### Glints, AA And Environment

Glints redistribute substrate direct single scattering, not emission. Use a
fixed seed. Zero weight / black mask restores smooth GGX; density / footprint
growth approaches its mean. Probe, SH and rectangles remain smooth. The four
Opaque / Cutout / Tess entries support it; Alpha / BackFront / Glass do not.

Native Probe and SH require real scene data. ReflectionIntensity does not create
a probe; AO and IndirectDiffuseIntensity do not create indirect light. Specular
AA reduces unresolved normal-lobe aliasing without randomizing Glints per frame.


## Release Profiles, Dependencies And Cost

Release: **0.2.0 RC1**, KKS / Unity 2019.4.9f1 runtime / Built-in / D3D11.
Use [Release Status](https://github.com/tomTom1010-IEE/TomBSDF/blob/main/Assets/Mods/TomShadersBSDF/Documents/Release-Status.md), not historical reports, for release gates.

### Starting Materials

[Release-Presets.json](https://github.com/tomTom1010-IEE/TomBSDF/blob/main/Assets/Mods/TomShadersBSDF/Documents/Release-Presets.json) is the numerical source. Twelve
independent Unity materials in `Material/Presets` provide six families and two
profiles. They do not replace shader defaults / carriers / scenes and are
**not ME one-click presets**. Colors below are linear RGB; the authoring presets
use ColorValueMode=2, not ordinary sRGB color-picker numbers.

| Family | Base color (linear RGB) | Metallic / roughness | Key settings |
| --- | --- | --- | --- |
| Plastic | 0.04, 0.22, 0.36 | 0 / 0.32 | IOR 1.5, DiffuseRoughness 0.15 |
| Metal | 0.90, 0.55, 0.28 | 1 / 0.24 | Copper-like RGB F0 fit, not measured optical constants |
| BrushedMetal | 0.65, 0.68, 0.72 | 1 / 0.32 | Anisotropy 0.8, rotation 0 degrees |
| CarPaint | 0.32, 0.015, 0.008 | 0 / 0.30 | Coat 1, IOR 1.5, roughness 0.12, thickness 0.05 mm |
| ThinFilm | About 0.1255 each channel | 0 / 0.25 | Coat 1, film weight 1, IOR 2.2, thickness 420 nm |
| Glass | 1, 1, 1 | Dielectric / 0.08 | IOR 1.5, thickness 0.006 m, absorption (0.35,0.8,0.6) at 0.05 m |

POM, local self-shadow, Glints and displacement are off initially. These starting
materials do not invent textures, scratches or independent measured flake layers.

### Explicit Quality Profiles

| Choice | Realtime | Screenshot copy / opt-in |
| --- | --- | --- |
| AreaLightQuality | 0 Realtime | 1 Reference |
| ThinFilmQuality | 0 Realtime | Still 0; Reference=1 is separate |
| ParallaxQuality | 0 when enabled | 1 when enabled |
| POM local self-shadow | Off initially | Off initially; follows POM quality |
| GlassBufferResolution | 2 Half | 1 Full |
| Tess recommendation, not preset values | Edge 0.05 m, maximum 8 | Edge 0.025 m, maximum 16 |

These are manual material choices, not automatic global quality. Supported
capture integration temporarily promotes **rectangle integration only**, then
restores its owned keywords without overwriting saved ME floats. Film / POM /
Tess do not promote based on resolution or scene names. Missing capture API
means material-selected quality, not an error.

### Dependency / Fallback Matrix

Use Companion **0.6.0 + matching Runtime** for the complete extension set.

| Feature | Dependency | Disabled / missing behavior |
| --- | --- | --- |
| Core color, GGX, anisotropy, coat, film, normals / AA | Shader-owned matching LUTs | No Companion / V+ / X dependency. Missing core energy data is an error |
| Native lights / opaque shadows | Unity lights, maps, quality | No generated map means no corresponding shadow |
| Probe / SH / AO | Actual Unity environment | No data means no corresponding indirect light; AO cannot create it |
| Tom Probe / SH | Independent 0.2.1 tool / DLL pair, Studio only | Native environment remains usable |
| Rectangles | Companion, protocol resources, LTC and control items | Zero rectangle contribution; maximum four, unshadowed |
| Capture Reference | Supported lifecycle API and camera target | Keep material quality; no film / POM / Tess changes |
| Transparent native shadows | Companion, maps / matrices / cascades, budget | Previous transparent path; no extra map generation or coverage changes |
| Screen refraction | Companion, same-camera opaque color / depth | Unshifted RGB transmission, absorption and reflection |
| POM / local self-shadow / Glints | Supported material data | Neutral when off / zero; no plugin required |
| Tess bounds | Companion bounds service or manual bounds | Geometry works but unmanaged bounds may cull incorrectly |
| Tooltips | Compatible ME catalog support | Help text absent, shading unaffected |

Scene Lighting master Off does not disable the bounds service; removing the
service does. Precombined static batches need manual handling.

### Expensive Combinations

| Combination | Cost | Advice |
| --- | --- | --- |
| Many native lights | Repeated Base / Add and caster work | Do not use lights to replace missing GI |
| Coat + anisotropy + film | Directional / optical layer evaluation | Enable per material; start with Realtime film |
| Layered film + rectangle Reference | Full layered numerical integration | Deliberate small-area captures / comparisons |
| POM + local shadow + many lights | View trace plus per-light height visibility | Avoid full-screen grazing Reference by default |
| Glints + coat / film | Footprint counts and layer work | Measure target scenes; not a global default |
| High Tess factors | Roughly factor-squared geometry times light / depth work | Start at 8; 32-63 on dense skinned meshes can be dangerous |
| AlphaBackFront | Extra draws / overdraw | Only for needed shell ordering |
| Full-resolution layered glass | Buffer copies / filtering / transparency | Start at Half; monitor capture memory |
| Continuous Probe / SH capture | Multiple camera faces and scheduling | Prefer manual / static refresh |

Historical Camera.Render-plus-readback timings are not GPU-only time or KKS FPS
predictions. Report resolution, visible area, lights, postprocess and measurement
method. No universal frame-rate guarantee is made.


## KKS / MaterialEditor Acceptance

The maintainer reported this release's manual game acceptance passed on
2026-10-25. This is also the repeatable checklist for future builds, not an
automatic test or a claim that the publishing agent operated the game.

Use a separate saved scene, fixed camera / exposure / postprocess, a UV sphere,
plane, floor, opaque checker background and blocker. Install the matching files
from [Installation](https://github.com/tomTom1010-IEE/TomBSDF/blob/main/Assets/Mods/TomShadersBSDF/Documents/Installation.md); back up previous scenes / packages first.
Record Pass / Fail / Resource unavailable / Not tested separately.

### Loading And Materials

- [ ] Startup log shows Companion 0.6.0, without duplicate / missing assemblies.
- [ ] All seven modern entries can be selected on independent materials; no magenta / missing passes.
- [ ] Empty maps allow BaseColor / Metallic / Roughness scalar authoring; texture maps and ORM channels work.
- [ ] Known RGB / AG normals decode with the selected encoding; detail normal strength zero / nonzero behaves independently.
- [ ] Plastic, metal, brushed metal, coat paint, thin film and Glass work in [the profile table](https://github.com/tomTom1010-IEE/TomBSDF/blob/main/Assets/Mods/TomShadersBSDF/Documents/HardSurface-Release.md).
- [ ] Anisotropy rotation changes lobe direction; zero restores isotropy; mirrored UVs stay finite.
- [ ] Coat normal / absorption operate independently. CoatWeight=0 ignores coat and film controls.
- [ ] Film thickness changes interference; Realtime / Reference remain plausible without requiring pixel equality.
- [ ] Specular AA reduces unresolved normal sparkle during slow motion; no frame-random pattern is introduced.

### Native Lighting And Coverage

- [ ] Directional, point and spot lights respond to movement, direction / range and native shadow blockers.
- [ ] Mixed native lights do not repeatedly add Probe / emission; test vertex fallback if the host exposes light importance.
- [ ] Valid Probe / SH data controls environment response. AO affects indirect response, not all direct light / emission.
- [ ] Alpha and BackFront Coverage=1 / 0.5 / 0 fade smoothly with AlphaClip=0; zero leaves no reflection film.
- [ ] Soft AlphaMask and MainTex alpha multiply coverage; BaseColor alpha is not the opacity control.
- [ ] AlphaClip / Cutoff and separate casting Off / Cutout / Dither modes work.
- [ ] Depth Off / NearestSurface / BackShell switch and save correctly; record their intentional layer-visibility tradeoffs.
- [ ] On both Alpha entries, compare transparent native shadow receiving On / Off for directional, spot and point.

For receiving, the same light must first shadow an opaque positive control.
Unavailable native maps are a resource limitation, not proof of a passed shadow
feature. No queue spoofing, forced ZWrite or extra shadow generation is expected.
Coverage, emission, Probe and SH must not be multiplied by the direct-light shadow.

### Height And Glints

- [ ] POM: supported BSDF / Cutout, ParallaxMode=1, HeightScale=0.01; grazing view shows relief without real silhouette movement.
- [ ] POM Off / HeightScale=0 restores neutral shading. Cutout keeps original-UV holes and casting.
- [ ] POM local self-shadow follows each native light; coat / film direct terms participate without darkening emission / Probe / SH.
- [ ] Glints: Weight=1, Density=5.5, Contrast=0.6, Seed=17 under direct light; static view does not animate randomly.
- [ ] Glint Weight=0 / black mask restores smooth reflection; denser / smaller-footprint behavior is plausible. Probe / area remain smooth.
- [ ] Tess: HeightScale=0.01, Fixed factor8, then WorldEdge 0.05 m / maximum8; silhouette / caster follow inward displacement.
- [ ] White envelope / inward black / height reverse / displacement mask work. Zero height restores original geometry and factor1.
- [ ] Check movement, negative scale, skinned motion, seams and view-edge culling. POM is not present on the same Tess height layer.

### Companion And Capture

- [ ] Rectangle control under Tom BSDF / Lighting emits along local +Z, responds to transform / ME and disappears when hidden / disabled.
- [ ] Realtime / Reference area quality works; at most four emitters are selected. No rectangle shadow is expected.
- [ ] Glass Coverage=1, IOR=1.5, thickness0.006 m retains reflection and optical transmission; absorption follows thickness.
- [ ] Refraction On / Off differs with an angled surface / opaque checker background; roughness gives bounded blur.
- [ ] Screen edges, foreground occlusion and camera switches do not smear / leak old camera content.
- [ ] Scene Buffers Off / missing companion retains unshifted RGB transmission and reflection, not magenta or disappearance.
- [ ] Half / Full buffers work; repeated scene / camera / visibility changes do not cause ongoing memory growth.
- [ ] Supported Screenshot Manager promotes area integration only and restores live state after normal / repeated / cancelled captures.
- [ ] Saved ME area quality stays unchanged; film / POM / Tess do not auto-promote. API absence retains ordinary selected quality.
- [ ] Optional Tom Probe / SH 0.2.1 refresh, bounds and native fallback work if installed; otherwise record not tested.

### Persistence, Fallback And Performance

- [ ] On all seven entries, edit float / color / texture / tiling / offset, duplicate material and switch shaders on copies.
- [ ] Save scene, exit, restart, reload and import into another scene; shader, maps, enum / seed / geometry settings and appearance persist.
- [ ] Legacy xukmi identities still load existing materials and are not automatically migrated.
- [ ] Master Scene Lighting Off preserves core / native / environment shading; scene extensions fall back. Bounds service remains independent.
- [ ] After closing the game, temporarily move both companion DLLs outside plugins; core works with documented fallbacks. Restore the pair and restart.
- [ ] Measure fixed-view warmed frame times for isolated costly features; record resolution / lights / postprocess, not just FPS.

Primary scope is Studio. Maker / gameplay and third-party export combinations
need their own host checks if advertised. Optional Tom Probe is Studio-only.

### Reporting And Stop Criteria

Record test ID / entry, parameters, expected versus actual result, screenshot
and log timestamp. Preserve the relevant `BepInEx/LogOutput.log` before restart
overwrites it. Missing entries / LUTs, crashes, lost saved data, non-neutral zero
controls or persistent leaks block a release. Missing optional maps / capture API
must not be falsely called a passed extension test.

SSR, exact BTDF, nested media, caustics, colored shadows, BSSRDF, area shadows,
arbitrary transparency ordering and KK support are not RC1 acceptance promises.


## Troubleshooting

### Missing Shader Or Magenta Material

Install the zipmod once and confirm Sideloader / ME loaded it. Select the intended
modern `tom/` entry. Missing shader-owned energy LUTs are a real error, not an
optional-plugin fallback. For source, pull LFS and keep native assets / metadata;
never substitute user maps or regenerate GUIDs to hide broken resource bindings.

### Companion Missing Or Wrong Version

Install Companion 0.6.0 and its matching Runtime together. Back up older duplicates
outside every plugin folder. Check `BepInEx/LogOutput.log`; Windows FileVersion
is not the feature version. Core colors / physical shading, POM and Glints work
without the plugin; rectangle / refraction / transparent-map services do not.
Missing CPU bounds management can still cause Tess culling.

### Unexpected Color Or Normals

Do not change game color space or use the old Linear-build project. Keep input
Auto unless actual encoding is known. Data restoration corrects a specific sRGB
sampling mismatch, not overall quality. Normal encoding is 0 UnityPacked,
1 RGB, 2 AG, separately for main / detail / coat. A red preview alone does not
establish packing. DetailNormalMapScale defaults to zero.

### Dark Metal Or Ineffective AO

Probe / SH controls need actual environment data; sliders do not create GI.
AO attenuates indirect light and Probe reflection, not all direct lights or
emission. A dark metal without useful light / reflection is expected. Optional
Probe capture also needs valid bounds, completed jobs and enabled runtime quality.

### Missing Point Or Transparent Shadows

First verify the same native light shadows an opaque control. Four-array lights
have no independent shadow maps. Transparent reuse additionally needs companion,
native maps / matrices and budget. It does not generate missing maps, promote
lights, change Queue or force ZWrite. Casting and receiving are separate controls.
Rectangles are unshadowed; Glass has no ShadowCaster.

### Glass Does Not Refract A Particular Object

Use BSDFGlass, keep intact Coverage=1, enable UseSceneRefraction and Scene Buffers,
and test a visible opaque background. Straight-on parallel plates can have little
offset. Invalid / occluded / offscreen samples retain unshifted transmission;
screen edges must not smear. Other transparent layers, hidden geometry, nested
media and offscreen objects are outside the opaque snapshot. This is not an
exact rough BTDF / caustic / colored-shadow renderer.

### Alpha Sorting Or Unexpected Transparency

Coverage is MainTex A * AlphaMask R * Coverage, not BaseColor A. AlphaClip=0
permits gradients. Back/Front and optional depth strategies trade specific layer
visibility; they are not OIT. Glass transmission is not ordinary opacity fading.
Check exposure / bloom / sharpening with a neutral test before diagnosing fringes.

### Height Has No Silhouette Or Shows Cracks

POM changes shading UV only. Tess changes real geometry. Height is white-envelope /
inward-black in meters; zero scale bypasses it. White height or black displacement
mask preserves position. Use suitable subdivision / mip and continuous seam data.
More tessellation cannot reconcile inconsistent UV heights / vertex normals.
Bounds require a service or authoring; picking, collision and old DepthNormals
replacement are not automatically displaced.

### Slow Captures Or Reference Sticks

Only a supported capture lifecycle / matching camera promotes rectangle quality.
Temporary keywords must restore and ME floats must stay unchanged. Manually
selected Reference stays expensive in live view. Film + multiple lights + area
Reference and full-resolution layered glass are costly. Keep diagnostic File
Bridge off. High-resolution memory peaks and continuous leaks are different issues.

### Shader Compiler Internal Error

RC1 has complete audited programs, not a proven fix for every Unity FXC cold
build failure. Preserve logs / successful cache and follow
[Delivery Workflow](https://github.com/tomTom1010-IEE/TomBSDF/blob/main/Assets/Mods/TomShadersBSDF/Documents/Delivery-Build-Workflow.md). Do not repeatedly clear cache,
strip variants, reduce sampling or splice bytecode. Known duplicate AssetBundle
Browser package GUID diagnostics are template issues, not a waiver for new
shader errors. A stalled worker alone does not establish hardware causation.

### Bug Reports

Include shader and package / companion versions, KKS host / graphics API,
relevant plugins, exact parameters / texture encodings, reproduction steps,
expected / actual images and whether restart / save / reload / import changes it.
For performance, include resolution, visible area, lights, postprocessing and
measurement method. Attach the relevant log interval, not the entire game or
Library. Remove tokens, personal paths and private user content before sharing.


## Rebuilding The Source Overlay

This repository overlays a compatible **KKS Unity 2019.4 modding template**.
It does not redistribute the game, Unity Editor, BepInEx SDK or the template's
ItemComponent. RC1 targets the original 2019.4.9f1 runtime / Built-in / D3D11.

### Checkout And Import

1. Install Git LFS, clone the repository and run `git lfs pull`.
2. Confirm the two large ResourcesData LUTs are full native assets, not small files beginning with `version https://git-lfs.github.com/spec/v1`.
3. Import `Assets/Mods/TomShadersBSDF` into the host template with its `.meta` files, native resources, materials, prefabs and Runtime DLL intact.
4. Preserve Gamma authoring settings. KKSLinear-v1 adapts input / output for the Linear KKS host; do not switch to an obsolete separate Linear build.
5. In Unity run **Tools / TomBSDF / Validate Source Overlay**. Resolve missing scripts / shader-owned LUTs before building. This command does not render or build automatically.

Edit native Unity assets only through the Editor / Unity APIs. The supplied
serialized assets are not templates to rewrite using string substitution.
Preserve GUIDs and non-modifiable shader texture bindings, not only filenames.

### Companion

Build with a .NET SDK, .NET Framework 4.6.2 targeting support and the game SDK:

```powershell
dotnet build Tools/TomBSDFRuntime/KKS_TomBSDF/KKS_TomBSDF.csproj -c Release -p:GameRoot="D:/Your/KKS"
```

The project resolves BepInEx and Unity assemblies from GameRoot. Its output
contains the plugin and matching runtime. Do not redistribute SDK reference DLLs.
The authoring copy at `Assets/Mods/TomShadersBSDF/Runtime/TomBSDF.Runtime.dll`
must match the player copy. If rebuilt runtime bytes change, update the authoring
DLL through Unity, validate serialized resources and rebuild dependent bundles.

### Native Build And Audit

Run **Tools / TomBSDF / Build Native Bundle** explicitly. It builds the assigned
BSDF bundle and records BSDF-owned submitted variants, including rectangle
Off / Realtime / Reference retention. It does not run developer GPU test suites
or build automatically on startup.

Outputs include:

```text
Build/abdata/chara/tom/shaders/tombsdf.unity3d
Build/TomBSDF-native-variants.jsonl
```

With Python 3.11+:

```powershell
python -m pip install -r Tools/BSDFBuildAudit/requirements.txt
python Tools/BSDFBuildAudit/audit.py Build/abdata/chara/tom/shaders/tombsdf.unity3d --submitted Build/TomBSDF-native-variants.jsonl --output Build/TomBSDF-native-audit.json
```

Require valid actual DXBC and matching stage / tier / keyword identities, not
just a written bundle or a familiar count. Tess includes VS / HS / DS / PS.
RC1 has 1642 modern and 1790 total programs; these are **this candidate's
baseline**, not fixed future limits. Unity-owned Standard programs are separately
accounted for, not falsely called BSDF-owned submission matches.

Use the host's KKS postprocess / normal zipmod packer, retaining mod metadata,
ME entries, tooltip catalog, Bundle and Studio item lists. Do not ship a newer
manifest with an older cached bundle. Audit the final archive:

```powershell
python Tools/BSDFBuildAudit/audit.py Build/abdata/chara/tom/shaders/tombsdf.unity3d --submitted Build/TomBSDF-native-variants.jsonl --output Build/TomBSDF-zip-audit.json --zipmod "Build/abdata/[tomTom][KKS] Tom Shaders BSDF v0.2.0.zipmod" --manifest Assets/Mods/TomShadersBSDF/manifest.xml
```

Then load and render the **packaged** materials in the Editor, verify shader-owned
LUT payloads / bindings, and perform the manual KKS / ME save / import checks.
An Editor source material rendering correctly is not packaged-runtime acceptance.

### Incremental Compilation Policy

Freeze source, native dependencies, toolchain, settings and submissions before
the first build. Preserve the same project's successful cache. After an initial
failure allow at most three explicit repair attempts, with strict progress and
bytecode-preservation checks. Stop on no progress or changed provenance.
One clean complete confirmation may reuse cache. Never splice binaries, reduce
samples or strip effective variants to fill the inventory.

See [Delivery Workflow](https://github.com/tomTom1010-IEE/TomBSDF/blob/main/Assets/Mods/TomShadersBSDF/Documents/Delivery-Build-Workflow.md). A clean cold build is not
guaranteed by RC1, and the old FXC failure is not declared root-fixed. No cache
clearing, alternate compiler replacement, unattended rebuild loop or game
deployment is part of source setup.

### Repository Contents

Tracked: production shader / runtime source, manifest / tooltips, active legacy
compatibility paths, build / audit helpers, native carriers / resources / LUTs,
authoring Runtime DLL, licenses and matching metadata. Large required LUTs use LFS.

Excluded: Library / Temp / caches, `bin` / `obj`, game reference assemblies,
zipmod / Bundle / unitypackage outputs, test fixtures / images / raw reports,
duplicate `Shaders 1` / `Shaders 2`, obsolete Linear-build experiments and local
Chinese planning notes. Do not add blanket `*.dll`, `*.asset`, `*.mat`,
`*.prefab`, `*.meta` or `*.csproj` ignores: they would break rebuildability.

`SOURCE-INVENTORY.json` lists verbatim Unity-exported files and hashes. Publication
documents and root tooling are reviewed separately from the frozen render payload.
Developer Bridge tests cited by historical summaries are intentionally not shipped.


## TomBSDF 0.2.0 RC1 Status

The accepted artifact is distributed as the
[complete KKS RC1 pre-release](https://github.com/tomTom1010-IEE/TomBSDF/releases/tag/v0.2.0-rc1)
on 2026-10-26. Packaging does not recompile or alter the accepted shader payload.

Updated 2026-10-25. **Packaged Editor acceptance passed. The maintainer reported
KKS / ME manual acceptance passed.** The game was operated by the maintainer,
not by the publishing agent. No new player frame-time measurements or individual
per-case game captures were supplied with that confirmation.

### Audited Artifact

| Check | Result |
| --- | --- |
| Modern entries | Seven, including BSDFTess and BSDFCutoutTess |
| Owned submissions | 13 BSDF-owned shaders, 88 snippets, 1704 required identities |
| Modern native programs | 1642 |
| Total delivered programs | 1790 valid DXBC; the other 86 are unchanged Unity-owned Standard programs |
| Bytecode preservation | All 1790 previously successful program hashes unchanged |
| Final native build | Warm, cache-preserving confirmation; no new shader errors |
| Template diagnostics | 24 existing duplicate immutable AssetBundle Browser GUID errors classified separately |
| Actual zipmod material regression | 330 checks, 95 PNGs, 44 source / package RGBA pairs with zero maximum error |
| LUTs | Four matching payloads; 27 modern shader LUT pointers resolve inside the Bundle |
| Active companion / ME game acceptance | Maintainer-reported checklist passed after Editor acceptance |

Editor renders used native lighting / Probe with extensions disabled. They did
not by themselves prove active game refraction / rectangle / shadow services.
The later manual game acceptance is separate evidence; do not relabel Editor
timings as player GPU measurements.

### Identity

Package GUID: `tom.Shaders.BSDF`; manifest version: `0.2.0`; RC1 is a candidate
label. Matching companion feature version: `0.6.0`.

```text
Current [tomTom][KKS] Tom Shaders BSDF v0.2.0.zipmod
SHA256 c62af78d9151f0b701128a7896065d2cc10dfc631392e9b0dadee6d07bff7153

Embedded chara/tom/shaders/tombsdf.unity3d
SHA256 0904d5aa53b43639d02660c040ae8a08d1774c38af965ceefe0335c22890c200

KKS_TomBSDF.dll
SHA256 5be347eaa8076b4d150e7bde3cd772dc88951f114721e74ebe6d5f3dbecd287f

TomBSDF.Runtime.dll
SHA256 a61ea084865949843beb8ab17d8b2fecf6f7c1cbd93d8e0adda7554236490667
```

The retained earlier `[xukmi&tomTom]` RC1 archive has a different zip hash
(`5cc3b3439af986fcf7c94674b365273e30945048299a6f3532b68e84e31d13b9`).
The current package has identical Bundle / Studio lists and XML-equivalent
manifest except the author field. Neither archive is silently renamed as the other.
Support-document updates do not change the already accepted render payload.

### Provenance And Validation Fixture

Developer evidence is retained outside Git under
`CodexBridge/Reports/BSDF-Release/RC1/FinalAcceptance-20261025-1822`.
The native producer is `Candidate-20261025-102910-022`, with
`Cache-Bundle-20261025-183051-678` submissions. The accepted Editor snapshot is
`BSDF-BuildAudit/Baseline-20261025-105447-409`.

A validation-only amendment replaced an incorrect direct-addressability LUT
check with packaged shader binding / metadata / payload checks. The separate
validation snapshot retained identical production configuration. It did not
change shader behavior, trigger another build or reset the repair allowance.
Original failed diagnostics remain archived, not rewritten as successes.

### Still Not Claimed

Cold reproducibility / the historic FXC crash root cause remain open. Controlled
incremental delivery with exact program / archive auditing is the current policy.
No compiler replacement, sample reduction, effective-variant removal or bytecode
splicing is a release solution. Counts describe RC1, not a fixed future target.

No KK port, exact OpenPBR / spectral transport, full GGX BTDF, SSR, BSSRDF, caustics,
nested media, colored shadows, automatic missing shadow maps or OIT is claimed.
Read [profiles and costs](https://github.com/tomTom1010-IEE/TomBSDF/blob/main/Assets/Mods/TomShadersBSDF/Documents/HardSurface-Release.md) before enabling costly combinations.
