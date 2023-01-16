#!/usr/bin/env sh

. normalized-ids.sh

cmake_arch() {
	local l_target="$(normalize-target.sh normalized $1)"
	[ -z "$l_target" ] && l_target="$(normalize-target.sh normalized $TARGET)"
	case "$l_target" in
	"$amd64_normalized")
		echo "x86_64"
		;;
	"$ia32_normalized")
		echo "x86"
		;;
	"$arm64_normalized")
		echo "arm64"
		;;
	"$arm_normalized")
		echo "arm"
		;;
		#"$riscv64_normalized")
		#	echo "riscv64"
		#	;;
	esac
}

if [ "$1" = "cmake_arch" ]; then
	shift
	cmake_arch "$@"
else
	cat <<EOF
	utils/cmake-targets.sh [cmake_arch] [target]
	USAGE:
		utils/cmake-targets.sh cmake_arch [target]
			ensure target name/id is one of the aliases that
			"cmake" supports
EOF
fi
