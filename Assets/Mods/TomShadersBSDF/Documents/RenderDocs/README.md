# TomBSDF Rendering Documentation

Portable entry for users and agents without this author's chat history. Reviewed 2026-10-27 against
manifest **0.2.0**, GUID `tom.Shaders.BSDF`, the **0.2.0 RC1** release. Target: KKS Unity 2019.4.9f1
runtime, Built-in Forward/D3D11. RenderDocs is documentation, not RenderDoc GPU-capture data.

## Read First

Starting with a new machine or an unconnected toolchain? Follow [Environment setup](EnvironmentSetup.md)
and its portable [entry skill](skills/kk-scene-pipeline-setup/SKILL.md) before material authoring.
The skill covers Blender MCP, the matching Unity template/bridge, StudioMCP and a saved-scene round trip.

1. [Shared rendering knowledge](SharedRendering.md): calibration, terminology and safe agent workflow.
2. [Pipeline](Pipeline.md): physical core, Pass ownership, resources and fallback boundaries.
3. [Material contracts](MaterialContracts.md): channels, units, transparency, height and layering.
4. [Shader catalog](ShaderCatalog.json): manifest registrations, source/carrier paths, categories,
   literal Pass names and content fingerprints. No compilation or runtime acceptance is implied.
5. [Material guide](../Material-Guide.md), [architecture](../Architecture.md),
   [release profiles](../HardSurface-Release.md) and [release status](../Release-Status.md).

## Choose An Entry

| Need | Shader |
| --- | --- |
| Opaque hard surface | `tom/BSDF` |
| Binary coverage holes | `tom/BSDFCutout` |
| Premultiplied coverage fade | `tom/BSDFAlpha` |
| Back/front shell ordering | `tom/BSDFAlphaBackFront`, not OIT |
| Reflection-preserving optical transmission | `tom/BSDFGlass`, not faded ordinary Alpha |
| Real inward displacement | `tom/BSDFTess`, `tom/BSDFCutoutTess` |
| Optional rectangle-light item control | `tom/RectAreaLight`, not a surface replacement |
| Existing legacy scenes | `xukmi/TomBSDFBase`, `xukmi/TomBSDF`, `xukmi/TomBSDFAlpha` |

There are seven modern surface entries, three separate legacy compatibility entries and one control
registration. Do not describe all eleven registrations as modern materials. Main bundle:
`chara/tom/shaders/tombsdf.unity3d`. Native carriers, runtime/resource assets, shader-owned LUTs and
their GUIDs are required source assets, not disposable Editor-generated clutter.

## First Agent Prompt

```text
Read Documents/RenderDocs/README.md, Pipeline.md and MaterialContracts.md, then the exact shader's
manifest and tooltip. Distinguish modern and legacy entries, texture transport, active map modes,
coverage and optical transmission. Inspect installed artifacts separately from source capability.
Use current feature contracts, not an old proposal or conversation. Report approximations and
validation scope. Do not build, mutate Unity assets, deploy, operate UI or push without task authority.
```

## Maintain And Check

From this package root in PowerShell 7:

```powershell
./Documents/RenderDocs/Audit-RenderDocs.ps1
# After reviewing actual changes and updating the reference:
./Documents/RenderDocs/Audit-RenderDocs.ps1 -RefreshCatalog -ReviewDate YYYY-MM-DD
```

The default audit is read-only. A static catalog does not prove delivered VS/HS/DS/PS, LUT binding,
game loading or appearance. For actual delivery, follow [Delivery Workflow](../Delivery-Build-Workflow.md).
No new rendering/build acceptance occurred while adding these docs. Historical count baselines and
the manifest's older descriptive acceptance wording do not supersede Release Status.

The separate local Agent-Knowledge directory contains machine-specific Rainline evidence and is
not required by this portable entry. A user can use RenderDocs from a standalone source overlay
without the local showcase folders, V+, TomX or any conversation context.
