# Khronos' build, which implements Vulkan on Metal: its library for this architecture, and
# its headers.
mkdir -p "$dest/lib" "$dest/include"
lipo MoltenVK/dynamic/dylib/macOS/libMoltenVK.dylib -thin $arch -output "$dest/lib/libMoltenVK.dylib"
cp -R MoltenVK/include/MoltenVK "$dest/include/"
