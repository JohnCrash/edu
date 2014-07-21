local kits = require 'kits'

local test_login = 
{
	[1] = {name='鲍老师',uid = 122097,cookie='sc1=15FD5FCCC97D38082490F38E277704C30C6CD6BAak99MgjoBYOcgHtZIUFvvkV%2fYgutNRji5EzUh8LI5lYpG0jPwGdmMTS%2bqA%2bQqkfvEeP2mYgfxGLd03oZpHpbaewlwrbp3A%3d%3d'},
	[2] = {name='杨朝来',uid = 125907,cookie='sc1=5B6A71FC333621695A285AC22CEDBF378D849D96ak96OwHoBYOcj3sCd0E24kV%2fbAusZhjjsUzUhMKTulZwFkjPwGhmamK%2b8VOQqknvELD2mN0fxGHdiCYZ%2fXdbaewnwrbp3A%3d%3d'},
	[3] = {name='姜平',uid = 122071,cookie='sc1=DD2D59DA4C4B01E5EBDA8BE5300968DF3EEDE5FBak99MgbuBYOcgXsCIUFvuEV%2fbwv3PBi45lKU19%2bP50E0GxHPwGtmMT%2b%2b8liO%2fkT7EuHjkQ%3d%3d'},
	[4] = {name='唐灿华',uid = 122067,cookie='sc1=171DA28BCFA4E5B05CE637AAB909E772360910FFak99MgfoBYOcjHsCJ0Fu6kV%2fbQutNBi4s0zUh8KSulYpRkjPwGtmajK%2bqVuQqkjvEeL2w98fxGLdiSYZpCdbaewnwrbp3A%3d%3'},
	[5] = {name='赵小雪',uid = 122068,cookie='sc1=1ABBC23D33E46E8C97D0C35D087248F3D999015Eak99MgfnBYOcgXtZJkE170V%2fbwv3NRjis0zUi8KTvFZwQkjPwGZmMTO%2b8l6QqkrvS%2bP2md8fxG7diCAZ%2fSNbaewnwrbp3A%3d%3d'},
}
local selector = 2
local function get_cookie()
	return test_login[selector].cookie
end

local function get_uid()
	return test_login[selector].uid
end

local function get_name()
	return test_login[selector].name
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
	get_name = get_name,
}