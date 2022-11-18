---
--- Created by Niklas.
--- DateTime: 8/10/2022 8:20 PM
--- Describtion:
---         DosLib is a interpreted programming language written in Lua 
---         with a syntax very similar to assembly. 
---         DosLib uses instructions (put, pop, ...) to modify values of variables ("registers").
---         
---         It's not really meant to be a serious programming language. I created it out of fun.
---         There surely are some missing core-features like propper error-handling (it has non).
---         However I learned a lot from creating this programming language and it was quiet fun.
---         I might create a Version 2 of DosLib someday.
---
---         ##### Documentation for the instructions can be seen in the "INFO.txt" file! ##### 
---
---         If you encounter bugs or want to suggest features/ functions feel free to contact me.
--- 
---         E-Mail: niklashamann0405@gmail.com            
---
---
---         INFO: THE CODE MAY NOT BE FULLY OPTIMIZED! I AM WORKING ON THAT AND PUSH AN UPDATE ASAP!
---
---

local DosLib = require("DosLib")


-- local Decode = require("Decode")
local ARRAYS = {}
local POINTERS = {}
local STACK = {}
local BUILD_IN_FUNCTIONS = require("FUNCS")
local ACCUMULATOR = 0
local REGISTERS = {}


local function Decode(INPUT)
    local LinePos = 1
    local CurrentWord = ""
    local Decoded = {}

    for pos = 1, #INPUT do
        local char = INPUT:sub(pos, pos)

        if (char == "\n") then
            if (CurrentWord ~= "") then
                table.insert(Decoded, #Decoded+1, { Word = CurrentWord; Line = LinePos })
                LinePos = LinePos + 1
                CurrentWord = ""
            end

        elseif (char == " ") then
            if (CurrentWord ~= "") then
                table.insert(Decoded, #Decoded+1, { Word = CurrentWord; Line = LinePos })
                CurrentWord = ""
            end
        else
            if (char ~= "\t" and char ~= " " and char ~= "\n") then
                CurrentWord = CurrentWord..char
            end
        end
    end

    return Decoded
end


--//    Syntax
local function Syntax(DecodedInput)

    local function arrPrint(Keyword)
        local res = "{ "
        for i, c in pairs(ARRAYS[Keyword]) do
            res = res..tostring(c)..", "
        end

        -- removes the last ","
        res = res:sub(1, #res-2)

        res = res.." }"
        return res
    end

    local function UpdatePointers()
        for i, pointer in pairs(POINTERS) do
            POINTERS[i] = pointer+1
        end
    end

    --- @param Word string
    local function GetVal(Word)
        if (#Word-1 <= 2 and Word:sub(1,1) == "r") then -- register
            local BufferX = tonumber(Word:sub(2))
            return REGISTERS[BufferX]

        elseif (Word:sub(1,1) == "*") then  -- pointer
            return STACK[POINTERS[Word]]

        elseif (Word == "acc") then -- accumulator
            return ACCUMULATOR

        elseif (Word:sub(1,1) == "!") then  -- array
            return arrPrint(Word:sub(2))

        else    -- other
            if (tonumber(Word)) then    -- number
                return tonumber(Word)
            end

            -- string
            return Word
        end
    end

    local function ConstructArray(CurrentPos)
        local Token = DecodedInput[CurrentPos]
        local NewCurrent = CurrentPos

        local array = {array={}, Current=NewCurrent}

        while (Token) do
            if (Token.Word == ">") then
                return array
            end

            table.insert(array.array, GetVal(Token.Word))
            array.Current = array.Current  + 1
            Token = DecodedInput[array.Current]
        end

        return array
    end

    local function ConstructFunction(CurrentPos)
        local Token = DecodedInput[CurrentPos]
        local NewCurrent = CurrentPos

        local FunctionBody = {Body={}, Current=NewCurrent}

        while (Token) do
            if (Token.Word == ")") then
                return FunctionBody
            end

            table.insert(FunctionBody.Body, Token)
            FunctionBody.Current = FunctionBody.Current  + 1
            Token = DecodedInput[FunctionBody.Current]
        end

        return FunctionBody
    end


    local Current = 1

    while true do
        if (not DecodedInput) then break end
        if (not DecodedInput[Current]) then break end

        local Word = DecodedInput[Current].Word
        local NextWord = nil
        if (DecodedInput[Current+1]) then
            NextWord = DecodedInput[Current+1].Word
        end

        if (Word == "pop") then
            if (#NextWord==2 or #NextWord==3 and NextWord:sub(1,1)=="r") then
                local BufferX = tonumber(NextWord:sub(2)) or 1

                REGISTERS[BufferX] = STACK[1]
                table.remove(STACK, 1)

                for i, pointer in pairs(POINTERS) do
                    POINTERS[i] = pointer-1
                    if (pointer-1==0) then
                        POINTERS[i] = nil
                    end
                end
                Current = Current + 1
            end

        elseif (Word == "prt") then
            if (NextWord) then
                local Vals = {}
                local now = Current + 1
                local startLine = DecodedInput[Current].Line
                local End = false

                while true do
                    if (not DecodedInput[now]) then break end
                    if (DecodedInput[now].Line ~= startLine or End) then
                        break
                    end
                    local i_NEXT = GetVal(DecodedInput[now].Word)
                    if (i_NEXT == "::END") then
                        i_NEXT = ""
                        End = true
                    end
                    table.insert(Vals, i_NEXT) 
                    now = now + 1
                end

                print(table.concat(Vals, " "))
                Current = now - 1
            end


        elseif (Word == "add") then -- addition command
            if (NextWord) then
                if (DecodedInput[Current+2]) then
                    local ThirdWord = DecodedInput[Current+2].Word
                    local AddTo = GetVal(ThirdWord)
                    local Value = GetVal(NextWord)

                    local BufferX = tonumber(ThirdWord:sub(2)) or 1
                    REGISTERS[BufferX] = Value + AddTo

                    Current = Current + 2
                end
            end

        elseif (Word == "put") then -- storing command
            if (NextWord) then
                if (DecodedInput[Current+2]) then
                    local ThirdWord = DecodedInput[Current+2].Word
                    local Value = GetVal(NextWord)

                    if (ThirdWord ~= "stack") then
                        local BufferX = tonumber(ThirdWord:sub(2)) or 1
                        REGISTERS[BufferX] = Value
                    else
                        table.insert(STACK, 1, Value)

                        UpdatePointers()
                    end

                    if (DecodedInput[Current+3]) then
                        if (DecodedInput[Current+3].Word == "point") then
                            POINTERS[DecodedInput[Current+4].Word] = 1
                        end
                    end
                    Current = Current + 2
                end
            end

        elseif (Word == "exp") then
            if (NextWord) then
                if (DecodedInput[Current+2]) then
                    local ThirdWord = DecodedInput[Current+2].Word
                    local AddTo = GetVal(ThirdWord)
                    local Value = GetVal(NextWord)

                    local BufferX = tonumber(ThirdWord:sub(2)) or 1
                    REGISTERS[BufferX] = AddTo ^ Value

                    Current = Current + 2
                end
            end

        elseif (Word == "sub") then -- subtract command
            if (NextWord) then
                if (DecodedInput[Current+2]) then
                    local ThirdWord = DecodedInput[Current+2].Word
                    local AddTo = GetVal(ThirdWord)
                    local Value = GetVal(NextWord)

                    local BufferX = tonumber(ThirdWord:sub(2)) or 1
                    REGISTERS[BufferX] = AddTo - Value

                    Current = Current + 2
                end
            end

        elseif (Word == "del") then -- deletion command
            if (NextWord) then
                if (#NextWord == 2 and NextWord:sub(1,1) == "r") then
                    local BufferX = tonumber(NextWord:sub(2)) or 1
                    REGISTERS[BufferX] = nil

                elseif (NextWord:sub(1,1) == "*") then
                    POINTERS[NextWord] = nil

                elseif (NextWord == "acc") then
                    ACCUMULATOR = 0
                end
            end

        elseif (Word == "mul") then -- multiplier command
            if (NextWord) then
                if (DecodedInput[Current+2]) then
                    local ThirdWord = DecodedInput[Current+2].Word
                    local AddTo = GetVal(ThirdWord)
                    local Value = GetVal(NextWord)

                    local BufferX = tonumber(ThirdWord:sub(2)) or 1
                    REGISTERS[BufferX] = Value * AddTo

                    Current = Current + 2
                end
            end

        elseif (Word == "div") then     -- division command
            if (NextWord) then
                if (DecodedInput[Current+2]) then
                    local ThirdWord = DecodedInput[Current+2].Word
                    local AddTo = GetVal(ThirdWord)
                    local Value = GetVal(NextWord)

                    local BufferX = tonumber(ThirdWord:sub(2)) or 1
                    REGISTERS[BufferX] = AddTo / Value

                    Current = Current + 2
                end
            end

        elseif (Word == "str") then
            -- str [add/sub/rep] "string" [r1/r2/r3]

            local ThirdWord  = DecodedInput[Current+2]
            local FourthWord = DecodedInput[Current+3]

            if (NextWord) then
                if (NextWord == "add") then
                    local reg = tonumber(FourthWord.Word:sub(2)) or 1
                    REGISTERS[reg] = REGISTERS[reg].." "..ThirdWord.Word

                elseif (NextWord == "sub") then
                    local reg = tonumber(FourthWord.Word:sub(2)) or 1
                    REGISTERS[reg] = string.sub(REGISTERS[reg], 0, -(tonumber(ThirdWord.Word)+1))

                elseif (NextWord == "rep") then -- replace
                    
                end
            end

            Current = Current + 3

        elseif (Word == "arr") then
            -- arr mak SomeArray < *pointer r1 r2 r3 r4 Hello 100 >
            -- arr idx SomeArray INDEX -> outputs value to accumulator (acc)
            -- arr rem SomeArray INDEX
            -- arr add SomeArray SomeValue -> adds SomeValue to SomeArray at bottom position // position set in accumulator (acc)
            -- arr sze SomeArray -> outputs size to accumulator (acc)
            -- arr has SomeArray SomeValue -> outputs result to accumulator (acc)
            local ArrayName = GetVal(DecodedInput[Current+2].Word)

            if (NextWord) then
                if (NextWord == "mak") then
                    if (DecodedInput[Current+3].Word == "<") then
                        local Array = ConstructArray(Current+4)
                        ARRAYS[ArrayName] = Array.array
                        Current = Array.Current
                    end

                elseif (NextWord == "rep") then
                    ARRAYS[ArrayName][GetVal(DecodedInput[Current+3].Word)] = GetVal(DecodedInput[Current+4].Word)
                    Current = Current + 4

                elseif (NextWord == "idx") then
                    ACCUMULATOR = ARRAYS[ArrayName][GetVal(DecodedInput[Current+3].Word)]
                    Current = Current + 3

                elseif (NextWord == "rem") then
                    local TargetIdx = tonumber(GetVal(DecodedInput[Current+3].Word)) or 1


                    table.remove(ARRAYS[ArrayName], TargetIdx)

                    Current = Current + 3

                elseif (NextWord == "add") then
                    table.insert(ARRAYS[ArrayName], GetVal(DecodedInput[Current+3]))
                    Current = Current + 3

                elseif (NextWord == "sze") then
                    ACCUMULATOR = #ARRAYS[ArrayName]
                    Current = Current + 2

                elseif (NextWord == "has") then
                    local found = false
                    for idx, element in pairs(ARRAYS[ArrayName]) do
                        if (element == GetVal(DecodedInput[Current+3].Word)) then
                            ACCUMULATOR = idx
                            found = true
                            break
                        end
                    end

                    if (not found) then ACCUMULATOR = 0 end
                    Current = Current + 3
                end
            end


        elseif (Word == "inp") then -- user input (Numbers only)

            if (NextWord == "INT") then
                local Input = DosLib.In.ReadNum() or 0
                ACCUMULATOR = Input

            elseif (NextWord == "STR") then
                local Input = io.read() or "NAN"
                ACCUMULATOR = Input

            else
                print("INVALID TYPE FOR INPUT")
                ACCUMULATOR = 0
            end
            Current = Current + 1

        elseif (Word == "com") then -- comparing two "registers"

            if (NextWord) then
                local OPERATIONS = {"<", ">", "==", "~=", ">=", "<="}
                local OPERATION = DecodedInput[Current+2].Word

                local _4th = DecodedInput[Current+3].Word

                if (DosLib.Table.find(OPERATIONS, OPERATION)) then

                    local RESULT
                    if (tonumber(GetVal(NextWord)) and tonumber(GetVal(_4th))) then
                        RESULT = load("return "..GetVal(NextWord).." "..OPERATION.." "..GetVal(_4th))()
                    else
                        RESULT = load("return \""..GetVal(NextWord).."\" "..OPERATION.." \""..GetVal(_4th).."\"")()
                    end

                    if (RESULT) then
                        ACCUMULATOR = 2
                    else
                        ACCUMULATOR = 1
                    end

                    if (DecodedInput[Current+4]) then
                        if (DecodedInput[Current+4].Word == "goto") then

                            -- if statement is true do this function
                            if (RESULT) then Syntax(BUILD_IN_FUNCTIONS[DecodedInput[Current+5].Word]) end

                            -- if there is an optional function
                            if (DecodedInput[Current+6]) then
                                if (DecodedInput[Current+6].Word == "??") then

                                    -- if the statement is false, do this optional function
                                    local OtherFunc = DecodedInput[Current+7].Word
                                    if (not RESULT) then
                                        Syntax(BUILD_IN_FUNCTIONS[OtherFunc])
                                    end
                                    Current = Current + 2
                                end
                            end

                            Current = Current + 2
                        end
                    end

                else print("INVALID")
                end

                Current = Current + 3
            end

        elseif (Word == "goto") then
            if (NextWord) then
                Syntax(BUILD_IN_FUNCTIONS[NextWord]) -- building method
            end

        else
            if (NextWord) then
                if (NextWord == "(") then
                    local Body = ConstructFunction(Current+2)

                    BUILD_IN_FUNCTIONS[Word] = Body.Body

                    Current = Body.Current
                end
            end
        end

        Current = Current + 1

        if (Current > #DecodedInput) then   -- break when all instructions are executed
            break
        end
    end
end


-- loading files
local InputFile = io.read()

if (InputFile:sub(#InputFile-4, #InputFile) == ".dosb") then

    local file = io.open(InputFile)
    if (not file) then return end

    local FILE_CONTENT = file:read("a")

    local start = os.clock()

    local Decoded = Decode(FILE_CONTENT)
    Syntax(Decoded)

    io.write("FINISHED IN: "..tostring(os.clock()-start).."\n")
    io.write("PRESS \"ENTER\" TO END THE PROGRAM")
    io.read()

        file:close()
else
    print("INVALID FILE!")
end




