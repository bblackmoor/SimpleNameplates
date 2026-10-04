-- Simple Nameplates: one decision shared by styling and Blizzard repair hooks.
local _, ns = ...
local Cap = ns.PresentationCapabilities
local GetContext = ns.WorldContext.Get
local Classify = ns.NameplateClassification.StateForUnit
local Resolve = ns.PresentationRules.Resolve
local Restore = ns.NameplateRestoration
local Text = ns.NameplateText
local SetShownSafe = ns.NameplateFrames.SetShownSafe

local function ApplyVisibility(frame, decision, assessment, context)
    SetShownSafe(assessment.healthBar, decision.showHealthBar, context)
    -- Keep the ancestor visible so name-only text is not concealed with the bar.
    SetShownSafe(frame.HealthBarsContainer, true, context)
    SetShownSafe(assessment.castBar, decision.showCastBar, context)
    SetShownSafe(frame.CastBar, decision.showCastBar, context)
    for _, key in ipairs({"castBarAnchor", "classificationIndicator", "ClassificationFrame", "selectionHighlight"}) do
        SetShownSafe(frame[key], decision.showCombatIndicators, context)
    end
end

local function ApplyStyle(frame, context)
    context = context or GetContext()
    local assessment = Cap.InspectFrame(frame, context)
    if not assessment.canAccess then return end
    if frame.SNPRestoring then return end
    if Restore.IsPending(frame) then
        if not Restore.Request(frame, context) then return end
        assessment = Cap.InspectFrame(frame, context)
        if not assessment.canAccess then return end
    end
    local unit = ns.AccessibleValue(frame.unit)
    if type(unit) ~= "string" or not unit:match("^nameplate%d+$") then return end
    if frame.SNPOriginalUnit and frame.SNPOriginalUnit ~= unit then
        if not Restore.Request(frame, context) then return end
        assessment = Cap.InspectFrame(frame, context)
        if not assessment.canAccess then return end
    end
    local state, _, facts = Classify(unit, context)
    local decision = Resolve(context, facts, state, assessment, ns.GetStylingEnabled(), ns.GetCategoryMode(state))
    if decision.action ~= "style" then Restore.Request(frame, context); return end
    local previous = frame.SNPPresentation
    if previous and (previous.suppressText == true) ~= (decision.suppressText == true) then
        if not Restore.Request(frame, context) then return end
    end
    Restore.Cancel(frame)
    Restore.Capture(frame, assessment, context)
    frame.SNPState, frame.SNPPresentation, frame.SNPEntityFacts = state, decision, facts
    if decision.suppressText then
        Text.StyleName(frame, state, context, decision)
        return
    end
    ns.NameplateFrames.ApplyBarWidth(frame, assessment, context)
    ApplyVisibility(frame, decision, assessment, context)
    ns.NameplateFrames.ApplyBarArtwork(frame, assessment, context)
    ns.NameplateThreat.UpdateThreatText(frame, state, context, decision)
    Text.StyleName(frame, state, context, decision)
    if decision.showHealthBar then assessment.healthBar:SetStatusBarColor(ns.PriorityColorForState(decision.colorState)) end
    ns.CastHighlight.UpdateInterruptibleHighlight(frame, context, decision)
end
-- Native UI writes can invoke the repair hooks synchronously. Keep one
-- styling pass per frame and release the guard even if a write fails.
local function ApplySimpleStyle(frame, context)
    context = context or GetContext()
    if not Cap.CanAccessFrame(frame, context) then return end
    if frame.SNPRestoring or frame.SNPApplyingStyle or frame.SNPApplyingArtwork then return end
    frame.SNPApplyingStyle = true
    local ok, err = pcall(ApplyStyle, frame, context)
    frame.SNPApplyingStyle = nil
    if not ok then error(err, 0) end
end

ns.NameplatePresentation = {
    ApplySimpleStyle = ApplySimpleStyle,
    RepairHealthColor = ApplySimpleStyle, RepairName = ApplySimpleStyle,
    RestoreFrame = Restore.Request,
}
