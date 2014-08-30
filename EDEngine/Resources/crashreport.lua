local kits = require "kits"
local curl = require "curl"
local md5 = require "md5"
local json = require "json-c"
local login = require "login"

local luacore_version = 1
local luaapp_name = "unkown"
local luaapp_version = 0

local last_source
local last_line

--http://api.lejiaolexue.com/ssp/kv/pset.ashx?app_id=12&sign=a1c1dnha73kan&key=abc&value=anystring
local crash_url ="http://api.lejiaolexue.com/ssp/kv/pset.ashx"
local crash_url_get ="http://api.lejiaolexue.com/ssp/kv/pget.ashx"

local function open_report_handle(appname,version)
	luaapp_name = appname
	luaapp_version = version
end

local function report_bug(t)
	if t and type(t)=='table' and t.appid and t.key and t.value and type(t.value)=='table' then
		local value = json.encode(t.value)
		if value then
			local text = 'value='..value
			local url_post = crash_url..'?app_id='..tostring(t.appid)..'&sign=unkown&key='..tostring(t.key)
			local result = kits.http_post(url_post,text,login.cookie())
			print( "report_bug result:"..tostring(result) )
		end
	else
		print('ERROR report_bug invalid param')
	end
end

function __G__TRACKBACK__(errmsg)
	local t = debug.getinfo(2,'Sl')
	if t and t.source and t.currentline and last_source~=t.source and last_line~=t.currentline then
		local bugs = {}
		bugs.source = t.source
		bugs.line = t.currentline
		bugs.call_stack = ""
		local level = 2
		for level = 2,16 do
			local t = debug.getinfo(level,'Sl')
			if t and t.source and t.currentline then
				bugs.call_stack = bugs.call_stack..t.source.."@"..t.currentline.."\n"
			else
				break
			end
		end
		bugs.errmsg = errmsg
		bugs.type = 'lua'
		--[[
			bugs.cpu
			bugs.os
			bugs.api
			bugs.core_version
		--]]
		bugs.luacore_version = luacore_version
		bugs.luaapp_name = luaapp_name
		bugs.luaapp_version = luaapp_version
		--[[
			bugs.log
		--]]
		report_bug{ appid = 1,key = md5.sumhexa( t.source..tostring(t.currentline) ),value=bugs}
		last_source = t.source
		last_line = t.currentline
	elseif t then
		print("_G_ERROR :"..tostring(t.source)..":"..tostring(t.currentline))
		print("	"..tostring(errmsg))
	end
end

return 
{
	report = report_bug,
	open = open_report_handle,
}