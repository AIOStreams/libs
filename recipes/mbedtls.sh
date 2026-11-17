# Builds only in its own tree.
make clean
if [[ $host == i686* ]]; then
	./scripts/config.py unset MBEDTLS_AESNI_C
else
	./scripts/config.py set MBEDTLS_AESNI_C
fi
# Mbed TLS reads /dev/random on Android, which blocks on kernels before 5.6.
./scripts/config.py set MBEDTLS_PLATFORM_DEV_RANDOM '"/dev/urandom"'
make -j$cores no_test
make DESTDIR="$dest" install
