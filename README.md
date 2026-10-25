# TomBSDF

Physically based hard-surface shaders for **Koikatsu Sunshine**, Built-in Forward
and D3D11, targeting the **Unity 2019.4.9f1 runtime**.

**0.2.0 RC1 passed packaged Editor validation and maintainer-reported KKS / ME
manual acceptance on 2026-10-25.** This is a source overlay for a compatible KKS
modding template, not a complete Unity project or an installable game package.
Cold-build/compiler-root-cause research remains open.

## Shader Entries

| Entry | Purpose |
| --- | --- |
| `tom/BSDF` | Opaque PBR, optional POM / local shadow / Glints |
| `tom/BSDFCutout` | The same physical core with coverage clipping |
| `tom/BSDFAlpha` | Premultiplied coverage transparency |
| `tom/BSDFAlphaBackFront` | Ordered back / front coverage for suitable shells |
| `tom/BSDFGlass` | Finite glass with reflection, absorption and optional screen refraction |
| `tom/BSDFTess` | Tessellation and real inward displacement |
| `tom/BSDFCutoutTess` | Displacement plus raw-UV coverage clipping |

Shared features include compensated GGX / Smith, EON diffuse, anisotropy,
Probe IBL / SH / AO, detail normals, specular AA, independent coat normals and
absorption, Realtime / Reference thin film and native multi-light shadows.

Three active `xukmi/TomBSDF*` compatibility entries are retained.
There is no V+ / TomShadersX dependency and **no modern KK / Unity 5.6 port**.

## Documentation

- [Installation / DLL configuration](Assets/Mods/TomShadersBSDF/Documents/Installation.md)
- [Material and texture guide](Assets/Mods/TomShadersBSDF/Documents/Material-Guide.md)
- [Presets / quality / dependency / cost matrix](Assets/Mods/TomShadersBSDF/Documents/HardSurface-Release.md)
- [KKS / ME acceptance checklist](Assets/Mods/TomShadersBSDF/Documents/KKS-ME-Acceptance.md)
- [Troubleshooting and bug reports](Assets/Mods/TomShadersBSDF/Documents/Troubleshooting.md)
- [Build and native-program audit](Assets/Mods/TomShadersBSDF/Documents/Build-Guide.md)
- [RC1 release status](Assets/Mods/TomShadersBSDF/Documents/Release-Status.md)
- [Documentation index](Assets/Mods/TomShadersBSDF/Documents/README.md)

## Source Setup

```powershell
git lfs install
git clone https://github.com/tomTom1010-IEE/TomBSDF.git
cd TomBSDF
git lfs pull
```

Before local edits, verify the exported files and publication rules with
`pwsh -File Tools/Validate-SourcePublication.ps1`.

Merge `Assets/Mods/TomShadersBSDF` into a compatible KKS modding template.
Keep required **prefabs, materials, native LUTs, authoring Runtime DLL and all
matching .meta files**. Do not replace native assets with LFS pointer text or
regenerate their GUIDs. The host provides its game SDK, ItemComponent and packer;
proprietary game / Unity / BepInEx reference assemblies are not redistributed.

The Gamma authoring template can stay Gamma. KKSLinear-v1 preserves linear
BRDF math for the KKS host; no isolated Linear build or grading cube is needed.

Build the optional companion with installed .NET Framework 4.6.2 targeting
support and a working game SDK:

```powershell
dotnet build Tools/TomBSDFRuntime/KKS_TomBSDF/KKS_TomBSDF.csproj -c Release -p:GameRoot="D:/Your/KKS"
```

Use `KKS_TomBSDF.dll` **0.6.0** and its matching `TomBSDF.Runtime.dll` as a pair.
The companion is optional for core physical shading, but required for rectangle
lights, screen-refraction buffers, transparent native-shadow reuse and automatic
Tess bounds. Rebuilt authoring / player runtimes must match before rebuilding
dependent native assets. See the build guide before distributing a new bundle.

## Scope And Publication Rules

Coverage Alpha is not glass. Glass uses a bounded screen / parallel-slab model,
not exact GGX BTDF, nested media, caustics or colored shadows. Rectangle lights
are unshadowed and limited to four. Probe anisotropy is approximate. SSR,
BSSRDF and extra shadow generation are not implemented.

Required native authoring assets and metadata are tracked. Large required LUTs
use Git LFS. Build outputs, zipmods, caches, test captures / fixtures, duplicate
shader backups, obsolete Linear-build experiments and local Chinese planning
notes are excluded. Active legacy compatibility code is intentionally included.
`SOURCE-INVENTORY.json` records the verbatim Unity-exported source / asset hashes.

The existing repository root [LICENSE](LICENSE) is preserved. Inherited MIT
notices are retained in [the module license](Assets/Mods/TomShadersBSDF/LICENSE),
and [the LTC notice](Assets/Mods/TomShadersBSDF/ThirdParty/LTC-LICENSE.txt) remains
with its data. This publication does not remove upstream license notices.
