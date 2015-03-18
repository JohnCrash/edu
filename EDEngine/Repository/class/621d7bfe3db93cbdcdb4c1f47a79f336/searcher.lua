local kits = require "kits"
local uikits = require "uikits"
local lfs = require "lfs"
local ljshell = require "ljshell"
local base = require "base"
local update = require "update_factory"
local factory = require "factory"
local FileUtils = cc.FileUtils:getInstance()

local ui={
	FILE = 'res/splash_6.json',
	ICON = 'Image_1',
	NAME = 'Label_2',
	COMMENT = 'Label_3',
	UUID = 'Label_4',
}

local classids = {}
local classes = {}
local root = {}
local list = {}

return {
	init = function(self)
		self._item = uikits.fromJson{file=self:getR(ui.FILE)}
		local size = uikits.getDR()
		self._scroll = uikits.scrollview{x=0,y=0,anchorX=0,anchorY=0,
		width=size.width,height=size.height,
		bgcolor=cc.c3b(64,64,64)
		}
		self:addChild(self._scroll)
		self._scroll:addChild(self._item)
		self._item:setVisible(false)
		if #classes == 0 then
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
				if cls then
					classes[classids[idx]] = {id=classids[idx],child={},cls=cls}
				end
			else
				--组织为树状结构
				for i,v in pairs(classes) do
					if v.cls.superid then
						table.insert(classes[v.cls.superid].child,i)
					else
						table.insert(root,i)
					end
				end
				--组织为一个列表结构
				local line = {level=1,child={}}
				local n_level
				local function enum(id,level)
					local this = classes[id]
					if this then
						if n_level<level then
							table.insert(line.child,id) 
						else
							table.insert(list,line)
							line = {level=level,child={}}
							table.insert(line.child,id)
						end
						n_level = level
					else
						kits.log("ERROR "..tostring(id).." is not exist")
					end
					for i,v in pairs(this.child) do
						enum(v,level+1)
					end
				end
				for i,v in pairs(root) do
					n_level = 0
					enum(v,1)
				end
				table.insert(list,line)
				--打印层次
				progressBox:close()
				scheduler:unscheduleScriptEntry(schedulerId)				
				self:print()
				self:layout()
			end
		end
		schedulerId = scheduler:scheduleScriptFunc(spin,0.01,false)	
	end,
	print = function(self)
		for i,v in pairs(list) do
			local str = ''
			for i=1,v.level do
				str = str..v.level..'\t'
			end
			for k,s in pairs(v.child) do
				str = str..'->'..tostring(classes[s].cls.name)
			end
			print(str)
		end				
	end,	
	layout = function(self)
		local size = self._item:getContentSize()
		local h = #list * size.height
		for i,v in pairs(list) do
			local y = h-size.height*i
			local x = (v.level-1)*size.width
			for k,s in pairs(v.child) do
				local item = self._item:clone()
				self._scroll:addChild(item)
				item:setVisible(true)
				item:setPosition(cc.p(x,y))
				x = x+size.width
				local name = uikits.child(item,ui.NAME)
				name:setString(classes[s].cls.name or '')
				name:setFontName("simhei")
				local comment = uikits.child(item,ui.COMMENT)
				comment:setString(classes[s].cls.comment or '')
				comment:setFontName("simhei")
				local uuid = uikits.child(item,ui.UUID)
				uuid:setString(s)
				uuid:setFontName("simhei")
				local img = uikits.child(item,ui.ICON)
				local imgFile = classes[s].cls.icon
				print(tostring(s)..' icon : '..tostring(imgFile))
				if imgFile and FileUtils:isFileExist(imgFile) then
					img:loadTexture(imgFile)
				elseif imgFile and FileUtils:isFileExist('class/'..s..'/'..imgFile) then
					img:loadTexture('class/'..s..'/'..imgFile)
				else
					print("not icon "..s)
				end
			end
		end
		local ss = self._scroll:getContentSize()
		self._scroll:setInnerContainerSize(cc.size(ss.width,h))
	end,
}