#!/usr/bin/env sh

. normalized-ids.sh

fetch_v8_source() {
	echo "Cloning depot_tools..."
	git clone -q --depth=10 \
		--branch=main https://chromium.googlesource.com/chromium/tools/depot_tools.git
	cd depot_tools
	git checkout -q main
	cd ..
	export PATH=$PWD/depot_tools:$PATH

	# reference - https://stackoverflow.com/a/47093174/30007
	mkdir v8
	cd v8
	git init .
	local v8_repo='https://chromium.googlesource.com/v8/v8.git'

	echo "Fetching v8 repo metadata..."
	git fetch -q --depth=2 $v8_repo +refs/tags/${JAVET_V8_VERSION}:v8_${JAVET_V8_VERSION}

	echo "Checking out v8:${JAVET_V8_VERSION}..."
	git checkout -q tags/${JAVET_V8_VERSION}
	git fetch --unshallow
	cd ..

	echo "gclient root"
	maybe-verbose.sh gclient root
	echo "gclient config"
	local spec_config='solutions = [{"name": "v8","url": "'"$v8_repo"'","deps_file": "DEPS","managed": False,"custom_deps": {},},]'
	local target=$(normalize-target.sh normalized)
	local plat_cpu=$(/cmds/v8/arch-build-alias.sh v8_flg_cpu $target)
	if [ $target != "$amd64_normalized" ]; then
		spec_config="$spec_config
target_cpu = [ \"$plat_cpu\" ]"
	fi
	gclient config --spec "$spec_config"
	echo "GCLIENT CONFIG = $spec_config"
	echo "gclient sync"
	maybe-verbose.sh gclient sync --no-history
	echo "gclient runhooks"
	gclient runhooks

	cd v8
	echo "Patching build-deps script"
	sed -i 's/snapcraft/nosnapcraft/g' ./build/install-build-deps.sh
	echo "Running build-deps script"
	maybe-verbose.sh ./build/install-build-deps.sh
	echo "Restoring build-deps script"
	sed -i 's/nosnapcraft/snapcraft/g' ./build/install-build-deps.sh
	cd ..

	echo "gclient sync"
	maybe-verbose.sh gclient sync --no-history

	echo "V8 source fetched"
}

if [ "$1" = "fetch_v8_source" ]; then
	shift
	fetch_v8_source
else
	cat <<EOF
	v8/repo-tools.sh [fetch_depot_tools|fetch_v8_source|run_final_sync]
	USAGE:
		v8/repo-tools.sh fetch_depot_tools
			Clone the chromium project via Git

		v8/repo-tools.sh fetch_v8_source
			Git fetch the v8 codebase, run first GClient sync, and 
			configure the project settings to control what parts get
			"sync"ed in the next step

		v8/repo-tools.sh run_final_sync
			run final GClient sync with modified settings
EOF
fi
