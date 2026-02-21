# ============================================================
# Management - Baseline Module
# ============================================================

Import-Module "$PSScriptRoot\..\Observability\Logging.psm1" -Force
Import-Module "$PSScriptRoot\..\Governance\Compliance.psm1" -Force

function Test-NetworkBaseline {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Initialize-Logger
    Write-Log -Message "Network baseline test started for $ComputerName." -Level INFO -Component "Baseline"

    $results = @()

    try {

        # =====================================================
        # 1. IPv6 Disabled Check
        # =====================================================
        $ipv6 = Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        $ipv6Disabled = ($ipv6 -and $ipv6.Enabled -eq $false)

        $results += [PSCustomObject]@{
            ComputerName = $ComputerName
            ControlName  = "IPv6Disabled"
            Category     = "Network"
            DesiredState = "Disabled"
            ActualState  = if ($ipv6Disabled) { "Disabled" } else { "Enabled" }
            IsCompliant  = $ipv6Disabled
            Severity     = "Medium"
            ScoreImpact  = Get-ScoreImpact -Severity "Medium" -IsCompliant $ipv6Disabled
            Timestamp    = Get-Date
        }

        # =====================================================
        # 2. Correct DNS Server Check
        # =====================================================
        $dns = (Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
        $correctDns = ($dns -contains "192.168.1.10")

        $results += [PSCustomObject]@{
            ComputerName = $ComputerName
            ControlName  = "CorrectDnsServer"
            Category     = "Network"
            DesiredState = "192.168.1.10"
            ActualState  = ($dns -join ", ")
            IsCompliant  = $correctDns
            Severity     = "High"
            ScoreImpact  = Get-ScoreImpact -Severity "High" -IsCompliant $correctDns
            Timestamp    = Get-Date
        }

        # =====================================================
        # 3. Time Synchronization Check
        # =====================================================
        $timeSource = (w32tm /query /status 2>$null | Select-String "Source").ToString()
        $timeCorrect = ($timeSource -match "DC01")

        $results += [PSCustomObject]@{
            ComputerName = $ComputerName
            ControlName  = "TimeSyncCorrect"
            Category     = "Network"
            DesiredState = "DC01"
            ActualState  = $timeSource
            IsCompliant  = $timeCorrect
            Severity     = "High"
            ScoreImpact  = Get-ScoreImpact -Severity "High" -IsCompliant $timeCorrect
            Timestamp    = Get-Date
        }

        Write-Log -Message "Network baseline evaluation completed for $ComputerName." -Level INFO -Component "Baseline"

        return $results
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level ERROR -Component "Baseline"
        throw
    }
}
