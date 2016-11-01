#!/bin/bash

# Architectures to build libraries for
declare -a ARCHITECTURES=("arm" "armv7a" "x86" "arm64v8")

# OpenSSL version to download if src is missing
OPENSSL_VERSION="1.0.2j"

# Set acccording to your Android NDK
ANDROID_PLATFORM="android-21"

ANDROID_ARM_TOOLCHAIN="arm-linux-androideabi-4.9"
ANDROID_X86_TOOLCHAIN="x86-4.9"
ANDROID_ARM64_V8_TOOLCHAIN="aarch64-linux-android-4.9"

####################################################################################################
## Do not modify below this line unless you know what are you doing

ANDROID_ARM_ARCH="arch-arm"
ANDROID_X86_ARCH="arch-x86"
ANDROID_ARM64_ARCH="arch-arm64"

####################################################################################################

RETURN_DIR="$PWD"
UDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR="${UDIR}/sources_orig"

cd "${UDIR}"
if [ ! -d "${DIR}" ]; then
        OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
        echo "OpenSSL not found in ${DIR}, trying to download: ${URL}"
        curl -O "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"

        if [ ! -f "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
            echo "> ERROR: cannot find sources directory with OpenSSL library: ${DIR}"
            echo "         Please download sources at http://www.openssl.org/source/ and extract it at ${DIR}"
            exit -2
        fi

        tar -xzvf "openssl-${OPENSSL_VERSION}.tar.gz"
        mv "openssl-${OPENSSL_VERSION}" "${DIR}"
fi

# Check for rsync.
which rsync 2>/dev/null > /dev/null
RSYNC_OK=$?
if [[ $RSYNC_OK != 0 ]]; then
    echo "> Error: rsync was not found, please install it".
    exit 3
fi

####################################################################################################

# Outputs architecture directory.
function getArchDir() {
    echo "${DIR}_$1"
}

# Gets the build host architecture
function getToolchainDir(){
    _TOOLCH=$1
    ANDROID_TOOLCHAIN=""
    for host in "linux-x86_64" "linux-x86" "darwin-x86_64" "darwin-x86"
    do
      if [ -d "${ANDROID_NDK}/toolchains/${_TOOLCH}/prebuilt/$host/bin" ]; then
        ANDROID_TOOLCHAIN="${ANDROID_NDK}/toolchains/${_TOOLCH}/prebuilt/$host/bin"
        break
      fi
    done
    echo "${ANDROID_TOOLCHAIN}"
}

function cleanVars () {
    unset TOOLCHAIN_PATH
    unset MACHINE
    unset RELEASE
    unset SYSTEM
    unset ARCH
    unset CROSS_COMPILE
    unset HOSTCC
    unset TOOL
    unset NDK_TOOLCHAIN_BASENAME
    unset CC
    unset CXX
    unset LINK
    unset LD
    unset AR
    unset RANLIB
    unset STRIP
    unset ARCH_FLAGS
    unset ARCH_LINK
    unset CPPFLAGS
    unset CXXFLAGS
    unset CFLAGS
    unset LDFLAGS
}

####################################################################################################
# AMRV7a
function compileArmv7 () {
    export TOOLCHAIN_PATH=$(getToolchainDir $ANDROID_ARM_TOOLCHAIN)
    export MACHINE=armv7l
    export RELEASE=2.6.37
    export SYSTEM=android
    export ARCH=arm
    export CROSS_COMPILE="arm-linux-androideabi-"
    export ANDROID_DEV="$ANDROID_NDK/platforms/${ANDROID_PLATFORM}/${ANDROID_ARM_ARCH}/usr"
    export HOSTCC=gcc
    env
    PATH=$TOOLCHAIN_PATH:$PATH ./config shared
    PATH=$TOOLCHAIN_PATH:$PATH make depend
    PATH=$TOOLCHAIN_PATH:$PATH make
}

####################################################################################################

function compileArm64v8(){
    export TOOLCHAIN_PATH=$(getToolchainDir $ANDROID_ARM64_V8_TOOLCHAIN)
    export TOOL=aarch64-linux-android
    export SYSTEM=android
    export ARCH=arm
    export CROSS_COMPILE="aarch64-linux-android-"
    export ANDROID_DEV="$ANDROID_NDK/platforms/${ANDROID_PLATFORM}/${ANDROID_ARM64_ARCH}/usr"
    export HOSTCC=gcc
    env
    PATH=$TOOLCHAIN_PATH:$PATH ./Configure android shared
    PATH=$TOOLCHAIN_PATH:$PATH make depend
    PATH=$TOOLCHAIN_PATH:$PATH make
}

####################################################################################################

# ARM
function compileArm () {
    $ANDROID_NDK/build/tools/make-standalone-toolchain.sh --platform=${ANDROID_PLATFORM} --toolchain=${ANDROID_ARM_TOOLCHAIN} --install-dir=`pwd`/android-toolchain-arm
    export TOOLCHAIN_PATH=`pwd`/android-toolchain-arm/bin
    export TOOL=arm-linux-androideabi
    export NDK_TOOLCHAIN_BASENAME=${TOOLCHAIN_PATH}/${TOOL}
    export CC=$NDK_TOOLCHAIN_BASENAME-gcc
    export CXX=$NDK_TOOLCHAIN_BASENAME-g++
    export LINK=${CXX}
    export LD=$NDK_TOOLCHAIN_BASENAME-ld
    export AR=$NDK_TOOLCHAIN_BASENAME-ar
    export RANLIB=$NDK_TOOLCHAIN_BASENAME-ranlib
    export STRIP=$NDK_TOOLCHAIN_BASENAME-strip
    export ARCH_FLAGS="-mthumb"
    export ARCH_LINK=
    export CPPFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 "
    export CXXFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 -frtti -fexceptions "
    export CFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 "
    export LDFLAGS=" ${ARCH_LINK} "
    PATH=$TOOLCHAIN_PATH:$PATH ./Configure android shared
    PATH=$TOOLCHAIN_PATH:$PATH make depend
    PATH=$TOOLCHAIN_PATH:$PATH make
}


####################################################################################################
# x86
function compileX86 () {
    export TOOLCHAIN_PATH=$(getToolchainDir $ANDROID_X86_TOOLCHAIN)
    export MACHINE=i686
    export RELEASE=2.6.37
    export SYSTEM=android
    export ARCH=x86
    export CROSS_COMPILE="i686-linux-android-"
    export ANDROID_DEV="$ANDROID_NDK/platforms/${ANDROID_PLATFORM}/${ANDROID_X86_ARCH}/usr"
    export HOSTCC=gcc
    PATH=$TOOLCHAIN_PATH:$PATH ./config shared
    PATH=$TOOLCHAIN_PATH:$PATH make depend
    PATH=$TOOLCHAIN_PATH:$PATH make
}

####################################################################################################

#
# Builds architecture in its directory.
#
function buildArchitectureSeparately () {
    curArch=$1
    ARCHDIR=$(getArchDir $curArch)

    echo -e "\n\n\n"
    echo "================================================================================"
    echo " - ARCH: ${curArch}"
    echo "================================================================================"
    echo "> Copying architecture $curArch to $ARCHDIR/"
    rsync -a --update --exclude '*.o' -v "${DIR}/" "${ARCHDIR}/"

    # Clear old libraries, if needed.
    cd "${ARCHDIR}"
    # clearlib

    echo "> Building architecture ${curArch} in directory: ${ARCHDIR}"
    cd "${ARCHDIR}"

    # Particular build commands
    cleanVars
    case "$curArch" in
    arm64*)
        echo "64-v8a"
        compileArm64v8
        LIBDIR="${UDIR}/arch-arm64/lib"
        ;;
    armv7*)
        echo "armv7"
        compileArmv7
        LIBDIR="${UDIR}/arch-armeabi-v7a/lib"

        # includes
        mkdir -p "${UDIR}/sources/include"
        rsync -avL "${ARCHDIR}/include/" "${UDIR}/sources/include/"
        ;;
    arm)
        echo "arm"
        compileArm
        LIBDIR="${UDIR}/arch-armeabi/lib"
        ;;
    x86)
        echo "x86"
        compileX86
        LIBDIR="${UDIR}/arch-x86/lib"
        ;;
    esac
    mkdir -p "$LIBDIR"
    cp lib*.a "$LIBDIR"
    cp lib*.so "$LIBDIR"
    cp lib*.so.1.0.0 "$LIBDIR"
}

for i in "${ARCHITECTURES[@]}"
do
	buildArchitectureSeparately "${i}"
done

# Return to calling directory.
cd "${RETURN_DIR}"
echo "> DONE for [${PEX_BUILD}]"


