# AIOStreams libraries

[![Build Status](https://github.com/AIOStreams/libs/actions/workflows/build.yml/badge.svg?branch=library)](https://github.com/AIOStreams/libs/actions/workflows/build.yml)

The native libraries [AIOStreams](https://github.com/Viren070/AIOStreams)' apps play video with: libmpv, with FFmpeg, libass, libplacebo and the libraries they use, for Android, Windows and macOS. Every source is pinned, and each push to `library` publishes all of it as one release. Our changes to mpv, FFmpeg and libass live in AIOStreams' forks of them ([below](#our-changes)).

## Releases

Each release is tagged `<yyyymmdd>-<commit>` and holds:

| File | What it is | Used by |
| --- | --- | --- |
| `libs-android.aar` | libmpv, FFmpeg, libass and libdovi for arm64-v8a, armeabi-v7a and x86_64, with a Kotlin API ([below](#the-android-library)), and each library's licence in `assets/licenses` | The Android app |
| `libs-windows-<arch>.zip` | `libmpv-2.dll` and FFmpeg's DLLs for x86_64 and aarch64, and each library's licence in `licenses`. It imports `vulkan-1.dll`, which GPU drivers install | The desktop app on Windows |
| `libs-macos-<arch>.zip` | `libmpv.2.dylib` with FFmpeg's and MoltenVK's dylibs for arm64 and x86_64, for macOS 11 and later, each finding the others beside it through `@rpath`, and each library's licence in `licenses` | The desktop app on macOS |
| `SHA256SUMS` | Every file's SHA-256 | |

The release notes list the pinned version of each source. Each package's `licenses/index.json` lists its libraries with their pins and licence files, for the apps' licence pages.

## Layout

| Path | What it holds |
| --- | --- |
| `sources.sh` | Every pin: a release version where the project publishes archives, otherwise a commit |
| `recipes/<library>.sh` | How each library builds, with its options per platform |
| `scripts/<platform>.sh` | A platform's toolchain, architectures, which library needs which, and how its release file is packaged |
| `build.sh` | Builds a platform for one architecture |
| `android/` | The Gradle project the AAR is built with |
| `docker/` | A container with the tools for the Android and Windows builds |

## Building

```sh
./build.sh <platform> <arch> [library]
```

For example `./build.sh windows x86_64` writes `out/libs-windows-x86_64.zip`. With a library, it builds only that library and what it needs, without packaging. Sources go in `deps/`, fetched again when their pins change, toolchains in `sdk/` and each build in `prefix/<platform>-<arch>/`. A library is rebuilt only when its recipe, pin, toolchain or one of the libraries it needs has changed, so a second run after a small change is quick; `--clean` starts its build folders over.

- **Android and Windows** build on Linux, which needs autotools, pkg-config, meson, ninja, nasm, CMake and Python 3. The build downloads the Android SDK and NDK or [llvm-mingw](https://github.com/mstorsjo/llvm-mingw) itself. Android also needs Java 21 and Rust. `docker/build.sh android arm64` runs a build in a container that has everything.
- **macOS** builds on a Mac with Xcode, Rust, CMake, Python 3, [cargo-c](https://github.com/lu-zero/cargo-c) and Homebrew's autoconf, automake, libtool, pkg-config, meson, ninja, nasm, gnu-sed and coreutils.

CI builds each platform and architecture in its own job and keeps each build's prefix in the cache, so a release rebuilds only what changed.

## Our changes

[AIOStreams/mpv](https://github.com/AIOStreams/mpv), [AIOStreams/FFmpeg](https://github.com/AIOStreams/FFmpeg) and [AIOStreams/libass](https://github.com/AIOStreams/libass) each have an `aiostreams` branch: the upstream commit we build on, with our changes as commits. `sources.sh` pins the branch's commit, which a tag (`aiostreams-<date>`) keeps whatever happens to the branch later. Moving to a newer upstream means rebasing the branch, tagging it and changing the pin.

| Fork | Changes |
| --- | --- |
| mpv | [edde746](https://github.com/edde746)'s MPVKit patches: a MoltenVK context for `gpu-next` on macOS, an AVFoundation video output that hands frames to the system's compositor, with HDR, Dolby Vision and picture in picture, passthrough through AVFoundation's audio output, and hardware decoding that waits out a burst of decode errors before falling back to software |
| FFmpeg | NEON 10-bit HEVC intra prediction on aarch64; decoding that starts at an open-GOP keyframe no longer fills a frame for each reference only skipped pictures use; `skip_loop_filter` for dav1d; and edde746's VideoToolbox patches for Dolby Vision on macOS: profile 7 converted to 8.1 with libdovi, its RPUs and HDR tags kept, and a plain HEVC session when the Dolby Vision one fails |
| libass | Faster parsing and shaping: integers without `strtoll`, short decimals with one division, FriBidi skipped for left-to-right paragraphs and HarfBuzz's results cached; a default bitmap cache that shrinks with the frame; shadows shifted a row at a time; and rendering on helper threads, with caches and fonts shared between them. Frames predicted to take more than 16 ms use as few helpers as bring them under it, and `ass_set_threads()` sets the most, by default one per processor up to 8. None of it changes what libass draws |

edde746's commits are from [MPVKit](https://github.com/edde746/MPVKit) at `b9e88e8`, rebased onto our pins, and keep their author. They are licensed under the GPL-3.0-only, © edde746, as `LICENSE.MPVKit` in each fork says. Two of the FFmpeg patches are left out: one only builds for Mac Catalyst, and FFmpeg has the other already.

## The Android library

The AAR is a library version of [mpv-android](https://github.com/mpv-android/mpv-android), from [abdallahmehiz](https://github.com/abdallahmehiz)'s, made for [mpvKt](https://github.com/abdallahmehiz/mpvKt). Beside libmpv it has:

- **Several mpv instances** at once, each independent
- **`mpv_node`** values for properties and commands
- **DASH** playback
- **FFmpeg's audio decoders and encoders**, through `AudioDecoder` and `AudioEncoder`, for a player that handles sound itself

It needs `androidx.core` and `kotlinx-coroutines-android` beside it.

### Using BaseMPVView

`BaseMPVView` attaches its surface to the `MPV` you give it:

```kotlin
val playerView = BaseMPVView(context, null)
playerView.mpv = MPV(context) { it.setOptionString("hwdec", "auto") }
playerView.mpv?.command("loadfile", "/path/to/video.mp4")
```

### Using MPV directly

```kotlin
// preInit runs before mpv initializes, which is when it reads options such as its config
val mpv = MPV(context) {
    it.setOptionString("config", "yes")
    it.setOptionString("config-dir", configDir)
}

mpv.attachSurface(surface)
mpv.command("loadfile", "/path/to/video.mp4")

// properties
val paused: Boolean? = mpv.prop["pause"]
mpv.prop["pause"] = false

// nodes
val node: MPVNode? = mpv.getPropertyNode("track-list")
mpv.setPropertyNode("chapter-list", myCustomChaptersList)

// properties as Kotlin flows
val pauseState: StateFlow<Boolean?> = mpv.propFlow["pause"]

mpv.detachSurface()
mpv.close()
```

### FFmpeg's audio decoders and encoders

`AudioDecoder` decodes packets with one of FFmpeg's decoders into interleaved 16-bit or float samples, and `AudioEncoder` encodes interleaved float samples, for example to AC-3 for a receiver that decodes it. Both take direct `ByteBuffer`s:

```kotlin
// DTS, which the device can't decode, into float samples
AudioDecoder("dca", extraData = null, sampleRate = 48000, channels = 6, float = true).use { decoder ->
    // The packet's buffer needs AudioDecoder.inputPadding spare bytes past its end
    val size = decoder.decode(packet, packetSize)
    if (size > 0) decoder.read(samples)
}

// 5.1 sound to AC-3, encoder.frameSize frames at a time
AudioEncoder("ac3", "5.1", sampleRate = 48000, bitRate = 640_000).use { encoder ->
    val packetSize = encoder.encode(frame, packet)
}
```

`AudioDecoder.has(codec)` and `AudioEncoder.has(codec)` say whether this build of FFmpeg has one.

## Licence

The build scripts and the Android library's own code are under the MIT licence in `LICENSE`, from mpv-android. Each library keeps its own: mpv is GPL-2.0-or-later and FFmpeg is built with its GPL-3.0 parts, so a release's libmpv as a whole is under the GPL-3.0.
