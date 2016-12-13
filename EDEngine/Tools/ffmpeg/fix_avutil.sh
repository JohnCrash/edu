#!/bin/sh

xcrun -sdk iphoneos lipo built/arm64/lib/libavutil.a -output built/arm64/lib/libavutil.a -thin arm64 
xcrun -sdk iphoneos lipo -output built/universal/lib/libavutil.a -create -arch armv7 built/armv7/lib/libavutil.a -arch arm64 built/arm64/lib/libavutil.a
 
