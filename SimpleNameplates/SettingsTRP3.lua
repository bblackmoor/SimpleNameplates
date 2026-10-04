-- Simple Nameplates: global Total RP 3 integration settings.
local _, ns = ...
local U = ns.SettingsUI

local function CreateTRP3Panel()
    local panel, content, layout = U.CreateScrollablePanel("TRP3")
    U.AddTitle(content, layout, "TRP3")
    U.AddDescription(content, layout,
        "Applies to all characters and profiles.")
    local refreshers, controls = {}, {}
    local function RefreshIntegration() if ns.TRP3 then ns.TRP3.Refresh() end end
    local function Refresh()
        U.RunRefreshers(refreshers)
        local enabled = ns.GetTRP3Enabled()
        for _, control in ipairs(controls) do
            control.toggle:SetEnabled(enabled)
            local shade = enabled and 1 or 0.5
            control.label:SetTextColor(shade, shade, shade, 1)
        end
    end
    U.AddToggle(content, layout, refreshers, "Display TRP3 profile information",
        ns.GetTRP3Enabled, ns.SetTRP3Enabled, function() RefreshIntegration(); Refresh() end)
    local status = U.AddDescription(content, layout, "")
    refreshers[#refreshers + 1] = function()
        if ns.TRP3 and ns.TRP3.IsAvailable() then
            status:SetText("Total RP 3 detected.")
            status:SetTextColor(0.35, 0.85, 0.35, 1)
        else
            status:SetText("Requires Total RP 3 to be installed and enabled.")
            status:SetTextColor(0.72, 0.72, 0.72, 1)
        end
    end
    U.AddSection(content, layout, "Names and titles")
    local function AddOption(text, setting, description)
        local row, label = U.CreateSettingRow(content, layout, text)
        local toggle = U.CreateSwitch(row, function(checked)
            ns.SetTRP3Setting(setting, checked)
            RefreshIntegration()
        end)
        toggle:SetPoint("LEFT", row, "LEFT", U.CONTROL_X, 0)
        controls[#controls + 1] = {toggle = toggle, label = label}
        refreshers[#refreshers + 1] = function() toggle:SetChecked(ns.GetTRP3Setting(setting)) end
        if description then U.AddDescription(content, layout, description) end
    end
    AddOption("Use TRP3 roleplaying full name", "useRoleplayingName")
    AddOption("Show short title before the name", "showShortTitle")
    AddOption("Show [OOC] instead of the short title", "showOOC")
    AddOption("Show TRP3 long title beneath the name", "showFullTitle",
        "Uses 80% of the name size; hidden while a health bar is visible.")
    U.AddDescription(content, layout,
        "Missing profile information uses the WoW name. NPC service titles do not require TRP3.")
    panel:SetScript("OnShow", Refresh)
    Refresh()
    layout:Finish()
    return panel
end
ns.SettingsPanels.TRP3 = CreateTRP3Panel
