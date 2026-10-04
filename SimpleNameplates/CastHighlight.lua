-- Simple Nameplates: Blizzard-driven interruptible-cast border and pulse.
local _, ns = ...
local CanAccessFrame = ns.PresentationCapabilities.CanAccessFrame
local GetContext = ns.WorldContext.Get
local GetStylingEnabled = ns.GetStylingEnabled
local GetInterruptibleHighlightEnabled = ns.GetInterruptibleHighlightEnabled
local EffectColor = ns.EffectColor
local GetHealthBar, GetCastBar = ns.NameplateFrames.GetHealthBar, ns.NameplateFrames.GetCastBar

local function SetInterruptibleHighlightShown(overlay, shown)
    if not overlay then return end
    local ok = pcall(overlay.SetShown, overlay, shown)
    if not ok then overlay:Hide() end
end

local function InstallInterruptibleHighlightHook(highlight)
    local icon = highlight and highlight.castBar and highlight.castBar.Icon
    if not icon then return false end
    if highlight.hookedIcon == icon then return true end

    local overlay = highlight.frame
    local ok = pcall(hooksecurefunc, icon, "SetShown", function(_, shown)
        if not CanAccessFrame(highlight.owner, GetContext()) then return end
        local decision = highlight.owner.SNPPresentation
        if GetStylingEnabled() and GetInterruptibleHighlightEnabled()
            and decision and decision.showCastBar then
            SetInterruptibleHighlightShown(overlay, shown)
        else
            overlay:Hide()
        end
    end)
    if ok then highlight.hookedIcon = icon end
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

    local function CreateBorder(inset, thickness, layer)
        local function Edge()
            return overlay:CreateTexture(nil, "OVERLAY", nil, layer)
        end
        local top, bottom, left, right = Edge(), Edge(), Edge(), Edge()
        top:SetPoint("TOPLEFT", inset, -inset)
        top:SetPoint("TOPRIGHT", -inset, -inset)
        top:SetHeight(thickness)
        bottom:SetPoint("BOTTOMLEFT", inset, inset)
        bottom:SetPoint("BOTTOMRIGHT", -inset, inset)
        bottom:SetHeight(thickness)
        left:SetPoint("TOPLEFT", inset, -inset)
        left:SetPoint("BOTTOMLEFT", inset, inset)
        left:SetWidth(thickness)
        right:SetPoint("TOPRIGHT", -inset, -inset)
        right:SetPoint("BOTTOMRIGHT", -inset, inset)
        right:SetWidth(thickness)
        return { top, bottom, left, right }
    end

    local highlight = {
        castBar = castBar,
        owner = frame,
        frame = overlay,
        border = CreateBorder(2, 4, 7),
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
    overlay:SetScript("OnShow", function() pulse:Play() end)
    overlay:SetScript("OnHide", function()
        pulse:Stop()
        overlay:SetAlpha(1)
    end)
    frame.SNPInterruptibleHighlight = highlight

    -- Blizzard already makes the secret-safe interruptibility decision and
    -- shows the ordinary spell icon only for interruptible modern nameplate
    -- casts. Mirror that resulting visibility without inspecting the secret.
    InstallInterruptibleHighlightHook(highlight)

    return highlight
end

local function UpdateInterruptibleHighlight(frame, context, decision)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    if not decision or not decision.showCastBar or not GetInterruptibleHighlightEnabled() then
        if frame.SNPInterruptibleHighlight then frame.SNPInterruptibleHighlight.frame:Hide() end
        return
    end
    local highlight = EnsureInterruptibleHighlight(frame, context)
    if not highlight then return end

    local r, g, b = EffectColor("interruptible")
    for _, edge in ipairs(highlight.border) do edge:SetColorTexture(r, g, b, 1) end

    if not GetInterruptibleHighlightEnabled() then
        highlight.frame:Hide()
        return
    end

    local icon = highlight.castBar and highlight.castBar.Icon
    if not icon then highlight.frame:Hide(); return end
    local ok, shown = pcall(icon.IsShown, icon)
    if ok then SetInterruptibleHighlightShown(highlight.frame, shown) end
end


ns.CastHighlight = {
    EnsureInterruptibleHighlight = EnsureInterruptibleHighlight,
    UpdateInterruptibleHighlight = UpdateInterruptibleHighlight,
}
