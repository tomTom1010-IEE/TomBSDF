# SceneBuffer-v1 Validation (2026-10-16)

Scope: KKS Unity 2019.4.9f1, Built-in Forward / D3D11, current Gamma authoring
project with controlled linear float targets. All Editor operations used Codex
Bridge. No computer use, full bundle build, game deployment or KK adaptation.

## Result

Final explicit command `20261016-bsdf-buffers-015-render` passes **168 checks**.
Saved: **65 capture PNGs, 62 RGBA float buffers, two material comparison sheets**
and numerical/contract metadata. Two sheets were visually inspected, together
with the asymmetric color consumer and Cutout depth images.

Evidence root (directory timestamp is UTC):

`CodexBridge/Reports/BSDF-Stage4/SceneBuffers/Render-20261015-173920-410`

- `report.json`: assertions and capture measurements.
- `buffers.json`: contract, material cases and on/off errors.
- `artifact-pins.json`: current source/runtime/resource hashes.
- `BSDF-buffer-comparison-comparison.png` and
  `BSDFCutout-buffer-comparison-comparison.png`: six material rows, columns are
  no companion / buffers active / extension disabled / RGB difference times 16.
- `capture-transparent-color-consumer.png`, `capture-opaque-color-buffer.png`,
  `depth-orthographic.png`, `depth-perspective.png`, `depth-cutout-holes.png`,
  `msaa4-sloped-raw-depth.png` and associated raw buffers: interface evidence.

Rows: red plastic, gold, anisotropic aluminum, absorbing coat on red plastic,
dielectric thin film and metallic thin film. All twelve material cases actually
render lit subjects. On/off/no-companion image MAE is **exactly zero**. The two
sheets are identical with complete Cutout coverage, which is expected; clipping
is tested independently using the depth holes.

## Coverage and Measurements

- No consumers: no capture commands/textures or automatic service bootstrap.
- Color-only, depth-only, combined, Full/Half and multiple-consumer demand.
- Linear HDR preserved: asymmetric copy contains blue **2.458984375**. Image
  MAE versus the full-float source is **6.4262e-5**, consistent with half storage.
- The transparent consumer reads the opaque copy, not itself. Camera depth
  attachment restoration preserves later transparent depth testing.
- Orthographic/perspective eye depth at the known 3-unit plane normalizes to
  **0.1999999881 / 0.1999999434** for far=15. Moving geometry changes depth;
  alpha-cut holes expose far depth, not the nearer transparent consumer.
- Skybox included; color MAE **1.5597e-4** versus the full-float frame.
- MSAA 4x resolves to single-sample color/depth. Known flat plane returns
  **2.9999997616** units; sloped depth vertical-alignment error is at most
  **2.6227e-6** units at the two asymmetric probe positions.
- Half-resolution depth preserves plane/far values; maximum eye-depth error
  **2.3842e-7** in the flat-geometry fixture. This is not conservative Hi-Z.
- Separate/nested cameras, a camera without demand, restored parent globals,
  resizing, lost targets, destroyed cameras and last-lease cleanup.
- Master/buffer disable, missing/incompatible resource, unknown protocol and
  reserved SSR capability fail closed; supported state recovers when restored.
- Native Base/Add lights, native Probe/SH and a genuinely selected rectangle
  coexist without image change: MAE **0**.

Source build: runtime and companion compile with **zero warnings/errors**; the
imported Editor DLL exactly matches that build. Hidden copy and consumer HLSL
compile/render successfully. Static checks pass **27 buffer**, **184 scene**
regression groups and **33 color-contract** checks. The scene regression also
checks frozen material mathematics, public inputs, prototypes and existing LUTs.
Manifest, both modern shader entries, production Forward include and project
settings retain their pre-request SHA256 hashes. No original material/prefab was
modified; the one internal buffer resource was created/bound through Unity APIs.

## Repairs Made During Validation

The final result supersedes intermediate failed attempts; those reports remain
as an audit trail, not passing evidence.

- AfterSkybox did not publish in the no-skybox fixture; BeforeForwardAlpha is
  the tested capture point. CPU snapshots now require actual current-camera
  command publication, not merely a scheduled command.
- A named RT identifier was not a reliable alias for the global depth texture;
  an explicit depth-sampling shader with a versioned retained resource replaces
  it. No unreferenced Shader.Find/stripping assumption remains.
- A test assertion assumed a 256-pixel capture for a 128-pixel second camera;
  it now uses the actual capture center.
- This host rejects direct RFloat ReadPixels usage. Final readbacks sample
  into RGBAFloat staging and use AsyncGPUReadback; the unsupported request is
  absent from the final run. No startup GPU jobs or crash retries were added.

## Not Claimed

This is controlled Editor acceptance, not actual-player ME/save-import or GPU
frame-time acceptance. Existing unrelated AssetBundleBrowser GUID conflicts and
historical shader warnings are not repaired by this feature. The final explicit
render command has no new error log entries; the Editor remains responsive.

The internal resource's dependency/label is checked in the main project, but no
distribution or resource-bundle roundtrip was built this round. The installed
game still needs a future matched runtime/companion/bundle update. No new white
furnace/OpenPBR integration was necessary: material math is unchanged.

SSR, normals/history, modern Alpha, refraction/absorption/thickness rendering,
transparent scene layers, stereo/dynamic-resolution/subviewport/oblique support,
full packaging and KK remain outside this completed infrastructure scope.

See [contract and consumer API](SceneBuffers-Contract.md).
