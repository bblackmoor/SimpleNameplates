-- Fixed-position health tint, clipped by native fill geometry; no health arithmetic.
local _, ns = ...
local FADE_END = 0.8
local threatCurve

local function Enabled()
    return ns.GetGradientEnabled and ns.GetGradientEnabled() == true
end

local function Hide(bar)
    if bar and bar.SNPHealthGradient then bar.SNPHealthGradient:Hide() end
end

local function Apply(bar, fill, context)
    if not bar then return end
    local cap = ns.PresentationCapabilities
    if cap.ObjectStatus(bar, context) ~= "accessible" then return end
    if not Enabled() then Hide(bar); return end
    if cap.ObjectStatus(fill, context) ~= "accessible" then Hide(bar); return end
    local width = ns.AccessibleNumber(cap.ReadRegion(bar, "GetWidth", context))
    if not width or width <= 0 then Hide(bar); return end
    if not bar.SNPHealthGradient then
        -- Native fill anchors resolve in the renderer even with secret health.
        -- The tint spans a fixed 80% of total width; the mask alone shrinks.
        local mask = bar:CreateMaskTexture(nil, "ARTWORK")
        mask:SetTexture("Interface\\Buttons\\WHITE8X8", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        local tint = bar:CreateTexture(nil, "ARTWORK", nil, 3)
        tint:SetTexture("Interface\\Buttons\\WHITE8X8")
        tint:SetGradient("HORIZONTAL", CreateColor(0, 0, 0, 0.9), CreateColor(0, 0, 0, 0))
        tint:AddMaskTexture(mask)
        tint:SetPoint("TOPLEFT", bar, "TOPLEFT")
        tint:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
        bar.SNPHealthGradient, bar.SNPHealthGradientMask = tint, mask
    end
    bar.SNPHealthGradientMask:ClearAllPoints()
    bar.SNPHealthGradientMask:SetAllPoints(fill)
    bar.SNPHealthGradient:SetWidth(width * FADE_END)
    bar.SNPHealthGradient:Show()
end

local function ThreatLayers(unit)
    if not Enabled() then return nil end
    -- Failure leaves the threat outline on, so text remains readable.
    if not UnitHealthPercent or not C_CurveUtil or not Enum or not Enum.LuaCurveType then
        return {alpha = 1}
    end
    if not threatCurve then
        threatCurve = C_CurveUtil.CreateCurve()
        threatCurve:SetType(Enum.LuaCurveType.Step)
        threatCurve:AddPoint(0, 0)
        threatCurve:AddPoint(FADE_END, 1)
        threatCurve:AddPoint(1, 1)
    end
    local ok, alpha = pcall(UnitHealthPercent, unit, false, threatCurve)
    if not ok then return {alpha = 1} end
    if not (issecretvalue and issecretvalue(alpha)) and ns.AccessibleNumber(alpha) == nil then
        return {alpha = 1}
    end
    -- Never inspect, compare, or calculate with the potentially secret result.
    return {alpha = alpha}
end

ns.HealthGradient = {Enabled = Enabled, Apply = Apply, Hide = Hide, ThreatLayers = ThreatLayers}
