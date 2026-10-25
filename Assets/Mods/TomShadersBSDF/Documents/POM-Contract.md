# Height-v1 / POM-v2

## Scope

Stage 5 first iteration, KKS Unity 2019.4 / D3D11 only. `tom/BSDF` and
`tom/BSDFCutout` accept optional UV-only POM. Coverage Alpha, Back/Front, Glass
and the frozen xukmi prototypes expose no POM controls. POM-v2 optionally adds
native-light local self-shadow rays; see POM-SelfShadow-Contract.md. There is no
area-light self-shadow, Glints, vertex/tessellation displacement, SSR, bundle
build or KK port. The original POM-v1 acceptance remains historical evidence.

## Height Data

- `_HeightMap` reads linear red, applies the accepted `_DataTextureRestore`
  adapter if explicitly requested, saturates, then optionally performs `1-h`.
- White is the mesh envelope; black is `_HeightScale` world meters below it.
  The default white texture is flat at the mesh. A constant nonwhite height is
  a uniformly recessed plane, not an automatic zero-relief texture.
- `_IsHeightReverse` reverses height, not alpha or masks. No implicit derivation
  of normals: use a matching normal map, retaining all current normal encodings.
  Reversing height does not automatically invert a supplied normal map; its
  authored slopes must agree with the chosen height interpretation.
- World-meter scale uses the local raw-UV/world-position Jacobian projected
  onto the unperturbed smooth-normal plane. Mirrored UVs and nonuniform object
  scale are part of that metric. Degenerate UV/metric falls back to flat sampling.
- Height has its own ST and sampler, including wrap/filter; it does not silently
  inherit RoughnessMap wrap. Atlas islands still require padding: the shader has
  no island-boundary data and cannot prevent sampling another atlas region.
- This contract is separate from coat millimeters and optical glass thickness.
  A future displacement adapter can share decoding, units and reference plane.

## Coordinates And Filtering

`TomSurfaceCoordinates` separates `originalUV` from shaded `uv`, stores the
resolved pixel footprint, and reserves a meter hit depth without publishing it
as actual geometry. The normal/tangent reconstruction retains `originalUV`.

Trace from the mesh envelope along the camera ray. Use an angle-adaptive bounded
linear scan to find the first detected sign-changing segment, followed by
bracketed interpolated refinements. Finite samples can miss very narrow relief;
Reference is not mathematical ground truth and height fields cannot overhang.

Every height lookup uses original UV derivatives with explicit SampleGrad. After
the trace reconverges, finite screen differences of the hit coordinates supply
the material gradients. Disocclusion jumps are bounded to 16 times the original
footprint. This is a documented stable approximation, not exact ray differentials.
No implicit derivatives are evaluated inside the variable-step trace.

The common raw UV offset precedes each texture's own ST: main RGB, main/detail
normals, separate material maps/ORM, anisotropy strength/rotation, emission and
all coat/film maps. Existing BRDF, layer transport, AA and indirect-light models
are unchanged. Height does not rotate the anisotropy frame or perturb its own
view ray using normal maps.

## Quality And Neutral Path

- `_ParallaxMode=0` or `_HeightScale=0` bypasses height reads and retains the
  old implicit material sampling. These cases must match the preserved source.
- Realtime: 12-32 scan steps, 2 refinements and one initial read (at most 35).
- Reference: 32-96 scan steps, 5 refinements and one initial read (at most 102).
- Both are uniform material branches, not new shader keywords. ME floats work
  without the companion; this iteration does not auto-promote screenshot quality.
- Distance fade uses `_ParallaxFadeStart/End` in meters (defaults 15/25).
  A reversed interval becomes a short positive interval. Grazing-angle fade
  defaults to cosine 0.15. Coarse height mips fade before the final mip levels.
- `_ParallaxMaxOffset` defaults to 0.25 HeightMap UV units. It scales the full
  ray's effective depth continuously, rather than clipping only the final UV.
- Base and each ForwardAdd trace the same camera ray independently. Cost grows
  with pixel coverage and native per-pixel light count; it is not a one-time
  cached operation. Off still retains the compiled module; neutral appearance
  does not promise zero instruction/register or compile-time overhead.

## Coverage, Depth And Shadows

Cutout always computes MainTex alpha, AlphaMask, Coverage and cutoff from
`originalUV`. Its ShadowCaster remains unchanged. Consequently the texture's
RGB may parallax independently of its coverage edge: provide padded opaque
interiors, not displaced alpha holes. This preserves the visible/caster mask
contract without introducing light-dependent camera-UV shadows.

No vertex change, SV_Depth, queue change or extra depth pass. Native depth,
silhouette, light attenuation positions, fog, probe positions and scene shadows
remain on the real mesh. Camera-ray self-occlusion is distinct from the optional
POM-v2 lighting self-shadow. No height visibility multiplies SH, Probe, emission
or final RGB.

## Validation

Explicit claimed Codex Bridge commands only:

- `compilebsdfpom`: `name=BSDF|BSDFCutout`, native keywords and passIndex.
- `renderbsdfpom`: `name=regression|geometry|materials|area|coverage|motion`.
- `timebsdfpom`: paired interleaved measurements; `reverseOrder` reverses order.

The pre-change source lives outside Assets in
`CodexBridge/Reports/BSDF-POM/Before-20261018`. It is expanded as a transient
oracle shader by the Bridge, not rebuilt into a distribution. Results include
linear float comparisons and identically display-mapped PNGs. Camera completion
timings include CPU/driver/readback overhead, not pure GPU shader timestamps or
live KKS frame time. Acceptance results are recorded separately after execution.
