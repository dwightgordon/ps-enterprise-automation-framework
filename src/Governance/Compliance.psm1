$Script:SeverityMap = @{
    Low		= -5
    Medium 	= -10
    High	= -20
    Critical	= -40
}

function Get-ScoreImpact {
    param (
        [string]$Severity,
        [bool]$IsCompliant
    )
    if ($IsCompliant) {
        return 0
    }
    if (-not $Script:SeverityMap.contsinskey($Severity)) {
        throw "Invalid severity value: $Severity"
    }
    return $Script:SeverityMap[$Severity]
}
