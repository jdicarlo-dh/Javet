#!/usr/bin/env sh

. normalized-ids.sh

install_deps() {
	local all_arch="gcc-$GCC_MAJOR_VERSION g++-$GCC_MAJOR_VERSION make"
	local cross="binutils-multiarch gcc-$GCC_MAJOR_VERSION-multilib g++-$GCC_MAJOR_VERSION-multilib"
	local amd64="libc6-i386 lib32stdc++6"
	local arm64="binutils-aarch64-linux-gnu gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
	gcc-$GCC_MAJOR_VERSION-aarch64-linux-gnu g++-$GCC_MAJOR_VERSION-aarch64-linux-gnu"
	#local i386="libc6-dev-i386 libstdc++-$GCC_MAJOR_VERSION-dev-i386-cross"
	#local arm="${i386} ${amd64}"
	local last_loc="$PWD"
	local l_target_normalized=$(normalize-target.sh normalized)

	case "$l_target_normalized" in
	"$amd64_normalized")
		maybe-verbose.sh apt-get install --upgrade -qq --yes ${all_arch} ${amd64}
		;;
	"$arm64_normalized")
		maybe-verbose.sh apt-get install --upgrade -qq --yes ${all_arch} ${cross} ${arm64}
		;;
		#"$ia32_normalized")
		#	dpkg --add-architecture i386
		#	maybe-verbose.sh apt-get install --upgrade -qq --yes ${all_arch} ${cross} ${i386}
		#	;;
		#"$arm_normalized")
		#	dpkg --add-architecture i386
		#	mkdir /rpi-newer-crosstools-tmp
		#	cd /rpi-newer-crosstools-tmp
		#	# NodeJS docs say this is the cross-compiler they use for rpi arm (armv7-a) builds
		#	git clone -q --depth=1 --filter=blob:none \
		#		--sparse https://github.com/rvagg/rpi-newer-crosstools.git .
		#	git sparse-checkout "set" "x64-gcc-8.3.0-glibc-2.28"
		#	cd "$last_loc"
		#
		#	mv /rpi-newer-crosstools-tmp/x64-gcc-8.3.0-glibc-2.28/arm-rpi-linux-gnueabihf \
		#		/rpi-newer-crosstools
		#	rm -R /rpi-newer-crosstools-tmp
		#	ls -a /rpi-newer-crosstools/bin/ | grep -e 'gcc$' -e 'g++$' || echo ""
		#
		#	maybe-verbose.sh apt-get install --upgrade -qq --yes ${all_arch} ${cross} ${arm}
		#	;;
	esac

	echo "INSTALLED COMPILERS:"
	ls -a /usr/bin/ | grep -e 'gcc$' -e 'g++$' -e "g++-$GCC_MAJOR_VERSION"
}

if [ "$1" = "install_deps" ]; then
	shift
	install_deps || install_deps
fi
