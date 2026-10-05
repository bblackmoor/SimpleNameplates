-- Verify fixed tint geometry, native clipping, exact threshold and secret-alpha sinks.
local ui = dofile("tests/details-framework-ui-stubs.lua")
function hooksecurefunc(object, method, callback)
    local original = object[method]
    object[method] = function(self, ...)
        original(self, ...)
        callback(self, ...)
    end
end
local enabled = true
local ns = {GetGradientEnabled = function() return enabled end,
    GetAppearanceSetting = function() return false end,
    WorldContext = {Get = function() return {} end},
    PresentationCapabilities = {
        ObjectStatus = function(object) return object and not object.blocked and "accessible" or "forbidden" end,
        ReadRegion = function(object, method) return object[method](object) end,
    }}
for _, file in ipairs({"Core", "FontRendering", "HealthGradient", "TextUnderlayers"}) do
    assert(loadfile("SimpleNameplates/" .. file .. ".lua"))("SimpleNameplates", ns)
end
local creates = 0
Enum.LuaCurveType = {Step = 1}
C_CurveUtil = {CreateCurve = function()
    creates = creates + 1
    local curve = {points = {}}
    function curve:SetType(value) self.kind = value end
    function curve:AddPoint(x, y) self.points[#self.points + 1] = {x, y} end
    function curve:Evaluate(x)
        assert(self.kind == Enum.LuaCurveType.Step)
        local value = 0
        for _, point in ipairs(self.points) do if x >= point[1] then value = point[2] end end
        return value
    end
    return curve
end}
local health = 1
function UnitHealth() error("health arithmetic is forbidden") end
function UnitHealthMax() error("health arithmetic is forbidden") end
function UnitHealthPercent(unit, predicted, curve)
    assert(unit == "nameplate1" and predicted == false)
    return curve:Evaluate(health)
end
local bar = CreateFrame("StatusBar")
bar:SetWidth(200)
bar:SetStatusBarTexture("native")
local fill = bar:GetStatusBarTexture()
ns.HealthGradient.Apply(bar, fill, {})
local tint, mask = bar.SNPHealthGradient, bar.SNPHealthGradientMask
assert(tint.width == 200, "fixed fade occupies the full bar width")
assert(tint.gradient[1] == "HORIZONTAL" and tint.gradient[2].a == 0.9 and tint.gradient[3].a == 0)
assert(tint.mask == mask and mask.allPoints == fill, "clip follows native remaining fill geometry")
for _, remainingWidth in ipairs({200, 160, 100, 20}) do
    fill:SetWidth(remainingWidth)
    assert(tint.width == 200 and mask.allPoints == fill, "native health loss cannot rescale gradient")
end
local replacement = bar:CreateTexture()
ns.HealthGradient.Apply(bar, replacement, {})
assert(mask.allPoints == replacement and bar.SNPHealthGradient == tint, "replacement fill reuses/reanchors tint")
bar:SetWidth(250)
ns.HealthGradient.Apply(bar, replacement, {})
assert(tint.width == 250, "configured width scales full gradient")
enabled = false
ns.HealthGradient.Apply(bar, replacement, {})
assert(not tint:IsShown() and ns.HealthGradient.ThreatLayers("nameplate1") == nil)
enabled = true
ns.HealthGradient.Apply(bar, replacement, {})
assert(tint:IsShown())
local text = bar:CreateFontString()
text:SetFont("font", 18, "")
text:SetText("255%")
text:Show()
for _, case in ipairs({{1, 1}, {0.8, 1}, {0.799999, 0}, {0.1, 0}, {0, 0}, {0.8, 1}}) do
    health = case[1]
    ns.TextUnderlayers.Update(text, bar, ns.HealthGradient.ThreatLayers("nameplate1"))
    for _, layer in ipairs(text.SNPUnderlayers) do assert(layer.alpha == case[2]) end
end
assert(creates == 1, "threshold curve is cached")
local secretAlpha = setmetatable({}, {__tostring = function() error("secret inspected") end})
function UnitHealthPercent() return secretAlpha end
function issecretvalue(value) return rawequal(value, secretAlpha) end
ns.TextUnderlayers.Update(text, bar, ns.HealthGradient.ThreatLayers("nameplate1"))
for _, layer in ipairs(text.SNPUnderlayers) do assert(rawequal(layer.alpha, secretAlpha)) end
text:SetText("200%") -- Sync must preserve the secret alpha through native updates.
for _, layer in ipairs(text.SNPUnderlayers) do
    assert(layer.text == "200%" and rawequal(layer.alpha, secretAlpha))
end
ns.TextUnderlayers.Update(text, bar, ns.HealthGradient.ThreatLayers("nameplate1"))
for _, layer in ipairs(text.SNPUnderlayers) do assert(rawequal(layer.alpha, secretAlpha)) end
function UnitHealthPercent() error("API temporarily blocked") end
ns.TextUnderlayers.Update(text, bar, ns.HealthGradient.ThreatLayers("nameplate1"))
for _, layer in ipairs(text.SNPUnderlayers) do assert(layer.alpha == 1, "failed curve keeps readable threat") end
enabled = false
ns.TextUnderlayers.Update(text, bar, ns.HealthGradient.ThreatLayers("nameplate1"))
for _, layer in ipairs(text.SNPUnderlayers) do assert(layer.alpha == 1) end
ns.HealthGradient.Hide(bar)
assert(not tint:IsShown(), "restoration hides tint")
print("Health gradient smoke: passed")
