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
local UpdateData = ns.NameplatePresentation.UpdateData
local RepairHealthColor, RepairName =
    ns.NameplatePresentation.RepairHealthColor, ns.NameplatePresentation.RepairName
local Restoration = ns.NameplateRestoration
local knownFrames = {}
local pendingUnits = {}
local removedUnits = {}
local pendingPlates = setmetatable({}, {__mode = "k"})
local CachedNameHasDrifted, RepairCachedName =
    ns.NameplateText.CachedNameHasDrifted, ns.NameplateText.RepairCachedName

local fullWork = {full = true}
local workKeys = {"full", "classify", "name", "threat", "cast", "layout"}
local function MergeWork(destination, source)
    for _, key in ipairs(workKeys) do if source[key] then destination[key] = true end end
    return destination
end

local function RefreshUnit(unit, reason, work)
    if removedUnits[unit] then return end
    work = MergeWork(pendingUnits[unit] or {}, work or fullWork)
    local context = WorldContext.Get()
    local frame = GetUnitFrame(unit, context)
    if frame then
        knownFrames[unit], pendingUnits[unit] = frame, nil
        if work.full then ApplySimpleStyle(frame, context, reason or "unit refresh")
        else UpdateData(frame, context, work) end
    else pendingUnits[unit] = work end
end

local function RefreshAll(work, queuedUnits)
    if not GetStylingEnabled() then return end
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    work = work or fullWork
    local context = WorldContext.Get()
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = GetFrameFromPlate(plate, context)
        if frame then
            local unit = ns.AccessibleValue(frame.unit)
            local currentWork = work
            if type(unit) == "string" then
                knownFrames[unit], removedUnits[unit] = frame, nil
                local pending = pendingUnits[unit]
                if queuedUnits and queuedUnits[unit] then
                    pending = MergeWork(pending or {}, queuedUnits[unit])
                    queuedUnits[unit] = nil
                end
                if pending then currentWork = MergeWork(pending, work) end
                pendingUnits[unit] = nil
            end
            pendingPlates[plate] = nil
            if currentWork.full then ApplySimpleStyle(frame, context, "refresh all")
            else UpdateData(frame, context, currentWork) end
        else pendingPlates[plate] = true end
    end
end

local function RestoreAll()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    local context = WorldContext.Get()
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        Restoration.RequestPlate(plate, context)
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
for _, event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_REGEN_ENABLED","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","PLAYER_TARGET_CHANGED","UNIT_FACTION","UNIT_FLAGS","UNIT_NAME_UPDATE","UNIT_TARGET","UNIT_THREAT_LIST_UPDATE","UNIT_THREAT_SITUATION_UPDATE","UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_STOP","UNIT_SPELLCAST_EMPOWER_START","UNIT_SPELLCAST_EMPOWER_STOP","UNIT_SPELLCAST_INTERRUPTIBLE","UNIT_SPELLCAST_NOT_INTERRUPTIBLE","CVAR_UPDATE","PLAYER_ENTERING_WORLD","ZONE_CHANGED","ZONE_CHANGED_INDOORS","ZONE_CHANGED_NEW_AREA","WAR_MODE_STATUS_UPDATE","PLAYER_FLAGS_CHANGED","PVP_TIMER_UPDATE","PLAYER_REGEN_DISABLED","PLAYER_SOFT_INTERACT_CHANGED","UPDATE_MOUSEOVER_UNIT"}) do
    events:RegisterEvent(event)
end

local dirtyUnits = {}
local allWork
local eventWork = {
    UNIT_NAME_UPDATE = {classify = true, name = true},
    UNIT_FACTION = {classify = true}, UNIT_FLAGS = {classify = true},
    UNIT_TARGET = {classify = true, threat = true},
    UNIT_THREAT_LIST_UPDATE = {classify = true, threat = true},
    UNIT_THREAT_SITUATION_UPDATE = {classify = true, threat = true},
    PLAYER_TARGET_CHANGED = {classify = true, threat = true},
    PLAYER_SOFT_INTERACT_CHANGED = {classify = true, name = true},
    UPDATE_MOUSEOVER_UNIT = {classify = true, name = true},
}
local castWork = {cast = true}
for _, event in ipairs({"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_STOP",
    "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"}) do eventWork[event] = castWork end

local function QueueUnitRefresh(unit, event)
    unit = ns.AccessibleValue(unit)
    if type(unit) == "string" and unit:match("^nameplate%d+$") then
        dirtyUnits[unit] = MergeWork(dirtyUnits[unit] or {}, eventWork[event] or fullWork)
        ns.Profiler.Count("Queued unit events", event or "unspecified")
    end
end

local function QueueRefreshAll(reason, work)
    ns.Profiler.Count("Queued global refresh", reason or "settings or callback")
    allWork = MergeWork(allWork or {}, work or fullWork)
end

local function FlushQueuedRefreshes()
    if not allWork and not next(dirtyUnits) then return end
    -- Detach the batch before writes: synchronous native callbacks may enqueue
    -- new work, which must survive for the next frame rather than being wiped.
    local units, work = dirtyUnits, allWork
    dirtyUnits, allWork = {}, nil
    if work then RefreshAll(work, units) end
    for unit, flags in pairs(units) do RefreshUnit(unit, "unit refresh", flags) end
end

local function HandlePlayerLogin()
    ns.EnsureDB()
    if ns.CheckNameplateSetup then ns.CheckNameplateSetup() end
    ns.ApplyCritterCompanionNameVisibility()
    C_Timer.After(1, function()
        if ns.GetHideCritterCompanionNames() then ns.ApplyCritterCompanionNameVisibility() end
        ns.ApplyManagedNameSettings()
    end)
    if ns.RegisterSettingsPanels then ns.RegisterSettingsPanels() end
    if ns.TRP3 and ns.TRP3.RegisterCallbacks then ns.TRP3.RegisterCallbacks() end
    if GetStylingEnabled() then
        -- Refresh once more after Blizzard finishes login setup.
        C_Timer.After(1, function()
            if GetStylingEnabled() then
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
        QueueRefreshAll("CVAR_UPDATE")
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
            QueueRefreshAll("CVAR_UPDATE")
            return
        end
    end
end

local function CleanupRemovedNameplate(unit)
    if ns.CastHighlight and ns.CastHighlight.ClearUnit then ns.CastHighlight.ClearUnit(unit) end
    local frame = knownFrames[unit] or GetUnitFrame(unit, WorldContext.Get())
    Restoration.Request(frame, WorldContext.Get(), unit)
    knownFrames[unit], dirtyUnits[unit], pendingUnits[unit] = nil, nil, nil
    removedUnits[unit] = true
end

local function HandleNameplateEvent(event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        removedUnits[unit] = nil
        RefreshUnit(unit, "initial plate")
        -- One delayed pass covers late nameplate initialization; the Blizzard
        -- hooks and cached drift check handle subsequent changes.
        C_Timer.After(0.50, function() RefreshUnit(unit, "late plate") end)
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
            or event == "UNIT_FLAGS" or event == "UNIT_FACTION" then QueueRefreshAll(event) end
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
        if ns.RetryNameplateSetup then ns.RetryNameplateSetup() end
        QueueRefreshAll(event)
        return
    end
    if event == "CVAR_UPDATE" then HandleCVarUpdate(unit); return end
    if event == "NAME_PLATE_UNIT_REMOVED" then CleanupRemovedNameplate(unit); return end
    local readableUnit = ns.AccessibleValue(unit)
    if ns.CastHighlight and ns.CastHighlight.RecordSpellcastEvent then
        ns.CastHighlight.RecordSpellcastEvent(event, readableUnit)
    end
    if not GetStylingEnabled() then return end
    if HandleNameplateEvent(event, unit) then return end
    if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED"
        or event == "UPDATE_MOUSEOVER_UNIT" then QueueRefreshAll(event, eventWork[event]); return end
    if type(readableUnit) == "string" and readableUnit:match("^nameplate%d+$") then QueueUnitRefresh(readableUnit, event)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then QueueRefreshAll(event, eventWork[event]) end
end

events:SetScript("OnEvent", HandleEvent)


-- Blizzard sometimes changes name text, font, or color without calling either
-- compact unit-frame update path. Compare readable text and safe cached
-- properties four times per second and write only when something has drifted.
-- Avoid point inspection on
-- Blizzard frames; hooks handle placement changes. Classification, TRP3
-- profile access, threat checks, and health-bar styling remain event-driven.
local function ReconcileNames(context)
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = GetFrameFromPlate(plate, context)
        if frame and frame.SNPArtworkPending then
            local assessment = ns.PresentationCapabilities.InspectFrame(frame, context)
            if assessment.canAccess then ns.NameplateFrames.ApplyBarArtwork(frame, assessment, context) end
        end
        if frame and frame.SNPTitleVisibilityPending then
            ns.NameplateText.SyncFullTitleVisibility(frame, context)
        end
        local drifted, reason
        if frame and frame.SNPState then drifted, reason = CachedNameHasDrifted(frame, context) end
        if drifted then
            ns.Profiler.Count("Name drift", reason or "unknown")
            if RepairCachedName(frame, context) then
                ns.Profiler.Count("Reconciliation repairs", "cached repair")
            else
                ns.Profiler.Count("Reconciliation repairs", "full-style fallback")
                ApplySimpleStyle(frame, context, "reconciliation fallback")
            end
        end
    end
end
ReconcileNames = ns.Profiler.Wrap("Reconciliation", ReconcileNames)

local reconcileElapsed = 0
local function RuntimeUpdate(_, elapsed)
    reconcileElapsed = reconcileElapsed + elapsed
    local reconcile = reconcileElapsed >= 0.25
    local context = WorldContext.Get()
    if reconcile then
        reconcileElapsed = 0
        if Restoration.Retry(context) and GetStylingEnabled() then QueueRefreshAll("restoration retry") end
        ns.CastHighlight.RetryPending(context)
        for plate in pairs(pendingPlates) do
            if not GetStylingEnabled() then
                if Restoration.RequestPlate(plate, context) then pendingPlates[plate] = nil end
            else
                local frame = GetFrameFromPlate(plate, context)
                if frame then
                    pendingPlates[plate] = nil
                    local unit = ns.AccessibleValue(frame.unit)
                    if type(unit) == "string" then knownFrames[unit], removedUnits[unit] = frame, nil end
                    ApplySimpleStyle(frame, context, "pending plate")
                end
            end
        end
        if GetStylingEnabled() then
            for unit, work in pairs(pendingUnits) do RefreshUnit(unit, "pending unit", work) end
        end
    end
    if not GetStylingEnabled() then return end
    FlushQueuedRefreshes()
    if not reconcile then return end

    ReconcileNames(context)
end
events:SetScript("OnUpdate", ns.Profiler.Wrap("Runtime update", RuntimeUpdate))


ns.QueueNameplateRefresh = QueueRefreshAll
ns.RefreshAll = function() RefreshAll() end
ns.RefreshNameplateData = function(work) QueueRefreshAll("TRP3 callback", work) end
ns.RestoreAll = RestoreAll
ns.StateForUnit = StateForUnit
