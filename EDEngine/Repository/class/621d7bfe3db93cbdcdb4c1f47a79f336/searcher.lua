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
local classes = {}
local tree = {}
local list = {}

return {
	init = function(self)
		self._item = uikits.fromJson{file=self:getR(ui.FILE)}
		local size = uikits.getDR()
		self._scroll = uikits.scrollview{x=0,y=0,anchorX=0,anchorY=0,
		width=size.width,height=size.height,
		bgcolor=cc.c3b(200,200,200)
		}
		self:addChild(self._scroll)
		if #tree == 0 then
			self:initClasses()
		end
	end,
	initClasses = function(self)
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
		local scheduler = self:getLayer():getScheduler()
		local schedulerId
		local idx = 0
		local count = #classids
		local progressBox = factory.create(base.ProgressBox)
		progressBox:open()			
		local function spin()
			idx = idx+1
			if idx<count then
				progressBox:setProgress(idx/count)
				local cls = factory.getClass(classids[idx])
				if not cls then
					cls = update.loadClassJson(classids[idx],'desc.json')
					if not cls then
						kits.log("ERROR can not load "..tostring(classids[idx])..'/desc.json')
					end
				end
				table.insert(classes,cls)
			else
				--组织为树状结构
				for i,v in pairs(classes) do
					local pedigree = {}
					if v.pedigree and #v.pedigree>0 then
						for k=#v.pedigree,1,-1 do
							table.insert(pedigree,v.pedigree[k])
						end
					end
					if v.superid then
						table.insert(pedigree,v.superid)
					end
					for k,id in pairs(pedigree) do
					end
				end
				progressBox:close()
				scheduler:unscheduleScriptEntry(schedulerId)
			end
		end
		schedulerId = scheduler:scheduleScriptFunc(spin,0.01,false)	
	end,
	release = function(self)
		
	end,
}