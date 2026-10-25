# Area Quality Isolation Validation

2026-10-16/17. Unity 2019.4.9f1, D3D11, RTX 4070 Ti SUPER, Gamma authoring
project with the unchanged KKSLinear-v1 adapter. All Editor operations used
explicit Codex Bridge commands. No game operations, KK port, glass, SSR or
full distribution build/deployment were performed.

## Implemented Contract

- Modern BSDF, Cutout, Alpha and Back/Front Base passes have separate local
  Off/Realtime/Reference programs. Add, depth and caster variants are unchanged.
- Physical core, film qualities, LUTs, samples, native pragmas, pass order and
  manifest properties/defaults are preserved. Base variant count increases by
  three; isolation is not feature stripping or a promise of faster full builds.
- Companion 0.3.0 synchronizes authoritative ME floats per camera and restores
  its owned keywords. Old same-name bundles are capability-gated; missing/old
  companions leave the new shader's native-light/Probe/SH fallback available.
- Optional Screencap Pre/Post events and a changed camera target promote only
  area integration. Recording-wide VideoExport lifetimes and nested captures
  retain live quality between exported frames. No saved float is modified.

See [AreaQuality-Contract.md](AreaQuality-Contract.md) for exact behavior and
unsupported capture integrations. There are no new public shader identities,
material parameters, carrier materials or prefabs to bind for this change.

## Source-Oracle Appearance

The pre-change shader/include sources are preserved in
`CodexBridge/Reports/BSDF-AreaQuality/Before-20261016`. The oracle uses their
original dynamic integrator, not a copy with new quality branches disabled.

The explicit resumed render passes **204 checks**, saving **57 captures** plus
a comparison sheet. Bare dielectric, metal, anisotropy, coat and film are
compared at both qualities. Every opaque comparison has RGB MAE zero; the
largest Alpha/BackFront comparison MAE is **9.0413e-11**. Cutout, premultiplication
and fog order are retained. ME scalar/reset-equivalent changes, clones, shader
switch, local/master disable, zero intensity, no emitters and no companion pass.

Screenshot public-event fixtures test two video frames under one recording
lease, live draws between them, nested events/cameras, restoration and absence
of global keyword pollution. This is Editor API-fixture evidence, not actual
Screenshot Manager/VideoExport or interactive KKS acceptance.

The unchanged independent rectangle probe passes 38 cases at each of two
integration settings. Worst normalized RGB errors are 0.050799 at 32 samples
and 0.006338 at 2048 samples. These are independent probe settings, not a claim
that the production 128-sample Reference has the latter error bound.

Comparison sheet (developer-local: `CodexBridge/Reports/BSDF-AreaQuality/Render-20261016-151533-615/area-quality-parity.png`)
and render report (developer-local: `CodexBridge/Reports/BSDF-AreaQuality/Render-20261016-151533-615/report.json`).
Rows: bare, metal, anisotropy, coat, film. Columns: old RT, new RT, absolute
difference x32, old Reference, new Reference, absolute difference x32.

## Compilation And Retention

Six explicit selected real-program compile reports pass, including preserved
dynamic source, new RT/Reference, and combined directional shadow/SH/dual-Probe/
EXP2 fog programs for opaque RT and BackFront Reference. Native uncached area
programs still take approximately **191-215 seconds** each. The 0.002-second
Off result is a cache-hit observation, not a cold-build performance result;
the first two reports predate cache-state metadata.

An additional **18 Alpha pass programs** pass: depth, area-free Base with
shadow/probe/fog, point/spot full-shadow Add, and depth/cube casters across
Alpha and BackFront. This does not claim transparent shadow receiving; the
native queue/resource limitation recorded in the Alpha contract remains.

The independent hidden constant-color retention canary builds/loads and
selects all three qualities without material/SVC carriers: **48 submitted
fragment variants, 16 native groups x 3 qualities**. The production build guard
checks complete quality triplets without stripping or rewriting anything.
This is not exhaustive production-variant compilation or a distribution build.

The canary report preserves 144 native log errors, all matching the template's
existing duplicate immutable AssetBundle Browser GUID conflicts. There are no
new shader/compiler errors in these checks. The active-RT cleanup warning from
the first canary attempt was fixed; the final rerun does not repeat it.

Final retention report (developer-local: `CodexBridge/Reports/BSDF-AreaQuality/Retention-20261017-001459-350/report.json`).
Alpha native report: `CodexBridge/Reports/BSDF-Alpha/Compile-20261017-001545-021`.

## Performance Characterization

Four complete runs retain **272 records / 136 old-new pairs** at 256/512,
0/1/4 rectangles and bare/aniso/coat/film materials. Two runs mirror order.
The last run uses 30 warmup frames and 15 samples of three renders per case;
earlier runs use 2 warmup frames and 5 samples. No raw outlier is discarded.

These are warmed **Camera.Render + GPU-complete AsyncGPUReadback latencies**,
including CPU submission, keyword synchronization, driver and readback costs.
Both source versions use the updated companion. These are not GPU timestamps,
an old-runtime comparison, actual KKS frame times or an FPS prediction.

Representative last-run medians, 512 target, one quad, four rectangles, ms:

| Material | Old RT | New RT | Old Reference | New Reference |
| --- | ---: | ---: | ---: | ---: |
| Bare | 1.309 | 1.331 | 4.504 | 4.353 |
| Anisotropic | 1.883 | 1.869 | 5.597 | 5.533 |
| Coat | 2.686 | 2.849 | 9.158 | 7.770 |
| Film + coat | 10.691 | 10.488 | 38.532 | 36.018 |

Low-load measurements are not uniformly stable. An initial 256/four-light film
ratio of 1.106 became 0.978 and 1.008 in repeats. Other single-light cases show
much larger latency excursions, including after longer warmup. Do not turn a
median across cases into a guaranteed GPU speedup or assert no regression in
every workload. Main-path raw data and pooled medians remain in the summary.

A separate **20-check / 8-record diagnostic** bypasses automatic synchronization
on transient test materials with fixed local keywords. Both LTC bindings are
128x64 and all four old/new output comparisons pass. Timing excursions still
occur with fixed keywords, including on the original shader. This rules out
missing LTC or changed images in those cases, and does not identify the
driver/scheduler/clock cause. It is not shipping-path performance evidence.

Last full timing run (developer-local: `CodexBridge/Reports/BSDF-AreaQuality/Render-20261016-163357-901/performance.json`)
and fixed-keyword diagnostic (developer-local: `CodexBridge/Reports/BSDF-AreaQuality/Diagnostics/Render-20261016-164257-247/performance.json`).

## Reproducibility And Boundaries

Summary and all run paths (developer-local: `CodexBridge/Reports/BSDF-AreaQuality/result.json`)
are generated by `Tests/summarize_area_quality.ps1`. An incomplete, interrupted
or failed command cannot be reported as completed merely because files exist.
The interrupted pre-restart attempt is retained separately, never auto-replayed.

Static checks pass: area quality 76, input/property contract 997, Alpha 230,
scene lighting 261, scene buffers 29, film optimization 228 and color contract
35. These suites overlap; their totals must not be added as unique tests.
Companion build succeeds with zero warnings/errors, and the authoring runtime
DLL hash matches the compiled runtime.

The additional scene-buffer regression passes **168 checks / 65 captures**,
including native light/Probe/SH/area coexistence and nested camera/resource
lifetimes. No new material appearance regression is reported.
Scene-buffer regression (developer-local: `CodexBridge/Reports/BSDF-Stage4/SceneBuffers/Render-20261016-164414-155/report.json`).

The shipped `Build/abdata/chara/tom/shaders/tombsdf.unity3d` remains unchanged:
SHA256 `9EC10C0BF0C4A0563513CED444FBA140D26DBC2DD9859C01A14283B42B138C94`.
Actual KKS/ME save-import, game screenshot integration, reliable GPU profiling
and a future complete production-variant bundle build remain separate acceptance.
