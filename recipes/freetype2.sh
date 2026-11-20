# Otherwise it finds HarfBuzz only when a cached build left one in the prefix, and on
# Linux the build machine's compression and PNG libraries.
args=(-Dharfbuzz=disabled)
[ $platform = linux ] && args+=(-D{bzip2,png,brotli}=disabled)
meson_build "${args[@]}"
