[CmdletBinding()]
param(
    [string[]]$ConfigPath = @(
        (Join-Path $PSScriptRoot 'wsl-dev.dsc.yaml'),
        (Join-Path $PSScriptRoot 'tools.dsc.yaml'),
        (Join-Path $PSScriptRoot 'shells.dsc.yaml')
    ),
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

$resources = @()
foreach ($path in $ConfigPath) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        [Console]::Error.WriteLine("DSC configuration not found: $path")
        exit 2
    }

    $json = & dsc --progress-format none config test --file $path --output-format json
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("dsc config test failed for ${path} with exit code $LASTEXITCODE")
        exit 2
    }

    try {
        $result = ($json -join "`n") | ConvertFrom-Json -ErrorAction Stop
    } catch {
        [Console]::Error.WriteLine("Could not parse DSC output for ${path}: $_")
        exit 2
    }

    if ($result.hadErrors) {
        [Console]::Error.WriteLine("DSC reported errors for ${path}:")
        $result.messages | ForEach-Object { [Console]::Error.WriteLine(($_ | Out-String)) }
        exit 2
    }

    $resources += @($result.results)
}

$drift = @($resources | Where-Object { -not $_.result.inDesiredState })

if ($Quiet) {
    if ($drift.Count -eq 0) {
        "OK: $($resources.Count) resources in desired state"
    } else {
        $drift | Select-Object name, @{ Name = 'Difference'; Expression = { $_.result.differingProperties -join ', ' } } | Format-Table -AutoSize
    }
} else {
    $resources | Select-Object `
        @{ Name = 'State'; Expression = { if ($_.result.inDesiredState) { 'OK' } else { 'DRIFT' } } }, `
        name, `
        @{ Name = 'Installed'; Expression = { $_.result.actualState.version } } |
        Format-Table -AutoSize
}

if ($drift.Count -gt 0) {
    exit 1
}
