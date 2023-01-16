# Copyright (c) 2021 caoccao.com Sam Cao
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# usage: docker build -t sjtucaocao/javet:2.0.0 \
#	--build-args TARGET=x86_64 \
#	--jobs=$(($( getconf _NPROCESSORS_ONLN ) - 1)) -f docker/linux/linux.Dockerfile .

# Only run with other debian-based images of similar version for now
# e.g. navikey/raspbian-bullseye:2022-05-08
ARG BASE_OS_IMAGE=ubuntu:20.04

# --------- Start of Builds --------------
# Initial stage adds all parameters and basic
# dependencies that are good to have for most
# stages until cleanup
FROM --platform=linux/amd64 $BASE_OS_IMAGE AS minimal_javet_buildenv

# Reduce output of noisy commands
ARG LOG_VERBOSE=false
ENV LOG_VERBOSE=${LOG_VERBOSE}
# v8 version
ARG JAVET_V8_VERSION=10.8.168.20
ENV JAVET_V8_VERSION=${JAVET_V8_VERSION}
# NodeJS version
ARG JAVET_NODEJS_VERSION=18.12.1
ENV JAVET_NODEJS_VERSION=${JAVET_NODEJS_VERSION}
# OpenJDK version number
ARG OPEN_JDK_VERSION=8
ENV OPEN_JDK_VERSION=${OPEN_JDK_VERSION}
# Version of GCC compiler to use, also determines cross-compilation library versions
ARG GCC_MAJOR_VERSION=9
ENV GCC_MAJOR_VERSION=${GCC_MAJOR_VERSION}

# CPU archetectures to build for (only one at a time)
# e.g. 'x86_64' 'amd64' 'arm' 'arm64' 'x86'
ARG TARGET=amd64
ENV TARGET=${TARGET}

ENV JAVA_HOME=/usr/lib/jvm/java-${OPEN_JDK_VERSION}-openjdk-amd64
ENV SDKMAN_HOME="/root/.sdkman"
ENV GRADLE_HOME="${SDKMAN_HOME}/candidates/gradle/current"

ENV PATH=$GRADLE_HOME/bin:$PATH

WORKDIR /
# Update debian-based linux
ENV DEBIAN_FRONTEND=noninteractive
ENV TAR_OPTIONS=--no-same-owner
ENV PATH=/cmds/utils:$PATH
COPY ./docker/linux/helpers/utils /cmds/utils
RUN chmod +x -R /cmds \
	#&& rm -f /etc/apt/apt.conf.d/docker-clean \
	&& apt-get update --yes 1>/dev/null \
	&& apt-get install --upgrade -qq --yes --no-install-recommends \
	software-properties-common curl zip unzip wget maven sudo \
	openjdk-${OPEN_JDK_VERSION}-jdk \
	software-properties-common patchelf file gcc-$GCC_MAJOR_VERSION \
	execstack ninja-build build-essential g++-$GCC_MAJOR_VERSION \
	python3 python3-pip cmake python3-distutils python3-testresources 1>/dev/null \
	&& add-apt-repository ppa:git-core/ppa \
	&& apt-get update --yes 1>/dev/null \
	&& apt-get install --upgrade -qq --yes --no-install-recommends \
	git 1>/dev/null \
	&& platform-deps.sh install_deps "${TARGET}" \
	&& pip3 install --no-cache-dir coloredlogs \
	&& apt-get update --yes 1>/dev/null \
	&& apt-get upgrade --yes 1>/dev/null \
	&& apt-get clean --yes \
	&& git config --global init.defaultBranch main \
	&& [ "${LOG_VERBOSE}" = "false" ] && git config --global advice.detachedHead false
# Install CMake
RUN wget -q https://github.com/Kitware/CMake/releases/download/v3.21.4/cmake-3.21.4-linux-$(arch).sh \
	&& chmod 755 cmake-3.21.4-linux-$(arch).sh \
	&& mkdir -p /usr/lib/cmake \
	&& ./cmake-3.21.4-linux-$(arch).sh --skip-license --exclude-subdir --prefix=/usr/lib/cmake \
	&& ln -sf /usr/lib/cmake/bin/cmake /usr/bin/cmake \
	&& ln -sf /usr/lib/cmake/bin/cmake /bin/cmake


# Prepare V8
FROM minimal_javet_buildenv AS v8fetch_javet_buildenv
ENV PATH=/google/depot_tools:$PATH
COPY ./docker/linux/helpers/v8 /cmds/v8
RUN chmod +x -R /cmds/v8 \
	&& mkdir /google \
	&& cd /google \
	&& echo "Beginning v8 fetch" \
	&& /cmds/v8/repo-tools.sh fetch_v8_source
WORKDIR /google


# Build V8
FROM v8fetch_javet_buildenv AS v8_javet_buildenv
WORKDIR /google/v8
COPY ./scripts/python/patch_v8_build.py .
RUN /cmds/v8/plat_builds.sh run_platform_builds "${TARGET}" \
	&& echo V8 build is completed.


# Prepare Node.js
FROM minimal_javet_buildenv AS nodejsenv_javet_buildenv
WORKDIR /
COPY ./docker/linux/helpers/nodejs /cmds/nodejs
RUN mkdir -p /node && chmod +x -R /cmds/nodejs \
	&& git clone -q --depth=1 \
	--branch=v${JAVET_NODEJS_VERSION} https://github.com/nodejs/node.git /node


# Build Node.js
FROM nodejsenv_javet_buildenv AS nodejs_javet_buildenv
WORKDIR /node
ENV PATH=/rpi-newer-crosstools/bin:$PATH
COPY ./scripts/python/patch_node_build.py .
RUN /cmds/nodejs/plat_builds.sh run_platform_builds "${TARGET}" \
	&& echo 'Node.js build is completed.'

# Prepare Javet Build Environment
FROM minimal_javet_buildenv AS java_javet_buildenv
COPY --from=v8_javet_buildenv /google/v8 /google/v8
COPY --from=nodejs_javet_buildenv /node /node
RUN chmod +x -R /cmds \
	&& rm /bin/sh && ln -s /bin/bash /bin/sh \
	&& bash -c "export SDKMAN_HOME=${SDKMAN_HOME} \
	&& export JAVA_HOME=${JAVA_HOME} \
	&& sdk_install() { \
	curl -s https://get.sdkman.io?rcconfig=false | bash \
	&& source ${SDKMAN_HOME}/bin/sdkman-init.sh \
	&& sdk install gradle 7.2 \
	&& which gradle > /gradle.txt ; } \
	&& ( sdk_install || sdk_install )" 1>/dev/null \
	&& ln -rs $(cat /gradle.txt) /usr/bin/gradle


# Shrink
FROM java_javet_buildenv AS full_javet_buildenv
RUN rm -rf ${SDKMAN_HOME}/archives/* \
	&& rm -rf ${SDKMAN_HOME}/tmp/* \
	&& apt-get clean -y \
	&& rm -rf /var/lib/apt/lists/*
WORKDIR /


# Pre-cache Dependencies
FROM full_javet_buildenv AS gradle_javet_buildenv
ENV JAVA_HOME=/usr/lib/jvm/java-${OPEN_JDK_VERSION}-openjdk-amd64
RUN mkdir Javet
WORKDIR /Javet
COPY . .
RUN gradle --warn dependencies 1>/dev/null \
	&& rm -rf /Javet \
	# Completed
	&& echo Javet build base image is completed.

FROM gradle_javet_buildenv as javet_build_artifact
ENV JAVA_HOME=/usr/lib/jvm/java-${OPEN_JDK_VERSION}-openjdk-amd64
WORKDIR /

# Copy Javet
RUN mkdir Javet
WORKDIR /Javet
COPY . .

# Build JNI
WORKDIR /Javet/cpp
RUN . gcc-env.sh \
	&& JAVA_HOME=${JAVA_HOME} sh ./build-linux.sh \
	-DV8_DIR=/google/v8 \
	-DCMAKE_LINUX_ARCH=$(cmake-targets.sh cmake_arch "${TARGET}")
RUN . gcc-env.sh \
	&& JAVA_HOME=${JAVA_HOME} sh ./build-linux.sh \
	-DNODE_DIR=/node \
	-DCMAKE_LINUX_ARCH=$(cmake-targets.sh "${TARGET}")

# Build Jar
WORKDIR /Javet
RUN touch src/main/resources/libjavet-v8*
RUN gradle build test --rerun-tasks --scan
FROM javet_build_artifact AS javet_build_jar
RUN touch src/main/resources/libjavet-node*
RUN gradle test --rerun-tasks --debug

VOLUME /output

# Completed
RUN echo Javet build is completed.
