-- Simple Nameplates: unit names, TRP3 titles, layout, and cached text repair.
local _, ns = ...
local CanAccessFrame = ns.PresentationCapabilities.CanAccessFrame
local GetContext = ns.WorldContext.Get
local AccessibleBoolean = ns.AccessibleBoolean
local UnitName = UnitName
local AccessibleNumber, AccessibleValue = ns.AccessibleNumber, ns.AccessibleValue
local PriorityColorForState, FontPath = ns.PriorityColorForState, ns.FontPath
local GetAppearanceSetting, GetTRP3Setting = ns.GetAppearanceSetting, ns.GetTRP3Setting
local GetThreatEnabled = ns.GetThreatEnabled
local GetHealthBar = ns.NameplateFrames.GetHealthBar

local function NameFontPath(context)
    if context.sanctuary == true and GetAppearanceSetting("matchSanctuaryFont") == true then
        -- The engine's world-label font family is localized by Blizzard.
        -- Read only its face: preserve the profile's size and our outline/layout.
        if SystemFont_World and type(SystemFont_World.GetFont) == "function" then
            local ok, path = pcall(SystemFont_World.GetFont, SystemFont_World)
            if ok then
                path = AccessibleValue(path)
                if type(path) == "string" and path ~= "" then return path end
            end
        end
        return FontPath("FRIZQT")
    end
    return FontPath(GetAppearanceSetting("nameFont"))
end

local function UpdateNameText(frame)
    local name, unit = frame and frame.name, frame and frame.unit
    if not name or not unit then return nil end
    -- UnitName can be secret in Midnight. FontString:SetText can display that
    -- value directly; do not replace it with an empty string.
    local unitName = UnitName(unit)
    local displayName = unitName
    local fullTitle = frame.SNPEntityFacts and frame.SNPEntityFacts.npcTitle
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
        -- Lua cannot concatenate a secret unit name. Retain the raw name
        -- when it is restricted; a readable TRP3 name can still use the prefix.
        if prefix and AccessibleValue(displayName) then
            displayName = prefix .. " " .. displayName
        end

        if not fullTitle and GetTRP3Setting("showFullTitle") then fullTitle = info.fullTitle end
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

local function StyleFullTitle(frame, state, text, baseNameSize, decision, context)
    local fullTitle = frame.SNPFullTitleText
    -- Long titles are useful on name-only plates, but add too much visual
    -- noise to units whose health bars are visible.
    local bar = GetHealthBar(frame, context)
    local barShown = AccessibleBoolean(ns.PresentationCapabilities.ReadRegion(bar, "IsShown", context))
    if not text or not decision.showFullTitle or (bar and barShown ~= false) then
        if fullTitle then fullTitle:SetText(""); fullTitle:Hide() end
        return
    end

    fullTitle = EnsureFullTitleText(frame)
    local titleSize = math.max(6, math.floor(baseNameSize * 0.8 + 0.5))
    fullTitle:SetFont(NameFontPath(context), titleSize, "OUTLINE")
    fullTitle:SetText(text)
    fullTitle:SetShadowColor(0, 0, 0, 1)
    fullTitle:SetShadowOffset(1, -1)
    fullTitle:ClearAllPoints()
    fullTitle:SetPoint("TOP", frame.name, "BOTTOM", 0, -1)
    fullTitle:SetJustifyH("CENTER")
    fullTitle:SetTextColor(PriorityColorForState(decision.colorState or state))
    fullTitle:Show()
end

local function RestoreOriginalBarHeight(frame, bar, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
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

local function ApplyConfiguredBarHeight(frame, state, bar, baseNameSize, context, decision)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return false, baseNameSize end
    local inside = GetAppearanceSetting("namePlacement") == "INSIDE"
        and decision and decision.showHealthBar and bar ~= nil
    if not inside then
        RestoreOriginalBarHeight(frame, bar, context)
        return false, baseNameSize
    end

    if not frame.SNPOriginalBarHeight then
        local originalHeight = AccessibleNumber(bar:GetHeight())
        if type(originalHeight) == "number" and originalHeight > 0 then
            frame.SNPOriginalBarHeight = originalHeight
        end
    end
    local container = frame.HealthBarsContainer
    if container and not frame.SNPOriginalHealthBarsContainerHeight then
        local originalHeight = AccessibleNumber(container:GetHeight())
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

local function PositionName(frame, name, bar, nameOnly, inside, rightInset)
    if nameOnly then
        name:ClearAllPoints()
        if bar then
            name:SetPoint("BOTTOM", bar, "TOP", 0, 2)
        else
            name:SetPoint("BOTTOM", frame, "TOP", 0, 2)
        end
        name:SetJustifyH("CENTER")
    elseif inside then
        name:ClearAllPoints()
        name:SetPoint("LEFT", bar, "LEFT", 3, 0)
        name:SetPoint("RIGHT", bar, "RIGHT", rightInset, 0)
        name:SetJustifyH("LEFT")
    elseif bar then
        name:ClearAllPoints()
        name:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 2)
        name:SetJustifyH("LEFT")
    end
end

local function GetInsideName(frame, bar)
    local insideName = frame.SNPInsideName
    if insideName and frame.SNPInsideNameBar == bar then return insideName end
    if insideName then insideName:Hide() end
    insideName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    insideName:SetDrawLayer("OVERLAY", 7)
    insideName:SetWordWrap(false)
    insideName:SetMaxLines(1)
    frame.SNPInsideName = insideName
    frame.SNPInsideNameBar = bar
    return insideName
end

local function ShowInsideName(frame, bar, text, fontPath, size, rightInset)
    local insideName = GetInsideName(frame, bar)
    insideName:SetText(text)
    insideName:SetFont(fontPath, size, "OUTLINE")
    insideName:SetShadowColor(0, 0, 0, 1)
    insideName:SetShadowOffset(1, -1)
    insideName:SetTextColor(1, 1, 1, 1)
    insideName:ClearAllPoints()
    insideName:SetPoint("LEFT", bar, "LEFT", 3, 0)
    insideName:SetPoint("RIGHT", bar, "RIGHT", rightInset, 0)
    insideName:SetJustifyH("LEFT")
    insideName:Show()
    -- Leave Blizzard's name shown for its health-text visibility logic, but
    -- avoid drawing a second copy behind the bar.
    frame.name:SetAlpha(0)
end

local function RestoreNameDisplay(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    if frame.SNPInsideName then frame.SNPInsideName:Hide() end
    if frame.name then frame.name:SetAlpha(1) end
end

local function CacheNameStyle(frame, displayName, fontPath, size, nameR, nameG, nameB,
        nameOnly, inside, rightInset, bar)
    local expected = frame.SNPNameStyle or {}
    frame.SNPNameStyle = expected
    expected.text = displayName
    expected.font = fontPath
    expected.size = size
    expected.flags = "OUTLINE"
    expected.r, expected.g, expected.b = nameR, nameG, nameB
    expected.nameOnly = nameOnly
    expected.inside = inside == true
    expected.rightInset = rightInset
    expected.bar = bar
    expected.frame = frame
end

local function SuppressText(frame, context)
    -- Do not hide/reparent the unit frame or touch widget containers.
    if frame.name then frame.name:SetAlpha(0) end
    for _, key in ipairs({"SNPInsideName", "SNPFullTitleText", "SNPThreatText"}) do
        ns.NameplateFrames.SetShownSafe(frame[key], false, context)
    end
end

local function StyleName(frame, state, context, decision)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    if not decision or decision.action ~= "style" then return end
    if decision.suppressText then
        SuppressText(frame, context)
        frame.SNPNameStyle = {suppressed = true, presentation = decision}
        return
    end
    local name = frame and frame.name
    if not name then return end
    local fullTitle, displayName = UpdateNameText(frame)
    local baseSize = GetAppearanceSetting("nameSize") or 12
    local bar = GetHealthBar(frame, context)
    local nameOnly = decision.nameOnly
    local inside, size = ApplyConfiguredBarHeight(frame, state, bar, baseSize, context, decision)
    local rightInset = GetThreatEnabled() and -42 or -3
    PositionName(frame, name, bar, nameOnly, inside, rightInset)

    local fontPath = NameFontPath(context)
    name:SetFont(fontPath, size, "OUTLINE")
    name:SetShadowColor(0, 0, 0, 1)
    name:SetShadowOffset(1, -1)
    local nameR, nameG, nameB = 1, 1, 1
    if nameOnly then nameR, nameG, nameB = PriorityColorForState(decision.colorState or state) end
    -- Blizzard also tints nameplate text with UnitSelectionColor through the
    -- FontString's vertex color. Keep that tint neutral so the configured
    -- Simple Nameplates color is displayed exactly.
    name:SetVertexColor(1, 1, 1, 1)
    name:SetTextColor(nameR, nameG, nameB, 1)
    name:Show()
    if inside then
        ShowInsideName(frame, bar, displayName, fontPath, size, rightInset)
    else
        RestoreNameDisplay(frame, context)
    end
    StyleFullTitle(frame, state, fullTitle, baseSize, decision, context)
    CacheNameStyle(frame, displayName, fontPath, size, nameR, nameG, nameB,
        nameOnly, inside, rightInset, bar)
    frame.SNPNameStyle.presentation = decision
end

local function NearlyEqual(a, b)
    a, b = AccessibleNumber(a), AccessibleNumber(b)
    return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 0.001
end

local function CacheIsCurrent(frame, expected, context)
    local decision = frame.SNPPresentation
    if not decision or expected.presentation ~= decision or decision.contextRevision ~= context.revision then return false end
    if type(UnitNameplateShowsWidgetsOnly) == "function" then
        local ok, value = pcall(UnitNameplateShowsWidgetsOnly, frame.unit)
        local widgetsOnly
        if ok then widgetsOnly = AccessibleBoolean(value) end
        if type(widgetsOnly) == "boolean" and widgetsOnly ~= (decision.suppressText == true) then return false end
    end
    if expected.suppressed then return true end
    if expected.font ~= NameFontPath(context) then return false end
    local bar = GetHealthBar(frame, context)
    if expected.bar ~= bar then return false end
    local shown = AccessibleBoolean(ns.PresentationCapabilities.ReadRegion(bar, "IsShown", context))
    if shown ~= nil and shown ~= decision.showHealthBar then return false end
    return true
end

local function CachedNameHasDrifted(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return false end
    local name, expected = frame and frame.name, frame and frame.SNPNameStyle
    if not name or not expected then return false end
    if not CacheIsCurrent(frame, expected, context) then return true end
    if expected.suppressed then
        if not NearlyEqual(name:GetAlpha(), 0) then return true end
        for _, key in ipairs({"SNPInsideName", "SNPFullTitleText", "SNPThreatText"}) do
            local shown = ns.PresentationCapabilities.ReadRegion(frame[key], "IsShown", context)
            if AccessibleBoolean(shown) == true then return true end
        end
        return false
    end
    -- FontString text can be a secret string in Midnight. Never read or compare
    -- it here; the secure Blizzard name-update hook and unit events repair text.
    local font, size, flags = name:GetFont()
    font, size, flags = AccessibleValue(font), AccessibleNumber(size), AccessibleValue(flags)
    if font == nil or size == nil or flags == nil then return false end
    if font ~= expected.font or not NearlyEqual(size, expected.size) or flags ~= expected.flags then
        return true
    end
    if expected.inside and expected.bar
        and not NearlyEqual(expected.bar:GetHeight(), expected.size + 4) then
        return true
    end
    if expected.inside and frame.HealthBarsContainer
        and not NearlyEqual(frame.HealthBarsContainer:GetHeight(), expected.size + 4) then
        return true
    end
    if expected.inside then
        local insideName = frame.SNPInsideName
        if not insideName or AccessibleBoolean(insideName:IsShown()) ~= true or not NearlyEqual(name:GetAlpha(), 0) then
            return true
        end
    elseif not NearlyEqual(name:GetAlpha(), 1) then
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

local function RepairCachedName(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return false end
    local name, expected = frame and frame.name, frame and frame.SNPNameStyle
    if not name or not expected or not CacheIsCurrent(frame, expected, context) then return false end
    if expected.suppressed then SuppressText(frame, context); return true end
    name:SetText(expected.text)
    name:SetFont(expected.font, expected.size, expected.flags)
    name:SetShadowColor(0, 0, 0, 1)
    name:SetShadowOffset(1, -1)
    name:SetVertexColor(1, 1, 1, 1)
    name:SetTextColor(expected.r, expected.g, expected.b, 1)
    if expected.inside and expected.bar then
        expected.bar:SetHeight(expected.size + 4)
        if frame.HealthBarsContainer then frame.HealthBarsContainer:SetHeight(expected.size + 4) end
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
    if expected.inside and expected.bar then
        ShowInsideName(frame, expected.bar, expected.text, expected.font,
            expected.size, expected.rightInset or -3)
    else
        RestoreNameDisplay(frame, context)
    end
    return true
end


ns.NameplateText = {
    StyleName = StyleName,
    RestoreOriginalBarHeight = RestoreOriginalBarHeight,
    ApplyConfiguredBarHeight = ApplyConfiguredBarHeight,
    RestoreNameDisplay = RestoreNameDisplay,
    CachedNameHasDrifted = CachedNameHasDrifted,
    RepairCachedName = RepairCachedName,
}
