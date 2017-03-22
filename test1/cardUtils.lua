--
-- Author: hxl
-- Date: 2017-03-21 14:38:19
--
local cardUtils = {}

local _defaultCompFun = function (card1,card2) -- 默认降序排序
	assert(cardUtils.isCard(card1) and cardUtils.isCard(card2))
	local v1 = card1%100
	local v2 = card2%100
	if v1 > v2 then
		return true
	elseif v1 < v2 then
		return false
	end

	local suit1 = cardUtils.getSuit(card1)
	local suit2 = cardUtils.getSuit(card2)
	return suit1 > suit2

end

local _compFun = _defaultCompFun

function cardUtils.getOriginCard(num,disarrange)
	num = num or 1
	if disarrange  == nil then
		disarrange = true
	end
	local card = {}
	for k=1,num do
		for i=1,4 do
			for t=1,13 do
				table.insert(card,i*100+t)
			end
		end
		table.insert(card,514) --小王
		table.insert(card,515) -- 大王
	
	end
	if not disarrange then
		return card
	end

	math.randomseed(tostring(os.time()):reverse())
	for i=1,#card do
		local index = math.random(i,#card)
		card[i],card[index] = card[index],card[i]
	end
	return card
end

--获得扑克牌的牌值   
function cardUtils.getValue(card)  
  return card % 100  
end  
  
--获得扑克牌的花色  
function cardUtils.getSuit(card)  
  return math.floor(card / 100 )
end  


--测试所有的牌是否都是扑克牌  
function cardUtils.isCard(cards)  
	assert(type(cards) == "number" or type(cards) == "table")
	local t = cards
	if type(t) == "number" then
		t = {t}
	end
	for _,c in pairs(t) do  
		if c < 100 then  
		  if  1 > c or  15 < c then  
		    return false  
		  end  
		else   
			local v = cardUtils.getValue(c)
		  if v > 15 or v < 1 then  
		    return false  
		  end  
		end  
	end  
	return true  
end  



function cardUtils.setCompFun(fun)
	if fun == nil then
		_compFun = _defaultCompFun
	else
		_compFun = fun
	end
end 

function cardUtils.getCompFun()
	return _compFun
end 

function cardUtils.hasRepeatCard(cards)
	-- local s = table.concat(cards," ")
	-- string.
end 

function cardUtils.sort(cards,sortStr)
	assert(type(cards) == "table")
	assert(cardUtils.isCard(cards))
	sortStr = sortStr or ">"
	if sortStr == ">" then -- 降序排序
		local buf = {}
		for _,v in ipairs(cards) do
			table.insert(buf,v)
		end
		table.sort(buf,_compFun)
		return buf
	elseif sortStr == "<"then -- 升序排序
		local buf = {}
		for _,v in ipairs(cards) do
			table.insert(buf,v)
		end
		table.sort(buf,function(card1,card2)
			return _compFun(card2,card1)
			end)
		return buf
	elseif sortStr == "c"then -- 按花色排序
		local suit = {}
		suit[1] = {}
		suit[2] = {}
		suit[3] = {}
		suit[4] = {}
		suit[5] = {}
		for i,v in ipairs(cards) do
			table.insert(suit[cardUtils.getSuit(v)],v)
		end
		table.sort(suit,function(t1,t2)
			if t1[1] and cardUtils.getSuit(t1[1]) == 5 then -- 王排在最前
				return true
			end
			if t2[1] and cardUtils.getSuit(t2[1]) == 5 then -- 王排在最前
				return false
			end
			if #t1 > #t2 then --花色多的排在前面
				return true
			elseif #t1 == #t2 then
				if #t1 ~= 0 then
					if cardUtils.getSuit(t1[1]) > cardUtils.getSuit(t2[1]) then
						return true
					end
				end
			end
			return false
		end)
		local res = {}
		for i=1,#suit do
			table.sort(suit[i],_defaultCompFun)
			for _,v in ipairs(suit[i]) do
				table.insert(res,v)
			end
		end
		return res
	elseif sortStr == "p"then -- 按对子排序
		local buf = {}
		for i=1,15 do
			buf[i] = {}
		end
		for _,v in ipairs(cards) do
			value = v%100
			table.insert(buf[value],v)
		end
		for _,v in ipairs(buf) do
			table.sort(v,_defaultCompFun)
		end
		table.sort(buf,function (t1,t2)
			if t1[1] and t2[1] and cardUtils.getSuit(t1[1]) == 5 and cardUtils.getSuit(t2[1]) == 5 then --两个王对比
				return t1[1] > t2[1]
			end
			if t1[1] and cardUtils.getSuit(t1[1]) == 5 then -- 王排在最前
				return true
			end
			if t2[1] and cardUtils.getSuit(t2[1]) == 5 then -- 王排在最前
				return false
			end
			if #t1 > #t2 then
				return true
			elseif #t1 == #t2 and #t1 ~= 0 then
				if cardUtils.getValue(t1[1]) > cardUtils.getValue(t2[1]) then -- 牌大的排前面
					return true
				end
			end
			return false
		end)
		local res = {}
		for i=1,#buf do
			if #buf[i] == 0 then
				break
			end
			for t=1,#buf[i] do
				table.insert(res,buf[i][t])
			end
		end
		return res
	end
end  

return cardUtils