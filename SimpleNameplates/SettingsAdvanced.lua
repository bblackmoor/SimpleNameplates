-- Experiment with per-profile cast effects without cluttering Colors.
local _, addon = ...
local UI, Widgets = addon.SettingsUI, addon.SettingsWidgets

local function CreateAdvancedPanel()
    local panel, content, layout = UI.CreateScrollablePanel("Advanced")
    UI.AddTitle(content, layout, "Advanced")
    local refreshers, sliders, previews = {}, {}, {}
    local canceling = false
    local function Refresh() UI.RunRefreshers(refreshers) end
    local function Preview(effect)
        local bar = previews[effect]
        if bar and addon.CastHighlight then addon.CastHighlight.UpdatePreview(bar, effect) end
    end
    local function CancelEdits(quiet)
        canceling = true
        local changed = false
        for _, slider in ipairs(sliders) do
            local old = slider:GetValue()
            slider:CancelEdit()
            if old ~= slider:GetValue() then changed = true end
        end
        canceling = false
        if changed and not quiet then UI.RefreshNameplates() end
    end
    addon.CancelAdvancedEdits = CancelEdits
    addon.AddProfileSelector(content, layout, refreshers, Refresh)
    UI.AddPageAction(content, layout, "Reset advanced effects", function()
        CancelEdits(true)
        addon.ResetCastAdvanced()
        Refresh()
        UI.RefreshNameplates()
    end)
    UI.AddDescription(content, layout,
        "Experimental settings are saved per profile. Cast highlight color, selected effect, and Active remain on Colors. " ..
        "Adjustments apply immediately, and Reset restores these effect parameters.")
    for _, effect in ipairs({"PULSE", "SOLID", "SOFT", "ANTS", "GLOW"}) do
        UI.AddSection(content, layout, addon.CAST_EFFECT_BY_VALUE[effect])
        if effect == "ANTS" then
            UI.AddDescription(content, layout,
                "Timing and frame count use Blizzard's fixed animation sprite sheet. Individual dash length/spacing are encoded in that texture.")
        elseif effect == "GLOW" then
            UI.AddDescription(content, layout,
                "Blizzard controls the animation speed and intrinsic texture thickness. Extent adjusts the visible size.")
        elseif effect == "SOFT" then
            UI.AddDescription(content, layout,
                "Three translucent layers; spread positions their parent independently of the framework's ineffective spread parameter.")
        end
        for _, definition in ipairs(addon.CAST_ADVANCED_CONTROLS[effect]) do
            local key = definition.key
            if definition.kind == "switch" then
                UI.AddSwitchRow(content, layout, refreshers, definition.label,
                    function() return addon.GetCastAdvancedSetting(effect, key) end,
                    function(value)
                        addon.SetCastAdvancedSetting(effect, key, value)
                        Preview(effect)
                        UI.RefreshNameplates()
                    end)
            else
                local block = CreateFrame("Frame", nil, content)
                block.LayoutFullWidth = true
                layout:Add(block, 24, 48, 6)
                local label = block:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                label:SetPoint("TOPLEFT", 0, -12)
                label:SetText(definition.label)
                local amount = block:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                amount:SetPoint("TOPLEFT", UI.CONTROL_X + 188, -12)
                local slider = Widgets.CreateSlider(block, definition.min, definition.max, definition.step, function(value)
                    amount:SetText(string.format("%g", value) .. (definition.suffix or ""))
                    if value == addon.GetCastAdvancedSetting(effect, key) then return end
                    addon.SetCastAdvancedSetting(effect, key, value)
                    if not canceling then Preview(effect); UI.RefreshNameplates() end
                end)
                slider:SetPoint("TOPLEFT", block, "TOPLEFT", UI.CONTROL_X, -10)
                slider:GetFrame():SetHeight(18)
                if slider.widget.amt then slider.widget.amt:Hide() end
                for _, endpoint in ipairs({{definition.min, "LEFT"}, {definition.max, "RIGHT"}}) do
                    local caption = block:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                    caption:SetText(string.format("%g", endpoint[1]))
                    caption:SetPoint("TOP"..endpoint[2], slider:GetFrame(), "BOTTOM"..endpoint[2], 0, -2)
                end
                sliders[#sliders+1] = slider
                refreshers[#refreshers+1] = function()
                    local value = addon.GetCastAdvancedSetting(effect, key)
                    slider:SetValue(value)
                    amount:SetText(string.format("%g", value) .. (definition.suffix or ""))
                end
            end
        end
        local row = UI.CreateSettingRow(content, layout, "Preview: " .. addon.CAST_EFFECT_BY_VALUE[effect])
        local bar = CreateFrame("StatusBar", nil, row)
        bar:SetPoint("LEFT", row, "LEFT", UI.CONTROL_X, 0)
        bar:SetSize(190, 16)
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        bar:SetStatusBarColor(0.25, 0.25, 0.25, 1)
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(65)
        previews[effect] = bar
        refreshers[#refreshers+1] = function() Preview(effect) end
    end
    panel.Refresh = Refresh
    panel:SetScript("OnShow", Refresh)
    panel:SetScript("OnHide", function()
        CancelEdits()
        for _, bar in pairs(previews) do
            if addon.CastHighlight then addon.CastHighlight.StopPreview(bar) end
        end
    end)
    Refresh()
    layout:Finish()
    return panel
end

addon.SettingsPanels.Advanced = CreateAdvancedPanel
