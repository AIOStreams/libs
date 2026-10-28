# libdovi's C API, as cargo-c would name it, without needing cargo-c.
case $host in
	arm-linux-androideabi) target=armv7-linux-androideabi ;;
	*) target=$host ;;
esac
rustup target add $target
linker=$(command -v $CC)
target_var=$(echo $target | tr 'a-z-' 'A-Z_')
export CARGO_TARGET_${target_var}_LINKER="$linker"
export CC_${target//-/_}="$linker" AR_${target//-/_}=$AR
cd dolby_vision
cargo rustc --release --locked --features capi --target $target --crate-type cdylib -- \
	-C panic=abort -C link-arg=-Wl,-soname,libdovi.so -C link-arg=-Wl,-z,max-page-size=16384
install -D target/$target/release/libdolby_vision.so "$prefix_dir/lib/libdovi.so"
