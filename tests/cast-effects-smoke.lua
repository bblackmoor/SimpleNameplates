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
local nativeCreate = CreateFrame
local templateAvailable = true
function DoesTemplateExist() return templateAvailable end
function CreateFrame(kind, name, parent, template)
    local frame = nativeCreate(kind, name, parent, template)
    if template == "ActionButtonSpellAlertTemplate" then
        frame.ProcStartAnim = frame:CreateAnimationGroup()
        frame.ProcLoop = frame:CreateAnimationGroup()
        frame.ProcStartFlipbook = frame:CreateTexture()
        frame.ProcLoopFlipbook = frame:CreateTexture()
        local a, b, c = frame.ProcStartAnim:CreateAnimation(), frame.ProcStartAnim:CreateAnimation(), frame.ProcStartAnim:CreateAnimation()
        local loop = frame.ProcLoop:CreateAnimation()
        function frame.ProcStartAnim:GetAnimations() return a, b, c end
        function frame.ProcLoop:GetAnimations() return loop end
    end
    return frame
end
dofile("tests/details-framework-loader.lua")("Libs/DetailsFramework/load.xml")
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
    GetCastAdvancedSetting = Param,
    EffectColor = function() return 0.2, 0.8, 1 end,
    PresentationCapabilities = {
        CanAccessFrame = function() return true end,
        SafeField = function(o,k) return o and o[k] end,
        ReadRegion = function(o,k) if o and type(o[k]) == "function" then return o[k](o) end end,
    },
    NameplateFrames = {GetCastBar = function(f) return f.castBar end, GetHealthBar = function() end},
}
for _, module in ipairs({"Profiler", "PeriodicWork", "CastHighlight"}) do
    assert(loadfile("SimpleNameplates/"..module..".lua"))("SimpleNameplates", ns)
end
local owner = {unit = "nameplate1", castBar = CreateFrame("StatusBar"), SNPPresentation = {showCastBar = true}}
owner.castBar.Icon = CreateFrame("Frame", nil, owner.castBar)
owner.castBar.GetSize = function() error("native cast geometry read") end
local function Update() ns.CastHighlight.UpdateInterruptibleHighlight(owner, {}, owner.SNPPresentation) end
for _, style in ipairs({"PULSE", "SOLID", "SOFT", "ANTS", "GLOW"}) do
    effect = style; Update()
    local h = owner.SNPInterruptibleHighlight
    assert(h.frame:IsShown() and h.activeEffect == style and not h.rendererError, style.." renders")
    if style ~= "PULSE" then
        assert(not h.pulse:IsPlaying(), "library effect stops pulse")
        assert(h.renderers[style]:IsShown())
    end
    if style == "ANTS" then
        AnimateTexCoords = nil
        h.renderers.ANTS:GetScript("OnUpdate")(h.renderers.ANTS, 0.1)
        assert(h.renderers.ANTS.Texture.texcoord, "owned sprite animation works without removed global")
    end
    local count = #ui.objects; Update()
    assert(#ui.objects == count, "same effect reuses library frames")
end
local h = owner.SNPInterruptibleHighlight
custom.PULSE = {thickness = 7, inset = 1, lowAlpha = 0.2, highAlpha = 0.9, fadeOut = 0.4, fadeIn = 0.7}
effect = "PULSE"; Update()
assert(h.pulseConfig and h.fadeOut.duration == 0.4 and h.fadeIn.duration == 0.7)
custom.SOLID = {thickness = 5, minPixels = 2, upward = 3, upwardMin = 2, distance = 2}
effect = "SOLID"; Update()
assert(h.renderers.SOLID.borderSize == 5)
custom.ANTS = {frameTime = 0.05, distance = 5, opacity = 0.6, frames = 11}
effect = "ANTS"; Update()
assert(h.renderers.ANTS.frameTime == 0.05 and h.renderers.ANTS.frameCount == 11)
custom.GLOW = {expandX = 14, expandY = 9, offsetX = 2, offsetY = 1, antsAlpha = 0.75, glowAlpha = 0.65}
effect = "GLOW"; Update()
assert(h.renderers.GLOW.SNPConfiguration and h.renderers.GLOW:IsShown())
enabled = false; Update()
assert(not h.frame:IsShown())
for _, renderer in pairs(h.renderers) do assert(not renderer:IsShown()) end
assert(not h.renderers.GLOW.ProcStartAnim:IsPlaying() and not h.renderers.GLOW.ProcLoop:IsPlaying())
enabled = true
effect = "SOLID"; Update()
assert(h.renderers.SOLID:IsShown() and not h.renderers.GLOW:IsShown(), "switch retires old glow")
ns.CastHighlight.RecordSpellcastEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "nameplate1"); Update()
assert(not h.frame:IsShown(), "noninterruptible state hides any selected effect")
local preview = CreateFrame("StatusBar")
effect = "ANTS"; enabled = false
ns.CastHighlight.UpdatePreview(preview)
assert(preview.SNPCastPreview.activeEffect == "ANTS", "preview independent of Active and real cast state")
ns.CastHighlight.StopPreview(preview)
assert(not preview.SNPCastPreview.frame:IsShown())
-- Missing native alert templates visibly fall back once without frame churn.
local fallback = CreateFrame("StatusBar")
templateAvailable = false; effect = "GLOW"
ns.CastHighlight.UpdatePreview(fallback)
assert(fallback.SNPCastPreview.activeEffect == "PULSE" and fallback.SNPCastPreview.rendererError)
local count = #ui.objects
ns.CastHighlight.UpdatePreview(fallback)
assert(#ui.objects == count, "failed renderer does not allocate each update")
print("Bundled cast effects smoke: passed")
