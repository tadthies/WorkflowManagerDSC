﻿Import-Module ServiceBus -ErrorAction SilentlyContinue
Import-Module WorkflowManager -ErrorAction SilentlyContinue

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $CertAutoGenerationKey,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,
    
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $RunAsPassword,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableFirewallRules = $false,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableHttpPort = $false,

        [parameter(Mandatory = $false)]
        [System.String]
        $SBNamespace = "ServiceBus"
    )

    $result = @{}
    try {
        $WFFarm = Get-WFFarm
        $SBNamespace = Get-SBNamespace | Select-Object -First 1
        $result = @{
            Ensure = "Present"
            DatabaseServer = $WFFarm.WFFarmDBConnectionString
            CredAutoGenerationKey = $CertAutoGenerationKey
            FarmAccount = $FarmAccount
            RunAsPassword = $RunAsPassword
            EnableFirewallRules = $EnableFirewallRules
            EnableHttpPort = $EnableHttpPort
            SBNamespace = $SBNamespace.Name
        }
    }
    catch {
        $result = @{
            Ensure = "Absent"
            DatabaseServer = $DatabaseServer
            CredAutoGenerationKey = $CertAutoGenerationKey
            FarmAccount = $FarmAccount
            RunAsPassword = $RunAsPassword
            EnableFirewallRules = $EnableFirewallRules
            EnableHttpPort = $EnableHttpPort
            SBNamespace = $SBNamespace
        }
    }

    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $CertAutoGenerationKey,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $RunAsPassword,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableFirewallRules = $false,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableHttpPort = $false,

        [parameter(Mandatory = $false)]
        [System.String]
        $SBNamespace = "ServiceBus"
    )
    
    $dbConnstring = "data source=" + $DatabaseServer + ";integrated security=true"

    New-SBFarm -SBFarmDBConnectionString $dbConnstring `
        -CertificateAutoGenerationKey $CertAutoGenerationKey.Password

    Add-SBHost -SBFarmDBConnectionString $dbConnstring `
        -RunAsPassword $RunAsPassword.Password `
        -EnableFirewallRules $EnableFirewallRules `
        -CertificateAutoGenerationKey $CertAutoGenerationKey.Password

    New-SBNamespace -Name $SBNamespace `
        -ManageUsers $FarmAccount.UserName

    New-WFFarm -WFFarmDBConnectionString $dbConnstring `
        -CertificateAutoGenerationKey $CertAutoGenerationKey.Password

    $SBConfig = Get-SBClientConfiguration -Namespaces $SBNamespace

    Add-WFHost -WFFarmDBConnectionString $dbConnstring `
        -RunAsPassword $RunasPassword.Password `
        -EnableFirewallRules $EnableFirewallRules `
        -EnableHttpPort $EnableHttpPort `
        -CertificateAutoGenerationKey $CertAutoGenerationKey.Password `
        -SBClientConfiguration $SBConfig
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $CertAutoGenerationKey,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $RunAsPassword,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableFirewallRules = $false,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableHttpPort = $false,

        [parameter(Mandatory = $false)]
        [System.String]
        $SBNamespace = "ServiceBus"
    )
    
    Write-Verbose -Message "Testing for presence of the Workflow Manager farm"
    $result = Get-TargetResource @PSBoundParameters

    return ($result.Ensure -eq $Ensure)
}

Export-ModuleMember -Function *-TargetResource
