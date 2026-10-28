# fetch <name>: the pinned source of a library in deps/<name>, downloaded once, with
# patches/<name>/*.patch applied in name order, each once; deps/<name>/.patches lists them.

# A repository at one commit, with its submodules: <dir> <url> <commit>
clone_at () {
	git init -q "$1"
	git -C "$1" fetch -q --depth 1 "$2" "$3"
	git -C "$1" checkout -q FETCH_HEAD
	git -C "$1" submodule -q update --init --recursive
}

# An archive's contents without its top folder: <dir> <tar's compression flag> <url>
unpack () {
	mkdir "$1"
	curl -fsSL --retry 3 "$3" | tar -x"$2" -C "$1" --strip-components=1
}

apply_patches () {
	local p id
	for p in "$root/patches/$1"/*.patch; do
		[ -f "$p" ] || continue
		id="$(basename "$p") $(sha256 <"$p" | cut -d' ' -f1)"
		grep -qxF "$id" "$1/.patches" 2>/dev/null && continue
		patch -d "$1" -p1 -R -s -f --dry-run <"$p" >/dev/null || patch -d "$1" -p1 -N -s <"$p"
		echo "$id" >>"$1/.patches"
	done
}

fetch () (
	mkdir -p "$root/deps" && cd "$root/deps"
	if [ ! -d "$1" ]; then
		msg "Fetching $1..."
		# Into a folder of its own first, so an interrupted download starts over.
		rm -rf "$1.part"
		case $1 in
			dav1d) clone_at $1.part https://github.com/videolan/dav1d $v_dav1d ;;
			dovi) clone_at $1.part https://github.com/quietvoid/dovi_tool $v_dovi ;;
			ffmpeg) clone_at $1.part https://github.com/FFmpeg/FFmpeg $v_ffmpeg ;;
			freetype2) git clone -q --depth 1 --recurse-submodules -b VER-${v_freetype//./-} \
				https://gitlab.freedesktop.org/freetype/freetype.git $1.part ;;
			fribidi) unpack $1.part J https://github.com/fribidi/fribidi/releases/download/v$v_fribidi/fribidi-$v_fribidi.tar.xz ;;
			harfbuzz) unpack $1.part J https://github.com/harfbuzz/harfbuzz/releases/download/$v_harfbuzz/harfbuzz-$v_harfbuzz.tar.xz ;;
			libass) clone_at $1.part https://github.com/libass/libass $v_libass ;;
			libplacebo) clone_at $1.part https://github.com/haasn/libplacebo $v_libplacebo ;;
			libxml2) unpack $1.part z https://gitlab.gnome.org/GNOME/libxml2/-/archive/v$v_libxml2/libxml2-v$v_libxml2.tar.gz ;;
			lua) unpack $1.part z https://www.lua.org/ftp/lua-$v_lua.tar.gz ;;
			mbedtls) unpack $1.part j https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$v_mbedtls/mbedtls-$v_mbedtls.tar.bz2 ;;
			mpv) clone_at $1.part https://github.com/mpv-player/mpv $v_mpv ;;
			unibreak) unpack $1.part z https://github.com/adah1972/libunibreak/releases/download/libunibreak_${v_unibreak//./_}/libunibreak-$v_unibreak.tar.gz ;;
			*) die "No source for $1" ;;
		esac
		mv "$1.part" "$1"
	fi
	apply_patches "$1"
)
