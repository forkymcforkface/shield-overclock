param(
    [Parameter(Mandatory = $true)][string]$BaseApk,
    [Parameter(Mandatory = $true)][string]$OutputApk,
    [string]$Gradle = "gradle"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$work = Join-Path ([System.IO.Path]::GetTempPath()) ("shield-tools-" + [guid]::NewGuid().ToString("N"))
$base = Join-Path $work "base"
$overlay = Join-Path $work "overlay"

try {
    apktool d -f $BaseApk -o $base
    Push-Location (Join-Path $repo "app-overlay")
    try {
        & $Gradle clean assembleRelease
    } finally {
        Pop-Location
    }
    $overlayApk = Join-Path $repo "app-overlay\app\build\outputs\apk\release\app-release-unsigned.apk"
    apktool d -f $overlayApk -o $overlay
    git -C $base apply (Join-Path $repo "patches\shield-tools\rootfan-1.4-to-1.5.patch")
    $target = Join-Path $base "smali_classes3\com\rootfan\shieldtools"
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item -Path (Join-Path $overlay "smali\com\rootfan\shieldtools\*") -Destination $target -Recurse -Force
    apktool b --use-aapt1 $base -o $OutputApk
} finally {
    if (Test-Path -LiteralPath $work) {
        Remove-Item -LiteralPath $work -Recurse -Force
    }
}
