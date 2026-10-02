-- Simple Nameplates: NPC subtitles from readable structured unit tooltips.
local _, ns = ...
local Value, Number = ns.AccessibleValue, ns.AccessibleNumber

local function Restricted(value)
    return (issecretvalue and issecretvalue(value))
        or (canaccessvalue and not canaccessvalue(value))
end

local function Field(object, key)
    if Restricted(object) then return nil, "restricted" end
    object = Value(object)
    if type(object) ~= "table" then return nil, "object unavailable" end
    local ok, value = pcall(function() return object[key] end)
    if not ok then return nil, "field read failed" end
    if Restricted(value) then return nil, "restricted" end
    local readable = Value(value)
    if readable == nil then return nil, value == nil and "absent" or "restricted" end
    return readable, "readable"
end

local function CleanTitle(text)
    text = Value(text)
    if type(text) ~= "string" then return nil, "subtitle text unavailable or not a string" end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    -- Do not turn links, textures, or other tooltip markup into overhead text.
    if text:find("|", 1, true) then return nil, "subtitle contains unsupported markup" end
    text = text:gsub("%s+", " "):match("^%s*(.-)%s*$")
    text = text:match("^<(.-)>$") or text
    if text == "" then return nil, "subtitle is empty" end
    return "<" .. text .. ">", "title extracted"
end

local function Extract(data)
    local types = Enum and Enum.TooltipDataLineType
    if not types or not types.UnitName or not types.UnitLevel or not types.None then
        return nil, "required tooltip line enums unavailable"
    end
    local lines, status = Field(data, "lines")
    if type(lines) ~= "table" then return nil, "tooltip lines " .. status end
    -- There is no service-title enum. Accept only the single plain subtitle
    -- immediately between the name and typed level line. Never use a generic
    -- second line (which could instead be a level, quest, owner, or status).
    for index, expected in ipairs({types.UnitName, types.None, types.UnitLevel}) do
        local line, lineStatus = Field(lines, index)
        if type(line) ~= "table" then return nil, "tooltip line " .. index .. " " .. lineStatus end
        local lineType, typeStatus = Field(line, "type")
        lineType = Number(lineType)
        if lineType == nil then return nil, "line " .. index .. " type " .. typeStatus end
        if lineType ~= expected then
            return nil, "layout rejected: line " .. index .. " type " .. lineType .. "; expected " .. expected
        end
    end
    local subtitle = Field(lines, 2)
    local right, rightStatus = Field(subtitle, "rightText")
    if rightStatus ~= "readable" and rightStatus ~= "absent" then
        return nil, "subtitle right text " .. rightStatus
    end
    if right ~= nil and right ~= "" then return nil, "subtitle has right-column text" end
    local left, leftStatus = Field(subtitle, "leftText")
    if leftStatus ~= "readable" then return nil, "subtitle left text " .. leftStatus end
    return CleanTitle(left)
end

local function ReadTooltip(unit, facts)
    if not facts or facts.isNPC ~= true then return nil, "unit not confirmed NPC" end
    local getter = C_TooltipInfo and C_TooltipInfo.GetUnit
    if type(getter) ~= "function" then return nil, "tooltip API unavailable" end
    local ok, data = pcall(getter, unit)
    if not ok then return nil, "tooltip API call failed" end
    if Restricted(data) then return nil, "tooltip data restricted" end
    data = Value(data)
    if data == nil then return nil, "no tooltip data returned" end
    if type(data) ~= "table" then return nil, "tooltip data unavailable or not a table" end
    return data
end

local function GetTitle(unit, facts)
    local data, reason = ReadTooltip(unit, facts)
    if not data then return nil, reason end
    return Extract(data)
end

local function Inspect(unit, facts)
    local data, reason = ReadTooltip(unit, facts)
    local result = {reason = reason, lines = {}}
    if not data then return result end
    result.title, result.reason = Extract(data)
    local lines = Field(data, "lines")
    if type(lines) ~= "table" then return result end
    -- Bounded diagnostic-only snapshot; never construct or mutate a tooltip.
    for index = 1, 12 do
        local line, status = Field(lines, index)
        if status == "absent" then break end
        local row = {index = index, status = status}
        row.lineType, row.typeStatus = Field(line, "type")
        row.left, row.leftStatus = Field(line, "leftText")
        row.right, row.rightStatus = Field(line, "rightText")
        result.lines[#result.lines + 1] = row
    end
    local _, status = Field(lines, 13)
    result.truncated = status ~= "absent"
    return result
end

ns.NPCTitles = {GetTitle = GetTitle, Extract = Extract, Inspect = Inspect}
