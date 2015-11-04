local thread = require "thread"

--线程模型实现
local function create(url,on_message)
	local filo
	local doneclose
	local s = {}
	s.send = function(self,data)
		filo = filo or {}
		table.insert(filo,data)
	end
	s.close = function(self)
		doneclose = true
	end
	s.thread = thread.new("wst",function(event,msg)
		if on_message then
			on_message(event,msg)
		end
		if filo and #filo > 0 then
			local data = filo
			filo = nil
			return "send",data
		end
		if doneclose then
			return "close"
		end		
	end,url)
	return s
end

--不使用线程模型实现
local function create2(url,on_message)
	local s = {}
	local ws_client = require "websocket.client_sync"()
	local uikits = require "uikits"
	local b,msg = ws_client:connect(url)
	if b then
		ws_client.sock:settimeout(0)
	else
		on_message("error",msg)
	end
	s.send = function(self,data)
		ws_client:send(data)
	end
	s.close = function(self)
		ws_client:close()
	end	
	uikits.delay_call(nil,function(dt)
		local msg,status = ws_client:receive()
		if msg then
			on_message("frame",msg)
		elseif status == "closed" then
			on_message("closed")
			return false
		elseif not status then
			on_message("error",status)
			return false
		end
		return true
	end,0.1)
	return s
end

return {
	create = create,
	create2 = create2,
}