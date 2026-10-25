# Contributing

Read the [architecture](Assets/Mods/TomShadersBSDF/Documents/Architecture.md) and
[build guide](Assets/Mods/TomShadersBSDF/Documents/Build-Guide.md) first.

- Keep changes scoped; do not make modern shaders depend on V+ / TomShadersX.
- Preserve neutral controls, map / unit contracts, native shader identities and ME persistence.
- Use Unity APIs for native assets. Keep required GUIDs, shader-owned LUT bindings and the matching authoring runtime.
- Install Git LFS. Large LUT pointer text is not a usable imported Unity asset.
- Keep support documentation in English for this publication.
- Do not commit caches, build / game packages, SDK references, test captures, crash dumps or duplicate backup shaders.
- Do not blanket-ignore DLL / native asset / metadata / project extensions. Required authoring assets must remain rebuildable.
- Retain upstream and third-party license notices and the repository-level license.

For rendering changes, document neutral-path / regression comparisons and test
the actual packaged Bundle. Audit submitted identities against real VS / HS /
DS / PS DXBC; matching counts alone do not prove completeness. Keep bounded
incremental repair evidence. Do not remove features, reduce samples or strip
valid variants to hide compiler errors.

Explain mathematical and approximation changes in a pull request, distinguish
Editor evidence from actual KKS / ME acceptance, and list tests not performed.
No automatic legacy-material migration or KK adaptation is part of RC1.
