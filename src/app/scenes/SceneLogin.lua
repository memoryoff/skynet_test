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

function SceneLogin:username(uid, subid, servername)
    return string.format("%s@%s#%s", scrypt.base64encode(uid), scrypt.base64encode(servername), scrypt.base64encode(tostring(subid)))
end

function SceneLogin:sendData(data) 
    data = scrypt.base64encode(data)
    data = data.."\n"
    self.socket_:send(data)
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

        local data = self.uid..":"..self.pass
        print("send login = "..data)
        data = scrypt.desencode(self.secret, data)
        self:sendData(data)

    elseif self.phase == 4 then --和游戏服务器连接
        local data = self:username(self.uid,self.subid,"serGate")
        print("username = ",data,self.uid,self.subid,"serGate")
        self.index = 1
        data = data..":"..self.index
        data = data..":"..scrypt.base64encode(scrypt.hmac_hash(self.secret,data))
        self.socket_:connect("127.0.0.1", 9001, false)
        data = string.pack(">P",data)
        self.socket_:send(data)
    elseif self.phase == 5 then -- 已经连上游戏服务器,发送消息格式为data+session(4byte)
        print("phase5 hanlder")
        local data = "hello world"
        data = data..string.pack(">I",1)
        print(helper.hex(data))
        self.socket_:send(string.pack(">P",data))

        -- data = string.pack(">PI","0123456789",2)
        -- self.socket_:send(data)
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
    self.pass = self.edtPassword:getString()
    if self.uid == "" then
        device.showAlert("", app.language.idNo)
        return
    end
    if self.pass == "" then
        device.showAlert("", app.language.psNo)
        return
    end

    self.phase = 1
    self.subid = nil
    self:handler()

end

function SceneLogin:register(event)
	app:enterScene("SceneRegister",nil,"random")
end

function SceneLogin:GuestLogin(event)
       
end

function SceneLogin:tcpData(event) 
    -- local len,data = string.unpack(event.data,">P")

    if self.phase == 1 then
        local data = event.data:sub(1,-2)
        data = crypto.decodeBase64(data)
        print("receive data:" .. data)
        self.challenge = data
        self.phase = 2
        self:handler()
    elseif self.phase == 2 then
        local data = event.data:sub(1,-2)
        data = crypto.decodeBase64(data)
        print("receive data:" .. data)
        self.secret = scrypt.dhsecret(data, self.clientkey)
        print("sceret is ", scrypt.hexencode(self.secret))
        self.phase = 3
        self:handler()
    elseif self.phase == 3 then
        print("receive data:" ..  event.data,#event.data)
        local index = event.data:find("200 ")
        if index then
            self.subid = event.data:sub(5,-2)
            self.subid = scrypt.base64decode(self.subid)
            self.phase = 4
            self:handler()
        else 
            self.socket_:close()
            device.showAlert("", app.language.psError)
        end
    elseif self.phase == 4 then
        local len,data = string.unpack(event.data,">P")
        print("msg from serGate = ",data)
        if data == "200 OK"then
            self.phase = 5
            self:handler()
        end
    elseif self.phase == 5 then
        local len,data = string.unpack(event.data,">P")
        local str = string.sub(data,1,-6)
        local other = string.sub(data,-5)
        print("msg from agent = ",str, string.unpack(other,">bI"))
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