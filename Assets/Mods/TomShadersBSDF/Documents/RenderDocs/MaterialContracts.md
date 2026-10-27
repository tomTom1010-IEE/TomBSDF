# TomBSDF Material Contracts

These contracts apply to modern `tom/BSDF*`, not automatically to the three legacy xukmi entries.
Use current manifest/property spelling and the [Material Guide](../Material-Guide.md).

## Maps And Input Routes

| Input | Channel/combination |
| --- | --- |
| MainTex / BaseColor | Decoded RGB multiplied; white permits color-only authoring |
| MetallicMap / Metallic | Linear R times scalar |
| RoughnessMap / Roughness | Linear R times perceptual roughness scalar |
| OcclusionMap / Occlusion | Linear R times scalar, blended by OcclusionStrength; white unoccluded |
| ORMMap with UseORM | R AO, G roughness, B metallic; replaces the separate-map branch |
| NormalMap / NormalMapDetail | Base and RNM detail tangent normals; each has encoding/scale/restore/flip |
| EmissionMask | RGB times decoded emission color and intensity |
| AlphaMask | R contributes to raw-UV geometric coverage where supported |
| HeightMap | Linear R Height-v1, not a normal and not a coverage mask |

Do not import TomX MaterialMap RGBA as BSDF ORM. Scalar values multiply assigned maps; their
availability is not permission to ignore active ORM mode. Shader-supplied defaults and carrier
resources are different from runtime `new Material(shader)` bindings; verify after a shader switch.

ColorTextureMode/ColorValueMode: 0 follows the KKS Linear input convention, 1 explicitly decodes
sRGB, 2 accepts linear. DataTextureRestore reverses an unwanted sRGB decode on data only. Normal
restore controls are independent. Neither is a general brightness or quality control.

NormalEncoding enums are 0 UnityPacked, 1 RGB, 2 AG. Choose by **sampled representation after import**.
ME can convert a blue source PNG in NormalMap/NormalMapDetail into packed data. Do not select RGB
only because that PNG was blue. Independent CoatNormalMap may not share ME's conversion route;
verify it separately. UnityPacked uses Unity UnpackNormal and ignores NormalDataRestore. Explicit
AG restoration touches RGB/G, not alpha, so restoring already-correct AG can tilt the result.
Use a neutral-map calibration through the actual slot before artistic compensation.

## Layers And Units

| Input | Unit or contract |
| --- | --- |
| AnisotropyRotation | Degrees in the tangent frame; mirror handedness matters |
| HeightScale / TessEdgeLength | World metres |
| GlassThickness / GlassAbsorptionDistance | World metres |
| CoatThickness / CoatAbsorptionDistance | Millimetres |
| ThinFilmThickness | Nanometres |
| GlintDensity | Log10 expected microstructures per original UV area |

Anisotropy changes GGX shape, not the existence of scratches. Zero strength selects the isotropic
path. Independent coat normals/roughness separate a wet layer from its coarse substrate. Weight
zero ignores coat/film controls and returns the accepted corrected bare-material baseline.
Film Realtime is optimized; Reference is the retained expensive comparison path. RGB/conductor
and rough-layer approximations are documented, not exact spectral OpenPBR equivalence.

Glints have fixed UV/seed structure and pixel-footprint filtering. They redistribute native-direct
substrate single scattering beneath the coat. Opaque/Cutout and their Tess entries support them;
Alpha/BackFront/Glass, Probe/SH and rectangles retain smooth paths. Zero weight or a black mask
selects smooth GGX. A noisy still is not proof of motion stability or per-realization energy conservation.

## Coverage Is Not Transmission

```text
coverage = saturate(MainTex.a * decoded AlphaMask.r * Coverage)
```

BaseColor.a is not coverage. Cutout uses raw UV and cutoff; Alpha premultiplies full surface
reflection, emission and fog. BackFront orders suitable shell layers, not arbitrary intersections.
AlphaClip, AlphaDepthMode and AlphaShadowMode are independent decisions. Casting is not receiving.
Avoid forcing ZWrite as a universal fix.

For intact glass, keep Coverage=1 and use IOR, physical thickness and absorption to tune optical
transmission. Lowering ordinary Alpha is not glass. Glass consumes available opaque scene buffers,
not arbitrary transparent/offscreen content, and falls back to unshifted transmission plus reflection
when data is invalid. It has no caster, caustics, colored projection or nested-medium stack.

## Height And Real Geometry

Height-v1: decode data R, clamp, optionally reverse; **white is the mesh envelope and black is
maximum inward depth**. Start with a shallow world-metre scale and a matching normal. Height
reversal does not automatically reverse normal slopes. Uniform gray is a recessed plane, not white.

POM is ordinary Opaque/Cutout only. Its shaded UV offset feeds supported maps, but original-UV
coverage and native depth remain geometric. Self-shadow rays are separate from native shadow maps.
Reference POM is higher sampling, not a mathematically exact solver. Each Add Pass repeats work.

Tess uses Fixed/WorldEdge factors, explicit height mip, an independent displacement mask and optional
edge pinning. It does not run same-layer POM. Do not copy TomX's midpoint/screen-edge settings into
this contract. Zero height restores vertices and frame, not absence of HS/DS overhead. UV seams,
CPU bounds, skinned deformation, colliders and DepthNormals replacement need separate treatment.

## Parameter Triage

- Missing indirect light: inspect actual SH/Probe and masks; AO/intensity cannot create scene GI.
- Plastic/road looks metallic: verify metallic branch/map, excessive coat and reflection lighting.
- Flat surface has broad directional shading: neutral-normal and data-encoding tests first.
- Roughness map appears inactive: check UseORM and scalar multiplier before changing lighting.
- Coat/film has no effect: verify coat weight/mask, mandatory LUT binding, metal F0 and feature scope.
- Refraction absent: distinguish buffer/service availability, rejected rays and intentionally safe fallback.
- POM/caster mismatch: POM depth is shading-only; verify original coverage rather than changing Queue.

No modern MatCap, toon ramp or legacy reverse-ShadowColor branch exists here. Adding those by
copying V+ code is a feature change, not a documentation correction or neutral material adjustment.
