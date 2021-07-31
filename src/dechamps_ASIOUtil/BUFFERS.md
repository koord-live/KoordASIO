# ASIO buffer management, explained

The [ASIO SDK][] documentation contains a lot of information about how the ASIO
Host Application and the ASIO Driver are supposed to interact with each other
when it comes to buffer management and event callbacks. However, despite the
precautions taken by the ASIO docs to try to carefully explain what's going on
under various angles and using examples, there are still some aspects of it that
are still arguably fairly confusing. This document provides one possible
interpretation of the ASIO buffer management semantics that is, hopefully,
correct and most consistent with the official documentation.

Part of the reason why this can be so confusing for an ASIO driver developer is
because ASIO was apparently designed for hardware using [Direct Memory Access
(DMA)][DMA], a scheme in which the hardware audio device reads/writes *directly*
from/to the ASIO buffers in main memory. This is an extremely efficient approach
that is well-suited for low-latency operation, but a lot of audio devices do not
work that way, especially USB devices and devices accessed through an
abstraction layer ("Universal" ASIO drivers). The way buffers and event
callbacks work in ASIO feels natural and intuitive to someone writing a driver
for a DMA-based device, but could be highly confusing when using a different
approach which requires audio buffers to be copied to/from some other place for
processing.

In order to understand what's going on, it is a good idea to take the
perspective of how things *would* work in a DMA-based driver, in order to
understand ASIO semantics and implement them in a non-DMA-based driver.

Note that this document assumes that you've read the ASIO SDK documentation
first, and that you understand the most trivial concepts described there (such
as the general principle of double buffering). This document only explains the
details that could arguably still be confusing after reading the documentation;
it does not address topics that the official documentation already makes clear.

## Input (recording) side

We'll start with the input side of things because it's the simplest. The
`bufferSwitch` callback documentation states:

> The addressed input buffer is now filled with incoming data.

In other words, if `bufferSwitch(0)` is called, it means that "input buffer 0 is
filled with recorded data".

The use of the passive form is unfortunate, but it should still be fairly
obvious that the driver is responsible for filling the input buffer with
incoming data (where else could it come from?).

The biggest problem in that sentence is the word *"now"*, which is arguably
ambiguous and could be interpreted in several different ways:

1. The specified input buffer is guaranteed to be filled with incoming data
   *before* `bufferSwitch` is called.
2. The specified input buffer is being filled with incoming data as the
   `bufferSwitch` call is taking place.
3. The specified input buffer will start to be filled with incoming data *after*
   `bufferSwitch` returns.

The correct interpretation is (1), on the following grounds:

- The driver sample code in the ASIO SDK fills buffer X *before*
  `bufferSwitch(X)` is called (see `AsioSample::bufferSwitch()`), which is
  inconsistent with (3).
- If (2) was the correct intepretation, then the ASIO host application would
  have no way of knowing when the input data is ready (there is no `inputReady`
  callback that the driver could use), and would have to wait until the next
  `bufferSwitch` call to be able to process the input, which would necessarily
  inflict additional latency of one buffer length. This contradicts other parts
  of the documentation, which state that a driver can achieve an input latency
  of a single buffer length ("block"); see the `ASIOGetLatencies()`
  documentation.
- A DMA driver cannot implement (3) because it does not get to choose when to
  "receive" the buffer from the hardware.
- (3) forces the ASIO Host Application to process (or at least copy) the input
  data before it can return from `bufferSwitch`, which is awkward if
  `directProcess` is false.
- (2) and (3) would be awkward from an API design perspective, because they
  would imply that the ASIO Host Application should not be processing the
  specified buffer but the *opposite* one, which is counter-intuitive.

Therefore, the documentation could be reworded as follows:

> **The driver guarantees that the specified input buffer is filled with
> incoming data *before* `bufferSwitch` is called.**

This also implies that, in order to minimize input latency, the driver should
call `bufferSwitch` as soon as possible after a full block of input data has
been recorded by the audio hardware.

This answers the question of when the input buffer becomes readable, but it does
not address a related question: for *how long* is the input buffer valid for;
i.e. when should the ASIO Host Application stop reading from the buffer. This is
addressed in the section regarding buffer validity, below.

## Output (playback) side

On the output side, the `bufferSwitch` callback documentation states:

> The current buffer half index (0 or 1) determines the output buffer that the
> host should start to fill. The other buffer will be passed to output hardware
> regardless of whether it got filled in time or not.

This is where it gets really confusing. It can probably be assumed that
*"current"* here means the buffer index that is specified as the parameter to
the callback. The terms *"should start to"* could be interpreted in several
different ways:

1. `bufferSwitch` is called *after* the specified output buffer has been fully
   sent to the hardware.
2. The specified buffer is being sent to the hardware as the `bufferSwitch` call
   is taking place.
3. The specified buffer will be sent to the hardware immediately after
   `bufferSwitch` returns.

The correct interpretation is (1), on the following grounds:

- The host sample code in the ASIO SDK fills the *specified* buffer in
  `bufferSwitch`, which is inconsistent with (2).
- (3) forces the ASIO Host Application to generate output data before it can
  return from `bufferSwitch`, which is awkward if `directProcess` is false.
- A DMA driver cannot implement (3) because it does not get to choose when to
  "send" the buffer to the hardware.
- (2) would be awkward from an API design perspective, because that would imply
  that the ASIO Host Application should not be processing the specified buffer
  but the *opposite* one, which is counter-intuitive.
- If (3) were true, then the driver could send the output data to the hardware
  as soon as `bufferSwitch` returns, which means there would be little reason
  for `ASIOOutputReady()` to exist (see below).

Therefore, the documentation could be reworded as follows:

> **The driver guarantees that the specified output buffer has been fully sent
> to the hardware *before* `bufferSwitch` is called.**

This answers the question of when the output buffer becomes writeable, but it
does not address a related question: for *how long* is the output buffer valid
for; i.e. when should the ASIO Host Application stop writing to the buffer. This
is addressed in the section regarding buffer validity, below.

## Buffer validity and race conditions

Upon entry of the `bufferSwitch` callback, the following guarantees hold:

- The specified input buffer can be read from.
- The specified output buffer can be written to.

What is still not clear, however, is *how long* these buffers are valid *for*.
Indeed, eventually the driver will start writing data to the input buffer (which
means valid data cannot be read from it anymore), and will start reading data
from the output buffer (which means the host must have stopped writing to it
by then).

The ASIO SDK documentation does not address these questions explicitly.
Intuitively, a C/C++ programmer might assume that these buffers are only valid
for the duration of the `bufferSwitch` call, because, in the absence of
documentation, one should assume that a pointer is only valid for the duration
of the call in which it is used. However, the way the ASIO documentation is
phrased, and in particular the existence of concepts such as `directProcess` and
`ASIOOutputReady`, casts doubt on that assumption. Section 5 "Audio Streaming"
states:

> This is a provision for drivers which require an immediate return of the
> `bufferSwitch()` or `bufferSwitchTimeInfo()` callback on interrupt driven
> systems like the Apple Macintosh, which cannot spend too long in the callback
> at a low level interrupt time. Instead the application will process the data
> at an interruptible execution level and inform the driver once it finished the
> processing.

In other words: it is possible to return from the callback first, *and then*
process the data (i.e. read and write buffers) later. This can only work if the
validity of the buffers is extended beyond the `bufferSwitch` callback itself.

On the other hand, this seems to be contradicted by a previous statement from
the same section:

> Upon return of the callback the application has read all input data and
> provided all output data.

There are multiple ways we could try to reconcile these statements:

1. In the latter statement, perhaps "all input data" and "all output data"
   refers to the *other* buffer half, not the buffer half that is specified in
   the callback that we are returning from.
2. Perhaps the latter statement is merely a recommendation and is non-normative;
   i.e. it is recommended that the host processes the data in `bufferSwitch`,
   but the driver should not rely on that.
3. Perhaps the API contract is different depending on whether `bufferSwitch` was
   called with `directProcess` enabled or not. If `directProcess` is enabled,
   the buffers are only valid for the duration of the callback. Otherwise, they
   stay valid beyond the duration of the callback.

It is worth discussing what the consequences would be if the driver and the
application disagree on this contract, i.e. the driver starts reading/writing a
buffer too soon after the application returns from `bufferSwitch`. Aside from
the obvious consequence of messing up the audio data, which will cause a likely
audible "glitch" (discontinuity), it also qualifies as a race condition (two
threads are reading/writing the same memory location at the same time), which is
[undefined behaviour][]. This is a big deal - [there is no such thing as a
benign race condition][benignrace], and such a situation could compromise the
integrity of the process.

In general, it is prudent for a driver to assume that, in general, the
application might access buffer 0 as soon as `bufferSwitch(0)` is called, up
until the application returns from `bufferSwitch(1)` (and vice-versa). In fact,
there is one more case where a buffer is accessed outside of `bufferSwitch`:
before streaming starts, when the application pre-fills buffer 1 before calling
`ASIOStart()` (see section about priming, below).

Note that a driver that exposes DMA buffers cannot really use this approach,
because *both* buffers are under the control by the application for the duration
of a `bufferSwitch` call, including the location that the hardware might
currently be reading/writing at. However, race conditions are inherent to such
drivers anyway, because their mode of operation if fundamentally designed around
the hardware and the application racing against each other.

## The case for `ASIOOutputReady()`

`ASIOOutputReady()` is an optional ASIO feature that allows the host to notify
the driver when the host has finished filling the output buffers that were
provided in the last `bufferSwitch` call. The ASIO SDK documentation does not
mention any restriction as to the context in which this function can be used; it
should be safe to assume that it can be called from within `bufferSwitch` (in a
reentrant manner) or from a separate thread between `bufferSwitch` calls.

One could naively assume that simply returning from `bufferSwitch` would achieve
the same effect, but that is not always true, because:

- It is not clear if the driver can safely assume that output buffer `X` is
  ready as soon as `bufferSwitch(X)` returns (see the discussion about validity
  of buffers, above).
- The application might have filled the output buffer some time before it
  wants to return from the `bufferSwitch` callback. For example, if the
  application generates the output *before* processing the input.

The ASIO SDK documentation explains `ASIOOutputReady()` using the concept of
"DMA buffers", which is confusing for drivers that are not DMA-based in the
first place. In a "pure" DMA-based driver where the hardware is reading the ASIO
buffers directly, then `ASIOOutputReady()` does not provide any benefit because
the driver doesn't have to do anything when the output buffer is "ready": the
data is already in place and will be read directly by the hardware as the clock
advances. However, drivers that do not directly expose DMA buffers cannot work
that way: they need to know when the output buffer is filled because they need
to take action before the hardware can play it (such as copying the data,
post-processing it, or sending it elsewhere), and waiting too long before taking
such action could lead to an output buffer underrun.

If the application does not support `ASIOOutputReady()`, then the driver needs
to wait at least until `bufferSwitch` returns before it could process the output
buffer, increasing the likelihood of missing deadlines. Worse, if the driver
assumes that the host application can continue writing to the output buffer
even after `bufferSwitch` has returned (see previous section), then it needs to
wait at least until the *next* `bufferSwitch` call has returned before it can
process the output buffer of the previous call. If the driver waits this long,
then it has to keep an additional output buffer in the hardware queue, otherwise
buffer underrun will occur around `bufferSwitch` time. This is why the
`ASIOGetLatencies()` documentation states that the output latency is doubled
under this mode of operation. The point of `ASIOOutputReady()` is to avoid this
problem by allowing the driver to do what it needs to do with the output buffers
*before* underrun might occur.

One caveat of `ASIOOutputReady()` is that, if it is called outside of a
`bufferSwitch` callback, it could race with that callback, and then it is not
clear if the `ASIOOutputReady()` call applies to the previous output buffer or
to the one that was passed to the `bufferSwitch` call that just happened. This
could mislead the driver into thinking that the application has stopped using
the new output buffer, resulting in race conditions. For this reason it might
be safer to make the driver block until the application has called
`ASIOOutputReady()` before making the next call to `bufferSwitch`.

## `ASIOStart()` and "priming"

The ASIO SDK documentation states in section 5:

> The audio streaming starts after the ASIOStart() call. Prior to starting the
> hardware streaming the driver will issue one or more `bufferSwitch()` or
> `bufferSwitchTimeInfo()` callbacks to fill its first output buffer(s). Since
> the hardware did not provide any input data yet the input channels' buffers
> should be filled with silence by the driver.

Section 6 states:

> the same system time is used for the first two callbacks, as the hardware did
> not start yet

The `ASIOStart()` documentation states:

> The first call to the hosts' `bufferSwitch(index == 0)` then tells the host to
> read from input buffer A (index 0), and start processing to output buffer A
> while output buffer B (which has been filled by the host prior to calling
> `ASIOStart()`) is possibly sounding

What this means in practice is that the host should fill buffer 1 prior to
calling `ASIOStart()`. On `ASIOStart()` the driver fills all input buffers with
silence, then calls `bufferSwitch(0)`. After `bufferSwitch(0)` returns (which
indicates the application is done using buffer 1), the driver sends buffer 1 to
the hardware. The driver can then start the hardware and start reading into
input buffer 1. On `ASIOOutputReady()`, the driver sends output buffer 0 to the
hardware. When the driver has finished filling input buffer 1, it can call
`bufferSwitch(1)`. Upon return the driver can start filling buffer 0, and we are
now in steady-state.

The above assumes that the application is allowed to use buffers until it
returns from the next `bufferSwitch` call (see section about buffer validity),
and that the application supports `ASIOOutputReady()`. If the application does
not support `ASIOOutputReady()`, the driver will have to call `bufferSwitch(1)`
earlier, *before* starting the hardware (passing silence again) so that it can
put another output buffer in the queue (see the section about
`ASIOOutputReady()` for why it has to do this). Then the driver enters
steady-state, with one additional buffer in the output queue at all times. This
seems to be the scenario described in the example in section 6 of the ASIO SDK
documentation.

## Summary of recommendations

In the presence of such ambiguity around buffer validity, the best option for
application developers and driver developers is to apply the
[Robustness principle][] to avoid race conditions:

- Paranoid driver developers should assume that the application will access
  buffer 0 as soon as `bufferSwitch(0)` is called, up until `bufferSwitch(1)`
  returns (and vice-versa).
  - If `ASIOOutputReady()` is called, the driver can assume the application is
    not using the output buffer anymore, but be careful about such calls racing
    against `bufferSwitch`. You might want to wait for `ASIOOutputReady()` to be
    called before making the next `bufferSwitch` call.
- Paranoid host application developers should assume that buffer 0 will cease to
  be valid as soon as they return from `bufferSwitch(0)` (same for the other
  buffer).
  - In any case, applications should *always* call `ASIOOutputReady()` when
    they have stopped using an output buffer.

An example sequence of calls could look as follows. If the application does not
support `ASIOOutputReady()`:

1. Application fills output buffer 1.
   - One could argue the application could wait right up until step 6 before
     doing that, but that would go against the documentation of `ASIOStart()`.
2. Application calls `ASIOStart()`.
3. Driver initially fills the input buffers with silence.
4. Driver returns from `ASIOStart()`.
5. Driver calls `bufferSwitch(0)`.
6. Application returns from `bufferSwitch(0)`.
7. Driver sends output buffer 1 to the hardware.
8. Driver calls `bufferSwitch(1)`.
9. Application returns from `bufferSwitch(1)`.
10. Driver sends output buffer 0 to the hardware.
11. Driver starts hardware playback and recording.
12. Driver waits for incoming data to arrive, stores it in buffer 0.
13. Driver calls `bufferSwitch(0)`.
14. Application returns from `bufferSwitch(0)`
15. Driver sends output buffer 1 to the hardware.
16. Driver waits for incoming data to arrive, stores it in buffer 1.
17. Driver calls `bufferSwitch(1)`.
18. Application returns from `bufferSwitch(1)`
19. Driver sends output buffer 0 to the hardware.
20. Steady-state: go to step 12.

If the application supports `ASIOOutputReady()`:

1. Application advertises support for `ASIOOutputReady()` by calling it.
2. Application fills output buffer 1.
3. Application calls `ASIOStart()`.
4. Driver initially fills the input buffers with silence.
5. Driver returns from `ASIOStart()`.
6. Driver sends output buffer 1 to the hardware.
   - One could argue that the application should call `ASIOOutputReady()` before
     the driver does that, for better consistency with steady-state operation.
     However, the application might disagree, leading the driver to wait
     forever.
7. Driver starts hardware playback and recording.
8. Driver calls `bufferSwitch(0)`.
9. Application returns from `bufferSwitch(0)`.
   - Before or after this step, the application calls `ASIOOutputReady()`. Upon
     receiving this call the driver sends output buffer 0 to the hardware.
10. Driver waits for incoming data to arrive, stores it in buffer 1.
11. Driver calls `bufferSwitch(1)`.
12. Application returns from `bufferSwitch(1)`.
    - Before or after this step, the application calls `ASIOOutputReady()`. Upon
      receiving this call the driver sends output buffer 1 to the hardware.
13. Driver waits for incoming data to arrive, stores it in buffer 0.
14. Steady-state: go to step 9.

---

*ASIO is a trademark and software of Steinberg Media Technologies GmbH*

[ASIO SDK]: https://www.steinberg.net/en/company/developers.html
[DMA]: https://en.wikipedia.org/wiki/Direct_memory_access
[Robustness principle]: https://en.wikipedia.org/wiki/Robustness_principle
[undefined behaviour]: https://en.wikipedia.org/wiki/Undefined_behavior
[benignrace]: https://software.intel.com/en-us/blogs/2013/01/06/benign-data-races-what-could-possibly-go-wrong
