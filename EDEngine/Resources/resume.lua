local json = require "json-c"
require "ljshellDeprecated"
local ljshell = require "ljshell"

local local_dir = ljshell.getDirectory(ljshell.AppDir)

local version = 9

local function exist_file( file )
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil  
end

local function read_file(name)
  local file = local_dir..name
  if not exist_file(file) then return false end
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
     print('ERROR Can not write file '..filename)
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
	if t then
		write_file("resume.json",result)
	else
		print("ERROR save_resume_table t = nil")
	end
end

local function isok()
	local t = get_resume_table()
	if t then
		if t.launcher==4 then
			return false
		elseif t.update==4 then
			return false
		end
		if t.version ~= version then
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
    print(' ERROR not found os.remove function')
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
	t.version = version
	save_resume_table(t)
end

local function clearflag(key)
	local t = get_resume_table("resume.json")
	if t then
		t[key] = 0
	end
	save_resume_table( t )
end

local function setvision( num )
	local t = get_resume_table("resume.json")
	t = t or {}
	t.version = tostring(num)
	save_resume_table( t )
end

local crash = read_file("crash.dump")
if crash then
	local crash_log = read_file("crash.log")
	crash = crash.."\n==============LOG============\n"..tostring(crash_log)
	local cr = require "crash"
	if cr and cr.report_bug then
		local result = cr.report_bug{errmsg="*ACRA*",log=crash}
		if result then
			local filename = local_dir.."crash.dump"
			if not os.remove(filename) then
				local filename2 = filename.."_"
				os.remove(filename2)
				os.rename(filename,filename2)
			end
		end
	end
end

if not g_isrun_resume then
	g_isrun_resume = true
	if not isok() then --如果系统奔溃
		resume() --恢复到初始状态
	end
	setflag()
end

local function getversion()
	return version
end

return 
{
	clearflag = clearflag,
	getversion = getversion,
}