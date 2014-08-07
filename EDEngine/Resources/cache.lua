local kits = require "kits"
local mt = require "mt"
local md5 = require "md5"
local uikits = require "uikits"
local json = require "json-c"
local login = require "login"

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
end

--得到资源cache数据
local function get_data( url )
	local n = get_name( url )
	if n then
		print( n )
		return kits.read_cache( n )
	end
end

local function is_done( url )
	local s = get_name( url )
	if s then
		return kits.exist_cache( s )
	end
end

--请求资源列表rtable,一个url列表
--请求如果获得了全部资源,将调用函数efunc
--该函数立刻返回,任务交给后台线程下载
--[[
	rtable = {
		urls = 
		{
			[1] = {url,cookie,done},
			[2] = {url,cookie,done},
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
		for i,v in pairs(rtable.urls) do
			if type(v)=='table' and isurl(v.url) then
				if is_done(v.url) then
					if rtable.ui then
						--延迟
						uikits.delay_call( rtable.ui,efunc,0.1,rtable,i,true )
					else
						efunc( rtable,i,true ) --已经下载了
					end
				else
					--开始后台下载
					local mh,msg = mt.new('GET',v.url,v.cookie,
							function(obj)
								if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED' then
									if obj.state =='OK' and obj.data then
										if v.done and type(v.done)=='function' then
											v.done( obj.data )
										else
											kits.write_cache( get_name(v.url),obj.data )
										end
										efunc( rtable,i,true )
									else
										--下载失败
										efunc( rtable,i,false )
									end
								end
							end)
					if not mh then
						--下载失败
						efunc( rtable,i,false )
					end
				end
			else
				efunc( rtable,i,false )
			end
		end
	else
		return false,"request_resources invalid argument"
	end
	return true
end

local function request( url,func )
	local mh,msg = mt.new('GET',url,login.cookie(),
			function(obj)
				if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
					if obj.state == 'OK'  then
						if obj.data then
							kits.write_cache(get_name(url),obj.data)
							func( true )
						end
					else
						if is_done( url ) then --下载失败尝试使用本地缓冲
							func( true )
						else
							kits.log('ERROR : request failed! url = '..tostring(url))
							kits.log('	reason: is_done return false')
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

return {
	request_resources = request_resources,
	get_name = get_name,
	get_data = get_data,
	request = request,
	request_json = request_json,
}
