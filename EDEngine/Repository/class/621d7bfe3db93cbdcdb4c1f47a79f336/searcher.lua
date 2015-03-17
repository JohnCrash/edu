local kits = require "kits"
local uikits = require "uikits"
local lfs = require "lfs"
local ljshell = require "ljshell"
local base = require "base"
local update = require "update_factory"
local factory = require "factory"

local ui={
	FILE = 'res/splash_6.json',
}

local classids = {}

return {
	init = function(self)
		self._item = uikits.fromJson{file=self:getR(ui.FILE)}
		self._layer:addChild(self._item)
		local path = update.getClassRootDirectory()
		for i,v in pairs(base) do
			if type(v)=='string' then
				table.insert(classids,v)
			end
		end		
		if string.sub(path,-1) == '/' then
			path = string.sub(path,1,-2)
		end
		for file in lfs.dir(path) do
			if file=='.' or file=='..' then
			else
				table.insert(classids,file)
			end
		end
		local scheduler = self._layer:getScheduler()
		local schedulerId
		local idx = 0
		local count = #classids
		local progressBox = factory.create(base.ProgressBox)
		progressBox:open()			
		local function spin()
			idx = idx+1
		
			if idx<count then
				progressBox:setProgress(idx/count)
				local cls = update.loadClassJson(classids[idx],'desc.json')
				if cls then
					print("name:"..tostring(cls.name))
					print("comment:"..tostring(cls.comment))
					print("icon:"..tostring(cls.icon))
				else
					kits.log("ERROR can not load "..tostring(classids[idx])..'/desc.json')
				end
			else
				progressBox:close()
				scheduler:unscheduleScriptEntry(schedulerId)
			end
		end
		schedulerId = scheduler:scheduleScriptFunc(spin,0.01,false)
	end,
	release = function(self)
		
	end,
}