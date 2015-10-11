local kits = require "kits"
local uikits = require "uikits"
local messagebox_ = require "messagebox"

local ui = {
	RECORD = 'luyinui/luyinui_1.json',
	OK = 'wc',
	TIME = 'jishi',
	VOLUME = 'jindu',
	RECORD_UI = 'ks',
	START_UI = 'qian',
	NUM = 'suzi',
}

local function messagebox(parent,title,text )
	messagebox_.open(parent,function()end,messagebox_.MESSAGE,tostring(title),tostring(text) )
end

local function open( parent,func )
	if not parent then return end
	if not cc_isobj(parent) then return end
	
	local _root = uikits.fromJson{file=ui.RECORD}
	
	if _root then
		_root:setAnchorPoint{x=0.5,y=0.5}
		local size
		if parent.getContentSize then
			size = parent:getContentSize()
		else
			size = uikits.getDR()
		end
		_root:setPosition{x=size.width/2,y=size.height/2}	
		parent:addChild(_root)
		local _record_ui = uikits.child(_root,ui.RECORD_UI)
		local _ok = uikits.child(_record_ui,ui.OK)
		local _time = uikits.child(_record_ui,ui.TIME)
		local _volume = uikits.child(_record_ui,ui.VOLUME)
		local _start_ui = uikits.child(_root,ui.START_UI)
		local _num = uikits.child(_start_ui,ui.NUM)
		local _scID = nil
		local _start_right = nil
		
		_record_ui:setVisible(false)
		_start_ui:setVisible(true)
		local scheduler = parent:getScheduler()
		local count = 1
		_num:setString( tostring(count) )
		
		if parent.setKeyboardEnabled then
			parent:setKeyboardEnabled(false)
		end
			
		local function start_record()
			uikits.event( _ok,function(sender)
				_root:setVisible(false)
				if parent.setKeyboardEnabled then
					parent:setKeyboardEnabled(true)
				end			
				if _scID then
					scheduler:unscheduleScriptEntry(_scID)
					_scID = nil
				end	
				if _start_right then
					local b,str = cc_stopRecordVoice()
					if not b then
						kits.log("ERROR RecordVoice false ")
						messagebox(parent,"错误","录音失败")
					end
					if func and type(func)=='function' then
						func(b,str)
					else
						kits.log("ERROR func = nil or invalid")
					end
				else
					kits.log("ERROR _start_right = false")
				end
				uikits.delay_call(parent,function()
					_root:removeFromParent()
				end,0)
			end)
			if cc_startRecordVoice() then
				_start_right = true
				_time:setString("0'")
				local function volume_func()
					local b,t,v = cc_getRecordVoiceInfo()
					if b then
						_time:setString(tostring(math.floor(t)).."'")
						v = 100*v/1024
						if v > 100 then
							v = 100
						end
						_volume:setPercent(v)
					else
						_time:setString('-')
					end
				end
				_scID = scheduler:scheduleScriptFunc( volume_func,0.1,false )
			else
				kits.log("ERROR cc_startRecordVoice return false")
				messagebox(parent,"错误","录音失败")
				if func and type(func)=='function' then
					func(false)
				end		
			end
		end
		
		local function num5()
			if count < 3 then
				count = count + 1
				_num:setString( tostring(count) )
			else
				scheduler:unscheduleScriptEntry(_scID)
				_scID = nil
				_record_ui:setVisible(true)
				_start_ui:setVisible(false)
				start_record()
			end
		end
		_scID = scheduler:scheduleScriptFunc( num5,1,false )
	else
		kits.log("ERROR can't found "..ui.RECORD )
	end
end

return 
{
	open = open,
}