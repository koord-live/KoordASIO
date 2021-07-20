
# KoordASIO - an easy-to-use universal ASIO driver

## Description

KoordASIO is a universal ASIO driver, free to download and use on any Windows computer, to provide a simple, accessible solution for low-latency
audio using ASIO on Windows. It should work with most soundcards currently supported by the Windows OS.

KoordASIO is a "respin" of the FlexASIO project, made simpler to use by removing various test and debug utilities unnecessary for the general user, and providing a simple GUI configuration utility.

Q: What is the Latency like?

A: In default Shared mode, which allows other sound apps to access the sound device simultaneously, users can expect latency in the 10-20ms range. In Exclusive mode, many users can achieve workable latencies in the 5-10ms range.

![Screenshot (6)](https://user-images.githubusercontent.com/584572/126207641-54abd5dc-ec65-43be-977a-99432c04714e.png)

KoordASIO Config utility

KoordASIO only uses the WASAPI backend within FlexASIO, to provide the best performance and feature set.
Exclusive Mode or Shared Mode can be enabled, and a sensible buffer-size range from 32 samples to 2048 samples.
The intention is not to provide all the features that FlexASIO offers, but to force a sensible high-performance low-latency configuration.

The KoordASIO configuration tool chooses sensible defaults if no existing valid configuration is set: 
- Input and Output devices to the system defaults
- Shared Mode to allow inter-operation with other sound apps
- Buffer Size of 64 samples

https://koord.live/

Koord acknowledges gratefully the work of the authors of these awesome upstream projects:
- FlexASIO
- PortAudio

For detailed info on implementation, debug binaries and test tools, please see the upstream FlexASIO repo, which contains a lot of useful documentation.

[ASIO]: http://en.wikipedia.org/wiki/Audio_Stream_Input/Output
[GitHub]: https://github.com/koord-live/KoordASIO/
[GitHub issue tracker]: https://github.com/koord-live/KoordASIO/issues
[PortAudio]: http://www.portaudio.com/
[releases]: https://github.com/koord-live/KoordASIO/releases
[report]: #reporting-issues-feedback-feature-requests
[WASAPI]: https://docs.microsoft.com/en-us/windows/desktop/coreaudio/wasapi
