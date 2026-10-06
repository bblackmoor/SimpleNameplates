-- Simple Nameplates: Blizzard-driven interruptible-cast pulse highlight.
local _, ns = ...
local Capabilities = ns.PresentationCapabilities
local CanAccessFrame = Capabilities.CanAccessFrame
local GetContext = ns.WorldContext.Get
local GetStylingEnabled = ns.GetStylingEnabled
local GetInterruptibleHighlightEnabled = ns.GetInterruptibleHighlightEnabled
local EffectColor = ns.EffectColor
local GetHealthBar, GetCastBar = ns.NameplateFrames.GetHealthBar, ns.NameplateFrames.GetCastBar

local pendingFrames = setmetatable({}, {__mode = "k"})
local eventStateByUnit = {}
local UpdateInterruptibleHighlight
local function RetryFrame(frame)
    if not pendingFrames[frame] then return end
    local context = GetContext()
    if CanAccessFrame(frame, context) then
        UpdateInterruptibleHighlight(frame, context, frame.SNPPresentation)
        return
    end
    return 0.25
end
local function DeferFrame(frame)
    pendingFrames[frame] = true
    ns.PeriodicWork.Schedule("cast retry", frame, RetryFrame, 0.25)
end

local START_EVENTS = {
    UNIT_SPELLCAST_START = true,
    UNIT_SPELLCAST_CHANNEL_START = true,
    UNIT_SPELLCAST_EMPOWER_START = true,
}
local STOP_EVENTS = {
    UNIT_SPELLCAST_STOP = true,
    UNIT_SPELLCAST_CHANNEL_STOP = true,
    UNIT_SPELLCAST_EMPOWER_STOP = true,
    UNIT_SPELLCAST_FAILED = true,
    UNIT_SPELLCAST_INTERRUPTED = true,
}

local function CreateBorder(parent, inset, thickness)
    local top = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    top:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
    top:SetHeight(thickness)

    local bottom = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", inset, inset)
    bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    bottom:SetHeight(thickness)

    local left = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    left:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", inset, inset)
    left:SetWidth(thickness)

    local right = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
    right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    right:SetWidth(thickness)

    return {top, bottom, left, right}
end

local function StopRenderer(highlight)
    if highlight.pulse then highlight.pulse:Stop() end
    if highlight.frame then highlight.frame:SetAlpha(1) end
    for _, edge in ipairs(highlight.border or {}) do edge:Hide() end
end

local function ApplyRenderer(highlight)
    local r, g, b = EffectColor("interruptible")
    for _, edge in ipairs(highlight.border) do
        edge:SetColorTexture(r, g, b, 1)
        edge:Show()
    end
    if not highlight.pulse:IsPlaying() then highlight.pulse:Play() end
end

-- Midnight can make IsInterruptable() secret. Blizzard has already consumed that
-- value to render the native icon/shield, so inspect those ordinary visual states
-- instead. Modern nameplates hide the spell icon for uninterruptible casts;
-- Classic-style nameplates keep the icon and show BorderShield instead.
local function NativeInterruptibleState(highlight, context)
    local bar = highlight and highlight.castBar
    if not bar then return nil end
    local barShown = ns.AccessibleBoolean(Capabilities.ReadRegion(bar, "IsShown", context))
    if barShown ~= true then return false end

    local icon = Capabilities.SafeField(bar, "Icon", context)
    local shield = Capabilities.SafeField(bar, "BorderShield", context)
    local iconShown = ns.AccessibleBoolean(Capabilities.ReadRegion(icon, "IsShown", context))
    local shieldShown = ns.AccessibleBoolean(Capabilities.ReadRegion(shield, "IsShown", context))
    local hideIcon = Capabilities.SafeField(bar, "HideIconWhenNotInterruptible", context)

    if hideIcon == true and iconShown ~= nil then return iconShown end
    if shieldShown == true then return false end
    if iconShown == true then return true end
    return nil
end

local function ResolvedInterruptibleState(highlight, context)
    local unit = ns.AccessibleValue(highlight and highlight.owner and highlight.owner.unit)
    if type(unit) == "string" and eventStateByUnit[unit] ~= nil then
        return eventStateByUnit[unit], "spellcast event"
    end
    local native = NativeInterruptibleState(highlight, context)
    if native ~= nil then return native, "native visual" end
    return nil, "unavailable"
end

local function RefreshHighlight(highlight, context, decision)
    if not highlight then return end
    if not GetStylingEnabled() or not GetInterruptibleHighlightEnabled()
        or not decision or not decision.showCastBar then
        highlight.interruptibleState, highlight.interruptibleSource = false, "disabled"
        highlight.frame:Hide()
        return
    end

    local state, source = ResolvedInterruptibleState(highlight, context)
    highlight.interruptibleState, highlight.interruptibleSource = state, source
    if state == true then
        highlight.frame:Show()
        ApplyRenderer(highlight)
    else
        highlight.frame:Hide()
    end
end

local function InstallRegionHook(highlight, region, registry)
    if not region then return false end
    highlight[registry] = highlight[registry] or setmetatable({}, {__mode = "k"})
    if highlight[registry][region] then return true end

    local overlay = highlight.frame
    local ok = pcall(hooksecurefunc, region, "SetShown", function()
        local context = GetContext()
        if not CanAccessFrame(highlight.owner, context) then
            DeferFrame(highlight.owner)
            return
        end
        if highlight.owner.SNPInterruptibleHighlight ~= highlight then overlay:Hide(); return end
        local bar = highlight.castBar
        local icon = Capabilities.SafeField(bar, "Icon", context)
        local shield = Capabilities.SafeField(bar, "BorderShield", context)
        if region ~= icon and region ~= shield then return end
        RefreshHighlight(highlight, context, highlight.owner.SNPPresentation)
    end)
    if ok then highlight[registry][region] = true end
    return ok
end

local function InstallInterruptibleHighlightHooks(highlight)
    local bar = highlight and highlight.castBar
    if not bar then return end
    InstallRegionHook(highlight, bar.Icon, "hookedIcons")
    InstallRegionHook(highlight, bar.BorderShield, "hookedShields")
end

local function EnsureInterruptibleHighlight(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    local castBar = GetCastBar(frame, context)
    if not castBar then return nil end
    local existing = frame.SNPInterruptibleHighlight
    if existing and existing.castBar == castBar then
        InstallInterruptibleHighlightHooks(existing)
        return existing
    end
    if existing and existing.frame then existing.frame:Hide() end

    local overlay = CreateFrame("Frame", nil, castBar)
    overlay:SetPoint("TOPLEFT", castBar, "TOPLEFT", -5, 5)
    overlay:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 5, -5)
    local healthBar = GetHealthBar(frame, context)
    local highestFrameLevel = castBar:GetFrameLevel()
    if healthBar then highestFrameLevel = math.max(highestFrameLevel, healthBar:GetFrameLevel()) end
    overlay:SetFrameLevel(highestFrameLevel + 20)
    overlay:Hide()

    local highlight = {
        castBar = castBar,
        owner = frame,
        frame = overlay,
        border = CreateBorder(overlay, 2, 4),
    }
    local pulse = overlay:CreateAnimationGroup()
    local fadeOut = pulse:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.35)
    fadeOut:SetDuration(0.55)
    fadeOut:SetOrder(1)
    local fadeIn = pulse:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.35)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.55)
    fadeIn:SetOrder(2)
    pulse:SetLooping("REPEAT")
    highlight.pulse = pulse

    overlay:SetScript("OnShow", function() ApplyRenderer(highlight) end)
    overlay:SetScript("OnHide", function() StopRenderer(highlight) end)
    frame.SNPInterruptibleHighlight = highlight
    InstallInterruptibleHighlightHooks(highlight)
    return highlight
end

UpdateInterruptibleHighlight = function(frame, context, decision)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then DeferFrame(frame); return end
    pendingFrames[frame] = nil
    ns.PeriodicWork.Cancel("cast retry", frame)
    if not GetStylingEnabled() or not decision or not decision.showCastBar
        or not GetInterruptibleHighlightEnabled() then
        if frame.SNPInterruptibleHighlight then
            frame.SNPInterruptibleHighlight.interruptibleState = false
            frame.SNPInterruptibleHighlight.interruptibleSource = "disabled"
            frame.SNPInterruptibleHighlight.frame:Hide()
        end
        return
    end
    local highlight = EnsureInterruptibleHighlight(frame, context)
    if not highlight then return end
    RefreshHighlight(highlight, context, decision)
end

local function RecordSpellcastEvent(event, unit)
    if type(unit) ~= "string" or not unit:match("^nameplate%d+$") then return false end
    if event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        eventStateByUnit[unit] = true
    elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        eventStateByUnit[unit] = false
    elseif START_EVENTS[event] then
        -- Initial state comes from Blizzard's rendered icon/shield after the
        -- cast-start event has finished dispatching.
        eventStateByUnit[unit] = nil
    elseif STOP_EVENTS[event] then
        eventStateByUnit[unit] = false
    else
        return false
    end
    return true
end

local function ClearUnit(unit, frame)
    if type(unit) == "string" then eventStateByUnit[unit] = nil end
    if frame then pendingFrames[frame] = nil; ns.PeriodicWork.Cancel("cast retry", frame) end
end

ns.CastHighlight = {
    EnsureInterruptibleHighlight = EnsureInterruptibleHighlight,
    UpdateInterruptibleHighlight = UpdateInterruptibleHighlight,
    RecordSpellcastEvent = RecordSpellcastEvent,
    ClearUnit = ClearUnit,
}
