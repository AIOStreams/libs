[ -f configure ] || ./autogen.sh
case $platform in
	# Shared for the app's own subtitle renderer, with its dependencies inside.
	android) link=(--enable-shared --disable-static LDFLAGS="$LDFLAGS -Wl,--no-undefined") ;;
	*) link=(--enable-static --disable-shared) ;;
esac
configure_build --with-pic "${link[@]}" --enable-libunibreak --disable-require-system-font-provider
