# Showcase Build Tools

The checked-in `docs/` directory is a buildless GitHub Pages site, styled to
match the sibling TomShadersX gallery. Hosting needs no Node / npm / Unity build.

`Export-Parameters.ps1` uses the platform XML parser to export exact manifest
categories / ranges / defaults and per-shader tooltip text. `build.mjs` checks
three explicitly accepted source runs, copies their 52 PNGs byte-for-byte, makes
uniformly resized labeled comparison sheets, and generates the README, manual,
reference and capture notes. It does not generate or enhance shader imagery.

```powershell
pwsh -File Tools/Showcase/Export-Parameters.ps1
npm --prefix Tools/Showcase install
node Tools/Showcase/build.mjs . PATH_TO_FOUNDATION_REPORT PATH_TO_SURFACE_REPORT PATH_TO_SCENE_REPORT
```

Source GPU reports are developer-local and deliberately excluded. Public
`docs/showcase-data.json` retains their run IDs, image hashes, recorded settings
and light notes. To refresh captures, explicitly render the actual Bundle through
the Unity Bridge in isolated temporary scenes; do not reconstruct them using AI
or modify the production shaders to match a desired picture.

Pinned build dependencies are developer tools only. Optional `MARKED_MODULE` and
`SHARP_MODULE` environment paths support an existing local tool installation;
no credentials, private paths or node_modules are published.

## Hosting

GitHub Pages publishes branch `main`, folder `/docs`, with `.nojekyll` for the
buildless files. The repository homepage points to
`https://tomtom1010-iee.github.io/TomBSDF/`. Routes are `index.html` / `Gallery.html`,
`UserManual.html`, `Reference.html` and `CaptureNotes.html`. Relative assets work
under the project path and when opened directly from a source checkout.

Curated public renders and comparison boards are intentional documentation
assets, not disposable test intermediates. Raw reports, browser QA captures,
Unity fixtures, cache, node_modules and complete build packages stay outside Git.
