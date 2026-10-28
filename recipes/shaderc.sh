cmake_build -DSHADERC_SKIP_TESTS=ON -DSHADERC_SKIP_EXAMPLES=ON -DSHADERC_SKIP_COPYRIGHT_CHECK=ON \
	-DSPIRV_SKIP_EXECUTABLES=ON -DSPIRV_SKIP_TESTS=ON -DSPIRV_HEADERS_SKIP_EXAMPLES=ON \
	-DENABLE_GLSLANG_BINARIES=OFF -DSPIRV_TOOLS_BUILD_STATIC=ON
# Nothing may link its shared copies.
rm -f "$dest"/{bin,lib}/lib{shaderc_shared,SPIRV-Tools-shared}.* "$dest/lib/pkgconfig/SPIRV-Tools-shared.pc"
# mpv and libplacebo look for the combined library as shaderc.
sed '/^Libs:/ s|$| -lc++|' "$dest/lib/pkgconfig/shaderc_combined.pc" >"$dest/lib/pkgconfig/shaderc.pc"
