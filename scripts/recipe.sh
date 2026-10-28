# What recipes/ use; build.sh runs each in deps/<name> with this sourced. Each builds in
# $build_dir with the given options and installs to /usr/local in $dest.

meson_setup () (
	unset CC CXX # meson reads these as the build machine's
	if [ -d "$build_dir/meson-private" ]; then
		meson setup --reconfigure "$build_dir" --cross-file "$crossfile" "$@" && return
		# As after the checkout moved, or meson changed: start over.
		rm -rf "$build_dir"
	fi
	meson setup "$build_dir" --cross-file "$crossfile" "$@"
)

meson_build () {
	meson_setup "$@"
	ninja -C "$build_dir" -j$cores
	DESTDIR="$dest" ninja -C "$build_dir" install
}

configure_build () (
	mkdir -p "$build_dir" && cd "$build_dir"
	../configure --host=$host "$@"
	make -j$cores
	make DESTDIR="$dest" install
)
