# Builds only in its own tree.
make clean
cflags=(
	# for libmpv.so
	-fPIC
	# bionic lacks decimal_point in localeconv [src/llex.c]
	-Dgetlocaledecpoint\\\(\\\)=\\\(46\\\)
	# nor has ftello/fseeko [src/liolib.c]
	-Dlua_fseek
)
# LUA_T= and LUAC_T= leave out the lua and luac programs.
make CC="$CC" AR="$AR rc" RANLIB="$RANLIB" MYCFLAGS="${cflags[*]}" PLAT=linux LUA_T= LUAC_T= -j$cores
# TO_BIN=/dev/null leaves them out of the install too.
make INSTALL=${INSTALL:-install} INSTALL_TOP="$dest/usr/local" TO_BIN=/dev/null install
# make pc writes only the variables.
mkdir -p "$dest/lib/pkgconfig"
{
	make pc
	cat <<'PC'
Name: Lua
Description:
Version: ${version}
Libs: -L${libdir} -llua
Cflags: -I${includedir}
PC
} >"$dest/lib/pkgconfig/lua.pc"
