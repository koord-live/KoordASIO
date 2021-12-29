# Powershell

# autobuild_1_prepare: set up environment, install Qt & dependencies


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
aqt install --outputdir C:\Qt 5.15.2 windows desktop win64_msvc2019_64
# install tools - vcredist, cmake
aqt tool windows desktop --outputdir C:\Qt tools_vcredist qt.tools.vcredist_msvc2019_x64
aqt tool windows desktop --outputdir C:\Qt tools_cmake qt.tools.cmake.win64


# echo "Get Qt 32 bit..."
# # intermediate solution if the main server is down: append e.g. " -b https://mirrors.ocf.berkeley.edu/qt/" to the "aqt"-line below
# aqt install --outputdir C:\Qt 5.15.2 windows desktop win32_msvc2019
# aqt tool --outputdir C:\Qt   windows tools_cmake 3.19.2-202101071154 qt.tools.cmake.win32
# # aqt tool windows tools_vcredist 2020-05-19-1  qt.tools.vcredist_msvc2019_x32

# echo "Get Qt WinRT 64 bit ..."
# # intermediate solution if the main server is down: append e.g. " -b https://mirrors.ocf.berkeley.edu/qt/" to the "aqt"-line below
# aqt install --outputdir C:\Qt 5.15.2 windows winrt win64_msvc2019_winrt_x64
