cmake_build -DVULKAN_HEADERS_ENABLE_TESTS=OFF -DVULKAN_HEADERS_ENABLE_MODULE=OFF
mkdir -p "$dest/lib/pkgconfig"
case $platform in
	windows)
		# The loader's import library, without building the loader.
		$host-dlltool -d vulkan-1.def -l "$dest/lib/libvulkan-1.dll.a"
		lib=vulkan-1
		;;
	macos) lib=MoltenVK ;;
esac
cat >"$dest/lib/pkgconfig/vulkan.pc" <<EOF
prefix=/usr/local
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: Vulkan-Loader
Description: Vulkan Loader
Version: $v_vulkan
Libs: -L\${libdir} -l$lib
Cflags: -I\${includedir}
EOF
