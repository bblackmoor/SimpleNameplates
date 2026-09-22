-- Simple Nameplates: unit classification, styling, and event handling.
-- Friendly units use colored names only; attackable states use white names
-- with colored full nameplates. Some world names are drawn by the engine and
-- are unavailable to addons.

local addon, ns = ...
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
local UnitExists = UnitExists
local UnitName = UnitName

local AccessibleNumber = ns.AccessibleNumber
local AccessibleBoolean = ns.AccessibleBoolean
local AccessibleValue = ns.AccessibleValue
local RelationshipColorForState = ns.RelationshipColorForState
local EffectColor = ns.EffectColor
local GetAppearanceSetting = ns.GetAppearanceSetting
local GetTRP3Setting = ns.GetTRP3Setting
local GetAttackingGlowEnabled = ns.GetAttackingGlowEnabled
local GetInterruptibleHighlightEnabled = ns.GetInterruptibleHighlightEnabled
local GetStylingEnabled = ns.GetStylingEnabled
local GetThreatEnabled = ns.GetThreatEnabled
local FontPath = ns.FontPath

local function UnitHasAggro(unitToken, hostileUnit)
    local threat = UnitThreatSituation(unitToken, hostileUnit)
    threat = AccessibleNumber(threat)
    return threat ~= nil and threat >= 2
end

local function HasAggroOnPlayerOrPet(unit)
    if UnitHasAggro("player", unit) or UnitHasAggro("pet", unit) then return true end
    return false
end

local function UnitMatches(unit1, unit2)
    return AccessibleBoolean(UnitIsUnit(unit1, unit2)) == true
end

local function TargetsPlayerControlledUnit(unit)
    local target = unit .. "target"
    if UnitMatches(target, "player") or UnitMatches(target, "pet") then return true end
    if UnitIsOwnerOrControllerOfUnit then
        return AccessibleBoolean(UnitIsOwnerOrControllerOfUnit("player", target)) == true
    end
    return false
end

local function IsAttackingPlayerControlledUnit(unit)
    return HasAggroOnPlayerOrPet(unit) or TargetsPlayerControlledUnit(unit)
end

local function IsPlayerControlledUnit(unit)
    if AccessibleBoolean(UnitIsPlayer(unit)) == true then return true end
    return AccessibleBoolean(UnitPlayerControlled(unit)) == true
end

local function OpposingPlayerState(unit)
    local canAttackThem = AccessibleBoolean(UnitCanAttack("player", unit))
    local canAttackUs = AccessibleBoolean(UnitCanAttack(unit, "player"))
    local combatAvailable = canAttackThem == true or canAttackUs == true

    if combatAvailable then
        if IsAttackingPlayerControlledUnit(unit) then
            return "attacking"
        end
        return "hostile"
    end

    if canAttackThem == false and canAttackUs == false then
        return "blizzardOverhead"
    end

    -- Attackability can be secret. PvP state is only a fallback and does not
    -- attempt to distinguish War Mode from ordinary PvP flagging.
    local pvp = AccessibleBoolean(UnitIsPVP(unit))
    if pvp == true and IsAttackingPlayerControlledUnit(unit) then
        return "attacking"
    end
    if pvp == true then return "hostile" end
    return "blizzardOverhead"
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

    -- Blizzard draws pets, guardians, totems, and minions as inaccessible
    -- overhead world text rather than addon-accessible nameplate text.
    if IsPlayerControlledUnit(unit) then
        return "blizzardOverhead"
    end

    if reaction and reaction >= 5 then return "friendlyNPC" end
    if IsAttackingPlayerControlledUnit(unit) then return "attacking" end
    if reaction == 4 then return "unfriendlyNPC" end
    if reaction then return "hostile" end

    local attackable = AccessibleBoolean(UnitCanAttack("player", unit))
    if attackable == true then return "hostile" end
    return "friendlyNPC"
end

local function IsNameOnlyState(state)
    return state == "friendlyNPC" or state == "friendlyPC"
end

local function GetUnitFrame(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    return plate and plate.UnitFrame or nil
end

local function GetHealthBar(frame)
    return frame and (frame.healthBar or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)) or nil
end

local function GetCastBar(frame)
    return frame and (frame.castBar or frame.CastBar) or nil
end

local function SetShownSafe(region, shown)
    if not region then return end
    if shown then region:Show() else region:Hide() end
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
    return fullTitle, displayName
end

local function EnsureFullTitleText(frame)
    if frame.SNPFullTitleText then return frame.SNPFullTitleText end
    -- Supply a template so the FontString is valid immediately, including
    -- during TRP3 callbacks that refresh a plate in the frame it is created.
    local fullTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fullTitle:SetJustifyH("LEFT")
    fullTitle:SetWordWrap(false)
    fullTitle:SetMaxLines(1)
    frame.SNPFullTitleText = fullTitle
    return fullTitle
end

local function StyleFullTitle(frame, state, text, baseNameSize)
    local fullTitle = frame.SNPFullTitleText
    -- Long titles are useful on name-only plates, but add too much visual
    -- noise to units whose health bars are visible.
    if not text or not IsNameOnlyState(state) then
        if fullTitle then fullTitle:SetText(""); fullTitle:Hide() end
        return
    end

    fullTitle = EnsureFullTitleText(frame)
    local titleSize = math.max(6, math.floor(baseNameSize * 0.8 + 0.5))
    fullTitle:SetFont(FontPath(GetAppearanceSetting("nameFont")), titleSize, "OUTLINE")
    fullTitle:SetText(text)
    fullTitle:SetShadowColor(0, 0, 0, 1)
    fullTitle:SetShadowOffset(1, -1)
    fullTitle:ClearAllPoints()
    fullTitle:SetPoint("TOP", frame.name, "BOTTOM", 0, -1)
    fullTitle:SetJustifyH("CENTER")
    fullTitle:SetTextColor(RelationshipColorForState(state))
    fullTitle:Show()
end

local function RestoreOriginalBarHeight(frame, bar)
    if not frame then return end
    if bar and frame.SNPOriginalBarHeight then
        bar:SetHeight(frame.SNPOriginalBarHeight)
    end
    local container = frame.HealthBarsContainer
    if container and frame.SNPOriginalHealthBarsContainerHeight then
        container:SetHeight(frame.SNPOriginalHealthBarsContainerHeight)
    end
    frame.SNPOriginalBarHeight = nil
    frame.SNPOriginalHealthBarsContainerHeight = nil
end

local function ApplyConfiguredBarHeight(frame, state, bar, baseNameSize)
    local inside = GetAppearanceSetting("namePlacement") == "INSIDE"
        and not IsNameOnlyState(state) and bar ~= nil
    if not inside then
        RestoreOriginalBarHeight(frame, bar)
        return false, baseNameSize
    end

    if not frame.SNPOriginalBarHeight then
        local originalHeight = bar:GetHeight()
        if type(originalHeight) == "number" and originalHeight > 0 then
            frame.SNPOriginalBarHeight = originalHeight
        end
    end
    local container = frame.HealthBarsContainer
    if container and not frame.SNPOriginalHealthBarsContainerHeight then
        local originalHeight = container:GetHeight()
        if type(originalHeight) == "number" and originalHeight > 0 then
            frame.SNPOriginalHealthBarsContainerHeight = originalHeight
        end
    end

    local insideNameSize = math.floor(baseNameSize * 0.8 + 0.5)
    local barHeight = insideNameSize + 4
    bar:SetHeight(barHeight)
    if container then container:SetHeight(barHeight) end
    return true, insideNameSize
end

local function StyleName(frame, state)
    local name = frame and frame.name
    if not name then return end
    local fullTitle, displayName = UpdateNameText(frame)

    local baseSize = GetAppearanceSetting("nameSize") or 12
    local bar = GetHealthBar(frame)
    local nameOnly = IsNameOnlyState(state)
    local inside, size = ApplyConfiguredBarHeight(frame, state, bar, baseSize)

    if nameOnly then
        name:ClearAllPoints()
        if bar then
            name:SetPoint("BOTTOM", bar, "TOP", 0, 2)
        else
            name:SetPoint("BOTTOM", frame, "TOP", 0, 2)
        end
        name:SetJustifyH("CENTER")
    elseif inside then
        local rightInset = GetThreatEnabled() and -42 or -3
        name:ClearAllPoints()
        name:SetPoint("LEFT", bar, "LEFT", 3, 0)
        name:SetPoint("RIGHT", bar, "RIGHT", rightInset, 0)
        name:SetJustifyH("LEFT")
    elseif bar then
        name:ClearAllPoints()
        name:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 2)
        name:SetJustifyH("LEFT")
    end

    local fontPath = FontPath(GetAppearanceSetting("nameFont"))
    name:SetFont(fontPath, size, "OUTLINE")
    name:SetShadowColor(0, 0, 0, 1)
    name:SetShadowOffset(1, -1)
    local nameR, nameG, nameB = 1, 1, 1
    if IsNameOnlyState(state) then nameR, nameG, nameB = RelationshipColorForState(state) end
    -- Blizzard also tints nameplate text with UnitSelectionColor through the
    -- FontString's vertex color. Keep that tint neutral so the configured
    -- Simple Nameplates color is displayed exactly.
    name:SetVertexColor(1, 1, 1, 1)
    name:SetTextColor(nameR, nameG, nameB, 1)
    name:Show()
    StyleFullTitle(frame, state, fullTitle, baseSize)

    local expected = frame.SNPNameStyle or {}
    frame.SNPNameStyle = expected
    expected.text = displayName
    expected.font = fontPath
    expected.size = size
    expected.flags = "OUTLINE"
    expected.r, expected.g, expected.b = nameR, nameG, nameB
    expected.nameOnly = nameOnly
    expected.inside = inside == true
    expected.rightInset = GetThreatEnabled() and -42 or -3
    expected.bar = bar
    expected.frame = frame
end

local function NearlyEqual(a, b)
    return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 0.001
end

local function CachedNameHasDrifted(frame)
    local name, expected = frame and frame.name, frame and frame.SNPNameStyle
    if not name or not expected then return false end
    -- FontString text can be a secret string in Midnight. Never read or compare
    -- it here; the secure Blizzard name-update hook and unit events repair text.
    local font, size, flags = name:GetFont()
    if font ~= expected.font or not NearlyEqual(size, expected.size) or flags ~= expected.flags then
        return true
    end
    if expected.inside and expected.bar
        and not NearlyEqual(expected.bar:GetHeight(), expected.size + 2) then
        return true
    end
    if expected.inside and frame.HealthBarsContainer
        and not NearlyEqual(frame.HealthBarsContainer:GetHeight(), expected.size + 2) then
        return true
    end

    local r, g, b = name:GetTextColor()
    if not NearlyEqual(r, expected.r) or not NearlyEqual(g, expected.g) or not NearlyEqual(b, expected.b) then
        return true
    end

    local rawVertexR, rawVertexG, rawVertexB, rawVertexA = name:GetVertexColor()
    local vertexR = AccessibleNumber(rawVertexR)
    local vertexG = AccessibleNumber(rawVertexG)
    local vertexB = AccessibleNumber(rawVertexB)
    local vertexA = AccessibleNumber(rawVertexA)
    if not NearlyEqual(vertexR, 1) or not NearlyEqual(vertexG, 1)
        or not NearlyEqual(vertexB, 1) or not NearlyEqual(vertexA, 1) then
        return true
    end

    return false
end

local function RepairCachedName(frame)
    local name, expected = frame and frame.name, frame and frame.SNPNameStyle
    if not name or not expected then return end
    name:SetText(expected.text)
    name:SetFont(expected.font, expected.size, expected.flags)
    name:SetShadowColor(0, 0, 0, 1)
    name:SetShadowOffset(1, -1)
    name:SetVertexColor(1, 1, 1, 1)
    name:SetTextColor(expected.r, expected.g, expected.b, 1)
    if expected.inside and expected.bar then
        expected.bar:SetHeight(expected.size + 2)
        if frame.HealthBarsContainer then frame.HealthBarsContainer:SetHeight(expected.size + 2) end
    end
    if expected.nameOnly then
        name:ClearAllPoints()
        if expected.bar then
            name:SetPoint("BOTTOM", expected.bar, "TOP", 0, 2)
        else
            name:SetPoint("BOTTOM", expected.frame, "TOP", 0, 2)
        end
    elseif expected.bar then
        name:ClearAllPoints()
        if expected.inside then
            name:SetPoint("LEFT", expected.bar, "LEFT", 3, 0)
            name:SetPoint("RIGHT", expected.bar, "RIGHT", expected.rightInset or -42, 0)
        else
            name:SetPoint("BOTTOMLEFT", expected.bar, "TOPLEFT", 0, 2)
        end
    end
    name:SetJustifyH(expected.nameOnly and "CENTER" or "LEFT")
    name:Show()
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
    local threatSize = 9
    if GetAppearanceSetting("namePlacement") == "INSIDE" then
        local baseNameSize = GetAppearanceSetting("nameSize") or 12
        threatSize = math.min(threatSize, math.floor(baseNameSize * 0.8 + 0.5))
    end
    threatText:SetFont(FontPath(GetAppearanceSetting("threatFont")), threatSize, "OUTLINE")
    if not GetThreatEnabled() then threatText:SetText(""); return end
    if IsNameOnlyState(state) then threatText:SetText(""); return end
    local _, _, scaled, raw = UnitDetailedThreatSituation("player", frame.unit)
    local percent = AccessibleNumber(raw) or AccessibleNumber(scaled)
    if percent then threatText:SetFormattedText("%.0f%%", percent) else threatText:SetText("") end
end

local function EnsureAttackingGlow(frame)
    local bar = GetHealthBar(frame)
    if not bar then return nil end
    if frame.SNPAttackingGlow and frame.SNPAttackingGlow.bar == bar then return frame.SNPAttackingGlow end

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
    frame.SNPAttackingGlow = glow
    return glow
end

local function UpdateGlowEdge(edge, shown, r, g, b)
    if shown then
        edge:SetColorTexture(r, g, b, 0.7)
        edge:Show()
    else
        edge:Hide()
    end
end

local function UpdateAttackingGlow(frame, state, r, g, b)
    local glow = frame.SNPAttackingGlow
    local shown = GetAttackingGlowEnabled() and state == "attacking"
    if shown then glow = EnsureAttackingGlow(frame) end
    if not glow then return end

    UpdateGlowEdge(glow.top, shown, r, g, b)
    UpdateGlowEdge(glow.bottom, shown, r, g, b)
    UpdateGlowEdge(glow.left, shown, r, g, b)
    UpdateGlowEdge(glow.right, shown, r, g, b)
end

local function SetInterruptibleHighlightShown(overlay, shown)
    if not overlay then return end
    local ok = pcall(overlay.SetShown, overlay, shown)
    if not ok then overlay:Hide() end
end

local function InstallInterruptibleHighlightHook(highlight)
    local icon = highlight and highlight.castBar and highlight.castBar.Icon
    if not icon then return false end
    if highlight.hookedIcon == icon then return true end

    local overlay = highlight.frame
    local ok = pcall(hooksecurefunc, icon, "SetShown", function(_, shown)
        if GetStylingEnabled() and GetInterruptibleHighlightEnabled() then
            SetInterruptibleHighlightShown(overlay, shown)
        else
            overlay:Hide()
        end
    end)
    if ok then highlight.hookedIcon = icon end
    return ok
end

local function EnsureInterruptibleHighlight(frame)
    local castBar = GetCastBar(frame)
    if not castBar then return nil end
    local existing = frame.SNPInterruptibleHighlight
    if existing and existing.castBar == castBar then
        InstallInterruptibleHighlightHook(existing)
        return existing
    end
    if existing and existing.frame then existing.frame:Hide() end

    local overlay = CreateFrame("Frame", nil, castBar)
    overlay:SetPoint("TOPLEFT", castBar, "TOPLEFT", -3, 3)
    overlay:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 3, -3)
    local healthBar = GetHealthBar(frame)
    local highestFrameLevel = castBar:GetFrameLevel()
    if healthBar then highestFrameLevel = math.max(highestFrameLevel, healthBar:GetFrameLevel()) end
    overlay:SetFrameLevel(highestFrameLevel + 20)
    overlay:Hide()

    local function CreateEdge()
        local edge = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
        edge:SetColorTexture(0, 1, 1, 0.9)
        edge:SetBlendMode("ADD")
        return edge
    end

    local highlight = {
        castBar = castBar,
        frame = overlay,
        top = CreateEdge(),
        bottom = CreateEdge(),
        left = CreateEdge(),
        right = CreateEdge(),
    }
    highlight.top:SetPoint("TOPLEFT")
    highlight.top:SetPoint("TOPRIGHT")
    highlight.top:SetHeight(3)
    highlight.bottom:SetPoint("BOTTOMLEFT")
    highlight.bottom:SetPoint("BOTTOMRIGHT")
    highlight.bottom:SetHeight(3)
    highlight.left:SetPoint("TOPLEFT")
    highlight.left:SetPoint("BOTTOMLEFT")
    highlight.left:SetWidth(3)
    highlight.right:SetPoint("TOPRIGHT")
    highlight.right:SetPoint("BOTTOMRIGHT")
    highlight.right:SetWidth(3)
    frame.SNPInterruptibleHighlight = highlight

    -- Blizzard already makes the secret-safe interruptibility decision and
    -- shows the ordinary spell icon only for interruptible modern nameplate
    -- casts. Mirror that resulting visibility without inspecting the secret.
    InstallInterruptibleHighlightHook(highlight)

    return highlight
end

local function UpdateInterruptibleHighlight(frame)
    local highlight = EnsureInterruptibleHighlight(frame)
    if not highlight then return end

    local r, g, b = EffectColor("interruptible")
    highlight.top:SetColorTexture(r, g, b, 0.9)
    highlight.bottom:SetColorTexture(r, g, b, 0.9)
    highlight.left:SetColorTexture(r, g, b, 0.9)
    highlight.right:SetColorTexture(r, g, b, 0.9)

    if not GetInterruptibleHighlightEnabled() then
        highlight.frame:Hide()
        return
    end

    local icon = highlight.castBar and highlight.castBar.Icon
    if not icon then highlight.frame:Hide(); return end
    local ok, shown = pcall(icon.IsShown, icon)
    if ok then SetInterruptibleHighlightShown(highlight.frame, shown) end
end

local function ApplyVisibility(frame, state)
    local nameOnly = IsNameOnlyState(state)
    local bar = GetHealthBar(frame)
    SetShownSafe(bar, not nameOnly)
    -- Do not hide HealthBarsContainer itself. Some Blizzard friendly-player
    -- layouts attach or otherwise couple the name to that container, so a
    -- visible FontString can still disappear when its ancestor is hidden.
    SetShownSafe(frame.HealthBarsContainer, true)
    SetShownSafe(frame.castBar, not nameOnly)
    SetShownSafe(frame.CastBar, not nameOnly)
    SetShownSafe(frame.castBarAnchor, not nameOnly)
    SetShownSafe(frame.classificationIndicator, not nameOnly)
    SetShownSafe(frame.ClassificationFrame, not nameOnly)
    SetShownSafe(frame.selectionHighlight, not nameOnly)
end

local function ApplySimpleStyle(frame)
    if not GetStylingEnabled() then return end
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    local state = StateForUnit(frame.unit)
    frame.SNPState = state
    if state == "blizzardOverhead" then
        RestoreOriginalBarHeight(frame, GetHealthBar(frame))
        return
    end
    local r, g, b = RelationshipColorForState(state)
    local bar = GetHealthBar(frame)
    ApplyVisibility(frame, state)
    StyleName(frame, state)
    if not IsNameOnlyState(state) and bar then
        bar:SetStatusBarColor(r, g, b, 1)
        UpdateThreatText(frame, state)
    elseif frame.SNPThreatText then
        frame.SNPThreatText:SetText("")
    end
    UpdateAttackingGlow(frame, state, r, g, b)
    UpdateInterruptibleHighlight(frame)
end

local function RepairHealthColor(frame)
    if not GetStylingEnabled() then return end
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    local state = frame.SNPState or StateForUnit(frame.unit)
    frame.SNPState = state
    if state == "blizzardOverhead" then
        RestoreOriginalBarHeight(frame, GetHealthBar(frame))
        return
    end
    local r, g, b = RelationshipColorForState(state)
    local bar = GetHealthBar(frame)
    ApplyConfiguredBarHeight(frame, state, bar, GetAppearanceSetting("nameSize") or 12)
    ApplyVisibility(frame, state)
    if not IsNameOnlyState(state) and bar then
        bar:SetStatusBarColor(r, g, b, 1)
    end
    UpdateAttackingGlow(frame, state, r, g, b)
    UpdateInterruptibleHighlight(frame)
end

local function RepairName(frame)
    if not GetStylingEnabled() then return end
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    local state = frame.SNPState or StateForUnit(frame.unit)
    frame.SNPState = state
    if state == "blizzardOverhead" then return end
    StyleName(frame, state)
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
    if not GetStylingEnabled() then return end
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if plate.UnitFrame then ApplySimpleStyle(plate.UnitFrame) end
    end
end

local function RestoreFrame(frame)
    if not frame then return end
    if frame.SNPThreatText then frame.SNPThreatText:SetText("") end
    if frame.SNPFullTitleText then frame.SNPFullTitleText:SetText(""); frame.SNPFullTitleText:Hide() end
    if frame.SNPAttackingGlow then UpdateAttackingGlow(frame, "", 1, 1, 1) end
    if frame.SNPInterruptibleHighlight then frame.SNPInterruptibleHighlight.frame:Hide() end
    frame.SNPNameStyle = nil
    frame.SNPState = nil
    RestoreOriginalBarHeight(frame, GetHealthBar(frame))

    -- Restore anything hidden by name-only styling before asking Blizzard to
    -- rebuild the frame according to its own current settings.
    SetShownSafe(GetHealthBar(frame), true)
    SetShownSafe(frame.HealthBarsContainer, true)
    if CompactUnitFrame_UpdateAll then
        CompactUnitFrame_UpdateAll(frame)
    else
        if CompactUnitFrame_UpdateName then CompactUnitFrame_UpdateName(frame) end
        if CompactUnitFrame_UpdateHealthColor then CompactUnitFrame_UpdateHealthColor(frame) end
    end
end

local function RestoreAll()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if plate.UnitFrame then RestoreFrame(plate.UnitFrame) end
    end
end

if hooksecurefunc and CompactUnitFrame_UpdateHealthColor then
    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", RepairHealthColor)
end

-- Blizzard recolors the name FontString in its name update path, which occurs
-- after NAME_PLATE_UNIT_ADDED in several situations (mounting, range changes,
-- recycled plates, etc.). Reapply our configured color after Blizzard finishes that pass.
if hooksecurefunc and CompactUnitFrame_UpdateName then
    hooksecurefunc("CompactUnitFrame_UpdateName", RepairName)
end

local events = CreateFrame("Frame")
for _, event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","PLAYER_TARGET_CHANGED","UNIT_FACTION","UNIT_FLAGS","UNIT_NAME_UPDATE","UNIT_TARGET","UNIT_THREAT_LIST_UPDATE","UNIT_THREAT_SITUATION_UPDATE","CVAR_UPDATE"}) do
    events:RegisterEvent(event)
end

local dirtyUnits = {}
local refreshAllQueued = false

local function QueueUnitRefresh(unit)
    if unit and tostring(unit):match("^nameplate%d+$") then dirtyUnits[unit] = true end
end

local function QueueRefreshAll()
    refreshAllQueued = true
end

local function FlushQueuedRefreshes()
    if refreshAllQueued then
        refreshAllQueued = false
        wipe(dirtyUnits)
        RefreshAll()
        return
    end
    for unit in pairs(dirtyUnits) do
        dirtyUnits[unit] = nil
        RefreshUnit(unit)
    end
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "ADDON_LOADED" then
        if unit ~= addon then return end
        events:UnregisterEvent("ADDON_LOADED")
        ns.EnsureDB()
        return
    end
    if event == "PLAYER_LOGIN" then
        ns.EnsureDB()
        ns.ApplyBlizzardMinionNameVisibility()
        ns.ApplyCritterCompanionNameVisibility()
        C_Timer.After(1, function()
            if ns.GetHideBlizzardMinionNames() then
                ns.ApplyBlizzardMinionNameVisibility()
            end
            if ns.GetHideCritterCompanionNames() then
                ns.ApplyCritterCompanionNameVisibility()
            end
        end)
        if ns.RegisterSettingsPanel then ns.RegisterSettingsPanel() end
        if ns.TRP3 and ns.TRP3.RegisterCallbacks then ns.TRP3.RegisterCallbacks() end
        if GetStylingEnabled() then
            ns.DisableFriendlyClassColors()
            -- Blizzard or another addon can restore CVars shortly after login.
            C_Timer.After(1, function()
                if GetStylingEnabled() then
                    ns.DisableFriendlyClassColors()
                    RefreshAll()
                end
            end)
            C_Timer.After(0.5, ns.ShowNameplateConflictWarning)
            C_Timer.After(0, RefreshAll)
        end
        return
    end
    if event == "CVAR_UPDATE" then
        if ns.GetHideBlizzardMinionNames() then
            for _, cvar in ipairs(ns.BLIZZARD_MINION_NAME_CVARS) do
                if unit == cvar then
                    ns.ApplyBlizzardMinionNameVisibility()
                    return
                end
            end
        end
        if ns.GetHideCritterCompanionNames() then
            for _, cvar in ipairs(ns.BLIZZARD_CRITTER_COMPANION_NAME_CVARS) do
                if unit == cvar then
                    ns.ApplyCritterCompanionNameVisibility()
                    return
                end
            end
        end
        if not GetStylingEnabled() then return end
        for _, cvar in ipairs(ns.FRIENDLY_COLOR_CVARS) do
            if unit == cvar then
                ns.DisableFriendlyClassColors()
                QueueRefreshAll()
                return
            end
        end
        return
    end
    if not GetStylingEnabled() then return end
    if event == "NAME_PLATE_UNIT_ADDED" then
        RefreshUnit(unit)
        -- One delayed pass covers late nameplate initialization; the Blizzard
        -- hooks and cached drift check handle subsequent changes.
        C_Timer.After(0.50, function() RefreshUnit(unit) end)
        return
    end
    if event == "NAME_PLATE_UNIT_REMOVED" then
        local frame = GetUnitFrame(unit)
        if frame then
            RestoreOriginalBarHeight(frame, GetHealthBar(frame))
            if frame.name then frame.name:SetText("") end
            if frame.SNPThreatText then frame.SNPThreatText:SetText("") end
            if frame.SNPFullTitleText then frame.SNPFullTitleText:SetText(""); frame.SNPFullTitleText:Hide() end
            frame.SNPNameStyle = nil
            frame.SNPState = nil
            UpdateAttackingGlow(frame, "", 1, 1, 1)
            if frame.SNPInterruptibleHighlight then frame.SNPInterruptibleHighlight.frame:Hide() end
        end
        dirtyUnits[unit] = nil
        return
    end
    if event == "PLAYER_TARGET_CHANGED" then QueueRefreshAll(); return end
    if unit and tostring(unit):match("^nameplate%d+$") then QueueUnitRefresh(unit)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then QueueRefreshAll() end
end)

-- Blizzard sometimes changes name text, font, or color without calling either
-- compact unit-frame update path. Compare safe cached properties twice per
-- second and write only when something has drifted. Avoid point inspection on
-- Blizzard frames; hooks handle placement changes. Classification, TRP3
-- profile access, threat checks, and health-bar styling remain event-driven.
local reconcileElapsed = 0
events:SetScript("OnUpdate", function(_, elapsed)
    if not GetStylingEnabled() then return end
    FlushQueuedRefreshes()
    reconcileElapsed = reconcileElapsed + elapsed
    if reconcileElapsed < 0.50 then return end
    reconcileElapsed = 0

    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = plate.UnitFrame
        if frame and frame.SNPState and CachedNameHasDrifted(frame) then
            RepairCachedName(frame)
        end
    end
end)

local function DebugBoolean(value)
    value = AccessibleBoolean(value)
    if value == nil then return "restricted/unavailable" end
    return value and "yes" or "no"
end

local function DebugValue(value)
    value = AccessibleValue(value)
    return value == nil and "restricted/unavailable" or tostring(value)
end

local function DebugRegionValue(region, methodName, valueType)
    if not region then return "not found" end
    local method = region[methodName]
    if type(method) ~= "function" then return "unavailable" end
    local ok, value = pcall(method, region)
    if not ok then return "unavailable" end

    if valueType == "boolean" then
        value = AccessibleBoolean(value)
        if value == nil then return "restricted/unavailable" end
        return value and "yes" or "no"
    end

    return DebugValue(value)
end

local function DebugUnit(unit)
    if AccessibleBoolean(UnitExists(unit)) ~= true then
        print("|cff0cd29fSimple Nameplates:|r No target selected.")
        return
    end

    local name = DebugValue(UnitName(unit))
    local state = StateForUnit(unit)
    local reaction = AccessibleNumber(UnitReaction(unit, "player"))
    local hasNameplate = GetUnitFrame(unit) ~= nil
    local display, colorHex
    if state == "blizzardOverhead" then
        display = "Blizzard-controlled overhead name"
        colorHex = "engine-controlled"
    else
        local r, g, b = RelationshipColorForState(state)
        colorHex = string.format("#%02X%02X%02X", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
        display = IsNameOnlyState(state) and "colored name only" or "white name with colored health bar"
    end

    print("|cff0cd29fSimple Nameplates debug:|r " .. name)
    print("  Styling enabled: " .. (GetStylingEnabled() and "yes" or "no")
        .. "; nameplate frame: " .. (hasNameplate and "yes" or "no")
        .. "; detected state: " .. state .. "; display: " .. display .. "; color: " .. colorHex)
    print("  Player: " .. DebugBoolean(UnitIsPlayer(unit))
        .. "; player-controlled: " .. DebugBoolean(UnitPlayerControlled(unit))
        .. "; owned/controlled by you: " .. DebugBoolean(UnitIsOwnerOrControllerOfUnit and UnitIsOwnerOrControllerOfUnit("player", unit)))
    print("  Reaction: " .. (reaction and tostring(reaction) or "restricted/unavailable")
        .. "; faction: " .. DebugValue(UnitFactionGroup(unit))
        .. "; you can attack: " .. DebugBoolean(UnitCanAttack("player", unit))
        .. "; it can attack you: " .. DebugBoolean(UnitCanAttack(unit, "player"))
        .. "; PvP flagged: " .. DebugBoolean(UnitIsPVP(unit)))
    print("  Threat on you: " .. DebugValue(UnitThreatSituation("player", unit))
        .. "; threat on pet: " .. DebugValue(UnitThreatSituation("pet", unit))
        .. "; targeting your controlled unit: " .. (TargetsPlayerControlledUnit(unit) and "yes" or "no"))

    local unitFrame = GetUnitFrame(unit)
    local nameRegion = unitFrame and unitFrame.name or nil
    local nameParent = nameRegion and nameRegion.GetParent and nameRegion:GetParent() or nil
    print("  Name region: " .. (nameRegion and "found" or "not found")
        .. "; text: " .. DebugRegionValue(nameRegion, "GetText")
        .. "; shown: " .. DebugRegionValue(nameRegion, "IsShown", "boolean")
        .. "; visible: " .. DebugRegionValue(nameRegion, "IsVisible", "boolean")
        .. "; alpha: " .. DebugRegionValue(nameRegion, "GetAlpha"))
    print("  Name parent: " .. (nameParent and "found" or "not found")
        .. "; shown: " .. DebugRegionValue(nameParent, "IsShown", "boolean")
        .. "; visible: " .. DebugRegionValue(nameParent, "IsVisible", "boolean")
        .. "; alpha: " .. DebugRegionValue(nameParent, "GetAlpha"))
    local castBar = GetCastBar(unitFrame)
    local highlight = unitFrame and EnsureInterruptibleHighlight(unitFrame) or nil
    local icon = castBar and castBar.Icon or nil
    local highlightShown = false
    if highlight and highlight.frame then
        local ok, shown = pcall(highlight.frame.IsShown, highlight.frame)
        highlightShown = ok and shown == true
    end
    print("  Interruptible highlight: enabled "
        .. (GetInterruptibleHighlightEnabled() and "yes" or "no")
        .. "; cast bar found " .. (castBar and "yes" or "no")
        .. "; cast icon found " .. (icon and "yes" or "no")
        .. "; hook installed " .. (highlight and highlight.hookedIcon == icon and icon ~= nil and "yes" or "no")
        .. "; highlight shown " .. (highlightShown and "yes" or "no"))
end

ns.RefreshAll = RefreshAll
ns.RestoreAll = RestoreAll
ns.DebugUnit = DebugUnit
ns.StateForUnit = StateForUnit
