args=(-Dtests=disabled -Ddocs=disabled)
# FreeType only, none of the build machine's libraries
[ $platform = linux ] && args+=(-Dauto_features=disabled -Dfreetype=enabled)
meson_build "${args[@]}"
