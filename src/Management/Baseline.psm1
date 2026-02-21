# ============================================================
# Management - Baseline Module
# ============================================================

Import-Module "$PSScriptRoot\..\Observability\Logging.psm1" -Force

function Test-NetworkBaseline {

    [CmdletBinding()]
    param (
	[string]$ComputerName
	)

    Initialize-Logger
    Write-Log -Message "Network baseline test started." -Level INFO -Component "Baseline"

    try {

        $checks = @{
            IPv6Disabled     = $false
            CorrectDnsServer = $false
            TimeSyncCorrect  = $false
        }

        # Check IPv6 binding
        $ipv6 = Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        if ($ipv6 -and $ipv6.Enabled -eq $false) {
            $checks.IPv6Disabled = $true
        }

        # Check DNS server
        $dns = (Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses
        if ($dns -contains "192.168.1.10") {
            $checks.CorrectDnsServer = $true
        }

        # Check time sync source
        $timeSource = (w32tm /query /status 2>$null | Select-String "Source").ToString()
        if ($timeSource -match "DC01") {
            $checks.TimeSyncCorrect = $true
        }

        # Compliance calculation
        $totalChecks  = $checks.Count
        $passedChecks = ($checks.Values | Where-Object { $_ -eq $true }).Count
        $score        = [math]::Round(($passedChecks / $totalChecks) * 100)

        # Governance classification
        if ($score -eq 100) {
            $status = "Compliant"
        }
        elseif ($score -ge 70) {
            $status = "Partially Compliant"
        }
        else {
            $status = "Non-Compliant"
        }

        Write-Log -Message "Baseline result: Score=$score Status=$status" -Level INFO -Component "Baseline"

        return [PSCustomObject]@{
            ComputerName     = $env:COMPUTERNAME
            ComplianceScore  = "$score`%"
            ComplianceStatus = $status
            Details          = $checks
            Timestamp        = Get-Date
        }
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level ERROR -Component "Baseline"
        throw
    }
}

function Invoke-NetworkRemediation {

    [CmdletBinding(SupportsShouldProcess)]
    param ()

    Initialize-Logger
    Write-Log -Message "Network remediation started." -Level WARN -Component "Baseline"

    try {

        if (Get-NetAdapterBinding -ComponentID ms_tcpip6 | Where-Object { $_.Enabled -eq $true }) {
            Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6 -Confirm:$false
        }

        Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.1.10"

        w32tm /config /syncfromflags:domhier /update | Out-Null
        Restart-Service w32time -Force

        Write-Log -Message "Network remediation completed successfully." -Level INFO -Component "Baseline"

        Write-Output "Remediation completed."
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level ERROR -Component "Baseline"
        throw
    }
}

Export-ModuleMember -Function Test-NetworkBaseline, Invoke-NetworkRemediation

