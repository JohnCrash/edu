local socket = require "socket"

local mod1 = 256
local mod2 = 65536
local mod3 = 16777216

local function toint32( s )
	return string.byte(s,1)*mod3+string.byte(s,2)*mod2+string.byte(s,3)*mod1+string.byte(s,4)
end

local function int32tostr( v )
	local p1 = string.char(v%mod1)
	local p2 = string.char(math.floor(v/mod1)%mod1)
	local p3 = string.char(math.floor(v/mod2)%mod1)
	local p4 = string.char(math.floor(v/mod3)%mod1)
	return p4..p3..p2..p1
end

local function send_imp(socket,msg,trycount)
	local try = 0
	while try<trycount do
		b,err = socket:send(msg)
		if b then
			return b
		elseif err~="timeout" then
			return b,err
		else
			try=try+1
			sleep(100)
			print("send time out try agin")
		end
	end
	return false,"send failed"
end

local function send( socket,msg )
	if msg and socket then
		local b,err,try
		try = 0
		if type(msg)=="string" then
			return send_imp(socket,int32tostr(string.len(msg))..msg,3)
		elseif type(msg)=="table" then
			local data = {}
			for i,v in pairs(msg) do
				table.insert(data,int32tostr(string.len(v))..v)
			end
			return send_imp(socket,table.concat(data),3)
		else
			return nil,"send invalid data "..tostring(msg)
		end
	else
		return nil,"send nil"
	end
end

local function recv( socket )
	local data
	while true do
		local msg,err = socket:receive(4)
		if msg and string.len(msg)==4 then
			data = data or {}
			local l = toint32(msg)
			if l >= 0 and l<65530 then
				socket:settimeout(60)
				msg,err = socket:receive(l)
				socket:settimeout(0.2)
				if msg then
					table.insert(data,msg)
				else
					return nil,"receive timeout"
				end
			else
				return nil,"out of range "..tostring(l)
			end
		end
		if err == "timeout" or err == "closed" then
			return data,nil
		end
	end
end

return function(adress,port)
	local connect,msg = socket.connect(adress,port)
	if connect then
		connect:settimeout(0.2)
	else
		post("error",msg)
	end
	local b,data,t
	b = connect
	while b do
		data,msg = recv(connect)
		if data then
			b,msg,t = post("frame",data)
		elseif msg == "closed" then
			b,msg,t = post(msg)
			break			
		elseif msg then
			b,msg,t = post("error",msg)
			connect:close()
			break
		else
			b,msg,t = post("idle")
		end
		if msg=="close" then
			connect:close()
			b,msg,t = post("closed")
			break
		elseif msg=="send" then
			if t and (type(t)=="string" or type(t)=="table") then
				b,msg = send(connect,t)
				if not b and msg then
					b,msg,t = post("error",msg)
					connect:close()
					return
				end
			else
				connect:close()
				post("error","send invalid argument")
				break
			end
		elseif msg=="exit" then
			break			
		end		
	end
end