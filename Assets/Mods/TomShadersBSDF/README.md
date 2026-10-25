# TomBSDF

Modern physically based materials for **Koikatsu Sunshine**, targeting the
Unity 2019.4.9f1 runtime, Built-in Forward and D3D11.

**0.2.0 RC1:** the packaged Editor regression and native-program audit passed;
the maintainer reported KKS / MaterialEditor manual acceptance passed on
2026-10-25. This does not claim Unity's historical FXC failure is fixed or
independent cold builds are reproducible.

| Shader | Purpose |
| --- | --- |
| `tom/BSDF` | Opaque hard surfaces, optional POM and Glints |
| `tom/BSDFCutout` | Shared core with consistent raw-UV coverage clipping |
| `tom/BSDFAlpha` | Premultiplied coverage transparency |
| `tom/BSDFAlphaBackFront` | Back-then-front coverage rendering for suitable shells |
| `tom/BSDFGlass` | Reflection-preserving finite glass and optional screen refraction |
| `tom/BSDFTess` | Independent tessellation and real inward displacement |
| `tom/BSDFCutoutTess` | Displaced geometry with coverage clipping |

The core includes compensated GGX / Smith, EON diffuse, anisotropy, native
lights / shadows, Probe IBL, SH, AO, detail normals, specular AA, layered coat,
absorption and Realtime / Reference thin film. Three `xukmi/TomBSDF*` identities
remain for existing scenes. They are active compatibility paths, not dead code.

## Documentation

- [Installation and companion configuration](Documents/Installation.md)
- [Material / texture guide](Documents/Material-Guide.md)
- [Presets, quality, dependencies and cost](Documents/HardSurface-Release.md)
- [KKS / ME acceptance](Documents/KKS-ME-Acceptance.md)
- [Troubleshooting](Documents/Troubleshooting.md)
- [Rebuilding and artifact auditing](Documents/Build-Guide.md)
- [RC1 status](Documents/Release-Status.md)
- [Complete index](Documents/README.md)

This is an independent **KKS modding-template source overlay**, not a standalone
Unity project or an installable zipmod. Preserve native materials, prefabs, LUTs,
authoring Runtime and `.meta` files. Two large LUTs require Git LFS. Compiled
packages are distributed separately; a source clone is not a game installation.

Companion **0.6.0 + matching TomBSDF.Runtime.dll** enables rectangles, scene
buffers, transparent native-shadow reuse, capture quality and automatic
displacement bounds. Base colors / physical shading do not depend on it.
Tom Lighting Probes 0.2.1 is optional; neither V+ nor TomShadersX is required.

Coverage Alpha is not optical glass. Glass is a finite parallel-slab / screen
approximation, not complete GGX BTDF, nested media or a lens solver. Anisotropic
Probe IBL and rough-layer transport remain approximate. Rectangles are limited
to four unshadowed emitters per camera. No SSR, BSSRDF, caustics, colored shadows,
automatic missing-shadow-map generation or KK / Unity 5.6 port is included.

Repository-level licensing is provided at the GitHub root. Inherited notices
remain in [LICENSE](LICENSE) and [the LTC notice](ThirdParty/LTC-LICENSE.txt).
