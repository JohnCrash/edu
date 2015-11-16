local ws_client = require "websocket.client_sync"()

return function(url)
	local b,msg = ws_client:connect(url)
	if b then
		ws_client.sock:settimeout(0.1)
	else
		post("error",msg)
	end
	local t,status,e,f,g
	while b do
		msg,status,e,f,g = ws_client:receive()
		if msg then
			b,msg,t = post("frame",msg)
		elseif status == "closed" then
			b,msg,t = post(status)
			break
		elseif not status then
			b,msg,t = post("error",status)
			break
		else
			b,msg,t = post("idle")
		end
		if msg=="close" then
			ws_client:close()
			b,msg,t = post("closed")
			break
		elseif msg=="send" then
			if t and type(t)=="string" then
				ws_client:send(t)
			elseif t and type(t)=="table" then
				for i,v in pairs(t) do
					ws_client:send(v)
				end
			else
				post("error","send invalid argument")
				break
			end
		elseif msg=="exit" then
			break
		end
	end
end