# Changelog

## 0.2.0 RC1 - 2026-10-25

- Seven modern KKS entries: Opaque, Cutout, premultiplied Alpha, Back/Front,
  finite Glass, Tess and CutoutTess, with three active xukmi compatibility entries.
- Compensated GGX / Smith and diffuse, native multi-light shadows, Probe / SH,
  AO / specular occlusion, detail normals, AA and anisotropy.
- Layered coat with independent normals / absorption / transport, calibrated
  conductor optics and optimized / retained Reference thin film.
- Optional Companion0.6.0: four unshadowed rectangles, isolated area quality,
  supported capture lifecycle, scene buffers, transparent native-shadow reuse
  and displacement bounds. KKSLinear-v1 colors do not depend on the companion.
- POM with native-light local self-shadow, statistical stable Glints on supported
  solid entries, and independent fixed / world-edge Tess displacement.
- Equivalent shared-fragment control-flow refactoring retained physical features,
  samples and effective variants. No claim of an FXC root-cause fix.
- Complete native-program / zip audit:1642 modern /1790 total programs; packaged
  regression330 checks /95 captures /44 exact source-versus-package pairs.
- KKS / ME manual acceptance reported passed by the maintainer.
- Rebuildable source overlay includes native carriers, matching metadata / runtime
  and LFS LUTs, with English installation, usage, profiles, build and support docs.

This is not full OpenPBR parity, a KK port, exact BTDF / spectral transport, SSR,
BSSRDF, caustics, nested media, colored shadows or OIT. Historical evidence and
limitations are retained in the documentation; generated binaries are not Git source.
