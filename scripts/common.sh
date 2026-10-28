# Sourced with root set to the repository.

. "$root/sources.sh"

if [[ "$OSTYPE" == darwin* ]]; then
	cores=${cores:-$(sysctl -n hw.ncpu)}
	# Builds rely on GNU sed and install; autoconf takes a bare INSTALL as a path in the source.
	export SED=gsed INSTALL=$(command -v ginstall)
else
	cores=${cores:-$(nproc)}
fi

msg () { printf >&2 '\e[1;34m%s\e[m\n' "$*"; }
die () { printf >&2 '\e[1;31m%s\e[m\n' "$*"; exit 1; }

sha256 () {
	if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

# <file> <url> <sha256>
download () {
	curl -fsSL --retry 3 -o "$1.part" "$2"
	echo "$3  $1.part" | sha256 -c --quiet - || die "$2 isn't the pinned file"
	mv "$1.part" "$1"
}

meson_list () {
	local word list=
	for word in $1; do list+="${list:+, }'$word'"; done
	echo "[$list]"
}

# <system> <cpu family> <cpu> [more [binaries] lines]
crossfile () {
	cat >"$crossfile.tmp" <<-EOF
		[built-in options]
		buildtype = 'release'
		default_library = 'static'
		wrap_mode = 'nodownload'
		prefix = '/usr/local'
		[binaries]
		c = $(meson_list "$CC")
		cpp = $(meson_list "$CXX")
		objc = $(meson_list "$CC")
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
	# Rewritten only on a change, or meson reconfigures everything.
	if cmp -s "$crossfile.tmp" "$crossfile"; then rm "$crossfile.tmp"; else mv "$crossfile.tmp" "$crossfile"; fi
}

flags_of () { if [[ $1 == *' '* ]]; then echo "${1#* }"; fi; }

# <system> <processor>
cmake_toolchain_file () {
	cat >"$cmake_toolchain" <<-EOF
		set(CMAKE_SYSTEM_NAME $1)
		set(CMAKE_SYSTEM_PROCESSOR $2)
		set(CMAKE_C_COMPILER ${CC%% *})
		set(CMAKE_CXX_COMPILER ${CXX%% *})
		set(CMAKE_C_FLAGS_INIT "$(flags_of "$CC")")
		set(CMAKE_CXX_FLAGS_INIT "$(flags_of "$CXX")")
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

# <zip> <folder>
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

# <folder>/licenses/index.json, which the apps list licences from.
license_index () {
	local name pin
	for name in $(ls "$1/licenses"); do
		[ -d "$1/licenses/$name" ] || continue
		printf %s "$name"
		for pin in $(pins $name); do printf '\t%s=%s' $pin "${!pin}"; done
		echo
	done | python3 -c '
import json, os, sys
top = sys.argv[1]
libraries = []
for line in sys.stdin.read().splitlines():
    name, *pins = line.split("\t")
    folder = os.path.join(top, name)
    files = sorted(os.path.relpath(os.path.join(d, f), folder).replace(os.sep, "/") for d, _, fs in os.walk(folder) for f in fs)
    libraries.append({"name": name, "pins": dict(p.split("=", 1) for p in pins), "files": files})
with open(os.path.join(top, "index.json"), "w") as out:
    json.dump({"libraries": libraries}, out, indent=1)
' "$1/licenses"
}
