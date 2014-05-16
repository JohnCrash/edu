1.安装NDK
2.安装ADT (android develop tools?)
3.安装cocos2d-x
4.安装vc2012
================================================================================
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
============================================================
cocos2d-x bug
CCFileUtils.cpp 
	使用前未定义的变量 ,android下不能加载动画,wnd32下碰巧真确
	在DictMaker()构造中加入_state = SAX_NONE;
--------------------------------------------------------------------------------------------------------------
增加cc.utf8
	cc.utf8.length(s)
	cc.utf8.next(s,i)
	加入到lua_cocos2dx_auto.cpp中
		int lua_register_cocos2dx_utf8(lua_State* tolua_S)
		{
			tolua_usertype(tolua_S,"cc.utf8");
			tolua_cclass(tolua_S,"utf8","cc.utf8","",nullptr);

			tolua_beginmodule(tolua_S,"utf8");
			tolua_endmodule(tolua_S);
			std::string typeName = "utf8";
			g_luaType[typeName] = "cc.utf8";
			g_typeCast["utf8"] = "cc.utf8";
			return 1;
		}
	在lua_cocos2dx_manual.cpp中加入
		static int lua_utf8_next(lua_State* tolua_S)
		{
			size_t byte_length;
			
			const char* bytes = luaL_checklstring(tolua_S,1,&byte_length);
			
			if( bytes != nullptr && lua_isnumber(tolua_S,2) )
			{
				int idx = luaL_checkinteger(tolua_S,2);
				if( idx < byte_length && idx >= 0 )
				{
					const char* nexts = cc_utf8_next(bytes+idx);
					lua_pushnumber(tolua_S,nexts-bytes-idx);
					return 1;
				}
				else
				{
					lua_pushnumber(tolua_S,cc_utf8_strlen(bytes,byte_length));
					return 1;
				}
			}
			lua_pushnil(tolua_S);
			return 1;
		}

		//cc.utf8.length(s)
		static int lua_utf8_length(lua_State* tolua_S)
		{
			size_t byte_length;
			const char* bytes;
			bytes = luaL_checklstring(tolua_S,1,&byte_length);
			if( bytes != nullptr )
			{
				lua_pushnumber(tolua_S,cc_utf8_strlen(bytes,byte_length));
				return 1;
			}
			lua_pushnil(tolua_S);
			return 1;
		}
		
		static void extendUtf8String(lua_State* tolua_S)
		{
			lua_pushstring(tolua_S, "cc.utf8");
			lua_rawget(tolua_S, LUA_REGISTRYINDEX);
			if (lua_istable(tolua_S,-1))
			{
				tolua_function(tolua_S,"next", lua_utf8_next);
				tolua_function(tolua_S,"length",lua_utf8_length);
			}
			lua_pop(tolua_S, 1);
		}
	在register_all_cocos2dx_manual函数中加入extendUtf8String(tolua_S);
--------------------------------------------------------------------------------------------------------------	
鼠标注册函数错误
	lua_cocos2dx_auto.cpp中函数
	tolua_cocos2dx_EventListenerMouse_registerScriptHandler
	if (argc == 1) 改成if (argc == 2) ?
