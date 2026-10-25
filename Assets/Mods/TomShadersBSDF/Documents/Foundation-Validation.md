# Foundation Validation - 2026-10-08

## Scope

The approved first implementation batch is complete: versioned inputs and
color contracts, physical core, opaque/cutout entries, and native multi-light
shadows. These are stages 0 and 1 of the zero-indexed architecture proposal.
Only the independent KKS TomShadersBSDF project was developed. No KK port,
prototype replacement, game installation, release publication, or runtime
render-pipeline plugin is part of this milestone.

## Environment

- Unity 2019.4.9f1, Built-in Forward, D3D11, RTX 4070 Ti SUPER.
- Gamma project; lightsUseLinearIntensity=false.
- Explicit temporary Editor scene, HDR ARGBFloat target, no MSAA.
- Reference output: linear; native Gamma output is tested separately.
- AsyncGPUReadback RGBAFloat; no Texture2D.ReadPixels.
- Fixed PNG display transform: x/(1+x), then sRGB. No per-image normalization.
- Commands claimed before execution; no startup render or automatic crash retry.

Reports are under the Unity project root's
`CodexBridge/Reports/BSDF-Foundation`. Render directory timestamps use UTC.

## Results

| Validation | Result |
| --- | --- |
| Static contract, XML, shader/manifest/default/tooltip agreement and preservation | 270 checks passed |
| CPU quadrature and physical-model invariants | 6 checks passed |
| Core HLSL vs independent CPU evaluations | 288 input cases, maximum relative error 1.744e-5 |
| Full Editor render suite | 122 checks passed, 72 captures |
| Built/loaded AssetBundle render suite | 34 checks passed, 14 captures |
| Frozen prototypes/assets/KK baseline | 66 hashes unchanged |

Numerical results in `Data/numerical-report.json`:

| Invariant | Maximum error | Threshold |
| --- | --- | --- |
| DFG against independent higher-sample integration | 0.001600 | 0.003 |
| EON white furnace | 0.0001984 | 0.001 |
| EON reciprocity | 2.22e-16 | 1e-12 |
| EON roughness-zero Lambert boundary | 0 | 1e-12 |
| Compensated GGX, F=1 white furnace | 0.002767 | 0.005 |
| LUT non-finite/negative values | 0 | 0 |

Integral resource: 65x65, 16384 visible-normal samples per node, RGBAFloat,
linear, bilinear, clamp, no mips. SHA256 of the generated reference data:
`930feee8eec9bc52608e3755cd251b25e1ea5cfb8f82c0352516b26b3d84e274`.

Final full render report: `Render-20261007-164342/report.json`.
Final bundle report: `BundleSmoke/report.json` (captures in
`Render-20261007-164411`). The smoke bundle is outside the game installation.

## Covered Behavior

- Scalar-only materials, white maps, explicit sRGB decoding, ORM channels.
- Neutral Unity/RGB/AG normals, known slopes, Y flip, mirrored transforms,
  backfaces, and derivative reconstruction of missing tangents.
- Directional, point and spot lights; front/back geometric horizon limits.
- Linear-target Base/Add sum; light intensity ratios; emission added once.
- Four-light fallback, coexistence with per-pixel Add, no stale removed lights.
- Real hard/soft directional, point and spot shadows, with shared cutout caster.
- Point, spot and additional directional cookies attenuate once.
- Eye-depth fog, black Add fog, SH input and indirect-only diffuse AO.
- Plastic/EON/metal roughness scans, basic white-probe energy response.
- Missing integral marker: magenta Base, zero Add; valid resource restores output.

Packaged shaders were loaded as distinct shader objects and assigned to both
fresh materials and existing Standard materials. Source and packaged renders
matched with zero measured mean RGB difference, including point/spot Add.
Tests also assert a valid LUT contract and a non-diagnostic reference image;
two matching missing-resource images cannot pass the build check.

## Resource Delivery Findings

Ordinary ShaderImporter.SetDefaultTextures passed Editor material checks but
did not survive the initial packaged shader reassignment test. Delivery now
uses SetNonModifiableTextures and NonModifiableTextureData. A duplicate ordinary
default entry, even null, overrides the binding and must be absent.

The resource is hidden from ME and the default Material Inspector. It is not
script-immutable: Material.SetTexture can override or clear it. The suite tests
that corruption is diagnosed and restoration of the actual reference recovers
the image. No global texture service or runtime companion is required.

## Remaining Boundaries

- Editor and bundle tests are not live KKS/ME acceptance or persistence tests.
  A representative in-game scene still needs camera/HDR/postprocess calibration.
- Native Gamma pass accumulation is not linear. Per-pass sRGB encoding cannot
  solve this host limitation; the controlled linear reference is separate.
- Basic single-probe IBL is present. Dual probes, box projection, advanced
  specular occlusion, detail normals, specular AA and anisotropy are later work.
- Clear coat, thin film, alpha blending, optical transmission and screen-space
  effects are not implemented in the new entries. Old prototypes remain usable.
- Conservative dielectric substrate coupling is not full OpenPBR layering.
- Custom cutout is shared by these visible/caster passes, not automatically by
  Unity's built-in replacement DepthNormals shader or every postprocess buffer.
- Full shadows require Unity's per-pixel light allocation and shadow resources;
  non-pixel fallback lights remain unshadowed.
- Known unrelated AssetBundle Browser duplicate-GUID warnings still occur in
  this template. They were not modified by this work.

## Reproduction

1. Run `Tests/foundation_math.py --output <project>/CodexBridge/Reports/BSDF-Foundation/Data`
   with Python and NumPy.
2. If code changed externally, submit `refresh` through Codex Bridge and wait
   for compilation before submitting the next command.
3. Submit `preparebsdffoundation`, then `renderbsdffoundation`, then
   `buildbsdffoundation` as separate explicit Bridge JSON commands, checking
   each result in Outbox before proceeding.
4. Run `Tests/validate_contract.ps1` for XML/property and preservation checks.

Unity-created assets are `ResourcesData/TomBSDFEnergyV1.asset`,
`Material/m_BSDF.mat`, `Prefab/a_BSDF.prefab`, `Material/m_BSDFCutout.mat`,
and `Prefab/a_BSDFCutout.prefab`, plus their Editor-generated metadata.
The carrier bundle is `chara/tom/shaders/tombsdf.unity3d`.
