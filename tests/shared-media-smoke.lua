-- Run the bundled libraries and real font/profile adapter, including load order.
function getfenv() return _G end
function GetLocale() return "enUS" end
function securecallfunction(callback, ...) return callback(...) end
strmatch = string.match
bit = {band = function(a, b)
    local result, place = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then result = result + place end
        a, b, place = math.floor(a / 2), math.floor(b / 2), place * 2
    end
    return result
end}
function UnitGUID() return "Player-Media" end
function UnitFullName() return "Player", "Realm" end
function strtrim(value) return value:match("^%s*(.-)%s*$") end
local function Load(file, ns) assert(loadfile("SimpleNameplates/" .. file))("SimpleNameplates", ns) end
Load("Libs/LibStub/LibStub.lua")
Load("Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua")
Load("Libs/LibSharedMedia-3.0/LibSharedMedia-3.0.lua")
local media = LibStub("LibSharedMedia-3.0")
local refreshes, controls = 0, 0
local function Core()
    local ns = {}
    for _, file in ipairs({"Defaults.lua", "FontMedia.lua", "Core.lua", "ManagedNames.lua", "Database.lua"}) do Load(file, ns) end
    ns.QueueNameplateRefresh = function() refreshes = refreshes + 1 end
    ns.RefreshFontControls = function() controls = controls + 1 end
    return ns
end
local ns = Core()
local function Has(value, selected)
    for _, option in ipairs(ns.GetFontOptions(selected)) do if option.value == value then return option end end
end
assert(ns.FontPath("FRIZQT") == "Fonts\\FRIZQT__.TTF", "legacy font path preserved")
assert(Has("ARIALN") and Has("2002B"), "all built-in choices remain")
assert(not Has("LSM:Arial Narrow"), "duplicate built-in path omitted")
assert(media:Register("font", "Media Font", "Interface\\AddOns\\MediaPack\\font.ttf"))
assert(refreshes == 1 and controls == 1, "late font registration queues presentation and refreshes controls")
assert(Has("LSM:Media Font"), "registered font available")
ns.SetAppearanceSetting("nameFont", "LSM:Media Font")
ns.SetAppearanceSetting("threatFont", "LSM:Media Font")
assert(ns.FontPath(ns.GetAppearanceSetting("nameFont")) == "Interface\\AddOns\\MediaPack\\font.ttf")
ns.SetAppearanceSetting("nameFont", "LSM:Missing")
assert(ns.GetAppearanceSetting("nameFont") == "LSM:Media Font", "setter rejects unavailable fonts")
ns.CopyActiveProfile("Media profile")
media.MediaTable.font["Media Font"] = nil
media.MediaList.font = nil
-- Simulate a new session in which the provider has not loaded.
ns = Core()
assert(ns.GetAppearanceSetting("nameFont") == "LSM:Media Font", "missing saved choice survives reload")
assert(ns.GetAppearanceSetting("threatFont") == "LSM:Media Font", "threat choice survives reload")
assert(ns.FontPath("LSM:Media Font") == "Fonts\\ARIALN.TTF", "missing provider uses safe fallback")
assert(Has("LSM:Media Font", "LSM:Media Font").label == "Media Font (unavailable)", "missing choice shown clearly")
assert(media:Register("font", "Media Font", "Interface\\AddOns\\MediaPack\\returned.ttf"))
assert(ns.FontPath("LSM:Media Font") == "Interface\\AddOns\\MediaPack\\returned.ttf", "late provider resolves without reselecting")
assert(Has("LSM:Media Font", "LSM:Media Font").label == "Media Font", "late font label updates")
local before = refreshes
media:Register("statusbar", "Media Bar", "Interface\\AddOns\\MediaPack\\bar.tga")
assert(refreshes == before, "unrelated registrations do not refresh plates")
media:SetGlobal("font", "Friz Quadrata TT")
assert(ns.FontPath("LSM:Media Font") == media:Fetch("font", "Friz Quadrata TT"), "global shared-font override respected")
assert(ns.FontPath("FRIZQT") == "Fonts\\FRIZQT__.TTF", "legacy selection unaffected by shared override")
media:SetGlobal("font", nil)
ns.ResetAppearance()
assert(ns.GetAppearanceSetting("nameFont") == "FRIZQT" and ns.GetAppearanceSetting("threatFont") == "ARIALN", "reset preserves built-in defaults")
assert(not ns.IsSavedFontSelection("LSM:") and not ns.IsSavedFontSelection("LSM:bad\nkey"), "malformed saved keys rejected")
Load("Libs/LibSharedMedia-3.0/LibSharedMedia-3.0.lua")
assert(LibStub("LibSharedMedia-3.0") == media and media:IsValid("font", "Media Font"), "second embed preserves registry")
local oldStub = LibStub
LibStub = nil
local bare = Core()
assert(bare.FontPath("LSM:Media Font") == "Fonts\\ARIALN.TTF" and #bare.GetFontOptions() == 6, "adapter safely handles absent library")
LibStub = oldStub
print("Shared media smoke: passed")
