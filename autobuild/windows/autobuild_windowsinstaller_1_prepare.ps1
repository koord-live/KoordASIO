# Powershell

# autobuild_1_prepare: set up environment, install Qt & dependencies

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


###################
###  PROCEDURE  ###
###################

echo "Install Qt..."
# Install Qt
pip install aqtinstall
#FIXME Install branch of aqtinstall to allow tools installations while mainline is broken
# pip install git+https://github.com/miurahr/aqtinstall.git@topic-tool-latest

echo "Get Qt 64 bit..."
# intermediate solution if the main server is down: append e.g. " -b https://mirrors.ocf.berkeley.edu/qt/" to the "aqt"-line below
aqt install --outputdir C:\Qt 6.3.2 windows desktop win64_msvc2019_64 --modules qtmultimedia
# install tools - vcredist, cmake
aqt install-tool windows desktop --outputdir C:\Qt tools_vcredist qt.tools.vcredist_msvc2019_x64
aqt install-tool windows desktop --outputdir C:\Qt tools_cmake qt.tools.cmake


# echo "Get Qt WinRT 64 bit ..."
# # intermediate solution if the main server is down: append e.g. " -b https://mirrors.ocf.berkeley.edu/qt/" to the "aqt"-line below
# aqt install --outputdir C:\Qt 5.15.2 windows winrt win64_msvc2019_winrt_x64


setupCodeSignCertificate
