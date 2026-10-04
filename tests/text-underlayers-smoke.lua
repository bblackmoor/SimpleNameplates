-- Verify native synchronization, exact offsets, reuse, and secret text safety.
local ns = {}
local slug = false
ns.GetAppearanceSetting = function(key) return key == "useSlugRendering" and slug end
assert(loadfile("SimpleNameplates/FontRendering.lua"))("SimpleNameplates", ns)
local secret = setmetatable({}, {__tostring = function() error("secret inspected") end})
function issecretvalue(value) return rawequal(value, secret) end
assert(loadfile("SimpleNameplates/Core.lua"))("SimpleNameplates", ns)
ns.WorldContext = {Get = function() return {} end}
ns.PresentationCapabilities = {ObjectStatus = function() return "accessible" end}
function hooksecurefunc(object, method, callback)
    local original = object[method]
    object[method] = function(self, ...)
        original(self, ...)
        callback(self, ...)
    end
end
local function Text()
    local t = {font = "font", size = 21, shown = true, alpha = 1, justify = "RIGHT", justifyV = "MIDDLE"}
    function t:GetFont() return self.font, self.size, self.flags end
    function t:SetFont(font, size, flags) self.font, self.size, self.flags = font, size, flags end
    function t:GetText() return self.text end
    function t:SetText(value) self.text = value end
    function t:SetFormattedText(_, value) self.text = value end
    function t:GetAlpha() return self.alpha end
    function t:SetAlpha(value) self.alpha = value end
    function t:GetJustifyH() return self.justify end
    function t:SetJustifyH(value) self.justify = value end
    function t:GetJustifyV() return self.justifyV end
    function t:SetJustifyV(value) self.justifyV = value end
    function t:IsShown() return self.shown end
    function t:Show() self.shown = true end
    function t:Hide() self.shown = false end
    function t:SetShown(value) self.shown = value end
    function t:SetDrawLayer(layer, sublevel) self.layer, self.sublevel = layer, sublevel end
    function t:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function t:SetTextColor(...) self.color = {...} end
    function t:SetShadowColor(...) self.shadow = {...} end
    function t:SetShadowOffset(...) self.shadowOffset = {...} end
    function t:SetWordWrap() end
    function t:SetMaxLines() end
    return t
end
local created = 0
local parent = {CreateFontString = function() created = created + 1; return Text() end}
local source = Text()
source:SetText("White label")
assert(loadfile("SimpleNameplates/TextUnderlayers.lua"))("SimpleNameplates", ns)
ns.TextUnderlayers.Update(source, parent)
assert(created == 2 and source.sublevel == 7)
for index, expected in ipairs({{1, -2}, {2, -1}}) do
    local layer = source.SNPUnderlayers[index]
    assert(layer.color[1] == 0 and layer.color[2] == 0 and layer.color[3] == 0 and layer.color[4] == 1)
    assert(layer.text == "White label" and layer.flags == "" and layer.shadow[4] == 0)
    assert(layer.sublevel < source.sublevel and layer.justify == "RIGHT")
    for _, point in ipairs(layer.points) do
        assert(point[2] == source and point[4] == expected[1] and point[5] == expected[2])
    end
end
source:SetFormattedText("%s", secret)
for _, layer in ipairs(source.SNPUnderlayers) do assert(rawequal(layer.text, secret), "secret only forwarded to text API") end
source:SetFont("changed-font", 30, "")
source:SetAlpha(0.5)
source:SetJustifyH("CENTER")
for _, layer in ipairs(source.SNPUnderlayers) do
    assert(layer.font == "changed-font" and layer.size == 30 and layer.alpha == 0.5 and layer.justify == "CENTER")
end
source:Hide()
for _, layer in ipairs(source.SNPUnderlayers) do assert(not layer.shown) end
source:Show()
for _, layer in ipairs(source.SNPUnderlayers) do assert(layer.shown) end
ns.TextUnderlayers.Update(source, parent)
assert(created == 2, "repeated refresh reuses exactly two layers")
slug = true
ns.TextUnderlayers.Update(source, parent)
for _, layer in ipairs(source.SNPUnderlayers) do assert(layer.flags == "SLUG", "underlayers share Slug rendering") end
slug = false
ns.TextUnderlayers.Update(source, parent)
for _, layer in ipairs(source.SNPUnderlayers) do assert(layer.flags == "", "ordinary rendering returns without new layers") end
ns.TextUnderlayers.Hide(source)
source:SetText("Native label")
source:Show()
for _, layer in ipairs(source.SNPUnderlayers) do assert(not layer.shown, "disabled layers cannot revive") end
print("Text underlayers smoke: passed")
