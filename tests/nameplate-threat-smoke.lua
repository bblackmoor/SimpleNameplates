-- Verify threat rendering, including opaque values passed only to WoW.
local function equal(actual, expected, label)
    assert(actual == expected, label)
end
local secret = setmetatable({}, {__tostring = function() error("secret inspected") end})
function issecretvalue(value) return rawequal(value, secret) end
local raw, scaled, fail = 73.4, 55, false
function UnitDetailedThreatSituation(who, unit)
    equal(who, "player", "player threat requested")
    equal(unit, "nameplate1", "current frame unit requested")
    if fail then error("unavailable") end
    return false, 1, scaled, raw
end
local enabled, accessible = true, true
local nameSize = 21
local function Bar()
    local bar = {}
    function bar:CreateFontString(_, layer, template)
        equal(layer, "OVERLAY", "threat uses overlay")
        equal(template, "GameFontNormal", "threat starts with valid font")
        local text = {bar = self}
        function text:GetFont() return self.font, self.size, self.flags end
        function text:GetText() return self.text end
        function text:IsShown() return self.shown end
        function text:SetAlpha(value) self.alpha = value end
        function text:SetJustifyV() end
        function text:SetDrawLayer(_, level) self.drawLevel = level end
        function text:SetPoint() end
        function text:SetJustifyH() end
        function text:SetWordWrap() end
        function text:SetMaxLines() end
        function text:SetTextColor(r, g, b) self.r, self.g, self.b = r, g, b end
        function text:SetFont(font, size, flags) self.font, self.size, self.flags = font, size, flags end
        function text:SetShadowColor(_, _, _, alpha) self.shadowAlpha = alpha end
        function text:SetShadowOffset(x, y) self.shadowX, self.shadowY = x, y end
        function text:SetText(value) self.text = value end
        function text:SetFormattedText(format, value)
            self.argument = value
            if issecretvalue(value) then self.text = "engine renders opaque percentage"
            else self.text = format:format(value) end
        end
        function text:Show() self.shown = true end
        function text:Hide() self.shown = false end
        return text
    end
    return bar
end
local frame = {unit = "nameplate1", healthBar = Bar()}
local ns = {
    PresentationCapabilities = {CanAccessFrame = function() return accessible end, ObjectStatus = function() return "accessible" end},
    AccessibleValue = function(value) return value end,
    AccessibleBoolean = function(value) return value end,
    WorldContext = {Get = function() return {} end},
    AccessibleNumber = function(value)
        assert(not issecretvalue(value), "opaque percentage must bypass numeric inspection")
        if type(value) == "number" then return value end
    end,
    FontPath = function() return "Fonts\\ARIALN.TTF" end,
    GetAppearanceSetting = function(key) return key == "nameSize" and nameSize or "ARIALN" end,
    GetThreatEnabled = function() return enabled end,
    NameplateFrames = {GetHealthBar = function(value) return value.healthBar end},
}
assert(loadfile("SimpleNameplates/TextUnderlayers.lua"))("SimpleNameplates", ns)
assert(loadfile("SimpleNameplates/NameplateThreat.lua"))("SimpleNameplates", ns)
local function Update(showBar)
    ns.NameplateThreat.UpdateThreatText(frame, "hostile", {}, {showHealthBar = showBar})
end
Update(true)
equal(frame.SNPThreatText.text, "73%", "raw percentage preferred")
equal(frame.SNPThreatText.shown, true, "percentage explicitly shown")
equal(frame.SNPThreatText.drawLevel, 7, "percentage drawn above bar artwork")
equal(frame.SNPThreatText.r, 1, "threat stays white")
equal(frame.SNPThreatText.size, 21, "threat matches default name size")
equal(frame.SNPThreatText.flags, "", "threat has no outline")
equal(frame.SNPThreatText.shadowAlpha, 0, "native threat shadow disabled")
equal(frame.SNPThreatText.shadowX, 0, "native shadow x cleared")
equal(frame.SNPThreatText.shadowY, 0, "native shadow y cleared")
equal(frame.SNPThreatText.font, "Fonts\\ARIALN.TTF", "separate threat font retained")
nameSize = 36
Update(true)
equal(frame.SNPThreatText.r, 1, "threat remains white after size change")
equal(frame.SNPThreatText.size, 36, "threat follows changed name size")
raw = 0
Update(true)
equal(frame.SNPThreatText.text, "0%", "readable zero displayed")
raw = nil
Update(true)
equal(frame.SNPThreatText.text, "55%", "scaled fallback")
raw = secret
Update(true)
assert(rawequal(frame.SNPThreatText.argument, secret), "secret passed directly to display API")
equal(frame.SNPThreatText.shown, true, "opaque percentage displayed")
raw, scaled = nil, nil
Update(true)
equal(frame.SNPThreatText.text, "", "absent threat never fabricated")
equal(frame.SNPThreatText.shown, false, "absent threat hidden")
for _, layer in ipairs(frame.SNPThreatText.SNPUnderlayers) do assert(not layer.shown, "absent threat underlayers hidden") end
raw = 100
enabled = false
Update(true)
equal(frame.SNPThreatStatus, "disabled", "disabled preference honored")
enabled = true
Update(false)
equal(frame.SNPThreatText.shown, false, "name-only presentation has no threat label")
local previousText = frame.SNPThreatText
frame.healthBar = Bar()
Update(true)
equal(previousText.shown, false, "old bar label hidden on replacement")
equal(frame.SNPThreatText.bar, frame.healthBar, "label follows current health bar")
equal(frame.SNPThreatText.shown, true, "replacement label shown")
fail = true
Update(true)
equal(frame.SNPThreatStatus, "threat API unavailable", "API failure reported")
equal(frame.SNPThreatText.shown, false, "failed API clears stale percentage")
accessible = false
ns.NameplateThreat.UpdateThreatText({}, "hostile", {}, {showHealthBar = true})
print("Nameplate threat smoke: passed")
