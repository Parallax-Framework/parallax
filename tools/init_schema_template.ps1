[CmdletBinding()]
param(
    [string]$Destination = "",

    [string]$SchemaName = "Schema Template",
    [string]$Description = "A minimal Parallax schema template.",
    [string]$Author = "Unknown",
    [switch]$Force
)

$source = Join-Path $PSScriptRoot "schema_template"

if ( [string]::IsNullOrWhiteSpace($Destination) ) {
    $Destination = (Get-Location).Path
}

if ( -not (Test-Path $source) ) {
    Write-Error "Schema template source not found at $source"
    exit 1
}

if ( Test-Path -LiteralPath $Destination ) {
    $hasItems = Get-ChildItem -LiteralPath $Destination -Force -ErrorAction SilentlyContinue | Select-Object -First 1
    if ( $hasItems -and -not $Force ) {
        Write-Error "Destination folder is not empty. Use -Force to overwrite."
        exit 1
    }
} else {
    New-Item -ItemType Directory -LiteralPath $Destination -Force | Out-Null
}

$schemaFolder = Split-Path -Leaf (Resolve-Path -LiteralPath $Destination)

Copy-Item -Path (Join-Path $source "*") -Destination $Destination -Recurse -Force:$Force

$bootPath = Join-Path $Destination "gamemode\schema\boot.lua"
$languagePath = Join-Path $Destination "gamemode\schema\languages\sh_english.lua"
$modulePath = Join-Path $Destination "gamemode\modules\sh_example.lua"
$parallaxSourcePath = Join-Path $Destination "parallax.txt"
$parallaxTargetPath = Join-Path $Destination ("{0}.txt" -f $schemaFolder)

if ( Test-Path -LiteralPath $parallaxSourcePath ) {
    Move-Item -LiteralPath $parallaxSourcePath -Destination $parallaxTargetPath -Force:$Force
}

$parallaxPath = $parallaxTargetPath

function Replace-TemplateTokens {
    param(
        [string]$FilePath
    )

    if ( -not (Test-Path -LiteralPath $FilePath) ) {
        return
    }

    $content = Get-Content -LiteralPath $FilePath -Raw
    $content = $content.Replace("{{SCHEMA_NAME}}", $SchemaName)
    $content = $content.Replace("{{SCHEMA_DESCRIPTION}}", $Description)
    $content = $content.Replace("{{SCHEMA_AUTHOR}}", $Author)
    $content = $content.Replace("{{SCHEMA_FOLDER}}", $schemaFolder)

    Set-Content -LiteralPath $FilePath -Value $content -NoNewline
}

Replace-TemplateTokens -FilePath $bootPath
Replace-TemplateTokens -FilePath $languagePath
Replace-TemplateTokens -FilePath $modulePath
Replace-TemplateTokens -FilePath $parallaxPath

Write-Host "Schema template initialized at $Destination"
