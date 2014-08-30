#include "lua_ext.h"
#include "tolua++.h"
#include "json-c/json.h"

#if __cplusplus
extern "C" {
#endif
#if LUA_VERSION_NUM < 502
#  define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

//判断是否是一个纯数组?
bool isArray( lua_State *L,int t )
{
	bool isArray = true;
	lua_pushnil(L);
	while( lua_next(L,t) != 0 )
	{
		if( lua_isnumber(L,-2) )
		{
			lua_Number d = lua_tonumber(L,-2);
			if( d != (int)d ) //要求全部的索引都必须是整数
			{
				isArray = false;
			}
		}
		else
		{
			isArray = false;
		}
		lua_pop(L,1);
//		if( !isArray )
//		{
			//lua_pop(L,1); //pop key
//			break;
//		}
	}	
	return isArray;
}

json_object *lua_travering( lua_State *L,int t )
{
	if( lua_isnumber(L,t) )
	{
		return json_object_new_double(lua_tonumber(L,-1));
	}
	else if( lua_isstring(L,t) )
	{
		return json_object_new_string(lua_tostring(L,-1));
	}
	else if( lua_isboolean(L,t) )
	{
		return json_object_new_boolean(lua_toboolean(L,-1));
	}
	else if( lua_istable(L,t) )
	{
		if( isArray(L,t) )
		{
			json_object *jarray = json_object_new_array();
			lua_pushnil(L);
			while( lua_next(L,t) != 0 )
			{
				//key -2,value -1
				json_object *val = lua_travering( L,lua_gettop(L));
				if( val )
				{
					json_object_array_add(jarray,val);
				}
				lua_pop(L,1); //pop value
			}
			return jarray;
		}
		else
		{
			json_object *jobject = json_object_new_object();
			lua_pushnil(L);
			while( lua_next(L,t) != 0 )
			{
				//key -2,value -1
				if( lua_isstring(L,-2) )
				{
					json_object *val = lua_travering( L,lua_gettop(L) );
					if( val )
					{
						json_object_object_add( jobject,lua_tostring(L,-2),val );
					}
				}
				lua_pop(L,1); //pop value
			}
			return jobject;
		}
	}
	else
	{ //Ignore
	}

	return nullptr;
}

/*
	json.encode( t,format )
*/
int lua_jsonEncode(lua_State *L)
{
	json_object * jobj = lua_travering(L,1);
	if( jobj )
	{
		int flag = JSON_C_TO_STRING_PLAIN;
		if( lua_isnumber(L,2) )
		{
			lua_Number d = lua_tonumber(L,2);
			if( d == (int)d )
			{
				flag = (int)d;
			}
		}
		const char * presult = json_object_to_json_string_ext(jobj,flag);
		if( presult )
		{
			lua_pushstring(L,presult);
			json_object_put( jobj );
			return 1;
		}
		json_object_put( jobj );
	}
	else
	{
		lua_pushnil(L);
		lua_pushstring(L,"invalid argument");
		return 2;
	}
	lua_pushnil(L);
	lua_pushstring(L,"json encode failed");
	return 2;	
}

//成功将解码的数据压入堆栈返回true，失败不压入任何东西返回false
bool decode_json( lua_State *L,json_object *jobject )
{
	if( json_object_is_type(jobject,json_type_string) )
	{
		lua_pushstring(L,json_object_get_string(jobject));
		return true;
	}
	else if( json_object_is_type(jobject,json_type_double)||
		json_object_is_type(jobject,json_type_int) )
	{
		if( json_object_is_type(jobject,json_type_int) )
		{
			lua_pushnumber(L,json_object_get_int(jobject));
		}
		else
		{
			lua_pushnumber(L,json_object_get_double(jobject));
		}
		
		return true;
	}
	else if( json_object_is_type(jobject,json_type_boolean) )
	{
		lua_pushboolean(L,json_object_get_boolean(jobject));
		return true;
	}
	else if( json_object_is_type(jobject,json_type_null) )
	{
		lua_pushnil(L);
		return true;
	}
	else if( json_object_is_type(jobject,json_type_object) )
	{
		lua_newtable(L);
		json_object_object_foreach(jobject, key, val)
		{
			lua_pushstring(L,key); //push key
			if( decode_json(L,val) ) //push value
			{
				lua_settable(L,-3);
			}
			else
				lua_pop(L,1);
		}
		return true;
	}
	else if( json_object_is_type(jobject,json_type_array) )
	{
		int idx = 1;
		lua_newtable(L);
		for(int i=0;i<json_object_array_length(jobject);++i)
		{
			lua_pushinteger(L,idx);
			json_object *val = json_object_array_get_idx(jobject,i);
			if( val && decode_json(L,val) )
			{
				lua_settable(L,-3);
				idx++;
			}
			else
				lua_pop(L,1);
		}
		return true;
	}
	return false;
}
/*
	json.decode( s )
	return table,or nil,err_msg
*/
int lua_jsonDecode(lua_State *L)
{
	if(lua_isstring(L,1))
	{
		const char *pstr = lua_tostring(L,1);
		json_tokener_error err;
		if( pstr )
		{
			json_object *jobject = json_tokener_parse_verbose(pstr,&err);
			if( jobject )
			{
				if( decode_json( L,jobject ) )
				{
					json_object_put(jobject);
					return 1;
				}
				else
				{
					json_object_put(jobject);
					lua_pushnil(L);
					lua_pushstring(L,"json decode failed");
					return 2;
				}
			}
			else
			{
				lua_pushnil(L);
				lua_pushstring(L,json_tokener_error_desc(err));
				return 2;
			}
		}
	}
	lua_pushnil(L);
	lua_pushstring(L,"invalid argument");
	return 2;
}

static const struct luaL_Reg lua_json_methods[] = 
{
	{"encode",lua_jsonEncode},
	{"decode",lua_jsonDecode},
	{NULL,NULL}
};

#define VERSION "1.0"

static void set_info(lua_State *L) 
{
	lua_pushliteral (L, "_COPYRIGHT");
	lua_pushliteral (L, "Copyright (C) 2014");
	lua_settable (L, -3);
	lua_pushliteral (L, "_DESCRIPTION");
	lua_pushliteral (L, "json is lua library.");
	lua_settable (L, -3);
	lua_pushliteral (L, "_VERSION");
	lua_pushliteral (L, "json " VERSION);
	lua_settable (L, -3);
}

int luaopen_json( lua_State *L )
{
	luaL_newlib(L,lua_json_methods);
	set_info( L );
	return 1;
}

static luaL_Reg luax_exts[] = {
    {"json", luaopen_json},
    {NULL, NULL}
};

#if __cplusplus
}
#endif