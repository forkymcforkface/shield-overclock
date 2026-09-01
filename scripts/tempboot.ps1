param(
    [Parameter(Mandatory = $true)]
    [string]$Serial,

    [Parameter(Mandatory = $true)]
    [string]$Image
)

$ErrorActionPreference = 'Stop'
$resolvedImage = (Resolve-Path -LiteralPath $Image).Path
$state = (& adb -s $Serial get-state 2>$null).Trim()
if ($state -ne 'device') {
    throw "ADB device $Serial is not connected"
}

$device = (& adb -s $Serial shell getprop ro.product.device).Trim()
if ($device -notlike 'foster*' -and $device -notlike 'darcy*') {
    throw "Refusing unsupported target: $device ($Serial)"
}

& adb -s $Serial reboot bootloader
$deadline = (Get-Date).AddSeconds(30)
do {
    Start-Sleep -Seconds 1
    $present = (& fastboot devices) -match [regex]::Escape($Serial)
} while (-not $present -and (Get-Date) -lt $deadline)

if (-not $present) {
    throw "Fastboot device $Serial did not appear"
}

& fastboot -s $Serial boot $resolvedImage
if ($LASTEXITCODE -ne 0) {
    throw "fastboot boot failed with exit code $LASTEXITCODE"
}

Write-Host 'Temporary boot sent. No partition was flashed.'
