local DosLib = {}
DosLib.Class = {}
DosLib.Math = {}
DosLib.Event = {}
DosLib.Table = {}
DosLib.Out = {}
DosLib.In = {}
DosLib.String = {}

--[[
            OUT LIB
]]
--- Custom error function // kinda useless
DosLib.Out.Error = function(...)
    print(...)
end

--[[
            STRING LIB
]]
DosLib.String.split = function(inputstr, sep)
    local result={}

    if sep == nil then
        sep = "%s"
    end

    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(result, str)
    end

    return result
end


--[[
            IN LIB
]]
--- Only accepts numbers as input
DosLib.In.ReadNum = function()
    local Input
    local Done = false
    while (not Done) do
        Input = io.read()
        if (tonumber(Input)) then
            Done = true
        else
            DosLib.Out.Error("Input has to be a number!")
        end
    end
    return tonumber(Input)
end

--- Only accepts booleans as input
DosLib.In.ReadBool = function()
    local Input = io.read()
    if (Input:lower() == "true") then
        return true
    elseif (Input:lower() == "false") then
        return false
    end
    DosLib.Out.Error("Input has to be a boolean!")
    return false
end

--[[
            TABLE LIB
]]
--- returns either false or the key/id of the given element in a given array/ dictionary
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
function DosLib.Math.Inverse(x) return -x end

--- Calculates an equation within a string
function DosLib.Math.StrEquation(str) return load("return "..str)() end

--[[
            CLASS LIB
]]
--- Creates new class
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
local EventIdList = {}
--- creates new event
function DosLib.Event.new(EventId)

    local ClassDetails = {
        EventId = EventId,
        OnEvent = {
            Connections = {},

            --- Connect a function to the Event
            Connect = function(self, func)
                if (not DosLib.Table.find(self.Connections, func)) then
                    table.insert(self.Connections, func)
                else
                    DosLib.Out.Error("Function is already in Event!")
                end

                return {
                --- returns the disconnector function
                disconnect=function()
                    local Pos = DosLib.Table.find(self.Connections, func)
                    if (Pos) then
                        table.remove(self.Connections, Pos)
                    else
                        DosLib.Out.Error("Function is not in Event!")
                    end
                end}
            end},
            
        Fire = function(self, ...)
            for i, func in pairs(self.OnEvent.Connections) do
                func(...)
            end
        end,

        Reset = function(self)
            for i, func in pairs(self.OnEvent.Connections) do
                self.OnEvent.Connections[i] = nil
            end
        end
    }

    local Event = DosLib.Class.new("Event", ClassDetails)
    EventIdList[EventId] = Event
    return Event
end

--- returns an existing event
function DosLib.Event.get(EventId)
    return EventIdList[EventId] or DosLib.Event.new(EventId)
end

return DosLib