# Height-v1 / POM-v2 Local Visibility

KKS Unity 2019.4 / D3D11, modern Opaque and Cutout only. Adds optional local
visibility without changing the accepted camera intersection, sample budgets,
BRDF, layered energy, anisotropy, film, area integration or native shadow maps.
No companion change, bundle build, deployment or KK adaptation is required.

## Parameters And Neutral Path

- ParallaxSelfShadow defaults to 0, a uniform float/ToggleUI, not a keyword.
- ParallaxSelfShadowStrength defaults to 1, range 0..1. Zero bypasses light rays.
- ParallaxSelfShadowBias defaults to 1, range 0..4. Dimensionless multiplier of
  a meter bias derived from effective relief and original height UV footprint.
- Quality follows ParallaxQuality. Realtime uses 8..16 light samples, Reference
  24..48, increasing toward oblique lighting. Both retain the existing complete
  camera search. Screenshot promotion still applies to area integration only.
- Disabled/zero strength, POM off, zero height, an invalid metric or faded-out
  relief returns local visibility 1. White mesh-envelope defaults need no trace.
  Constant nonwhite height is a recessed plane and must not shadow itself.

## Shared Height Context

TomHeightContext is separate from physical material/layer data. It retains the
camera hit UV/depth, effective meter height, original SampleGrad derivatives,
smooth unperturbed normal, inverse UV/world metric and virtual hit position.
Effective height includes distance, view grazing, mip and camera excursion
limits. Visibility amplitude fades with those guards too; flattened relief
cannot leave an unrelated cavity shadow. Material hit derivatives remain
unchanged. No implicit derivatives occur inside the light loop.

The light ray starts at the virtual view hit and compares its inward depth with
the same decoded height field. A footprint-based clearance smoothstep suppresses
self-intersection and filters the crossing. This is not physical light-size
penumbra filtering and not temporal stochastic sampling. Reference remains a
finite higher-budget approximation that can miss narrow relief, not ground truth.

Directional sources have constant direction; point/spot/four-array sources use
the actual finite world light position and stop no later than that endpoint.
Trace also ends upon reaching the height envelope. The reliable local model
fades between light-normal cosines 0.02..0.08, and between full light-ray UV
excursions 1..2 in HeightMap UV units. It fails open outside the neighborhood,
without rescaling the height field separately for each lamp. Source degeneracy
also fails open. Native shadows and existing geometric horizon limits remain.

## Direct Light And Layers

One achromatic height visibility multiplies each native lamp's attenuation
exactly once before the bare/covered split. ForwardBase/each ForwardAdd uses its
own source; both bare and layered four-light loops apply the same query per
active lamp. Black/zero native light contributions skip the query. No light is
removed by its index or a global shared light budget.

Unity owns light allocation, not this float switch. Four-array support means
all four valid slots supplied by Unity, not a promise that four requested
ForceVertex lights plus arbitrary pixel lights are all published. A measured
directional/spot coexistence case can supply three nonzero slot colors, or four
with the last RGB attenuated below the Inspector intensity; the independent
pre-change source has the same allocation. Equal-priority lamp ties can also
change selection between culls. The fixture uses distinct intensities,
reads position/color/attenuation on the GPU with the production pass/data
requirements retained, and compares the unchanged active-light set and actual
published RGB gains before disabling lamps for the isolated native reference.
This is a white-lamp, linear-input controlled test. It does not hide omissions
by loosening the linear-superposition tolerance or altering shader light counts.

Coat, substrate, partial coat coverage and thin film describe a common conformal
height surface. Independent coat normals, anisotropy and specular AA still shape
their original lobes; they do not rotate the height metric or visibility ray.
Beer absorption and film Fresnel are not another geometric visibility factor.
Height does not simulate a coat filling grooves, separate top/bottom geometry,
colored height transmission or transport of light bouncing inside the relief.

SH, Probe/IBL, AO, emission and area lights never receive this visibility.
Rectangle self-shadow requires per-integration-direction visibility in a later
task; no center-point approximation is installed. Native BRDF light direction,
distance attenuation, cookies and shadow sampling retain real mesh positions;
the virtual hit is used only for local visibility. Very near lights therefore
retain the documented mesh-lighting approximation.

## Coverage And Cost

Original Cutout coverage and ShadowCaster are byte-unchanged. No alpha remap,
SV_Depth, geometry, new pass, queue/ZWrite change or new shadow producer. This is
a continuous solid height-field model, not mask-aware ray traversal through
alpha holes. Atlas islands require padding; texture wrap/filter are the existing
HeightMap sampler. It cannot cast relief onto other objects or change silhouettes.

New height fetches scale with covered fragments, native draw/light count and
active four-array lights. Each native pass still repeats the camera search.
Coat/film do not multiply the number of visibility rays. Off preserves appearance
but does not guarantee zero compiled instruction/register/compile-time overhead.
Performance evidence must distinguish interleaved camera completion latency from
pure GPU timestamps and live game frame times.

## Explicit Validation Commands

Commands are claimed before native/GPU work and never replayed after a crash:
compilebsdfpomshadow (name, keywords, passIndex), renderbsdfpomshadow (name:
regression/analytic/lights/fallback/layers/coverage/motion/area), timebsdfpomshadow
(reverseOrder). Evidence and the independent pre-change source oracle are under
CodexBridge/Reports/BSDF-POMSelfShadow. The reference step-field test uses a dense
independent CPU intersection rather than accepting Reference as exact truth.
