# KoordASIO Developer Information

See `LICENSE.txt` for licensing information. In particular, do note that
specific license terms apply to the ASIO trademark and ASIO SDK.

## Building

KoordASIO is designed to be built using CMake within the Microsoft Visual C++
2019 toolchain native CMake support.

KoordASIO uses a CMake "superbuild" system (in `/src`) to automatically build the
dependencies (most notably [PortAudio][]) before building FlexASIO itself. These
dependencies are pulled in as git submodules.

The build is carried out automatically via Github Actions.
See .github/workflows/autobuild.yml for the top level of the build.

