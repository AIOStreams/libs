# aiostreams-libs

[![Build Status](https://github.com/Viren070/aiostreams-libs/actions/workflows/build.yml/badge.svg?branch=library)](https://github.com/Viren070/aiostreams-libs/actions/workflows/build.yml)

The native libraries [AIOStreams](https://github.com/Viren070/AIOStreams)' apps ship. Every source is pinned to a commit in [depinfo.sh](buildscripts/include/depinfo.sh), the patches in [buildscripts/patches](buildscripts/patches) apply on top, and each push to `library` publishes a release with these files and their SHA-256s:

| File | What it is | Used by |
| --- | --- | --- |
| `mpv-android-lib-<tag>.aar` | libmpv for Android (arm64-v8a, armeabi-v7a, x86_64), with FFmpeg, dav1d, libass, libplacebo and libdovi | The Android app's mpv player, FFmpeg audio decoders and seek-bar thumbnails |
| `ffmpeg-windows-<arch>.zip` | FFmpeg's avcodec and avutil DLLs for Windows x86_64 and aarch64, with only the H.264, HEVC, VP9, MPEG-1/2 and AV1 (dav1d) decoders | The desktop app's seek-bar thumbnails |

## FFmpeg patches

| Patch | Change |
| --- | --- |
| `hevcpred-10bit-neon.patch` | NEON 10-bit HEVC angular and planar intra prediction on aarch64 |
| `hevc-irap-missing-refs.patch` | Decoding that starts at an open-GOP keyframe no longer allocates and fills a frame for each of its references, which only skipped pictures use |
| `libdav1d-skip-loop-filter.patch` | `skip_loop_filter` turns off dav1d's in-loop filters, as it does FFmpeg's own decoders' |

## libmpv for Android

A library version of [mpv-android](https://github.com/mpv-android/mpv-android), providing [libmpv](https://github.com/mpv-player/mpv) for Android applications. Initially made for [mpvKt](https://github.com/abdallahmehiz/mpvKt).

### "New" Features

* **Multiple MPV instances**
* **`mpv_node` support**
* **DASH support**
* **FFmpeg's audio decoders and encoders**, through `AudioDecoder` and `AudioEncoder`, for a player that handles sound itself

### Installation

Download the AAR from [Releases](https://github.com/Viren070/aiostreams-libs/releases) and check it against the SHA-256 in the release notes. It needs `androidx.core` and `kotlinx-coroutines-android` beside it.

### Getting Started

#### Using BaseMPVView

`BaseMPVView` attaches its surface to the `MPV` you give it:

```kotlin
val playerView = BaseMPVView(context, null)
playerView.mpv = MPV(context) { it.setOptionString("hwdec", "auto") }
playerView.mpv?.command("loadfile", "/path/to/video.mp4")
```

#### Using MPV() Directly

You can also use `MPV()` then attach to fully control your mpv instance.

```kotlin
// preInit runs before mpv initializes, which is when it reads options such as its config
val mpv = MPV(context) {
    it.setOptionString("config", "yes")
    it.setOptionString("config-dir", configDir)
}

// Attach to a view surface
mpv.attachSurface(surface)

// Load and play a file
mpv.command("loadfile", "/path/to/video.mp4")

// Access props
val paused: Boolean? = mpv.prop["pause"]
mpv.prop["pause"] = false

// access and set nodes
val node: MPVNode? = mpv.getPropertyNode("track-list")
mpv.setPropertyNode("chapter-list", myCustomChaptersList)

// observe as kotlin flows
val pauseState: StateFlow<Boolean?> = mpv.propFlow["pause"]

// cleanup
mpv.detachSurface()
mpv.close()
```

#### Multiple Instances

Each `MPV()` or `BaseMPVView` instance is independent:

```kotlin
val player1 = MPV(context)
val player2 = MPV(context)

// Each player can play different content simultaneously
```

#### FFmpeg's Audio Decoders and Encoders

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

## Building from source

- The Android library: see [buildscripts/README.md](buildscripts/README.md).
- FFmpeg for Windows: `buildscripts/windows-ffmpeg.sh x86_64|aarch64` on Linux, with [llvm-mingw](https://github.com/mstorsjo/llvm-mingw) at the version in depinfo.sh, meson, ninja and nasm on PATH. It writes `buildscripts/windows/ffmpeg-windows-<arch>.zip`.

Some other documentation can be found at this [link](http://mpv-android.github.io/mpv-android/).
