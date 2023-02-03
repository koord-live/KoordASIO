# Powershell

# autobuild_3_copy_files: copy the built files to deploy folder

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
} elseif (!(Test-Path -Path "$koordasio_project_path")) {
    throw "non.existing koordasio_project_path: $koordasio_project_path"
} else {
    echo "koordasio_project_path is valid: $koordasio_project_path"
}
if (($koordasio_buildversionstring -eq $null) -or ($koordasio_buildversionstring -eq "")) {
    echo "expecting ""koordasio_buildversionstring"" as parameter or ENV"
    echo "using ""NoVersion"" as koordasio_buildversionstring for filenames"
    $koordasio_buildversionstring = "NoVersion"
}

###################
###  PROCEDURE  ###
###################

# Rename the files
echo "rename exe file"
$artifact_deploy_filename = "KoordASIO_${Env:koordasio_buildversionstring}_win64.exe"
echo "rename deploy file to $artifact_deploy_filename"
cp "$koordasio_project_path\Output\KoordASIO-*.exe" "$koordasio_project_path\deploy\$artifact_deploy_filename"

# echo "rename appx file"
# $winrt_artifact_deploy_filename = "koord-asio_${Env:koordasio_buildversionstring}_win.appx"
# echo "rename appx deploy file to $winrt_artifact_deploy_filename"
# cp "$koordasio_project_path\xdeploy\KoordASIO*" "$koordasio_project_path\deploy\$winrt_artifact_deploy_filename"

Function github_output_value
{
    param (
        [Parameter(Mandatory=$true)]
        [string] $name,
        [Parameter(Mandatory=$true)]
        [string] $value
    )
    
    echo "github_output_value() $name = $value"
    echo "$name=$value"
}

github_output_value -name "artifact_1" -value "$artifact_deploy_filename"
