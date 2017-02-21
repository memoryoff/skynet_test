local helper = {}


function helper.serialize(t)
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


function helper.unserialize(lua)  
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

function helper.split(input, delimiter)
    if not input then
        return nil
    end
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

return helper