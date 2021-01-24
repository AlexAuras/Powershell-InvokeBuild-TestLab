# Lightweight PowerShell build automation and dependency resolution script

Using the [Invoke-Build module by Roman Kuzmin](https://github.com/nightroman/Invoke-Build). \
Inspired by build scripts I found on the web (but don't remember anymore) 

This can be used as alternative to PSake + PSDepend. 

# How to build

There are several options to launch the build process: 

* Running the build script `.\Testlab.build.ps1`
* Executing `Invoke-Build`
* _Ctrl + Shift + B_
* Using [VSCode's built-in tasks](https://code.visualstudio.com/docs/editor/tasks) (Press _F1_, then type `> Tasks: Run Task`)
* F5 Debugging


# First run experience

If you do not have the Invoke-Build module installed, the build script ensures it's availability by downloading the module from [PSGallery](https://www.powershellgallery.com/). This process is called "bootstrapping". 

# Listing available build tasks

Call `Invoke-Build ?`

This will show you somehing like: 

```
Name                         Jobs         Synopsis
----                         ----         --------
-Hello                       {}           Hello World
Clean                        {}           Deletes the Dependencies folder
Restore                      {Clean, {}}  Downloads required modules to build the project
Import                       {}           Imports the Modules from the Dependencies folder
Close-Module-Versions        {Import, {}} Tells the 'Restore' task to stick to the modules current versions
Open-Module-Versions         {}           Allows the 'Restore' task to load the latest version of the modules
Install-VSCode-build-helpers {}           Installs task-completion and F5 debugging experience with VSCode
.
```

# Default Task

When launching the build with `Invoke-Build` or by using the VSCode commands the default task is executed (which in our case is doing nothing as this is just for testing). \
Nevertheless if you run [Testlab.build.ps1](Testlab.build.ps1) without specifying a task, the tasks "Restore" and "Import" are executed before the default task. This supports a smooth first run experience in which the whole system is reset to a clean initial state when the script is run without parameters. 

# Virtual Environment

Downloading the dependencies alone does not yet make sure they are loaded regardless of whether the same modules are already installed on the machine (but probably with another version). To make sure the modules are loaded preferably from the dependencies folder during development time we must add it to the _PSModulePath_. 

```PowerShell
$ProjectRoot = Resolve-Path . | Select-Object -ExpandProperty Path
Add-PathVariable "$ProjectRoot\.dependencies" -Name "PSModulePath" -Prepend
```

# Helpers

## Task-completion and F5 debugging experience with VSCode

To integrate the tasks into VSCode's built-in task system, execute the build task _Install-VSCode-build-helpers_. 

```PowerShell
Invoke-Build Install-VSCode-build-helpers
```

## Alias

Consider using the alias `ib` for `Invoke-Build` in order to reduce typing even more. Namely, in your _Microsoft.VSCode_profile.ps1_ set

```PowerShell
Set-Alias ib Invoke-Build
```

# More

More on https://github.com/nightroman/Invoke-Build/wiki