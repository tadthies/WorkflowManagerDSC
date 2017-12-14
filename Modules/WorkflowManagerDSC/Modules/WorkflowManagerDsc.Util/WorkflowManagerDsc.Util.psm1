<#
.SYNOPSIS

This cmdlet determines the version number of Office Web Apps that is installed locally

#>
function Get-WmfDscInstalledProductVersion
{
    [CmdletBinding()]
    [OutputType([Version])]
    param()

    return Get-ItemProperty 'HKLM:\Software\Microsoft\Workflow Manager\*' | `
        Select-Object Version | `
        ForEach-Object -Process {
            return [Version]::Parse($_.Version)
        } | Select-Object -First 1
}

Export-ModuleMember -Function *
