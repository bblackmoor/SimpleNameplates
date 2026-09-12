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
    if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(STANDARD_NAMEPLATES) then
        return true
    end
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
        button1 = "Disable & Reload",
        button2 = "Ignore",
        OnAccept = function()
            if C_AddOns and C_AddOns.DisableAddOn then
                C_AddOns.DisableAddOn(STANDARD_NAMEPLATES)
            end
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,
        preferredIndex = 3,
    }
    StaticPopup_Show("ESNP_ELLESMERE_NAMEPLATE_CONFLICT")
end

local function AccessibleNumber(value)
    if value == nil or issecretvalue(value) or not canaccessvalue(value) then
        return nil
    end
    if type(value) ~= "number" then return nil end
    return value
end

local function ColorForUnit(unit)
    -- Reaction is the cleanest expression of the three non-combat states.
    -- 5-8 friendly; 4 neutral; 1-3 hostile.
    local reaction = UnitReaction(unit, "player")
    if reaction ~= nil and not issecretvalue(reaction) and canaccessvalue(reaction) then
        if reaction >= 5 then
            return COLORS.friendly
        elseif reaction == 4 then
            return COLORS.neutral
        end
    else
        -- Conservative fallback when reaction is unavailable. Only call something
        -- friendly when neither side can attack the other.
        local playerCanAttack = UnitCanAttack("player", unit)
        local unitCanAttack = UnitCanAttack(unit, "player")
        if not playerCanAttack and not unitCanAttack then
            return COLORS.friendly
        end
    end

    -- Threat status 2 and 3 both mean the player is the mob's primary target.
    -- That is exactly our definition of RED. Status 0/1 remains ORANGE.
    local threat = UnitThreatSituation("player", unit)
    if threat ~= nil and not issecretvalue(threat) and canaccessvalue(threat) then
        if threat >= 2 then
            return COLORS.angry
        end
    end

    return COLORS.hostile
end

local function GetUnitFrame(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    return plate and plate.UnitFrame or nil
end

local function EnsureThreatText(frame)
    if frame.ESNPThreatText then return frame.ESNPThreatText end

    local healthBar = frame.healthBar or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)
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
    if not unit or not UnitCanAttack("player", unit) then
        text:SetText("")
        return
    end

    local _, _, scaledPercent, rawPercent = UnitDetailedThreatSituation("player", unit)
    local percent = AccessibleNumber(rawPercent) or AccessibleNumber(scaledPercent)
    if percent then
        text:SetFormattedText("%.0f%%", percent)
    else
        -- Midnight may intentionally make threat values secret. Never attempt to
        -- inspect or format a secret value; the color state can still be useful.
        text:SetText("")
    end
end

local function ApplySimpleColor(frame)
    if not frame or not frame.unit then return end
    if not tostring(frame.unit):match("^nameplate%d+$") then return end

    local healthBar = frame.healthBar or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)
    if not healthBar then return end

    local color = ColorForUnit(frame.unit)
    healthBar:SetStatusBarColor(color[1], color[2], color[3], 1)

    -- Keep the name and health bar speaking the same four-color language.
    if frame.name then
        frame.name:SetTextColor(color[1], color[2], color[3], 1)
    end

    UpdateThreatText(frame)
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

-- Blizzard recolors the health bar for faction, selection, and other normal
-- updates. Re-apply our deliberately small palette after Blizzard finishes.
if hooksecurefunc and CompactUnitFrame_UpdateHealthColor then
    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
        ApplySimpleColor(frame)
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_FACTION")
events:RegisterEvent("UNIT_FLAGS")
events:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
events:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0.5, ShowNameplateConflictWarning)
        return
    end

    if event == "NAME_PLATE_UNIT_ADDED" then
        -- Let Blizzard finish its normal setup first, then apply only our color.
        C_Timer.After(0, function() RefreshUnit(unit) end)
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        RefreshAll()
        return
    end

    if unit and tostring(unit):match("^nameplate%d+$") then
        RefreshUnit(unit)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        -- This event can refer to the player rather than a particular nameplate.
        RefreshAll()
    end
end)

-- Public helper for testing: /run EllesmereUI._ModuleNS.EllesmereUISimpleNameplates.RefreshAll()
ns.RefreshAll = RefreshAll
