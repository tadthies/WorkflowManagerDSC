function Invoke-TestHarness
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [System.String]
        $TestResultsFile,

        [Parameter(Mandatory = $false)]
        [System.String]
        $DscTestsPath,

        [Parameter(Mandatory = $false)]
        [Switch]
        $IgnoreCodeCoverage
    )

    Write-Verbose -Message 'Commencing all OfficeOnlineServerDsc tests'

    $repoDir = Join-Path -Path $PSScriptRoot -ChildPath '..\' -Resolve

    $testCoverageFiles = @()
    if ($IgnoreCodeCoverage.IsPresent -eq $false)
    {
        Get-ChildItem -Path "$repoDir\modules\OfficeOnlineServerDsc\DSCResources\**\*.psm1" -Recurse | ForEach-Object {
            if ($_.FullName -notlike '*\DSCResource.Tests\*') 
            {
                $testCoverageFiles += $_.FullName
            }
        }
    }

    $testResultSettings = @{ }
    if ([String]::IsNullOrEmpty($TestResultsFile) -eq $false) 
    {
        $testResultSettings.Add('OutputFormat', 'NUnitXml' )
        $testResultSettings.Add('OutputFile', $TestResultsFile)
    }

    Import-Module -Name "$repoDir\modules\OfficeOnlineServerDsc\OfficeOnlineServerDsc.psd1"
    $testsToRun = @()

    # Run Unit Tests
    $versionsPath = Join-Path -Path $repoDir -ChildPath "\Tests\Unit\Stubs\"
    $versionsToTest = (Get-ChildItem -Path $versionsPath).Name
    # Import the first stub found so that there is a base module loaded before the tests start
    $firstVersion = $versionsToTest | Select-Object -First 1
    $firstStub = Join-Path -Path $repoDir `
                           -ChildPath "\Tests\Unit\Stubs\$firstVersion\OfficeWebApps.psm1"
    Import-Module $firstStub -WarningAction SilentlyContinue

    $versionsToTest | ForEach-Object -Process {
        $stubPath = Join-Path -Path $repoDir `
                              -ChildPath "\Tests\Unit\Stubs\$_\OfficeWebApps.psm1"
        $testsToRun += @(@{
            'Path' = (Join-Path -Path $repoDir -ChildPath "\Tests\Unit")
            'Parameters' = @{ 
                'WACCmdletModule' = $stubPath
            }
        })
    }

    # Integration Tests (not run in appveyor due to time/reboots needed to install SharePoint)
    #$integrationTestsPath = Join-Path -Path $repoDir -ChildPath 'Tests\Integration'
    #$testsToRun += @( (Get-ChildItem -Path $integrationTestsPath -Filter '*.Tests.ps1').FullName )

    # DSC Common Tests
    if ($PSBoundParameters.ContainsKey('DscTestsPath') -eq $true)
    {
        $testsToRun += @( $DscTestsPath )
    }

    if ($IgnoreCodeCoverage.IsPresent -eq $false)
    {
        $testResultSettings.Add('CodeCoverage', $testCoverageFiles)
    }

    $results = Invoke-Pester -Script $testsToRun -PassThru @testResultSettings

    return $results
}
