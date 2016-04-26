require "Cocos2d"
local kits=require("kits")


local function main()
	--更新检测
	kits.isNeedUpade({"qwxt","topics","wuliu"},function(b)
		if b then
			require("qwxt/popup").msgBox({text="检测到一个新的版本，客户端软件需要更新！",title="温馨提示"},function(ok)
				kits.doUpdate({"qwxt","topics","wuliu"})
			end,true)
		end
	end)

	ccs.ArmatureDataManager:destroyInstance()
	--测试分辨率
	--cc.Director:getInstance():getOpenGLView():setFrameSize(1600,900)
	--cc.Director:getInstance():getOpenGLView():setFrameSize(1280,720)
	--cc.Director:getInstance():getOpenGLView():setFrameSize(1024,768)

	--随机种子
	math.randomseed(os.time())

	require "qwxt/globalSettings"
	local public=require("qwxt/public")

	--设计分辨率
	cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(globalSettings.designResolution.width,globalSettings.designResolution.height,cc.ResolutionPolicy.EXACT_FIT)

	--加载
	local shouyeScene=nil
	local loadingScene=public.showLoading(function()
		local function asyncLoad(list,loadFunction)
			local loadCount=0
			local loadNext=true
			while loadCount<#list do
				if loadNext then
					local fileName=list[loadCount+1]
					if cc.FileUtils:getInstance():isFileExist(fileName) then
						loadNext=false
						loadFunction(fileName,function(param)
							loadNext=true
							loadCount=loadCount+1
						end)
					else
						loadCount=loadCount+1
					end
				end
				coroutine.yield()
			end
		end

		--加载图片
		asyncLoad(
		{
			"qwxt/page_selected.png",
			"qwxt/page_normal.png",
			"qwxt/diyi.png",
			"qwxt/dier.png",
			"qwxt/disan.png",
			"qwxt/disi.png",
			"qwxt/loading2.png",
		},function(fileName,callback)
--			cc.Director:getInstance():getTextureCache():addImageAsync(fileName,callback)		lua不能使用addImageAsync
			cc.Director:getInstance():getTextureCache():addImage(fileName)
			callback()
		end)
		--加载动画
		asyncLoad(
		{
			"qwxt/animation/zuihou/zuihou.ExportJson",
			"qwxt/animation/mijing/mijing.ExportJson",
			"qwxt/animation/shuangbei/shuangbei.ExportJson",
			"qwxt/animation/liandui/liandui.ExportJson",
			"qwxt/animation/tanchu/tanchu.ExportJson",
			"qwxt/animation/baozang/baozang.ExportJson",
			"qwxt/animation/success/success.ExportJson",
		},function(fileName,callback)
			ccs.ArmatureDataManager:getInstance():addArmatureFileInfoAsync(fileName,callback)
		end)
		--加载音乐音效
--		asyncLoad(music.backgroundList,function(fileName,callback)
--			AudioEngine.preloadMusic(fileName)
--			callback()
--		end)
--		asyncLoad(music.zuotiList,function(fileName,callback)
--			AudioEngine.preloadMusic(fileName)
--			callback()
--		end)
		asyncLoad(music.effectList,function(fileName,callback)
			AudioEngine.preloadEffect(fileName)
			callback()
		end)
		--加载首页
		shouyeScene=public.createScene("shouye")
		shouyeScene:retain()
	end,function()
		--进入首页
		if cc.Director:getInstance():getRunningScene() then
			cc.Director:getInstance():popToRootScene()
			cc.Director:getInstance():replaceScene(shouyeScene)
		else
			cc.Director:getInstance():runWithScene(shouyeScene)
		end
		shouyeScene:release()
	end)

	return loadingScene;
end

return
{
	create=main
}
