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
        SetPoint = function() end, ClearAllPoints = function() end,
        SetAllPoints = function() end, SetSize = function(self, w, h) self.width, self.height = w, h end,
        SetWidth = function(self, w) self.width = w end,
        SetHeight = function(self, h) self.height = h end,
        GetWidth = function(self) return self.width or 640 end,
        GetHeight = function(self) return self.height or 500 end,
        SetText = function(self, value) self.text = value end,
        GetText = function(self) return self.text end,
        SetTextColor = function() end, SetJustifyH = function() end,
        GetStringWidth = function(self) return #(self.text or "") * 8 end,
        GetStringHeight = function() return 16 end,
        SetColorTexture = function() end, SetBackdrop = function() end,
        SetBackdropColor = function() end, SetBackdropBorderColor = function() end,
        SetScrollChild = function(self, value) self.scrollChild = value end,
        SetScript = function(self, event, fn) self.scripts = self.scripts or {}; self.scripts[event] = fn end,
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
function UIDropDownMenu_AddButton() end
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
local attacking = { 1, 0, 0 }
local modes = { friendly = "active" }
local profile = { nameFont = "ARIALN", nameSize = 12, threatFont = "ARIALN", namePlacement = "ABOVE" }
local ns = {
    VERSION = "1.0.test", SOURCE_URL = "https://github.com/bblackmoor/SimpleNameplates",
    FONT_OPTIONS = { { value = "ARIALN", label = "Arial Narrow" } },
    MIN_NAME_SIZE = 8, MAX_NAME_SIZE = 36,
    DEFAULT_PROFILE_NAME = "Default",
    PriorityColorForState = function() return unpack(attacking) end,
    SetPriorityColor = function(_, r, g, b) attacking = { r, g, b } end,
    EffectColor = function() return 0, 1, 1 end,
    GetCategoryMode = function(key) return modes[key] or "active" end,
    SetCategoryMode = function(key, value) modes[key] = value end,
    GetAppearanceSetting = function(key) return profile[key] end,
    SetAppearanceSetting = function(key, value) profile[key] = value end,
    ResetAppearance = function() profile.nameSize = 12 end,
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
    GetThreatEnabled = function() return true end,
    GetInterruptibleHighlightEnabled = function() return false end,
    GetTRP3Enabled = function() return false end,
    GetTRP3Setting = function() return true end,
    GetHideCritterCompanionNames = function() return false end,
    GetReplaceBlizzardOverheadNames = function() return false end,
    RefreshAll = function() refreshes = refreshes + 1 end,
    DisableFriendlyClassColors = function() end,
    ApplyOverheadNameReplacement = function() end,
    RestoreOverheadNameSettings = function() end,
    RestoreFriendlyClassColors = function() end,
    RestoreAll = function() end,
    TRP3 = { IsAvailable = function() return false end, Refresh = function() end },
}
for _, name in ipairs({
    "ResetPriorityColor", "SetEffectColor", "ResetEffectColor",
    "ResetAllColors", "SetInterruptibleHighlightEnabled",
    "SetThreatEnabled", "SetHideCritterCompanionNames",
    "SetReplaceBlizzardOverheadNames", "SetTRP3Enabled", "SetTRP3Setting",
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
equal(#categories, 4, "About and three subcategories")
equal(table.concat({categories[1].name,categories[2].name,categories[3].name,categories[4].name}, ","),
    "Simple Nameplates,Behavior,Appearance,TRP3", "tab order")
ns.RegisterSettingsPanel()
equal(#categories, 4, "one-time registration")
equal(SLASH_SNP1, "/snp", "slash registration")
for _, route in ipairs({{"",2},{"about",1},{"appearance",3},{"colors",3},{"trp3",4}}) do
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
button("Restore Bundled Profiles"):Click()
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
print("Settings smoke: passed")
