# Architecture And Scope

An independent KKS Built-in Forward source overlay; no modern V+ / TomShadersX
include dependency, old toon ramp / MatCap / liquid or reverse-shadow branches.
The actively referenced legacy entries keep their separate local compatibility code.

| Module | Responsibility |
| --- | --- |
| `Shaders/Core` | Material / light data, GGX / Smith, diffuse, metal optics, energy, film / layers, POM and Glints mathematics |
| `Shaders/Material` | Input contracts, maps / frames, layers, coverage and material preparation |
| `Shaders/Lighting` | Native-light evaluation, Probe / occlusion and rectangles |
| `Shaders/Platform/Unity2019` | KKS color, Unity lights / Probe, native-map reuse, scene buffers and tessellation |
| `Shaders/Passes` | Base / Add / caster, Alpha policies, Glass composition and Tess wrappers |
| `Runtime` / `ResourcesData` | Matching native resources, authoring DLL and shader-owned LUTs |
| `Tools/TomBSDFRuntime` | Optional discovery, camera scopes, captures, buffer / shadow copies and bounds |
| `manifest.xml` / `Tooltips` | ME controls and descriptions |
| `Material` / `Prefab` | Required native authoring assets with original GUIDs |

Physical evaluation is separate from resource acquisition. Shadow visibility
attenuates the associated direct light, not coverage / emission / SH / Probe.
Coverage represents surface presence; Glass uses separate RGB transmission.
POM shading UV and actual Tess geometry share height decoding but are mutually
exclusive for one layer. KKSLinear-v1 keeps BRDF math linear in Gamma authoring.
Core LUTs are serialized shader-owned dependencies, not ordinary ME user maps.

Rectangle Off / Realtime / Reference programs are retained. Camera-scoped owned
keywords follow saved ME floats and restore after nested cameras / captures.
The companion does not replace host rendering, color grading or generate missing
native shadow maps. Optional services have neutral fallbacks; missing mandatory
energy data is an error.

Implemented stages: physical foundation, environment / anisotropy, coat / film,
scene integration / coverage / finite glass, POM / local shadow, Glints and Tess.
RC1 is a hard-surface checkpoint, not full OpenPBR feature parity.

Deferred: KK adaptation, SSR, full GGX BTDF / nested media, BSSRDF / fuzz, caustics,
colored shadows, extra shadow maps, area self-shadow, Alpha / Glass POM / Glints /
Tess and screen-space Tess LOD. Probe anisotropy uses an isotropic prefilter
approximately; RGB film / conductor and rough-layer transport are not exact
spectral / refractive transport. See [Release Status](Release-Status.md).
