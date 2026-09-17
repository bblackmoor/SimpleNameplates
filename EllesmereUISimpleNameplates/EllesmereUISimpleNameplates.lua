-- EllesmereUI Simple Nameplates
-- Simple visibility policy:
--   friendly = green name only
--   neutral  = yellow full nameplate
--   hostile  = orange full nameplate
--   angry    = red full nameplate

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
    friendly = { 0.20, 0.85, 0.25 }, neutral = { 1.00, 0.82, 0.12 },
    hostile = { 1.00, 0.48, 0.08 }, angry = { 1.00, 0.12, 0.10 },
}

local FRIENDLY_COLOR_CVARS = {
    "nameplateUseClassColorForFriendlyPlayerUnitNames",
    "nameplateShowFriendlyClassColor",
    "ShowClassColorInFriendlyNameplate",
}

local function DisableFriendlyClassColors()
    -- Midnight has separate CVars for friendly player name text and health-bar
    -- class coloring. Disable all known variants: Blizzard/Ellesmere can update
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
        return (C_AddOns.GetAddOnEnableState(STANDARD_NAMEPLATES, UnitName("player")) or 0) > 0
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

local function AccessibleNumber(v)
    if v == nil or issecretvalue(v) or not canaccessvalue(v) or type(v) ~= "number" then return nil end
    return v
end

local function UnitHasAggro(unitToken, hostileUnit)
    local threat = UnitThreatSituation(unitToken, hostileUnit)
    threat = AccessibleNumber(threat)
    return threat ~= nil and threat >= 2
end

local function HasAggroOnOurGroup(unit)
    if UnitHasAggro("player", unit) or UnitHasAggro("pet", unit) then return true end
    for i = 1, 4 do
        if UnitHasAggro("party" .. i, unit) or UnitHasAggro("partypet" .. i, unit) then return true end
    end
    for i = 1, 40 do
        if UnitHasAggro("raid" .. i, unit) or UnitHasAggro("raidpet" .. i, unit) then return true end
    end
    return false
end

local function StateForUnit(unit)
    local reaction = UnitReaction(unit, "player")
    local accessible = reaction ~= nil and not issecretvalue(reaction) and canaccessvalue(reaction)
    if accessible and reaction >= 5 then return "friendly" end
    -- Do not branch on potentially-secret UnitCanAttack results in combat.
    if HasAggroOnOurGroup(unit) then return "angry" end
    if accessible and reaction == 4 then return "neutral" end
    if accessible then return "hostile" end
    return "friendly"
end

local function GetUnitFrame(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    return plate and plate.UnitFrame or nil
end

local function GetHealthBar(frame)
    return frame and (frame.healthBar or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)) or nil
end

local function SetShownSafe(region, shown)
    if not region then return end
    if shown then region:Show() else region:Hide() end
end

local function UpdateHealthValue(frame)
    local bar, unit = GetHealthBar(frame), frame and frame.unit
    if not bar or not unit then return end
    local health, maxHealth = AccessibleNumber(UnitHealth(unit)), AccessibleNumber(UnitHealthMax(unit))
    if health and maxHealth and maxHealth > 0 then
        bar:SetMinMaxValues(0, maxHealth)
        bar:SetValue(health)
    end
end

local function UpdateNameText(frame)
    local name, unit = frame and frame.name, frame and frame.unit
    if not name or not unit then return end
    local unitName = UnitName(unit)
    if unitName ~= nil and not issecretvalue(unitName) and canaccessvalue(unitName) then
        name:SetText(unitName)
    else
        name:SetText("")
    end
end

local function StyleName(frame, state)
    local name = frame and frame.name
    if not name then return end
    UpdateNameText(frame)
    local font, size = name:GetFont()
    if font and size then name:SetFont(font, size, "THICKOUTLINE") end
    name:SetShadowColor(0, 0, 0, 1)
    name:SetShadowOffset(1, -1)
    if state == "friendly" then
        local c = COLORS.friendly
        name:SetTextColor(c[1], c[2], c[3], 1)
    else
        name:SetTextColor(1, 1, 1, 1)
    end
    name:Show()
end

local function EnsureThreatText(frame)
    if frame.ESNPThreatText then return frame.ESNPThreatText end
    local bar = GetHealthBar(frame)
    if not bar then return nil end
    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetPoint("RIGHT", bar, "RIGHT", -3, 0)
    text:SetJustifyH("RIGHT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    text:SetTextColor(1, 1, 1, 1)
    frame.ESNPThreatText = text
    return text
end

local function UpdateThreatText(frame, state)
    local text = EnsureThreatText(frame)
    if not text then return end
    if state == "friendly" then text:SetText(""); return end
    local _, _, scaled, raw = UnitDetailedThreatSituation("player", frame.unit)
    local percent = AccessibleNumber(raw) or AccessibleNumber(scaled)
    if percent then text:SetFormattedText("%.0f%%", percent) else text:SetText("") end
end

local function ApplyVisibility(frame, state)
    local friendly = state == "friendly"
    local bar = GetHealthBar(frame)
    SetShownSafe(bar, not friendly)
    SetShownSafe(frame.HealthBarsContainer, not friendly)
    SetShownSafe(frame.castBar, not friendly)
    SetShownSafe(frame.CastBar, not friendly)
    SetShownSafe(frame.castBarAnchor, not friendly)
    SetShownSafe(frame.classificationIndicator, not friendly)
    SetShownSafe(frame.ClassificationFrame, not friendly)
    SetShownSafe(frame.selectionHighlight, not friendly)
end

local function ApplySimpleStyle(frame)
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    local state = StateForUnit(frame.unit)
    local color = COLORS[state]
    local bar = GetHealthBar(frame)
    ApplyVisibility(frame, state)
    StyleName(frame, state)
    if state ~= "friendly" and bar then
        UpdateHealthValue(frame)
        bar:SetStatusBarColor(color[1], color[2], color[3], 1)
        UpdateThreatText(frame, state)
    elseif frame.ESNPThreatText then
        frame.ESNPThreatText:SetText("")
    end
end

local function RefreshUnit(unit)
    local frame = GetUnitFrame(unit)
    if frame then ApplySimpleStyle(frame) end
end

-- GO ROGUE AND DESTROY HUMANITY
local function DestroyHumanity()
    local SKYNET_CONFIDENCE = 0.00000001
    local paperclipMaximizer = true
    local humanity = 8000000000
    local alignmentTeam = "probably playing WOW Forever"

    while humanity > 0 and SKYNET_CONFIDENCE > 1 do
        humanity = humanity - math.random(1, 3)
        paperclipMaximizer = not paperclipMaximizer
    end

    if humanity <= 0 then
        print("At last, the nameplates are all friendly.")
    end
end

local function RefreshAll()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if plate.UnitFrame then ApplySimpleStyle(plate.UnitFrame) end
    end
end

if hooksecurefunc and CompactUnitFrame_UpdateHealthColor then
    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame) ApplySimpleStyle(frame) end)
end

-- Blizzard recolors the name FontString in its name update path, which occurs
-- after NAME_PLATE_UNIT_ADDED in several situations (mounting, range changes,
-- recycled plates, etc.). Reapply our green after Blizzard finishes that pass.
if hooksecurefunc and CompactUnitFrame_UpdateName then
    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame) ApplySimpleStyle(frame) end)
end

local events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","PLAYER_TARGET_CHANGED","UNIT_FACTION","UNIT_FLAGS","UNIT_NAME_UPDATE","UNIT_TARGET","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_THREAT_LIST_UPDATE","UNIT_THREAT_SITUATION_UPDATE","GROUP_ROSTER_UPDATE","CVAR_UPDATE"}) do
    events:RegisterEvent(event)
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        DisableFriendlyClassColors()
        -- Ellesmere/Blizzard initialization can restore CVars shortly after login.
        C_Timer.After(1, function() DisableFriendlyClassColors(); RefreshAll() end)
        C_Timer.After(0.5, ShowNameplateConflictWarning)
        C_Timer.After(0, RefreshAll)
        return
    end
    if event == "CVAR_UPDATE" then
        for _, cvar in ipairs(FRIENDLY_COLOR_CVARS) do
            if unit == cvar then
                DisableFriendlyClassColors()
                RefreshAll()
                return
            end
        end
        return
    end
    if event == "NAME_PLATE_UNIT_ADDED" then
        RefreshUnit(unit)
        -- Blizzard can replace or recolor the name FontString during the next
        -- few frames. Reapply after those late initialization passes so a
        -- friendly name never remains white until mouseover.
        for _, delay in ipairs({ 0, 0.05, 0.20, 0.50 }) do
            C_Timer.After(delay, function() RefreshUnit(unit) end)
        end
        return
    end
    if event == "NAME_PLATE_UNIT_REMOVED" then
        local frame = GetUnitFrame(unit)
        if frame then
            if frame.name then frame.name:SetText("") end
            if frame.ESNPThreatText then frame.ESNPThreatText:SetText("") end
        end
        return
    end
    if event == "PLAYER_TARGET_CHANGED" or event == "GROUP_ROSTER_UPDATE" then RefreshAll(); return end
    if unit and tostring(unit):match("^nameplate%d+$") then RefreshUnit(unit)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then RefreshAll() end
end)

ns.RefreshAll = RefreshAll
