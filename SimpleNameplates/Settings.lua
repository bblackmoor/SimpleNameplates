-- Simple Nameplates: About and color settings pages.

local _, ns = ...
if not ns.ColorForState then return end

local VERSION = ns.VERSION
local SOURCE_URL = ns.SOURCE_URL
local ColorForState = ns.ColorForState
local SetStateColor = ns.SetStateColor
local ResetStateColors = ns.ResetStateColors
local GetAppearanceSetting = ns.GetAppearanceSetting
local SetAppearanceSetting = ns.SetAppearanceSetting
local ResetAppearance = ns.ResetAppearance

local settingsCategory
local colorsSettingsCategory
local textSettingsCategory

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
        "It keeps Blizzard's Midnight nameplates while providing separate, " ..
        "customizable colors for NPC and player-character relationships."
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
    description:SetText("Choose the name and threat fonts and place hostile-unit names above or inside their health bars.")

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
        "Hostile-unit name placement",
        -252,
        {
            { value = "ABOVE", label = "Above bar" },
            { value = "INSIDE", label = "Inside bar" },
        },
        function() return GetAppearanceSetting("namePlacement") end,
        function(value) SetAppearanceSetting("namePlacement", value) end
    )

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 24, -334)
    note:SetWidth(600)
    note:SetJustifyH("LEFT")
    note:SetText("Inside-bar names automatically shrink to fit the existing Blizzard bar. Name-only friendly and non-PvP players are unaffected.")

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetPoint("TOPLEFT", 24, -386)
    reset:SetText("Reset Text")
    reset:SetScript("OnClick", function()
        ResetAppearance()
        for _, refresh in ipairs(refreshers) do refresh() end
        RefreshNameplates()
    end)

    panel:SetScript("OnShow", function()
        for _, refresh in ipairs(refreshers) do refresh() end
    end)
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
    description:SetText("Choose name colors for nonattackable units and health-bar colors for hostile units.")

    local swatchRefreshers = {}

    local function CreateSection(text, y)
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", 24, y)
        label:SetText(text)
    end

    local function CreateColorRow(text, state, y)
        local row = CreateFrame("Frame", nil, panel)
        row:SetPoint("TOPLEFT", 24, y)
        row:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
        row:SetHeight(34)

        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", 4, 0)
        label:SetPoint("RIGHT", row, "RIGHT", -44, 0)
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
    end

    CreateSection("NON-PLAYER CHARACTERS", -82)
    CreateColorRow("Friendly NPC", "friendlyNPC", -108)
    CreateColorRow("Unfriendly (attackable) NPC", "unfriendlyNPC", -144)
    CreateColorRow("Hostile (will attack me) NPC", "hostileNPC", -180)
    CreateColorRow("Attacking (me, a pet, or an ally) NPC", "attackingNPC", -216)

    CreateSection("PLAYER CHARACTERS", -266)
    CreateColorRow("Friendly (same faction) PC", "friendlyPC", -292)
    CreateColorRow("Unfriendly (opposite faction) PC", "unfriendlyPC", -328)
    CreateColorRow("Hostile (PvP-enabled opposite faction) PC", "hostilePC", -364)
    CreateColorRow("Attacking (PvP-enabled opposite faction) PC", "attackingPC", -400)

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetPoint("TOPLEFT", 24, -454)
    reset:SetText("Reset Colors")
    reset:SetScript("OnClick", function()
        ResetStateColors()
        for _, refresh in ipairs(swatchRefreshers) do refresh() end
        RefreshNameplates()
    end)

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

    SLASH_SNP1 = "/snp"
    SlashCmdList.SNP = function(message)
        if InCombatLockdown and InCombatLockdown() then
            print("|cff0cd29fSimple Nameplates:|r Settings cannot be opened during combat.")
            return
        end

        local command = string.lower(strtrim(message or ""))
        if command == "about" then
            Settings.OpenToCategory(settingsCategory:GetID())
        elseif command == "text" or command == "font" or command == "fonts" then
            Settings.OpenToCategory(textSettingsCategory:GetID())
        elseif command == "" or command == "colors" or command == "config"
            or command == "options" or command == "settings" then
            Settings.OpenToCategory(colorsSettingsCategory:GetID())
        else
            print("|cff0cd29fSimple Nameplates:|r /snp, /snp colors, /snp text, /snp about")
        end
    end
end

ns.RegisterSettingsPanel = RegisterSettingsPanel
