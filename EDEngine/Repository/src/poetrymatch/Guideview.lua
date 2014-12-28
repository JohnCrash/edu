local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local Mainview = require "poetrymatch/Mainview"
local person_info = require "poetrymatch/Person_info"

local Guideview = class("Guideview")
Guideview.__index = Guideview
local ui = {
	Guideview_FILE = 'poetrymatch/kaipian.json',
	Guideview_FILE_3_4 = 'poetrymatch/kaipian.json',
	
	VIEW_USER = 'kaip/wo',
	PIC_USER_MAN  = 'kaip/wo/nan',
	PIC_USER_WOMAN  = 'kaip/wo/nv',
	BUTTON_USER_NEXT = 'kaip/wo/xyt',
	TXT_USER_NAME = 'kaip/wo/duihua/mz',
	TXT_USER_CONTENT = 'kaip/wo/duihua/dh',
	
	VIEW_NPC = 'kaip/daos',
	PIC_NPC  = 'kaip/daos/k2',
	BUTTON_NPC_NEXT = 'kaip/daos/xyt',
	TXT_NPC_NAME = 'kaip/daos/duihua/mz',
	TXT_NPC_CONTENT = 'kaip/daos/duihua/dh',	
	
	VIEW_MUTONG = 'mutong',
	BUTTON_MUTONG_OK = 'mutong/hui',
}

local talk_content = {
{id=0,data='拜见秦真人！'},
{id=1,data='嗯？找我这个臭道士有何事啊，我可从来不给人算命的，要算命出门左拐，山下的天桥上有一堆，童叟无欺、价格公道！'},
{id=0,data='秦真人，我可不是来算命的，听闻秦真人是当世最精通古诗词的高人，我从小就爱好诗词，特来拜师学艺的。'},
{id=1,data='哈哈哈，学诗，你是在开玩笑吧，诗词歌赋这种东西学来有何用，你有这么多空余时间，还是回家玩玩游戏得了，那才是正事儿，让你根本停不下来。'},
{id=0,data='您都一大把年纪了，不带这么逗人玩的。我像是那种自甘堕落的人么？那啥，这是我爷爷托我给您带的酒，他过60岁大寿时都没舍得拿出来喝！'},
{id=1,data='（秦真人打开酒闻一下。）哇，好酒，至少存了30年。对了，你爷爷是谁？'},
{id=0,data='我爷爷说，把这个玉佩给您看，你就知道了。（说完，将玉佩给了秦真人。）'},
{id=1,data='哦，明白了。可是你爷爷长得那么对不起人民群众，而你如此清秀，你不是亲生的吧！'},
{id=0,data='那啥，这话可不能乱说啊，会爆发战争的！我爷爷有心脏病，万一……'},
{id=1,data='唉呀，年轻人，我就随便说说嘛，瞧你还当真了，连个玩笑都开不起！'},
{id=0,data='啊！这事儿，也能开玩笑。秦真人，我是来拜师学艺的，我们先谈正事儿好不好！'},
{id=1,data='好吧，看在瓶好酒的份上，我们来说正事儿！（随后，秦真人不知从哪里拿出一颗黑漆漆的药丸放在前面。）'},
{id=0,data='什么个意思？'},
{id=1,data='这是一颗毒药，你先吃了它。吃了没死的话，我们再来谈学诗的事情！'},
{id=0,data='不是吧！你这是要谋财害命啊，我只是来学个诗而已，至于跟生命扯上关系吗？'},
{id=1,data='道家有云，朝闻道，夕可死。年轻人，绽放你的生命，才能懂得诗的真谛。'},
{id=0,data='我左看右看，都觉得你是一个骗子。打死我也不会吃这颗毒药的。'},
{id=1,data='那你走吧，以后也不要来烦我，回去跟你爷爷说，是你自己放弃的。（秦真人转身就要离开）'},
{id=0,data='等一下！我明白了，原来你是为了要赶我走。哼哼，这点小伎俩，我三岁就玩过了。这是毒药是吧，我猜是巧克力味儿的。（说完，拿起药丸就扔到了嘴里。）'},
{id=1,data='哟，你还真敢吃呀！'},
{id=0,data='我怕什么呀！这东西的味道怎么有点怪怪的。'},
{id=1,data='倒计时开始，三！'},
{id=0,data='什么个意思？怎么有点晕！'},
{id=1,data='二！'},
{id=0,data='难道真是毒药，我……（还没说完，晕倒在了秦真人前面。）'},
{id=1,data='倒下吧！唉，现在这年轻人，一点防范意识都没有，毒药都敢吃。（说完，手持结印放在胸前。）吾行一令，诸神有请，九天回梦，开！急急如律令！'},
{id=2,data='喂？你怎么了？醒醒！'},
{id=0,data='啊，让我再睡一会儿，今天是星期六，不上课！'},
{id=2,data='星期六是何节日？我只知道今天是端午节！'},
{id=0,data='啊！端午节，不可能呀。（说完，悠悠的张开了眼睛，看到牧童时，吓了一跳，立马睡意全无。）'},
{id=2,data='怎么不可能呀，等下在凤祥城外还要举办龙舟竞渡呢，全城的人都会去看！听说还从长安来了好些个才子呢？'},
{id=0,data='啊？你是谁？'},
{id=2,data='你说我呀，我是凤祥城员外郎张大人家的牧童，他们都叫我张小二。'},
{id=0,data='凤祥城？员外郎？这都什么跟什么呀？'},
{id=2,data='就知道你不知道，看你穿着如此奇异，想必是从关外来的吧！你可是我见到的第一个从关外来的人哦！'},
{id=0,data='关外？等等！我记得我是去拜见秦真人，然后……不会吧！这，这，这不科学啊！难道真的有穿越这回事儿？'},
{id=2,data='啊？你说什么？'},
{id=0,data='哈哈，哦。没事儿，你刚才说凤祥城外会举办什么龙舟竞渡，还从长安来了几个才子？'},
{id=2,data='是呀，听说有李白、杜甫、高适呢，真羡慕他们。小小年纪就已经成为名动一方的才子了，而我现在还在放牛呢。'},
{id=0,data='小小年纪？'},
{id=2,data='是呀，也就跟你年纪差不多。写诗，写得可好了。要是我能跟他们一块对诗就太棒了。'},
{id=0,data='啊？小时候的李白、杜甫？走，张小二，你带我去找他们，我们去找他们对诗！'},
{id=2,data='啊？不行啊！我现在要放牛！'},
{id=0,data='放什么牛啊，放牛有什么前途，放牛能成为一个才子吗？难道你不想见识一下李白、杜甫他们？'},
{id=2,data='不去！这牛要是丢了，张大人会扒了我的皮的！'},
{id=0,data='那你不去就算了，我一个人去！'},
{id=2,data='啊？你等一下，我也要去。'},
{id=0,data='你不放牛了？'},
{id=2,data='当然，不放了。但你要帮我，和我一块把牛牵回去，还得在路上把它给喂饱了。然后，我就带你去找李白、杜甫他们。'},
{id=0,data='好！小事一件，就这么说定了。'},

}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Guideview)		
	
	scene:addChild(cur_layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			cur_layer:init()
		elseif "exit" == event then			
			cur_layer:release()
		end
	end	
	cur_layer:registerScriptHandler(onNodeEvent)
	return scene	
end

function Guideview:show_talk()
	local view_user = uikits.child(self._Guideview,ui.VIEW_USER)
	local view_bot = uikits.child(self._Guideview,ui.VIEW_NPC)
	local txt_user_name = uikits.child(self._Guideview,ui.TXT_USER_NAME)
	local txt_bot_name = uikits.child(self._Guideview,ui.TXT_NPC_NAME)
	local txt_user_content = uikits.child(self._Guideview,ui.TXT_USER_CONTENT)
	local txt_bot_content = uikits.child(self._Guideview,ui.TXT_NPC_CONTENT)
	local but_user_next = uikits.child(self._Guideview,ui.BUTTON_USER_NEXT)
	local but_bot_next = uikits.child(self._Guideview,ui.BUTTON_NPC_NEXT)
	local pic_user_man = uikits.child(self._Guideview,ui.PIC_USER_MAN)
	local pic_user_woman = uikits.child(self._Guideview,ui.PIC_USER_WOMAN)
	local pic_bot_daos = uikits.child(self._Guideview,ui.PIC_NPC)
	local pic_bot_mut = pic_bot_daos:clone()
	view_bot:addChild(pic_bot_mut)
	self.user_info = person_info.get_user_info()
	txt_user_name:setString(self.user_info.name..'：')
	if self.user_info.sex == 1 then
		pic_user_man:setVisible(true)
		pic_user_woman:setVisible(false)
	else
		pic_user_man:setVisible(false)
		pic_user_woman:setVisible(true)	
	end
	person_info.load_card_pic(pic_bot_daos,'daos.png')
	person_info.load_card_pic(pic_bot_mut,'13.png')
	
	local content_index = 1
	
	local function turn_to_next()
		if content_index > #talk_content then
			local view_mutong = uikits.child(self._Guideview,ui.VIEW_MUTONG)
			local but_mutong_ok = uikits.child(self._Guideview,ui.BUTTON_MUTONG_OK)
			view_mutong:setVisible(true)
			uikits.event(but_mutong_ok,	
				function(sender,eventType)	
					local scene_next = Mainview.create()        
					cc.Director:getInstance():replaceScene(scene_next) 
				end,"click")
		end

		if talk_content[content_index].id == 0 then
			txt_user_content:setString(talk_content[content_index].data)
			view_user:setVisible(true)
			view_bot:setVisible(false)
		elseif talk_content[content_index].id == 1 then
			txt_bot_content:setString(talk_content[content_index].data)
			txt_bot_name:setString('秦真人：')
			pic_bot_daos:setVisible(true)
			pic_bot_mut:setVisible(false)
			view_user:setVisible(false)
			view_bot:setVisible(true)
		elseif talk_content[content_index].id == 2 then
			txt_bot_content:setString(talk_content[content_index].data)
			txt_bot_name:setString('牧童：')
			pic_bot_daos:setVisible(false)
			pic_bot_mut:setVisible(true)
			view_user:setVisible(false)
			view_bot:setVisible(true)
		end	
		content_index = content_index+1
	end
	
	uikits.event(but_user_next,	
		function(sender,eventType)	
			turn_to_next()
		end,"click")

	uikits.event(but_bot_next,	
		function(sender,eventType)	
			turn_to_next()
		end,"click")

	turn_to_next()		
end


function Guideview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Guideview = uikits.fromJson{file_9_16=ui.Guideview_FILE,file_3_4=ui.Guideview_FILE_3_4}
	self:addChild(self._Guideview)
	
	self:show_talk()
end

function Guideview:release()

end
return {
create = create,
}