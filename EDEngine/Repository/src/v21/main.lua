require "AudioEngine" 
local kits = require "kits"
local uikits = require "uikits"
local factory = require "factory"
local base = require "base"
local json = require "json-c"
local pubs = require "v21/pubserver"

local function messagebox(caption,text,button,func)
	local messageBox = factory.create(base.MessageBox)
	messageBox:open{caption=caption,text=text,onClick=func,button=button or 1}
end

local function loadingbox()
	local spinBox = factory.create(base.Spin)
	spinBox:open()
	return spinBox
end

local ui = {
	FILE = 'v21/MainUI_1.json',
	FILE_3_4 = 'v21/MainUI_1.json',
	BACK = 'exit',
	MAIN_PANEL='main',
	BUILD = 'build',
	CAPTION = 'name',
	SEARCH = 'search',
	START = 'start',
	INPUT = 'input',
	CLIST = 'chat_list',
	BUILD_PANEL = 'build_panel',
	GANE_NAME = 'gamename',
	OK = 'ok',
	CANCEL = 'cancel',
}

local main = uikits.SceneClass("main")
function main:stop_loading()
	if self._loading then
	self._loading:close()
	end
end

function main:init_ui()
	self.start:setVisible(false)
	self.input:setVisible(false)
	self.clist:setVisible(false)
	self.build_panel:setVisible(false)
end

function main:build_ui()
	self.start:setVisible(false)
	self.input:setVisible(false)
	self.clist:setVisible(false)
	self.build_panel:setVisible(true)
end

function main:search_ui()
	self.start:setVisible(false)
	self.input:setVisible(false)
	self.clist:setVisible(false)
	self.build_panel:setVisible(false)
end

function main:chat_ui()
	self.start:setVisible(false)
	self.input:setVisible(true)
	self.clist:setVisible(true)
	self.build_panel:setVisible(false)
	self.start:setVisible(true)
end

function main:game_ui()
end

function main:init(b)
	local function quit()
			messagebox("","确定要退出游戏吗？",2,
			function(e)
				if e==1 then
					self:stop_loading()
					uikits.delay_call( self._root,function(dt)
						kits.quit()
					end)
				end
			end)	
	end
	
	local function onKeyRelease(key,event)
		if key == cc.KeyCode.KEY_ESCAPE then
			quit()
		end
	end
	--uikits.pushKeyboardListener(onKeyRelease)
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		self._ss = cc.size(1024,576)
	else
		self._ss = cc.size(1024,576)
	end
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			quit()
		end)
	end
	self.start = uikits.child(self._root,ui.START)
	self.build = uikits.child(self._root,ui.BUILD)
	self.input = uikits.child(self._root,ui.INPUT)
	self.clist = uikits.child(self._root,ui.CLIST)
	self.build_panel = uikits.child(self._root,ui.BUILD_PANEL)
	self.build_ok = uikits.child(self.build_panel,ui.OK)
	self.build_cancel = uikits.child(self.build_panel,ui.CANCEL)
	self.search = uikits.child(self._root,ui.SEARCH)
	self.name = uikits.child(self._root,ui.CAPTION)
	uikits.event(self.build,function(sender)
		self:build_ui()
	end)
	uikits.event(self.build_ok,function(sender)
		local addr = pubs.pub(self.input:getStringValue()) 
		if addr then
			self.name:setString(addr)
			self:chat_ui()
		end
	end)	
	uikits.event(self.build_cancel,function(sender)
		self.build_panel:setVisible(false)
	end)		
	uikits.event(self.search,function(sender)
		if pubs.search(function(event,msg)
			self:stop_loading()
			if event=='recv' and msg then
				local t = json.decode(msg)
				self.name:setString(tostring(t.name).."["..tostring(t.address)..":"..tostring(t.port).."]")
				self:chat_ui()
			end
		end) then	
			self:search_ui()
			self._loading = loadingbox()
		end
	end)	
	self:init_ui()
end

function main:release()
	pubs.stop()
	self:stop_loading()
	--uikits.popKeyboardListener()
end

return main