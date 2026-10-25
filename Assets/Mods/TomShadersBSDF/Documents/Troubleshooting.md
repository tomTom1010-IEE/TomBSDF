# Troubleshooting

## Missing Shader Or Magenta Material

Install the zipmod once and confirm Sideloader / ME loaded it. Select the intended
modern `tom/` entry. Missing shader-owned energy LUTs are a real error, not an
optional-plugin fallback. For source, pull LFS and keep native assets / metadata;
never substitute user maps or regenerate GUIDs to hide broken resource bindings.

## Companion Missing Or Wrong Version

Install Companion 0.6.0 and its matching Runtime together. Back up older duplicates
outside every plugin folder. Check `BepInEx/LogOutput.log`; Windows FileVersion
is not the feature version. Core colors / physical shading, POM and Glints work
without the plugin; rectangle / refraction / transparent-map services do not.
Missing CPU bounds management can still cause Tess culling.

## Unexpected Color Or Normals

Do not change game color space or use the old Linear-build project. Keep input
Auto unless actual encoding is known. Data restoration corrects a specific sRGB
sampling mismatch, not overall quality. Normal encoding is 0 UnityPacked,
1 RGB, 2 AG, separately for main / detail / coat. A red preview alone does not
establish packing. DetailNormalMapScale defaults to zero.

## Dark Metal Or Ineffective AO

Probe / SH controls need actual environment data; sliders do not create GI.
AO attenuates indirect light and Probe reflection, not all direct lights or
emission. A dark metal without useful light / reflection is expected. Optional
Probe capture also needs valid bounds, completed jobs and enabled runtime quality.

## Missing Point Or Transparent Shadows

First verify the same native light shadows an opaque control. Four-array lights
have no independent shadow maps. Transparent reuse additionally needs companion,
native maps / matrices and budget. It does not generate missing maps, promote
lights, change Queue or force ZWrite. Casting and receiving are separate controls.
Rectangles are unshadowed; Glass has no ShadowCaster.

## Glass Does Not Refract A Particular Object

Use BSDFGlass, keep intact Coverage=1, enable UseSceneRefraction and Scene Buffers,
and test a visible opaque background. Straight-on parallel plates can have little
offset. Invalid / occluded / offscreen samples retain unshifted transmission;
screen edges must not smear. Other transparent layers, hidden geometry, nested
media and offscreen objects are outside the opaque snapshot. This is not an
exact rough BTDF / caustic / colored-shadow renderer.

## Alpha Sorting Or Unexpected Transparency

Coverage is MainTex A * AlphaMask R * Coverage, not BaseColor A. AlphaClip=0
permits gradients. Back/Front and optional depth strategies trade specific layer
visibility; they are not OIT. Glass transmission is not ordinary opacity fading.
Check exposure / bloom / sharpening with a neutral test before diagnosing fringes.

## Height Has No Silhouette Or Shows Cracks

POM changes shading UV only. Tess changes real geometry. Height is white-envelope /
inward-black in meters; zero scale bypasses it. White height or black displacement
mask preserves position. Use suitable subdivision / mip and continuous seam data.
More tessellation cannot reconcile inconsistent UV heights / vertex normals.
Bounds require a service or authoring; picking, collision and old DepthNormals
replacement are not automatically displaced.

## Slow Captures Or Reference Sticks

Only a supported capture lifecycle / matching camera promotes rectangle quality.
Temporary keywords must restore and ME floats must stay unchanged. Manually
selected Reference stays expensive in live view. Film + multiple lights + area
Reference and full-resolution layered glass are costly. Keep diagnostic File
Bridge off. High-resolution memory peaks and continuous leaks are different issues.

## Shader Compiler Internal Error

RC1 has complete audited programs, not a proven fix for every Unity FXC cold
build failure. Preserve logs / successful cache and follow
[Delivery Workflow](Delivery-Build-Workflow.md). Do not repeatedly clear cache,
strip variants, reduce sampling or splice bytecode. Known duplicate AssetBundle
Browser package GUID diagnostics are template issues, not a waiver for new
shader errors. A stalled worker alone does not establish hardware causation.

## Bug Reports

Include shader and package / companion versions, KKS host / graphics API,
relevant plugins, exact parameters / texture encodings, reproduction steps,
expected / actual images and whether restart / save / reload / import changes it.
For performance, include resolution, visible area, lights, postprocessing and
measurement method. Attach the relevant log interval, not the entire game or
Library. Remove tokens, personal paths and private user content before sharing.
