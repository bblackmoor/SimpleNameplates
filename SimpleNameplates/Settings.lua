-- Simple Nameplates: About and settings pages.

local _, ns = ...
if not ns.PriorityColorForState or not ns.EffectColor then return end

local VERSION, SOURCE_URL = ns.VERSION, ns.SOURCE_URL
local PriorityColorForState = ns.PriorityColorForState
local GetCategoryMode, SetCategoryMode = ns.GetCategoryMode, ns.SetCategoryMode
local SetPriorityColor = ns.SetPriorityColor
local ResetPriorityColor = ns.ResetPriorityColor
local EffectColor, SetEffectColor, ResetEffectColor = ns.EffectColor, ns.SetEffectColor, ns.ResetEffectColor
local ResetAllColors = ns.ResetAllColors
local GetAppearanceSetting, SetAppearanceSetting = ns.GetAppearanceSetting, ns.SetAppearanceSetting
local ResetAppearance = ns.ResetAppearance
local GetInterruptibleHighlightEnabled = ns.GetInterruptibleHighlightEnabled
local SetInterruptibleHighlightEnabled = ns.SetInterruptibleHighlightEnabled
local GetStylingEnabled, SetStylingEnabled = ns.GetStylingEnabled, ns.SetStylingEnabled
local GetThreatEnabled, SetThreatEnabled = ns.GetThreatEnabled, ns.SetThreatEnabled
local GetHideBlizzardMinionNames = ns.GetHideBlizzardMinionNames
local SetHideBlizzardMinionNames = ns.SetHideBlizzardMinionNames
local GetHideCritterCompanionNames = ns.GetHideCritterCompanionNames
local SetHideCritterCompanionNames = ns.SetHideCritterCompanionNames
local GetReplaceBlizzardOverheadNames = ns.GetReplaceBlizzardOverheadNames
local SetReplaceBlizzardOverheadNames = ns.SetReplaceBlizzardOverheadNames

local settingsCategory, behaviorSettingsCategory, appearanceSettingsCategory, trp3SettingsCategory

local function RefreshNameplates()
    if ns.RefreshAll then ns.RefreshAll() end
end

-- Canvas settings pages are not scrollable on their own. Each page owns a
-- scroll frame and a content frame. The cursor makes vertical placement
-- sequential; explicit horizontal offsets and control heights remain useful.
local function CreateScrollablePanel(name)
    local panel = CreateFrame("Frame")
    panel.name = name
    local scroll = CreateFrame("ScrollFrame", nil, panel, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -28, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(640, 1)
    scroll:SetScrollChild(content)

    local desiredHeight = 1
    local function UpdateContentSize(_, width, height)
        width = width or scroll:GetWidth()
        height = height or scroll:GetHeight()
        if width and width > 4 then content:SetWidth(width - 4) end
        content:SetHeight(math.max(desiredHeight, height or 1, 1))
    end
    scroll:SetScript("OnSizeChanged", UpdateContentSize)
    scroll:SetScript("OnShow", function(self)
        UpdateContentSize(self, self:GetWidth(), self:GetHeight())
    end)

    local layout = { parent = content, offset = 18 }
    function layout:Add(region, x, height, gap)
        if height and region.SetHeight then region:SetHeight(height) end
        region:SetPoint("TOPLEFT", self.parent, "TOPLEFT", x or 20, -self.offset)
        self.offset = self.offset + (height or 20) + (gap or 0)
        return region
    end
    function layout:Space(height) self.offset = self.offset + height end
    function layout:Finish(bottomPadding)
        desiredHeight = self.offset + (bottomPadding or 20)
        UpdateContentSize(scroll, scroll:GetWidth(), scroll:GetHeight())
    end
    return panel, content, layout
end

local function AddTitle(content, layout, text)
    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetText(text)
    return layout:Add(title, 20, 24, 4)
end

local function AddDescription(content, layout, text, height)
    local description = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    description:SetJustifyH("LEFT")
    description:SetText(text)
    return layout:Add(description, 20, height or 32, 4)
end

-- Visual switch with the same SetChecked/GetChecked contract as the former checkbox.
local function CreateSwitch(parent, onChanged)
    local switch = CreateFrame("Button", nil, parent)
    switch:SetSize(44, 20)
    local track = switch:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    local thumb = switch:CreateTexture(nil, "ARTWORK")
    thumb:SetSize(18, 16)
    function switch:SetChecked(checked)
        self.checked = checked == true
        thumb:ClearAllPoints()
        if self.checked then
            track:SetColorTexture(0.19, 0.42, 0.31, self:IsEnabled() and 1 or 0.5)
            thumb:SetPoint("RIGHT", self, "RIGHT", -2, 0)
        else
            track:SetColorTexture(0.25, 0.25, 0.26, self:IsEnabled() and 1 or 0.5)
            thumb:SetPoint("LEFT", self, "LEFT", 2, 0)
        end
        thumb:SetColorTexture(0.72, 0.72, 0.73, self:IsEnabled() and 1 or 0.5)
    end
    function switch:GetChecked() return self.checked end
    switch:SetScript("OnEnable", function(self) self:SetChecked(self.checked) end)
    switch:SetScript("OnDisable", function(self) self:SetChecked(self.checked) end)
    switch:SetScript("OnClick", function(self)
        self:SetChecked(not self:GetChecked())
        onChanged(self:GetChecked())
    end)
    switch:SetChecked(false)
    return switch
end

local function AddInfoLink(parent, anchor, popupKey)
    local link = CreateFrame("Button", nil, parent)
    link:SetSize(24, 26)
    link:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
    local circle = link:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    circle:SetPoint("CENTER")
    circle:SetText("O")
    local letter = link:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    letter:SetPoint("CENTER")
    letter:SetText("i")
    link:SetSize(math.ceil(math.max(circle:GetStringWidth(), letter:GetStringWidth()) + 6),
        math.ceil(math.max(circle:GetStringHeight(), letter:GetStringHeight()) + 4))
    link:SetScript("OnClick", function() StaticPopup_Show(popupKey) end)
    return link
end

local function CreateAboutPanel()
    local panel, content, layout = CreateScrollablePanel("About")
    StaticPopupDialogs["SNP_COPY_SOURCE"] = {
        text = "Press Ctrl+C to copy the source URL.", button1 = CLOSE or "Close",
        hasEditBox = true, maxLetters = 255, editBoxWidth = 340,
        OnShow = function(self, url)
            local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
            editBox:SetText(url or self.data or SOURCE_URL)
            editBox:SetFocus()
            editBox:HighlightText()
        end,
        EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }

    AddTitle(content, layout, "Simple Nameplates — About")
    AddDescription(content, layout,
        "A deliberately simple standalone nameplate-color addon. It recolors addon-accessible " ..
        "Blizzard Midnight nameplates with customizable Priority Colors and an optional " ..
        "interruptible cast highlight.")

    local details = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    details:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    details:SetJustifyH("LEFT")
    details:SetText("Version " .. VERSION .. "\nAuthor    Brandon Blackmoor\nCategory  Unit Frames")
    layout:Add(details, 20, 48, 2)

    local sourceRow = CreateFrame("Frame", nil, content)
    sourceRow:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(sourceRow, 20, 18, 2)
    local sourceLabel = sourceRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceLabel:SetPoint("LEFT")
    sourceLabel:SetText("Source    ")
    local sourceLink = CreateFrame("Button", nil, sourceRow)
    sourceLink:SetPoint("LEFT", sourceLabel, "RIGHT")
    local sourceText = sourceLink:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceText:SetPoint("LEFT")
    sourceText:SetText(SOURCE_URL)
    sourceText:SetTextColor(0.35, 0.7, 1, 1)
    sourceLink:SetSize(sourceText:GetStringWidth(), 16)
    sourceLink:SetScript("OnEnter", function() sourceText:SetTextColor(0.65, 0.85, 1, 1) end)
    sourceLink:SetScript("OnLeave", function() sourceText:SetTextColor(0.35, 0.7, 1, 1) end)
    sourceLink:SetScript("OnClick", function() StaticPopup_Show("SNP_COPY_SOURCE", nil, nil, SOURCE_URL) end)

    local information = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    information:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    information:SetJustifyH("LEFT")
    information:SetText(
        "License   GPL-3.0\n\nSlash commands\n" ..
        "    /snp - Open the behavior settings.\n" ..
        "    /snp behavior - Open the behavior settings.\n" ..
        "    /snp appearance (or colors) - Open the appearance settings.\n" ..
        "    /snp trp3 - Open the TRP3 settings.\n" ..
        "    /snp debug - Explain the current target and cast-highlight state.\n" ..
        "    /snp about - Open this About page.")
    layout:Add(information, 20, 145)
    layout:Finish()
    return panel
end

local function OptionLabel(options, value)
    for _, option in ipairs(options) do
        if option.value == value then return option.label end
    end
    return ""
end

local function CreateAppearanceDropdown(content, layout, refreshers, labelText, options, getter, setter)
    local block = CreateFrame("Frame", nil, content)
    block:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(block, 20, 38, 4)
    local label = block:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 4, -12)
    label:SetText(labelText)
    local dropdown = CreateFrame("Frame", nil, block, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 164, 0)
    UIDropDownMenu_SetWidth(dropdown, 190)

    local function Refresh()
        local value = getter()
        UIDropDownMenu_SetSelectedValue(dropdown, value)
        UIDropDownMenu_SetText(dropdown, OptionLabel(options, value))
    end
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for _, option in ipairs(options) do
            local value, optionLabel = option.value, option.label
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value = optionLabel, value
            info.checked = getter() == value
            info.func = function()
                setter(value)
                Refresh()
                RefreshNameplates()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    refreshers[#refreshers + 1] = Refresh
    Refresh()
end

local function AddNameSizeControl(content, layout, refreshers)
    local sizeBlock = CreateFrame("Frame", nil, content)
    sizeBlock:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(sizeBlock, 20, 48, 6)
    local sizeLabel = sizeBlock:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", 4, -12)
    local sizeValue = sizeBlock:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sizeValue:SetPoint("TOPLEFT", 460, -12)
    local sizeSlider = CreateFrame("Slider", "SimpleNameplatesNameSizeSlider", sizeBlock, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", 194, -10)
    sizeSlider:SetSize(230, 18)
    sizeSlider:SetMinMaxValues(ns.MIN_NAME_SIZE, ns.MAX_NAME_SIZE)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetObeyStepOnDrag(true)
    sizeSlider.Low:SetText(tostring(ns.MIN_NAME_SIZE))
    sizeSlider.High:SetText(tostring(ns.MAX_NAME_SIZE))
    sizeSlider.Text:SetText("")

    local refreshingSize = false
    local function RefreshNameSize()
        local value = GetAppearanceSetting("nameSize")
        refreshingSize = true
        sizeSlider:SetValue(value)
        refreshingSize = false
        sizeLabel:SetText("Name size")
        sizeValue:SetText(tostring(value) .. " pt")
    end
    sizeSlider:SetScript("OnValueChanged", function(_, rawValue)
        local value = math.floor(rawValue + 0.5)
        sizeValue:SetText(tostring(value) .. " pt")
        if refreshingSize or value == GetAppearanceSetting("nameSize") then return end
        SetAppearanceSetting("nameSize", value)
        RefreshNameplates()
    end)
    refreshers[#refreshers + 1] = RefreshNameSize
    RefreshNameSize()
end

local function AddThreatControl(content, layout, refreshers)
    local row = CreateFrame("Frame", nil, content)
    row:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(row, 24, 30, 4)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT")
    label:SetText("Show threat percentage when available")
    local threat = CreateSwitch(row, function(checked)
        SetThreatEnabled(checked)
        RefreshNameplates()
    end)
    threat:SetPoint("LEFT", label, "RIGHT", 12, 0)
    local function RefreshThreat() threat:SetChecked(GetThreatEnabled()) end
    refreshers[#refreshers + 1] = RefreshThreat
    RefreshThreat()
end

local function AddNameSizeNote(content, layout)
    local note = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    note:SetJustifyH("LEFT")
    note:SetText("Name size applies to addon-controlled floating names and names above health bars. Inside-bar names use 80% of that size, rounded, with two UI units of padding above and below. Blizzard-controlled overhead names cannot be resized.")
    layout:Add(note, 24, 42, 6)
end

local function AddSectionResetButton(content, layout, title, buttonText, onClick)
    local row = CreateFrame("Frame", nil, content)
    row:SetPoint("RIGHT", content, "RIGHT", -24, 0)
    layout:Add(row, 24, 26, 8)
    local heading = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    heading:SetPoint("LEFT", 0, 0)
    heading:SetText(title)
    local reset = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetPoint("LEFT", heading, "RIGHT", 12, 0)
    reset:SetText(buttonText)
    reset:SetScript("OnClick", onClick)
end

local function AddTextAndLayoutControls(content, layout, refreshers)
    AddSectionResetButton(content, layout, "TEXT AND LAYOUT", "Reset Appearance", function()
        ResetAppearance()
        SetThreatEnabled(true)
        for _, refresh in ipairs(refreshers) do refresh() end
        RefreshNameplates()
    end)

    CreateAppearanceDropdown(content, layout, refreshers, "Name font", ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("nameFont") end,
        function(value) SetAppearanceSetting("nameFont", value) end)
    AddNameSizeControl(content, layout, refreshers)
    AddNameSizeNote(content, layout)
    CreateAppearanceDropdown(content, layout, refreshers, "Threat-percentage font", ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("threatFont") end,
        function(value) SetAppearanceSetting("threatFont", value) end)
    CreateAppearanceDropdown(content, layout, refreshers, "Health-bar name placement", {
        { value = "ABOVE", label = "Above bar" }, { value = "INSIDE", label = "Inside bar" },
    }, function() return GetAppearanceSetting("namePlacement") end,
        function(value) SetAppearanceSetting("namePlacement", value) end)
    AddThreatControl(content, layout, refreshers)
end

local function RegisterProfileDialogs()
    StaticPopupDialogs["SNP_PROFILE_NAME"] = {
        text = "Enter a profile name.", button1 = ACCEPT or "Accept",
        button2 = CANCEL or "Cancel", hasEditBox = true, maxLetters = 64,
        editBoxWidth = 260,
        OnShow = function(self, data)
            local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
            editBox:SetText(data and data.initial or "")
            editBox:SetFocus()
            editBox:HighlightText()
        end,
        OnAccept = function(self, data)
            local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
            local ok, message = data.action(editBox:GetText())
            if not ok and message then print("|cff0cd29fSimple Nameplates:|r " .. message) end
            if ok then data.onChanged() end
        end,
        EditBoxOnEnterPressed = function(self)
            local dialog = self:GetParent()
            if dialog.button1 then dialog.button1:Click() end
        end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_DELETE_PROFILE"] = {
        text = "Delete the profile |cffffffff%s|r? Characters using it will switch to Default.",
        button1 = DELETE or "Delete", button2 = CANCEL or "Cancel",
        OnAccept = function(_, data)
            local ok, message = ns.DeleteActiveProfile()
            if not ok and message then print("|cff0cd29fSimple Nameplates:|r " .. message) end
            if ok then data.onChanged() end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_RESTORE_BUNDLED_PROFILES"] = {
        text = "Restore the bundled Default and High Contrast profiles? This replaces their current appearance settings and recreates High Contrast if it was deleted or renamed.",
        button1 = "Restore", button2 = CANCEL or "Cancel",
        OnAccept = function(_, data)
            ns.RestoreBundledProfiles()
            data.onChanged()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
end

local function CreateProfileButtons(content, layout)
    local buttonRow = CreateFrame("Frame", nil, content)
    buttonRow:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(buttonRow, 24, 24, 8)
    local buttons = {}
    for index, definition in ipairs({
        { "Create", 88 }, { "Copy", 88 }, { "Rename", 88 }, { "Delete", 88 },
    }) do
        local button = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
        button:SetSize(definition[2], 24)
        if index == 1 then button:SetPoint("LEFT")
        else button:SetPoint("LEFT", buttons[index - 1], "RIGHT", 8, 0) end
        button:SetText(definition[1])
        buttons[index] = button
    end
    return buttons
end

local function InstallProfileButtonScripts(buttons, changed)
    local create, copy, rename, delete =
        buttons[1], buttons[2], buttons[3], buttons[4]
    local function OpenNameDialog(action, initial)
        StaticPopup_Show("SNP_PROFILE_NAME", nil, nil,
            { action = action, initial = initial, onChanged = changed })
    end
    create:SetScript("OnClick", function() OpenNameDialog(ns.CreateProfile, "") end)
    copy:SetScript("OnClick", function()
        OpenNameDialog(ns.CopyActiveProfile, ns.GetActiveProfileName() .. " Copy")
    end)
    rename:SetScript("OnClick", function()
        OpenNameDialog(ns.RenameActiveProfile, ns.GetActiveProfileName())
    end)
    delete:SetScript("OnClick", function()
        StaticPopup_Show("SNP_DELETE_PROFILE", ns.GetActiveProfileName(), nil,
            { onChanged = changed })
    end)
end

local function AddProfileControls(content, layout, refreshers, onChanged)
    RegisterProfileDialogs()
    local section = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    section:SetText("PROFILES")
    layout:Add(section, 24, 20, 6)
    AddDescription(content, layout,
        "Profiles hold appearance settings and are shared account-wide. Each character remembers its selected profile.", 40)

    local profileRow = CreateFrame("Frame", nil, content)
    profileRow:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(profileRow, 24, 42, 6)
    local label = profileRow:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", 0, 0)
    label:SetText("Selected profile")
    local profileDropdown = CreateFrame("Frame", nil, profileRow, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("LEFT", label, "RIGHT", -4, 0)
    UIDropDownMenu_SetWidth(profileDropdown, 235)

    local buttons = CreateProfileButtons(content, layout)
    local rename, delete = buttons[3], buttons[4]
    local function Changed()
        onChanged()
        RefreshNameplates()
    end
    InstallProfileButtonScripts(buttons, Changed)

    local restore = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    restore:SetSize(172, 24)
    restore:SetText("Restore Bundled Profiles")
    layout:Add(restore, 24, 24, 6)
    restore:SetScript("OnClick", function()
        StaticPopup_Show("SNP_RESTORE_BUNDLED_PROFILES", nil, nil,
            { onChanged = Changed })
    end)
    AddDescription(content, layout,
        "Default can be edited and restored, but not renamed or deleted. Create starts with bundled defaults; Copy uses the selected profile. Restore replaces Default and High Contrast.", 48)

    local function Refresh()
        local active = ns.GetActiveProfileName()
        UIDropDownMenu_SetSelectedValue(profileDropdown, active)
        UIDropDownMenu_SetText(profileDropdown, active)
        local protected = active == ns.DEFAULT_PROFILE_NAME
        rename:SetEnabled(not protected)
        delete:SetEnabled(not protected)
    end
    UIDropDownMenu_Initialize(profileDropdown, function(_, level)
        for _, profileName in ipairs(ns.GetProfileNames()) do
            local name = profileName
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value = name, name
            info.checked = ns.GetActiveProfileName() == name
            info.func = function()
                ns.SetActiveProfileName(name)
                Changed()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    refreshers[#refreshers + 1] = Refresh
    Refresh()
end

local function CreateTRP3Panel()
    local panel, content, layout = CreateScrollablePanel("TRP3")
    AddTitle(content, layout, "Simple Nameplates — TRP3")
    AddDescription(content, layout, "Optional Total RP 3 profile integration. Simple Nameplates continues to work normally when TRP3 is absent.")
    local enabledRow = CreateFrame("Frame", nil, content)
    enabledRow:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(enabledRow, 24, 30, 8)
    local enabledLabel = enabledRow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    enabledLabel:SetPoint("LEFT")
    enabledLabel:SetText("Display TRP3 profile information")
    local refreshOptions
    local enabled = CreateSwitch(enabledRow, function(checked)
        ns.SetTRP3Enabled(checked)
        if ns.TRP3 then ns.TRP3.Refresh() end
        refreshOptions()
    end)
    enabled:SetPoint("LEFT", enabledLabel, "RIGHT", 12, 0)

    local status = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    status:SetJustifyH("LEFT")
    layout:Add(status, 24, 38, 8)
    local section = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    section:SetText("DISPLAY OPTIONS")
    layout:Add(section, 24, 20, 2)

    local optionControls = {}
    local function CreateOption(labelText, setting)
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("RIGHT", content, "RIGHT", -20, 0)
        layout:Add(row, 24, 34, 2)
        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT")
        label:SetText(labelText)
        local option = CreateSwitch(row, function(checked)
            ns.SetTRP3Setting(setting, checked)
            if ns.TRP3 then ns.TRP3.Refresh() end
        end)
        option:SetPoint("LEFT", label, "RIGHT", 12, 0)
        optionControls[#optionControls + 1] = { button = option, label = label, setting = setting }
    end
    CreateOption("Use TRP3 roleplaying full name", "useRoleplayingName")
    CreateOption("Show short title before the name", "showShortTitle")
    CreateOption("Show [OOC] instead of the short title", "showOOC")
    CreateOption("Show long title beneath the name", "showFullTitle")

    local note = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    note:SetJustifyH("LEFT")
    note:SetText("Long titles appear beneath names at 80% of the name size and are hidden for units with visible health bars. If no cached TRP3 profile or selected field is available, the normal WoW name is used.")
    layout:Add(note, 24, 40)

    local function Refresh()
        enabled:SetChecked(ns.GetTRP3Enabled())
        local isEnabled = ns.GetTRP3Enabled()
        for _, control in ipairs(optionControls) do
            control.button:SetChecked(ns.GetTRP3Setting(control.setting))
            control.button:SetEnabled(isEnabled)
            local shade = isEnabled and 1 or 0.5
            control.label:SetTextColor(shade, shade, shade, 1)
        end
        if ns.TRP3 and ns.TRP3.IsAvailable() then
            status:SetText("Total RP 3 detected. Enabled options apply to cached player profiles.")
            status:SetTextColor(0.35, 0.85, 0.35, 1)
        else
            status:SetText("Total RP 3 is not currently available. This setting will take effect when it is installed and enabled.")
            status:SetTextColor(0.75, 0.75, 0.75, 1)
        end
    end
    refreshOptions = Refresh
    panel:SetScript("OnShow", Refresh)
    Refresh()
    layout:Finish()
    return panel
end

local CATEGORY_ROWS = {
    { "1. Attacking me", "attacking", "Includes attacks on pets, guardians, and minions; overrides 2–6" },
    { "2. Will attack me if it notices me", "hostile", "Aggressive units not currently attacking me" },
    { "3. Attackable by me, but not hostile", "unfriendlyNPC", "Units that will not initiate combat" },
    { "4. Opposite-faction PC", "unfriendlyPC", "Non-attackable opponents; attackable opponents use 1 or 2" },
    { "5. My-faction PC", "friendlyPC", "Same-faction player characters" },
    { "6. Anything else Simple Nameplates can color", "other", "Friendly NPCs and other unmatched colorable units" },
}

local function AddSection(content, layout, text)
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetText(text)
    layout:Add(label, 24, 20, 2)
end

local function RunRefreshers(refreshers)
    for _, refresh in ipairs(refreshers) do refresh() end
end

local function CreateBehaviorToggle(context, labelText, noteText, getter, setter, onChanged)
    local content, layout = context.content, context.layout
    local row = CreateFrame("Frame", nil, content)
    row:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(row, 24, 30, 0)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT")
    label:SetText(labelText)
    local toggle
    toggle = CreateSwitch(row, function(checked)
        setter(checked)
        if onChanged then onChanged(checked) end
        toggle:SetChecked(getter())
    end)
    toggle:SetPoint("LEFT", label, "RIGHT", 12, 0)
    if noteText then
        local note = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        note:SetPoint("RIGHT", content, "RIGHT", -20, 0)
        note:SetJustifyH("LEFT")
        note:SetText(noteText)
        layout:Add(note, 24, 34, 8)
    else
        layout:Space(6)
    end

    local function Refresh() toggle:SetChecked(getter()) end
    context.refreshers[#context.refreshers + 1] = Refresh
    Refresh()
end

local function HandleStylingChanged(enabled)
    if enabled then
        ns.DisableFriendlyClassColors()
        ns.ApplyOverheadNameReplacement()
        RefreshNameplates()
    else
        ns.RestoreOverheadNameSettings()
        ns.RestoreFriendlyClassColors()
        if ns.RestoreAll then ns.RestoreAll() end
    end
end

local CATEGORY_MODES = {
    { value = "active", label = "Active" },
    { value = "inactive", label = "Inactive" },
    { value = "hide", label = "Hide" },
}

local function CreateCategoryModeRow(context, rowData)
    local content, layout = context.content, context.layout
    local labelText, state, noteText = rowData[1], rowData[2], rowData[3]
    local row = CreateFrame("Frame", nil, content)
    row:SetPoint("RIGHT", content, "RIGHT", -24, 0)
    layout:Add(row, 24, 44, 2)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 4, -3)
    label:SetWidth(375)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)
    local dropdown = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", label, "RIGHT", -4, -9)
    UIDropDownMenu_SetWidth(dropdown, 82)
    local note = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    note:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    note:SetJustifyH("LEFT")
    note:SetText(noteText)

    local function Refresh()
        local mode = GetCategoryMode(state)
        UIDropDownMenu_SetSelectedValue(dropdown, mode)
        for _, option in ipairs(CATEGORY_MODES) do
            if option.value == mode then UIDropDownMenu_SetText(dropdown, option.label) end
        end
    end
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for _, option in ipairs(CATEGORY_MODES) do
            local value, optionLabel = option.value, option.label
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value = optionLabel, value
            info.checked = GetCategoryMode(state) == value
            info.func = function()
                SetCategoryMode(state, value)
                ns.DisableFriendlyClassColors()
                Refresh()
                RefreshNameplates()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    context.refreshers[#context.refreshers + 1] = Refresh
    Refresh()
end

local function AddBehaviorCategoryControls(context)
    AddSection(context.content, context.layout, "CATEGORY HANDLING")
    AddDescription(context.content, context.layout,
        "Active lets Simple Nameplates style the category. Inactive leaves Blizzard's display unchanged. Hide conceals it wherever Blizzard permits.")
    for _, rowData in ipairs(CATEGORY_ROWS) do CreateCategoryModeRow(context, rowData) end
end

local function AddBehaviorOverheadNameControls(context)
    context.layout:Space(6)
    AddSection(context.content, context.layout, "BLIZZARD OVERHEAD NAMES")
    CreateBehaviorToggle(context, "Replace Blizzard overhead names (experimental)",
        "Requests name-only player, minion, and NPC plates, then hides matching world names. A unit may have no visible name if Blizzard does not create a plate.",
        GetReplaceBlizzardOverheadNames, SetReplaceBlizzardOverheadNames, RefreshNameplates)
    CreateBehaviorToggle(context, "Hide Blizzard-controlled minion names",
        "Hides friendly and enemy pets, guardians, totems, and minions. Opposing-player names remain visible.",
        GetHideBlizzardMinionNames, SetHideBlizzardMinionNames)
    CreateBehaviorToggle(context, "Hide critter and companion names",
        "Hides Blizzard overhead names for noncombat critters and companions.",
        GetHideCritterCompanionNames, SetHideCritterCompanionNames)
end

local function CreateBehaviorPanel()
    local panel, content, layout = CreateScrollablePanel("Behavior")
    AddTitle(content, layout, "Simple Nameplates — Behavior")
    AddDescription(content, layout,
        "Global addon behavior and user preferences. These settings do not change with the appearance profile.")

    local context = { content = content, layout = layout, refreshers = {} }
    AddSection(content, layout, "ADDON")
    CreateBehaviorToggle(context, "Enable Simple Nameplates styling", nil,
        GetStylingEnabled, SetStylingEnabled, HandleStylingChanged)
    AddBehaviorCategoryControls(context)
    AddBehaviorOverheadNameControls(context)

    panel:SetScript("OnShow", function() RunRefreshers(context.refreshers) end)
    layout:Finish()
    return panel
end

local function RegisterAppearancePopups()
    StaticPopupDialogs["SNP_BLIZZARD_OVERHEAD_INFO"] = {
        text = "Blizzard draws non-attackable opposing-faction players and many player-controlled pets, guardians, totems, and minions as engine-level overhead names in periwinkle blue rather than as addon-accessible nameplate text.\n\nThe experimental replacement option on the Behavior page hides those world-name categories and requests ordinary nameplates instead. It can only work when Blizzard creates a nameplate for the unit.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_BLIZZARD_INTERACTIVE_INFO"] = {
        text = "Blizzard draws interactive NPCs, including city guards that offer directions, as engine-level yellow overhead names rather than as addon-accessible nameplate text. The experimental replacement option can restyle them only when Blizzard creates a friendly-NPC nameplate.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_BLIZZARD_VENDOR_INFO"] = {
        text = "Blizzard draws vendor NPCs as engine-level green overhead names rather than as addon-accessible nameplate text. The experimental replacement option can restyle them only when Blizzard creates a friendly-NPC nameplate.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
end

local function CreateColorRow(context, text, displayText, getColor, setColor, resetColor, getEnabled, setEnabled)
    local content, layout = context.content, context.layout
    local row = CreateFrame("Frame", nil, content)
    row:SetPoint("RIGHT", content, "RIGHT", -24, 0)
    layout:Add(row, 24, 40, 2)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 4, -3)
    label:SetWidth(getEnabled and 370 or 410)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    if getEnabled and setEnabled then
        local toggle = CreateSwitch(row, function(checked)
            setEnabled(checked)
            RefreshNameplates()
        end)
        toggle:SetPoint("LEFT", label, "RIGHT", 8, -9)
        local function RefreshToggle() toggle:SetChecked(getEnabled()) end
        context.toggleRefreshers[#context.toggleRefreshers + 1] = RefreshToggle
        RefreshToggle()
    end

    local display = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    display:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    display:SetWidth(380)
    display:SetJustifyH("LEFT")
    display:SetText(displayText)

    local swatch = CreateFrame("Button", nil, row, "BackdropTemplate")
    swatch:SetSize(26, 26)
    swatch:SetPoint("LEFT", 440, 0)
    swatch:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    swatch:SetBackdropColor(0.04, 0.04, 0.04, 1)
    swatch:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    local fill = swatch:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    local function UpdateSwatch() fill:SetColorTexture(getColor()) end
    context.swatchRefreshers[#context.swatchRefreshers + 1] = UpdateSwatch
    UpdateSwatch()

    swatch:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:AddLine("Click to choose a color.", 1, 1, 1)
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
        GameTooltip:Hide()
    end)
    swatch:SetScript("OnClick", function()
        local oldR, oldG, oldB = getColor()
        local function ApplyPickerColor()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            setColor(r, g, b)
            UpdateSwatch()
            RefreshNameplates()
        end
        ColorPickerFrame:SetupColorPickerAndShow({
            r = oldR, g = oldG, b = oldB, hasOpacity = false,
            swatchFunc = ApplyPickerColor,
            cancelFunc = function()
                setColor(oldR, oldG, oldB)
                UpdateSwatch()
                RefreshNameplates()
            end,
        })
    end)

    local resetOne = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    resetOne:SetSize(54, 22)
    resetOne:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
    resetOne:SetText("Reset")
    resetOne:SetScript("OnClick", function()
        resetColor()
        UpdateSwatch()
        RefreshNameplates()
    end)
end

local function CreatePriorityColorRow(context, text, state, displayText)
    CreateColorRow(context, text, displayText,
        function() return PriorityColorForState(state) end,
        function(r, g, b) SetPriorityColor(state, r, g, b) end,
        function() ResetPriorityColor(state) end)
end

local function CreateLockedColorRow(context, text, r, g, b, popupKey)
    local content, layout = context.content, context.layout
    local row = CreateFrame("Frame", nil, content)
    row:SetPoint("RIGHT", content, "RIGHT", -24, 0)
    layout:Add(row, 24, 40, 2)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 4, -3)
    label:SetWidth(410)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    local display = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    display:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    display:SetWidth(380)
    display:SetJustifyH("LEFT")
    display:SetText("Controlled by Blizzard; cannot be changed")
    local swatch = CreateFrame("Frame", nil, row, "BackdropTemplate")
    swatch:SetSize(26, 26)
    swatch:SetPoint("LEFT", 440, 0)
    swatch:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    swatch:SetBackdropColor(0.04, 0.04, 0.04, 1)
    swatch:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    local fill = swatch:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    fill:SetColorTexture(r, g, b, 1)
    AddInfoLink(row, swatch, popupKey)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:AddLine("This color is chosen by Blizzard and cannot be edited.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function AddPriorityColorControls(context)
    AddSectionResetButton(context.content, context.layout, "PRIORITY COLORS", "Reset Colors", function()
        ResetAllColors()
        RunRefreshers(context.swatchRefreshers)
        RefreshNameplates()
    end)

    CreatePriorityColorRow(context, "1. Attacking me", "attacking",
        "Health bar; includes attacks on pets, guardians, and minions; overrides 2–6")
    CreatePriorityColorRow(context, "2. Will attack me if it notices me", "hostile",
        "Health bar for aggressive units not currently attacking me")
    CreatePriorityColorRow(context, "3. Attackable by me, but not hostile", "unfriendlyNPC",
        "Health bar for units that will not initiate combat")
    CreatePriorityColorRow(context, "4. Opposite-faction PC", "unfriendlyPC",
        "Name when not attackable; attackable opponents use 1 or 2")
    CreatePriorityColorRow(context, "5. My-faction PC", "friendlyPC",
        "Name of same-faction player characters")
    CreatePriorityColorRow(context, "6. Anything else Simple Nameplates can color", "other",
        "Name of friendly NPCs and other unmatched colorable units")
end

local function AddLockedColorControls(context)
    context.layout:Space(6)
    AddSection(context.content, context.layout, "BLIZZARD-CONTROLLED OVERHEAD NAMES")
    CreateLockedColorRow(context, "Opposite-faction PCs and player-controlled minions",
        102 / 255, 102 / 255, 1, "SNP_BLIZZARD_OVERHEAD_INFO")
    CreateLockedColorRow(context, "Interactive NPCs",
        1, 1, 0, "SNP_BLIZZARD_INTERACTIVE_INFO")
    CreateLockedColorRow(context, "Vendor NPCs",
        0, 1, 0, "SNP_BLIZZARD_VENDOR_INFO")
end

local function AddCastBarControls(context)
    AddSection(context.content, context.layout, "CAST BARS")
    CreateColorRow(context, "Highlight interruptible casts and channels",
        "Changes the pulsing cast-bar border color",
        function() return EffectColor("interruptible") end,
        function(r, g, b) SetEffectColor("interruptible", r, g, b) end,
        function() ResetEffectColor("interruptible") end,
        GetInterruptibleHighlightEnabled, SetInterruptibleHighlightEnabled)
    local note = context.content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("RIGHT", context.content, "RIGHT", -20, 0)
    note:SetJustifyH("LEFT")
    note:SetText("Uses Blizzard's interruptibility result; the border pulses and has a dark outer edge.")
    context.layout:Add(note, 24, 28, 8)
end

local function RefreshAppearanceControls(context)
    RunRefreshers(context.swatchRefreshers)
    RunRefreshers(context.toggleRefreshers)
end

local function CreateAppearancePanel()
    local panel, content, layout = CreateScrollablePanel("Appearance")
    AddTitle(content, layout, "Simple Nameplates — Appearance")
    AddDescription(content, layout,
        "Profiles contain every look-and-feel setting. Profiles are shared account-wide; each character remembers its selection.")
    RegisterAppearancePopups()

    local context = {
        content = content,
        layout = layout,
        swatchRefreshers = {},
        toggleRefreshers = {},
    }
    AddProfileControls(content, layout, context.toggleRefreshers,
        function() RefreshAppearanceControls(context) end)
    layout:Space(8)
    AddTextAndLayoutControls(content, layout, context.toggleRefreshers)
    layout:Space(8)
    AddPriorityColorControls(context)
    AddLockedColorControls(context)
    AddCastBarControls(context)

    panel:SetScript("OnShow", function() RefreshAppearanceControls(context) end)
    RefreshAppearanceControls(context)
    layout:Finish()
    return panel
end

local function RegisterSettingsPanel()
    if settingsCategory or not Settings or not Settings.RegisterCanvasLayoutCategory
        or not Settings.RegisterCanvasLayoutSubcategory then return end
    local aboutPanel = CreateAboutPanel()
    settingsCategory = Settings.RegisterCanvasLayoutCategory(aboutPanel, "Simple Nameplates")
    Settings.RegisterAddOnCategory(settingsCategory)
    behaviorSettingsCategory = Settings.RegisterCanvasLayoutSubcategory(settingsCategory, CreateBehaviorPanel(), "Behavior")
    appearanceSettingsCategory = Settings.RegisterCanvasLayoutSubcategory(settingsCategory, CreateAppearancePanel(), "Appearance")
    trp3SettingsCategory = Settings.RegisterCanvasLayoutSubcategory(settingsCategory, CreateTRP3Panel(), "TRP3")

    SLASH_SNP1 = "/snp"
    SlashCmdList.SNP = function(message)
        local command = string.lower(strtrim(message or ""))
        if command == "debug" or command == "diagnose" then
            if ns.DebugUnit then ns.DebugUnit("target") end
            return
        end
        if InCombatLockdown and InCombatLockdown() then
            print("|cff0cd29fSimple Nameplates:|r Settings cannot be opened during combat.")
            return
        end
        if command == "about" then
            Settings.OpenToCategory(settingsCategory:GetID())
        elseif command == "text" or command == "font" or command == "fonts"
            or command == "appearance" then
            Settings.OpenToCategory(appearanceSettingsCategory:GetID())
        elseif command == "colors" or command == "color" then
            Settings.OpenToCategory(appearanceSettingsCategory:GetID())
        elseif command == "trp3" or command == "rp" then
            Settings.OpenToCategory(trp3SettingsCategory:GetID())
        elseif command == "" or command == "behavior" or command == "general" or command == "config"
            or command == "options" or command == "settings" then
            Settings.OpenToCategory(behaviorSettingsCategory:GetID())
        else
            print("|cff0cd29fSimple Nameplates:|r /snp, /snp behavior, /snp appearance, /snp colors, /snp trp3, /snp debug, /snp about")
        end
    end
end

ns.RegisterSettingsPanel = RegisterSettingsPanel
