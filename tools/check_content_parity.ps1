# Checks that runtime game content is byte-identical to the reverse-engineering
# corpus configs (clone methodology pillar 1: zero-translation of original data).
#
#   Every file under content/ MUST exist in the corpus data/config with identical
#   bytes. Anything else is a self-made/translated data layer and fails the check.
#   Corpus files absent from content/ are reported as "not integrated" (allowed;
#   they are pending systems tracked in docs/METHOD_MAP.md section D).
#
# Exit codes: 0 = parity (or corpus missing), 1 = violations found.

param(
    [string]$CorpusConfig = "C:\Users\User\Documents\GitHub\Faust-local-source\_unpack\data\config"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$contentDir = Join-Path $repoRoot "content"

if (-not (Test-Path $CorpusConfig)) {
    Write-Warning "Corpus config dir not found: $CorpusConfig - parity check SKIPPED."
    exit 0
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
        Write-Output "DIFFERS content/$rel is not byte-identical to corpus data/config/$rel"
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
exit 0
