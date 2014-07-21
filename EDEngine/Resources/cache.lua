local kits = require "kits"
local mt = require "mt"
local md5 = require "md5"
local uikits = require "uikits"

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
										kits.write_cache( get_name(v.url),obj.data )
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

return {
	request_resources = request_resources,
	get_name = get_name,
	get_data = get_data,
}
