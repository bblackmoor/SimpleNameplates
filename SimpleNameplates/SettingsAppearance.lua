-- Simple Nameplates: Appearance settings page.
local _, ns = ...
local U = ns.SettingsUI
local CreateScrollablePanel, AddTitle, AddDescription =
    U.CreateScrollablePanel, U.AddTitle, U.AddDescription
local AddSection, RunRefreshers, RefreshNameplates = U.AddSection, U.RunRefreshers, U.RefreshNameplates
local GetAppearanceSetting, SetAppearanceSetting, ResetAppearance =
    ns.GetAppearanceSetting, ns.SetAppearanceSetting, ns.ResetAppearance
local GetThreatEnabled, SetThreatEnabled = ns.GetThreatEnabled, ns.SetThreatEnabled

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
        "Also sets threat-text size. Titles use 80%; inside-bar names add three units of padding above and below.")
end

local function AddSanctuaryFontControl(content, layout, refreshers)
    U.AddToggle(content, layout, refreshers, "Match Blizzard font in sanctuaries",
        function() return GetAppearanceSetting("matchSanctuaryFont") end,
        function(checked) SetAppearanceSetting("matchSanctuaryFont", checked) end, RefreshNameplates)
    AddDescription(content, layout,
        "When off, the selected Name font applies everywhere.")
end

local function AddSharedAppearanceControls(content, layout, refreshers)
    AddSection(content, layout, "Fonts and sizing")

    CreateAppearanceDropdown(content, layout, refreshers, "Name font", ns.FONT_OPTIONS,
        function() return GetAppearanceSetting("nameFont") end,
        function(value) SetAppearanceSetting("nameFont", value) end)
    AddSanctuaryFontControl(content, layout, refreshers)
    AddNameSizeControl(content, layout, refreshers)
    AddNameSizeNote(content, layout)
end

local function AddInCombatTextControls(content, layout, refreshers)
    AddSection(content, layout, "Health bars")
    AddDescription(content, layout,
        "Out of combat, only Attacking, Hostile and Neutral use bars. In combat, all Active categories use available bars.")
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
    local refreshers = {}
    local function Refresh() RunRefreshers(refreshers) end
    ns.AddProfileSelector(content, layout, refreshers, Refresh)
    U.AddActionButton(content, layout, "Reset settings", function()
        ResetAppearance()
        SetThreatEnabled(ns.Defaults.showThreat)
        ns.SetHideCritterCompanionNames(ns.Defaults.hideCritterCompanionNames)
        Refresh()
        RefreshNameplates()
    end)
    AddDescription(content, layout,
        "Resets the settings below, including global critter/companion visibility.")
    AddSharedAppearanceControls(content, layout, refreshers)
    AddInCombatTextControls(content, layout, refreshers)
    ns.AddGlobalAppearanceControls(content, layout, refreshers)
    panel:SetScript("OnShow", Refresh)
    Refresh()
    layout:Finish()
    return panel
end
ns.SettingsPanels.Appearance = CreateAppearancePanel

