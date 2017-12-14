[CmdletBinding()]
param(
    [String] $WACCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\1.0\WorkflowManager.psm1" -Resolve)
)

$Script:DSCModuleName      = 'WorkflowManagerDsc'
$Script:DSCResourceName    = 'MSFT_WorkflowManagerInstall'
$Global:CurrentWACCmdletModule = $WACCmdletModule

[String] $moduleRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\Modules\WorkflowManagerDsc" -Resolve
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Script:DSCModuleName `
    -DSCResourceName $Script:DSCResourceName `
    -TestType Unit 

try
{
    InModuleScope $Script:DSCResourceName {
        Describe "WorkflowManagerInstall [WAC server version $((Get-Item $Global:CurrentWACCmdletModule).Directory.BaseName)]" {

            Import-Module (Join-Path $PSScriptRoot "..\..\..\Modules\WorkflowManagerDsc" -Resolve)
            #Remove-Module -Name "WorkflowManager" -Force -ErrorAction SilentlyContinue
            Import-Module $Global:CurrentWACCmdletModule -WarningAction SilentlyContinue 

            Context "Office online server is not installed, but should be" {
                $testParams = @{
                    Ensure = "Present"
                    WebPIPath = "C:/WFFiles/bin/WebPICmd.exe"
                    XMLFeedPath "C:/WFFiles/Feeds/Latest/webproductlist.xml"
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }
                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                It "Returns that it is not installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Returns false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Starts the install from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context "Workflow Manager is installed and should be" {
                $testParams = @{
                    Ensure = "Present"
                    WebPIPath = "C:/WFFiles/bin/WebPICmd.exe"
                    XMLFeedPath "C:/WFFiles/Feeds/Latest/webproductlist.xml"
                }

                Mock Get-ChildItem -MockWith {
                    return @(
                        @{
                            Name = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Workflow Manager"
                        }
                    )
                }

                It "Returns that it is installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Returns true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }           
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
