-- Simple Nameplates: profile appearance and global critter visibility.
local _, ns = ...
local U, W = ns.SettingsUI, ns.SettingsWidgets
local function Refresh(context) U.RunRefreshers(context.refreshers) end

local function AddToggle(context, label, getter, setter, onChanged)
    U.AddSwitchRow(context.content, context.layout, context.refreshers, label, getter, function(value)
        setter(value)
        if onChanged then onChanged() end
    end)
end

local function AddFont(context, label, key)
    local selected
    local _, dropdown = U.CreateDropdownRow(context.content, context.layout, label, function()
        return ns.GetFontOptions(ns.GetAppearanceSetting(key))
    end, function(value)
        ns.SetAppearanceSetting(key, value)
        Refresh(context)
        U.RefreshNameplates()
    end)
    local function RefreshFont()
        local value = ns.GetAppearanceSetting(key)
        if value ~= selected then dropdown:InvalidateOptions(); selected = value end
        dropdown:SetValue(value, ns.FontLabel(value))
    end
    context.refreshers[#context.refreshers + 1] = RefreshFont
    context.fontRefreshers[#context.fontRefreshers + 1] = function()
        dropdown:InvalidateOptions() -- Rebuild only on the next menu opening.
        RefreshFont()
    end
end

local function AddSize(context, key, label, minimum, maximum, step, suffix)
    local block = CreateFrame("Frame", nil, context.content)
    block.SNPLayoutFullWidth = true
    context.layout:Add(block, 24, 48, 6)
    local text = block:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 0, -12)
    text:SetText(label)
    local amount = block:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    amount:SetPoint("TOPLEFT", U.CONTROL_X + 188, -12)
    local slider = W.CreateSlider(block, minimum, maximum, step, function(value)
        amount:SetText(tostring(value) .. suffix)
        if value == ns.GetAppearanceSetting(key) then return end
        ns.SetAppearanceSetting(key, value)
        if not context.canceling then U.RefreshNameplates() end
    end)
    slider:SetPoint("TOPLEFT", block, "TOPLEFT", U.CONTROL_X, -10)
    slider:GetFrame():SetHeight(18)
    slider.widget.amt:Hide() -- The existing adjacent value label carries units.
    for _, endpoint in ipairs({{minimum, "LEFT"}, {maximum, "RIGHT"}}) do
        local caption = block:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        caption:SetText(tostring(endpoint[1]))
        caption:SetPoint("TOP" .. endpoint[2], slider:GetFrame(), "BOTTOM" .. endpoint[2], 0, -2)
    end
    context.sliders[#context.sliders + 1] = slider
    context.refreshers[#context.refreshers + 1] = function()
        local value = ns.GetAppearanceSetting(key)
        slider:SetValue(value)
        amount:SetText(tostring(value) .. suffix)
    end
end

local function AddPlacement(context)
    local options = {{value = "ABOVE", label = "Above bar"}, {value = "INSIDE", label = "Inside bar"}}
    local _, dropdown = U.CreateDropdownRow(context.content, context.layout, "Health-bar name placement", function() return options end, function(value)
        ns.SetAppearanceSetting("namePlacement", value)
        Refresh(context)
        U.RefreshNameplates()
    end)
    context.refreshers[#context.refreshers + 1] = function()
        dropdown:SetValue(ns.GetAppearanceSetting("namePlacement"))
    end
end

local function AddControls(context)
    local content, layout = context.content, context.layout
    U.AddSection(content, layout, "Fonts and sizing")
    AddFont(context, "Name font", "nameFont")
    U.AddDescription(content, layout, "Includes fonts registered by other addons and SharedMedia packs.")
    AddToggle(context, "Use smoother font rendering (Slug)",
        function() return ns.GetAppearanceSetting("useSlugRendering") end,
        function(value) ns.SetAppearanceSetting("useSlugRendering", value) end, U.RefreshNameplates)
    U.AddDescription(content, layout,
        "Applies to names, titles, health, threat and cast text. Uses thin outlines outside health bars; keeps the two black underlayers inside.")
    AddToggle(context, "Match Blizzard font in sanctuaries",
        function() return ns.GetAppearanceSetting("matchSanctuaryFont") end,
        function(value) ns.SetAppearanceSetting("matchSanctuaryFont", value) end, U.RefreshNameplates)
    U.AddDescription(content, layout, "When off, the selected Name font applies everywhere.")
    AddSize(context, "nameSize", "Name size", ns.MIN_NAME_SIZE, ns.MAX_NAME_SIZE, 1, " pt")
    U.AddDescription(content, layout,
        "Also sets threat-text size. Titles use 80%; inside-bar text has four units above and three below.")
    U.AddSection(content, layout, "Health bars")
    U.AddDescription(content, layout,
        "Out of combat, only Attacking, Hostile and Neutral use bars. In combat, all Active categories use available bars.")
    AddSize(context, "healthBarWidth", "Health bar width", ns.MIN_HEALTH_BAR_WIDTH, ns.MAX_HEALTH_BAR_WIDTH, 5, "%")
    AddPlacement(context)
    AddFont(context, "Threat-percentage font", "threatFont")
    AddToggle(context, "Show threat percentage when available", ns.GetThreatEnabled, ns.SetThreatEnabled, U.RefreshNameplates)
    U.AddSection(content, layout, "Global visibility")
    -- This setter owns its CVar capture/restoration.
    AddToggle(context, "Hide critter and companion names", ns.GetHideCritterCompanionNames, ns.SetHideCritterCompanionNames)
    U.AddDescription(content, layout, "Noncombat units only.")
end

local function CreateAppearancePanel()
    local panel, content, layout = U.CreateScrollablePanel("Appearance")
    U.AddTitle(content, layout, "Appearance")
    local context = {content = content, layout = layout, refreshers = {}, fontRefreshers = {}, sliders = {}}
    local function CancelEdits(quiet)
        local changed = false
        context.canceling = true
        for _, slider in ipairs(context.sliders) do
            local previous = slider:GetValue()
            slider:CancelEdit()
            if previous ~= slider:GetValue() then changed = true end
        end
        context.canceling = false
        if changed and not quiet then U.RefreshNameplates() end
    end
    ns.CancelAppearanceEdits = CancelEdits
    ns.RefreshFontControls = function() U.RunRefreshers(context.fontRefreshers) end
    local function RefreshPage() Refresh(context) end
    ns.AddProfileSelector(content, layout, context.refreshers, RefreshPage)
    U.AddPageAction(content, layout, "Reset settings", function()
        CancelEdits(true)
        ns.ResetAppearance()
        ns.SetThreatEnabled(ns.Defaults.showThreat)
        ns.SetHideCritterCompanionNames(ns.Defaults.hideCritterCompanionNames)
        RefreshPage()
        U.RefreshNameplates()
    end)
    U.AddDescription(content, layout, "Resets the settings below, including global critter/companion visibility.")
    AddControls(context)
    panel:SetScript("OnShow", RefreshPage)
    panel:SetScript("OnHide", function() CancelEdits() end)
    RefreshPage()
    layout:Finish()
    return panel
end
ns.SettingsPanels.Appearance = CreateAppearancePanel
