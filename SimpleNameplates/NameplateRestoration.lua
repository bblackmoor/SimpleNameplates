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

local unpackValues = unpack or table.unpack
local nameProperties = {
    {"GetFont", "SetFont"}, {"GetTextColor", "SetTextColor"},
    {"GetVertexColor", "SetVertexColor"}, {"GetShadowColor", "SetShadowColor"},
    {"GetShadowOffset", "SetShadowOffset"}, {"GetJustifyH", "SetJustifyH"},
}

-- Only read presentation data. Native health/heal-prediction updates must run
-- from Blizzard's own events, never from this addon's restoration stack.
local function ReadValues(region, method, context, ...)
    local getter = Cap.SafeField(region, method, context)
    if type(getter) ~= "function" then return nil end
    local values = {pcall(getter, region, ...)}
    if not values[1] then return nil end
    table.remove(values, 1)
    for index = 1, #values do
        values[index] = ns.AccessibleValue(values[index])
        if values[index] == nil then return nil end
    end
    return #values > 0 and values or nil
end

local function CaptureNativePresentation(frame, assessment, context)
    local original = {name = {}}
    local name = assessment.name
    for _, property in ipairs(nameProperties) do
        original.name[property[2]] = ReadValues(name, property[1], context)
    end
    original.text = ns.AccessibleValue(Cap.ReadRegion(name, "GetText", context))
    local count = ns.AccessibleNumber(Cap.ReadRegion(name, "GetNumPoints", context))
    if count then
        local points = {}
        for index = 1, count do
            local point = ReadValues(name, "GetPoint", context, index)
            if not point then points = nil; break end
            points[#points + 1] = point
        end
        original.points = points
    end
    original.barColor = ReadValues(assessment.healthBar, "GetStatusBarColor", context)
    frame.SNPOriginalPresentation = original
end

local function RestoreNativePresentation(frame, assessment, context, removedUnit)
    local original = frame.SNPOriginalPresentation
    if not original then return end
    local name = assessment.name
    if name then
        for _, property in ipairs(nameProperties) do
            local values = original.name[property[2]]
            if values then name[property[2]](name, unpackValues(values)) end
        end
        if original.points then
            name:ClearAllPoints()
            for _, point in ipairs(original.points) do name:SetPoint(unpackValues(point)) end
        end
        local unit = ns.AccessibleValue(frame.unit)
        if removedUnit and unit == removedUnit then
            name:SetText("")
        elseif unit == frame.SNPOriginalUnit and original.text ~= nil then
            name:SetText(original.text)
        elseif type(unit) == "string" and UnitName then
            -- SetText accepts a secret name directly; do not inspect it.
            name:SetText(UnitName(unit))
        end
    end
    if assessment.healthBar and original.barColor then
        assessment.healthBar:SetStatusBarColor(unpackValues(original.barColor))
    end
end

local function Capture(frame, assessment, context)
    if frame.SNPOriginalVisibility then return end
    CaptureNativePresentation(frame, assessment, context)
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
    if frame.SNPThreatText then
        ns.TextUnderlayers.Hide(frame.SNPThreatText)
        frame.SNPThreatText:SetText("")
        frame.SNPThreatText:Hide()
    end
    if frame.SNPFullTitleText then frame.SNPFullTitleText:SetText(""); frame.SNPFullTitleText:Hide() end
    Text.RestoreNameDisplay(frame, context)
    if frame.SNPInterruptibleHighlight then frame.SNPInterruptibleHighlight.frame:Hide() end
    Text.RestoreOriginalBarHeight(frame, assessment.healthBar, context)
    ns.NameplateFrames.RestoreBarArtwork(frame, context)
    ns.NameplateFrames.RestoreBarWidth(frame, assessment)
    local original = frame.SNPOriginalVisibility or {}
    for _, key in ipairs(visibilityKeys) do
        if original[key] ~= nil then SetShownSafe(frame[key], original[key], context) end
    end
    if original.healthBar ~= nil then SetShownSafe(assessment.healthBar, original.healthBar, context) end
    if original.nameAlpha ~= nil and assessment.name then assessment.name:SetAlpha(original.nameAlpha) end
    RestoreNativePresentation(frame, assessment, context, removedUnit)
    frame.SNPNameStyle, frame.SNPState, frame.SNPPresentation, frame.SNPEntityFacts = nil, nil, nil, nil
    frame.SNPOriginalVisibility, frame.SNPOriginalUnit, frame.SNPOriginalPresentation = nil, nil, nil
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
