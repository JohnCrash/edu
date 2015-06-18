local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"

local ui = {
	FILE = 'ss/zhujiemian_1.json',
	FILE_3_4 = 'ss/zhujiemian_1.json',
	PROGRESS = "jindu",
}

local ss = uikits.SceneClass("ss")

function ss:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		self._ss = cc.size(1080,1920)
	else
		self._ss = cc.size(1080,1920)
	end
	uikits.initDR{width=self._ss.width,height=self._ss.height,mode=cc.ResolutionPolicy.EXACT_FIT}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
	end
end

function ss:release()
end

return ss