#!/bin/bash -e
# Packs libraries' pinned sources with their patches applied, for builds that compile them
# themselves, such as AIOStreams' Flatpak:
#   ./pack-source.sh <library>...
# Each goes to out/<library>-source.tar.gz, the same bytes for the same sources.

root=$(cd "$(dirname "$0")" && pwd)
. "$root/scripts/common.sh"
. "$root/scripts/fetch.sh"

[ $# -gt 0 ] || { sed -n '2,6p' "$0" | cut -c3- >&2; exit 1; }
mkdir -p "$root/out"
for name in "$@"; do
	fetch $name
	msg "Packing $name..."
	tar -c -C "$root/deps" --exclude=.git --exclude=.patches --exclude='_build-*' \
		--sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner "$name" |
		gzip -n -9 >"$root/out/$name-source.tar.gz"
done
