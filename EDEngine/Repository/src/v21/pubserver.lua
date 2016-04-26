local kits = require "kits"
local uikits=require "uikits"
local socket=require "socket"
local factory = require "factory"
local base = require "base"
local json = require "json-c"
local udp
local function messagebox(caption,text,button,func)
	local messageBox = factory.create(base.MessageBox)
	messageBox:open{caption=caption,text=text,onClick=func,button=button or 1}
end
return {
	pub = function( gamename )
		if udp then
			udp:close()
		end
		udp = socket.udp()
		udp:setoption('broadcast',true)
		local host = socket.dns.gethostname()
		kits.log("host name : "..tostring(host))
		local address,resolved = socket.dns.toip(host)
		kits.logTable(resolved)
		address,resolved = socket.dns.toip('guancha.cn')
		kits.logTable(resolved)		
		return true
		--[[
		local datagrams = json.encode{name=gamename,address=address,port=5001}
		if address then
			uikits.delay_call(nil,function(dt)
				if not udp then
					return false
				end
				local ret,err = udp:sendto(datagrams,"255.255.255.255",5000)
				if not ret then
					udp:close()
					udp=nil
					messagebox("error","udp.sendto "..tostring(err),1,function(e)end)
					return false
				end
				kits.log("broadcast : "..datagrams)
				return true
			end,0.5)
			return address
		else
			udp:close()
			udp=nil
			messagebox("error","toip "..tostring(address),1,function(e)
			end)
		end
		--]]
	end,
	stop = function()
		if udp then
			udp:close()
			udp=nil
		end
	end,
	search = function(notify_func)
		if udp then
			udp:close()
		end
		local function notify(event,msg)
		if notify_func then
			notify_func(event,msg)
		end
		end
		udp = socket.udp()
		udp:setoption('broadcast',true)
		udp:setsockname("*",5000)
		udp:settimeout(0.1)
		local c = 0
		uikits.delay_call(nil,function(dt)
			if not udp then
				return false
			end		
			c = c+1
			local msg,addr,port = udp:receivefrom()
			if msg then
				kits.log("recv : "..tostring(msg).." from "..tostring(addr)..":"..tostring(port))
				notify("recv",msg)
				return true
			elseif addr=='timeout' then
				kits.log("recv : nothing")
				if c > 20 then
					notify("timeout")
					return false
				end
				return true
			else
				kits.log("recv error : "..tostring(addr))
				notify("error",tostring(addr))
			end
		end,0.5)
		return true
	end,
}