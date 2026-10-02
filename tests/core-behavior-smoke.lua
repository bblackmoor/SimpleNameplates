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
equal(ns.GetCategoryMode("friendly"), "active", "category default")
equal(ns.GetTRP3Enabled(), false, "TRP3 default")
equal(ns.GetThreatEnabled(), true, "threat default")
equal(ns.GetInterruptibleHighlightEnabled(), false, "cast default")
equal(ns.GetAppearanceSetting("matchSanctuaryFont"), true, "sanctuary matching default")
ns.SetAppearanceSetting("matchSanctuaryFont", false)
equal(ns.CopyActiveProfile("Font copy"), true, "copy sanctuary font choice")
equal(ns.GetAppearanceSetting("matchSanctuaryFont"), false, "copied sanctuary font choice")
ns.ResetAppearance()
equal(ns.GetAppearanceSetting("matchSanctuaryFont"), true, "reset sanctuary matching default")
ns.DeleteActiveProfile()
equal(ns.GetAppearanceSetting("matchSanctuaryFont"), false, "profile choice independent")
ns.ResetAppearance()
ns.SetAppearanceSetting("matchSanctuaryFont", "false")
equal(ns.GetAppearanceSetting("matchSanctuaryFont"), true, "invalid setter ignored")
equal(ns.GetAppearanceSetting("nameFont"), "FRIZQT", "name font default")
equal(ns.GetAppearanceSetting("nameSize"), 21, "name size default")
equal(ns.GetAppearanceSetting("namePlacement"), "ABOVE", "placement default")
equal(ns.PriorityColorForState("attacking"), 1, "default red component")
for _, case in ipairs({
    {"sanctuaryFriendly", 135, 206, 235},
    {"useful", 211, 211, 211},
    {"useless", 153, 153, 153},
}) do
    local r, g, b = ns.PriorityColorForState(case[1])
    equal(r, case[2] / 255, "sanctuary default red")
    equal(g, case[3] / 255, "sanctuary default green")
    equal(b, case[4] / 255, "sanctuary default blue")
    ns.SetPriorityColor(case[1], 0.2, 0.3, 0.4)
    equal(ns.CopyActiveProfile("Sanctuary copy"), true, "copy sanctuary colors")
    equal(ns.PriorityColorForState(case[1]), 0.2, "copied sanctuary customization")
    ns.ResetPriorityColor(case[1])
    equal(ns.PriorityColorForState(case[1]), case[2] / 255, "reset sanctuary color")
    ns.DeleteActiveProfile()
    ns.ResetPriorityColor(case[1])
end
equal(ns.EnsureDB().profiles.Default.priorityColors.sanctuaryUseful, nil, "no separate useful sanctuary setting")
equal(ns.EnsureDB().profiles.Default.priorityColors.sanctuaryUseless, nil, "no separate useless sanctuary setting")
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
equal(ns.GetAppearanceSetting("nameSize"), 21, "create factory values")
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
        stylingEnabled = false, categoryModes = { friendly = "hide", hostile = "bad" },
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
equal(ns.GetCategoryMode("friendly"), "active", "removed category mode discarded")
equal(ns.GetCategoryMode("hostile"), "active", "invalid category reset")
equal(ns.GetTRP3Enabled(), true, "valid TRP3 retained")
equal(ns.GetTRP3Setting("showOOC"), true, "invalid TRP3 reset")
equal(ns.GetAppearanceSetting("nameSize"), 25, "valid appearance retained")
equal(ns.GetAppearanceSetting("nameFont"), "FRIZQT", "invalid font reset")
equal(ns.GetAppearanceSetting("namePlacement"), "INSIDE", "valid placement retained")
equal(ns.GetThreatEnabled(), false, "valid profile toggle retained")
equal(ns.PriorityColorForState("attacking"), 0.4, "valid color retained")
equal(ns.GetActiveProfileName(), "Default", "invalid assignment reset")
equal(db.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName, "original", "ledger retained")
equal(db.global.managedNameCVarOriginals.InventedCVar, nil, "unknown ledger entry dropped")
ns.SetCategoryMode("friendly", "inactive")
ns.SetCategoryMode("friendly", "hide")
equal(ns.GetCategoryMode("friendly"), "inactive", "removed category mode rejected by setter")
-- A schema marker does not discard valid fields; no legacy aliases are converted.
for _, marker in ipairs({ 999, false }) do
    SimpleNameplatesDB = {
        schemaVersion = marker,
        global = {
            stylingEnabled = false,
            hideBlizzardMinionNames = true,
            hideCritterCompanionNames = true,
            categoryModes = { hostile = "inactive", useless = "invalid" },
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
    equal(ns.GetCategoryMode("useless"), "active", "invalid mode discarded")
    equal(db.profiles.Default.appearance.nameSize, 25, "valid appearance retained")
    equal(db.profiles.Default.appearance.nameFont, "FRIZQT", "invalid font discarded")
    equal(ns.GetActiveProfileName(), "Custom", "valid selection retained")
    equal(db.global.hideBlizzardMinionNames, nil, "removed setting discarded")
    equal(db.global.legacyStylingEnabled, nil, "unknown setting discarded")
    equal(db.legacyAppearance, nil, "legacy layout not converted")
    equal(ns.GetHideCritterCompanionNames(), true, "critter toggle retained")
end

-- Removed replacement setting is discarded, while valid originals restore.
ns = fresh()
db = ns.EnsureDB()
db.global.replaceBlizzardOverheadNames = true
db.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName = "original"
db.global.managedNameCVarOriginals.nameplateShowFriendlyPlayers = "original-plates"
cvars.UnitNameFriendlyPlayerName, cvars.nameplateShowFriendlyPlayers = "0", "1"
ns = loadCore()
db = ns.EnsureDB()
equal(db.global.replaceBlizzardOverheadNames, nil, "removed preference discarded")
equal(ns.GetReplaceBlizzardOverheadNames, nil, "replacement getter removed")
equal(ns.SetReplaceBlizzardOverheadNames, nil, "replacement setter removed")
equal(ns.ApplyOverheadNameReplacement, nil, "replacement action removed")
ns.ApplyManagedNameSettings()
equal(cvars.UnitNameFriendlyPlayerName, "original", "world name original restored")
equal(cvars.nameplateShowFriendlyPlayers, "original-plates", "plate original restored")
equal(next(db.global.managedNameCVarOriginals), nil, "successful restore clears ledger")
local before = #writes
ns.ApplyManagedNameSettings()
for _, state in ipairs({"attacking", "hostile", "neutral", "friendly", "useful", "useless"}) do
    ns.SetCategoryMode(state, "inactive")
    ns.SetCategoryMode(state, "active")
end
equal(#writes, before, "replacement never recaptures or rewrites restored values")

-- Every former replacement CVar remains eligible for restoration only.
ns = fresh()
db = ns.EnsureDB()
for _, cvar in ipairs(ns.MANAGED_NAME_CVARS) do
    if cvar ~= "UnitNameNonCombatCreatureName" then
        db.global.managedNameCVarOriginals[cvar] = "original-" .. cvar
        cvars[cvar] = "modified"
    end
end
ns = loadCore()
db = ns.EnsureDB()
ns.ApplyManagedNameSettings()
for _, cvar in ipairs(ns.MANAGED_NAME_CVARS) do
    if cvar ~= "UnitNameNonCombatCreatureName" then
        equal(cvars[cvar], "original-" .. cvar, "restoration allowlist: " .. cvar)
    end
end
equal(next(db.global.managedNameCVarOriginals), nil, "all original entries restored")

-- Failed or silently rejected restoration retains its original for retry.
ns = fresh()
db = ns.EnsureDB()
db.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName = "custom"
cvars.UnitNameFriendlyPlayerName = "0"
rejectedWrites.UnitNameFriendlyPlayerName = true
ns.ApplyManagedNameSettings()
equal(cvars.UnitNameFriendlyPlayerName, "0", "failed restore leaves current value")
equal(db.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName, "custom", "failed restore retains original")
rejectedWrites.UnitNameFriendlyPlayerName = "silent"
ns.ApplyPendingManagedNameSettings()
equal(db.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName, "custom", "silent failure retains original")
rejectedWrites.UnitNameFriendlyPlayerName = nil
ns.ApplyPendingManagedNameSettings()
equal(cvars.UnitNameFriendlyPlayerName, "custom", "restoration retries")
equal(db.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName, nil, "successful retry clears original")

-- Removed-feature restoration works with styling disabled and defers in combat.
ns = fresh()
db = ns.EnsureDB()
db.global.stylingEnabled = false
db.global.managedNameCVarOriginals.nameplateShowOnlyNameForFriendlyPlayerUnits = "bar-original"
cvars.nameplateShowOnlyNameForFriendlyPlayerUnits = "1"
inCombat = true
before = #writes
ns.ApplyManagedNameSettings()
equal(#writes, before, "combat defers restoration")
equal(db.global.managedNameCVarOriginals.nameplateShowOnlyNameForFriendlyPlayerUnits,
    "bar-original", "combat retains original")
inCombat = false
ns.ApplyPendingManagedNameSettings()
equal(cvars.nameplateShowOnlyNameForFriendlyPlayerUnits, "bar-original", "disabled styling restoration retries")
equal(next(db.global.managedNameCVarOriginals), nil, "deferred restore clears ledger")

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

-- Critter hiding remains independent and does not request minion replacements.
ns = fresh()
cvars.UnitNameFriendlyPetName = "pet-original"
cvars.UnitNameNonCombatCreatureName = "critter-original"
equal(ns.GetHideBlizzardMinionNames, nil, "minion getter removed")
equal(ns.SetHideBlizzardMinionNames, nil, "minion setter removed")
ns.SetHideCritterCompanionNames(true)
equal(cvars.UnitNameFriendlyPetName, "pet-original", "critter hide leaves pets alone")
equal(cvars.UnitNameNonCombatCreatureName, "0", "dedicated critter hide retained")
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

-- Current category fields survive; obsolete category keys are discarded without conversion.
SimpleNameplatesDB = {
    schemaVersion = 999,
    global = {categoryModes = {
        attacking = "inactive", hostile = "active", neutral = "inactive", friendly = "active",
        useful = "inactive", useless = "active", friendlyPC = "inactive", unfriendlyPC = "inactive",
        unfriendlyNPC = "inactive", other = "inactive",
    }},
    profiles = {Default = {priorityColors = {
        attacking = {r = 0.1, g = 0.2, b = 0.3}, neutral = {r = 0.4, g = 0.5, b = 0.6},
        sanctuaryUseful = {r = 0.2, g = 0.2, b = 0.2},
        sanctuaryUseless = {r = 0.3, g = 0.3, b = 0.3},
        useful = {r = 0.7, g = 0.8, b = 0.9}, friendlyPC = {r = 1, g = 0, b = 1},
        unfriendlyPC = {r = 1, g = 0, b = 1}, unfriendlyNPC = {r = 1, g = 0, b = 1},
        other = {r = 1, g = 0, b = 1},
    }, appearance = {nameSize = 19, matchSanctuaryFont = false}}},
}
ns = loadCore()
db = ns.EnsureDB()
equal(ns.GetCategoryMode("neutral"), "inactive", "valid new mode retained")
equal(ns.PriorityColorForState("neutral"), 0.4, "valid new color retained")
equal(ns.PriorityColorForState("useful"), 0.7, "useful color retained")
equal(ns.GetAppearanceSetting("nameSize"), 19, "unrelated appearance retained")
equal(ns.GetAppearanceSetting("matchSanctuaryFont"), false, "saved false matching choice retained")
for _, key in ipairs({"friendlyPC", "unfriendlyPC", "unfriendlyNPC", "other", "sanctuaryUseful", "sanctuaryUseless"}) do
    equal(db.global.categoryModes[key], nil, "obsolete mode discarded: " .. key)
    equal(db.profiles.Default.priorityColors[key], nil, "obsolete color discarded: " .. key)
end
equal(ns.PriorityColorForState("friendly"), 51 / 255, "old player color not converted")
equal(ns.PriorityColorForState("sanctuaryFriendly"), 135 / 255, "existing profile receives sanctuary default")
local categoryCount = 0
for _ in pairs(db.global.categoryModes) do categoryCount = categoryCount + 1 end
equal(categoryCount, 6, "exactly six current categories")

-- Friendly class-color control respects possible player combat priorities.
ns = fresh()
local friendlyCVar = ns.FRIENDLY_COLOR_CVARS[1]
cvars[friendlyCVar] = "class-before"
ns.DisableFriendlyClassColors()
ns.SetCategoryMode("hostile", "inactive")
ns.DisableFriendlyClassColors()
equal(cvars[friendlyCVar], "class-before", "friendly class CVar respects possible hostile duel")

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
    "Defaults.lua,Core.lua,WorldContext.lua,ManagedNames.lua,NameplateSetup.lua,Database.lua,TRP3.lua,EntityFacts.lua,NameplateClassification.lua,PresentationCapabilities.lua,PresentationRules.lua,NameplateFrames.lua,NPCTitles.lua,NameplateText.lua,NameplateThreat.lua,CastHighlight.lua,NameplateRestoration.lua,NameplatePresentation.lua,Nameplates.lua,Diagnostics.lua,SettingsControls.lua,SettingsAbout.lua,SettingsBehavior.lua,SettingsProfiles.lua,SettingsAppearance.lua,SettingsColors.lua,SettingsTRP3.lua,Settings.lua",
    "TOC module order")

print("Core behavior smoke: passed")
