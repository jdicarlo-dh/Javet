#!/usr/bin/env bash

. normalized-ids.sh

run_platform_builds() {
	local l_target=$(/cmds/utils/normalize-target.sh normalized)
	local cc_target=$(/cmds/nodejs/arch-build-alias.sh node_make_dest_cpu $l_target)

	python3 patch_node_build.py -p ./

	local configure_args="--enable-static --without-intl --dest-cpu=$cc_target --dest-os=linux"

	local gcc_prefix

	. gcc-env.sh

	case "$l_target" in
	#"$ia32_normalized")
	#	configure_args="${configure_args} --cross-compiling"
	#	;;
	"$arm64_normalized")
		# Fix for Nodejs arm builds to bypass missing checks
		# for support for the specific flag and its variations.
		# See issue: nodejs/node#42888
		# Ultimately the conclusion was to update this flag for newer gcc versions
		# and remove in older ones
		python3 /cmds/nodejs/arm-patch.py

		configure_args="${configure_args} --cross-compiling --with-arm-float-abi=hard"
		;;
		#"$arm_normalized")
		#	configure_args="${configure_args} --cross-compiling --with-arm-float-abi=hard"
		#	;;
		#"$riscv64_normalized")
		#	configure_args="${configure_args} --cross-compiling"
		#	;;
	esac
	./configure $configure_args

	python3 patch_node_build.py -p ./
	rm patch_node_build.py
	#1>/dev/null
	make -j4 5>&1 2>&5- | egrep -v -i 'warning: ((overriding)|(ignoring old)) recipe for target'
}

if [ "$1" = "run_platform_builds" ]; then
	shift
	run_platform_builds "$@"
else
	cat <<EOF
	nodejs/plat_builds.sh [run_platform_builds]
	USAGE:
		nodejs/plat_builds.sh run_platform_builds
			Run build pipeline for each platform specified in
			the envirionment variable that's read and normalized
			by the "normalize-target.sh" script
EOF
fi
