#!/bin/bash -e

## Dependency versions
# Make sure to keep v_ndk and v_ndk_n in sync, both are listed on the NDK download page

v_sdk=11076708_latest
v_ndk=r29
v_ndk_n=29.0.14206865
v_sdk_platform=35
v_sdk_build_tools=35.0.0
# windows-ffmpeg.sh's toolchain, and the SHA-256 of its Ubuntu x86_64 archive
v_llvm_mingw=20261006
v_llvm_mingw_sha256=5f9c6ed95b2d4bdb2869a488c5fd5857fbdabcf288a0aa3eb1da43f6a08d8ab4

v_lua=5.2.4
v_unibreak=6.1
v_harfbuzz=12.2.0
v_fribidi=1.0.16
v_freetype=2.14.1
v_mbedtls=3.6.5
v_libxml2=2.13.5

# Commits, so each build gets exactly these sources
v_dav1d=54706fc6bc0cdecab7e9593974a4039cc038fca7 # 1.5.4
v_ffmpeg=7ef5a794c42abcb4a62e1ab22f4ae3ce40aee729
v_libass=4a05d8127f525943ebf45fdc6497c9e665947f0d # 0.17.5
v_libplacebo=0d043c7f6f79cd3687c023454bdacbe615e4d96f
v_mpv=36abaa32d00a7229ee206aae12dc0e97e7962dca
v_dovi=d1abe0e27ff2c7ab3339614d06db9f8a058af6b2 # libdovi 3.4.0


## Dependency tree
# I would've used a dict but putting arrays in a dict is not a thing

dep_mbedtls=()
dep_libxml2=()
dep_dav1d=()
dep_ffmpeg=(mbedtls dav1d libxml2)
dep_freetype2=()
dep_fribidi=()
dep_harfbuzz=()
dep_unibreak=()
dep_libass=(freetype2 fribidi harfbuzz unibreak)
dep_lua=()
dep_libplacebo=()
dep_mpv=(ffmpeg libass lua libplacebo)
dep_dovi=()
dep_mpv_android=(mpv dovi)


## for CI workflow

# filename used to uniquely identify a build prefix
ci_tarball="prefix-ndk-${v_ndk}-lua-${v_lua}-unibreak-${v_unibreak}-harfbuzz-${v_harfbuzz}-fribidi-${v_fribidi}-freetype-${v_freetype}-mbedtls-${v_mbedtls}-libxml2-${v_libxml2}-dav1d-${v_dav1d:0:12}-ffmpeg-${v_ffmpeg:0:12}-libass-${v_libass:0:12}-libplacebo-${v_libplacebo:0:12}-dovi-${v_dovi:0:12}.tgz"
