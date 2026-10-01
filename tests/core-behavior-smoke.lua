-- Characterization of the current Core.lua contract.
-- Run from the repository root: lua tests/core-behavior-smoke.lua
-- LuaTeX can also run it with: luatex --luaonly tests/core-behavior-smoke.lua

local function equal(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local character = "Player-One"
local inCombat = false
local cvars = {}
local writes = {}
local rejectedWrites = {}

function UnitGUID() return character end
function UnitFullName() return "Fallback", "Realm" end
function strtrim(value) return value:match("^%s*(.-)%s*$") end
function InCombatLockdown() return inCombat end
function wipe(t) for key in pairs(t) do t[key] = nil end end
C_CVar = {
    GetCVar = function(name) return cvars[name] or "1" end,
    SetCVar = function(name, value)
        if rejectedWrites[name] == "silent" then return end
        if rejectedWrites[name] then error("CVar write blocked") end
        cvars[name] = value
        writes[#writes + 1] = { name, value }
    end,
}
local function loadCore()
    local namespace = {}
    for _, file in ipairs({ "Defaults.lua", "Core.lua", "ManagedNames.lua", "Database.lua" }) do
        assert(loadfile("SimpleNameplates/" .. file))("SimpleNameplates", namespace)
    end
    return namespace
end
local function fresh()
    SimpleNameplatesDB = nil
    cvars, writes, rejectedWrites = {}, {}, {}
    inCombat, character = false, "Player-One"
    return loadCore()
end

-- Fresh defaults and independent character selection.
local ns = fresh()
local db = ns.EnsureDB()
equal(db.schemaVersion, 2, "schema")
equal(ns.GetActiveProfileName(), "Default", "fresh selection")
equal(ns.GetStylingEnabled(), true, "master default")
equal(ns.GetCategoryMode("friendlyPC"), "active", "category default")
equal(ns.GetTRP3Enabled(), false, "TRP3 default")
equal(ns.GetThreatEnabled(), true, "threat default")
equal(ns.GetInterruptibleHighlightEnabled(), false, "cast default")
equal(ns.GetAppearanceSetting("nameSize"), 12, "name size default")
equal(ns.GetAppearanceSetting("namePlacement"), "ABOVE", "placement default")
equal(ns.PriorityColorForState("attacking"), 1, "default red component")
equal(ns.SetActiveProfileName("High Contrast"), true, "select bundled")
equal(ns.GetActiveProfileName(), "High Contrast", "bundled selected")
equal(ns.PriorityColorForState("attacking"), 1, "contrast red component")
local _, green = ns.PriorityColorForState("attacking")
equal(green, 0, "contrast magenta green component")
character = "Player-Two"
equal(ns.GetActiveProfileName(), "Default", "other character untouched")
character = "Player-One"
equal(ns.GetActiveProfileName(), "High Contrast", "first character selection retained")

-- Profile lifecycle, independent copies, name validation, and reassignment.
equal(ns.CreateProfile("Test"), true, "create")
equal(ns.GetAppearanceSetting("nameSize"), 12, "create factory values")
ns.SetAppearanceSetting("nameSize", 17)
ns.SetPriorityColor("attacking", 0.1, 0.2, 0.3)
equal(ns.CopyActiveProfile("Copy"), true, "copy")
equal(ns.GetAppearanceSetting("nameSize"), 17, "copy settings")
equal(ns.PriorityColorForState("attacking"), 0.1, "copy color")
ns.SetPriorityColor("attacking", 0.7, 0.2, 0.3)
equal(ns.SetActiveProfileName("Test"), true, "switch original")
equal(ns.PriorityColorForState("attacking"), 0.1, "copy independent")
character = "Player-Two"
equal(ns.SetActiveProfileName("Test"), true, "second character selects original")
character = "Player-One"
equal(ns.RenameActiveProfile("Renamed"), true, "rename")
equal(db.profileKeys["Player-Two"], "Renamed", "rename all assignments")
equal(ns.DeleteActiveProfile(), true, "delete")
equal(db.profileKeys["Player-Two"], "Default", "delete reassigns second")
equal(ns.GetActiveProfileName(), "Default", "delete reassigns active")
equal(ns.DeleteActiveProfile(), false, "Default protected")
equal(ns.RenameActiveProfile("Anything"), false, "Default rename protected")
equal(ns.CreateProfile(" copy "), false, "case-insensitive duplicate")
ns.SetActiveProfileName("High Contrast")
ns.SetPriorityColor("attacking", 0.2, 0.2, 0.2)
ns.RestoreBundledProfiles()
local red, contrastGreen, blue = ns.PriorityColorForState("attacking")
equal(red, 1, "restore red")
equal(contrastGreen, 0, "restore green")
equal(blue, 1, "restore blue")

-- Valid version-2 values survive reload; malformed values fall back individually.
SimpleNameplatesDB = {
    schemaVersion = 2,
    global = {
        stylingEnabled = false, categoryModes = { friendlyPC = "hide", hostile = "bad" },
        trp3 = { enabled = true, showOOC = "wrong" },
        managedNameCVarOriginals = {
            UnitNameFriendlyPlayerName = "original",
            InventedCVar = "discard",
        },
    },
    profiles = {
        Default = {
            appearance = { nameSize = 25, nameFont = "bad", namePlacement = "INSIDE" },
            priorityColors = { attacking = { r = 0.4, g = 0.2, b = 0.1 } },
            showThreat = false,
        },
        ["High Contrast"] = {},
    },
    profileKeys = { ["Player-One"] = "Missing" },
}
ns = loadCore()
db = ns.EnsureDB()
equal(ns.GetStylingEnabled(), false, "valid global retained")
equal(ns.GetCategoryMode("friendlyPC"), "active", "removed category mode discarded")
equal(ns.GetCategoryMode("hostile"), "active", "invalid category reset")
equal(ns.GetTRP3Enabled(), true, "valid TRP3 retained")
equal(ns.GetTRP3Setting("showOOC"), true, "invalid TRP3 reset")
equal(ns.GetAppearanceSetting("nameSize"), 25, "valid appearance retained")
equal(ns.GetAppearanceSetting("nameFont"), "ARIALN", "invalid font reset")
equal(ns.GetAppearanceSetting("namePlacement"), "INSIDE", "valid placement retained")
equal(ns.GetThreatEnabled(), false, "valid profile toggle retained")
equal(ns.PriorityColorForState("attacking"), 0.4, "valid color retained")
equal(ns.GetActiveProfileName(), "Default", "invalid assignment reset")
equal(db.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName, "original", "ledger retained")
equal(db.global.managedNameCVarOriginals.InventedCVar, nil, "unknown ledger entry dropped")
ns.SetCategoryMode("friendlyPC", "inactive")
ns.SetCategoryMode("friendlyPC", "hide")
equal(ns.GetCategoryMode("friendlyPC"), "inactive", "removed category mode rejected by setter")
-- A schema marker does not discard valid fields; no legacy aliases are converted.
for _, marker in ipairs({ 999, false }) do
    SimpleNameplatesDB = {
        schemaVersion = marker,
        global = {
            stylingEnabled = false,
            hideBlizzardMinionNames = true,
            hideCritterCompanionNames = true,
            categoryModes = { hostile = "inactive", other = "invalid" },
            legacyStylingEnabled = true,
        },
        profiles = {
            Default = { appearance = { nameSize = 25, nameFont = "invalid" } },
            Custom = { showThreat = false },
        },
        profileKeys = { ["Player-One"] = "Custom" },
        legacyAppearance = { nameSize = 30 },
    }
    ns = loadCore()
    db = ns.EnsureDB()
    equal(db.schemaVersion, 2, "current schema marker")
    equal(ns.GetStylingEnabled(), false, "valid setting retained across schema markers")
    equal(ns.GetCategoryMode("hostile"), "inactive", "valid mode retained")
    equal(ns.GetCategoryMode("other"), "active", "invalid mode discarded")
    equal(db.profiles.Default.appearance.nameSize, 25, "valid appearance retained")
    equal(db.profiles.Default.appearance.nameFont, "ARIALN", "invalid font discarded")
    equal(ns.GetActiveProfileName(), "Custom", "valid selection retained")
    equal(db.global.hideBlizzardMinionNames, nil, "removed setting discarded")
    equal(db.global.legacyStylingEnabled, nil, "unknown setting discarded")
    equal(db.legacyAppearance, nil, "legacy layout not converted")
    equal(ns.GetHideCritterCompanionNames(), true, "critter toggle retained")
end

-- Replacement CVar capture, restoration, reload, and combat deferral.
ns = fresh()
cvars.UnitNameFriendlyPlayerName = "original"
cvars.nameplateShowFriendlyPlayers = "original-plates"
ns.SetReplaceBlizzardOverheadNames(true)
equal(cvars.UnitNameFriendlyPlayerName, "0", "replacement applies name CVar")
equal(cvars.nameplateShowFriendlyPlayers, "1", "replacement requests player plates")
equal(SimpleNameplatesDB.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName,
    "original", "capture original once")
ns.SetCategoryMode("friendlyPC", "active")
ns.SetReplaceBlizzardOverheadNames(true)
equal(cvars.UnitNameFriendlyPlayerName, "0", "replacement claims name CVar")
equal(cvars.nameplateShowFriendlyPlayers, "1", "replacement claims plate CVar")
ns.SetCategoryMode("friendlyPC", "inactive")
equal(cvars.UnitNameFriendlyPlayerName, "original", "last name claim restored")
equal(cvars.nameplateShowFriendlyPlayers, "original-plates", "last plate claim restored")
ns.SetCategoryMode("friendlyPC", "active")
ns = loadCore()
ns.EnsureDB()
ns.RestoreOverheadNameSettings()
equal(cvars.UnitNameFriendlyPlayerName, "original", "reload restore original")
equal(next(SimpleNameplatesDB.global.managedNameCVarOriginals), nil, "restore clears ledger")
inCombat = true
local before = #writes
ns.SetCategoryMode("friendlyPC", "active")
equal(#writes, before, "combat defers writes")
inCombat = false
ns.ApplyPendingManagedNameSettings()
equal(cvars.UnitNameFriendlyPlayerName, "0", "pending applies after combat")
ns.SetStylingEnabled(false)
ns.RestoreOverheadNameSettings()
equal(cvars.UnitNameFriendlyPlayerName, "original", "disabled restores originals")


-- A failed restoration must retain its original for a later retry.
ns = fresh()
cvars.UnitNameFriendlyPlayerName = "custom"
ns.SetReplaceBlizzardOverheadNames(true)
rejectedWrites.UnitNameFriendlyPlayerName = true
ns.SetCategoryMode("friendlyPC", "inactive")
equal(cvars.UnitNameFriendlyPlayerName, "0", "failed restore leaves modified CVar")
equal(SimpleNameplatesDB.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName,
    "custom", "failed restore retains original")
rejectedWrites.UnitNameFriendlyPlayerName = "silent"
ns.ApplyPendingManagedNameSettings()
equal(SimpleNameplatesDB.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName,
    "custom", "silent refusal retains original")
rejectedWrites.UnitNameFriendlyPlayerName = nil
ns.ApplyPendingManagedNameSettings()
equal(cvars.UnitNameFriendlyPlayerName, "custom", "failed restore retries")
equal(SimpleNameplatesDB.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName,
    nil, "successful retry clears original")

-- An explicit restore in combat waits until combat ends, keeping the ledger.
ns.SetCategoryMode("friendlyPC", "active")
inCombat = true
ns.RestoreOverheadNameSettings()
equal(SimpleNameplatesDB.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName,
    "custom", "combat restore retains original")
equal(cvars.UnitNameFriendlyPlayerName, "0", "combat restore makes no write")
inCombat = false
ns.ApplyPendingManagedNameSettings()
equal(cvars.UnitNameFriendlyPlayerName, "custom", "combat restore retries")

-- Friendly class-color settings have their own original-value capture and retry.
ns = fresh()
local friendly = ns.FRIENDLY_COLOR_CVARS[1]
cvars[friendly] = "class-original"
ns.DisableFriendlyClassColors()
equal(cvars[friendly], "0", "friendly class color disabled")
rejectedWrites[friendly] = true
ns.RestoreFriendlyClassColors()
equal(cvars[friendly], "0", "failed friendly restore retains changed CVar")
rejectedWrites[friendly] = nil
ns.ApplyPendingManagedNameSettings()
equal(cvars[friendly], "class-original", "friendly restore retries")
ns.DisableFriendlyClassColors()
inCombat = true
ns.RestoreFriendlyClassColors()
equal(cvars[friendly], "0", "friendly combat restore deferred")
inCombat = false
ns.ApplyPendingManagedNameSettings()
equal(cvars[friendly], "class-original", "friendly combat restore applied")

-- Critter hiding remains independent; replacement still manages minion names.
ns = fresh()
cvars.UnitNameFriendlyPetName = "pet-original"
cvars.UnitNameNonCombatCreatureName = "critter-original"
equal(ns.GetHideBlizzardMinionNames, nil, "minion getter removed")
equal(ns.SetHideBlizzardMinionNames, nil, "minion setter removed")
ns.SetHideCritterCompanionNames(true)
equal(cvars.UnitNameFriendlyPetName, "pet-original", "critter hide leaves pets alone")
equal(cvars.UnitNameNonCombatCreatureName, "0", "dedicated critter hide retained")
ns.SetReplaceBlizzardOverheadNames(true)
equal(cvars.UnitNameFriendlyPetName, "0", "replacement retains minion-name behavior")
ns.SetReplaceBlizzardOverheadNames(false)
equal(cvars.UnitNameFriendlyPetName, "pet-original", "replacement pet claim restored")
equal(cvars.UnitNameNonCombatCreatureName, "0", "critter hide remains independent")
ns.SetHideCritterCompanionNames(false)
equal(cvars.UnitNameNonCombatCreatureName, "critter-original", "critter original restored")

-- Valid restoration records remain usable after an obsolete setting is discarded.
ns = fresh()
db = ns.EnsureDB()
db.global.hideBlizzardMinionNames = true
db.global.managedNameCVarOriginals.UnitNameFriendlyPetName = "pre-addon-pet"
cvars.UnitNameFriendlyPetName = "0"
ns = loadCore()
db = ns.EnsureDB()
equal(db.global.hideBlizzardMinionNames, nil, "obsolete minion toggle discarded")
ns.ApplyManagedNameSettings()
equal(cvars.UnitNameFriendlyPetName, "pre-addon-pet", "valid pet original restored")

-- Removed Hide values fall back for every category and old CVar claims restore.
ns = fresh()
db = ns.EnsureDB()
for state in pairs(db.global.categoryModes) do db.global.categoryModes[state] = "hide" end
db.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName = "pre-hide-original"
cvars.UnitNameFriendlyPlayerName = "0"
ns = loadCore()
db = ns.EnsureDB()
for state in pairs(db.global.categoryModes) do
    equal(ns.GetCategoryMode(state), "active", "old hide resets: " .. state)
end
ns.ApplyManagedNameSettings()
equal(cvars.UnitNameFriendlyPlayerName, "pre-hide-original", "old category hide CVar restored")
equal(next(db.global.managedNameCVarOriginals), nil, "old category claims cleared")

-- All declared addon modules must exist, compile, and load in dependency order.
local toc = assert(io.open("SimpleNameplates/SimpleNameplates.toc", "r"))
local modules = {}
for line in toc:lines() do
    if line:match("%.lua$") then
        modules[#modules + 1] = line
        assert(loadfile("SimpleNameplates/" .. line), line .. " must compile")
    end
end
toc:close()
equal(table.concat(modules, ","),
    "Defaults.lua,Core.lua,ManagedNames.lua,Database.lua,TRP3.lua,NameplateClassification.lua,NameplateFrames.lua,NameplateText.lua,NameplateThreat.lua,CastHighlight.lua,NameplatePresentation.lua,Nameplates.lua,Diagnostics.lua,SettingsControls.lua,SettingsAbout.lua,SettingsBehavior.lua,SettingsProfiles.lua,SettingsAppearance.lua,SettingsTRP3.lua,Settings.lua",
    "TOC module order")

print("Core behavior smoke: passed")
