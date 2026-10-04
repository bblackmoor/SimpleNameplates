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
        local group = {playing = false}
        function group:Play() self.playing = true end
        function group:Stop() self.playing = false end
        function group:IsPlaying() return self.playing end
        function group:SetLooping() end
        function group:CreateAnimation()
            return setmetatable({}, {__index = function() return function() end end})
        end
        return group
    end
    for _, method in ipairs({"SetTexture","SetTexCoord","SetDrawLayer","SetDesaturated","SetAllPoints"}) do r[method] = function() end end
    return r
end
local function Pool(parent, resetter)
    local p = {active = {}, inactive = {}}
    function p:Acquire()
        local obj = table.remove(self.inactive) or Region(parent)
        self.active[obj] = true
        return obj
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
function CreateFrame(_, _, parent) return Region(parent) end
function CreateTexturePool(parent, _, _, _, reset) return Pool(parent, reset) end
function CreateFramePool(_, parent, _, reset) return Pool(parent, reset) end
function hooksecurefunc(object, method, callback)
    local original = object[method]
    object[method] = function(self, ...) original(self,...); callback(self,...) end
end
assert(loadfile("SimpleNameplates/Libs/LibStub/LibStub.lua"))()
assert(loadfile("SimpleNameplates/Libs/LibCustomGlow-1.0/LibCustomGlow-1.0.lua"))()
local ns = {}
assert(loadfile("SimpleNameplates/Core.lua"))("SimpleNameplates", ns)
local style, enabled, color = "PIXEL", true, {0,1,1}
ns.WorldContext = {Get = function() return {} end}
ns.PresentationCapabilities = {CanAccessFrame = function() return true end}
ns.GetStylingEnabled = function() return enabled end
ns.GetInterruptibleHighlightEnabled = function() return enabled end
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
assert(not h.pulse:IsPlaying() and h.glowRunning)
local oldTimer = glow.timer
glow.scripts.OnUpdate(glow, 0.1)
assert(glow.timer > oldTimer, "library animates dashes")
Update()
assert(h.glowHost[key] == glow, "refresh reuses animation")
color = {1,0,0}; Update()
assert(glow.textures[1].color[1] == 1 and glow.textures[1].color[2] == 0, "live color update")
style = "PULSE"; Update()
assert(not h.glowHost[key] and not glow.scripts.OnUpdate and h.pulse:IsPlaying(), "switching to pulse releases glow")
style = "PIXEL"; Update()
assert(h.glowHost[key] and not h.pulse:IsPlaying())
frame.castBar.Icon:SetShown(false)
assert(not h.glowHost[key] and not h.pulse:IsPlaying(), "uninterruptible/end hides and stops animation")
frame.castBar.Icon:SetShown(true)
assert(h.glowHost[key], "interruptible icon restarts glow")
local oldBar = frame.castBar
frame.castBar = Region(); frame.castBar.Icon = Region(); Update()
assert(not h.glowHost[key], "bar replacement stops old animation")
oldBar.Icon:SetShown(false); oldBar.Icon:SetShown(true)
assert(not h.frame:IsShown(), "old icon cannot revive retired highlight")
h = frame.SNPInterruptibleHighlight
local secret = {}
function issecretvalue(value) return value == secret end
frame.castBar.GetSize = function() return secret, secret end
Update()
assert(not h.glowHost[key] and h.pulse:IsPlaying(), "secret geometry uses pulse without arithmetic")
enabled = false; Update()
assert(not h.pulse:IsPlaying() and not h.glowHost[key], "disable stops both effects")
print("Pixel glow integration smoke: passed")
