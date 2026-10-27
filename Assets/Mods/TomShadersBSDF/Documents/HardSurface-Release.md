# Release Profiles, Dependencies And Cost

Release: **0.2.0 RC1**, KKS / Unity 2019.4.9f1 runtime / Built-in / D3D11.
Use [Release Status](Release-Status.md), not historical reports, for release gates.

## Starting Materials

[Release-Presets.json](Release-Presets.json) is the numerical source. Twelve
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

## Explicit Quality Profiles

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

## Dependency / Fallback Matrix

Use Companion **0.6.0 + matching Runtime** for the complete extension set.

| Feature | Dependency | Disabled / missing behavior |
| --- | --- | --- |
| Core color, GGX, anisotropy, coat, film, normals / AA | Shader-owned matching LUTs | No Companion / V+ / X dependency. Missing core energy data is an error |
| Native lights / opaque shadows | Unity lights, maps, quality | No generated map means no corresponding shadow |
| Probe / SH / AO | Actual Unity environment | No data means no corresponding indirect light; AO cannot create it |
| Tom Probe / SH | Base-supplied 0.2.2 resource / DLL pair, Studio only | Native environment remains usable |
| Rectangles | Companion, protocol resources, LTC and control items | Zero rectangle contribution; maximum four, unshadowed |
| Capture Reference | Supported lifecycle API and camera target | Keep material quality; no film / POM / Tess changes |
| Transparent native shadows | Companion, maps / matrices / cascades, budget | Previous transparent path; no extra map generation or coverage changes |
| Screen refraction | Companion, same-camera opaque color / depth | Unshifted RGB transmission, absorption and reflection |
| POM / local self-shadow / Glints | Supported material data | Neutral when off / zero; no plugin required |
| Tess bounds | Companion bounds service or manual bounds | Geometry works but unmanaged bounds may cull incorrectly |
| Tooltips | Compatible ME catalog support | Help text absent, shading unaffected |

Scene Lighting master Off does not disable the bounds service; removing the
service does. Precombined static batches need manual handling.

## Expensive Combinations

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
