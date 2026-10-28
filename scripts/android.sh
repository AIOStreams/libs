# Android at API level 21, packaged as out/libmpv-android.aar with every ABI built so far.

archs="armv7l arm64 x86 x86_64"
ships=(mpv dovi)

dep_ffmpeg=(mbedtls dav1d libxml2)
dep_libass=(freetype2 fribidi harfbuzz unibreak)
dep_mpv=(ffmpeg libass lua libplacebo)

fetch_sdk () (
	mkdir -p "$root/sdk" && cd "$root/sdk"
	local os=linux
	[[ "$OSTYPE" == darwin* ]] && os=mac
	if [ ! -d android-sdk-$os ]; then
		msg "Fetching the Android SDK..."
		curl -fsSL --retry 3 -o tools.zip https://dl.google.com/android/repository/commandlinetools-$os-$v_sdk.zip
		mkdir android-sdk-$os.part
		unzip -q -d android-sdk-$os.part tools.zip
		rm tools.zip
		mv android-sdk-$os.part android-sdk-$os
	fi
	local sdkmanager=android-sdk-$os/cmdline-tools/latest/bin/sdkmanager
	[ -x $sdkmanager ] || sdkmanager=android-sdk-$os/cmdline-tools/bin/sdkmanager
	if [ ! -d android-sdk-$os/platforms/android-$v_sdk_platform ] || [ ! -d android-sdk-$os/build-tools/$v_sdk_build_tools ]; then
		echo y | $sdkmanager --sdk_root=android-sdk-$os \
			"platforms;android-$v_sdk_platform" "build-tools;$v_sdk_build_tools" "extras;android;m2repository"
	fi
	if [ ! -d android-ndk-$v_ndk ]; then
		msg "Fetching the Android NDK..."
		echo y | $sdkmanager --sdk_root=android-sdk-$os "ndk;$v_ndk_n"
		ln -s android-sdk-$os/ndk/$v_ndk_n android-ndk-$v_ndk
	fi
	grep -qF "$v_ndk_n" android-ndk-$v_ndk/source.properties || die "sdk/android-ndk-$v_ndk isn't $v_ndk_n"
	if [ ! -f bin/gas-preprocessor.pl ]; then
		mkdir -p bin
		curl -fsSL --retry 3 -o bin/gas-preprocessor.pl \
			https://raw.githubusercontent.com/FFmpeg/gas-preprocessor/$v_gas_preprocessor/gas-preprocessor.pl
		chmod +x bin/gas-preprocessor.pl
	fi
)

toolchain () {
	fetch_sdk
	local api=21 cc
	case $arch in
		armv7l) host=arm-linux-androideabi cc=armv7a-linux-androideabi$api ;;
		arm64) host=aarch64-linux-android cc=$host$api ;;
		x86) host=i686-linux-android cc=$host$api ;;
		x86_64) host=x86_64-linux-android cc=$host$api ;;
	esac
	local os=linux
	[[ "$OSTYPE" == darwin* ]] && os=mac
	export ANDROID_HOME="$root/sdk/android-sdk-$os"
	unset ANDROID_SDK_ROOT ANDROID_NDK_ROOT
	export PATH="$(echo "$root/sdk/android-ndk-$v_ndk/toolchains/llvm/prebuilt/"*)/bin:$root/sdk/android-ndk-$v_ndk:$root/sdk/bin:$PATH"
	export CC=$cc-clang CXX=$cc-clang++ AR=llvm-ar NM=llvm-nm RANLIB=llvm-ranlib STRIP=llvm-strip
	export LDFLAGS="-Wl,-O1,--icf=safe -Wl,-z,max-page-size=16384"
	local family=${host%%-*}
	[ $family = i686 ] && family=x86
	crossfile android $family ${cc%%-*}
}

package () (
	cd "$root/android"
	local abi var
	for abi in armv7l:PREFIX32 arm64:PREFIX64 x86_64:PREFIX_X64 x86:PREFIX_X86; do
		var=${abi#*:} abi=${abi%:*}
		[ -f "$root/prefix/android-$abi/lib/libmpv.so" ] && export $var="$root/prefix/android-$abi"
	done
	# Restored once the AAR is built.
	local utils=lib/src/main/java/is/xyz/mpv/Utils.kt
	cp $utils $utils.orig
	trap 'mv $utils.orig $utils' EXIT
	${SED:-sed} -i -e "s/%MPV_VERSION%/${v_mpv::9}/" -e "s/%LIBPLACEBO_VERSION%/${v_libplacebo::9}/" \
		-e "s/%FFMPEG_VERSION%/${v_ffmpeg::9}/" -e "s/%DATE%/$(LC_ALL=C date -u '+%b %e %Y %T')/" $utils
	ndk-build -C lib/src/main -j$cores
	./gradlew :lib:assembleRelease
	cp lib/build/outputs/aar/lib-release.aar "$root/out/libmpv-android.aar"
)
