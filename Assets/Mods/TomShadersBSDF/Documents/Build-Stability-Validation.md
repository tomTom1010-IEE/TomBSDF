# Complete Build Stability Investigation

Date: 2026-10-23. Status: **current cached baseline passes artifact/packaged-material
delivery checks; controlled incremental delivery accepted; cold research deferred**.

## Glints Delivery (2026-10-24)

The changed-source Glints version now passes the current delivery gate with
1042 modern /1190 total valid native programs and28 packaged-material pairs
(161 checks,56 PNGs). Initial compilation took9488.01s and omitted one Cutout
program. Explicit repair added exactly that program without replacing any of
the previous1189 bytecodes. A subsequent20.32s cached full confirmation has no
new shader errors;24 known template GUID diagnostics remain separate.
Stale ShaderUtil/importer diagnostics were archived, reproduced with a compiled
cached pass, then cleared by explicit shader reimport before confirmation.
No cache was cleared, no code/sample/variant was cut and no binary was spliced.
See [Glints validation](Glints-Validation.md) for exact histories, hashes and the
stronger visible-Cutout package fixture. This is not a compiler root-cause fix.
The new archive is `Baseline-20261023-190023-291`; the previous seals below remain
unchanged. Actual KKS/ME and production GPU profiling remain release checks.

## Latest Delivery Decision (2026-10-23)

The user accepted controlled same-source incremental repair plus strict artifact
auditing as the current delivery workflow. Two independent successful cold builds
are no longer a prerequisite for delivery or the next Glints implementation.
The complete baseline and its normal packaging/render evidence below remain valid;
the failed cold candidates remain failed and are not deployed. Each future source
version must pass its own final build, native-program, zip and material gates.

The exact workflow and bounded repair/stop rules are in
[Delivery-Build-Workflow.md](Delivery-Build-Workflow.md). Cold-root-cause research,
alternate toolchains and `qualify.py` are retained as deferred diagnostics, not
silently relabeled as successes. `CodexBridge/Reports/BSDF-BuildAudit/current-status.json`
records the earlier cold audit, not this newer policy. This documentation update
did not run a build or render and does not assert full live-KKS release acceptance.

## Build Qualification Infrastructure (2026-10-23)

The following archive/cold results describe the pre-Glints baseline. Subsequent
Glints implementation has 51 production shader/includes and its own frozen
candidate, explicit complete build, memory/log observations and passed delivery
audit. See [Glints validation](Glints-Validation.md); the old 48-source seal is
preserved and is not evidence that the new feature was already packaged.

The main successful ShaderCache, project settings and installed Editor are
preserved. All 48 production shader/include hashes are unchanged in this round.
The reusable implementation is in project-root `Tools/BSDFBuildAudit`; native
asset export/import and render commands execute through Codex Bridge.

- Sealed baseline: `CodexBridge/Reports/BSDF-BuildAudit/Baseline-20261023-101057-904`.
  It contains the complete bundle, source/configuration/submission records,
  original compiler and builtin-include hashes, exported dependencies, material
  comparison images and a hash seal. 1042 modern programs is this source version's
  baseline, not a permanent feature or variant-count limit.
- Native auditing checks actual segmented DXBC, stage/instruction/chunk bounds,
  keyword identities and hardware tiers against native submissions. Unity's
  common-tier sentinel and unnamed `Pass 0` serialization are handled explicitly.
  Corrupt/missing programs and exact failed variants are reported; Unity-owned
  shaders lacking preprocess callbacks are listed, not claimed as captured.
- `DeliveryGate-20261023-100339-345` passes the normal project Zipmod packer,
  exact Bundle/manifest/CRC checks and 22 paired source-versus-zipped-material
  regressions (44 PNGs). The zip already present before this repack was complete;
  the earlier stale-zip incident is historical, not an error reproduced here.
- A separate original 2019.4.9f1 Linear/D3D11 validation player passes a 42-case
  baseline self-check (84 PNGs, maximum RGBA delta 0). It covers native lights,
  Probe fallback, coat, both film qualities, anisotropy, POM, Alpha, Back/Front
  and glass resource-missing fallback, plus sixteen bare/film rectangle cases on
  both area quality paths with pre-draw keyword checks. These are baseline
  self-checks, not validation of a cold candidate, actual KKS/ME or the complete
  extension lifecycle. Evidence: `Player-Area-Baseline-Selfcheck`.
- The now-deferred cold gate `qualify.py` joins two independent cold lifecycles, matching toolchains,
  original-runtime comparisons and a normal package containing a qualified cold
  artifact. Complete caches or repeated use of one project cannot satisfy it.
- Eighteen unit tests and seven PowerShell syntax checks pass. Negative cases
  cover missing programs, instruction/custom-data overruns, wrong stages/tiers,
  stale zip payloads and incorrectly counting one cache as two cold runs. The
  instruction-record walker follows the [Microsoft tokenized format](https://raw.githubusercontent.com/microsoft/DirectXShaderCompiler/main/include/dxc/Support/d3d12TokenizedProgramFormat.hpp);
  it checks structural bounds, not full opcode/operand semantics or every driver.
  `final-baseline-instruction-audit.json` again verifies the unchanged delivery
  bundle/zip: 1042 modern and 1190 total programs, no mismatches.

### Independent Cold Build D

Frozen configuration/source/dependency hashes match baseline091024. A fresh
external project, normal RGBM lightmaps, Gamma/D3D11 and seven compiler processes
were used. The build took 4805.09 seconds and emitted **1040/1042** modern programs;
it is rejected and never promoted to delivery. Missing fragment programs:

- `BSDFAlphaBackFront / ForwardBaseFront`: `DIRECTIONAL SHADOWS_SCREEN
  TOM_BSDF_AREA_REFERENCE UNITY_SPECCUBE_BLENDING`.
- `BSDF / ForwardBase`: `DIRECTIONAL SHADOWS_SCREEN TOM_BSDF_AREA_REALTIME`.

The first worker fault is the old FXC `ReadWriteInfo/PropagatePredicates` family;
the second reports `failed to emit instruction`. This identifies compiler failure
stages, not a proven triggering HLSL expression. Minimum sampled free physical
memory was 12.73 GiB, maximum single compiler private memory 1.98 GiB. Sampling
does not exclude brief peaks or prove any hardware diagnosis. This run overlapped
other isolated diagnostics; wall time is not a controlled compiler speed benchmark.
Licensing-client signature messages are recorded separately from shader errors.

Evidence: `CodexBridge/Reports/BSDF-BuildAudit/Cold-D/` and
`cold-D-verification.json`. The raw first crash dump expired during Windows'
rolling retention before it could be copied; parsed/symbolized evidence survives.
Do not describe it as a retained raw dump.

### Toolchain Candidates

Copies with signed System32 FXC26100 and SDK FXC19041 fail even basic Unity
builtin imports despite independent D3DCompile smoke success. They are rejected,
not installed into the main Editor, and do not establish a shader-source defect.
The official signed Unity2019.4.40f1 installer was extracted into an external
directory without executing the installer. Its UnityShaderCompiler differs,
but its FXC binary is identical to 2019.4.9's. Cold-G completed in 4918.45 seconds
and emitted **1041/1042** modern programs (1189 total). It is rejected. Missing:

- `tom/BSDFCutout / ForwardBase / Fragment / Tier1`:
  `DIRECTIONAL LIGHTPROBE_SH TOM_BSDF_AREA_REALTIME UNITY_SPECCUBE_BOX_PROJECTION`.

Production source, native dependencies and captured rendering settings match
the baseline. The newer Editor has eleven changed builtin includes, separately
listed in `cold-G-verification.json`; it is not claimed to be an identical
compiler environment. Its worker dump again identifies old FXC ReadWriteInfo
optimization, not a proven source expression. Minimum sampled free RAM was
12.73 GiB, maximum sampled single-worker private memory about1.98 GiB. This does
not establish CPU/RAM health or prove an allocation root cause. The complete
logs, memory samples, partial bundle and exact native audit are in `Cold-G/`;
the retained raw dump is `cold-G-worker-8884.dmp`.

A second 2019.4.40 project (H) was cancelled once G failed, rather than waiting
for a possibly lucky result and calling that a repair. Loader-proxy experiments
I/J failed builtin imports before BSDF was imported. Read-only inspection shows
the private Unity loader uses a fixed import mapping, including zero-return
stubs for LoadLibraryA/GetProcAddress; the tested proxy is not a valid way to
substitute modern FXC. This is a separate loader issue, not the shader-optimizer
root cause. See `rejected-loader-provenance.json`. No binary patch was applied to
Unity, and no alternate toolchain was installed into the authoring Editor.

**Historical cold qualification: NOT PASSED, zero qualifying cold builds out of
the two required by that separate gate.** Two full diagnostic runs completed, but both contain shader errors
and missing programs. The normal packaging/render gate passed for the complete
cached baseline only. No failing cold bundle replaced that delivery. All owned
diagnostic Editors have exited; the main Editor/cache remain untouched.

If cold research is explicitly resumed, its next work is a verified optimizer-
trigger reproduction and equivalent HLSL repair, or a demonstrably compatible
supported compiler route. After that, run
two new independent cold projects, compare their output on original2019.4.9,
and package one of those exact cold bundles. No feature/sample/valid-variant
reduction or retry-filled cache is accepted as the fix.

That root-cause sequence is deferred by the newer decision above. The current
stage-5 sequence is audited incremental delivery, Glints, optional real displacement,
then hard-surface release preparation. No Glints, displacement, KK adaptation or
game deployment has been performed. Diagnostics use explicit Codex Bridge commands.

## Evidence Before The Host Check

The original October 19 bundle is missing 119 modern native programs when
compared with the current unchanged variant contract. A written bundle is not
proof of shader completeness. The audit reads actual Unity shader blobs and
validates DXBC against the final IPreprocessShaders submission record.

| Complete diagnostic build | Delivered modern programs | Result |
| --- | --- | --- |
| Cache-Bundle-20261023-033405-131 | 1041 / 1042 | Missing Alpha ForwardBase Realtime fragment |
| Cache-Bundle-20261023-044419-460 | 1039 / 1042 | Missing BackFront Realtime, Cutout Reference and Opaque Reference fragments |
| Cache-Bundle-20261023-060852-830 | 1039 / 1042 | Three BackFront fragments missing after worker crashes |
| Cache-Bundle-20261023-153653-508 | 1042 / 1042 | Same-source cached repair, all three missing fragments recovered |
| Cache-Bundle-20261023-154336-648 | 1042 / 1042 | Same-source cache recheck, byte-identical to the complete repair |

The three completed builds took 3450.15, 3659.24 and 2934.10 seconds. No incomplete build
is deployed. The third build source hashes were unchanged. Opaque174, Cutout174,
Alpha176 and Glass172 are complete; BackFront343/346 is not. Its missing programs:

- Back/Fragment: DIRECTIONAL LIGHTPROBE_SH AREA_REALTIME plus both probe keywords.
- Back/Fragment: DIRECTIONAL plus both probe keywords, **area path disabled**.
- Front/Fragment: DIRECTIONAL LIGHTPROBE_SH SHADOWS_SCREEN AREA_REALTIME plus probe blending.

The exact prefixed keyword sets are retained in `native-third-audit.json`.
The final cached ShaderUtil error list is empty despite the missing programs;
native process errors and the actual delivered-program audit remain mandatory.
Known immutable duplicate AssetBundle Browser GUID messages are
retained separately from genuine shader/compiler errors, not silently ignored.

Crash minidumps identify Unity's private FXC 10.0.14393.33 in
`CProgram::ReadWriteInfo` / `PropagatePredicates`, with D3DCompile flags 0x1000
and ps_5_0. This identifies the failing optimizer stage, not a proven HLSL
trigger. Shader resources inspected so far remain within D3D11 limits. Failing
Reference cases also exclude an LTC-only explanation.

Native platform defines enable both probe blending and box projection even
when they are absent from the material keyword label. Isolated reproductions
must include those platform defines. Earlier probe-off isolated passes were
not equivalent to the failing native programs. Corrected independent FXC
reconstructions pass repeatedly, but do not establish native batch stability.

## Same-Source Incremental Repair

At the user's request, retained the successful shader cache and reran the
complete original bundle through Bridge, without shader changes, frozen
diagnostic shaders, binary patching, stripping, or compiler/settings changes.
All 48 shader/include source hashes still match the third build. Unity can
reuse compiled variants with identical source and compile missing variants;
see [Unity 2019.4 shader compilation](https://docs.unity3d.com/2019.4/Documentation/Manual/shader-compilation.html).

Command031 completed in **176.9203 seconds**. Actual bundle DXBC audit confirms
**1042/1042** submitted modern programs. Comparison against the third bundle:

- All 1039 previously delivered program bytecodes are identical.
- Exactly the three previously missing fragments were added, with no removals.
- Each recovered Back/Front fragment is byte-identical to the matching keyword
  program in the opposite face pass. This is not evidence of a Back/Front-only
  shading algorithm error; the earlier builds also failed Alpha/Cutout/Opaque.

Command032 repeated the complete bundle build in **8.1077 seconds**. The second
audit again confirms 1042/1042, all byte-identical to command031. Both builds
report no shader/compiler errors, while retaining the template's 24 duplicate
AssetBundle Browser GUID errors as separate environment errors.

The command031 watcher sampled memory every 10 seconds (20 samples). Minimum
available physical memory was **29.38 GiB**; maximum committed memory was
**23.05 GiB** against a **143.84 GiB** commit limit. Compiler private bytes summed
to at most 3.60 GiB in those samples; the largest single sampled worker was
0.63 GiB. This shows ample capacity during this incremental repair, NOT the
earlier cold/batch builds. Sampling can miss short peaks and is not a RAM
integrity test. Command032's watcher started after its fast build finished;
its single sample is not an in-build memory measurement.

These two complete raw diagnostic bundles are saved, not postprocessed or
deployed to the game. No delivered-bundle render was performed in this round.
Successful cache recovery is distinct from a cold-build reliability fix. The
next root-cause investigation should distinguish compiler allocation/lifetime
faults and batch concurrency/memory pressure from hardware instability rather
than assuming the CPU is at fault. Do not clear this recovered cache casually.

## Current Source Candidate

- Four-light fallback loops retain all four lights and order without forced
  inlining expansion of the complete layered evaluator.
- Alpha depth/shadow helpers and their private uniforms are owned by their
  consuming passes; common coverage behavior is unchanged.
- Thin-film channel-specific Airy spectra are evaluated in RGB lanes. All
  16 harmonics and 32/64/256/512 integration budgets are retained. The original
  scalar functions remain an independent numerical oracle.
- The complex square-root real-axis limit is evaluated analytically, avoiding
  cancellation that invents a transmitted component at lossless TIR.

No BRDF feature, public property, sampling quality, shader identity, native
variant or material binding is removed. These changes are **not yet a proven
fix for complete native builds**. Other single-exit/receiver/LTC experiments
remain diagnostic-only outside production.

## Numerical And Appearance Checks

- 60 source-contract checks and 231 Alpha source checks pass.
- 8,416 optical cases: maximum non-TIR vector/scalar error 4.10080e-5;
  maximum lossless-TIR error against analytic reflectance=1 is 2.38419e-7.
  The unchanged scalar oracle has a small TIR cancellation error; its raw
  discrepancies are retained. The existing 1e-4 bound was not relaxed.
- Reference and Realtime each pass 294 independent complete layered-BRDF
  point/furnace checks. Reference maximum GPU/MIS furnace discrepancy is about
  5.72e-5; maximum white-furnace loss about 0.00798 remains within its old bound.
- Four frozen-source thin-film appearance pairs pass 21 checks; eight PNGs
  are saved. Maximum RGBA difference is 9.53674e-7.
- Timing is warmed 256-square Camera.Render plus completion, not pure GPU
  or actual-game frame time. One sequence has first-case outliers; no stable
  performance claim is made before opposite-order repetition.

## Independent Host Evidence

Read-only Windows event inspection found WHEA event 19 at **2026-10-23
06:09:14.270 +08:00**, shortly after the third build started: Processor Core,
Corrected Machine Check, Translation Lookaside Buffer Error, APIC16.
Seven other October16 events report processor Internal parity error, mostly
APIC16. A corrected hardware event alone does not prove the cause of an FXC
crash; it does mean host stability cannot be ruled out from a repeated
compiler stack or a repeatable heavy workload.

The inspected host uses i7-14700KF, MSI MPG Z790 EDGE TI MAX WIFI,
BIOS1.70 dated2024-08-14, and Update Revision registry bytes29 01 00 00 hex
(microcode0x129). Intel currently recommends relevant Intel Default Settings
and BIOS microcode0x12F or later for this processor family:
[Intel support article](https://www.intel.com/content/www/us/en/support/articles/000102331/processors.html).
This is vendor guidance, not a diagnosis of permanent CPU damage.

No firmware, voltage, power, affinity or compiler installation was changed.
Additional independent stress compiles were stopped after this evidence was
found. The user subsequently reported stable CPU testing, raised memory as an
alternative, and requested trying to recover the three missing programs. The
bounded same-source repair above succeeded without additional stress tests or
hardware-setting changes. Neither WHEA nor a successful repair establishes the
root cause; do not label the CPU or RAM as defective based on this evidence.

## Saved Evidence

Project-relative paths outside Assets:

- `CodexBridge/Reports/BSDF-Stage5Stability/work-in-progress.md`
- `CodexBridge/Reports/BSDF-Stage5Stability/host-evidence.json`
- `CodexBridge/Reports/BSDF-Stage5Stability/native-first-audit.json`
- `CodexBridge/Reports/BSDF-Stage5Stability/native-second-audit.json`
- `CodexBridge/Reports/BSDF-Stage5Stability/native-third-audit.json`
- `CodexBridge/Reports/BSDF-Stage5Stability/native-incremental-031-audit.json`
- `CodexBridge/Reports/BSDF-Stage5Stability/incremental-031-bytecode-comparison.json`
- `CodexBridge/Reports/BSDF-Stage5Stability/incremental-031-memory-summary.json`
- `CodexBridge/Reports/BSDF-Stage5Stability/native-cache-032-audit.json`
- `CodexBridge/Reports/BSDF-Stage5Stability/incremental-032-bytecode-comparison.json`
- `CodexBridge/Reports/BSDF-Compiler/Cache-Bundle-20261023-153653-508/`
- `CodexBridge/Reports/BSDF-Compiler/Cache-Bundle-20261023-154336-648/`
- `CodexBridge/Reports/BSDF-Stage5Stability/Render-20261022-220610-112/`
- `CodexBridge/Reports/BSDF-Stage5Stability/Render-20261022-220501-632/`
- `CodexBridge/Reports/BSDF-Stage5Stability/Render-20261022-220516-654/`
- `CodexBridge/Reports/BSDF-Compiler/Film-Vector-20261023-060450-393/`

The complete 1042/1042 native-program audit and cache recheck passed; the later
normal packaged-material regression at the top of this document also passed.
Cold/batch reliability remains unresolved and deferred. Actual KKS/ME acceptance
and broader production-performance qualification remain distinct from these
artifact gates. Passing a cached build does not prove that a future full shader-
source rebuild will avoid the optimizer failure.
