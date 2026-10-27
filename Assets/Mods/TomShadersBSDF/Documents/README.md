# Documentation

These English documents describe **TomBSDF 0.2.0 RC1 for KKS**. The maintainer
reported KKS / ME manual acceptance passed on 2026-10-25. See
[Release Status](Release-Status.md) for evidence and boundaries.

The [sphere showcase](https://tomtom1010-iee.github.io/TomBSDF/) follows the
sibling TomShadersX presentation: real GPU comparisons and expandable settings.
The [web manual](https://tomtom1010-iee.github.io/TomBSDF/UserManual.html)
combines the user chapters, and the searchable
[parameter reference](https://tomtom1010-iee.github.io/TomBSDF/Reference.html)
uses all 592 current modern/control manifest and tooltip entries.

## Start Here

For an agent without prior project context, start with the portable
[Rendering documentation](RenderDocs/README.md). It has its own shared reference, pipeline,
material contracts and a static source/manifest/carrier inventory; local evidence is not required.

| Document | Content |
| --- | --- |
| [Installation](Installation.md) | zipmod / DLL paths, dependencies and companion configuration |
| [Material Guide](Material-Guide.md) | Shader selection, maps, normal encodings, coverage, height and units |
| [Release Profiles](HardSurface-Release.md) | Six starting materials, quality, dependency / cost / fallback matrix |
| [Manual Acceptance](KKS-ME-Acceptance.md) | Game checks, save / reload / import and capture lifecycle |
| [Troubleshooting](Troubleshooting.md) | Known limits and useful bug reports |
| [Architecture](Architecture.md) | Current module boundaries and support scope |
| [Build Guide](Build-Guide.md) | Source overlay, Git LFS, native build and actual artifact audit |
| [Delivery Workflow](Delivery-Build-Workflow.md) | Frozen candidates and bounded incremental repair |
| [Release Status](Release-Status.md) | RC1 audit, user acceptance and open compiler research |

## Feature Contracts

- [Foundation](Foundation-Contract.md) and [property data](Foundation-Properties.json)
- [Coat and thin film](Layering-Contract.md)
- [Scene lighting](SceneLighting-Contract.md) and [area quality](AreaQuality-Contract.md)
- [Scene buffers](SceneBuffers-Contract.md) and [native shadow reception](ShadowReceiving-Contract.md)
- [Coverage Alpha](Coverage-Alpha-Contract.md) and [finite glass](Glass-Contract.md)
- [POM](POM-Contract.md) and [local self-shadow](POM-SelfShadow-Contract.md)
- [Glints](Glints-Contract.md), [tessellation](Tessellation-Contract.md) and [presets](Release-Presets.json)

English `*-Validation.md` files are historical milestone summaries, not the
current release status. Developer Bridge fixtures, image directories and raw
reports cited there are not shipped in the source overlay. Older pending-work
statements apply to their own dates and do not override Release Status. No
private scene, screenshot collection, crash dump or test cache is needed to rebuild.

## Agent Maintenance Reference

Use the public [RenderDocs](RenderDocs/README.md) for reusable KKS/ME import,
pipeline and material contracts. Machine-local authoring notes, scene-specific
settings and raw evidence are not source-publication inputs or rebuild dependencies.
