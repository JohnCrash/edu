local socket = require "socket"

--[[
function get(host,url,port)
	local connect,msg = socket.connect(host,port)
	if connect then
		local reqs = "GET "..url.." HTTP/1.0\r\n"
		reqs = reqs.."Host:"..host.."\r\n"
		--reqs = reqs.."Connection:Keep-Alive\r\n"
		--reqs = reqs.."Content-length:0\r\n"
		reqs = reqs.."\r\n"
		local result = connect:send(reqs)
		repeat
			local t = cc_clock()
			local chunk,status,partial = connect:receive()
			if chunk then
				post(chunk)
			end
		until status == 'closed'
		connect:close()
		post(false,"closed")
	else
		post(false,"connect failed")
	end
end
--]]
local ws_client = require "websocket.client_sync"()
function ws(host,url,port)
	local b,msg = ws_client:connect(host..url)
	if b then
	end
end

return ws