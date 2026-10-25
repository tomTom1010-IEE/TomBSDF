# Showcase Capture Notes

52 actual GPU images, captured from the accepted RC1 Bundle, not generated illustrations or photographs. All source images are 768x768 and copied byte-for-byte into this gallery. Comparison boards resize uniformly and add captions outside the render.

## Shared Conditions

- Unity 2019.4.9f1, NVIDIA GeForce RTX 4070 Ti SUPER, D3D11, Gamma authoring with the explicit KKSLinear-v1 linear output contract.
- Standard Unity UV sphere, orthographic camera at (0,0,-3), size 0.7; no automatic exposure / grading.
- Default directional key intensity 0.85, rotation (25,-32,0), fixed analytic studio cubemap and ambient SH. Native additional light / shadow and isolated environment groups explicitly change light sources.
- POM uses a documented grazing key (65,-55,0). Coverage / glass use opaque checkers. Native shadows use a shadow-only blocker. The rectangle requires the matching temporary scene service.
- One global display transform: Reinhard x/(1+x), followed by sRGB. No per-image exposure, contrast, AI enhancement or content retouching.
- Known procedural RGB ripple maps illustrate normals; a shared brick set illustrates POM; periodic R height illustrates Tess. Settings identify named procedural maps rather than claiming a user texture pack.

## Provenance

Bundle SHA256: `0904d5aa53b43639d02660c040ae8a08d1774c38af965ceefe0335c22890c200`. The material's shader-owned tables come from that Bundle. Public [showcase data](showcase-data.json) records the source image SHA256, all captured public material settings, light notes and source run IDs. [Parameter data](parameter-data.json) comes from the shipped manifest and tooltip catalog.

The full private developer fixture / raw GPU and compiler evidence remains outside this repository. No user character or scene is used. These images do not replace manual KKS acceptance or establish whole-scene GPU performance.

## Interpretation

Groups are controlled illustrations, not a single scene with every feature enabled. Do not interpret black shadow regions without indirect fill as colored-light transport, Back/Front as OIT, POM as silhouette geometry, a finite glass sphere as a solid lens, or Glints as emission. The [user manual](UserManual.html) lists approximation and fallback boundaries.
