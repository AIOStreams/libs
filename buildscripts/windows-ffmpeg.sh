#!/bin/bash -e

# Builds FFmpeg's avcodec and avutil for Windows from the pinned sources and patches, with only
# the decoders AIOStreams' desktop app makes seek-bar thumbnails with, AV1 through dav1d.
# Needs llvm-mingw's <arch>-w64-mingw32-* tools, meson, ninja and nasm on PATH.
# Usage: ./windows-ffmpeg.sh x86_64|aarch64, which writes windows/ffmpeg-windows-<arch>.zip

cd "$(dirname "$0")"
. ./include/depinfo.sh
. ./include/sources.sh

arch=$1
case "$arch" in
	x86_64|aarch64) ;;
	*) echo "Usage: $0 x86_64|aarch64" >&2; exit 1 ;;
esac
triple=$arch-w64-mingw32
out=$PWD/windows
prefix=$out/prefix-$arch

mkdir -p deps "$out" && cd deps
[ ! -d dav1d ] && clone_at dav1d https://github.com/videolan/dav1d $v_dav1d
[ ! -d ffmpeg ] && clone_at ffmpeg https://github.com/FFmpeg/FFmpeg $v_ffmpeg
apply_patches

rm -rf "$prefix"
cat >"$out/cross-$arch.txt" <<EOF
[binaries]
c = '$triple-clang'
ar = '$triple-ar'
strip = '$triple-strip'
windres = '$triple-windres'

[host_machine]
system = 'windows'
cpu_family = '$arch'
cpu = '$arch'
endian = 'little'
EOF
rm -rf dav1d/_build-windows-$arch
meson setup dav1d/_build-windows-$arch dav1d --cross-file "$out/cross-$arch.txt" \
	--buildtype release --default-library static --prefix "$prefix" --libdir lib \
	-Denable_tools=false -Denable_tests=false
ninja -C dav1d/_build-windows-$arch install

rm -rf ffmpeg/_build-windows-$arch
mkdir ffmpeg/_build-windows-$arch && cd ffmpeg/_build-windows-$arch
PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig" ../configure \
	--prefix="$prefix" --target-os=mingw32 --arch=$arch --enable-cross-compile \
	--cross-prefix=$triple- --cc=$triple-clang --pkg-config=pkg-config --pkg-config-flags=--static \
	--enable-shared --disable-static --enable-w32threads \
	--disable-everything --disable-programs --disable-doc --disable-autodetect --disable-network \
	--disable-avformat --disable-avfilter --disable-avdevice --disable-swscale --disable-swresample \
	--enable-libdav1d --enable-decoder=h264,hevc,vp9,mpeg1video,mpeg2video,libdav1d
make -j"$(nproc)"
make install
cd ../..

files=$(mktemp -d)
for dll in "$prefix"/bin/avcodec-*.dll "$prefix"/bin/avutil-*.dll; do
	$triple-strip -o "$files/$(basename "$dll")" "$dll"
done
cp ffmpeg/COPYING.LGPLv2.1 "$files/FFmpeg-COPYING.LGPLv2.1"
cp dav1d/COPYING "$files/dav1d-COPYING"
python3 -c 'import os, sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted(sys.argv[2:]): z.write(f, os.path.basename(f))' "$out/ffmpeg-windows-$arch.zip" "$files"/*
rm -rf "$files"
echo "$out/ffmpeg-windows-$arch.zip"
