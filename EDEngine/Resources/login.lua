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
	[13] = {name='李四',uid=954175,cookie='sc1=04F4896F61A1FC64933FBA1A8D752EE862005833Ykh7MwbqBZfKjW8JIFBm6FMvYQvwMxjjsUyJ18LP61YoQVbTx2VyaDKgoFDQ%2fk%2brTbDgmI0DwzbNiCNe%2fidVbrImzLO%2f3r6GqwsAKg%3d%3d'},
	[14] = {name='六六',uid=955471,cookie='sc1=E21CF27FB6F841CE0FF2E3EA70B7C63629682360Ykh6NgbuBdXIimoKIVdj61IrbBWwYAj%2f7VyU04OPu0Y0G0bPxDp4Yj2qq1uOqk76SLewkoAOmDWZhHtd%2fiAFbeFzybHuirzQ9QsLfAM%3d'},
	[15] = {name='六六的哥哥',uid=1269209,cookie='sc1=6C405349AD6B13010489AA101B79BA1679945F62ak95OwPvB52KiG0PIlZk7lEoaxj0Phi%2f4EyJh8LLulZ0FlbSkHsiNyP%2bp06MrlryHfa2lJwDknKZhGdZqWdZa%2fJ3zL%2fo17%2fbowhWflZanTGCfaQHuyBFS2zzmmq7GzTKAs1I0d3kuFHnzA%3d%3d'},
	[16] = {name='六六母亲',uid=955473,cookie='sc1=87DE0078D583AF636F1245269116137C541E4873Ykh6NgbsBZfKjW8JIFBm6FEsYQvwMBji4EzQ1sLP61YpFlaLwXsmZSP69k6Nq1qvHfaxwJxYk2zJinAHrHkFaed3nefq1brZ8VIGdgdZmzeEcvUO7HYWQD33wDe9SA%3d%3d'},
	[17] = {name='55的家长',uid=955472,cookie='sc1=9DF20349B1B911407961DA6A0A7D074342E74288Ykh6NgbtBZfKjW8JIFBm6FEvYRugIFjt8FDQl9%2be%2bxYkBhKPgDx1dmOitVKA6h2sEuLok4IKmjLJgSNY/3FZbO50mLHgjeyC9gYFKlYOzjSDdPYG4XIV'},
	[18] = {name='额额',uid=955461,cookie='sc1=46E00D3D39E73B7C298ECEDC1F361202B2E59A3FYkh6NgfuBZfKjW8JIFBm6FEpYQvwPBi750yI1sLP51ZwEVbTwWVyaDWgoluF9Br7GbK3wooDlW6a0HcF%2fSACPeIgnLTs2%2bjSo1ULd1Ve'},
	[19]={name='杨艳波',uid=819133,cookie='sc1=EE2C9D0C490BD7F9416308E313F78D4BEC06881FY0x2MwLsBfXIimgCIlZl6FAuYxWwYAv%2f7A2U09%2bPu0s0G0rPx21mNjC%2b8liQrk3xGOjimokBxGbI0CZfr3tUYbV3zL24juyFpgVWf1MMn2CBIqgG6iQ%3d'},
	[20] = {name='张泳',uid=1261507,cookie='sc1=0F36DE9A59C5A8883A514FAB5303CDE48A26C4F7ak95MwTvCZ3IgWYKI1Vn61ArahWwYAj%2ftwqU09ePu0U0QUDPx214Yj2vq1mF%2f0SvGOOyxdoJmGPB0yMJpSMCOrIjz%2bHp2bmGoQNVd14InA%3d%3d'},
	[21] = {name='李四',uid=954175,cookie='sc1=04F4896F61A1FC64933FBA1A8D752EE862005833Ykh7MwbqBZfKjW8JIFBm6FMvYQvwMxjjsUyJ18LP61YoQVbTx2VyaDKgoFDQ%2fk%2brTbDgmI0DwzbNiCNe%2fidVbrImzLO%2f3r6GqwsAKg%3d%3d'},
	[22]={name="未来之星校长",uid=888384,"sc1=43463C32D6156F653894C5196C3D6665657DE05FY0V3MQnrBZDPj2gDK1xv7FYsYQvwMxjjtkzQ08LP6FYoR1aLkHsmZyP5qU6NrVqvH%2fbqmZwDx3Kdh2ddrGcBafJzwKHg2auC9QgCdFcKwmCBdKtb6HERFm6iwTu3TzDPDptMgYi3tgzknMRPfFqxwtyAtw%3d%3d"},
	[23] = {name='大小',uid=955540,cookie='sc1=38129CD33E8848C85065429DEFB7BCA0A3A1534EYkh6NwXvBZfKjW8JIFVm6FArYQvwMBi45UyJ1MLP61ZwF1aLkmVyaDeqq1mF%2f0SvGOOyxdoJmGPB0yMJpSMCOrIjz%2bHp2bmGoQNVd14InA%3d%3d'},	
	[24]={name='田老师',uid=1731762,cookie='sc1=51F2C4BD82BF6C5E25F0A9CCF4A2D3785D10BD02akp8MwbpDJ3IgWsKKlJv7lIiYxWwYAr%2f7F2U0NePu0s0G0PPnW9mNjO%2b8lOQ90fxGOjnmosKkWydgHJd%2bCFTYeMvm%2bXs1e%2bC8VYGeQMLzGXXdqBY4XlDFw%3d%3d'},
	[25]={name='李杰学生',uid=873174,cookie='sc1=B9737545CEA344F692AED907DF7E0E5AE3592A8FY0p8MwbrBdXIjGYKIlRg4lcraxWwYAv%2f7A2UioKPu0U0GhfPx25mNjO%2b8Q%2bQrknvTOT2mI0fmDHDgHkNp3JbPeYmmOC637fUqlFSel9amzDUcaZb6XRHFD%2bhnje2HjQ%3d'},
	[26]={name='王晓睿',uid=1814336,cookie='sc1=3BD24C3372B22113FDA29D06110A3DA6BAB0A1D5akV%2bNgLsCJ2KiG0CIFRn6lgvah%2buIFjt8FHUl9%2fI%2bxYnBkrTgGdwdmOstVLR6h2sEuLokIIKmjLJgSNY%2f3FZbO50mLHgjeyC9gYFKlYOzjSDdPYG4XIV'},
	[27]={name='吕雉',uid=1266530,cookie='sc1=F0CCB5D14F770B3CB9835B3EC3DABD8D23197388ak95NATsDp3IgWcLI1Rn6FIraxWwYAj%2f7FmUi9KPu0o0GhHPnWd4Yj2oq1mF%2f0SvGOOyxdoJmGPB0yMJpSMCOrIjz%2bHp2bmGoQNVd14InA%3d%3d'},
	[28] = {name='马桐浩',uid=264460,cookie='sc1=B462A233430A1DBA69F3180E9A2DEB9B2FEAE848aUt7NgfvBYOcgHtaKkE2uUV%2fbAv0NBjj5UzUhMLI61ZwGkjPwGdmMj%2b%2b8QiQqknvSOL2mIkfxGHd03cZ%2fXtbaewnwrbp3LXRoQAHelA%3d'},
	[29] = {name='刘亮',uid=145884,cookie='sc1=504C02F67C4CD5CDC30F16C4A8270BBC6D3079F0akl6OgnrBd%2bY1zlZegowowUjbRWwYAv%2f7A2U09%2bPu0Q0G0HPx21mNjK%2b8lOQ9h7xGOjimok%3d'},
	[30] = {name='张燕老师',uid=866447,cookie='sc1=BC2AB48DFAA575D3EFACFB0B7A958ACBE470E1BCY0t5NgXoBYOcjHtZcEE26kV%2fbQutMhjj4EzUisKS7lYpElaPkHshayOjqFCQqkrvS7D2wIkfxGDdiXUZpXdFPe8zwbT81L%2fF9gYWLV4ewWqKdasN4nNAQjagyjy6GGc%3d'},
	[31] = {name='云飞扬',uid=303626,cookie='sc1=42679B0C6F9D275FA5243A2F1ADEE0ECB10181B2aE18NAPpBZfKjGwKJlJk6lQqYQvwMRi4tEyIg8LP51ZwEFbTwHsmZSOjqU7UrET7EuDok4kKmjLJgSNY%2f3FZbO50mLHgjeyC9gYFKlYOzjSDdPYG4XIV'},
	[32] = {name='燕燕学生',uid=689017,cookie='sc1=E4F00F49E0CA458A10FEE131D96A20239ABE6A61bUV2MgDoBdXIgWgKIVVm41UvahWwYAr%2f7V6Ui9KPu0Q0G0TPnGtmNjO%2b8Q%2bQrknvTOT2mI0fmDHDgHkNp3JbPeYmmOC637fUqlFSel9amzDUcaZb6XRHFD%2bhnje2HjQ%3d'},
	[33] = {name='张燕老师八',uid=3195925,cookie='sc1=844656F0D96E3E47A7D9244DE1F57BBB000ADC00aEx2NwjtC53IjmcKJF1m7VkqYhWwYAj%2ftwqU09ePu0Q0G0TPnGtmNj6%2bqFuQ907vTOb2w4EfmW%2fd1HcZpHdFObUtyL%2fq177b9gIDLgJYymuFffJf7HgREG%2f0zTnrHWTNUcgehdW6sww%3d'},
	
	[34] = {name='张燕学生2',uid=2707001,cookie='sc1=FBA771E70EB7980CF1338D8BB5264E80A993A5F9aUp%2fNQHvD52KiGkDIlNv61ciahyuIFjv8AvSl4aa%2bxYmBkvdgGd2dmOutQrR6h78DLbkhIAOhG6eg3kNp3NbaOxzyLS4iO3TqgcKLQcOwDPTJvUL7yRARzr3yj%2foFWnJUg%3d%3d'},
	[35] = {name='胡老师',uid=324105,cookie='sc1=8C4A3D6819B3B0EAE00C414C17FDB561B2A2C0FAaE97MwHqBZfBiW8LIlFk41grYQvwPRji5kzQg8LP5lYpE1bSlHsmZiP5qE6N90T7EuLnmokBxGbI0CZfr3tUYbV3zL24juyFpgVWf1MMn2CBIqgG6iQ%3d'},
	[36] = {name='李杰',uid=873175,cookie='sc1=093B716C63D4B3DC602EA8BD257E0B49B6EABB1FY0p8MwbqBZfMgW8KI1Nv7VErYQvwMxjjsUyJ18LP6FYoR1aIlWVyaDepq1uOq0z7EOHqwNsDmGbNiXMK%2fiBUYeZ3m7K42bjVqlJVLQU%3d; XXID=3DC55FF8E759A9'},
	[37] = {name='刘',uid=145829,cookie='sc1=59E9FE42385DD9C8201BB049BDD64514BC2F3AAAakl6OgPmBcqQzDlOfAwis1cvYQvwMBji7UyIisLP61YoQVaIwXsmayP59U6N9kT7EuLokYJfkGeZ1SEPpXZZOrYjwOW7juvVpVYDelFdy2LXfKgNvA%3d%3d'},
	[38] = {name='李杰老师',uid=883188,cookie='sc1=BCABD1B97F00B65AFB5051976EB867F6EBE1E7AFY0V8MwnnBZfMgW8KI1Ji61crYQvwMxjjsUyJ18LP6FYoR1aIlXsmayOjoE6N%2flqvHPaxmZwCmWzJinEHrHkGPOBwyb293uzUpwsDLQIKzDGIc%2fMH6HMTRGmkyjq4Tw%3d%3d'},
	[39] = {name='家家父亲',uid=1267700,cookie='sc1=3E49FAB7A81A960646B969226C9B0821DBC715C4ak95NQbvDp3c3GsecgFyuFY%2fPxuwZFj%2ft1%2bU19CP5ks0QUXPwGpmMWe%2b8lmO6hr%2fDLK2hNsMhDLNlCNZuSBWfbIh3LzhyezWtlYHagRa3DCDf6EF63pCQj2qyT29GWTM'},
	[40] = {name='梁洁父亲',uid=1587825,cookie='sc1=B508023B3A3978A99859E7137B67E534D586F3A0akh3NQntC53IjG4NKldj7lQiaBWwYAv%2ftFuUitaPu0U0QUfPnW9mNjG%2bqFOQrUnvTOf2w9gfw2XDgHkOp3JbOrFywLbsiu%2fYpQMLewRfyWGBdPZavHYWFj2knGvqFGY%3d'},
}

local selector = 2
local g_cookie
local g_uid
local g_name
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
	if g_name then
		return g_name
	else
		if test_login[selector] then
			return test_login[selector].name
		else
			return ""
		end
	end
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
 
local function load_name()
	if not cache then
		cache = require "cache"
		kits = require "kits"
	end
	local url = 'http://api.lejiaolexue.com/rest/userinfo/full/current'
	cache.request_json( url,function(t)
		if t then
			g_name = t.uig[1].uname
			print("g_name = "..tostring(g_name))
		end
	end)
end

return {
	cookie = get_cookie,
	uid = get_uid,
	get_logo = get_logo,
	get_logo_url = get_logo_url,
	get_name = get_name,
	load_name = load_name,
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