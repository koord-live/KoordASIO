# Powershell

# autobuild_2_build: actual build process


####################
###  PARAMETERS  ###
####################

# Get the source path via parameter
param (
    [string] $koordasio_project_path = $Env:koordasio_project_path,
    [string] $koordasio_buildversionstring = $Env:koordasio_buildversionstring
)
# Sanity check of parameters
if (("$koordasio_project_path" -eq $null) -or ("$koordasio_project_path" -eq "")) {
    throw "expecting ""koordasio_project_path"" as parameter or ENV"
} elseif (!(Test-Path -Path $koordasio_project_path)) {
    throw "non.existing koordasio_project_path: $koordasio_project_path"
} else {
    echo "koordasio_project_path is valid: $koordasio_project_path"
}


###################
###  PROCEDURE  ###
###################

echo "Build installer..."
# Build the installer
$ExtraArgs += ("-APP_BUILD_VERSION", $Env:koordasio_buildversionstring)
powershell "$koordasio_project_path\windows\deploy_windows.ps1" @ExtraArgs
