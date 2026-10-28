[ -f configure ] || ./autogen.sh
configure_build --with-pic --enable-static --disable-shared --enable-libunibreak --disable-require-system-font-provider
