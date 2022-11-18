function Decode(INPUT)
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

return Decode