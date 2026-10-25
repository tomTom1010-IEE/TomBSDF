# Rebuilding The Source Overlay

This repository overlays a compatible **KKS Unity 2019.4 modding template**.
It does not redistribute the game, Unity Editor, BepInEx SDK or the template's
ItemComponent. RC1 targets the original 2019.4.9f1 runtime / Built-in / D3D11.

## Checkout And Import

1. Install Git LFS, clone the repository and run `git lfs pull`.
2. Confirm the two large ResourcesData LUTs are full native assets, not small files beginning with `version https://git-lfs.github.com/spec/v1`.
3. Import `Assets/Mods/TomShadersBSDF` into the host template with its `.meta` files, native resources, materials, prefabs and Runtime DLL intact.
4. Preserve Gamma authoring settings. KKSLinear-v1 adapts input / output for the Linear KKS host; do not switch to an obsolete separate Linear build.
5. In Unity run **Tools / TomBSDF / Validate Source Overlay**. Resolve missing scripts / shader-owned LUTs before building. This command does not render or build automatically.

Edit native Unity assets only through the Editor / Unity APIs. The supplied
serialized assets are not templates to rewrite using string substitution.
Preserve GUIDs and non-modifiable shader texture bindings, not only filenames.

## Companion

Build with a .NET SDK, .NET Framework 4.6.2 targeting support and the game SDK:

```powershell
dotnet build Tools/TomBSDFRuntime/KKS_TomBSDF/KKS_TomBSDF.csproj -c Release -p:GameRoot="D:/Your/KKS"
```

The project resolves BepInEx and Unity assemblies from GameRoot. Its output
contains the plugin and matching runtime. Do not redistribute SDK reference DLLs.
The authoring copy at `Assets/Mods/TomShadersBSDF/Runtime/TomBSDF.Runtime.dll`
must match the player copy. If rebuilt runtime bytes change, update the authoring
DLL through Unity, validate serialized resources and rebuild dependent bundles.

## Native Build And Audit

Run **Tools / TomBSDF / Build Native Bundle** explicitly. It builds the assigned
BSDF bundle and records BSDF-owned submitted variants, including rectangle
Off / Realtime / Reference retention. It does not run developer GPU test suites
or build automatically on startup.

Outputs include:

```text
Build/abdata/chara/tom/shaders/tombsdf.unity3d
Build/TomBSDF-native-variants.jsonl
```

With Python 3.11+:

```powershell
python -m pip install -r Tools/BSDFBuildAudit/requirements.txt
python Tools/BSDFBuildAudit/audit.py Build/abdata/chara/tom/shaders/tombsdf.unity3d --submitted Build/TomBSDF-native-variants.jsonl --output Build/TomBSDF-native-audit.json
```

Require valid actual DXBC and matching stage / tier / keyword identities, not
just a written bundle or a familiar count. Tess includes VS / HS / DS / PS.
RC1 has 1642 modern and 1790 total programs; these are **this candidate's
baseline**, not fixed future limits. Unity-owned Standard programs are separately
accounted for, not falsely called BSDF-owned submission matches.

Use the host's KKS postprocess / normal zipmod packer, retaining mod metadata,
ME entries, tooltip catalog, Bundle and Studio item lists. Do not ship a newer
manifest with an older cached bundle. Audit the final archive:

```powershell
python Tools/BSDFBuildAudit/audit.py Build/abdata/chara/tom/shaders/tombsdf.unity3d --submitted Build/TomBSDF-native-variants.jsonl --output Build/TomBSDF-zip-audit.json --zipmod "Build/abdata/[tomTom][KKS] Tom Shaders BSDF v0.2.0.zipmod" --manifest Assets/Mods/TomShadersBSDF/manifest.xml
```

Then load and render the **packaged** materials in the Editor, verify shader-owned
LUT payloads / bindings, and perform the manual KKS / ME save / import checks.
An Editor source material rendering correctly is not packaged-runtime acceptance.

## Incremental Compilation Policy

Freeze source, native dependencies, toolchain, settings and submissions before
the first build. Preserve the same project's successful cache. After an initial
failure allow at most three explicit repair attempts, with strict progress and
bytecode-preservation checks. Stop on no progress or changed provenance.
One clean complete confirmation may reuse cache. Never splice binaries, reduce
samples or strip effective variants to fill the inventory.

See [Delivery Workflow](Delivery-Build-Workflow.md). A clean cold build is not
guaranteed by RC1, and the old FXC failure is not declared root-fixed. No cache
clearing, alternate compiler replacement, unattended rebuild loop or game
deployment is part of source setup.

## Repository Contents

Tracked: production shader / runtime source, manifest / tooltips, active legacy
compatibility paths, build / audit helpers, native carriers / resources / LUTs,
authoring Runtime DLL, licenses and matching metadata. Large required LUTs use LFS.

Excluded: Library / Temp / caches, `bin` / `obj`, game reference assemblies,
zipmod / Bundle / unitypackage outputs, test fixtures / images / raw reports,
duplicate `Shaders 1` / `Shaders 2`, obsolete Linear-build experiments and local
Chinese planning notes. Do not add blanket `*.dll`, `*.asset`, `*.mat`,
`*.prefab`, `*.meta` or `*.csproj` ignores: they would break rebuildability.

`SOURCE-INVENTORY.json` lists verbatim Unity-exported files and hashes. Publication
documents and root tooling are reviewed separately from the frozen render payload.
Developer Bridge tests cited by historical summaries are intentionally not shipped.
