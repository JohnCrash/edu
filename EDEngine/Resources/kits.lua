local lfs = require "lfs"
local curl = require "curl"
local socket = require "socket"
local http = require "socket.http"
local json = require "json-c"
require "ljshellDeprecated"
local ljshell = require "ljshell"

local local_dir = ljshell.getDirectory(ljshell.AppDir)
local platform = CCApplication:getInstance():getTargetPlatform()
local cache_dir = local_dir.."cache/"
local tmp_dir = ljshell.getDirectory(ljshell.AppTmpDir)
local host = {{"192.168.2.211",81,"/lgh/"},{"192.168.0.182",80,"/"}}
local use_idx = 1
local cobj = curl.new()

local MAX_LOG = 512
local LOW_LOG = 256
local logs = {}

local function get_version()
	return 5
end

local function get_logs()
	return logs
end
local function my_log( a )
	local msg = tostring(a)
	if table.maxn(logs) > MAX_LOG then
		for i=1,LOW_LOG do
			table.remove(logs,i)
		end
	end
	table.insert(logs,msg)
	print( msg )
	if cc_acr_log then
		cc_acr_log(msg)
	end
end

cclog = function(...)
    print(string.format(...))
end

local function log_caller()
	local caller = debug.getinfo(3,'nSl')
	local func = debug.getinfo(2,'n')
	if caller and func then
		my_log('	call from '..caller.source..':'..caller.currentline )
		my_log('		function:'..func.name )
	else
		my_log("ERROR: log_caller debug.getinfo return nil.")
	end
end

local function download_http_by_socket(host,file,port)
  port = port or 80
  local connect = socket.connect(host,port)
  local buf,err_msg

  if connect then
    connect:settimeout(0.1)
    local reqs = "GET "..file.." HTTP/1.0\r\n\r\n"
    my_log(reqs)
    local result = connect:send(reqs)
    repeat
      local chunk,status,partial = connect:receive(1024)
      if not buf then
        buf = chunk
      elseif buf and chunk then
        buf = buf..chunk
      end
    until status == 'closed'
    connect:close()
  else
    err_msg = 'can not connect '..host
  end
  return buf,err_msg
end

local function download_http_by_http(url)
  return http.require(url)
end

local function encode_space( url )
	return string.gsub( url,' ','%%20')
end

local function download_http_by_curl(url,tout)
	--local cobj = curl.new()
   cobj:setopt(curl.OPT_URL, encode_space(url) )
   local time_out = tout or 60
	
	cobj:setopt(curl.OPT_TIMEOUT,time_out)
	cobj:setopt(curl.OPT_CONNECTTIMEOUT,2)
   local t = {} -- this will collect resulting chunks
   cobj:setopt(curl.OPT_WRITEFUNCTION, function (param, buf)
        table.insert(t, buf) -- store a chunk of data received
        return #buf
    end)
   cobj:setopt(curl.OPT_PROGRESSFUNCTION, function(param, dltotal, dlnow)
       -- print('%', url, dltotal, dlnow) -- do your fancy reporting here
   end)
   cobj:setopt(curl.OPT_NOPROGRESS, false) -- use this to activate progress
   local result,err_msg,err_code = cobj:perform()
   if result then
		return table.concat(t) -- return the whole data as a string  
	else
		my_log( '-----------download_http_by_curl---------------' )
		my_log( 'can\'t connect to '..url )
		my_log( 'Error message : '..err_msg )
		my_log( 'Error code : '..err_code )
		return nil
	end 
end

local function encode_str( s )
	local length = string.len(s)
	if length == 0 then
		return ''
	end		
	local t = {}
	for i=1,length do
		local ch = string.byte(s,i)
		local hex = string.format('%X',ch)
		local l = string.len(hex)
		if l<2 then
			if l == 1 then
				hex = '0'..hex
			else
				hex = '00'..hex
			end
		elseif l>2 then
			hex = string.sub(hex,-2)
		end
		table.insert(t,hex)
	end
	return '%'..table.concat(t,'%')
end
local function encode_url( p )
	if p and type(p)=='table' then
		local s
		for k,v in pairs(p) do
			if s then
				s = s..'&'..tostring(k)..'='..tostring(v)
			else
				s = tostring(k)..'='..tostring(v)
			end
		end
		return s
	elseif p and type(p)=='string' then
		return encode_str( p )
	end
end

local function http_post(url,text,cookie,to)
	local time_out = time_out or 2 --2'
	local t = {}
	--local cobj = curl.new()
	cobj:setopt(curl.OPT_TIMEOUT,60)
	cobj:setopt(curl.OPT_CONNECTTIMEOUT,time_out)
	
	cobj:setopt(curl.OPT_URL,encode_space(url))
	cobj:setopt(curl.OPT_CUSTOMREQUEST,'POST')

	if cookie then
		cobj:setopt(curl.OPT_COOKIE,cookie)
	end
	if text then
		cobj:setopt(curl.OPT_POSTFIELDS,text)
		cobj:setopt(curl.OPT_POSTFIELDSIZE,string.len(text))
--		cobj:setopt(curl.OPT_HTTPHEADER,"Content-Type: text/plain\nContent-Length: "..string.len(text))
	end
	cobj:setopt(curl.OPT_WRITEFUNCTION, function (param, buf)
        table.insert(t, buf) -- store a chunk of data received
        return #buf 
		end)
		
	local result,err_msg,err_code = cobj:perform()
   if result then
		return table.concat(t) -- return the whole data as a string  
	else
		my_log( '-----------http_post---------------' )
		my_log( 'can\'t connect to '..url )
		my_log( 'Error message : '..err_msg )
		my_log( 'Error code : '..err_code )
		return nil
	end
end

local function http_get(url,cookie,to)
	--local cobj = curl.new()
   cobj:setopt(curl.OPT_URL, encode_space(url))
   local time_out = to or 2
   
   if cookie then
		cobj:setopt(curl.OPT_COOKIE,cookie)
   end
   
	cobj:setopt(curl.OPT_TIMEOUT,60)
	cobj:setopt(curl.OPT_CONNECTTIMEOUT,time_out)

   local t = {} -- this will collect resulting chunks
   cobj:setopt(curl.OPT_WRITEFUNCTION, function (param, buf)
        table.insert(t, buf) -- store a chunk of data received
        return #buf
    end)
   cobj:setopt(curl.OPT_PROGRESSFUNCTION, function(param, dltotal, dlnow)
       -- print('%', url, dltotal, dlnow) -- do your fancy reporting here
   end)
   cobj:setopt(curl.OPT_NOPROGRESS, false) -- use this to activate progress
   
   local result,err_msg,err_code = cobj:perform()
   if result then
		return table.concat(t) -- return the whole data as a string  
	else
		my_log( '-----------http_get---------------' )
		my_log( 'can\'t connect to '..url )
		my_log( 'Error message : '..err_msg )
		my_log( 'Error code : '..err_code )
		return nil
	end
end

local function exist_file( file )
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil  
end

local function directory_exists( dir )
	local s,err = lfs.attributes( dir )
	if s and s.mode == 'directory' then
		return true
	end
	return false
end

local function make_directory( name )
	local dir = name
	if not directory_exists(dir) then
		lfs.mkdir(dir)
	end
end

local function local_exists( file )
	return exist_file( local_dir..file )
end

local function read_file(name)
  local file = name
  if not exist_file(file) then return false end
  local alls
  
  file = io.open(file,"rb")
  alls = file:read("*a")
  file:close()
  return alls	
end

local function read_local_file( name )
  local file = local_dir..name
  return read_file(file)
end

local function read_network_file( name )
  local url = 'http://'..host[use_idx][1]..':'..host[use_idx][2]..host[use_idx][3]..name
  return download_http_by_curl(url)
end

local function make_file_directory( filename )
	local i = 1
	local dirs = {}
	if not filename then
		return
	end
	while i do
		local s = i
		i = string.find(filename,'[/\\]',i)
		local e = i
		if i then
			table.insert(dirs,string.sub(filename,s,e-1))
			i = i + 1
		end
	end
	local dir = ""
	for k,v in pairs(dirs) do
		dir = dir..v
		make_directory( dir )
		dir = dir..'/'
	end
end

local function log_file_directory( filename )
	local i = 1
	local dirs = {}
	if not filename then
		return
	end
	while i do
		local s = i
		i = string.find(filename,'[/\\]',i)
		local e = i
		if i then
			table.insert(dirs,string.sub(filename,s,e-1))
			i = i + 1
		end
	end
	
	local dir = ""
	for k,v in pairs(dirs) do
		dir = dir..v
		if not directory_exists( dir ) then
			my_log("error directory "..tostring(dir).." not exist~")
		end
		dir = dir..'/'
	end
end

local function write_file( name,buf )
  local filename = name
  local file,msg = io.open(filename,'wb')
  if file then
    file:write(buf)
    file:close()
	return true
  else
	--open failed ,make directory 
	make_file_directory(filename)
	if directory_exists(filename) then
		lfs.rmdir(filename)
	end
	 local file,msg = io.open(filename,'wb')
	 if file then
		file:write(buf)
		file:close()
		return true	 
	 else
		 my_log('Can not write file '..tostring(filename)..' '..tostring(msg))
		 log_file_directory(filename)
		 my_log("filename is directory:"..tostring(directory_exists(filename)))
		 local file,msg = io.open(filename,'r')
		 if file then
			my_log("filename can open by mode r")
			file:close()
		 else
			my_log("filename can not open by mode r error:"..tostring(msg))	 
		 end
		 return false
	 end
  end
end

local function copy_file( f1,f2 )
	if f1 == f2 then return end
	local buf = read_file( f1 )
	if buf then
		return write_file( f2,buf )
	end
end

local function write_local_file( name,buf )
  local filename = local_dir..name
  return write_file( filename,buf )
end

local function make_local_directory( name )
	make_directory( local_dir..name )
end

local function del_directory( name )
	--no imp?
end

local function del_local_directory( name )
	del_directory( local_dir..name )
end

local function del_file( name )
	local filename = name
  if os.remove then
    return os.remove(filename)
  else
    my_log('not found os.remove function')
  end
end

local function rename_file( old,new )
	local b,msg = os.rename(old,new)
	if not b then
		local new_isexist = exist_file(new)
		local old_isexist = exist_file(old)
		my_log("rename_file failed:")
		my_log("old="..tostring(old).." isexist:"..tostring(old_isexist))
		my_log("new="..tostring(new).." isexist:"..tostring(new_isexist))
		my_log(" error_msg:"..tostring(msg))
		my_log(" try rename new file")
		local e,m = os.rename(new,new.."_")
		if not e then
			my_log(" rename failed "..tostring(m))
		else
			my_log(" rename success")
		end
		my_log("try rename old file")
		e,m = os.rename(old,new)
		if not e then
			my_log(" rename failed "..tostring(m))
		else
			my_log(" rename success ")
			b = e
		end
		--HOTFIX
		if not e then
			if (string.find(old,"/res/") or string.find(old,"/src/")) and
				(string.find(new,"/res/") or string.find(new,"/src/")) then
				local b1 = string.find(new,"/res/")
				local b2 = string.find(new,"/src/")
				local filename
				if b1 then
					filename = string.sub(new,b1)
				else
					filename = string.sub(new,b2)
				end
				my_log("download from original server:")
				local liexue_server_sr = 'http://file.lejiaolexue.com/upgrade/luaapp/v7'
				local url = liexue_server_sr..filename
				my_log(" try :"..tostring(url))
				for i=1,3 do
					local data_s = http_get(url,'',300)
					if data_s then
						e = write_file(new,data_s)
						my_log("	done ")
						break
					else
						my_log("	failed "..tostring(i))
					end
				end
			end
		end
		b = e
		require "crash".report("*RENAME FAILED INFO*"..tostring(math.floor(os.time())))
	end
	return b,msg
end

local function del_local_file( name )
	local filename = local_dir..name
	del_file(filename)
end

--try 10 times
local function download_file(file)
  local fbuf = nil
  
  for i = 1,10 do
		fbuf = read_network_file(file)
		if fbuf then break end
		my_log('download file \''..file..'\' error,try agin!')
		my_log('------------------------------------------------')
	end
	
  if fbuf then
	write_local_file(file,fbuf)
  elseif file then
	cclog('Can not download file '..file)
  else
    cclog('download_file param invalid!(nil)')
  end
end

local function hot_cache( name,sec )
	local filename = cache_dir..name
	local s = lfs.attributes( filename )
	if s and s.change then
		local dt = os.time() - s.change
		if dt < sec*1000 then
			return true
		end
	end
	return false
end

local function exist_cache( name )
	if not name then
		return false
	end
	local filename = cache_dir..name
	return exist_file( filename )
end

local function read_cache( name )
  local file = cache_dir..name
  if not exist_file(file) then return false end
  local alls
  
  file = io.open(file,"rb")
  alls = file:read("*a")
  file:close()
  --[[
  for line in io.lines(file) do
    if not alls then
      alls = line
    else
      alls = alls..line
    end
  end
  --]]
  return alls
end

local function write_cache( name,buf )
  local filename = cache_dir..name
  local file = io.open(filename,'wb')
  if file and buf and type(buf)=='string' then
    file:write(buf)
    file:close()
	return true
  else
     --local file error?
	 my_log( 'buf="'..tostring(buf)..'"'..",type="..type(buf) )
     cclog('Can not write cache '..filename)
	 return false
  end
end

local function copy_cache( f1,f2 )
	if f1 == f2 then return end
	local buf = read_cache( f1 )
	if buf then
		return write_cache( f2,buf )
	end	
end

local function decode_json( buf )
	if buf then
		local b,re = pcall( json.decode,buf )
		if b then
			return re
		else
			my_log('JSON.DECODE ERROR: '..re)
		end
	else
		my_log('decode_json argument #1 is nil')
	end
	return nil
end

--'/Date(1405425300000+0800)/'
local function unix_date_by_string( str )
	local t = string.match( str,"(%d+)%+0800" )
	if t then
		local d = tonumber( t )
		if d then
			return d/1000
		end
	end
end

local function time_to_string( d,expet_sec )
	if d then
		local day = math.floor( d /(3600*24) )
		local hours = math.floor( (d - day*3600*24)/3600 )
		local mins = math.floor( (d - day*3600*24 - hours*3600)/60 )
		local sec = math.floor( d - day*3600*24 - hours*3600-mins*60 )
		local result = ''
		if day > 0 then
			result = result..day..'天'
		end
		if hours > 0 or day > 0 then
			result = result..hours..'小时'
		end
		if mins > 0 or hours > 0 or day > 0 then
			result = result..mins..'分'
		end
		if not expet_sec then
			result = result..sec..'秒'
		end
		return result
	end
end

local function time_abs_string( d )
	local t = os.date('*t',d)
	return t.year..'.'..t.month..'.'..t.day..'  '..t.hour..':'..t.min
end

local function time_to_string_simple( d,expet_sec )
	if d then
		local day = math.floor( d /(3600*24) )
		local hours = math.floor( (d - day*3600*24)/3600 )
		local mins = math.floor( (d - day*3600*24 - hours*3600)/60 )
		local sec = math.floor( d - day*3600*24 - hours*3600-mins*60 )
		if day > 0 then
			return day..'天'
		elseif hours > 0 then
			return hours..'小时'
		elseif mins > 0 then
			return mins..'分'
		elseif sec >= 0 then
			return sec..'秒'
		end
	end
	return '-'
end

local function check_table(t,...)
	if t and type(t)=='table' then
		for i = 1,select('#',...) do
			if not t[select(i,...)] then
				my_log( 'ERROR '..tostring(select(i,...))..' not exist!' )
				return false
			end
		end
	else
		my_log('ERROR assert invalid paramter t=nil or not table')
		return false
	end
	return true
end

local function encodeURI(s)
	s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
	return string.gsub(s, " ", "+")
end

local config_table

local function config(key,value)
	if not config_table then
		local result = read_local_file("config.json")
		if result then
			config_table = json.decode(result)
		end
	end
	config_table = config_table or {}
	local oldvalue = config_table[key]
	if value ~= "get" then
		config_table[key] = value
		local result = json.encode(config_table)
		if result then
			my_log("WARNING write config file")
			write_local_file("config.json",result)
		else
			my_log("ERROR config json.encode return nil")
		end
	end
	return oldvalue
end

local function quit()
	config_table = config_table or {}
	local result = json.encode(config_table)
	if result then
		write_local_file("config.json",result)
	end
	cc.Director:getInstance():endToLua()
end

local function get_local_directory()
	return local_dir
end

local function get_cache_path()
	return cache_dir
end

local function get_tmp_path()
	return tmp_dir
end

local function launch(app)
	local update = require "update"
	if update then
		update.create{name=app.."_shell",updates={"luacore"},
		run = function()
			local s = kits.read_local_file("res/luacore/app.json")
			if s then
				local apps = json.decode( s )
				if apps and apps[app] and apps[app].name and apps[app].updates and apps[app].launch then
					update.create{name=apps[app].name,updates=apps[app].updates,
						run=function()
							local a = require(apps[app].launch)
							return a.create()
						end}			
				else
					kits.log("ERROR : can not found applet : "..tostring(app))
				end
			else
				kits.log("ERROR : can not read res/luacore/app.json")
			end
		end
		}
	else
		log("ERROR launch failed,update = nil")
	end
end

local _ljshell_config
local function get_ljconfig()
	if _ljshell_config then
		return _ljshell_config
	end
	local file = ljshell.getDirectory(ljshell.LJDIR).."/share/ShareSettings.json"
	local rf = read_file(file)
	if rf then
		_ljshell_config = json.decode(rf)
	end
	return _ljshell_config
end

local function getApiServer()
	local server = 'api.lejiaolexue.com'
	local lj_config = get_ljconfig()
	if lj_config and lj_config.setting then
		if type(lj_config.setting)=='table' and lj_config.setting.ApiServer then
			server = lj_config.setting.ApiServer
		end
	end
	return server
end

local function getAppServer()
	local server = 'api.lejiaolexue.com'
	local lj_config = get_ljconfig()
	if lj_config and lj_config.setting then
		if type(lj_config.setting)=='table' and lj_config.setting.AppServer then
			server = lj_config.setting.AppServer
		end
	end
	return server
end

local function getUpdateServer()
	local server = 'api.lejiaolexue.com'
	local lj_config = get_ljconfig()
	if lj_config and lj_config.setting then
		if type(lj_config.setting)=='table' and lj_config.setting.FileServer then
			server = lj_config.setting.FileServer
		end
	end
	return server	
end

local function getImageUploadServer()
	local server = 'image.lejiaolexue.com'
	local lj_config = get_ljconfig()
	if lj_config and lj_config.setting then
		if type(lj_config.setting)=='table' and lj_config.setting.ImageServerUpload then
			server = lj_config.setting.ImageServerUpload
		end
	end
	return server
end

local function getImageDownloadServer()
	local api = 'image.lejiaolexue.com'
	local lj_config = get_ljconfig()
	if lj_config and lj_config.setting then
		if type(lj_config.setting)=='table' and lj_config.setting.ImageServer then
			api = lj_config.setting.ImageServer
		end
	end
	return api
end

local function isNeedUpade(appname,func)
	local uikits = require "uikits"
	if not uikits then return end
	
	local function _isNeedUpade(appname)
		if appname then
			if type(appname)=="string" then
				local s = read_local_file(tostring(appname).."_config.json")
				if not s then return end
				local t = decode_json(s)
				if t and type(t)=='table' then
					for i,v in pairs(t) do
						if v then
							return true
						end
					end
				end
			elseif type(appname)=="table" then
				for i,v in pairs(appname) do
					local s = read_local_file(tostring(v).."_config.json")
					if not s then return end
					local t = decode_json(s)
					if t and type(t)=='table' then
						for i,v in pairs(t) do
							if v then
								return true
							end
						end
					end				
				end
			else
				my_log("ERROR isNeedUpade failed,appname invalid type")
			end
		end
	end
	local count = 0
	uikits.delay_call(nil,function(dt)
		count = count+1
		if count<=10 then
			if _isNeedUpade(appname) then
				func( true,appname )
				return
			end
			return true
		end
		func( false,appname )
	end,1)
end

local function doUpdate(appname)
	local uikits = require "uikits"
	if not uikits then return end

	for i=1,uikits.getSceneCount() do
		uikits.popScene()
	end
	package.loaded["launcher"] = nil
	for i,v in pairs(package.loaded) do
		if i and type(i)=='string' then
			if type(appname)=="string" then
				local idx = string.find(i,appname)
				if idx==1 then
					package.loaded[i] = nil		
				end
			elseif type(appname)=="table" then
				for j,vv in pairs(appname) do
					local idx = string.find(i,vv)
					if idx==1 then
						package.loaded[i] = nil		
					end				
				end
			else
				my_log("ERROR doUpdate failed,appname invalid type")
			end
		end
	end
	require "launcher"
end

local function logTable(t, index)
	---[====[
	if index == nil then
		my_log("TABLE:")
	end

	local space = "   "
	local _space = " "
	if index ~= nil then
		for i = 1, index do
			_space = _space .. space
		end
		index = index + 1
	else
		index = 1
	end

	if t == nil then 
		my_log(_space .. "table is nil") 
		return
	end

	for k,v in pairs(t) do
		if type(v) ~= "table" then
			my_log(string.format("%s%s[%s]      %s[%s]", 
				_space, tostring(k), type(k), tostring(v), type(v)))
		else
			my_log(_space .. "T[".. tostring(k) .. "]------------------")
			logTable(v, index)
		end
	end

	--]====]
end

local exports = {
	download_file = download_file,
	del_local_file = del_local_file,
	del_local_directory = del_local_directory,
	make_local_directory = make_local_directory,
	directory_exists = directory_exists,
	download_http_by_socket = download_http_by_socket,
	download_http_by_http = download_http_by_http,
	download_http_by_curl = download_http_by_curl,
	local_exists = local_exists,
	read_local_file = read_local_file,
	read_file = read_file,
	read_network_file = read_network_file,
	write_local_file = write_local_file,
	http_post = http_post,
	http_get = http_get,
	encode_url = encode_url,
	encode_space = encode_space,
	encode_str = encode_str,
	read_cache = read_cache,
	write_cache = write_cache,
	hot_cache = hot_cache,
	exist_cache = exist_cache,
	copy_cache = copy_cache,
	decode_json = decode_json,
	unix_date_by_string = unix_date_by_string,
	time_to_string = time_to_string,
	time_to_string_simple = time_to_string_simple,
	time_abs_string = time_abs_string,
	log = my_log,
	check = check_table,
	write_file = write_file,
	copy_file = copy_file,
	make_directory = make_directory,
	del_file = del_file,
	del_directory = del_directory,
	get_logs = get_logs,
	config = config,
	quit = quit,
	rename_file = rename_file,
	exist_file = exist_file,
	get_local_directory = get_local_directory,
	get_cache_path = get_cache_path,
	get_tmp_path = get_tmp_path,
	get_version = get_version,
	launch = launch,
	get_ljconfig = get_ljconfig,
	getApiServer = getApiServer,
	getUpdateServer = getUpdateServer,
	getImageUploadServer = getImageUploadServer,
	getImageDownloadServer = getImageDownloadServer,
	getAppServer = getAppServer,
	log_caller = log_caller,
	isNeedUpade = isNeedUpade,
	doUpdate = doUpdate,
	logTable = logTable,
}

return exports
