#region Configuration

$Global:LogConfig = @{
    LogPath        = "C:\ProgramData\MgmtFramework\Logs"
    LogFileName    = "framework.log"
    LogLevel       = "INFO"
    EnableConsole  = $true
}

#endregion

#region Helper

function Initialize-Logger {

    if (-not (Test-Path $Global:LogConfig.LogPath)) {
        New-Item -ItemType Directory -Path $Global:LogConfig.LogPath -Force | Out-Null
    }

    $Global:LogFile = Join-Path $Global:LogConfig.LogPath $Global:LogConfig.LogFileName
}

function Get-LogLevelPriority {
    param([string]$Level)

    switch ($Level.ToUpper()) {
        "DEBUG" {1}
        "INFO"  {2}
        "WARN"  {3}
        "ERROR" {4}
        "FATAL" {5}
        default {2}
    }
}

#endregion

#region Core Logging

function Write-Log {

    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("DEBUG","INFO","WARN","ERROR","FATAL")]
        [string]$Level = "INFO",

        [string]$Component = "Core",

        [string]$CorrelationId = [guid]::NewGuid().ToString()
    )

    if ((Get-LogLevelPriority $Level) -lt (Get-LogLevelPriority $Global:LogConfig.LogLevel)) {
        return
    }

    $logEntry = [PSCustomObject]@{
        Timestamp     = (Get-Date).ToUniversalTime().ToString("o")
        Level         = $Level
        Component     = $Component
        CorrelationId = $CorrelationId
        Message       = $Message
        Host          = $env:COMPUTERNAME
        User          = $env:USERNAME
    }

    $json = $logEntry | ConvertTo-Json -Compress

    Add-Content -Path $Global:LogFile -Value $json

    if ($Global:LogConfig.EnableConsole) {
        Write-Host "$Level [$Component] $Message"
    }
}

#endregion