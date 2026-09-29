-- Simple Nameplates: Appearance settings page.
local _, ns = ...
local U = ns.SettingsUI
local CreateScrollablePanel, AddTitle, AddDescription, CreateSwitch =
    U.CreateScrollablePanel, U.AddTitle, U.AddDescription, U.CreateSwitch
local AddInfoLink, AddSectionResetButton, AddSection, RunRefreshers, RefreshNameplates =
    U.AddInfoLink, U.AddSectionResetButton, U.AddSection, U.RunRefreshers, U.RefreshNameplates
local AddProfileControls = ns.AddProfileControls
local PriorityColorForState, SetPriorityColor, ResetPriorityColor =
    ns.PriorityColorForState, ns.SetPriorityColor, ns.ResetPriorityColor
local EffectColor, SetEffectColor, ResetEffectColor =
    ns.EffectColor, ns.SetEffectColor, ns.ResetEffectColor
local ResetAllColors = ns.ResetAllColors
local GetAppearanceSetting, SetAppearanceSetting, ResetAppearance =
    ns.GetAppearanceSetting, ns.SetAppearanceSetting, ns.ResetAppearance
local GetThreatEnabled, SetThreatEnabled = ns.GetThreatEnabled, ns.SetThreatEnabled
local GetInterruptibleHighlightEnabled, SetInterruptibleHighlightEnabled =
    ns.GetInterruptibleHighlightEnabled, ns.SetInterruptibleHighlightEnabled

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

local function OpenColorPicker(getColor, setColor, updateSwatch)
    local oldR, oldG, oldB = getColor()
    local function ApplyPickerColor()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        setColor(r, g, b)
        updateSwatch()
        RefreshNameplates()
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = oldR, g = oldG, b = oldB, hasOpacity = false,
        swatchFunc = ApplyPickerColor,
        cancelFunc = function()
            setColor(oldR, oldG, oldB)
            updateSwatch()
            RefreshNameplates()
        end,
    })
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
        OpenColorPicker(getColor, setColor, UpdateSwatch)
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

ns.SettingsPanels.Appearance = CreateAppearancePanel
