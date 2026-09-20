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

local DEFAULT_COLORS = {
    friendlyNPC = RGB8(51, 204, 51),
    unfriendlyNPC = RGB8(255, 204, 0),
    hostileNPC = RGB8(255, 102, 0),
    attackingNPC = RGB8(255, 0, 0),
    friendlyPC = RGB8(51, 204, 255),
    unfriendlyPC = RGB8(0, 255, 204),
    attackablePC = RGB8(255, 204, 0),
    attackingPC = RGB8(255, 51, 153),
}
ns.DEFAULT_COLORS = DEFAULT_COLORS

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

local OVERHEAD_FONT_OPTIONS = {
    { value = "DEFAULT", label = "Blizzard default" },
}
for _, option in ipairs(FONT_OPTIONS) do
    OVERHEAD_FONT_OPTIONS[#OVERHEAD_FONT_OPTIONS + 1] = option
end

local BLIZZARD_UNIT_NAME_FONT = _G.UNIT_NAME_FONT or "Fonts\\FRIZQT__.TTF"

local DEFAULT_APPEARANCE = {
    nameFont = "ARIALN",
    threatFont = "ARIALN",
    overheadNameFont = "DEFAULT",
    namePlacement = "ABOVE",
}

local DEFAULT_TRP3 = {
    enabled = false,
    useRoleplayingName = true,
    showShortTitle = true,
    showFullTitle = true,
    showOOC = true,
}

local DEFAULT_STYLING_ENABLED = true
local DEFAULT_SHOW_THREAT = true

ns.FONT_OPTIONS = FONT_OPTIONS
ns.OVERHEAD_FONT_OPTIONS = OVERHEAD_FONT_OPTIONS
ns.DEFAULT_APPEARANCE = DEFAULT_APPEARANCE

local dbReady = false

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

-- Versions 1.0.35 through 1.0.37 offered an option that tried to replace
-- Blizzard's overhead names with nameplates. Midnight does not create a
-- nameplate for every affected unit, so restore settings saved by that option
-- once and remove its obsolete saved state.
local function RemoveOverheadNameReplacement(db)
    local originals = db.overheadNameCVarOriginals
    db.replaceOverheadNames = nil
    db.overheadNameCVarOriginals = nil

    -- Clear the obsolete saved state before SetCVar fires CVAR_UPDATE. This
    -- makes the one-time migration safe even if another event handler enters
    -- the database while the original settings are being restored.
    if type(originals) == "table" then
        for cvar, value in pairs(originals) do
            SetCVarValue(cvar, value)
        end
    end
end

local function EnsureDB()
    if dbReady then return SimpleNameplatesDB end
    if type(SimpleNameplatesDB) ~= "table" then
        SimpleNameplatesDB = {}
    end
    local db = SimpleNameplatesDB
    if type(db.colors) ~= "table" then db.colors = {} end
    for key, default in pairs(DEFAULT_COLORS) do
        local color = db.colors[key]
        if type(color) ~= "table" or type(color.r) ~= "number"
            or type(color.g) ~= "number" or type(color.b) ~= "number" then
            db.colors[key] = { r = default.r, g = default.g, b = default.b }
        end
    end
    if type(db.appearance) ~= "table" then db.appearance = {} end
    if not FONT_BY_VALUE[db.appearance.nameFont] then
        db.appearance.nameFont = DEFAULT_APPEARANCE.nameFont
    end
    if not FONT_BY_VALUE[db.appearance.threatFont] then
        db.appearance.threatFont = DEFAULT_APPEARANCE.threatFont
    end
    if db.appearance.overheadNameFont ~= "DEFAULT"
        and not FONT_BY_VALUE[db.appearance.overheadNameFont] then
        db.appearance.overheadNameFont = DEFAULT_APPEARANCE.overheadNameFont
    end
    if db.appearance.namePlacement ~= "ABOVE" and db.appearance.namePlacement ~= "INSIDE" then
        db.appearance.namePlacement = DEFAULT_APPEARANCE.namePlacement
    end
    if type(db.stylingEnabled) ~= "boolean" then db.stylingEnabled = DEFAULT_STYLING_ENABLED end
    if type(db.showThreat) ~= "boolean" then db.showThreat = DEFAULT_SHOW_THREAT end
    if type(db.pcGlow) ~= "boolean" then db.pcGlow = false end
    if type(db.trp3) ~= "table" then db.trp3 = {} end
    for key, default in pairs(DEFAULT_TRP3) do
        if type(db.trp3[key]) ~= "boolean" then db.trp3[key] = default end
    end

    -- CVar restoration below fires CVAR_UPDATE synchronously. Mark the
    -- database ready first so those events cannot recursively initialize it.
    dbReady = true
    RemoveOverheadNameReplacement(db)
    return db
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

local function ApplyOverheadNameFont()
    local appearance = EnsureDB().appearance
    local value = appearance.overheadNameFont
    local option = FONT_BY_VALUE[value]
    if value == "DEFAULT" or not option then
        appearance.overheadNameFont = "DEFAULT"
        _G.UNIT_NAME_FONT = BLIZZARD_UNIT_NAME_FONT
    else
        _G.UNIT_NAME_FONT = option.path
    end
end

local function SetAppearanceSetting(key, value)
    local appearance = EnsureDB().appearance
    if (key == "nameFont" or key == "threatFont") and FONT_BY_VALUE[value] then
        appearance[key] = value
    elseif key == "overheadNameFont" and (value == "DEFAULT" or FONT_BY_VALUE[value]) then
        appearance[key] = value
        ApplyOverheadNameFont()
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
    ApplyOverheadNameFont()
end

local function ColorForState(state)
    local color = EnsureDB().colors[state] or DEFAULT_COLORS[state] or DEFAULT_COLORS.friendlyNPC
    return color.r, color.g, color.b
end

local function SetStateColor(state, r, g, b)
    EnsureDB().colors[state] = { r = r, g = g, b = b }
end

local function ResetStateColor(state)
    local default = DEFAULT_COLORS[state]
    if not default then return end
    EnsureDB().colors[state] = { r = default.r, g = default.g, b = default.b }
end

local function ResetStateColors()
    local colors = EnsureDB().colors
    for key, default in pairs(DEFAULT_COLORS) do
        colors[key] = { r = default.r, g = default.g, b = default.b }
    end
end

local function GetPCGlowEnabled()
    return EnsureDB().pcGlow
end

local function SetPCGlowEnabled(enabled)
    EnsureDB().pcGlow = enabled == true
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

local FRIENDLY_COLOR_CVARS = {
    "nameplateUseClassColorForFriendlyPlayerUnitNames",
    "nameplateShowFriendlyClassColor",
    "ShowClassColorInFriendlyNameplate",
}
ns.FRIENDLY_COLOR_CVARS = FRIENDLY_COLOR_CVARS
local friendlyColorCVarOriginals = {}
local friendlyColorCVarsCaptured = false

local function DisableFriendlyClassColors()
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

local function RestoreFriendlyClassColors()
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
ns.ColorForState = ColorForState
ns.SetStateColor = SetStateColor
ns.ResetStateColor = ResetStateColor
ns.ResetStateColors = ResetStateColors
ns.GetPCGlowEnabled = GetPCGlowEnabled
ns.SetPCGlowEnabled = SetPCGlowEnabled
ns.GetStylingEnabled = GetStylingEnabled
ns.SetStylingEnabled = SetStylingEnabled
ns.GetThreatEnabled = GetThreatEnabled
ns.SetThreatEnabled = SetThreatEnabled
ns.GetAppearanceSetting = GetAppearanceSetting
ns.SetAppearanceSetting = SetAppearanceSetting
ns.ApplyOverheadNameFont = ApplyOverheadNameFont
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
