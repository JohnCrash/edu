local lfs = require "lfs"
local curl = require "curl"
local socket = require "socket"
local http = require "socket.http"
local json = require "json-c"

local local_dir = cc.FileUtils:getInstance():getWritablePath()
local cache_dir
local platform = CCApplication:getInstance():getTargetPlatform()
if platform == kTargetWindows then
	cache_dir = local_dir.."cache/"
else
	cache_dir = local_dir.."test/"
end
local host = {{"192.168.2.211",81,"/lgh/"},{"192.168.0.182",80,"/"}}
local use_idx = 1
local cobj = curl.new()

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
    print(reqs)
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
		print( '-----------download_http_by_curl---------------' )
		print( 'can\'t connect to '..url )
		print( 'Error message : '..err_msg )
		print( 'Error code : '..err_code )
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
		print( '-----------http_post---------------' )
		print( 'can\'t connect to '..url )
		print( 'Error message : '..err_msg )
		print( 'Error code : '..err_code )
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
		print( '-----------http_get---------------' )
		print( 'can\'t connect to '..url )
		print( 'Error message : '..err_msg )
		print( 'Error code : '..err_code )
		return nil
	end
end

local function local_exists( file )
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil  
end

local function read_local_file( name )
  local file = local_dir..name
  if not local_exists(file) then return false end
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

local function read_network_file( name )
  local url = 'http://'..host[use_idx][1]..':'..host[use_idx][2]..host[use_idx][3]..name
  return download_http_by_curl(url)
end

local function write_local_file( name,buf )
  local filename = local_dir..name
  local file = io.open(filename,'wb')
  if file then
    file:write(buf)
    file:close()
  else
     --local file error?
     cclog('Can not write file '..filename)
  end
end

local function local_directory_exists( dir )
	local s,err = lfs.attributes( dir )
	if s and s.mode == 'directory' then
		return true
	end
	return false
end

local function make_local_directory( name )
	local dir = local_dir..name
	if not local_directory_exists(dir) then
		lfs.mkdir(dir)
	end
end

local function del_local_directory( name )
	--no imp?
end

local function del_local_file( name )
	local filename = local_dir..name
  if os.remove then
    os.remove(filename)
  else
    print('not found os.remove function')
  end
end

--try 10 times
local function download_file(file)
  local fbuf = nil
  
  for i = 1,10 do
		fbuf = read_network_file(file)
		if fbuf then break end
		print('download file \''..file..'\' error,try agin!')
		print('------------------------------------------------')
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
	return local_exists( filename )
end

local function read_cache( name )
  local file = cache_dir..name
  if not local_exists(file) then return false end
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
	 print( 'buf="'..tostring(buf)..'"'..",type="..type(buf) )
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
			print('JSON.DECODE ERROR: '..re)
		end
	else
		print('decode_json argument #1 is nil')
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
				print( 'ERROR '..tostring(select(i,...))..' not exist!' )
				return false
			end
		end
	else
		print('ERROR assert invalid paramter t=nil or not table')
		return false
	end
	return true
end

local function encodeURI(s)
	s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
	return string.gsub(s, " ", "+")
end

local function my_log( a )
	print( tostring(a) )
end

local exports = {
	download_file = download_file,
	del_local_file = del_local_file,
	del_local_directory = del_local_directory,
	make_local_directory = make_local_directory,
	local_directory_exists = local_directory_exists,
	download_http_by_socket = download_http_by_socket,
	download_http_by_http = download_http_by_http,
	download_http_by_curl = download_http_by_curl,
	local_exists = local_exists,
	read_local_file = read_local_file,
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
}

return exports