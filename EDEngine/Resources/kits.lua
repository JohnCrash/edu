local lfs = require "lfs"
local curl = require "curl"
local socket = require "socket"
local http = require "socket.http"

local local_dir = cc.FileUtils:getInstance():getWritablePath()
local host = {{"192.168.2.211",81,"/lgh/"},{"192.168.0.182",80,"/"}}
local use_idx = 1
local curl_obj = curl.new()

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

local function download_http_by_curl(url,time_out)
   curl_obj:setopt(curl.OPT_URL, url)
   time_out = time_out or 2
	curl_obj:setopt(curl.OPT_TIMEOUT,time_out)
   local t = {} -- this will collect resulting chunks
   curl_obj:setopt(curl.OPT_WRITEFUNCTION, function (param, buf)
        table.insert(t, buf) -- store a chunk of data received
        return #buf
    end)
   curl_obj:setopt(curl.OPT_PROGRESSFUNCTION, function(param, dltotal, dlnow)
       -- print('%', url, dltotal, dlnow) -- do your fancy reporting here
   end)
   curl_obj:setopt(curl.OPT_NOPROGRESS, false) -- use this to activate progress
   if curl_obj:perform() then
		return table.concat(t) -- return the whole data as a string  
	else
		print( 'can\'t connect to '..url )
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
  for line in io.lines(file) do
    if not alls then
      alls = line
    else
      alls = alls..line
    end
  end
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

local function download_file(file)
  local fbuf = read_network_file(file)
  if fbuf then
	write_local_file(file,fbuf)
  elseif file then
	cclog('Can not download file '..file)
  else
    cclog('download_file param invalid!(nil)')
  end
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
	write_local_file = write_local_file
}

return exports