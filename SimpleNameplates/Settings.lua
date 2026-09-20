-- Simple Nameplates: About and color settings pages.

local _, ns = ...
if not ns.ColorForState then return end

local VERSION = ns.VERSION
local SOURCE_URL = ns.SOURCE_URL
local ColorForState = ns.ColorForState
local SetStateColor = ns.SetStateColor
local ResetStateColor = ns.ResetStateColor
local ResetStateColors = ns.ResetStateColors
local GetAppearanceSetting = ns.GetAppearanceSetting
local SetAppearanceSetting = ns.SetAppearanceSetting
local ResetAppearance = ns.ResetAppearance
local GetAttackingGlowEnabled = ns.GetAttackingGlowEnabled
local SetAttackingGlowEnabled = ns.SetAttackingGlowEnabled
local GetInterruptibleHighlightEnabled = ns.GetInterruptibleHighlightEnabled
local SetInterruptibleHighlightEnabled = ns.SetInterruptibleHighlightEnabled
local GetStylingEnabled = ns.GetStylingEnabled
local SetStylingEnabled = ns.SetStylingEnabled
local GetThreatEnabled = ns.GetThreatEnabled
local SetThreatEnabled = ns.SetThreatEnabled

local settingsCategory
local colorsSettingsCategory
local textSettingsCategory
local trp3SettingsCategory

local function RefreshNameplates()
    if ns.RefreshAll then ns.RefreshAll() end
end

local function CreateAboutPanel()
    local panel = CreateFrame("Frame")

    StaticPopupDialogs["SNP_COPY_SOURCE"] = {
        text = "Press Ctrl+C to copy the source URL.",
        button1 = CLOSE or "Close",
        hasEditBox = true,
        maxLetters = 255,
        editBoxWidth = 340,
        OnShow = function(self, url)
            local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
            editBox:SetText(url or self.data or SOURCE_URL)
            editBox:SetFocus()
            editBox:HighlightText()
        end,
        EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    heading:SetText("Simple Nameplates — About")

    local description = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -12)
    description:SetWidth(620)
    description:SetJustifyH("LEFT")
    description:SetText(
        "A deliberately simple standalone nameplate-color addon. " ..
        "It recolors addon-accessible Blizzard Midnight nameplates with " ..
        "customizable relationship colors and an optional interruptible cast highlight."
    )

    local details = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    details:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -24)
    details:SetWidth(620)
    details:SetJustifyH("LEFT")
    details:SetText(
        "Version " .. VERSION .. "\n" ..
        "Author    Brandon Blackmoor\n" ..
        "Category  Unit Frames"
    )

    local sourceLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceLabel:SetPoint("TOPLEFT", details, "BOTTOMLEFT", 0, -2)
    sourceLabel:SetText("Source    ")

    local sourceLink = CreateFrame("Button", nil, panel)
    sourceLink:SetPoint("LEFT", sourceLabel, "RIGHT", 0, 0)

    local sourceText = sourceLink:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceText:SetPoint("LEFT", sourceLink, "LEFT")
    sourceText:SetText(SOURCE_URL)
    sourceText:SetTextColor(0.35, 0.7, 1, 1)

    sourceLink:SetSize(sourceText:GetStringWidth(), 16)
    sourceLink:SetScript("OnEnter", function() sourceText:SetTextColor(0.65, 0.85, 1, 1) end)
    sourceLink:SetScript("OnLeave", function() sourceText:SetTextColor(0.35, 0.7, 1, 1) end)
    sourceLink:SetScript("OnClick", function()
        StaticPopup_Show("SNP_COPY_SOURCE", nil, nil, SOURCE_URL)
    end)

    local information = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    information:SetPoint("TOPLEFT", sourceLabel, "BOTTOMLEFT", 0, -2)
    information:SetWidth(620)
    information:SetJustifyH("LEFT")
    information:SetText(
        "License   GPL-3.0\n\n" ..
        "Slash commands\n" ..
        "    /snp - Open the color settings.\n" ..
        "    /snp colors - Open the color settings.\n" ..
        "    /snp text - Open the text settings.\n" ..
        "    /snp trp3 - Open the TRP3 settings.\n" ..
        "    /snp debug - Explain the current target's detected state.\n" ..
        "    /snp about - Open this About page."
    )

    return panel
end

local function CreateTextPanel()
    local panel = CreateFrame("Frame")
    panel.name = "Text"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText("Simple Nameplates — Text")

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetPoint("RIGHT", panel, "RIGHT", -20, 0)
    description:SetJustifyH("LEFT")
    description:SetText("Choose the name and threat fonts and place names above or inside visible health bars.")

    local refreshers = {}

    local function OptionLabel(options, value)
        for _, option in ipairs(options) do
            if option.value == value then return option.label end
        end
        return ""
    end

    local function CreateDropdown(labelText, y, options, getter, setter)
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", 24, y)
        label:SetText(labelText)

        local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", 8, y - 18)
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
                info.text = optionLabel
                info.value = value
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

    CreateDropdown(
        "Name font",
        -88,
        ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("nameFont") end,
        function(value) SetAppearanceSetting("nameFont", value) end
    )
    CreateDropdown(
        "Threat-percentage font",
        -170,
        ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("threatFont") end,
        function(value) SetAppearanceSetting("threatFont", value) end
    )
    CreateDropdown(
        "Health-bar name placement",
        -252,
        {
            { value = "ABOVE", label = "Above bar" },
            { value = "INSIDE", label = "Inside bar" },
        },
        function() return GetAppearanceSetting("namePlacement") end,
        function(value) SetAppearanceSetting("namePlacement", value) end
    )

    local threat = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    threat:SetSize(26, 26)
    threat:SetPoint("TOPLEFT", 20, -326)
    threat:SetHitRectInsets(0, -250, 0, 0)

    local threatLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    threatLabel:SetPoint("LEFT", threat, "RIGHT", 4, 0)
    threatLabel:SetText("Show threat percentage when available")

    local function RefreshThreat()
        threat:SetChecked(GetThreatEnabled())
    end
    threat:SetScript("OnClick", function(self)
        SetThreatEnabled(self:GetChecked() == true)
        RefreshNameplates()
    end)

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 24, -370)
    note:SetWidth(600)
    note:SetJustifyH("LEFT")
    note:SetText("Inside-bar names shrink to fit the existing Blizzard bar. Friendly name-only plates are unaffected; Blizzard overhead names have no nameplate frame to modify.")

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetPoint("TOPLEFT", 24, -422)
    reset:SetText("Reset Text")
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
    return panel
end

local function CreateTRP3Panel()
    local panel = CreateFrame("Frame")
    panel.name = "TRP3"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText("Simple Nameplates — TRP3")

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetPoint("RIGHT", panel, "RIGHT", -20, 0)
    description:SetJustifyH("LEFT")
    description:SetText("Optional Total RP 3 profile integration. Simple Nameplates continues to work normally when TRP3 is absent.")

    local enabled = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enabled:SetSize(26, 26)
    enabled:SetPoint("TOPLEFT", 20, -78)
    enabled:SetHitRectInsets(0, -260, 0, 0)

    local enabledLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    enabledLabel:SetPoint("LEFT", enabled, "RIGHT", 4, 0)
    enabledLabel:SetText("Display TRP3 profile information")

    local status = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", 24, -116)
    status:SetWidth(600)
    status:SetJustifyH("LEFT")

    local section = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    section:SetPoint("TOPLEFT", 24, -158)
    section:SetText("DISPLAY OPTIONS")

    local optionControls = {}

    local function CreateOption(labelText, setting, y)
        local option = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        option:SetSize(26, 26)
        option:SetPoint("TOPLEFT", 20, y)
        option:SetHitRectInsets(0, -360, 0, 0)

        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", option, "RIGHT", 4, 0)
        label:SetText(labelText)

        option:SetScript("OnClick", function(self)
            ns.SetTRP3Setting(setting, self:GetChecked() == true)
            if ns.TRP3 then ns.TRP3.Refresh() end
        end)
        optionControls[#optionControls + 1] = { button = option, label = label, setting = setting }
    end

    CreateOption("Use TRP3 roleplaying full name", "useRoleplayingName", -180)
    CreateOption("Show short title before the name", "showShortTitle", -216)
    CreateOption("Show [OOC] instead of the short title", "showOOC", -252)
    CreateOption("Show full title above the name", "showFullTitle", -288)

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 24, -334)
    note:SetWidth(600)
    note:SetJustifyH("LEFT")
    note:SetText("Full titles always appear outside the health bar. If no cached TRP3 profile or selected field is available, the normal WoW name is used.")

    local function Refresh()
        enabled:SetChecked(ns.GetTRP3Enabled())
        local isEnabled = ns.GetTRP3Enabled()
        for _, control in ipairs(optionControls) do
            control.button:SetChecked(ns.GetTRP3Setting(control.setting))
            control.button:SetEnabled(isEnabled)
            if isEnabled then
                control.label:SetTextColor(1, 1, 1, 1)
            else
                control.label:SetTextColor(0.5, 0.5, 0.5, 1)
            end
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
    return panel
end

local function RegisterSettingsPanel()
    if settingsCategory or not Settings or not Settings.RegisterCanvasLayoutCategory
        or not Settings.RegisterCanvasLayoutSubcategory then return end

    local panel = CreateFrame("Frame")
    panel.name = "Colors"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText("Simple Nameplates — Colors")

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetPoint("RIGHT", panel, "RIGHT", -20, 0)
    description:SetJustifyH("LEFT")
    description:SetText("Each row shows where its color is applied.")

    local enabled = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enabled:SetSize(26, 26)
    enabled:SetPoint("TOPLEFT", 20, -66)
    enabled:SetHitRectInsets(0, -280, 0, 0)

    local enabledLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    enabledLabel:SetPoint("LEFT", enabled, "RIGHT", 4, 0)
    enabledLabel:SetText("Enable Simple Nameplates styling")

    local function RefreshEnabled()
        enabled:SetChecked(GetStylingEnabled())
    end
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

    local swatchRefreshers = {}
    local toggleRefreshers = {}

    StaticPopupDialogs["SNP_BLIZZARD_OVERHEAD_INFO"] = {
        text = "Blizzard draws non-attackable opposing-faction players and all player-controlled pets, guardians, totems, and minions as engine-level overhead names in periwinkle blue rather than as addon-accessible nameplate text.\n\nWoW's settings and addons can request friendly, enemy, and always-visible nameplates, but they cannot force the game to create a nameplate frame for these units. Without that frame, addons cannot recolor the name, change its font, or draw replacement text at the same world position.\n\nI have spent months trying to change this one fucking text type. Apparently, it is simply impossible.",
        button1 = OKAY or "Okay",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local function CreateSection(text, y)
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", 24, y)
        label:SetText(text)
    end

    local function CreateColorRow(text, state, displayText, y, getEnabled, setEnabled)
        local row = CreateFrame("Frame", nil, panel)
        row:SetPoint("TOPLEFT", 24, y)
        row:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
        row:SetHeight(34)

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
            label:SetPoint("LEFT", toggle, "RIGHT", 0, 0)
        else
            label:SetPoint("LEFT", 4, 0)
        end
        label:SetPoint("RIGHT", row, "RIGHT", -250, 0)
        label:SetJustifyH("LEFT")
        label:SetText(text)

        local swatch = CreateFrame("Button", nil, row, "BackdropTemplate")
        swatch:SetSize(26, 26)
        swatch:SetPoint("RIGHT", -4, 0)
        swatch:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        swatch:SetBackdropColor(0.04, 0.04, 0.04, 1)
        swatch:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)

        local fill = swatch:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 3, -3)
        fill:SetPoint("BOTTOMRIGHT", -3, 3)

        local function UpdateSwatch()
            fill:SetColorTexture(ColorForState(state))
        end
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
            local oldR, oldG, oldB = ColorForState(state)
            local function ApplyPickerColor()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                SetStateColor(state, r, g, b)
                UpdateSwatch()
                RefreshNameplates()
            end
            local info = {
                r = oldR, g = oldG, b = oldB,
                hasOpacity = false,
                swatchFunc = ApplyPickerColor,
                cancelFunc = function()
                    SetStateColor(state, oldR, oldG, oldB)
                    UpdateSwatch()
                    RefreshNameplates()
                end,
            }
            ColorPickerFrame:SetupColorPickerAndShow(info)
        end)

        local resetOne = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        resetOne:SetSize(54, 22)
        resetOne:SetPoint("RIGHT", swatch, "LEFT", -8, 0)
        resetOne:SetText("Reset")
        resetOne:SetScript("OnClick", function()
            ResetStateColor(state)
            UpdateSwatch()
            RefreshNameplates()
        end)

        local display = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        display:SetPoint("RIGHT", resetOne, "LEFT", -12, 0)
        display:SetWidth(125)
        display:SetJustifyH("RIGHT")
        display:SetText(displayText)
    end

    local function CreateLockedColorRow(text, y)
        local row = CreateFrame("Frame", nil, panel)
        row:SetPoint("TOPLEFT", 24, y)
        row:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
        row:SetHeight(34)

        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", 4, 0)
        label:SetPoint("RIGHT", row, "RIGHT", -250, 0)
        label:SetJustifyH("LEFT")
        label:SetText(text)

        local swatch = CreateFrame("Frame", nil, row, "BackdropTemplate")
        swatch:SetSize(26, 26)
        swatch:SetPoint("RIGHT", -4, 0)
        swatch:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        swatch:SetBackdropColor(0.04, 0.04, 0.04, 1)
        swatch:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)

        local fill = swatch:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 3, -3)
        fill:SetPoint("BOTTOMRIGHT", -3, 3)
        fill:SetColorTexture(102 / 255, 102 / 255, 1, 1)

        local info = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        info:SetSize(24, 22)
        info:SetPoint("RIGHT", swatch, "LEFT", -8, 0)
        info:SetText("?")
        info:SetScript("OnClick", function()
            StaticPopup_Show("SNP_BLIZZARD_OVERHEAD_INFO")
        end)

        local display = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        display:SetPoint("RIGHT", info, "LEFT", -12, 0)
        display:SetWidth(125)
        display:SetJustifyH("RIGHT")
        display:SetText("Engine-controlled")

        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text)
            GameTooltip:AddLine("This color is chosen by Blizzard and cannot be edited.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    CreateSection("FRIENDLY", -106)
    CreateColorRow("Friendly NPC", "friendlyNPC", "Colored name", -132)
    CreateColorRow("Friendly same-faction PC", "friendlyPC", "Colored name", -168)

    CreateSection("UNFRIENDLY", -210)
    CreateColorRow("Attackable but non-aggressive NPC", "unfriendlyNPC", "Health bar", -236)
    CreateColorRow("Aggressive NPC or PvP-enabled opposing PC", "hostile", "Health bar", -272)
    CreateLockedColorRow("Blizzard-controlled overhead names", -308)

    CreateSection("COMBAT OVERRIDE", -350)
    CreateColorRow("Attacking me or one of my controlled units", "attacking", "Health bar", -376)

    local attackingGlow = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    attackingGlow:SetSize(26, 26)
    attackingGlow:SetPoint("TOPLEFT", 20, -418)
    attackingGlow:SetHitRectInsets(0, -320, 0, 0)

    local attackingGlowLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    attackingGlowLabel:SetPoint("LEFT", attackingGlow, "RIGHT", 4, 0)
    attackingGlowLabel:SetText("Glow attacking units")

    local attackingGlowNote = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    attackingGlowNote:SetPoint("TOPLEFT", 24, -450)
    attackingGlowNote:SetWidth(600)
    attackingGlowNote:SetJustifyH("LEFT")
    attackingGlowNote:SetText("Uses the configured Attacking color and applies to both PCs and NPCs.")

    local function RefreshAttackingGlow()
        attackingGlow:SetChecked(GetAttackingGlowEnabled())
    end
    attackingGlow:SetScript("OnClick", function(self)
        SetAttackingGlowEnabled(self:GetChecked() == true)
        RefreshNameplates()
    end)

    CreateSection("CAST BARS", -486)
    CreateColorRow(
        "Highlight interruptible casts and channels",
        "interruptible",
        "Cast-bar outline",
        -512,
        GetInterruptibleHighlightEnabled,
        SetInterruptibleHighlightEnabled
    )

    local interruptibleNote = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    interruptibleNote:SetPoint("TOPLEFT", 24, -544)
    interruptibleNote:SetWidth(600)
    interruptibleNote:SetJustifyH("LEFT")
    interruptibleNote:SetText("Uses Blizzard's interruptibility result and is drawn above the attacking glow.")

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetPoint("TOPLEFT", 24, -576)
    reset:SetText("Reset Colors")
    reset:SetScript("OnClick", function()
        ResetStateColors()
        for _, refresh in ipairs(swatchRefreshers) do refresh() end
        RefreshNameplates()
    end)

    panel:SetScript("OnShow", function()
        RefreshEnabled()
        RefreshAttackingGlow()
        for _, refresh in ipairs(toggleRefreshers) do refresh() end
    end)
    RefreshEnabled()
    RefreshAttackingGlow()

    local aboutPanel = CreateAboutPanel()
    settingsCategory = Settings.RegisterCanvasLayoutCategory(aboutPanel, "Simple Nameplates")
    Settings.RegisterAddOnCategory(settingsCategory)
    colorsSettingsCategory = Settings.RegisterCanvasLayoutSubcategory(
        settingsCategory,
        panel,
        "Colors"
    )
    textSettingsCategory = Settings.RegisterCanvasLayoutSubcategory(
        settingsCategory,
        CreateTextPanel(),
        "Text"
    )
    trp3SettingsCategory = Settings.RegisterCanvasLayoutSubcategory(
        settingsCategory,
        CreateTRP3Panel(),
        "TRP3"
    )

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
