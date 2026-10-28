meson_build -Dvulkan=disabled -Ddemos=false
# Static linking needs the C++ library, which meson leaves out:
# https://github.com/mesonbuild/meson/issues/11300
${SED:-sed} -i '/^Libs:/ s|$| -lc++|' "$prefix_dir/lib/pkgconfig/libplacebo.pc"
