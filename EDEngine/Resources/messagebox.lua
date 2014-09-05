local kits = require "kits"
local uikits = require "uikits"

local ui = {
	LOADBOX = 'homework/ladingbox.json',
	LOADING = 'load/load.ExportJson',
	FILE = 'homework/networkbox.json', --网络错误
	FILE2 = 'homework/repairbox.json', --系统维护500
	EXIT = 'red_in/out',
	TRY = 'red_in/again',
}

local function messagebox( parent )
	
end

return 
{
	LOADING = 1,
	RETRY = 2,
	REPAIR = 3,
	TRY = 4,
	CLOSE = 5,
	open = messagebox,
}