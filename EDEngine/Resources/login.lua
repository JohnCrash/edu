local kits = require 'kits'

local cookie_bao = 'sc1=15FD5FCCC97D38082490F38E277704C30C6CD6BAak99MgjoBYOcgHtZIUFvvkV%2fYgutNRji5EzUh8LI5lYpG0jPwGdmMTS%2bqA%2bQqkfvEeP2mYgfxGLd03oZpHpbaewlwrbp3A%3d%3d'
local cookie_student = 'sc1=5B6A71FC333621695A285AC22CEDBF378D849D96ak96OwHoBYOcj3sCd0E24kV%2fbAusZhjjsUzUhMKTulZwFkjPwGhmamK%2b8VOQqknvELD2mN0fxGHdiCYZ%2fXdbaewnwrbp3A%3d%3d'
local uid_student = 122097
local function get_cookie()
	return cookie_student
end

local function get_uid()
	return uid_student
end

local logo_url = 'http://image.lejiaolexue.com/ulogo/'

--返回logo cache文件名
--如果不存在则先下载
local function get_logo( uid )
	local seg1 = math.floor(uid/10000)%100
	local seg2 = math.floor(uid/100)%100
	local logo_type = 2 --50x50
	return logo_url..tostring(seg1)..'/'..tostring(seg2)..'/'..tostring(uid)..'_'..logo_type..'.jpg'
end

return {
	cookie = get_cookie,
	uid = get_uid,
	get_logo = get_logo,
}