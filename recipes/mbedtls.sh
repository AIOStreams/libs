# Builds only in its own tree.
make clean
if [[ $host == i686* ]]; then
	./scripts/config.py unset MBEDTLS_AESNI_C
else
	./scripts/config.py set MBEDTLS_AESNI_C
fi
make -j$cores no_test
make DESTDIR="$prefix_dir" install
