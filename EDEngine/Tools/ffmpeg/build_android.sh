export TMPDIR=G:/tmp
export PKG_CONFIG_PATH=/cygdrive/d/source/x264/build/android

if test "$1" = "config" || test "$1" = ""; then
NDK=C:/android-ndk-r9d
PLATFORM=$NDK/platforms/android-9/arch-arm/
PREBUILT=$NDK/toolchains/arm-linux-androideabi-4.8/prebuilt/windows
CPU=armeabi
OPTIMIZE_CFLAGS="-mfloat-abi=softfp -marm -mcpu=cortex-a8"
PREFIX=./android/$CPU
cpu=cortex-a8
./configure --target-os=linux \
    --prefix=$PREFIX \
    --enable-cross-compile \
    --arch=arm \
    --enable-nonfree \
    --enable-asm \
    --cc=$PREBUILT/bin/arm-linux-androideabi-gcc \
    --cross-prefix=$PREBUILT/bin/arm-linux-androideabi- \
    --nm=$PREBUILT/bin/arm-linux-androideabi-nm \
    --sysroot=$PLATFORM \
    --extra-cflags=" -O3 -fpic -DANDROID -DHAVE_SYS_UIO_H=1 $OPTIMIZE_CFLAGS " \
    --disable-shared \
    --enable-static \
    --extra-ldflags="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib  -nostdlib -lc -lm -ldl -llog" \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-ffserver \
    --enable-swscale \
    --enable-swresample \
    --enable-avformat \
    --enable-avcodec \
	--enable-protocol=http \
	--enable-protocol=rtmp \
    --disable-optimizations \
    --disable-debug \
    --disable-doc \
    --disable-stripping \
	--enable-libx264 \
	--enable-gpl \
    --enable-yasm
fi

if test "$1" = "make" || test "$1" = ""; then
	make
fi

if test "$1" = "install"; then
	mkdir build  > /dev/null
	mkdir build/include > /dev/null
	mkdir build/android > /dev/null
	mkdir build/android/armeabi > /dev/null
	
	cp libavformat/*.a ./build/android/armeabi -f
	cp libavdevice/*.a ./build/android/armeabi -f
	cp libavcodec/*.a ./build/android/armeabi -f
	cp libavutil/*.a ./build/android/armeabi -f
	cp libswresample/*.a ./build/android/armeabi -f
	cp libswscale/*.a ./build/android/armeabi -f
	cp libavfilter/*.a ./build/android/armeabi -f
	cp libpostproc/*.a ./build/android/armeabi -f
	cp ../x264/build/android/*.a ./build/android/armeabi -f
	
	cp libavformat/avformat-*.so ./build/android/armeabi -f
	cp libavdevice/avdevice-*.so ./build/android/armeabi -f
	cp libavcodec/avcodec-*.so ./build/android/armeabi -f
	cp libavutil/avutil-*.so ./build/android/armeabi -f
	cp libswresample/swresample-*.so ./build/android/armeabi -f
	cp libswscale/swscale-*.so ./build/android/armeabi -f
	cp libavfilter/avfilter-*.so ./build/android/armeabi -f
	cp libpostproc/*.so ./build/android/armeabi -f
	cp ../x264/build/android/*.so ./build/android/armeabi -f
	
	cp config.h ./build/android -f
	rm ./build/android/ffconfig.h > /dev/null
	mv ./build/android/config.h ./build/android/ffconfig.h
fi

if test "$1" = "setup"; then
	mkdir ../cocos2d-x/external/ffmpeg > /dev/null
	mkdir ../cocos2d-x/external/ffmpeg/prebuilt > /dev/null
	mkdir ../cocos2d-x/external/ffmpeg/prebuilt/android > /dev/null
	mkdir ../cocos2d-x/external/ffmpeg/prebuilt/android/armeabi > /dev/null
	mkdir ../cocos2d-x/external/ffmpeg/prebuilt/android/armeabi-v7a > /dev/null
	mkdir ../cocos2d-x/external/ffmpeg/prebuilt/android/x86 > /dev/null
	
	cp build/android/* ../cocos2d-x/external/ffmpeg/prebuilt/android -Rf
fi

#make clean
#make  -j4 install

#$PREBUILT/bin/arm-linux-androideabi-ar d libavcodec/libavcodec.a inverse.o

#$PREBUILT/bin/arm-linux-androideabi-ld -rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib  -soname libffmpeg.so -shared -nostdlib  -z noexecstack -Bsymbolic --whole-archive --no-undefined -o $PREFIX/libffmpeg.so libavcodec/libavcodec.a libavformat/libavformat.a libavutil/libavutil.a libswscale/libswscale.a -lc -lm -lz -ldl -llog --dynamic-linker=/system/bin/linker $PREBUILT/lib/gcc/arm-linux-androideabi/4.8/libgcc.a
