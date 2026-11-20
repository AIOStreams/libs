# Linux with glibc 2.39 and later, built on Ubuntu 24.04 for the machine's own architecture,
# packaged as out/libs-linux-<arch>.zip.

archs="x86_64 aarch64"
ships=(mpv)

dep_ffmpeg=(zlib mbedtls dav1d libxml2 nvcodec-headers)
dep_libxml2=(zlib)
dep_freetype2=(zlib)
dep_libass=(freetype2 fribidi harfbuzz unibreak)
dep_libplacebo=(lcms2)
dep_mpv=(ffmpeg libass luajit uchardet libplacebo libdisplay-info)

# What libmpv and FFmpeg may load from the system.
system_libs="libc.so.6 libm.so.6 libstdc++.so.6 libgcc_s.so.1 ld-linux-x86-64.so.2 ld-linux-aarch64.so.1
	libdrm.so.2 libva.so.2 libva-drm.so.2 libEGL.so.1 libpulse.so.0 libasound.so.2 libfontconfig.so.1"

toolchain () {
	[ "$(uname -m)" = $arch ] || die "Linux builds only for this machine's $(uname -m)"
	host=$arch-linux-gnu
	export CC="gcc -fPIC" CXX="g++ -fPIC" AR=ar NM=nm RANLIB=ranlib STRIP=strip
	# pkg-config's sysroot is the prefix, so its usr shows the system's, all but usr/local.
	if [ -L "$prefix_dir/usr" ]; then
		rm "$prefix_dir/usr" && mkdir "$prefix_dir/usr" && ln -s .. "$prefix_dir/usr/local"
		for dir in /usr/*; do [ $dir = /usr/local ] || ln -s $dir "$prefix_dir/usr/"; done
	fi
	system_pkg_config=/usr/lib/$host/pkgconfig:/usr/share/pkgconfig
	crossfile linux $arch $arch
	cmake_toolchain_file Linux $arch
}

needed () { readelf -d "$1" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'; }

package () (
	local files=$(mktemp -d) lib name todo=libmpv.so.2
	trap 'rm -rf "$files"' EXIT
	# libmpv and what it loads from the prefix, transitively.
	while [ -n "$todo" ]; do
		set -- $todo
		name=$1 && shift && todo="$*"
		[ -f "$files/$name" ] && continue
		cp -L "$prefix_dir/lib/$name" "$files/"
		for lib in $(needed "$files/$name"); do
			if [ -e "$prefix_dir/lib/$lib" ]; then
				todo+=" $lib"
			elif [[ " $(echo $system_libs) " != *" $lib "* ]]; then
				die "$name loads $lib from the system"
			fi
		done
	done
	for lib in "$files"/*; do
		$STRIP --strip-unneeded "$lib"
		# Each finds the others beside it, also when loaded alone.
		patchelf --set-rpath '$ORIGIN' "$lib"
	done
	# Fails if anything libmpv loads is missing.
	python3 - "$files/libmpv.so.2" <<-'PY'
		import ctypes, sys
		mpv = ctypes.CDLL(sys.argv[1])
		mpv.mpv_create.restype = ctypes.c_void_p
		mpv.mpv_initialize.argtypes = mpv.mpv_terminate_destroy.argtypes = [ctypes.c_void_p]
		mpv.mpv_get_property_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
		mpv.mpv_get_property_string.restype = ctypes.c_char_p
		handle = mpv.mpv_create()
		assert handle and mpv.mpv_initialize(handle) == 0, 'mpv did not start'
		print(*(mpv.mpv_get_property_string(handle, p).decode() for p in (b'mpv-version', b'ffmpeg-version')))
		mpv.mpv_terminate_destroy(handle)
	PY
	cp -r "$prefix_dir/licenses" "$files/licenses"
	license_index "$files"
	zipdir "$root/out/libs-linux-$arch.zip" "$files"
)
