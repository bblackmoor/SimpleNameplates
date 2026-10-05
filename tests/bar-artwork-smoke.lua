-- Verify native edge removal and reversible bar/text artwork.
local ns = {}
local slug = false
ns.GetAppearanceSetting = function(key) return key == "useSlugRendering" and slug end
assert(loadfile("SimpleNameplates/FontRendering.lua"))("SimpleNameplates", ns)
local barRGB = {1, 1, 0}
ns.PriorityColorForState = function() return barRGB[1], barRGB[2], barRGB[3] end
local unpackValues = unpack or table.unpack
assert(loadfile("SimpleNameplates/Core.lua"))("SimpleNameplates", ns)
ns.WorldContext = {Get = function() return {combatLockdown = false} end}
assert(loadfile("SimpleNameplates/PresentationCapabilities.lua"))("SimpleNameplates", ns)
assert(loadfile("SimpleNameplates/TextUnderlayers.lua"))("SimpleNameplates", ns)
assert(loadfile("SimpleNameplates/NameplateFrames.lua"))("SimpleNameplates", ns)
local function Region()
    local r = {alpha = 1, shown = true, texture = "original", coords = {0.1, 0.9, 0.2, 0.8},
        font = "font", size = 10, flags = "OUTLINE", shadow = {0, 0, 0, 1}, offset = {1, -1}}
    function r:GetNumPoints() return #(self.points or {}) end
    function r:GetPoint(index) return unpackValues(self.points[index]) end
    function r:ClearAllPoints() self.points = {} end
    function r:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function r:SetDrawLayer(layer, level) self.layer, self.level = layer, level end
    function r:GetDrawLayer() return self.layer or "ARTWORK", self.level or 0 end
    function r:GetText() return self.text end
    function r:SetText(text) self.text = text end
    function r:SetJustifyH() end
    function r:SetJustifyV() end
    function r:SetWordWrap() end
    function r:SetMaxLines() end
    function r:IsShown() return self.shown end
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
    function bar:CreateFontString() return Region() end
    function bar:HookScript(_, callback) self.onShow = callback end
    return bar
end
local health, cast = Bar("bgTexture"), Bar("Background")
health.Text, health.RightText, health.LeftText = Region(), Region(), Region()
health.Text:SetPoint("CENTER", health, "CENTER", 0, 0)
health.selectedBorder, health.deselectedOverlay = Region(), Region()
cast.Border, cast.DropShadow, cast.Text = Region(), Region(), Region()
cast.BorderShield = Region()
local frame = {healthBar = health, castBar = cast}
local context = ns.WorldContext.Get()
local assessment = ns.PresentationCapabilities.InspectFrame(frame, context)
ns.NameplateFrames.ApplyBarArtwork(frame, assessment, context)
for _, key in ipairs({"Text", "RightText", "LeftText"}) do
    assert(health[key].r == 1 and health[key].g == 1 and health[key].b == 1, "bright bar native text white")
    assert(health[key].flags == "", "native health text has no outline")
    assert(health[key].shadow[4] == 0 and #health[key].SNPUnderlayers == 2, "native health text uses black offset copy")
    assert(health[key].vr == 1, "native text tint neutral")
end
assert(health.LeftText.points[1][5] == -0.5, "rightmost native health label padding moves down")
assert(health.RightText.points[1][2] == health.LeftText and health.RightText.points[1][3] == "LEFT", "native value follows percentage")
assert(health.Text.points[1][2] == health.RightText and health.Text.points[1][3] == "LEFT", "single native label cannot overlap other shown labels")
barRGB = {0, 0, 1}
ns.NameplateFrames.ApplyBarArtwork(frame, assessment, context)
assert(health.LeftText.points[1][5] == -0.5 and health.Text.points[1][5] == 0, "native text padding does not accumulate")
assert(health.Text.r == 1, "native health text stays white on dark bars")
assert(health.bgTexture.alpha == 0 and health.selectedBorder.alpha == 0)
assert(health.deselectedOverlay.alpha == 0 and cast.Border.alpha == 0)
assert(cast.DropShadow.alpha == 0 and cast.BorderShield.alpha == 1, "shield stays intact")
assert(cast.Text.flags == "THICKOUTLINE" and cast.Text.shadow[4] == 0 and cast.Text.offset[1] == 0)
assert(cast.Text.font == "font" and cast.Text.size == 10, "cast face/size preserved")
slug = true
ns.NameplateFrames.ApplyBarArtwork(frame, assessment, context)
assert(cast.Text.flags == "SLUG,OUTLINE", "cast text uses outlined Slug")
for _, key in ipairs({"Text", "RightText", "LeftText"}) do
    assert(health[key].flags == "SLUG", "native health text uses unoutlined Slug")
    for _, layer in ipairs(health[key].SNPUnderlayers) do assert(layer.flags == "SLUG", "native underlayers use Slug") end
end
slug = false
ns.NameplateFrames.ApplyBarArtwork(frame, assessment, context)
assert(cast.Text.flags == "THICKOUTLINE" and health.Text.flags == "", "toggle off restores ordinary rendering")
assert(health.barTexture.texture == "Interface\\Buttons\\WHITE8X8")
assert(health.SNPPlainBackground.bar == health and health.SNPPlainBackground.shown)
cast.barTexture:SetAtlas("changed-for-new-cast")
cast.onShow()
assert(cast.barTexture.atlas == nil, "new casts regain flat artwork")
-- A native layout callback during font writes cannot recurse through artwork.
local setFont, writes = cast.Text.SetFont, 0
function cast.Text:SetFont(...)
    writes = writes + 1
    assert(writes < 5, "recursive native artwork repair")
    setFont(self, ...)
    cast.onShow()
end
ns.NameplateFrames.ApplyBarArtwork(frame, assessment, context)
assert(writes == 1, "one artwork font write despite callback")
cast.Text.SetFont = function() error("simulated artwork failure") end
assert(not pcall(ns.NameplateFrames.ApplyBarArtwork, frame, assessment, context))
assert(frame.SNPApplyingArtwork == nil, "artwork failure releases guard")
cast.Text.SetFont = setFont
ns.NameplateFrames.ApplyBarArtwork(frame, assessment, context)
-- Restoring while a decorated region is inaccessible must retain originals.
health.bgTexture.IsForbidden = function() return true end
assert(not pcall(ns.NameplateFrames.RestoreBarArtwork, frame, context))
assert(frame.SNPOriginalArtwork, "failed restoration keeps backup")
health.bgTexture.IsForbidden = nil
ns.NameplateFrames.RestoreBarArtwork(frame, context)
assert(health.Text.points[1][5] == 0, "native text anchor restored")
assert(health.Text.layer == "ARTWORK" and health.Text.level == 0, "native draw layer restored")
for _, layer in ipairs(health.Text.SNPUnderlayers) do assert(not layer.shown, "native underlayers hidden after restoration") end
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
