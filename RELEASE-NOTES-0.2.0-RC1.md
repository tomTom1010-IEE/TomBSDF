# TomBSDF 0.2.0 RC1 - KKS Complete Package

> Historical 2026-10-26 Complete-package notes. Current **Infra1** installation
> requires [TomRenderInfrastructure 0.1.0](https://github.com/tomTom1010-IEE/TomRenderInfrastructure/releases/tag/v0.1.0)
> first; new shader packs do not embed DLLs or Probe resources. See the current
> [installation guide](Assets/Mods/TomShadersBSDF/Documents/Installation.md) and
> [Infra1 release](https://github.com/tomTom1010-IEE/TomBSDF/releases/tag/v0.2.0-rc1-infra.1).
> The older archive and instructions below remain preserved for historical use,
> not as a recommendation to mix pre-Core providers into the new cohort.

Binary release: **2026-10-26**. KKS / Unity 2019.4.9f1 runtime / Built-in Forward /
D3D11. This is the accepted **RC1 pre-release**, not a KK / Unity 5.6 package.
No new shader compilation or material-feature change was made for distribution.

## Downloads

- **Recommended:** `TomBSDF-KKS-Complete-0.2.0-RC1-20261026.zip`. Contains the main zipmod, matching Companion 0.6.0 / Runtime, optional Tom Lighting Probes 0.2.1 with its DLL pair, English instructions / offline manual and license notices.
- **Core only:** `TomBSDF-KKS-0.2.0-RC1.zipmod`. For existing matched installations or ordinary core shading without scene extensions. It does not contain the companion DLLs.
- `SHA256SUMS.txt` verifies both downloadable archives. The Complete zip also contains per-file payload checksums.

[Open the release](https://github.com/tomTom1010-IEE/TomBSDF/releases/tag/v0.2.0-rc1).
GitHub's automatic source-code archives are not game installers.

## Installation / Upgrade

1. Close Studio and KKS. Keep backups outside `mods` and `BepInEx/plugins`.
2. Remove older duplicate BSDF zipmods, including `TomShadersBSDF-Stage4-KKS-test.zipmod` or a previous same-GUID package. Keep exactly one `tom.Shaders.BSDF` registration.
3. Extract the Complete zip into a temporary folder. Copy its `mods` and `BepInEx` folders into the KKS game directory, preserving their paths.
4. Replace both `BepInEx/plugins/TomBSDF/KKS_TomBSDF.dll` and `TomBSDF.Runtime.dll` together. Do not keep old DLL copies in another plugin subfolder.
5. Optional Probe tools use their own zipmod and `BepInEx/plugins/TomProbe/` pair. If already installed by TomShadersX at 0.2.1, these are the same shared tools, not a second provider. You may omit all three Probe files together if not wanted.
6. Keep your existing configuration. Do not extract a zipmod over game `abdata`; leave it intact in `mods`. Do not copy source materials / prefabs / metadata into the game.
7. Start Studio, check the plugin log, select a `tom/BSDF*` entry in ME and test a scene copy before replacing existing materials.

Base rendering needs the usual BepInEx, KKS API, Sideloader, Extended Save and ME
stack. Neither the full V+ nor TomShadersX shader pack is required. The shared
Probe tool is optional and Studio-only. Screenshot automatic area Reference
requires a compatible Screenshot Manager lifecycle API; that plugin is not bundled.

Configuration is `BepInEx/config/com.tomtom1010.tombsdf.scene.cfg`.
Defaults enable scene services and native transparent shadow reuse, with a
128 MB per-camera copy budget and **Validation / File Bridge=false**. No config,
game, scene, character card or diagnostic command payload is installed by this archive.

## Included Materials

Seven modern entries: `tom/BSDF`, `tom/BSDFCutout`, `tom/BSDFAlpha`,
`tom/BSDFAlphaBackFront`, `tom/BSDFGlass`, `tom/BSDFTess` and
`tom/BSDFCutoutTess`. Three active `xukmi/TomBSDF*` compatibility identities and
the invisible `tom/RectAreaLight` control are retained.

Shared features include compensated GGX / Smith and EON diffuse, anisotropy,
Probe / SH / AO, detail normals, specular AA, layered coat / absorption and
optimized / Reference thin film. Supported solid entries add POM local shadows,
statistical Glints and separate real Tess displacement.

The companion adds up to four unshadowed rectangles, bounded screen refraction,
native-map transparent shadow reuse, supported capture quality lifecycle and
automatic displacement bounds. No companion means documented neutral fallbacks,
not broken base colors. Glass retains unshifted RGB transmission / reflection;
unmanaged displacement bounds need manual authoring.

## Validation And Limits

The unchanged Bundle passes a fresh native / final-zip audit: **1642 modern /
1790 total valid programs**, with required VS / HS / DS / PS accounted for.
The earlier packaged regression passed 330 checks and 44 exact source / package
pairs; the maintainer reported KKS / ME manual acceptance passed. The binary
payload is the already accepted artifact, not an untested recompile.

Coverage Alpha is not glass. Glass is finite parallel-slab / screen transport,
not a complete GGX BTDF, lens or nested-medium solver. Anisotropic IBL and layer
transport remain approximations. No SSR, BSSRDF, caustics, colored shadows,
area shadows, extra missing-shadow-map rendering or arbitrary transparent sorting
is provided. POM / Glints / Tess are not offered on Alpha / Glass in this release.
The historical Unity FXC cold-build problem is not declared solved.

## Documentation

- [Showcase](https://tomtom1010-iee.github.io/TomBSDF/)
- [User manual](https://tomtom1010-iee.github.io/TomBSDF/UserManual.html)
- [Parameter reference](https://tomtom1010-iee.github.io/TomBSDF/Reference.html)
- [Support](https://github.com/tomTom1010-IEE/TomBSDF/blob/main/SUPPORT.md)

The repository license and inherited MIT / LTC notices are preserved in the
Complete archive. Source and required authoring assets remain in the repository;
compiled release packages and developer test intermediates are not committed to Git.
