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

local function RestoreBarWidth(frame, assessment)
    local bar = frame.SNPOriginalHealthBar or assessment.healthBar
    local container = frame.SNPOriginalHealthBarsContainer or frame.HealthBarsContainer
    if bar and frame.SNPOriginalBarWidth then
        bar:SetWidth(frame.SNPOriginalBarWidth)
    end
    if container and frame.SNPOriginalContainerWidth then
        container:SetWidth(frame.SNPOriginalContainerWidth)
    end
    frame.SNPOriginalBarWidth, frame.SNPOriginalContainerWidth = nil, nil
    frame.SNPBarWidth, frame.SNPContainerWidth = nil, nil
end

local function ApplyBarWidth(frame, assessment, context)
    local percent = ns.GetAppearanceSetting("healthBarWidth") or 100
    if percent == 100 then RestoreBarWidth(frame, assessment); return end
    for _, item in ipairs({
        {assessment.healthBar, "SNPOriginalBarWidth", "SNPBarWidth"},
        {frame.HealthBarsContainer, "SNPOriginalContainerWidth", "SNPContainerWidth"},
    }) do
        local region, originalKey, expectedKey = item[1], item[2], item[3]
        if region and not frame[originalKey] then
            local width = ns.AccessibleNumber(Capabilities.ReadRegion(region, "GetWidth", context))
            if width and width > 0 then frame[originalKey] = width end
        end
        if region and frame[originalKey] then
            frame[expectedKey] = frame[originalKey] * percent / 100
            region:SetWidth(frame[expectedKey])
        end
    end
end

-- Keep native progress/value logic; replace only the decorative artwork.
local function ReadValues(region, method, context, ...)
    local fn = Capabilities.SafeField(region, method, context)
    if type(fn) ~= "function" then return nil end
    local values = {pcall(fn, region, ...)}
    if not values[1] then return nil end
    table.remove(values, 1)
    for index, value in ipairs(values) do
        values[index] = ns.AccessibleValue(value)
        if values[index] == nil then return nil end
    end
    return values
end

local function OriginalArtwork(frame, region, context)
    if Capabilities.ObjectStatus(region, context) ~= "accessible" then return nil end
    local originals = frame.SNPOriginalArtwork or {}
    frame.SNPOriginalArtwork = originals
    local original = originals[region]
    if not original then
        original = {}
        originals[region] = original
    end
    return original
end

local function RemoveArtworkEdge(frame, region, context)
    local original = OriginalArtwork(frame, region, context)
    if not original then return end
    if original.alpha == nil then
        original.alpha = ns.AccessibleNumber(Capabilities.ReadRegion(region, "GetAlpha", context))
    end
    if original.alpha ~= nil then region:SetAlpha(0) end
end

local function FlattenFill(frame, region, context)
    local original = OriginalArtwork(frame, region, context)
    if not original then return end
    if not original.fill then
        local atlas = Capabilities.ReadRegion(region, "GetAtlas", context)
        local texture = Capabilities.ReadRegion(region, "GetTexture", context)
        local coords = ReadValues(region, "GetTexCoord", context)
        if not atlas and not texture then return end
        original.fill = {atlas = atlas, texture = texture, coords = coords}
    end
    region:SetTexture("Interface\\Buttons\\WHITE8X8")
    region:SetTexCoord(0, 1, 0, 1)
end

local function StyleNativeTextOutline(frame, region, context, inside)
    local original = OriginalArtwork(frame, region, context)
    if not original then return end
    if not original.font then
        local font = ReadValues(region, "GetFont", context)
        if not font or type(font[1]) ~= "string" or type(font[2]) ~= "number" then return end
        original.font = font
        original.shadowColor = ReadValues(region, "GetShadowColor", context)
        original.shadowOffset = ReadValues(region, "GetShadowOffset", context)
        if inside then original.drawLayer = ReadValues(region, "GetDrawLayer", context) end
    end
    region:SetFont(original.font[1], original.font[2], ns.FontFlags(not inside))
    region:SetShadowColor(0, 0, 0, 0)
    region:SetShadowOffset(0, 0)
end

local function StyleHealthText(frame, region, context, bar)
    local original = OriginalArtwork(frame, region, context)
    if not original then return end
    StyleNativeTextOutline(frame, region, context, true)
    if original.points == nil then
        local count = ns.AccessibleNumber(Capabilities.ReadRegion(region, "GetNumPoints", context))
        if count then
            local points = {}
            for index = 1, count do
                local values = ReadValues(region, "GetPoint", context, index)
                if not values or type(values[4]) ~= "number" or type(values[5]) ~= "number" then
                    points = nil; break
                end
                points[#points + 1] = values
            end
            original.points = points
        end
    end
    if original.points then
        region:ClearAllPoints()
        for _, point in ipairs(original.points) do
            region:SetPoint(point[1], point[2], point[3], point[4], point[5] - 0.5)
        end
    end
    if not original.textColor then
        original.textColor = ReadValues(region, "GetTextColor", context)
        original.vertexColor = ReadValues(region, "GetVertexColor", context)
    end
    if ns.HealthGradient and ns.HealthGradient.Enabled() then
        region:SetDrawLayer("OVERLAY", 7)
        ns.TextUnderlayers.Hide(region)
    else
        ns.TextUnderlayers.Update(region, bar)
    end
    if original.textColor then
        region:SetTextColor(1, 1, 1, 1)
        if original.vertexColor then region:SetVertexColor(1, 1, 1, 1) end
    end
end

-- Right-to-left order matches Blizzard's percentage/value/single-text labels.
-- Anchors follow label regions, so secret or changing text widths need no reads.
local function HealthTextLayoutState(frame, bar, context)
    local labels, signature = {}, ""
    local threat
    if bar and frame.SNPThreatTextBar == bar
        and frame.SNPThreatStatus == "displayed scaled percentage" then
        threat = frame.SNPThreatText
    end
    signature = threat and "T" or "-"
    for _, key in ipairs({"LeftText", "RightText", "Text"}) do
        local region = Capabilities.SafeField(bar, key, context)
        if Capabilities.ObjectStatus(region, context) ~= "accessible" then region = nil end
        local original = frame.SNPOriginalArtwork and frame.SNPOriginalArtwork[region]
        local shown = ns.AccessibleBoolean(Capabilities.ReadRegion(region, "IsShown", context))
        -- Preserve space for unknown visibility; do not inspect restricted text.
        local included = region and original and original.points and shown ~= false
        signature = signature .. (included and "1" or "0")
        if included then labels[#labels + 1] = region end
    end
    return labels, threat, signature
end

local function GetHealthTextInsetRegion(frame, bar, context)
    local labels, threat, signature = HealthTextLayoutState(frame, bar, context)
    return labels[#labels] or threat, signature
end

local function LayoutHealthText(frame, bar, context)
    local labels, threat = HealthTextLayoutState(frame, bar, context)
    local previous = threat
    if threat then
        threat:ClearAllPoints()
        threat:SetPoint("RIGHT", bar, "RIGHT", -3, -0.5)
    end
    for _, region in ipairs(labels) do
        region:ClearAllPoints()
        region:SetPoint("RIGHT", previous or bar, previous and "LEFT" or "RIGHT", -3, previous and 0 or -0.5)
        previous = region
    end
    return GetHealthTextInsetRegion(frame, bar, context)
end

local function FlattenBar(frame, bar, backgroundKey, context)
    if Capabilities.ObjectStatus(bar, context) ~= "accessible" then return end
    RemoveArtworkEdge(frame, Capabilities.SafeField(bar, backgroundKey, context), context)
    local fill = Capabilities.SafeField(bar, "barTexture", context)
        or Capabilities.ReadRegion(bar, "GetStatusBarTexture", context)
    FlattenFill(frame, fill, context)
    local background = bar.SNPPlainBackground
    if not background and type(bar.CreateTexture) == "function" then
        background = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
        background:SetAllPoints(bar)
        background:SetColorTexture(0, 0, 0, 0.4)
        bar.SNPPlainBackground = background
    end
    if background then
        frame.SNPPlainBackgrounds = frame.SNPPlainBackgrounds or {}
        frame.SNPPlainBackgrounds[background] = true
        background:Show()
    end
end

local function InstallArtworkHooks(frame, bar, context)
    if Capabilities.ObjectStatus(bar, context) ~= "accessible" then return end
    if bar.SNPArtworkHookOwner == frame then return end
    local function Refresh()
        if frame.SNPRestoring or frame.SNPApplyingStyle or frame.SNPApplyingArtwork
            or not frame.SNPOriginalArtwork then return end
        local current = ns.WorldContext.Get()
        local assessment = Capabilities.InspectFrame(frame, current)
        if assessment.canAccess then ns.NameplateFrames.ApplyBarArtwork(frame, assessment, current) end
    end
    if type(bar.HookScript) == "function" then bar:HookScript("OnShow", Refresh) end
    if hooksecurefunc and type(bar.ApplyStyleAndAnchoring) == "function" then
        hooksecurefunc(bar, "ApplyStyleAndAnchoring", Refresh)
    end
    bar.SNPArtworkHookOwner = frame
end

local function ApplyArtwork(frame, assessment, context)
    local healthBar, castBar = assessment.healthBar, assessment.castBar
    InstallArtworkHooks(frame, healthBar, context)
    InstallArtworkHooks(frame, castBar, context)
    FlattenBar(frame, healthBar, "bgTexture", context)
    if ns.HealthGradient then
        local fill = Capabilities.SafeField(healthBar, "barTexture", context)
            or Capabilities.ReadRegion(healthBar, "GetStatusBarTexture", context)
        ns.HealthGradient.Apply(healthBar, fill, context)
        if healthBar then
            frame.SNPGradientBars = frame.SNPGradientBars or {}
            frame.SNPGradientBars[healthBar] = true
        end
    end
    for _, key in ipairs({"Text", "RightText", "LeftText"}) do
        StyleHealthText(frame, Capabilities.SafeField(healthBar, key, context), context, healthBar)
    end
    -- Blizzard keeps absorb fill/prediction visible; suppress only its bright
    -- right-edge overflow marker. Retail owns it on the bar; legacy frames
    -- may expose the region directly.
    RemoveArtworkEdge(frame, Capabilities.SafeField(healthBar, "overAbsorbGlow", context), context)
    RemoveArtworkEdge(frame, Capabilities.SafeField(frame, "overAbsorbGlow", context), context)
    for _, key in ipairs({"selectedBorder", "deselectedOverlay"}) do
        RemoveArtworkEdge(frame, Capabilities.SafeField(healthBar, key, context), context)
    end
    FlattenBar(frame, castBar, "Background", context)
    for _, key in ipairs({"Border", "TextBorder", "DropShadow"}) do
        RemoveArtworkEdge(frame, Capabilities.SafeField(castBar, key, context), context)
    end
    for _, key in ipairs({"Text", "CastTargetNameText"}) do
        StyleNativeTextOutline(frame, Capabilities.SafeField(castBar, key, context), context)
    end
    LayoutHealthText(frame, healthBar, context)
end

-- Artwork hooks can also fire while a bar or its labels are being changed.
local function ApplyBarArtwork(frame, assessment, context)
    if frame.SNPRestoring or frame.SNPApplyingArtwork then return end
    frame.SNPApplyingArtwork = true
    local ok, err = pcall(ApplyArtwork, frame, assessment, context)
    frame.SNPApplyingArtwork = nil
    if not ok then error(err, 0) end
end

local unpackValues = unpack or table.unpack
local function RestoreBarArtwork(frame, context)
    for region, original in pairs(frame.SNPOriginalArtwork or {}) do
        if Capabilities.ObjectStatus(region, context) ~= "accessible" then
            error("Bar artwork restoration is temporarily inaccessible")
        end
        ns.TextUnderlayers.Hide(region)
        if original.drawLayer then region:SetDrawLayer(unpackValues(original.drawLayer)) end
        if original.alpha ~= nil then region:SetAlpha(original.alpha) end
        if original.fill then
            if original.fill.atlas then region:SetAtlas(original.fill.atlas)
            else region:SetTexture(original.fill.texture) end
            if original.fill.coords then region:SetTexCoord(unpackValues(original.fill.coords)) end
        end
        if original.textColor then region:SetTextColor(unpackValues(original.textColor)) end
        if original.vertexColor then region:SetVertexColor(unpackValues(original.vertexColor)) end
        if original.points then
            region:ClearAllPoints()
            for _, point in ipairs(original.points) do region:SetPoint(unpackValues(point)) end
        end
        if original.font then
            region:SetFont(original.font[1], original.font[2], original.font[3] or "")
            if original.shadowColor then region:SetShadowColor(unpackValues(original.shadowColor)) end
            if original.shadowOffset then region:SetShadowOffset(unpackValues(original.shadowOffset)) end
        end
    end
    for region in pairs(frame.SNPPlainBackgrounds or {}) do
        if Capabilities.ObjectStatus(region, context) ~= "accessible" then
            error("Plain bar background restoration is temporarily inaccessible")
        end
        region:Hide()
    end
    for bar in pairs(frame.SNPGradientBars or {}) do
        if Capabilities.ObjectStatus(bar, context) ~= "accessible" then
            error("Gradient restoration is temporarily inaccessible")
        end
        ns.HealthGradient.Hide(bar)
    end
    frame.SNPGradientBars = nil
    frame.SNPOriginalArtwork, frame.SNPPlainBackgrounds = nil, nil
end

ns.NameplateFrames = {
    ApplyBarWidth = ApplyBarWidth, RestoreBarWidth = RestoreBarWidth,
    LayoutHealthText = LayoutHealthText, GetHealthTextInsetRegion = GetHealthTextInsetRegion,
    ApplyBarArtwork = ApplyBarArtwork, RestoreBarArtwork = RestoreBarArtwork,
    GetUnitFrame = GetUnitFrame, GetFrameFromPlate = GetFrameFromPlate,
    GetHealthBar = GetHealthBar, GetCastBar = GetCastBar, SetShownSafe = SetShownSafe,
}
