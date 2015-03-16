local kits = require "kits"
local uikits = require "uikits"
local lfs = require "lfs"
local ljshell = require "ljshell"
local base = require "base"
local update = require "update_factory"

local ui={
	FILE = 'res/splash_6.json',
}

local classids = {}
for i,v in pairs(base) do
	if type(v)=='string' then
		table.insert(classids,v)
	end
end

return {
	init = function(self)
		self._item = uikits.fromJson{file=self:getR(ui.FILE)}
		self._layer:addChild(self._item)
		local path = update.getClassRootDirectory()
		if string.sub(path,-1) == '/' then
			path = string.sub(path,1,-2)
		end
		for file in lfs.dir(path) do
			if file=='.' or file=='..' then
			else
				table.insert(classids,file)
			end
		end
	end,
	release = function(self)
		
	end,
}