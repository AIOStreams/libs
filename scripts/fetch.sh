# fetch <name>: a library's pinned source in deps/<name>, fetched again when its pins change.

# <dir> <url> <commit>
clone_at () {
	git init -q "$1"
	git -C "$1" fetch -q --depth 1 "$2" "$3"
	git -C "$1" checkout -q FETCH_HEAD
	git -C "$1" submodule -q update --init --recursive
}

# <dir> <tar's compression flag> <url>
unpack () {
	mkdir "$1"
	curl -fsSL --retry 3 "$3" | tar -x"$2" -C "$1" --strip-components=1
}

fetch () (
	mkdir -p "$root/deps" && cd "$root/deps"
	local pin source=
	for pin in $(pins $1); do source+="$pin=${!pin}"$'\n'; done
	if [ -d "$1" ] && [ "$(cat "$1/.source" 2>/dev/null)"$'\n' != "$source" ]; then
		msg "$1's pin changed"
		rm -rf "$1"
	fi
	[ -d "$1" ] && return
	msg "Fetching $1..."
	# Apart first, so an interrupted download starts over.
	rm -rf "$1.part"
	case $1 in
		dav1d) clone_at $1.part https://github.com/videolan/dav1d $v_dav1d ;;
		dovi) clone_at $1.part https://github.com/quietvoid/dovi_tool $v_dovi ;;
		ffmpeg) clone_at $1.part https://github.com/AIOStreams/FFmpeg $v_ffmpeg ;;
		freetype2) git clone -q --depth 1 --recurse-submodules -b VER-${v_freetype//./-} \
			https://gitlab.freedesktop.org/freetype/freetype.git $1.part ;;
		fribidi) unpack $1.part J https://github.com/fribidi/fribidi/releases/download/v$v_fribidi/fribidi-$v_fribidi.tar.xz ;;
		harfbuzz) unpack $1.part J https://github.com/harfbuzz/harfbuzz/releases/download/$v_harfbuzz/harfbuzz-$v_harfbuzz.tar.xz ;;
		lcms2) unpack $1.part z https://github.com/mm2/Little-CMS/releases/download/lcms$v_lcms2/lcms2-$v_lcms2.tar.gz ;;
		libass) clone_at $1.part https://github.com/AIOStreams/libass $v_libass ;;
		libiconv) unpack $1.part z https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$v_libiconv.tar.gz ;;
		libplacebo) clone_at $1.part https://github.com/haasn/libplacebo $v_libplacebo ;;
		libxml2) unpack $1.part z https://gitlab.gnome.org/GNOME/libxml2/-/archive/v$v_libxml2/libxml2-v$v_libxml2.tar.gz ;;
		lua) unpack $1.part z https://www.lua.org/ftp/lua-$v_lua.tar.gz ;;
		luajit) clone_at $1.part https://github.com/LuaJIT/LuaJIT $v_luajit ;;
		mbedtls) unpack $1.part j https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$v_mbedtls/mbedtls-$v_mbedtls.tar.bz2 ;;
		mpv) clone_at $1.part https://github.com/AIOStreams/mpv $v_mpv ;;
		nvcodec-headers) clone_at $1.part https://github.com/FFmpeg/nv-codec-headers $v_nvcodec_headers ;;
		shaderc)
			clone_at $1.part https://github.com/google/shaderc $v_shaderc
			clone_at $1.part/third_party/glslang https://github.com/KhronosGroup/glslang $v_glslang
			clone_at $1.part/third_party/spirv-tools https://github.com/KhronosGroup/SPIRV-Tools $v_spirv_tools
			clone_at $1.part/third_party/spirv-headers https://github.com/KhronosGroup/SPIRV-Headers $v_spirv_headers
			;;
		spirv-cross) clone_at $1.part https://github.com/KhronosGroup/SPIRV-Cross vulkan-sdk-$v_vulkan ;;
		# freedesktop.org's downloads turn CI runners away.
		uchardet) clone_at $1.part https://gitlab.freedesktop.org/uchardet/uchardet.git $v_uchardet ;;
		unibreak) unpack $1.part z https://github.com/adah1972/libunibreak/releases/download/libunibreak_${v_unibreak//./_}/libunibreak-$v_unibreak.tar.gz ;;
		# The loader's exports make its import library.
		vulkan)
			clone_at $1.part https://github.com/KhronosGroup/Vulkan-Headers vulkan-sdk-$v_vulkan
			curl -fsSL --retry 3 -o $1.part/vulkan-1.def \
				https://raw.githubusercontent.com/KhronosGroup/Vulkan-Loader/vulkan-sdk-$v_vulkan/loader/vulkan-1.def
			;;
		zlib) unpack $1.part J https://github.com/madler/zlib/releases/download/v$v_zlib/zlib-$v_zlib.tar.xz ;;
		*) die "No source for $1" ;;
	esac
	printf %s "$source" >"$1.part/.source"
	mv "$1.part" "$1"
)

pins () {
	case $1 in
		freetype2) echo v_freetype ;;
		shaderc) echo v_shaderc v_glslang v_spirv_tools v_spirv_headers ;;
		spirv-cross) echo v_vulkan ;;
		*) echo v_${1//-/_} ;;
	esac
}
