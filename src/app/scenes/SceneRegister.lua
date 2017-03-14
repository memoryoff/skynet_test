local net = require("framework.cc.net.init")
local helper = require("helper")
local scrypt = require("scrypt")

local SceneRegister = class("SceneRegister",import(".ViewBase"))

SceneRegister.RESOURCE_FILENAME = "RegisterView.json"   

function SceneRegister:sendData(data) 
	data = scrypt.base64encode(data)
	self.socket_:send(string.pack(">P",data))
end

function SceneRegister:handler()
	if self.phase == 1 then
		self.socket_:connect("127.0.0.1", 8888, false)
		-- self.socket_:send(sendData) 	
	elseif self.phase == 2 then
		self.clientkey = scrypt.randomkey()
		print("clientkey = ".. self.clientkey)
		-- local data = scrypt.base64encode(scrypt.dhexchange(self.clientkey))
		-- self.socket_:send(string.pack(">P",data))
		self:sendData(scrypt.dhexchange(self.clientkey))
	elseif self.phase == 3 then
		local hmac = scrypt.hmac64(self.challenge, self.secret)
		-- self.socket_:send(string.pack(">P",scrypt.base64encode(hmac)))
		self:sendData(hmac)
	elseif self.phase == 4 then
		local id = self.edtId:getString()
		local pass = self.edtPass1:getString()
		local nick = self.edtNick:getString()
		local sex = 0
		if self.btMan:isButtonSelected() then
			sex = 1
		end
		local data = id..":"..pass..":"..nick..":"..tostring(sex)
		print("send register = "..data)
		data = scrypt.desencode(self.secret, data)
		self:sendData(data)
	end
	
end 

local binding = { 
    btBack = {varname = "btBack",events = { {event = "touch",method = "onBack"} }} ,
    btCommit = {varname = "btCommit",events = { {event = "touch",method = "onCommit"} }} ,
    btMan = {varname = "btMan",events = { {event = "checkBoxButton",method = "onCheckBox"} }} ,
    btWomen = {varname = "btWomen",events = { {event = "checkBoxButton",method = "onCheckBox"} }} ,
    btTermsOfService = {varname = "btTermsOfService"},
    edtAccounts = {varname = "edtId"},
    edtPassword = {varname = "edtPass1"},
    edtRepeat = {varname = "edtPass2"},
    edtNickName = {varname = "edtNick"},
    }

SceneRegister.RESOURCE_BINDING = binding

function SceneRegister:onCreate()
	self.btMan:onButtonClicked(handler(self, self.onCheckBox))
	self.btWomen:onButtonClicked(handler(self, self.onCheckBox))
	self.btMan:setButtonSelected(true)

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
	if self.edtId:getString()=="" then
		device.showAlert("", app.language.idNo)
		return
	end

	if  self.edtPass1:getString()=="" then
		device.showAlert("",app.language.psNo)
		return
	end

	if self.edtPass1:getString() ~= self.edtPass2:getString() then
		device.showAlert("",app.language.psDif)
		return
	end

	if self.edtNick:getString()=="" then
		device.showAlert("",app.language.nickNo)
		return
	end

	if  self.btTermsOfService:isButtonSelected() then
		self.phase = 1
		self:handler()
	else
		device.showAlert("",app.language.agreeNo)
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
		self.phase = 2
		self:handler()
	elseif self.phase == 2 then
		data = scrypt.base64decode(data)
		self.secret = scrypt.dhsecret(data, self.clientkey)
		print("sceret is ", scrypt.hexencode(self.secret))
		self.phase = 3
		self:handler()
	elseif self.phase == 3 then
		data = scrypt.base64decode(data)
		if data == "ok" then
			self.phase = 4
			self:handler()
		else
			self.socket_:close()
		end
		print(data)
	elseif self.phase == 4 then
		data = scrypt.base64decode(data)
		print(data)
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