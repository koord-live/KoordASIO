# Steps for generating Windows artifacts via Github Actions
# See README.md in this folder for details.
# See windows/deploy_windows.ps1 for standalone builds.

param(
    [Parameter(Mandatory=$true)]
    [string] $Stage = "",
    # Allow buildoption to be passed for jackonwindows build, leave empty for standard (ASIO) build:
    [string] $BuildOption = "",
    # unused, only required during refactoring as long as not all platforms have been updated:
    [string] $GithubWorkspace =""
)

# Fail early on all errors
$ErrorActionPreference = "Stop"

$QtDir = 'C:\Qt'
$ChocoCacheDir = 'C:\ChocoCache'
$Qt64Version = "6.4.2"
$AqtinstallVersion = "3.0.1"
$Msvc64Version = "win64_msvc2019_64"
$JomVersion = "1.1.2"

$KoordASIOVersion = $Env:koordasio_buildversionstring
if ( $KoordASIOVersion -notmatch '^\d+\.\d+\.\d+.*' )
{
    throw "Environment variable koordasio_buildversionstring has to be set to a valid version string"
}

Function installQt
{
    param(
        [string] $QtVersion,
        [string] $QtArch
    )
    $Args = (
        "--outputdir", "$QtDir",
        "windows",
        "desktop",
        "$QtVersion",
        "$QtArch",
        "--modules", "qtmultimedia",
        "--archives", "qtbase", "qtdeclarative", "qtsvg", "qttools"
    )
    aqt install-qt @Args
    if ( !$? )
    {
        Write-Output "WARNING: Qt installation via first aqt run failed, re-starting with different base URL."
        aqt install-qt -b https://mirrors.ocf.berkeley.edu/qt/ @Args
        if ( !$? )
        {
            throw "Qt installation with args @Args failed with exit code $LastExitCode"
        }
    }

    # Above should do:
    # aqt install --outputdir C:\Qt 5.15.2 windows desktop win64_msvc2019_64

    # add vcredist and cmake - for KoordASIO build
    aqt install-tool windows desktop --outputdir C:\Qt tools_vcredist qt.tools.vcredist_msvc2019_x64
    aqt install-tool windows desktop --outputdir C:\Qt tools_cmake qt.tools.cmake

    # # add openssl 1.1
    # aqt install-tool windows desktop --outputdir C:\Qt tools_openssl_x64
}

Function ensureQt
{
    if ( Test-Path -Path $QtDir )
    {
        Write-Output "Using Qt installation from previous run (actions/cache)"
        return
    }

    Write-Output "Install Qt..."
    # Install Qt
    #   "Preparing metadata (pyproject.toml) did not run successfully."
    pip install "aqtinstall==$AqtinstallVersion" 
    if ( !$? )
    {
        throw "pip install aqtinstall failed with exit code $LastExitCode"
    }

    Write-Output "Get Qt 64 bit..."
    installQt "${Qt64Version}" "${Msvc64Version}"
}

Function ensureJom
{
    choco install --no-progress -y jom --version "${JomVersion}"
}

Function setupCodeSignCertificate
{
    # write Windows OV CodeSign cert to file
    Write-Output "Writing CodeSign cert output to file C:\KoordOVCert.pfx ..."
    $B64Cert = $Env:WINDOWS_CODESIGN_CERT
    $WindowsOVCert = [Convert]::FromBase64String($B64Cert)
    [IO.File]::WriteAllBytes('C:\KoordOVCert.pfx', $WindowsOVCert)
    ls 'C:\KoordOVCert.pfx'
    Write-Output "debug: CodeSign cert :"
    cat 'C:\KoordOVCert.pfx'

    # write Windows OV CodeSIgn cert password to file
    Write-Output "Writing CodeSign password to C:\KoordOVCertPwd ..."
    $Env:WINDOWS_CODESIGN_PWD | Out-File 'C:\KoordOVCertPwd'
    # New-Item 'C:\KoordOVCertPwd'
    # Set-Content 'C:\KoordOVCertPwd' $Env:WINDOWS_CODESIGN_PWD
    ls 'C:\KoordOVCertPwd'
    Write-Output "debug: CodeSign password :"
    cat 'C:\KoordOVCertPwd'
}

Function buildAppWithInstaller
{
    Write-Output "Build app and create installer..."
    $ExtraArgs = @()
    if ( $BuildOption -ne "" )
    {
        $ExtraArgs += ("-BuildOption", $BuildOption)
    }
    $ExtraArgs += ("-APP_BUILD_VERSION", $KoordASIOVersion)
    $ExtraArgs += ("-QtInstallPath", "C:\Qt\${$Qt64Version}")
    powershell ".\windows\deploy_windows.ps1" @ExtraArgs
    if ( !$? )
    {
        throw "deploy_windows.ps1 failed with exit code $LastExitCode"
    }
}

Function passExeArtifactToJob
{
    $artifact = "KoordASIO_${KoordASIOVersion}.exe"

    Write-Output "Copying artifact to ${artifact}"
    # "Output" is name of dir for innosetup output
    Move-Item ".\Output\KoordASIO*.exe" ".\deploy\${artifact}"
    if ( !$? )
    {
        throw "Move-Item failed with exit code $LastExitCode"
    }
    Write-Output "Setting Github step output name=artifact_1::${artifact}"
    Write-Output "artifact_1=${artifact}" >> "$Env:GITHUB_OUTPUT"
}

# Function passMsixArtifactToJob
# {
#     $artifact = "KoordASIO_${KoordASIOVersion}.msix"

#     Write-Output "Copying artifact to ${artifact}"
#     # "deploy" is dir of MakeAppx output

#     # make special dir for store upload
#     New-Item -Path  ".\publish" -ItemType Directory
#     # Copy-Item .msix artifact to publish/ dir
#     Copy-Item ".\deploy\KoordASIO.msix" ".\publish\${artifact}"

#     Move-Item ".\deploy\KoordASIO.msix" ".\deploy\${artifact}"
#     if ( !$? )
#     {
#         throw "Move-Item failed with exit code $LastExitCode"
#     }
#     Write-Output "Setting Github step output name=artifact_2::${artifact}"
#     Write-Output "artifact_2=${artifact}" >> "$Env:GITHUB_OUTPUT"
# }

switch ( $Stage )
{
    "setup"
    {
        choco config set cacheLocation $ChocoCacheDir
        ensureQt
        ensureJom

    }
    "build"
    {
        setupCodeSignCertificate
        buildAppWithInstaller
    }
    "get-artifacts"
    {
        passExeArtifactToJob
        # passMsixArtifactToJob
    }
    default
    {
        throw "Unknown stage ${Stage}"
    }
}
