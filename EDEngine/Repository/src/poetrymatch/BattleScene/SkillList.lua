---
--SkillList.lua
--华夏诗魂中战斗技能的列表

--卢乐颜
--2014.12.29

local lly = require "poetrymatch/BattleScene/llyLuaBase2"

lly.finalizeCurrentEnvironment()

--技能类型
local SKILL_TYPE = {
	DIRECT = 1, --直接技能，点击后立即生效
	FIGHTING = 2, --战斗技能，战斗时生效
}

--技能目标
local SKILL_AIM = {
	SELF = 1, --对自己释放
	ENEMY = 2, --对敌人释放
}

--技能的结构体
local StruSkill = lly.struct(function ()
	return {
		strName = "",
		nID = 0,
		eType = SKILL_TYPE.DIRECT,
		eAim = SKILL_AIM.SELF,
		strAnim_init = "", --点击技能后直接展示的动画
		strAnim_beforeAttack = "", --攻击前动画 不是每个技能都有
		strAnim_attack = "", --攻击时的动画 不是每个技能都有
		strAnim_effect = "", --效果动画

		--构造函数
		ctor = function (self, str, id, type, aim, str1, str2, str3, str4)
			self.strName = str
			self.nID = id
			self.eType = type
			self.eAim = aim
			self.strAnim_init = str1
			self.strAnim_beforeAttack = str2
			self.strAnim_attack = str3
			self.strAnim_effect = str4

			return self
		end
	}
end)

local strNormalAtk = "pt2"
local strNormalAtkEnd = "pt3"

local SKILL = lly.const{
	[1001] = StruSkill:create():ctor("轩辕甲", 1001, SKILL_TYPE.FIGHTING, SKILL_AIM.SELF, "xuanyj1", "", "", "xuanyj3"),
	[1002] = StruSkill:create():ctor("雷火剑", 1002, SKILL_TYPE.FIGHTING, SKILL_AIM.ENEMY, "leihj1", "", "leihj2", "leihj3"),
	[1003] = StruSkill:create():ctor("益血丹", 1003, SKILL_TYPE.DIRECT, SKILL_AIM.SELF, "yixd1", "", "", "yixd3"),
	[1004] = StruSkill:create():ctor("血灵盾", 1004, SKILL_TYPE.FIGHTING, SKILL_AIM.SELF, "xueld1", "", "", "xueld3"),
	[1005] = StruSkill:create():ctor("穿云剑", 1005, SKILL_TYPE.FIGHTING, SKILL_AIM.ENEMY, "chuanyj1", "", "chuanyj2", "chuanyj3"),
	[1006] = StruSkill:create():ctor("百年好酒", 1006, SKILL_TYPE.DIRECT, SKILL_AIM.ENEMY, "bainhj1", "", "", "bainhj3"),
	[1007] = StruSkill:create():ctor("迷雾幻境", 1007, SKILL_TYPE.DIRECT, SKILL_AIM.ENEMY, "miwhj1", "", "", "miwhj3"),
	[1008] = StruSkill:create():ctor("天界慧眼", 1008, SKILL_TYPE.DIRECT, SKILL_AIM.SELF, "tianjhy1", "", "", "tianjhy3"),
	[1009] = StruSkill:create():ctor("破障灵光", 1009, SKILL_TYPE.DIRECT, SKILL_AIM.SELF, "pozlg1", "", "", "pozlgj3"),
	[1010] = StruSkill:create():ctor("软骨散", 1010, SKILL_TYPE.FIGHTING, SKILL_AIM.ENEMY, "ruangs1", "ruangs3", "", ""),

}


return {
	SKILL = SKILL,
	TYPE = SKILL_TYPE,
	AIM = SKILL_TYPE,
	ATK = strNormalAtk,
	ATK_END = strNormalAtkEnd,
}