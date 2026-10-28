case $platform in
	android) args=(-Dvulkan=disabled) ;;
	windows)
		args=(
			-D{vulkan,d3d11,shaderc,lcms}=enabled -Dglslang=disabled
			-Dvulkan-registry="$prefix_dir/share/vulkan/registry/vk.xml"
		)
		;;
	macos)
		args=(
			-D{vulkan,shaderc,lcms,libdovi}=enabled -Dglslang=disabled
			-Dvulkan-registry="$prefix_dir/share/vulkan/registry/vk.xml"
		)
		;;
esac
meson_build -Ddemos=false "${args[@]}"
# Static linking needs the C++ library, which meson leaves out:
# https://github.com/mesonbuild/meson/issues/11300
${SED:-sed} -i '/^Libs:/ s|$| -lc++|' "$dest/lib/pkgconfig/libplacebo.pc"
