# Only what Direct3D 11 needs: GLSL in, HLSL out.
cmake_build -DSPIRV_CROSS_CLI=OFF -DSPIRV_CROSS_ENABLE_TESTS=OFF -DSPIRV_CROSS_SHARED=OFF -DSPIRV_CROSS_STATIC=ON \
	-DSPIRV_CROSS_ENABLE_{MSL,CPP,REFLECT,UTIL}=OFF
# mpv and libplacebo look for the shared C API; this is the static one, with what it links.
sed -e 's/^Name: .*/Name: spirv-cross-c-shared/' \
	-e 's/^Libs: .*/Libs: -L${libdir} -lspirv-cross-c -lspirv-cross-hlsl -lspirv-cross-glsl -lspirv-cross-core -lc++/' \
	"$dest/lib/pkgconfig/spirv-cross-c.pc" >"$dest/lib/pkgconfig/spirv-cross-c-shared.pc"
