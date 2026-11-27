# TomBSDF 0.2.1 for Koikatsu Sunshine

The rectangle light can now be added after MaterialEditor loads its shaders. ME reads a dedicated shader-source prefab; Studio keeps the original placeable prefab. The mod GUID, item slot, material name and saved scenes are unchanged. This release carries the qualified S7 shader bundle (2,634 native programs); no shaders were recompiled for promotion.

Close Studio and KKS. Move the old TomBSDF zipmod outside `mods/`, then place `TomBSDF-KKS-0.2.1.zipmod` in `mods/`. Keep exactly one `tom.Shaders.BSDF`. Install [the shared runtime](https://github.com/tomTom1010-IEE/TomRenderInfrastructure/releases/tag/v0.1.1) first. Update [Lighting Probes](https://github.com/tomTom1010-IEE/TomRenderInfrastructure/releases/tag/lighting-probes-v0.2.6) separately for the equivalent probe and SH fix. Keep the installed ME and DLLs. This resource release does not install or upgrade the optional planar/SSR runtime.

Stock KKS ME 4.0.3: all seven Lighting Probes items plus the rectangle were created, saved and loaded after ME had actually applied the three control shaders. Rectangle radiance, probe capture/box projection and SH edits were verified in rendered images. The ownership contract also applies to ME 5.0; no patched ME is distributed or required. Roll back by restoring your prior zipmod, not by deleting user cards or clearing caches.

The [release fingerprint](distribution/0.2.1.json) lists the installable zipmod and both stored Unity bundles. For source builds, use the original item bundle plus an independent `AssetBundleBuild` named `chara/tom/me/rect_control_source.unity3d` with only `Assets/TomMEControlSources/a_RectAreaLightME.prefab` as its exported entry; keep it self-contained. Never register a Studio item as an ME shader source.
