case $platform in
	android) args=(-Diconv=disabled -Dlua=enabled) ;;
	windows)
		# meson looks for iconv beside the compiler; the C++ and thread runtimes link in.
		link="['-L$prefix_dir/lib', '-static-libgcc', '-Wl,-Bstatic', '-lc++', '-lwinpthread', '-Wl,-Bdynamic']"
		args=(
			-Dlua=luajit -D{iconv,uchardet,lcms2,d3d11,vulkan,shaderc,spirv-cross}=enabled
			-D{c,cpp}_args=-I$prefix_dir/include -D{c,cpp}_link_args="$link"
		)
		;;
	macos)
		args=(
			-Dlua=luajit -D{iconv,uchardet,lcms2,vulkan,moltenvk,gl,plain-gl,gl-cocoa,cocoa}=enabled
			-D{coreaudio,avfoundation,vo-avfoundation,videotoolbox-gl,videotoolbox-pl}=enabled
			-D{macos-touchbar,macos-media-player}=disabled
			-Dswift-flags="-target $arch-apple-macos$MACOSX_DEPLOYMENT_TARGET"
			-D{c,objc}_link_args=-Wl,-headerpad_max_install_names
		)
		;;
esac
meson_setup --default-library shared -Dlibmpv=true -Dcplayer=false -Dmanpage-build=disabled "${args[@]}"
ninja -C $build_dir -j$cores
# Meson sometimes builds a static libmpv; starting over fixes it.
if [ -f $build_dir/libmpv.a ]; then
	rm -rf $build_dir
	exec bash -e -c '. "$root/scripts/recipe.sh"; . "$0"' "$0"
fi
DESTDIR="$dest" ninja -C $build_dir install
