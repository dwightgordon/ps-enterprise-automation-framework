# ============================================================
# Logging Module - Observability Layer
# ============================================================

$Script:LogConfig = @{
    LogPath       = "C:\ProgramData\MgmtFramework\Logs"
    LogFileName   = "framework.log"
    LogLevel      = "INFO"
    EnableConsole = $true
    MaxSizeMB     = 10
}

function Invoke-LogRotation {

    if (Test-Path $Script:LogFile) {

        $sizeMB = (Get-Item $Script:LogFile).Length / 1MB

        if ($sizeMB -ge $Script:LogConfig.MaxSizeMB) {

            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $archiveFile = "$($Script:LogFile).$timestamp"

            Rename-Item -Path $Script:LogFile -NewName $archiveFile
        }
    }
}

function Initialize-Logger {

    if (-not (Test-Path $Script:LogConfig.LogPath)) {
        New-Item -ItemType Directory -Path $Script:LogConfig.LogPath -Force | Out-Null
    }

    $Script:LogFile = Join-Path $Script:LogConfig.LogPath $Script:LogConfig.LogFileName
}

function Write-Log {

    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("DEBUG","INFO","WARN","ERROR","FATAL")]
        [string]$Level = "INFO",

        [string]$Component = "Framework"
    )

    if (-not $Script:LogFile) {
        throw "Logger not initialized. Run Initialize-Logger first."
    }

    Invoke-LogRotation

    $timestamp = (Get-Date).ToUniversalTime().ToString("o")
    $logEntry = "$timestamp [$Level] [$Component] $Message"

    Add-Content -Path $Script:LogFile -Value $logEntry

    if ($Script:LogConfig.EnableConsole) {
        Write-Host $logEntry
    }
}

Export-ModuleMember -Function Initialize-Logger, Write-Log