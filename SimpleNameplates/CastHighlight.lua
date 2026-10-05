-- Simple Nameplates: Blizzard-driven interruptible-cast effects from LibCustomGlow.
local _, ns = ...
local CanAccessFrame = ns.PresentationCapabilities.CanAccessFrame
local GetContext = ns.WorldContext.Get
local GetStylingEnabled = ns.GetStylingEnabled
local GetInterruptibleHighlightEnabled = ns.GetInterruptibleHighlightEnabled
local EffectColor = ns.EffectColor
local GetHealthBar, GetCastBar = ns.NameplateFrames.GetHealthBar, ns.NameplateFrames.GetCastBar

local Glow = LibStub and LibStub("LibCustomGlow-1.0", true)
local GLOW_KEY = "SNPInterruptible"
local pendingFrames = setmetatable({}, {__mode = "k"})

local function StopRenderer(highlight)
    local host, style = highlight.glowHost, highlight.glowStyle
    if host then host:Hide() end
    -- Hide first so Action Button Glow stops immediately rather than fading
    -- over a newly selected effect or a finished cast.
    if Glow and host then
        if style == "PIXEL" then Glow.PixelGlow_Stop(host, GLOW_KEY)
        elseif style == "AUTOCAST" then Glow.AutoCastGlow_Stop(host, GLOW_KEY)
        elseif style == "BUTTON" then Glow.ButtonGlow_Stop(host)
        elseif style == "PROC" then Glow.ProcGlow_Stop(host, GLOW_KEY) end
    end
    highlight.glowStyle, highlight.glowColor = nil, nil
    highlight.glowWidth, highlight.glowHeight = nil, nil
end

local function ApplyRenderer(highlight)
    if not highlight.glowHost then return end
    local style = ns.GetInterruptibleCastStyle()
    if not Glow or style == "NONE" then StopRenderer(highlight); return end
    local ok, w, h = pcall(highlight.castBar.GetSize, highlight.castBar)
    local width, height
    if ok then width, height = ns.AccessibleNumber(w), ns.AccessibleNumber(h) end
    if not width or not height or width <= 0 or height <= 0 then StopRenderer(highlight); return end
    local r, g, b = EffectColor("interruptible")
    local color = highlight.glowColor
    if highlight.glowStyle == style and color and color[1] == r and color[2] == g and color[3] == b
        and highlight.glowWidth == width and highlight.glowHeight == height then return end
    StopRenderer(highlight)
    local host = highlight.glowHost
    -- All library effects perform geometry arithmetic. Use explicit readable
    -- dimensions on our own host; never pass secret native sizes to the library.
    host:SetSize(width + 6, height + 6)
    host:Show()
    local rgba = {r, g, b, 1}
    if style == "PIXEL" then
        Glow.PixelGlow_Start(host, rgba, 12, 0.125, 8, 2, 0, 0, false, GLOW_KEY)
    elseif style == "AUTOCAST" then
        Glow.AutoCastGlow_Start(host, rgba, 4, 0.125, 1, 0, 0, GLOW_KEY)
    elseif style == "BUTTON" then
        Glow.ButtonGlow_Start(host, rgba)
    elseif style == "PROC" then
        Glow.ProcGlow_Start(host, {color = rgba, key = GLOW_KEY})
    else
        host:Hide()
        return
    end
    highlight.glowStyle, highlight.glowColor = style, {r, g, b}
    highlight.glowWidth, highlight.glowHeight = width, height
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

    local highlight = {castBar = castBar, owner = frame, frame = overlay}
    local glowHost = CreateFrame("Frame", nil, overlay)
    glowHost:SetPoint("TOPLEFT", castBar, "TOPLEFT", -3, 3)
    glowHost:SetFrameLevel(overlay:GetFrameLevel())
    highlight.glowHost = glowHost
    overlay:SetScript("OnShow", function() ApplyRenderer(highlight) end)
    overlay:SetScript("OnHide", function()
        StopRenderer(highlight)
    end)
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
