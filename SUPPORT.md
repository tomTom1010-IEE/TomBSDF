# Support

Start with the [installation guide](Assets/Mods/TomShadersBSDF/Documents/Installation.md),
[material guide](Assets/Mods/TomShadersBSDF/Documents/Material-Guide.md) and
[troubleshooting](Assets/Mods/TomShadersBSDF/Documents/Troubleshooting.md).
This release targets KKS, not KK / Unity 5.6.

For Infra1 releases, install
[TomRenderInfrastructure 0.1.0](https://github.com/tomTom1010-IEE/TomRenderInfrastructure/releases/tag/v0.1.0)
first. Helper DLLs are supplied there, not embedded in BSDF shader archives.
Include the base version/file hashes when reporting extension problems; retained
plugin versions alone do not identify an integrated cohort. Remove old duplicate
providers rather than installing a second copy beside them.

Report reproducible problems through this repository's Issues. Include the exact
shader, BSDF / companion versions, relevant plugins, parameters / map encoding,
reproduction steps, expected / actual screenshots and the relevant log interval.
For performance include resolution, visible area, lights, postprocessing and
measurement method. State whether restart / shader switch / save / reload / import
changes the behavior. Resource unavailable and a feature failure are different results.

Do not post game files, proprietary SDK assemblies, personal scenes, tokens,
unredacted private paths or a complete Library / crash-dump collection.
Raw developer tests / reports are not required from ordinary users.

Known limits include ordinary transparent sorting, finite screen refraction,
approximate anisotropic IBL, unshadowed rectangles and the old Unity compiler's
unresolved cold-build behavior. See [Release Status](Assets/Mods/TomShadersBSDF/Documents/Release-Status.md).
