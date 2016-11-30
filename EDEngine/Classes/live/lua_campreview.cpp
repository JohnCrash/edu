#include "cocos2d.h"
#include "campreview.h"
#include "lua_campreview.h"
#include "LuaBasicConversions.h"

int lua_cocos2dx_ui_CamPreview_constructor(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::CamPreview* cobj = nullptr;
	bool ok = true;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif



	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		if (!ok)
			return 0;
		cobj = new cocos2d::ui::CamPreview();
		cobj->autorelease();
		int ID = (int)cobj->_ID;
		int* luaID = &cobj->_luaID;
		toluafix_pushusertype_ccobject(tolua_S, ID, luaID, (void*)cobj, "ccui.CamPreview");
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "CamPreview", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_CamPreview_constructor'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_CamPreview_create(lua_State* tolua_S)
{
	int argc = 0;
	bool ok = true;
#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertable(tolua_S, 1, "ccui.ImageView", 0, &tolua_err)) goto tolua_lerror;
#endif

	argc = lua_gettop(tolua_S) - 1;
	do
	{
		if (argc == 0)
		{
			cocos2d::ui::CamPreview* ret = cocos2d::ui::CamPreview::create();
			object_to_luaval<cocos2d::ui::CamPreview>(tolua_S, "ccui.CamPreview", (cocos2d::ui::CamPreview*)ret);
			return 1;
		}
	} while (0);
	ok = true;
	CCLOG("%s has wrong number of arguments: %d, was expecting %d", "create", argc, 0);
	return 0;
#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_CamPreview_create'.", &tolua_err);
#endif
	return 0;
}

int lua_cocos2dx_ui_CamPreview_createInstance(lua_State* tolua_S)
{
	int argc = 0;
	bool ok = true;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertable(tolua_S, 1, "ccui.CamPreview", 0, &tolua_err)) goto tolua_lerror;
#endif

	argc = lua_gettop(tolua_S) - 1;

	if (argc == 0)
	{
		if (!ok)
			return 0;
		cocos2d::Ref* ret = cocos2d::ui::CamPreview::createInstance();
		object_to_luaval<cocos2d::Ref>(tolua_S, "cc.Ref", (cocos2d::Ref*)ret);
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d\n ", "createInstance", argc, 0);
	return 0;
#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_CamPreview_createInstance'.", &tolua_err);
#endif
	return 0;
}

int lua_register_cocos2dx_ui_CamPreview(lua_State* tolua_S)
{
	tolua_usertype(tolua_S, "ccui.CamPreview");
	tolua_cclass(tolua_S, "CamPreview", "ccui.CamPreview", "ccui.Widget", nullptr);

	tolua_beginmodule(tolua_S, "ImageView");
	tolua_function(tolua_S, "new", lua_cocos2dx_ui_CamPreview_constructor);
	tolua_function(tolua_S, "create", lua_cocos2dx_ui_CamPreview_create);
	tolua_function(tolua_S, "createInstance", lua_cocos2dx_ui_CamPreview_createInstance);
	tolua_endmodule(tolua_S);
	std::string typeName = typeid(cocos2d::ui::CamPreview).name();
	g_luaType[typeName] = "ccui.ImageView";
	g_typeCast["ImageView"] = "ccui.ImageView";
	return 1;
}

int lua_register_CamPreview(lua_State* tolua_S)
{
	tolua_open(tolua_S);

	tolua_module(tolua_S, "ccui", 0);
	tolua_beginmodule(tolua_S, "ccui");

	lua_register_cocos2dx_ui_CamPreview(tolua_S);
	tolua_endmodule(tolua_S);
	return 1;
}