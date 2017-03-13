--
-- Author: hxl
-- Date: 2017-03-06 16:39:06
--

local SceneLogin = class("SceneLogin",import(".ViewBase"))

SceneLogin.RESOURCE_FILENAME = "LogonView.json"   

local binding = { 
    btRegister = {varname = "btRegister",events = { {event = "touch",method = "register"} }} ,
    btLogon = {varname = "btLogon",events = { {event = "touch",method = "login"} }} ,
    btGuestLogon = {varname = "btGuestLogon",events = { {event = "touch",method = "GuestLogin"} }} ,
    edtAccounts = {varname = "edtAccounts"},
    edtPassword = {varname = "edtPassword"},
    }

SceneLogin.RESOURCE_BINDING = binding


function SceneLogin:onCreate()
	local node = cc.uiloader:seekNodeByName(self.resourceNode_,"LogonBK")
     local childs = node:getChildren()
     local childNum = node:getChildrenCount()
     for i=1,childNum do
     	printInfo(childs[i].name.. " "..childs[i].__cname)
     end
end

function SceneLogin:login(event)
    if event.name == "ended"then
        printInfo("onLogin")
        if self.text_id:getString() == "" then
            printInfo("empty")    
        else
            printInfo("no empty")
        end
    end
    
end

function SceneLogin:register(event)
	app:enterScene("SceneRegister",nil,"random")
end

function SceneLogin:GuestLogin(event)
	 if event.name == "ended"then
        printInfo("onGuestLogin")
        if self.text_id:getString() == "" then
            printInfo("empty")    
        else
            printInfo("no empty")
        end
    end
end

return SceneLogin