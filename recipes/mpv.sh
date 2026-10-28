meson_setup --default-library shared \
	-Diconv=disabled -Dlua=enabled -Dlibmpv=true -Dcplayer=false -Dmanpage-build=disabled
ninja -C $build_dir -j$cores
# Meson sometimes builds a static libmpv; starting over fixes it.
if [ -f $build_dir/libmpv.a ]; then
	rm -rf $build_dir
	exec bash -e -c '. "$root/scripts/recipe.sh"; . "$0"' "$0"
fi
DESTDIR="$dest" ninja -C $build_dir install
