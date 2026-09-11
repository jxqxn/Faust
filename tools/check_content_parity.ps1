# Checks that runtime game content is byte-identical to the reverse-engineering
# original StreamingAssets configs (clone methodology pillar 1: zero-translation of original data).
#
#   Every file under content/ MUST exist in the corpus StreamingAssets/config with identical
#   bytes. Anything else is a self-made/translated data layer and fails the check.
#   Corpus files absent from content/ are reported as "not integrated" (allowed;
#   they are pending systems tracked in docs/METHOD_MAP.md section D).
#
# Exit codes: 0 = parity, 1 = violations found.

param(
    [string]$CorpusConfig = "C:\Users\User\Documents\GitHub\Faust-local-source\_unpack\unity_export\ExportedProject\Assets\StreamingAssets\config",
    [string]$Godot = "C:\Tools\Godot\4.7-stable\Godot_v4.7-stable_win64_console.exe",
    [string]$Python = "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$contentDir = Join-Path $repoRoot "content"

if (-not (Test-Path $CorpusConfig)) {
    Write-Warning "Corpus config dir not found: $CorpusConfig - parity check FAILED."
    exit 1
}

function Get-RelPaths([string]$root) {
    Get-ChildItem -LiteralPath $root -Recurse -File |
        ForEach-Object { $_.FullName.Substring($root.Length + 1) }
}

$contentFiles = @(Get-RelPaths $contentDir)
$corpusFiles = @(Get-RelPaths $CorpusConfig)
$corpusSet = @{}
foreach ($rel in $corpusFiles) { $corpusSet[$rel] = $true }

$violations = 0
foreach ($rel in $contentFiles) {
    $counterpart = Join-Path $CorpusConfig $rel
    if (-not $corpusSet.ContainsKey($rel)) {
        Write-Output "SELF-MADE content/$rel has no corpus counterpart"
        $violations++
        continue
    }
    $repoHash = (Get-FileHash -LiteralPath (Join-Path $contentDir $rel) -Algorithm SHA256).Hash
    $corpusHash = (Get-FileHash -LiteralPath $counterpart -Algorithm SHA256).Hash
    if ($repoHash -ne $corpusHash) {
        Write-Output "DIFFERS content/$rel is not byte-identical to corpus StreamingAssets/config/$rel"
        $violations++
    }
}

$contentSet = @{}
foreach ($rel in $contentFiles) { $contentSet[$rel] = $true }
$pending = @($corpusFiles | Where-Object { -not $contentSet.ContainsKey($_) } | Sort-Object)

Write-Output ""
Write-Output ("content parity: {0} files checked, {1} violation(s)" -f $contentFiles.Count, $violations)
Write-Output ("corpus domains not yet integrated ({0}, tracked in docs/METHOD_MAP.md section D):" -f $pending.Count)
foreach ($rel in $pending) { Write-Output "  - $rel" }

if ($violations -gt 0) { exit 1 }
# Byte identity alone failed to catch the old duplicate-key collapse. Also
# compare the runtime reader with Python's independent lossless token tree.
foreach ($toolPath in @($Godot, $Python)) {
    if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
        throw "Required validation runtime missing: $toolPath"
    }
}
$oraclePath = Join-Path ([System.IO.Path]::GetTempPath()) ("faust-source-oracle-" + [guid]::NewGuid().ToString() + ".json")
$priorOracle = $env:FAUST_SOURCE_ORACLE
try {
    & $Python (Join-Path $PSScriptRoot 'audit_source_duplicate_keys.py') --source-root $CorpusConfig --oracle $oraclePath
    if ($LASTEXITCODE -ne 0) { throw "Independent source JSONC audit failed" }
    $env:FAUST_SOURCE_ORACLE = $oraclePath
    $readerOutput = & $Godot --headless --path $repoRoot --script tools/verify_source_config.gd 2>&1
    $readerCode = $LASTEXITCODE
    $readerOutput | Write-Output
    $readerText = $readerOutput -join [Environment]::NewLine
    $expectedSummary = "Original token parity: {0} files, 0 differences" -f $contentFiles.Count
    if ($readerCode -ne 0 -or $readerText -match 'SCRIPT ERROR|ERROR:' -or -not $readerText.Contains($expectedSummary)) {
        throw "Runtime token parity failed or did not finish"
    }
}
finally {
    $env:FAUST_SOURCE_ORACLE = $priorOracle
    if (Test-Path -LiteralPath $oraclePath) { Remove-Item -LiteralPath $oraclePath }
}
exit 0
