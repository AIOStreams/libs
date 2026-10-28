cmake_build -DZLIB_BUILD_SHARED=OFF -DZLIB_BUILD_TESTING=OFF
# Named libzs.a on MinGW, though zlib.pc links -lz.
if [ -f "$dest/lib/libzs.a" ]; then mv "$dest/lib/libzs.a" "$dest/lib/libz.a"; fi
