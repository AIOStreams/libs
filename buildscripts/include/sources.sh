# Fetching the pinned sources, for download-deps.sh and windows-ffmpeg.sh; run inside deps/

# A repository at one commit, with its submodules
clone_at () {
	git init -q "$1"
	git -C "$1" fetch -q --depth 1 "$2" "$3"
	git -C "$1" checkout -q FETCH_HEAD
	git -C "$1" submodule -q update --init --recursive
}

# patches/<dependency>/*.patch in name order, each applied once, to the dependencies present;
# <dependency>/.patches lists those applied
apply_patches () {
	local p d id
	for p in ../patches/*/*.patch; do
		[ -f "$p" ] || continue
		d=$(basename "$(dirname "$p")")
		[ -d "$d" ] || continue
		id="$(basename "$p") $(sha256sum <"$p" | cut -d' ' -f1)"
		grep -qxF "$id" "$d/.patches" 2>/dev/null && continue
		patch -d $d -p1 -R -s -f --dry-run <"$p" >/dev/null || patch -d $d -p1 -N -s <"$p"
		echo "$id" >>"$d/.patches"
	done
}
