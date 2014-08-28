
==========================================================
执行程序放在Edu
	Wnd32 执行程序在proj.win32的Debug.win32下.
		EDEngine.exe
		附带的内置脚本在EDEngine.exe同一个目录下.
		*.lua
		socket/*.lua
	Android程序在proj.android的bin下.
		EDEngine.apk
		附带的内置的脚本在proj.android/assets
			bootstrap.lua 用于跟新
			kits.lua 包括一些工具api
			lom.lua xml对象模型库
==========================================================
脚本程序在\\192.168.2.211\lgh下
	res目录下存的是资源文件
		amouse是地鼠游戏的相关资源.
		fonts 来至于cocos2d-x的字体文件
		Images 来至于cocos2d-x的图像文件
	src目录下放的是脚本文件
		src目录下的一些lua文件是来至于luaTest
		amouse 包括打地鼠游戏的源文件
	根目录下有三个文件
	filelist.xml 需要跟新的文件列表和MD5
	version.xml 修改版本号将导致跟新
	update.py 运行该脚本可以跟新filelist.xml文件。
==========================================================
关于编译可以看BUILD_NOTE.md
	cocos2d-x 增加了一些扩展
		luaCurl 
		luaFileSystem
		luaExpat
==========================================================
	

