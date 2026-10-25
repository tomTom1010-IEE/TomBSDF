# TomBSDF KKS Scene Companion

Current companion feature version: **0.6.0**. Source accompanies the independent
`Assets/Mods/TomShadersBSDF` overlay. There is no V+ / X dependency and no Unity
5.6 backend. See the module's `Documents/Installation.md`, `Build-Guide.md`
and `Release-Status.md` for current support and acceptance.

## Build

```powershell
dotnet build Tools/TomBSDFRuntime/KKS_TomBSDF/KKS_TomBSDF.csproj -c Release -p:GameRoot="D:/Your/KKS"
```

Requires a .NET SDK, .NET Framework 4.6.2 targeting support, the KKS managed SDK
and BepInEx. Install `KKS_TomBSDF.dll` and matching `TomBSDF.Runtime.dll`
together in `BepInEx/plugins/TomBSDF`. Do not redistribute reference DLLs.

The authoring Runtime DLL in `Assets/Mods/TomShadersBSDF/Runtime` must match
the player runtime. Rebuilt runtime changes require Unity-managed resource
validation and rebuilding dependent assets; do not hand-edit native serialization.

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
