---
--- Created by Niklas.
--- DateTime: 8/10/2022 8:20 PM
--- Describtion:
---         DOSB is a programming language written in Lua 
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
---         INFO: THE CODE MAY NOT BE FULLY OPTIMIZED! I AM WORKING ON THAT AND PUSH AN UPDATE ASAP!
---

local DosLib = require("DosLib")

local ARRAYS = {}
local POINTERS = {}

local STACK = {}
local BUILD_IN_FUNCTIONS = require("module")
local BUILD_IN_LOOPS = {}
local ACCUMULATOR
local REGISTERS = {}
local LAMBDABODIES = {}

-- presetting each register with value 0. removing the operation-on-nil error
for i = -9, 99, 1 do
    REGISTERS[i] = 0
end

--keeps track of runtime for randomseed
local BeforeClock = os.time()
math.randomseed(BeforeClock)

-- takes in a string input and returns a table with details about the word (the word itself, Line-Position)
local function Decode(INPUT)
    local Decoded = {}
    local LinePos = 1
    local CurrentWord = ""

    for pos = 1, #INPUT do
        local char = INPUT:sub(pos, pos)

        if char == "\n" then
            if CurrentWord == "" then goto skip end 

            table.insert(Decoded, { Word = CurrentWord, Line = LinePos })

            LinePos = LinePos + 1
            CurrentWord = ""

        elseif char == " " then
            if CurrentWord == "" then goto skip end

            table.insert(Decoded, { Word = CurrentWord, Line = LinePos })
            CurrentWord = ""

        else
            if char ~= "\t" and char ~= " " and char ~= "\n" then
                CurrentWord = CurrentWord..char
            end
        end

        ::skip::
    end

    return Decoded
end


-- returns string representation of the given array
local function arrPrint(arr, clear)
    local res = "{ "
    if (clear) then res="" end

    for i, c in pairs(arr) do
        if clear then
            res = res..tostring(c).." "
        else
            res = res..tostring(c)..", "
        end
    end

    if not clear then
        -- removes the last ","
        res = res:sub(1, #res-2)
        res = res.." }"
    end

    return res
end

-- updates the position of pointers
local function UpdatePointers()
    for i, pointer in ipairs(POINTERS) do
        POINTERS[i] = pointer+1
    end
end

-- Checks if the given word is a variable, pointer, accumulator or array
-- returns either the value or returns the word itself
local function GetVal(Word, clear)
    if #Word-1 <= 2 and #Word-1 > 0 and Word:sub(1, 1) == "r" then -- register
        local BufferX = tonumber(Word:sub(2))
        return REGISTERS[BufferX]

    elseif Word == "\\!" then
        return "!"

    elseif Word == "\\w" then
        return " "

    elseif Word == "\\s" then
        return ""

    elseif Word:sub(1, 1) == "*" then  -- pointer
        return STACK[POINTERS[Word]]

    elseif Word == "acc" then -- accumulator
        return ACCUMULATOR

    elseif Word:sub(1, 1) == "!" then  -- array
        local ArrayName = Word:sub(2)

        if ArrayName == "stack" then
            return arrPrint(STACK, clear)
        else
            return arrPrint(ARRAYS[ArrayName], clear)
        end

    else    -- other
        local num = tonumber(Word)
        if num then    -- number
            return num
        end

        -- string
        return Word
    end
end

--//
local function Syntax(DecodedInput)

    -- creates an array with given start-index
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

    -- creates a method with given start-index
    local function ConstructFunction(CurrentPos)
        local Token = DecodedInput[CurrentPos]
        local NewCurrent = CurrentPos

        local FunctionBody = {Body={}, Current=NewCurrent}

        while (Token) do
            if (Token.Word == ")") then
                break
            end

            table.insert(FunctionBody.Body, Token)
            FunctionBody.Current = FunctionBody.Current  + 1
            Token = DecodedInput[FunctionBody.Current]
        end

        return FunctionBody
    end

    -- current position within the token-array
    local Current = 1

    -- looping through the token-array until no tokens are left to execute
    while true do
        if (not DecodedInput) then break end
        if (not DecodedInput[Current]) then break end


        local Word = DecodedInput[Current].Word
        local NextWord = "NAN"

        if (DecodedInput[Current+1]) then
            NextWord = DecodedInput[Current+1].Word
        end

        -- removes the first element from the stack and puts it in the given variable
        if (Word == "pop") then
            if (#NextWord==2 or #NextWord==3 and NextWord:sub(1,1)=="r") then
                local reg = tonumber(NextWord:sub(2)) or 1

                if (#STACK<1)then
                    REGISTERS[reg] = 0
                else
                    -- moving first value of stack to given variable
                    -- removing the value from the stack
                    REGISTERS[reg] = STACK[1]
                    table.remove(STACK, 1)

                    -- updating the pointers positions
                    for i, pointer in pairs(POINTERS) do
                        POINTERS[i] = pointer-1
                        if (pointer-1==0) then
                            POINTERS[i] = nil
                        end
                    end
                end
                Current = Current + 1
            end

        -- prints everything behind the instruction until the "::END"
        elseif (Word == "prt") then
            if (NextWord) then

                local Vals = {}
                local now = Current + 1
                local startLine = DecodedInput[Current].Line
                local End = false

                local clear = false
                while true do
                    if (not DecodedInput[now]) then break end
                    if (DecodedInput[now].Line ~= startLine or End) then break end

                    if (DecodedInput[now].Word == "::END") then
                        local CLEAR1 = DecodedInput[now+1]
                        local CLEAR2 = DecodedInput[now+2]
                        if (CLEAR1) then
                            if (CLEAR1.Word == "::CLEAR") then
                                clear = true
                                break
                            end
                        end if (CLEAR2) then
                            if (CLEAR2.Word == "::CLEAR") then
                                clear = true
                                break
                            end
                        end
                        now = now + 1
                    end

                    now = now + 1
                end
                now = Current + 1

                -- looping through the print statement until the "::END" or a newline is reached
                while true do
                    if (not DecodedInput[now]) then break end
                    if (DecodedInput[now].Line ~= startLine or End) then
                        break
                    end

                    local i_NEXT = GetVal(DecodedInput[now].Word, clear)

                    if (i_NEXT == "::END") then
                        i_NEXT = ""
                        End = true
                    elseif (i_NEXT == "\\!") then
                        i_NEXT = "!"
                    elseif (i_NEXT == "\\*") then
                        i_NEXT = "*"
                    end

                    table.insert(Vals, i_NEXT)
                    now = now + 1
                end

                -- displaying the content
                local sep = " "
                if (DecodedInput[now]) then
                    if (DecodedInput[now].Word == "::SEP_LINE") then
                        sep = "\n"
                        now = now + 1
                    end
                end

                print(table.concat(Vals, sep))
                Current = now - 1
                if (clear) then
                    Current = now
                end
            end

        -- adds a value to given variable 
        -- e.g.: add r1 1 
        elseif (Word == "add") then -- addition command
            if (NextWord) then
                if (DecodedInput[Current+2]) then
                    local ThirdWord = DecodedInput[Current+2].Word
                    local AddTo = tonumber(GetVal(ThirdWord)) or 1

                    if (tonumber(GetVal(ThirdWord)) == nil) then Current = Current - 1 end

                    local Value = GetVal(NextWord)

                    local BufferX = tonumber(NextWord:sub(2)) or 1
                    REGISTERS[BufferX] = Value + AddTo

                    Current = Current + 2
                end
            end

        -- modulo operation
        elseif (Word == "mod") then -- syntax: mod r1 2 // valueOf(r1) % 2 -> newValueOf(r1)
            if (NextWord) then
                if (DecodedInput[Current+2]) then
                    local ThirdWord = DecodedInput[Current+2].Word
                    local Mod = tonumber(GetVal(ThirdWord)) or 1

                    if (tonumber(GetVal(ThirdWord)) == nil) then Current = Current - 1 end

                    local Value = GetVal(NextWord)

                    local BufferX = tonumber(NextWord:sub(2)) or 1
                    REGISTERS[BufferX] = Value % Mod

                    Current = Current + 2
                end
            end

        -- puts a value into another variable or the stack
        -- e.g.: put 100 r1 <- puts 100 into r1-variable
        -- e.g.: put r1 r2 <- puts value of r1-variable into r2-variable (r1's value stays untouched)
        -- e.g.: put 100 stack <- puts 100 ontop of the stack 
        -- e.g.: put 100 stack point *OneHundred <- puts 100 ontop of the stack and creates a pointer to that value
        elseif (Word == "put") then
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

        -- exponential-instruction 
        -- e.g.: exp 2 r1 <- value of r1-variable to the power of 2 -> result put in the r1-variable
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

        -- substracts given number from variable 
        -- e.g.: sub 100 r1 <- r1 = r1 - 100
        -- e.g.: sub r1 r2 <- r2 = r2 - r1 
        -- e.g.: sub *OneHundred r1 <- r1 = r1 - *OneHundred (100)
        elseif (Word == "sub") then
            if (NextWord) then
                if (DecodedInput[Current+2]) then
                    local ThirdWord = DecodedInput[Current+2].Word
                    local SubTo = tonumber(GetVal(ThirdWord)) or 1

                    if (tonumber(GetVal(ThirdWord)) == nil) then Current = Current - 1 end

                    local Value = GetVal(NextWord)

                    local BufferX = tonumber(NextWord:sub(2)) or 1
                    REGISTERS[BufferX] = Value - SubTo

                    Current = Current + 2
                end
            end

        -- deletes the value of given variable or removes given pointer:
        -- e.g.: del r1 <- r1 = nil 
        -- e.g.: del *OneHundred <- *OneHundred = nil 
        elseif (Word == "del") then
            if (NextWord) then
                if (#NextWord == 2 and NextWord:sub(1,1) == "r") then
                    local BufferX = tonumber(NextWord:sub(2)) or 1
                    REGISTERS[BufferX] = nil

                elseif (NextWord:sub(1,1) == "*") then
                    POINTERS[NextWord] = nil

                elseif (NextWord:sub(1,1) == "!") then
                    local Array = NextWord:sub(2, #NextWord)

                    if (Array) then
                        ARRAYS[Array] = nil
                    end

                elseif (NextWord == "acc") then
                    ACCUMULATOR = 0
                end
            end

        -- multiplies the value of the given variable
        -- e.g.: mul 2 r1 <- r1 = r1 * 2
        -- e.g.: mul *OneHundred r2 <- r2 = r2 * *OneHundred
        elseif (Word == "mul") then
            if (NextWord) then
                if (DecodedInput[Current+2]) then

                    local ThirdWord = DecodedInput[Current+2].Word
                    local SubTo = tonumber(GetVal(ThirdWord)) or 2

                    if (tonumber(GetVal(ThirdWord)) == nil) then Current = Current - 1 end

                    local Value = GetVal(NextWord)

                    local BufferX = tonumber(NextWord:sub(2)) or 1
                    REGISTERS[BufferX] = Value * SubTo

                    Current = Current + 2
                end
            end

        -- divides the value of the given variable
        -- e.g.: div 10 r1 <- r1 = r1 / 10
        elseif (Word == "div") then
            if (NextWord) then
                if (DecodedInput[Current+2]) then

                    local ThirdWord = DecodedInput[Current+2].Word
                    local SubTo = tonumber(GetVal(ThirdWord)) or 2

                    if (tonumber(GetVal(ThirdWord)) == nil) then Current = Current - 1 end

                    local Value = GetVal(NextWord)

                    local BufferX = tonumber(NextWord:sub(2)) or 1
                    REGISTERS[BufferX] = Value / SubTo

                    Current = Current + 2
                end
            end

        -- string instructions
        elseif (Word == "str") then
            local ThirdWord  = DecodedInput[Current+2]
            local FourthWord = DecodedInput[Current+3]

            -- !!!! variables used in string instructions have to be string-initialized via "put" instruction !!!!
            -- e.g.: put "Hello" r1 
            -- e.g.: put " " r2

            if (NextWord) then
                -- adds a word to given string stored in a variable
                -- e.g.: str add "World" r1 <- r1 = r1.."World" -> "Hello World" // note that a space " " is beind added automatically! 
                if (NextWord == "add") then
                    local reg = tonumber(FourthWord.Word:sub(2)) or 1
                    local sep = ""
                    local with = DecodedInput[Current+4].Word
                    if (with == "space") then
                        sep = " "
                    end
                    REGISTERS[reg] = REGISTERS[reg]..sep..GetVal(ThirdWord.Word)

                -- removes given length of characters from given string stored in variable
                -- e.g.: str sub 3 r1 <- r1 = string.sub(r1, 1, 3)
                elseif (NextWord == "sub") then
                    local reg = tonumber(FourthWord.Word:sub(2)) or 1
                    REGISTERS[reg] = string.sub(REGISTERS[reg], 0, -GetVal(ThirdWord.Word))

                -- array to string
                elseif (NextWord == "con") then
                    local Words = GetVal(ThirdWord.Word, true)
                    local reg = tonumber(FourthWord.Word:sub(2)) or 1
                    REGISTERS[reg] = Words

                elseif (NextWord == "split") then
                    local String = GetVal(ThirdWord.Word, false)
                    local seperator = GetVal(FourthWord.Word, false)
                    local reg = tonumber(DecodedInput[Current+4].Word:sub(2)) or 1
                    REGISTERS[reg] = DosLib.String.split(String, seperator)

                elseif (NextWord == "lower") then
                    local _str = tostring(GetVal(ThirdWord.Word))
                    local reg = tonumber(DecodedInput[Current+4].Word:sub(2)) or 1
                    REGISTERS[reg] = string.lower(_str)
                    Current = Current - 1 

                elseif (NextWord == "upper") then
                    local _str = tostring(GetVal(ThirdWord.Word))
                    local reg = tonumber(DecodedInput[Current+4].Word:sub(2)) or 1
                    REGISTERS[reg] = string.upper(_str)
                    Current = Current - 1

                elseif (NextWord == "sze") then
                    local _str = tostring(GetVal(ThirdWord.Word))
                    ACCUMULATOR = #_str
                    Current = Current - 1

                end
            end

            Current = Current + 3

        elseif (Word == "arr") then
            -- array libary:
            --  creating array
            --  getting index of elements within a given array
            --  replacing elements of a given array at given index with given element
            --  removing elements from a given array
            --  adding elements to a given array 
            --  getting the element-count of a given array
            --  checking a given array contains a certain element
            local ArrayName = GetVal(DecodedInput[Current+2].Word)

            if (NextWord) then
                if (NextWord == "mak") then
                    -- creating a new array
                    -- arr mak SomeArray < *pointer r1 r2 r3 r4 Hello 100 >
                    if (DecodedInput[Current+3].Word == "<") then
                        local Array = ConstructArray(Current+4)
                        ARRAYS[ArrayName] = Array.array
                        Current = Array.Current
                    end

                elseif (NextWord == "rep") then
                    -- replaces element with other element of given element
                    -- arr rep ArrayName TargetIndex NewElement
                    ARRAYS[ArrayName][GetVal(DecodedInput[Current+3].Word)] = GetVal(DecodedInput[Current+4].Word)
                    Current = Current + 4

                elseif (NextWord == "idx") then
                    -- returns the element at given index of given array to accumulator
                    -- arr idx SomeArray INDEX -> outputs value to accumulator (acc) 
                    ACCUMULATOR = ARRAYS[ArrayName][GetVal(DecodedInput[Current+3].Word)]
                    Current = Current + 3

                elseif (NextWord == "rem") then
                    -- removes element at given index of given array
                    -- arr rem SomeArray INDEX
                    local TargetIdx = tonumber(GetVal(DecodedInput[Current+3].Word)) or 1
                    table.remove(ARRAYS[ArrayName], TargetIdx)

                    Current = Current + 3

                elseif (NextWord == "add") then
                    -- adds an given element at bottom position of given array and returns the index to the accumulator
                    -- arr add SomeArray SomeValue

                    table.insert(ARRAYS[ArrayName], GetVal(DecodedInput[Current+3].Word))
                    Current = Current + 3

                elseif (NextWord == "sze") then
                    -- returns the size of a given array to the accumulator
                    -- arr sze SomeArray 
                    ACCUMULATOR = #ARRAYS[ArrayName]
                    Current = Current + 2

                elseif (NextWord == "has") then
                    -- checks if a given element exists within a given array and returns the index to the accumulator // 0 if no element has been found
                    -- arr has SomeArray SomeValue
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


        elseif (Word == "inp") then -- user input 
            -- numbers only
            if (NextWord:lower() == "num") then
                local Input = DosLib.In.ReadNum() or 0
                ACCUMULATOR = Input

            -- string only
            elseif (NextWord:lower() == "str") then
                local Input = io.read() or "NAN"
                ACCUMULATOR = Input

            else
                print("INVALID TYPE FOR INPUT")
                ACCUMULATOR = 0
            end
            Current = Current + 1

            -- returns the ascii value of given input character
        elseif (Word == "asc") then
            if (NextWord == "con") then
                local ThirdWord = DecodedInput[Current+2].Word
                local Val = tonumber(GetVal(ThirdWord)) or 0
                local ASCII_Value = string.char(Val)
                ACCUMULATOR = ASCII_Value
                Current = Current+2

            elseif (NextWord == "frm") then
                local ThirdWord = DecodedInput[Current+2].Word
                local Val = tostring(GetVal(ThirdWord))
                local ASCII_Value = string.byte(Val)
                ACCUMULATOR = ASCII_Value
                Current = Current+2
            end

        elseif (Word == "com") then -- comparing two variables
            -- compares the truth of two given values

            if (NextWord) then
                local OPERATIONS = {"<", ">", "==", "~=", ">=", "<=", "inner_limits", "outter_limits"}
                local OPERATION = DecodedInput[Current+2].Word

                local _4th = DecodedInput[Current+3].Word

                if (DosLib.Table.find(OPERATIONS, OPERATION)) then

                    local RESULT

                    -- comparing the given value whether it's or is within the given limit
                    if (OPERATION == "inner_limits") then
                        local limits = DosLib.String.split(GetVal(_4th), ":")
                        RESULT = load("return "..GetVal(NextWord).." >= "..tostring(limits[1]).." and "..GetVal(NextWord).." <= "..tostring(limits[2]))()

                    -- comparing the given value whether it's or is outside the given limit
                    elseif (OPERATION == "outter_limits") then
                        local limits = DosLib.String.split(GetVal(_4th), ":")
                        RESULT = load("return "..GetVal(NextWord).." <= "..tostring(limits[1]).." or "..GetVal(NextWord).." >= "..tostring(limits[2]))()

                    else
                        if (tonumber(GetVal(NextWord)) and tonumber(GetVal(_4th))) then
                            -- using Lua's load()-method to return the boolean value by comparing value1 with value2
                            RESULT = load("return "..GetVal(NextWord).." "..OPERATION.." "..GetVal(_4th))()
                        else
                            RESULT = load("return \""..GetVal(NextWord).."\" "..OPERATION.." \""..GetVal(_4th).."\"")()
                        end
                    end

                    -- 2 -> true
                    -- 1 -> false (idk why but it works lol)
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

                        elseif (DecodedInput[Current+4].Word == "aboard") then
                            return
                        end
                    end

                else
                    print("INVALID")
                end

                Current = Current + 3
            end

        -- calling a method
        elseif (Word == "goto") then
            if (NextWord:sub(1,1) == ":") then
                Syntax(BUILD_IN_LOOPS[NextWord]) -- starting/ restarting a loop
            else
                Syntax(BUILD_IN_FUNCTIONS[NextWord]) -- executing a method
            end

        elseif (Word == "get_time") then
            if (NextWord == "format") then
                local Format = GetVal(DecodedInput[Current+2].Word)
                local withTime = DecodedInput[Current+3].Word
                local Time
                if (withTime == "with") then
                    Time = GetVal(DecodedInput[Current+4].Word)
                    Current = Current + 1
                else
                    Time = os.time()
                end

                ---@diagnostic disable-next-line: param-type-mismatch
                ACCUMULATOR = os.date(Format, Time)
                Current = Current + 2

            elseif (NextWord == "in_sec") then
                ACCUMULATOR = os.time()
                Current = Current + 1
            end

        -- sleep/ delay method
        elseif (Word == "slp") then
            local startTime = os.clock()
            local endVal = GetVal(NextWord)
            local bufferJob = 0

            repeat
                -- keeps the loop busy (also from crashing)
                bufferJob = bufferJob + 1
                bufferJob = 1 / bufferJob

            until (startTime+endVal <= os.clock())

            Current = Current + 1

        elseif (Word == "break") then
            ACCUMULATOR = "break *714561j15"
            Current = Current + 1

        elseif (Word:sub(1,1) == ":") then
            local Body = ConstructFunction(Current+2)
            BUILD_IN_LOOPS[Word] = Body.Body

            repeat
                Syntax(BUILD_IN_LOOPS[Word])
            until ACCUMULATOR == "break *714561j15"

            Current = Body.Current

        elseif (Word == "run") then
            local _file = tostring(GetVal(NextWord))

            if (_file) then
                local Openfile = io.open(_file)
                if (not Openfile) then return end

                local Content = Openfile:read("a")
                Syntax(Decode(Content))
                Openfile:close()

            end

        elseif (Word == "rnd") then
            local reg = tonumber(NextWord:sub(2)) or 1
            local Range = DosLib.String.split(DecodedInput[Current+2].Word, ":")

            -- overwriting the randomseed
            if (BeforeClock ~= os.time()) then
                BeforeClock = os.time()
                math.randomseed(BeforeClock)
            end

            Range[1] = GetVal(Range[1])
            Range[2] = GetVal(Range[2])
            local randomNumber = math.random(Range[1], Range[2])
            REGISTERS[reg] = randomNumber
            Current = Current + 2

        -- lambda ExpressionName ( x:10 y:20 z:30 : x+y+z+1 )
        elseif (Word == "lambda") then
            local Name = GetVal(NextWord)

            -- constructs the lambda
            local function constructLambda(Body)
                local LambdaBody = Body.Body
                local Expression = ""
                local ExpressionOn = false

                for i, token in pairs(LambdaBody) do
                    if (not ExpressionOn) then
                        local VarInfo = DosLib.String.split(token.Word,":")

                        if (#VarInfo<2) then
                            ExpressionOn = true
                            Expression = Expression.."return "
                            goto ex_loop
                        end

                        Expression = Expression.."local "..VarInfo[1].." = "..tostring(GetVal(VarInfo[2])).."\n"
                    end
                    if (ExpressionOn) then
                        Expression = Expression..tostring(GetVal(token.Word))
                    end
                    ::ex_loop::
                end

                return Expression
            end

            -- calling the lambda
            if (LAMBDABODIES[Name] and DecodedInput[Current+2].Word ~= "(") then
                ACCUMULATOR = load(constructLambda(LAMBDABODIES[Name]))()
                Current = Current + 1

            else
                local Body = ConstructFunction(Current+3)
                LAMBDABODIES[Name] = Body

                Current = Body.Current
            end


        elseif (Word == "io") then
            if (NextWord == "read") then
                local Filepath = DecodedInput[Current+2].Word
                local File = io.open(Filepath, "r") or ""
                local FileContent = File:read("a") or ""
                File:close()
                ACCUMULATOR = FileContent
                Current = Current + 2

            elseif (NextWord == "write") then
                local Filepath = DecodedInput[Current+2].Word
                local WriteMode = DecodedInput[Current+3].Word
                local Content = GetVal(DecodedInput[Current+4].Word)
                local param = GetVal(DecodedInput[Current+5].Word)

                if (WriteMode=="add") then -- adding content to the selected file
                    local File = io.open(Filepath, "r") or ""
                    local PreContent = File:read("a")
                    File:close()

                    if (param) then
                        if (param == "new_line") then -- sets the new content to the new line
                            Content = Content.."\n"
                            Current = Current + 1

                        elseif (param == "first_line") then -- puts new content always ontop of the file it's written to
                            local swap = PreContent
                            PreContent = Content.."\n"
                            Content = swap
                            Current = Current + 1
                        end
                    end

                    io.open(Filepath,"w"):write(PreContent..Content):close()
                    Current = Current + 3

                elseif (WriteMode=="ovr") then -- overwriting the selected file with the given content
                    io.open(Filepath, "w+"):write(Content):close()
                    Current = Current + 3
                end
            end

        else
            if (NextWord == "(") then
                local Body = ConstructFunction(Current+2)
                
                BUILD_IN_FUNCTIONS[Word] = Body.Body

                -- FirstRun function
                if (DecodedInput[Current-1].Word == "start") then 
                    Syntax(BUILD_IN_FUNCTIONS[Word])
                end

                Current = Body.Current
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

local RT_Mode = ""

if (InputFile:sub(1,4) == "rtm") then
    io.write("Run-on-Terminal-Mode is now activated!\n\n")
    local ended = false

    -- reading input until the user leaves the mode 
    -- then changes to execute-mode
    repeat
        io.write("=> ")
        local input = io.read()

        -- exit rt-mode
        if (input:lower()=="/exit") then
            ended = true
        else 
            RT_Mode = RT_Mode..input.."\n"
        end

    until ended

    io.write("\nOutput:\n")
    Syntax(Decode(RT_Mode))

    io.write("PRESS \"ENTER\" TO END THE PROGRAM")
    io.read()
else
    if (InputFile:sub(#InputFile-4, #InputFile) == ".dosb") then
        local file = io.open(InputFile)
        if (not file) then return end

        local FILE_CONTENT = file:read("a")
        file:close()

        print("--------------------")
        print("running programm: " .. InputFile)
        print("--------------------\n")

        local start = os.clock()

        local Decoded = Decode(FILE_CONTENT)
        local DecodeTime = os.clock()

        Syntax(Decoded)

        io.write("\nTOTAL RUN-TIME: "..tostring(os.clock()-start).."\nDECODE RUN-TIME: "..tostring(DecodeTime-start).."\nRUN-TIME: "..tostring(os.clock()-DecodeTime).."\n")
        io.write("PRESS \"ENTER\" TO END THE PROGRAM")
        io.read()
    else
        print("INVALID FILE!")
    end
end