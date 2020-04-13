local players = game:GetService("Players")

local methods = rs.methods

local to_unicode = function(string)
    local codepoints = "utf8.char("
    
    for i,v in utf8.codes(string) do
        codepoints = codepoints .. v .. ', '
    end
    
    return codepoints:sub(1, -3) .. ')'
end

local userdata_value = function(data)
    local type = typeof(data)

    if type == "Instance" then
        return methods.get_path(data)
    elseif 
        type == "Vector3" or
        type == "Vector2" or
        type == "CFrame" or
        type == "Color3" 
    then
        return type .. ".new(" .. tostring(data) .. ")"
    elseif type == "CFrame" then
        return "CFrame.new(" .. tostring(data) .. ")"
    elseif type == "Color3" then
        return "Color3.new(" .. tostring(data) .. ")"
    elseif type == "Ray" then
        local split = tostring(data):split('}, ')
        local origin = split[1]:gsub('{', "Vector3.new("):gsub('}', ')')
        local direction = split[2]:gsub('{', "Vector3.new("):gsub('}', ')')
        return "Ray.new(" .. origin .. "), " .. direction .. ')'
    elseif type == "ColorSequence" then
        return "ColorSequence.new(" .. methods.data_to_string(v.Keypoints) .. ')'
    elseif type == "ColorSequenceKeypoint" then
        return "ColorSequenceKeypoint.new(" .. data.Time .. ", Color3.new(" .. tostring(data.Value) .. "))" 
    end

    return tostring(data)
end

methods.to_string = function(value)
    local data_type = typeof(value)

    if data_type == "userdata" or data_type == "table" then
        local mt = rs.methods.get_metatable(value)
        local __tostring = mt and rawget(mt, "__tostring")

        if not mt or (mt and not __tostring) then 
            return tostring(value) 
        end

        rawset(mt, "__tostring", nil)
        
        value = tostring(value)
        
        rawset(mt, "__tostring", __tostring)

        return value 
    elseif type(value) == "userdata" then
        return userdata_value(value)
    else
        return tostring(value) 
    end
end

methods.get_path = function(instance)
    local head = '.' .. instance.Name
    
    if not instance.Parent and instance ~= game then
        return head .. " --[[ PARENTED TO NIL OR DESTOYED ]]"
    end
    
    if instance == game then
        return "game"
    elseif instance == workspace then
        return "workspace"
    else
        local success, result = pcall(game.GetService, game, instance.ClassName)
        
        if result then
            head = ':GetService("' .. instance.ClassName .. '")'
        elseif instance == players.LocalPlayer then
            head = '.LocalPlayer' 
        elseif instance.Name:gsub('_', ''):find('%W') then
            head = '[' .. to_unicode(instance.Name) .. ']'
        end
    end
    
    return methods.get_path(instance.Parent) .. head
end

methods.data_to_string = function(data, indents)
    local data_type = type(data)

    if data_type == "userdata" then
        return userdata_value(data)
    elseif data_type == "string" then
        if #(data:gsub('%w', ''):gsub('%s', ''):gsub('%p', '')) > 0 then
            return to_unicode(data)
        else
            return ('"%s"'):format(data:gsub('"', '\\"'))
        end
    elseif data_type == "table" then
        indents = indents or 1
        
        local head = '{\n'
        local elements = 0
        local indent = ('\t'):rep(indents)
        
        for i,v in pairs(data) do
            if i ~= data and v ~= data then
                head = head .. ("%s[%s] = %s,\n"):format(indent, methods.data_to_string(i, indents + 1), methods.data_to_string(v, indents + 1))
            else
                head = head .. ("%sHUSH_CYCLIC_PROTECTION,\n"):format(indent)
            end

            elements = elements + 1
        end
        
        if elements > 0 then
            return ("%s\n%s"):format(head:sub(1, -3), ('\t'):rep(indents - 1) .. '}')
        else
            return "{}"
        end
    end

    return tostring(data)
end