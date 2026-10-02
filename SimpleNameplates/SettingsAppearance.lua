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

local function AddSharedAppearanceControls(content, layout, refreshers)
    AddSectionResetButton(content, layout, "SHARED APPEARANCE", "Reset Appearance", function()
        ResetAppearance()
        SetThreatEnabled(true)
        for _, refresh in ipairs(refreshers) do refresh() end
        RefreshNameplates()
    end)
    AddDescription(content, layout,
        "Fonts, name size, and colors are shared between combat states. Reset Appearance resets text and layout in both sections below.", 40)

    CreateAppearanceDropdown(content, layout, refreshers, "Name font", ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("nameFont") end,
        function(value) SetAppearanceSetting("nameFont", value) end)
    AddNameSizeControl(content, layout, refreshers)
    AddNameSizeNote(content, layout)
end

local function AddOutOfCombatControls(context)
    local content, layout = context.content, context.layout
    layout:Space(8)
    AddSection(content, layout, "OUT OF COMBAT")
    AddDescription(content, layout,
        "Friendly players and Useful/Otherwise NPCs use colored names with available titles. " ..
        "Attacking, Hostile, and Neutral entities retain supported bars. NPC service titles appear " ..
        "automatically beneath name-only labels at 80% of the name size; visible health bars hide full titles.", 74)
    if ns.AddTRP3FullTitleControl then
        ns.AddTRP3FullTitleControl(content, layout, context.toggleRefreshers)
    end
    AddDescription(content, layout,
        "TRP3 title integration is global and applies to every appearance profile. Other TRP3 options remain on the TRP3 page. " ..
        "Name-only titles can also appear in combat when no supported health bar is available.", 58)
end

local function AddInCombatTextControls(content, layout, refreshers)
    AddSection(content, layout, "IN COMBAT")
    AddDescription(content, layout,
        "Every Active category uses supported health and cast bars while you are in combat. " ..
        "The controls below apply whenever those bars are visible, including danger categories out of combat. " ..
        "Fonts and colors come from Shared Appearance.", 62)
    CreateAppearanceDropdown(content, layout, refreshers, "Health-bar name placement", {
        { value = "ABOVE", label = "Above bar" }, { value = "INSIDE", label = "Inside bar" },
    }, function() return GetAppearanceSetting("namePlacement") end,
        function(value) SetAppearanceSetting("namePlacement", value) end)
    CreateAppearanceDropdown(content, layout, refreshers, "Threat-percentage font", ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("threatFont") end,
        function(value) SetAppearanceSetting("threatFont", value) end)
    AddThreatControl(content, layout, refreshers)
end

local function RegisterAppearancePopups()
    StaticPopupDialogs["SNP_BLIZZARD_OVERHEAD_INFO"] = {
        text = "Nonattackable opposite-faction PCs in sanctuary have been observed with native periwinkle overhead labels and no matching addon-accessible plate. That presentation remains outside the addon's control. The verified entity types and world contexts are listed in About.\n\nNative pet, guardian, totem, and minion world labels are also separate from nameplate text. Simple Nameplates styles those entities only where Blizzard supplies an accessible plate.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_BLIZZARD_INTERACTIVE_INFO"] = {
        text = "Blizzard's native interactive-NPC world labels are separate from addon-accessible nameplates. Their native color is controlled by the game.\n\nInteractive NPCs can also have ordinary nameplates that Simple Nameplates styles, including service titles when verified. Enable Friendly NPC Nameplates for ordinary friendly NPC plates. A native world-label color does not establish whether a separate plate is available.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_BLIZZARD_VENDOR_INFO"] = {
        text = "Blizzard's native vendor-NPC world labels are separate from addon-accessible nameplates. Their native color is controlled by the game.\n\nVendor NPCs can also have ordinary nameplates that Simple Nameplates styles, including service titles when verified. Enable Friendly NPC Nameplates for ordinary friendly NPC plates. Vendors are not a blanket unalterable entity category.",
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
        "Health bar; includes attacks on your controlled units; overrides 2–6")
    CreatePriorityColorRow(context, "2. Will attack me — Hostile", "hostile",
        "Health bar for aggressive NPCs and eligible PvP opponents")
    CreatePriorityColorRow(context, "3. Can attack me — Neutral", "neutral",
        "Health bar for entities that can attack you without a higher priority")
    CreatePriorityColorRow(context, "4. Player — Friendly", "friendly",
        "Colored name out of combat; colored health bar in combat when supported")
    CreatePriorityColorRow(context, "5. Interactive NPC — Useful", "useful",
        "Interactive NPC: colored name out of combat; health bar in combat when supported")
    CreatePriorityColorRow(context, "6. Otherwise — Useless", "useless",
        "Remaining entity: colored name out of combat; health bar in combat when supported")

    AddSection(context.content, context.layout, "SANCTUARY COLORS")
    CreatePriorityColorRow(context, "Same-faction player", "sanctuaryFriendly",
        "Sanctuary only; higher combat priorities keep their normal colors")
    CreatePriorityColorRow(context, "Interactive NPC — Useful", "sanctuaryUseful",
        "Sanctuary only; higher combat priorities keep their normal colors")
    CreatePriorityColorRow(context, "Other NPC — Useless", "sanctuaryUseless",
        "Sanctuary only; applies to NPCs in the Otherwise category")
end

local function AddLockedColorControls(context)
    context.layout:Space(6)
    AddSection(context.content, context.layout, "BLIZZARD-CONTROLLED OVERHEAD NAMES")
    CreateLockedColorRow(context, "Native PC and player-controlled minion world labels",
        102 / 255, 102 / 255, 1, "SNP_BLIZZARD_OVERHEAD_INFO")
    CreateLockedColorRow(context, "Native interactive-NPC world labels",
        1, 1, 0, "SNP_BLIZZARD_INTERACTIVE_INFO")
    CreateLockedColorRow(context, "Native vendor-NPC world labels",
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
        "Profiles share fonts and colors across combat states. Below, presentation is grouped by Out of Combat and In Combat. Each character remembers its profile.", 42)
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
    AddSharedAppearanceControls(content, layout, context.toggleRefreshers)
    layout:Space(8)
    AddPriorityColorControls(context)
    AddLockedColorControls(context)
    AddOutOfCombatControls(context)
    layout:Space(8)
    AddInCombatTextControls(content, layout, context.toggleRefreshers)
    AddCastBarControls(context)

    panel:SetScript("OnShow", function() RefreshAppearanceControls(context) end)
    RefreshAppearanceControls(context)
    layout:Finish()
    return panel
end

ns.SettingsPanels.Appearance = CreateAppearancePanel
