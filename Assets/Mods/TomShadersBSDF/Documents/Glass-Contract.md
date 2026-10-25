# Finite Glass v1 (KKS / Unity 2019)

Independent entry: `tom/BSDFGlass`. This is optical transmission, not another
coverage-Alpha mode. Existing BSDF/BSDFCutout/Alpha/BackFront and frozen xukmi
shader sources remain unchanged. Scope is an air/glass/air locally parallel slab,
supplied thickness, RGB absorption, native-light/Probe reflection and optional
bounded screen refraction. It is not an exact GGX BTDF or a solid lens solver.

## Material And Energy

Reflection reuses the accepted compensated isotropic/anisotropic GGX, normal
decoders (Unity packed, RGB and AG), tangent handedness, detail normal, specular
AA, Probe projection/blending, AO and native Base/Add lighting. The same filtered
roughness/frame drives the transmission filter. Glass is a dielectric: no metal,
painted diffuse, coat or thin-film controls are exposed in this first entry.
Combining those layers with a transmissive substrate needs a separate budget;
their existing opaque/Alpha implementation is not removed or changed.

`MainTex.rgb * BaseColor.rgb * GlassAbsorptionColor.rgb`, decoded through the
existing color-input contract, is a transmission reference color at
`GlassAbsorptionDistance` meters. White is clear. Thickness is
`GlassThickness * GlassThicknessMap.r` in world meters, independent of object
scale. The refracted inside path is thickness divided by its normal cosine.
Beer-Lambert absorption uses that path, not coverage or final-pixel alpha.

With interface directional reflectance F from the accepted GGX energy table
and one-way RGB absorption A, the incoherent internal-return closure is:

```
T = (1-F)^2 * A / (1-F^2*A^2)
R = F + (1-F)^2 * F*A^2 / (1-F^2*A^2)
```

The existing front reflection shape is scaled by R/F; extra internal return
shares that lobe as an approximation. White lossless slabs have R+T=1, absorbing
slabs have R+T<=1. IOR=1 removes interface reflection and screen bending. This
does not implement phase-coherent interference between the two interfaces,
microfacet exit-normal integration, polarization or spectral dispersion.

`Coverage` remains geometric presence, multiplied by MainTex A and AlphaMask R.
Keep it at 1 for intact glass: Fresnel and absorption provide optical transparency.
Emission is independent of R/T, but follows coverage. There is no SH-painted body
diffuse and no AO darkening of transmitted scene color. AO/horizon affect Probe
reflection only; native shadows attenuate their corresponding direct reflection.

## Framebuffer Composition

Native camera scheduling runs three pass types, with no transparent depth write:

1. `GlassTransmission` attenuates the existing framebuffer in RGB, independently
   of alpha. This is `Blend Zero SrcColor`, with ordinary coverage-over alpha.
2. `ForwardBase` adds reflection, emission and any valid refracted scene color.
3. Each `ForwardAdd` adds only its associated native light reflection. It never
   applies background attenuation or transmission a second time.

For coverage c, valid refraction weight w and opaque scene sample S:

```
C = ((1-c) + c*T*(1-w))*currentFramebuffer + c*(surfaceReflection + emission + T*w*S)
```

Missing resources, disabled refraction or rejected screen data make w=0. The
same RGB absorption and surface reflection remain on the unshifted framebuffer;
no scalar-opacity approximation, magenta resource failure or invented environment
background is necessary. Fog applies to the new surface light; an already fogged
scene sample is not fogged again. A foreground-fog correction prevents absorption
from tinting the fog between the camera and the glass.

The two stages are transmission/reflection composition, **not** the coverage
BackFront variant. Default back culling renders one local slab for a visible
closed surface. Cull Off can show a two-sided sheet, but does not model a stack
of nested glass volumes. Transparent intersection/order remains Unity's regular
limitation. The opaque snapshot excludes other transparent surfaces: earlier
transparent content is preserved only by the unshifted fraction of the composite,
not traced/refracted as another volume. No OIT guarantee is made.

## Scene Data And Failure Boundaries

The companion 0.5.0 discovers visible `tom/BSDFGlass` materials opting into
`UseSceneRefraction` before camera culling. It leases existing SceneBuffer-v1
color+depth at Full/Half resolution; the highest visible request wins. Eight
camera entries are cached at most; active enclosing cameras are not evicted.
No requesting material means no automatic lease. Material clones, shader switches
and ME float edits are read before each camera, without saved keywords/components.
External explicit leases still share the same underlying camera buffers.

The existing BeforeForwardAlpha copy contains opaque/cutout depth and scene color
including sky, not hidden/back-face depth or other transparent materials. Refracted
inside direction and supplied thickness determine an exit position. Parallel-slab
exit direction equals the incident direction. Two bounded background-depth-plane
refinements locate a sample, not a general ray marcher or SSR implementation.
Foreground/inside-thickness depth, discontinuous depth, offscreen projection and
unsupported host/camera data fall back to unshifted transmission. Edge fade blends
back smoothly; out-of-bounds UVs are never clamped into stretched edge colors.

Rough transmission uses a positive normalized center-plus-eight ellipse filter,
based on filtered anisotropic GGX axes, IOR and distance to the visible background.
Foreground/discontinuous taps use the valid center. This is a finite cheap screen
approximation, not a measured ground-truth rough BTDF, mip-chain/Hi-Z filter,
offscreen reconstruction or arbitrary hidden-object intersection.

Native directional/spot/point receiving reuses the current optional map adapter.
Unavailable native maps retain its existing fallback; no map is generated on
demand. Glass has no ShadowCaster: no opaque/dithered substitute is presented as
physical transmission shadows. No caustics, nested media, camera-inside-medium
tracking, colored shadows, SSR, extra shadow cameras or automatic thickness pass.

## Delivery And Validation

Manifest: `tom/BSDFGlass` -> `a_BSDFGlass` in
`chara/tom/shaders/tombsdf.unity3d`. Material: `m_BSDFGlass`. The explicit
`preparebsdfglass` Bridge operation creates/binds them and the existing energy,
anisotropic-energy and rectangle-LTC dependencies through Unity APIs.
`Glass-Properties.json` plus the selected common properties generate shader/ME
declarations and per-property help with `Tests/sync_glass_contract.ps1`.

The KKSLinear-v1 color adapter remains independent of Gamma authoring macros.
No current bundle/game deployment or KK port is implied. Explicit native compile,
energy, image and lifetime evidence belongs in `Glass-Validation.md`, not this
feature contract. Compiler wall time is not GPU frame time.

Parameter references: [Khronos volume](https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_materials_volume/README.md)
and [Filament materials](https://google.github.io/filament/Materials.md.html).
The slab closure and framebuffer fallback above are this implementation's
documented approximations, not a claim of numerical OpenPBR equivalence.
