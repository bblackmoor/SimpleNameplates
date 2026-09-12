-- EllesmereUI Simple Nameplates
--
-- This addon does NOT create a second nameplate. It keeps Blizzard's current
-- Midnight nameplate frame (health depletion, cast bar, target treatment,
-- classification, etc.) and replaces only the reaction/threat color language.
--
--   green  = friendly / cannot fight
--   yellow = neutral / attackable but non-aggressive
--   orange = hostile / not currently attacking you
--   red    = hostile and currently targeting/tanking you

if EUI_CLIENT_BLOCKED then return end
local addon, ns = ...
if not EllesmereUI then return end
if EllesmereUI._ModuleNS then EllesmereUI._ModuleNS[addon] = ns end

local C_NamePlate = C_NamePlate
local UnitCanAttack = UnitCanAttack
local UnitReaction = UnitReaction
local UnitThreatSituation = UnitThreatSituation
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitName = UnitName
local issecretvalue = issecretvalue or function() return false end
local canaccessvalue = canaccessvalue or function(v) return not issecretvalue(v) end

local STANDARD_NAMEPLATES = "EllesmereUINameplates"

local COLORS = {
    friendly = { 0.20, 0.85, 0.25 },
    neutral  = { 1.00, 0.82, 0.12 },
    hostile  = { 1.00, 0.48, 0.08 },
    angry    = { 1.00, 0.12, 0.10 },
}

local function StandardNameplatesEnabled()
    if not C_AddOns then return false end
    if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(STANDARD_NAMEPLATES) then return true end
    if C_AddOns.GetAddOnEnableState then
        local player = UnitName("player")
        return (C_AddOns.GetAddOnEnableState(STANDARD_NAMEPLATES, player) or 0) > 0
    end
    return false
end

local function ShowNameplateConflictWarning()
    if not StandardNameplatesEnabled() then return end
    StaticPopupDialogs["ESNP_ELLESMERE_NAMEPLATE_CONFLICT"] = {
        text = "|cff0cd29fEllesmereUI Simple Nameplates|r\n\nThe standard |cff0cd29fEllesmereUI Nameplates|r addon is also enabled. The two nameplate modules should not run together.\n\nDisable standard EllesmereUI Nameplates and reload the UI?",
        button1 = "Disable & Reload", button2 = "Ignore",
        OnAccept = function()
            if C_AddOns and C_AddOns.DisableAddOn then C_AddOns.DisableAddOn(STANDARD_NAMEPLATES) end
            ReloadUI()
        end,
        timeout = 0, whileDead = true, hideOnEscape = false, preferredIndex = 3,
    }
    StaticPopup_Show("ESNP_ELLESMERE_NAMEPLATE_CONFLICT")
end

local function AccessibleNumber(value)
    if value == nil or issecretvalue(value) or not canaccessvalue(value) then return nil end
    if type(value) ~= "number" then return nil end
    return value
end

local function ColorForUnit(unit)
    local reaction = UnitReaction(unit, "player")
    local reactionAccessible = reaction ~= nil and not issecretvalue(reaction) and canaccessvalue(reaction)
    if reactionAccessible and reaction >= 5 then return COLORS.friendly end
    if not reactionAccessible then
        local playerCanAttack = UnitCanAttack("player", unit)
        local unitCanAttack = UnitCanAttack(unit, "player")
        if not playerCanAttack and not unitCanAttack then return COLORS.friendly end
    end
    local threat = UnitThreatSituation("player", unit)
    if threat ~= nil and not issecretvalue(threat) and canaccessvalue(threat) and threat >= 2 then
        return COLORS.angry
    end
    if reactionAccessible and reaction == 4 then return COLORS.neutral end
    return COLORS.hostile
end

local function GetUnitFrame(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    return plate and plate.UnitFrame or nil
end

local function GetHealthBar(frame)
    return frame and (frame.healthBar or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)) or nil
end

local function UpdateHealthValue(frame)
    local unit = frame and frame.unit
    local healthBar = GetHealthBar(frame)
    if not unit or not healthBar then return end
    local health = AccessibleNumber(UnitHealth(unit))
    local healthMax = AccessibleNumber(UnitHealthMax(unit))
    if not health or not healthMax or healthMax <= 0 then return end
    healthBar:SetMinMaxValues(0, healthMax)
    healthBar:SetValue(health)
end

local function StyleName(frame, color)
    local name = frame and frame.name
    if not name then return end

    -- Names are labels first and status indicators second. White provides maximum
    -- contrast for normal plates; a heavy outline keeps the text readable over
    -- bright floors, foliage, spell effects, and dark interiors.
    local font, size = name:GetFont()
    if font and size then name:SetFont(font, size, "THICKOUTLINE") end
    name:SetShadowColor(0, 0, 0, 1)
    name:SetShadowOffset(1, -1)

    if GetHealthBar(frame) then
        name:SetTextColor(1, 1, 1, 1)
    else
        -- If Blizzard gives a friendly unit a name-only plate, retain green as the
        -- only available friendly-state signal while keeping the strong outline.
        name:SetTextColor(color[1], color[2], color[3], 1)
    end
end

local function EnsureThreatText(frame)
    if frame.ESNPThreatText then return frame.ESNPThreatText end
    local healthBar = GetHealthBar(frame)
    if not healthBar then return nil end
    local text = healthBar:CreateFontString(nil, "OVERLAY")
    text:SetPoint("RIGHT", healthBar, "RIGHT", -3, 0)
    text:SetJustifyH("RIGHT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    text:SetTextColor(1, 1, 1, 1)
    frame.ESNPThreatText = text
    return text
end

local function UpdateThreatText(frame)
    local text = EnsureThreatText(frame)
    if not text then return end
    local unit = frame.unit
    if not unit or not UnitCanAttack("player", unit) then text:SetText(""); return end
    local _, _, scaledPercent, rawPercent = UnitDetailedThreatSituation("player", unit)
    local percent = AccessibleNumber(rawPercent) or AccessibleNumber(scaledPercent)
    if percent then text:SetFormattedText("%.0f%%", percent) else text:SetText("") end
end

local function ApplySimpleColor(frame)
    if not frame or not frame.unit then return end
    if not tostring(frame.unit):match("^nameplate%d+$") then return end
    local healthBar = GetHealthBar(frame)
    local color = ColorForUnit(frame.unit)

    if healthBar then
        UpdateHealthValue(frame)
        healthBar:SetStatusBarColor(color[1], color[2], color[3], 1)
        UpdateThreatText(frame)
    end

    StyleName(frame, color)
end

local function RefreshUnit(unit)
    local frame = GetUnitFrame(unit)
    if frame then ApplySimpleColor(frame) end
end

local function RefreshAll()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if plate.UnitFrame then ApplySimpleColor(plate.UnitFrame) end
    end
end

if hooksecurefunc and CompactUnitFrame_UpdateHealthColor then
    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame) ApplySimpleColor(frame) end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_FACTION")
events:RegisterEvent("UNIT_FLAGS")
events:RegisterEvent("UNIT_HEALTH")
events:RegisterEvent("UNIT_MAXHEALTH")
events:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
events:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then C_Timer.After(0.5, ShowNameplateConflictWarning); return end
    if event == "NAME_PLATE_UNIT_ADDED" then C_Timer.After(0, function() RefreshUnit(unit) end); return end
    if event == "PLAYER_TARGET_CHANGED" then RefreshAll(); return end
    if unit and tostring(unit):match("^nameplate%d+$") then
        RefreshUnit(unit)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        RefreshAll()
    end
end)

ns.RefreshAll = RefreshAll
