function Test-NetworkBaseline {

    [CmdletBinding()]
    param ()

    $result = [PSCustomObject]@{
        ComputerName      = $env:COMPUTERNAME
        IPv6Disabled      = $false
        CorrectDnsServer  = $false
        TimeSyncCorrect   = $false
        Timestamp         = Get-Date
    }

    # Check IPv6 binding
    $ipv6 = Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    if ($ipv6.Enabled -eq $false) {
        $result.IPv6Disabled = $true
    }

    # Check DNS server
    $dns = (Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses
    if ($dns -contains "192.168.1.10") {
        $result.CorrectDnsServer = $true
    }

    # Check time sync source
    $timeSource = (w32tm /query /status 2>$null | Select-String "Source").ToString()
    if ($timeSource -match "DC01") {
        $result.TimeSyncCorrect = $true
    }

    return $result
}
