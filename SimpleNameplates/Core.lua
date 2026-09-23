-- Simple Nameplates: shared metadata, saved variables, and startup helpers.

local addon, ns = ...

local getAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

ns.VERSION = getAddOnMetadata and getAddOnMetadata(addon, "Version") or "Unknown"
ns.SOURCE_URL = "https://github.com/bblackmoor/SimpleNameplates"

local issecretvalue = issecretvalue or function() return false end
local canaccessvalue = canaccessvalue or function(v) return not issecretvalue(v) end

local function RGB8(r, g, b)
    return { r = r / 255, g = g / 255, b = b / 255 }
end

local DEFAULT_PRIORITY_COLORS = {
    attacking = RGB8(255, 0, 0),
    hostile = RGB8(255, 102, 0),
    unfriendlyNPC = RGB8(255, 204, 0),
    unfriendlyPC = RGB8(102, 102, 255),
    friendlyPC = RGB8(51, 204, 51),
    other = RGB8(51, 204, 255),
}
local DEFAULT_CATEGORY_MODES = {
    attacking = "active",
    hostile = "active",
    unfriendlyNPC = "active",
    unfriendlyPC = "active",
    friendlyPC = "active",
    other = "active",
}
local DEFAULT_EFFECT_COLORS = {
    interruptible = RGB8(0, 255, 255),
}
local COLOR_PRESETS = {
    highContrast = {
        priorityColors = {
            attacking = RGB8(255, 0, 255),
            hostile = RGB8(255, 102, 0),
            unfriendlyNPC = RGB8(255, 255, 0),
            unfriendlyPC = RGB8(0, 102, 255),
            friendlyPC = RGB8(0, 255, 255),
            other = RGB8(255, 255, 255),
        },
        effectColors = {
            interruptible = RGB8(0, 255, 0),
        },
    },
}
ns.DEFAULT_PRIORITY_COLORS = DEFAULT_PRIORITY_COLORS
ns.DEFAULT_EFFECT_COLORS = DEFAULT_EFFECT_COLORS

local FONT_OPTIONS = {
    { value = "ARIALN", label = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    { value = "FRIZQT", label = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
    { value = "MORPHEUS", label = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    { value = "SKURRI", label = "Skurri", path = "Fonts\\skurri.ttf" },
    { value = "2002", label = "2002", path = "Fonts\\2002.TTF" },
    { value = "2002B", label = "2002 Bold", path = "Fonts\\2002B.TTF" },
}
local FONT_BY_VALUE = {}
for _, option in ipairs(FONT_OPTIONS) do FONT_BY_VALUE[option.value] = option end

local DEFAULT_APPEARANCE = {
    nameFont = "ARIALN",
    nameSize = 12,
    threatFont = "ARIALN",
    namePlacement = "ABOVE",
}
local MIN_NAME_SIZE = 8
local MAX_NAME_SIZE = 36

local DEFAULT_TRP3 = {
    enabled = false,
    useRoleplayingName = true,
    showShortTitle = true,
    showFullTitle = true,
    showOOC = true,
}

local DEFAULT_STYLING_ENABLED = true
local DEFAULT_SHOW_THREAT = true
local DEFAULT_HIDE_BLIZZARD_MINION_NAMES = false
local DEFAULT_HIDE_CRITTER_COMPANION_NAMES = false
local DEFAULT_REPLACE_BLIZZARD_OVERHEAD_NAMES = false

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

ns.FONT_OPTIONS = FONT_OPTIONS
ns.DEFAULT_APPEARANCE = DEFAULT_APPEARANCE
ns.MIN_NAME_SIZE = MIN_NAME_SIZE
ns.MAX_NAME_SIZE = MAX_NAME_SIZE

local dbReady = false

local function IsFiniteNumber(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function IsValidColor(color)
    return type(color) == "table"
        and IsFiniteNumber(color.r) and color.r >= 0 and color.r <= 1
        and IsFiniteNumber(color.g) and color.g >= 0 and color.g <= 1
        and IsFiniteNumber(color.b) and color.b >= 0 and color.b <= 1
end

local function CopyColor(color)
    return { r = color.r, g = color.g, b = color.b }
end

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

local function SavedBoolean(value, default)
    if type(value) == "boolean" then return value end
    return default
end

local function CopySavedCVarOriginals(source, allowedCVars)
    if type(source) ~= "table" then return nil end

    local copy
    for _, cvar in ipairs(allowedCVars) do
        local value = source[cvar]
        local valueType = type(value)
        if valueType == "string" or valueType == "number" or valueType == "boolean" then
            copy = copy or {}
            copy[cvar] = value
        end
    end
    return copy
end

local function ValidatedDB(saved)
    if type(saved) ~= "table" then saved = {} end

    local db = {
        priorityColors = {},
        categoryModes = {},
        effectColors = {},
        appearance = {},
        trp3 = {},
    }

    local savedPriorityColors = type(saved.priorityColors) == "table"
        and saved.priorityColors or {}
    for key, default in pairs(DEFAULT_PRIORITY_COLORS) do
        local color = savedPriorityColors[key]
        db.priorityColors[key] = CopyColor(IsValidColor(color) and color or default)
    end
    local savedCategoryModes = type(saved.categoryModes) == "table" and saved.categoryModes or {}
    for key, default in pairs(DEFAULT_CATEGORY_MODES) do
        local mode = savedCategoryModes[key]
        db.categoryModes[key] = (mode == "active" or mode == "inactive" or mode == "hide")
            and mode or default
    end

    local savedEffectColors = type(saved.effectColors) == "table" and saved.effectColors or {}
    for key, default in pairs(DEFAULT_EFFECT_COLORS) do
        local color = savedEffectColors[key]
        db.effectColors[key] = CopyColor(IsValidColor(color) and color or default)
    end

    local savedAppearance = type(saved.appearance) == "table" and saved.appearance or {}
    db.appearance.nameFont = FONT_BY_VALUE[savedAppearance.nameFont]
        and savedAppearance.nameFont or DEFAULT_APPEARANCE.nameFont
    if IsFiniteNumber(savedAppearance.nameSize)
        and savedAppearance.nameSize >= MIN_NAME_SIZE
        and savedAppearance.nameSize <= MAX_NAME_SIZE then
        db.appearance.nameSize = math.floor(savedAppearance.nameSize + 0.5)
    else
        db.appearance.nameSize = DEFAULT_APPEARANCE.nameSize
    end
    db.appearance.threatFont = FONT_BY_VALUE[savedAppearance.threatFont]
        and savedAppearance.threatFont or DEFAULT_APPEARANCE.threatFont
    if savedAppearance.namePlacement == "ABOVE" or savedAppearance.namePlacement == "INSIDE" then
        db.appearance.namePlacement = savedAppearance.namePlacement
    else
        db.appearance.namePlacement = DEFAULT_APPEARANCE.namePlacement
    end

    db.stylingEnabled = SavedBoolean(saved.stylingEnabled, DEFAULT_STYLING_ENABLED)
    db.showThreat = SavedBoolean(saved.showThreat, DEFAULT_SHOW_THREAT)
    db.hideBlizzardMinionNames = SavedBoolean(saved.hideBlizzardMinionNames,
        DEFAULT_HIDE_BLIZZARD_MINION_NAMES)
    db.hideCritterCompanionNames = SavedBoolean(saved.hideCritterCompanionNames,
        DEFAULT_HIDE_CRITTER_COMPANION_NAMES)
    db.replaceBlizzardOverheadNames = SavedBoolean(saved.replaceBlizzardOverheadNames,
        DEFAULT_REPLACE_BLIZZARD_OVERHEAD_NAMES)
    db.attackingGlow = SavedBoolean(saved.attackingGlow, false)
    db.interruptibleHighlight = SavedBoolean(saved.interruptibleHighlight, false)

    local savedTRP3 = type(saved.trp3) == "table" and saved.trp3 or {}
    for key, default in pairs(DEFAULT_TRP3) do
        db.trp3[key] = SavedBoolean(savedTRP3[key], default)
    end

    db.managedNameCVarOriginals = CopySavedCVarOriginals(
        saved.managedNameCVarOriginals, MANAGED_NAME_CVARS) or {}

    return db
end

local function EnsureDB()
    if dbReady then return SimpleNameplatesDB end
    SimpleNameplatesDB = ValidatedDB(SimpleNameplatesDB)
    dbReady = true
    return SimpleNameplatesDB
end

local function GetTRP3Enabled()
    return EnsureDB().trp3.enabled
end

local function SetTRP3Enabled(enabled)
    EnsureDB().trp3.enabled = enabled == true
end

local function GetTRP3Setting(key)
    return EnsureDB().trp3[key]
end

local function SetTRP3Setting(key, enabled)
    if DEFAULT_TRP3[key] ~= nil then
        EnsureDB().trp3[key] = enabled == true
    end
end

local function GetAppearanceSetting(key)
    return EnsureDB().appearance[key]
end

local function SetAppearanceSetting(key, value)
    local appearance = EnsureDB().appearance
    if (key == "nameFont" or key == "threatFont") and FONT_BY_VALUE[value] then
        appearance[key] = value
    elseif key == "nameSize" and type(value) == "number" then
        appearance[key] = math.max(MIN_NAME_SIZE,
            math.min(MAX_NAME_SIZE, math.floor(value + 0.5)))
    elseif key == "namePlacement" and (value == "ABOVE" or value == "INSIDE") then
        appearance[key] = value
    end
end

local function FontPath(value)
    local option = FONT_BY_VALUE[value] or FONT_BY_VALUE.ARIALN
    return option.path
end

local function ResetAppearance()
    local appearance = EnsureDB().appearance
    for key, value in pairs(DEFAULT_APPEARANCE) do appearance[key] = value end
end

local ApplyManagedNameSettings

local function PriorityColorForState(state)
    local color = EnsureDB().priorityColors[state]
        or DEFAULT_PRIORITY_COLORS[state]
        or DEFAULT_PRIORITY_COLORS.other
    return color.r, color.g, color.b
end

local function GetCategoryMode(state)
    return EnsureDB().categoryModes[state] or "active"
end

local function SetCategoryMode(state, mode)
    if not DEFAULT_CATEGORY_MODES[state]
        or (mode ~= "active" and mode ~= "inactive" and mode ~= "hide") then return end
    EnsureDB().categoryModes[state] = mode
    if ApplyManagedNameSettings then ApplyManagedNameSettings() end
end

local function SetPriorityColor(state, r, g, b)
    if DEFAULT_PRIORITY_COLORS[state] then
        EnsureDB().priorityColors[state] = { r = r, g = g, b = b }
    end
end

local function ResetPriorityColor(state)
    local default = DEFAULT_PRIORITY_COLORS[state]
    if not default then return end
    EnsureDB().priorityColors[state] = CopyColor(default)
end

local function EffectColor(effect)
    local color = EnsureDB().effectColors[effect]
        or DEFAULT_EFFECT_COLORS[effect]
        or DEFAULT_EFFECT_COLORS.interruptible
    return color.r, color.g, color.b
end

local function SetEffectColor(effect, r, g, b)
    if DEFAULT_EFFECT_COLORS[effect] then
        EnsureDB().effectColors[effect] = { r = r, g = g, b = b }
    end
end

local function ResetEffectColor(effect)
    local default = DEFAULT_EFFECT_COLORS[effect]
    if not default then return end
    EnsureDB().effectColors[effect] = CopyColor(default)
end

local function ResetAllColors()
    local db = EnsureDB()
    for key, default in pairs(DEFAULT_PRIORITY_COLORS) do
        db.priorityColors[key] = CopyColor(default)
    end
    for key, default in pairs(DEFAULT_EFFECT_COLORS) do
        db.effectColors[key] = CopyColor(default)
    end
end

local function ApplyColorPreset(presetName)
    local preset = COLOR_PRESETS[presetName]
    if not preset then return false end

    local db = EnsureDB()
    for key, color in pairs(preset.priorityColors or {}) do
        if DEFAULT_PRIORITY_COLORS[key] and IsValidColor(color) then
            db.priorityColors[key] = CopyColor(color)
        end
    end
    for key, color in pairs(preset.effectColors or {}) do
        if DEFAULT_EFFECT_COLORS[key] and IsValidColor(color) then
            db.effectColors[key] = CopyColor(color)
        end
    end
    return true
end

local function GetAttackingGlowEnabled()
    return EnsureDB().attackingGlow
end

local function SetAttackingGlowEnabled(enabled)
    EnsureDB().attackingGlow = enabled == true
end

local function GetInterruptibleHighlightEnabled()
    return EnsureDB().interruptibleHighlight
end

local function SetInterruptibleHighlightEnabled(enabled)
    EnsureDB().interruptibleHighlight = enabled == true
end

local function GetStylingEnabled()
    return EnsureDB().stylingEnabled
end

local function SetStylingEnabled(enabled)
    EnsureDB().stylingEnabled = enabled == true
end

local function GetThreatEnabled()
    return EnsureDB().showThreat
end

local function SetThreatEnabled(enabled)
    EnsureDB().showThreat = enabled == true
end

local applyingManagedNameSettings = false
local managedNameSettingsPending = false

local function MergeCVarValues(target, source)
    for cvar, value in pairs(source or {}) do target[cvar] = value end
end

local function DesiredManagedNameSettings(db)
    local desired = {}
    if not db.stylingEnabled then return desired end

    if db.replaceBlizzardOverheadNames then
        local replacementActive
        for _, state in ipairs({ "hostile", "unfriendlyPC", "friendlyPC", "other" }) do
            if db.categoryModes[state] == "active" then
                MergeCVarValues(desired, CATEGORY_REPLACEMENT_CVAR_VALUES[state])
                replacementActive = true
            end
        end
        if replacementActive then MergeCVarValues(desired, SHARED_REPLACEMENT_CVAR_VALUES) end
    end

    for _, state in ipairs({ "unfriendlyPC", "friendlyPC", "other" }) do
        if db.categoryModes[state] == "hide" then
            MergeCVarValues(desired, CATEGORY_HIDE_CVAR_VALUES[state])
        end
    end
    if db.hideBlizzardMinionNames then
        for _, cvar in ipairs(BLIZZARD_MINION_NAME_CVARS) do desired[cvar] = "0" end
    end
    if db.hideCritterCompanionNames then
        for _, cvar in ipairs(BLIZZARD_CRITTER_COMPANION_NAME_CVARS) do desired[cvar] = "0" end
    end
    return desired
end

ApplyManagedNameSettings = function()
    local db = EnsureDB()
    if applyingManagedNameSettings then return end
    if InCombatLockdown and InCombatLockdown() then
        managedNameSettingsPending = true
        return
    end

    applyingManagedNameSettings = true
    managedNameSettingsPending = false
    db.managedNameCVarOriginals = type(db.managedNameCVarOriginals) == "table"
        and db.managedNameCVarOriginals or {}
    local originals = db.managedNameCVarOriginals
    local desired = DesiredManagedNameSettings(db)

    for cvar, original in pairs(originals) do
        if desired[cvar] == nil then
            SetCVarValue(cvar, original)
            originals[cvar] = nil
        end
    end
    for cvar, value in pairs(desired) do
        local current = GetCVarValue(cvar)
        if current ~= nil then
            if originals[cvar] == nil then originals[cvar] = current end
            SetCVarValue(cvar, value)
        end
    end
    applyingManagedNameSettings = false
end

local function RestoreAllManagedNameSettings()
    local db = EnsureDB()
    local originals = db.managedNameCVarOriginals
    db.managedNameCVarOriginals = {}
    managedNameSettingsPending = false
    if type(originals) ~= "table" then return end
    applyingManagedNameSettings = true
    for cvar, value in pairs(originals) do SetCVarValue(cvar, value) end
    applyingManagedNameSettings = false
end

local function GetHideBlizzardMinionNames()
    return EnsureDB().hideBlizzardMinionNames
end

local function SetHideBlizzardMinionNames(enabled)
    EnsureDB().hideBlizzardMinionNames = enabled == true
    ApplyManagedNameSettings()
end

local function ApplyBlizzardMinionNameVisibility()
    ApplyManagedNameSettings()
end

local function GetHideCritterCompanionNames()
    return EnsureDB().hideCritterCompanionNames
end

local function SetHideCritterCompanionNames(enabled)
    EnsureDB().hideCritterCompanionNames = enabled == true
    ApplyManagedNameSettings()
end

local function ApplyCritterCompanionNameVisibility()
    ApplyManagedNameSettings()
end

local function GetReplaceBlizzardOverheadNames()
    return EnsureDB().replaceBlizzardOverheadNames
end

local function SetReplaceBlizzardOverheadNames(enabled)
    EnsureDB().replaceBlizzardOverheadNames = enabled == true
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

ns.EnsureDB = EnsureDB
ns.PriorityColorForState = PriorityColorForState
ns.GetCategoryMode = GetCategoryMode
ns.SetCategoryMode = SetCategoryMode
ns.SetPriorityColor = SetPriorityColor
ns.ResetPriorityColor = ResetPriorityColor
ns.EffectColor = EffectColor
ns.SetEffectColor = SetEffectColor
ns.ResetEffectColor = ResetEffectColor
ns.ResetAllColors = ResetAllColors
ns.ApplyColorPreset = ApplyColorPreset
ns.GetAttackingGlowEnabled = GetAttackingGlowEnabled
ns.SetAttackingGlowEnabled = SetAttackingGlowEnabled
ns.GetInterruptibleHighlightEnabled = GetInterruptibleHighlightEnabled
ns.SetInterruptibleHighlightEnabled = SetInterruptibleHighlightEnabled
ns.GetStylingEnabled = GetStylingEnabled
ns.SetStylingEnabled = SetStylingEnabled
ns.GetThreatEnabled = GetThreatEnabled
ns.SetThreatEnabled = SetThreatEnabled
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
ns.GetAppearanceSetting = GetAppearanceSetting
ns.SetAppearanceSetting = SetAppearanceSetting
ns.FontPath = FontPath
ns.ResetAppearance = ResetAppearance
ns.GetTRP3Enabled = GetTRP3Enabled
ns.SetTRP3Enabled = SetTRP3Enabled
ns.GetTRP3Setting = GetTRP3Setting
ns.SetTRP3Setting = SetTRP3Setting
ns.DisableFriendlyClassColors = DisableFriendlyClassColors
ns.RestoreFriendlyClassColors = RestoreFriendlyClassColors
ns.ShowNameplateConflictWarning = ShowNameplateConflictWarning
ns.AccessibleNumber = AccessibleNumber
ns.AccessibleBoolean = AccessibleBoolean
ns.AccessibleValue = AccessibleValue
