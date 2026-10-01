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
function hooksecurefunc(name, callback, objectCallback)
    hooks[#hooks + 1] = { name = name, callback = objectCallback or callback }
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
local unitExists = true
function UnitExists() return unitExists end
function UnitName() return "Diagnostic Target" end
function UnitAffectingCombat() return false end
function UnitIsInteractable() return unit.interactable or false end

local appearance = { namePlacement = "ABOVE", nameSize = 12, nameFont = "ARIALN", threatFont = "ARIALN" }
local categoryMode = "active"
local trp3Options = {}
local calls = {}
local stylingEnabled = true
local highlightEnabled = false
local function count(name) calls[name] = (calls[name] or 0) + 1 end
local ns = {
    EnsureDB = function() count("db") end,
    AccessibleNumber = function(value) return type(value) == "number" and value or nil end,
    AccessibleBoolean = function(value) if type(value) == "boolean" then return value end end,
    AccessibleValue = function(value) return value end,
    GetStylingEnabled = function() return stylingEnabled end,
    GetCategoryMode = function() return categoryMode end,
    GetAppearanceSetting = function(key) return appearance[key] end,
    GetTRP3Setting = function(key) return trp3Options[key] or false end,
    GetInterruptibleHighlightEnabled = function() return highlightEnabled end,
    GetThreatEnabled = function() return false end,
    GetHideCritterCompanionNames = function() return false end,
    PriorityColorForState = function() return 1, 0, 0 end,
    EffectColor = function() return 0, 1, 1 end,
    FontPath = function() return "Fonts\\ARIALN.TTF" end,
    ApplyCritterCompanionNameVisibility = function() count("critters") end,
    DisableFriendlyClassColors = function() count("classColors") end,
    ApplyPendingManagedNameSettings = function() count("pending") end,
    ApplyManagedNameSettings = function() count("managed") end,
    RegisterSettingsPanel = function() count("settings") end,
    ShowNameplateConflictWarning = function() count("warning") end,
    MANAGED_NAME_CVAR_SET = { unitnamefriendlyplayername = true },
    BLIZZARD_CRITTER_COMPANION_NAME_CVARS = {},
    FRIENDLY_COLOR_CVARS = {},
}
for _, file in ipairs({ "WorldContext.lua", "EntityFacts.lua", "NameplateClassification.lua", "PresentationCapabilities.lua", "PresentationRules.lua", "NameplateFrames.lua", "NameplateText.lua", "NameplateThreat.lua", "CastHighlight.lua", "NameplateRestoration.lua", "NameplatePresentation.lua", "Nameplates.lua", "Diagnostics.lua" }) do
    assert(loadfile("SimpleNameplates/" .. file))("SimpleNameplates", ns)
end
equal(#frames, 1, "one event frame")
local events = frames[1]
equal(#hooks, 2, "two Blizzard repair hooks")
equal(hooks[1].name, "CompactUnitFrame_UpdateHealthColor", "health hook")
equal(hooks[2].name, "CompactUnitFrame_UpdateName", "name hook")
local countEvents = 0
for _, registered in pairs(events.registered) do countEvents = countEvents + registered end
equal(countEvents, 22, "one registration for each event")
assert(events.scripts.OnEvent and events.scripts.OnUpdate, "event/update scripts installed")
events.scripts.OnEvent(events, "ADDON_LOADED", "AnotherAddon")
equal(calls.db, nil, "other addon ignored")
events.scripts.OnEvent(events, "ADDON_LOADED", "SimpleNameplates")
equal(calls.db, 1, "database initialized once")
equal(events.registered.ADDON_LOADED, nil, "load event unregistered")
events.scripts.OnEvent(events, "PLAYER_LOGIN")
equal(calls.settings, 1, "settings registration on login")
equal(calls.critters, 1, "managed critter settings on login")
equal(calls.overhead, nil, "removed replacement has no login action")
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
    { label = "attackable neutral", data = { reaction = 4, canAttackUs = true }, state = "neutral" },
    { label = "opposing PC", data = { player = true, faction = "Horde", reaction = 2 }, state = "friendly" },
    { label = "attackable opposing PC", data = { player = true, faction = "Horde", canAttack = true }, state = "hostile" },
    { label = "same faction PC", data = { player = true, faction = "Alliance", reaction = 5 }, state = "friendly" },
    { label = "controlled pet", data = { controlled = true, reaction = 5 }, state = "useless" },
    { label = "friendly NPC", data = { reaction = 5 }, state = "useless" },
    { label = "useful NPC", data = { reaction = 5, interactable = true }, state = "useful" },
    { label = "hostile vendor", data = { reaction = 3, interactable = true }, state = "hostile" },
    { label = "restricted reaction fallback", data = { reaction = {} }, state = "useless" },
}
for _, case in ipairs(cases) do
    unit = case.data
    equal(ns.StateForUnit("nameplate1"), case.state, case.label)
end
-- Exercise presentation across modules, not just event registration.
local function Region()
    local region = { shown = true, alpha = 1, height = 20 }
    function region:Show() self.shown = true end
    function region:Hide() self.shown = false end
    function region:IsShown() return self.shown end
    function region:IsVisible() return self.shown end
    function region:SetAlpha(value) self.alpha = value end
    function region:GetAlpha() return self.alpha end
    function region:SetHeight(value) self.height = value end
    function region:GetHeight() return self.height end
    function region:SetText(value) self.text = value end
    function region:GetText() return self.text end
    function region:SetFormattedText(format, value) self.text = format:format(value) end
    function region:SetFont(font, size, flags) self.font, self.size, self.flags = font, size, flags end
    function region:GetFont() return self.font, self.size, self.flags end
    function region:SetTextColor(r, g, b) self.r, self.g, self.b = r, g, b end
    function region:GetTextColor() return self.r, self.g, self.b end
    function region:SetVertexColor(r, g, b, a) self.vr, self.vg, self.vb, self.va = r, g, b, a end
    function region:GetVertexColor() return self.vr, self.vg, self.vb, self.va end
    function region:SetStatusBarColor(r, g, b) self.barR, self.barG, self.barB = r, g, b end
    function region:ClearAllPoints() self.points = {} end
    function region:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function region:CreateFontString() return Region() end
    for _, method in ipairs({ "SetShadowColor", "SetShadowOffset", "SetJustifyH",
        "SetWordWrap", "SetMaxLines", "SetDrawLayer" }) do region[method] = function() end end
    return region
end
local plateFrame = Region()
plateFrame.unit, plateFrame.name = "nameplate1", Region()
plateFrame.healthBar, plateFrame.HealthBarsContainer = Region(), Region()
local plate = { UnitFrame = plateFrame }
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return { plate } end

unit = { reaction = 3 }
ns.RefreshAll()
equal(plateFrame.SNPState, "hostile", "hostile presentation category")
equal(plateFrame.healthBar.shown, true, "hostile bar visible")
equal(plateFrame.name.r, 1, "bar name white red")
equal(plateFrame.name.g, 1, "bar name white green")
equal(plateFrame.healthBar.barG, 0, "priority applied to health bar")

unit = { player = true, faction = "Alliance", reaction = 5 }
ns.RefreshAll()
equal(plateFrame.healthBar.shown, false, "friendly name-only presentation")
equal(plateFrame.name.g, 0, "priority applied to floating name")
plateFrame.name:SetTextColor(0, 1, 1)
events.scripts.OnUpdate(events, 0.5)
equal(plateFrame.name.g, 0, "cached drift repaired across module boundary")

ns.TRP3 = { GetDisplayInfo = function()
    return { roleplayingName = "Roleplay Name", fullTitle = "Long Title" }
end }
trp3Options = { useRoleplayingName = true, showFullTitle = true }
ns.RefreshAll()
equal(plateFrame.name.text, "Roleplay Name", "TRP3 name retained")
equal(plateFrame.SNPFullTitleText.shown, true, "name-only long title shown")
-- Combat changes presentation without changing the Friendly classification.
appearance.namePlacement = "INSIDE"
local oldNameStyle = {}
for key, value in pairs(plateFrame.SNPNameStyle) do oldNameStyle[key] = value end
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
events.scripts.OnUpdate(events, 0.5)
equal(plateFrame.SNPState, "friendly", "combat does not change category")
equal(plateFrame.healthBar.shown, true, "friendly combat bar")
equal(plateFrame.SNPFullTitleText.shown, false, "friendly combat hides long title")
equal(plateFrame.SNPInsideName.shown, true, "friendly combat inside name")
equal(plateFrame.healthBar.height, 14, "friendly combat padding")
equal(plateFrame.name.g, 1, "bar name is white")
plateFrame.SNPNameStyle = oldNameStyle
equal(ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get()), false, "stale cache rejected")
events.scripts.OnUpdate(events, 0.5)
equal(plateFrame.healthBar.shown, true, "stale drift cannot undo combat bar")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
-- A Blizzard name hook must apply the whole new decision before the queued refresh.
hooks[2].callback(plateFrame)
equal(plateFrame.healthBar.shown, false, "name hook applies combat exit")
equal(plateFrame.SNPFullTitleText.shown, true, "combat exit restores title")
equal(plateFrame.SNPInsideName.shown, false, "combat exit removes inside name")
equal(plateFrame.name.alpha, 1, "combat exit restores floating name")
equal(plateFrame.healthBar.height, 20, "combat exit restores height")

unit = { reaction = 3 }
appearance.namePlacement = "INSIDE"
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.shown, false, "bar suppresses long title")
equal(plateFrame.SNPInsideName.text, "Roleplay Name", "inside name retained")
equal(plateFrame.name.alpha, 0, "original inside name concealed")
equal(plateFrame.healthBar.height, 14, "inside padding retained")

categoryMode = "inactive"
ns.RefreshAll()
equal(plateFrame.SNPState, nil, "inactive restores category presentation")
equal(plateFrame.SNPInsideName.shown, false, "inside overlay restored")
equal(plateFrame.name.alpha, 1, "original name alpha restored")
equal(plateFrame.healthBar.height, 20, "original bar height restored")
categoryMode = "active"
appearance.namePlacement = "ABOVE"
ns.RefreshAll()
ns.RestoreAll()
equal(plateFrame.SNPState, nil, "master restoration reachable")
C_NamePlate.GetNamePlateForUnit = function() return nil end
C_NamePlate.GetNamePlates = function() return {} end

-- Existing cast effects and their Blizzard icon hook obey the shared decision.
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return {plate} end
unit = { player = true, faction = "Alliance", reaction = 5 }
plateFrame.castBar = Region()
plateFrame.castBar.Icon = Region()
local castOverlay = Region()
function castOverlay:SetShown(shown) self.shown = shown end
plateFrame.SNPInterruptibleHighlight = {
    owner = plateFrame, castBar = plateFrame.castBar, frame = castOverlay, border = {},
}
highlightEnabled = true
ns.RefreshAll()
equal(castOverlay.shown, false, "name-only cast effect hidden")
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
events.scripts.OnUpdate(events, 0.5)
equal(castOverlay.shown, true, "combat cast effect follows Blizzard icon")
local iconHook = hooks[#hooks].callback
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
events.scripts.OnUpdate(events, 0.5)
iconHook(plateFrame.castBar.Icon, true)
equal(castOverlay.shown, false, "icon hook cannot revive name-only effect")
highlightEnabled = false
-- If a bar remains shown despite a requested hide, titles must remain hidden.
local hideBar = plateFrame.healthBar.Hide
plateFrame.healthBar.Hide = function() end
plateFrame.healthBar.shown = true
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.shown, false, "observed bar suppresses title")
plateFrame.healthBar.Hide = hideBar
ns.RefreshAll()

-- Missing bars use a colored floating name and permit a title even in combat.
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return {plate} end
local savedBar = plateFrame.healthBar
plateFrame.healthBar = nil
unit = { reaction = 3 }
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
events.scripts.OnUpdate(events, 0.5)
equal(plateFrame.SNPPresentation.showHealthBar, false, "no fabricated health bar")
equal(plateFrame.SNPPresentation.nameOnly, true, "missing bar uses name color")
equal(plateFrame.name.g, 0, "missing-bar priority color")
equal(plateFrame.SNPFullTitleText.shown, true, "missing bar allows long title")
plateFrame.healthBar = savedBar
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
ns.RestoreAll()

-- Context events still run with styling disabled; combat state is independent.
stylingEnabled = false
function GetZoneText() return "Silvermoon City" end
function GetSubZoneText() return "Shared" end
function InCombatLockdown() return false end
C_PvP = { GetZonePVPInfo = function() return "sanctuary", false end }
events.scripts.OnEvent(events, "ZONE_CHANGED")
equal(ns.WorldContext.Get().sanctuary, true, "context updated with styling off")
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
equal(ns.WorldContext.Get().inCombat, true, "combat cached with styling off")
equal(ns.WorldContext.Get().combatLockdown, false, "lockdown separate from combat")
stylingEnabled = true
-- All mutation entry points skip forbidden frames, including direct Blizzard hooks.
local forbidden = setmetatable({ IsForbidden = function() return true end }, {
    __index = function(_, key) error("forbidden frame inspected: " .. key) end,
    __newindex = function() error("forbidden frame modified") end,
})
C_NamePlate.GetNamePlateForUnit = function() return {UnitFrame = forbidden} end
C_NamePlate.GetNamePlates = function() return {{UnitFrame = forbidden}} end
ns.RefreshAll()
ns.RestoreAll()
hooks[1].callback(forbidden)
hooks[2].callback(forbidden)
events.scripts.OnUpdate(events, 0.5)
events.scripts.OnEvent(events, "NAME_PLATE_UNIT_REMOVED", "nameplate1")
ns.NameplateText.RestoreNameDisplay(forbidden)
equal(ns.NameplateText.CachedNameHasDrifted(forbidden), false, "forbidden drift skipped")
ns.CastHighlight.EnsureInterruptibleHighlight(forbidden)
ns.CastHighlight.UpdateInterruptibleHighlight(forbidden)
-- A protected frame skipped in lockdown is styled again after combat exit.
local locked = true
function InCombatLockdown() return locked end
plateFrame.IsProtected = function() return true end
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return {plate} end
plateFrame.SNPState = nil
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
ns.RefreshAll()
equal(plateFrame.SNPState, nil, "protected frame skipped during lockdown")
locked = false
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
events.scripts.OnUpdate(events, 0.5)
assert(plateFrame.SNPState, "protected frame refreshed after lockdown")
plateFrame.IsProtected = nil
C_NamePlate.GetNamePlateForUnit = function() return nil end
C_NamePlate.GetNamePlates = function() return {} end

-- Disabled styling still retries restoration after combat lockdown ends.
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return {plate} end
unit = { player = true, faction = "Alliance", reaction = 5 }
appearance.namePlacement = "INSIDE"
locked = false
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
ns.RefreshAll()
equal(plateFrame.healthBar.height, 14, "styled height before lockdown")
plateFrame.IsProtected = function() return true end
locked = true
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
stylingEnabled = false
ns.RestoreAll()
events.scripts.OnUpdate(events, 0.5)
assert(plateFrame.SNPState, "protected style retained until safe restoration")
locked = false
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
events.scripts.OnUpdate(events, 0.5)
equal(plateFrame.SNPState, nil, "disabled styling restoration retried")
equal(plateFrame.SNPPresentation, nil, "presentation cache cleared on restore")
equal(plateFrame.SNPInsideName.shown, false, "deferred inside name hidden")
equal(plateFrame.healthBar.height, 20, "deferred original height restored")
plateFrame.IsProtected = nil
stylingEnabled = true
ns.RefreshAll()
local baseForbidden = true
plate.IsForbidden = function() return baseForbidden end
stylingEnabled = false
ns.RestoreAll()
events.scripts.OnUpdate(events, 0.5)
assert(plateFrame.SNPState, "forbidden base plate restoration postponed")
baseForbidden = false
events.scripts.OnUpdate(events, 0.5)
equal(plateFrame.SNPState, nil, "base plate restoration retried with styling off")
plate.IsForbidden = nil
stylingEnabled = true
categoryMode = "active"
ns.RefreshAll()
local frameForbidden = true
plateFrame.IsForbidden = function() return frameForbidden end
categoryMode = "inactive"
ns.RefreshAll()
frameForbidden = false
events.scripts.OnUpdate(events, 0.5)
equal(plateFrame.SNPState, nil, "inactive restoration after access returns without context event")
plateFrame.IsForbidden = nil
categoryMode = "active"
ns.RefreshAll()
-- Deferred removed-unit cleanup cannot clear a newly styled recycled frame.
plateFrame.IsProtected = function() return true end
locked = true
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
C_NamePlate.GetNamePlateForUnit = function() return nil end
events.scripts.OnEvent(events, "NAME_PLATE_UNIT_REMOVED", "nameplate1")
plateFrame.unit = "nameplate2"
locked = false
ns.WorldContext.Refresh("PLAYER_REGEN_ENABLED")
C_NamePlate.GetNamePlateForUnit = function() return plate end
ns.RefreshAll()
equal(plateFrame.SNPOriginalUnit, "nameplate2", "recycled frame captures current owner")
events.scripts.OnUpdate(events, 0.5)
assert(plateFrame.SNPState, "old pending cleanup does not clear recycled style")
equal(plateFrame.name.text, "Roleplay Name", "recycled name remains")
plateFrame.IsProtected = nil
plateFrame.unit = "nameplate1"
ns.RefreshAll()

-- Removed plate lookup may already be gone; retain the last known frame for cleanup.
C_NamePlate.GetNamePlateForUnit = function() return nil end
C_NamePlate.GetNamePlates = function() return {} end
events.scripts.OnEvent(events, "NAME_PLATE_UNIT_REMOVED", "nameplate1")
equal(plateFrame.SNPState, nil, "removed known frame cleaned")
equal(plateFrame.name.text, "", "removed name cleared")
appearance.namePlacement = "ABOVE"

-- Execute the diagnostic path: the extracted targeting predicate must remain available.
local output, originalPrint = {}, print
print = function(message) output[#output + 1] = message end
unit = { player = true, faction = "Horde", canAttack = true, targetPlayer = true }
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("targeting your controlled unit: yes", 1, true),
    "diagnostics use the classification targeting predicate")
-- Diagnostics may read an accessible cast bar but must not create an overlay or hook.
local frameCount, hookCount = #frames, #hooks
plateFrame.castBar = Region()
C_NamePlate.GetNamePlateForUnit = function() return plate end
plateFrame.SNPInterruptibleHighlight = nil
ns.DebugUnit("nameplate1")
equal(#frames, frameCount, "diagnostic creates no frame")
equal(#hooks, hookCount, "diagnostic installs no hook")
equal(plateFrame.SNPInterruptibleHighlight, nil, "diagnostic creates no overlay")
output = {}
categoryMode = "inactive"
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("configured display: Blizzard presentation", 1, true), "inactive diagnosed")
categoryMode = "active"
stylingEnabled = false
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("configured color: Blizzard-controlled", 1, true), "disabled diagnosed")
stylingEnabled = true
C_NamePlate.GetNamePlateForUnit = function() return {UnitFrame = forbidden} end
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("Presentation access: forbidden", 1, true), "forbidden diagnosed")
output = {}
unitExists = false
ns.DebugUnit("target")
assert(table.concat(output, "\n"):find("Simple Nameplates context:", 1, true), "no-target context")
assert(table.concat(output, "\n"):find("No target selected.", 1, true), "no-target reported")
unitExists = true
print = originalPrint

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
