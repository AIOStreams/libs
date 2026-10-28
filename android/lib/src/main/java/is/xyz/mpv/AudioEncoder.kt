package `is`.xyz.mpv

import java.nio.ByteBuffer

/**
 * One of FFmpeg's audio encoders, such as `ac3`, for a player that encodes
 * sound itself. Takes [frameSize] frames of interleaved float samples at a time.
 */
class AudioEncoder(codec: String, layout: String, sampleRate: Int, bitRate: Int) : AutoCloseable {
    private var handle = nativeOpen(codec, layout, sampleRate, bitRate)

    init {
        check(handle != 0L) { "FFmpeg can't encode $codec in $layout at $sampleRate Hz" }
    }

    val frameSize = nativeFrameSize(handle)

    /**
     * Encodes a frame from the start of [input] into the start of [output], both
     * direct buffers: the packet's size, or 0 while the encoder holds it back.
     */
    fun encode(input: ByteBuffer, output: ByteBuffer): Int =
        nativeEncode(handle, input, output).also { check(it >= 0) { "encoding failed" } }

    override fun close() {
        if (handle != 0L) nativeClose(handle)
        handle = 0
    }

    companion object {
        init {
            System.loadLibrary("mpv")
            System.loadLibrary("player")
        }

        /** Whether FFmpeg was built with the encoder. */
        @JvmStatic
        fun has(codec: String) = nativeHas(codec)

        @JvmStatic
        private external fun nativeHas(codec: String): Boolean

        @JvmStatic
        private external fun nativeOpen(codec: String, layout: String, sampleRate: Int, bitRate: Int): Long

        @JvmStatic
        private external fun nativeFrameSize(handle: Long): Int

        @JvmStatic
        private external fun nativeEncode(handle: Long, input: ByteBuffer, output: ByteBuffer): Int

        @JvmStatic
        private external fun nativeClose(handle: Long)
    }
}
