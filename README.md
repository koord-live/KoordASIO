
# KoordASIO - an easy-to-use universal ASIO driver

## Description

KoordASIO is a universal ASIO driver, free to download and use on any Windows computer, to provide a simple, accessible solution for low-latency
audio using ASIO on Windows. is a "respin" of the FlexASIO project, simplified by removing various test and debug utilities unnecessary for the general user, and  
providing a simple GUI configuration utility.

![Screenshot (6)](https://user-images.githubusercontent.com/584572/126207641-54abd5dc-ec65-43be-977a-99432c04714e.png)

KoordASIO Config utility

KoordASIO only uses the WASAPI backend within FlexASIO, to provide the best performance and feature set.
Exclusive Mode or Shared Mode can be enabled, and a sensible buffer-size range from 32 samples to 2048 samples.
The intention is not to provide all the features that FlexASIO offers, but to force a sensible high-performance low-latency configuration.

https://koord.live/

For detailed info on implementation, debug binaries and test tools, please see the upstream FlexASIO repo, which contains a lot of useful documentation.

[ASIO]: http://en.wikipedia.org/wiki/Audio_Stream_Input/Output
[GitHub]: https://github.com/koord-live/KoordASIO/
[GitHub issue tracker]: https://github.com/koord-live/KoordASIO/issues
[PortAudio]: http://www.portaudio.com/
[releases]: https://github.com/koord-live/KoordASIO/releases
[report]: #reporting-issues-feedback-feature-requests
[WASAPI]: https://docs.microsoft.com/en-us/windows/desktop/coreaudio/wasapi
