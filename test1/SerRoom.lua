--
-- Author: hxl
-- Date: 2017-03-20 09:54:09
--
local skynet = require "skynet"
local snax = require "snax"
local game = require "gameLogic"


local id = 1
local roomId = 0
local maxNum = 3000
local curNum = 0
local readyTime = 30 -- 超时时间
local users = {} -- uid = {房号,房间状态标记，玩家状态标记,时间戳}
local roomWaiting = {}
local roomReady = {}
local roomRunning = {}

local role_unready = 1
local role_ready = 2
local role_playing = 3

local room_wait = 1
local room_ready = 2
local room_run = 3

local game_start = 1
local game_playing = 2
local game_end = 3

local table = {}

function table.init(rid)

	if #roomRunning[rid] ~= 3 or not game.isOver(rid)then
		return false
	end
	return game.init(rid,roomRunning)
end


local function getRoom() -- 返回一个空闲的房间
	if next(roomWaiting) then
		math.randomseed(tostring(os.time()):reverse())
    	local t = {}
    	for k,v in pairs(roomWaiting) do
    		t[#t+1] = k
    	end
    	local index = math.random(1,#t)
    	local roomId = t[index]
    	return roomId
	else
		roomId = roomId + 1
		roomWaiting[roomId] = {}
		return roomId
	end
end

local function initReadyRoom(rid)
	local stamp = skynet.now()
	for _,uid in ipairs(roomReady[rid]) do
		users[uid].roomState = room_ready
		if users[uid].ready == role_unready then
			users[uid].timeStamp = stamp
		end
	end

end

local function initRunningRoom(rid)
	roomRunning[rid],roomReady[rid] = roomReady[rid],nil
	for _,uid in ipairs(roomRunning[rid]) do
		users[uid].roleState = role_playing
	end
end

local function enterRoom(rid,uid)
	table.insert(roomWaiting[rid],uid)
	users[uid] = {roomId = rid,roomState = room_wait,roleState = role_unready}
	if #roomWaiting[rid] >= 3 then
		roomReady[rid],roomWaiting[rid]= roomWaiting[rid],nil
		initReadyRoom(rid)
	end
end


function response.enter(uid)
	assert(users[uid] == nil,"uid has in room")
	assert(curNum < maxNum,"room reach upper limit ")

	curNum = curNum + 1
	local roomId = getRoom()
	enterRoom(roomId,uid)
	return roomId
end

function response.quit(uid)
	assert(users[uid],"uid not in room")
	curNum = curNum - 1
	users[uid] = nil
end

function response.ready(uid,ready)
	assert(users[uid],"uid not in room")
	if users[uid].roleState == role_playing then
		return false
	end
	if ready then
		users[uid].roleState = role_ready
		users[uid].timeStamp = nil
		if users[uid].roomState == room_ready then
			for i,v in ipairs(roomReady[uid]) do
				if users[v].roleState != role_ready then
					return true
				end
			end
			init
		end
		for i,v in ipairs() do
			print(i,v)
		end
	else
		users[uid].roleState = role_unready
		users[uid].timeStamp = skynet.now()
	end
	return true
end

function response.changeRoom(uid)
	assert(users[uid],"uid not in room")

	local roomState = users[uid].roomState
	local roomId = users[uid].roomId
	if roomState == room_wait then
		for i,v in ipairs(roomWaiting[roomId]) do
			if v == uid then
				table.remove(roomWaiting[roomId],i)
				if #roomWaiting[roomId] == 0 then
					roomWaiting[roomId] = nil
				end
				break
			end
		end
		
	elseif roomState == room_ready then
		for i,v in ipairs(roomReady[roomId]) do
			if v == uid then
				table.remove(roomReady[roomId],i)
				roomWaiting[roomId],roomReady[roomId] = roomReady[roomId],nil
				break
			end
		end
	elseif roomState == room_run then

	end

	roomId = getRoom()
	enterRoom(roomId,uid)
	return roomId
end





function accept.exit(...)
	snax.exit(...)
end

function response.error()
	error "snax error"
end

function init( ... )
	print ("snax_test server start:", ...)
	local fun = function() --超时设定
		if #roomReady > 0 then
			local stamp = skynet.now()
			local quitUser = quitUser{}
			for _,v in ipairs(roomReady) do
				for _,uid in ipairs(v[1]) do
					if not users[uid].ready then
						local diff = stamp - users[uid].timeStamp
						if diff >= readyTime*100 then
							table.insert(quitUser,uid)
						end
					end
				end
			end
			if #quitUser > 0 then
				for _,uid in ipairs(quitUser) do
					response.quit(uid)
				end
			end
		end
		skynet.timeout(20,fun)
	end
	skynet.timeout(20,fun)
end

function exit(...)
	print ("snax_test server exit:", ...)
end
