# Builds only in its own tree; its code generator runs on the build machine.
make clean
make -j$cores HOST_CC=cc CROSS=$host- CC=clang TARGET_SYS=Windows BUILDMODE=static amalg
# Its install target doesn't know Windows.
install -D -m644 src/libluajit.a "$dest/lib/libluajit-5.1.a"
mkdir -p "$dest/include/luajit-2.1" "$dest/lib/pkgconfig"
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
