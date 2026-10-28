# Windows, cross-compiled from Linux, packaged as out/libs-windows-<arch>.zip. libmpv
# imports vulkan-1.dll, which GPU drivers install.

archs="x86_64 aarch64"
ships=(mpv)

dep_ffmpeg=(zlib dav1d libxml2 nvcodec-headers)
dep_libxml2=(zlib)
dep_freetype2=(zlib)
dep_libass=(freetype2 fribidi harfbuzz unibreak)
dep_libplacebo=(vulkan shaderc spirv-cross lcms2)
dep_mpv=(ffmpeg libass luajit libiconv uchardet libplacebo)

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
	export CC=$host-clang CXX=$host-clang++ AR=$host-ar NM=$host-nm RANLIB=$host-ranlib STRIP=$host-strip \
		RC=$host-windres
	crossfile windows $arch $arch "windres = '$RC'"
	cmake_toolchain_file Windows $arch
}

package () (
	local files=$(mktemp -d) runtime="$root/sdk/llvm-mingw-$v_llvm_mingw-ucrt-ubuntu-22.04-x86_64/$host/bin" dll
	trap 'rm -rf "$files"' EXIT
	# libmpv and what it imports from the prefix.
	for dll in libmpv-2.dll $($host-objdump -p "$prefix_dir/bin/libmpv-2.dll" | sed -n 's/^\s*DLL Name: //p'); do
		[ -f "$runtime/$dll" ] && die "libmpv-2.dll imports the toolchain's $dll, which the app doesn't ship"
		[ -f "$prefix_dir/bin/$dll" ] && $STRIP -o "$files/$dll" "$prefix_dir/bin/$dll"
	done
	cp -r "$prefix_dir/licenses" "$files/licenses"
	license_index "$files"
	zipdir "$root/out/libs-windows-$arch.zip" "$files"
)
