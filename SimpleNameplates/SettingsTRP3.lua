-- Simple Nameplates: TRP3 settings page.
local _, ns = ...
local U = ns.SettingsUI
local CreateScrollablePanel, AddTitle, AddDescription, CreateSwitch =
    U.CreateScrollablePanel, U.AddTitle, U.AddDescription, U.CreateSwitch

local function CreateTRP3Panel()
    local panel, content, layout = CreateScrollablePanel("TRP3")
    AddTitle(content, layout, "Simple Nameplates — TRP3")
    AddDescription(content, layout, "Optional Total RP 3 profile integration. Simple Nameplates continues to work normally when TRP3 is absent.")
    local enabledRow = CreateFrame("Frame", nil, content)
    enabledRow:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(enabledRow, 24, 30, 8)
    local enabledLabel = enabledRow:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    enabledLabel:SetPoint("LEFT")
    enabledLabel:SetText("Display TRP3 profile information")
    local refreshOptions
    local enabled = CreateSwitch(enabledRow, function(checked)
        ns.SetTRP3Enabled(checked)
        if ns.TRP3 then ns.TRP3.Refresh() end
        refreshOptions()
    end)
    enabled:SetPoint("LEFT", enabledLabel, "RIGHT", 12, 0)

    local status = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    status:SetJustifyH("LEFT")
    layout:Add(status, 24, 38, 8)
    local section = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    section:SetText("DISPLAY OPTIONS")
    layout:Add(section, 24, 20, 2)

    local optionControls = {}
    local function CreateOption(labelText, setting)
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("RIGHT", content, "RIGHT", -20, 0)
        layout:Add(row, 24, 34, 2)
        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT")
        label:SetText(labelText)
        local option = CreateSwitch(row, function(checked)
            ns.SetTRP3Setting(setting, checked)
            if ns.TRP3 then ns.TRP3.Refresh() end
        end)
        option:SetPoint("LEFT", label, "RIGHT", 12, 0)
        optionControls[#optionControls + 1] = { button = option, label = label, setting = setting }
    end
    CreateOption("Use TRP3 roleplaying full name", "useRoleplayingName")
    CreateOption("Show short title before the name", "showShortTitle")
    CreateOption("Show [OOC] instead of the short title", "showOOC")
    CreateOption("Show long title beneath the name", "showFullTitle")

    local note = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    note:SetJustifyH("LEFT")
    note:SetText("Long titles appear beneath names at 80% of the name size and are hidden for units with visible health bars. If no cached TRP3 profile or selected field is available, the normal WoW name is used.")
    layout:Add(note, 24, 40)

    local function Refresh()
        enabled:SetChecked(ns.GetTRP3Enabled())
        local isEnabled = ns.GetTRP3Enabled()
        for _, control in ipairs(optionControls) do
            control.button:SetChecked(ns.GetTRP3Setting(control.setting))
            control.button:SetEnabled(isEnabled)
            local shade = isEnabled and 1 or 0.5
            control.label:SetTextColor(shade, shade, shade, 1)
        end
        if ns.TRP3 and ns.TRP3.IsAvailable() then
            status:SetText("Total RP 3 detected. Enabled options apply to cached player profiles.")
            status:SetTextColor(0.35, 0.85, 0.35, 1)
        else
            status:SetText("Total RP 3 is not currently available. This setting will take effect when it is installed and enabled.")
            status:SetTextColor(0.75, 0.75, 0.75, 1)
        end
    end
    refreshOptions = Refresh
    panel:SetScript("OnShow", Refresh)
    Refresh()
    layout:Finish()
    return panel
end

ns.SettingsPanels.TRP3 = CreateTRP3Panel
