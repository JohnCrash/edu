local test_login = 
{
--[[
	[1] = {name='鲍老师',uid = 122097,cookie='sc1=15FD5FCCC97D38082490F38E277704C30C6CD6BAak99MgjoBYOcgHtZIUFvvkV%2fYgutNRji5EzUh8LI5lYpG0jPwGdmMTS%2bqA%2bQqkfvEeP2mYgfxGLd03oZpHpbaewlwrbp3A%3d%3d'},
	[2] = {name='杨朝来',uid = 125907,cookie='sc1=5B6A71FC333621695A285AC22CEDBF378D849D96ak96OwHoBYOcj3sCd0E24kV%2fbAusZhjjsUzUhMKTulZwFkjPwGhmamK%2b8VOQqknvELD2mN0fxGHdiCYZ%2fXdbaewnwrbp3A%3d%3d'},
	[3] = {name='姜平',uid = 122071,cookie='sc1=DD2D59DA4C4B01E5EBDA8BE5300968DF3EEDE5FBak99MgbuBYOcgXsCIUFvuEV%2fbwv3PBi45lKU19%2bP50E0GxHPwGtmMT%2b%2b8liO%2fkT7EuHjkQ%3d%3d'},
	[4] = {name='唐灿华',uid = 122067,cookie='sc1=171DA28BCFA4E5B05CE637AAB909E772360910FFak99MgfoBYOcjHsCJ0Fu6kV%2fbQutNBi4s0zUh8KSulYpRkjPwGtmajK%2bqVuQqkjvEeL2w98fxGLdiSYZpCdbaewnwrbp3A%3d%3'},
	[5] = {name='赵小雪',uid = 122068,cookie='sc1=1ABBC23D33E46E8C97D0C35D087248F3D999015Eak99MgfnBYOcgXtZJkE170V%2fbwv3NRjis0zUi8KTvFZwQkjPwGZmMTO%2b8l6QqkrvS%2bP2md8fxG7diCAZ%2fSNbaewnwrbp3A%3d%3d'},
	--]]
	--[1] = {name='刘亮',uid=145884,cookie='sc1=504C02F67C4CD5CDC30F16C4A8270BBC6D3079F0akl6OgnrBd%2bY1zlZegowowUjbRWwYAv%2f7A2U09%2bPu0Q0G0HPx21mNjK%2b8lOQ9h7xGOjimok%3d'},
	--[1] = {name='杨炳业',uid=146551,cookie='sc1=CEA85BC1D4187130336F24CB4619C8F62A195974akl5NwTuBd%2bY1zlZegowowUsYhWwYAv%2f7A2U09%2bPu0Q0G0HPx21mNjK%2b8lOQ9h7xGOjimok%3d'},
	--[1] = {name='王飞飞',uid=149535,cookie='sc1=DD9040950CA7F9CE1E9859B589F4FC4D32A05AE9akl2NwLqBdGY1zlddg0xvwkraBWwYAr%2f7QyUioWPu0o0QkDPnDtmNj%2b%2b8ViQ9hrxGOjimok%3d'},
	--[4] = {name='刘亮',uid=145832,cookie='4EEF85ADD04B10E062B563C13C4F8E0AFC5318D5akl6OgLtBcqQzDJScgow7VUhf0ugIAXi8FCJl4Ke%2bxFwBhKPnm94Yj2r'},
	--[2] = {name='张老师',uid=145487,cookie='sc1=B985BAC54D6A2322811266BD3A74BEFD1391BB39akl6NgnoBZfKi2oLKlJh7FEtYQvwMBi4tkzQgsLP5lYpE1bSlHsmZiP5qE6N90T7EuDokQ%3d%3d'},
	[2] = {name='陈玉莹',uid=149527,cookie='sc1=6A133D1AD29C83E6ACEF87727B156F446348F977akl2NwPoBZfKi24LI1Rn6lAoYQvwPBjj7EyJisLP6VYpRlbSnHsmayOj9U7X9kT7EuDok4kK'},
	[1] = {name='张老师',uid=145487,cookie='sc1=B985BAC54D6A2322811266BD3A74BEFD1391BB39akl6NgnoBZfKi2oLKlJh7FEtYQvwMBi4tkzQgsLP5lYpE1bSlHsmZiP5qE6N90T7EuDokQ%3d%3d'},
--	[4] = {name="赵颖",uid=146608,cookie='sc1=1751B59A5C03746874CE4817043C233BE282BEEBakl5NAHnBdyR2DFCegow4UV%2fYgv3MBi44EzUi8LL7FYoFUjbnm94Yw%3d%3d'}
	[3] = {name='王飞飞家长',uid=149537,cookie='sc1=ACAF0B81E7028AF0F9DCE904745F895E220F6FCDakl2NwLoBZfKi24LI1Rn6lAjYQvwMhjisEyJ0MLP51ZwEFbTwHsmaiP6o06MqlqvHPayxJxYl3KdiGcFqWcCPuwnwrbi3A%3d%3d'},
	[4] = {name='王飞飞',uid=149535,cookie='sc1=DD9040950CA7F9CE1E9859B589F4FC4D32A05AE9akl2NwLqBdGY1zlddg0xvwkraBWwYAr%2f7QyUioWPu0o0QkDPnDtmNj%2b%2b8ViQ9hrxGOjimok%3d'},
	[5] = {name='曹珀笙',uid=280889,cookie='sc1=1F23B4F9E58326D0704F6CCE435CCA0706B4AF50aUV%2fOgnmBdWNi24CJlJs%2fwUsfxf3IF%2fj8AyGl9%2fM%2b0shBhbdgD8gdj%2biq1qO%2fkT6'},
	[6] = {name='李洪',uid=144975,cookie='sc1=7BC33223C36F1B2EB26E310E5AE65F6FCE084DDFakl7OwbqBZfKj2YIIVRn6VkiYQvwMxjjsUyJ18LP6FZzF1aLxGVyaDWgoA%3d%3d'},
	[8] = {name='李洪家长',uid=145823,cookie='sc1=A77088A25A39273F195F916CCD787CD457AFFDE4akl6OgPsBcqQ0TFVdFNi4UV%2fbAusYRjisEzUhMLI6lZwQkjbnm94Yw%3d%3d'},	
	[7] = {name='张瑜',uid=591892,cookie='sc1=50979108ED86EB3240235BF4366282FD9394E9AFbkR%2bOgjtBZfBj28JIlVu71UqYQvwMBi4tkzQgsLP6VYpFFbTkHsmZSP69k6Nq1qvHfaxwJxYk2zJinAHrnJQ'},	
	[9] = {name='张雨',uid=446947,cookie='sc1=891CB859C1E8266CDBCCF35A92DB784C0B21B4C7b0l5OwXoBZfKjWgNIFBi6lgpYQvwMBi4tkzQgsLP51YoQVaLnWVyaDWgoluF'},	
	--[7] = {name='张瑜',uid=145948,cookie='sc1=E2DBA2CED31E252E7924D016E976CD26934FED47akl6OwXnBZfKgG8LK1du6VcvYQvwMhji40yJ08LP51ZzQVbSwHsmZiOj8k6N%2bET7EuLimok%3d'},	
	--[7] = {name='张瑜',uid=303626,cookie='sc1=FA606D2AD4ACEA55353B6C9068E70CF266212F84aE18NAPpBZfKjGwKJlJk6lQqYQvwPBi4t0yJhsLP61ZzQFaIxGVyaDWgoluF'},	
	[10] = {name='刘文文',uid=13830000001,cookie='sc1=B8CCE023FD4A5F6BBE407B997F18B573055C2836b094NADuBZfKgW0LI1Rn6lArYQvwMBji7UyIisLP6FYoFVbSknsmZSOipk6N%2bET7Eufok4kKmjLJgSNY%2f3FZbO50mLHgjeyC9gYFKlYOzjSDdPYG4XIV'},
	[11] = {name='秦胜兵',uid=454652,cookie='sc1=836C111ECBEAA14DDAB56D47991743E92F98BED7b0h7NATtBdeQ1y1TdgowuAl0PRmjPhi%2f4kzQhcLL6FZ0G1bSlnt6MCP%2bpU6N%2blqoHOjimo0Bk2fIiicNrCMEO%2bQvzb27jbvZ8lFRKlMNnGKEc%2fYM6SdISj70'},
	[12] = {name='五五',uid=955470,cookie='sc1=16ECA3EFA5BC76F12324027CB0AEF13592EF358CYkh6NgbvBdXIimoKIVdj61IrbxWwYAn%2ftwiUi9OPu0c0QRLPnGp4Yj2qq1uOqk76SLewkoAOmDWZhHtd%2fiAFbeFzybHuirzQ9QsLfAM%3d'},
}

local selector = 2
local g_cookie
local g_uid
local s_app,s_cookie,s_uid = cc_launchparam()
local TEACHER = 3
local STUDENT = 1
local PARENT = 2

local g_uidtype = nil
local g_subid = nil

if s_cookie and type(s_cookie)=='string' and string.len(s_cookie)>1 then
	g_cookie = s_cookie
end
if s_uid and type(s_uid)=='string' and string.len(s_uid)>1 then
	g_uid = s_uid
end

local function set_cookie( cookie )
	g_cookie = cookie
end

local function set_userid( uid )
	g_uid = uid
end

local function get_uid_type()
	if not g_uidtype then
		local kits = require "kits"
		local json = require "json-c"
		local url = "http://api.lejiaolexue.com/rest/userinfo/simple/current"
		local result = kits.http_get( url,g_cookie )
		if result then
			local t  = json.decode( result )
			if t and type(t) == 'table' then
				if t.result == 0 then
					if t.uig and type(t.uig)=='table' and t.uig[1] and t.uig[1].user_role then
						g_uidtype =  t.uig[1].user_role
					else
						kits.log("ERROR: login get_uid_type invalid result")
					end
				else
					kits.log("ERROR: login get_uid_type invalid result ("..tostring(t.msg))
				end
			else
				kits.log("ERROR:login get_uid_type decode failed!")
			end
		else
			kits.log("ERROR: login get_uid_type http_get return nil")
		end
	end
	return g_uidtype
end

local function set_uid_type( t )
	g_uidtype = t
end

local function set_subuid( t )
	g_subid = t
end

local function get_subuid()
	return g_subid
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
	TEACHER = TEACHER,
	STUDENT = STUDENT,
	PARENT = PARENT,
	get_uid_type = get_uid_type,
	set_uid_type = set_uid_type,
	set_subuid = set_subuid,
	get_subuid = get_subuid,
}