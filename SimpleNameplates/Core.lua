-- Simple Nameplates: shared metadata, saved variables, and startup helpers.

local addon, ns = ...

local getAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local STANDARD_NAMEPLATES = "EllesmereUINameplates"

ns.VERSION = getAddOnMetadata and getAddOnMetadata(addon, "Version") or "Unknown"
ns.SOURCE_URL = "https://github.com/bblackmoor/SimpleNameplates"
ns.STANDARD_NAMEPLATES = STANDARD_NAMEPLATES

local issecretvalue = issecretvalue or function() return false end
local canaccessvalue = canaccessvalue or function(v) return not issecretvalue(v) end

local DEFAULT_COLORS = {
    friendlyNPC = { r = 0.20, g = 0.85, b = 0.25 },
    unfriendlyNPC = { r = 1.00, g = 0.82, b = 0.12 },
    hostileNPC = { r = 1.00, g = 0.48, b = 0.08 },
    attackingNPC = { r = 1.00, g = 0.12, b = 0.10 },
    friendlyPC = { r = 0.25, g = 0.75, b = 1.00 },
    unfriendlyPC = { r = 0.55, g = 0.55, b = 1.00 },
    hostilePC = { r = 0.85, g = 0.30, b = 1.00 },
    attackingPC = { r = 1.00, g = 0.15, b = 0.55 },
}
ns.DEFAULT_COLORS = DEFAULT_COLORS

local dbReady = false

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
    dbReady = true
    return db
end

local function ColorForState(state)
    local color = EnsureDB().colors[state] or DEFAULT_COLORS[state] or DEFAULT_COLORS.friendlyNPC
    return color.r, color.g, color.b
end

local function SetStateColor(state, r, g, b)
    EnsureDB().colors[state] = { r = r, g = g, b = b }
end

local function ResetStateColors()
    local colors = EnsureDB().colors
    for key, default in pairs(DEFAULT_COLORS) do
        colors[key] = { r = default.r, g = default.g, b = default.b }
    end
end

local FRIENDLY_COLOR_CVARS = {
    "nameplateUseClassColorForFriendlyPlayerUnitNames",
    "nameplateShowFriendlyClassColor",
    "ShowClassColorInFriendlyNameplate",
}
ns.FRIENDLY_COLOR_CVARS = FRIENDLY_COLOR_CVARS

local function DisableFriendlyClassColors()
    -- Midnight has separate CVars for friendly player name text and health-bar
    -- class coloring. Disable all known variants: Blizzard or another addon can update
    -- these independently, and leaving the name-text CVar enabled produces the
    -- familiar rainbow of class-colored friendly names.
    for _, cvar in ipairs(FRIENDLY_COLOR_CVARS) do
        if C_CVar and C_CVar.SetCVar then
            pcall(C_CVar.SetCVar, cvar, "0")
        elseif SetCVar then
            pcall(SetCVar, cvar, "0")
        end
    end
end

local function StandardNameplatesEnabled()
    if not C_AddOns then return false end
    if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(STANDARD_NAMEPLATES) then return true end
    if C_AddOns.GetAddOnEnableState then
        return (C_AddOns.GetAddOnEnableState(UnitName("player"), STANDARD_NAMEPLATES) or 0) > 0
    end
    return false
end

local function ShowNameplateConflictWarning()
    if not StandardNameplatesEnabled() then return end
    StaticPopupDialogs["ESNP_ELLESMERE_NAMEPLATE_CONFLICT"] = {
        text = "|cff0cd29fSimple Nameplates|r\n\n|cff0cd29fEllesmereUI Nameplates|r is also enabled. The two nameplate addons should not run together.\n\nDisable EllesmereUI Nameplates and reload the UI?",
        button1 = "Disable & Reload", button2 = "Ignore",
        OnAccept = function()
            if C_AddOns and C_AddOns.DisableAddOn then C_AddOns.DisableAddOn(STANDARD_NAMEPLATES) end
            ReloadUI()
        end,
        timeout = 0, whileDead = true, hideOnEscape = false, preferredIndex = 3,
    }
    StaticPopup_Show("ESNP_ELLESMERE_NAMEPLATE_CONFLICT")
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
ns.ResetStateColors = ResetStateColors
ns.DisableFriendlyClassColors = DisableFriendlyClassColors
ns.ShowNameplateConflictWarning = ShowNameplateConflictWarning
ns.AccessibleNumber = AccessibleNumber
ns.AccessibleBoolean = AccessibleBoolean
ns.AccessibleValue = AccessibleValue
