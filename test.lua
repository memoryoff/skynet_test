--table转字符串(只取标准写法，以防止因系统的遍历次序导致ID乱序)  
function sz_T2S(_t)  
    local szRet = "{"  
    function doT2S(_i, _v)  
        if "number" == type(_i) then  
            szRet = szRet .. "[" .. _i .. "] = "  
            if "number" == type(_v) then  
                szRet = szRet .. _v .. ","  
            elseif "string" == type(_v) then  
                szRet = szRet .. '"' .. _v .. '"' .. ","  
            elseif "table" == type(_v) then  
                szRet = szRet .. sz_T2S(_v) .. ","  
            else  
                szRet = szRet .. "nil,"  
            end  
        elseif "string" == type(_i) then  
            szRet = szRet .. '["' .. _i .. '"] = '  
            if "number" == type(_v) then  
                szRet = szRet .. _v .. ","  
            elseif "string" == type(_v) then  
                szRet = szRet .. '"' .. _v .. '"' .. ","  
            elseif "table" == type(_v) then  
                szRet = szRet .. sz_T2S(_v) .. ","  
            else  
                szRet = szRet .. "nil,"  
            end  
        end  
    end  
    for k,v in pairs(_t) do
        doT2S(k,v)
    end
    -- table.foreach(_t, doT2S)  
    szRet = szRet .. "}"  
    return szRet  
end  
  
  
  
--字符串转table(反序列化,异常数据直接返回nil)  
function t_S2T(_szText)  
    --栈  
    function stack_newStack()  
        local first = 1  
        local last = 0  
        local stack = {}  
        local m_public = {}  
        function m_public.pushBack(_tempObj)  
            last = last + 1  
            stack[last] = _tempObj  
        end  
        function m_public.temp_getBack()  
            if m_public.bool_isEmpty() then  
                return nil  
            else  
                local val = stack[last]  
                return val  
            end  
        end  
        function m_public.popBack()  
            stack[last] = nil  
            last = last - 1  
        end  
        function m_public.bool_isEmpty()  
            if first > last then  
                first = 1  
                last = 0  
                return true  
            else  
                return false  
            end  
        end  
        function m_public.clear()  
            while false == m_public.bool_isEmpty() do  
                stack.popFront()  
            end  
        end  
        return m_public  
    end  
    function getVal(_szVal)  
        local s, e = string.find(_szVal,'"',1,string.len(_szVal))  
        if nil ~= s and nil ~= e then  
            --return _szVal  
            return string.sub(_szVal,2,string.len(_szVal)-1)  
        else  
            return tonumber(_szVal)  
        end  
    end  
  
    local m_szText = _szText  
    local charTemp = string.sub(m_szText,1,1)  
    if "{" == charTemp then  
        m_szText = string.sub(m_szText,2,string.len(m_szText))  
    end  
    function doS2T()  
        local tRet = {}  
        local tTemp = nil  
        local stackOperator = stack_newStack()  
        local stackItem = stack_newStack()  
        local val = ""  
        while true do  
            local dLen = string.len(m_szText)  
            if dLen <= 0 then  
                break  
            end  
  
            charTemp = string.sub(m_szText,1,1)  
            if "[" == charTemp or "=" == charTemp then  
                stackOperator.pushBack(charTemp)  
                m_szText = string.sub(m_szText,2,dLen)  
            elseif '"' == charTemp then  
                local s, e = string.find(m_szText, '"', 2, dLen)  
                if nil ~= s and nil ~= e then  
                    val = val .. string.sub(m_szText,1,s)  
                    m_szText = string.sub(m_szText,s+1,dLen)  
                else  
                    return nil  
                end  
            elseif "]" == charTemp then  
                if "[" == stackOperator.temp_getBack() then  
                    stackOperator.popBack()  
                    stackItem.pushBack(val)  
                    val = ""  
                    m_szText = string.sub(m_szText,2,dLen)  
                else  
                    return nil  
                end  
            elseif "," == charTemp then  
                if "=" == stackOperator.temp_getBack() then  
                    stackOperator.popBack()  
                    local Item = stackItem.temp_getBack()  
                    Item = getVal(Item)  
                    stackItem.popBack()  
                    if nil ~= tTemp then  
                        tRet[Item] = tTemp  
                        tTemp = nil  
                    else  
                        tRet[Item] = getVal(val)  
                    end  
                    val = ""  
                    m_szText = string.sub(m_szText,2,dLen)  
                else  
                    return nil  
                end  
            elseif "{" == charTemp then  
                m_szText = string.sub(m_szText,2,string.len(m_szText))  
                local t = doS2T()  
                if nil ~= t then  
                    szText = sz_T2S(t)  
                    tTemp = t  
                    --val = val .. szText  
                else  
                    return nil  
                end  
            elseif "}" == charTemp then  
                m_szText = string.sub(m_szText,2,string.len(m_szText))  
                return tRet  
            elseif " " ~= charTemp then  
                val = val .. charTemp  
                m_szText = string.sub(m_szText,2,dLen)  
            else  
                m_szText = string.sub(m_szText,2,dLen)  
            end  
        end  
        return tRet  
    end  
    local t = doS2T()  
    return t  
end 


function serialize(t)
    local mark={}
    local assign={}
 
    local function ser_table(tbl,parent)
        mark[tbl]=parent
        local tmp={}
        for k,v in pairs(tbl) do
            local key= type(k)=="number" and "["..k.."]" or k
            if type(v)=="table" then
                local dotkey= parent..(type(k)=="number" and key or "."..key)
                if mark[v] then
                    table.insert(assign,dotkey.."="..mark[v])
                else
                    table.insert(tmp, key.."="..ser_table(v,dotkey))
                end
            else
                if type(v) == "string" then
                    table.insert(tmp, key.."='"..v.. "'")
                else
                    table.insert(tmp, key.."="..v)
                end
                
            end
        end
        return "{"..table.concat(tmp,",").."}"
    end
    
    return ser_table(t,"ret")..table.concat(assign," ")
    -- return "do local ret="..ser_table(t,"ret")..table.concat(assign," ").." return ret end"
end

function unserialize(lua)  
    local t = type(lua)  
    if t == "nil" or lua == "" then  
        return nil  
    elseif t == "number" or t == "string" or t == "boolean" then  
        lua = tostring(lua)  
    else  
        error("can not unserialize a " .. t .. " type.")  
    end  
    lua = "do local ret="..lua.." return ret end"
    local func = load(lua)  
    if func == nil then  
        return nil  
    end  
    return func()  
end  


local t = {name = "hxl",1,2,3,{1,2},fun = "some",other = {"a","b",name = "ohter"}}
-- local s = sz_T2S(t)
print(s)
-- local t2 = t_S2T(s)
-- for k,v in pairs(t2) do
--     print(k,v)
-- end

s = serialize(t)
print(s)
t2 = unserialize(s)
for k,v in pairs(t2) do
    print(k,v)
end