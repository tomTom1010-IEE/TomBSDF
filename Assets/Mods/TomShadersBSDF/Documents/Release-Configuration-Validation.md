# Release Configuration Acceptance (2026-10-24)

Scope: release definition, six starting materials, explicit Realtime/Screenshot
copies, dependency/cost/fallback guidance. No BRDF, shader, manifest, tooltip,
runtime DLL or existing carrier changed; no distribution build, deployment,
interactive game operation, migration or KK work. Unity operations use the
explicit Codex Bridge, never hand-authored native asset serialization.

## Accepted Outputs

- [Release scope and dependency/cost matrix](HardSurface-Release.md).
- [Release-Presets.json](Release-Presets.json), version 1, current numerical source.
- Twelve independent authoring materials in `Material/Presets`: each of Plastic,
  Metal, BrushedMetal, CarPaint, ThinFilm and Glass has a Realtime and Screenshot
  copy. No preset has a Bundle assignment or saved area-light quality keywords.
- Shader defaults and existing `m_` / `a_` carriers remain unchanged. These are
  NOT an ME one-click preset feature or a runtime-wide quality setting.
- Seven modern shader importers reference the existing 27 applicable shader-owned
  energy/anisotropy/film/LTC resources. No importer/LUT was rewritten.

Screenshot materials choose area Reference, dormant POM Reference and Full
glass requests. Both profiles keep optimized Realtime thin film. Automatic
capture promotion is still area-only; no screenshot guesses or global geometry
promotion were added. Missing mandatory LUTs remain a delivery defect, distinct
from optional plugin fallback.

## Bridge And Static Results

Paths below are relative to the Unity project root:

The current entry point is `CodexBridge/Reports/BSDF-Release/validation-index.json`;
it records exact material identities, the catalog hash and all 55 image hashes.

| Gate | Evidence under `CodexBridge/Reports/BSDF-Release` | Result |
| --- | --- | --- |
| Saved/reimported presets and resource inventory | `Prepare-20261024-112352-080/presets.json` | 12 materials, 7 shaders, 27 bindings |
| Explicit camera preview and fallback checks | `Render-20261024-112414-769/report.json` | 126 checks pass, 27 captures |
| Release catalog/ranges/scope/prepared assets/current evidence | `contract-validation.json` | 959 checks pass |
| Existing six-entry foundation property/manifest/tooltip contract | `foundation-contract-validation.json` | 1633 checks pass |
| Protected production files before/after | `protected-before.json`, `protected-after.json` | All 181 hashes unchanged |
| Cached native shader diagnostics | final prepare/render `presets.json` | 0 Errors, 67 retained pre-existing Warnings |

The 181 protected files include production shaders/includes and their metadata,
manifest, tooltips, existing materials/prefabs/resources/runtime assets, and the
existing BSDF distribution bundle/zip. Newly created standalone preset assets
are intentionally outside that set. No source or bytecode compatibility change
is inferred from merely saving a new material.

Preview fixture: Unity 2019.4.9f1 / D3D11, Gamma authoring project with an explicit
linear HDR target, one directional light, fixed synthetic HDR reflection and SH,
isolated sphere and a checker backdrop for glass. No rectangle is created; the
costly area Reference programs are not requested by this preview. No new
performance benchmark or full variant inventory is claimed.

`Release-Presets-preview.png` has rows Plastic, Metal, BrushedMetal, CarPaint,
ThinFilm, Glass. Columns are Realtime/no companion, Realtime/scene buffers,
Screenshot/scene buffers. The five non-glass rows are expected identical because
POM is disabled, film quality is unchanged and no area emitter is active.
The glass rows verify actual 128-square Half versus 256-square Full buffers and
nonzero valid refraction; extension off and buffers off exactly match the
no-companion RGB-transmission/reflection fallback.

The named anisotropy, coat and film features have independent disabled controls
with nonzero image differences. Every capture is finite, nonnegative and not the
missing-LUT diagnostic. All twelve preset asset hashes are unchanged by rendering.
PNG previews share the existing Reinhard/sRGB display transform, not a shader
color modification. All 27 full linear float captures are also saved as EXR;
there are 28 PNGs including the comparison sheet. Images were visually inspected.

## Retained History And Residual Checks

- Command `20261024-bsdf-release-001-prepare` was consumed by the old Bridge
  assembly and reported Unknown operation. It made no assets. An explicit refresh
  and a fresh claimed command succeeded; no crash replay or automatic retry was
  introduced. All command results are retained in `CodexBridge/Outbox`.
- Initial previews (`Render-20261024-111730-874` and `Render-20261024-112053-227`)
  used a high-F0 white-metal film example with weak visible color. Only the two
  newly owned film preset materials were explicitly revised via Bridge. The
  accepted version uses a dark dielectric substrate and film IOR 2.2 / 420 nm;
  shader defaults, reference optics and BRDF mathematics did not change.
- The historical `Tests/validate_glass.ps1` returns 139/152, with 13 failed
  **obsolete freeze-snapshot checks**. Its POM compatibility switch handles only
  property-contract versions 8/9, while current Glints/Tess uses version 11. Eleven
  source comparisons and two whole-manifest/tooltip comparisons therefore still
  target the October 18 pre-Glints/pre-Tess snapshot. Results are preserved in
  `historical-glass-validation.json`, not hidden or counted as passing. All those
  production inputs are identical to this task's before hashes; none of its
  other 139 glass declaration/transport/runtime checks failed. No baseline was
  rewritten to turn this script green. Update its versioned audit contract during
  the separately planned resource/contract consolidation, not as a shader fix.
- Existing 67 FXC warnings remain visible. No claim of a warning-free compiler,
  fixed cold-build root cause, complete native-program distribution or real KKS
  performance acceptance is made.
- The shared Editor log also contains the template's existing duplicate immutable
  AssetBundleBrowser GUID conflicts and unrelated tasks. They are not evidence
  of a BSDF preset regression, and this scoped result is not an error-free-project
  claim. This round did not modify those packages or other projects.

## Remaining Release Work

Full ME/tooltip consolidation and non-destructive migration are not implemented
by authoring presets. Resource/valid-variant consolidation, final seven-entry
VS/HS/DS/PS package audit, exact zip payload and packaged-material regression
remain. The accepted shipping package is still pre-Tess Glints, unchanged here.
Actual KKS appearance, shader switching, reload, save and import acceptance stay
with the user. Controlled incremental delivery remains the policy; cold research
and KK adaptation remain deferred.

Re-run configuration checks explicitly:

```powershell
pwsh -NoProfile -File Assets/Mods/TomShadersBSDF/Tests/validate_release_presets.ps1
```

Bridge operations are `preparebsdfrelease` and `renderbsdfrelease`. Preparation
refuses to overwrite a material whose ownership or values differ from the
catalog; preview refuses an already active user scene service. No startup work
or full bundle operation is scheduled.
