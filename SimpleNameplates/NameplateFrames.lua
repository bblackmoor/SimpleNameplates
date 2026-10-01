-- Simple Nameplates: access to assessed Blizzard nameplate regions.
local _, ns = ...
local Capabilities = ns.PresentationCapabilities

local function GetUnitFrame(unit, context)
    return Capabilities.InspectUnit(unit, context).frame
end

local function GetFrameFromPlate(plate, context)
    local frame = Capabilities.SafeField(plate, "UnitFrame", context)
    return Capabilities.InspectFrame(frame, context).frame
end

local function GetHealthBar(frame, context)
    local assessment = Capabilities.InspectFrame(frame, context)
    if assessment.canAccess then return assessment.healthBar end
end

local function GetCastBar(frame, context)
    local assessment = Capabilities.InspectFrame(frame, context)
    if assessment.canAccess then return assessment.castBar end
end

local function SetShownSafe(region, shown, context)
    if Capabilities.ObjectStatus(region, context or ns.WorldContext.Get()) ~= "accessible" then return end
    if shown then region:Show() else region:Hide() end
end

ns.NameplateFrames = {
    GetUnitFrame = GetUnitFrame, GetFrameFromPlate = GetFrameFromPlate,
    GetHealthBar = GetHealthBar, GetCastBar = GetCastBar, SetShownSafe = SetShownSafe,
}
