-- Simple Nameplates: NPC subtitles from readable structured unit tooltips.
local _, ns = ...
local Value, Number = ns.AccessibleValue, ns.AccessibleNumber

local function Field(object, key)
    object = Value(object)
    if type(object) ~= "table" then return nil end
    local ok, value = pcall(function() return object[key] end)
    if ok then return Value(value) end
end

local function CleanTitle(text)
    text = Value(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    -- Do not turn links, textures, or other tooltip markup into overhead text.
    if text:find("|", 1, true) then return nil end
    text = text:gsub("%s+", " "):match("^%s*(.-)%s*$")
    text = text:match("^<(.-)>$") or text
    if text == "" then return nil end
    return "<" .. text .. ">"
end

local function Extract(data)
    local types = Enum and Enum.TooltipDataLineType
    if not types or not types.UnitName or not types.UnitLevel or not types.None then return nil end
    local lines = Field(data, "lines")
    if type(lines) ~= "table" then return nil end
    -- There is no service-title enum. Accept only the single plain subtitle
    -- immediately between the name and typed level line. Never use a generic
    -- second line (which could instead be a level, quest, owner, or status).
    if Number(Field(Field(lines, 1), "type")) ~= types.UnitName
        or Number(Field(Field(lines, 2), "type")) ~= types.None
        or Number(Field(Field(lines, 3), "type")) ~= types.UnitLevel then return nil end
    local subtitle = Field(lines, 2)
    local right = Field(subtitle, "rightText")
    if right ~= nil and right ~= "" then return nil end
    return CleanTitle(Field(subtitle, "leftText"))
end

local function GetTitle(unit, facts)
    if not facts or facts.isNPC ~= true then return nil end
    local getter = C_TooltipInfo and C_TooltipInfo.GetUnit
    if type(getter) ~= "function" then return nil end
    local ok, data = pcall(getter, unit)
    if not ok then return nil end
    return Extract(data)
end

ns.NPCTitles = {GetTitle = GetTitle, Extract = Extract}
