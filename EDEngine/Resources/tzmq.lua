return function()
	local zmq = require"lzmq"

	local context = zmq.init(1)

	--  Socket to talk to server
	print("Connecting to hello world server...")
	local socket = context:socket(zmq.REQ)
	socket:connect("tcp://192.168.2.157:5555")

	for n=1,10 do
		print("Sending Hello " .. n .. " ...")
		socket:send("Hello")

		local reply = socket:recv()
		print("Received World " ..  n .. " [" .. reply .. "]")
	end
	socket:close()
	context:term()
end