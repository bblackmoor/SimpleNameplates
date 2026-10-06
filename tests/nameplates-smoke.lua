-- Characterize nameplate classification and one-time runtime setup.
-- Run from the repository root: lua tests/nameplates-smoke.lua
local function equal(actual, expected, label)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)), 2)
    end
end

local frames, hooks, timers = {}, {}, {}
function CreateFrame(kind)
    local frame = { kind = kind, registered = {}, scripts = {} }
    function frame:RegisterEvent(event) self.registered[event] = (self.registered[event] or 0) + 1 end
    function frame:UnregisterEvent(event) self.registered[event] = nil end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    frames[#frames + 1] = frame
    return frame
end
function hooksecurefunc(name, callback, objectCallback)
    hooks[#hooks + 1] = { name = name, callback = objectCallback or callback }
end
function CompactUnitFrame_UpdateHealthColor() end
function CompactUnitFrame_UpdateName() end
C_NamePlate = {
    GetNamePlateForUnit = function() return nil end,
    GetNamePlates = function() return {} end,
}
C_Timer = { After = function(delay, callback) timers[#timers + 1] = { delay, callback } end }
function wipe(t) for key in pairs(t) do t[key] = nil end end

local unit = {}
local barColorOverride
local threatEnabled, threatPercent = false, nil
function UnitDetailedThreatSituation() return false, 1, threatPercent, 255 end
function UnitThreatSituation(who) return who == "player" and unit.aggro and 2 or nil end
function UnitIsUnit(token, target) return unit.targetPlayer and token == "nameplate1target" and target == "player" or false end
function UnitIsOwnerOrControllerOfUnit() return false end
function UnitIsPlayer() return unit.player or false end
function UnitPlayerControlled() return unit.controlled or false end
function UnitCanAttack(who)
    if who == "player" then return unit.canAttack or false end
    return unit.canAttackUs or false
end
function UnitFactionGroup(who) return who == "player" and "Alliance" or unit.faction end
function UnitReaction() return unit.reaction end
function UnitIsPVP() return unit.pvp or false end
local unitExists = true
function UnitExists() return unitExists end
function UnitName(token)
    if unit.unavailableNames then error("restricted name") end
    return unit.names and unit.names[token] or "Diagnostic Target"
end
function UnitAffectingCombat() return false end
function UnitIsInteractable() return unit.interactable or false end

local appearance = { namePlacement = "ABOVE", nameSize = 12, nameFont = "ARIALN", threatFont = "ARIALN", healthBarWidth = 100 }
local categoryMode = "active"
local trp3Options = {}
local calls = {}
local stylingEnabled = true
local highlightEnabled = false
local function count(name) calls[name] = (calls[name] or 0) + 1 end
local ns = {
    EnsureDB = function() count("db") end,
    AccessibleNumber = function(value) return type(value) == "number" and value or nil end,
    AccessibleBoolean = function(value) if type(value) == "boolean" then return value end end,
    AccessibleValue = function(value)
        if issecretvalue and issecretvalue(value) then return nil end
        if canaccessvalue and not canaccessvalue(value) then return nil end
        return value
    end,
    GetStylingEnabled = function() return stylingEnabled and categoryMode ~= "inactive" end,
    GetHealthBarEnabled = function() return true end,
    GetCategoryMode = function() return categoryMode end,
    GetAppearanceSetting = function(key) return appearance[key] end,
    GetTRP3Setting = function(key) return trp3Options[key] or false end,
    GetInterruptibleHighlightEnabled = function() return highlightEnabled end,
    GetThreatEnabled = function() return threatEnabled end,
    GetHideCritterCompanionNames = function() return false end,
    PriorityColorForState = function(state)
        if barColorOverride then return barColorOverride[1], barColorOverride[2], barColorOverride[3] end
        if state == "useful" then return 211 / 255, 211 / 255, 211 / 255 end
        if state == "useless" then return 153 / 255, 153 / 255, 153 / 255 end
        return 1, 0, 0
    end,
    EffectColor = function() return 0, 1, 1 end,
    FontPath = function(value)
        if value == "FRIZQT" then return "Fonts\\FRIZQT__.TTF" end
        return "Fonts\\ARIALN.TTF"
    end,
    ApplyCritterCompanionNameVisibility = function() count("critters") end,
    DisableFriendlyClassColors = function() count("classColors") end,
    ApplyPendingManagedNameSettings = function() count("pending") end,
    ApplyManagedNameSettings = function() count("managed") end,
    RegisterSettingsPanels = function() count("settings") end,
    ShowNameplateConflictWarning = function() count("warning") end,
    MANAGED_NAME_CVAR_SET = { unitnamefriendlyplayername = true },
    BLIZZARD_CRITTER_COMPANION_NAME_CVARS = {},
    FRIENDLY_COLOR_CVARS = {},
}
for _, file in ipairs({ "Profiler.lua", "WorldContext.lua", "EntityFacts.lua", "NameplateClassification.lua", "PresentationCapabilities.lua", "PresentationRules.lua", "FontRendering.lua", "NameplateFrames.lua", "NPCTitles.lua", "NameplateText.lua", "NameplateThreat.lua", "CastHighlight.lua", "NameplateRestoration.lua", "NameplatePresentation.lua", "Nameplates.lua", "Diagnostics.lua" }) do
    assert(loadfile("SimpleNameplates/" .. file))("SimpleNameplates", ns)
end
-- Retired category-disable fixtures exercise the global restoration path.
local runtimeRefresh = ns.RefreshAll
ns.RefreshAll = function()
    if categoryMode == "inactive" then ns.RestoreAll() else runtimeRefresh() end
end
equal(#frames, 1, "one event frame")
local events = frames[1]
equal(#hooks, 2, "two Blizzard repair hooks")
equal(hooks[1].name, "CompactUnitFrame_UpdateHealthColor", "health hook")
equal(hooks[2].name, "CompactUnitFrame_UpdateName", "name hook")
local countEvents = 0
for _, registered in pairs(events.registered) do countEvents = countEvents + registered end
equal(countEvents, 33, "one registration for each event")
assert(events.scripts.OnEvent and events.scripts.OnUpdate, "event/update scripts installed")
assert(not events.registered.UNIT_HEALTH and not events.registered.UNIT_MAXHEALTH, "no events for retired threat-layer threshold")
events.scripts.OnEvent(events, "ADDON_LOADED", "AnotherAddon")
equal(calls.db, nil, "other addon ignored")
events.scripts.OnEvent(events, "ADDON_LOADED", "SimpleNameplates")
equal(calls.db, 1, "database initialized once")
equal(events.registered.ADDON_LOADED, nil, "load event unregistered")
events.scripts.OnEvent(events, "PLAYER_LOGIN")
equal(calls.settings, 1, "settings registration on login")
equal(calls.critters, 1, "managed critter settings on login")
equal(calls.overhead, nil, "removed replacement has no login action")
equal(calls.classColors, nil, "login does not change native class colors")
events.scripts.OnEvent(events, "CVAR_UPDATE", "UnitNameFriendlyPlayerName")
equal(calls.managed, 1, "managed CVar update reapplied")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
equal(calls.pending, 1, "deferred CVar action applied after combat")
events.scripts.OnUpdate(events, 0.25)
assert(ns.RefreshAll and ns.RestoreAll and ns.DebugUnit and ns.StateForUnit, "runtime API")

local cases = {
    { label = "attacking NPC", data = { reaction = 3, aggro = true }, state = "attacking" },
    { label = "hostile NPC", data = { reaction = 3 }, state = "hostile" },
    { label = "attackable neutral", data = { reaction = 4, canAttackUs = true }, state = "neutral" },
    { label = "opposing PC", data = { player = true, faction = "Horde", reaction = 2 }, state = "friendly" },
    { label = "attackable opposing PC", data = { player = true, faction = "Horde", canAttack = true }, state = "hostile" },
    { label = "same faction PC", data = { player = true, faction = "Alliance", reaction = 5 }, state = "friendly" },
    { label = "controlled pet", data = { controlled = true, reaction = 5 }, state = "useless" },
    { label = "friendly NPC", data = { reaction = 5 }, state = "useless" },
    { label = "useful NPC", data = { reaction = 5, interactable = true }, state = "useful" },
    { label = "hostile vendor", data = { reaction = 3, interactable = true }, state = "hostile" },
    { label = "restricted reaction fallback", data = { reaction = {} }, state = "useless" },
}
for _, case in ipairs(cases) do
    unit = case.data
    equal(ns.StateForUnit("nameplate1"), case.state, case.label)
end
-- Exercise presentation across modules, not just event registration.
local function Region()
    local region = { shown = true, alpha = 1, height = 20, width = 140 }
    function region:HookScript(event, callback)
        self.scriptHooks = self.scriptHooks or {}
        self.scriptHooks[event] = self.scriptHooks[event] or {}
        table.insert(self.scriptHooks[event], callback)
    end
    function region:SetShown(shown)
        if self.shown == shown then return end
        self.shown = shown
        local callback = self.scripts and self.scripts[shown and "OnShow" or "OnHide"]
        if callback then callback(self) end
        for _, callback in ipairs(self.scriptHooks and self.scriptHooks[shown and "OnShow" or "OnHide"] or {}) do callback(self) end
    end
    function region:Show() self:SetShown(true) end
    function region:Hide() self:SetShown(false) end
    function region:IsShown() return self.shown end
    function region:IsInterruptable() return self.Icon and self.Icon:IsShown() or false end
    function region:IsVisible() return self.shown end
    function region:SetAlpha(value) self.alpha = value end
    function region:GetAlpha() return self.alpha end
    function region:SetHeight(value) self.height = value end
    function region:GetHeight() return self.height end
    function region:GetWidth() return self.width end
    function region:SetWidth(width) self.width = width end
    function region:SetText(value) self.text = value end
    function region:GetText() return self.text end
    function region:SetFormattedText(format, value) self.text = format:format(value) end
    function region:SetFont(font, size, flags) self.font, self.size, self.flags = font, size, flags end
    function region:GetFont() return self.font, self.size, self.flags end
    function region:SetTextColor(r, g, b) self.r, self.g, self.b = r, g, b end
    function region:GetTextColor() return self.r, self.g, self.b end
    function region:SetVertexColor(r, g, b, a) self.vr, self.vg, self.vb, self.va = r, g, b, a end
    function region:GetVertexColor() return self.vr, self.vg, self.vb, self.va end
    function region:SetStatusBarColor(r, g, b) self.barR, self.barG, self.barB = r, g, b end
    function region:GetStatusBarColor() return self.barR, self.barG, self.barB end
    function region:GetNumPoints() return #(self.points or {}) end
    function region:GetPoint(index) return table.unpack(self.points[index]) end
    function region:ClearAllPoints() self.points = {} end
    function region:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function region:CreateFontString() return Region() end
    function region:CreateTexture() return Region() end
    function region:SetAllPoints() end
    function region:SetColorTexture(...) self.color = {...} end
    function region:GetFrameLevel() return self.level or 1 end
    function region:SetFrameLevel(level) self.level = level end
    function region:SetScript(event, callback)
        self.scripts = self.scripts or {}
        self.scripts[event] = callback
    end
    function region:CreateAnimationGroup()
        local group = {playing = false}
        function group:Play() self.playing = true end
        function group:Stop() self.playing = false end
        function group:IsPlaying() return self.playing end
        function group:SetLooping(value) self.looping = value end
        function group:CreateAnimation()
            return setmetatable({}, {__index = function() return function() end end})
        end
        return group
    end
    function region:SetShadowColor(...) self.shadow = {...} end
    function region:SetShadowOffset(x,y) self.shadowX, self.shadowY = x,y end
    function region:SetWordWrap(value) self.wordWrap = value end
    function region:SetMaxLines(value) self.maxLines = value end
    for _, method in ipairs({ "SetJustifyH", "SetJustifyV",
        "SetDrawLayer" }) do region[method] = function() end end
    return region
end
local createEventFrame = CreateFrame
function CreateFrame(kind, name, parent)
    if parent then return Region() end
    return createEventFrame(kind)
end
local plateFrame = Region()
plateFrame.unit, plateFrame.name = "nameplate1", Region()
plateFrame.healthBar, plateFrame.HealthBarsContainer = Region(), Region()
plateFrame.name:SetFont("NativeFont", 10, "")
plateFrame.name:SetText("Native name")
plateFrame.name:SetTextColor(0.2, 0.4, 0.6)
plateFrame.name:SetPoint("BOTTOM", plateFrame, "TOP", 0, 4)
plateFrame.healthBar:SetStatusBarColor(0.3, 0.5, 0.7)
local plate = { UnitFrame = plateFrame }
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return { plate } end

unit = { reaction = 3 }
ns.RefreshAll()
equal(plateFrame.SNPState, "hostile", "hostile presentation category")
equal(plateFrame.healthBar.shown, true, "hostile bar visible")
equal(plateFrame.name.r, 1, "bar name white red")
equal(plateFrame.name.g, 1, "bar name white green")
equal(plateFrame.healthBar.barG, 0, "priority applied to health bar")
-- Width follows the profile, resists Blizzard layout drift, and restores.
appearance.healthBarWidth = 150
ns.RefreshAll()
equal(plateFrame.healthBar.width, 210, "bar uses 150 percent native width")
equal(plateFrame.HealthBarsContainer.width, 210, "container follows bar width")
plateFrame.healthBar.width, plateFrame.HealthBarsContainer.width = 140, 140
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.healthBar.width, 210, "cached repair restores configured width")
appearance.healthBarWidth = 125
ns.RefreshAll()
equal(plateFrame.healthBar.width, 175, "changing width does not compound scaling")
categoryMode = "inactive"
ns.RefreshAll()
equal(plateFrame.healthBar.width, 140, "inactive restores native bar width")
equal(plateFrame.HealthBarsContainer.width, 140, "inactive restores container width")
categoryMode, appearance.healthBarWidth = "active", 100
ns.RefreshAll()


unit = { player = true, faction = "Alliance", reaction = 5 }
ns.RefreshAll()
equal(plateFrame.healthBar.shown, true, "friendly uniform bar presentation")
equal(plateFrame.name.g, 1, "uniform bar name stays white")
plateFrame.name:SetTextColor(0, 1, 1)
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.name.g, 1, "cached drift repaired across module boundary")

ns.TRP3 = { GetDisplayInfo = function()
    return { roleplayingName = "Roleplay Name", fullTitle = "Long Title" }
end }
trp3Options = { useRoleplayingName = true, showFullTitle = true }
ns.RefreshAll()
equal(plateFrame.name.text, "Roleplay Name", "TRP3 name retained")
equal(plateFrame.SNPFullTitleText.shown, true, "name-only long title shown")
-- Combat changes presentation without changing the Friendly classification.
appearance.namePlacement = "INSIDE"
local oldNameStyle = {}
for key, value in pairs(plateFrame.SNPNameStyle) do oldNameStyle[key] = value end
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.SNPState, "friendly", "combat does not change category")
equal(plateFrame.healthBar.shown, true, "friendly combat bar")
equal(plateFrame.SNPFullTitleText.shown, true, "idle friendly combat retains long title")
equal(plateFrame.SNPInsideName.shown, true, "friendly combat inside name")
equal(plateFrame.healthBar.height, 20, "friendly combat padding")
equal(plateFrame.name.g, 1, "bright bar inside name stays white")
equal(plateFrame.SNPInsideName.r, 1, "inside overlay stays white")
barColorOverride = {0, 0, 0.2}
ns.RefreshAll()
equal(plateFrame.SNPInsideName.r, 1, "dark bar inside name stays white")
plateFrame.name:SetTextColor(0, 0, 0)
ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get())
equal(plateFrame.SNPInsideName.r, 1, "cached repair preserves white inside text")
barColorOverride = nil
ns.RefreshAll()

plateFrame.SNPNameStyle = oldNameStyle
equal(ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get()), false, "stale cache rejected")
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.healthBar.shown, true, "stale drift cannot undo combat bar")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
-- A Blizzard name hook must apply the whole new decision before the queued refresh.
hooks[2].callback(plateFrame)
equal(plateFrame.healthBar.shown, true, "name hook preserves bar on combat exit")
equal(plateFrame.SNPFullTitleText.shown, true, "combat exit restores title")
equal(plateFrame.SNPInsideName.shown, true, "combat exit retains inside name")
equal(plateFrame.name.alpha, 0, "combat exit retains concealed native name")
equal(plateFrame.healthBar.height, 20, "combat exit restores height")

unit = { reaction = 3 }
appearance.namePlacement = "INSIDE"
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.shown, true, "idle health bar permits long title")
equal(plateFrame.SNPInsideName.text, "Roleplay Name", "inside name retained")
equal(plateFrame.name.alpha, 0, "original inside name concealed")
equal(plateFrame.healthBar.height, 20, "inside padding retained")
equal(plateFrame.SNPInsideName.size, 12, "inside name retains selected size")
equal(plateFrame.SNPInsideName.flags, "OUTLINE", "inside name has thin outline")
threatEnabled, threatPercent = true, nil
ns.RefreshAll()
equal(plateFrame.SNPInsideName.points[2][2], plateFrame.healthBar, "blank threat uses full bar width")
equal(plateFrame.SNPInsideName.points[2][4], -3, "blank threat leaves only right padding")
threatPercent = 255
ns.RefreshAll()
equal(plateFrame.SNPInsideName.points[2][2], plateFrame.SNPThreatText, "name ends beside visible threat")
equal(plateFrame.SNPInsideName.points[2][3], "LEFT", "name uses actual threat left edge")
ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get())
equal(plateFrame.SNPInsideName.points[2][2], plateFrame.SNPThreatText, "cached repair preserves threat anchor")
threatEnabled, threatPercent = false, nil
ns.RefreshAll()

equal(plateFrame.name.flags, "OUTLINE", "hidden native inside name has thin outline")
appearance.nameSize = 36
ns.RefreshAll()
equal(plateFrame.SNPInsideName.size, 36, "large inside name retains full size")
equal(plateFrame.SNPInsideName.shadow[4], 0, "inside name native shadow disabled")
equal(plateFrame.SNPInsideName.shadowX, 0, "inside name native shadow x cleared")
equal(plateFrame.SNPInsideName.shadowY, 0, "inside name native shadow y cleared")
equal(plateFrame.SNPInsideName.points[1][5], -0.5, "asymmetric padding moves name half unit down")
equal(plateFrame.healthBar.height, 43, "bar expands for full font plus padding")
equal(plateFrame.HealthBarsContainer.height, 43, "container expands with bar")
plateFrame.healthBar:SetHeight(20)
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.healthBar.height, 43, "drift repair retains expanded height")
appearance.namePlacement, threatEnabled, threatPercent = "ABOVE", true, 100
ns.RefreshAll()
equal(plateFrame.healthBar.height, 43, "above-bar names still leave padding for threat text")
equal(plateFrame.SNPInsideName.shown, false, "threat text does not move above-bar name inside")
equal(plateFrame.name.flags, "OUTLINE", "outside name keeps thin outline")
appearance.namePlacement, threatEnabled, threatPercent = "INSIDE", false, nil
appearance.nameSize = 12
ns.RefreshAll()


categoryMode = "inactive"
ns.RefreshAll()
equal(plateFrame.SNPState, nil, "inactive restores category presentation")
equal(plateFrame.SNPInsideName.shown, false, "inside overlay restored")
equal(plateFrame.name.alpha, 1, "original name alpha restored")
equal(plateFrame.healthBar.height, 20, "original bar height restored")
equal(plateFrame.name.font, "NativeFont", "original native font restored")
equal(plateFrame.name.text, UnitName(plateFrame.unit), "current native name restored")
equal(plateFrame.name.g, 0.4, "original native name color restored")
equal(plateFrame.name.points[1][5], 4, "original native name anchor restored")
equal(plateFrame.healthBar.barG, 0.5, "original native bar color restored")
categoryMode = "active"
appearance.namePlacement = "ABOVE"
ns.RefreshAll()
ns.RestoreAll()
equal(plateFrame.SNPState, nil, "master restoration reachable")

-- Restoration must not invoke native updates that compare secret health.
local nativeUpdates = 0
local updateName, updateColor = CompactUnitFrame_UpdateName, CompactUnitFrame_UpdateHealthColor
local function UnsafeNativeUpdate()
    nativeUpdates = nativeUpdates + 1
    error("attempt to compare maxHealth (a secret number value)")
end
CompactUnitFrame_UpdateAll = UnsafeNativeUpdate
CompactUnitFrame_UpdateName, CompactUnitFrame_UpdateHealthColor = UnsafeNativeUpdate, UnsafeNativeUpdate
for index = 1, 3 do
    categoryMode = "active"
    ns.RefreshAll()
    categoryMode = "inactive"
    ns.RefreshAll()
    equal(plateFrame.SNPState, nil, "hostile disable succeeds without native updates")
    equal(ns.NameplateRestoration.IsPending(plateFrame), false, "secret health cannot queue retries")
    equal(plateFrame.name.font, "NativeFont", "hostile disable restores native font")
    equal(plateFrame.healthBar.barG, 0.5, "hostile disable restores native bar color")
end
equal(nativeUpdates, 0, "restoration never enters native health update stack")
CompactUnitFrame_UpdateAll = nil
CompactUnitFrame_UpdateName, CompactUnitFrame_UpdateHealthColor = updateName, updateColor
categoryMode = "active"

-- A failed presentation write retains originals and releases the guard.
ns.RefreshAll()
local setBarColor = plateFrame.healthBar.SetStatusBarColor
plateFrame.healthBar.SetStatusBarColor = function() error("simulated presentation restoration failure") end
ns.RestoreAll()
equal(plateFrame.SNPRestoring, nil, "failed restoration releases guard")
assert(ns.NameplateRestoration.IsPending(plateFrame), "failed restoration retained for retry")
assert(plateFrame.SNPOriginalPresentation, "failed restoration retains native presentation")
plateFrame.healthBar.SetStatusBarColor = setBarColor
events.scripts.OnUpdate(events, 0.25)
equal(ns.NameplateRestoration.IsPending(plateFrame), false, "successful retry removes pending work")
equal(plateFrame.SNPState, "hostile", "successful retry reapplies hostile presentation")
ns.RestoreAll()
plateFrame.unit = "nameplate1"
C_NamePlate.GetNamePlateForUnit = function() return nil end
C_NamePlate.GetNamePlates = function() return {} end

-- Existing cast effects and their Blizzard icon hook obey the shared decision.
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return {plate} end
unit = { player = true, faction = "Alliance", reaction = 5 }
plateFrame.castBar = Region()
plateFrame.castBar:Hide()
plateFrame.castBar.Icon = Region()
plateFrame.SNPInterruptibleHighlight = nil
local castHighlight = ns.CastHighlight.EnsureInterruptibleHighlight(plateFrame)
local castOverlay = castHighlight.frame
highlightEnabled = true
plateFrame.castBar:Hide()
ns.RefreshAll() -- Capture the native idle cast bar before simulating a cast.
plateFrame.castBar:Show()
ns.RefreshAll()
equal(castOverlay.shown, true, "uniform friendly cast effect permitted")
equal(castHighlight.pulse:IsPlaying(), true, "visible cast highlight starts pulse")
equal(plateFrame.SNPFullTitleText.shown, false, "active cast replaces title")
plateFrame.castBar:Hide()
equal(plateFrame.SNPFullTitleText.shown, true, "cast end restores title without a styling pass")
equal(plateFrame.SNPFullTitleText.points[1][2], plateFrame.healthBar, "title anchors below health bar")
ns.RefreshAll()
equal(plateFrame.castBar.shown, false, "styling does not show idle cast bar")
plateFrame.castBar:Show()
equal(plateFrame.SNPFullTitleText.shown, false, "channel/cast start immediately hides title")
plateFrame.IsForbidden = function() return true end
plateFrame.castBar:Hide()
equal(plateFrame.SNPTitleVisibilityPending, true, "blocked transition queues title visibility")
plateFrame.IsForbidden = nil
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.SNPFullTitleText.shown, true, "blocked cast end retries when accessible")
plateFrame.castBar:Show()
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
events.scripts.OnUpdate(events, 0.25)
equal(castOverlay.shown, true, "combat cast effect follows Blizzard icon")
local iconHook = hooks[#hooks].callback
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
events.scripts.OnUpdate(events, 0.25)
iconHook(plateFrame.castBar.Icon, true)
equal(castOverlay.shown, true, "uniform icon hook remains available after combat")
highlightEnabled = false
-- An idle cast bar permits a title even when the health bar is visible.
plateFrame.castBar:Hide()
local hideBar = plateFrame.healthBar.Hide
plateFrame.healthBar.Hide = function() end
plateFrame.healthBar.shown = true
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.shown, true, "observed health bar permits idle title")
local currentCast = plateFrame.castBar
local titleHooks = #currentCast.scriptHooks.OnShow
local readShown = currentCast.IsShown
currentCast.IsShown = function() error("cast visibility unavailable") end
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.shown, false, "unreadable cast visibility hides title")
equal(plateFrame.SNPTitleVisibilityPending, true, "unreadable cast visibility queues retry")
currentCast.IsShown = readShown
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.SNPFullTitleText.shown, true, "readable idle state restores title")
plateFrame.castBar = Region(); plateFrame.castBar:Hide(); ns.RefreshAll()
plateFrame.castBar:Show()
currentCast:Show(); currentCast:Hide()
equal(plateFrame.SNPFullTitleText.shown, false, "retired cast cannot show title over replacement cast")
plateFrame.castBar:Hide()
equal(plateFrame.SNPFullTitleText.shown, true, "replacement cast end restores title")
plateFrame.castBar = currentCast; ns.RefreshAll()
equal(#currentCast.scriptHooks.OnShow, titleHooks, "returning cast bar reuses title hook")
trp3Options.showFullTitle = false; ns.RefreshAll()
currentCast:Show(); currentCast:Hide()
equal(plateFrame.SNPFullTitleText.shown, false, "cast end cannot revive disabled TRP3 title")
trp3Options.showFullTitle = true; ns.RefreshAll()
stylingEnabled = false; ns.RestoreAll()
currentCast:Show(); currentCast:Hide()
equal(plateFrame.SNPFullTitleText.shown, false, "cast end cannot revive restored title")
stylingEnabled = true; ns.RefreshAll()
plateFrame.healthBar.Hide = hideBar
ns.RefreshAll()

-- Missing bars use a colored floating name and permit a title even in combat.
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return {plate} end
local savedBar = plateFrame.healthBar
plateFrame.healthBar = nil
unit = { reaction = 3 }
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.SNPPresentation.showHealthBar, false, "no fabricated health bar")
equal(plateFrame.SNPPresentation.nameOnly, true, "missing bar uses name color")
equal(plateFrame.name.g, 0, "missing-bar priority color")
equal(plateFrame.SNPFullTitleText.shown, true, "missing bar allows long title")
plateFrame.name:ClearAllPoints()
equal(ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get()), true, "missing-bar cached repair succeeds")
equal(plateFrame.name.points[1][2], plateFrame, "missing-bar repair uses the owning frame")
equal(plateFrame.name.points[1][1], "BOTTOM", "missing-bar repair restores floating placement")
plateFrame.healthBar = savedBar
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
ns.RestoreAll()

-- Context events still run with styling disabled; combat state is independent.
stylingEnabled = false
function GetZoneText() return "Silvermoon City" end
function GetSubZoneText() return "Shared" end
function InCombatLockdown() return false end
C_PvP = { GetZonePVPInfo = function() return "sanctuary", false end }
events.scripts.OnEvent(events, "ZONE_CHANGED")
equal(ns.WorldContext.Get().sanctuary, true, "context updated with styling off")
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
equal(ns.WorldContext.Get().inCombat, true, "combat cached with styling off")
equal(ns.WorldContext.Get().combatLockdown, false, "lockdown separate from combat")
stylingEnabled = true
-- All mutation entry points skip forbidden frames, including direct Blizzard hooks.
local forbidden = setmetatable({ IsForbidden = function() return true end }, {
    __index = function(_, key) error("forbidden frame inspected: " .. key) end,
    __newindex = function() error("forbidden frame modified") end,
})
C_NamePlate.GetNamePlateForUnit = function() return {UnitFrame = forbidden} end
C_NamePlate.GetNamePlates = function() return {{UnitFrame = forbidden}} end
ns.RefreshAll()
ns.RestoreAll()
hooks[1].callback(forbidden)
hooks[2].callback(forbidden)
events.scripts.OnUpdate(events, 0.25)
events.scripts.OnEvent(events, "NAME_PLATE_UNIT_REMOVED", "nameplate1")
ns.NameplateText.RestoreNameDisplay(forbidden)
equal(ns.NameplateText.CachedNameHasDrifted(forbidden), false, "forbidden drift skipped")
ns.CastHighlight.EnsureInterruptibleHighlight(forbidden)
ns.CastHighlight.UpdateInterruptibleHighlight(forbidden)
-- A protected frame skipped in lockdown is styled again after combat exit.
local locked = true
function InCombatLockdown() return locked end
plateFrame.IsProtected = function() return true end
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return {plate} end
plateFrame.SNPState = nil
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
ns.RefreshAll()
equal(plateFrame.SNPState, nil, "protected frame skipped during lockdown")
locked = false
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
events.scripts.OnUpdate(events, 0.25)
assert(plateFrame.SNPState, "protected frame refreshed after lockdown")
plateFrame.IsProtected = nil
C_NamePlate.GetNamePlateForUnit = function() return nil end
C_NamePlate.GetNamePlates = function() return {} end

-- Disabled styling still retries restoration after combat lockdown ends.
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return {plate} end
unit = { player = true, faction = "Alliance", reaction = 5 }
appearance.namePlacement = "INSIDE"
locked = false
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
ns.RefreshAll()
equal(plateFrame.healthBar.height, 20, "styled height before lockdown")
plateFrame.IsProtected = function() return true end
locked = true
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
stylingEnabled = false
ns.RestoreAll()
events.scripts.OnUpdate(events, 0.25)
assert(plateFrame.SNPState, "protected style retained until safe restoration")
locked = false
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.SNPState, nil, "disabled styling restoration retried")
equal(plateFrame.SNPPresentation, nil, "presentation cache cleared on restore")
equal(plateFrame.SNPInsideName.shown, false, "deferred inside name hidden")
equal(plateFrame.healthBar.height, 20, "deferred original height restored")
plateFrame.IsProtected = nil
stylingEnabled = true
ns.RefreshAll()
local baseForbidden = true
plate.IsForbidden = function() return baseForbidden end
stylingEnabled = false
ns.RestoreAll()
events.scripts.OnUpdate(events, 0.25)
assert(plateFrame.SNPState, "forbidden base plate restoration postponed")
baseForbidden = false
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.SNPState, nil, "base plate restoration retried with styling off")
plate.IsForbidden = nil
stylingEnabled = true
categoryMode = "active"
ns.RefreshAll()
local frameForbidden = true
plateFrame.IsForbidden = function() return frameForbidden end
categoryMode = "inactive"
ns.RefreshAll()
frameForbidden = false
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.SNPState, nil, "inactive restoration after access returns without context event")
plateFrame.IsForbidden = nil
categoryMode = "active"
ns.RefreshAll()
-- Deferred removed-unit cleanup cannot clear a newly styled recycled frame.
plateFrame.IsProtected = function() return true end
locked = true
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
C_NamePlate.GetNamePlateForUnit = function() return nil end
events.scripts.OnEvent(events, "NAME_PLATE_UNIT_REMOVED", "nameplate1")
plateFrame.unit = "nameplate2"
locked = false
ns.WorldContext.Refresh("PLAYER_REGEN_ENABLED")
C_NamePlate.GetNamePlateForUnit = function() return plate end
ns.RefreshAll()
equal(plateFrame.SNPOriginalUnit, "nameplate2", "recycled frame captures current owner")
events.scripts.OnUpdate(events, 0.25)
assert(plateFrame.SNPState, "old pending cleanup does not clear recycled style")
equal(plateFrame.name.text, "Roleplay Name", "recycled name remains")
plateFrame.IsProtected = nil
plateFrame.unit = "nameplate1"
ns.RefreshAll()

-- Removed plate lookup may already be gone; retain the last known frame for cleanup.
C_NamePlate.GetNamePlateForUnit = function() return nil end
C_NamePlate.GetNamePlates = function() return {} end
events.scripts.OnEvent(events, "NAME_PLATE_UNIT_REMOVED", "nameplate1")
equal(plateFrame.SNPState, nil, "removed known frame cleaned")
equal(plateFrame.name.text, "", "removed name cleared")
appearance.namePlacement = "ABOVE"

-- Execute the diagnostic path: the extracted targeting predicate must remain available.
local output, originalPrint = {}, print
print = function(message) output[#output + 1] = message end
unit = { player = true, faction = "Horde", canAttack = true, targetPlayer = true }
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("targeting your controlled unit: yes", 1, true),
    "diagnostics use the classification targeting predicate")
-- Diagnostics may read an accessible cast bar but must not create an overlay or hook.
local frameCount, hookCount = #frames, #hooks
plateFrame.castBar = Region()
plateFrame.castBar:Hide()
C_NamePlate.GetNamePlateForUnit = function() return plate end
plateFrame.SNPInterruptibleHighlight = nil
ns.DebugUnit("nameplate1")
equal(#frames, frameCount, "diagnostic creates no frame")
equal(#hooks, hookCount, "diagnostic installs no hook")
equal(plateFrame.SNPInterruptibleHighlight, nil, "diagnostic creates no overlay")
-- Diagnose the actual current icon's registered hook without installing one.
local diagnosticIcon = Region()
plateFrame.castBar.Icon = diagnosticIcon
plateFrame.SNPInterruptibleHighlight = nil
ns.CastHighlight.EnsureInterruptibleHighlight(plateFrame)
assert(plateFrame.SNPInterruptibleHighlight.hookedIcons[diagnosticIcon], "diagnostic fixture installs real cast hook")
local diagnosticFrames, diagnosticHooks = #frames, #hooks
output = {}
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("hook installed yes", 1, true), "registered current icon hook diagnosed")
plateFrame.castBar.Icon = Region()
output = {}
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("hook installed no", 1, true), "replacement unhooked icon diagnosed")
plateFrame.castBar.Icon = diagnosticIcon
output = {}
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("hook installed yes", 1, true), "returning registered icon diagnosed")
plateFrame.castBar.Icon = nil
output = {}
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("cast icon found no; hook installed no", 1, true), "missing current icon diagnosed")
equal(#frames, diagnosticFrames, "hook diagnosis creates no frames")
equal(#hooks, diagnosticHooks, "hook diagnosis installs no hooks")
plateFrame.SNPInterruptibleHighlight = nil

output = {}
categoryMode = "inactive"
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("configured display: Blizzard presentation", 1, true), "inactive diagnosed")
categoryMode = "active"
stylingEnabled = false
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("configured color: Blizzard-controlled", 1, true), "disabled diagnosed")
stylingEnabled = true
C_NamePlate.GetNamePlateForUnit = function() return {UnitFrame = forbidden} end
ns.DebugUnit("nameplate1")
assert(table.concat(output, "\n"):find("Presentation access: forbidden", 1, true), "forbidden diagnosed")
output = {}
unitExists = false
-- Target aliases can miss direct lookup while an enumerated plate matches.
unitExists = true
local previousIsUnit, previousGUID = UnitIsUnit, UnitGUID
local previousLookup, previousList = C_NamePlate.GetNamePlateForUnit, C_NamePlate.GetNamePlates
local cachedStyle = plateFrame.SNPNameStyle
plateFrame.SNPNameStyle = {text = "Cached diagnostic label", nameOnly = true, inside = false}
local diagnosticStyle = plateFrame.SNPNameStyle
local beforeFrames, beforeHooks = #frames, #hooks
C_NamePlate.GetNamePlateForUnit = function(token)
    if token == "target" then return nil end
    return plate
end
C_NamePlate.GetNamePlates = function() return {plate, plate} end
UnitIsUnit = function(a, b) return a == "nameplate1" and b == "target" end
ns.DebugUnit("target")
local report = table.concat(output, "\n")
assert(report:find("direct missing", 1, true), "target direct lookup miss reported")
assert(report:find("matching frames: 1", 1, true), "enumeration finds and deduplicates matching frame")
assert(report:find("enumerated unit match", 1, true), "lookup source reported")
assert(report:find("Cached name style: found", 1, true), "addon cached text reported")
assert(report:find("SNPFullTitleText: found", 1, true), "addon title region reported")
equal(plateFrame.SNPNameStyle, diagnosticStyle, "diagnostic does not rewrite cached style")
equal(#frames, beforeFrames, "enumerated diagnostic creates no frames")
equal(#hooks, beforeHooks, "enumerated diagnostic creates no hooks")

-- Unrelated frames are counted but do not flood chat, even with stale displayed text.
output = {}
local previousNameText = plateFrame.name.text
plateFrame.unit = "nameplate2"
plateFrame.name:SetText("Orin Straylight")
diagnosticStyle.text = "Orin Straylight"
unit.names = {nameplate2 = "Different NPC"}
ns.DebugUnit("target")
report = table.concat(output, "\n")
assert(report:find("matching frames: 0", 1, true), "nonmatching frame remains unmatched")
assert(report:find("scanned: 2", 1, true), "unrelated enumeration counted")
assert(report:find("unique relevant frames: 0", 1, true), "unrelated details omitted")
assert(not report:find("Different NPC", 1, true), "unrelated unit not dumped")
assert(not report:find("text: Orin Straylight", 1, true), "stale displayed name not used to select a plate")
equal(plateFrame.name.text, "Orin Straylight", "diagnostic does not repair stale text")
equal(plateFrame.unit, "nameplate2", "diagnostic does not change unit")
equal(plateFrame.SNPNameStyle, diagnosticStyle, "nonmatching cache untouched")
equal(#frames, beforeFrames, "nonmatching diagnostic creates no frames")
equal(#hooks, beforeHooks, "nonmatching diagnostic creates no hooks")

-- Both Orin presentations remain visible together, without claiming name-based identity.
output = {}
local secondFrame = {unit = "nameplate3", name = Region()}
secondFrame.name:SetText("Orin Straylight")
local secondPlate = {UnitFrame = secondFrame}
local nearby = {plate, secondPlate, plate}
for index = 1, 50 do
    local token = "nearby" .. index
    unit.names[token] = "Unrelated " .. index
    nearby[#nearby + 1] = {UnitFrame = {unit = token}}
end
unit.names.target, unit.names.nameplate2, unit.names.nameplate3 = "Orin Straylight", "Orin Straylight", "Orin Straylight"
C_NamePlate.GetNamePlates = function() return nearby end
UnitNameplateShowsWidgetsOnly = function(token) return token == "nameplate2" end
ns.DebugUnit("target")
report = table.concat(output, "\n")
assert(report:find("matching frames: 0", 1, true), "same names never count as identity matches")
assert(report:find("unique relevant frames: 2", 1, true), "both same-name frames selected and deduplicated")
assert(report:find("token nameplate2; unit name: Orin Straylight; matches inspected unit: no; same name: yes", 1, true), "widget candidate distinguished")
assert(report:find("token nameplate3; unit name: Orin Straylight; matches inspected unit: no; same name: yes", 1, true), "ordinary candidate distinguished")
assert(report:find("Plate kind [nameplate2]: softinteract match: no; widgets only: yes", 1, true), "widget plate retained")
assert(report:find("Plate kind [nameplate3]: softinteract match: no; widgets only: no", 1, true), "ordinary plate retained")
assert(not report:find("Unrelated", 1, true), "crowded surroundings omitted")
local _, detailsCount = report:gsub("Relevant nameplate", "")
equal(detailsCount, 2, "each relevant frame detailed once")
assert(#output < 85, "two presentations fit a bounded report despite 50 nearby units")
output = {}
unit.unavailableNames = true
ns.DebugUnit("target")
assert(table.concat(output, "\n"):find("unique relevant frames: 0", 1, true), "unavailable names never associate plates")
unit.unavailableNames = nil
UnitNameplateShowsWidgetsOnly = nil
C_NamePlate.GetNamePlates = function() return {plate, plate} end
plateFrame.unit = "nameplate1"
plateFrame.name:SetText(previousNameText)
unit.names = nil

output = {}
UnitIsUnit = function() error("identity unavailable") end
UnitGUID = function(token)
    if token == "target" or token == "nameplate1" then return "Creature-Match" end
end
ns.DebugUnit("target")
assert(table.concat(output, "\n"):find("matching frames: 1", 1, true), "readable GUID fallback")

output = {}
UnitGUID = function() return {} end
ns.DebugUnit("target")
report = table.concat(output, "\n")
assert(report:find("matching frames: 0", 1, true), "unreadable identity never matches by name")
assert(report:find("identity unavailable: 2", 1, true), "unknown identity reported")

output = {}
C_NamePlate.GetNamePlates = function() return { {IsForbidden = function() return true end} } end
ns.DebugUnit("target")
assert(table.concat(output, "\n"):find("matching frames: 0", 1, true), "forbidden candidate skipped")
assert(table.concat(output, "\n"):find("identity unavailable: 1", 1, true), "forbidden candidate counted without details")
output = {}
C_NamePlate.GetNamePlates = function() error("enumeration unavailable") end
ns.DebugUnit("target")
assert(table.concat(output, "\n"):find("enumeration available: no", 1, true), "failed enumeration reported")
UnitIsUnit, UnitGUID = previousIsUnit, previousGUID
plateFrame.SNPNameStyle = cachedStyle
C_NamePlate.GetNamePlateForUnit, C_NamePlate.GetNamePlates = previousLookup, previousList
output = {}
unitExists = false
ns.DebugUnit("target")
assert(table.concat(output, "\n"):find("Simple Nameplates context:", 1, true), "no-target context")
assert(table.concat(output, "\n"):find("No target selected.", 1, true), "no-target reported")
-- A mouseover report works with no selected target and no nearby plate.
unitExists = true
local oldExists = UnitExists
UnitExists = function(token) return token == "mouseover" end
C_NamePlate.GetNamePlateForUnit = function() return nil end
C_NamePlate.GetNamePlates = function() return {} end
output = {}
local mouseoverFrameCount, mouseoverHookCount = #frames, #hooks
ns.DebugUnit("mouseover")
local mouseoverReport = table.concat(output, "\n")
assert(mouseoverReport:find("debug [mouseover]", 1, true), "report identifies inspected token")
assert(mouseoverReport:find("direct missing", 1, true), "distant mouseover plate absence reported")
assert(mouseoverReport:find("matching frames: 0", 1, true), "no mouseover plate invented")
equal(#frames, mouseoverFrameCount, "mouseover diagnostic creates no frames")
equal(#hooks, mouseoverHookCount, "mouseover diagnostic creates no hooks")
output = {}
unitExists = false
UnitExists = oldExists
ns.DebugUnit("mouseover")
assert(table.concat(output, "\n"):find("No mouseover unit available.", 1, true), "missing mouseover reported")
unitExists = true
print = originalPrint

-- The shared sanctuary decision reaches text, titles, bars, and repair hooks.
C_NamePlate.GetNamePlateForUnit = function() return plate end
C_NamePlate.GetNamePlates = function() return {plate} end
C_PvP = {GetZonePVPInfo = function() return "sanctuary", false end}
for _, case in ipairs({
    {data = {player = true, faction = "Alliance", reaction = 5}, green = 0},
    {data = {reaction = 5, interactable = true}, green = 211 / 255},
    {data = {reaction = 5}, green = 153 / 255},
    {data = {player = true, faction = "Horde", reaction = 5}, green = 0},
}) do
    unit = case.data
    ns.WorldContext.Refresh("PLAYER_REGEN_ENABLED")
    ns.RefreshAll()
    equal(plateFrame.name.g, 1, "sanctuary uniform bar name")
    equal(plateFrame.SNPFullTitleText.r, 1, "TRP3 title remains white across categories: red")
    equal(plateFrame.SNPFullTitleText.g, 1, "TRP3 title remains white across categories: green")
    equal(plateFrame.SNPFullTitleText.b, 1, "TRP3 title remains white across categories: blue")
    plateFrame.name:SetTextColor(0, 0, 0)
    hooks[2].callback(plateFrame)
    equal(plateFrame.name.g, 1, "sanctuary uniform name repair")
    ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
    ns.RefreshAll()
    equal(plateFrame.healthBar.barG, case.green, "sanctuary combat bar")
    plateFrame.healthBar:SetStatusBarColor(0, 0, 0)
    hooks[1].callback(plateFrame)
    equal(plateFrame.healthBar.barG, case.green, "sanctuary health repair")
end

-- Match the localized world-name face while retaining the selected size and plain text.
appearance.matchSanctuaryFont = true
SystemFont_World = {GetFont = function() return "Fonts\\WorldLocalized.ttf", 64, "" end}
unit = {reaction = 5, interactable = true}
ns.WorldContext.Refresh("PLAYER_REGEN_ENABLED")
ns.RefreshAll()
equal(plateFrame.name.font, "Fonts\\WorldLocalized.ttf", "sanctuary uses localized world font")
equal(plateFrame.name.size, 12, "sanctuary preserves name size")
equal(plateFrame.name.flags, "OUTLINE", "sanctuary name uses thin outline")
equal(plateFrame.SNPFullTitleText.flags, "OUTLINE", "title uses thin outline")
equal(plateFrame.SNPFullTitleText.font, "Fonts\\WorldLocalized.ttf", "sanctuary TRP3 title font")
plateFrame.name:SetFont("Fonts\\Drift.ttf", 12, "OUTLINE")
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.name.font, "Fonts\\WorldLocalized.ttf", "cached repair retains sanctuary font")
appearance.matchSanctuaryFont = false
events.scripts.OnUpdate(events, 0.25)
equal(plateFrame.name.font, "Fonts\\ARIALN.TTF", "switch off invalidates font cache")
equal(plateFrame.SNPFullTitleText.font, "Fonts\\ARIALN.TTF", "switch off refreshes title font")
appearance.matchSanctuaryFont = true
appearance.namePlacement = "INSIDE"
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
ns.RefreshAll()
equal(plateFrame.SNPInsideName.font, "Fonts\\WorldLocalized.ttf", "inside-bar sanctuary font")
C_PvP = {GetZonePVPInfo = function() return "friendly", false end}
ns.WorldContext.Refresh("ZONE_CHANGED_NEW_AREA")
ns.RefreshAll()
equal(plateFrame.name.font, "Fonts\\ARIALN.TTF", "leaving sanctuary restores selected font")
equal(plateFrame.SNPInsideName.shown, true, "leaving sanctuary retains uniform inside name")
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
ns.RefreshAll()
equal(plateFrame.SNPInsideName.font, "Fonts\\ARIALN.TTF", "outside sanctuary combat restores inside font")
appearance.namePlacement = "ABOVE"
C_PvP = {GetZonePVPInfo = function() return "sanctuary", false end}
ns.WorldContext.Refresh("PLAYER_REGEN_ENABLED")
ns.RefreshAll()
equal(plateFrame.name.font, "Fonts\\WorldLocalized.ttf", "reentering sanctuary restores matching font")
SystemFont_World = {GetFont = function() error("unavailable") end}
ns.RefreshAll()
equal(plateFrame.name.font, "Fonts\\FRIZQT__.TTF", "unavailable world font falls back to Friz Quadrata")
SystemFont_World = nil
appearance.matchSanctuaryFont = false

-- NPC service titles appear below health without TRP3 while no cast is active.
plateFrame.castBar:Hide()
Enum = {TooltipDataLineType = {None = 0, UnitName = 2, UnitLevel = 47}}
C_TooltipInfo = {GetUnit = function()
    return {lines = {{type = 2, leftText = "Orin Straylight"},
        {type = 0, leftText = "Voidforge Steward"}, {type = 47, leftText = "Level 90"}}}
end}
unit = {reaction = 5, interactable = true}
trp3Options = {}
ns.WorldContext.Refresh("PLAYER_REGEN_ENABLED")
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.text, "<Voidforge Steward>", "NPC service title independent of TRP3")
equal(plateFrame.SNPFullTitleText.shown, true, "NPC service title shown below floating name")
equal(plateFrame.SNPFullTitleText.size, 10, "NPC title uses name size minus two")
equal(plateFrame.SNPFullTitleText.r, 1, "NPC title white red channel")
equal(plateFrame.SNPFullTitleText.g, 1, "NPC title white green channel")
equal(plateFrame.SNPFullTitleText.b, 1, "NPC title white blue channel")
appearance.matchSanctuaryFont = true
SystemFont_World = {GetFont = function() return "Fonts\\WorldLocalized.ttf" end}
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.font, "Fonts\\WorldLocalized.ttf", "NPC service title uses sanctuary font")
appearance.matchSanctuaryFont = false
SystemFont_World = nil
ns.WorldContext.Refresh("PLAYER_REGEN_DISABLED")
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.shown, true, "NPC title remains below health bar in combat")
ns.WorldContext.Refresh("PLAYER_REGEN_ENABLED")
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.shown, true, "NPC title restored after combat")
C_TooltipInfo.GetUnit = function() return {lines = {{type = 2}, {type = 47}}} end
unit.names = {nameplate1 = "Different NPC", target = "Different NPC"}
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.shown, false, "missing subtitle clears previous title")
equal(plateFrame.SNPFullTitleText.text, "", "old NPC service text cleared")
C_TooltipInfo = nil

-- Match the screenshot: sparse plate tooltip, fuller target tooltip, false
-- UnitIsUnit, and different interaction evidence on the two unit tokens.
UNIT_LEVEL_TEMPLATE = "Level %d"
UnitLevel = function() return 90 end
local currentGUID = "Creature-Orin"
unit.names = {nameplate1 = "Orin Straylight", target = "Orin Straylight"}
UnitGUID = function(token)
    if token == "nameplate1" then return currentGUID end
    if token == "target" then return "Creature-Orin" end
end
UnitIsInteractable = function(token) return token == "target" end
C_TooltipInfo = {GetUnit = function(token)
    local lines = {{type = 2, leftText = "Orin Straylight"}}
    if token == "target" then lines[#lines + 1] = {type = 0, leftText = "Voidforge Steward"} end
    lines[#lines + 1] = {type = 0, leftText = "Level 90"}
    return {lines = lines}
end}
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.text, "<Voidforge Steward>", "sparse plate resolves target subtitle")
equal(plateFrame.SNPFullTitleText.shown, true, "resolved service title visible")
equal(plateFrame.name.g, 1, "verified useful NPC bar name white")
equal(plateFrame.SNPFullTitleText.g, 1, "verified useful NPC title white")
currentGUID = "Creature-Orin-Plate"
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.text, "<Voidforge Steward>", "unmatched readable GUID resolves by NPC name")
equal(plateFrame.SNPEntityFacts.npcTitleSource, "cached NPC name (GUID unmatched)", "weaker association reported")
UnitGUID = function(token) if token == "nameplate1" then return currentGUID end end
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.text, "<Voidforge Steward>", "title survives target change")
currentGUID = "Creature-Other"
unit.names = {nameplate1 = "Different NPC"}
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.shown, false, "token reuse clears service title")
equal(plateFrame.name.g, 1, "token reuse retains white bar name")

-- Hyperlink titles retain white text while the category colors the bar.
unit.names = {nameplate1 = "Orin Straylight", target = "Orin Straylight"}
C_TooltipInfo.GetHyperlink = function() return {lines = {
    {type = 2, leftText = "Orin Straylight"},
    {type = 0, leftText = "Voidforge Steward"}, {type = 47, leftText = "Level 90"},
}} end
ns.RefreshAll()
equal(plateFrame.SNPFullTitleText.text, "<Voidforge Steward>", "hyperlink title displayed")
equal(plateFrame.SNPEntityFacts.npcTitleSource, "GUID hyperlink tooltip", "hyperlink presentation source")
equal(plateFrame.name.g, 1, "hyperlink retains white bar name")
equal(plateFrame.SNPFullTitleText.g, 1, "hyperlink title remains white")
local oldIsUnit, oldWidgetsOnly, oldCVar = UnitIsUnit, UnitNameplateShowsWidgetsOnly, C_CVar
UnitIsUnit = function(token, other) return token == "nameplate1" and other == "softinteract" end
UnitNameplateShowsWidgetsOnly = function(token) return token == "nameplate1" end
C_CVar = {GetCVar = function(key)
    equal(key, "nameplateShowFriendlyNpcs", "diagnostic reads friendly NPC CVar")
    return "1"
end}
output = {}
print = function(text) output[#output + 1] = text end
ns.DebugUnit("target")
local report = table.concat(output, "\n")
assert(report:find("nameplateShowFriendlyNpcs=1", 1, true), "friendly NPC visibility reported")
assert(report:find("Plate kind [nameplate1]: softinteract match: yes; widgets only: yes", 1, true), "special plate flags reported")
assert(report:find("NPC hyperlink [nameplate1]: title <Voidforge Steward>; result: title extracted", 1, true), "hyperlink result reported")
UnitNameplateShowsWidgetsOnly = function() error("restricted") end
output = {}
ns.DebugUnit("target")
assert(table.concat(output, "\n"):find("widgets only: restricted/unavailable", 1, true), "failed widget read explicit")
print = originalPrint
UnitIsUnit, UnitNameplateShowsWidgetsOnly, C_CVar = oldIsUnit, oldWidgetsOnly, oldCVar
C_TooltipInfo = nil

-- One NPC can have an ordinary plate plus a separate widget anchor.
ns.RestoreAll()
ns.TRP3 = nil
unit = {reaction = 5, interactable = true,
    names = {nameplate1 = "Orin Straylight", nameplate21 = "Orin Straylight"}}
local widgetFrame = Region()
widgetFrame.unit, widgetFrame.name = "nameplate21", Region()
widgetFrame.name:SetAlpha(0.7)
widgetFrame.healthBar, widgetFrame.HealthBarsContainer = Region(), Region()
widgetFrame.WidgetContainer = Region()
widgetFrame.SNPFullTitleText, widgetFrame.SNPInsideName = Region(), Region()
local widgetPlate = {UnitFrame = widgetFrame}
C_NamePlate.GetNamePlates = function() return {widgetPlate, plate} end
C_TooltipInfo = {GetUnit = function() return {lines = {
    {type = 2, leftText = "Orin Straylight"},
    {type = 0, leftText = "Voidforge Steward"}, {type = 47, leftText = "Level 90"},
}} end}
local widgetMode = true
UnitNameplateShowsWidgetsOnly = function(token) return token == "nameplate21" and widgetMode end
ns.RefreshAll()
equal(widgetFrame.name.alpha, 0, "widget actor name suppressed")
equal(widgetFrame.SNPFullTitleText.shown, false, "widget title suppressed")
equal(widgetFrame.SNPInsideName.shown, false, "widget inside name suppressed")
equal(widgetFrame.shown, true, "widget frame preserved")
equal(widgetFrame.WidgetContainer.shown, true, "widget container preserved")
equal(widgetFrame.healthBar.shown, true, "widget bar visibility untouched")
equal(widgetFrame.HealthBarsContainer.shown, true, "widget bar ancestor untouched")
equal(plateFrame.name.alpha, 1, "ordinary actor name remains visible")
equal(plateFrame.SNPFullTitleText.text, "<Voidforge Steward>", "ordinary plate retains service title")
equal(plateFrame.SNPFullTitleText.shown, true, "ordinary service title visible")
equal(plateFrame.name.g, 1, "ordinary uniform bar name remains white")
widgetFrame.name:SetAlpha(1)
widgetFrame.SNPFullTitleText:Show()
events.scripts.OnUpdate(events, 0.25)
equal(widgetFrame.name.alpha, 0, "widget name drift repaired")
equal(widgetFrame.SNPFullTitleText.shown, false, "widget title drift repaired")
widgetFrame.name:SetAlpha(1)
hooks[2].callback(widgetFrame)
equal(widgetFrame.name.alpha, 0, "Blizzard name hook preserves suppression")
categoryMode = "inactive"
ns.NameplatePresentation.ApplySimpleStyle(widgetFrame)
equal(widgetFrame.name.alpha, 0.7, "inactive restores original name opacity")
equal(widgetFrame.SNPPresentation, nil, "inactive clears suppression decision")
categoryMode = "active"
ns.RefreshAll()
stylingEnabled = false
ns.RestoreAll()
equal(widgetFrame.name.alpha, 0.7, "disabled restores original name opacity")
equal(widgetFrame.WidgetContainer.shown, true, "restoration preserves widgets")
stylingEnabled = true
ns.RefreshAll()
widgetMode = false
events.scripts.OnUpdate(events, 0.25)
equal(widgetFrame.name.alpha, 1, "widget-to-ordinary transition restores name")
equal(widgetFrame.SNPFullTitleText.shown, true, "widget-to-ordinary transition styles title")
widgetMode = true
events.scripts.OnUpdate(events, 0.25)
equal(widgetFrame.name.alpha, 0, "ordinary-to-widget transition suppresses text")
equal(widgetFrame.healthBar.shown, true, "transition restores Blizzard bar before suppression")
UnitNameplateShowsWidgetsOnly = function() error("restricted") end
ns.RefreshAll()
equal(widgetFrame.name.alpha, 1, "unavailable widget flag never confirms suppression")
UnitNameplateShowsWidgetsOnly = function() return {} end
ns.RefreshAll()
equal(widgetFrame.name.alpha, 1, "nonboolean widget flag never confirms suppression")
UnitNameplateShowsWidgetsOnly = function(token) return token == "nameplate21" end
ns.RefreshAll()
widgetFrame.unit = "nameplate22"
UnitNameplateShowsWidgetsOnly = function() return false end
ns.NameplatePresentation.ApplySimpleStyle(widgetFrame)
equal(widgetFrame.name.alpha, 1, "recycled widget frame becomes ordinary")
equal(widgetFrame.SNPOriginalUnit, "nameplate22", "recycled frame captures new unit")
ns.RestoreAll()
UnitNameplateShowsWidgetsOnly = oldWidgetsOnly
C_TooltipInfo = nil

-- Native repair callbacks during a style write must not recursively restyle.
C_NamePlate.GetNamePlates = function() return {plate} end
C_NamePlate.GetNamePlateForUnit = function() return plate end
unit = {reaction = 3}
stylingEnabled, categoryMode, highlightEnabled = true, "active", false
appearance.namePlacement = "INSIDE"
plateFrame.SNPInterruptibleHighlight = nil
local originalSetFont = plateFrame.name.SetFont
local fontWrites = 0
function plateFrame.name:SetFont(...)
    fontWrites = fontWrites + 1
    assert(fontWrites < 5, "recursive native font repair")
    originalSetFont(self, ...)
    hooks[2].callback(plateFrame)
end
for index = 1, 3 do
    categoryMode = "inactive"
    ns.RefreshAll()
    equal(plateFrame.SNPState, nil, "hostile toggle restores native display")
    categoryMode, fontWrites = "active", 0
    ns.RefreshAll()
    equal(fontWrites, 1, "hostile toggle applies font once despite native callback")
    equal(plateFrame.SNPInsideName.flags, "OUTLINE", "hostile toggle retains shadow rendering")
end
plateFrame.name.SetFont = function() error("simulated font write failure") end
local ok = pcall(ns.RefreshAll)
equal(ok, false, "style failure remains visible")
equal(plateFrame.SNPApplyingStyle, nil, "style failure releases reentry guard")
plateFrame.name.SetFont = originalSetFont
ns.RefreshAll()
equal(plateFrame.SNPInsideName.shown, true, "styling recovers after failed write")
local nativeFlags = plateFrame.SNPOriginalPresentation.name.SetFont[3] or ""
appearance.useSlugRendering = true
equal(ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get()), false, "ordinary font cache cannot undo Slug selection")
ns.RefreshAll()
equal(plateFrame.SNPInsideName.flags, "SLUG,OUTLINE", "inside name uses Slug with thin outline")
assert(plateFrame.SNPInsideName.SNPUnderlayers == nil, "inside name has no glyph copies")
plateFrame.name:SetFont("drifted", 10, "")
ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get())
equal(plateFrame.name.flags, "SLUG,OUTLINE", "cached repair preserves Slug")
appearance.namePlacement = "ABOVE"; ns.RefreshAll()
equal(plateFrame.name.flags, "SLUG,OUTLINE", "above-bar name uses thin Slug outline")
unit = {reaction = 5, interactable = true}; ns.RefreshAll()
equal(plateFrame.name.flags, "SLUG,OUTLINE", "floating name uses outlined Slug")
equal(plateFrame.SNPFullTitleText.flags, "SLUG,OUTLINE", "title uses outlined Slug")
appearance.useSlugRendering = false; ns.RefreshAll()
equal(plateFrame.name.flags, "OUTLINE", "toggle off restores ordinary name outline")
ns.RestoreAll()
equal(plateFrame.name.flags, nativeFlags, "native name font flags restored after Slug")

local visited, largest = {}, 0
local function CheckUpvalues(fn)
    if visited[fn] then return end
    visited[fn] = true
    local count = 0
    while true do
        local name, value = debug.getupvalue(fn, count + 1)
        if not name then break end
        count = count + 1
        if type(value) == "function" then CheckUpvalues(value) end
    end
    if count > largest then largest = count end
    assert(count <= 60, "function exceeds WoW upvalue limit: " .. count)
end
for _, fn in ipairs({ ns.StateForUnit, ns.RefreshAll, ns.RestoreAll,
    ns.DebugUnit, events.scripts.OnEvent, events.scripts.OnUpdate,
    hooks[1].callback, hooks[2].callback }) do
    CheckUpvalues(fn)
end
-- Exercise the real timing wrappers, including runtime reconciliation.
local perfOutput, originalPrint = {}, print
print = function(message) perfOutput[#perfOutput + 1] = message end
local timer = 0
GetTimePreciseSec = function() timer = timer + 0.001; return timer end
ns.Profiler.Command("start")
ns.RefreshAll()
hooks[1].callback(plateFrame)
hooks[2].callback(plateFrame)
plateFrame.name.text = "Drifted"
events.scripts.OnUpdate(events, 0.25)
-- An invalid layout cache forces the reconciliation fallback, preserving the
-- distinction between a successful cached repair and a full styling request.
plateFrame.SNPNameStyle.healthTextSignature = "stale"
events.scripts.OnUpdate(events, 0.25)
ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get())
events.scripts.OnEvent(events, "UNIT_NAME_UPDATE", "nameplate1")
events.scripts.OnUpdate(events, 0.01)
events.scripts.OnEvent(events, "PLAYER_TARGET_CHANGED")
events.scripts.OnUpdate(events, 0.01)
ns.Profiler.Command("stop")
ns.Profiler.Command("report")
print = originalPrint
for _, label in ipairs({"Full styling", "Classification", "NPC title lookup", "Text repair", "Runtime update", "Reconciliation",
    "Access assessment", "Health text layout", "Bar artwork", "Name/title styling", "Name drift check"}) do
    local found
    for _, line in ipairs(perfOutput) do if line:find(label .. ":", 1, true) then found = true end end
    assert(found, "runtime instrumentation missing: " .. label)
end
for _, expected in ipairs({"Styling requests: health-color hook =", "Styling requests: name hook =",
    "Styling requests: reconciliation fallback =", "Styling outcomes: styled =",
    "Name drift: native name text =", "Name drift: health label layout =",
    "Reconciliation repairs: cached repair =", "Reconciliation repairs: full-style fallback =",
    "Queued unit events: UNIT_NAME_UPDATE =", "Queued full refresh: PLAYER_TARGET_CHANGED ="}) do
    local found
    for _, line in ipairs(perfOutput) do if line:find(expected, 1, true) then found = true end end
    assert(found, "runtime reason counter missing: " .. expected)
end
-- Restoration preserves native dynamic state rather than the initial snapshot.
ns.RestoreAll()
plateFrame.unit = "nameplate1"
plateFrame.IsProtected = nil
trp3Options = {}
for _, disableMaster in ipairs({false, true}) do
    for _, initiallyCasting in ipairs({false, true}) do
        stylingEnabled, categoryMode = true, "active"
        unit = {reaction = 3, names = {nameplate1 = "Before rename"}}
        plateFrame.name:SetText("Before rename")
        plateFrame.castBar = Region()
        plateFrame.castBar:SetShown(initiallyCasting)
        C_NamePlate.GetNamePlateForUnit = function() return plate end
        C_NamePlate.GetNamePlates = function() return {plate} end
        ns.RefreshAll()
        unit.names.nameplate1 = "After rename"
        events.scripts.OnEvent(events, "UNIT_NAME_UPDATE", "nameplate1")
        events.scripts.OnUpdate(events, 0.01)
        equal(plateFrame.name.text, "After rename", "name event updates styled name")
        plateFrame.castBar:SetShown(not initiallyCasting)
        if disableMaster then stylingEnabled = false; ns.RestoreAll()
        else categoryMode = "inactive"; ns.RefreshAll() end
        equal(plateFrame.castBar.shown, not initiallyCasting, "disable preserves current cast visibility")
        equal(plateFrame.name.text, "After rename", "disable restores current native unit name")
        events.scripts.OnUpdate(events, 0.25)
        equal(plateFrame.castBar.shown, not initiallyCasting, "cast state survives reconciliation")
    end
end
stylingEnabled, categoryMode = true, "active"

-- Reconciliation repairs visibility and readable text without full restyling.
ns.RestoreAll()
unit = {reaction = 3}
trp3Options = {useRoleplayingName = true}
ns.TRP3 = {GetDisplayInfo = function() return {roleplayingName = "Expected RP name"} end}
for _, placement in ipairs({"ABOVE", "INSIDE"}) do
    appearance.namePlacement = placement
    ns.RefreshAll()
    plateFrame.name:Hide()
    events.scripts.OnUpdate(events, 0.25)
    equal(plateFrame.name.shown, true, "native name visibility repaired")
    plateFrame.name:SetText("Overwritten native name")
    events.scripts.OnUpdate(events, 0.25)
    equal(plateFrame.name.text, "Expected RP name", "native text-only drift repaired")
    if placement == "INSIDE" then
        plateFrame.SNPInsideName:SetText("Overwritten inside name")
        events.scripts.OnUpdate(events, 0.25)
        equal(plateFrame.SNPInsideName.text, "Expected RP name", "inside text-only drift repaired")
    end
end
local secretName = setmetatable({}, {__tostring = function() error("secret name inspected") end})
local previousSecretCheck = issecretvalue
issecretvalue = function(value) return rawequal(value, secretName) end
plateFrame.name:SetText(secretName)
plateFrame.SNPInsideName:SetText(secretName)
assert(not ns.NameplateText.CachedNameHasDrifted(plateFrame), "restricted text skipped")
plateFrame.SNPNameStyle.text = secretName
plateFrame.name:SetText("Readable replacement")
plateFrame.SNPInsideName:SetText("Readable replacement")
assert(not ns.NameplateText.CachedNameHasDrifted(plateFrame), "restricted expected text skipped")
issecretvalue = previousSecretCheck
ns.RefreshAll()

-- Missed cast-icon transitions are retried after region access returns.
ns.RestoreAll()
plateFrame.castBar = Region()
plateFrame.castBar.Icon = Region()
plateFrame.SNPInterruptibleHighlight = nil
local retryOverlay = ns.CastHighlight.EnsureInterruptibleHighlight(plateFrame).frame
highlightEnabled = true
local iconBlocked = false
plateFrame.castBar.Icon.IsForbidden = function() return iconBlocked end
ns.RefreshAll()
local retryIconHook
for _, hook in ipairs(hooks) do
    if hook.name == plateFrame.castBar.Icon then retryIconHook = hook.callback end
end
assert(retryIconHook)
for _, shown in ipairs({false, true}) do
    iconBlocked = true
    plateFrame.castBar.Icon:SetShown(shown)
    retryIconHook(plateFrame.castBar.Icon, shown)
    events.scripts.OnUpdate(events, 0.25)
    equal(retryOverlay.shown, not shown, "restricted cast callback defers writes")
    iconBlocked = false
    events.scripts.OnUpdate(events, 0.25)
    equal(retryOverlay.shown, shown, "cast retry reads current icon visibility")
end
iconBlocked = true
retryIconHook(plateFrame.castBar.Icon, false)
stylingEnabled = false
ns.RestoreAll()
iconBlocked = false
events.scripts.OnUpdate(events, 0.25)
equal(retryOverlay.shown, false, "pending cast retry cannot revive disabled styling")
stylingEnabled = true

-- Region replacement starts from the replacement's own native geometry.
ns.RestoreAll()
stylingEnabled, categoryMode = true, "active"
unit, trp3Options = {reaction = 3}, {}
appearance.namePlacement, appearance.nameSize, appearance.healthBarWidth = "INSIDE", 21, 150
plateFrame.healthBar, plateFrame.HealthBarsContainer = Region(), Region()
ns.RefreshAll()
local retiredBar, retiredContainer = plateFrame.healthBar, plateFrame.HealthBarsContainer
local replacementBar, replacementContainer = Region(), Region()
replacementBar:SetWidth(200); replacementBar:SetHeight(30)
replacementBar:SetStatusBarColor(0.1, 0.2, 0.3)
replacementContainer:SetWidth(220); replacementContainer:SetHeight(30)
plateFrame.healthBar, plateFrame.HealthBarsContainer = replacementBar, replacementContainer
ns.RefreshAll()
equal(replacementBar.width, 300, "replacement scales its own native width")
equal(replacementContainer.width, 330, "replacement container scales its own native width")
equal(retiredBar.width, 140, "retired bar width restored")
equal(retiredBar.height, 20, "retired bar height restored")
equal(retiredContainer.width, 140, "retired container width restored")
ns.RestoreAll()
equal(replacementBar.width, 200, "replacement native width restored")
equal(replacementBar.height, 30, "replacement native height restored")
equal(replacementContainer.width, 220, "replacement container width restored")
equal(replacementContainer.height, 30, "replacement container height restored")
equal(replacementBar.barG, 0.2, "replacement native color restored")

-- Container-only replacement must invalidate cached repair before any writes.
ns.RefreshAll()
local containerOnly = Region()
containerOnly:SetWidth(240); containerOnly:SetHeight(40); containerOnly:Hide()
plateFrame.HealthBarsContainer = containerOnly
events.scripts.OnUpdate(events, 0.25)
equal(containerOnly.width, 360, "container-only replacement uses its own width")
equal(containerOnly.height, 40, "container-only replacement keeps taller native height")
equal(replacementContainer.width, 220, "retired container restored during reconciliation")
ns.RestoreAll()
equal(containerOnly.width, 240, "container-only native width restored")
equal(containerOnly.shown, false, "container-only native visibility restored")

-- Retired restricted regions stay untouched and are released once access returns.
ns.RefreshAll()
local inaccessibleOldBar = plateFrame.healthBar
local retiredBlocked = true
inaccessibleOldBar.IsForbidden = function() return retiredBlocked end
local accessibleNewBar = Region()
accessibleNewBar:SetWidth(180); accessibleNewBar:SetHeight(25)
plateFrame.healthBar = accessibleNewBar
ns.RefreshAll()
equal(accessibleNewBar.width, 180, "restricted retired bar defers replacement styling")
retiredBlocked = false
events.scripts.OnUpdate(events, 0.25)
equal(accessibleNewBar.width, 270, "replacement styled when retired bar accessible")
ns.RestoreAll()
equal(accessibleNewBar.width, 180, "replacement width restores after access retry")

-- Target/mouseover highlights remain native through repairs and both disable paths.
for _, disableMaster in ipairs({false, true}) do
    for _, initiallyShown in ipairs({false, true}) do
        ns.RestoreAll()
        stylingEnabled, categoryMode = true, "active"
        unit = {reaction = 3}
        plateFrame.selectionHighlight = Region()
        plateFrame.selectionHighlight:SetShown(initiallyShown)
        ns.RefreshAll()
        equal(plateFrame.selectionHighlight.shown, initiallyShown, "styling preserves native selection highlight")
        ns.NameplatePresentation.RepairHealthColor(plateFrame)
        ns.NameplatePresentation.RepairName(plateFrame)
        equal(plateFrame.selectionHighlight.shown, initiallyShown, "repairs preserve native selection highlight")
        plateFrame.selectionHighlight:SetShown(not initiallyShown)
        ns.NameplatePresentation.RepairHealthColor(plateFrame)
        ns.NameplatePresentation.RepairName(plateFrame)
        equal(plateFrame.selectionHighlight.shown, not initiallyShown, "repairs preserve changed native selection")
        if disableMaster then stylingEnabled = false; ns.RestoreAll()
        else categoryMode = "inactive"; ns.RefreshAll() end
        equal(plateFrame.selectionHighlight.shown, not initiallyShown, "disable preserves live selection visibility")
    end
end
stylingEnabled, categoryMode = true, "active"

-- Native classification can hide a retained atlas after reuse or raid marking.
for _, disableMaster in ipairs({false, true}) do
    ns.RestoreAll()
    stylingEnabled, categoryMode = true, "active"
    unit = {reaction = 3}
    plateFrame.ClassificationFrame, plateFrame.classificationIndicator = Region(), Region()
    plateFrame.ClassificationFrame.classificationIndicator = plateFrame.classificationIndicator
    plateFrame.ClassificationFrame.classificationAtlasElement = nil
    plateFrame.classificationIndicator.atlas = "nameplates-icon-elite-gold"
    plateFrame.ClassificationFrame:Hide()
    ns.RefreshAll()
    ns.NameplatePresentation.RepairHealthColor(plateFrame)
    ns.NameplatePresentation.RepairName(plateFrame)
    equal(plateFrame.ClassificationFrame.shown, false, "styling cannot expose retained classification atlas")
    plateFrame.ClassificationFrame:Show()
    plateFrame.classificationIndicator:Hide()
    ns.NameplatePresentation.RepairName(plateFrame)
    equal(plateFrame.ClassificationFrame.shown, true, "native classification show preserved")
    equal(plateFrame.classificationIndicator.shown, false, "native classification icon hide preserved")
    if disableMaster then stylingEnabled = false; ns.RestoreAll()
    else categoryMode = "inactive"; ns.RefreshAll() end
    equal(plateFrame.ClassificationFrame.shown, true, "disable preserves changed native classification")
    equal(plateFrame.classificationIndicator.shown, false, "disable preserves changed native icon visibility")
end
stylingEnabled, categoryMode = true, "active"

-- Use the native nested layout for title transitions and cast decisions.
ns.RestoreAll()
stylingEnabled, categoryMode, highlightEnabled = true, "active", true
unit = {player = true, faction = "Alliance", reaction = 5}
trp3Options = {showFullTitle = true}
ns.TRP3 = {GetDisplayInfo = function() return {fullTitle = "Visible RP title"} end}
local nestedCast = plateFrame.castBar
nestedCast.Icon:SetShown(true)
plateFrame.CastBarsContainer = Region()
plateFrame.CastBarsContainer.castBar = nestedCast
plateFrame.castBar, plateFrame.CastBar = nil, nil
nestedCast:Show()
ns.RefreshAll()
equal(plateFrame.SNPPresentation.showCastBar, true, "native nested cast included in presentation")
equal(plateFrame.SNPFullTitleText.shown, false, "native nested cast hides long title")
equal(plateFrame.SNPInterruptibleHighlight.castBar, nestedCast, "highlight uses native nested cast")
equal(plateFrame.SNPInterruptibleHighlight.frame.shown, true, "nested interruptible cast permits highlight")
events.scripts.OnEvent(events, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "nameplate1")
events.scripts.OnUpdate(events, 0.01)
equal(plateFrame.SNPInterruptibleHighlight.frame.shown, false, "not-interruptible event hides highlight")
events.scripts.OnEvent(events, "UNIT_SPELLCAST_INTERRUPTIBLE", "nameplate1")
events.scripts.OnUpdate(events, 0.01)
equal(plateFrame.SNPInterruptibleHighlight.frame.shown, true, "interruptible event restores highlight")
nestedCast:Hide()
equal(plateFrame.SNPFullTitleText.shown, true, "nested cast end restores title without restyling")
nestedCast:Show()
equal(plateFrame.SNPFullTitleText.shown, false, "nested channel start hides title")
stylingEnabled = false; ns.RestoreAll()
equal(nestedCast.shown, true, "disable preserves native nested cast visibility")
equal(plateFrame.SNPInterruptibleHighlight.frame.shown, false, "disable hides nested cast effect")
nestedCast:Hide()
equal(plateFrame.SNPFullTitleText.shown, false, "nested cast end cannot revive disabled title")

-- Coordinate every displayed health label with threat and the inside name.
ns.RestoreAll()
stylingEnabled, categoryMode = true, "active"
unit, ns.TRP3 = {reaction = 3}, nil
local healthLabels = {}
for _, key in ipairs({"LeftText", "RightText", "Text"}) do
    local label = Region()
    label:SetFont("NativeHealthFont", 14, "")
    label:SetText(key == "LeftText" and "75%" or "123k")
    label:SetPoint("RIGHT", plateFrame.healthBar, "RIGHT", -4, 0)
    healthLabels[key], plateFrame.healthBar[key] = label, label
end
for _, placement in ipairs({"INSIDE", "ABOVE"}) do
    for _, showThreat in ipairs({false, true}) do
        for _, visible in ipairs({{}, {"Text"}, {"LeftText"}, {"RightText"}, {"LeftText", "RightText"}}) do
            ns.RestoreAll()
            local selected = {}
            for _, key in ipairs(visible) do selected[key] = true end
            for key, label in pairs(healthLabels) do label:SetShown(selected[key] == true) end
            appearance.namePlacement, threatEnabled, threatPercent = placement, showThreat, 100
            ns.RefreshAll()
            local preceding = showThreat and plateFrame.SNPThreatText or plateFrame.healthBar
            if showThreat then
                equal(preceding.points[1][2], plateFrame.healthBar, "threat keeps bar right edge")
                equal(preceding.points[1][4], -3, "threat keeps right padding")
            end
            for _, key in ipairs({"LeftText", "RightText", "Text"}) do
                local label = healthLabels[key]
                if selected[key] then
                    equal(label.points[1][2], preceding, "health labels form a nonoverlapping chain")
                    equal(label.points[1][3], preceding == plateFrame.healthBar and "RIGHT" or "LEFT", "health labels anchor to preceding left edge")
                    equal(label.points[1][4], -3, "health labels leave three-unit gaps")
                    equal(label.points[1][5], preceding == plateFrame.healthBar and -0.5 or 0, "health labels share baseline")
                    preceding = label
                end
                equal(label.shown, selected[key] == true, "native health visibility preserved")
            end
            if placement == "INSIDE" then
                equal(plateFrame.SNPInsideName.points[2][2], preceding, "name reserves all health and threat text")
            end
            ns.RestoreAll()
            for _, label in pairs(healthLabels) do
                equal(label.points[1][2], plateFrame.healthBar, "native health anchor restored")
                equal(label.points[1][4], -4, "native health horizontal offset restored")
                equal(label.points[1][5], 0, "native health vertical offset restored")
            end
        end
    end
end
-- A health-value visibility change can leave the same leftmost label in place.
for _, label in pairs(healthLabels) do label:Show() end
appearance.namePlacement, threatEnabled = "INSIDE", true
ns.RefreshAll()
healthLabels.RightText:Hide()
events.scripts.OnUpdate(events, 0.25)
equal(healthLabels.Text.points[1][2], healthLabels.LeftText, "reconciliation removes hidden middle label")
healthLabels.RightText:Show()
events.scripts.OnUpdate(events, 0.25)
equal(healthLabels.Text.points[1][2], healthLabels.RightText, "reconciliation reserves newly shown middle label")
local nativeLabelBlocked = true
healthLabels.RightText.IsForbidden = function() return nativeLabelBlocked end
stylingEnabled = false; ns.RestoreAll()
assert(ns.NameplateRestoration.IsPending(plateFrame), "inaccessible health label defers restoration")
nativeLabelBlocked = false
events.scripts.OnUpdate(events, 0.25)
equal(healthLabels.RightText.points[1][4], -4, "health-label restoration retries after access returns")

-- Unknown native visibility reserves space without inspecting opaque health text.
stylingEnabled = true
for _, label in pairs(healthLabels) do label:Hide() end
local opaqueHealth = setmetatable({}, {__tostring = function() error("opaque health inspected") end})
local oldSecretCheck, oldShown = issecretvalue, healthLabels.LeftText.IsShown
issecretvalue = function(value) return rawequal(value, opaqueHealth) end
healthLabels.LeftText:SetText(opaqueHealth)
healthLabels.LeftText.IsShown = function() return opaqueHealth end
ns.RefreshAll()
equal(plateFrame.SNPInsideName.points[2][2], healthLabels.LeftText, "unknown health visibility conservatively reserves name space")
healthLabels.LeftText.IsShown, issecretvalue = oldShown, oldSecretCheck
ns.RestoreAll()

-- Each category's disabled bar compacts the title under the floating name.
categoryMode, stylingEnabled = "active", true
unit = {reaction = 3, canAttack = true}
ns.TRP3 = {GetDisplayInfo = function() return {fullTitle = "Compact title"} end}
trp3Options.showFullTitle = true
local showBar = false
ns.GetHealthBarEnabled = function() return showBar end
local cast = ns.NameplateFrames.GetCastBar(plateFrame)
if cast then cast:Hide() end
for _, placement in ipairs({"ABOVE", "INSIDE"}) do
    for _, size in ipairs({8, 18, 31}) do
        appearance.namePlacement, appearance.nameSize = placement, size
        showBar = false
        ns.RefreshAll()
        equal(plateFrame.healthBar.shown, false, "bar off hides native health bar")
        equal(plateFrame.name.alpha, 1, "bar off keeps floating name visible")
        equal(plateFrame.SNPPresentation.nameOnly, true, "bar off uses colored floating name")
        equal(plateFrame.SNPInsideName.shown, false, "bar off removes inside copy")
        equal(plateFrame.SNPFullTitleText.points[1][2], plateFrame.name, "title directly below name")
        equal(plateFrame.SNPFullTitleText.points[1][5], -1, "one-unit title gap")
        equal(plateFrame.SNPFullTitleText.size, size - 2, "title exactly two smaller")
        equal(plateFrame.SNPFullTitleText.shown, true, "bar off displays title")
        equal(plateFrame.SNPThreatText.shown, false, "bar off hides threat")
        plateFrame.healthBar:Show()
        events.scripts.OnUpdate(events, 0.25)
        equal(plateFrame.healthBar.shown, false, "reconciliation repairs native reshow")
        showBar = true
        ns.RefreshAll()
        equal(plateFrame.healthBar.shown, true, "bar on restores health")
        equal(plateFrame.SNPFullTitleText.points[1][2], plateFrame.healthBar, "bar on restores title anchor")
    end
end
ns.RestoreAll()

-- Gradient toggles preserve one outlined label, without health-dependent text work.
assert(loadfile("SimpleNameplates/HealthGradient.lua"))("SimpleNameplates", ns)
local gradients = true
ns.GetGradientEnabled = function() return gradients end
function CreateColor(r, g, b, a) return {r=r, g=g, b=b, a=a} end
local function GradientTexture()
    local texture = Region()
    function texture:SetColorTexture(...) self.color = {...} end
    function texture:SetTexture(value) self.texture = value end
    function texture:GetTexture() return self.texture end
    function texture:SetTexCoord() end
    function texture:SetAllPoints(other) self.allPoints = other end
    function texture:SetGradient(...) self.gradient = {...} end
    function texture:AddMaskTexture(mask) self.mask = mask end
    return texture
end
local bar = ns.NameplateFrames.GetHealthBar(plateFrame)
bar.barTexture = GradientTexture()
bar.barTexture:SetTexture("native-fill")
function bar:CreateTexture() return GradientTexture() end
function bar:CreateMaskTexture() return GradientTexture() end
function UnitHealthPercent() error("retired health threshold must not be queried") end
appearance.namePlacement, threatEnabled, threatPercent = "INSIDE", true, 255
ns.RefreshAll()
assert(bar.SNPHealthGradient.shown)
assert(plateFrame.SNPInsideName.flags == "OUTLINE" and plateFrame.SNPInsideName.SNPUnderlayers == nil)
events.scripts.OnUpdate(events, 0.25)
gradients = false
ns.RefreshAll()
assert(not bar.SNPHealthGradient.shown)
assert(plateFrame.SNPInsideName.flags == "OUTLINE" and plateFrame.SNPInsideName.SNPUnderlayers == nil)
gradients = true
ns.RefreshAll()
ns.RestoreAll()
assert(not bar.SNPHealthGradient.shown, "global restoration removes gradient")

-- Use fresh interaction/title observations, independent of earlier cache fixtures.
UnitIsInteractable = function() return unit.interactable or false end
ns.NPCTitles.GetTitle = function() return "<Background subtitle>" end
local dimBackground = false
ns.GetDimBackgroundNames = function() return dimBackground end
gradients = false
unit = {reaction = 5}
for _, barEnabled in ipairs({true, false}) do
    showBar = barEnabled
    for _, placement in ipairs({"ABOVE", "INSIDE"}) do
        appearance.namePlacement = placement
        for _, enabled in ipairs({false, true}) do
            dimBackground = enabled
            ns.RefreshAll()
            equal(plateFrame.SNPState, "useless", "background classification")
            local expected = enabled and 153 / 255 or 1
            equal(plateFrame.name.r, expected, "background native name shade")
            equal(plateFrame.name.g, expected, "background native name green")
            equal(plateFrame.name.b, expected, "background native name blue")
            equal(plateFrame.SNPFullTitleText.r, expected, "background title matches name red")
            equal(plateFrame.SNPFullTitleText.g, expected, "background title matches name green")
            equal(plateFrame.SNPFullTitleText.b, expected, "background title matches name blue")
            if barEnabled and placement == "INSIDE" then
                equal(plateFrame.SNPInsideName.r, expected, "background inside name shade")
            end
            plateFrame.name:SetTextColor(0, 0, 0)
            ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get())
            equal(plateFrame.name.r, expected, "cached repair preserves dimming")
        end
    end
end
showBar = true; unit = {reaction = 5, interactable = true}
ns.RefreshAll()
equal(plateFrame.name.r, 1, "interactive NPC name stays white")
equal(plateFrame.SNPFullTitleText.r, 1, "interactive NPC title stays white")
ns.NPCTitles.GetTitle = function() return nil end

-- Native one-line title layout is constrained even when the bar is hidden.
ns.TRP3 = {GetDisplayInfo = function() return {fullTitle = "A very long roleplaying title with wide glyphs WWW and accented é characters"} end}
trp3Options.showFullTitle = true
for _, enabled in ipairs({true, false}) do
    showBar = enabled
    appearance.healthBarWidth = 100
    ns.RefreshAll()
    local title = plateFrame.SNPFullTitleText
    local healthBar = ns.NameplateFrames.GetHealthBar(plateFrame)
    equal(title.width, healthBar.width, "title uses bar width with either visibility")
    equal(title.wordWrap, false, "title cannot wrap")
    equal(title.maxLines, 1, "title remains single line")
    local source = title.text
    appearance.healthBarWidth = 120; ns.RefreshAll()
    equal(title.width, healthBar.width, "wider bar updates title constraint")
    equal(title.text, source, "constraint retains source title for native truncation")
    title:SetWidth(999)
    assert(ns.NameplateText.CachedNameHasDrifted(plateFrame, ns.WorldContext.Get()))
    ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get())
    equal(title.width, healthBar.width, "cached repair restores title width")
end
appearance.healthBarWidth = 100; ns.RefreshAll()
local title = plateFrame.SNPFullTitleText
local healthBar = ns.NameplateFrames.GetHealthBar(plateFrame)
healthBar:SetWidth(73)
assert(ns.NameplateText.CachedNameHasDrifted(plateFrame, ns.WorldContext.Get()))
ns.NameplateText.RepairCachedName(plateFrame, ns.WorldContext.Get())
equal(title.width, 73, "native bar resizing updates title without full restyling")

print("Nameplates smoke: passed")
