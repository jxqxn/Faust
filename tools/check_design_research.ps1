param()

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $repoRoot "docs\research\faust-game-design-data-research.md"
$indexPath = Join-Path $repoRoot "docs\research\README.md"
$snapshotPath = Join-Path $repoRoot "docs\research\data\faust-design-research-snapshot.json"
$snapshotExporter = Join-Path $PSScriptRoot "export_design_research_snapshot.ps1"

& $snapshotExporter -Check
if ($LASTEXITCODE -ne 0) {
    throw "The design research snapshot is stale or invalid."
}

$requiredReportMarkers = @(
    "SG-CFG-001",
    "LOCAL-SNAPSHOT-001",
    "FAUST-DATA-001",
    "SG-TOOL-001",
    "faust-design-research-snapshot.json"
)

$reportText = Get-Content -LiteralPath $reportPath -Raw -Encoding UTF8
foreach ($marker in $requiredReportMarkers) {
    if (-not $reportText.Contains($marker)) {
        throw "Missing required report marker: $marker"
    }
}

$claimSection = [regex]::Match($reportText, '(?s)### 2\.5 .*?(?=### 2\.6 )').Value
$sourceSection = [regex]::Match($reportText, '(?s)## 14\. .*').Value
if ([string]::IsNullOrWhiteSpace($claimSection) -or [string]::IsNullOrWhiteSpace($sourceSection)) {
    throw "Could not isolate the claim or source registry."
}

function Get-RegistryIds([string]$Section) {
    return @([regex]::Matches($Section, '(?m)^\|\s*([A-Z][A-Z0-9-]+)\s*\|') | ForEach-Object {
            $_.Groups[1].Value
        })
}

$claimIds = Get-RegistryIds $claimSection
$sourceIds = Get-RegistryIds $sourceSection
if ($claimIds.Count -eq 0 -or $sourceIds.Count -eq 0) {
    throw "The claim or source registry contains no machine-readable IDs."
}
if (@($claimIds | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
    throw "The claim registry contains duplicate IDs."
}
if (@($sourceIds | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
    throw "The source registry contains duplicate IDs."
}
$collidingIds = @($claimIds | Where-Object { $sourceIds -contains $_ })
if ($collidingIds.Count -gt 0) {
    throw "Claim and source IDs must not collide: $($collidingIds -join ', ')"
}

$claimLines = @($claimSection -split "`r?`n" | Where-Object { $_ -match '^\|\s*[A-Z][A-Z0-9-]+\s*\|' })
foreach ($line in $claimLines) {
    $columns = @($line.Trim('|').Split('|'))
    if ($columns.Count -ne 6) {
        throw "Claim registry row does not have six columns: $line"
    }
    if (@('A', 'B', 'C', 'U') -notcontains $columns[3].Trim()) {
        throw "Claim registry row has an invalid evidence grade: $line"
    }
}

$sourceLines = @($sourceSection -split "`r?`n" | Where-Object { $_ -match '^\|\s*[A-Z][A-Z0-9-]+\s*\|' })
foreach ($line in $sourceLines) {
    $columns = @($line.Trim('|').Split('|'))
    if ($columns.Count -ne 5 -or @($columns | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
        throw "Source registry row is incomplete: $line"
    }
}

$requiredEntrypoints = @(
    (Join-Path $repoRoot "AGENTS.md"),
    $indexPath,
    (Join-Path $repoRoot "docs\design\fire-emblem-narrative-transformation.md"),
    (Join-Path $repoRoot "docs\design\hearthstone-battlegrounds-transformation.md"),
    (Join-Path $repoRoot "docs\design\mahjong-autobattler-common-origin.md"),
    (Join-Path $repoRoot "docs\design\p5r-mda-experience-baseline.md"),
    (Join-Path $repoRoot "docs\design\sultans-game-cognitive-load-and-automation.md"),
    (Join-Path $repoRoot "docs\design\sultans-game-narrative-transformation.md"),
    (Join-Path $repoRoot "docs\design\three-houses-campus-architecture-and-engage-contrast.md"),
    (Join-Path $repoRoot "docs\design\three-houses-p5-sultan-schedule-comparison.md"),
    (Join-Path $repoRoot "docs\design\three-houses-sultan-campus-loop-comparison.md"),
    (Join-Path $repoRoot "docs\design\unicorn-overlord-autobattle-narrative-reference.md")
)

foreach ($path in $requiredEntrypoints) {
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if (-not $text.Contains("faust-game-design-data-research.md")) {
        throw "Research report is not discoverable from: $path"
    }
}

$researchLinkedFiles = @($requiredEntrypoints | Where-Object { $_ -ne (Join-Path $repoRoot "AGENTS.md") }) + @($reportPath)
$knownRegistryIds = @($claimIds) + @($sourceIds)
foreach ($path in $researchLinkedFiles) {
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $referencedIds = @([regex]::Matches($text, '\b(?:SG|FE3H|P5R|BG|MJ|UX|NARR|FAUST|LOCAL|TEL|UO|NAB)(?:-[A-Z0-9]+)*-\d{3}\b') | ForEach-Object {
            $_.Value
        } | Sort-Object -Unique)
    $unknownIds = @($referencedIds | Where-Object { $knownRegistryIds -notcontains $_ })
    if ($unknownIds.Count -gt 0) {
        throw "Unknown research IDs in $path : $($unknownIds -join ', ')"
    }
    $linkMatches = [regex]::Matches($text, '\[[^\]]*\]\(([^)]+)\)')
    foreach ($match in $linkMatches) {
        $target = $match.Groups[1].Value.Split('#')[0]
        if ([string]::IsNullOrWhiteSpace($target) -or $target -match '^[a-zA-Z][a-zA-Z0-9+.-]*:') {
            continue
        }
        $resolvedTarget = Join-Path (Split-Path -Parent $path) $target
        if (-not (Test-Path -LiteralPath $resolvedTarget)) {
            throw "Broken local Markdown link in $path : $target"
        }
    }
}

$obsoleteName = "personified-systems-game-reference-database.md"
$obsoleteReferences = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot "docs") -Filter '*.md' -File -Recurse | Where-Object {
        (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8).Contains($obsoleteName)
    })
if ($obsoleteReferences.Count -gt 0) {
    throw "Obsolete research document is still referenced: $($obsoleteReferences.FullName -join ', ')"
}

$snapshot = Get-Content -LiteralPath $snapshotPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($null -eq $snapshot.corpus -or $null -eq $snapshot.parsing) {
    throw "Snapshot is missing the corpus or parsing section."
}
if ([string]::IsNullOrWhiteSpace([string]$snapshot.corpus.fingerprint)) {
    throw "Snapshot is missing its corpus fingerprint."
}
if ($null -eq $snapshot.corpus.input_file_count -or $null -eq $snapshot.parsing.successful_file_count) {
    throw "Snapshot is missing required file-count fields."
}
if ([int]$snapshot.parsing.error_count -ne 0) {
    throw "Snapshot contains JSON parse errors."
}
if ([int]$snapshot.parsing.successful_file_count -ne [int]$snapshot.corpus.input_file_count) {
    throw "Snapshot parsed-file count does not match its input-file count."
}

$snapshotValuesRequiredInReport = @(
    [string]$snapshot.corpus.input_file_count,
    [string]$snapshot.corpus.fingerprint,
    [string]$snapshot.rite.definition_file_count,
    [string]$snapshot.after_story.definition_file_count,
    [string]$snapshot.rite.round_zero_count,
    [string]$snapshot.rite.round_positive_count,
    [string]$snapshot.rite.auto_begin_count,
    [string]$snapshot.rite.auto_result_count,
    [string]$snapshot.rite.total_card_slot_definitions,
    [string]$snapshot.rite.total_settlement_branch_entries
)
foreach ($value in $snapshotValuesRequiredInReport) {
    if (-not $reportText.Contains($value)) {
        throw "Snapshot value is missing from the research report: $value"
    }
}

Write-Output "Design research checks passed."
Write-Output "Report: $reportPath"
Write-Output "Registered claims: $($claimIds.Count); registered sources: $($sourceIds.Count)"
Write-Output "Snapshot fingerprint: $($snapshot.corpus.fingerprint)"
