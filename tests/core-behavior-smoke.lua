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

function UnitGUID() return character end
function UnitFullName() return "Fallback", "Realm" end
function strtrim(value) return value:match("^%s*(.-)%s*$") end
function InCombatLockdown() return inCombat end
function wipe(t) for key in pairs(t) do t[key] = nil end end
C_CVar = {
    GetCVar = function(name) return cvars[name] or "1" end,
    SetCVar = function(name, value)
        cvars[name] = value
        writes[#writes + 1] = { name, value }
    end,
}
local function loadCore()
    local namespace = {}
    for _, file in ipairs({ "Defaults.lua", "Core.lua", "Database.lua" }) do
        assert(loadfile("SimpleNameplates/" .. file))("SimpleNameplates", namespace)
    end
    return namespace
end
local function fresh()
    SimpleNameplatesDB = nil
    cvars, writes = {}, {}
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
equal(ns.GetCategoryMode("friendlyPC"), "hide", "valid category retained")
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
SimpleNameplatesDB = { schemaVersion = 999, global = { stylingEnabled = false } }
ns = loadCore()
equal(ns.EnsureDB().schemaVersion, 2, "incompatible schema discarded")
equal(ns.GetStylingEnabled(), true, "incompatible values ignored")

-- CVar capture, shared claims, restoration, reload, and combat deferral.
ns = fresh()
cvars.UnitNameFriendlyPlayerName = "original"
cvars.nameplateShowFriendlyPlayers = "original-plates"
ns.SetCategoryMode("friendlyPC", "hide")
equal(cvars.UnitNameFriendlyPlayerName, "0", "hide applies name CVar")
equal(cvars.nameplateShowFriendlyPlayers, "0", "hide applies plate CVar")
equal(SimpleNameplatesDB.global.managedNameCVarOriginals.UnitNameFriendlyPlayerName,
    "original", "capture original once")
ns.SetCategoryMode("friendlyPC", "active")
ns.SetReplaceBlizzardOverheadNames(true)
equal(cvars.UnitNameFriendlyPlayerName, "0", "replacement claims name CVar")
equal(cvars.nameplateShowFriendlyPlayers, "1", "replacement claims plate CVar")
ns.SetCategoryMode("friendlyPC", "inactive")
equal(cvars.UnitNameFriendlyPlayerName, "original", "last name claim restored")
equal(cvars.nameplateShowFriendlyPlayers, "original-plates", "last plate claim restored")
ns.SetCategoryMode("friendlyPC", "hide")
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
    "Defaults.lua,Core.lua,Database.lua,TRP3.lua,Nameplates.lua,Settings.lua",
    "TOC module order")

print("Core behavior smoke: passed")
