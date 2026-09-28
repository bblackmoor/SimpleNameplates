-- Simple Nameplates: metadata, managed-name CVars, and shared diagnostics.
local addon, ns = ...

local getAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

ns.VERSION = getAddOnMetadata and getAddOnMetadata(addon, "Version") or "Unknown"
ns.SOURCE_URL = "https://github.com/bblackmoor/SimpleNameplates"

local issecretvalue = issecretvalue or function() return false end
local canaccessvalue = canaccessvalue or function(v) return not issecretvalue(v) end


local BLIZZARD_MINION_NAME_CVARS = {
    "UnitNameFriendlyMinionName",
    "UnitNameEnemyMinionName",
    "UnitNameFriendlyPetName",
    "UnitNameEnemyPetName",
    "UnitNameFriendlyGuardianName",
    "UnitNameEnemyGuardianName",
    "UnitNameFriendlyTotemName",
    "UnitNameEnemyTotemName",
}
ns.BLIZZARD_MINION_NAME_CVARS = BLIZZARD_MINION_NAME_CVARS

local BLIZZARD_CRITTER_COMPANION_NAME_CVARS = {
    "UnitNameNonCombatCreatureName",
}
ns.BLIZZARD_CRITTER_COMPANION_NAME_CVARS = BLIZZARD_CRITTER_COMPANION_NAME_CVARS

-- Category-aware world-name management. Each CVar is captured once, may be
-- claimed by several options, and is restored only when nothing still needs it.
local CATEGORY_REPLACEMENT_CVAR_VALUES = {
    hostile = {
        UnitNameHostleNPC = "0",
        nameplateShowEnemies = "1",
    },
    unfriendlyPC = {
        UnitNameEnemyPlayerName = "0",
        nameplateShowEnemies = "1",
    },
    friendlyPC = {
        UnitNameFriendlyPlayerName = "0",
        nameplateShowFriendlyPlayers = "1",
        nameplateShowOnlyNameForFriendlyPlayerUnits = "1",
    },
    other = {
        UnitNameFriendlyMinionName = "0",
        UnitNameEnemyMinionName = "0",
        UnitNameFriendlyPetName = "0",
        UnitNameEnemyPetName = "0",
        UnitNameFriendlyGuardianName = "0",
        UnitNameEnemyGuardianName = "0",
        UnitNameFriendlyTotemName = "0",
        UnitNameEnemyTotemName = "0",
        UnitNameFriendlySpecialNPCName = "0",
        UnitNameInteractiveNPC = "0",
        UnitNameNPC = "0",
        nameplateShowFriendlyNpcs = "1",
        nameplateShowFriendlyPlayerMinions = "1",
        nameplateShowFriendlyPlayerPets = "1",
        nameplateShowFriendlyPlayerGuardians = "1",
        nameplateShowFriendlyPlayerTotems = "1",
        nameplateShowFriendlyMinions = "1",
        nameplateShowFriendlyPets = "1",
        nameplateShowFriendlyGuardians = "1",
        nameplateShowFriendlyTotems = "1",
        nameplateShowEnemyMinions = "1",
        nameplateShowEnemyPets = "1",
        nameplateShowEnemyGuardians = "1",
        nameplateShowEnemyTotems = "1",
    },
}
local CATEGORY_HIDE_CVAR_VALUES = {
    hostile = {
        UnitNameHostleNPC = "0",
    },
    unfriendlyPC = {
        UnitNameEnemyPlayerName = "0",
    },
    friendlyPC = {
        UnitNameFriendlyPlayerName = "0",
        nameplateShowFriendlyPlayers = "0",
    },
    other = {
        UnitNameFriendlyMinionName = "0",
        UnitNameEnemyMinionName = "0",
        UnitNameFriendlyPetName = "0",
        UnitNameEnemyPetName = "0",
        UnitNameFriendlyGuardianName = "0",
        UnitNameEnemyGuardianName = "0",
        UnitNameFriendlyTotemName = "0",
        UnitNameEnemyTotemName = "0",
        UnitNameFriendlySpecialNPCName = "0",
        UnitNameInteractiveNPC = "0",
        UnitNameNPC = "0",
        nameplateShowFriendlyNpcs = "0",
        nameplateShowFriendlyPlayerMinions = "0",
        nameplateShowFriendlyPlayerPets = "0",
        nameplateShowFriendlyPlayerGuardians = "0",
        nameplateShowFriendlyPlayerTotems = "0",
        nameplateShowFriendlyMinions = "0",
        nameplateShowFriendlyPets = "0",
        nameplateShowFriendlyGuardians = "0",
        nameplateShowFriendlyTotems = "0",
        nameplateShowEnemyMinions = "0",
        nameplateShowEnemyPets = "0",
        nameplateShowEnemyGuardians = "0",
        nameplateShowEnemyTotems = "0",
    },
}
local SHARED_REPLACEMENT_CVAR_VALUES = {
    nameplateShowAll = "1",
    nameplateForceShowUnitName = "1",
}
local MANAGED_NAME_CVARS, MANAGED_NAME_CVAR_SET = {}, {}
local function RegisterManagedCVars(values)
    for cvar in pairs(values) do
        if not MANAGED_NAME_CVAR_SET[cvar] then
            MANAGED_NAME_CVAR_SET[cvar] = true
            MANAGED_NAME_CVAR_SET[string.lower(cvar)] = true
            MANAGED_NAME_CVARS[#MANAGED_NAME_CVARS + 1] = cvar
        end
    end
end
RegisterManagedCVars(SHARED_REPLACEMENT_CVAR_VALUES)
for _, values in pairs(CATEGORY_REPLACEMENT_CVAR_VALUES) do RegisterManagedCVars(values) end
for _, values in pairs(CATEGORY_HIDE_CVAR_VALUES) do RegisterManagedCVars(values) end
for _, cvar in ipairs(BLIZZARD_MINION_NAME_CVARS) do RegisterManagedCVars({ [cvar] = "0" }) end
for _, cvar in ipairs(BLIZZARD_CRITTER_COMPANION_NAME_CVARS) do RegisterManagedCVars({ [cvar] = "0" }) end
table.sort(MANAGED_NAME_CVARS)
ns.OVERHEAD_REPLACEMENT_CVARS = MANAGED_NAME_CVARS
ns.OVERHEAD_REPLACEMENT_CVAR_SET = MANAGED_NAME_CVAR_SET


local function GetCVarValue(cvar)
    local getter = C_CVar and C_CVar.GetCVar or GetCVar
    return getter and getter(cvar) or nil
end

local function SetCVarValue(cvar, value)
    if value == nil or GetCVarValue(cvar) == tostring(value) then return end
    if C_CVar and C_CVar.SetCVar then
        pcall(C_CVar.SetCVar, cvar, tostring(value))
    elseif SetCVar then
        pcall(SetCVar, cvar, tostring(value))
    end
end

-- Database.lua loads after this module; callbacks resolve its API when invoked.
local function EnsureDB() return ns.EnsureDB() end
local function GetCategoryMode(state) return ns.GetCategoryMode(state) end
local function GetStylingEnabled() return ns.GetStylingEnabled() end

local applyingManagedNameSettings = false
local managedNameSettingsPending = false

local function MergeCVarValues(target, source)
    for cvar, value in pairs(source or {}) do target[cvar] = value end
end

local function AddReplacementCVarSettings(desired, global)
    if not global.replaceBlizzardOverheadNames then return end
    local replacementActive
    for _, state in ipairs({ "hostile", "unfriendlyPC", "friendlyPC", "other" }) do
        if global.categoryModes[state] == "active" then
            MergeCVarValues(desired, CATEGORY_REPLACEMENT_CVAR_VALUES[state])
            replacementActive = true
        end
    end
    if replacementActive then MergeCVarValues(desired, SHARED_REPLACEMENT_CVAR_VALUES) end
end

local function AddHiddenCategoryCVarSettings(desired, global)
    for _, state in ipairs({ "unfriendlyPC", "friendlyPC", "other" }) do
        if global.categoryModes[state] == "hide" then
            MergeCVarValues(desired, CATEGORY_HIDE_CVAR_VALUES[state])
        end
    end
end

local function AddExplicitHiddenNameCVarSettings(desired, global)
    if global.hideBlizzardMinionNames then
        for _, cvar in ipairs(BLIZZARD_MINION_NAME_CVARS) do desired[cvar] = "0" end
    end
    if global.hideCritterCompanionNames then
        for _, cvar in ipairs(BLIZZARD_CRITTER_COMPANION_NAME_CVARS) do desired[cvar] = "0" end
    end
end

local function DesiredManagedNameSettings(db)
    local desired = {}
    local global = db.global
    if not global.stylingEnabled then return desired end
    AddReplacementCVarSettings(desired, global)
    AddHiddenCategoryCVarSettings(desired, global)
    AddExplicitHiddenNameCVarSettings(desired, global)
    return desired
end

local function RestoreUnmanagedCVars(originals, desired)
    for cvar, original in pairs(originals) do
        if desired[cvar] == nil then
            SetCVarValue(cvar, original)
            originals[cvar] = nil
        end
    end
end

local function ApplyDesiredCVars(originals, desired)
    for cvar, value in pairs(desired) do
        local current = GetCVarValue(cvar)
        if current ~= nil then
            if originals[cvar] == nil then originals[cvar] = current end
            SetCVarValue(cvar, value)
        end
    end
end

local function ApplyManagedNameSettings()
    local db = EnsureDB()
    if applyingManagedNameSettings then return end
    if InCombatLockdown and InCombatLockdown() then
        managedNameSettingsPending = true
        return
    end

    applyingManagedNameSettings = true
    managedNameSettingsPending = false
    db.global.managedNameCVarOriginals = type(db.global.managedNameCVarOriginals) == "table"
        and db.global.managedNameCVarOriginals or {}
    local originals = db.global.managedNameCVarOriginals
    local desired = DesiredManagedNameSettings(db)
    RestoreUnmanagedCVars(originals, desired)
    ApplyDesiredCVars(originals, desired)
    applyingManagedNameSettings = false
end

local function RestoreAllManagedNameSettings()
    local db = EnsureDB()
    local originals = db.global.managedNameCVarOriginals
    db.global.managedNameCVarOriginals = {}
    managedNameSettingsPending = false
    if type(originals) ~= "table" then return end
    applyingManagedNameSettings = true
    for cvar, value in pairs(originals) do SetCVarValue(cvar, value) end
    applyingManagedNameSettings = false
end

local function GetHideBlizzardMinionNames()
    return EnsureDB().global.hideBlizzardMinionNames
end

local function SetHideBlizzardMinionNames(enabled)
    EnsureDB().global.hideBlizzardMinionNames = enabled == true
    ApplyManagedNameSettings()
end

local function ApplyBlizzardMinionNameVisibility()
    ApplyManagedNameSettings()
end

local function GetHideCritterCompanionNames()
    return EnsureDB().global.hideCritterCompanionNames
end

local function SetHideCritterCompanionNames(enabled)
    EnsureDB().global.hideCritterCompanionNames = enabled == true
    ApplyManagedNameSettings()
end

local function ApplyCritterCompanionNameVisibility()
    ApplyManagedNameSettings()
end

local function GetReplaceBlizzardOverheadNames()
    return EnsureDB().global.replaceBlizzardOverheadNames
end

local function SetReplaceBlizzardOverheadNames(enabled)
    EnsureDB().global.replaceBlizzardOverheadNames = enabled == true
    ApplyManagedNameSettings()
end

local function ApplyOverheadNameReplacement()
    ApplyManagedNameSettings()
end

local function RestoreOverheadNameSettings()
    RestoreAllManagedNameSettings()
end

local function ApplyPendingManagedNameSettings()
    if managedNameSettingsPending then ApplyManagedNameSettings() end
end

local FRIENDLY_COLOR_CVARS = {
    "nameplateUseClassColorForFriendlyPlayerUnitNames",
    "nameplateShowFriendlyClassColor",
    "ShowClassColorInFriendlyNameplate",
}
ns.FRIENDLY_COLOR_CVARS = FRIENDLY_COLOR_CVARS
local friendlyColorCVarOriginals = {}
local friendlyColorCVarsCaptured = false

local RestoreFriendlyClassColors

local function DisableFriendlyClassColors()
    if GetCategoryMode("friendlyPC") ~= "active" then
        RestoreFriendlyClassColors()
        return
    end
    -- Midnight has separate CVars for friendly player name text and health-bar
    -- class coloring. Disable all known variants: Blizzard or another addon can update
    -- these independently, and leaving the name-text CVar enabled produces the
    -- familiar rainbow of class-colored friendly names.
    for _, cvar in ipairs(FRIENDLY_COLOR_CVARS) do
        if not friendlyColorCVarsCaptured then
            local getCVar = C_CVar and C_CVar.GetCVar or GetCVar
            if getCVar then friendlyColorCVarOriginals[cvar] = getCVar(cvar) end
        end
        if C_CVar and C_CVar.SetCVar then
            pcall(C_CVar.SetCVar, cvar, "0")
        elseif SetCVar then
            pcall(SetCVar, cvar, "0")
        end
    end
    friendlyColorCVarsCaptured = true
end

RestoreFriendlyClassColors = function()
    if not friendlyColorCVarsCaptured then return end
    for _, cvar in ipairs(FRIENDLY_COLOR_CVARS) do
        local value = friendlyColorCVarOriginals[cvar]
        if value ~= nil then
            if C_CVar and C_CVar.SetCVar then
                pcall(C_CVar.SetCVar, cvar, value)
            elseif SetCVar then
                pcall(SetCVar, cvar, value)
            end
        end
    end
    wipe(friendlyColorCVarOriginals)
    friendlyColorCVarsCaptured = false
end

local function AddOnEnabled(name)
    local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    if isLoaded and isLoaded(name) then return true end

    local getEnableState = C_AddOns and C_AddOns.GetAddOnEnableState or GetAddOnEnableState
    if getEnableState then
        local state = getEnableState(UnitName("player"), name)
        return type(state) == "number" and state > 0
    end
    return false
end

local function PlainTitle(title)
    return (title or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function FindOtherPlateAddOns()
    local getNumAddOns = C_AddOns and C_AddOns.GetNumAddOns or GetNumAddOns
    local getAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
    if not getNumAddOns or not getAddOnInfo then return {} end

    local found = {}
    for index = 1, getNumAddOns() do
        local name, title = getAddOnInfo(index)
        if name and name ~= addon and not name:match("^Blizzard_") then
            local searchText = string.lower(name .. " " .. (title or "")):gsub("template", "")
            if searchText:find("plate", 1, true) and AddOnEnabled(name) then
                local displayName = type(title) == "string" and title ~= "" and title or name
                found[#found + 1] = PlainTitle(displayName)
            end
        end
    end
    table.sort(found)
    return found
end

local function ShowNameplateConflictWarning()
    local conflicts = FindOtherPlateAddOns()
    if #conflicts == 0 then return end

    StaticPopupDialogs["SNP_NAMEPLATE_CONFLICT"] = {
        text = "|cff0cd29fSimple Nameplates|r\n\nOther enabled addons whose names contain ‘plate’ were found:\n\n%s\n\nRunning more than one nameplate addon can cause conflicting colors or duplicate nameplates. Disable the others and reload the UI if you see problems.",
        button1 = OKAY or "Okay",
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopup_Show("SNP_NAMEPLATE_CONFLICT", table.concat(conflicts, "\n"))
end

local function AccessibleNumber(v)
    if v == nil or issecretvalue(v) or not canaccessvalue(v) or type(v) ~= "number" then return nil end
    return v
end

local function AccessibleBoolean(v)
    if v == nil or issecretvalue(v) or not canaccessvalue(v) or type(v) ~= "boolean" then return nil end
    return v
end

local function AccessibleValue(v)
    if v == nil or issecretvalue(v) or not canaccessvalue(v) then return nil end
    return v
end


ns.GetHideBlizzardMinionNames = GetHideBlizzardMinionNames
ns.SetHideBlizzardMinionNames = SetHideBlizzardMinionNames
ns.ApplyBlizzardMinionNameVisibility = ApplyBlizzardMinionNameVisibility
ns.GetHideCritterCompanionNames = GetHideCritterCompanionNames
ns.SetHideCritterCompanionNames = SetHideCritterCompanionNames
ns.ApplyCritterCompanionNameVisibility = ApplyCritterCompanionNameVisibility
ns.GetReplaceBlizzardOverheadNames = GetReplaceBlizzardOverheadNames
ns.SetReplaceBlizzardOverheadNames = SetReplaceBlizzardOverheadNames
ns.ApplyOverheadNameReplacement = ApplyOverheadNameReplacement
ns.ApplyManagedNameSettings = ApplyManagedNameSettings
ns.ApplyPendingManagedNameSettings = ApplyPendingManagedNameSettings
ns.RestoreOverheadNameSettings = RestoreOverheadNameSettings
ns.DisableFriendlyClassColors = DisableFriendlyClassColors
ns.RestoreFriendlyClassColors = RestoreFriendlyClassColors
ns.ShowNameplateConflictWarning = ShowNameplateConflictWarning
ns.AccessibleNumber = AccessibleNumber
ns.AccessibleBoolean = AccessibleBoolean
ns.AccessibleValue = AccessibleValue
