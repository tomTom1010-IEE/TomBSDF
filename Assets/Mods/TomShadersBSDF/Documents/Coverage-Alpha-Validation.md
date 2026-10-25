# Coverage Alpha Validation (2026-10-16)

## Scope

KKS / Unity 2019.4.9f1 / D3D11 Built-in Forward. The authoring project stays
Gamma; the physical core emits KKSLinear-v1 into linear floating-point targets.
All asset preparation and camera/GPU operations use explicit Codex Bridge
commands. No computer use, user-scene save, full bundle build, game deployment,
SSR, glass/refraction or KK work is included.

Implementation: [Coverage-Alpha-Contract.md](Coverage-Alpha-Contract.md).
New entries: `tom/BSDFAlpha` and `tom/BSDFAlphaBackFront`. The four shader-owned
tables are shared with the original modern entries. Carriers and bundle paths
were created/bound through Unity APIs, not serialized-asset text edits.

## Current Evidence

- Source preservation and Alpha contract: 230 checks passed.
- Full four-entry property/manifest/tooltip/carrier contract: 997 checks passed.
- Scene-light contract: 261 passed; buffers: 29 passed; film contract: 228 passed.
- Final camera run `CodexBridge/Reports/BSDF-Alpha/Render-20261016-125405-699`:
  366 checks passed, 188 capture PNGs plus two comparison sheets. These include
  explicit null texture resets, Standard reassignment, carrier binding/bundle
  names and all four table dependencies.
- The explicit pass-variant compilation is recorded separately in
  `CodexBridge/Reports/BSDF-Alpha/Compile-20261016-203119-555/report.json`.
  Terminal status is `passed`: 18/18 selected material pass variants compiled,
  covering every pass type. The measured sum of synchronous native compile
  calls is 1312.52 seconds; this is mostly cold compilation, NOT GPU draw time.
  No variants, samples or physical features were removed for this test.
- `CodexBridge/Reports/BSDF-Alpha/static-report.json` stores the static suites.
  Report paths are relative to the Unity project root.
- Regression numerics: 83 phase/full-BRDF checks passed, including the saved
  26,571-point comparison, in `CodexBridge/Reports/BSDF-Compiler/Render-20261016-125448-729`.
- Existing opaque/cutout appearance: 212 checks passed, 81 captures and four
  sheets, in `CodexBridge/Reports/BSDF-Stage4/ColorAppearance/Render-20261016-125450-321`.
- Existing scene buffers: 168 checks passed, 65 captures and two sheets, in
  `CodexBridge/Reports/BSDF-Stage4/SceneBuffers/Render-20261016-125805-002`.
- `CodexBridge/Reports/BSDF-Alpha/result.json` is the final consolidated audit.
  Its status explicitly includes the native transparent-receiver limitation.

The camera suite covers uniform/texture coverage, Porter-Duff alpha, HDR
emission, soft masks, optional visible cutoff, zero-coverage resource/depth
neutrality, full-coverage core equivalence, partial-coverage analytical
composition, normal/detail normal, six material cases, multiple lights and fog.
Back/Front order is tested using a real camera with directional/point/spot
lights and deliberately reversed triangle ordering, not manual pass replay.
Nearest-surface/back-shell cases test actual depth rejection and a later
transparent renderer behind zero coverage. Directional, point and spot
coverage shadow CASTING is tested using the real native shadow maps.
Area lights scale once with coverage; extension-off/no-companion appearance
is neutral, and ordinary Alpha acquires no scene-color/depth leases.

Comparison sheets:

- `coverage-materials-comparison.png`: analytic premultiplied result / actual
  Alpha / full opaque reference / absolute expected-actual RGB difference x16.
- `coverage-spheres-comparison.png`: ordinary Alpha / BackFront / opaque sphere /
  ordinary-BackFront difference x16. The last column intentionally shows the
  extra surface contribution, not a regression error. Both Alpha columns use
  soft coverage masks over a checker backdrop.

Rows are plastic-red, metal-gold, anisotropic-aluminum, coat-red,
film-dielectric and film-metal. Numeric comparisons use float GPU readback,
not display-encoded PNG pixel differences.

Maximum float RGB image MAE for coverage=1 versus the opaque core is
`3.0494e-9`; for analytical partial coverage it is `2.1795e-8`. Fog composite
MAE is `5.1730e-9`; native Back/Front multiple-light order MAE is `5.5978e-9`.
Zero-coverage later-renderer depth neutrality and both depth strategies match
their analytical center values exactly in the saved fixtures.

The only changed existing shader sources are input/coverage routing,
Forward output and the ShadowCaster wrapper. All `Shaders/Core` and
`Shaders/Lighting` files, original modern shader entries and legacy reference
shader sources match the pre-Alpha snapshot byte-for-byte. The accepted LTC
FXC structural fix is unchanged. No new compiler crash dump was generated;
the Editor is responsive after all jobs, with no Alpha commands left pending.
The prior delivery bundle is untouched (SHA256
`9ec10c0bf0c4a0563513ced444fba140d26dbc2dd9859c01a14283b42b138c94`).
The runtime DLL was rebuilt only to correct its old "Alpha not implemented"
diagnostic sentence; no runtime lighting/buffer algorithm or API changed.

## Explicit Unsupported Capability

`shadow-receiver-capabilities.json` records six native transparent-receiver
cases (two entries x directional/point/spot), all marked
`unsupported_native_transparent_queue`, NOT supported or shadow-receiving
acceptance. The same-scene opaque controls visibly receive shadows; both
TomBSDF Alpha and native Standard Transparent have zero shadow-on/off delta.
Their unshadowed physical coverage composites match exactly. This agrees with
the [Unity 2019 Built-in limitation](https://docs.unity3d.com/2019.4/Documentation/Manual/ShadowPerformance.html).
No queue spoofing, forced opaque depth or extra shadow-map service is added.
This restriction is explicit in the Alpha tooltips. Full-shadow programs are
retained for compilation/possible future adapters, not removed to hide the limit.

Back/Front and the optional depth strategies are also not OIT and do not solve
arbitrary triangle/object intersections, colored transmission shadows, camera
depth-texture participation or glass thickness. Those are not claimed here.

## Diagnostics Retained

The first render report (`Render-20261016-120201-593`) retained seven failed
matched-input comparisons: copying the entire Opaque property sheet cleared
Alpha-only inputs to null/zero. Actual effective coverage was about half the
intended value. Explicitly initializing the additional mask, Coverage and
AlphaClip fixed fog/area comparisons without modifying the physical core.
Fresh/default and Standard-to-Alpha reassignment are checked separately.

The next report (`Render-20261016-122435-489`) retained twelve failed
receiver-shadow assertions. A subsequent same-scene native Standard control
proved the host limitation above; the capability report now distinguishes
unsupported native scheduling from an implementation regression. If the
Standard control receives shadows and TomBSDF does not, the test fails.
The earlier reports/Bridge exceptions remain available; they were not erased
or reclassified as successful shadow-receiving renders.

Template duplicate AssetBundle Browser GUID errors are unrelated to these
shader programs and remain in the Unity logs. Actual KKS/ME save-load,
distribution-bundle delivery, live-game performance and exhaustive variant
compilation are not accepted by this bounded Editor run.
