-- Converted Colors page with real DF, real profile database and native UI stubs.
local ui = dofile("tests/details-framework-ui-stubs.lua")
dofile("tests/details-framework-loader.lua")("Libs/DetailsFramework/load.xml")
function UnitGUID() return "Player-Colors" end
function UnitFullName() return "Colors", "Realm" end
function strtrim(text) return text:match("^%s*(.-)%s*$") end
function GameTooltip:SetOwner(frame) self.owner = frame end
function GameTooltip:AddLine() end
local ns, refreshes = {}, 0
for _, file in ipairs({"Defaults", "FontMedia", "Core", "ManagedNames", "Database",
    "SettingsControls", "SettingsColorPicker", "SettingsWidgets", "SettingsProfileDialogs", "SettingsProfiles", "SettingsColors"}) do
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

-- Adapted profile selector stays shared; switching refreshes DF controls silently.
local selector
for _, object in ipairs(ui.objects) do
    if object:GetParent() == Row("Selected profile") and object.MyObject and object.MyObject.type == "dropdown" then selector = object end
end
ns.SetAppearanceSetting("nameSize", 31)
local preservedDefault = Snapshot(ns.EnsureDB().profiles.Default)
for _, option in ipairs(selector.MyObject.func()) do
    if option.value == "High Contrast" then option.onclick(nil, nil, option.value) end
end
assert(ns.GetActiveProfileName() == "High Contrast" and selector.MyObject.myvalue == "High Contrast")
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
-- Old picker callbacks must not undo a reset or write into the next profile.
local attacking = Control(Row("1. Attacking me"), "color")
ns.SetPriorityColor("attacking", 0.7, 0.8, 0.9)
panel:GetScript("OnShow")(panel)
Click(attacking)
local oldPicker = ColorPickerFrame.info
oldPicker.swatchFunc()
Click(resetAll)
oldPicker.cancelFunc()
RGBEqual({ns.PriorityColorForState("attacking")}, 1, 0, 1)
oldPicker.swatchFunc()
RGBEqual({ns.PriorityColorForState("attacking")}, 1, 0, 1)
-- Switching profiles rolls back the original profile before refreshing the new one.
ns.SetPriorityColor("attacking", 0.7, 0.8, 0.9)
panel:GetScript("OnShow")(panel)
Click(attacking); oldPicker = ColorPickerFrame.info; oldPicker.swatchFunc()
local target = Snapshot(ns.EnsureDB().profiles.Default)
for _, option in ipairs(selector.MyObject.func()) do
    if option.value == "Default" then option.onclick(nil, nil, option.value) end
end
RGBEqual({ns.EnsureDB().profiles["High Contrast"].priorityColors.attacking.r,
    ns.EnsureDB().profiles["High Contrast"].priorityColors.attacking.g,
    ns.EnsureDB().profiles["High Contrast"].priorityColors.attacking.b}, 0.7, 0.8, 0.9)
oldPicker.cancelFunc(); oldPicker.swatchFunc()
assert(Snapshot(ns.EnsureDB().profiles.Default) == target)
Click(attacking); oldPicker = ColorPickerFrame.info; oldPicker.swatchFunc()
local reset = Control(Row("1. Attacking me"), "button")
Click(reset); oldPicker.cancelFunc()
RGBEqual({ns.PriorityColorForState("attacking")}, 1, 0, 0)
Click(attacking); oldPicker = ColorPickerFrame.info; oldPicker.swatchFunc()
panel:GetScript("OnHide")(panel); oldPicker.swatchFunc()
RGBEqual({ns.PriorityColorForState("attacking")}, 1, 0, 0)
print("Colors settings integration smoke: passed")


-- Direct database mutations retire edits before changing their captured target.
local function OpenPreview()
    ns.SetPriorityColor("attacking", 0.7, 0.8, 0.9)
    panel.Refresh()
    Click(attacking)
    local edit = ColorPickerFrame.info
    assert(edit.extraInfo.owner and edit.extraInfo.target.name == ns.GetActiveProfileName())
    assert(edit.extraInfo.target.object == ns.GetProfile(ns.GetActiveProfileName()))
    edit.swatchFunc()
    RGBEqual({ns.PriorityColorForState("attacking")}, 0.2, 0.3, 0.4)
    return edit
end
local serial = 0
for _, mutate in ipairs({
    function() assert(ns.SetActiveProfileName("Default")) end,
    function() assert(ns.CreateProfile("Created directly")) end,
    function() assert(ns.CopyActiveProfile("Copied directly")) end,
    function() assert(ns.RenameActiveProfile("Renamed directly")) end,
    function() assert(ns.DeleteActiveProfile()) end,
    function() ns.RestoreBundledProfiles() end,
    function() ns.ResetPriorityColor("attacking") end,
    function() ns.ResetEffectColor("interruptible") end,
    function() ns.ResetAllColors() end,
    function() ns.ResetAppearance() end,
}) do
    serial = serial + 1
    assert(ns.CreateProfile("Direct mutation " .. serial))
    local edit = OpenPreview()
    local original = edit.extraInfo.target.object
    mutate()
    assert(not ColorPickerFrame:IsShown(), "database mutation closes its picker")
    local saved = Snapshot(SimpleNameplatesDB)
    edit.cancelFunc(); edit.swatchFunc()
    assert(Snapshot(SimpleNameplatesDB) == saved, "database mutations retire picker callbacks")
    if serial <= 6 then
        RGBEqual({original.priorityColors.attacking.r, original.priorityColors.attacking.g,
            original.priorityColors.attacking.b}, 0.7, 0.8, 0.9)
    end
end
-- Invalid mutations leave the current edit intact.
local edit = OpenPreview()
assert(not ns.SetActiveProfileName("Missing"))
assert(not ns.CreateProfile(""))
assert(ColorPickerFrame:IsShown())
edit.cancelFunc()
RGBEqual({ns.PriorityColorForState("attacking")}, 0.7, 0.8, 0.9)
-- Same-name replacement is rejected even if a caller bypasses database mutations.
edit = OpenPreview()
local name, original = ns.GetActiveProfileName(), ns.GetProfile(ns.GetActiveProfileName())
ns.EnsureDB().profiles[name] = ns.GetProfile("High Contrast")
local saved = Snapshot(SimpleNameplatesDB)
edit.swatchFunc(); edit.cancelFunc()
assert(Snapshot(SimpleNameplatesDB) == saved, "replacement identity cannot receive old preview or rollback")
ns.EnsureDB().profiles[name] = original
saved = Snapshot(SimpleNameplatesDB)
edit.swatchFunc(); edit.cancelFunc()
assert(Snapshot(SimpleNameplatesDB) == saved, "cancel retires replaced-target callbacks permanently")
print("PASS direct database mutation and picker target identity")
