# SceneBuffer-v1 (KKS / Unity 2019)

Scope: on-demand color/depth infrastructure. This does not implement glass,
modern Alpha, SSR, normals, motion/history buffers or a Deferred renderer.
Current BSDF/BSDFCutout material properties, manifest, BRDF and color adapter
are unchanged. No additional material/prefab carrier is needed.

## Ownership and Demand

The existing optional companion owns `TomBSDFSceneService.Buffers`. A consumer
acquires an explicit per-camera `TomSceneBufferLease` for Color, Depth, or both,
at Full or Half resolution. Acquire before the camera's pre-cull callback, not
while an object is being drawn. Dispose when that consumer is disabled or no
longer needs the resources; change requests between camera renders.

```csharp
var request = TomBSDFSceneService.AcquireSceneBuffers(camera,
    TomSceneBufferFlags.Color | TomSceneBufferFlags.Depth);
// Keep the lease while the future effect is active; Dispose on disable.
```

This API does not call EnsureInstance or render a camera. Without the companion
it returns an inactive lease. Consumers must handle that state and reacquire if
the service is subsequently created. Multiple consumers share one camera copy;
the union of flags and highest requested resolution wins. No demand means no
capture command or buffer allocation. Last release, destruction, disable,
resolution change and lost targets have explicit cleanup/recreation paths.

The existing `Scene Lighting/Enabled` config is the master extension switch.
`Scene Buffers/Enabled` independently permits requests; default true does not
capture anything by itself. Switches are applied before the next camera render.
Component disable/disposal invalidates old leases; reacquire after re-enabling.

## Production and Formats

- Supported: Unity 2019 Built-in Forward / D3D11, full-viewport, non-stereo Game
  cameras. SceneView is not automatically enrolled; any camera needs a lease.
- Capture at **BeforeForwardAlpha**, after opaque/skybox rendering, before
  transparent geometry. It also works when no skybox is assigned. Opaque image
  effects scheduled earlier are already present; final display grading must be
  later for the color to retain the required linear scene meaning.
- Color: linear `ARGBHalf`, no mip/history, bilinear sampling, clamp addressing.
  Includes the rendered sky, excludes subsequently rendered transparent objects.
  Half storage does not restore HDR already clipped by an LDR source camera.
- Depth: point-sampled `RFloat`, raw device Z from `_CameraDepthTexture`, not
  eye depth or an alpha/height mask. The consumer helper linearizes perspective
  or orthographic projections and handles reversed Z without cancellation.
- Depth requests are installed at pre-cull. Native depth modes are preserved;
  only this service's added Depth bit is restored when flags have not changed.
  Unity has no per-owner reference counter: another plugin adding exactly that
  same bit during our render is not distinguishable. Consumers should coordinate
  camera depth ownership instead of toggling shared flags during a render.
- Depth contents follow Unity's producer, generally opaque/cutout ShadowCaster
  coverage. Transparent ZWrite alone does not guarantee inclusion. This is not
  a complete scene representation, thickness buffer or hidden/back-face depth.
- Full and Half color/depth are tested; half depth selects existing surface/far
  values rather than averaging distinct surfaces. It is not a conservative Hi-Z
  pyramid. MSAA capture resolves color to a single-sample texture and uses
  Unity's generated sampleable depth; 4x D3D11 is covered by Editor checks.
- Camera color/depth attachments are restored after copying. Existing native
  lights, shadows, Probe, SH and area-light contributions are not replaced.

The actual KKS host is Linear. The Gamma authoring project needs an explicitly
linear offscreen target for this contract. Ordinary Gamma backbuffer capture,
stereo, array/dynamic-resolution targets, sub-viewports, reflection/preview
cameras and oblique clipping planes currently fail closed with `Status(camera)`.

## Consumer Interface

`Shaders/Platform/Unity2019/TomBSDFSceneBuffers.cginc` is an optional include,
not included in the opaque physical core. Use ComputeScreenPos-derived UVs for
the current camera. Out-of-bounds UVs, missing capabilities and unknown protocol
return false; the caller keeps its existing non-screen-space path.

- `_TomBSDFBufferParams`: protocol=1, capability bits, camera ID, render sequence.
- `_TomBSDFBufferSize`: width, height, reciprocal width/height.
- `_TomBSDFBufferProjection`: near, far, orthographic, reversed-Z.
- `_TomBSDFBufferInverseProjection`: inverse GPU projection into a texture.
- `_TomBSDFBufferCameraToWorld`: camera-to-world matrix.
- `_TomBSDFSceneColor`, `_TomBSDFSceneDepth`: the requested copies only.
- `TomTrySceneColor(uv, out color)` and `TomTrySceneEyeDepth(uv, out depth)`
  provide the initial glass/refraction data interface. No IOR, absorption,
  transmission, ray tracing or color contribution is implemented here.

The depth helper uses a point `Texture2D.Load` without another sampler slot.
Color has one linear-clamp sampler; a future consumer may define
`TOM_SCENE_COLOR_SAMPLER` as a compatible shared SamplerState before including
the library. This keeps a sampler-sharing route open for the full material's
D3D11 limit; the existing material input samplers are not refactored this round.

Globals are unavailable before capture and after the camera ends. Nested cameras
save/restore enclosing publication, including cameras with no demand. The CPU
`TryGetSnapshot` API exposes the last completed camera submission, not CPU-ready
memory or a promise that an old frame is current. GPU reads retain normal command
ordering; CPU pixel access needs an explicit readback/fence. The render sequence
and captured matrices travel with the snapshot;
resources are owned by the lease/service, not the caller. Reacquire snapshots
after rendering, resizing or request changes; do not retain old texture handles.

Normals (bit 4) and screen reflections (bit 8) are reserved and explicitly
unsupported. Requests are rejected and GPU availability returns false. There
are no SSR textures, dispatches, history, filters, material/manifest properties
or indirect reflection contributions. Future SSR must compose with Probe rather
than double-add it and must define its own scheduling/material-data contract.

## Resource Delivery

The explicit `preparebsdfbuffers` Bridge command creates/binds
`ResourcesData/TomBSDFSceneBuffersV1.asset` using Unity APIs. It retains the
hidden depth-copy shader and is labeled for the existing TomBSDF bundle. The
normal main-project builder collects that label, including the copy dependency.
No hidden Shader.Find reference is trusted to survive stripping. The companion
resolves this versioned asset only from already loaded bundles; it never opens
or deploys zipmods/bundles itself. Missing/incompatible depth resources make a
depth-requiring capture unavailable; a color-only request needs no copy shader.

The authoring and companion runtime DLLs must match. The source build and main
Editor copy are updated together; this request does not build or deploy the full
shader bundle or change the currently installed game package.

## Cost and Boundaries

Full-size color+depth storage is 12 bytes/pixel: about 23.7 MiB at 1920x1080 per
requested camera, excluding Unity's own depth, copies/bandwidth and driver costs.
Half resolution uses one quarter of that storage. There is no allocation or
extra scene copy when no effect requests it, but this is not a live-game GPU
frame-time guarantee. No current opaque material requires the service.

The initial color is an opaque scene snapshot, not another transparent layer.
Future glass needs a deliberate opaque-source/multiple-transparent-layer policy;
lowering Alpha alone and reading this buffer cannot implement nested glass,
offscreen refraction, thickness, caustics or physical transmission shadows.

See [validation](SceneBuffers-Validation.md) for saved evidence and limitations.
