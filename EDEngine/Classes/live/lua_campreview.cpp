#include "cocos2d.h"
#include "campreview.h"
#include "movieview.h"
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
	if (!tolua_isusertable(tolua_S, 1, "ccui.CamPreview", 0, &tolua_err)) goto tolua_lerror;
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

int lua_cocos2dx_ui_CamPreview_startPreview(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::CamPreview* cobj = nullptr;
	bool ok = true;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.CamPreview", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::CamPreview*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_CamPreview_startPreview'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		cobj->startPreview();
		return 0;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "loadTexture", argc, 1);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_ImageView_loadTexture'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_CamPreview_stopPreview(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::CamPreview* cobj = nullptr;
	bool ok = true;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.CamPreview", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::CamPreview*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_CamPreview_startPreview'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		cobj->stopPreview();
		return 0;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "loadTexture", argc, 1);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_ImageView_loadTexture'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_CamPreview_getPreviewSize(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::CamPreview* cobj = nullptr;
	bool ok = true;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.CamPreview", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::CamPreview*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_Widget_getPreviewSize'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		if (!ok)
			return 0;
		const cocos2d::Size& ret = cobj->getPreviewSize();
		size_to_luaval(tolua_S, ret);
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "getPreviewSize", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_Widget_getPreviewSize'.", &tolua_err);
#endif

	return 0;
}

int lua_register_cocos2dx_ui_CamPreview(lua_State* tolua_S)
{
	tolua_usertype(tolua_S, "ccui.CamPreview");
	tolua_cclass(tolua_S, "CamPreview", "ccui.CamPreview", "ccui.Widget", nullptr);

	tolua_beginmodule(tolua_S, "CamPreview");
	tolua_function(tolua_S, "new", lua_cocos2dx_ui_CamPreview_constructor);
	tolua_function(tolua_S, "create", lua_cocos2dx_ui_CamPreview_create);
	tolua_function(tolua_S, "createInstance", lua_cocos2dx_ui_CamPreview_createInstance);
	tolua_function(tolua_S, "startPreview", lua_cocos2dx_ui_CamPreview_startPreview);
	tolua_function(tolua_S, "stopPreview", lua_cocos2dx_ui_CamPreview_stopPreview);
	tolua_function(tolua_S, "getPreviewSize", lua_cocos2dx_ui_CamPreview_getPreviewSize);
	tolua_endmodule(tolua_S);
	std::string typeName = typeid(cocos2d::ui::CamPreview).name();
	g_luaType[typeName] = "ccui.CamPreview";
	g_typeCast["CamPreview"] = "ccui.CamPreview";
	return 1;
}

int lua_cocos2dx_ui_MovieView_constructor(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;
	bool ok = true;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif



	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		if (!ok)
			return 0;
		cobj = new cocos2d::ui::MovieView();
		cobj->autorelease();
		int ID = (int)cobj->_ID;
		int* luaID = &cobj->_luaID;
		toluafix_pushusertype_ccobject(tolua_S, ID, luaID, (void*)cobj, "ccui.MovieView");
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "MovieView", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_constructor'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_create(lua_State* tolua_S)
{
	int argc = 0;
	bool ok = true;
#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertable(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	argc = lua_gettop(tolua_S) - 1;
	do
	{
		if (argc == 0)
		{
			cocos2d::ui::MovieView* ret = cocos2d::ui::MovieView::create();
			object_to_luaval<cocos2d::ui::MovieView>(tolua_S, "ccui.MovieView", (cocos2d::ui::MovieView*)ret);
			return 1;
		}
	} while (0);
	ok = true;
	CCLOG("%s has wrong number of arguments: %d, was expecting %d", "create", argc, 0);
	return 0;
#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_create'.", &tolua_err);
#endif
	return 0;
}

int lua_cocos2dx_ui_MovieView_createInstance(lua_State* tolua_S)
{
	int argc = 0;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertable(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	argc = lua_gettop(tolua_S) - 1;

	if (argc == 0)
	{
		cocos2d::Ref* ret = cocos2d::ui::MovieView::createInstance();
		object_to_luaval<cocos2d::Ref>(tolua_S, "cc.Ref", (cocos2d::Ref*)ret);
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d\n ", "createInstance", argc, 0);
	return 0;
#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_createInstance'.", &tolua_err);
#endif
	return 0;
}

int lua_cocos2dx_ui_MovieView_getMovieSize(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_getMovieSize'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		const cocos2d::Size& ret = cobj->getMovieSize();
		size_to_luaval(tolua_S, ret);
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "getMovieSize", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_getMovieSize'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_open(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_open'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 1)
	{
		std::string arg0;
		luaval_to_std_string(tolua_S, 2, &arg0);
		bool ret = cobj->open(arg0.c_str());
		tolua_pushboolean(tolua_S, ret);
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_open'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_close(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_close'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		cobj->close();
		tolua_pushboolean(tolua_S, true);
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_close'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_length(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_length'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushnumber(tolua_S, cobj->length());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_length'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_cur(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_cur'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushnumber(tolua_S, cobj->cur());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_cur'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_seek(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_seek'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 1)
	{
		double d;
		if (luaval_to_number(tolua_S, 2, &d)){
			tolua_pushboolean(tolua_S, cobj->seek(d));
			return 1;
		}
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_seek'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_pause(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_pause'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushboolean(tolua_S, cobj->pause());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_pause'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_isOpen(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_isOpen'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushboolean(tolua_S, cobj->isOpen());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_isOpen'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_isEnd(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_isEnd'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushboolean(tolua_S, cobj->isEnd());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_isEnd'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_isError(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_isError'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushboolean(tolua_S, cobj->isError());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_isError'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_isPause(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_isPause'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushboolean(tolua_S, cobj->isPause());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_isPause'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_isPlaying(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_isPlaying'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushboolean(tolua_S, cobj->isPlaying());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_isPlaying'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_isSeeking(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_isSeeking'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushboolean(tolua_S, cobj->isSeeking());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_isSeeking'.", &tolua_err);
#endif

	return 0;
}


int lua_cocos2dx_ui_MovieView_getErrMsg(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_getErrMsg'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushstring(tolua_S, cobj->getErrMsg());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_getErrMsg'.", &tolua_err);
#endif

	return 0;
}

int lua_cocos2dx_ui_MovieView_play(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::ui::MovieView* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertype(tolua_S, 1, "ccui.MovieView", 0, &tolua_err)) goto tolua_lerror;
#endif

	cobj = (cocos2d::ui::MovieView*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
	if (!cobj)
	{
		tolua_error(tolua_S, "invalid 'cobj' in function 'lua_cocos2dx_ui_MovieView_play'", nullptr);
		return 0;
	}
#endif

	argc = lua_gettop(tolua_S) - 1;
	if (argc == 0)
	{
		tolua_pushboolean(tolua_S, cobj->play());
		return 1;
	}
	CCLOG("%s has wrong number of arguments: %d, was expecting %d \n", "open", argc, 0);
	return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'lua_cocos2dx_ui_MovieView_play'.", &tolua_err);
#endif

	return 0;
}

int lua_register_cocos2dx_ui_MovieView(lua_State* tolua_S)
{
	tolua_usertype(tolua_S, "ccui.MovieView");
	tolua_cclass(tolua_S, "MovieView", "ccui.MovieView", "ccui.Widget", nullptr);

	tolua_beginmodule(tolua_S, "MovieView");
	tolua_function(tolua_S, "new", lua_cocos2dx_ui_MovieView_constructor);
	tolua_function(tolua_S, "create", lua_cocos2dx_ui_MovieView_create);
	tolua_function(tolua_S, "createInstance", lua_cocos2dx_ui_MovieView_createInstance);
	tolua_function(tolua_S, "getMovieSize", lua_cocos2dx_ui_MovieView_getMovieSize);
	tolua_function(tolua_S, "open", lua_cocos2dx_ui_MovieView_open);
	tolua_function(tolua_S, "close", lua_cocos2dx_ui_MovieView_close);
	tolua_function(tolua_S, "length", lua_cocos2dx_ui_MovieView_length);
	tolua_function(tolua_S, "cur", lua_cocos2dx_ui_MovieView_cur);
	tolua_function(tolua_S, "seek", lua_cocos2dx_ui_MovieView_seek);
	tolua_function(tolua_S, "play", lua_cocos2dx_ui_MovieView_play);
	tolua_function(tolua_S, "pause", lua_cocos2dx_ui_MovieView_pause);
	tolua_function(tolua_S, "isOpen", lua_cocos2dx_ui_MovieView_isOpen);
	tolua_function(tolua_S, "isEnd", lua_cocos2dx_ui_MovieView_isEnd);
	tolua_function(tolua_S, "isError", lua_cocos2dx_ui_MovieView_isError);
	tolua_function(tolua_S, "isPause", lua_cocos2dx_ui_MovieView_isPause);
	tolua_function(tolua_S, "isPlaying", lua_cocos2dx_ui_MovieView_isPlaying);
	tolua_function(tolua_S, "isSeeking", lua_cocos2dx_ui_MovieView_isSeeking);
	tolua_function(tolua_S, "getErrMsg", lua_cocos2dx_ui_MovieView_getErrMsg);
	tolua_endmodule(tolua_S);
	std::string typeName = typeid(cocos2d::ui::MovieView).name();
	g_luaType[typeName] = "ccui.MovieView";
	g_typeCast["MovieView"] = "ccui.MovieView";
	return 1;
}

int lua_register_CamPreview(lua_State* tolua_S)
{
	const luaL_reg global_functions[] = {
		{ NULL, NULL }
	};
	luaL_register(tolua_S, "_G", global_functions);

	tolua_open(tolua_S);

	tolua_module(tolua_S, "ccui", 0);
	tolua_beginmodule(tolua_S, "ccui");

	lua_register_cocos2dx_ui_CamPreview(tolua_S);
	lua_register_cocos2dx_ui_MovieView(tolua_S);
	tolua_endmodule(tolua_S);
	return 1;
}