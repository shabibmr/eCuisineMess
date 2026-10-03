# tools/vendor.ps1 - Downloads pinned vendor dependencies into mock-ui/vendor/
$ErrorActionPreference = 'Stop'

$VendorDir = Join-Path -Path $PSScriptRoot -ChildPath "..\vendor"
if (!(Test-Path $VendorDir)) {
    New-Item -ItemType Directory -Path $VendorDir -Force | Out-Null
}

$files = @(
    @{ Name = "Alpine.js"; Version = "3.14.8"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/alpinejs@3.14.8/dist/cdn.min.js"; Out = "alpine.min.js" },
    @{ Name = "Tabulator JS"; Version = "6.3.1"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/tabulator-tables@6.3.1/dist/js/tabulator.min.js"; Out = "tabulator.min.js" },
    @{ Name = "Tabulator CSS"; Version = "6.3.1"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/tabulator-tables@6.3.1/dist/css/tabulator.min.css"; Out = "tabulator.min.css" },
    @{ Name = "SheetJS (XLSX)"; Version = "0.20.3"; License = "Apache 2.0"; Url = "https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js"; Out = "xlsx.full.min.js" },
    @{ Name = "jsPDF"; Version = "2.5.1"; License = "MIT"; Url = "https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"; Out = "jspdf.umd.min.js" },
    @{ Name = "jspdf-autotable"; Version = "3.8.4"; License = "MIT"; Url = "https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.8.4/jspdf.plugin.autotable.min.js"; Out = "jspdf.plugin.autotable.min.js" },
    @{ Name = "ApexCharts JS"; Version = "4.3.0"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/apexcharts@4.3.0/dist/apexcharts.min.js"; Out = "apexcharts.min.js" },
    @{ Name = "ApexCharts CSS"; Version = "4.3.0"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/apexcharts@4.3.0/dist/apexcharts.css"; Out = "apexcharts.css" },
    @{ Name = "Fuse.js"; Version = "7.0.0"; License = "Apache 2.0"; Url = "https://cdn.jsdelivr.net/npm/fuse.js@7.0.0/dist/fuse.min.js"; Out = "fuse.min.js" },
    @{ Name = "flatpickr JS"; Version = "4.6.13"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/flatpickr.min.js"; Out = "flatpickr.min.js" },
    @{ Name = "flatpickr CSS"; Version = "4.6.13"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/flatpickr.min.css"; Out = "flatpickr.min.css" },
    @{ Name = "SortableJS"; Version = "1.15.6"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/sortablejs@1.15.6/Sortable.min.js"; Out = "sortable.min.js" },
    @{ Name = "AutoAnimate"; Version = "0.8.2"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/@formkit/auto-animate@0.8.2/index.min.js"; Out = "auto-animate.min.js" },
    @{ Name = "Notyf JS"; Version = "3.10.0"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/notyf@3.10.0/notyf.min.js"; Out = "notyf.min.js" },
    @{ Name = "Notyf CSS"; Version = "3.10.0"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/notyf@3.10.0/notyf.min.css"; Out = "notyf.min.css" },
    @{ Name = "hotkeys-js"; Version = "3.13.9"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/hotkeys-js@3.13.9/dist/hotkeys.min.js"; Out = "hotkeys.min.js" },
    @{ Name = "Day.js Core"; Version = "1.11.13"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/dayjs@1.11.13/dayjs.min.js"; Out = "dayjs.min.js" },
    @{ Name = "Day.js customParseFormat"; Version = "1.11.13"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/dayjs@1.11.13/plugin/customParseFormat.js"; Out = "dayjs-customParseFormat.js" },
    @{ Name = "Day.js isBetween"; Version = "1.11.13"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/dayjs@1.11.13/plugin/isBetween.js"; Out = "dayjs-isBetween.js" },
    @{ Name = "Day.js isoWeek"; Version = "1.11.13"; License = "MIT"; Url = "https://cdn.jsdelivr.net/npm/dayjs@1.11.13/plugin/isoWeek.js"; Out = "dayjs-isoWeek.js" },
    @{ Name = "Lucide Icons (UMD)"; Version = "0.475.0"; License = "ISC"; Url = "https://cdn.jsdelivr.net/npm/lucide@0.475.0/dist/umd/lucide.min.js"; Out = "lucide.min.js" }
)

Write-Host "Downloading vendor assets..."

foreach ($f in $files) {
    $outName = $f['Out']
    $outPath = Join-Path -Path $VendorDir -ChildPath $outName
    if (!(Test-Path $outPath)) {
        Write-Host "Downloading $($f['Name']) v$($f['Version']) -> $outName"
        Invoke-WebRequest -Uri $f['Url'] -OutFile $outPath -UseBasicParsing
    } else {
        Write-Host "Already exists: $outName"
    }
}

# Write VERSIONS.md
$versionsPath = Join-Path -Path $VendorDir -ChildPath "VERSIONS.md"
$lines = @(
    "# Vendor Libraries and Versions",
    "",
    "| Library | Version | Licence | URL | File |",
    "|---|---|---|---|---|"
)

foreach ($f in $files) {
    $n = $f['Name']
    $v = $f['Version']
    $l = $f['License']
    $u = $f['Url']
    $o = $f['Out']
    $lines += "| $n | $v | $l | [$u]($u) | ``$o`` |"
}

Set-Content -Path $versionsPath -Value ($lines -join "`n") -Encoding UTF8
Write-Host "Vendor process complete. VERSIONS.md written."
