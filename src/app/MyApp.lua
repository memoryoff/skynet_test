
require("config")
require("cocos.init")
require("framework.init")
require("pack")

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
end

function MyApp:run()
    cc.FileUtils:getInstance():addSearchPath("res/")
    cc.FileUtils:getInstance():addSearchPath("res/quick_sample/")
    cc.FileUtils:getInstance():addSearchPath("res/lecai/")
    -- self:enterScene("MainScene")
    self:enterScene("SceneLogin")
end

return MyApp
