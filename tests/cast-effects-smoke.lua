-- Exercise the actual bundled DF effect constructors with native UI fixtures.
local ui = dofile("tests/details-framework-ui-stubs.lua")
local methods = getmetatable(UIParent).__index
function methods:SetIgnoreParentScale(value) self.ignoreParentScale = value end
function methods:SetTexCoord(...) self.texcoord = {...} end
function methods:IsPlaying() return self.playing == true end
function methods:Play() self.playing = true; self.plays = (self.plays or 0) + 1 end
function methods:Stop() self.playing = false end
function methods:Show()
    if self.shown == true then return end
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    if self.shown == false then return end
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetDuration(value) self.duration = value end
function methods:SetAlpha(value) self.alpha = value end
local enabled, effect = true, "PULSE"
local custom = {}
local function Param(name, key) return custom[name] and custom[name][key] end
local ns = {
    WorldContext = {Get = function() return {} end},
    AccessibleBoolean = function(v) if type(v) == "boolean" then return v end end,
    AccessibleValue = function(v) return v end,
    GetStylingEnabled = function() return enabled end,
    GetInterruptibleHighlightEnabled = function() return enabled end,
    GetInterruptibleEffect = function() return effect end,
    GetCastBorderSetting = Param,
    EffectColor = function() return 0.2, 0.8, 1 end,
    PresentationCapabilities = {
        CanAccessFrame = function() return true end,
        SafeField = function(o,k) return o and o[k] end,
        ReadRegion = function(o,k) if o and type(o[k]) == "function" then return o[k](o) end end,
    },
    NameplateFrames = {GetCastBar = function(f) return f.castBar end, GetHealthBar = function() end},
}
assert(loadfile("SimpleNameplates/Defaults.lua"))("SimpleNameplates", ns)
for _, module in ipairs({"Profiler", "PeriodicWork", "CastHighlight"}) do
    assert(loadfile("SimpleNameplates/"..module..".lua"))("SimpleNameplates", ns)
end
local owner = {unit = "nameplate1", castBar = CreateFrame("StatusBar"), SNPPresentation = {showCastBar = true}}
owner.castBar.Icon = CreateFrame("Frame", nil, owner.castBar)
owner.castBar.GetSize = function() error("native cast geometry read") end
local function Update() ns.CastHighlight.UpdateInterruptibleHighlight(owner, {}, owner.SNPPresentation) end
local h
for _, style in ipairs({"PULSE", "SOLID", "PULSE", "SOLID"}) do
    effect = style; Update()
    h = owner.SNPInterruptibleHighlight
    assert(h.frame:IsShown() and h.activeEffect == style, style.." renders")
    assert(h.pulse:IsPlaying() == (style == "PULSE"), "only pulse animates")
    assert(h.border[1].height == 4 and h.border[2].height == 4)
    assert(h.border[3].width == 4 and h.border[4].width == 4, "side thickness matches")
    for _, point in pairs(h.frame.points) do
        assert(point[2] == owner.castBar and point[4] == 0 and point[5] == 0, "cast bar alignment")
    end
    for _, edge in ipairs(h.border) do
        for _, point in pairs(edge.points) do assert(point[4] == 0 and point[5] == 0, "zero inset") end
    end
    assert(h.fadeIn.duration == 0.2 and h.fadeOut.duration == 0.2)
    local count = #ui.objects; Update()
    assert(#ui.objects == count, "same effect reuses regions")
end
custom.PULSE = {thickness = 7, fadeOut = 0.4, fadeIn = 0.7}
for _, style in ipairs({"PULSE", "SOLID"}) do
    effect = style; Update()
    assert(h.border[1].height == 7 and h.border[3].width == 7, "shared thickness")
end
assert(h.fadeOut.duration == 0.4 and h.fadeIn.duration == 0.7)
assert(h.frame.alpha == 1, "solid restores full opacity")
enabled = false; Update()
assert(not h.frame:IsShown() and not h.pulse:IsPlaying())
enabled = true; Update()
ns.CastHighlight.RecordSpellcastEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "nameplate1"); Update()
assert(not h.frame:IsShown(), "noninterruptible hides selected effect")
local preview = CreateFrame("StatusBar")
effect = "PULSE"; enabled = false
ns.CastHighlight.UpdatePreview(preview)
assert(preview.SNPCastPreview.activeEffect == "PULSE", "preview independent of Active")
effect = "SOLID"; ns.CastHighlight.UpdatePreview(preview)
assert(not preview.SNPCastPreview.pulse:IsPlaying(), "preview stops pulse on selection change")
ns.CastHighlight.StopPreview(preview)
assert(not preview.SNPCastPreview.frame:IsShown())
print("Cast border effects smoke: passed")
