-- Simple Nameplates: shared access to Blizzard nameplate regions.
local _, ns = ...
local C_NamePlate = C_NamePlate

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


ns.NameplateFrames = {
    GetUnitFrame = GetUnitFrame,
    GetHealthBar = GetHealthBar,
    GetCastBar = GetCastBar,
    SetShownSafe = SetShownSafe,
}
