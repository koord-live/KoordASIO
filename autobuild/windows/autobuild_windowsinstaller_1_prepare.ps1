# Powershell

# autobuild_1_prepare: set up environment, install Qt & dependencies


###################
###  PROCEDURE  ###
###################

echo "Install Qt..."
# Install Qt
pip install aqtinstall
echo "Get Qt 64 bit..."
# intermediate solution if the main server is down: append e.g. " -b https://mirrors.ocf.berkeley.edu/qt/" to the "aqt"-line below
aqt install --outputdir C:\Qt 5.15.2 windows desktop win64_msvc2019_64
aqt tool --outputdir C:\Qt windows tools_cmake 3.19.2-202101071154 qt.tools.cmake.win64
# aqt tool windows tools_vcredist 2020-05-19-1  qt.tools.vcredist_msvc2019_x64

# echo "Get Qt 32 bit..."
# # intermediate solution if the main server is down: append e.g. " -b https://mirrors.ocf.berkeley.edu/qt/" to the "aqt"-line below
# aqt install --outputdir C:\Qt 5.15.2 windows desktop win32_msvc2019
# aqt tool --outputdir C:\Qt   windows tools_cmake 3.19.2-202101071154 qt.tools.cmake.win32
# # aqt tool windows tools_vcredist 2020-05-19-1  qt.tools.vcredist_msvc2019_x32

# echo "Get Qt WinRT 64 bit ..."
# # intermediate solution if the main server is down: append e.g. " -b https://mirrors.ocf.berkeley.edu/qt/" to the "aqt"-line below
# aqt install --outputdir C:\Qt 5.15.2 windows winrt win64_msvc2019_winrt_x64
