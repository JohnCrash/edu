local thread = require "thread"

local function create(adres,port,on_message)
	local filo
	local doneclose
	local iserror,isclosed
	local s = {}
	s.send = function(self,data)
		if iserror then
			return false,iserror
		end
		if isclosed then
			return false,"closed"
		end
		filo = filo or {}
		table.insert(filo,data)
		return true
	end
	s.close = function(self)
		doneclose = true
	end
	s.thread = thread.new("st",function(event,msg)
		if event=="error" then
			iserror = msg
		elseif event=="closed" then
			isclosed = true
		end
		if on_message then
			on_message(event,msg)
		end
		if msg=="closed" then
			filo = nil
			return "exit"
		end
		if filo and #filo > 0 then
			local data = filo
			filo = nil
			return "send",data
		end
		if doneclose then
			return "close"
		end		
	end,adres,port)
	return s	
end

return {
	create = create,
}