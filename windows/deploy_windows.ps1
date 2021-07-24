param(
    # Replace default path with system Qt installation folder if necessary
    [string] $QtPath = "C:\Qt",
    [string] $QtInstallPath = "C:\Qt\5.15.2",
    [string] $QtCompile32 = "msvc2019",
    [string] $QtCompile64 = "msvc2019_64",
    [string] $AsioSDKName = "ASIOSDK2.3.2",
    [string] $AsioSDKUrl = "https://www.steinberg.net/sdk_downloads/ASIOSDK2.3.2.zip",
    [string] $InnoSetupUrl = "https://jrsoftware.org/download.php/is.exe",
    [string] $InnoSetupIsccPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    [string] $VsDistFile64Redist = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Redist\",
    [string] $VsDistFile64Path = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Redist\MSVC\14.29.30036\x64\Microsoft.VC142.CRT"
)

# change directory to the directory above (if needed)
Set-Location -Path "$PSScriptRoot\..\"

# Global constants
$RootPath = "$PWD"
$BuildPath = "$RootPath\build"
$DeployPath = "$RootPath\deploy"
$WindowsPath ="$RootPath\windows"
$AppName = "KoordASIO"

# Stop at all errors
$ErrorActionPreference = "Stop"


# Execute native command with errorlevel handling
Function Invoke-Native-Command {
    Param(
        [string] $Command,
        [string[]] $Arguments
    )

    & "$Command" @Arguments

    if ($LastExitCode -Ne 0)
    {
        Throw "Native command $Command returned with exit code $LastExitCode"
    }
}

# Cleanup existing build folders
Function Clean-Build-Environment
{
    if (Test-Path -Path $BuildPath) { Remove-Item -Path $BuildPath -Recurse -Force }
    if (Test-Path -Path $DeployPath) { Remove-Item -Path $DeployPath -Recurse -Force }

    New-Item -Path $BuildPath -ItemType Directory
    New-Item -Path $DeployPath -ItemType Directory
}

# For sourceforge links we need to get the correct mirror (especially NISIS) Thanks: https://www.powershellmagazine.com/2013/01/29/pstip-retrieve-a-redirected-url/
Function Get-RedirectedUrl {

    Param (
        [Parameter(Mandatory=$true)]
        [String]$URL
    )

    $request = [System.Net.WebRequest]::Create($url)
    $request.AllowAutoRedirect=$false
    $response=$request.GetResponse()

    if ($response.StatusCode -eq "Found")
    {
        $response.GetResponseHeader("Location")
    }
}

function Initialize-Module-Here ($m) { # see https://stackoverflow.com/a/51692402

    # If module is imported say that and do nothing
    if (Get-Module | Where-Object {$_.Name -eq $m}) {
        Write-Output "Module $m is already imported."
    }
    else {

        # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
            Import-Module $m
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
                Install-Module -Name $m -Force -Verbose -Scope CurrentUser
                Import-Module $m
            }
            else {

                # If module is not imported, not available and not in online gallery then abort
                Write-Output "Module $m not imported, not available and not in online gallery, exiting."
                EXIT 1
            }
        }
    }
}

# Download and uncompress dependency in ZIP format
Function Install-Dependency
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $Uri,
        [Parameter(Mandatory=$true)]
        [string] $Name,
        [Parameter(Mandatory=$true)]
        [string] $Destination
    )

    if (Test-Path -Path "$WindowsPath\$Destination") { return }

    $TempFileName = [System.IO.Path]::GetTempFileName() + ".zip"
    $TempDir = [System.IO.Path]::GetTempPath()

    if ($Uri -Match "downloads.sourceforge.net")
    {
      $Uri = Get-RedirectedUrl -URL $Uri
    }

    Invoke-WebRequest -Uri $Uri -OutFile $TempFileName
    echo $TempFileName
    Expand-Archive -Path $TempFileName -DestinationPath $TempDir -Force
    echo $WindowsPath\$Destination
    Move-Item -Path "$TempDir\$Name" -Destination "$WindowsPath\$Destination" -Force
    Remove-Item -Path $TempFileName -Force
}

# Install VSSetup (Visual Studio detection), ASIO SDK and NSIS Installer
Function Install-Dependencies
{
    if (-not (Get-PackageProvider -Name nuget).Name -eq "nuget") {
      Install-PackageProvider -Name "Nuget" -Scope CurrentUser -Force
    }
    Initialize-Module-Here -m "VSSetup"
    Install-Dependency -Uri $AsioSDKUrl `
        -Name $AsioSDKName -Destination "ASIOSDK2"

    # assuming Powershell3, install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force; iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex
    # now install Innosetup
    choco install innosetup
}

# Setup environment variables and build tool paths
Function Initialize-Build-Environment
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $QtInstallPath,
        [Parameter(Mandatory=$true)]
        [string] $BuildArch
    )

    # Look for Visual Studio/Build Tools 2017 or later (version 15.0 or above)
    $VsInstallPath = Get-VSSetupInstance | `
        Select-VSSetupInstance -Product "*" -Version "15.0" -Latest | `
        Select-Object -ExpandProperty "InstallationPath"

    if ($VsInstallPath -Eq "") { $VsInstallPath = "<N/A>" }

    if ($BuildArch -Eq "x86_64")
    {
        $VcVarsBin = "$VsInstallPath\VC\Auxiliary\build\vcvars64.bat"
        $QtMsvcSpecPath = "$QtInstallPath\$QtCompile64\bin"
    }
    else
    {
        $VcVarsBin = "$VsInstallPath\VC\Auxiliary\build\vcvars32.bat"
        $QtMsvcSpecPath = "$QtInstallPath\$QtCompile32\bin"
    }

    # Setup Qt executables paths for later calls
    Set-Item Env:QtQmakePath "$QtMsvcSpecPath\qmake.exe"
    Set-Item Env:QtCmakePath  "$QtPath\Tools\CMake_64\bin\cmake.exe"
    Set-Item Env:QtCmakePath  "C:\Qt\Tools\CMake_64\bin\cmake.exe"
    Set-Item Env:QtWinDeployPath "$QtMsvcSpecPath\windeployqt.exe"

    ""
    "**********************************************************************"
    "Using Visual Studio/Build Tools environment settings located at"
    $VcVarsBin
    "**********************************************************************"
    ""
    "**********************************************************************"
    "Using Qt binaries for Visual C++ located at"
    $QtMsvcSpecPath
    "**********************************************************************"
    ""

    if (-Not (Test-Path -Path $VcVarsBin))
    {
        Throw "Microsoft Visual Studio ($BuildArch variant) is not installed. " + `
            "Please install Visual Studio 2017 or above it before running this script."
    }

    if (-Not (Test-Path -Path $Env:QtQmakePath))
    {
        Throw "The Qt binaries for Microsoft Visual C++ 2017 or above could not be located at $QtMsvcSpecPath. " + `
            "Please install Qt with support for MSVC 2017 or above before running this script," + `
            "then call this script with the Qt install location, for example C:\Qt\5.15.2"
    }

    if (-Not (Test-Path -Path $Env:QtCmakePath))
    {
        Throw "The Qt binaries for CMake for Microsoft Visual C++ 2017 or above could not be located at $QtPath. " + `
            "Please install Qt with support for MSVC 2017 or above before running this script," + `
            "then call this script with the Qt install location, for example C:\Qt\5.15.2"
    }

    # Import environment variables set by vcvarsXX.bat into current scope
    $EnvDump = [System.IO.Path]::GetTempFileName()
    Invoke-Native-Command -Command "cmd" `
        -Arguments ("/c", "`"$VcVarsBin`" && set > `"$EnvDump`"")

    foreach ($_ in Get-Content -Path $EnvDump)
    {
        if ($_ -Match "^([^=]+)=(.*)$")
        {
            Set-Item "Env:$($Matches[1])" $Matches[2]
        }
    }

    Remove-Item -Path $EnvDump -Force
}

# Build KoordASIO x86_64 and x86
Function Build-App
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $BuildConfig,
        [Parameter(Mandatory=$true)]
        [string] $BuildArch
    )

    # Build kdasioconfig Qt project with CMake / nmake
    Invoke-Native-Command -Command "$Env:QtCmakePath" `
        -Arguments ("-DCMAKE_PREFIX_PATH='$QtInstallPath\$QtCompile64\lib\cmake'", `
            "-DCMAKE_BUILD_TYPE=Release", `
            "-S", "$RootPath\src\kdasioconfig", `
            "-B", "$BuildPath\$BuildConfig\kdasioconfig", `
            "-G", "NMake Makefiles")
    Set-Location -Path "$BuildPath\$BuildConfig\kdasioconfig"
    # Invoke-Native-Command -Command "nmake" -Arguments ("$BuildConfig")
    Invoke-Native-Command -Command "nmake"

    # Build FlexASIO dlls with CMake / nmake
    Invoke-Native-Command -Command "$Env:QtCmakePath" `
        -Arguments ("-DCMAKE_PREFIX_PATH='$QtInstallPath\$QtCompile64\lib\cmake:$RootPath\src\dechamps_cpputil:$RootPath\src\dechamps_ASIOUtil'", `
            "-DCMAKE_BUILD_TYPE=Release", `
            "-S", "$RootPath\src", `
            "-B", "$BuildPath\$BuildConfig\flexasio", `
            "-G", "NMake Makefiles")
    Set-Location -Path "$BuildPath\$BuildConfig\flexasio"
    Invoke-Native-Command -Command "nmake"

    # Collect necessary Qt dlls for kdasioconfig
    Invoke-Native-Command -Command "$Env:QtWinDeployPath" `
        -Arguments ("--$BuildConfig", "--no-compiler-runtime", "--dir=$DeployPath\$BuildArch", `
        "--no-system-d3d-compiler",  "--no-opengl-sw", `
        "$BuildPath\$BuildConfig\kdasioconfig\kdasioconfig.exe")

    Tree "$VsDistFile64Redist" /a

    # Transfer VS dist DLLs for x64
    Copy-Item -Path "$VsDistFile64Path\*" -Destination "$DeployPath\$BuildArch"

    # all build files:
        # kdasioconfig files inc qt dlls now in 
            # D:/a/KoordASIO/KoordASIO/deploy/x86_64/
                # - kdasioconfig.exe
                # all qt dlls etc ...
        # flexasio files in:
            # D:\a\KoordASIO\KoordASIO\build\flexasio\install\bin
                # - FlexASIO.dll
                # - portaudio_x64.dll 

    # Move kdasioconfig.exe to deploy dir
    Move-Item -Path "$BuildPath\$BuildConfig\kdasioconfig\kdasioconfig.exe" -Destination "$DeployPath\$BuildArch" -Force
    # Move 2 x FlexASIO dlls to deploy dir, rename DLL here for separation
    Move-Item -Path "$BuildPath\$BuildConfig\flexasio\install\bin\KoordASIO.dll" -Destination "$DeployPath\$BuildArch" -Force
    Move-Item -Path "$BuildPath\$BuildConfig\flexasio\install\bin\portaudio_x64.dll" -Destination "$DeployPath\$BuildArch" -Force
    # move InnoSetup script to deploy dir
    Move-Item -Path "$WindowsPath\kdinstaller.iss" -Destination "$RootPath" -Force

    Get-ChildItem -Recurse $RootPath

    Invoke-Native-Command -Command "nmake" -Arguments ("clean")
    Set-Location -Path $RootPath

}

# Build and deploy KoordASIO 64bit and 32bit variants
function Build-App-Variants
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $QtInstallPath
    )

    # foreach ($_ in ("x86_64", "x86"))
    foreach ($_ in ("x86_64")) # only build x64 now
    {
        $OriginalEnv = Get-ChildItem Env:
        Initialize-Build-Environment -QtInstallPath $QtInstallPath -BuildArch $_
        Build-App -BuildConfig "release" -BuildArch $_
        $OriginalEnv | % { Set-Item "Env:$($_.Name)" $_.Value }
    }
}

# Build Windows installer
Function Build-Installer
{
    foreach ($_ in Get-Content -Path "$RootPath\kdASIOVersion.txt")
    {
        if ($_ -Match "^VERSION *= *(.*)$")
        {
            $AppVersion = $Matches[1]
            break
        }
    }

    # Invoke-Native-Command -Command "$WindowsPath\NSIS\makensis" `
    #     -Arguments ("/v4", "/DAPP_NAME=$AppName", "/DAPP_VERSION=$AppVersion", `
    #     "/DROOT_PATH=$RootPath", "/DWINDOWS_PATH=$WindowsPath", "/DDEPLOY_PATH=$DeployPath", `
    #     "$WindowsPath\installer.nsi")

    #FIXME for 64bit build only
    Set-Location -Path "$RootPath"
    # /Program Files (x86)/Inno Setup 6/ISCC.exe
    Invoke-Native-Command -Command "${InnoSetupIsccPath}" `
        -Arguments ("$RootPath\kdinstaller.iss", `
         "/FKoordASIO-${AppVersion}")

}


Clean-Build-Environment
Install-Dependencies
Build-App-Variants -QtInstallPath $QtInstallPath
Build-Installer
