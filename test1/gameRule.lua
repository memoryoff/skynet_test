--
-- Author: hxl
-- Date: 2017-03-21 14:12:02
--
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
  if not CardUtils.isCards(cards)then   
      return false  
  end  
  if 1 == #cards then  
    return true  
  end  
  return false  
end  
  
--对子  
function isDouble(cards)  
  if not CardUtils.isCards(cards) then   
      return false  
  end  
  if 2 == #cards then  
    if cards[1] == cards[2] then  
        return true   
    end  
  end  
  return false  
end  
  
--王炸  
function isKingBomb(cards)  
  if not CardUtils.isCards(cards) or 2 ~= #cards then   
      return false  
  end  
  table.sort(cards)  
  if cards[1] == 16 and cards[2] == 17 then  
    return true  
  end  
  return false  
end  
  
--3不带 只要判断三个牌值相等  
function isThree(cards)  
  if not CardUtils.isCards(cards) or 3 ~= #cards then   
      return false  
  end  
  if cards[1] == cards[2] and cards[1] == cards[3] then  
      return true   
  end  
  return false  
end  
  
--3带1 先对数字排序 再判断带的牌是在那个位置 （4446，3444）再将带的牌移除判断剩下的三个牌是不是 3不带  
function isThreeOne(cards)  
  if not CardUtils.isCards(cards) or 4 ~= #cards then   
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
  if not CardUtils.isCards(cards) or 5 ~= #cards then   
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
  
--炸弹  
function isBomb( cards )  
  if not CardUtils.isCards(cards) or 4 ~= #cards then   
      return false  
  end  
  if cards[1] == cards[2] and cards[2] == cards[3] and cards[3] == cards[4] then  
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
