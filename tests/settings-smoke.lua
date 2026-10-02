-- Characterize WoW settings registration and primary UI callbacks.
-- Run from repository root: lua tests/settings-smoke.lua
local function equal(actual, expected, label)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)), 2)
    end
end

local frames, opened, popups, categories = {}, {}, {}, {}
local function region(kind, parent, template)
    local item = { kind = kind, parent = parent, template = template, enabled = true }
    frames[#frames + 1] = item
    local methods = {
        SetPoint = function(self, point, relative, relativePoint, x, y)
            self.points = self.points or {}; self.points[point] = {relative, relativePoint, x, y}
        end, ClearAllPoints = function(self) self.points = {} end,
        SetAllPoints = function() end, SetSize = function(self, w, h) self.width, self.height = w, h end,
        SetWidth = function(self, w) self.width = w end,
        SetHeight = function(self, h) self.height = h end,
        GetWidth = function(self) return self.width or 640 end,
        GetHeight = function(self) return self.height or 500 end,
        SetText = function(self, value) self.text = value end,
        GetText = function(self) return self.text end,
        SetTextColor = function() end, SetJustifyH = function() end,
        GetStringWidth = function(self) return #(self.text or "") * 8 end,
        GetStringHeight = function(self) return self.naturalHeight or 16 end,
        SetColorTexture = function(self, r, g, b) self.color = {r, g, b} end,
        SetBackdrop = function() end,
        SetBackdropColor = function() end, SetBackdropBorderColor = function() end,
        SetScrollChild = function(self, value) self.scrollChild = value end,
        SetScript = function(self, event, fn) self.scripts = self.scripts or {}; self.scripts[event] = fn end,
        GetScript = function(self, event) return self.scripts and self.scripts[event] end,
        SetEnabled = function(self, yes) self.enabled = yes end,
        IsEnabled = function(self) return self.enabled end,
        SetMinMaxValues = function() end, SetValueStep = function() end,
        SetObeyStepOnDrag = function() end, SetValue = function(self, value) self.value = value end,
        EnableMouse = function() end, SetOwner = function() end,
        AddLine = function() end, Show = function() end, Hide = function() end,
        SetFocus = function() end, HighlightText = function() end,
        GetParent = function(self) return self.parent end,
        GetID = function(self) return self.id end,
        GetEditBox = function(self) return self.editBox end,
        Click = function(self) if self.scripts and self.scripts.OnClick then self.scripts.OnClick(self) end end,
    }
    methods.CreateFontString = function(self) return region("FontString", self) end
    methods.CreateTexture = function(self) return region("Texture", self) end
    return setmetatable(item, { __index = methods })
end
function CreateFrame(kind, _, parent, template)
    local frame = region(kind, parent, template)
    if template == "OptionsSliderTemplate" then
        frame.Low, frame.High, frame.Text = region("FontString", frame), region("FontString", frame), region("FontString", frame)
    end
    return frame
end
GameTooltip = region("Tooltip")
ColorPickerFrame = region("Picker")
function ColorPickerFrame:GetColorRGB() return 0.4, 0.5, 0.6 end
function ColorPickerFrame:SetupColorPickerAndShow(options) self.options = options end
function UIDropDownMenu_SetWidth(item, w) item.width = w end
function UIDropDownMenu_SetSelectedValue(item, value) item.selected = value end
function UIDropDownMenu_SetText(item, value) item.text = value end
function UIDropDownMenu_Initialize(item, fn) item.initialize = fn end
function UIDropDownMenu_CreateInfo() return {} end
local menuOptions = {}
function UIDropDownMenu_AddButton(info) menuOptions[#menuOptions + 1] = info end
StaticPopupDialogs = {}
function StaticPopup_Show(key, text, _, data)
    popups[#popups + 1] = { key = key, text = text, data = data }
end
Settings = {
    RegisterCanvasLayoutCategory = function(panel, name)
        local c = { id = 1, name = name, panel = panel }
        function c:GetID() return self.id end
        categories[#categories + 1] = c
        return c
    end,
    RegisterCanvasLayoutSubcategory = function(_, panel, name)
        local c = { id = #categories + 1, name = name, panel = panel }
        function c:GetID() return self.id end
        categories[#categories + 1] = c
        return c
    end,
    RegisterAddOnCategory = function() end,
    OpenToCategory = function(id) opened[#opened + 1] = id end,
}
SlashCmdList = {}
function strtrim(value) return value:match("^%s*(.-)%s*$") end
function InCombatLockdown() return false end

local active, refreshes, styling = "Default", 0, true
local trp3Enabled, trp3Settings, trp3Refreshes = false, { showFullTitle = true }, 0
local resetStates, allColorResets = {}, 0
local threatEnabled, castEnabled = true, false
local attacking = { 1, 0, 0 }
local npcColors = { useful = {0.8, 0.8, 0.8}, useless = {0.6, 0.6, 0.6} }
local modes = { friendly = "active" }
local profile = { matchSanctuaryFont = true, nameFont = "ARIALN", nameSize = 12, threatFont = "ARIALN", namePlacement = "ABOVE" }
local ns = {
    VERSION = "1.0.test", SOURCE_URL = "https://github.com/bblackmoor/SimpleNameplates",
    FONT_OPTIONS = { { value = "ARIALN", label = "Arial Narrow" } },
    MIN_NAME_SIZE = 8, MAX_NAME_SIZE = 36,
    DEFAULT_PROFILE_NAME = "Default",
    PriorityColorForState = function(state) return unpack(npcColors[state] or attacking) end,
    SetPriorityColor = function(state, r, g, b)
        if npcColors[state] then npcColors[state] = {r, g, b}
        else attacking = {r, g, b} end
    end,
    ResetPriorityColor = function(state)
        resetStates[#resetStates + 1] = state
        if npcColors[state] then npcColors[state] = {0.7, 0.7, 0.7} end
    end,
    EffectColor = function() return 0, 1, 1 end,
    GetCategoryMode = function(key) return modes[key] or "active" end,
    SetCategoryMode = function(key, value) modes[key] = value end,
    GetAppearanceSetting = function(key) return profile[key] end,
    SetAppearanceSetting = function(key, value) profile[key] = value end,
    ResetAppearance = function()
        profile.nameSize, profile.nameFont, profile.threatFont = 21, "FRIZQT", "ARIALN"
        profile.namePlacement, profile.matchSanctuaryFont = "ABOVE", true
    end,
    GetActiveProfileName = function() return active end,
    GetProfileNames = function() return { "Default", "High Contrast" } end,
    SetActiveProfileName = function(name) active = name; return true end,
    CreateProfile = function(name) active = name; return true end,
    CopyActiveProfile = function(name) active = name; return true end,
    RenameActiveProfile = function(name) active = name; return true end,
    DeleteActiveProfile = function() active = "Default"; return true end,
    RestoreBundledProfiles = function() active = "Default" end,
    GetStylingEnabled = function() return styling end,
    SetStylingEnabled = function(value) styling = value end,
    GetThreatEnabled = function() return threatEnabled end,
    SetThreatEnabled = function(value) threatEnabled = value end,
    GetInterruptibleHighlightEnabled = function() return castEnabled end,
    SetInterruptibleHighlightEnabled = function(value) castEnabled = value end,
    ResetAllColors = function() allColorResets = allColorResets + 1 end,
    GetTRP3Enabled = function() return trp3Enabled end,
    SetTRP3Enabled = function(value) trp3Enabled = value end,
    GetTRP3Setting = function(key) return trp3Settings[key] ~= false end,
    SetTRP3Setting = function(key, value) trp3Settings[key] = value end,
    GetHideCritterCompanionNames = function() return false end,
    RefreshAll = function() refreshes = refreshes + 1 end,
    DisableFriendlyClassColors = function() end,
    ApplyManagedNameSettings = function() end,
    RestoreManagedNameSettings = function() end,
    RestoreFriendlyClassColors = function() end,
    RestoreAll = function() end,
    TRP3 = { IsAvailable = function() return false end, Refresh = function() trp3Refreshes = trp3Refreshes + 1 end },
}
for _, name in ipairs({
    "SetEffectColor", "ResetEffectColor",
    "SetHideCritterCompanionNames",
}) do ns[name] = function() end end

local function loadSettings()
    for line in assert(io.open("SimpleNameplates/SimpleNameplates.toc")):lines() do
        if line:match("^Settings[%w]*%.lua$") then
            assert(loadfile("SimpleNameplates/" .. line))("SimpleNameplates", ns)
        end
    end
end
loadSettings()
assert(ns.RegisterSettingsPanel, "settings registration API")
ns.RegisterSettingsPanel()
equal(#categories, 6, "About and five subcategories")
equal(table.concat({categories[1].name,categories[2].name,categories[3].name,categories[4].name,categories[5].name,categories[6].name}, ","),
    "Simple Nameplates,Behavior,Profiles,Appearance,Colors,TRP3", "tab order")
ns.RegisterSettingsPanel()
equal(#categories, 6, "one-time registration")
equal(SLASH_SNP1, "/snp", "slash registration")
for _, route in ipairs({{"",2},{"about",1},{"profiles",3},{"appearance",4},{"colors",5},{"trp3",6}}) do
    SlashCmdList.SNP(route[1])
    equal(opened[#opened], route[2], "route " .. route[1])
end
for _, c in ipairs(categories) do
    if c.panel.scripts and c.panel.scripts.OnShow then c.panel.scripts.OnShow(c.panel) end
end
local function button(text)
    for _, item in ipairs(frames) do
        if item.kind == "Button" and item.text == text then return item end
    end
end
local function switchFor(labelText)
    for _, item in ipairs(frames) do
        if item.kind == "Button" and item.width == 44 then
            for _, label in ipairs(frames) do
                if label.parent == item.parent and label.text == labelText then return item end
            end
        end
    end
end
local sanctuaryFont = assert(switchFor("Match Blizzard font in sanctuaries"))
equal(sanctuaryFont:GetChecked(), true, "sanctuary matching switch reflects profile")
local beforeFontRefresh = refreshes
sanctuaryFont:Click()
equal(profile.matchSanctuaryFont, false, "switch changes profile font choice")
equal(refreshes, beforeFontRefresh + 1, "font switch refreshes nameplates")
profile.matchSanctuaryFont = true
categories[4].panel.scripts.OnShow(categories[4].panel)
equal(sanctuaryFont:GetChecked(), true, "profile refresh synchronizes font switch")

-- Keeping title controls together retains the global value and master gate.
local fullTitle = assert(switchFor("Show TRP3 long title beneath the name"))
equal(fullTitle:GetChecked(), true, "existing full-title value retained")
equal(fullTitle:IsEnabled(), false, "title disabled with TRP3 integration off")
local trp3Master = assert(switchFor("Display TRP3 profile information"))
trp3Master:Click()
categories[6].panel.scripts.OnShow(categories[6].panel)
equal(fullTitle:IsEnabled(), true, "title enabled when integration enabled")
local beforeTitleRefresh = trp3Refreshes
fullTitle:Click()
equal(trp3Settings.showFullTitle, false, "moved control updates original global key")
equal(trp3Refreshes, beforeTitleRefresh + 1, "title change refreshes TRP3 presentation")
trp3Master:Click()
categories[6].panel.scripts.OnShow(categories[6].panel)
equal(fullTitle:IsEnabled(), false, "title gate refreshed after integration disabled")
equal(fullTitle:GetChecked(), false, "disabled integration preserves title choice")
assert(button("Create") and button("Copy") and button("Rename") and button("Delete"),
    "Profile action buttons")
button("Create"):Click()
equal(popups[#popups].key, "SNP_PROFILE_NAME", "create dialog")
local data = popups[#popups].data
local dialog = region("Dialog")
dialog.editBox = region("EditBox", dialog)
dialog.editBox:SetText("New profile")
StaticPopupDialogs.SNP_PROFILE_NAME.OnAccept(dialog, data)
equal(active, "New profile", "create callback")
assert(refreshes > 0, "Profile change refreshes nameplates")
button("Restore bundled profiles"):Click()
equal(popups[#popups].key, "SNP_RESTORE_BUNDLED_PROFILES", "restore confirmation")
StaticPopupDialogs.SNP_RESTORE_BUNDLED_PROFILES.OnAccept(nil, popups[#popups].data)
equal(active, "Default", "restore callback")
equal(StaticPopupDialogs.SNP_BLIZZARD_VENDOR_INFO ~= nil, true, "Blizzard info popup")
local stylingSwitch
for _, item in ipairs(frames) do
    if item.kind == "Button" and item.width == 44 then
        for _, label in ipairs(frames) do
            if label.parent == item.parent and label.text == "Enable Simple Nameplates styling" then
                stylingSwitch = item
            end
        end
    end
end
assert(stylingSwitch, "master styling switch exists")
stylingSwitch:Click()
equal(styling, false, "master styling callback")
local swatch
for _, item in ipairs(frames) do
    if item.kind == "Button" and item.template == "BackdropTemplate" then
        swatch = item
        break
    end
end
assert(swatch, "editable color swatch exists")
swatch:Click()
assert(ColorPickerFrame.options, "color picker opens")
ColorPickerFrame.options.swatchFunc()
equal(attacking[1], 0.4, "color picker applies")
ColorPickerFrame.options.cancelFunc()
equal(attacking[1], 1, "color picker cancel restores")

-- Duplicate NPC controls share a saved key and repaint together in both directions.
local function colorRow(labelText)
    local row
    for _, item in ipairs(frames) do
        if item.kind == "FontString" and item.text == labelText then
            for _, control in ipairs(frames) do
                if control.parent == item.parent and control.kind == "Button"
                    and control.template == "BackdropTemplate" then row = item.parent; break end
            end
            if row then break end
        end
    end
    assert(row, "color row " .. labelText)
    local swatch, reset, fill
    for _, item in ipairs(frames) do
        if item.parent == row and item.kind == "Button" then
            if item.template == "BackdropTemplate" then swatch = item end
            if item.text == "Reset" then reset = item end
        end
    end
    for _, item in ipairs(frames) do
        if item.kind == "Texture" and item.parent == swatch then fill = item; break end
    end
    return assert(swatch), assert(reset), assert(fill)
end
for _, case in ipairs({
    {"useful", "5. Interactive NPC — Useful", "Interactive NPC — Useful", 0.8},
    {"useless", "6. Otherwise — Useless", "Other NPC — Useless", 0.6},
}) do
    local first, firstReset, firstFill = colorRow(case[2])
    local second, secondReset, secondFill = colorRow(case[3])
    first:Click()
    ColorPickerFrame.options.swatchFunc()
    equal(npcColors[case[1]][1], 0.4, "priority copy updates shared NPC color")
    equal(firstFill.color[1], 0.4, "priority swatch updates")
    equal(secondFill.color[1], 0.4, "sanctuary swatch updates immediately")
    ColorPickerFrame.options.cancelFunc()
    equal(firstFill.color[1], case[4], "cancel restores priority swatch")
    equal(secondFill.color[1], case[4], "cancel restores sanctuary swatch")
    second:Click()
    ColorPickerFrame.options.swatchFunc()
    equal(firstFill.color[1], 0.4, "sanctuary edit repaints priority copy")
    secondReset:Click()
    equal(firstFill.color[1], 0.7, "sanctuary reset repaints priority copy")
    equal(secondFill.color[1], 0.7, "sanctuary reset repaints own copy")
    firstReset:Click()
    equal(secondFill.color[1], 0.7, "priority reset repaints sanctuary copy")
end

-- Cross-page selectors reread one selected profile, with management on Profiles only.
local function belongsTo(item, panel)
    while item do
        if item == panel then return true end
        item = item.parent
    end
    return false
end
local function selectorFor(panel)
    for _, label in ipairs(frames) do
        if label.kind == "FontString" and label.text == "Selected profile" and belongsTo(label, panel) then
            for _, item in ipairs(frames) do
                if item.parent == label.parent and item.template == "UIDropDownMenuTemplate" then return item end
            end
        end
    end
end
local profilesSelector = assert(selectorFor(categories[3].panel))
local appearanceSelector = assert(selectorFor(categories[4].panel))
local colorsSelector = assert(selectorFor(categories[5].panel))
menuOptions = {}
colorsSelector.initialize(nil, 1)
for _, option in ipairs(menuOptions) do
    if option.value == "High Contrast" then option.func() end
end
equal(active, "High Contrast", "Colors selector changes shared active profile")
equal(colorsSelector.selected, "High Contrast", "Colors selector updates immediately")
categories[3].panel.scripts.OnShow(categories[3].panel)
categories[4].panel.scripts.OnShow(categories[4].panel)
equal(profilesSelector.selected, "High Contrast", "Profiles selector refreshes on show")
equal(appearanceSelector.selected, "High Contrast", "Appearance selector refreshes on show")
assert(belongsTo(button("Create"), categories[3].panel), "management belongs to Profiles")
assert(belongsTo(fullTitle, categories[6].panel), "long-title switch belongs to TRP3")
local _, _, effectFill = colorRow("Interruptible cast highlight")
assert(belongsTo(effectFill, categories[5].panel), "cast color belongs to Colors")
local castSwitch = assert(switchFor("Highlight interruptible casts and channels"))
assert(belongsTo(castSwitch, categories[4].panel), "cast toggle belongs to Appearance")
resetStates = {}
button("Reset priority colors"):Click()
equal(table.concat(resetStates, ","), "attacking,hostile,neutral,friendly,useful,useless", "priority reset scope")
equal(allColorResets, 0, "priority reset does not call complete color reset")
button("Reset all profile colors"):Click()
equal(allColorResets, 1, "complete color reset remains available")
castEnabled, threatEnabled = true, false
profile.nameSize, profile.matchSanctuaryFont = 31, false
button("Reset text and layout"):Click()
equal(profile.nameSize, 21, "text reset restores size")
equal(profile.matchSanctuaryFont, true, "text reset restores sanctuary switch")
equal(threatEnabled, true, "text reset preserves prior threat-enable behavior")
equal(castEnabled, true, "text reset preserves cast toggle")
equal(allColorResets, 1, "text reset does not reset colors")
-- Shared layout remeasures wrapped descriptions and keeps actions on their own rows.
local sample, content, layout = ns.SettingsUI.CreateScrollablePanel("Sample")
local description = ns.SettingsUI.AddDescription(content, layout, "Wrapped description")
description.naturalHeight = 80
ns.SettingsUI.AddSection(content, layout, "Sample section")
local action = ns.SettingsUI.AddActionButton(content, layout, "Sample action", function() end)
layout:Finish()
equal(description.height, 82, "description uses measured height")
local firstActionY = action.points.TOPLEFT[4]
description.naturalHeight = 120
sample.scripts.OnShow(sample)
equal(description.height, 122, "page show remeasures description")
equal(action.points.TOPLEFT[4], firstActionY - 40, "following action follows text reflow")
equal(action.parent, content, "section action has its own content row")
for _, item in ipairs(frames) do
    if item.kind == "FontString" and item.template == "GameFontNormal" then
        assert(item.text ~= "PRIORITY COLORS" and item.text ~= "IN COMBAT" and item.text ~= "PROFILES", "old caps heading removed")
    end
end

print("Settings smoke: passed")

for _, item in ipairs(frames) do
    assert(item.text ~= "Replace Blizzard overhead names (experimental)", "replacement UI removed")
end
