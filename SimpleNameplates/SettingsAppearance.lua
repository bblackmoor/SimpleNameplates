-- Simple Nameplates: Appearance settings page.
local _, ns = ...
local U = ns.SettingsUI
local CreateScrollablePanel, AddTitle, AddDescription =
    U.CreateScrollablePanel, U.AddTitle, U.AddDescription
local AddSection, RunRefreshers, RefreshNameplates = U.AddSection, U.RunRefreshers, U.RefreshNameplates
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
    local block = U.CreateSettingRow(content, layout, labelText)
    local dropdown = CreateFrame("Frame", nil, block, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", block, "LEFT", U.CONTROL_X - 16, 0)
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
    sizeBlock.SNPLayoutFullWidth = true
    layout:Add(sizeBlock, 24, 48, 6)
    local sizeLabel = sizeBlock:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sizeLabel:SetPoint("TOPLEFT", 0, -12)
    local sizeValue = sizeBlock:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sizeValue:SetPoint("TOPLEFT", U.CONTROL_X + 188, -12)
    local sizeSlider = CreateFrame("Slider", "SimpleNameplatesNameSizeSlider", sizeBlock, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", U.CONTROL_X, -10)
    sizeSlider:SetSize(180, 18)
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
    U.AddToggle(content, layout, refreshers, "Show threat percentage when available",
        GetThreatEnabled, SetThreatEnabled, RefreshNameplates)
end

local function AddNameSizeNote(content, layout)
    AddDescription(content, layout,
        "All names use this size. Titles use 80%, rounded. " ..
        "Health bars expand to fit inside-bar names with three UI units of padding above and below. Native world labels cannot be resized.")
end

local function AddSanctuaryFontControl(content, layout, refreshers)
    U.AddToggle(content, layout, refreshers, "Match Blizzard font in sanctuaries",
        function() return GetAppearanceSetting("matchSanctuaryFont") end,
        function(checked) SetAppearanceSetting("matchSanctuaryFont", checked) end, RefreshNameplates)
    AddDescription(content, layout,
        "Uses Blizzard's native world-name font in sanctuaries. The selected Name font applies elsewhere, " ..
        "or everywhere when this switch is off. Size, outline, colors, and placement keep their settings.")
end

local function AddSharedAppearanceControls(content, layout, refreshers)
    AddSection(content, layout, "Fonts and sizing")
    AddDescription(content, layout, "Fonts and name size are shared between combat states. Colors are on the Colors page.")

    CreateAppearanceDropdown(content, layout, refreshers, "Name font", ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("nameFont") end,
        function(value) SetAppearanceSetting("nameFont", value) end)
    AddSanctuaryFontControl(content, layout, refreshers)
    AddNameSizeControl(content, layout, refreshers)
    AddNameSizeNote(content, layout)
end

local function AddOutOfCombatControls(context)
    local content, layout = context.content, context.layout
    AddSection(content, layout, "Out of combat")
    AddDescription(content, layout,
        "Friendly players and Useful/Otherwise NPCs use colored names with available titles. " ..
        "Attacking, Hostile, and Neutral entities retain supported bars. NPC service titles appear " ..
        "automatically beneath name-only labels at 80% of the name size; visible health bars hide full titles.")
    AddDescription(content, layout,
        "TRP3 name and title options are on the TRP3 page. Name-only titles can also appear in combat when no supported health bar is available.")
end

local function AddInCombatTextControls(content, layout, refreshers)
    AddSection(content, layout, "In combat")
    AddDescription(content, layout,
        "Every Active category uses supported health and cast bars while you are in combat. " ..
        "The controls below apply whenever those bars are visible, including danger categories out of combat. " ..
        "Names use the shared font and size above; colors are on the Colors page.")
    CreateAppearanceDropdown(content, layout, refreshers, "Health-bar name placement", {
        { value = "ABOVE", label = "Above bar" }, { value = "INSIDE", label = "Inside bar" },
    }, function() return GetAppearanceSetting("namePlacement") end,
        function(value) SetAppearanceSetting("namePlacement", value) end)
    CreateAppearanceDropdown(content, layout, refreshers, "Threat-percentage font", ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("threatFont") end,
        function(value) SetAppearanceSetting("threatFont", value) end)
    AddThreatControl(content, layout, refreshers)
end

local function CreateAppearancePanel()
    local panel, content, layout = CreateScrollablePanel("Appearance")
    AddTitle(content, layout, "Appearance")
    AddDescription(content, layout, "Text, layout, and display effects for the selected appearance profile.")
    local refreshers = {}
    local function Refresh() RunRefreshers(refreshers) end
    ns.AddProfileSelector(content, layout, refreshers, Refresh)
    AddSharedAppearanceControls(content, layout, refreshers)
    AddOutOfCombatControls({content = content, layout = layout})
    AddInCombatTextControls(content, layout, refreshers)
    U.AddToggle(content, layout, refreshers, "Highlight interruptible casts and channels",
        GetInterruptibleHighlightEnabled, SetInterruptibleHighlightEnabled, RefreshNameplates)
    AddDescription(content, layout,
        "Pulses the cast-bar border when Blizzard reports an interruptible cast or channel. Its color is on Colors.")
    ns.AddGlobalAppearanceControls(content, layout, refreshers)
    AddSection(content, layout, "Reset text and layout")
    AddDescription(content, layout,
        "Restores this profile's fonts, name size, sanctuary font matching, and name placement, and enables threat display. " ..
        "Colors and the cast-highlight switch keep their values.")
    U.AddActionButton(content, layout, "Reset text and layout", function()
        ResetAppearance()
        SetThreatEnabled(true)
        Refresh()
        RefreshNameplates()
    end)
    panel:SetScript("OnShow", Refresh)
    Refresh()
    layout:Finish()
    return panel
end
ns.SettingsPanels.Appearance = CreateAppearancePanel

