-- Verify native edge removal and reversible bar/text artwork.
local ns = {}
local barRGB = {1, 1, 0}
ns.PriorityColorForState = function() return barRGB[1], barRGB[2], barRGB[3] end
local unpackValues = unpack or table.unpack
assert(loadfile("SimpleNameplates/Core.lua"))("SimpleNameplates", ns)
ns.WorldContext = {Get = function() return {combatLockdown = false} end}
assert(loadfile("SimpleNameplates/PresentationCapabilities.lua"))("SimpleNameplates", ns)
assert(loadfile("SimpleNameplates/NameplateFrames.lua"))("SimpleNameplates", ns)
local function Region()
    local r = {alpha = 1, shown = true, texture = "original", coords = {0.1, 0.9, 0.2, 0.8},
        font = "font", size = 10, flags = "OUTLINE", shadow = {0, 0, 0, 1}, offset = {1, -1}}
    function r:GetAlpha() return self.alpha end
    function r:SetAlpha(v) self.alpha = v end
    function r:GetAtlas() return self.atlas end
    function r:GetTexture() return self.texture end
    function r:SetTexture(v) self.texture, self.atlas = v, nil end
    function r:SetAtlas(v) self.atlas = v end
    function r:GetTexCoord() return unpackValues(self.coords) end
    function r:SetTexCoord(...) self.coords = {...} end
    function r:GetTextColor() return self.r or 0.7, self.g or 0.8, self.b or 0.9, 1 end
    function r:SetTextColor(r, g, b) self.r, self.g, self.b = r, g, b end
    function r:GetVertexColor() return 0.5, 0.5, 0.5, 1 end
    function r:SetVertexColor(r, g, b) self.vr, self.vg, self.vb = r, g, b end
    function r:GetFont() return self.font, self.size, self.flags end
    function r:SetFont(f, s, flags) self.font, self.size, self.flags = f, s, flags end
    function r:GetShadowColor() return unpackValues(self.shadow) end
    function r:SetShadowColor(...) self.shadow = {...} end
    function r:GetShadowOffset() return unpackValues(self.offset) end
    function r:SetShadowOffset(...) self.offset = {...} end
    function r:Show() self.shown = true end
    function r:Hide() self.shown = false end
    function r:SetAllPoints(bar) self.bar = bar end
    function r:SetColorTexture(...) self.color = {...} end
    return r
end
local function Bar(backgroundKey)
    local bar = Region()
    bar[backgroundKey], bar.barTexture = Region(), Region()
    bar.barTexture.atlas = "native-fill"
    function bar:CreateTexture() return Region() end
    function bar:HookScript(_, callback) self.onShow = callback end
    return bar
end
local health, cast = Bar("bgTexture"), Bar("Background")
health.Text, health.RightText, health.LeftText = Region(), Region(), Region()
health.selectedBorder, health.deselectedOverlay = Region(), Region()
cast.Border, cast.DropShadow, cast.Text = Region(), Region(), Region()
cast.BorderShield = Region()
local frame = {healthBar = health, castBar = cast}
local context = ns.WorldContext.Get()
local assessment = ns.PresentationCapabilities.InspectFrame(frame, context)
ns.NameplateFrames.ApplyBarArtwork(frame, assessment, context)
for _, key in ipairs({"Text", "RightText", "LeftText"}) do
    assert(health[key].r == 1 and health[key].g == 1 and health[key].b == 1, "bright bar native text white")
    assert(health[key].flags == "THICKOUTLINE", "native health text uses game outline")
    assert(health[key].vr == 1, "native text tint neutral")
end
barRGB = {0, 0, 1}
ns.NameplateFrames.ApplyBarArtwork(frame, assessment, context)
assert(health.Text.r == 1, "native health text stays white on dark bars")
assert(health.bgTexture.alpha == 0 and health.selectedBorder.alpha == 0)
assert(health.deselectedOverlay.alpha == 0 and cast.Border.alpha == 0)
assert(cast.DropShadow.alpha == 0 and cast.BorderShield.alpha == 1, "shield stays intact")
assert(cast.Text.flags == "THICKOUTLINE" and cast.Text.shadow[4] == 0 and cast.Text.offset[1] == 0)
assert(cast.Text.font == "font" and cast.Text.size == 10, "cast face/size preserved")
assert(health.barTexture.texture == "Interface\\Buttons\\WHITE8X8")
assert(health.SNPPlainBackground.bar == health and health.SNPPlainBackground.shown)
cast.barTexture:SetAtlas("changed-for-new-cast")
cast.onShow()
assert(cast.barTexture.atlas == nil, "new casts regain flat artwork")
-- Restoring while a decorated region is inaccessible must retain originals.
health.bgTexture.IsForbidden = function() return true end
assert(not pcall(ns.NameplateFrames.RestoreBarArtwork, frame, context))
assert(frame.SNPOriginalArtwork, "failed restoration keeps backup")
health.bgTexture.IsForbidden = nil
ns.NameplateFrames.RestoreBarArtwork(frame, context)
assert(health.Text.r == 0.7 and health.Text.g == 0.8 and health.Text.vr == 0.5, "native health text restored")
assert(health.bgTexture.alpha == 1 and health.selectedBorder.alpha == 1)
assert(cast.Border.alpha == 1 and cast.DropShadow.alpha == 1)
assert(health.barTexture.atlas == "native-fill" and health.barTexture.coords[1] == 0.1)
assert(cast.Text.flags == "OUTLINE" and cast.Text.shadow[4] == 1 and cast.Text.offset[1] == 1)
assert(not health.SNPPlainBackground.shown and not frame.SNPOriginalArtwork)
cast.barTexture:SetAtlas("restored-native-update")
cast.onShow()
assert(cast.barTexture.atlas == "restored-native-update", "inactive hooks leave Blizzard alone")
print("Bar artwork smoke: passed")
