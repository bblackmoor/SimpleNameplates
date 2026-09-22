-- Simple Nameplates: About and settings pages.

local _, ns = ...
if not ns.RelationshipColorForState or not ns.EffectColor then return end

local VERSION, SOURCE_URL = ns.VERSION, ns.SOURCE_URL
local RelationshipColorForState = ns.RelationshipColorForState
local SetRelationshipColor = ns.SetRelationshipColor
local ResetRelationshipColor = ns.ResetRelationshipColor
local EffectColor, SetEffectColor, ResetEffectColor = ns.EffectColor, ns.SetEffectColor, ns.ResetEffectColor
local ResetAllColors = ns.ResetAllColors
local ApplyColorPreset = ns.ApplyColorPreset
local GetAppearanceSetting, SetAppearanceSetting = ns.GetAppearanceSetting, ns.SetAppearanceSetting
local ResetAppearance = ns.ResetAppearance
local GetAttackingGlowEnabled, SetAttackingGlowEnabled = ns.GetAttackingGlowEnabled, ns.SetAttackingGlowEnabled
local GetInterruptibleHighlightEnabled = ns.GetInterruptibleHighlightEnabled
local SetInterruptibleHighlightEnabled = ns.SetInterruptibleHighlightEnabled
local GetStylingEnabled, SetStylingEnabled = ns.GetStylingEnabled, ns.SetStylingEnabled
local GetThreatEnabled, SetThreatEnabled = ns.GetThreatEnabled, ns.SetThreatEnabled
local GetHideBlizzardMinionNames = ns.GetHideBlizzardMinionNames
local SetHideBlizzardMinionNames = ns.SetHideBlizzardMinionNames
local GetHideCritterCompanionNames = ns.GetHideCritterCompanionNames
local SetHideCritterCompanionNames = ns.SetHideCritterCompanionNames

local settingsCategory, colorsSettingsCategory, textSettingsCategory, trp3SettingsCategory

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

local function AddDescription(content, layout, text)
    local description = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    description:SetJustifyH("LEFT")
    description:SetText(text)
    return layout:Add(description, 20, 32, 4)
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
        "Blizzard Midnight nameplates with customizable relationship colors and an optional " ..
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
        "    /snp - Open the color settings.\n" ..
        "    /snp colors - Open the color settings.\n" ..
        "    /snp text - Open the text settings.\n" ..
        "    /snp trp3 - Open the TRP3 settings.\n" ..
        "    /snp debug - Explain the current target and cast-highlight state.\n" ..
        "    /snp about - Open this About page.")
    layout:Add(information, 20, 145)
    layout:Finish()
    return panel
end

local function CreateTextPanel()
    local panel, content, layout = CreateScrollablePanel("Text")
    AddTitle(content, layout, "Simple Nameplates — Text")
    AddDescription(content, layout, "Choose the name size and fonts, and place names above or inside visible health bars.")
    local refreshers = {}

    local function OptionLabel(options, value)
        for _, option in ipairs(options) do
            if option.value == value then return option.label end
        end
        return ""
    end

    local function CreateDropdown(labelText, options, getter, setter)
        local block = CreateFrame("Frame", nil, content)
        block:SetPoint("RIGHT", content, "RIGHT", -20, 0)
        layout:Add(block, 20, 70, 8)
        local label = block:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", 4, 0)
        label:SetText(labelText)
        local dropdown = CreateFrame("Frame", nil, block, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", -12, -18)
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

    CreateDropdown("Name font", ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("nameFont") end,
        function(value) SetAppearanceSetting("nameFont", value) end)

    local sizeBlock = CreateFrame("Frame", nil, content)
    sizeBlock:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(sizeBlock, 20, 66, 8)
    local sizeLabel = sizeBlock:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", 4, 0)
    local sizeValue = sizeBlock:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sizeValue:SetPoint("TOPRIGHT", -4, 0)
    local sizeSlider = CreateFrame("Slider", "SimpleNameplatesNameSizeSlider", sizeBlock, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", 8, -28)
    sizeSlider:SetPoint("RIGHT", sizeBlock, "RIGHT", -8, 0)
    sizeSlider:SetHeight(18)
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

    CreateDropdown("Threat-percentage font", ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("threatFont") end,
        function(value) SetAppearanceSetting("threatFont", value) end)
    CreateDropdown("Health-bar name placement", {
        { value = "ABOVE", label = "Above bar" }, { value = "INSIDE", label = "Inside bar" },
    }, function() return GetAppearanceSetting("namePlacement") end,
        function(value) SetAppearanceSetting("namePlacement", value) end)

    local threat = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    threat:SetSize(26, 26)
    threat:SetHitRectInsets(0, -250, 0, 0)
    layout:Add(threat, 20, 30, 8)
    local threatLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    threatLabel:SetPoint("LEFT", threat, "RIGHT", 4, 0)
    threatLabel:SetText("Show threat percentage when available")
    local function RefreshThreat() threat:SetChecked(GetThreatEnabled()) end
    threat:SetScript("OnClick", function(self)
        SetThreatEnabled(self:GetChecked() == true)
        RefreshNameplates()
    end)

    local note = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    note:SetJustifyH("LEFT")
    note:SetText("Name size applies to addon-controlled floating names and names above health bars. Inside-bar names use 80% of that size, rounded to the nearest point; the bar expands to leave two UI units above and below. Blizzard-controlled overhead names have no nameplate frame to modify.")
    layout:Add(note, 24, 54, 12)
    local reset = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetText("Reset Text")
    layout:Add(reset, 24, 24)
    reset:SetScript("OnClick", function()
        ResetAppearance()
        SetThreatEnabled(true)
        for _, refresh in ipairs(refreshers) do refresh() end
        RefreshThreat()
        RefreshNameplates()
    end)
    panel:SetScript("OnShow", function()
        for _, refresh in ipairs(refreshers) do refresh() end
        RefreshThreat()
    end)
    RefreshThreat()
    layout:Finish()
    return panel
end

local function CreateTRP3Panel()
    local panel, content, layout = CreateScrollablePanel("TRP3")
    AddTitle(content, layout, "Simple Nameplates — TRP3")
    AddDescription(content, layout, "Optional Total RP 3 profile integration. Simple Nameplates continues to work normally when TRP3 is absent.")
    local enabled = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    enabled:SetSize(26, 26)
    enabled:SetHitRectInsets(0, -260, 0, 0)
    layout:Add(enabled, 20, 30, 8)
    local enabledLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    enabledLabel:SetPoint("LEFT", enabled, "RIGHT", 4, 0)
    enabledLabel:SetText("Display TRP3 profile information")

    local status = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    status:SetJustifyH("LEFT")
    layout:Add(status, 24, 38, 8)
    local section = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    section:SetText("DISPLAY OPTIONS")
    layout:Add(section, 24, 20, 2)

    local optionControls = {}
    local function CreateOption(labelText, setting)
        local option = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        option:SetSize(26, 26)
        option:SetHitRectInsets(0, -360, 0, 0)
        layout:Add(option, 20, 34, 2)
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", option, "RIGHT", 4, 0)
        label:SetText(labelText)
        option:SetScript("OnClick", function(self)
            ns.SetTRP3Setting(setting, self:GetChecked() == true)
            if ns.TRP3 then ns.TRP3.Refresh() end
        end)
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
    enabled:SetScript("OnClick", function(self)
        ns.SetTRP3Enabled(self:GetChecked() == true)
        if ns.TRP3 then ns.TRP3.Refresh() end
        Refresh()
    end)
    panel:SetScript("OnShow", Refresh)
    Refresh()
    layout:Finish()
    return panel
end

local function CreateColorsPanel()
    local panel, content, layout = CreateScrollablePanel("Colors")
    AddTitle(content, layout, "Simple Nameplates — Colors")
    AddDescription(content, layout, "Each row shows where its color is applied.")
    local enabled = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    enabled:SetSize(26, 26)
    enabled:SetHitRectInsets(0, -280, 0, 0)
    layout:Add(enabled, 20, 30, 8)
    local enabledLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    enabledLabel:SetPoint("LEFT", enabled, "RIGHT", 4, 0)
    enabledLabel:SetText("Enable Simple Nameplates styling")
    local function RefreshEnabled() enabled:SetChecked(GetStylingEnabled()) end
    enabled:SetScript("OnClick", function(self)
        local isEnabled = self:GetChecked() == true
        SetStylingEnabled(isEnabled)
        if isEnabled then
            ns.DisableFriendlyClassColors()
            RefreshNameplates()
        else
            ns.RestoreFriendlyClassColors()
            if ns.RestoreAll then ns.RestoreAll() end
        end
    end)

    local swatchRefreshers, toggleRefreshers = {}, {}
    StaticPopupDialogs["SNP_BLIZZARD_OVERHEAD_INFO"] = {
        text = "Blizzard draws non-attackable opposing-faction players and many player-controlled pets, guardians, totems, and minions as engine-level overhead names in periwinkle blue rather than as addon-accessible nameplate text.\n\nWithout a nameplate frame, addons cannot recolor the name, change its font, or draw replacement text at the same world position. Minion names can be hidden with the option below; opposing-player names cannot be changed independently beyond Blizzard's global name settings.\n\nI have spent months trying to change this one fucking text type. Apparently, it is simply impossible.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_BLIZZARD_INTERACTIVE_INFO"] = {
        text = "Blizzard draws interactive NPCs, including city guards that offer directions, as engine-level yellow overhead names rather than as addon-accessible nameplate text. Like the periwinkle overhead names, addons cannot recolor these names, change their font, or replace them at the same world position.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_HIGH_CONTRAST_PRESET_CONFIRM"] = {
        text = "Apply the High Contrast preset?\n\nThis replaces all six editable colors and enables the attacking glow. Blizzard's colorblind settings and filters will not be changed.",
        button1 = "Apply",
        button2 = CANCEL or "Cancel",
        OnAccept = function(_, applyPreset)
            if applyPreset then applyPreset() end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local function CreateSection(text)
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetText(text)
        layout:Add(label, 24, 20, 2)
    end

    local function CreateColorRow(text, displayText, getColor, setColor, resetColor, getEnabled, setEnabled)
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("RIGHT", content, "RIGHT", -24, 0)
        layout:Add(row, 24, 40, 2)
        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        if getEnabled and setEnabled then
            local toggle = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            toggle:SetSize(26, 26)
            toggle:SetPoint("LEFT", -4, 0)
            toggle:SetScript("OnClick", function(self)
                setEnabled(self:GetChecked() == true)
                RefreshNameplates()
            end)
            local function RefreshToggle() toggle:SetChecked(getEnabled()) end
            toggleRefreshers[#toggleRefreshers + 1] = RefreshToggle
            RefreshToggle()
            label:SetPoint("TOPLEFT", toggle, "TOPRIGHT", 0, -1)
        else
            label:SetPoint("TOPLEFT", 4, -3)
        end
        label:SetPoint("TOPRIGHT", row, "TOPRIGHT", -104, -3)
        label:SetJustifyH("LEFT")
        label:SetText(text)

        local display = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        display:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
        display:SetPoint("RIGHT", row, "RIGHT", -104, 0)
        display:SetJustifyH("LEFT")
        display:SetText(displayText)

        local swatch = CreateFrame("Button", nil, row, "BackdropTemplate")
        swatch:SetSize(26, 26)
        swatch:SetPoint("RIGHT", -4, 0)
        swatch:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        swatch:SetBackdropColor(0.04, 0.04, 0.04, 1)
        swatch:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
        local fill = swatch:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 3, -3)
        fill:SetPoint("BOTTOMRIGHT", -3, 3)
        local function UpdateSwatch() fill:SetColorTexture(getColor()) end
        swatchRefreshers[#swatchRefreshers + 1] = UpdateSwatch
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
        resetOne:SetPoint("RIGHT", swatch, "LEFT", -8, 0)
        resetOne:SetText("Reset")
        resetOne:SetScript("OnClick", function()
            resetColor()
            UpdateSwatch()
            RefreshNameplates()
        end)
    end

    local function CreateRelationshipRow(text, state, displayText)
        CreateColorRow(text, displayText,
            function() return RelationshipColorForState(state) end,
            function(r, g, b) SetRelationshipColor(state, r, g, b) end,
            function() ResetRelationshipColor(state) end)
    end

    local function CreateLockedColorRow(text, r, g, b, popupKey)
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("RIGHT", content, "RIGHT", -24, 0)
        layout:Add(row, 24, 40, 2)
        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("TOPLEFT", 4, -3)
        label:SetPoint("TOPRIGHT", row, "TOPRIGHT", -104, -3)
        label:SetJustifyH("LEFT")
        label:SetText(text)
        local display = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        display:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
        display:SetPoint("RIGHT", row, "RIGHT", -104, 0)
        display:SetJustifyH("LEFT")
        display:SetText("Controlled by Blizzard; cannot be changed")
        local swatch = CreateFrame("Frame", nil, row, "BackdropTemplate")
        swatch:SetSize(26, 26)
        swatch:SetPoint("RIGHT", -4, 0)
        swatch:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        swatch:SetBackdropColor(0.04, 0.04, 0.04, 1)
        swatch:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
        local fill = swatch:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 3, -3)
        fill:SetPoint("BOTTOMRIGHT", -3, 3)
        fill:SetColorTexture(r, g, b, 1)
        local info = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        info:SetSize(24, 22)
        info:SetPoint("RIGHT", swatch, "LEFT", -8, 0)
        info:SetText("?")
        info:SetScript("OnClick", function() StaticPopup_Show(popupKey) end)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text)
            GameTooltip:AddLine("This color is chosen by Blizzard and cannot be edited.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    CreateSection("FRIENDLY")
    CreateRelationshipRow("Friendly NPC", "friendlyNPC", "Changes the name color")
    CreateRelationshipRow("Friendly same-faction PC", "friendlyPC", "Changes the name color")
    layout:Space(6)
    CreateSection("UNFRIENDLY")
    CreateRelationshipRow("Attackable but non-aggressive NPC", "unfriendlyNPC", "Changes the health-bar color")
    CreateRelationshipRow("Aggressive NPC or PvP-enabled opposing PC", "hostile", "Changes the health-bar color")
    CreateLockedColorRow("Blizzard overhead names (periwinkle)",
        102 / 255, 102 / 255, 1, "SNP_BLIZZARD_OVERHEAD_INFO")
    CreateLockedColorRow("Interactive NPC overhead names",
        1, 1, 0, "SNP_BLIZZARD_INTERACTIVE_INFO")
    local hideMinionNames = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    hideMinionNames:SetSize(26, 26)
    hideMinionNames:SetHitRectInsets(0, -340, 0, 0)
    layout:Add(hideMinionNames, 20, 30, 0)
    local hideMinionNamesLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hideMinionNamesLabel:SetPoint("LEFT", hideMinionNames, "RIGHT", 4, 0)
    hideMinionNamesLabel:SetText("Hide Blizzard-controlled minion names")
    local hideMinionNamesNote = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hideMinionNamesNote:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    hideMinionNamesNote:SetJustifyH("LEFT")
    hideMinionNamesNote:SetText("Hides friendly and enemy pets, guardians, totems, and minions. Opposing-player names remain visible.")
    layout:Add(hideMinionNamesNote, 24, 28, 8)
    local function RefreshHideMinionNames()
        hideMinionNames:SetChecked(GetHideBlizzardMinionNames())
    end
    hideMinionNames:SetScript("OnClick", function(self)
        SetHideBlizzardMinionNames(self:GetChecked() == true)
        RefreshHideMinionNames()
    end)
    local hideCritterCompanionNames = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    hideCritterCompanionNames:SetSize(26, 26)
    hideCritterCompanionNames:SetHitRectInsets(0, -340, 0, 0)
    layout:Add(hideCritterCompanionNames, 20, 30, 0)
    local hideCritterCompanionNamesLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hideCritterCompanionNamesLabel:SetPoint("LEFT", hideCritterCompanionNames, "RIGHT", 4, 0)
    hideCritterCompanionNamesLabel:SetText("Hide critter and companion names")
    local hideCritterCompanionNamesNote = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hideCritterCompanionNamesNote:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    hideCritterCompanionNamesNote:SetJustifyH("LEFT")
    hideCritterCompanionNamesNote:SetText("Hides Blizzard overhead names for noncombat critters and companions.")
    layout:Add(hideCritterCompanionNamesNote, 24, 28, 8)
    local function RefreshHideCritterCompanionNames()
        hideCritterCompanionNames:SetChecked(GetHideCritterCompanionNames())
    end
    hideCritterCompanionNames:SetScript("OnClick", function(self)
        SetHideCritterCompanionNames(self:GetChecked() == true)
        RefreshHideCritterCompanionNames()
    end)
    layout:Space(6)
    CreateSection("COMBAT OVERRIDE")
    CreateRelationshipRow("Attacking me or one of my controlled units", "attacking", "Changes the health-bar color")

    local attackingGlow = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    attackingGlow:SetSize(26, 26)
    attackingGlow:SetHitRectInsets(0, -320, 0, 0)
    layout:Add(attackingGlow, 20, 30, 2)
    local attackingGlowLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    attackingGlowLabel:SetPoint("LEFT", attackingGlow, "RIGHT", 4, 0)
    attackingGlowLabel:SetText("Glow attacking units")
    local attackingGlowNote = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    attackingGlowNote:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    attackingGlowNote:SetJustifyH("LEFT")
    attackingGlowNote:SetText("Uses the configured Attacking color and applies to both PCs and NPCs.")
    layout:Add(attackingGlowNote, 24, 28, 8)
    local function RefreshAttackingGlow() attackingGlow:SetChecked(GetAttackingGlowEnabled()) end
    attackingGlow:SetScript("OnClick", function(self)
        SetAttackingGlowEnabled(self:GetChecked() == true)
        RefreshNameplates()
    end)

    CreateSection("CAST BARS")
    CreateColorRow("Highlight interruptible casts and channels", "Changes the cast-bar outline color",
        function() return EffectColor("interruptible") end,
        function(r, g, b) SetEffectColor("interruptible", r, g, b) end,
        function() ResetEffectColor("interruptible") end,
        GetInterruptibleHighlightEnabled, SetInterruptibleHighlightEnabled)
    local interruptibleNote = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    interruptibleNote:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    interruptibleNote:SetJustifyH("LEFT")
    interruptibleNote:SetText("Uses Blizzard's interruptibility result and is drawn above the attacking glow.")
    layout:Add(interruptibleNote, 24, 28, 8)

    local buttonRow = CreateFrame("Frame", nil, content)
    buttonRow:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(buttonRow, 24, 24)

    local preset = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    preset:SetSize(150, 24)
    preset:SetPoint("LEFT")
    preset:SetText("High Contrast")

    local reset = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetPoint("LEFT", preset, "RIGHT", 12, 0)
    reset:SetText("Reset Colors")
    reset:SetScript("OnClick", function()
        ResetAllColors()
        for _, refresh in ipairs(swatchRefreshers) do refresh() end
        RefreshNameplates()
    end)
    preset:SetScript("OnClick", function()
        StaticPopup_Show("SNP_HIGH_CONTRAST_PRESET_CONFIRM", nil, nil, function()
            if ApplyColorPreset("highContrast") then
                SetAttackingGlowEnabled(true)
                RefreshAttackingGlow()
                for _, refresh in ipairs(swatchRefreshers) do refresh() end
                RefreshNameplates()
            end
        end)
    end)
    panel:SetScript("OnShow", function()
        RefreshEnabled()
        RefreshAttackingGlow()
        RefreshHideMinionNames()
        RefreshHideCritterCompanionNames()
        for _, refresh in ipairs(toggleRefreshers) do refresh() end
    end)
    RefreshEnabled()
    RefreshAttackingGlow()
    RefreshHideMinionNames()
    RefreshHideCritterCompanionNames()
    layout:Finish()
    return panel
end

local function RegisterSettingsPanel()
    if settingsCategory or not Settings or not Settings.RegisterCanvasLayoutCategory
        or not Settings.RegisterCanvasLayoutSubcategory then return end
    local aboutPanel = CreateAboutPanel()
    settingsCategory = Settings.RegisterCanvasLayoutCategory(aboutPanel, "Simple Nameplates")
    Settings.RegisterAddOnCategory(settingsCategory)
    colorsSettingsCategory = Settings.RegisterCanvasLayoutSubcategory(settingsCategory, CreateColorsPanel(), "Colors")
    textSettingsCategory = Settings.RegisterCanvasLayoutSubcategory(settingsCategory, CreateTextPanel(), "Text")
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
        elseif command == "text" or command == "font" or command == "fonts" then
            Settings.OpenToCategory(textSettingsCategory:GetID())
        elseif command == "trp3" or command == "rp" then
            Settings.OpenToCategory(trp3SettingsCategory:GetID())
        elseif command == "" or command == "colors" or command == "config"
            or command == "options" or command == "settings" then
            Settings.OpenToCategory(colorsSettingsCategory:GetID())
        else
            print("|cff0cd29fSimple Nameplates:|r /snp, /snp colors, /snp text, /snp trp3, /snp debug, /snp about")
        end
    end
end

ns.RegisterSettingsPanel = RegisterSettingsPanel
