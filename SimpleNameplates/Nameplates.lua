-- Simple Nameplates: runtime events, refresh queues, hooks, and plate lifecycle.
local addon, ns = ...
if not ns.EnsureDB then return end
local C_NamePlate = C_NamePlate
local WorldContext = ns.WorldContext
local GetFrameFromPlate = ns.NameplateFrames.GetFrameFromPlate
local GetStylingEnabled = ns.GetStylingEnabled
local StateForUnit = ns.NameplateClassification.StateForUnit
local GetUnitFrame, GetHealthBar = ns.NameplateFrames.GetUnitFrame, ns.NameplateFrames.GetHealthBar
local ApplySimpleStyle = ns.NameplatePresentation.ApplySimpleStyle
local RepairHealthColor, RepairName =
    ns.NameplatePresentation.RepairHealthColor, ns.NameplatePresentation.RepairName
local RestoreFrame = ns.NameplatePresentation.RestoreFrame
local RestoreOriginalBarHeight, RestoreNameDisplay =
    ns.NameplateText.RestoreOriginalBarHeight, ns.NameplateText.RestoreNameDisplay
local CachedNameHasDrifted, RepairCachedName =
    ns.NameplateText.CachedNameHasDrifted, ns.NameplateText.RepairCachedName

local function RefreshUnit(unit)
    local context = WorldContext.Get()
    local frame = GetUnitFrame(unit, context)
    if frame then ApplySimpleStyle(frame, context) end
end

local function RefreshAll()
    if not GetStylingEnabled() then return end
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    local context = WorldContext.Get()
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = GetFrameFromPlate(plate, context)
        if frame then ApplySimpleStyle(frame, context) end
    end
end

local function RestoreAll()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    local context = WorldContext.Get()
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = GetFrameFromPlate(plate, context)
        if frame then RestoreFrame(frame, context) end
    end
end

if hooksecurefunc and CompactUnitFrame_UpdateHealthColor then
    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame) RepairHealthColor(frame, WorldContext.Get()) end)
end

-- Blizzard recolors the name FontString in its name update path, which occurs
-- after NAME_PLATE_UNIT_ADDED in several situations (mounting, range changes,
-- recycled plates, etc.). Reapply our configured color after Blizzard finishes that pass.
if hooksecurefunc and CompactUnitFrame_UpdateName then
    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame) RepairName(frame, WorldContext.Get()) end)
end

local events = CreateFrame("Frame")
for _, event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_REGEN_ENABLED","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","PLAYER_TARGET_CHANGED","UNIT_FACTION","UNIT_FLAGS","UNIT_NAME_UPDATE","UNIT_TARGET","UNIT_THREAT_LIST_UPDATE","UNIT_THREAT_SITUATION_UPDATE","CVAR_UPDATE","PLAYER_ENTERING_WORLD","ZONE_CHANGED","ZONE_CHANGED_INDOORS","ZONE_CHANGED_NEW_AREA","WAR_MODE_STATUS_UPDATE","PLAYER_FLAGS_CHANGED","PVP_TIMER_UPDATE","PLAYER_REGEN_DISABLED","PLAYER_SOFT_INTERACT_CHANGED"}) do
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

local function HandlePlayerLogin()
    ns.EnsureDB()
    ns.ApplyCritterCompanionNameVisibility()
    C_Timer.After(1, function()
        if ns.GetHideCritterCompanionNames() then ns.ApplyCritterCompanionNameVisibility() end
        ns.ApplyManagedNameSettings()
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
end

local function HandleCVarUpdate(cvarName)
    if type(cvarName) == "string"
        and ns.MANAGED_NAME_CVAR_SET[string.lower(cvarName)] then
        if ns.ApplyManagedNameSettings then ns.ApplyManagedNameSettings() end
        QueueRefreshAll()
        return
    end
    if ns.GetHideCritterCompanionNames() then
        for _, cvar in ipairs(ns.BLIZZARD_CRITTER_COMPANION_NAME_CVARS) do
            if cvarName == cvar then
                ns.ApplyCritterCompanionNameVisibility()
                return
            end
        end
    end
    if not GetStylingEnabled() then return end
    for _, cvar in ipairs(ns.FRIENDLY_COLOR_CVARS) do
        if cvarName == cvar then
            ns.DisableFriendlyClassColors()
            QueueRefreshAll()
            return
        end
    end
end

local function CleanupRemovedNameplate(unit)
    local context = WorldContext.Get()
    local frame = GetUnitFrame(unit, context)
    if frame then
        RestoreOriginalBarHeight(frame, GetHealthBar(frame, context), context)
        if frame.name then frame.name:SetText("") end
        if frame.SNPThreatText then frame.SNPThreatText:SetText("") end
        if frame.SNPFullTitleText then frame.SNPFullTitleText:SetText(""); frame.SNPFullTitleText:Hide() end
        RestoreNameDisplay(frame, context)
        frame.SNPNameStyle = nil
        frame.SNPState = nil
        if frame.SNPInterruptibleHighlight then frame.SNPInterruptibleHighlight.frame:Hide() end
    end
    dirtyUnits[unit] = nil
end

local function HandleNameplateEvent(event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        RefreshUnit(unit)
        -- One delayed pass covers late nameplate initialization; the Blizzard
        -- hooks and cached drift check handle subsequent changes.
        C_Timer.After(0.50, function() RefreshUnit(unit) end)
        return true
    end
    if event == "NAME_PLATE_UNIT_REMOVED" then
        CleanupRemovedNameplate(unit)
        return true
    end
    return false
end

local function HandleEvent(_, event, unit)
    if WorldContext.HandlesEvent(event, unit) then
        local _, changed = WorldContext.Refresh(event)
        if changed or event == "PLAYER_ENTERING_WORLD"
            or event == "UNIT_FLAGS" or event == "UNIT_FACTION" then QueueRefreshAll() end
    end
    if event == "ADDON_LOADED" then
        if unit ~= addon then return end
        events:UnregisterEvent("ADDON_LOADED")
        ns.EnsureDB()
        WorldContext.Refresh(event)
        return
    end
    if event == "PLAYER_LOGIN" then HandlePlayerLogin(); return end
    if event == "PLAYER_REGEN_ENABLED" then
        if ns.ApplyPendingManagedNameSettings then ns.ApplyPendingManagedNameSettings() end
        QueueRefreshAll()
        return
    end
    if event == "CVAR_UPDATE" then HandleCVarUpdate(unit); return end
    if not GetStylingEnabled() then return end
    if HandleNameplateEvent(event, unit) then return end
    if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" then QueueRefreshAll(); return end
    if unit and tostring(unit):match("^nameplate%d+$") then QueueUnitRefresh(unit)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then QueueRefreshAll() end
end

events:SetScript("OnEvent", HandleEvent)


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
    local context = WorldContext.Get()
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = GetFrameFromPlate(plate, context)
        if frame and frame.SNPState and CachedNameHasDrifted(frame, context) then
            RepairCachedName(frame, context)
        end
    end
end)


ns.RefreshAll = RefreshAll
ns.RestoreAll = RestoreAll
ns.StateForUnit = StateForUnit
