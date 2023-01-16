. normalized-ids.sh

make_vars() {
	local gcc_prefix
	local gcc_postfix=""
	local l_target

	local l_TARGET_ARCH
	local l_CC_host
	local l_CXX_host
	local l_CC
	local l_CXX

	[ -z "$1" ] || l_target="$(normalize-target.sh normalized $1)"
	[ -z "$l_target" ] && l_target="$(normalize-target.sh normalized $TARGET)"

	[ -z "$GCC_MAJOR_VERSION" ] || gcc_postfix="-$GCC_MAJOR_VERSION"

	case "$l_target" in
	"$amd64_normalized")
		gcc_prefix="x86_64-linux-gnu-"
		l_TARGET_ARCH="-march=x86_64"
		l_CC_host="gcc -m64"
		l_CXX_host="g++ -m64"
		l_CC="${gcc_prefix}gcc${gcc_postfix}"
		l_CXX="${gcc_prefix}g++${gcc_postfix}"
		;;
	"$ia32_normalized")
		gcc_prefix="aarch64-linux-gnu-" # Update if using
		l_TARGET_ARCH="-march=aarch64"  # Update if using
		l_CC_host="gcc -m32"
		l_CXX_host="g++ -m32"
		l_CC="${gcc_prefix}gcc${gcc_postfix}"
		l_CXX="${gcc_prefix}g++${gcc_postfix}"
		;;
	"$arm64_normalized")
		gcc_prefix="aarch64-linux-gnu-"
		l_TARGET_ARCH="-march=aarch64"
		l_CC_host="gcc -m64"
		l_CXX_host="g++ -m64"
		l_CC="${gcc_prefix}gcc${gcc_postfix}"
		l_CXX="${gcc_prefix}g++${gcc_postfix}"
		;;
	"$arm_normalized")
		gcc_prefix="arm-rpi-linux-gnueabihf-"
		l_TARGET_ARCH="-march=arm"
		l_CC_host="gcc -m32"
		l_CXX_host="g++ -m32"
		l_CC="${gcc_prefix}gcc${gcc_postfix}"
		l_CXX="${gcc_prefix}g++${gcc_postfix}"
		;;
		#"$riscv64_normalized")
		#	gcc_prefix="aarch64-linux-gnu-"
		#	l_TARGET_ARCH="-march=aarch64"
		#	l_CC_host="gcc"
		#	l_CXX_host="g++"
		#	l_CC="${gcc_prefix}gcc${gcc_postfix}"
		#	l_CXX="${gcc_prefix}g++${gcc_postfix}"
		#	;;
	esac
	echo "CC='$l_CC'"
	echo "CXX='$l_CXX'"
	export TARGET_ARCH="$l_TARGET_ARCH"
	export CC_host="$l_CC_host"
	export CXX_host="$l_CXX_host"
	export CC="$l_CC"
	export CXX="$l_CXX"
	export CXX_TARGET_ARCH="$TARGET_ARCH"
	export V8_TARGET_ARCH="$TARGET_ARCH"
}

make_vars "$@"
