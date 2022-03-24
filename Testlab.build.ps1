<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>

using namespace Microsoft.PowerShell.Commands

[CmdletBinding()]
param(
	[Parameter(Position=0)]
    [string[]] $Tasks = @('Restore', 'Import', '.'),
    
	[ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Release', 

    [string] $DependenciesFolderPath = ".\.dependencies"
)

$Script:InformationPreference = "Continue"

# Ensure and call the InvokeBuild module.
if ([System.IO.Path]::GetFileName($MyInvocation.ScriptName) -ne 'Invoke-Build.ps1') {

    $Local:ErrorActionPreference = 'Stop'
    
	try {
		Import-Module $DependenciesFolderPath\InvokeBuild -Verbose:$VerbosePreference
	}
	catch {
        Write-Information "Bootstrap InvokeBuild"

        New-Item -ItemType Directory -Path $DependenciesFolderPath -Force | Out-Null
		Save-Module InvokeBuild -RequiredVersion "5.6.2" -Path $DependenciesFolderPath -Verbose:$VerbosePreference
        Import-Module $DependenciesFolderPath\InvokeBuild -Verbose:$VerbosePreference
    }
    
    Invoke-Build -Task $Tasks -File $MyInvocation.MyCommand.Path @PSBoundParameters
    return
    
}

# Synopsis: Hello World
task '-Hello' {

    'Hello, World!'

}

# Synopsis: Deletes the Dependencies folder
task 'Clean' {

    Write-Information "Delete Dependencies folder"
    remove $DependenciesFolderPath

}

# Synopsis: Downloads required modules to build the project
task 'Restore' Clean, {

    Write-Information "Read modules from Configuration.psd1"
    Write-Verbose "Import-PowerShellDataFile $((Resolve-Path .\Configuration.psd1).Path)"
    [ModuleSpecification[]] $RequiredModules = (Import-PowerShellDataFile .\Configuration.psd1 -Verbose:$VerbosePreference).Modules
    
    Write-Information "Ensure dependency folder"
    New-Item -ItemType Directory -Path $DependenciesFolderPath -Force | Out-Null
    
    $Policy = (Get-PSRepository PSGallery).InstallationPolicy
    Set-PSRepository PSGallery -InstallationPolicy Trusted

    try {

        Write-Information "Save modules"
        $RequiredModules | Save-Module -Path "$DependenciesFolderPath" -Repository PSGallery -Verbose:$VerbosePreference

    } finally {

        Set-PSRepository PSGallery -InstallationPolicy $Policy

    }

}

# Synopsis: Imports the Modules from the Dependencies folder
task 'Import' {

    $RequiredModules = Get-ChildItem  "$DependenciesFolderPath"
    $ImportedModules = Get-Module | Where-Object { $_.Name -in $RequiredModules.Name }

    Write-Information "Remove Modules $($ImportedModules.Name -join ', ')"
    $ImportedModules.Name | Remove-Module -ErrorAction SilentlyContinue -Verbose:$VerbosePreference

    Write-Information "Import Modules $($RequiredModules.Name -join ', ')"
    $RequiredModules.FullName | Import-Module -ErrorAction SilentlyContinue -Verbose:$VerbosePreference

}

# Synopsis: Tells the 'Restore' task to stick to the modules current versions
task 'Close-Module-Versions' Import, {
    $config = Import-PowerShellDataFile -Path .\Configuration.psd1

    if($config.Modules[0] -is [string]) {
    
        $config.Modules = Get-Module | Where-Object { $_.Name -in $config.Modules } | ForEach-Object { @{"ModuleName" = $_.Name; "RequiredVersion" = $_.Version} }

        Write-Information "Patch Configuration.psd1"
        $config | ConvertTo-Psd | Out-File .\Configuration.psd1

    } else {
        
        Write-Warning "Module Versions already closed"

    }
}

# Synopsis: Allows the 'Restore' task to load the latest version of the modules
task 'Open-Module-Versions' {
    $config = Import-PowerShellDataFile -Path .\Configuration.psd1

    if($config.Modules[0] -is [hashtable]) {

        $config.Modules = $config.Modules.ModuleName

        Write-Information "Patch Configuration.psd1"
        $config | ConvertTo-Psd | Out-File .\Configuration.psd1

    } else {

        Write-Warning "Module Versions already open"

    }
}

# Synopsis: Installs task-completion and F5 debugging experience with VSCode
task 'Install-VSCode-build-helpers' {

    Write-Information "Install InvokeBuild helper scripts"
    Install-Script -Name 'Invoke-TaskFromVSCode', 'Invoke-Build.ArgumentCompleters', 'New-VSCodeTask' -Verbose:$VerbosePreference

    if(-not(Test-Path $profile) -or -not (Select-String -Path $profile -SimpleMatch "Invoke-TaskFromVSCode.ps1" -Quiet)) {
        $helpers = @"
Register-EditorCommand -Name IB1 -DisplayName 'Invoke task' -ScriptBlock {
    Invoke-TaskFromVSCode.ps1
}

Register-EditorCommand -Name IB2 -DisplayName 'Invoke task in console' -SuppressOutput -ScriptBlock {
    Invoke-TaskFromVSCode.ps1 -Console
}

Invoke-Build.ArgumentCompleters.ps1

Set-Alias ib Invoke-Build
"@

        Write-Information "Patch `$profile script"
        Add-Content -Value $helpers -Path $profile -Verbose:$VerbosePreference

        Write-Warning "You must restart VSCode to make use of the helpers"
    }

}

task . 
