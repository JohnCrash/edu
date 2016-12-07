local uikits = require "uikits"
local kits = require "kits"
local ljshell = require "ljshell"
require  "ff"

local ui = {
	FILE = 'video/VideoPlayer_2.json',
	FILE_3_4 = 'video/VideoPlayer_2.json',
	designWidth = 1024,
	designHeight = 576,
	BACK = 'back',
	RECODER_BUTTON = 'record',
	LIVE_BUTTON = 'rtmp',
}

local recoder = uikits.SceneClass("recoder",ui)

function recoder:init(b)
	if b then
		local size = uikits.getDR()
		local video_param = self._arg.video
		local audio_param = self._arg.audio
		local back = uikits.child(self._root,ui.BACK)
		local recoder = uikits.child(self._root,ui.RECODER_BUTTON)
		local live = uikits.child(self._root,ui.LIVE_BUTTON)
		local liveFlag = live:clone()
		
		liveFlag:setVisible(false)
		liveFlag:setPosition(cc.p(size.width-64,size.height-64))
		self._root:addChild(liveFlag)
		
		local recordFlag = recoder:clone()
		
		recordFlag:setVisible(false)
		recordFlag:setPosition(cc.p(size.width-64,size.height-64))
		self._root:addChild(recordFlag)
		
		local isLiveing
		local isRecording
		
		uikits.event(recoder,function(sender)
			if isLiveing then return end
			if isRecording then
				isRecording = nil
				recordFlag:setVisible(false)
				cc_liveStop()
			else
				isRecording = 1
				local filename = ljshell.getDirectory(ljshell.AppDir).."/test.mp4"
				print("recode : "..filename)
				cc_liveStart
				{
					address=filename,
					live_w = video_param.max_w,
					live_h = video_param.max_h,
					live_fps = video_param.max_fps,
					video_bitrate=2560*1024,
					audio_bitrate=32*1024,
				}	
			end		
		end)
		uikits.event(live,function(sender)
			if isRecording then return end
			if isLiveing then
				isLiveing = nil
				liveFlag:setVisible(false)
				cc_liveStop()
			else
				isLiveing = 1
				cc_liveStart
				{
					address='rtmp://192.168.7.157/myapp/mystream',
					live_w = video_param.max_w,
					live_h = video_param.max_h,
					live_fps = video_param.max_fps,
					video_bitrate=256*1024,
					audio_bitrate=16*1024,
				}	
			end
		end)
		uikits.event(back,function(sender)
			cc_camclose()
			uikits.popScene()
		end)

		local campreivew = uikits.camPreview{width=size.width,height=size.height}
		self._root:addChild(campreivew)
		
		uikits.delay_call(campreivew,function(dt)
			local s = campreivew:getPreviewSize()
			if s.width > 0 and s.height > 0 then
				local w = s.width * size.height / s.height
				local x = (size.width - w)/2
				campreivew:setContentSize(cc.size(w,size.height))
				campreivew:setPosition(cc.p(x,0))
				return false
			end
			return true
		end,0.01)
		cc_liveSetCB(
			function(state,nframes,ntimes,encodeBufferSize,writerBufferSize,errors)
			if not errors then
				if isLiveing then
					local isv = liveFlag:isVisible()
					liveFlag:setVisible(not isv)
				end
				if isRecording then
					local isv = recordFlag:isVisible()
					recordFlag:setVisible(not isv)
				end
				
				print(string.format("%d - %d - %d",state,nframes,ntimes))
			else
				kits.logTable(errors)
			end
			return 0
		end)

		local b,errmsg = cc_camopen{
			cam_name=video_param.name,
			cam_w=video_param.max_w,
			cam_h=video_param.max_h,
			cam_fps = video_param.max_fps,
			pix_fmt=video_param.pix_format,
			
			phone_name=audio_param.name,
			sample_freq=audio_param.max_rate,
			sample_fmt='s16',
		}
		if not b then
			print("live failed: "..tostring(errmsg))
			uikits.popScene()
		end
		
		uikits.event(self._root,function(sender)cc_autofocus(true)end)
	end
end

function recoder:release()
	
end

return recoder