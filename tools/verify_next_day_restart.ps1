param(
    [string]$GodotPath = 'C:\Tools\Godot\4.7-stable\Godot_v4.7-stable_win64_console.exe'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('faust-day-restart-' + [guid]::NewGuid().ToString('N'))
$evidenceRoot = Join-Path $repoRoot 'docs/audit/next_day_runtime/process_restart'
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
$steps = @(@('start', 1), @('night', 2), @('day', 2), @('night', 3), @('day', 3), @('stable', 3))
$processIds = @()
foreach ($step in $steps) {
    $phase = $step[0]
    $round = $step[1]
    $log = Join-Path $evidenceRoot "$phase-$round.log"
    & $GodotPath --path $repoRoot --rendering-method gl_compatibility --script tools/verify_next_day_restart.gd -- $fixtureRoot $phase $round 2>&1 | Tee-Object -FilePath $log
    if ($LASTEXITCODE -ne 0) { throw "Process failed: $phase $round; see $log" }
    $text = Get-Content -LiteralPath $log -Raw
    if ($text -match 'SCRIPT ERROR:|ERROR:|RESTART FAIL:|ObjectDB instances leaked|RID allocations|resources still in use|unclaimed string names') {
        throw "Engine or assertion failure: $log"
    }
    if ($text -notmatch 'PROCESS_RESTART .* failures=0 pid=(\d+)') {
        throw "Missing completed replay marker: $log"
    }
    $processIds += $Matches[1]
}
if (@($processIds | Select-Object -Unique).Count -ne $steps.Count) {
    throw 'Replay did not use six independent processes'
}
Get-ChildItem -LiteralPath $fixtureRoot -Filter '*.png' | Copy-Item -Destination $evidenceRoot
Write-Output "PASS: six independent GPU processes; evidence $evidenceRoot; isolated saves $fixtureRoot"
