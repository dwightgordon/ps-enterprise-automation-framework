Initialize-Logger

Write-Log -Message "Starting VM provisioning" -Level INFO -Component "HyperV"

try {
    # provisioning code
    Write-Log -Message "VM created successfully" -Level INFO -Component "HyperV"
}
catch {
    Write-Log -Message $_.Exception.Message -Level ERROR -Component "HyperV"
}
