local kits = require "kits"
local uikits = require "uikits"
local json = require "json-c"
local lfs = require "lfs"
local ljshell = require "ljshell"
local base = require "base"
local update = require "update_factory"
local factory = require "factory"
local FileUtils = cc.FileUtils:getInstance()

local ui={
	FILE = 'res/splash_6.json',
	ICON = 'Image_1',
	REFRESH = 'res/splash/refresh.png',
	NAME = 'Label_2',
	COMMENT = 'Label_3',
	UUID = 'Label_4',
}

local classids = {}
local classes = {}
local root = {}
local list = {}
local items = {}

return {
	init = function(self)
		self:initDesignView(1024*2,576*2)
		if not self._scroll then
			self._item = uikits.fromJson{file=self:getR(ui.FILE)}
			local size = uikits.getDR()
			self._scroll = uikits.scrollview{x=0,y=0,anchorX=0,anchorY=0,
			width=size.width-16,height=size.height,
			bgcolor=cc.c3b(64,64,64)
			}
			self:addChild(self._scroll)
			self._scroll:addChild(self._item)
			self._item:setVisible(false)
			self:initRefresh()
		end
		if #list == 0 then
			self:initClasses()
		else
			local inner = self._scroll:getInnerContainer()	
			inner:setPosition(cc.p(self._scrollx,self._scrolly))
		end
	end,
	release=function(self)
		--保存滚动位置
		local inner = self._scroll:getInnerContainer()
		self._scrollx,self._scrolly = inner:getPosition()
	end,
	initRefresh=function(self)
		local size = uikits.getDR()
		self._sprite = uikits.button{x=size.width-128,y=size.height-128,width=128,height=128,
		anchorX=0.5,anchorY=0.5}
		self._sprite:loadTextures(self:getR(ui.REFRESH),self:getR(ui.REFRESH))
		self:addChild(self._sprite,2)
		uikits.event(self._sprite,function(sender)
			local actionTo2 = cc.RotateTo:create( 0.2, 360)
			local actionTo = cc.RotateTo:create( 0.2, 180)	
			self._sprite:runAction(cc.Sequence:create(
			actionTo,actionTo2))
			classids = {}
			classes = {}
			root = {}
			list = {}
			for i,v in pairs(items) do
				v:removeFromParent()
			end
			items = {}
			self:initClasses()
		end,"click")
	end,
	getClassRootDirectory = function(self)
		if cc_isdebug() then
			return cc.FileUtils:getInstance():getWritablePath()..'class/'
		else
			return ljshell.getDirectory(ljshell.AppDir)..'class/'
		end	
	end,
	loadClassJson = function( self,classId,jsonFile )
		local df = self:getClassRootDirectory()..classId..'/'..tostring(jsonFile)
		local file = io.open( df,"rb" )
		if file then
			local all = file:read("*a")
			file:close()
			local destable = json.decode( all )
			if destable.superid and type(destable.superid)=='string' and
				string.len(destable.superid)~=32 then
				if base[destable.superid] then
					destable.superid = base[destable.superid]
				end
			end
			if destable.pedigree and type(destable.pedigree)=='table' then
				for i,v in pairs(destable.pedigree) do
					if string.len(v)~=32 then
						if base[v] then
							destable.pedigree[i] = base[v] 
						end
					end
				end
			end			
			return destable
		end
	end,
	initClasses = function(self)
		local path = self:getClassRootDirectory()
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
		local scheduler = self:ccScene():getScheduler()
		local schedulerId
		local idx = 0
		local count = #classids
		local progressBox = factory.create(base.ProgressBox)
		progressBox:open()			
		local function spin()
			idx = idx+1
			if idx<=count then
				progressBox:setProgress(idx/count)
				local cls = factory.getClass(classids[idx])
				if not cls then
					cls = self:loadClassJson(classids[idx],'desc.json')
					if not cls then
						kits.log("ERROR can not load "..tostring(classids[idx])..'/desc.json')
					end
				end
				local isbase = false
				for i,v in pairs(base) do
					if classids[idx]==v then
						isbase = true
						break
					end
				end
				if cls then
					classes[classids[idx]] = {id=classids[idx],child={},cls=cls,isbase=isbase}
				end
			elseif idx==count+1 then
				progressBox:setProgress(1)
			else
				--组织为树状结构
				for i,v in pairs(classes) do
					if v.cls.superid and classes[v.cls.superid] then
						table.insert(classes[v.cls.superid].child,i)
					else
						table.insert(root,i)
					end
				end
				--组织为一个列表结构
				local line
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
					line = {level=1,child={}}
					enum(v,1)
				end
				table.insert(list,line)
				--打印层次
				progressBox:close()
				scheduler:unscheduleScriptEntry(schedulerId)				
				self:print()
				self:layout()
				local ss = self._scroll:getContentSize()
				self._scrollbar = factory.create(base.ScrollBar)
				self._scrollbar:setSize(cc.size(16,ss.height))
				self._scrollbar:setPosition(cc.p(ss.width,0))
				self:addChild(self._scrollbar)
				self._scrollbar:trackScrollView(self._scroll)
				--uikits.enableMouseWheelIFWindows(self._scroll,200)				
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
				table.insert(items,item)
				item:setVisible(true)
				item:setPosition(cc.p(x,y))
				x = x+size.width
				local name = uikits.child(item,ui.NAME)
				name:setString(classes[s].cls.name or '')
				name:setFontName("simhei")
				item:setBackGroundColorType(LAYOUT_COLOR_SOLID)
				if classes[s].isbase then
					item:setBackGroundColor(cc.c3b(128,32,0))			
				else
					item:setBackGroundColor(cc.c3b(16,96,0))							
				end
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
				uikits.event(item,function(sender)
					--[[
					local menu = factory.create(base.PopupMenu)
					menu:addItem("测试",function(sender)
						local obj = factory.createAsyn(s,function(obj)
							obj:test()
						end)						
					end)
					menu:addItem("创建子类",function(sender)
					end)
					menu:addItem("修改",function(sender)
					end)
					menu:addItem("删除",function(sender)
						local msgbox = factory.create(base.MessageBox)
						msgbox:open{caption="提示",text={"你确定要删除"..tostring(classes[s].cls.name)..'?','ID:'..s},
							button=2,
							onClick=function(i,text)
								if i==1 then
									print("删除")
								else
									print("取消")
								end
							end
						}					
					end)
					local p = sender:getTouchBeganPosition()
					menu:open(p)
					--]]
					local progressbox = factory.create(base.ProgressBox)
					factory.resetClass(s)
					local obj = factory.createAsyn(s,function(obj)
						progressbox:close()
						if obj then
							obj:test()
						else
							kits.log("ERROR factory.createAsyn("..s..") return nil")
						end
					end,function(d,txt)
						progressbox:setProgress(d)
						progressbox:setText(txt)
					end)
				end,"click")
				--[[
				uikits.event(item,function(sender)
					local obj = factory.createAsyn(s,function(obj)
						obj:test()
					end)
				end,"click")
				--]]
			end
		end
		local ss = self._scroll:getContentSize()
		self._scroll:setInnerContainerSize(cc.size(ss.width,h))
	end,
	test = function(self)
		print("you can not test searcher!")
	end
}