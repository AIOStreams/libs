case $platform in
	android) args=(-Dvulkan=disabled) ;;
	windows)
		args=(
			-D{vulkan,d3d11,shaderc,lcms}=enabled -Dglslang=disabled
			-Dvulkan-registry="$prefix_dir/share/vulkan/registry/vk.xml"
		)
		;;
	macos)
		args=(
			-D{vulkan,shaderc,lcms,libdovi}=enabled -Dglslang=disabled
			-Dvulkan-registry="$prefix_dir/share/vulkan/registry/vk.xml"
		)
		;;
	linux) args=(-Dauto_features=disabled -D{opengl,gl-proc-addr,lcms,dovi}=enabled) ;;
esac
# The program binary goes after the cache header, so it gets the buffer less the header.
grep -qF 'buf_size - (GLint) sizeof(*header)' src/opengl/gpu_pass.c ||
	${SED:-sed} -i 's/GetProgramBinary(pass_gl->program, buf_size,/GetProgramBinary(pass_gl->program, buf_size - (GLint) sizeof(*header),/' src/opengl/gpu_pass.c
grep -qF 'buf_size - (GLint) sizeof(*header)' src/opengl/gpu_pass.c
meson_build -Ddemos=false "${args[@]}"
# Static linking needs the C++ library, which meson leaves out:
# https://github.com/mesonbuild/meson/issues/11300
cxxlib=c++
[ $platform = linux ] && cxxlib=stdc++
${SED:-sed} -i "/^Libs:/ s|\$| -l$cxxlib|" "$dest/lib/pkgconfig/libplacebo.pc"
