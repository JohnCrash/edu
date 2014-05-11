require "Cocos2d"

local local_dir = cc.FileUtils:getInstance():getWritablePath()

local function init_test_resource()
  local res = local_dir..'res/'
  local pfu = cc.FileUtils:getInstance()
  local size = cc.Director:getInstance():getVisibleSize()
  --[[
  pfu:addSearchPath(res)
  if 100 > 320 then
    pfu:addSearchPath(res..'hd')
    pfu:addSearchPath(res..'hd/Images')
    pfu:addSearchPath(res..'hd/scenetest/ArmatureComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/AttributeComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/BackgroundComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/EffectComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/LoadSceneEdtiorFileTest')
    pfu:addSearchPath(res..'hd/scenetest/ParticleComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/SpriteComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/TmxMapComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/UIComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/TriggerTest')
  else
    pfu:addSearchPath(res..'Images')
    pfu:addSearchPath(res..'scenetest/ArmatureComponentTest')
    pfu:addSearchPath(res..'scenetest/AttributeComponentTest')
    pfu:addSearchPath(res..'scenetest/BackgroundComponentTest')
    pfu:addSearchPath(res..'scenetest/EffectComponentTest')
    pfu:addSearchPath(res..'scenetest/LoadSceneEdtiorFileTest')
    pfu:addSearchPath(res..'scenetest/ParticleComponentTest')
    pfu:addSearchPath(res..'scenetest/SpriteComponentTest')
    pfu:addSearchPath(res..'scenetest/TmxMapComponentTest')
    pfu:addSearchPath(res..'scenetest/UIComponentTest')
    pfu:addSearchPath(res..'scenetest/TriggerTest')    
  end
  -]]
    pfu:addSearchPath(res..'hd')
    pfu:addSearchPath(res..'hd/Images')
    pfu:addSearchPath(res..'hd/scenetest/ArmatureComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/AttributeComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/BackgroundComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/EffectComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/LoadSceneEdtiorFileTest')
    pfu:addSearchPath(res..'hd/scenetest/ParticleComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/SpriteComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/TmxMapComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/UIComponentTest')
    pfu:addSearchPath(res..'hd/scenetest/TriggerTest')
    pfu:addSearchPath(res)
end


init_test_resource()
require "src/controller"