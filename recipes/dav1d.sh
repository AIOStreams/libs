args=(-Denable_tests=false -Denable_tools=false)
[ $platform = android ] && args+=(-Db_lto=true -Dstack_alignment=16)
meson_build "${args[@]}"
