# KoordASIO, a user-friendly universal ASIO driver

*ASIO is a trademark and software of Steinberg Media Technologies GmbH*

**If you are looking for an installer, see the 
[GitHub releases page][releases].**

## Description

KoordASIO is a universal ASIO driver, meaning that it is not tied to
specific audio hardware. 
You can use it with any audio hardware that doesn't come with its own drivers,
or where you need features that aren't available with your bundled ASIO drivers.

![KoordASIOScreenshot1](https://user-images.githubusercontent.com/584572/184340647-045088d1-6ba6-452d-b3ed-058e5d073449.png)

KoordASIO is a clone of the powerful FlexASIO project, but with the addition of an 
intuitive Control GUI that gives the user an easy way to use all the power of 
FlexASIO without any technical knowledge. FlexASIO itself has a wide array of 
options, but KoordASIO focuses on simplicity and low-latency configuration, 
giving the user the choice of WASAPI Shared Mode (to mix ASIO audio with other 
audio application audio) and WASAPI Exclusive Mode (locks out non-ASIO audio, 
and ensures lowest-latency, bit-perfect operation). 

## Requirements

 - Windows Vista or later
 - Compatible 64-bit ASIO Host Applications

## Usage

After running the [installer][releases], KoordASIO should appear in the ASIO
driver list of any ASIO Host Application (e.g. Ableton, Cubase, Reaper).

The default settings are as follows:

 - WASAPI Shared Mode [backend][BACKENDS]
 - Uses the Windows default recording and playback audio devices
 - 32-bit float sample type
 - 32-sample buffer size
 - Minimum "suggested" latency

The KoordASIO Control GUI lets you select your Input/Output audio devices (with
a link to the relevant Windows control panel), choose between Shared or
Exclusive mode, and to change the Buffer Size in steps between 32 and 2048 samples.

## Troubleshooting
Hopefully KoordASIO should work seamlessly out-of-the-box for you. If you do notice
problems, please create an Issue at 
