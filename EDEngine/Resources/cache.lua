local kits = require "kits"
local mt = require "mt"
local md5 = require "md5"
local uikits = require "uikits"
local json = require "json-c"
local login = require "login"
local lfs = require "lfs"

local request_list = {}
local cache_data = {}
setmetatable(cache_data,{__mode='v'})
 
local function add_cache_data(url,data)
	cache_data[url] = data
end

local function clear_files( path,day )
	local len = string.len(path)
	if string.sub(path,len,len) == '/' then
		path = string.sub(path,1,len-1)
	end
	if not lfs.attributes( path ) then
		kits.log("ERROR path not exist "..path )
		return
	end
	kits.log('---> do clear path:'..path)
	for file in lfs.dir(path) do
		if file~='.' and file~='..' then
			local f = path..'/'..file
			local attr = lfs.attributes(f)
			if attr.mode=='directory' then
			else
				local dt = os.time() - attr.modification
				if dt > day*24*3600 then 
					os.remove(f)
				end
			end
		end
	end
end

local function clear_cache()
	local path = kits.get_cache_path()
	kits.log('clear path:'..path)
	clear_files( path,3 ) --保留7天的缓冲数据
	local tmp = kits.get_tmp_path();
	kits.log('clear path:'..path)
	clear_files( tmp,1 ) --临时文件保留一天
end

local function random_delay()
	return math.random()
end

local function isurl( url )
	if url and type(url)=='string' and string.len(url) > 4 then
		if string.lower( string.sub(url,1,4) ) == 'http' then
			return true
		end
	end
	return false
end

--得到资源cache名称
local function get_name( url )
	if isurl( url ) then
		if string.sub(url,-4,-4)=='.' then
			return md5.sumhexa(url)..string.sub(url,-4)
		else
			return md5.sumhexa(url)
		end
	end
	return nil
end

--得到资源cache数据
local function get_data( url )
	if cache_data[url] then
		return cache_data[url] --直接从缓存返回
	else
		local n = get_name( url )
		if n then
			return kits.read_cache( n )
		end
	end
end

local function is_cache( f )
	if f then
		return kits.exist_cache( f )
	end
end

local function is_done( url )
	if cache_data[url] then
		return true
	else
		local s = get_name( url )	
		if s then
			return kits.exist_cache( s )
		end
	end
end

local function is_hot( url,sec )
	local n = get_name(url)
	if n then
		return kits.hot_cache( n,sec )
	end
	return false
end

local function request_nc( url,func,filename ) --网络优先，然后缓存
	local mh,msg = mt.new('GET',url,login.cookie(),
			function(obj)
				if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
					if obj.state == 'OK' and obj.data then
						kits.log('INFO : request:'..url..' successed!')
						kits.log('INFO :	request data write to '..tostring(get_name(url)))
						if filename then
							kits.write_cache(filename,obj.data)
						else
							add_cache_data(url,obj.data) --加入缓存
							kits.write_cache(get_name(url),obj.data)
						end
						func( true,obj.data )
					else
						if obj.state == 'FAILED' and (is_done( url ) or is_cache(filename)) then --下载失败尝试使用本地缓冲
							func( true,obj.data )
						else
							kits.log('ERROR : request failed! url = '..tostring(url))
							if obj.state == 'FAILED' then
								kits.log('INFO : reason: obj.state = FAILED '..tostring(get_name(url)))
								kits.log('INFO : reason: errcode='..tostring(obj.errcode)..' errmsg='..tostring(obj.errmsg) )
								kits.log('=====obj.data=====')
								kits.log(tostring(obj.data))
								kits.log('==================')
							else
								kits.log('	reason: is_done return false : '..tostring(get_name(url)))
							end
							func( false )
						end
					end
				end
			end )
	if not mh then
		if is_done( url ) or is_cache(filename) then
			if is_done( url ) then
				func( true,get_data(url) )
			else
				data = kits.read_cache( filename )
				func( true,data )
			end
		else
			func( false,msg )
			kits.log('ERROR : request failed! url = '..tostring(url))
			kits.log('	reason:'..tostring(msg))
		end
	else
		table.insert(request_list,mh)
	end
end
local function request_cn( url,func,filename )
	if is_done(url) then
		if filename then
			if not kits.exist_cache(filename) then
				kits.copy_cache(get_name(url),filename)
			end
		end
		func( true )
	else
		request_nc( url,func,filename )
	end
end
local function request_n( url,func )
	local mh,msg = mt.new('GET',url,login.cookie(),
			function(obj)
				if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
					if obj.state == 'OK' and obj.data then
						add_cache_data(url,obj.data) --加入缓存
						func( true,obj.data )
					else
						func( false,obj.errmsg )
					end
				end
			end )
	if not mh then
		func( false,msg )
		kits.log('ERROR : request failed! url = '..tostring(url))
		kits.log('	reason:'..tostring(msg))
	else
		table.insert(request_list,mh)
	end
end
--两种优先级别网络优先，文件优先
--priority = 'CN' 表示先文件后网络 'NC' 表示先网络后文件 ,'N'表示仅网络，'C'仅文件
local function request( url,func,priority )
	if priority == 'C' then
		if is_done(url) then
			func( true )
		else
			func( false )
		end
	elseif priority == 'N' then
		request_n( url,func )
	elseif priority == 'CN' then
		request_cn( url,func )
	elseif priority == 'NC' then
		request_nc( url,func )
	else
		request_nc( url,func ) --默认是nc
	end
end

local function request_json( url,func,priority )
	local function json_proc(b)
		if b then
			local data = get_data(url)
			if data then
				local t = json.decode(data)
				if t then
					func(t)
				else
					func(false)
					kits.log('ERROR : request_json json decode failed! url = '..tostring(url))
					kits.log('data='..string.sub(tostring(data),1,128)..'...')
				end
			else
				func(false)
				kits.log('ERROR : request_json get_data = nil! url = '..tostring(url))
			end
		else
			func(false)
			kits.log('ERROR : request_json failed url = '..tostring(url))
		end
	end
	request(url,json_proc,priority)
end

--上传
--http://file-stu.lejiaolexue.com/rest/user/upload/hw
--下载
--http://file-stu.lejiaolexue.com/rest/dl
local function upload(url,filename,data,func,progress_func)
	local progress = nil
	if progress_func and type(progress_func)=='function' then
		progress = progress_func
	end
	local mh,msg = mt.new("HTTPPOST",url,login.cookie(),
		function(obj)
			if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
				if obj.state == 'OK' and obj.data then
					local t = json.decode(obj.data)
					if t and type(t)=='table' then
						func(true,t)
						return
					end
				end
				func(false)
				kits.log('ERROR : upload failed! url = '..tostring(url)..' filename='..filename)
				kits.log('	reason:'..tostring(obj.errmsg)..' errorcode='..tostring(obj.errcode))
				kits.log('	'..tostring(obj.data))
			end
			if obj.state == 'LOADING' and progress then
				progress( obj.progress )
			end
		end,{{copyname='filedata',filename=filename,filecontents=data}})
	if not mh then
		func(false)
		kits.log('ERROR : upload failed! url = '..tostring(url)..' filename='..filename)
		kits.log('	reason:'..tostring(msg))
	end
end

local function post(url,form,func,content_type)
	local ret,msg = mt.new('POST',url,login.cookie(),
		function(obj)
			if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
				if obj.state == 'OK' and obj.data then
					add_cache_data(url,obj.data) --加入缓存
					kits.write_cache(get_name(url),obj.data)
					func( true,obj.data )
				else
					func( false,obj.errmsg)
					kits.log('ERROR : cache.post failed! url = '..tostring(url))
					kits.log('	errmsg = '..tostring(obj.errmsg))
					kits.log('	errcode = '..tostring(obj.errcode))
					kits.log('	data= '..tostring(obj.data))
				end
			end
		end,form,content_type )
	if not ret then
		kits.log('ERROR : cache.post failed url = '..tostring(url))
		kits.log('	errmsg = '..tostring(msg))
		func( false,msg )
	end
end

--[[local function post_json( url,t,func )
end
--]]
local function request_cancel()
	for i,m in pairs(request_list) do
		m:cancel()
	end
	request_list = {}
end

--请求资源列表rtable,一个url列表
--请求如果获得了全部资源,将调用函数efunc
--该函数立刻返回,任务交给后台线程下载
--[[
	rtable = {
		urls = 
		{
			[1] = {url,filename,done},
			[2] = {url,filename,done},
			...
			--url,cookie 链接地址,cookie
			--done 回调，如果给定链接下载成功通知，并传给数据.不缓存数据
		}
		ui --延时调用
	}
--]]

local function request_resources( rtable,efunc,priority )
	if rtable and type(rtable)=='table' and rtable.urls and type(rtable.urls) == 'table' and 
		efunc and type(efunc)=='function' then
		local b = true
		for i,v in pairs(rtable.urls) do
			b = false
			if type(v)=='table' and isurl(v.url) then
				request_cn(v.url,function(b)
					efunc( rtable,i,b )
				end,v.filename)
			else
				efunc( rtable,i,false )
			end
		end
		if b then
			efunc( rtable,0,b )
		end
	else
		return false,"request_resources invalid argument"
	end
	return true
end

return {
	request_resources = request_resources,
	get_name = get_name,
	get_data = get_data,
	request = request,
	request_json = request_json,
	request_cancel = request_cancel,
	upload = upload,
	clear = clear_cache,
	post = post,
	request_nc = request_nc
--	post_json = post_json,
}
