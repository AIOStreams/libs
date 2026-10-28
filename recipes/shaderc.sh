cmake_build -DSHADERC_SKIP_TESTS=ON -DSHADERC_SKIP_EXAMPLES=ON -DSHADERC_SKIP_COPYRIGHT_CHECK=ON \
	-DSPIRV_SKIP_EXECUTABLES=ON -DSPIRV_SKIP_TESTS=ON -DSPIRV_HEADERS_SKIP_EXAMPLES=ON \
	-DENABLE_GLSLANG_BINARIES=OFF -DSPIRV_TOOLS_BUILD_STATIC=ON
# It builds shared copies too, which nothing should link.
rm -f "$dest"/bin/lib{shaderc_shared,SPIRV-Tools-shared}.dll "$dest"/lib/lib{shaderc_shared,SPIRV-Tools-shared}.dll.a \
	"$dest/lib/pkgconfig/SPIRV-Tools-shared.pc"
# Everything in one library, which mpv and libplacebo look for as shaderc, with the C++ library.
sed '/^Libs:/ s|$| -lc++|' "$dest/lib/pkgconfig/shaderc_combined.pc" >"$dest/lib/pkgconfig/shaderc.pc"
