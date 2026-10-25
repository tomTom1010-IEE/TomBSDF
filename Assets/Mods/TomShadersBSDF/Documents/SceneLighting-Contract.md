# KKS Scene Lighting Prototype v1

Original scope: stage 4.0 and 4.1, Unity 2019 Built-in Forward / D3D11. The later
2026-10-16 demand-driven color/depth service has its independent
[SceneBuffer-v1 contract](SceneBuffers-Contract.md). No KK adapter, modern Alpha,
transmission, SSR implementation or global color-space change.

## Neutral behavior

`SceneLighting=0`, `AreaLightIntensity=0`, an absent/disabled scene service, an
unrecognized protocol, or no selected emitters adds zero to the existing shader.
Native lights, shadows, reflection probes and the existing Tom SH receiver
contract remain independent. Area lighting is evaluated once in ForwardBase,
before linear output and fog, never in ForwardAdd. The observed KKS host is
Linear; the authoring template is Gamma. Controlled Editor checks use a linear
float target; the ordinary Gamma Scene/material preview is not the KKS display
pipeline and is not a colorimetric acceptance reference.

The prefab-facing `TomBSDF.Runtime.dll` does not automatically bootstrap a service.
Only the companion plugin or an explicit Editor test does so. Having a control
prefab or authoring DLL without the plugin therefore does not silently enable it.

## Camera protocol

- `_TomBSDFSceneParams`: x=1 (protocol), y=selected count, z=enabled, w=reserved.
- Four fixed-length arrays: center, half-right, half-up and linear RGB radiance.
- Half-right.w selects one-/two-sided emission. The cross product of the two
  axes is the emitting front normal. Local +Z faces the illuminated surface.
- Camera pre-render publishes a camera-filtered, priority/instance-ID-stable
  list. Post-render clears it or restores the enclosing camera during nested
  renders. Disable/destroy clears the validity vector.
- This prototype accepts four emitters per camera. Lower-priority overflow is
  counted and ignored, not folded into Unity's point-light arrays.
- Camera culling layers filter emitter controls. Per-receiver light linking,
  automatic relevance ranking, textured emitters, shadows and occlusion are not
  implemented. Rectangles illuminate compatible BSDF materials only.

## Radiometric and geometric inputs

Emitter color is explicitly sRGB by default; the control has a linear-input mode.
`AreaLightRadiance` multiplies linear RGB radiance in engine reference units, not
lumens. Area and distance are already present in the solid-angle integral; no
second inverse-square factor or arbitrary range attenuation is applied.
Changing width/height at fixed radiance changes total emitted power. Transform
scaling affects the two half-axis vectors; negative scale changes orientation.
Degenerate emitters are rejected. The control renderer is invisible and does
not cast shadows, but remains enabled so Studio visibility can disable the light.

## Integration and quality

Subsequent compilation isolation and camera-scoped ME/screenshot quality are
specified in [AreaQuality-Contract.md](AreaQuality-Contract.md). Its Off/RT/Ref
local variants preserve all sample counts and mathematics described below;
the unqualified production Base now omits rectangles entirely without a service.

Bare isotropic Realtime uses the pinned Heitz/Dupuy/Hill/Neubelt LTC fit as a
control variate, not as a replacement BRDF. The analytic LTC and broad cosine
integrals are corrected by the complete current BRDF minus those distributions.
Area, visible-GGX and cosine proposals use 16 samples each. Broad directional
energy matching reduces residual variance. The mesh and shading horizons are
clipped independently for the analytic polygon.

Layered or anisotropic Realtime evaluates the existing full BRDF with area,
cosine, substrate visible-GGX and, when needed, coat visible-GGX MIS proposals,
32 samples per proposal. Partial coat coverage uses a bare/substrate mixture.
Current material filtering, anisotropic frames, independent coat normals,
absorption, thin-film quality and layer transmission are reused unchanged.
Reference quality uses 128 samples per proposal without LTC. Numerical tests
also use a separate 2048-sample-per-proposal GPU integration and an independent
163840-direction float64 CPU reference.

Finite deterministic sampling is an approximation. Rect intersection changes
can produce low-sample motion error; very large/close lights, mirror limits,
strong anisotropy and critical thin film need measured convergence. Quality
tiers change sample precision, not material parameter meanings. A passing
Editor fixture is not general production or live-game GPU performance approval.

The LTC source is pinned in `Tests/prepare_area_lut.py`; redistribution license
and paper attribution are retained in `ThirdParty/LTC-LICENSE.txt`.

## Host color profile and packaging

Actual KKS inspection records Linear / D3D11 with lightsUseLinearIntensity=false.
The modern adapter now explicitly targets `KKSLinear-v1`, independent of the
Gamma author's `UNITY_COLORSPACE_GAMMA`. The earlier adapter incorrectly used
that compile-time macro to infer the player's sampling/output space: saved
player floats showed emission 0.25 becoming 0.537099. That old package remains
rejected; a Gamma-built bundle with the corrected adapter is not the same case.

- Auto color textures/uniforms and evaluated Probe/SH follow the KKS Linear
  convention; explicit sRGB mode still decodes once. Alpha is never decoded.
- Correct scalar/normal data stays raw. Explicit data-restore controls undo an
  unwanted sRGB sampling conversion regardless of the build project's setting.
- Probe RGBM uses the Linear exponent and runtime HDR decode instructions, not
  UnityCG's Gamma compile-time shortcut. Native float HDR ignores alpha through
  its runtime decode instructions. Native SH polynomial evaluation stays linear.
- Base/Add, emission and fog output linear scene values. The removed legacy
  `_TomBSDFLinearOutput` override has no effect on modern production shaders.
  No plugin is required to select the correct basic color path.
- No per-material tonemapping, display LUT or artistic grading is introduced.
  The game's existing exposure/postprocess/display pipeline remains responsible.

Build normally in the current main Gamma project. `buildbsdfstage4` restores the
explicit bundle/reference build without changing project settings. It is an
expensive full-variant build and is never part of the bounded color tests.
The hidden stage-3 reference preserves BRDF math but uses the corrected color
adapters, not the old Gamma appearance. Receipts distinguish build color space
from target color space and require `KKSLinear-v1` plus exact tested hashes.
The old isolated LinearBuildBridge is historical, not a required packaging step.

Explicit Bridge commands `renderbsdfcolor` and `bundlebsdfcolor` exercise only
the small shared production color helpers and their bundle roundtrip. The
separate `smokebsdfcolor` renders the two complete modern shaders. These checks
do not claim actual KKS/ME player or interactive save/import acceptance.

## Runtime and validation

Source is in `Tools/TomBSDFRuntime`, matching the existing probe runtime layout.
The same runtime DLL is imported for authoring and deployed beside
`KKS_TomBSDF.dll`. The plugin has no hard dependency on TomShadersX or TomProbe.
Native reflection probes and Tom SH remain compatible, with no texture/property
block replacement by the scene service.

The local diagnostic file bridge is disabled by default. When explicitly
enabled, it accepts only `inspect`, `hostbaseline`, and `acceptance` under
`UserData/TomBSDF/Validation/Inbox`. Commands are claimed before execution and
never automatically retried after a crash. Tests use disposable isolated
geometry and restore modified global/light state. No existing character or
scene files are overwritten. Actual ME registry/API checks are player-only;
the shared Editor harness labels them as not exercised.

Host frame intervals, valid player GPU FrameTiming values, and isolated
CPU+GPU+readback completion latency are distinct measurements. Unsupported GPU
timing is reported as unavailable, never filled using zero/CPU timings.
