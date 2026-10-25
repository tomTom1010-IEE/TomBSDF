param([string]$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$tracked = @(& git -C $Root ls-files)
if ($LASTEXITCODE -or $tracked.Count -lt 1) { throw 'A populated source-overlay Git index is required.' }
$inventory = Get-Content -LiteralPath (Join-Path $Root 'SOURCE-INVENTORY.json') -Raw | ConvertFrom-Json
if (-not $inventory.files.Count) { throw 'Missing Unity-exported inventory.' }
foreach ($item in $inventory.files) {
    $path = [IO.Path]::GetFullPath((Join-Path $Root $item.path))
    if (-not $path.StartsWith($Root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Inventory path escapes repository: $($item.path)"
    }
    if ($item.path -notin $tracked) { throw "Required file not tracked: $($item.path)" }
    $file = Get-Item -LiteralPath $path
    if ($file.Length -ne $item.bytes -or (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() -ne $item.sha256) {
        throw "Exported source/native bytes changed: $($item.path)"
    }
}
foreach ($file in $tracked) {
    if ($file -match '(^|/)(Tests|Library|Temp|Logs|CodexBridge|Reports|Captures|Artifacts|bin|obj|__pycache__)(/|$)' -or
        $file -match 'Shaders [12]/|LinearBuildBridge|\.zh-CN\.md|\.(zipmod|unity3d|unitypackage|pdb|dmp|log)$') {
        throw "Excluded publication content is tracked: $file"
    }
}
$mod = 'Assets/Mods/TomShadersBSDF'
[xml]$manifest = Get-Content -LiteralPath (Join-Path $Root "$mod/manifest.xml") -Raw
if ($manifest.manifest.game -ne 'Koikatsu Sunshine' -or $manifest.manifest.version -ne '0.2.0') {
    throw 'Unexpected package host/version.'
}
$entries = @($manifest.manifest.MaterialEditor.Shader)
$modern = @($entries | Where-Object { $_.Name -like 'tom/BSDF*' })
if ($entries.Count -ne 11 -or $modern.Count -ne 7) { throw 'Expected seven modern, three legacy and one rectangle entry.' }
foreach ($entry in $entries) {
    foreach ($relative in @("$mod/Prefab/$($entry.Asset).prefab", "$mod/Prefab/$($entry.Asset).prefab.meta")) {
        if ($relative -notin $tracked) { throw "Required carrier absent: $relative" }
    }
}
$lutPaths = @("$mod/ResourcesData/TomBSDFAnisotropyEnergyV1.asset", "$mod/ResourcesData/TomBSDFFilmEnergyV1.asset")
foreach ($relative in $lutPaths) {
    $attr = (& git -C $Root check-attr filter -- $relative) -join ''
    if ($LASTEXITCODE -or $attr -notmatch ': filter: lfs$') { throw "Required LFS binding absent: $relative" }
    $reader = [IO.StreamReader]::new((Join-Path $Root $relative))
    try { $first = $reader.ReadLine() } finally { $reader.Dispose() }
    if ($first -like 'version https://git-lfs.github.com/spec/*') { throw "Unresolved LFS pointer: $relative" }
}
$docs = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.md' | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }
foreach ($doc in $docs) {
    $body = Get-Content -LiteralPath $doc.FullName -Raw
    if ($body -match '[\u3400-\u9fff]') { throw "Non-English documentation remains: $($doc.FullName)" }
    foreach ($link in [regex]::Matches($body, '\[[^\]\r\n]*\]\(([^)\r\n]+)\)')) {
        $target = $link.Groups[1].Value.Trim('<', '>')
        if ($target -match '^(https?://|mailto:|#)') { continue }
        $target = [uri]::UnescapeDataString(($target -split '#', 2)[0])
        if ($target -and -not (Test-Path -LiteralPath (Join-Path $doc.DirectoryName $target))) {
            throw "Broken documentation link: $($doc.Name) -> $target"
        }
    }
}
[pscustomobject]@{
    status = 'passed'
    trackedFiles = $tracked.Count
    verifiedExportedFiles = $inventory.files.Count
    modernEntries = $modern.Count
    nativeCarriers = $entries.Count
    lfsLuts = $lutPaths.Count
    englishDocuments = $docs.Count
    scope = 'Source publication integrity only; no Unity compilation, Bundle build or game operation.'
} | ConvertTo-Json
