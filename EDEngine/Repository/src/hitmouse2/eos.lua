local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"
local login = require "login"
local level = require "hitmouse2/game"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/tianyan.json',
	FILE_3_4 = 'hitmouse2/tianyan43.json',
	designWidth = 1920,
	designHeight = 1080,
	BACK = 'ding/fan',
	LIST = 'lieb',
	ITEM = 'cy1',
	ITEM_BUT = 'an',
	PLANE = 'chengy',
	PLANE_PINGYIN = 'pingy',
	PLANE_IDIOM = 'chengy',
	PLANE_EXPLANATION_TITLE = 'w1',
	PLANE_EXPLANATION = 'shiy',
	PLANE_SOURCE_TITLE = 'w2',
	PLANE_SOURCE = 'chuc',
	PLANE_CHARACTER_TITLE = 'w3',
	PLANE_CHARACTER = 'renw',
	PLANE_STORY_TITLE = 'w4',
	PLANE_STORY = 'diangu',
}

local eos = uikits.SceneClass("eos",ui)

function eos:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			if not self._current then
				uikits.popScene()
			else
				self._plane:setVisible(false)
				self._scrollview._scrollview:setVisible(true)
				self._current = nil
			end
		end)
		self._plane = uikits.child(self._root,ui.PLANE)
		self._plane:setVisible(false)
		self._scrollview = uikits.scrollex(self._root,ui.LIST,{ui.ITEM})
		self._scrollview._scrollview:setVisible(true)
		if self._arg then
			self._data = level.get(self._arg)	
			for i,v in pairs(self._data.answers) do
				local item = self._scrollview:additem(1)
				local but = uikits.child(item,ui.ITEM_BUT)
				but:setTitleText(v.entry.idiom)
				uikits.event(but,function(sender)
					self._current = v.entry
					if not self._current.iseos then
						self:use_10_sliver()
					else
						self._plane:setVisible(true)
						self._scrollview._scrollview:setVisible(false)
						self:initPlane()						
					end
				end)
			end
		end
		if uikits.get_factor() == uikits.FACTOR_9_16 then
			self._scrollview:relayout_colume(7,30,12,64)
		else
			self._scrollview:relayout_colume(5,30,12,64)
		end
	end
end

function eos:use_10_sliver()
	local send_data = {v1=2,v2=10,v3="使用天眼"}
	http.post_data(self._root,'use_sliver_sp',send_data,function(t,v)
		if t and t == 200 and v then
			http.logTable(v,1)
			if v.v1 then
				if v.v3 then
					state.set_sliver(v.v3)
					state.set_sp(v.v4,v.v5,v.v6)
				end
				self._current.iseos = true
				if self._current then
					self._plane:setVisible(true)
					self._scrollview._scrollview:setVisible(false)
					self:initPlane()
				end			
			else
				http.messagebox(self._root,http.NO_SILVER,function(e)
				end,v)	
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e==http.RETRY then
					self:use_10_sliver()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end,true)		
end

function sn( s )
	if not s then return s end
	t = {}
	for i=1,10 do
		table.insert(t,s)
		table.insert(t,'\n')
	end
	
	return table.concat(t)
end

function getTextLabelObject( obj )
	return obj:getVirtualRenderer()
end

function setLabelDimensions( obj,w,h )
	local label = getTextLabelObject(obj)
	label:setDimensions( w,h )
end

function getLabelDimensions( obj )
	local label = getTextLabelObject(obj)
	return label:getDimensions()
end

function getSize( obj )
	local node = obj:getVirtualRenderer()
	local childs = node:getChildren()
	if childs then
		for _,sprite in pairs(childs) do
			local textrue = sprite:getTexture()
			return textrue:getContentSizeInPixels()
		end
	end
end

function calcTextStringHeight( obj )
	local ratios
	if CCApplication:getInstance():getTargetPlatform() == kTargetWindows then
		ratios = 1
	else
		ratios = 1.5
	end
	local size = obj:getContentSize()
	local str = obj:getString()
	local l = cc.utf8.length(str)
	local fontSize = obj:getFontSize()
	local lineHeight = fontSize*ratios
	local emptyLineNum = 0
	local idx = 0
	local lineCharNum = 0
	kits.log("width = "..tostring(size.width).."fontSize = "..tostring(fontSize))
	repeat
		local idx2 = cc.utf8.next(str,idx)
		if idx2 and idx2 < l then
			if string.sub(str,idx+1,idx+idx2) == '\n' then
				emptyLineNum = emptyLineNum+math.floor((lineCharNum*fontSize)/size.width)+1
				lineCharNum = 0
			else
				lineCharNum = lineCharNum+1
			end
		end
		idx = idx2 + idx
	until idx2==nil or idx2 >= l

	local height
	if emptyLineNum == 0 then
		kits.log("lineNum2 = "..tostring(math.floor((l*fontSize)/size.width)+1))
		height = (math.floor((l*fontSize)/size.width)+1)*lineHeight
	else
		kits.log("lineNum1 = "..tostring(emptyLineNum))
		height = emptyLineNum*lineHeight
	end
	obj:setContentSize( cc.size(size.width,height) )
	return height
end
			
function relayoutTextByHeight(t,lineSpace)
	local height
	local sc
	lineSpace = lineSpace or 0
	for _,v in pairs(t) do
		local height2
		for i,c in pairs(v) do
			local x,y = c:getPosition()
			if not sc then
				sc = c:getParent()
				if sc then
					sc = sc:getParent()
				end
			end
			y = height or y
			c:setPosition(cc.p(x,y))		
			if i == 1 then
				x,y = c:getPosition()
				height2 = y-(calcTextStringHeight(c)+lineSpace)
			end
		end
		height = height2
	end
	if sc and height < 0 then
		local inner = sc:getInnerContainer()
		local insize = inner:getContentSize()
		insize.height = insize.height-height
		sc:setInnerContainerSize(insize)
		local childes = inner:getChildren()
		for i,v in pairs(childes) do
			local x,y = v:getPosition()
			y=y-height
			v:setPosition(cc.p(x,y))
		end
	end
end

function eos:initPlane()
	local pingyin = uikits.child(self._plane,ui.PLANE_PINGYIN)
	local explanation = uikits.child(self._plane,ui.PLANE_EXPLANATION)
	local source = uikits.child(self._plane,ui.PLANE_SOURCE)
	local story = uikits.child(self._plane,ui.PLANE_STORY)
	
	uikits.child(self._plane,ui.PLANE_IDIOM):setString( self._current.idiom or "-" )
	
	explanation:setString(self._current.explanation or "-" )
	source:setString( self._current.memo or "-" )
	story:setString( self._current.story or "-" )		
	pingyin:setString( self._current.pingyin or "-" )
	
	local character = ""
	if self._current.character then
		for i,v in pairs(self._current.character) do
			if character == "" then
				character = v
			else
				character = character..","..v
			end
		end
	end
	local chara = uikits.child(self._plane,ui.PLANE_CHARACTER)
	chara:setString( character or "-" )
	
	t={}
	if string.len(self._current.explanation)==0 then
		explanation:setVisible(false)
		uikits.child(self._plane,ui.PLANE_EXPLANATION_TITLE):setVisible(false)
	else
		table.insert(t,{explanation,uikits.child(self._plane,ui.PLANE_EXPLANATION_TITLE)})
	end
	if string.len(self._current.memo)==0 then
		source:setVisible(false)
		uikits.child(self._plane,ui.PLANE_SOURCE_TITLE):setVisible(false)
	else
		table.insert(t,{source,uikits.child(self._plane,ui.PLANE_SOURCE_TITLE)})
	end

	if string.len(self._current.story)==0 then
		story:setVisible(false)	
		uikits.child(self._plane,ui.PLANE_STORY_TITLE):setVisible(false)
	else	
		table.insert(t,{story,uikits.child(self._plane,ui.PLANE_STORY_TITLE)})	
	end
	if string.len(character)==0 then
		chara:setVisible(false)	
		uikits.child(self._plane,ui.PLANE_CHARACTER_TITLE):setVisible(false)
	else
		table.insert(t,{chara,uikits.child(self._plane,ui.PLANE_CHARACTER_TITLE)})
	end
	relayoutTextByHeight(t,12)
end

function eos:release()
end

return eos