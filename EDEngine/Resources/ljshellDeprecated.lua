local ljshell = require "ljshell"

ljshell.DataDir = 1
ljshell.ShareDir = 2
ljshell.LobbyDir = 3
ljshell.DownloadDir = 4
ljshell.AppDir = 5
ljshell.AppDataDir = 6
ljshell.AppTmpDir = 7
ljshell.UserDir = 8
ljshell.AppUserDir = 9
ljshell.IdNameFile = 10
ljshell.ShareSettingFile = 11
ljshell.UserSettingFile = 12
ljshell.LJDIR = 13

RESULT_OK = -1
RESULT_CANCEL = 0
RESULT_ERROR = -2
TAKE_PICTURE = 1
PICK_PICTURE = 2
BUY_ITEM = 100
--[[
]]--
if cc_clock then
	os.clock = cc_clock
end

ljshell.initApp("EDEngine")