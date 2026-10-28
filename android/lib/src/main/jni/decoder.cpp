#include <jni.h>
#include <stdint.h>
#include <string.h>

extern "C" {
    #include <libavcodec/avcodec.h>
    #include <libavutil/channel_layout.h>
    #include <libavutil/mem.h>
    #include <libswresample/swresample.h>
}

#define decoder_func(return_type, name, ...) \
    extern "C" JNIEXPORT return_type JNICALL Java_is_xyz_mpv_AudioDecoder_##name(JNIEnv *env, jclass cls, ##__VA_ARGS__)

enum { INVALID_DATA = -1, FAILED = -2 };

struct Decoder {
    AVCodecContext *ctx;
    AVPacket *packet;
    AVFrame *frame;
    uint8_t *extra;
    int extra_size;
    int announced_rate;
    int announced_channels;
    AVSampleFormat format;
    // What the resampler takes, as the last frame was.
    SwrContext *swr;
    AVChannelLayout in_layout;
    int in_format;
    int in_rate;
    // What every frame becomes, set by the first.
    AVChannelLayout out_layout;
    int out_rate;
    uint8_t *out;
    unsigned int out_capacity;
    int out_size;
};

static bool open_context(Decoder *d, const AVCodec *codec) {
    d->ctx = avcodec_alloc_context3(codec);
    if (!d->ctx)
        return false;
    d->ctx->request_sample_fmt = d->format;
    d->ctx->err_recognition = AV_EF_IGNORE_ERR;
    if (d->extra) {
        d->ctx->extradata = (uint8_t *)av_mallocz(d->extra_size + AV_INPUT_BUFFER_PADDING_SIZE);
        if (!d->ctx->extradata)
            return false;
        memcpy(d->ctx->extradata, d->extra, d->extra_size);
        d->ctx->extradata_size = d->extra_size;
    }
    // Raw telephony sound has no header to say these.
    if (codec->id == AV_CODEC_ID_PCM_MULAW || codec->id == AV_CODEC_ID_PCM_ALAW) {
        d->ctx->sample_rate = d->announced_rate;
        av_channel_layout_default(&d->ctx->ch_layout, d->announced_channels);
    }
    return avcodec_open2(d->ctx, codec, nullptr) >= 0;
}

static void free_decoder(Decoder *d) {
    swr_free(&d->swr);
    av_channel_layout_uninit(&d->in_layout);
    av_channel_layout_uninit(&d->out_layout);
    av_frame_free(&d->frame);
    av_packet_free(&d->packet);
    avcodec_free_context(&d->ctx);
    av_free(d->extra);
    av_free(d->out);
    delete d;
}

// A first frame may carry only the core of a stream's sound, so the stream's own channel count wins where it's more.
static bool set_output(Decoder *d, const AVFrame *f) {
    d->out_rate = f->sample_rate;
    if (d->announced_channels > f->ch_layout.nb_channels) {
        av_channel_layout_default(&d->out_layout, d->announced_channels);
        return true;
    }
    return av_channel_layout_copy(&d->out_layout, &f->ch_layout) >= 0;
}

static bool resample_from(Decoder *d, const AVFrame *f) {
    if (d->swr && f->format == d->in_format && f->sample_rate == d->in_rate &&
            !av_channel_layout_compare(&f->ch_layout, &d->in_layout))
        return true;
    swr_free(&d->swr);
    av_channel_layout_uninit(&d->in_layout);
    if (swr_alloc_set_opts2(&d->swr, &d->out_layout, d->format, d->out_rate, &f->ch_layout,
                (AVSampleFormat)f->format, f->sample_rate, 0, nullptr) < 0 ||
            swr_init(d->swr) < 0 || av_channel_layout_copy(&d->in_layout, &f->ch_layout) < 0) {
        swr_free(&d->swr);
        return false;
    }
    d->in_format = f->format;
    d->in_rate = f->sample_rate;
    return true;
}

static int convert(Decoder *d, const AVFrame *f) {
    if (!d->out_layout.nb_channels && !set_output(d, f))
        return FAILED;
    if (!resample_from(d, f))
        return FAILED;
    int frame_bytes = d->out_layout.nb_channels * av_get_bytes_per_sample(d->format);
    int room = swr_get_out_samples(d->swr, f->nb_samples);
    if (room < 0)
        return FAILED;
    uint8_t *out = (uint8_t *)av_fast_realloc(d->out, &d->out_capacity, d->out_size + room * frame_bytes);
    if (!out)
        return FAILED;
    d->out = out;
    out += d->out_size;
    int converted = swr_convert(d->swr, &out, room, (const uint8_t **)f->extended_data, f->nb_samples);
    if (converted < 0)
        return FAILED;
    d->out_size += converted * frame_bytes;
    return 0;
}

static int failure(int error) {
    return error == AVERROR_INVALIDDATA ? INVALID_DATA : FAILED;
}

decoder_func(jboolean, nativeHas, jstring codec) {
    const char *name = env->GetStringUTFChars(codec, nullptr);
    bool found = avcodec_find_decoder_by_name(name) != nullptr;
    env->ReleaseStringUTFChars(codec, name);
    return found;
}

decoder_func(jint, nativeInputPadding) {
    return AV_INPUT_BUFFER_PADDING_SIZE;
}

decoder_func(jstring, nativeVersion) {
    return env->NewStringUTF(LIBAVCODEC_IDENT);
}

decoder_func(jlong, nativeOpen, jstring codec, jbyteArray extra, jint sample_rate, jint channels, jboolean float_output) {
    const char *name = env->GetStringUTFChars(codec, nullptr);
    const AVCodec *found = avcodec_find_decoder_by_name(name);
    env->ReleaseStringUTFChars(codec, name);
    if (!found)
        return 0;
    Decoder *d = new Decoder{};
    d->announced_rate = sample_rate;
    d->announced_channels = channels;
    d->format = float_output ? AV_SAMPLE_FMT_FLT : AV_SAMPLE_FMT_S16;
    if (extra) {
        d->extra_size = env->GetArrayLength(extra);
        d->extra = (uint8_t *)av_malloc(d->extra_size);
        if (!d->extra) {
            free_decoder(d);
            return 0;
        }
        env->GetByteArrayRegion(extra, 0, d->extra_size, (jbyte *)d->extra);
    }
    if (!open_context(d, found) || !(d->packet = av_packet_alloc()) || !(d->frame = av_frame_alloc())) {
        free_decoder(d);
        return 0;
    }
    return (jlong)(intptr_t)d;
}

decoder_func(jint, nativeChannels, jlong handle) {
    return ((Decoder *)(intptr_t)handle)->out_layout.nb_channels;
}

decoder_func(jint, nativeSampleRate, jlong handle) {
    return ((Decoder *)(intptr_t)handle)->out_rate;
}

// The size of the sound a packet of `size` bytes from the start of `input` gives, held for nativeRead.
decoder_func(jint, nativeDecode, jlong handle, jobject input, jint size) {
    Decoder *d = (Decoder *)(intptr_t)handle;
    uint8_t *in = (uint8_t *)env->GetDirectBufferAddress(input);
    if (!in || size < 0)
        return FAILED;
    d->out_size = 0;
    d->packet->data = in;
    d->packet->size = size;
    int ret = avcodec_send_packet(d->ctx, d->packet);
    d->packet->data = nullptr;
    d->packet->size = 0;
    if (ret < 0)
        return failure(ret);
    while ((ret = avcodec_receive_frame(d->ctx, d->frame)) >= 0) {
        int converted = convert(d, d->frame);
        av_frame_unref(d->frame);
        if (converted < 0)
            return converted;
    }
    return ret == AVERROR(EAGAIN) ? d->out_size : failure(ret);
}

decoder_func(jboolean, nativeRead, jlong handle, jobject output) {
    Decoder *d = (Decoder *)(intptr_t)handle;
    uint8_t *out = (uint8_t *)env->GetDirectBufferAddress(output);
    if (!out || env->GetDirectBufferCapacity(output) < d->out_size)
        return false;
    memcpy(out, d->out, d->out_size);
    return true;
}

// As in Media3's own decoder, TrueHD's opens again rather than flushing.
decoder_func(jboolean, nativeFlush, jlong handle) {
    Decoder *d = (Decoder *)(intptr_t)handle;
    swr_free(&d->swr);
    if (d->ctx->codec_id != AV_CODEC_ID_TRUEHD) {
        avcodec_flush_buffers(d->ctx);
        return true;
    }
    const AVCodec *codec = d->ctx->codec;
    avcodec_free_context(&d->ctx);
    return open_context(d, codec);
}

decoder_func(void, nativeClose, jlong handle) {
    free_decoder((Decoder *)(intptr_t)handle);
}
