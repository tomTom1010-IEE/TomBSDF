# Controlled Incremental Delivery

Policy adopted2026-10-23; current RC1 status updated2026-10-25.
A complete audited artifact and a reproducible cold compiler are separate gates.
This is not a root-cause fix for the historical Unity FXC failure.

## Current Baseline

[RC1 status](Release-Status.md) records seven modern entries,1642 modern /
1790 total programs, exact zip payload / LUT checks, packaged regression and
subsequent maintainer-reported KKS / ME acceptance. The original1042 program
baseline was pre-Tess and is not a fixed target for future development.
Unity-owned Standard programs are separately accounted for.

Historical failed / partial bundles remain failed. A current complete artifact
does not reclassify cold-build research, earlier worker crashes or compiler
substitution experiments as successful.

## Freeze A Candidate

Before building record source, shader includes, native dependencies / GUIDs,
manifest / tooltips, runtime assemblies, Bundle bindings, relevant build tools,
Editor / UnityShaderCompiler / FXC / builtin includes, D3D11 settings / tiers /
keywords, authoring color and stripping configuration.

Keep a previous complete delivery for regression. Each source / dependency /
configuration change requires a new candidate, not a retry of the old freeze.
Keep the same project's successful ShaderCache; no cache transplantation or
unrequested cold-cache clearing.

## Bounded Build And Repair

1. Explicitly build the complete assigned BSDF bundle with native submission capture. Cache hits are allowed. A snippet compile alone is not a delivery build.
2. Save each attempt's provenance, command / result, submissions, logs, duration, output hashes, native identity audit and available memory / process observations.
3. After the first attempt, allow at most **three explicit incremental repair builds**. No unattended retry or automatic crash replay. Keep successful cache.
4. While incomplete, the missing / invalid identity set must strictly shrink. Previously valid DXBC must remain valid; unexpected replacements require explanation and review.
5. Stop on no progress, changed provenance, damaged output, resource failure, unexplained replacements or the repair limit. Preserve the last accepted artifact.
6. Once complete, one clean confirmation may reuse cache. The final build interval must have no new shader / C# compile errors. An earlier errorful attempt is not the final acceptance.
7. Match submissions even for cache-only rechecks: reuse only a provenance-matched retained inventory, never an empty expected set.

Do not manually splice missing programs, concatenate bundles, reduce sampling,
remove features or strip effective variants. ForceRebuild can rebuild the container
while still using shader cache; it does not mean an interrupted request resumes
at a literal instruction checkpoint.

## Mandatory Artifact Checks

| Gate | Required result |
| --- | --- |
| Provenance | Frozen sources / dependencies / settings / toolchain match |
| Build interval | Completed request, no new shader / script errors |
| Native identity | Required stage / tier / keyword identities present, not just a matching count |
| Executable structure | Actual segmented DXBC stage, bounds, chunks and executable records valid |
| Geometry | Include VS / HS / DS / PS for Tess paths |
| Archive | Correct manifest, CRC, no duplicate paths, exact embedded Bundle hash |
| Resources | Shader-owned native LUT references resolve and payloads match |
| Rendering | Load actual zipped materials, compare with matched source inputs |
| Player | Manual KKS / ME edit, save / reload / import and extension lifecycle checks |

Known duplicate immutable AssetBundle Browser GUID diagnostics are recorded
separately. They never excuse a new shader / script failure. Keep original failed
attempt logs, not only a clean Console screenshot.

## Validation Changes And Publication

A validation-only amendment must preserve the original native producer and
evidence, record a separate validation-source snapshot and prove unchanged
production inputs. It does not silently replace earlier producer provenance or
reset repair limits. RC1's corrected implicit-LUT check followed this rule.

Use [Build Guide](Build-Guide.md) and the shipped `Tools/BSDFBuildAudit/audit.py`.
Full developer Bridge fixtures, raw reports and cold-research tools are deliberately
not part of the public overlay. Preserve required authoring assets / metadata;
exclude cache, build outputs, duplicate shader backups and obsolete tools.

Native / zip / render acceptance does not prove all driver instruction semantics
or universal performance. Alternative toolchains require real loading / rendering
in the original2019.4.9f1 runtime before adoption. No automatic game deployment,
KK synchronization, compiler replacement or cold research is part of publication.
