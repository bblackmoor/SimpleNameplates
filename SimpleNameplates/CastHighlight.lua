-- Simple Nameplates: Blizzard-driven interruptible cast effects.
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


local function Parameter(effect, key, fallback)
    local getter = ns.GetCastAdvancedSetting
    local value = getter and getter(effect, key)
    if value ~= nil then return value end
    return fallback
end

local function Reanchor(frame, parent, distance)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", -distance, distance)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", distance, -distance)
end

local function ConfigurePulse(h)
    local thick = Parameter("PULSE", "thickness", 4)
    local inset = Parameter("PULSE", "inset", 2)
    local low = Parameter("PULSE", "lowAlpha", 0.35)
    local high = Parameter("PULSE", "highAlpha", 1)
    local fadeOut = Parameter("PULSE", "fadeOut", 0.55)
    local fadeIn = Parameter("PULSE", "fadeIn", 0.55)
    local signature = table.concat({thick, inset, low, high, fadeOut, fadeIn}, ":")
    if h.pulseConfig == signature then return end
    h.pulseConfig = signature
    local top, bottom, left, right = unpack(h.border)
    for _, edge in ipairs(h.border) do edge:ClearAllPoints() end
    top:SetPoint("TOPLEFT", h.frame, "TOPLEFT", inset, -inset)
    top:SetPoint("TOPRIGHT", h.frame, "TOPRIGHT", -inset, -inset)
    top:SetHeight(thick)
    bottom:SetPoint("BOTTOMLEFT", h.frame, "BOTTOMLEFT", inset, inset)
    bottom:SetPoint("BOTTOMRIGHT", h.frame, "BOTTOMRIGHT", -inset, inset)
    bottom:SetHeight(thick)
    left:SetPoint("TOPLEFT", h.frame, "TOPLEFT", inset, -inset)
    left:SetPoint("BOTTOMLEFT", h.frame, "BOTTOMLEFT", inset, inset)
    left:SetWidth(thick)
    right:SetPoint("TOPRIGHT", h.frame, "TOPRIGHT", -inset, -inset)
    right:SetPoint("BOTTOMRIGHT", h.frame, "BOTTOMRIGHT", -inset, inset)
    right:SetWidth(thick)
    h.pulse:Stop()
    h.fadeOut:SetFromAlpha(high)
    h.fadeOut:SetToAlpha(low)
    h.fadeOut:SetDuration(fadeOut)
    h.fadeIn:SetFromAlpha(low)
    h.fadeIn:SetToAlpha(high)
    h.fadeIn:SetDuration(fadeIn)
end

local function StopRenderer(highlight)
    if highlight.pulse then highlight.pulse:Stop() end
    if highlight.frame then highlight.frame:SetAlpha(1) end
    for _, edge in ipairs(highlight.border or {}) do edge:Hide() end
    for _, renderer in pairs(highlight.renderers or {}) do
        if renderer.Stop then renderer:Stop() end
        if renderer.ProcLoop then renderer.ProcLoop:Stop() end
        renderer:Hide()
    end
    for _, host in pairs(highlight.effectHosts or {}) do host:Hide() end
end

local function FrameworkRenderer(highlight, effect)
    highlight.renderers = highlight.renderers or {}
    if highlight.renderers[effect] then return highlight.renderers[effect] end
    if highlight.failedEffects and highlight.failedEffects[effect] then error(highlight.failedEffects[effect]) end
    local df = LibStub and LibStub:GetLibrary("DetailsFramework-1.0", true)
    if not df then error("Details Framework unavailable") end
    -- Track a hidden construction host before calling library code, so a
    -- partially failing constructor cannot leave visible child regions behind.
    local layer = CreateFrame("Frame", nil, highlight.frame)
    layer:SetAllPoints(highlight.frame)
    layer:SetFrameLevel(highlight.frame:GetFrameLevel() + 1)
    layer:Hide()
    highlight.effectHosts = highlight.effectHosts or {}
    highlight.effectHosts[effect] = layer
    local renderer
    if effect == "SOLID" then
        renderer = df:CreateFullBorder(nil, layer)
        renderer:SetIgnoreParentScale(false)
        renderer:SetBorderSizes(2, 2, 2, 2)
        renderer:UpdateSizes()
    elseif effect == "SOFT" then
        renderer = layer
        df:CreateBorderWithSpread(renderer, 1, 0.55, 0.2, 2, 0)
    elseif effect == "ANTS" then
        renderer = df:CreateAnts(layer, {
            Texture = "Interface\\SpellActivationOverlay\\IconAlertAnts",
            TextureWidth = 256, TextureHeight = 256,
            TexturePartsWidth = 48, TexturePartsHeight = 48, AmountParts = 22,
        }, -3, 3, 3, -3)
        -- DF's helper calls AnimateTexCoords, absent on some Midnight clients.
        -- Animate only this owned sheet; never read native cast dimensions.
        renderer:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            local index = math.floor(self.elapsed / (self.frameTime or 0.025)) % (self.frameCount or 22)
            local left, top = (index % 5) * 48 / 256, math.floor(index / 5) * 48 / 256
            self.Texture:SetTexCoord(left, left + 48 / 256, top, top + 48 / 256)
        end)
    elseif effect == "GLOW" then
        -- The framework sizes its alert using parent:GetSize(). Seed a separate
        -- owned frame with known dimensions before anchoring it to the bar.
        if type(DoesTemplateExist) ~= "function"
            or not (DoesTemplateExist("ActionButtonSpellAlertTemplate")
                or DoesTemplateExist("ActionBarButtonSpellActivationAlert")) then
            error("Spell-alert template unavailable")
        end
        local host = CreateFrame("Frame", nil, layer)
        host:SetSize(160, 20)
        renderer = df:CreateGlowOverlay(host)
        host:SetAllPoints(layer)
        renderer:ClearAllPoints()
        renderer:SetPoint("TOPLEFT", highlight.frame, "TOPLEFT", -8, 8)
        renderer:SetPoint("BOTTOMRIGHT", highlight.frame, "BOTTOMRIGHT", 8, -8)
        if renderer.ProcStartFlipbook then
            renderer.ProcStartFlipbook:ClearAllPoints()
            renderer.ProcStartFlipbook:SetAllPoints(renderer)
        end
        if not renderer.animIn and not renderer.ProcStartAnim then
            renderer:Hide()
            error("Spell-alert animation unavailable")
        end
    end
    if not renderer then error("Unknown effect") end
    renderer:SetFrameLevel(highlight.frame:GetFrameLevel() + 1)
    renderer:Hide()
    highlight.renderers[effect] = renderer
    return renderer
end


local function ConfigureLibraryEffect(h, effect, renderer)
    local controls = ns.CAST_ADVANCED_CONTROLS and ns.CAST_ADVANCED_CONTROLS[effect]
    local values = {}
    if controls then
        for _, control in ipairs(controls) do
            values[#values + 1] = tostring(Parameter(effect, control.key, control.default))
        end
    end
    local signature = table.concat(values, ":")
    if renderer.SNPConfiguration == signature then return end
    renderer.SNPConfiguration = signature
    local layer = h.effectHosts[effect]
    if effect == "SOLID" then
        Reanchor(renderer, layer, Parameter("SOLID", "distance", 0))
        renderer:SetBorderSizes(Parameter("SOLID", "thickness", 2),
            Parameter("SOLID", "minPixels", 2), Parameter("SOLID", "upward", 2),
            Parameter("SOLID", "upwardMin", 2))
        renderer:UpdateSizes()
    elseif effect == "SOFT" then
        Reanchor(layer, h.frame, Parameter("SOFT", "spread", 0))
        local size = Parameter("SOFT", "thickness", 2)
        for _, group in ipairs({layer.Borders.Layer1, layer.Borders.Layer2, layer.Borders.Layer3}) do
            for i, texture in ipairs(group) do
                if i == 1 or i == 3 then texture:SetWidth(size)
                else texture:SetHeight(size) end
            end
        end
        layer:SetBorderAlpha(Parameter("SOFT", "alpha1", 1),
            Parameter("SOFT", "alpha2", 0.55), Parameter("SOFT", "alpha3", 0.2))
        layer:SetLayerVisibility(Parameter("SOFT", "layer1", true),
            Parameter("SOFT", "layer2", true), Parameter("SOFT", "layer3", true))
    elseif effect == "ANTS" then
        local d = Parameter("ANTS", "distance", 3)
        renderer:SetOffset(-d, d, d, -d)
        renderer.frameTime = Parameter("ANTS", "frameTime", 0.025)
        renderer.frameCount = Parameter("ANTS", "frames", 22)
    elseif effect == "GLOW" then
        local x = Parameter("GLOW", "expandX", 8)
        local y = Parameter("GLOW", "expandY", 8)
        local dx = Parameter("GLOW", "offsetX", 0)
        local dy = Parameter("GLOW", "offsetY", 0)
        renderer:ClearAllPoints()
        renderer:SetPoint("TOPLEFT", h.frame, "TOPLEFT", dx-x, dy+y)
        renderer:SetPoint("BOTTOMRIGHT", h.frame, "BOTTOMRIGHT", dx+x, dy-y)
        if renderer.ProcStartFlipbook then
            renderer.ProcStartFlipbook:ClearAllPoints()
            renderer.ProcStartFlipbook:SetAllPoints(renderer)
        end
    end
end

local function ApplyRenderer(highlight)
    local effect = highlight.previewEffect or (ns.GetInterruptibleEffect and ns.GetInterruptibleEffect()) or "PULSE"
    if highlight.activeEffect ~= effect then StopRenderer(highlight) end
    highlight.activeEffect, highlight.rendererError = effect, nil
    local r, g, b = EffectColor("interruptible")
    if effect ~= "PULSE" then
        local ok, err = pcall(function()
            local renderer = FrameworkRenderer(highlight, effect)
            ConfigureLibraryEffect(highlight, effect, renderer)
            if effect == "SOLID" then renderer:SetVertexColor(r, g, b, 1)
            elseif effect == "SOFT" then renderer:SetBorderColor(r, g, b)
            elseif effect == "ANTS" then renderer.Texture:SetVertexColor(r, g, b, Parameter("ANTS", "opacity", 1))
            else renderer:SetColor({r, g, b, Parameter("GLOW", "antsAlpha", 1)},
                {r, g, b, Parameter("GLOW", "glowAlpha", 1)}) end
            highlight.effectHosts[effect]:Show()
            local wasShown = renderer:IsShown()
            renderer:Show()
            if renderer.Play and not wasShown then renderer:Play() end
        end)
        if ok then return end
        StopRenderer(highlight)
        highlight.rendererError = tostring(err)
        highlight.failedEffects = highlight.failedEffects or {}
        highlight.failedEffects[effect] = highlight.rendererError
        -- Keep an obvious indicator if a winning external DF copy or the
        -- client's template lacks the requested effect. Diagnostics explains it.
        highlight.activeEffect = "PULSE"
    end
    ConfigurePulse(highlight)
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
    local shown = ns.AccessibleBoolean(Capabilities.ReadRegion(highlight and highlight.castBar, "IsShown", context))
    if shown == false then return false, "cast bar hidden" end
    if shown == nil then return nil, "cast visibility unavailable" end
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
        if state == nil and highlight.owner then DeferFrame(highlight.owner) end
    end
end

local function InstallRegionHook(highlight, region, registry)
    if not region then return false end
    highlight[registry] = highlight[registry] or setmetatable({}, {__mode = "k"})
    if highlight[registry][region] then return true end

    local overlay = highlight.frame
    local function Changed()
        local context = GetContext()
        if not CanAccessFrame(highlight.owner, context) then
            DeferFrame(highlight.owner)
            return
        end
        if highlight.owner.SNPInterruptibleHighlight ~= highlight then overlay:Hide(); return end
        local bar = highlight.castBar
        local icon = Capabilities.SafeField(bar, "Icon", context)
        local shield = Capabilities.SafeField(bar, "BorderShield", context)
        if region ~= bar and region ~= icon and region ~= shield then return end
        RefreshHighlight(highlight, context, highlight.owner.SNPPresentation)
    end
    local ok = true
    for _, method in ipairs({"SetShown", "Show", "Hide"}) do
        if type(Capabilities.SafeField(region, method, GetContext())) == "function" then
            local installed = pcall(hooksecurefunc, region, method, Changed)
            ok = ok and installed
        end
    end
    if ok then highlight[registry][region] = true end
    return ok
end

local function InstallInterruptibleHighlightHooks(highlight)
    local bar = highlight and highlight.castBar
    if not bar then return end
    local context = GetContext()
    InstallRegionHook(highlight, Capabilities.SafeField(bar, "Icon", context), "hookedIcons")
    InstallRegionHook(highlight, Capabilities.SafeField(bar, "BorderShield", context), "hookedShields")
    InstallRegionHook(highlight, bar, "hookedBars")
    if not highlight.barVisibilityHooked then
        local function Changed()
            local context = GetContext()
            if highlight.owner.SNPInterruptibleHighlight ~= highlight then highlight.frame:Hide(); return end
            if not CanAccessFrame(highlight.owner, context) then DeferFrame(highlight.owner); return end
            RefreshHighlight(highlight, context, highlight.owner.SNPPresentation)
        end
        local ok = pcall(function()
            bar:HookScript("OnShow", Changed)
            bar:HookScript("OnHide", Changed)
        end)
        highlight.barVisibilityHooked = ok
    end
end

local function CreateHighlight(castBar, owner, healthBar)
    local overlay = CreateFrame("Frame", nil, castBar)
    overlay:SetPoint("TOPLEFT", castBar, "TOPLEFT", -5, 5)
    overlay:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 5, -5)
    local highestFrameLevel = castBar:GetFrameLevel()
    if healthBar then highestFrameLevel = math.max(highestFrameLevel, healthBar:GetFrameLevel()) end
    overlay:SetFrameLevel(highestFrameLevel + 20)
    overlay:Hide()

    local highlight = {
        castBar = castBar,
        owner = owner,
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
    highlight.pulse, highlight.fadeOut, highlight.fadeIn = pulse, fadeOut, fadeIn

    overlay:SetScript("OnShow", function() ApplyRenderer(highlight) end)
    overlay:SetScript("OnHide", function() StopRenderer(highlight) end)
    return highlight
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
    local highlight = CreateHighlight(castBar, frame, GetHealthBar(frame, context))
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
    UpdatePreview = function(bar, effect)
        if not bar.SNPCastPreview then bar.SNPCastPreview = CreateHighlight(bar) end
        bar.SNPCastPreview.previewEffect = effect
        bar.SNPCastPreview.frame:Show()
        ApplyRenderer(bar.SNPCastPreview)
    end,
    StopPreview = function(bar)
        if bar and bar.SNPCastPreview then bar.SNPCastPreview.frame:Hide() end
    end,
}

