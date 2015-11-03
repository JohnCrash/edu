local json = require "json"
local kits = require "kits"
local mt = require "mt"
local md5 = require "md5"
local login = require "login"

local function post(url,form,func,content_type)
	local ret,msg = mt.new('POST',url,login.cookie(),
		function(obj)
			if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
				if obj.state == 'OK' and obj.data then
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

local function pay(app_id,order_no,
total_money,product_info,
product_count,provider_id,
private_key,func,extend,user_context)
	if not app_id then
		return false,"invalid argument app_id"
	end
	if not order_no then
		return false,"invalid argument order_no"
	end
	if not total_money or total_money <= 0 then
		return false,"invalid argument total_money = "..tostring(total_money)
	end
	if not product_info then
		return false,"invalid argument product_info = "..tostring(product_info)
	end
	if not product_count or product_count <= 0 then
		return false,"invalid argument product_count = "..tostring(product_count)
	end
	if not provider_id then
		return false,"invalid argument provider_id"
	end
	if not private_key then
		return false,"invalid argument private_key"
	end	
	if not func and type(func)=="function" then
		return false,"invalid argument func"
	end
	local pay_table={
		order_no = order_no,
		total_money = total_money,
		product_info = product_info,
		product_count = product_count,
		app_id = app_id,
		pay_type = 1,
		extend = extend,
		user_context = user_context,		
	}
	local t = json.encode(pay_table)
	local c = md5.sumhexa(order_no..total_money..app_id..product_count..product_info..provider_id..private_key)
	local form = "t="..t.."&c="..c
	local url = "http://pay.lejiaolexue.com/PayHandler.ashx?s=app"
	post(url,form,function(b,data)
		if b and data then
			local t = json.decode(data)
			if t then
				if t.result and t.result == 200 then
					func(true,t.msg)
				elseif t.result then
					func(false,t.msg)
				else
					func(false,tostring(data))
				end
			else
				func(false,tostring(data))
			end
		else
			func(b,tostring(data))
		end
	end)
	return true
end

local function byurl(form,func)
	local url = "http://pay.lejiaolexue.com/PayHandler.ashx?s=app"
	post(url,form,function(b,data)
		if b and data then
			local t = json.decode(data)
			if t then
				if t.result and t.result == 200 then
					func(true,t.msg)
				elseif t.result then
					func(false,t.msg)
				else
					func(false,tostring(data))
				end
			else
				func(false,tostring(data))
			end
		else
			func(b,tostring(data))
		end
	end)
	return true
end

return {
	pay = pay,
	byurl = byurl,
}