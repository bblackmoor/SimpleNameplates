-- Simple Nameplates: apply and restore the current category-based presentation.
local _, ns = ...
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

local RestoreFrame

local function ApplySimpleStyle(frame)
    if not GetStylingEnabled() then return end
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    local state = StateForUnit(frame.unit)
    local mode = GetCategoryMode(state)
    if mode == "inactive" then
        RestoreFrame(frame)
        return
    end
    frame.SNPState = state
    local r, g, b = PriorityColorForState(state)
    local bar = GetHealthBar(frame)
    ApplyVisibility(frame, state)
    StyleName(frame, state)
    if not IsNameOnlyState(state) and bar then
        bar:SetStatusBarColor(r, g, b, 1)
        UpdateThreatText(frame, state)
    elseif frame.SNPThreatText then
        frame.SNPThreatText:SetText("")
    end
    UpdateInterruptibleHighlight(frame)
end

local function RepairHealthColor(frame)
    if not GetStylingEnabled() then return end
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    if frame.SNPRestoring then return end
    local state = StateForUnit(frame.unit)
    local mode = GetCategoryMode(state)
    if mode == "inactive" then
        RestoreFrame(frame)
        return
    end
    frame.SNPState = state
    local r, g, b = PriorityColorForState(state)
    local bar = GetHealthBar(frame)
    ApplyConfiguredBarHeight(frame, state, bar, GetAppearanceSetting("nameSize") or 12)
    ApplyVisibility(frame, state)
    if not IsNameOnlyState(state) and bar then
        bar:SetStatusBarColor(r, g, b, 1)
    end
    UpdateInterruptibleHighlight(frame)
end

local function RepairName(frame)
    if not GetStylingEnabled() then return end
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    if frame.SNPRestoring then return end
    local state = StateForUnit(frame.unit)
    local mode = GetCategoryMode(state)
    if mode == "inactive" then
        RestoreFrame(frame)
        return
    end
    frame.SNPState = state
    StyleName(frame, state)
end

RestoreFrame = function(frame)
    if not frame or frame.SNPRestoring then return end
    frame.SNPRestoring = true
    if frame.SNPThreatText then frame.SNPThreatText:SetText("") end
    if frame.SNPFullTitleText then frame.SNPFullTitleText:SetText(""); frame.SNPFullTitleText:Hide() end
    RestoreNameDisplay(frame)
    if frame.SNPInterruptibleHighlight then frame.SNPInterruptibleHighlight.frame:Hide() end
    frame.SNPNameStyle = nil
    frame.SNPState = nil
    RestoreOriginalBarHeight(frame, GetHealthBar(frame))

    -- Restore anything hidden by name-only styling before asking Blizzard to
    -- rebuild the frame according to its own current settings.
    SetShownSafe(frame.name, true)
    SetShownSafe(GetHealthBar(frame), true)
    SetShownSafe(frame.HealthBarsContainer, true)
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
