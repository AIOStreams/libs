# macOS 11 and later, built on a Mac, packaged as out/libmpv-macos-<arch>.zip.

archs="arm64 x86_64"
ships=(mpv)

dep_ffmpeg=(dav1d libxml2 dovi)
dep_libass=(freetype2 fribidi harfbuzz unibreak)
dep_vulkan=(moltenvk)
dep_libplacebo=(vulkan shaderc lcms2 dovi)
dep_mpv=(ffmpeg libass luajit uchardet libplacebo)

toolchain () {
	host=${arch/arm64/aarch64}-apple-darwin
	export MACOSX_DEPLOYMENT_TARGET=11.0
	local flags="-arch $arch -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
	export CC="clang $flags" CXX="clang++ $flags" AR=ar NM=nm RANLIB=ranlib STRIP=strip
	# Homebrew's, not Apple's libtool
	export LIBTOOLIZE=glibtoolize
	crossfile darwin ${arch/arm64/aarch64} $arch
	cmake_toolchain_file Darwin $arch
}

package () (
	local files=$(mktemp -d) dylib name lib todo=libmpv.2.dylib
	trap 'rm -rf "$files"' EXIT
	# libmpv and what it loads from the prefix, transitively.
	while [ -n "$todo" ]; do
		set -- $todo
		name=$1 && shift && todo="$*"
		[ -f "$files/$name" ] && continue
		cp "$prefix_dir/lib/$name" "$files/"
		todo+=" $(otool -L "$files/$name" | sed -En 's#^[[:space:]]*(/usr/local/lib|@rpath)/([^ ]*) .*#\2#p' | xargs)"
	done
	for dylib in "$files"/*.dylib; do
		name=$(basename "$dylib")
		# Khronos signed it, and it loads by @rpath already.
		[ $name = libMoltenVK.dylib ] && continue
		chmod u+w "$dylib"
		install_name_tool -id "@rpath/$name" "$dylib"
		for lib in $(otool -L "$dylib" | sed -En 's#^[[:space:]]*(/usr/local/lib/[^ ]*) .*#\1#p'); do
			install_name_tool -change "$lib" "@rpath/$(basename "$lib")" "$dylib"
		done
		# dyld refuses a library that lists a run path twice.
		otool -l "$dylib" | grep -q 'path @loader_path ' || install_name_tool -add_rpath @loader_path "$dylib"
		strip -x "$dylib"
		codesign -f -s - "$dylib"
	done
	# Fails if anything libmpv loads is missing.
	arch -$arch /usr/bin/python3 - "$files/libmpv.2.dylib" <<-'PY'
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
	zipdir "$root/out/libmpv-macos-$arch.zip" "$files"
)
