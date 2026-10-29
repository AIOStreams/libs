# Every source: a release where the project publishes archives, otherwise a commit.

## Toolchains
v_sdk=11076708_latest
# v_ndk and v_ndk_n name the same NDK; its download page lists both
v_ndk=r29
v_ndk_n=29.0.14206865
v_sdk_platform=35
v_sdk_build_tools=35.0.0
v_gas_preprocessor=ac1836309c2e77023c228b7184485597286289d3
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
v_zlib=1.3.2
v_libiconv=1.18
v_lcms2=2.19.1
v_luajit=a4c064539ea931274d407e1249b4bb575424a0f4 # v2.1
v_uchardet=ae6302a016088ad07177f86d417b20010053632b # 0.0.8
v_nvcodec_headers=n13.0.19.0
# Vulkan-Headers, the loader's exports and SPIRV-Cross share an SDK release.
v_vulkan=1.4.363.0
v_moltenvk=1.4.1 # 1.4.2 needs macOS 12
v_moltenvk_sha256=5ea0c259df7ded9a275444820f09cced54d6e5a7c7a31d262de62a5cdb7e15cf
v_shaderc=v2026.4
# shaderc's DEPS names these.
v_glslang=e1b562a8bed273a02f30b59b66a5d499793cede5
v_spirv_tools=ef96ed763b43b59b33b31b362f09a02b729fa1c9
v_spirv_headers=04fd3caa1e8267e4d95c806cad901181728e1006
v_dav1d=54706fc6bc0cdecab7e9593974a4039cc038fca7 # 1.5.4
v_libplacebo=275f7dea27924cdd34ab2e6c20e448b6bc4fab65 # v7.387.0
v_dovi=d1abe0e27ff2c7ab3339614d06db9f8a058af6b2 # libdovi 3.4.0

## Our forks: the tagged commit and the upstream one it builds on
v_ffmpeg=c0cd16a576c8a1c250b2600bd370db3ee54251cd # aiostreams-20261028.2, on 28fda48e0b
v_libass=6fd011533a0eea1d8eefa656a60f73daf23531c5 # aiostreams-20261029, on f61db567e6, after 0.17.5
v_mpv=2257f49820d113c16ccbad7846b410e149bdd5a4 # aiostreams-20261029, on a9a08cd171
