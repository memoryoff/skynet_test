--
-- Author: hxl
-- Date: 2017-03-21 14:12:02
--

local cardUtils = require "cardUtils"

local game_ready = 0 --抢地主阶段
local game_play = 1
local game_end = 2

local game = {}

----各种牌型的对应数字 
game.CARD_ERROR = 0--错误牌型  
game.CARD_ONE = 1--单牌    
game.CARD_PAIR = 2--对子    
game.CARD_THREE = 3--3不带    
game.CARD_THREEONE = 4--3带1    
game.CARD_THREEPAIR = 5--3带2    
game.CARD_FOURTWO = 6--四个带2张单牌或两个对子 
game.CARD_CONNECT = 7--顺子    
game.CARD_COMPANY = 8--连对   
game.CARD_AIRCRAFT = 9--飞机不带    
game.CARD_AIRCRAFTWING = 10--飞机带单牌或对子  
game.CARD_BOMB = 11--炸弹    
game.CARD_KINGBOMB = 12--王炸  

game.STATE_READY = 1
game.STATE_PLAY = 2
game.STATE_OVER = 3


-- 单牌  
local function isOne(cards)  
  if 1 == #cards then  
    return cards[1]
  end  
  return false  
end  
  
--对子  
local function isPair(cards)  
  if 2 == #cards then  
    if cards[1] == cards[2] then  
        return cards[1]
    end  
  end  
  return false  
end  
  

  
--3不带 只要判断三个牌值相等  
local function isThree(cards)  
  if 3 ~= #cards then   
      return false  
  end  
  if cards[1] == cards[2] and cards[1] == cards[3] then  
      return cards[1]
  end  
  return false  
end  
  
--3带1 先对数字排序 再判断带的牌是在那个位置 （4446，3444）再将带的牌移除判断剩下的三个牌是不是 3不带  
local function isThreeOne(cards)  
	if 4 ~= #cards then   
	  return false  
	end  
	if cards[1] == cards[2] and cards[1] == cards[3] then
		return cards[1]
	elseif cards[2] == cards[3] and cards[2] == cards[4] then
		return cards[2]
	end
 	return false  
end  
  
--3带对子  先排序 头尾都是对子而且中间的牌等于头或者尾的值（55577，44555）  
local function isThreePair( cards )  
  if 5 ~= #cards then   
      return false  
  end  
  if cards[1] == cards[2] and cards[4] == cards[5] then  
    if cards[3] == cards[2] or cards[3] == cards[4] then  
      return cards[3]
    end  
  end  
  return false  
end  

function isFourTwo(cards)  
  if #cards ~= 6 or #cards ~ 8 then   
      return false  
  end 
  local four = {}
  local other = {}
  for i=1,#cards - 3 do
  	if cards[i] == cards[i+1] and cards[i] == cards[i+2] and cards[i+3] then
  		table.insert(four,cards[i])
  		table.insert(four,cards[i+1])
  		table.insert(four,cards[i+2])
  		table.insert(four,cards[i+3])
  		i = i + 3
  	else
  		table.insert(other,cards[i])
  		if i== #cards-3 then
  			table.insert(other,cards[i+1])
  			table.insert(other,cards[i+2])
  			table.insert(other,cards[i+3])
  		end
  	end
  end
  if #four > 0 and #other == 2 or (other[1]==other[2] and other[3]==other[4])then
  	return four[1]
  end
  return false
end  

-- -- 4带2个单
-- function isFourPairOne(cards)  
--   if #cards ~= 6 then   
--       return false  
--   end   
  
--   if cards[1] == cards[2] and cards[1] == cards[3] and cards[1] == cards[4]
--   	return cards[1]
--   elseif cards[3] == cards[4] and cards[3] == cards[5] and cards[3] == cards[6]
--   	return cards[6]
--   end
--   return false
-- end  

-- -- 4带2个双
-- function isFourPairTwo(cards)  
--   if #cards ~= 8 then   
--       return false  
--   end   
  
--   if cards[1] == cards[2] and cards[1] == cards[3] and cards[1] == cards[4] and cards[5] == cards[6] and cards[7] == cards[8]
--   	return cards[1]
--   elseif cards[1] == cards[2] and cards[3] == cards[4] and cards[5] == cards[6] and cards[5] == cards[7] and cards[5] == cards[8]
--   	return cards[8]
--   end
--   return false
-- end 

--顺子 只要判断相邻的数字数值是否差1就可以,默认从A开始排序
local function isConnect(cards)  
  if 5 > #cards then   
      return false  
  end  

	for i = 1, (#cards - 1) do  -- 先判断重复
	    if cards[i] == cards[i+1] then  
	      return false  
	    end  
	end  

  --大小王不能加入顺子  
  if cards[#cards] >13 then  
    return false  
  end  
  if cards[1]==2 or cards[2]==2 then -- 2不能加入顺子
  	return false
  end
  if cards[1] == 1 then -- 有1的情况特殊处理
  	if cards[#cards] ~= 13 then
  		return false
  	else
  		for i = 2, (#cards - 1) do  
		    if cards[i] ~= cards[i+1] -1 then  
		      return false  
		    end  
  		end  
  		return cards[2]
  	end
  end
  for i = 1, (#cards - 1) do  -- 没有1判断是否为顺子
    if cards[i] ~= cards[i+1] -1 then  
      return false  
    end  
  end  
  return cards[1]
end  
  
-- 连对 33445566 ,
local function isCompany(cards)  
  if 6 > #cards or (#cards % 2) ==1 then   
      return false  
  end
  if cards[1]==2 or cards[3]==2 then -- 不包括2
  	return false
  end
  local begin = 1
  if cards[1]==1 and cards[#cards]==13 and cards[1] == cards[2] then -- 有A的情况特殊处理
  	begin = 3
  else
  	return false
  end
  for i = begin, (#cards  - 1) do  
    if (i % 2) ==1 then  
      if cards[i] ~= cards[i + 1]  then  
        return false  
      end   
    else  
      if cards[i] ~= cards[i + 1] - 1 then  
        return false  
      end  
    end  
  end  
  return cards[1] 
end 


-- 飞机不带    
-- 遍历到三个一组中的第一个的时候判断这组的值是否都相等  
-- 遍历到三个一组中的最后一个的时候判断和下一组的数值是不是差一  
local function isAircraft(cards)  
  if 6 > #cards or (#cards % 3) ~=0 then   
      return false  
  end   
  if cards[1]==2 or cards[4]==2 then -- 不包括2
  	return false
  end

  local begin = 1
  if cards[1]==1 and cards[#cards]==13 and cards[2]==1 and cards[3]==1 then -- 有A特殊处理
  	begin = 4
  else
  	return false
  end
  for i = begin, (#cards - 1) do  
    if (i % 3) ==1 then  
      if cards[i] ~= cards[i + 1] or cards[i + 1] ~= cards[i + 2] then  
        return false  
      end   
    elseif (i % 3) == 0 then  
      if cards[i] ~= cards[i + 1] - 1 then  
        return false  
      end  
    end  
  end  
  return cards[1]
end  
  
  
-- 飞机带翅膀  
local function isAircraftWing(cards)  
	if 8 > #cards  then   
	  	return false  
	end   
	if (#cards % 4) ~=0 and (#cards % 5) ~= 0 then  
		return false  
	end  

	local other = {}
	local three = {}

	for k = 1, (#cards - 2) do  
		if cards[k] == cards[k+1] and cards[k] == cards[k+2] then
			table.insert(three,cards[k])
			table.insert(three,cards[k+1])
			table.insert(three,cards[k+2])
			k = k+2
		else
			table.insert(other,cards[k])
			if k == #cards - 2 then
				table.insert(other,cards[k+1])
				table.insert(other,cards[k+2])
			end
		end
	end

	if #cards % 5 == 0 and #other/2 == #three/3 then
	  	for i=1,#other,2 do
	  		if other[i] ~= other[i+1] then
	  			return false
	  		end
	  	end
  	end
	if #other ~= #three/3 then
		return false
	end

	if not isAircraft(three) then
		return false
	end

  	return three[1]
end 
  
--炸弹  
local function isBomb( cards )  
  if 4 ~= #cards then   
      return false  
  end  
  if cards[1] == cards[2] and cards[2] == cards[3] and cards[3] == cards[4] then  
    return cards[1]
  end  
  return false  
end

--王炸  
local function isKingBomb(cards)  
  if 2 ~= #cards then   
      return false  
  end  
  if cards[1] == 14 and cards[2] == 15 then  
    return card[1]
  end  
  return false  
end  

local cardOder = {3,4,5,6,7,8,9,10,11,12,13,1,2,14,15}
local compData = {}
for i=1,#cardOder do
	compData[cardOder[i]] = i
end
local function comp(card1,card2) -- 比较单牌card1是否大于card2
	return compData[card1] > compData[card2]
end



local function cardType(cards)-- 返回类型，数量，关键牌
	if not cardUtils.isCard(cards) then
		return game.CARD_ERROR
	end
	local tmpCards = {}
	for i=1,#cards do
		table.insert(tmpCards,cardUtils.getValue(cards[i]))
	end
	table.sort(tmpCards)
	local num = #tmpCards
	local key = 0
	if num == 1 then
		key = isOne(tmpCards)
		if key then
			return game.CARD_ONE,num,key
		end
	elseif num == 2 then
		key = isPair(tmpCards)
		if key then
			return game.CARD_PAIR,num,key
		end
		key = isKingBomb(tmpCards)
		if key then
			return game.CARD_KINGBOMB,num,key
		end
	elseif num == 3 then
		key = isThree(tmpCards)
		if key then
			return game.CARD_THREE,num,key
		end
	elseif num == 4 then
		key = isBomb(tmpCards)
		if key then
			return game.CARD_BOMB,num,key
		end
		key = isThreeOne(tmpCards)
		if key then
			return game.CARD_THREEONE,num,key
		end
	elseif num == 5 then
		key = isThreePair(tmpCards)
		if key then
			return game.CARD_THREEPAIR,num,key
		end
		key = isConnect(tmpCards)
		if key then
			return game.CARD_CONNECT,num,key
		end
	else -- 大于5张牌的
		key = isConnect(tmpCards)
		if key then
			return game.CARD_CONNECT,num,key
		end
		key = isFourTwo(tmpCards)
		if key then
			return game.CARD_FOURTWO,num,key
		end
		key = isAircraft(tmpCards)
		if key then
			return game.CARD_AIRCRAFT,num,key
		end
		key = isCompany(tmpCards)
		if key then
			return game.CARD_CONNECT,num,key
		end
		key = isAircraftWing(tmpCards)
		if key then
			return game.CARD_AIRCRAFTWING,num,key
		end
	end
	return game.CARD_ERROR
end


local function canPlay(cards,lastInfo) -- 如果可以出牌，返回牌的信息

	local res = table.pack(cardType(cards))
	if res[1] == game.CARD_ERROR then
		return false
	end
	if not lastInfo then -- 没有上一把牌信息表示可以出牌
		return true,res
	elseif lastInfo[1] == game.CARD_KINGBOMB then-- 王炸最大，都不能出牌
		return false
	end
	if res[1] == game.CARD_KINGBOMB then
		return true,res
	elseif res[1] == game.CARD_BOMB then
		if lastInfo[1] == game.CARD_BOMB then
			if comp(res[3],lastInfo[3]) then
				return true,res
			end
		else
			return true,res
		end
	elseif res[1] == lastInfo[1] and res[2] == lastInfo[2] and comp(res[3],lastInfo[3]) then
		return true,res
	end
	return false
end
 

function game.init(rid,room)
	game.data = game.data or {} 
	game.data[rid] = game.data[rid] or {}
	local data = game.data[rid]
	assert(not data.state and data.state == game.STATE_OVER,"the rid game not end")
	data.state = game.STATE_READY
	data.players = data.players or {}
 	data.times = 0 -- 倍数
	
	local roleChange = false
	for _,uid in ipairs(room[rid]) do
		if not data.players[uid] then
			roleChange = true
			data.players = {} -- 房间换了新人，置空用户表
			break
		end
	end
	if not roleChange then -- 选出第一个叫地主的玩家
		data.curPlayIndex = data[data.winer].index
	else
		data.curPlayIndex = math.random(1,3)
	end
	
	local cards = cardUtils.getOriginCard() -- 给每个玩家分配牌
	for i,uid in ipairs(room[rid]) do
		data.players[i] = uid
		data.players[uid] = {}
		data.players[uid].index = i
		data.players[uid].resCards = {}
		-- data.players[uid].playCards = {}
		data.players[uid].agent = false
		-- data.players[uid].timeStamp = skynet.now()
		for t=1 , 17 do
			table.insert(data.players[uid].resCards,cards[t+(i-1)*17])
		end
	end
	data.baseCards = {}
	for i=52,54 do
		table.insert(data.baseCards,cards[i])	
	end
	data.pastInfo = {} -- 每一轮打过的牌以及牌的信息
	return data.players[data.curPlayIndex]
end






function game.getCurPlayer(rid)
	local data = game.data[rid]
	return data.players[data.curPlayIndex]
end

function game.isOver(rid)
	local data = game.data[rid]
	return not data.state or data.state==game.STATE_OVER
end

function game.getTimes(rid)
	return game.data[rid].times
end

function game.callLoard(rid,uid,times) -- 叫地主,times==0表示不叫
	assert(times >= 0 and times <= 3)
	local data = game.data[rid]
	assert(data.state == game.STATE_READY)

	if data.players[uid].index ~= data.curPlayIndex then -- 没有轮到当前玩家出牌
		return false
	end
	if times > 0 and times <= data.times then -- 不能小于当前倍数
		return false
	end

	table.insert(data.pastInfo,{uid = uid,times = times})
	if #data.pastInfo == 3 then -- 所有玩家都叫过一遍，选取倍速最高的成为地主
		local index
		local max = 0
		for i=1,3 do
			if data.pastInfo[i].times>max then
				index = i
				max = data.pastInfo[i].times
			end
		end
		if max == 0 then -- 没有人叫地主,游戏结束
			data.state = game.STATE_OVER
			return true,data.state
		else -- 否则分最高的人成为地主
			data.state = game.STATE_PLAY
			data.curPlayIndex = data.players[data.pastInfo[index].uid].index
			for i=1,#data.baseCards do
				table.insert(data.players[data.players[data.curPlayIndex]].resCards,data.baseCards[i])
			end
			return true,data.state
		end
	end

	if times == 3 then -- 叫三分的人成为地主
		data.state = game.STATE_PLAY
		data.curPlayIndex = data.players[uid].index
		for i=1,#data.baseCards do
			table.insert(data.players[data.players[data.curPlayIndex]].resCards,data.baseCards[i])
		end
	else
		data.curPlayIndex = data.curPlayIndex % 3 + 1
	end
	
	return true,data.state
end


function game.pass(rid,uid) -- 过牌
	local data = game.data[rid]
	if data[uid].index ~= data.curPlayIndex then -- 没有轮到当前玩家出牌
		return false
	end
	table.insert(data.pastInfo,{uid = uid})
	data.curPlayIndex = data.curPlayIndex % 3 + 1
	return true
end

function game.play(rid,uid,cards) --返回第一个boolean表示出牌是否成功，第二个表示是否结束比赛并获胜
	assert(type(cards) == "table")
	local data = game.data[rid]
	if data.players[uid].index ~= data.curPlayIndex then -- 没有轮到当前玩家出牌
		return false
	end
	local lastInfo = data.pastInfo[#data.pastInfo]
	if lastInfo then
		lastInfo = lastInfo.info
	end

	local ok,info = canPlay(cards,lastInfo)
	if ok then
		local res = data.players[uid].resCards
		for i=1,#cards do
			local find = false
			for k=1,#res do
				if res[k] == cards[i] then
					table.remove(res,k)	
					find = true
					break
				end
			end
			assert(find,"no find the card in player")
		end
		table.insert(data.pastInfo,{uid = uid,cards = cards,info = info})
		if #res==0 then
			data.winer = uid
			data.state = game.STATE_OVER
			return true,true
		end
		data.curPlayIndex = data.curPlayIndex % 3 + 1
		return true,false
	end
	return false
end

local function sub(t1,t2)
	for i=1,#t2 do
		for t=1,#t1 do
			if t2[i] == t1[t] then
				table.remove(t1,t)
				break
			end
		end
	end
end

function game.tip(cards,compInfo)
	assert(type(cards) == "table")

	local oCards = {}
	local key = {}
	local num = {{},{},{},{}}
	local res = {}
	for i=1,15 do
		key[i] = {}
	end
	for _,v in ipairs(cards) do
		table.insert(oCards,v)
	end
	local sortFun = function (c1,c2)
		local v1 = cardUtils.getValue(c1)
		local v2 = cardUtils.getValue(c2)
		if v1 == v2 then
			return c1 < c2			
		elseif comp(v2,v1) then
			return true
		end
		return false
	end
	table.sort(oCards,sortFun)

	for _,v in ipairs(oCards) do
		local value = v%100
		table.insert(key[value],v)
	end
	for i=1,#cardOder do
		if #key[cardOder[i]] == 1 then
			table.insert(num[1],key[i][1])
		elseif #key[cardOder[i]] == 2 then
			table.insert(num[2],{key[i][1],key[i][2]})
			table.insert(num[1],key[i][1])
		elseif #key[cardOder[i]] == 3 then
			table.insert(num[3],{key[i][1],key[i][2],key[i][3]})
			table.insert(num[2],{key[i][1],key[i][2]})
			table.insert(num[1],key[i][1])
		elseif #key[cardOder[i]] == 4 then
			table.insert(num[4],{key[i][1],key[i][2],key[i][3],key[i][4]})
			table.insert(num[3],{key[i][1],key[i][2],key[i][3]})
			table.insert(num[2],{key[i][1],key[i][2]})
			table.insert(num[1],key[i][1])
	end

	local hasKindBomb = #key[14]==1 and #key[15]==1
	local kingBomb = nil
	if hasKingBomb then
		kingBomb = {514,515}
	end

	if compInfo[1] == game.CARD_KINGBOMB then
		return res
	elseif compInfo[1] == game.CARD_BOMB then
		if #num[4] ~= 0 then
			for _,v in ipairs(num[4]) do
				if comp(cardUtils.getValue(v[1]),compInfo[3]) then
					table.insert(res,v)
				end
			end
		end
		table.insert(res,kingBomb)
		return res
	elseif compInfo[1] == game.CARD_ONE or compInfo[1] == game.CARD_PAIR or compInfo[1] == game.CARD_THREE then
		for _,v in ipairs(num[compInfo[1]]) do
			if comp(cardUtils.getValue(v[1]),compInfo[3]) then
				table.insert(res,v)
			end
		end
	elseif compInfo[1] == game.CARD_THREEONE or compInfo[1] == game.CARD_THREEPAIR then
		for _,v in ipairs(num[3]) do
			if comp(cardUtils.getValue(v[1]),compInfo[3]) then
				table.insert(res,v)
			end
		end

		if compInfo[1] == game.CARD_THREEONE then
			for i=#res,1 do
				sub(oCards,res[i])
				if #oCards > 0 then
					local temp = oCards[i]
					for _,tmp = res[i] do -- 还原
						table.insert(oCards,tmp)
					end
					table.sort(oCards,sortFun)
					table.insert(res[i],temp)
					break
				else
					table.remove(res,i)
				end
			end
		else
			for i=#res,1 do
				local find = false
				for _,p in ipairs(num[2]) do
					if cardUtils.getValue(p[1]) ~= cardUtils.getValue(res[i][1]) then
						find = true
						table.insert(res[i],p)
						break
					end
				end
				if not find then
					table.remove(res,i)
				end
			end
		end
	elseif compInfo[1] == game.CARD_FOURTWO then
		for i,v in ipairs(num[4]) do
			local value = cardUtils.getValue(v[1])
			if comp(value,compInfo[3]) then
				if compInfo[2] == 6 then
					sub(oCards,v)
					if #oCards > 1 then
						table.insert(res,v)
						table.insert(res[#res],oCards[1])
						table.insert(res[#res],oCards[2])
					end
					for _,c in ipairs(v)
						table.insert(oCards,c)
					end
					table.sort(oCards,sortFun)
				else
					if #num[2] > 2 then
						local tmp = nil
						for i,v in ipairs(num[2]) do
							if cardUtils.getValue(v[1]) == value then
								tmp = v
								table.remove(num[2],i)
								break
							end
						end
						table.insert(res,v)
						table.insert(res[#res],num[2][1])
						table.insert(res[#res],num[2][2])
						table.insert(num[2],tmp)
					end
				end
			end
		end
	elseif compInfo[1] == game.CARD_CONNECT then
		if compInfo[3] + compInfo[2] - 1 < 14 then -- 小于A
			for i=1,#num[1] - compInfo[2]+1 do
				if cardUtils.getValue(num[1][i]) > compInfo[2] and cardUtils.getValue(num[1][i+compInfo[2]-1])<14  then
					local ibreak = false
					for t=0,compInfo[2]-2 do
						local v1 = cardUtils.getValue(num[1][i+t])
						local v2 = cardUtils.getValue(num[1][i+t+1])
						if v1 == 1 then
							v1 = 14
						end
						if v2 == 1 then
							v2 = 14
						end
						if  v1 ~= v2-1 then
							ibreak = true
							break
						end
					end
					if not ibreak then
						table.insert(res,{})
						for t=0,compInfo[2]-1 do
							table.insert(res[#res],num[1][i+t])
						end
					end
				end
			end
		end
	elseif compInfo[1] == game.CARD_COMPANY then
		if compInfo[3] + compInfo[2]/2 - 1 < 14 then -- 小于A
			for i=1,#num[2] - compInfo[2]/2+1 do
				if cardUtils.getValue(num[2][i][1]) > compInfo[2] and cardUtils.getValue(num[2][i+compInfo[2]/2-1][1])<14  then
					local ibreak = false
					for t=0,compInfo[2]-2,2 do
						local v1 = cardUtils.getValue(num[2][i+t][1])
						local v2 = cardUtils.getValue(num[2][i+t+2][1])
						if v1 == 1 then
							v1 = 14
						end
						if v2 == 1 then
							v2 = 14
						end
						if  v1 ~= v2-1 then
							ibreak = true
							break
						end
					end
					if not ibreak then
						table.insert(res,{})
						for t=0,compInfo[2]-2,2 do
							table.insert(res[#res],num[2][i+t][1])
							table.insert(res[#res],num[2][i+t][2])
						end
					end
				end
			end
		end
	elseif compInfo[1] == game.CARD_AIRCRAFT then
		if compInfo[3] + compInfo[2]/3 - 1 < 14 then -- 小于A
			for i=1,#num[3] - compInfo[2]/3+1 do
				if cardUtils.getValue(num[3][i][1]) > compInfo[2] and cardUtils.getValue(num[3][i+compInfo[2]/3-1][1])<14  then
					local ibreak = false
					for t=0,compInfo[2]-3,3 do
						local v1 = cardUtils.getValue(num[3][i+t][1])
						local v2 = cardUtils.getValue(num[3][i+t+3][1])
						if v1 == 1 then
							v1 = 14
						end
						if v2 == 1 then
							v2 = 14
						end
						if  v1 ~= v2-1 then
							ibreak = true
							break
						end
					end
					if not ibreak then
						table.insert(res,{})
						for t=0,compInfo[2]-3,3 do
							table.insert(res[#res],num[3][i+t][1])
							table.insert(res[#res],num[3][i+t][2])
							table.insert(res[#res],num[3][i+t][3])
						end
					end
				end
			end
		end
	elseif compInfo[1] == game.CARD_AIRCRAFT then
		if compInfo[3] + compInfo[2]/3 - 1 < 14 then -- 小于A
			for i=1,#num[3] - compInfo[2]/3+1 do
				if cardUtils.getValue(num[3][i][1]) > compInfo[2] and cardUtils.getValue(num[3][i+compInfo[2]/3-1][1])<14  then
					local ibreak = false
					for t=0,compInfo[2]-3,3 do
						local v1 = cardUtils.getValue(num[3][i+t][1])

						local v2 = cardUtils.getValue(num[3][i+t+3][1])
						if v1 == 1 then
							v1 = 14
						end
						if v2 == 1 then
							v2 = 14
						end
						if  v1 ~= v2-1 then
							ibreak = true
							break
						end
					end
					if not ibreak then
						table.insert(res,{})
						for t=0,compInfo[2]/3 do
							table.insert(res[#res],num[3][i+t][1])
							table.insert(res[#res],num[3][i+t][2])
							table.insert(res[#res],num[3][i+t][3])
						end
					end
				end
			end
		end
	elseif compInfo[1] == game.CARD_AIRCRAFTWING then
		local keyNum = 0
		local otherNum = 0
		local findSingle = true
		if compInfo[2] == 8 or compInfo[2] == 12 then
			otherNum = keyNum = compInfo[2]/4
		elseif compInfo[2] == 10 or compInfo[2] == 15 then
			otherNum = keyNum = compInfo[2]/5
			findSingle = false
		end
		
		if compInfo[3] + keyNum - 1 < 14 then -- 小于A
			for i=1,#num[3] - keyNum+1 do
				if cardUtils.getValue(num[3][i][1]) > compInfo[2] and cardUtils.getValue(num[3][i+keyNum-1][1])<14  then
					local ibreak = false
					for t=0,keyNum-1 do
						local v1 = cardUtils.getValue(num[3][i+t][1])
						local v2 = cardUtils.getValue(num[3][i+t+1][1])
						if v1 == 1 then
							v1 = 14
						end
						if v2 == 1 then
							v2 = 14
						end
						if  v1 ~= v2-1 then
							ibreak = true
							break
						end
					end
					if not ibreak then
						table.insert(res,{})
						for t=0,keyNum-1 do
							table.insert(res[#res],num[3][i+t][1])
							table.insert(res[#res],num[3][i+t][2])
							table.insert(res[#res],num[3][i+t][3])
						end
					end
				end
			end
		end
		if #res > 0 then
			for i=1,#res do
				if findSingle then
					sub(oCards,res[i])
					for t=otherNum,1 do
						table.insert(res[i],oCards[t])
						table.remove(oCards,t)
					end
					for t=1,#res[i] do
						table.insert(oCards,res[i][t])
					end
					table.sort(oCards,sortFun)
				else
					for i=1,#res do
						for r=1,keyNum do
							 for t=1,#num[2] do
							 	if cardUtils.getValue(num[2][t][1]) == cardUtils.getValue(res[i][r*3]) then
							 		table.remove(num[2],t)
							 		break
							 	end
							 end
						end
						if #num[2] >= otherNum then
							for t=otherNum,1 do
								table.insert(res[i],num[2][t][1])
								table.insert(res[i],num[2][t][2])
								table.remove(num[2],t)
							end
						else
							res = {}
							break
						end
						for r=1,#res[i] do
							local v1 = cardUtils.getValue(res[r])
							local v2 = cardUtils.getValue(res[r+1])
							local v3 = cardUtils.getValue(res[r+2])
							table.insert(num[2],{res[r],res[r+1]})
							if v1 == v2 and v1 == v3 then
								r = r+2
							else
								r = r+1
							end
						end
					end
				end
			end
		end
	elseif compInfo[1] == game.CARD_BOMB then
		for i=1,#num[4] do
			if comp(cardUtils.getValue(num[4][i][1]),compInfo[3]) then
				table.insert(res,num[4][i])
			end
		end
	end

	if compInfo[1] ~= game.CARD_BOMB then
		for i=1,#num[4] do
			table.insert(res,num[4][i])
		end
	end
	table.insert(res,kingBomb)
	return res
end

return game

