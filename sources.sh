# Every source the builds use: a version where the project publishes release archives,
# otherwise a commit, so each build gets exactly these. scripts/fetch.sh downloads them.

## Toolchains
v_sdk=11076708_latest
# v_ndk and v_ndk_n name the same NDK; its download page lists both
v_ndk=r29
v_ndk_n=29.0.14206865
v_sdk_platform=35
v_sdk_build_tools=35.0.0
v_gas_preprocessor=ac1836309c2e77023c228b7184485597286289d3
# llvm-mingw for Windows, and the SHA-256 of its Ubuntu x86_64 archive
v_llvm_mingw=20261006
v_llvm_mingw_sha256=5f9c6ed95b2d4bdb2869a488c5fd5857fbdabcf288a0aa3eb1da43f6a08d8ab4

## Libraries
v_lua=5.2.4
v_unibreak=6.1
v_harfbuzz=12.2.0
v_fribidi=1.0.16
v_freetype=2.14.1
v_mbedtls=3.6.5
v_libxml2=2.13.5
v_dav1d=54706fc6bc0cdecab7e9593974a4039cc038fca7 # 1.5.4
v_ffmpeg=7ef5a794c42abcb4a62e1ab22f4ae3ce40aee729
v_libass=f61db567e6593df3470e91594bcd4ad2d0473aff # master, after 0.17.5
v_libplacebo=0d043c7f6f79cd3687c023454bdacbe615e4d96f
v_mpv=36abaa32d00a7229ee206aae12dc0e97e7962dca
v_dovi=d1abe0e27ff2c7ab3339614d06db9f8a058af6b2 # libdovi 3.4.0
