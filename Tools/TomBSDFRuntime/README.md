# TomBSDF KKS Scene Companion

## Canonical Source And Distribution

Since 28 October 2026, runtime development/builds and game DLL distribution are
owned by [TomRenderInfrastructure](https://github.com/tomTom1010-IEE/TomRenderInfrastructure).
Install its KKS 0.1.0 base package before the TomBSDF shader package. TomBSDF
shader releases no longer embed the companion or Probe DLLs. The files retained
beside this README in the original Unity workspace are historical compatibility
mirrors, not inputs for a new standalone companion build.

Build the maintained `src/BSDF` projects through the infrastructure solution and
its documented SDK/GameRoot workflow. All migrated helpers require the matching
single `TomRender.Core.dll`; do not mix old standalone providers with the cohort.
The shader source overlay retains its Unity authoring Runtime DLL and matching
Core/metadata for native asset import; these are not a game installation package.

Current companion feature version: **0.6.0**. There is no V+ / TomX shader-pack
dependency and no Unity 5.6 backend. See the module's `Documents/Installation.md`, `Build-Guide.md`
and `Release-Status.md` for current support and acceptance.

## Build

```powershell
# Run in the separate TomRenderInfrastructure repository:
pwsh -File build/Build.ps1 -GameRoot "D:/Your/KKS"
```

Requires a .NET SDK, .NET Framework 4.6.2 targeting support, the KKS managed SDK
and BepInEx. Install `KKS_TomBSDF.dll` and matching `TomBSDF.Runtime.dll`
together in `BepInEx/plugins/TomBSDF`. Do not redistribute reference DLLs.

The authoring Runtime DLL in `Assets/Mods/TomShadersBSDF/Runtime` and the single
Core authoring dependency must match the accepted player cohort. Use Unity-managed
identity/resource validation for runtime revisions; do not hand-edit serialization
or assume that changing DLL hashes alone authorizes rebuilding shader Bundles.

## Services

- Up to four ME-controlled unshadowed rectangle lights.
- Camera-scoped Off / Realtime / Reference selection with temporary owned keywords.
- Supported Screenshot Manager lifecycle promotion of area integration only.
- Demand-driven scene color / depth for independent BSDFGlass refraction.
- Native directional / point / spot map reuse for transparent receivers.
- Reversible pre-cull bounds management for Tess meshes and skinned renderers.

The control item is **Tom BSDF / Lighting / Tom Rectangle Area Light Prototype**.
It is invisible and emits along local +Z. Native lights, Probe / SH and colors do
not depend on the companion. No SSR, missing-shadow-map generation, camera
replacement or game color-space change is performed.

Configuration lives in `BepInEx/config/com.tomtom1010.tombsdf.scene.cfg`.
Keep Validation / File Bridge false outside explicit developer diagnostics.
The scene master switch does not disable the independent bounds service.

Developer GPU fixture commands and raw reports are intentionally excluded from
the public source overlay. No startup test or automatic build runs. User-operated
game acceptance and Editor validation are distinct evidence.
