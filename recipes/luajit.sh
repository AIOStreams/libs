# Builds only in its own tree; its code generator runs on the build machine.
make clean
case $platform in
	windows) args=(HOST_CC=cc CROSS=$host- CC=clang TARGET_SYS=Windows) ;;
	macos) args=(HOST_CC=clang CC=clang TARGET_FLAGS="${CC#* }" TARGET_SYS=Darwin) ;;
esac
make -j$cores "${args[@]}" BUILDMODE=static amalg
# Its install target knows neither Windows nor a separate destination.
mkdir -p "$dest/lib/pkgconfig" "$dest/include/luajit-2.1"
cp src/libluajit.a "$dest/lib/libluajit-5.1.a"
cp src/{lua.h,lualib.h,lauxlib.h,luaconf.h,lua.hpp,luajit.h} "$dest/include/luajit-2.1/"
cat >"$dest/lib/pkgconfig/luajit.pc" <<EOF
prefix=/usr/local
libdir=\${prefix}/lib
includedir=\${prefix}/include/luajit-2.1

Name: LuaJIT
Description: Just-in-time compiler for Lua
Version: 2.1
Libs: -L\${libdir} -lluajit-5.1
Cflags: -I\${includedir}
EOF
