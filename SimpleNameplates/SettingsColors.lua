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
end

local function CreatePriorityColorRow(context, text, state, displayText)
    CreateColorRow(context, text, displayText,
        function() return PriorityColorForState(state) end,
        function(r, g, b) SetPriorityColor(state, r, g, b) end,
        state)
end

local function AddGradientControl(context)
    local row = UI.CreateSettingRow(context.content, context.layout, "Gradients")
    -- Reserve room for a preview even at the maximum configured font size.
    context.layout.items[#context.layout.items].height = 50
    local toggle = Widgets.CreateSwitch(row, function(checked)
        addon.SetGradientEnabled(checked)
        RefreshContext(context)
        RefreshNameplates()
    end)
    toggle:SetPoint("LEFT", row, "LEFT", UI.CONTROL_X, 0)
    context.refreshers[#context.refreshers + 1] = function()
        toggle:SetChecked(addon.GetGradientEnabled())
    end
    local preview = CreateFrame("StatusBar", nil, row)
    preview:SetPoint("LEFT", toggle:GetFrame(), "RIGHT", 12, 0)
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
        text:SetTextColor(1, 1, 1, 1)
        text:SetWordWrap(false)
        text:SetMaxLines(1)
    end
    context.refreshers[#context.refreshers + 1] = function()
        local size = addon.GetAppearanceSetting("nameSize")
        local flags = addon.FontFlags and addon.FontFlags(false) or ""
        preview:SetHeight(size + 7)
        preview:SetStatusBarColor(PriorityColorForState("hostile"))
        name:SetFont(addon.FontPath(addon.GetAppearanceSetting("nameFont")), size, flags)
        threat:SetFont(addon.FontPath(addon.GetAppearanceSetting("threatFont")), size, flags)
        if addon.HealthGradient then
            addon.HealthGradient.Apply(preview, preview:GetStatusBarTexture(), addon.WorldContext.Get())
            if addon.HealthGradient.Enabled() then addon.TextUnderlayers.Hide(name)
            else addon.TextUnderlayers.Update(name, preview) end
            -- Full health always retains the threat glyph copies.
            addon.TextUnderlayers.Update(threat, preview)
        end
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
    CreatePriorityColorRow(context, "6. NPC - Background", "useless",
        "Fallback for unmatched entities.")
end

local function AddCastEffectSelector(context)
    local options = {
        {value = "NONE", label = "None"},
        {value = "PIXEL", label = "Moving dashes"},
        {value = "AUTOCAST", label = "Autocast Shine"},
        {value = "BUTTON", label = "Action Button Glow"},
        {value = "PROC", label = "Proc Glow"},
    }
    local _, dropdown = UI.CreateDropdownRow(context.content, context.layout, "Effect", function() return options end, function(value)
        addon.SetInterruptibleCastStyle(value)
        RefreshContext(context)
        RefreshNameplates()
    end)
    context.refreshers[#context.refreshers + 1] = function()
        dropdown:SetValue(addon.GetInterruptibleCastStyle())
    end
end

local function CreateColorsPanel()
    local panel, content, layout = UI.CreateScrollablePanel("Colors")
    UI.AddTitle(content, layout, "Colors")
    local context = {content = content, layout = layout, refreshers = {}}
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
        "Restores this profile's Health Bar switches to On, gradients to Off, and cast highlight to None.")
    AddGradientControl(context)
    AddPriorityColorControls(context)
    AddSection(content, layout, "Cast highlight color")
    CreateColorRow(context, "Interruptible cast highlight",
        "Highlights interruptible casts and channels. Applies to the selected profile.",
        function() return EffectColor("interruptible") end,
        function(r, g, b) SetEffectColor("interruptible", r, g, b) end)
    AddCastEffectSelector(context)
    panel.Refresh = Refresh
    panel:SetScript("OnShow", panel.Refresh)
    panel:SetScript("OnHide", function() UI.CancelColorEdit() end)
    Refresh()
    layout:Finish()
    return panel
end
addon.SettingsPanels.Colors = CreateColorsPanel


