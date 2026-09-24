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
local DB_SCHEMA_VERSION = 2
local DEFAULT_PROFILE_NAME = "Default"
local HIGH_CONTRAST_PROFILE_NAME = "High Contrast"
local MAX_PROFILE_NAME_LENGTH = 64

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

local function NewProfile(presetName)
    local preset = presetName and COLOR_PRESETS[presetName] or nil
    local profile = {
        priorityColors = {},
        effectColors = {},
        appearance = {},
        showThreat = DEFAULT_SHOW_THREAT,
        interruptibleHighlight = false,
    }
    for key, default in pairs(DEFAULT_PRIORITY_COLORS) do
        local color = preset and preset.priorityColors and preset.priorityColors[key] or default
        profile.priorityColors[key] = CopyColor(color)
    end
    for key, default in pairs(DEFAULT_EFFECT_COLORS) do
        local color = preset and preset.effectColors and preset.effectColors[key] or default
        profile.effectColors[key] = CopyColor(color)
    end
    for key, value in pairs(DEFAULT_APPEARANCE) do profile.appearance[key] = value end
    return profile
end

local function ValidateProfileColors(profile, saved)
    local savedPriorityColors = type(saved.priorityColors) == "table"
        and saved.priorityColors or {}
    for key, default in pairs(profile.priorityColors) do
        local color = savedPriorityColors[key]
        profile.priorityColors[key] = CopyColor(IsValidColor(color) and color or default)
    end

    local savedEffectColors = type(saved.effectColors) == "table" and saved.effectColors or {}
    for key, default in pairs(profile.effectColors) do
        local color = savedEffectColors[key]
        profile.effectColors[key] = CopyColor(IsValidColor(color) and color or default)
    end
end

local function ValidateProfileAppearance(profile, saved)
    local savedAppearance = type(saved.appearance) == "table" and saved.appearance or {}
    profile.appearance.nameFont = FONT_BY_VALUE[savedAppearance.nameFont]
        and savedAppearance.nameFont or profile.appearance.nameFont
    if IsFiniteNumber(savedAppearance.nameSize)
        and savedAppearance.nameSize >= MIN_NAME_SIZE
        and savedAppearance.nameSize <= MAX_NAME_SIZE then
        profile.appearance.nameSize = math.floor(savedAppearance.nameSize + 0.5)
    end
    profile.appearance.threatFont = FONT_BY_VALUE[savedAppearance.threatFont]
        and savedAppearance.threatFont or profile.appearance.threatFont
    if savedAppearance.namePlacement == "ABOVE" or savedAppearance.namePlacement == "INSIDE" then
        profile.appearance.namePlacement = savedAppearance.namePlacement
    end
end

local function ValidateProfileToggles(profile, saved)
    profile.showThreat = SavedBoolean(saved.showThreat, profile.showThreat)
    profile.interruptibleHighlight = SavedBoolean(saved.interruptibleHighlight,
        profile.interruptibleHighlight)
end

local function ValidatedProfile(saved, presetName)
    if type(saved) ~= "table" then saved = {} end
    local profile = NewProfile(presetName)
    ValidateProfileColors(profile, saved)
    ValidateProfileAppearance(profile, saved)
    ValidateProfileToggles(profile, saved)
    return profile
end

local function CopyProfile(profile)
    return ValidatedProfile(profile)
end

local function CharacterKey()
    local guid = UnitGUID and UnitGUID("player")
    if type(guid) == "string" and guid ~= "" then return guid end
    local name, realm = UnitFullName and UnitFullName("player")
    if type(name) == "string" and name ~= "" then
        return name .. "-" .. ((type(realm) == "string" and realm ~= "") and realm or "Unknown")
    end
    return "Unknown"
end

local function CreateValidatedDB()
    return {
        schemaVersion = DB_SCHEMA_VERSION,
        global = {
            categoryModes = {},
            trp3 = {},
        },
        profiles = {},
        profileKeys = {},
    }
end

local function ValidateProfiles(db, savedProfiles)
    db.profiles[DEFAULT_PROFILE_NAME] = ValidatedProfile(savedProfiles[DEFAULT_PROFILE_NAME])
    if savedProfiles[HIGH_CONTRAST_PROFILE_NAME] == nil then
        db.profiles[HIGH_CONTRAST_PROFILE_NAME] = NewProfile("highContrast")
    else
        db.profiles[HIGH_CONTRAST_PROFILE_NAME] = ValidatedProfile(
            savedProfiles[HIGH_CONTRAST_PROFILE_NAME], "highContrast")
    end

    local knownProfileNames = {
        [string.lower(DEFAULT_PROFILE_NAME)] = true,
        [string.lower(HIGH_CONTRAST_PROFILE_NAME)] = true,
    }
    for name, profile in pairs(savedProfiles) do
        local normalized = type(name) == "string" and strtrim(name) or ""
        local lowerName = string.lower(normalized)
        if normalized == name and normalized ~= "" and #normalized <= MAX_PROFILE_NAME_LENGTH
            and not knownProfileNames[lowerName] then
            db.profiles[name] = ValidatedProfile(profile)
            knownProfileNames[lowerName] = true
        end
    end
end

local function ValidateProfileKeys(db, savedProfileKeys)
    savedProfileKeys = type(savedProfileKeys) == "table" and savedProfileKeys or {}
    for character, profileName in pairs(savedProfileKeys) do
        if type(character) == "string" and type(profileName) == "string"
            and db.profiles[profileName] then
            db.profileKeys[character] = profileName
        end
    end
end

local function ValidateCategoryModes(db, savedGlobal)
    local savedCategoryModes = type(savedGlobal.categoryModes) == "table"
        and savedGlobal.categoryModes or {}
    for key, default in pairs(DEFAULT_CATEGORY_MODES) do
        local mode = savedCategoryModes[key]
        db.global.categoryModes[key] = (mode == "active" or mode == "inactive" or mode == "hide")
            and mode or default
    end
end

local function ValidateGlobalToggles(db, savedGlobal)
    db.global.stylingEnabled = SavedBoolean(savedGlobal.stylingEnabled, DEFAULT_STYLING_ENABLED)
    db.global.hideBlizzardMinionNames = SavedBoolean(savedGlobal.hideBlizzardMinionNames,
        DEFAULT_HIDE_BLIZZARD_MINION_NAMES)
    db.global.hideCritterCompanionNames = SavedBoolean(savedGlobal.hideCritterCompanionNames,
        DEFAULT_HIDE_CRITTER_COMPANION_NAMES)
    db.global.replaceBlizzardOverheadNames = SavedBoolean(savedGlobal.replaceBlizzardOverheadNames,
        DEFAULT_REPLACE_BLIZZARD_OVERHEAD_NAMES)
end

local function ValidateTRP3Settings(db, savedGlobal)
    local savedTRP3 = type(savedGlobal.trp3) == "table" and savedGlobal.trp3 or {}
    for key, default in pairs(DEFAULT_TRP3) do
        db.global.trp3[key] = SavedBoolean(savedTRP3[key], default)
    end
end

local function ValidatedDB(saved)
    -- Saved data from another schema is intentionally ignored. Keeping schema
    -- changes here avoids permanent one-off migration code and prevents stale
    -- or misplaced settings from leaking into the current configuration.
    if type(saved) ~= "table" or saved.schemaVersion ~= DB_SCHEMA_VERSION then saved = {} end

    local savedGlobal = type(saved.global) == "table" and saved.global or {}
    local savedProfiles = type(saved.profiles) == "table" and saved.profiles or {}
    local db = CreateValidatedDB()

    ValidateProfiles(db, savedProfiles)
    ValidateProfileKeys(db, saved.profileKeys)
    ValidateCategoryModes(db, savedGlobal)
    ValidateGlobalToggles(db, savedGlobal)
    ValidateTRP3Settings(db, savedGlobal)
    db.global.managedNameCVarOriginals = CopySavedCVarOriginals(
        savedGlobal.managedNameCVarOriginals, MANAGED_NAME_CVARS) or {}
    return db
end

local function EnsureDB()
    if dbReady then return SimpleNameplatesDB end
    SimpleNameplatesDB = ValidatedDB(SimpleNameplatesDB)
    dbReady = true
    return SimpleNameplatesDB
end

local function GetActiveProfileName()
    local db = EnsureDB()
    local key = CharacterKey()
    local profileName = db.profileKeys[key]
    if not db.profiles[profileName] then
        profileName = DEFAULT_PROFILE_NAME
        db.profileKeys[key] = profileName
    end
    return profileName
end

local function ActiveProfile()
    local db = EnsureDB()
    return db.profiles[GetActiveProfileName()]
end

local function ActiveProfileDefaults()
    return NewProfile(GetActiveProfileName() == HIGH_CONTRAST_PROFILE_NAME
        and "highContrast" or nil)
end

local function GetProfileNames()
    local names = {}
    for name in pairs(EnsureDB().profiles) do names[#names + 1] = name end
    table.sort(names, function(a, b)
        if a == b then return false end
        if a == DEFAULT_PROFILE_NAME then return true end
        if b == DEFAULT_PROFILE_NAME then return false end
        if a == HIGH_CONTRAST_PROFILE_NAME then return true end
        if b == HIGH_CONTRAST_PROFILE_NAME then return false end
        return string.lower(a) < string.lower(b)
    end)
    return names
end

local function FindProfileName(name)
    if type(name) ~= "string" then return nil end
    local wanted = string.lower(name)
    for existing in pairs(EnsureDB().profiles) do
        if string.lower(existing) == wanted then return existing end
    end
end

local function ValidProfileName(name, currentName)
    name = type(name) == "string" and strtrim(name) or ""
    if name == "" then return nil, "Enter a profile name." end
    if #name > MAX_PROFILE_NAME_LENGTH then
        return nil, "Profile names may contain at most 64 characters."
    end
    local existing = FindProfileName(name)
    if existing and existing ~= currentName then return nil, "That profile name is already in use." end
    return name
end

local function SetActiveProfileName(name)
    local exactName = FindProfileName(name)
    if not exactName then return false, "Profile not found." end
    EnsureDB().profileKeys[CharacterKey()] = exactName
    return true
end

local function CreateProfile(name)
    local validName, errorMessage = ValidProfileName(name)
    if not validName then return false, errorMessage end
    EnsureDB().profiles[validName] = NewProfile()
    SetActiveProfileName(validName)
    return true
end

local function CopyActiveProfile(name)
    local validName, errorMessage = ValidProfileName(name)
    if not validName then return false, errorMessage end
    EnsureDB().profiles[validName] = CopyProfile(ActiveProfile())
    SetActiveProfileName(validName)
    return true
end

local function RenameActiveProfile(name)
    local db = EnsureDB()
    local oldName = GetActiveProfileName()
    if oldName == DEFAULT_PROFILE_NAME then return false, "Default cannot be renamed." end
    local validName, errorMessage = ValidProfileName(name, oldName)
    if not validName then return false, errorMessage end
    if validName == oldName then return true end
    db.profiles[validName] = db.profiles[oldName]
    db.profiles[oldName] = nil
    for character, assignedName in pairs(db.profileKeys) do
        if assignedName == oldName then db.profileKeys[character] = validName end
    end
    return true
end

local function DeleteActiveProfile()
    local db = EnsureDB()
    local name = GetActiveProfileName()
    if name == DEFAULT_PROFILE_NAME then return false, "Default cannot be deleted." end
    db.profiles[name] = nil
    for character, assignedName in pairs(db.profileKeys) do
        if assignedName == name then db.profileKeys[character] = DEFAULT_PROFILE_NAME end
    end
    return true
end

local function RestoreBundledProfiles()
    local db = EnsureDB()
    db.profiles[DEFAULT_PROFILE_NAME] = NewProfile()
    db.profiles[HIGH_CONTRAST_PROFILE_NAME] = NewProfile("highContrast")
end

local function GetTRP3Enabled()
    return EnsureDB().global.trp3.enabled
end

local function SetTRP3Enabled(enabled)
    EnsureDB().global.trp3.enabled = enabled == true
end

local function GetTRP3Setting(key)
    return EnsureDB().global.trp3[key]
end

local function SetTRP3Setting(key, enabled)
    if DEFAULT_TRP3[key] ~= nil then
        EnsureDB().global.trp3[key] = enabled == true
    end
end

local function GetAppearanceSetting(key)
    return ActiveProfile().appearance[key]
end

local function SetAppearanceSetting(key, value)
    local appearance = ActiveProfile().appearance
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
    local appearance = ActiveProfile().appearance
    for key, value in pairs(DEFAULT_APPEARANCE) do appearance[key] = value end
end

local ApplyManagedNameSettings

local function PriorityColorForState(state)
    local color = ActiveProfile().priorityColors[state]
        or DEFAULT_PRIORITY_COLORS[state]
        or DEFAULT_PRIORITY_COLORS.other
    return color.r, color.g, color.b
end

local function GetCategoryMode(state)
    return EnsureDB().global.categoryModes[state] or "active"
end

local function SetCategoryMode(state, mode)
    if not DEFAULT_CATEGORY_MODES[state]
        or (mode ~= "active" and mode ~= "inactive" and mode ~= "hide") then return end
    EnsureDB().global.categoryModes[state] = mode
    if ApplyManagedNameSettings then ApplyManagedNameSettings() end
end

local function SetPriorityColor(state, r, g, b)
    if DEFAULT_PRIORITY_COLORS[state] then
        ActiveProfile().priorityColors[state] = { r = r, g = g, b = b }
    end
end

local function ResetPriorityColor(state)
    local default = ActiveProfileDefaults().priorityColors[state]
    if not default then return end
    ActiveProfile().priorityColors[state] = CopyColor(default)
end

local function EffectColor(effect)
    local color = ActiveProfile().effectColors[effect]
        or DEFAULT_EFFECT_COLORS[effect]
        or DEFAULT_EFFECT_COLORS.interruptible
    return color.r, color.g, color.b
end

local function SetEffectColor(effect, r, g, b)
    if DEFAULT_EFFECT_COLORS[effect] then
        ActiveProfile().effectColors[effect] = { r = r, g = g, b = b }
    end
end

local function ResetEffectColor(effect)
    local default = ActiveProfileDefaults().effectColors[effect]
    if not default then return end
    ActiveProfile().effectColors[effect] = CopyColor(default)
end

local function ResetAllColors()
    local profile = ActiveProfile()
    local defaults = ActiveProfileDefaults()
    for key, default in pairs(defaults.priorityColors) do
        profile.priorityColors[key] = CopyColor(default)
    end
    for key, default in pairs(defaults.effectColors) do
        profile.effectColors[key] = CopyColor(default)
    end
end

local function GetInterruptibleHighlightEnabled()
    return ActiveProfile().interruptibleHighlight
end

local function SetInterruptibleHighlightEnabled(enabled)
    ActiveProfile().interruptibleHighlight = enabled == true
end

local function GetStylingEnabled()
    return EnsureDB().global.stylingEnabled
end

local function SetStylingEnabled(enabled)
    EnsureDB().global.stylingEnabled = enabled == true
end

local function GetThreatEnabled()
    return ActiveProfile().showThreat
end

local function SetThreatEnabled(enabled)
    ActiveProfile().showThreat = enabled == true
end

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

ApplyManagedNameSettings = function()
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

ns.EnsureDB = EnsureDB
ns.DEFAULT_PROFILE_NAME = DEFAULT_PROFILE_NAME
ns.HIGH_CONTRAST_PROFILE_NAME = HIGH_CONTRAST_PROFILE_NAME
ns.GetActiveProfileName = GetActiveProfileName
ns.GetProfileNames = GetProfileNames
ns.SetActiveProfileName = SetActiveProfileName
ns.CreateProfile = CreateProfile
ns.CopyActiveProfile = CopyActiveProfile
ns.RenameActiveProfile = RenameActiveProfile
ns.DeleteActiveProfile = DeleteActiveProfile
ns.RestoreBundledProfiles = RestoreBundledProfiles
ns.PriorityColorForState = PriorityColorForState
ns.GetCategoryMode = GetCategoryMode
ns.SetCategoryMode = SetCategoryMode
ns.SetPriorityColor = SetPriorityColor
ns.ResetPriorityColor = ResetPriorityColor
ns.EffectColor = EffectColor
ns.SetEffectColor = SetEffectColor
ns.ResetEffectColor = ResetEffectColor
ns.ResetAllColors = ResetAllColors
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
