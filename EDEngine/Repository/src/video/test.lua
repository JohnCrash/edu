local uikits = require "uikits"
local kits = require "kits"
local ljshell = require "ljshell"
require  "ff"

local ui = {
	FILE = 'video/VideoPlayer_1.json',
	FILE_3_4 = 'video/VideoPlayer_1.json',
	designWidth = 1024,
	designHeight = 576,
	BACK = 'Button_127',
	OPEN = 'opencam',
	DEVICES_LIST = 'devices',
	FORMATS_LIST = 'formats',
	DEVICES_ITEM = 'ITEM1',
	FORMATS_ITEM = 'ITEM2',
}

local video = uikits.SceneClass("video",ui)

function video:init(b)
	if b then
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,function(sender)
			cc_camclose()
			uikits.popScene()
		end)
		local openbut = uikits.child(self._root,ui.OPEN)
		local devices = uikits.scroll(self._root,ui.DEVICES_LIST,ui.DEVICES_ITEM)
		local formats = uikits.scroll(self._root,ui.FORMATS_LIST,ui.FORMATS_ITEM)
		local t = cc_camdevices()
		local video_select = uikits.child(self._root,'video_select')
		local audio_select = uikits.child(self._root,'audio_select')
		local video_param
		local audio_param
		local last_video_check
		local last_audio_check
		local default_name
		uikits.event(openbut,function(sender)
			if video_param then
				if not audio_param then
					audio_param = {
						name = default_name,
						max_rate = 22050,
					}
				end
				uikits.pushScene(require "video/recoder".create{video=video_param,audio=audio_param})
			end
		end)
		local function listFormats()
			last_video_check = nil
			last_audio_check = nil
			formats:clear()
			for i ,v in pairs(t) do
				if v.isSelected and v.capability then
					for k,s in pairs(v.capability) do
						local item = formats:additem()
						local text = uikits.child(item,'text')
						local check = uikits.child(item,'check')
						if v.type == 'video' then
							text:setString(string.format("%dx%d %s (%d-%d)",s.max_w,s.max_h,s.pix_format,s.min_fps,s.max_fps))
						elseif v.type == 'audio' then
							text:setString(string.format("%d %d %d %s",s.max_ch,s.max_rate,s.max_bit,s.sample_format))
						end
						if s.isSelected then
							check:setSelectedState(true)
						end
						uikits.event(check,function(sender)
							if check:getSelectedState() then
								s.isSelected = true
								if v.type == 'video' then
									video_param = s
									video_param.show_name = v.show_name
									video_param.name = v.name									
									video_select:setString(v.show_name.." - "..text:getString())
									
									if last_video_check then
										last_video_check:setSelectedState(false)
									end
									last_video_check = check
								else
									audio_param = s
									audio_param.show_name = v.show_name
									audio_param.name = v.name									
									audio_select:setString(v.show_name.." - "..text:getString())
									
									if last_audio_check then
										last_audio_check:setSelectedState(false)
									end
									last_audio_check = check									
								end								
							else
								if v.type == 'video' then
									video_param = nil
									video_select:setString('')
								else
									audio_param = nil
									audio_select:setString('')
								end
								s.isSelected = false
							end
						end)
					end
				end
			end
			formats:relayout()
			uikits.enableMouseWheelIFWindows(formats)
		end
		
		for i ,v in pairs(t) do
			local item = devices:additem()
			local text = uikits.child(item,'text')
			text:setString(v.show_name)
			if v.type == 'audio' then
				default_name = default_name or v.name
			end
			local check = uikits.child(item,'check')
			uikits.event(check,function(sender)
				if check:getSelectedState() then
					v.isSelected = true
				else
					v.isSelected = false
				end
				listFormats()
			end)
		end
		devices:relayout()
		
		uikits.event(uikits.child(self._root,'play'),function(sender)
			--uikits.pushScene(require "video/player".create{filename=ljshell.getDirectory(ljshell.AppDir).."/test.mp4"})
			uikits.pushScene(require "video/player".create{filename="http://videobjcdn.lejiaolexue.com/mts/571c1cba58e836256d5d3c16fa501a9aed30fb9d.m3u8"})
		end)
		uikits.event(uikits.child(self._root,'live'),function(sender)
			--uikits.pushScene(require "video/player".create{filename="rtmp://192.168.7.157/myapp/mystream"})
			uikits.pushScene(require "video/player".create{filename="rtmp://live.lexinedu.com/ljlxvideo/video1?auth_key=1481380257-0-0-b37a4e316c22076042b19b4469ca1b71"})
		end)		
	end
end

function video:release()
	uikits.enableMouseWheelIFWindows()
end

return video