#!/bin/bash

SDKVERSION="10.0"

ARCHS="armv7 arm64"

DEVELOPER=`xcode-select -print-path`

cd "`dirname \"$0\"`"
REPOROOT=$(pwd)

# where we will store intermediary builds
INTERDIR="${REPOROOT}/built"
mkdir -p $INTERDIR
export PKG_CONFIG_PATH=../x264/build/ios
for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
		EXTRA_CONFIG="--arch=i386 --disable-asm --enable-cross-compile --target-os=darwin --cpu=i386"
		EXTRA_CFLAGS="-arch i386"
		EXTRA_LDFLAGS="-arch i386 -I${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk/usr/lib"
	else
		PLATFORM="iPhoneOS"
		EXTRA_CONFIG="--arch=${ARCH} --target-os=darwin --enable-cross-compile"
	#EXTRA_CFLAGS="-marm -mfloat-abi=softfp -mcpu=cortex-a8 -w -arch ${ARCH}"
		EXTRA_CFLAGS="-w -arch ${ARCH}"
		EXTRA_LDFLAGS="-arch ${ARCH}"
	fi

	mkdir -p "${INTERDIR}/${ARCH}"

	echo "==========================================================="
	echo " configure "${ARCH}
	echo "${INTERDIR}/${ARCH}"
	echo "==========================================================="

./configure --prefix="${INTERDIR}/${ARCH}" \
    --enable-optimizations \
    --enable-neon \
    --enable-small \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-ffserver \
    --disable-iconv \
    --disable-bzlib \
    --enable-avresample \
    --enable-videotoolbox \
    --disable-shared \
    --enable-static \
    --enable-asm \
    --enable-yasm \
    --enable-protocol=http \
    --enable-protocol=rtmp \
    --enable-libx264 \
    --enable-gpl \
    --sysroot="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \
    --cc="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang" \
    --extra-cflags="${EXTRA_CFLAGS} -O3 -fpic -miphoneos-version-min=${SDKVERSION}" \
    --extra-ldflags="${EXTRA_LDFLAGS} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk -miphoneos-version-min=${SDKVERSION}" ${EXTRA_CONFIG} \
    --enable-pic \
    --extra-cxxflags="$CPPFLAGS -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk"

	#echo "==========================================================="
	#echo " make "${ARCH}
	#echo "${INTERDIR}/${ARCH}"
	#echo "==========================================================="

	make

	#echo "==========================================================="
	#echo " install "${ARCH}
	#echo "${INTERDIR}/${ARCH}"
	#echo "==========================================================="

	make install 

	#echo "==========================================================="
	#echo " clean "${ARCH}
	#echo "${INTERDIR}/${ARCH}"
	#echo "==========================================================="

	make clean
done

mkdir -p "${INTERDIR}/universal/lib"

cd "${INTERDIR}/armv7/lib"
for file in *.a
do

	cd ${INTERDIR}
	xcrun -sdk iphoneos lipo -output universal/lib/$file  -create -arch armv7 armv7/lib/$file -arch arm64 arm64/lib/$file
	echo "Universal $file created."

done


echo "Done."
