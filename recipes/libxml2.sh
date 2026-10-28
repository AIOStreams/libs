# Builds only in its own tree.
args=(--host=$host --without-python --without-iconv)
# Android ships it beside FFmpeg; elsewhere it goes into FFmpeg.
[ $platform = android ] || args+=(--enable-static --disable-shared)
[ -f configure ] || ./autogen.sh "${args[@]}"
make clean || true
./configure "${args[@]}"
make -j$cores
make DESTDIR="$dest" install
