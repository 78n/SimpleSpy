--[[
    higlight.lua v0.0.1 by exxtremewa#9394
    
    Features:
     - uses the power of fancy syntax detection algorithms to convert a frame into a syntax highlighted high quality code box
     - is cool
]]

local cloneref  = cloneref or function(...)
    return ...
end

local TextService = cloneref(game:GetService("TextService"))
local RunService = cloneref(game:FindService("RunService"))
--- The Highlight class
--- @class Highlight
local Highlight = {}

-- PRIVATE METHODS/PROPERTIES --

--[[
    Char Object:
    {
        Char: string -- A single character
        Color: Color3 -- The intended color of the char
        Line: number -- The line number
    }
]]

local parentFrame
local scrollingFrame
local textFrame
local lineNumbersFrame
local lines = {}

--- Contents of the table- array of char objects
local tableContents = {}

local line = 0
local largestX = 0

local lineSpace = 15
local font = Enum.Font.Ubuntu
local textSize = 14

local backgroundColor = Color3.fromRGB(40, 44, 52)
local operatorColor = Color3.fromRGB(187, 85, 255)
local functionColor = Color3.fromRGB(97, 175, 239)
local stringColor = Color3.fromRGB(152, 195, 121)
local numberColor = Color3.fromRGB(209, 154, 102)
local booleanColor = numberColor
local objectColor = Color3.fromRGB(229, 192, 123)
local defaultColor = Color3.fromRGB(224, 108, 117)
local commentColor = Color3.fromRGB(148, 148, 148)
local lineNumberColor = commentColor
local genericColor = Color3.fromRGB(240, 240, 240)

local operators = {"^(function)[^%w_]", "^(local)[^%w_]", "^(if)[^%w_]", "^(for)[^%w_]", "^(while)[^%w_]", "^(then)[^%w_]", "^(do)[^%w_]", "^(else)[^%w_]", "^(elseif)[^%w_]", "^(return)[^%w_]", "^(end)[^%w_]", "^(continue)[^%w_]", "^(and)[^%w_]", "^(not)[^%w_]", "^(or)[^%w_]", "[^%w_](or)[^%w_]", "[^%w_](and)[^%w_]", "[^%w_](not)[^%w_]", "[^%w_](continue)[^%w_]", "[^%w_](function)[^%w_]", "[^%w_](local)[^%w_]", "[^%w_](if)[^%w_]", "[^%w_](for)[^%w_]", "[^%w_](while)[^%w_]", "[^%w_](then)[^%w_]", "[^%w_](do)[^%w_]", "[^%w_](else)[^%w_]", "[^%w_](elseif)[^%w_]", "[^%w_](return)[^%w_]", "[^%w_](end)[^%w_]"}
--- In this case, patterns could not be used, so just the string characters are provided
local strings = {{"\"", "\""}, {"'", "'"}, {"%[%[", "%]%]", true}}
local comments = {"%-%-%[%[[^%]%]]+%]?%]?", "(%-%-[^\n]+)"}
local functions = {"[^%w_]([%a_][%a%d_]*)%s*%(", "^([%a_][%a%d_]*)%s*%(", "[:%.%(%[%p]([%a_][%a%d_]*)%s*%("}
local numbers = {"[^%w_](%d+[eE]?%d*)", "[^%w_](%.%d+[eE]?%d*)", "[^%w_](%d+%.%d+[eE]?%d*)", "^(%d+[eE]?%d*)", "^(%.%d+[eE]?%d*)", "^(%d+%.%d+[eE]?%d*)"}
local booleans = {"[^%w_](true)", "^(true)", "[^%w_](false)", "^(false)", "[^%w_](nil)", "^(nil)"}
local objects = {"[^%w_:]([%a_][%a%d_]*):", "^([%a_][%a%d_]*):"}
local other = {"[^_%s%w=>~<%-%+%*]", ">", "~", "<", "%-", "%+", "=", "%*"}
local offLimits = {}

--- Determines if index is in a string
function isOffLimits(index)
    for _, v in next, offLimits do
        if index >= v[1] and index <= v[2] then
            return true
        end
    end
    return false
end

--- Find iterator
-- function gfind(str, pattern)
--     local start = 0
--     return function()
--         local findStart, findEnd = str:find(pattern, start)
--         if findStart and findEnd ~= #str then
--             start = findEnd + 1
--             return findStart, findEnd
--         else
--             return nil
--         end
--     end
-- end

--- Find iterator
function gfind(str, pattern)
    return coroutine.wrap(function()
        local start = 0
        while true do
            local findStart, findEnd = str:find(pattern, start)
            if findStart and findEnd ~= #str then
                start = findEnd + 1
                coroutine.yield(findStart, findEnd)
            else
                return
            end
        end
    end)
end

--- Finds and highlights comments with `commentColor`
function renderComments()
    local str = Highlight:getRaw()
    local step = 1
    for _, pattern in next, comments do
        for commentStart, commentEnd in gfind(str, pattern) do
            if step % 1000 == 0 then
                RunService.Heartbeat:Wait()
            end
            step += 1
            if not isOffLimits(commentStart) then
                for i = commentStart, commentEnd do
                    table.insert(offLimits, {commentStart, commentEnd})
                    if tableContents[i] then
                        tableContents[i].Color = commentColor
                    end
                end
            end
        end
    end
end

-- Finds and highlights strings with `stringColor`
function renderStrings()
    local stringType
    local stringEndType
    local ignoreBackslashes
    local stringStart
    local stringEnd
    local offLimitsIndex
    local skip = false
    
    for i, char in next, tableContents do
        if stringType then
            char.Color = stringColor
            local possibleString = ""
            for k = stringStart, i do
                possibleString = possibleString .. tableContents[k].Char
            end
            if char.Char:match(stringEndType) and not not ignoreBackslashes or (possibleString:match("(\\*)" .. stringEndType .. "$") and #possibleString:match("(\\*)" .. stringEndType .. "$") % 2 == 0) then
                skip = true
                stringType = nil
                stringEndType = nil
                ignoreBackslashes = nil
                stringEnd = i
                offLimits[offLimitsIndex][2] = stringEnd
            end
        end
        if not skip then
            for _, v in next, strings do
                if char.Char:match(v[1]) and not isOffLimits(i) then
                    stringType = v[1]
                    stringEndType = v[2]
                    ignoreBackslashes = v[3]
                    char.Color = stringColor
                    stringStart = i
                    offLimitsIndex = #offLimits + 1
                    offLimits[offLimitsIndex] = {stringStart, math.huge}
                end
            end
        end
        skip = false
    end
end

--- Highlights the specified patterns with the specified color
--- @param patternArray string[]
---@param color userdata
function highlightPattern(patternArray, color)
    local str = Highlight:getRaw()
    local step = 1
    for _, pattern in next, patternArray do
        for findStart, findEnd in gfind(str, pattern) do
            if step % 1000 == 0 then
                RunService.Heartbeat:Wait()
            end
            step += 1
            if not isOffLimits(findStart) and not isOffLimits(findEnd) then
                for i = findStart, findEnd do
                    if tableContents[i] then
                        tableContents[i].Color = color
                    end
                end
            end
        end
    end
end

--- Automatically replaces reserved chars with escape chars
--- @param s string
function autoEscape(s)
    for i = 0, #s do
        local char = string.sub(s, i, i)
        if char == "<" then
            s = string.format("%s%s%s", string.sub(s, 0, i - 1), "&lt;", string.sub(s, i + 1, -1))
            i += 3
        elseif char == ">" then
            s = string.format("%s%s%s", string.sub(s, 0, i - 1), "&gt;", string.sub(s, i + 1, -1))
            i += 3
        elseif char == '"' then
            s = string.format("%s%s%s", string.sub(s, 0, i - 1), "&quot;", string.sub(s, i + 1, -1))
            i += 5
        elseif char == "'" then
            s = string.format("%s%s%s", string.sub(s, 0, i - 1), "&apos;", string.sub(s, i + 1, -1))
            i += 5
        elseif char == "&" then
            s = string.format("%s%s%s", string.sub(s, 0, i - 1), "&amp;", string.sub(s, i + 1, -1))
            i += 4
        end
    end
    -- s:gsub("<", "&lt;")
    -- s:gsub(">", "&gt;")
    -- s:gsub('"', "&quot;")
    -- s:gsub("'", "&apos;")
    -- s:gsub("&", "&amp;")
    return s
end

--- Main function for syntax highlighting tableContents
function render()
    offLimits = {}
    lines = {}
    textFrame:ClearAllChildren()
    lineNumbersFrame:ClearAllChildren()

    highlightPattern(functions, functionColor)
    highlightPattern(numbers, numberColor)
    highlightPattern(operators, operatorColor)
    highlightPattern(objects, objectColor)
    highlightPattern(booleans, booleanColor)
    highlightPattern(other, genericColor)
    renderComments()
    renderStrings()

    local lastColor
    local lineStr = ""
    local rawStr = ""
    largestX = 0
    line = 1

    for i = 1, #tableContents + 1 do
        local char = tableContents[i]
        if i == #tableContents + 1 or char.Char == "\n" then
            lineStr = lineStr .. (lastColor and "</font>" or "")

            local lineText = Instance.new("TextLabel")
            local x = TextService:GetTextSize(rawStr, textSize, font, Vector2.new(math.huge, math.huge)).X + 60

            if x > largestX then
                largestX = x
            end

            lineText.TextXAlignment = Enum.TextXAlignment.Left
            lineText.TextYAlignment = Enum.TextYAlignment.Top
            lineText.Position = UDim2.new(0, 0, 0, line * lineSpace - lineSpace / 2)
            lineText.Size = UDim2.new(0, x, 0, textSize)
            lineText.RichText = true
            lineText.Font = font
            lineText.TextSize = textSize
            lineText.BackgroundTransparency = 1
            lineText.Text = lineStr
            lineText.Parent = textFrame

            if i ~= #tableContents + 1 then
                local lineNumber = Instance.new("TextLabel")
                lineNumber.Text = line
                lineNumber.Font = font
                lineNumber.TextSize = textSize
                lineNumber.Size = UDim2.new(1, 0, 0, lineSpace)
                lineNumber.TextXAlignment = Enum.TextXAlignment.Right
                lineNumber.TextColor3 = lineNumberColor
                lineNumber.Position = UDim2.new(0, 0, 0, line * lineSpace - lineSpace / 2)
                lineNumber.BackgroundTransparency = 1
                lineNumber.Parent = lineNumbersFrame
            end

            lineStr = ""
            rawStr = ""
            lastColor = nil
            line += 1
            updateZIndex()
            updateCanvasSize()
            if line % 5 == 0 then
                RunService.Heartbeat:Wait()
            end
        elseif char.Char == " " then
            lineStr = lineStr .. char.Char
            rawStr = rawStr .. char.Char
        elseif char.Char == "\t" then
            lineStr = lineStr .. string.rep(" ", 4)
            rawStr = rawStr .. char.Char
        else
            if char.Color == lastColor then
                lineStr = lineStr .. autoEscape(char.Char)
            else
                lineStr = lineStr .. string.format('%s<font color="rgb(%d,%d,%d)">', lastColor and "</font>" or "", char.Color.R * 255, char.Color.G * 255, char.Color.B * 255)
                lineStr = lineStr .. autoEscape(char.Char)
                lastColor = char.Color
            end
            rawStr = rawStr .. char.Char
        end
    end
    updateZIndex()
    updateCanvasSize()
end

function onFrameSizeChange()
    local newSize = parentFrame.AbsoluteSize
    scrollingFrame.Size = UDim2.new(0, newSize.X, 0, newSize.Y)
end

function updateCanvasSize()
    -- local codeSize = Vector2.new(TextService:GetTextSize(Highlight:getRaw(), textSize, font, Vector2.new(math.huge, math.huge)).X + 60, #lines * lineSpace + 60)
    scrollingFrame.CanvasSize = UDim2.new(0, largestX, 0, line * lineSpace)
end

function updateZIndex()
    for _, v in next, parentFrame:GetDescendants() do
        if v:IsA("GuiObject") then
            v.ZIndex = parentFrame.ZIndex
        end
    end
end

-- PUBLIC METHODS --

--- Runs when a new object is instantiated
--- @param frame userdata
function Highlight:init(frame)
    if typeof(frame) == "Instance" and frame:IsA("Frame") then
        frame:ClearAllChildren()

        parentFrame = frame
        scrollingFrame = Instance.new("ScrollingFrame")
        textFrame = Instance.new("Frame")
        lineNumbersFrame = Instance.new("Frame")

        local parentSize = frame.AbsoluteSize
        scrollingFrame.Size = UDim2.new(0, parentSize.X, 0, parentSize.Y)
        scrollingFrame.BackgroundColor3 = backgroundColor
        scrollingFrame.BorderSizePixel = 0
        scrollingFrame.ScrollBarThickness = 4

        textFrame.Size = UDim2.new(1, -40, 1, 0)
        textFrame.Position = UDim2.new(0, 40, 0, 0)
        textFrame.BackgroundTransparency = 1

        lineNumbersFrame.Size = UDim2.new(0, 25, 1, 0)
        lineNumbersFrame.BackgroundTransparency = 1

        textFrame.Parent = scrollingFrame
        lineNumbersFrame.Parent = scrollingFrame
        scrollingFrame.Parent = parentFrame

        render()
        parentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(onFrameSizeChange)
        parentFrame:GetPropertyChangedSignal("ZIndex"):Connect(updateZIndex)
    else
        error("Initialization error: argument " .. typeof(frame) .. " is not a Frame Instance")
    end
end

--- Sets the raw text of the code box (\n = new line, \t converted to spaces)
--- @param raw string
function Highlight:setRaw(raw)
    raw = raw .. "\n"
    tableContents = {}
    local line = 1
    for i = 1, #raw do
        table.insert(tableContents, {
            Char = raw:sub(i, i),
            Color = defaultColor,
            -- Line = line
        })
        if i % 1000 == 0 then
            RunService.Heartbeat:Wait()
        end
        -- if raw:sub(i, i) == "\n" then
        --     line = line + 1
        -- end
    end
    render()
end

--- Returns the (string) raw text of the code box (\n = new line). This includes placeholder characters so it should only be used internally.
--- @return string
function Highlight:getRaw()
    local result = ""
    for _, char in next, tableContents do
        result = result .. char.Char
    end
    return result
end

--- Returns the (string) text of the code box (\n = new line)
--- @return string
function Highlight:getString()
    local result = ""
    for _, char in next, tableContents do
        result = result .. char.Char:sub(1, 1)
    end
    return result
end

--- Returns the (char[]) array that holds all the lines in order as strings
--- @return table[]
function Highlight:getTable()
    return tableContents
end

--- Returns the (int) number of lines in the code box
--- @return number
function Highlight:getSize()
    return #tableContents
end

--- Returns the (string) line of the specified line number
--- @param line number
--- @return string
function Highlight:getLine(line)
    local currentline = 0
    local rightLine = false
    local result = ""
    for _, v in next, tableContents do
        currentline = currentline + 1
        if v.Char == "\n" and not rightLine then
            rightLine = true
        end
        if rightLine and v.Char ~= "\n" then
            result = result .. v.Char
        elseif rightLine then
            break
        end
    end
    return result
end

--- Replaces the specified line number with the specified string (\n will overwrite further lines)
--- @param line number
---@param text string
function Highlight:setLine(line, text)
    if #tableContents and line >= tableContents[#tableContents].Line then
        for i = tableContents[#tableContents].Line, line do
            table.insert(tableContents, {
                Char = "\n",
                Line = i,
                Color = defaultColor
            })
            local str = Highlight:getRaw()
            str = str:sub(0, #str) .. text
            Highlight:setRaw(str)
            return
        end
    elseif not #tableContents then
        return
    end
    local str = Highlight:getRaw()
    local lastStart = 0
    local currentLine = 0
    for i in gfind(str, "\n") do
        currentLine = currentLine + 1
        if line == currentLine then
            str = str:sub(0, lastStart) .. text .. str:sub(i, #str)
            Highlight:setRaw(str)
            return
        end
    end
    error("Unable to set line")
end

--- Inserts a line made from the specified string and moves all existing lines down (\n will insert further lines)
--- @param line number
---@param text string
function Highlight:insertLine(line, text)
    if #tableContents and line >= tableContents[#tableContents].Line then
        Highlight:setLine(line, text)
    elseif not #tableContents then
        return
    end
    local str = Highlight:getRaw()
    local lastStart = 0
    local currentLine = 0
    for i in gfind(str, "\n") do
        currentLine = currentLine + 1
        if line == currentLine then
            str = str:sub(0, lastStart) .. "\n" .. text .. "\n" .. str:sub(i, #str)
            Highlight:setRaw(str)
            return
        end
    end
    error("Unable to insert line")
end

-- CONSTRUCTOR --

local constructor = {}
--- responsible for instantiation
function constructor.new(...)
    local class = Highlight
    local new = {}
    class.__index = class
    setmetatable(new, class)
    new:init(...)
    return new
end

return constructor
