-- Simple Nameplates: apply and restore the current category-based presentation.
local _, ns = ...
local CanAccessFrame = ns.PresentationCapabilities.CanAccessFrame
local GetContext = ns.WorldContext.Get
local StateForUnit, IsNameOnlyState =
    ns.NameplateClassification.StateForUnit, ns.NameplateClassification.IsNameOnlyState
local GetStylingEnabled, GetCategoryMode = ns.GetStylingEnabled, ns.GetCategoryMode
local PriorityColorForState, GetAppearanceSetting = ns.PriorityColorForState, ns.GetAppearanceSetting
local GetHealthBar, SetShownSafe = ns.NameplateFrames.GetHealthBar, ns.NameplateFrames.SetShownSafe
local StyleName = ns.NameplateText.StyleName
local ApplyConfiguredBarHeight = ns.NameplateText.ApplyConfiguredBarHeight
local RestoreOriginalBarHeight = ns.NameplateText.RestoreOriginalBarHeight
local RestoreNameDisplay = ns.NameplateText.RestoreNameDisplay
local UpdateThreatText = ns.NameplateThreat.UpdateThreatText
local UpdateInterruptibleHighlight = ns.CastHighlight.UpdateInterruptibleHighlight

local function ApplyVisibility(frame, state, context)
    local nameOnly = IsNameOnlyState(state)
    local bar = GetHealthBar(frame, context)
    SetShownSafe(bar, not nameOnly, context)
    -- Do not hide HealthBarsContainer itself. Some Blizzard friendly-player
    -- layouts attach or otherwise couple the name to that container, so a
    -- visible FontString can still disappear when its ancestor is hidden.
    SetShownSafe(frame.HealthBarsContainer, true, context)
    SetShownSafe(frame.castBar, not nameOnly, context)
    SetShownSafe(frame.CastBar, not nameOnly, context)
    SetShownSafe(frame.castBarAnchor, not nameOnly, context)
    SetShownSafe(frame.classificationIndicator, not nameOnly, context)
    SetShownSafe(frame.ClassificationFrame, not nameOnly, context)
    SetShownSafe(frame.selectionHighlight, not nameOnly, context)
end

local RestoreFrame

local function ApplySimpleStyle(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    if not GetStylingEnabled() then return end
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    local state = StateForUnit(frame.unit, context)
    local mode = GetCategoryMode(state)
    if mode == "inactive" then
        RestoreFrame(frame, context)
        return
    end
    frame.SNPState = state
    local r, g, b = PriorityColorForState(state)
    local bar = GetHealthBar(frame, context)
    ApplyVisibility(frame, state, context)
    StyleName(frame, state, context)
    if not IsNameOnlyState(state) and bar then
        bar:SetStatusBarColor(r, g, b, 1)
        UpdateThreatText(frame, state, context)
    elseif frame.SNPThreatText then
        frame.SNPThreatText:SetText("")
    end
    UpdateInterruptibleHighlight(frame, context)
end

local function RepairHealthColor(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    if not GetStylingEnabled() then return end
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    if frame.SNPRestoring then return end
    local state = StateForUnit(frame.unit, context)
    local mode = GetCategoryMode(state)
    if mode == "inactive" then
        RestoreFrame(frame, context)
        return
    end
    frame.SNPState = state
    local r, g, b = PriorityColorForState(state)
    local bar = GetHealthBar(frame, context)
    ApplyConfiguredBarHeight(frame, state, bar, GetAppearanceSetting("nameSize") or 12, context)
    ApplyVisibility(frame, state, context)
    if not IsNameOnlyState(state) and bar then
        bar:SetStatusBarColor(r, g, b, 1)
    end
    UpdateInterruptibleHighlight(frame, context)
end

local function RepairName(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    if not GetStylingEnabled() then return end
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    if frame.SNPRestoring then return end
    local state = StateForUnit(frame.unit, context)
    local mode = GetCategoryMode(state)
    if mode == "inactive" then
        RestoreFrame(frame, context)
        return
    end
    frame.SNPState = state
    StyleName(frame, state, context)
end

RestoreFrame = function(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    if not frame or frame.SNPRestoring then return end
    frame.SNPRestoring = true
    if frame.SNPThreatText then frame.SNPThreatText:SetText("") end
    if frame.SNPFullTitleText then frame.SNPFullTitleText:SetText(""); frame.SNPFullTitleText:Hide() end
    RestoreNameDisplay(frame, context)
    if frame.SNPInterruptibleHighlight then frame.SNPInterruptibleHighlight.frame:Hide() end
    frame.SNPNameStyle = nil
    frame.SNPState = nil
    RestoreOriginalBarHeight(frame, GetHealthBar(frame, context), context)

    -- Restore anything hidden by name-only styling before asking Blizzard to
    -- rebuild the frame according to its own current settings.
    SetShownSafe(frame.name, true, context)
    SetShownSafe(GetHealthBar(frame, context), true, context)
    SetShownSafe(frame.HealthBarsContainer, true, context)
    if CompactUnitFrame_UpdateAll then
        CompactUnitFrame_UpdateAll(frame)
    else
        if CompactUnitFrame_UpdateName then CompactUnitFrame_UpdateName(frame) end
        if CompactUnitFrame_UpdateHealthColor then CompactUnitFrame_UpdateHealthColor(frame) end
    end
    frame.SNPRestoring = nil
end


ns.NameplatePresentation = {
    ApplySimpleStyle = ApplySimpleStyle,
    RepairHealthColor = RepairHealthColor,
    RepairName = RepairName,
    RestoreFrame = RestoreFrame,
}
