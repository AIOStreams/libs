# Windows: llvm-mingw's clang, cross-compiling from Linux, packaged as
# out/ffmpeg-windows-<arch>.zip: FFmpeg's avcodec and avutil with the decoders AIOStreams'
# desktop app makes seek-bar thumbnails with, AV1 through dav1d.

archs="x86_64 aarch64"
ships=(ffmpeg)

dep_ffmpeg=(dav1d)

# llvm-mingw in sdk/, downloaded once.
fetch_llvm_mingw () (
	mkdir -p "$root/sdk" && cd "$root/sdk"
	local name=llvm-mingw-$v_llvm_mingw-ucrt-ubuntu-22.04-x86_64
	[ -d $name ] && return
	msg "Fetching llvm-mingw..."
	download llvm-mingw.tar.xz https://github.com/mstorsjo/llvm-mingw/releases/download/$v_llvm_mingw/$name.tar.xz \
		$v_llvm_mingw_sha256
	tar -xf llvm-mingw.tar.xz
	rm llvm-mingw.tar.xz
)

toolchain () {
	fetch_llvm_mingw
	host=$arch-w64-mingw32
	export PATH="$root/sdk/llvm-mingw-$v_llvm_mingw-ucrt-ubuntu-22.04-x86_64/bin:$PATH"
	export CC=$host-clang CXX=$host-clang++ AR=$host-ar NM=$host-nm RANLIB=$host-ranlib STRIP=$host-strip
	crossfile windows $arch $arch "windres = '$host-windres'"
}

package () (
	local files=$(mktemp -d)
	trap 'rm -rf "$files"' EXIT
	for dll in "$prefix_dir"/bin/avcodec-*.dll "$prefix_dir"/bin/avutil-*.dll; do
		$STRIP -o "$files/$(basename "$dll")" "$dll"
	done
	cp "$prefix_dir/licenses/ffmpeg/COPYING.LGPLv2.1" "$files/FFmpeg-COPYING.LGPLv2.1"
	cp "$prefix_dir/licenses/dav1d/COPYING" "$files/dav1d-COPYING"
	zipdir "$root/out/ffmpeg-windows-$arch.zip" "$files"
)
