local kits = require "kits"
local curl = require "curl"
local md5 = require "md5"
local json = require "json-c"
local login = require "login"

local luacore_version = 2
local luaapp_name = "unkown"
local luaapp_version = 0

local last_source
local last_line

--http://api.lejiaolexue.com/ssp/kv/pset.ashx?app_id=12&sign=a1c1dnha73kan&key=abc&value=anystring
local crash_url ="http://api.lejiaolexue.com/ssp/debug/pset.ashx"
local crash_url_get ="http://api.lejiaolexue.com/ssp/debug/pget.ashx"

local platform = CCApplication:getInstance():getTargetPlatform()

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
			kits.log( "INFO : report_bug result:"..tostring(result) )
		end
	else
		kits.log('ERROR report_bug invalid param')
	end
end

local function report_export( errmsg,stack_level )
	local t = debug.getinfo(stack_level or 2,'Sl')
	if t and t.source and t.currentline and last_source~=t.source and last_line~=t.currentline then
		local bugs = {}
		bugs.source = t.source
		bugs.line = t.currentline
		bugs.call_stack = ""
		for level = stack_level or 2,16 do
			local t = debug.getinfo(level,'Sl')
			if t and t.source and t.currentline then
				bugs.call_stack = bugs.call_stack..t.source.."@"..t.currentline.."\n"
			else
				break
			end
		end
		kits.log("INFO : Call Stack")
		kits.log("========")
		kits.log( "INFO : "..bugs.call_stack )
		
		bugs.errmsg = errmsg
		bugs.type = 'lua'
		
		if platform == kTargetWindows then
			bugs.platform = 'windows'
		elseif platform == kTargetIphone then
			bugs.platform = 'iphone'
		elseif platform == kTargetIpad then
			bugs.platform = 'ipad'
		elseif platform == kTargetAndroid then
			bugs.platform = 'android'
		elseif platform == kTargetMacOS then
			bugs.platform = 'macx'
		else
			bugs.platform = 'unkown'
		end
		bugs.cocos2dx = '3.2'
		bugs.luacore_version = luacore_version
		bugs.luaapp_name = luaapp_name
		bugs.luaapp_version = luaapp_version
		
		local logs = kits.get_logs()
		if logs then
			local ca={}
			for i=1,32 do
				local inx = #logs+i-32
				if inx > 0 and logs[inx]then
					table.insert(ca,logs[inx])
				end
			end
			bugs.log = table.concat(ca,'\n')
			kits.log( bugs.log)
		end
		report_bug{ appid = 1,key = md5.sumhexa( t.source..tostring(t.currentline) ),value=bugs}
		last_source = t.source
		last_line = t.currentline
	elseif t then
		kits.log("ERROR _G_ERROR :"..tostring(t.source)..":"..tostring(t.currentline))
		kits.log("INFO : "..tostring(errmsg))
	end	
end

function __G__TRACKBACK__(errmsg)
	kits.log( "ERROR : "..tostring(errmsg) )
	report_export(errmsg,3)
end

return 
{
	report = report_export,
	open = open_report_handle,
}