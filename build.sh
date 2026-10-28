#!/bin/bash -e
# Builds a platform's libraries for one architecture and packages them into out/:
#   ./build.sh [--clean] [--no-deps] <platform> <arch> [library]
# With a library, builds only it and what it needs (or only it, with --no-deps). A
# platform is scripts/<platform>.sh, a library's build recipes/<library>.sh. Sources go
# in deps/, toolchains in sdk/, each build in prefix/<platform>-<arch>.

root=$(cd "$(dirname "$0")" && pwd)
. "$root/scripts/common.sh"
. "$root/scripts/fetch.sh"

usage () {
	sed -n '2,6p' "$0" | cut -c3- >&2
	echo "Platforms: $(cd "$root/scripts" && ls | sed -n 's/\.sh$//p' | grep -vx 'common\|fetch\|recipe' | xargs)" >&2
	exit 1
}

clean=0 nodeps=0
while [ $# -gt 0 ]; do
	case $1 in
		--clean) clean=1 ;;
		-n|--no-deps) nodeps=1 ;;
		-h|--help) usage ;;
		-*) die "Unknown option $1" ;;
		*) break ;;
	esac
	shift
done
[ $# -ge 2 ] || usage
platform=$1 arch=$2 library=$3
case $platform in common|fetch|recipe) usage ;; esac
[ -f "$root/scripts/$platform.sh" ] || usage
. "$root/scripts/$platform.sh"
[[ " $archs " == *" $arch "* ]] || die "$platform has no $arch, only $archs"

export root platform arch cores
export prefix_dir="$root/prefix/$platform-$arch"
export build_dir=_build-$platform-$arch
export crossfile="$prefix_dir/crossfile.txt"
mkdir -p "$prefix_dir" "$root/out"
# Everything installs to /usr/local in the prefix, which these make the prefix itself.
[ -e "$prefix_dir/usr" ] || ln -s . "$prefix_dir/usr"
[ -e "$prefix_dir/local" ] || ln -s . "$prefix_dir/local"
unset CC CXX CPATH LIBRARY_PATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
toolchain
export host
export PKG_CONFIG_SYSROOT_DIR="$prefix_dir" PKG_CONFIG_LIBDIR="$prefix_dir/usr/local/lib/pkgconfig"
unset PKG_CONFIG_PATH

# What a library's build depends on: its recipe, pin and patches, the platform, the
# toolchains, and what it was built with.
inputs () {
	local pin=v_$1 needs="dep_$1[*]" dep
	[ $1 = freetype2 ] && pin=v_freetype
	{
		cat "$root/recipes/$1.sh" "$root/scripts/"{$platform,common,recipe}.sh
		grep "^$pin=\|^v_\(sdk\|ndk\|gas_preprocessor\|llvm_mingw\)" "$root/sources.sh"
		cat "$root/patches/$1"/*.patch 2>/dev/null || true
		for dep in ${!needs}; do cat "$prefix_dir/.built/$dep"; done
	} | sha256 | cut -d' ' -f1
}

declare -A built
build () {
	local name=$1 dep needs="dep_$1[*]"
	[ -n "${built[$name]}" ] && return
	if [ $nodeps -eq 0 ]; then
		for dep in ${!needs}; do build $dep; done
	fi
	built[$name]=1
	local stamp="$prefix_dir/.built/$name"
	if [ $clean -eq 0 ] && [ "$(cat "$stamp" 2>/dev/null)" = "$(inputs $name)" ]; then
		msg "$name for $platform $arch is up to date"
		return
	fi
	fetch $name
	msg "Building $name for $platform $arch..."
	rm -f "$stamp"
	[ $clean -eq 1 ] && rm -rf "$root/deps/$name/$build_dir"
	(cd "$root/deps/$name" && bash -e -c '. "$root/scripts/recipe.sh"; . "$0"' "$root/recipes/$name.sh")
	# Its licence, for the packages.
	rm -rf "$prefix_dir/licenses/$name" && mkdir -p "$prefix_dir/licenses/$name" "$prefix_dir/.built"
	find "$root/deps/$name" -maxdepth 1 -type f \( -iname 'COPYING*' -o -iname 'LICENSE*' -o -iname 'COPYRIGHT*' \) \
		-exec cp {} "$prefix_dir/licenses/$name/" \;
	inputs $name >"$stamp"
}

if [ -n "$library" ]; then
	build $library
else
	for name in "${ships[@]}"; do build $name; done
	msg "Packaging $platform $arch..."
	package
fi
