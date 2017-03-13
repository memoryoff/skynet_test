local net = require("framework.cc.net.init")
local helper = require("helper")


local SceneRegister = class("SceneRegister",import(".ViewBase"))

SceneRegister.RESOURCE_FILENAME = "RegisterView.json"   

function SceneRegister:handler()
	if self.phase == 1 then
		self.socket_:connect("127.0.0.1", 8888, true)
		-- self.socket_:send(sendData) 	
	
	elseif self.phase == 2 then

	end
	
end 

local binding = { 
    btBack = {varname = "btBack",events = { {event = "touch",method = "onBack"} }} ,
    btCommit = {varname = "btCommit",events = { {event = "touch",method = "onCommit"} }} ,
    btMan = {varname = "btMan",events = { {event = "checkBoxButton",method = "onCheckBox"} }} ,
    btWomen = {varname = "btWomen",events = { {event = "checkBoxButton",method = "onCheckBox"} }} ,
    btTermsOfService = {varname = "btTermsOfService"}
    }

SceneRegister.RESOURCE_BINDING = binding

function SceneRegister:onCreate()
	self.btMan:onButtonClicked(handler(self, self.onCheckBox))
	self.btWomen:onButtonClicked(handler(self, self.onCheckBox))


	local socket = net.SocketTCP.new()
	socket:setName("TestSocketTcp")
	socket:setReconnTime(6)
	socket:setConnFailTime(4)

	socket:addEventListener(net.SocketTCP.EVENT_DATA, handler(self, self.tcpData))
	socket:addEventListener(net.SocketTCP.EVENT_CLOSE, handler(self, self.tcpClose))
	socket:addEventListener(net.SocketTCP.EVENT_CLOSED, handler(self, self.tcpClosed))
	socket:addEventListener(net.SocketTCP.EVENT_CONNECTED, handler(self, self.tcpConnected))
	socket:addEventListener(net.SocketTCP.EVENT_CONNECT_FAILURE, handler(self, self.tcpConnectedFail))

	self.socket_ = socket



end



function SceneRegister:onBack(event)
	app:enterScene("SceneLogin", nil, "random", 1)
end

function SceneRegister:onCommit(event)
	if  self.btTermsOfService:isButtonSelected() then
		self.phase = 1
		self:handler()
	else
		printInfo("not ok")
	end
end

function SceneRegister:onCheckBox(event)
	print(event.name .. " ".. event.target.name .." onCheckBox")
	self.buttons_ = self.buttons_ or {self.btMan,self.btWomen}
	local function updateButtonState_(clickedButton) 
		local currentSelectedIndex = 0
	    for index, button in ipairs(self.buttons_) do
	        if button == clickedButton then
	            currentSelectedIndex = index
	            if not button:isButtonSelected() then
	                button:setButtonSelected(true)
	            end
	        else
	            if button:isButtonSelected() then
	                button:setButtonSelected(false)
	            end
	        end
	    end
	    -- if self.currentSelectedIndex_ ~= currentSelectedIndex then
	    --     local last = self.currentSelectedIndex_
	    --     self.currentSelectedIndex_ = currentSelectedIndex
	    --     self:dispatchEvent({name = UICheckBoxButtonGroup.BUTTON_SELECT_CHANGED, selected = currentSelectedIndex, last = last})
	    -- end
	end

    if event.name == cc.ui.UICheckBoxButton.STATE_CHANGED_EVENT and event.target:isButtonSelected() == false then
    	print("test")
    	print(event.target.name)
        return
    end
    updateButtonState_(event.target)
end

function SceneRegister:tcpData(event) 
	print("receive data")

	local len,data = string.unpack(event.data,">P")
	print("SocketTCP receive data:" .. data)
	if self.phase == 1 then
		self.challenge = crypto.decodeBase64(data)
	end
end

function SceneRegister:tcpClose()
	print("SocketTCP close")
end

function SceneRegister:tcpClosed()
	print("SocketTCP closed")
end

function SceneRegister:tcpConnected()
	print("SocketTCP connect success")
end

function SceneRegister:tcpConnectedFail()
	print("SocketTCP connect fail")
end


return SceneRegister