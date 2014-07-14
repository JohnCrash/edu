local kits = require 'kits'
local cache = require 'cache'
local json = require 'json'

local function read_topics_cache( pid )
	local result = kits.read_cache( pid )
	if result then
		local t = json.decode(result)
		if t then
			return t
		else
			print('error : t = nil, read_topics_cache pid = '..tostring(pid))
		end
	else
		print('error : result = nil , read_topics_cache pid = '..tostring(pid))
	end
end

local function write_topics_cache( pid,t )
	local result = json.encode( t )
	if result then
		kits.write_cache( pid,result )
	else
		print('error : result = nil, write_topics_cache pid = '..tostring(pid))
	end
end

return 
{
	read = read_topics_cache,
	write = write_topics_cache,
}
