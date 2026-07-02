param(
	[string]$GodotExe = "C:\Users\evans\Desktop\Godot_v4.7-stable_win64.exe",
	[ValidateSet("debug", "release")]
	[string]$Mode = "debug",
	[switch]$Install
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$ExportDir = Join-Path $ProjectRoot "builds\android\exports"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ApkPath = Join-Path $ExportDir "darts-game-$Timestamp.apk"
$AdbExe = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"

New-Item -ItemType Directory -Force -Path $ExportDir | Out-Null

if (Test-Path $AdbExe) {
	& $AdbExe kill-server | Out-Null
}

$ExportFlag = if ($Mode -eq "release") { "--export-release" } else { "--export-debug" }

Write-Host "Exporting Android APK:"
Write-Host "  $ApkPath"

& $GodotExe --headless --path $ProjectRoot $ExportFlag "Android" $ApkPath

if ($LASTEXITCODE -ne 0) {
	throw "Godot Android export failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path $ApkPath)) {
	throw "Godot reported success, but the APK was not found: $ApkPath"
}

Write-Host ""
Write-Host "APK exported successfully:"
Write-Host "  $ApkPath"

if ($Install) {
	if (-not (Test-Path $AdbExe)) {
		throw "ADB was not found at $AdbExe"
	}

	Write-Host ""
	Write-Host "Installing APK to connected Android device..."
	& $AdbExe start-server | Out-Null
	& $AdbExe install -r $ApkPath

	if ($LASTEXITCODE -ne 0) {
		throw "ADB install failed with exit code $LASTEXITCODE."
	}
}
