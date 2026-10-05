-- Exercise the bundled library with the real cast-highlight integration.
local function Region(parent)
    local r = {parent = parent, shown = true, level = 1, width = 140, height = 20, scripts = {}, masks = {}}
    function r:GetParent() return self.parent end
    function r:SetParent(p) self.parent = p end
    function r:SetSize(w,h) self.width,self.height = w,h end
    function r:GetSize()
        if self.anchorTarget and self.points.BOTTOMRIGHT then return self.anchorTarget:GetSize() end
        return self.width,self.height
    end
    function r:SetPoint(point, relative, ...)
        self.points = self.points or {}; self.points[point] = {relative, ...}
        if point == "TOPLEFT" and type(relative) == "table" then self.anchorTarget = relative end
    end
    function r:ClearAllPoints() self.points = {}; self.anchorTarget = nil end
    function r:SetHeight(v) self.height = v end
    function r:SetWidth(v) self.width = v end
    function r:SetFrameLevel(v) self.level = v end
    function r:GetFrameLevel() return self.level end
    function r:SetScript(key, callback) self.scripts[key] = callback end
    function r:IsShown() return self.shown end
    function r:IsInterruptable() return self.Icon and self.Icon:IsShown() or false end
    function r:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function r:GetAlpha() return self.alpha or 1 end
    function r:SetShown(value)
        if self.shown == value then return end
        self.shown = value
        local callback = self.scripts[value and "OnShow" or "OnHide"]
        if callback then callback(self) end
    end
    function r:Show() self:SetShown(true) end
    function r:Hide() self:SetShown(false) end
    function r:SetAlpha(v) self.alpha = v end
    function r:SetColorTexture(...) self.color = {...} end
    function r:SetVertexColor(...) self.color = {...} end
    function r:GetNumMaskTextures() return #self.masks end
    function r:GetMaskTexture(i) return self.masks[i] end
    function r:AddMaskTexture(mask) self.masks[#self.masks+1] = mask end
    function r:RemoveMaskTexture(mask) for i,v in ipairs(self.masks) do if v == mask then table.remove(self.masks,i); break end end end
    function r:CreateTexture() return Region(self) end
    function r:CreateMaskTexture() return Region(self) end
    function r:CreateAnimationGroup()
        local group = {playing = false, parent = self, scripts = {}}
        function group:Play() self.playing = true; if self.scripts.OnPlay then self.scripts.OnPlay(self) end end
        function group:Stop() self.playing = false; if self.scripts.OnStop then self.scripts.OnStop(self) end end
        function group:IsPlaying() return self.playing end
        function group:SetLooping() end
        function group:SetToFinalAlpha() end
        function group:SetScript(k, callback) self.scripts[k] = callback end
        function group:GetParent() return self.parent end
        function group:CreateAnimation()
            return setmetatable({}, {__index = function() return function() end end})
        end
        return group
    end
    for _, method in ipairs({"SetTexture","SetTexCoord","SetDrawLayer","SetDesaturated","SetAllPoints","SetBlendMode","SetAtlas"}) do r[method] = function() end end
    return r
end
local function Pool(parent, resetter)
    local p = {active = {}, inactive = {}}
    function p:Acquire()
        local obj = table.remove(self.inactive)
        local new = not obj
        obj = obj or Region(parent)
        self.active[obj] = true
        return obj, new
    end
    function p:Release(obj)
        if not self.active[obj] then return end
        resetter(self, obj)
        self.active[obj] = nil
        self.inactive[#self.inactive+1] = obj
    end
    return p
end
UIParent = Region()
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE = 1,1
min, tinsert, tremove, strmatch = math.min, table.insert, table.remove, string.match
function AnimateTexCoords() end
function CreateFrame(_, _, parent) return Region(parent) end
function CreateTexturePool(parent, _, _, _, reset) return Pool(parent, reset) end
function CreateFramePool(_, parent, _, reset) return Pool(parent, reset) end
function hooksecurefunc(object, method, callback)
    object.hookCount = (object.hookCount or 0) + 1
    local original = object[method]
    object[method] = function(self, ...) original(self,...); callback(self,...) end
end
assert(loadfile("SimpleNameplates/Libs/LibStub/LibStub.lua"))()
assert(loadfile("SimpleNameplates/Libs/LibCustomGlow-1.0/LibCustomGlow-1.0.lua"))()
local ns = {}
assert(loadfile("SimpleNameplates/Core.lua"))("SimpleNameplates", ns)
local style, enabled, color = "PIXEL", true, {0,1,1}
ns.WorldContext = {Get = function() return {} end}
local blocked = false
ns.PresentationCapabilities = {CanAccessFrame = function() return not blocked end}
ns.GetStylingEnabled = function() return enabled end
ns.GetInterruptibleHighlightEnabled = function() return enabled and style ~= "NONE" end
ns.GetInterruptibleCastStyle = function() return style end
ns.EffectColor = function() return table.unpack(color) end
ns.NameplateFrames = {GetCastBar = function(f) return f.castBar end, GetHealthBar = function(f) return f.healthBar end}
local frame = {castBar = Region(), healthBar = Region(), SNPPresentation = {showCastBar = true}}
frame.castBar.Icon = Region()
assert(loadfile("SimpleNameplates/CastHighlight.lua"))("SimpleNameplates",ns)
local function Update() ns.CastHighlight.UpdateInterruptibleHighlight(frame, {}, frame.SNPPresentation) end
Update()
local h = frame.SNPInterruptibleHighlight
local key = "_PixelGlowSNPInterruptible"
local glow = assert(h.glowHost[key], "bundled PixelGlow starts")
local w, height = h.glowHost:GetSize()
assert(w == 146 and height == 26, "library receives explicit readable host geometry")
assert(#glow.textures == 12 and not glow.bg, "dashed outline without dark backing")
assert(h.glowStyle == "PIXEL" and not h.pulse, "custom pulse removed")
local oldTimer = glow.timer
glow.scripts.OnUpdate(glow, 0.1)
assert(glow.timer > oldTimer, "library animates dashes")
Update()
assert(h.glowHost[key] == glow, "refresh reuses animation")
color = {1,0,0}; Update()
assert(glow.textures[1].color[1] == 1 and glow.textures[1].color[2] == 0, "live color update")
local effects = {
    {"AUTOCAST", "_AutoCastGlowSNPInterruptible"},
    {"BUTTON", "_ButtonGlow"},
    {"PROC", "_ProcGlowSNPInterruptible"},
    {"PIXEL", key},
}
local previousKey = key
for _, effect in ipairs(effects) do
    style = effect[1]; Update()
    assert(not h.glowHost[previousKey], "previous library effect released")
    local active = assert(h.glowHost[effect[2]], "selected library effect starts")
    assert(h.glowStyle == style)
    Update()
    assert(h.glowHost[effect[2]] == active, "refresh reuses selected effect")
    frame.castBar.Icon:SetShown(false)
    assert(not h.glowHost[effect[2]], "cast end releases selected effect")
    frame.castBar.Icon:SetShown(true)
    assert(h.glowHost[effect[2]], "interruptible cast restarts selected effect")
    color = {0.2, 0.4, 0.8}; Update()
    active = assert(h.glowHost[effect[2]], "color change preserves selected effect")
    local tint = active.textures and active.textures[1].color or active.ants and active.ants.color or active.ProcLoop.color
    assert(tint[1] == 0.2 and tint[2] == 0.4 and tint[3] == 0.8, "selected effect uses profile color")
    frame.castBar:SetSize(160, 22); Update()
    local hostWidth, hostHeight = h.glowHost:GetSize()
    assert(hostWidth == 166 and hostHeight == 28, "selected effect follows bar resize")
    previousKey = effect[2]
end
style = "NONE"; Update()
assert(not h.glowHost[key] and not h.frame:IsShown(), "None hides and stops effect")
style = "PIXEL"; Update()
assert(h.glowHost[key])
frame.castBar.Icon:SetShown(false)
assert(not h.glowHost[key] and not h.glowStyle, "uninterruptible/end hides and stops animation")
frame.castBar.Icon:SetShown(true)
assert(h.glowHost[key], "interruptible icon restarts glow")
local oldIcon = frame.castBar.Icon
local newIcon = Region(); newIcon:Hide()
frame.castBar.Icon = newIcon; Update()
assert(not h.frame:IsShown(), "replacement icon determines interruptibility")
oldIcon:SetShown(false); oldIcon:SetShown(true)
assert(not h.frame:IsShown(), "retired icon cannot restart the current bar's glow")
newIcon:SetShown(true)
assert(h.glowHost[key], "replacement icon starts the current glow")
frame.castBar.Icon = oldIcon; Update()
assert(oldIcon.hookCount == 1, "returning icons reuse their existing hook")
newIcon:SetShown(false)
assert(h.glowHost[key], "retired icon cannot stop the current bar's glow")
local originalIsShown = oldIcon.IsShown
oldIcon.IsShown = function() error("icon temporarily unavailable") end
Update()
assert(not h.frame:IsShown() and not h.glowHost[key], "unreadable visibility cannot retain a stale glow")
oldIcon.IsShown = originalIsShown; Update()
assert(h.glowHost[key], "readable visibility resumes the glow")
local oldBar = frame.castBar
frame.castBar = Region(); frame.castBar.Icon = Region(); Update()
assert(not h.glowHost[key], "bar replacement stops old animation")
oldBar.Icon:SetShown(false); oldBar.Icon:SetShown(true)
assert(not h.frame:IsShown(), "old icon cannot revive retired highlight")
h = frame.SNPInterruptibleHighlight
local secret = {}
function issecretvalue(value) return value == secret end
frame.castBar.GetSize = function() return secret, secret end
for _, effect in ipairs(effects) do
    style = effect[1]; Update()
    assert(not h.glowHost[effect[2]] and not h.glowStyle, "secret geometry skips every effect without arithmetic")
end
enabled = false; Update()
assert(not h.glowStyle and not h.glowHost[key], "disable stops effect")
-- Deferred callbacks recover the actual library effect, not stale arguments.
enabled, style = true, "PIXEL"
frame.castBar.GetSize = function() return 140, 20 end
Update()
assert(h.glowHost[key], "effect starts with readable geometry")
blocked = true
frame.castBar.Icon:SetShown(false)
ns.CastHighlight.RetryPending({})
assert(h.glowHost[key], "blocked retries defer native access")
blocked = false
ns.CastHighlight.RetryPending({})
assert(not h.glowHost[key] and not h.frame:IsShown(), "retry stops stale library glow")
blocked = true
frame.castBar.Icon:SetShown(true)
blocked = false
ns.CastHighlight.RetryPending({})
assert(h.glowHost[key], "retry starts current interruptible glow")
blocked = true
frame.castBar.Icon:SetShown(false)
enabled = false
blocked = false
ns.CastHighlight.RetryPending({})
assert(not h.glowHost[key], "deferred retry stops effects after disable")
-- Classic style leaves the icon visible regardless of interruptibility.
enabled, style = true, "PIXEL"
frame.castBar.HideIconWhenNotInterruptible = false
local interruptible = false
frame.castBar.IsInterruptable = function() return interruptible end
frame.castBar.Icon:SetShown(true)
Update()
assert(not h.frame:IsShown() and not h.glowHost[key], "Classic uninterruptible cast cannot glow despite visible icon")
interruptible = true
frame.castBar.Icon:SetShown(true)
assert(h.frame:IsShown() and h.glowHost[key], "Classic interruptible channel starts glow without icon visibility change")
interruptible = false
frame.castBar.Icon:SetShown(true)
assert(not h.frame:IsShown() and not h.glowHost[key], "Classic interruptibility change stops glow with icon still shown")
blocked = true
interruptible = true
frame.castBar.Icon:SetShown(true)
blocked = false
ns.CastHighlight.RetryPending({})
assert(h.glowHost[key], "Classic deferred retry reads the current native decision")

-- Model SetShown consuming an opaque false value without Lua inspecting it.
local nativeSetShown, received = h.frame.SetShown, nil
h.frame.SetShown = function(self, value)
    received = value
    nativeSetShown(self, false)
end
frame.castBar.IsInterruptable = function() return secret end
Update()
assert(received == secret and not h.glowHost[key], "restricted decision forwarded unchanged to the visibility API")
h.frame.SetShown = nativeSetShown
frame.castBar.IsInterruptable = function() error("native decision unavailable") end
Update()
assert(not h.frame:IsShown(), "unavailable native decision safely hides glow")
frame.castBar.IsInterruptable = nil
Update()
assert(not h.frame:IsShown(), "missing native decision cannot fall back to ambiguous icon visibility")

-- Resolve a native nested cast through real capabilities/accessors and Glow.
assert(loadfile("SimpleNameplates/PresentationCapabilities.lua"))("SimpleNameplates", ns)
assert(loadfile("SimpleNameplates/TextUnderlayers.lua"))("SimpleNameplates", ns)
assert(loadfile("SimpleNameplates/NameplateFrames.lua"))("SimpleNameplates", ns)
assert(loadfile("SimpleNameplates/CastHighlight.lua"))("SimpleNameplates", ns)
local nestedFrame = {name = Region(), healthBar = Region(), CastBarsContainer = Region(),
    SNPPresentation = {showCastBar = true}}
local nestedBar = Region(nestedFrame.CastBarsContainer)
nestedFrame.CastBarsContainer.castBar = nestedBar
nestedBar.Icon, nestedBar.Border = Region(nestedBar), Region(nestedBar)
nestedBar.Border:SetAlpha(0.7)
ns.CastHighlight.UpdateInterruptibleHighlight(nestedFrame, {}, nestedFrame.SNPPresentation)
local nestedHighlight = assert(nestedFrame.SNPInterruptibleHighlight, "native nested cast creates highlight")
assert(nestedHighlight.castBar == nestedBar and nestedHighlight.glowHost[key], "native nested cast starts real library glow")
local assessment = ns.PresentationCapabilities.InspectFrame(nestedFrame, {})
ns.NameplateFrames.ApplyBarArtwork(nestedFrame, assessment, {})
assert(nestedBar.Border:GetAlpha() == 0, "nested cast artwork styled")
ns.NameplateFrames.RestoreBarArtwork(nestedFrame, {})
assert(nestedBar.Border:GetAlpha() == 0.7, "nested cast original artwork restored")
local containerBlocked = true
nestedFrame.CastBarsContainer.IsForbidden = function() return containerBlocked end
nestedBar.Icon:SetShown(false)
assert(nestedHighlight.glowHost[key], "forbidden nested container defers callback")
containerBlocked = false
ns.CastHighlight.RetryPending({})
assert(not nestedHighlight.glowHost[key], "nested access recovery retries current native interruptibility")

print("Cast glow integration smoke: passed")
