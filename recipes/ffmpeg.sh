mkdir -p $build_dir && cd $build_dir
args=(--enable-cross-compile --cross-prefix=$host- --cc=$CC --pkg-config=pkg-config --disable-{doc,programs})
case $platform in
	android)
		cpu=armv7-a cflags=
		case $host in
			arm*) cflags="-mfpu=neon -mcpu=cortex-a8" ;;
			aarch64*) cpu=armv8-a ;;
			x86_64*) cpu=generic ;;
			i686*) cpu="i686 --disable-asm" ;;
		esac
		args+=(
			--target-os=android --nm=llvm-nm --arch=${host%%-*} --cpu=$cpu
			--extra-cflags="-I$prefix_dir/include $cflags" --extra-ldflags="-L$prefix_dir/lib"
			--enable-{jni,mediacodec,mbedtls,libdav1d,libxml2} --disable-vulkan
			--disable-static --enable-shared --enable-{gpl,version3} --disable-stripping
			--disable-{encoders,devices}
			# for screenshots, and AC-3 to re-encode surround sound for S/PDIF
			--enable-encoder=mjpeg,png,ac3
		)
		# The AC-3 encoder queues its frames, which configure doesn't select for it.
		grep -q '^ac3_encoder_select=.*audio_frame_queue' ../configure ||
			${SED:-sed} -i 's/^ac3_encoder_select="/&audio_frame_queue /' ../configure
		;;
	windows)
		args+=(
			--target-os=mingw32 --arch=$arch --pkg-config-flags=--static
			--enable-shared --disable-static --enable-w32threads
			--disable-{everything,autodetect,network,avformat,avfilter,avdevice,swscale,swresample}
			--enable-libdav1d --enable-decoder=h264,hevc,vp9,mpeg1video,mpeg2video,libdav1d
		)
		;;
esac
../configure "${args[@]}"
make -j$cores
make DESTDIR="$dest" install
