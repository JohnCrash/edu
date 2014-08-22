local kits = require "kits"
local mt = require "mt"
local md5 = require "md5"
local uikits = require "uikits"
local json = require "json-c"
local login = require "login"

local request_list = {}

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
	local n = get_name( url )
	if n then
		return kits.read_cache( n )
	end
end

local function is_done( url )
	local s = get_name( url )
	if s then
		return kits.exist_cache( s )
	end
end

local function is_hot( url,sec )
	local n = get_name(url)
	if n then
		return kits.hot_cache( n,sec )
	end
	return false
end

local function request( url,func )
	--if is_hot(url,60) then
	--	uikits.delay_call( nil,func,random_delay(),true )
	--	return
	--end
	local mh,msg = mt.new('GET',url,login.cookie(),
			function(obj)
				if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
					if obj.state == 'OK' and obj.data then
						kits.log('request:'..url..' successed!')
						kits.log('	request data write to '..tostring(get_name(url)))
						kits.write_cache(get_name(url),obj.data)
						func( true )
					else
						if obj.state == 'FAILED' and is_done( url ) then --下载失败尝试使用本地缓冲
							func( true )
						else
							kits.log('ERROR : request failed! url = '..tostring(url))
							kits.log('	reason: is_done return false : '..tostring(get_name(url)))
							func( false )
						end
					end
				end
			end )
	if not mh then
		if is_done( url ) then
			func( true )
		else
			func( false )
			kits.log('ERROR : request failed! url = '..tostring(url))
			kits.log('	reason:'..tostring(msg))
		end
	end
	table.insert(request_list,mh)
end

local function request_json( url,func )
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
	request(url,json_proc)
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
					if t and type(t)=='table' and t.md5 and type(t.md5)=='string' and string.len(t.md5)>0 then
						func(true,t.md5)
						return
					end
				end
				func(false)
				kits.log('ERROR : upload failed! url = '..tostring(url)..' filename='..filename)
				kits.log('	reason:'..tostring(obj.errmsg))
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
			[1] = {url,done},
			[2] = {url,done},
			...
			--url,cookie 链接地址,cookie
			--done 回调，如果给定链接下载成功通知，并传给数据.不缓存数据
		}
		ui --延时调用
	}
--]]

local function request_resources( rtable,efunc )
	if rtable and type(rtable)=='table' and rtable.urls and type(rtable.urls) == 'table' and 
		efunc and type(efunc)=='function' then
		local b = true
		for i,v in pairs(rtable.urls) do
			b = false
			if type(v)=='table' and isurl(v.url) then
				request(v.url,function(b)
					efunc( rtable,i,b )
				end)
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
}
