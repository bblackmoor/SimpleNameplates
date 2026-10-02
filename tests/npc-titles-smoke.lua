-- Readable NPC tooltip subtitles; no player data or visible tooltip scanning.
local secret = {}
local ns = {
    AccessibleValue = function(v) if v ~= secret then return v end end,
    AccessibleNumber = function(v) if type(v) == "number" then return v end end,
}
Enum = {TooltipDataLineType = {None = 0, UnitName = 2, UnitLevel = 47, QuestTitle = 17}}
assert(loadfile("SimpleNameplates/NPCTitles.lua"))("SimpleNameplates", ns)
local function tooltip(title)
    return {lines = {
        {type = 2, leftText = "Orin Straylight"},
        {type = 0, leftText = title},
        {type = 47, leftText = "Level 90"},
    }}
end
local function equal(a, b, label) assert(a == b, label) end
equal(ns.NPCTitles.Extract(tooltip("Voidforge Steward")), "<Voidforge Steward>", "NPC subtitle")
equal(ns.NPCTitles.Extract(tooltip("|cffffffff<Forgeron du Vide>|r")), "<Forgeron du Vide>", "localized colored subtitle")
equal(ns.NPCTitles.Extract(tooltip("")), nil, "empty title")
equal(ns.NPCTitles.Extract(tooltip(secret)), nil, "secret text")
equal(ns.NPCTitles.Extract(secret), nil, "secret tooltip")
equal(ns.NPCTitles.Extract(tooltip("|Ticon:16|t")), nil, "texture markup")
equal(ns.NPCTitles.Extract({lines = {{type = 2}, {type = 47, leftText = "Level 90"}}}), nil, "no title")
local data = tooltip("Quest text")
data.lines[2].type = 17
equal(ns.NPCTitles.Extract(data), nil, "quest is not a title")
data = tooltip("Status text")
data.lines[3].type = 0
equal(ns.NPCTitles.Extract(data), nil, "ambiguous layout")
data = tooltip("Title")
data.lines[2].rightText = "Other information"
equal(ns.NPCTitles.Extract(data), nil, "two-column line")
data = tooltip("Title")
data.lines[2] = setmetatable({}, {__index = function() error("restricted field") end})
equal(ns.NPCTitles.Extract(data), nil, "unreadable field")
local calls = 0
C_TooltipInfo = {GetUnit = function(unit)
    calls = calls + 1
    equal(unit, "nameplate1", "exact supplied token")
    return tooltip("Voidforge Steward")
end}
equal(ns.NPCTitles.GetTitle("nameplate1", {isNPC = true}), "<Voidforge Steward>", "API read")
equal(ns.NPCTitles.GetTitle("player", {isNPC = false}), nil, "player excluded")
equal(ns.NPCTitles.GetTitle("unknown", {}), nil, "unknown excluded")
equal(calls, 1, "no player or unknown tooltip reads")
local info = ns.NPCTitles.Inspect("nameplate1", {isNPC = true})
equal(calls, 2, "inspection reads tooltip once")
equal(info.title, "<Voidforge Steward>", "inspection title")
equal(info.reason, "title extracted", "successful extraction reason")
equal(#info.lines, 3, "snapshot ends at absent line")
equal(info.lines[2].lineType, 0, "subtitle type snapshot")
equal(info.lines[2].left, "Voidforge Steward", "subtitle text snapshot")
equal(info.lines[2].rightStatus, "absent", "missing right column explicit")
equal(info.truncated, false, "short snapshot not truncated")
data = tooltip("Quest text")
data.lines[2].type = 17
C_TooltipInfo.GetUnit = function() return data end
info = ns.NPCTitles.Inspect("nameplate1", {isNPC = true})
equal(info.reason, "layout rejected: line 2 type 17; expected 0", "layout rejection distinguished")
equal(info.lines[2].left, "Quest text", "rejected layout still readable")
equal(data.lines[2].type, 17, "inspection preserves source")
data = tooltip(secret)
C_TooltipInfo.GetUnit = function() return data end
info = ns.NPCTitles.Inspect("nameplate1", {isNPC = true})
equal(info.reason, "subtitle left text restricted", "restricted field distinguished")
equal(info.lines[2].leftStatus, "restricted", "restricted snapshot status")
equal(info.lines[2].left, nil, "restricted value omitted")
data = tooltip("Title")
for i = 4, 13 do data.lines[i] = {type = 0, leftText = "Extra"} end
C_TooltipInfo.GetUnit = function() return data end
info = ns.NPCTitles.Inspect("nameplate1", {isNPC = true})
equal(#info.lines, 12, "snapshot bounded")
equal(info.truncated, true, "extra lines reported")
C_TooltipInfo.GetUnit = function() return nil end
equal(ns.NPCTitles.Inspect("nameplate1", {isNPC = true}).reason, "no tooltip data returned", "missing data distinguished")
C_TooltipInfo.GetUnit = function() error("blocked") end
equal(ns.NPCTitles.GetTitle("nameplate1", {isNPC = true}), nil, "blocked API")
equal(ns.NPCTitles.Inspect("nameplate1", {isNPC = true}).reason, "tooltip API call failed", "failed API distinguished")
C_TooltipInfo = nil
equal(ns.NPCTitles.GetTitle("nameplate1", {isNPC = true}), nil, "missing API")
equal(ns.NPCTitles.Inspect("nameplate1", {isNPC = true}).reason, "tooltip API unavailable", "missing API distinguished")
print("NPC titles smoke: passed")
