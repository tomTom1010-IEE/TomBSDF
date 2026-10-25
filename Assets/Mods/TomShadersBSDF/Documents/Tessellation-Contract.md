# Tess-v1: Tessellation And Real Displacement

## Scope

- Independent `tom/BSDFTess` and `tom/BSDFCutoutTess`, D3D11 / shader model 5,
  KKS Unity 2019.4.9f1 Built-in Forward. Ordinary BSDF entries do not acquire a
  hull/domain stage or any geometry amplification.
- Reuse the complete current physical core: compensated GGX, anisotropy, detail
  normals, specular AA, coat, absorption, film, Glints, native lamps, SH, probes
  and optional rectangle quality variants. Tess is geometry, not another BRDF.
- Alpha/BackFront/Glass tessellation, screen-space tessellation LOD, PN-triangle
  silhouette smoothing and a custom DepthNormals replacement are not in v1.
- No KK port, game deployment or automatic full distribution build.

## Height And Coverage

Height-v1 remains linear R with independent ST/filter/wrap, optional material
data restoration, then `h = 1-h` when reversed. The original mesh is the WHITE
envelope. World displacement is `normalize(worldNormal) * (h-1) * HeightScale
* DisplacementMask * edgeFade`. HeightScale is clamped to [0, 0.2] meters at the
geometry boundary, independent of nonuniform, negative and parent transforms.
No signed outward displacement or object-space depth interpretation is added.

Zero HeightScale returns original vertices/normal/tangent, bypasses all geometry
texture fetches and sets every tessellation factor to 1. The SM5 Tess entry still
has a hull/domain pipeline; use the ordinary shader to remove that fixed cost.
White height or black displacement mask preserves the original frame and
position; those cases can still subdivide when HeightScale is nonzero.

Cutout samples MainTex/AlphaMask/Coverage/Cutoff at ORIGINAL UV, using the same
coverage helper in Forward and ShadowCaster. Height moves the covered geometry,
not the alpha pattern relative to the mesh. DisplacementMask is NOT AlphaMask.
POM controls are not exposed or compiled in Tess entries. The same height layer
cannot simultaneously receive POM, POM local self-shadow and actual displacement.
Native shadow maps supply visibility for real displaced geometry; four-array
fallback lights still have no native shadow maps of their own.

## Geometry And Pass Contract

`Platform/Unity2019/TomBSDFTessellation.cginc` owns control points, shared-edge
factors, the hull shader, height/mask sampling, position/frame reconstruction.
Forward and Shadow wrappers call exactly this evaluator before the existing
vertex adapters. All lighting positions, lamp distances, fog, Probe lookup and
fragment derivatives use the displaced position. No physical lobe is rewritten.

Subdivision is fractional-odd, factor [1,63]. Edge factors depend ONLY on their
two original transformed endpoints and shared material settings. Fixed mode
uses TessFactor. WorldEdge mode uses world edge length / TessEdgeLength, capped
by TessMaxFactor. Inside uses the maximum of the three edge factors. There is
no camera/light-dependent culling, distance fade, automatic mip or screen LOD.
The original VS VERTEXLIGHT_ON decision is explicitly carried through HS/DS:
Unity's domain program must not guess it from a vertex-only variant keyword.

ForwardBase, ForwardAdd and ShadowCaster all carry VS/HS/DS/PS. Built-in Forward
also uses ShadowCaster for `_CameraDepthTexture`, so camera depth sees the same
geometry and raw coverage. Merely adding an unused `DepthOnly` pass would NOT
integrate Built-in depth. `_CameraDepthNormalsTexture` is a separate legacy
replacement-shader path; it ignores these custom stages. No claim of matching
DepthNormals, motion vectors, collision, raycasts or CPU picking is made.

## Filtering And Frames

DisplacementMip is explicit and uniform across passes/cameras. Height and mask
use their own SampleLevel sampler and clamp to available mip range. The domain
evaluator takes five height and five mask samples (center and centered U/V
differences), except zero-depth early return. Gradients include each texture's
ST, data restoration and height reverse. No implicit pixel derivative appears
in HS/DS. Coarse geometry cannot reproduce details below its tessellated edges:
author/filter a suitable mip and use normal/detail maps for remaining detail.

The world-space metric reconstructs the normal from displacement derivatives,
including the derivative of the interpolated normalized smooth normal. The UV
tangent and handedness are rebuilt from the displaced derivatives. Degenerate
UVs fall back to a projected source tangent/stable axis; degenerate geometric
metrics retain a finite smooth normal. Smooth vertex normal transport is an
offset-surface approximation, not exact high-order subdivision geometry.
The existing normal/detail/coat frames, anisotropy and AA consume the result;
fragment geometric normals still come from displaced triangle derivatives.
Use the normal/detail maps for residual detail. Encoding the entire height
gradient again in those maps can double the apparent slope; geometry-derived
normals are already present even when NormalMap is neutral.

## Cracks And Mesh Authoring

Symmetric edge factors prevent tessellation T-junctions for shared endpoints
and identical material settings. They cannot make different UV heights or
different vertex normals represent the same displaced edge. Across UV/normal
seams, overlapping islands, submesh/material boundaries or detached vertices:

1. Author matching height/normal/depth/ST/mip/settings on both sides, OR paint
   the independent DisplacementMask to black with a smooth fade at those seams.
2. Optional DisplacementEdgeFade pins EVERY original triangle edge. It also
   protects incompatible seams, but can produce visible triangle-shaped grooves.
   Default 0 preserves continuous relief; it is an explicit fallback, not a
   free seamless reconstruction or automatic seam detector.
3. Shared-edge rules do not weld detached meshes or repair non-manifold input.
   No PN smoothing is applied to original hard edges or silhouettes.

## Culling And Skinning

GPU displacement does not expand Unity 2019 CPU bounds. Companion 0.6.0 adds
`TomBSDFTessellationBounds`, prepared before camera/light culling even when the
optional scene-light extension is off. It reads ME material switches/depth on
each camera, keeps source assets untouched and restores on zero depth, shader
switch, hidden renderer or service disposal.

- MeshRenderer: private transient HideAndDontSave mesh copy; only its bounds
  change, source mesh/collider/material assets do not. Each renderer can have
  a different depth/transform. Procedural code that mutates the original mesh
  in-place must explicitly reassign its mesh or provide its own bounds policy;
  this is not an automatic streaming-mesh synchronization service.
- SkinnedMeshRenderer: expand localBounds without cloning the skin mesh or
  changing bones/blendshapes. Existing animation/body-plugin bounds updates
  are rebased rather than cumulatively expanded or silently restored over.
- Unity 2019 `updateWhenOffscreen=true` otherwise recomputes and replaces that
  AABB, including when queried. Suspend this flag only inside the camera/cull
  scope, then restore it after the outer camera or on abort/disposal. Visible
  skinning still executes; ordinary offscreen updates resume outside the scope.
  Root-bone/render local-frame padding is conservatively combined.
- Expansion in each local axis is HeightScale times that row length of
  worldToLocal. This contains any unit-normal world displacement under inverse
  scaling and shear. It is conservative for this inward-only material.
- No companion: geometry/lighting still work, but authors must expand mesh or
  skinned bounds themselves. The shader cannot guarantee frustum/shadow culling
  at an edge of unexpanded bounds. Singular (zero) object scale is unsupported.
- Already precombined static batches are not cloned or patched: their ranges
  and per-renderer culling metadata are not an ordinary MeshFilter bounds
  override. Unbatch them before applying this material or author matching bounds.
  The service reports UnsupportedStaticRenderers rather than mutating the
  shared combined geometry. New carrier prefabs are not static batches.

Nonzero depth with a white map or black mask can still retriangulate the mesh.
Expect subpixel raster/interpolant and AA/Glints differences, not bitwise image
identity with the coarse original. Zero HeightScale has a strict bypass and is
the appearance-compatibility control. Validation isolates geometry/frame error,
coverage edge ownership and smooth versus statistical reflection separately.

## Public Parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| HeightMap | white | Height-v1 linear R |
| HeightScale | 0 | Maximum inward world meters |
| IsHeightReverse | 0 | Invert decoded height before geometry |
| DisplacementMask | white | Independent linear R, pins seams at zero |
| TessellationMode | 1 | 0 Fixed, 1 WorldEdge |
| TessFactor | 4 | Fixed factor [1,63] |
| TessEdgeLength | 0.05 | Target original edge length, meters |
| TessMaxFactor | 16 | Amplification cap [1,63] |
| DisplacementMip | 0 | Explicit shared mip, clamped per map |
| DisplacementEdgeFade | 0 | Optional per-source-triangle edge pinning |

Manifest uses `Height / Tessellation`; tooltips explain no-plugin culling and
seam limits. Shader-owned integration textures and a_BSDFTess/a_BSDFCutoutTess
carrier materials/prefabs are created/bound only through Codex Bridge.

## Validation And Delivery

`Tests/tessellation_reference.py` checks independent differential geometry,
world-meter/culling metrics, shared-edge symmetry, public scope and actual
preprocessed HLSL token parity for the old Forward families. Explicit Bridge
operations are prepare/compile/render/time + `bsdftess`; each produces saved
source hashes and results below `CodexBridge/Reports/BSDF-Tess`.

Selected-pass compilation/rendering is NOT a complete native-program audit.
New Hull/Domain stages and both carriers are part of the next full candidate's
submission identity contract. Counts follow that submission, not the previous
1042-program snapshot. Retain the existing sealed complete pre-Tess baseline;
do not package a new manifest alongside an old bundle. The controlled
incremental delivery policy still applies to a separately authorized full build.
