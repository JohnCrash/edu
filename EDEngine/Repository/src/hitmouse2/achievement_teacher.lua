local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/chengjiuLAO.json',
	FILE_3_4 = 'hitmouse2/chengjiuLAO43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	PLANE = 'gund',
	V1 = 'sul',
	V2 = 'cisu',
	V3 = 'jues',
	V4 = 'guanc',
	V5 = 'pingjun',
	V6 = 'zshi',
	V7 = 'pjshi',
	V8 = 'zjiang',
	V9 = 'pjjiang',
}

local _ming = "名"
local _chi = "次"
local achievement_teacher = uikits.SceneClass("achievement_teacher",ui)
function achievement_teacher:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		local plane = uikits.child(self._root,ui.PLANE)
		local send_data = {}
		kits.log("do achievement_teacher:init...")
		http.post_data(self._root,'teacher_award',send_data,function(t,v)
			if t and t==200 and v then
				http.logTable(v,1)
				if v.v1 then
					
					uikits.child(plane,ui.V1):setString((v.v1 or "-").._ming)
					uikits.child(plane,ui.V2):setString((v.v2 or "-").._chi)
					uikits.child(plane,ui.V3):setString((v.v3 or "-").._chi)
					uikits.child(plane,ui.V4):setString((v.v4 or "-").._chi)
					uikits.child(plane,ui.V5):setString((v.v5 or "-").._chi)
					uikits.child(plane,ui.V6):setString((v.v6 or "-"))
					uikits.child(plane,ui.V7):setString((v.v7 or "-"))
					uikits.child(plane,ui.V8):setString((v.v8 or "-"))
					uikits.child(plane,ui.V9):setString((v.v9 or "-"))
				else
					http.messagebox(self,http.DIY_MSG,function(s)
						uikits.exit()
					end,"teacher_award return invalid value")
				end
			else
				kits.log("ERROR teacher_award failed!")
			end
		end,true)	
		uikits.child(plane,ui.V1):setString("")
		uikits.child(plane,ui.V2):setString("")
		uikits.child(plane,ui.V3):setString("")
		uikits.child(plane,ui.V4):setString("")
		uikits.child(plane,ui.V5):setString("")
		uikits.child(plane,ui.V6):setString("")
		uikits.child(plane,ui.V7):setString("")
		uikits.child(plane,ui.V8):setString("")
		uikits.child(plane,ui.V9):setString("")
	end
end

function achievement_teacher:release()
end

return achievement_teacher