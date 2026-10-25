# Native Shadow Receivers v1

This extension completes direct-light shadow reception for the modern geometric
coverage materials `tom/BSDFAlpha` and `tom/BSDFAlphaBackFront`. It does not add
glass transmission, colored shadows, rectangle-light shadows or screen-space
reflection. The native transparent fallback remains available independently.

## Resource Acquisition

The companion records command buffers on its selected lights at
`LightEvent.AfterShadowMap`. It copies the native raw shadow depth, without
rendering any shadow casters again or replacing the engine's shadow textures.
`SetShadowSamplingMode(RawDepth)` is scoped by Unity to the command buffer.
Directional/spot maps use an RFloat 2D copy; point depth cubes are copied to a
3-by-2 face atlas. No queue, light, shadow bias, camera depth or project shadow
setting is changed.

The map event stores the native spot caster VP, point depth projection, native
texture dimensions and light identity. Directional matrices, split spheres,
radii and split planes become current at `BeforeScreenspaceMask`, not reliably
at `AfterShadowMap` when cameras change. A tiny per-slot depth-generation stamp
couples that late metadata to the same camera's actual map copy. These are GPU uniforms,
not CPU guesses read from `Shader.GetGlobalMatrix`. A private 40-by-8 RGBAFloat
metadata table pairs the matrices with the copies. Camera sequence markers
invalidate stale data if Unity does not execute a shadow-map event.

Spot projection is obtained from the actual caster VP, not a guessed CPU
projection: X is `(VP.row0 + VP.row3)/2`, Y is `(-VP.row1 + VP.row3)/2` for D3D
top-left texture coordinates, and depth/W keep the native GPU rows. The regular
`unity_WorldToShadow` can still describe a different light during the spot event.
The shader performs the homogeneous divide at the actual fragment position.

Acquisition was diagnosed independently before connecting the physical shader.
Initial static-camera renders made the two directional matrix events appear
equivalent. Nested-camera regression exposed the stale early matrices; the
late-event plus depth-stamp fix is required, not optional. Perspective 1/2/4 cascade
and orthographic maps were inspected; orthographic native rendering uses a
single cascade even when a multi-cascade quality setting is selected.

The companion requires a versioned `TomBSDFNativeShadowsV1.asset` dependency
created and assigned to the existing BSDF bundle through Bridge/AssetDatabase.
It resolves that asset from already loaded bundles, not a hidden `Shader.Find`
assumption and not an independent zipmod loader. Native resource absence is an
unshadowed/native-transparent fallback, not a magenta material error.

## Sampling And Light Isolation

Only the Alpha compile path includes the receiver adapter. After Unity computes
its usual attenuation, a valid matching native light can replace its realtime
visibility while keeping that light's cookie and distance attenuation. The
physical GGX, coat, thin-film, energy, normal/AA and environment code is shared
and unchanged. Base and Add, including both BackFront face groups, use the same
entry point.

Directional/spot projection uses the transparent fragment's own world position.
Directional cascade selection supports native stable-fit spheres and close-fit
eye-depth split planes. Native shadow strength, distance fading and reversed-Z
are retained. Point receivers use the native dominant-axis depth projection
and bias, with face selection in direction space.

The initial 2D soft filter is a four-tap PCF approximation; it is not a claim
of bitwise parity with Unity's hardware-comparison tent kernel. Point filtering
uses the native four direction offsets and can cross cube faces without mixing
unrelated atlas tiles. This is native-resolution shadow-map reuse, not PCSS,
contact-hardening or physically sized area-light shadows.

Light identity uses native position/direction and type. Native event light
colors can describe a previous light and are retained for diagnostics only,
not matching. CPU selection rejects coincident active position/type keys,
including non-shadow-casting lights; the shader also rejects multiple matching
packets. These conservative ambiguous cases retain the previous attenuation
rather than selecting another light's shadow. The
extension does not promote vertex/four-array lights to pixel lights. Unity must
actually schedule a native map for a light to have reusable visibility.

Visibility is passed only into `TomUnityCurrentLight`. It is not multiplied
onto the final color, coverage, emission, SH, Probe or rectangle contribution.
The material remains ordinary premultiplied coverage, not preserved-specular
glass. Coverage shadow CASTING settings remain independent of RECEIVING.

## Demand, Lifetime And Limits

Only visible modern Alpha receivers cause allocation. The extension uses a
bounded cache of eight cameras, up to eight native shadow lights per camera, with a configurable
128-MiB copy budget by default. Directional lights sort first, then local lights
by camera distance and stable instance ID. Unselected, over-budget or unavailable
maps keep the original native transparent appearance. Copies do not silently
downsample a map exceeding the allocated native-resolution capacity.

The companion discovers materials and publishes a capture scope before culling:
native shadow events can occur before `onPreRender`. One stable owned command
per light contains camera-target draws selected by a private GPU owner guard.
Nested cameras maintain separate copies and metadata, then restore capture and
consumer bindings; they do not remove/re-add the enclosing native light hook.
Owned hooks detach after the outermost camera. Commands are never removed
wholesale from another plugin.
The owner token is a small cache-local integer, not a potentially imprecise
large Unity instance ID in a GPU float. Post-render, disable, destroy,
allocation failure and aborted-render cleanup
must release/restore owned state. `Renderer.receiveShadows=false` is honored
through scoped private property-block flags, preserving existing blocks.

Supported host: Unity 2019.4 Built-in Forward, D3D11, raw shadow depth sampling,
non-XR camera rendering. Preview/unsupported cameras fail closed. This iteration
does not implement baked lightmap/shadowmask material support or native light
shadow rendering when Unity did not schedule it. In the isolated Alpha-only
fixture Unity does not schedule native maps without an opaque native receiver.
Those cases use the declared missing-resource fallback, NOT successful shadow
receiving. Acceptance uses an ordinary visible opaque backdrop as a native-map
positive control; the companion never creates a runtime proxy object.
Copy and sampling work have
a cost; no live KKS GPU timing or large-scene performance acceptance is implied.

## Switches And Delivery

Companion 0.4.0 adds `Alpha Shadows / Receive Native Shadows` and the copy memory
budget. The scene-extension master switch also gates acquisition. No material
property, ME schema, manifest identity or author-controlled shader value is
added or rewritten for this resource extension. Existing area-quality/capture
and scene-buffer protocols remain separate.

An older/missing companion, missing resource, disabled extension, skipped map
event or unsupported host preserves the previous native material path. Opaque,
Cutout and frozen `xukmi/TomBSDF*` are not consumers. A future distribution build
must deliver the resource asset plus its shader dependency and matching runtime;
this work does not request a full distribution build or game deployment.

Acceptance evidence, including any remaining restrictions, belongs in
`ShadowReceiving-Validation.md`; an acquisition probe alone is not rendering
acceptance.
