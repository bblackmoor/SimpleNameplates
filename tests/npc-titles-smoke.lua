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
C_TooltipInfo.GetUnit = function() error("blocked") end
equal(ns.NPCTitles.GetTitle("nameplate1", {isNPC = true}), nil, "blocked API")
C_TooltipInfo = nil
equal(ns.NPCTitles.GetTitle("nameplate1", {isNPC = true}), nil, "missing API")
print("NPC titles smoke: passed")
