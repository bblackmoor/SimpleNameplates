-- Simple Nameplates: original visibility and deferred frame/plate restoration.
local _, ns = ...
local Cap = ns.PresentationCapabilities
local GetContext = ns.WorldContext.Get
local SetShownSafe = ns.NameplateFrames.SetShownSafe
local Text = ns.NameplateText
local pendingFrames = setmetatable({}, {__mode = "k"})
local pendingPlates = setmetatable({}, {__mode = "k"})
local visibilityKeys = {"name", "HealthBarsContainer", "castBar", "CastBar", "castBarAnchor",
    "classificationIndicator", "ClassificationFrame", "selectionHighlight"}

local function Capture(frame, assessment, context)
    if frame.SNPOriginalVisibility then return end
    local values = {}
    for _, key in ipairs(visibilityKeys) do
        values[key] = ns.AccessibleBoolean(Cap.ReadRegion(frame[key], "IsShown", context))
    end
    values.healthBar = ns.AccessibleBoolean(Cap.ReadRegion(assessment.healthBar, "IsShown", context))
    values.nameAlpha = ns.AccessibleNumber(Cap.ReadRegion(assessment.name, "GetAlpha", context))
    frame.SNPOriginalVisibility = values
    frame.SNPOriginalUnit = ns.AccessibleValue(frame.unit)
end

local function RestoreAccessibleFrame(frame, assessment, context, removedUnit)
    frame.SNPThreatStatus = nil
    if frame.SNPThreatText then frame.SNPThreatText:SetText("") end
    if frame.SNPFullTitleText then frame.SNPFullTitleText:SetText(""); frame.SNPFullTitleText:Hide() end
    Text.RestoreNameDisplay(frame, context)
    if frame.SNPInterruptibleHighlight then frame.SNPInterruptibleHighlight.frame:Hide() end
    Text.RestoreOriginalBarHeight(frame, assessment.healthBar, context)
    ns.NameplateFrames.RestoreBarArtwork(frame, context)
    local original = frame.SNPOriginalVisibility or {}
    for _, key in ipairs(visibilityKeys) do
        if original[key] ~= nil then SetShownSafe(frame[key], original[key], context) end
    end
    if original.healthBar ~= nil then SetShownSafe(assessment.healthBar, original.healthBar, context) end
    if original.nameAlpha ~= nil and assessment.name then assessment.name:SetAlpha(original.nameAlpha) end
    frame.SNPNameStyle, frame.SNPState, frame.SNPPresentation, frame.SNPEntityFacts = nil, nil, nil, nil
    frame.SNPOriginalVisibility, frame.SNPOriginalUnit = nil, nil
    if removedUnit and ns.AccessibleValue(frame.unit) == removedUnit then
        if frame.name then frame.name:SetText("") end
    elseif CompactUnitFrame_UpdateAll then
        CompactUnitFrame_UpdateAll(frame)
    else
        if CompactUnitFrame_UpdateName then CompactUnitFrame_UpdateName(frame) end
        if CompactUnitFrame_UpdateHealthColor then CompactUnitFrame_UpdateHealthColor(frame) end
    end
end

local function Request(frame, context, removedUnit)
    context = context or GetContext()
    frame = ns.AccessibleValue(frame)
    if not frame then return true end
    local assessment = Cap.InspectFrame(frame, context)
    if not assessment.canAccess then
        pendingFrames[frame] = removedUnit or pendingFrames[frame] or true
        return false
    end
    if frame.SNPRestoring then return false end
    local pending = pendingFrames[frame]
    if not removedUnit and type(pending) == "string" then removedUnit = pending end
    if not pending and not frame.SNPState and not frame.SNPNameStyle
        and not frame.SNPOriginalVisibility then return true end
    frame.SNPRestoring = true
    -- Blizzard updates can invoke our repair hooks or throw. Always release
    -- the reentry guard, including when caches were already cleared.
    local ok, err = pcall(RestoreAccessibleFrame, frame, assessment, context, removedUnit)
    frame.SNPRestoring = nil
    if not ok then
        pendingFrames[frame] = removedUnit or true
        local message = tostring(ns.AccessibleValue(err) or "Unavailable restoration error")
        local previous = frame.SNPRestoreError
        frame.SNPRestoreError = message
        if message ~= previous and geterrorhandler then geterrorhandler()(message) end
        return false
    end
    pendingFrames[frame], frame.SNPRestoreError = nil, nil
    return true
end

local function RequestPlate(plate, context)
    context = context or GetContext()
    plate = ns.AccessibleValue(plate)
    if not plate then return true end
    if Cap.ObjectStatus(plate, context) ~= "accessible" then
        pendingPlates[plate] = true
        return false
    end
    local frame, readable = Cap.SafeField(plate, "UnitFrame", context)
    if readable == false then pendingPlates[plate] = true; return false end
    pendingPlates[plate] = nil
    return Request(frame, context)
end

local function Retry(context)
    context = context or GetContext()
    local restored = false
    for plate in pairs(pendingPlates) do
        if RequestPlate(plate, context) then restored = true end
    end
    for frame, removedUnit in pairs(pendingFrames) do
        if Request(frame, context, type(removedUnit) == "string" and removedUnit or nil) then
            restored = true
        end
    end
    return restored
end
ns.NameplateRestoration = {
    Capture = Capture, Request = Request, RequestPlate = RequestPlate, Retry = Retry,
    Cancel = function(frame) pendingFrames[frame] = nil end,
    IsPending = function(frame) return pendingFrames[frame] ~= nil end,
}
