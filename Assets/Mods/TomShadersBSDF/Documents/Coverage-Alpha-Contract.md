# Modern Coverage Alpha (KKS)

## Scope

`tom/BSDFAlpha` and `tom/BSDFAlphaBackFront` extend the modern physical core;
they do not replace frozen `xukmi/TomBSDFAlpha`. Native GGX/Smith, EON,
anisotropy, probes/SH, AO, detail normals, AA, coat and film use the same
material and light evaluation as `tom/BSDF`. The KKSLinear-v1 input adapter
still works independently of the companion plugin. No glass, refraction,
GrabPass or SSR implementation is included. No KK adaptation is included.

## Coverage, Not Glass

```
c = saturate(MainTex.a * restored(AlphaMask.r) * Coverage)
rgb = complete_lit_surface_rgb * c
alpha = c
```

All reflected lobes, emission and fog belong to the covered fraction, including
metal, coat and film highlights. There is no preserved-specular fade mode.
`BaseColor.a` does not control coverage. Both texture slots have independent
scale/offset. DataTextureRestore applies to the mask red channel, not MainTex
alpha. Empty slots are white and Coverage defaults to 1.

When a tool uses `Material.CopyPropertiesFromMaterial` from an Opaque material,
initialize the destination's extra coverage inputs explicitly. That API copies
the source property sheet, not a semantic shader conversion: the source has no
AlphaMask/Coverage contract and can clear them to null/zero. The matched-input
tests set a white mask, Coverage and AlphaClip after such copies. Fresh and
Standard-to-Alpha shader-switched material defaults are audited separately.

ForwardBase uses `Blend One OneMinusSrcAlpha, One OneMinusSrcAlpha`. Each
ForwardAdd uses `Blend One One, Zero One`, RGB-only writes and zero source
alpha. Direct extra lights are premultiplied too, but do not attenuate the
background or accumulate coverage again. Fog is applied before premultiplication;
additional-light fog tends to black, as in the opaque core.

This models fractional surface presence, useful for fades, fine coverage and
soft masks. It does not model light traveling through a solid dielectric.
Future glass is a separate material entry with its own optical transmission,
absorption, thickness and optional scene-buffer consumers. Lowering Coverage
is not an IOR/thickness/refraction control. Coat absorption only concerns the
existing reflected layered material; it does not sample the background.

## Color, Depth And Shadows Are Separate Policies

| Property | Default | Meaning |
| --- | --- | --- |
| Coverage | 1 | Uniform multiplier on both coverage texture sources |
| AlphaClip | 0 | Enable optional visible hard clipping with Cutoff |
| Cutoff | 0.5 | Visible cutoff only when AlphaClip is enabled |
| AlphaDepthMode | 0 | 0 Off, 1 NearestSurface, 2 BackShell |
| AlphaDepthCutoff | 0.95 | Minimum coverage contributing to optional depth |
| AlphaShadowMode | 2 | 0 Off, 1 Cutout, 2 Dither |
| AlphaShadowCutoff | 0.5 | Shadow threshold for Cutout mode only |

Color passes never write depth. Zero coverage is discarded before resource,
material or lighting evaluation; it writes neither color, optional depth nor
shadows, even with zero cutoff settings. AlphaClip applies consistently in all
three policies. The depth and shadow thresholds do not quantize color coverage.

The optional depth-only pass runs before color:

- Off is ordinary transparency and the default. No depth texture is acquired.
- NearestSurface writes the nearest qualifying surface. The ordinary entry
  respects CullOption; the BackFront entry includes both faces. This removes
  deeper transparent layers at covered pixels, deliberately trading accumulated
  transparency for simpler self-occlusion and reduced shaded overdraw.
- BackShell writes only back-facing qualifying surfaces. It can retain the
  nearest back shell and nearer front faces while rejecting deeper sheets.
  The nearest back face is not guaranteed to be the outer boundary of a concave
  or intersecting mesh. Open sheets may have no usable back-facing shell.

Depth cutoff defaults high, so a half-covered surface does not silently become
an opaque depth blocker. Users can lower it deliberately. Any depth-writing
strategy can hide subsequently drawn transparent renderers. It is not OIT,
per-pixel sorting, or a promise that the object appears in every camera depth,
DOF or depth-normal buffer. It is not the future glass thickness representation.

ShadowCaster reuses the native vertex/bias/cube-depth path. Cutout mode is binary;
Dither uses a fixed 4x4 ordered threshold in shadow-map raster space, shared by
directional, spot and cube shadows, with no extra noise texture. This estimates
fractional visibility; it is not a colored or refracted shadow. Pattern grain,
shadow-map motion and soft-shadow filtering remain resolution-dependent.

### Shadow Receiving Boundary

Casting is implemented; transparent shadow receiving is a different capability.
Unity 2019 Built-in does not provide the opaque native receiver path to the
Transparent queue. Merely retaining full-shadow shader variants cannot supply
missing native scheduling/bindings. The receiving capability audit uses an
opaque positive control and same-scene Standard Transparent negative control
for directional, point and spot lights, saving explicit supported/unsupported
records in `shadow-receiver-capabilities.json`. Unsupported is not a passed
shadow-receiving feature. If the native control receives shadows but TomBSDF
does not, the audit fails rather than classifying it as an engine boundary.

These entries keep the proper transparent queue; they do not pretend to be
opaque objects to obtain shadows at the expense of transparency order.
The subsequent 2026-10-17 Native Shadow Receivers v1 extension supplies
camera/light-scoped native map reuse through companion 0.4.0. It samples the
transparent fragment's own position and keeps coverage, emission, SH and Probe
independent. No queue spoofing or forced depth workaround is used. Missing
native maps, resources or companion retain the earlier native transparent path;
the original capability audit remains evidence for that no-service baseline.
See [ShadowReceiving-Contract.md](ShadowReceiving-Contract.md) and its separate
validation record for actual receiving support and availability limits.

## Back/Front Self-Overlap Variant

The ordinary entry has one ForwardBase/ForwardAdd group with CullOption
defaulting to Back. Cull Off renders both sides in mesh triangle order.

BackFront instead uses fixed groups in this order:

1. Optional AlphaDepth.
2. Back-facing ForwardBase and all of its additional lights (Cull Front).
3. Front-facing ForwardBase and all of its additional lights (Cull Back).
4. A separate native ShadowCaster (not part of the camera color sequence).

Each face still uses the original two-sided normal/tangent handling. CullOption
is deliberately not exposed on the fixed variant. For a simple closed shell,
the back surface is composited before the front, without doubling the opaque
depth state or adding per-material screen captures. It does not sort multiple
back faces among themselves, intersecting triangles or different objects.
Its color draw count is twice the ordinary entry for the same pixel-light
assignment. Both entries also submit a small depth-only draw; Off discards all
of its fragments, rather than removing the draw through a float property.
This is not a measured GPU-time ratio:
coverage, rejection, layers and light count determine the actual cost. Alpha
still pays the existing physical core/film cost for each shaded covered layer.

## Assets And Property Contract

The version-7 `Foundation-Properties.json` drives shader properties, manifest
and tooltip catalogs. Common material properties retain their defaults and
semantics. Only AlphaMask/Coverage/Cutoff applicability expands from Cutout to
coverage entries; five new controls have Alpha-only scope.

Carrier names are `m_BSDFAlpha` / `a_BSDFAlpha` and
`m_BSDFAlphaBackFront` / `a_BSDFAlphaBackFront`. Both use
`chara/tom/shaders/tombsdf.unity3d`. Creation/binding uses `preparebsdfalpha`
through Codex Bridge and Unity APIs, including the four existing shader-owned
tables. Native assets and metadata are never hand-authored. This preparation
does not build or deploy an AssetBundle.

`compilebsdfalpha` explicitly compiles every pass type with representative
directional/probe, point/spot shadow and fog variants. `renderbsdfalpha` uses
real camera Forward scheduling into linear floating-point targets. Reports and
comparison PNGs are saved in `CodexBridge/Reports/BSDF-Alpha`. Tests do not run
on startup. A compile/render run is not an exhaustive distribution build,
actual ME save/load acceptance or live-game GPU performance acceptance.

## References

- [Unity 2019.4 ShaderLab blending](https://docs.unity3d.com/2019.4/Documentation/Manual/SL-Blend.html)
- [Unity 2019.4 Forward rendering](https://docs.unity3d.com/2019.4/Documentation/Manual/RenderTech-ForwardRendering.html)
- [Unity 2019.4 shadow troubleshooting](https://docs.unity3d.com/2019.4/Documentation/Manual/ShadowPerformance.html)
- [OpenPBR model](https://academysoftwarefoundation.github.io/OpenPBR/)
