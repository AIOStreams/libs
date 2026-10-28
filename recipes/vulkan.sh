cmake_build -DVULKAN_HEADERS_ENABLE_TESTS=OFF -DVULKAN_HEADERS_ENABLE_MODULE=OFF
# The loader's import library, without building the loader.
mkdir -p "$dest/lib/pkgconfig"
$host-dlltool -d vulkan-1.def -l "$dest/lib/libvulkan-1.dll.a"
cat >"$dest/lib/pkgconfig/vulkan.pc" <<EOF
prefix=/usr/local
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: Vulkan-Loader
Description: Vulkan Loader
Version: $v_vulkan
Libs: -L\${libdir} -lvulkan-1
Cflags: -I\${includedir}
EOF
