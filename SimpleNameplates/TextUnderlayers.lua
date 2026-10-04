-- Simple Nameplates: two black glyph copies behind inside-bar text.
local _, ns = ...
local offsets = {{1, -2}, {2, -1}}

local function Read(text, method)
    local getter = text[method]
    if type(getter) ~= "function" then return nil end
    local ok, value = pcall(getter, text)
    if ok then return value end -- Text may be secret; only pass it to SetText.
end

local function Hide(text)
    if not text then return end
    text.SNPUnderlayersActive = nil
    for _, layer in ipairs(text.SNPUnderlayers or {}) do layer:Hide() end
end

local function Sync(text)
    if not text.SNPUnderlayersActive then return end
    local context = ns.WorldContext.Get()
    if ns.PresentationCapabilities.ObjectStatus(text, context) ~= "accessible" then return end
    local font, size = text:GetFont()
    font, size = ns.AccessibleValue(font), ns.AccessibleNumber(size)
    if not font or not size then return end
    local shown = ns.AccessibleBoolean(Read(text, "IsShown"))
    local alpha = ns.AccessibleNumber(Read(text, "GetAlpha")) or 1
    local justify = ns.AccessibleValue(Read(text, "GetJustifyH")) or "LEFT"
    local justifyV = ns.AccessibleValue(Read(text, "GetJustifyV")) or "MIDDLE"
    local value = Read(text, "GetText")
    for _, layer in ipairs(text.SNPUnderlayers) do
        layer:SetFont(font, size, "")
        layer:SetJustifyH(justify)
        layer:SetJustifyV(justifyV)
        layer:SetText(value)
        layer:SetAlpha(alpha)
        if shown == true then layer:Show() else layer:Hide() end
    end
end

local function Update(text, parent)
    if not text then return end
    if not text.SNPUnderlayers then
        local layers = {}
        for index, offset in ipairs(offsets) do
            local layer = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            layer:SetDrawLayer("OVERLAY", index + 4)
            layer:SetPoint("TOPLEFT", text, "TOPLEFT", offset[1], offset[2])
            layer:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", offset[1], offset[2])
            layer:SetTextColor(0, 0, 0, 1)
            layer:SetShadowColor(0, 0, 0, 0)
            layer:SetShadowOffset(0, 0)
            layer:SetWordWrap(false)
            layer:SetMaxLines(1)
            layers[index] = layer
        end
        text.SNPUnderlayers = layers
        -- Native health labels can change without a full addon styling pass.
        if hooksecurefunc then
            for _, method in ipairs({"SetText", "SetFormattedText", "SetFont", "SetJustifyH", "SetJustifyV", "SetAlpha", "Show", "Hide", "SetShown"}) do
                if type(text[method]) == "function" then
                    hooksecurefunc(text, method, function() Sync(text) end)
                end
            end
        end
    end
    text.SNPUnderlayersActive = true
    text:SetDrawLayer("OVERLAY", 7)
    text:SetShadowColor(0, 0, 0, 0)
    text:SetShadowOffset(0, 0)
    Sync(text)
end

ns.TextUnderlayers = {Update = Update, Hide = Hide}
