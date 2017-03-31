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
local users = {} -- uid = {房号，玩家状态标记,时间戳}
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

function table.cardLoard( ... )
	-- body
end

function table.cardplay( ... )
	-- body
end

function table.cardPass( ... )
	-- body
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
	roomReady[rid],roomWaiting[rid]= roomWaiting[rid],nil
	local stamp = skynet.now()
	for _,uid in ipairs(roomReady[rid]) do
		-- if users[uid].ready == role_unready then
		-- 	users[uid].timeStamp = stamp
		-- end
		users[uid].timeStamp = stamp
	end

end

local function initRunningRoom(rid) -- 正式打牌，返回第一个出牌的人的uid
	roomRunning[rid],roomReady[rid] = roomReady[rid],nil
	for _,uid in ipairs(roomRunning[rid]) do
		users[uid].state = role_playing
	end
	return table.init(rid)
end

local function enterRoom(rid,uid)
	if #roomWaiting[rid] >= 3 then
		return false
	end
	table.insert(roomWaiting[rid],uid)
	users[uid] = {roomId = rid,state = role_unready}
	if #roomWaiting[rid] >= 3 then
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
	if users[uid].state == role_playing then
		return false
	end
	if ready then
		users[uid].state = role_ready
		users[uid].timeStamp = nil
		if roomReady[users[uid].roomId] then
			for _,id in ipairs(roomReady[users[uid].roomId]) do
				if users[id].state != role_ready then
					return true
				end
			end
			local firstUid = initRunningRoom(users[uid].roomId) -- 如果所有人都已经准备，一桌牌正式开始
			return true,firstUid
		end
	else
		users[uid].state = role_unready
		users[uid].timeStamp = skynet.now()
	end
	return true
end

function response.changeRoom(uid)
	assert(users[uid],"uid not in room")
	if users[uid].state == role_playing then
		return false
	end

	local rid = users[uid].roomId
	if roomWaiting[rid] then
		for i,v in ipairs(roomWaiting[rid]) do
			if v == uid then
				table.remove(roomWaiting[rid],i)
				if #roomWaiting[rid] == 0 then
					roomWaiting[rid] = nil
				end
				break
			end
		end
		
	elseif roomReady[rid] then
		for i,v in ipairs(roomReady[rid]) do
			if v == uid then
				table.remove(roomReady[rid],i)
				roomWaiting[rid],roomReady[rid] = roomReady[rid],nil
				break
			end
		end
	elseif roomRunning[rid] then
		return false
	end

	rid = getRoom()
	enterRoom(rid,uid)
	return rid
end

function response.cardCallLoard(uid,times)
	assert(users[uid],"uid not in room")
	if users[uid].state == role_playing then
		return false
	end
	local rid = users[uid].roomId
	if not game.isReady(rid) then
		return false
	end

	local ok,gameState = game.callLoard(rid,uid,times)
	local res = {}
	res.ok = ok
	if ok then
		res.gameState = gameState
		res.nextPlayer = game.getCurPlayer(rid)
	end
	return res
end

function response.cardPlay(uid)
	assert(users[uid],"uid not in room")
	if users[uid].state == role_playing then
		return false
	end
	local rid = users[uid].roomId
	if not game.isReady(rid) then
		return false
	end

	local ok,gameState = game.callLoard(rid,uid,times)
	local res = {}
	res.ok = ok
	if ok then
		res.gameState = gameState
		res.nextPlayer = game.getCurPlayer(rid)
	end
	return res
end

function response.cardPass(uid)
	assert(users[uid],"uid not in room")
	if users[uid].state == role_playing then
		return false
	end

	local rid = users[uid].roomId
	if roomWaiting[rid] then
		for i,v in ipairs(roomWaiting[rid]) do
			if v == uid then
				table.remove(roomWaiting[rid],i)
				if #roomWaiting[rid] == 0 then
					roomWaiting[rid] = nil
				end
				break
			end
		end
		
	elseif roomReady[rid] then
		for i,v in ipairs(roomReady[rid]) do
			if v == uid then
				table.remove(roomReady[rid],i)
				roomWaiting[rid],roomReady[rid] = roomReady[rid],nil
				break
			end
		end
	elseif roomRunning[rid] then
		return false
	end

	rid = getRoom()
	enterRoom(rid,uid)
	return rid
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
