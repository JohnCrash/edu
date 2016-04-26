local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/shijiegui.json',
	FILE_3_4 = 'hitmouse2/shijiegui43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	CAPTION = 'biao/bism/shaim',
	DATE = 'biao/bism/shijian',
}

local worldmatch_rule = uikits.SceneClass("worldmatch_rule",ui)

function worldmatch_rule:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		if self._arg then
			uikits.child(self._root,ui.CAPTION):setString(self._arg.caption or '-')
			uikits.child(self._root,ui.DATE):setString(self._arg.date or '-')
		end
	end
end

function worldmatch_rule:release()
end

return worldmatch_rule