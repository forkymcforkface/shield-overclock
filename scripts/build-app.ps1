param(
    [Parameter(Mandatory = $true)][string]$BaseApk,
    [Parameter(Mandatory = $true)][string]$OutputApk,
    [string]$Gradle = "gradle"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$resolvedBaseApk = (Resolve-Path -LiteralPath $BaseApk).Path
$resolvedOutputApk = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputApk)
if (Test-Path -LiteralPath $resolvedOutputApk) {
    throw "Output already exists: $resolvedOutputApk"
}
$work = Join-Path ([System.IO.Path]::GetTempPath()) ("shield-tools-" + [guid]::NewGuid().ToString("N"))
$base = Join-Path $work "base"
$overlay = Join-Path $work "overlay"

function Assert-NativeSuccess([string]$Operation, [int]$ExitCode) {
    if ($ExitCode -ne 0) {
        throw "$Operation failed with exit code $ExitCode"
    }
}

try {
    apktool d -f $resolvedBaseApk -o $base
    Assert-NativeSuccess "Apktool base decode" $LASTEXITCODE
    if (-not (Test-Path -LiteralPath (Join-Path $base "apktool.yml"))) {
        throw "Apktool base decode did not produce apktool.yml"
    }
    Push-Location (Join-Path $repo "app-overlay")
    try {
        & $Gradle clean assembleRelease
        Assert-NativeSuccess "Gradle build" $LASTEXITCODE
    } finally {
        Pop-Location
    }
    $overlayApk = Join-Path $repo "app-overlay\app\build\outputs\apk\release\app-release-unsigned.apk"
    if (-not (Test-Path -LiteralPath $overlayApk)) {
        throw "Gradle build did not produce $overlayApk"
    }
    apktool d -f $overlayApk -o $overlay
    Assert-NativeSuccess "Apktool overlay decode" $LASTEXITCODE
    if (-not (Test-Path -LiteralPath (Join-Path $overlay "apktool.yml"))) {
        throw "Apktool overlay decode did not produce apktool.yml"
    }
    git -C $base apply (Join-Path $repo "patches\shield-tools\rootfan-1.4-to-1.5.patch")
    Assert-NativeSuccess "Shield Tools patch" $LASTEXITCODE
    $target = Join-Path $base "smali_classes3\com\rootfan\shieldtools"
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item -Path (Join-Path $overlay "smali\com\rootfan\shieldtools\*") -Destination $target -Recurse -Force
    apktool b --use-aapt1 $base -o $resolvedOutputApk
    Assert-NativeSuccess "Apktool build" $LASTEXITCODE
    if (-not (Test-Path -LiteralPath $resolvedOutputApk)) {
        throw "Apktool build did not produce $resolvedOutputApk"
    }
} finally {
    if (Test-Path -LiteralPath $work) {
        Remove-Item -LiteralPath $work -Recurse -Force
    }
}
