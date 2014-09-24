local json = require "json-c"
require "ljshellDeprecated"
local ljshell = require "ljshell"

local local_dir = ljshell.getDirectory(ljshell.AppDir)

local function exists_file( file )
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil  
end

local function read_file(name)
  local file = local_dir..name
  if not exists_file(file) then return false end
  local alls
  
  file = io.open(file,"rb")
  alls = file:read("*a")
  file:close()
  return alls	
end

local function write_file( name,buf )
  local filename = local_dir..name
  local file = io.open(filename,'wb')
  if file then
    file:write(buf)
    file:close()
	return true
  else
     --local file error?
     print('Can not write file '..filename)
	 return false
  end
end

local function get_resume_table()
	local result = read_file("resume.json")
	if result then
		return json.decode(result)	
	end
end

local function save_resume_table(t)
	local result = json.encode(t)
	write_file("resume.json",result)
end

local function isok()
	local t = get_resume_table()
	if t then
		if t.launcher==4 then
			return false
		elseif t.update==4 then
			return false
		end
	end
	return true	
end

local function get_local_json( name )
	local result = read_file( name )
	if result then
		return json.decode(result)
	end
end

local function del_file( name )
end

local function del_file( name )
	local filename = local_dir..name
  if os.remove then
    return os.remove(filename)
  else
    my_log('not found os.remove function')
  end
end

local function del_files( t,s )
	if t then
		for i,v in pairs(t) do
			if v and v.name then
				print( 'delete file '..v.name)
				del_file( s..v.name )
			end
		end
	end
end

local function resume()
--清理luacore目录
	print("===========")
	print("resume")
	print( local_dir )
	print("===========")
	local src_filelist = get_local_json('src/luacore/filelist.json')
	del_files( src_filelist,"src/luacore/" )
	local res_filelist = get_local_json('res/luacore/filelist.json')
	del_files( res_filelist,"res/luacore/" )
	del_file('src/luacore/version.json') 
	del_file('res/luacore/version.json') 	
	del_file('src/luacore/filelist.json') 
	del_file('res/luacore/filelist.json') 
end

local function setflag()
	local t = {}
	t['launcher'] = 4
	t['update'] = 4
	save_resume_table(t)
end

local function clearflag(key)
	local t = get_resume_table("resume.json")
	if t then
		t[key] = 0
	end
	save_resume_table( t )
end

if not g_isrun_resume then
	g_isrun_resume = true
	if not isok() then --如果系统奔溃
		resume() --恢复到初始状态
	end
	setflag()
end
return 
{
	clearflag = clearflag,
}