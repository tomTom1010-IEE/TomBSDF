# TomBSDF 0.2.0 RC1 Status

The accepted artifact is distributed as the
[complete KKS RC1 pre-release](https://github.com/tomTom1010-IEE/TomBSDF/releases/tag/v0.2.0-rc1)
on 2026-10-26. Packaging does not recompile or alter the accepted shader payload.

Updated 2026-10-25. **Packaged Editor acceptance passed. The maintainer reported
KKS / ME manual acceptance passed.** The game was operated by the maintainer,
not by the publishing agent. No new player frame-time measurements or individual
per-case game captures were supplied with that confirmation.

## Audited Artifact

| Check | Result |
| --- | --- |
| Modern entries | Seven, including BSDFTess and BSDFCutoutTess |
| Owned submissions | 13 BSDF-owned shaders, 88 snippets, 1704 required identities |
| Modern native programs | 1642 |
| Total delivered programs | 1790 valid DXBC; the other 86 are unchanged Unity-owned Standard programs |
| Bytecode preservation | All 1790 previously successful program hashes unchanged |
| Final native build | Warm, cache-preserving confirmation; no new shader errors |
| Template diagnostics | 24 existing duplicate immutable AssetBundle Browser GUID errors classified separately |
| Actual zipmod material regression | 330 checks, 95 PNGs, 44 source / package RGBA pairs with zero maximum error |
| LUTs | Four matching payloads; 27 modern shader LUT pointers resolve inside the Bundle |
| Active companion / ME game acceptance | Maintainer-reported checklist passed after Editor acceptance |

Editor renders used native lighting / Probe with extensions disabled. They did
not by themselves prove active game refraction / rectangle / shadow services.
The later manual game acceptance is separate evidence; do not relabel Editor
timings as player GPU measurements.

## Identity

Package GUID: `tom.Shaders.BSDF`; manifest version: `0.2.0`; RC1 is a candidate
label. Matching companion feature version: `0.6.0`.

```text
Current [tomTom][KKS] Tom Shaders BSDF v0.2.0.zipmod
SHA256 c62af78d9151f0b701128a7896065d2cc10dfc631392e9b0dadee6d07bff7153

Embedded chara/tom/shaders/tombsdf.unity3d
SHA256 0904d5aa53b43639d02660c040ae8a08d1774c38af965ceefe0335c22890c200

KKS_TomBSDF.dll
SHA256 5be347eaa8076b4d150e7bde3cd772dc88951f114721e74ebe6d5f3dbecd287f

TomBSDF.Runtime.dll
SHA256 a61ea084865949843beb8ab17d8b2fecf6f7c1cbd93d8e0adda7554236490667
```

The retained earlier `[xukmi&tomTom]` RC1 archive has a different zip hash
(`5cc3b3439af986fcf7c94674b365273e30945048299a6f3532b68e84e31d13b9`).
The current package has identical Bundle / Studio lists and XML-equivalent
manifest except the author field. Neither archive is silently renamed as the other.
Support-document updates do not change the already accepted render payload.

## Provenance And Validation Fixture

Developer evidence is retained outside Git under
`CodexBridge/Reports/BSDF-Release/RC1/FinalAcceptance-20261025-1822`.
The native producer is `Candidate-20261025-102910-022`, with
`Cache-Bundle-20261025-183051-678` submissions. The accepted Editor snapshot is
`BSDF-BuildAudit/Baseline-20261025-105447-409`.

A validation-only amendment replaced an incorrect direct-addressability LUT
check with packaged shader binding / metadata / payload checks. The separate
validation snapshot retained identical production configuration. It did not
change shader behavior, trigger another build or reset the repair allowance.
Original failed diagnostics remain archived, not rewritten as successes.

## Still Not Claimed

Cold reproducibility / the historic FXC crash root cause remain open. Controlled
incremental delivery with exact program / archive auditing is the current policy.
No compiler replacement, sample reduction, effective-variant removal or bytecode
splicing is a release solution. Counts describe RC1, not a fixed future target.

No KK port, exact OpenPBR / spectral transport, full GGX BTDF, SSR, BSSRDF, caustics,
nested media, colored shadows, automatic missing shadow maps or OIT is claimed.
Read [profiles and costs](HardSurface-Release.md) before enabling costly combinations.
