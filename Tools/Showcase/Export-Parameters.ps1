param([string]$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')))
$ErrorActionPreference = 'Stop'
$module = Join-Path $Root 'Assets/Mods/TomShadersBSDF'
[xml]$manifest = Get-Content -LiteralPath (Join-Path $module 'manifest.xml') -Raw
[xml]$tips = Get-Content -LiteralPath (Join-Path $module 'Tooltips/tom_bsdf_tooltips.xml') -Raw
$shaders = foreach ($shader in $manifest.SelectNodes('/manifest/MaterialEditor/Shader')) {
    $name = $shader.GetAttribute('Name')
    if (-not $name.StartsWith('tom/', [StringComparison]::Ordinal)) { continue }
    $help = $tips.SelectSingleNode("/MaterialEditorTooltips/Shader[@Name='$name']")
    $properties = foreach ($property in $shader.SelectNodes('Property')) {
        $id = $property.GetAttribute('Name')
        $text = $help.SelectSingleNode("Property[@Name='$id']")
        if (-not $text -or -not $text.InnerText.Trim()) { throw "Missing tooltip: $name / $id" }
        [ordered]@{
            name = $id
            type = $property.GetAttribute('Type')
            category = $property.GetAttribute('Category')
            range = $property.GetAttribute('Range')
            default = $property.GetAttribute('DefaultValue')
            description = $text.InnerText.Trim()
        }
    }
    [ordered]@{ name = $name; properties = @($properties) }
}
$data = [ordered]@{
    schemaVersion = 1
    version = $manifest.manifest.version
    source = 'Manifest and per-shader tooltip catalog; ME names omit the leading underscore.'
    shaders = @($shaders)
}
$output = Join-Path $Root 'docs/parameter-data.json'
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($output)) | Out-Null
[IO.File]::WriteAllText($output, (($data | ConvertTo-Json -Depth 8) -replace "`r`n", "`n") + "`n", [Text.UTF8Encoding]::new($false))
[pscustomobject]@{ shaders = $data.shaders.Count; properties = ($data.shaders.properties | Measure-Object).Count; output = $output } | ConvertTo-Json
