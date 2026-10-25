# Area Quality and Compilation Isolation

KKS / Unity 2019.4 / Built-in Forward / D3D11 only. This is stage-4.1
engineering cleanup, not a new BRDF, lower sample budget or new area-light
model. Glass, SSR, transparent shadow receiving and KK remain separate work.

## Paths and Preserved Mathematics

Every modern ForwardBase (including both Alpha Back/Front groups) declares
one local multi-compile set:

- No keyword: native lights/Probe/SH/coat/film only, no area include or calls.
- `TOM_BSDF_AREA_REALTIME`: unchanged LTC control variate, 16 residual samples
  per proposal on bare isotropic material; otherwise 32 complete-BRDF MIS
  samples per proposal. No 128-sample branch in this program.
- `TOM_BSDF_AREA_REFERENCE`: unchanged full-BRDF MIS, 128 samples per proposal,
  no LTC control variate. Reference is retained, not replaced by a fit.

The original dynamic integrator remains in the area include's unqualified
path for independent numerical probes, and the complete pre-change sources
are preserved in `CodexBridge/Reports/BSDF-AreaQuality/Before-20261016` as a
separate render/compile oracle. The structural FXC clipper fix is unchanged.
Thin-film Realtime/Reference and all other physical calculations are unchanged.

There are no added draws, Pass reordering, sampling changes, light/shadow/fog/
probe removals or build-time feature stripping. The new set multiplies Base
variants by three: isolation reduces the work inside an individual program,
not the number of retained programs. It is NOT a promise of a three-times
faster full build. Add/caster/depth programs get no area quality variants.

## ME and Optional Companion

Existing floats and serialized defaults are unchanged: `SceneLighting=1`,
`AreaLightIntensity=1`, `AreaLightQuality=0`. Values greater than 0.5 select
Reference; values up to 0.5 select Realtime. The exact legacy midpoint keeps
its non-LTC 32-sample behavior. Capture promotion deliberately selects Reference.

The companion reads actual shared materials and their floats before each
camera draws, after filtering active renderers by the camera's layer mask.
It uses `GetSharedMaterials`, never creates renderer material instances,
never writes floats/shaders, and changes only the two owned local keywords.
This handles ME edits/reset/copy, Timeline values, fresh loaded materials,
and shader switches without a hard MaterialEditor API/Harmony dependency.

Each nested camera saves and restores enclosing keywords independently.
Post-render, service disable/destroy and aborted camera stack cleanup restore
the previous owned keyword state without overwriting other plugins' keywords.
No quality keywords are written to carrier materials or prefab assets.
An internal SubShader capability tag prevents new keywords being applied to
same-name older shader bundles. The new shaders require companion 0.3.0 for
rectangle integration; older/missing companions retain native-light fallback.
Redundant keyword writes are skipped. The current implementation scans active
renderers per camera for immediate ME correctness; large-scene CPU scaling is
not inferred from the small Editor fixture. A LateUpdate watchdog restores an
aborted synchronous render scope; no valid Camera.Render spans LateUpdate.

Without the companion, the unqualified program remains the original native
lighting/Probe/SH result, with zero rectangle contribution, as before. Extension
off, local off, zero intensity or no visible emitter also selects the area-free
path. Supplying old global arrays manually without a service no longer enables
production rectangle lighting: clients must use the scoped companion protocol.

## Screenshot and Offline Export

The optional plugin config `Area Light Quality / Screenshot Reference`
defaults to true. A reflection-bound adapter uses the existing public
`Screencap.ScreenshotManager.OnPreCapture` and `OnPostCapture` events. It has
no hard Screenshot Manager dependency and safely does nothing without that API.

Inspected local sources:

- `BepisPlugins_OfflineReShade/src/Core_Screencap_KKEC/ScreenshotManager.OfflineExport.cs`:
  Ctrl+F10 brackets capture with Pre/Post, ending in finally; KKS reuses
  `Camera.main` and temporarily changes its target to a color RT, with a depth
  blit after the same render. There is no required dedicated screenshot scene.
- `HSPlugins_OfflineReShade/VideoExport.Core/ScreenshotPlugins/ScreencapPlugin.cs`:
  OnStartRecording/OnEndRecording bracket the entire recording. Each Normal+
  Depth frame calls `ExportOfflineReShadeInputs`, which does not emit events.

The adapter keeps a stack of lifecycle leases, allowing a recording to contain
nested captures. Reference promotion requires BOTH an active lease for that
camera AND a non-null target different from its pre-capture target. Live draws
between exported frames follow the saved material quality (Realtime by default).
Stereo renders using the same camera
inherit the lease. Reflection/preview and unrelated cameras do not.

PostCapture/adapter disposal releases leases; material keywords are restored
after every camera independently. Exception-safe exporters must still close
their lifecycle: this project does not patch other plugins' coroutines. A direct
caller of `ExportOfflineReShadeInputs` must bracket it with Pre/Post, as the
local VideoExport does. Independent cloned/360 camera exporters need explicit
`TomBSDFCaptureQuality.Begin(camera, ...)` integration; no name/size heuristics
or guessed scene matching are used. No other local plugin source was changed.

Promotion changes only rectangle integration precision, not thin-film quality,
saved ME values, material colors, coverage, native shadows or render settings.
It is still rasterized real-time rendering with higher integration accuracy,
not a path tracer, additional bounces or an offline light transport solver.

## Retention and Evidence

`multi_compile_local`, not `shader_feature`, preserves all three quality paths
for runtime selection without carrier keyword dependence. Native variants are
unchanged. A non-mutating `IPreprocessShaders` guard verifies complete Off/RT/Ref
groups for every submitted fragment Base keyword/tier/platform combination;
if another stripper removes a quality, packaging fails rather than silently
choosing a wrong variant. The guard never removes or rewrites any variants.

A tiny independent constant-color canary uses the same native Base/local
pragmas, with no material or SVC keyword carriers. Its isolated test bundle
checks submitted quality triplets and GPU selection of all three after loading.
That is a retention-mechanism test, not a production BRDF/distribution build;
the shipped `tombsdf.unity3d` is not rebuilt or replaced by it.

Explicit Bridge commands compile selected real material programs, render
against preserved source, audit optional/disabled/nested capture behavior and
measure both qualities. No global shader cache is removed. First-request and
repeat compile times must be labeled; they are not a controlled cold-cache
benchmark or an exhaustive delivery build.

Camera completion timings include CPU submission, material synchronization,
GPU completion and readback/driver latency. They are not pure GPU timestamps
or live KKS frame time. A full distribution build and actual game screenshot/
VideoExport acceptance are not performed by these Editor checks.

Saved results and timing limitations are in
[AreaQuality-Validation.md](AreaQuality-Validation.md). Timing commands support
`reverseOrder`, `warmupFrames` and odd `timingSamples` for explicit repeat runs.
`fixedQualityDiagnostic` is test-only and writes under `Diagnostics`; its
transient fixed-keyword materials are not shipping-path performance evidence.
