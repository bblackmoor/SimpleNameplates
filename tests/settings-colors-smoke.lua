-- Converted Colors page with real DF, real profile database and native UI stubs.
local ui = dofile("tests/details-framework-ui-stubs.lua")
dofile("tests/details-framework-loader.lua")("Libs/DetailsFramework/load.xml")
function UnitGUID() return "Player-Colors" end
function UnitFullName() return "Colors", "Realm" end
function strtrim(text) return text:match("^%s*(.-)%s*$") end
function UIDropDownMenu_SetWidth(frame, width) frame:SetWidth(width) end
function UIDropDownMenu_SetSelectedValue(frame, value) frame.selected = value end
function UIDropDownMenu_SetText(frame, value) frame:SetText(value) end
function UIDropDownMenu_Initialize(frame, callback) frame.initialize = callback end
function UIDropDownMenu_CreateInfo() return {} end
local profileOptions = {}
function UIDropDownMenu_AddButton(option) profileOptions[#profileOptions + 1] = option end
function GameTooltip:SetOwner(frame) self.owner = frame end
function GameTooltip:AddLine() end
local ns, refreshes = {}, 0
for _, file in ipairs({"Defaults", "FontMedia", "Core", "ManagedNames", "Database",
    "SettingsControls", "SettingsWidgets", "SettingsProfiles", "SettingsColors"}) do
    assert(loadfile("SimpleNameplates/" .. file .. ".lua"))("SimpleNameplates", ns)
end
ns.RefreshAll = function() refreshes = refreshes + 1 end
ns.EnsureDB()
ns.GetActiveProfileName() -- Resolve the normal character assignment before testing UI refresh.
local function Snapshot(value)
    if type(value) ~= "table" then return tostring(value) end
    local entries = {}
    for key, item in pairs(value) do entries[#entries + 1] = tostring(key) .. "=" .. Snapshot(item) end
    table.sort(entries)
    return "{" .. table.concat(entries, ",") .. "}"
end
local initial = Snapshot(SimpleNameplatesDB)
local panel = ns.SettingsPanels.Colors()
assert(Snapshot(SimpleNameplatesDB) == initial and refreshes == 0, "constructing Colors is read-only")
local function Row(text)
    for _, object in ipairs(ui.objects) do
        if object.kind == "FontString" and object:GetText() == text then return object:GetParent() end
    end
    error("Missing row " .. text)
end
local function Control(row, kind)
    for _, object in ipairs(ui.objects) do
        local widget = object.MyObject
        if object:GetParent() == row and widget then
            if kind == "color" and widget.__iscolorpicker then return object end
            if widget.type == kind and not widget.__iscolorpicker then return object end
        end
    end
    error("Missing control " .. kind)
end
local function Click(frame)
    frame:GetScript("OnMouseDown")(frame, "LeftButton")
    frame:GetScript("OnMouseUp")(frame, "LeftButton")
end
local function RGBEqual(actual, r, g, b)
    assert(actual[1] == r and actual[2] == g and actual[3] == b, "RGB mismatch")
end
local function SwatchRGB(frame) return {frame.MyObject:GetColor()} end
local cases = {
    {"attacking", "1. Attacking me"}, {"hostile", "2. Will attack me — Hostile"},
    {"neutral", "3. Can attack me — Neutral"}, {"friendly", "4. Player - Friendly"},
    {"useful", "5. NPC - Interactive"}, {"useless", "6. NPC - Background"},
}
for _, case in ipairs(cases) do
    local state, row = case[1], Row(case[2])
    local swatch, toggle, reset = Control(row, "color"), Control(row, "switch"), Control(row, "button")
    assert(swatch:GetWidth() == 26 and swatch:GetHeight() == 26)
    assert(reset:GetWidth() == 54 and reset:GetHeight() == 22)
    assert(toggle.MyObject.is_toggle and toggle:GetWidth() == 44)
    assert(swatch.point[4] == 340 and toggle.point[2] == swatch and toggle.point[4] == 8)
    assert(swatch.MyObject.color_texture.points.TOPLEFT[4] == 3)
    assert(swatch.MyObject.color_texture.points.BOTTOMRIGHT[5] == 3)
    swatch:GetScript("OnEnter")(swatch)
    assert(GameTooltip.owner == swatch and GameTooltip:GetText() == case[2], "native tooltip owner")
    swatch:GetScript("OnLeave")(swatch)
    local before = refreshes
    toggle:GetScript("OnClick")(toggle, "LeftButton")
    assert(ns.GetCategoryMode(state) == "inactive" and refreshes == before + 1)
    local oldR, oldG, oldB = ns.PriorityColorForState(state)
    Click(swatch)
    local picker = ColorPickerFrame.info
    assert(picker.hasOpacity == false)
    function ColorPickerFrame:GetColorRGB() return 0.2, 0.3, 0.4 end
    picker.swatchFunc()
    RGBEqual({ns.PriorityColorForState(state)}, 0.2, 0.3, 0.4)
    RGBEqual(SwatchRGB(swatch), 0.2, 0.3, 0.4)
    picker.cancelFunc()
    RGBEqual(SwatchRGB(swatch), oldR, oldG, oldB)
    RGBEqual({ns.PriorityColorForState(state)}, oldR, oldG, oldB)
    ns.SetPriorityColor(state, 0.8, 0.7, 0.6)
    Click(reset)
    local default = ns.Defaults.priorityColors[state]
    RGBEqual(SwatchRGB(swatch), default.r, default.g, default.b)
    assert(ns.GetCategoryMode(state) == "inactive", "individual reset preserves global mode")
    assert(refreshes == before + 4, "each user edit refreshes plates once; redraws are silent")
end

local effect = Control(Row("Effect"), "dropdown")
assert(effect.point[4] == 340 and effect:GetWidth() == 190)
local expected = {"NONE", "PIXEL", "AUTOCAST", "BUTTON", "PROC"}
for i, option in ipairs(effect.MyObject.func()) do
    assert(option.value == expected[i])
    local item = CreateFrame("Button", nil, effect.dropdownframe:GetScrollChild())
    item.object, item.table = effect.MyObject, option
    local before = refreshes
    DetailsFrameworkDropDownOptionClick(item)
    assert(ns.GetInterruptibleCastStyle() == expected[i] and effect.MyObject.myvalue == expected[i])
    assert(refreshes == before + 1)
end
local castRow = Row("Interruptible cast highlight")
local cast, castReset = Control(castRow, "color"), Control(castRow, "button")
Click(cast)
local picker = ColorPickerFrame.info
picker.swatchFunc()
RGBEqual({ns.EffectColor("interruptible")}, 0.2, 0.3, 0.4)
picker.cancelFunc()
RGBEqual({ns.EffectColor("interruptible")}, 0, 1, 1)
Click(castReset)
assert(ns.GetInterruptibleCastStyle() == "PROC", "cast-color reset preserves chosen effect")

-- Native profile selector stays shared; switching refreshes DF controls silently.
local selector
for _, object in ipairs(ui.objects) do
    if object:GetParent() == Row("Selected profile") and object.initialize then selector = object end
end
ns.SetAppearanceSetting("nameSize", 31)
local preservedDefault = Snapshot(ns.EnsureDB().profiles.Default)
profileOptions = {}
selector.initialize(nil, 1)
for _, option in ipairs(profileOptions) do if option.value == "High Contrast" then option.func() end end
assert(ns.GetActiveProfileName() == "High Contrast" and selector.selected == "High Contrast")
local highContrast = ns.Defaults.colorPresets.highContrast
RGBEqual(SwatchRGB(Control(Row(cases[1][2]), "color")), 1, 0, 1)
ns.SetPriorityColor("attacking", 0.1, 0.2, 0.3)
ns.SetEffectColor("interruptible", 0.4, 0.5, 0.6)
ns.SetInterruptibleCastStyle("PIXEL")
ns.SetTRP3Enabled(true)
local resetAll
for _, object in ipairs(ui.objects) do
    if object.MyObject and object.MyObject.type == "button" and object.text:GetText() == "Reset all colors" then resetAll = object end
end
assert(resetAll:GetWidth() == 190 and resetAll:GetHeight() == 24)
assert(resetAll.point[5] > castRow.point[5], "whole-page reset remains above controls")
local before = refreshes
Click(resetAll)
assert(refreshes == before + 1 and ns.GetInterruptibleCastStyle() == "NONE")
assert(ns.GetTRP3Enabled() and Snapshot(ns.EnsureDB().profiles.Default) == preservedDefault)
assert(ns.GetActiveProfileName() == "High Contrast")
for _, case in ipairs(cases) do
    local default = highContrast.priorityColors[case[1]]
    RGBEqual(SwatchRGB(Control(Row(case[2]), "color")), default.r, default.g, default.b)
    assert(ns.GetCategoryMode(case[1]) == "active")
end
RGBEqual(SwatchRGB(cast), 0, 1, 0)
initial, before = Snapshot(SimpleNameplatesDB), refreshes
panel:GetScript("OnShow")(panel)
panel:GetScript("OnShow")(panel)
assert(Snapshot(SimpleNameplatesDB) == initial and refreshes == before, "show/reflow refresh is read-only")
assert(ns.GetThreatEnabled() and ns.GetStylingEnabled(), "unrelated global settings preserved")
print("Colors settings integration smoke: passed")
