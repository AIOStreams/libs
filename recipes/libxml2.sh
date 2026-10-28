# Builds only in its own tree.
[ -f configure ] || ./autogen.sh --host=$host --without-python
make clean || true
./configure --host=$host --without-python --without-iconv
make -j$cores
make DESTDIR="$dest" install
