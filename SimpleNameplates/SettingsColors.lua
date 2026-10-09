-- Simple Nameplates: profile colors and category health-bar preferences.
local _, addon = ...
local UI = addon.SettingsUI
local AddSection, AddDescription, RunRefreshers, RefreshNameplates =
    UI.AddSection, UI.AddDescription, UI.RunRefreshers, UI.RefreshNameplates
local PriorityColorForState, SetPriorityColor = addon.PriorityColorForState, addon.SetPriorityColor
local EffectColor, SetEffectColor = addon.EffectColor, addon.SetEffectColor

local Widgets = addon.SettingsWidgets

local function RefreshContext(context)
    RunRefreshers(context.refreshers)
end

local function AddHealthBarSwitch(context, row, swatch, state)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetText("Health Bar")
    label:SetPoint("LEFT", swatch:GetFrame(), "RIGHT", 12, 0)
    local toggle = Widgets.CreateSwitch(row, function(checked)
        addon.SetHealthBarEnabled(state, checked)
        RefreshContext(context)
        RefreshNameplates()
    end)
    toggle:SetPoint("LEFT", label, "RIGHT", 8, 0)
    context.refreshers[#context.refreshers + 1] = function()
        toggle:SetChecked(addon.GetHealthBarEnabled(state))
    end
end

local function AddCastHighlightSwitch(context, row, swatch)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetText("Active")
    label:SetPoint("LEFT", swatch:GetFrame(), "RIGHT", 12, 0)
    local toggle = Widgets.CreateSwitch(row, function(checked)
        addon.SetInterruptibleHighlightEnabled(checked)
        RefreshContext(context)
        RefreshNameplates()
    end)
    toggle:SetPoint("LEFT", label, "RIGHT", 8, 0)
    context.refreshers[#context.refreshers + 1] = function()
        toggle:SetChecked(addon.GetInterruptibleHighlightEnabled())
    end
end

local function AddCastBorderControls(context)
    for _, effect in ipairs({"PULSE"}) do
        for _, definition in ipairs(addon.CAST_BORDER_CONTROLS[effect]) do
            local key = definition.key
            local block = CreateFrame("Frame", nil, context.content)
            block.LayoutFullWidth = true
            context.layout:Add(block, 24, 48, 6)
            local label = block:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            label:SetPoint("TOPLEFT", 0, -12)
            label:SetText(definition.label)
            local amount = block:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            amount:SetPoint("TOPLEFT", UI.CONTROL_X + 188, -12)
            local slider = Widgets.CreateSlider(block, definition.min, definition.max, definition.step, function(value)
                amount:SetText(string.format("%g", value) .. definition.suffix)
                if value == addon.GetCastBorderSetting(effect, key) then return end
                addon.SetCastBorderSetting(effect, key, value)
                if not context.canceling then RefreshContext(context); RefreshNameplates() end
            end)
            slider:SetPoint("TOPLEFT", block, "TOPLEFT", UI.CONTROL_X, -10)
            slider:GetFrame():SetHeight(18)
            if slider.widget.amt then slider.widget.amt:Hide() end
            for _, endpoint in ipairs({{definition.min, "LEFT"}, {definition.max, "RIGHT"}}) do
                local caption = block:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                caption:SetText(string.format("%g", endpoint[1]))
                caption:SetPoint("TOP"..endpoint[2], slider:GetFrame(), "BOTTOM"..endpoint[2], 0, -2)
            end
            context.sliders[#context.sliders + 1] = slider
            context.refreshers[#context.refreshers + 1] = function()
                local value = addon.GetCastBorderSetting(effect, key)
                slider:SetValue(value)
                amount:SetText(string.format("%g", value) .. definition.suffix)
            end
        end
    end
end

local function AddCastEffectControl(context)
    local _, dropdown = UI.CreateDropdownRow(context.content, context.layout, "Effect",
        function() return addon.CAST_EFFECT_OPTIONS end, function(value)
            addon.SetInterruptibleEffect(value)
            RefreshContext(context)
            RefreshNameplates()
        end)
    context.refreshers[#context.refreshers + 1] = function()
        local value = addon.GetInterruptibleEffect()
        dropdown:SetValue(value, addon.CAST_EFFECT_BY_VALUE[value])
    end
    AddCastBorderControls(context)
    local row = UI.CreateSettingRow(context.content, context.layout, "Effect preview")
    local preview = CreateFrame("StatusBar", nil, row)
    preview:SetPoint("LEFT", row, "LEFT", UI.CONTROL_X, 0)
    preview:SetSize(190, 14)
    preview:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    preview:SetStatusBarColor(0.25, 0.25, 0.25, 1)
    preview:SetMinMaxValues(0, 100)
    preview:SetValue(65)
    context.preview = preview
    context.refreshers[#context.refreshers + 1] = function()
        if addon.CastHighlight then addon.CastHighlight.UpdatePreview(preview) end
    end
    AddDescription(context.content, context.layout,
        "Preview demonstrates the selected effect even while Inactive; it does not detect a real cast. Enable Active above to highlight interruptible enemy casts.")
end

local function CreateColorRow(context, text, displayText, getColor, setColor, state)
    local row = UI.CreateSettingRow(context.content, context.layout, text)
    local swatch = Widgets.CreateColorPicker(row, function(r, g, b)
        setColor(r, g, b)
        RefreshContext(context)
        RefreshNameplates()
    end, getColor)
    swatch:SetPoint("LEFT", row, "LEFT", UI.CONTROL_X, 0)
    context.refreshers[#context.refreshers + 1] = function() swatch:SetColor(getColor()) end
    local frame = swatch:GetFrame()
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:AddLine("Click to choose a color.", 1, 1, 1)
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
    if state then AddHealthBarSwitch(context, row, swatch, state) end
    if displayText then AddDescription(context.content, context.layout, displayText) end
    return row, swatch
end

local function CreatePriorityColorRow(context, text, state, displayText)
    CreateColorRow(context, text, displayText,
        function() return PriorityColorForState(state) end,
        function(r, g, b) SetPriorityColor(state, r, g, b) end,
        state)
end

local function AddGradientControl(context)
    local row = UI.CreateSettingRow(context.content, context.layout, "Gradient opacity")
    context.layout.items[#context.layout.items].height = 48
    local amount = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    amount:SetPoint("LEFT", row, "LEFT", UI.CONTROL_X + 188, 0)
    amount:SetWidth(40)
    local slider = Widgets.CreateSlider(row, 0, 100, 1, function(value)
        amount:SetText(string.format("%d%%", value))
        if value == addon.GetGradientOpacity() then return end
        addon.SetGradientOpacity(value)
        if not context.canceling then RefreshContext(context); RefreshNameplates() end
    end)
    slider:SetPoint("LEFT", row, "LEFT", UI.CONTROL_X, 0)
    for _, endpoint in ipairs({{0, "LEFT"}, {100, "RIGHT"}}) do
        local caption = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        caption:SetText(endpoint[1] .. "%")
        caption:SetPoint("TOP"..endpoint[2], slider:GetFrame(), "BOTTOM"..endpoint[2], 0, -2)
    end
    if slider.widget.amt then slider.widget.amt:Hide() end
    context.sliders[#context.sliders + 1] = slider
    context.refreshers[#context.refreshers + 1] = function()
        local value = addon.GetGradientOpacity()
        slider:SetValue(value)
        amount:SetText(string.format("%d%%", value))
    end
    local preview = CreateFrame("StatusBar", nil, row)
    preview:SetPoint("LEFT", amount, "RIGHT", 12, 0)
    preview:SetWidth(190)
    preview:SetMinMaxValues(0, 100)
    preview:SetValue(100)
    preview:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    local name = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local threat = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", preview, "LEFT", 3, -0.5)
    name:SetPoint("RIGHT", threat, "LEFT", -3, 0)
    name:SetJustifyH("LEFT")
    name:SetText("Sample")
    threat:SetPoint("RIGHT", preview, "RIGHT", -3, -0.5)
    threat:SetJustifyH("RIGHT")
    threat:SetText("255%")
    for _, text in ipairs({name, threat}) do
        text:SetDrawLayer("OVERLAY", 7)
        text:SetTextColor(1, 1, 1, 1)
        text:SetWordWrap(false)
        text:SetMaxLines(1)
    end
    context.refreshers[#context.refreshers + 1] = function()
        local size = addon.GetAppearanceSetting("nameSize")
        local flags = addon.FontFlags and addon.FontFlags() or ""
        preview:SetHeight(size + 7)
        preview:SetStatusBarColor(PriorityColorForState("hostile"))
        name:SetFont(addon.FontPath(addon.GetAppearanceSetting("nameFont")), size, flags)
        threat:SetFont(addon.FontPath(addon.GetAppearanceSetting("threatFont")), size, flags)
        if addon.HealthGradient then
            addon.HealthGradient.Apply(preview, preview:GetStatusBarTexture(), addon.WorldContext.Get())
        end
    end
end

local function AddBackgroundNameControl(context)
    local row = UI.CreateSettingRow(context.content, context.layout, "Dim background NPC names")
    local toggle = Widgets.CreateSwitch(row, function(checked)
        addon.SetDimBackgroundNames(checked)
        RefreshContext(context)
        RefreshNameplates()
    end)
    toggle:SetPoint("LEFT", row, "LEFT", UI.CONTROL_X, 0)
    context.refreshers[#context.refreshers + 1] = function()
        toggle:SetChecked(addon.GetDimBackgroundNames())
    end
end

local function AddPriorityColorControls(context)
    AddSection(context.content, context.layout, "Priority colors")
    AddDescription(context.content, context.layout,
        "First matching category wins. Health Bar switches apply to the selected profile. Off shows the name and title together, without a health bar. Blizzard-controlled plates may be unchangeable.")
    CreatePriorityColorRow(context, "1. Attacking me", "attacking",
        "Includes attacks on your controlled units.")
    CreatePriorityColorRow(context, "2. Will attack me — Hostile", "hostile",
        "Includes eligible PvP opponents.")
    CreatePriorityColorRow(context, "3. Can attack me — Neutral", "neutral")
    CreatePriorityColorRow(context, "4. Player - Friendly", "friendly")
    CreatePriorityColorRow(context, "5. NPC - Interactive", "useful")
    CreatePriorityColorRow(context, "6. NPC - Background", "useless")
    AddBackgroundNameControl(context)
end

local function CreateColorsPanel()
    local panel, content, layout = UI.CreateScrollablePanel("Colors")
    UI.AddTitle(content, layout, "Colors")
    local context = {content = content, layout = layout, refreshers = {}, sliders = {}}
    local function CancelColorsEdits(quiet)
        context.canceling = true
        local changed = false
        Widgets.CancelEdits(function()
            for _, slider in ipairs(context.sliders) do
                local old = slider:GetValue()
                slider:CancelCombatEdit()
                if old ~= slider:GetValue() then changed = true end
            end
        end)
        context.canceling = false
        if changed and not quiet then RefreshNameplates() end
    end
    addon.CancelColorsEdits = CancelColorsEdits
    local function Refresh()
        RefreshContext(context)
    end
    addon.AddProfileSelector(content, layout, context.refreshers, Refresh)
    UI.AddPageAction(content, layout, "Reset all colors", function()
        UI.CancelColorEdit()
        addon.ResetAllColors()
        Refresh()
        RefreshNameplates()
    end)
    AddDescription(content, layout,
        "Restores High Contrast defaults for that profile, Default for all others. " ..
        "Restores health bars to On except NPC - Background, background-name dimming to On, gradient opacity to 100% for Default/custom profiles or 0% for High Contrast, and cast highlight to Inactive with Pulsing border, border thickness to 4, and pulse fade times to 0.2 seconds.")
    AddGradientControl(context)
    AddPriorityColorControls(context)
    AddSection(content, layout, "Cast highlight color")
    local row, swatch = CreateColorRow(context, "Interruptible cast highlight",
        "Highlights interruptible casts and channels. Applies to the selected profile.",
        function() return EffectColor("interruptible") end,
        function(r, g, b) SetEffectColor("interruptible", r, g, b) end)
    AddCastHighlightSwitch(context, row, swatch)
    AddCastEffectControl(context)
    panel.Refresh = Refresh
    panel:SetScript("OnShow", panel.Refresh)
    panel:SetScript("OnHide", function()
        CancelColorsEdits()
        UI.CancelColorEdit()
        if addon.CastHighlight then addon.CastHighlight.StopPreview(context.preview) end
    end)
    Refresh()
    layout:Finish()
    return panel
end
addon.SettingsPanels.Colors = CreateColorsPanel




