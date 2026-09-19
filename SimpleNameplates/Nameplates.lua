-- Simple Nameplates: unit classification, styling, and event handling.
-- Friendly units and unattackable opposite-faction players use colored names
-- only; attackable states use white names with colored full nameplates.

local _, ns = ...
if not ns.EnsureDB then return end

local C_NamePlate = C_NamePlate
local UnitCanAttack = UnitCanAttack
local UnitFactionGroup = UnitFactionGroup
local UnitIsPlayer = UnitIsPlayer
local UnitIsOwnerOrControllerOfUnit = UnitIsOwnerOrControllerOfUnit
local UnitIsPVP = UnitIsPVP
local UnitIsUnit = UnitIsUnit
local UnitPlayerControlled = UnitPlayerControlled
local UnitReaction = UnitReaction
local UnitThreatSituation = UnitThreatSituation
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitName = UnitName

local AccessibleNumber = ns.AccessibleNumber
local AccessibleBoolean = ns.AccessibleBoolean
local AccessibleValue = ns.AccessibleValue
local ColorForState = ns.ColorForState
local GetAppearanceSetting = ns.GetAppearanceSetting
local GetTRP3Setting = ns.GetTRP3Setting
local GetPCGlowEnabled = ns.GetPCGlowEnabled
local FontPath = ns.FontPath

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

local function UnitMatches(unit1, unit2)
    return AccessibleBoolean(UnitIsUnit(unit1, unit2)) == true
end

local function TargetsOurGroup(unit)
    local target = unit .. "target"
    if UnitMatches(target, "player") or UnitMatches(target, "pet") then return true end
    for i = 1, 4 do
        if UnitMatches(target, "party" .. i) or UnitMatches(target, "partypet" .. i) then return true end
    end
    for i = 1, 40 do
        if UnitMatches(target, "raid" .. i) or UnitMatches(target, "raidpet" .. i) then return true end
    end
    return false
end

local function IsPlayerControlledUnit(unit)
    if AccessibleBoolean(UnitIsPlayer(unit)) == true then return true end
    return AccessibleBoolean(UnitPlayerControlled(unit)) == true
end

local function IsOwnedOrControlledByPlayer(unit)
    if not UnitIsOwnerOrControllerOfUnit then return false end
    return AccessibleBoolean(UnitIsOwnerOrControllerOfUnit("player", unit)) == true
end

local function OpposingPlayerState(unit)
    local canAttackThem = AccessibleBoolean(UnitCanAttack("player", unit))
    local canAttackUs = AccessibleBoolean(UnitCanAttack(unit, "player"))
    local combatAvailable = canAttackThem == true or canAttackUs == true

    if combatAvailable then
        if HasAggroOnOurGroup(unit) or TargetsOurGroup(unit) then
            return "attackingPC"
        end
        return "attackablePC"
    end

    if canAttackThem == false and canAttackUs == false then
        return "unfriendlyPC"
    end

    -- Attackability can be secret. PvP state is only a fallback and does not
    -- attempt to distinguish War Mode from ordinary PvP flagging.
    local pvp = AccessibleBoolean(UnitIsPVP(unit))
    if pvp == true and (HasAggroOnOurGroup(unit) or TargetsOurGroup(unit)) then
        return "attackingPC"
    end
    if pvp == true then return "attackablePC" end
    if pvp == false then return "unfriendlyPC" end
    return "unfriendlyPC"
end

local function StateForUnit(unit)
    local reaction = AccessibleNumber(UnitReaction(unit, "player"))

    if AccessibleBoolean(UnitIsPlayer(unit)) == true then
        local playerFaction = AccessibleValue(UnitFactionGroup("player"))
        local unitFaction = AccessibleValue(UnitFactionGroup(unit))
        if playerFaction and unitFaction then
            if playerFaction == unitFaction then return "friendlyPC" end
            return OpposingPlayerState(unit)
        end

        -- If faction information is restricted, retain reaction as the safest
        -- available same-side signal.
        if reaction and reaction >= 5 then return "friendlyPC" end
        return OpposingPlayerState(unit)
    end

    -- Some temporary guardians do not report a useful reaction. Explicitly
    -- recognize the player's own pets, guardians, minions, and vehicles first.
    if IsOwnedOrControlledByPlayer(unit) then return "friendlyPC" end

    -- Other player-controlled units follow the player-side color language
    -- instead of being mistaken for ordinary NPCs.
    if IsPlayerControlledUnit(unit) then
        if reaction and reaction >= 5 then return "friendlyPC" end
        return OpposingPlayerState(unit)
    end

    if reaction and reaction >= 5 then return "friendlyNPC" end
    if HasAggroOnOurGroup(unit) then return "attackingNPC" end
    if reaction == 4 then return "unfriendlyNPC" end
    if reaction then return "hostileNPC" end

    local attackable = AccessibleBoolean(UnitCanAttack("player", unit))
    if attackable == true then return "hostileNPC" end
    return "friendlyNPC"
end

local function IsNameOnlyState(state)
    return state == "friendlyNPC" or state == "friendlyPC" or state == "unfriendlyPC"
end

local function IsPCState(state)
    return state == "friendlyPC" or state == "unfriendlyPC"
        or state == "attackablePC" or state == "attackingPC"
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
    if not name or not unit then return nil end
    local unitName = AccessibleValue(UnitName(unit))
    local displayName = unitName or ""
    local fullTitle
    local info = ns.TRP3 and ns.TRP3.GetDisplayInfo(unit)

    if info then
        if GetTRP3Setting("useRoleplayingName") and info.roleplayingName then
            displayName = info.roleplayingName
        end

        local prefix
        if GetTRP3Setting("showOOC") and info.isOutOfCharacter then
            prefix = "[OOC]"
        elseif GetTRP3Setting("showShortTitle") then
            prefix = info.shortTitle
        end
        if prefix then displayName = prefix .. " " .. displayName end

        if GetTRP3Setting("showFullTitle") then fullTitle = info.fullTitle end
    end

    name:SetText(displayName)
    return fullTitle
end

local function EnsureFullTitleText(frame)
    if frame.SNPFullTitleText then return frame.SNPFullTitleText end
    local fullTitle = frame:CreateFontString(nil, "OVERLAY")
    fullTitle:SetJustifyH("LEFT")
    fullTitle:SetWordWrap(false)
    fullTitle:SetMaxLines(1)
    frame.SNPFullTitleText = fullTitle
    return fullTitle
end

local function StyleFullTitle(frame, state, text, nameInsideBar, baseNameSize, bar)
    local fullTitle = frame.SNPFullTitleText
    if not text then
        if fullTitle then fullTitle:SetText(""); fullTitle:Hide() end
        return
    end

    fullTitle = EnsureFullTitleText(frame)
    fullTitle:SetText(text)
    fullTitle:SetFont(FontPath(GetAppearanceSetting("nameFont")), math.max(6, baseNameSize - 1), "OUTLINE")
    fullTitle:SetShadowColor(0, 0, 0, 1)
    fullTitle:SetShadowOffset(1, -1)
    fullTitle:ClearAllPoints()
    if nameInsideBar and bar then
        fullTitle:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 2)
    else
        fullTitle:SetPoint("BOTTOMLEFT", frame.name, "TOPLEFT", 0, 1)
    end
    if IsNameOnlyState(state) then
        fullTitle:SetTextColor(ColorForState(state))
    else
        fullTitle:SetTextColor(1, 1, 1, 1)
    end
    fullTitle:Show()
end

local function StyleName(frame, state)
    local name = frame and frame.name
    if not name then return end
    local fullTitle = UpdateNameText(frame)

    local _, currentSize = name:GetFont()
    if not frame.SNPBaseNameSize and type(currentSize) == "number" then
        frame.SNPBaseNameSize = currentSize
    end
    local baseSize = frame.SNPBaseNameSize or currentSize or 10
    local size = baseSize
    local bar = GetHealthBar(frame)
    local inside = GetAppearanceSetting("namePlacement") == "INSIDE"
        and not IsNameOnlyState(state) and bar

    if inside then
        local barHeight = bar:GetHeight()
        if type(barHeight) == "number" and barHeight > 0 then
            size = math.max(6, math.min(size, math.floor(barHeight - 2)))
        else
            size = math.min(size, 9)
        end
        name:ClearAllPoints()
        name:SetPoint("LEFT", bar, "LEFT", 3, 0)
        name:SetPoint("RIGHT", bar, "RIGHT", -42, 0)
        name:SetJustifyH("LEFT")
    elseif bar then
        name:ClearAllPoints()
        name:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 2)
        name:SetJustifyH("LEFT")
    end

    name:SetFont(FontPath(GetAppearanceSetting("nameFont")), size, "OUTLINE")
    name:SetShadowColor(0, 0, 0, 1)
    name:SetShadowOffset(1, -1)
    if IsNameOnlyState(state) then
        local r, g, b = ColorForState(state)
        name:SetTextColor(r, g, b, 1)
    else
        name:SetTextColor(1, 1, 1, 1)
    end
    name:Show()
    StyleFullTitle(frame, state, fullTitle, inside, baseSize, bar)
end

local function EnsureThreatText(frame)
    if frame.SNPThreatText then return frame.SNPThreatText end
    local bar = GetHealthBar(frame)
    if not bar then return nil end
    local threatText = bar:CreateFontString(nil, "OVERLAY")
    threatText:SetPoint("RIGHT", bar, "RIGHT", -3, 0)
    threatText:SetJustifyH("RIGHT")
    threatText:SetTextColor(1, 1, 1, 1)
    frame.SNPThreatText = threatText
    return threatText
end

local function UpdateThreatText(frame, state)
    local threatText = EnsureThreatText(frame)
    if not threatText then return end
    threatText:SetFont(FontPath(GetAppearanceSetting("threatFont")), 9, "OUTLINE")
    if IsNameOnlyState(state) then threatText:SetText(""); return end
    local _, _, scaled, raw = UnitDetailedThreatSituation("player", frame.unit)
    local percent = AccessibleNumber(raw) or AccessibleNumber(scaled)
    if percent then threatText:SetFormattedText("%.0f%%", percent) else threatText:SetText("") end
end

local function EnsurePCGlow(frame)
    local bar = GetHealthBar(frame)
    if not bar then return nil end
    if frame.SNPPCGlow and frame.SNPPCGlow.bar == bar then return frame.SNPPCGlow end

    local function CreateEdge()
        local edge = bar:CreateTexture(nil, "OVERLAY")
        edge:SetColorTexture(1, 1, 1, 0.7)
        edge:SetBlendMode("ADD")
        edge:Hide()
        return edge
    end

    local glow = {
        bar = bar,
        top = CreateEdge(),
        bottom = CreateEdge(),
        left = CreateEdge(),
        right = CreateEdge(),
    }
    glow.top:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", -2, -1)
    glow.top:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 2, -1)
    glow.top:SetHeight(3)
    glow.bottom:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", -2, 1)
    glow.bottom:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 2, 1)
    glow.bottom:SetHeight(3)
    glow.left:SetPoint("TOPRIGHT", bar, "TOPLEFT", 1, 2)
    glow.left:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", 1, -2)
    glow.left:SetWidth(3)
    glow.right:SetPoint("TOPLEFT", bar, "TOPRIGHT", -1, 2)
    glow.right:SetPoint("BOTTOMLEFT", bar, "BOTTOMRIGHT", -1, -2)
    glow.right:SetWidth(3)
    frame.SNPPCGlow = glow
    return glow
end

local function UpdatePCGlow(frame, state, r, g, b)
    local glow = frame.SNPPCGlow
    local shown = GetPCGlowEnabled() and IsPCState(state) and not IsNameOnlyState(state)
    if shown then glow = EnsurePCGlow(frame) end
    if not glow then return end

    for _, edge in ipairs({glow.top, glow.bottom, glow.left, glow.right}) do
        if shown then
            edge:SetColorTexture(r, g, b, 0.7)
            edge:Show()
        else
            edge:Hide()
        end
    end
end

local function ApplyVisibility(frame, state)
    local nameOnly = IsNameOnlyState(state)
    local bar = GetHealthBar(frame)
    SetShownSafe(bar, not nameOnly)
    SetShownSafe(frame.HealthBarsContainer, not nameOnly)
    SetShownSafe(frame.castBar, not nameOnly)
    SetShownSafe(frame.CastBar, not nameOnly)
    SetShownSafe(frame.castBarAnchor, not nameOnly)
    SetShownSafe(frame.classificationIndicator, not nameOnly)
    SetShownSafe(frame.ClassificationFrame, not nameOnly)
    SetShownSafe(frame.selectionHighlight, not nameOnly)
end

local function ApplySimpleStyle(frame)
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    local state = StateForUnit(frame.unit)
    frame.SNPState = state
    local r, g, b = ColorForState(state)
    local bar = GetHealthBar(frame)
    ApplyVisibility(frame, state)
    StyleName(frame, state)
    if not IsNameOnlyState(state) and bar then
        UpdateHealthValue(frame)
        bar:SetStatusBarColor(r, g, b, 1)
        UpdateThreatText(frame, state)
    elseif frame.SNPThreatText then
        frame.SNPThreatText:SetText("")
    end
    UpdatePCGlow(frame, state, r, g, b)
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
-- recycled plates, etc.). Reapply our configured color after Blizzard finishes that pass.
if hooksecurefunc and CompactUnitFrame_UpdateName then
    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame) ApplySimpleStyle(frame) end)
end

local events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","PLAYER_TARGET_CHANGED","UNIT_FACTION","UNIT_FLAGS","UNIT_NAME_UPDATE","UNIT_TARGET","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_THREAT_LIST_UPDATE","UNIT_THREAT_SITUATION_UPDATE","GROUP_ROSTER_UPDATE","CVAR_UPDATE"}) do
    events:RegisterEvent(event)
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        ns.EnsureDB()
        if ns.RegisterSettingsPanel then ns.RegisterSettingsPanel() end
        ns.DisableFriendlyClassColors()
        -- Blizzard or another addon can restore CVars shortly after login.
        C_Timer.After(1, function() ns.DisableFriendlyClassColors(); RefreshAll() end)
        C_Timer.After(0.5, ns.ShowNameplateConflictWarning)
        C_Timer.After(0, RefreshAll)
        return
    end
    if event == "CVAR_UPDATE" then
        for _, cvar in ipairs(ns.FRIENDLY_COLOR_CVARS) do
            if unit == cvar then
                ns.DisableFriendlyClassColors()
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
            if frame.SNPThreatText then frame.SNPThreatText:SetText("") end
            if frame.SNPFullTitleText then frame.SNPFullTitleText:SetText(""); frame.SNPFullTitleText:Hide() end
            UpdatePCGlow(frame, "", 1, 1, 1)
        end
        return
    end
    if event == "PLAYER_TARGET_CHANGED" or event == "GROUP_ROSTER_UPDATE" then RefreshAll(); return end
    if unit and tostring(unit):match("^nameplate%d+$") then RefreshUnit(unit)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then RefreshAll() end
end)

-- Blizzard sometimes changes name font or placement without calling either
-- compact unit-frame update path. Repair cached names only; classification,
-- threat scans, and health-bar styling remain event-driven.
local reconcileElapsed = 0
events:SetScript("OnUpdate", function(_, elapsed)
    reconcileElapsed = reconcileElapsed + elapsed
    if reconcileElapsed < 0.20 then return end
    reconcileElapsed = 0

    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = plate.UnitFrame
        if frame and frame.SNPState then
            StyleName(frame, frame.SNPState)
        end
    end
end)

ns.RefreshAll = RefreshAll
ns.StateForUnit = StateForUnit
