mkdir -p $build_dir && cd $build_dir
args=(
	--enable-cross-compile --cc="$CC" --pkg-config=pkg-config
	--disable-static --enable-shared --enable-{gpl,version3} --disable-{doc,programs}
	--disable-{encoders,devices}
	# for screenshots, and AC-3 to re-encode surround sound for S/PDIF
	--enable-encoder=mjpeg,png,ac3
	--enable-{libdav1d,libxml2} --disable-vulkan
)
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
			--target-os=android --cross-prefix=$host- --nm=llvm-nm --arch=${host%%-*} --cpu=$cpu
			--extra-cflags="-I$prefix_dir/include $cflags" --extra-ldflags="-L$prefix_dir/lib"
			--enable-{jni,mediacodec,mbedtls} --disable-stripping
		)
		;;
	windows)
		args+=(
			--target-os=mingw32 --cross-prefix=$host- --arch=$arch --pkg-config-flags=--static
			--enable-{zlib,ffnvcodec,nvdec} --disable-avdevice
			# the one part needing C++
			--disable-filter=gfxcapture
		)
		;;
	macos)
		args+=(
			--target-os=darwin --arch=$arch --pkg-config-flags=--static
			--enable-{videotoolbox,audiotoolbox,securetransport} --disable-avdevice
			--extra-cflags="$(pkg-config --cflags dovi)" --extra-libs="$(pkg-config --libs --static dovi)"
			# room for the packaging's install names
			--extra-ldflags=-Wl,-headerpad_max_install_names
		)
		;;
esac
# The AC-3 encoder queues its frames, which configure doesn't select for it.
grep -q '^ac3_encoder_select=.*audio_frame_queue' ../configure ||
	${SED:-sed} -i 's/^ac3_encoder_select="/&audio_frame_queue /' ../configure
../configure "${args[@]}"
make -j$cores
make DESTDIR="$dest" install
