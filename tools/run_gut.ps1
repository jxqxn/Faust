param(
	[string]$GodotPath = $(if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "C:\Tools\Godot\4.7-stable\Godot_v4.7-stable_win64.exe" })
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$logPath = Join-Path $repoRoot "gut-test.log"

if (-not (Test-Path -LiteralPath $GodotPath)) {
	throw "Godot executable not found: $GodotPath. Set GODOT_BIN or pass -GodotPath."
}

Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
$process = Start-Process -FilePath $GodotPath -ArgumentList @(
	"--headless", "--path", $repoRoot, "--log-file", $logPath,
	"--script", "tools/run_gut.gd"
) -Wait -PassThru

$engineErrors = @()
$leakLines = @()
$orphanFailures = @()
if (Test-Path -LiteralPath $logPath) {
	$engineErrors = Select-String -LiteralPath $logPath -Pattern '(^|\s)(SCRIPT ERROR:|ERROR:)' |
		ForEach-Object { $_.Line }
	$leakLines = Select-String -LiteralPath $logPath -Pattern 'RID allocations|ObjectDB instances leaked|resources still in use at exit' |
		ForEach-Object { $_.Line }
	$orphanFailures = Select-String -LiteralPath $logPath -Pattern '^\s*Orphans\s+[1-9][0-9]*\b' |
		ForEach-Object { $_.Line }
}

if ($process.ExitCode -ne 0 -or $engineErrors.Count -gt 0 -or $leakLines.Count -gt 0 -or $orphanFailures.Count -gt 0) {
	$details = @($engineErrors) + @($leakLines) + @($orphanFailures)
	if ($details.Count -gt 0) {
		Write-Error ("Godot test-gate failure:`n" + ($details -join "`n"))
	}
	exit 1
}

Write-Host "GUT passed without Godot engine errors or leak diagnostics."
exit 0
