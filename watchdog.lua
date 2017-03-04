local skynet = require "skynet"
local netpack = require "netpack"

local AddressBook_pb = require("pb.AddressBook_pb")
local ResultInfo_pb = require("pb.ResultInfo_pb")
local RoomInfo_pb = require("pb.RoomInfo_pb")
local GetRoom_pb = require("pb.GetRoom_pb")

local CMD = {}
local SOCKET = {}
local gate
local agent = {}

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	agent[fd] = skynet.newservice("agent")
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("gate")
end)


function testRoom()
    -- 序列化 GetRoomRequest
    local roomIdList = {10,20,30}
    local getRoomRequestWriter = GetRoom_pb.GetRoomRequest() --#pbTips

    for _, v in ipairs(roomIdList) do
        getRoomRequestWriter.roomId:append(v) -- 向数组添加元素，不能直接赋值
    end
    print("== Serialize to GetRoomRequest")
    local data = getRoomRequestWriter:SerializeToString()

    -- 反序列化 GetRoomRequest
    local getRoomRequestReader = GetRoom_pb.GetRoomRequest() --#pbTips
    print("== Parse From GetRoomRequest")
    getRoomRequestReader:ParseFromString(data)
    -- 使用 ipairs 可正确获取到数据，paris 会有多余数据打印出来
    for _, v in ipairs(getRoomRequestReader.roomId) do
        print(v)
    end

    -- 序列化 GetRoomResponse
    local getRoomResponseWriter = GetRoom_pb.GetRoomResponse()
    getRoomResponseWriter.result = ResultInfo_pb.SUCCESS

    for i=1,2 do
        local room = getRoomResponseWriter.room:add() -- 数组中的元素是对象，用add来添加
        room.id = "1000" .. i
        room.name = "小黑屋-" .. i
        room.taskType = RoomInfo_pb.MAINLINE
    end
    print("== Serialize to GetRoomResponse")
    local data = getRoomResponseWriter:SerializeToString()

    -- 反序列化 GetRoomResponse
    local getRoomResponseReader = GetRoom_pb.GetRoomResponse()
    print("== Parse From GetRoomResponse")
    getRoomResponseReader:ParseFromString(data)
    print("result:" .. getRoomResponseReader.result)
    print("message:" .. getRoomResponseReader.message) -- default value test
    for _, v in ipairs(getRoomResponseReader.room) do
        print(v.id)
        print(v.name)
        print(v.taskType)
        print(v.needHp) -- default value test
    end
end

function testPerson()
    print("========= test AddressBook ====")

    -- 序列化
    local addressBookWriter = AddressBook_pb.AddressBook()
    for i = 1, 5 do
        local person = addressBookWriter.person:add()
        person.name = "my " .. i
        person.id = i

        local phone = person.phone:add()
        phone.number = "123456789"
        if i % 2 == 0 then
            phone.type = AddressBook_pb.Person.WORK
        end
    end
    local data = addressBookWriter:SerializeToString()

    -- write to file for compare test with python pb
    -- local path = cc.FileUtils:getInstance():getWritablePath() .. "testpb.bin"
    -- io.writefile(path, data, "wb")

    -- 反序列化
    local addressBookReader = AddressBook_pb.AddressBook()
    addressBookReader:ParseFromString(data)
    for _, person in ipairs(addressBookReader.person) do
        print(person.name)
        print(person.id)
        for _, phone in ipairs(person.phone) do
            print(phone.number)
            if (phone.type == AddressBook_pb.Person.MOBILE) then
                print("MOBILE")
            elseif (phone.type == AddressBook_pb.Person.HOME) then
                print("HOME")
            else
                print("WORK")
            end
        end
    end
end

testRoom()
testPerson()
