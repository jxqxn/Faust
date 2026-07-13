param(
	[string]$GodotPath = $(if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "C:\Tools\Godot\godot.exe" })
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

$knownGutShutdownResource = 'ERROR: 5 resources still in use at exit (run with --verbose for details).'
$unexpectedErrors = @($engineErrors | Where-Object { $_ -ne $knownGutShutdownResource })
$unexpectedLeakLines = @($leakLines | Where-Object {
	$_ -notmatch 'ObjectDB instances leaked' -and $_ -ne $knownGutShutdownResource
})

if ($process.ExitCode -ne 0 -or $unexpectedErrors.Count -gt 0 -or $unexpectedLeakLines.Count -gt 0 -or $orphanFailures.Count -gt 0) {
	$details = @($unexpectedErrors) + @($unexpectedLeakLines) + @($orphanFailures)
	if ($details.Count -gt 0) {
		Write-Error ("Godot test-gate failure:`n" + ($details -join "`n"))
	}
	exit 1
}

if ($engineErrors -contains $knownGutShutdownResource) {
	Write-Host "GUT passed. Ignored the verified GUT 9.6 shutdown baseline: 5 cached Script resources."
} else {
	Write-Host "GUT passed without Godot engine errors."
}
exit 0
