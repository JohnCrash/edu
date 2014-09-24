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

local host = {{"192.168.2.211",81,"/lgh/"},{"192.168.0.182",80,"/"}}
local use_idx = 1
local cobj = curl.new()

local MAX_LOG = 512
local LOW_LOG = 256
local logs = {}

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
end

cclog = function(...)
    print(string.format(...))
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

--±àÂëurl²ÎÊý±í
--ÀýÈçapp_id=2001&game_id=agcn3nanf&stage_id=2&
local function encode_url( p )
	local s = ''
	for k,v in pairs(p) do
		s = s..k..'='..v..'&'
	end
	return s
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

local function exists_file( file )
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil  
end

local function local_exists( file )
	return local_exists( local_dir..file )
end

local function read_file(name)
  local file = name
  if not exists_file(file) then return false end
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

local function write_file( name,buf )
  local filename = name
  local file = io.open(filename,'wb')
  if file then
    file:write(buf)
    file:close()
	return true
  else
     --local file error?
     my_log('Can not write file '..filename)
	 return false
  end
end

local function write_local_file( name,buf )
  local filename = local_dir..name
  return write_file( filename,buf )
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
	return os.rename(old,new)
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
	local filename = cache_dir..name
	return exists_file( filename )
end

local function read_cache( name )
  local file = cache_dir..name
  if not exists_file(file) then return false end
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
			result = result..day..'å¤©'
		end
		if hours > 0 or day > 0 then
			result = result..hours..'å°æ—¶'
		end
		if mins > 0 or hours > 0 or day > 0 then
			result = result..mins..'åˆ†'
		end
		if not expet_sec then
			result = result..sec..'ç§’'
		end
		return result
	end
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
	read_cache = read_cache,
	write_cache = write_cache,
	hot_cache = hot_cache,
	exist_cache = exist_cache,
	decode_json = decode_json,
	unix_date_by_string = unix_date_by_string,
	time_to_string = time_to_string,
	log = my_log,
	check = check_table,
	write_file = write_file,
	make_directory = make_directory,
	del_file = del_file,
	del_directory = del_directory,
	get_logs = get_logs,
	config = config,
	quit = quit,
	rename_file = rename_file,
	exists_file = exists_file,
	get_local_directory = get_local_directory,
	get_cache_path = get_cache_path,
}

return exports
