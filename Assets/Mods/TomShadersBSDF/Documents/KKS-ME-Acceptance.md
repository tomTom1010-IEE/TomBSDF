# KKS / MaterialEditor Acceptance

The maintainer reported this release's manual game acceptance passed on
2026-10-25. This is also the repeatable checklist for future builds, not an
automatic test or a claim that the publishing agent operated the game.

Use a separate saved scene, fixed camera / exposure / postprocess, a UV sphere,
plane, floor, opaque checker background and blocker. Install the matching files
from [Installation](Installation.md); back up previous scenes / packages first.
Record Pass / Fail / Resource unavailable / Not tested separately.

## Loading And Materials

- [ ] Startup log shows Companion 0.6.0, without duplicate / missing assemblies.
- [ ] All seven modern entries can be selected on independent materials; no magenta / missing passes.
- [ ] Empty maps allow BaseColor / Metallic / Roughness scalar authoring; texture maps and ORM channels work.
- [ ] Known RGB / AG normals decode with the selected encoding; detail normal strength zero / nonzero behaves independently.
- [ ] Plastic, metal, brushed metal, coat paint, thin film and Glass work in [the profile table](HardSurface-Release.md).
- [ ] Anisotropy rotation changes lobe direction; zero restores isotropy; mirrored UVs stay finite.
- [ ] Coat normal / absorption operate independently. CoatWeight=0 ignores coat and film controls.
- [ ] Film thickness changes interference; Realtime / Reference remain plausible without requiring pixel equality.
- [ ] Specular AA reduces unresolved normal sparkle during slow motion; no frame-random pattern is introduced.

## Native Lighting And Coverage

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

## Height And Glints

- [ ] POM: supported BSDF / Cutout, ParallaxMode=1, HeightScale=0.01; grazing view shows relief without real silhouette movement.
- [ ] POM Off / HeightScale=0 restores neutral shading. Cutout keeps original-UV holes and casting.
- [ ] POM local self-shadow follows each native light; coat / film direct terms participate without darkening emission / Probe / SH.
- [ ] Glints: Weight=1, Density=5.5, Contrast=0.6, Seed=17 under direct light; static view does not animate randomly.
- [ ] Glint Weight=0 / black mask restores smooth reflection; denser / smaller-footprint behavior is plausible. Probe / area remain smooth.
- [ ] Tess: HeightScale=0.01, Fixed factor8, then WorldEdge 0.05 m / maximum8; silhouette / caster follow inward displacement.
- [ ] White envelope / inward black / height reverse / displacement mask work. Zero height restores original geometry and factor1.
- [ ] Check movement, negative scale, skinned motion, seams and view-edge culling. POM is not present on the same Tess height layer.

## Companion And Capture

- [ ] Rectangle control under Tom BSDF / Lighting emits along local +Z, responds to transform / ME and disappears when hidden / disabled.
- [ ] Realtime / Reference area quality works; at most four emitters are selected. No rectangle shadow is expected.
- [ ] Glass Coverage=1, IOR=1.5, thickness0.006 m retains reflection and optical transmission; absorption follows thickness.
- [ ] Refraction On / Off differs with an angled surface / opaque checker background; roughness gives bounded blur.
- [ ] Screen edges, foreground occlusion and camera switches do not smear / leak old camera content.
- [ ] Scene Buffers Off / missing companion retains unshifted RGB transmission and reflection, not magenta or disappearance.
- [ ] Half / Full buffers work; repeated scene / camera / visibility changes do not cause ongoing memory growth.
- [ ] Supported Screenshot Manager promotes area integration only and restores live state after normal / repeated / cancelled captures.
- [ ] Saved ME area quality stays unchanged; film / POM / Tess do not auto-promote. API absence retains ordinary selected quality.
- [ ] Base-supplied Tom Probe / SH 0.2.2 refresh, bounds and native fallback work if installed; otherwise record not tested.

## Persistence, Fallback And Performance

- [ ] On all seven entries, edit float / color / texture / tiling / offset, duplicate material and switch shaders on copies.
- [ ] Save scene, exit, restart, reload and import into another scene; shader, maps, enum / seed / geometry settings and appearance persist.
- [ ] Legacy xukmi identities still load existing materials and are not automatically migrated.
- [ ] Master Scene Lighting Off preserves core / native / environment shading; scene extensions fall back. Bounds service remains independent.
- [ ] After closing the game, temporarily move both companion DLLs outside plugins; core works with documented fallbacks. Restore the pair and restart.
- [ ] Measure fixed-view warmed frame times for isolated costly features; record resolution / lights / postprocess, not just FPS.

Primary scope is Studio. Maker / gameplay and third-party export combinations
need their own host checks if advertised. Optional Tom Probe is Studio-only.

## Reporting And Stop Criteria

Record test ID / entry, parameters, expected versus actual result, screenshot
and log timestamp. Preserve the relevant `BepInEx/LogOutput.log` before restart
overwrites it. Missing entries / LUTs, crashes, lost saved data, non-neutral zero
controls or persistent leaks block a release. Missing optional maps / capture API
must not be falsely called a passed extension test.

SSR, exact BTDF, nested media, caustics, colored shadows, BSSRDF, area shadows,
arbitrary transparency ordering and KK support are not RC1 acceptance promises.
