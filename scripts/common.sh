# What build.sh and the platforms share; sourced, with root set to the repository.

. "$root/sources.sh"

if [[ "$OSTYPE" == darwin* ]]; then
	cores=${cores:-$(sysctl -n hw.ncpu)}
	# Several builds rely on GNU's sed and install.
	export SED=gsed INSTALL=ginstall
else
	cores=${cores:-$(nproc)}
fi

msg () { printf >&2 '\e[1;34m%s\e[m\n' "$*"; }
die () { printf >&2 '\e[1;31m%s\e[m\n' "$*"; exit 1; }

sha256 () {
	if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

# A file, checked against its SHA-256: <file> <url> <sha256>
download () {
	curl -fsSL --retry 3 -o "$1.part" "$2"
	echo "$3  $1.part" | sha256 -c --quiet - || die "$2 isn't the pinned file"
	mv "$1.part" "$1"
}

# meson's cross file for the prefix: <system> <cpu family> <cpu> [more [binaries] lines]
crossfile () {
	cat >"$crossfile.tmp" <<-EOF
		[built-in options]
		buildtype = 'release'
		default_library = 'static'
		wrap_mode = 'nodownload'
		prefix = '/usr/local'
		[binaries]
		c = '$CC'
		cpp = '$CXX'
		ar = '$AR'
		nm = '$NM'
		strip = '$STRIP'
		pkg-config = 'pkg-config'
		${4:-}
		[host_machine]
		system = '$1'
		cpu_family = '$2'
		cpu = '$3'
		endian = 'little'
	EOF
	# Rewritten only when it changes, so meson doesn't reconfigure everything.
	if cmp -s "$crossfile.tmp" "$crossfile"; then rm "$crossfile.tmp"; else mv "$crossfile.tmp" "$crossfile"; fi
}

# CMake's toolchain file for the prefix: <system> <processor>
cmake_toolchain_file () {
	cat >"$cmake_toolchain" <<-EOF
		set(CMAKE_SYSTEM_NAME $1)
		set(CMAKE_SYSTEM_PROCESSOR $2)
		set(CMAKE_C_COMPILER $CC)
		set(CMAKE_CXX_COMPILER $CXX)
		set(CMAKE_RC_COMPILER ${RC:-})
		set(CMAKE_AR $(command -v $AR))
		set(CMAKE_RANLIB $(command -v $RANLIB))
		set(CMAKE_FIND_ROOT_PATH $prefix_dir)
		set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
		set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
		set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
		set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
	EOF
}

# A folder's files as a zip, in name order: <zip> <folder>
zipdir () {
	python3 - "$@" <<-'PY'
		import os, sys, zipfile
		out, top = sys.argv[1:]
		names = sorted(os.path.relpath(os.path.join(d, f), top) for d, _, fs in os.walk(top) for f in fs)
		with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
		    for name in names:
		        z.write(os.path.join(top, name), name)
	PY
}
