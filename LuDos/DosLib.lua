local DosLib = {}
DosLib.Class = {}
DosLib.Math = {}
DosLib.Event = {}
DosLib.Table = {}
DosLib.out = {}
DosLib.In = {}

--[[
            OUT LIB
]]
--- Custom error function
--- @return nil
DosLib.out.Error = function(...)
    print(...)
end

--[[
            IN LAB
]]
--- Only accepts numbers as input
--- @return number
DosLib.In.ReadNum = function()
    local Input = io.read()
    if (tonumber(Input)) then
        return tonumber(Input) or 0
    end
    DosLib.out.Error("Input has to be a number!")
    return 0
end

--- Only accepts booleans as input
--- @return boolean
DosLib.In.ReadBool = function()
    local Input = io.read()
    if (Input:lower() == "true") then
        return true
    elseif (Input:lower() == "false") then
        return false
    end
    DosLib.out.Error("Input has to be a boolean!")
    return false
end

--[[
            TABLE LIB
]]
--- returns either false or the key/id of the given element in a given array/ dictionary
--- @param tab table
function DosLib.Table.find(tab, element)
    for i, v in pairs(tab) do
        if (i == element or v == element) then
            return i
        end
    end
    return false
end

--[[
            MATH LIB
]]
--- returns the inverse of the given number
--- @param x number
--- @return number
function DosLib.Math.Inverse(x) return -x end

--- Calculates an equation within a string
--- @param str string
--- @return number
function DosLib.Math.StrEquation(str) return load("return "..str)() end

--[[
            CLASS LIB
]]
--- Creates new class
--- @param ClassName string
--- @param ClassDetails table
--- @return table
function DosLib.Class.new(ClassName, ClassDetails)
    Class = {}
    Class.Name = ClassName

    for i, detail in pairs(ClassDetails) do
        Class[i] = detail
    end

    setmetatable(Class, {})
    Class.__index = Class

    return Class
end

--[[
            EVENT LIB
]]
--- creates new event
--- @param EventId string
--- @return table
function DosLib.Event.new(EventId)
    local ClassDetails = {
        EventId = EventId,
        OnEvent = {
            Connections = {},

            --- Connect a function to the Event
            --- @param func function
            --- @return table
            Connect = function(self, func)
                if (not DosLib.Table.find(self.Connections, func)) then
                    table.insert(self.Connections, func)
                else
                    DosLib.out.Error("Function is already in Event!")
                end

                return {
                --- returns the disconnector function
                --- @return nil
                disconnect=function()
                    local Pos = DosLib.Table.find(self.Connections, func)
                    if (Pos) then
                        table.remove(self.Connections, Pos)
                    else
                        DosLib.out.Error("Function is not in Event!")
                    end
                end}
            end},
            
        Fire = function(self, ...)
            for i, func in pairs(self.OnEvent.Connections) do
                func(...)
            end
        end
    }

    local Event = DosLib.Class.new("Event", ClassDetails)
    return Event
end

return DosLib