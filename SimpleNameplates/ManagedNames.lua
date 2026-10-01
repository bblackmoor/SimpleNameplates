-- Simple Nameplates: Blizzard name CVars, ownership, and restoration.
local _, ns = ...

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
    if value == nil then return false end
    value = tostring(value)
    if GetCVarValue(cvar) == value then return true end
    local setter = C_CVar and C_CVar.SetCVar or SetCVar
    if not setter then return false end
    local ok = pcall(setter, cvar, value)
    return ok and GetCVarValue(cvar) == value
end

-- Database.lua loads after this module; callbacks resolve its API when invoked.
local function EnsureDB() return ns.EnsureDB() end
local function GetCategoryMode(state) return ns.GetCategoryMode(state) end
local function GetStylingEnabled() return ns.GetStylingEnabled() end

local applyingManagedNameSettings = false
local pendingManagedAction -- "apply" or "restore"; last requested action wins
local pendingFriendlyAction
local DisableFriendlyClassColors, RestoreFriendlyClassColors

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
    AddExplicitHiddenNameCVarSettings(desired, global)
    return desired
end

local function RestoreUnmanagedCVars(originals, desired)
    local failed = false
    for cvar, original in pairs(originals) do
        if desired[cvar] == nil then
            if SetCVarValue(cvar, original) then
                originals[cvar] = nil
            else
                failed = true
            end
        end
    end
    return failed
end

local function ApplyDesiredCVars(originals, desired)
    local failed = false
    for cvar, value in pairs(desired) do
        local current = GetCVarValue(cvar)
        if current ~= nil then
            if originals[cvar] == nil then originals[cvar] = current end
            if not SetCVarValue(cvar, value) then failed = true end
        end
    end
    return failed
end

local function ApplyManagedNameSettings()
    local db = EnsureDB()
    if applyingManagedNameSettings then return end
    if InCombatLockdown and InCombatLockdown() then
        pendingManagedAction = "apply"
        return
    end

    applyingManagedNameSettings = true
    pendingManagedAction = nil
    db.global.managedNameCVarOriginals = type(db.global.managedNameCVarOriginals) == "table"
        and db.global.managedNameCVarOriginals or {}
    local originals = db.global.managedNameCVarOriginals
    local desired = DesiredManagedNameSettings(db)
    local restoreFailed = RestoreUnmanagedCVars(originals, desired)
    local applyFailed = ApplyDesiredCVars(originals, desired)
    if restoreFailed or applyFailed then pendingManagedAction = "apply" end
    applyingManagedNameSettings = false
end

local function RestoreAllManagedNameSettings()
    if InCombatLockdown and InCombatLockdown() then
        pendingManagedAction = "restore"
        return
    end
    local db = EnsureDB()
    local originals = db.global.managedNameCVarOriginals
    pendingManagedAction = nil
    if type(originals) ~= "table" then return end
    applyingManagedNameSettings = true
    for cvar, value in pairs(originals) do
        if SetCVarValue(cvar, value) then
            originals[cvar] = nil
        else
            pendingManagedAction = "restore"
        end
    end
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
    if pendingManagedAction == "restore" then
        RestoreAllManagedNameSettings()
    elseif pendingManagedAction == "apply" then
        ApplyManagedNameSettings()
    end
    if pendingFriendlyAction == "restore" then
        RestoreFriendlyClassColors()
    elseif pendingFriendlyAction == "disable" then
        DisableFriendlyClassColors()
    end
end

local FRIENDLY_COLOR_CVARS = {
    "nameplateUseClassColorForFriendlyPlayerUnitNames",
    "nameplateShowFriendlyClassColor",
    "ShowClassColorInFriendlyNameplate",
}
ns.FRIENDLY_COLOR_CVARS = FRIENDLY_COLOR_CVARS
local friendlyColorCVarOriginals = {}
local friendlyColorCVarsCaptured = false

DisableFriendlyClassColors = function()
    if GetCategoryMode("friendlyPC") ~= "active" then
        RestoreFriendlyClassColors()
        return
    end
    -- Midnight has separate CVars for friendly player name text and health-bar
    -- class coloring. Disable all known variants: Blizzard or another addon can update
    -- these independently, and leaving the name-text CVar enabled produces the
    -- familiar rainbow of class-colored friendly names.
    if InCombatLockdown and InCombatLockdown() then
        pendingFriendlyAction = "disable"
        return
    end
    pendingFriendlyAction = nil
    for _, cvar in ipairs(FRIENDLY_COLOR_CVARS) do
        local current = GetCVarValue(cvar)
        if current ~= nil then
            if friendlyColorCVarOriginals[cvar] == nil then
                friendlyColorCVarOriginals[cvar] = current
            end
            if not SetCVarValue(cvar, "0") then pendingFriendlyAction = "disable" end
        end
    end
    friendlyColorCVarsCaptured = next(friendlyColorCVarOriginals) ~= nil
end

RestoreFriendlyClassColors = function()
    if not friendlyColorCVarsCaptured then
        pendingFriendlyAction = nil
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        pendingFriendlyAction = "restore"
        return
    end
    pendingFriendlyAction = nil
    for cvar, value in pairs(friendlyColorCVarOriginals) do
        if SetCVarValue(cvar, value) then
            friendlyColorCVarOriginals[cvar] = nil
        else
            pendingFriendlyAction = "restore"
        end
    end
    friendlyColorCVarsCaptured = next(friendlyColorCVarOriginals) ~= nil
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
