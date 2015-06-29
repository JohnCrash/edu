local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"

local ui = {
	FILE = 'calc/zhujiemian_1.json',
	FILE_3_4 = 'calc/zhujiemian_1.json',
	PROGREloading = "jindu",
	designWidth = 1080,
	designHeight = 1920,	
}

local loading = uikits.SceneClaloading("loading",ui)

function loading:init()
end

function loading:release()
end

return loading