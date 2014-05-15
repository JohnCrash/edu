1.安装NDK
2.安装ADT (android develop tools?)
3.安装cocos2d-x
4.安装vc2012

设置环境变量
ANDROID_SDK = C:\adt-bundle-windows-x86-20140321\sdk\platforms;C:\adt-bundle-windows-x86-20140321\sdk\tools;C:\adt-bundle-windows-x86-20140321\sdk\platform-tools
ANDROID_SDK_ROOT = C:\adt-bundle-windows-x86-20140321\sdk
ANT_HOME = C:\apache-ant-1.9.3
ANT_ROOT = C:\apache-ant-1.9.3
COCOS_CONSOLE_ROOT = D:\1Source\cocos2d-x-3.0\tools\cocos2d-console\bin
COCOS_ROOT = D:\1Source\cocos2d-x-3.0
JAVA_HOME = C:\Program Files\Java\jdk1.8.0_05
NDK_ROOT = C:\android-ndk-r9d
Path = D:\1Source\cocos2d-x-3.0\tools\cocos2d-console\bin;;C:\Program Files\IDM Computer Solutions\UltraEdit\;C:\Program Files\IDM Computer Solutions\UltraCompare\;C:\Python27\;C:\cygwin\bin;C:\apache-ant-1.9.3\bin;%JAVA_HOME%\bin;%ANDROID_SDK%

运行cocos2d设置setup.py

================================================================================
cocos2d-x修改
增加curl lua接口 luacurl
增加luafilesystem
增加luaexpat-1.3.0
================================================================================
anroid 下编译需要修改cocos2d-x的一系列编译文件
vc2012 直接在工程文件中增加文件
\cocos\scripting\lua-bindings\Android.mk