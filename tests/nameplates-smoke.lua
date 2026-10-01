-- Characterize nameplate classification and one-time runtime setup.
-- Run from the repository root: lua tests/nameplates-smoke.lua
local function equal(actual, expected, label)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)), 2)
    end
end

local frames, hooks, timers = {}, {}, {}
function CreateFrame(kind)
    local frame = { kind = kind, registered = {}, scripts = {} }
    function frame:RegisterEvent(event) self.registered[event] = (self.registered[event] or 0) + 1 end
    function frame:UnregisterEvent(event) self.registered[event] = nil end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    frames[#frames + 1] = frame
    return frame
end
function hooksecurefunc(name, callback)
    hooks[#hooks + 1] = { name = name, callback = callback }
end
function CompactUnitFrame_UpdateHealthColor() end
function CompactUnitFrame_UpdateName() end
C_NamePlate = {
    GetNamePlateForUnit = function() return nil end,
    GetNamePlates = function() return {} end,
}
C_Timer = { After = function(delay, callback) timers[#timers + 1] = { delay, callback } end }
function wipe(t) for key in pairs(t) do t[key] = nil end end

local unit = {}
function UnitThreatSituation(who) return who == "player" and unit.aggro and 2 or nil end
function UnitIsUnit(token, target) return unit.targetPlayer and token == "nameplate1target" and target == "player" or false end
function UnitIsOwnerOrControllerOfUnit() return false end
function UnitIsPlayer() return unit.player or false end
function UnitPlayerControlled() return unit.controlled or false end
function UnitCanAttack(who)
    if who == "player" then return unit.canAttack or false end
    return unit.canAttackUs or false
end
function UnitFactionGroup(who) return who == "player" and "Alliance" or unit.faction end
function UnitReaction() return unit.reaction end
function UnitIsPVP() return unit.pvp or false end

local calls = {}
local function count(name) calls[name] = (calls[name] or 0) + 1 end
local ns = {
    EnsureDB = function() count("db") end,
    AccessibleNumber = function(value) return type(value) == "number" and value or nil end,
    AccessibleBoolean = function(value) return type(value) == "boolean" and value or nil end,
    AccessibleValue = function(value) return type(value) ~= "table" and value or nil end,
    GetStylingEnabled = function() return true end,
    GetCategoryMode = function() return "active" end,
    GetAppearanceSetting = function() return "ABOVE" end,
    GetTRP3Setting = function() return false end,
    GetInterruptibleHighlightEnabled = function() return false end,
    GetThreatEnabled = function() return false end,
    GetReplaceBlizzardOverheadNames = function() return false end,
    GetHideCritterCompanionNames = function() return false end,
    PriorityColorForState = function() return 1, 0, 0 end,
    EffectColor = function() return 0, 1, 1 end,
    FontPath = function() return "Fonts\\ARIALN.TTF" end,
    ApplyCritterCompanionNameVisibility = function() count("critters") end,
    ApplyOverheadNameReplacement = function() count("overhead") end,
    DisableFriendlyClassColors = function() count("classColors") end,
    ApplyPendingManagedNameSettings = function() count("pending") end,
    ApplyManagedNameSettings = function() count("managed") end,
    RegisterSettingsPanel = function() count("settings") end,
    ShowNameplateConflictWarning = function() count("warning") end,
    OVERHEAD_REPLACEMENT_CVAR_SET = { unitnamefriendlyplayername = true },
    BLIZZARD_CRITTER_COMPANION_NAME_CVARS = {},
    FRIENDLY_COLOR_CVARS = {},
}
assert(loadfile("SimpleNameplates/NameplateClassification.lua"))("SimpleNameplates", ns)
assert(loadfile("SimpleNameplates/Nameplates.lua"))("SimpleNameplates", ns)
equal(#frames, 1, "one event frame")
local events = frames[1]
equal(#hooks, 2, "two Blizzard repair hooks")
equal(hooks[1].name, "CompactUnitFrame_UpdateHealthColor", "health hook")
equal(hooks[2].name, "CompactUnitFrame_UpdateName", "name hook")
local countEvents = 0
for _, registered in pairs(events.registered) do countEvents = countEvents + registered end
equal(countEvents, 13, "one registration for each event")
assert(events.scripts.OnEvent and events.scripts.OnUpdate, "event/update scripts installed")
events.scripts.OnEvent(events, "ADDON_LOADED", "AnotherAddon")
equal(calls.db, nil, "other addon ignored")
events.scripts.OnEvent(events, "ADDON_LOADED", "SimpleNameplates")
equal(calls.db, 1, "database initialized once")
equal(events.registered.ADDON_LOADED, nil, "load event unregistered")
events.scripts.OnEvent(events, "PLAYER_LOGIN")
equal(calls.settings, 1, "settings registration on login")
equal(calls.critters, 1, "managed critter settings on login")
equal(calls.overhead, 1, "overhead setting on login")
equal(calls.classColors, 1, "friendly class colors on login")
events.scripts.OnEvent(events, "CVAR_UPDATE", "UnitNameFriendlyPlayerName")
equal(calls.managed, 1, "managed CVar update reapplied")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
equal(calls.pending, 1, "deferred CVar action applied after combat")
events.scripts.OnUpdate(events, 0.5)
assert(ns.RefreshAll and ns.RestoreAll and ns.DebugUnit and ns.StateForUnit, "runtime API")

local cases = {
    { label = "attacking NPC", data = { reaction = 3, aggro = true }, state = "attacking" },
    { label = "hostile NPC", data = { reaction = 3 }, state = "hostile" },
    { label = "attackable neutral", data = { reaction = 4 }, state = "unfriendlyNPC" },
    { label = "opposing PC", data = { player = true, faction = "Horde", reaction = 2 }, state = "unfriendlyPC" },
    { label = "attackable opposing PC", data = { player = true, faction = "Horde", canAttack = true }, state = "hostile" },
    { label = "same faction PC", data = { player = true, faction = "Alliance", reaction = 5 }, state = "friendlyPC" },
    { label = "controlled pet", data = { controlled = true, reaction = 5 }, state = "other" },
    { label = "friendly NPC", data = { reaction = 5 }, state = "other" },
    { label = "restricted reaction fallback", data = { reaction = {} }, state = "other" },
}
for _, case in ipairs(cases) do
    unit = case.data
    equal(ns.StateForUnit("nameplate1"), case.state, case.label)
end
local visited, largest = {}, 0
local function CheckUpvalues(fn)
    if visited[fn] then return end
    visited[fn] = true
    local count = 0
    while true do
        local name, value = debug.getupvalue(fn, count + 1)
        if not name then break end
        count = count + 1
        if type(value) == "function" then CheckUpvalues(value) end
    end
    if count > largest then largest = count end
    assert(count <= 60, "function exceeds WoW upvalue limit: " .. count)
end
for _, fn in ipairs({ ns.StateForUnit, ns.RefreshAll, ns.RestoreAll,
    ns.DebugUnit, events.scripts.OnEvent, events.scripts.OnUpdate,
    hooks[1].callback, hooks[2].callback }) do
    CheckUpvalues(fn)
end
print("Nameplates smoke: passed")
