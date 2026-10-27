# Installation

**Install [TomRenderInfrastructure KKS 0.1.0](https://github.com/tomTom1010-IEE/TomRenderInfrastructure/releases/tag/v0.1.0)
first**, then the [TomBSDF Infra1 shader pack](https://github.com/tomTom1010-IEE/TomBSDF/releases/tag/v0.2.0-rc1-infra.1).
The shader release no longer embeds companion/Probe DLLs. Its `mods` folder
contains the unchanged accepted BSDF zipmod; shared DLLs and Probe resources
come from the base, installed once even when using both BSDF and TomX.
GitHub's automatic source-code archives are not game installers.

## Supported Host

TomBSDF 0.2.0 RC1 targets **KKS / Unity 2019.4.9f1 runtime / Built-in Forward /
D3D11**. The player is Linear; the authoring template may remain Gamma.
KKSLinear-v1 handles that boundary without a color-grading cube or the companion.
Do not change the game's color space. KK / Unity 5.6 is not supported by this release.

Keep a working BepInEx, KKS API, Sideloader, Extended Save and MaterialEditor
installation. ME tooltip-catalog support is optional, not a rendering dependency.

## Game Files

Close Studio / KKS before replacing DLLs. Back up previous BSDF files outside
the `mods` and `BepInEx/plugins` trees. Keep only one mod GUID
`tom.Shaders.BSDF` and one copy of each runtime assembly.
Paths below are relative to the game root, for example `D:/Program Files/KoikatuSunshine`.

| File | Install location | Required for |
| --- | --- | --- |
| `TomBSDF-KKS-0.2.0-RC1.zipmod` | `mods/` | Shaders, carriers, LUTs, tooltip catalog and rectangle item lists |
| `KKS_TomBSDF.dll` 0.6.0 | `BepInEx/plugins/TomBSDF/` | Optional scene companion |
| Matching `TomBSDF.Runtime.dll` | `BepInEx/plugins/TomBSDF/` | Matching scene services and resource types |

The two DLL rows above are supplied by TomRenderInfrastructure, not this shader
archive. Install its matching `TomRender.Core.dll` and complete DLL pairs; remove
old standalone duplicates. Runtime source/build ownership is in that repository's
`src/BSDF`, not the retired standalone Tools build. Do not copy SDK references.
Windows FileVersion alone cannot distinguish cohorts; check release hashes.

The published zipmod is byte-identical to the accepted authoring output named
`[tomTom][KKS] Tom Shaders BSDF v0.2.0.zipmod`. Its filename does not change
the internal mod GUID or version. Keep only one of these same-GUID copies.

Do not unpack zipmods over game `abdata` or install LUT / prefab / material /
`.meta` files separately. A repository clone is source, not an installable
zipmod; see [Build Guide](Build-Guide.md).

## Configuration

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

## Optional Probe And Capture Tools

Tom Lighting Probes **0.2.2** is supplied by the base, with its zipmod in `mods/` and both
`KKS_TomProbe.dll` / `TomProbe.Runtime.dll` in `BepInEx/plugins/TomProbe/`.
Items appear under **Tom Lighting / Probes**. It is an independent Studio-only
tool; installing the full TomShadersX pack is unnecessary. Replace old 0.2.1
resources and DLLs together; do not mix cohorts. Native environment
lighting remains available without it. Reflection capture requires the game's
Realtime Reflection Probes quality setting and a completed capture.

Existing Screenshot Manager / Screencap integration is optional. A compatible
lifecycle API and matching camera target allow temporary rectangle Reference
quality. Unsupported APIs keep material-selected quality. Thin-film, POM and
tessellation do not automatically promote. No replacement capture plugin is bundled.

## First Launch

1. Install the base first and check `BepInEx/LogOutput.log` for Companion 0.6.0 and missing / duplicate assembly errors.
2. Select all seven modern `tom/BSDF*` entries on independent test materials.
3. For area lighting, add **Tom BSDF / Lighting / Tom Rectangle Area Light Prototype**. It is intentionally invisible and emits along local +Z.
4. Complete [Manual Acceptance](KKS-ME-Acceptance.md), including scene save / reload / import.

The three legacy `xukmi/TomBSDF*` entries remain for existing scenes. A modern
shader switch is not a semantic migration: duplicate the old material first
and explicitly initialize new coverage / optical inputs.
