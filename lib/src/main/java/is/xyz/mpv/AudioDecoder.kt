package `is`.xyz.mpv

import java.nio.ByteBuffer

/**
 * One of FFmpeg's audio decoders, such as `dca`, for a player that decodes
 * sound itself, into interleaved 16-bit or float samples. The output keeps the
 * first frame's layout and rate, or the stream's [channels] where it announces
 * more, whatever later frames carry.
 */
class AudioDecoder(codec: String, extraData: ByteArray?, sampleRate: Int, channels: Int, float: Boolean) :
    AutoCloseable {
    private var handle = nativeOpen(codec, extraData, sampleRate, channels, float)

    init {
        check(handle != 0L) { "FFmpeg can't decode $codec" }
    }

    /** The output's channel count, 0 until the first frame. */
    val channels get() = nativeChannels(handle)

    /** The output's sample rate, 0 until the first frame. */
    val sampleRate get() = nativeSampleRate(handle)

    /**
     * Decodes a packet of [size] bytes from the start of [input], a direct buffer:
     * the size of the sound it gives, which [read] copies out, or [INVALID_DATA]
     * for a packet to skip.
     */
    fun decode(input: ByteBuffer, size: Int): Int =
        nativeDecode(handle, input, size).also { check(it != FAILED) { "decoding failed" } }

    /** Copies the last packet's sound to the start of [output], a direct buffer. */
    fun read(output: ByteBuffer) = check(nativeRead(handle, output)) { "output too small" }

    /** Drops what the decoder holds, for a seek; the output stays as it is. */
    fun flush() = check(nativeFlush(handle)) { "couldn't reopen the decoder" }

    override fun close() {
        if (handle != 0L) nativeClose(handle)
        handle = 0
    }

    companion object {
        init {
            System.loadLibrary("mpv")
            System.loadLibrary("player")
        }

        const val INVALID_DATA = -1
        private const val FAILED = -2

        /** Whether FFmpeg was built with the decoder. */
        @JvmStatic
        fun has(codec: String) = nativeHas(codec)

        /** The bytes a packet's buffer needs past its end. */
        @JvmStatic
        val inputPadding: Int = nativeInputPadding()

        @JvmStatic
        val version: String = nativeVersion()

        @JvmStatic
        private external fun nativeHas(codec: String): Boolean

        @JvmStatic
        private external fun nativeInputPadding(): Int

        @JvmStatic
        private external fun nativeVersion(): String

        @JvmStatic
        private external fun nativeOpen(
            codec: String,
            extraData: ByteArray?,
            sampleRate: Int,
            channels: Int,
            float: Boolean,
        ): Long

        @JvmStatic
        private external fun nativeChannels(handle: Long): Int

        @JvmStatic
        private external fun nativeSampleRate(handle: Long): Int

        @JvmStatic
        private external fun nativeDecode(handle: Long, input: ByteBuffer, size: Int): Int

        @JvmStatic
        private external fun nativeRead(handle: Long, output: ByteBuffer): Boolean

        @JvmStatic
        private external fun nativeFlush(handle: Long): Boolean

        @JvmStatic
        private external fun nativeClose(handle: Long)
    }
}
