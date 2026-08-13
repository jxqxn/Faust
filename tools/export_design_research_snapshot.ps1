param(
    [string]$CorpusRoot = '',
    [string]$OutputPath = '',
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($CorpusRoot)) {
    $CorpusRoot = Join-Path (Split-Path -Parent $repoRoot) 'Faust-local-source\_unpack\data\config'
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repoRoot 'docs\research\data\faust-design-research-snapshot.json'
}

$riteRoot = Join-Path $CorpusRoot 'rite'
$afterStoryRoot = Join-Path $CorpusRoot 'after_story'
foreach ($requiredPath in @($riteRoot, $afterStoryRoot)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Container)) {
        throw "Required corpus directory not found: $requiredPath"
    }
}

function Get-JsonFiles([string]$Root) {
    return @(Get-ChildItem -LiteralPath $Root -Filter '*.json' -File | Sort-Object Name)
}

function Get-ObjectPropertyCount($Value) {
    if ($null -eq $Value) {
        return 0
    }
    return @($Value.PSObject.Properties).Count
}

function Get-ArrayCount($Value) {
    if ($null -eq $Value) {
        return 0
    }
    return @($Value).Count
}

function Get-CorpusFingerprint([System.IO.FileInfo[]]$Files, [string]$Root) {
    $resolvedRoot = (Get-Item -LiteralPath $Root).FullName.TrimEnd('\', '/')
    $records = foreach ($file in $Files) {
        if (-not $file.FullName.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Input file is outside corpus root: $($file.FullName)"
        }
        $relativePath = $file.FullName.Substring($resolvedRoot.Length).TrimStart('\', '/').Replace('\', '/')
        $fileHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$relativePath`t$fileHash"
    }
    $payload = [System.Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($payload))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

$parseErrors = [System.Collections.Generic.List[object]]::new()
$riteRows = [System.Collections.Generic.List[object]]::new()
$riteFiles = Get-JsonFiles $riteRoot
foreach ($file in $riteFiles) {
    try {
        $definition = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $slotCount = Get-ObjectPropertyCount $definition.cards_slot
        $branchCount = (Get-ArrayCount $definition.settlement_prior) +
            (Get-ArrayCount $definition.settlement) +
            (Get-ArrayCount $definition.settlement_extre)
        $riteRows.Add([pscustomobject][ordered]@{
            file = $file.Name
            id = $definition.id
            name = $definition.name
            round_number = [int]$definition.round_number
            auto_begin = [int]$definition.auto_begin
            auto_result = [int]$definition.auto_result
            slot_count = $slotCount
            settlement_branch_count = $branchCount
        })
    }
    catch {
        $parseErrors.Add([pscustomobject][ordered]@{
            area = 'rite'
            file = $file.Name
            error = $_.Exception.Message
        })
    }
}

$afterStoryRows = [System.Collections.Generic.List[object]]::new()
$afterStoryFiles = Get-JsonFiles $afterStoryRoot
foreach ($file in $afterStoryFiles) {
    try {
        $definition = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $afterStoryRows.Add([pscustomobject][ordered]@{
            file = $file.Name
            id = $definition.id
            name = $definition.name
            prior_entry_count = Get-ArrayCount $definition.prior
            extra_entry_count = Get-ArrayCount $definition.extra
        })
    }
    catch {
        $parseErrors.Add([pscustomobject][ordered]@{
            area = 'after_story'
            file = $file.Name
            error = $_.Exception.Message
        })
    }
}

$allInputFiles = @($riteFiles) + @($afterStoryFiles)
$slotHistogram = [ordered]@{}
$riteRows | Group-Object slot_count | Sort-Object { [int]$_.Name } | ForEach-Object {
    $slotHistogram[$_.Name] = $_.Count
}

$snapshot = [ordered]@{
    schema_version = 1
    snapshot_date = '2026-08-13'
    generator = 'tools/export_design_research_snapshot.ps1'
    corpus = [ordered]@{
        logical_root = 'Faust-local-source/_unpack/data/config'
        included_directories = @('rite', 'after_story')
        fingerprint_algorithm = 'sha256(relative_path + tab + file_sha256, newline joined, sorted by file name within each directory)'
        fingerprint = Get-CorpusFingerprint $allInputFiles $CorpusRoot
        input_file_count = $allInputFiles.Count
    }
    parsing = [ordered]@{
        successful_file_count = $riteRows.Count + $afterStoryRows.Count
        error_count = $parseErrors.Count
        errors = @($parseErrors)
    }
    rite = [ordered]@{
        definition_file_count = $riteFiles.Count
        parsed_definition_count = $riteRows.Count
        round_zero_count = @($riteRows | Where-Object round_number -eq 0).Count
        round_positive_count = @($riteRows | Where-Object round_number -ge 1).Count
        auto_begin_count = @($riteRows | Where-Object auto_begin -eq 1).Count
        auto_result_count = @($riteRows | Where-Object auto_result -eq 1).Count
        total_card_slot_definitions = ($riteRows.slot_count | Measure-Object -Sum).Sum
        definitions_with_card_slots = @($riteRows | Where-Object slot_count -gt 0).Count
        maximum_slots_in_one_definition = ($riteRows.slot_count | Measure-Object -Maximum).Maximum
        slot_count_histogram = $slotHistogram
        total_settlement_branch_entries = ($riteRows.settlement_branch_count | Measure-Object -Sum).Sum
        definitions_with_settlement_branches = @($riteRows | Where-Object settlement_branch_count -gt 0).Count
        maximum_settlement_branches_in_one_definition = ($riteRows.settlement_branch_count | Measure-Object -Maximum).Maximum
        maximum_slot_definitions = @($riteRows | Sort-Object -Property @(
                @{ Expression = 'slot_count'; Descending = $true },
                @{ Expression = 'file'; Descending = $false }
            ) | Select-Object -First 5)
        maximum_branch_definitions = @($riteRows | Sort-Object -Property @(
                @{ Expression = 'settlement_branch_count'; Descending = $true },
                @{ Expression = 'file'; Descending = $false }
            ) | Select-Object -First 5)
    }
    after_story = [ordered]@{
        definition_file_count = $afterStoryFiles.Count
        parsed_definition_count = $afterStoryRows.Count
        total_prior_entries = ($afterStoryRows.prior_entry_count | Measure-Object -Sum).Sum
        total_extra_entries = ($afterStoryRows.extra_entry_count | Measure-Object -Sum).Sum
        definitions_with_prior_entries = @($afterStoryRows | Where-Object prior_entry_count -gt 0).Count
        definitions_with_extra_entries = @($afterStoryRows | Where-Object extra_entry_count -gt 0).Count
    }
    interpretation_guard = @(
        'Counts describe static configuration definitions, not runtime instances or player-visible content.',
        'auto_begin and auto_result are configuration fields and do not independently prove runtime timing.',
        'after_story entry counts are conditional text entries, not a count of mutually exclusive player endings.'
    )
}

$json = $snapshot | ConvertTo-Json -Depth 10
if ($Check) {
    if (-not (Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
        throw "Snapshot does not exist: $OutputPath"
    }
    $existing = Get-Content -LiteralPath $OutputPath -Raw -Encoding UTF8
    if ($existing.TrimEnd() -ne $json.TrimEnd()) {
        throw "Snapshot is stale. Run tools/export_design_research_snapshot.ps1 and review the diff."
    }
    Write-Output "Design research snapshot is current: $OutputPath"
    exit 0
}

$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
Write-Output "Wrote design research snapshot: $OutputPath"
