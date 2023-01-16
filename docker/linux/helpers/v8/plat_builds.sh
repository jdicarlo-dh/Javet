#!/usr/bin/env sh

. normalized-ids.sh

run_platform_builds() {
	local v8_args="v8_monolithic=true v8_use_external_startup_data=false \
		is_component_build=false v8_enable_i18n_support=false \
		v8_enable_pointer_compression=false v8_static_library=true \
		symbol_level=0 use_custom_libcxx=false v8_enable_sandbox=false"

	local l_qt='"'

	local target=$(normalize-target.sh normalized)
	local plat_release=$(/cmds/v8/arch-build-alias.sh v8_release $target)
	local plat_cpu=$(/cmds/v8/arch-build-alias.sh v8_flg_cpu $target)

	#if [ $target != "$amd64_normalized" ]; then
	#	v8_args=" target_cpu=${l_qt}$plat_cpu${l_qt} v8_target_cpu=${l_qt}$plat_cpu${l_qt} $v8_args"
	#fi

	local success=false
	echo "V8_ARGS=$v8_args"
	python3 tools/dev/v8gen.py ${plat_release}.release -- $v8_args && success=true
	if [ "$success" = false ]; then
		echo "v8get.py failed"
		exit 1
	fi

	success=false
	echo "v8 first try: ninja -C out.gn/${plat_release}.release"
	maybe-verbose.sh ninja -C out.gn/${plat_release}.release v8_monolith && success=true
	if [ "$success" = false ]; then
		python3 patch_v8_build.py -p ./
		echo "v8 try after patch: ninja -C out.gn/${plat_release}.release"
		maybe-verbose.sh ninja -C out.gn/${plat_release}.release v8_monolith
	fi

	rm patch_v8_build.py
	ln -rs out.gn/${plat_release}.release out.gn/platform.release
}

if [ "$1" = "run_platform_builds" ]; then
	shift
	run_platform_builds "$@"
else
	cat <<EOF
	v8/plat_builds.sh [run_platform_builds]
	USAGE:
		v8/plat_builds.sh run_platform_builds
			Run build pipeline for each platform specified in
			the envirionment variable that's read and normalized
			by the "normalize-target.sh" script
EOF
fi
