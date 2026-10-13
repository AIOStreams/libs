#include <jni.h>
#include <stdint.h>
#include <string.h>

extern "C" {
    #include <libavcodec/avcodec.h>
    #include <libavutil/channel_layout.h>
}

#define encoder_func(return_type, name, ...) \
    extern "C" JNIEXPORT return_type JNICALL Java_is_xyz_mpv_AudioEncoder_##name(JNIEnv *env, jclass cls, ##__VA_ARGS__)

struct Encoder {
    AVCodecContext *ctx;
    AVFrame *frame;
    AVPacket *packet;
    int64_t pts;
};

static void free_encoder(Encoder *e) {
    av_frame_free(&e->frame);
    av_packet_free(&e->packet);
    avcodec_free_context(&e->ctx);
    delete e;
}

static Encoder *open_encoder(const char *codec_name, const char *layout, int sample_rate, int bit_rate) {
    const AVCodec *codec = avcodec_find_encoder_by_name(codec_name);
    if (!codec)
        return nullptr;
    Encoder *e = new Encoder{};
    e->ctx = avcodec_alloc_context3(codec);
    if (!e->ctx || av_channel_layout_from_string(&e->ctx->ch_layout, layout) < 0) {
        free_encoder(e);
        return nullptr;
    }
    e->ctx->sample_rate = sample_rate;
    e->ctx->bit_rate = bit_rate;
    e->ctx->sample_fmt = AV_SAMPLE_FMT_FLTP;
    e->ctx->time_base = AVRational{1, sample_rate};
    if (avcodec_open2(e->ctx, codec, nullptr) < 0 || !(e->frame = av_frame_alloc()) ||
            !(e->packet = av_packet_alloc())) {
        free_encoder(e);
        return nullptr;
    }
    e->frame->nb_samples = e->ctx->frame_size;
    e->frame->format = e->ctx->sample_fmt;
    e->frame->sample_rate = sample_rate;
    if (av_channel_layout_copy(&e->frame->ch_layout, &e->ctx->ch_layout) < 0 ||
            av_frame_get_buffer(e->frame, 0) < 0) {
        free_encoder(e);
        return nullptr;
    }
    return e;
}

encoder_func(jboolean, nativeHas, jstring codec) {
    const char *name = env->GetStringUTFChars(codec, nullptr);
    bool found = avcodec_find_encoder_by_name(name) != nullptr;
    env->ReleaseStringUTFChars(codec, name);
    return found;
}

encoder_func(jlong, nativeOpen, jstring codec, jstring layout, jint sample_rate, jint bit_rate) {
    const char *codec_name = env->GetStringUTFChars(codec, nullptr);
    const char *layout_name = env->GetStringUTFChars(layout, nullptr);
    Encoder *e = open_encoder(codec_name, layout_name, sample_rate, bit_rate);
    env->ReleaseStringUTFChars(codec, codec_name);
    env->ReleaseStringUTFChars(layout, layout_name);
    return (jlong)(intptr_t)e;
}

encoder_func(jint, nativeFrameSize, jlong handle) {
    return ((Encoder *)(intptr_t)handle)->ctx->frame_size;
}

// One frame of interleaved float samples from the start of `input`; the packet's size in `output`,
// 0 while the encoder holds it back, or -1 on an error.
encoder_func(jint, nativeEncode, jlong handle, jobject input, jobject output) {
    Encoder *e = (Encoder *)(intptr_t)handle;
    const float *in = (const float *)env->GetDirectBufferAddress(input);
    uint8_t *out = (uint8_t *)env->GetDirectBufferAddress(output);
    int channels = e->ctx->ch_layout.nb_channels;
    int samples = e->frame->nb_samples;
    if (!in || !out || env->GetDirectBufferCapacity(input) < (jlong)samples * channels * 4 ||
            av_frame_make_writable(e->frame) < 0)
        return -1;
    for (int c = 0; c < channels; c++) {
        float *plane = (float *)e->frame->extended_data[c];
        for (int i = 0; i < samples; i++)
            plane[i] = in[i * channels + c];
    }
    e->frame->pts = e->pts;
    e->pts += samples;
    if (avcodec_send_frame(e->ctx, e->frame) < 0)
        return -1;
    int ret = avcodec_receive_packet(e->ctx, e->packet);
    if (ret == AVERROR(EAGAIN))
        return 0;
    if (ret < 0)
        return -1;
    int size = e->packet->size;
    if (size > env->GetDirectBufferCapacity(output))
        size = -1;
    else
        memcpy(out, e->packet->data, size);
    av_packet_unref(e->packet);
    return size;
}

encoder_func(void, nativeClose, jlong handle) {
    free_encoder((Encoder *)(intptr_t)handle);
}
