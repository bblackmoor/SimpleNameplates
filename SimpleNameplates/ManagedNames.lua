-- Simple Nameplates: Blizzard name CVars, ownership, and restoration.
local _, ns = ...

local BLIZZARD_CRITTER_COMPANION_NAME_CVARS = {
    "UnitNameNonCombatCreatureName",
}
ns.BLIZZARD_CRITTER_COMPANION_NAME_CVARS = BLIZZARD_CRITTER_COMPANION_NAME_CVARS

-- Allowlist for current critter control and persisted original values.
-- Player/NPC/minion and plate entries are restoration-only: never claim or
-- capture them again. Keep originals readable until restoration succeeds.
local MANAGED_NAME_CVARS = {
    "UnitNameEnemyGuardianName",
    "UnitNameEnemyMinionName",
    "UnitNameEnemyPetName",
    "UnitNameEnemyPlayerName",
    "UnitNameEnemyTotemName",
    "UnitNameFriendlyGuardianName",
    "UnitNameFriendlyMinionName",
    "UnitNameFriendlyPetName",
    "UnitNameFriendlyPlayerName",
    "UnitNameFriendlySpecialNPCName",
    "UnitNameFriendlyTotemName",
    "UnitNameHostleNPC",
    "UnitNameInteractiveNPC",
    "UnitNameNPC",
    "UnitNameNonCombatCreatureName",
    "nameplateForceShowUnitName",
    "nameplateShowAll",
    "nameplateShowEnemies",
    "nameplateShowEnemyGuardians",
    "nameplateShowEnemyMinions",
    "nameplateShowEnemyPets",
    "nameplateShowEnemyTotems",
    "nameplateShowFriendlyGuardians",
    "nameplateShowFriendlyMinions",
    "nameplateShowFriendlyNpcs",
    "nameplateShowFriendlyPets",
    "nameplateShowFriendlyPlayerGuardians",
    "nameplateShowFriendlyPlayerMinions",
    "nameplateShowFriendlyPlayerPets",
    "nameplateShowFriendlyPlayerTotems",
    "nameplateShowFriendlyPlayers",
    "nameplateShowFriendlyTotems",
    "nameplateShowOnlyNameForFriendlyPlayerUnits",
}
local MANAGED_NAME_CVAR_SET = {}
for _, cvar in ipairs(MANAGED_NAME_CVARS) do
    MANAGED_NAME_CVAR_SET[cvar] = true
    MANAGED_NAME_CVAR_SET[string.lower(cvar)] = true
end
ns.MANAGED_NAME_CVARS = MANAGED_NAME_CVARS
ns.MANAGED_NAME_CVAR_SET = MANAGED_NAME_CVAR_SET


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

local function AddExplicitHiddenNameCVarSettings(desired, global)
    if global.hideCritterCompanionNames then
        for _, cvar in ipairs(BLIZZARD_CRITTER_COMPANION_NAME_CVARS) do desired[cvar] = "0" end
    end
end

local function DesiredManagedNameSettings(db)
    local desired = {}
    local global = db.global
    if not GetStylingEnabled() then return desired end
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

local function RestoreManagedNameSettings()
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
    if not GetStylingEnabled() or GetCategoryMode("friendly") ~= "active" or GetCategoryMode("hostile") ~= "active"
        or GetCategoryMode("attacking") ~= "active" then
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


ns.GetHideCritterCompanionNames = GetHideCritterCompanionNames
ns.SetHideCritterCompanionNames = SetHideCritterCompanionNames
ns.ApplyCritterCompanionNameVisibility = ApplyCritterCompanionNameVisibility
ns.ApplyManagedNameSettings = ApplyManagedNameSettings
ns.ApplyPendingManagedNameSettings = ApplyPendingManagedNameSettings
ns.RestoreManagedNameSettings = RestoreManagedNameSettings
ns.DisableFriendlyClassColors = DisableFriendlyClassColors
ns.RestoreFriendlyClassColors = RestoreFriendlyClassColors
