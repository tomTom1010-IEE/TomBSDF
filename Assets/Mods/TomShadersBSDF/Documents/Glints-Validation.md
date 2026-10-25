# Glints Implementation And Validation

Status: **G0/G1/G2/G3 Editor, mathematical, timing and audited-delivery gates pass.**
The new Glints bundle replaces the pre-change delivery only after controlled
repair and clean confirmation. Live KKS/ME and production GPU profiling remain
separate acceptance. Evidence below is relative
to the Unity project root under `CodexBridge/Reports/BSDF-Glints`.

## Mathematical Reference

| Check | Evidence | Result |
| --- | --- | --- |
| Independent CPU PMF, explicit-binomial samples, count quadrature, fractional/rare tails and anisotropic GGX bound | `G0-20261023-A/report.json` | 242 checks pass |
| Production GPU count against independent moment integration | `GPUCount-20261023-144838-907/analysis.json` | 48 cases, 32768 samples each pass; confidence accounts for unobserved sparse tails |
| Complete smooth BRDF reference | `FurnaceReference-20261023/reference.json` | 65536 independent MIS directions per case; six white materials integrate to 0.99976..1.00019 |
| Production complete BRDF, Reference film | `Render-20261023-184246-514` | Six cases, 1024 fixed-UV material seeds, 4096 rays each; 30 checks pass |
| Production complete BRDF, Realtime film | `Render-20261023-184251-907` | Three covered cases, 1024 seeds, 4096 rays each; 15 checks pass |

The complete layered test includes white dielectric, mixed metal/anisotropy,
bare metal, coated metal, rough coat and film-covered metal. It compares both
the smooth target against the independent CPU integral and the Glints ensemble
against that target. The maximum absolute added RGB energy deviation including
three standard errors is 0.004083 for Reference and 0.002645 for Realtime,
inside the predeclared 0.01 bound. Schema2 `furnace.json` stores every seed's
integrated RGB in flattened `realizationsRGB` triplets, plus means and standard
errors. An explicit disk-JSON roundtrip check passes for all nine rows, and
external recomputation from saved samples matches the stored means. The earlier
refined runs retained correct aggregate values but omitted nested per-seed arrays;
the repaired export and repeated integrations above supersede that logging gap.
An individual random realization is not required to equal the ensemble.
This is six representative full-BRDF cases, not an exhaustive
parameter proof. Both refined reports stamp the final production shader sources.

The independent references are in `Tests/glints_reference.py` and
`Tests/prepare_glints_furnace.py`; test-only `GlintsCount.compute` and
`GlintsBRDFProbe.shader` exercise production floating-point evaluation. Exact PMF,
high-sample integration and spectral Reference tests are not shipping features.

The Reference quality realization distribution below uses mean RGB energy per
fixed-UV material seed, not per-pixel highlight intensity. The percentile indices
are `floor(p * (1024 - 1))`; complete RGB values remain available in the JSON.

| White material | Minimum | P01 | Median | P99 | Maximum |
| --- | --- | --- | --- | --- | --- |
| Dielectric | 0.998159 | 0.998767 | 1.000010 | 1.001285 | 1.001985 |
| Mixed metal / anisotropy | 0.984090 | 0.990103 | 1.000160 | 1.011337 | 1.014670 |
| Bare metal | 0.876001 | 0.912504 | 0.997914 | 1.102904 | 1.169627 |
| Coated metal | 0.941840 | 0.961384 | 1.000163 | 1.039258 | 1.047970 |
| Rough coat | 0.998727 | 0.999126 | 1.000156 | 1.001054 | 1.001367 |
| Film-covered metal | 0.965124 | 0.978454 | 1.000078 | 1.023518 | 1.032801 |

In particular, individual bare-metal realizations can exceed unit white-furnace
energy by about17%. This statistical NDF model is not a strictly normalized
per-realization physical BRDF. Do not conceal that limitation with a final RGB
clamp or present the passing ensemble bound as a per-material guarantee.
`furnace-realization-summary.json` links both qualities to their source reports.

## Source And Isolation

`Tests/validate_glints.ps1` passes 133 checks: five matching properties only on
modern Opaque/Cutout, manifest/tooltip/contract consistency, original physical
core and other shader families unchanged, unchanged native pragma inventory,
and an independent pre-change source archive. The archive includes the original
48 production sources, manifest and complete bundle in `Before-20261023`.
The shipping source set is now 51 shader/include files.

Eighteen artifact-auditor unit tests also pass. They do not replace auditing the
actual new bundle. The native submission callback now covers every BSDF-owned
shader, not just five modern entries; Unity-owned programs remain explicitly
accounted for if no callback is emitted.

## Render And Timing Gates

All rows below stamp the same 51 production sources as the refined furnace.

| Batch | Evidence directory | Checks / PNG captures |
| --- | --- | --- |
| Native directional/point/spot, Add sum, deterministic seed and coverage | `Render-20261023-153648-800` | 58 / 32 |
| Independent pre-change zero-weight and black-mask comparisons, bare/metal/anisotropy/coat/film on both entries | `Render-20261023-154139-468` | 50 / 30; tested images are exactly equal |
| Actual four-array RGB allocation and coexistence with pixel lights | `Render-20261023-154141-050` | 32 / 20 |
| Layer/film, both film qualities and rough-coat variance sweep | `Render-20261023-154404-494` | 49 / 28 |
| Camera return, negative scale, mirrored UV/rebuilt tangents, main/detail normal AA and 75/85-degree views | `Render-20261023-154405-534` | 25 / 21 |
| Metal, anisotropy, blue coat and film appearance | `Render-20261023-154405-847` | 12 / 12 plus comparison sheet |
| Both rectangle quality paths remain smooth and unchanged | `Render-20261023-154406-205` | 24 / 12 |
| Directional/point/spot native maps affect direct Glints only | `Render-20261023-155308-325` | 15 / 6 |
| POM layered local visibility multiplies once, coverage unchanged | `Render-20261023-155547-872` | 30 / 18 |
| Smooth Probe response unchanged | `Render-20261023-155548-618` | 9 / 6 |
| Weight/mask linearity, ST independence, density convergence, index-matched negative control and Unity material serialization | `Render-20261023-155548-738` | 21 / 12 |
| GPU footprint LOD/ratio/orientation/wrap/isotropic-limit continuity | `Render-20261023-155852-728` | 10 numerical checks; float data saved |

These are 335 explicit render/numerical checks and 197 capture PNGs, excluding
comparison sheets and the 45 refined furnace/export checks. The footprint test shrinks
the parameter step from 1e-3 to 1e-5 at 128 fixed UV locations; worst fine-step
normalized-D RMS is 0.000243. Rough-coat fluctuation variance falls from 0.6834
at roughness0 to 0.00217 at0.7 in the saved sweep. This is a statistical smoothing
calibration, not proof of exact rough-layer angular transport.

Raw linear float captures are saved for selected light/showcase comparisons;
PNG sheets use the fixture display transform. The four-column hard-surface sheet
shows smooth / Glints / higher density / amplified absolute difference, not four
separate lighting models. The 21-frame motion directory is a saved camera/normal
regression, not arbitrary animated/skinned production-scene qualification.

Timing uses 12 warm draws per material, seven interleaved samples per state,
opposite ordering and covered full-screen quads on RTX4070 Ti SUPER. The corner
pixel's alpha is checked to reject an empty target. Camera.Render plus a one-pixel
completion readback includes CPU, driver and Editor overhead; it is not a GPU
timestamp or an actual Studio frame measurement. Median ranges across the two
orders, in milliseconds:

| Case | Before Glints | Current weight0 | Current weight1 |
| --- | --- | --- | --- |
| 1920x1080, one native lamp, metal | 0.40..0.43 | 0.42..0.45 | 0.95..1.02 |
| 1920x1080, three native lamps | 0.81..0.85 | 0.86..0.88 | 2.34..2.50 |
| 3840x2160, one native lamp | Not measured | 1.44..1.45 | 3.00..3.03 |
| 3840x2160, three native lamps | Not measured | 3.05..3.07 | 8.23..8.24 |
| 512x512, four fallback lamps | Not measured | 0.16 | 0.42 |
| 512x512, four fallback plus three native lamps | Not measured | 0.22..0.23 | 0.67..0.68 |
| 512x512, coated metal, three native lamps | Not measured | 1.01..1.02 | 1.21..1.22 |
| 512x512, Realtime film, three native lamps | Not measured | 2.42..2.52 | 2.60..2.71 |
| 512x512, Reference film, three native lamps | Not measured | 15.02..15.03 | 15.16..15.32 |

1080p before/off/on evidence is `Render-20261023-155852-800` and
`155853-244`; 4K is `155551-383` and `155551-717`; layered cases are
`155552-052` and `155553-256`; valid enabled-fallback runs are `155853-521`
and `155853-591` (all use the `Render-20261023-` prefix). Full raw series,
metadata and source stamps are retained. Glints is not free when disabled,
and its full-screen/multi-lamp cost is material; zero weight remains the default.

Earlier timing files remain as diagnostic history. Their first 1080p samples
show a large transient before settling and are not the stable baseline. Earlier
fallback timing fixtures accidentally left the four lamps disabled, and two
premature baseline requests ran the previous loaded Editor assembly without the
before state; these are not accepted timing comparisons. Final rows above use
the corrected loaded assembly and enabled lamps. No quality/variant/sample cuts
were used to produce the timings.

## Delivery Gate

The accepted artifact is now in `Build/abdata`; the normal zipmod packer has
produced the matching package without deploying it to the game.
`Candidate-20261023-155853-645` was the initial frozen candidate; its build is
`CodexBridge/Reports/BSDF-Compiler/Cache-Bundle-20261024-000116-632`.
The initial attempt finished after9488.01 seconds with a new Cutout
ForwardBase/Fragment compiler socket/protocol failure and worker restart.
The actual native audit confirms1041/1042 modern and1189 total programs, with
one missing Cutout Fragment identity: `DIRECTIONAL LIGHTPROBE_SH
UNITY_SPECCUBE_BLENDING UNITY_SPECCUBE_BOX_PROJECTION`, common hardware tier0.
All BSDF-owned shaders have submission records; only Unity's Standard lacks one.
This errorful/incomplete artifact is not promoted.

Sampled available memory stayed above22 GiB during the observed failure; this
does not establish its cause or exclude a short/per-process allocation failure.
Both UnityShaderCompiler and its FXC DLL are x64/large-address-aware; a roughly
2 GiB observed worker footprint alone is not proof of a 32-bit process limit.
Full relevant Editor logs, five-second memory/CPU observations and cache-write
observations are retained with the candidate. No worker log files were emitted
at the normal project/temporary locations in this run.

The flat furnace-export repair and expanded reference/normal-
packer source stamps created evidence revision `Candidate-20261023-184254-328`.
Its shader, native dependency, compile-setting and compiler configuration is
exactly equal to the initial candidate; only validation/workflow source stamps
changed. Its first controlled native repair is attempt2, retaining attempt1
and its missing set; the repair allowance is not reset.

| Attempt | Native build directory under `CodexBridge/Reports/BSDF-Compiler` | Outcome |
| --- | --- | --- |
| 1 initial | `Cache-Bundle-20261024-000116-632` | 9488.01s; 1041 modern / 1189 total; one Cutout compiler failure |
| 2 repair1 | `Cache-Bundle-20261024-024537-602` | 147.90s; all1042 modern /1190 total valid; exactly one program added, all1189 previous bytecodes preserved; old importer error still present in ShaderUtil |
| 3 clean confirmation / repair2 | `Cache-Bundle-20261024-025307-964` | 20.32s; complete audit again, all1190 bytecodes unchanged; zero new shader/C# errors and zero remaining ShaderUtil errors; 24 known duplicate AssetBundle Browser GUID diagnostics recorded separately |

The targeted diagnostic check after attempt2 was compiled from cache in0.0017s
with no native error, but still returned the archived generic importer message.
`ShaderUtil.ClearShaderMessages` did not clear that importer diagnostic. Explicit
Bridge reimport of the two modern shader assets cleared it; candidate hashes
were rechecked before the clean full confirmation. No ShaderCache was cleared,
no binary was spliced, and no feature, valid variant or sample budget was reduced.
Two of the permitted three repair slots were used, including clean confirmation.
This establishes the tested cached delivery, **not a cold-compiler root-cause fix**.

The final validation-only fixture revision is `Candidate-20261023-185847-030`.
It replaces the Cutout sphere's U mask, which clipped almost the entire visible
hemisphere, with a V mask and explicit useful-coverage/visible-light checks.
Only that render fixture changed; native shaders/resources/settings/compilers
match the accepted producer exactly. No additional native build was needed or
performed for the fixture-only revision. Its workflow stamp and source are
archived alongside the actual native producer's frozen workflow, not substituted
for it.

Final delivery evidence is
`CodexBridge/Reports/BSDF-BuildAudit/DeliveryGate-20261023-185846-556`:

- Actual native audit: all required identities and valid DXBC, 1042 modern /
  1190 total; every BSDF-owned shader has submissions, only Unity Standard is
  explicitly uncaptured.
- Normal packer, exact bundle/manifest bytes, zip CRC and duplicate-name checks pass.
- Actual zipped material regression: 28 pairs /161 checks /56 PNG captures pass,
  maximum RGBA error0. Cutout coverage is approximately20% of the target and has
  inspectable lighting, not just a nonzero silhouette pixel.
- Material directory: `CodexBridge/Reports/BSDF-BuildAudit/Materials/Render-20261023-185906-932`.
- Accepted archive: `CodexBridge/Reports/BSDF-BuildAudit/Baseline-20261023-190023-291`.
- Bundle SHA256: `bd3f2b02234739cfd27bb134f5dc6cc3cd1c91e0386adbdbd77d2e3deed383c4`.
- Zipmod SHA256: `d1e2843321698c482bd1b083442ed240dc2146a2dfbd7dbba637948a4f4e1101`.

The package remains `[xukmi&tomTom][KKS] Tom Shaders BSDF v0.1.0.zipmod`; this
task did not rename the existing release identity or create new carrier assets.
The earlier145-check zipped run is retained but superseded by the stronger
Cutout fixture above. Cold investigation remains deferred.

Aggregate decoded DXBC across all native program records, including duplicates,
grows from16.64 to26.91 MiB for Opaque and16.68 to27.04 MiB for Cutout.
Alpha, Back/Front and Glass retain their previous byte/instruction totals.
This code-size/compile-time cost is separate from the warmed render timings;
see `native-size-comparison.json`. The large exact-count reference is still
test-only; these production increases are the bounded runtime Glints path.

## Development Corrections

Retained development failures include a dynamic integer-vector lvalue rejected
by FXC, a diagnostic-only sampler reference removed by optimization, an enabled
fixture sun in a four-light sum, and a positive-Glints fixture with index-matched
dielectric IORs. These were corrected in source or fixtures; the last is now also
an explicit no-substrate-reflection control. They are not accepted final failures
or evidence that extra energy should be added to an index-matched layer.

No computer use, game deployment, interactive ME save/import acceptance, cold
cache clearing, other-mod changes, KK adaptation or real displacement is part of
these tests. Scope and approximations are in [the contract](Glints-Contract.md).
