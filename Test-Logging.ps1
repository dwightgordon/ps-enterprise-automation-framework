param (
    [Parameter(Mandatory)]
    [string]$ComputerName
)

Write-Host "Starting Enterprise Baseline Evaluation..." -ForegroundColor Cyan

# Resolve project root
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import modules
Import-Module "$ProjectRoot\src\Governance\Compliance.psm1" -Force
Import-Module "$ProjectRoot\src\Observability\Logging.psm1" -Force
Import-Module "$ProjectRoot\src\Management\Baseline.psm1" -Force

Write-Host "Modules imported successfully." -ForegroundColor Green

# Execute baseline
$results = Test-NetworkBaseline -ComputerName $ComputerName

# Calculate compliance score (risk-based model)
$totalImpact = ($results.Results | Measure-Object ScoreImpact -Sum).Sum
$complianceScore = 100 + $totalImpact

if ($complianceScore -lt 0) { $complianceScore = 0 }

Write-Host ""
Write-Host "===== Compliance Summary =====" -ForegroundColor Yellow
Write-Host "ComputerName  : $ComputerName"
Write-Host "Score         : $complianceScore%"
Write-Host "Status        : $($results.ComplianceStatus)"
Write-Host "===============================" -ForegroundColor Yellow