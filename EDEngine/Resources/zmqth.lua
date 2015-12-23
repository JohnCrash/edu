return function(ctx,address)
	local zmq = require"lzmq"
	local context = zmq.init_ctx(ctx)
	local socket,err = context:socket(zmq.PAIR)
	if not socket then
		print("socket error :"..zmq.strerror(err))
		return
	end
	socket:bind(address)
	print("wait for single.."..tostring(address))
	local msg,errorMsg = socket:recv()
	if msg then
		print("run.. : "..msg)
	else
		print("error : "..zmq.strerror(errorMsg))
	end
	socket:close()
end