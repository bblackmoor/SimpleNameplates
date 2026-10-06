-- Simple Nameplates: Blizzard-driven interruptible-cast pulse highlight.
local _, ns = ...
local CanAccessFrame = ns.PresentationCapabilities.CanAccessFrame
local GetContext = ns.WorldContext.Get
local GetStylingEnabled = ns.GetStylingEnabled
local GetInterruptibleHighlightEnabled = ns.GetInterruptibleHighlightEnabled
local EffectColor = ns.EffectColor
local GetHealthBar, GetCastBar = ns.NameplateFrames.GetHealthBar, ns.NameplateFrames.GetCastBar

local pendingFrames = setmetatable({}, {__mode = "k"})

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

local function SetInterruptibleHighlightShown(overlay, shown)
    if not overlay then return end
    local ok = pcall(overlay.SetShown, overlay, shown)
    if not ok then overlay:Hide() end
end

-- Blizzard wraps this result in spell-cast secrecy when needed. Forward it
-- directly to SetShown; never branch on or invert the interruptibility value.
local function SyncInterruptibleHighlight(highlight)
    local bar = highlight.castBar
    local method = bar and bar.IsInterruptable
    if type(method) ~= "function" then highlight.frame:Hide(); return end
    local ok, shown = pcall(method, bar)
    if ok then SetInterruptibleHighlightShown(highlight.frame, shown)
    else highlight.frame:Hide() end
end

local function InstallInterruptibleHighlightHook(highlight)
    local icon = highlight and highlight.castBar and highlight.castBar.Icon
    if not icon then return false end
    highlight.hookedIcons = highlight.hookedIcons or setmetatable({}, {__mode = "k"})
    if highlight.hookedIcons[icon] then return true end

    local overlay = highlight.frame
    local ok = pcall(hooksecurefunc, icon, "SetShown", function()
        if not CanAccessFrame(highlight.owner, GetContext()) then
            pendingFrames[highlight.owner] = true
            return
        end
        if highlight.owner.SNPInterruptibleHighlight ~= highlight then overlay:Hide(); return end
        -- Secure hooks cannot be removed. A replaced icon must no longer drive
        -- the current bar, even before the next addon refresh notices it.
        if highlight.castBar.Icon ~= icon then return end
        local decision = highlight.owner.SNPPresentation
        if GetStylingEnabled() and GetInterruptibleHighlightEnabled()
            and decision and decision.showCastBar then
            SyncInterruptibleHighlight(highlight)
        else
            overlay:Hide()
        end
    end)
    if ok then highlight.hookedIcons[icon] = true end
    return ok
end

local function EnsureInterruptibleHighlight(frame, context)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    local castBar = GetCastBar(frame, context)
    if not castBar then return nil end
    local existing = frame.SNPInterruptibleHighlight
    if existing and existing.castBar == castBar then
        InstallInterruptibleHighlightHook(existing)
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

    -- Icon updates notify us of cast/interruptibility changes in every native
    -- style. Read Blizzard's decision rather than inferring it from the icon:
    -- Classic keeps its spell icon visible for uninterruptible casts too.
    InstallInterruptibleHighlightHook(highlight)

    return highlight
end

local function UpdateInterruptibleHighlight(frame, context, decision)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then pendingFrames[frame] = true; return end
    pendingFrames[frame] = nil
    if not GetStylingEnabled() or not decision or not decision.showCastBar or not GetInterruptibleHighlightEnabled() then
        if frame.SNPInterruptibleHighlight then frame.SNPInterruptibleHighlight.frame:Hide() end
        return
    end
    local highlight = EnsureInterruptibleHighlight(frame, context)
    if not highlight then return end

    local icon = highlight.castBar and highlight.castBar.Icon
    if not icon then highlight.frame:Hide(); return end
    SyncInterruptibleHighlight(highlight)
    if ns.AccessibleBoolean(highlight.frame:IsShown()) == true then ApplyRenderer(highlight) end
end

local function RetryPending(context)
    for frame in pairs(pendingFrames) do
        if CanAccessFrame(frame, context) then
            -- Re-read current state; a missed callback may belong to a removed
            -- or recycled plate, a retired icon, or a now-disabled category.
            UpdateInterruptibleHighlight(frame, context, frame.SNPPresentation)
        end
    end
end

ns.CastHighlight = {
    EnsureInterruptibleHighlight = EnsureInterruptibleHighlight,
    UpdateInterruptibleHighlight = UpdateInterruptibleHighlight,
    RetryPending = RetryPending,
}
