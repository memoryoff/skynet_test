--
-- Author: hxl
-- Date: 2017-03-21 14:12:02
--

local cardUtils = require "cardUtils"
----各种牌型的对应数字  
local ERROR_CARD = 0 --错误牌型  
local SINGLE_CARD = 1 --单牌    
local DOUBLE_CARD = 2 --对子    
local THREE_CARD = 3 --3不带    
local THREE_ONE_CARD = 4 --3带1    
local THREE_TWO_CARD = 5 --3带2    
local BOMB_TWO_CARD = 6 --四个带2张单牌    
local BOMB_FOUR_CARD = 7 --四个带2对    
local CONNECT_CARD = 8 --连牌    
local COMPANY_CARD = 9 --连队,三对或更多的连续对牌
local AIRCRAFT_CARD = 10 --飞机不带,二个或更多的连续三张牌（如：333444 、 555 666 777 888）。不包括 2 点和双王。
local AIRCRAFT_WING = 11 --飞机带单牌或对子  ,三顺+同数量的单牌（或同数量的对牌）。
local BOMB_CARD = 12 --炸弹    
local KINGBOMB_CARD = 13 --王炸  



local game_start = 1
local game_playing = 2
local game_end = 3

local game = {}

function game.init(rid,room)
	local card = {}
	for i=1,4 do
		for t=1,13 do
			table.insert(card,i*100+t)
		end
	end
	table.insert(card,514) --小王
	table.insert(card,515) -- 大王
	math.randomseed(tostring(os.time()):reverse())
	for i=1,#card do
		local index = math.random(i,#card)
		card[i],card[index] = card[index],card[i]
	end

	game.data = game.data or {} 
	game.data[rid] = game.data[rid] or {}
	local data = game.data[rid]
	data.ready = false
	local roleChange = false
	for i,uid in ipairs(room[rid]) do
		if not data[uid] then
			roleChange = true
		end
		data[i] = uid
		data[uid] = {}
		data[uid].index = i
		data[uid].restCard = {}
		data[uid].playCard = {}
		data[uid].agent = false
		data[uid].timeStamp = skynet.now()
		for t=1 , 17 do
			table.insert(data[uid].restCard,card[t+(i-1)*17])
		end
	end
	data.baseCard = {}
	data.lastPlayCard = {}
	for i=52,54 do
		table.insert(data.baseCard,card[i])	
	end

	if not roleChange then
		data.callIndex = data[data.lastWiner].index
	else
		data.callIndex = math.random(1,3)
	end
	return data[data.callIndex]
end




-- 单牌  
function isSingle(cards)  
  if not cardUtils.isCard(cards)then   
      return false  
  end  
  if 1 == #cards then  
    return true  
  end  
  return false  
end  
  
--对子  
function isDouble(cards)  
  if not cardUtils.isCard(cards) then   
      return false  
  end  
  if 2 == #cards then  
    if cards[1] == cards[2] then  
        return true   
    end  
  end  
  return false  
end  
  

  
--3不带 只要判断三个牌值相等  
function isThree(cards)  
  if not cardUtils.isCard(cards) or 3 ~= #cards then   
      return false  
  end  
  if cards[1] == cards[2] and cards[1] == cards[3] then  
      return true   
  end  
  return false  
end  
  
--3带1 先对数字排序 再判断带的牌是在那个位置 （4446，3444）再将带的牌移除判断剩下的三个牌是不是 3不带  
function isThreeOne(cards)  
  if not cardUtils.isCard(cards) or 4 ~= #cards then   
      return false  
  end  
  table.sort(cards)  
  if cards[1] ~=cards[2] then  
    table.remove(cards, 1)  
  else   
    table.remove(cards, 4)  
  end  
  if isThree(cards)  then  
    return true  
  end  
  return false  
end  
  
--3带对子  先排序 头尾都是对子而且中间的牌等于头或者尾的值（55577，44555）  
function isThreeTwo( cards )  
  if not cardUtils.isCard(cards) or 5 ~= #cards then   
      return false  
  end  
  table.sort(cards)  
  if cards[1] == cards[2] and cards[4] == cards[5] then  
    if cards[3] == cards[2] or cards[3] == cards[4] then  
      return true  
    end  
  end  
  return false  
end  

-- 4带2个单
function isBombPairOne(cards)  
  if not cardUtils.isCard(cards) or  #cards ~= 6 then   
      return false  
  end   
  
  table.sort(cards)  
  if cards[1] == cards[2] and cards[1] == cards[3] and cards[1] == cards[4]
  	return true
  elseif cards[3] == cards[4] and cards[3] == cards[5] and cards[3] == cards[6]
  	return true
  end
  return false
end  

-- 4带2个双
function isBombPairTwo(cards)  
  if not cardUtils.isCard(cards) or  #cards ~= 6 then   
      return false  
  end   
  
  table.sort(cards)  
  if cards[1] == cards[2] and cards[1] == cards[3] and cards[1] == cards[4] and cards[5] == cards[6] and cards[7] == cards[8]
  	return true
  elseif cards[1] == cards[2] and cards[3] == cards[4] and cards[5] == cards[6] and cards[5] == cards[7] and cards[5] == cards[8]
  	return true
  end
  return false
end 

--顺子 只要判断相邻的数字数值是否差1就可以  
function isConnect(cards)  
  if not cardUtils.isCard(cards) or 5 > #cards then   
      return false  
  end  
  table.sort(cards)  

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
  		return true
  	end
  end
  for i = 1, (#cards - 1) do  -- 没有1判断是否为顺子
    if cards[i] ~= cards[i+1] -1 then  
      return false  
    end  
  end  
  return true  
end  
  
-- 连对 33445566 1和2 3和4 5和6 7和8 相等 ，2和3 4和5 6和7 相差1   
function isCompany(cards)  
  if not cardUtils.isCard(cards) or 6 > #cards or (#cards % 2) ==1 then   
      return false  
  end  
  table.sort(cards)  
  local len = #cards  
  for i = 1, (len - 1) do  
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
  return true  
end 


-- 飞机不带    
-- 遍历到三个一组中的第一个的时候判断这组的值是否都相等  
-- 遍历到三个一组中的最后一个的时候判断和下一组的数值是不是差一  
function isAircraft(cards)  
  if not cardUtils.isCard(cards) or 6 > #cards or (#cards % 3) ~=0 then   
      return false  
  end   
  table.sort(cards)  
  local len = #cards  
  for i = 1, (len - 1) do  
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
  return true   
end  
  
  
  

  
-- 飞机带翅膀  
function isAircraftWing(cards)  
  if not cardUtils.isCard(cards) or 8 > #cards  then   
      return false  
  end   
  if (#cards % 4) ~=0 and (#cards % 5) ~= 0 then  
    return false  
  end  
  -- 先判断有没有炸弹插成三带一的情况如果有那么将其中一个替换为扑克中没有的数（如 19）  
  table.sort(cards)  
  local tmp = 0 --记录有几个炸弹 防止有多个炸插成三带一  
  for k = 1, (#cards - 4) do  
    if cards[k] == cards[k + 1] and cards[k + 1] == cards[k + 2] and cards[k + 2] == cards[k + 3] then  
      cards[k + 3] = 19 + tmp  
      tmp = tmp + 1  
    end  
  end  
  
  local aircraftCount = math.floor(#cards / 4)  
  table.sort(cards)  
  local tmpTable1 = {} --存放飞机的牌  
  local tmpTable2 = {}  --存放飞机带的牌  
  -- 先从牌中抽出飞机不带  
  for pos = 1, #cards - 2 do  
    if cards[pos] == cards[pos + 1] and cards[pos] == cards[pos + 2] then  
      table.insert(tmpTable1, cards[pos])  
      table.insert(tmpTable1, cards[pos + 1])  
      table.insert(tmpTable1, cards[pos + 2])  
      tmppos = pos  
    end  
  end   
   -- 再得到带的牌  
  for k1, v1 in pairs(cards) do  
    local count = 0  
    for i = 1, aircraftCount do  
      if v1 == tmpTable1[i * 3] then  
        count = count + 1  
      end  
    end  
    if  count == 0 then  
        table.insert(tmpTable2, v1)  
    end   
  end  
  
  if not cardUtils.isAircraft(tmpTable1) then  
    return false  
  end  
  if #tmpTable2 == aircraftCount * 2 then  
    for i = 1, #tmpTable2, 2 do  
      if tmpTable2[i] ~= tmpTable2[i + 1] then  
        return false  
      end  
    end  
  end  
  
  return true  
end 
  
--炸弹  
function isBomb( cards )  
  if not cardUtils.isCard(cards) or 4 ~= #cards then   
      return false  
  end  
  if cards[1] == cards[2] and cards[2] == cards[3] and cards[3] == cards[4] then  
    return true  
  end  
  return false  
end

--王炸  
function isKingBomb(cards)  
  if not cardUtils.isCard(cards) or 2 ~= #cards then   
      return false  
  end  
  table.sort(cards)  
  if cards[1] == 14 and cards[2] == 15 then  
    return true  
  end  
  return false  
end  




 
  
 


















function game.canPlay(rid,uid,card)
	local data = game.data[rid]
	assert(uid == data[data.callIndex],"not the uid player")
	udata = data[uid]
	for _,v in ipairs(card) do
		local find = false
		for _,res in ipairs(udata.restCard) do
			if res == v then
				find = true
				break
			end
		end
		assert(find,"card not find in uid restcard")
	end

	
	
end

function game.play(rid,uid,card)
	local data = game.data[rid]
	assert(uid == data[data.callIndex],"not the uid player")
	udata = data[uid]
	for _,v in ipairs(card) do
		local find = false
		for _,res in ipairs(udata.restCard) do
			if res == v then
				find = true
				break
			end
		end
		assert(find,"card not find in uid rest")
	end



	-- body
end

function game.rule(cardA,cardB)
	-- body
end
