require "Cocos2d"
local lfs = require "lfs"
local lxp = require "lom"
local curl = require "curl"
local socket = require "socket"
local http = require "socket.http"

local host = {{"192.168.2.211",81,"/lgh/"},{"192.168.0.182",80,"/"}}
local use_idx = 1
local local_dir = cc.FileUtils:getInstance():getWritablePath()

local cclog = function(...)
    print(string.format(...))
end

--for debuger
--require("mobdebug").start("192.168.2.182")

local curl_obj = curl.new()

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

local function download_http_by_curl(url)
    curl_obj:setopt(curl.OPT_URL, url)
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
     cclog('Can not write file '..name)
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

local function isNeedSync()
  local version_xml = 'version.xml'
  local local_version = read_local_file(version_xml)
  if not local_version then
    return true
  else
    local host_version = read_network_file(version_xml)
    if host_version then
      local lvt = lxp.parse(local_version)
      local nvt = lxp.parse(host_version)
      if lvt and nvt and lvt.tag and nvt.tag and
        lvt.tag == nvt.tag and lvt.attr and nvt.attr and
        lvt.attr.number and nvt.attr.number and 
        lvt.attr.number == nvt.attr.number then
        return false
      end
    else
      --network error?
      return true
    end
  end
  return true
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

local function operate_by_table(filelist)
	for k,v in pairs(filelist) do
		if v.download then
			download_file(v.download)
		elseif v.mkdir then
			make_local_directory(v.mkdir)
		end
	end
end

local function operate_one_by_one(t)
	if t then
		if t.download then
			download_file(t.download)
		elseif t.mkdir then
			make_local_directory(t.mkdir)
		elseif t.remove then
			--delete file
			del_local_file(t.remove)
		elseif t.remove_dir then
			--delete directory
			del_local_directory(t.remove_dir)
		end
	end
end

local function table_apped(t,s)
	if t and s then
		for k,v in ipairs(s) do
			t[#t+1] = v
		end
	end
end

local function get_ups_string(ups,name)
	local lups
	if not ups or (type(ups)=='string' and string.len(ups)==0) then
		lups = name
	else
		lups = ups..'/'..name
	end
	return lups
end
			
local function filelist_by_table(tb,ups)
  local filelist = {}
  if tb and tb.tag then
    if tb.tag == 'filelist' or tb.tag == 'directory' then
      for k,v in pairs(tb) do
        if type(v) == 'table' and v.attr and v.tag and v.attr.name then
          if v.tag == 'directory' then
			--make_local_directory(lups) --try make local directory
			filelist[#filelist+1] = {mkdir=get_ups_string(ups,v.attr.name)}
            table_apped(filelist,filelist_by_table(v,get_ups_string(ups,v.attr.name)))
          elseif v.tag == 'file' then
			filelist[#filelist+1] = {download=get_ups_string(ups,v.attr.name),md5=v.attr.md5}
          end
        end
      end
    elseif tb.tag == 'file' then
      if tb.attr and tb.attr.name then
		filelist[#filelist+1] = {download=get_ups_string(ups,v.attr.name)}
      end
    end
  end	
  return filelist
end

local function is_need_download(t,file,md5)
	if t then
		for i,v in ipairs(t) do
			if v.download and v.download == file and v.md5 == md5 then
				return false
			end
		end
	end
	return true
end

local function g_fast_tt(t)
  local tt = {}
  for i,v in ipairs(t) do
	if v.download then
		tt[v.download] = v.md5
  elseif v.mkdir then
    tt[v.mkdir] = 1
	end
  end
  return tt
end

local function is_need_download2(t,file,md5)
  return t[file] ~= md5
end

local function filelist_compare_table(source,target)
	local source_t = lxp.parse(source)
	local target_t = lxp.parse(target)
	local filelist = {}
	if source_t and target_t then
		local st = filelist_by_table(source_t,'')
		local tt = filelist_by_table(target_t,'')
		local fast_tt = g_fast_tt(tt)
		local fast_st = g_fast_tt(st)
		if st and fast_tt and fast_st then
			--sub operate
			for i,v in ipairs(tt) do
				if v.download and not fast_st[v.download] then
					filelist[#filelist+1] = {remove=v.download}
				elseif v.mkdir and not fast_st[v.mkdir] then
					filelist[#filelist+1] = {remove_dir=v.mkdir}
				end
			end
			--add operate
			for i,v in ipairs(st) do
				if v.download and is_need_download2(fast_tt,v.download,v.md5) then
					filelist[#filelist+1] = v
				elseif v.mkdir and is_need_download2(fast_tt,v.mkdir,1) then
					filelist[#filelist+1] = v
				end
			end			
		end
	end
	return filelist
end

local function download_compare_filelist(source,target)
	local filelist = filelist_compare_table(source,target)
	return filelist
end

local function download_file_by_table(tb,ups)
	local filelist = filelist_by_table(tb,ups)
	return filelist
end

local function download_all_filelist(filelist)
  local flt = lxp.parse(filelist)
  if flt then
    return download_file_by_table(flt,'')
  else
  --filelist file parse error?
    cclog('Cant parse xml:\n'..filelist)
    return nil
  end
end

--return result,oplist
local function doSync()
  if isNeedSync() then
    --download version.xml and filelist.xml
    local filelist_xml = 'filelist.xml'
    local version_xml = 'version.xml'
    local local_filelist = read_local_file(filelist_xml)
    local host_filelist = read_network_file(filelist_xml)
	local filelist
    if local_filelist and host_filelist then
      --compare
      filelist = download_compare_filelist(host_filelist,local_filelist)
	  return true,filelist
    elseif local_filelist then
      --host down?
	  return false,'Can not connect synchronous server!\nPlease check your network!'
    elseif host_filelist then
      --first sync?
      filelist = download_all_filelist(host_filelist)
	  return true,filelist
    else
	  return false,'Can not connect synchronous server!'
    end
  else
		return true,'ok'
  end
end

local function CreateSyncLayer()
	local layer = cc.Layer:create()
	local loadingBar = ccui.LoadingBar:create()
	local widgetSize = cc.Director:getInstance():getVisibleSize()
	local first = 0
	local maxcount,count
  local err,filelist
  
	loadingBar:setTag(0)
	loadingBar:setName("LoadingBar")
	loadingBar:loadTexture("loading/sliderProgress.png")
	loadingBar:setPercent(0)
	loadingBar:setPosition(cc.p(widgetSize.width / 2.0, widgetSize.height / 2.0 + loadingBar:getSize().height / 4.0))
	layer:addChild(loadingBar)
  
	local function exit_loading()
		loadingBar:setPercent(100)
		layer:unscheduleUpdate()
		--do script
		package.path = package.path..';'..local_dir..'?.lua'
		require ('src/helloworld')
	end
	
	local function update(delta)
		if first==0 then
			first = 1
			err,filelist = doSync()
			if err and filelist and type(filelist)=='table' then
				maxcount = #filelist
				count = 0
			elseif filelist == 'ok' then
				first = 0
				cclog('all ready!')
				exit_loading()
				return
			else
				first = 0
				cclog('error :update filelist is nil')
				exit_loading()
				return
			end
		end
		
    if not filelist then
      cclog('empty update..')
      return
    end
    
		count = count + 1
		if loadingBar ~= nil and count and maxcount then
			loadingBar:setPercent(100*count/maxcount)
		end
		if count > maxcount then
			download_file('version.xml')
			download_file('filelist.xml')		
			exit_loading()
			cclog('finiched..')
		elseif filelist and filelist[count] then
			operate_one_by_one(filelist[count])
		else
			exit_loading()
			cclog('download error!')
		end		
	end
	
	layer:scheduleUpdateWithPriorityLua(update,0)
	
	local function onNodeEvent(tag)
        if tag == "exit" then
			cclog('Exit loading...')
            layer:unscheduleUpdate()
			first = 0
        end
    end
	
	layer:registerScriptHandler(onNodeEvent)
	
	return layer
end

--doSync()
local function doSyncScene()
  local scene = cc.Scene:create()
  scene:addChild(CreateSyncLayer())
  cc.Director:getInstance():runWithScene(scene)
end

doSyncScene()

--[[
s = download_http_by_socket(host[1],'/lgh/filelist.xml',81)
if s then
  print(s)
end
local result = http.request('http://'..host[1]..':81/lgh/filelist.xml')
print(result)

local result = download_http_by_curl('http://'..host[1]..':81/lgh/filelist.xml')
print(result)
print("parse contante..")
local t = lxp.parse(result)
parse_xml(t)
for k,v in pairs(t) do
  print(k)
end
--]]