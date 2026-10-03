# tools/fonts.ps1 - Downloads WOFF2 font files for Nunito, Sora, and IBM Plex Sans Arabic into assets/fonts/
$ErrorActionPreference = 'Stop'

$FontsDir = Join-Path -Path $PSScriptRoot -ChildPath "..\assets\fonts"
if (!(Test-Path $FontsDir)) {
    New-Item -ItemType Directory -Path $FontsDir -Force | Out-Null
}

$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
$cssUrl = "https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&family=Sora:wght@300;400;600;700&family=IBM+Plex+Sans+Arabic:wght@400;600&display=swap"

Write-Host "Fetching Google Fonts CSS metadata..."
$cssContent = Invoke-WebRequest -Uri $cssUrl -UserAgent $ua -UseBasicParsing | Select-Object -ExpandProperty Content

# Parse @font-face blocks
$fontFaceBlocks = [regex]::Matches($cssContent, '(?s)@font-face\s*\{[^}]+\}')

$localCssLines = @(
    "/* Self-hosted WOFF2 fonts for Mess Module Mock UI */",
    ""
)

$counter = 1
foreach ($block in $fontFaceBlocks) {
    $blockText = $block.Value
    
    # Extract font-family, font-style, font-weight, src url
    if ($blockText -match "font-family:\s*['`"]?([^'`";]+)['`"]?") { $family = $Matches[1].Trim() } else { continue }
    if ($blockText -match "font-weight:\s*([^;]+);") { $weight = $Matches[1].Trim() } else { $weight = "400" }
    if ($blockText -match "font-style:\s*([^;]+);") { $style = $Matches[1].Trim() } else { $style = "normal" }
    if ($blockText -match "src:\s*url\(([^)]+)\)") { $url = $Matches[1].Trim("'", '"') } else { continue }
    if ($blockText -match "unicode-range:\s*([^;]+);") { $unicodeRange = $Matches[1].Trim() } else { $unicodeRange = $null }

    # Clean family name for file name
    $cleanFamily = $family -replace '\s+', ''
    $cleanWeight = $weight -replace '\s+', ''
    $fileName = "$cleanFamily-$cleanWeight-$counter.woff2"
    $counter++

    $destPath = Join-Path -Path $FontsDir -ChildPath $fileName

    if (!(Test-Path $destPath)) {
        Write-Host "Downloading $family ($weight) -> $fileName"
        Invoke-WebRequest -Uri $url -OutFile $destPath -UserAgent $ua -UseBasicParsing
    } else {
        Write-Host "Font already exists: $fileName"
    }

    $localCssLines += "@font-face {"
    $localCssLines += "  font-family: '$family';"
    $localCssLines += "  font-style: $style;"
    $localCssLines += "  font-weight: $weight;"
    $localCssLines += "  font-display: swap;"
    $localCssLines += "  src: url('../../assets/fonts/$fileName') format('woff2');"
    if ($unicodeRange) {
        $localCssLines += "  unicode-range: $unicodeRange;"
    }
    $localCssLines += "}"
    $localCssLines += ""
}

$cssPath = Join-Path -Path $PSScriptRoot -ChildPath "..\css\base\fonts.css"
Set-Content -Path $cssPath -Value ($localCssLines -join "`n") -Encoding UTF8
Write-Host "Fonts downloaded and css/base/fonts.css created successfully."
