--
-- Author: hxl
-- Date: 2017-03-06 16:39:06
--
local net = require("framework.cc.net.init")
local helper = require("helper")
local scrypt = require("scrypt")

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


function SceneLogin:sendData(data) 
    data = scrypt.base64encode(data)
    self.socket_:send(string.pack(">P",data))
end

function SceneLogin:handler()
    if self.phase == 1 then
        self.socket_:connect("127.0.0.1", 8001, false)
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


function SceneLogin:onCreate()
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

function SceneLogin:login(event)
    self.uid = self.edtAccounts:getString()
    self.pass = self.edtAccounts:getString()
    if self.uid == "" then
        device.showAlert("", app.language.idNo)
        return
    end
    if self.pass == "" then
        device.showAlert("", app.language.psNo)
        return
    end

    self.phase = 1
    self:handler()

end

function SceneLogin:register(event)
	app:enterScene("SceneRegister",nil,"random")
end

function SceneLogin:GuestLogin(event)
       
end

function SceneLogin:tcpData(event) 
    -- local len,data = string.unpack(event.data,">P")
    local data = event.data:sub(1,-2)
    data = crypto.decodeBase64(data)
    print("receive data:" .. data)
    if self.phase == 1 then
        self.challenge = data
        self.phase = 2
        -- self:handler()
    elseif self.phase == 2 then
        self.secret = scrypt.dhsecret(data, self.clientkey)
        print("sceret is ", scrypt.hexencode(self.secret))
        self.phase = 3
        self:handler()
    elseif self.phase == 3 then
        if data == "ok" then
            self.phase = 4
            self:handler()
        else
            self.socket_:close()
        end
        print(data)
    elseif self.phase == 4 then
        print(data)
    end
end

function SceneLogin:tcpClose()
    print("SocketTCP close")
end

function SceneLogin:tcpClosed()
    print("SocketTCP closed")
end

function SceneLogin:tcpConnected()
    print("SocketTCP connect success")
end

function SceneLogin:tcpConnectedFail()
    print("SocketTCP connect fail")
end

return SceneLogin