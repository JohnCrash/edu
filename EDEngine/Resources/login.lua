local test_login = 
{
--[[
	[1] = {name='鲍老师',uid = 122097,cookie='sc1=15FD5FCCC97D38082490F38E277704C30C6CD6BAak99MgjoBYOcgHtZIUFvvkV%2fYgutNRji5EzUh8LI5lYpG0jPwGdmMTS%2bqA%2bQqkfvEeP2mYgfxGLd03oZpHpbaewlwrbp3A%3d%3d'},
	[2] = {name='杨朝来',uid = 125907,cookie='sc1=5B6A71FC333621695A285AC22CEDBF378D849D96ak96OwHoBYOcj3sCd0E24kV%2fbAusZhjjsUzUhMKTulZwFkjPwGhmamK%2b8VOQqknvELD2mN0fxGHdiCYZ%2fXdbaewnwrbp3A%3d%3d'},
	[3] = {name='姜平',uid = 122071,cookie='sc1=DD2D59DA4C4B01E5EBDA8BE5300968DF3EEDE5FBak99MgbuBYOcgXsCIUFvuEV%2fbwv3PBi45lKU19%2bP50E0GxHPwGtmMT%2b%2b8liO%2fkT7EuHjkQ%3d%3d'},
	[4] = {name='唐灿华',uid = 122067,cookie='sc1=171DA28BCFA4E5B05CE637AAB909E772360910FFak99MgfoBYOcjHsCJ0Fu6kV%2fbQutNBi4s0zUh8KSulYpRkjPwGtmajK%2bqVuQqkjvEeL2w98fxGLdiSYZpCdbaewnwrbp3A%3d%3'},
	[5] = {name='赵小雪',uid = 122068,cookie='sc1=1ABBC23D33E46E8C97D0C35D087248F3D999015Eak99MgfnBYOcgXtZJkE170V%2fbwv3NRjis0zUi8KTvFZwQkjPwGZmMTO%2b8l6QqkrvS%2bP2md8fxG7diCAZ%2fSNbaewnwrbp3A%3d%3d'},
	--]]
	--[1] = {name='刘亮',uid=141770,cookie='sc1=D3F1DC81D98457FE8E1085CB4262CAAD5C443773akl%2bNQbvBYOcjHsDK0Fu4kV%2fbgv3ZBi7sFKU19KP5ks0GkvPwGpmMWe%2b8Q6O%2fkT7EuHjkQ%3d%3d'},
	[1] = {name='杨炳业',uid=146551,cookie='sc1=CEA85BC1D4187130336F24CB4619C8F62A195974akl5NwTuBd%2bY1zlZegowowUsYhWwYAv%2f7A2U09%2bPu0Q0G0HPx21mNjK%2b8lOQ9h7xGOjimok%3d'},
	[2] = {name='张老师',uid=145487,cookie='sc1=B985BAC54D6A2322811266BD3A74BEFD1391BB39akl6NgnoBZfKi2oLKlJh7FEtYQvwMBi4tkzQgsLP5lYpE1bSlHsmZiP5qE6N90T7EuDokQ%3d%3d'},
	[3] = {name='杨炳业家长',uid=146583,cookie='sc1=2AB5A8AD46D6A8E6989A12BB72A28F0702049650akl5NwnsBZfMiG4KI1Vi7FktYQvwMxjjsUzQisLP6VYpEVaIlnsmZyP5qE6MrlqvHPayxJxYl3KdiGcFqWcCPuwnwrbi3A%3d%3d'},
}
local selector = 2
local g_cookie
local g_uid

local function set_cookie( cookie )
	g_cookie = cookie
end

local function set_userid( uid )
	g_uid = uid
end

local function get_name()
	return test_login[selector].name
end

local function get_cookie()
	if g_cookie then
		return g_cookie
	else
		return test_login[selector].cookie
	end
end

local function get_uid()
	if g_uid then
		return g_uid
	else
		return test_login[selector].uid
	end
end

local logo_url = 'http://image.lejiaolexue.com/ulogo/'

local function set_selector(idx)
	selector = idx
	print('登陆用户:'..tostring(get_name()))
end
--返回logo cache文件名
--如果不存在则先下载
local function get_logo_url( uid,t )
	local seg1 = math.floor(uid/10000)%100
	local seg2 = math.floor(uid/100)%100
	local logo_type = 2 --50x50
	if t then
		if t > 2 then
			t = 99
		end
		logo_type = t
	end
	return logo_url..tostring(seg1)..'/'..tostring(seg2)..'/'..tostring(uid)..'_'..logo_type..'.jpg'
end

local cache
local kits
local logo_cache = {}
local function get_logo( uid,func,t )
	local url = get_logo_url( uid,t )
	if not cache then
		cache = require "cache"
		kits = require "kits"
	end
	if logo_cache[url] then
		local filename = cache.get_name(url)
		if kits.exist_cache(filename) then
			func( filename )
		else
			func()
		end
	else --确保第一次申请下载一次
		cache.request( url,function(b)
			if b then
				logo_cache[url] = true
				func( cache.get_name(url) )
			else
				func()
			end
		end)
	end
end

return {
	cookie = get_cookie,
	uid = get_uid,
	get_logo = get_logo,
	get_logo_url = get_logo_url,
	get_name = get_name,
	set_selector = set_selector,
	test_login = test_login,
	set_cookie = set_cookie,
	set_userid = set_userid,
}