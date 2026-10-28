cd dolby_vision
case $platform in
	android)
		# libdovi.so as cargo-c would build it, without cargo-c.
		case $host in
			arm-linux-androideabi) target=armv7-linux-androideabi ;;
			*) target=$host ;;
		esac
		rustup target add $target
		linker=$(command -v $CC)
		target_var=$(echo $target | tr 'a-z-' 'A-Z_')
		export CARGO_TARGET_${target_var}_LINKER="$linker"
		export CC_${target//-/_}="$linker" AR_${target//-/_}=$AR
		cargo rustc --release --locked --features capi --target $target --crate-type cdylib -- \
			-C panic=abort -C link-arg=-Wl,-soname,libdovi.so -C link-arg=-Wl,-z,max-page-size=16384
		mkdir -p "$dest/lib"
		cp target/$target/release/libdolby_vision.so "$dest/lib/libdovi.so"
		;;
	macos)
		# Linked in, Rust's unwinder would be one more than Apple's linker can encode for libmpv.
		rustup target add $host
		cargo cinstall --release --locked --features capi --target $host --library-type cdylib \
			--prefix /usr/local --destdir "$dest"
		;;
esac
