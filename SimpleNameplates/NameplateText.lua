-- Simple Nameplates: unit names, TRP3 titles, layout, and cached text repair.
local _, ns = ...
local CanAccessFrame = ns.PresentationCapabilities.CanAccessFrame
local GetContext = ns.WorldContext.Get
local AccessibleBoolean = ns.AccessibleBoolean
local UnitName = UnitName
local AccessibleNumber, AccessibleValue = ns.AccessibleNumber, ns.AccessibleValue
local PriorityColorForState, FontPath = ns.PriorityColorForState, ns.FontPath
local GetAppearanceSetting, GetTRP3Setting = ns.GetAppearanceSetting, ns.GetTRP3Setting
local GetHealthBar = ns.NameplateFrames.GetHealthBar
local GetCastBar = ns.NameplateFrames.GetCastBar

local function NameFontPath(context)
    if context.sanctuary == true and GetAppearanceSetting("matchSanctuaryFont") == true then
        -- The engine's world-label font family is localized by Blizzard.
        -- Read only its face: preserve the profile's size and our text layout.
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

local function SyncFullTitleVisibility(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) or frame.SNPRestoring then return end
    frame.SNPTitleVisibilityPending = nil
    local title, decision = frame.SNPFullTitleText, frame.SNPPresentation
    if not title then return end
    if not ns.GetStylingEnabled() or not frame.SNPFullTitleAvailable
        or not decision or not decision.showFullTitle or decision.suppressText then
        title:Hide(); return
    end
    local cast = GetCastBar(frame, context)
    local shown = AccessibleBoolean(ns.PresentationCapabilities.ReadRegion(cast, "IsShown", context))
    if cast and shown == nil then frame.SNPTitleVisibilityPending = true end
    -- Unknown cast visibility must not put title text over a possible cast.
    if cast and shown ~= false then title:Hide() else title:Show() end
end

local function InstallTitleCastHooks(frame, cast)
    if not cast or type(cast.HookScript) ~= "function" or cast.SNPTitleHookOwner == frame then return end
    local function Refresh()
        frame.SNPTitleVisibilityPending = true
        local context = GetContext()
        if GetCastBar(frame, context) == cast then SyncFullTitleVisibility(frame, context) end
    end
    cast:HookScript("OnShow", Refresh)
    cast:HookScript("OnHide", Refresh)
    cast.SNPTitleHookOwner = frame
end

local function FullTitleWidth(frame, context)
    local cap = ns.PresentationCapabilities
    for _, region in ipairs({GetHealthBar(frame, context) or false, frame.HealthBarsContainer or false, frame}) do
        if region and cap.ObjectStatus(region, context) == "accessible" then
            local width = AccessibleNumber(cap.ReadRegion(region, "GetWidth", context))
            if width and width > 0 then return width end
        end
    end
    -- Unknown geometry must not leave an unlimited title. Reconciliation retries.
    return 1
end

local function ConstrainFullTitle(frame, context)
    if frame.SNPFullTitleText then
        frame.SNPFullTitleText:SetWidth(FullTitleWidth(frame, context))
    end
end

local function StyleFullTitle(frame, state, text, baseNameSize, decision, context, nameShade)
    local fullTitle = frame.SNPFullTitleText
    local bar = GetHealthBar(frame, context)
    frame.SNPFullTitleAvailable = text ~= nil and decision.showFullTitle == true
    if not frame.SNPFullTitleAvailable then
        if fullTitle then fullTitle:SetText(""); fullTitle:Hide() end
        return
    end

    fullTitle = EnsureFullTitleText(frame)
    local titleSize = math.max(6, baseNameSize - 2)
    fullTitle:SetFont(NameFontPath(context), titleSize, ns.FontFlags(true))
    -- Native single-line layout truncates overflow using the actual font.
    -- Keep the source string intact so widening the bar restores more text.
    ConstrainFullTitle(frame, context)
    fullTitle:SetText(text)
    fullTitle:SetShadowColor(0, 0, 0, 0)
    fullTitle:SetShadowOffset(0, 0)
    fullTitle:ClearAllPoints()
    fullTitle:SetPoint("TOP", decision.showHealthBar and bar or frame.name, "BOTTOM", 0, -1)
    fullTitle:SetJustifyH("CENTER")
    fullTitle:SetVertexColor(1, 1, 1, 1)
    local shade = state == "useless" and nameShade or 1
    fullTitle:SetTextColor(shade, shade, shade, 1)
    InstallTitleCastHooks(frame, GetCastBar(frame, context))
    SyncFullTitleVisibility(frame, context)
end

local function RestoreOriginalBarHeight(frame, bar, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    if not frame then return end
    bar = frame.SNPOriginalHealthBar or bar
    if bar and frame.SNPOriginalBarHeight then
        bar:SetHeight(frame.SNPOriginalBarHeight)
    end
    local container = frame.SNPOriginalHealthBarsContainer or frame.HealthBarsContainer
    if container and frame.SNPOriginalHealthBarsContainerHeight then
        container:SetHeight(frame.SNPOriginalHealthBarsContainerHeight)
    end
    frame.SNPOriginalBarHeight = nil
    frame.SNPOriginalHealthBarsContainerHeight = nil
end

local function InsideBarHeight(frame, nameSize)
    return math.max(nameSize + 7, frame.SNPOriginalBarHeight or 0,
        frame.SNPOriginalHealthBarsContainerHeight or 0)
end

local function ApplyConfiguredBarHeight(frame, state, bar, baseNameSize, context, decision)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return false, baseNameSize end
    local inside = GetAppearanceSetting("namePlacement") == "INSIDE"
        and decision and decision.showHealthBar and bar ~= nil
    local hasThreat = frame.SNPThreatStatus == "displayed raw percentage"
        or frame.SNPThreatStatus == "displayed scaled percentage"
    local hasNativeText = false
    if bar and decision and decision.showHealthBar then
        for _, key in ipairs({"Text", "RightText", "LeftText"}) do
            if AccessibleBoolean(ns.PresentationCapabilities.ReadRegion(bar[key], "IsShown", context)) == true then
                hasNativeText = true
            end
        end
    end
    if not inside and not hasThreat and not hasNativeText then
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

    local insideNameSize = baseNameSize
    local barHeight = InsideBarHeight(frame, insideNameSize)
    bar:SetHeight(barHeight)
    if container then container:SetHeight(barHeight) end
    return inside, insideNameSize
end

local function PositionName(frame, name, bar, nameOnly, inside, rightInset, rightRegion)
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
        name:SetPoint("RIGHT", rightRegion or bar, rightRegion and "LEFT" or "RIGHT", rightInset, 0)
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
    if insideName then ns.TextUnderlayers.Hide(insideName); insideName:Hide() end
    insideName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    insideName:SetDrawLayer("OVERLAY", 7)
    insideName:SetWordWrap(false)
    insideName:SetMaxLines(1)
    frame.SNPInsideName = insideName
    frame.SNPInsideNameBar = bar
    return insideName
end

local function ShowInsideName(frame, bar, text, fontPath, size, rightInset, rightRegion, textColor)
    local insideName = GetInsideName(frame, bar)
    insideName:SetText(text)
    insideName:SetFont(fontPath, size, ns.FontFlags(false))
    insideName:SetShadowColor(0, 0, 0, 0)
    insideName:SetShadowOffset(0, 0)
    insideName:SetTextColor(textColor, textColor, textColor, 1)
    insideName:ClearAllPoints()
    insideName:SetPoint("LEFT", bar, "LEFT", 3, -0.5)
    insideName:SetPoint("RIGHT", rightRegion or bar, rightRegion and "LEFT" or "RIGHT", rightInset, rightRegion and 0 or -0.5)
    insideName:SetJustifyH("LEFT")
    insideName:Show()
    if ns.HealthGradient and ns.HealthGradient.Enabled() then
        ns.TextUnderlayers.Hide(insideName)
    else
        ns.TextUnderlayers.Update(insideName, bar)
    end
    -- Leave Blizzard's name shown for its health-text visibility logic, but
    -- avoid drawing a second copy behind the bar.
    frame.name:SetAlpha(0)
end

local function RestoreNameDisplay(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    if frame.SNPInsideName then ns.TextUnderlayers.Hide(frame.SNPInsideName); frame.SNPInsideName:Hide() end
    if frame.name then frame.name:SetAlpha(1) end
end

local function CacheNameStyle(frame, displayName, fontPath, size, nameR, nameG, nameB,
        nameOnly, inside, rightInset, bar, rightRegion)
    local expected = frame.SNPNameStyle or {}
    frame.SNPNameStyle = expected
    expected.text = displayName
    expected.font = fontPath
    expected.size = size
    expected.flags = ns.FontFlags(not inside)
    expected.r, expected.g, expected.b = nameR, nameG, nameB
    expected.nameOnly = nameOnly
    expected.inside = inside == true
    expected.rightInset = rightInset
    expected.rightRegion = rightRegion
    expected.bar = bar
    expected.barHeight = frame.SNPOriginalBarHeight and InsideBarHeight(frame, size) or nil
    expected.barWidth = frame.SNPBarWidth
    expected.containerWidth = frame.SNPContainerWidth
end

local function SuppressText(frame, context)
    -- Do not hide/reparent the unit frame or touch widget containers.
    if frame.name then frame.name:SetAlpha(0) end
    for _, key in ipairs({"SNPInsideName", "SNPFullTitleText", "SNPThreatText"}) do
        ns.TextUnderlayers.Hide(frame[key])
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
    local rightInset = -3

    local fontPath = NameFontPath(context)
    name:SetFont(fontPath, size, ns.FontFlags(not inside))
    name:SetShadowColor(0, 0, 0, 0)
    name:SetShadowOffset(0, 0)
    local nameR, nameG, nameB = 1, 1, 1
    if nameOnly then nameR, nameG, nameB = PriorityColorForState(decision.colorState or state)
    end
    if state == "useless" then
        local shade = ns.GetDimBackgroundNames and ns.GetDimBackgroundNames() and 153 / 255 or 1
        nameR, nameG, nameB = shade, shade, shade
    end
    -- Blizzard also tints nameplate text with UnitSelectionColor through the
    -- FontString's vertex color. Keep that tint neutral so the configured
    -- Simple Nameplates color is displayed exactly.
    name:SetVertexColor(1, 1, 1, 1)
    name:SetTextColor(nameR, nameG, nameB, 1)
    name:Show()
    -- Showing the native name can itself change native health-text visibility.
    local rightRegion, healthTextSignature = ns.NameplateFrames.LayoutHealthText(frame, bar, context)
    PositionName(frame, name, bar, nameOnly, inside, rightInset, rightRegion)
    if inside then
        ShowInsideName(frame, bar, displayName, fontPath, size, rightInset, rightRegion, nameR)
    else
        RestoreNameDisplay(frame, context)
    end
    StyleFullTitle(frame, state, fullTitle, baseSize, decision, context, nameR)
    CacheNameStyle(frame, displayName, fontPath, size, nameR, nameG, nameB,
        nameOnly, inside, rightInset, bar, rightRegion)
    frame.SNPNameStyle.presentation = decision
    frame.SNPNameStyle.healthTextSignature = healthTextSignature
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
    if expected.flags ~= ns.FontFlags(expected.inside ~= true) then return false end
    if expected.font ~= NameFontPath(context) then return false end
    local bar = GetHealthBar(frame, context)
    if expected.bar ~= bar then return false end
    local inset, signature = ns.NameplateFrames.GetHealthTextInsetRegion(frame, bar, context)
    if inset ~= expected.rightRegion or signature ~= expected.healthTextSignature then return false end
    if frame.SNPOriginalVisibility
        and frame.SNPOriginalHealthBarsContainer ~= frame.HealthBarsContainer then return false end
    local shown = AccessibleBoolean(ns.PresentationCapabilities.ReadRegion(bar, "IsShown", context))
    if shown ~= nil and shown ~= decision.showHealthBar then return false end
    return true
end

local function ReadableTextHasDrifted(region, expectedText, context)
    local actual = ns.PresentationCapabilities.ReadRegion(region, "GetText", context)
    local expected = AccessibleValue(expectedText)
    -- Compare only readable strings. Restricted names still pass directly to SetText.
    return type(actual) == "string" and type(expected) == "string" and actual ~= expected
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
    local shown = ns.PresentationCapabilities.ReadRegion(name, "IsShown", context)
    if AccessibleBoolean(shown) == false then return true end
    if ReadableTextHasDrifted(name, expected.text, context) then return true end
    local font, size, flags = name:GetFont()
    font, size, flags = AccessibleValue(font), AccessibleNumber(size), AccessibleValue(flags)
    if font == nil or size == nil or flags == nil then return false end
    if font ~= expected.font or not NearlyEqual(size, expected.size) or flags ~= expected.flags then
        return true
    end
    if expected.barHeight and expected.bar
        and not NearlyEqual(expected.bar:GetHeight(), expected.barHeight) then
        return true
    end
    if expected.barHeight and frame.HealthBarsContainer
        and not NearlyEqual(frame.HealthBarsContainer:GetHeight(), expected.barHeight) then
        return true
    end
    if expected.barWidth and not NearlyEqual(expected.bar:GetWidth(), expected.barWidth) then return true end
    if expected.containerWidth and frame.HealthBarsContainer
        and not NearlyEqual(frame.HealthBarsContainer:GetWidth(), expected.containerWidth) then return true end
    if frame.SNPFullTitleAvailable and frame.SNPFullTitleText
        and not NearlyEqual(ns.PresentationCapabilities.ReadRegion(frame.SNPFullTitleText, "GetWidth", context),
            FullTitleWidth(frame, context)) then return true end
    if expected.inside then
        local insideName = frame.SNPInsideName
        if not insideName or AccessibleBoolean(insideName:IsShown()) ~= true or not NearlyEqual(name:GetAlpha(), 0) then
            return true
        end
        if ReadableTextHasDrifted(insideName, expected.text, context) then return true end
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
    name:SetShadowColor(0, 0, 0, 0)
    name:SetShadowOffset(0, 0)
    name:SetVertexColor(1, 1, 1, 1)
    name:SetTextColor(expected.r, expected.g, expected.b, 1)
    if expected.barHeight and expected.bar then
        expected.bar:SetHeight(expected.barHeight)
        if frame.HealthBarsContainer then frame.HealthBarsContainer:SetHeight(expected.barHeight) end
    end
    if expected.barWidth then expected.bar:SetWidth(expected.barWidth) end
    if expected.containerWidth and frame.HealthBarsContainer then frame.HealthBarsContainer:SetWidth(expected.containerWidth) end
    ConstrainFullTitle(frame, context)
    PositionName(frame, name, expected.bar, expected.nameOnly, expected.inside,
        expected.rightInset or -3, expected.rightRegion)
    name:Show()
    if expected.inside and expected.bar then
        ShowInsideName(frame, expected.bar, expected.text, expected.font,
            expected.size, expected.rightInset or -3, expected.rightRegion, expected.r)
    else
        RestoreNameDisplay(frame, context)
    end
    return true
end


RepairCachedName = ns.Profiler.Wrap("Text repair", RepairCachedName)

ns.NameplateText = {
    SyncFullTitleVisibility = SyncFullTitleVisibility,
    StyleName = StyleName,
    RestoreOriginalBarHeight = RestoreOriginalBarHeight,
    ApplyConfiguredBarHeight = ApplyConfiguredBarHeight,
    RestoreNameDisplay = RestoreNameDisplay,
    CachedNameHasDrifted = CachedNameHasDrifted,
    RepairCachedName = RepairCachedName,
}
