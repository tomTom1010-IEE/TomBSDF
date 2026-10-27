# TomBSDF Rendering Pipeline

Modern TomBSDF separates material mathematics, host adapters and resource acquisition. This document
describes the implemented RC1 path, not full OpenPBR parity or the old development proposal.
See [Architecture](../Architecture.md) and [Release Status](../Release-Status.md).

## Source Ownership

Paths are relative to the shader package. Companion source/build ownership is
`src/BSDF` in [TomRenderInfrastructure](https://github.com/tomTom1010-IEE/TomRenderInfrastructure).
Install its KKS base before the Infra1 shader pack; helper DLLs are not embedded
in shader releases. The overlay retains only required authoring DLLs/metadata.

| Module | Owns |
| --- | --- |
| `Shaders/Core` | GGX/Smith, EON diffuse, anisotropy, metal optics, layer transport, thin film, POM, Glints mathematics |
| `Shaders/Material` | Map decode, UV/gradient frame, input data, layer parameters, coverage and prepared material |
| `Shaders/Lighting` | Complete per-light layered evaluation, Probe/occlusion, Glints and rectangular-light integration |
| `Shaders/Platform/Unity2019` | Native lighting/Probe interface, KKS color adapter, shadow reuse, scene buffers and Tess geometry |
| `Shaders/Passes` | Base/Add/caster, coverage policies, Glass composition and Tess wrappers |
| `Runtime`, `ResourcesData` | Authoring/runtime resource types, serialized shader-owned LUTs and service resources |
| `manifest.xml`, `Tooltips` | ME identities and visible contract |
| `Material`, `Prefab` | Native carrier bindings including nontrivial default resources |

Modern shaders do not call V+ or TomX include trees. Legacy `xukmi/TomBSDF*` remain active local
compatibility paths with separate KKP libraries. They are neither dead files nor complete aliases
for modern `tom/BSDF*` behavior.

## Light And Layer Composition

ForwardBase owns the main native light, native four-light fallback, indirect SH/Probe, emission
and optional service terms. ForwardAdd owns the selected additional pixel light. Per-light direction,
distance/cookie, actual native shadow visibility and geometric guards stay associated with that lamp.
Do not multiply final material RGB, coverage, emission or indirect terms by one lamp's shadow.

The substrate uses compensated GGX/Smith and diffuse with optional anisotropy and AA. Glints modify
the substrate's direct single-scattering distribution, not emission or all lighting terms. The
coat has independent normals, roughness, IOR and absorption; layer transport attenuates/refracts the
substrate approximation. Film is tied to the coat system. Weight zero returns the accepted bare
model, not the earlier known energy-loss baseline.

SH is indirect diffuse. Probe IBL supplies environment reflection using native captures and the
documented anisotropic approximation. AO/specular occlusion modulate existing environment terms.
Mandatory energy/film data is serialized with the shader; a missing core LUT is an error, not a
neutral substitute texture or a scene-lighting preference.

## Host Color And Optional Services

KKSLinear-v1 keeps BRDF math linear even when compiled in the Gamma authoring template. Sampling,
uniform and data restoration controls describe actual inputs. It does not require a grading LUT,
changed project color space or a runtime plugin to fix base material color.

| Optional service | Responsibility | Disabled/missing behavior |
| --- | --- | --- |
| Companion native-shadow reception for Alpha | Capture/reuse native maps, per-light matrices and camera identity | Existing receiving path; do not synthesize missing shadow maps |
| Rectangle lights | Discover bounded rectangle emitters and bind resources/quality | No rectangle contribution; native lights and physical core continue |
| Scene color/depth | Camera-scoped opaque buffers for finite glass | Rejected/missing screen sample uses unshifted RGB transmission plus reflection |
| Tess bounds support | Expand CPU culling conservatively without mutating source meshes | Author bounds manually or accept possible culling limitations |
| Shared custom Probe/SH items | Supply captured indirect scene data | Native scene Probe/SH remains the applicable fallback |

Companion version and install paths are in [Installation](../Installation.md). Source-shared files
outside this package remain dependencies of the companion build, not a reason to copy V+ libraries.
Rectangle quality has camera-scoped Off/Realtime/Reference programs and saved ME float authority;
capture promotion is not a global quality upgrade for film, POM or every shader feature.

## Geometry, Coverage And Transmission

- Ordinary Opaque/Cutout POM modifies shaded UVs and gradients only. Cutout/caster coverage stays
  on original UVs. Optional POM self-shadow attenuates complete layered native direct-light terms,
  including four-light fallback, not SH/Probe/emission/rectangle terms.
- Tess entries share Height-v1 decode but replace same-layer POM with real inward geometry. Base,
  Add and native caster/camera-depth use the shared displacement. Bounds, seams, skinning and
  DepthNormals replacement have explicit limitations. Zero height restores geometry/frame while
  the Tess entry still has geometry-stage overhead.
- Ordinary Alpha is premultiplied geometric coverage. All reflected/emissive surface terms fade
  with coverage. Optional nearest/back-shell depth modes intentionally change overlap visibility.
- Glass preserves surface reflection while computing finite RGB transmission from IOR, supplied
  thickness and absorption. Screen refraction is bounded and can reject samples. It is not full
  GGX BTDF path transport, nested media or a replacement for offscreen geometry. Glass has no caster.

## Cost And Qualification

Use Realtime presets first. Reference thin film, large/high-quality POM, several ForwardAdd lights,
Tess, self-overlap transparency and full-resolution glass buffers have different cost centers and
can combine badly. Capture latency includes CPU/driver/readback; it is not GPU frame time.

RC1 is an accepted hard-surface checkpoint with a separately recorded native-program audit and
maintainer-reported game acceptance. Cold-build reproducibility/FXC root cause remain open. This
documentation review does not rerun those tests. SSR, BSSRDF, fuzz, exact spectral/anisotropic IBL,
caustics, colored transmission shadows and arbitrary nested media are not implemented claims.
